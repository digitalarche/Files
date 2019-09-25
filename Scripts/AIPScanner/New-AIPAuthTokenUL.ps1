if (Get-InstalledModule -Name "AzureAD" -ErrorAction SilentlyContinue) {
    "Importing Azure AD Module"
    Import-Module -Name "AzureAD"
} else {
    "Installing Azure AD Module"
    Install-Module -Name "AzureAD"
    "Importing Azure AD Module"
    Import-Module -Name "AzureAD"
}

$gacred = get-credential -Message "Enter Azure Global Admin Credentials"

"Connecting to Azure AD"
Connect-AzureAD -Credential $gacred

$Date = Get-Date -UFormat %m%d%H%M
$DisplayName = "AIPOBOv2-" + $Date

"Creating Azure AD Applications. This may take 1-2 minutes."	
"Creating Web Application $DisplayName and Secret key with one year expiration "

$SvcPrincipal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Rights Management Services" }
$ReqAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$ReqAccess.ResourceAppId = $SvcPrincipal.AppId

$Role1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "d13f921c-7f21-4c08-bade-db9d048bd0da", "Role"
$Role2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "7347eb49-7a1a-43c5-8eac-a5cd1d1c7cf0", "Role"
$Role3 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "006e763d-a822-41fc-8df5-8d3d7fe20022", "Role"
$ReqAccess.ResourceAccess = $Role1, $Role2, $Role3

$SvcPrincipalUL = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Information Protection Sync Service" }
$ReqAccessUL = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$ReqAccessUL.ResourceAppId = $SvcPrincipalUL.AppId

$Role4 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "8b2071cd-015a-4025-8052-1c0dba2d3f64", "Role"
$ReqAccessUL.ResourceAccess = $Role4

New-AzureADApplication -DisplayName $DisplayName -ReplyURLs http://localhost -RequiredResourceAccess @($ReqAccess, $ReqAccessUL)
$WebApp = Get-AzureADApplication -Filter "DisplayName eq '$DisplayName'"
New-AzureADServicePrincipal -AppId $WebApp.AppId
$WebAppKey = New-Guid
$Date = Get-Date
New-AzureADApplicationPasswordCredential -ObjectId $WebApp.ObjectID -startDate $Date -endDate $Date.AddYears(1) -Value $WebAppKey.Guid -CustomKeyIdentifier "Password"
$TenantID = (Get-AzureADCurrentSessionInfo).tenantid

"Generating Authenitcation Token scripts for AIP Scanner Service"    
Start-Sleep -Seconds 5

'"A browser will launch to the created web application to provide Admin consent for the required API permissions. Please log in with tenant admin credentials to provide permissions for this application.  If you are unable to provide this consent, please provide the URL below to your tenant administrator."' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1
'$weburl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/'+$WebApp.AppId+'/isMSAApp/"' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
"" | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
'$weburl' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
'"Press Enter below to launch the browser"' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
"" | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
'Pause' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
'Start-Process $weburl' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append
'Pause' | Out-File ~\Desktop\Grant-AdminConsentUL.ps1 -Append

'$ServiceAccount = Get-Credential -Message "Enter the on-premises service account credentials"' | Out-File ~\Desktop\Set-AIPAuthenticationUL.ps1 -Append
"Set-AIPAuthentication -AppID " + $WebApp.AppId + " -AppSecret " + $WebAppKey.Guid + " -TenantID " + $TenantID.Guid + ' -OnBehalfOf $ServiceAccount' | Out-File ~\Desktop\Set-AIPAuthenticationUL.ps1 -append
""
"Authenitcation Token scripts stored on the desktop as Grant-AdminConsentUL.ps1 and Set-AIPAUthenticationUL.ps1"
""
"Follow the instructions at https://aka.ms/ScannerBlog to install the service"
""
"Run the commands below to complete your AIP scanner installation"
""
"In the context of the AIP service account, run the Set-AIPAuthentication command stored in the text file"
"When prompted, sign in using the cloud or synced AIP scanner service account"
""
"In an Admin PowerShell prompt, run the command below"
"Restart-Service AIPScanner"
"Start-AIPScan"
Pause
