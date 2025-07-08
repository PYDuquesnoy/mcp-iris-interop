/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Log File Viewer.
/// Display contents of the DeepSee log file for the current namespace.
/// 
Class %DeepSee.UI.LogViewer Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Log Viewer";

Parameter DOCBOOKID = "D2MODEL_cube_build_errors";

XData Style
{
<style type="text/css">
/* SMP reskin
body {
	background: rgb(240,240,240);
}
*/
#logFile {
	border: 1px solid #808080;
	background: white;
	overflow: auto;
	margin-left: 20px;
}

#logFile pre {
	color: #404040;
	padding: 3px;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee"
>
<html id="logFile" OnDrawContent="DrawLogFile"/>
</pane>
}

/// Draw contents of log file pane.
Method DrawLogFile(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFileName = ##class(%DeepSee.Utils).%GetLogFileName()

		If ('##class(%File).Exists(tFileName)) {
			&html<<pre>>
			Write $$$Text("Log file does not exist: "),!
			Write tFileName,!
			&html<</pre>>
			Quit
		}
		&html<<a href="#bottom" name="top" class="portalServerLink">#($$$TextHTML("[Goto Bottom]"))#</a>>
		&html<<pre>>
		Write tFileName,!
		Write $ZDT($ZU(188),3),!			// DTB332 - Use $ZU function which accounts for local time
		Write "-----------------------",!

		Set tFile = ##class(%File).%New(tFileName)
		Set tSC = tFile.Open("RS")
		If $$$ISERR(tSC) Quit
		While ('tFile.AtEnd) {
			Write $ZCVT(tFile.ReadLine(),"O","HTML"),!
		}

		Write "###",!
		&html<</pre>>
		&html<<a href="#top" name="bottom" class="portalServerLink">#($$$TextHTML("[Goto Top]"))#</a>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Log File Viewer")
}

/// Get the name for the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Log File Viewer")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Log Viewer")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdRefresh",$$$Text("Refresh"),$$$Text("Reload contents of log file"),"zenPage.refreshLog();")
	Set pCommands(2) = $LB("cmdDelete",$$$Text("Delete"),$$$Text("Delete log file"),"zenPage.deleteLog();")
	Quit $$$OK
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.LogViewer.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	}
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var logFile = zen('logFile');
		var divLog = logFile.getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();
		var h = winHeight - (25 + th);

		if (divLog) {
			divLog.style.width = winWidth - (25) + 'px';
			divLog.style.height = h + 'px';
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Reload contents of file.
ClientMethod refreshLog() [ Language = javascript ]
{
	zen('logFile').refreshContents();
}

/// Delete the log file.
ClientMethod deleteLog() [ Language = javascript ]
{
	if (confirm($$$Text('Do you wish to delete the DeepSee log file?'))) {
		var msg = zenPage.DeleteLogFile();
		if ('' !== msg) {
			alert(msg);
		}
		zen('logFile').refreshContents();
	}
}

/// Delete the log file.
Method DeleteLogFile() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tSC = ##class(%DeepSee.Utils).%KillLogFile()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

}
