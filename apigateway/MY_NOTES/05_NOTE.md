# 진짜 핵심: ReactiveAuthorization.java

파일 위치:

```
apigateway/src/main/java/org/egovframe/cloud/apigateway/config/ReactiveAuthorization.java
```

---

```
@Component
public class ReactiveAuthorization 
    implements ReactiveAuthorizationManager<AuthorizationContext> {

    @Override
    public Mono<AuthorizationDecision> check(
            Mono<Authentication> authentication, // 😜 JWT 검증 후 생성된 사용자 정보
            AuthorizationContext context // 😜 현재 요청 정보
    )
```

- 이 클래스가 이 게이트웨이의 핵심 중 핵심입니다.
- 이름 그대로 **ReactiveAuthorizationManager 구현체**이고,
- 요청마다 **토큰을 검사**한 뒤, **별도의 인가 체크 API**를 호출해서 최종 허용 여부를 결정합니다.

---

코드 흐름을 풀어보면 이렇습니다.

## 5-1. 요청을 받으면 먼저 헤더의 Authorization 토큰을 읽음

```
ServerHttpRequest request = context.getExchange().getRequest();

List<String> authorizations =
    request.getHeaders().containsKey(HttpHeaders.AUTHORIZATION) ?
        request.getHeaders().get(HttpHeaders.AUTHORIZATION) : null;
```

코드는 HttpHeaders.AUTHORIZATION에서 토큰을 꺼내고, 

```
authorizationHeader = authorizations.get(0);
String jwt = authorizationHeader.replace("Bearer ", ""); // 실제 JWT만 추출
```

Bearer 를 제거한 뒤 JWT를 파싱합니다. 

```
String subject = Jwts.parser()
                .verifyWith(loadPublicKey(TOKEN_PUBLIC))
                .build().parseSignedClaims(jwt).getPayload().getSubject();
```

token.public 값을 이용해 RSA 공개키를 로드해서 서명 검증도 합니다. 

```
if (authorizations != null && authorizations.size() > 0
    && StringUtils.hasLength(authorizations.get(0))
    && !"undefined".equals(authorizations.get(0))
) {
    try {
        ...
        
        if (subject == null || subject.isEmpty()) {
            log.error("토큰 인증 오류");
            throw new AuthorizationServiceException("토큰 인증 오류");
        }
    } catch (IllegalArgumentException e) {
        log.error("토큰 헤더 오류 : {}", e.getMessage());
        throw new AuthorizationServiceException("토큰 인증 오류");
    } catch (ExpiredJwtException e) {
        log.error("토큰 유효기간이 만료되었습니다. : {}", e.getMessage());
        throw new AuthorizationServiceException("토큰 유효기간 만료");
    } catch (Exception e) {
        log.error("토큰 인증 오류 Exception : {}", e.getMessage());
        throw new AuthorizationServiceException("토큰 인증 오류");
    }
}else{
    throw new AuthorizationServiceException("토큰 오류");
}
```

subject가 비어 있거나 토큰이 잘못되면 바로 예외를 던집니다.

---

## 5-2. 토큰만 유효하다고 끝나는 게 아님

```
public static final String AUTHORIZATION_URI = 
    "/backend5-service" + "/api/v1/authorizations/check";
public static final String REFRESH_TOKEN_URI = 
    "/user-service" + "/api/v1/users/token/refresh";

...

//인가 체크하는 api 주소.
String baseUrl =
    APIGATEWAY_HOST + AUTHORIZATION_URI 
    + "?httpMethod=" + httpMethod 
    + "&requestPath=" + requestPath;
```

이 클래스는 토큰 검증 후, 별도 URI로 인가 확인을 또 보냅니다. 

현재 코드상 인가 확인 URI 상수는

/backend5-service/api/authorizations/check

입니다. 그리고 실제 호출 URL은

APIGATEWAY_HOST + AUTHORIZATION_URI + "?httpMethod=...&requestPath=..."

형태로 만듭니다. 

즉 게이트웨이가 다시 backend5-service 쪽 인가 API를 호출해, 

이 요청이 허용되는지 물어보는 구조입니다.

---

## 5-3. WebClient로 인가 서버 호출

```
boolean granted = false;
try {
    String token = authorizationHeader; // Variable used in lambda expression should be final or effectively final
    
    // 4. 😜 인가 체크 API 호출 (gateway는 권한을 직접 판단 X, 서비스에 질문)
    Mono<Boolean> body = WebClient.create(baseUrl)
        .get()
        .headers(httpHeaders -> {
            httpHeaders.add(HttpHeaders.AUTHORIZATION, token);
        })
        .retrieve().bodyToMono(Boolean.class);
        
    // 인가 체크 API 호출 결과
    granted = body.toFuture().get().booleanValue();
    
} catch (Exception e) {
    log.error("인가 서버에 요청 중 오류 : {}", e.getMessage());
    throw new AuthorizationServiceException("인가 요청시 오류 발생");
    // return Mono.just(new AuthorizationDecision(true));
}

// 😜 5. Gateway 최종 판단 (true -> 서비스 호출/false -> 403)
return Mono.just(new AuthorizationDecision(granted));
```

토큰을 그대로 넣어서 WebClient.create(baseUrl).get()으로 Boolean 응답을 받고, 

그 값을 AuthorizationDecision으로 반환합니다. 

실패하면 인가 요청시 오류 발생 예외를 던집니다.

---

이걸 한 줄로 요약하면:

> 이 게이트웨이는 “JWT 서명 검증” + “인가 서버 확인” 
> 두 단계를 모두 통과해야 요청을 통과시킵니다.

---

6. 왜 희원님이 본 503이 여기서 나왔는가

희원님이 전에 본 로그가 인가 서버에 요청 중 오류와 No servers available for service: BACKEND5-SERVICE였죠. 그건 이 파일을 보면 바로 연결됩니다. ReactiveAuthorization은 인가 확인을 위해 /backend5-service/api/authorizations/check로 요청을 보내게 되어 있는데, 게이트웨이의 라우팅도 lb://BACKEND5-SERVICE를 사용합니다. 따라서 discovery에 BACKEND5-SERVICE가 등록돼 있지 않으면 인가 체크 자체가 실패합니다. 그 결과 protected endpoint 접근이 막히는 겁니다.

즉 현재 구조에서는 backend5-service가 단순 비즈니스 서비스가 아니라, 사실상 인가 판정의 의존 서비스 역할까지 맡고 있습니다. 그래서 이 서비스가 안 뜨면 게이트웨이 보안 흐름도 같이 흔들립니다.