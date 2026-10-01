#!/usr/bin/env python3
"""Fake the GitHub CLI at the process boundary; never access the network."""

import json
from pathlib import Path
import sys
import time

home = Path.cwd()
args = sys.argv[1:]
with (home / 'gh-calls.jsonl').open('a') as calls:
    calls.write(json.dumps(args) + '\n')
state = json.loads((home / 'gh-response.json').read_text())
if args[:2] == ['pr', 'view']:
    assert args[3:5] == ['--json', 'number,title'], args
    gate = home / 'pr-gate'
    while gate.exists():
        time.sleep(0.02)
    if state.get('pr_failure'):
        sys.exit(1)
    if 'raw' in state:
        print(state['raw'])
    else:
        print(json.dumps({'number': int(args[2]), 'title': state['title']}))
elif args == ['repo', 'view', '--json', 'name', '--jq', '.name']:
    gate = home / 'repo-gate'
    while gate.exists():
        time.sleep(0.02)
    if state.get('repo_failure'):
        sys.exit(1)
    print(state['repo'])
else:
    raise AssertionError(f'Unexpected GitHub CLI request: {args!r}')
