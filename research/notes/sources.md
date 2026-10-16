---
title: Research source access map
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
sources:
  - live probes from this workstation, re-probed 2026-10-16
---

# Research source access map

Standing reference for the bug-bounty research sources. Check this note
**before** any lookup — it records which sources are reachable, the exact
working access route for each, and the traps.

All probes done 2026-10-16 with GET, `User-Agent: Mozilla/5.0 ... Chrome/120`.

## Source status

| Source | Working entry point | Feed | Notes |
| --- | --- | --- | --- |
| **TBHM** | `raw.githubusercontent.com/jhaddix/tbhm/master/<file>` | n/a (git) | Static repo. Skip the GitHub UI entirely. |
| **PortSwigger Research** | `https://portswigger.net/research` | **`/research/rss`** — 40 items | **404s on HEAD, 200 on GET.** Always GET. |
| **PortSwigger Academy** | `https://portswigger.net/web-security` | n/a | Per-class reference pages, and the `all-labs` view for practice targets. Best structured source for a single vulnerability class. |
| **Orange Tsai** | `https://blog.orange.tw/posts/<slug>/` | **`/atom.xml`** — 100 entries | Static site. Posts have `-en`/`-ch` pairs — **take `-en`**. |
| **tl;dr sec** | `https://tldrsec.com/` | **`/feed.xml`** — 20 items | Redirects to `rss.beehiiv.com`. Beehiiv-hosted. |
| **Assetnote** | **`https://www.slcyber.io/research`** | none | **MOVED.** `blog.assetnote.io` 301s to `www.slcyber.io/assetnote`. |
| **Searchlight Cyber** | **`https://www.slcyber.io/research-blog`** | none | Same content, the current index path. `/research` also works. |
| **Pentester Land** | **`https://pentester.land/sitemap.xml`** | **none** | **JS-rendered — see trap 4.** Use the sitemap, not the HTML. |
| **web.archive.org** | `https://web.archive.org/` | n/a | Fallback for dead links, JS-rendered pages, vanished slides. |

## Traps (all confirmed by probing, not assumed)

### 1. PortSwigger 404s HEAD requests
```
HEAD https://portswigger.net/research  -> 404   (false "dead")
GET  https://portswigger.net/research  -> 200
```
A HEAD-based liveness sweep will wrongly report PortSwigger as gone.
**Always probe with GET.**

### 2. tl;dr sec uses soft-404s
`/feed`, `/rss.xml`, `/atom.xml` all return **HTTP 200** but redirect to
`https://tldrsec.com/?404=/rss.xml` — a 404 *page* with a 200 status and no
`<item>` elements.

**A status-code-only probe reports these as working.** Check for `<item>`/`<entry>`
elements or a non-`?404=` final URL, not just the status.

Real feed: `/feed.xml` → 301 → `https://rss.beehiiv.com/feeds/xgTKUmMmUm.xml`.

### 3. Assetnote has moved and has no feed
`https://blog.assetnote.io/` → **301 → `https://www.slcyber.io/assetnote`**
(Assetnote was acquired by Searchlight Cyber).

Every conventional feed path 404s: `/rss/`, `/feed/`, `/atom.xml`,
`/index.xml`, `/rss.xml`. Content is at **`https://www.slcyber.io/research`**.
`/blog` holds lighter "Beacon" threat-intel posts; `/research` holds the
vulnerability research.

### 4. Pentester Land is client-side rendered — use the sitemap

`/feed/`, `/rss.xml`, `/atom.xml` all hard-404, which makes it look like an
HTML-scraping target. **It isn't one.** `pentester.land/` returns 200 and ~20 KB
of HTML containing **zero `href` attributes** — the page is rendered by
JavaScript. A scraper finds nothing and concludes the site is empty. It isn't.

```text
GET https://pentester.land/            -> 200, 20 KB, 0 hrefs
GET https://pentester.land/sitemap.xml -> 200, 34 KB, full URL index
```

**Use `https://pentester.land/sitemap.xml`** — 190 URLs as of 2026-10-16, all
`/blog/<slug>/` posts. Filter it with regex rather than paginating a rendered
index.

Content note: the blog skews recon and methodology. It is a good source for
subdomain enumeration and recon workflow, and thin on access-control and auth
vuln classes. Use PortSwigger Academy for those.

### 5. Orange Tsai has no `/feed/`
Only `/atom.xml` works. A WordPress assumption (`/feed/`) gets a 404.

## Fetch order for a lookup

1. **Primary first.** PortSwigger blogs and Orange Tsai for vuln classes;
   Searchlight (ex-Assetnote) for attack-surface discovery; TBHM for
   methodology. The researcher who found a bug first usually says the most.
2. **Feed over HTML** where a feed exists — PortSwigger `/research/rss`,
   Orange Tsai `/atom.xml`, tl;dr sec `/feed.xml`. Three of six sources.
3. **raw.githubusercontent.com** for TBHM chapters.
4. **web.archive.org** when: a page 404s, needs JS to render, or a conference
   slide PDF is no longer hosted.

## Sources that need no special handling
TBHM chapters are plain Markdown; `https://github.com/jhaddix/tbhm` returns
200 and the `git/trees/master?recursive=1` API endpoint gives the full file list
in one call — useful for confirming a chapter is a stub before reading it.

## Extraction rule

Never cache raw PDFs or scraped HTML. Convert anything worth keeping into a
short dated Markdown note in `research/notes/<topic>.md`, with a source URL and
the access route used. See `research/notes/_index.md`.

## Maintenance

Re-probe the table when a lookup unexpectedly 404s or returns empty content —
the Assetnote move happened without the old URL breaking loudly. Add the date
you re-verified to `verified:` in the frontmatter.