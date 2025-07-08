/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syPidtab

Class %SYSTEM.Security [ Abstract, System = 4 ]
{

/// Add the extra roles associated with the named application
ClassMethod AddRoles(ApplicationName As %String, Hash As %String = "") As %Status
{
}

/// Audit a user-level event.  If auditing is enabled for user level events, generate an audit record
/// with the user-specified information.<br>
/// Source - Source of the Audit event<br>
/// Type - Type of the Audit event<br>
/// Name - Name of the Audit event<br>
/// EventData - Data logged by the event. Maximum size of 3632952 bytes. Truncated if longer.<br>
/// Description - Description of the audit event. Maximum size of 128 bytes. Truncated if longer.<br>
ClassMethod Audit(Source As %String, Type As %String, Name As %String, EventData As %String, Description As %String) As %Status [ Abstract ]
{
}

/// Audit a system-level event.<br>
/// This method functions exactly like the Audit method, but avoids the overhead of looking up the
/// Audit Index using the Source, Type, and Name.<br> 
/// AuditIndex - Audit event number defined in %syAudit.<br>
/// EventData - Data logged by the event. Maximum size of 3632952 bytes. Truncated if longer.<br>
/// Description - Description of the audit event. Maximum size of 128 bytes. Truncated if longer.<br>
ClassMethod AuditID(AuditIndex As %Integer, EventData As %String, Description As %String) As %Boolean [ Abstract, Internal ]
{
}

/// Change password for a user.<br>
/// Parameters:<br>
/// Username - Name of the User to change<br>
/// NewPassword - New password to set<br>
/// OldPassword - Old Password to validate against<br>
/// Return Value: <br>
/// 0 - Failure<br>
/// 1 - Password changed<br>
/// On failure, an error code is returned in Status.<br>
/// If the old password is not passed as a parameter, then the password will be changed
/// to the NewPassword parameter, providing the following:<br><br>
/// The calling process has Write permission on the resource that protects the 
/// IRISSYS database or the calling routine is stored in the system database.<br>
/// If you are trying to change the password of a user who was created either through Delegated
/// authentication or through LDAP authentication, you will need to update the 
/// ChangePassword^ZAUTHENTICATE routine on your system. See the ZAUTHENTICATE routine in the
/// SAMPLES namespace for documentation.
ClassMethod ChangePassword(Username As %String, NewPassword As %String, OldPassword As %String, ByRef Status As %Status) As %Boolean
{
}

/// Determine if a specified privilege is held on a specified resource.
/// <br>
/// If called as $System.Security.Check(resource)
/// <br>
/// it returns the privileges held on that resource as a comma-separated
/// list.  For example,
/// <br>
/// $System.Security.Check("%DB_IRISTEMP") => "READ,WRITE"
/// <br><br>
/// If called as $System.Security.Check(resource,privilege) it returns 1 or
/// 0 depending on whether the specified privilege is held.  For example,
/// <br>
/// $System.Security.Check("%Development","USE") => 1
/// <br>
/// Note: If the process holds the %All role, then the method always returns "READ,WRITE,USE" for the 1-argument form
/// and 1 for the 2-argument form.<br>
/// 
ClassMethod Check(ResourceName As %String, Permissions As %String) As %RawString [ Abstract ]
{
}

/// Determine if a specified privilege is held on a specified resource for a set of roles.
/// <br>
/// If called as $System.Security.CheckRolesPermission(Roles,Resource)
/// <br>
/// it returns the privileges held on that resource as a comma-separated
/// list. For example,
/// <br>
/// $System.Security.CheckRolesPermission("%Manager,%Operator","%DB_IRISSYS") => "READ,WRITE"
/// <br><br>
/// If called as $System.Security.CheckRolesPermission(Roles,Resource,Privilege) it returns 1 or
/// 0 depending on whether the specified privilege is held.  For example,
/// <br>
/// $System.Security.CheckRolesPermission("%Manager","%Admin_Secure","USE") => 1
/// <br>
/// The method will take the list of roles passed to this method, and for each role in the list will determine
/// if any additional roles are granted by this role. If so, it also adds this role to the list. Once the entire set of
/// roles is calculated, the list of resources and permissions which the list of roles contains is calculated. Finally,
/// any PUBLIC resources are also added to the list of resources and permission. The resource name is then checked against
/// this list to determine the return value for the method.<br>
/// Note: If one of the roles being checked is %All, then the method always returns "READ,WRITE,USE" for the 2-argument form
/// and 1 for the 3-argument form<br>
/// If the Role does not exist, or an error occurs, then the method will return "" for the 2-argument form
/// and 0 for the 3-argument form.<br>
/// %objlasterror - Set with %Status code on error<br>
ClassMethod CheckRolesPermission(Roles As %String, ResourceName As %String, Permissions As %String) As %String
{
}

/// Determine if a specified privilege is held on a specified resource for a specific Username.
/// <br>
/// If called as $System.Security.CheckUserPermission(Username,Resource)
/// <br>
/// it returns the privileges held on that resource as a comma-separated
/// list. For example,
/// <br>
/// $System.Security.CheckUserPermission("Admin","%DB_IRISSYS") => "READ,WRITE"
/// <br><br>
/// If called as $System.Security.CheckUserPermission(Username,Resource,Privilege) it returns 1 or
/// 0 depending on whether the specified privilege is held.  For example,
/// <br>
/// $System.Security.CheckUserPermission("Operator","%Admin_Secure","USE") => 0
/// <br>
/// The method will take the Username passed to this method, and retrieve the list of roles the user is granted.
/// For each role in this list, it will determine 
/// if any additional roles are granted by this role. If so, it also adds this role to the list. Once the entire set of
/// roles is calculated, the list of resources and permissions which the list of roles contains is calculated. Finally,
/// any PUBLIC resources are also added to the list of resources and permission. The resource name is then checked against
/// this list to determine the return value for the method.<br>
/// Note: If the Username holds the %All role, then the method always returns "READ,WRITE,USE" for the 2-argument form
/// and 1 for the 3-argument form<br>
/// If the User does not exist, or an error occurs, then the method returns "" for the 2-argument form
/// and 0 for the 3-argument form<br>
/// If Username is not = $username, you must have %Admin_Secure:USE privilege to return the privilege for the specified user.<br>
/// %objlasterror - Set with %Status code on error<br>
ClassMethod CheckUserPermission(Username As %String, ResourceName As %String, Permissions As %String) As %String
{
}

/// Validate a password against system password policy.<br>
/// Password - Password to validate against the system password policy<br>
/// Username - (Optional) Username to use to validate against user defined password policy<br>
ClassMethod ValidatePassword(Password As %String, Username As %String = "User") As %Status
{
}

/// Log in a user given a valid username and password.<br>
/// Parameters:<br>
/// Username - Name of the user to log in as<br>
/// Password - Password of user to log in (optional)<br>
/// Return Value: <br>
/// 0 - Failure<br>
/// 1 - Success, user logged in<br>
/// If the password is not passed as a parameter (1 argument form), 
/// then the user will be logged in if
/// the calling process has Write permission on the resource that protects the 
/// IRISSYS database or the calling routine is stored in the system database.<br><br>
/// When the password is passed in as the second parameter (2 argument form), the 
/// method requires that the user has the %Service_Login:USE privilege.<br>
ClassMethod Login(Username As %String, Password As %String) As %Boolean
{
}

/// Return the permissions the process has for a global.<br>
/// This method will follow the mapping of where the global and subscript are actually
/// mapped to to find out the access to it.<br> If the database where it maps to is read-only,
/// then the method can only return "READ" or "".<br>
/// Parameters:<br>
/// Namespace - Namespace where the global exists. The namespace specified may either be a real namespace,
/// or an implied namespace in the format ^system^directory.<br>
/// Global - Name of the global. If not specified or "", then
/// the method returns the permissions for the default global database of the namespace.<br>
/// Subscripts - Fully specified subscript including "()". <br>
/// Mount - Default = 1 - 1=If the database is not mounted, mount it before checking. Subsequent
/// permission checks may be faster.<br>0 = Do not mount the database if it is not mounted.<br>
/// Return Values:<br>
/// Comma delimited list of permissions the process has on the global,
/// or "" for no access/invalid parameters.<br>
/// e.g. READ,WRITE<br>
/// In the case where an ECP database is not mounted, the return value may be "UNKNOWN"<br>
/// Examples:<br>
/// Check the access on the global ^GLOBALNAME("Subscript1")<br>
/// S x=$SYSTEM.Security.GetGlobalPermission("USER","GLOBALNAME","(""Subscript1"")")<br>
/// Check the access on the global ^ABC("Subscript1",2)<br>
/// S x=$SYSTEM.Security.GetGlobalPermission("USER","GLOBALNAME","(""Subscript1"",2)")<br>
ClassMethod GetGlobalPermission(Namespace As %String = "", Global As %String = "", Subscript As %String, Mount As %Boolean = 1) As %String
{
}

/// Checks if the caller has the permissions requested on the specified global.<br>
/// This method follows the mappings for the namespace and determines if you have 
/// the permissions requested on the specified global.<br>
/// Parameters:<br>
/// Permissions - comma separated list of permissions. Can be any combination of
/// "READ","R","WRITE", or "W".<br>
/// Namespace - Namespace where the global exists. The namespace specified may either be a real namespace,
/// or an implied namespace in the format ^system^directory.<br>
/// Global - Name of the global. 
/// Subscripts - Fully specified subscript including "()". <br>
/// Mount - Default = 1 - 1=If the database is not mounted, mount it before checking. Subsequent
/// permission checks may be faster.<br>0 = Do not mount the database if it is not mounted.<br>
/// Return Values:<br>
/// Comma delimited list of permissions the process has on the global,
/// or "" for no access/invalid parameters.<br>
/// e.g. READ,WRITE<br>
/// In the case where an ECP database is not mounted, and the mount flag is not specified, 
/// the return value may be "UNKNOWN"<br>
/// Examples:<br>
/// Check for READ access on the global ^GLOBALNAME("Subscript1")<br>
/// S x=$SYSTEM.Security.GlobalPermissionCheck("READ","USER","GLOBALNAME","(""Subscript1"")")<br>
/// Check READ and WRITE access on the global ^ABC("Subscript1",2)<br>
/// S x=$SYSTEM.Security.GlobalPermissionCheck("READ,WRITE","USER","GLOBALNAME","(""Subscript1"",2)")<br>
ClassMethod GlobalPermissionCheck(Permissions As %String, Namespace As %String = "", Global As %String = "", Subscript As %String, Mount As %Boolean = 1) As %Boolean
{
}

/// Return the permissions the process has for a routine.<br>
/// This method will follow the mapping of where the routine is
/// mapped to to find out the access to it.<br> If the database where it maps to is read-only,
/// then the method can only return "READ" or "".<br>
/// Parameters:<br>
/// Namespace - Namespace where the routine exists. The namespace specified may either be a real namespace,
/// or an implied namespace in the format ^system^directory.<br>
/// Routine - Name of the routine. If not specified or "", then
/// the method returns the permissions for the default routine database of the namespace.<br>
/// Mount - Default = 1 - 1=If the database is not mounted, mount it before checking. Subsequent
/// permission checks may be faster.<br>0 = Do not mount the database if it is not mounted.<br>
/// Return Values:<br>
/// Comma delimited list of permissions the process has on the routine,
/// or "" for no access/invalid parameters.<br>
/// e.g. READ,WRITE<br>
/// In the case where an ECP database is not mounted, and the mount flag is not specified, 
/// the return value may be "UNKNOWN"<br>
/// Examples:<br>
/// Check the access on the routine ^ROUTINENAME<br>
/// S x=$SYSTEM.Security.GetRoutinePermission("USER","ROUTINENAME")<br>
/// Check the access for the default routine database for the namespace<br>
/// S x=$SYSTEM.Security.GetRoutinePermission("USER")<br>
ClassMethod GetRoutinePermission(Namespace As %String = "", Routine As %String = "", Mount As %Boolean = 1) As %String
{
}

/// Checks if the caller has the permissions requested on the specified routine.<br>
/// This method follows the mappings for the namespace and determines if you have 
/// the permissions requested on the specified routine.<br>
/// Parameters:<br>
/// Namespace - Namespace where the routine exists. The namespace specified may either be a real namespace,
/// or an implied namespace in the format ^system^directory.<br>
/// Routine - Name of the routine. If not specified or "", then
/// the method returns the permissions for the default routine database of the namespace.<br>
/// Mount - Default = 1 - 1=If the database is not mounted, mount it before checking. Subsequent
/// permission checks may be faster.<br>0 = Do not mount the database if it is not mounted.<br>
/// Return Values:<br>
/// Comma delimited list of permissions the process has on the routine,
/// or "" for no access/invalid parameters.<br>
/// e.g. READ,WRITE<br>
/// In the case where an ECP database is not mounted, the return value may be "UNKNOWN"<br>
/// Examples:<br>
/// Check the access on the routine ^ROUTINENAME<br>
/// S x=$SYSTEM.Security.RoutinePermissionCheck("USER","ROUTINENAME")<br>
/// Check the access for the default routine database for the namespace<br>
/// S x=$SYSTEM.Security.RoutinePermissionCheck("USER")<br>
ClassMethod RoutinePermissionCheck(Permissions As %String, Namespace As %String = "", Routine As %String = "", Mount As %Boolean = 1) As %Boolean
{
}

/// Given a set of roles, recurse through them for the entire set of roles which would be granted.<br>
/// When a role is granted to a process, the role itself may grant another role. This method takes a comma delimited
/// set of roles as input, and returns the comma delimited entire set of roles which would be granted to the process.<br>
/// Parameters:<br>
/// Roles - Comma delimited list of roles to recurse.<br>
/// Return value:<br>
/// RecursedRoles - Comma delimited list of recursed roles.<br>
/// You must have %Admin_Secure:USE privilege to call this method.<br>
ClassMethod GetRecursedRoleSet(Roles As %String, ByRef RecursedRoles As %String) As %Status
{
}

/// Given a Username, return the entire set of roles which would be granted if they logged in.<br>
/// When a role is granted to a process, the role itself may grant another role. This method takes a username 
/// as input, and returns the comma delimited entire set of roles which would be granted to the user if they logged in.<br>
/// Parameters:<br>
/// Username - Username to calculate recursed role set for.<br>
/// Return value:<br>
/// RecursedRoles - Comma delimited list of recursed roles.<br>
/// If not your own username, you must have %Admin_Secure:USE privilege<br>
ClassMethod GetUserRecursedRoleSet(Username As %String, ByRef RecursedRoles As %String) As %Status
{
}

/// Returns 0/1 if the resource exists
ClassMethod ResourceExists(Resource As %String) As %Boolean [ Internal ]
{
}

/// Escalate the user's CSP session to the given escalation role. This role must be one of the current user's configured
/// EscalationRoles. This method should not be used directly, instead Applications should call: <br>
/// <example>Do %session.EscalateLogin(Role,Password)</example>
ClassMethod CSPEscalateLogin(RoleName As %String, Password As %String) As %Status [ Internal ]
{
}

/// Escalate the user's login to the given escalation role. This role must be one of the current user's configured
/// EscalationRoles.
/// <ul>
/// <li><b>RoleName</b></li> - specifies the escalation role to assume
/// <li><b>Password</b></li> - the user's password
/// </ul>
/// Both parameters are optional; if absent the user will be prompted for their values. This method must be called from a
/// foreground process. 
ClassMethod EscalateLogin(RoleName As %String, Password As %String) As %Status
{
}

}
