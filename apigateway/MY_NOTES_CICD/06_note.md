# image-registry-cicd.yml과 apigateway-registry.yml는 나눈 이유

대체로 **맞게 이해한 거야.**

`main-gateway` 브랜치의 `.github/workflows` 아래에는 

`apigateway-registry.yml`과 `image-registry-cicd.yml` 두 파일이 있고, 

특히 `apigateway-registry.yml`은 주석과 설정 자체가 **“apigateway 전용”**이라고 못 박고 있어. 

---

이 workflow는 
    
- `main-gateway` 브랜치에 push되고 
- `apigateway/**` 또는 해당 workflow 파일이 바뀌었을 때만 

실행되며, 

`./apigateway/Dockerfile`을 기준으로 이미지를 빌드해서 GHCR에 push하도록 되어 있다. ([GitHub][1])

---

조금 더 정확히 말하면, `main-gateway` 브랜치에는 두 가지 흐름이 같이 보여.

- 하나는 방금 말한 **apigateway 전용 workflow**이고,
- 다른 하나는 `config`, `discovery`, `apigateway`를 한꺼번에 대상으로 하는 
**공용 image-registry-cicd**야. 

`main` 브랜치의 `image-registry-cicd.yml`은 
각 모듈 폴더의 `scripts/build_jar.sh`와 `scripts/build_docker.sh`를 호출하는 구조인데, 
`main-gateway` 브랜치의 같은 이름 workflow는 그 부분이 주석 처리되고 
`docker/build-push-action` 중심으로 바뀌어 있어서, 
브랜치 안에서 CI 방식을 실험하거나 바꿔보는 흔적이 보인다. ([GitHub][2])

---

그래서 “왜 굳이 브랜치를 나눠서 했나?”에 대한 가장 그럴듯한 설명은 이거야.

## 첫째, **메인 브랜치를 깨뜨리지 않고 실험하려고**.

GitHub Actions workflow는 `.github/workflows/**`에 들어가고, 

조건이 맞으면 실제로 바로 실행된다. 

특히 `main` 브랜치 workflow는 `main` 또는 `master` push 시 자동 실행되도록 되어 있어서, 

여기서 바로 수정 실험을 하면 원치 않는 빌드/푸시가 발생할 수 있다. 

> 반면 `main-gateway`의 `apigateway-registry.yml`은
> `main-gateway` 브랜치 push에만 반응하도록 분리되어 있어서, 
> apigateway만 따로 검증하기 좋다. ([GitHub][3])

---

## 둘째, **범위를 줄여서 학습하기 위해서**.

처음부터 `config`, `discovery`, `apigateway` 세 모듈 전체를 CI에 걸면 

어디서 실패했는지 추적이 어려워져. 

그런데 `apigateway-registry.yml`은 아예 

- `context: ./apigateway`, 
- `file: ./apigateway/Dockerfile`로 

고정해서 apigateway 하나만 다룬다. 

즉, “workflow가 잘 도는가”, “Dockerfile이 맞는가”, “GHCR 로그인/푸시가 되는가”를 
가장 작은 단위로 확인하려는 의도로 보는 게 자연스럽다. ([GitHub][3])

---

## 셋째, **기존 방식과 새 방식을 비교하려고**.

`main`의 공용 workflow는 모듈별 스크립트를 재사용하는 구조이고, 

`main-gateway`의 공용 workflow는 

중간에 

- `Prepare image URI`, 
- `docker/build-push-action@v5` 

같은 직접 빌드 방식이 들어가 있으며 예전 스크립트 방식은 주석 처리돼 있다. 

이건 단순 추가라기보다, 

“스크립트 재사용형”에서 “Dockerfile 직접 빌드형”으로 바꿔보는 테스트 브랜치 성격이 강하다. ([GitHub][2])

---

즉 정리하면:

* **네 해석의 핵심은 맞다.**
* `main-gateway`는 **apigateway 관련 이미지 빌드/GHCR push를 따로 검증하려는 브랜치**로 보인다.
* 브랜치를 나눈 이유는 보통 **메인 보호, 자동 실행 범위 제한, 학습/실험 단순화** 때문이다. ([GitHub][3])

---

다만 하나는 분명히 구분해야 해.

`main-gateway`가 “오직 apigateway만 있는 브랜치”는 아니고, 그 안에는 여전히 3개 모듈용 `image-registry-cicd.yml`도 있다. 

그래서 더 정확한 표현은 **“apigateway 전용 workflow를 추가해서 

gateway부터 따로 떼어 검증한 브랜치”**에 가깝다. ([GitHub][1])