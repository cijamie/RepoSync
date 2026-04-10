# RepoSync

> A lightweight, elite Windows batch utility that automates a safe, interactive `git pull` + `git commit` + `git push` workflow for any Git repository.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Usage & Commands](#usage--commands)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Requirements](#requirements)
- [License](#license)

---

## Overview

RepoSync is a single `reposync.bat` script designed to quickly synchronize your local repository with its remote without losing uncommitted work. It is built for developers who want a "one-shot" sync command that handles safety, rebase, and push automatically.

---

## Features

- **🚀 One-Shot Sync**: Pass your commit message as an argument to skip all prompts.
- **🛡️ Branch Protection**: Visual warnings when working on `main`, `master`, or `prod`.
- **🔍 Dry-Run Mode**: See exactly what would happen without modifying your files.
- **🛠️ Self-Healing Recovery**: Automatically detects and fixes interrupted rebases or leftover `TEMP` commits.
- **📊 Changelog Summary**: Shows a concise list of modified files before committing.
- **🎨 ANSI Color Support**: Clean, professional, and readable terminal output.
- **🔗 Smart Upstream Detection**: Automatically tracks your branch's configured remote.

---

## Usage & Commands

### Standard Interactive Sync
Just run the script and follow the prompts.
```bat
reposync
```

### Fast Sync (Skip Prompt)
Provide your commit message as the first argument.
```bat
reposync "Fix layout issues on mobile"
```

### Dry-Run Mode
Test the sync process without applying any changes.
```bat
reposync --dry
# or
reposync -d
```

---

## How It Works

1. **Step 0: Connectivity Check** — Verifies remote reachable.
2. **Step 1: Change Detection** — Identifies local work.
3. **Step 2: Temporary Auto-Commit** — Protects work during rebase.
4. **Step 3: Rebase Pull** — Syncs with remote.
5. **Step 4: Temp Removal** — Unstages changes for your message.
6. **Step 5: Final Check** — Confirms if commit is needed.
7. **Step 6: Summary & Commit** — Shows modified files and prompts for message (or uses argument).
8. **Step 7: Push** — Sends synchronized work to remote.

---

## Installation

### 🚀 Quick Download
**Right-click the link below and select "Save link as..."**
[**Download reposync.bat (v2.2)**](https://raw.githubusercontent.com/cijamie/RepoSync/main/reposync.bat)

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

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details. Fully open source and free for all.

---

*Made by [cijamie](https://github.com/cijamie)*
