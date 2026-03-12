# 2️⃣ 전체 구조 (수업 환경)

지금 사용하는 구조를 실제 흐름으로 그려보면 이거다.

```
내 PC
│
├ Docker
│   └ 컨테이너 이미지 생성
│
├ Minikube
│   └ Kubernetes Cluster
│       │
│       ├ API Server
│       ├ Scheduler
│       ├ Controller Manager
│       │
│       └ Node
│           └ Pod
│               └ Container (Docker)
│
└ kubectl
    └ Kubernetes API 호출
```

즉

```
docker → 컨테이너 이미지
kubernetes → 컨테이너 관리
kubectl → kubernetes 조작
minikube → 로컬 kubernetes 실행
```

---

# 3️⃣ 실제 실행 흐름 (프로젝트 기준)

apigateway 예시로 보면

### 1️⃣ jar 생성

```
./gradlew bootJar
```

결과

```
apigateway.jar
```

---

### 2️⃣ docker 이미지 생성

```
docker build -t apigateway .
```

이미지 생성

```
apigateway:latest
```

---

### 3️⃣ minikube cluster 실행

```
minikube start
```

이 순간

```
Kubernetes cluster
```

가 노트북 안에서 실행된다.

---

### 4️⃣ kubectl로 배포

```
kubectl apply -f apigateway.yaml
```

이 명령의 실제 흐름

```
kubectl
   ↓
Kubernetes API Server
   ↓
Deployment 생성
   ↓
Pod 생성
   ↓
Container 실행
```

---

# 4️⃣ apigateway 실제 동작 구조

보고 있는 MSA 프로젝트 구조를 간단히 정리하면

```
User
 │
 ▼
API Gateway
 │
 ▼
Backend Service
 │
 ▼
Database
```

이걸 Kubernetes 안에서는 이렇게 실행한다.

```
Kubernetes Cluster
│
├ Pod
│   └ apigateway container
│
├ Pod
│   └ backend1 container
│
├ Pod
│   └ backend2 container
│
└ Service
    └ Load Balancing
```

---

# 5️⃣ Deployment / Pod / Service 관계

이건 Kubernetes에서 가장 중요하다.

```
Deployment
   ↓
Pod
   ↓
Container
```

예

```
Deployment: apigateway
 replicas: 2
```

그러면

```
Pod 1
  └ apigateway container

Pod 2
  └ apigateway container
```

---

Service는 접근용이다.

```
User
 ↓
Service
 ↓
Pod
```

---

# 6️⃣ apigateway.yaml 예시 구조

프로젝트에서 이런 구조가 있을 거야.

### Deployment

```
Deployment
  name: apigateway
  replicas: 1
```

Pod 생성

```
Pod
 └ Container
     image: apigateway
     port: 8000
```

---

### Service

```
Service
  type: LoadBalancer
  port: 8000
```

역할

```
외부 요청 → apigateway Pod
```

---

# 7️⃣ 그래서 전체 시스템은 이렇게 동작한다

지금 하는 MSA 시스템.

```
User
 │
 ▼
Service (LoadBalancer)
 │
 ▼
API Gateway Pod
 │
 ▼
Backend Service Pod
 │
 ▼
Database
```

---

# 8️⃣ CI/CD까지 연결하면

수업에서 하는 흐름.

```
코드 수정
   ↓
Git push
   ↓
GitHub Actions
   ↓
Docker build
   ↓
Image registry
   ↓
Kubernetes deploy
```

---

# 9️⃣ 그래서 scripts 폴더가 하는 일

질문한 scripts 흐름은 이것이다.

```
build_jar.sh
    ↓
Spring Boot jar 생성

build_docker.sh
    ↓
Docker image 생성

register_k8s.sh
    ↓
Kubernetes 리소스 등록

run_k8s.sh
    ↓
Pod 실행

check_k8s.sh
    ↓
상태 확인
```

즉

**MSA 배포 자동화 스크립트**다.

---

# 🔟 지금 단계에서 꼭 이해해야 할 5개

이거만 확실히 잡으면 된다.

1️⃣ **Docker = 컨테이너 생성**

```
docker build
docker run
```

2️⃣ **Kubernetes = 컨테이너 관리**

```
Deployment
Pod
Service
```

3️⃣ **kubectl = Kubernetes 리모컨**

```
kubectl apply
kubectl get pods
```

4️⃣ **Minikube = 로컬 Kubernetes**

```
minikube start
```

5️⃣ **MSA = 여러 서비스**

```
gateway
backend1
backend2
```

