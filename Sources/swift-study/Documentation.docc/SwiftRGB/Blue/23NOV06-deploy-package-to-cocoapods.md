# 스위프트 패키지를 코코아팟에 배포하기

스위프트 패키지를 코코아팟(CocoaPods) 의존성 관리도구(Dependency Manager) 에 배포하는 과정

## Overview

|프로퍼티 | 설명 |
| --- | --- |
| 대상 | 스위프트 패키지를 코코아팟에 배포하고 싶은 분 |
| 난이도 | 🫐 Blueprint (참고하면서 개발하기 좋음) |
| 날짜 | 23.11.06 |

## 1. 배경 및 목적

Xcode 에서 개발한 Framework 를 코코아팟에 배포하고 XCFramework 를 추출해서 스위프트 패키지 매니저에도 배포는 수차례 해보았지만
스위프트 패키지 매니저에 배포하던 스위프트 패키지를 코코아팟에 배포하는 것은 경험이 없었다.

CocoaPods의 매니페스트(Manifest) 설정을 담당하는 Podspec 를 가볍게 수정하는 것으로 스위프트 패키지를 코코아팟에 배포할 수 있다.

이 문서에서는 `SevenSegmentUI` 라는 스위프트 패키지에 `.podspec` 파일을 생성하고 코코아팟 트렁크(Trunk) 에 푸시하여 배포하는 과정을 다뤄보겠습니다.

## 2. 코코아팟 배포 과정

### 2.1. Podspec 생성 및 수정

> **중요**
>
> `pod` 커맨드라인 도구 설치가 사전에 필요합니다.

```bash
pod spec create SevenSegmentUI # 패키지 이름
```

`spec create` 는 `.podspec` 파일을 생성하는 명령어 입니다.<sup>[1](#footnote_1)</sup>

명령어 실행 후 `package-seven-segments` 폴더의 구성은 다음과 같게 됩니다.

```
package-seven-segments
|--- Package.swift
|--- SevenSegmentUI.podspec
|--- Sources
     |--- SevenSegmentUI
```

`.podspec` 을 열고 아래와 같이 팟의 스펙 정보를 작성했습니다.

```podspec
Pod::Spec.new do |spec|
  spec.name         = "SevenSegmentUI"
  spec.version      = "0.0.1"
  spec.summary      = "한 줄 설명"

  spec.description  = <<-DESC
    라이브러리에 대한 자세한 소개 문구가 들어갑니다.
                   DESC

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Jaesung Lee" => "이메일주소" }

  spec.ios.deployment_target = "16.0"
  spec.swift_version = "5.9"

  spec.source       = {
    :git => "https://github.com/jaesung-0o0/package-seven-segments.git",
    :tag => "#{spec.version}"
  }

  spec.source_files  = "Sources/SevenSegmentUI/**/*"

end
```
스펙에 들어가야 하는 정보는 다음과 같습니다. 여기서 가장 중요한 것은 `spec.source_files` 입니다. Sources 하위 폴더 중 팟으로 제공하고자 하는 소스의 폴더를 명시해줘야 합니다.

| 항목 | 설명 | 예시 |
| --- | --- | --- |
| `name` | pod 이름 | `spec.name = "MyPackage"` |
| `version` | 버전. 아래의 `source`에서 태그(`:tag`)를 버전으로 사용하게 세팅합니다. | `spec.version = "1.0.0"` |
| `summary` | 한 줄 요약 | `spec.summary = "Swift Package that provides OOO features"` |
| `description` | 자세한 소개 문구 | 위의 코드 블럭 참고 |
| `license` | 라이센스. 오픈소스 라이센스라면 `:type` 과 `:file` 을 사용하면 된다. | `spec.license = { :type => "MIT", :file => "LICENSE" }` |
| `author` | 작성자. 코코아팟 트렁크에 등록(`pod trunk register`)된 이메일과 이름이어야 합니다. | `spec.author = { "Jaesung Lee" => "이메일주소" }` |
| `ios.deployment_target` | 지원하느 플랫폼 버전 | `spec.ios.deployment_target = "16.0"` |
| `swift_version` | 지원하는 스위프트 버전 | `spec.swift_version = "5.9"` |
| `source` | 소스코드 저장 위치와 버전. `:git` 에 깃 저장소 URL 주소를 기재하고, `:tag` 는 태그를 버전으로 사용할 수 있도록 `"#{spec.version}"` 을 값으로 사용합니다. | `spec.source = { :git => "https://github.com/사용자이름/레포지토리이름.git", :tag => "#{spec.version}"` |
| `source_files` | 소스코드가 위치한 Sources 의 하위폴더를 명시합니다. Package.swift 에서 타겟에 소스파일 경로를 명시하는 것과 동일합니다. | `spec.source_files = "Sources/MyPackage/**/*"`<sup>[2](#footnote_2)</sup> |

`.podspec` 수정이 완료되면 다음과 같이 작성된 내용이 유효한 지 검증합니다.

```bash
pod spec lint SevenSegmentUI.podspec
```

### 2.2. 코코아팟에 배포

수정된 `.podspec` 커밋하고 원격 저장소에 푸시합니다. 

```bash
git add *
git commit -m "[버전] 1.0.0"
git push origin main
```

커밋에 버전을 명시한 태그를 추가합니다. 아까 `.podspec` 에서 `source_files` 의 `:tag` 에 태그 내용을 버전으로 사용한다고 명시했기 때문에, trunk 에 배포 전 반드시 원격저장소에 태그가 먼저 추가되어 있어야 합니다.

```bash
git tag "1.0.0"
```

태그까지 추가 되었다면 트렁크에 푸시합니다.

```bash
pod trunk push
```

> **NOTE**
>
> `git.author` 에 기재한 작성자 정보가 트렁크에 등록되어있지 않다면 트렁크에 푸시할 수 없습니다. 푸시 전 다음 명령어를 실행하여 이메일과 이름을 트렁크에 등록해주도록 합니다.
>
> ```bash
> pod trunk register 이메일주소 이름 # 띄어쓰기는 밑줄로 대체. 예: Jaesung_Lee
> ```
>
> 이 명령어를 실행하면 등록을 하려는 이메일 주소로 인증메일이 발송 됩니다. 인증 메일에 있는 링크를 누르면 등록이 완료됩니다.

푸시가 성공적으로 완료되면 다음과 같이 메세지가 나타납니다.

```bash
--------------------------------------------------------------------------------
 🎉  Congrats

 🚀  SevenSegmentUI (0.0.1) successfully published
 📅  November 3rd, 04:37
 🌎  https://cocoapods.org/pods/SevenSegmentUI
 👍  Tell your friends!
--------------------------------------------------------------------------------
```

## 3. 결론

`.podspec` 의 `source_files` 에 `Sources/소스폴더이름/**/*` 를 기재하여 스위프트 패키지를 코코아팟에 배포할 수 있습니다.


## 4. 참고 문헌

<a name="footnote_1">1</a>: [https://guides.cocoapods.org/making/specs-and-specs-repo](https://guides.cocoapods.org/making/specs-and-specs-repo.html)

<a name="footnote_2">2</a>: `**` 는 모든 하위폴더를 의미, `*` 모든 파일을 의미
