# GitHub Actions로 수정되면 안되는 파일 체크하기

GitHub Actions 의 워크플로우를 사용해서 수정되면 안되는 파일에 수정이 발생했는지 Pull Request 이벤트에서 체크하기

## Overview

| 프로퍼티 | 설명 |
| --- | --- |
| 대상 | pull-request 이벤트에서 동작하는 GitHub actions 에서 git commit 관련 명령 수행하고 싶은 분 |
| 난이도 | 🫐 Blueprint (참고하면서 개발하기 좋음) |
| 날짜 | 24.01.06 |

## 1. 배경 및 목적

공동작업을 하다보면 수정하면 안되는 파일이 있을 수 있습니다.
예를 들어, `apikey-info.plist`에 테스트용 API Key 값을 받는 키를 추가하고 로컬 작업 시에만 API Key 값을 넣고 사용한다고 가정 했을 때, `apikey-info.plist` 는 이미 공동작업을 위해 main 브랜치에 push 되어 있기 때문에 `.gitignore` 에 포함시킬 수 없습니다. 그러면 매번 커밋을 푸시하기 전 또는 PR을 `main` 머지하기 전에 `apikey-info.plist` 의 수정사항을 체크해서 스테이지에 올라가지 않도록 해야합니다.
이는 정말 번거로우며 실수로 푸시할 수 있다는 점에서 전혀 안전성이 보장되지 않습니다.
이 문서에서는 GitHub Actions 를 사용하여 자칫 `main` 에 반영되지 않도록 `pull-request` 이벤트에서 `apikey-info.plist` 처럼 수정되면 안되는 파일들에 수정사항이 있으면 CI Fail 를 발생시키는 워크플로우를 작성합니다.

## 2. 진행 방법과 결과 데이터

### 2.1. shell 스크립트 파일 작성

다음과 같이 수정하면 안되는 파일(이하 `guard_modification.sh`)을 정의합니다.
```bash
TARGET_FILES=("Sources/Network/apikey-info.plist") # 콤마 없이 띄어쓰기를 사용하여 요소 추가
```
base 브랜치의 최신 커밋 해시를 가져와 `git diff` 명령어로 변경이 있는 파일들의 이름을 전부 가져옵니다.
```bash
ORIGIN_COMMIT=$(git rev-list main)

CHANGED_FILES=$(git diff --name-only $FIRST_COMMIT HEAD)
```
수정되면 안되는데 수정된 파일들을 찾아 `MODIFIED_TARGET_FILES` 저장합니다.
```bash
MODIFIED_TARGET_FILES=()
for TARGET_FILE in "${TARGET_FILES[@]}"; do
  if [[ $CHANGED_FILES == *"$TARGET_FILE"* ]]; then
    MODIFIED_TARGET_FILES+=("$TARGET_FILE")
  fi
done
```
`MODIFIED_TARGET_FILES` 에 값이 존재하면 에러를 출력합니다.
```bash
if [ ${#MODIFIED_TARGET_FILES[@]} -gt 0 ]; then
  for MODIFIED_FILE in "${MODIFIED_TARGET_FILES[@]}"; do
    echo "::error:: $MODIFIED_FILE 에서 올바르지 않은 수정이 발견되었습니다."
  done
  exit 1
fi
```
이 스크립트를 다음과 같이 터미널에서 실행해보면 잘 동작하는 것을 확인할 수 있습니다.
```bash
cd path/to/repository/.github/scripts
chmod +x guard_modifications.sh
./guard_modifications.sh
```

### 2.2. GitHub Actions 워크플로우를 작성합니다

```yml
name: 코드 검증을 시작합니다.

on:
  pull_request: # PR 이벤트가 발생할 때 액션 시작
    branches:
      - '*'

jobs:
  guard-modifications:
    name: 커밋 검증을 시작합니다
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 커밋 체크
        run: |
          chmod +x .github/scripts/guard_modifications.sh
          .github/scripts/guard_modifications.sh
```

### 2.3. GITHUB_REF
`pull_request` 이벤트에서 `GITHUB_REF` 는 `HEAD` 에서 base 브랜치로 병합된 커밋을 나타냅니다. 
즉, 실제로 머지가 되었을 때 문제가 없는지 미리 체크해보기 위해 가상의 머지 커밋에서 CI를 돌려 패스 하는지 확인하는 것이 GitHub Actions 워크플로우의 의도입니다. 

만약 병합된 커밋이 아니라 현재 `HEAD` 커밋으로 이동하고 싶을 땐, `ref` 에 `HEAD`의 `sha` 를 대입하여 체크아웃 하도록 해야합니다.
이 때 체크아웃은 기본적으로 shallow하기 때문에 마지막 커밋만 가지고 있는데 `fetch-depth` 값을 조정하여 원하는 최신 커밋 개수를 가져올 수 있고, 전체를 가져오고 싶으면 `0`으로 세팅하여 가져올 수 있습니다. (`fetch-depth` 기본값은 `1`)
따라서 다음과 같이 워크플로우의 `guard-modifications` job의 체크아웃 명령을 수정합니다.

```yml
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}
    fetch-depth: 0
```

그리고 스크립트에서 `ORIGIN_COMMIT=$(git rev-list main)` 는 `main` 브랜치의 최신 커밋을 가져오므로 GitHub Actions 이 동작원리에 따른다면 이때 `ORIGIN_COMMIT` 은 가상 병합된 커밋 값을 가져올 것입니다. 즉 가상 병합된 커밋을 가리키는 `HEAD` 와 동일해집니다.

따라서 다음과 같이 `ORIGIN_COMMIT` 정의를 수정해야 합니다.

```bash
ORIGIN_COMMIT=$(git rev-list HEAD^)
```
`HEAD^`는 `HEAD` 이전의 커밋을 가져오는 옵션입니다.  

## 3. 결론

GitHub Actions 는 `pull_request` 이벤트에서 돌아갈 때 가상 병합을 하여 base 브랜치에서 CI를 돌리기 때문에 [2.3. GITHUB_REF]에서 처럼 `actions/checkout@4`에 `ref` 옵션에 `head.sha` 값을 넣고 이를 고려하여 로컬에서 돌렸던 스크립트와 달리 원래의 base 브랜치 최신 커밋을 가져오기 위해서는 `git rev-list main` 이 아닌, `git rev-list HEAD^` 명령을 사용해야 합니다. 

마지막으로 전체 스크립트와 워크플로우 코드를 정리합니다.
```bash
# /.github/scripts/guard_modifications.sh
TARGET_FILES=("Sources/Network/apikey-info.plist")
ORIGIN_COMMIT=$(git rev-list main)
CHANGED_FILES=$(git diff --name-only $FIRST_COMMIT HEAD)

MODIFIED_TARGET_FILES=()
for TARGET_FILE in "${TARGET_FILES[@]}"; do
  if [[ $CHANGED_FILES == *"$TARGET_FILE"* ]]; then
    MODIFIED_TARGET_FILES+=("$TARGET_FILE")
  fi
done

if [ ${#MODIFIED_TARGET_FILES[@]} -gt 0 ]; then
  for MODIFIED_FILE in "${MODIFIED_TARGET_FILES[@]}"; do
    echo "::error:: $MODIFIED_FILE 에서 올바르지 않은 수정이 발견되었습니다."
  done
  exit 1
fi
```

```yml
# /.github/workflows/code_review.yml
name: 코드 검증을 시작합니다.

on:
  pull_request:
    branches:
      - '*'

jobs:
  guard-modifications:
    name: 커밋 검증을 시작합니다
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 커밋 체크
        run: |
          chmod +x .github/scripts/guard_modifications.sh
          .github/scripts/guard_modifications.sh
```

## 4. 참고

- https://stackoverflow.com/a/62335935
