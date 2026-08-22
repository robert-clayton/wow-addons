function Sync-CollectionistAchievementCriteria {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)][string]$CurrentDb2Root,
        [switch]$AllAchievements
    )

    $achievementPath = Join-Path $CurrentDb2Root "Achievement.csv"
    $criteriaPath = Join-Path $CurrentDb2Root "Criteria.csv"
    $treePath = Join-Path $CurrentDb2Root "CriteriaTree.csv"
    foreach ($path in @($achievementPath, $criteriaPath, $treePath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Missing current-retail criteria input: $path"
        }
    }

    $achievementByID = @{}
    foreach ($row in @(Import-Csv -LiteralPath $achievementPath)) {
        $achievementByID[[string]$row.ID] = $row
    }

    $criteriaByID = @{}
    foreach ($row in @(Import-Csv -LiteralPath $criteriaPath)) {
        $criteriaByID[[string]$row.ID] = $row
    }

    $treeByID = @{}
    $childrenByParent = @{}
    foreach ($row in @(Import-Csv -LiteralPath $treePath)) {
        $treeByID[[string]$row.ID] = $row
        $parentID = [string]$row.Parent
        if (-not $childrenByParent.ContainsKey($parentID)) {
            $childrenByParent[$parentID] = [System.Collections.Generic.List[object]]::new()
        }
        [void]$childrenByParent[$parentID].Add($row)
    }

    $eligibleAchievementIDs = @{}
    foreach ($group in @($Rows | Group-Object achievement_id)) {
        if ($AllAchievements -or ($group.Count -ge 2 -and $group.Count -le 30)) {
            $eligibleAchievementIDs[[string]$group.Name] = $true
        }
    }

    $currentLeafByAchievementAndTree = @{}
    $currentCriterionByAchievement = @{}
    foreach ($achievementID in @($eligibleAchievementIDs.Keys)) {
        $achievement = $achievementByID[$achievementID]
        if (-not $achievement) { continue }
        $rootIDs = @(
            [string]$achievement.Criteria_tree
            [string]$achievement.Shares_criteria
        ) | Where-Object { $_ -and $_ -ne "0" -and $treeByID.ContainsKey($_) } | Sort-Object -Unique
        if ($rootIDs.Count -eq 0) { continue }

        $queue = [System.Collections.Generic.Queue[object]]::new()
        foreach ($rootID in $rootIDs) { $queue.Enqueue(@($rootID, "")) }
        while ($queue.Count -gt 0) {
            $pair = $queue.Dequeue()
            $parentID = [string]$pair[0]
            $parentPath = [string]$pair[1]
            foreach ($node in @($childrenByParent[$parentID] | Sort-Object { [int]$_.OrderIndex }, { [int]$_.ID })) {
                $orderPath = if ($parentPath) { "$parentPath/$($node.OrderIndex)" } else { [string]$node.OrderIndex }
                $children = @($childrenByParent[[string]$node.ID])
                if ([string]$node.CriteriaID -ne "0") {
                    $criterion = $criteriaByID[[string]$node.CriteriaID]
                    $currentLeafByAchievementAndTree["${achievementID}:$($node.ID)"] = [pscustomobject]@{
                        order_path    = $orderPath
                        tree_id       = [string]$node.ID
                        description   = [string]$node.Description_lang
                        criteria_id   = [string]$node.CriteriaID
                        criteria_type = if ($criterion) { [string]$criterion.Type } else { $null }
                        asset_id      = if ($criterion) { [string]$criterion.Asset } else { $null }
                        amount        = [string]$node.Amount
                        operator      = [string]$node.Operator
                    }
                    $currentCriterionByAchievement["${achievementID}:$($node.CriteriaID)"] = $true
                } elseif ($children.Count -gt 0) {
                    $queue.Enqueue(@([string]$node.ID, $orderPath))
                }
            }
        }
    }

    foreach ($row in @($Rows)) {
        if (-not $eligibleAchievementIDs.ContainsKey([string]$row.achievement_id)) {
            $row
            continue
        }
        $current = $currentLeafByAchievementAndTree["$($row.achievement_id):$($row.tree_id)"]
        if (-not $current) {
            if ($currentCriterionByAchievement.ContainsKey("$($row.achievement_id):$($row.criteria_id)")) {
                $row
            }
            continue
        }
        $row.order_path = $current.order_path
        if ($current.description) { $row.description = $current.description }
        $row.criteria_id = $current.criteria_id
        $row.criteria_type = $current.criteria_type
        $row.asset_id = $current.asset_id
        $row.amount = $current.amount
        $row.operator = $current.operator
        $row
    }
}

function Sync-CollectionistEncounterRows {
    param(
        [Parameter(Mandatory = $true)]$Rows,
        [Parameter(Mandatory = $true)]$CurrentCriteriaRows
    )

    $currentByAchievementAndTree = @{}
    foreach ($row in @($CurrentCriteriaRows)) {
        $currentByAchievementAndTree["$($row.achievement_id):$($row.tree_id)"] = $row
    }

    foreach ($row in @($Rows)) {
        $current = $currentByAchievementAndTree["$($row.achievement_id):$($row.tree_id)"]
        if (-not $current) { continue }
        $row.order_path = $current.order_path
        $row.criteria_id = $current.criteria_id
        $row.criteria_type = $current.criteria_type
        if ($row.PSObject.Properties["criteria_asset"]) { $row.criteria_asset = $current.asset_id }
        if ($row.PSObject.Properties["amount"]) { $row.amount = $current.amount }
        if ($current.description) {
            if ($row.PSObject.Properties["criterion"]) { $row.criterion = $current.description }
            if ($row.PSObject.Properties["treasure"]) { $row.treasure = $current.description }
        }
        if ($row.PSObject.Properties["npc_ids"] -and [string]$current.criteria_type -eq "0") {
            $row.npc_ids = $current.asset_id
            if ($row.PSObject.Properties["object_ids"]) { $row.object_ids = $null }
            if ($row.PSObject.Properties["entity_mapping"]) { $row.entity_mapping = "criteria_creature_asset" }
        }
        $row
    }
}
