/// Test page for Zen timer component.
Class ZENTest.TimerTest Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Timer Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// Counter to keep track of how many timer events have fired.
Property eventCounter As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Timer Test">
<demo:demoTitle id="title" title="Zen Timer Test Page"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Timer" title="Timer Test Page" />
</locatorBar>

<timer id="timer" 
	ontimeout="zenPage.timeout(zenThis);" 
	timeout="1000"/>
<html id="message">No events (An event should fire once per second).</html>
</page>
}

/// Timer has fired
ClientMethod timeout(timer) [ Language = javascript ]
{
	this.eventCounter++;

	var div = this.getComponentById('message');
	div.setProperty("content",'This is event: ' + this.eventCounter);

	// restart the timer
	timer.startTimer();
}

}

