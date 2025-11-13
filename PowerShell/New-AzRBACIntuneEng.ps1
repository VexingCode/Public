# Create AzureAD 'Intune Engineer' role information
$displayName = "Intune Engineer"
$description = "Grants permissions similar to an Intune Administrators, without full control. Intended for the Device Engineering team members that are not Intune Administrators."
$templateId = (New-Guid).Guid
 
# Set of permissions to grant
$allowedResourceAction =
@(
    "microsoft.directory/bitlockerKeys/key/read", # Read bitlocker metadata and key on devices.
    "microsoft.directory/bitlockerKeys/metadata/read", # Read bitlocker key metadata on devices.
    "microsoft.directory/devices/delete", # Delete devices from Azure AD
    "microsoft.directory/devices/disable", # Disable devices in Azure AD
    "microsoft.directory/devices/enable", # Enable devices in Azure AD
    "microsoft.directory/devices/extensionAttributeSet1/update", # Update the extensionAttribute1 to extensionAttribute5 properties on devices
    "microsoft.directory/devices/extensionAttributeSet2/update", # Update the extensionAttribute6 to extensionAttribute10 properties on devices
    "microsoft.directory/devices/extensionAttributeSet3/update", # Update the extensionAttribute11 to extensionAttribute15 properties on devices
    "microsoft.directory/devices/registeredOwners/update", # Update registered owners of devices
    "microsoft.directory/devices/registeredUsers/update", # Update registered users of devices
    "microsoft.directory/deviceLocalCredentials/password/read", # Read all properties of the backed up local administrator account credentials for Azure AD joined devices, including the password
    "microsoft.directory/deviceManagementPolicies/standard/read", # Read standard properties on device management application policies
    "microsoft.directory/deviceRegistrationPolicy/standard/read", # Read standard properties on device registration policies
    "microsoft.directory/groups.security/create", # Create Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/delete", # Delete Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/basic/update", # Update basic properties on Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/classification/update", # Update the classification property on Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/dynamicMembershipRule/update", # Update the dynamic membership rule on Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/members/update", # Update members of Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/owners/update", # Update owners of Security groups, excluding role-assignable groups
    "microsoft.directory/groups.security/visibility/update" # Update the visibility property on Security groups, excluding role-assignable groups
    
)
$rolePermissions = @{'allowedResourceActions'= $allowedResourceAction}
 
# Create new custom admin role
$customAdmin = New-MgRoleManagementDirectoryRoleDefinition -RolePermissions $rolePermissions -DisplayName $displayName -IsEnabled -Description $description -TemplateId $templateId