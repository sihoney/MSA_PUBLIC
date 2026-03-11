```
@EnableWebFluxSecurity // Spring Security 설정들을 활성화시켜 준다
public class WebFluxSecurityConfig {
    ...
}
```

- **@EnableWebFluxSecurity**가 붙어 있고, **SecurityWebFilterChain**을 직접 구성
- 여기서 중요한 건 이 게이트웨이가 Servlet 기반 Spring MVC 보안이 아니라 WebFlux 기반 보안 체인을 쓰고 있다는 점
- 그래서 클래스 이름도 WebFluxSecurityConfig입니다.

---

### 실제로 하는 설정

```
@EnableWebFluxSecurity 
public class WebFluxSecurityConfig {

    @Bean
    public SecurityWebFilterChain configure(
        ServerHttpSecurity http, 
        ReactiveAuthorizationManager<AuthorizationContext> check
    ) throws Exception {
        http.csrf().disable()
            ...
        return http.build();
    }

}
```

CSRF 비활성화

---

```
http.headers().frameOptions().disable()
```

frameOptions 비활성화

---

```
.formLogin().disable()
```

formLogin 비활성화

---

```
.httpBasic().authenticationEntryPoint(
    new HttpStatusServerEntryPoint(HttpStatus.UNAUTHORIZED)
) 
// login dialog disabled & 401 HttpStatus return
```

httpBasic 인증 실패 시 401 반환

---

```
private final static String[] PERMITALL_ANTPATTERNS = {
        ReactiveAuthorization.AUTHORIZATION_URI, "/", "/csrf",
        "/backend5-service/api/member/login", "/?*-service/api/v1/messages/**", "/api/v1/messages/**",
        "/member-service/api/v1/refresh/token",
        "/?*-service/actuator/?*", "/actuator/?*",
        "/actuator/gateway/**",
        ...
        "/v3/api-docs/**", "/?*-service/v3/api-docs", "/swagger*/**", "/webjars/**"
};

private final static String USER_JOIN_ANTPATTERNS = "/member-service/api/v1/members";

...

.authorizeExchange()
    .pathMatchers(PERMITALL_ANTPATTERNS).permitAll()
    .pathMatchers(HttpMethod.POST, USER_JOIN_ANTPATTERNS).permitAll()
```

일부 경로는 permitAll

---

```
.anyExchange().access(check);
```

그 외 나머지는 ReactiveAuthorization으로 인가 검사

반대로 나머지 요청은 anyExchange().access(check)로 가는데, 
여기서 check가 바로 ReactiveAuthorization입니다. 
즉 보안의 실제 핵심 판단은 ReactiveAuthorization이 한다고 보면 됩니다.

---

