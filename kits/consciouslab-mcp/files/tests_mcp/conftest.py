"""MCP testlerinin düzeneği: auth-core çalışmadan token basan test issuer."""
import socket

import pytest

pytest_plugins = ["consciouslab_auth.testing.pytest_plugin"]


@pytest.fixture
def resource(monkeypatch, token_issuer):
    """App'in ortamı: issuer = test issuer, adres = boş bir port. Dönüş: beklenen `aud`."""
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    address = f"http://127.0.0.1:{port}/mcp"
    monkeypatch.setenv("AUTH_ISSUER", token_issuer.url)
    monkeypatch.setenv("PORT", str(port))
    monkeypatch.setenv("MCP_RESOURCE", address)
    return address
