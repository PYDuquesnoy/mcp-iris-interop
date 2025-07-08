/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This page allows to print execute query result to a printer.
Class %CSP.UI.Portal.SQL.PrintQuery Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "PrintQuery";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.PrintQuery.zen";

Parameter RESOURCE = "%Development";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Print Query";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Switch namespace for this page: 
Parameter AUTONS As BOOLEAN = 1;

/// Namespace passed in from URL.
Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

/// History Id passed in from URL.
Property HistoryId As %String(ZENURL = "$ID1");

/// Save to file name
Property FileName As %String;

Property RuntimeMode As %ZEN.Datatype.string(ZENURL = "RuntimeMode") [ InitialExpression = "2" ];

Property Dialect As %ZEN.Datatype.string(ZENURL = "Dialect") [ InitialExpression = "Nothing" ];

Property ObjectSelectMode As %Integer(ZENURL = "ObjectSelectMode") [ InitialExpression = 0 ];

Property MaxRows As %ZEN.Datatype.string(ZENURL = "MaxRows") [ InitialExpression = "1000" ];

Property ShowRowNum As %ZEN.Datatype.boolean(ZENURL = "ShowRowNum") [ InitialExpression = 0 ];

/// Whether to execute the SQL query in the foreground [Passed in from URL]
Property Foreground As %ZEN.Datatype.boolean(ZENURL = "Foreground") [ InitialExpression = 0 ];

Property msgSelect As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a file name.")} ];

Property msgValidate As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("File already exists. Overwrite the existing file?")} ];

Property CurrentQueryID As %ZEN.Datatype.integer [ Internal ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
a.link {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px; 
	font-weight: bold;
	padding-left: 4px;
	text-decoration: underline; 
}
a.link:visited {
	color: #00A09A;
}
a.link:hover {
	color: #00A09A;
}
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />
<vgroup cellStyle="padding-top:2px;" containerStyle="padding:10px;">
<hgroup cellStyle="padding-right:2px;">
<button caption="Close" onclick="zenPage.doClose();" valign="top"/>
<button caption="Print" title="Print the current page. Click to select a printer" onclick="zenPage.doPrint();" valign="top"/>
<checkbox id="chkExport" caption="Export to File" captionClass="normal" title="Export query results to a file. Click to select options." onclick="zenPage.show('groupExport');" valign="top"/>
<vgroup id="groupExport" labelPosition="left" hidden="true" valign="top"  enclosingStyle="padding:4px;background:#F1F1F1;">
<select id="selDisplayMode" label="File Format" labelClass="normal" title="Select a file format" showEmpty="false" 
displayList="xml,html,pdf,txt,csv" 
valueList="0,1,2,99,100" 
value="2"
onchange="zenPage.updateFileExt(zenThis.value);"
/>
<hgroup cellVAlign="bottom" label="File Name" labelClass="normal" labelPosition="left" title="Enter a directory and filename. If no directory is entered, the manager Temp directory will be used.">
<text id="txtFileName" size="70" value="queryText" hint="File Format is always used as the file extension in the export." hintClass="helpText" title="You may leave the file extension out."/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect();" valign="top"/>
</hgroup>
<button caption="Export" title="Click to start exporting job in the background" onclick="zenPage.doSave();"/>
</vgroup>
</hgroup>
<vgroup id="idResult" hidden="true">
<label id="idFileName" label="The export task will be run in the background."/>
<link id="idFileLink" caption="Click here to view the background tasks page." href="/csp/sys/%25CSP.UI.Portal.BackgroundTasks.zen"/>
</vgroup>
<link caption="Query" href="javascript:zenPage.show('show');"/>
<vgroup id="show" hidden="false">
<label id="QueryText"/>
</vgroup>

<link caption="Result" href="javascript:zenPage.show('htmlResult');"/>
<label id="resultStatus" />
<html id="htmlResult" OnDrawContent="DrawHTML" />

</vgroup>
</page>
}

/// Prepare to start printing
ClientMethod doPrint() [ Language = javascript ]
{
	window.print();
}

/// User clicked the Browse button.
ClientMethod browseSelect() [ Language = javascript ]
{
	var File = zen("txtFileName").getValue();
	var wildcard = this.getWildcard(zen("selDisplayMode").getValue());
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(File)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

ClientMethod getWildcard(value) [ Language = javascript ]
{
	if (value == 0) return "*.xml";
	if (value == 1) return "*.html";
	if (value == 2) return "*.pdf";
	if (value == 99) return "*.txt";
	if (value == 100) return "*.csv";
	return ""
}

/// User changed File Format. Update the file extension in the file name.
ClientMethod updateFileExt(Format) [ Language = javascript ]
{
	var newFileName = this.GetFile(Format,zen("txtFileName").getValue());
	zen("txtFileName").setValue(newFileName);
}

/// Prepare to start export
ClientMethod doSave() [ Language = javascript ]
{
	var DisplayMode = zen("selDisplayMode").getValue();
	// make sure that the extension matches the File Format selected in case user has changed it.
	this.updateFileExt(DisplayMode);

	var FileName = zen("txtFileName").getValue();
	var ok = this.ValidateFile(FileName);
	if (ok == 0) {
		alert(this.msgSelect);
		zen("txtFileName").focus();
		return;
	}
	if (ok == 2) {
		if (!confirm(this.msgValidate)) {
			zen("txtFileName").focus();
			return;
		}
	}
	var ok = this.StartExport(this.HistoryId,FileName,DisplayMode,this.RuntimeMode,this.Dialect,this.ObjectSelectMode);
	this.getComponentById("idResult").setHidden(false);
	this.getComponentById("idFileName").setProperty("value",FileName);
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			zen("txtFileName").setValue(value);
		}
	} catch (ex) {
		alert("Error: " + ex);
	}
}

ClientMethod doClose() [ Language = javascript ]
{
	this.cancelPopup();
}

/// Show or hide the other information
ClientMethod show(name) [ Language = javascript ]
{
	var nameObj = zenPage.getComponentById(name);
	nameObj.setProperty("hidden",!nameObj.getProperty("hidden"));
	if (name == "groupExport") {
		// if user checks the Export checkbox, show or hide the current result to make the page clearner.
		var flag = 	nameObj.getProperty("hidden");
		zen("htmlResult").setHidden(!flag);
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set ..%GetComponentById("htmlResult").label = $$$Text("Namespace: ")_$G(%request.Data("$NAMESPACE",1))
	If ..HistoryId = "" Set ..HistoryId = $G(%session.Data($Username,"SQL","HistoryId"))
	Set Query = ##class(%CSP.UI.Portal.SQL.Home).GetText(..HistoryId)
	//Set ..%GetComponentById("htmlResult").seed = Query
	Set ..%GetComponentById("QueryText").value = Query
	Set LastSaved = $G($$$IRISTempMgt($UserName,"LastFile","SQL","ExportQuery"))
	If LastSaved = "" {
		// For the first time user, default to pdf file
		Set LastSaved = $LB(2,##class(%File).NormalizeFilename("exportQuery")_".pdf")	
	}
	Set LastDisplayMode = $LG(LastSaved,1)
	Set LastSaveFile = $LG(LastSaved,2)
	Set ..%GetComponentById("selDisplayMode").value = LastDisplayMode
	Set ..%GetComponentById("txtFileName").value = LastSaveFile
	Set EventDesc = "Print Query Result"
	Set EventData = "Query text: "_$$$CRLF_Query
	$$$SMPAuditExecute
	quit $$$OK
}

/// Prepare for background export of the file.
ClassMethod StartExport(pHistoryId, pFileName, pDisplayMode, pRuntimeMode, pDialect, pObjectSelectMode) As %Integer [ ZenMethod ]
{
	Set $$$IRISTempMgt($UserName,"LastFile","SQL","ExportQuery") = $LB(pDisplayMode,pFileName)
	Set tParms("NAMESPACE") = $namespace
	Set tParms("FileName") = pFileName
	Set tParms("DisplayMode") = pDisplayMode
	Set tParms("HistoryId") = pHistoryId
	Set tParms("RuntimeMode") = pRuntimeMode
	Set tParms("Dialect") = pDialect
	Set tParms("ObjectSelectMode") = pObjectSelectMode
	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("QueryExport",$namespace,.tParms,.tJob)
	If $$$ISERR(status) Do ##class(%CSP.UI.SQL.ExImWizardResultPage).LogMsg($System.Status.GetErrorText(status))
	Quit 1
}

/// Return 0 if file is directory; 2 if file exists.
ClassMethod ValidateFile(FileName) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(FileName) Quit 0
	If ##class(%File).Exists(FileName) Quit 2

	Quit 1
}

/// Return file name with new extension
ClassMethod GetFile(Format, FileName) As %String [ ZenMethod ]
{
	Quit:FileName="" FileName
	Set Mode = $Case(Format,"0":"xml","1":"html","2":"pdf","99":"txt",:"csv")
	If $L(FileName,".")<2 Quit FileName_"."_Mode
	Set NewFile = $P(FileName,".",1,$L(FileName,".")-1)_"."_Mode
	Quit NewFile
}

Method DrawHTML(pText As %String(MAXLEN="")) As %Status
{
	quit:pText="" $$$OK
	quit:..CurrentQueryID="" $$$OK
	
	if $g(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"interface"))="Foreground" {
		// Foreground execution
		set sc = ..StartQueryExecution(0,..CurrentQueryID,%page.RuntimeMode,%page.Dialect,%page.ObjectSelectMode,%page.ShowRowNum,%page.MaxRows)  // MRP1304
	} else {
		// Background execution: results are waiting in 
		// ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")
		quit:'$d(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")) $$$OK
		for i = 1:1:$g(^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data")) {
			write ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"data",i),!
		}
		set sc = $$$OK
	}
	kill:..CurrentQueryID'=0 ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID)  // Retain foreground information global; Kill background information global!
	set ..CurrentQueryID=""
	quit sc
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String) As %Status
{
	&js<var sc = zen('htmlResult').setProperty("seed", "done");
		//zen('htmlResult').refreshContents();
		zen('resultStatus').setHidden(true);>
}

ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	set tStatus = $zconvert(pStatus,"O","JS")
	&js<zen('resultStatus').setProperty("label","#(tStatus)#");>
}

ClassMethod StartQueryExecution(pRunInBackground As %Boolean = 1, pQueryID As %Integer, pRuntimeMode As %String, pDialect As %String, pObjectSelectMode As %Integer, pShowRowNum As %Boolean, pMaxRows As %Integer) As %Status
{
#define dump(%c) set ^IRIS.Temp.ExecuteQuery($username,pQueryID,"data",$i(^IRIS.Temp.ExecuteQuery($username,pQueryID,"data"))) = %c

	if pRunInBackground { new %inBackground set %inBackground=1 }
	set tSC=$$$OK
	try {
		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Executing query")_"...")
		Set ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"TaskID") = +$job
		
		merge tSessionData = ^IRIS.Temp.ExecuteQuery($username,pQueryID,"sessionData")

		// BDB927 
		set pSQL = ^IRIS.Temp.ExecuteQuery($Username,pQueryID,"FullSQL")
		
		Set tAccStat = 0
		Do ##class(%CSP.UI.Portal.SQL.Utils).InitCollectStats(.tAccStat)

		Set tResult = ##class(%CSP.UI.Portal.SQL.Utils).SQLExecuteQuery(pSQL, .tClassName, pRuntimeMode, pDialect, pObjectSelectMode,,.tDiskRead,.StatementType,.tAccStat,.tSessionData,pQueryID,.pRuntimeClassName)

		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Fetching query result")_"...")

		Set tDrawTab = 0
		Do ##class(%CSP.UI.Portal.SQL.Utils).DrawResult(tResult,tDrawTab,pShowRowNum,.tAccStat,pMaxRows,pQueryID)

		do:pRunInBackground ..%SetBackgroundMethodStatus($$$Text("Rendering result")_"...")

		If $G(tClassName) '= "" {
			$$$dump("<br/><div valign='top'>"_$ZDT($h,3)_"&nbsp;&nbsp;"_$$$TextHTML("Routine: ")_$$$HTMLENCODE(tClassName)_$s($g(pRuntimeClassName)'="":$$$TextHTML(", ")_$$$HTMLENCODE(pRuntimeClassName),1:"")_"</div>")
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		do:pRunInBackground ..%SetBackgroundMethodStatus("ERROR: "_$system.Status.GetErrorText(tSC))
	}
	do:pRunInBackground ..%EndBackgroundMethod()
	Quit $$$OK
}

Method StartQuery(pSQL As %String, foreground As %Boolean = 0) As %Boolean [ ZenMethod ]
{
	if foreground { // --- Store Foreground Execution Query Output in Slot 0 --- [MRP1305]
		set ..CurrentQueryID=0  // Slot 0 reserved for Foreground Execution!
		kill ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID)   // Tabula Rasa!
		set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID)=1  // Acquire Slot
	}
	else { // --- Find a Free Slot to Store Background Execution Query Output --- [BDB933]
		for { // --- Acquire a '..CurrentQueryID' Slot ---
			lock +^IRIS.Temp.ExecuteQuery($username):0   // Acquire Top-Level Global LOCK!
			continue:'$test  // Lock already Acquired!
			
			set currentQueryID=$o(^IRIS.Temp.ExecuteQuery($username," "),-1)+1
			set ^IRIS.Temp.ExecuteQuery($username,currentQueryID)=1  // Acquire Slot
			set ..CurrentQueryID=currentQueryID
			lock -^IRIS.Temp.ExecuteQuery($username)  // Unlock Top-Level Global!
			quit
		}
	}
	
	// BDB836	
	kill ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"sessionData")
	merge ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"sessionData") = %session.Data($username,"SQL")
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"mlconfiguration")=$system.Context.SQL().MLConfiguration	// record current process's ML Configuration, use the same one in the backgroupd process
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"FullSQL") = pSQL
	set ^IRIS.Temp.ExecuteQuery($username,..CurrentQueryID,"interface")=$CASE(foreground,1:"Foreground",:"Background")
	quit $s(foreground:$$$OK, 1:..%RunBackgroundMethod("StartQueryExecution", 1, ..CurrentQueryID, %page.RuntimeMode, %page.Dialect, %page.ObjectSelectMode, %page.ShowRowNum, %page.MaxRows))
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
 	if (this.Foreground == true) { // --- Execute SQL Query in the Foreground ---
		var sc = zenPage.StartQuery(zen('QueryText').getValue(),1);
		sc = zen('htmlResult').setProperty("seed", "done");
		//zen('htmlResult').refreshContents();
		zen('resultStatus').setHidden(true);
 	}
 	else { // --- Execute SQL Query in the Background ---
		var sc = zenPage.StartQuery(zen('QueryText').getValue(),0);
 	}
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Print Query")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
