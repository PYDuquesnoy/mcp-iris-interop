/// Test of creating components dynamically.
Class ZENTest.DynamicComponentsTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Dynamic Component Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
.button {
	width: 180px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents
{
<page xmlns="http://www.intersystems.com/zen" xmlns:test="http://www.intersystems.com/zentest" xmlns:demo="http://www.intersystems.com/zendemo" 
	title="Dynamic Components Test">
<demo:demoTitle id="title" title="Zen Dynamic Components Test Page" category="Zen Test Suite"/>

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Dynamic Components" title="Dynamic components test page" />
</locatorBar>


<spacer height="25"/>

<hgroup>
<spacer width="25"/>
<html enclosingClass="msg">
Use the combo boxes below to select a component to create dynamically. This logic can be run on the client or on the server.<br/>
</html>
</hgroup>

<hgroup>
<spacer width="25"/>
<combobox id="cbClient" label="Component (client-side):"
		title="Select a component to create on the client."
		onchange="zenPage.showComponentClient(zenThis.getValue());"
		editable="false">
<option text="button" value="button" />
<option text="calendar" value="calendar" />
<option text="text" value="text" />
<option text="demoMenu" value="http://www.intersystems.com/zendemo^demoMenu" />
<option text="customComponent" value="http://www.intersystems.com/zentest^customComponent" />
</combobox>
<spacer width="25"/>

<combobox id="cbServer" label="Component (server-side):"
		title="Select a component to create on the server."
		onchange="zenPage.showComponentServer(zenThis.getValue());"
		editable="false">
<option text="button" value="button" />
<option text="calendar" value="calendar" />
<option text="text" value="text" />
<option text="tablePane" value="tablePane" />
<option text="demoMenu" value="http://www.intersystems.com/zendemo^demoMenu" />
</combobox>
<spacer width="25"/>
<fieldSet legend="Table Columns" 
	id="tableOptions" layout="horizontal" >

<checkbox id="tcName" caption="Name" onchange="zenPage.tcChange(zenThis,'Name');" />
<checkbox id="tcTitle" caption="Title" onchange="zenPage.tcChange(zenThis,'Title');"/>
<checkbox id="tcSSN" caption="SSN" onchange="zenPage.tcChange(zenThis,'SSN');"/>
</fieldSet>
</hgroup>

<spacer height="5"/>
<hgroup>
<spacer width="25"/>

<!-- Use import property to make sure that code for demoMenu && customComponent is
part of the client model -->
<fieldSet legend="dynamic component" id="holder" 
	import="ZENDemo.Component.demoMenu,ZENTest.customComponent" />
</hgroup>
<!--
<button caption="objects" onclick="zenPage.showObjects();" />
<html id="objList"/>
-->
</page>
}

/// Display the component specified by the component combobox.
ClientMethod showComponentClient(type) [ Language = javascript ]
{
	// use client-side methods to create new components
	var holder = zenPage.getComponentById('holder');

	// if present, remove old component
	var comp = zenPage.getComponentById('dynamicComponent');
	if (comp) {
		zenPage.deleteComponent(comp);
	}

	// create new component within "holder"
	// if custom component, type is NS^type
	var ns = '';
	var t = type.split('^');
	if (t.length > 1) {
		ns = t[0];
		type = t[1]
	}
	
	var comp = zenPage.createComponentNS(ns,type);

	if (comp) {
		switch (type) {
		case 'button':
			comp.setProperty('caption','Button');
			break;
		case 'text':
			comp.setProperty('label','Name:');
			break;
		case 'calendar':
			break;
		}
		
		comp.setProperty('id','dynamicComponent');
		holder.addChild(comp);
		holder.refreshContents();
	}
}

/// Display the component specified by the component combobox.
Method showComponentServer(pType As %String) [ ZenMethod ]
{
	#; use server-side methods to create new components
	Set tHolder = %page.%GetComponentById("holder")

	#; if present, remove old component
	Set tComp = %page.%GetComponentById("dynamicComponent")
	If $IsObject(tComp) {
		#; remove component from its group
		Do tHolder.%RemoveChild(tComp)
	}

	#; create new component
	#; translate component name to actual class name
	Set tComp = ""
	If (pType = "button") {
		Set tComp = ##class(%ZEN.Component.button).%New()
		Set tComp.caption = "Button"
	}
	ElseIf (pType = "text") {
		Set tComp = ##class(%ZEN.Component.text).%New()
		Set tComp.label = "Name:"
	}
	ElseIf (pType = "calendar") {
		Set tComp = ##class(%ZEN.Component.calendar).%New()
		Set tComp.label = "Date:"
	}
	ElseIf (pType = "http://www.intersystems.com/zendemo^demoMenu") {
		Set tComp = ##class(ZENDemo.Component.demoMenu).%New()
	}
	ElseIf (pType = "tablePane") {
		Set tComp = ##class(%ZEN.Component.tablePane).%New()
		Set tComp.tableName="ZENDemo_Data.Employee"
		Set tComp.useSnapshot=1
		Set tComp.pageSize=20
		Set tCol = tComp.%AddColumn()
		Set tCol.colName = "ID"
		Set tCol.width = "50"

		#; add additional columns based on column options
		For tName = "Name","Title","SSN" {
			Set opt = %page.%GetComponentById("tc"_tName)
			If ($IsObject(opt)&&(opt.value)) {
				Set tCol = tComp.%AddColumn()
				Set tCol.colName = tName
				Set tCol.width = "200"
			}
		}
	}

	If $IsObject(tComp) {
		Set tComp.id = "dynamicComponent"
		Do tHolder.%AddChild(tComp)
	}
}

/// Table column checkbox has changed.
ClientMethod tcChange(cb, name) [ Language = javascript ]
{
	// see if the dynamic component is a tablePane
	// if so, modify its columns
	var table = zenPage.getComponentById('dynamicComponent');
	if (table && table.isOfType('tablePane')) {
		// call server method to recreate tablePane
		zenPage.showComponentServer('tablePane');
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	/*
	Set tGroup = ##class(%ZEN.Component.group).%New()
	Do %page.%AddChild(tGroup)

	Set tBtn = ##class(%ZEN.Component.button).%New()
	Set tBtn.caption = "Button 1"
	Do tGroup.%AddChild(tBtn)

	Set tBtn = ##class(%ZEN.Component.button).%New()
	Set tBtn.caption = "Button 2"
	Do tGroup.%AddChild(tBtn)
	
	Do %page.%RemoveChild(tGroup)
	*/

	Quit $$$OK
}

ClientMethod showObjects() [ Language = javascript ]
{
	var html = new Array();

	html[html.length] = zenPage.nextIndex + '<br/>';

	for (var i = 20; i < _zenIndex.length; i++) {
		html[html.length] = i + ': ' + (_zenIndex[i] ? _zenIndex[i]._type + (_zenIndex[i].children?_zenIndex[i].children.length:'') : 'null') + '<br/>';
	}
	
	var div = zenPage.getComponentById('objList').getEnclosingDiv();
	div.innerHTML = html.join('');
}

}

