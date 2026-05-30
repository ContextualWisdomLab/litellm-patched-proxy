## 2024-05-30 - Optimize Dockerfile
**Learning:** In Alpine based images, `apk add --no-cache` will fetch the index during install, making `apk update` unnecessary and increasing layer size/build time if cached. Grouping python packages into a single pip installation command reduces overhead.
**Action:** Always combine pip install commands and omit `apk update` when using `apk add --no-cache`.
