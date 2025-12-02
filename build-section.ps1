# PowerShell script to convert DocFx toc.yml files to Mintlify pages structure
# This script traverses all toc.yml files and generates complete JSON structure

param(
    [Parameter(Mandatory=$true)]
    [string]$TocFile,
    
    [string]$LanguagePrefix,
    
    [string]$OutputFile,
    
    [int]$IndentLevel = 2
)

$ErrorActionPreference = "Stop"

# Helper function to parse YAML toc.yml file and build item tree
function Parse-TocYaml {
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Warning "TOC file not found: $FilePath"
        return @()
    }
    
    $content = Get-Content $FilePath -Raw
    $lines = $content -split "`r?`n"
    
    $items = @()
    $currentItem = $null
    
    foreach ($line in $lines) {
        # Skip empty lines, comments, the top-level "items:" line, and topicHref lines
        if ($line -match '^\s*$' -or $line -match '^\s*#' -or $line -match '^items:\s*$' -or $line -match '^\s+topicHref:') {
            continue
        }
        
        # Match "- name:" at any indentation level (this starts a new item)
        if ($line -match '^\s*- name:\s*(.+)$') {
            # Save previous item if exists
            if ($currentItem) {
                $items += $currentItem
            }
            
            $name = $matches[1].Trim().Trim('"').Trim("'")
            $currentItem = @{
                Name = $name
                Href = $null
            }
        }
        elseif ($line -match '^\s+href:\s*(.+)$' -and $currentItem) {
            $href = $matches[1].Trim().Trim('"').Trim("'")
            $currentItem.Href = $href
        }
    }
    
    # Add last item
    if ($currentItem) {
        $items += $currentItem
    }
    
    return $items
}

# Convert TOC items to Mintlify pages structure with full recursion
function ConvertTo-MintlifyPages {
    param(
        [array]$TocItems,
        [string]$BaseDir,
        [string]$CurrentDir,
        [string]$LanguagePrefix
    )
    
    $pages = @()
    
    foreach ($item in $TocItems) {
        $pageRef = $null
        $nestedPages = @()
        $hasNestedToc = $false
        
        # Check if href points to a nested toc.yml
        if ($item.Href -and $item.Href -match '\.yml$') {
            # Resolve the path to the nested TOC
            $tocPath = Join-Path $CurrentDir $item.Href
            $tocPath = [System.IO.Path]::GetFullPath($tocPath)
            
            if (Test-Path $tocPath) {
                Write-Host "  Traversing nested TOC: $($item.Href)" -ForegroundColor Cyan
                $hasNestedToc = $true
                $nestedItems = Parse-TocYaml -FilePath $tocPath
                $nestedDir = Split-Path $tocPath
                $nestedPages = ConvertTo-MintlifyPages -TocItems $nestedItems -BaseDir $BaseDir -CurrentDir $nestedDir -LanguagePrefix $LanguagePrefix
            } else {
                Write-Warning "Nested TOC not found: $tocPath"
            }
        }
        elseif ($item.Href -and $item.Href -notmatch '\.yml$') {
            # Regular markdown file - resolve full path from current directory
            $fullPath = Join-Path $CurrentDir $item.Href
            $fullPath = [System.IO.Path]::GetFullPath($fullPath)
            
            # Get relative path from BaseDir
            $relativePath = [System.IO.Path]::GetRelativePath($BaseDir, $fullPath)
            $pageRef = $relativePath -replace '\.md$', '' -replace '\\', '/'
            
            # Add language prefix if needed
            if ($LanguagePrefix -and $pageRef -notmatch "^$LanguagePrefix/") {
                $pageRef = "$LanguagePrefix/$pageRef"
            }
        }
        
        # Build the structure
        if ($hasNestedToc) {
            # This is a group with nested pages
            $group = [ordered]@{
                group = $item.Name
                pages = $nestedPages
            }
            
            $pages += $group
        }
        elseif ($pageRef) {
            # Simple page reference
            $pages += $pageRef
        }
    }
    
    return $pages
}

# Main execution
Write-Host "Mintlify Pages Builder" -ForegroundColor Cyan
Write-Host "=====================`n" -ForegroundColor Cyan

# Resolve paths
$tocPath = [System.IO.Path]::GetFullPath($TocFile)
if (-not (Test-Path $tocPath)) {
    Write-Error "TOC file not found: $tocPath"
    exit 1
}

# Use the workspace root (where the toc file's language folder is)
$tocDir = Split-Path $tocPath
# Go up to find the workspace root (parent of language folders like 'en', 'no', etc.)
$baseDir = Split-Path $tocDir

Write-Host "TOC File: $tocPath" -ForegroundColor Yellow
Write-Host "Base Dir: $baseDir" -ForegroundColor Yellow
if ($LanguagePrefix) {
    Write-Host "Language Prefix: $LanguagePrefix" -ForegroundColor Yellow
}
Write-Host ""

# Parse the TOC file
Write-Host "Parsing TOC structure..." -ForegroundColor Cyan
$tocItems = Parse-TocYaml -FilePath $tocPath

Write-Host "Found $($tocItems.Count) top-level items" -ForegroundColor Green

# Convert to Mintlify pages structure
Write-Host "`nConverting to Mintlify pages..." -ForegroundColor Cyan
$mintlifyPages = ConvertTo-MintlifyPages -TocItems $tocItems -BaseDir $baseDir -CurrentDir $tocDir -LanguagePrefix $LanguagePrefix

# Convert to JSON
$jsonOutput = $mintlifyPages | ConvertTo-Json -Depth 20 -Compress:$false

# Add proper indentation
$indent = " " * $IndentLevel
$jsonOutput = $jsonOutput -split "`r?`n" | ForEach-Object {
    if ($_ -match '^\s*\{' -or $_ -match '^\s*\[' -or $_ -match '^\s*\}' -or $_ -match '^\s*\]' -or $_ -match '^\s*"') {
        $indent + $_
    } else {
        $_
    }
} | Out-String

# Output results
Write-Host "`nGenerated Mintlify Pages:" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host $jsonOutput

if ($OutputFile) {
    $outputPath = [System.IO.Path]::GetFullPath($OutputFile)
    $jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Host "`nOutput saved to: $outputPath" -ForegroundColor Green
}

Write-Host "`nConversion complete!" -ForegroundColor Green
