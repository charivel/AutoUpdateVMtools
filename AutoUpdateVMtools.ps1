<#
    .NOTES
    ===========================================================================
     Créé par:  Christophe HARIVEL
	 Date: 		02 mars 2020
     Blog:      www.vrun.fr
     Twitter:   @harivchr
    ===========================================================================
    .DESCRIPTION
        L'objectif de ce script est de fournir 3 fonctions pour la lister/activer/désactiver la fonctionnalité de vérification et mise à jour automatique des VMtools à chaque reboot des VMs
		
		Script réalisé avec vSphere 6.5
    ===========================================================================
	.NOTICE
        Penser à modifier les variables dans la rubriques "VARIABLES A MODIFIER"
		Puis lancer ./AutoUpdateVMtools.ps1
#>

####################### VARIABLES A MODIFIER ###################################
# Indiquer le nom du vCenter
$VC = "nom_du_vcenter"

# Indiquer le nom du cluster sur lequel appliquer la configuration
$cluster = "nom_du_cluster"


####################### LISTE DES FONCTIONS ###################################

function Get-VMTools-Policy (){
	$result = @()
	
	$List = get-cluster $cluster| get-vm
	
	foreach($vm in $List){
		$Object = new-object PSObject
		$Object | add-member -name "VM" -membertype Noteproperty -value $vm.Name
		$Object | add-member -name "OS" -membertype Noteproperty -value $vm.Guest.OSFullName
		$Object | add-member -name "VMTools Version" -membertype Noteproperty -value $vm.ExtensionData.Config.Tools.ToolsVersion
		$Object | add-member -name "VMTools Policy" -membertype Noteproperty -value $vm.ExtensionData.Config.Tools.ToolsUpgradePolicy
		
		$result	+= $Object
	}
	return $result
}

function Enable-VMTools-Auto-Update (){
	$result = @()
	
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
	$vmConfigSpec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"
	
	$List = get-cluster $cluster| get-vm | where {$_.ExtensionData.Config.Tools.ToolsUpgradePolicy -like "manual"}
	
	foreach($vm in $List){
		$vm.ExtensionData.ReconfigVM_task($vmConfigSpec) 2>$null
		write-host "Enabled: $vm" 
	}
	
}

function Disable-VMTools-Auto-Update (){
	$result = @()
	
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
	$vmConfigSpec.Tools.ToolsUpgradePolicy = "manual"
	
	$List = get-cluster $cluster| get-vm | where {$_.ExtensionData.Config.Tools.ToolsUpgradePolicy -like "UpgradeAtPowerCycle"}
	
	foreach($vm in $List){
		$vm.ExtensionData.ReconfigVM_task($vmConfigSpec) 2>$null
		write-host "Disabled: $vm" 
	}
	
}

####################### SCRIPT ###################################

############## CONNEXION AU VCENTER
	write-host "Connexion au vCenter: $VC" -foregroundcolor "green"
	Connect-VIServer -server $VC 
	write-host
	
############## LANCEMENT DE LA FONCTION SOUHAITEE
	# Commenter les fonctions que vous ne souhaitez pas lancer
	
	# Enable-VMTools-Auto-Update
	# Disable-VMTools-Auto-Update
	Get-VMTools-Policy | ft


############## DECONNEXION DU VCENTER
	write-host "Deconnexion du vCenter: $VC" -foregroundcolor "green"
	Disconnect-VIServer * -confirm:$false
	write-host