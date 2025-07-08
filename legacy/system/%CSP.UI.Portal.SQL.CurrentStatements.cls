/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardingManager

Class %CSP.UI.Portal.SQL.CurrentStatements Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.SQL.CurrentStatements.zen";

Parameter HELPADDRESS = "Home,SQL";

/// Displayed name of this page.
Parameter PAGENAME = "Currently running SQL statements";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// MRP1310 [Major Refactoring]
/// The RowID for the 'Application Metadata Stack' (AMS) row SELECTed by the user.
/// This property has the following format, with {field} values obtained from the 
/// 'INFORMATION_SCHEMA.CURRENT_STATEMENTS' table: 
///    {Server}_"||"_{ProcessID}_"||"_{StatementIndexHash}
Property SelectedRowID As %String [ Internal ];

Property InfoCache As array Of %String [ Internal, Private ];

/// Filter value user entered into the "Filter" field in the table navigator. This value is saved and reloaded for this page.
Property Filter As %ZEN.Datatype.string;

/// Previous Filter value
Property PrevFilter As %ZEN.Datatype.string [ InitialExpression = "PrevFilter" ];

/// 0 if not part of a sharded cluster, 1 for namespace-level cluster, 2 for node-level
Property isCluster As %Boolean [ Internal, Private ];

XData Style
{
<style type="text/css">

#tblDetails td.caption,
#tblStats td.caption {
	width: 130px;
}

/* copied from %CSP.UI.Portal.SQL.Home */
/* table style for catalog details */
table.DetailTable	{ 
	font-size: 11px;
	margin-left: 2px; margin-right: 10px;
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

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<hgroup width="100%">
<vgroup width="50%" enclosingStyle="margin-right: 15px;" valign="top">
<titleBox title="Currently executing SQL statements" />
<label id="lblDescription" value="" enclosingStyle="margin-bottom: 10px; margin-top: 10px;" />
<hgroup labelPosition="left" enclosingStyle="margin-bottom: 10px;">
<tableNavBar id="tblNavBar" tablePaneId="table" showFilter="true" showPageSize="true" showMaxRows="true" saveSizeMax="true"
onfilterChange="zenPage.filterChanged(value);" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="To filter: enter one or more characters of any column followed by [Tab]."/>
</hgroup>
<tablePane id="table"
	OnCreateResultSet="CreateRS" 
	OnExecuteResultSet="ExecuteRS" 
	valueColumn="CurrStmtID"
	onselectrow="zenPage.selectRow(zenThis.getValue());"
	showRowSelector="true"
	showZebra="true">
<column colName="CurrStmtID" hidden="true" />
<column colName="Server" id="colServer" />
<column colName="ProcessID" header="Process" />
<column colName="UserName" header="User" />
<column colName="Namespace" header="Namespace" />
<column colName="QueryRunTypeExec" header="Query Run Type" />
<column colName="QueryRunType" hidden="true" />
<column colName="ExecutionDuration" header="Elapsed Time" />
<column colName="SQLStatementID" header="Stmt ID" />
<column colName="StatementIndexHash" header="Statement" OnDrawCell="DrawStatementExcerpt" />
<column colName="TPNestingLevel" hidden="true" />
<column colName="Parameters" hidden="true" />
<column colName="CachedQuery" hidden="true" />
<column colName="CallerName" hidden="true" />
<column colName="CurrentWorkerCount" hidden="true" />
<column colName="StartTime" hidden="true" />
<column colName="StartTimeUTC" hidden="true" />
<column colName="ParentType" hidden="true" />
<column colName="Parent" hidden="true" />
<column colName="ChildStatements" hidden="true" />
</tablePane>
</vgroup>
<vgroup width="50%" enclosingStyle="margin-left: 15px;" valign="top">
<titleBox title="Selected statement details" />
<html id="htmlDetails" OnDrawContent="DrawDetails" />
</vgroup>
</hgroup>
</pane>
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink))=$LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$$$HTMLENCODE(NAMESPACE))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Current SQL Statements")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// User entered something into the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	this.Filter = value;
	var table = zen("table");
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	table.executeQuery(0);
	this.updateTime();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// Update / Reload table. This overrides the one in Portal.Utils.
ClientMethod updateView() [ Language = javascript ]
{
    this.filterChanged(this.Filter);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');
	this.filterChanged(this.Filter);
	var navbar = zen("tblNavBar");
	navbar.setFilterSize(40);
}

ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows);
}

ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value);
}

/// Create the ResultSet for <tablePane id="table" ...</tablePane> to be displayed by this page...
Method CreateRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	set sql($i(sql))="SELECT (Server || (('||')) || ProcessID || (('||')) || StatementIndexHash) AS CurrStmtID, "
	set sql($i(sql))="       Server, ProcessID, UserName, Namespace, "
	set sql($i(sql))="       CASE WHEN Parent IS NULL THEN QueryRunType ELSE (ParentType || ((' Query'))) END AS QueryRunTypeExec, QueryRunType, "
	set sql($i(sql))="       ROUND(ExecutionDuration,3) AS ExecutionDuration, SQLStatementID, StatementIndexHash, "
	set sql($i(sql))="       TP_NestingLevel AS TPNestingLevel, Parameters, CachedQuery, CallerName, "
	set sql($i(sql))="       CurrentWorkerCount, ExecutionStart AS StartTime, ExecutionStartUTC AS StartTimeUTC, ParentType, Parent, ChildStatements "
	set sql($i(sql))="FROM INFORMATION_SCHEMA.CURRENT_STATEMENTS "
	
	kill params
	set filter=%page.Filter
	set:filter'=%page.PrevFilter %page.PrevFilter=filter
	set:$e(filter,*)="*" filter=$e(filter,1,*-1)

	if filter'="" { // --- Process 'Filter' from SMP Page ---
		set filter=$$$UPPER($ZSTRIP(filter,"<>=W"))  // Remove Leading/Extra/Trailing Whitespace & Make Case-Insensitive!
		set pInfo.parms=$l(filter," "),where=""
		for pos=1:1:pInfo.parms { // --- Process All 'Filter' Params ---
			set where=where_"UPPER(Server || ((' ')) || ProcessID || ((' ')) || UserName || ((' ')) || NameSpace || ((' ')) || CASE WHEN Parent IS NULL THEN QueryRunType ELSE (ParentType || ((' Query'))) END || ((' ')) || SQLStatementID || ((' ')) || INFORMATION_SCHEMA.GetSQLStatement(Namespace,StatementIndexHash)) [ ? OR "
			set pInfo.parms(pos)=$p(filter," ",pos)
		}
		set sql($i(sql))="WHERE " _ $e(where,1,*-4)
	}
	set sql($i(sql))="ORDER BY StatementOrder"
	
	set rs=##class(%ResultSet).%New()
	set sc=rs.Prepare(.sql)
	if $$$ISERR(sc) { $$$ThrowStatus(sc) }
	RETURN rs
}

Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	do ..InfoCache.Clear()
	merge params = pInfo.parms
	set tSC = pRS.Execute(params...) 
	quit tSC
}

ClientMethod selectRow(id) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedRowID', id);
	zen('htmlDetails').refreshContents();
}

ClientMethod selectParent(id) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedRowID', id);
	zen('htmlDetails').refreshContents();
	zen('table').selectRow(zenPage.GetTableRow(id));
}

Method GetTableRow(id) As %Integer [ ZenMethod ]
{
	quit:'..InfoCache.IsDefined($$$LOWER(id)) -1
	set info = {}.%FromJSON(..InfoCache.GetAt($$$LOWER(id)))
	quit $s('$isobject(info):-1, 1:info.TableRow)
}

Method DrawStatementExcerpt(table As %ZEN.Component.tablePane, name As %String, seed As %String) As %Status
{
	set hash = $g(%query("StatementIndexHash"))
	quit:hash="" $$$OK
	
	set tSC=##class(%SQL.Manager.Catalog).GetStatementInfoOption($g(%query("Namespace")),hash,$LB("stmt"),.stmtInfo)
	set sqlStmt=$g(stmtInfo("statement"))
	
	if $g(sqlStmt)'="" {
		set:$p(sqlStmt," ",1)="DECLARE" sqlStmt = $p(sqlStmt," ",5,*)
		set sqlStmtText=$$$HTMLENCODE($e(sqlStmt,1,40)_"...")
		&html<<tt>#(sqlStmtText)#</tt>>
	} else {
		set sqlStmtText=$$$Text("Statement text could not be retrieved")
		&html<<i>#(sqlStmtText)#</i>>
	}
	
	// we'll also use this method to cache info about this entry so we'll still be able
	// to show something in case the process ends before someone clicks it in the table
	set info = {}, key=""
	for {
		set key = $order(%query(key),1,value)
		quit:key=""
		do info.%Set(key, value)
	}
	set info.TableRow = ..InfoCache.Count()
	do ..InfoCache.SetAt(info.%ToJSON(),$$$LOWER(%query("CurrStmtID")))
	
	quit $$$OK
}

Method DrawDetails(seed As %String) As %Status
{
	new $namespace
	if (..SelectedRowID = "") {
		set text = $$$Text("No row selected")
		&html<<p>#(text)#</p>>
		quit $$$OK
	}
	
	if '..InfoCache.IsDefined($$$LOWER(..SelectedRowID)) {
		set text = $$$Text("No data for selected ID")_" '"_..SelectedRowID_"'"
		&html<<p>#(text)#</p>>
		quit $$$OK
	}
	set info = {}.%FromJSON(..InfoCache.GetAt($$$LOWER(..SelectedRowID)))
	set pid=info.ProcessID
	set hash=info.StatementIndexHash
	
	set localToThisServer=$s(..isCluster:$$$UPPER($zu(110)_":"_$g(^%SYS("SSPort")))=$$$UPPER(info.Server),1:1)
	
	if localToThisServer {
		// check to see if it is still running
		set stillRunning = 1
		do ##class(%SYS.AppMetadataStack.SQL).GetStackInfo(pid,1,.amsInfoNew)

		// this is not a watertight check, but close enough for the use case
		if '$d(amsInfoNew(info.Server,pid,hash)) { 
			set text=$$$Text("This statement's execution already ended")
			set elapsed=$$$Text("execution ended")
			set stillRunning=0
		} 
		else { // --- Use the Timing Information from the new 'amsInfoNew(...)' Array ---
			set elapsedTime=$fn($LG($LG(amsInfoNew(info.Server,pid,hash,"info"),$$$AMSSQLPPStatsListPos),$$$AMSSQLExecutionDurationSubPos),,3)
			set elapsedOffset=elapsedTime
			set elapsedHrs=elapsedOffset\3600 set elapsedOffset=elapsedOffset-(elapsedHrs*3600)
			set elapsedMins=elapsedOffset\60 set elapsedOffset=elapsedOffset-(elapsedMins*60)
			set elapsedSecs=elapsedOffset
			set elapsedHMS=$s(elapsedTime'<60:$s(elapsedHrs:elapsedHrs_" hr"_$s(elapsedHrs>1:"s",1:""),1:"")_$s(elapsedMins:$s(elapsedHrs:"  ",1:"")_elapsedMins_" min"_$s(elapsedMins>1:"s",1:""),1:"")_$s(elapsedSecs:$s(elapsedHrs+elapsedMins:"  ",1:"")_elapsedSecs_" sec"_$s(elapsedSecs>1:"s",1:""),1:""),1:"")
			set elapsed=$$$Text("Elapsed: ")_elapsedTime_"sec"_$s(elapsedHMS'="":"  =  "_elapsedHMS,1:"")
			set text = $$$Text("This statement has been running for ")_elapsedTime_"sec"
		}
	} else {
		set text = $$$Text("This statement may still be running on ")_info.Server, elapsed = "remote"
	}
	&html<<p>#(text)#</p>>
	
	set tSC=$$UpdateSQLStatsByHash^%SYS.SQLSRV(info.Namespace,hash)  // MRP1314
	set tSC=##class(%SQL.Manager.Catalog).GetStatementInfoOption(info.Namespace,hash,$LB("stmt","stats"),.stmtInfo)
	set statement=$g(stmtInfo("statement"))
	set statCount=$g(stmtInfo("stats","callCount"))
	set statAverage=$g(stmtInfo("stats","runTimeAvg"))
	set statDeviation=$g(stmtInfo("stats","standardDev"))
	set statRowCount=$g(stmtInfo("stats","rowCount"))
	set statCommands=$g(stmtInfo("stats","commands"))
	
	set inTransaction=$s(info.TPNestingLevel:$$$Text("Yes"),1:$$$Text("No"))
	&html<<table id="tblDetails" class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
	&html<<tr><td class="caption">Process</td>>
	&html<<td id="tdProcessInfo" class="value">>
	if ..isCluster {
		if localToThisServer {
			if stillRunning {
				&html<<a href="%25CSP.UI.Portal.ProcessDetails.zen?PID=#(pid)#&DISPLAYID=#(pid)#&$ID1=#(pid)#" title="Click to show the Process Details...">#(pid)#</a>, running on this instance>
			} else {
				&html<#(pid)#, previously running on this instance>
			}
		} else {
			&html<#(pid)#, running on server #(info.Server)#>
		}
	}
	if localToThisServer,stillRunning { // --- Display [Cancel Query] Button for Locally Executing SQL Query that's still running ---
		&html<<span id="btnCancelContainer" style="float: right;"><button id="btnCancel" type="button" onclick="if (confirm($$$Text('Are you sure you want to cancel this operation?'))) zenPage.CancelQuery(#(pid)#,#(info.SQLStatementID)#);" title="Click to cancel this SQL Query">Cancel Query</button></span>>
	}
	&html<</td></tr>>
	if localToThisServer { // --- Local SQL Query Execution: Add Show Plan link ---
		&html<<tr><td class="caption">SQL Statement ID</td><td class="value"><a href="../exp/%25CSP.UI.Portal.Dialog.SQLStatementDetails.zen?$NAMESPACE=#(info.Namespace)#&NAMESPACE=#(info.Namespace)#&STMTHASH=#(hash)#&OpenInTab=1" target="_new" title="Click to show the SQL Statement Plan & Details...">#(info.SQLStatementID)#</a></td></tr>>
	}
	else { // --- Remote SQL Query Execution: Just show the data ---
		&html<<tr><td class="caption">SQL Statement ID</td><td class="value">#(info.SQLStatementID)#</td></tr>>
	}
	&html<<tr><td class="caption">User</td><td class="value">#(info.UserName)#</td></tr>>
	&html<<tr><td class="caption">Transaction?</td><td class="value">#(inTransaction)#</td></tr>>
	&html<<tr><td class="caption">Start/Execution time</td><td class="value" title="UTC timestamp: #(info.StartTimeUTC)#">#(info.StartTime)# (#(elapsed)#)</td></tr>>
	if $LD(info.Parameters,1) { // --- Display All 'info.Parameters' Values ---
		&html<<tr><td class="caption">Parameters</td><td class="value"><ol>>
		for paramPos=1:1:$LL(info.Parameters) { // --- Process All 'info.Parameters' Values ---
			set paramVal=$LG(info.Parameters,paramPos)
			set:$e(paramVal,*-1,*)=$$$ParameterTruncateSignal paramVal=paramVal_"... (Truncated)"
			&html<<li>#($$$HTMLENCODE(paramVal))#</li>>
		}

		&html<</ol></td></tr>>
	}
	&html<<tr><td class="caption">Statement</td><td class="value">>
	if $g(statement)'="" {
		set statement=$$$HTMLENCODE($zstrip(statement,"<>WC"))
		&html<<tt>#(statement)#</tt>>
	} else {
		set statement = $$$Text("statement text could not be retrieved")
		&html<<i>#(statement)#</i><br />>
	}
	// if this is a locally executing query, we can show the plan
	if localToThisServer {
		&html< <p align="right"><a href="../exp/%25CSP.UI.Portal.Dialog.SQLStatementDetails.zen?$NAMESPACE=#(info.Namespace)#&NAMESPACE=#(info.Namespace)#&STMTHASH=#(hash)#&OpenInTab=1" target="_new" title="Click to show the SQL Statement Plan & Details...">plan &amp; details</a></p>>
	}
	&html<</td></tr>>
	&html<<tr><td class="caption">Cached Query</td><td class="value">>
	try {
		set canSeeCQ = localToThisServer && $data(^[info.Namespace]rINDEX(info.CachedQuery_".1","INT")) && ($e(hash, 1, 7) '= "THROUGH")
	} catch {
		set canSeeCQ = 0
	}
	if canSeeCQ { 
		&html<<a href="../exp/%25CSP.UI.System.ViewCode.cls?$TYPE=rtn&FILENAME=#(info.CachedQuery)#.1.int&$NAMESPACE=#(info.Namespace)#" target="_new" title="Click to show the generated Cached Query .INT routine...">#(info.CachedQuery)#</a>>
	} else {
		&html<#(info.CachedQuery)#>
		if 'localToThisServer { &html< (on server #(info.Server)#)> }
	}
	&html<</td></tr>>
	
	if info.Parent'="" {
		// Parent structure: {Server}_"||"_{ProcessID}_"||"_{StatementIndexHash} (e.g. "server-name:port-number||PID||hash")
		//                   (Obtained from the 'INFORMATION_SCHEMA.CURRENT_STATEMENTS' table)
		set parentID=$$$LOWER(info.Parent)
		&html<<tr><td class="caption">Parent statement</td><td class="value"><a href="#" onclick="zenPage.selectParent('#(parentID)#');" title="Click to show the Parent SQL Statement...">#(parentID)#</a> (#(info.ParentType)#)</td></tr>>
	}

	if info.ChildStatements'="" { // --- Display {CurrentWorkerCount} ---
		set workerMsg="Worker"_$s(info.CurrentWorkerCount>1:"s",1:"")
		&html<<tr><td class="caption">#(workerMsg)#</td><td class="value">#(info.CurrentWorkerCount)#</td></tr>>
	}
	
	&html<</table>>
	
	// BDB940 - for the next bits of output we need to be in the namespace where the statement is executing
	try {
		set $namespace = info.Namespace
	} catch {
		// exit if for some reason we couldn't switch to this namespace. 
		return $$$OK
	}
		
	// BDB940 - add link to SQL Diagnostic logs if there are any we can find.
	if localToThisServer && stillRunning {
		// We'll look for the first %SQL_Diag.Result initiated at or right after this statement's start time by
		// the current process, which may already have finished by the time we get here.
		// Future optimization: limit this even further by filtering on the StatementID
		set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT TOP 1 %ID FROM %SQL_Diag.Result WHERE processId = ? AND createTime >= ? ORDER BY %ID ASC", pid, ##class(%PosixTime).DisplayToLogical(info.StartTimeUTC))
		if rs.%Next() {
			set diagLink = ..Link("%25CSP.UI.Portal.SQL.Logs.zen?$NAMESPACE="_info.Namespace_"&resultID="_rs.%GetData(1))
			&html<<p><a href="#(diagLink)#">Show SQL diagnostic logs for this statement</a></p>>
		}
	}
	
	if 'statCount {
		set (statCount, statAverage, statDeviation, statRowCount, statCommands) = $$$Text("no data yet")
	} else {
		set statAverage=$fn(statAverage,"",4)_" sec"
		set statDeviation=$fn(statDeviation,"",4)
		set statRowCount=$s(statCount:$fn(statRowCount\statCount,","),1:0)_" row(s)"
		set statCommands=$s(statCount:$fn(statCommands\statCount,","),1:0)_" commands"
	}
	
	// fetch daily stats
	set yesterday = $zd($h-1,3), lastWeek = $zd($h-7,3)
	&SQL(SELECT SUM(StatCount) AS StatCount, 
				SUM(StatTotal) AS StatTotal, 
				SUM(StatVariance*StatCount)/SUM(StatCount) AS StatVariance, 
				SUM(StatRowCount) AS StatRowCount,
				SUM(StatCommands) AS StatCommands 
			INTO :statCountW, :statTotalW, :statVarianceW, :statRowCountW, :statCommandsW
		 	FROM INFORMATION_SCHEMA.STATEMENT_DAILY_STATS 
		 	WHERE Statement = :hash AND Day BETWEEN %ODBCIN(:lastWeek) AND %ODBCIN(:yesterday))
		 	
	if (SQLCODE=0) && statCountW {
		set statAverageW=$fn(statTotalW/statCountW,"",4)_" sec"
		set statDeviationW=$fn($zsqr(statVarianceW),"",4)
		set statRowCountW=$s(statCountW:$fn(statRowCountW\statCountW,","),1:0)_" row(s)"
		set statCommandsW=$s(statCountW:$fn(statCommandsW\statCountW,","),1:0)_" commands"
	} else {
		set (statCountW, statAverageW, statDeviationW, statRowCountW, statCommandsW) = $$$Text("no data yet")
	}
	
	&html<<div class="titleBoxTitle" style="margin-top: 20px; margin-bottom: 10px;">Execution statistics</div>>
	&html<<table id="tblStats" class="DetailTable" border="0" cellspacing="0" cellpadding="0">>
	&html<<tr><td class="caption">&nbsp;</td><td class="caption">Overall</td><td class="caption">Last week</td></tr>>
	&html<<tr><td class="caption">Times executed</td><td class="value">#(statCount)#</td><td class="value">#(statCountW)#</td></tr>>
	&html<<tr><td class="caption">Average runtime</td><td class="value">#(statAverage)#</td><td class="value">#(statAverageW)#</td></tr>>
	&html<<tr><td class="caption">Runtime standard deviation</td><td class="value">#(statDeviation)#</td><td class="value">#(statDeviationW)#</td></tr>>
	&html<<tr><td class="caption">Average rowcount</td><td class="value">#(statRowCount)#</td><td class="value">#(statRowCountW)#</td></tr>>
	&html<<tr><td class="caption">Average commands</td><td class="value">#(statCommands)#</td><td class="value">#(statCommandsW)#</td></tr>>
	&html<</table>>
	quit $$$OK
}

/// Cancel the specified SQL Query...
Method CancelQuery(pid = "", SQLStatementID = "") As %Boolean [ ZenMethod ]
{
	RETURN:(pid="")||(SQLStatementID="") $$$OK  // 'pid' & 'SQLStatementID' must be specified!

	set tSC=$SYSTEM.SQL.CancelQuery(pid,SQLStatementID,2)
	
	if $$$ISERR(tSC) { // --- Display Error ---
		set errorCode=$$$GETERRORCODE(tSC)
		set errorMsg=$replace($s(errorCode=5521:$$$GETERRORMESSAGE(tSC,3),1:$$$GETERRORMESSAGE(tSC)),"'","\'")
		&js<alert('[Cancel Query] failed for the following reason: \n#(errorMsg)#')>
	}
	else { // --- SQL Query Successfully Cancelled ---
		&js<self.document.getElementById("tdProcessInfo").innerHTML = "#(pid)#, previously running on this instance <span style='color: red; float: right;'>Query Cancelled</span>";>
	}

	RETURN $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	// BDB917 - hide the Server column if this instance isn't part of a sharded cluster
	set ..isCluster = 0
	try {
		if $SYSTEM.Cluster.ClusterNamespace()'="" {
			set ..isCluster = 2
		} else {
			// otherwise, keep it simple
			set ..isCluster = ##class(Security.Services).IsEnabled($$$ServiceSharding)
		}
	} catch (ex) { }
	set ..%GetComponentById("colServer").hidden = '..isCluster
	
	Set ..%GetComponentById("lblDescription").value = $$$Text("The following is a list of actively running SQL statements")_" "_$s(..isCluster:$$$Text("for this sharded cluster"),1:$$$Text("for this instance"))_":"
	
	Quit $$$OK
}

}
