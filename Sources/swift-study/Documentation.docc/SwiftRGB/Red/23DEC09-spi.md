# @_spi

Swift Private Interface. 노출 시키고 싶진 않지만 Public 으로 해야하는 인터페이스를 위한 접근제어.

## Overview

|프로퍼티 | 설명 |
| --- | --- |
| 대상 | Public 으로 해야하지만 API를 숨기고 싶은 분 |
| 난이도 | 🧣 Read (가볍게 읽기 좋음) |
| 날짜 | 23.12.09 |


## 1. 배경 및 목적
pointfree.co 의 swift-composable-architecture [#2633 PR](https://github.com/pointfreeco/swift-composable-architecture/pull/2633/files)을 확인해보면 Public API 선언부 앞에 `@_spi(Internals)` 키워드를 추가한 것을 볼 수 있습니다.
```swift
@_spi(Internals) public func scope<ChildState, ChildAction>(
    state toChildState: @escaping (State) -> ChildState,
    id: ScopeID<State, Action>?,
    action fromChildAction: @escaping (ChildAction) -> Action,
    isInvalid: ((State) -> Bool)?,
    removeDuplicates isDuplicate: ((ChildState, ChildState) -> Bool)? 
) -> Store<ChildState, ChildAction>
```
이렇게 선언하면 `@testable import`가 없어도 테스트 할 수 있다고 합니다. [^1]
```swift
- #if DEBUG
- @testable import ComposableArchitecture
- #endif

+ @_spi(Internals) import ComposableArchitecture
```
하지만 API 사용할 때 프레임워크를 가져오는 방법이 `@testable import`에서 `@_spi(Internals) import` 로 바뀌는 거라 더 불편하게도 느껴지는데 `@_spi` 에 대해서 자세히 알아봅니다.
## 2. SPI
### 2.1. 이론
SPI 는 Swift Private Interface 의 약자 입니다.
프레임워크 간의 또 다른 Access Control를 하며 외부에 노출할 인터페이스를 제어할 수 있습니다. 하지만 공식적인 기능이 아닌 **비공식** 기능입니다.
`@_spi(Name)` 키워드를 선언부 앞에 추가하면 사용하는 쪽에서는 `@_spi(Name) import` 를 해줘야 인터페이스에 접근이 가능합니다. 
가장 우선순위가 높은 Access Level 이기 때문에 public API 여도 `@_spi(Name)` 키워드를 사용하지 않고는 접근할 수 없습니다.

### 2.2. SPI 사용과 결과

직접 SPI 를 사용해보겠습니다. 다음과 같이 패키지에 타겟을 세팅합니다.
```swift
.target(
    // 영화 관련 UI 컴포넌트를 제공
    name: "CinemaUI",
    dependencies: ["Models"]
),
.target(
    // 영화정보와 같은 영화 관련 모델을 제공
    name: "Models" 
),
```
`CinemaUI` 는 영화 관련 UI 컴포넌트를 제공하고 `Models` 는 영화정보와 같은 영화 관련 모델을 제공합니다.
그리고 위의 패키지 소스와 같이 `CinemaUI` 모듈은 `Models` 모듈을 의존성으로 갖고 있습니다.

`CinemaUI` 에 `MovieRow` 라는 단일 영화에 대한 정보를 보여주는 리스트 아이템용 UI 코드를 다음과 같이 작성할 수 있습니다.

```swift
import Models
import SwiftUI

public struct MovieRow: View {
    public let movie: Movie
    
    public var body: some View {
        HStack {
            Text("#\(movie.rank)")
                .bold()
                .foregroundStyle(Color.secondary)
            
            Text(movie.name)
        }
    }

    public init(movie: Movie) {
        self.movie = movie
    }
}
```

그리고 다음과 같이 `Movie` 에 mock 값인 `Movie.kuflix` 를 정의합니다.
```swift
extension Movie {
    public static var kuflix = Movie(
        name: "Kuflix",
        rank: Int.random(in: 1...10).description,
        code: UUID().uuidString
    )
}
```

그러면 `Movie.kuflix`이 `public` 이므로 다른 모듈인 `CinemaUI` 에서 접근이 가능해 `MovieRow` 의 Preview 코드를 다음과 같이 작성할 수 있습니다.
```swift
#Preview {
    MovieRow(movie: Movie.kuflix)
}
```

하지만 `Movie.kuflix` 는 테스트를 위한 용도임에도 불구하고 `public` 이라서 누구나 외부에서 접근이 가능합니다. 

이 때 사용할 수 있는 것이 바로 앞서 소개했던 `@_spi` 속성 입니다.

다음과 같이 `Movie.kuflix` 선언부에 `@_spi` 를 추가해줍니다.
```swift
@_spi(Mocks) public static var kuflix = Movie(...)
```

그런 다음 다시 프리뷰 코드로 돌아오면 `'kuflix' is inaccessible due to '@_spi' protection level` 이라는 에러가 발생합니다.
- Warning: 🛑 'kuflix' is inaccessible due to '@_spi' protection level

이제 `Movie.kuflix` 는 `public`임에도 불구하고 아무나 접근 할 수 없고 다음과 같이 모듈을 import 할 때 `@_spi` 를 사용해야만 인터페이스에 접근이 가능하게 됩니다.

```swift
@_spi(Mocks) import Models
```

## 3. 결론
외부에 노출시키지 않아도 되는 API 이지만 필요한 순간에 반드시 사용해야하는 경우 `@_spi` 키워드를 활용할 수 있습니다. 단 비공식적인 기능임을 염두해야 합니다.
실수로 호출하게 되는 것을 방지해야 하거나 어떠한 이유로 노출 시키고 싶진 않지만 Public 으로 해야하는 경우에 사용할 수 있습니다.

## 4. 참고
### 4.1. 참고링크
- https://github.com/ku-ring/swift-cinema/blob/main/swift-cinema/Sources/CinemaUI/MovieRow.swift
- https://github.com/ku-ring/swift-cinema/blob/main/swift-cinema/Sources/Models/Movie.swift

### 4.2. 각주
[^1]: https://github.com/pointfreeco/swift-composable-architecture/pull/2633#discussion_r1420401964
