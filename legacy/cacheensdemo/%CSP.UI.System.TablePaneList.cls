/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This class differs from TablePane in that it does not use Parameters for general list. This class
/// is created to deal with the queries existed in the %SYSTEM classes.
Class %CSP.UI.System.TablePaneList Extends %CSP.Util.TablePane [ System = 4 ]
{

/// This method performs the actual execution of the ResultSet
/// This can be overridden by subclasses
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Set tSC = pRS.Execute()

Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

}
