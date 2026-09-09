# 제품·기술 갭 기준선

권위는 exact-head와 그 head에서 끝난 검사다. 이전 커밋 숫자는 참고만 한다.

## 현재 exact-head

- 저장소: ContextualWisdomLab/litellm-patched-proxy
- 작업 브랜치: `docs/public-surface-metadata` (PR #2)
- 현 권위 head: `28f3dc64ffdc75ec5a944cd91a16d4690fd062e5`
- 직전 권위 head: `9dea8515aea58587c244d6c2827af1071d666e98`
- 이 문서가 적힌 시각: 2026-09-09
- 기반 이미지: `ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029`
- 게시 이미지: `ghcr.io/contextualwisdomlab/litellm-patched-proxy`

## 열린 PR

| PR | 제목 | 베이스 | mergeable | 검사 | 메모 |
| --- | --- | --- | --- | --- | --- |
| #2 | docs: align public LiteLLM proxy surface | develop | MERGEABLE | PASS: PR Validate run 34207909440 (`validate`, `sql-maintenance`, head `28f3dc6`). FAIL: CodeQL compatibility run 34207909411 (`actions`, `python`, handshake verdict enforced). FAIL: strix run 34207907041 (`Run Strix (quick)`). REVIEW_REQUIRED, Draft | 스택 바닥. 현 head `28f3dc6`이 org GHCR 경로를 포함. 로컬 3종 계약 통과. 외부 필수 검사를 우회하지 않음. |
| #4 | fix(ci): skip docs-only changes for Build Publish Scan, CodeQL, PR Validate | `docs/public-surface-metadata` | MERGEABLE | FAIL: CodeQL compatibility, validate, dependency-review | Draft. #2 위 스택. head `7a23ad`는 게이트 허용 이전. base가 `28f3dc6`으로 이동했으므로 후손 재검증 필요. force-push 없이 재실행. |
| #3 | chore(actions): remove redundant Copilot auto-merge workflow | develop | MERGEABLE | FAIL: noema-review, dependency-review, validate, trivy-fs, coverage-evidence | 워크플로 삭제만. 이미지 게이트는 develop 잔여 취약점에 묶인다. |
| #1 | ci: publish the patched proxy under ContextualWisdomLab | develop | MERGEABLE | PASS: validate. FAIL: noema-review, dependency-review, opencode-review, trivy-fs | GHCR 경로 delta는 현 #2 head `28f3dc6`이 승계. Dockerfile은 #2 ABI가 대체. 잔여 고유 delta 확인 전 close 금지. |

충돌(CONFLICTING)은 없다. force-push는 하지 않는다.

## 열린 이슈

| 이슈 | 범위 | exact-head | CRITICAL | HIGH | 출처 |
| --- | --- | --- | --- | --- | ---: |
| #5 | PR #2 | `4db52b8f11ffcec3dbfb75048fae30db602be51e` | 0 | 4 | validate job 101966376516; `9dea851` 게이트 허용 후 validate PASS |
| #6 | PR #4 | `7a23ad76198cf8946a6cd6c1e6dad64eaf56c6db` | 2 | 81 | #2 이미지 상속 |

`86704c3`는 HIGH 56. `c7e3bb1`은 Trivy 표가 없다. 빌드가 pip에서 먼저 죽었다. `4db52b8` 표가 interpreter HIGH 4건의 권위이고, `9dea851` validate가 그 게이트 통과의 권위다.

## 고객 체감 갭

게이트가 열린 이미지만 배포 후보다. 현 head `28f3dc6`의 PR Validate run `34207909440`은 `success`다. 남은 판매 품질 구멍은 두 가지다.

- 공개 패키지는 현 head에서 `ghcr.io/contextualwisdomlab/litellm-patched-proxy`로 맞췄다. 로컬 계약(`test_container_runtime_contract`, `check_container_runtime_contract`, `test_image_vulnerability_gate`)과 `actionlint`, `git diff --check`은 2026-09-09에 통과했다.
- python-3.13 / python-3.13-base `3.13.14-r0` HIGH 4건(`CVE-2026-11940`, `CVE-2026-15308`)은 이 digest가 올리지 못한다. 고정본 r2/r3는 `GLIBC_2.44`가 필요하다. 게이트는 그 HIGH만 허용하고 CRITICAL과 다른 패키지는 막는다. SARIF와 이슈 #5는 잔여분을 남긴다.

## 갭 행과 조치

| ID | 갭 | 증거 | 조치 | 상태 |
| --- | --- | --- | --- | --- |
| G1 | venv만 올리고 시스템 site-packages 구버전이 남음 | 과거 #5. `86704c3` venv assert는 starlette 1.3.1 등 통과 | 보안 핀을 venv와 시스템 interpreter에 같이 설치 | `86704c3` |
| G2 | cryptography 48.0.1 / tornado 6.5.6이 여전히 CVE | OSV: cryptography 50.0.1, tornado 6.5.8 | `cryptography==50.0.1`, `tornado==6.5.8` | `86704c3` |
| G3 | mcp 1.26.0 등 언어 패키지 CVE | 과거 #5 표 | mcp 1.30.0(2.x 아님) 등 핀 | `86704c3` |
| G4 | npm tar 7.5.11 CRITICAL CVE-2026-59873 | `86704c3` Trivy CRITICAL 0 | tar 7.5.22 등 tarball 교체 | `86704c3` |
| G5 | openssl / busybox HIGH, `apk add`만으로는 미갱신 | job 101966376516 표에 openssl/busybox 없음 | 해당 패키지만 `apk add --upgrade`. 전역 `apk upgrade` 금지 | `4db52b8`, 닫힘 |
| G6 | python-3.13 / python-3.13-base HIGH | job 101966376516: 4건. r3는 `GLIBC_2.44` 필요 | in-place 교체 금지. 게이트는 interpreter HIGH만 허용. 새 기반 digest가 올 때까지 잔여 | `9dea851`, 잔여 HIGH 허용, validate PASS |
| G7 | PR #4는 #2 이미지를 그대로 물려받음 | 이슈 #6 | #2 게이트가 닫힌 뒤 스택 후손 재검증. 리베이스/force-push 없음 | 대기 |
| G8 | PR #3/#1은 워크플로 변경인데 이미지 게이트에 막힘 | 2026-09-08 `gh pr list` FAIL 목록 | #2를 develop에 넣은 뒤 재검사. GHCR 경로 delta는 이번 커밋이 승계 | 부분 승계 |
| G9 | uv archive METADATA를 설치된 패키지로 집계 | job 101966376516 표에 uv archive 없음 | Prisma 복사 전에 `/root/.cache/uv`·`pip` 삭제. 복사 후 경로 부재 확인 | `c7e3bb1`/`4db52b8`, 닫힘 |
| G10 | CodeQL compatibility analysis (actions/python) FAIL | PR #2 run 34207909411 jobs 102005777033/102005777038, 단계 `Release runner or enforce current-head CodeQL verdict` 실패 | org `codeql-scan-dispatch`가 터미널 판정 후 같은 head를 다시 돌린다. 이 사이클은 대기하지 않음 | 핸드셰이크 대기 |
| G11 | 공개 GHCR가 개인 네임스페이스 | README·워크플로 `ghcr.io/seongho-bae/pre-secured-llm-proxy`; PR #1 잔여 delta | `ghcr.io/contextualwisdomlab/litellm-patched-proxy`와 계약 회귀 검사 | `28f3dc6`, 닫힘: 로컬 계약 통과와 PR Validate run 34207909440 `success` |
| G12 | strix `Run Strix (quick)` FAIL | PR #2 run 34207907041 job 102005654455, head `28f3dc6` | 리포트 아티팩트를 열어 근본 원인을 분류한 뒤 owner/supplier 경계면 ADR 제외, 이 저장소 결함이면 RED→fix→GREEN | 열림 |
| G13 | PR Actions에 `concurrency.group` 없음 | `.github/workflows`에 `concurrency` 0건, 2026-09-09 `grep` | `{workflow명}-{repository}-{PR번호}`로 같은 group 구형 실행만 `cancel-in-progress`, merge/release/deploy/migration은 취소 금지. `actionlint`로 검증 | 열림 |

## 이번 사이클이 하지 않은 일

- 전역 `apk upgrade` 재도입
- python-3.13 in-place 교체와 glibc를 같이 올리는 일
- LiteLLM overlay 커밋·SHA-256 변경
- mcp 2.x, pacote 22, cryptography 49.0.0
- python-3.13 in-place를 3.14로 올리는 일
- PR #4 리베이스(force-push 금지)
- PR #1/#3 close(유효 delta 확인 전 종결 금지)
- CI가 끝날 때까지 대기
- CodeQL 핸드셰이크를 로컬에서 우회하는 일
- PR #1 Dockerfile을 가져와 ABI 계약을 덮는 일
- 보호 브랜치 필수 review/Checks 우회 병합

## 다음 권위 측정

현 head `28f3dc6`의 PR Validate run `34207909440`(`success`)이 이미지·계약 권위다. 로컬 계약 3종과 `actionlint`, `git diff --check`은 2026-09-09에 통과했다. CodeQL compatibility는 org 디스패치 터미널 판정 뒤의 같은 head 재실행이 권위다. strix는 리포트 아티팩트 RCA 뒤의 같은 head 재실행이 권위다. interpreter 이외 HIGH/CRITICAL이 다시 뜨면 그 PkgPath가 다음 작업이다.
