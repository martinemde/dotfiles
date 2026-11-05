"""Offline tests for the live Zellij asset checker."""

import hashlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import sys
import unittest
from unittest.mock import patch


sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("check_zellij_plugins", str(ROOT / "bin/check-zellij-plugins"))
spec = importlib.util.spec_from_loader(loader.name, loader)
checker = importlib.util.module_from_spec(spec)
loader.exec_module(checker)


class CheckPluginsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.manifest = Path(self.directory.name) / "plugins.toml"
        self.payload = b"plugin bytes"
        self.digest = hashlib.sha256(self.payload).hexdigest()
        self.url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm"
        self.manifest.write_text(
            f'[".config/zellij/plugins/zellij-autolock.wasm"]\n'
            f'type = "file"\nurl = "{self.url}"\nchecksum.sha256 = "{self.digest}"\n'
        )

    def verify(self, *, api_digest=None, payload=None):
        release = {"assets": [{"name": "zellij-autolock.wasm", "browser_download_url": self.url, "digest": api_digest}]}
        responses = [io.BytesIO(json.dumps(release).encode()), io.BytesIO(self.payload if payload is None else payload)]
        with patch.object(checker, "urlopen", side_effect=responses), patch("sys.stdout", new_callable=io.StringIO) as output:
            checker.check_plugins(self.manifest)
        return output.getvalue()

    def test_missing_sha256_is_rejected_before_downloading(self):
        self.manifest.write_text(self.manifest.read_text().replace(f'checksum.sha256 = "{self.digest}"\n', ""))
        with patch.object(checker, "urlopen") as download:
            with self.assertRaises(KeyError):
                checker.check_plugins(self.manifest)
        download.assert_not_called()

    def test_api_digest_matches(self):
        self.assertIn("GitHub API digest matches", self.verify(api_digest=f"sha256:{self.digest}"))

    def test_missing_api_digest_is_disclosed(self):
        self.assertIn("GitHub API digest unavailable", self.verify())

    def test_changed_bytes_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "SHA256 mismatch"):
            self.verify(payload=b"tampered bytes")

    def test_api_digest_mismatch_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "GitHub API digest mismatch"):
            self.verify(api_digest="sha256:" + "0" * 64)


if __name__ == "__main__":
    unittest.main()
