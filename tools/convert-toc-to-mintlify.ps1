#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Converts a DocFx toc.yml file to Mintlify navigation JSON format.

.DESCRIPTION
    This script reads a DocFx-style toc.yml file and converts it to Mintlify's
    navigation structure, outputting JSON that can be inserted into docs.json.

.PARAMETER TocPath
    Path to the source toc.yml file to convert.

.PARAMETER TabName
    The name of the tab to create in Mintlify navigation.

.PARAMETER TabIcon
    The icon for the tab (optional, defaults to "book").

.PARAMETER BasePath
    Base path prefix to prepend to all page paths (e.g., "en/developer-portal").

.PARAMETER OutputType
    Type of output: "Tab" (complete tab structure), "Groups" (groups array), or "Group" (single group object). Defaults to "Tab".

.PARAMETER GroupName
    Name for the group when OutputType is "Group". If not specified, uses the first item's name.

.PARAMETER OutputFile
    Path to write the JSON output (optional, outputs to console if not specified).

.EXAMPLE
    .\convert-toc-to-mintlify.ps1 -TocPath "en\developer-portal\toc.yml" -TabName "Developer Portal" -TabIcon "laptop-code" -BasePath "en/developer-portal"

.EXAMPLE
    .\convert-toc-to-mintlify.ps1 -TocPath "en\api\toc.yml" -BasePath "en/api" -OutputType "Group" -GroupName "Web Services"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TocPath,
    
    [Parameter(Mandatory=$false)]
    [string]$TabName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TabIcon = "book",
    
    [Parameter(Mandatory=$false)]
    [string]$BasePath = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Tab", "Groups", "Group")]
    [string]$OutputType = "Tab",
    
    [Parameter(Mandatory=$false)]
    [string]$GroupName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = ""
)

function Convert-YamlPath {
    param([string]$href)
    
    if ([string]::IsNullOrWhiteSpace($href)) {
        return $null
    }
    
    # Skip toc.yml references (these should already be expanded)
    if ($href -match 'toc\.yml$') {
        return $null
    }
    
    # Clean up path - remove extension, normalize slashes
    $path = $href -replace '\.md$', '' -replace '^/', '' -replace '\\', '/'
    
    # Add base path if provided
    if ($BasePath) {
        $cleanBase = $BasePath -replace '\\', '/'
        $path = "$cleanBase/$path" -replace '//', '/'
    }
    
    return $path
}

function Expand-NestedToc {
    param(
        [string]$TocPath,
        [string]$ParentDir
    )
    
    Write-Host "  Expanding: $TocPath" -ForegroundColor DarkGray
    
    # Validate the path is actually a file path, not a directory
    if (-not $TocPath.EndsWith('.yml')) {
        Write-Warning "  Invalid TocPath (not a .yml file): $TocPath"
        return @()
    }
    
    if (-not (Test-Path $TocPath)) {
        Write-Warning "  Nested toc.yml not found: $TocPath"
        return @()
    }
    
    $lines = Get-Content $TocPath
    $tocDir = Split-Path -Parent $TocPath
    $relativePrefix = if ($ParentDir) {
        # Calculate relative path manually (PS 5.1 doesn't have GetRelativePath)
        $parentPath = $ParentDir.TrimEnd('\', '/') -replace '\\', '/'
        $tocPath = $tocDir.TrimEnd('\', '/') -replace '\\', '/'
        
        # Remove common prefix
        if ($tocPath.StartsWith($parentPath + '/')) {
            $rel = $tocPath.Substring($parentPath.Length + 1)
            $rel + '/'
        }
        elseif ($tocPath -eq $parentPath) {
            ''
        }
        else {
            # Different paths - calculate manually
            $parentParts = $parentPath -split '/'
            $tocParts = $tocPath -split '/'
            
            # Find common prefix length
            $commonLength = 0
            $minLength = [Math]::Min($parentParts.Length, $tocParts.Length)
            for ($i = 0; $i -lt $minLength; $i++) {
                if ($parentParts[$i] -eq $tocParts[$i]) {
                    $commonLength++
                }
                else {
                    break
                }
            }
            
            # Build relative path
            $upLevels = $parentParts.Length - $commonLength
            $downParts = $tocParts[$commonLength..($tocParts.Length - 1)]
            
            $rel = ('../' * $upLevels) + ($downParts -join '/')
            if ($rel) { $rel + '/' } else { '' }
        }
    } else { '' }
    
    $expandedLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check for nested toc.yml reference
        if ($line -match '^\s*href:\s*(.+toc\.yml)\s*$') {
            $nestedTocRef = $Matches[1].Trim()
            $nestedTocPath = Join-Path $tocDir $nestedTocRef
            
            if (-not (Test-Path $nestedTocPath)) {
                # Get the name for placeholder
                $itemName = ''
                for ($j = $i - 1; $j -ge 0; $j--) {
                    if ($lines[$j] -match '^(\s*)- name:\s*(.+)$') {
                        $itemName = $Matches[2].Trim()
                        break
                    }
                }
                Write-Warning "  Nested toc.yml not found: $nestedTocRef (from $TocPath)"
                if ($itemName) {
                    # Get indentation of name line
                    $nameIndent = ''
                    if ($lines[$j] -match '^(\s*)- name:') {
                        $nameIndent = $Matches[1]
                    }
                    $expandedLines += "$nameIndent- name: $itemName"
                }
                continue
            }
            
            # Get the indentation of the href line
            $hrefIndent = ''
            if ($line -match '^(\s*)href:') {
                $hrefIndent = $Matches[1]
            }
            
            # Get the name from previous line(s)
            $nameIndent = ''
            $itemName = ''
            for ($j = $i - 1; $j -ge 0; $j--) {
                if ($lines[$j] -match '^(\s*)- name:\s*(.+)$') {
                    $nameIndent = $Matches[1]
                    $itemName = $Matches[2].Trim()
                    break
                }
            }
            
            # Recursively expand the nested toc (keep as relative path for proper relative path calculation)
            $nestedLines = Expand-NestedToc -TocPath $nestedTocPath -ParentDir $tocDir
            
            if ($nestedLines.Count -gt 0) {
                # Remove the "items:" line if it's the first line
                if ($nestedLines[0] -match '^\s*items:\s*$') {
                    $nestedLines = $nestedLines[1..($nestedLines.Count - 1)]
                }
                
                # Adjust indentation and paths in nested content
                $indentAdjust = $hrefIndent.Length - 2  # -2 because nested items start at indent 2
                
                foreach ($nestedLine in $nestedLines) {
                    if ([string]::IsNullOrWhiteSpace($nestedLine)) {
                        continue
                    }
                    
                    # Calculate new indentation
                    $nestedIndent = ''
                    if ($nestedLine -match '^(\s*)') {
                        $nestedIndent = $Matches[1]
                    }
                    $newIndent = ' ' * ($nestedIndent.Length + $indentAdjust)
                    $content = $nestedLine.Trim()
                    
                    # Adjust paths in href and topicHref
                    if ($content -match '^((?:topic)?href):\s*(.+)$') {
                        $hrefType = $Matches[1]
                        $hrefValue = $Matches[2].Trim()
                        
                        # Skip nested toc.yml references (should already be expanded)
                        if ($hrefValue -notmatch 'toc\.yml$') {
                            # Prepend the relative path prefix
                            $adjustedPath = $relativePrefix + $hrefValue
                            $expandedLines += "$newIndent$hrefType`: $adjustedPath"
                        }
                    }
                    else {
                        # Non-href line, just adjust indentation
                        $expandedLines += "$newIndent$content"
                    }
                }
                
                # Skip the href: toc.yml line (already processed)
                continue
            }
            else {
                # Failed to expand, create a placeholder entry with the name
                if ($itemName) {
                    Write-Warning "  Could not expand nested toc, creating placeholder for: $itemName"
                    $expandedLines += "$nameIndent- name: $itemName"
                }
                continue
            }
        }
        
        # Regular line, add with path adjustment if needed
        if ($line -match '^\s*((?:topic)?href):\s*(.+)$') {
            $hrefType = $Matches[1]
            $hrefValue = $Matches[2].Trim()
            
            # Skip toc.yml references at this level (they'll be handled above)
            if ($hrefValue -match 'toc\.yml$') {
                # This shouldn't happen if we're processing correctly, but skip anyway
                continue
            }
            
            # Get indentation
            $indent = ''
            if ($line -match '^(\s*)') {
                $indent = $Matches[1]
            }
            
            # Prepend relative prefix to paths
            $adjustedPath = $relativePrefix + $hrefValue
            $expandedLines += "$indent$hrefType`: $adjustedPath"
        }
        else {
            # Non-href line, keep as-is
            $expandedLines += $line
        }
    }
    
    return $expandedLines
}

function Read-YamlFile {
    param([string]$FilePath)
    
    $lines = Get-Content $FilePath
    $result = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Calculate indentation
        $indent = 0
        if ($line -match '^(\s*)') {
            $indent = $Matches[1].Length
        }
        $content = $line.Trim()
        
        # Skip root "items:" declaration
        if ($content -eq 'items:' -and $indent -eq 0) {
            continue
        }
        
        # Handle list item with name
        if ($content -match '^- name:\s*(.+)$') {
            $name = $Matches[1].Trim()
            
            $item = @{
                name = $name
                indent = $indent
                href = $null
                topicHref = $null
                items = @()
            }
            
            # Look ahead for href, topicHref, and child items
            $j = $i + 1
            $itemIndent = $indent + 2
            
            while ($j -lt $lines.Count) {
                $nextLine = $lines[$j]
                
                if ([string]::IsNullOrWhiteSpace($nextLine)) {
                    $j++
                    continue
                }
                
                $nextIndent = 0
                if ($nextLine -match '^(\s*)') {
                    $nextIndent = $Matches[1].Length
                }
                $nextContent = $nextLine.Trim()
                
                # If we're back to same or lower indent level, stop
                if ($nextIndent -lt $itemIndent) {
                    break
                }
                
                # Parse href
                if ($nextContent -match '^href:\s*(.+)$') {
                    $item.href = $Matches[1].Trim()
                }
                # Parse topicHref
                elseif ($nextContent -match '^topicHref:\s*(.+)$') {
                    $item.topicHref = $Matches[1].Trim()
                }
                # Parse nested items
                elseif ($nextContent -eq 'items:') {
                    # Mark that this item has children
                    $item.hasChildren = $true
                }
                
                $j++
            }
            
            # Add to appropriate parent based on indentation
            if ($indent -eq 2) {
                # Top level item (child of root)
                $result += $item
            }
            else {
                # Find the parent based on indentation
                $parentIndent = $indent - 4
                $parent = $null
                
                for ($k = $result.Count - 1; $k -ge 0; $k--) {
                    if ($result[$k].indent -eq $parentIndent) {
                        $parent = $result[$k]
                        break
                    }
                    # Also check nested items
                    foreach ($candidate in $result[$k].items) {
                        if ($candidate.indent -eq $parentIndent) {
                            $parent = $candidate
                            break
                        }
                    }
                    if ($parent) { break }
                }
                
                if ($parent) {
                    $parent.items += $item
                }
                else {
                    # Fallback: add to last top-level item
                    if ($result.Count -gt 0) {
                        $result[$result.Count - 1].items += $item
                    }
                }
            }
        }
    }
    
    return $result
}

function Convert-ToMintlifyGroup {
    param([hashtable]$Item)
    
    $group = @{
        group = $Item.name
        pages = @()
    }
    
    # Add main page if exists (prefer topicHref over href)
    # Skip if topicHref matches first child's href (Mintlify drilldown handles this)
    $mainPath = $null
    $skipTopicHref = $false
    
    if ($Item.topicHref -and $Item.items.Count -gt 0) {
        # Check if topicHref matches first child's href
        $firstChildHref = $null
        if ($Item.items[0].href) {
            $firstChildHref = $Item.items[0].href
        }
        elseif ($Item.items[0].topicHref) {
            $firstChildHref = $Item.items[0].topicHref
        }
        
        if ($firstChildHref -and $Item.topicHref -eq $firstChildHref) {
            $skipTopicHref = $true
        }
    }
    
    if (-not $skipTopicHref) {
        if ($Item.topicHref) {
            $mainPath = Convert-YamlPath $Item.topicHref
        }
        elseif ($Item.href) {
            $mainPath = Convert-YamlPath $Item.href
        }
        
        if ($mainPath) {
            $group.pages += $mainPath
        }
    }
    
    # Add child items
    foreach ($child in $Item.items) {
        if ($child.items.Count -gt 0) {
            # Has sub-items, create nested group
            $nestedGroup = Convert-ToMintlifyGroup $child
            $group.pages += $nestedGroup
        }
        else {
            # Leaf item, add as page
            $childPath = $null
            if ($child.topicHref) {
                $childPath = Convert-YamlPath $child.topicHref
            }
            elseif ($child.href) {
                $childPath = Convert-YamlPath $child.href
            }
            
            if ($childPath) {
                $group.pages += $childPath
            }
        }
    }
    
    return $group
}

# Parse the YAML file
Write-Host "Parsing $TocPath..." -ForegroundColor Cyan

# First, expand any nested toc.yml references
Write-Host "Expanding nested toc.yml files..." -ForegroundColor Cyan
$tocDir = Split-Path -Parent $TocPath
$expandedLines = Expand-NestedToc -TocPath $TocPath -ParentDir $null

# Create a temporary expanded toc file
$tempTocPath = [System.IO.Path]::GetTempFileName()
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($tempTocPath, $expandedLines, $utf8NoBom)

# Parse the expanded YAML
$items = Read-YamlFile $tempTocPath

# Clean up temp file
Remove-Item $tempTocPath -Force

if ($items.Count -eq 0) {
    Write-Error "No items found in YAML file"
    exit 1
}

Write-Host "Found $($items.Count) top-level items" -ForegroundColor Cyan

# Build groups array
$groups = @()
foreach ($item in $items) {
    $group = Convert-ToMintlifyGroup $item
    $groups += $group
}

Write-Host "Created $($groups.Count) groups" -ForegroundColor Cyan

# Create output based on type
if ($OutputType -eq "Tab") {
    # Validate required parameters for Tab output
    if ([string]::IsNullOrWhiteSpace($TabName)) {
        Write-Error "TabName is required when OutputType is 'Tab'"
        exit 1
    }
    
    $output = @{
        tab = $TabName
        icon = $TabIcon
        groups = $groups
    }
}
elseif ($OutputType -eq "Groups") {
    # Output the groups array
    $output = $groups
}
else {
    # Output a single group object containing all pages
    $groupName = if ([string]::IsNullOrWhiteSpace($GroupName)) {
        $items[0].name
    } else {
        $GroupName
    }
    
    # Flatten all groups into a single group's pages
    $allPages = @()
    foreach ($group in $groups) {
        if ($group.pages) {
            $allPages += $group.pages
        }
    }
    
    $output = @{
        group = $groupName
        pages = $allPages
    }
}

# Convert to JSON
$json = $output | ConvertTo-Json -Depth 20

# Output
if ($OutputFile) {
    # Use UTF8 without BOM for consistency (PS 5.1 adds BOM with -Encoding UTF8)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($OutputFile, $json, $utf8NoBom)
    Write-Host "Converted to Mintlify format: $OutputFile" -ForegroundColor Green
    
    # Delete all toc.yml files in the processed directory tree after successful conversion
    Write-Host "Cleaning up toc.yml files..." -ForegroundColor Cyan
    $tocBaseDir = Split-Path -Parent $TocPath
    $allTocFiles = Get-ChildItem -Path $tocBaseDir -Filter "toc.yml" -Recurse -File
    
    $deletedCount = 0
    foreach ($tocFile in $allTocFiles) {
        Remove-Item $tocFile.FullName -Force
        Write-Host "  Deleted: $($tocFile.FullName -replace [regex]::Escape($tocBaseDir), '.')" -ForegroundColor DarkGray
        $deletedCount++
    }
    
    Write-Host "Deleted $deletedCount toc.yml file(s)" -ForegroundColor Green
}
else {
    Write-Output $json
}

exit 0