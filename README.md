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

## 목차
### [Install Guide](#설치)
### [Usage](#사용법)
### [License](#라이센스)

## 설치
### [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)
Swift 패키지 관리자는 Swift 코드를 배포하는 작업을 자동화하는 도구로, Swift 컴파일러에 통합되어 있습니다.
The [Swift Package Manager](https://github.com/swiftlang/swift-package-manager) is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Swift 패키지를 설정한 후, `Package.swift`의 `dependencies` 값이나 Xcode의 패키지 목록에 `SwiftSynology`를 추가하는 것만으로 간단하게 종속성으로 추가할 수 있습니다.
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

## 사용법
### 연결 생성
시작은 `DiskStation` 객체를 생성하는 것입니다. DiskStation은 `DSM`과 상호작용을 위한 추상화입니다. `DiskStation`을 생성하기 위해서는 `QuickConnect`를 이용하여 자동으로 `URL`을 찾거나, 명시적으로 `URL`을 전달할 수 있습니다.

#### QuickConnect 사용
`QuickConnect`는 포트 전달 규칙을 설정할 필요 없이 클라이언트 응용 프로그램이 인터넷을 통해 Synology NAS에 연결할 수 있도록 해줍니다. `SynologySwift`에서는 `QuickConnect` API를 제공하여 손쉽게 장치를 검색할 수 있는 기능을 제공합니다.

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

`QuickConnect`는 여러 연결방식을 시도한 후, 우선순위가 가장 높은 것과 연결됩니다.
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

#### URL 사용
`URL`을 전달하여 `DiskStation`을 생성할 수 있습니다.
```swift
let diskStation = DiskStation(serverURL: <#url#>)
```

`QuickConnect`와 다르게 `URL`을 통한 `DiskStation` 연결 가능여부를 수동으로 확인해야 합니다. `DSM` 연결 상태를 테스트 하기 위해 `PingPong` API를 제공합니다.

```swift
let pingPong = PingPoing()
let pong = try await pingPong.ping(to: <#url#>)
print(pong.success) // true or false (Bool)
```

#### 지역화
`DSM`은 여러 언어를 지원하며 `CodePage` 값을 전달하면 문자열들이 언어에 맞추어 전달됩니다. 기본적으로 `SwiftSynology` 패키지 내에서는 `Apple System Language` 값을 읽어 `CodePage`를 자동으로 구성합니다.

지원되는 언어는 다음과 같으며, `DiskStation` 인스턴스를 생성할 때, `CodePage`를 전달할 수 있습니다.
```swift
public enum CodePage {
  case englishUS // English (US)
  case chineseTraditional // Chinese (Traditional)
  case chineseSimplified // Chinese (Simplified)
  case korean // Korean
  case german // German
  case french // French
  case italian // Italian
  case spanish // Spanish
  case japanese // Japanese
  case danish // Danish
  case norwegian // Norwegian
  case swedish // Swedish
  case dutch // Dutch
  case russian // Russian
  case polish // Polish
  case portugueseBrazil // PortugueseBrazil
  case portuguesePortugal // PortuguesePortugal
  case hungarian // Hungarian
  case turkish // Turkish
  case czech // Czech
}

// Use QuickConnect
let diskStation = QuickConnect().connect(id: <#QuickConnectID#>, codePage: .englishUS)

// Use URL
let diskStation = DiskStation(serverURL: <#url#>, codePage: .englishUS)
```

### 인증
`DiskStation`의 `auth()`에는 인증을 위한 API를 제공합니다.

`SynologySwift`는 로그인이 성공하면 내부적으로 `sessionID`를 보관하고 API를 호출할 때, 자동으로 인증값을 포함하여 요청합니다.

> 💡 `sessionID`는 프로그램이 종료되면 사라지기 때문에 로그인을 유지하기 위해선 `Keychain`과 같은 영속성 저장소에 저장하여 사용해야 합니다. 자세한 내용은 아래에서 다시 설명합니다.

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

연결이 성공하면 `Authorization`이 만들어지고 이 값에는 인증을 위한 `sessionID` 값이 있습니다. 인증을 유지하기 위해서 이 값을 저장하고 DiskStation 객체를 생성할 때 전달하면 됩니다.
```swift
let diskStation = DiskStation(
  serverURL: <#url#>,
  sessionID: <#sessionID#> // 👈
)
```

#### 이중인증
`DSM`은 이중인증을 지원하며 이를 위한 API를 제공하고 있습니다. 로그인 하려는 계정이 이중인증을 사용하는지 여부를 먼저 알기 위해서는 `OTP` 값 없이 로그인을 시도합니다.
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

`requiredTwoFactorAuthenticationCode`오류가 발생하면 login(account:password:otp:)를 호출하여 `Auth.OTP` 값을 함께 전달하여야 합니다.
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

#### Health
`system().health()`를 사용하여 `DSM`의 간단한 정보 및 상태를 읽을 수 있습니다.
```swift
let health = try await diskStation.system().health()
```
###### ... System.Health
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|`DSM`의 호스트이름|
|interfaces|Array<System.Health.Interface>|장치의 Network 인터페이스 정보|
|status|System.Health.Status|장치의 상태 (`danger`\|`attention`\|`normal`)|
|upTime|TimeInterval|장치가 부팅된 후 경과한 시간|
###### ... System.Health.Interface
|Property|Type|Description|
|--------|----|-----------|
|id|String|인터페이스 ID|
|ip|String|IP 주소|
|type|String|인터페이스 Type|


#### Info
`system().info()`를 사용하여 장치의 상세한 정보를 읽을 수 있습니다.
```swift
let info = try await diskStation.system().info()
```
###### ... System.Info
|Property|Type|Description|
|--------|----|-----------|
|model|String|디바이스 모델명|
|serial|String|디바이스 시리얼번호|
|cpu|System.Info.CPU|CPU 정보|
|ram|Int|RAM 용량|
|firmwareVersion|String|Firmware 버전|
|supportsESATA|Bool|ESATA 지원여부|
|ntpEnabled|Bool|NTP 사용여부|
|ntpServer|String|NTP 서버|
|temperature|Int|장치 온도|
|temperatureWarning|Bool|온도로 인한 문제여부|
|upTime|TimeInterval|장치가 부팅된 후 경과한 시간|
|usbDevices|Array<System.Info.USB>|연결 된 USB 장치 정보|
###### ... System.Info.CPU
|Property|Type|Description|
|--------|----|-----------|
|clockSpeed|Int|클럭속도 (hz)|
|coreCount|Int|코어 개수|
|vendor|String|CPU 제조사|
|family|String|CPU 브랜드명|
|series|String|CPU 모델명|
###### ... System.Info.USB
|Property|Type|Description|
|--------|----|-----------|
|cls|String|
|pid|String|장치 ID|
|vendor|String|장치 제조사|
|product|String|장치 이름|
|rev|String|Revision|
|vid|String|

#### StorageInfo
`system().storageInfo()`를 사용하여 연결 된 저장장치의 상세한 정보를 읽을 수 있습니다.
```swift
let storageInfo = try await diskStation.system().storageInfo()
```
###### ... System.StorageInfo
|Property|Type|Description|
|--------|----|-----------|
|drives|Array<System.StorageInfo.Drive>|드라이브 정보|
|volumes|Array<System.StorageInfo.Volume>|볼륨 정보|
###### ... System.StorageInfo.Drive
|Property|Type|Description|
|--------|----|-----------|
|order|Int|순서|
|no|String|디스크 번호|
|path|String|디스크 경로|
|type|String|디스크 타입|
|capacity|UInt64|디스크 용량|
|model|String|모델명|
|status|String|상태|
|temp|Int|온도|

###### ... System.StorageInfo.Volume
|Property|Type|Description|
|--------|----|-----------|
|name|String|이름|
|volumeName|String|볼륨 이름|
|type|String|볼륨 타입|
|status|String|상태|
|usedSize|UInt64|사용 용량|
|totalSize|UInt64|전체 용량|

### [개인설정] (Personal Settings)
개인설정 정보를 읽기 위한 API를 제공합니다.
#### Wallpaper
`DSM`에 설정 된 배경화면 이미지를 가져옵니다.
```swift
let wallpaperImage = try await diskStation.personalSettings().wallpaper()
// 플랫폼에 따라 UIImage 또는 NSImage를 리턴합니다.
```

### [Notification]
알림센터의 메시지들를 읽기 위한 API를 제공합니다. 메시지는 설정 된 `CodePage` 값으로 지역화 된 문자열을 읽어 옵니다. [👉 CodePage 구성](#지역화)

#### SystemNotification.Message
```swift
let messages = try await diskStation.notification().messages()
```
###### ... SystemNotification.Message
|Property|Type|Description|
|--------|----|-----------|
|className|String|종류|
|level|SystemnNotification.Level|레벨(`info`\|`warning`\|`error`\|`unknown`)|
|date|Date|날짜|
|title|String|타이틀|
|detail|String|내용|

### [FileStation]
`FileStation` API는 많은 파일을 다루기 위해 `offset`과 `limit`로 구성 된 인터페이스를 제공하고 있습니다. `SwiftSynology`에서는 이 단위를 `Page`라는 구조체로 표현하고 있습니다.
```swift
public struct Page<Element> {
  public let offset: Int
  public let totalCount: Int
  public let elements: [Element]
  public var isAtEnd: Bool
}
```
`Page`는 `Sequence`, `Collection`, 그리고 `BidirectionalCollection`을 구현하여, `Swift Collection`에서 제공되는 기능들을 활용할 수 있습니다.

#### Info
`fileStation().info()`는 `FileStation` 시스템의 전반적인 정보를 제공합니다.
```swift
let info = try await diskStation.fileStation().info()
```
###### ... FileStation.Info
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|`DSM`의 호스트이름|
|isManager|Bool|관리자 여부|
|supportFileRequest|Bool|File 요청 지원여부|
|supportFileSharing|Bool|File 공유 지원여부|
|supportVirtualProtocols|Array<String>|지원되는 Virtual Protocol 목록|
|systemCodepage|CodePage?|시스템 `CodePage`|

#### 공유 폴더
`공유 폴더`는 `DSM`에서 파일과 폴더를 저장하고 관리할 수 있는 기본 디렉토리입니다. `fileStation().sharedFolders()`를 통해 `공유 폴더` 정보를 가져올 수 있습니다.
```swift
let sharedFolders = try await diskStation.fileStation().sharedFolders()
```
###### ... Parameters
|name|type|default|description|
|----|----|-------|-----------|
|offset|Int?|nil|요청 오프셋|
|limit|Int?|nil|요청 최대 개수|
|sortBy|SortBy\<FileStation.SharedFolderSortAttribute\>?|nil|정렬 방식|
|additionalInfo|Set\<FileStation.SharedFolderAdditionalInfo\>?|nil|추가 정보|
|onlyWritable|Bool|false|쓰기 권한이 있는 폴더만 필터링 여부|

###### ... FileStation.SharedFolder
|Property|Type|Description|
|--------|----|-----------|
|name|String|이름|
|path|String|상대 경로|
|absolutePath|String?|절대 경로 (요청 시 `SharedFolderAdditionalInfo.absolutePath` 필요)|
|mountPointType|String?|마운트 포인터 타입 (요청 시 `SharedFolderAdditionalInfo.mountPointType` 필요)|
|owner|FileStation.Owner?|파일 소유자 정보 (요청 시 `SharedFolderAdditionalInfo.owner` 필요)|
|dates|FileStation.Dates?|파일 `생성`,`수정`,`변경`,`접근` 시간 정보 (요청 시 `SharedFolderAdditionalInfo.time` 필요)|
|permission|FileStation.Permission?|파일 퍼미션 정보 (요청 시 `SharedFolderAdditionalInfo.permission` 필요)|
|isReadOnly|Bool?|읽기 전용 여부 (요청 시 `SharedFolderAdditionalInfo.volumeStatus` 필요)|
|freeSpace|UInt64?|남은 용량 (요청 시 `SharedFolderAdditionalInfo.volumeStatus` 필요)|
|totalSpace|UInt64?|전체 용량 (요청 시 `SharedFolderAdditionalInfo.volumeStatus` 필요)|
|usesSpace|UInt64?|사용 용량 (요청 시 `SharedFolderAdditionalInfo.volumeStatus` 필요)|

#### File List
파일목록을 가져오고 그 정보를 읽는 것은 `FileStation`에서 중요한 기능 중 하나입니다.
```swift
let page = try await diskStation.fileStation().files(at: <#path#>)
```

## 라이센스
MIT license. See [LICENSE](https://github.com/Jaesung-Jung/SwiftSynology/blob/main/LICENSE) for details.