# 07 · GitHub and Claude Code

## Goal

Keep the homelab config and docs in a GitHub repo without ever committing private data, and use Claude Code on the server to help run and document it.

## What I built

- Repo [`JesseAleksey/HomeLab`](https://github.com/JesseAleksey/HomeLab), cloned at `~/homelab` on the server.
- `gh` signed in over HTTPS; commits use the GitHub no-reply email address.
- Claude Code (native installer, at `~/.local/bin/claude`), logged in with a Claude Pro plan.
- [`CLAUDE.md`](../CLAUDE.md): rules and context for Claude Code in this repo. Summary of the rules:
  1. Never stop, restart, recreate or update the `adguard` container without asking (it's the house DNS).
  2. Explain each command before running it.
  3. Never commit `adguard/` or `jellyfin/`.

### What's in git

```bash
git ls-files
# .gitignore  CHANGELOG.md  CLAUDE.md  README.md  docker-compose.yml  health-check.sh
# docs/*.md   docs/screenshots/.gitkeep
```

## Steps

1. On github.com, create `HomeLab` **with a README and a `.gitignore`**.
2. On the server, sign in with `gh`. There's no browser on the server, so use the device code:
   ```bash
   gh auth login     # GitHub.com → HTTPS → Login with a web browser
   ```
   Enter the one-time code shown on another device's browser.
3. Use the no-reply address for commits (find it under *GitHub → Settings → Emails*):
   ```bash
   git config --global user.email "<id>+<username>@users.noreply.github.com"
   ```
4. Clone it: `gh repo clone JesseAleksey/HomeLab ~/homelab`.
5. Install Claude Code with the native installer:
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```
   Then run `claude` in `~/homelab` and log in with the Pro account ([below](#claude-code-login-pro-is-required)).

## Verification

```bash
gh auth status            # Logged in to github.com account JesseAleksey, protocol https
claude --version
git status --ignored      # adguard/ and jellyfin/ listed as ignored
git ls-files              # only the files listed above
```

Checked 2026-11-23: `gh` is logged in over HTTPS, Claude Code 2.1.330, and the commit email is a no-reply address.

The server's time zone is `America/Chicago` (set 2026-11-23, see [02](02-ubuntu-install.md#time-zone)), so new commits show local time (`-0600` in winter). Commits made before the change show UTC (`+0000`).

### Screenshots

Screenshots go in [`docs/screenshots/`](screenshots/). AdGuard and Jellyfin screens can show client IPs, query logs, usernames and API keys, so crop or blur them before committing.

## Problems and fixes

### `git pull` fails: "untracked working tree files would be overwritten" (`.gitignore`)

The repo was created on GitHub with a `.gitignore`, and another `.gitignore` was also created locally but never committed. `git pull` refused:

```
error: The following untracked working tree files would be overwritten by merge:
	.gitignore
Please move or remove them before you merge.
```

Fix: move the local file aside, pull, then add its rules to the pulled version:

```bash
mv .gitignore .gitignore.local
git pull
cat .gitignore.local >> .gitignore    # then remove any duplicate lines
rm .gitignore.local
git add .gitignore
git commit -m "Merge local .gitignore rules"
git push
```

Before pushing, check `git status --ignored` and `git ls-files` ([Verification](#verification)). If a data folder was already committed, untrack it without deleting it: `git rm -r --cached adguard jellyfin`.

### Claude Code login: "Pro is required"

The first login failed with "Pro is required", because the browser was signed in to the wrong Claude account.

Fix: switch the browser to the account with the Pro plan, then log in again.

## What I learned

- Creating files on GitHub's web UI and locally at the same time causes pull conflicts. Pick one place to create them.
- Device-code login is the way to authenticate a headless server.
- Check which account the browser is signed in to before an OAuth login.
- A CLAUDE.md with hard rules (like "don't touch AdGuard") makes an assistant safer on a live server.
- TODO: add your own notes.

## Next steps

- [x] Set the server's time zone to `America/Chicago` for local commit times (`sudo timedatectl set-timezone America/Chicago`).
- [ ] Keep [CHANGELOG.md](../CHANGELOG.md) updated with each change.
