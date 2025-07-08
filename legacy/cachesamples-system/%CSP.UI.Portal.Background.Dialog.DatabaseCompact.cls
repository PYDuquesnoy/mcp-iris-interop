/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Background.Dialog.DatabaseCompact Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Background.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Background.Dialog.DatabaseCompact.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Compact";

Parameter RESOURCE = "%Admin_Operate:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// ID for edit. DBName for this page.
Property DBName As %String(ZENURL = "DBName");

/// DBDirectory passed in.
Property Directory As %String(ZENURL = "Directory");

Property SysBGTaskId As %String;

/// Total available freespace.
Property FreeSpace As %String;

/// Amount free at end
Property EndFree As %Integer;

/// Style applied to buttons when automatically disabled.
Property disabledStyle As %ZEN.Datatype.style [ InitialExpression = "background-image:none;background:#D0D0D0;cursor: not-allowed;" ];

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
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
 <label id="DatabaseName" label="Database Name:" value="#(%page.DBName)#" enclosingClass="normal"/>
 <label id="Directory" label="Directory:" value="#(%page.Directory)#" enclosingClass="normal"/>
 <label id="Size" label="Current size:" enclosingClass="normal"/>
 <label id="FreeSpace" label="Total available free space:" enclosingClass="normal"/>
 <label id="EndFree" label="Free space at end of file:" enclosingClass="normal"/>
 <text id="txtTarget" label="" size="10" hintClass="helpText"/> 
 <label id="Warning" controlClass="redText"/>
 <html><hr size="1"/></html>
 </group>

 </form>
    <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	
	if (zen('txtTarget').getProperty('hidden')) {
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
	
	//Set ..%GetComponentById("Text1").value = $$$Text("To compact free space in the selected database, fill out the following form. When ready, press the OK button:")

	Set msg = ..GetFreeSpace(%page.Directory,.FreeSpace,.EndFree,.CurrSize)
	If (msg '= 1) {
		Set ErrorComp = ..%GetComponentById("idError")
		If (msg = "Not Mounted") || (msg = "ReadOnly") {
			Set ErrorComp.seed = 1
		} Else {
			Set ErrorComp.seed = msg
		}
		Set ErrorComp.hidden = 0
		Set ..%GetComponentById("form").hidden = 1
		Set ..%GetComponentById("btnExit").hidden = 0
	} Else {
		Set %page.FreeSpace = FreeSpace
		Set %page.EndFree = EndFree
		Set ..%GetComponentById("Size").value = CurrSize_" MB"
		Set txtTarget = ..%GetComponentById("txtTarget")
		Set msg = ""
		If ..FreeSpace = 0 {
			Set msg = $$$TextHTML("No free space to compact")
		} ElseIf  ..FreeSpace '> ..EndFree {
			Set msg = $$$TextHTML("All free space is already compacted")
		}
		If msg '= "" {
			Set txtTarget.hidden = 1
			Set ..%GetComponentById("Warning").value = msg
			Set ..%GetComponentById("btnOK").disabled = 1
			Set ..%GetComponentById("btnOK").controlClass = "commandButtonDisabled"
		} Else {
			Set txtTarget.label = $$$Text("Target free space (in MB) at end of file:")
			Set txtTarget.hint = $$$FormatText($$$Text("Specify a number between %1 and %2."),%page.EndFree,%page.FreeSpace)
		}
		Set ..%GetComponentById("FreeSpace").value = %page.FreeSpace_" MB"
		Set ..%GetComponentById("EndFree").value = %page.EndFree_" MB"
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Compact Database")
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
		var FreeSpace = this.FreeSpace;
		var EndFree = this.EndFree;
		var Target = zen("txtTarget").getValue();
		if (!this.validate(Target,EndFree,FreeSpace)) return;

		var proxy = this.StartCompact(DatabaseName,Directory,Target);
		if (proxy.error) {
			alert(proxy.error);
			return;
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

/// Make sure that the Target size is smaller than that of the current available freespace
ClientMethod validate(target, sizemin, sizemax) As %Boolean [ Language = javascript ]
{
	var ok = true;
	if (target == "") ok = false;
	else if (!(target.match(/\d/))) ok = false;
	else if (parseInt(target) > parseInt(sizemax)) ok = false;
	else if (parseInt(target) < parseInt(sizemin)) ok = false;
	else if (parseInt(target) < 0) ok = false;
	if (!ok) {
		alert($$$Text('Please enter a number that is within the range of the total available free space.'));
		zen("txtTarget").focus();
	}
	return ok
}

/// Start background job to compact a selected directory
ClassMethod StartCompact(DBName, Directory, Target) As %ZEN.proxyObject [ ZenMethod ]
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
		Set tParms("DBName") = DBName
		Set tParms("Directory") = Directory
		Set tParms("Target") = Target
 		Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("CompactDBSpace",tParms("NAMESPACE"),.tParms,,.tJob)
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
	Set tProxy.error = "Error occurred in StartCompact: "_$ZE
	Quit tProxy
}

/// Return available FreeSpace
ClassMethod GetFreeSpace(Directory As %String, Output FreeSpace As %Integer, Output EndFree As %Integer, Output CurrSize As %Integer) As %String
{
	Try {
		Set tObj = ##Class(SYS.Database).%OpenId(Directory,,.tSC)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		If (tObj.Mounted '= 1) {
			Set msg = "Not Mounted"
		} ElseIf $$$NotAllowDBCompTrunDefrag(tObj) {
			Set msg = "ReadOnly"
		} Else {
			Set CurrSize = tObj.Size
			Set tSC = tObj.GetFreeSpace(Directory,.FreeSpace)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			Set tSC = ##class(SYS.Database).FileCompact(tObj.Directory,0,.EndFree)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			#; YSD2365 - return converted integer only
			Set FreeSpace = FreeSpace\1
			Set msg = $$$OK
		}
	} Catch Error {
		Set msg = $$$Text("Error occurred in GetFreeSpace:")_" "_..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
	}
	Quit msg
}

}
