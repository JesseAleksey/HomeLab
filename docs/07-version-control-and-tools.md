# 07 · Version control and tools

## Goal

Keep the homelab config and docs in a GitHub repo without ever committing private data.

## What I built

- Repo [`JesseAleksey/HomeLab`](https://github.com/JesseAleksey/HomeLab), linked to the existing `~/homelab` folder on the server.
- `gh` signed in over HTTPS; commits use the GitHub no-reply email address.

### What's in git

```bash
git ls-files
# .gitignore  CHANGELOG.md  README.md  docker-compose.yml  health-check.sh
# docs/*.md   docs/screenshots/.gitkeep   docs/screenshots/*.png
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
   git config --global user.email "157409608+JesseAleksey@users.noreply.github.com"
   ```
4. Turn the existing `~/homelab` folder into a repo and connect it to GitHub:
   ```bash
   cd ~/homelab
   git init -b main
   git remote add origin https://github.com/JesseAleksey/HomeLab.git
   git pull origin main
   ```
   The pull failed because of the local `.gitignore` ([below](#git-pull-fails-untracked-working-tree-files-would-be-overwritten-gitignore)).

## Verification

```bash
gh auth status            # Logged in to github.com account JesseAleksey, protocol https
git status --ignored      # adguard/ and jellyfin/ listed as ignored
git ls-files              # only the files listed above
```

Checked 2026-11-23: `gh` is logged in over HTTPS, and `git config --global user.email` is the no-reply address `157409608+JesseAleksey@users.noreply.github.com`.

The server's time zone is `America/Chicago` (set 2026-11-23, see [02](02-ubuntu-install.md#5-time-zone)), so new commits show local time (`-0600` in winter). Commits made before the change show UTC (`+0000`).

### Screenshots

Screenshots go in [`docs/screenshots/`](screenshots/). AdGuard and Jellyfin screens can show client IPs, query logs, usernames and API keys, so crop or blur them before committing.

## AI assistance

I used Claude Code as an assistant for drafting configs and docs. I reviewed every command before it ran and verified the results on the live system.

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
git pull origin main
cat .gitignore.local >> .gitignore    # then remove any duplicate lines
rm .gitignore.local
git add .gitignore
git commit -m "Merge local .gitignore rules"
git push -u origin main    # first push: sets origin/main as upstream, later pushes are just `git push`
```

Before pushing, check `git status --ignored` and `git ls-files` ([Verification](#verification)). If a data folder was already committed, untrack it without deleting it: `git rm -r --cached adguard jellyfin`.

## What I learned

- Check what's being uploaded before every push to a public repo. A `.gitignore` plus `git ls-files` keeps logs and password hashes private.
- Git conflicts are protective, not broken. "Untracked files would be overwritten" meant git was refusing to destroy my local file.
- AI tools speed up the work but need supervision. The assistant guessed wrong when it lacked context, so I gave it written context, reviewed every command and checked results on the live system.
- Documentation has to match reality. Verifying the live system before writing things down caught real mistakes in my own docs.

## Next steps

- [x] Set the server's time zone to `America/Chicago` for local commit times (`sudo timedatectl set-timezone America/Chicago`).
- [ ] Keep [CHANGELOG.md](../CHANGELOG.md) updated with each change.
