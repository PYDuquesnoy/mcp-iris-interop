/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This class implements the form used to execute user SQL queries within the Mgt Portal.
/// It also includes some methods used to manage the query history.
Class %CSP.UI.SQL.QueryForm Extends (%RegisteredObject, %CSP.Util.AutoForm) [ Inheritance = right, System = 4 ]
{

/// Query text
Property Query As %String(CAPTION = "SQL Query", MAXLEN = 10000);

/// Query run-time mode
Property RuntimeMode As %String(CAPTION = "Data Display Mode", DISPLAYLIST = ",Logical Mode,ODBC Mode,Display Mode", MAXLEN = 50, VALUELIST = ",0,1,2");

/// Rows to display
Property MaxRows As %Integer(CAPTION = "Maximum Rows", MINVAL = 1);

ClassMethod CreateInstance(ByRef pID As %String) As %CSP.Util.AutoForm
{
	Set tObj = ..%New()
	If $G(%request.Data("$NAMESPACE",1)) '= "" ZN %request.Data("$NAMESPACE",1)
	#; test for Delete query from History case
	If ($G(pID(1)) = "$DELETE") {
		Set tObj.Query = ""
		Kill %session.Data("$SQLQUERY")
		#; remove item from History
		If ($G(pID(2)) '= "") {
			Kill ^mqh($UserName,pID(2))
		} Else {
			Kill ^mqh($UserName)	
		}
	} ElseIf ($G(pID(1)) = "$SELECT")!($G(pID(1)) = "$EXECUTE")!($G(pID(1)) = "$SHOWPLAN") {
		#; If it's called from History, we are getting the query text from global instead of passing to URL
		Set tObj.Query = $G(^mqh($UserName,+$G(pID(2))))
	} 
	Else {
		#; See if we are passed query from History list first
		#;YSD2100 Set tObj.Query = $G(pID(1),$G(%session.Data("$SQLQUERY")))
		Set query = $ZCVT($G(pID(1)),"O","HTML")
		If query = "" Set query = $G(%session.Data("$SQLQUERY"))
		Set tObj.Query = query 
	}

	If ($G(%session.Data("$SQLQUERYMODE")) '= "") {
		#; use session value
		Set tObj.RuntimeMode = %session.Data("$SQLQUERYMODE")
	}
	Else {
		#; get default run-time mode
		Do GetPortalSettings^%SYS.cspServer2($UserName,.PortalSettings)	
		Set tObj.RuntimeMode = $G(PortalSettings("RUNTIMEMODE"),2)
	}

	Set tObj.MaxRows = $G(%session.Data("$SQLMAXROWS"),1000)
	Quit tObj
}

Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
	#; remember runtime mode
	Set %session.Data("$SQLQUERYMODE") = ..RuntimeMode
	Set %session.Data("$SQLMAXROWS") = ..MaxRows

	#; strip white space from query
	Set ..Query = $ZSTRIP(..Query,"<>W")

	Set tUseQuery = 1

	#; see what kind of action was requested
	If (pSubmit = "$AUTOFORM_EXECUTE") {
		Do ##class(%SQL.Manager.API).UpdateQueryHistory()
		#; redirect to get rid of $ID1 etc.
		Set %response.Redirect = ##class(%CSP.Page).Link("UtilSqlQuery.csp")
		Set %response.Context("$EXEC") = 1
	}
	ElseIf (pSubmit = "$AUTOFORM_SHOWPLAN") {
		#; force jump to ShowPlan Page
		Do ##class(%SQL.Manager.API).UpdateQueryHistory()
		Set %response.Redirect = ##class(%CSP.Page).Link("UtilSqlQueryShowPlan.csp")
	}
	ElseIf (pSubmit = "$AUTOFORM_HISTORY") {
		#; force jump to history Page
		Set %response.Redirect = ##class(%CSP.Page).Link("UtilSqlQueryHistory.csp")

		#; do not remember query in this case
		Set tUseQuery = 0
	}
	
	If (tUseQuery) {
		#; save query in history
		Set tQuery = ..Query
		Set tSC = ##class(%SQL.Manager.API).SaveQueryHistory(50, .currentIndex, .tQuery, $UserName, $namespace)
	
		#; Place query into Session, not URL
		Set %session.Data("$SQLQUERY") = ..Query
	}
	Else {
		Kill %session.Data("$SQLQUERY")
	}

	Quit $$$OK
}

/// define buttons
ClassMethod OnDefineButtons(ByRef pButtons As %CSP.Util.FormButton)
{
	Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(1).Name = "$AUTOFORM_EXECUTE"
	Set pButtons(1).Caption = $$$Text("Execute Query")

	Set pButtons(2) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(2).Name = "$AUTOFORM_SHOWPLAN"
	Set pButtons(2).Caption = $$$Text("Show Query Plan")

	Set pButtons(3) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(3).Name = "$AUTOFORM_HISTORY"
	Set pButtons(3).Caption = $$$Text("Query History")
	
	Set pButtons(4) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(4).Name = "$AUTOFORM_QUERYBUILDER"
	Set pButtons(4).Caption = $$$Text("Query Builder")
	Set PageName = ##class(%CSP.Page).Link("%CSP.UI.SQL.QueryBuilderWindow.cls",,1)
	Set pButtons(4).OnClick = "launchPopupWindow('"_PageName_"ClassFilter=&ColumnType=2&$ID1='+encodeURIComponent(self.document.getElementById('Query').value),'resizable','QueryBuilder');"
	Set pButtons(4).Type = "popup"
}

/// Returns query history list
Query QueryHistory() As %Query(ROWSPEC = "ID:%String,Query:%String")
{
}

ClassMethod QueryHistoryExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ""
	Quit $$$OK
}

ClassMethod QueryHistoryFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = QueryHistoryExecute ]
{
	Set qHandle = $O(^mqh($UserName,qHandle))
	If (qHandle = "") {
		Set Row = ""
		Set AtEnd = 1
	}
	Else {
		Set Row = $LB(qHandle,^mqh($UserName,qHandle))
		Set AtEnd = 0
	}

	Quit $$$OK
}

ClassMethod QueryHistoryClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = QueryHistoryExecute ]
{
	Quit $$$OK
}

/// Manual override of generated method.
ClassMethod DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As FormButton, pTarget As %String = "") As %Status
{
	Set hasError = ($G(%request.Data("$AUTOFORMERROR",1))'="")

	Write "<form action="""_(pActionURL)_""" method=""POST"" name=""theForm"" target="""_(pTarget)_""">",!
	Write ##class(%CSP.Page).InsertHiddenFields(pActionURL)
	Write "<input type=""HIDDEN"" name=""$CLASS"" value=""%CSP.UI.SQL.QueryForm"">",!
	Write "<input type=""HIDDEN"" name=""$FRAME"" value="""_(pTarget)_""">",!
	Write "<input type=""HIDDEN"" name=""$FORMURL"" value="""_(%request.URL)_""">",!
	Write "<input type=""HIDDEN"" name=""$NAMESPACE"" value="""_($G(%request.Data("$NAMESPACE",1)))_""">",!
	Set id = $O(pID(""))
	While (id '= "") {
	Write "<input type=""HIDDEN"" name=""$ID"_(id)_""" value="""_($ZCVT(pID(id),"O","HTML"))_""">",!
	Set id = $O(pID(id))
	}
	Write "<table class=""AutoForm"">",!

	Write "<tr>",!
	Write "<td class=""AutoFormButton"" style=""text-align:left;"">",!

	Write "<nobr>"

	If ('$D(pButtons)) {
		Do ..OnDefineButtons(.pButtons)
	}
	Do ..DrawFormButtons(.pButtons)

	#; options
	Set tVal = $select(pObj="":"",1:(pObj.RuntimeModeLogicalToDisplay(pObj.RuntimeMode)))
	Set:hasError tVal = $G(%request.Data("RuntimeMode",1),"YO")
	Set msg = $$$Text("Display","%Utility")
	Set hlp = $$$Text("Display mode used for the results","%Utility")
	Set lang = $$$SessionLanguage
	
	Write "&nbsp;&nbsp;"_($ZCVT(msg,"O","HTML"))_":&nbsp;",!
	Write "<select class=""AutoForm"" title="""_hlp_""" name=""RuntimeMode"">",!
		Write "<option class=""AutoForm"" value="""" "_($S(tVal="":"selected",1:""))_">"_($get(^%qMsg("%Utility",lang,"0"),"")),!
		Write "<option class=""AutoForm"" value=""Logical Mode"" "_($S(tVal="Logical Mode":"selected",1:""))_">"_($get(^%qMsg("%Utility",lang,"2508538291"),"Logical Mode")),!
		Write "<option class=""AutoForm"" value=""ODBC Mode"" "_($S(tVal="ODBC Mode":"selected",1:""))_">"_($get(^%qMsg("%Utility",lang,"3352301680"),"ODBC Mode")),!
		Write "<option class=""AutoForm"" value=""Display Mode"" "_($S(tVal="Display Mode":"selected",1:""))_">"_($get(^%qMsg("%Utility",lang,"3743525170"),"Display Mode")),!
		Write "</select>",!
		Write "",!
	Write "&nbsp;&nbsp;",!
	Set tVal = $select(pObj="":"",1:(pObj.MaxRowsLogicalToDisplay(pObj.MaxRows)))
	Set:hasError tVal = $G(%request.Data("MaxRows",1),"YO")
	Set msg = $$$Text("Max Rows","%Utility")
	Set hlp = $$$Text("Maximum number of rows to display","%Utility")

	Write ($ZCVT(msg,"O","HTML"))_":&nbsp;",!
	Write "<input class=""AutoForm"" type=""text"" title="""_hlp_""" name=""MaxRows"" size=""8"" value='"_($ZCVT(tVal,"O","HTML"))_"'>",!
	Write "&nbsp;&nbsp;"
	Write "</nobr>"

	#; prevent IE default submit behavior!
	Write "<input type=""text"" style=""display:none;"" name=""IEworkaound"">",!

	Write "</td></tr>"

	Set tVal = $select(pObj="":"",1:(pObj.QueryLogicalToDisplay(pObj.Query)))
	Set:hasError tVal = $G(%request.Data("Query",1),"YO")
	Write "<tr class=""AutoForm"" valign=""middle"">",!
	Write "<td class=""AutoFormControl"" nowrap>"

	&html<<textarea name="Query" id="Query" style="height:150px;width:100%;">#($ZCVT(tVal,"O","HTML"))#</textarea>>
	Write "</td>",!
	Write "</tr>",!
	Set tError = ..GetFormError()
	If (tError '= "") {
		Write "<tr><td class=""AutoFormLabel"">&nbsp;</td><td style=""border: 1px black solid; font-weight: bold; color: #DA4848; background: #FFFFFF;"">"_(tError)_"</td></tr>",!
	}
	Write "</table>",!
	Write "</form>",!
	Quit $$$OK
}

}
