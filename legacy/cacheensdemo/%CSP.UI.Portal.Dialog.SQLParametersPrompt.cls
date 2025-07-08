/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog prompts for user to enter dynamic SQL statement's parameter values.
/// The calling page should pass in the number of parameters need to be prompted.
Class %CSP.UI.Portal.Dialog.SQLParametersPrompt Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLParametersPrompt.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "SQLParametersPrompt";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Total number of input prompt we should generate
Property PromptCount As %ZEN.Datatype.string(ZENURL = "PromptCount");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#htmlQuery {
	height: 200px;
	overflow: auto;
	border-bottom: 1px solid white;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<vgroup id="idValues" cellStyle="padding:10px;">
<html id="htmlQuery" label="Query Text:" OnDrawContent="DrawQuery"/>
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Enter Parameter Value for Query")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen("p1")) zen("p1").focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		zen("result").setValue("");
		var values = "";
		var tParam;
		for (var n=1; n <= this.PromptCount; n++) {
			tParam = zen("p" + n).getValue();
			if (n != 1) values = values + "^";
			values = values + tParam;
		}
		var ok = this.SaveParameterValues(this.PromptCount, values);
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
	
	Set tPrompt = $$$Text("Enter value for parameter %1:")
	Set tGroup = ..%GetComponentById("idValues")
	Set tPromptCount = $P(%session.Data($Username,"SQL","QueryParam"),"^",2)
	Set tParam = $O(%session.Data($Username,"SQL","QueryParam",""))
	While tParam '= "" {
		Set tText = ##class(%ZEN.Component.text).%New()
		Set tText.id = "p"_tParam
		Set tText.label = $$$FormatText(tPrompt,tParam)
		Do tGroup.%AddChild(tText)
		Set tParam = $O(%session.Data($Username,"SQL","QueryParam",tParam))
	}
	Quit $$$OK
}

Method DrawQuery(pSeed) As %Status
{
	If pSeed = "" {
		Set n = $O(%session.Data($Username,"SQL","QueryText",""))
		While n '= "" {
			Set tData = %session.Data($Username,"SQL","QueryText",n)
			Set tRows = $L(tData,$c(10))
			For tLine = 1:1:tRows &html<#(..EscapeHTML($P(tData,$c(10),tLine)))#<br/>>			
			Set n = $O(%session.Data($Username,"SQL","QueryText",n))
		}
	} Else {
		&html<#(pSeed)#>	
	}
	Quit 1
}

ClassMethod SaveParameterValues(pPromptCount, pValues) As %String [ ZenMethod ]
{
	For tParm = 1:1:pPromptCount {
		Set %session.Data($Username,"SQL","QueryParam",tParm,"Value") = $P(pValues,"^",tParm)
	}
	Quit 1
}

}
