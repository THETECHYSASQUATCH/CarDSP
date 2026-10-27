# Git index-lock permissions on Windows

The 2026-10-26 inspection found no .git/index.lock. Git status and index refresh succeeded with approved repository access, while the restricted chat account could not enter the repository. The .git directory has explicit deny entries for the restricted account; the interactive user has FullControl. This is evidence of an execution-access boundary, not a stale lock or damaged index.

Use an authorized PowerShell 7 session with access to this repository, or approve the agent's specific repository operation. Do not remove access-control protections, recursively grant permissions, or repeatedly delete index.lock to work around restricted access.

This complete diagnostic script preserves staged and unstaged changes. Index refresh updates cached file metadata; it does not stage file content. Exit code 1 can mean tracked files need updating.

```powershell
$ErrorActionPreference = 'Stop'
$repoPath = 'C:\Users\thetechysasquatch\Documents\GitHub\CarDSP'
try {
    git -C $repoPath status --short --branch
    if ($LASTEXITCODE -ne 0) { throw 'Cannot access repository. Check the execution account and approved folder access.' }
    $gitDirectory = git -C $repoPath rev-parse --absolute-git-dir
    if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve the Git directory.' }
    $lockPath = Join-Path $gitDirectory 'index.lock'
    if (Test-Path -LiteralPath $lockPath) {
        Get-Item -LiteralPath $lockPath | Select-Object FullName,LastWriteTime,Length
        Get-Process git* -ErrorAction SilentlyContinue
        Write-Warning 'Lock exists. Confirm its owner has finished before considering removal. This script does not remove it.'
    } else {
        git -C $repoPath update-index --refresh
        if ($LASTEXITCODE -gt 1) { throw 'Index refresh failed; inspect account permissions and the Git error.' }
        elseif ($LASTEXITCODE -eq 1) { Write-Warning 'Tracked files need updating; preserve local changes and inspect status.' }
        else { Write-Output 'Index refresh succeeded.' }
    }
    git -C $repoPath status --short --branch
    if ($LASTEXITCODE -ne 0) { throw 'Final Git status failed.' }
} catch {
    Write-Error $_
    exit 1
}
```

The origin URL is https://github.com/THETECHYSASQUATCH/CarDSP.git. Branches are independent: do not reset development/shared-dsp-ci to its remote; it has a local roadmap commit. Historical local main tracks a removed origin/main. Preserve it rather than silently repointing or deleting it.
