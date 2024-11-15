echo "Remember to run the other script and do forensics first. Did you do it?"
set /p DUMMY=Hit ENTER to continue...
echo "What function would you like to run? The list is the following.\n1. Create DNS Server\n2. "
:x
@echo off
set /p input=Type any input: 
if %input%==1 (
    set /p name=Input the name of the server: 
    set /p IP1=Input the primary IP address of the server: 
    set /p IP2=Input the secondary IP address of the server: 
    set /p forward=Input a list of forwards lookup zones of the server: 
    set /p backward=Input a list of backwards lookup zones of the server: 
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', '& {Import-Module .\DNS.psm1; New-DnsServer name IP1 IP2 forward backward}' -Verb RunAs}"
) else if %input%==2 (
    echo rawr3
) else if %input%==3 (
    echo rawr3
) else if %input%==4 (
    echo rawr4
) else if %input%==0 (
    goto y
)
goto x

:y
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', '& {Import-Module .\DNS.psm1; Sign-AllZones}' -Verb RunAs}"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', '& {Import-Module .\DNS.psm1; Sign-Secure-DnsServer}' -Verb RunAs}"

echo "Run 'net share' in a CMD and check for any unauthorised file sharing. Also configure any authorised file sharing."
set /p DUMMY=Hit ENTER to continue...
echo "Configure any user groups needed. Also check for any unauthorised user groups. To configure, go to lusrmgr.msc >> groups. From there you can configure anything you want."
set /p DUMMY=Hit ENTER to continue...
echo "Check open ports using 'netstat -ab'."
set /p DUMMY=Hit ENTER to continue...
::alias new_dns_server='pwsh -Command "Import-Module dns.psm1; New-DnsServer, Secure-DnsServer, Sign-AllZones"'
::pwsh -Command "New-DnsServer -Param1 Value1 -Param2 Value2"


::rewrite in batch script