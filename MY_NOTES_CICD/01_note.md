# 6일차 CI/CD

오늘 수업에서 배우는 핵심은 

- “MSA 프로젝트를 자동으로 빌드하고, 
- Docker 이미지를 만들고, 
- 필요하면 로컬 Kubernetes(minikube)까지 반영하는 흐름”이야.

---

네가 오늘 수업에서 아마 배우게 될 내용은 크게 4개다.

## 첫째, CI와 CD를 구분하는 법이야.

이 레포의 image-registry-cicd.yml은 “서버 배포”까지는 하지 않고, 

config, discovery, apigateway 3개 모듈의 이미지를 만들어 

GHCR(GitHub Container Registry) 에 올리는 역할만 한다. 

즉, 지금 이 workflow는 엄밀히 말하면 

CI 중심 + 이미지 레지스트리 push까지이고, 실제 서버 반영은 아직 붙지 않은 상태다. 

문서도 “지금은 CI만 만들고, CD는 나중에 붙이는 구조”라고 설명한다.

---

## 둘째, GitHub Actions workflow를 읽는 법이야.

이 workflow는 main 또는 master에 push될 때, 

그리고 
    config/**, 
    discovery/**, 
    apigateway/**, 
    .github/workflows/image-registry-cicd.yml
이 바뀌었을 때만 실행되도록 되어 있다. 

또 matrix를 써서 config, discovery, apigateway를 각각 병렬 비슷하게 처리하고, 

각 모듈에서 build_jar.sh → build_docker.sh 순서로 실행한다. 

그리고 GHCR 로그인에는 별도 계정 비밀번호 대신 GITHUB_TOKEN을 쓰고 있다. 

이건 수업에서 거의 반드시 짚을 포인트다.

---

## 셋째, 로컬 자동배포 방식 두 가지를 비교하게 될 가능성이 크다.

이 저장소 문서에는 로컬 CI/CD 방법으로 

- Jenkins와 
- GitHub Actions self-hosted runner 

두 가지가 정리되어 있다. 

로컬 가이드는 “내 PC 코드 변경 → 로컬 빌드 → 로컬 이미지 생성 → minikube 반영” 구조를 설명하고, 

self-hosted runner 문서는 

- “GitHub가 명령을 보내고, 
- 내 PC가 실제 작업을 실행”

하는 방식이라고 설명한다. 

Jenkins 문서는 

- Jenkins가 운영체제별 4_run_local_deploy 스크립트를 대신 실행

하는 구조라고 정리한다.

--

## 넷째, 시크릿과 운영 환경 변수 관리야.

이 레포는 GHCR push 자체에는 필수 시크릿이 없다고 적어 두었지만, 

JWT 관련 값인 TOKEN_MAKER, TOKEN_PRIVATE, TOKEN_PUBLIC, 그리고 DB 접속 정보는 

Git에 넣지 말고 시크릿으로 관리해야 한다고 분명히 적고 있다. 

이건 수업에서 “왜 어떤 값은 코드에 두면 안 되는가”를 이해하는 데 중요하다.

---

## 네가 가장 먼저 봐야 할 파일 순서

### 1순위: .github/workflows/image-registry-cicd.yml

여기가 핵심이다.
이 파일에서 봐야 할 포인트는:

언제 실행되는지: **push, workflow_dispatch**

어떤 모듈이 대상인지: config, discovery, apigateway

어떤 권한이 필요한지: contents: read, packages: write

어떤 순서로 동작하는지: 

```
checkout 
→ JDK 17 
→ GHCR 로그인 
→ jar 빌드 
→ Docker 이미지 빌드/푸시
```

이 파일 하나를 읽으면 “CI 파이프라인이 코드로 어떻게 표현되는지” 감이 잡힌다.

---

### 2순위: docs/cicd/CLOUD_CICD_GUIDE.md

이건 “왜 이 workflow를 이렇게 만들었는지”를 설명해 주는 해설서다.

특히 

- “지금은 서버 배포 없이 이미지까지만 올린다”, 
- “가장 단순한 권장 구조는 GitHub Actions → GHCR push다”

라는 부분이 중요하다. 

즉, 네가 workflow를 읽다가 “왜 여기서 끝나지?” 싶을 때 이 문서가 답을 준다.

---

### 3순위: docs/cicd/LOCAL_CICD_GUIDE.md

수업에서 로컬 minikube까지 연결해서 설명할 가능성이 높으면 이 문서가 중요하다.

여기서는 

- 로컬 CI 단계(build_jar.sh, build_docker.sh)와 
- 로컬 CD 단계(register_k8s.sh, run_k8s.sh, check_k8s.sh)

를 구분해서 설명한다. 

즉, “빌드”와 “쿠버네티스 반영”을 분리해서 이해하게 해 준다.

---

### 4순위: docs/cicd/SELF_HOSTED_RUNNER_GUIDE.md 또는 JENKINS_LOCAL_GUIDE.md

수업이 GitHub Actions 중심이면 self-hosted runner 문서를,
수업이 Jenkins 중심이면 Jenkins 문서를 보면 된다.

두 문서 모두 “자동화 도구가 실제로 어떤 스크립트를 호출하는가”를 설명해 준다.

--- 

### 5순위: scripts/jenkins, scripts/self-hosted-runner

여기는 이론보다 실전이다.

읽을 때는 “자동화 도구가 결국 이 스크립트를 대신 실행하는구나”라는 관점으로 보면 된다. 

README에서 각 폴더의 역할도 정리돼 있다. 

scripts/jenkins는 설치/시작/배포/확인/중지 흐름이고, 

scripts/self-hosted-runner는 환경 확인 → 로컬 배포 → 상태 확인 순서다.

---

## 오늘 수업에서 배우는 건 아마 이런 흐름일 거야.

```
코드 수정
→ GitHub에 push
→ GitHub Actions 또는 Jenkins가 빌드 실행
→ jar 생성
→ Docker 이미지 생성
→ GHCR 또는 로컬 이미지 저장
→ minikube/Kubernetes 반영
```

--- 

네가 수업 전에 최소한으로 준비하려면 이렇게 보면 된다.

image-registry-cicd.yml을 먼저 보고

CLOUD_CICD_GUIDE.md로 전체 흐름을 이해하고

로컬 실습이면 LOCAL_CICD_GUIDE.md를 보고

수업이 
    Jenkins면            JENKINS_LOCAL_GUIDE.md, 
    GitHub Actions면     SELF_HOSTED_RUNNER_GUIDE.md
를 보면 된다.

네 수준에서 특히 놓치면 안 되는 포인트는 이것뿐이다.

CI는 “검증하고 빌드하는 자동화”

CD는 “배포까지 이어지는 자동화”

이 레포는 지금 이미지 빌드/푸시 중심

로컬 minikube 반영은 추가 스크립트/Jenkins/self-hosted runner로 이어진다.

원하면 다음 답변에서 내가 이 레포 기준으로 **“image-registry-cicd.yml 한 줄씩 해설”**해줄게.