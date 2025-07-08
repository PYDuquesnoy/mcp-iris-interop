/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - SQL Performance Tool - Troubleshooting Report Generator
Class %CSP.UI.Portal.SQL.QButtons.ReportGenerator Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

/// Switch namespace $NAMESPACE is present
Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.ReportGenerator.zen";

Parameter HELPADDRESS = "Home,Generate SQL Troubleshooting Report";

/// Displayed name of this page.
Parameter PAGENAME = "SQL QButtons Report Generator";

/// Security requirement
Parameter RESOURCE = "%Development";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property msgWRC As %ZEN.Datatype.string [ InitialExpression = {$$$Text("Please enter a WRC number that already exist in the table or select existing IDs from the table.")} ];

Property OpenDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.OpenDetails.cls",,1)} ];

Property SaveQueryOutputPage As %ZEN.Datatype.string [ InitialExpression = {$P(..Link("%25CSP.UI.Portal.SQL.QButtons.SaveQueryOutput.zen"),"?$NAMESPACE",1)} ];

Property ViewProcessPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/op/%25CSP.UI.Portal.ProcessDetails.zen",,1)} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
.EditForm {
	width: 800px;	
}	
#propertyPane {
	background: white;
	height: 449px;
	width: 550px;
	border-right: none;
	border-bottom: none;
	display: none;
}
#propertyTitle {
	height: 300px;
	width: 100%;
	overflow:auto;
}
	
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding-top:10px;padding-left:20px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:10px;"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<form id="form1" enclosingClass="EditForm" labelPosition="left">

<hgroup label="WRC Number:" labelClass="normal">
<text id="WRCNum" name="WRCNum" size="8" value="" onchange="zenPage.checkWRCResult();"/>
<label label=" (Required)" labelClass="helpText"/>
</hgroup>
<spacer height="4"/>
<hgroup label="SQL Statement:" labelClass="normal">
<textarea id="QueryText" 
rows="5" 
cols="90" 
valign="top" 
value="" onkeyup="return zenPage.toggleClearText(zenThis);"
/>
<image id="imageClearQueryText" src="csp/broker/deepsee/ds2_circle_x_44.png" width="16" height="16" onclick="zenPage.doClearQueryText();" title="Clear SQL statement" valign="top" hidden="true"/>
</hgroup>

<checkbox id="includeresults" caption="Include query results data?" captionClass="normal" value="0" hidden="true"/>
<checkbox id="chkBackground" caption="Run Save Query process in the background" captionClass="zenLabel" value="1" hint=" (Recommended as Save Query will calculate stats that may take a long time to run)"/>
</form>
<spacer height="4"/>
<hgroup id="content">
<vgroup id="editorPane" label="Currently Saved Queries" labelClass="caption"  valign="top">

<tablePane id="table"
valueColumn="ID"
queryClass="%SQL.Manager.QButtons.Base"
queryName="SavedQueries"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="true"
maxRows="50"
showValueInTooltip="false"
showZebra="true"
useSnapshot="true"
initialExecute="true"
onselectrow="zenPage.doSelectRow();"
>
<column colName="ID" header="ID" hidden="false" />
<column colName="WRCNumber" title="WRC number" header="WRC Number"/>
<column colName="IncludeResults" header="Result Data?" hidden="true"/>
<column colName="TimeInserted" title="Time inserted" header="Time Inserted (GMT)"/>
<column colName="QueryCompileDecomposedStatus" title="Query compile status" header="Status"/>
<column colName="AllowDelimitedIdentifiers" title="Saved with 'Allow Delimited Identifiers'" header="Delim. Ident."/>
<column colName="DefaultSchema" title="Saved with Default Schema" header="Schema" />
<column colName="QueryStatement" header="SQL Statement" OnDrawCell="DrawQueryText" />
<column onclick="zenPage.openDetails('#(%query.ID)#');" linkCaption="Details" link="#"/>
</tablePane>

<button id="btnClearWRC" caption="Clear" title="Delete saved queries for the WRC" onclick="zenPage.doClear();"/>

</vgroup>
</hgroup>

<button id="btnViewProcess" caption="View Process" controlClass="commandButton" onclick="zenPage.doViewProcess();" hidden="true"/>
<iframe id="outputSaveQuery" hidden="true" valign="top" containerStyle="padding-top:10px;"/>

</pane>
}

/// Write upto 80 characters of query statement in tablePane
Method DrawQueryText(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw query text upto 80 characters.
	Set tText = $E(%query(pName),1,80) _ $S($L(%query(pName))>80:"...",1:"")
	&html<&nbsp;#(..EscapeHTML(tText))#>
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.adjustSizes();
	this.checkWRCResult();
	zen("WRCNum").focus();
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var table = zen('table').getEnclosingDiv();
		var editDiv = zen('editorPane').getEnclosingDiv();	
		var halfWinWidth = (winWidth / 2) - 25;
		var halfWinHeight = (winHeight / 2) - 25;
		
		editDiv.style.height = halfWinHeight - 40 + 'px';

		var frame = zen("outputSaveQuery");
		frame.setProperty("width",halfWinWidth + "px");
		frame.setProperty("height",150 +"px");
	
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This method checked whether the WRC number user entered exists in the table 
/// The Generate button is disabled if it is the saved queries does not include the WRC.
ClientMethod checkWRCResult() As %Boolean [ Language = javascript ]
{
	var WRCNum = zen("WRCNum").getValue();
	if (this.validateWRCNum(WRCNum)) {
		if (!this.WRCRowExists(WRCNum)) {
			this.disableCommandButton("btnGenerate");
			return false;
		} else {
			this.enableCommandButton("btnGenerate");
			return true;
		}
		this.msgReset();
	}
	return false;
}

/// If user selected one or more checkboxes, then get the WRC numbers from that
/// Otherwise check to see if user entered a WRC number in the WRC Number field.
ClientMethod doClear() [ Language = javascript ]
{
	this.resetMsg();
	var ok = false;
	var selectedIDs = this.getSelectedList();
	if (selectedIDs != '') {
		if (confirm($$$Text("Are you sure you want to delete all the selected queries?"))) {
			ok = this.ClearClick('',selectedIDs);
		} else {
			return false;
		}
	} else {
		var WRCNum = zen("WRCNum").getValue();
		if (zenTrim(WRCNum) === '') {
			this.showMsg(this.msgWRC);
			zen("WRCNum").focus();
			return false;
		}
		if (this.checkWRCResult()) {
			var WRCNum = zen("WRCNum").getValue();
			var msg = $$$FormatText($$$Text("Are you sure you want to delete all queries associated with WRC '%1'?"),WRCNum);
			if (confirm(msg)) {
				ok = this.ClearClick(WRCNum,'');
			} else {
				return false;	
			}
	    }
	}
	if (ok.error == '') {
		this.refreshTable();	
	} else {
		this.showMsg(ok.error,true);
		zen("WRCNum").focus();
	}
}

ClientMethod getSelectedList() [ Language = javascript ]
{
	var table = zen("table");
	var selectedRows = table.getProperty("selectedRows");
	var selectedArray = selectedRows.split(',');
	var slist = '';
	for (var i=0; i<selectedArray.length; i++) {
		if (selectedArray[i] != '') {
			if (slist != '') {
				slist = slist + ',';
			}
			slist += selectedArray[i];	
		}
	}
	return slist;
}

/// Show Plan and other details on a separate tab
ClientMethod openDetails(PID) [ Language = javascript ]
{
	url = this.OpenDetailsPage + '$NAMESPACE=' + encodeURIComponent(this.NAMESPACE) + '&PID=' + encodeURIComponent(PID);
	var win = window.open(url,'ViewDetails');
	win.focus();
}

ClientMethod doGenerate() [ Language = javascript ]
{
	var slist = this.getSelectedList();
	var WRCNum = zen("WRCNum").getValue();
	if (!slist) {
		if (!this.validateWRCNum()) {
			this.showMsg(this.msgWRC,true);
			zen("WRCNum").focus();
			return;
		}
	}
	var parms = {
			WRCNUM: WRCNum,
			SelectedIDs: slist,
			$NAMESPACE: this.NAMESPACE
	};
	//open dialog for export criteria
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.SQLReportGenerator.zen','Generate','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod refreshTable() [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery(1);
	this.checkWRCResult();
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.validateWRCNum()) {
		var WRCNum = zen("WRCNum").getValue();
		var QueryText = zen("QueryText").getValue();
		if(zenTrim(QueryText)==='') {
			this.showMsg($$$Text("Please enter a SQL Statement!"));
			zen("QueryText").focus();
			return false;	
		};
		var includeresults = (zen("includeresults").getValue() == true) ? 1 : 0;
		var chkBackground = ((zen("chkBackground").getValue()==true)) ? 1 : 0;
		if (!chkBackground) {
			var ok = this.SaveClick(QueryText,WRCNum,includeresults);
			if (ok == -1) {
				return;	
			}
			if (ok != 1) {
				this.showMsg('SaveClick returned error: '+ok,true);	
			} else {
				this.refreshTable();
			}
		} else {
			// start process in background
			// display background status 
			this.toggleFields(true);
			delete this._jobNumber;
			var link = this.SaveQueryOutputPage + "?namespace="+encodeURIComponent(this.NAMESPACE);
			zen('outputSaveQuery').setProperty('src',link);
			var proxy = this.JobSaveQuery(QueryText,WRCNum,includeresults);
			this._proxy = proxy;
			if (proxy.jobNumber) {
				// start timer to check status
				// if background process is finished, display result
				this._jobNumber = proxy.jobNumber;
				var output = zen('outputSaveQuery');
				var timer = zen('timer');
				timer.setProperty('timeout',2000);
				timer.startTimer();
			} else {
				if (proxy.error) {
					this.showMsg(proxy.error,true);
				}
			}
		}
	} else {
		this.showMsg(this.msgWRC,true);
		zen("WRCNum").focus();
	}
}

ClientMethod toggleFields(hideflag) [ Language = javascript ]
{
	zen("outputSaveQuery").setHidden(!hideflag);
	zen("btnViewProcess").setHidden(!hideflag);
	zen("content").setHidden(hideflag);
	zen("WRCNum").setDisabled(hideflag);
	zen("QueryText").setDisabled(hideflag);
	//zen("includeresults").setDisabled(hideflag);
	zen("chkBackground").setDisabled(hideflag);
	zen("btnClearWRC").setHidden(hideflag);
	if (hideflag) {
		this.disableCommandButton("btnSave");
		this.disableCommandButton("btnGenerate");
	} else {
		this.enableCommandButton("btnSave");
		this.enableCommandButton("btnGenerate");
	}
}

/// This function is executed when SaveQuery is processed to run in the background. 
ClientMethod timeout() [ Language = javascript ]
{
	if (!this._jobNumber) {
		alert("no jobNumber!");
		return;	
	}
	var proxy = this.CheckJobStatus(this._jobNumber);
	var link = this.SaveQueryOutputPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&jobNumber="+this._jobNumber;
	link += "&status=" + proxy.status + "&msg=" + proxy.msg;
	switch (proxy.status) {
		case 'running':
		case 'suspended':
			//zen('outputSaveQuery').setHidden(false);
			if (this._proxy) {
				zen('outputSaveQuery').setProperty('src',link);				
			}
			var timer = zen('timer');
			timer.setProperty('timeout',4000);
			timer.startTimer();
			break;
		case 'done':
		case 'error':
		case 'terminated':
			if (this._proxy) {
				zen('outputSaveQuery').setProperty('src',link);
				delete this._jobNumber;
			} else {
				// this should never happen
				alert('cannot find this._proxy -- unable to continue.');
			}
			this.toggleFields(false);
			this.refreshTable();
			break;
	}
}

ClientMethod doSelectRow() [ Language = javascript ]
{
	this.resetMsg();
	var table = zenPage.getComponentById("table");
	var selectedIndex = table.getProperty("selectedIndex");
	if (table.getRowData(selectedIndex)) {
		var rowData = table.getRowData(selectedIndex);
		if (rowData && rowData["WRCNumber"]) {
			zen('WRCNum').setValue(rowData["WRCNumber"]);
		}
	}
	return;
}

ClientMethod validateWRCNum() As %Boolean [ Language = javascript ]
{
	var wrcnumstring = zen("WRCNum").getValue();
	//Make sure the wrc number only has digits and no whitespaces
	if (/\D/.test(wrcnumstring) || /\s/.test(wrcnumstring) || wrcnumstring == "") {
		return false
	}
	return true
}

/// Clear data by WRC. If single wrcnum is passed in, clear that.
/// If a list of selected IDs are passed in, clear each one in the list.
ClassMethod ClearClick(wrcnum As %String = "", selectedIDs As %String = "") As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.error = ""
	If selectedIDs '= "" {
		Set tCnt = 1
		Set tItem = $P(selectedIDs,",",tCnt)
		While tItem '= "" {
			Set tSC = ##class(%SQL.Manager.QButtons.Base).ClearRow(tItem)
			If $$$ISERR(tSC) {
				Set tProxy.error = tProxy.error _ $S(tProxy.error '= "": ", ",1:"") _ $System.Status.GetErrorText(tSC)
			}
			Set tCnt = tCnt + 1
			Set tItem = $P(selectedIDs,",",tCnt)
		}		
	} Else {
		Set tSC = ##class(%SQL.Manager.QButtons.Base).ClearData(wrcnum)
		If $$$ISERR(tSC) {
			Set tProxy.error = $System.Status.GetErrorText(tSC)
		}
	}
	Quit tProxy
}

ClassMethod RemoveRow(delId As %String) As %Integer [ ZenMethod ]
{
	Set sc = ##class(%SQL.Manager.QButtons.Base).ClearRow(delId)
	If $$$ISERR(sc) Set sc = $System.Status.GetErrorText(sc)
	Quit sc
}

ClassMethod SaveClick(QueryText, WRCNum, includeresults) As %String [ ZenMethod ]
{
	Set sc = ##class(%SQL.Manager.QButtons.Base).InsertQuery(QueryText,WRCNum,includeresults)
	If $$$ISERR(sc) Set sc = $System.Status.GetErrorText(sc)
	Quit sc
}

ClassMethod WRCRowExists(WRCNum) As %Boolean [ ZenMethod ]
{
	Quit ##class(%SQL.Manager.QButtons.Base).WRCRowExists(WRCNum)
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Enter a WRC number and a SQL statement you wish to diagnose. Click 'Save Query' for each statement entered. When you are finished with saving all the queries, then click 'Generate Report'.")

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSQL",$$$Text("SQL Home"),$$$Text("Goto the SQL Home page"),"zenPage.gotoPToolsPage('sqlhome');")
	Set pCommands(2) = $LB("btnSave",$$$Text("Save Query"),$$$Text("Save statement and query"),"zenPage.doSave();")
	Set pCommands(3) = $LB("btnGenerate",$$$Text("Generate Report"),$$$Text("Generate report for the WRC number of the saved queries"),"zenPage.doGenerate();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Generate Report")
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("SQL Performance Tools","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.QButtons.ReportGenerator.zen");
		this.NAMESPACE = value;
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	}
}

/// Draw html for details title: SQL Statement
Method DrawDetailsTitle(pId) As %Status
{
	Quit:pId="" $$$OK
	
	Set QueryText = ##class(%SQL.Manager.QButtons.Base).FindQueryById(pId)	
	If QueryText '= "" {
		&html<<h4 nowrap>#($$$Text("SQL Statement:"))#</h4>>
		&html<#(..EscapeHTML(QueryText))#>
	}
	Quit $$$OK
}

ClassMethod JobSaveQuery(query, WRCNum, includeresults) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tParms("Username") = $Username
	Set tParms("Namespace") = $ZU(5)
	Set tParms("QueryText") = query
	Set tParms("WRCNum") = WRCNum
	Set tParms("includeresults") = includeresults
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("JobSaveQuery",$zu(5),.tParms,.tItems,.tJob)
	If $$$ISERR(status) {
		Set tError = $System.Status.GetErrorText(status)
		Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg(tError)
		Set proxy.status = 0
		Set proxy.error = tError
	} Else {
		Set proxy.status = 1
		Set proxy.jobNumber = tJob
		Set proxy.Username = $Username
		Set proxy.msg = $$$TextHTML("Save Query process started in the background.")
	}
	Quit proxy
}

/// View details of a background process for Show Plan
ClientMethod doViewProcess() [ Language = javascript ]
{
	if (!this._jobNumber) {
		this.showMsg($$$Text("Process number unavailable!"),true);
		return;
	}
	var PID = this._jobNumber;
	var url = this.ViewProcessPage + "PID=" + PID + "&DISPLAYID=" + PID + "&$ID1=" + PID;
	var win = window.open(url,'ViewProcessDetails');
	win.focus();
}

ClientMethod doClearQueryText() [ Language = javascript ]
{
	var queryText = zen("QueryText");
	queryText.setValue('');
	this.toggleClearText(queryText);
	queryText.focus();
}

}
