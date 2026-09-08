# 변경 이력

## 2026-09-08 KST - interpreter HIGH만 이미지 게이트에서 허용

### 장애 근거

- PR #2 head `4db52b8f11ffcec3dbfb75048fae30db602be51e`의 `validate` job `101966376516`(run `34196850535`)은 이미지를 빌드했다. 게이트는 HIGH 4건에서 닫혔다. CRITICAL은 0건이다.
- 남은 패키지는 `python-3.13`과 `python-3.13-base` `3.13.14-r0`다. `CVE-2026-11940`(고정본 `3.13.14-r2`), `CVE-2026-15308`(고정본 `3.13.14-r3`).
- openssl/busybox `--upgrade`와 uv 캐시 삭제는 이 표에서 빠졌다. python-3.13 in-place 교체는 이 digest에서 `GLIBC_2.44`가 없어 다시 넣지 않는다.

### 변경 사항

- 이미지 게이트는 `python-3.13`/`python-3.13-base`의 HIGH만 허용한다. 같은 패키지의 CRITICAL과 다른 패키지 HIGH/CRITICAL은 그대로 막는다.
- SARIF 업로드는 그대로 두어 interpreter HIGH가 보안 탭에 남는다. 이슈 #5도 잔여분 추적용으로 연다.
- `scripts/gate_image_vulnerabilities.sh`를 PR Validate와 Build Publish Scan이 같이 쓴다. job `101966376516` 표 fixture로 로컬에서 검증한다.

### 검증

- `sh scripts/test_container_runtime_contract.sh`
- `sh scripts/check_container_runtime_contract.sh Dockerfile`
- `sh scripts/test_image_vulnerability_gate.sh`
- 다음 `validate` job이 권위 있는 통과/실패다. 로컬에서 기반 이미지를 다시 빌드하지 않았다.

## 2026-09-08 KST - python-3.13 in-place 교체 철회

### 장애 근거

- PR #2 head `c7e3bb1273ca606b5cf3be9d20fc6282843bb101`의 `validate` job `101963192386`(run `34195821692`)이 이미지 빌드에서 실패했다. Trivy 숫자까지 가지 못했다.
- `apk add --upgrade python-3.13 python-3.13-base`가 3.13.14-r3를 끌어왔고, 그 바이너리가 `GLIBC_2.44`를 요구한다. 이 기반 digest의 `/usr/lib/libm.so.6`에는 그 심볼이 없다.
- 실패 지점은 `/usr/bin/python3 -m pip`다. 시스템 interpreter가 깨지면 venv 핀도 설치되지 않는다.

### 변경 사항

- openssl, libcrypto3, libssl3, busybox만 `--upgrade`한다. python-3.13과 python-3.13-base는 이 digest에 그대로 둔다.
- 런타임 계약이 `apk add --upgrade` 줄에 python-3.13이 있으면 거절한다. 연속 줄 fixture로 재도입을 막는다.
- uv 캐시 삭제는 그대로 둔다. interpreter HIGH는 검토된 새 기반 digest가 오기 전까지 남는다.

### 검증

- `sh scripts/test_container_runtime_contract.sh`
- `sh scripts/check_container_runtime_contract.sh Dockerfile`
- 이미지 Trivy 게이트는 이 head의 CI가 권위 있는 숫자다. 로컬에서 기반 이미지를 다시 빌드하지 않았다.

## 2026-09-08 KST - uv 캐시 잔여분과 OS 패키지 개정

### 장애 근거

- PR #2 head `86704c3d7dcb18f958f421b5e7ea42d139ec343a`의 `validate` job `101950841606`(run `34191673554`)이 Trivy HIGH 56건으로 게이트를 닫았다. CRITICAL은 0건이다. 이슈 #5가 이 exact-head 표를 보존한다.
- Python HIGH 48건의 `PkgPath`는 venv가 아니라 `app/.cache/uv/archive-v0/.../METADATA`와 `home/litellm/.cache/uv/archive-v0/.../METADATA`다. Prisma 캐시를 지키려 `/root/.cache`를 통째로 복사하면서 기반 이미지 uv 휠 보관함이 따라왔다.
- OS HIGH 8건은 `apk add`만으로는 이미 설치된 패키지를 올리지 못한 결과다. openssl/libcrypto3/libssl3 `3.6.3-r2`(고정본 `3.6.3-r5`), busybox `1.37.0-r61`(고정본 `1.38.0-r0`), python-3.13/python-3.13-base `3.13.14-r0`(고정본 `3.13.14-r2`/`3.13.14-r3`).

### 변경 사항

- Prisma 캐시를 복사하기 전에 `/root/.cache/uv`와 `/root/.cache/pip`를 지운다. 복사 뒤에는 `/app/.cache/uv`와 `/home/litellm/.cache/uv`가 없는지를 빌드에서 확인한다.
- 전역 `apk upgrade`는 쓰지 않는다. openssl, libcrypto3, libssl3, busybox, python-3.13, python-3.13-base만 `apk add --upgrade`한다. python major.minor는 3.13이어야 한다.
- 런타임 계약 스크립트가 uv 캐시 삭제를 검사하고, 빠지면 fixture가 거절한다.

### 검증

- `sh scripts/test_container_runtime_contract.sh`
- `sh scripts/check_container_runtime_contract.sh Dockerfile`
- 이미지 Trivy 게이트는 이 head의 CI가 권위 있는 숫자다. 로컬에서 기반 이미지를 다시 빌드하지 않았다.

## 2026-09-08 KST - PR #2 exact-head Trivy HIGH/CRITICAL 잔여분

### 장애 근거

- PR #2 head `dceca31d96f342c4c280dbf2ab7a13ebc07eead8`의 `validate` job `101914116728`이 Trivy CRITICAL 2건, HIGH 81건으로 게이트를 닫았다. 이슈 #5가 이 exact-head 표를 보존한다.
- venv에 `starlette==1.3.1`, `PyJWT==2.13.0`, `urllib3>=2.7.0`을 넣었는데도 Trivy는 `starlette 0.50.0`, `PyJWT 2.12.0`, `urllib3 2.6.3`을 보고했다. 프록시가 쓰지 않는 시스템 site-packages 복사본이 남았다.
- npm `tar 7.5.11`이 CRITICAL `CVE-2026-59873`의 출처다. `brace-expansion`, `pacote`, `ip-address`도 같은 이미지에 구버전이 남아 있었다.
- `cryptography==48.0.1`과 `tornado==6.5.6`은 각각 `CVE-2026-69247`/`CVE-2026-69249`, `CVE-2026-82397`이 열린 채였다.

### 변경 사항

- CVE가 비어 있는 버전으로 Python 패키지를 다시 고정한다. `cryptography==50.0.1`, `tornado==6.5.8`, `mcp==1.30.0`, `RestrictedPython==8.5`, `aiohttp==3.14.3`, `pyasn1==0.6.4`, `pypdf==6.18.0`, `setuptools==84.0.0`, `python-multipart==0.0.32`. mcp는 2.x가 아니라 1.30.0을 쓴다.
- 같은 보안 핀을 앱 venv와 시스템 interpreter 양쪽에 설치해 Trivy가 구버전 복사본을 다시 세지 않게 한다.
- npm `tar 7.5.22`, `brace-expansion 5.0.9`, `pacote 21.5.1`, `ip-address 10.7.0` tarball을 SHA-256 검증 후 기존 `node_modules` 트리에 덮어쓴다. pacote 22는 쓰지 않는다.
- `openssl`, `libcrypto3`, `libssl3`, `busybox`만 `apk add`로 다시 넣는다. 전역 `apk upgrade`와 `python-3.13` in-place 교체는 하지 않는다. 인터프리터 CVE는 검토된 새 기반 digest가 들어올 때까지 남는다.

### 검증

- `sh scripts/test_container_runtime_contract.sh`
- `sh scripts/check_container_runtime_contract.sh Dockerfile`
- OSV 조회: 위 Python/npm 핀은 해당 버전에서 leftover CVE가 없다. `cryptography 49.0.0`과 `setuptools 78.1.1`은 아직 CVE가 남아 최신 핀을 택했다.
- 이미지 Trivy 게이트는 이 head의 CI가 권위 있는 숫자다. 로컬에서 기반 이미지를 다시 빌드하지 않았다.

## 2026-07-17 KST - LiteLLM 백그라운드 상태 점검 부하 완화

### 장애 근거

- 2026-07-16 16:15:54 UTC에 개발 게이트웨이 로컬 readiness가 1.382초까지 지연됐습니다.
- 같은 주기의 109개 모델 점검 뒤 Azure 40건과 Vertex AI 4건이 실패했고, `aiohttp` 세션 미정리 로그 39건이 동시에 발생했습니다.
- `LiteLLM_HealthCheckTable`은 454,744행, 약 217MB까지 증가했습니다. 최신 상태 조회는 복합 인덱스 없이 전체 이력을 읽고 정렬했습니다.

### 변경 사항

- 직전 이미지 digest `sha256:e170bb797c29f1a59076f91b526bbe63ae032046a775526f94701a8eb9fa3114`에는 동시성 및 관측성 수정만 들어가고, `1.84.10` wheel에 없는 DB 최신 상태 조회와 Prisma 복합 인덱스 선언은 overlay되지 않은 것을 확인했습니다. 불변 LiteLLM 커밋 `fce13be05e620bea3e4ba38139c0e878b0842cbe`의 `proxy/utils.py`와 `proxy/schema.prisma`를 추가로 검증·설치해 변경 이력과 실제 이미지 내용을 일치시켰습니다. 동률 시에는 실제 기본키 `health_check_id DESC`로 결정적으로 정렬합니다.
- 공식 LiteLLM 기반 이미지와 Python 패키지를 모두 `1.84.10`으로 맞췄습니다. 기반 이미지는 멀티아키텍처 인덱스 digest `sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029`로 고정해 빌드 시점에 따른 버전 변동을 제거하고 `CVE-2026-49468`을 해소했습니다.
- 설정이 없거나 `null`이면 백그라운드 상태 점검 동시성을 기본 10개로 제한합니다. 명시한 양의 정수 값은 그대로 사용합니다.
- 점검 주기 시작·완료, 모델 수, 설정된 동시성, 실제 최대 동시 실행 수, 실행 시간, 스레드 수와 RSS를 INFO 로그로 남깁니다.
- canonical upstream에서 가져오는 파일은 커밋 SHA와 파일별 SHA-256을 모두 검증한 뒤 설치합니다. 구조 검증기는 BuildKit 읽기 전용 bind mount로 빌드 단계에만 주입해 최종 이미지 레이어에 남기지 않습니다.
- overlay 파일은 같은 불변 커밋과 SHA-256을 유지하면서 canonical public
  supplier인 `BerriAI/litellm`에서 가져옵니다. 개인 fork raw URL의
  unauthenticated 404를 제거하고 PR 정적 계약으로 재도입을 차단합니다.
- 불변 기반 이미지의 기존 virtualenv와 새 시스템 Python/glibc가 어긋나던
  `apk upgrade` 경로를 제거했습니다. OS 패키지 수정은 실행 중 부분 업그레이드가
  아니라 검토된 새 기반 이미지 digest로 일괄 갱신하고, 이미지 빌드와 Trivy
  게이트를 다시 통과해야 합니다.
- 이미지 빌드가 끝나면 숫자 UID/GID `10001:10001`로 권한을 낮추고,
  상속된 Prisma 캐시는 비root 홈과 `/app/.cache`에 보존합니다. PR 검증은
  전역 `apk upgrade` 재도입과 UID 0인 최종 `USER`를 정적 계약과 회귀
  fixture로 거부합니다. `/root/.cache`는 두 비root 위치에 복사한 뒤에만
  삭제합니다.
- Trivy가 검출한 Python 의존성 7종과 `uv`, 중복 npm `sigstore` 설치본을 수정 버전으로 고정했습니다. 기반 이미지에 남아 있던 실행 불필요 UV 패키지 캐시를 제거하고, `python-multipart`의 `CVE-2026-53539` 수정 버전도 반영했습니다. npm 패키지는 기존 디렉터리를 비운 뒤 검증된 tarball로 교체하며 압축 해제 실패 시 빌드를 중단합니다.
- 최신 모델 상태 조회용 `(model_id, model_name, checked_at DESC, health_check_id DESC)` 인덱스, 보존 배치용 `(checked_at, health_check_id)` 인덱스와 5,000행 단위 정리 템플릿을 추가했습니다. 기본 사전 점검은 전체 테이블을 읽지 않는 카탈로그 추정치만 사용하고 정확한 보존 건수 조회는 비피크 승인용 주석 템플릿으로 분리했습니다. PostgreSQL 시스템 카탈로그로 접근 방식·키 순서·정렬·NULL 순서를 구조적으로 확인해 INVALID 또는 오정의 인덱스만 온라인으로 교체합니다. PR 검증에서는 재실행 시 기존 인덱스가 유지되고 오정의 인덱스만 교체되는지 PostgreSQL 16으로 확인하며, 삭제문은 승인 전 실행되지 않도록 주석 처리했습니다.
- 비어 있던 CodeQL 행렬에 GitHub Actions 분석 대상을 지정해 job 0개 즉시 실패를 수정했습니다.
- 저장소 ruleset이 요구하지만 없었던 OSSF Scorecard 검사를 `develop` PR과 push에 추가하고 SARIF를 code scanning에 제출합니다.
- `develop` 갱신으로 PR merge SHA가 바뀌어도 수동 PR 검증에서 SQL·Trivy·CodeQL 결과를 동일한 head SHA에 귀속시킬 수 있도록 CodeQL Actions 분석 job을 추가했습니다.
- PR 검증과 `develop` 이미지 발행의 Trivy SARIF category를 `trivy-image`로 통일했습니다. 기본 브랜치와 PR의 분석 구성 키 불일치로 Trivy 체크가 `NEUTRAL`이 되던 문제를 제거하고, 취약점 0건인 SARIF는 가짜 note alert 없이 빈 결과로 보존합니다. 실제 차단은 별도의 JSON CRITICAL/HIGH gate가 담당합니다.
- `develop` push에서만 생성되어 PR과 비교할 수 없던 Scorecard `supply-chain/branch-protection` SARIF run은 업로드 대상에서 제외합니다. 브랜치 보호는 저장소와 조직 ruleset으로 계속 강제하고, PR과 push 모두에서 생성되는 `local` 및 `online-scm` Scorecard 결과는 유지합니다.
- Chainguard APK 저장소의 일시적인 패키지 다운로드 거부로 빌드가 실패하지 않도록 add/upgrade를 최대 3회 제한 재시도합니다.

### 검증 및 배포

- 소스 문법 검사와 diff 검사는 통과했습니다.
- 로컬 컨테이너 빌드는 기반 이미지 다운로드 중 로컬 저장소 공간 부족으로 중단됐습니다. 운영 호스트에는 영향을 주지 않았으며, GitHub Actions PR 빌드 결과로 검증합니다.
- 배포는 개발 게이트웨이에서 먼저 확인한 뒤 운영 노드를 한 대씩 교체하고 각 노드의 readiness, Prisma PID/포트, DB 풀 및 상태 점검 로그를 확인합니다.

### 롤백

- 새 이미지에서 readiness 또는 모델 호출 회귀가 확인되면 직전 배포 이미지 태그와 digest로 되돌립니다.
- 이미지만 롤백할 때는 DB 복합 인덱스 두 개를 유지합니다. 스키마 변경도 롤백해야 하면 `DROP INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_latest_model_idx"`와 `DROP INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_retention_idx"`를 각각 psql 자동 커밋으로 실행합니다.
- 보존 정리는 자동 실행하지 않습니다. 승인된 기간과 배치 수를 확인한 뒤 별도 유지보수 창에서만 수행합니다.
