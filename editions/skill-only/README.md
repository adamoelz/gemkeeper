# gemkeeper (skill-only edition)

**Never kill a good Claude Code session again.** Claude keeps a tiny, always-current ledger of the
2% of context that matters (rules, decisions and *why*, dead ends, next step) in `.gemkeeper/ledger.md`,
so you can `/clear` a bloated session and pick up at full quality.

This is the edition for the Claude plugin directory: a skill and one command, **no hooks and no scripts**.
The [full version](https://github.com/adamoelz/gemkeeper) adds hooks that load the ledger automatically
after `/clear` and compaction and remind Claude to save gems as you go.

| | Skill-only edition | [Full version](https://github.com/adamoelz/gemkeeper) |
|---|---|---|
| Ledger written continuously | Claude checks each message itself | Hooks flag messages that look like gems |
| After `/clear` or a new session | Run `/gemkeeper:resume` | Ledger loaded automatically |
| Sweep warning when the context gets long | Claude suggests it | Measured from real token usage |
| Runs code on your machine | No | Small bash hooks |

## Use

Work as usual. When you want to reset:

```
/gemkeeper:gems      # full sweep, then "Safe to /clear"
/clear
/gemkeeper:resume    # mission, where we are, next step
```

## Benchmark

The [benchmark](https://github.com/adamoelz/gemkeeper#benchmark) numbers (30/30 facts kept after `/clear`,
~2.6k tokens carried over) were measured with the full version. Results for this edition:
[gemkeeper-bench](https://github.com/adamoelz/gemkeeper-bench).

## License

MIT
