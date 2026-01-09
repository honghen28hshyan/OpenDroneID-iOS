import XCTest
@testable import OpenDroneID

final class FinalTest: XCTestCase {
    
    func testPythonComparison() {
        let hexData = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
        
        let parser = OpenDroneIDHexParser()
        let result = parser.parseAll(from: hexData)
        
        print("=== TEST RESULTS ===")
        print("Total messages: \(result.totalMessageCount)")
        print("Basic IDs: \(result.basicIDs.count)")
        print("Locations: \(result.locations.count)")
        print("Systems: \(result.systems.count)")
        
        // Print Basic ID details
        for basicID in result.basicIDs {
            print("\n===BasicID===")
            print("UAType: \(basicID.uaType)")
            print("IDType: \(basicID.idType)")
            print("UASID: \(basicID.uasID)")
        }
        
        // Print Location details
        for location in result.locations {
            print("\n===Location===")
            print("Status: \(location.status)")
            print("Speed Mult: \(location.speedMultiplier)")
            print("EW Direction: \(location.ewDirection)")
            print("Height Type: \(location.heightType)")
            print("Direction: \(location.direction)")
            print("Speed Horizontal: \(location.speedHorizontal)")
            print("Speed Vertical: \(location.speedVertical)")
            print("Latitude: \(location.latitude)")
            print("Longitude: \(location.longitude)")
            print("Altitude Baro: \(location.altitudeBaro)")
            print("Altitude Geo: \(location.altitudeGeo)")
            print("Height: \(location.height)")
            print("Horiz Accuracy: \(location.horizontalAccuracy)")
            print("Vert Accuracy: \(location.verticalAccuracy)")
            print("Speed Accuracy: \(location.speedAccuracy)")
            print("Timestamp: \(location.timestamp)")
            print("Timestamp Accuracy: \(location.timestampAccuracy)")
        }
        
        // Print System details
        for system in result.systems {
            print("\n===System===")
            print("Classification Type: \(system.classificationType)")
            print("Operator Location Type: \(system.operatorLocationType)")
            print("Operator Latitude: \(system.operatorLatitude)")
            print("Operator Longitude: \(system.operatorLongitude)")
            print("Area Count: \(system.areaCount)")
            print("Area Radius: \(system.areaRadius)")
            print("Area Ceiling: \(system.areaCeiling)")
            print("Area Floor: \(system.areaFloor)")
            print("UA category: \(system.uaCategory)")
            print("UA class: \(system.uaClass)")
            print("Operator Altitude: \(system.operatorAltitude)")
            print("Timestamp: \(system.timestamp)")
        }
        
        // Verify we got the expected number of messages (should be 3 based on Python output)
        XCTAssertEqual(result.totalMessageCount, 3, "Should parse 3 messages")
        XCTAssertEqual(result.basicIDs.count, 1, "Should parse 1 Basic ID message")
        XCTAssertEqual(result.locations.count, 1, "Should parse 1 Location message")
        XCTAssertEqual(result.systems.count, 1, "Should parse 1 System message")
        
        // Verify Basic ID content matches Python output
        if let basicID = result.basicIDs.first {
            XCTAssertEqual(basicID.uasID, "1581F87LW25420023NVN", "Basic ID UASID should match Python output")
        }
    }
}
