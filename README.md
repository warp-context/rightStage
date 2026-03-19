# aiflow

> Stop rewriting AI context. Every terminal window, always in sync.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![ShellCheck](https://github.com/warp-context/rightStage/actions/workflows/ci.yml/badge.svg)](https://github.com/warp-context/rightStage/actions)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows%20Git%20Bash-blue)

**aiflow** keeps your AI context in sync across every terminal window. Drop a `progress.md` in your project — any window, any moment, one command to know where you are and paste the right context into your AI.

No daemon. No server. No config. Just three shell scripts and a markdown file.

![aiflow demo](docs/demo.gif)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/warp-context/rightStage/main/install.sh | bash
```

<details>
<summary>Or clone and install manually</summary>

```bash
git clone https://github.com/warp-context/rightStage
cd aiflow && bash install.sh
```

</details>

---

## The problem

You open a new terminal window. You forget where you left off. You spend two minutes re-reading your notes before you can write a single prompt. You do this ten times a day.

| Problem | aiflow's fix |
|---|---|
| Switched windows, forgot where you were | `progress.md` is the single source of truth |
| Rewriting context for AI every time | `ai_inject` assembles it in < 100 lines |
| `progress.md` drifts out of sync | Auto-derived from git commit messages |
| Multiple windows, different context | All windows read the same file — always in sync |

---

## 30-second quickstart

**Step 1** — create your task list (once per project):

```bash
mkdir -p .ai && cat > .ai/progress.md << 'EOF'
[1] Login UI        done
[2] API integration  doing
[3] Error handling   todo
[4] Unit tests       todo
EOF
```

**Step 2** — inject context into your AI:

```bash
ai_inject .                          # print context
ai_inject -c .                       # print + copy to clipboard
ai_inject -c . "help me with retry"  # include your prompt too
```

**Step 3** — commit with a task number:

```bash
git commit -m "[2] API integration complete"
# Next time you run ai_inject, [2] is automatically marked done
```

That's it. Any window. Any time. Always in sync.

---

## Commands

### `ai_inject [options] [project_dir] ["your prompt"]`

Generates the minimal context block to paste into your AI.

```
Options:
  -c, --copy      Copy output to clipboard
  -n, --no-update Skip auto-sync from git
  -h, --help      Show help
```

Output (auto-assembled, < 100 lines):

```
[CURRENT]    what you're working on right now
[NEXT]       the task after this one
[GOAL]       project goal (first 15 lines)
[API]        API spec (first 10 lines, optional)
[CONSTRAINT] tech constraints (first 10 lines, optional)
[ISSUES]     last 3 known failure notes (optional)
[INPUT]      your prompt
```

### `ai_progress [project_dir]`

Reads your git log and updates `progress.md` automatically.

- Commit message contains `[2]` or matches a task name → marked `done`
- First unfinished task → `doing`
- Rest → `todo`

Runs automatically inside `ai_inject` (skip with `-n`).

### `ai_done [project_dir]`

Marks the current `doing` task as `done`, promotes the next `todo` to `doing`.

---

## File structure

```
your-project/
└── .ai/
    ├── progress.md        ← the only file you write
    └── ctx/               ← auto-generated, do not edit
        ├── 00_goal.md     ← project goal (optional, you write once)
        ├── 02_current.md  ← auto-generated
        ├── 03_next.md     ← auto-generated
        ├── 04_constraint.md  ← tech constraints (optional)
        ├── 05_api.md         ← API spec (optional)
        └── 07_issue.md       ← known issues log (optional)
```

**Global fallback:** `~/.ai/ctx/` — shared defaults across all projects.

---

## Works with any AI

| Tool | How |
|---|---|
| Warp AI | `ai_inject -c .` → paste in the AI input bar |
| Claude / ChatGPT | `ai_inject -c . "your question"` → paste in chat |
| Cursor / Copilot | Paste into system prompt or first message |
| Any LLM | Same — it's just text |

---

## Supported platforms

- macOS (zsh / bash)
- Linux (bash)
- Windows Git Bash

---

## Design principles

1. **Context is runtime state, not documentation** — written for the model, not for humans
2. **Current task first** — CURRENT > NEXT > everything else
3. **Must self-update** — anything requiring manual maintenance will rot
4. **Token-minimal** — < 100 lines keeps the model sharp

---

## Uninstall

```bash
rm ~/.local/bin/ai_inject ~/.local/bin/ai_progress ~/.local/bin/ai_done
rm -rf ~/.ai   # optional: removes global context dir
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome — especially for new shell environments or AI tool integrations.

If aiflow saves you time, consider starring the repo. It helps others find it.

---

## License

MIT — see [LICENSE](LICENSE)

---

<details>
<summary>中文文档</summary>

## 核心思路

> 让任何一个终端窗口，在 3 秒内知道"现在该干嘛"。

| 常见问题 | aiflow 的解法 |
|---|---|
| 换个窗口就忘了做到哪 | `progress.md` 是唯一状态源 |
| 每次要手写上下文给 AI | `ai_inject` 自动拼装，控制在 100 行内 |
| progress 手动维护容易忘 | 从 git commit 自动推导 |
| 多窗口上下文不同步 | 所有窗口读同一份文件，天然同步 |

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/warp-context/rightStage/main/install.sh | bash
```

## 快速上手

**第一步：** 在项目根目录创建 `.ai/progress.md`

```text
[1] 登录UI     done
[2] API接入    doing
[3] 错误处理   todo
[4] 单元测试   todo
```

**第二步：** 任意窗口运行

```bash
ai_inject .           # 查看当前状态
ai_inject -c .        # 复制到剪贴板
ai_inject -c . "帮我实现错误处理的 retry 逻辑"
```

**第三步：** commit 带编号，下次自动推进

```bash
git commit -m "[2] 完成API接入，支持token刷新"
```

## 设计原则

1. **上下文是运行态，不是文档** — 写给模型用，不是给人看
2. **当前态优先** — CURRENT > NEXT > 其他
3. **必须能自动更新** — 靠人手维护必崩
4. **Token 极省** — 控制在 100 行以内，避免降智

</details>
