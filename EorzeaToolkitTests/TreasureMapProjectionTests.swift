import XCTest
@testable import EorzeaToolkit

/// A spot's map coordinates run from 1 to 1 + 41 / (size factor / 100), so the spot card has to
/// scale by the map's size factor before placing the map image. The expected position comes from
/// the spot's raw world coordinates instead, the way the game maps them onto the 2048-pixel map
/// image, so it does not share a formula with the code under test.
final class TreasureSpotMapProjectionTests: XCTestCase {
    private struct RawSpot: Decodable {
        struct Coordinate: Decodable {
            let x: Double
            let y: Double
            let z: Double
        }

        let id: String
        let map: Int
        let coords: Coordinate
        let rawCoords: Coordinate
    }

    private struct RawMap: Decodable {
        let sizeFactor: Int
        let offsetX: Double
        let offsetY: Double

        enum CodingKeys: String, CodingKey {
            case sizeFactor = "size_factor"
            case offsetX = "offset_x"
            case offsetY = "offset_y"
        }
    }

    func testSpotCardPositionAccountsForTheMapSizeFactor() throws {
        let spots: [RawSpot] = try LocalDataService.load("treasures")
        let maps: [String: RawMap] = try LocalDataService.load("maps")
        XCTAssertFalse(spots.isEmpty)

        var misplacedSpotsByMap: [Int: Int] = [:]
        for spot in spots {
            let map = try XCTUnwrap(maps[String(spot.map)], "map \(spot.map)")
            let scale = Double(map.sizeFactor) / 100
            let expectedX = ((spot.rawCoords.x + map.offsetX) * scale + 1024) / 2048
            let expectedY = ((spot.rawCoords.y + map.offsetY) * scale + 1024) / 2048

            let actual = TreasureSpotMapProjection.normalizedPosition(
                of: TreasureSpot.Coordinate(x: spot.coords.x, y: spot.coords.y, z: spot.coords.z),
                sizeFactor: map.sizeFactor
            )

            if abs(actual.x - expectedX) > 0.001 || abs(actual.y - expectedY) > 0.001 {
                misplacedSpotsByMap[spot.map, default: 0] += 1
            }
        }

        XCTAssertTrue(
            misplacedSpotsByMap.isEmpty,
            "spots placed off their map position, by map id: \(misplacedSpotsByMap.sorted { $0.key < $1.key })"
        )
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

    func testSharedPlaceNamesResolveToTheMapOfTheirGatheringNodes() {
        let viewModel = TreasureMapViewModel()
        viewModel.loadMaps()
        XCTAssertNil(viewModel.loadError)

        var checkedZoneIds: Set<Int> = []
        for map in viewModel.maps {
            for node in viewModel.gatheringNodes(for: map) {
                guard let expectedMapId = expectedMapIdByZoneId[node.zoneId] else { continue }
                checkedZoneIds.insert(node.zoneId)
                XCTAssertEqual(
                    viewModel.mapInfo(forMapId: node.mapId)?.id, expectedMapId,
                    "\(map.grade) node in zone \(node.zoneId) at (\(node.x), \(node.y))"
                )
            }
        }

        XCTAssertEqual(checkedZoneIds, Set(expectedMapIdByZoneId.keys), "zones with no gathering nodes to check")
    }
}
