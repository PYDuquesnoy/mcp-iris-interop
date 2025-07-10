/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Dialog to report information during an attempt to update or change the status of a production.
Class EnsPortal.Dialog.UpdateProduction Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_ProductionRun or the %Ens_ConfigItemRun resource to view this page.
Parameter RESOURCE = "%Ens_ProductionRun:USE,%Ens_ConfigItemRun:USE";

Parameter APPLYBUTTON = 0;

Parameter CANCELBUTTON = 0;

Parameter CLOSEONESC = 2;

Parameter CLOSEONENTER = 1;

Parameter PAGENAME = "Production Update";

Property productionId As %ZEN.Datatype.className(ZENURL = "PRODUCTION");

/// Used so that the status update can advise more will be done.
Property itemRestart As %ZEN.Datatype.boolean(ZENURL = "ITEMRESTART") [ InitialExpression = 0 ];

Property action As %ZEN.Datatype.string(ZENURL = "ACTION");

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..action,
			"start"  : $$$TextHTML("Start Production"),
			"stop"   : $$$TextHTML("Stop Production"),
			"update" : $$$TextHTML("Production Updating..."),
			"recover": $$$TextHTML("Recovering Production..."),
			: $ZCVT($$$FormatText($$$Text("ERROR '%1'"),..action),"O","HTML"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod applyDetails() [ Language = javascript ]
{
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" align="left" valign="middle" >
<hgroup>
<label id="actionLabel" enclosingClass="labels" />
<spacer width="10" />
<label id="prodName" enclosingClass="labels" />
</hgroup>
<label id="msgWait" enclosingClass="" />
<iframe id="outputFrame" frameBorder="false" />
</pane>
}

XData Style
{
<style type="text/css">
#updateText {
	background: white;
	padding: 5px;
	border: 1px solid gray;
}
.labels {
	font-weight: bold;
	white-space: nowrap;
}
#msgWait {
	font-size: 11pt;
}
</style>
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
	Set tProdLabel = ..%GetComponentById("prodName")
	If $IsObject(tProdLabel) {
		Set tProdLabel.value = ..productionId
		Set tWait = ..%GetComponentById("msgWait")
		Set tWait.value = $$$TextHTML("Please wait, progress messages will appear below...")
	}
	Set tActionLabel = ..%GetComponentById("actionLabel")
	If $IsObject(tActionLabel) {
		Set tActionLabel.value = $Case(..action, 
										"start"  : $$$TextHTML("Starting Production: "),
										"stop"   : $$$TextHTML("Stopping Production: "),
										"update" : $$$TextHTML("Updating Production: "),
										"recover": $$$TextHTML("Recovering Production: "),
										: "-")
	}
	Set tOutputFrame = ..%GetComponentById("outputFrame")
	If $IsObject(tOutputFrame) && (tActionLabel.value'="-") {
		Set tQuery("ACTION") = ..action
		Set tQuery("PRODUCTION") = ..productionId
		Set tQuery("ITEMRESTART") = ..itemRestart
		Set tOutputFrame.src = ..Link("EnsPortal.StartStopFrame.cls", .tQuery)
	} Else {
		Set tActionLabel.value = "ERROR "_$ZCVT(..action,"O","HTML")
	} 
	Quit $$$OK
}

ClientMethod onresizeHandler() [ Language = javascript ]
{
	this.adjustSizes();
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.getComponentById('btnOK').focus();
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try{
		var totalHeight = zenGetWindowHeight();
		var totalWidth = zenGetWindowWidth();
		var frame = zenPage.getComponentById('outputFrame');
		var framew = totalWidth - 15;
		var frameh = totalHeight - 190;
		frame.setProperty('height',frameh);
		frame.setProperty('width',framew);
		if ((self.body.scrollWidth == self.body.offsetWidth) && (self.body.scrollLeft == 0 )) {
			frame.setProperty('height',totalHeight - 170);
		}
	}
	catch(ex){
		alert('Error in adjustSizes()');
	}
}

}
