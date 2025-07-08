/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Web Form WizardS ettings.
Class %ZEN.Template.WebFormWizard.Settings Extends %ZEN.Component.page [ Deprecated, System = 4 ]
{

/// Display title of this page <title></title>
Parameter PAGETITLE = "Web Form Wizard Settings";

/// Require %Development:USE for access to this page.
Parameter RESOURCE = "%Development:USE";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Parameter HELPID = "GZEN_webform_wizard_settings";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.stdTitle {
	color: black;
	background: #c5d6d6;
	background-image: url(images/titlegradient.png);
	background-repeat: repeat-y;
	background-position: right;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid darkblue;
	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
	white-space: nowrap;
}
.EditForm {
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x500.png);
	background-repeat: repeat-x;
	border: black 1px solid;
}
#btnOK input,#btnCancel input{
	width: 5.0em;
}
.caption {
	color: black;
	font-size: 0.9em;
	font-weight: bold;
	padding-right: 5px;
}
.normal {
	color: black;
	font-size: 0.9em;
	padding-right: 5px;
}
.radioSetSpan {
	color: black;
	font-size: 0.9em;
	font-weight: normal;
	padding-left: 5px;
}

</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page>
<html id="header" OnDrawContent="%DrawTitle" />
<vgroup width="100%">
<form cellStyle="padding:10px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;font-family: Verdana, Arial, Helvetica, sans-serif;" labelPosition="left" hidden="false">
<fieldSet legend="Screen Layout" enclosingClass="caption" labelPosition="left" cellStyle="padding:4px;">
<select id="CollectionRows" label="Number of display rows for lists and arrays:" labelClass="normal" valueList="1,2,3,4,5,6,7,8,9,10" showEmpty="false" />
<select id="MultilineRows" label="Number of display rows for multiline textbox:" labelClass="normal" valueList="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20" showEmpty="false" />
<hgroup labelPosition="left" showLabel="false" cellAlign="even">
<label label="Image (pixels)" labelClass="normal" />
<text id="ImageWidth" label="Width:" size="5" labelClass="normal" />
<text id="ImageHeight" label="Height:" size="5" labelClass="normal" />
</hgroup>
</fieldSet>
<fieldSet legend="Label Alignment" enclosingClass="caption" cellStyle="padding:4px;">
<radioSet id="LabelAlignLeft" valueList="0,1" displayList="Labels are left justified,Labels are right justified"/>
</fieldSet>
<fieldSet legend="Form Layout" enclosingClass="caption"  >
<radioSet id="SaveMethod" label="Specify which JavaScript code is to be generated" labelClass="normal" containerStyle="padding:6px;" valueList="0,1,2" displayList="All,Validation only,None"/>
<html><hr/></html>
<checkbox id="Save" caption="Form contains Save button" captionClass="normal"/>
<checkbox id="New" caption="Form contains Clear button" captionClass="normal"/>
<checkbox id="Search" caption="Form contains Search button" captionClass="normal"/>
<checkbox id="Bold" caption="Highlight labels" captionClass="normal" containerStyle="padding-bottom:4px;"/>
</fieldSet>
<fieldSet legend="Search Page Layout" enclosingClass="caption" cellStyle="padding:4px;">
<hgroup>
<vgroup>
<checkbox id="SearchNew" caption="New window" captionClass="normal"/>
<checkbox id="SearchClear" caption="Contains Clear button" captionClass="normal"/>
</vgroup>
<vgroup>
<checkbox id="SearchPredicates" caption="Contains Match options" captionClass="normal"/>
<checkbox id="SearchSort" caption="Contains Sort options" captionClass="normal"/>
</vgroup>
</hgroup>
</fieldSet>
<hgroup align="right" cellStyle="padding-right:6px;">
<button id="btnOK" caption="OK" onclick="zenPage.doSave();"/>
<button id="btnCancel" caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</form>
</vgroup>
</page>
}

/// Provide HTML for standard template html title box.
Method %DrawTitle(pSeed As %String) As %Status
{
	#; draw html title box
	Set tName = $$$TextHTML("Web Form Wizard Settings","%ZEN")

	&html<<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr height="40">
		<td bgcolor="#9C9A8C">
		<span style="font-weight: bold; color: #FFFAE7; font-size:20px; padding:6px; margin-left:14px;"><nobr>&nbsp;#(tName)#</nobr></span>
		</td>
		</tr>
	  	<tr>
		<td bgcolor="#356B8D"><img src='#(..Link("/csp/sys/images/spacer.gif"))#' width="100%" height="2" alt="-" border="0"></td>
	  	</tr>
		</table>>
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	try {
		var proxy = this.GetLayout();
		zenPage.getComponentById("ImageHeight").setValue(proxy.ImageHeight);
		zenPage.getComponentById("ImageWidth").setValue(proxy.ImageWidth);
		zenPage.getComponentById("CollectionRows").setValue(proxy.CollectionRows);
		zenPage.getComponentById("MultilineRows").setValue(proxy.MultilineRows);
		zenPage.getComponentById("LabelAlignLeft").setValue(proxy.LabelAlignLeft);
		zenPage.getComponentById("SaveMethod").setValue(proxy.SaveMethod);
		zenPage.getComponentById("Save").setValue(proxy.Save);
		zenPage.getComponentById("New").setValue(proxy.New);
		zenPage.getComponentById("Search").setValue(proxy.Search);
		zenPage.getComponentById("Bold").setValue(proxy.Bold);
		zenPage.getComponentById("SearchNew").setValue(proxy.SearchNew);
		zenPage.getComponentById("SearchClear").setValue(proxy.SearchClear);
		zenPage.getComponentById("SearchPredicates").setValue(proxy.SearchPredicates);
		zenPage.getComponentById("SearchSort").setValue(proxy.SearchSort);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Close this dialog without applying its value.
ClientMethod doCancel() [ Language = javascript ]
{
	try {
		// check for callback
		var ok = true;
		if (this.ondialogCancel) {
			ok = this.ondialogCancel();
		}
	
		if (ok) {
			zenPage.cancelPopup();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Get values, set them to proxy object and send to server to save.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.ImageHeight = zenPage.getComponentById("ImageHeight").getValue();
		proxy.ImageWidth = zenPage.getComponentById("ImageWidth").getValue();
		proxy.CollectionRows = zenPage.getComponentById("CollectionRows").getValue();
		proxy.MultilineRows = zenPage.getComponentById("MultilineRows").getValue();
		proxy.LabelAlignLeft = zenPage.getComponentById("LabelAlignLeft").getValue();
		proxy.SaveMethod = zenPage.getComponentById("SaveMethod").getValue();
		proxy.Save = 0;
		proxy.New = 0;
		proxy.Search = 0;
		proxy.Bold = 0;
		proxy.SearchNew = 0;
		proxy.SearchClear = 0;
		proxy.SearchPredicates = 0;
		proxy.SearchSort = 0;
		if (zenPage.getComponentById("Save").getValue()) proxy.Save = 1;	
		if (zenPage.getComponentById("New").getValue()) proxy.New = 1;
		if (zenPage.getComponentById("Search").getValue()) proxy.Search = 1;
		if (zenPage.getComponentById("Bold").getValue()) proxy.Bold = 1;
		if (zenPage.getComponentById("SearchNew").getValue()) proxy.SearchNew = 1;
		if (zenPage.getComponentById("SearchClear").getValue()) proxy.SearchClear = 1;
		if (zenPage.getComponentById("SearchPredicates").getValue()) proxy.SearchPredicates = 1;
		if (zenPage.getComponentById("SearchSort").getValue()) proxy.SearchSort = 1;
		this.SaveSettings(proxy);
		this.doCancel();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This method is called when user wants to save setting parameters permanently.
ClassMethod SaveSettings(proxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","ImageHeight") = proxy.ImageHeight
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","ImageWidth") = proxy.ImageWidth
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","CollectionRows") = proxy.CollectionRows
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","MultilineRows") = proxy.MultilineRows
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","LabelAlignLeft") = proxy.LabelAlignLeft
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SaveMethod") = proxy.SaveMethod
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Save") = proxy.Save
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","New") = proxy.New
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Search") = proxy.Search
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Bold") = proxy.Bold
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchNew") = proxy.SearchNew
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchClear") = proxy.SearchClear
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchPredicates") = proxy.SearchPredicates
		Set ^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchSort") = proxy.SearchSort
	
	} While (0)
	Quit 1
Done
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit $$$OK
Trap
	Set $ZT=""	
	Quit "Error occurred in SaveSettings: "_$ZE
	Goto Done
}

/// Return layout settings.
ClassMethod GetLayout() As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"	
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Message = ""
	#; Screen Layout:
	Set tProxy.ImageHeight = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","ImageHeight"),100)
	Set tProxy.ImageWidth = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","ImageWidth"),100)
	Set tProxy.CollectionRows = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","CollectionRows"),3)
	Set tProxy.MultilineRows = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","MultilineRows"),5)
	
	#; Label Alignment (right justified is the default)
	Set tProxy.LabelAlignLeft = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","LabelAlignLeft"),1)
	
	#; Form Layout:
	#; How JavaScript code is to be generated (All=0, Validation only=1, None=2)
	Set tProxy.SaveMethod = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SaveMethod"),0)
	#; Form contains Save button
	Set tProxy.Save = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Save"),1)
	#; Form contains Clear button
	Set tProxy.New = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","New"),1)
	#; Form contains Search button
	Set tProxy.Search = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Search"),1)
	#; Highlight labels
	Set tProxy.Bold = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","Bold"),1)
	
	#; Search Form Layout:
	#; New window
	Set tProxy.SearchNew = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchNew"),1)
	#; Contains Clear button
	Set tProxy.SearchClear = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchClear"),0)
	#; Contains Match options
	Set tProxy.SearchPredicates = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchPredicates"),0)
	#; Contains Sort options
	Set tProxy.SearchSort = $G(^IRIS.Temp.WebFormWizardSettings($UserName,"Layout","SearchSort"),0)
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.Message = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

}
