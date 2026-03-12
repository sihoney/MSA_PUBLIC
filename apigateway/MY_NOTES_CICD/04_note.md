# ./github/workflows/image-registry-cicd.yml

이 파일은 

- 코드를 push하면 
- config / discovery / apigateway 3개 서비스를 자동으로 jar 빌드하고, 
- Docker 이미지로 만들어 
- GHCR에 올리는 

GitHub Actions workflow

아직 **서버에 실제 배포하는 단계는 없고**, 

현재는 **이미지 생성 + 레지스트리 push**까지만 담당한다. 

문서도 이 저장소의 현재 구조를 “지금은 CI 중심, CD는 나중에 추가”라고 설명한다. ([GitHub][1])

---

아래처럼 보면 된다.

```yaml
name: image-registry-cicd
```

이건 workflow 이름이야.

GitHub Actions 탭에서 이 작업이 `image-registry-cicd`라는 이름으로 보인다. 

즉 “이미지 레지스트리용 CI/CD”라는 뜻인데, 

실제로는 지금 단계에선 **registry push 중심의 CI**라고 보는 게 더 정확하다. ([GitHub][1])

---

```yaml
on:
  workflow_dispatch:
  push:
    branches:
      - main
      - master
```

이 부분은 **언제 실행할지** 정하는 구간이야.

* `workflow_dispatch`: GitHub 화면에서 버튼 눌러 수동 실행 가능
* `push`: 코드가 push되면 자동 실행
* `branches: main, master`: 아무 브랜치나 아니고 `main` 또는 `master`에 push될 때만 동작

즉, 수업에서 여기서 배우는 포인트는 **“자동화가 어떤 이벤트에 반응하는가”**야. 

CI/CD는 항상 “무슨 조건에서 시작되는가”부터 본다. ([GitHub][1])

---

```yaml
    paths:
      - "config/**"
      - "discovery/**"
      - "apigateway/**"
      - ".github/workflows/apigateway-registry.yml"
```

이건 꽤 중요하다.

`main`에 push했다고 해서 매번 실행하지 않고, 

**특정 경로가 바뀌었을 때만 실행**하게 제한한 거야.

예를 들어:

* `config` 폴더 수정 → 실행
* `discovery` 폴더 수정 → 실행
* `apigateway` 폴더 수정 → 실행
* workflow 파일 자체 수정 → 실행

반대로 README만 바꿨다면 굳이 이미지 빌드를 다시 안 할 수 있다.

즉, **불필요한 빌드를 줄여 비용과 시간을 아끼는 설정**이야. 

수업에서 이 부분은 “왜 paths 필터를 거는가?”로 자주 나온다. ([GitHub][1])

---

```yaml
concurrency:
  group: image-registry-cicd
  cancel-in-progress: true
```

이건 **중복 실행 방지** 설정이야.

예를 들어 네가 짧은 시간 안에 push를 두 번 하면:

* 먼저 실행 중이던 오래된 빌드는 취소
* 가장 최신 코드 기준 빌드만 남김

이렇게 해야 낡은 커밋 기준 이미지가 올라가는 걸 줄일 수 있어.

즉, **“최신 push 기준으로만 작업 유지”**라고 이해하면 된다. ([GitHub][1])

---

```yaml
permissions:
  contents: read
  packages: write
```

이건 GitHub Actions가 가지는 권한이야.

* `contents: read` → 저장소 코드 checkout 하려면 필요
* `packages: write` → GHCR에 이미지 push 하려면 필요

여기서 수업 포인트는 **“Actions도 권한이 있어야 뭘 할 수 있다”**는 점이야.

그냥 workflow만 작성한다고 push가 되는 게 아니라, 

패키지 레지스트리에 쓸 권한도 열어줘야 한다. 

문서에서도 GHCR push에 `packages: write`가 필요하다고 정리한다. ([GitHub][1])

---

```yaml
jobs:
  build-and-push:
    name: "${{ matrix.module_name }} 이미지 빌드 및 푸시"
    runs-on: ubuntu-latest
```

이제 실제 작업(job)이 시작된다.

* `build-and-push`: job 이름
* `name`: Actions 화면에서 서비스별로 보기 좋게 표시할 이름
* `runs-on: ubuntu-latest`: GitHub가 제공하는 우분투 러너에서 실행

즉, 네 로컬 PC가 아니라 **GitHub의 리눅스 실행 환경**에서 빌드가 돌아가는 구조다. ([GitHub][1])

---

```yaml
    strategy:
      fail-fast: false
      matrix:
        include:
          - module_name: config
            module_dir: config
            image_name: config
          - module_name: discovery
            module_dir: discovery
            image_name: discovery
          - module_name: apigateway
            module_dir: apigateway
            image_name: apigateway
```

여기가 핵심 중 핵심이다.

이건 **matrix 전략**이야. 같은 작업 구조를 3개 서비스에 반복 적용하는 방식이다.

즉, 이 workflow는 사실상 아래 3개를 돌린다.

* config 이미지 빌드/푸시
* discovery 이미지 빌드/푸시
* apigateway 이미지 빌드/푸시

`fail-fast: false`는 한 모듈이 실패해도 나머지 모듈은 계속 돌게 하겠다는 뜻이야.

예를 들어 `config` 빌드 실패해도 `discovery`, `apigateway`는 계속 시도한다.

수업에서는 이걸 통해 **“중복되는 workflow 코드를 줄이는 법”**을 배울 가능성이 크다. ([GitHub][1])

---

```yaml
steps:
  - name: 저장소 체크아웃
    uses: actions/checkout@v4
```

이건 러너에 **현재 Git 저장소 코드를 내려받는 단계**야.

이게 없으면 빌드할 파일, Dockerfile, Gradle wrapper, 스크립트가 없어서 

다음 단계가 전부 실패한다. ([GitHub][1])

---

```yaml
  - name: JDK 설정
    uses: actions/setup-java@v4
    with:
      distribution: temurin
      java-version: "17"
      cache: gradle
```

여기는 자바 프로젝트라서 JDK를 세팅하는 부분이다.

* `temurin` 배포판 사용
* Java 17 설치
* `cache: gradle`로 Gradle 의존성 캐시 활용

이 저장소 문서도 workflow가 **JDK 17 설정 후 각 모듈 jar를 빌드한다**고 설명한다.

즉, 수업에서는 여기서 **“CI 러너는 매번 깨끗한 환경이므로, 

필요한 런타임부터 설치해야 한다”**는 걸 이해하면 된다. ([GitHub][1])

---

```yaml
  - name: 이미지 경로 값 준비
    shell: bash
    run: |
      echo "IMAGE_REGISTRY=ghcr.io/${GITHUB_REPOSITORY_OWNER,,}" >> "${GITHUB_ENV}"
      echo "IMAGE_TAG=${GITHUB_SHA::7}" >> "${GITHUB_ENV}"
```

이 단계는 **환경변수 준비**다.

첫 줄:

* `IMAGE_REGISTRY=ghcr.io/저장소소유자`
* `${GITHUB_REPOSITORY_OWNER,,}`는 소유자명을 소문자로 바꾸는 bash 문법

둘째 줄:

* `IMAGE_TAG=현재 커밋 SHA 앞 7자리`

예를 들면 이런 식이 된다.

* `ghcr.io/truthplumage/config:a1b2c3d`

왜 이렇게 하냐면:

* GHCR 경로는 보통 소문자가 안전하고
* 태그를 커밋 SHA로 두면 **“어느 커밋에서 나온 이미지인지” 추적 가능**하기 때문이야. ([GitHub][1])

여기서 특히 네가 이해해야 할 건 `GITHUB_ENV`야.
이 파일에 `echo`로 값을 넣으면, **뒤에 오는 step들에서 공통 환경변수처럼 재사용**할 수 있다. 즉 이 단계는 “값 계산만 해두고, 뒤에서 쓰게 만드는 준비 단계”다. ([GitHub][1])

---

```yaml
  - name: GHCR 로그인
    uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
```

이건 GHCR 로그인이다.

* `registry: ghcr.io` → GitHub Container Registry 사용
* `username: github.actor` → 현재 실행 주체 계정
* `password: secrets.GITHUB_TOKEN` → GitHub가 기본 제공하는 토큰

문서에도 이 workflow 기준으로는 별도 `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` 없이
**기본 `GITHUB_TOKEN`으로 push 가능**하다고 적혀 있다.

즉, 수업 포인트는 **“모든 비밀번호를 직접 넣는 게 아니라 

GitHub 기본 토큰과 권한으로 처리할 수 있다”**는 점이야. ([GitHub][1])

---

```yaml
  - name: 이미지 빌드 및 푸시
    shell: bash
    working-directory: ${{ matrix.module_dir }}
    env:
      IMAGE_REGISTRY: ${{ env.IMAGE_REGISTRY }}
      IMAGE_NAME: ${{ matrix.image_name }}
      IMAGE_TAG: ${{ env.IMAGE_TAG }}
      PUSH_IMAGE: "true"
      LOAD_TO_MINIKUBE: "false"
    run: |
      ./scripts/build_jar.sh
      ./scripts/build_docker.sh
```

여기가 실질적인 본체다.

먼저 `working-directory: ${{ matrix.module_dir }}` 때문에
각 모듈 폴더로 들어가서 실행한다.

즉 matrix 값에 따라:

* `config/`
* `discovery/`
* `apigateway/`

중 하나에서 동일한 스크립트를 수행한다는 뜻이야. ([GitHub][1])

`env:` 부분은 스크립트에 넘겨주는 값들이다.

* `IMAGE_REGISTRY`: ghcr.io/소유자
* `IMAGE_NAME`: config 또는 discovery 또는 apigateway
* `IMAGE_TAG`: 커밋 SHA 7자리
* `PUSH_IMAGE: "true"` → 이미지 빌드 후 push까지 수행
* `LOAD_TO_MINIKUBE: "false"` → minikube에는 싣지 않음

이게 중요하다.

즉 이 workflow는 **클라우드 레지스트리 push용**이지, **로컬 minikube 적재용은 아니다**.

문서도 현재 구조를 “Docker 이미지 생성 후 GHCR push”로 설명하고 있고, 

서버 배포나 Kubernetes 반영은 나중 단계라고 분리해 둔다. ([GitHub][1])

그리고 `run:` 안에서 실제 하는 일은 딱 두 단계다.

1. `./scripts/build_jar.sh`
2. `./scripts/build_docker.sh`

즉:

* 먼저 Spring Boot 실행 jar를 만들고
* 그 jar를 포함한 Docker 이미지를 만들고
* `PUSH_IMAGE=true`니까 push까지 간다

문서도 이 저장소의 CI 단계가 **각 모듈의 `scripts/build_jar.sh`, `scripts/build_docker.sh`를 재사용한다**고 적고 있다. ([GitHub][1])

---

```yaml
  - name: 결과 출력
    shell: bash
    run: |
      echo "완료 이미지: ${{ env.IMAGE_REGISTRY }}/${{ matrix.image_name }}:${{ env.IMAGE_TAG }}"
```

이건 마지막 로그 출력이다.
예를 들면 이런 식으로 찍힌다.

`완료 이미지: ghcr.io/owner/apigateway:a1b2c3d`

실제 배포는 안 하지만,

적어도 **“어떤 이미지가 어떤 태그로 올라갔는지”** 확인할 수 있게 해 준다.

나중에 CD를 붙일 때는 바로 이 태그를 써서 

`docker pull` 하거나 `kubectl set image` 같은 데 연결할 수 있다. 

문서도 현재는 여기까지가 CI이고, 서버가 생기면 그 다음 단계로 배포를 붙인다고 설명한다. ([GitHub][1])

---

이 workflow를 한 줄 요약하면 이거다.

**`main/master에 관련 서비스 코드가 push되면
→ GitHub Actions가 각 서비스 jar를 빌드하고 
→ Docker 이미지를 만들고 
→ GHCR에 push한다.`** ([GitHub][1])

---

수업에서 특히 봐야 할 포인트만 다시 압축하면:

1. `on`
   → 언제 자동화가 시작되는지

2. `paths`
   → 어떤 변경일 때만 실행할지

3. `permissions`
   → 왜 GHCR push 권한이 필요한지

4. `matrix`
   → 여러 서비스를 반복 처리하는 방법

5. `setup-java`
   → 러너 환경 준비

6. `GITHUB_ENV`, `GITHUB_SHA`
   → 이미지 경로와 태그를 동적으로 만드는 법

7. `docker/login-action`
   → 레지스트리 인증 처리

8. `build_jar.sh`, `build_docker.sh`
   → 실제 빌드 책임이 어디 있는지

9. `PUSH_IMAGE=true`, `LOAD_TO_MINIKUBE=false`
   → 이 workflow가 “GHCR push용”이라는 점

---

네가 지금 이걸 공부할 때 제일 좋은 순서는:
**이 workflow 읽기 → 각 모듈의 `scripts/build_jar.sh` 확인 → `scripts/build_docker.sh` 확인**이야.
그래야 “Actions가 직접 다 하는 게 아니라, 결국 프로젝트 안의 스크립트를 호출하는 구조”라는 게 잡힌다.

다음 답변에서는 원하면 내가 바로 이어서
**`build_jar.sh` / `build_docker.sh`까지 레포 기준으로 연결해서 설명**해줄게.

[1]: https://raw.githubusercontent.com/truthplumage/MSA_PUBLIC/refs/heads/main/.github/workflows/image-registry-cicd.yml "raw.githubusercontent.com"
