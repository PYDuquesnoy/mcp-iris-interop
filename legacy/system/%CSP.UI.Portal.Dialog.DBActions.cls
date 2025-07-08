/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Actions for Local Databases: Mount DB, etc.
Class %CSP.UI.Portal.Dialog.DBActions Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.DBActions.zen";

Parameter RESOURCE = "%Admin_Operate:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Mount DB";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property Action As %ZEN.Datatype.string(ZENURL = "ACTION");

Property DBName As %ZEN.Datatype.string(ZENURL = "DBName");

Property Directory As %ZEN.Datatype.string(ZENURL = "Dir");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<vgroup id="idMount" cellStyle="padding:10px;">
<checkbox id="chkClustered" caption="Clustered" value="0"/>
<checkbox id="chkReadOnly" caption="Read Only" value="0"/>
<checkbox id="chkCatchup" caption="Start Mirror Catchup?" value="1"/>
</vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
    zen("btnOK").focus();
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If %page.Action = "Mount"
	Quit $$$Text("Mount Database")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		zen("result").setValue("");
		var proxy = new zenProxy();
		proxy.Directory = this.Directory;
		proxy.ReadOnly = zen("chkReadOnly").getValue();
		proxy.Clustered = zen("chkClustered").getValue();
		proxy.MirrorCatchup = zen("chkCatchup").getValue();
		var ok = this.Mount(proxy);
		if (ok != 1) zen("result").setValue(ok);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	if (ok == 1) return true;
	return false;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tmsg = ""
	Set ..%GetComponentById("idMount").label = $$$FormatText($$$Text("Mount %1 in the following Mode:"),%page.DBName)
	Set cluster = ##Class(%SYS.ClusterInfo).NodeStatus()
	If cluster = "This system is not part of a cluster" Set ..%GetComponentById("chkClustered").hidden = 1
	If '##class(SYS.Database).%ExistsId(%page.Directory) {
		Set tmsg = $$$Text("Database no longer exists.")
	} Else {
		Set dbOBJ = ##class(SYS.Database).%OpenId(%page.Directory,,.Status)
		If '$$$ISOK(Status) {
			Set tmsg = Status
		} Else {
			If dbOBJ.Mirrored = 0 || dbOBJ.MirrorActivationRequired || dbOBJ.InActiveMirror Set ..%GetComponentById("chkCatchup").hidden = 1
			Set ClusterMountMode = dbOBJ.ClusterMountMode
			Set Mounted = dbOBJ.Mounted
			Set ReadOnly = dbOBJ.ReadOnly
			If cluster = "",ClusterMountMode = 1 {
				 Set ..%GetComponentById("chkClustered").value = 1
			}
			If ReadOnly = 1 {
				Set ..%GetComponentById("chkReadOnly").value = 1
				Set ..%GetComponentById("chkReadOnly").disabled = 1
			}
			If Mounted = 1 Set tmsg = $$$TextHTML("Database is already mounted.")
		}
		Kill dbOBJ
	}
	If tmsg '= "" {
		Set ..%GetComponentById("result").value = tmsg
		Set ..%GetComponentById("btnOK").disabled = 1
	}
	Quit $$$OK
}

/// Mount a DB.
ClassMethod Mount(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tmsg = 1
	If '##class(SYS.Database).%ExistsId(pProxy.Directory) {
		Set tmsg = $$$TextHTML("Database no longer exists.")
		Quit tmsg
	}
	Set dbOBJ = ##class(SYS.Database).%OpenId(pProxy.Directory,,.Status)
	If '$$$ISOK(Status) {
		Set tmsg = Status
		Quit tmsg
	}
	Set Mounted = dbOBJ.Mounted
	Kill dbOBJ
	If Mounted = 0 {
		Set Status = ##class(SYS.Database).MountDatabase(pProxy.Directory,pProxy.ReadOnly,pProxy.Clustered,pProxy.MirrorCatchup)
		If Status '= 1 Set tmsg = ..EscapeHTML($System.Status.GetErrorText(Status))
	}
	Quit tmsg
}

}
