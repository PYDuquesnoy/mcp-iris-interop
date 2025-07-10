/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is for simple list pages that consist of only a ribbon and a table
Class EnsPortal.Template.listPage Extends EnsPortal.Template.standardPage [ Abstract, System = 4 ]
{

/// Does this page have refresh functionality?
/// Note that this value is ignored when <property>enableAutoRefresh</property> is false.
Property showRefresh As %Boolean [ InitialExpression = 0 ];

Property msgSelectItemToExport As %String [ InitialExpression = "Please select an item to export." ];

/// Is the user permitted to access the fileSelect popup?
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// Contents of the list page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<pane id="ListPane" paneName="ListPane"/>
<timer id="refreshTimer" ontimeout="zenPage.refreshTimeout(zenThis);" timeout="0"/>  
</pane>
}

/// Override this pane in order to add columns and parameters to the table.
/// Be sure to set id="table", queryName="Enumerate", and queryClass = the list page.
/// Include parameter "filter" in order for the filter to work.  
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<tablePane id="table"
queryClass="EnsPortal.Template.listPage"
queryName="Enumerate"
cellSpacing="2"
useSnapshot="true"
showZebra="true"
>
<parameter id="filter" value=""/>
<!--Query displayed on this list page -->
<parameter id="queryMethod"/>
<!--Class containing the query for this list page -->
<parameter id="queryClass"/>
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.  This is a wrapper around Query QueryMethod in class QueryClass.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "") [ SqlProc ]
{
}

/// Override this Method to pass more arguments to the class query 
ClassMethod EnumerateExecute(ByRef qHandle As %Binary, pFilter As %String = "", QueryMethod As %String, QueryClass As %String) As %Status
{
	Set tSC = $CLASSMETHOD(QueryClass, QueryMethod_"Execute", .qHandle)
	Set qHandle("Filter") = pFilter
	Set qHandle("QueryClass") = QueryClass
	Set qHandle("QueryMethod") = QueryMethod
	Quit tSC
}

ClassMethod EnumerateClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateExecute ]
{
$CLASSMETHOD(qHandle("QueryClass"),qHandle("QueryMethod")_"Close",.qHandle)
}

ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateExecute ]
{
	Set Filter = qHandle("Filter")
	Set QueryClass = qHandle("QueryClass")
	Set QueryMethod = qHandle("QueryMethod")
	Do {
		Set tSC = $CLASSMETHOD(QueryClass,QueryMethod_"Fetch", .qHandle, .Row, .AtEnd)
		If ((Row'="") && (Filter'="")) {
		 	Set StringRow = $listtostring(Row,$C(13))
		 	If $zcvt(StringRow,"L")'[$zcvt(Filter,"L") {
			 	Set Row = ""
		 	}
		 }
	}
	While(('AtEnd) && (Row=""))
	Quit tSC
}

/// User entered something into the searchbox. Re-load the table with filter value.
ClientMethod searchBoxHandler(pValue) [ Language = javascript ]
{
	var table = zen("table");
	zen('filter').setProperty('value',pValue);
	table.executeQuery();
}

ClientMethod doExport() [ Language = javascript ]
{
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	var tab = zen("table").getValue();
	if (tab.length <= 0) {
		alert($$$Text(zenPage.msgSelectItemToExport));
		return;
	}
 	parms = {
		Dir:zenPage.GetDefaultDir(),
		File:zenPage.GetDefaultFile(tab)+ '.xml',
		wildcard:'*.xml'
	}
	zenLaunchPopupWindow(
  	zenLink('%ZEN.Dialog.fileSelect.zen'),
 	this.addPopupSuffix('ExportFileSelection'),
  	'status,scrollbars,resizable,width=660,height=700',
  	parms);
}

ClientMethod doImport() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	parms = {
		Dir:zenPage.GetDefaultDir(),
		wildcard:'*.xml'
	}
	zenLaunchPopupWindow(
  	zenLink('%ZEN.Dialog.fileSelect.zen'),
  	this.addPopupSuffix('ImportFileSelection'),
  	'status,scrollbars,resizable,width=660,height=700',
  	parms);
}

/// Override this in order to use a different naming scheme for default filename 
ClientMethod GetDefaultFile(table) As %String [ Language = javascript ]
{
	return table.split(".").join("_");
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

Method FileExists(pFilename As %String) As %String [ ZenMethod ]
{
	Quit ##class(%File).Exists(pFilename)
}

ClassMethod Export(Filename As %String, Classname As %String) As %String [ ZenMethod ]
{
	Set tSC = $system.OBJ.Export(Classname_".cls",Filename,"/nodisplay")
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Else {
		Set tMsg = "1"
	}
	Quit tMsg
}

ClassMethod Import(Filename As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		// Redirect output to the null device to support verbose output loading and converting .BPL Studio documents
		Set tNullDevice = ##class(%Library.Device).GetNullDevice()
		If (tNullDevice) { 
			Set tIO = $IO
			Use tNullDevice 
		}
		Set tSC = $system.OBJ.Load(Filename,"/compile/nodisplay")
	}
	Catch {
		Set tSC = $$$SystemError
	}
	If ($get(tIO) '= "") && ($IO '= tIO) {
		Use tIO
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Else {
		Set tMsg = "1"
	}
	Quit tMsg
}

/// If auto-refresh is still on, refresh the table and restart the timer
ClientMethod refreshTimeout(timer) [ Language = javascript ]
{
	var chk = document.getElementById('refreshOn');
	if (chk && (chk.checked)) {
		zenPage.doRefresh();
		timer.startTimer(); // restart timer
	}
}

/// Reload diagram with a fresh copy.
ClientMethod doRefresh() [ Language = javascript ]
{
	icon = document.getElementById('iconRefresh');
	if (icon) {
		icon.style.backgroundColor = '#D0F8D0';
		zen('table').executeQuery();
		setTimeout(function() {
			icon.style.backgroundColor = '';
		}, 75);
	} else {
		zen('table').executeQuery();
	}
}

/// User chose a new Auto-Refresh value for the table; set a new timeout value and start the timer
ClientMethod changeRefresh() [ Language = javascript ]
{
	var chk = document.getElementById('refreshOn');
	var rate = document.getElementById('refreshRate');
	if (rate) {
		var val = parseInt(rate.value,10);
		if ((val < 5) || isNaN(val)) {
			val = 5;
		}
		rate.value = val;
		if (chk && (chk.checked)) {
			var timer = zen('refreshTimer'); //get timer
			timer.setProperty('timeout',val*1000); //set timeout
			timer.startTimer(); //restart timer
		// Otherwise don't start the timer and it will just sit there
		}
	}
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	If ..enableAutoRefresh && ..showRefresh {
		
		Set msgSeconds = $$$Text("refreshing interval in number of seconds (minimum is 5)")

		&html<
			<td style="padding-left:6px;width:30px;">
			<image id="iconRefresh" src="deepsee/loop_24.gif" style="position:relative;top:4px" class="icon" title="Refresh Table" onclick="zenPage.doRefresh();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
			</td>
			<td nowrap style="padding-left:5px;padding-right:20px;">
			<div nowrap>
				<span id="id_refresh" style="font-size:10pt;color:#606060;font-weight:bold;">#($$$TextHTML("Refresh:"))#</span>
				<input id="refreshOff" name="refresh" type="radio" checked/><span>#($$$Text("off"))#</span>
				<input id="refreshOn" name="refresh" type="radio" onclick="zenPage.changeRefresh();"/><span>#($$$Text("on"))#</span>
				<input style="padding-left:5px;" id="refreshRate" name="refreshRate" type="textbox" title="#(msgSeconds)#" size="2" value="5" onchange="zenPage.changeRefresh();"><span style="font-size:0.8em;" title="#(msgSeconds)#">&nbsp;#($$$Text("seconds"))#</span>
			</div></td>
			<td style="padding-right:20px;"></td>
		>
	}
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
/// Override to include buttons.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	// include a search box in the ribbon
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()
	Quit $$$OK
}

/// Adjust size of table on the page, so buttons don't scroll off page
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var table = zen('ListPane');
		var tableDiv = table.getEnclosingDiv();
		
		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th;
		
		if (hgt > 100) {
			// let table scroll while buttons remain fixed
			tableDiv.style.height = hgt + 'px';
			tableDiv.style.overflowY = "auto";
		}
		else {
			// the table would be too small to be of much use if we didn't allow entire page to scroll
			tableDiv.style.overflowY = "visible";
		}
		
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

}
