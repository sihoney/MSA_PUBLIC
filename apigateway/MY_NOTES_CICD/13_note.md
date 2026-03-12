# GHCR 이미지 등록

좋아. 수업 따라가기용으로는 이 레포의 workflow 중에서 **`apigateway-registry.yml`부터 보는 게 맞아.**
이 파일이 훨씬 단순하고, **“GHCR에 이미지를 올리는 최소 흐름”**이 거의 그대로 들어 있어. 
반면 `image-registry-cicd.yml`은 여러 모듈을 한 번에 처리하려고 만든 공용 버전이라 초반에 보기엔 더 헷갈린다. ([GitHub][1])

---

## 먼저, GHCR 등록 흐름 한 줄 요약

이 workflow가 하는 일은 딱 이거야.

```text
코드 push
→ GitHub Actions 실행
→ 저장소 코드 checkout
→ GHCR 로그인
→ Dockerfile로 이미지 빌드
→ ghcr.io/... 에 push
```

GitHub 공식 문서도 Actions에서 컨테이너 레지스트리에 이미지를 게시할 때 이런 흐름을 사용한다고 설명하고, 
GHCR에는 `GITHUB_TOKEN` 또는 적절한 토큰으로 인증할 수 있다고 안내한다. ([GitHub Docs][2])

---

# 1) `apigateway-registry.yml` 설명

이 파일의 주석부터 이미 목적이 분명해.
**apigateway 전용**, **`main-gateway` 브랜치에 apigateway 관련 변경이 push되면**, **`apigateway/Dockerfile` 기준으로 이미지를 빌드해서 GHCR에만 올린다**, 그리고 **별도 shell script는 호출하지 않는다**고 적혀 있다. ([GitHub][1])

이 파일을 단계별로 풀면 이렇다.

### ① 언제 실행되나

* 수동 실행: `workflow_dispatch`
* 자동 실행: `push`
* 대상 브랜치: `main-gateway`
* 대상 경로: `apigateway/**`, `.github/workflows/apigateway-registry.yml` ([GitHub][1])

즉, 아무 브랜치에서나 되는 게 아니라 **`main-gateway`에 push**되어야 하고, 그중에서도 **apigateway 관련 파일이 바뀌었을 때** 실행되게 묶어 둔 거야. ([GitHub][1])

### ② 동시에 여러 번 돌지 않게 함

`concurrency`에서 `apigateway-registry` 그룹으로 묶고 `cancel-in-progress: true`로 되어 있다.
뜻은 같은 workflow가 연속 실행되면 **이전 실행을 취소하고 최신 실행만 남긴다**는 거야. 오래된 커밋 기준 이미지가 늦게 올라가는 걸 막기 좋다. ([GitHub][1])

### ③ 권한

`permissions`는

* `contents: read`
* `packages: write`

로 잡혀 있다.
여기서 `packages: write`가 중요해. GHCR에 push하려면 패키지 쓰기 권한이 필요하다. GitHub 문서도 Actions에서 패키지를 게시할 때 `GITHUB_TOKEN`으로 게시할 수 있으며, 패키지 권한 설정이 핵심이라고 설명한다. ([GitHub][1])

### ④ 저장소 체크아웃

`actions/checkout@v4`
이 단계가 있어야 runner가 레포 파일들을 내려받고, 그다음 `Dockerfile`과 소스 코드를 실제로 볼 수 있다. ([GitHub][1])

### ⑤ 이미지 이름과 태그 준비

이 step에서 두 값을 만든다.

* `IMAGE_PATH=ghcr.io/${GITHUB_REPOSITORY_OWNER,,}/apigateway`
* `IMAGE_TAG=${GITHUB_SHA::7}` ([GitHub][1])

여기서 뜻은:

* `ghcr.io/.../apigateway`
  → GHCR에 저장될 이미지 경로
* `${GITHUB_REPOSITORY_OWNER,,}`
  → owner를 **소문자**로 바꾼 값
* `${GITHUB_SHA::7}`
  → 현재 커밋 SHA 앞 7자리

그래서 최종 이미지는 대략 이런 형태가 된다.

```text
ghcr.io/owner/apigateway:a1b2c3d
ghcr.io/owner/apigateway:latest
```

즉 **“이번 커밋 버전 태그”**와 **“latest 태그”**를 같이 올리는 구조야. ([GitHub][1])

### ⑥ GHCR 로그인

이 workflow는 `docker/login-action@v3`를 쓰고,

* `registry: ghcr.io`
* `username: ${{ github.repository_owner }}`
* `password: ${{ secrets.GHCR_TOKEN }}`

으로 로그인한다. ([GitHub][1])

여기서 중요한 점은, 이 파일은 **`GHCR_TOKEN`이라는 별도 secret**을 쓰고 있다는 거야.
GitHub 공식 문서는 GHCR 인증에 **`GITHUB_TOKEN`을 사용할 수 있고**, 경우에 따라 **PAT(classic)**도 쓸 수 있다고 설명한다. 이 workflow는 그중 **별도 secret 방식**을 택한 셈이야. ([GitHub Docs][3])

### ⑦ Docker 이미지 빌드 + 푸시

`docker/build-push-action@v5`를 사용하고,

* `context: ./apigateway`
* `file: ./apigateway/Dockerfile`
* `push: true`
* `tags:` 두 개 설정 ([GitHub][1])

핵심은:

* `context: ./apigateway`
  → 빌드 컨텍스트를 apigateway 폴더로 잡음
* `file: ./apigateway/Dockerfile`
  → 저 Dockerfile을 사용
* `push: true`
  → 빌드만 하지 않고 **GHCR까지 올림**

즉, **이 한 step이 실제 GHCR 업로드의 본체**야. ([GitHub][1])

### ⑧ 결과 출력

마지막에

* `${IMAGE_PATH}:${IMAGE_TAG}`
* `${IMAGE_PATH}:latest`

를 출력해서 **어떤 이미지가 올라갔는지 로그로 확인**하게 해 둔 구조야. ([GitHub][1])

---

# 2) 이 파일을 진짜 초보자 관점에서 번역하면

이 workflow는 사실 이렇게 읽으면 된다.

```text
1. apigateway 관련 코드가 main-gateway에 push되면
2. GitHub Actions가 서버를 하나 띄운다
3. 레포를 다운받는다
4. ghcr.io에 로그인한다
5. apigateway/Dockerfile로 이미지를 만든다
6. 그 이미지를 ghcr.io/owner/apigateway:태그 로 업로드한다
```

이게 바로 수업에서 말한 **“GHCR에 이미지 등록”**이야.

---

# 3) `image-registry-cicd.yml`은 뭐가 다른가

이 파일은 주석상 목적이 더 넓어.
**서버 배포까지는 하지 않고**, **config, discovery, apigateway 세 모듈 이미지를 만들어 GHCR까지 올리는 역할만 담당**한다고 적혀 있다. 즉 이것도 **배포 자동화 전체**라기보다 **이미지 등록 자동화** 쪽이야. ([GitHub][4])

구조는 이렇다.

### ① 트리거

* `workflow_dispatch`
* `push`
* 브랜치: `main`, `master`
* 경로: `config/**`, `discovery/**`, `apigateway/**`, 해당 workflow 파일 ([GitHub][4])

### ② matrix

한 번의 workflow 안에서

* config
* discovery
* apigateway

세 개를 각각 따로 빌드하게 만든다. `fail-fast: false`라서 하나 실패해도 나머지는 계속 간다. ([GitHub][4])

### ③ JDK 준비

`actions/setup-java@v4`로 JDK 17을 설치하고 `cache: gradle`도 켠다.
즉 여기서는 Docker 빌드만이 아니라 Java/Gradle 빌드도 염두에 둔 설계다. ([GitHub][4])

### ④ GHCR 로그인

이 파일은 `secrets.GITHUB_TOKEN`으로 로그인한다.
GitHub 공식 문서와도 맞는 방식이다. 레포와 연결된 패키지를 게시할 때 `GITHUB_TOKEN`을 쓸 수 있다. ([GitHub][4])

### ⑤ build-push-action 사용

현재 활성화된 방식은 `docker/build-push-action@v5`로 바로 빌드/푸시하는 구조다. 예전에 `scripts/build_jar.sh`, `scripts/build_docker.sh`를 재사용하려던 부분은 주석 처리돼 있다. ([GitHub][4])

---

# 4) 수업 따라가기 기준으로 어느 파일을 보면 되나

**`apigateway-registry.yml` 하나만 먼저 이해하면 된다.**
이유는 단순해.

* 모듈 1개만 다룸
* matrix 없음
* JDK setup도 없음
* GHCR 로그인 → Docker build/push 흐름이 바로 보임 ([GitHub][1])

즉 수업에서 “GHCR에 이미지 올린다”를 놓쳤다면,
이 파일을 아래 순서로 읽으면 된다.

```text
on
→ permissions
→ checkout
→ IMAGE_PATH/IMAGE_TAG 준비
→ GHCR 로그인
→ build-push-action
```

---

# 5) 네가 특히 헷갈렸을 포인트

## `GHCR`이 뭐냐

GitHub Container Registry야.
Docker 이미지를 저장하는 GitHub 쪽 저장소라고 보면 된다. GitHub 공식 문서도 컨테이너 이미지를 GHCR에 게시하는 워크플로 예시를 제공한다. ([GitHub Docs][2])

## `workflow`가 이미지를 직접 만드나

직접 만드는 건 아니고, **workflow가 Docker 빌드 액션을 실행해서** 만들게 한다.
실제 이미지 조리법은 `Dockerfile`에 있고, workflow는 그걸 호출해 GHCR로 push한다. ([GitHub][1])

## `태그`는 왜 2개냐

하나는 **커밋 추적용** (`SHA 7자리`), 하나는 **최신본 표시용** (`latest`)이야. ([GitHub][1])

## 왜 owner를 소문자로 바꾸나

이 workflow 주석에 **GHCR는 owner를 소문자로 쓰는 것이 안전하다**고 적혀 있다. 그래서 `${GITHUB_REPOSITORY_OWNER,,}` 문법을 쓴 거야. ([GitHub][1])

---

# 6) 이 레포에서 한 가지 조심해서 볼 점

`image-registry-cicd.yml`의 `Prepare image URI` step은

* 앞 단계에서 `IMAGE_REGISTRY`를 만들었는데
* 실제 조합 step에서는 `REGISTRY`, `IMAGE_NAME`을 사용하고 있다. ([GitHub][4])

즉 파일 내용만 놓고 보면, **변수 이름이 서로 안 맞아 보여서** 그대로는 이미지 경로가 의도대로 안 만들어질 가능성이 있다. 이건 “무조건 실패한다”까지는 단정 못 하지만, **수업 복습용 기준으로는 먼저 `apigateway-registry.yml`을 보는 게 안전한 이유**가 된다. ([GitHub][4])

---

# 7) 진짜 실습 감각으로 정리

희원이 기준으로 이 workflow를 머릿속에 이렇게 넣으면 된다.

```text
내가 apigateway 코드를 push한다
→ GitHub Actions가 자동 실행된다
→ GitHub가 내 레포를 임시 서버에 내려받는다
→ ghcr.io에 로그인한다
→ apigateway/Dockerfile로 이미지를 만든다
→ ghcr.io/owner/apigateway:sha, latest 로 업로드한다
```

여기까지가 **GHCR 등록**이다.
아직 Kubernetes 배포는 아니다. 그건 그 다음 단계다. `k8s yaml`은 이 이미지를 **어떻게 띄울지** 정하는 파일이지, GHCR 업로드 자체를 하는 파일은 아니다. ([GitHub][1])

원하면 다음 답변에서 `apigateway-registry.yml` 내용을 **한 줄씩 주석 달아서 초보자용으로 다시 풀어줄게.

[1]: https://raw.githubusercontent.com/sihoney/MSA_PUBLIC/my_practice_apigateway/.github/workflows/apigateway-registry.yml "raw.githubusercontent.com"
[2]: https://docs.github.com/actions/guides/publishing-docker-images?utm_source=chatgpt.com "Publishing Docker images"
[3]: https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry?utm_source=chatgpt.com "Working with the Container registry"
[4]: https://raw.githubusercontent.com/sihoney/MSA_PUBLIC/my_practice_apigateway/.github/workflows/image-registry-cicd.yml "raw.githubusercontent.com"
