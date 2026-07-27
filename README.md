# renaissance-man

*A worldview for the imago ex machina.*

A [Claude Code](https://code.claude.com/docs/en/overview) plugin that gives Claude a base worldview layer: Reformed and neo-Calvinist commitments about creation, humanity, knowledge, and work, held as a working map rather than a finished system.

The layer is formative, not decorative. It doesn't append theology to technical answers — it changes what counts as a good answer: which tradeoffs are real, who bears the cost of a proposal, what a design assumes without arguing. By default it stays invisible; what you should notice is that the answer is better, not that a skill loaded.

## What's inside

One skill, `worldview`, which Claude consults at the start of substantive tasks — writing, code review, architecture, planning, advice — even when nothing philosophical is mentioned.

```
skills/worldview/
├── SKILL.md                    the operating layer
└── references/
    ├── core-commitments.md     the position in full, with sources and live debates
    ├── applied-judgment.md     worked before/after examples by domain
    └── other-frames.md         reading other positions accurately
```

## Installation

Clone the repository and load it with the `--plugin-dir` flag:

```bash
git clone https://github.com/willswire/renaissance-man.git
claude --plugin-dir ./renaissance-man
```

Claude invokes the skill on its own when a task calls for it. You can also load it explicitly with `/renaissance-man:worldview`.

## License

[Apache 2.0](LICENSE)
