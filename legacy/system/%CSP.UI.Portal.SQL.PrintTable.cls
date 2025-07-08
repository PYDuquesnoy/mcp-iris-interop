/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This page allows to print a table to a printer.
Class %CSP.UI.Portal.SQL.PrintTable Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "PrintTable";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.PrintTable.zen";

Parameter RESOURCE = "%Development";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Print Table";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Switch namespace for this page: 
Parameter AUTONS As BOOLEAN = 1;

/// Namespace passed in from URL.
Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

/// Schema name passed in from URL.
Property Schema As %String(ZENURL = "$ID1");

/// Table name passed in from URL.
Property Table As %String(ZENURL = "$ID2");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
a.link {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px; 
	font-weight: bold;
	padding-left: 4px;
	text-decoration: none; 
}
a.link:visited {
	color: #00A09A;
}
a.link:hover {
	color: #00A09A;
}
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<vgroup cellStyle="padding-top:2px;" containerStyle="padding:10px;">
<hgroup cellStyle="padding-right:2px;">
<button caption="Print" onclick="zenPage.doPrint();"/>
<button caption="Close" onclick="zenPage.doClose();"/>
</hgroup>
<tablePane id="table" queryClass="%SQL.Manager.Catalog" queryName="Fields"
  caption="" initialExecute="false" maxRows="5000" showZebra="true"
>
<parameter value=""/>
<parameter value=""/>
</tablePane>

<link caption="Indices" href="javascript:zenPage.show('tableI');"/>
<tablePane id="tableI" queryClass="%SQL.Manager.Catalog" queryName="Indices"
  caption="" initialExecute="false" hidden="true" maxRows="5000" showZebra="true"
>
<parameter value=""/>
<parameter value=""/>
</tablePane>

<link caption="Triggers" href="javascript:zenPage.show('tableT');"/>
<tablePane id="tableT" queryClass="%SQL.Manager.Catalog" queryName="Triggers"
  caption="" initialExecute="false" hidden="true" maxRows="5000" showZebra="true"
>
<parameter value=""/>
<parameter value=""/>
</tablePane>

<link caption="Constraints" href="javascript:zenPage.show('tableC');"/>
<tablePane id="tableC" queryClass="%SQL.Manager.Catalog" queryName="Constraints"
  caption="" initialExecute="false" hidden="true" maxRows="5000" showZebra="true"
>
<parameter value=""/>
<parameter value=""/>
</tablePane>
</vgroup>
</page>
}

/// Prepare to start printing
ClientMethod doPrint() [ Language = javascript ]
{
	window.print();
}

ClientMethod doClose() [ Language = javascript ]
{
	this.cancelPopup();
}

/// Show or hide the other information
ClientMethod show(tableName) [ Language = javascript ]
{
	var table = zenPage.getComponentById(tableName);
	if (table.getProperty("hidden") == true) {
		table.parameters[0].value = this.Schema;
		table.parameters[1].value = this.Table;
		table.executeQuery();
		table.setProperty("hidden",false);
	} else {
		table.setProperty("hidden",true);
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set Schema = $G(%request.Data("$ID1",1))
	Set Table = $G(%request.Data("$ID2",1))
	Set ..%GetComponentById("table").caption = $zconvert($G(%request.Data("$NAMESPACE",1))_": "_Schema_"."_Table,"O","HTML")
	Set EventDesc = "Print Catalog"
	Set EventData = Schema_"."_Table
	$$$SMPAuditView
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var table = zenPage.getComponentById("table");
	table.parameters[0].value = this.Schema;
	table.parameters[1].value = this.Table;
	table.executeQuery();
}

}
