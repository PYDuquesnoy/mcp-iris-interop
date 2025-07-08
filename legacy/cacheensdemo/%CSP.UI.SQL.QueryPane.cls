/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>An AutoPage pane that lets a user enter an SQL query and execute it.
Class %CSP.UI.SQL.QueryPane Extends %CSP.Util.SQLQueryPane [ System = 4 ]
{

/// Should this page display timing stats
Parameter SHOWSTATISTICS = 1;

Parameter SHOWSQLINFO = 1;

Method CreateResultSet(ByRef pID As %String, ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"

	Do {
		If ($G(pID(1)) = "$DELETE") {
			#; ignore request to delete item from history
			Quit
		}

		#; if not an explicit execute request (or history), skip it
		If ('$D(pID(1)) && '$D(%request.Data("$EXEC",1))) {
			Quit
		}
		
		#; Run user's SQL init code
		Set sc = ##class(%SQL.Manager.API).SetServerInitCode() 
		If (sc'=0) {
			Set tSC = $$$ERROR($$$GeneralError,"Error in running ServerInitCode: " _ sc)
			Quit
		}

		#; make sure column names for user queries are not localized!
		Set ..LocalizeColumns = 0
		
		#; look to see if this is from CQ
		Set query = ""
		If $G(%request.Data("$CQ",1)) = 1 {	
			If $G(pID(1)) = ""||'$D($$$CQ("QueryRoutine",pID(1))) {
				Set errmsg = $$$TextHTML("Cached query is no longer defined. Unable to continue.")	
				&html<<p>#(errmsg)#</p>>
			Quit
			}
			Set query = ##class(%SQL.Manager.API).GetCachedQueryInfo(pID(1),.sCreate,.sLast,.bSource,.sQueryType)
		} Else {
		#; look to see if this a request from History first. If it is get the query text from global
			If ($G(pID(1)) = "$EXECUTE") {
				Set query = $G(^mqh($UserName,+$G(pID(2))))
			}
			If ($G(pID(1)) '= "$SELECT") {
				#;YSD2100 If $G(query) = "" Set query = $G(pID(1),$G(%session.Data("$SQLQUERY")))
				If $G(query) = "" {
					#; YSD2344 Set query = $ZCVT($G(pID(1)),"O","HTML")
					Set query = $ZCVT($G(pID(1)),"I","URL")
					If query = "" Set query = $G(%session.Data("$SQLQUERY"))
				}
			}
		}
		Set query = $zstrip(query,"<>WC")
		If (query = "") {
			// if query is empty, do nothing
			Quit
		}
		If $G(%session.Data("$NAMESPACE")) '= "" ZN %session.Data("$NAMESPACE")

		Set pRS = ##class(%ResultSet).%New()

		#; do not allow queries that take more than 30 seconds to compile!
		#; YSD1750 Do $System.Alarm.Set(30)
		Set responseTimeout = %request.GatewayTimeout - 5
		If responseTimeout < 15 Set responseTimeout = 15
		Do $System.Alarm.Set(responseTimeout)
		Set tSC = pRS.Prepare(query)
		Do $System.Alarm.Clear()
	} While(0)
	If $$$ISERR(tSC) {
		#; YSD2236 If query errored out properly then return it as is
		If $System.Status.GetErrorCodes(tSC) Quit tSC
		Goto Trap
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Do $System.Alarm.Clear()
	If ($ZE["<ALARM>") {
		#; YSD1750 Set tSC=$$$ERROR($$$GeneralError,$$$Text("Query did not compile within 30 seconds."))
		Set responseTimeout = %request.GatewayTimeout - 5
		Set responseTimeout = $S(responseTimeout'<15:responseTimeout,1:15)
		Set tText = $ZCVT($$$FormatText($$$Text("Query did not compile within %1 seconds."), responseTimeout),"O","HTML")
		Set tSC=$$$ERROR($$$GeneralError,tText)
	} ElseIf $ZE["<PROTECT>" {
		Set tSC = $$$ERROR(940)
	} Else {
		Set tSC=$$$ERROR($$$GeneralError,$ZE)
	}
	Goto Done
}

Method ExecuteResultSet(pRS As %ResultSet, ByRef pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"

	Do {
		// allow override of RUNTIME mode
		If ($G(%session.Data("$SQLQUERYMODE")) '= "") {
			// use session value
			Set pRS.RuntimeMode = %session.Data("$SQLQUERYMODE")
		}
		Else {
			Do GetPortalSettings^%SYS.cspServer2($UserName,.PortalSettings)	
			Set pRS.RuntimeMode = $G(PortalSettings("RUNTIMEMODE"),2)
		}

		// assume there are no parms for user-entered queries
		Set tParms = pRS.GetParamCount()
		If (tParms > 0) {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Execute Query Page does not support query parameters."))
			Quit
		}
		#; do not allow queries that take more than 30 seconds to execute!
		#; YSD1750 Do $System.Alarm.Set(30)
		Set responseTimeout = %request.GatewayTimeout - 5
		If responseTimeout < 15 Set responseTimeout = 15
		Do $System.Alarm.Set(responseTimeout)
		Set tSC = pRS.Execute()
		Do $System.Alarm.Clear()
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Do $System.Alarm.Clear()
	If ($ZE["<ALARM>") {
		#; YSD1750 Set tSC=$$$ERROR($$$GeneralError,$$$Text("Query did not execute within 30 seconds."))
		Set tText = $ZCVT($$$FormatText($$$Text("Query did not execute within %1 seconds."), %request.GatewayTimeout-5),"O","HTML")
		Set tSC=$$$ERROR($$$GeneralError,tText)
	} ElseIf $ZE["<PROTECT>" {
		Set tSC = $$$ERROR(940)
	} Else {
		Set tSC=$$$ERROR($$$GeneralError,$ZE)
	}
	Goto Done
}

}
