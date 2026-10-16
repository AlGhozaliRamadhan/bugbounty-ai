---
description: Research a bug bounty topic from primary sources
---

Research `$ARGUMENTS` for bug bounty work, following the protocol in
`AGENTS.md`.

1. **Check `research/notes/_index.md` first.** If a note already covers this,
   read it and answer from it. Do not redo the lookup.

2. If it isn't covered, go to primary sources — `research/notes/sources.md` has
   the verified access routes and the traps. The order that works: the person
   who found the bug class first, then the writeups, then blogs.

3. Probe every URL before you put it in a note. Check the status, the final URL
   after redirects, and whether the body actually contains what you expected.
   Never assert a route you haven't hit.

4. Assert on content, not status codes. A 200 can be a soft-404. PortSwigger
   returns 404 to HEAD and 200 to GET — always GET.

5. If a source is unreachable, try `web.archive.org` or a GitHub mirror. If it
   still fails, **say the source was unreachable** — do not quietly fall back to
   memory.

6. Write the result to `research/notes/<topic>.md` with frontmatter (`title`,
   `date`, `type`, `status`, `verified`, `sources`), then add it to `_index.md`.

Convert to a short dated Markdown note. **Never cache raw PDFs or scraped
HTML** — extract the headings and code blocks you need and keep those.

When you give me the answer, state plainly whether it came from a fresh lookup
or from memory. Bug bounty knowledge goes stale silently, and an unlabelled
answer is indistinguishable from a checked one.