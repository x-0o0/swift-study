# Single Sheet Support 에러

결론: 동일한 `.sheet` 로직이 서로 뷰 계층에 중복으로 있는 지 확인해 볼 것

## 결론

동일한 `.sheet` 로직이 서로 뷰 계층에 중복으로 있는 지 확인해 볼것!
```swift
struct ParentView: View {
    @State private var isSheetPresented = false

    var body: some View {
        VStack {
            ChildView()
                .sheet(isPresented: $isSheetPresented) {
                    SheetView()
                }
        }
        .sheet(isPresented: $isSheetPresented) {
            SheetView()
        }
    }
}
```

### 설명

부모 뷰와 자식뷰에 `.sheet` 를 동일한 데이터로 트리거 하는 로직이 있다면 해당 데이터가 동시에 두개 이상의 `sheet` 컨텐츠를 트리거할 수 있다. 꼭 부모-자식이 아니더라도 서로 다른 뷰 계층 구조면 해당되는 상황이다. 실제 그 상황이 발생하면 콘솔에 다음과 같이 로그가 뜨는 것을 확인할 수 있다.

> Currently, only presenting a single sheet is supported. The next sheet will be presented when the currently presented sheet gets dismissed.

글쓴이 본인이 이 에러를 마주했을 때 코드는 아래와 같이 동일한 `.sheet` 코드가 부모 뷰와 자식뷰에 있었다.

```swift
// 부모뷰: NoticesContentView
var body: some View {
    NoticeList(store: self.store) // 자식뷰
        .sheet( // 👈 자식 뷰에 동일 코드 있음
            store: self.store.scope(
                state: \.$changeDepartment,
                action: \.changeDepartment
            )
        ) { store in
            NavigationStack {
                DepartmentSelector(store: store)
            }
        }
}

// 자식뷰: NoticeList
var body: some View {
    Section {
        // ...
    }
    .sheet( // 👈 자식 뷰에 동일 코드
        store: self.store.scope(
            state: \.$changeDepartment,
            action: \.changeDepartment
        )
    ) { store in
        NavigationStack {
            DepartmentSelector(store: store)
        }
    }
}
```

이 코드 하나만으로 `onAppear` 로직이 올바르게 동작하지 않아 Canvas Preview 가 실행되자 마자 에러가 나는 등 원인을 쉽게 찾을 수 없는 골치 아픈 에러들을 야기했다.
