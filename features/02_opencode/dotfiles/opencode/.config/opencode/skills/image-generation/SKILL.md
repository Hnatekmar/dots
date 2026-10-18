---
name: image-generation
description: Generate images from text with Qwen-Image-2.1-Turbo on the dev cluster.
---

# Image generation (Qwen-Image-2.1-Turbo)

Text-to-image on the homelab dev cluster: `Qwen-Image-2.1-Turbo` served by
sd.cpp behind `https://llm.dev-k8s.srv.hnatekmar.dev/qwen21`, at ~8 s per
1024×1024 image once the pod is warm.

Use this skill when the user asks for an image, a picture, a poster, an icon,
or a visual mock and has not named a specific generator.

## Generate

```bash
bash ~/.config/opencode/skills/image-generation/scripts/generate.sh \
    -o out.png "a red cube on a wooden table, studio light"
bash ~/.config/opencode/skills/image-generation/scripts/generate.sh \
    -o cover.png -W 768 -H 1344 "vertical book cover, dusk city"
```

The script lives next to this file as `scripts/generate.sh`; the absolute path
above is where the dots bootstrap stows it.

Options: `-o` output path (required), `-W`/`-H` size, `-s` seed,
`-n` negative prompt, `-h` help. `QWEN21_URL` overrides the endpoint.

The script prints the seed it used. Report it whenever the user may want the
same image again.

Save images inside the repository the user is working in (`./images/` or the
project's asset directory), never in `/tmp`, so they survive the session. A
generated image is a deliverable: give the user the path.

## Fixed parameters

Turbo needs its distilled schedule. The script always sets these; do not
change them by hand:

| Parameter | Value |
|---|---|
| steps | 8 |
| cfg_scale | 1.0 |
| sampler | euler |
| custom_sigmas | `1.0,0.978453,0.95418,0.926626,0.89508,0.845148,0.704534,0.414568,0.0` |

A request without `custom_sigmas` runs the non-Turbo flow schedule at 8 steps
and returns mush. The sigmas travel inside the prompt as
`<sd_cpp_extra_args>{"sample_params":{"custom_sigmas":[...]}}</sd_cpp_extra_args>`,
because the A1111 endpoint has no field for them.

Width and height must be divisible by 32.

## When it fails

- **Connection error or 5xx after a long wait** — the deployment scales to
  zero by default (SCALE toggle row 5, `qwen21`). Say so and stop. Do not
  retry in a loop, and do not silently fall back to another model.
- **First request after scale-up is slow** — the pod reads 16 GB of weights
  at startup (~45 s to Ready, then the first request). The script waits up to
  300 s for that.
- **Blocky or smeared output** — the sigmas are missing or wrongly formatted.
  Use the script; do not hand-write the payload.

## Reference

`scripts/generate.sh` is the only supported client. It needs `curl` and
`python3`; nothing else.
