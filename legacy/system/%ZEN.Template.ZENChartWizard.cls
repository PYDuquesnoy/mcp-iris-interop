/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Inserts a new chart definition within an XData definition.
Class %ZEN.Template.ZENChartWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Chart Wizard";

Parameter TEMPLATETITLE = "Zen Chart Wizard";

Parameter TEMPLATEDESCRIPTION = "Inserts a Zen chart definition within a Contents document.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Parameter HELPID = "GZEN_chart_wizard";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#objectInspector {
	height: 400px;
	width: 310px;
	border: 1px solid darkblue;
	overflow-y: scroll;
	overflow-x: auto;
}
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" xmlns="http://www.intersystems.com/zen">
<tabGroup id="tabGroup" onshowTab="zenPage.tabChange(zenThis);">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<hidden id="results" name="results" />
<radioSet label="Chart Type:" id="chartType" name="chartType"
	onchange="zenPage.chartTypeChange(zenThis);"
	 />
</vgroup>

</tab>
<tab>
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<hgroup cellVAlign="top">
<svgFrame id="svgFrame" layout="horizontal"
	height="500" width="800">
</svgFrame>
<spacer width="5"/>
<vgroup valign="top">
<titleBox title="Chart Attributes" />
<html enclosingClass="msg">Set attribute values of the chart.</html>
<radioSet id="element" 
	valueList="chart,xAxis,yAxis"
	displayList="Chart,X axis,Y axis"
	value="chart"
	onchange="zenPage.inspectElement(zenThis.getValue());"
	/>
<objectInspector id="objectInspector"
	showAll="false" 
	idEditable="true"
	onedit="zenPage.editProperty();"/>
</vgroup>
</hgroup>

</tab>
</tabGroup>

</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard inserts a new Zen chart definition within an Xdata block of a Zen page class."),"<br/>"
	Write $$$TextHTML("Select which type of chart you wish to create and then press Next.")
	Quit $$$OK
}

/// Provide contents of description component.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$TextHTML("Adjust the settings of the chart. Press Finish when complete.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; find list of chart types
	Set tRS = ##class(%ResultSet).%New("%ZEN.Utils:EnumerateComponents")
	Set tSC = tRS.%Execute("%ZEN.SVGComponent.chart")

	Set tList = ""
	While (tRS.%Next()) {
		Set tName = $G(tRS.Data("Name"))
		Set tClassName = $G(tRS.Data("ClassName"))
		If (tClassName'["%DeepSee") {
			Set tList = tList _ $S(tList="":"",1:",") _ tName
		}
	}
	
	Set tRadio = ..%GetComponentById("chartType")
	Set tRadio.valueList = tList
	Quit $$$OK
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSize();

	// adjust size of svgFrame
	var frame = zenPage.getComponentById('svgFrame');
	var winWidth = zenGetWindowWidth();

	var sz = winWidth - 350;
	frame.setProperty('width',sz);
}

/// Notification that the chart type has changed.
ClientMethod chartTypeChange(cb) [ Language = javascript ]
{
	this.updateState();
	this.changeChart(cb.getValue());
}

/// Create and display the specified chart type.
ClientMethod changeChart(chartType) [ Language = javascript ]
{
	// create a new chart
	var chart = null;
	if ('' != chartType) {
		var frame = zenPage.getComponentById('svgFrame');
		chart = zenPage.createComponent(chartType);
		frame.addChild(chart);
		frame.setEditMode('drag');
		
		var xAxis = zenPage.createComponent('axis');
		chart.setXAxis(xAxis);
		var yAxis = zenPage.createComponent('axis');
		chart.setYAxis(yAxis);
		
		// default properties
		chart.setProperty('width',400);
		chart.setProperty('height',400);
		chart.setProperty('title','Zen Chart');
		chart.setProperty('seriesCount',1);
		chart.setProperty('seriesSize',10);
		chart.setProperty('ongetData',"return zenPage.getChartData(series);");

		// if there is an old chart, copy its properties
		// removed to correct issue with performance & comboChart redraw

		// make sure plotToEdge is correct!
		chart.setProperty('plotToEdge','barChart' != chartType);
	}

	// get rid of the old chart
	if (null != this._currChart) {
		zenPage.deleteComponent(this._currChart);
		delete this._currChart;
	}
	this._currChart = chart;
}

/// Notification that a new tab was selected.
ClientMethod tabChange(tabGroup) [ Language = javascript ]
{
	var tabNo = tabGroup.getCurrTabNo();

	switch(tabNo) {
	case 2:
		// update chart page
		var el = zenPage.getComponentById('element');
		el.setValue('chart');
		this.inspectElement('chart');
		break;
	}

	// adjust layout
	this.adjustSize();
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	
	switch(tabNo) {
	case 1:
		// if user selects an element, we can go to the next tab
		var element = zenPage.getComponentById('chartType');
		return ('' != element.getValue());
	}

	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');

	return (tabGroup.getCurrTabNo() > 1);
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showNextTab();
	this._currChart.render();
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// Callback to provide random data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	var size = 10; // !!!
	size = isNaN(size) ? 0 : size;
	var data = new Array(size);
	var value = 50;
	
	for (var i = 0; i < size; i++) {
		if (Math.random() > 0.9) {
			value += (Math.random() * 50) - 35;
		}
		else {
			value += (Math.random() * 20) - 9;
		}		
		
		//FKH013: store generated values in sessionStorage if available
		if (window.sessionStorage){			
			if (sessionStorage.getItem("chartdata"+i)){
				data[i]=sessionStorage.getItem("chartdata"+i);							
			} else {
				data[i]=value;
				sessionStorage.setItem(["chartdata"+i],value);
			}
		} else {
			data[i]=value;
		}
		
	
	}
	return data;
}

/// Point object inspector to given component.
ClientMethod inspectElement(name) [ Language = javascript ]
{
	
	var obj = this._currChart; // !!!

	if (obj) {
		switch (name) {
		case 'xAxis':
			obj = obj.getXAxis();
			break;
		case 'yAxis':
			obj = obj.getYAxis();
			break;
		default:
			break;
		}
	}
	
	var inspector = zenPage.getComponentById('objectInspector');
	inspector.setCurrObject(obj);
}

/// User has pressed edit button in the objectInspector.
ClientMethod editProperty() [ Language = javascript ]
{
	var inspector = this.getComponentById('objectInspector');

	// request to edit a property
	var obj = inspector.getCurrObject();
	var mbr = inspector.getCurrMember();
	
	zenASSERT(obj,'No object to edit',arguments);
	zenASSERT(mbr,'No object property to edit',arguments);
	
	if ('id' == mbr) {
		alert('Editing of id value is not allowed on this page.');
		return;
	}

	// launch the built-in component value editor dialog
	var value = obj.getProperty(mbr);
	var mbrType = inspector.getCurrMemberType();
	if (mbrType == 'boolean') {
		value = (value) ? '1' : '0';
	}

	var parms = new Object();
	parms.property = mbr;
	parms.className = obj._serverClass;
	parms.value = value;
	parms.type = mbrType;

	zenPage.launchPopupWindow(zenLink('%ZEN.Dialog.componentValueEditor.cls'),'ValueEditor','resizable,width=500,height=500',parms,this);
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	var inspector = this.getComponentById('objectInspector');
	switch (action) {
	case 'ok':
	case 'apply':
		var obj = inspector.getCurrObject();
		var mbr = inspector.getCurrMember();
		var mbrType = inspector.getCurrMemberType();
		if (mbrType == 'boolean') {
			value = ('1' == value) ? true : false;
		}

		var handled = obj.setProperty(mbr,value);
		if (!handled && obj.refreshContents) {
			// if object did not handle set, go to server!
			obj.refreshContents();
		}
		if ('ok' == action) {
			inspector.setCurrMember('');
		}
		break;
	}
	var obj = this._currChart;
	inspector.setCurrObject(obj);
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
}

/// This is called when the template is finished;
ClientMethod onfinishHandler() [ Language = javascript ]
{
	// get XML version of chart, store in hidden field
	var ctrl = zenPage.getComponentById('results');
	ctrl.setValue(this.SerializeChart(this._currChart));
	return true;
}

/// Convert chart to xml representation.
ClassMethod SerializeChart(pChart As %ZEN.SVGComponent.chart) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tState = ""
	Set $ZT="Trap"
	Do {
		#; serialize to xml
		Set tStream = ##class(%Stream.TmpCharacter).%New()

		Set tSC = ##class(%ZEN.Utils).%ObjectToXML(tStream,pChart,.tNS)
		If $$$ISERR(tSC) Quit
		
		Set tState = tStream.Read(30000)
	} While(0)
Done
	Quit tState
Trap
	Set $ZT=""
	Set tState = ""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Write ..%GetValueByName("results")
	Quit $$$OK
}

}
