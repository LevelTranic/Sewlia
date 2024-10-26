#!/usr/bin/env pwsh

# Powered by Transoft, distributed in the GPL-3 protocol.
# https://github.com/LevelTranic

# upstreamCommit <baseHash> <newHash>
# param: baseHash - the commit hash to use for comparing commits (baseHash...newHash)
# param: newHash - the commit hash to use for comparing commits

param (
    [string]$baseHash,
    [string]$newHash
)

function exit_on_error {
    param (
        [string]$message
    )
    Write-Host $message
    exit 1
}

try {
    $shreddedPaperResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/PaperMC/Folia/compare/$baseHash...$newHash" -Headers @{ Accept = "application/vnd.github.v3+json" }
    $shreddedPaperCommits = $shreddedPaperResponse.commits | ForEach-Object {
        "PaperMC/Folia@$($_.sha.Substring(0, 7)) $($_.commit.message.Split("`r`n")[0].Split("`n")[0])"
    }

    $updated = ""
    $logsuffix = ""
    if ($shreddedPaperCommits) {
        $logsuffix = "`n`nFolia Changes:`n$($shreddedPaperCommits -join "`n")"
        $updated = "Folia"
    }
    $disclaimer = "Upstream has released updates that appear to apply and compile correctly"
    $log = "${env:UP_LOG_PREFIX}Updated Upstream ($updated)`n`n${disclaimer}${logsuffix}"

    $log | Out-File -FilePath "commit_message.txt" -Encoding utf8
    git commit -F "commit_message.txt"
    Remove-Item -Path "commit_message.txt" -Force
} catch {
    exit_on_error $_.Exception.Message
}