/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Dialog.ArchiveWizard Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Edit Archive Target";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As %Boolean = 0;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.ArchiveWizard.zen";

Parameter HELPADDRESS = "System Administration, Configuration, System Configuration, Archive Target Settings, Add Archive Target";

Parameter RECENT = 0;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %String(ZENURL = "isNew") [ InitialExpression = "1" ];

/// Archive for edit. Null if adding new archive.
Property PID As %String(ZENURL = "PID");

XData Style
{
<style type="text/css">
.zenLabelDisabled,a.radioSetCaptionDisabled { color:black; }
</style>
}

XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
 <!-- block to show result -->
 <form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="Name" label="Name" hint="Required." onchange="zenPage.doModified();"/>
<radioSet id="Type" label="Type" valueList="s3,rsync,noop" displayList="AWS S3,rsync or robocopy,no-op (for test only)" value="s3" onchange="zenPage.changeType(zenThis.getValue());" layout="horizontal"/>
<text id="Location" label="Location" hint="Required." title="'s3://dir/' for s3, '/dir' or 'server:/dir/' for rsync (Unix/Linux) and 'drive:\dir\' or '\\server\share\dir\' for robocopy (Windows)" size="70" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod doModified(newvalue) [ Language = javascript ]
{
	// no-op
}

ClientMethod changeType(newvalue) [ Language = javascript ]
{
        this.doModified();
        zen('Location').setValue("");
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		;if (!this.validateRequired(zen('Type'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Location'),pass,"S")) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

/// Process save and create new archive. Return true if success. OW return false.
ClientMethod doSave() As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		if (!this.validate()) {
			return false;
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Name = zenEscapeJS(zen("Name").getValue());
		proxy.Type = zenEscapeJS(zen("Type").getValue());
		proxy.Location = zenEscapeJS(zen("Location").getValue());
		
                var result = this.SaveData(proxy);
                if (result.ok != 1) {
                        this.showMsg(result.ErrorMessage);
                        return false;
                }
        } catch(ex) {
                zenExceptionHandler(ex,arguments);
                return false;
        }
        return true;
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("Type") = pProxy.Type
		Set Properties("Location") = pProxy.Location
		
		Set tMethod = $S(pProxy.PID="":"Create",1:"Modify")
		Set tSC = $classmethod("Config.Archives",tMethod,pProxy.Name,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.<br/>
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		return this.doSave();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
       return zen('Name').getValue();
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
       Quit $$$TextHTML("Archive Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
       Quit ""
}

/// Overriden to add PID to the page name to distinguish the specific page.
ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,this.PID);
}

/// Overriden to add PID to the page name to distinguish the specific page.
ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value,this.PID);
}

/// Used to Save tableNavBar values, add PID to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, pPID As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_" "_pPID,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
