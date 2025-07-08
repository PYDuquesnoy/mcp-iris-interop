/// Zen Test: Menu bar test page
Class ZENTest.MenuTest Extends %ZEN.Component.page
{

/// Displayed name of this page.
Parameter PAGENAME = "Menu Test";

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// example of customized style sheet
XData Style
{
<style type="text/css">

.msg {
	margin: 10px;
	font-family: verdana;
}

.helpMsg {
	margin: 10px;
	padding: 10px;
	width: 200px;
	border: 1px solid gray;
	background: #FFEEAA;
	opacity: 0.75;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Menu Test Page">
<demo:demoTitle id="title" title="Menu Test Page" category="Zen Test Suite"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Menus" title="Menu Test Page" />
</locatorBar>

<hmenu id="topMenu">
<menuItem   caption="Home" 
					link="ZENDemo.Home.cls"
					help="Go to main demo page."
					/>
<menuItem   caption="Menu Demo" 
					link="ZENTest.HomePage.cls"
					help="Go to testing home page."
					/>
</hmenu>

<spacer height="25"/>
<html enclosingClass="msg">The following are examples of menus.</html>
<html><hr/></html>
<html enclosingClass="msg">Vertical menu:<br/></html>
<hgroup width="100%" cellAlign="left">
<spacer width="100" />
<menu id="menu2" layout="vertical">
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					/>
<menuSeparator />
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					/>
<menu id="menu2B" caption="Submenu" layout="vertical" onactivate="zenPage.activateMenu2B();">

<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					id="menu2B_A"
					/>
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					/>
<menu id="menu2BB" caption="Sub Submenu"  layout="vertical">

<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					/>
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					/>
<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					/>
</menu>

<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					/>
</menu>

<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					/>
<menu id="menu2C" caption="Submenu Two" layout="vertical">

<menuItem   caption="Menu C2" 
					link="javascript: alert('C2');"
					/>

</menu>
</menu>
</hgroup>

<html><hr/></html>
<html enclosingClass="msg">Horizontal menu:</html>
<hgroup width="100%" cellAlign="left">
<spacer width="100" />
<menu id="menu2ii" layout="horizontal"
	onshowHelp="zenPage.showHelp(help);"
	help="Top">
<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					help="Option A"
					image="images/folder.gif"
					/>
<menuSeparator />
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					help="Option B"
					image="images/folder.gif"
					/>
<menu id="menu2B2" caption="Submenu" layout="vertical">

<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					image="images/folder.gif"
					/>
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					/>
<menu id="menu2BB2" caption="Sub Submenu"  layout="vertical">

<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					/>
<menuItem   caption="Menu B" 
					link="javascript: alert('B');"
					/>
<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					help="Sub Option C"
					/>
<menu id="menu2BC" caption="Sub Sub Submenu" layout="vertical">

<menuItem   caption="Menu A" 
					link="javascript: alert('A');"
					/>
</menu>

</menu>

<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					/>
</menu>

<menuItem   caption="Form C" 
					link="javascript: alert('C');"
					help="Option C"
					/>
<menu id="menu2C3" caption="Submenu Two" layout="vertical">

<menuItem   caption="Menu C2" 
					link="javascript: alert('C2');"
					/>

</menu>
</menu>
</hgroup>

<html id="help"></html>
</page>
}

ClientMethod activateMenu2B() [ Language = javascript ]
{
	// submenu 2B is activated
	var item = zenPage.getComponentById('menu2B_A');
	if (item) {
		item.setDisabled(!item.getDisabled());
	}
}

ClientMethod showHelp(msg) [ Language = javascript ]
{
	var html = zenPage.getComponentById('help');
	if (html) {
		if ('' == msg) {
			html.setHidden(true);
		}
		else {
			html.setHidden(false);
			html.setProperty('content','<div class="helpMsg">' + msg + '</div>');
		}
	}
}

}

