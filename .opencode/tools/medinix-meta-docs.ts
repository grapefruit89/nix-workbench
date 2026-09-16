import { tool } from "@opencode-ai/plugin"

// mode "check":    read-only — detects stale or missing generated AGENTS.md.
// mode "generate": WRITES the per-folder AGENTS.md files from NIXMETA
//                  headers. Guarded by permission "medinix-meta-docs": "ask".
// Exposed commands deliberately exclude repair/sync-deps/build-brain/mcp.

export default tool({
  description:
    "Check or regenerate the generated per-folder AGENTS.md documentation from NIXMETA headers. mode 'check' is read-only (detects stale/missing docs); mode 'generate' WRITES the AGENTS.md files (requires user approval).",
  args: {
    mode: tool.schema
      .enum(["check", "generate"])
      .describe("'check' = verify docs are fresh (read-only); 'generate' = rewrite AGENTS.md files (writes files)"),
  },
  async execute(args, context) {
    const dir = context.worktree
    const script = `${dir}/50-core/medinix-meta.py`
    const cmd = args.mode === "generate" ? "generate-docs" : "check-docs"

    try {
      const proc = Bun.$`cd ${dir} && python3 ${script} ${cmd}`.nothrow()
      const text = await proc.text()

      if (proc.exitCode === 0) {
        return text.trim()
      }
      return `medinix-meta ${cmd} FAILED (exit ${proc.exitCode})\n${text.trim()}`
    } catch (error) {
      return `medinix-meta ${cmd} crashed: ${error instanceof Error ? error.message : String(error)}`
    }
  },
})
