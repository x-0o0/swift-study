# XCTest 에서 로컬 JSON 파일 사용하기

결론: `Bundle(for:)` 과 `url(forResource:withExtension:)` 를 연속적으로 사용하여 파일 경로에 접근할 수 있다

## 결론
`Bundle(for:)` 과 `url(forResource:withExtension:)` 으로 파일 경로에 접근할 수 있다

```swift
// MyTests 와 같은 번들에 `.json` 파일이 있는 경우
if let jsonURL = Bundle(for: MyTests.self).url(forResource: "{파일이름}", withExtension: "json") {
    let jsonData = try Data(contentsOf: jsonURL)
    let response = try JSONDecoder().decode(MyResponse.self, from: jsonData)
    XCTAssert(!response.items.isEmpty)
}
```

### 설명

![screenshot](https://user-images.githubusercontent.com/53814741/165452304-7064cfba-e850-4401-86a1-d2cc207f4d2c.png)

`NormalNoiceTypes.json` 을 `NoticeTests` 에서 사용하려는 경우

<img width="341" alt="Screen Shot 2022-04-27 at 3 07 54 PM" src="https://user-images.githubusercontent.com/53814741/165452304-7064cfba-e850-4401-86a1-d2cc207f4d2c.png">

```swift
import XCTest
@testable import KuringSDK

class NoticeTests: XCTestCase {
    func test_fetchNormalNoticeTypes() throws {
        if let jsonURL = Bundle(for: NoticeTests.self).url(forResource: "NormalNoticeTypes", withExtension: "json") {
            let jsonData = try Data(contentsOf: jsonURL)
            let noticeTypes = try JSONDecoder().decode(NormalNoticeTypeResponse.self, from: jsonData)
            XCTAssert(!noticeTypes.noticeTypes.isEmpty)
        } else {
            XCTFail("NormalNoticeTypes.json 파일을 찾을 수 없습니다.")
        }
    }
    ...
}

```
