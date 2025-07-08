/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.UI.Dialog.compileDomain Extends %ZEN.Dialog.standardDialog [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter DOMAIN = "%iKnow";

Parameter RESOURCE = "%Development";

/// Domain Definition class
Property domainDefinition As %ZEN.Datatype.string(ZENURL = "DOMAINDEF");

XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<!--label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" controlClass="labelValue"/-->
<label id="cubeName" label="Cube Name" controlClass="labelValue"/>
<timer id="timer" ontimeout="zenPage.timeout();"/>
<iframe id="output"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Compile Domain")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Compile Domain Definition")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.domainDefinition;
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Quit $zname(pClassName,3)
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	zen("btnOK").setProperty("caption",$$$Text("Compile"));
	this.compile();
	this.onresizeHandler();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try 
	{
		Set ..domainDefinition = ..EscapeHTML(..domainDefinition)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Start the compile
ClientMethod compile() [ Language = javascript ]
{
	zen('btnOK').setHidden(true);	
	zen('btnCancel').setDisabled(true);
	zen('timer').timeout = 1000;
	zen('timer').startTimer();

	zen('output').setProperty('src','_iKnow.UI.Dialog.compileDomainOutput.cls?DOMAINDEF=' + encodeURIComponent(this.domainDefinition));
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var wd = (document.documentElement.clientWidth ? document.documentElement.clientWidth : document.body.clientWidth) - 20;
	var ht = (document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight) - 240;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// Check compile status periodically.
ClientMethod timeout() [ Language = javascript ]
{
	//var status = this.CheckStatus(this.cubeClass);
	var status = this.CheckStatus(this.domainDefinition);

	if (status != 'Done') {
		zen('timer').timeout = 500;
		zen('timer').startTimer();
	}
	else {
		zen("btnOK").setProperty("caption",$$$Text("OK"));
		zen('btnOK').setHidden(false);
		zen('btnCancel').setDisabled(false);
		// when build finished, set focus on Cancel button so [Enter] key will exit easily.
		zen("btnCancel").setProperty("caption",$$$Text("Done"));
		zen("btnCancel").focus();
	}
	return;
}

ClassMethod CheckStatus(pCubeClass) As %String [ ZenMethod ]
{
	Set IsComplete = $G(^IRIS.Temp.iKnowDomainCompile($Username,pCubeClass,+$J))
	If IsComplete = "Done" Kill ^IRIS.Temp.iKnowDomainCompile($Username,pCubeClass,+$J)
	Quit IsComplete
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	//this.compile();
	return true;
}

}
