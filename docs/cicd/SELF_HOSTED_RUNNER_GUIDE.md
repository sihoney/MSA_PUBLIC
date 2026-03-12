# Self-hosted Runner 정리

이 문서는 GitHub Actions의 self-hosted runner를 어떻게 붙이는지 정리한 문서입니다.

## 1. self-hosted runner가 뭔가

GitHub Actions는 원래 GitHub가 준비한 서버에서 실행됩니다.

self-hosted runner는 반대로:

- 내 PC
- 사내 서버
- 개인 서버

이런 내가 가진 장비 안에서 GitHub Actions 작업을 실행하는 방식입니다.

즉:

```text
GitHub가 명령을 보냄 -> 내 PC가 그 작업을 실제로 실행
```

## 2. 뭘 설치해야 하나

네. runner를 돌릴 장비 안에 설치가 필요합니다.

설치 대상:

- GitHub Actions runner 프로그램

그리고 이 프로젝트를 돌리려면 runner 장비 안에 아래도 있어야 합니다.

- Git
- JDK
- Docker
- kubectl
- minikube
- curl

즉 runner 하나만 설치하면 끝이 아니라,
실제로 워크플로가 사용하는 도구도 같이 준비돼 있어야 합니다.

## 3. 어디에 설치하나

보통 아래 중 하나에 설치합니다.

- 내 노트북
- 내 데스크톱
- 사내 리눅스 서버
- 항상 켜져 있는 개발용 머신

로컬 자동배포 기준이라면 보통:

- minikube가 돌고 있는 같은 PC

여기에 설치하는 것이 가장 단순합니다.

## 4. 왜 쓰나

이 프로젝트처럼 로컬 Kubernetes까지 같이 써야 하면,
GitHub 기본 runner는 내 PC 안의 minikube에 접근할 수 없습니다.

그래서:

- 내 PC 안에 runner를 설치하고
- GitHub Actions가 그 PC 안에서 실행되게 만드는 겁니다

## 5. 지금 레포에서 연결된 파일

현재 이 레포에는 self-hosted runner 기준 workflow와 실행 스크립트가 들어 있습니다.

- [local-cicd.yml](/Users/parkjinwoo/source/study/grepp_BE2/.github/workflows/local-cicd.yml)

이 파일은 아래처럼 동작합니다.

1. self-hosted runner에서 실행
2. 저장소 체크아웃
3. JDK 설정
4. 운영체제에 맞는 로컬 배포 스크립트 실행

실행 스크립트:

- [README.md](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/README.md)
- mac: [1_check_runner_env.sh](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/mac/1_check_runner_env.sh)
- mac: [2_run_local_cicd.sh](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/mac/2_run_local_cicd.sh)
- mac: [3_check_local_cicd.sh](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/mac/3_check_local_cicd.sh)
- Windows: [1_check_runner_env.bat](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/windows/1_check_runner_env.bat)
- Windows: [2_run_local_cicd.bat](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/windows/2_run_local_cicd.bat)
- Windows: [3_check_local_cicd.bat](/Users/parkjinwoo/source/study/grepp_BE2/MSA/scripts/self-hosted-runner/windows/3_check_local_cicd.bat)

## 6. 설치 흐름

순서는 보통 이렇습니다.

1. GitHub 저장소 열기
2. `Settings`
3. `Actions`
4. `Runners`
5. `New self-hosted runner`
6. 운영체제 선택
7. 안내되는 명령을 runner 장비에서 실행

그러면 runner 프로그램이 다운로드되고 등록됩니다.

## 7. runner 장비에서 준비할 것

등록 전에 아래를 먼저 확인하면 편합니다.

```bash
git --version
java -version
docker --version
kubectl version --client
minikube version
curl --version
```

그리고 Docker와 minikube가 실제로 동작해야 합니다.

예:

```bash
docker ps
minikube status
kubectl get ns
```

## 8. GitHub Secrets도 필요하다

이 레포의 로컬 workflow는 아래 값을 사용합니다.

- `TOKEN_MAKER`
- `TOKEN_PRIVATE`
- `TOKEN_PUBLIC`

GitHub 저장소의 `Settings -> Secrets and variables -> Actions`에 넣으면 됩니다.

## 9. runner가 실제로 하는 일

현재 기준으로는 runner가 아래를 수행합니다.

1. minikube 시작
2. `config-service` 배포
3. `discovery` 배포
4. `apigateway` 배포
5. `member-service` 배포
6. Swagger 응답 확인

즉 runner는 단순 감시 프로그램이 아니라,
실제로 내 PC에서 배포 스크립트를 실행하는 주체입니다.

## 10. 주의할 점

### 1) runner PC는 켜져 있어야 함

꺼져 있으면 workflow가 실행되지 않습니다.

### 2) 포트 충돌 가능

로컬 앱 실행과 minikube 배포를 같이 쓰면 포트가 충돌할 수 있습니다.

### 3) 권한 문제

runner 계정이 Docker, kubectl, minikube를 실행할 수 있어야 합니다.

### 4) 토큰/키 관리

JWT 키는 GitHub Secrets에 넣고,
파일 자체는 Git에 올리지 않는 것이 안전합니다.

## 11. 가장 단순한 이해

한 줄로 정리하면:

```text
self-hosted runner = GitHub Actions를 내 컴퓨터에서 실행하게 만드는 프로그램
```

즉 질문에 답만 짧게 하면:

- 네, 내부 장비에 설치해야 합니다.
- 보통 minikube가 있는 그 PC에 설치합니다.
- 그리고 그 장비 안에 Docker, kubectl, minikube도 같이 준비해야 합니다.
