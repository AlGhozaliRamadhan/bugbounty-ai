---
title: Orange Tsai — multi-step vulnerability chains
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://blog.orange.tw/atom.xml (100-entry live Atom feed, fresh lookup)
  - https://blog.orange.tw/ (post index)
---

# Orange Tsai — multi-step vulnerability chains

Orange Tsai's corpus is the best available proof that **single bugs are rarely
what pays**. Nearly every high-impact bug in his archive is a **chain of 2-4
primitives**, each one individually mediocre, which together produce
pre-auth RCE.

**Access route:** Atom feed at `https://blog.orange.tw/atom.xml` — 100 entries,
plain XML, works. There is **no `/feed/`** (404). The site is static HTML with
posts at `/posts/<slug>/`. Several posts have `-en`/`-ch` pairs; **take the `-en`
one.**

## The pattern that matters

Look at the shape of his best work:

| Series | Primitives chained |
| --- | --- |
| **MS Exchange** (2021, 3 parts) | ProxyLogon → ProxyOracle → ProxyShell |
| **SSL VPN** (2019, 3 parts) | Palo Alto GlobalProtect pre-auth RCE → Fortigate → Pulse Secure |
| **PHP** (2019→2024) | PHP-FPM RCE (CVE-2019-11043) → CGI argument injection (CVE-2024-4577) |

The recurring structure:

1. **Primitive 1** — usually an *SSRF*, an auth bypass, or an injection that
   looks low-severity on its own.
2. **Primitive 2** — the SSRF/auth bypass reaches an *internal* service that
   isn't otherwise exposed. This is the step that turns "low" into "interesting".
3. **Primitive 3+** — a memory-corruption or RCE primitive in the thing the
   SSRF reached.

**The lesson for bounty work:** a finder who stops at "I have an SSRF" files a
low-severity duplicate. The same SSRF chained one hop further is a critical and
unique. Before triaging anything down, ask *what internal service does this
reach?*

## Specific posts worth reading

### "Confusion Attacks: Exploiting Hidden Semantic Ambiguity in Apache HTTP Server" (2024-08)
Semantic ambiguity in how Apache parses requests. Same family as the
parser-differential theme in `portswigger-techniques.md` — **the HTTP spec has
ambiguity, and ambiguity is exploit**. Read this before doing manual HTTP
request work against any non-standard proxy or gateway.

### "CVE-2024-4577 - Yet Another PHP RCE: Make PHP-CGI Argument Injection Great Again!" (2024-06)
PHP-CGI argument injection. **Argument injection is the theme** — the class is
"injection into a process-launching parameter," which is under-tested compared
to SQLi/XSS. Worth a look at any app that shells out with user input.

### "How I Hacked Facebook Again! Unauthenticated RCE on MobileIron MDM" (2020-09)
MobileIron MDM, pre-auth RCE, found by a web researcher against enterprise
software. Demonstrates the **enterprise appliance as an ideal target**: pre-auth,
internet-exposed, high-value data, often under-patched.

### "A Web Dog's Guide to OSEE" (2025-07)
Outlook Search Engine Exploitation — abusing the *search* surface of enterprise
mail rather than the obvious delivery surface. Framed as a study guide for
OSCP-level Windows exploitation.

### "WorstFit: Unveiling Hidden Transformers in Windows ANSI" (2025-01)
Clever naming pun, serious content: abuse of Windows' ANSI escape handling.

### "Let's Dance in the Cache: Destabilizing Hash Table on Microsoft IIS" (2022-08)
Hash-table collision DoS. **Note the workspace rule against DoS testing** —
this is a read-and-understand post, not something to reproduce against a target.

### "The Art of PHP" (2025-08)
CTF journey + **PHP filter chains** for LFI → RCE. Directly applicable if you
find a local file inclusion: filter chains get you `php://` execution without
uploading anything.

### "A Journey Combining Web Hacking and Binary Exploitation in Real World" (2021-02)
How a web-only finding crossed into native exploitation. Useful for framing
"how much further does this go" in a report.

## How to use this

1. **Before triaging down any SSRF/authz bug**, chain it one hop. Ask what
   internal service it reaches.
2. **Enterprise appliances and MDM/SSL-VPN/VPN concentrators are the recurring
   target class** across his whole archive. Pre-auth + internet-facing + high-value.
3. **Keep the argument-injection and file-inclusion chains in your back pocket.**
   LFI → filter chain → RCE; shell parameter → argument injection. Both are
   high-yield and under-swept.
4. This is a **chain-building** corpus, not a technique-list corpus. Read for
   *structure* — "what did they reach with the first primitive" — not payloads.