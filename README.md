# SynologyAPI

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Jaesung-Jung/SwiftSynology/blob/main/Assets/swift-synology-dark.png?raw=true">
  <img src="https://github.com/Jaesung-Jung/SwiftSynology/blob/main/Assets/swift-synology-light.png?raw=true" width="50%" alt="SwiftSynology Logo" />
</picture>
<br />
<br />
<img src="https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-333333.svg" alt="Supported Platforms: iOS, macOS, tvOS and watchOS" />
<br />
<a href="https://github.com/swiftlang/swift-package-manager" alt="RxSwift on Swift Package Manager" title="RxSwift on Swift Package Manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" /></a>
</p>

Synology NAS 장치와의 상호작용을 위한 Swift 라이브러리로, Synology NAS의 다양한 기능을 애플리케이션에 손쉽게 통합할 수 있습니다. 

`SwiftSynology`는 `Swift Concurrency`의 `actor` 및 `async`/`await` 패러다임을 활용하여 동시성 처리를 최적화한 구조로 설계되었습니다. 이를 통해 안전하고 효율적인 비동기 작업 관리가 가능하며, 동시성 관련 문제를 최소화합니다.

## 기능

QuickConnect
DiskStation
PingPong

## 설치
### [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)
Swift 패키지 관리자는 Swift 코드를 배포하는 작업을 자동화하는 도구로, Swift 컴파일러에 통합되어 있습니다.
The [Swift Package Manager](https://github.com/swiftlang/swift-package-manager) is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Swift 패키지를 설정한 후, `Package.swift`의 `dependencies` 값이나 Xcode의 패키지 목록에 Alamofire를 추가하는 것만으로 간단하게 종속성으로 추가할 수 있습니다.
Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift` or the Package list in Xcode.

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

## 사용법
### 장치연결
#### QuickConnect
`QuickConnect`는 포트 전달 규칙을 설정할 필요 없이 클라이언트 응용 프로그램이 인터넷을 통해 Synology NAS에 연결할 수 있도록 해줍니다. `SynologySwift`에서는 `QuickConnect` API를 제공하여 손쉽게 장치에 연결할 수 있도록 지원합니다.

```swift
import Synology

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

QuickConnect는 여러 연결방식을 시도하고, 우선순위가 가장 높은 것과 연결됩니다.
우선순위는 다음과 같습니다.
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

> QuickConnect는 https/http 모든 연결을 지원하지만, [NSAppTransportSecurity](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/) 설정으로 인해 http 연결이 실패할 수 있습니다.

#### 수동연결
`URL`을 사용하여 수동으로 연결할 수 있습니다.
```swift
import Synology

let diskStation = DiskStation(serverURL: <#url#>)
```

`url`을 가진 DiskStation 인스턴스만 생성하며, 연결이 올바른지 확인을 위한 `PingPong` API를 제공합니다.

```swift
import Synology

let pingPong = PingPoing()
let pong = try await pingPong.ping(to: <#url#>)
print(pong.success) // true or false (Bool)
```

### 인증
`DiskStation`의 `auth()`에는 인증을 위한 API를 제공합니다.

`SynologySwift`는 로그인이 되면 내부적으로 `sessionID`를 저장하고 API를 호출할 때, 자동으로 인증값을 포함하여 요청합니다. 인증값은 프로그램이 종료되면 사라지기 때문에 로그인을 유지하기 위해선 `Keychain`과 같은 영속성 저장소에 저장하여 사용해야 합니다.

#### 로그인
`auth().login(account:password:)`를 사용하여 로그인을 할 수 있습니다.
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

연결이 성공하면 `authorization`이 만들어지고 이 값에는 인증을 위한 `sessionID` 값이 있습니다. 인증을 유지하기 위해서 이 값을 저장하고 DiskStation 객체를 생성할 때 전달하면 됩니다.

```swift
let diskStation = DiskStation(
  serverURL: <#url#>,
  sessionID: <#sessionID#>
)
```

#### 이중인증
`DSM`은 이중인증을 지원하며 이를 위한 API를 제공하고 있습니다. 로그인 하는 계정이 이중인증을 사용하는지 여부를 먼저 알기 위해서는 `OTP` 값 없이 로그인을 시도합니다.
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

`requiredTwoFactorAuthenticationCode`오류가 발생하면 login(account:password:otp:)를 호출하여 Auth.OTP 값을 함께 전달하여야 합니다.
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

`enableDeviceToken`은 `신뢰할 수 있는 장치` 설정을 위한 값으로 true 값을 전달하고, `authorization`의 `deviceID`를 저장하여 다음 로그인 시 OTP 인증을 건너뛸 수 있습니다.
```swift
let authorization = try await diskStation.auth().login(
  account: <#account#>,
  password: <#password#>,
  deviceID: <#deviceID#> // 👈
)
```

#### 로그아웃
`logout()` API를 사용하여 디바이스에서 명시적으로 로그아웃 할 수 있습니다. 이 작업을 수행하게 되면 `DSM`에서 발행 된 `sessionID`가 만료 됩니다.
```swift
try await diskStation.logout()
```

### 시스템
`diskStation.system()`에는 `DSM` 시스템 상태 정보를 읽기 위한 API를 제공하고 있습니다.

#### System.Health
System.Health는 `hostname`, `interfaces`, `status` 그리고 `upTime` 정보를 제공합니다.
```swift
let health = try await diskStation.system().health()
```

#### System.Info
System.Info는 `model`, `serial`, `cpu`, `ram`, `firmwareVersion` 그리고 `usbDevices` 등의 정보를 제공합니다.
```swift
let info = try await diskStation.system().info()
```

#### System.StorageInfo
System.StorageInfo는 연결 된 `drive`와 `volume` 정보를 제공합니다.
```swift
let storageInfo = try await diskStation.system().storageInfo()
```

### [개인설정] (Personal Settings)
개인설정 정보를 읽기 위한 API를 제공합니다.
#### wallpaper
설정 된 wallpaper 이미지를 가져옵니다.
```swift
let wallpaperImage = try await diskStation.personalSettings().wallpaper()
```

### [NotificationCenter]
알림센터의 메시지들를 읽기 위한 API를 제공합니다.
#### SystemNotification.Message
```swift
let messages = try await diskStation.notification().messages()
```
메시지는 DSM에서 지원되는 다양한 언어로 지역화를 제공합니다. `SwiftSynology` 패키지에서는 기본적으로 `Apple System Language`값으로 `CodePage`을 자동으로 구성합니다. `DSM`에서 지원되지 않는 언어라면 기본값인 `Engligh (US)` 값으로 설정됩니다.

지원되는 언어는 다음과 같습니다.
```
English (US)
Chinese (Traditional)
Chinese (Simplified)
Korean
German
French
Italian
Spanish
Japanese
Danish
Norwegian
Swedish
Dutch
Russian
Polish
PortugueseBrazil
PortuguesePortugal
Hungarian
Turkish
Czech
```

### [FileStation]
FileStation에 관련 된 API를 제공합니다.

#### Info
`fileStation().info()`는 `FileStation` 시스템의 전반적인 정보를 제공합니다.
```swift
let info = try await diskStation.fileStation().info()
```

#### 공유 폴더
`공유 폴더`는 `DSM`에서 파일과 폴더를 저장하고 관리할 수 있는 기본 디렉토리입니다. `fileStation().sharedFolders()`를 통해 `공유 폴더` 정보를 가져올 수 있습니다.
```swift
let sharedFolders = try await diskStation.fileStation().sharedFolders()
```
##### ...Parameters
|name|type|default|description|
|----|----|-------|-----------|
|offset|Int?|nil||
|limit|Int?|nil
|sortBy|SortBy\<FileStation.SharedFolderSortAttribute\>?|nil
|additionalInfo|Set\<FileStation.SharedFolderAdditionalInfo\>?|nil
|onlyWritable|Bool|false

#### File List
파일목록을 가져오고 그 정보를 읽는 것은 `FileStation`에서 중요한 기능 중 하나입니다.
```swift
let page = try await diskStation.fileStation().files(at: <#path#>)
```
