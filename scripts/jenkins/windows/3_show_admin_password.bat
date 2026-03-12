@echo off
setlocal EnableExtensions

rem Jenkins 최초 접속용 관리자 비밀번호를 보여준다.

call "%~dp0common.bat"

rem 비밀번호는 컨테이너 안 파일에서 읽으므로 Docker가 필요하다.
where docker >nul 2>&1 || (
  echo 필수 명령을 찾지 못했습니다: docker
  exit /b 1
)

rem 설치가 안 된 상태면 비밀번호 파일도 없다.
docker ps -a --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if errorlevel 1 (
  echo Jenkins 컨테이너가 없습니다. 먼저 1_install_jenkins.bat를 실행하세요.
  exit /b 1
)

rem 실행 중인 컨테이너 안에서 비밀번호 파일을 읽는다.
docker ps --format "{{.Names}}" | findstr /x /c:"%JENKINS_CONTAINER%" >nul 2>&1
if errorlevel 1 (
  echo Jenkins가 꺼져 있습니다. 먼저 2_start_jenkins.bat를 실행하세요.
  exit /b 1
)

echo [jenkins] 초기 관리자 비밀번호
rem Jenkins 첫 로그인 화면에서 그대로 입력할 문자열을 출력한다.
docker exec "%JENKINS_CONTAINER%" cat /var/jenkins_home/secrets/initialAdminPassword
exit /b 0
