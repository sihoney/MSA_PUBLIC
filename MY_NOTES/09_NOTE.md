9. 쿠버네티스에서 이 게이트웨이가 어떻게 뜨는가

파일 위치:

apigateway/k8s/apigateway.yaml

이 YAML에서는 컨테이너 이미지가 apigateway:1.0.0이고, 환경변수로 SPRING_APPLICATION_NAME=apigateway, EUREKA_INSTANCE_HOSTNAME=discovery, SPRING_CLOUD_CONFIG_URI=http://config-service:8888, SERVER_PORT=8000 등을 주입합니다. readiness/liveness probe는 둘 다 /actuator/health를 사용합니다.

이게 의미하는 건 단순합니다.

로컬에서는 application.yml의 http://localhost:8888를 볼 수 있지만,

Kubernetes에선 config-service:8888을 보게 되고,

Eureka도 discovery라는 서비스 이름으로 찾도록 바뀝니다.

즉 이 게이트웨이는 로컬 실행용 설정과 K8s 실행용 환경 주입을 둘 다 고려한 구조입니다. 그리고 health probe가 붙어 있으니, K8s는 /actuator/health가 살아 있는지 보면서 이 Pod를 트래픽 대상에 넣을지 판단합니다.