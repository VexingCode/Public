# Basic role information
$displayName = "Helpdesk Operators - Tier 1"
$description = "Can view and manage basic operations for devices and users. To be used in conjunction with the Intune role of the same name."
$templateId = (New-Guid).Guid
 
# Set of permissions to grant
$allowedResourceAction =
@(
    "microsoft.directory/bitlockerKeys/key/read", # Read bitlocker metadata and key on devices.
    "microsoft.directory/bitlockerKeys/metadata/read", # Read bitlocker key metadata on devices.
    "microsoft.directory/devices/registeredOwners/update", # Update registered owners of devices.
    "microsoft.directory/devices/registeredUsers/update" # Update registered users of devices.
)
$rolePermissions = @{'allowedResourceActions'= $allowedResourceAction}
 
# Create new custom admin role
$customAdmin = New-AzureADMSRoleDefinition -RolePermissions $rolePermissions -DisplayName $displayName -Description $description -TemplateId $templateId -IsEnabled $true