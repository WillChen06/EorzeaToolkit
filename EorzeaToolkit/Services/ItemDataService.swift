import CryptoKit
import Foundation

enum ItemDataService {
    private static let manifestURL = URL(string: "https://eorzeatoolkitdata.willchen06.workers.dev/manifest.json")!
    private static let cachedVersionKey = "itemData.cachedVersion"
    private static let cachedItemsFilename = "items-current.json"

    enum ItemDataError: Error, LocalizedError {
        case invalidItemsURL
        case unexpectedByteSize(expected: Int, actual: Int)
        case checksumMismatch
        case noAvailableData(Error)

        var errorDescription: String? {
            switch self {
            case .invalidItemsURL:
                return "遠端道具資料網址無效"
            case .unexpectedByteSize(let expected, let actual):
                return "遠端道具資料大小不符：預期 \(expected) bytes，實際 \(actual) bytes"
            case .checksumMismatch:
                return "遠端道具資料校驗失敗"
            case .noAvailableData(let error):
                return "無法載入本地或內建道具資料：\(error.localizedDescription)"
            }
        }
    }

    static func loadCachedOrBundledData() async throws -> ItemDataResponse {
        try await loadPreferredData(
            cachedVersion: cachedVersion,
            loadCached: loadCachedData,
            loadBundled: loadBundledData,
            discardCache: discardCachedItems
        )
    }

    /// Loads the bundled data unless the cache holds a newer version (see `ItemDataVersion`).
    ///
    /// The bundled data is regenerated with every app build, so an older cache — or one in a
    /// version format that does not parse — is discarded rather than allowed to replace it.
    /// The cache is still used when the bundled data cannot be loaded at all.
    static func loadPreferredData(
        cachedVersion: String?,
        loadCached: () async throws -> ItemDataResponse?,
        loadBundled: () async throws -> ItemDataResponse,
        discardCache: () -> Void
    ) async throws -> ItemDataResponse {
        let bundledData: ItemDataResponse
        do {
            bundledData = try await loadBundled()
        } catch {
            if let cachedData = try? await loadCached() {
                return cachedData
            }
            discardCache()
            throw ItemDataError.noAvailableData(error)
        }

        if ItemDataVersion.isNewer(cachedVersion, than: bundledData.version),
           let cachedData = try? await loadCached() {
            return cachedData
        }

        discardCache()
        return bundledData
    }

    static func refreshDataIfNeeded(currentVersion: String?) async throws -> ItemDataResponse? {
        try await refreshDataIfNeeded(currentVersion: currentVersion) { url in
            try await URLSession.shared.data(from: url).0
        }
    }

    /// Downloads the remote items only when the manifest version is newer than `currentVersion`,
    /// the version of the data in use: the bundled data, or a newer cache. A manifest in a
    /// version format that does not parse is never downloaded.
    static func refreshDataIfNeeded(
        currentVersion: String?,
        fetch: (URL) async throws -> Data
    ) async throws -> ItemDataResponse? {
        let manifestData = try await fetch(manifestURL)
        let manifest = try JSONDecoder().decode(ItemDataManifest.self, from: manifestData)

        guard ItemDataVersion.isNewer(manifest.version, than: currentVersion) else {
            return nil
        }

        guard let itemsURL = URL(string: manifest.itemsURL, relativeTo: manifestURL)?.absoluteURL else {
            throw ItemDataError.invalidItemsURL
        }

        let itemData = try await fetch(itemsURL)
        try validate(itemData, with: manifest)

        let response = try JSONDecoder().decode(ItemDataResponse.self, from: itemData)
        try writeCachedItems(itemData)
        cachedVersion = manifest.version

        return response
    }

    private static var cachedVersion: String? {
        get {
            UserDefaults.standard.string(forKey: cachedVersionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cachedVersionKey)
        }
    }

    private static var cachedItemsURL: URL {
        get throws {
            try applicationSupportDirectory().appending(path: cachedItemsFilename)
        }
    }

    private static func loadCachedData() async throws -> ItemDataResponse? {
        let url = try cachedItemsURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ItemDataResponse.self, from: data)
        }.value
    }

    private static func loadBundledData() async throws -> ItemDataResponse {
        try await Task.detached(priority: .userInitiated) {
            try LocalDataService.load("items")
        }.value
    }

    private static func writeCachedItems(_ data: Data) throws {
        let directory = try applicationSupportDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: try cachedItemsURL, options: .atomic)
    }

    private static func discardCachedItems() {
        cachedVersion = nil

        guard let cachedItemsURL = try? cachedItemsURL else {
            return
        }

        try? FileManager.default.removeItem(at: cachedItemsURL)
    }

    private static func applicationSupportDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return baseURL.appending(path: "EorzeaToolkit", directoryHint: .isDirectory)
    }

    private static func validate(_ data: Data, with manifest: ItemDataManifest) throws {
        if data.count != manifest.items.byteSize {
            throw ItemDataError.unexpectedByteSize(expected: manifest.items.byteSize, actual: data.count)
        }

        let digest = SHA256.hash(data: data)
        let checksum = digest.map { String(format: "%02x", $0) }.joined()

        guard checksum == manifest.items.sha256 else {
            throw ItemDataError.checksumMismatch
        }
    }
}

private struct ItemDataManifest: Decodable, Sendable {
    let version: String
    let itemsURL: String
    let items: RemoteItemFile
}

private struct RemoteItemFile: Decodable, Sendable {
    let sha256: String
    let byteSize: Int
}
