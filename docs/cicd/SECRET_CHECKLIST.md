# 시크릿으로 관리할 값 정리

이 문서는 GitHub Actions, Kubernetes, 서비스 실행에서
시크릿으로 다뤄야 하는 값을 짧게 정리한 문서입니다.

## 1. 지금 `MSA` 저장소 workflow에서 꼭 필요한 시크릿

현재 [image-registry-cicd.yml](/Users/parkjinwoo/source/study/grepp_BE2/MSA/.github/workflows/image-registry-cicd.yml)은
GHCR push만 하므로 필수 시크릿이 없습니다.

이유:

- `GITHUB_TOKEN`을 사용함
- workflow에 `packages: write` 권한이 이미 들어 있음

즉 지금은 별도 `REGISTRY_USERNAME`, `REGISTRY_PASSWORD`를 넣지 않아도 됩니다.

## 2. 시크릿으로 관리해야 하는 대표 값

아래 값들은 Git에 넣지 말고 시크릿으로 관리하는 것이 맞습니다.

- DB 계정
  - `DB_URL`
  - `DB_USERNAME`
  - `DB_PASSWORD`
- JWT 관련 값
  - `TOKEN_MAKER`
  - `TOKEN_PRIVATE`
  - `TOKEN_PUBLIC`
- 외부 API 키
  - 예: 결제 키, 이메일 키, 문자 발송 키
- 클라우드 접속 정보
  - 예: `KUBE_CONFIG`, 서버 SSH 키, 클라우드 access key

## 3. 이 프로젝트에서 특히 시크릿으로 봐야 하는 값

지금 기준으로 특히 중요한 것은 아래입니다.

### 1) JWT 키

- `TOKEN_MAKER`
- `TOKEN_PRIVATE`
- `TOKEN_PUBLIC`

이유:

- 로그인 토큰 생성과 검증에 사용됨
- Git에 올리면 안 됨
- 값이 바뀌면 기존 토큰이 무효화될 수 있음

### 2) DB 접속 정보

- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`

이유:

- 실제 DB 계정 정보이기 때문

## 4. 나중에 클라우드 배포를 붙이면 추가될 시크릿

서버나 Kubernetes 배포를 자동화하면 아래가 추가될 수 있습니다.

- `KUBE_CONFIG`
- `SSH_PRIVATE_KEY`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

단, GHCR를 `GITHUB_TOKEN`으로만 쓰면
`REGISTRY_USERNAME`, `REGISTRY_PASSWORD`는 없어도 됩니다.

## 5. 어디에 넣나

상황에 따라 위치가 다릅니다.

### 1) GitHub Actions

저장 위치:

- `Settings -> Secrets and variables -> Actions`

### 2) Kubernetes

저장 위치:

- `Secret`

예:

- `member-service-secrets`

### 3) 로컬 실행

저장 위치:

- 환경변수
- `.env` 파일
- 별도 키 파일

단, `.env`, `pem`, `key` 파일은 Git에 올리지 않아야 합니다.

## 6. 한 줄 기준

아래에 해당하면 시크릿으로 보면 됩니다.

- 외부에 노출되면 안 되는 값
- 계정 로그인에 쓰는 값
- 토큰 서명에 쓰는 값
- 서버 접속에 쓰는 값
