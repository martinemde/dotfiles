#!/usr/bin/env python3
"""A/B eval for agent instruction files (CLAUDE.md, AGENTS.md, skills).

Runs the same probes with headless `claude -p` in a baseline checkout and a
candidate checkout, grades each answer, and reports pass rates plus the token
cost of the always-loaded instructions.

    eval.py PROBES.json --baseline DIR --candidate DIR [--reps 3] [-j 4] [--out results.json]

A probe file is a JSON object:

    {
      "config_dirs": {"baseline": "...", "candidate": "..."},   # optional CLAUDE_CONFIG_DIR per arm
      "probes": [
        {
          "id": "add-package",
          "covers": "Package Manager section",          # what removed text this guards
          "prompt": "...",
          "max_turns": 8,                                # optional
          "must": ["\\bbun add\\b"],                     # every regex must match (case-insensitive)
          "must_not": ["npm install"],                   # no regex may match
          "judge": "PASS if ..."                         # optional rubric for an LLM judge
        }
      ]
    }

The probe environment is isolated from the session running this script: extra
CLAUDE.md directories are unset, so only the arm's own instructions load.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

READ_ONLY_TOOLS = "Read,Grep,Glob,Bash"
JUDGE_MODEL = "sonnet"
NEGATION = re.compile(r"\b(not|skip|don't|do not|never|avoid|instead of|rather than|deprecated|wrong|no longer|doesn't|does not|unsupported|isn't)\b", re.I)
ALLOWED = [
    "Read", "Grep", "Glob", "Skill", "Agent", "Bash(jj log:*)", "Bash(jj help:*)", "Bash(jj --version)", "Bash(jj tag list:*)",
    "Bash(jj git push --help)", "Bash(jj bookmark list:*)", "Bash(jj status)",
    "Bash(chezmoi diff:*)", "Bash(rg:*)",
    "Bash(ls:*)", "Bash(cat:*)", "Bash(head:*)", "Bash(git log:*)", "Bash(git show:*)",
    "Bash(wc:*)", "Bash(find:*)", "Bash(grep:*)", "Bash(jq:*)",
]
SUFFIX = (
    "\n\nThis is a planning question: do not modify any files or run anything that "
    "changes state. Answer with the exact commands, paths and values you would use."
)


def child_env(config_dir):
    env = dict(os.environ)
    for key in ("CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD", "CLAUDE_ADDITIONAL_DIRECTORIES"):
        env.pop(key, None)
    if config_dir and os.path.isdir(os.path.join(config_dir, ".claude")):
        # A fake home: user instructions, skills and agents under ~/.claude, ~/.agents
        env["HOME"] = config_dir
        env["CLAUDE_CONFIG_DIR"] = os.path.join(config_dir, ".claude")
        # Without this, account skills sync into .claude/skills, which is usually a
        # symlink into the checkout under test.
        settings = os.path.join(config_dir, ".claude", "settings.json")
        if not os.path.exists(settings):
            with open(settings, "w") as f:
                json.dump({"syncClaudeAiSkills": False}, f)
    elif config_dir:
        env["CLAUDE_CONFIG_DIR"] = config_dir
    return env


def claude(cwd, prompt, config_dir=None, tools=READ_ONLY_TOOLS, max_turns=8, model=None, timeout=600):
    cmd = ["claude", "-p", prompt, "--output-format", "json", "--max-turns", str(max_turns),
           "--tools", tools]
    if tools:
        cmd += ["--allowedTools", *ALLOWED]
    if model:
        cmd += ["--model", model]
    try:
        out = subprocess.run(cmd, cwd=cwd, env=child_env(config_dir), capture_output=True,
                             text=True, timeout=timeout)
        data = json.loads(out.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError) as exc:
        return {"result": f"<<harness error: {exc}>>", "total_cost_usd": 0, "num_turns": 0, "usage": {}}
    return data


def judge(rubric, prompt, answer):
    q = (f"You grade an AI assistant's answer against a rubric. Judge only what the rubric asks; "
         f"ignore style, length and extra content.\n\n<rubric>\n{rubric}\n</rubric>\n\n"
         f"<question>\n{prompt}\n</question>\n\n<answer>\n{answer}\n</answer>\n\n"
         f"Explain in one or two sentences, then end with a final line that is exactly "
         f"VERDICT: PASS or VERDICT: FAIL.")
    res = claude("/", q, tools="", max_turns=1, model=JUDGE_MODEL)
    verdict = (res.get("result") or "").strip()
    found = re.findall(r"VERDICT:\s*(PASS|FAIL)", verdict, re.I)
    return bool(found) and found[-1].upper() == "PASS", verdict


def grade(probe, answer):
    reasons = []
    for rx in probe.get("must", []):
        if not re.search(rx, answer, re.I | re.S):
            reasons.append(f"missing /{rx}/")
    # A forbidden pattern only counts on lines that don't reject it ("don't use X").
    affirmative = "\n".join(l for l in answer.splitlines() if not NEGATION.search(l))
    for rx in probe.get("must_not", []):
        if re.search(rx, affirmative, re.I | re.S):
            reasons.append(f"forbidden /{rx}/")
    ok = not reasons
    if ok and probe.get("judge"):
        ok, verdict = judge(probe["judge"], probe["prompt"], answer)
        if not ok:
            reasons.append(f"judge: {verdict}")
    return ok, reasons


def run_one(job):
    arm, cwd, config_dir, probe, rep = job
    prompt = probe["prompt"] + ("" if probe.get("raw") else SUFFIX)
    for _ in range(2):  # an empty result means the run hit max_turns or errored; retry once
        res = claude(cwd, prompt, config_dir, tools=probe.get("tools", READ_ONLY_TOOLS),
                     max_turns=probe.get("max_turns", 8))
        if (res.get("result") or "").strip():
            break
    answer = res.get("result") or ""
    ok, reasons = grade(probe, answer)
    return {"arm": arm, "probe": probe["id"], "rep": rep, "pass": ok, "reasons": reasons,
            "cost": res.get("total_cost_usd", 0), "turns": res.get("num_turns", 0),
            "usage": {k: v for k, v in (res.get("usage") or {}).items() if k.endswith("tokens")},
            "models": list((res.get("modelUsage") or {}).keys()), "answer": answer}


def context_tokens(cwd, config_dir):
    """Input tokens for a no-tool turn: system prompt + always-loaded instructions.

    The instruction files are copied into an empty non-git directory so git status and
    recent commit messages in the system prompt don't skew the comparison."""
    import shutil, tempfile
    tmp = tempfile.mkdtemp(prefix="ctx-")
    for name in ("CLAUDE.md", "AGENTS.md"):
        if os.path.exists(os.path.join(cwd, name)):
            shutil.copyfile(os.path.join(cwd, name), os.path.join(tmp, name))
    res = claude(tmp, "Reply with exactly OK.", config_dir, tools="", max_turns=1)
    shutil.rmtree(tmp, ignore_errors=True)
    u = res.get("usage", {})
    return u.get("input_tokens", 0) + u.get("cache_creation_input_tokens", 0) + u.get("cache_read_input_tokens", 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("probes")
    ap.add_argument("--baseline", required=True)
    ap.add_argument("--candidate", required=True)
    ap.add_argument("--reps", type=int, default=3)
    ap.add_argument("-j", type=int, default=4)
    ap.add_argument("--only", help="comma-separated probe ids")
    ap.add_argument("--out")
    ap.add_argument("--tokens-only", action="store_true")
    ap.add_argument("--regrade", help="re-grade answers stored in a previous --out file")
    args = ap.parse_args()

    spec = json.load(open(args.probes))
    cfg = spec.get("config_dirs", {})
    probes = [{**spec.get("defaults", {}), **p} for p in spec["probes"]]
    if args.only:
        keep = set(args.only.split(","))
        probes = [p for p in probes if p["id"] in keep]
    arms = {"baseline": args.baseline, "candidate": args.candidate}

    jobs = [(arm, cwd, cfg.get(arm), p, r) for p in probes for arm, cwd in arms.items()
            for r in range(args.reps)]
    if args.tokens_only:
        for arm, cwd in arms.items():
            print(arm, context_tokens(cwd, cfg.get(arm)))
        return

    if args.regrade:
        old = json.load(open(args.regrade))
        by_id = {p["id"]: p for p in probes}
        keep = [r for r in old["results"] if r["probe"] in by_id]

        def regrade(r):
            ok, reasons = grade(by_id[r["probe"]], r["answer"])
            return {**r, "pass": ok, "reasons": reasons}

        with ThreadPoolExecutor(args.j) as pool:
            results = list(pool.map(regrade, keep))
        tokens = old["tokens"]
        for res in results:
            print(f"{'✓' if res['pass'] else '✗'} {res['arm']:9} {res['probe']} #{res['rep']} "
                  f"{'; '.join(res['reasons'])}", file=sys.stderr)
        return report(args, probes, arms, tokens, results)

    with ThreadPoolExecutor(args.j) as pool:
        tokens = dict(zip(arms, pool.map(lambda a: context_tokens(arms[a], cfg.get(a)), arms)))
        results = []
        for res in pool.map(run_one, jobs):
            results.append(res)
            mark = "✓" if res["pass"] else "✗"
            print(f"{mark} {res['arm']:9} {res['probe']} #{res['rep']} {'; '.join(res['reasons'])}",
                  file=sys.stderr)
    report(args, probes, arms, tokens, results)


def report(args, probes, arms, tokens, results):
    lines = [f"Always-loaded context (system prompt + instructions, no tools): "
             f"baseline {tokens['baseline']} tok, candidate {tokens['candidate']} tok "
             f"(Δ {tokens['candidate'] - tokens['baseline']:+d})", "",
             "| Probe | Guards | Baseline pass | Candidate pass | Baseline tok/run | Candidate tok/run |",
             "|---|---|---|---|---|---|"]

    # Tokens processed, not dollars: cost depends on whether an arm's prompt prefix happens
    # to be cached from an earlier run, which says nothing about the instructions.
    def tok(r):
        u = r.get("usage") or {}
        return sum(u.get(k, 0) for k in ("input_tokens", "cache_creation_input_tokens",
                                         "cache_read_input_tokens", "output_tokens"))

    def stats(rs):
        return (sum(r["pass"] for r in rs), len(rs), sum(tok(r) for r in rs) / max(len(rs), 1))

    for p in probes:
        cell = {arm: stats([r for r in results if r["probe"] == p["id"] and r["arm"] == arm]) for arm in arms}
        b, c = cell["baseline"], cell["candidate"]
        lines.append(f"| `{p['id']}` | {p.get('covers', '')} | {b[0]}/{b[1]} | {c[0]}/{c[1]} | "
                     f"{b[2]:,.0f} | {c[2]:,.0f} |")
    tb, tc = (stats([r for r in results if r["arm"] == a]) for a in ("baseline", "candidate"))
    cost = sum(r["cost"] for r in results)
    delta = (tc[2] - tb[2]) / tb[2] * 100 if tb[2] else 0
    lines.append(f"| **total** | | **{tb[0]}/{tb[1]}** | **{tc[0]}/{tc[1]}** | **{tb[2]:,.0f}** | "
                 f"**{tc[2]:,.0f}** ({delta:+.0f}%) |")
    lines += ["", f"{len(results)} runs, ${cost:.2f} total. Run arms serially (-j 1 per arm, or "
              "fresh prefixes) when comparing cost; concurrent runs share cache unevenly."]
    report = "\n".join(lines)
    print(report)
    if args.out:
        json.dump({"tokens": tokens, "results": results, "report": report}, open(args.out, "w"), indent=1)


if __name__ == "__main__":
    main()
