@echo off
setlocal EnableExtensions

rem 이미 설치된 Jenkins 컨테이너를 실행한다.

call "%~dp0common.bat"

rem 컨테이너를 시작하려면 Docker가 있어야 한다.
where docker >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: docker
  exit /b 1
)

rem 설치되지 않은 상태에서 start만 치는 경우를 막는다.
docker ps -a --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if errorlevel 1 (
  echo Jenkins 컨테이너가 없습니다. 먼저 1_install_jenkins.bat를 실행하세요.
  exit /b 1
)

rem 이미 실행 중이면 다시 시작하지 않고 정보만 보여준다.
docker ps --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if not errorlevel 1 (
  echo Jenkins가 이미 실행 중입니다.
  echo Jenkins URL: http://localhost:%JENKINS_PORT%
  echo 컨테이너 이름: %JENKINS_CONTAINER%
  echo Jenkins Home: %JENKINS_HOME_DIR%
  exit /b 0
)

rem 중지돼 있던 Jenkins 컨테이너를 켠다.
docker start "%JENKINS_CONTAINER%" >nul
if errorlevel 1 exit /b 1

echo [jenkins] 실행 완료
echo Jenkins URL: http://localhost:%JENKINS_PORT%
echo 컨테이너 이름: %JENKINS_CONTAINER%
echo Jenkins Home: %JENKINS_HOME_DIR%
exit /b 0
