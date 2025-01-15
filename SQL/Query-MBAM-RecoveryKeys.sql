-- Get devices and their recovery keys from the MBAM database

Select mac.Name "Machine Name",
    K.RecoveryKeyId "Recovery Key ID",
    K.RecoveryKey "Recovery Key"
FROM [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Machines MAC
    JOIN [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Machines_Volumes mv ON MAC.id = mv.machineid
    JOIN [MBAM Recovery and Hardware].RecoveryAndHardwareCore.Keys k ON mv.volumeId = k.VolumeID