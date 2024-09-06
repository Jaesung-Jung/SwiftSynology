<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jaesung-Jung/SwiftSynology/blob/main/Assets/swift-synology-dark.png?raw=true">
  <img src="https://github.com/Jaesung-Jung/SwiftSynology/blob/main/Assets/swift-synology-light.png?raw=true" width="50%" alt="SwiftSynology Logo" />
</picture>
<br />
<br />
<img src="https://img.shields.io/badge/platforms-iOS 13+%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-333333.svg" alt="Supported Platforms: iOS, macOS, tvOS and watchOS" />
<br />
<a href="https://github.com/swiftlang/swift-package-manager" alt="RxSwift on Swift Package Manager" title="RxSwift on Swift Package Manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" /></a>

<p align="center"><a href="https://github.com/Jaesung-Jung/SwiftSynology/blob/main/README_KO.md">한국어</a></p>
</p>

`SwiftSynology` is a Swift library that facilitates interaction with `Synology NAS` devices, making it easy to integrate various `Synology NAS` functionalities into applications. The library is designed with a structure optimized for concurrency handling by leveraging `Swift Concurrency`’s `actor` and `async`/`await` paradigms. This ensures safe and efficient asynchronous operations while minimizing concurrency-related issues.

## Install
### [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)
The [Swift Package Manager](https://github.com/swiftlang/swift-package-manager) is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Once you have your Swift package set up, adding `SwiftSynology` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.
```swift
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(url: "https://github.com/Jaesung-Jung/SwiftSynology.git", .upToNextMajor(from: "0.2.0"))
  ],
  targets: [
    .target(
      name: "YourProject",
      dependencies: [
        .product(name: "Synology", package: "SwiftSynology")
      ]
    )
  ]
)
```
<br/>

## Usage
### Create a DiskStation
The first step is to create a `DiskStation` object. `DiskStation` is an abstraction layer for interacting with `DSM`. To create a `DiskStation`, you can either use `QuickConnect` to automatically find the `URL`, or explicitly provide the `URL`.

#### Use QuickConnect
`QuickConnect` allows client applications to connect to `DSM` over the internet without the need to configure port forwarding rules. `SynologySwift` provides a `QuickConnect` API that offers an easy way to discover devices.
```swift
do {
  let quickConnect = QuickConnect()
  let diskStation = try await quickConnect.connect(id: <#QuickConnectID#>)
} catch {
  switch error {
  case QuickConnectError.availableServerNotFound:
    print("Available server not found")
  default:
    print("Network or other errors")
  }
}
```

`QuickConnect` attempts multiple connection methods and connects to the one with the highest priority.
```
<QuickConnect Priority>
- https
- Connection Type
  Smart DNS LAN IPv4
  Smart DNS LAN IPv6
  LAN IPv4
  LAN IPv6
  FQDN
  DDNS
  Smart DNS Host
  Smart DNS WAN IPv6
  Smart DNS WAN IPv4
  WAN IPv6
  WAN IPv4
- Dynamic Port
```

> QuickConnect supports both HTTPS and HTTP connections, but HTTP connections may fail due to [NSAppTransportSecurity](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/) configuration.

#### Use URL
You can create a `DiskStation` object by providing a `URL`.
```swift
let diskStation = DiskStation(serverURL: <#url#>)
```

Unlike `QuickConnect`, when using a URL, you need to manually check the connection availability to the DSM. To test the DSM connection status, the `PingPong` API is provided.
```swift
let pingPong = PingPoing()
let pong = try await pingPong.ping(to: <#url#>)
print(pong.success) // true or false (Bool)
```

#### Localization
DSM supports multiple languages, and by passing a `CodePage` value, the strings are configured according to the selected language. By default, the `SwiftSynology` package automatically configures the `CodePage` by reading the system language settings.

The supported languages are as follows, and you can pass the `CodePage` value when creating a `DiskStation` instance.
```swift
public enum CodePage {
  case englishUS          // English (US)
  case chineseTraditional // Chinese (Traditional)
  case chineseSimplified  // Chinese (Simplified)
  case korean             // Korean
  case german             // German
  case french             // French
  case italian            // Italian
  case spanish            // Spanish
  case japanese           // Japanese
  case danish             // Danish
  case norwegian          // Norwegian
  case swedish            // Swedish
  case dutch              // Dutch
  case russian            // Russian
  case polish             // Polish
  case portugueseBrazil   // PortugueseBrazil
  case portuguesePortugal // PortuguesePortugal
  case hungarian          // Hungarian
  case turkish            // Turkish
  case czech              // Czech
}

// Use QuickConnect
let diskStation = QuickConnect().connect(id: <#QuickConnectID#>, codePage: .englishUS)

// Use URL
let diskStation = DiskStation(serverURL: <#url#>, codePage: .englishUS)
```
<br/>

### Auth
The `auth()` function in `DiskStation` provides APIs for authentication.
<br/>
`SynologySwift` stores the `sessionID` internally upon a successful login and automatically includes the authentication token when making API requests.
> 💡 Since the `sessionID` is lost when the program terminates, it should be stored in a persistent storage like `Keychain` to maintain the login session. Further details are explained below.

#### Login
You can perform a login using the `auth().login(account:password:)` API.
```swift
do {
  let authorization = try await diskStation.auth().login(
    account: <#account#>,
    password: <#password#>
  )
} catch let error as AuthError where error == .noSuchAccountOrIncorrectPassword {
  // No such account or incorrect password
} catch {
  // Network or other errors
}
```

When the connection is successful, an `Authorization` is generated, which contains the `sessionID` for authentication. To maintain the authentication, store this value and provide it when creating the `DiskStation` object.
```swift
let diskStation = DiskStation(
  serverURL: <#url#>,
  sessionID: <#sessionID#> // 👈
)
```

#### Two-Factor Authentication
`DSM` supports two-factor authentication and provides an API for it. To determine if the account requires two-factor authentication, you should attempt to log in without an `OTP` value first.
```swift
do {
  let authorization = try await diskStation.auth().login(
    account: <#account#>,
    password: <#password#>
  )
} catch let error as AuthError where error == .requiredTwoFactorAuthenticationCode {
  // Required two factor authentication code
}
```

If a `requiredTwoFactorAuthenticationCode` error occurs, you need to call `login(account:password:otp:)` and provide the `Auth.OTP` value.
```swift
do {
  let authorization = try await diskStation.auth().login(
    account: <#account#>,
    password: <#password#>,
    otp: Auth.OTP(code: <#otp#>, enableDeviceToken: true)
  )
} catch let error as AuthError where error == .incorrectTwoFactorAuthenticationCode {
  // Incorrect two factor authentication code
}
```

`enableDeviceToken` is a value used to set a `trusted device`. By passing true and storing the `deviceID` from the `Authorization`, you can skip OTP authentication on subsequent logins.
```swift
let authorization = try await diskStation.auth().login(
  account: <#account#>,
  password: <#password#>,
  deviceID: <#deviceID#> // 👈
)
```

#### Logout
You can explicitly log out from the device using the `logout()` API. Performing this action will invalidate the `sessionID` issued by DSM.
```swift
try await diskStation.logout()
```
<br/>

### System
`system()` provides an API to retrieve the DSM system status information.

#### Health
You can use `system().health()` to retrieve basic information and the status of the DSM.
```swift
let health = try await diskStation.system().health()
```
###### ... System.Health
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|Host name of the DSM|
|interfaces|Array<System.Health.Interface>|Network interface of the device|
|status|System.Health.Status|Device status (`danger`\|`attention`\|`normal`)|
|upTime|TimeInterval|Elapsed time since the device was booted|
###### ... System.Health.Interface
|Property|Type|Description|
|--------|----|-----------|
|id|String|Interface ID|
|ip|String|IP Address|
|type|String|Interface Type|


#### Info
You can use `system().info()` to retrieve detailed information about the device.
```swift
let info = try await diskStation.system().info()
```
###### ... System.Info
|Property|Type|Description|
|--------|----|-----------|
|model|String|Device model name|
|serial|String|Device serial number|
|cpu|System.Info.CPU|CPU info|
|ram|Int|RAM capacity|
|firmwareVersion|String|Firmware version|
|supportsESATA|Bool|ESATA support status|
|ntpEnabled|Bool|NTP usage status|
|ntpServer|String|NTP server name|
|temperature|Int|Device temperature|
|temperatureWarning|Bool|Temperature warning status|
|upTime|TimeInterval|Elapsed time since the device was booted|
|usbDevices|Array<System.Info.USB>|Connected USB devices|
###### ... System.Info.CPU
|Property|Type|Description|
|--------|----|-----------|
|clockSpeed|Int|CPU clock speed (hz)|
|coreCount|Int|Number of cpu cores|
|vendor|String|CPU vendor|
|family|String|CPU brand|
|series|String|CPU model|
###### ... System.Info.USB
|Property|Type|Description|
|--------|----|-----------|
|cls|String|Device class|
|pid|String|Device ID|
|vendor|String|Device vendor|
|product|String|Device name|
|rev|String|Revision|
|vid|String|

#### StorageInfo
You can use `system().storageInfo()` to retrieve detailed information about the connected storage devices.
```swift
let storageInfo = try await diskStation.system().storageInfo()
```
###### ... System.StorageInfo
|Property|Type|Description|
|--------|----|-----------|
|drives|Array<System.StorageInfo.Drive>|Drive info|
|volumes|Array<System.StorageInfo.Volume>|Volume info|
###### ... System.StorageInfo.Drive
|Property|Type|Description|
|--------|----|-----------|
|order|Int|Order|
|no|String|Disk number|
|path|String|Disk path|
|type|String|Disk type|
|capacity|UInt64|Disk capacity|
|model|String|Disk model name|
|status|String|Disk status|
|temp|Int|Disk temperature|

###### ... System.StorageInfo.Volume
|Property|Type|Description|
|--------|----|-----------|
|name|String|Volume name|
|volumeName|String|Volume name|
|type|String|Volume type|
|status|String|Volume status|
|usedSize|UInt64|Volume used capacity|
|totalSize|UInt64|Volume capacity|

<br/>

### Personal Settings
Provides an API to retrieve personal settings.
#### Wallpaper
Retrieves the `background image` set in DSM.
```swift
let wallpaperImage = try await diskStation.personalSettings().wallpaper()
// Returns either [UIImage] or [NSImage] depending on the platform.
```
<br/>

### Notification
Provides an API to read messages from the Notification Center. The messages are localized based on the configured `CodePage` value.
<br/>
[👉 Configure CodePage](#Localization)

#### Messages
```swift
let messages = try await diskStation.notification().messages()
```
###### ... SystemNotification.Message
|Property|Type|Description|
|--------|----|-----------|
|className|String|Message class|
|level|SystemnNotification.Level|Message level(`info`\|`warning`\|`error`\|`unknown`)|
|date|Date|Receive date|
|title|String|Message title|
|detail|String|Message content|

### FileStation
The `FileStation` API provides an interface with `offset` and `limit` parameters for handling a large number of files. In `SwiftSynology`, this is represented by a `Page` structure.
```swift
public struct Page<Element> {
  public let offset: Int
  public let totalCount: Int
  public let elements: [Element]
  public var isAtEnd: Bool
}
```
`Page` implements `Sequence`, `Collection`, and `BidirectionalCollection`, allowing you to leverage the functionalities provided by `Swift Collection`.

#### Info
`fileStation().info()` provides overall information about the `FileStation` service.
```swift
let info = try await diskStation.fileStation().info()
```
###### ... FileStation.Info
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|Host name of the DSM|
|isManager|Bool|Administrator status|
|supportFileRequest|Bool|File request support status|
|supportFileSharing|Bool|File share support status|
|supportVirtualProtocols|Array<String>|List of supported Virtual Protocols|
|systemCodepage|CodePage?|System code page|

#### Shared Folder
A `shared folder` is the primary directory in DSM for storing and managing files and folders. You can retrieve information about shared folders using `fileStation().sharedFolders()`.
```swift
// Fetch all shared folders
let sharedFolders = try await diskStation.fileStation().sharedFolders()

// Fetch shared folders, limited to 10
let sharedFolders = try await diskStation.fileStation().sharedFolders(offset: 0, limit: 10)
// Next Page
let sharedFolders = try await diskStation.fileStation().sharedFolders(offset: 10, limit: 10)

// Fetch shared folders, sort by name (ascending)
let sharedFolders = try await diskStation.fileStation().sharedFolders(sortBy: .ascending(.name))
// Fetch shared folders, sort by name (dscdescending)
let sharedFolders = try await diskStation.fileStation().sharedFolders(sortBy: .dscdescending(.name))

// Fetch shared folders with additional info
let sharedFolders = try await diskStation.fileStation().sharedFolders(additionalInfo: [.time, .volumeStatus])
```
###### ... Parameters
|name|type|default|description|
|----|----|-------|-----------|
|offset|Int?|nil|Request offset|
|limit|Int?|nil|Maximum count of request|
|sortBy|SortBy\<FileStation.SharedFolderSortAttribute\>?|nil|Sorting method|
|additionalInfo|Set\<FileStation.SharedFolderAdditionalInfo\>?|nil|Additional info|
|onlyWritable|Bool|false|Filter only folders with write permissions|

###### ... FileStation.SharedFolder
|Property|Type|Description|
|--------|----|-----------|
|name|String|Name of shared folder|
|path|String|Relative path|
|absolutePath|String?|Absolute path (`SharedFolderAdditionalInfo.absolutePath` is required when making a request.)|
|mountPointType|String?|Mount point type (`SharedFolderAdditionalInfo.mountPointType` is required when making a request.)|
|owner|FileStation.Owner?|File owner (`SharedFolderAdditionalInfo.owner` is required when making a request.)|
|dates|FileStation.Dates?|File `creation`, `modification`, `change`, and `access` time info (`SharedFolderAdditionalInfo.time` is required when making a request.)|
|permission|FileStation.Permission?|File permission info (`SharedFolderAdditionalInfo.permission` is required when making a request.)|
|isReadOnly|Bool?|Read-only status (`SharedFolderAdditionalInfo.volumeStatus` is required when making a request.)|
|freeSpace|UInt64?|Available space (`SharedFolderAdditionalInfo.volumeStatus` is required when making a request.)|
|totalSpace|UInt64?|Total space (`SharedFolderAdditionalInfo.volumeStatus` is required when making a request.)|
|usesSpace|UInt64?|Used space (`SharedFolderAdditionalInfo.volumeStatus` is required when making a request.)|

#### File
In `SynologySwift`, files and directories are represented as `FileStation.File`. The package supports operations such as file listing, directory creation, renaming, moving, copying, deleting, directory size calculation, and MD5 hash computation.

The following is a simple example of retrieving a file list.
```swift
// Fetch all files
let files = try await diskStation.fileStation().files(at: <#path#>)

// Fetch files, limited to 10
let files = try await diskStation.fileStation().files(at: <#path#>, offset: 0, limit: 10)
// Next Page
let files = try await diskStation.fileStation().files(at: <#path#>, offset: 10, limit: 10)

// Fetch files, sort by name (ascending)
let files = try await diskStation.fileStation().files(at: <#path#>, sortBy: .ascending(.name))
// Fetch files, sort by name (dscdescending)
let files = try await diskStation.fileStation().files(at: <#path#>, sortBy: .dscdescending(.name))

// Fetch shared folders with additional info
let files = try await diskStation.fileStation().files(at: <#path#>, additionalInfo: [.time, .size])
```
###### ... Parameters
|name|type|default|description|
|----|----|-------|-----------|
|path|String|-|path|
|pattern|String?|nil|filter pattern(`Glob Pattern`)|
|offset|Int?|nil|Request offset|
|limit|Int?|nil|Maximum count of request|
|sortBy|SortBy\<FileStation.FileSortAttribute\>?|nil|Sorting method|
|additionalInfo|Set\<FileStation.FileAdditionalInfo\>?|nil|Additional info|
|type|FileStation.FileTypeFilter|nil|`.fileOnly` \| `.directoryOnly`|

###### ... FileStation.File
|Property|Type|Description|
|--------|----|-----------|
|name|String|Name of the file|
|path|String|Relative path|
|isDirectory|Bool|Directory status|
|isValid|Bool|Validation status|
|fileExtension|String|File extension|
|size|UInt64?|File size (`FileAdditionalInfo.size` is required when making a request.)|
|absolutePath|String?|Absolute path (`FileAdditionalInfo.absolutePath` is required when making a request.)|
|mountPointType|String?|Mount point type (`FileAdditionalInfo.mountPointType` is required when making a request.)|
|owner|FileStation.Owner?|File owner (`FileAdditionalInfo.owner` is required when making a request.)|
|dates|FileStation.Dates?|File `creation`, `modification`, `change`, and `access` time info (`FileAdditionalInfo.time` is required when making a request.)|
|permission|FileStation.Permission?|File permission info (`FileAdditionalInfo.permission` is required when making a request.)|

#### ShareLink
ShareLink is a service that allows you to easily share files or folders stored on a Synology NAS. By sharing the URL or QR code of the ShareLink with others, they can download the selected files or folders regardless of whether they have a DSM account.
<br/>
This package supports operations such as `listing`, `creating`, `editing`, and `deleting` ShareLinks.

The following is a simple example of creating a ShareLink.
```swift
let shareLink = try await diskStation.fileStation().createShareLink(path: <#filePath#>)
```
###### ... Parameters
|name|type|default|description|
|----|----|-------|-----------|
|path|String|-|File path|
|password|String|nil|Share password|
|availableDate|Date|nil|Availabel date|
|expiredDate|Date|nil|Expired date|

###### ... FileStation.ShareLink
|Property|Type|Description|
|--------|----|-----------|
|id|String|Link ID|
|url|URL|Link URL|
|qrcode|String|QR Code(Base64 encoded)|
|name|String|File name|
|path|String|File path|
|isDirectory|Bool|Directory status|
|status|FileStation.ShareLink.Status|Lin status|
|hasPassword|Bool|Password requirement status|
|owner|String|File owner|
|availableDate|String|Available date (yyyy-MM-dd HH:mm:ss)|
|expiredDate|String|Expired date (yyyy-MM-dd HH:mm:ss)|

#### Background Task
Operations such as copying, compression, or MD5 hash computation in FileStation can take a long time. These tasks are classified as BackgroundTasks and managed internally by DSM. In this package, the `BackgroundTask<Completed, Processing>` is abstracted as an actor, allowing continuous status monitoring using a polling method. `BackgroundTask.status()` returns the status via an `AsyncThrowingStream` at intervals specified by `pollingInterval` until the task is completed.

The following is an example of using `BackgroundTask` for the `copy`.
```swift
let task = try await diskStation.fileStation()
  .copy(
    filesPaths: [<#filePath#>],
    destinationFilePath: <#destinationFilePath#>,
    overwrite: true
  )

for try await status in try await task.status(pollingInterval: .seconds(1)) {
  switch status {
  case .processing(let progress):
    print("😄 \(progress)")
  case .completed:
    print("😄 completed")
  }
}
```

### DownloadStation
#### WIP

## License
MIT license. See [LICENSE](https://github.com/Jaesung-Jung/SwiftSynology/blob/main/LICENSE) for details.
