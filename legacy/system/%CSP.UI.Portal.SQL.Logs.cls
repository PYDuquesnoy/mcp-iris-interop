/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.SQL.Logs Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

Parameter AUTONS As BOOLEAN = 1;

/// TODO: why is this not working?
Parameter SHOWNAMESPACE As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.SQL.Logs.zen";

Parameter HELPADDRESS = "Home,SQL";

Parameter PAGENAME = "SQL Diagnostic Logs";

/// TODO: check if appropriate
Parameter RESOURCE = "%Admin_Operate";

Property SelectedRowID As %ZEN.Datatype.integer(ZENURL = "resultID") [ Internal ];

Property filterString As %String [ Internal ];

XData Style
{
<style type="text/css">

table.tpTable td,
table.tpTable th {
	padding-left: 5px;
	padding-right: 5px;
}

/* copied from %CSP.UI.Portal.SQL.Home */
/* table style for catalog details */
table.DetailTable	{ 
	font-size: 11px;
	margin-left: 2px; margin-right: 10px;
	margin-top: 10px;
	border: 1px #888888 solid;
}
table.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: center;
}
table.DetailTable td.caption { 
	font-weight: bold;		
	background: #D0D0FF; 
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 3px;
}
table.DetailTable td.value { 		
	background: #FFFFFF; 
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 3px;
}
table.DetailTable tr.OddRow { background: white; }

table.DetailTable tr.EvenRow { background: #F0F0F0; }

p.logMessage {
	font-size: 12px;
}
font.logSeverityerror,
font.logSeverityabort {
	color: firebrick;
}
font.logSeveritywarning {
	color: darkorange;
}
font.logSeverityinfo {
	color:royalblue;
}
font.logSeveritycompleted {
	color: forestgreen;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<hgroup valign="top">
<vgroup width="50%" valign="top">
<titleBox title="Results" />
<hgroup labelPosition="left" enclosingStyle="margin-bottom: 10px; margin-top: 10px;">
<text id="txtFilter" onchange="zenPage.applyFilter(zenThis.getValue());" label="Filter statements" />
</hgroup>
<tablePane id="table"
	OnCreateResultSet="CreateRS" 
	OnExecuteResultSet="ExecuteRS" 
	valueColumn="ID"
	onselectrow="zenPage.selectRow(zenThis.getValue());"
	multiSelect="true"
	showRowSelector="true"
	showZebra="true">
<column colName="ID" hidden="true" />
<column colName="createTime" header="Started at" OnDrawCell="DrawPXCell" />
<column colName="statement" header="Statement" OnDrawCell="DrawStatementCell" style="overflow-wrap: anywhere;" />
<column colName="status" header="Status" />
<column colName="username" header="Username" />
</tablePane>
</vgroup>
<spacer width="20" />
<vgroup valign="top" width="50%">
<titleBox title="Details" />
<html id="htmlDetails" OnDrawContent="DrawDetails" />
</vgroup>
</hgroup>
</pane>
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("System Logs","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?$NAMESPACE="_$ZCVT($G(%session.Data("$NAMESPACE")),"O","URL")))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	set pDisplay = 1
	set pSearchBox = 0
	set pRibbonTitle = ..%OnGetPageName()
	set pCommands($i(pCommands)) = $lb("cmdDelete",$$$Text("Delete"),$$$Text("Delete selected logs"),"zenPage.cmdDelete();")
	quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL Diagnostic Logs")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
	zen('table').executeQuery();
	zen('htmlDetails').refreshContents();
}

ClientMethod applyFilter(filter) [ Language = javascript ]
{
	var sc = zenPage.setProperty('filterString', filter);
	zen('table').executeQuery();
}

Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	set sql = "SELECT ID, createTime, statement, status, ""user"" as username FROM %SQL_Diag.Result"
	
	kill params
	if ..filterString'="" {
		set filter = $zstrip(..filterString,"<>=W"), 
			where = "",
			pInfo.parms = $l(filter," ")
		for i = 1:1:pInfo.parms {
			set where = where _ $s(where="":"", 1:" AND ") _ "UPPER(statement) LIKE ?"
			set pInfo.parms(i) = "%"_$$$UPPER($piece(filter," ",i))_"%"
		}
		set sql = sql_" WHERE "_where
	}
	
	set sql = sql_" ORDER BY createTime DESC"
	
	set rs = ##class(%ResultSet).%New(),
		rs.RuntimeMode = 1, // ODBC mode
		sc = rs.Prepare(sql)
	if $$$ISERR(sc) { $$$ThrowStatus(sc) }
	quit rs
}

Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	merge params = pInfo.parms
	set tSC = pRS.Execute(params...) 
	quit tSC
}

ClientMethod selectRow(id) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedRowID', id);
	zen('htmlDetails').refreshContents();
}

ClientMethod cmdDelete() [ Language = javascript ]
{
	var allRows = zen('table').selectedRows.split(',');
	var selected = [];
	for (r in allRows) {
		if (allRows[r]=='') continue;
		selected[selected.length] = allRows[r];
	}
	if (selected.length == 0)  return; // nothing selected
	if (confirm($$$FormatText($$$Text('Are you sure you want to delete %1 records?'),selected.length))) {
		var sc = zenPage.Delete(selected.join(','));
		zenPage.updateView();
	}
}

Method Delete(selectedIDs As %String) As %Status [ ZenMethod ]
{
	set list = $lfs(selectedIDs)
	&SQL(DELETE FROM %SQL_Diag.Message WHERE diagResult %INLIST :list)
	&SQL(DELETE FROM %SQL_Diag.Result WHERE ID %INLIST :list)
	set:$listfind(list,..SelectedRowID) ..SelectedRowID = ""
	quit $$$OK
}

Method DrawDetails(seed As %String) As %Status
{
	set sc = $$$OK
	try {

		if ..SelectedRowID="" {
			set text = $$$Text("No row selected")
			&html<<p>#(text)#</p>>
			quit		
		}

		set info = ##class(%SQL.Diag.Result).%OpenId(..SelectedRowID)
		if info="" {
			set text = $$$Text("No data for selected row")
			&html<<p>#(text)#</p>>
			quit		
		}
		set pid = $$$HTMLENCODE(info.processId)
		
		&html<<table id="tblDetails" class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
		&html<<tr><td class="caption">Start time</td><td class="value">#(##class(%PosixTime).LogicalToDisplay(info.createTime))#</td></tr>>
		&html<<tr><td class="caption">User</td><td class="value">#($$$HTMLENCODE(info.user))#</td></tr>>
		&html<<tr><td class="caption">Status</td><td class="value">#($$$HTMLENCODE(info.status))#</td></tr>>
		if info.status="In Progress" {
			&html<<tr><td class="caption">Process ID</td><td class="value"><a href="%25CSP.UI.Portal.ProcessDetails.zen?PID=#(pid)#&DISPLAYID=#(pid)#&$ID1=#(pid)#">#(pid)#</a></td></tr>>
		} else {
			&html<<tr><td class="caption">Process ID</td><td class="value">#(pid)#</td></tr>>
			if (info.sqlcode=0) {
				&html<<tr><td class="caption">SQLCODE</td><td class="value"><font class="logSeveritycompleted">0 - success</font></td></tr>>
			} else {
				&html<<tr><td class="caption">SQLCODE</td><td class="value"><font class="logSeverityerror">#($$$HTMLENCODE(info.sqlcode))# - See detailed error messages below</font></td></tr>>
			}
		}
		&html<<tr><td class="caption">Input record count</td><td class="value">#(+info.inputRecordCount)#</td></tr>>
		&html<<tr><td class="caption">Error count</td><td class="value">#(+info.errorCount)# (max error count: #(+info.maxErrorCount)#)</td></tr>>
		&html<<tr><td class="caption">Statement</td><td class="value" style="overflow-wrap: anywhere;"><tt>#($$$HTMLENCODE($zstrip(info.statement,"<>WC")))#</tt></td></tr>>
		&html<</table>>

		set stmt = ##class(%SQL.Statement).%New(), stmt.%SelectMode = 1
		set sc = stmt.%Prepare("SELECT ID, messageTime, actor, severity, message FROM %SQL_Diag.Message WHERE diagResult = ? ORDER BY messageTime ASC")
		quit:$$$ISERR(sc)
		set rs = stmt.%Execute(..SelectedRowID)
		if 'rs.%Next() {
			&html<<p class="logMessage">No messages to display</p>>
			quit
		}
		&html<<h4>Messages:</h4>>
		do {
			set severity = $$$HTMLENCODE($translate(rs.%Get("severity")," ",""))
			&html<<p class="logMessage">#($$$HTMLENCODE($e($piece(rs.%Get("messageTime")," ",2),1,12)))# (#($$$HTMLENCODE(rs.%Get("actor")))#) - <font class="logSeverity#(severity)#">#(severity)#</font>: #($$$HTMLENCODE(rs.%Get("message")))#</p>>
		} while rs.%Next()
		
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	quit sc
}

ClassMethod DrawStatementCell(table As %ZEN.Component.tablePane, name As %String, seed As %String) As %Status
{
	// shorten statement to essentials
	set statement = $zstrip(%query(name),"=W"), from=0
	if $$$UPPER($piece(statement," ",1)) = "LOAD" {
		for i = 3:1 {
			set:('from)&&($$$UPPER($piece(statement," ",i))="FROM") from=i
			quit:$$$UPPER($piece(statement," ",i))="INTO"
		}
		&html<<tt>#($$$HTMLENCODE($piece(statement," ",1,from+1)))# ... #($$$HTMLENCODE($piece(statement," ",i,i+1)))# ...</tt>>
	} else {
		&html<<tt>#($$$HTMLENCODE($piece(statement," ",1,3)))# ...</tt>>
	}
	quit $$$OK
}

ClassMethod DrawPXCell(table As %ZEN.Component.tablePane, name As %String, seed As %String) As %Status
{
	&html<#($$$HTMLENCODE($piece(%query(name),".",1)))#>
	quit $$$OK
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.Logs.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	default:
	}
}

}
