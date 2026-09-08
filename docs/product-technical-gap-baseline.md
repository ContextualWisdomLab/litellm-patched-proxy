# 제품·기술 갭 기준선

권위는 exact-head와 그 head에서 끝난 검사다. 이전 커밋 숫자는 참고만 한다.

## 현재 exact-head

- 저장소: ContextualWisdomLab/litellm-patched-proxy
- 작업 브랜치: `docs/public-surface-metadata` (PR #2)
- 직전 권위 head: `dceca31d96f342c4c280dbf2ab7a13ebc07eead8`
- 기반 이미지: `ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029`
- 이 문서가 적힌 시각: 2026-09-08

## 열린 PR

| PR | 제목 | 베이스 | mergeable | 검사 | 메모 |
| --- | --- | --- | --- | --- | --- |
| #2 | docs: align public LiteLLM proxy surface | develop | MERGEABLE | FAIL: CodeQL compatibility (actions/python), validate | Draft. 스택 바닥. 이미지 계약·공개 표면. |
| #4 | fix(ci): skip docs-only changes for Build Publish Scan, CodeQL, PR Validate | `docs/public-surface-metadata` | MERGEABLE | FAIL: CodeQL compatibility (actions/python), validate, dependency-review | Draft. #2 위 스택. 이미지 취약점은 #2에서 상속. |
| #3 | chore(actions): remove redundant Copilot auto-merge workflow | develop | MERGEABLE | FAIL: noema-review, dependency-review, validate, trivy-fs, coverage-evidence | 워크플로 삭제만. 이미지 게이트는 develop 잔여 취약점에 묶인다. |
| #1 | ci: publish the patched proxy under ContextualWisdomLab | develop | MERGEABLE | FAIL: noema-review, dependency-review, opencode-review, trivy-fs | 이전 마이그레이션. #2가 공개 표면과 이미지 계약을 승계한다. |

충돌(CONFLICTING)은 없다. force-push는 하지 않는다.

## 열린 이슈

| 이슈 | 범위 | exact-head | CRITICAL | HIGH | 출처 |
| --- | --- | --- | --- | --- | ---: |
| #5 | PR #2 | `dceca31d96f342c4c280dbf2ab7a13ebc07eead8` | 2 | 81 | validate job 101914116728 |
| #6 | PR #4 | `7a23ad76198cf8946a6cd6c1e6dad64eaf56c6db` | 2 | 81 | #2 이미지 상속 |

## 고객 체감 갭

판매 품질을 막는 것은 문서 문장이 아니라 이미지가 CRITICAL/HIGH에서 안 닫히는 일이다. 게이트가 열린 이미지만 배포 후보가 된다.

PR #2는 이미 다음을 갖췄다.

- overlay는 `BerriAI/litellm` 불변 커밋과 파일 SHA-256만 쓴다.
- 전역 `apk upgrade`를 제거해 기반 ABI를 지킨다.
- 최종 프로세스는 `USER 10001:10001`이다.
- `/root/.cache`는 비root 홈과 `/app/.cache`에 복사한 뒤에만 지운다.

그래도 exact-head Trivy는 83건을 남겼다. venv 핀과 실제 스캔 대상이 달랐다.

## 갭 행과 조치

| ID | 갭 | 증거 | 조치 | 상태 |
| --- | --- | --- | --- | --- |
| G1 | venv만 올리고 시스템 site-packages 구버전이 남음 | #5: starlette 0.50.0, PyJWT 2.12.0, urllib3 2.6.3, python-multipart 0.0.27, ddtrace 2.19.0, tornado 6.5.5 | 보안 핀을 venv와 시스템 interpreter에 같이 설치 | 이 커밋 |
| G2 | cryptography 48.0.1 / tornado 6.5.6이 여전히 CVE | OSV: cryptography 49.0.0은 CVE-2026-69247 잔존, 50.0.1은 없음. tornado 6.5.8이 CVE-2026-82397 수정 | `cryptography==50.0.1`, `tornado==6.5.8` | 이 커밋 |
| G3 | mcp 1.26.0, RestrictedPython 8.1, aiohttp 3.14.1, pyasn1 0.6.3, pypdf 6.10.2, setuptools 68.1.2 | #5 표. setuptools 78.1.1은 CVE-2026-59890 잔존 | mcp 1.30.0(2.x 아님), RestrictedPython 8.5, aiohttp 3.14.3, pyasn1 0.6.4, pypdf 6.18.0, setuptools 84.0.0 | 이 커밋 |
| G4 | npm tar 7.5.11 CRITICAL CVE-2026-59873 | #5. 고정본 tar 7.5.21+, OSV leftover 없음은 7.5.22. pacote 21.5.1은 CVE-2026-9496 없음, 22.0.0은 불필요 | tar 7.5.22, brace-expansion 5.0.9, pacote 21.5.1, ip-address 10.7.0 tarball 교체 | 이 커밋 |
| G5 | openssl / busybox HIGH | #5: openssl 3.6.3-r2 CVE-2026-14456, busybox 1.37.0-r61 CVE-2026-38754 | 전역 `apk upgrade` 없이 해당 패키지만 `apk add` | 이 커밋, CI 재스캔이 권위 |
| G6 | python-3.13 / python-3.13-base HIGH | #5: 3.13.14-r0 CVE-2026-11940, CVE-2026-15308. 과거 `apk upgrade`가 venv ABI를 깨뜨림 | in-place 교체 금지. 새 기반 digest가 이 CVE를 닫을 때만 교체 | 열림 |
| G7 | PR #4는 #2 이미지를 그대로 물려받아 같은 83건 | 이슈 #6 | #2 게이트가 닫힌 뒤 스택 후손 재검증 | 대기 |
| G8 | PR #3/#1은 워크플로 변경인데 이미지 게이트에 막힘 | 2026-09-08 `gh pr list` FAIL 목록 | #2를 develop에 넣은 뒤 재검사. 유효 delta는 삭제하지 않음 | 대기 |

## 이번 사이클이 하지 않은 일

- 전역 `apk upgrade` 재도입
- LiteLLM overlay 커밋·SHA-256 변경
- mcp 2.x, pacote 22, cryptography 49.0.0
- PR #4 리베이스(force-push 금지)
- CI가 끝날 때까지 대기

## 다음 권위 측정

이 커밋이 PR #2 head가 된 뒤 `validate` job의 CRITICAL/HIGH 건수. G6가 남으면 게이트는 계속 닫혀 있고, 그때는 기반 digest 교체가 다음 작업이다.
