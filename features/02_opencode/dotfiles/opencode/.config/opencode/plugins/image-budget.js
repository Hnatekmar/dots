/**
 * image-budget — cap the number of images in a single model request.
 *
 * Why this exists
 * ---------------
 * Inference backends cap images per request (vLLM: --limit-mm-per-prompt,
 * 16 on the local lanes). A coding session accumulates images whenever the
 * model reads a screenshot, a rendered canvas or a diagram, and every request
 * replays the whole session history. The image count therefore climbs with
 * the session, not with the current task, until the backend rejects the turn:
 *
 *   Error: At most 16 image(s) may be provided in one prompt. (parameter=image)
 *
 * That error is not recoverable from inside the session: every later request
 * carries the same history and fails the same way.
 *
 * What this does
 * --------------
 * On each request, keep the newest `keep` images and replace every older one
 * with a short text placeholder. The model still sees the current screenshot;
 * it stops paying for the superseded ones. Stored history is untouched — this
 * only rewrites the request draft.
 *
 * The same budget applies to the auxiliary requests that replay history:
 * compaction, title generation and generate. Otherwise the first auto-compaction
 * of a long session would fail on the images the agent loop just escaped.
 *
 * Configure the budget with plugin options:
 *
 *   "plugins": [
 *     { "package": "./plugins/image-budget.js", "options": { "keep": 2 } }
 *   ]
 */

const DEFAULT_KEEP = 3

const isImage = (part) =>
  part != null &&
  (part.type === "file" || part.type === "image") &&
  typeof part.mime === "string" &&
  part.mime.startsWith("image/")

const placeholder = (part) => ({
  type: "text",
  text: `[image${part.name ? " " + part.name : ""} omitted: sent earlier in this session and dropped by image-budget to stay under the per-request image limit]`,
})

/**
 * Collect every image slot in document order: a direct content part (a user
 * attachment) or an entry inside a tool result (what `read` returns for an
 * image file). Each slot records the array and index to rewrite.
 */
function imageSlots(message) {
  const slots = []
  const content = message?.content
  if (!Array.isArray(content)) return slots

  content.forEach((part, index) => {
    if (isImage(part)) {
      slots.push({ array: content, index })
      return
    }
    const values = part?.type === "tool-result" ? part.result?.value : undefined
    if (!Array.isArray(values)) return
    values.forEach((value, valueIndex) => {
      if (isImage(value)) slots.push({ array: values, index: valueIndex })
    })
  })

  return slots
}

function applyBudget(messages, keep) {
  const slots = (messages ?? []).flatMap(imageSlots)
  const excess = slots.length - keep
  if (excess <= 0) return 0

  for (const slot of slots.slice(0, excess)) {
    slot.array[slot.index] = placeholder(slot.array[slot.index])
  }
  return excess
}

export default {
  id: "image-budget",
  async setup(ctx) {
    const configured = Number(ctx?.options?.keep)
    const keep = Number.isFinite(configured) && configured >= 0 ? configured : DEFAULT_KEEP

    const prune = (event) => {
      const dropped = applyBudget(event?.messages, keep)
      if (dropped > 0 && process.env.OPENCODE_IMAGE_BUDGET_DEBUG === "1") {
        console.error(`[image-budget] dropped ${dropped} image(s), kept ${keep}`)
      }
    }

    // Every request kind that replays conversation history.
    await ctx.session.hook("context", prune)
    await ctx.session.hook("compaction", prune)
    await ctx.session.hook("title", prune)
    await ctx.session.hook("generate", prune)
  },
}
