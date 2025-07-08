/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays controls without attached content. The widget does not
/// require a dataSource to allow definition of controls. Some controls themselves require a dataSource to add information,
/// for example the filter controls.
Class %DeepSee.Component.Widget.controlPanel Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// This widget can override the title bar display.
Property showTitleBar As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specify whether to display the separator between the toolbar and widget content
Property showToolbarBottomBorder As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Style for widget sections
XData Style
{
<style type="text/css">

.controlError {
	background: #f6f8f9;
	padding: 3px;
	color: darkred;
	border: 1px solid #808080;
	box-shadow: 2px 2px 2px #808080;
	position: absolute;
	font-family: arial;
	font-size: 12pt;
	z-index: 10;
}
</style>
}

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Controls Widget","%DeepSee"),..%ClassName(1),"deepsee/ds2_equalizer_44.png")
	Set pSubtypeList($I(n)) = $LB("verticalControls",$$$Text("Vertical Control Widget","%DeepSee"),,"deepsee/ds2_equalizer_44.png")
	Set pSubtypeList($I(n)) = $LB("horizontalControls",$$$Text("Horizontal Control Widget","%DeepSee"),,"deepsee/ds2_equalizer_44.png")
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	// $LB(name,value,type,caption,title,hidden,displayList)
	Set pInfo($I(pInfo)) = $LB("showTitleBar",1,"%Boolean","Show Title Bar","Hide the toolbar for a controls widget.")
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList)
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			Set tPValue(tName) = $S(..%definition.properties.%IsA("%Collection.AbstractArray"):..%definition.properties.GetAt(tName),1:"")
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}
		
		Set ..showTitleBar = +$G(tPValue("showTitleBar"))
		
		// add invisible div to support style hacking
		// add pivot table to the widget
		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.id = ..%MakeWidgetId("test")
		Set tHTML.enclosingStyle = "display:none;"
		Set tSC = pGroup.%AddChild(tHTML)
		If $$$ISERR(tSC) Quit
		
		// add controlPanel content to the widget. This is a placeholder to keep consistent with the
		// standard widget architecture.
		Set tPanel = ##class(%DeepSee.Component.Widget.abstractControlPanel).%New()

		Merge tPanel.settings = tPValue

		Set tPanel.id = ..%MakeWidgetId("controlBody")
		Set tPanel.enclosingStyle = "background: white;"
		//Set tSC = pGroup.%AddChild(tPanel)
		If $$$ISERR(tSC) Quit

		// If we have a data source, create a data controller
		Set tSC = ..%CreateController(pGroup, .tController)
		If $$$ISERR(tSC) Quit
	
		// connect portlet to controller
		If $IsObject(tController) {
			Set:$IsObject(tController) tPanel.controllerId = tController.id
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// If this widget has a data source, create a data controller that
/// will serve this data to the client.<br/>
/// The controller's id is "controller" (within the scope of this widget).
Method %CreateController(pGroup As %ZEN.Component.abstractGroup, Output pController As %ZEN.Auxiliary.abstractController) As %Status
{
	Set tSC = $$$OK
	Try {
		// see if we have a data source
		Set tMsg = ""
		Set pController = ""
		Set tKPIClass = ""
		Set tDataSource = ..dataSource
		Set tExt = $P(tDataSource,".",$L(tDataSource,"."))
		If (tExt = "kpi") {
			Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
		}
		ElseIf (tExt = "worksheet") {
			Set tKPIClass = "%DeepSee.KPIWorksheet"
		}

		If (tKPIClass'="") {
			// add data controller to the widget
			Set pController = ##class(%ZEN.Auxiliary.dataController).%New()
			Set pController.id = ..%MakeWidgetId("controller")
			Set pController.modelClass = tKPIClass
			If (tExt = "metric") {
				Set pController.modelId = ..dataSource
			}
			ElseIf (tExt = "worksheet") {
				Set pController.modelId = ..dataSource
			}
			Set tSC = pGroup.%AddChild(pController)
			If $$$ISERR(tSC) Quit
			Set tInvert = 0
		}
		ElseIf (tExt="pivot") {
			// saved pivot
			// create a hidden pivotTable and use it as the controller
			Set tPivotDef = ""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dataSource)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource,.tSC)
				If $$$ISERR(tSC) Quit
			}

			If '$IsObject(tPivotDef) {
				// Show error on widget
				Set tLabel = ##class(%ZEN.Component.label).%New()
				Set tLabel.value = $$$FormatText($$$Text("The data source '%1' is missing.","%DeepSee"),..dataSource)
				Set tLabel.enclosingClass = "portletError"
				Set tSC = pGroup.%AddChild(tLabel)
				If $$$ISERR(tSC) Quit
			}

			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()
			Set tPivotTable.id = ..%MakeWidgetId("controller")
			Set tPivotTable.hidden = 1
			Set tSC = pGroup.%AddChild(tPivotTable)
			If $$$ISERR(tSC) Quit

			// test for bad pivot
			If $IsObject(tPivotDef) {
				// copy information from the saved item to the graphical pivot
				Set tSC = tPivotDef.%CopyToComponent(tPivotTable)
				If $$$ISERR(tSC) Quit
			}
			
			Set pController = tPivotTable
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnAddToPageBefore() As %Status
{
	Set tSC = $$$OK
	Try {
		// avoid double rendering
		If (..children.Count() > 0) Quit

		If ($G(%zenContext)="method") {
			// don't bother to recreate children of this widget
			// during processing of client method call
			Quit
		}
		
		// check for write privilege
		Set tCanWrite = 0
		If ($IsObject(%page)&&%page.%IsA("%DeepSee.UserPortal.DashboardViewer")&&'%page.readOnly&&%page.dashboardModify) {
			Set tCanWrite = 1
		}
		// default settings
		// set flag to prevent ie timing issues with charts--jmd
		Set ..onclosepending = "zenPage._containerClosing=true;if (zenPage.widgetClosing) {zenPage.widgetClosing();}"
		Set ..layout = "vertical"
		Set ..cellVAlign = "top"
		If ('..previewMode) {
			Set ..onresize = "zenPage.getComponent("_..index_").adjustSizes(false);"
		}
		Set ..headerLayout = $S(..previewMode:"T",tCanWrite:"CFT",1:"FT")

		// add header group (use form so we can grab values from filters)
		Set tParentHeader = ##class(%ZEN.Component.group).%New()
		Set tParentHeader.id = ..%MakeWidgetId("pheader")
		Set tParentHeader.layout = "none" // tells system to project this as a div rather than a table
		Set tParentHeader.enclosingStyle="background-color:transparent;opacity:1.0;position:relative;top:0px;left:0px"
		Set tSC = ..%AddChild(tParentHeader)
		If $$$ISERR(tSC) Quit
		Set tBkgHeader = ##class(%ZEN.Component.group).%New()
		Set tBkgHeader.id = ..%MakeWidgetId("bkgheader") // control needs to get bkgheader to set its attributes of background-color and opacity
		Set tBkgHeader.layout = "none"
		Set tBkgHeader.enclosingStyle="position:absolute;top:0px;left:0px;right:0px;bottom:0px;display:block;background-color:"_..colorToolbar_";opacity:"_..opacityToolbar_";z-index:-100"
		Set tSC = tParentHeader.%AddChild(tBkgHeader)
		If $$$ISERR(tSC) Quit
		//- JSL4483
			
		If (..subtype="horizontalControls") {
			Set tHeader = ##class(%ZEN.Component.hgroup).%New()
			Set tHeader.cellStyle = "padding-right:6px;"
		}
		Else {
			Set tHeader = ##class(%ZEN.Component.vgroup).%New()
			Set tHeader.cellStyle = "padding-top:6px;"
		}
		Set tHeader.id = ..%MakeWidgetId("header")
		Set tHeader.enclosingClass = "dswidgetHeader"
		
		Set tHeader.labelPosition = "top"
		Set tHeader.cellVAlign = "bottom"
		// select this widget
		Set tHeader.onclick = "zenPage.getComponent("_..index_").selectWidget(zenEvent);"
		Set tSC = tParentHeader.%AddChild(tHeader)
		If $$$ISERR(tSC) Quit

		// command buttons
		Set tSC = ..%CreateCommandButtons(tHeader,tCanWrite)

		// let subclass add components to header group
		Set tSC = ..%OnCreateControls(tHeader)
		If $$$ISERR(tSC) Quit

		// create controls
		If ($IsObject(..%definition)) {
			Set ..dataSource = ..%definition.%GetDataSource()
			If (..%definition.controls.Count()>0) {
				Set tSC = ##class(%DeepSee.UserPortal.DashboardViewer).%CreateControls("widget",..%definition.controls,tHeader,##this)
				If $$$ISERR(tSC) Quit
			}
		}
				
		// add main group; this holds the content and sidebar
		Set tMainGroup = ##class(%ZEN.Component.hgroup).%New()
		Set tMainGroup.id = ..%MakeWidgetId("main")
		Set tSC = ..%AddChild(tMainGroup)
		If $$$ISERR(tSC) Quit

	// let subclass add components to main group
		Set tSC = ..%OnCreateWidget(tMainGroup)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClientMethod navSelectItem(key, value, final) [ Language = javascript ]
{
	var forceUpdate = false;
	if (key=='widget-common-widgetSubtype') {
		if (value != this.subtype) forceUpdate = true;
	}	
	this.invokeSuper('navSelectItem',arguments);
	if (forceUpdate) {
		// Stupid widget template is overconstrained at the server
		// will fix it locally to avoid full page refresh
		var header = this.findComponent('header');
		var headerDiv = header.getEnclosingDiv();
		for (var t = headerDiv.firstChild; t && t.tagName!='TABLE'; t=t.nextSibling);
		if (t) {
			for (var tb = t.firstChild; tb && tb.tagName!='TBODY'; tb=tb.nextSibling);
			if (tb) {
				var tdArray = []
				this.extractTDNodes(t,tdArray);
				tb.innerHTML="";
				if (this.subtype == "horizontalControls") {
					t.style.width="";
					var tr = document.createElement('tr');
					var len = tdArray.length;
					for (var i=0;i<len;i++) {
						var td = tdArray[i].node;
						td.innerHTML = tdArray[i].content;
						td.style.paddingRight = "6px";
						td.style.textAlign = "";
						tr.appendChild(td);
					}
					tb.appendChild(tr);
				}
				else { //verticalControls
					//t.style.width="100%";
					var len = tdArray.length;
					for (var i=0;i<len;i++) {
						var tr = document.createElement('tr');
						var td = tdArray[i].node;
						td.innerHTML = tdArray[i].content;
						//tr.style.width= "100%";
						td.style.paddingRight = "0px";
						//td.style.textAlign = "center";
						tr.appendChild(td);
						tb.appendChild(tr);
					}
				}
			}
		}
	}
}

ClientMethod extractTDNodes(tableRoot, tdArray) [ Internal, Language = javascript ]
{
	if (tableRoot && tableRoot.tagName=='TD') tdArray.push({node:tableRoot,content:tableRoot.innerHTML});
	else {
		for (var n=tableRoot.firstChild; n; n = n.nextSibling) {
			this.extractTDNodes(n,tdArray);
		}
	}
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	if (this.subtype == 'verticalControls' ) return;
	
	// DTB447 - The header *is* the content in the controls widget case!	
	// Inspect the header contents in an attempt to make sure all
	// controls are visible. Fill the available widget space with the header.
	var header = this.findComponent('header');
	var headerDiv = header.getEnclosingDiv();
	
	headerDiv.style.width = width + 20 + 'px';
	headerDiv.style.height = (headerDiv.style.height ? parseInt(headerDiv.style.height) : 0) + height + 20 + 'px';
}

/// Apply the given filter to this widget.
ClientMethod applyFilter(name, value) [ Language = javascript ]
{
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('controller');
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ..%FindComponent("controller")
}

/// Test if this widget is ready to be resized.
ClientMethod isReady() [ Internal, Language = javascript ]
{
	var controller = this.getDataController();
	if (controller && controller.hasData) {
		return controller.hasData();
	}
	return true;
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	Quit $$$OK
}

}
