@echo off
setlocal EnableExtensions

rem 실행 중인 Jenkins 컨테이너를 중지한다.

call "%~dp0common.bat"

rem 컨테이너 중지에는 Docker가 필요하다.
where docker >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: docker
  exit /b 1
)

rem 설치가 안 된 상태면 중지할 대상도 없다.
docker ps -a --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if errorlevel 1 (
  echo Jenkins 컨테이너가 없습니다.
  exit /b 0
)

rem 이미 꺼져 있으면 그대로 종료한다.
docker ps --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if errorlevel 1 (
  echo Jenkins는 이미 중지되어 있습니다.
  exit /b 0
)

rem 실행 중인 Jenkins 컨테이너를 정상 종료한다.
docker stop "%JENKINS_CONTAINER%" >nul
if errorlevel 1 exit /b 1

echo [jenkins] 중지 완료
exit /b 0
