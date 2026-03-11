## 1. 어디부터 봐야 하나: apigateway

위치:

```
.../apigateway/ApigatewayApplication.java
```

**@EnableDiscoveryClient**

- Eureka Client로 설정
- Eureka Server가 먼저 떠야 한다

> 즉 이 게이트웨이는 혼자 뜨는 게 아니라 discovery에 등록되는 클라이언트입니다.

---

## 2. 실제 라우팅 규칙은 어디 있나: application.yml

포트 번호: 

```
server:
  port: 8000
```

애플리케이션 이름 & 라우트 정의

```
spring:
  application:
    name: apigateway
  cloud:
    gateway:
      routes:
        - id: member-service
          uri: lb://MEMBER-SERVICE
          predicates:
            - Path=/member-service/**
          filters:
            - RewritePath=/member-service/(?<segment>.*), /$\{segment}
        - id: backend5-service
          uri: lb://BACKEND5-SERVICE
          predicates:
            - Path=/backend5-service/**
          filters:
            - RewritePath=/backend5-service/(?<segment>.*), /$\{segment}
        - id: openapi
          uri: http://localhost:${server.port}
          predicates:
            - Path=/v3/api-docs/**
          filters:
            - RewritePath=/v3/api-docs/(?<segment>.*), /$\{segment}/v3/api-docs
```

default-filters & discovery locator 설정

```
spring:
  cloud:
    gateway:
      default-filters:
        - name: GlobalFilter
          args:
            preLogger: true
            postLogger: true
      discovery:
        locator:
          enabled: true
```

config server URI 설정

```
spring:
  cloud:
    config:
      uri: http://localhost:8888
      name: application
```

---

## 3. 게이트웨이 내부에서 어떤 코드가 있나

하위 패키지/파일

- api
- config
- exception
- filter
- ApigatewayApplication.java

특히 **config 폴더**에는 아래 파일들이 있습니다.

- MessageSourceConfig.java
- OpenApiDocConfig.java
- ReactiveAuthorization.java
- WebFluxSecurityConfig.java

---

이 구성의 의미

- WebFluxSecurityConfig.java → 게이트웨이 보안 설정
- ReactiveAuthorization.java → 리액티브 방식 인가 로직
- GlobalFilter.java → 모든 요청/응답 앞뒤에 공통 처리
- OpenApiDocConfig.java → Swagger/OpenAPI 문서 관련 설정

> 즉, 게이트웨이에서 “요청을 어디로 보낼지”만 하는 게 아니라 
> 보안, 인가, 문서, 공통 필터링까지 처리하게 만든 구조