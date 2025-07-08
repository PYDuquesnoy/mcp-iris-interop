/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Projection class used by <class>%ZEN.Component.page class</class>.
/// Currently this does nothing.
Class %ZEN.PageProjection Extends %Projection.AbstractProjection [ Deprecated, System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Don't run this method on the base class
		If (pClassName="%ZEN.Component.page") Quit

		#; ignore % classes
		If ($E(pClassName)="%") Quit
		
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod RemoveProjection(pClassName As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Don't run this method on the base class
		If (pClassName="%ZEN.Component.page") Quit
	
		#; ignore % classes for now
		If ($E(pClassName)="%") Quit
	
	} While(0)
Exit
  	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
