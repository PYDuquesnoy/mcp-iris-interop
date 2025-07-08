/// Zen Test Suite Home Page.
/// This page shows a set of links to the various Zen test pages.
Class ZENTest.HomePage Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Home Page";

Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
.vmenuTable {
	border: 1px solid gray;
	font-family: arial;
	font-size: 0.9em;
	padding: 0px;
	color: black;
	background: white;
}

a.menuItem {
	color: black;
}

a.menuItem:hover {
	color: darkblue;
}

#menu {
}


#intro {
	font-weight: normal;
}

</style>
}

/// Contents of this page:
/// serialized set of Zen component objects
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Test Suite">
<demo:demoTitle id="title" title="Zen Test Suite Home Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" />
</locatorBar>

<html id="intro">
Welcome to the Zen Test Suite Home Page.<br/>
Use the links below to go to one of the Zen test pages.
</html>

<hgroup>
<spacer width="100"/>
 <vmenu id="menu">
</vmenu>
</hgroup>
</page>
}

/// This callback is called after the server-side page 
/// object and all of its children are created.
Method %OnAfterCreatePage() As %Status
{
	#; add items to main menu
	Set tMenu = ..%GetComponentById("menu")

	#; get pages in our application
	Do ##class(%ZEN.Utils).%GetPagesInApplication(..#APPLICATION, .tList)

	#; order pages by page name
	Set tPage = $O(tList(""))
	While (tPage '= "") {
		If (tPage '= ..%ClassName(1)) {
			Set tLabel = ..FindPageName(tPage)
			If (tLabel '= "") {
				Set tPageList(tLabel) = tPage
			}
		}

		#; next
		Set tPage = $O(tList(tPage))
	}

	#; now create a menu dynamically from the list

	Set tLabel = $O(tPageList(""),1,tPage)
	While (tLabel '= "") {
		#; menuitem
		Set tItem = ##class(%ZEN.Component.menuItem).%New()
		Set tItem.caption = tLabel
		Set tItem.link = tPage _ ".cls"
		Do tMenu.%AddChild(tItem)

		Set tLabel = $O(tPageList(tLabel),1,tPage)
	}

	Quit $$$OK
}

/// Get the page name for the given class (if possible).
Method FindPageName(pClass As %String) As %String
{
	Set $ZT="Trap"
	Set tPageName = $zobjclassmethod(pClass,"%GetPageName")
	Quit $S(tPageName="":pClass,1:tPageName)
Trap
	Set $ZT=""
	Quit pClass
}

}

