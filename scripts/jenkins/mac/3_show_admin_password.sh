#!/usr/bin/env bash
set -euo pipefail

# Jenkins 최초 접속용 관리자 비밀번호를 보여준다.

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 비밀번호는 컨테이너 안 파일에서 읽으므로 Docker가 필요하다.
require_cmd docker

# 설치가 안 된 상태면 비밀번호 파일도 없다.
if ! container_exists; then
  echo "Jenkins 컨테이너가 없습니다. 먼저 1_install_jenkins.sh를 실행하세요." >&2
  exit 1
fi

# 실행 중인 컨테이너 안에서 비밀번호 파일을 읽는다.
if ! container_running; then
  echo "Jenkins가 꺼져 있습니다. 먼저 2_start_jenkins.sh를 실행하세요." >&2
  exit 1
fi

echo "[jenkins] 초기 관리자 비밀번호"
# Jenkins 첫 로그인 화면에서 그대로 입력할 문자열을 출력한다.
docker exec "${JENKINS_CONTAINER}" cat /var/jenkins_home/secrets/initialAdminPassword
