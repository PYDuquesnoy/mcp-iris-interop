/// Zen Event log viewer page.
Class ZENTest.LogPage Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Event Log Page";

/// Domain used for localization.
/// Parameter DOMAIN = "ZENTEST";
XData Style
{
<style type="text/css">

table.tpTable {
	table-layout: auto;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Event Log Page">

<demo:demoTitle id="title" title="Zen Event Log Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Event Log" title="Event Log Page" />
</locatorBar>
<tablePane
	id="logTable"
	caption="Zen Event Log"
	queryClass="%ZEN.Utils"
	queryName="EnumerateLog"
	useSnapshot="true"
	pageSize="1000"

	fixedHeaders="true"
	bodyHeight="25.0em"
	filtersDisabled="false"

	showZebra="true"
	showRowNumbers="true"
	maxRows="10000"
	useKeys="true"
	showValueInTooltip="true"
>
<!--
<column colName="Type" width="80"/>
<column colName="Job" width="50"/>
<column colName="Time" width="120"/>
<column colName="Class" width="200"/>
<column colName="Message" width="350"/>
<column colName="Object" width="80"/>
-->
</tablePane>
<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<checkbox id="cbEnabled" caption="Logging Enabled" onchange="zenPage.enabledChange(zenThis);"/>
<spacer width="25"/>
<button caption="Refresh" onclick="zenPage.refreshLog();"/>
<spacer width="25"/>
<button caption="Reset" onclick="zenPage.resetLog();"/>
</hgroup>
</page>
}

/// Refresh the event log table.
ClientMethod refreshLog() [ Language = javascript ]
{
	var table = zenPage.getComponentById('logTable');
	table.executeQuery();
}

/// Reset the event log.
ClientMethod resetLog() [ Language = javascript ]
{
	this.EnableLog();
	this.refreshLog();
}

/// User has changed enabled checkbox.
ClientMethod enabledChange(cb) [ Language = javascript ]
{
	this.EnableLog(cb.getValue()==1 ? true : false);
	this.refreshLog();
}

/// Turn logging on or off.
ClassMethod EnableLog(flag As %Boolean = "") As %Boolean [ ZenMethod ]
{
	If (flag = "") {
		Set flag = ##class(%ZEN.Utils).%LoggingEnabled()
	}
	If (flag) {
		Do ##class(%ZEN.Utils).%StartLog()
	}
	Else {
		Do ##class(%ZEN.Utils).%StopLog()
	}
	Quit 1
}

/// This callback is called after the page model is created.
Method %OnAfterCreatePage() As %Status
{
	Set tCB = ..%GetComponentById("cbEnabled")
	Set tCB.value = $S(##class(%ZEN.Utils).%LoggingEnabled():1,1:0)
	Quit $$$OK
}

}

