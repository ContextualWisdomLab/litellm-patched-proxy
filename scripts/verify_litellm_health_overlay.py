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
    "pool_busy=%s pool_idle=%s",
    "pool_open=%s pool_opened_total=%s pool_closed_total=%s",
    "pool_wait_histogram_count=%s pool_wait_histogram_sum_ms=%s",
    "pool_wait_histogram_le_1000=%s pool_wait_histogram_le_5000=%s",
    "pool_target=%s",
    "pool_metrics_error_type=%s",
    "Prisma DB reconnect preflight before destructive action.",
    "trigger_type=%s exception_type=%s",
    "trigger_elapsed_ms=%s request_elapsed_ms=%s",
    "diagnostics_elapsed_ms=%s consecutive_reconnect_failures=%s",
    "engine_rss_bytes=%s engine_vmsize_bytes=%s",
    "cgroup_memory_current_bytes=%s cgroup_memory_peak_bytes=%s",
    "cgroup_oom_kill_count=%s",
]
EXPECTED_SPEND_WRITER_TOKENS = [
    "event=prisma_spend_transaction_failure",
    "exception_type=%s elapsed_ms=%s error=%s consecutive_failures=%s",
    "engine_started_at=%s engine_process_error_type=%s",
    "pool_opened_total=%s pool_closed_total=%s",
    "pool_wait_histogram_count=%s pool_wait_histogram_sum_ms=%s",
    "self._redis_db_commit_consecutive_failures = 0",
]
EXPECTED_LANGFUSE_HANDLER_TOKENS = [
    "standard_callback_dynamic_params: Optional[StandardCallbackDynamicParams]",
    "if standard_callback_dynamic_params is None:",
]
EXPECTED_ASYNC_HTTP_HANDLER_TOKENS = [
    "_async_client_cleanup_tasks: Set[asyncio.Task] = set()",
    "task = asyncio.get_running_loop().create_task(self.close())",
    "_async_client_cleanup_tasks.add(task)",
    "task.add_done_callback(_discard_async_client_cleanup_task)",
]
EXPECTED_HEALTH_PAYLOAD_TOKENS = [
    '_GENERATIVE_HEALTH_CHECK_MODES = frozenset((None, "chat", "completion", "responses"))',
    "_MIN_HEALTH_CHECK_OUTPUT_TOKENS = 16",
    "_DEFAULT_REASONING_HEALTH_CHECK_OUTPUT_TOKENS = 256",
    "return max(int(explicit), minimum_tokens)",
    'for key in ("messages", "max_tokens", "reasoning_effort"):',
    "litellm_params.pop(key, None)",
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

    tree = ast.parse(source, filename=str(path))
    reconnect_functions = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.AsyncFunctionDef)
        and node.name == "_attempt_reconnect_inside_lock"
    ]
    if len(reconnect_functions) != 1:
        fail("expected exactly one _attempt_reconnect_inside_lock function")

    diagnostics_calls = [
        node
        for node in ast.walk(reconnect_functions[0])
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and node.func.attr == "_get_db_watchdog_diagnostics"
    ]
    reconnect_calls = [
        node
        for node in ast.walk(reconnect_functions[0])
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and node.func.attr == "_run_reconnect_cycle"
    ]
    if len(diagnostics_calls) != 1 or len(reconnect_calls) != 1:
        fail("reconnect preflight must capture diagnostics before one reconnect cycle")
    if diagnostics_calls[0].lineno >= reconnect_calls[0].lineno:
        fail("reconnect diagnostics must be captured before destructive reconnect")


def verify_spend_writer(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [token for token in EXPECTED_SPEND_WRITER_TOKENS if token not in source]
    if missing:
        fail(f"spend-writer observability tokens are missing: {missing!r}")


def verify_langfuse_handler(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [
        token for token in EXPECTED_LANGFUSE_HANDLER_TOKENS if token not in source
    ]
    if missing:
        fail(f"Langfuse callback guard tokens are missing: {missing!r}")

    tree = ast.parse(source, filename=str(path))
    functions = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.FunctionDef)
        and node.name == "_dynamic_langfuse_credentials_are_passed"
    ]
    if len(functions) != 1:
        fail("expected exactly one dynamic Langfuse credential predicate")

    none_guards = [
        node
        for node in ast.walk(functions[0])
        if isinstance(node, ast.If)
        and isinstance(node.test, ast.Compare)
        and isinstance(node.test.left, ast.Name)
        and node.test.left.id == "standard_callback_dynamic_params"
        and len(node.test.ops) == 1
        and isinstance(node.test.ops[0], ast.Is)
        and len(node.test.comparators) == 1
        and isinstance(node.test.comparators[0], ast.Constant)
        and node.test.comparators[0].value is None
        and len(node.body) == 1
        and isinstance(node.body[0], ast.Return)
        and isinstance(node.body[0].value, ast.Constant)
        and node.body[0].value.value is False
    ]
    if len(none_guards) != 1:
        fail("dynamic Langfuse credential predicate must return False for None")


def verify_async_http_handler(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [
        token for token in EXPECTED_ASYNC_HTTP_HANDLER_TOKENS if token not in source
    ]
    if missing:
        fail(f"async HTTP cleanup tokens are missing: {missing!r}")

    tree = ast.parse(source, filename=str(path))
    classes = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.ClassDef) and node.name == "AsyncHTTPHandler"
    ]
    if len(classes) != 1:
        fail("expected exactly one AsyncHTTPHandler class")
    destructors = [
        node
        for node in classes[0].body
        if isinstance(node, ast.FunctionDef) and node.name == "__del__"
    ]
    if len(destructors) != 1:
        fail("expected exactly one AsyncHTTPHandler destructor")

    calls = [node for node in ast.walk(destructors[0]) if isinstance(node, ast.Call)]
    create_calls = [
        node
        for node in calls
        if isinstance(node.func, ast.Attribute) and node.func.attr == "create_task"
    ]
    retain_calls = [
        node
        for node in calls
        if isinstance(node.func, ast.Attribute) and node.func.attr == "add"
    ]
    callback_calls = [
        node
        for node in calls
        if isinstance(node.func, ast.Attribute)
        and node.func.attr == "add_done_callback"
    ]
    if len(create_calls) != 1 or len(retain_calls) != 1 or len(callback_calls) != 1:
        fail("async HTTP destructor must create, retain, and release one cleanup task")
    if not (create_calls[0].lineno < retain_calls[0].lineno < callback_calls[0].lineno):
        fail("async HTTP cleanup task must be retained before its done callback")


def verify_health_payload(path: Path) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [token for token in EXPECTED_HEALTH_PAYLOAD_TOKENS if token not in source]
    if missing:
        fail(f"provider-safe health payload tokens are missing: {missing!r}")

    tree = ast.parse(source, filename=str(path))
    functions = {
        node.name: node
        for node in ast.walk(tree)
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
    }
    for name in (
        "_resolve_health_check_max_tokens",
        "_update_litellm_params_for_health_check",
    ):
        if name not in functions:
            fail(f"expected health payload function is missing: {name}")


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
            re.sub(r"\s+", "", field) for field in index.group("fields").split(",")
        ]
        if fields != EXPECTED_INDEX_FIELDS:
            fail(f"unexpected composite index fields: {fields!r}")
        return
    fail(f"mapped composite index is missing: {EXPECTED_INDEX_NAME}")


def main() -> None:
    if len(sys.argv) != 7:
        fail(
            "usage: verify_litellm_health_overlay.py "
            "UTILS SCHEMA HEALTH_CHECK SPEND_WRITER LANGFUSE_HANDLER "
            "ASYNC_HTTP_HANDLER"
        )
    utils_path = Path(sys.argv[1])
    verify_query(utils_path)
    verify_watchdog(utils_path)
    verify_schema(Path(sys.argv[2]))
    verify_health_payload(Path(sys.argv[3]))
    verify_spend_writer(Path(sys.argv[4]))
    verify_langfuse_handler(Path(sys.argv[5]))
    verify_async_http_handler(Path(sys.argv[6]))
    print("health overlay structure verified")


if __name__ == "__main__":
    main()
