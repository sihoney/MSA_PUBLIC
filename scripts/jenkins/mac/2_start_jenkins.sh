#!/usr/bin/env bash
set -euo pipefail

# 이미 설치된 Jenkins 컨테이너를 실행한다.

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 컨테이너를 시작하려면 Docker가 있어야 한다.
require_cmd docker

# 설치되지 않은 상태에서 start만 치는 경우를 막는다.
if ! container_exists; then
  echo "Jenkins 컨테이너가 없습니다. 먼저 1_install_jenkins.sh를 실행하세요." >&2
  exit 1
fi

# 이미 실행 중이면 다시 시작하지 않고 정보만 보여준다.
if container_running; then
  echo "Jenkins가 이미 실행 중입니다."
  print_jenkins_info
  exit 0
fi

# 중지돼 있던 Jenkins 컨테이너를 켠다.
docker start "${JENKINS_CONTAINER}" >/dev/null

echo "[jenkins] 실행 완료"
# 브라우저 접속 정보를 바로 보여준다.
print_jenkins_info
