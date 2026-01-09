import Foundation

// Test that exactly matches Python's parsing flow

// Sample hex string
let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

print("=== Python Exact Match Test ===")
print("Hex string: \(hexStr.prefix(50))...")
print()

// Step 1: Find FA0BB0CD pattern
print("1. Finding FA0BB0CD pattern...")
let lowerHex = hexStr.lowercased()
if let patternRange = lowerHex.range(of: "fa0bbc0d") {
    print("   ✓ Found FA0BB0CD pattern")
    let patternPos = hexStr.distance(from: hexStr.startIndex, to: patternRange.lowerBound)
    print("   Position: \(patternPos)")
    
    // Step 2: Extract size
    print("2. Extracting size...")
    let sizeStart = patternPos + 14
    let sizeEnd = patternPos + 16
    let sizeHex = String(hexStr[hexStr.index(hexStr.startIndex, offsetBy: sizeStart)..<hexStr.index(hexStr.startIndex, offsetBy: sizeEnd)])
    print("   Size hex: \(sizeHex)")
    
    if let sizeData = Data(hexString: sizeHex) {
        let size = sizeData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) }
        print("   Parsed size: \(size)")
        
        // Step 3: Extract ODID data
        print("3. Extracting ODID data...")
        let odidStart = patternPos + 16
        let odidHex = String(hexStr[hexStr.index(hexStr.startIndex, offsetBy: odidStart)...])
        print("   ODID hex length: \(odidHex.count) characters")
        
        if let odidData = Data(hexString: odidHex) {
            print("   ODID data length: \(odidData.count) bytes")
            
            // Step 4: Parse messages
            print("4. Parsing \(size) messages...")
            let messageSize = 25
            
            for i in 0..<Int(size) {
                let start = i * messageSize
                let end = start + messageSize
                
                if end <= odidData.count {
                    let msgData = Data(odidData[start..<end])
                    let firstByte = msgData[0]
                    let msgType = firstByte >> 4
                    let protoVer = firstByte & 0x0F
                    
                    print("   Message \(i+1): Type=\(msgType), Version=\(protoVer)")
                    
                    // Check message type
                    switch msgType {
                    case 0: // Basic ID
                        print("     ✅ Basic ID message")
                        let uasIDBytes = msgData[2..<22]
                        if let uasID = String(data: uasIDBytes, encoding: .ascii)?.replacingOccurrences(of: "[ \t\n\r]", with: "", options: .regularExpression) {
                            print("     UAS ID: \(uasID)")
                        }
                    case 1: // Location
                        print("     ✅ Location message")
                    case 4: // System
                        print("     ✅ System message")
                    default:
                        print("     ❓ Unknown message type")
                    }
                }
            }
        }
    }
} else {
    print("   ✗ FA0BB0CD pattern not found")
}

print()
print("=== Test Complete ===")
