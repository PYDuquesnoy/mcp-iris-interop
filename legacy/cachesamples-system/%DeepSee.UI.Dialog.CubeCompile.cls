/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog compiles a DeepSee cube definition and displays the output.
Class %DeepSee.UI.Dialog.CubeCompile Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dialog mode:<br/>
/// "compilecube" -- save a cube. "compilesub" -- compile a subjectarea. <br/>
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "compilecube" ];

/// Cube class name.
Property cubeClass As %ZEN.Datatype.string(ZENURL = "CLASS");

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Compile status
Property status As %ZEN.Datatype.string;

/// Compile tracking ID
Property trackingId As %ZEN.Datatype.integer;

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
<label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" controlClass="labelValue"/>
<timer id="timer" ontimeout="zenPage.timeout();"/>
<iframe id="output"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..mode,"compilesub":$$$TextHTML("Compile Subject Area"),:$$$TextHTML("Compile Cube"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $Case(..mode,"compilesub":$$$TextHTML("Compile this subject area definition."),:$$$TextHTML("Compile this cube definition."))
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
	this.compile();
	this.onresizeHandler();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..cubeClass = ..EscapeHTML(..cubeClass)
		If ..mode = "compilesub" Set ..%GetComponentById("cubeName").label = $$$Text("Subject Area Name")
		Set ..trackingId = $I(^IRIS.Temp.DeepSeeCubeCompile)		// DTB946
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
	// DTB946 - Include the unique tracking number in the url so this dialog can track progress of the embedded output
	zen('output').setProperty('src','_DeepSee.UI.Dialog.CubeCompileOutput.cls?CUBECLASS=' + encodeURIComponent(this.cubeClass) + '&TRACKINGID=' + encodeURIComponent(this.trackingId));
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
	this.status = this.CheckStatus(this.cubeClass,this.trackingId);		// DTB946 - Include trackingId for this instance of the compile
	if ((this.status != 'Done')&&(this.status != 'Error')) {
		zen('timer').timeout = 500;
		zen('timer').startTimer();
	}
	else {
		zen('btnCancel').setDisabled(false);
		// when build finished, set focus on Cancel button so [Enter] key will exit easily.
		zen('btnCancel').setProperty('caption',$$$Text('Done'));
		zen('btnCancel').focus();
		
		if ('compilecube'==this.mode) {
			// DP-417293 - Disable the parent page's Build button if the cube being compiled is abstract.
			var cube = this.getOpener().zenPage.getCubeObject();
			if (('Error' == this.status) || cube.abstract) {
				this.getOpener().zenPage.disableCommandButton('cmdBuild');
			}
			else if ('Done' == this.status) {
				this.getOpener().zenPage.enableCommandButton('cmdBuild');
			}
		}
	}
	return;
}

ClassMethod CheckStatus(pCubeClass, pTrackingId) As %String [ ZenMethod ]
{
	// DTB946 - This is no longer dependent on the job number. The specific node in the tracking global will be 
	// passed in after being set on open of this dialog
	Set IsComplete = $G(^IRIS.Temp.DeepSeeCubeCompile($Username,pCubeClass,pTrackingId))
	If IsComplete = "Done" {
		// DTB918 - Report a compile error
		Set:$D(^IRIS.Temp.DeepSeeCubeCompile($Username,pCubeClass,pTrackingId,"error")) IsComplete = "Error" 
		Kill ^IRIS.Temp.DeepSeeCubeCompile($Username,pCubeClass,pTrackingId)
	}
	Quit IsComplete
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	this.compile();
	return false;
}

}
