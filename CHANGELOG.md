# 변경 이력

## 2026-08-06 KST - Async HTTP destructor cleanup ownership

### 장애 근거

- 개발 게이트웨이는 `2026-08-05T15:14:31.435Z`에 `aiohttp`의 `Unclosed client session`을 기록했습니다. 같은 호스트에서는 이전 109개 모델 상태 점검 주기에 39건이 함께 발생한 이력이 있습니다.
- LiteLLM 1.84.10의 `AsyncHTTPHandler.__del__()`은 `close()` task를 생성한 뒤 강한 참조를 유지하지 않아 destructor 복귀 직후 task가 수집될 수 있습니다. 정확한 이번 session id와 생성 call stack은 기존 런타임 로그에 없으므로 단일 경고의 소유자를 과장하지 않습니다.
- LiteLLM fork PR #18은 cleanup task를 모듈 집합에 보관하고 완료 callback에서 제거하는 회귀 테스트를 거쳐 병합됐습니다. 이 이미지는 동일 수정을 1.84.10 소스에 적용한 immutable commit `978a3fbf108218487ed660d5be74b2758204430b`을 사용합니다.

### 변경 사항

- `llms/custom_httpx/http_handler.py`를 vendored overlay에 추가해 destructor cleanup task가 종료될 때까지 강한 참조를 유지합니다.
- 완료 callback은 task를 집합에서 제거하고 예외를 회수해 별도의 unhandled task 경고를 막습니다.
- Docker build는 파일 SHA-256과 AST 실행 순서인 create, retain, done callback 등록을 검증합니다.

### 검증 및 롤백

- 소스 회귀 테스트, Ruff, vendored source compile, overlay 구조 검증, 이미지 build와 in-image smoke를 수행합니다.
- 배포 전 런타임 변경은 없습니다. dev에 먼저 적용해 상태 점검 주기 여러 번과 `Unclosed client session` 재발 여부를 확인하며, 회귀 시 직전 immutable image digest로 복귀합니다.

## 2026-08-06 KST - Prisma OOM initiating query and reconnect preflight evidence

### 장애 근거

- 개발 게이트웨이는 background_health_checks=True, 300초 주기로 동작하지만 배포된 LiteLLM 1.83.7의 get_all_latest_health_checks()는 LiteLLM_HealthCheckTable 전체를 매 주기 읽고 Python에서 최신 행을 고릅니다.
- 2026-08-05T15:14Z 기준 이 테이블은 506,773행이고 최신 상태는 78개 모델뿐입니다. 배포 코드에는 복합 최신 상태 인덱스도 없습니다.
- 상태 변경 기록의 5분 주기와 일치하는 2026-08-04T19:07:33Z에 query-engine이 private anonymous RSS 약 7.0GiB까지 증가해 swap 없는 15GiB 호스트에서 global OOM으로 종료됐습니다. Langfuse 콜백 오류는 약 9초 먼저 기록됐지만 메모리 할당 원인으로 입증되지 않았고, Prisma reconnect와 PgCat session close는 OOM 뒤에 발생했습니다.

### 변경 사항

- DB-side distinct와 결정적 정렬, 최신 상태 복합 인덱스를 포함한 기존 overlay를 실제 이미지에 유지해 50만여 행의 반복 역직렬화를 제거합니다.
- 모든 destructive Prisma reconnect 직전에 trigger/exception type, trigger 및 lock 대기 경과시간, 연속 실패 수, 이전 query-engine PID/port/state/start time, RSS/VSZ, cgroup current/peak/OOM count와 전체 pool/wait histogram을 한 번 기록합니다.
- 진단은 추가 DB query를 실행하지 않고 query-engine local metrics와 procfs/cgroup만 200ms 제한으로 읽습니다. 진단 실패는 reconnect를 차단하지 않습니다.
- 구조 검증기는 진단 수집이 _run_reconnect_cycle()보다 앞에 있는지 AST로 확인합니다.

### 검증 및 롤백

- vendored Python source compile, overlay structure verification 및 diff 검사를 통과했습니다. PR 이미지 빌드와 Trivy CRITICAL/HIGH 0건 게이트가 추가 검증합니다.
- 배포 전까지 런타임과 DB는 변경하지 않습니다. dev에 먼저 immutable digest를 적용하고 readiness/liveliness, 실모델 호출, query-engine RSS, 5분 상태 점검 주기와 오류 창을 확인합니다.
- 회귀 시 직전 immutable image digest로 복귀합니다. 최신 상태 인덱스는 읽기 경로를 지원하므로 이미지 롤백과 독립적으로 유지하며, 제거가 필요하면 승인된 유지보수 창에서만 DROP INDEX CONCURRENTLY를 사용합니다.

## 2026-08-05 KST - Langfuse dynamic callback None guard

### 장애 근거

- 개발 게이트웨이에서 `2026-08-04T15:25:42.870856Z`에 Langfuse 성공 콜백이 `standard_callback_dynamic_params=None`을 처리하지 못해 `AttributeError: 'NoneType' object has no attribute 'get'`을 기록했습니다.
- 컨테이너와 Prisma query-engine은 연속 실행 중이었으므로 이 예외는 engine 재시작이나 DB reconnect의 후속 오류가 아닙니다.

### 변경 사항

- LiteLLM fork merge commit `3dc0fcfade4f1906af2f6ad8a08903e5867194ae`의 `integrations/langfuse/langfuse_handler.py`를 vendored overlay로 고정했습니다.
- dynamic callback parameter가 `None`이면 dynamic credential이 없는 것으로 처리해 global Langfuse logger 경로를 사용합니다.
- Docker build는 handler SHA-256, Optional 시그니처 및 명시적인 `None` guard를 검증합니다.
- 최신 Trivy DB가 추가로 탐지한 `aiohttp`, `cryptography`, `mcp`, `pyasn1`, `pypdf`, `brace-expansion`, `ip-address`, `tar`의 수정 가능 HIGH/CRITICAL 취약점을 고정 버전으로 갱신합니다. `cryptography 50`과 호환되는 `msal 1.37.0`을 함께 고정하고 `uv pip check`로 전체 Python 의존성 일관성을 검증합니다. npm tarball은 SHA-256을 검증한 뒤 중복 설치본 전체를 교체합니다.

### 검증 및 롤백

- 소스 PR의 회귀 테스트 2개, Ruff 및 Black 검사를 통과했습니다. 이미지에서는 hash, 구조 검증, Python compile, container build 및 callback smoke test를 다시 수행합니다.
- 배포 전까지 런타임 변경은 없습니다. 배포 후 callback 회귀 시 직전 immutable image digest로 노드별 롤백합니다.

## 2026-08-04 KST - Prisma spend transaction event-time diagnostics

### 장애 근거

- 개발 게이트웨이에서 `2026-08-04T12:45:57.228643Z`에 spend writer의 Prisma `P2028` transaction start 실패가 재발했습니다.
- transaction body timeout은 60초였지만 connection checkout은 기본 `max_wait=2s`를 유지했습니다. 설치된 런타임은 실패 시점의 exception class, checkout 경과 시간, query-engine 상태, pool counter 및 연속 실패 횟수를 남기지 않아 개별 `SELECT 1` 지연 원인을 분리할 수 없었습니다.
- `2026-08-04T19:07:33Z`에는 장시간 증가한 query-engine 메모리로 child process가 OOM 종료된 뒤 reconnect가 발생했습니다. 이 overlay는 메모리 증가 자체를 수정하지 않으며, 다음 재발 시 low-level failure branch와 event-time pool 상태를 입증하기 위한 진단 범위를 확장합니다.

### 변경 사항

- LiteLLM fork merge commit `4b5e57c14b12f427546afc0cc7c89a2caff8bc34`의 `proxy/utils.py`와 `proxy/db/db_spend_update_writer.py`를 vendored overlay로 고정했습니다.
- spend transaction 실패 시 기존 일반 오류보다 먼저 exception type, elapsed milliseconds, 연속 실패 상태, engine PID/port/state/start UTC, pool active/wait/busy/idle/open, opened/closed 및 wait histogram을 기록합니다.
- 연속 실패 횟수는 Redis-to-DB commit 전체가 성공한 뒤에만 초기화합니다. reconnect 조건과 동작은 변경하지 않습니다.
- Docker build는 두 파일의 SHA-256과 필수 관측성 토큰을 모두 검증합니다.

### 검증 및 롤백

- 소스 PR에서 관련 테스트 50개와 Ruff를 통과했습니다. 이미지에서는 hash, 구조 검증, Python compile, container build 및 smoke test를 다시 수행합니다.
- 배포 전까지 런타임 변경은 없습니다. 배포 후 회귀 시 직전 immutable image digest로 복귀하고 readiness/liveliness, engine continuity, effective pool, PgCat/PostgreSQL 오류 창을 재검증합니다.

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
- 포크에서 가져오는 파일은 커밋 SHA와 파일별 SHA-256을 모두 검증한 뒤 설치합니다. 구조 검증기는 BuildKit 읽기 전용 bind mount로 빌드 단계에만 주입해 최종 이미지 레이어에 남기지 않습니다.
- 부분 OS 업그레이드로 `pyexpat`와 `libexpat1`의 ABI가 어긋나던 경로를 제거하고, 설치된 OS 패키지를 의존성 단위로 함께 업그레이드합니다. APK 저장소 스냅샷 없이 사라질 수 있는 리비전을 강제하지 않고, 불변 기반 이미지에서 `apk upgrade` 후 Trivy 게이트로 수정 상태를 검증합니다.
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
