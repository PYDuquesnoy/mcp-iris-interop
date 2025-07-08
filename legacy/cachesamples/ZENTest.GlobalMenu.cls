/// Tree Menu defined by a global.
/// This page uses the dynaTree control to display menu based on a global.
Class ZENTest.GlobalMenu Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Global Tree Menu Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
body {
	background: #F0F0FF;
	font-family: verdana;
} 

#tree {
	border: 1px darkblue solid;
	background: white;
	height: 600px;
	width: 300px;
	overflow: auto;
	border-radius: 5px;
}

#label {
	border: 1px darkblue solid;
	background: white;
	padding: 2px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Global Menu Test Page">

<demo:demoTitle id="title" title="Global Menu Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Global Menu" title="Global Menu Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<dynaTree
	id="tree"
	dataGlobal="^ZENTest.menu"
/>
<spacer width="25"/>
<vgroup valign="top">
<button caption="Create Global" onclick="zenPage.CreateGlobal();"/>
<button caption="Kill Global" onclick="zenPage.KillGlobal();"/>
</vgroup>
</hgroup>
</page>
}

/// Create the global that defines this menu
Method CreateGlobal() [ ZenMethod ]
{
	Kill ^ZENTest.menu

	Set ^ZENTest.menu("Demo","Form") = "ZENDemo.FormDemo.cls"
	Set ^ZENTest.menu("Demo","Home") = "ZENDemo.Home.cls"

	Set ^ZENTest.menu("Test","Form") = "ZENTest.FormTest.cls"
	Set ^ZENTest.menu("Test","Home") = "ZENTest.HomePage.cls"
	Set ^ZENTest.menu("Test","Timer") = "ZENTest.TimerTest.cls"

	#; go to object edit page
	For n=1:1:25 {
		Set ^ZENTest.menu("Demo","Form",n) = "ZENDemo.FormDemo.cls?ID="_n
	}

	#; links to local JS method
	For n=1:1:10 {
		Set ^ZENTest.menu("Local",n) = "javascript:zenPage.localMethod("_n_");"
	}

	#; make sure tree gets updated
	&js<zenPage.getComponentById('tree').refreshContents();>
}

/// Create the global that defines this menu
Method KillGlobal() [ ZenMethod ]
{
	Kill ^ZENTest.menu

	#; make sure tree gets updated
	&js<zenPage.getComponentById('tree').refreshContents();>
}

/// localMethod
ClientMethod localMethod(n) [ Language = javascript ]
{
	alert('This is a local, client method: ' + n);
}

}

