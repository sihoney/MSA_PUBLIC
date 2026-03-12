# “개념 → 기술 → 명령어” 기준으로 정리

---

## 1️⃣ 전체 흐름 (지금 네가 한 것)

```
Spring Boot 코드
        │
gradlew bootJar
        │
JAR 생성
        │
docker build
        │
Docker Image 생성
        │
kubectl apply
        │
Kubernetes Deployment 생성
        │
Pod 실행
```

즉 애플리케이션 → 컨테이너 → 클러스터 실행 단계

---

## 2️⃣ Spring Boot → JAR

### 개념

Spring Boot 앱을 독립 실행 프로그램으로 만드는 단계.

### 결과

build/libs/apigateway-xxx.jar

이 jar는

```
java -jar app.jar
```

로 실행할 수 있는 프로그램이다.

---

## 3️⃣ Docker

### 개념

애플리케이션을 컨테이너 이미지로 만든다.

왜 필요할까? 

어디서든 같은 환경으로 실행하기 위해서다.

---

### Dockerfile

이미지를 어떻게 만들지 정의하는 파일

예시:

```
FROM        openjdk:17
COPY        app.jar app.jar
ENTRYPOINT  ["java","-jar","app.jar"]
```

---

### docker build

이미지 생성

```
docker build -t local/apigateway:dev .
```

---

## 4️⃣ Kubernetes

### 개념

Docker 컨테이너를 대규모로 관리하는 시스템

역할

```
컨테이너 실행
컨테이너 자동 재시작
로드밸런싱
서비스 연결
```

---

## 5️⃣ Kubernetes 핵심 리소스

실습에서 사용한 것들이다.

### Namespace

서비스들을 논리적으로 분리

예:

```
msa
default
kube-system
```

확인

```
kubectl get namespaces
```

---

### Deployment

컨테이너 실행을 관리하는 객체

역할

```
Pod 생성
Pod 개수 유지
자동 재시작
롤링 업데이트
```

확인

```
kubectl get deployment
```

---

### Pod

Kubernetes에서 실제로 실행되는 컨테이너

확인:

```
kubectl get pods
```

---

### Service

Pod에 접근할 수 있는 네트워크 엔드포인트

예:

```
ClusterIP
NodePort
LoadBalancer
```

확인:

```
kubectl get svc
```

---

## 6️⃣ kubectl 명령어

쿠버네티스 CLI

### 리소스 생성

```
kubectl apply -f apigateway.yaml
```

의미:

yaml 설정을 기반으로 쿠버네티스 리소스를 생성

---

### 리소스 조회

```
kubectl get pods
kubectl get svc
kubectl get deployment
```

---

### 상태 상세 확인

```
kubectl describe pod
```

---

### 로그 확인

```
kubectl logs <pod-name>
```

---

## 8️⃣ 실제 실행 구조

```
minikube (kubernetes cluster)
        │
        ▼
    apigateway pod
        │
        ▼
  docker container
        │
        ▼
Spring Boot app
```

---

## 명령어 실행 결과

> kubectl -n msa get pods

```
PS C:\my_project\MSA_PUBLIC\config\scripts> kubectl -n msa get pods
NAME                              READY   STATUS    RESTARTS   AGE
apigateway-775b88d57c-xfwdr       1/1     Running   0          70m
config-service-6d77b88fbb-r8sjl   1/1     Running   0          79m
```

---

> kubectl -n msa get svc

```
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
apigateway       LoadBalancer   10.111.65.252   127.0.0.1     8000:31088/TCP   3h15m
config-service   ClusterIP      10.111.15.199   <none>        8888/TCP         161m       443/TCP   20h
```

---

>  kubectl -n msa get deployment

```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
apigateway       1/1     1            1           146m
config-service   1/1     1            1           161m
```

---

>  kubectl -n msa describe pod

```
Name:             apigateway-775b88d57c-xfwdr
Namespace:        msa
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Thu, 12 Mar 2026 11:38:17 +0900
Labels:           app.kubernetes.io/name=apigateway
                  pod-template-hash=775b88d57c
Annotations:      <none>
Status:           Running
IP:               10.244.0.10
IPs:
  IP:           10.244.0.10
Controlled By:  ReplicaSet/apigateway-775b88d57c
Containers:
  apigateway:
    Container ID:   docker://d4ff6bcf09b8e3c5bcad13082cf5a9a92e27ac51eb2e49dd65bfcef518c0bada
    Image:          local/apigateway:dev
    Image ID:       docker://sha256:5a52d3d022bd06476ec9cb6f86f7734760c4904d7e107b3870bc3188842a96e2
    Port:           8000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 12 Mar 2026 11:38:18 +0900
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:8000/actuator/health delay=45s timeout=1s period=20s #success=1 #failure=3
    Readiness:      http-get http://:8000/actuator/health delay=15s timeout=1s period=10s #success=1 #failure=3
    Environment:
      SPRING_PROFILES_ACTIVE:    default
      SPRING_APPLICATION_NAME:   apigateway
      EUREKA_INSTANCE_HOSTNAME:  discovery
      SPRING_CLOUD_CONFIG_URI:   http://config-service:8888
      SERVER_PORT:               8000
    Mounts:
      /usr/app/msa-attach-volume/messages from messages (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-kqngf (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  messages:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  kube-api-access-kqngf:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>


Name:             config-service-6d77b88fbb-r8sjl
Namespace:        msa
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Thu, 12 Mar 2026 11:29:19 +0900
Labels:           app=config-service
                  pod-template-hash=6d77b88fbb
Annotations:      <none>
Status:           Running
IP:               10.244.0.9
IPs:
  IP:           10.244.0.9
Controlled By:  ReplicaSet/config-service-6d77b88fbb
Containers:
  config-service:
    Container ID:   docker://4612cf1203f1db71d986855ff16637a0cb9e5f62da7d9403bb73db94a958d53f
    Image:          local/config:dev
    Image ID:       docker://sha256:a7ed0f6cb13fda8670839b2f0fc2b7db40479f8c76b3bf4526ec0d4ea9739548
    Port:           8888/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 12 Mar 2026 11:29:19 +0900
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:      200m
      memory:   256Mi
    Liveness:   http-get http://:8888/actuator/health delay=40s timeout=1s period=30s #success=1 #failure=3
    Readiness:  http-get http://:8888/actuator/health delay=20s timeout=1s period=10s #success=1 #failure=3
    Environment:
      SPRING_PROFILES_ACTIVE:                              native
      SPRING_APPLICATION_NAME:                             config-service
      SERVER_PORT:                                         8888
      SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS:  file:/config
    Mounts:
      /config from config-repo (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-c474b (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  config-repo:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      config-repo
    Optional:  false
  kube-api-access-c474b:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>
```

---

> kubectl -n msa apigateway-775b88d57c-xfwdr