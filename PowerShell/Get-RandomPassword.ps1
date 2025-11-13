# Generates random password. Adjust $pwlength to set min and max random password length
    Function Get-RandomPassword {
        # Generate a random length
        [int]$pwLength = Get-Random -Minimum 14 -Maximum 128
        # Set the number of Non-AlphaNumeric characters
        [int]$NumberOfNonAlphaNumericCharacters = 0
        Add-Type -AssemblyName 'System.Web'
        return [System.Web.Security.Membership]::GeneratePassword($pwLength, $NumberOfNonAlphaNumericCharacters)
    }
