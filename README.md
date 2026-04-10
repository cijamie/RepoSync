# RepoSync

> A lightweight Windows batch utility that automates a safe, interactive `git pull` + `git commit` + `git push` workflow for any Git repository.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Requirements](#requirements)
- [When to Use RepoSync](#when-to-use-reposync)
- [Limitations](#limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

RepoSync is a single `reposync.bat` script designed to quickly synchronize your local repository with its remote without losing uncommitted work. It automatically detects the current repository root, active branch, and default remote, then performs a conflict-aware pull, prompts you for a commit message, and pushes your changes — all in one command.

---

## Features

- **Auto-detection** of repo root via `git rev-parse --show-toplevel`
- **Auto-detection** of the current branch via `git branch --show-current`
- **Auto-detection** of the remote (prefers `origin`, falls back to first available remote)
- **Safe handling** of uncommitted changes via a temporary commit before pull
- **Linear history** via `git pull --rebase` to avoid unnecessary merge commits
- **Automatic cleanup** of the temporary commit using `git reset --soft HEAD~1`
- **Interactive commit prompt** with an auto-generated fallback message (includes date and time)
- **Clear console output** with labeled step-by-step status messages
- **Graceful exit** when not run inside a valid Git repository

---

## How It Works

RepoSync runs through a numbered 7-step sequence every time you execute `reposync.bat` inside a Git repository.

### Step 1 — Dynamic Identity Detection

Before anything else, the script identifies where it is and what it is working with:

- Runs `git rev-parse --show-toplevel` to locate the repo root → stored in `REPO_ROOT`
- Runs `git branch --show-current` to detect the active branch → stored in `BRANCH`
- Runs `git remote` and selects `origin` if available, otherwise falls back to the first listed remote → stored in `REMOTE`
- If `REPO_ROOT` is empty (not a Git repo), the script prints:
  ```
  [ERROR] This folder is not a Git repository.
  ```
  ...and exits immediately.

The terminal title is then set to `Git Sync - <branch> @ <remote>` and a header banner is displayed.

---

### `[1/7]` — Change Detection

```bat
git status --porcelain | findstr . >nul
```

- If **no changes** are found, the script skips ahead to the pull-only flow.
- If **changes exist**, it proceeds to the temporary commit step.

---

### `[2/7]` — Temporary Auto-Commit

When uncommitted changes are detected:

```bat
git add -A
git commit -m "TEMP: auto-staged changes before sync"
```

- This protects your local work from being overwritten during the rebase pull.
- If the commit fails (e.g., nothing actually staged), the script falls back to a pull-only flow.

---

### `[3/7]` — Rebase Pull from Remote

```bat
git pull --rebase <REMOTE> <BRANCH>
```

- Fetches and rebases the remote changes on top of your local commits to keep history clean and linear.
- If a **rebase conflict** is detected, the script stops and prints:
  ```
  Resolve manually: git add . && git rebase --continue
  ```
  You must resolve the conflicts yourself and then continue the rebase before re-running RepoSync.

---

### `[4/7]` — Temporary Commit Removal

After a successful rebase:

```bat
git reset --soft HEAD~1
```

- Drops the `TEMP` commit created in step 2 while keeping all your changes staged and ready to commit properly.

---

### `[5/7]` — Final Change Check

```bat
git status --porcelain | findstr . >nul
```

- Checks again whether there are any changes remaining after the rebase.
- If there are none, it prints `No changes to commit.` and jumps directly to the push step.

---

### `[6/7]` — Interactive Commit

You are prompted:

```
[ENTER COMMIT MESSAGE (or leave blank for auto)]:
```

- If you provide a message, that message is used.
- If you leave it blank, a default is generated:
  ```
  Update <DATE> <TIME>
  ```
- Then stages and commits:
  ```bat
  git add -A
  git commit -m "<your message or auto message>"
  ```

---

### `[7/7]` — Push to Remote

```bat
git push <REMOTE> <BRANCH>
```

- On success:
  ```
  [ SUCCESS - Repository synced! ]
  ```
- On failure:
  ```
  [ PUSH FAILED - Check your credentials or remote status ]
  ```
- The script then pauses so you can read the output before the window closes.

---

## Installation

RepoSync is distributed as a single Windows batch file — `reposync.bat`. No installer or dependencies beyond Git are required.

### Option 1 — Single Project Use

1. Download `reposync.bat` from this repository (use **Download raw file** on the GitHub file view, or clone the repo).
2. Drop `reposync.bat` into the root directory of your Git project.
3. Run it from a terminal or by double-clicking.

### Option 2 — Global Use (Recommended)

1. Place `reposync.bat` in a dedicated scripts directory, for example:
   ```
   C:\Tools\git-scripts\reposync.bat
   ```
2. Add that directory to your system `PATH`:
   - Open **System Properties** → **Advanced** → **Environment Variables**
   - Under **System variables**, find `Path` and click **Edit**
   - Add the path to your scripts directory (e.g., `C:\Tools\git-scripts`)
   - Click **OK** and restart any open terminals
3. Now you can run `reposync` from any Git repository on your system.

---

## Usage

### From a Terminal (Recommended)

1. Open a terminal inside your repository root.
2. Run:
   ```bat
   reposync
   ```
3. Follow the on-screen prompts.

### By Double-Clicking

- Navigate to the repo root in File Explorer.
- Double-click `reposync.bat`.
- A Command Prompt window will open, run all 7 steps, and pause at the end so you can review the results.

### Example Session

```
============================================================
   UNIVERSAL REPOSITORY SYNC UTILITY
   Branch : main
   Remote : origin
============================================================

[1/7] Checking for local changes...
      Changes detected.

[2/7] Creating temporary commit...
      Temporary commit created.

[3/7] Pulling from origin/main (rebase)...
      Rebase successful.

[4/7] Removing temporary commit...
      Temporary commit removed.

[5/7] Checking for changes to commit...
      Changes found.

[6/7] Committing changes...
[ENTER COMMIT MESSAGE (or leave blank for auto)]: Implement login page
      Committed: Implement login page

[7/7] Pushing to origin/main...
      [ SUCCESS - Repository synced! ]

Press any key to continue . . .
```

---

## Requirements

| Requirement | Details |
|---|---|
| Operating System | Windows (uses `cmd.exe` batch syntax) |
| Git | Must be installed and available on `PATH` |
| Repository | Must be run from inside a valid Git repository |
| Remote Access | Credentials must be configured (SSH key or credential manager) |

---

## When to Use RepoSync

RepoSync is most helpful when you:

- Make quick edits across multiple files and want a **one-shot sync command** instead of chaining `git add`, `git commit`, `git pull`, and `git push` manually.
- Work on a branch and want to **regularly rebase onto the remote** to keep a clean, linear history.
- Frequently **forget to commit before pulling**, risking conflicts with your uncommitted local changes.
- Want a **beginner-friendly** Git workflow without memorizing multiple commands.

---

## Limitations

- **Windows only.** The script uses `cmd.exe` batch syntax and is not compatible with Linux or macOS without modification.
- **All files are staged.** RepoSync always uses `git add -A`, so every tracked change and untracked new file in the working directory will be included in the commit. Selective staging is not supported.
- **Single remote and branch.** RepoSync is designed for a standard workflow with one primary remote. Complex multi-remote or multi-branch setups may require manual commands.
- **No automated conflict resolution.** If a rebase conflict occurs, the script stops and requires you to resolve it manually before continuing.
- **No dry-run mode.** The script executes all steps live. There is no preview or simulation option.

---

## Contributing

Contributions are welcome. If you have ideas for improvements — such as logging, dry-run mode, Linux/macOS support, or selective staging — feel free to:

1. Fork the repository.
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit them.
4. Push to your fork and open a Pull Request.

Please open an issue first if you plan a significant change so it can be discussed before implementation.

---

## License

A license has not yet been formally defined for this repository. Until one is added, all rights are reserved. Do not redistribute or relicense without explicit permission from the repository owner.

---

*Made by [cijamie](https://github.com/cijamie)*
