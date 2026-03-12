@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Jenkins를 Docker 컨테이너로 설치한다.
rem 이 스크립트는 Jenkins 자체와 Jenkins가 사용할 로컬 도구 접근 경로를 준비한다.

call "%~dp0common.bat"

rem 설치 전에 Docker, kubectl, minikube가 먼저 있어야 한다.
where docker >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: docker
  exit /b 1
)
where kubectl >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: kubectl
  exit /b 1
)
where minikube >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: minikube
  exit /b 1
)

rem 같은 이름의 컨테이너가 이미 있으면 새로 만들지 않는다.
for /f "delims=" %%I in ('docker ps -a --format "{{.Names}}" ^| findstr /x /c:"%JENKINS_CONTAINER%"') do set "CONTAINER_EXISTS=1"
if defined CONTAINER_EXISTS (
  echo 이미 Jenkins 컨테이너가 있습니다: %JENKINS_CONTAINER%
  echo Jenkins URL: http://localhost:%JENKINS_PORT%
  echo 컨테이너 이름: %JENKINS_CONTAINER%
  echo Jenkins Home: %JENKINS_HOME_DIR%
  exit /b 0
)

rem Jenkins 설정 파일을 저장할 로컬 폴더를 미리 만든다.
if not exist "%JENKINS_HOME_DIR%" mkdir "%JENKINS_HOME_DIR%"

echo [jenkins] Jenkins 컨테이너 설치
rem Jenkins를 Docker 컨테이너로 띄운다.
rem 주요 포인트:
rem - docker.sock을 마운트해서 컨테이너 안 Jenkins가 바깥 Docker를 제어한다.
rem - .kube, .minikube를 마운트해서 host의 Kubernetes 설정을 그대로 쓴다.
rem - 작업 폴더 전체를 /workspace로 마운트해서 Jenkins가 같은 소스를 바로 사용한다.
docker run -d ^
  --name "%JENKINS_CONTAINER%" ^
  --restart unless-stopped ^
  -u root ^
  -p "%JENKINS_PORT%:8080" ^
  -p "%JENKINS_AGENT_PORT%:50000" ^
  -v "%JENKINS_HOME_DIR%:/var/jenkins_home" ^
  -v "%WORKSPACE_ROOT%:/workspace" ^
  -v //var/run/docker.sock:/var/run/docker.sock ^
  -v "%USERPROFILE%\.kube:/root/.kube" ^
  -v "%USERPROFILE%\.minikube:/root/.minikube" ^
  -w /workspace ^
  "%JENKINS_IMAGE%"
if errorlevel 1 exit /b 1

echo.
echo [jenkins] 설치 완료
echo Jenkins URL: http://localhost:%JENKINS_PORT%
echo 컨테이너 이름: %JENKINS_CONTAINER%
echo Jenkins Home: %JENKINS_HOME_DIR%
echo 초기 비밀번호 확인: MSA\scripts\jenkins\windows\3_show_admin_password.bat
exit /b 0
