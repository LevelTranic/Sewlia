#!/usr/bin/env pwsh

# Powered by Transoft, distributed in the GPL-3 protocol.
# https://github.com/LevelTranic

function exit_on_error {
    param (
        [string]$message
    )
    Write-Host $message
    exit 1
}

# git reset --hard HEAD

$fileContent = Get-Content -Path "gradle.properties"

$oldHash = $null
foreach ($line in $fileContent) {
    if ($line -match "^foliaCommit = (.*)$") {
        $oldHash = $matches[1].Trim()
        break
    }
}

if (-not $oldHash) {
    Write-Host "Error: Could not find 'foliaCommit' in gradle.properties."
    exit 1
}

$newHash = (Invoke-RestMethod -Uri "https://api.github.com/repos/PaperMC/Folia/commits/dev/1.21.1").sha

if (-not $newHash) {
    Write-Error "Failure to get key information in the API"
    exit 1
}

if ($oldHash -eq $newHash) {
    Write-Host "Upstream has not updated!"
    exit 0
}

Write-Host "Updating Folia: $oldHash -> $newHash"

(Get-Content gradle.properties) -replace "foliaCommit = $oldHash", "foliaCommit = $newHash" | Set-Content gradle.properties

git add gradle.properties

./gradlew applyPatches || exit_on_error "An error occurred when merging patches!"
./gradlew rebuildPatches || exit_on_error "An error occurred when rebuilding patches!"
./gradlew createMojmapPaperclipJar || exit_on_error "An error occurred when building!"

scripts/upstreamCommit.ps1 $oldHash $newHash

Write-Host "Created new commit, please review before pushing."
