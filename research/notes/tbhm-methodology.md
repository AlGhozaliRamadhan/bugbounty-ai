---
title: TBHM — The Bug Hunter's Methodology
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://github.com/jhaddix/tbhm (fresh lookup, raw.githubusercontent.com)
  - Fast Testing Checklist.md (full 74-item extraction)
---

# TBHM — The Bug Hunter's Methodology

Jared Hatcher's methodology, still the best short frame for how bounty hunting
differs from normal pentest work.

**Structure:** 12 numbered chapters + a `Fast Testing Checklist`. Chapters are
deliberately thin — the author's own headers say "Auth (better be quick)",
"Session (better be quick)". The **checklist is the actual deliverable**. Treat
the chapters as pointers and the checklist as the workhorse.

Fetch via `raw.githubusercontent.com/jhaddix/tbhm/master/<file>` — skips page chrome.

## The strategic frame: this is not pentesting

From `01_Philosophy.md`, the differences that matter:

- **Looking mostly for common-ish vulns.** Not exotic novel classes. A chained
  IDOR or an authz bypass pays better than a theoretical memory-corruption bug.
- **Not competing with others.** Other hunters are on the same target with the
  same scanners. Low-hanging fruit is gone. Go where the crowd isn't.
- **Payment based on impact, not number of findings.** One severe beats fifteen
  informational.
- **Incentivized to find unique bugs.** Programs discount duplicates hard.

Report writing is called out explicitly, with two references:
- https://blog.bugcrowd.com/advice-for-writing-a-great-vulnerability-report/
- https://forum.bugcrowd.com/t/writing-a-bug-report-attack-scenario-and-impact-are-key/640

The recurring point: **attack scenario and impact are what get paid.**

## Discovery (ch. 02) — "find the road less traveled"

- **Bounty metadata is recon.** Reward range and scope tell you where the money is.
- **Acquisitions and mergers are a seam.** New parent, new rules, old
  infrastructure. Check whether acquired domains carry the bounty.
- Search the **parent company by trademark and privacy policy** — that's how you
  find assets nobody listed in scope.
- **Port scan every domain, not just the apex.** Obscure web servers and
  non-standard services hide off the main site.
- **Functionality changes / re-designs** create new attack surface nobody has looked at.
- "LMGTFY" — the author explicitly endorses Google over clever tooling here.

Worked examples he gives: Facebook once had a **Jenkins script console with no
auth**; IIS.net had **RDP exposed and vulnerable to MS12-020**. Both are
"wrong thing exposed in the wrong place", not clever app-logic bugs.

## Mapping (ch. 03)

- **Smart\* directory brute forcing** — the raft/big lists, not `common.txt`.
  RAFT lists are in SecLists; so is the SVN digger list.
- **Platform identification** → then target that platform's known vulns.
- **DNS subdomain brute force.**
- Tool referenced: **Intrigue** (for mapping/crawling).
- Also noted: `retire.js` for outdated-JS-library detection, via CLI or as a Burp extension.

## Auth & Session (ch. 04) — verbatim flaws to hunt

His list is short and concrete:

- User/pass discrepancy flaw
- Registration page harvesting
- Password reset page harvesting
- **Password not required for account updates**
- **Password reset tokens with no expiry or re-use**
- Failure to invalidate old cookies
- No new cookie issued on login/logout/timeout
- Never-ending cookie length
- Multiple sessions allowed
- **Easily reversible cookie (base64 most often)**

The last one is the highest-yield: decode the session cookie. If it's base64 or
plaintext JSON, you may not need a vuln at all.

## IDOR (ch. 12) is a stub

`12_IDOR.markdown` is **58 characters** — a heading and no content. TBHM's IDOR
chapter is effectively unwritten. Don't expect guidance there; see
`idor-bola-testing.md` instead.

## The Fast Testing Checklist — 74 items

The real payload. Six groups, in the order he recommends working them.

### App Recon and analysis (9)
Map visible content manually · discover hidden & default content (dir/file
bruteforce) · test for debug parameters · identify data entry points (Burp Pro
dynamic content discovery) · identify technologies (Wappalyzer or similar) ·
**research existing vulnerabilities in that technology** · gather
technology-specific wordlists (he calls out Assetnote's as excellent) · map attack
surface automatically (spider) · collect all JS files for later analysis.

That 4th-from-last item is the multiplier: knowing it's Jenkins means the next
step is *find Jenkins bugs*, not *fuzz blindly*.

### Handling of access (22)

**Authentication (10)** — password quality rules · username enumeration ·
resilience to password guessing · account recovery · "remember me" ·
impersonation function · username uniqueness · unsafe credential distribution ·
**fail-open conditions** · multi-stage mechanisms.

**Session handling (9)** — test tokens for **meaning** · test tokens for
**predictability** · insecure transmission of tokens · token disclosure in logs ·
**mapping of tokens to sessions** · session termination · session fixation · CSRF ·
cookie scope.

**Access controls (3)** — understand the requirements first, then test
effectiveness **using multiple accounts**, then test insecure control *methods*
(trusting request parameters, `Referer`, etc.).

Testing authz with 2+ accounts of different privilege tiers is the single most
reusable habit in this list.

### Handling of input (17)
Fuzz all request parameters · SQLi · **identify all reflected data** · reflected
XSS · HTTP header injection · arbitrary redirection · **stored attacks** · OS
command injection · path traversal · script injection · file inclusion · SMTP
injection · native software flaws (buffer overflow, integer bugs, format strings)
· SOAP injection · LDAP injection · XPath injection · **SSRF and HTTP redirects
in all redirecting parameters**.

### Application logic (8)
Identify the logic attack surface · **transmission of data via the client** ·
reliance on client-side validation · thick-client components · multi-stage process
flaws · **handling of incomplete input** · **trust boundaries** · transaction logic.

"Incomplete input" and "trust boundaries" are where real money hides — these are
rarely covered by scanners.

### Application hosting (9)
Segregation in shared infrastructure · segregation between co-hosted apps · web
server vulns · default credentials · default content · dangerous HTTP methods ·
proxy functionality · virtual hosting misconfiguration · web server software bugs.

### Miscellaneous (9)
DOM-based attacks · frame injection · local privacy vulnerabilities · persistent
cookies · caching · **sensitive data in URL parameters** · autocomplete-enabled
forms · follow up any information leakage · weak SSL ciphers.

## How to actually use this

The checklist is 74 items — too many to run linearly on one target under time
pressure. The practical read:

1. **Recon+auth/session first (31 items).** Highest hit rate, cheapest, no
   destructive payloads. Most bounty reports are IDOR/authz.
2. **Then input (17)** driven by what recon revealed about the stack.
3. **Logic (8) and hosting (9)** when the app is meaty or the program pays for
   business logic — these are where a scanner contributes nothing.
4. **Miscellaneous (9)** as a sweep at the end.

Per `02_Discovery.md` and the workspace rules: **reuse results. Don't re-scan a
host already in `ports.txt`** unless something changed.