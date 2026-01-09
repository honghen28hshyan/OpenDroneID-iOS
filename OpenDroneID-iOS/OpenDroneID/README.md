# OpenDroneID Swift Library

A Swift implementation of the OpenDroneID standard for parsing and processing Remote ID messages from drones.

## Overview

This library provides a comprehensive implementation of the OpenDroneID standard, allowing iOS, macOS, tvOS, and watchOS applications to parse and handle Remote ID messages emitted by drones. The library supports all message types defined in the OpenDroneID specification.

## Features

- Support for all OpenDroneID message types:
  - Basic ID
  - Location
  - Authentication
  - Self ID
  - System
  - Operator ID
  - Packed messages

- Easy-to-use parsing API
- Platform-agnostic (supports iOS, macOS, tvOS, watchOS)
- No external dependencies
- Comprehensive test coverage

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/OpenDroneID-iOS.git", from: "1.0.0")
]
```

Or, in Xcode, go to `File > Add Package Dependencies` and enter the repository URL.

## Usage

### Basic Usage

```swift
import OpenDroneID

// Create a parser instance
let parser = OpenDroneIDParser()

// Parse hex string data (e.g., from Bluetooth or WiFi)
let hexString = "001234567890..." // Your OpenDroneID hex data here
if let data = parser.parseHexString(hexString) {
    // Parse messages from data
    let messages = parser.parseMessages(from: data)
    
    // Process each message
    for message in messages {
        switch message.messageType {
        case .basicID:
            if let basicID = parser.parseBasicID(from: message) {
                print("Basic ID: \(basicID.uasID)")
                print("UA Type: \(basicID.uaType)")
            }
        case .location:
            if let location = parser.parseLocation(from: message) {
                print("Location: \(location.latitude), \(location.longitude)")
                print("Altitude: \(location.altitudeBaro) m")
            }
        case .selfID:
            if let selfID = parser.parseSelfID(from: message) {
                print("Self ID: \(selfID.selfIDText)")
            }
        case .system:
            if let system = parser.parseSystem(from: message) {
                print("System: Category \(system.uaCategory), Class \(system.uaClass)")
            }
        case .operatorID:
            if let operatorID = parser.parseOperatorID(from: message) {
                print("Operator ID: \(operatorID.operatorID)")
            }
        default:
            break
        }
    }
}
```

### Finding FA0BB0CD Pattern

The library includes a helper method to find the FA0BB0CD pattern in hex strings, which is used to identify OpenDroneID messages in some protocols:

```swift
if let range = parser.findFA0BB0CDPattern(in: hexString) {
    // Process the data starting from this pattern
    let messageData = hexString[range.upperBound...]
    // Parse the message data
}
```

## Message Types

### Basic ID

Contains the basic identification information of the drone, including:
- ID Type (Serial Number, CAA Registration ID, etc.)
- UA Type (Airplane, Multirotor, etc.)
- UAS ID (Unique Identifier)

### Location

Contains the current location information of the drone:
- Status (Airborne, Ground, Emergency, etc.)
- Position (Latitude, Longitude)
- Altitude (Barometric and Geodetic)
- Speed (Horizontal and Vertical)
- Direction
- Accuracy information

### Self ID

Contains additional self-identification information:
- Self ID Type (Text, Emergency, Extended Status)
- Self ID Text

### System

Contains system information about the drone and operator:
- Classification Type
- Operator Location
- Area Information
- UA Category and Class
- Timestamp

### Operator ID

Contains the operator's identification information:
- Operator ID Type
- Operator ID

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on the OpenDroneID specification
- Inspired by the original Python implementation
