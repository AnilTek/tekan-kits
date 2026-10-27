"""MCP sunucusunun auth sözleşmesi: giriş, izin, alan ayıklama. Gerçek auth-core gerekmez."""
import pytest
from mcp_server.app import create_app
from mcp_server.tools import REDACTED_KEYS
from starlette.testclient import TestClient

HEADERS = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}


@pytest.fixture
def client(resource):
    base = resource.removesuffix("/mcp")
    with TestClient(create_app(), base_url=base) as test_client:
        yield test_client


def rpc(client, method, params=None, token=None):
    headers = dict(HEADERS)
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or {}}
    return client.post("/mcp", headers=headers, json=body)


def call(client, name, token, arguments=None):
    response = rpc(client, "tools/call", {"name": name, "arguments": arguments or {}}, token)
    assert response.status_code == 200, response.text
    return response.json()["result"]


def find_keys(value, keys):
    if isinstance(value, dict):
        return [k for k in value if k in keys] + [f for v in value.values() for f in find_keys(v, keys)]
    if isinstance(value, list):
        return [f for v in value for f in find_keys(v, keys)]
    return []


def test_no_token_is_challenged(client, resource):
    response = rpc(client, "tools/list")
    host = resource.removesuffix("/mcp")
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == (
        f'Bearer resource_metadata="{host}/.well-known/oauth-protected-resource"'
    )


@pytest.mark.parametrize("kind", ["wrong_aud", "wrong_iss", "expired", "bad_signature", "alg_none"])
def test_bad_token_is_rejected(client, resource, token_issuer, kind):
    assert rpc(client, "tools/list", token=token_issuer.bad_tokens(resource)[kind]).status_code == 401


def test_every_tool_declares_a_permission_and_there_is_list_spaces(client, resource, token_issuer):
    tools = rpc(client, "tools/list", token=token_issuer.issue(aud=resource)).json()["result"]["tools"]
    assert "list_spaces" in {tool["name"] for tool in tools}
    assert len(tools) <= 10
    assert all(tool["_meta"]["required_permission"] for tool in tools)


def test_tool_without_permission_does_not_run(client, resource, token_issuer):
    token = token_issuer.issue(aud=resource, permissions=[])
    result = call(client, "list_spaces", token)
    assert result["isError"] is True


def test_no_tool_returns_redacted_fields(client, resource, token_issuer):
    token = token_issuer.issue(aud=resource)
    for name in ("list_spaces", "list_items"):
        result = call(client, name, token)
        assert result["isError"] is False
        assert find_keys(result["structuredContent"], REDACTED_KEYS) == []
