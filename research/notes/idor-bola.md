---
title: IDOR / BOLA testing
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://portswigger.net/web-security/access-control/idor (Web Security Academy, GET)
  - https://portswigger.net/web-security/access-control (topic index, GET)
  - https://docs.hackerone.com/en/articles/8495674-defining-severity (severity policy, GET)
---

# IDOR / BOLA testing

Insecure Direct Object Reference — OWASP calls the broader class Broken Object
Level Authorization (BOLA). Popularized by OWASP 2007 Top 10, but it is just one
of many access-control implementation mistakes.

**Fresh lookup, 2026-10-16.** PortSwigger Academy is the primary source below.

## The two shapes

**Direct reference to a database object.** A URL takes a customer number and
uses it as a record index:

```
/customer_account?customer_number=1337
```

With no other control, changing `customer_number` views other customers' records.
Horizontal privilege escalation.

**Direct reference to a static file.** Transcripts, exports, avatars, invoices
saved with an incrementing filename:

```
/download?id=1273
```

Same flaw, different storage. Chained files (`report-1337.pdf`) are worse — you
can walk the whole directory.

## Vertical vs horizontal

- **Horizontal** — same privilege level, different user. The common case.
- **Vertical** — escalate *up*. Change a role/user parameter to reach an admin
  function.

Both come from the same missing check, and vertical is frequently rated higher
because it reaches more. Test both: change the object **and** change the role
parameter if one is present.

## Why it is so common

The authorization check is written *somewhere else*. The endpoint reads the
object and returns it; the middleware that would have compared ownership doesn't
run, or runs on a different route, or only checks authentication ("who are you")
rather than authorization ("is this yours").

## How to test it

**You need two accounts.** This is not optional. IDOR is a comparison, and one
account gives you nothing to compare against. Different roles if vertical
escalation is in play.

1. Create accounts A and B. Record their identifiers.
2. As A, request a resource and capture the request.
3. Replay it in B's session, or simply substitute B's object identifier while
   authenticated as A.
4. Observe whether the ownership field matches the authenticated principal.

The test that works best: **stay authenticated as A, request B's object.** If the
response contains B's data, the check is missing. Confusing this is the single
most common IDOR false negative — people switch accounts *and* change the ID, and
then can't tell which change did it.

## Enumerate object identifiers

The identifier is often the whole attack surface.

```bash
# sequential integers are the common case
seq 1 1000 | ffuf -w - -u "https://target/api/item/FUZZ" -H "Authorization: Bearer $TOKEN" -mc 200 -rate 20
```

Watch for: UUIDs (still enumerable if the API takes them raw), base64-encoded
IDs, GraphQL node IDs, and composite keys.

**Mass assignment / parameter tampering** is the sibling bug: add a field the
form never showed. `role=admin`, `is_admin=true`, `price=0`, `owner_id=<other>`.
Some APIs accept fields that only the admin UI sets — check whether the server
filters by role or just deserializes.

## What pays and what doesn't

| Finding | Usually pays? |
| --- | --- |
| Read another user's invoice/PII, one record, proven | yes |
| Read another user's record across a whole table, minimal sample | yes, higher |
| Vertical escalation to admin on a real function | yes, often high |
| Read your own record with a different ID | **no** — not IDOR |
| Access a record you created yourself | **no** — self-inflicted |
| Download a file whose name you guessed | yes, if it's another user's |

The last two rows are the classic self-inflicted trap. If you created the object
and then accessed it, you proved nothing about the access-control model.

**Minimal proof.** One other user's record demonstrates the bug. Pulling 200
records is negligence, not evidence, and it's a scope violation on most
programs. See `docs/report-writing.md`.

## Chained with other bugs

- **Cache poisoning** — an IDOR becomes sitewide if the response is cached
  without varying on the right key. See `race-conditions.md`.
- **IDOR + weak reference** — an unguessable UUID is not authorization. If you
  can obtain another user's UUID from any source, it's IDOR. That's the argument
  to make when a triager claims the IDs are unguessable.
- **IDOR on a PATCH/DELETE** — integrity and availability matter more than
  confidentiality. Write access is often rated higher, and deletion proves it
  faster than reading (though destroying a real record is out of bounds — use
  something you own in a disposable state, and ask first).

## OAuth angle

Object references in OAuth callbacks are a common IDOR vector — a `state` that
isn't bound to the session, or a `redirect_uri` that accepts arbitrary hosts.
See `oauth-oidc.md`.

## Report framing

Lead with the impact, not the mechanism. "Invoice API returns any customer's
billing data to any authenticated user" beats "the `id` parameter is not
authorized". Include both accounts' roles, the exact request, and the ownership
mismatch in the response. Severity should reflect data sensitivity and scale,
not the CVSS of the parameter itself.