# Variaveis
$groupName1 = "CN=,OU=,DC=,DC=,DC=" # Caminho do grupo
$groupName2 = "CN=,OU=,DC=,DC=,DC=" # Caminho do grupo
$logFile = "" # Path do caminho onde você deseja salvar o log do seu script

# Get nos dois grupos
$membersGroup1 = Get-ADGroupMember -Identity $groupName1 | Select-Object -ExpandProperty SamAccountName
$membersGroup2 = Get-ADGroupMember -Identity $groupName2 | Select-Object -ExpandProperty SamAccountName

# Comparação dos usuarios
$usersInBothGroups = Compare-Object -ReferenceObject $membersGroup1 -DifferenceObject $membersGroup2 -IncludeEqual | Where-Object { $_.SideIndicator -eq "==" } | Select-Object -ExpandProperty InputObject

# Logica + log
if ($usersInBothGroups.Count -eq 0) {
    Write-Output "Nenhum usuário para remover."
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Nenhum usuário para remover."
    Add-Content -Path $logFile -Value $logEntry
} else {
    
    foreach ($user in $usersInBothGroups) {
        Remove-ADGroupMember -Identity $groupName1 -Members $user -Confirm:$false
    }

    
    foreach ($user in $usersInBothGroups) {
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Usuário '$user' removido do grupo '$groupName1'."
        Add-Content -Path $logFile -Value $logEntry
    }
}
