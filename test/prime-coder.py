"""Offline CLI boundary tests: no Coder account, network, or model access."""

from datetime import datetime, timedelta, timezone
import json
import os
from pathlib import Path
import shlex
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parent.parent
LAUNCHER = ROOT / "home/dot_local/bin/executable_prime-coder"
VERSION = "test-prime-1"


def record(home, event):
    with (home / "events.jsonl").open("a") as stream:
        stream.write(json.dumps(event) + "\n")


def fake_command():
    home = Path(__file__).resolve().parent.parent
    config = json.loads((home / "config.json").read_text())
    tool, args = Path(sys.argv[0]).name, sys.argv[1:]
    event = {"tool": tool, "args": args}
    if tool == "prime-agent":
        event["remote"] = os.environ.get("HOME") == str(home / "remote")
        event["pid"] = os.getpid()
        event["cwd"] = os.getcwd()
        if args[:1] == ["--daemon-socket"]:
            event["env"] = dict(os.environ)
        record(home, event)
        if args == ["--version"]:
            print(VERSION)
        elif args == ["update", "--check"]:
            print("Channel:  stable\nUp to date." if config.get("remote_current")
                  else "Channel:  stable\nUpdate available.")
        elif args == ["update", "--stable"]:
            if os.environ.get("PRIME_AGENT_INTERACTIVE_SELF_UPDATE") == "1":
                return 75
            if config.get("fail_update") == ("remote" if event["remote"] else "local"):
                return 9
        elif args[:1] == ["--daemon-socket"]:
            return config.get("ui_exit", 0)
        elif args[:2] == ["--mode", "daemon"]:
            fake_daemon(home, args[args.index("--daemon-socket") + 1], config)
        else:
            raise AssertionError(args)
    elif tool == "coder":
        record(home, event)
        if args == ["list", "--output", "json"]:
            print(json.dumps(config["workspaces"]))
        elif args[:1] == ["ssh"]:
            command = args[args.index("--") + 1:]
            assert len(command) == 1, command
            if config.get("banner"):
                print("==> Startup scripts finished", flush=True)
            env = {**os.environ, "HOME": str(home / "remote"), "PATH": str(home / "bin"),
                   "TMPDIR": str(home / "remote/tmp")}
            env.pop("PRIME_AGENT_INTERACTIVE_SELF_UPDATE", None)
            return subprocess.call(["/bin/sh", "-c", command[0]], env=env)
        elif args[0] == "stop":
            return 1 if config.get("cancel_stop") else 0
        elif args[0] not in ("create", "start"):
            raise AssertionError(args)
    elif tool == "curl":
        event["remote"] = os.environ.get("HOME") == str(home / "remote")
        record(home, event)
        failure = config.get("install_failure")
        if failure == "curl":
            return 22
        if failure != "before":
            installer = ('import os; from pathlib import Path; home = Path(os.environ["HOME"]); '
                         '(home / ".local/bin/prime-agent").symlink_to(home.parent / "bin/prime-agent")')
            print("python3 -c " + shlex.quote(installer))
            print("echo 'Installed Prime fixture'")
        if failure in ("before", "after"):
            print("exit 9")
    elif tool == "fzf":
        event["choices"] = sys.stdin.read().splitlines()
        record(home, event)
        if config.get("fzf_exit"):
            return config["fzf_exit"]
        print(config.get("key", ""))
        print(event["choices"][config.get("choice", 0)])
    elif tool == "ssh":
        record(home, event)
        if "-L" in args:
            endpoint, remote = args[args.index("-L") + 1].split(":", 1)
            Path(endpoint).symlink_to(remote)
        else:
            assert args[args.index("-O") + 1] == "exit", args
    else:
        raise AssertionError(tool)
    return 0


def fake_daemon(home, endpoint, config):
    """A separate daemon process, for tests that need to replace one."""
    Path(endpoint).unlink(missing_ok=True)
    server = socket.socket(socket.AF_UNIX)
    server.bind(endpoint)
    server.listen()
    version = config.get("daemon_version", VERSION)
    while True:
        connection, _ = server.accept()
        with connection, connection.makefile("rwb") as stream:
            stream.write((json.dumps({"type": "hello", "protocol": 1, "appVersion": version}) + "\n").encode())
            stream.flush()
            for line in stream:
                message = json.loads(line)
                record(home, {"tool": "daemon", "version": version, "command": message["command"]})
                kind = message["command"]["type"]
                data = ({"sessions": config["sessions"]} if kind == "list"
                        else None if kind == "shutdown" else {"activeSessionId": "session-created"})
                stream.write((json.dumps({"type": "response", "id": message["id"],
                                          "success": True, "data": data}) + "\n").encode())
                stream.flush()
                if kind == "shutdown":
                    server.close()
                    Path(endpoint).unlink()
                    return 0


class PrimeCoderTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="pc-test-", dir="/tmp")
        self.home = Path(self.temporary.name).resolve()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.remote = self.home / "remote"
        (self.remote / ".prime/agent").mkdir(parents=True)
        (self.remote / "workspace/project/.git").mkdir(parents=True)
        source = "#!" + sys.executable + "\n" + Path(__file__).read_text()
        for tool in ("coder", "ssh", "prime-agent", "fzf", "curl"):
            executable = self.bin / tool
            executable.write_text(source)
            executable.chmod(0o755)
        (self.bin / "python3").symlink_to(sys.executable)
        (self.bin / "sh").symlink_to("/bin/sh")
        (self.remote / ".local/bin").mkdir(parents=True)
        (self.remote / ".local/bin/prime-agent").symlink_to(self.bin / "prime-agent")
        self.config = {
            "workspaces": [{"name": "dev", "template_name": "durable",
                            "latest_build": {"status": "running"}}],
            "sessions": [{"sessionName": "prime-coder", "activeSessionId": "session-existing",
                          "workerPid": 1234}],
        }
        self.endpoint = self.remote / "tmp" / f"prime-agent-{os.getuid()}" / "daemon.sock"
        self.endpoint.parent.mkdir(parents=True)
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(str(self.endpoint))
        self.server.listen()
        self.server.settimeout(0.1)
        self.stopping = threading.Event()
        self.requests = []
        self.errors = []
        self.connections = 0
        self.thread = threading.Thread(target=self.serve, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.stopping.set()
        self.thread.join(2)
        self.server.close()
        self.temporary.cleanup()
        self.assertFalse(self.thread.is_alive(), "Fake daemon failed to stop")
        self.assertEqual(self.errors, [])

    def serve(self):
        while not self.stopping.is_set():
            try:
                connection, _ = self.server.accept()
            except socket.timeout:
                continue
            try:
                with connection, connection.makefile("rwb") as stream:
                    self.connections += 1
                    version = self.config.get("daemon_version", VERSION)
                    if self.config.get("bad_forward") and self.connections % 2 == 0:
                        version = "wrong-version"
                    stream.write((json.dumps({"type": "hello", "protocol": 1,
                                              "appVersion": version}) + "\n").encode())
                    stream.flush()
                    for line in stream:
                        message = json.loads(line)
                        command = message["command"]
                        self.requests.append(command)
                        if command["type"] == "list":
                            data = {"sessions": self.config["sessions"]}
                        elif command["type"] == "create":
                            data = {"activeSessionId": "session-created"}
                        else:
                            raise AssertionError(command)
                        stream.write((json.dumps({"type": "response", "id": message["id"],
                                                  "success": True, "data": data}) + "\n").encode())
                        stream.flush()
            except Exception as error:
                self.errors.append(repr(error))

    def launch(self, *args, input="", interval="0", debug=False):
        (self.home / "config.json").write_text(json.dumps(self.config))
        env = {"HOME": str(self.home), "PATH": str(self.bin), "LANG": "C",
               "TERM": "xterm-256color", "LAPTOP_SECRET": "never-send-this",
               "PRIME_AGENT_INTERACTIVE_SELF_UPDATE": "1"}
        if debug:
            env["DEBUG"] = "1"
        if interval is not None:
            env["PRIME_CODER_UPDATE_INTERVAL"] = interval
        result = subprocess.run([sys.executable, str(LAUNCHER), *args], input=input,
                                text=True, capture_output=True, env=env, timeout=10)
        return result

    def events(self, tool=None):
        path = self.home / "events.jsonl"
        events = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        return [event for event in events if tool is None or event["tool"] == tool]

    def ui_events(self):
        return [event for event in self.events("prime-agent")
                if event["args"][:1] == ["--daemon-socket"]]

    def assert_cleanup(self):
        ssh = self.events("ssh")
        forwards = [event for event in ssh if "-L" in event["args"]]
        exits = [event for event in ssh if "-O" in event["args"]]
        self.assertEqual(len(exits), len(forwards))
        for forward, exit_event in zip(forwards, exits):
            args = forward["args"]
            control = args[args.index("-S") + 1]
            self.assertEqual(exit_event["args"][exit_event["args"].index("-S") + 1], control)
            self.assertFalse(Path(control).parent.exists())

    def test_auth_is_never_read_or_changed_without_opt_in(self):
        local = self.home / ".prime/agent"
        local.mkdir(parents=True)
        (local / "auth.json").write_text("not valid JSON")
        remote = self.remote / ".prime/agent/auth.json"
        remote.write_text('{"untouched": true}')
        result = self.launch("dev")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(remote.read_text(), '{"untouched": true}')

    def test_forward_auth_merges_refreshes_and_never_logs_keys(self):
        local = self.home / ".prime/agent"
        local.mkdir(parents=True)
        remote = self.remote / ".prime/agent/auth.json"
        remote.write_text(json.dumps({"provider": {"type": "oauth", "refresh": "old"},
                                      "unrelated": {"type": "api_key", "key": "remote-key"}}))
        remote.chmod(0o644)
        for secret in ("test-secret-first", "test-secret-rotated"):
            saved = {"provider": {"type": "api_key", "key": secret},
                     "oauth": {"type": "oauth", "access": "oauth-access", "refresh": "oauth-refresh"},
                     "command": {"type": "api_key", "key": "!never-run-this"}}
            (local / "auth.json").write_text(json.dumps(saved))
            result = self.launch("--forward-auth", "dev", debug=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(remote.read_text()), {
                "provider": saved["provider"], "unrelated": {"type": "api_key", "key": "remote-key"}})
            self.assertEqual(remote.stat().st_mode & 0o777, 0o600)
            self.assertFalse((remote.parent / "auth.json.lock").exists())
            self.assertEqual(list(remote.parent.glob(".auth-*")), [])
            visible = result.stdout + result.stderr + json.dumps(self.events())
            for value in (secret, "oauth-access", "oauth-refresh"):
                self.assertNotIn(value, visible)
            command = [event for event in self.events("coder") if event["args"][0] == "ssh"][-1]
            self.assertIn("--tty=false", command["args"])
            self.assertNotIn("--forward-auth", self.ui_events()[-1]["args"])
        self.assert_cleanup()

    def test_forward_auth_resolves_saved_env_references_with_picker(self):
        local = self.home / ".prime/agent"
        local.mkdir(parents=True)
        (local / "auth.json").write_text(json.dumps({"provider": {"type": "api_key", "key": "LAPTOP_SECRET"}}))
        self.config["choice"] = 1  # existing workspace, not New workspace
        result = self.launch("--forward-auth")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.remote / ".prime/agent/auth.json").read_text()), {
            "provider": {"type": "api_key", "key": "never-send-this"}})
        self.assertNotIn("LAPTOP_SECRET", self.ui_events()[0]["env"])

    def test_forward_auth_failures_do_not_launch_or_replace_remote_auth(self):
        local = self.home / ".prime/agent"
        local.mkdir(parents=True)
        path = local / "auth.json"
        for content in (None, "not JSON", json.dumps({"oauth": {"type": "oauth", "refresh": "secret"}})):
            if content is not None:
                path.write_text(content)
            result = self.launch("--forward-auth", "dev")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(self.ui_events(), [])
            self.assertEqual(self.requests, [])
            self.assertNotIn("secret", result.stderr)
        path.write_text(json.dumps({"provider": {"type": "api_key", "key": "test-secret"}}))
        remote = self.remote / ".prime/agent/auth.json"
        for malformed in ("not JSON", "[]"):
            remote.write_text(malformed)
            result = self.launch("--forward-auth", "dev")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(remote.read_text(), malformed)
            self.assertFalse((remote.parent / "auth.json.lock").exists())
            self.assertEqual(list(remote.parent.glob(".auth-*")), [])
        remote.write_text("{}")
        (remote.parent / "auth.json.lock").mkdir()
        result = self.launch("--forward-auth", "dev")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(remote.read_text(), "{}")
        self.assertIn("busy", result.stderr)
        self.assertEqual(self.ui_events(), [])
        self.assertEqual(self.requests, [])

    def test_forwarding_updates_and_cleanup_on_every_invocation(self):
        self.config["ui_exit"] = 7
        self.config["banner"] = True
        arguments = ["--name", "two words", "--print", "literal '$HOME'; *", ""]
        for remote_current in (False, True):
            self.config["remote_current"] = remote_current
            result = self.launch("dev", *arguments)
            self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual(len(self.ui_events()), 2)
        self.assertEqual(self.events("curl"), [])
        for event in self.ui_events():
            self.assertEqual(event["args"][2:], arguments)
            self.assertEqual(event["cwd"], "/")
            self.assertNotIn("LAPTOP_SECRET", event["env"])
            self.assertNotIn("HOME", event["env"])
            self.assertNotIn("PATH", event["env"])
            self.assertEqual(event["env"]["PRIME_AGENT_SESSION_DIR"],
                             str(self.remote / ".prime/agent/sessions"))
        updates = [event["remote"] for event in self.events("prime-agent")
                   if event["args"] == ["update", "--stable"]]
        self.assertEqual(updates, [False, True, False])
        checks = [event["remote"] for event in self.events("prime-agent")
                  if event["args"] == ["update", "--check"]]
        self.assertEqual(checks, [True, True])
        self.assertEqual(self.requests, [])
        self.assert_cleanup()

    def test_missing_remote_prime_installs_before_updates_and_bootstrap(self):
        binary = self.remote / ".local/bin/prime-agent"
        binary.unlink()
        result = self.launch("dev")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(os.access(binary, os.X_OK))
        self.assertEqual(self.events("curl"), [{
            "tool": "curl", "args": ["-fsSL", "https://app.primeintellect.ai/prime-agent/install.sh"],
            "remote": True,
        }])
        self.assertIn("Installed Prime fixture", result.stderr)
        self.assertNotIn("Installed Prime fixture", result.stdout)
        events = self.events()
        curl_index = next(index for index, event in enumerate(events) if event["tool"] == "curl")
        remote_checks = [index for index, event in enumerate(events)
                         if event["tool"] == "prime-agent" and event["remote"]
                         and event["args"] == ["update", "--check"]]
        self.assertEqual(len(remote_checks), 1)
        self.assertLess(curl_index, remote_checks[0])
        updates = [event["remote"] for event in self.events("prime-agent")
                   if event["args"] == ["update", "--stable"]]
        self.assertEqual(updates, [False, True])
        self.assertEqual([command["type"] for command in self.requests], ["list"])
        self.assertEqual(self.ui_events()[0]["args"][2:], ["attach", "session-existing"])
        self.assert_cleanup()

    def test_remote_install_failure_prevents_update_bootstrap_and_ui(self):
        binary = self.remote / ".local/bin/prime-agent"
        for failure in ("curl", "before", "after"):
            with self.subTest(failure=failure):
                binary.unlink(missing_ok=True)
                self.config["install_failure"] = failure
                result = self.launch("dev")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(binary.exists(), failure == "after")
                self.assertEqual(len(self.events("curl")), 1)
                self.assertEqual([(event["remote"], event["args"])
                                  for event in self.events("prime-agent")],
                                 [(False, ["update", "--stable"]), (False, ["--version"])])
                self.assertEqual(len(self.events("coder")), 2)
                self.assertEqual(self.requests, [])
                self.assertEqual(self.connections, 0)
                self.assertEqual(self.ui_events(), [])
                self.assertEqual(self.events("ssh"), [])
                (self.home / "events.jsonl").unlink()

    def test_chooser_creates_workspace_with_native_coder_prompts(self):
        self.config["sessions"] = []
        self.config["workspaces"].append({"name": "unrelated", "template_name": "other",
                                          "latest_build": {"status": "running"}})
        result = self.launch(input="new-dev\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        create = next(event for event in self.events("coder") if event["args"][0] == "create")
        self.assertEqual(create["args"], ["create", "new-dev"])
        self.assertEqual(self.events("fzf")[0]["choices"],
                         ["+ New workspace", "dev        running  durable  never used",
                          "unrelated  running  other    never used"])
        self.assertEqual(self.ui_events()[0]["args"][2:], ["attach", "session-created"])
        self.assertEqual(self.requests[-1]["config"]["cwd"], str(self.remote / "workspace/project"))
        self.assertTrue(self.requests[-1]["telemetryDisabled"])
        self.assert_cleanup()

    def test_stopped_workspace_starts_and_reattaches_existing_session(self):
        self.config["workspaces"][0]["latest_build"]["status"] = "stopped"
        self.config["choice"] = 1
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        coder = self.events("coder")
        self.assertEqual(coder[1]["args"], ["start", "dev", "--yes"])
        self.assertEqual(self.ui_events()[0]["args"][2:], ["attach", "session-existing"])
        self.assertEqual([command["type"] for command in self.requests], ["list"])
        self.assert_cleanup()

    def test_chooser_stop_confirms_without_starting_or_connecting(self):
        self.config.update(choice=1, key="ctrl-x")
        for args, cancel in (([], False), ([], True), (["--forward-auth"], False), (["--forward-auth"], True)):
            with self.subTest(args=args, cancel=cancel):
                self.config["cancel_stop"] = cancel
                result = self.launch(*args)
                self.assertEqual(result.returncode, 1 if cancel else 0, result.stderr)
                self.assertEqual([event["args"] for event in self.events("coder")],
                                 [["list", "--output", "json"], ["stop", "dev"]])
                self.assertEqual(self.events("prime-agent"), [])
                self.assertEqual(self.events("ssh"), [])
                self.assertEqual(self.requests, [])
                (self.home / "events.jsonl").unlink()
        self.config["choice"] = 0
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([event["args"] for event in self.events("coder")],
                         [["list", "--output", "json"]])

    def test_inactive_saved_session_is_resumed_instead_of_attached(self):
        self.config["sessions"][0].update(workerPid=None, sessionFile="/saved/session.jsonl")
        result = self.launch("dev")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.ui_events()[0]["args"][2:], ["attach", "session-created"])
        self.assertEqual(self.requests[-1]["sessionPath"], "/saved/session.jsonl")
        self.assertTrue(self.requests[-1]["telemetryDisabled"])
        self.assert_cleanup()

    def test_update_or_daemon_failure_prevents_ui(self):
        for failure in ({"fail_update": "local"}, {"fail_update": "remote"},
                        {"daemon_version": "wrong-version"}, {"bad_forward": True}):
            with self.subTest(failure=failure):
                self.config.update(failure)
                result = self.launch("dev", "list", "--all", "--json")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.ui_events(), [])
                updates = [event["remote"] for event in self.events("prime-agent")
                           if event["args"] == ["update", "--stable"]]
                self.assertEqual(updates, [False] if failure.get("fail_update") == "local"
                                 else [False, True])
                self.assertEqual(bool(self.events("ssh")), bool(failure.get("bad_forward")))
                self.assert_cleanup()
                for key in failure:
                    del self.config[key]
                (self.home / "events.jsonl").unlink()
                self.connections = 0

    def test_chooser_sorts_running_then_recent_and_shows_template(self):
        now = datetime.now(timezone.utc)
        stamp = lambda hours: (now - timedelta(hours=hours)).strftime("%Y-%m-%dT%H:%M:%S.123456789Z")
        self.config["workspaces"] = [
            {"name": "old", "template_name": "t", "last_used_at": stamp(50),
             "latest_build": {"status": "running"}},
            {"name": "parked", "template_name": "t", "last_used_at": stamp(0),
             "latest_build": {"status": "stopped"}},
            {"name": "fresh", "template_name": "t", "last_used_at": stamp(3),
             "latest_build": {"status": "running"}},
        ]
        self.config["fzf_exit"] = 130
        result = self.launch()
        self.assertEqual(self.events("fzf")[0]["choices"], [
            "+ New workspace", "fresh   running  t  used 3h ago",
            "old     running  t  used 2d ago", "parked  stopped  t  used just now"])
        self.assertEqual((result.returncode, result.stderr), (130, ""))
        self.assertEqual([event["args"] for event in self.events("coder")],
                         [["list", "--output", "json"]])

    def test_update_checks_run_at_most_once_per_interval(self):
        for _ in range(2):
            result = self.launch("dev", interval=None)
            self.assertEqual(result.returncode, 0, result.stderr)
        updates = [(event["remote"], event["args"][1]) for event in self.events("prime-agent")
                   if event["args"][:1] == ["update"]]
        self.assertEqual(updates, [(False, "--stable"), (True, "--check"), (True, "--stable")])
        self.assertEqual(len([event for event in self.events("coder") if event["args"][0] == "ssh"]), 2)
        self.assertEqual(len(self.ui_events()), 2)

    def test_stale_daemon_without_live_sessions_is_replaced(self):
        self.stopping.set()
        self.thread.join(2)
        self.server.close()
        self.endpoint.unlink()
        self.config.update(daemon_version="old", sessions=[
            {"sessionName": "prime-coder", "sessionFile": "/saved/session.jsonl"}])
        (self.home / "config.json").write_text(json.dumps(self.config))
        env = {"HOME": str(self.remote), "PATH": str(self.bin), "TMPDIR": str(self.remote / "tmp")}
        old = subprocess.Popen([str(self.bin / "prime-agent"), "--mode", "daemon",
                                "--daemon-socket", str(self.endpoint)], env=env)
        try:
            for _ in range(100):
                if self.endpoint.exists():
                    break
                time.sleep(0.05)
            del self.config["daemon_version"]
            result = self.launch("dev")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("restarting it", result.stderr)
            self.assertEqual(old.wait(5), 0)
            served = [(event["version"], event["command"]["type"]) for event in self.events("daemon")]
            self.assertEqual(served, [("old", "list"), ("old", "shutdown"), (VERSION, "list"), (VERSION, "create")])
            started = [event["cwd"] for event in self.events("prime-agent")
                       if event["args"][:2] == ["--mode", "daemon"] and event["pid"] != old.pid]
            self.assertEqual(started, [str(self.remote / "workspace/project")])
            self.assertEqual(self.ui_events()[0]["args"][2:], ["attach", "session-created"])
            self.assert_cleanup()
        finally:
            old.kill()
            old.wait()
            for event in self.events("prime-agent"):
                if event["args"][:2] == ["--mode", "daemon"] and event["pid"] != old.pid:
                    os.kill(event["pid"], signal.SIGKILL)


if __name__ == "__main__":
    if Path(sys.argv[0]).name == "prime-coder.py":
        unittest.main()
    else:
        sys.exit(fake_command())
