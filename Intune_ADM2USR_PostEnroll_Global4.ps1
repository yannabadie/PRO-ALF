#Contexte:
#** SystÃ¨me
#** AprÃ¨s l'enrollement du device par le compte Administrateur local.
#Objectif: 
# 1) TransfÃ©rer le nouveau compte Azure AD (Administrateur local) dans le groupe local "users"
# 2) Transferer tout autre compte Administrateur local (sauf systÃ¨me) vers le groupe local "users"
###NOTE: Remplacer si nÃ©cessaire 'tenantname' par le nom du domaine ou 'AzureAD'
#1)
#Acquisition des noms de groupes
$UsersGroupName = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-545'").Name
$AdminGroupName = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-544'").Name

#RÃ©cupÃ©ration du TenantName
$dsregcmd = dsregcmd /status
$Tenant=$dsregcmd -match 'TenantName'

$TenantName = $Tenant.split(':')[1] -replace ' ',''

#Acquisition du localusername
$AdminGroupMembers = net localgroup $AdminGroupName
$UsersGroupMembers = net localgroup $UsersGroupName

$LocalUserName = $AdminGroupMembers -match "AzureAD"


if($LocalUserName -match "AzureAD"){

net localgroup $UsersGroupName $LocalUserName /add
net localgroup $AdminGroupName $LocalUserName /delete

    }elseif($AdminGroupMembers -match "$TenantName"){
    
    
net localgroup $UsersGroupName $LocalUserName /add
net localgroup $AdminGroupName $LocalUserName /delete


    }

<#
net localgroup $UsersGroupName $LocalUserName /add
net localgroup $AdminGroupName $LocalUserName /delete
#>

#2)

#RÃ©cupÃ©ration des comptes users systemes locaux
$Accounts_SYS_local_SID = (Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-50%'").SID
$Accounts_SYS_local = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-50%'"

#RÃ©cupÃ©ration des comptes users locaux
$Accounts_local_SID = (Get-WmiObject -Class Win32_UserAccount).SID
$Accounts_local = Get-WmiObject -Class Win32_UserAccount

#Obtentions des comptes users locaux non systeme
$Accounts_local_NSYS = @()
$Account = @()
foreach($Account in $Accounts_local){


        if ($Accounts_SYS_local -notcontains $Account){
        
                
        $Accounts_local_NSYS += $Account


        }
}


#Obtention des noms des comptes users locaux non systeme
$Accounts_local_NSYS_NAMES = $Accounts_local_NSYS.Name

$NSYSNAME = @()

#Changements de grous des NSYS users

foreach($NSYSNAME in $Accounts_local_NSYS_NAMES){

#Ajout/suppression aux groupes
net localgroup $UsersGroupName $NSYSNAME /add


}


$NSYSNAME = @()

foreach($NSYSNAME in $Accounts_local_NSYS_NAMES){

#Ajout/suppression aux groupes

net localgroup $AdminGroupName $NSYSNAME /delete

}
