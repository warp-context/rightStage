# Contributing to aiflow

Thanks for taking the time to contribute!

## Ways to help

- **Bug reports** — open an issue with your OS, shell version, and the exact error
- **Shell environment support** — fish, nushell, PowerShell patches welcome
- **AI tool integrations** — new workflows for Cursor, Copilot, Claude, etc.
- **Translations** — README in other languages

## Ground rules

- Keep it minimal. aiflow's value is that it has no dependencies and does one thing well.
- Shell scripts must pass [ShellCheck](https://www.shellcheck.net/) with no warnings.
- Test on macOS (BSD sed) and Linux (GNU sed) — they behave differently.

## Submitting a PR

1. Fork the repo and create a branch from `main`
2. Make your changes in `bin/`
3. Run ShellCheck: `shellcheck bin/*.sh`
4. Open a PR with a clear description of what and why

## Running locally

```bash
git clone https://github.com/warp-context/rightStage
cd rightStage && bash install.sh

# Test with the included example project
ai_inject examples/my_project
ai_done examples/my_project
```

## Reporting a bug

Please include:
- OS and shell version (`uname -a`, `bash --version`)
- The command you ran
- The full output / error message
