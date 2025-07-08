/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Cluster Settings
Class %CSP.UI.Portal.Config.Cluster Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.Advanced) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.Cluster.zen";

Parameter HELPADDRESS = "Home,Configuration,Cluster Settings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "Cluster Settings";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Cluster" ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<select id="JoinCluster" label="JoinCluster" valueList="0,1"
displayList="false,true" onchange="zenPage.doModified();" showEmpty="false"
 hint="Identify whether this configuration is part of a cluster." />
<text id="CommIPAddress" label="CommIPAddress" size="50"
hint="IP Address to advertise in the PIJ to the other cluster members."
 onchange="zenPage.doModified();"/>
<hgroup label="pijdir" cellVAlign="top" hint="Note: Changes to this directory will require a InterSystems IRIS restart." hintClass="brownnote">
<text id="pijdir" showLabel="false" size="50"
hint="Directory to store the cluster image journal."
 onchange="zenPage.doModified();"/>
<spacer width="5px"/>
<button id="Browse" caption="Browse..." onclick="zenPage.doBrowse();"/>
</hgroup>
</group>
</form>
</pane>
}

/// Launching a file selector window. 
ClientMethod doBrowse() [ Language = javascript ]
{
	var Dir = zen("pijdir").getValue();
	var wildcard = "*";
	var url = "%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=1";
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=600,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("pijdir").setValue(value);
		this.doModified();	
	}
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..lblTitle = $$$Text("Use the form below to edit cluster settings for the system:")
	
	Set tSC = ..PopulateFields()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Cluster Settings")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
