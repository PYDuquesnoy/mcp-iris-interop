/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// This class defines a task that can be executed by the Task Manager.
/// To create a new task, create a subclass and override the OnTask method.<br>
/// All public properties whose name does not start with a "%" are treated
/// as user-configurable "settings" for this task.
Class %SYS.Task.Definition Extends %RegisteredObject [ System = 4 ]
{

Parameter PROPERTYVALIDATION = 2;

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// This defines the user-visible name of this task.
/// It is defined in the subclasses.
Parameter TaskName As STRING;

/// This specifies a security resource and optional permission. Access to the resource
/// will be required to create, modify or run a task of this type. 
/// The format is "<resource>:<permission>". If <permission> is ommited, "USE" is implied.
/// Note that this parameter cannot be overridden using the COSEXPRESSION parameter type.
Parameter RESOURCE As STRING;

Property %RunDate As %Date;

Property %RunTime As %Time;

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "Settings" for the task, and then
/// invokes this method to execute the task.<br>
/// In order to execute a real task, override this method in a subclass.
Method OnTask() As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Return a serialized list of user-defined Property values for an instance of this Task as a $List.
/// This serialized list is stored in %SYS.Task.Settings for the scheduled Task and used by
/// the Task Manager to set the Properties before OnTask() is run.<br>
/// The serialized state is of the form: $LB(name,val,name,val)
Method GetSettings() As %List [ CodeMode = objectgenerator, Final ]
{
	Do %code.WriteLine(" Set tState = """"")

	// find list of "settings"
	For n = 1:1:%compiledclass.Properties.Count() {
		Set pdef = %compiledclass.Properties.GetAt(n)
		If (pdef.Private || ($E(pdef.Name,1,1) = "%")) continue
		// JMD: removed call to IsValid as it made no sense here!
		If pdef.Collection]"" {
			Do %code.WriteLine(" Set tColState=""""")
			Do %code.WriteLine(" Set key="""" For  Set value=.."_pdef.Name_".GetNext(.key) quit:key=""""  Set tColState = tColState _ $LB(key,value)")
			Do %code.WriteLine(" Set tState = tState _ $LB("""_pdef.Name_""",tColState)")
		} Else {
			Do %code.WriteLine(" Set tState = tState _ $LB("""_pdef.Name_""",.."_pdef.Name_")")
		}
 	}

	Do %code.WriteLine(" Quit tState")
	
	Quit $$$OK
}

/// Called by the Task Manager prior to running OnTask() to set all Property values.<br>
/// The 'pState' value is the serialized list of Property values stored in the scheduled
/// Task in %SYS.Task.Settings.
Method SetSettings(pState As %List) As %Status [ Final ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Do ..GetCollectionType("",.tCollection)
	// apply serial state to this object
	For n=1:2:$LL(pState) {
		Set tName = $LG(pState,n)
		Set tVal = $LG(pState,n+1)
		Set tMethod=$g(tCollection(tName))
		Set tMethod=$S(tMethod="array":"SetAt",tMethod="list":"InsertAt",1:"")
		If tMethod = "" Set $property($this,tName) = tVal continue
		Set tCollectionVar = $property($this,tName)
		Do tCollectionVar.Clear()
		For idx=1:2:$ll(tVal) {
			Set tNode=$li(tVal,idx)
			Set tColVal=$li(tVal,idx+1)
			Do $method(tCollectionVar,tMethod,tColVal,tNode)
		}
	}

Done
	Quit tSC

Trap
	Set $ZT=""
	Goto Done
}

/// This callback is called when this form is submitted.
/// <var>pID</var> is the ID value associated with the form.
/// The default implementation will perform a Save if the AutoForm is a persistent object.<br>
/// <var>pSubmit</var> is the name of the submit button (i.e., $AUTOFORM_SAVE).
Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status [ CodeMode = objectgenerator, Final ]
{
	// see if submitted values are valid
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Set tError = """"")
	
	Do %code.WriteLine(" Do {")

	// find list of "settings"
	For n = 1:1:%compiledclass.Properties.Count() {
		Set pdef = %compiledclass.Properties.GetAt(n)
		If ('pdef.Private && ($E(pdef.Name,1,1) '= "%")) {
			Do %code.WriteLine(" Set tValid = 1")
			If (pdef.Required) {
				Do %code.WriteLine(" Set:(.."_pdef.Name_"="""") tSC = $$$ERROR($$$PropertyRequired,"""_pdef.Name_""")")
			}
			Do %code.WriteLine(" Set:(.."_pdef.Name_"'="""") tValid =.."_pdef.Name_"IsValid(.."_pdef.Name_")")
			Do %code.WriteLine(" If ('tValid) {")
				Do %code.WriteLine(" Set tSC = $$$ERROR($$$DatatypeValidationFailed,"""_pdef.Name_""",.."_pdef.Name_")")
				Do %code.WriteLine(" Quit")
			Do %code.WriteLine(" }")
		}
	}
	Do %code.WriteLine(" } While(0)")

	Do %code.WriteLine(" Quit tSC")
	
	Quit $$$OK
}

/// Returns the localized name of this task.
ClassMethod GetTaskName() As %String [ CodeMode = objectgenerator, Final ]
{
	// Make sure task name gets a $$$Text macro wrapped around it
	// so that it is localized.
	// User-defined task classes must make sure to set DOMAIN if they
	// want to use localization.

	Set TASKNAME = $G(%parameter("TaskName"))
	If (TASKNAME = "") {
		// no task name defined: use class name and do not localize!
		Do %code.WriteLine(" Quit """_%class.Name_"""")
		Quit $$$OK
	}

	// Test if we need to localize:
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.Name [ "%SYS.Task") {
		// a built-in task
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		// user-defined
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%Utility")
	}

	// now generate code to get name
	If (tLocalize) {
		Do %code.WriteLine(" Quit $$$Text("_$$$quote($G(%parameter("TaskName")))_")")
	}
	Else {
		Do %code.WriteLine(" Quit ..#TaskName")
	}
	Quit $$$OK
}

ClassMethod GetPropertyName(propertyName As %String) As %String [ CodeMode = objectgenerator, Final ]
{
	// Test if we need to localize:
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.Name [ "%SYS.Task") {
		// a built-in task
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		// user-defined
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%Utility")
	}
	If 'tLocalize {
		Do %code.WriteLine(" Quit propertyName")
		Quit $$$OK
	}
	Do %code.WriteLine(" Quit:propertyName="""" """"")
	// find list of "settings"
	For n = 1:1:%compiledclass.Properties.Count() {
		Set pdef = %compiledclass.Properties.GetAt(n)
		If (pdef.Private || ($E(pdef.Name,1,1) = "%")) continue
		Do %code.WriteLine(" Set array("""_pdef.Name_""")=$$$Text("""_pdef.Name_""")")
 	}

	Do %code.WriteLine(" Quit $G(array(propertyName))")
	Quit $$$OK
}

/// Return a collection type for a property. By passing reference tCollection we can get all properties which are collections.
ClassMethod GetCollectionType(propertyName As %String, ByRef tCollection As %String) As %String [ CodeMode = objectgenerator, Final ]
{
	// find list of "settings"
	For n = 1:1:%compiledclass.Properties.Count() {
		Set pdef = %compiledclass.Properties.GetAt(n)
		If pdef.Collection]"" Do %code.WriteLine(" Set tCollection("""_pdef.Name_""")="""_pdef.Collection_"""")
 	}
	Do %code.WriteLine(" Quit:propertyName="""" """"")
	Do %code.WriteLine(" Quit $G(tCollection(propertyName))")
	Quit $$$OK
}

/// This method checks if the current process has the permission defined by the RESOURCE parameter for the given Task class. This will
/// return 1 if the process has permission, or if no RESOURCE is defined. It will return 0 otherwise. 
ClassMethod CheckPermission(taskClass As %String, namespace As %String, Output sc As %Status) As %Boolean
{
	Set allowed=1, sc=$$$OK
	Try {
		Set parameter = ..GetResource(taskClass,namespace)
		If parameter'="" {
			Set resource = $piece(parameter,":",1)
			Set permission = $piece(parameter,":",2)
			If permission="" Set permission = "USE"
			If '$System.Security.Check(resource,permission) {
				Set allowed = 0
				Set sc = $$$ERROR($$$TASKModifyNotAuthorized,resource_":"_permission,taskClass)	
			}
		}
	} Catch e {
		Set sc = e.AsStatus()
		Set allowed = 0
	}
	Return allowed
}

ClassMethod GetResource(taskClass As %String, namespace As %String) As %String [ Final, Private ]
{
	$$$AddAllRoleTemporary
	If $namespace'=namespace {
		New $namespace
		Set $namespace = namespace
	}
	return $$$comMemberKeyGet(taskClass, $$$cCLASSparameter,"RESOURCE", $$$cPARAMdefault)
}

}
