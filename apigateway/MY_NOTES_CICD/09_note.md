# 포트포워딩(port forwarding) 

이름 그대로 **“한 포트로 들어온 요청을 다른 곳의 포트로 전달하는 것”**이야.

CI/CD나 Kubernetes 수업에서 나오는 이유는 

**내 로컬 PC에서 클러스터 안의 서비스에 접근하기 위해서**다.

먼저 개념부터 잡자.

---

# 1️⃣ 포트포워딩 기본 개념

예를 들어 어떤 서버가 이렇게 실행돼 있다고 하자.

```text
Spring Boot 서버
포트 : 8000
```

그런데 이 서버가 **내 컴퓨터가 아니라 Kubernetes 클러스터 내부**에 있다.

```text
내 PC
   ↓
Kubernetes cluster
      ↓
      Pod
      └ Spring Boot (8000)
```

이 상태에서는 보통 **localhost:8000으로 접근이 안 된다.**

그래서 **포트포워딩을 만든다.**

```text
내 PC:8000  →  Kubernetes Pod:8000
```

그러면

```text
http://localhost:8000
```

요청이

```text
Pod:8000
```

으로 전달된다.

---

# 2️⃣ Kubernetes에서 사용하는 명령어

가장 많이 쓰는 명령어

```bash
kubectl port-forward svc/apigateway 8000:8000
```

의미를 해석해보면

```
kubectl port-forward
  서비스/apigateway
  로컬포트:클러스터포트
```

즉

```text
내 PC 8000 → apigateway 서비스 8000
```

---

# 3️⃣ 실제 네 수업 프로젝트 상황

지금 apigateway 구조는 대략 이렇다.

```text
브라우저
   ↓
localhost:8000
   ↓ (port-forward)
Kubernetes Service
   ↓
Pod
   ↓
Spring Boot API Gateway
```

그래서 스크립트에서 이런 안내가 나왔던 거야.

```bash
kubectl -n msa port-forward svc/apigateway 8000:8000
```

그리고 나서

```
http://localhost:8000/swagger-ui/index.html
```

로 접속하는 거지.

---

# 4️⃣ 왜 포트포워딩을 쓰냐 (CI/CD / Kubernetes에서)

Kubernetes 서비스는 보통 외부에 바로 노출되지 않는다.

서비스 타입이

```text
ClusterIP
```

이면 **클러스터 내부에서만 접근 가능**하다.

그래서 개발할 때는

```
외부 접근 → port-forward
```

를 사용한다.

---

# 5️⃣ Service 타입에 따른 차이

| 타입           | 접근        |
| ------------ | --------- |
| ClusterIP    | 클러스터 내부만  |
| NodePort     | 노드 포트로 접근 |
| LoadBalancer | 외부 로드밸런서  |
| port-forward | 임시 터널     |

포트포워딩은 **개발/디버깅용 임시 접근 방법**이다.

---

# 6️⃣ Pod에도 포트포워딩 가능

서비스 말고 **Pod에 직접 연결**할 수도 있다.

```bash
kubectl port-forward pod/apigateway-xxxxx 8000:8000
```

구조

```text
localhost:8000
   ↓
pod/apigateway
```

---

# 7️⃣ CI/CD에서 포트포워딩이 나오는 이유

CI/CD에서 테스트할 때

```text
pipeline
   ↓
kubectl deploy
   ↓
서비스 정상 확인
```

을 해야 한다.

그래서

```text
테스트 서버 접근
```

을 위해 포트포워딩을 쓰기도 한다.

예

```bash
kubectl port-forward svc/api 8080:8080
curl localhost:8080/health
```

---

# 8️⃣ 포트포워딩의 특징

✔ SSH 터널 같은 개념
✔ 임시 연결
✔ kubectl 실행 중일 때만 유지
✔ 종료하면 연결도 종료

즉

```text
kubectl port-forward 실행중
      ↓
localhost 접근 가능

종료
      ↓
접근 불가
```

---

# 9️⃣ 한 문장 정리

포트포워딩은

> **로컬 컴퓨터의 포트를 Kubernetes 내부 서비스나 Pod의 포트로 연결하는 임시 터널이다.**

---

💡 지금 배우는 MSA + Kubernetes에서
**이 포트포워딩은 거의 필수 개념**이야.

왜냐하면 개발할 때 보통 이런 흐름이기 때문이야.

```text
minikube cluster
      ↓
service
      ↓
port-forward
      ↓
localhost 테스트
```

---

원하면 내가 **MSA + Kubernetes + API Gateway 구조를
(보고 있는 프로젝트 기준으로)**

```
gateway
discovery
config
backend-service
```

까지 **전체 요청 흐름을 그림으로 설명해 줄게.**

이걸 이해하면 **MSA 구조가 갑자기 확 정리된다.**
