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
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            exit # Quit this session of powershell 
        }  
    }  
    else  
    {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
} 
 
 
Use-RunAs


# Repertoire Script

function Get-ScriptDirectory {
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    }
    else {
        $global:PSScriptRoot
    }
}

$RepertoireScript = Get-ScriptDirectory

cd $RepertoireScript

#M35 connection

Get-Module AzureAD
Install-Module AzureAD
Import-Module AzureAD

Get-Module ExchangeOnlineManagement
Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement

Connect-AzureAD
Connect-ExchangeOnline

#CHEMIN
$NomCSV=Read-Host "NomFichiercsv.csv"
$CheminCSV = ".\"+$NomCSV
$CSV= Import-Csv -Path $CheminCSV -Delimiter ","
$password = Read-host "ENTER ONE PASSWORD FOR RULE THEM ALL (8c mini)" -AsSecureString

foreach($users in $CSV){

$Name = $users.AdresseSolution30.Split('@')[0]

New-mailuser -PrimarySmtpAddress $users.AdresseExterne -ExternalEmailAddress $users.AdresseExterne -Name $Name -MicrosoftOnlineServicesID $users.AdresseSolution30 -Password $password

Write-Host $Name

}

$CSV | ogv