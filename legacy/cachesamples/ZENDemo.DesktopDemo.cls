/// This is the Desktop Demonstration page for the Zen demonstration application.
Class ZENDemo.DesktopDemo Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Desktop Demo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	font-size: 0.8em;
}

#desktop {
	border: 1px solid black;
	width: 800px;
	height: 550px;
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
}

#dgCalendar, #dgNotes, #dgGrid {
	background: #c5d6d6;
	background-image: url(images/sidebargradient.png);
	background-repeat: repeat-x;
	border: 1px solid black;
}

#dgCalendar {
	top: 50px;
	left: 100px;
}

#dgNotes {
	top: 50px;
	left: 400px;
}

#dgGrid {
	top: 50px;
	left: 700px;
}

#notes textarea {
	background: #FFEEAA;
}

/* Column labels for dynaGrid. */
table.dynaGrid th.dynaGridLabel,
table.dynaGrid th.dynaGridRow,
table.dynaGrid th.dynaGridColumn {
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" 
	title="Zen Desktop Demo">
<demo:demoTitle id="title" title="Desktop Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Desktop Demo" title="Desktop Demo" />
</locatorBar>
<hgroup valign="top">
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates Zen's desktop components:">
<demo:bullet text="A desktop is a specialized group that allows the user to drag and position its child dragGroup components within a matrix of rows and columns."/>
<demo:bullet text="The desktop component supports interactive layout changes via mouse drag operations. DragGroups may be rearranged, resized or removed at will."/>
<demo:bullet text="The behavior of the desktop component can be controlled via its rowStyle and columnStyle properties."/>
</demo:sidebar>
</vgroup>
<spacer width="20"/>
<vgroup cellVAlign="top">
<hgroup labelPosition="left">
<select label="Row Style" valueList="FILL_ROW,ALIGN_ROW_TOP,ALIGN_ROW_CENTER,ALIGN_ROW_BOTTOM,FILL_UNIFORM,ALIGN_UNIFORM_TOP,ALIGN_UNIFORM_CENTER,ALIGN_UNIFORM_BOTTOM" onchange="zenPage.applyRowStyle(zenThis.getValue());"/>
<spacer width="20"/>
<select label="Column Style" valueList="FILL_COLUMN,ALIGN_COLUMN_LEFT,ALIGN_COLUMN_CENTER,ALIGN_COLUMN_RIGHT,FILL_WIDTH,ALIGN_WIDTH_LEFT,ALIGN_WIDTH_CENTER,ALIGN_WIDTH_RIGHT,FILL_UNIFORM,ALIGN_UNIFORM_LEFT,ALIGN_UNIFORM_CENTER,ALIGN_UNIFORM_RIGHT" onchange="zenPage.applyColStyle(zenThis.getValue());"/>
</hgroup>
<desktop id="desktop">
<dragGroup id="dgCalendar" header="Calendar" width="250px" height="250px">
<calendar/>
</dragGroup>
<dragGroup id="dgGrid" header="Calculator" width="250px" height="250px">
<dynaGrid gridLabel="QuikCalc"
	onchange="zenPage.calcCellChange(zenThis);"
>
<gridRow label="1"/>
<gridRow label="2"/>
<gridRow label="3"/>
<gridRow label="4"/>
<gridRow label="5"/>
<gridRow label="Total" readOnly="true" style="font-weight: bold;"/>
</dynaGrid>
</dragGroup>
<dragGroup id="dgNotes" header="Notes" width="250px" height="250px">
<textarea id="notes" controlStyle="width:100%;" rows="8"/>
</dragGroup>
</desktop>
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

/// Apply the given row style to the desktop.
ClientMethod applyRowStyle(style) [ Language = javascript ]
{
	var desktop = zenPage.getComponentById('desktop');
	desktop.setRowStyle(style);
}

/// Apply the given column style to the desktop.
ClientMethod applyColStyle(style) [ Language = javascript ]
{
	var desktop = zenPage.getComponentById('desktop');
	desktop.setColumnStyle(style);
}

/// cellChange: called when cell is changed
ClientMethod calcCellChange(grid) [ Language = javascript ]
{
	// compute sum of cells
	var rows = grid.getRowCount();

	// next get totals of rows
	var subtotal = 0;
	for (var r = 1; r < rows; r++) {
		var value = parseFloat(grid.getCellValue(r,1));
		value = isNaN(value) ? 0 : value;
		subtotal += value;

	}
	// set total cell
	grid.setCellValue(subtotal,r,1);
}

}

