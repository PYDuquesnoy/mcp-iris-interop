/// expando Control Test
Class ZENTest.ExpandoTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Expando Control Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="expando Control Test Page">

<demo:demoTitle id="title" title="Zen expando Control Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="expando" title="expando Test Page" />
</locatorBar>

<spacer height="25"/>
<expando caption="expando" childIndent="25px" remember="true">
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />

<expando caption="Subexpando" OnDrawContent="DrawContent" remember="true">
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />
<titleBox title="Zen expando Control Test Page" 
		subtitle="Use this page to test the Zen expando control." />
<text label="Edit"/>

</expando>
</expando>

</page>
}

/// OnDrawContent callback
Method DrawContent(ByRef expando As %ZEN.Component.expando) As %Status
{
	&html<&nbsp;<b>*</b>>
	// Set expando.expanded = 0
	Quit $$$OK
}

}

