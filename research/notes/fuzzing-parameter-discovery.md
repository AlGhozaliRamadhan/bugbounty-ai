---
title: Fuzzing and parameter discovery
date: 2026-10-16
type: technique
status: current
verified: 2026-10-16
sources:
  - https://raw.githubusercontent.com/ffuf/ffuf/master/README.md (GET - primary)
  - https://github.com/ffuf/ffuf/releases/latest
---

# Fuzzing and parameter discovery

**Fresh lookup, 2026-10-16.** Flags below are taken from the ffuf README, which
is the authoritative source. ffuf is installed here; see `docs/environment.md`.

Fuzzing has four jobs: **find content**, **find parameters**, **find values that
change behaviour**, and **find hidden virtual hosts**. They want different
filters, and using the wrong filter is why people conclude "nothing there".

## Parameter discovery first

You cannot fuzz a parameter you haven't found, and parameters are where the
interesting bugs live. Get the list before you fuzz:

```bash
# from collected URLs
cat urls.txt | gf qurl | grep -E '\?' | sort -u > params.txt

# extract distinct parameter NAMES, not full URLs
cat urls.txt | grep -oE '[?&][a-zA-Z0-9_.-]+=' | sed 's/[?&]//; s/=//' | sort -u > param_names.txt
```

Wordlist, not guesswork:

```bash
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
     -u "https://target/page.php?FUZZ=test_value" -fs 4242 -rate 50
```

**The `-fs 4242` idiom is from the ffuf README itself** — a size that means
"nothing here". Find your own by requesting a definitely-absent parameter once and
noting the response size.

## Filters: match vs filter

This is the part that matters, and mixing them up costs entire runs.

| Flag | Meaning |
| --- | --- |
| `-mc` / `--match-http-status` | only report these status codes |
| `-fc` / `--filter-http-status` | hide these status codes |
| `-ms` / `--match-size` | only report these response sizes |
| `-fs` / `--filter-size` | hide these response sizes |
| `-ml` / `--match-lines`, `-fl` / `--filter-lines` | same, by line count |
| `-mw` / `--match-words`, `-fw` / `--filter-words` | same, by word count |
| `-mr` / `--match-regex` | only report responses matching a regex |
| `-fr` / `--filter-regex` | hide responses matching a regex |

`-fc 404` is the common baseline, but it is not sufficient: many apps return
**200 with "not found" in the body**, and a 403 blanket redirect masks real
findings. Check whether the app uses a soft 404 before trusting `-fc 404`.

## The four jobs

**Content discovery** — README verbatim, plus extensions and rate:

```bash
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
     -u https://target/FUZZ -e .php,.html,.json,.txt,.bak,.old,.zip \
     -mc all -fc 404 -rate 50 -t 20 -s -o out.json
```

**GET parameter fuzzing** — two directions, and the second is underused:

```bash
# find parameter NAMES
ffuf -w paramnames.txt -u "https://target/script.php?FUZZ=test_value" -fs 4242

# find parameter VALUES that change behaviour
ffuf -w values.txt -u "https://target/script.php?valid_name=FUZZ" -fc 401
```

Fuzzing values is how you find an admin flag, a role parameter, or a hidden
filter. The `-fc 401` filter means "anything that doesn't 401 is interesting".

**POST data fuzzing**:

```bash
ffuf -w postdata.txt -X POST -d "username=admin&password=FUZZ" \
     -u https://target/login.php -fc 401
```

**Vhost discovery** — find hosts on a shared IP with no DNS record:

```bash
ffuf -w vhost/wordlist -u https://target -H "Host: FUZZ" -fs 4242
```

This finds internal names and forgotten admin panels that no subdomain enum will.

## Recursion and time limits

```bash
# depth-limited recursion
ffuf -w wordlist.txt -u https://target/FUZZ -maxtime-job 60 -recursion -recursion-depth 2

# absolute wall-clock cap, works with recursion
ffuf -w wordlist.txt -u https://target/FUZZ -maxtime 60 -recursion -recursion-depth 2
```

`-maxtime` is the total budget; `-maxtime-job` is per-job. **Set one of these on
any recursive run.** An unbounded recursive ffuf will happily run for hours and
walk straight into the program's rate limit.

## External mutation

```bash
ffuf --input-cmd 'radamsa --seed $FFUF_NUM example1.txt example2.txt' \
     -H "Content-Type: application/json" -X POST -u https://target/FUZZ \
     -mc all -fc 400
```

`$FFUF_NUM` expands per iteration, so you generate structured test cases rather
than a flat wordlist. `-fr "error"` is the right filter for JSON APIs.

## Interactive mode

The README documents interactive mode for inspecting matches as ffuf runs. It
exists precisely because reviewing 4,000 results in a JSON file afterwards is
slower and worse.

## Rules

- **Always set `-rate`.** Default is 50 here; against a bug bounty program that
  may already be too fast. `-rate 20` is a safer default for unfamiliar hosts.
- Recursion and large wordlists are the two things that get people rate-limited.
- Never fuzz on a host that isn't in `recon/<host>/scope.md`.
- `ffuf` cannot read `.gz` wordlists — gunzip first.

## Reporting

Directory discovery is only interesting if something is actually exposed: a
`.git` directory, a `.env`, a backup containing source, an admin panel without
auth. "I found 300 directories" is not a finding. See
`../research/notes/tbhm-methodology.md` for the application-hosting section that
covers what to do with a discovered directory.