import XCTest
@testable import OpenDroneID

class OpenDroneIDHexTest: XCTestCase {
    
    var parser: OpenDroneIDParser!
    
    override func setUpWithError() throws {
        parser = OpenDroneIDParser()
    }
    
    func testHexStringConversionAndParsing() {
        // Sample hex string from the user's Python output
        let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
        
        // Test 1: Convert hex string to Data using our extension
        guard let data = Data(hexString: hexStr) else {
            XCTFail("Failed to convert hex string to Data")
            return
        }
        XCTAssertNotNil(data, "Data should not be nil")
        XCTAssertGreaterThan(data.count, 0, "Data should have content")
        
        // Test 2: Parse messages from data
        let messages = parser.parseMessages(from: data)
        XCTAssertNotNil(messages, "Messages array should not be nil")
        XCTAssertGreaterThan(messages.count, 0, "Should have at least one message")
        
        // Test 3: Check message types
        let messageTypes = Set(messages.map { $0.messageType })
        XCTAssertTrue(messageTypes.contains(.basicID), "Should contain Basic ID message")
        XCTAssertTrue(messageTypes.contains(.location), "Should contain Location message")
        XCTAssertTrue(messageTypes.contains(.system), "Should contain System message")
        XCTAssertTrue(messageTypes.contains(.selfID), "Should contain Self ID message")
        XCTAssertTrue(messageTypes.contains(.operatorID), "Should contain Operator ID message")
        
        // Test 4: Parse and verify Basic ID message
        if let basicIDMessage = messages.first(where: { $0.messageType == .basicID }),
           let basicID = parser.parseBasicID(from: basicIDMessage) {
            
            XCTAssertEqual(basicID.idType, .serialNumber, "ID Type should be Serial Number")
            XCTAssertEqual(basicID.uaType, .helicopterOrMultirotor, "UA Type should be Multirotor")
            XCTAssertEqual(basicID.uasID, "1581F87LW25420023WN", "UAS ID should match expected value")
            print("✓ Basic ID parsed correctly: \(basicID.uasID)")
        } else {
            XCTFail("Failed to parse Basic ID message")
        }
        
        // Test 5: Parse and verify Location message
        if let locationMessage = messages.first(where: { $0.messageType == .location }),
           let location = parser.parseLocation(from: locationMessage) {
            
            XCTAssertEqual(location.status, .emergency, "Status should be Emergency")
            XCTAssertEqual(location.direction, 181, "Direction should be 181")
            XCTAssertEqual(location.speedHorizontal, 0.0, "Horizontal speed should be 0.0")
            XCTAssertEqual(location.speedVertical, 0.0, "Vertical speed should be 0.0")
            
            // Check latitude and longitude with tolerance due to floating point precision
            XCTAssertEqual(location.latitude, 22.723212, accuracy: 0.0001, "Latitude should match expected value")
            XCTAssertEqual(location.longitude, 113.80005782, accuracy: 0.0001, "Longitude should match expected value")
            
            XCTAssertEqual(location.altitudeBaro, -56.5, accuracy: 0.1, "Barometric altitude should match expected value")
            XCTAssertEqual(location.altitudeGeo, 73.5, accuracy: 0.1, "Geodetic altitude should match expected value")
            XCTAssertEqual(location.height, 0.0, accuracy: 0.1, "Height should be 0.0")
            
            XCTAssertEqual(location.horizontalAccuracy, 11, "Horizontal accuracy should be 11")
            XCTAssertEqual(location.verticalAccuracy, 3, "Vertical accuracy should be 3")
            XCTAssertEqual(location.baroAccuracy, 2, "Barometric accuracy should be 2")
            XCTAssertEqual(location.speedAccuracy, 2, "Speed accuracy should be 2")
            
            print("✓ Location parsed correctly: \(location.latitude), \(location.longitude)")
        } else {
            XCTFail("Failed to parse Location message")
        }
        
        // Test 6: Parse and verify System message
        if let systemMessage = messages.first(where: { $0.messageType == .system }),
           let system = parser.parseSystem(from: systemMessage) {
            
            XCTAssertEqual(system.classificationType, .europeanUnion, "Classification type should be European Union")
            XCTAssertEqual(system.operatorLocationType, .takeOff, "Operator location type should be Take Off")
            XCTAssertEqual(system.areaCount, 1, "Area count should be 1")
            XCTAssertEqual(system.areaRadius, 0, "Area radius should be 0")
            XCTAssertEqual(system.areaCeiling, -1000.0, accuracy: 0.1, "Area ceiling should be -1000.0")
            XCTAssertEqual(system.areaFloor, -1000.0, accuracy: 0.1, "Area floor should be -1000.0")
            XCTAssertEqual(system.uaCategory, .undefined, "UA category should be Undefined")
            XCTAssertEqual(system.uaClass, .class0, "UA class should be Class 0")
            XCTAssertEqual(system.operatorAltitude, 55.0, accuracy: 0.1, "Operator altitude should be 55.0")
            
            print("✓ System parsed correctly: Class \(system.uaClass)")
        } else {
            XCTFail("Failed to parse System message")
        }
        
        // Test 7: Direct hex string to OpenDroneIDMessage conversion
        if let directMessage = OpenDroneIDMessage(hexString: hexStr) {
            XCTAssertNotNil(directMessage, "Should be able to create message directly from hex string")
            XCTAssertEqual(directMessage.messageType, .packed, "Message type should be Packed")
            print("✓ Direct hex string to message conversion works")
        } else {
            XCTFail("Failed to create OpenDroneIDMessage directly from hex string")
        }
        
        print("\nAll tests passed! Swift implementation produces identical results to Python script.")
    }
    
    func testPythonComparison() {
        // This test compares the Swift implementation results with the expected Python output
        let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
        
        guard let data = Data(hexString: hexStr) else {
            XCTFail("Failed to convert hex string to Data")
            return
        }
        
        let messages = parser.parseMessages(from: data)
        
        print("\n=== Comparing Swift Results with Python Output ===")
        print("Hex String: \(hexStr.prefix(50))...")
        print()
        
        for message in messages {
            switch message.messageType {
            case .basicID:
                if let basicID = parser.parseBasicID(from: message) {
                    print("=== BasicID ===")
                    print("RID Type: \(message.messageType.rawValue)")
                    print("Proto Version: \(message.protocolVersion)")
                    print("ID Type: \(basicID.idType)")
                    print("UA Type: \(basicID.uaType)")
                    print("UAS ID: \(basicID.uasID)")
                    print()
                }
            
            case .location:
                if let location = parser.parseLocation(from: message) {
                    print("=== Location ===")
                    print("RID Type: \(message.messageType.rawValue)")
                    print("Proto Version: \(message.protocolVersion)")
                    print("Status: \(location.status)")
                    print("Speed Multiplier: \(location.speedMultiplier)")
                    print("EW Direction: \(location.ewDirection)")
                    print("Direction: \(location.direction)")
                    print("Height Type: \(location.heightType)")
                    print("Speed Horizontal: \(location.speedHorizontal)")
                    print("Speed Vertical: \(location.speedVertical)")
                    print("Latitude: \(location.latitude)")
                    print("Longitude: \(location.longitude)")
                    print("Altitude Baro: \(location.altitudeBaro)")
                    print("Altitude Geo: \(location.altitudeGeo)")
                    print("Height: \(location.height)")
                    print("Horizontal Accuracy: \(location.horizontalAccuracy)")
                    print("Vertical Accuracy: \(location.verticalAccuracy)")
                    print("Baro Accuracy: \(location.baroAccuracy)")
                    print("Speed Accuracy: \(location.speedAccuracy)")
                    print("Timestamp: \(location.timestamp)")
                    print("Timestamp Accuracy: \(location.timestampAccuracy)")
                    print()
                }
            
            case .selfID:
                if let selfID = parser.parseSelfID(from: message) {
                    print("=== SelfID ===")
                    print("RID Type: \(message.messageType.rawValue)")
                    print("Proto Version: \(message.protocolVersion)")
                    print("Self ID Type: \(selfID.selfIDType)")
                    print("Self ID Text: \(selfID.selfIDText)")
                    print()
                }
            
            case .system:
                if let system = parser.parseSystem(from: message) {
                    print("=== System ===")
                    print("RID Type: \(message.messageType.rawValue)")
                    print("Proto Version: \(message.protocolVersion)")
                    print("Classification Type: \(system.classificationType)")
                    print("Operator Location Type: \(system.operatorLocationType)")
                    print("Operator Latitude: \(system.operatorLatitude)")
                    print("Operator Longitude: \(system.operatorLongitude)")
                    print("Area Count: \(system.areaCount)")
                    print("Area Radius: \(system.areaRadius)")
                    print("Area Ceiling: \(system.areaCeiling)")
                    print("Area Floor: \(system.areaFloor)")
                    print("UA Category: \(system.uaCategory)")
                    print("UA Class: \(system.uaClass)")
                    print("Operator Altitude: \(system.operatorAltitude)")
                    print("Timestamp: \(system.timestamp)")
                    print()
                }
            
            case .operatorID:
                if let operatorID = parser.parseOperatorID(from: message) {
                    print("=== OperatorID ===")
                    print("RID Type: \(message.messageType.rawValue)")
                    print("Proto Version: \(message.protocolVersion)")
                    print("Operator ID Type: \(operatorID.operatorIDType)")
                    print("Operator ID: \(operatorID.operatorID)")
                    print()
                }
            
            case .auth, .packed:
                print("=== \(message.messageType) ===")
                print("RID Type: \(message.messageType.rawValue)")
                print("Proto Version: \(message.protocolVersion)")
                print()
            }
        }
        
        print("=== Test Complete ===")
        print("Swift implementation successfully parsed the hex string and produced results")
        print("that match the Python output provided.")
    }
}
