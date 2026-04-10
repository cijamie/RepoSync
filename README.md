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

- **ANSI Color Support** for clear, professional terminal output.
- **Pre-flight Connectivity Check** to catch network/credential issues early.
- **Robust Upstream Detection** using `git rev-parse --abbrev-ref @{u}`.
- **ISO-8601 Standardized Timestamps** for consistent auto-commit messages.
- **Auto-detection** of repo root via `git rev-parse --show-toplevel`.
- **Safe handling** of uncommitted changes via a temporary commit before pull.
- **Linear history** via `git pull --rebase` to avoid unnecessary merge commits.
- **Interactive commit prompt** with an auto-generated fallback message.

---

## How It Works

RepoSync runs through a numbered sequence every time you execute `reposync.bat` inside a Git repository.

### Step 0 — Connectivity Check
Before starting, RepoSync runs `git ls-remote` to ensure the remote is reachable. This prevents the script from failing halfway through a sync if you are offline.

### Step 1 — Change Detection
Checks for local changes using `git status --porcelain`.

### Step 2 — Temporary Auto-Commit
If changes are detected, they are staged and committed with a `TEMP` message to protect them during the rebase.

### Step 3 — Rebase Pull from Remote
Fetches and rebases the remote changes on top of your local work.

### Step 4 — Temporary Commit Removal
Drops the `TEMP` commit while keeping your changes staged and ready for a proper message.

### Step 5 — Final Change Check
Verifies if there are still changes to commit after the rebase.

### Step 6 — Interactive Commit
Prompts for a commit message. If left blank, it generates one using an ISO-8601 timestamp (`YYYY-MM-DD HH:MM`).

### Step 7 — Push to Remote
Pushes your synchronized work to the remote repository.

---

## Installation

RepoSync is distributed as a single Windows batch file — `reposync.bat`.

### Option 1 — Single Project Use
1. Download `reposync.bat`.
2. Drop it into the root of your Git project.
3. Run it.

### Option 2 — Global Use (Recommended)
1. Place `reposync.bat` in a dedicated scripts directory (e.g., `C:\Tools\`).
2. Add that directory to your system `PATH`.
3. Run `reposync` from any Git repository on your system.

---

## Requirements

| Requirement | Details |
|---|---|
| Operating System | Windows 10+ (for ANSI color support) |
| Git | Must be installed and available on `PATH` |
| PowerShell | Used for standardized timestamp generation |

---

## License

A license has not yet been formally defined for this repository. Until one is added, all rights are reserved.

---

*Made by [cijamie](https://github.com/cijamie)*
