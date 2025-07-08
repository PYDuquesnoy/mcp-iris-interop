/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Generic Pane for Displaying Explorer List.
Class %CSP.UI.System.GlobalListPane Extends %CSP.UI.System.ExpListPane [ System = 4 ]
{

Method CreateResultSet(ByRef pID As %String, ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	If $D(^xxx)   // test connection for remote
	// If it's implied namespace, then use DirectoryList
	If ($E($namespace)="^") Set ..Query = "%SYS.GlobalQuery:DirectoryList"
	Set pRS = ##class(%ResultSet).%New(..Query)
	If ('pRS.QueryIsValid()) {
		Quit $$$ERROR($$$GeneralError,"Invalid Query: " _ ..Query)
	}
Done
	Quit tSC
Trap
	Set $ZT = ""
	i $ze["<PROTECT" {
		Set tSC = $$$ERROR($$$NamespaceUnavailable,$namespace)
	} else {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	Goto Done
}

/// This method performs the actual execution of the ResultSet
Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
		
	Set tSpec = $G(pID(1))
	Set tSpec = $ZSTRIP(tSpec,"<>W")
	Set tType="Globals"
	#; YSD1844: get the last mask user entered
	Do ..GetExpParameters(.tType,.tMaxResults,.tSpec,.tOrderBy,.tDir)
	Set:tSpec="" tSpec="*"
	#; whether to show system items
	Set tShowSys = +$G(pID(2))
	#; if implied namespace use directory
	If ($E($namespace)="^") {
		#;SML1141+ pass the system name for remote.
		Set Dir = $P($namespace,"^",3),system=$p($namespace,"^",2) 
		Set tSC = pRS.Execute(Dir,system,tSpec,tShowSys,,1) 
		#;SML1141-
	} Else {
		Set tSC = pRS.Execute($namespace,tSpec,tShowSys,.UnavailableDatabases,,1)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<PROTECT>" Set tSC = $$$ERROR(940)
	Else  Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

}
