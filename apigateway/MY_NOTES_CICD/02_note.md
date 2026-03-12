# MSA + Docker + Kubernetes + CI/CD 전체 구조

---

## 1️⃣ 전체 구조 (한눈에 보기)

```
                GitHub Repository
                        │
                        │ (git push)
                        ▼
             GitHub Actions (CI)
                        │
                        │ gradle build
                        ▼
                   JAR 생성
                        │
                        │ docker build
                        ▼
                 Docker Image 생성
                        │
                        │ push (registry)
                        ▼
               Container Registry
                        │
                        │ pull
                        ▼
                 Kubernetes Cluster
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   config-service   discovery       apigateway
      (pod)           (pod)           (pod)
```

---

## MSA 서비스 구조

이 레포에서 서비스는 이렇게 나뉜다.

```
config
discovery
apigateway
backend-service
```

각 서비스는 Spring Boot 프로젝트 하나다.

즉

```
Spring Boot app
      ↓
     jar
      ↓
docker image
      ↓
kubernetes pod
```

---

## 3️⃣ Kubernetes에서 실제 실행 구조

Kubernetes에서는 이렇게 돌아간다.

```
                    Client
                       │
                       ▼
                 API Gateway
                       │
       ┌───────────────┼───────────────┐
       ▼                               ▼
  discovery server                backend service
 (service registry)                 (business logic)
       │
       ▼
   config server
(configuration)
```

역할은 다음과 같다.

| 서비스        | 역할                 |
| ---------- | ------------------ |
| config     | 설정 관리              |
| discovery  | 서비스 위치 관리 (Eureka) |
| apigateway | 모든 요청의 입구          |
| backend    | 실제 비즈니스 로직         |

---

## Docker가 하는 일

Docker는 Spring Boot 앱을 컨테이너로 만든다.

```
Spring Boot code
        │
        ▼
  gradle bootJar
        │
        ▼
     app.jar
        │
        ▼
    Dockerfile
        │
        ▼
   Docker Image
```

---

## Kubernetes가 하는 일

Docker 이미지를 실제로 실행하는 시스템이다.

```
Docker image
     │
     ▼
Kubernetes Deployment
     │
     ▼
Pod 생성
```

---

## CI/CD 흐름

```
개발자가 코드 수정
        │
        ▼
git push
        │
        ▼
GitHub Actions 실행
        │
        ▼
gradle build
        │
        ▼
jar 생성
        │
        ▼
docker image 생성
        │
        ▼
registry push
        │
        ▼
kubernetes deploy
```