# LM Studio + Pi setup for Iago

Run Iago locally with the same Agent Skills workflow you use in Cursor, backed by LM Studio instead of cloud models.

## Architecture

```
LM Studio (local model)  →  http://127.0.0.1:1234/v1
        ↓
Pi agent (read, bash, edit, write + skills)
        ↓
Iago repo (.cursor/skills → .pi/skills symlinks, data/ state)
```

Pi implements the [Agent Skills standard](https://agentskills.io). Iago skills in `.cursor/skills/*/SKILL.md` work in both Cursor and Pi without reformatting.

## 1. LM Studio

1. Open **LM Studio**.
2. Load a model (recommended for Iago agent work):
   - `qwen/qwen3.5-9b` (default)
   - `qwen/qwen2.5-coder-14b` (stronger coding/tool use)
   - `meta-llama-3.1-8b-instruct` (lighter, faster)
3. Go to **Local Server** (or Developer tab) → **Start Server**.
4. Confirm: `curl http://127.0.0.1:1234/v1/models` returns a model list.

### LM Studio settings that help

| Setting | Recommendation |
|---------|----------------|
| Context length | Set manually (e.g. 32k). Do not leave on auto for agent runs. |
| Unified KV Cache | Disable if you see 0% prompt stalls |
| Stop tokens (Gemma) | Add think-tag stop tokens if output leaks reasoning markers |

## 2. Pi (local agent)

Install once:

```bash
npm install -g @earendil-works/pi-coding-agent
```

Configure LM Studio as a provider in `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "lmstudio": {
      "name": "LM Studio",
      "baseUrl": "http://127.0.0.1:1234/v1",
      "api": "openai-completions",
      "apiKey": "lm-studio",
      "models": [
        { "id": "qwen/qwen3.5-9b", "name": "Qwen 3.5 9B", "contextWindow": 32768, "input": ["text"] },
        { "id": "qwen/qwen2.5-coder-14b", "name": "Qwen 2.5 Coder 14B", "contextWindow": 32768, "input": ["text"] }
      ]
    }
  }
}
```

Model `id` values must match LM Studio's server panel exactly.

## 3. Wire Iago skills

From your Iago clone (prod: `Iago/` in this vault):

```bash
cd /path/to/iago
bash scripts/install-pi-skills.sh
```

This:

- Symlinks `.cursor/skills/*` → `.pi/skills/*` (project discovery)
- Adds `~/.cursor/skills` and `.pi/skills` to `~/.pi/agent/settings.json`

If you already run `scripts/install-skills.sh` for Cursor, the global `~/.cursor/skills` symlinks are reused.

## 4. Preflight

```bash
bash scripts/verify-lm-studio.sh
```

Fix any failures before starting an agent session.

## 5. Interactive use

```bash
cd /path/to/iago
pi --approve --provider lmstudio --model qwen/qwen3.5-9b
```

In the Pi session:

```
/skill:iago-daily
Run the daily job search for today
```

Other skills:

| Task | Pi command |
|------|------------|
| Daily search | `/skill:iago-daily` |
| Pipeline review | `/skill:iago-pipeline-review` |
| Shortlist / apply | `/skill:update-application` |
| Company brief | `/skill:company-research` |
| Resume review | `/skill:resume-feedback` |
| Interview prep | `/skill:interview-prep` |
| First-time setup | `/skill:iago-setup` |

Switch models mid-session: `/model` or `Ctrl+L`.

## 6. Headless daily search

```bash
bash scripts/run-daily-search-pi.sh
```

Logs: `data/logs/latest-pi.log`

Override model:

```bash
PI_MODEL=qwen/qwen2.5-coder-14b bash scripts/run-daily-search-pi.sh
```

## 7. Optional: web search for job boards

Iago skills reference web search and browser tools (built into Cursor). Pi's default tools are `read`, `bash`, `edit`, `write`.

For better parity, install pi-skills:

```bash
pi install git:github.com/badlogic/pi-skills
```

Then use `/skill:brave-search` or documented curl/bash patterns from the skill when iago-daily needs live listings.

## Cursor vs Pi differences

| Cursor | Pi + LM Studio |
|--------|----------------|
| Skills in `.cursor/skills/` | Same files; also `.pi/skills/` symlinks |
| `AskQuestion` tool | Ask in chat |
| Built-in web search / browser MCP | bash/curl or pi-skills |
| `cursor agent -p` headless | `pi -p` or `run-daily-search-pi.sh` |
| Cloud models | Local LM Studio models |

Skills that say "use browser for SPAs" still work: Pi can curl/fetch or use pi-skills browser helpers where available.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Connection refused on :1234 | Start LM Studio local server; load a model |
| Pi hangs on first prompt | Model not loaded in LM Studio; try a smaller model |
| Skill not found | Run `bash scripts/install-pi-skills.sh`; use `/skill:name` explicitly |
| Context overflow | Use smaller model, shorter session, or reduce loaded skills (`--no-skills --skill .cursor/skills/iago-daily`) |
| Poor tool use | Switch to `qwen/qwen2.5-coder-14b` |

## Files added by this setup

| Path | Purpose |
|------|---------|
| `~/.pi/agent/models.json` | LM Studio provider config |
| `~/.pi/agent/settings.json` | Skill paths + defaults |
| `.pi/skills/` | Symlinks to `.cursor/skills/` |
| `AGENTS.md` | Pi project context |
| `scripts/install-pi-skills.sh` | Skill wiring |
| `scripts/verify-lm-studio.sh` | Preflight checks |
| `scripts/run-daily-search-pi.sh` | Headless daily search |
