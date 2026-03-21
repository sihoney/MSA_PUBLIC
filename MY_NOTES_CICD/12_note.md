# CI/CD (설정) 파일 구조도(연결도)

좋아. 이 브랜치 기준으로 **“어느 파일이 무엇을 담당하고, 어디로 이어지는지”**를 한눈에 보이게 그려줄게.

## 1. 제일 단순한 전체 구조도

```text
[코드 push]
   │
   ▼
[.github/workflows/*.yml]
   │
   ├─ 어떤 브랜치/경로 변경에 반응할지 결정
   ├─ 체크아웃
   ├─ GHCR 로그인
   └─ Docker 이미지 빌드/푸시 실행
   │
   ▼
[apigateway/Dockerfile]
   │
   ├─ Gradle로 bootJar 생성
   ├─ 런타임 이미지에 jar 복사
   └─ 컨테이너 실행 방식 정의
   │
   ▼
[GHCR 이미지]
   │
   ▼
(여기까지가 GitHub Actions 쪽 자동화)

--------------------------------------------

[apigateway/scripts/*.sh]
   │
   ├─ jar 빌드
   ├─ docker image 생성
   ├─ k8s 리소스 등록
   ├─ deployment image 교체
   └─ 실행/상태 확인
   │
   ▼
[apigateway/k8s/apigateway.yaml]
   │
   ├─ Service 정의
   └─ Deployment 정의
   │
   ▼
[Kubernetes / Minikube 에서 apigateway 실행]
```

이 저장소는 지금 **두 줄**로 이해하면 편해.

* **줄 1: GitHub Actions → 이미지 만들고 GHCR에 올림**
* **줄 2: scripts + k8s yaml → 쿠버네티스에 등록하고 실행**

이 두 줄이 완전히 한 파일에서 합쳐진 구조는 아니야. ([GitHub][1])

---

## 2. 파일별 역할 구조도

```text
.github/workflows/apigateway-registry.yml
   └─ apigateway 전용 이미지 빌드/푸시

.github/workflows/image-registry-cicd.yml
   └─ config / discovery / apigateway 공통 이미지 빌드/푸시

apigateway/Dockerfile
   └─ apigateway 이미지를 어떻게 만들지 정의

apigateway/k8s/apigateway.yaml
   └─ apigateway를 k8s에서 어떻게 띄울지 정의

apigateway/scripts/build_jar.sh
   └─ jar 생성

apigateway/scripts/build_docker.sh
   └─ docker image 생성 / 옵션에 따라 push

apigateway/scripts/register_k8s.sh
   └─ k8s yaml apply, replica 0으로 등록만

apigateway/scripts/run_k8s.sh
   └─ 실제 이미지 연결, replica 1로 실행

apigateway/scripts/check_k8s.sh
   └─ deployment / pod / service 상태 확인

apigateway/scripts/all_in_one.sh
   └─ 위 과정을 순서대로 한 번에 실행
```

`all_in_one.sh`는 실제로 `jar 생성 → 도커 이미지 생성 → 쿠버네티스 리소스 등록 → 쿠버네티스 실행 → 상태 확인` 순서를 그대로 호출한다. ([GitHub][2])

---

## 3. GitHub Actions 쪽 흐름

### A. apigateway 전용 workflow

```text
push (main-gateway, apigateway 관련 경로 변경)
   ▼
.github/workflows/apigateway-registry.yml
   ▼
actions/checkout
   ▼
GHCR 로그인
   ▼
apigateway/Dockerfile 로 이미지 빌드
   ▼
GHCR push
```

이 파일 주석 자체가 **“apigateway/Dockerfile 기준으로 이미지를 빌드하고 GHCR에만 올린다”**, 그리고 **“별도 shell 스크립트는 호출하지 않는다”**고 말하고 있어. 즉 이 워크플로는 **이미지 publishing 전용**에 가깝다. ([GitHub][1])

### B. 공용 workflow

```text
push (main/master, config/discovery/apigateway 변경)
   ▼
.github/workflows/image-registry-cicd.yml
   ▼
matrix(config, discovery, apigateway)
   ▼
Docker build-push-action
   ▼
GHCR push
```

이 파일도 주석에서 **“서버 배포까지는 하지 않고 GHCR까지 올리는 역할만 담당”**한다고 적고 있다. 그리고 현재 활성화된 방식은 `docker/build-push-action@v5`를 쓰는 구조고, shell 스크립트 재사용 부분은 주석 처리되어 있다. ([GitHub][3])

---

## 4. Dockerfile 쪽 흐름

`apigateway/Dockerfile`은 이렇게 읽으면 돼.

```text
[builder stage]
Gradle 이미지 사용
   ▼
소스/gradle 파일 복사
   ▼
./gradlew bootJar

[runtime stage]
eclipse-temurin:8-jre
   ▼
빌드된 jar 복사
   ▼
8000 포트 노출
   ▼
java -jar /usr/app/app.jar
```

즉 Dockerfile은 **“GitHub Actions가 이미지를 만들 때 참고하는 조리법”**이다.
워크플로가 Dockerfile을 실행하고, Dockerfile이 실제 이미지를 만든다. ([GitHub][4])

---

## 5. Kubernetes 쪽 흐름

`apigateway/k8s/apigateway.yaml`은 크게 두 덩어리야.

```text
Service
 └─ apigateway 로 접근할 창구

Deployment
 └─ apigateway 컨테이너를 몇 개, 어떤 이미지로 띄울지 정의
```

여기에는

* `Service` 이름: `apigateway`
* `Deployment` 이름: `apigateway`
* 기본 이미지: `apigateway:dev`
* 포트: `8000`
* readiness/liveness probe: `/actuator/health`
* 환경변수: `SPRING_APPLICATION_NAME`, `SPRING_CLOUD_CONFIG_URI`, `EUREKA_INSTANCE_HOSTNAME` 등

이 들어 있다. 즉 이 파일은 **이미지를 만드는 파일이 아니라, 이미지를 클러스터에서 어떻게 띄울지 적어둔 파일**이다. ([GitHub][5])

---

## 6. scripts 쪽 흐름

여기가 가장 헷갈리기 쉬운 부분인데, 사실 역할은 명확해.

### 구조도

```text
all_in_one.sh
   ├─ build_jar.sh
   ├─ build_docker.sh
   ├─ register_k8s.sh
   ├─ run_k8s.sh
   └─ check_k8s.sh
```

### register_k8s.sh

```text
namespace 준비
   ▼
kubectl apply -f apigateway/k8s/apigateway.yaml
   ▼
deployment/apigateway replicas=0
```

즉 **리소스는 등록하지만 아직 실행은 안 하게** 만든다. ([GitHub][6])

### run_k8s.sh

```text
IMAGE_REGISTRY/IMAGE_NAME:IMAGE_TAG 조합
   ▼
kubectl set image deployment/apigateway ...
   ▼
replicas=1
   ▼
rollout status 확인
```

즉 **등록된 Deployment에 실제 이미지를 꽂고 실행하는 단계**다. ([GitHub][7])

---

## 7. 네 질문에 대한 가장 정확한 연결 순서

네가 말한:

> github workflow yml, k8s yml, dockerfile 이 순서로 cicd에 기여한다고 보면 될까?

이건 **정확한 순서가 아니야.**

더 정확하게는 이렇게 나눠야 해.

### GitHub Actions 라인

```text
workflow yml
   ▼
Dockerfile
   ▼
GHCR 이미지
```

### Kubernetes 실행 라인

```text
k8s yml
   ▼
kubectl apply / set image / scale
   ▼
실행된 Pod
```

즉 `k8s yml`은 `Dockerfile`보다 앞에서 이미지를 만드는 데 기여하는 파일이 아니고,
**만들어진 이미지를 클러스터에서 어떻게 쓸지**를 정의하는 파일이야. ([GitHub][1])

---

## 8. 한 장으로 다시 그리면

```text
[1] 개발자가 코드 push
   │
   ▼
[2] .github/workflows/*.yml
   │  - 언제 실행할지
   │  - 어떤 모듈을 빌드할지
   │  - 어디로 push할지
   ▼
[3] apigateway/Dockerfile
   │  - jar 만들기
   │  - 이미지 구성하기
   ▼
[4] GHCR
   │  - 완성된 이미지 저장
   ▼
-------------------------------
   ▼
[5] apigateway/k8s/apigateway.yaml
   │  - service/deployment 정의
   ▼
[6] apigateway/scripts/register_k8s.sh
   │  - apply
   │  - replica 0
   ▼
[7] apigateway/scripts/run_k8s.sh
   │  - set image
   │  - replica 1
   │  - rollout status
   ▼
[8] Kubernetes / Minikube 에서 실행
```

---

## 9. 이렇게 기억하면 안 헷갈린다

딱 세 문장으로 외우면 된다.

* **workflow yml** = 자동화의 시작점, “언제 무엇을 실행할지”
* **Dockerfile** = 이미지 제작 설명서, “무슨 이미지를 만들지”
* **k8s yml** = 실행 명세서, “그 이미지를 클러스터에서 어떻게 띄울지”

이 프로젝트는 현재 **“이미지 빌드/푸시 자동화”와 “쿠버네티스 실행”이 완전히 한 줄로 합쳐져 있지 않고 분리된 구조**로 보는 게 가장 정확하다. ([GitHub][1])

