/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Background.Dialog.DatabaseTruncate Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Background.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Background.Dialog.DatabaseTruncate.zen";

/// Displayed name of this page.
Parameter PAGENAME = "DatabaseTruncate";

Parameter RESOURCE = "%Admin_Operate:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// ID for edit. DBName for this page.
Property DBName As %String(ZENURL = "DBName");

/// DBDirectory passed in.
Property Directory As %String(ZENURL = "Directory");

/// Current size.
Property Size As %String;

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
 <label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<label id="DatabaseName" label="Database Name:" value="#(%page.DBName)#" enclosingClass="normal"/>
 <label id="Directory" label="Directory:" value="#(%page.Directory)#" enclosingClass="normal"/>
 <label id="Size" label="Size: " value="" enclosingClass="normal"/>
 <text id="txtTarget" label="" size="10" value="0" hint="" hintClass="helpText"/> 
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
	
	Set msg = ..GetSize(%page.Directory,.Size)
	If (msg '= 1) {
		Set ErrorComp = ..%GetComponentById("idError")
		If (msg = "Not Mounted") || (msg = "ReadOnly") {
			Set ErrorComp.seed = 1
		} Else {
			Set ErrorComp.seed = msg
		}
		Set ErrorComp.hidden = 0
		Set ..%GetComponentById("form").hidden = 1
	} Else {
		Set %page.Size = Size
		Set ..%GetComponentById("Size").value = %page.Size_" MB"
		Set txtTarget = ..%GetComponentById("txtTarget")
		Set txtTarget.label = $$$TextHTML("Target file size (MB):")
		Set txtTarget.hint = $$$TextHTML("Specify the target size for the file, or 0 to remove all unused space.")
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Truncate Database")
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
		var ok = 1;
		var DatabaseName = this.DBName;
		var Directory = this.Directory;
		var Size = this.Size;
		var Target = zenPage.getComponentById("txtTarget").getValue();
		if (!this.validate(Size,Target)) return;
		var proxy = this.StartCleanup(DatabaseName,Directory,Target);
		if (proxy.error != '') {
			this.showMsg(proxy.error, 1);
			ok = 0;	
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

/// Start background job to cleanup a selected directory
ClassMethod StartCleanup(DBName, Directory, Target) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = ##class(SYS.Database).ReturnUnusedSpace(
				$G(Directory),
				$G(Target),
				.newsize)
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)	
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartCleanup: "_$ZE
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Make sure that the Target size is smaller than that of the current size.
ClientMethod validate(size, target) As %Boolean [ Language = javascript ]
{
	var ok = true;
	if ((target != "") && (target == 0)) {
		return ok;
	} else {
		if (target == "") ok = false;
	    else if (!(target.match(/\d/))) ok = false;
		else if (parseInt(target) >= parseInt(size)) ok = false;
	}
	if (!ok) {
		alert($$$Text('Please enter a number that is less than the current size. To remove all unused space, enter 0.'));
		zenPage.getComponentById("txtTarget").focus();
	}
	return ok
}

/// Return current size since the size may have changed since the table was drawn
ClassMethod GetSize(Directory As %String, Output Size As %Integer) As %String
{
	Try {
		Set tObj = ##Class(SYS.Database).%OpenId(Directory,,.tSC)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		If (tObj.Mounted '= 1) {
			Set msg = "Not Mounted"
		} ElseIf $$$NotAllowDBCompTrunDefrag(tObj) {
			Set msg = "ReadOnly"
		} Else {
			Set Size = tObj.Size
			Set msg = $$$OK
		}
	} Catch Error {
		Set msg = $$$Text("Error occurred in GetSize:")_" "_..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
	}
	Quit msg
}

}
