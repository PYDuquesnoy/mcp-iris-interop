/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This persistent class represents the contents of a user-defined DeepSee dashboard.<br/>
/// APIs for dealing with Dashboard definitions are in the <class>%DeepSee.Dashboard.Utils</class> class.<br/>
/// The logic for converting definitions into visible items is in 
/// the <class>%DeepSee.UserPortal.DashboardViewer</class> class.<br/>
Class %DeepSee.Dashboard.Definition Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

Parameter XMLNAME = "dashboard";

Parameter ITEMTYPE = "dashboard";

Parameter ICON = "deepsee/ds2_dashboard_22.png";

Parameter LARGEICON = "deepsee/ds2_dashboard_44.png";

/// Name of color scheme to use for this dashboard.
Property scheme As %String(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Number of worklist boxes to display on the page.
Property worklistCount As %Integer(MAXVAL = 2, MINVAL = 0, XMLPROJECTION = "attribute") [ InitialExpression = 2 ];

/// Set of visual widgets displayed on this dashboard.
Property widgets As list Of Widget(XMLNAME = "widget", XMLPROJECTION = "element");

/// Dashboard is in "snap to grid" mode.
Property snapTo As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Dashboard uses the new snapGrid layout mode.
Property snapGrid As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Number of rows when using the new snapGrid layout mode.
Property gridRows As %Integer(XMLPROJECTION = "attribute") [ InitialExpression = 10 ];

/// Number of columns when using the new snapGrid layout mode.
Property gridCols As %Integer(XMLPROJECTION = "attribute") [ InitialExpression = 10 ];

/// User can move and resize widgets.
Property canResize As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// User can change widget definitions.
Property canModify As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Display widget title bars.
Property showTitleBar As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Specify opacity of title bars.
Property titleBarOpacity As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Specify color of title bars.
Property titleBarColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify opacity of title bars.
Property selectedTitleBarOpacity As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Specify color of title bars.
Property selectedTitleBarColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify color of title bars.
Property titleBarTextColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify color of title bar text for selected widgets.
Property selectedTitleBarTextColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify font of title bar text
Property titleBarFont As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Local override of company name.
Property companyName As %String(MAXLEN = 512, XMLPROJECTION = "attribute");

/// Local override of company logo.
Property companyLogo As %String(MAXLEN = 512, XMLPROJECTION = "attribute");

/// Local override of company style.
Property companyStyle As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// background color of dashboard
Property backgroundColor As %ZEN.Datatype.color [ InitialExpression = "white" ];

/// background image of dashboard
Property backgroundImage As %ZEN.Datatype.string [ InitialExpression = "none" ];

/// background image of dashboard
Property backgroundRepeat As %ZEN.Datatype.string [ InitialExpression = "no-repeat" ];

/// background image of dashboard
Property backgroundSize As %ZEN.Datatype.string [ InitialExpression = "100% 100%" ];

/// background opacity of dashboard
Property backgroundOpacity As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// border of widgets in dashboard
Property widgetBorders As %ZEN.Datatype.string [ InitialExpression = "1px solid #F0F0F0" ];

/// Whether border is none, inherit or "width style color"
Property widgetBordersSwitch As %ZEN.Datatype.string [ InitialExpression = "edit" ];

/// color of widgets border
Property widgetBordersColor As %ZEN.Datatype.string [ InitialExpression = "#F0F0F0" ];

/// style of widgets border, e.g. solid, dashed, dotted
Property widgetBordersStyle As %ZEN.Datatype.string [ InitialExpression = "solid" ];

/// width of widgets border 
Property widgetBordersWidth As %ZEN.Datatype.string [ InitialExpression = "1" ];

/// Whether borders of widgets are on or off
Property widgetBordersToggle As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = ##class(%DeepSee.UserPortal.Utils).%GetViewerURL()
	Set tURL = tURL _ $S(tURL["?":"&",1:"?") _ "DASHBOARD="_$ZCVT($ZCVT(..fullName,"O","UTF8"),"O","URL")
	Quit tURL
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit $$$Text("Dashboard","%DeepSee")
}

/// Return a list of all other folder items (including cubes or kpis) that this item depends upon.
Method %GetDependencies(pList As %String) As %Status
{
	For n=1:1:..widgets.Count() {
		Set tWidget = ..widgets.GetAt(n)
		If '$D(pList(..fullName)) {
			Set tSC = tWidget.%GetDependencies(.pList)
		}
	}
	Quit ##super(.pList)
}

Method %CopyToDao(ByRef pDynamicObj As %DynamicObject = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK

	// DP-427658 - Initialize a new dynamic object if no object is provided
	Set:('$IsObject(pDynamicObj)) pDynamicObj = {}
 
	// Properties that are useful to client visualization tools
	// DP-436046 - Add the canvas style and widget geometry
	Set pDynamicObj.name = ..name
	Set pDynamicObj.fullName = ..fullName
	Set pDynamicObj.description = ..description
	Set pDynamicObj.title = ..title
	Set pDynamicObj.canModify = ..canModify
	Set pDynamicObj.snapTo = ..snapTo
	Set pDynamicObj.snapGrid = ..snapGrid
	Set pDynamicObj.gridCols = ..gridCols
	Set pDynamicObj.gridRows = ..gridRows

	Try {
		Set pDynamicObj.widgets = []
		Set pDynamicObj.widgetsGeometry = []		// DP-436046
	
		For n=1:1:..widgets.Count() {
			Set tWidgetJSONObj = {}
			Set tWidgetGeometry = {}
			Set tWidget = ..widgets.GetAt(n)
			Set tSC = tWidget.%CopyToDao(.tWidgetJSONObj)
			If $$$ISERR(tSC) Quit
			Do pDynamicObj.widgets.%Push(tWidgetJSONObj)

			// DP-436046 - Add this widget's display geometry to export
			Set tWidgetGeometry.name = tWidget.name
			Set tWidgetGeometry.homeRow = tWidget.homeRowL
			Set tWidgetGeometry.homeCol = tWidget.homeColL
			Set tWidgetGeometry.rowSpan = tWidget.rowSpanL
			Set tWidgetGeometry.colSpan = tWidget.colSpanL
			Set tWidgetGeometry.width = tWidget.width
			Set tWidgetGeometry.height = tWidget.height
			Set tWidgetGeometry.top = tWidget.top
			Set tWidgetGeometry.left = tWidget.left
			Do pDynamicObj.widgetsGeometry.%Push(tWidgetGeometry)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Diagnostic method: display contents of this folder item to the console.
Method %Dump() As %Status
{
	Set tSC = ##super()
	If $$$ISOK(tSC) {
		Write "Widgets:",?25,..widgets.Count(),!
		For n=1:1:..widgets.Count() {
			Set tSC = ..widgets.GetAt(n).%Dump()
			If $$$ISERR(tSC) Quit
		}
	}
	Quit tSC
}

Storage Default
{
<Data name="DefinitionDefaultData">
<Subscript>"Definition"</Subscript>
<Value name="1">
<Value>scheme</Value>
</Value>
<Value name="2">
<Value>title</Value>
</Value>
<Value name="3">
<Value>widgets</Value>
</Value>
<Value name="4">
<Value>controls</Value>
</Value>
<Value name="5">
<Value>worklistCount</Value>
</Value>
<Value name="6">
<Value>snapTo</Value>
</Value>
<Value name="7">
<Value>snapGrid</Value>
</Value>
<Value name="8">
<Value>gridRows</Value>
</Value>
<Value name="9">
<Value>gridCols</Value>
</Value>
<Value name="10">
<Value>canResize</Value>
</Value>
<Value name="11">
<Value>canModify</Value>
</Value>
<Value name="12">
<Value>showTitleBar</Value>
</Value>
<Value name="13">
<Value>companyName</Value>
</Value>
<Value name="14">
<Value>companyLogo</Value>
</Value>
<Value name="15">
<Value>companyStyle</Value>
</Value>
<Value name="16">
<Value>backgroundColor</Value>
</Value>
<Value name="17">
<Value>backgroundImage</Value>
</Value>
<Value name="18">
<Value>backgroundRepeat</Value>
</Value>
<Value name="19">
<Value>backgroundSize</Value>
</Value>
<Value name="20">
<Value>backgroundOpacity</Value>
</Value>
<Value name="21">
<Value>widgetBorders</Value>
</Value>
<Value name="22">
<Value>widgetBordersSwitch</Value>
</Value>
<Value name="23">
<Value>widgetBordersColor</Value>
</Value>
<Value name="24">
<Value>widgetBordersStyle</Value>
</Value>
<Value name="25">
<Value>widgetBordersWidth</Value>
</Value>
<Value name="26">
<Value>widgetBordersToggle</Value>
</Value>
<Value name="27">
<Value>titleBarOpacity</Value>
</Value>
<Value name="28">
<Value>titleBarColor</Value>
</Value>
<Value name="29">
<Value>userModifiedTitleBars</Value>
</Value>
<Value name="30">
<Value>selectedTitleBarOpacity</Value>
</Value>
<Value name="31">
<Value>selectedTitleBarColor</Value>
</Value>
<Value name="32">
<Value>titleBarTextColor</Value>
</Value>
<Value name="33">
<Value>selectedTitleBarTextColor</Value>
</Value>
<Value name="34">
<Value>titleBarFont</Value>
</Value>
</Data>
<DefaultData>DefinitionDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
