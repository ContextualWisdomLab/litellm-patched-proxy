#!/usr/bin/env python3
"""Verify that LiteLLM runtime imports use the patched installed package."""

from __future__ import annotations

from datetime import timedelta
import json
from pathlib import Path
import sys

import litellm
from litellm.caching import redis_cache
from litellm.router_strategy import lowest_latency


def fail(message: str) -> None:
    raise SystemExit(f"runtime overlay verification failed: {message}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: verify_litellm_runtime_overlay.py PACKAGE_ROOT")

    expected_root = Path(sys.argv[1]).resolve()
    imported_root = Path(litellm.__file__).resolve().parent
    if imported_root != expected_root:
        fail(f"imported {imported_root}, expected {expected_root}")
    if "site-packages" not in imported_root.parts or imported_root.name != "litellm":
        fail(f"runtime package is not an installed site-packages tree: {imported_root}")

    expected_modules = {
        "redis_cache": expected_root / "caching" / "redis_cache.py",
        "lowest_latency": expected_root / "router_strategy" / "lowest_latency.py",
    }
    actual_modules = {
        "redis_cache": Path(redis_cache.__file__).resolve(),
        "lowest_latency": Path(lowest_latency.__file__).resolve(),
    }
    for name, expected_path in expected_modules.items():
        if actual_modules[name] != expected_path:
            fail(f"{name} imported from {actual_modules[name]}, expected {expected_path}")

    encoded = json.dumps(
        {"latency": timedelta(milliseconds=1250)},
        default=redis_cache._json_default,
    )
    if json.loads(encoded) != {"latency": 1.25}:
        fail(f"timedelta serialization returned {encoded}")

    source = actual_modules["lowest_latency"].read_text(encoding="utf-8")
    if source.count("final_value: float = response_seconds") != 2:
        fail("sync and async latency paths do not both normalize response_seconds")

    print(
        json.dumps(
            {
                "litellm_root": str(imported_root),
                "redis_timedelta_seconds": 1.25,
                "normalized_latency_paths": 2,
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
