import { tool } from "@opencode-ai/plugin"

// READ-ONLY tool: runs `python3 50-core/medinix-meta.py check` in the
// current worktree. Validates NIXMETA ids, provides/requires links and
// deadlinks across all modules. Never mutates anything.

export default tool({
  description:
    "Run the mediNix metadata check (read-only). Validates NIXMETA ids, provides/requires links and deadlinks across all .nix modules. Use before and after any module change.",
  args: {},
  async execute(args, context) {
    const dir = context.worktree
    const script = `${dir}/50-core/medinix-meta.py`

    try {
      const proc = Bun.$`cd ${dir} && python3 ${script} check`.nothrow()
      const text = await proc.text()

      if (proc.exitCode === 0) {
        return text.trim()
      }
      return `medinix-meta check FAILED (exit ${proc.exitCode})\n${text.trim()}`
    } catch (error) {
      return `medinix-meta check crashed: ${error instanceof Error ? error.message : String(error)}`
    }
  },
})
