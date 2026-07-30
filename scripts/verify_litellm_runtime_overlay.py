#!/usr/bin/env python3
"""Verify that the runtime CLI imports the patched LiteLLM installation."""

from __future__ import annotations

from datetime import timedelta
from importlib.metadata import version
import inspect
import json
from pathlib import Path
import shutil
import sys


EXPECTED_VERSION = "1.84.10"
EXPECTED_VENV = Path("/app/.venv").resolve()
EXPECTED_CLI = EXPECTED_VENV / "bin/litellm"


def fail(message: str) -> None:
    raise SystemExit(f"runtime overlay verification failed: {message}")


def require_venv_path(path: str | Path, label: str) -> Path:
    resolved = Path(path).resolve()
    if not resolved.is_relative_to(EXPECTED_VENV):
        fail(f"{label} resolved outside {EXPECTED_VENV}: {resolved}")
    return resolved


def main() -> None:
    import litellm
    from litellm.caching import redis_cache
    from litellm.integrations.langfuse.langfuse_handler import LangFuseHandler
    from litellm.llms.custom_httpx import http_handler
    from litellm.router_strategy import lowest_latency

    interpreter = Path(sys.executable).absolute()
    if not interpreter.is_relative_to(EXPECTED_VENV):
        fail(f"Python interpreter resolved outside {EXPECTED_VENV}: {interpreter}")
    require_venv_path(litellm.__file__, "LiteLLM package")
    require_venv_path(redis_cache.__file__, "Redis cache module")
    require_venv_path(http_handler.__file__, "HTTP handler module")
    require_venv_path(lowest_latency.__file__, "lowest-latency module")

    cli = shutil.which("litellm")
    if cli is None or Path(cli).resolve() != EXPECTED_CLI:
        fail(f"litellm CLI resolved to {cli!r}, expected {EXPECTED_CLI}")

    installed_version = version("litellm")
    if installed_version != EXPECTED_VERSION:
        fail(f"LiteLLM version is {installed_version}, expected {EXPECTED_VERSION}")

    encoded = json.dumps(
        {"latency": [timedelta(seconds=1, microseconds=250_000)]},
        default=redis_cache._json_default,
    )
    if json.loads(encoded) != {"latency": [1.25]}:
        fail(f"timedelta serialization returned {encoded}")

    redis_source = inspect.getsource(redis_cache.RedisCache.async_set_cache)
    if "json.dumps(value, default=_json_default)" not in redis_source:
        fail("Redis async writer is missing the timedelta-safe JSON encoder")

    latency_source = inspect.getsource(
        lowest_latency.LowestLatencyLoggingHandler.async_log_success_event
    )
    required_latency_fragments = (
        "response_ms.total_seconds()",
        "final_value: float = response_seconds",
    )
    for fragment in required_latency_fragments:
        if fragment not in latency_source:
            fail(f"lowest-latency runtime is missing {fragment!r}")

    cleanup_source = inspect.getsource(http_handler.AsyncHTTPHandler.__del__)
    required_cleanup_fragments = (
        "_async_client_cleanup_tasks.add(task)",
        "task.add_done_callback(_discard_async_client_cleanup_task)",
    )
    for fragment in required_cleanup_fragments:
        if fragment not in cleanup_source:
            fail(f"HTTP client cleanup is missing {fragment!r}")

    if LangFuseHandler._dynamic_langfuse_credentials_are_passed(None):
        fail("missing Langfuse dynamic parameters must not imply credentials")

    print(
        "runtime overlay verified:",
        f"python={interpreter}",
        f"litellm={Path(litellm.__file__).resolve()}",
        f"cli={Path(cli).resolve()}",
    )


if __name__ == "__main__":
    main()
