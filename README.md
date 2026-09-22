# WinPEAS-lite

A native-PowerShell, **read-only** host enumeration collector. It runs a set of
recon checks and writes a clean, navigable **Markdown report**. Because a single
`powershell -e <base64>` command can outgrow the shell's command-line limit, the
script is split into several small base64 chunks, each runnable on its own line.

## Files

| File | Purpose |
|------|---------|
| `winPEAS-lite.ps1` | The master script. 75 read-only sections, each emits a `## Heading` + fenced output. |
| `Chunk-Enc.ps1` | Splits any script into `powershell -e <blob>` lines under a length limit. |

## What it collects

System/hardware, users/groups/privileges/sessions, full network state, processes,
services (incl. unquoted paths & writable binaries), autoruns, disks/shadow copies,
shares, installed software/drivers, scheduled tasks, credential *locations*
(DPAPI/Vault/RDP/config files), certificates, event logs, domain info
(users/groups/SPNs/GPP-cpassword), defender/AV, and more. It only **reads** — no
dumping, no persistence, no changes.

## Why chunking

`powershell -e` takes **base64 of UTF-16LE** bytes. That blob is passed on the
command line, which `cmd.exe` caps at **8191 characters** (and some shells cap
lower). The full script's blob exceeds that, so it's split so every
`powershell -e <blob>` line stays under a chosen limit. Each chunk is
self-contained — it carries the shared header (error settings + the `S` helper
that formats each section), so any chunk runs standalone and in any order.

## Generate the chunks

```powershell
powershell -ep bypass -f Chunk-Enc.ps1 -Path .\winPEAS-lite.ps1 -MaxLen 4096 -OutFile run-commands.txt
```

- `-Path`    the script to encode
- `-MaxLen`  max characters per `powershell -e` line (default 4096; lower it for a tighter shell)
- `-OutFile` where the command lines are written

It prints how many commands it produced and each line's length (flagging any
`OVER LIMIT`). Re-run it any time you edit `winPEAS-lite.ps1`.

> Manual one-off encode (no chunking) from PowerShell:
> ```powershell
> [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content .\winPEAS-lite.ps1 -Raw)))
> ```
> Or on Linux: `iconv -t UTF-16LE < winPEAS-lite.ps1 | base64 -w0`

## Run on target and build the report

Open `run-commands.txt` and run each line **in order**, appending to one file:

```cmd
powershell -e <blob-1> >> report.md
powershell -e <blob-2> >> report.md
...
```

The first chunk writes the `# ...Report` title; the rest append their `##`
sections. Open `report.md` in any Markdown viewer — headings make it navigable,
and long paths/tables are rendered wide so nothing is truncated.

Running the whole script directly (no chunking) also works:

```powershell
powershell -ep bypass .\winPEAS-lite.ps1 > report.md
```

## Good to know

- **Two slow sections:** `SENSITIVE FILES` (walks all of `C:\`) and
  `WRITABLE PROGRAM FILES BINARIES` (write-tests every exe/dll) can take 30–90s.
- **Encoding must be UTF-16LE.** Plain UTF-8 base64 will fail with `-e`.
- **Domain sections** auto-skip on non-domain hosts (they print `Not domain-joined`).
- **Authorized / CTF / lab use only.**
