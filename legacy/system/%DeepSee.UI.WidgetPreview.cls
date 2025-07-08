/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// DeepSee Widget Preview page.
/// Displays a transient version of a widget for the widget builder page.
/// (Restored)
Class %DeepSee.UI.WidgetPreview Extends %ZEN.Component.page [ System = 4 ]
{

Parameter CSPURL = "%DeepSee.UI.WidgetPreview";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

Parameter PAGENAME = "Widget Preview";

/// Name of dashboard containing widget.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Name of catalog containing widget.
Property catalogName As %ZEN.Datatype.string(ZENURL = "CATALOG");

XData Style
{
<style type="text/css">

body {
	overflow:hidden;
}

#theWidget {
	overflow:hidden;
}

.dragChildren {
	overflow:hidden;
}

#desktop {
	width: 350px;
	height: 350px;
	overflow: hidden;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee" import="%DeepSee.Component.Widget.pivot">
<desktop id="desktop"/>
<label id="msg" hidden="true"/>
</page>
}

Method %OnAfterCreatePage() As %Status
{
	Set tDesktop = ..%GetComponentById("desktop")
	Set tLabel = ..%GetComponentById("msg")
	Set tWidgetDef = ""

	If (..catalogName'="") {
		Set tTemplate = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..catalogName,.tSC)
		If $$$ISERR(tSC) Quit
		If ($IsObject( tTemplate)) {
			Set tWidgetDef =  tTemplate.widget
		}
	}
	ElseIf (..dashboardName'="") {
		// get saved dashboard
		Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
		If $$$ISERR(tSC) Quit tSC
		If ($IsObject(tDashboard)) {
			Set tWidgetDef = tDashboard.widgets.GetAt(1)
		}
	}


	If '$IsObject(tWidgetDef) {
		Set tDesktop.hidden = 1
		Set tLabel.hidden = 0
		Set tLabel.value = "Nothing to display"
	}
	Else {
		// create actual widget from definition
		Set tURLSettings("initialExecute") = 0
		Set tSC = tWidgetDef.%CreateVisualWidget(.tWidget,.tURLSettings,1)
		If $$$ISERR(tSC) Quit

		Set tWidget.id = "theWidget"
		Set tWidget.previewMode = 1
		Set tWidget.height = 350
		Set tWidget.width = 350
		Do tDesktop.%AddChild(tWidget)
	}

	Quit $$$OK
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();
	var desktop = zen('desktop');
	var widget = zen('theWidget');
	if (desktop) {
		var desktopDiv = desktop.getEnclosingDiv();
		desktopDiv.style.height = winHeight + 'px';
		desktopDiv.style.width = winWidth + 'px';
	}
	
	if (widget && load) {
		// refresh contents of widget
		widget.applyFilters(true);
	}
}

/// Add include files to support color schemes.
Method %OnDrawHTMLHead() As %Status
{
	// Copied from dashboard viewer!
	Do ##class(%DeepSee.UserPortal.Utils).%GetPreferences(.tPrefs)
	Set tScheme = $G(tPrefs("Scheme"))

	// check for URL override
	If ($D(%request.Data("SCHEME",1))) {
		Set tScheme = $$$LOWER($G(%request.Data("SCHEME",1)))
	}

	If (tScheme '= "") {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetColorSchemeInfo(tScheme,.tInfo)

		// CSS file
		Set tCSSFile = $G(tInfo("css"))
		If (tCSSFile'="") {
			Write "<link rel=""stylesheet"" type=""text/css"" href="""_tCSSFile_"""/>",!
		}

		// Initializer file for SVG components
		Set tInitFile = $G(tInfo("js"))
		If (tInitFile'="") {
			Write "<script type=""text/javascript"" src="""_tInitFile_"""></script>",!
		}
	}

	Quit $$$OK
}

}
