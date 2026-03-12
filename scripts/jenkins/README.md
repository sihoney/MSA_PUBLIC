# Jenkins 스크립트 정리

운영체제별로 폴더를 나눴습니다.

## mac

1. `mac/1_install_jenkins.sh`
2. `mac/2_start_jenkins.sh`
3. `mac/3_show_admin_password.sh`
4. `mac/4_run_local_deploy.sh`
5. `mac/5_check_local_deploy.sh`
6. `mac/6_stop_jenkins.sh`
7. `mac/common.sh`

## windows

1. `windows/1_install_jenkins.bat`
2. `windows/2_start_jenkins.bat`
3. `windows/3_show_admin_password.bat`
4. `windows/4_run_local_deploy.bat`
5. `windows/5_check_local_deploy.bat`
6. `windows/6_stop_jenkins.bat`
7. `windows/common.bat`

공통 순서는 같습니다.

1. Jenkins 설치
2. Jenkins 실행
3. 초기 비밀번호 확인
4. 로컬 배포 실행
5. 배포 상태 확인
6. Jenkins 중지

Windows 배치 파일은 `docker`, `kubectl`, `minikube`, `powershell`을 직접 사용한다.

`windows/4_run_local_deploy.bat`는 기존 모듈별 `all_in_one.sh`를 재사용하므로
Git Bash의 `bash.exe`가 PATH에 잡혀 있어야 한다.
