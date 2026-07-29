#!/usr/bin/env python3
"""Verify the structural contract of the LiteLLM health overlays."""

from __future__ import annotations

import ast
from pathlib import Path
import re
import sys


EXPECTED_DISTINCT = ["model_id", "model_name"]
EXPECTED_ORDER = [
    ("model_id", "asc"),
    ("model_name", "asc"),
    ("checked_at", "desc"),
    ("health_check_id", "desc"),
]
EXPECTED_INDEX_FIELDS = [
    "model_id",
    "model_name",
    "checked_at(sort:Desc)",
    "health_check_id(sort:Desc)",
]
EXPECTED_INDEX_NAME = "LiteLLM_HealthCheckTable_latest_model_idx"
EXPECTED_WATCHDOG_TOKENS = [
    "Prisma DB health watchdog probe failed before reconnect.",
    "db_health_watchdog_probe_timeout",
    "db_health_watchdog_connection_error",
    "failure_kind=%s exception_type=%s elapsed_ms=%s",
    "consecutive_reconnect_failures=%s",
    "pool_active=%s pool_wait=%s",
    "pool_busy=%s pool_idle=%s pool_open=%s pool_target=%s",
    "pool_metrics_error_type=%s",
]


def fail(message: str) -> None:
    raise SystemExit(f"health overlay verification failed: {message}")


def string_list(node: ast.AST) -> list[str] | None:
    if not isinstance(node, (ast.List, ast.Tuple)):
        return None
    values: list[str] = []
    for item in node.elts:
        if not isinstance(item, ast.Constant) or not isinstance(item.value, str):
            return None
        values.append(item.value)
    return values


def order_list(node: ast.AST) -> list[tuple[str, str]] | None:
    if not isinstance(node, (ast.List, ast.Tuple)):
        return None
    values: list[tuple[str, str]] = []
    for item in node.elts:
        if not isinstance(item, ast.Dict) or len(item.keys) != 1:
            return None
        key = item.keys[0]
        value = item.values[0]
        if (
            not isinstance(key, ast.Constant)
            or not isinstance(key.value, str)
            or not isinstance(value, ast.Constant)
            or not isinstance(value.value, str)
        ):
            return None
        values.append((key.value, value.value))
    return values


def verify_query(path: Path) -> None:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    functions = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.AsyncFunctionDef)
        and node.name == "get_all_latest_health_checks"
    ]
    if len(functions) != 1:
        fail("expected exactly one get_all_latest_health_checks function")

    calls = [
        node
        for node in ast.walk(functions[0])
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and node.func.attr == "find_many"
    ]
    if len(calls) != 1:
        fail("expected exactly one find_many call in latest health query")

    keywords = {keyword.arg: keyword.value for keyword in calls[0].keywords}
    distinct = string_list(keywords.get("distinct", ast.Constant(None)))
    order = order_list(keywords.get("order", ast.Constant(None)))
    if distinct != EXPECTED_DISTINCT:
        fail(f"unexpected distinct fields: {distinct!r}")
    if order != EXPECTED_ORDER:
        fail(f"unexpected order fields: {order!r}")


def verify_watchdog(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [token for token in EXPECTED_WATCHDOG_TOKENS if token not in source]
    if missing:
        fail(f"watchdog observability tokens are missing: {missing!r}")


def verify_schema(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    model = re.search(
        r"(?ms)^model\s+LiteLLM_HealthCheckTable\s*\{(?P<body>.*?)^\}",
        source,
    )
    if model is None:
        fail("LiteLLM_HealthCheckTable model is missing")

    indexes = re.finditer(
        r'@@index\(\[(?P<fields>[^\]]+)\]\s*,\s*map:\s*"(?P<name>[^"]+)"\s*\)',
        model.group("body"),
    )
    for index in indexes:
        if index.group("name") != EXPECTED_INDEX_NAME:
            continue
        fields = [
            re.sub(r"\s+", "", field)
            for field in index.group("fields").split(",")
        ]
        if fields != EXPECTED_INDEX_FIELDS:
            fail(f"unexpected composite index fields: {fields!r}")
        return
    fail(f"mapped composite index is missing: {EXPECTED_INDEX_NAME}")


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: verify_litellm_health_overlay.py UTILS SCHEMA")
    utils_path = Path(sys.argv[1])
    verify_query(utils_path)
    verify_watchdog(utils_path)
    verify_schema(Path(sys.argv[2]))
    print("health overlay structure verified")


if __name__ == "__main__":
    main()
