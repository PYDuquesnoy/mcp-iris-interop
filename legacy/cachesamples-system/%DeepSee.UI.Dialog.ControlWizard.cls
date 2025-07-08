/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog creates a new control for a dashboard widget.
/// (Copied from old control edit dialog).
Class %DeepSee.UI.Dialog.ControlWizard Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Index of control within parent dialog list or "" for new.
Property controlNumber As %ZEN.Datatype.string(ZENURL = "NUMBER");

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Data source name.
Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

/// Name of widget.
Property widgetName As %ZEN.Datatype.string(ZENURL = "WIDGETNAME");

/// List of all widget names.
Property widgetNames As %ZEN.Datatype.csv(ZENURL = "WIDGETNAMES");

/// This provides the ability to initialize the Target field on load.
Property defaultTarget As %ZEN.Datatype.string(ZENURL = "TARGET");

/// Logical value of the control default
Property defaultCtrlValue As %ZEN.Datatype.string;

/// Display text of the control default
Property defaultCtrlText As %ZEN.Datatype.string;

/// List of action types.
Property actionTypes As list Of %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<radioSet id="controlLocation" hidden="false" label="Location" 
	hint="Location of control or source of event" 
	title="Widget: place control on widget; Dashboard: place control on dashboard; OnClick: apply action when widget is clicked"
	valueList="widget,dashboard,click" displayList="Widget,Dashboard,Onclick Event"/>

<combobox id="controlTarget" editable="true" unrestricted="true" label="Target" hint="Name of widget to apply the action to. Use * for all, blank for this widget."/>

<hgroup>
<select id="controlAction" label="Action" hint="Action for this control" title="Action to take when this control is activated." onchange="zenPage.actionChange(true);"/>
<spacer width="10"/>
<select id="controlProperty" label="Filter" hint="Filter to apply the action to." onchange="zenPage.changeProperty();"/>
<spacer width="10"/>
<select id="controlPropertyListing" label="Listing" hint="Listing to show. Leave empty for default listing."/>
<spacer width="10"/>
<select id="controlPropertyGeoListing" label="Geo Listing" hint="Geo listing to show."/>
<spacer width="10"/>
<select id="controlPropertyPivotVariable" label="Pivot Variable" hint="Pivot variable to apply."/>
<spacer width="10"/>
<text id="controlPropertyDB" label="Dashboard" hint="Dashboard to navigate to" size="40"/>
<image id="imgPropertyDB" src="deepsee/zoom_24.png" title="Select a dashboard" onclick="zenPage.browseDashboards();"/>
<spacer width="10"/>
<text id="controlPropertyURL" label="URL" hint="URL to navigate to" size="40"/>
<spacer width="10"/>
<text id="controlPropertyValue" label="Value" hint="Value for the action" size="20"/>
<spacer width="10" />
<select id="controlPropertyAnalysis" label="Analysis" hint="Analysis screen to display." />
<spacer width="10" />
<textarea id="dataSourceValue" cols="30" rows="2"/>
<image id="controlTermLists" src="deepsee/zoom_24.png" title="browse term lists" onclick="zenPage.browseTermLists();"/>
<image id="controlDataSources" src="deepsee/zoom_24.png" title="browse data sources" onclick="zenPage.browseDataSources();"/>
</hgroup>

<hgroup label="Type">
<select id="controlType" valueList="auto,dropdown,searchBox,button,hidden,timer,custom" hint="Type of control to display" onchange="zenPage.controlTypeChange(zenThis.getValue());"/>
<spacer width="10"/>
<selector id="controlClass" hint="Custom control" hidden="true" size="40" context="/Classes?super=%ZEN.Component.control&amp;system=1"/>
<spacer width="10"/>
<text id="controlTimer" hint="Time (in seconds)" hidden="true" size="4"/>
</hgroup>

<hgroup cellVAlign="top">
<combobox id="controlLabel" label="Control Label or Icon" editable="true" unrestricted="true" hint="Label displayed for this control; Use &quot;@iconname&quot; to show an icon"/>
<spacer width="10"/>
<select id="controlActiveWhen" label="Active When" hint="When is this control enabled" showEmpty="false" valueList=",itemSelected,listingSelected1,listingSelected" displayList="Always,Item Selected,1 Listing Item Selected,Listing Item Selected"/>
</hgroup>

<hgroup cellVAlign="top">
<text id="controlTitle" label="Control Tooltip" hint="Tooltip displayed for this control"/>
<spacer width="20"/>
<text id="controlSize" size="3" label="Control Size" hint="Optional size applied to control"/>
<spacer width="20"/>
<checkbox id="controlReadOnly" label="Read Only"/>
</hgroup>

<hgroup cellVAlign="middle">
<text id="controlValue" label="Default Value" size="50" hint="Optional. Default value for the control."/>
<spacer width="5"/>
<image src="deepsee/ds2_magnify_18.png" title="Show the default value editor" onclick="zenPage.showDefaultValueEditor();"/>
<spacer width="20"/>
<checkbox id="controlValRequired" label="Value Required"/>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Control Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add a control to this widget.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();
		var widgetDef = main.zenPage.getWidgetDefinition(main.zenPage.currWidgetKey);
		if (widgetDef) {
			var control = {};
			control.value = this.defaultCtrlValue;		// DTB442
			control.text = this.defaultCtrlText;		// DTB442
			control.label = zen('controlLabel').getValue();
			control.activeWhen = zen('controlActiveWhen').getValue();
			control.title = zen('controlTitle').getValue();
			control.size = zen('controlSize').getValue();
			control.readOnly = zen('controlReadOnly').getValue();
			control.action = zen('controlAction').getValue();
			control.type = zen('controlType').getValue();
			control.target = zen('controlTarget').getValue();
			control.controlClass = zen('controlClass').getValue();
			control.timeout = zen('controlTimer').getValue();
			control.valueRequired = zen('controlValRequired').getValue();		// DTB140
			
			// action type determines what the targetProp is
			var ctrl = zen('controlAction');
			var type = this.actionTypes[ctrl.getSelectedIndex()];

			// set default label for some actions
			if (control.label=='') {
				switch(control.action) {
				case 'setDataSource':
				case 'chooseDataSource':
					control.label = $$$Text('Data','%DeepSee');
					break;
				case 'setRowSpec':
				case 'chooseRowSpec':
					control.label = $$$Text('Rows','%DeepSee');
					break;
				case 'setColumnSpec':
				case 'chooseColumnSpec':
					control.label = $$$Text('Columns','%DeepSee');
					break;
				}
			}

			switch (type) {
			case 'url':
				control.targetProperty = zen('controlPropertyURL').getValue();
				break;
			case 'dashboard':
				control.targetProperty = zen('controlPropertyDB').getValue();
				break;

			default:
				if (control.action == 'showListing') {
					// target property is name of listing
					control.targetProperty = zen('controlPropertyListing').getValue();
				}
				else if (control.action == 'showGeoListing') {
					// target property is name of listing
					control.targetProperty = zen('controlPropertyGeoListing').getValue();
				}
				else if (control.action == 'applyVariable') {
					// target property is name of variable
					control.targetProperty = zen('controlPropertyPivotVariable').getValue();
				}
				else if (control.action == 'showBreakdown') {
					// target property is name of pivot analysis option
					control.targetProperty = zen('controlPropertyAnalysis').getValue();
				}
				else if (control.action == 'chooseDataSource' || control.action == 'setDataSource' || control.action == 'chooseRowSpec' || control.action == 'setRowSpec' || control.action == 'chooseColumnSpec' || control.action == 'setColumnSpec') {
					control.targetProperty = zen('dataSourceValue').getValue(); 
				}
				else {
					control.targetProperty = zen('controlProperty').getValue();
					control.targetPropertyDisplay = zen('controlProperty').getOptionText(zen('controlProperty').getSelectedIndex());
				}
				break;
			}

			control.location = zen('controlLocation').getValue();
			if ('' == control.location || 'undefined' == typeof control.location) {
				control.location = 'widget';
			}
			
			if (!widgetDef.controls) {
				widgetDef.controls = [];
			}
			// WAL064 -- we must always add controls to the end of the array
			widgetDef.controls[widgetDef.controls.length] = control;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		var main = this.getOpener();
		var widgetDef = main.zenPage.getWidgetDefinition(main.zenPage.currWidgetKey);

		if ('controlPanel'==widgetDef.type) {
			// DTB442 - Hide the location since it isn't useful for this widget
			zen('controlLocation').setHidden(true);
		}

		zen('controlType').setValue('auto');
		zen('controlLocation').setValue('widget');
		
		// hide/show controls
		this.actionChange(false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Updates the datasources field in the control wizard when the user picks a data source from a finder dialog.
ClientMethod updateForm(val) [ Language = javascript ]
{
	var action = zen('controlAction').getValue();
	if (action == "chooseDataSource" || action == "setDataSource" || action == 'chooseRowSpec' || action == 'chooseColumnSpec') {
		zen('dataSourceValue').setValue(val)
	}
}

/// User selected a new control type.
ClientMethod controlTypeChange(type) [ Language = javascript ]
{
	if (type=='custom') {
		zen('controlClass').setHidden(false);
		zen('controlClass').adjustSize();
	}
	else if (type=='timer') {
		zen('controlTimer').setHidden(false);
		zen('controlClass').setHidden(true);
	}
	else {
		zen('controlTimer').setHidden(true);
		zen('controlClass').setHidden(true);
	}
}

/// User selected a new action type.
ClientMethod actionChange(clear) [ Language = javascript ]
{
	// hide/show value controls
	var ctrl = zen('controlAction');
	var type = this.actionTypes[ctrl.getSelectedIndex()];

	zen('controlProperty').setHidden(true);
	zen('controlPropertyDB').setHidden(true);
	zen('imgPropertyDB').setHidden(true);
	zen('controlPropertyURL').setHidden(true);
	zen('controlPropertyValue').setHidden(true);
	zen('controlPropertyListing').setHidden(true);
	zen('controlPropertyGeoListing').setHidden(true);
	zen('controlPropertyPivotVariable').setHidden(true);
	zen('controlPropertyAnalysis').setHidden(true);
	zen('dataSourceValue').setHidden(true);
	zen('controlDataSources').setHidden(true);
	zen('controlTermLists').setHidden(true);
	

	if (ctrl.getValue()=='showListing') {
		zen('controlPropertyListing').setHidden(false);
	}
	else if (ctrl.getValue()=='showGeoListing') {
		zen('controlPropertyGeoListing').setHidden(false);
	}
	else if (ctrl.getValue()=='applyVariable') {
		zen('controlPropertyPivotVariable').setHidden(false);
	}
	else if(ctrl.getValue()=='chooseDataSource' || ctrl.getValue()=='chooseColumnSpec' || ctrl.getValue()=='chooseRowSpec') {
		zen('controlTermLists').setHidden(false);
		zen('dataSourceValue').setHidden(false);
		zen('dataSourceValue').setProperty('label', 'Name of termlist');
	}
	else if(ctrl.getValue()=='setDataSource'){
		zen('controlDataSources').setHidden(false);
		zen('dataSourceValue').setHidden(false);
		zen('dataSourceValue').setProperty('label', 'DataSource path');
	}
	else if(ctrl.getValue()=='setColumnSpec' || ctrl.getValue()=='setRowSpec') {
		zen('dataSourceValue').setHidden(false);
		zen('dataSourceValue').setProperty('label', 'Name of Dimension');
	}
	
	zen('controlActiveWhen').setValue('');
	
	if (ctrl.getValue()=='showBreakdown') {
		zen('controlPropertyAnalysis').setHidden(false);
		zen('controlActiveWhen').setValue('itemSelected');
	}
	else if (ctrl.getValue()=='showListing') {
		zen('controlActiveWhen').setValue('itemSelected');		// DTB532
	} else {
		zen('controlActiveWhen').setValue('');
	}

	switch (type) {
	case 'filter':
		if (clear) {
			zen('controlProperty').setValue('');
		}
		zen('controlProperty').setHidden(false);
		break;
	case 'url':
		if (clear) {
			zen('controlPropertyURL').setValue('');
		}
		zen('controlPropertyURL').setHidden(false);
		break;
	case 'dashboard':
		if (clear) {
			zen('controlPropertyDB').setValue('');
		}
		zen('controlPropertyDB').setHidden(false);
		zen('imgPropertyDB').setHidden(false);
		break;
	case 'value':
		if (clear) {
			zen('controlPropertyValue').setValue('');
		}
		zen('controlPropertyValue').setHidden(false);
		break;
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// get filters from data source
		Set tValueList = ""
		Set tDisplayList = ""

		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(..dataSource,.tFilters)
		If $$$ISERR(tSC) Quit

		Set a = $O(tFilters(""))
		While (a'="") {
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tFilters(a),1)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $LG(tFilters(a),2)
			If (($L(tDisplayList)>31000)||($L(tValueList)>31000)) {
				Quit
			}
			Set a = $O(tFilters(a))
		}

		// add *searchable* measures to the lists
		Set tExt = $P(..dataSource,".",$L(..dataSource,"."))
		If (tExt = "pivot") {
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource,.tSC)
			If '$IsObject(tPivot) Quit

			Set tSC = ##class(%DeepSee.Utils).%GetCubeSearchableMeasures(tPivot.%GetCubeName(),.tMeasures)
			If $$$ISERR(tSC) Quit

			Set n = $O(tMeasures(""))
			While (n'="") {
				// + WAL163 -- Cube searchable measures are returned with logical value in postion 1 and display
				//             value in position two
				//Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ "Measures."_$LG(tMeasures(n),1)
				//Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "[Measures].["_$LG(tMeasures(n),2)_"]"
				Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ "Measures."_$LG(tMeasures(n),2)
				Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "[Measures].["_$LG(tMeasures(n),1)_"]"
				// - WAL163
				If (($L(tDisplayList)>31000)||($L(tValueList)>31000)) {
					Quit
				}
				Set n = $O(tMeasures(n))
			}
		}

		Set tPropertyCtrl = ..%GetComponentById("controlProperty")
		Set tPropertyCtrl.showEmpty = 1
		Set tPropertyCtrl.displayList = tDisplayList
		Set tPropertyCtrl.valueList = tValueList
		If (tValueList="") {
			Set tPropertyCtrl.valueList = $$$Text("No Data Source","%DeepSee")
			Set tPropertyCtrl.disabled = 1
		}
		Set tTargetCtrl = ..%GetComponentById("controlTarget")
		Set tTargetCtrl.value = ..defaultTarget		// DTB442 - Set target according to context from the caller
		Set tTargetCtrl.valueList = "*"_$S(..widgetNames="":"",1:",")_..widgetNames

		// get table listings from data source
		Set tListingCount = 0
		Set tValueList = ""
		Set tDisplayList = ""

		Kill tListings
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(..dataSource,.tListings,"table")
		If $$$ISERR(tSC) Quit

		Set a = $O(tListings(""))
		While (a'="") {
			Set tListingCount = tListingCount + 1
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tListings(a),1)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $LG(tListings(a),2)
			Set a = $O(tListings(a))
		}

		Set tListingCtrl = ..%GetComponentById("controlPropertyListing")
		Set tListingCtrl.showEmpty = 1
		Set tListingCtrl.displayList = tDisplayList
		Set tListingCtrl.valueList = tValueList

		// get table listings from data source
		Set tValueList = ""
		Set tDisplayList = ""
		Set tGeoListingCount = 0
		Set tIKnowMeasureCount = 1

		Kill tListings
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(..dataSource,.tListings,"map")
		If $$$ISERR(tSC) Quit

		Set a = $O(tListings(""))
		While (a'="") {
			Set tGeoListingCount = tGeoListingCount + 1
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tListings(a),1)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $LG(tListings(a),2)
			Set a = $O(tListings(a))
		}

		Set tListingCtrl = ..%GetComponentById("controlPropertyGeoListing")
		Set tListingCtrl.showEmpty = 0
		Set tListingCtrl.displayList = tDisplayList
		Set tListingCtrl.valueList = tValueList
		
		// JMD1276: get pivot variables
		Kill tVariables
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetPivotVariablesForDataSource(..dataSource,.tVariables)
		If $$$ISERR(tSC) Quit

		Set tValueList = ""
		Set tDisplayList = ""
		Set a = $O(tVariables(""))
		While (a'="") {
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tVariables(a),2)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "$variable." _ $LG(tVariables(a),1)
			Set a = $O(tVariables(a))
		}

		Set tListingCtrl = ..%GetComponentById("controlPropertyPivotVariable")
		Set tListingCtrl.showEmpty = 0
		Set tListingCtrl.displayList = tDisplayList
		Set tListingCtrl.valueList = tValueList

		// BDB263: append analysis options
		set tValueList = "_DeepSee.UI.Analysis.Clustering.zen,_DeepSee.UI.Analysis.Distribution.zen,_DeepSee.UI.Analysis.Regression.zen" 
		set tDisplayList = "Clustering,Distribution,Regression"
		if (1) { // perhaps check if there's any iKnow measures first?
			set tValueList = tValueList _ ",_iKnow.DeepSee.UI.Analysis.Content.zen,_iKnow.DeepSee.UI.Analysis.Entities.zen"
			set tDisplayList = tDisplayList _ ",iKnow - content,iKnow - entities"
		}
		set tAnalysisControl = ..%GetComponentById("controlPropertyAnalysis")
		set tAnalysisControl.valueList = tValueList
		set tAnalysisControl.displayList = tDisplayList

		// list of user-defined icons
		Set tIconNames  = ""
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserIconList(.tUserList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tUserList(""))
		While (k'="") {
			Set tName = $LG(tUserList(k),1)
			Set tIconNames = tIconNames _ $S(tIconNames="":"",1:",") _ "@"_tName
			Set k = $O(tUserList(k))
		}
		Set tLabelCtrl = ..%GetComponentById("controlLabel")
		Set tLabelCtrl.valueList = tIconNames

		// actions
		Set tValueList = ""
		Set tDisplayList = ""
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetDashboardActionList(.tActions,..dataSource)
		If $$$ISERR(tSC) Quit

		Set a = $O(tActions(""))
		While (a'="") {
			Set tValue = $LG(tActions(a),1)
			Set tSkip = 0
			If ((tValue="showListing")&&(tListingCount=0)) {
				Set tSkip = 1
			}
			ElseIf ((tValue="showGeoListing")&&(tGeoListingCount=0)) {
				Set tSkip = 1
			}
			ElseIf ((tValue="showIKnowMsrValue")&&(tIKnowMeasureCount=0)) {
				Set tSkip = 1
			}
			If ('tSkip) {
				Set tActionType = $LG(tActions(a),4)
				Do ..actionTypes.Insert(tActionType)
				Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ tValue
				Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tActions(a),2)
			}
			Set a = $O(tActions(a))
		}

		Set tActionCtrl = ..%GetComponentById("controlAction")
		Set tActionCtrl.displayList = tDisplayList
		Set tActionCtrl.valueList = tValueList
		Set tActionCtrl.showEmpty = 0
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change of filter property.
ClientMethod changeProperty() [ Language = javascript ]
{
	// if this is the first set of the filter, then set the label as well (if blank)
	var ctrl = zen('controlProperty');
	if ('' == zen('controlLabel').getValue()) {
		var text = ctrl.getOptionText(ctrl.getSelectedIndex());
		zen('controlLabel').setValue(text);
	}
}

/// Launch the dashboard finder.
ClientMethod browseDashboards() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards','FindDashboard','status,scrollbars,resizable=yes,width=800,height=600');
}

ClientMethod browseTermLists() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists', 'browseTermLists');
}

ClientMethod browseDataSources() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=datasources', 'browseDataSources');
}

/// Launch the value editor.
ClientMethod showDefaultValueEditor() [ Language = javascript ]
{
	var parms = {
		DASHBOARD:this.dashboardName,
		DATASOURCE:this.dataSource,
		VALUE:zen('controlValue').getValue(),
		FILTER:zen('controlProperty').getValue()
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardEditDefaultValue.zen','EditValue','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'FindDashboard':
		zen('controlPropertyDB').setValue(value);
		break;
	case 'EditValue':
		if (value.defaultValue) {
			// DTB442 - Test to see if there is a displayValue/logicalValue object
			zen('controlValue').setValue(value.defaultText);
			this.defaultCtrlValue = value.defaultValue;
			this.defaultCtrlText = value.defaultText;
		}
		else {
			zen('controlValue').setValue(value);
		}
		break;
	case 'browseDataSources':
	case 'browseTermLists':
		this.updateForm(value);
		break;
	}
}

}
