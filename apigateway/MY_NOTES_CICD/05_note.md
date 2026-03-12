# Dockerfile 수정 (local -> local github actions)

좋아. 이 Dockerfile 수정은 단순 문법 수정이 아니라, 

> **“윈도우에서 만든 Gradle wrapper를 리눅스 컨테이너 안에서 안전하게 실행하기 위한 보정 
> + 멀티스테이지 빌드 구조 적용”**

이라고 보면 된다.

---

핵심부터 말하면, 네가 수정한 이유는 크게 3가지야.

첫째, gradlew 실행 오류를 막기 위해서
둘째, 빌드용 환경과 실행용 환경을 분리하기 위해서
셋째, 최종 이미지를 더 가볍게 만들기 위해서다.

---

## 1. 왜 수정된 건가

네가 처음 만난 에러는 이거였지.

```
/usr/bin/env: ‘sh\r’: No such file or directory
```

이건 거의 전형적인 **CRLF 문제**야.

윈도우에서 생성하거나 수정한 gradlew 파일은 줄바꿈이 CRLF(\r\n)일 수 있는데,
도커 컨테이너 안은 리눅스라서 LF(\n)만 기대한다.

즉 gradlew 첫 줄이 원래는:

```
#!/usr/bin/env sh
```

이렇게 읽혀야 하는데, 실제로는:

```
#!/usr/bin/env sh\r
```

처럼 돼서 리눅스가 sh가 아니라 sh\r를 찾으려다 실패한 거야.

그래서 이 줄이 추가된 거다.

```
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew && ./gradlew bootJar --no-daemon
```

여기서 **sed -i 's/\r$//' gradlew**가 줄 끝의 \r 제거, 
즉 CRLF를 LF처럼 보정하는 역할을 한다.

---

## 2. 전체 구조 먼저 보기

이 Dockerfile은 **멀티 스테이지 빌드 구조**야.

즉 단계를 두 개로 나눈다.

### 1단계: builder

Gradle로 소스코드를 빌드

jar 파일 생성

### 2단계: runtime

만들어진 jar만 복사

실제 실행만 담당

이렇게 나누는 이유는, 최종 이미지 안에 Gradle, 소스코드, 빌드 캐시 같은 걸 다 넣지 않기 위해서야.
즉 최종 컨테이너는 실행에 필요한 jar만 가지게 된다.

---

## 3. 각 명령어 설명

이제 위에서부터 하나씩 보자.

```
FROM gradle:7.4.0-jdk AS builder
```

의미:

**베이스 이미지를 gradle:7.4.0-jdk로 사용**

이 단계의 이름을 builder로 지정

설명:

이 이미지는 **Gradle과 JDK가 이미 설치되어 있는 빌드용 이미지**야.

소스코드를 컨테이너 안에서 바로 ./gradlew bootJar로 빌드할 수 있다.

---

```
AS builder
```

를 붙이면 나중에 다른 단계에서

COPY --from=builder ...처럼 결과물을 꺼내 쓸 수 있다.

쉽게 말하면:

1번 작업실 이름이 builder

여기서 jar를 만든 뒤

나중 단계에서 그 결과만 가져가는 구조야.

---

```
WORKDIR /workspace
```

의미:

현재 작업 디렉토리를 /workspace로 설정

설명:

이후 COPY, RUN 같은 명령이 기본적으로 이 폴더 기준으로 동작한다.

리눅스에서 cd /workspace 해놓고 작업하는 것과 비슷하게 생각하면 된다.

즉:

컨테이너 안의 작업 루트를 /workspace로 잡은 거야.

---

```
COPY gradle gradle
```

의미:

로컬 프로젝트의 gradle 폴더를 컨테이너 안의 gradle 폴더로 복사

설명:

Gradle wrapper가 사용하는 설정/실행 파일들이 들어 있다.

보통 gradle/wrapper/... 경로 아래 wrapper 관련 파일들이 있음.

왜 필요하냐면:

./gradlew는 혼자 못 돌고, 내부적으로 이 wrapper 관련 파일을 참조한다.

---

```
COPY gradlew gradlew
```

의미:

로컬의 gradlew 파일을 컨테이너 안으로 복사

설명:

gradlew는 Gradle wrapper 실행 스크립트다.

리눅스/맥에서는 ./gradlew

윈도우에서는 보통 gradlew.bat

도커 컨테이너는 리눅스니까 gradlew가 필요하다.

---

```
COPY build.gradle settings.gradle ./
```

의미:

build.gradle, settings.gradle 파일을 현재 작업 디렉토리(/workspace)에 복사

설명:

Gradle 빌드 설정 파일이다.

어떤 플러그인을 쓰는지, 의존성이 뭔지, 어떤 태스크를 실행하는지 여기 정의돼 있다.

./는 현재 디렉토리, 즉 /workspace를 의미한다.

---

```
COPY src src
```

의미:

로컬의 src 디렉토리를 컨테이너 안의 src로 복사

설명:

실제 자바 소스코드, 리소스 파일 등을 복사하는 단계다.

이것까지 복사돼야 bootJar가 실제 프로젝트를 빌드할 수 있다.

---

```
RUN sed -i 's/\r$//' gradlew &&
   chmod +x gradlew && 
   ./gradlew bootJar --no-daemon
```

이 줄이 제일 중요하다.

세 부분으로 나눠서 봐야 한다.

---

> 1) sed -i 's/\r$//' gradlew

의미:

gradlew 파일 각 줄 끝에 있는 \r 문자를 제거

설명:

sed는 텍스트 치환 도구다.

's/\r$//'는 “줄 끝에 있는 carriage return(\r)을 빈 문자열로 바꿔라”는 뜻

-i는 파일을 직접 수정하라는 뜻

즉:

윈도우식 줄바꿈 때문에 생긴 CRLF 문제를 Docker 안에서 바로 고친다.

왜 필요한가:

local GitHub Actions든 Docker build든 대부분 러너는 리눅스 환경이기 때문

윈도우에서 작성한 스크립트 파일이 리눅스에서 그대로 깨질 수 있음

---

> 2) chmod +x gradlew

의미:

gradlew 파일에 실행 권한 부여

설명:

리눅스에서는 파일이 있어도 실행 권한이 없으면 ./gradlew처럼 실행할 수 없다.

+x는 **executable, 즉 실행 가능 권한** 추가라는 뜻

즉:

“이 파일은 실행 가능한 스크립트다”라고 표시하는 작업이다.

---

> 3) ./gradlew bootJar --no-daemon

의미:

Gradle wrapper로 bootJar 태스크 실행

설명:

bootJar는 Spring Boot 실행 가능한 **jar를 만드는** 태스크다.

보통 build/libs/ 아래에 jar 파일이 생성된다.

--no-daemon은 백그라운드 데몬 프로세스를 쓰지 않고 **1회성**으로 실행하라는 뜻

---

왜 --no-daemon을 쓰냐:

CI/CD 환경은 짧게 실행되고 끝나는 비영구 환경이라, 데몬을 굳이 띄울 이점이 적다.

빌드 서버나 Docker build 단계에선 보통 --no-daemon을 자주 사용한다.

---

즉 이 한 줄 전체는:

- 줄바꿈 문제 해결
- 실행 권한 부여
- jar 빌드

를 한 번에 처리하는 거야.

---

```
#RUN chmod +x gradlew && ./gradlew bootJar --no-daemon
```

이 주석 처리된 이전 줄은 왜 빠졌냐?

원래는 이것만 있었는데, CRLF 문제가 있는 경우엔 이걸로는 해결이 안 된다.

---

## 4. 두 번째 단계 설명

```  
FROM eclipse-temurin:8-jre
```

의미:

최종 실행 이미지는 **Java 8 JRE 기반**으로 사용

설명:

여기서는 더 이상 Gradle도 필요 없고, 소스코드도 필요 없다.

**그냥 jar를 실행만 하면** 되니까 JRE만 있으면 된다.

---

이게 멀티 스테이지 빌드의 핵심이야.

> 빌드는 무거운 이미지에서
> 실행은 가벼운 이미지에서

---

다만 주의할 점도 있다.
빌드 JDK 버전과 실행 JRE 버전이 맞아야 한다.

지금은 builder 쪽이 gradle:7.4.0-jdk라 태그가 좀 애매한데, 런타임은 명시적으로 Java 8이다.
프로젝트가 Java 8 기준이면 괜찮지만, Java 17 기능으로 빌드되면 실행 시 깨질 수 있다.

이건 수업에서 꽤 중요한 포인트다.
“빌드 성공”과 “실행 성공”은 다른 문제다.

---

```
RUN mkdir -p /usr/app/msa-attach-volume/messages
```

의미:

디렉토리 생성

설명:

/usr/app/msa-attach-volume/messages 폴더를 만든다.

-p는 중간 경로가 없어도 같이 만들라는 뜻

왜 필요할까:

애플리케이션이 실행 중 이 경로를 참조하거나 파일을 저장할 수 있기 때문

미리 만들어 두지 않으면 런타임에 파일 저장 시 오류가 날 수 있다

즉:

**앱이 사용할 폴더**를 컨테이너 시작 전에 준비하는 거다.

---

```
WORKDIR /usr/app
```

의미:

이제 실행 단계의 기본 작업 디렉토리를 /usr/app로 설정

설명:

이후 jar 복사나 실행 기준 위치가 된다.

---

```
COPY --from=builder /workspace/build/libs/*.jar app.jar
```

의미:

builder 단계에서 만든 jar 파일을 현재 단계로 복사

이름은 app.jar로 저장

설명:

이게 멀티 스테이지 빌드의 핵심 문법이다.

앞 단계 builder에서 생성된 결과물을 가져온다.

/workspace/build/libs/*.jar 위치의 jar를 최종 이미지 안 /usr/app/app.jar로 복사

즉:

소스코드 전체를 가져오는 게 아니라

빌드 결과물만 가져오는 것

이게 좋은 이유: 

- 최종 이미지가 가벼워짐
- 보안상도 조금 더 단순해짐
- 빌드 도구가 최종 이미지에 안 들어감

---
```
EXPOSE 8000
```

의미:

컨테이너가 8000 포트를 사용한다고 문서화

설명:

이건 실제 포트를 자동 개방하는 명령은 아니고,

“이 컨테이너는 8000 포트에서 서비스할 예정”이라고 알려주는 역할에 가깝다.

실제 외부에서 접근하려면 여전히

docker run -p 8000:8000

혹은 Kubernetes Service 설정
이 필요하다.

즉:

포트 사용 선언이지, 연결 자체는 아니다.

---

```
CMD ["java", "-jar", "/usr/app/app.jar"]
```

의미:

**컨테이너 시작 시 기본 실행 명령**

설명:

컨테이너가 뜨면 자바로 /usr/app/app.jar 실행

JSON 배열 형태는 exec form이라 쉘을 거치지 않고 바로 실행됨

문자열 하나로 쓰는 shell form보다 보통 더 안정적이다

즉:

최종 컨테이너의 역할은 “이 jar 실행” 하나다.