8. 실제 요청 하나를 코드 기준으로 따라가 보기

예를 들어 이런 요청이 왔다고 해볼게요.

GET /backend5-service/api/v1/authorizations/check
Authorization: Bearer <jwt>

이 요청은 대략 이렇게 흘러갑니다.

application.yml의 route가 /backend5-service/**를 잡음.

GlobalFilter가 시작 로그를 남김.

WebFluxSecurityConfig가 이 요청이 permitAll 대상인지 확인. permitAll이 아니면 ReactiveAuthorization으로 넘김.

ReactiveAuthorization이 Authorization 헤더에서 JWT를 꺼내 공개키로 검증.

그 뒤 인가 확인 API를 다시 호출해 Boolean 결과를 받음.

허용되면 게이트웨이가 lb://BACKEND5-SERVICE로 실제 요청을 전달하고, 전달 전 RewritePath로 /backend5-service prefix를 제거.

응답이 돌아오면 GlobalFilter가 종료 로그를 남김.

여기서 중요한 포인트는 라우팅과 보안이 분리돼 있지만, 실제 실행에서는 한 요청 안에서 같이 일어난다는 점입니다. 이 구조를 머릿속에 넣으면 apigateway가 훨씬 읽기 쉬워집니다.