# Script criado para automatizar o processo de criptografia de disco, logo apos criptografar salva a chave de recuperação no Azure AD
# Para verificar os requisitos para criptografar um dispositivo: https://learn.microsoft.com/pt-br/windows/security/operating-system-security/data-protection/bitlocker/

# Verifica se o sistema atende aos requisitos do BitLocker
$tpmPresent = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm

if ($tpmPresent.IsEnabled) {
    # Obtém a unidade do sistema operacional
    $osVolume = Get-BitLockerVolume | Where-Object { $_.VolumeType -eq "OperatingSystem" }

    # Verifica o status de criptografia da unidade do sistema operacional
    if ($osVolume.VolumeStatus -eq "FullyDecrypted") {
        # Ativa o BitLocker usando o comando manage-bde
        $encryptionMethod = "AES256"
        $usedSpaceOnly = $true
        manage-bde -on $osVolume.MountPoint -em $encryptionMethod
        manage-bde -protectors -enable $osVolume.MountPoint

        Write-Host "BitLocker ativado com sucesso!"

        # Obter informações sobre o volume BitLocker associado à unidade do sistema
        $bitlockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive

        # Verificar se já existe um protetor de chave do tipo "RecoveryPassword"
        $recoveryProtector = $bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }

        if ($recoveryProtector -eq $null) {
            # Se não houver um protetor de chave de recuperação, adicioná-lo
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector
        }

        # Obtendo novamente as informações do volume BitLocker após a possível adição do protetor
        $bitlockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive

        # Exibindo todos os protetores de chave disponíveis para o volume
        $bitlockerVolume.KeyProtector | ForEach-Object {
            Write-Host "Protetor de chave: $_.KeyProtectorType"
        }

        # Encontrar o protetor de chave com o tipo "RecoveryPassword"
        $recoveryProtector = $bitlockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }

        # Verificar se foi encontrado um protetor de chave de recuperação
        if ($recoveryProtector -ne $null) {
            # Obter o ID do protetor de chave de recuperação
            $keyProtectorId = $recoveryProtector.KeyProtectorId

            # Fazer backup da chave no Azure Active Directory
            BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $keyProtectorId
        } else {
            Write-Host "Nenhum protetor de chave de recuperação encontrado para o volume do sistema."
        }
    } else {
        Write-Host "A unidade do sistema operacional não está completamente descriptografada."
    }
} else {
    Write-Host "O TPM não está presente ou não está configurado corretamente."
}
