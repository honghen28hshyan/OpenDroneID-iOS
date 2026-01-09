//
//  OpenDroneIDTests.swift
//  OpenDroneIDTests
//
//  Created by on 2026/01/09.
//

import XCTest
@testable import OpenDroneID

class OpenDroneIDTests: XCTestCase {
    
    var parser: OpenDroneIDParser!
    
    override func setUp() {
        super.setUp()
        parser = OpenDroneIDParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    func testMessageTypeEnum() {
        XCTAssertEqual(ODIDMessageType.basicID.rawValue, 0)
        XCTAssertEqual(ODIDMessageType.location.rawValue, 1)
        XCTAssertEqual(ODIDMessageType.auth.rawValue, 2)
        XCTAssertEqual(ODIDMessageType.selfID.rawValue, 3)
        XCTAssertEqual(ODIDMessageType.system.rawValue, 4)
        XCTAssertEqual(ODIDMessageType.operatorID.rawValue, 5)
        XCTAssertEqual(ODIDMessageType.packed.rawValue, 0xF)
    }
    
    func testConstants() {
        XCTAssertEqual(OpenDroneIDConstants.idSize, 20)
        XCTAssertEqual(OpenDroneIDConstants.strSize, 23)
        XCTAssertEqual(OpenDroneIDConstants.messageSize, 25)
    }
    
    func testHexStringParsing() {
        let hexString = "001234567890"
        let expectedData = Data([0x00, 0x12, 0x34, 0x56, 0x78, 0x90])
        
        let result = parser.parseHexString(hexString)
        XCTAssertEqual(result, expectedData)
    }
    
    func testInvalidHexStringParsing() {
        let invalidHexString = "0012345"
        let result = parser.parseHexString(invalidHexString)
        XCTAssertNil(result)
    }
    
    func testCleanedString() {
        let dirtyString = "Hello\tWorld\n\r"
        let cleanedString = dirtyString.cleaned()
        XCTAssertEqual(cleanedString, "HelloWorld")
    }
    
    func testCleanedSNString() {
        let dirtySN = "1234 5678\t90"
        let cleanedSN = dirtySN.cleanedForSN()
        XCTAssertEqual(cleanedSN, "1234567890")
    }
    
    func testFA0BB0CDPatternFinding() {
        let hexString = "abcdef012345fa0bbc0d6789"
        let range = parser.findFA0BB0CDPattern(in: hexString)
        XCTAssertNotNil(range)
        
        let foundSubstring = hexString[range!]
        XCTAssertEqual(foundSubstring.lowercased(), "fa0bbc0d")
    }
    
    func testEmptyFA0BB0CDPatternFinding() {
        let hexString = "abcdef012345"
        let range = parser.findFA0BB0CDPattern(in: hexString)
        XCTAssertNil(range)
    }
    
    func testBasicIDParsing() {
        // Create a mock Basic ID message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: Basic ID (0x0), Protocol version: 1 (0x1)
        mockData[0] = 0x01
        
        // ID Type: Serial Number (1), UA Type: Multirotor (2)
        mockData[1] = 0x12
        
        // UAS ID: "TEST1234567890123456" (20 bytes)
        let uasID = "TEST1234567890123456"
        let uasIDData = uasID.data(using: .ascii)! + Data(count: OpenDroneIDConstants.idSize - uasID.count)
        uasIDData.copyBytes(to: &mockData[2], count: uasIDData.count)
        
        // Create message and parse
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .basicID)
        
        let basicID = parser.parseBasicID(from: message!)
        XCTAssertNotNil(basicID)
        XCTAssertEqual(basicID?.idType, .serialNumber)
        XCTAssertEqual(basicID?.uaType, .helicopterOrMultirotor)
        XCTAssertEqual(basicID?.uasID, uasID)
    }
    
    func testLocationParsing() {
        // Create a mock Location message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: Location (1x0), Protocol version: 1 (0x1)
        mockData[0] = 0x11
        
        // Status: Airborne (2), Speed Mult: 0, EW Direction: 0, Height Type: Above Ground Level (1)
        mockData[1] = 0x22
        
        // Direction: 90 degrees
        mockData[2] = 90
        
        // Speed Horizontal: 50 (0x32)
        mockData[3] = 0x32
        
        // Speed Vertical: 2.0 (0x04)
        mockData[4] = 0x04
        
        // Create message and parse
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .location)
        
        let location = parser.parseLocation(from: message!)
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.status, .airborne)
        XCTAssertEqual(location?.heightType, .aboveGroundLevel)
        XCTAssertEqual(location?.direction, 90)
    }
    
    func testSelfIDParsing() {
        // Create a mock Self ID message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: Self ID (3x0), Protocol version: 1 (0x1)
        mockData[0] = 0x31
        
        // Self ID Type: Text (0)
        mockData[1] = 0x00
        
        // Self ID Text: "Test Drone"
        let selfIDText = "Test Drone"
        let selfIDData = selfIDText.data(using: .ascii)! + Data(count: OpenDroneIDConstants.strSize - selfIDText.count)
        selfIDData.copyBytes(to: &mockData[2], count: selfIDData.count)
        
        // Create message and parse
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .selfID)
        
        let selfID = parser.parseSelfID(from: message!)
        XCTAssertNotNil(selfID)
        XCTAssertEqual(selfID?.selfIDType, .text)
        XCTAssertEqual(selfID?.selfIDText, selfIDText)
    }
    
    func testOperatorIDParsing() {
        // Create a mock Operator ID message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: Operator ID (5x0), Protocol version: 1 (0x1)
        mockData[0] = 0x51
        
        // Operator ID Type: Operator ID (0)
        mockData[1] = 0x00
        
        // Operator ID: "OP1234567890123456789"
        let operatorID = "OP1234567890123456789"
        let operatorIDData = operatorID.data(using: .ascii)! + Data(count: OpenDroneIDConstants.idSize - operatorID.count)
        operatorIDData.copyBytes(to: &mockData[2], count: operatorIDData.count)
        
        // Create message and parse
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .operatorID)
        
        let operatorIDObj = parser.parseOperatorID(from: message!)
        XCTAssertNotNil(operatorIDObj)
        XCTAssertEqual(operatorIDObj?.operatorIDType, .operatorID)
        XCTAssertEqual(operatorIDObj?.operatorID, operatorID)
    }
    
    func testSystemParsing() {
        // Create a mock System message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: System (4x0), Protocol version: 1 (0x1)
        mockData[0] = 0x41
        
        // Classification Type: European Union (1), Operator Location Type: Dynamic (1)
        mockData[1] = 0x05
        
        // Create message and parse
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .system)
        
        let system = parser.parseSystem(from: message!)
        XCTAssertNotNil(system)
        XCTAssertEqual(system?.classificationType, .europeanUnion)
        XCTAssertEqual(system?.operatorLocationType, .dynamic)
    }
    
    func testMessageParsingFromData() {
        // Create multiple mock messages
        let messageCount = 3
        var combinedData = Data()
        
        for i in 0..<messageCount {
            var mockData = Data(count: OpenDroneIDConstants.messageSize)
            // Set different message types
            mockData[0] = UInt8(i) << 4 | 0x01 // Message type: i, Protocol version: 1
            combinedData.append(mockData)
        }
        
        let messages = parser.parseMessages(from: combinedData)
        XCTAssertEqual(messages.count, messageCount)
        
        for (i, message) in messages.enumerated() {
            XCTAssertEqual(message.messageType.rawValue, UInt8(i))
            XCTAssertEqual(message.protocolVersion, 0x01)
        }
    }
    
    func testAuthMessageParsing() {
        // Create a mock Auth message
        var mockData = Data(count: OpenDroneIDConstants.messageSize)
        
        // Message type: Auth (2x0), Protocol version: 1 (0x1)
        mockData[0] = 0x21
        
        let message = OpenDroneIDMessage(data: mockData)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.messageType, .auth)
    }
}
