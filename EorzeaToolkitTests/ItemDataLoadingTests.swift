import CryptoKit
import XCTest
@testable import EorzeaToolkit

/// The bundled `items.json` is the newest data an app build ships with. These tests pin down
/// when a cached or downloaded copy may replace it. Every dependency is injected, so nothing
/// here touches the network, the app's UserDefaults or its Application Support files.
final class ItemDataLoadingTests: XCTestCase {
    private let bundledVersion = "2026.09.14.0000.0000-r1"

    // MARK: - Choosing between the cache and the bundled data

    func testOlderCacheLoadsBundledData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: "2026.07.22.0000.0000-r3", log: log)

        XCTAssertEqual(data.items.first?.nameTw, bundledName)
        XCTAssertEqual(log.loadCachedCalls, 0, "an older cache must not even be read")
        XCTAssertEqual(log.discardCalls, 1, "an older cache is discarded")
    }

    /// The cache written from the remote file published before the Traditional Chinese data.
    func testUnparseableCacheLoadsBundledData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: "2026-05-17-v2", log: log)

        XCTAssertEqual(data.items.first?.nameTw, bundledName)
        XCTAssertEqual(log.loadCachedCalls, 0)
        XCTAssertEqual(log.discardCalls, 1)
    }

    func testCacheOfTheSameVersionLoadsBundledData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: bundledVersion, log: log)

        XCTAssertEqual(data.items.first?.nameTw, bundledName)
        XCTAssertEqual(log.loadCachedCalls, 0)
    }

    func testMissingCacheLoadsBundledData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: nil, log: log, cacheIsReadable: false)

        XCTAssertEqual(data.items.first?.nameTw, bundledName)
    }

    func testNewerCacheLoadsCachedData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: "2026.09.14.0000.0000-r2", log: log)

        XCTAssertEqual(data.items.first?.nameTw, cachedName)
        XCTAssertEqual(log.loadCachedCalls, 1)
        XCTAssertEqual(log.discardCalls, 0, "the cache in use must not be discarded")
    }

    func testNewerCacheThatCannotBeReadFallsBackToBundledData() async throws {
        let log = CallLog()

        let data = try await load(cachedVersion: "2026.09.14.0000.0000-r2", log: log, cacheIsReadable: false)

        XCTAssertEqual(data.items.first?.nameTw, bundledName)
        XCTAssertEqual(log.discardCalls, 1)
    }

    // MARK: - Deciding whether to download the remote file

    func testOlderManifestIsNotDownloaded() async throws {
        let requests = try await refresh(currentVersion: bundledVersion, manifestVersion: "2026.07.22.0000.0000-r3")

        XCTAssertEqual(requests, ["manifest.json"])
    }

    func testManifestOfTheSameVersionIsNotDownloaded() async throws {
        let requests = try await refresh(currentVersion: bundledVersion, manifestVersion: bundledVersion)

        XCTAssertEqual(requests, ["manifest.json"])
    }

    /// The manifest the Cloudflare Worker serves until the new files are uploaded.
    func testUnparseableManifestIsNotDownloaded() async throws {
        let requests = try await refresh(currentVersion: bundledVersion, manifestVersion: "2026-05-17-v2")

        XCTAssertEqual(requests, ["manifest.json"])
    }

    /// The data in use can be a cache that is newer than the bundled data. A manifest between
    /// the two must not replace it.
    func testManifestOlderThanTheCacheInUseIsNotDownloaded() async throws {
        let requests = try await refresh(
            currentVersion: "2026.09.14.0000.0000-r3",
            manifestVersion: "2026.09.14.0000.0000-r2"
        )

        XCTAssertEqual(requests, ["manifest.json"])
    }

    /// The download itself fails validation here (the manifest promises one byte, the fake
    /// server returns none), which also keeps the test from writing a cache file.
    func testNewerManifestDownloadsTheItems() async throws {
        let log = RequestLog()

        do {
            _ = try await ItemDataService.refreshDataIfNeeded(
                currentVersion: bundledVersion,
                fetch: { url in
                    log.urls.append(url)
                    if url.lastPathComponent == "manifest.json" {
                        return manifestData(version: "2026.09.14.0000.0000-r2")
                    }
                    return Data()
                }
            )
            XCTFail("an empty download cannot match the manifest's byte size")
        } catch {}

        XCTAssertEqual(log.urls.map(\.lastPathComponent), ["manifest.json", "items-test.json"])
    }

    /// A file that passes the size and checksum checks but declares an older version than its
    /// manifest must not be cached under the manifest's version. The guard runs before the
    /// cache is written, so this test leaves no file behind.
    func testDownloadWhoseVersionDiffersFromTheManifestIsRejected() async throws {
        let manifestVersion = "2026.09.14.0000.0000-r2"
        let fileVersion = "2026.09.14.0000.0000-r1"
        let items = Data(
            #"{"_meta":{"version":"\#(fileVersion)"},"items":[{"id":1,"name_tw":"測試","icon_id":0,"icon_path":"","ilvl":1,"rarity":1}]}"#.utf8
        )
        let checksum = SHA256.hash(data: items).map { String(format: "%02x", $0) }.joined()

        do {
            _ = try await ItemDataService.refreshDataIfNeeded(
                currentVersion: bundledVersion,
                fetch: { url in
                    if url.lastPathComponent == "manifest.json" {
                        return manifestData(version: manifestVersion, sha256: checksum, byteSize: items.count)
                    }
                    return items
                }
            )
            XCTFail("a file declaring another version than its manifest must be rejected")
        } catch ItemDataService.ItemDataError.versionMismatch(let manifest, let file) {
            XCTAssertEqual(manifest, manifestVersion)
            XCTAssertEqual(file, fileVersion)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    // MARK: - Helpers

    private let bundledName = "內建資料"
    private let cachedName = "快取資料"

    /// `cacheIsReadable: false` makes the cache loader return nothing, as it does when the
    /// file is missing or cannot be decoded.
    private func load(
        cachedVersion: String?,
        log: CallLog,
        cacheIsReadable: Bool = true
    ) async throws -> ItemDataResponse {
        let cached = cacheIsReadable ? itemData(named: cachedName, version: cachedVersion) : nil
        let bundled = itemData(named: bundledName, version: bundledVersion)

        return try await ItemDataService.loadPreferredData(
            cachedVersion: cachedVersion,
            loadCached: {
                log.loadCachedCalls += 1
                return cached
            },
            loadBundled: { bundled },
            discardCache: { log.discardCalls += 1 }
        )
    }

    /// Returns the last path component of every URL requested.
    private func refresh(currentVersion: String?, manifestVersion: String) async throws -> [String] {
        let log = RequestLog()

        let result = try await ItemDataService.refreshDataIfNeeded(
            currentVersion: currentVersion,
            fetch: { url in
                log.urls.append(url)
                return manifestData(version: manifestVersion)
            }
        )

        XCTAssertNil(result)
        return log.urls.map(\.lastPathComponent)
    }
}

private final class CallLog {
    var loadCachedCalls = 0
    var discardCalls = 0
}

private final class RequestLog {
    var urls: [URL] = []
}

private func itemData(named name: String, version: String?) -> ItemDataResponse {
    ItemDataResponse(
        meta: ItemDataMeta(version: version),
        items: [
            Item(
                id: 1,
                nameTw: name,
                iconId: 0,
                iconPath: "",
                ilvl: 1,
                rarity: 1,
                canBeHq: false,
                isUntradable: false
            )
        ]
    )
}

private func manifestData(version: String, sha256: String = "00", byteSize: Int = 1) -> Data {
    Data(#"{"version":"\#(version)","itemsURL":"/items-test.json","items":{"sha256":"\#(sha256)","byteSize":\#(byteSize)}}"#.utf8)
}
