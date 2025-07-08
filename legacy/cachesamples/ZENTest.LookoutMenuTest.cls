/// lookoutMenu Test
Class ZENTest.LookoutMenuTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Lookout Menu Test Page";

/// If provided, start with this tab open.
Property StartTab As %ZEN.Datatype.string(ZENURL = "TAB");

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
body {
	background: #F0F0FF;
	font-family: verdana;
}

#lookout {
	border: 1px solid darkblue;
	overflow: auto;
	height: 600px;
	width: 200px;
	background: darkgray;
}

.lookoutTab {
}

</style>
}

/// This XML defines the contents of this page.
XData Contents
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="lookout Menu Test Page">
<demo:demoTitle id="title" title="lookout Test Page" category="Zen Test Suite"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Lookout Menu" title="lookout Menu Test Page" />
</locatorBar>
<hgroup>
<lookoutMenu id="lookout" >
<tab caption="Animal" id="animal">
<menuItem   caption="Mineral" 
					link="javascript: zenPage.toggleTab('mineral');"
					image="images/folder.gif"
					/>
<menuItem   caption="Vegetables" 
					link="javascript: zenPage.toggleTab('vegetable');"
					image="images/folder.gif"
					/>
<menuItem   caption="Cheese" 
					link="javascript: zenPage.toggleTab('vegetable');"
					image="images/folder.gif"
					/>

</tab>
<tab caption="Mineral" id="mineral" tabResource="MyResource">
<form>
<text label="Name:" />
<text label="Weight:" />
</form>


</tab>
<tab caption="Vegetable" id="vegetable" disabled="true">
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					help="Option B"
					image="images/folder.gif"
					/>

<menuItem   caption="Disable" 
					link="javascript: zenPage.toggleTab('vegetable');"
					image="images/folder.gif"
					/>

</tab>
<tab caption="Cheese" id="cheese">
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>

</tab>
</lookoutMenu>
</hgroup>

</page>
}

Method %OnAfterCreatePage() As %Status
{
	#; try to go to specified tab
	Set tTab = ..%GetComponentById(..StartTab)
	If $IsObject(tTab) {
		Do tTab.%Activate()
	}

	Quit $$$OK
}

/// Toggle disabled state of given tab.
ClientMethod toggleTab(id) [ Language = javascript ]
{
	var tab = zenPage.getComponentById(id);
	tab.setProperty('disabled',!tab.getProperty('disabled'));
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// adjust size of lookout menu
	var menu = zenPage.getComponentById('lookout');
	zenASSERT(menu,'Unable to find menu',arguments);

	// find div for titleBox & locator
	var title = zenPage.getComponentById('title');
	var divTitle = title.getEnclosingDiv();

	var loc = zenPage.getComponentById('locator');
	var divLoc = loc.getEnclosingDiv();

	// find height of window
	var winHeight = zenGetWindowHeight();

	// adjust size of menu
	var sz = winHeight - (parseInt(divTitle.offsetHeight)) - (parseInt(divLoc.offsetHeight)) - 20;
	menu.setSize(null,sz);
}

}

