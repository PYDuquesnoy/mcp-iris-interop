/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Configuration Management Change Control Base <br>
/// 
/// This class is the change control superclass.  It does nothing but provide interface for the real
/// extensibility classes to use. Subclass from this and implement the methods as required.
Class %XML.Exchange.ChangeControlBase Extends %RegisteredObject [ System = 4 ]
{

/// The username of this source control user.
Property Username As %Library.Username;

/// This just calls the <method>Login</method> to perform an initialisation.
/// Note that this is called automatically via the <class>%XML.Exchange.ChangeControlInterface</class>
/// class, do not call %New directly.
Method %OnNew(initval As %String) As %Status [ Final ]
{
	Set ..Username=$listget(initval)
	Quit ..Login($listget(initval),$listget(initval,2))
}

/// Call the <method>LogOut</method> method before the object closes.
Method %OnClose() As %Status
{
	Quit ..Logout()
}

/// Perform any login step here.
Method Login(Name As %String, Password As %String) As %Status
{
	Quit $$$OK
}

/// Perform any logout step here.
Method Logout() As %Status
{
	Quit $$$OK
}

/// This is called before the actual load of data to give the chance
/// to load the Exchange Item from an external format.
/// Note: This event is not fired prior to an update via SQL.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// This is called after the Exchange Item is loaded.
Method OnAfterLoad(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Called before the Exchange Item is saved to the database. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Insert As %Boolean) As %Status
{
	Quit $$$OK
}

/// This is called after the Exchange Item has been saved to the database.
Method OnAfterSave(InternalName As %String, Insert As %Boolean) As %Status
{
	Quit $$$OK
}

/// Called before a Exchange Item is deleted. Returning an error code prevents the delete from occurring.
Method OnBeforeDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Called after a Exchange Item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Internal use event.
Method %BeforeLoad(InternalName As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Quit ..OnBeforeLoad(item)
}

/// Internal use event.
Method %AfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Quit ..OnAfterLoad(item)
}

/// Internal use event.
/// Note: Internal ids are not allocated to new objects prior to this event.
Method %BeforeSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}, Insert As %Boolean) As %Status
{
	#Define NewId "*"
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	#; %Storage.Persistent objects will not always have an Id assigned prior to %BeforeSave.
	#; Use an asterix(*) to indicate the id is yet to be assigned.
	#; If the id is empty then the oid created using $$$oidCompose will not include
	#; the classname.
	If id = ""&&($IsObject(Object)) Set id = $$$NewId, className = $ClassName(Object), newId = 1
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id,Object)
	If InternalName'=item&&($$$oidPrimary(item)'=$$$NewId) Set Insert = 0
	If $g(newId)&&($$$oidPrimary(item)=$$$NewId) Set $li(item)=""
	Quit ..OnBeforeSave(item,Insert)
}

/// Internal use event.
Method %AfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}, Insert As %Boolean) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	If InternalName'=item Set Insert = 0
	Quit ..OnAfterSave(item,Insert)
}

/// Internal use event.
Method %BeforeDelete(InternalName As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Set delete = (InternalName=item)
	If delete {
		Set sc = ..OnBeforeDelete(item)
	} Else {
		#; A child class has been deleted which means the item has been updated.
		Set sc = ..OnBeforeSave(item,0)
	}
	Quit sc
}

/// Internal use event.
Method %AfterDelete(InternalName As %String) As %Status
{
	If $Get(%xmlExchangeItem) {
		#; Events during %XML.Exchange:Load / Export are not passed on.
		#; Deleted objects should still have their ^OBJ.GUID entry removed.
		Set sc = $$$OK
	} Else {
		Set className = $$$oidClassName(InternalName)
		Set id = $$$oidPrimary(InternalName)
		If className = ""||(id = "") Quit $$$OK
		Set item = $ClassMethod(className,"XMLGetElement",id)
		Set delete = (InternalName=item)
		If delete {
			Set sc = ..OnAfterDelete(item)
		} Else {
			#; A child class has been deleted which means the item has been updated.
			Set sc = ..OnAfterSave(item,0)
		}
	}
	#; Remove ^OBJ.GUID entry.
	#; This is done after passing on the event in case the
	#; ChangeControl class requires access to the GUID.
	If $Data(^OBJ.GUID(1,InternalName), guid), guid'="" {
		Kill ^OBJ.GUID(0,guid)
		Kill ^OBJ.GUID(1,InternalName)
	}
	Quit sc
}

/// Internal use trigger.
/// Note: Id has already been allocated when the before insert trigger is fired.
Method %BeforeInsertTrigger(InternalName As %String, Values As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Set insert = (InternalName=item)
	Quit ..OnBeforeSave(item,insert)
}

/// Internal use trigger.
Method %AfterInsertTrigger(InternalName As %String, Values As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	If $Get(^OBJ.GUID(1,InternalName))="" Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Set insert = (InternalName=item)
	Quit ..OnAfterSave(item,insert)
}

/// Internal use trigger.
Method %BeforeUpdateTrigger(InternalName As %String, Values As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Quit ..OnBeforeSave(item,0)
}

/// Internal use trigger.
Method %AfterUpdateTrigger(InternalName As %String, Values As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Quit ..OnAfterSave(item,0)
}

/// Internal use trigger.
Method %BeforeDeleteTrigger(InternalName As %String) As %Status
{
	If $Get(%xmlExchangeItem) Quit $$$OK
	Set className = $$$oidClassName(InternalName)
	Set id = $$$oidPrimary(InternalName)
	If className = ""||(id = "") Quit $$$OK
	Set item = $ClassMethod(className,"XMLGetElement",id)
	Set delete = (InternalName=item)
	If delete {
		Set sc = ..OnBeforeDelete(item)
	} Else {
		#; A child class has been deleted which means the item has been updated.
		Set sc = ..OnBeforeSave(item,0)
	}
	Quit sc
}

/// Internal use trigger.
Method %AfterDeleteTrigger(InternalName As %String) As %Status
{
	If $Get(%xmlExchangeItem) {
		#; Events during %XML.Exchange:Load / Export are not passed on.
		#; Deleted objects should still have their ^OBJ.GUID entry removed.
		Set sc = $$$OK
	} Else {
		Set className = $$$oidClassName(InternalName)
		Set id = $$$oidPrimary(InternalName)
		If className = ""||(id = "") Quit $$$OK
		Set item = $ClassMethod(className,"XMLGetElement",id)
		Set delete = (InternalName=item)
		If delete {
			Set sc = ..OnAfterDelete(item)
		} Else {
			#; A child class has been deleted which means the item has been updated.
			Set sc = ..OnAfterSave(item,0)
		}
	}
	#; Remove ^OBJ.GUID entry.
	#; This is done after passing on the event in case the
	#; ChangeControl class requires access to the GUID.
	If $Data(^OBJ.GUID(1,InternalName), guid), guid'="" {
		Kill ^OBJ.GUID(0,guid)
		Kill ^OBJ.GUID(1,InternalName)
	}
	Quit sc
}

}
