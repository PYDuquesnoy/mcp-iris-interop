/// This is the ActiveGroup Demonstration page for the Zen demonstration application.
Class ZENDemo.ActiveGroupDemo Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Active Group Demo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#groupTopRight {
	padding: 10px;
	background: #C0FFC0;
	height: 100%;
	overflow: hidden;
}

#groupBottomRight {
	padding: 10px;
	background: #C0C0FF;
	height: 100%;
	overflow: hidden;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" 
	title="Zen Active Group Demo" >
<demo:demoTitle id="title" title="Active Group Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Active Group Demo" title="Active Group Demo" />
</locatorBar>

<activeHGroup split="5" autoExpand="250" handleThickness="1">
<vgroup valign="top">
<demo:sidebar text="This panel demonstrates the autoExpand feature.">
<demo:bullet image="images/einstein.jpg" text="Einstein"/>
<demo:bullet text="Remember to keep your Zen code as simple as possible, but no simpler."/>
</demo:sidebar>
</vgroup>
<activeHGroup split="25%" handleThickness="5">
<vgroup valign="top">
<demo:sidebar text="This panel demonstrates Zen's Active Group feature.">
<demo:bullet text="An active group splits a region of the page into two sections which can be resized using the mouse (without the use of frames)."/>
<demo:bullet text="Active groups can be nested to create more complex pages."/>
<demo:bullet text="Move the mouse to the left hand side of the page to see the autoExpand feature."/>
</demo:sidebar>
</vgroup>
<activeVGroup split="25%" handleThickness="5" >
<vgroup id="groupTopRight">
<label value="This is the top right Active Group." />
</vgroup>
<vgroup id="groupBottomRight">
<label value="This is the bottom right Active Group." />
</vgroup>
</activeVGroup>
</activeHGroup>
</activeHGroup>
</page>
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onlayoutHandler(first) [ Language = javascript ]
{
	ZLM.notifyResize(document.body);
}

}

