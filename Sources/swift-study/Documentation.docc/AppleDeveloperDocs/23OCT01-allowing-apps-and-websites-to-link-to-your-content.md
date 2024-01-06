# 앱과 웹사이트가 컨텐츠를 연결하도록 하기 

Allowing Apps and Websites to Link to Your Content | Developer, https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content

## Overview
유니버셜 링크를 사용하여 앱 안 깊숙히 있는 컨텐츠를 연결 시킬 수 있습니다. 사용자들은 지정된 컨텍스트로 앱을 열어 효율적으로 목표하는 바를 수행토록 합니다.

사용자들이 유니버셜 링크를 탭하거나 클릭할 때, 시스템은 사파리나 웹사이트를 거쳐가지 않고 바로 앱으로 직접 링크를 연결합니다. 게다가 유니버셜 링크가 표준 HTTP, HTTPS 링크를 사용하기 때문에 하나의 URL로 웹사이트, 앱 두군데 모두에서 동작합니다. 만약 사용자가 앱을 설치하지 않았다면, 시스템은 사파리에서 URL을 열어 웹사이트에서 다룰 수 있도록 합니다.

사용자가 앱을 설치했다면, 시스템은 웹서버에 저장된 파일들 중 웹사이트가 앱이 URL을 열 수 있도록 허용을 해주었는지 인증해주는 파일을 확인합니다. 오직 서버 관리자만이 해당 파일을 저장할 수 있으며 이를 통해 웹사이트와 앱 간의 연결을 보호할 수 있습니다.

## 유니버셜 링크 지원하기
유니버셜 링크를 지원하기 위해 다음 단계들을 따르십시오:
1. 앱관 웹사이트 간에 두 가지 연결을 생성하고 앱이 다룰 URL을 지정하도록 합니다. ( [연결도메인 지원하기](bear://x-callback-url/open-note?id=4C8FA186-1CAD-4C34-A295-32037EF57B07-9693-00000F6B1FED8C7E) 를 참고하세요)
2. 유니버셜 링크가 앱으로 보내질 때 시스템이 제공하는 유저 액티비티(User Activity) 객체에 AppDelegate 가 응답할 수 있도록 업데이트 해줍니다. ([앱에 유니버셜 링크 지원하기(Supporting Universal Links in Your App)](https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/supporting_universal_links_in_your_app)를 참고하세요)

유니버셜 링크를 사용하여, 사용자들은 사파리에서 웹사이트로 연결되는 링크를 클릭하여 앱을 엽니다. 그리고 링크를 클릭하게 되면 호출에 대한 결과는 다음으로 전달받습니다:
- `open(_:options:completionHandler:)` (iOS, tvOS)
- `openSystemURL(_:)` (watchOS)
- `open(_:withApplicationAt:configuration:completionHandler:)` (macOS)
- `openURL` (SwiftUI)

> **노트**  
> 만약 사용자가 사파리에서 웹사이트를 보고 있는데 같은 도메인의 유니버셜 링크를 탭한다면, 시스템은 사용자가 브라우저에서 계속 진행하고 싶어할 것을 고려해 사파리에서 링크를 엽니다.   
> 만약 유저가 다른 도메인의 유니버셜 링크를 탭한다면, 시스템은 앱에서 해당 링크를 엽니다.  

## 다른 앱과 소통하기

앱들은 유니버셜 링크를 통해 서로 소통될 수 있습니다. 유니버셜 링크를 지원하는 것은 다른 앱들이 소량의 데이터를 서드파티 서버 없이 여러분의 앱으로 직접 전달할 수 있도록 해줍니다.

URL 쿼리 문자열 내에서 다룰 파라미터들을 정의하여야 합니다. 아래의 예시 코드는  사진 라이브러리 앱에서 파라미터들이 앨범의 이름과 띄우고자 하는 사진의 인덱스를 포함시키도록 명시하고 있습니다.

```
https://myphotoapp.example.com/albums?albumname=vacation&index=1
https://yphotoapp.example.com/albums?albumname=wedding&index=17
```

다른 앱들은 여러분의 도메인과 경로, 그리고 파라미터들에 기반하여 URL들을 만들고 여러분의 앱에 해당 URL들을 열 것을 요청하기 위해 다음 메소드를 호출합니다.
- `UIApplication.open(_:options:completionHandler:)` (iOS, tvOS)
- `WKExtension.openSystemURL(_:)` (watchOS)
- `NSWorkspace.open(_:withApplicationAt:configuration:completionHandler:)` (macOS)
- `openURL` environment value (SwiftUI)

앱 호출은 여러분의 앱이 URL을 열 때 시스템에 알려달라고 요청할 수 있습니다.

다음 예시 코드에서 앱은 iOS 와 tvOS의 유니버셜 링크를 호출하고 있습니다.
```swift
if let appURL = URL(string: "https://myphotoapp.example.com/albums?albumname=vacation&index=1") {
    UIApplication.shared.open(appURL) { success in
        if success {
            print("The URL was delivered successfully.")
        } else {
            print("The URL failed to open.")
        }
    }
} else {
    print("Invalid URL specified.")
}
```

다음 예시 코드에서 앱은 watchOS의 유니버셜 링크를 호출하고 있습니다.
```swift
if let appURL = URL(string: "https://myphotoapp.example.com/albums?albumname=vacation&index=1") {
    WKExtension.shared().openSystemURL(appURL)
} else {
    print("Invalid URL specified.")
}
```

다음 예시 코드에서 앱은 macOS의 유니버셜 링크를 호출하고 있습니다.
```swift
if let appURL = URL(string: "https://myphotoapp.example.com/albums?albumname=vacation&index=1") {
    let configuration = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.open(appURL, configuration: configuration) { (app, error) in
        guard error == nil else {
            print("The URL failed to open.")
            return
        }
        print("The URL was delivered successfully.")
    }
} else {
    print("Invalid URL specified.")
}
```

앱 내에서 링크를 다루는 것에 대한 추가적인 정보가 필요하다면 [앱에서 유니버셜 링크 지원하기(Supporting Universal Links in Your App)](https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/supporting_universal_links_in_your_app) 를 참고하세요.


