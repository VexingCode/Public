-- Get status messages from MS.CM.exe, by status message ID

select * from vStatusMessagesWithStrings
where component = 'Microsoft.ConfigurationManagement.exe' and MessageID = #####