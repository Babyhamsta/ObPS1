$obfuscatedScript = Get-Content -Path "C://PATH//test.ps1" -Raw

function Obfuscate-Vars ([string]$script) {
  $variablePattern = '\$([a-zA-Z0-9_]+)'
  $variables = [regex]::Matches($script,$variablePattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

  $obfuscatedVariables = @{}
  $variables | ForEach-Object {
    if ($_ -eq '_') { return }

    $randomName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    $obfuscatedVariables["$_"] = $randomName
  }

  $obfuscatedVariables.GetEnumerator() | ForEach-Object {
    $script = $script -replace ('\$' + [regex]::Escape($_.Key)),('$' + $_.Value)
  }

  return $script

}

function Obfuscate-StringsToBytes ([string]$script) {
  $stringPattern = '"([^"]*)"'

  $obfuscatedScript = [regex]::Replace($script,$stringPattern,{
      param($match)
      $originalString = $match.Groups[1].Value
      $byteString = -join ($originalString.ToCharArray() | ForEach-Object {
          $byteVal = [byte][char]$_
          $hexVal = "{0:X2}" -f $byteVal
          "`$([char]([byte]0x$hexVal))"
        })

      "`"$byteString`""
    })

  return $obfuscatedScript
}


function Obfuscate-Functions ([string]$script) {
  $functionPattern = '(?i)function ([a-zA-Z0-9_]+)'
  $foundFunctions = [regex]::Matches($script,$functionPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

  $foundFunctions | ForEach-Object {
    $randomFunctionName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    $script = $script -replace "function $_","function $randomFunctionName"
    $script = $script -replace "\b$_\b",$randomFunctionName
  }

  return $script
}

function Generate-ObfuscatedCommandName ([string]$commandName) {
    $chars = $commandName.ToCharArray()
    $obfuscatedChars = @()
    
    for ($i = 0; $i -lt $chars.Length; $i++) {
        # Generate a new random number for each character
        $random = Get-Random -Minimum 1 -Maximum 5
        
        if (($i + 1) % $random -eq 0) {
            $obfuscatedChars += '?'
        } else {
            $obfuscatedChars += $chars[$i]
        }
    }
    
    return -join $obfuscatedChars
}


function Obfuscate-Commands ([string]$script) {
  $functionPattern = '(?i)function ([a-zA-Z0-9_]+)'
  $foundFunctions = [regex]::Matches($script, $functionPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($script, [ref]$null, [ref]$null)
  $commandNodes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
  
  $actualCommands = $commandNodes | Where-Object {
    $firstElement = $_.CommandElements[0]
    $firstElement.Value -notin $foundFunctions
  }

  foreach ($command in $actualCommands) {
    $originalCommand = $command.Extent.Text
    $originalCommandName = $command.GetCommandName()

    $arguments = $originalCommand.Substring($command.CommandElements[0].Extent.Text.Length)
    $obfuscatedCommandName = Generate-ObfuscatedCommandName $originalCommandName
    
    $newCommandWithArgs = "&(Get-Command $obfuscatedCommandName*) $arguments"
    $script = $script -replace [regex]::Escape($command.Extent.Text), $newCommandWithArgs
  }
  
  return $script
}

function Generate-RandomJunk {
    $junkSnippets = @("`$a1B2c = 1", "`$D3e_4 = 'txt'", "`$varF5G6 = `$null", "`$H7_I8J = 0", "`$K9_L0 = 2 + 2", "`$C2_D3 = 'x' * 2", "`$E4f5 = 3 - 1", "`$G6_H7 = 3 / 1", "`$I8j9 = 4 % 3", "`$M2n3 = 'rnd'", "`$O4_P5 = 2 -eq 2", "`$Q6r7 = 'a' -ne 'b'", "`$S8_T9 = 1 -lt 2", "`$Y4z5 = 1..2", "`$C8d9 = `$false -or `$true", "`$E0_F1 = -not `$false", "`$G2h3 = [math]::Pi", "`$I4_J5 = [math]::E", "`$K6l7 = [math]::Sqrt(1)", "`$O0p1 = [math]::Cos(1)", "`$Q2_R3 = [math]::Tan(1)", "`$S4t5 = [math]::Asin(1)", "`$U6_V7 = [math]::Pow(1,2)", "`$W8x9 = [math]::Log(2)", "`$Y0_Z1 = [math]::Abs(-1)", "`$A2b3 = [math]::Sign(1)", "`$C4_D5 = [math]::Round(1)", "`$newString = 'randomString'", "`$anotherString = 'moreRandom'")
    return $junkSnippets | Get-Random
}

function Add-JunkFunctions {
  param(
    [string]$script,
    [int]$functionCount
  )

  [System.Collections.ArrayList]$scriptLines = ($script -split "\r?\n")
  $insertedIndices = @()

  for ($i = 0; $i -lt $functionCount; $i++) {
    $randIndex = Get-Random -Minimum 0 -Maximum $scriptLines.Count
    $functionName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

    $junkCodeArray = 1..(Get-Random -Minimum 3 -Maximum 10) | ForEach-Object {
        Generate-RandomJunk
    }

    $junkCode = $junkCodeArray -join "`r`n"

    $randSnippet = @"
function $functionName {
    $junkCode
}
$functionName
"@

    while (
      ($insertedIndices -contains $randIndex) -or
      (($randIndex -gt 0) -and ($scriptLines[$randIndex - 1] -match "(?i)(function|if|else|for|while)")) -or
      (($randIndex -lt ($scriptLines.Count - 1)) -and ($scriptLines[$randIndex + 1] -match "^\s*\{"))
    ) {
      $randIndex = Get-Random -Minimum 0 -Maximum $scriptLines.Count
    }

    $insertedIndices += $randIndex

    if ($randIndex -eq 0) {
      $scriptLines.Insert(0, $randSnippet)
    } else {
      $scriptLines.Insert($randIndex, $randSnippet)
    }
  }

  return ($scriptLines -join "`r`n")
}

function Add-JunkCode {
  param(
    [string]$script,
    [int]$junkLevel
  )

  [System.Collections.ArrayList]$scriptLines = ($script -split "\r?\n")
  $insertedIndices = @()

  for ($i = 0; $i -lt $junkLevel; $i++) {
    $randIndex = Get-Random -Minimum 0 -Maximum $scriptLines.Count
    $randSnippet = Generate-RandomJunk

    # Check for sensitive code structures
    while (
      ($insertedIndices -contains $randIndex) -or
      (($randIndex -gt 0) -and ($scriptLines[$randIndex - 1] -match "(?i)(function|if|else|for|while)")) -or
      (($randIndex -lt ($scriptLines.Count - 1)) -and ($scriptLines[$randIndex + 1] -match "^\s*\{"))
    ) {
      $randIndex = Get-Random -Minimum 0 -Maximum $scriptLines.Count
    }

    $insertedIndices += $randIndex

    if ($randIndex -eq 0) {
      $scriptLines.Insert(0, $randSnippet)
    } else {
      $scriptLines.Insert($randIndex, $randSnippet)
    }
  }

  return ($scriptLines -join "`r`n")
}


<#
Minify PS1
Create by Ingo Karstein // http://ikarstein.wordpress.com
Modifyed to suit my needs
#>

function Minify-Script {
  param(
    [string]$inputData = $null
  )


  try {
    $limiters = @(
      @{ Open = '@"'; close = '"@'; type = "DQMLString"; canBeEscaped = $false; ignoreInOutput = $false },
      @{ Open = "@'"; close = "'@"; type = "SQMLString"; canBeEscaped = $false; ignoreInOutput = $false },
      @{ Open = "<#"; close = "#>"; type = "MLComment"; canBeEscaped = $false; ignoreInOutput = $true },
      @{ Open = "#"; close = "`n"; type = "EOLComment"; canBeEscaped = $false; ignoreInOutput = $true; moveEnd = -1 },
      @{ Open = '"'; close = '"'; type = "DQString"; escapeChar = "``"; canBeEscaped = $true; ignoreInOutput = $false },
      @{ Open = "'"; close = "'"; type = "SQString"; escapeChar = "``"; canBeEscaped = $true; ignoreInOutput = $false },
      @{ type = "Code"; regex = @(
          @{ search = [regex]'\n'; Replace = ";"; priority = 1000 },
          @{ search = [regex]'([^\w\d])\x20{1}'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'\x20+([^\w\d\-\$\@])'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'\x20*(\n)'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'(\x20)\x20+'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'(\,)\;'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'\x20*([\;\,\(\)\{\}\[\]])\x20*'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'([\{]);*'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]';*([\}])'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'([;])[;]*'; Replace = '$1'; priority = 1000 },
          @{ search = [regex]'\x20*$'; Replace = ''; priority = 1000 },
          @{ search = [regex]'\r'; Replace = "`n"; priority = 1000 },
          @{ search = [regex]'\t'; Replace = " "; priority = 1000 },
          @{ search = [regex]'([\w\d])$'; Replace = '$1 '; priority = 1000 },
          @{ search = [regex]'\n{2,}'; Replace = "`n"; priority = 1000 },
          @{ search = [regex]'([\}\{])[;\s\t\n]*([\{\}])'; Replace = '$1$2'; priority = 1000 }
        ) }
    )

    if ($inputData -is [array]) { $inputData = [string]::Join("`n",$inputData) }

    $l = 0
    do { $l = $inputData.Length; $inputData = $inputData -replace "`r`n","`n" -replace "`r","x" } while ($inputData.Length -ne $l)

    $inputData += "`n"

    $limOpen = ($limiters | Where-Object { ![string]::IsNullOrEmpty($_.Open) } | ForEach-Object { ($_.Open)[0] } | Select-Object -Unique)

    $p = 0; $p1 = 0; $lp = 0; $nStr = "";
    $result1 = @()

    while ($true) {
      $n = $inputData.IndexOfAny($limOpen,$p1)

      if ($n -ge 0) {
        $limiter = $null; $closer = $null

        $limiters | Where-Object { $limiter -eq $null -and $_.Open -ne $null } | ForEach-Object {
          $lim = $_
          $n2 = 0
          if ((([string]$lim.Open).ToCharArray() | ForEach-Object { if ($inputData[$n + $n2] -ne $_) { $false }; $n2++ }) -eq $null) {
            $limiter = $lim
          }
        }

        if ($limiter -ne $null -and $limiter.needCharsBefore -ne $null) {
          $n4 = $n - 1
          while ($n4 -ge 0) {
            $c = $inputData[$n4]
            if ($c -notmatch $limiter.ignoreCharactersBefore) {
              if ($c -notmatch $limiter.needCharsBefore) {
                $limiter = $null
                break
              } else {
                break
              }
            }
            $n4 --
          }
        }

        if ($limiter -ne $null) {
          if ($p -lt $n) {
            $s = $inputData.Substring($p,$n - $p)

            $r = New-Object PSObject
            $r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty
            $r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty
            $r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty
            $r | Add-Member -Name "Length" -Value ($n - $p) -Force -MemberType NoteProperty
            $r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty
            if ($verbose) { $r | Out-String | Write-Host -ForegroundColor DarkBlue }
            $result1 += $r
          }

          $n1 = $n + $limiter.Open.Length
          do {
            $closer = $null

            #we look for the closing limiter
            if ($limiter.close -is [array]) {
              $n3 = $inputData.Length
              $limiter.close | ForEach-Object {
                $tmpN3 = $inputData.IndexOf($_.close,$n1)
                if ($tmpN3 -lt $n3) {
                  $n3 = $tmpN3
                  $closer = $_
                }
              }
              $n1 = $n3
            } else {
              $n1 = $inputData.IndexOf($limiter.close,$n1)
              $closer = $limiter
            }

            if ($n1 -lt 0) {
              break
            } else {
              if ($closer.canBeEscaped) {
                if ($n1 -lt ($closer.close.Length + ($closer.escapeChar.Length * 2))) {
                  break
                } else {
                  if ($inputData.Substring($n1 - ($closer.escapeChar.Length),$closer.escapeChar.Length) -ne $closer.escapeChar) {
                    break
                  } else {
                    if ($inputData.Substring($n1 - ($closer.escapeChar.Length * 2),$closer.escapeChar.Length * 2) -eq "$($closer.escapeChar)$($closer.escapeChar)") {
                      break
                    }
                  }
                }
              } else {
                break
              }
            }
            $n1 += $closer.close.Length
          } while ($true)

          if ($n1 -lt 0) {
            throw "input data not valid at position $($n)"
            return
          }

          if ($closer.followdByCharacters -ne $null) {
            while ($inputData[$n1 + $closer.close.Length] -match $closer.followdByCharacters) { $n1++ }
          }

          $s = $inputData.Substring($n,$n1 - $n + $closer.close.Length)

          $r = New-Object PSObject
          $r | Add-Member -Name "Type" -Value $closer.type -Force -MemberType NoteProperty
          $r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty
          $r | Add-Member -Name "Pos" -Value $n -Force -MemberType NoteProperty
          $r | Add-Member -Name "Length" -Value ($n1 - $n + $closer.close.Length) -Force -MemberType NoteProperty
          $r | Add-Member -Name "IgnoreInOutput" -Value $closer.ignoreInOutput -Force -MemberType NoteProperty
          if ($verbose) { $r | Out-String | Write-Host -ForegroundColor DarkBlue }
          $result1 += $r

          $p = $p1 = $n1 + $closer.close.Length
          if ($closer.moveEnd -ne $null) { $p += $closer.moveEnd }
        } else {
          $p1 = $n + 1;
        }
      } else {
        $s = $inputData.Substring($p)
        $r = New-Object PSObject
        $r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty
        $r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty
        $r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty
        $r | Add-Member -Name "Length" -Value ($inputData.Length - $p) -Force -MemberType NoteProperty
        $r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty
        if ($verbose) { $r | Out-String | Write-Host -ForegroundColor DarkBlue }
        $result1 += $r
        break
      }
    }

    $result2 = $result1 | Where-Object { !$_.ignoreInOutput }

    $prev = $null
    $result3 = $result2 | ForEach-Object {
      if ($_.type -ieq "code") {
        if ($prev -ne $null) {
          $prev.Text += $_.Text
          $prev.Length = -1
        } else {
          $prev = $_
        }
      } else {
        if ($prev -ne $null) { $prev; $prev = $null }
        $_
      }
    }

    if ($prev -ne $null) { $result3 += $prev }

    $result4 = $result3 | ForEach-Object {
      $entity = $_

      $lim = $null
      $lim = ($limiters | Where-Object { $_.type -eq $entity.type })

      $s = $entity.Text
      $l = 0
      do {
        $l = $s.Length
        if (![string]::IsNullOrEmpty($lim.Replace)) {
          $s = $lim.Replace
        } else {
          $lim.regex | Where-Object { $_ -ne $null } | Select-Object @{ Name = "Obj"; Expression = { $_ } },@{ Name = "Priority"; Expression = { $_.priority } } | sort priority | ForEach-Object {
            $processor = $_.Obj
            if ($processor.search.IsMatch($s)) {
              $s = $processor.search.Replace($s,$processor.Replace)
            }
          }
        }
      } while ($l -ne $s.Length)

      $entity | Add-Member -Name "TextAfterProcessing" -Value $s -Force -MemberType NoteProperty

      $entity
    }

    if (!([string]::IsNullOrEmpty($xmlOutputFile))) {
      $result4 | Export-Clixml $xmlOutputFile -Force -ErrorAction:$ErrorActionPreference
    }

    $sb = New-Object system.text.StringBuilder
    $result4 | ForEach-Object {
      if (![string]::IsNullOrEmpty($_.TextAfterProcessing)) {
        $sb.append($_.TextAfterProcessing)
      }
    } | Out-Null

    return $sb.ToString().Trim()
  } catch {
    throw
  }
}

# Obfuscate
$obfuscatedScript = Obfuscate-Functions -Script $obfuscatedScript
$obfuscatedScript = Obfuscate-Commands -Script $obfuscatedScript

# Junk it
#$obfuscatedScript = Add-JunkFunctions -Script $obfuscatedScript -functionCount 10
#$obfuscatedScript = Add-JunkCode -Script $obfuscatedScript -junkLevel 100

# We do this last for better results
$obfuscatedScript = Obfuscate-StringsToBytes -Script $obfuscatedScript
$obfuscatedScript = Obfuscate-Vars -Script $obfuscatedScript

# Minify the output
#$obfuscatedScript = Minify-Script -inputData $obfuscatedScript

# Step 3: Write to New File
Set-Content -Path "C://PATH//TestScript_obfuscated.ps1" -Value $obfuscatedScript
