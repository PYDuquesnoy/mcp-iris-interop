/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>An AutoPage pane that lets a user enter an SQL query and execute it.
Class %CSP.UI.SQL.OpenPane Extends %CSP.Util.SQLQueryPane [ System = 4 ]
{

Method CreateResultSet(ByRef pID As %String, ByRef pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK
	
	// make sure column names for user queries are not localized!
	Set ..LocalizeColumns = 0


	// get request parms via object
	//Set tRequest = ##class(%CSP.UI.SQL.QueryForm).ProcessSubmit(%request, .pID)

	//Set query = $G(%session.Data("$SQLQUERY"))
	//Set query = $ZSTRIP(query,"<>W")
	Set Schema = $G(%request.Data("$ID1",1))
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.Schema)
	Set Table = $G(%request.Data("$ID2",1))
	Set gvDummy = ##class(%SQL.Manager.API).CheckIdentifier(.Table)
	Set msColumns = ""
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
	Do tRS.Execute(Schema,Table)
	While tRS.Next() {
		Set sColumn = tRS.Get("FIELD_NAME")
        If tRS.Get("HIDDEN")="No" {
        	Set msColumns = msColumns _ $$quoter2^%apiSQL(sColumn) _ ","
        } Else {
	     	If $E(sColumn,1,2) = "ID" Set msColumns = msColumns _ sColumn _ ","
        }
	}
	If $E(msColumns,$L(msColumns))="," Set msColumns=$E(msColumns,1,$L(msColumns)-1)
	If msColumns = "" Set msColumns = "*"
	Set query = "SELECT "_msColumns_" FROM "_Schema_"."_Table
	If (query = "") {
		// if query is empty, do nothing
		Quit $$$OK
	}
	If Schema = "Config",$namespace="%SYS" Set query = query _ " where SectionHeader = '" _ Table_"'"

	// test for SELECT
	//Set start = $ZCVT($E(query,1,6),"U")
	//If (start '= "SELECT") {
	//	Quit $$$ERROR($$$GeneralError,"Only SELECT statements are allowed")
	//}
	$$$ChangeNamespace

	#; Run user's SQL init code
	Set sc = ##class(%SQL.Manager.API).SetServerInitCode() 
	If (sc'=0) {
		Quit $$$ERROR($$$GeneralError,$$$Text("Error in running ServerInitCode: ") _ sc)
	}
	Set pRS = ##class(%ResultSet).%New()
	Set tSC = pRS.Prepare(query)
	
	Set EventDesc = "Open Table"
	Set EventData = query
	$$$SMPAuditView
	Quit tSC
}

}
