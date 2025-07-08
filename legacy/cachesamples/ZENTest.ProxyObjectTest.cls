/// Zen test page for proxy objects.
/// This page demonstrates the various ways in which Zen pages can invoke
/// methods using proxy objects.
Class ZENTest.ProxyObjectTest Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Proxy Object Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#menuTitleBox {
	color: black;
	background: #000040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

#menu {
}

#html {
	background: white;
	border: 1px solid black;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Proxy Object Test Page">
<demo:demoTitle id="title" title="Zen Proxy Object Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Proxy Test" title="Proxy Object Test Page" />
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="Using a light-weight proxy object to communicate between the client and server." />
<demo:bullet text="How a proxy object can be used with the HTML component." />
</demo:sidebar>
</vgroup>

<spacer width="50" />
<vgroup valign="top">
<spacer height="25" />
 <menu	id="menu" layout="vertical" cellVAlign="top">
<titleBox	title="Methods" 
	id="menuTitleBox"
			subtitle="Invoking Methods using proxy objects"
 />

<menuItem   caption="Server Instance Method Using a Proxy Object" 
					onclick="zenPage.testServerInstanceMethod();"
					help="Invoke server instance method."
					/>

<menuItem   caption="Server Instance Method that Modifies the Proxy Object" 
					onclick="zenPage.testServerInstanceMethodMod();"
					help="Invoke server instance method that modifies the proxy."
					/>

<menuItem   caption="Server Class Method that Modifies the Proxy Object" 
					onclick="zenPage.testServerClassMethodMod();"
					help="Invoke server class method that modifies the proxy."
					/>

<menuItem   caption="Server Class Method returning a Proxy Object" 
					onclick="zenPage.testServerClassMethodReturn();"
					help="Invoke server class method that returns a proxy."
					/>

<menuItem   caption="Update HTML component using a Proxy Object" 
					onclick="zenPage.testHTMLUpdate();"
					help="Refresh HTML component from server using a proxy."
					/>

</menu>
<spacer height="20"/>
<html id="html" OnDrawContent="DrawHTML"></html>
</vgroup>
</hgroup>
</page>
}

/// Draw contents of HTML box.
ClassMethod DrawHTML(pSeed As %String) As %Status
{
	If $IsObject(pSeed) {
		&html<<table>>
		&html<<tr><td>Name:</td><td>#(pSeed.Name)#</td></tr>>
		&html<<tr><td>SSN:</td><td>#(pSeed.SSN)#</td></tr>>
		&html<</table>>
	}
	Else {
		&html<<i>No data to display</i>>
	}
	Quit $$$OK
}

/// Test of server instance method.
ClientMethod testServerInstanceMethod() [ Language = javascript ]
{
	// create a proxy object
	var proxy = new zenProxy();
	proxy.Name = "Elvis";
	proxy.SSN = "111-22-3333";

	// pass this object to the server
	zenPage.serverInstanceMethod(proxy);
}

/// Server instance method
Method serverInstanceMethod(pProxy As %ZEN.proxyObject) [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server instance method received: #(pProxy.Name)#, #(pProxy.SSN)#');
	>
}

/// Test of server instance method that modifies the proxy object.
ClientMethod testServerInstanceMethodMod() [ Language = javascript ]
{
	// create a proxy object
	var proxy = new zenProxy();
	proxy.Name = "Elvis";
	proxy.SSN = "111-22-3333";

	// pass this object to the server
	zenPage.serverInstanceMethodMod(proxy);
	
	alert('Server returned:\nName:\t'+proxy.Name+'\nTime:\t'+proxy.ServerTime);
}

/// Server instance method that modifies the proxy.
/// This is a synchronous call.
Method serverInstanceMethodMod(pProxy As %ZEN.proxyObject) As %Boolean [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server instance method received: #(pProxy.Name)#, #(pProxy.SSN)#');
	>
	
	#; Modify proxy
	Set pProxy.Name = "Jack"
	Set pProxy.ServerTime = $ZH
	
	Quit 1
}

/// Test of server class method that modifies the proxy object.
ClientMethod testServerClassMethodMod() [ Language = javascript ]
{
	// create a proxy object
	var proxy = new zenProxy();
	proxy.Name = "Elvis";
	proxy.SSN = "111-22-3333";

	// pass this object to the server
	zenPage.serverClassMethodMod(proxy);
	
	alert('Server returned:\nName:\t'+proxy.Name+'\nTime:\t'+proxy.ServerTime);
}

/// Server class method that modifies the proxy.
/// This is a synchronous call.
ClassMethod serverClassMethodMod(pProxy As %ZEN.proxyObject) As %Boolean [ ZenMethod ]
{
	#; The server returns the following JavaScript statements to client
	#; for execution.
	&js<
	alert('Server class method received: #(pProxy.Name)#, #(pProxy.SSN)#');
	>
	
	#; Modify proxy
	Set pProxy.Name = "Jill"
	Set pProxy.ServerTime = $ZH
	
	Quit 1
}

/// Test of server class method that returns a proxy object.
ClientMethod testServerClassMethodReturn() [ Language = javascript ]
{
	var proxy = zenPage.serverClassMethodReturn();
	alert('Server returned:\nName:\t'+proxy.Name+'\nTime:\t'+proxy.ServerTime);
}

/// Server class method that modifies proxy.
/// This is a synchronous call.
ClassMethod serverClassMethodReturn() As %ZEN.proxyObject [ ZenMethod ]
{
	#; Create proxy
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Name = "Jim"
	Set tProxy.ServerTime = $ZH
	Quit tProxy
}

/// Test of server class method that updates the HTML component.
ClientMethod testHTMLUpdate() [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.Name = 'Marla';
	proxy.SSN = '333-22-1111';

	var html = zenPage.getComponentById('html');
	html.seed = proxy;
	html.refreshContents();
}

}

