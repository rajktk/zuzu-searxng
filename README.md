---
title: ZuZu SearXNG
emoji: 🔎
colorFrom: blue
colorTo: gray
sdk: docker
app_port: 7860
pinned: false
license: agpl-3.0
---

# ZuZu SearXNG (Hugging Face Space)

Live Space: https://huggingface.co/spaces/idnameraj/zuzu-searxng  
API base: `https://idnameraj-zuzu-searxng.hf.space`

Metasearch backend for [ZuZu Writer](https://huggingface.co/spaces/idnameraj/zuzuwriter) plagiarism checks.

ZuZu calls:

```text
GET /search?q=...&format=json
```

On the ZuZu Space set:

```text
SEARXNG_BASE_URL=https://idnameraj-zuzu-searxng.hf.space
```

## Important

- Prefer a **private** Space if possible (public = open JSON search API).
- Cloud IPs are often rate-limited by Google/Bing; keep Google CSE as fallback on ZuZu.
- Set secret `SEARXNG_SECRET` and variable `SEARXNG_BASE_URL` on this Space.
- Entrypoint runs a **2-minute keep-alive** loop (local + `SEARXNG_BASE_URL` / `SPACE_HOST`) while the container is up. That only helps while Running; paid CPU hardware is still the reliable always-on option. Override interval with `KEEP_ALIVE_INTERVAL` (seconds).
