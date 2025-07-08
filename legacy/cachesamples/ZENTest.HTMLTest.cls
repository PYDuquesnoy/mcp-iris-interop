/// HTML Component Test
Class ZENTest.HTMLTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "HTML Component Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

Property object As %ZEN.Datatype.string [ InitialExpression = "HEY" ];

XData Style
{
<style type="text/css">
/* set style used for html element */
#html1 {
	border: 1px solid darkblue;
	background: white;
	padding: 5px;
	width: 500px;
}

#html2 {
	border: 1px solid darkblue;
	background: white;
	padding: 5px;
	width: 500px;
	height: 200px;
	overflow: auto;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="HTML Component Test Page">
<demo:demoTitle id="title" title="Zen HTML Component Test Page" category="Zen Test Suite"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="HTML" title="HTML Test Page" />
</locatorBar>

<hgroup>
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="How you can use the HTML component to inject any HTML content within a Zen page" />
<demo:bullet text="How the contents of an HTML component can be modified dynamically" />
</demo:sidebar>

<spacer width="25"/>
<vgroup>
<spacer height="25"/>
<html id="html1">The name of this page is: <b>#(%page.title)#</b>.<br/>
The current object is: #(%page.object)#<br/>
URL Parm ID is #(%url.ID)#
</html>
<spacer height="20"/>
<hgroup>
<button caption="Set client content" onclick="zenPage.setContent(zenThis,'html1');"/>
<spacer width="10"/>
<button caption="Refresh content" onclick="zenPage.refreshHTML(zenThis,'html1');"/>
</hgroup>
<spacer height="25"/>
<html id="html2" OnDrawContent="getHTML"/>
<spacer height="20"/>
<hgroup>
<button caption="Refresh content" onclick="zenPage.refreshHTML(zenThis,'html2');"/>
</hgroup>
</vgroup>
</hgroup>
</page>
}

/// Provide HTML for html2 component
Method getHTML(pSeed As %String) As %Status
{
	Set tColors = $LB("red","green","blue","black","orange")
	Set tCount = $R(10)+1
	For n = 1:1:tCount {
		Set tColor = $LG(tColors,$R($LL(tColors))+1)
		&html<<div style="color: #(tColor)#;">#(n)#: This #(tColor)# HTML is provided from a callback!</div>>
	}
	
	Quit $$$OK
}

/// Set content
ClientMethod setContent(btn, id) [ Language = javascript ]
{
	var html = this.getComponentById(id);
	var content = prompt("Enter new content",html.getProperty('content'));
	if (content || content=='') {
		html.setProperty('content',content);
	}
}

/// Refresh HTML from server.
ClientMethod refreshHTML(btn, id) [ Language = javascript ]
{
	var html = this.getComponentById(id);
	html.refreshContents();
}

}

