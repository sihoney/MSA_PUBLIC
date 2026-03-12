#!/usr/bin/env bash
set -euo pipefail

# 공통으로 쓰는 경로와 기본값을 한 곳에 모아 둔 파일이다.
# 다른 Jenkins 스크립트들은 이 파일을 source 해서 같은 값을 재사용한다.

# 현재 파일 위치를 기준으로 경로를 계산하면
# 어느 폴더에서 실행하든 동일한 경로를 사용할 수 있다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# `WORKSPACE_ROOT`는 `MSA`, `member-service`가 같이 있는 작업 폴더다.
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# 공통 인프라 모듈이 있는 MSA 폴더
MSA_DIR="${WORKSPACE_ROOT}/MSA"
# member-service 모듈 폴더
MEMBER_DIR="${WORKSPACE_ROOT}/member-service"

# Jenkins Docker 컨테이너 이름
JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins-local}"
# 설치할 Jenkins 이미지
JENKINS_IMAGE="${JENKINS_IMAGE:-jenkins/jenkins:lts-jdk17}"
# 브라우저에서 Jenkins에 접속할 포트
JENKINS_PORT="${JENKINS_PORT:-8090}"
# Jenkins 에이전트 통신 포트
JENKINS_AGENT_PORT="${JENKINS_AGENT_PORT:-50000}"
# Jenkins 설정, 플러그인, Job 정보가 저장될 로컬 폴더
JENKINS_HOME_DIR="${JENKINS_HOME_DIR:-${WORKSPACE_ROOT}/.jenkins_home}"

# Docker 이미지 이름 앞부분
IMAGE_REGISTRY="${IMAGE_REGISTRY:-local}"
# Jenkins 실행마다 다르게 줄 수 있는 이미지 태그
IMAGE_TAG="${IMAGE_TAG:-jenkins-$(date +%Y%m%d%H%M%S)}"
# Kubernetes 네임스페이스
NAMESPACE="${NAMESPACE:-msa}"
# true면 이미지를 minikube에 적재한다.
LOAD_TO_MINIKUBE="${LOAD_TO_MINIKUBE:-true}"
# minikube가 사용할 드라이버
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-docker}"
# true면 배포 확인 시 Swagger 응답까지 검사한다.
CHECK_SWAGGER="${CHECK_SWAGGER:-true}"
# port-forward에 잠깐 사용할 로컬 포트
PORT_FORWARD_PORT="${PORT_FORWARD_PORT:-18000}"

# 스크립트 실행 전에 필요한 명령이 설치돼 있는지 확인한다.
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "필수 명령을 찾지 못했습니다: $1" >&2
    exit 1
  fi
}

# Jenkins 컨테이너가 "존재"하는지 확인한다.
# 꺼져 있어도 생성돼 있으면 true가 된다.
container_exists() {
  docker ps -a --format '{{.Names}}' | grep -Fx "${JENKINS_CONTAINER}" >/dev/null 2>&1
}

# Jenkins 컨테이너가 현재 "실행 중"인지 확인한다.
container_running() {
  docker ps --format '{{.Names}}' | grep -Fx "${JENKINS_CONTAINER}" >/dev/null 2>&1
}

# 자주 보여주는 접속 정보를 함수로 묶어 둔다.
print_jenkins_info() {
  echo "Jenkins URL: http://localhost:${JENKINS_PORT}"
  echo "컨테이너 이름: ${JENKINS_CONTAINER}"
  echo "Jenkins Home: ${JENKINS_HOME_DIR}"
}
