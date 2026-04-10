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
- [License](#license)

---

## Overview

RepoSync is a single `reposync.bat` script designed to quickly synchronize your local repository with its remote without losing uncommitted work. It automatically detects the current repository root, active branch, and default remote, then performs a conflict-aware pull, prompts you for a commit message, and pushes your changes — all in one command.

---

## Features

- **ANSI Color Support** for clear, professional terminal output.
- **Self-Healing Recovery** automatically detects interrupted rebases or leftover `TEMP` commits.
- **Changelog Summary** shows you exactly which files changed before you write your commit message.
- **Pre-flight Connectivity Check** to catch network/credential issues early.
- **Robust Upstream Detection** using `git rev-parse --abbrev-ref @{u}`.
- **ISO-8601 Standardized Timestamps** for consistent auto-commit messages.
- **Linear history** via `git pull --rebase` to avoid unnecessary merge commits.

---

## How It Works

1. **Step 0: Connectivity Check** — Verifies remote reachable.
2. **Step 1: Change Detection** — Identifies local work.
3. **Step 2: Temporary Auto-Commit** — Protects work during rebase.
4. **Step 3: Rebase Pull** — Syncs with remote.
5. **Step 4: Temp Removal** — Unstages changes for your message.
6. **Step 5: Final Check** — Confirms if commit is needed.
7. **Step 6: Summary & Commit** — Shows modified files and prompts for message.
8. **Step 7: Push** — Sends synchronized work to remote.

---

## Installation

### 🚀 Quick Download
**Right-click the link below and select "Save link as..."**
[**Download reposync.bat (v2.1)**](https://raw.githubusercontent.com/cijamie/RepoSync/main/reposync.bat)

### Global Setup (Recommended)
1. Place `reposync.bat` in a directory like `C:\Tools\`.
2. Add that directory to your system **PATH**.
3. Run `reposync` from any terminal in any Git repository.

---

## Requirements

| Requirement | Details |
|---|---|
| Operating System | Windows 10+ |
| Git | Installed and on PATH |
| PowerShell | Installed (standard on Windows) |

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details. It is fully open source and free to use, modify, and distribute.

---

*Made by [cijamie](https://github.com/cijamie)*
