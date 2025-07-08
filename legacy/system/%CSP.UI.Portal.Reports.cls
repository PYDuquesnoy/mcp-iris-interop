/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// 
/// System Management Portal - Reports Settings
Class %CSP.UI.Portal.Reports Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// 
/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// 
/// Displayed name of this page.
Parameter PAGENAME = "Reports Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Reports.zen";

Parameter HELPADDRESS = "Home,Configuration";

/// 
/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property msgTestFail As %String;

Property msgTestSuccess As %String;

Property lblDone As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Done")} ];

XData Style
{
<style type="text/css">

.normal {

	text-decoration: none;

}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">

<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>

<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>

<form id="fld">

<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">

 

<hgroup cellStyle="padding-bottom:4px;" valign="top">

<text id="transformerpath" label="Path and File Name For PDF Generation" size="100" onchange="zenPage.doModified();"/>

<button caption="Browse..." showLabel="false" hint=" " onclick="zenPage.doBrowse('transformerpath');" valign="top" containerStyle="padding-top:18px;"/>

</hgroup>



<group>

<fieldSet label="Configuration File For PDF Rendering Engine">

<radioButton id="radUse" name="radTransform" caption="Use" captionClass="normal" 

optionValue="1" value="1" onchange="zenPage.changeTransform();"/>

<hgroup id="idTransform" cellStyle="padding-bottom:4px;">

<text id="transformerconfig" label="Configuration File" size="95" containerStyle="padding-left:20px;" onchange="zenPage.doModified();" hint="A default fop.xconf will be used if this field is not set and Reports do not set USEINSTALLEDFOP=0."/>

<button caption="Browse..." showLabel="false" valign="top" containerStyle="padding-top:18px;" hint=" " onclick="zenPage.doBrowse('transformerconfig');"/>

</hgroup>

<radioButton id="radIgnore" name="radTransform" caption="None" captionClass="normal"

optionValue="0" onchange="zenPage.doModified();zenPage.changeTransform();"/>

</fieldSet>

</group>



<group>

<text id="renderserverport" label="Default HotJVM Render Server Port" size="10" maxlength="5" value="" hint="When this value is specified, all Reports will use by default a HotJVM running on this port." onchange="zenPage.doModified();"/>

</group>



<html><hr size="1"/></html>

<group>

<label id="JavaHome" label="JAVA_HOME Environment Variable" controlClass="normal" value="" hint="Current value of O.S. environment variable JAVA_HOME."/>

</group>



<html><hr size="1"/></html>

<group labelPosition="left">

<button id="Test" label="To verify that the xsl engine is configured correctly, click here:" caption="Verify Now" controlClass="commandButton" onclick="zenPage.testItem();"/>

</group>

</group>

</form>

</pane>
}

/// 
/// Launching a file selector window. 
ClientMethod doBrowse(what) [ Language = javascript ]
{

	var Dir = zen(what).getValue();

	var wildcard = "*.*";

	if (what=='transformerpath') wildcard = "*.bat;*.cmd";

	var showdirectoryonly = "0";

	var url = "%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=" + showdirectoryonly;

	zenLaunchPopupWindow(url,what,'status,scrollbars,resizable,width=600,height=700');
}

/// 
/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// 
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{

	if (action == "ok") {

		zen(popupName).setValue(value);

		this.doModified();	

	}
}

/// 
/// Use clicked a transform radio button.
ClientMethod changeTransform() [ Language = javascript ]
{

	var flag = (zen("radUse").getValue()==1) ? false : true;

	zen("idTransform").setHidden(flag);
}

/// 
/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{

	try {

		var transformerpath = zen("transformerpath").getValue();

		var transformerconfig = zen("transformerconfig").getValue();

		var transUse = zen("radUse").getValue();

		var renderserverport = zen("renderserverport").getValue();

		var result = this.SaveData(transformerpath,transformerconfig,transUse,renderserverport);

		this.afterSave(result);	

	} catch (ex) {

		alert("Error: " + ex);

	}
}

/// 
/// Test current item. 
ClientMethod testItem() [ Language = javascript ]
{

	try {

		var ok = this.TestSetup();

		if (ok == 1) {

			this.showMsg(this.msgTestSuccess,0);

		} else {

			this.showMsg(this.msgTestFail,1)

		}

	} catch (ex) {

		alert("Error: " + ex);

	}
}

Method %OnAfterCreatePage() As %Status
{

	Set tSC = ##super()

	If $$$ISERR(tSC) Quit tSC



	Set ..%GetComponentById("Text1").value = $$$Text("Use the form below to edit Reports settings for the system:")

	

	// Set into LocatorHeader so DrawTitle can use it

	Set ..LocatorHeader = $$$Text("Reports Settings")

	// Set into HelpAddress so DrawTitle can use it

	// Set test success message

	Set ..msgTestFail = $$$Text("PDF Generation is not configured properly.")

	Set ..msgTestSuccess = $$$Text("PDF Generation is configured properly.")



	Set Properties("transformerpath") = $G(^%SYS("zenreport","transformerpath"))

	Set Properties("transformerconfig") = $G(^%SYS("zenreport","transformerconfig"))

	Set Properties("renderserverport") = $G(^%SYS("zenreport","renderserverport"))

	

	/// If more properties are added, the following loop will take care of it.

	Set (tProperty,p) = ""

	Set tProperty = $O(Properties(tProperty)) 

	While tProperty '= ""  {

		Set p = p_","_tProperty

		Set ..%GetComponentById(tProperty).value = Properties(tProperty)

		Set tProperty = $O(Properties(tProperty)) 

	}



	Set tJavaHome = $System.Util.GetEnviron("JAVA_HOME")

	Set:tJavaHome="" tJavaHome = $$$TextHTML(" (Not defined)")

	Set ..%GetComponentById("JavaHome").value = tJavaHome

	

	#;YSD2866 If it's set to null then it means to ignore config file

	If $D(^%SYS("zenreport","transformerconfig")),^%SYS("zenreport","transformerconfig")="" {

		Set ..%GetComponentById("idTransform").hidden = 1

		Set ..%GetComponentById("radIgnore").value = 0

	} 

	Set ..%GetComponentById("transformerpath").hint = $$$Text("Default file: ")_$$$fopbat

	Set ..%GetComponentById("transformerconfig").hint = $$$Text("Default file: ")_$$$fopconfig



	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Reports Settings")
}

/// 
/// Save file into global. Outside white spaces are stripped.
ClassMethod SaveData(transformerpath, transformerconfig, transUse, renderserverport) As %ZEN.proxyObject [ ZenMethod ]
{

	#; Initialize return proxy object

	Set tProxy = ##class(%ZEN.proxyObject).%New()



	Try {

		Set ^%SYS("zenreport","transformerpath") = $ZStrip(transformerpath,"<>W")

		Set trans = $ZStrip(transformerconfig,"<>W")

		If transUse = 1 {

			If trans = "" Kill ^%SYS("zenreport","transformerconfig")

			Else  Set ^%SYS("zenreport","transformerconfig") = trans

		} Else {

			Set ^%SYS("zenreport","transformerconfig") = ""

		}

		Set ^%SYS("zenreport","renderserverport") = $ZStrip(renderserverport,"<>W")

		Set tProxy.ok = 1

	} Catch Error {

		Set tProxy.ok = 0

		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())

	}

	Quit tProxy
}

/// 
/// Test to verify that the xsl engine is configured correctly
ClassMethod TestSetup() As %String [ ZenMethod ]
{

	Set tSC = ##class(%ZEN.Report.reportPage).TestPDFGeneration()

	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)

	Quit tSC
}

/// 
/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{

	this.invokeSuper('onloadHandler',arguments);

	zen("transformerpath").focus();
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
