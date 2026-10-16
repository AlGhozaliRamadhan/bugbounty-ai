---
title: OAuth 2.0 and OpenID Connect flaws
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://portswigger.net/web-security/oauth (GET)
  - https://portswigger.net/web-security/oauth/openid (GET)
  - https://portswigger.net/web-security/oauth/grant-types (GET)
  - https://portswigger.net/research/hidden-oauth-attack-vectors (GET, Stepankin, 2021-03-24)
---

# OAuth 2.0 and OpenID Connect flaws

**Fresh lookup, 2026-10-16.** Primary sources: PortSwigger Academy, plus Michael
Stepankin's *Hidden OAuth attack vectors* (`@artsploit`), published 2021-03-24.
The Academy OAuth topic was written in collaboration with that research.

## Why it's worth the time

OAuth is everywhere — "log in with Google/GitHub/SAML-adjacent social login" is on
most consumer and a lot of enterprise applications. It's **inherently prone to
implementation mistakes** because the spec is complex and most integrators
copy-paste a tutorial. Flaws here routinely reach full account takeover or
authorization-code interception.

Note the legacy split: OAuth **1a** still exists on older sites and is completely
different from 2.0. Academy material refers to 2.0 only.

## Always run discovery first

Before testing anything:

```bash
curl -s https://target.com/.well-known/openid-configuration
```

Stepankin's explicit advice: whenever you see an OAuth flow, assume OIDC is also
supported and try this endpoint. It exposes the authorization endpoint, token
endpoint, userinfo endpoint, JWKS, and **supported `response_types` and grant
types** — free reconnaissance in a black-box assessment.

Everything else depends on knowing which of these are in play:

| Parameter | What it tells you |
| --- | --- |
| `response_type=code` | Authorization code flow — most common, best practice |
| `response_type=token` | Implicit flow — token in the URL fragment, legacy |
| `response_type=id_token` | OIDC hybrid |
| `grant_type=authorization_code` | Code exchange |
| `grant_type=implicit` | No backend, token in browser |

Also: try `/register` (Dynamic Client Registration) even though it appears in no
client-side HTML. See vector 1 below.

## Classic vectors

**`redirect_uri` manipulation** — the centerpiece. Open redirects on OAuth
usually escalate to authorization-code or token theft, because the code lands on
an attacker-controlled URL.

Test for: missing allowlist, subdomain wildcard (`*.target.com` accepting
`evil.target.com.attacker's.com`), open redirect chained in, URL parsing
differential, and fragment/query confusion. `portswigger-techniques.md` covers
the URL-validation bypass class in depth.

**CSRF / login CSRF** — the `state` parameter. If it's missing, an attacker can
force a victim to bind their account to the attacker's identity. If it's present
but not bound to the session, it validates nothing.

**Token leakage in the referrer** — tokens in the fragment don't hit the server,
but the authorization `code` in a query string does. Check the Referer header
flowing from the callback page to third parties.

**Scope escalation** — ask for more than you should. Request
`scope=openid email profile` when the app only needs email. Weak scope validation
means a legit-looking client gets broader access than intended.

**Weak or missing `nonce`** on OIDC — nonce-less id_tokens enable replay.

## Hidden attack vectors (Stepankin 2021)

Three that don't appear in ordinary tutorials:

**1. Dynamic Client Registration — SSRF by design.** The `/register` endpoint
(RFC 7591 for OAuth, OpenID Connect Registration 1.0 for OIDC) accepts client
metadata including `client_name`, `client_secret`, and **`redirect_uris`** — all
URL references, all SSRF candidates. Most servers don't resolve them on receipt;
they store them and use them later during the authorization flow. That makes it
a **second-order SSRF**: the fetch happens outside the registration request, which
defeats blind in-request SSRF detectors. They demonstrated against ForgeRock
OpenAM and MITREid Connect.

**2. `redirect_uri` session poisoning.** Session state manipulated such that the
authorization response binds to the wrong session.

**3. WebFinger user enumeration.** The WebFinger endpoint
(`/.well-known/webfinger?resource=acct:...`) can leak valid accounts.

## OpenID Connect specifics

OIDC layers identity on top of OAuth. Same three roles, renamed:

- **Relying party** = the client app
- **End user** = the resource owner
- **OpenID provider** = the OAuth service supporting OIDC

Standard scopes are identical across providers, unlike plain OAuth:

| Scope | Claims |
| --- | --- |
| `openid` | required, signals an OIDC request |
| `profile` | `family_name`, `given_name`, `birth_date`, ... |
| `email` | email address and verification status |
| `address` | address claims |
| `phone` | phone number |

The key addition is **`id_token`** — a JWT signed with JWS. Its claims tell the
client when and how the user authenticated, so the client can decide whether the
authentication was sufficient (MFA freshness, etc.).

Attack surface that follows: **signature verification** (`alg: none`, key
confusion RS256→HS256), **claim validation** (is `iss` right, is `aud` your
client), and **`nonce`** (replay). PortSwigger's `SignSaboteur`
(`https://portswigger.net/research/introducing-signsaboteur-forge-signed-web-tokens-with-ease`)
exists for forging signed tokens during testing.

## Testing order

1. `/.well-known/openid-configuration` — map the surface.
2. Identify the flow and grant type from the authorize request.
3. Register a client if `/register` is open. Registering your own client is
   legitimate testing on an in-scope host; confirm the host is in scope first.
4. Walk the full flow in Burp and inspect every request — especially `state`,
   `nonce`, `redirect_uri` validation, and what the callback does with `error`.
5. Replay the authorization code. Single-use enforced?
6. Swap accounts: bind A's code to B's session.
7. Test scope escalation by requesting more than the UI offers.
8. If id_tokens appear, check algorithm, issuer, audience, and nonce.

## Rules

- Register a client on hosts that are in scope, and close it when done if the
  endpoint lets you. Leave no artifacts.
- Don't complete an OAuth flow that binds a real user's account to your client.
- Use your own test accounts throughout.

## Report framing

"Full account takeover" is the impact line that gets paid. Show the complete
chain — the manipulated request, the resulting redirect, and what the attacker
captures. Specify whether a victim must click a link, and whether the attacker
needs an existing account on the target. State which grant type and whether the
target supports OIDC.