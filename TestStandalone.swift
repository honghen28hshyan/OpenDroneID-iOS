import Foundation

// Add the OpenDroneID module to the path
#if os(macOS)
    let modulePath = "/Users/dyw/空间/WB/OpenDroneID-iOS/OpenDroneID-iOS/OpenDroneID"
    // SwiftPM builds to .build/debug directory
    let buildPath = modulePath + "/.build/debug"
    print("Module path: \(modulePath)")
    print("Build path: \(buildPath)")
#endif

// Import the module
@_exported import OpenDroneID

// Test the parsing
func testParsing() {
    let hexData = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
    
    print("\n=== Testing Hex Parsing ===")
    print("Hex data length: \(hexData.count)")
    
    let parser = OpenDroneIDHexParser()
    let result = parser.parseAll(from: hexData)
    
    print("\n=== TEST RESULTS ===")
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
    
    // Verify results match Python output
    if result.totalMessageCount == 3 && 
       result.basicIDs.count == 1 && 
       result.locations.count == 1 && 
       result.systems.count == 1 {
        print("\n✅ SUCCESS: Parsed 3 messages as expected")
        
        if let basicID = result.basicIDs.first {
            if basicID.uasID == "1581F87LW25420023NVN" {
                print("✅ SUCCESS: Basic ID UASID matches Python output")
            } else {
                print("❌ FAILURE: Basic ID UASID doesn't match Python output")
            }
        }
    } else {
        print("\n❌ FAILURE: Expected 3 messages, got \(result.totalMessageCount)")
    }
}

// Run the test
testParsing()
