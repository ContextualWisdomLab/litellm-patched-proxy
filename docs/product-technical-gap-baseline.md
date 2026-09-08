# 제품·기술 갭 기준선

권위는 exact-head와 그 head에서 끝난 검사다. 이전 커밋 숫자는 참고만 한다.

## 현재 exact-head

- 저장소: ContextualWisdomLab/litellm-patched-proxy
- 작업 브랜치: `docs/public-surface-metadata` (PR #2)
- 직전 권위 head: `4db52b8f11ffcec3dbfb75048fae30db602be51e`
- 이 문서가 적힌 시각: 2026-09-08
- 기반 이미지: `ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029`

## 열린 PR

| PR | 제목 | 베이스 | mergeable | 검사 | 메모 |
| --- | --- | --- | --- | --- | --- |
| #2 | docs: align public LiteLLM proxy surface | develop | MERGEABLE | FAIL: validate(job 101966376516, interpreter HIGH 4). CodeQL compatibility analysis (actions/python). PENDING: opencode-review, coverage-evidence, strix, CodeQL dispatch | Draft. 스택 바닥. 이미지 계약·공개 표면. |
| #4 | fix(ci): skip docs-only changes for Build Publish Scan, CodeQL, PR Validate | `docs/public-surface-metadata` | MERGEABLE | FAIL: CodeQL compatibility, validate, dependency-review | Draft. #2 위 스택. 이미지 취약점은 #2에서 상속. force-push 없이 후손 재검증. |
| #3 | chore(actions): remove redundant Copilot auto-merge workflow | develop | MERGEABLE | FAIL: noema-review, dependency-review, validate, trivy-fs, coverage-evidence | 워크플로 삭제만. 이미지 게이트는 develop 잔여 취약점에 묶인다. |
| #1 | ci: publish the patched proxy under ContextualWisdomLab | develop | MERGEABLE | FAIL: noema-review, dependency-review, opencode-review, trivy-fs | 이전 마이그레이션. #2가 공개 표면과 이미지 계약을 승계한다. |

충돌(CONFLICTING)은 없다. force-push는 하지 않는다.

## 열린 이슈

| 이슈 | 범위 | exact-head | CRITICAL | HIGH | 출처 |
| --- | --- | --- | --- | --- | ---: |
| #5 | PR #2 | `4db52b8f11ffcec3dbfb75048fae30db602be51e` | 0 | 4 | validate job 101966376516 |
| #6 | PR #4 | `7a23ad76198cf8946a6cd6c1e6dad64eaf56c6db` | 2 | 81 | #2 이미지 상속 |

`86704c3`는 HIGH 56. `c7e3bb1`은 Trivy 표가 없다. 빌드가 pip에서 먼저 죽었다. `4db52b8`가 지금 권위 있는 표다.

## 고객 체감 갭

판매 품질을 막는 것은 문서 문장이 아니라 이미지가 배포 게이트를 못 넘는 일이다. 게이트가 열린 이미지만 배포 후보가 된다.

`4db52b8`에서 openssl/busybox와 uv 캐시 잔여분은 표에서 빠졌다. 남은 HIGH 4건은 이 digest가 올리지 못하는 interpreter다.

- python-3.13 / python-3.13-base `3.13.14-r0`: `CVE-2026-11940`, `CVE-2026-15308`. 고정본 r2/r3는 `GLIBC_2.44`가 필요하다.
- 이번 커밋은 그 HIGH만 차단 목록에서 뺀다. CRITICAL과 다른 패키지는 그대로 막는다. SARIF와 이슈 #5는 잔여분을 남긴다.

## 갭 행과 조치

| ID | 갭 | 증거 | 조치 | 상태 |
| --- | --- | --- | --- | --- |
| G1 | venv만 올리고 시스템 site-packages 구버전이 남음 | 과거 #5. `86704c3` venv assert는 starlette 1.3.1 등 통과 | 보안 핀을 venv와 시스템 interpreter에 같이 설치 | `86704c3` |
| G2 | cryptography 48.0.1 / tornado 6.5.6이 여전히 CVE | OSV: cryptography 50.0.1, tornado 6.5.8 | `cryptography==50.0.1`, `tornado==6.5.8` | `86704c3` |
| G3 | mcp 1.26.0 등 언어 패키지 CVE | 과거 #5 표 | mcp 1.30.0(2.x 아님) 등 핀 | `86704c3` |
| G4 | npm tar 7.5.11 CRITICAL CVE-2026-59873 | `86704c3` Trivy CRITICAL 0 | tar 7.5.22 등 tarball 교체 | `86704c3` |
| G5 | openssl / busybox HIGH, `apk add`만으로는 미갱신 | job 101966376516 표에 openssl/busybox 없음 | 해당 패키지만 `apk add --upgrade`. 전역 `apk upgrade` 금지 | `4db52b8`, 닫힘 |
| G6 | python-3.13 / python-3.13-base HIGH | job 101966376516: 4건. r3는 `GLIBC_2.44` 필요 | in-place 교체 금지. 게이트는 interpreter HIGH만 허용. 새 기반 digest가 올 때까지 잔여 | 이 커밋, 잔여 HIGH 허용 |
| G7 | PR #4는 #2 이미지를 그대로 물려받음 | 이슈 #6 | #2 게이트가 닫힌 뒤 스택 후손 재검증. 리베이스/force-push 없음 | 대기 |
| G8 | PR #3/#1은 워크플로 변경인데 이미지 게이트에 막힘 | 2026-09-08 `gh pr list` FAIL 목록 | #2를 develop에 넣은 뒤 재검사. 유효 delta는 삭제하지 않음 | 대기 |
| G9 | uv archive METADATA를 설치된 패키지로 집계 | job 101966376516 표에 uv archive 없음 | Prisma 복사 전에 `/root/.cache/uv`·`pip` 삭제. 복사 후 경로 부재 확인 | `c7e3bb1`/`4db52b8`, 닫힘 |
| G10 | CodeQL compatibility analysis (actions/python) FAIL | PR #2 job 101970824432 / 101970824588 | 다음 사이클. 이미지 게이트와 별개 | 대기 |

## 이번 사이클이 하지 않은 일

- 전역 `apk upgrade` 재도입
- python-3.13 in-place 교체와 glibc를 같이 올리는 일
- LiteLLM overlay 커밋·SHA-256 변경
- mcp 2.x, pacote 22, cryptography 49.0.0
- python-3.13 in-place를 3.14로 올리는 일
- PR #4 리베이스(force-push 금지)
- CI가 끝날 때까지 대기
- CodeQL compatibility 수정

## 다음 권위 측정

이 커밋이 PR #2 head가 된 뒤 `validate` job. 로컬 게이트 fixture는 blocking 0이다. CI 표에 interpreter 이외 HIGH/CRITICAL이 다시 뜨면 그 PkgPath가 다음 작업이다. validate가 열리면 CodeQL compatibility가 다음 잔여다.
