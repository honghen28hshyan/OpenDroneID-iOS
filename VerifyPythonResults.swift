import Foundation

// Test to verify that our Swift implementation produces the same results as the Python code

// Create a sample test that mimics the Python output
let sampleHexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

print("=== Verifying Swift Implementation Against Python Results ===")
print("Sample hex string: \(sampleHexStr.prefix(50))...")
print()

// Create parser instance
let hexParser = OpenDroneIDHexParser()

// Test 1: Parse all models
print("1. Testing parseAll() method:")
let result = hexParser.parseAll(from: sampleHexStr)
print("   Total messages: \(result.totalMessageCount)")
print("   Total models: \(result.totalModelCount)")
print()

// Test 2: Check Basic ID (should match Python output)
print("2. Verifying Basic ID:")
if let basicID = result.basicIDs.first {
    print("   ✓ Basic ID found")
    print("     ID Type: \(basicID.idType)")
    print("     UA Type: \(basicID.uaType)")
    print("     UAS ID: \(basicID.uasID)")
    
    // Compare with Python expected result
    let expectedUASID = "1581F87LW25420023WN"
    if basicID.uasID == expectedUASID {
        print("     ✅ UAS ID matches Python result: \(expectedUASID)")
    } else {
        print("     ❌ UAS ID mismatch: expected \(expectedUASID), got \(basicID.uasID)")
    }
} else {
    print("   ✗ No Basic ID found")
}
print()

// Test 3: Check Location (should match Python output)
print("3. Verifying Location:")
if let location = result.locations.first {
    print("   ✓ Location found")
    print("     Status: \(location.status)")
    print("     Latitude: \(location.latitude)")
    print("     Longitude: \(location.longitude)")
    print("     Altitude Baro: \(location.altitudeBaro)")
    print("     Altitude Geo: \(location.altitudeGeo)")
    
    // Compare with Python expected results
    let expectedLatitude = 22.723212
    let expectedLongitude = 113.80005782
    
    if abs(location.latitude - expectedLatitude) < 0.0001 {
        print("     ✅ Latitude matches Python result: \(expectedLatitude)")
    } else {
        print("     ❌ Latitude mismatch: expected \(expectedLatitude), got \(location.latitude)")
    }
    
    if abs(location.longitude - expectedLongitude) < 0.0001 {
        print("     ✅ Longitude matches Python result: \(expectedLongitude)")
    } else {
        print("     ❌ Longitude mismatch: expected \(expectedLongitude), got \(location.longitude)")
    }
} else {
    print("   ✗ No Location found")
}
print()

// Test 4: Check System (should match Python output)
print("4. Verifying System:")
if let system = result.systems.first {
    print("   ✓ System found")
    print("     UA Category: \(system.uaCategory)")
    print("     UA Class: \(system.uaClass)")
    print("     Operator Altitude: \(system.operatorAltitude)")
    
    // Compare with Python expected results
    let expectedOperatorAltitude = 55.0
    
    if abs(system.operatorAltitude - expectedOperatorAltitude) < 0.0001 {
        print("     ✅ Operator Altitude matches Python result: \(expectedOperatorAltitude)")
    } else {
        print("     ❌ Operator Altitude mismatch: expected \(expectedOperatorAltitude), got \(system.operatorAltitude)")
    }
} else {
    print("   ✗ No System found")
}
print()

// Test 5: Print all messages for debugging
print("5. All Messages Found:")
for (index, message) in result.allMessages.enumerated() {
    print("   Message \(index + 1): Type=\(message.messageType), Version=\(message.protocolVersion)")
}
print()

// Test 6: Check if we found the FA0BB0CD pattern
print("6. Checking for FA0BB0CD pattern:")
let parser = OpenDroneIDParser()
if let range = parser.findFA0BB0CDPattern(in: sampleHexStr) {
    print("   ✓ Found FA0BB0CD pattern at position: \(sampleHexStr.distance(from: sampleHexStr.startIndex, to: range.lowerBound))")
    let patternHex = String(sampleHexStr[range])
    print("   Pattern hex: \(patternHex)")
} else {
    print("   ✗ FA0BB0CD pattern not found")
}
print()

print("=== Test Complete ===")
print("If all ✅ marks are shown, the Swift implementation matches the Python output!")
