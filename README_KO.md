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
</p>

`SwiftSynology`는 `Synology NAS` 장치와 상호작용할 수 있는 Swift 라이브러리로, `Synology NAS`의 다양한 기능을 애플리케이션에 손쉽게 통합할 수 있도록 합니다. 이 라이브러리는 `Swift Concurrency`의 `actor`와 `async`/`await` 패러다임을 활용하여 동시성 처리를 최적화한 구조로 설계되었습니다. 이를 통해 안전하고 효율적인 비동기 작업이 가능하며, 동시성 관련 문제를 최소화합니다.

## 설치
### [Swift Package Manager](https://github.com/swiftlang/swift-package-manager)
[Swift 패키지 관리자]((https://github.com/swiftlang/swift-package-manager))는 Swift 코드를 배포하는 작업을 자동화하는 도구로, Swift 컴파일러에 통합되어 있습니다.

Swift 패키지를 설정한 후, `Package.swift`의 `dependencies` 값이나 Xcode의 패키지 목록에 `SwiftSynology`를 추가하는 것만으로 간단하게 종속성으로 추가할 수 있습니다.
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

## 가이드
### DiskStation 생성
시작은 `DiskStation` 객체를 생성하는 것입니다. `DiskStation`은 `DSM`과 상호작용하기 위한 추상화 레이어입니다. `DiskStation`을 생성하기 위해서는 `QuickConnect`를 사용하여 자동으로 `URL`을 찾거나, 명시적으로 `URL`을 전달할 수 있습니다.

#### QuickConnect 사용
`QuickConnect`는 포트 포워딩 규칙을 설정하지 않아도 클라이언트 애플리케이션이 인터넷을 통해 `DSM`에 연결할 수 있도록 해줍니다. `SynologySwift`는 `QuickConnect` API를 통해 쉽게 장치를 검색할 수 있는 기능을 제공합니다.
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

`QuickConnect`는 여러 연결 방식을 시도한 후, 우선순위가 가장 높은 방식에 연결됩니다.
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

> QuickConnect는 HTTPS와 HTTP를 모두 지원하지만, [NSAppTransportSecurity](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/) 설정으로 인해 HTTP 연결이 실패할 수 있습니다.

#### URL 사용
`URL`을 전달하여 `DiskStation` 객체를 생성할 수 있습니다.
```swift
let diskStation = DiskStation(serverURL: <#url#>)
```

`QuickConnect`와 달리, URL을 통해서는 DSM 연결 가능 여부를 수동으로 확인해야 합니다. DSM 연결 상태를 테스트하기 위해 `PingPong` API를 제공합니다.
```swift
let pingPong = PingPoing()
let pong = try await pingPong.ping(to: <#url#>)
print(pong.success) // true or false (Bool)
```

#### 지역화
DSM은 여러 언어를 지원하며, `CodePage` 값을 전달하면 문자열이 해당 언어에 맞게 구성됩니다. 기본적으로 `SwiftSynology` 패키지는 시스템 언어 값을 읽어 `CodePage`를 자동으로 설정합니다.

지원되는 언어는 다음과 같으며, `DiskStation` 인스턴스를 생성할 때 `CodePage` 값을 전달할 수 있습니다.
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

### 인증
`DiskStation`의 `auth()`는 인증을 위한 API를 제공합니다.
<br/>
`SynologySwift`는 로그인이 성공하면 내부적으로 `sessionID`를 저장하고, API 호출 시 자동으로 인증 값을 포함하여 요청을 처리합니다.
> 💡 `sessionID`는 프로그램이 종료되면 사라지므로, 로그인을 유지하려면 `Keychain`과 같은 영속성 저장소에 저장해 사용해야 합니다. 자세한 내용은 아래에서 설명합니다.

#### 로그인
`auth().login(account:password:)` API를 사용해 로그인을 수행할 수 있습니다.
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

연결이 성공하면 `Authorization`이 생성되며, 이 값에는 인증을 위한 `sessionID`가 포함됩니다. 인증을 유지하려면 이 값을 저장한 후, `DiskStation` 객체를 생성할 때 전달하면 됩니다.
```swift
let diskStation = DiskStation(
  serverURL: <#url#>,
  sessionID: <#sessionID#> // 👈
)
```

#### 이중인증
`DSM`은 이중 인증을 지원하며, 이를 위한 API를 제공합니다. 이중 인증을 사용하는 계정인지 확인하려면 먼저 `OTP` 값 없이 로그인을 시도해야 합니다.
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

`requiredTwoFactorAuthenticationCode` 오류가 발생하면, `login(account:password:otp:)`를 호출하여 `Auth.OTP` 값을 함께 전달해야 합니다.
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

`enableDeviceToken`은 `신뢰할 수 있는 장치`를 설정하기 위한 값으로, true를 전달하면 `Authorization`의 `deviceID`를 저장하여 다음 로그인 시 OTP 인증을 건너뛸 수 있습니다.
```swift
let authorization = try await diskStation.auth().login(
  account: <#account#>,
  password: <#password#>,
  deviceID: <#deviceID#> // 👈
)
```

#### 로그아웃
`logout()` API를 사용해 디바이스에서 명시적으로 로그아웃할 수 있습니다. 이 작업을 수행하면 DSM에서 발행된 `sessionID`가 만료됩니다.
```swift
try await diskStation.logout()
```
<br/>

### 시스템
`system()`은 DSM 시스템 상태 정보를 읽기 위한 API를 제공합니다.

#### Health
`system().health()`를 사용하여 DSM의 간단한 정보와 상태를 확인할 수 있습니다.
```swift
let health = try await diskStation.system().health()
```
###### ... System.Health
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|`DSM`의 호스트이름|
|interfaces|Array<System.Health.Interface>|장치의 네트워크 인터페이스 정보|
|status|System.Health.Status|장치의 상태 (`danger`\|`attention`\|`normal`)|
|upTime|TimeInterval|장치가 부팅된 후 경과 시간|
###### ... System.Health.Interface
|Property|Type|Description|
|--------|----|-----------|
|id|String|인터페이스 ID|
|ip|String|IP 주소|
|type|String|인터페이스 Type|


#### Info
`system().info()`를 사용해 장치의 상세 정보를 확인할 수 있습니다.
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
|supportsESATA|Bool|ESATA 지원 여부|
|ntpEnabled|Bool|NTP 사용 여부|
|ntpServer|String|NTP 서버|
|temperature|Int|장치 온도|
|temperatureWarning|Bool|온도 경고 여부|
|upTime|TimeInterval|장치가 부팅된 후 경과 시간|
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
|cls|String|장치 class|
|pid|String|장치 ID|
|vendor|String|장치 제조사|
|product|String|장치 이름|
|rev|String|Revision|
|vid|String|

#### StorageInfo
`system().storageInfo()`를 사용해 연결된 저장 장치의 상세 정보를 확인할 수 있습니다.
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

<br/>

### 개인 설정
개인 설정 정보를 읽기 위한 API를 제공합니다.
#### Wallpaper
DSM에 설정된 `배경화면 이미지`를 가져옵니다.
```swift
let wallpaperImage = try await diskStation.personalSettings().wallpaper()
// 플랫폼에 따라 [UIImage] 또는 [NSImage]를 리턴합니다.
```
<br/>

### 알림
알림 센터의 메시지를 읽기 위한 API를 제공합니다. 메시지는 설정된 `CodePage` 값에 따라 지역화된 문자열을 가져옵니다.
<br/>
[👉 CodePage 구성](#지역화)

#### Messages
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

### FileStation
`FileStation` API는 많은 파일을 처리하기 위해 `offset`과 `limit`으로 구성된 인터페이스를 제공합니다. `SwiftSynology`에서는 이를 `Page`라는 구조체로 표현하고 있습니다.
```swift
public struct Page<Element> {
  public let offset: Int
  public let totalCount: Int
  public let elements: [Element]
  public var isAtEnd: Bool
}
```
`Page`는 `Sequence`, `Collection`, 그리고 `BidirectionalCollection`을 구현하여, `Swift Collection`에서 제공하는 다양한 기능을 활용할 수 있습니다.

#### Info
`fileStation().info()`는 `FileStation` 서비스의 전반적인 정보를 제공합니다.
```swift
let info = try await diskStation.fileStation().info()
```
###### ... FileStation.Info
|Property|Type|Description|
|--------|----|-----------|
|hostname|String|DSM의 호스트이름|
|isManager|Bool|관리자 여부|
|supportFileRequest|Bool|File 요청 지원 여부|
|supportFileSharing|Bool|File 공유 지원 여부|
|supportVirtualProtocols|Array<String>|지원되는 Virtual Protocol 목록|
|systemCodepage|CodePage?|시스템 code page|

#### 공유 폴더
`공유 폴더`는 DSM에서 파일과 폴더를 저장하고 관리하는 기본 디렉토리입니다. `fileStation().sharedFolders()`를 통해 공유 폴더 정보를 가져올 수 있습니다.
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
|offset|Int?|nil|요청 오프셋|
|limit|Int?|nil|요청 최대 개수|
|sortBy|SortBy\<FileStation.SharedFolderSortAttribute\>?|nil|정렬 방식|
|additionalInfo|Set\<FileStation.SharedFolderAdditionalInfo\>?|nil|추가 정보|
|onlyWritable|Bool|false|쓰기 권한이 있는 폴더만 필터링할지 여부|

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

#### File
`SynologySwift`에서는 파일과 디렉토리를 `FileStation.File`로 표현합니다. 이 패키지는 파일 목록, 디렉토리 생성, 이름 변경, 이동, 복사, 삭제, 디렉토리 크기 계산, 그리고 MD5 해시 연산 등의 작업을 지원합니다.

다음은 파일 목록을 읽어오는 간단한 예제입니다.
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
|path|String|-|경로|
|pattern|String?|nil|필터링 패턴(`Glob Pattern`)|
|offset|Int?|nil|요청 오프셋|
|limit|Int?|nil|요청 최대 개수|
|sortBy|SortBy\<FileStation.FileSortAttribute\>?|nil|정렬 방식|
|additionalInfo|Set\<FileStation.FileAdditionalInfo\>?|nil|추가 정보|
|type|FileStation.FileTypeFilter|nil|`.fileOnly` \| `.directoryOnly`|

###### ... FileStation.File
|Property|Type|Description|
|--------|----|-----------|
|name|String|이름|
|path|String|상대 경로|
|isDirectory|Bool|디렉토리 여부|
|isValid|Bool|파일 유효성|
|fileExtension|String|파일 확장자|
|size|UInt64?|파일 사이즈 (요청 시 `FileAdditionalInfo.size` 필요)|
|absolutePath|String?|절대 경로 (요청 시 `FileAdditionalInfo.absolutePath` 필요)|
|mountPointType|String?|마운트 포인터 타입 (요청 시 `FileAdditionalInfo.mountPointType` 필요)|
|owner|FileStation.Owner?|파일 소유자 정보 (요청 시 `FileAdditionalInfo.owner` 필요)|
|dates|FileStation.Dates?|파일 `생성`,`수정`,`변경`,`접근` 시간 정보 (요청 시 `FileAdditionalInfo.time` 필요)|
|permission|FileStation.Permission?|파일 퍼미션 정보 (요청 시 `FileAdditionalInfo.permission` 필요)|

#### 공유 링크
공유 링크는 Synology NAS에 저장된 파일이나 폴더를 쉽게 공유할 수 있는 서비스입니다. 공유 링크의 URL 또는 QR 코드를 다른 사용자와 공유하면, DSM 계정 여부와 상관없이 선택한 파일이나 폴더를 다운로드할 수 있습니다.
<br/>
이 패키지는 `공유 링크 목록`, `공유 링크 생성`, `공유 링크 수정`, 그리고 `공유 링크 삭제` 등의 작업을 지원합니다.

다음은 공유 링크를 생성하는 간단한 예제입니다.
```swift
let shareLink = try await diskStation.fileStation().createShareLink(path: <#filePath#>)
```
###### ... Parameters
|name|type|default|description|
|----|----|-------|-----------|
|path|String|-|파일 경로|
|password|String|nil|공유 암호|
|availableDate|Date|nil|공유 시작날짜|
|expiredDate|Date|nil|공유 만료날짜|

###### ... FileStation.ShareLink
|Property|Type|Description|
|--------|----|-----------|
|id|String|링크 ID|
|url|URL|링크 URL|
|qrcode|String|QR Code(Base64 인코딩)|
|name|String|파일 이름|
|path|String|파일 경로|
|isDirectory|Bool|디렉토리 여부|
|status|FileStation.ShareLink.Status|공유링크 상태|
|hasPassword|Bool|비밀번호 필요 여부|
|owner|String|파일 소유자명|
|availableDate|String|공유 시작날짜 (yyyy-MM-dd HH:mm:ss)|
|expiredDate|String|공유 만료날짜 (yyyy-MM-dd HH:mm:ss)|

#### Background Task
FileStation의 복사, 압축, MD5 해시 연산 등의 작업은 시간이 오래 걸릴 수 있습니다. 이러한 작업들은 DSM 내부에서 BackgroundTask로 분류되어 관리됩니다. 이 패키지에서는 `BackgroundTask<Completed, Processing>` actor로 추상화되어 있으며, 폴링 방식으로 상태를 지속적으로 확인할 수 있습니다. `BackgroundTask.status()`는 `AsyncThrowingStream`을 통해 지정된 `pollingInterval` 간격으로 작업이 완료될 때까지 상태를 반환합니다.

다음은 `복사` 기능의 `BackgroundTask`를 사용하는 예제입니다.
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

## 라이센스
MIT license. See [LICENSE](https://github.com/Jaesung-Jung/SwiftSynology/blob/main/LICENSE) for details.
