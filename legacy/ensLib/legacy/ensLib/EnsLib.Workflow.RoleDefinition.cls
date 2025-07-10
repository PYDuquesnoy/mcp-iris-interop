/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// Defines a workflow role and its members.
Class EnsLib.Workflow.RoleDefinition Extends (%Persistent, %XML.Adaptor, %CSP.Util.AutoForm) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Index ID On Name [ IdKey ];

/// The (unique) name of this role.
Property Name As %String(CAPTION = "@Ensemble:Name@Name", MAXLEN = 128, XMLNAME = "name", XMLPROJECTION = "attribute") [ Required ];

/// (Optional) Description for this role.
Property Description As %String(CAPTION = "@EnsColumns:Description@Description", MAXLEN = 2000, XMLNAME = "description", XMLPROJECTION = "element");

/// Defines the <i>capacity<i> of this Role.<br>
/// This value is used to report the number of active tasks assigned
/// to a Role as a percentage value.
Property Capacity As %Integer(CAPTION = "@EnsColumns:Capacity@Capacity", MINVAL = 1) [ InitialExpression = 100 ];

/// Returns a <class>%ResultSet</class> of all active users for this role.
/// The returned result set is executed and ready to be read from.
/// If <var>pTitle</var> is provided, filter results by Title.
Method GetUserSet(pTitle As %String = "") As %ResultSet
{
	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = $classname()
	If (pTitle = "") {
		Set tRS.QueryName = "ActiveUsersForRole"
		Set tSC = tRS.Execute(..Name)
	}
	Else {
		Set tRS.QueryName = "ActiveUsersForRoleByTitle"
		Set tSC = tRS.Execute(..Name, pTitle)
	}
	If $$$ISERR(tSC) Quit ""
	
	Quit tRS
}

/// Returns set of all Users for a given Role ordered by Ranking.
Query UsersForRole(pRoleName As %String = "") As %SQLQuery
{
SELECT UserName, Ranking, Title, UserName->IsActive As IsActive, User As CurrUser 
FROM RoleMembership
WHERE RoleName = :pRoleName
ORDER BY Ranking
}

/// Returns set of active Users for a given Role ordered by ranking
Query ActiveUsersForRole(pRoleName As %String = "") As %SQLQuery
{
SELECT UserName, Ranking, Title
FROM RoleMembership
WHERE RoleName = :pRoleName AND UserName->IsActive = 1
ORDER BY Ranking
}

/// Returns set of active Users for a given Role 
/// with a given title ordered by ranking.
Query ActiveUsersForRoleByTitle(pRoleName As %String = "", pTitle As %String = "") As %SQLQuery
{
SELECT UserName, Ranking, Title
FROM RoleMembership
WHERE RoleName = :pRoleName AND 
		Title = :pTitle AND
		UserName->IsActive = 1
ORDER BY Ranking
}

/// Returns set of all available Roles.
Query Roles() As %SQLQuery
{
SELECT R.Name As Name, 
	R.Description,
	R.Capacity,
	(SELECT COUNT(*) FROM RoleMembership WHERE RoleName = R.Name) As Users
FROM RoleDefinition R
ORDER BY R.Name
}

/// Create a Workflow role
ClassMethod CreateRole(pRoleName As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		Set tRole = ##class(RoleDefinition).%New()
		Set tRole.Name = pRoleName
		Set tSC = tRole.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// This callback is called when this form is submitted.
/// <var>pID</var> is the ID value associated with the form.
/// The default implementation will perform a Save if the AutoForm is a persistent object.<BR>
/// <var>pSubmit</var> is the name of the submit button (i.e., $AUTOFORM_SAVE).
Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
	If (pSubmit = "$AUTOFORM_DELETE") {
		// delete this role

		Set id = ..%Id()
		&SQL(DELETE FROM RoleDefinition WHERE Name = :id)
		Quit $$$OK
	}

	If (pSubmit = "$AUTOFORM_SAVE") {
		// save this object
		Set tSC = ..%Save()
		#; JMD269: workaround for error handling within frames
		If $$$ISERR(tSC) {
			Do $System.Status.DecomposeStatus(tSC,.tErr)
			Set ^IRIS.Temp.AutoFormError(%session.SessionId) = $G(tErr(1))
			Quit $$$OK
		}
	}
	
	Quit $$$OK
}

/// Add an additional user to the specified workflow role.
/// <var>pRoleName</var> is the name of the role.<br>
/// <var>pUserName</var> is the name of the user.<br>
/// <var>pRanking</var> is the optional rank of this user within the role.<br>
/// <var>pTitle</var> is the optional title of this user within the role.<br>
ClassMethod AddUserToRole(pRoleName As %String, pUserName As %String, pRanking As %Integer = 3, pTitle As %String = "") As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		Set tRole = ##class(RoleDefinition).%OpenId(pRoleName,-1,.tSC)
		If $$$ISERR(tSC) Quit

		Set tUser = ##class(UserDefinition).%OpenId(pUserName,-1,.tSC)
		If $$$ISERR(tSC) Quit
		
		// create association
		Set tAssoc = ##class(RoleMembership).%New()
		Set tAssoc.Role = tRole
		Set tAssoc.User = tUser
		Set tAssoc.Ranking = pRanking
		Set tAssoc.Title = pTitle

		Set tSC = tAssoc.%Save()
		If $$$ISERR(tSC) Quit
		
		// Notify Workflow Engine
		Set tSC = ##class(Engine).%OnRoleMembershipChange(pRoleName,$$$WfUserAddedToRole,pUserName)

	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Remove an existing user from the specified workflow role.
/// <var>pRoleName</var> is the name of the role.<br>
/// <var>pUserName</var> is the name of the user.<br>
ClassMethod RemoveUserFromRole(pRoleName As %String, pUserName As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		// Delete the role membership
		Set tSC = ##class(RoleMembership).IDDelete(pRoleName,pUserName)
		
		// Notify Workflow Engine
		Set tSC = ##class(Engine).%OnRoleMembershipChange(pRoleName,$$$WfUserRemovedFromRole,pUserName)

	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

ClassMethod DrawHTMLFormFields(pObj As %RegisteredObject) As %Status
{
	// !!! override until IDKEY is handled by system

	Set tVal = $select(pObj="":"",1:(pObj.NameLogicalToDisplay(pObj.Name)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp;Name:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><INPUT ",$select(pObj.%Id()="":"",1:"readonly")," CLASS=""AutoForm"" TYPE=""TEXT"" NAME=""Name"" SIZE=""40"" VALUE='"_($ZCVT(tVal,"O","HTML"))_"'>",!
	Write "</TD>",!
	Write "</TR>",!
	Set tVal = $select(pObj="":"",1:(pObj.CapacityLogicalToDisplay(pObj.Capacity)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp;  Capacity:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><INPUT CLASS=""AutoForm"" TYPE=""text"" NAME=""Capacity"" SIZE=""8"" VALUE='"_($ZCVT(tVal,"O","HTML"))_"'>",!
	Write "</TD>",!
	Write "</TR>",!
	Set tVal = $select(pObj="":"",1:(pObj.DescriptionLogicalToDisplay(pObj.Description)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp;Description:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><TEXTAREA CLASS=""AutoForm"" NAME=""Description"" COLS=""60"" ROWS=""5"">"_($ZCVT(tVal,"O","HTML"))_"</TEXTAREA>",!
	Write "</TD>",!
	Write "</TR>",!
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	// Notify Workflow Engine that this Object is being deleted
	Set tSC = ##class(Engine).%OnRoleChange($$$oidPrimary(oid),$$$WfRoleDeleted)
	Quit tSC
}

/// SQL Delete Trigger
Trigger SQLDelete [ Event = DELETE ]
{
	Do ##class(Engine).%OnRoleChange({Name},$$$WfRoleDeleted)
}

Storage Default
{
<Data name="RoleDefinitionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>Capacity</Value>
</Value>
</Data>
<DataLocation>^EnsLib.W.RoleDefinitionD</DataLocation>
<DefaultData>RoleDefinitionDefaultData</DefaultData>
<IdLocation>^EnsLib.W.RoleDefinitionD</IdLocation>
<IndexLocation>^EnsLib.W.RoleDefinitionI</IndexLocation>
<StreamLocation>^EnsLib.W.RoleDefinitionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
