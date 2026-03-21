# docker, kubectl, minikube

많이 헷갈리는 부분인데, 이 네 개는 **역할이 완전히 다른 도구**야.
핵심을 먼저 말하면:

* **Docker** → 컨테이너 만드는 도구
* **Kubernetes** → 컨테이너 여러 개를 관리하는 시스템
* **kubectl** → Kubernetes를 조작하는 CLI
* **Minikube** → 내 PC에서 Kubernetes를 실행하는 도구

즉 구조는 이렇게 된다.

```
내 PC
 └─ Minikube
      └─ Kubernetes cluster
           ├─ Pod (container)
           │     └─ Docker container
           └─ Service / Deployment
           
kubectl → Kubernetes에게 명령
docker → container 이미지 생성
```

이제 하나씩 정확히 설명할게.

---

# 1️⃣ Docker (도커)

Docker는 **컨테이너를 만들고 실행하는 도구**야.

예를 들어 Spring Boot 앱을 실행한다고 하자.

### 일반 실행

```bash
java -jar app.jar
```

문제:

* Java 버전 달라서 실행 안 됨
* OS 환경 다름
* 라이브러리 충돌

그래서 **컨테이너로 묶는다.**

### Dockerfile

```dockerfile
FROM openjdk:17
COPY app.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

이미지 생성

```bash
docker build -t apigateway .
```

컨테이너 실행

```bash
docker run -p 8000:8000 apigateway
```

정리

Docker 역할

```
app → image → container
```

즉

**컨테이너 생성 엔진**

---

# 2️⃣ Kubernetes

문제 상황

```
container 1개 → docker run
container 100개 → ????
```

운영 환경에서는

* 서버 여러 개
* 컨테이너 수십 개
* 자동 복구
* 자동 스케일링

이걸 관리하는 시스템이

**Kubernetes**

예

```
User
  ↓
Service
  ↓
Pod
  ↓
Container (Docker)
```

Kubernetes 기능

* 컨테이너 자동 실행
* 장애 복구
* 로드밸런싱
* 스케일링
* 배포 관리

예

```bash
kubectl apply -f deployment.yaml
```

그러면 Kubernetes가

```
컨테이너 생성
컨테이너 관리
죽으면 재시작
```

을 자동으로 한다.

---

# 3️⃣ kubectl

`kubectl`은 **Kubernetes를 조작하는 CLI**야.

즉

```
kubectl → Kubernetes API
```

예

### Pod 목록 보기

```bash
kubectl get pods
```

### 배포

```bash
kubectl apply -f deployment.yaml
```

### 로그

```bash
kubectl logs pod-name
```

### 스케일

```bash
kubectl scale deployment apigateway --replicas=3
```

즉

```
kubectl = Kubernetes 리모컨
```

---

# 4️⃣ Minikube

Kubernetes는 보통

```
AWS
GCP
Azure
```

같은 클라우드에서 돌린다.

하지만 개발할 때는

```
내 노트북
```

에서 Kubernetes를 실행해야 한다.

그래서 등장한 게

**Minikube**

Minikube는

```
내 PC 안에
Kubernetes cluster 하나 생성
```

해준다.

실행

```bash
minikube start
```

그러면 내부에서

```
VM
  └ Kubernetes cluster
```

가 만들어진다.

그래서 kubectl이 Minikube의 Kubernetes에 연결된다.

---

# 5️⃣ 그래서 전체 구조는 이렇게 된다

```
Laptop
│
├ Docker
│   └ container image 생성
│
├ Minikube
│   └ Kubernetes cluster
│
└ kubectl
     └ Kubernetes 조작
```

실제 실행 흐름

```
1 Docker image build
   docker build

2 Kubernetes 등록
   kubectl apply

3 실행
   kubectl scale

4 확인
   kubectl get pods
```

---

# 6️⃣ 네가 본 명령어 기준으로 보면

### docker

이미지 생성

```
docker build
docker push
docker run
```

---

### minikube

로컬 쿠버네티스 관리

```
minikube start
minikube stop
minikube image load
minikube tunnel
```

---

### kubectl

쿠버네티스 조작

```
kubectl apply
kubectl get pods
kubectl logs
kubectl scale
kubectl rollout
```

---

# 7️⃣ 이걸 한 문장으로 정리하면

| 도구         | 역할                 |
| ---------- | ------------------ |
| Docker     | 컨테이너 이미지 생성        |
| Kubernetes | 컨테이너 오케스트레이션 시스템   |
| kubectl    | Kubernetes CLI     |
| Minikube   | 로컬에서 Kubernetes 실행 |

---

# 8️⃣ 지금 네 프로젝트 기준 실제 흐름

CI/CD 수업에서 하는 것

```
1 build jar
2 docker build
3 kubectl apply
4 kubectl scale
5 kubectl get pods
```

구조

```
Spring Boot
   ↓
Docker image
   ↓
Kubernetes Pod
   ↓
Service
   ↓
API Gateway
```

---

💡 내가 솔직히 말할게.

지금 헷갈리는 이유는 **도구 계층이 3개라서 그래.**

```
컨테이너 레벨
Docker

오케스트레이션 레벨
Kubernetes

로컬 실행 레벨
Minikube
```

여기서 kubectl은 그냥 **리모컨**일 뿐이다.

---

원하면 내가 다음 단계로 **이 프로젝트 기준**

```
apigateway
docker
kubernetes
service
pod
gateway routing
```

까지 **전체 아키텍처를 그림으로 설명해 줄게.**

이거 이해되면 **MSA + Kubernetes 구조가 한 번에 정리된다.**
