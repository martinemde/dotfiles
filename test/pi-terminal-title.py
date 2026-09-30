"""Drive the real Pi TUI in an isolated PTY with an offline provider."""

import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time


ROOT = Path(__file__).resolve().parent.parent
TITLE = re.compile(rb"\x1b\]0;([^\x07]*)\x07")
SPINNER_FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
WORKING = rf"π ── [{SPINNER_FRAMES}] Working"


class Terminal:
    def __init__(self, home):
        agent = home / "agent"
        agent.mkdir()
        (agent / "settings.json").write_text(json.dumps({
            "quietStartup": True,
            "enableInstallTelemetry": False,
            "compaction": {"enabled": False, "keepRecentTokens": 1},
            "cacheWarming": "off",
            "packages": [],
        }))
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 160, 0, 0))
        self.output = b""
        self.command = [
            shutil.which("pi"), "--offline", "--no-extensions", "--no-skills",
            "--no-prompt-templates", "--no-themes", "--no-tools", "--no-context-files",
            "--extension", str(ROOT / "home/dot_pi/private_agent/extensions/terminal-title.ts"),
            "--extension", str(ROOT / "test/fixtures/pi-title-provider.ts"),
            "--provider", "terminal-title-test", "--model", "alpha",
            "--thinking", "off",
        ]
        self.env = {
            "PATH": os.environ["PATH"],
            "HOME": str(home),
            "XDG_CACHE_HOME": str(home / "cache"),
            "PI_CODING_AGENT_DIR": str(agent),
            "PI_OFFLINE": "1",
            "TERM": "xterm-256color",
        }
        self.process = subprocess.Popen(
            self.command, stdin=slave, stdout=slave, stderr=slave,
            cwd=home, env=self.env,
        )
        os.close(slave)

    def read(self, seconds=0.1):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            if select.select([self.master], [], [], max(0, end - time.monotonic()))[0]:
                try:
                    data = os.read(self.master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        return
                    raise
                if not data:
                    return
                self.output += data

    def send(self, text):
        self.output = b""
        os.write(self.master, text.encode())

    def titles(self):
        return [value.decode() for value in TITLE.findall(self.output)]

    def wait_title(self, pattern, timeout=15):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            self.read()
            if any(re.fullmatch(pattern, title) for title in self.titles()):
                return
            if self.process.poll() is not None:
                break
        raise AssertionError(f"Missing title {pattern!r}; output: {self.output.decode(errors='replace')!r}")

    def assert_stable(self, title):
        self.output = b""
        self.read(1.2)
        assert all(value == title for value in self.titles()), self.titles()

    def close(self):
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        os.close(self.master)


def main():
    with tempfile.TemporaryDirectory(prefix="pi-title-test-") as temporary:
        home = Path(temporary)
        terminal = Terminal(home)
        fallback = re.escape(home.name)
        try:
            terminal.wait_title(rf"π ready \| \d+% \| alpha \| {fallback}")
            terminal.read(1)
            assert re.fullmatch(rf"π ready \| \d+% \| alpha \| {fallback}", terminal.titles()[-1])

            terminal.send("/name title-test\r")
            terminal.wait_title(r"π ready \| \d+% \| alpha \| title-test")
            terminal.read(0.5)
            assert re.fullmatch(r"π ready \| \d+% \| alpha \| title-test", terminal.titles()[-1])

            terminal.send("work\r")
            terminal.wait_title(rf"{WORKING} \| \d+% \| alpha \| title-test")
            terminal.wait_title(r"π ready \| 42% \| alpha \| title-test")
            frames = [match.group(1) for title in terminal.titles()
                      if (match := re.match(rf"π ── ([{SPINNER_FRAMES}]) Working", title))]
            # Match Pi's complete spinner cycle, not a static braille character.
            assert ''.join(dict.fromkeys(frames)) == SPINNER_FRAMES, frames
            terminal.assert_stable("π ready | 42% | alpha | title-test")

            terminal.send("/title-idle-question\r")
            terminal.wait_title(r"π \[\.\] \| 42% \| alpha \| title-test")
            terminal.wait_title(r"π \[!\] \| 42% \| alpha \| title-test")
            terminal.send("\x1b")  # Cancel the confirmation.
            terminal.wait_title(r"π ready \| 42% \| alpha \| title-test")
            terminal.assert_stable("π ready | 42% | alpha | title-test")

            terminal.send("question\r")
            terminal.wait_title(rf"{WORKING} \| \d+% \| alpha \| title-test")
            terminal.wait_title(r"π \[\.\] \| \d+% \| alpha \| title-test")
            terminal.wait_title(r"π \[!\] \| \d+% \| alpha \| title-test")
            terminal.send("\r")  # Accept the selected answer.
            terminal.wait_title(rf"{WORKING} \| \d+% \| alpha \| title-test")
            terminal.wait_title(r"π ready \| 42% \| alpha \| title-test")

            terminal.send("/compact\r")
            terminal.wait_title(rf"{WORKING} \| 42% \| alpha \| title-test")
            terminal.wait_title(r"π ready \| \?% \| alpha \| title-test")

            terminal.send("/model terminal-title-test/beta\r")
            terminal.wait_title(r"π ready \| \?% \| beta off \| title-test")
            for effort in ['minimal', 'low', 'medium', 'high', 'xhigh']:
                terminal.send("\x1b[Z")  # Shift+Tab: Pi's real effort cycling key.
                terminal.wait_title(rf"π ready \| \?% \| beta {effort} \| title-test")
            terminal.send("work\r")
            terminal.wait_title(rf"{WORKING} \| \?% \| beta xhigh \| title-test")
            terminal.send("\x1b")  # Abort the active turn.
            terminal.wait_title(r"π ready \| \?% \| beta xhigh \| title-test")

            terminal.send("/reload\r")
            terminal.wait_title(r"π ready \| \?% \| beta xhigh \| title-test")
            terminal.read(0.7)
            assert terminal.titles()[-1] == "π ready | ?% | beta xhigh | title-test", terminal.titles()

            terminal.send("/new\r")
            terminal.wait_title(rf"π ready \| \d+% \| alpha \| {fallback}")
            terminal.read(0.7)
            assert re.fullmatch(rf"π ready \| \d+% \| alpha \| {fallback}", terminal.titles()[-1])
            result = subprocess.run(
                [*terminal.command, '--mode', 'json', '--print', 'work'],
                stdin=subprocess.DEVNULL, capture_output=True, cwd=home,
                env=terminal.env, timeout=15,
            )
            assert result.returncode == 0, result.stderr.decode()
            assert not TITLE.findall(result.stdout)
            for line in result.stdout.splitlines():
                json.loads(line)

            print("Pi terminal title integration checks passed")
        finally:
            terminal.close()


if __name__ == "__main__":
    main()
