# Quickstart

## 5-minute walkthrough

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/warp-context/rightStage/main/install.sh | bash

# 2. Go to your project
cd ~/myproject

# 3. Create your task list
mkdir -p .ai
cat > .ai/progress.md << 'EOF'
[1] Login UI        todo
[2] API integration  todo
[3] Error handling   todo
EOF

# 4. See current status
ai_inject .

# 5. Work, commit with task number
git commit -m "[1] Login UI done"

# 6. Next time you open a window — 3 seconds to orient
ai_inject .
```

## Works with any AI tool

### Warp AI

```bash
# Copy context to clipboard, paste into Warp AI input bar
ai_inject -c .
# Then Cmd+V — your AI instantly knows the context
```

### Claude / ChatGPT

```bash
# Copy context + your question, paste into the chat
ai_inject -c . "help me implement the retry logic"
```

### Shell alias (recommended)

Add to `~/.zshrc`:

```bash
alias aic='ai_inject -c .'
```

Then just:

```bash
aic "look at this bug"
```

## progress.md format

```text
# comment lines are ignored
[1] task name   done    # completed
[2] task name   doing   # in progress (only one at a time)
[3] task name   todo    # not started
```

**Tips:**
- Keep task names short (< 10 words)
- Match task names to your commit messages for accurate auto-detection

## git commit format

Formats that trigger auto-detection:

```text
[2] API integration done       ← recommended, number match is most reliable
[2] fix: API token refresh     ← also works
feat: API integration          ← matched by task name, must be exact
```

## Uninstall

```bash
rm ~/.local/bin/ai_inject ~/.local/bin/ai_progress ~/.local/bin/ai_done
# optionally remove global context dir
rm -rf ~/.ai
```
