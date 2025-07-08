/// dynaView Control Test
Class ZENTest.DynaViewTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Dynamic View Control Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
/* override of label control style */
.labelText {
	padding: 2px;
	background: white;
	border: 1px solid black;
	height: 1.0em;
	width: 12.0em;
}

#view {
	width: 400px;
	height: 300px;
	overflow: auto;
	border: 1px solid black;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Dynamic View Control Test">
<demo:demoTitle id="title" title="Zen dynaView Control Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="dynaView" title="dynaView Test Page" />
</locatorBar>

<spacer height="25"/>
<vgroup containerStyle="padding-left:20px;">
<dynaView id="view" 
	viewType="list" 
	OnGetViewContents="GetViewContents"
	rows="15" 
	onchange="zenPage.viewChange(zenThis);"
	ondblclick="alert('dbl: ' + zenThis.getProperty('value'));"
	>
	<parameter paramName="label" value="ABC" />
	<parameter paramName="dateFormat" value="3" />
	</dynaView>
<spacer height="25"/>
<form>
<label id="currValue" label="value:" value="..."/>
<spacer height="5"/>
<text id="selectedIndex" label="selectedIndex:" onchange="zenPage.selectViewItem(zenThis);" />
<spacer height="5"/>
<radioSet label="viewType:"
		valueList="list,details" 
		titleList="Put view into list mode,Put view into display mode" 
		value="list" onchange="zenPage.changeViewType(zenThis);"/>
<spacer height="5"/>
<text label="rows:" id="rows"
		title="Number of rows to use for list mode." 
		value="15" />
<spacer height="5"/>
<text label="Label: " id="labelVal"
		title="Label parameter value for the dynaView." 
		 hint="Set this and press Apply"
		value="ABC" />
<spacer height="5"/>
<text label="Date Format: " id="dateFormatVal"
		title="dateFormat parameter value for the dynaView." 
		 hint="Enter a number from 1 to 14"
		value="3" />
<spacer height="5"/>
<button caption="Apply" onclick="zenPage.refreshView();" />
</form>
</vgroup>

</page>
}

/// Refresh contents of the view
ClientMethod refreshView() [ Language = javascript ]
{
	var view = this.getComponentById('view');

	// change value of rows
	view.setProperty('rows',this.getComponentById('rows').getValue());

	// set label parameter
	view.setProperty('parameters','label',this.getComponentById('labelVal').getValue());

	// set date format parameter
	view.setProperty('parameters','dateFormat',this.getComponentById('dateFormatVal').getValue());
}

/// Change type of view
ClientMethod changeViewType(rs) [ Language = javascript ]
{
	var view = this.getComponentById('view');
	view.setProperty('viewType',rs.getValue());
}

/// new value of selected index
ClientMethod selectViewItem(ctrl) [ Language = javascript ]
{
	var view = this.getComponentById('view');
	view.setProperty('selectedIndex',ctrl.getValue());
}

/// view value has changed
ClientMethod viewChange(view) [ Language = javascript ]
{
	this.getComponentById('currValue').setValue(view.getProperty('value'));
	this.getComponentById('selectedIndex').setValue(view.getProperty('selectedIndex'));
}

/// This callback determines the contents of the dynaView component.
/// It is passed an array, <var>pParms</var> that contains a set 
/// of input parameters (values subscripted by name). These are
/// defined by the parameter property of the dynaView component.
/// On return, this method fills in two arrays:<br>
/// <var>pHeaders</var> is an array of column headers (for multi-column display) subscripted by column number.<br> 
/// <var>pContents</var> is an array of item descriptions 
/// subscripted by item number. Each item is a $List containing:<br>
/// textValue,logicalValue,icon, followed by any additional columns
/// to be displayed in "details" mode. 
Method GetViewContents(ByRef pParms As %String, Output pContents As %String, Output pHeaders As %String) As %Status
{
	#; Set detail headers
	Set pHeaders(1) = "Name"
	Set pHeaders(2) = "Size"
	Set pHeaders(3) = "Date"

	#; read parameters
	Set tLabel = $G(pParms("label"))
	Set tFormat = $G(pParms("dateFormat"),3)
	Set tFormat = $S(tFormat<1:3,tFormat>14:3,1:tFormat)

	#; text, value, icon,size,date
	For n=1:1:50 {
		Set icon = "images/folder.gif"
		Set pContents(n) = $LB(tLabel_" "_n,tLabel _ " " _n,icon,$R(1000),$ZDT($H-$R(1000),tFormat))
	}
	Quit $$$OK
}

}

