import Foundation

/// A utility class for directly parsing hex strings into OpenDroneID models
public class OpenDroneIDHexParser {
    
    private let parser = OpenDroneIDParser()
    
    public init() {}
    
    /// Parses a hex string and returns all OpenDroneID messages found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDMessage objects
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
    
    /// Parses a hex string and returns all Basic ID models found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDBasicID objects
    public func parseBasicIDs(from hexString: String) -> [OpenDroneIDBasicID] {
        let messages = parseMessages(from: hexString)
        return messages.compactMap { parser.parseBasicID(from: $0) }
    }
    
    /// Parses a hex string and returns all Location models found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDLocation objects
    public func parseLocations(from hexString: String) -> [OpenDroneIDLocation] {
        let messages = parseMessages(from: hexString)
        return messages.compactMap { parser.parseLocation(from: $0) }
    }
    
    /// Parses a hex string and returns all Self ID models found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDSelfID objects
    public func parseSelfIDs(from hexString: String) -> [OpenDroneIDSelfID] {
        let messages = parseMessages(from: hexString)
        return messages.compactMap { parser.parseSelfID(from: $0) }
    }
    
    /// Parses a hex string and returns all System models found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDSystem objects
    public func parseSystems(from hexString: String) -> [OpenDroneIDSystem] {
        let messages = parseMessages(from: hexString)
        return messages.compactMap { parser.parseSystem(from: $0) }
    }
    
    /// Parses a hex string and returns all Operator ID models found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: Array of OpenDroneIDOperatorID objects
    public func parseOperatorIDs(from hexString: String) -> [OpenDroneIDOperatorID] {
        let messages = parseMessages(from: hexString)
        return messages.compactMap { parser.parseOperatorID(from: $0) }
    }
    
    /// Parses a hex string and returns a comprehensive result containing all model types
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDParsingResult containing all parsed models
    public func parseAll(from hexString: String) -> OpenDroneIDParsingResult {
        let messages = parseMessages(from: hexString)
        
        return OpenDroneIDParsingResult(
            basicIDs: messages.compactMap { parser.parseBasicID(from: $0) },
            locations: messages.compactMap { parser.parseLocation(from: $0) },
            selfIDs: messages.compactMap { parser.parseSelfID(from: $0) },
            systems: messages.compactMap { parser.parseSystem(from: $0) },
            operatorIDs: messages.compactMap { parser.parseOperatorID(from: $0) },
            allMessages: messages
        )
    }
    
    /// Parses a single OpenDroneID message from a hex string
    /// - Parameter hexString: The hex string containing a single message
    /// - Returns: OpenDroneIDMessage if parsing succeeds
    public func parseSingleMessage(from hexString: String) -> OpenDroneIDMessage? {
        guard let data = Data(hexString: hexString) else {
            return nil
        }
        return OpenDroneIDMessage(data: data)
    }
    
    /// Parses a hex string and returns the first Basic ID model found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDBasicID if found
    public func parseFirstBasicID(from hexString: String) -> OpenDroneIDBasicID? {
        return parseBasicIDs(from: hexString).first
    }
    
    /// Parses a hex string and returns the first Location model found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDLocation if found
    public func parseFirstLocation(from hexString: String) -> OpenDroneIDLocation? {
        return parseLocations(from: hexString).first
    }
    
    /// Parses a hex string and returns the first Self ID model found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDSelfID if found
    public func parseFirstSelfID(from hexString: String) -> OpenDroneIDSelfID? {
        return parseSelfIDs(from: hexString).first
    }
    
    /// Parses a hex string and returns the first System model found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDSystem if found
    public func parseFirstSystem(from hexString: String) -> OpenDroneIDSystem? {
        return parseSystems(from: hexString).first
    }
    
    /// Parses a hex string and returns the first Operator ID model found
    /// - Parameter hexString: The hex string to parse
    /// - Returns: OpenDroneIDOperatorID if found
    public func parseFirstOperatorID(from hexString: String) -> OpenDroneIDOperatorID? {
        return parseOperatorIDs(from: hexString).first
    }
}

/// A comprehensive result structure containing all parsed OpenDroneID models
public struct OpenDroneIDParsingResult {
    public let basicIDs: [OpenDroneIDBasicID]
    public let locations: [OpenDroneIDLocation]
    public let selfIDs: [OpenDroneIDSelfID]
    public let systems: [OpenDroneIDSystem]
    public let operatorIDs: [OpenDroneIDOperatorID]
    public let allMessages: [OpenDroneIDMessage]
    
    /// Total number of parsed messages
    public var totalMessageCount: Int {
        allMessages.count
    }
    
    /// Total number of parsed models across all types
    public var totalModelCount: Int {
        basicIDs.count + locations.count + selfIDs.count + systems.count + operatorIDs.count
    }
    
    /// Checks if the result contains any models
    public var isEmpty: Bool {
        totalModelCount == 0
    }
    
    /// Checks if the result contains any messages
    public var hasMessages: Bool {
        !allMessages.isEmpty
    }
}


