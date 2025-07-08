/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL Catalog Queries - Privileged
Class %Library.SQLCatalogPriv [ Not Hidden, System = 3 ]
{

Parameter SQLPUBLICSECURITY = "{""SQLCatalogPriv_SQLUsers"":""E""}";

/// <pre>
/// Get a list of all SQL Roles.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLRoles Procedure
/// 	%SQLCatalogPriv_SQLRoles()
/// 		Takes no parameters
/// 		Returns all SQL Roles defined
/// 		ROWSPEC = ROLE_NAME:%Library.String	- Name of the role
/// 			  DESCRIPTION:%Library.String	- Role's Desription
/// 			  CREATED_BY:%Library.String	- SQL User who created the Role
/// 			  ESCALATION_ONLY:%Library.Boolean - Can this role be assigned at login, or can it only be used for escalation?
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLRoles() As %Query(ROWSPEC = "ROLE_NAME:%Library.String,DESCRIPTION:%Library.String,CREATED_BY:%Library.String,ESCALATION_ONLY:%Library.Boolean") [ SqlProc ]
{
}

ClassMethod SQLRolesExecute(ByRef %q As %Binary) As %Status [ Internal ]
{
}

ClassMethod SQLRolesFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLRolesClose(%q As %Library.Binary) As %Library.Status [ Internal ]
{
}

/// <pre>
/// Get a list of Privileges granted to a Role
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLRolePrivleges Procedure
/// 	%SQLCatalogPriv_SQLRolePrivileges('rolename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a Role.
/// 		Returns all privileges granted to the role.
/// 		ROWSPEC = TYPE:%String			- TABLE or VIEW or PROCEDURE
/// 			  NAME:%String			- Name of the object with privs granted to the role
/// 			  PRIVILEGE:%String		- Privilege granted
/// 			  GRANTED_BY:%String		- SQL user name who granted the privilege
/// 			  GRANT_OPTION:%String		- 'Yes' or 'No', privilege granted with grant option
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLRolePrivileges(role As %String) As %Query(ROWSPEC = "TYPE:%String(MAXLEN=9):TYPE,NAME:%String(MAXLEN=128),PRIVILEGE:%String(MAXLEN=10),GRANTED_BY:%String,GRANT_OPTION:%String(MAXLEN=3)") [ SqlProc ]
{
}

ClassMethod SQLRolePrivilegesExecute(ByRef %q As %Binary, role As %String = "") As %Status [ Internal ]
{
}

ClassMethod SQLRolePrivilegesFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLRolePrivilegesClose(%q As %Library.Binary) As %Status [ Internal ]
{
}

/// <pre>
/// Get a list of all Users/Roles granted a Role.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
///   SQLRoleUser Procedure
/// 	%SQLCatalogPriv_SQLRoleUser('rolename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a Role.
/// 		Returns all SQL Users granted the role
/// 		ROWSPEC = NAME:%Library.String	- Name of the SQL user granted the role
/// 			  TYPE:%Library.String  - ROLE or USER, type of UID it is granted too
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLRoleUser(role As %String) As %Query(ROWSPEC = "NAME:%Library.String,USER:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLRoleUserExecute(ByRef %q As %Binary, role As %String = "") As %Status [ Internal ]
{
}

ClassMethod SQLRoleUserFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLRoleUserClose(%q As %Library.Binary) As %Status [ Internal ]
{
}

/// <pre>
/// Get a list of all Users.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLUsers Procedure
/// 	%SQLCatalogPriv_SQLUsers()
/// 		Takes no parameters
/// 		Returns a list of SQL users:
/// 		ROWSPEC = USERNAME:%Library.String    - Name of the SQL user
/// 			  DESCRIPTION:%Library.String - SQL User description
/// 			  ENABLED:%Library.String     - Yes/No: is user definition enabled?
/// 			  NAMESPACE:%Library.String   - User's Namespace
/// 			  ROUTINE:%Library.String     - Routine
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLUsers() As %Query(ROWSPEC = "USERNAME:%Library.String,DESCRIPTION:%Library.String,ENABLED:%Library.String,NAMESPACE:%Library.String,ROUTINE:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLUsersExecute(ByRef %q As %Binary) As %Status [ Internal ]
{
}

ClassMethod SQLUsersFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLUsersClose(%q As %Library.Binary) As %Status [ Internal ]
{
}

/// <pre>
/// If the user exists, return the username; otherwise nothing
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLUserExists Procedure
/// 	%SQLCatalogPriv_SQLUserExists('username')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of an SQL user.
/// 		Returns the SQL username if the user exists, otherwise nothing:
/// 		ROWSPEC = USER_NAME:%String	- Name of the SQL user
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLUserExists(user As %String) As %Query(ROWSPEC = "USER_NAME:%String") [ SqlProc ]
{
}

ClassMethod SQLUserExistsExecute(ByRef %q As %Binary, user As %String = "") As %Status [ Internal ]
{
}

ClassMethod SQLUserExistsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLUserExistsClose(%q As %Binary) As %Status [ Internal ]
{
}

/// <pre>
/// Get a list of Privileges granted to a SQL User
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLUserPrivs Procedure
/// 	%SQLCatalogPriv_SQLUserPrivs('username')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a SQL User.
/// 		Returns all privileges granted to the user.
/// 		ROWSPEC = TYPE:%Library.String		- TABLE, VIEW, STORED PROCEDURE
/// 			  NAME:%Library.String 		- Name of the item with privs granted to the user
/// 			  PRIVILEGE:%Library.String 	- Privilege granted
/// 			  GRANTED_BY:%Library.String	- SQL user name who granted the privilege
/// 			  GRANT_OPTION:%Library.String	- 'Yes' or 'No', privilege granted with grant option
/// 			  GRANTED_VIA:%Library.String   - Direct, SuperUser, Role, _PUBLIC - How was the user granted the priv
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLUserPrivs(user As %String) As %Query(ROWSPEC = "TYPE:%Library.String,NAME:%Library.String,PRIVILEGE:%Library.String(MAXLEN=10),GRANTED_BY:%Library.String,GRANT_OPTION:%Library.String(MAXLEN=3),GRANTED_VIA:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLUserPrivsExecute(ByRef %q As %Binary, user As %String = "") As %Status [ Internal ]
{
}

ClassMethod SQLUserPrivsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLUserPrivsClose(%q As %Library.Binary) As %Status [ Internal ]
{
}

/// <pre>
/// Get a list of all Roles granted to an SQL User.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLUserRole Procedure
/// 	%SQLCatalogPriv_SQLUserRole('username')
/// 		Takes 1 %Library.String/VARCHAR type parameter which is the name of a SQL user.
/// 		Returns all Roles granted to the user
/// 		ROWSPEC = ROLE_NAME:%Library.String	- Name of the role granted to the user
/// 			  ADMIN_OPTION:%Library.Boolean - 1/0 Role granted with Admin Option?
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLUserRole(user As %String) As %Query(ROWSPEC = "ROLE_NAME:%Library.String,ADMIN_OPTION:%Library.Boolean") [ SqlProc ]
{
}

ClassMethod SQLUserRoleExecute(ByRef %q As %Binary, user As %String = "") As %Status [ Internal ]
{
}

ClassMethod SQLUserRoleFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal ]
{
}

ClassMethod SQLUserRoleClose(%q As %Library.Binary) As %Status [ Internal ]
{
}

/// <pre>
/// Get all System Privileges granted to the user/role 'user'
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLUserSysPriv Procedure
/// 	%SQLCatalogPriv_SQLUserSysPrivs('username')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of an SQL User or Role.
/// 		Returns all system privileges granted to a user or role
/// 		ROWSPEC = PRIVILEGE:%Library.String	- Name of the system privilege granted
/// 			  ADMIN_OPTION:%Library.String	- 'Yes' or 'No' whether the privilege was granted with admin option
/// 			  GRANTED_VIA:%Library.String	- Direct, SuperUser, Role, _PUBLIC - How was the user granted the priv
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLUserSysPrivs(user As %String) As %Query(ROWSPEC = "PRIVILEGE:%String,ADMIN_OPTION:%String,GRANTED_VIA:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLUserSysPrivsExecute(ByRef %q As %Library.Binary, user As %Library.String = "") As %Library.Status [ Internal ]
{
}

ClassMethod SQLUserSysPrivsFetch(ByRef %q As %Library.Binary, ByRef Row As %Library.List, AtEnd As %Library.Integer) As %Library.Status [ Internal ]
{
}

ClassMethod SQLUserSysPrivsClose(ByRef %q As %Library.Binary) As %Library.Status [ Internal ]
{
}

}
