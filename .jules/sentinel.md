## 2026-06-03 - [Fix] Update pip dependencies in Dockerfile
**Vulnerability:** Several high vulnerabilities found in OS-level Python packages (urllib3 vulnerabilities affecting `py3-pip`, `py3-pip-wheel`).
**Learning:** Even when upgrading base Python (`python-3.13`), its related `pip` dependencies shipped via OS-packages may still be vulnerable if they aren't explicitly listed in `apk upgrade`.
**Prevention:** Always ensure OS package upgrades include associated auxiliary packages like `py3-pip` and `py3-pip-wheel` to fully eliminate associated vulnerabilities.
