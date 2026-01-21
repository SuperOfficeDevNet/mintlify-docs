#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Converts a DocFx toc.yml file to Mintlify navigation JSON format.

.DESCRIPTION
    This script reads a DocFx-style toc.yml file and converts it to Mintlify's
    navigation structure, outputting JSON that can be inserted into docs.json.

    Supports recursive expansion of nested toc.yml files and creates nested
    group structures in Mintlify format.

    For more information about Mintlify navigation structure, see:
    https://www.mintlify.com/docs/organize/navigation

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

.NOTES
    Known Issues:
    - May generate duplicate entries when topicHref matches child hrefs. Review and deduplicate manually if needed.
    - Complex nesting with variable indentation (2-space and 4-space mixed) may have edge cases in parent-finding.
      The script handles most cases by finding the closest ancestor at lower indent.

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

# Resolve TocPath - if it's a directory, append toc.yml
if (Test-Path $TocPath -PathType Container) {
    $TocPath = Join-Path $TocPath "toc.yml"
    Write-Host "Resolved to: $TocPath" -ForegroundColor DarkGray
}

if (-not (Test-Path $TocPath)) {
    Write-Error "TOC file not found: $TocPath"
    exit 1
}

# Auto-generate OutputFile if not specified
if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    # Get directory path and create hyphenated filename
    $tocDir = Split-Path -Parent $TocPath
    $relativePath = $tocDir -replace '\\', '-' -replace '/', '-' -replace '^\.?-?', ''
    $OutputFile = "toc-$relativePath.json"
    Write-Host "Output file: $OutputFile" -ForegroundColor DarkGray
}

# Auto-detect BasePath if not specified
if ([string]::IsNullOrWhiteSpace($BasePath)) {
    $tocDir = Split-Path -Parent $TocPath
    $BasePath = $tocDir -replace '\\', '/'
    Write-Host "Auto-detected BasePath: $BasePath" -ForegroundColor DarkGray
}


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

    # Validate the path is actually a toc.yml file, not other .yml files (like landing pages)
    if (-not $TocPath.EndsWith('toc.yml')) {
        Write-Warning "  Skipping non-TOC file: $TocPath (only toc.yml files are expanded)"
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
    $skipUntilLine = -1  # Track lines to skip after processing nested toc.yml

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Skip lines that were already processed as part of nested toc expansion
        if ($i -le $skipUntilLine) {
            continue
        }

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

            # Get the name from previous line(s) and check for topicHref after
            $nameIndent = ''
            $itemName = ''
            $topicHref = $null
            for ($j = $i - 1; $j -ge 0; $j--) {
                if ($lines[$j] -match '^(\s*)- name:\s*(.+)$') {
                    $nameIndent = $Matches[1]
                    $itemName = $Matches[2].Trim()
                    break
                }
            }

            # Check if there's a topicHref on the next line(s) after href: toc.yml
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $nextLine = $lines[$j]
                if ([string]::IsNullOrWhiteSpace($nextLine)) {
                    continue
                }
                # If we hit another item at same/lower indent, stop
                if ($nextLine -match '^\s*- name:') {
                    break
                }
                if ($nextLine -match '^\s*topicHref:\s*(.+)$') {
                    $topicHref = $Matches[1].Trim()
                    break
                }
                # If we hit items: or another property at the parent item level, stop
                if ($nextLine -match '^\s*(items|href):') {
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

                # Add topicHref if found (before items:)
                if ($topicHref) {
                    $adjustedTopicHref = $relativePrefix + $topicHref
                    $expandedLines += "$nameIndent  topicHref: $adjustedTopicHref"
                }

                # Add items: marker (parent name line already exists)
                $expandedLines += "$nameIndent  items:"

                # Adjust indentation and paths in nested content
                # Nested items should be indented 4 spaces more than the parent name
                $indentAdjust = $nameIndent.Length + 4 - 2  # +4 for being children of parent, -2 because nested items start at indent 2

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

                # Mark the topicHref line (if found) to be skipped in the main loop
                if ($topicHref) {
                    # Find the topicHref line index
                    for ($k = $i + 1; $k -lt $lines.Count; $k++) {
                        if ($lines[$k] -match '^\s*topicHref:') {
                            $skipUntilLine = $k
                            break
                        }
                        # Stop if we hit another item
                        if ($lines[$k] -match '^\s*- name:') {
                            break
                        }
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
                # Find the parent - look for most recent item at lower indent (recursive search)
                function Find-Recent-Parent {
                    param($Items, $ChildIndent)

                    $bestParent = $null
                    $bestIndent = -1

                    for ($k = $Items.Count - 1; $k -ge 0; $k--) {
                        $candidateIndent = $Items[$k].indent

                        # Parent must have lower indent than child
                        if ($candidateIndent -lt $ChildIndent) {
                            # Found a potential parent - prefer the one with highest indent (closest ancestor)
                            if ($candidateIndent -gt $bestIndent) {
                                $bestParent = $Items[$k]
                                $bestIndent = $candidateIndent
                            }
                        }

                        # Also search recursively in this item's children
                        if ($Items[$k].items.Count -gt 0) {
                            $nestedParent = Find-Recent-Parent -Items $Items[$k].items -ChildIndent $ChildIndent
                            if ($nestedParent -and $nestedParent.indent -gt $bestIndent -and $nestedParent.indent -lt $ChildIndent) {
                                $bestParent = $nestedParent
                                $bestIndent = $nestedParent.indent
                            }
                        }
                    }

                    return $bestParent
                }

                $parent = Find-Recent-Parent -Items $result -ChildIndent $indent

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

    # Use ordered hashtable to ensure group comes before pages (Mintlify convention)
    $group = [ordered]@{
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
        # Check if child has sub-items
        $hasChildren = ($child.items -and $child.items.Count -gt 0)

        if ($hasChildren) {
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

# Check if expansion returned valid content
if ($null -eq $expandedLines -or $expandedLines.Count -eq 0) {
    Write-Error "No items found in YAML file"
    exit 1
}

# Create a temporary expanded toc file
$tempTocPath = [System.IO.Path]::GetTempFileName()
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($tempTocPath, $expandedLines, $utf8NoBom)

# Debug: Save expanded content for inspection
if ($env:DEBUG_SAVE_EXPANDED) {
    $debugPath = $OutputFile -replace '\.json$', '-expanded.yml'
    [System.IO.File]::WriteAllLines($debugPath, $expandedLines, $utf8NoBom)
    Write-Host "DEBUG: Saved expanded TOC to $debugPath" -ForegroundColor Magenta
}

# Debug: Show expanded content
if ($env:DEBUG_TOC_EXPANDED) {
    Write-Host "`nDEBUG: Expanded TOC content:" -ForegroundColor Magenta
    Get-Content $tempTocPath | Select-Object -First 50 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    Write-Host "  ... (showing first 50 lines)" -ForegroundColor DarkGray
}

# Parse the expanded YAML
$items = Read-YamlFile $tempTocPath

# Clean up temp file
Remove-Item $tempTocPath -Force

if ($items.Count -eq 0) {
    Write-Error "No items found in YAML file"
    exit 1
}

Write-Host "Found $($items.Count) top-level items" -ForegroundColor Cyan

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
    # Auto-generate TabName from first item if not provided
    if ([string]::IsNullOrWhiteSpace($TabName)) {
        if ($items.Count -gt 0 -and $items[0].name) {
            $TabName = $items[0].name
            Write-Host "Auto-detected TabName: $TabName" -ForegroundColor DarkGray
        }
        else {
            Write-Error "TabName is required when OutputType is 'Tab' and could not be auto-detected"
            exit 1
        }
    }

    # Use ordered hashtable to maintain property order (Mintlify convention)
    $output = [ordered]@{
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

    # Use ordered hashtable to ensure group comes before pages (Mintlify convention)
    $output = [ordered]@{
        group = $groupName
        pages = $allPages
    }
}

function Remove-DuplicatesFromStructure {
    param(
        $obj,
        [int]$depth = 0,
        [int]$maxDepth = 100,
        [System.Collections.Generic.HashSet[object]]$visited = $null
    )

    # Initialize visited set on first call
    if ($null -eq $visited) {
        $visited = [System.Collections.Generic.HashSet[object]]::new()
    }

    # Prevent infinite recursion - bail out if we go too deep
    if ($depth -ge $maxDepth) {
        Write-Warning "Maximum recursion depth ($maxDepth) reached in Remove-DuplicatesFromStructure"
        return $obj
    }

    if ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
        # Check if we've already visited this object (circular reference detection)
        if ($visited.Contains($obj)) {
            Write-Verbose "Circular reference detected at depth $depth"
            return @()  # Return empty array to break the cycle
        }
        $visited.Add($obj) | Out-Null

        # Handle arrays - remove duplicate strings, recursively process objects
        $seen = @{}
        $result = @()

        foreach ($item in $obj) {
            if ($item -is [string]) {
                # For strings, check if we've seen this exact value
                if (-not $seen.ContainsKey($item)) {
                    $seen[$item] = $true
                    $result += $item
                }
            }
            elseif ($item -is [hashtable] -or $item -is [System.Collections.Specialized.OrderedDictionary]) {
                # Recursively clean hashtables/ordered dictionaries
                $result += Remove-DuplicatesFromStructure -obj $item -depth ($depth + 1) -maxDepth $maxDepth -visited $visited
            }
            else {
                # Keep other types as-is
                $result += $item
            }
        }

        return $result
    }
    elseif ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) {
        # Check if we've already visited this object (circular reference detection)
        if ($visited.Contains($obj)) {
            Write-Verbose "Circular reference detected at depth $depth"
            return [ordered]@{}  # Return empty ordered dict to break the cycle
        }
        $visited.Add($obj) | Out-Null

        # Handle hashtables and ordered dictionaries
        $result = if ($obj -is [System.Collections.Specialized.OrderedDictionary]) {
            [ordered]@{}
        } else {
            @{}
        }

        foreach ($key in $obj.Keys) {
            $result[$key] = Remove-DuplicatesFromStructure -obj $obj[$key] -depth ($depth + 1) -maxDepth $maxDepth -visited $visited
        }

        return $result
    }
    else {
        # Return primitives as-is
        return $obj
    }
}

# Remove any duplicate entries from the output structure
$output = Remove-DuplicatesFromStructure $output

# Convert to JSON
$json = $output | ConvertTo-Json -Depth 20

# Write to file (always write to file now, OutputFile is auto-generated if not specified)
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

# Check and fix BOM in docs.json if this conversion modified it
if (Test-Path "$PSScriptRoot\..\docs.json") {
    & "$PSScriptRoot\check-bom.ps1" -Path "$PSScriptRoot\..\docs.json" -RemoveBOM | Out-Null
}

exit 0