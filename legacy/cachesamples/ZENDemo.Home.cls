/// This is the home page for the Zen demonstration application.
Class ZENDemo.Home Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Home";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* style for lookout menu */
#lookout {
	border: 1px solid black;
	overflow: auto;
	background: white;
}

.lookoutTab {
	background: white;
	border-bottom: 1px solid black;
}

.lookoutButton {
	color: white;
	background: rgb(47,98,128);
	font-weight: bold;
	font-family: verdana;
	font-size: 1.0em;
	text-align: left;
	border: 1px solid rgb(27,78,108);
}

.lookoutButton:hover {
	background: rgb(47,128,98);
}

#iframe {
	border: none;
}

</style>
}

/// This XML block defines the contents of this page.
/// Setting XMLNamespace turns on StudioAssist for this XML block.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Demo" height="100%">
<demo:demoTitle id="title" title="Welcome"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page"/>
</locatorBar>
<hgroup width="100%" cellAlign="left" cellVAlign="top">
<lookoutMenu id="lookout" expandable="false" 
	onexpand="zenPage.onlayoutHandler();" 
	oncontract="zenPage.onlayoutHandler();"
	remember="true">
<tab caption="Overview" id="menuOverview">
<menuItem   caption="Form Demo"
					link="ZENDemo.FormDemo.cls"
					image="images/folder.gif"
					title="A demonstration of a form built with Zen"
					/>
<menuItem   caption="SVG Dashboards"
					link="ZENDemo.Dashboard.cls"
					image="images/folder.gif"
					title="A demonstration of an SVG-based Dashboard built with Zen"
					/>
<menuItem   caption="Expense Calculator"
					link="ZENDemo.ExpenseCalculator.cls"
					image="images/folder.gif"
					title="A demonstration of an interactive SVG-based Chart built with Zen"
					/>

<menuItem   caption="Drag and Drop"
					link="ZENDemo.DragAndDropDemo.cls"
					image="images/folder.gif"
					title="A demonstration of Zen's drag-and-drop capabilities"
					/>

<menuItem   caption="Active Groups"
					link="ZENDemo.ActiveGroupDemo.cls"
					image="images/folder.gif"
					title="A demonstration of Zen's active group components"
					/>

<menuItem   caption="Desktop"
					link="ZENDemo.DesktopDemo.cls"
					image="images/folder.gif"
					title="A demonstration of Zen's desktop components"
					/>


<menuItem   caption="Controls"
					link="ZENDemo.ControlTest.cls"
					image="images/folder.gif"
					title="A demonstration of the various controls included with Zen"
					/>
<menuItem   caption="Methods"
					link="ZENDemo.MethodTest.cls"
					image="images/folder.gif"
					title="A demonstration of method calls using Zen"
					/>

</tab>
<tab caption="Components" id="menuComponents">
<menuItem   caption="Grids"
					link="ZENTest.DynaGridTest.cls"
					image="images/folder.gif"
					title="A demonstration of the Zen grid component"
					/>
<menuItem   caption="Tables"
					link="ZENTest.TableTest.cls"
					image="images/folder.gif"
					title="A demonstration of the Zen table component"
					/>
<menuItem   caption="Trees"
					link="ZENTest.DynaTreeTest.cls"
					image="images/folder.gif"
					title="A demonstration of the Zen tree control"
					/>
<menuItem   caption="Tabs"
					link="ZENTest.TabTest.cls"
					image="images/folder.gif"
					title="A demonstration of the Zen tab component"
					/>
<menuItem   caption="Menus"
					link="ZENTest.MenuTest.cls"
					image="images/folder.gif"
					title="A demonstration of menus build with Zen"
					/>
<menuItem   caption="HTML Component"
					link="ZENTest.HTMLTest.cls"
					image="images/folder.gif"
					title="A demonstration of the Zen HTML component"
					/>
<menuItem   caption="Popup Windows"
					link="javascript: zenPage.showPopupWindow();"
					image="images/folder.gif"
					title="A demonstration of launching a popup window"
					/>
<menuItem   caption="Dialogs"
					link="javascript: zenPage.showFileSelectionWindow();"
					image="images/folder.gif"
					title="A demonstration of launching a dialog window"
					/>
</tab>
<tab caption="SVG Components" id="menuSVG">
<menuItem   caption="SVG Line Charts"
					link="ZENTest.SVGLineChartTest.cls"
					image="images/folder.gif"
					title="A demonstration of SVG line charts"
					/>

<menuItem   caption="SVG Bar Charts"
					link="ZENTest.SVGBarChartTest.cls"
					image="images/folder.gif"
					title="A demonstration of SVG bar charts"
					/>

<menuItem   caption="SVG Pie Charts"
					link="ZENTest.SVGPieChartTest.cls"
					image="images/folder.gif"
					title="A demonstration of SVG pie charts"
					/>

<menuItem   caption="SVG Components"
					link="ZENTest.SVGLayoutTest.cls"
					image="images/folder.gif"
					title="A demonstration of the SVG components"
					/>
<menuItem   caption="SVG OwnerDraw Test"
					link="ZENTest.SVGOwnerDrawTest.cls"
					image="images/folder.gif"
					title="A demonstration of the SVG owner-draw component"
					/>
</tab>
<tab caption="Model View Controller" id="menuMVC">
<menuItem   caption="Form Demo"
					link="ZENMVC.MVCForm.cls"
					image="images/folder.gif"
					title="A demonstration of an MVC form"
					/>

<menuItem   caption="Form Template Demo"
					link="ZENMVC.PatientForm.cls"
					image="images/folder.gif"
					title="A demonstration of an MVC form based on a template class"
					/>

<menuItem   caption="Master Detail Demo"
					link="ZENMVC.MVCMasterDetail.cls"
					image="images/folder.gif"
					title="A demonstration of master/detail page built using MVC"
					/>

<menuItem   caption="Chart Demo"
					link="ZENMVC.MVCChart.cls"
					image="images/folder.gif"
					title="A demonstration of an SVG chart driven by an MVC data model"
					/>
<menuItem   caption="Meter Demo"
					link="ZENMVC.MVCMeters.cls"
					image="images/folder.gif"
					title="A demonstration of SVG meters driven by an MVC data model"
					/>
</tab>

<tab caption="Sample Applications" id="menuApp">
<menuItem   caption="HelpDesk Application"
					link="ZENApp.SampleApp.cls"
					image="images/folder.gif"
					title="Show the HelpDesk sample application"
					/>


<menuItem   caption="Visual Navigator"
					link="ZENDemo.SVGBrowser.cls"
					image="images/folder.gif"
					title="Show the Visual Navigator sample application"
					/>

</tab>

<tab caption="Test Suite" id="menuTest">
<menuItem   caption="Zen Test Suite"
					link="ZENTest.TestApplication.cls"
					image="images/folder.gif"
					title="Show the list of available Zen test pages"
					/>

</tab>
</lookoutMenu>
<spacer width="20"/>
<vgroup valign="top">
<html id="description" width="800" OnDrawContent="DrawDescription"/>
<iframe id="iframe" src="images/zenLogo.svg" width="600" height="600"/>
</vgroup>
</hgroup>
</page>
}

/// DrawDescription
Method DrawDescription(seed As %ZEN.Datatype.string) As %Status
{
	Write $$$TextHTML("Welcome to Zen, the Web Application Development Framework!")
	Quit $$$OK
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// adjust size of lookout menu
	var menu = zenPage.getComponentById('lookout');
	zenASSERT(menu,'Unable to find menu',arguments);

	// find divs for title & mainMenu
	var title = zenPage.getComponentById('title');
	var locator = zenPage.getComponentById('locator');
	var divTitle = title.getEnclosingDiv();
	var divLocator = locator.getEnclosingDiv();

	// find height of window
	var winHeight = zenGetWindowHeight();

	// adjust size of menu
	var sz = winHeight - (parseInt(divTitle.offsetHeight) + parseInt(divLocator.offsetHeight)) - 20;
	menu.setSize(220,sz);
}

/// Demonstration of launching a popup window. 
ClientMethod showPopupWindow() [ Language = javascript ]
{
	zenLaunchPopupWindow('%ZEN.Dialog.colorSelect.cls','ColorPicker','status,scrollbars,resizable=no,width=500,height=700');
}

/// Demonstration of launching a file selector window. 
ClientMethod showFileSelectionWindow() [ Language = javascript ]
{
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.cls','FileSelection','status,scrollbars,resizable,width=500,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'ColorPicker':
		// set background of the enclosing div of the page
		zenPage.getEnclosingDiv().style.background = value;
		break;
	}
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	#; make sure we have demo data created
	Do ..CreateDemoData()
	Quit $$$OK
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

/// Create the data used by the various demo page by calling
/// the appropriate Populate methods.
/// This is done the first time the demo pages are run.
ClassMethod CreateDemoData()
{
	#; patient
	&sql(SELECT COUNT(*) INTO :count FROM ZENDemo_Data.Patient)
	If (count = 0) {
		Do ##class(ZENDemo.Data.Patient).%KillExtent()
		Do ##class(ZENDemo.Data.Patient).Populate(1000)
	}

	#; employee
	&sql(SELECT COUNT(*) INTO :count FROM ZENDemo_Data.Employee)
	If (count = 0) {
		Do ##class(ZENDemo.Data.Employee).%KillExtent()
		Do ##class(ZENDemo.Data.Employee).Populate(1000)
	}

	#; invoice
	&sql(SELECT COUNT(*) INTO :count FROM ZENApp_Report.Invoice)
	If (count = 0) {
		Do ##class(ZENApp.Report.Invoice).%KillExtent()
		Do ##class(ZENApp.Report.Invoice).Populate(1000)
	}
}

}

