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
