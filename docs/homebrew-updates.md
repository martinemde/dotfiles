# Homebrew updates

Use Homebrew's normal update and upgrade path weekly rather than leaving security
fixes until a manual full-tool update. A user LaunchAgent runs Sunday at 10:00 local
time, independently of shell startup or chezmoi apply. launchd catches a missed
calendar event after sleep; the user must be logged in. This is not an unattended
system update service or a vulnerability-specific security feed.

No sudo, third-party taps, `--greedy`, or verification bypasses are added. Default
Homebrew behavior leaves pinned formulae and auto-updating/latest casks alone.
The trade-off is accepting current Homebrew-reviewed formulae without a seven-day
quarantine. Homebrew verification establishes expected bytes, not benign code.
Brewfile reconciliation still uses `--no-upgrade`.

The agent is registered on chezmoi apply; adding the source files does not start
an upgrade. Logs: `~/Library/Logs/dotfiles-homebrew.log`. Failures remain in the log
and launchd exit status; no tight retry loop. Run `update-homebrew` for an immediate
retry. It does not update mise tools, editor plugins, or Mac App Store apps.
