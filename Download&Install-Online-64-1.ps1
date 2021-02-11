<#
    EXECUTER LE SCRIPT EN ADMINISTRATEUR
    
#>

function Use-RunAs 
{    
    
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }     
 
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
        {  
            try 
            {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Erreur - Impossible de redemarrer le script avec 'runas'"  
                break               
            } 
            exit # Termine la session powershell
        }  
    }  
    else  
    {  
        Write-Warning "Erreur - Le script doit être sauve en .ps1 avant"  
        break  
    }  
} 
 
 
Use-RunAs

Set-ExecutionPolicy Unrestricted

# Repertoire Script

function Get-ScriptDirectory {
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    }
    else {
        $global:PSScriptRoot
    }
}

function Get-ODTUri {
    <#
 
       Recuperation ODT
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $ODTUri.href
    }
}

<#
Données:
PowerShell Wrapper pour MDT, Standalone and Chocolatey Installation
Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
Example 3 EXE (Always use ' '):
$UnattendedArgs='/qn'
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
Example 4 MSI (Always use " "):
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode
#>

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$scriptdirectory = Get-ScriptDirectory
cd $scriptdirectory

$Vendor = "Microsoft"
$Product = "Office 365"
$PackageName = "setup"
$InstallerType = "exe"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$Unattendedxml = 'configuration64.xml'
$UnattendedArgs = "/configure $Unattendedxml"
$UnattendedArgs2 = "/download $Unattendedxml"
$URL = $(Get-ODTUri)
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

Write-Verbose "Downloading latest version of Office 365 Deployment Tool (ODT)." -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile .\officedeploymenttool.exe
Write-Verbose "Read version number from downloaded file" -Verbose
$Version = (Get-Command .\officedeploymenttool.exe).FileVersionInfo.FileVersion

Write-Verbose "If downloaded ODT file is newer, create new sub-directory." -Verbose
if( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
    Copy-item ".\$Unattendedxml" -Destination $Version -Force
    .\officedeploymenttool.exe /quiet /extract:.\$Version
    start-sleep -s 5
    Write-Verbose "New folder created $Version" -Verbose
}
else {
    Write-Verbose "Version identical. Skipping folder creation." -Verbose
}

Set-Location $Version

Write-Verbose "Downloading $Vendor $Product via ODT $Version" -Verbose
if (!(Test-Path -Path .\Office\Data\v64.cab)) {
    (Start-Process "setup.exe" -ArgumentList $unattendedArgs2 -Wait -Passthru).ExitCode
}
else {
    Write-Verbose "File exists. Skipping Download." -Verbose
}

Write-Verbose "Starting Installation of $Vendor $Product via ODT $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
