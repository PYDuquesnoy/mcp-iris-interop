/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog adds (or edits) a new data property definition to a DeepSee dashboard widget.
Class %DeepSee.UI.Dialog.DashboardEditDataProperty Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
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
	Quit $$$TextHTML("Add Data Property to Dashboard Widget")
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
		var def = null;
		if (''==this.itemNumber) {
			def = main.zenPage.createComponentNS('http://www.intersystems.com/deepsee','dataPropertyDefinition');
			main.zenPage.dataPropertyDefs[main.zenPage.dataPropertyDefs.length] = def;
		}
		else {
			def = main.zenPage.dataPropertyDefs[parseInt(this.itemNumber)-1];
		}
		if (def) {
			//def.name = zen('controlName').getValue();
			def.label = zen('controlLabel').getValue();
			def.format = zen('controlFormat').getValue();
			def.style = zen('controlStyle').getValue();
			def.align = zen('controlAlign').getValue();
			def.dataValue = zen('controlDataValue').getValue();
			def.targetValue = zen('controlTargetValue').getValue();
			def.display = zen('controlDisplay').getValue();
			def.showAs = zen('controlShowAs').getValue();
			def.summary = zen('controlSummary').getValue();
			def.summaryValue = zen('controlSummaryValue').getValue();
			def.valueColumn = zen('controlValueColumn').getValue();
			def.rangeUpper = zen('controlRangeUpper').getValue();
			def.rangeLower = zen('controlRangeLower').getValue();
			def.baseValue = zen('controlBaseValue').getValue();
			def.thresholdUpper = zen('controlThresholdUpper').getValue();
			def.thresholdLower = zen('controlThresholdLower').getValue();
			def.subtype = zen('controlSubtype').getValue();
			def.width = zen('controlWidth').getValue();
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

		// get additional values from parent window
		var def = null;
		if (''!=this.itemNumber) {
			def = main.zenPage.dataPropertyDefs[parseInt(this.itemNumber)-1];
		}
		if (def) {
			//zen('controlName').setValue(def.name);
			zen('controlLabel').setValue(def.label);
			zen('controlFormat').setValue(def.format);
			zen('controlStyle').setValue(def.style);
			zen('controlAlign').setValue(def.align);
			zen('controlDataValue').setValue(def.dataValue);
			zen('controlTargetValue').setValue(def.targetValue);
			zen('controlDisplay').setValue(def.display);
			zen('controlShowAs').setValue(def.showAs);
			zen('controlSummary').setValue(def.summary);
			zen('controlSummaryValue').setValue(def.summaryValue);
			zen('controlValueColumn').setValue(def.valueColumn);
			zen('controlRangeUpper').setValue(def.rangeUpper);
			zen('controlRangeLower').setValue(def.rangeLower);
			zen('controlThresholdUpper').setValue(def.thresholdUpper);
			zen('controlThresholdLower').setValue(def.thresholdLower);
			zen('controlBaseValue').setValue(def.baseValue);
			zen('controlSubtype').setValue(def.subtype);
			zen('controlWidth').setValue(def.width);

			// JMD997
			if (def.label=='$auto') {
				zen('controlAutoLabel').setValue(true);
				zen('controlLabel').setDisabled(true);
			}
			else {
				zen('controlAutoLabel').setValue(false);
			}

			if (def.display=='') {
				zen('controlDisplay').setValue('value');
			}
			if (def.showAs=='') {
				zen('controlShowAs').setValue('value');
			}
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
