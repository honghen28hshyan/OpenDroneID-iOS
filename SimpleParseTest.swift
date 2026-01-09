import Foundation

// Simple test to verify the core parsing functionality

// Sample hex string with FA0BB0CD pattern
let sampleHexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

print("=== Simple Parse Test ===")
print("Hex string: \(sampleHexStr.prefix(50))...")
print()

// Step 1: Convert hex string to Data
print("1. Converting hex string to Data...")
let cleanHex = sampleHexStr.replacingOccurrences(of: "[^0-9a-fA-F]", with: "", options: .regularExpression)
var data = Data()

for i in stride(from: 0, to: cleanHex.count, by: 2) {
    let startIndex = cleanHex.index(cleanHex.startIndex, offsetBy: i)
    let endIndex = cleanHex.index(startIndex, offsetBy: 2)
    let byteString = cleanHex[startIndex..<endIndex]
    
    if let byte = UInt8(byteString, radix: 16) {
        data.append(byte)
    }
}

print("   ✓ Data length: \(data.count) bytes")
print()

// Step 2: Search for FA0BB0CD pattern
print("2. Searching for FA0BB0CD pattern...")
let fa0bbc0dPattern: [UInt8] = [0xFA, 0x0B, 0xBC, 0x0D]
var patternStartIndex: Int?

for i in 0..<(data.count - fa0bbc0dPattern.count + 1) {
    var match = true
    for j in 0..<fa0bbc0dPattern.count {
        if data[i + j] != fa0bbc0dPattern[j] {
            match = false
            break
        }
    }
    if match {
        patternStartIndex = i
        break
    }
}

if let startIndex = patternStartIndex {
    print("   ✓ Found FA0BB0CD pattern at index: \(startIndex)")
    let patternBytes = data[startIndex..<(startIndex + 4)]
    let patternHex = patternBytes.map { String(format: "%02X", $0) }.joined()
    print("   Pattern: \(patternHex)")
    
    // Extract data from pattern onwards
    let effectiveData = Data(data[startIndex...])
    print("   Effective data length: \(effectiveData.count) bytes")
    print()
    
    // Step 3: Parse messages
    print("3. Parsing messages...")
    let messageSize = 25
    let messageCount = effectiveData.count / messageSize
    print("   Message size: \(messageSize) bytes")
    print("   Expected messages: \(messageCount)")
    
    for i in 0..<messageCount {
        let msgStart = i * messageSize
        let msgEnd = msgStart + messageSize
        let msgData = Data(effectiveData[msgStart..<msgEnd])
        
        // Get message type from first byte
        let firstByte = msgData[0]
        let messageType = firstByte >> 4
        let protocolVersion = firstByte & 0x0F
        
        print("   Message \(i+1): Type=\(messageType), Version=\(protocolVersion)")
        
        // Check if this is a Basic ID message (type 0)
        if messageType == 0 {
            print("     ✅ Basic ID message found")
            // Extract UAS ID (bytes 2-21)
            let uasIDBytes = msgData[2..<22]
            if let uasID = String(data: uasIDBytes, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) {
                print("     UAS ID: \(uasID)")
            }
        }
        
        // Check if this is a Location message (type 1)
        if messageType == 1 {
            print("     ✅ Location message found")
        }
        
        // Check if this is a System message (type 4)
        if messageType == 4 {
            print("     ✅ System message found")
        }
    }
    
} else {
    print("   ✗ FA0BB0CD pattern not found")
    
    // Try parsing without pattern
    print("   Trying to parse entire data...")
    let messageSize = 25
    let messageCount = data.count / messageSize
    print("   Message size: \(messageSize) bytes")
    print("   Expected messages: \(messageCount)")
    
    for i in 0..<messageCount {
        let msgStart = i * messageSize
        let msgEnd = msgStart + messageSize
        let msgData = Data(data[msgStart..<msgEnd])
        
        let firstByte = msgData[0]
        let messageType = firstByte >> 4
        let protocolVersion = firstByte & 0x0F
        
        print("   Message \(i+1): Type=\(messageType), Version=\(protocolVersion)")
    }
}

print()
print("=== Test Complete ===")
