> 파일 위치: apigateway/k8s/apigateway.yaml

```
apiVersion: v1
kind: Service
...
---
apiVersion: apps/v1
kind: Deployment
```

- kind: Service → 외부/내부에서 접근할 네트워크 엔드포인트
- kind: Deployment → Pod를 관리하는 배포 단위

---

```
---
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 1
```

- replicas: 1 → 현재 Pod 1개

---

```
---
apiVersion: apps/v1
kind: Deployment
metadata: ...
spec:
  replicas: 1
  selector:
  template:
    spec:
      containers:
        - name: apigateway
          image: apigateway:1.0.0
```

- image: apigateway:1.0.0 → Docker 이미지

---

```
---
apiVersion: apps/v1
kind: Deployment
metadata: ...
spec:
  replicas: 1
  selector: ...
  template:
    metadata: ...
    spec:
      containers:
        - name: apigateway
          image: apigateway:1.0.0
          imagePullPolicy: IfNotPresent
          env: ...
          ports: ...
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 10
```

- readinessProbe/livenessProbe → 헬스체크

---

```
lb://MEMBER-SERVICE
```

- 이 부분이 MSA에서 정말 중요
- http://localhost:8081 같은 고정 URL이 아닙니다.
- **로드밸런서 + 서비스 이름 기반 호출**
- 게이트웨이는 MEMBER-SERVICE라는 이름을 discovery에서 찾고, 등록된 인스턴스로 요청을 넘깁니다.