# Agent Shell evaluation notes

Context: evaluating `xenodium/agent-shell` for Doom Emacs usage.

Summary:

- Agent Shell is a native Emacs UI for ACP agents, built on `acp.el`, `shell-maker`, and `comint`.
- It is actively maintained and has Doom install docs: `(package! shell-maker)`, `(package! acp)`, `(package! agent-shell)`, followed by `doom sync`.
- It includes provider adapters for Hermes, Claude, Codex, Gemini, Goose, OpenCode, Qwen, Kiro, and others.
- It stores project data under `.agent-shell/` by default and may auto-add that directory to `.gitignore`.

Doom pilot recommendation:

```elisp
;; packages.el
(package! shell-maker)
(package! acp)
(package! agent-shell)

;; config.el
(after! agent-shell
  ;; Agent Shell upstream currently uses symbols in this default; Emacs
  ;; process APIs expect command names as strings.
  (setq agent-shell-hermes-acp-command
        '("hermes" "acp"))

  ;; Start conservatively until the permission/write flow is trusted.
  (setq agent-shell-text-file-capabilities nil)

  ;; Optional: prefer Hermes when invoking `agent-shell`.
  (setq agent-shell-preferred-agent-config 'hermes))
```

If GUI Emacs has a reduced PATH, use an absolute Hermes command path instead of `"hermes"`.

Known pitfall:

- `agent-shell-hermes-acp-command` was observed upstream as `'(hermes acp)`, a list of symbols. `executable-find` and `make-process` expect command strings, so override it with strings in Doom config.

OpenCode caution:

- Agent Shell's OpenCode adapter defaults to `("opencode" "acp")`.
- OpenCode ACP advertises TCP server options (`--port`, `--hostname`, mDNS). Do not assume compatibility with `acp.el`'s stdio process client; smoke-test before enabling OpenCode through Agent Shell.

Safety defaults:

- Keep `agent-shell-text-file-capabilities` nil for an initial trial.
- Do not globally enable auto-approval helpers such as `agent-shell-permission-allow-always`.
- Add keybindings only after the basic Hermes flow works.
