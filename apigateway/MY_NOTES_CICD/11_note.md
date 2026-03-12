# CI/CD와 연관된 설정 파일

응, 그런데 네가 잡은 순서는 **반쯤만 맞아**.

이 브랜치 기준으로는 

```
`GitHub workflow yml 
        ▼
Dockerfile 
        ▼
(이미지 레지스트리) 
        ▼
k8s yml` 
```

쪽이 더 정확하고, 

**k8s yml은 지금 GitHub Actions가 직접 적용하는 구조가 아니라 

로컬/수동 배포 스크립트 쪽에서 쓰인다**고 보는 게 맞아. 

즉 `workflow yml, k8s yml, dockerfile` 순서로 한 줄로 묶기엔 조금 틀어져 있어. ([GitHub][1])

---

이 프로젝트에서 apigateway 기준으로 자동화에 실제로 걸리는 파일을 역할별로 나누면 이렇게 보면 된다.

첫째, **트리거와 CI 파이프라인 정의**는 `.github/workflows/*.yml` 이 맡고, 
둘째, **이미지 빌드 방법**은 `apigateway/Dockerfile` 이 맡고, 
셋째, **쿠버네티스에 어떤 형태로 띄울지**는 `apigateway/k8s/apigateway.yaml` 이 맡고, 
넷째, **로컬에서 빌드·등록·실행 순서를 묶는 것**은 `apigateway/scripts/*.sh` 가 맡는다. ([GitHub][2])

---

### 가장 먼저 봐야 할 건 워크플로 두 개야.

`.github/workflows/apigateway-registry.yml` 은 

- **apigateway 전용**이고, 
- `main-gateway` 브랜치에서 `apigateway/**` 또는 해당 워크플로 파일이 바뀌면 실행되며, 
- checkout 후 GHCR 로그인, 그다음 `apigateway/Dockerfile` 기준으로 이미지를 빌드해서 
GHCR로 push 한다고 적혀 있어. 

주석에도 **별도 shell 스크립트는 호출하지 않는다**고 명시돼 있어. ([GitHub][1])

---

반면 `.github/workflows/image-registry-cicd.yml` 은 

- 더 넓은 범위의 공용 워크플로로, 
- `main` 또는 `master` 에서 `config`, `discovery`, `apigateway` 관련 경로가 바뀌면 실행되도록 되어 있고, 
- matrix로 세 모듈 이미지를 빌드·푸시하게 설계되어 있어. 

여기 주석도 “**서버 배포까지는 하지 않고** … **GHCR까지 올리는 역할만** 담당한다”고 말하고 있어. 
즉 이 파일은 엄밀히 말하면 **CI + image publishing** 이지, 
Kubernetes 배포까지 자동화하는 CD는 아니야. ([GitHub][3])

---

중요한 점 하나.

이 저장소에서 **GitHub Actions와 Kubernetes가 직접 연결돼 있지는 않다**는 흔적이 보여. 

`image-registry-cicd.yml` 에는 

- 예전처럼 `./scripts/build_jar.sh` 와 `./scripts/build_docker.sh` 를 재사용하는 블록이 주석 처리돼 있고, 
- 현재 활성화된 부분은 `docker/build-push-action@v5` 로 바로 빌드·푸시하는 흐름이야. 

그래서 이 브랜치의 현재 상태를 보면, 

GitHub Actions는 “이미지 생성/레지스트리 업로드”까지 담당하고, 
Kubernetes 반영은 별도 단계로 남겨둔 구조에 가깝다. ([GitHub][4])

---

### 그다음 `apigateway/Dockerfile` 은 **이미지 내부를 어떻게 만들지** 정의하는 파일이야.

이 파일은 멀티스테이지 빌드로 되어 있어서, 

- 먼저 `gradle:7.4.0-jdk` 단계에서 소스와 Gradle 파일을 복사한 뒤 `./gradlew bootJar` 로 jar를 만들고, 
- 이후 `eclipse-temurin:8-jre` 런타임 이미지에 그 jar를 복사해서 `java -jar /usr/app/app.jar` 로 실행하게 되어 있어. 

> 즉 Dockerfile은 “컨테이너 이미지를 어떤 방식으로 빌드하고 실행할지”를 정의하는 중심 파일이고, 
> 워크플로가 그 Dockerfile을 불러 쓰는 관계야. ([GitHub][5])

---

그래서 네가 묻는 연결 관계를 apigateway 전용 워크플로 기준으로 가장 단순하게 쓰면 이거야.

```
`GitHub push` 
→ `apigateway-registry.yml 실행` 
→ `actions/checkout` → `GHCR 로그인` 
→ `apigateway/Dockerfile 로 이미지 빌드` 
→ `GHCR push`. 
```

이 흐름에는 **k8s yaml이 직접 등장하지 않는다**. ([GitHub][1])

---

### 반대로 `apigateway/k8s/apigateway.yaml` 은 **배포 명세서**야.

- 여기엔 `Service` 와 `Deployment` 가 같이 들어 있고, 
- 서비스 타입은 `LoadBalancer`, 
- 포트는 8000, 
- Deployment의 컨테이너 이름은 `apigateway`, 
- 기본 이미지는 `apigateway:dev`, 
- imagePullPolicy` 는 `IfNotPresent` 로 되어 있어. 
- 환경변수로 
    `SPRING_APPLICATION_NAME=apigateway`, 
    `SPRING_CLOUD_CONFIG_URI=http://config-service:8888`, 
    `EUREKA_INSTANCE_HOSTNAME=discovery`,   
    `SERVER_PORT=8000` 
도 들어 있다. 

> 즉 이 파일은 
> “쿠버네티스에서 apigateway를 어떤 이름, 어떤 이미지, 어떤 포트, 어떤 환경변수로 띄울지”
> 를 정의하는 파일이지, 

이미지를 만드는 파일은 아니야. ([GitHub][6])

---

### 이 k8s 파일을 실제로 적용하는 건 `apigateway/scripts/register_k8s.sh` 와 `run_k8s.sh` 야.

`register_k8s.sh` 는 

- namespace를 준비하고 
- `kubectl apply -f .../k8s/apigateway.yaml` 로 리소스를 등록한 다음, 
- 곧바로 `deployment/apigateway --replicas=0` 으로 맞춰 “등록만 하고 아직 실행은 안 하는” 단계로 끝낸다. 

그다음 `run_k8s.sh` 가 

- `IMAGE_REGISTRY/IMAGE_NAME:IMAGE_TAG` 조합으로 실제 이미지명을 만든 뒤 
- `kubectl set image deployment/apigateway ...` 로 이미지 교체, 
- `replicas=1` 로 실행, 
- `rollout status` 로 상태 확인을 한다.([GitHub][7])

---

즉 **로컬 배포 스크립트** 관점의 연결은 이렇게 보는 게 맞아.

`build_jar.sh` 가 `./gradlew clean bootJar` 로 jar를 만들고, 
`build_docker.sh` 가 그 jar 존재를 확인한 뒤 `docker build -t ...` 로 이미지를 만들며, 옵션에 따라 `minikube image load` 또는 `docker push` 를 수행하고, 
`register_k8s.sh` 가 k8s yaml을 apply 하고, 
`run_k8s.sh` 가 Deployment 이미지와 replicas를 조정하고, 
마지막으로 `check_k8s.sh` 가 deployment/pod/service 상태와 `port-forward` 예시를 보여 준다. 
`all_in_one.sh` 는 이 순서를 그대로 묶어 놓은 실행기야. ([GitHub][8])

---

### 그래서 머릿속에서는 **두 개의 자동화 라인**으로 분리해서 이해하면 훨씬 편해.

**1. GitHub Actions 라인**

> 코드 변경 감지 → workflow 실행 → Dockerfile로 이미지 빌드 → GHCR push.

여기서는 핵심 파일이 `.github/workflows/*.yml` + `apigateway/Dockerfile` 이야. ([GitHub][1])

**2. 로컬 Kubernetes 배포 라인**

> jar 생성 → docker image 생성 → `k8s/apigateway.yaml` apply → deployment 이미지 교체/실행 → 상태 확인.

여기서는 핵심 파일이 `apigateway/scripts/*.sh` + `apigateway/k8s/apigateway.yaml` 이야. ([GitHub][8])

---

그래서 네 질문에 직접 답하면,

“**github workflow yml, k8s yml, dockerfile 이 순서로 cicd에 기여한다고 보면 될까?**” 에 대한 답은 

**아니야, 이 브랜치 기준으로는 그렇게 단순화하면 틀린다**야.

더 맞는 표현은:

* **CI 쪽:** `workflow yml → Dockerfile → GHCR`
* **배포 쪽:** `scripts(.sh) → k8s yml → kubectl set image/scale`
* 또는 GitHub Actions가 k8s까지 붙어 있지 않으니, 
현재는 **“이미지 자동화”와 “쿠버네티스 실행”이 분리된 상태**라고 보는 게 가장 정확해. ([GitHub][1])

---

한 줄로 정리하면 이거야.

`workflow yml` 은 **언제/어떻게 자동 실행할지**,
`Dockerfile` 은 **무슨 이미지를 만들지**,
`k8s yml` 은 **그 이미지를 클러스터에서 어떻게 띄울지**를 정한다. ([GitHub][9])
