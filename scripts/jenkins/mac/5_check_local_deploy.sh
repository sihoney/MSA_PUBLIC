#!/usr/bin/env bash
set -euo pipefail

# Jenkins 배포 후 상태를 확인한다.
# Pod/Service 상태를 보고, 필요하면 게이트웨이 Swagger 응답도 체크한다.

# 공통 변수와 공통 함수를 불러온다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# 상태 조회와 HTTP 확인에 필요한 명령만 체크한다.
for cmd in kubectl curl; do
  require_cmd "${cmd}"
done

# 디플로이먼트가 의도한 replica 수로 올라왔는지 먼저 본다.
echo "[jenkins-check] deployment 상태"
kubectl -n "${NAMESPACE}" get deployment

echo
# 실제 파드가 Running/Ready인지 확인한다.
echo "[jenkins-check] pod 상태"
kubectl -n "${NAMESPACE}" get pods -o wide

echo
# 서비스 이름과 포트가 원하는 값인지 확인한다.
echo "[jenkins-check] service 상태"
kubectl -n "${NAMESPACE}" get svc

# Swagger 검사를 끄고 싶을 때는 CHECK_SWAGGER=false로 실행하면 여기서 끝난다.
if [[ "${CHECK_SWAGGER}" != "true" ]]; then
  exit 0
fi

# port-forward는 백그라운드로 띄우고,
# 스크립트가 끝날 때 자동으로 정리되게 cleanup 함수를 둔다.
pf_pid=""
cleanup() {
  if [[ -n "${pf_pid}" ]] && kill -0 "${pf_pid}" >/dev/null 2>&1; then
    kill "${pf_pid}" >/dev/null 2>&1 || true
    wait "${pf_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# 게이트웨이를 임시 로컬 포트로 연결한다.
kubectl -n "${NAMESPACE}" port-forward svc/apigateway "${PORT_FORWARD_PORT}:8000" >/tmp/jenkins-local-port-forward.log 2>&1 &
pf_pid=$!

# 게이트웨이 응답이 올라오는 데 시간이 걸릴 수 있으므로 여러 번 재시도한다.
for _ in $(seq 1 20); do
  if curl --fail --silent "http://127.0.0.1:${PORT_FORWARD_PORT}/v3/api-docs/swagger-config" >/dev/null; then
    echo
    echo "[jenkins-check] 게이트웨이 Swagger 응답 확인 완료"
    echo "Swagger URL: http://127.0.0.1:${PORT_FORWARD_PORT}/swagger-ui/index.html"
    exit 0
  fi
  sleep 2
done

# 끝까지 응답이 없으면 Jenkins 콘솔에서 실패가 바로 보이도록 종료 코드를 1로 반환한다.
echo "게이트웨이 Swagger 확인에 실패했습니다." >&2
echo "확인 경로: http://127.0.0.1:${PORT_FORWARD_PORT}/v3/api-docs/swagger-config" >&2
exit 1
