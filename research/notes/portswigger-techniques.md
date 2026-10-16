---
title: PortSwigger Research — current technique landscape
date: 2026-10-16
type: technique
verified: 2026-10-16
sources:
  - https://portswigger.net/research/rss (40-item live feed, fresh lookup)
  - https://portswigger.net/research/the-fragile-lock (fetched)
  - https://portswigger.net/research/cookie-chaos-how-to-bypass-host-and-secure-cookie-prefixes (fetched)
---

# PortSwigger Research — current technique landscape

Pulled from the live RSS feed on 2026-10-16. **Use the RSS feed, not the HTML
index** — `/research/rss` is the clean entry point and returns all 40 recent posts
in one request. (`HEAD /research` 404s; always GET. See `sources.md`.)

## The dominant theme: parser differentials

The single most consistent thread across 2024→2026 PortSwigger research is
**disagreement between two implementations of the same spec**. Front-end vs
back-end, browser vs server, one XML library vs another. Nearly every modern
high-impact web bug is this shape:

- Two parsers read the same bytes and reach different conclusions
- A security control is enforced by parser A while parser B does the real work
- You smuggle a payload through the gap

This is why "common-ish vulns" (per TBHM) still pay: these classes are
unusual but *systematic*, and no scanner covers the whole chain.

## SAML authentication bypass — "The Fragile Lock" (Dec 2025)

Zakhar Fedotkin. Claims **full unauthenticated bypass across the Ruby and PHP
SAML ecosystems** by chaining several parser-level inconsistencies:

| Step | Technique |
| --- | --- |
| 1 | **XML Signature Wrapping (XSW)** — the classic: signature covers one node, the assertion you actually get trusted is a different node |
| 2 | **Attribute pollution** — `<samlp:Response ID="1" samlp:ID="2">` vs `<samlp:Response samlp:ID="2" ID="1">`. Identical XML, **different attribute-precedence in different parsers** |
| 3 | **REXML namespace confusion without DTDs** — namespace rebinding to `http://www.w3.org/2000/09/xmldsig#` using `xml:xmlns` |
| 4 | **"Impossible XSW"** — using the SAML XML Schema itself to construct a wrapping the validator accepts |
| 5 | **Void canonicalization** — breaks signature verification by changing how the doc canonicalizes |
| 6 | **Golden SAML** — forge a response with a genuinely valid signature |

The lesson: **SAML is exploitable via parser disagreement, not crypto weakness.**
Signature *verification* is present and working — it's just verifying a
different document than the one being consumed.

Check any target with SSO for: ruby-saml, python3-saml (onelogin), and
PHP SAML libs by version, before spending time on password attacks.

Related: **"SAML roulette: the hacker always wins"** (Mar 2025) — round-trip
attacks + namespace confusion → unauthenticated admin on GitLab Enterprise.

## Cookie security bypasses

Four separate 2024-2025 posts attacking cookie defenses. These matter constantly
in bounties because cookie flags are deployed *as* the mitigation.

**Cookie Chaos** (Zakhar Fedotkin, Sep 2025) — bypass `__Host-` and `__Secure-`
prefixes. The prefix rules require no `Domain` attribute and a secure path. Two
parser tricks defeat them:

```js
// 1. Unicode whitespace overwrite — U+2000 before the name
document.cookie = `${String.fromCodePoint(0x2000)}__Host-name=injected; Domain=.example.com; Path=/;`
// -> server receives: Cookie: __Host-name=Carlos;  â€€__Host-name=<img src=x onerror=alert(1)>;
```
```js
// 2. Legacy $Version parsing
document.cookie = `$Version=1,__Host-name=injected; Path=/somethingreallylong/; Domain=.example.com;`
```
Both turn a cookie-injection primitive into **XSS**, because the prefix check
sees a different name than the browser does.

**Also relevant:**
- **"Cookie sandwich"** (Jan 2025) — bypass the **HttpOnly** flag on certain servers
- **"The phantom $Version cookie"** (Dec 2024) — same `$Version` quirk used to **bypass WAFs**
- **Cookie Chaos** (above) — bypass the prefix rules

Practical: whenever you find cookie injection, test all three flags (HttpOnly,
`__Host-`, `__Secure-`) for bypass before reporting. A report that says "cookie
injection" and gets triaged as "no XSS, HttpOnly protects it" is a weak report.

## HTTP request smuggling / desync

- **"CRLF-Powered Desync Attacks: Beheading HTTP Streams"** (Aug 2026) — argues
  **header injection is severely underestimated**. Positioned as a *desync*
  primitive, not "just open redirect / XSS". Highest-impact framing here.
- **"HTTP/1.1 must die: the desync endgame"** (Aug 2025) — upstream HTTP/1.1
  framing is fundamentally broken; six years of mitigations hid it without fixing it.
- **"Beware the false false-positive: how to distinguish HTTP pipelining from
  request smuggling"** (Aug 2025) — **read this before reporting smuggling.**
  Most apparent smuggles are just keep-alive/pipelining. Confirm before you claim it.

## URL validation bypasses

PortSwigger maintains a **URL Validation Bypass Cheat Sheet** —
https://portswigger.net/research/introducing-the-url-validation-bypass-cheat-sheet

Root cause for a large share of **SSRF, CORS misconfig, and open redirect**:
ambiguous URLs that different components parse differently.

Feed it: `http://127.0.0.1:80\@example.com`, `example.com\t.evil.com`,
`http://evil.com#@example.com`, credentials-embedded payloads
(**"Concealing payloads in URL credentials"**, Oct 2024). Also
**"Bypassing character blocklists with unicode overflows"** (Jan 2025) — codepoint
truncation when a server stores a multi-byte char in a single byte; the overflow
can truncate a blocklisted suffix.

## CSS injection and data exfiltration

- **"CSS: the bomb inside your inbox"** (Gareth Heyes, Aug 2026) — webmail
  clients render untrusted CSS in a **trusted UI**. Sanitization is the whole
  attack surface. Any app that renders user-supplied CSS/HTML in an email-like
  context deserves a look.
- **"Inline Style Exfiltration"** (Aug 2025) — steal attribute data using CSS
  **conditionals inside `style` attributes**, no selectors and no `@import`.
  This extends CSS injection to places that strip `<style>` but pass `style="..."`.

## Protocol blind spots

- **"WebSocket Turbo Intruder"** (Sep 2025) — most testers and tools **give up
  when a protocol upgrade to WebSocket happens**. The post names the classes
  hiding in that gap explicitly: **broken access control and race conditions**.
  If a target upgrades to WS, that is where the unaudited surface is.
- **"What's in a tag name? JavaScript, apparently"** (Aug 2026) — characters
  allowed *after* the first char in an HTML tag name, and where the parser
  boundary between "tag name" and "JavaScript identifier" actually falls.

## Tooling worth knowing (Burp)

- **HTTP Anomaly Rank** (Nov 2025) — ranks Intruder/Turbo Intruder responses by
  anomaly instead of you manually sorting thousands of rows by length/difference.
  Directly replaces the tedium TBHM's "fuzz all request parameters" step.
- **Turbo Intruder HTTP/3** (Sep 2026) — >100,000 req/s over Wi-Fi, auto-tuning.
  Makes large-scale parameter fuzzing feasible.
- **Repeater Strike** (Jul 2025) — AI extension automating IDOR hunting.

## AI in the research loop

- **"Can AI do novel security research? Meet the HTTP Terminator"** (Aug 2026) —
  a decade after "AI finds bugs," asks whether an autonomous system can invent
  new techniques and use them against live sites at scale.

## How to use this

1. **Check the RSS feed at the start of a research session.** New classes appear
   monthly; this note is a snapshot, not a standing truth.
2. **Prioritize by bounty value, not novelty.** Cookie/session bypass and SAML
   auth bypass land constantly. Desync pays enormously but is rare.
3. **Always read the "false positive" companion post before reporting.** The
   smuggling post exists because people over-report it.
4. Chains beat single bugs. "The Fragile Lock" is six stacked parser quirks —
   each one alone is probably a dud, together they're unauthenticated admin.