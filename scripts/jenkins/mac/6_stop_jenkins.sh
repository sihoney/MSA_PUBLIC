#!/usr/bin/env bash
set -euo pipefail

# 실행 중인 Jenkins 컨테이너를 중지한다.

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 컨테이너 중지에는 Docker가 필요하다.
require_cmd docker

# 설치가 안 된 상태면 중지할 대상도 없다.
if ! container_exists; then
  echo "Jenkins 컨테이너가 없습니다."
  exit 0
fi

# 이미 꺼져 있으면 그대로 종료한다.
if ! container_running; then
  echo "Jenkins는 이미 중지되어 있습니다."
  exit 0
fi

# 실행 중인 Jenkins 컨테이너를 정상 종료한다.
docker stop "${JENKINS_CONTAINER}" >/dev/null

echo "[jenkins] 중지 완료"
