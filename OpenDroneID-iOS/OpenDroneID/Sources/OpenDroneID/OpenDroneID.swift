//
//  OpenDroneID.swift
//  OpenDroneID
//
//  Created by on 2026/01/09.
//

import Foundation

enum ODIDMessageType: UInt8 {
    case basicID = 0
    case location = 1
    case auth = 2
    case selfID = 3
    case system = 4
    case operatorID = 5
    case packed = 0xF
}

enum ODIDBasicIDType: UInt8 {
    case none = 0
    case serialNumber = 1
    case caaRegistrationID = 2
    case utmAssignedUUID = 3
    case specificSessionID = 4
}

enum ODIDUAType: UInt8 {
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

enum ODIDLocationStatus: UInt8 {
    case undeclared = 0
    case ground = 1
    case airborne = 2
    case emergency = 3
    case remoteIDSystemFailure = 4
}

enum ODIDLocationHeightType: UInt8 {
    case aboveTakeoff = 0
    case aboveGroundLevel = 1
}

enum ODIDSelfIDType: UInt8 {
    case text = 0
    case emergency = 1
    case extendedStatus = 2
}

enum ODIDSystemClassificationType: UInt8 {
    case undeclared = 0
    case europeanUnion = 1
}

enum ODIDSystemOperatorLocationType: UInt8 {
    case takeOff = 0
    case dynamic = 1
    case fixed = 2
}

enum ODIDSystemUACategory: UInt8 {
    case undefined = 0
    case open = 1
    case specific = 2
    case certified = 3
}

enum ODIDSystemUAClass: UInt8 {
    case undefined = 0
    case class0 = 1
    case class1 = 2
    case class2 = 3
    case class3 = 4
    case class4 = 5
    case class5 = 6
    case class6 = 7
}

enum ODIDOperatorIDType: UInt8 {
    case operatorID = 0
}

struct OpenDroneIDConstants {
    static let idSize = 20
    static let strSize = 23
    static let messageSize = 25
}

public struct OpenDroneIDMessage {
    public let messageType: ODIDMessageType
    public let protocolVersion: UInt8
    public let data: Data
    
    public init?(data: Data) {
        guard data.count >= OpenDroneIDConstants.messageSize else {
            return nil
        }
        
        let typeByte = data[0]
        self.messageType = ODIDMessageType(rawValue: typeByte >> 4) ?? .packed
        self.protocolVersion = typeByte & 0x0F
        self.data = data
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
        self.idType = ODIDBasicIDType(rawValue: data[1] >> 4) ?? .none
        self.uaType = ODIDUAType(rawValue: data[1] & 0x0F) ?? .none
        
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
        
        self.status = ODIDLocationStatus(rawValue: (data[1] >> 4) & 0x0F) ?? .undeclared
        self.speedMultiplier = data[1] & 0x01
        self.ewDirection = (data[1] >> 1) & 0x01
        self.heightType = ODIDLocationHeightType(rawValue: (data[1] >> 2) & 0x01) ?? .aboveTakeoff
        self.direction = data[2]
        
        let speedHorizontalRaw = Double(data[3])
        self.speedHorizontal = OpenDroneIDLocation.decodeSpeedHorizontal(speedHorizontalRaw, speedMultiplier: self.speedMultiplier)
        
        let speedVerticalRaw = Double(data[4]) * 0.5
        self.speedVertical = speedVerticalRaw == 63 ? Double.nan : speedVerticalRaw
        
        let latitudeRaw = Int(data[5..<9].withUnsafeBytes { $0.load(as: Int32.self) })
        let longitudeRaw = Int(data[9..<13].withUnsafeBytes { $0.load(as: Int32.self) })
        
        self.latitude = Double(latitudeRaw) / 10_000_000.0
        self.longitude = Double(longitudeRaw) / 10_000_000.0
        
        let altitudeBaroRaw = UInt16(data[13..<15].withUnsafeBytes { $0.load(as: UInt16.self) })
        let altitudeGeoRaw = UInt16(data[15..<17].withUnsafeBytes { $0.load(as: UInt16.self) })
        let heightRaw = UInt16(data[17..<19].withUnsafeBytes { $0.load(as: UInt16.self) })
        
        self.altitudeBaro = Double(Int(altitudeBaroRaw) - 2000) / 2.0
        self.altitudeGeo = Double(Int(altitudeGeoRaw) - 2000) / 2.0
        self.height = Double(Int(heightRaw) - 2000) / 2.0
        
        self.horizontalAccuracy = data[19] & 0x0F
        self.verticalAccuracy = (data[19] >> 4) & 0x0F
        self.baroAccuracy = (data[20] >> 4) & 0x0F
        self.speedAccuracy = data[20] & 0x0F
        
        let timestampRaw = UInt16(data[21..<23].withUnsafeBytes { $0.load(as: UInt16.self) })
        self.timestamp = OpenDroneIDLocation.decodeTimestamp(timestampRaw)
        self.timestampAccuracy = data[23] & 0x0F
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

public struct OpenDroneIDSelfID {
    public let selfIDType: ODIDSelfIDType
    public let selfIDText: String
    
    public init?(message: OpenDroneIDMessage) {
        guard message.messageType == .selfID else {
            return nil
        }
        
        let data = message.data
        self.selfIDType = ODIDSelfIDType(rawValue: data[1]) ?? .text
        
        let textBytes = data[2..<(2 + OpenDroneIDConstants.strSize)]
        self.selfIDText = String(data: textBytes, encoding: .ascii)?.cleaned() ?? ""
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
        let flags = data[1]
        
        self.classificationType = ODIDSystemClassificationType(rawValue: (flags >> 2) & 0x03) ?? .undeclared
        self.operatorLocationType = ODIDSystemOperatorLocationType(rawValue: flags & 0x03) ?? .takeOff
        
        let operatorLatitudeRaw = Int(data[2..<6].withUnsafeBytes { $0.load(as: Int32.self) })
        let operatorLongitudeRaw = Int(data[6..<10].withUnsafeBytes { $0.load(as: Int32.self) })
        
        self.operatorLatitude = Double(operatorLatitudeRaw) / 10_000_000.0
        self.operatorLongitude = Double(operatorLongitudeRaw) / 10_000_000.0
        
        self.areaCount = data[10..<12].withUnsafeBytes { $0.load(as: UInt16.self) }
        self.areaRadius = data[12]
        
        let areaCeilingRaw = Int16(data[13..<15].withUnsafeBytes { $0.load(as: Int16.self) })
        let areaFloorRaw = Int16(data[15..<17].withUnsafeBytes { $0.load(as: Int16.self) })
        
        self.areaCeiling = Double(areaCeilingRaw)
        self.areaFloor = Double(areaFloorRaw)
        
        self.uaCategory = ODIDSystemUACategory(rawValue: (data[17] >> 4) & 0x0F) ?? .undefined
        self.uaClass = ODIDSystemUAClass(rawValue: data[17] & 0x0F) ?? .undefined
        
        let operatorAltitudeRaw = Int16(data[18..<20].withUnsafeBytes { $0.load(as: Int16.self) })
        self.operatorAltitude = Double(Int(operatorAltitudeRaw) - 2000) / 2.0
        
        let timestampRaw = UInt32(data[20..<24].withUnsafeBytes { $0.load(as: UInt32.self) })
        // Add 01/01/2019 timestamp
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampRaw) + 1546300800)
        self.timestamp = timestamp
    }
}

public struct OpenDroneIDOperatorID {
    public let operatorIDType: ODIDOperatorIDType
    public let operatorID: String
    
    public init?(message: OpenDroneIDMessage) {
        guard message.messageType == .operatorID else {
            return nil
        }
        
        let data = message.data
        self.operatorIDType = ODIDOperatorIDType(rawValue: data[1]) ?? .operatorID
        
        let idBytes = data[2..<(2 + OpenDroneIDConstants.idSize)]
        self.operatorID = String(data: idBytes, encoding: .ascii)?.cleaned() ?? ""
    }
}

extension String {
    func cleaned() -> String {
        return self.replacingOccurrences(of: ["\t", "\n", "\r"], with: "", options: .regularExpression)
    }
    
    func cleanedForSN() -> String {
        return self.replacingOccurrences(of: ["\t", "\n", "\r", " "], with: "", options: .regularExpression)
    }
}

extension Array where Element == String {
    func joined(separator: String) -> String {
        return self.reduce("") { $0 + ($0.isEmpty ? "" : separator) + $1 }
    }
}

public class OpenDroneIDParser {
    public init() {}
    
    public func parseMessages(from data: Data) -> [OpenDroneIDMessage] {
        var messages: [OpenDroneIDMessage] = []
        
        let messageCount = data.count / OpenDroneIDConstants.messageSize
        
        for i in 0..<messageCount {
            let startIndex = i * OpenDroneIDConstants.messageSize
            let endIndex = startIndex + OpenDroneIDConstants.messageSize
            
            guard endIndex <= data.count else {
                continue
            }
            
            let messageData = data[startIndex..<endIndex]
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
    
    public func parseSelfID(from message: OpenDroneIDMessage) -> OpenDroneIDSelfID? {
        return OpenDroneIDSelfID(message: message)
    }
    
    public func parseSystem(from message: OpenDroneIDMessage) -> OpenDroneIDSystem? {
        return OpenDroneIDSystem(message: message)
    }
    
    public func parseOperatorID(from message: OpenDroneIDMessage) -> OpenDroneIDOperatorID? {
        return OpenDroneIDOperatorID(message: message)
    }
    
    public func findFA0BB0CDPattern(in hexString: String) -> Range<String.Index>? {
        return hexString.lowercased().range(of: "fa0bbc0d")
    }
    
    public func parseHexString(_ hexString: String) -> Data? {
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
        
        return data
    }
}
