import Foundation

// MARK: - OpenDroneID Enums (abbreviated for test)
public enum ODIDSystemClassificationType: UInt8 {
    case undeclared = 0
    case europeanUnion = 1
}

public enum ODIDSystemOperatorLocationType: UInt8 {
    case takeOff = 0
    case dynamic = 1
    case fixed = 2
}

public enum ODIDSystemUACategory: UInt8 {
    case undefined = 0
    case open = 1
    case specific = 2
    case certified = 3
}

public enum ODIDSystemUAClass: UInt8 {
    case undefined = 0
    case class0 = 1
    case class1 = 2
    case class2 = 3
    case class3 = 4
    case class4 = 5
    case class5 = 6
    case class6 = 7
}

public struct OpenDroneIDConstants {
    public static let idSize = 20
    public static let strSize = 23
    public static let messageSize = 25
}

public struct OpenDroneIDMessage {
    public let messageType: UInt8
    public let protocolVersion: UInt8
    public let data: Data
    
    public init?(data: Data) {
        guard data.count == OpenDroneIDConstants.messageSize else {
            return nil
        }
        
        let firstByte = data[0]
        self.messageType = firstByte >> 4
        self.protocolVersion = firstByte & 0x0F
        self.data = data
    }
}

// MARK: - System Struct with Fixed areaCeiling/areaFloor Calculation
public struct OpenDroneIDSystem {
    public let classificationType: ODIDSystemClassificationType
    public let operatorLocationType: ODIDSystemOperatorLocationType
    public let operatorLatitude: Double
    public let operatorLongitude: Double
    public let areaCount: UInt16
    public let areaRadius: UInt8
    public let areaCeiling: Double
    public let areaFloor: Double
    public let uaCategory: ODIDSystemUACategory
    public let uaClass: ODIDSystemUAClass
    public let operatorAltitude: Double
    public let timestamp: Date
    
    public init?(message: OpenDroneIDMessage) {
        let data = message.data
        var messageBuffer = [UInt8](repeating: 0, count: OpenDroneIDConstants.messageSize)
        data.copyBytes(to: &messageBuffer, count: OpenDroneIDConstants.messageSize)
        
        let flags = messageBuffer[1]
        
        self.classificationType = ODIDSystemClassificationType(rawValue: (flags >> 2) & 0x03) ?? .undeclared
        self.operatorLocationType = ODIDSystemOperatorLocationType(rawValue: flags & 0x03) ?? .takeOff
        
        // Safe little-endian parsing for integers
        let operatorLatitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[2..<6]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: Int32.self).pointee
        }))
        let operatorLongitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[6..<10]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: Int32.self).pointee
        }))
        
        self.operatorLatitude = Double(operatorLatitudeRaw) / 10_000_000.0
        self.operatorLongitude = Double(operatorLongitudeRaw) / 10_000_000.0
        
        self.areaCount = UInt16(littleEndian: Data(messageBuffer[10..<12]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: UInt16.self).pointee
        })
        self.areaRadius = messageBuffer[12]
        
        let areaCeilingRaw = Int16(littleEndian: Data(messageBuffer[13..<15]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: Int16.self).pointee
        })
        let areaFloorRaw = Int16(littleEndian: Data(messageBuffer[15..<17]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: Int16.self).pointee
        })
        
        // FIXED: Apply the same calculation as altitude values (subtract 2000 and divide by 2)
        self.areaCeiling = Double(Int(areaCeilingRaw) - 2000) / 2.0
        self.areaFloor = Double(Int(areaFloorRaw) - 2000) / 2.0
        
        self.uaCategory = ODIDSystemUACategory(rawValue: (messageBuffer[17] >> 4) & 0x0F) ?? .undefined
        self.uaClass = ODIDSystemUAClass(rawValue: messageBuffer[17] & 0x0F) ?? .undefined
        
        let operatorAltitudeRaw = Int16(littleEndian: Data(messageBuffer[18..<20]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: Int16.self).pointee
        })
        self.operatorAltitude = Double(Int(operatorAltitudeRaw) - 2000) / 2.0
        
        let timestampRaw = UInt32(littleEndian: Data(messageBuffer[20..<24]).withUnsafeBytes { buffer in 
            buffer.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
        })
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampRaw) + 1546300800)
        self.timestamp = timestamp
    }
}

// MARK: - Test
func testAreaCalculation() {
    // Test with the system message data from the provided hex string
    // The system message starts at byte position 75 in the odid_bytes (after the header)
    let hexData = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
    
    // Extract the FA0BBC0D pattern
    let lowerHex = hexData.lowercased()
    guard let patternRange = lowerHex.range(of: "fa0bbc0d") else {
        print("❌ FAILURE: Could not find FA0BBC0D pattern")
        return
    }
    
    let patternStartPos = hexData.distance(from: hexData.startIndex, to: patternRange.lowerBound)
    let odidStartPos = patternStartPos + 16
    let odidHex = String(hexData[hexData.index(hexData.startIndex, offsetBy: odidStartPos)...])
    
    guard let odidData = Data(hexString: odidHex) else {
        print("❌ FAILURE: Could not parse hex data")
        return
    }
    
    // Get the system message (third message, index 2)
    let messageSize = OpenDroneIDConstants.messageSize
    let systemMsgStart = 2 * messageSize
    let systemMsgEnd = systemMsgStart + messageSize
    
    guard systemMsgEnd <= odidData.count else {
        print("❌ FAILURE: System message out of bounds")
        return
    }
    
    let systemMsgData = Data(odidData[systemMsgStart..<systemMsgEnd])
    guard let systemMessage = OpenDroneIDMessage(data: systemMsgData) else {
        print("❌ FAILURE: Could not create system message")
        return
    }
    
    // Parse the system message with our fixed calculation
    guard let system = OpenDroneIDSystem(message: systemMessage) else {
        print("❌ FAILURE: Could not parse system message")
        return
    }
    
    // Verify the areaCeiling and areaFloor values
    print("Testing areaCeiling and areaFloor calculation...")
    print("areaCeiling: \(system.areaCeiling)")
    print("areaFloor: \(system.areaFloor)")
    
    if system.areaCeiling == -1000 && system.areaFloor == -1000 {
        print("✅ SUCCESS: areaCeiling and areaFloor are correctly calculated as -1000")
    } else {
        print("❌ FAILURE: Expected -1000 for both values")
    }
    
    // Verify the calculation is using the correct formula
    print("\nVerifying calculation formula...")
    print("Expected formula: (rawValue - 2000) / 2")
    
    // For areaCeiling and areaFloor, the raw values from the message should be 0
    // So (0 - 2000) / 2 = -1000
    let rawValue = 0
    let expected = Double(rawValue - 2000) / 2.0
    print("Example calculation: (\(rawValue) - 2000) / 2 = \(expected)")
}

// MARK: - Data Extension for Hex Parsing
extension Data {
    init?(hexString: String) {
        let cleanString = hexString.replacingOccurrences(of: "[^0-9a-fA-F]", with: "", options: .regularExpression)
        
        guard cleanString.count % 2 == 0 else {
            return nil
        }
        
        var data = Data()
        for i in stride(from: 0, to: cleanString.count, by: 2) {
            let startIndex = cleanString.index(cleanString.startIndex, offsetBy: i)
            let endIndex = cleanString.index(startIndex, offsetBy: 2)
            let byteString = cleanString[startIndex..<endIndex]
            
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
        }
        
        self = data
    }
}

// Run the test
testAreaCalculation()
