/// Test page for tabbed groups.
Class ZENTest.TabTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Tab Control Test";

Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">

/* body of tab group */
.tabGroupBody {
	background: #C0D0FF;
}

/* selected tab */
td.tabGroupButtonOn {
	background: #C0D0FF;
}

/* div for tab group */
#tabGroup {
	height: 400px;
	width: 650px;
}

#grid {
	width: 400px;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Tab Control Test">
<demo:demoTitle id="title" title="Zen Tab Component Test Page" category="Zen Test Suite"/>

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Tab Control" title="Tabbed Dialog Test Page" />
</locatorBar>

<spacer height="50" />
<hgroup  width="75%" cellAlign="center">
<tabGroup id="tabGroup" showTabBar="true" onshowTab="zenPage.updateButtons();" remember="true">
<tab caption="First Page">
<spacer height="5"/>
<html>This is the first tab!</html>
<form width="75%" layout="vertical" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;" groupStyle="border:1px solid darkblue;">
<titleBox title="My Form" titleStyle="background: #DDDDFF;" containerStyle="padding: 0px;" />
<spacer height="5"/>

<colorPicker title="This is a custom control!" label="Color (custom control):" name="Color" />
<text label="Color Name:" name="ColorName" size="12" />
<hgroup id="tgroup" cellVAlign="top">
<text label="DOB:" id="DOB" name="DOB" size="15" maxlength="10" valign="bottom"/>
</hgroup>
</form>
</tab>
<tab caption="Second Page">
<spacer height="5"/>
<html>This is the second tab!</html>
<dataCombo label="Patient:" name="Patient" size="24"
	sql="SELECT Name FROM ZENDemo_Data.Employee WHERE Name %STARTSWITH ? ORDER BY Name"/>
</tab>
<tab caption="Third Page" tabResource="MyResource">
<spacer height="5"/>
<html>This is the third tab!</html>
<dynaGrid id="grid" rowLabelWidth="25">
<gridColumn label="Name"   width="25%" />
<gridColumn label="Salary" width="25%"  />
<gridColumn label="Comment" width="50%" />
<gridRow label="R1" />
<gridRow label="R2" />
<gridRow label="R3" />
</dynaGrid>
</tab>
</tabGroup>
</hgroup>
<spacer height="50" />
<hgroup width="40%" cellAlign="right">
<button id="prev" caption=" Prev " onclick="zenPage.prevTab();" />
<spacer width="5" />
<button id="next" caption=" Next " onclick="zenPage.nextTab();" />
<spacer width="5" />
</hgroup>

</page>
}

ClientMethod prevTab() [ Language = javascript ]
{
	var tab = this.getComponentById('tabGroup');
	tab.showPreviousTab();
	this.updateButtons();
}

ClientMethod nextTab() [ Language = javascript ]
{
	var tab = this.getComponentById('tabGroup');
	tab.showNextTab();
	this.updateButtons();
}

ClientMethod updateButtons() [ Language = javascript ]
{
	var tab = this.getComponentById('tabGroup');
	var prev = this.getComponentById('prev');
	var next = this.getComponentById('next');

	if (1 == tab.getCurrTabNo()) {
		prev.setDisabled(true);
	}
	else {
		prev.setDisabled(false);
	}

	if (tab.getTabCount() == tab.getCurrTabNo()) {
		next.setDisabled(true);
	}
	else {
		next.setDisabled(false);
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.updateButtons();
}

}

