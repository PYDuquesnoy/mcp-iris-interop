/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.UI.Dialog.buildDomain Extends %ZEN.Dialog.standardDialog [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter CANCELBUTTON = 0;

Parameter DOMAIN = "%iKnow";

Parameter RESOURCE = "%Development";

/// Domain Definition class
Property domainDefinition As %ZEN.Datatype.string(ZENURL = "DOMAINDEF");

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<!--label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" controlClass="labelValue"/-->
<label id="cubeName" label="Domain" controlClass="labelValue"/>
<textarea id="output" cols="60" rows="25" readOnly="true" />
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Build Domain")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	set tDomainName = "undefined"
	try {
		set tDomainName = $classmethod(..domainDefinition, "%GetDomainName")
	} catch {}
	quit $$$TextHTML("Build Domain")_" '"_$zcvt(tDomainName,"O","HTML")_"'"
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	Quit $zname(pClassName,3)
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.BuildDomain();
	zen('btnOK').setDisabled(true);
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

Method BuildDomain() As %Status [ ZenMethod ]
{
	quit ..%RunBackgroundMethod("BuildDomainAsync", ..domainDefinition)
}

ClassMethod BuildDomainAsync(pDomainDefClass As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("Building...", 0)
		
		do $classmethod(pDomainDefClass, "%Build", 1,, 1)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do ..%EndBackgroundMethod()
	quit tSC
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	return true;
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task and the task is complete.
/// Typically a subclass uses this to send back JavaScript to update
/// the page.
ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	set tSC = ..%OnMonitorBackgroundTask(pTaskID, "", 0)
	kill ^IRIS.Temp.IK.DomainBuild(pTaskID)
	&js<zen('btnOK').setDisabled(false);>
	quit tSC
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task.
/// Typically a subclass uses this to send back JavaScript to update
/// a progress bar.
ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	set tSC = $$$OK
	try {
		merge tOutput = ^IRIS.Temp.IK.DomainBuild(pTaskID,"out")
		&js<var o = zen('output');>
		&js<o.setValue('');>
		for i = 1:1:tOutput {
			set tOutputLine = $zconvert($g(tOutput(i)),"O","JS")
			&js<o.setValue(o.getValue()+'\n#(tOutputLine)#');>
		}
		&js<o.scrollTop = o.scrollHeight;>
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
