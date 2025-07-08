/// Zen Test: Layout Test Page
Class ZENTest.LayoutTest Extends %ZEN.Component.page
{

/// Displayed name of this page.
Parameter PAGENAME = "LayoutTest";

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

XData Style
{
<style type="text/css">
div.lyo {
	border: 1px solid black;
	background: orange;
}
body {
	white-space:nowrap;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page title="Zen Layout Demo" xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" layout="vertical" cellVAlign="top">
<demo:demoTitle id="title" title="Zen Layout Test Page" category="Zen Test Suite"/>

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Layout" title="Layout Test Page" />
</locatorBar>

<group layout="horizontal" width="100%" 
	cellSize="stretch"
	cellAlign="center">
<html slice="2"><div class="lyo">Ant</div></html>
<html slice="4"><div class="lyo">Bear</div></html>
<html slice="1"><div class="lyo">Cat</div></html>
</group>

<spacer height="100"/>
<vgroup width="100%" cellVAlign="top">
<hgroup>
<html><div class="lyo">-A1-</div></html>
<html><div class="lyo">-B1-</div></html>
<html><div class="lyo">-C1-</div></html>
</hgroup>
<hgroup width="80%" cellAlign="center">
<html><div class="lyo">-A2-</div></html>
<html><div class="lyo">-B2-</div></html>
<html><div class="lyo">-C2-</div></html>
</hgroup>
<hgroup width="100%" cellAlign="left">
<html width="90%"><div class="lyo">-A3-</div></html>
<html><div class="lyo">-B3-</div></html>
<html><div class="lyo">-C3-</div></html>
</hgroup>
<hgroup width="100%" cellAlign="right">
<html><div class="lyo">-A3-</div></html>
<html><div class="lyo">-B3-</div></html>
<html><div class="lyo">-C3-</div></html>
</hgroup>
<hgroup width="100%" cellAlign="even">
<html><div class="lyo">-A4-</div></html>
<html><div class="lyo">-B4-</div></html>
<html><div class="lyo">-C4-</div></html>
</hgroup>
<hgroup width="100%" cellSize="same">
<html><div class="lyo">-A5-</div></html>
<html><div class="lyo">-B5-</div></html>
<html><div class="lyo">-C5-</div></html>
<html><div class="lyo">-D5-</div></html>
<html><div class="lyo">-E5-</div></html>
<spacer/>
<html><div class="lyo">-FFFFFFFFFFFFFF-</div></html>
</hgroup>
<hgroup width="100%" cellSize="stretch">
<html><div class="lyo">-A6-</div></html>
<html><div class="lyo">-B6-</div></html>
<html><div class="lyo">-C6-</div></html>
</hgroup>
<hgroup width="100%" cellSize="stretch">
<html slice="1"><div class="lyo">-A7-</div></html>
<html slice="4"><div class="lyo">-B7-</div></html>
<spacer slice="22"/>
<html slice="16"><div class="lyo">-C7-</div></html>
</hgroup>
<hgroup width="100%" cellSize="stretch">
<html slice="2"><div class="lyo">-A8-</div></html>
<html slice="4"><div class="lyo">-B8-</div></html>
<spacer slice="1"/>
<html slice="8"><div class="lyo">-C8-</div></html>
</hgroup>
</vgroup>
<hgroup height="25%">
<vgroup>
<html><div class="lyo">-A1-</div></html>
<html><div class="lyo">-B1-</div></html>
<html><div class="lyo">-C1-</div></html>
<html><div class="lyo">-A1-</div></html>
<html><div class="lyo">-B1-</div></html>
<html><div class="lyo">-C1-</div></html>
<html><div class="lyo">-A1-</div></html>
<html><div class="lyo">-B1-</div></html>
<html><div class="lyo">-C1-</div></html>
</vgroup>
<vgroup height="100%" cellSize="stretch">
<html slice="1"><div class="lyo">-A2-</div></html>
<html slice="2"><div class="lyo">-B2-</div></html>
<html slice="6"><div class="lyo">-C2-</div></html>
</vgroup>
<vgroup cellVAlign="bottom">
<html><div class="lyo">-A3-</div></html>
<html><div class="lyo">-B3-</div></html>
<html><div class="lyo">-C3-</div></html>
</vgroup>
<vgroup height="100%" cellVAlign="even">
<html><div class="lyo">-A3-</div></html>
<html><div class="lyo">-B3-</div></html>
<html><div class="lyo">-C3-</div></html>
</vgroup>
</hgroup>

</page>
}

}

