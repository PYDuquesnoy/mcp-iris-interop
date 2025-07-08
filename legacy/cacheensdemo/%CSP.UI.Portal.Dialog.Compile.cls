/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Compile dialog for Management Portal.
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// This dialog is used by Classes/Routines for both Namespaces and Databases.<br/>
/// Please be extremely careful!!! </b></p>
Class %CSP.UI.Portal.Dialog.Compile Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.Compile.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Compile";

Parameter RESOURCE = "%Development:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property COMPILEALL As %ZEN.Datatype.string(ZENURL = "COMPILEALL");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}
/* style for title instructions */
div.Description	{
	font-size: 16px; 
	padding: 5px;
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
<button id="btnFinish" controlClass="commandButton" caption="Compile" onclick="zenPage.doCompile();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:20;">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<group id="idFlags" layout="none">
<vgroup label="Compile Flags" labelPosition="left" >
<checkbox id="co-1" caption="Keep generated source code" captionClass="normal" aux="k" value="1" onchange="zenPage.updateFlags();"/>
<checkbox id="co-2" caption="Compile dependent classes" captionClass="normal" aux="b" value="0" onchange="zenPage.updateFlags();"/>
<checkbox id="co-3" caption="Skip related up-to-date classes" captionClass="normal" aux="u" value="1" onchange="zenPage.updateFlags();"/>
</vgroup>
<text id="Flags" label="Flags" value="cuk"/>
<html><hr size="1"/></html>
</group>
<checkbox id="chkBackground" caption="Run compile in the background" captionClass="zenLabel" hint=" (Highly recommended for compiling many or large files.)"/>
<iframe id="output"/>
</pane>
}

/// User changed a Compile flag, update the Flags textbox.<br/>
/// Get all the checkboxes values and reset the Flags. (Classes only).
ClientMethod updateFlags() [ Language = javascript ]
{
	var keep = (zen("co-1").getValue()) ? "k" : "";
	var compile = (zen("co-2").getValue()) ? "b" : "";
	var skip = (zen("co-3").getValue()) ? "u" : "";
	zen("Flags").setValue("c"+skip+keep+compile);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("btnFinish").focus();
}

/// Start the compile
ClientMethod doCompile() [ Language = javascript ]
{
	var flags = zen("Flags").getValue();
	if (this.FILETYPE == "Class") {
		var keep = (zen("co-1").getValue()) ? 1 : 0;
		var compile = (zen("co-2").getValue()) ? 1 : 0;
		var skip = (zen("co-3").getValue()) ? 1 : 0;
		this.SaveFlags(this.FILETYPE,keep,compile,skip,flags)
	} else {
		flags = "k";	
	}
	var background = (zen("chkBackground").getValue()==true) ? 1 : 0;
	var namespace = encodeURIComponent(this.NAMESPACE);
	var params = 'FILETYPE=' + this.FILETYPE + '&FLAGS=' + flags + '&NAMESPACE=' + namespace + '&COMPILEALL=' + this.COMPILEALL + '&RUNBACKGROUND=' + background;
	zen('output').setProperty('src',zenLink('_CSP.UI.Portal.Dialog.CompileOutput.zen?'+params));
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnFinish').setProperty('disabled',true);
	zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
	zen('btnCancel').focus();
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	try {
		this.firePopupAction('StatementRefresh',1,false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.firePopupAction('StatementRefresh',1,false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var heightadj = (this.FILETYPE == "Class") ? 360 : 240;
	var wd = zenGetWindowWidth() - 60;
	var ht = zenGetWindowHeight() - heightadj;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..FILETYPE [ "Class" {
		If ..COMPILEALL = 1 Quit $$$TextHTML("Compile All Classes")
		Quit $$$TextHTML("Compile Classes")	
	} ElseIf ..FILETYPE [ "Routine" {
		If ..COMPILEALL = 1 Quit $$$TextHTML("Compile All Routines")
		Quit $$$TextHTML("Compile Routines")
	}
	Set ..InvalidParam = 1
	Quit $$$TextHTML("Undefined Type")
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
	
	If ..FILETYPE [ "Routine" {
		Set ..%GetComponentById("idFlags").hidden = 1
	} 
	Else {
		#; For classes, use the last choices. Default to "cuk" if this is the first time in Compile.
		Set Last = $G($$$IRISTempMgt($Username,..FILETYPE,"Compile","Flags"),$LB(1,0,1,"cuk"))
		For n=1:1:3 Set ..%GetComponentById("co-"_n).value = $LG(Last,n)
		Set ..%GetComponentById("Flags").value = $LG(Last,4)
	}
	If %page.COMPILEALL = 1 || (+$G(%session.Data($Username,%page.FILETYPE,"selectedRows")) > 1) {
		Set ..%GetComponentById("chkBackground").value = 1
	}
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set espNamespace = ..EscapeHTML(%page.NAMESPACE)
	Set tPageTitle = ""	
	If %page.COMPILEALL = 0 {		
		Set tTotal = +$G(%session.Data($Username,%page.FILETYPE,"TotalSelected"))
		if %page.FILETYPE="SQLStatementClass" {
			if tTotal>1 {
				set tTitle = $$$Text("Compile %1 classes from namespace %2.")
				set tPageTitle = $$$FormatText(tTitle,tTotal,espNamespace)_"<br/>"
			}
			else {
				set classname=$g(%session.Data($Username,%page.FILETYPE,"selectedRows",1))
				set:classname'="" classname=$e(classname,1,*-4)  // Strip .cls from classname
				set tTitle=$$$Text("Compile class %1 from namespace %2")
				set tPageTitle = $$$FormatText(tTitle,classname,espNamespace)_"<br/>"
			}
		}
		elseif %page.FILETYPE="SQLStatementRoutine" {
			if tTotal>1 {
				set tTitle = $$$Text("Compile %1 routines from namespace %2.")
				set tPageTitle = $$$FormatText(tTitle,tTotal,espNamespace)_"<br/>"
			}
			else {
				set rtnname=$g(%session.Data($Username,%page.FILETYPE,"selectedRows",1))
				set:rtnname'="" rtnname=$e(rtnname,1,*-4)  // Strip .mac from rtnname
				set tTitle=$$$Text("Compile routine %1 from namespace %2")
				set tPageTitle = $$$FormatText(tTitle,rtnname,espNamespace)_"<br/>"
			}
		}
		else {
			Set:%page.FILETYPE="Class" tTitle = $S(tTotal>1:$$$Text("Compile %1 classes from namespace %2."),1:$$$Text("Compile %1 class from namespace %2"))
			Set:%page.FILETYPE="Routine" tTitle = $S(tTotal>1:$$$Text("Compile %1 routines from namespace %2."),1:$$$Text("Compile %1 routine from namespace %2"))
			Set tPageTitle = $$$FormatText(tTitle,tTotal,espNamespace)_"<br/>"
		}
	} 
	Else {
		If %page.FILETYPE="Class" Set tPageTitle = $$$FormatText($$$Text("Compile all classes in namespace %1."),espNamespace)_"<br/>"
		If %page.FILETYPE="Routine" Set tPageTitle = $$$FormatText($$$Text("Compile all routines in namespace %1."),espNamespace)_"<br/>"
	}	
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit 1
}

/// Save the user's choices (optimization values for older versions excluded) for next time.
ClassMethod SaveFlags(pFileType, pKeep, pCompile, pSkip, pFlags) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,pFileType,"Compile","Flags") = $LB(pKeep,pCompile,pSkip,pFlags)
}

}
