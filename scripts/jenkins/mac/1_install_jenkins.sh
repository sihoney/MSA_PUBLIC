#!/usr/bin/env bash
set -euo pipefail

# Jenkins를 Docker 컨테이너로 설치한다.
# 이 스크립트는 Jenkins 자체와 Jenkins가 사용할 로컬 도구 접근 경로를 준비한다.

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 설치 전에 Docker, kubectl, minikube가 먼저 있어야 한다.
for cmd in docker kubectl minikube; do
  require_cmd "${cmd}"
done

# 같은 이름의 컨테이너가 이미 있으면 새로 만들지 않는다.
if container_exists; then
  echo "이미 Jenkins 컨테이너가 있습니다: ${JENKINS_CONTAINER}"
  print_jenkins_info
  exit 0
fi

# Jenkins 설정 파일을 저장할 로컬 폴더를 미리 만든다.
mkdir -p "${JENKINS_HOME_DIR}"

# 현재 시스템에서 실제로 쓰는 바이너리 경로를 구한다.
# 이 경로를 컨테이너 안에도 그대로 마운트해서 Jenkins가 같은 명령을 쓰게 한다.
DOCKER_BIN="$(command -v docker)"
KUBECTL_BIN="$(command -v kubectl)"
MINIKUBE_BIN="$(command -v minikube)"

echo "[jenkins] Jenkins 컨테이너 설치"
# Jenkins를 Docker 컨테이너로 띄운다.
# 주요 포인트:
# - root 계정으로 실행해서 Docker socket, kube 설정 파일 접근을 단순하게 만든다.
# - docker.sock을 마운트해서 컨테이너 안 Jenkins가 바깥 Docker를 제어한다.
# - ~/.kube, ~/.minikube를 마운트해서 host의 Kubernetes 설정을 그대로 쓴다.
# - 작업 폴더 전체를 마운트해서 Jenkins가 같은 소스를 바로 사용한다.
docker run -d \
  --name "${JENKINS_CONTAINER}" \
  --restart unless-stopped \
  -u root \
  -p "${JENKINS_PORT}:8080" \
  -p "${JENKINS_AGENT_PORT}:50000" \
  -v "${JENKINS_HOME_DIR}:/var/jenkins_home" \
  -v "${WORKSPACE_ROOT}:${WORKSPACE_ROOT}" \
  -v "${DOCKER_BIN}:${DOCKER_BIN}:ro" \
  -v "${KUBECTL_BIN}:${KUBECTL_BIN}:ro" \
  -v "${MINIKUBE_BIN}:${MINIKUBE_BIN}:ro" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${HOME}/.kube:/root/.kube" \
  -v "${HOME}/.minikube:/root/.minikube" \
  -w "${WORKSPACE_ROOT}" \
  "${JENKINS_IMAGE}"

echo
echo "[jenkins] 설치 완료"
# 접속 주소와 Jenkins Home 위치를 바로 출력한다.
print_jenkins_info
# 최초 로그인 비밀번호를 바로 확인할 다음 명령도 같이 보여준다.
echo "초기 비밀번호 확인: ./MSA/scripts/jenkins/mac/3_show_admin_password.sh"
