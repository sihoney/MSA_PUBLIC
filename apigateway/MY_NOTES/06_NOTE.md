7. 공통 로그 필터: GlobalFilter.java

파일 위치:

apigateway/src/main/java/org/egovframe/cloud/apigateway/filter/GlobalFilter.java

이 클래스는 AbstractGatewayFilterFactory를 상속하고, Config 내부 클래스에 preLogger, postLogger 설정을 받습니다. 실제 동작은 요청 시작 전에 request ID, method, path를 로그로 남기고, 체인이 끝난 뒤 응답 status까지 포함해서 종료 로그를 남깁니다.

그리고 이 필터가 실제로 적용되는 이유는 application.yml의 default-filters에서 GlobalFilter가 등록돼 있기 때문입니다. 즉 각 라우트마다 따로 붙이는 게 아니라 게이트웨이를 통과하는 요청 전체에 공통 적용됩니다. 희원님이 봤던 로그

[GlobalFilter Start] request ID: ... method: GET path: ...

도 바로 여기서 나온 겁니다.