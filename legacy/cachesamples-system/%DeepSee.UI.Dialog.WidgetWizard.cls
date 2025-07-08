/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog creates a new widget for a dashboard.
Class %DeepSee.UI.Dialog.WidgetWizard Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Data source name.
Property dataSource As %ZEN.Datatype.string;

/// Local data source name (if any).
Property localDataSource As %ZEN.Datatype.string;

/// Drill down data source name.
Property drillDownDataSource As %ZEN.Datatype.string;

/// Data link name.
Property dataLink As %ZEN.Datatype.string;

/// Name of widget (on the dashboard).
Property widgetName As %ZEN.Datatype.string(ZENURL = "WIDGETNAME");

/// Key for widget (if editing).
Property widgetKey As %ZEN.Datatype.string(ZENURL = "KEY");

/// Current selected widget type.
Property widgetType As %ZEN.Datatype.string;

/// Current selected widget subtype.
Property widgetSubtype As %ZEN.Datatype.string;

/// List of data series definitions for the widget.
Property dataSeriesDefs As list Of %DeepSee.Component.dataSeriesDefinition;

/// List of control definitions for the widget.
Property controlDefs As list Of %DeepSee.Component.controlDefinition;

/// List of data property definitions for the widget.
Property dataPropertyDefs As list Of %DeepSee.Component.dataPropertyDefinition;

/// Name used to save this widget to the catalog!
Property widgetTemplateName As %ZEN.Datatype.string;

/// Description of the widget (if any).
Property widgetDescription As %ZEN.Datatype.string;

/// Widget owner.
Property widgetOwner As %ZEN.Datatype.string(MAXLEN = 255);

/// Widget resource.
Property widgetResource As %ZEN.Datatype.string(MAXLEN = 255);

/// Keywords of the saved widget (if any).
Property widgetKeywords As %ZEN.Datatype.string;

/// Additional name/value pairs for the widget.
Property widgetPropertyArray As array Of %ZEN.Datatype.string;

/// List of current widget names on dashboard.
Property widgetNames As %ZEN.Datatype.csv(ZENURL = "NAMES");

/// Number of widgets on dashboard.
Property widgetCount As %ZEN.Datatype.csv(ZENURL = "COUNT");

/// Should dialog show the widget preview.
Property showPreview As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Name of dashboard used to hold preview copy.
Property previewName As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

body {
	background: #E0E0FF;
}

#body {
	background: #E0E0FF;
	overflow: hidden;
}

.zam-menu {
	width: 250px;
	height: 400px;
	background: #F8F8F8;
}

.zam-caption-1 {
	color: #404040;
    background: #C0C0C0;
    text-shadow: none;
    height: 30px;
}

.zam-caption-2,
.zam-caption-3 {
	vertical-align: top;
    height: 30px;
	color: #404040;
    background: white;
    text-shadow: none;
}

.zam-caption-1:hover {
	opacity: 1.0;
	color: black;
}

.zam-caption-2:hover,
.zam-caption-3:hover {
	opacity: 1.0;
	color: black;
	background: #FFEEAA;
}

.zam-caption-1:active,
.zam-caption-2:active,
.zam-caption-3:active {
	text-shadow: -1px 1px 8px #D0D0FF, 1px -1px 8px #D0D0D0;
}


#dataSourceGroup {
	background: #F0F0F0;
}

#widgetTypeHelp,
#widgetNameHelp,
#dataSourceHelp {
	font-size: 14px;
	color: #404040;
	width: 300px;
}

#optionsGroup {
	border: 1px solid darkgray;
	overflow: auto;
	width: 600px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
 import=""
cellStyle="padding-bottom:8px;"
>
<!-- set of available widgets -->
<jsonProvider id="jsonWidgetTypeList" OnGetArray="GetWidgetTypeList"/>

<hgroup cellVAlign="top">
<accordionMenu id="widgetMenu" controllerId="jsonWidgetTypeList" onselect="zenPage.selectWidgetType(key);"/>
<vgroup cellStyle="padding:10px;" labelPosition="top">
<html id="widgetTypeHelp"/>
<label id="lblWidgetType" label="Widget Family" value="" hidden="true" enclosingStyle="font-size:20px;" />
<label id="lblWidgetSubtype" label="Widget Subtype" value="" hidden="true" enclosingStyle="font-size:20px;"/>

<vgroup id="dataSourceGroup" hidden="true">
<html id="dataSourceHelp"/>
<hgroup cellVAlign="top">
<hgroup cellVAlign="top" label="Data source">
<text id="dataSource" size="40" onchange="zenPage.dataSourceChange();" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<image src="deepsee/zoom_24.png" title="Select a data source for this widget" onclick="zenPage.browseDataSources();"/>
<image src="deepsee/close_a_24.png" title="Clear the data source for this widget" onclick="zenPage.clearDataSource();"/>
</hgroup>
</hgroup>
<select id="dataLink" label="Link to" hint="Use same data source as another widget on the dashboard" onchange="zenPage.dataSourceChange();"/>
</vgroup>

<vgroup id="widgetNameGroup" hidden="true">
<html id="widgetNameHelp"/>
<text id="widgetName" label="Widget Name" required="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</vgroup>

</vgroup>
</hgroup>
</pane>
}

/// Apply changes to page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..hideApplyButton = 1

		// labels
		Set tLabel = ..%GetComponentById("widgetTypeHelp")
		Set tLabel.content = "<span style=""font-size:30px;"">1</span>&nbsp;"_$$$Text("Select the type of widget you wish to create using the menu on the left.","%DeepSee")

		Set tLabel = ..%GetComponentById("dataSourceHelp")
		Set tLabel.content = "<span style=""font-size:30px;"">2</span>&nbsp;"_$$$Text("Select a data source. The data source supplies the values displayed by the widget.","%DeepSee")

		Set tLabel = ..%GetComponentById("widgetNameHelp")
		Set tLabel.content = "<span style=""font-size:30px;"">3</span>&nbsp;"_$$$Text("Give this widget a unique name to identify it.","%DeepSee")

		If (..dashboardName = "") {
			Quit
		}

		Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
		If '$IsObject(tDashboard) {
			Set tSC = $$$ERROR($$$GeneralError,"Dashboard does not exist: " _ ..dashboardName)
			Quit
		}
		
		Set ..%GetComponentById("dataLink").valueList = ..widgetNames
		Set ..%GetComponentById("widgetName").value = $$$Text("Widget")_(..widgetCount+1)

		Set tWidgetDef = ""
		If ('$IsObject(tWidgetDef)) {
			// get default values
			Set tWidgetDef = ##class(%DeepSee.Dashboard.Widget).%New()
		}
		Set ..widgetType = tWidgetDef.type
		Set ..widgetSubtype = tWidgetDef.subtype
		Set ..dataSource = tWidgetDef.dataSource
		Set ..localDataSource = tWidgetDef.localDataSource
		Set ..dataLink = tWidgetDef.dataLink
		Set ..drillDownDataSource = tWidgetDef.drillDownDataSource
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Widget Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create a new dashboard widget")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
	}
	catch(ex) {
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var wname = zen('widgetName').getValue();
		if (wname.indexOf(',')>=0) {
			alert($$$Text('Widget name must not contain commas.'));
			return false;
		}
		
		if (wname) {
			var t = this.widgetNames.toString().split(',');
			for (var n = 0; n < t.length; n++) {
				if (t[n] == wname) {
					alert($$$Text('Widget name is already used. Please enter a new name.'));
					return false;
				}
			}
		}

		if (''==this.widgetType) {
			alert($$$Text('Please select a widget category'));
			return false;
		}

		var info = new zenProxy();
		info.widgetType = this.widgetType;
		info.widgetSubtype = this.widgetSubtype;

		info.dataSource = zen('dataSource').getValue();
		info.localDataSource = this.localDataSource;
		info.dataLink = zen('dataLink').getValue();
		var msg = this.AddWidgetToDashboard(this.dashboardName,wname,info);
		if ('' != msg) {
			alert(msg);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in WidgetWizard.ondialogFinish');
	}
	return true;
}

/// Add a widget to the given dashboard definition.
/// If <var>pPreview</var>, then save to the private preview dashboard.
Method AddWidgetToDashboard(pDashboardName As %String, pWidgetName As %String, pInfo As %ZEN.proxyObject, pPreview As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// pInfo is a proxyObject containing widget info
		Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(pDashboardName,.tSC)
		If '$IsObject(tDashboard) {
			Set tMsg = $$$Text("Please save dashboard before adding widgets")
			Quit
		}

		Set tWidgetDef = ""
		Set tWidth = 200
		Set tHeight = 200
		Set tWidgetDef = ##class(%DeepSee.Dashboard.Widget).%New()
		Set tWidgetDef.name = pWidgetName
		Set tWidgetDef.type = pInfo.widgetType
		Set tWidgetDef.subtype = pInfo.widgetSubtype
		Set tWidgetDef.title = pInfo.widgetTitle

		Set tWidgetDef.dataSource = pInfo.dataSource
		Set tWidgetDef.localDataSource = pInfo.localDataSource
		Set tWidgetDef.drillDownDataSource = pInfo.drillDownDataSource
		Set tWidgetDef.dataLink = pInfo.dataLink
		Set tWidgetDef.height = tHeight
		Set tWidgetDef.width = tWidth

		// !!! test against grid size
		Set tWidgetDef.homeRowL = 0
		Set tWidgetDef.homeColL = 0
		Set tWidgetDef.colSpanL = 4
		Set tWidgetDef.rowSpanL = 4
		Do tDashboard.widgets.Insert(tWidgetDef)

		Set tSC = tDashboard.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// User edit of dataSource.
ClientMethod dataSourceChange() [ Language = javascript ]
{
	var value = zen('dataSource').getValue();
	var link = zen('dataLink').getValue();
	if ((this.dataSource != value)||(this.dataLink != link)) {
		this.localDataSource = ''; // reset
		this.dataSource = value;
		this.dataLink = link;
		if (''==this.dataLink) {
			zen('dataSource').setProperty('disabled',false);
		}
		else {
			zen('dataSource').setProperty('disabled',true);
		}
		zen('dataSource').setProperty('controlStyle','');
	}
}

/// Clear the data source.
/// If there is a local override, first clear it and restore the original value.
ClientMethod clearDataSource() [ Language = javascript ]
{
	if (this.localDataSource!='') {
		// reset local overrider
		this.localDataSource = ''; // reset
		zen('dataSource').setProperty('controlStyle','');
	}
	else {
		zen('dataSource').setValue('');
		zen('dataSource').setProperty('controlStyle','');
		this.dataSource = '';
		this.localDataSource = '';
	}
	if ('' == this.dataLink) {
	}
}

/// Launch the data source finder.
ClientMethod browseDataSources() [ Language = javascript ]
{
	// launch finder according to type
	switch(this.widgetType) {
	case 'map':
	case 'pivot':
	case 'meter':
	case 'scoreCardWidget':
	case 'portlet':
	case 'controlPanel':		// DTB447
		this.loadPivot();
		break;
	case 'worksheet':
		this.loadWorksheet();
		break;
	default:
		this.loadKPI();
		break;
	}
}

/// Launch the data source finder.
ClientMethod browseDrillDataSources() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards','DrillDataSourceOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Clear the data source.
ClientMethod clearDrillDataSource() [ Language = javascript ]
{
	zen('drillDownDataSource').setValue('');
}

/// Launch the pivot finder dialog.
ClientMethod loadPivot() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=datasources','DataSourceOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the KPI finder dialog.
ClientMethod loadKPI() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=kpis','DataSourceOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the worksheet finder dialog.
ClientMethod loadWorksheet() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=worksheets','DataSourceOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'ChooseDataSource':
		if (this._controlId) {
			var ctrl = self.document.getElementById(this._controlId);
			if (ctrl) {
				ctrl.value = value;
				this.widgetPropertyChange();
			}
		}
		break;

	case 'DataSourceOpen':
		if ((this.dataSource != value) || (this.localDataSource!='')) {
			this.localDataSource = '';
			this.dataSource = value;
			zen('dataSource').setValue(value);
			zen('dataSource').setProperty('controlStyle','');
			if ('' == this.dataLink) {
			}
		}
		break;
	case 'DrillDataSourceOpen':
		zen('drillDownDataSource').setValue(value);
		break;
	}
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	var body = zen('body');
	var divBody = body.getEnclosingDiv();
	zen('widgetMenu').getEnclosingDiv().style.height = (divBody.offsetHeight-15)+'px';
}

/// Show data source finder for widget property control
ClientMethod chooseDataSource(id) [ Language = javascript ]
{
	this._controlId = id;
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=datasources','ChooseDataSource','status,scrollbars,resizable=yes,width=800,height=600');
}

/// User selected a widget type.
ClientMethod selectWidgetType(key) [ Language = javascript ]
{
	if (key) {
		var info = new zenProxy();
		// get more info on the selected widget
		var msg = this.GetWidgetInfo(key,info);
		if (msg) {
			alert(msg);
		}
		else {
			this.widgetType = info.type;
			this.widgetSubtype = info.subtype;

			zen('lblWidgetType').setHidden(!info.type);
			zen('lblWidgetType').setValue(info.typeName);
			zen('lblWidgetSubtype').setHidden(!info.subtype);
			zen('lblWidgetSubtype').setValue(info.subtypeName);

			zen('dataSourceGroup').setHidden(!info.type);
			zen('widgetNameGroup').setHidden(!info.type);
		}
	}
}

/// Get info on the selected widget.
ClassMethod GetWidgetInfo(pKey As %String, pInfo As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tClassName = $P(pKey,":",1)
		Set tType = $P($P(pKey,":",2),"/",1)
		Set tSubtype = $P($P(pKey,":",2),"/",2)
		Do $classmethod(tClassName,"%GetCatalogInfo",.tCatInfo,.tSubInfo)

		Set pInfo.type = tType
		Set pInfo.typeName = $LG($G(tCatInfo),2)
		Set pInfo.description = ""

		If ('$D(tSubInfo)||(tSubtype="")) {
			Set pInfo.subtype = ""
			Set pInfo.subtypeName = ""
		}
		Else {
			Set n = $O(tSubInfo(""))
			While (n'="") {
				If ($LG(tSubInfo(n),1)=tSubtype) {
					Set pInfo.subtype = tSubtype
					Set pInfo.subtypeName = $LG(tSubInfo(n),2)
					Quit
				}
				Set n = $O(tSubInfo(n))
			}
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Return JSON array of widget types.<br/>
Method GetWidgetTypeList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("key","caption","className","image")

		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetWidgetClasses(.tInfo)
		If $$$ISERR(tSC) Quit

		// loop over types
		Set tCount = 0
		Set tItem = $O(tInfo(""))
		While (tItem'="") {
			Set tName = $LG(tInfo(tItem),1)
			Set tTitle = $LG(tInfo(tItem),2)
			Set tClassName = $LG(tInfo(tItem),3)
			Set tImage = $LG(tInfo(tItem),4)

			Set pData($I(tCount)) = $LB("",tTitle,tClassName,"")

			// Find subtypes
			Do $classmethod(tClassName,"%GetCatalogInfo",,.tList)

			If $D(tList) {
				Set n = $O(tList(""))
				While (n'="") {
					Set tSubName = $LG(tList(n),1)
					Set tSubTitle = $LG(tList(n),2)
					Set tSubImage = $LG(tList(n),4)
					Set:tSubImage="" tSubImage = "deepsee/lamp_48.gif"

					Set pData(tCount,n) = $LB(tClassName_":"_tName_"/"_tSubName,tSubTitle,"",tSubImage)
					Set n = $O(tList(n))
				}
			}
			Else {
				// add synthetic item
					Set pData(tCount,1) = $LB(tClassName_":"_tName,tTitle,"",tImage)
			}

			Set tItem = $O(tInfo(tItem))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
