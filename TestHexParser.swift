import Foundation

// Sample hex string from the user
let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

print("=== Testing OpenDroneIDHexParser ===")
print("Hex string: \(hexStr.prefix(50))...")
print()

// Create parser instance
let hexParser = OpenDroneIDHexParser()

// Test 1: Parse all models at once
print("1. Testing parseAll() method:")
let result = hexParser.parseAll(from: hexStr)
print("   Total messages parsed: \(result.totalMessageCount)")
print("   Total models parsed: \(result.totalModelCount)")
print("   Basic IDs: \(result.basicIDs.count)")
print("   Locations: \(result.locations.count)")
print("   Self IDs: \(result.selfIDs.count)")
print("   Systems: \(result.systems.count)")
print("   Operator IDs: \(result.operatorIDs.count)")
print()

// Test 2: Parse specific model types
print("2. Testing specific model parsing:")

// Parse Basic IDs
if let basicID = hexParser.parseFirstBasicID(from: hexStr) {
    print("   ✓ Basic ID found:")
    print("     ID Type: \(basicID.idType)")
    print("     UA Type: \(basicID.uaType)")
    print("     UAS ID: \(basicID.uasID)")
} else {
    print("   ✗ No Basic ID found")
}

// Parse Location
if let location = hexParser.parseFirstLocation(from: hexStr) {
    print("   ✓ Location found:")
    print("     Status: \(location.status)")
    print("     Latitude: \(location.latitude)")
    print("     Longitude: \(location.longitude)")
    print("     Altitude Baro: \(location.altitudeBaro) m")
} else {
    print("   ✗ No Location found")
}

// Parse System
if let system = hexParser.parseFirstSystem(from: hexStr) {
    print("   ✓ System found:")
    print("     Classification: \(system.classificationType)")
    print("     UA Category: \(system.uaCategory)")
    print("     UA Class: \(system.uaClass)")
} else {
    print("   ✗ No System found")
}
print()

// Test 3: Parse all messages
print("3. Testing message parsing:")
let messages = hexParser.parseMessages(from: hexStr)
print("   Parsed \(messages.count) messages")
for (index, message) in messages.enumerated() {
    print("   Message \(index + 1): Type=\(message.messageType), Version=\(message.protocolVersion)")
}
print()

// Test 4: Demonstrate usage patterns
print("4. Usage patterns:")

// Pattern 1: Quick access to first model of each type
print("   Pattern 1 - Quick access:")
print("   if let basicID = hexParser.parseFirstBasicID(from: hexStr) {")
print("       // Use basicID")
print("   }")
print()

// Pattern 2: Process all models of a specific type
print("   Pattern 2 - Process all of specific type:")
print("   let locations = hexParser.parseLocations(from: hexStr)")
print("   for location in locations {")
print("       // Process each location")
print("   }")
print()

// Pattern 3: Comprehensive result for detailed processing
print("   Pattern 3 - Comprehensive processing:")
print("   let result = hexParser.parseAll(from: hexStr)")
print("   if !result.isEmpty {")
print("       // Process all models")
print("   }")
print()

print("=== Test Complete ===")
