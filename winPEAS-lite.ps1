$ErrorActionPreference='SilentlyContinue';$ProgressPreference='SilentlyContinue'
function S($t,[scriptblock]$b){"";"## $t";"";'```text';(((& $b|Out-String -Width 4096) -split "`n" | ForEach-Object {$_.TrimEnd()}) -join "`n").Trim();'```'}
"# Windows Enumeration Report - $env:COMPUTERNAME - $(Get-Date -Format s)"
S "OS / SYSTEM" { Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,InstallDate,LastBootUpTime | Format-List; Get-CimInstance Win32_ComputerSystem | Select-Object Name,Manufacturer,Model,Domain,PartOfDomain,Workgroup | Format-List }
S "HOTFIXES" { Get-HotFix | Sort-Object InstalledOn | Format-Table HotFixID,Description,InstalledOn -Auto }
S "CURRENT USER" { whoami 2>$null; whoami /user 2>$null }
S "GROUPS" { whoami /groups 2>$null }
S "PRIVILEGES" { whoami /priv 2>$null }
S "LOCAL USERS" { Get-LocalUser | Select-Object Name,Enabled,LastLogon,PasswordRequired,PasswordLastSet | Format-Table -Auto }
S "LOCAL GROUPS" { Get-LocalGroup | Select-Object Name | Format-Table -Auto }
S "ADMINISTRATORS MEMBERS" { Get-LocalGroupMember Administrators | Format-Table Name,ObjectClass -Auto }
S "DOMAIN CONTROLLERS" { nltest /dclist:$env:USERDNSDOMAIN 2>$null; nltest /domain_trusts 2>$null }
S "IP CONFIGURATION" { Get-NetIPConfiguration | Format-List; ipconfig /all 2>$null }
S "ROUTING TABLE" { Get-NetRoute | Select-Object DestinationPrefix,NextHop,RouteMetric,ifIndex | Format-Table -Auto }
S "ARP CACHE" { Get-NetNeighbor | Where-Object State -ne Unreachable | Select-Object IPAddress,LinkLayerAddress,State | Format-Table -Auto }
S "ACTIVE CONNECTIONS" { Get-NetTCPConnection | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess | Sort-Object State | Format-Table -Auto }
S "FIREWALL PROFILES" { Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction | Format-Table -Auto }
S "HOSTS FILE" { Get-Content "$env:windir\System32\drivers\etc\hosts" }
S "PROCESSES" { Get-CimInstance Win32_Process | Select-Object ProcessId,Name,CommandLine | Format-Table -Auto }
S "ALL SERVICES" { Get-CimInstance Win32_Service | Select-Object Name,DisplayName,State,StartName,StartMode,PathName | Format-Table -Auto }
S "UNQUOTED SERVICE PATHS" { Get-CimInstance Win32_Service | Where-Object {$_.PathName -and $_.PathName -notmatch '^"' -and $_.PathName -match ' ' -and $_.PathName -notmatch [regex]::Escape($env:windir)} | Select-Object Name,PathName | Format-Table -Auto }
S "STARTUP COMMANDS" { Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location,User | Format-Table -Auto }
S "SCHEDULED TASKS" { Get-ScheduledTask | Select-Object TaskName,TaskPath,State,@{n='RunAs';e={$_.Principal.UserId}} | Format-Table -Auto }
S "INSTALLED SOFTWARE" { Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher | Sort-Object DisplayName | Format-Table -Auto }
S "INSTALLED DRIVERS" { driverquery /v /fo csv 2>$null | ConvertFrom-Csv | Select-Object 'Display Name','Driver Type','Path' | Format-Table -Auto }
S "DISKS AND VOLUMES" { Get-Volume | Select-Object DriveLetter,FileSystemLabel,FileSystem,DriveType,@{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}},@{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}} | Format-Table -Auto }
S "BITLOCKER" { Get-BitLockerVolume | Select-Object MountPoint,ProtectionStatus,VolumeStatus | Format-Table -Auto }
S "SHADOW COPIES" { vssadmin list shadows 2>$null }
S "NETWORK SHARES" { Get-SmbShare | Select-Object Name,Path,Description | Format-Table -Auto }
S "MAPPED DRIVES" { Get-SmbMapping | Format-Table -Auto; Get-CimInstance Win32_MappedLogicalDisk | Select-Object Name,ProviderName | Format-Table -Auto }
S "ALWAYSINSTALLELEVATED" { Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer -Name AlwaysInstallElevated | Select-Object AlwaysInstallElevated; Get-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer -Name AlwaysInstallElevated | Select-Object AlwaysInstallElevated }
S "WINLOGON AUTOLOGON" { Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" | Select-Object DefaultUserName,DefaultDomainName,DefaultPassword,AutoAdminLogon | Format-List }
S "STORED CREDENTIALS" { cmdkey /list 2>$null }
S "SAVED RDP SERVERS" { Get-ChildItem "HKCU:\Software\Microsoft\Terminal Server Client\Servers" | Format-Table -Auto }
S "WIFI PROFILES" { netsh wlan show profiles 2>$null }
S "POWERSHELL HISTORY" { Get-Content (Get-PSReadlineOption).HistorySavePath }
S "SENSITIVE FILES" { Get-ChildItem C:\ -Recurse -Force -Include *.kdbx,*.ppk,*.pem,*.pfx,*.p12,*.key,*.crt,*.cer,*.ovpn,*.rdp,*.vnc,*.gpg,*.config,*.ini,*.bak,*.old,*.sql,*id_rsa*,*.kdb,web.config,unattend.xml,*password*,*cred*,*secret* | ForEach-Object { "{0}  {1,10} bytes  {2}" -f $_.LastWriteTime,$_.Length,$_.FullName } }
S "DEFENDER STATUS" { Get-MpComputerStatus | Select-Object AMRunningMode,RealTimeProtectionEnabled,AntivirusEnabled,IoavProtectionEnabled | Format-List }
S "DEFENDER EXCLUSIONS" { Get-MpPreference | Select-Object -ExpandProperty ExclusionPath; Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess }
S "AV PRODUCTS" { Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntivirusProduct | Select-Object displayName,productState | Format-Table -Auto }
S "LANGUAGE MODE" { $ExecutionContext.SessionState.LanguageMode }
S "HARDWARE / BIOS" { Get-CimInstance Win32_BIOS | Select-Object Manufacturer,Name,SerialNumber,SMBIOSBIOSVersion,Version,ReleaseDate | Format-List; Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber,Version | Format-List; Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors | Format-List }
S "TIMEZONE / LOCALE" { Get-TimeZone | Select-Object Id,DisplayName | Format-List; Get-WinSystemLocale | Select-Object Name,DisplayName | Format-List }
S "SESSIONS" { qwinsta 2>$null; query user 2>$null; klist sessions 2>$null }
S "DNS CLIENT CACHE" { Get-DnsClientCache | Select-Object Entry,Name,Data,Type | Format-Table -Auto }
S "UDP ENDPOINTS" { Get-NetUDPEndpoint | Select-Object LocalAddress,LocalPort,OwningProcess | Format-Table -Auto }
S "AUTORUN REGISTRY KEYS" { 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run' | ForEach-Object { "[$_]"; Get-ItemProperty $_ | Select-Object * -Exclude PS* | Format-List } }
S "WINLOGON SHELL / USERINIT" { Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" | Select-Object Shell,Userinit,AppSetup,GinaDLL | Format-List }
S "LSA CONFIG" { Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' | Select-Object RunAsPPL,LmCompatibilityLevel,NoLMHash,RestrictAnonymous,DisableRestrictedAdmin,LimitBlankPasswordUse | Format-List }
S "DLL HIJACK SURFACE" { $w='HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Windows'; "AppInit_DLLs: "+(Get-ItemProperty $w).AppInit_DLLs; "LoadAppInit_DLLs: "+(Get-ItemProperty $w).LoadAppInit_DLLs; "RequireSignedAppInit_DLLs: "+(Get-ItemProperty $w).RequireSignedAppInit_DLLs; "KnownDLLs:"; Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs' | Select-Object * -Exclude PS* | Format-List }
S "WRITABLE PATH DIRS" { $env:PATH -split ';' | Where-Object {$_} | ForEach-Object { $d=$_; try { $t=Join-Path $d ([guid]::NewGuid().ToString()); [IO.File]::WriteAllText($t,'x'); Remove-Item $t -Force; "WRITABLE: $d" } catch {} } }
S "MODIFIABLE SERVICE BINARIES" { Get-CimInstance Win32_Service | Where-Object {$_.PathName} | ForEach-Object { $p=($_.PathName -replace '^"([^"]+)".*','$1'); $exe=($p -split '\.exe')[0]+'.exe'; if($exe -notmatch '^[A-Za-z]:\\Windows' -and (Test-Path $exe)) { try { $fs=[IO.File]::OpenWrite($exe); $fs.Close(); "WRITABLE BINARY: $($_.Name) -> $exe" } catch {} } } }
S "CERTIFICATES" { Get-ChildItem Cert:\LocalMachine\My,Cert:\CurrentUser\My | Select-Object Subject,Issuer,NotAfter,HasPrivateKey,Thumbprint | Format-Table -Auto }
S "RDP CONFIG" { Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' | Select-Object fDenyTSConnections | Format-List; Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' | Select-Object PortNumber,UserAuthentication,SecurityLayer | Format-List }
S "EVENT LOGS WITH RECORDS" { Get-WinEvent -ListLog * 2>$null | Where-Object RecordCount -gt 0 | Sort-Object RecordCount -Descending | Select-Object LogName,RecordCount -First 40 | Format-Table -Auto }
S "RECENT PROCESS CREATION 4688" { Get-WinEvent -FilterHashtable @{LogName='Security';Id=4688} -MaxEvents 25 2>$null | Select-Object TimeCreated,@{n='NewProcess';e={$_.Properties[5].Value}},@{n='CommandLine';e={$_.Properties[8].Value}} | Format-Table -Auto }
S "WMI EVENT SUBSCRIPTIONS" { Get-WmiObject -Namespace root\Subscription -Class __EventFilter 2>$null | Select-Object Name,Query | Format-List; Get-WmiObject -Namespace root\Subscription -Class __FilterToConsumerBinding 2>$null | Select-Object Filter,Consumer | Format-List; Get-WmiObject -Namespace root\Subscription -Class __EventConsumer 2>$null | Select-Object Name,__CLASS | Format-List }
S "POWERSHELL CONFIG" { Get-ExecutionPolicy -List | Format-Table -Auto; "Profiles:"; $PROFILE.AllUsersAllHosts,$PROFILE.CurrentUserAllHosts | ForEach-Object { if(Test-Path $_){ "== $_ =="; Get-Content $_ } }; "Transcripts:"; Get-ChildItem $env:USERPROFILE\Documents -Recurse -Filter *transcript* -File 2>$null | Select-Object FullName }
S "DPAPI / VAULT LOCATIONS" { cmdkey /list 2>$null; vaultcmd /list 2>$null; "Blob locations:"; Get-ChildItem "$env:APPDATA\Microsoft\Protect","$env:APPDATA\Microsoft\Credentials","$env:LOCALAPPDATA\Microsoft\Credentials","$env:APPDATA\Microsoft\Vault" -Recurse -Force 2>$null | ForEach-Object { "$($_.FullName)  ($($_.Length) bytes)" } }
S "NULL SESSION / SHARE CONFIG" { Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' | Select-Object NullSessionShares,NullSessionPipes,RestrictNullSessAccess | Format-List }
S "RECENT FILES / PREFETCH" { Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -Force 2>$null | Select-Object Name,LastWriteTime | Format-Table -Auto; Get-ChildItem C:\Windows\Prefetch -Force 2>$null | Sort-Object LastWriteTime -Descending | Select-Object Name,LastWriteTime -First 40 | Format-Table -Auto }
S "DOMAIN DISCOVERY" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ nltest /dsgetdc:$env:USERDNSDOMAIN 2>$null; nltest /domain_trusts /all_trusts 2>$null; net group "Domain Controllers" /domain 2>$null } else { "Not domain-joined" } }
S "DOMAIN USERS AND GROUPS" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ net user /domain 2>$null; net group "Domain Admins" /domain 2>$null; net group "Enterprise Admins" /domain 2>$null; net accounts /domain 2>$null } else { "Not domain-joined" } }
S "KERBEROASTABLE SPNS" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ setspn -T $env:USERDNSDOMAIN -Q */* 2>$null } else { "Not domain-joined" } }
S "GPP CPASSWORD SEARCH" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ Get-ChildItem "\\$env:USERDNSDOMAIN\SYSVOL" -Recurse -Include *.xml -Force 2>$null | Select-String -Pattern 'cpassword' 2>$null | ForEach-Object { "$($_.Path): L$($_.LineNumber): $($_.Line.Trim())" } } else { "Not domain-joined" } }
S "LOCAL PASSWORD POLICY" { net accounts 2>$null }
S "UAC CONFIG" { Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Select-Object EnableLUA,ConsentPromptBehaviorAdmin,PromptOnSecureDesktop,LocalAccountTokenFilterPolicy,FilterAdministratorToken | Format-List }
S "WSUS CONFIG" { Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' | Select-Object WUServer,WUStatusServer | Format-List; Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' | Select-Object UseWUServer | Format-List }
S "WINDOWS OPTIONAL FEATURES" { Get-WindowsOptionalFeature -Online 2>$null | Where-Object State -eq Enabled | Select-Object FeatureName | Format-Table -Auto }
S "INSTALLED PS MODULES" { Get-Module -ListAvailable | Select-Object Name,Version,ModuleType | Sort-Object Name | Format-Table -Auto }
S "BROWSER ARTIFACTS" { 'Google\Chrome\User Data\Default\Login Data','Google\Chrome\User Data\Default\Cookies','Google\Chrome\User Data\Default\History','Microsoft\Edge\User Data\Default\Login Data' | ForEach-Object { $p=Join-Path $env:LOCALAPPDATA $_; if(Test-Path $p){ "FOUND: $p" } }; Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Force 2>$null | Select-Object FullName | Format-Table -Auto }
S "CONFIG FILE CREDENTIALS" { $f="$env:windir\system32\inetsrv\config\applicationHost.config"; if(Test-Path $f){ Select-String -Path $f -Pattern 'password|userName' 2>$null | ForEach-Object { "$($f): L$($_.LineNumber): $($_.Line.Trim())" } }; Get-ChildItem C:\inetpub -Recurse -Include web.config -Force 2>$null | Select-String -Pattern 'password|connectionString' 2>$null | ForEach-Object { "$($_.Path): L$($_.LineNumber): $($_.Line.Trim())" } }
S "WRITABLE PROGRAM FILES BINARIES" { Get-ChildItem 'C:\Program Files','C:\Program Files (x86)' -Recurse -Include *.exe,*.dll -Force 2>$null | ForEach-Object { try { $fs=[IO.File]::OpenWrite($_.FullName); $fs.Close(); "WRITABLE: $($_.FullName)" } catch {} } }
S "PRIVILEGED DOMAIN GROUPS" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ 'Schema Admins','Backup Operators','Account Operators','Server Operators','Print Operators','DnsAdmins','Domain Computers' | ForEach-Object { "== $_ =="; net group "$_" /domain 2>$null } } else { "Not domain-joined" } }
S "GPO RESULT" { gpresult /r 2>$null }
S "SYSVOL SCRIPT CRED SEARCH" { if((Get-CimInstance Win32_ComputerSystem).PartOfDomain){ Get-ChildItem "\\$env:USERDNSDOMAIN\SYSVOL" -Recurse -Include *.bat,*.vbs,*.ps1,*.cmd -Force 2>$null | Select-String -Pattern 'password|net use|/user:' 2>$null | ForEach-Object { "$($_.Path): L$($_.LineNumber): $($_.Line.Trim())" } } else { "Not domain-joined" } }
S "ENVIRONMENT VARIABLES" { Get-ChildItem Env: | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" } }
