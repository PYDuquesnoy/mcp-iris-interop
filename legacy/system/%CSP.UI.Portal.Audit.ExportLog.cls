/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Export Audit Log
Class %CSP.UI.Portal.Audit.ExportLog Extends %CSP.UI.Portal.Audit.ActionTemplate [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Export Audit Log";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.ExportLog.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Export Audit Log";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property Action As %String [ InitialExpression = "Export" ];

XData formPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px" label="Export to file">
<hgroup cellStyle="padding:4px;">
<text id="FileName" size="50" value="AuditExport.xml"/>
<button id="FileNameBrowse" caption="Browse..." onclick="zenPage.doBrowse('FileName');"/>
</hgroup>
</pane>
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen(popupName).setValue(value);		
	}
}

/// Launching a file selector window. 
ClientMethod doBrowse(fieldID) [ Language = javascript ]
{
	var Dir = zen(fieldID).getValue();
	var wildcard = "*";
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=1");
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
}

ClientMethod saveToCookie(filename) [ Language = javascript ]
{
	var expires = '; expires=Tuesday, 31-Dec-2030 23:59:59 GMT';
	document.cookie = "LastFileUtilSysAuditExport.csp=" + filename + expires;
}

ClassMethod FileExists(filename As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("To export items from the audit log, fill out the following form and press [ OK ]:")
	
	Set ..%GetComponentById("DaysOption").displayList = $$$TextHTML("Export all items")_","_$$$TextHTML("Export all items older than this many days:")
	
	Set LastSaveFile = %request.GetCookie("LastFileUtilSysAuditExport.csp")
	If LastSaveFile '= "" Set ..%GetComponentById("FileName").value = LastSaveFile

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Export Audit Log")
}

}
