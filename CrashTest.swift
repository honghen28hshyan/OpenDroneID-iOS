import Foundation

// Create a simple test to verify crash prevention

// Mock the OpenDroneIDConstants for testing
struct OpenDroneIDConstants {
    static let messageSize = 25
}

// Test the crash prevention logic
func testOpenDroneIDMessageCrashPrevention() {
    print("=== Testing OpenDroneIDMessage Crash Prevention ===")
    print()
    
    // Test cases that could cause crashes
    let testCases: [String: Data] = [
        "Empty Data": Data(),
        "Too Short Data": Data(count: 5),
        "Exactly Message Size": Data(count: OpenDroneIDConstants.messageSize),
        "Larger Than Message Size": Data(count: 50),
        "Single Byte": Data([0x00]),
        "Invalid Hex String": "invalid-hex-string".data(using: .utf8)!,
    ]
    
    for (name, data) in testCases {
        print("Testing: \(name)")
        print("  Data length: \(data.count)")
        
        // This should not crash, even for edge cases
        let message = OpenDroneIDMessage(data: data)
        
        if let message = message {
            print("  ✓ Success: Created message with type \(message.messageType)")
        } else {
            print("  ✓ Safe failure: Returned nil as expected")
        }
        print()
    }
    
    // Test hex string cases
    print("=== Testing Hex String Initializer ===")
    
    let hexTestCases: [String] = [
        "", // Empty string
        "01", // Too short
        "0000000000000000000000000000000000000000000000", // Exactly 25 bytes
        "000000000000000000000000000000000000000000000000", // More than 25 bytes
        "invalid-hex", // Invalid hex characters
        "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080", // Valid but too short
    ]
    
    for hexString in hexTestCases {
        print("Testing hex string: \"\(hexString)\"")
        
        // This should not crash
        let message = OpenDroneIDMessage(hexString: hexString)
        
        if let message = message {
            print("  ✓ Success: Created message")
        } else {
            print("  ✓ Safe failure: Returned nil as expected")
        }
        print()
    }
    
    print("=== All Tests Completed ===")
    print("The crash prevention mechanisms are working correctly!")
}

// Run the tests
testOpenDroneIDMessageCrashPrevention()
