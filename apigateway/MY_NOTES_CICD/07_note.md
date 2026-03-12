# apigateway/scripts 폴더

응. 이 브랜치의 `apigateway/scripts` 는 

**“jar 빌드 → Docker 이미지 생성 → Kubernetes 등록 → 실행 → 상태 확인”** 흐름을 

단계별로 쪼개 둔 셸 스크립트 모음이야. 

`all_in_one.sh`가 그 순서를 그대로 호출하고 있고, 

내부적으로 `build_jar.sh`, `build_docker.sh`, `register_k8s.sh`, `run_k8s.sh`, `check_k8s.sh`를 차례로 실행해. ([GitHub][1])

---

가장 먼저 전체 그림부터 잡자.

`all_in_one.sh`

* 1단계: `./build_jar.sh`
* 2단계: `./build_docker.sh`
* 3단계: `./register_k8s.sh`
* 4단계: `./run_k8s.sh`
* 5단계: `./check_k8s.sh`

즉, 이 스크립트는 **apigateway를 쿠버네티스에 올리기 위한 자동 실행 버튼**이라고 보면 된다. ([GitHub][1])

---

## 1. 제일 먼저 알아야 할 셸 문법

스크립트 맨 위에 공통으로 붙어 있는 이 줄이 중요해.

```bash
#!/usr/bin/env bash
set -euo pipefail
```

이건 그냥 장식이 아니야.

* `#!/usr/bin/env bash`
  이 파일을 **bash 셸로 실행하라**는 뜻이야.
* `set -e`
  중간에 명령 하나라도 실패하면 바로 종료.
* `set -u`
  선언되지 않은 변수를 쓰면 에러.
* `set -o pipefail`
  파이프라인(`|`) 안 앞쪽 명령이 실패해도 실패로 잡음.

즉, **조용히 실패하지 않게 만드는 안전장치**야. CI/CD에서 특히 중요하다. ([GitHub][1])

---

## 2. 경로 잡는 부분: 이건 꼭 이해해야 해

여러 스크립트에 이런 코드가 들어 있어.

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${MODULE_DIR}"
```

이건 현재 스크립트 파일의 위치를 기준으로 폴더를 계산해서,
**어디서 실행하든 apigateway 모듈 폴더로 이동**하게 만드는 코드야. ([GitHub][2])

각 명령 의미는 이래:

* `BASH_SOURCE[0]` : 현재 실행 중인 스크립트 파일
* `dirname` : 그 파일의 디렉터리명 추출
* `cd ... && pwd` : 해당 폴더로 이동한 뒤 절대경로 얻기
* `MODULE_DIR=.../..` : scripts 상위 폴더, 즉 `apigateway/`
* `cd "${MODULE_DIR}"` : 실제 작업 디렉터리를 모듈 루트로 변경

이 패턴은 실무에서도 엄청 자주 본다.
왜냐하면 **“내가 지금 어느 폴더에서 실행했는지”에 의존하면 스크립트가 자주 깨지기 때문**이야.

---

## 3. `build_jar.sh` 에서 꼭 알아야 할 것

이 스크립트 핵심은 이거야.

```bash
./gradlew clean bootJar
```

이 명령은 Gradle Wrapper를 이용해서

* `clean`: 기존 빌드 산출물 삭제
* `bootJar`: 스프링 부트 실행용 jar 생성

을 수행한다. 그리고 나서 `find`로 `build/libs` 아래에서 실제 실행용 jar를 찾는데, 
`*plain.jar`는 제외하고 있어. ([GitHub][3])

왜 `plain.jar`를 제외하냐면,
스프링 부트 프로젝트는 경우에 따라

* 일반 jar
* 실행 가능한 fat jar(bootJar)
  두 종류가 생길 수 있는데,

여기서는 **실행 가능한 부트 jar만 필요**하기 때문이야. 그래서 이런 조건이 붙어 있다.

```bash
find build/libs 
    -maxdepth 1 
    -type f 
    -name '*.jar' 
    ! -name '*plain.jar'
```

여기서 꼭 알아둘 옵션:

* `find`: 파일 찾기
* `-maxdepth 1`: 하위 폴더 깊게 안 내려감
* `-type f`: 파일만 찾음
* `-name '*.jar'`: jar 파일 찾음
* `! -name '*plain.jar'`: plain.jar 제외
* `head -n 1`: 첫 번째 결과 하나만 사용

즉, **“실행 가능한 jar 하나만 골라라”**라는 뜻이야. ([GitHub][3])

---

## 4. `build_docker.sh` 에서 꼭 알아야 할 것

핵심 명령은 이것들이다.

```bash
docker build -t "${IMAGE}" .
minikube image load "${IMAGE}"
docker push "${IMAGE}"
```

---

이 스크립트는 먼저 환경변수 기본값을 잡아. ([GitHub][2])

```bash
IMAGE_REGISTRY="${IMAGE_REGISTRY:-local}"
IMAGE_NAME="${IMAGE_NAME:-apigateway}"
IMAGE_TAG="${IMAGE_TAG:-dev}"
LOAD_TO_MINIKUBE="${LOAD_TO_MINIKUBE:-false}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
```

이 문법은 꼭 알아야 해.

```bash
VAR="${VAR:-default}"
```

의미:

* 환경변수 `VAR`가 이미 있으면 그 값 사용
* 없으면 `default` 사용

즉 기본값 주입 문법이야. CI/CD에서 엄청 자주 쓴다. ([GitHub][2])

---

이 스크립트 흐름은:

1. `build/libs` 폴더가 있는지 확인
2. 실행용 jar가 있는지 확인
3. `docker build -t local/apigateway:dev .` 같은 식으로 이미지 생성
4. `LOAD_TO_MINIKUBE=true` 면 Minikube 내부에 이미지 적재
5. `PUSH_IMAGE=true` 면 원격 레지스트리로 push

이 구조야. ([GitHub][2])

---

특히 중요한 포인트:

### `docker build -t "${IMAGE}" .`

* 현재 폴더의 `Dockerfile` 또는 지정된 Dockerfile 기준으로 이미지 빌드
* `-t` 는 태그 지정
* `.` 은 빌드 컨텍스트(현재 폴더)

### `minikube image load`

이건 **로컬에서 만든 이미지를 Minikube 클러스터가 볼 수 있게 넣는 작업**이야.
로컬 PC에 이미지를 만들어도, 
Minikube 내부 Docker/Container runtime이 그 이미지를 못 보면 Pod가 못 뜬다. 
그래서 이 명령이 필요할 수 있어. ([GitHub][2])

### `docker push`

원격 레지스트리(GHCR, Docker Hub 등)에 업로드하는 명령이다.
지금 스크립트는 기본값이 `PUSH_IMAGE=false`라서, 
수업 환경이 로컬 Minikube 위주라는 뜻에 가깝다. ([GitHub][2])

---

## 5. `register_k8s.sh` 는 “실행”보다 “등록”에 가깝다

이 파일은 이름이 되게 잘 지어졌어.
핵심은 **쿠버네티스 리소스를 먼저 apply만 해두고, 
replica는 0으로 내려서 아직 실행은 안 하게 한다**는 점이야. ([GitHub][4])

---

중요 명령:

```bash
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "${MODULE_DIR}/k8s/apigateway.yaml"
kubectl -n "${NAMESPACE}" scale deployment/apigateway --replicas=0
```

---

### 1) namespace 생성

```bash
kubectl create namespace msa 
    --dry-run=client 
    -o yaml | 
    
kubectl apply -f -
```

이건 초보가 처음 보면 진짜 헷갈리는데, 의미는:

* namespace yaml을 “실제로 만들지는 않고” 출력
* 그 결과를 `kubectl apply -f -`로 넘겨서 적용

이 방식의 장점은 **이미 있어도 크게 문제 없이 재실행 가능**하다는 점이야.
즉, CI/CD에서 다시 돌려도 비교적 안전하다. ([GitHub][4])

### 2) 리소스 등록

```bash
kubectl apply -f k8s/apigateway.yaml
```

이 YAML 안에는

* `Service`
* `Deployment`

가 들어 있다. 

서비스는 `LoadBalancer`, 
디플로이먼트는 `apigateway` 컨테이너를 띄우도록 정의되어 있다.

환경변수로 

`SERVER_PORT=8000`, 
`SPRING_APPLICATION_NAME=apigateway`, 
`SPRING_CLOUD_CONFIG_URI=http://config-service:8888`, 
`EUREKA_INSTANCE_HOSTNAME=discovery` 

등이 들어가 있다. 

readiness/liveness probe도 `/actuator/health`로 잡혀 있다. ([GitHub][5])

### 3) replica 0

```bash
kubectl scale deployment/apigateway --replicas=0
```

이게 중요하다.
리소스는 등록해 두되 **Pod는 아직 안 뜨게 해 두는 것**이야.

왜 이렇게 하냐?

* 아직 이미지 바꾸기 전일 수 있음
* 다른 의존 서비스(config, discovery)가 먼저 떠야 할 수 있음
* 등록과 실행을 분리하면 디버깅이 쉬움

즉, **“선언부터 해두고, 실제 가동은 다음 단계에서”**라는 전략이다. ([GitHub][4])

---

## 6. `run_k8s.sh` 는 진짜 실행 단계다

핵심 명령:

```bash
kubectl -n "${NAMESPACE}" set image deployment/apigateway apigateway="${IMAGE}"
kubectl -n "${NAMESPACE}" scale deployment/apigateway --replicas=1
kubectl -n "${NAMESPACE}" rollout status deployment/apigateway
```

이 스크립트는 이미 등록된 Deployment에 대해

1. 이미지 교체
2. replica 1로 올리기
3. 배포 완료될 때까지 기다리기

를 한다. ([GitHub][6])

---

### `kubectl set image`

이 명령은 Deployment 템플릿 안의 컨테이너 이미지를 바꾸는 거야.
형식은:

```bash
kubectl set image deployment/배포이름 컨테이너이름=이미지이름:태그
```

여기서는

* 배포 이름: `apigateway`
* 컨테이너 이름: `apigateway`
* 이미지: `local/apigateway:dev` 같은 값

이렇게 대응된다. ([GitHub][6])

### `scale --replicas=1`

```bash
kubectl -n "${NAMESPACE}" scale deployment/apigateway --replicas=1
```

Pod를 1개 띄우라는 뜻.

### `rollout status`

```bash
kubectl -n "${NAMESPACE}" rollout status deployment/apigateway
```

새 이미지로 교체된 Deployment가 정상적으로 준비되는지 확인하는 명령이야.

배포 중간에 실패하면 여기서 멈추거나 에러를 보여준다. 그래서 매우 중요하다. ([GitHub][6])

---

## 7. `check_k8s.sh` 는 확인용 치트시트다

이건 운영/학습 둘 다에서 되게 좋은 스크립트야.

```bash
kubectl -n "${NAMESPACE}" get deployment apigateway
kubectl -n "${NAMESPACE}" get pods -l app.kubernetes.io/name=apigateway -o wide
kubectl -n "${NAMESPACE}" get svc apigateway
```

그리고 마지막에 이런 예시도 출력해 준다.

```bash
kubectl -n msa logs deploy/apigateway
kubectl -n msa port-forward svc/apigateway 8000:8000
http://localhost:8000/swagger-ui/index.html
```

즉 이 스크립트는

* 배포 객체 상태
* 실제 Pod 상태
* Service 상태
  를 보고, 필요하면 로그와 포트포워딩까지 이어서 할 수 있게 안내해 준다. ([GitHub][7])

---

여기서 꼭 알아둘 것:

### `get deployment`

```bash
kubectl -n "${NAMESPACE}" get deployment apigateway
```

원하는 개수/준비된 개수 확인

---

### `get pods -l ...`

```bash
kubectl -n "${NAMESPACE}" get pods -l app.kubernetes.io/name=apigateway -o wide
```

라벨로 **특정 앱 Pod**만 필터링
`-l` 은 label selector

### `-o wide`

더 자세한 정보(IP, node 등) 출력

---

### `get svc`

```bash
kubectl -n "${NAMESPACE}" get svc apigateway
```

Service 노출 상태 확인

---

### `logs deploy/apigateway`

Deployment 기준 로그 보기

### `port-forward svc/apigateway 8000:8000`

내 로컬 8000 포트를 쿠버네티스 서비스 8000 포트에 연결

---

## 8. 이 스크립트에서 “진짜 중요한 명령어”만 추리면

네가 수업 복습용으로 최소한 이 정도는 알아야 한다.

### Bash

* `set -euo pipefail`
* `$(...)`
* `dirname`
* `pwd`
* `cd`
* `find`
* `head`
* `if [[ ... ]]`
* 환경변수 기본값 문법: `${VAR:-default}`

### Gradle

* `./gradlew clean bootJar`

### Docker

* `docker build -t ... .`
* `docker push ...`

### Minikube

* `minikube image load ...`

### Kubernetes

* `kubectl apply -f ...`
* `kubectl create namespace ... --dry-run=client -o yaml | kubectl apply -f -`
* `kubectl scale deployment/... --replicas=n`
* `kubectl set image deployment/... container=image:tag`
* `kubectl rollout status deployment/...`
* `kubectl get deployment`
* `kubectl get pods -l ...`
* `kubectl get svc`
* `kubectl logs deploy/...`
* `kubectl port-forward svc/... 로컬포트:서비스포트`

이 정도만 잡아도 수업 내용이 훨씬 덜 흐릿해질 거야. ([GitHub][2])

---

## 9. 이 apigateway 스크립트에서 꼭 알아야 할 핵심 개념 4개

### 1) “빌드”와 “배포”는 다르다

* `build_jar.sh` = 자바 애플리케이션 빌드
* `build_docker.sh` = 이미지를 만듦
* `register_k8s.sh` / `run_k8s.sh` = 쿠버네티스에 반영

이걸 섞어 생각하면 안 된다. ([GitHub][1])

### 2) “등록”과 “실행”도 분리돼 있다

`register_k8s.sh`는 apply 후 replica 0,
`run_k8s.sh`는 image 교체 후 replica 1.

이 분리는 디버깅과 단계적 제어를 쉽게 해 준다. ([GitHub][4])

### 3) 이미지 태그/이름은 환경변수로 바뀔 수 있다

같은 스크립트를 로컬, Minikube, 원격 registry 환경에서 재사용하려는 구조다. ([GitHub][2])

### 4) 쿠버네티스 YAML과 스크립트가 같이 읽혀야 한다

스크립트만 보면 왜 `set image` 하는지 헷갈릴 수 있는데, 

YAML 안에 이미 기본 이미지 `apigateway:dev`가 박혀 있고, 

실행 단계에서 그걸 다시 덮어쓴다. 

Service는 8000 포트, 
Deployment도 8000 포트, 
health check는 `/actuator/health`다. ([GitHub][5])

---

## 10. 네가 특히 헷갈릴 만한 포인트를 미리 짚으면

**왜 `register_k8s.sh`에서 apply 해놓고 또 `run_k8s.sh`에서 set image를 하지?**
→ YAML 기본값으로 등록만 해두고, 실제 실행 시점에 원하는 이미지 태그를 꽂아 넣으려는 거야. 
환경별 재사용성이 좋아진다. ([GitHub][4])

**왜 `replicas=0`으로 내리나?**
→ 리소스는 만들어 두되 아직 실행시키지 않으려는 거야. 등록과 실행 분리. ([GitHub][4])

**왜 `minikube image load`가 필요한가?**
→ 로컬 Docker 이미지가 Minikube 내부에서 안 보일 수 있기 때문이야. ([GitHub][2])

**왜 `plain.jar`를 제외하지?**
→ 스프링 부트 실행용 jar만 골라야 해서. ([GitHub][3])

---
