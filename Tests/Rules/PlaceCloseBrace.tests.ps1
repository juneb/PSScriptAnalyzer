﻿$directory = Split-Path -Parent $MyInvocation.MyCommand.Path
$testRootDirectory = Split-Path -Parent $directory

Import-Module PSScriptAnalyzer
Import-Module (Join-Path $testRootDirectory "PSScriptAnalyzerTestHelper.psm1")

$ruleConfiguration = @{
    Enable = $true
    NoEmptyLineBefore = $true
    IgnoreOneLineBlock = $true
    NewLineAfter = $true
}

$settings = @{
    IncludeRules = @("PSPlaceCloseBrace")
    Rules = @{
        PSPlaceCloseBrace = $ruleConfiguration
    }
}

Describe "PlaceCloseBrace" {
    Context "When a close brace is not on a new line" {
        BeforeAll {
            $def = @'
function foo {
    Write-Output "close brace not on a new line"}
'@
            $ruleConfiguration.'NoEmptyLineBefore' = $false
            $ruleConfiguration.'IgnoreOneLineBlock' = $false
            $ruleConfiguration.'NewLineAfter' = $false
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should find a violation" {
            $violations.Count | Should Be 1
        }

        It "Should mark the right extent" {
            $violations[0].Extent.Text | Should Be "}"
        }
    }

    Context "When there is an extra new line before a close brace" {
        BeforeAll {
            $def = @'
function foo {
    Write-Output "close brace not on a new line"

}
'@
            $ruleConfiguration.'NoEmptyLineBefore' = $true
            $ruleConfiguration.'IgnoreOneLineBlock' = $false
            $ruleConfiguration.'NewLineAfter' = $false
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should find a violation" {
            $violations.Count | Should Be 1
        }

        It "Should mark the right extent" {
            $violations[0].Extent.Text | Should Be "}"
        }
    }

    Context "When there is a one line hashtable" {
        BeforeAll {
            $def = @'
$hashtable = @{a = 1; b = 2}
'@
            $ruleConfiguration.'NoEmptyLineBefore' = $false
            $ruleConfiguration.'IgnoreOneLineBlock' = $true
            $ruleConfiguration.'NewLineAfter' = $false
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should not find a violation" {
            $violations.Count | Should Be 0
        }
    }

    Context "When there is a multi-line hashtable" {
        BeforeAll {
            $def = @'
$hashtable = @{
    a = 1
    b = 2}
'@
            $ruleConfiguration.'NoEmptyLineBefore' = $false
            $ruleConfiguration.'IgnoreOneLineBlock' = $true
            $ruleConfiguration.'NewLineAfter' = $false
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should find a violation" {
            $violations.Count | Should Be 1
        }
    }

    Context "When a close brace is on the same line as its open brace" {
        BeforeAll {
            $def = @'
Get-Process * | % { "blah" }
'@
            $ruleConfiguration.'IgnoreOneLineBlock' = $false
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should not find a violation" {
            $violations.Count | Should Be 0
        }

        It "Should ignore violations for one line if statement" {
            $def = @'
$x = if ($true) { "blah" } else { "blah blah" }
'@
            $ruleConfiguration.'IgnoreOneLineBlock' = $true
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
            $violations.Count | Should Be 0
        }
    }

    Context "When a close brace should be follow a new line" {
        BeforeAll {
            $def = @'
if (Test-Path "blah") {
    "blah"
} else {
    "blah blah"
}
'@
            $ruleConfiguration.'NoEmptyLineBefore' = $false
            $ruleConfiguration.'IgnoreOneLineBlock' = $false
            $ruleConfiguration.'NewLineAfter' = $true
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $def -Settings $settings
        }

        It "Should find two violations" {
            $violations.Count | Should Be 2
            $params = @{
                RawContent = $def
                DiagnosticRecord = $violations[0]
                CorrectionsCount = 1
                ViolationText = '}'
                CorrectionText = '}' + [System.Environment]::NewLine
            }
            Test-CorrectionExtentFromContent @params

            $params = @{
                RawContent = $def
                DiagnosticRecord = $violations[1]
                CorrectionsCount = 1
                ViolationText = '}'
                CorrectionText = '}' + [System.Environment]::NewLine
            }
            Test-CorrectionExtentFromContent @params
        }
    }
}
