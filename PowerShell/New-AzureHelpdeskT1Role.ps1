# Basic role information
$displayName = "Helpdesk Operators - Tier 1"
$description = "Can view and manage basic operations for devices and users. To be used in conjunction with the Intune role of the same name, and Global Reader."
$templateId = (New-Guid).Guid
 
# Set of permissions to grant
$allowedResourceAction =
@(
    "microsoft.directory/bitlockerKeys/key/read", # Read bitlocker metadata and key on devices.
    "microsoft.directory/bitlockerKeys/metadata/read", # Read bitlocker key metadata on devices.
    "microsoft.directory/deviceManagementPolicies/standard/read", # Read standard properties on device management application policies.
    "microsoft.directory/deviceRegistrationPolicy/standard/read", # Read standard properties on device registration policies.
    "microsoft.directory/devices/registeredOwners/update", # Update registered owners of devices.
    "microsoft.directory/devices/registeredUsers/update", # Update registered users of devices.
    "microsoft.directory/devices/standard/read", # Read basic properties on devices.
    "microsoft.directory/users/appRoleAssignments/read", # Read application role assignments for users.
    "microsoft.directory/users/deviceForResourceAccount/read", # Read deviceForResourceAccount of users.
    "microsoft.directory/users/directReports/read", # Read the direct reports for users.
    "microsoft.directory/users/identities/read", # Read identities of users.
    "microsoft.directory/users/licenseDetails/read", # Read license details of users.
    "microsoft.directory/users/manager/read", # Read manager of users.
    "microsoft.directory/users/memberOf/read", # Read the group memberships of users.
    "microsoft.directory/users/ownedDevices/read", # Read owned devices of users.
    "microsoft.directory/users/registeredDevices/read", # Read registered devices of users.
    "microsoft.directory/users/scopedRoleMemberOf/read", # Read user's membership of an Azure AD role, that is scoped to an administrative unit.
    "microsoft.directory/users/standard/read" # Read basic properties on users.
)
$rolePermissions = @{'allowedResourceActions'= $allowedResourceAction}
 
# Create new custom admin role
$customAdmin = New-AzureADMSRoleDefinition -RolePermissions $rolePermissions -DisplayName $displayName -Description $description -TemplateId $templateId -IsEnabled $true