/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - SQL Tuen Table page.
Class %CSP.UI.Portal.SQL.TuneTable Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "SQL Table Statistics";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Development";

Property SCHEMANAME As %String(ZENURL = "SCHEMANAME");

Property TABLENAME As %String(ZENURL = "TABLENAME");

/// Current extent size when the page is loaded. Used to compare with the textbox value.
Property CurrentSize As %Integer;

Property lblCurrentTableSize As %ZEN.Datatype.string [ InitialExpression = {$$$TextHTML("Current Extentsize (per shard if table is sharded): ")} ];

Property IsTuned As %Boolean [ InitialExpression = 0 ];

Property iTimeoutInterval As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.note {
	color: rgb(218,72,72);	
}

/* custom font size for tableNavigatorBar */
.tnbrPagingButtons {
	font-size: 10px;
}
.tnbrFound {
	font-size: 10px;
}
/* @doc="Filter and page size control." */
.tnbrFilter {
	font-size: 10px;
}
.detailLabel {
	margin: 2px;
}

</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground { fill:white; stroke:white; }	
</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	width="100%" height="100%"
	title="#(%page.StdTitle)#"
>
<group layout="none">

<html id="htmlTitle" OnDrawContent="DrawSQLTitle"/>

</group>

<group width="100%" valign="top">
<pane paneName="contentPane" width="100%"/>
</group>

</page>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
<button caption="Close" controlClass="commandButton" title="Exit this dialog" onclick="zenPage.doClose();" valign="bottom"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<hgroup valign="top">
<vgroup id="editorPane" valign="top">
<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white; stroke-width:2; border:none;">
<tabBar id="tabBar" tabCaptions=":Selectivity:Map Size"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>
<vgroup id="page_1" hidden="false" enclosingStyle="padding:10px;">
<hgroup labelPosition="left" enclosingStyle="padding-top:10px;">
<label id="expTableSize"/>
<link id="linkOptions" caption="edit" title="Edit the table extentsize" href="javascript:zenPage.toggleOptions();" />
<spacer width="2"/>
<hgroup id="idExtentSize" labelPosition="left" hidden="true" containerStyle="border:1px dashed rgb(67,67,67);">
<text id="txtExtentSize" label="Override Extentsize:" title="Tune Table will calculate if left alone." labelStyle="padding-left:4px;" size="6"/>
<button id="btnSaveExtentSize" caption="Save" onclick="zenPage.doSaveTableSize();"/>
</hgroup>
<button id="btnTuneTable" caption="Tune Table" controlClass="commandButton" onclick="zenPage.doTuneTable();" valign="bottom"/>
</hgroup>
<vgroup labelPosition="left" enclosingStyle="padding-top:6px;padding-bottom:10px;">
<checkbox id="chkKeepClassUpToDate" label="Keep class up to date:" 
title="If checked, the class definition will be updated with the new EXTENTSIZE and SELECTIVITY values, but the class definition will be kept as up-to-date. "/>
</vgroup>
<hgroup valign="top" labelPosition="left">
<tableNavBar showPageSize="true" showMaxRows="true" tablePaneId="table1"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table1');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table1');"
/>
</hgroup>
<tablePane id="table1"
queryClass="%SQL.Manager.Catalog" 
queryName="FieldCurrentSelectivity"
fixedHeaders="false"
maxRows="1000"
multiSelect="false"
onselectrow="zenPage.doSelectRow(1);"
OnExecuteResultSet="ExecuteRS"
pageSize="20"
showZebra="true"
useSnapshot="true"
valign="top"
valueColumn="FIELD_NAME"
>
<column colName="FIELD_NAME" header="Field Name" title="Click a row to edit selectivity"/>
<column colName="NOTES" header="Notes"/>
<column colName="SELECTIVITY" header="Selectivity"/>
<column colName="OUTLIER_SELECTIVITY" header="Outlier Selectivity" />
<column colName="OUTLIER_VALUE" header="Outlier Value" />
<column colName="AVERAGE_FIELD_SIZE" header="Average Field Size" />
<parameter value=""/>
<parameter value=""/>
</tablePane>
</vgroup>
<vgroup id="page_2" hidden="true" enclosingStyle="padding:10px;">
<hgroup valign="top" labelPosition="left" cellStyle="padding:2px;">
<tableNavBar showPageSize="true" showMaxRows="true" tablePaneId="table2"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'table2');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'table2');"
/>
</hgroup>
<tablePane id="table2"
queryClass="%SQL.Manager.Catalog" 
queryName="MapBlockCount"
fixedHeaders="false"
maxRows="1000"
multiSelect="false"
onselectrow="zenPage.doSelectRow(2);"
OnExecuteResultSet="ExecuteRS"
pageSize="20"
showZebra="true"
useSnapshot="true"
valign="top"
valueColumn="SQL_MAP_NAME"
>
<column colName="SQL_MAP_NAME" header="SQL Map Name"/>
<column colName="SIZE_MB" header="Size (MB)"/>
<column colName="SIZE_TYPE" header="Size Type"/>
<parameter value=""/>
<parameter value=""/>
</tablePane>
</vgroup>
</vgroup>
<spacer width="2"/>
<vgroup id="propertyPane" valign="top">
<html id="propertyTitle"></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabDetails" caption="Details">
<spacer height="3"/>
<vgroup id="defaultDetails" label="Select an item to view details"/>
<html id="htmlPropertyTitle" OnDrawContent="DrawPropertyTitle" seed=""></html>

<vgroup id="propertyForm1" cellStyle="padding:4px 10px 4px 10px;" hidden="true">
<hgroup align="center">
<button id="btnSave1" caption="Save" title="Save changes" controlClass="commandButton" onclick="zenPage.doSave('1');"/>
</hgroup>
<text id="txtItemSelectivity" label="Selectivity" hint="Enter a selectivity percentage from > 0% though 99.999%"/>
<text id="txtItemOutSelectivity" label="Outlier Selectivity" hint="Enter an outlier selectivity percentage from > 0% though 99.999%"/>
<text id="txtItemOutValue" label="Outlier Value" hint="Enter a datavalue - use double quotes for a string"/>
<text id="txtItemAverageFieldSize" label="Average Field Size" hint="Enter the average field size for this field's data"/>

<html id="htmlHistogram" OnDrawContent="DrawHistogram" />
</vgroup>

<vgroup id="propertyForm2" cellStyle="padding:4px 10px 4px 10px" hidden="true">
<hgroup align="center">
<button id="btnSave2" caption="Save" title="Save changes" controlClass="commandButton" onclick="zenPage.doSave('2');"/>
</hgroup>
<text id="txtItemSizeMB" label="Map Size (MB)" hint="Enter a positive number or leave it empty for Tune Table to calculate it."/>
</vgroup>

</tab>
</tabGroup>
</vgroup>
</hgroup>
</pane>
}

/// timeout function
ClientMethod timeout() [ Language = javascript ]
{
	if (!this._jobNumber) {
		return;	
	}
	var proxy = this.CheckJobStatus(this._jobNumber,this.SCHEMANAME,this.TABLENAME);
	switch (proxy.status) {
		case 'running':
		case 'suspended':
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
			break;
		case 'done':
		case 'error':
		case 'terminated':
			var LastSize = zen("txtExtentSize").getValue();
			if (LastSize != proxy.ExtentSize) {
				if (LastSize !== '') {
					zen("txtExtentSize").setValue(proxy.ExtentSize);
				}
				zen("expTableSize").setProperty("label",this.lblCurrentTableSize + proxy.ExtentSize);
			}
			var table = zen("table1");
			table.executeQuery(0);
			var table = zen("table2");
			table.executeQuery(0);
			this.IsTuned = 1;
			this.resetMsg();			
			this.toggleButtons('enable');
			break;
	}
}

/// hide the two panes during Tuning until Tuning is finished.
/// user can still click the Close button to quit out.
ClientMethod toggleButtons(flag) [ Language = javascript ]
{
	var propDiv = zen('propertyPane').getEnclosingDiv();
	var editDiv = zen('editorPane').getEnclosingDiv();
	if (flag == 'enable') {
		propDiv.style.display = 'block';
		editDiv.style.display = 'block';
	} else {
		propDiv.style.display = 'none';
		editDiv.style.display = 'none';
	}
}

ClientMethod doSelectRow(option) [ Language = javascript ]
{
	this.resetMsg();
	try {
		var table = zen("table"+option);
		var selectedIndex = table.getProperty("selectedIndex");
		if (selectedIndex == -1) return;
		var itemId = table.getValue();
		zen("propertyForm"+option).setHidden(false);
		var html = zen("htmlPropertyTitle");
		html.setProperty('seed',itemId);

		var rowData = table.getRowData(selectedIndex);
		if (!rowData) return;
		if (option == 1) {
			zen("txtItemSelectivity").setValue(rowData["SELECTIVITY"]);
			zen("txtItemOutSelectivity").setValue(rowData["OUTLIER_SELECTIVITY"]);
			zen("txtItemOutValue").setValue(rowData["OUTLIER_VALUE"]);
			zen("txtItemAverageFieldSize").setValue(rowData["AVERAGE_FIELD_SIZE"]);
			var sc = zen("htmlHistogram").setProperty("seed", itemId);
			zen("htmlHistogram").refreshContents();
		} else {
			zen("txtItemSizeMB").setValue(rowData["SIZE_MB"]);
		}
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error');
	}
}

ClientMethod doTuneTable() [ Language = javascript ]
{
	this.resetMsg();
	this.clearForm();
	var LastSize = zen("txtExtentSize").getValue();
	var keep = zen("chkKeepClassUpToDate").getValue() ? 1 : 0;
	var proxy = this.SetSelValues(this.CurrentSize,LastSize,keep,this.SCHEMANAME,this.TABLENAME);
	if (proxy.ErrorMessage.length > 0) {
		this.showMsg(proxy.ErrorMessage,1);	
	} else {
		this.showMsg(proxy.Message,0);
		this._jobNumber = proxy.TuneID;
		zen('timer').setProperty('timeout',this.iTimeoutInterval);
		zen('timer').startTimer();
		this.toggleButtons('disable');
	}
}

ClientMethod doSave(option) [ Language = javascript ]
{
	this.resetMsg();
	var table = zen("table"+option);
	var selectedIndex = table.getProperty("selectedIndex");
	if (selectedIndex == -1) return;
	var itemId = table.getValue();
	var ok = "";
	var keep = zen("chkKeepClassUpToDate").getValue() ? 1 : 0;
	switch(option) {
		case '1':
			var selectivity = zen("txtItemSelectivity").getValue();
			var outSelectivity = zen("txtItemOutSelectivity").getValue();
			var outValue = zen("txtItemOutValue").getValue();
			var outAverageFieldSize = zen("txtItemAverageFieldSize").getValue();
			var ok = this.SaveData(this.SCHEMANAME, this.TABLENAME, keep, itemId, selectivity, outSelectivity, outValue, outAverageFieldSize);
			this.IsTuned = 1;
			break;
		case '2':
			var blockCount = Math.round(zen("txtItemSizeMB").getValue() * 1024 / 2 ) ; // convert from MB to block count, and round to nearest integer; YWH027
			var pass = true;
			if (blockCount!=""&&!this.validateRequired(zen('txtItemSizeMB'),pass,"N",true,0)) pass = false; // change the size limit in MB to >0; YWH027
			if (!pass) return;
			var ok = this.SaveMap(this.SCHEMANAME, this.TABLENAME, keep, itemId, blockCount);
			this.IsTuned = 1;
			break;
	}
	if (ok != 1) {
		this.showMsg(ok,1);	
	} else {
		// do not clear the previous selection so if user wants to change the number again they don't 
		// have to click the row again.
		//table.setProperty("selectedIndex",-1);
		table.executeQuery(0);
		return;	
	}
}

ClientMethod doSaveTableSize() [ Language = javascript ]
{
	this.resetMsg();
	var tableSize = zen("txtExtentSize").getValue();
	var keep = zen("chkKeepClassUpToDate").getValue() ? 1 : 0;
	var ok = this.SaveTableSize(this.SCHEMANAME, this.TABLENAME, tableSize, keep);
	if (ok != 1) {
		this.showMsg(ok,1);	
	} else {
		// update the Current Table Extentsize
		zen("expTableSize").setProperty("label",this.lblCurrentTableSize + tableSize);
	}
}

ClientMethod doClose() [ Language = javascript ]
{
            if (!this.IsTuned) {
                        zenPage.cancelPopup();
            } else {
                        this.firePopupAction('ok',1);
            }
}

/// Clear form 
ClientMethod clearForm() [ Language = javascript ]
{
	zen("table1").setProperty("selectedIndex",-1);
	zen("txtItemSelectivity").setValue('');
	zen("txtItemOutSelectivity").setValue('');
	zen("txtItemOutValue").setValue('');
	zen("txtItemAverageFieldSize").setValue('');
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
		if (this.SCHEMANAME == "") return;
		this.adjustSizes();				
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	var option;
	for ( var i=0; i<2; i++ ) {
		option = i + 1;
		if ( i == index ) {
			var table = zen("table"+option);
			var selectedItem = table.getValue();
			// if user has not selected any item from the table then do not show propertyForm yet.
			zen("propertyForm"+option).setHidden(selectedItem>-1);
			// show table under selected tab now
			zen("page_"+option).setHidden(false);
			// display selected item name as propertyForm title
			var html = zen("htmlPropertyTitle");
			html.seed = selectedItem;
			html.refreshContents();
		} else {
			// hide other tabs and propertyForm
			zen("page_"+option).setHidden(true);
			zen("propertyForm"+option).setHidden(true);
		}				
	}
}

/// Show or hide Edit Table Extentsize fields.
ClientMethod toggleOptions() [ Language = javascript ]
{
	var group = zen("idExtentSize");
	var newOption = !group.getProperty("hidden");
	group.setHidden(newOption);
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var propDiv = zen('propertyPane').getEnclosingDiv();
		var editDiv = zen('editorPane').getEnclosingDiv();

		propDiv.style.display = 'block';

		propWidth = (winWidth<900) ? 250 : 280;
		var editorWid = winWidth - propDiv.offsetWidth - 15;
		editorWid = Math.max(editorWid,100);
		propDiv.style.width = propWidth + 'px';
		editDiv.style.width = editorWid + 'px';
		
		var propHeight = winHeight - 180;
		propHeight = Math.max(propHeight,100);
		propDiv.style.height = propHeight + 'px';

		var tabBodyHgt = winHeight - 220;
		tabBodyHgt = (tabBodyHgt < 1 ? 1 : tabBodyHgt);
		zen('propertyTabs').setBodySize(tabBodyHgt,propDiv.offsetWidth-2);

		zen("svgTabArea").setProperty("width",editorWid-2);
		zen("tabBar").setProperty("width",editorWid-2);
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tPageName = ..%GetPageName()
	For n = 1,2 Do ..%GetNavTableState(tPageName_"^table"_n)
	
	Set ..%GetComponentById("Text1").value = $$$TextHTML("Tune Table is a utility that examines the data in a table and gathers table statistics, such as the ExtentSize (the number of rows in the table) and the Selectivity of each field (the percentage of rows returned for a given value). It also generates the size for each SQL map.")
	Set %page.CurrentSize = ##class(%SQL.Manager.Catalog).GetCurrentTableExtentSize(%page.SCHEMANAME,%page.TABLENAME)
	Set ..%GetComponentById("txtExtentSize").value = ""
	Set ..%GetComponentById("expTableSize").label = %page.lblCurrentTableSize _ %page.CurrentSize
	Quit $$$OK
}

Method DrawSQLTitle(pSeed) As %Status
{
	Set tDict = "<h2>"_$$$HTMLENCODE(%page.SCHEMANAME)_"."_$$$HTMLENCODE(%page.TABLENAME)_"</h2>"
	Set tNamespace = $$$TextHTML("Namespace: ")_..EscapeHTML($namespace)
	Set tImg = ..Link("/csp/broker/portal/sql_query_48.gif")
	Set tTitle = $$$TextHTML("Table Statistics")
	&html<<table width="100%" border="0" cellspacing="2">
	<tr><td>&nbsp;&nbsp;<img id="imgLogo" src="#(tImg)#" height="70"/></td>
	<td><div width=10/>&nbsp;&nbsp;</td>
	<td width="40%">#(tDict)#</td><td>#(tNamespace)#</td>
	<td class="ribbonTitle" style="height:70px;width:250px;">&nbsp;&nbsp;<nobr>#(tTitle)#</nobr>&nbsp;&nbsp;</td>
	</tr>
	<tr>
	<td colspan="6"><div style="border-top:1px solid black;">&nbsp;</div></td>
	</tr>
	</table>>
	Quit $$$OK
}

/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SQL Table Statistics")
}

ClassMethod SaveData(SchemaName, TableName, KeepClassUpToDate, field, selectivity, outSelectivity, outValue, AverageFieldSize) As %String [ ZenMethod ]
{
	Set tSC = ##Class(%SQL.Manager.Catalog).SetFieldSelectivity(SchemaName, TableName, field, selectivity, KeepClassUpToDate, outSelectivity, outValue, AverageFieldSize)	
	If $$$ISERR(tSC) Set tSC = $$$HTMLErrorMsg(tSC)
	Quit tSC
}

ClassMethod SaveMap(SchemaName, TableName, KeepClassUpToDate, field, blockCount) As %String [ ZenMethod ]
{
	Set tSC = ##Class(%SQL.Manager.Catalog).SetMapBlockCount(SchemaName, TableName, field, blockCount, KeepClassUpToDate)				
	If $$$ISERR(tSC) Set tSC = $$$HTMLErrorMsg(tSC)
	Quit tSC
}

/// Method for executing the process query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSC = pRS.Execute(%page.SCHEMANAME,%page.TABLENAME) 
	Quit tSC
}

/// User clicked Tune Table button. Now calculate table extentsize, blockcounts, and selectivity and save.
ClassMethod SetSelValues(CurrentSize, ExtentSize, KeepClassUpToDate, SCHEMANAME, TABLENAME) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim EventData,EventDesc As %Library.String
	Set EventDesc = "Tune Table"
	Set EventData = SCHEMANAME _ "."_TABLENAME
	$$$SMPAuditChange
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ErrorMessage = ""
	Set tProxy.Message = ""
	Set tParms("Schema") = SCHEMANAME
	Set tParms("Table") = TABLENAME
	Set tParms("ExtentSize") = ExtentSize
	Set tParms("NAMESPACE") = $ZU(5)
	Set tParms("KeepClassUpToDate") = KeepClassUpToDate
	Set tParms("ClearValues") = 0
	Set tParms("LogFile") = ""
	Set tParms("DISPLAY") = 0
	Set tProxy.TuneID = $J
	Set msg1 = $$$TextHTML("Tune Tables started in the background.")
	Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
	Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("TuneTable",tParms("NAMESPACE"),.tParms,.tItmes,.tJob)
	If $$$ISERR(status) {
		Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
		Set tProxy.ErrorMessage = $System.Status.GetErrorText(status)
	} Else {
		Set tProxy.TuneID = tJob
		Set tProxy.Message = $$$FormatText($$$Text("Tune Table is in process (%1). Please wait..."), tJob)
	}
	RETURN tProxy
}

/// This is called when user clicks Save for Table Extentsize they edited.
ClassMethod SaveTableSize(SCHEMANAME, TABLENAME, ExtentSize, KeepClassUpToDate) As %String [ ZenMethod ]
{
	Try {
		Set tSC = ##Class(%SQL.Manager.Catalog).SetTableExtentSize(SCHEMANAME, TABLENAME, ExtentSize, KeepClassUpToDate)
		If $$$ISERR(tSC) Set tSC = $$$HTMLErrorMsg(tSC)	
	}
	Catch(ex) {
		Set tSC = $$$TextHTML("Save table extentsize failed.")
	}
	Quit tSC
}

Method DrawPropertyTitle(pPropertyForm) As %Status
{
	If pPropertyForm = "" Quit $$$OK
	&html<<center><div class="detailLabel">#(..EscapeHTML(pPropertyForm))#</div></center>>
	Quit $$$OK
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navPageSizeChanged(value, tableId) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,tableId);
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navMaxRowsChanged(value, tableId) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value,tableId);
}

/// Used to Save tableNavBar values, add MapType to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, ptableId As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_"^"_ptableId,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

ClassMethod CheckJobStatus(PID, SCHEMANAME, TABLENAME) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.msg = ""
	// check if background job has errorred
	If $G($$$TempMgtPortalTask(PID,"Status")) = $$$Text("ERROR") {
		Set proxy.status = "error" 
		Set proxy.msg = $G($$$TempMgtPortalTask(PID,"Details"))_" "_$G($$$TempMgtPortalTask(PID,"ERROR"))
	} Else {
		// check if it is finished
		Set Status = $G($$$TempMgtPortalTask(PID,"FinishStatus"))
		// if it has not finished, check if the process has been terminated or suspended
		If Status '= 1 {
			Set tCurrentNS = $ZU(5)
			Set $Namespace = "%SYS"
			Set tPOBJ = ##class(%CSP.UI.Portal.ProcessDetails).GetPIDOBJ(PID)
			If '$IsObject(tPOBJ) {
				Set proxy.status = "terminated"
				Set proxy.msg = $$$FormatText($$$Text("Process '%1' no longer exists"),PID)
			} Else {
				If tPOBJ.CanBeSuspended = 0 {
					Set proxy.status = "suspended"
					Set proxy.msg = $$$FormatText($$$Text("Process '%1' has been suspended."),PID)
				} Else {
					Set proxy.status = "running"
				}
			}
			Set $Namespace = tCurrentNS
		} Else {
			Set proxy.ExtentSize = ##class(%SQL.Manager.Catalog).GetCurrentTableExtentSize(SCHEMANAME,TABLENAME)
			Set proxy.status = "done"
		}
	}
	Quit proxy
}

Method DrawHistogram(seed) As %Status [ Internal, ServerOnly = 1 ]
{
	set sc = $$$OK
	try {
		quit:seed=""
		set colName = seed
		set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT * FROM INFORMATION_SCHEMA.COLUMN_HISTOGRAMS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ? ORDER BY BUCKET_POSITION", ..SCHEMANAME, ..TABLENAME, colName)
		
		if 'rs.%Next() {
			set colName = $$$HTMLENCODE(colName)
			&html<No histogram data for column #(colName)#>
			quit
		}
		&html<<p class="zenLabel">Histogram</p>
			  <p>Bucket width: #((rs.%Get("BUCKET_WIDTH")*100\1))#%<br/>Interpolatable: #(rs.%Get("INTERPOLATABLE"))#<br/>Number of null buckets: #(rs.%Get("NULL_BUCKETS"))#</p>
			  <table>
			  <tr><th>Percentile</th><th style="padding-left: 10px;">Value</th></tr>>
		
		do {
			set value = $$$HTMLENCODE(rs.%Get("VALUE"))
			&html<<tr><td align="right">#(rs.%Get("PERCENTILE")*100\1)#%</td><td style="padding-left: 10px;">#(value)#</td></tr>>	
		} while rs.%Next()
		&html<</table>>
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	quit sc
}

}
