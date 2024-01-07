# GitHub Actions 워크플로우를 커멘트로 트리거해서 PR 브랜치 코드 검증하기

## Overview

| 프로퍼티 | 설명 |
| --- | --- |
| 대상 | Github Actions 의 `issue_comment` 나 `pull_request_review_comment` 이벤트를 쓰시거나 체크아웃 문제를 겪는 분 |
| 난이도 | 🫐 Blueprint (참고하면서 개발하기 좋음) |
| 날짜 | 24.01.07 |

## 1. 배경 및 목적

사이드 프로젝트에서 Pull Request 가 생성되고 나면 커멘트로 유닛 테스트를 돌려보도록 GitHub Actions 워크플로우를 추가했습니다.
하지만 GitHub Actions 에서 `issue_comment` 이벤트에 의해서 트리거 되는 워크플로우는 base 브랜치로 체크아웃 합니다.[^1]
Pull Request 에서 커멘트로 워크플로우를 동작시켜 테스트를 돌려보는 이유는 PR 브랜치의 코드를 검증하기 위해서 이므로
기본 체크아웃을 사용하면 PR 브랜치로 체크아웃하지 않아서 올바른 검증을 하지 못하는 문제가 있습니다.

이 문서에서 PR 브랜치의 코드를 검증할 수 있도록 수정하는 방법을 알아보겠습니다.

## 2. 진행 방법과 결과 데이터

### 2.1. `pull_request_review_comment` 이벤트 사용

`pull_request_review_comment` 은 PR에 리뷰 커멘트 관련 이벤트로 PR이 가상 병합된 base 브랜치 커밋으로 체크아웃 합니다.

![pull_request_review_comment](https://github.com/ku-ring/ios-app/assets/53814741/62efe431-720b-4bb8-8ef5-a0c9273725e0)

 다음과 같이 워크플로우를 수정하면 PR reviewer가 리뷰 커멘트를 남겼을 때 정의한 Job 을 실행하게 됩니다.[^2]
```yml
on:
-  issue_comment:
+  pull_request_review_comment:
    types: [created]
```

하지만 `pull_request_review_comment` 은 PR을 생성한 사람이 워크플로우를 트리거할 수 없다는 단점이 있습니다.

### 2.2. `issue_comment` 이벤트 시, 체크아웃에 `ref` 값으로 `event.issue.number` 사용

`issue_comment` 로 해결하기 위해 `issue_comment` 이벤트 시, PR 브랜치 최신 커밋(`HEAD`) 로 체크아웃 하는 방법에 대해서 알아보던 중 다음 답변을 발견했습니다.

https://github.com/actions/checkout/issues/331#issuecomment-1438220926

이벤트 내 프로퍼티에 `issue.number` 를 사용해 PR 번호를 가져올 수 있고 이를 다음과 같이 `actions/checkout` 에 `ref` 값으로 사용하여 PR 브랜치의 `HEAD` 로 체크아웃 할 수 있습니다.

```yml
- name: Checkout pull request
        uses: actions/checkout@v4
        with:
          ref: refs/pull/${{ github.event.issue.number }}/head
```

이를 base 브랜치에 반영한 후 새 PR을 생성하여 커멘트를 남기면 다음과 같이 PR 브랜치로 잘 체크아웃 되는 것을 확인하였습니다.

![method2_result](https://github.com/ku-ring/ios-app/assets/53814741/a720bddf-2335-4bfe-ae93-1e728ac5f5a8)

### 3. 결론

GitHub Actions를 사용해 PR 에서 comment 를 남겨 PR 코드를 검증하려는 경우 워크플로우에 `issue_comment` 이벤트를 사용할 수 있습니다.
하지만 이 경우 체크아웃을 base branch 로 하기 때문에, `actions/checkout` 의 `ref` 에
`refs/pull/${{ github.event.issue.number }}/head` 를 넣어 PR 브랜치로 체크아웃 할 수 있습니다.

### 4. 참고

### 4.1. 참고링크

- [pull_request_review_comment 이벤트 적용한 커밋]: https://github.com/ku-ring/ios-app/pull/87/commits/ddf207025e17c5e4084a741395a8633eda4b74f5
- [issue_comment 의 issue.number로 체크아웃한 워크플로우]: https://github.com/ku-ring/ios-app/actions/runs/7438192548/job/20236707241


#### 4.2. 각주

[^1]: https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request_review_comment
[^2]: https://github.com/ku-ring/ios-app/pull/87/commits/ddf207025e17c5e4084a741395a8633eda4b74f5


