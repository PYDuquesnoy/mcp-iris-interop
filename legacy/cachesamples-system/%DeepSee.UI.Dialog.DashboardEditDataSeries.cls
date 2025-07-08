/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog adds (or edits) a new chart data series definition for a DeepSee dashboard widget.
Class %DeepSee.UI.Dialog.DashboardEditDataSeries Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Index of series within parent dialog list or "" for new.
Property seriesNumber As %ZEN.Datatype.string(ZENURL = "NUMBER");

/// Type of chart being displayed.
Property chartType As %ZEN.Datatype.string(ZENURL = "CHARTTYPE");

/// Dashboard name.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<deepsee:styleEdit features="background" label="Color" id="seriesColor"/>
<!-- used for parsing css -->
<html id="test" />

<radioSet id="seriesType" hidden="false" label="Type" 
	hint="How to display data for this series" 
	title="Default: use default plot type; Bar: plot data as a bar chart; Line: plot data as a line chart; Area: plot data as a background area;"
	valueList=",bar,line,area" displayList="Default,Bar,Line,Area"/>

<radioSet id="seriesMarker" hidden="false" label="Marker" 
	hint="Marker to display for this series (if any)." 
	valueList=",up,down,circle,square" displayList="None,Up Arrow,Down Arrow,Circle,Square"/>

<radioSet id="seriesYAxis" hidden="false" label="y-Axis" 
	hint="Y-axis to use for this data" 
	title="Y-axis to use for this data"
	valueList="0,1,2,3,4,5" displayList="1,2,3,4,5,6"/>

<checkbox id="seriesHasLegend" hidden="true" label="Has Legend" 
	hint="Include this series in the chart legend" 
	title="Include this series in the chart legend"
	/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Add a Chart Data Series to a Dashboard Widget")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add a data series to this widget.")
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

		// apply changes to parent window
		var def = null;
		
		if (''==this.seriesNumber) {
			def = main.zenPage.createComponentNS('http://www.intersystems.com/deepsee','dataSeriesDefinition');
			main.zenPage.dataSeriesDefs[main.zenPage.dataSeriesDefs.length] = def;
		}
		else {
			def = main.zenPage.dataSeriesDefs[parseInt(this.seriesNumber)-1];
		}
		if (def) {
			def.type = zen('seriesType').getValue();
			var div = zen('test').getEnclosingDiv();
			div.style.cssText = zen('seriesColor').getValue();
			def.color = div.style.backgroundColor;
			def.markerShape = zen('seriesMarker').getValue();
			def.yAxisIndex = zen('seriesYAxis').getValue();
			def.hasLegend = zen('seriesHasLegend').getValue() ? true : false;
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

		this._originalTargetProperty = '';

		// get additional values from parent window
		var def = null;
		if (''!=this.seriesNumber) {
			def = main.zenPage.dataSeriesDefs[parseInt(this.seriesNumber)-1];
		}
		if (def) {
			zen('seriesType').setValue(def.type);
			zen('seriesColor').setValue(def.color!=='' ? 'background:'+def.color+';' : '');
			zen('seriesMarker').setValue(def.markerShape);
			zen('seriesYAxis').setValue(''===def.yAxisIndex?0:def.yAxisIndex);
			zen('seriesHasLegend').setValue(''===def.hasLegend||def.hasLegend?1:0);
		}
		else {
			zen('seriesType').setValue('');
			zen('seriesColor').setValue('');
			zen('seriesMarker').setValue('');
			zen('seriesYAxis').setValue(0);
			zen('seriesHasLegend').setValue(1);
		}
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

}
