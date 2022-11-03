-- Grab the recovery key for the specified device; be sure to replace 'ComputerNameHere' with the hostname

Use [MBAM Recovery and Hardware]
Select mac.Name "Machine Name",
    K.RecoveryKeyId "Recovery Key ID",
    K.RecoveryKey "Recovery Key",
    K.LastUpdateTime
FROM [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Machines MAC
    JOIN [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Machines_Volumes mv ON MAC.id = mv.machineid
    JOIN [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Keys k ON mv.volumeId = k.VolumeID
Where mac.Name = 'ComputerNameHere'