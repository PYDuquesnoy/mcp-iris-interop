/// Repeating Group Test
Class ZENTest.RepeatingGroupTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Repeating Group Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// Rows to fetch from query.
Property Rows As %ZEN.Datatype.integer(ZENURL = "ROWS") [ InitialExpression = 10 ];

/// Search key value used by repeating group query.
Property SearchKey As %ZEN.Datatype.string(ZENURL = "KEY") [ InitialExpression = "A" ];

XData Style
{
<style type="text/css">
#repeatingGroup input.button {
	width: 300px;
	margin: 1px;
	text-align: left;
}

/* div around repeating group */
#repeatingGroup {
	border: 1px solid black;
	background: #E0D0E0;
}

/* items within the repeating group */
.repeatingGroup,.repeatingGroupSelected {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding: 10px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="RepeatingGroup Test Page">
<demo:demoTitle id="title" title="RepeatingGroup Test Page" category="Zen Test Suite"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Repeating Group" title="Repeating Group Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<vgroup id="vg">
<repeatingGroup id="repeatingGroup"
	maxRows="1000"
	sql="SELECT TOP ? Name,Title FROM ZENDemo_Data.Employee WHERE Name %STARTSWITH ?">
	<parameter value="#(%page.Rows)#" />
	<parameter value="#(%page.SearchKey)#" />
<hgroup id="hg">
<button caption='#(%query.Name)#' onclick="alert('#(%query.Name)#')"/>
<spacer width="25"/>
<button caption='#(%query.Title)#' onclick="alert('#(%query.Title)#')"/>
<spacer width="10"/>
<html>Item #(%this.tuple)#: <b>#(%query.Title)#</b></html>
</hgroup>
</repeatingGroup>
<spacer height="25"/>
<form>
<text id="search" label="Key:" value="#(%page.SearchKey)#" size="10"/>
<text id="rows" label="Rows:" value="#(%page.Rows)#" size="5"/>
<button caption="Search" onclick="zenPage.refreshGroup();" />
</form>
</vgroup>
</hgroup>
</page>
}

/// Refresh contents of the repeating group
/// using a new search key.
ClientMethod refreshGroup() [ Language = javascript ]
{
	var rg = this.getComponentById("repeatingGroup");
	var skey = this.getComponentById("search");
	var rows = this.getComponentById("rows");

	rg.parameters[0].value = parseInt(rows.getValue());
	rg.parameters[1].value = skey.getValue();
	rg.refreshContents();
}

}

