FROM gradle:7.4.0-jdk AS builder
WORKDIR /workspace

COPY gradle gradle
COPY gradlew gradlew
COPY build.gradle settings.gradle ./
COPY src src

RUN sed -i 's/\r$//' gradlew && chmod +x gradlew && ./gradlew bootJar --no-daemon
#RUN chmod +x gradlew && ./gradlew bootJar --no-daemon

# openjdk8 base image
FROM eclipse-temurin:8-jre
# directory 생성
RUN mkdir -p /usr/app/msa-attach-volume/messages
# 작업 시작 위치
WORKDIR /usr/app
# jar 파일 복사
COPY --from=builder /workspace/build/libs/*.jar app.jar
# application port
EXPOSE 8000
# 실행
CMD ["java", "-jar", "/usr/app/app.jar"]


## openjdk8 base image
#FROM eclipse-temurin:8-jre
#
## directory 생성
#RUN mkdir -p /usr/app/msa-attach-volume/messages
## jar 파일이 복사되는 위치
#ENV APP_HOME=/usr/app/
## 작업 시작 위치
#WORKDIR $APP_HOME
## jar 파일 복사
#COPY build/libs/*.jar apigateway.jar
## application port
#EXPOSE 8000
## 실행
#CMD ["java", "-Dspring.profiles.active=${profile:default}", "-jar", "apigateway.jar"]
