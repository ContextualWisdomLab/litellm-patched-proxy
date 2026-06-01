## 2023-10-27 - Dockerfile Layer Optimization
**Learning:** Using `uv pip install` instead of `pip install` inside Dockerfile significantly reduces image build time by speeding up python package installation.
**Action:** When installing multiple python packages in Dockerfile, prefer using `uv pip install` if `uv` is available, as it leverages parallel downloads and dependency resolution. Remember to use `--system` and `--no-cache` to ensure system installation and avoid cache bloat.
