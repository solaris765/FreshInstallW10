# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }

   # Run your code that needs to be elevated here
Write-Host -NoNewLine "This process has been automatically elevated. `nPress any key to continue...`n`n"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

   ##SELF ELEVATING CODE ABOVE##
#################################################################################
#################################################################################
write-host "Hello"

#$Scripts = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
#$Installers = $Scripts[0] + ":\Software\Installers"

#Scripts Under Debloat
$DebloatScripts = "\Scripts\block-telemetry.ps1", 
                  "\Scripts\fix-privacy-settings.ps1", 
                  "\Scripts\optimize-user-interface.ps1", 
                  "\Scripts\optimize-windows-update.ps1", 
                  "\Scripts\remove-default-apps.ps1"

#FUNCTIONS---------------------------------------------
function isInstalled ($check) {
    $TEST = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
    
    foreach ($item in $TEST) {If ($item -match 'X*' + $check) {return $true}}
    
    return $false
}

<#
.SOURCE
    https://github.com/MSAdministrator/GetGithubRepository
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
   This function will download files from Github without using Git.  You will need to know the Owner, Repository name, branch (default master),
   and FilePath.  The Filepath will include any folders and files that you want to download.
.EXAMPLE
   Get-GithubRepository -Owner MSAdministrator -Repository WriteLogEntry -Verbose -FilePath `
        'WriteLogEntry.psm1',
        'WriteLogEntry.psd1',
        'Public',
        'en-US',
        'en-US\about_WriteLogEntry.help.txt',
        'Public\Write-LogEntry.ps1'
#>
function Get-GithubRepository
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Please provide the repository owner
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Owner,

        # Please provide the name of the repository
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$Repository,

        # Please provide a branch to download from
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]$Branch = 'master',

        # Please provide a list of files/paths to download
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string[]]$FilePath
    )

    Begin
    {
        $modulespath = ($env:temp -split ";")[0]
        
        $PowerShellModule = "$modulespath\$Repository"

        Write-Verbose "Creating module directory"

        New-Item -Type Container -Force -Path $PowerShellModule | out-null

        Write-Verbose "Downloading and installing"

        $wc = New-Object System.Net.WebClient

        $wc.Encoding = [System.Text.Encoding]::UTF8

    }
    Process
    {
        foreach ($item in $FilePath)
        {
            Write-Verbose -Message "$item in FilePath"

            if ($item -like '*.*')
            {
                Write-Debug -Message "Attempting to create $PowerShellModule\$item"

                New-Item -ItemType File -Force -Path "$PowerShellModule\$item" | Out-Null

                $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"

                Write-Debug -Message "Attempting to download from $url"

                ($wc.DownloadString("$url")) | Out-File "$PowerShellModule\$item"
            }
            else
            {
                Write-Debug -Message "Attempting to create $PowerShellModule\$item"

                New-Item -ItemType Container -Force -Path "$PowerShellModule\$item" | Out-Null

                $url = "https://raw.githubusercontent.com/$Owner/$Repository/$Branch/$item"

                Write-Debug -Message "Attempting to download from $url"
            }
        }
    }
    End
    {
    }
}

function makeKeyIfNull {
#Returns an array of Length 2
#makeKeyIfNull[0] is the key value if it does exist
#makeKeyIfNull[1] is a boolean that return False if the key already Exists

param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Path,

    [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Name
    )

#Trim to file name
if ($Name.LastIndexOf('\')[0]) {
    $Name = $Name.Substring($Name.LastIndexOf("\")[0]+1)
}

#Make Path
IF (-Not (Test-Path $Path)) {New-Item -Path $Path}

#Check if Key Exists and has a value
try {
        Get-ItemPropertyValue -Path $RegistryPath -Name $Name 
        $check = $true
    } 
catch {
        $check = $false
    }

#Make Key
IF ($check) {
    write-host "Exists: " $Name 
    return $False
    }
Else {
    write-host "Does not Exist: " $Name
    New-ItemProperty -Path $Path -Name $Name -Value 1
    return $True
    }
}

#------------------------------------------------------

If (-Not (isInstalled("Chrome"))) {
    write-host "Chrome is being installed."
    #$Path = $env:TEMP; $Installer = "chrome_installer.exe"; Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer; Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait; Remove-Item $Path\$Installer
}
Else {write-host "Chrome has already been installed, skipping."}

$RegistryPath = "HKLM:\SOFTWARE\DebloatScripts\"
IF (-Not (Test-Path $RegistryPath)) {New-Item -Path $RegistryPath}

#Download Scripts from https://github.com/W4RH4WK/Debloat-Windows-10
Get-GithubRepository -Owner W4RH4WK -Repository Debloat-Windows-10 -FilePath 'lib\force-mkdir.psm1',
                                                                             'lib\take-own.psm1',
                                                                             'scripts\block-telemetry.ps1',
                                                                             'scripts\fix-privacy-settings.ps1',
                                                                             'scripts\optimize-user-interface.ps1',
                                                                             'scripts\optimize-windows-update.ps1',
                                                                             'scripts\remove-default-apps.ps1'

#Unblocks files from OS
$Debloat = $env:temp + "\Debloat-Windows-10"
$Unblock = $Debloat + "\*"
Unblock-File -Path $Unblock

$ScriptToRun = $Debloat

for ($i = 0; $i -lt $DebloatScripts.Length; $i++)
{
    $ScriptToRun += $DebloatScripts[$i]

    $notAlreadyRun = makeKeyIfNull -Path 'HKLM:\SOFTWARE\DebloatScripts' -Name $DebloatScripts[$i]
    If ($notAlreadyRun[1]) {
            Unblock-File -Path $ScriptToRun
            &$ScriptToRun
        }

    $ScriptToRun = $Debloat
} 
