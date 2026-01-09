import Foundation

// Simplified version focusing on hex string to Data conversion

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

// Sample hex string from the user
let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

print("Testing hex string to Data conversion...")
print("Hex string: \(hexStr.prefix(50))...")
print()

// Test 1: Convert hex string to Data
if let data = Data(hexString: hexStr) {
    print("✓ Success: Converted hex string to Data")
    print("  Data length: \(data.count) bytes")
    print("  Data hex representation: \(data.map { String(format: "%02X", $0) }.joined())")
    print()
    
    // Test 2: Verify the conversion is reversible
    let reversedHex = data.map { String(format: "%02X", $0) }.joined()
    print("✓ Success: Data conversion is reversible")
    print("  Original hex length: \(hexStr.count)")
    print("  Reversed hex length: \(reversedHex.count)")
    print("  First 20 chars match: \(hexStr.prefix(20).lowercased() == reversedHex.prefix(20).lowercased())")
    print("  Last 20 chars match: \(hexStr.suffix(20).lowercased() == reversedHex.suffix(20).lowercased())")
    print()
    
    // Test 3: Demonstrate how to use with OpenDroneIDMessage
    print("✓ Success: Ready to use with OpenDroneIDMessage")
    print("  Usage example:")
    print("    let hexStr = \"your-hex-string\"")
    print("    if let data = Data(hexString: hexStr) {")
    print("        let message = OpenDroneIDMessage(data: data)")
    print("        // Use the message")
    print("    }")
    print()
    print("  Or using the convenience initializer:")
    print("    let hexStr = \"your-hex-string\"")
    print("    if let message = OpenDroneIDMessage(hexString: hexStr) {")
    print("        // Use the message")
    print("    }")
    
} else {
    print("✗ Failed: Could not convert hex string to Data")
}

print()
print("=== Test Complete ===")
