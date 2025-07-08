/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog creates a new data property for a dashboard widget.
/// (Copied from old control data property dialog).
Class %DeepSee.UI.Dialog.DataPropertyWizard Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter JSINCLUDES = "dsparser.js";

/// Index of property within parent dialog list or "" for new.
Property itemNumber As %ZEN.Datatype.string(ZENURL = "NUMBER");

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Data source name.
Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

/// Name of widget.
Property widgetName As %ZEN.Datatype.string(ZENURL = "WIDGETNAME");

/// Type of widget, used to decide what controls to show.
Property widgetType As %ZEN.Datatype.string(ZENURL = "WIDGETTYPE");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="mainPane" hidden="false" xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<!-- provide context for selectors -->
<hidden id="dataSource" value="#(%page.dataSource)#"/>

<hgroup>
<hgroup label="Label" hint="Check box for auto label">
<text id="controlLabel"/>
<checkbox id="controlAutoLabel" onchange="zenPage.changeAutoLabel();" />
</hgroup>
<spacer width="10"/>
<checkbox id="controlHidden" label="Hidden" hint="If true do not display this item" onchange="zenPage.changeHidden();" />
</hgroup>

<hgroup>
<!-- n.b.: we should probably use the caption as the display value but the
selector does not support this -->
<selector id="controlDataValue" size="40" 
	label="Data Value" 
	hint="Value or name of property supplying the value for this item."
	onchange="zenPage.validateValue(zenThis);"
	context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>

<spacer width="10"/>
<checkbox id="controlValueColumn" label="Value Column" hint="If true, this column supplies the value for its row." />
</hgroup>

<select id="controlSubtype" label="Meter type"
	onchange="zenPage.changeDisplay();"
	valueList=",speedometer,fuelGauge,textMeter,trafficLight,lightBar,smiley"
	displayList="Default,Speedometer,Fuel Gauge,Text Meter,Traffic Light,Light Bar,Smiley"
	showEmpty="false"
	 hint="Type of meter to display"/>

<selector id="controlTargetValue" size="40" 
	label="Target Value" 
	hint="Target value or name of property supplying the target value for this item."
	onchange="zenPage.validateValue(zenThis);"
	context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>

<hgroup>
<select id="controlDisplay" label="Display"
	onchange="zenPage.changeDisplay();"
	valueList="itemNo,label,value,arrow,lamp,trendLine,plotBox,title,hidden"
	displayList="Item No,Label,Value,Arrow,Lamp,Trend Line,Plot Box,Title,Hidden"
	 hint="How to display the value"/>
<spacer width="10"/>
<select id="controlShowAs" label="Show As"
	valueList="value,conditional,sum,target,target%,sum%" 
	displayList="Value,Conditional,Sum,Target,% of Target,% of Sum" 
hint="What value to display"/>
<spacer width="10"/>
<select id="controlSummary" label="Summary"
	onchange="zenPage.changeSummary();"
	valueList="sum,avg,min,max,value" 
	displayList="Sum,Average,Min,Max,Value" 
hint="What to show in summary line"/>
<spacer width="5"/>
<selector id="controlSummaryValue" size="40" 
	label="Summary Value" 
	hint="Value or name of column supplying the summary value for this column."
	onchange="zenPage.validateValue(zenThis);"
	context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>

</hgroup>

<hgroup id="hgThresh" hint="Optional. Upper and lower threshold values for this item. This can be a property name.">
<selector id="controlThresholdLower" label="Lower Threshold" 
	onchange="zenPage.validateValue(zenThis);"
context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>
<spacer width="20"/>
<selector id="controlThresholdUpper" label="Upper Threshold" 
	onchange="zenPage.validateValue(zenThis);"
context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>
</hgroup>
<hgroup id="hgRange" hint="Optional. Values for the upper, lower, and base range values for this item. This can be a property name.">
<selector id="controlRangeLower" label="Lower Range" 
	onchange="zenPage.validateValue(zenThis);"
context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>
<spacer width="20"/>
<selector id="controlRangeUpper" label="Upper Range" 
	onchange="zenPage.validateValue(zenThis);"
context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>
<spacer width="20"/>
<selector id="controlBaseValue" label="Base Value" 
	onchange="zenPage.validateValue(zenThis);"
context="%DeepSee.Component.ContextSearch/DataProperties?dataSource=@dataSource"/>
</hgroup>

<hgroup>
<text id="controlFormat" label="Format" size="15" hint="Optional formatting to apply."/>
<spacer width="20"/>
<text id="controlStyle" label="Style" size="40" hint="Optional style to apply."/>
<spacer width="20"/>
<select id="controlAlign" label="Align" valueList="left,right,center" displayList="left,right,center" hint="Optional alignment."/>
<spacer width="20"/>
<text id="controlWidth" label="Width" size="10" hint="Optional width."/>
</hgroup>

<html id="error" enclosingStyle="font-size:12pt;font-family:arial;"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Data Property Wizard")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add a data property to this widget.")
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
		var main = this.getOpener ? this.getOpener() : window.opener;

		// apply changes to parent window
		var widgetDef = main.zenPage.getWidgetDefinition(main.zenPage.currWidgetKey);
		if (widgetDef) {
			var dp = {};

			dp.label = zen('controlLabel').getValue();
			dp.format = zen('controlFormat').getValue();
			dp.style = zen('controlStyle').getValue();
			dp.align = zen('controlAlign').getValue();
			dp.dataValue = zen('controlDataValue').getValue();
			dp.targetValue = zen('controlTargetValue').getValue();
			dp.display = zen('controlDisplay').getValue();
			dp.showAs = zen('controlShowAs').getValue();
			dp.summary = zen('controlSummary').getValue();
			dp.summaryValue = zen('controlSummaryValue').getValue();
			dp.valueColumn = zen('controlValueColumn').getValue();
			dp.rangeUpper = zen('controlRangeUpper').getValue();
			dp.rangeLower = zen('controlRangeLower').getValue();
			dp.baseValue = zen('controlBaseValue').getValue();
			dp.thresholdUpper = zen('controlThresholdUpper').getValue();
			dp.thresholdLower = zen('controlThresholdLower').getValue();
			dp.subtype = zen('controlSubtype').getValue();
			dp.width = zen('controlWidth').getValue();

			if (!widgetDef.dataProperties) {
				widgetDef.dataProperties = [];
			}
			widgetDef.dataProperties[widgetDef.dataProperties.length] = dp;
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
		var main = this.getOpener ? this.getOpener() : window.opener;
		var widgetDef = main.zenPage.getWidgetDefinition(main.zenPage.currWidgetKey);
		if (widgetDef) {
			this.changeSummary();
			this.changeDisplay();
		}

		// hide certain controls based on widget type
		switch(this.widgetType) {
		case 'meter':
			//zen('controlFormat').setHidden(true);
			//zen('controlStyle').setHidden(true);
			zen('controlDisplay').setHidden(true);
			zen('controlShowAs').setHidden(true);
			zen('controlSummary').setHidden(true);
			zen('controlSummaryValue').setHidden(true);
			zen('controlValueColumn').setHidden(true);
			zen('controlBaseValue').setHidden(true);
			zen('controlWidth').setHidden(true);
			zen('controlAlign').setHidden(true);
			break;
		case 'pivot':
			//zen('controlLabel').setHidden(true);
			//zen('controlFormat').setHidden(true);
			zen('controlAlign').setHidden(true);
			zen('controlStyle').setHidden(true);
			zen('controlTargetValue').setHidden(true);
			zen('controlDisplay').setHidden(true);
			zen('controlShowAs').setHidden(true);
			zen('controlSummary').setHidden(true);
			zen('controlSummaryValue').setHidden(true);
			//zen('controlValueColumn').setHidden(true);
			zen('hgRange').setHidden(true);
			zen('hgThresh').setHidden(true);
			zen('controlSubtype').setHidden(true);
			zen('controlWidth').setHidden(true);
			break;
		default:
			zen('controlSubtype').setHidden(true);
			break;
		}

		// show the contents
		zen('mainPane').setHidden(false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change to summary value control.
ClientMethod changeSummary() [ Language = javascript ]
{
	var value = zen('controlSummary').getValue();
	if ('value'==value) {
		zen('controlSummaryValue').setHidden(false);
	}
	else {
		zen('controlSummaryValue').setHidden(true);
	}
}

/// Change to "hidden" control.
ClientMethod changeHidden() [ Language = javascript ]
{
	var value = zen('controlHidden').getValue();
	if (value) {
		zen('controlDisplay').setValue('hidden');
	}
	else {
		zen('controlDisplay').setValue('value');
	}
}

/// Change to "autoLabel" control.
ClientMethod changeAutoLabel() [ Language = javascript ]
{
	var value = zen('controlAutoLabel').getValue();
	if (value) {
		zen('controlLabel').setValue('$auto');
		zen('controlLabel').setDisabled(true);
	}
	else {
		zen('controlLabel').setValue('');
		zen('controlLabel').setDisabled(false);
	}
}

/// Change to "display" control.
ClientMethod changeDisplay() [ Language = javascript ]
{
	var value = zen('controlDisplay').getValue();
	zen('controlHidden').setValue('hidden'==value);
}

/// Validate the value (expression) within the given control.
ClientMethod validateValue(ctrl) [ Language = javascript ]
{
	var value = ctrl.getValue();
	zen('error').setContent('');

	ctrl.setProperty('controlStyle','');

	if (''===value) {
	}
	else if (value.toString().charAt(0)=='=' && 'undefined'!= typeof dsFormulaParser) {
		var output = '';
		var parser = new dsFormulaParser();

		// dummy set of functions for validation purposes
		var funcSet = {
		max: function(args) {},
		min: function(args) {},
		count: function(args) {},
		sum: function(args) {},
		avg: function(args) {}
		}
		parser.setFunctionSet(funcSet);

		parser.parse(value.toString().substring(1));
		if (parser.errorHTML != '') {
			zen('error').setContent(ctrl.label + ' - ' + $$$Text('Error in formula: ') + parser.errorHTML);
			ctrl.setProperty('controlStyle','color: red;');
		}
	}
}

}
