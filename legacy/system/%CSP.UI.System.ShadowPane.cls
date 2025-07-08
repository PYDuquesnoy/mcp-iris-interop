/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane always use Runtime mode = 2 = Display mode.
Class %CSP.UI.System.ShadowPane Extends %CSP.Util.TablePane [ System = 4 ]
{

/// This method performs the actual execution of the ResultSet
/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"

	Set pRS.RuntimeMode = 2
	
	Set tParms = pRS.GetParamCount()
	// YSD1904 If (tParms = 0) {
		Set tSC = pRS.Execute()
	 //}
	/* YSD1904
	ElseIf (tParms = 1) {
		Set tSC = pRS.Execute($G(pID(1)))
	}
	ElseIf (tParms = 2) {
		Set tSC = pRS.Execute($G(pID(1)),$G(pID(2)))
	}
	Else {
		Set tSC = pRS.Execute($G(pID(1)),$G(pID(2)),$G(pID(3)))
	}
	*/
Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

}
