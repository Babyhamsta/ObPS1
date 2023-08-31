# Hi there this is a sample script, do note this is subject to change!
$var = "Ice cream would be great right now"

Function MakeIt()
{
    Write-Output "Function was hit!"
    return "Why are we obfuscating a script anyways? Who would want to read my code?"
}

MakeIt

if ($var -match "Ice")
{
    Write-Output "Now that's epic"
}


<# 
Output from script:

Function was hit!
Why are we obfuscating a script anyways? Who would want to read my code?
Now that's epic
#>
