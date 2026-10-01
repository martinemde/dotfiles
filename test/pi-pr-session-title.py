"""Exercise the pinned upstream and local formatter through real, offline Pi."""

from contextlib import contextmanager
from importlib import import_module
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True
TUI = import_module('pi-terminal-title')
Terminal = TUI.Terminal
WORKING = TUI.WORKING
SPINNER_FRAMES = TUI.SPINNER_FRAMES
ROOT = Path(__file__).resolve().parent.parent
UPSTREAM = Path(sys.argv[1]).resolve()
SUBJECT = 'fix(auth): Prevent Login Race Conditions During Token Refresh'
NAME = 'pinwheel#123 — fix prevent login race conditions'


@contextmanager
def sandbox(*, state=None, arguments=(), gate=None, missing_gh=False):
    with tempfile.TemporaryDirectory(prefix='pi-pr-title-test-') as temporary:
        home = Path(temporary)
        extension = home / 'extensions/pr-session-title'
        extension.mkdir(parents=True)
        shutil.copyfile(ROOT / 'home/dot_pi/private_agent/extensions/pr-session-title/index.ts', extension / 'index.ts')
        shutil.copyfile(UPSTREAM, extension / 'upstream.ts')
        gh = home / 'gh'
        shutil.copyfile(ROOT / 'test/fixtures/pi-pr-gh.py', gh)
        gh.chmod(0o755)
        response = {'title': SUBJECT, 'repo': 'pinwheel', **(state or {})}
        (home / 'gh-response.json').write_text(json.dumps(response))
        if gate:
            (home / gate).touch()
        terminal = Terminal(
            home, extensions=[extension], arguments=arguments,
            environment={'PR_SESSION_TITLE_GH': str(home / 'absent-gh' if missing_gh else gh)},
        )
        try:
            yield terminal, home
        finally:
            for pending in ['pr-gate', 'repo-gate']:
                (home / pending).unlink(missing_ok=True)
            terminal.close()


def calls(home):
    path = home / 'gh-calls.jsonl'
    return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []


def wait_call(terminal, home, kind):
    end = time.monotonic() + 10
    while time.monotonic() < end:
        terminal.read()
        if any(call[:2] == [kind, 'view'] for call in calls(home)):
            return
    raise AssertionError(f'Missing {kind} request; calls: {calls(home)!r}; output: {terminal.output!r}')


def names(home):
    return [entry['name']
            for session in (home / 'agent/sessions').rglob('*.jsonl')
            for line in session.read_text().splitlines()
            if (entry := json.loads(line))['type'] == 'session_info']


def prompt(terminal, text):
    terminal.send(text + '\r')
    terminal.wait_title(rf'{WORKING} \| \d+% \| alpha \| .*')
    terminal.output = b''


def assert_name(terminal, home, name):
    terminal.wait_title(rf'π ready \| 42% \| alpha \| {re.escape(name)}')
    terminal.assert_stable(f'π ready | 42% | alpha | {name}')
    assert names(home)[-1] == name, names(home)


def assert_unnamed(terminal, home):
    terminal.wait_title(rf'π ready \| 42% \| alpha \| {re.escape(home.name)}')
    terminal.assert_stable(f'π ready | 42% | alpha | {home.name}')
    assert names(home) == [], names(home)


def main():
    for text, repo_arg in [
        ('review https://github.com/acme/pinwheel/pull/123', ['--repo', 'acme/pinwheel']),
        ('review PR #123', []),
        ('work on pull request 123', []),
        ('please review #123', []),
    ]:
        with sandbox() as (terminal, home):
            terminal.wait_title(r'π ready \| \d+% \| alpha \| .*')
            prompt(terminal, text)
            assert_name(terminal, home, NAME)
            expected = [['pr', 'view', '123', '--json', 'number,title', *repo_arg]]
            if not repo_arg:
                expected.append(['repo', 'view', '--json', 'name', '--jq', '.name'])
            assert calls(home) == expected, calls(home)
            prompt(terminal, 'review PR 456')
            assert_name(terminal, home, NAME)
            assert calls(home) == expected, calls(home)

    with sandbox(state={'title': 'Repair Token Refresh'}, arguments=['review PR 123']) as (terminal, home):
        assert_name(terminal, home, 'pinwheel#123 — repair token refresh')
        # Print-mode initial prompts use the same deferred upstream hook; names persist,
        # but terminal-title must not write OSC sequences to machine-readable output.
        result = subprocess.run(
            [*terminal.command, '--mode', 'json', '--print'],
            stdin=subprocess.DEVNULL, capture_output=True, cwd=home,
            env=terminal.env, timeout=15,
        )
        assert result.returncode == 0, result.stderr.decode()
        assert b'\x1b]0;' not in result.stdout
        for line in result.stdout.splitlines():
            json.loads(line)
        assert names(home).count('pinwheel#123 — repair token refresh') == 2, names(home)

    for subject, short_name in [
        ('Fix Login', 'fix login'),
        ('Réparer\nToken  Refresh!', 'réparer token refresh'),
        ('feat(session)!: Add Better Task Names Everywhere', 'feat add better task names'),
    ]:
        with sandbox(state={'title': subject}, arguments=['review PR 123']) as (terminal, home):
            assert_name(terminal, home, 'pinwheel#123 — ' + short_name)

    for text, state, missing_gh in [
        ('work without a PR reference', {}, False),
        ('review PR 123', {'pr_failure': True}, False),
        ('review PR 123', {'raw': 'not JSON'}, False),
        ('review PR 123', {'title': ''}, False),
        ('review PR 123', {'repo_failure': True}, False),
        ('review PR 123', {}, True),
    ]:
        with sandbox(state=state, missing_gh=missing_gh) as (terminal, home):
            terminal.wait_title(r'π ready \| \d+% \| alpha \| .*')
            prompt(terminal, text)
            assert_unnamed(terminal, home)
            if text == 'work without a PR reference' or missing_gh:
                assert calls(home) == [], calls(home)

    with sandbox() as (terminal, home):
        terminal.wait_title(r'π ready \| \d+% \| alpha \| .*')
        terminal.send('/name chosen by me\r')
        terminal.wait_title(r'π ready \| \d+% \| alpha \| chosen by me')
        prompt(terminal, 'review PR 123')
        assert_name(terminal, home, 'chosen by me')
        assert calls(home) == [], calls(home)

    # Manual renames win both before and after the upstream title lookup resolves.
    for gate, kind in [('pr-gate', 'pr'), ('repo-gate', 'repo')]:
        with sandbox(arguments=['review PR 123'], gate=gate) as (terminal, home):
            wait_call(terminal, home, kind)
            terminal.send('/name my pending lookup name\r')
            terminal.wait_title(
                rf'π (?:ready|[{SPINNER_FRAMES}] working) \| \d+% \| alpha \| my pending lookup name'
            )
            (home / gate).unlink()
            assert_name(terminal, home, 'my pending lookup name')
            assert names(home) == ['my pending lookup name'], names(home)

    # A stale formatter must not rename the replacement session after its repo lookup.
    with sandbox(arguments=['review PR 123'], gate='repo-gate') as (terminal, home):
        wait_call(terminal, home, 'repo')
        terminal.wait_title(rf'π ready \| 42% \| alpha \| {re.escape(home.name)}')
        terminal.send('/new\r')
        terminal.wait_title(rf'π ready \| \d+% \| alpha \| {re.escape(home.name)}')
        (home / 'repo-gate').unlink()
        terminal.read(1)
        assert names(home) == [], names(home)
        prompt(terminal, 'review https://github.com/acme/other-repo/pull/456')
        assert_name(terminal, home, 'other-repo#456 — fix prevent login race conditions')
        assert names(home) == ['other-repo#456 — fix prevent login race conditions'], names(home)

    print('Pi PR naming integration checks passed (fake gh, no network)')


if __name__ == '__main__':
    main()
