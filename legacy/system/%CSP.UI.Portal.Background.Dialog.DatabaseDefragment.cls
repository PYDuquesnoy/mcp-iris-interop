/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Background.Dialog.DatabaseDefragment Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Background.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Background.Dialog.DatabaseDefragment.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Defragment";

Parameter RESOURCE = "%Admin_Operate:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// ID for edit. DBName for this page.
Property DBName As %String(ZENURL = "DBName");

/// DBDirectory passed in.
Property Directory As %String(ZENURL = "Directory");

Property WarningMessage As %String;

Property SysBGTaskId As %String;

Property disabledStyle As %ZEN.Datatype.style [ InitialExpression = "background-image:none;background:#D0D0D0;cursor: not-allowed;" ];

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
.message {
	color: #000000;
	font-size: 12px;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<form>
<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
 <label id="DatabaseName" label="Database name:" value="#(%page.DBName)#" enclosingClass="normal"/>
 <label id="Directory" label="Directory:" value="#(%page.Directory)#" enclosingClass="normal"/>
 <label id="Size" label="Current size:" enclosingClass="normal"/>
 <label id="Warning" controlClass="redText"/>
 <html>
  <div id="idMessage" class="message"/>
 </html>
 <html><hr size="1"/></html>
 </group>
 </form>
    <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>

</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.WarningMessage) {
		var message = document.getElementById("idMessage");
		if (message) {
			message.innerHTML = this.WarningMessage;
		}
	}
	if (!zenPage.getComponentById("idError").getProperty('hidden')) {
		var btnOK = zenPage.getComponentById('btnOK');
		if (btnOK) {
			btnOK.setProperty('disabled',true);
			btnOK.setProperty('controlStyle',this.disabledStyle);
		}	
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ErrorComp = ..%GetComponentById("idError")
	Set ErrorComp.seed = ""
	
	Set tSC = ##class(SYS.Database).DefragmentCheck(%page.Directory,.dbobj,.datasize,.endfree,.freespace,.expreq,.overmax)
 	If $$$ISERR(tSC) {
		Set ErrorComp.seed = $System.Status.GetErrorText(tSC)
	} Else {
		If (dbobj.Mounted = 0) || ($$$NotAllowDBCompTrunDefrag(dbobj)) {
			Set ErrorComp.seed = 1
		}
	}
	If ErrorComp.seed '= "" {
		Set ErrorComp.hidden = 0
		Set ..%GetComponentById("form").hidden = 1
	} Else {
		If datasize {
			Set %page.WarningMessage = $$$FormatText($$$Text("There are %1 MB of data to be processed."),datasize)
			Set ..%GetComponentById("Size").value = datasize _ "MB"
		} Else {
			Set %page.WarningMessage = $$$TextHTML("There is less than 1MB of data to be processed.")
		}
		If (expreq) {
			Set %page.WarningMessage = %page.WarningMessage _ "<div>" _ $$$FormatText($$$Text("There are %1 MB of free space at the end of the database, and defragmentation requires an additional %2 MB to operate."), endfree, expreq)_"</div>"
			If overmax {
				Set %page.WarningMessage = %page.WarningMessage _ "<div>" _ $$$TextHTML("That amount would exceed the maximum size of the database.")_"</div>"
			}
			If (freespace-endfree)>20 {
				Set %page.WarningMessage = %page.WarningMessage _ "<div>" _ $$$FormatText($$$Text("There is a total of %1 MB freespace in the database. You can go back and compact the free space to make more usable for defragmentation."),freespace)_"</div>"
				If overmax && ((freespace-endfree)>overmax) {
					Set %page.WarningMessage = %page.WarningMessage _ "<div>" _ $$$TextHTML("However, that alone would not be enough.")_"</div>"
				}
			}
			If ('overmax) {
				Set %page.WarningMessage = %page.WarningMessage _ "<div>" _ $$$FormatText($$$Text("You can continue, in which case the database may expand to accomodate up to %1 MB of additional space needed for defragmentation to operate."),expreq)_"</div>"
			}
		}
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Defragment Database")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $ZCVT(..DBName,"O","HTML")
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed = 1 {
		Set text = $$$TextHTML("Unable to continue. Database is not mounted or is read-only.")
	} Else {
		Set text = $ZCVT(seed,"O","HTML")
	}
	&html<<div class="ErrorBox">#(text)#</div>>
	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var DatabaseName = this.DBName;
		var Directory = this.Directory;
		var ok = 0;
		var proxy = this.StartDefrag(DatabaseName,Directory);
		if (proxy.error) {
			alert(proxy.error);
		}
		if (proxy.SysBGTaskId) {
			this.SysBGTaskId = proxy.SysBGTaskId;
			ok = 1;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	if (ok == 1) {
		return true;
	}
	return false;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.SysBGTaskId;
}

/// Start background job to defragment a selected directory
ClassMethod StartDefrag(pDBName, pDirectory) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.jobId = ""
		Set tProxy.SysBGTaskId = ""
		Kill tParms
		Set tParms("NAMESPACE") = "%SYS"
		Set tParms("DBName") = pDBName
		Set tParms("Directory") = pDirectory
 		Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("DefragmentDB",tParms("NAMESPACE"),.tParms,,.tJob)
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)
	} Else {
		Set tProxy.jobId = +$G(tJob)
		For i = 1:1:5 {
			H 1
			Set tProxy.SysBGTaskId = $Get(^|"%SYS"|IRIS.Temp.MgtPortalTask(tJob,"SysBGTaskId"))
			Quit:tProxy.SysBGTaskId'=""
		}
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error = "Error occurred in StartDefrag: "_$ZE
	Quit tProxy
}

}
