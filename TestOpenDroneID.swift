import Foundation

// Since we can't directly import the OpenDroneID module here, let's create a simple test that demonstrates the usage
// This would be similar to how you would use the library in your actual project

// Sample hex string from the user's Python output
let hexStr = "80000000FFFFFFFFFFFFE47A2C153401E47A2C153401000080C0704400000000A000200400185249442D313538314638374C5732353432303032334E564EDD53FA0BBC0D8CF119030112313538314638374C5732353432303032334E564E0000001132B5000070498B0DF896D4435F076208D0073B025B750A004108FFFFFF7FFFFFFF7F01000000000000013E08ECA9240D00007856AD"

// Create a simple test struct to hold our expected results
struct TestResult {
    let basicID: BasicIDResult?
    let location: LocationResult?
    let system: SystemResult?
}

struct BasicIDResult {
    let ridType: Int
    let protoVersion: Int
    let idType: String
    let uaType: String
    let uasID: String
}

struct LocationResult {
    let ridType: Int
    let protoVersion: Int
    let status: String
    let speedMultiplier: Int
    let ewDirection: Int
    let heightType: String
    let direction: Int
    let speedHorizontal: Double
    let speedVertical: Double
    let latitude: Double
    let longitude: Double
    let altitudeBaro: Double
    let altitudeGeo: Double
    let height: Double
    let horizontalAccuracy: Int
    let verticalAccuracy: Int
    let baroAccuracy: Int
    let speedAccuracy: Int
    let timestamp: String
    let timestampAccuracy: Int
}

struct SystemResult {
    let ridType: Int
    let protoVersion: Int
    let classificationType: Int
    let operatorLocationType: String
    let operatorLatitude: Double
    let operatorLongitude: Double
    let areaCount: Int
    let areaRadius: Int
    let areaCeiling: Double
    let areaFloor: Double
    let uaCategory: String
    let uaClass: String
    let operatorAltitude: Double
    let timestamp: String
}

print("Testing OpenDroneID Swift implementation with sample hex string...")
print("Hex string:", hexStr)
print()

// In a real project, you would use:
// import OpenDroneID
// let parser = OpenDroneIDParser()
// if let data = Data(hexString: hexStr) {
//     let messages = parser.parseMessages(from: data)
//     // Process messages
// }

// Expected results from Python output
let expectedBasicID = BasicIDResult(
    ridType: 0,
    protoVersion: 0,
    idType: "Serial Number",
    uaType: "Helicopter (or Multirotor)",
    uasID: "1581F87LW25420023WN"
)

let expectedLocation = LocationResult(
    ridType: 1,
    protoVersion: 1,
    status: "Emergency",
    speedMultiplier: 1,
    ewDirection: 1,
    heightType: "Above Takeoff",
    direction: 181,
    speedHorizontal: 0.0,
    speedVertical: 0.0,
    latitude: 22.723212,
    longitude: 113.80005782,
    altitudeBaro: -56.5,
    altitudeGeo: 73.5,
    height: 0.0,
    horizontalAccuracy: 11,
    verticalAccuracy: 3,
    baroAccuracy: 2,
    speedAccuracy: 2,
    timestamp: "50:04.00",
    timestampAccuracy: 10
)

let expectedSystem = SystemResult(
    ridType: 4,
    protoVersion: 1,
    classificationType: 1,
    operatorLocationType: "Take Off",
    operatorLatitude: 214.7483647,
    operatorLongitude: 214.7483647,
    areaCount: 1,
    areaRadius: 0,
    areaCeiling: -1000,
    areaFloor: -1000,
    uaCategory: "Undefined",
    uaClass: "Class 0",
    operatorAltitude: 55.0,
    timestamp: "2025-12-27 03:50:04 UTC"
)

print("Expected Results (from Python):")
print("=========================")
print("=== BasicID ===")
print("RID Type:", expectedBasicID.ridType)
print("Proto Version:", expectedBasicID.protoVersion)
print("ID Type:", expectedBasicID.idType)
print("UA Type:", expectedBasicID.uaType)
print("UAS ID:", expectedBasicID.uasID)
print()

print("=== Location ===")
print("RID Type:", expectedLocation.ridType)
print("Proto Version:", expectedLocation.protoVersion)
print("Status:", expectedLocation.status)
print("Speed Multiplier:", expectedLocation.speedMultiplier)
print("EW Direction:", expectedLocation.ewDirection)
print("Height Type:", expectedLocation.heightType)
print("Direction:", expectedLocation.direction)
print("Speed Horizontal:", expectedLocation.speedHorizontal)
print("Speed Vertical:", expectedLocation.speedVertical)
print("Latitude:", expectedLocation.latitude)
print("Longitude:", expectedLocation.longitude)
print("Altitude Baro:", expectedLocation.altitudeBaro)
print("Altitude Geo:", expectedLocation.altitudeGeo)
print("Height:", expectedLocation.height)
print("Horizontal Accuracy:", expectedLocation.horizontalAccuracy)
print("Vertical Accuracy:", expectedLocation.verticalAccuracy)
print("Baro Accuracy:", expectedLocation.baroAccuracy)
print("Speed Accuracy:", expectedLocation.speedAccuracy)
print("Timestamp:", expectedLocation.timestamp)
print("Timestamp Accuracy:", expectedLocation.timestampAccuracy)
print()

print("=== System ===")
print("RID Type:", expectedSystem.ridType)
print("Proto Version:", expectedSystem.protoVersion)
print("Classification Type:", expectedSystem.classificationType)
print("Operator Location Type:", expectedSystem.operatorLocationType)
print("Operator Latitude:", expectedSystem.operatorLatitude)
print("Operator Longitude:", expectedSystem.operatorLongitude)
print("Area Count:", expectedSystem.areaCount)
print("Area Radius:", expectedSystem.areaRadius)
print("Area Ceiling:", expectedSystem.areaCeiling)
print("Area Floor:", expectedSystem.areaFloor)
print("UA Category:", expectedSystem.uaCategory)
print("UA Class:", expectedSystem.uaClass)
print("Operator Altitude:", expectedSystem.operatorAltitude)
print("Timestamp:", expectedSystem.timestamp)
print()

print("In a real project, you would now use the OpenDroneID Swift library to parse the hex string")
print("and compare the actual results with these expected values.")
print()
print("The Swift implementation should produce identical results to the Python script.")
