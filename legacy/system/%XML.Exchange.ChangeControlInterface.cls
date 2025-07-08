/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Configuration Management Change Control Interface
/// This provides the interface may be used to communicate with the change control class.
Class %XML.Exchange.ChangeControlInterface [ System = 4 ]
{

/// Return the name of the change control class we should use for this
/// namespace. If we return "" then change control is not enabled in
/// this namespace.
ClassMethod ChangeControlClassGet() As %String [ CodeMode = expression, Final, NotInheritable ]
{
$select($get(^SYS("ChangeControlClass"))="":$get(^%SYS("ChangeControlClass",$namespace),$get(^%SYS("ChangeControlClass"))),1:^SYS("ChangeControlClass"))
}

/// Set the name of the change control class we should use for this
/// namespace. Set the value to "" to disable change control in this
/// namespace.
ClassMethod ChangeControlClassSet(val As %String = "") As %Status [ Final, NotInheritable ]
{
	If $get(^SYS("ChangeControlLock")) Quit $$$ERROR($$$GeneralError, "ChangeControlLock::"_..ChangeControlClassGet())
	Set $ztrap="setTrap"
	If val'="" {
		Set extends=$zobjclassmethod(val,"%Extends","%XML.Exchange.ChangeControlBase")
		If 'extends Quit $$$ERROR($$$GeneralError, "InvalidChangeControlClass::"_val)
	}
	Set ^SYS("ChangeControlClass")=val
	Quit $$$OK
setTrap	Set $ztrap=""
	Quit $$$ERROR($$$GeneralError, "InvalidChangeControlClass::"_val)
}

/// Creates an instance of the change control class stored in the local variable
/// '%ChangeControl' this is used by the load/save functions to import
/// export the routine to the external change control class.<p>
/// It also returns <var>Created</var> which is true if the change control class was created
/// correctly. 
ClassMethod ChangeControlCreate(Name As %String, Password As %String, ByRef Created As %Boolean, ByRef Flags As %Integer, Output Username As %String, Version As %String = "", ByRef Reload As %String) As %Status [ Final, NotInheritable ]
{
	Set Username=$username,Reload=0

	Set $ztrap="Trap"
	Set %ChangeControl=""
	Set Created=0,Flags=0
	Set class=..ChangeControlClassGet()
	If class="" Quit $$$OK
	New %objlasterror
	Set %ChangeControl=$zobjclassmethod(class,"%New",$ListBuild(Name,Password))
	If %ChangeControl="" Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$GeneralError, "ChangeControlClass::"_class))
	Set Created=1,Flags=15
	Quit $$$OK
Trap	Set $ztrap=""
	If $zerror["<CLASS DOES NOT EXIST>" Quit $$$ERROR($$$GeneralError, "ChangeControlClass::"_class)
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Return information about this entity. The <var>Reload</var> parameter is returned by this
/// function and is true if the status check changed the item and so may need to be reloaded.
ClassMethod GetStatus(InternalName As %String, ByRef IsInChangeControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String, ByRef Reload As %Boolean) As %Status
{
	If '$IsObject($Get(%ChangeControl)) {
		#; Reload not implemented.
		Set Reload = 0
		Set tmp=%ChangeControl New %ChangeControl Set rc=tmp.GetStatus(InternalName,.IsInChangeControl,.Editable,.IsCheckedOut,.UserCheckedOut)
		Quit rc
	} Else {
		Quit $$$ERROR($$$GeneralError, "ChangeControlNotLoggedIn")
	}
}

/// Returns the external name of this file
ClassMethod ExternalName(InternalName As %String) As %String
{
	If $isobject($get(%ChangeControl)) {
		Set tmp=%ChangeControl New %ChangeControl
		Quit tmp.ExternalName(InternalName)
	} Else {
		Quit ""
	}
}

Query ExtensionClasses() As %Query(ROWSPEC = "Name:%String,Description:%String") [ SqlProc ]
{
}

ClassMethod ExtensionClassesExecute(ByRef qHandle As %Binary) As %Status
{
	Set sc=$$GetAllDerivedClasses^%occLibrary("%XML.Exchange.ChangeControlBase",.classes)
	If $$$ISERR(sc) Quit sc
	Set idx=$increment(^IRIS.Temp)
	#; Make sure this is cleaned up if the process crashes
	$$$AddTempNode(^IRIS.Temp(idx))
	Merge ^IRIS.Temp(idx)=classes
	Set qHandle=$listbuild(idx,"")
	Quit $$$OK
}

ClassMethod ExtensionClassesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set idx=$listget(qHandle),index=$listget(qHandle,2)
	Set Row="",AtEnd=0
	If idx="" Set AtEnd=1 Quit $$$OK
	Set index=$order(^IRIS.Temp(idx,index))
	If index="" Set AtEnd=1 Quit $$$OK
	Set desc=$zconvert($translate($piece($$$comClassKeyGet(index,$$$cCLASSdescription),$char(10)),$char(13)),"I","HTML")
	Set Row=$listbuild(index,desc),$list(qHandle,2)=index
	Quit $$$OK
}

ClassMethod ExtensionClassesClose(ByRef qHandle As %Binary) As %Status
{
	Set idx=$listget(qHandle)
	If idx'="" Kill ^IRIS.Temp(idx) $$$RemoveTempNode(^IRIS.Temp(idx))
	Quit $$$OK
}

}
