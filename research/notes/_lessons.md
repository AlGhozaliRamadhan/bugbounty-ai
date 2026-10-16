---
title: Lessons learned — do / don't
date: 2026-10-16
type: reference
verified: 2026-10-16
sources:
  - mistakes made during the initial workspace setup and research pass
---

# Lessons learned — do / don't

Written from actual mistakes made on 2026-10-16 while setting up this
workspace. Not hypothetical. Each entry says what went wrong, why it mattered,
and the rule.

---

## 1. Never write an access route you haven't verified

**DON'T:** claim a site has an RSS feed because blogs usually do.

I wrote into `sources.md`: *"Assetnote — Ghost blog. Has an RSS feed, which
beats scraping the HTML archive."* Ghost blogs often do. Assetnote did not.
Probing later showed `/rss/`, `/feed/`, `/atom.xml`, `/index.xml`, `/rss.xml`
**all 404** — and the domain had moved entirely (301 → `slcyber.io`).

**Why it mattered:** the note was going to be trusted by a future session and
would have silently wasted a lookup every time.

**DO:** probe every access route before it goes in a note. Status, final URL
after redirects, and whether the response actually *contains* the expected
elements. Record the trap too — "no feed, scrape the index" is as useful as
"here's the feed."

---

## 2. Never use HEAD to check whether a site is alive

**DON'T:** use `Method Head` for a liveness sweep.

PortSwigger Research returned **404 to HEAD** and **200 to GET**. A HEAD sweep
reports a live, important source as dead.

**DO:** probe with GET. If you must use HEAD, fall back to GET on any non-2xx
before concluding anything.

---

## 3. A 200 status does not mean the page exists

**DON'T:** trust `StatusCode == 200` as proof of a valid response.

tl;dr sec returns **HTTP 200** for `/feed`, `/rss.xml`, and `/atom.xml` — each
redirects to `https://tldrsec.com/?404=/rss.xml`, a 404 *page* with a 200
status and zero `<item>` elements.

**DO:** assert on content, not status. Check for the elements you expect
(`<item>`, `<entry>`) and confirm the final URL isn't a `?404=` pattern.

---

## 4. Stay in your lane — confirm scope before deep-diving

**DON'T:** spend a long stretch diagnosing the Kali MCP when the task was
research.

I diagnosed a broken MCP, traced it to an uninstalled package, and produced
three findings — then got told: *"your job here to manage the research, not
mcp."* The findings were real, but unrequested, and they'd gone in the wrong
direction for the whole middle of the session.

**DO:** read the task, do that task. If you notice a genuine problem
adjacent to it, **report it briefly and ask** — don't expand into it. Depth is
only helpful when pointed the right way.

Related: if a question goes unanswered, don't paper over it by launching
unrequested work. Note that it's blocked and stop.

---

## 5. Write bash to a file; don't pass it inline through PowerShell

**DON'T:** inline complex bash in `wsl ... bash -lc "..."`.

Cost me three failed calls:
- `&&` / `||` inside the string were parsed by **PowerShell** as statement
  separators → `ParserError`
- `$()` subexpressions expanded by PowerShell instead of bash
- `cmd < file` → `The '<' operator is reserved for future use` (PowerShell has
  no input redirection)

**DO:** write the script to a temp file, then pipe it:
```powershell
Get-Content "C:\...\probe.sh" -Raw | wsl -d kali-linux -u root -e bash -s
```
Escaping bugs disappear, and the script is readable and re-runnable.

---

## 6. Watch for self-matching diagnostics

**DON'T:** use `pgrep -f <pattern>` when `<pattern>` appears in the command
you're running.

`pgrep -f 'kali-server-mcp'` run via `bash -lc` **matches the bash process
holding that very string**. It reports RUNNING unconditionally. Worse, the
bracket trick `[k]ali-server-mcp` *also* self-matched — because the same
command line contained the plain string elsewhere.

**DO:** test the thing you actually care about — the port:
```bash
ss -lnt | grep -q ':5000'
```
And when a diagnostic can match its own invocation, cross-check with a second,
independent method before believing it.

---

## 7. Harvest in code, not in context

**DO:** process fetched pages inside the sandbox — strip tags, extract
headings and `<code>` blocks, cap lengths — and return the *distillation*.

Pulling TBHM's 12 chapters and PortSwigger's 40-post feed returned a 74-item
checklist and two deep reads while keeping the raw HTML out of context.

**DON'T:** dump raw HTML or full file listings into the conversation. Extract
what you need; you can always re-fetch.

---

## 8. Check the shape of what a helper returns before chaining

A fetch bug: `const t = await r.text()` then `await r.body.text()` →
`Cannot read properties of undefined`. Consumed a call.

**DO:** one read per response. If you need a second pass, fetch twice or
buffer once and parse from the buffer.

---

## 9. Freshness beats confidence

**DO:** label answers as fresh-lookup vs memory, and re-verify anything
load-bearing.

This is the whole reason for the research protocol. Assetnote's move is the
proof case: I "knew" the blog, and the blog had relocated to a company
(`Searchlight Cyber`) whose research index lives at a different path. Training
knowledge was not just stale, it was *quietly wrong in a way that didn't
announce itself*.

---

## When in doubt

1. Probe it before asserting it.
2. Assert on content, not status codes.
3. Do the task you were given; flag the rest, don't absorb it.
4. Write down what you got wrong — the next session reads these notes instead
   of repeating the mistake.