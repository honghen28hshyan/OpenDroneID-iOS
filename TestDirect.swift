import Foundation

// MARK: - OpenDroneID Enums
public enum ODIDMessageType: UInt8 {
    case basicID = 0
    case location = 1
    case auth = 2
    case selfID = 3
    case system = 4
    case operatorID = 5
    case packed = 0xF
}

public enum ODIDBasicIDType: UInt8 {
    case none = 0
    case serialNumber = 1
    case caaRegistrationID = 2
    case utmAssignedUUID = 3
    case specificSessionID = 4
}

public enum ODIDUAType: UInt8 {
    case none = 0
    case aeroplane = 1
    case helicopterOrMultirotor = 2
    case gyroplane = 3
    case hybridLift = 4
    case ornithopter = 5
    case glider = 6
    case kite = 7
    case freeBalloon = 8
    case captiveBalloon = 9
    case airship = 10
    case freeFallOrParachute = 11
    case rocket = 12
    case tetheredPoweredAircraft = 13
    case groundObstacle = 14
    case other = 15
}

public enum ODIDLocationStatus: UInt8 {
    case undeclared = 0
    case ground = 1
    case airborne = 2
    case emergency = 3
    case remoteIDSystemFailure = 4
}

public enum ODIDLocationHeightType: UInt8 {
    case aboveTakeoff = 0
    case aboveGroundLevel = 1
}

public enum ODIDSelfIDType: UInt8 {
    case text = 0
    case emergency = 1
    case extendedStatus = 2
}

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

public enum ODIDOperatorIDType: UInt8 {
    case operatorID = 0
}

public struct OpenDroneIDConstants {
    public static let idSize = 20
    public static let strSize = 23
    public static let messageSize = 25
}

// MARK: - OpenDroneID Structures
public struct OpenDroneIDMessage {
    public let messageType: ODIDMessageType
    public let protocolVersion: UInt8
    public let data: Data
    
    public init?(data: Data) {
        guard data.count == OpenDroneIDConstants.messageSize else {
            return nil
        }
        
        let (messageType, protocolVersion) = data.withUnsafeBytes { buffer -> (ODIDMessageType, UInt8) in
            let rawPtr = buffer.baseAddress
            guard let ptr = rawPtr else {
                return (.packed, 0)
            }
            
            let firstByte = ptr.load(as: UInt8.self)
            let messageTypeRaw = firstByte >> 4
            let protocolVersionRaw = firstByte & 0x0F
            
            return (ODIDMessageType(rawValue: messageTypeRaw) ?? .packed, protocolVersionRaw)
        }
        
        self.messageType = messageType
        self.protocolVersion = protocolVersion
        self.data = data
    }
    
    public init?(hexString: String) {
        guard let data = Data(hexString: hexString) else {
            return nil
        }
        
        self.init(data: data)
    }
}

public struct OpenDroneIDBasicID {
    public let idType: ODIDBasicIDType
    public let uaType: ODIDUAType
    public let uasID: String
    
    public init?(message: OpenDroneIDMessage) {
        guard message.messageType == .basicID else {
            return nil
        }
        
        let data = message.data
        var messageBuffer = [UInt8](repeating: 0, count: OpenDroneIDConstants.messageSize)
        data.copyBytes(to: &messageBuffer, count: OpenDroneIDConstants.messageSize)
        
        self.idType = ODIDBasicIDType(rawValue: messageBuffer[1] >> 4) ?? .none
        self.uaType = ODIDUAType(rawValue: messageBuffer[1] & 0x0F) ?? .none
        
        let idBytes = data[2..<(2 + OpenDroneIDConstants.idSize)]
        self.uasID = String(data: idBytes, encoding: .ascii)?.cleanedForSN() ?? ""
    }
}

public struct OpenDroneIDLocation {
    public let status: ODIDLocationStatus
    public let speedMultiplier: UInt8
    public let ewDirection: UInt8
    public let heightType: ODIDLocationHeightType
    public let direction: UInt8
    public let speedHorizontal: Double
    public let speedVertical: Double
    public let latitude: Double
    public let longitude: Double
    public let altitudeBaro: Double
    public let altitudeGeo: Double
    public let height: Double
    public let horizontalAccuracy: UInt8
    public let verticalAccuracy: UInt8
    public let baroAccuracy: UInt8
    public let speedAccuracy: UInt8
    public let timestamp: String
    public let timestampAccuracy: UInt8
    
    public init?(message: OpenDroneIDMessage) {
        guard message.messageType == .location else {
            return nil
        }
        
        let data = message.data
        var messageBuffer = [UInt8](repeating: 0, count: OpenDroneIDConstants.messageSize)
        data.copyBytes(to: &messageBuffer, count: OpenDroneIDConstants.messageSize)
        
        self.status = ODIDLocationStatus(rawValue: (messageBuffer[1] >> 4) & 0x0F) ?? .undeclared
        self.speedMultiplier = messageBuffer[1] & 0x01
        self.ewDirection = (messageBuffer[1] >> 1) & 0x01
        self.heightType = ODIDLocationHeightType(rawValue: (messageBuffer[1] >> 2) & 0x01) ?? .aboveTakeoff
        self.direction = messageBuffer[2]
        
        let speedHorizontalRaw = Double(messageBuffer[3])
        self.speedHorizontal = OpenDroneIDLocation.decodeSpeedHorizontal(speedHorizontalRaw, speedMultiplier: self.speedMultiplier)
        
        let speedVerticalRaw = Double(messageBuffer[4]) * 0.5
        self.speedVertical = speedVerticalRaw == 63 ? Double.nan : speedVerticalRaw
        
        let latitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[5..<9]).withUnsafeBytes { $0.pointee }))
        let longitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[9..<13]).withUnsafeBytes { $0.pointee }))
        
        self.latitude = Double(latitudeRaw) / 10_000_000.0
        self.longitude = Double(longitudeRaw) / 10_000_000.0
        
        let altitudeBaroRaw = UInt16(littleEndian: Data(messageBuffer[13..<15]).withUnsafeBytes { $0.pointee })
        let altitudeGeoRaw = UInt16(littleEndian: Data(messageBuffer[15..<17]).withUnsafeBytes { $0.pointee })
        let heightRaw = UInt16(littleEndian: Data(messageBuffer[17..<19]).withUnsafeBytes { $0.pointee })
        
        self.altitudeBaro = Double(Int(altitudeBaroRaw) - 2000) / 2.0
        self.altitudeGeo = Double(Int(altitudeGeoRaw) - 2000) / 2.0
        self.height = Double(Int(heightRaw) - 2000) / 2.0
        
        self.horizontalAccuracy = messageBuffer[19] & 0x0F
        self.verticalAccuracy = (messageBuffer[19] >> 4) & 0x0F
        self.baroAccuracy = (messageBuffer[20] >> 4) & 0x0F
        self.speedAccuracy = messageBuffer[20] & 0x0F
        
        let timestampRaw = UInt16(littleEndian: Data(messageBuffer[21..<23]).withUnsafeBytes { $0.pointee })
        self.timestamp = OpenDroneIDLocation.decodeTimestamp(timestampRaw)
        self.timestampAccuracy = messageBuffer[23] & 0x0F
    }
    
    private static func decodeSpeedHorizontal(_ speedEncoded: Double, speedMultiplier: UInt8) -> Double {
        guard speedEncoded != 255 else {
            return Double.nan
        }
        
        if speedMultiplier == 1 {
            return (speedEncoded * 0.75) + (255 * 0.25)
        } else {
            return speedEncoded * 0.75
        }
    }
    
    private static func decodeTimestamp(_ timestamp: UInt16) -> String {
        let minutes = Int(timestamp / 10 / 60)
        let seconds = Int((timestamp - UInt16(minutes * 60 * 10)) / 10)
        let secondsDecimals = Int((timestamp - UInt16(minutes * 60 * 10)) % 10)
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, secondsDecimals)
    }
}

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
        guard message.messageType == .system else {
            return nil
        }
        
        let data = message.data
        var messageBuffer = [UInt8](repeating: 0, count: OpenDroneIDConstants.messageSize)
        data.copyBytes(to: &messageBuffer, count: OpenDroneIDConstants.messageSize)
        
        let flags = messageBuffer[1]
        
        self.classificationType = ODIDSystemClassificationType(rawValue: (flags >> 2) & 0x03) ?? .undeclared
        self.operatorLocationType = ODIDSystemOperatorLocationType(rawValue: flags & 0x03) ?? .takeOff
        
        let operatorLatitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[2..<6]).withUnsafeBytes { $0.pointee }))
        let operatorLongitudeRaw = Int(Int32(littleEndian: Data(messageBuffer[6..<10]).withUnsafeBytes { $0.pointee }))
        
        self.operatorLatitude = Double(operatorLatitudeRaw) / 10_000_000.0
        self.operatorLongitude = Double(operatorLongitudeRaw) / 10_000_000.0
        
        self.areaCount = UInt16(littleEndian: Data(messageBuffer[10..<12]).withUnsafeBytes { $0.pointee })
        self.areaRadius = messageBuffer[12]
        
        let areaCeilingRaw = Int16(littleEndian: Data(messageBuffer[13..<15]).withUnsafeBytes { $0.pointee })
        let areaFloorRaw = Int16(littleEndian: Data(messageBuffer[15..<17]).withUnsafeBytes { $0.pointee })
        
        self.areaCeiling = Double(areaCeilingRaw)
        self.areaFloor = Double(areaFloorRaw)
        
        self.uaCategory = ODIDSystemUACategory(rawValue: (messageBuffer[17] >> 4) & 0x0F) ?? .undefined
        self.uaClass = ODIDSystemUAClass(rawValue: messageBuffer[17] & 0x0F) ?? .undefined
        
        let operatorAltitudeRaw = Int16(littleEndian: Data(messageBuffer[18..<20]).withUnsafeBytes { $0.pointee })
        self.operatorAltitude = Double(Int(operatorAltitudeRaw) - 2000) / 2.0
        
        let timestampRaw = UInt32(littleEndian: Data(messageBuffer[20..<24]).withUnsafeBytes { $0.pointee })
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampRaw) + 1546300800)
        self.timestamp = timestamp
    }
}

// MARK: - Hex Parser
public class OpenDroneIDHexParser {
    
    public init() {}
    
    public func parseMessages(from hexString: String) -> [OpenDroneIDMessage] {
        // Step 1: Find FA0BBC0D pattern in hex string (case insensitive)
        let lowerHex = hexString.lowercased()
        guard let patternRange = lowerHex.range(of: "fa0bbc0d") else {
            return []
        }
        
        // Step 2: Extract bytes after the pattern
        let patternStartPos = hexString.distance(from: hexString.startIndex, to: patternRange.lowerBound)
        
        // Step 3: Extract size from bytes 14-16 after pattern (Python: bytes_str[index + 14:index+16])
        let sizeStartPos = patternStartPos + 14
        let sizeEndPos = patternStartPos + 16
        
        guard sizeEndPos <= hexString.count else {
            return []
        }
        
        let sizeHex = String(hexString[hexString.index(hexString.startIndex, offsetBy: sizeStartPos)..<hexString.index(hexString.startIndex, offsetBy: sizeEndPos)])
        guard let sizeData = Data(hexString: sizeHex) else {
            return []
        }
        
        // Convert size bytes to integer (explicit little endian to match Python)
        let size: UInt16 = sizeData.withUnsafeBytes { buffer in
            let rawPtr = buffer.baseAddress!
            return UInt16(littleEndian: rawPtr.assumingMemoryBound(to: UInt16.self).pointee)
        }
        
        // Step 4: Extract ODID bytes from byte 16 onwards after pattern (Python: bytes_str[index + 16:])
        let odidStartPos = patternStartPos + 16
        guard odidStartPos <= hexString.count else {
            return []
        }
        
        let odidHex = String(hexString[hexString.index(hexString.startIndex, offsetBy: odidStartPos)...])
        guard let odidData = Data(hexString: odidHex) else {
            return []
        }
        
        // Step 5: Parse exactly 'size' number of messages (like Python's print_message_pack)
        var messages: [OpenDroneIDMessage] = []
        let messageSize = OpenDroneIDConstants.messageSize
        
        for i in 0..<Int(size) {
            let startIndex = i * messageSize
            let endIndex = startIndex + messageSize
            
            guard endIndex <= odidData.count else {
                break
            }
            
            let messageData = Data(odidData[startIndex..<endIndex])
            if let message = OpenDroneIDMessage(data: messageData) {
                messages.append(message)
            }
        }
        
        return messages
    }
    
    public func parseBasicID(from message: OpenDroneIDMessage) -> OpenDroneIDBasicID? {
        return OpenDroneIDBasicID(message: message)
    }
    
    public func parseLocation(from message: OpenDroneIDMessage) -> OpenDroneIDLocation? {
        return OpenDroneIDLocation(message: message)
    }
    
    public func parseSystem(from message: OpenDroneIDMessage) -> OpenDroneIDSystem? {
        return OpenDroneIDSystem(message: message)
    }
    
    public func parseAll(from hexString: String) -> (basicIDs: [OpenDroneIDBasicID], locations: [OpenDroneIDLocation], systems: [OpenDroneIDSystem], allMessages: [OpenDroneIDMessage]) {
        let messages = parseMessages(from: hexString)
        
        return (
            basicIDs: messages.compactMap { parseBasicID(from: $0) },
            locations: messages.compactMap { parseLocation(from: $0) },
            systems: messages.compactMap { parseSystem(from: $0) },
            allMessages: messages
        )
    }
}

// MARK: - Extensions
extension String {
    func cleaned() -> String {
        return self.replacingOccurrences(of: "[\t\n\r]", with: "", options: .regularExpression)
    }
    
    func cleanedForSN() -> String {
        return self.replacingOccurrences(of: "[\t\n\r ]", with: "", options: .regularExpression)
    }
}

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

// MARK: - Test
func testParsing() {
    let hexData = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"
    
    print("\n=== Testing Hex Parsing ===")
    print("Hex data length: \(hexData.count)")
    
    let parser = OpenDroneIDHexParser()
    let result = parser.parseAll(from: hexData)
    
    print("\n=== TEST RESULTS ===")
    print("Total messages: \(result.allMessages.count)")
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
    if result.allMessages.count == 3 && 
       result.basicIDs.count == 1 && 
       result.locations.count == 1 && 
       result.systems.count == 1 {
        print("\n✅ SUCCESS: Parsed 3 messages as expected")
        
        if let basicID = result.basicIDs.first {
            if basicID.uasID == "1581F87LW25420023NVN" {
                print("✅ SUCCESS: Basic ID UASID matches Python output")
            } else {
                print("❌ FAILURE: Basic ID UASID doesn't match Python output")
                print("   Expected: 1581F87LW25420023NVN")
                print("   Got:      \(basicID.uasID)")
            }
        }
    } else {
        print("\n❌ FAILURE: Expected 3 messages, got \(result.allMessages.count)")
    }
}

// Run the test
testParsing()
