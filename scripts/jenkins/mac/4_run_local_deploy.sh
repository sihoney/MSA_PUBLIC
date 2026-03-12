#!/usr/bin/env bash
set -euo pipefail

# Jenkins Job에서 호출할 로컬 배포 스크립트
# 순서:
# 1) minikube 시작
# 2) config-service 배포
# 3) discovery 배포
# 4) apigateway 배포
# 5) member-service 배포

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 이 스크립트는 minikube, kubectl, docker를 모두 사용한다.
for cmd in minikube kubectl docker bash; do
  require_cmd "${cmd}"
done

# 각 모듈의 `all_in_one.sh`를 그대로 재사용한다.
# 이렇게 하면 모듈별 빌드/배포 로직을 한 군데에서 유지할 수 있다.
run_module() {
  local module_dir="$1"
  local module_name="$2"

  echo "[jenkins-deploy] ${module_name} 배포 시작"
  (
    # 대상 모듈 폴더로 이동해서 그 모듈 스크립트를 실행한다.
    cd "${module_dir}"
    # 이미지 태그, 네임스페이스 같은 값은 Jenkins job에서 바꾸기 쉽도록
    # 환경변수로 넘겨준다.
    IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
    IMAGE_TAG="${IMAGE_TAG}" \
    NAMESPACE="${NAMESPACE}" \
    LOAD_TO_MINIKUBE="${LOAD_TO_MINIKUBE}" \
    ./scripts/all_in_one.sh
  )
}

echo "[jenkins-deploy] minikube 시작"
# 로컬 Kubernetes 클러스터가 꺼져 있으면 먼저 올린다.
minikube start --driver="${MINIKUBE_DRIVER}"

# 의존 순서대로 인프라를 먼저 올리고 마지막에 member-service를 올린다.
run_module "${MSA_DIR}/config" "config-service"
run_module "${MSA_DIR}/discovery" "discovery"
run_module "${MSA_DIR}/apigateway" "apigateway"
run_module "${MEMBER_DIR}" "member-service"

echo
echo "[jenkins-deploy] 배포 완료"
# 실제 상태와 Swagger 확인은 다음 스크립트로 분리했다.
echo "상태 확인은 5_check_local_deploy.sh로 진행하세요."
