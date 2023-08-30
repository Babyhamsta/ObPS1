# Created by Babyhamsta Github
# https://github.com/Babyhamsta/ObPS1
# v0.0.1

$obfuscatedScript = Get-Content -Path "C:/Users/User/Desktop/OrignialScript.ps1" -Raw

Function Obfuscate-Vars ([string]$script) {
    $variablePattern = '\$([a-zA-Z0-9_]+)'
    $variables = [regex]::Matches($script, $variablePattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    $obfuscatedVariables = @{}
    $variables | ForEach-Object {
        if ($_ -eq '_') { return }

        $randomName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
        $obfuscatedVariables["$_"] = $randomName
    }

    $obfuscatedVariables.GetEnumerator() | ForEach-Object {
        $script = $script -replace ('\$' + [regex]::Escape($_.Key)), ('$' + $_.Value)
    }

    return $script

}

Function Obfuscate-StringsToBytes ([string]$script) {
    $stringPattern = '"([^"]*)"'

    $obfuscatedScript = [regex]::Replace($script, $stringPattern, {
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


Function Obfuscate-Functions ([string]$script) {
    $functionPattern = 'function ([a-zA-Z0-9_]+)'
    $foundFunctions = [regex]::Matches($script, $functionPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    $foundFunctions | ForEach-Object {
        $randomFunctionName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
        $script = $script -replace "function $_", "function $randomFunctionName"
        $script = $script -replace "\b$_\b", $randomFunctionName
    }

    return $script
}

Function Obfuscate-Commands ([string]$script) {
    # Detect PowerShell commands; this pattern assumes space or end of line after the command name
    $commandPattern = '\b([a-zA-Z0-9\-]+)\s|\b([a-zA-Z0-9\-]+)$'
    $foundCommands = [regex]::Matches($script, $commandPattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    $foundCommands | ForEach-Object {
        $randomCommandName = -join ((65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
        $obfuscatedScript = $script -replace $_, $randomCommandName
        $cmdDefinition = "`$$randomCommandName = '$_'"
        $script = "$cmdDefinition`r`n$script"
    }

    return $script
}

Function Add-RandomJunk {
    param(
        [string]$script,
        [int]$junkLevel
    )

    $junkSnippets = @("`$a1B2c = 1", "`$D3e_4 = 'txt'", "$varF5G6 = $null", "`$H7_I8J = 0", "`$K9_L0 = 2 + 2", "if(`$A1b){}", "`$C2_D3 = 'x' * 2", "`$E4f5 = 3 - 1", "`$G6_H7 = 3 / 1", "`$I8j9 = 4 % 3", "if(`$K0_L1){}", "`$M2n3 = 'rnd'", "`$O4_P5 = 2 -eq 2", "`$Q6r7 = 'a' -ne 'b'", "`$S8_T9 = 1 -lt 2", "if(`$U0v1){}", "`$Y4z5 = 1..2", "$A6_B7 = $true -and `$false", "$C8d9 = $false -or `$true", "$E0_F1 = -not $false", "`$G2h3 = [math]::Pi", "`$I4_J5 = [math]::E", "`$K6l7 = [math]::Sqrt(1)", "if(`$M8_N9){}", "`$O0p1 = [math]::Cos(1)", "`$Q2_R3 = [math]::Tan(1)", "`$S4t5 = [math]::Asin(1)", "`$U6_V7 = [math]::Pow(1,2)", "`$W8x9 = [math]::Log(2)", "`$Y0_Z1 = [math]::Abs(-1)", "`$A2b3 = [math]::Sign(1)", "`$C4_D5 = [math]::Round(1)", "`$G8_H9 = [System.Guid]::NewGuid()", "`$I0j1 = Get-Random", "`$K2_L3 = Get-Date", "`$M4n5 = Get-Process", "`$O6_P7 = Get-Host", "`$Q8r9 = Get-Command", "`$S0_T1 = Get-Alias", "`$U2v3 = Get-PSDrive", "`$W4_X5 = Get-PSProvider", "`$Y6z7 = Get-Module", "`$A8_B9 = Get-Service", "`$C0d1 = Get-WmiObject", "`$E2_F3 = Get-CimInstance", "`$G4h5 = Get-Item", "`$I6_J7 = Get-ChildItem", "`$K8l9 = Get-Content", "`$M0_N1 = Set-Content", "`$O2p3 = Add-Content", "`$Q4_R5 = Clear-Content", "`$S6t7 = Get-Location", "`$U8_V9 = Set-Location", "`$W0x1 = Remove-Item", "`$Y2_Z3 = Move-Item", "`$A4b5 = Copy-Item", "`$C6_D7 = New-Item", "$E8f9 = Write-Host '$randomTxt'", "$G0_H1 = Write-Output '$randOut'", "`$aB1C2_D3 = 1 + 1 - (3 % 2)", "iex -Verbose -Debug 'whoami' -ErrorVariable `$rndmE1 -WarningAction SilentlyContinue", "`$eF2_G3H = [math]::Sqrt(16) * [math]::Pi", "Get-Date -UFormat '%Y-%m-%d' | Out-Null", "Get-Process | Select-Object -First 1 | Out-String", "Get-Host | Get-Member -MemberType Property", "`$pQ8_R9 = Get-Random -Minimum 5 -Maximum 100", "`$sT0_U1 = 'string1','string2' -join ','", "$vW2_X3Y = if ($true) { 'true' } else { 'false' }", "Get-Culture | Select-Object -Property DisplayName", "`$zA4_B5 = Get-Service | Sort-Object Status", "`$cD6_E7 = Get-EventLog -LogName 'System' -Newest 1", "Write-Host ('Random:' + `$pQ8_R9)", "`$fG8_H9 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aGVsbG8='))", "$iJ0_K1 = 1..5 | ForEach-Object { $_ * 2 }", "$lM2_N3 = Get-Process | Where-Object { $_ -match 'idle' }", "`$oP4_Q5 = 'This is a string'.Replace('string', 'sentence')", "`$rS6_T7 = [enum]::GetNames([System.DayOfWeek])", "`$uV8_W9 = Get-PSProvider | Format-Table -Property Name", "`$xY0_Z1 = 'lowercase'.ToUpper()", "`$aB2_C3 = Get-Date | Get-Member -MemberType Method", "$dE4_F5 = Get-Disk | Where-Object { $_ -like '*0' }", "`$gH6_I7 = 'sample string' -split ' '", "`$jK8_L9 = 12.3456.ToString('N2')", "`$mN0_O1 = Get-Variable | Out-Host", "`$pQ2_R3 = [System.Net.Dns]::GetHostAddresses('localhost')", "`$sT4_U5 = New-TimeSpan -Minutes 10", "`$vW6_X7 = [System.Math]::Round(12.3456, 2)", "`$yZ8_09 = Test-Path 'C:\Windows\notepad.exe'", "`$b12_C3 = (Get-Service | Select-Object -First 1).ServiceName", "$e45_F6 = $true -xor `$false", "`$h78_I9 = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()", "`$k01_J2 = Get-Command | Group-Object -Property CommandType", "`$n34_O5 = 'string'.Length", "`$q67_P8 = Get-PSDrive | Sort-Object -Property Used", "`$t90_U1 = Get-EventLog -LogName 'System' -InstanceId 6006 -Newest 1", "`$w23_V4 = [System.Text.Encoding]::UTF8.GetBytes('hello')", "`$z56_W7 = [math]::Log10(100)", "`$c89_X0 = Test-Connection -ComputerName localhost -Count 1", "`$f12_Y3 = Get-ChildItem 'C:\' -File", "`$i45_Z6 = [System.Text.RegularExpressions.Regex]::IsMatch('test', '^[a-z]+$')", "$l78_A9 = Get-Variable | Where-Object { $_ -like 'env' }", "`$o01_B2 = Get-Process | Sort-Object -Property CPU -Descending", "`$r34_C5 = 'test string' -match '^[a-zA-Z ]+$'", "`$u67_D8 = [System.Uri]::EscapeDataString('test string')", "`$x90_E1 = 'test' + ' ' + 'string'", "`$a23_F4 = Get-Command | Sort-Object -Property Source", "`$d56_G7 = [System.IO.Path]::GetRandomFileName()")

    [System.Collections.ArrayList]$scriptLines = ($script -split "\r?\n")
    $insertedIndices = @()

    for($i = 0; $i -lt $junkLevel; $i++) {
        $randIndex = Get-Random -Minimum 0 -Maximum $scriptLines.Count

        $randSnippet = $junkSnippets | Get-Random

        while ($insertedIndices -contains $randIndex) {
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
					@{open='@"'; close='"@'; type="DQMLString"; canBeEscaped=$false; ignoreInOutput=$false},
					@{open="@'"; close="'@"; type="SQMLString"; canBeEscaped=$false; ignoreInOutput=$false},
					@{open="<#"; close="#>"; type="MLComment"; canBeEscaped=$false; ignoreInOutput=$true},
					@{open="#"; close="`n"; type="EOLComment"; canBeEscaped=$false; ignoreInOutput=$true; moveEnd=-1},
					@{open='"'; close='"'; type="DQString"; escapeChar="``"; canBeEscaped=$true; ignoreInOutput=$false},
					@{open="'"; close="'"; type="SQString"; escapeChar="``"; canBeEscaped=$true; ignoreInOutput=$false},
					@{type="Code"; regex = @( 
							@{search=[regex]'\n'; replace=";"; priority=1000},
							@{search=[regex]'([^\w\d])\x20{1}'; replace='$1'; priority=1000},
							@{search=[regex]'\x20+([^\w\d\-\$\@])'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*(\n)'; replace='$1'; priority=1000},
							@{search=[regex]'(\x20)\x20+'; replace='$1'; priority=1000},
							@{search=[regex]'(\,)\;'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*([\;\,\(\)\{\}\[\]])\x20*'; replace='$1'; priority=1000},
							@{search=[regex]'([\{]);*'; replace='$1'; priority=1000},
							@{search=[regex]';*([\}])'; replace='$1'; priority=1000},
							@{search=[regex]'([;])[;]*'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*$'; replace=''; priority=1000},
							@{search=[regex]'\r'; replace="`n"; priority=1000},
							@{search=[regex]'\t'; replace=" "; priority=1000},
							@{search=[regex]'([\w\d])$'; replace='$1 '; priority=1000},
							@{search=[regex]'\n{2,}'; replace="`n"; priority=1000},
							@{search=[regex]'([\}\{])[;\s\t\n]*([\{\}])'; replace='$1$2'; priority=1000}
						)}
				)

		if( $inputData -is [Array] ) { $inputData = [string]::Join("`n", $inputData) }
		
		$l = 0
		do { $l = $inputData.Length; $inputData = $inputData -replace "`r`n","`n" -replace "`r", "x" } while( $inputData.Length -ne $l)

		$inputData += "`n"

		$limOpen = ($limiters | ? {![string]::IsNullOrEmpty($_.open)} | % { ($_.open)[0]} | select -Unique)

		$p = 0; $p1 = 0; $lp = 0; $nStr = "";
		$result1 = @()

		while( $true ) {
			$n = $inputData.IndexOfAny($limOpen, $p1)
			
			if( $n -ge 0 ) {
				$limiter = $null; $closer = $null 

				$limiters | ? { $limiter -eq $null -and $_.open -ne $null } | % {
					$lim = $_	
					$n2 = 0
					if( ( ([string]$lim.Open).ToCharArray() | % {  if( $inputData[$n+$n2] -ne $_) {$false}; $n2++ }) -eq $null ) {
						$limiter = $lim
					}
				}
				
				if($limiter -ne $null -and $limiter.needCharsBefore -ne $null ) {
					$n4 = $n - 1
					while($n4 -ge 0){
						$c = $inputData[$n4]
						if( $c -notmatch $limiter.ignoreCharactersBefore) {
							if( $c -notmatch $limiter.needCharsBefore ) {
								$limiter = $null
								break
							} else  {
								break
							}
						}
						$n4--
					}
				}
				
				if( $limiter -ne $null ) {
					if( $p -lt $n ) {
						$s = $inputData.Substring($p, $n-$p)
						
						$r = New-Object PSObject
						$r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Length" -Value ($n-$p) -Force -MemberType NoteProperty 
						$r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty 
						if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
						$result1 += $r
					}

					$n1 = $n + $limiter.open.length
					do {
						$closer = $null

						#we look for the closing limiter
						if( $limiter.close -is [array] ) {
							$n3 = $inputData.Length
							$limiter.close | % { 
								$tmpN3 = $inputData.IndexOf($_.close, $n1)
								if($tmpN3 -lt $n3 ){
									$n3 = $tmpN3
									$closer = $_
								}
							}
							$n1 = $n3
						} else {
							$n1 = $inputData.IndexOf($limiter.close, $n1)
							$closer = $limiter
						}
						
						if( $n1 -lt 0 ) {
							break
						} else {
							if($closer.canBeEscaped) {
								if( $n1 -lt ($closer.close.Length+($closer.escapeChar.Length*2)) ) {
									break
								} else {
									if( $inputData.Substring($n1-($closer.escapeChar.Length), $closer.escapeChar.Length) -ne $closer.escapeChar ) {
										break
									} else {
										if( $inputData.Substring($n1-($closer.escapeChar.Length*2), $closer.escapeChar.Length*2) -eq "$($closer.escapeChar)$($closer.escapeChar)" ) {
											break
										}
									}
								}
							} else {
								break
							}
						}
						$n1 += $closer.close.length
					} while( $true ) 
					
					if( $n1 -lt 0 ) {
						throw "input data not valid at position $($n)"
						return
					}
					
					if($closer.followdByCharacters -ne $null ) {
						while( $inputData[$n1 + $closer.close.Length] -match $closer.followdByCharacters ) { $n1++ }
					}
					
					$s = $inputData.Substring( $n, $n1 - $n + $closer.close.Length)
					
					$r = New-Object PSObject
					$r | Add-Member -Name "Type" -Value $closer.type -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Pos" -Value $n -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Length" -Value ($n1 - $n + $closer.close.Length) -Force -MemberType NoteProperty 
					$r | Add-Member -Name "IgnoreInOutput" -Value $closer.IgnoreInOutput -Force -MemberType NoteProperty 
					if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
					$result1 += $r

					$p = $p1 = $n1 + $closer.close.length
					if($closer.moveEnd -ne $null ) {$p += $closer.moveEnd}
				} else {
					$p1 = $n + 1;
				}
			} else {
				$s = $inputData.Substring( $p)		
				$r = New-Object PSObject
				$r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Length" -Value ($inputData.Length-$p) -Force -MemberType NoteProperty 
				$r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty 
				if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
				$result1 += $r
				break
			}
		}
		
		$result2 = $result1 | ? { !$_.IgnoreInOutput} 
		
		$prev = $null
		$result3 = $result2 | % {
			if($_.Type -ieq "code" ) {
				if( $prev -ne $null ) {
			   		$prev.Text += $_.Text
					$prev.Length = -1
				} else {
					$prev = $_
				}
			} else {
				if($prev -ne $null ) { $prev; $prev = $null}
				$_
			}
		} 
		
		if($prev -ne $null ) { $result3 += $prev}

		$result4 = $result3 | % {
			$entity = $_

			$lim=$null
			$lim = ($limiters | ? { $_.Type -eq $entity.Type })	
			
			$s = $entity.Text
			$l = 0 
			do {
				$l = $s.Length
				if(![string]::IsNullOrEmpty($lim.replace)) {
					$s = $lim.Replace
				} else {
					$lim.regex | ? { $_ -ne $null } | select @{Name="Obj"; Expression={$_}}, @{Name="Priority"; Expression={$_.priority}} | sort priority | % {
						$processor = $_.Obj
						if( $processor.Search.IsMatch($s) ) {
							$s = $processor.Search.Replace($s, $processor.Replace)
						}
					}
				}
			} while( $l -ne $s.Length)
			
			$entity | Add-Member -Name "TextAfterProcessing" -Value $s -Force -MemberType NoteProperty

			$entity
		}
		
		if( !([string]::IsNullOrEmpty($xmlOutputFile)) ) {
			$result4 | Export-Clixml $xmlOutputFile -Force -ErrorAction:$ErrorActionPreference
		}
		
		$sb = New-Object system.text.StringBuilder
		$result4 | % { 
			if(![string]::IsNullOrEmpty($_.TextAfterProcessing)) {
				$sb.append($_.TextAfterProcessing)
			}
		} | Out-Null
		
		return $sb.ToString().Trim()
	} catch {
		throw
	}
}

# Obfuscate
$obfuscatedScript = Obfuscate-Functions -script $obfuscatedScript
$obfuscatedScript = Obfuscate-Commands -script $obfuscatedScript

# Junk it
$obfuscatedScript = Add-RandomJunk -script $obfuscatedScript -junkLevel 350

# We do this last for better results
$obfuscatedScript = Obfuscate-StringsToBytes -script $obfuscatedScript
$obfuscatedScript = Obfuscate-Vars -script $obfuscatedScript

# Minify the output
$obfuscatedScript = Minify-Script -inputData $obfuscatedScript

# Step 3: Write to New File
Set-Content -Path "C:/Users/User/Desktop/TestScript_obfuscated.ps1" -Value $obfuscatedScript
