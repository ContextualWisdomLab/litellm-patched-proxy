# 제품·기술 갭 기준선

권위는 exact-head와 그 head에서 끝난 검사다. 이전 커밋 숫자는 참고만 한다.

## 현재 exact-head

- 저장소: ContextualWisdomLab/litellm-patched-proxy
- 작업 브랜치: `docs/public-surface-metadata` (PR #2)
- 직전 권위 head: `c7e3bb1273ca606b5cf3be9d20fc6282843bb101`
- 이 문서가 적힌 시각: 2026-09-08
- 기반 이미지: `ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029`

## 열린 PR

| PR | 제목 | 베이스 | mergeable | 검사 | 메모 |
| --- | --- | --- | --- | --- | --- |
| #2 | docs: align public LiteLLM proxy surface | develop | MERGEABLE | FAIL: validate 빌드 깨짐(job 101963192386). 나머지 required는 queued | Draft. 스택 바닥. 이미지 계약·공개 표면. |
| #4 | fix(ci): skip docs-only changes for Build Publish Scan, CodeQL, PR Validate | `docs/public-surface-metadata` | MERGEABLE | FAIL: CodeQL compatibility, validate, dependency-review | Draft. #2 위 스택. 이미지 취약점은 #2에서 상속. force-push 없이 후손 재검증. |
| #3 | chore(actions): remove redundant Copilot auto-merge workflow | develop | MERGEABLE | FAIL: noema-review, dependency-review, validate, trivy-fs, coverage-evidence | 워크플로 삭제만. 이미지 게이트는 develop 잔여 취약점에 묶인다. |
| #1 | ci: publish the patched proxy under ContextualWisdomLab | develop | MERGEABLE | FAIL: noema-review, dependency-review, opencode-review, trivy-fs | 이전 마이그레이션. #2가 공개 표면과 이미지 계약을 승계한다. |

충돌(CONFLICTING)은 없다. force-push는 하지 않는다.

## 열린 이슈

| 이슈 | 범위 | exact-head | CRITICAL | HIGH | 출처 |
| --- | --- | --- | --- | --- | ---: |
| #5 | PR #2 | `86704c3d7dcb18f958f421b5e7ea42d139ec343a` | 0 | 56 | validate job 101950841606 |
| #6 | PR #4 | `7a23ad76198cf8946a6cd6c1e6dad64eaf56c6db` | 2 | 81 | #2 이미지 상속 |

`c7e3bb1`은 Trivy 표가 없다. 빌드가 pip에서 먼저 죽었다.

## 고객 체감 갭

판매 품질을 막는 것은 문서 문장이 아니라 이미지가 CRITICAL/HIGH에서 안 닫히는 일이다. 게이트가 열린 이미지만 배포 후보가 된다.

`86704c3`에서 venv·npm 핀은 들어갔고 CRITICAL tar는 사라졌다. `c7e3bb1`은 uv 캐시를 지우고 python-3.13을 `--upgrade`했다가 `GLIBC_2.44` 부재로 빌드가 죽었다. 이번 커밋은 interpreter를 이 digest에 묶고 openssl/busybox만 올린다.

- Python 48건: Prisma 보존을 위해 `/root/.cache`를 통째로 복사하면서 uv `archive-v0` METADATA가 `/app/.cache`와 `/home/litellm/.cache`에 남음. `c7e3bb1`에서 복사 전 삭제. 다음 Trivy가 권위.
- OS: openssl `3.6.3-r2` / busybox `1.37.0-r61`는 `--upgrade` 유지. python-3.13 `3.13.14-r0`는 이 digest의 glibc에 맞춰 남긴다. 고정본 `3.13.14-r3`는 `GLIBC_2.44`가 필요하다.

## 갭 행과 조치

| ID | 갭 | 증거 | 조치 | 상태 |
| --- | --- | --- | --- | --- |
| G1 | venv만 올리고 시스템 site-packages 구버전이 남음 | 과거 #5. `86704c3` venv assert는 starlette 1.3.1 등 통과 | 보안 핀을 venv와 시스템 interpreter에 같이 설치 | `86704c3` |
| G2 | cryptography 48.0.1 / tornado 6.5.6이 여전히 CVE | OSV: cryptography 50.0.1, tornado 6.5.8 | `cryptography==50.0.1`, `tornado==6.5.8` | `86704c3` |
| G3 | mcp 1.26.0 등 언어 패키지 CVE | 과거 #5 표 | mcp 1.30.0(2.x 아님) 등 핀 | `86704c3` |
| G4 | npm tar 7.5.11 CRITICAL CVE-2026-59873 | `86704c3` Trivy CRITICAL 0 | tar 7.5.22 등 tarball 교체 | `86704c3` |
| G5 | openssl / busybox HIGH, `apk add`만으로는 미갱신 | job 101950841606: 3.6.3-r2 / 1.37.0-r61, 고정본 3.6.3-r5 / 1.38.0-r0 | 해당 패키지만 `apk add --upgrade`. 전역 `apk upgrade` 금지 | 이 커밋, CI 재스캔이 권위 |
| G6 | python-3.13 / python-3.13-base HIGH | job 101963192386: 3.13.14-r3가 `GLIBC_2.44`를 요구하고 `/usr/lib/libm.so.6`에 없음 | 이 digest에서는 in-place 교체 금지. 계약 스크립트가 `apk add --upgrade`+python-3.13을 거절. 새 기반 digest가 올 때까지 잔여 | 이 커밋, 잔여 HIGH 허용 |
| G7 | PR #4는 #2 이미지를 그대로 물려받음 | 이슈 #6 | #2 게이트가 닫힌 뒤 스택 후손 재검증. 리베이스/force-push 없음 | 대기 |
| G8 | PR #3/#1은 워크플로 변경인데 이미지 게이트에 막힘 | 2026-09-08 `gh pr list` FAIL 목록 | #2를 develop에 넣은 뒤 재검사. 유효 delta는 삭제하지 않음 | 대기 |
| G9 | uv archive METADATA를 설치된 패키지로 집계 | job 101950841606 PkgPath `app/.cache/uv/archive-v0`·`home/litellm/.cache/uv/archive-v0` 48건 | Prisma 복사 전에 `/root/.cache/uv`·`pip` 삭제. 복사 후 경로 부재 확인 | `c7e3bb1`, 다음 Trivy가 권위 |

## 이번 사이클이 하지 않은 일

- 전역 `apk upgrade` 재도입
- glibc를 python-3.13과 같이 올려 r3를 살리는 일
- LiteLLM overlay 커밋·SHA-256 변경
- mcp 2.x, pacote 22, cryptography 49.0.0
- python-3.13 in-place를 3.14로 올리는 일
- PR #4 리베이스(force-push 금지)
- CI가 끝날 때까지 대기

## 다음 권위 측정

이 커밋이 PR #2 head가 된 뒤 `validate` job이 이미지를 빌드하는지, 그다음 Trivy CRITICAL/HIGH 건수. 빌드가 다시 죽으면 로그의 ImportError가 다음 작업이다. 0이면 게이트가 열리고, HIGH가 남으면 그 job JSON의 PkgPath가 다음 작업이다.
