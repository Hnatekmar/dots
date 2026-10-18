/**
 * describe_image — look at an image without putting it in the conversation.
 *
 * Why this exists
 * ---------------
 * Reading an image file with `read` inserts the picture into the session
 * history, and every later request replays that history. A few renders or
 * screenshots later the request exceeds the backend's per-request image cap
 * (vLLM --limit-mm-per-prompt, 16 on the local lanes) and the session is
 * wedged. This tool sends the image to a vision model on a side channel and
 * returns only text, so the main conversation stays pixel-free.
 *
 * Contract
 * --------
 *   describe_image({ path, question? }) -> text
 *
 * - `path` is absolute or relative to the project directory.
 * - `question` is optional; without it the tool asks for a description.
 * - The tool never returns image content, only text.
 * - Errors come back as text, so the agent can recover instead of the turn
 *   aborting.
 *
 * Options (plugin options, all optional):
 *   { "baseURL": "https://proxy.../v1", "model": "vision",
 *     "apiKey": "...", "maxBytes": 12582912, "timeoutMs": 120000 }
 *
 * The companion `image-budget` plugin stays useful as the safety net for
 * images that do reach the conversation anyway (a direct `read`, a pasted
 * screenshot).
 */

import fs from "node:fs/promises"
import path from "node:path"

const DEFAULT_BASE_URL = "https://proxy.personal-hermes.hnatekmar.dev/v1"
const DEFAULT_MODEL = "vision"
const DEFAULT_MAX_BYTES = 12 * 1024 * 1024
const DEFAULT_TIMEOUT_MS = 120_000

const MIME = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".bmp": "image/bmp",
  ".tif": "image/tiff",
  ".tiff": "image/tiff",
}

const DEFAULT_PROMPT =
  "Describe this image precisely and concretely. State what is visibly there: layout, " +
  "text, colours, shapes, and anything wrong or unexpected. Do not speculate beyond what " +
  "is visible. Keep it under 200 words."

const failure = (message) => ({ content: `describe_image error: ${message}` })

export default {
  id: "describe-image",
  async setup(ctx) {
    const options = ctx?.options ?? {}
    const baseURL = String(options.baseURL ?? process.env.DESCRIBE_IMAGE_BASE_URL ?? DEFAULT_BASE_URL).replace(/\/+$/, "")
    const model = String(options.model ?? process.env.DESCRIBE_IMAGE_MODEL ?? DEFAULT_MODEL)
    const apiKey = options.apiKey ?? process.env.DESCRIBE_IMAGE_API_KEY
    const maxBytes = Number(options.maxBytes) > 0 ? Number(options.maxBytes) : DEFAULT_MAX_BYTES
    const timeoutMs = Number(options.timeoutMs) > 0 ? Number(options.timeoutMs) : DEFAULT_TIMEOUT_MS
    const root = ctx?.location?.directory

    const describe = async (input) => {
      const requested = typeof input?.path === "string" ? input.path.trim() : ""
      if (!requested) return failure("no path given")

      const file = path.isAbsolute(requested) ? requested : path.resolve(root ?? process.cwd(), requested)
      const extension = path.extname(file).toLowerCase()
      const mime = MIME[extension]
      if (!mime) {
        return failure(`unsupported image type "${extension || "none"}"; supported: ${Object.keys(MIME).join(", ")}`)
      }

      let stat
      try {
        stat = await fs.stat(file)
      } catch (error) {
        return failure(`cannot read ${file}: ${error?.message ?? error}`)
      }
      if (!stat.isFile()) return failure(`${file} is not a file`)
      if (stat.size === 0) return failure(`${file} is empty`)
      if (stat.size > maxBytes) {
        return failure(`${file} is ${stat.size} bytes; the limit is ${maxBytes}. Downscale it or describe a crop.`)
      }

      const bytes = await fs.readFile(file)
      const url = `data:${mime};base64,${bytes.toString("base64")}`
      const question = typeof input?.question === "string" && input.question.trim() ? input.question.trim() : DEFAULT_PROMPT

      let response
      try {
        response = await fetch(`${baseURL}/chat/completions`, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            ...(apiKey ? { authorization: `Bearer ${apiKey}` } : {}),
          },
          body: JSON.stringify({
            model,
            max_tokens: 1024,
            messages: [
              {
                role: "user",
                content: [
                  { type: "text", text: question },
                  { type: "image_url", image_url: { url } },
                ],
              },
            ],
          }),
          signal: AbortSignal.timeout(timeoutMs),
        })
      } catch (error) {
        return failure(`vision request failed: ${error?.message ?? error}`)
      }

      if (!response.ok) {
        const body = await response.text().catch(() => "")
        return failure(`vision endpoint returned HTTP ${response.status}: ${body.slice(0, 400)}`)
      }

      let payload
      try {
        payload = await response.json()
      } catch (error) {
        return failure(`vision endpoint returned invalid JSON: ${error?.message ?? error}`)
      }

      const text = payload?.choices?.[0]?.message?.content
      const answer = typeof text === "string" ? text.trim() : Array.isArray(text) ? text.map((p) => p?.text ?? "").join("").trim() : ""
      if (!answer) return failure("vision endpoint returned no text")

      return {
        content: answer,
        metadata: { file, model: payload?.model ?? model, bytes: stat.size },
      }
    }

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "describe_image",
        description:
          "Look at an image file and get a text description. Use this instead of `read` for PNG, JPEG, WEBP, GIF, BMP and TIFF files: " +
          "reading an image puts the picture into the conversation, and every later request replays it until the backend rejects the turn for " +
          "too many images. This tool sends the image to a separate vision model and returns text only.",
        input: {
          type: "object",
          properties: {
            path: { type: "string", description: "Image path, absolute or relative to the project directory." },
            question: {
              type: "string",
              description: "What to answer about the image. Omit for a general description.",
            },
          },
          required: ["path"],
        },
        execute: describe,
        // Direct tool call: codemode routes the result through the code sandbox,
        // which truncates long descriptions.
        options: { codemode: false, pinned: true },
      })
    })
  },
}
