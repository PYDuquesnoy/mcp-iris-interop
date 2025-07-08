/// ZENTest.FinderPaneTest
/// Test page for the Zen Finder Pane component.
Class ZENTest.FinderPaneTest Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "FinderPane Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* establish size of finder */
#finder {
	border: 1px solid black;
	width: 900px;
	height: 400px;
	overflow-x: auto;
	overflow-y: hidden;
	background: rgb(180,190,200);
}

/* fix width/height of each finder column */
.finderColumn {
	width: 300px;
	height: 400px;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" height="100%">
<demo:demoTitle id="title" title="Zen FinderPane Test" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="FinderPane Test" title="FinderPane Test" />
</locatorBar>
<!-- this provides the object content for the finder -->
<jsonProvider id="json" OnGetArray="GetFinderArray"/>

<html>
<div style="padding:5px;">
The Finder Panel displays a random organization chart (is that redundant?) based on data served as JSON content.
</div>
</html>
<spacer height="50"/>

<hgroup cellVAlign="top">
<spacer width="50"/>
<!-- the finder asked the jsonProvider for the data -->
<finderPane id="finder" ongetdata="return zen('json').getContentObject();" 
	onselectitem="return zenPage.itemSelected(item);"
	ondrawdetails="return zenPage.drawDetails(item);"
	ondrawempty="return zenPage.drawEmptyFinder();"
	/>
</hgroup>
</page>
}

/// Provide the source data (as an array) that will drive the finder.
Method GetFinderArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	// The MetaData list specifies the names of the properties of the 
	// JavaScript objects and the order in which they appear within
	// nodes of the data array.
	Set pMetaData = $LB("name","title","supervisor","phoneNo")

	// create a random org chart
	Set d = 0
	For tDept = "Sales","Marketing","Engineering","HR","Finance" {
		// add top-level entry for each department
		Set d = d + 1
		Set pData(d) = $LB(tDept) // name, but no other properties

		// add executive to each dept
		Set tVPName = ##class(%PopulateUtils).Name()
		Set pData(d,1) = $LB(tVPName,"Vice President, "_ tDept)

		// add 2nd level managers
		For n = 1:1:($R(10)+2) {
			Set tMgrName = ##class(%PopulateUtils).Name()
			Set pData(d,1,n) = $LB(tMgrName,"Manager",tVPName)

			// add workers
			For w = 1:1:($R(25)+2) {
				Set tWkrName = ##class(%PopulateUtils).Name()
				Set tTitle = ##class(%PopulateUtils).Title()
				Set pData(d,1,n,w) = $LB(tWkrName,tTitle,tMgrName)
			}

		}
	}
	Quit $$$OK	
	Quit $$$OK
}

/// Provide HTML for details on selected item in finder.
ClientMethod drawDetails(item) [ Language = javascript ]
{
	if (null == item) return '';
	var html = new Array();
	html[html.length] = '<div style="text-align:center; padding: 5px;">';
	if (item.name) {
		html[html.length] = '<b>' + item.name + '</b><br/>';
		html[html.length] = '<hr/>';
	}

	var icon = '/csp/broker/images/einstein.jpg';
	html[html.length] = '<img alt="" src="' + icon + '"/></b><br/><br/>';

	if (item.title) {
		html[html.length] = '<b>Title:</b>&nbsp;' + item.title + '<br/>';
		html[html.length] = '<hr/>';
	}
	if (item.phoneNo) {
		html[html.length] = '<b>Phone No:</b>&nbsp;' + item.phoneNo + '<br/>';
		html[html.length] = '<hr/>';
	}

	html[html.length] = '</div>';
	return html.join('');
}

/// Provide HTML for empty finder.
ClientMethod drawEmptyFinder(item) [ Language = javascript ]
{
	var html = new Array();
	html[html.length] = 'This finder pane is empty.' + '<br/>';

	return html.join('');
}

/// Item selected within the Finder.
ClientMethod itemSelected(item) [ Language = javascript ]
{
	return true;
}

}

