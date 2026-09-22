param(
    [Parameter(Mandatory=$true)][string]$Path,
    [int]$MaxLen = 4096,
    [string]$OutFile = "run-commands.txt"
)

$raw   = Get-Content -Path $Path -Raw
$lines = ($raw -replace "`r","") -split "`n"

$header = New-Object System.Collections.Generic.List[string]
$idx = 0
while ($idx -lt $lines.Count) {
    $l = $lines[$idx]
    if ($l -match '^\s*S\s+"' -or $l -match '^\s*"#') { break }
    $header.Add($l); $idx++
}
$headerText = (($header -join "`n").TrimEnd()) + "`n"

$units = @()
for ($i = $idx; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim().Length -gt 0) { $units += $lines[$i] }
}

function Enc([string]$s) { [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($s)) }
$prefix = "powershell -e "

function CmdFor([string[]]$sel) {
    $script = $headerText + (($sel -join "`n")) + "`n"
    return $prefix + (Enc $script)
}

$cmds = New-Object System.Collections.Generic.List[string]
$cur  = @()
foreach ($u in $units) {
    $trial = $cur + $u
    if ($cur.Count -gt 0 -and (CmdFor $trial).Length -gt $MaxLen) {
        $cmds.Add((CmdFor $cur))
        $cur = @($u)
    } else {
        $cur = $trial
    }
}
if ($cur.Count -gt 0) { $cmds.Add((CmdFor $cur)) }

$cmds | Set-Content -Path $OutFile -Encoding ASCII

Write-Host "Wrote $($cmds.Count) command(s) to $OutFile"
$n = 0
foreach ($c in $cmds) {
    $n++
    $flag = if ($c.Length -gt $MaxLen) { "  <-- OVER LIMIT" } else { "" }
    Write-Host ("  line {0}: {1} chars{2}" -f $n, $c.Length, $flag)
}
