# ObPS1

ObPS1 is a Powershell obfuscation script that aims to help obfuscate powershell. It is currently still being developed but has some very useful features.
1. Var obfuscation - Changes all var names to 32 character vars
2. Function obfuscation - Pretty much the same as above but it'll do it with function names
3. Command obfuscation - Currently replaces functions with a 32 var and then defines them all at the top of the script. It more affects how it's read, I plan on adding a get-command obfuscation method in the future
4. String to byte obfuscation - Will convert strings to byte/hex so instead of text it'll look like this: $([char]([byte]0x53))$([char]([byte]0x3A))$([char]([byte]0x5C))$([char]([byte]0x49))$([char]([byte]0x6E))$([char]([byte]0x66))
5. Junk adder - This is currently static but I hope to work to make it a dynamic junk code generator in the future, currently you can adjust how much junk code it adds to help prevent readability
6. Minifier - This will minify the script affecting it's readability.

This is pretty non-invasive so it should work with most scripts, currently it doesn't accept prams but I plan on making it more standardised in the future.
