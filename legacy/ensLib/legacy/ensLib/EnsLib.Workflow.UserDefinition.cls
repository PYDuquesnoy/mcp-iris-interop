/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// Defines a workflow user.<br>
/// Typically the user name matches a system user name but
/// this is not required.<br>
/// Workflow users that are not registered system users
/// will not be able to log into the Workflow portal and
/// check the status of their worklist.
Class EnsLib.Workflow.UserDefinition Extends (%Persistent, %XML.Adaptor, %CSP.Util.AutoForm) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Index ID On Name [ IdKey ];

/// The user name of this Workflow user.
Property Name As %String(CAPTION = "@Ensemble:Name@Name", MAXLEN = 128, XMLNAME = "name", XMLPROJECTION = "attribute") [ Required ];

/// (Optional) Full name (i.e., "Presley,Elvis") for User.
Property FullName As %String(CAPTION = "@EnsColumns:FullName@Full Name", MAXLEN = 128, XMLNAME = "fullname", XMLPROJECTION = "attribute");

/// Indicates if this user is currently active.
Property IsActive As %Boolean(CAPTION = "@EnsColumns:IsActive@Is Active", XMLNAME = "isActive", XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Returns a <class>%ResultSet</class> of all roles for this user.
/// The returned result set is executed and ready to be read from.
Method GetRoleSet() As %ResultSet
{
	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "EnsLib.Workflow.Engine"
	Set tRS.QueryName = "RolesForUser"
	Set tSC = tRS.Execute(..Name)
	If $$$ISERR(tSC) Quit ""
	
	Quit tRS
}

/// Create a Workflow user
ClassMethod CreateUser(pUserName As %String, pFullName As %String = "") As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		Set tUser = ##class(UserDefinition).%New()
		Set tUser.Name = pUserName
		Set tUser.FullName = pFullName
		Set tSC = tUser.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Delete a Workflow user
ClassMethod DeleteUser(pUserName As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		// Delete the user by username
		Set tSC = ##class(UserDefinition).%DeleteId(pUserName)
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
		&SQL(DELETE FROM UserDefinition WHERE Name = :id)
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

ClassMethod DrawHTMLFormFields(pObj As %RegisteredObject) As %Status
{
	// !!! override until IDKEY is handled by system

	Set tVal = $select(pObj="":"",1:(pObj.NameLogicalToDisplay(pObj.Name)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp;  Name:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><INPUT ",$select(pObj.%Id()="":"",1:"readonly")," CLASS=""AutoForm"" TYPE=""TEXT"" NAME=""Name"" SIZE=""40"" VALUE='"_($ZCVT(tVal,"O","HTML"))_"'>",!
	Write "</TD>",!
	Write "</TR>",!
	Set tVal = $select(pObj="":"",1:(pObj.FullNameLogicalToDisplay(pObj.Name)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp; Full Name:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><INPUT CLASS=""AutoForm"" TYPE=""TEXT"" NAME=""Name"" SIZE=""40"" VALUE='"_($ZCVT(tVal,"O","HTML"))_"'>",!
	Write "</TD>",!
	Write "</TR>",!
	Set tVal = $select(pObj="":"",1:(pObj.IsActiveLogicalToDisplay(pObj.IsActive)))
	Write "<TR CLASS=""AutoForm"" VALIGN=""CENTER"">",!
	Write "<TD CLASS=""AutoFormCaption"" NOWRAP>&nbsp;  IsActive:</TD>",!
	Write "<TD CLASS=""AutoFormControl"" NOWRAP><INPUT CLASS=""AutoForm"" TYPE=""checkbox"" NAME=""IsActive""  "_($S(tVal:"CHECKED",1:""))_">",!
	Write "</TD>",!
	Write "</TR>",!

	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	// Notify Workflow Engine that this Object is being deleted
	Do ##class(Engine).%OnUserChange($$$oidPrimary(oid),$$$WfUserDeleted)
	Quit $$$OK
}

/// SQL Delete Trigger
Trigger SQLDelete [ Event = DELETE ]
{
	Do ##class(Engine).%OnUserChange({Name},$$$WfUserDeleted)
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private ]
{
	If ('insert && '..IsActive) {
		// user is inactive, notify
		Do ##class(Engine).%OnUserChange(..Name,$$$WfUserInactivated)
	}
	ElseIf ('insert && ..IsActive) {
		Set tWasActive = ..IsActiveGetStored(..%Id())
		// inactive user activated, notify
		If 'tWasActive Do ##class(Engine).%OnUserChange(..Name,$$$WfUserActivated)
	}

	Quit $$$OK
}

/// SQL Update Trigger
Trigger SQLUpdate [ Event = UPDATE ]
{
	If ({IsActive} = 0) {
		Do ##class(Engine).%OnUserChange({Name},$$$WfUserInactivated)
	}
	ElseIf ({IsActive} = 1)&&({IsActive*O} = 0) {
		Do ##class(Engine).%OnUserChange({Name},$$$WfUserActivated)
	}
}

Storage Default
{
<Data name="UserDefinitionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>IsActive</Value>
</Value>
<Value name="3">
<Value>FullName</Value>
</Value>
</Data>
<DataLocation>^EnsLib.W.UserDefinitionD</DataLocation>
<DefaultData>UserDefinitionDefaultData</DefaultData>
<IdLocation>^EnsLib.W.UserDefinitionD</IdLocation>
<IndexLocation>^EnsLib.W.UserDefinitionI</IndexLocation>
<StreamLocation>^EnsLib.W.UserDefinitionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
