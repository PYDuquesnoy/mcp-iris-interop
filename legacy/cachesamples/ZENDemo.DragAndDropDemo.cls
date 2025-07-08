/// This is the Drag-and-Drop Demonstration page for the Zen demonstration application.
Class ZENDemo.DragAndDropDemo Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Drag and Drop Demo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#priority {
	color: red;
	font-weight: bold;
	font-size: 1.2em;
	border: 1px solid black;
	width: 600px;
	height: 93px;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x500.png);
	background-repeat: repeat-x;
	padding: 3px;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" 
	title="Zen DragAndDrop Demo" dragAndDrop="true">
<demo:demoTitle id="title" title="Drag and Drop Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="DragAndDrop Demo" title="Drag and Drop Demo" />
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates Zen's drag and drop capabilities:">
<demo:bullet text="The Zen page has a dragAndDrop property. Setting this true enables drag and drop behavior for the page." />
<demo:bullet text="Each component has properties called dragEnabled and dropEnabled. Setting these true enable the default drag or drop behavior for the component." />
<demo:bullet text="Many components have built-in drag and drop behavior (such as list boxes or other controls). It is also possible to override or extend this behavior." />
<demo:bullet text="In this example, the listBoxes override the default behavior in order to remove items after they are dropped." />
</demo:sidebar>
</vgroup>

<spacer width="40"/>

<vgroup valign="top" id="mainGroup">
<spacer height="25"/>
<titleBox title="Zen Drag-and-Drop Project Manager" 
subtitle="Use the mouse to move resources between projects."/>
<spacer height="25"/>
<hgroup>
<vgroup valign="top">
<titleBox title="Project 1"/>
<listBox id="listBox1" listWidth="150px" listHeight="241px"
	dragEnabled="true" dropEnabled="true"
	 onafterdrag="zenPage.afterDrag(zenThis,dragData);">
<option text="Adam" value="1"/>
<option text="Betty" value="2"/>
<option text="Claudio" value="3"/>
<option text="Deborah" value="4"/>
<option text="Edward" value="5"/>
<option text="Fred" value="6"/>
<option text="Ginger" value="7"/>
</listBox>
</vgroup>
<spacer width="50"/>
<vgroup valign="top">
<titleBox title="Project 2"/>
<listBox id="listBox2"  listWidth="150px" listHeight="241px"
	dragEnabled="true" dropEnabled="true"
	onafterdrag="zenPage.afterDrag(zenThis,dragData);">
</listBox>
</vgroup>
<spacer width="50"/>
<vgroup valign="top">
<titleBox title="Project 3"/>
<listBox id="listBox3"  listWidth="150px" listHeight="241px"
	dragEnabled="true" dropEnabled="true"
	onafterdrag="zenPage.afterDrag(zenThis,dragData);">
</listBox>
</vgroup>
<spacer width="50"/>
<vgroup valign="top">
<titleBox title="Text Box"/>
<text dropEnabled="true"/>
</vgroup>
</hgroup>
<spacer height="50"/>
<html id="priority">Project 1 and 2 are understaffed.</html>
</vgroup>
</hgroup>
</page>
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

/// This method is called after a drag operation is completed.
/// <var>comp</var> is the component on which the drag started.
/// <var>dragData</var> is an object containing details about the 
/// drag operation.<br/>
/// <var>dragData</var> has the following properties:<br/>
/// <br/>
/// <var>dragData.value</var> - logical value of the drag data.<br/>
/// <var>dragData.text</var> - display value of the drag data.<br/>
/// <var>dragData.sourceComponent</var> - Zen component in which the drag started.<br/>
/// <var>dragData.targetComponent</var> - Zen component in which the drop occurred.<br/>
/// <var>dragData.sourceItem</var> - Component-specific value indicating where the drag started within the source.<br/>
/// <var>dragData.targetItem</var> - Component-specific value indicating where the drop occurred within the target.<br/>
/// <var>dragData.sourceMeta</var> - Arbitrary value set by the drag source.<br/>
/// <var>dragData.targetMeta</var> - Arbitrary value set by the drop target.<br/>
/// 
ClientMethod afterDrag(listBox, dragData) [ Language = javascript ]
{
	// override default behavior:
	// if this is a drag and drop between the 2 list boxes,
	// then remove the item from the drag source.
	
	// make sure target is a list box
	if (dragData.targetComponent.isOfType('listBox')) {
		// ignore drag onto ourselves
		if (dragData.targetComponent != listBox) {
			if (dragData.sourceItem >= 0) {
				listBox.removeOption(dragData.sourceItem);
				zenPage.updatePriorities();
			}
		}
	}
}

ClientMethod updatePriorities() [ Language = javascript ]
{
	// find items in each list box
	var p = new Array(3);
	p[0] = zenPage.getComponentById('listBox1').getOptionCount();
	p[1] = zenPage.getComponentById('listBox2').getOptionCount();
	p[2] = zenPage.getComponentById('listBox3').getOptionCount();

	var top = 0;
	var bottom = 2;
	if (p[0] < p[1]) {
		top = (p[0] < p[2]) ? 0 : 2;
		bottom = (p[1] > p[2]) ? 1 : 2;
	}
	else {
		top = (p[1] < p[2]) ? 1 : 2;
		bottom = (p[0] > p[2]) ? 0 : 2;
	}

	var msg = 'Project ' + (top+1) + ' is the top priority.';
	if (p[bottom] > 3) {
		msg += '<br/>' + 'Project ' + (bottom+1) + ' is not important.'
	}

	var html = zenPage.getComponentById('priority');
	html.setProperty('content',msg);
}

}

