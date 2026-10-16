---
title: Assetnote → Searchlight Cyber — attack-surface research
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://www.slcyber.io/research (post index, fresh lookup)
  - https://www.slcyber.io/assetnote (redirect landing page)
---

# Assetnote → Searchlight Cyber — attack-surface research

**URL moved.** `https://blog.assetnote.io/` now **301-redirects to
`https://www.slcyber.io/assetnote`**. Assetnote was acquired by Searchlight
Cyber; the blog content lives at **`https://www.slcyber.io/research`**.

No RSS feed at the old paths — `/rss/`, `/feed/`, `/atom.xml`, `/index.xml`,
`/rss.xml` all return 404. **Scrape the `/research` index page** instead; the
post links are in plain HTML.

Their own framing is now **ASM (attack surface management)**: *"Discover
everything on your attack surface... 96% faster discovery and validation."*
The blog is marketed as the research arm of that product. Posts are still
genuine vulnerability research, just framed commercially.

## Recent research posts

| Post | Angle |
| --- | --- |
| **"More Critical Bugs in Adobe Experience Manager: Pre-Auth RCE"** | Enterprise CMS, pre-auth. Multiple critical bugs in one product. |
| **"Leaking the Keys to the Kingdom: How a Single Slip Handed Over a Darknet Empire"** | **One mistake → entire operation.** Impact-narrative style writeup. |
| **"A JPEG, a Race, and a Ghost: Breaking Discourse's Image Pipeline"** | Three classes concatenated: image parsing + race condition + use-after-free. |
| **"Out of Bounds, Out of Sandbox: RCE in Go JavaScript Engine (goja)"** | Sandbox escape in a JS engine — OOB write. |
| **"Exploit brokers pay $500,000 for a WordPress RCE — I found one with GPT-5.6"** | AI-discovered WordPress RCE, framed against broker pricing. |
| **"WP2Shell: Pre-Authentication RCE in WordPress Core"** | Pre-auth RCE in the most deployed CMS on earth. |

The `/blog` path (vs `/research`) carries lighter "Beacon" threat-intel posts —
useful for knowing what is actively exploited, but not methodology.

## Patterns worth stealing

### 1. Product-family hunting, not one-off hunting
"More Critical Bugs in Adobe Experience Manager" is explicitly *multiple bugs in
one product*. Their stated method is finding the product, understanding it
thoroughly, then sweeping it — rather than scanning the whole internet for
one-offs. This matches TBHM's "identify the technologies used → research
existing vulnerabilities in that technology."

**Applies directly:** once recon fingerprints a product (WordPress, Discourse,
Adobe AEM, Jira, Confluence), the highest-value move is to research *that
product's* known bug classes, not to keep fuzzing generically.

### 2. Chaining a mundane primitive with a severe one
"A JPEG, a Race, and a Ghost" — the JPEG is an image-parsing routine, the race
is a concurrency bug, the ghost is a use-after-free. None is individually
critical. Together, breaking the image pipeline of a forum used by millions.

Same structural insight as Orange Tsai's chains, reached from a different
direction: **fuzzing an image/video/document parser is the modern equivalent of
fuzzing a query parameter**, and it reaches deeper code with far less auth
required.

### 3. Severity is the narrative
"How a Single Slip Handed Over a Darknet Empire" is titled on *impact*, not
technique. Matches TBHM's "payment based on impact, not number of findings" and
its pointers to Bugcrowd's report-writing guidance. The lesson: **write the
title as the consequence**, and the triage reads it first.

### 4. Pre-auth on ubiquitous infrastructure
WordPress Core pre-auth RCE, Adobe AEM pre-auth RCE, goja sandbox escape.
Common denominator: **pre-auth, widely deployed, reachable by a hobbyist's
scanner.** That's the Assetnote target profile.

## How to use this

1. **Fix the URL first** — `blog.assetnote.io` is dead as a direct path; it
   only survives as a redirect. Cite `slcyber.io/research` in notes.
2. After recon, **identify the product and research its class of bugs.** This
   is the highest-leverage habit across both Assetnote and TBHM.
3. **Parser targets (JPEG, PDF, image pipelines, document converters, JS
   engines) are underexamined** relative to their reach. Good places to spend
   time when a program allows.
4. Read their posts for **framing** — severity narrative, chain construction —
   as much as for the technical content.