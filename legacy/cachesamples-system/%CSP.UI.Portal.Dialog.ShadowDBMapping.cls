/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Dialog.ShadowDBMapping Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.ShadowDBMapping.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ShadowDBMapping";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property ShadowName As %ZEN.Datatype.string(ZENURL = "ShadowName");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.link {
	font-size: 0.8em;
	color: #3B84BC;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();;"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="editGroup" labelPosition="top" cellStyle="padding-bottom:5px;">
<dataCombo id="FromDB"
label="Source Database Directory"
queryClass="Config.Shadows"
queryName="SourceDatabases"
showEmpty="true"
dropdownWidth="750px"
displayColumns="1"
choiceColumn="1"
valueColumn="1"
maxRows="100000"
size="104"
hint="Required."
hzScroll="true"
>
<parameter id="param1"/>
</dataCombo>
<spacer height="5px"/>
<dataCombo id="ToDB"
label="Shadow Database Directory"
queryClass="Config.Databases"
queryName="List"
showEmpty="true"
dropdownWidth="750px"
displayColumns="2"
choiceColumn="2"
valueColumn="2"
auxColumn="1"
maxRows="100000"
size="104"
hint="Required."
hzScroll="true"
>
<parameter value="*"/>
<parameter value=""/>
<parameter value="1"/>
<parameter value=""/>
</dataCombo>
</group>
</pane>
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	zen('btnCancel').focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return 1;
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg();
	var FromDB = zen('FromDB');
	var FromDBValue = FromDB.getValue();
	var ToDB = zen('ToDB');
	var ToDBValue = ToDB.getValue();
	var pass = true;
	var msg = $$$Text("There was a problem with the form. See the highlighted fields below.");
	
	if (FromDBValue == '') {
		FromDB.setProperty('hintClass','redText');
		if (pass) {
			FromDB.focus();
		}
		pass = false;
	} else if (zenPage.MapShadowExists(zenPage.ShadowName,FromDBValue)) {
		FromDB.setProperty('hintClass','redText');
		if (pass) {
			FromDB.focus();
		}
		msg = $$$Text('Source directory is not unique.');
		pass = false;
	} else {
		FromDB.setProperty("hintClass","helpText");
	}
	
	if (ToDBValue == '') {
		ToDB.setProperty('hintClass','redText');
		if (pass) {
			ToDB.focus();
		}
		pass = false;
	} else if (ToDB.getAuxValue() == 'IRISSYS') {
		ToDB.setProperty('hintClass','redText');
		if (pass) {
			ToDB.focus();
		}
		msg = $$$Text('The manager directory is not allowed as a target database of shadowing.');
		pass = false;
	} else {
		ToDB.setProperty('hintClass','helpText');
	}
	
	if (!pass) {
		this.showMsg(msg,true);
	}
	
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.ShadowName = zenPage.ShadowName;
		proxy.FromDB = zen('FromDB').getValue();
		proxy.ToDB = zen('ToDB').getValue();
		
		var result = zenPage.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return false;
		} 
		return true;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	return false;
}

ClassMethod MapShadowExists(ShadowName As %String, SourceDir As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(Config.MapShadows).Exists(ShadowName,SourceDir)
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		// Make sure shadow isn't running at this point.
		Set shadowStatus = ##class(SYS.Shadowing.Shadow).GetStatus(pProxy.ShadowName)
		If '##class(%Library.ShadowState).CanStart(shadowStatus) {
   			Set tSC = $$$ERROR($$$ShadowStopRequired,pProxy.ShadowName)
   			throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set Properties("Directory") = pProxy.ToDB
		Set tSC = ##class(Config.MapShadows).Create(pProxy.ShadowName,pProxy.FromDB,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Add Database Mapping")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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
	
	Set rs = ##class(%ResultSet).%New("Config.Shadows:SourceDatabases")
	Set tSC = rs.Execute(..ShadowName)
	If '$$$ISOK(tSC) {
		Set ..%GetComponentById("idRespond").value = ..EvalResult(tSC)
		Set ..%GetComponentById("idRespond").hidden = 0
		Set ..%GetComponentById("editGroup").hidden = 1
		Set ..%GetComponentById("btnFinish").disabled = 1
		Set ..%GetComponentById("btnFinish").controlClass = "commandButtonDisabled"
		Quit $$$OK
	}
	
	Set ..%GetComponentById("param1").value = ..ShadowName
		
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Add Database Mapping for Shadow %1"),..EscapeHTML(%page.ShadowName))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
