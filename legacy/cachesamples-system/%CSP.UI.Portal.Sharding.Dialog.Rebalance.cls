/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Sharding.Dialog.Rebalance Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Rebalance.zen";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "NAMESPACE");

Property ISNODELEVEL As %ZEN.Datatype.boolean(ZENURL = "ISNODELEVEL");

/// Displayed name of this page.
Parameter PAGENAME = "ShardingRebalance";

Parameter RESOURCE = "%Admin_Manage";

Property ShardingLicense As %Boolean;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property PageMessage As %String;

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}

a.radioSetCaption {
	color: #000000;
	font-size: 12px;
	font-weight: 600;
	text-align: left;
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
<button id="btnFinish" controlClass="commandButton" caption="Start" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<form>
<label id="Text1" value="" containerStyle="padding:10px;"/>
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:4px;padding-top:2px;" labelPosition="left">

<text id="TimeLimit" label="Maximum duration of the rebalance operation" size="3" value="0" hint="minutes"/>

 <html id="durationNote" OnDrawContent="DrawDuration" />
 </group>
 </form>
 <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>
 <label id="outputLabel" label=""/>
<iframe id="output" />
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	if (!this.ShardingLicense) {
		zen('form').setHidden(true);
	}
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var div = zen("output");
	var heightadj = 400;
	var wd = zenGetWindowWidth() - 20;
	var ht = zenGetWindowHeight() - heightadj;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	div.setProperty("width",wd);
	div.setProperty("height",ht);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ..ShardingLicense = $$Sharding^%SYS.LICENSE()
	Set ..%GetComponentById("Text1").value = $S(..ShardingLicense=1:$$$TextHTML("Rebalancing redistributes sharded data evenly across all data nodes, including those recently added to an existing cluster."),1:$$$TextHTML("Sharding is unavailable for current license."))
	Set tWhat = $S(..ISNODELEVEL:$$$Text("node-level cluster"),1:$$$Text("namespace-level cluster"))
	Set ..%GetComponentById("outputLabel").label = $$$FormatText($$$Text("Rebalance %1 in %2. "),tWhat,$zconvert($G(%request.Data("NAMESPACE",1)),"O","HTML"))_" "_$$$TextHTML("This task will be run in the background.")

	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Rebalance")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed '= "" {
		&html<<div class="ErrorBox"><pre>#(..EscapeHTML(seed))#</pre></div>>
	}
	Quit $$$OK
}

Method DrawResult(seed As %String) As %Status
{
	If seed '= "" {
		&html<<pre>#(..EscapeHTML(seed))#</pre>>
	}
	Quit $$$OK
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var ok = 1;
		var TimeLimit = zen('TimeLimit').getValue();
		if (!(TimeLimit.match(/\d/)) || (isNaN(TimeLimit))) {
			alert($$$Text("You entered an invalid entry for the time limit. Please enter a number."));
			zen('TimeLimit').focus();
			return;
		}
		var namespace = encodeURIComponent(this.NAMESPACE);
		var params = 'NAMESPACE=' + namespace + '&TimeLimit=' + TimeLimit + '&ISNODELEVEL=' + (this.ISNODELEVEL?1:0);
		zen('output').setProperty('src','_CSP.UI.Portal.Sharding.Dialog.RebalanceOutput.zen?'+params);
		zen('btnCancel').setProperty('caption',$$$Text("Done"));
		zen('btnFinish').setProperty('disabled',true);
		zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		zen('btnCancel').focus();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return false;
}

/// Start background job to cleanup a selected directory
ClassMethod StartRebalance(pMasterNamespace, pTimeLimit) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = $System.Sharding.Rebalance(pMasterNamespace, pTimeLimit, .pReport)
		Set %session.Data("Sharding","StartRebalance") = tSC
		 // pReport("Elapsed Seconds") is set to the elapsed time for this call, in seconds.
		 // pReport("Buckets Moved") is set to the number of buckets moved by this call.
		 // pReport("Buckets To Move") is set to the total number of buckets remaining to be moved.
		If $$$ISERR(tSC) {
			Set tProxy.error = $System.Status.GetErrorText(tSC)
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)	
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartRebalance: "_$ZE
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

Method DrawDuration(seed) As %Status
{
	Set hint = $$$TextHTML("Specify the maximum duration of the rebalancing operation. If all the time has been used before the operation is complete, it is paused and all cluster resources become fully available for queries again. The paused rebalancing operation can be resumed from this page at any time.")
	&html<<div class="zenHint">#(hint)#>
	Quit $$$OK
}

}
