import XCTest
@testable import EorzeaToolkit

/// A spot's map coordinates run from 1 to 1 + 41 / (size factor / 100), so the spot card has to
/// scale by the map's size factor before placing the map image. The expected position comes from
/// the spot's raw world coordinates instead, the way the game maps them onto the 2048-pixel map
/// image, so it does not share a formula with the code under test.
final class TreasureSpotMapProjectionTests: XCTestCase {
    private struct RawSpot {
        let id: String
        let mapId: Int
        /// `Level` X and Z for the spot's `TreasureSpot.Location`, from the pinned datamining commit.
        let worldX: Double
        let worldZ: Double
    }

    /// Two spots on size factor 100 maps and two on size factor 95 maps. Every map they are on has
    /// an offset of 0.
    private let rawSpots = [
        RawSpot(id: "1.0", mapId: 4, worldX: 364.934, worldZ: 60.0566),
        RawSpot(id: "28.16", mapId: 857, worldX: 639.239, worldZ: 379.987),
        RawSpot(id: "10.10", mapId: 212, worldX: -42.3056, worldZ: 673.399),
        RawSpot(id: "11.0", mapId: 211, worldX: -788.745, worldZ: -519.184),
    ]

    func testSpotCardPositionAccountsForTheMapSizeFactor() throws {
        let data: TreasureMapData = try LocalDataService.load("treasure_maps")
        let zonesBySpotId = Dictionary(
            data.maps.flatMap(\.zones).flatMap { zone in zone.spots.map { ($0.id, (zone, $0)) } },
            uniquingKeysWith: { first, _ in first }
        )

        var sizeFactors: Set<Int> = []
        for raw in rawSpots {
            let (zone, spot) = try XCTUnwrap(zonesBySpotId[raw.id], "spot \(raw.id)")
            XCTAssertEqual(zone.mapId, raw.mapId, "spot \(raw.id)")
            sizeFactors.insert(zone.sizeFactor)

            let scale = Double(zone.sizeFactor) / 100
            let expectedX = (raw.worldX * scale + 1024) / 2048
            let expectedY = (raw.worldZ * scale + 1024) / 2048

            let actual = TreasureSpotMapProjection.normalizedPosition(of: spot, sizeFactor: zone.sizeFactor)

            XCTAssertEqual(actual.x, expectedX, accuracy: 0.001, "spot \(raw.id)")
            XCTAssertEqual(actual.y, expectedY, accuracy: 0.001, "spot \(raw.id)")
        }

        XCTAssertEqual(sizeFactors, [95, 100], "the checked spots should cover both size factors in use")
    }

    /// Every spot sits on its map image, whatever the map's size factor.
    func testEverySpotFallsInsideItsMapImage() throws {
        let data: TreasureMapData = try LocalDataService.load("treasure_maps")

        var outside: [String] = []
        for zone in data.maps.flatMap(\.zones) {
            for spot in zone.spots {
                let position = TreasureSpotMapProjection.normalizedPosition(of: spot, sizeFactor: zone.sizeFactor)
                if !(0...1).contains(position.x) || !(0...1).contains(position.y) {
                    outside.append(spot.id)
                }
            }
        }

        XCTAssertTrue(outside.isEmpty, "spots outside their map image: \(outside)")
    }
}

/// Gathering nodes carry a PlaceName id, and several non-dungeon maps can share one PlaceName.
/// The node map has to open the map the nodes are actually on, every time. The expected maps are
/// where the pinned Teamcraft nodes.json puts the treasure map gathering nodes of each shared
/// PlaceName.
@MainActor
final class TreasureMapGatheringZoneMapTests: XCTestCase {
    private let expectedMapIdByZoneId = [
        45: 23,     // 南薩納蘭; map 93 shares the PlaceName
        55: 5,      // 黑衣森林東部林區; map 180 (size factor 200) shares it
        56: 6,      // 黑衣森林南部林區; maps 181 and 187 share it
        67: 25,     // 摩杜納; map 105 (size factor 400) shares it
        3712: 699,  // 天外天垓; map 751 shares it
    ]

    /// The image of each expected map, and its size factor.
    private let expectedImageByMapId = [
        23: "https://xivapi.com/m/w1f4/w1f4.01.jpg",
        5: "https://xivapi.com/m/f1f2/f1f2.00.jpg",
        6: "https://xivapi.com/m/f1f3/f1f3.00.jpg",
        25: "https://xivapi.com/m/l1f1/l1f1.01.jpg",
        699: "https://xivapi.com/m/u5f2/u5f2.00.jpg",
    ]

    func testSharedPlaceNamesResolveToTheMapOfTheirGatheringNodes() async throws {
        let catalog = try await TreasureMapClient.liveValue.fetch()

        var checkedZoneIds: Set<Int> = []
        for map in catalog.maps {
            for node in map.gatheringNodes {
                guard let expectedMapId = expectedMapIdByZoneId[node.zoneId] else { continue }
                checkedZoneIds.insert(node.zoneId)
                let label = "\(map.grade) node in zone \(node.zoneId) at (\(node.x), \(node.y))"
                XCTAssertEqual(node.mapId, expectedMapId, label)
                XCTAssertEqual(node.image, expectedImageByMapId[expectedMapId], label)
                XCTAssertEqual(node.sizeFactor, 100, label)
            }
        }

        XCTAssertEqual(checkedZoneIds, Set(expectedMapIdByZoneId.keys), "zones with no gathering nodes to check")
    }
}
