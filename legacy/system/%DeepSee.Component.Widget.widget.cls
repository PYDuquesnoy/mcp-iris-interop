/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for DeepSee Dashboard widgets.<br/>
/// Instances of this class, or its subclasses, represent graphical items within a
/// DeepSee Dashboard (such as a pivot, chart, or meter).
Class %DeepSee.Component.Widget.widget Extends %ZEN.Component.dragGroup [ Abstract, System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js";

Parameter DOMAIN = "%DeepSee";

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Set this to false to prevent this widget from being listed.
Parameter PUBLISHED As Boolean = 1;

/// Default header layout pattern.
/// N.B. Overridden in code.
Parameter DEFAULTHEADERLAYOUT = "CIFT";

/// Default image for close group button.
Parameter DEFAULTCLOSEIMAGE = "images/MacCloseX.png";

/// Default image for maximize group button.
Parameter DEFAULTMAXIMAGE = "images/MacFullScreenPlus.png";

/// Default image for minimize group button.
Parameter DEFAULTMINIMAGE = "images/MacIconifyDash.png";

/// Default image for contract group button.
Parameter DEFAULTCONTRACTIMAGE = "images/MacIconifyDash.png";

/// Default image for expand group button.
Parameter DEFAULTEXPANDIMAGE = "images/MacIconifyDash.png";

/// Default image for maximize group button.
Parameter DEFAULTRESIZEIMAGE = "images/grayDragResize.png";

/// Default resize icon size in pixels
Parameter DEFAULTRESIZEICONSIZE = 16;

/// Specify which specific sub-type of widget to display. The interpretation of this
/// is up to subclasses to implement.
Property subtype As %ZEN.Datatype.string;

/// HTML content of sidebar.
Property sidebarContent As %ZEN.Datatype.html;

/// Specify whether to display a toolbar.
Property showToolbar As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specify whether to display the separator between the toolbar and widget content
Property showToolbarBottomBorder As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specify whether to display a toolbar.
Property showToolbarOnlyWhenMaximized As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Specify whether to display a sidebar.
Property showSidebar As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Width of sidebar area.
Property sidebarWidth As %ZEN.Datatype.length [ InitialExpression = "25%" ];

/// Used to hold a reference to the widget definition that defined this widget.
Property %definition As %DeepSee.Dashboard.Widget(XMLPROJECTION = "none");

/// A string containing the layout state for this widget:
/// "key:top:left:width:height:max"
/// This is used by "SaveSettings"
Property widgetLayout As %ZEN.Datatype.string;

/// Identifying key for the widget.
Property widgetKey As %ZEN.Datatype.integer;

/// If true, then render in preview mode.
Property previewMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Holder for dataSource.
Property dataSource As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// If this widget is linked, then this is the key of the widget we are linked to.
/// Set when the page is created.
Property linkWidgetKey As %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

/// Names of target widgets to send click events to.
Property clickTargets As list Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Names of actions to raise for click events.
Property clickActions As list Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Names of target properties for click events.
Property clickTargetProperties As list Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Array of component indices for controls created by this widget.
Property controlIndices As list Of %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

/// Special filter value applied to this widget in response to a click event.
/// Also used to handle filters passed in as part of the URL that are not mapped to
/// a filter control.<br/>
/// If this starts with "%FILTER ", then this is one or more %FILTER clauses.
Property clickFilterSpec As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Array of logical names of filters on this widget and their current values.<br/>
/// Each name is of the form: [DIM].[HIER].[LEVEL]<br/>
/// Each value is an MDX key value.
Property filterState As array Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Array of logical names of filters on this widget and their current display value.<br/>
/// This augments the <property>filterState</property> property.
Property filterText As array Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Array of default values of filters on this widget.<br/>
/// This is used to prevent saving of default values for widgets.
/// This augments the <property>filterState</property> property.
Property filterDefault As array Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Settings applied to this widget.
/// These are pulled from the URL of the dashboard viewer.
Property settings As array Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Value of most recently selected item on this widget, if applicable.
Property currValue As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Value name for most recently selected item on this widget, if applicable.
Property currValueName As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Filter spec for most recently selected item on this widget, if applicable.
/// If this starts with "%FILTER ", then it contains one or more "%FILTER" clauses.
Property currFilterSpec As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Item number for most recently selected item on this widget, if applicable.
Property currItemNo As %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

/// Series number for most recently selected item on this widget, if applicable.
Property currSeriesNo As %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

/// If true, then there are filter values that have to be applied.
Property hasInitialFilters As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// If true, then this widget should be maximized when it is initially displayed.
Property maximized As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// color of toolbar
Property colorToolbar As %ZEN.Datatype.color(XMLPROJECTION = "NONE") [ InitialExpression = "#F0F0F0" ];

Property opacityToolbar As %ZEN.Datatype.float(XMLPROJECTION = "NONE") [ InitialExpression = 1.0 ];

/// color of widget background
Property backgroundColor As %ZEN.Datatype.color(XMLPROJECTION = "NONE") [ InitialExpression = "#F0F0F0" ];

/// opacity of widget background
Property opacity As %ZEN.Datatype.float(XMLPROJECTION = "NONE") [ InitialExpression = 1.0 ];

/// Prevent the user from changing the settings for show toolbar.
Property forceToolbar As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Current CSP session.
Property sessionCookie As %ZEN.Datatype.string;

/// Names of activeWhen values for click events.
Property clickActive As list Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// homeRow value before a widget is dragged
Property prevHomeRow As %ZEN.Datatype.integer;

/// homeCol value before a widget is dragged
Property prevHomeCol As %ZEN.Datatype.integer;

/// isClosed stores the state of a widget
Property isClosed As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Style for widget sections
XData Style
{
<style type="text/css">

.dragGroup {
	padding: 0px;
	margin: 0px;
	border: none;
}

.dragHeader {
	border-bottom: 1px solid #D0D0D0;
	background: rgb(220,231,241);
	background-image: none;
	color: #404040;	
	font-family: arial;
}

/* header area */
.dswidgetHeader {
	color: #404040;
	padding: 2px;
	font-size: 10px;
	overflow: hidden;
	overflow-x: auto;
	border-bottom: 1px solid #D0D0D0;
	margin-top: auto;
}

/* icon in header */
.dswidgetHeader img {
	border: 1px solid transparent;
	height: 20px;
	padding: 1px;
	opacity: 0.8;
}

.dswidgetHeader img:hover {
	border: 1px solid #D0D0D0;
	background: #FFEEAA;
	opacity: 1.0;
}

.dswidgetHeader img:active {
	background: white;
	box-shadow: 2px 2px 2px #FFEEAA, -2px -2px 2px #FFEEAA;
}

/* Sidebar area */
.dswidgetSidebar {
	color: #404040;
	padding: 4px;
	font-size: 12px;
	overflow: hidden;
	width: 100%;
	height: 100%;
}

/* footer area */
.dswidgetFooter {
	color: #404040;
	padding: 2px;
	font-size: 12px;
	overflow: hidden;
}

/* command button */
.dsWidgetCommand {
	font-size: 10px;
	border:none;
	color: blue;
	background: none;
}

.dsWidgetCommand:hover {
	background: #FFEEAA;
}

.dsWidgetCommandDisabled {
	font-size: 10px;
	border:none;
	color: gray;
	background: none;
}

</style>
}

/// Override dragGroup behavior.
Method %DrawHTML()
{
	If ('..previewMode) {
		// Do ##super()

		// JMD1128: adjust size of header based on mode!
		#; header
		Set tStyle = ""
		&html<<div class="dragHeader" style="#(tStyle)#" id="#(..%MakeId("header"))#" onclick="zenPage.getComponent(#(..index)#).selectWidget(event||window.event);"></div>>		// DTB196 - Use cross-browser event language
		
		#; children
		&html<<div class="dragChildren" id="#(..%MakeId("children"))#" style="position:absolute" >>
		Do ..%LayoutChildren(..tuple)
		&html<</div>>
	}
	Else {
		#; preview mode
		#; header
		&html<<div class="dragHeader" id="#(..%MakeId("header"))#" style="cursor: default;"><div style="padding:2px;" onclick="zenPage.getComponent(#(..index)#).selectWidget(event||window.event);">#(..header)#</div></div>>		// DTB196 - Use cross-browser event language
		
		#; children
		&html<<div class="dragChildren" id="#(..%MakeId("children"))#">>
		Do ..%LayoutChildren(..tuple)
		&html<</div>>
	}

	#; Modify renderFlag to be force client-side call to renderContents
	Set ..renderFlag = ..renderFlag + 1
}

/// Create an id value for an component within this widget.
Method %MakeWidgetId(pString As %String) As %String
{
	Quit ..id _ "/" _ pString
}

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	// $LB(name,value,type,caption,title)
	Quit $$$OK
}

/// If implemented, this callback method is called at page render-time
/// when this component is added to a page but before any of its children
/// have been created.
Method %OnAddToPageBefore() As %Status
{
	Set tSC = $$$OK
	Try {
		// avoid double rendering
		If (..children.Count() > 0) Quit

		// JMD1005
		If ($G(%zenContext)="method") {
			// don't bother to recreate children of this widget
			// during processing of client method call
			Quit
		}

		// check for write privilege
		Set tCanWrite = 0
		If ($IsObject(%page)&&%page.%IsA("%DeepSee.UserPortal.DashboardViewer")&&'%page.readOnly&&%page.dashboardModify) {
			// JMD996 Check dashboardModify
			Set tCanWrite = 1
		}

		// default settings
		// set flag to prevent ie timing issues with charts--jmd
		
		// zenThis.abortClose() prevents the widget's enclosing div from being deleted, which allows it to be reopened
		Set ..onclosepending = "zenThis.abortClose(); zenThis.closeWidget();"
		
		Set ..onwindowdrop = "zenThis.setModifiedIfDragged();"
		Set ..onwindowgrab = "zenThis.initializeHomeRowCol();"
		Set ..layout = "vertical"
		Set ..cellVAlign = "top"
		If ('..previewMode) {
			Set ..onresize = "zenPage.getComponent("_..index_").adjustSizes(false);"
		}
		Set ..headerLayout = $S(..previewMode:"T",tCanWrite:"CFT",1:"FT")

		// add header group (use form so we can grab values from filters)
		//+ JSL4483
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
		Set tHeader = ##class(%ZEN.Component.hgroup).%New()
		Set tHeader.id = ..%MakeWidgetId("header")
		Set tHeader.enclosingClass = "dswidgetHeader"
		If (..showToolbar=0) {
			Set tHeader.enclosingStyle = "display:none;"
		}
		
		Set tHeader.labelPosition = "top"
		Set tHeader.cellStyle = "padding-right:6px;"
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
		Set tMainGroup.cellVAlign = "top"
		Set tSC = ..%AddChild(tMainGroup)
		If $$$ISERR(tSC) Quit

		// let subclass add components to main group
		Set tSC = ..%OnCreateWidget(tMainGroup)
		If $$$ISERR(tSC) Quit
		
		// +DTB194 - Move code to supporting methods
		Set tSC = ..%AddSidebar(tMainGroup)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ..%AddFooter()
		If $$$ISERR(tSC) Quit
		// -DTB194
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add a sidebar to the <var>pMainGroup</var> of this widget.
Method %AddSidebar(pMainGroup) As %Status
{
	// Method added by DTB194
	Set tSC = $$$OK
	Try {
		Set tSidebar = ##class(%ZEN.Component.html).%New()
		Set tSidebar.id = ..%MakeWidgetId("sidebar")
		Set tSidebar.content = ..sidebarContent
		// DTB122 don't set sidebarWidth here, that is accounted for in adjustSizes
		Set tSidebar.enclosingClass = "dswidgetSidebar"
		Set tSidebar.hidden = '..showSidebar
		
		Set tSC = pMainGroup.%AddChild(tSidebar)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Add a footer to this widget.
Method %AddFooter() As %Status
{
	// Method added by DTB194
	Set tSC = $$$OK
	Try {
		Set tFooter = ##class(%ZEN.Component.html).%New()
		Set tFooter.id = ..%MakeWidgetId("footer")
		Set tFooter.enclosingClass = "dswidgetFooter"
		Set tFooter.content = ""
		Set tSC = ..%AddChild(tFooter)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Create the "command" buttons for this widget.
Method %CreateCommandButtons(pGroup As %ZEN.Component.group, pCanWrite As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tHeader = pGroup
		

		// analyzer button

		// JMD1128 definition *might* be a proxy object without this method!
		Set tDataSource = $S('$IsObject(..%definition):"",..%definition.localDataSource'="":..%definition.localDataSource,1:..%definition.dataSource)
		If ( $IsObject(..%definition) && (..%definition.dataLink="") && (tDataSource[".pivot")) {
			// DTB310 - Ability to write to the dashboard is not a condition for using the mini-Analyzer
			// test for analyzer property
			Set tAnalyze = ..%definition.properties.GetAt("analyzer")
			Set:tAnalyze="" tAnalyze=0				// DTB171 - Initialize widget without the mini-Analyzer

			If (tAnalyze) {
				// does user have analyzer view privilege?
				If ($$CheckAnalyzerViewAccess^%qdsUtils()) {
					Set tButton = ##class(%ZEN.Component.image).%New()
					Set tButton.src = "deepsee/ds2_calculator_44.png"
					Set tButton.title = $$$Text("Use the Analyzer to change the data displayed in this widget","%DeepSee")
					If (..previewMode) {
						Set tButton.disabled = 1
					}
					Else {
						Set tButton.onclick = "zenPage.showAnalyzerDialog('"_..widgetKey_"','"_$ZCVT(..%definition.dataSource,"O","JS")_"','"_$ZCVT(..%definition.localDataSource,"O","JS")_"');"
					}
					Do tHeader.%AddChild(tButton)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
/// <var>pGroup</var> is the group to which new Zen components should be added.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// +DTB581 - Move to widget class
	for (var n = 0; n < this.controlIndices.length; n++) {
		var control = zenPage.getComponent(this.controlIndices[n]);
		if (control && control.name == 'applyVariable') { 
			control.onchangeHandler(); // JSL4419
		}
	}
	// -DTB581
	
	this.adjustSizes(true);
	this.updateControlState();
	if (this.hasInitialFilters) {
		// DTB655
		var dc = this.getDataController();
		var initialExecute = (dc._type=="pivotTable") ? dc.initialExecute : true;
	
		this.applyFilters(initialExecute);
		this.hasInitialFilters = false;
	}
	this.setProperty('opacity',this.opacity); // JSL4483
	this.setProperty('backgroundColor',this.backgroundColor); // JSL4483
	var legendDiv = document.getElementById(this.id+'/chartLegend'); // JSL4503
	if (legendDiv != null) { // JSL4503
		dragGroupDiv = this.getEnclosingDiv(); // JSL4503
		if (dragGroupDiv != null && dragGroupDiv._transparent) { // JSL4503
			dragGroupDiv.style.background = 'transparent'; // JSL4503
		} // JSL4503
	} // JSL4503
	return this.invokeSuper('onloadHandler',arguments);
}

/// Find a component within this widget with the given sub id.
ClientMethod findComponent(id) [ Language = javascript ]
{
	return zenPage.getComponentById(this.id + '/' + id);
}

/// Find a component within this widget with the given sub id.
Method %FindComponent(id As %String) As %ZEN.Component.component
{
	Quit %page.%GetComponentById(..id _ "/" _ id)
}

/// Test if this widget is ready to be resized.
ClientMethod isReady() [ Internal, Language = javascript ]
{
	return true;
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustSizes(load) [ Language = javascript ]
{
	if (this.isResizeInProgress()) {
		zenPage.setModified(true);
		return;
	}
	var div = this.getChildDiv();
	if (null == div) {
		//alert('null div');
		return;
	}

	var head = this.findComponent('header');
	var main = this.findComponent('main');
	var foot = this.findComponent('footer');
	var side = this.findComponent('sidebar');
	var sideDiv = side ? side.getEnclosingDiv() : null;

	var headH = (head && head.getEnclosingDiv()) ? head.getEnclosingDiv().offsetHeight : 0;
	var footH = 0;
	if (foot && (''==foot.content)) {
		// DTB171 - Footer has padding. If it's empty, treat it as height 0.
		var ft = foot.getEnclosingDiv();
		if (ft) {
			ft.style.display = 'none';
		}
		footH = 0;
	}
	else {
		footH = 0;
	}
	
	if (head && head.children.length == 0) {
		// no header
		var hd = head.getEnclosingDiv();
		if (hd) {
			hd.style.display = 'none';
		}
		headH = 0;
	}
	else if (head) {
		var hd = head.getEnclosingDiv();
		if (hd) {
			var iesx = div.offsetWidth-5;
			iesx = (iesx < 5) ? 0 : iesx;
			hd.style.width = iesx + 'px';
			
			// + WAL105 -- check to see if we should hide the toolbar because the widget is maximized 
			var state = this.getState().split(':');
			var maximized = state[7];
			if (maximized==0 && this.showToolbarOnlyWhenMaximized) {
				hd.style.display = 'none';
				headH = 0;
			}
			else if (this.showToolbar) {
				hd.style.display = 'block';
				if (this.showToolbarBottomBorder) {
					hd.style.borderBottom = '';		// DTB171 - Expose default css styling
				}
				else {
					hd.style.borderBottom = 'none';	// DTB171 - Override default to hide border
				}
			}
			// - WAL105
		}
	}

	// sidebar
	var sideW = 0;
	var sidebarWidth = (this.sidebarWidth != '') ? this.sidebarWidth : '15%';		// DTB171 - Add default of 15% sidebar if it is shown with no width setting
	if (this.showSidebar) {
		if (sidebarWidth.toString().indexOf('%')!=-1) {
			var pct = parseFloat(sidebarWidth)/100;
			sideW = Math.floor(pct * div.offsetWidth);		// DTB171 - Make sure the percentage result is an integer
		}
		else {
			sideW = parseFloat(sidebarWidth);
		}
	}
	var adjW = 0;
	// JMD1128: shrink footer
	var adjH = 0;

	// adjust size of content frame
	var contentHgt = div.offsetHeight - headH - footH - adjH;
	contentHgt = (contentHgt < 0) ? 0 : contentHgt;

	if (sideDiv) {
		if (sideW <= 0) {
			sideDiv.style.display = 'none';
		}
		else {
			sideDiv.style.display = '';
			sideDiv.style.width = sideW + 'px';
			sideDiv.style.height = contentHgt + 'px';
			if (sideDiv.offsetHeight>contentHgt) {
				// DTB171 - Set the sidebar height to be the actual height of the rest of the content, accounting for padding
				var sideHgtDiff = sideDiv.offsetHeight - contentHgt;
				sideDiv.style.height = (contentHgt - sideHgtDiff) + 'px';
			}
			sideW = sideDiv.offsetWidth;
		}
	}
	var contentWid = div.offsetWidth - sideW - adjW;
	contentWid = (contentWid < 0) ? 0 : contentWid;
	
	this.adjustContentSize(load,contentWid,contentHgt);
}

/// Sets the "Modified" flag when a widget is dragged.
/// Called in the onwindowdrop callback.
ClientMethod setModifiedIfDragged() [ Language = javascript ]
{
	if (this.homeRow !== this.prevHomeRow || this.homeCol !== this.prevHomeCol) {
		zenPage.setModified(true);
	}
}

/// Stores previous values of homeRow and homeCol (widget coordinates).
/// Called in the onwindowgrab callback. 
ClientMethod initializeHomeRowCol() [ Language = javascript ]
{
	this.prevHomeRow = this.homeRow;
	this.prevHomeCol = this.homeCol;
}

/// Dynamically update Open/Hidden lists in the menu bar when a widget is closed/reopened.
ClientMethod updateMenuBar() [ Language = javascript ]
{
	zenPage.widgetSelected(event, "WidgetList");
	this.selectWidget(event || window.event);
	zenPage.getNavigator().expandHandler();
}

/// Hide a widget. Called in onclosepending callback of this widget. 
ClientMethod closeWidget() [ Language = javascript ]
{
	this.isClosed = true;
	if (this.maximized) {	
		this.normalize(event || window.event);
	}
	this.updateMenuBar();
	document.getElementById(this.id).style.display = "none";
}

/// Open a closed widget. Called in an onclick callback in <class>%ZEN.Component.navigator</class>.
ClientMethod openWidget() [ Language = javascript ]
{
	document.getElementById(this.id).style.display = "block";
	this.isClosed = false;
	this.updateMenuBar();
}

/// Called when page is loaded (<var>load</var> will be true) or the widget is resized.
/// This lets a subclass adjust the size of any components it has placed in
/// the contents area.
/// <var>width</var> and <var>height</var> contain the size of the content area.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
}

/// This method is called when a control event is sent to this widget.
/// A control event is raised by filter controls.<br/>
/// <var>text</var> is optional display value for <var>value</var>.
ClientMethod controlEventHandler(which, action, targetProp, value, text) [ Language = javascript ]
{
	if (zenPage.trace) {
		alert('Control event received by: '+this.name+'\n' + '\nWhich: '+ which + '\nAction: '+ action + '\nValue: ' + value);
	}

	var filterState = this.getFilterStateArray();
	var filterText = this.getFilterTextArray();

	switch(action) {
	case 'reloadDashboard':
		if (zenPage.reloadDashboard) {
			zenPage.reloadDashboard();
		}
		break;
	case 'refresh':
		this.applyFilters(true);
		break;
	case 'showListing':
		// targetProp is name of listing
		this.showListing(targetProp);
		break;
	case 'showGeoListing':
		// targetProp is name of listing
		this.showGeoListing(targetProp);
		break;
	case 'showDimensions':
		this.showDimensions();
		break;
	case 'clickFilter':
		// filter set by clicking on widget
		this.clickFilterSpec = value;
		this.applyFilters(true);
		break;
	case 'setFilter':
	case 'applyFilter':
		// apply filter value to filter state
		if ('' === targetProp) break;
		if (null == filterState[targetProp]) {
			// try a case-insensitive match
			var found = false;
			var tpu = targetProp.toString().toUpperCase();
			for (var x in filterState) {
				if (x.toString().toUpperCase() == tpu) {
					found = true;
					targetProp = x;
					break;
				}
			}
			if (!found) {
				break;
			}
		}

		filterState[targetProp] = value;
		filterText[targetProp] = text ? text : '';
		
		this.clickFilterSpec = '';		// DTB427 - Clear previous onclick filters

		// make sure all filter controls show the same value
		this.syncFilters(targetProp,value,text);

		if ('applyFilter' == action) {
			this.applyFilters(true);
			// pass on to master and slaves
			var master = this.getMasterWidget();
			if (master) {
				master.syncMaster(this);
				master.syncFilters(targetProp,value);
			}
			if (zenPage.getSlaveList) {
				var slaves = zenPage.getSlaveList(this);
				for (var n = 0; n < slaves.length; n++) {
					slaves[n].syncSlave(this,false);
					slaves[n].syncFilters(targetProp,value);
				}
			}
		}
		break;

	case 'applyVariable':
		// JMD1276: apply pivot variable value
		if (this.applyPivotVariable) {
			var varName = targetProp.toString().toLowerCase().split('$variable.')[1];
			this.applyPivotVariable(varName,value);
		}
		break;

	case 'setRowCount':
	case 'setRowSort':
	case 'setColumnCount':
	case 'setColumnSort':
		this.applySetting(action,value);
		break;
	case 'showBreakdown':
		this.showBreakdown(targetProp);
		break;

	case 'setDataSource':
		value = targetProp;
		// fall through
	case 'chooseDataSource':
		// JMD1139
		var dc = this.getDataController();
		if (value=='') {
			// restore default
			var widgetDef = this.getDefinition(this.widgetKey);
			value = widgetDef.dataSource;
		}

		if (this.dataSource!=value) {
			// DTB218 - Pass any overrides down to the server when changing the data source
			var overrides = this.getOverrides();
			var pivotOverrides = overrides['pivot'];
			var msg = zenPage.SetDataSource(this,dc,value,pivotOverrides);
			if (msg) {
				alert(msg);
			}
			this.applyFilters(true);
		}
		break;

		// !!!JMD
	case 'setRowSpec':
		value = targetProp;
		// fall through
	case 'chooseRowSpec':
		var dc = this.getDataController();
		if (dc._type == 'pivotTable') {
			dc.overrideRowSpec = value;
			dc.overrideRowText = text;
			
			if (dc.removeAllDrillLevels) {
				// DTB745 - Clear out drill down and reset to the newly selected level
				dc.removeAllDrillLevels();
			}

			this.applyFilters(true);
		}
		break;

	case 'setColumnSpec':
		value = targetProp;
		// fall through
	case 'chooseColumnSpec':
		var dc = this.getDataController();
		if (dc._type == 'pivotTable') {
			dc.overrideColumnSpec = value;
			dc.overrideColumnText = text;
			this.applyFilters(true);
		}
		break;

	// + WAL083
	case 'setChartType':
		// targetProp is the chart type the user associated with the control
		this.changeChartType(targetProp); 
		break;
	case 'chooseChartType':
		// in this case, tagetProp is a comma separated list; use the type the
		// user just selected from the list (value) 
		this.changeChartType(value); 
		break;
	// - WAL083
	case 'printWidget':
		// DTB251 - Call export PDF with parameters on every widget that has the method
		if (this.exportPDF) {
			if (value) {
				// DTB252 - Execute in multi-print mode to generate xsl only
				this.exportPDF(true,false);
			}
			else {
				this.exportPDF();
			}
		}
		break;
	default:
		// if not handled, pass back to Dashboard viewer.
		if (zenPage.actionHandler) {
			zenPage.actionHandler(this,this.dataSource,action);
		}
		break;
	}

	this.updateControlState();
}

/// Make sure all filter controls show the same value.<br/>
/// <var>text</var> is optional text value of the filter (used when server actions
/// drive the filter change!).
ClientMethod syncFilters(targetProp, value, text) [ Internal, Language = javascript ]
{
	var head = this.findComponent('header');
	var bind = 'filter' + "/" + targetProp;
	if (head) {
		for (var n = 0; n < head.children.length; n++) {
			var child = head.children[n];
			if (child && child.dataBinding && bind==child.dataBinding) {
				// zenPage._sourceControl fired the event
				if ((zenPage._sourceControl==null)||(zenPage._sourceControl != child)) {
					child.setValue(value);
					if (child.setTextValue && zenPage._sourceControl && zenPage._sourceControl.text) {
						// brute force method!
						child.setTextValue(zenPage._sourceControl.text);
					}
					else if (child.setTextValue && typeof text != 'undefined') {
						child.setTextValue(text);
					}
				}
			}
		}
	}
}

/// This method is called an event on this widget (such as click on a chart series)
/// occurs and it needs to be dispatched.
ClientMethod raiseEventHandler(action) [ Language = javascript ]
{
	if (zenPage.trace) {
		alert('Widget raised event: '+this.name+'\n' + '\nAction: '+ action + '\nValue: ' + this.currValue + "\nFilter: " + this.currFilterSpec);
	}

	// send event to each target in the list
	if (zenPage.dashboardEventHandler) {
		for (var n = 0; n < this.clickTargets.length; n++) {
			var target = this.clickTargets[n];
			var taction = this.clickActions[n];
			var tprop = this.clickTargetProperties[n];
			var tactiveWhen = this.clickActive[n];		// DTB584

			// default target is *this* widget
			if (target == '') {
				target = this.name;
			}

			switch(taction) {
			case 'setFilter':
			case 'applyFilter':
				taction = 'clickFilter';
				break;
			}
			if ((("itemSelected"==tactiveWhen) && (""!=this.currValue)) || (""==tactiveWhen)) {
				// DTB584 - Execute this conditionally
				var ok = zenPage.dashboardEventHandler(this,'click',this.currFilterSpec,taction,target,tprop);
			}
			
			if (!ok) {
				break;
			}
		}
	}
}

/// Perform a showListing action, if supported.
ClientMethod showListing(listing) [ Language = javascript ]
{
}

/// Perform a showGeoListing action, if supported.
ClientMethod showGeoListing(listing) [ Language = javascript ]
{
}

/// Perform a showDimensions action, if supported.
ClientMethod showDimensions() [ Language = javascript ]
{
}

/// Perform a showBreakdown action, if supported.
ClientMethod showBreakdown(analysisClass) [ Language = javascript ]
{
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return null;
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ""
}

/// Apply the given setting value to this widget.
/// For example, this is used to set the row count for a pivot.
ClientMethod applySetting(action, value) [ Internal, Language = javascript ]
{
}

/// Apply the current filters to this widget.
ClientMethod applyFilters(refresh) [ Internal, Language = javascript ]
{
	var dc = this.getDataController();
	if (null == dc) return;
	
	// JMD1210: guard against closed widget
	if (!this.getEnclosingDiv()) return;

	if (dc._type == 'pivotTable') {
		// pivot case
		var pivot = dc;
		if (!pivot) return;

		// clear any "run-time" pivot filters
		// leave original filter alone
		// go in reverse since we are deleting
		for (var f = pivot.filters.length - 1; f >= 0 ; f--) {
			if (pivot.filters[f].transient) {
				pivot.filters.splice(f,1);
			}
		}

		// apply click-filter
		if (this.clickFilterSpec) {
			if ('$$$CLEAR'==this.clickFilterSpec) {
				// DTB648 - The user has cleared the selection
				this.clickFilterSpec = '';
				pivot.contextFilterSpec = '';
			}
			else {
				pivot.contextFilterSpec = this.clickFilterSpec;
			}
		}

		var n = 0;
		var filterState = this.getFilterStateArray();
		var filterText = this.getFilterTextArray();

		for (var f in filterState) {
			var isAdvanced = true;
			var value = filterState[f];
			var text = filterText[f] ? filterText[f] : value;
			if (''!=dc.kpi) {
				var spec = f;
			}
			else {
				// DP-420389 - Create an exectuable MDX filter clause using the filter's level spec and the value. If the returned spec is identical to the original value,
				// mark this as an advanced filter.
				var spec = this.constructMDXClause(f,value);
				isAdvanced = (spec == value);
			}
			if ('' !== spec) {
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				parm.transient = true; // mark that we added this filter
				parm.advanced = isAdvanced; // mark as advanced so that we can use complex spec!
				parm.spec = (isAdvanced ? spec : f + '.Members');		// DP-420389
				parm.value = value;
				parm.text = text;
				parm.key = value;
				parm.caption = '';	// this gets filled in by pivotTable
				parm.baseSpec = f;
				pivot.filters[pivot.filters.length] = parm;
			}
		}
		if (refresh) {
			// JMD993: force regeneration of listing; don't end listing mode
			if (pivot.isDrillThrough) {
				pivot.mdx = '';
			}
			// change of filter ends listing mode
			// pivot.setDrillThrough(false);
			pivot.selectedRange = '';
			pivot.executeQuery(true);
		}
	}
	else {
		// data controller
		var filterState = this.getFilterStateArray();
		var filterText = this.getFilterTextArray();

		var proxy = new zenProxy();
		for (var f in filterState) {
			var value = filterState[f];
			if ('' !== value) {
				proxy[f] = value;
			}
		}
		dc.criteria = proxy;
		dc.update();
	}
	this.onApplyFilters(refresh);
}

/// Notification to subclasses that filter has changed.
ClientMethod onApplyFilters(refresh) [ Internal, Language = javascript ]
{
}

/// Get the array of filter state information.
Method %GetFilterStateArray() As %ListOfObjects [ Internal ]
{
	If ((..linkWidgetKey'="")&&(..linkWidgetKey'=..widgetKey)) {
		// if linked, get master filter state
		Set tMaster = $G(%tKeyToWidget(..linkWidgetKey))
		If $IsObject(tMaster) {
			Quit tMaster.%GetFilterStateArray()
		}
	}
	Quit ..filterState
}

/// Get the array of filter text information.
Method %GetFilterTextArray() As %ListOfObjects [ Internal ]
{
	If ((..linkWidgetKey'="")&&(..linkWidgetKey'=..widgetKey)) {
		// if linked, get master filter text
		Set tMaster = $G(%tKeyToWidget(..linkWidgetKey))
		If $IsObject(tMaster) {
			Quit tMaster.%GetFilterTextArray()
		}
	}
	Quit ..filterText
}

/// Get the array of filter default information.
Method %GetFilterDefaultArray() As %ListOfObjects [ Internal ]
{
	If ((..linkWidgetKey'="")&&(..linkWidgetKey'=..widgetKey)) {
		// if linked, get master filter value
		Set tMaster = $G(%tKeyToWidget(..linkWidgetKey))
		If $IsObject(tMaster) {
			Quit tMaster.%GetFilterDefaultArray()
		}
	}
	Quit ..filterDefault
}

/// Apply the current filters to the widget.
/// This is called when the page is first rendered to set the current filter values.
/// It is called by the %CreateWidgets method of the DashboardViewer.
Method %ApplyFilters() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// + WAL092 -- Special case for portlets:
		//             If this portlet loads with a filter state, meaning that it has
		//             A default filter or a URL filter, set ..hasInitialFilters
		//             This causes onloadHandler to fire the portlets onAppyFilters
		//             method, giving the portlet a chance to render the filtered data
        // + WAL121 & PFS -- make sure to check all filters to see if they have values, 
        //                   not just the first one
        If (..%IsA("%DeepSee.Component.Widget.portlet")) { 
            Do { 
                Set tInitialFilter=..%GetFilterStateArray().GetNext(.tKey) 
                Set:tInitialFilter'="" ..hasInitialFilters=1 
            } While tKey'="" 
            Quit 
        }
        // - WAL121 & PFS
		// - WAL092
		
		Set tDC = ..%GetDataController()
		If '$IsObject(tDC) Quit

		If (tDC.%IsA("%DeepSee.Component.pivotTable")) {
			Set tFilterState = ..%GetFilterStateArray()
			Set tFilterText = ..%GetFilterTextArray()

			// DTB551 - Do this in the pivotTable case as well
			Do { 
                Set tInitialFilter=..%GetFilterStateArray().GetNext(.tKey) 
                Set:tInitialFilter'="" ..hasInitialFilters=1 
            } While tKey'=""

			// apply click-filter
			// (this is most likely a general filter being passed in via the URL)
			Set tDC.contextFilterSpec = ..clickFilterSpec

			// create transient filters for saved filters
			Set tFSpec = ""
			Set tFValue = tFilterState.GetNext(.tFSpec)
			If (tFSpec'="") {
				Set tFText = tFilterText.GetAt(tFSpec)
			}
			Else {
				Set tFText = ""
			}

			// if there is a dashboard setting value for this filter (user-based)
			// it overrides the saved filter (and will be in filterState)

			While (tFSpec '= "") {
				If (tFValue'="") {
					Set tFilter = ##class(%DeepSee.Component.pivotLevel).%New()
					Set tFilter.advanced = 1
					Set tFilter.transient = 1
					If (tDC.kpi'="") {
						// data source is a KPI
						Set tFilter.spec = tFSpec
						Set tFilter.value = tFValue

						// set filter text value as well
						Set tFilter.text = tFText
					}
					Else {
						// spec for advanced filter includes key
						// we have to process the key and deal with {} and %NOT
						Set tActualSpec = ""
						Set tIsNot = 0
						Set xf = tFValue
						If ($E(tFValue,1,4)="%NOT") {
							Set tIsNot = 1
							Set xf = $ZSTRIP($E(tFValue,5,$L(tFValue)),"<>W")
						}

						If ($E(xf,1,8)["%SEARCH.") {
							// filter on measure
							Set tActualSpec = xf
						}
						ElseIf ($E(xf,1)="{") {
							Set xf = $E(xf,2,$L(xf)-1)
							// WAL096 -- Names with commas broke because we parse by comma. Fixed this
							//           by checking each comma found to see if it is preceded
							//           by a ']' which is not preceded by a ']'.
							//           That condition means that the comma followed an unescaped closing
							//           bracket and is therefore used syntactically rather than as part of the name.
							Set tPartialSpec = ""
							For n = 1:1:$L(xf,",") {
								Set tThisPiece=$P(xf,",",n)
								Set tLastChar = $E(tThisPiece,*)
								Set tNextToLastChar = $E(tThisPiece,*-1)
								If ((tLastChar = "]") && (tNextToLastChar '= "]")) {
									If ($G(tPartialSpec)'="") {
										// replace comma that was removed during parsing
										Set tFilterValue = tPartialSpec _ "," _ tThisPiece
										Set tPartialSpec = ""	
									}
									Else {
										Set tFilterValue = tThisPiece
									}
									// + WAL034 -- add %NOT to each member name if we are excluding items
									Set tActualSpec = tActualSpec _ $S(tActualSpec="":"",1:",") _ tFSpec_"."_tFilterValue _ $S(tIsNot:".%NOT",1:"")
									// - WAL034
								}
								Else {
									// accumulate, don't apply yet -- replace comma that was removed during parsing
									Set tPartialSpec = tPartialSpec _ $S($G(tPartialSpec)'="":",",1:"") _ tThisPiece		// DTB510 - Include previous partial spec
								}
							}
							// - WAL096
							If (tIsNot) {
								// WAL034 -- make a tuple of %NOT members if we are excluding multiple items
								Set tActualSpec = "("_ tActualSpec _ ")"
								// - WAL034
							}
							Else {
								// JMD1075 wrap with %OR
								Set tActualSpec = "%OR({"_tActualSpec_"})"
							}
						}
						ElseIf (xf["]:&[") {
							// JMD1321: wrap range with %OR
							Set tActualSpec = "%OR("_tFSpec_"."_tFValue_")"
						}
						ElseIf (tIsNot) {
							// JMD1075 Use %NOT
							Set tActualSpec = tFSpec_"."_xf_".%NOT"
						}
						Else {
							Set tActualSpec = tFSpec_"."_tFValue
						}
						Set tFilter.spec = tActualSpec

						// set key/caption/text to ensure tooltip will work
						Set tFilter.key = tFValue
						Set tFilter.caption = ##class(%DeepSee.Component.pivotTable).GetItemCaption(tDC.cubeName,tFilter.spec)
						Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(tDC.cubeName,tFSpec,tFValue,.tText)
						Set tFilter.text = tText
					}
					Do tDC.filters.Insert(tFilter)
					Do %page.%AddComponent(tFilter)
				}
				Set tFValue = tFilterState.GetNext(.tFSpec)
				If (tFSpec'="") {
					Set tFText = tFilterText.GetAt(tFSpec)
				}
				Else {
					Set tFText = ""
				}
			}
		}
		Else {
			// non-pivot
			Set tFilterState = ..%GetFilterStateArray()

			// see if there are any filters in play
			Set tFilterCount = 0

			// create transient filters for saved filters
			Set tFSpec = ""
			Set tFValue = tFilterState.GetNext(.tFSpec)
			While (tFSpec '= "") {
				If (tFValue'="") {
					Set tFilterCount = tFilterCount + 1 
				}
				Set tFValue = tFilterState.GetNext(.tFSpec)
			}
			If (tFilterCount>0) {
				Set tDC.dataLoaded = 1
				Set ..hasInitialFilters = 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the current state of filters for this widget as one serialized string.
ClientMethod getFilterState(delim1, delim2) [ Internal, Language = javascript ]
{
	// use tab and cr as default delims!
	delim1 = ('undefined'==typeof delim1) ? '\t' : delim1;
	delim2 = ('undefined'==typeof delim2) ? '\n' : delim2;

	var filterState = this.getFilterStateArray();

	var state = '';
	for (var f in filterState) {
		var value = filterState[f];
		state += f + delim1 + value + delim2;
	}
	return state;
}

/// Set the current state of filters from a serialized string.
ClientMethod setFilterState(state) [ Internal, Language = javascript ]
{
	// use tab and cr as default delims!
	delim1 = '\t';
	delim2 = '\n';

	// test if we are a slave widget
	var widget = this.getMasterWidget();
	if (widget && widget === this) {
		return;
	}

	var filterState = this.getFilterStateArray();

	// clear old state
	for (var p in filterState) {
		delete filterState[p];
	}

	var t = state.toString().split(delim2);
	for (var n = 0; n < t.length; n++) {
		var p = t[n].toString().split(delim1);
		if (p[0]) {
			filterState[p[0]] = p[1];
		}
	}
}

/// Given an MDX member expression and key value expression, return a clause that
/// can be used as a filter spec.
ClientMethod constructMDXClause(filter, value) [ Internal, Language = javascript ]
{
	var spec = '';

	if ('' !== value) {
		// guess what type of value we have
		// this *could* do a more complete parse

		// JMD1253: test for named filter
		if (filter=='$NAMEDFILTER') {
			return value;
		}		

		if (value.substr(0,8).toUpperCase()=='%SEARCH.') {
			// searchable measure expression
			return value;
		}

		var isnot = false;
		if (value.substr(0,5)=='%NOT ') {
			// special NOT operator;
			value = value.substr(5);
			isnot = true;
		}

		// JMD1002
		var isrange = value.indexOf(']:&[')>0;
		if (isrange) {
			spec = '%OR(' + filter + '.' + value + ')';
		}
		else if (value.charAt(0)=='&' && value.charAt(value.length-1) == ']') {
			// single value
			if (isnot) {
				// JMD1002
				spec = filter + '.' + value + '.%NOT';
			}
			else {
				spec = filter + '.' + value;
			}
		}
		else if (value.charAt(0)=='{' && value.charAt(value.length-1) == '}') {
			// set of values
			// JMD1002
			// + WAL034	-- for %NOT, start tuple	
			spec = isnot ? '(' : '%OR({';
			// - WAL034
			// strip off {}
			value = value.substr(1,value.length-2);
			var t = value.split('],&['); // !!!
			for (var i=0;i<t.length;i++) {
				var m = t[i];
				if ( i>0 ) {
					// DP-408166 - Prepend the 2nd to Nth keys with the '&[' key opening token which has been 
					// parsed out by the split.
					m = '&[' + m;
				}
				if (i<(t.length-1)) {
					// DP-408166 - Append the 1st to (N-1)th keys with the ']' key closing token which has been 
					// parsed out by the split.
					m = m + ']';
				}
				// + WAL034
				if (isnot) {
					spec = spec + ((i>0)?',':'') + filter + '.' + m + '.%NOT';
				}
				else {
					spec = spec + ((i>0)?',':'') + filter + '.' + m;
				}
				// - WAL034
			}
			if (isnot) {
				// + WAL034 -- Close tuple
				spec = spec + ')';
				// - WAL034
			}
			else {
				spec = spec + '})';
			}
		}
	}
	return spec;
}

/// Update the display current controls for this widget.
/// Implemented by subclasses.
ClientMethod updateControlState() [ Internal, Language = javascript ]
{
	// default: disable listing button
	for (var n = 0; n < this.controlIndices.length; n++) {
		var control = zenPage.getComponent(this.controlIndices[n]);
		if (control && control.name == 'showListing') {
			control.setDisabled(true);
		}
	}
}

/// Perform a local drill down for a target widget.
ClientMethod executeDrillDown(dataSource) [ Internal, Language = javascript ]
{
}

/// Find the value of the given parameter value.
ClientMethod getParameterValue(parm) [ Internal, Language = javascript ]
{
	var value = '';
	switch(parm) {
	case 'CURRVALUE':
		// current value (selected item)
		value = this.currValue;
		break;
	case 'VALUELIST':
		// list of values for selected rows
		value = this.currValue;
		break;
	case 'ROWSPEC':
		// MDX spec for current pivot row
		break;
	case 'COLUMNSPEC':
		// MDX spec for current pivot column
		break;
	case 'FILTERS':
		// current value of filters (as one string)
		// + WAL069 -- use default delimiters
		value = encodeURIComponent(this.getFilterState());
		// - WAL069
		break;
	}
	return value;
}

/// Get array of "dashboard" settings for this widget.
Method %GetWidgetSettings(ByRef pSettings As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pSettings

		// walk over list of controls for this widget
		// and get current values
		For n=1:1:..controlIndices.Count() {
			Set tControl = %page.%GetComponent(..controlIndices.GetAt(n))
			If ($IsObject(tControl)&&'tControl.%IsA("%ZEN.Component.button")&&'tControl.%IsA("%ZEN.Component.timer")) {
				If (tControl.aux'="") {
					// use controlKey (aux)
					// + WAL097 & PFS -- save the control value even if its empty
					//                   this is used in save my settings, so if the user clears a control
					//                   this should be saveable
					//                   This method is currently only called from DashboardViewer::%GetDashboardSettings
					//Set:tControl.value'="" pSettings("controls",tControl.aux,"value") = tControl.value
					Set pSettings("controls",tControl.aux,"value") = tControl.value
					// - WAL097
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// If this is a slave to another widget, return the master.
/// Otherwise return null.
ClientMethod getMasterWidget() [ Internal, Language = javascript ]
{
	if (zenPage.findWidgetByKey && this.linkWidgetKey!='') {
		return zenPage.findWidgetByKey(this.linkWidgetKey);
	}
	return null;
}

/// Get the array of filter state information for this widget.
ClientMethod getFilterStateArray() [ Internal, Language = javascript ]
{
	// if linked, dispatch
	var widget = this.getMasterWidget();
	if (widget && widget !== this) {
		return widget.getFilterStateArray();
	}
	return this.filterState;
}

/// Get the array of filter text information for this widget.
ClientMethod getFilterTextArray() [ Internal, Language = javascript ]
{
	// if linked, dispatch
	var widget = this.getMasterWidget();
	if (widget && widget !== this) {
		return widget.getFilterTextArray();
	}
	return this.filterText;
}

/// Called on a master widget from a slave when the data source or filters are changed.
ClientMethod syncMaster(slave) [ Internal, Language = javascript ]
{
	this.applyFilters(true);

	// pass on to other slaves
	if (zenPage.getSlaveList) {
		var slaves = zenPage.getSlaveList(this);
		for (var n = 0; n < slaves.length; n++) {
			if (slave !== slaves[n]) {
				slaves[n].syncSlave(this,false);
			}
		}
	}
}

/// Called on a slave widget from a master when data source or filters are changed.
ClientMethod syncSlave(master, dataChange) [ Internal, Language = javascript ]
{
	if (dataChange) {
		this.syncSlaveData(master);
	}
	else {
		this.applyFilters(true);
	}

	// pass on to slaves of this slave
	// not currently supported
	/*
	if (zenPage.getSlaveList) {
		var slaves = zenPage.getSlaveList(this);
		for (var n = 0; n < slaves.length; n++) {
			slaves[n].syncSlave(this,dataChange);
		}
	}
	*/
}

/// Called on a slave widget from a master when its data source is changed.
ClientMethod syncSlaveData(master) [ Internal, Language = javascript ]
{
	// + WAL089 -- moved from %DeepSee.Component.Widget.pivot on Dmitry Z.'s suggestion
	//             so that other widget types, like portlets, will update
	var masterDC = master.getDataController();
	var slaveDC = this.getDataController();
	if (masterDC && slaveDC && slaveDC.copyState) {
		slaveDC.copyState(masterDC);
		this.applyFilters(true);
	}
	// - WAL089
}

/// Intercept call to make sure all widgets get resize event!
ClientMethod normalize(event) [ Internal, Language = javascript ]
{
	this.invokeSuper('normalize',arguments);
	// JMD859
	if (zenPage.invokeAdjustSizes) {
		zenPage.invokeAdjustSizes(this);
	}
}

/// Set the style of this widget to indicate that it is selected.
ClientMethod setHighlight(flag) [ Internal, Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) {
		// widget is closed
		return;
	}
	var header = this.findElement('header');
	if (flag) {
		var prefix = '';
		var who=navigator.userAgent;
		if (who.indexOf("WebKit")>=0) {
			prefix = '-webkit-';
		}
		else if (who.indexOf("Firefox")>=0) {
			prefix = '-moz-';
		}
		
		// + WAL101
		var titleBarColor;
		var titleBarOpacity;
		var textColor;
		if (zenPage.selectedTitleBarColor) {
			titleBarColor = zenPage.selectedTitleBarColor;
		}
		else {
			titleBarColor = 'rgb(53,107,141)';
		}
		// 0 is a value we need to consider
		if (zenPage.selectedTitleBarOpacity || (parseInt(zenPage.selectedTitleBarOpacity)==0)) {
			titleBarOpacity = zenPage.selectedTitleBarOpacity;
		}
		else {
			titleBarOpacity = 1;	
		}
		if (zenPage.selectedTitleBarTextColor) {
			textColor = zenPage.selectedTitleBarTextColor;
		}
		else {
			textColor = 'white';
		}
		var rgba = ZLM.convertColorToRGBA(titleBarColor, titleBarOpacity);
		header.style.background = 'rgba('+rgba+')';
		header.style.color = textColor;
		// - WAL101
		//if (prefix) {
		//	header.style.backgroundImage = prefix + 'linear-gradient(top,  rgb(53,107,141) 0%,rgb(53,107,161) 45%,rgb(53,107,161) 55%,rgb(53,107,141) 100%)';
		//}
		div.style.border = '2px solid ' + 'rgba('+rgba+')';
	}
	else {
		// + WAL101 -- handle unselecting the widget
		zenPage.setTitleBarColorAndOpacity();
		if (zenPage.widgetBordersToggle) {		// DTB171 - Check the page setting when deselecting a widget
			div.style.border = '';				// DTB171 - Expose default css styling
		}
		else {
			div.style.border = 'none';			// DTB171 - Override default border to remove it
		}
		// - WAL101
	}
	this.onSetHighlight(flag);
}

/// Notification that this widget is selected / unselected.
ClientMethod onSetHighlight(flag) [ Internal, Language = javascript ]
{
}

/// Hide/show the drag header for this widget.
ClientMethod showDragHeader(flag) [ Internal, Language = javascript ]
{
	var header = this.findElement('header');
	if (flag) {
		this.resetWindowChrome();
		if (!zenPage.dashboardResize) this.disableResize();
	}
	else {
		this.removeWindowChrome();
		if (zenPage.dashboardResize) this.enableResize();
	}
}

/// Hide/show the toolbar for this widget.
ClientMethod hideToolbar(flag) [ Internal, Language = javascript ]
{
	var head = this.findComponent('header');
	if (head) {
		var div = head.getEnclosingDiv();
		if (div) {
			if (this.showToolbar != !flag) {
				this.showToolbar = !flag;
				if (this.showToolbar) {
					div.style.display = 'block';
					if (this.showToolbarBottomBorder) {
						div.style.borderBottom = '';		// DTB171 - Expose default css styling
					}
					else {
						div.style.borderBottom = 'none';	// DTB171 - Override default to hide border
					}
				}
				else {
					div.style.display = 'none';
				}
				this.adjustSizes();
			}
		}
	}
}

/// Select this widget.
ClientMethod selectWidget(evt) [ Language = javascript ]
{
	if (zenPage.widgetSelected) {
		evt = evt ? evt : window.event;
		zenPage.widgetSelected(evt,this.widgetKey);
	}
}

/// Return an object describing what to display for this level within the navigator.
/// Invoked from dashboard viewer.
ClientMethod navGetContentForLevel(level, key, value) [ Internal, Language = javascript ]
{
	var content = { title: key, items:[] };
	// key may take the form key:no
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// key may take the form key/type
	var keyType = '';
	if (key.toString().indexOf('/')>0) {
		var t = key.split('/');
		key = t[0];
		keyType = t[1];
	}

	// special handling for widget settings drill downs
	var navigator = zenPage.getNavigator();
	switch (keyType) {
	case 'ColorSVG':
		// choose a color
		content.title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'svg');
		return content;
	case 'Format':
		// choose a format
		content.title = $$$Text('Numeric Format','%DeepSee');
		var list = [
			{ caption:$$$Text('###','%DeepSee'), value:'###'},
			{ caption:$$$Text('###.#','%DeepSee'), value:'###.#'},
			{ caption:$$$Text('###.##','%DeepSee'), value:'###.##'},
			{ caption:$$$Text('###.###','%DeepSee'), value:'###.###'},
			{ caption:$$$Text('#,##','%DeepSee'), value:'#,##'},
			{ caption:$$$Text('#,##.#','%DeepSee'), value:'#,##.#'},
			{ caption:$$$Text('#,##.##','%DeepSee'), value:'#,##.##'},
			{ caption:$$$Text('#,##.###','%DeepSee'), value:'#,##.###'},
			{ caption:$$$Text('##.##%','%DeepSee'), value:'##.##%'},
		];
		content.html = navigator.getChooserListHTML(list,key,value,$$$Text('Format','%DeepSee'),$$$Text('Choose a numeric format','%DeepSee'));
		return content;
	//case 'Opacity': // JSL4483
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:zenGet(this.opacity), key:'widget-common-opacity', minValue:0, maxValue:1};
		//return content;
	}

	switch (key) {
	case 'WidgetSettings':
		// common settings
		content.title = $$$Text('Widget','%DeepSee');
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Reset Styles','%DeepSee'), action:'select', key:'widget-common-reset', help:$$$Text('Reset the style of this widget','%DeepSee'), disabled:!this.hasOverrides()};

		var widgetType = '';
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);

		if (widgetDef) {
			content.items[content.items.length] = {display:'section', caption:$$$Text('General Settings','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Name','%DeepSee'), edit:'string', value:zenGet(widgetDef.name),	key:'widget-common-name'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), edit:'string', value:zenGet(widgetDef.title),	key:'widget-common-title'};
			var swvalue = zenGet(widgetDef.showToolbar)==true ? $$$Text('On','%DeepSee') : $$$Text('Off','%DeepSee');
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Toolbar','%DeepSee'), action:'drill',	key:'widget-common-toolbar', value:swvalue }; // JSL4483 - change to drill

			// +DTB122 - drill to sidebar settings
			var showSidebarValue = (true==zenGet(widgetDef.showSidebar)) ? $$$Text('On','%DeepSee') : $$$Text('Off','%DeepSee');
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Sidebar','%DeepSee'), action:'drill',	key:'widget-common-sidebar', value:showSidebarValue }; 
			// -DTB122

			content.items[content.items.length] = {display:'image-caption', caption:$$$Text('Type & Data Source','%DeepSee'), image:'deepsee/ds2_gear_44.png', action:'drill', key:'widget-common-typeAndData'};

			content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_equalizer_44.png', caption:$$$Text('Widget Settings','%DeepSee'), action:'drill', key:'widget-common-settings'};

			content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_wrench2_44.png', caption:$$$Text('Controls','%DeepSee'), action:'drill', key:'widget-common-controls', help:$$$Text('Add controls and filters to this widget','%DeepSee')};

			// only show for select widgets
			switch (this._type) {
			case 'pivot':
			case 'meter':
			case 'map':
				content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_target_44.png', caption:$$$Text('Data Properties','%DeepSee'), action:'drill', key:'widget-common-dataProperties', help:$$$Text('Add data properties to this widget','%DeepSee')};
				break;
			}
		}
		break;

	case 'widget-common-toolbar':
		// JSL4483
		content.title =  $$$Text('Toolbar Settings','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var forceToolbar = false;

		if (zenGet(widgetDef.type)=="controlPanel") forceToolbar = true;

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Toolbar','%DeepSee'), edit:'switch', value:zenGet(widgetDef.showToolbar),	key:'widget-common-showToolbar', disabled:forceToolbar };

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Bottom Border','%DeepSee'), edit:'switch', value:zenGet(widgetDef.showToolbarBottomBorder),	key:'widget-common-showToolbarBottomBorder'};		// DTB171
		// + WAL105 -- showToolbarOnlyWhenMaximized Setting
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Maximized','%DeepSee'), help:$$$Text('If on, only display toolbar when widget is maximized'), edit:'switch', value:zenGet(widgetDef.showToolbarOnlyWhenMaximized),	key:'widget-common-showToolbarOnlyWhenMaximized'};
		// - WAL105
		var fillColor = navigator.transformColor(zenGet(this.colorToolbar)!="" ? this.colorToolbar : "#F0F0F0");			
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Toolbar Color','%DeepSee'), action:'drill',  key:'widget-common-colorToolbar', help:$$$Text('Specify color of toolbar','%DeepSee'), valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'}; // JSL4479
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Toolbar Opacity','%DeepSee'), edit:'slider', value:zenGet(this.opacityToolbar),	key:'widget-common-opacityToolbar', minValue:0, maxValue:1};
		break;
		
 	case 'widget-common-sidebar':		// DTB122 - add case to show the actual sidebar options
 		content.title = $$$Text('Sidebar Settings','%DeepSee');
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Sidebar','%DeepSee'), edit:'switch', value:this.showSidebar,key:'widget-common-showSidebar'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Sidebar Content','%DeepSee'), edit:'string', value:this.sidebarContent,key:'widget-common-sidebarContent'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Sidebar Width','%DeepSee'), edit:'string', value:this.sidebarWidth,key:'widget-common-sidebarWidth'};
 		break;
 		
	case 'widget-common-colorToolbar':
		// JSL4483
		content.title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value);
	case 'widget-common-theme':
		// get list of themes
		content.title = $$$Text('Themes','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var theme = '';
		if (widgetDef) {
			theme = widgetDef.theme;
		}

		var options = zenPage.fetchOptionList('widget-themes','');
		var list = options.children;
		
		content.items[content.items.length] = {display:'info', caption:$$$Text('Theme','%DeepSee'), value:$$$Text('The Theme provides the base styles for this widget','%DeepSee')};

		// show list of options
		for (var n = 0; n < list.length; n++) {
			var ivalue = zenGet(list[n].value);
			var caption = list[n].caption ? list[n].caption : ivalue;
			var style = ivalue==''?'font-style:italic;':'';
			content.items[content.items.length] = {display:'value', selected:theme==ivalue, key:key+':'+ivalue, value:ivalue, action:'apply', text:caption, style:style, closeButton:(ivalue!='')};
		}
		break;

	case 'widget-common-typeAndData':
		content.title = $$$Text('Type and Data','%DeepSee');
		var widgetType = '';
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			widgetSubtype = widgetDef.subtype;
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget Type','%DeepSee'), value:widgetSubtype, action:'drill', key:'widget-common-widgetSubtype', help:$$$Text('Set the type of this widget','%DeepSee')};

		var sname = zenGet(widgetDef.dataSource).toString();
		sname = sname.split('/');
		sname = sname[sname.length-1];
		sname = sname.split('.')[0];
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Data Source','%DeepSee'), edit:'string', value:zenGet(widgetDef.dataSource), text:sname, title:zenGet(widgetDef.dataSource), action:'popup', key:'widget-common-dataSource', help:$$$Text('Set the data source for this widget','%DeepSee'), url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=datasources', disabled:(zenGet(widgetDef.dataLink)?true:false)};

		// Reset local data source
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Reset Data Source','%DeepSee'), action:'select', key:'widget-common-resetDataSource', help:$$$Text('Clear any local changes to the data source','%DeepSee'), disabled:(zenGet(widgetDef.localDataSource)=='')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Link to','%DeepSee'), value:zenGet(widgetDef.dataLink), action:'drill', key:'widget-common-dataLink', help:$$$Text('Use same data source as another widget on the dashboard','%DeepSee')};

		var sname = zenGet(widgetDef.drillDownDataSource).toString();
		sname = sname.split('/');
		sname = sname[sname.length-1];
		sname = sname.split('.')[0];
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Drilldown Target','%DeepSee'), edit:'string', value:zenGet(widgetDef.drillDownDataSource),text:sname,title:zenGet(widgetDef.drillDownDataSource), action:'popup', key:'widget-common-drillDownDataSource', help:$$$Text('Dashboard to display when drilling into this widget','%DeepSee'), url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget Theme','%DeepSee'), value:zenGet(widgetDef.theme), action:'drill', key:'widget-common-theme', help:$$$Text('Theme that supplies the base styles for this widget','%DeepSee'), text:zenGet(widgetDef.theme).split('.')[0]};
		break;

	case 'widget-common-dataLink':
		// list of widget names to link to
		content.title = $$$Text('Widgets','%DeepSee');
		var model = zenPage.getDefinition();
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var list = [];
		list[list.length] = { caption:$$$Text('None','%DeepSee'), value:''};

		if (model) {
			for (var n = 0; n < model.widgets.length; n++) {
				if (widgetDef.name != model.widgets[n].name && model.widgets[n].name!=='') {
					list[list.length] = { value:model.widgets[n].name};
				}
			}
		}
		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(widgetDef.dataLink),$$$Text('Link To','%DeepSee'),$$$Text('Choose a widget to link to','%DeepSee'));
		break;

	case 'widget-common-widgetSubtype':
		// list of widget sub-types (from JSON)
		content.title = $$$Text('Widget Type','%DeepSee');

		var widgetType = '';
		var widgetSubtype = '';
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			widgetType = widgetDef.type;
			widgetSubtype = widgetDef.subtype;
		}

		// show subtypes for the current widget
		var types = zenPage.getWidgetTypes();
		if (types && types.children) {
			for (var n = 0; n < types.children.length; n++) {
				var type = types.children[n];
				if (type.name == widgetType) {
					if (type.children) {
						content.items[content.items.length] = {display:'section', caption:type.title };
						for (var j = 0; j < type.children.length; j++) {
							var subtype = type.children[j];
							content.items[content.items.length] = {display:'image-caption', image:subtype.image, caption:subtype.title, value:subtype.name, action:'select', key:key};
						}
					}
					else {
						// add fake section header for single item
						content.items[content.items.length] = {display:'section', caption:type.title };
						content.items[content.items.length] = {display:'image-caption', image:type.image, caption:types.children[n].title, value:type.name, action:'select', key:key};
					}
				}
			}
		}
		break;

	case 'widget-common-settings':
		// list of widget settings
		content.title = $$$Text('Widget Settings','%DeepSee');

		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
	
		// DTB111 - for portlet, read current properties and pass them to the json parameters
		var widgetProperties = [];
		if (widgetDef.type=='portlet') {
			widgetProperties = widgetDef.properties;
		}

		// get list
		var options = zenPage.fetchOptionList('widget-settings',widgetDef.type+":"+widgetDef.subtype,widgetProperties);
		if (options && options.children && options.children.length) {
			var list = options.children;
			// translate list to navigator items
			for (var n = 0; n < list.length; n++) {
				var setting = list[n];
				if (!setting.hidden) {
					var value = zenGet(widgetDef.properties[setting.value],setting.defValue);
					var type = setting.type.toString().split('^')[0];

					var edit = '';
					var action = '';
					var vlist = '';
					var dlist = '';
					var text = value;
					var valueStyle = '';
					var special = '';
					var minValue = null;
					var maxValue = null;
					var navKey = null;
					
					switch(type) {
					case '%Boolean':
						edit = 'switch';
						value = (value&&value!=='0') ? true : false;
						text = value;
						break;
					case 'ColorSVG':
						action = 'drill';
						// tack on type so that we can handle the drill down
						special = '/ColorSVG';
						text = '';
						valueStyle = 'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+value+';'
						break;
					case 'Format':
						action = 'drill';
						special = '/Format';
						edit = 'string';
						break;
					case 'Opacity':
						edit = 'slider';
						minValue = 0.0;
						maxValue = 1.0;
						break;
					// + WAL095 -- In case we are going to render a drill list
					//             of user provided options for portlet settings
					//             If navKey has keyNo AND special, special goes first
					//             This is used when the list is too long for an ENUM
					//             and only at the user's request (via %OnGetPortletSettings)
					case 'DRILL': 
						action = 'drill';
						special = '/'+setting.value;
						text = this.getSettingDisplayValue(setting,value);
						navKey = 'widget-common-portletSettings'+special+':'+n;
						break;
					// - WAL095
					case 'ENUM':
						edit = 'choice';
						var settingLists = this.getSettingLists(setting); // WAL095 -- use helper method
						vlist = settingLists['vlist'];
						dlist = settingLists['dlist'];
						break;
					case '%String':
					default:
						edit = 'string';
						break;
					}
					// + WAL095
					if (navKey==null) {
						navKey = 'widget-common-settings-'+setting.value+special;
					}
					if (minValue != null) {
						content.items[content.items.length] = {display:'caption-value-hz', edit:edit, action:action, caption:setting.caption, value:value,text:text, help:setting.hint, key:navKey,valueList:vlist, displayList:dlist, valueStyle:valueStyle};
					} else {
						content.items[content.items.length] = {display:'caption-value-hz', edit:edit, action:action, caption:setting.caption, value:value,text:text, help:setting.hint, key:navKey,valueList:vlist, displayList:dlist, valueStyle:valueStyle, minValue:minValue, maxValue:maxValue};
					}
					// - WAL095
				}
			}
		}
		else {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Widget has no settings','%DeepSee')};
		}
		break;
	
	// + WAL095 -- draw a list of options provided by the portlet
	case 'widget-common-portletSettings':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		// Assume this is a portlet and grab properties
		var widgetProperties = widgetDef.properties;
		var options = zenPage.fetchOptionList('widget-settings',widgetDef.type+":"+widgetDef.subtype,widgetProperties);
		if (options && options.children && options.children.length) {
			var list = options.children;
			var setting = list[keyNo];
			var settingLists = this.getSettingLists(setting);
			vlist = settingLists['vlist'].split(',');
			dlist = settingLists['dlist'].split(',');
		}
		var list = [];
		for (var i = 0; i < vlist.length; ++i) {
			list[i] = {
				"caption":dlist[i],
				"value":vlist[i],
				"style":''
			}
		}
		// setting.caption can be localized in the portlet's %OnGetPortletSettings method (on the server)
		content.title = setting.caption;
		content.html = zenPage.getNavigator().getChooserListHTML(list,'','','',$$$Text('Choose a value for this setting','%DeepSee'));
		break;
	// - WAL095	
		
	case 'widget-common-controls':
		// list of controls (from widget def)
		content.title = $$$Text('Controls','%DeepSee');

		// "add control" button
		content.headerButtons = [ 
			{key:'widget-common-controlAdd', caption:$$$Text('Add Control','%DeepSee'), image:'deepsee/ds2_plus_44_w.png'}
		];

		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef.controls.length == 0) {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Widget has no Controls','%DeepSee'), value:$$$Text('Press the Add button to add a Control','%DeepSee'),captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;'};
		}

		if (widgetDef && widgetDef.controls) {
			for (var n = 0; n < widgetDef.controls.length; n++) {
				var control = widgetDef.controls[n];
				var image = 'deepsee/ds2_wrench2_44.png';
				var caption = control.label;
				
				switch(control.action) {
				case 'refresh':
					caption = caption ? caption : $$$Text('Refresh');
					break;
				case 'printWidget':
					// DTB251
					caption = caption ? caption : $$$Text('Print Widget');
					break;
				case 'showListing':
					// DTB251
					caption = caption ? caption : $$$Text('Show Listing');
					break;
				}
				
				// DTB251 - Move caption failsafe after the typed defaults
				if (caption==='') {
					caption = control.action;
				}
		
				content.items[content.items.length] = {display:'image-caption', image:image, caption:caption, action:'drill', key:'widget-common-control:'+n, canDrag:true, closeButton:true};
			}
		}
		break;
	case 'widget-common-control':

		// details on one control
		content.title = $$$Text('Control','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}
		if (control) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label','%DeepSee'), value:zenGet(control.label), edit:'string', action:'drill', key:'widget-common-control-label:'+keyNo, help:$$$Text('Label to display for this control','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Action','%DeepSee'), value:zenGet(control.action), action:'drill', key:'widget-common-control-action:'+keyNo, help:$$$Text('Define what this control does','%DeepSee'), text:zenGet(control.actionDisplay)};

			// show different item based on action
			switch(control.action) {
			case 'setFilter':
			case 'applyFilter':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Filter','%DeepSee'), value:zenGet(control.targetProperty), action:'drill', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Filter to apply the action to','%DeepSee'), text:zenGet(control.targetPropertyDisplay)};
				break;

			case 'applyVariable':
				// JMD1276
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Pivot Variable','%DeepSee'), value:zenGet(control.targetProperty), action:'drill', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Pivot variable to apply the action to','%DeepSee'), text:zenGet(control.targetPropertyDisplay)};
				break;

			case 'viewDashboard':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Dashboard','%DeepSee'), edit:'string', value:zenGet(control.targetProperty), action:'popup', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Dashboard to navigate to','%DeepSee'), url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards'};
				break;

				// JMD1139
			case 'setDataSource':
				var sname = zenGet(control.targetProperty).toString();
				sname = sname.split('/');
				sname = sname[sname.length-1];
				sname = sname.split('.')[0];
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('DataSource','%DeepSee'), edit:'string', value:zenGet(control.targetProperty), text:sname, title:zenGet(control.targetProperty), action:'popup', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Set the alternate data source for this control','%DeepSee'), url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=datasources'};
				break;

			case 'chooseDataSource':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('DataSource List','%DeepSee'), value:zenGet(control.targetProperty), edit:'string', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Term list supplying the list of data sources','%DeepSee'), action:'popup', url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists'};
				break;

			case 'setRowSpec':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Spec','%DeepSee'), edit:'string', value:zenGet(control.targetProperty), title:zenGet(control.targetProperty), action:'popup', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Set the alternate set of rows for this control','%DeepSee')};
				break;

			case 'chooseRowSpec':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Spec List','%DeepSee'), value:zenGet(control.targetProperty), edit:'string', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Term list supplying the list of row specs','%DeepSee'), action:'popup', url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists'};
				break;

			case 'setColumnSpec':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Spec','%DeepSee'), edit:'string', value:zenGet(control.targetProperty), title:zenGet(control.targetProperty), action:'popup', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Set the alternate set of columns for this control','%DeepSee')};
				break;

			case 'chooseColumnSpec':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Spec List','%DeepSee'), value:zenGet(control.targetProperty), edit:'string', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Term list supplying the list of column specs','%DeepSee'), action:'popup', url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists'};
				break;
				
			// + WAL083 -- Handles the case where a user click a specific "setChartType" or "chooseChartType" control in the navigator
			//             Displays the "Chart Type" field which shows the one or more chart types associated with the control
			case 'setChartType':
			case 'chooseChartType':
				content.items[content.items.length] = {display:'caption-value-hz', action:'drill', caption:$$$Text('Chart Type','%DeepSee'), value:zenGet(control.targetProperty), key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Chart Type to Use','%DeepSee')};
				break;
			// - WAL083

			case 'navigate':
			case 'newWindow':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('URL','%DeepSee'), value:zenGet(control.targetProperty), edit:'string', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('URL to navigate to','%DeepSee')};
				break;

			case 'showListing':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Listing','%DeepSee'), value:zenGet(control.targetProperty), action:'drill', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Listing to display','%DeepSee'), text:zenGet(control.targetPropertyDisplay)};
				break;
			case 'showGeoListing':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Geo-listing','%DeepSee'), value:zenGet(control.targetProperty), action:'drill', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Listing to display','%DeepSee'), text:zenGet(control.targetPropertyDisplay)};
				break;
			case 'showBreakdown':
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Analysis','%DeepSee'), value:zenGet(control.targetProperty), action:'drill', key:'widget-common-control-targetProperty:'+keyNo, help:$$$Text('Analysis window to show','%DeepSee'), text:zenGet(control.targetPropertyDisplay)};
				break;
			}

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Type','%DeepSee'), value:zenGet(control.type), action:'drill', key:'widget-common-control-type:'+keyNo, help:$$$Text('What type of control to display','%DeepSee'),text:zenGet(control.typeDisplay)};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Location','%DeepSee'), value:zenGet(control.location), action:'drill', key:'widget-common-control-location:'+keyNo, help:$$$Text('Where to place this control','%DeepSee'), text:zenGet(control.locationDisplay)};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Target','%DeepSee'), value:zenGet(control.target), edit:'string', action:'drill', key:'widget-common-control-target:'+keyNo, help:$$$Text('Name of widget to apply the action to. Use * for all, blank for this widget.','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Active When','%DeepSee'), value:zenGet(control.activeWhen), action:'drill', key:'widget-common-control-activeWhen:'+keyNo, help:$$$Text('When is this control enabled','%DeepSee'), text:zenGet(control.activeWhenDisplay)};

			if (control.type=='timer') {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Time (sec)','%DeepSee'), value:zenGet(control.timeout), edit:'string', key:'widget-common-control-timeout:'+keyNo, help:$$$Text('Time period for timer','%DeepSee')};
			}
			else {
				if ((control.type=='custom')||(control.type=='dropdown')) {
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value List','%DeepSee'), value:zenGet(control.valueList), edit:'string', key:'widget-common-control-valueList:'+keyNo};
					content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Display List','%DeepSee'), value:zenGet(control.displayList), edit:'string', key:'widget-common-control-displayList:'+keyNo};
				}
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Read Only','%DeepSee'), value:zenGet(control.readOnly), edit:'switch', key:'widget-common-control-readOnly:'+keyNo};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Size','%DeepSee'), value:zenGet(control.size), edit:'string', key:'widget-common-control-size:'+keyNo, help:$$$Text('Size of this control','%DeepSee')};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Tooltip','%DeepSee'), value:zenGet(control.title), edit:'string', key:'widget-common-control-title:'+keyNo, help:$$$Text('Tooltip for this control','%DeepSee')};

				var url = '_DeepSee.UI.Dialog.DashboardEditDefaultValue.zen?DASHBOARD='+encodeURIComponent(zenPage.dashboardName);
				url += '&DATASOURCE='+encodeURIComponent(widgetDef.dataSource);
				url += '&VALUE='+encodeURIComponent(control.value);
				url += '&TEXT='+encodeURIComponent(control.text);
				url += '&FILTER='+encodeURIComponent(control.targetProperty);

				// DTB442 - Display the control text if it is defined
				var displayValue = ((control.text) ? control.text : zenGet(control.value));
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Default Value','%DeepSee'), value:displayValue, title:zenGet(control.value), action:'popup', key:'widget-common-control-value:'+keyNo, help:$$$Text('Default value for control','%DeepSee'),url:url};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Required','%DeepSee'), value:zenGet(control.valueRequired), edit:'switch', key:'widget-common-control-valueRequired:'+keyNo};		// DTB140 - Add switch to toggle valueRequired
			}

			if (control.type=='custom') {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Custom Control','%DeepSee'), value:zenGet(control.controlClass), edit:'string', key:'widget-common-control-controlClass:'+keyNo, help:$$$Text('Type of custom control','%DeepSee')};
			}
		}
		break;

	case 'widget-common-control-label':
		// get icon list
		content.title = $$$Text('Icons','%DeepSee');
		var options = zenPage.fetchOptionList('user-icons','');
		var list = options.children;
		content.html = zenPage.getNavigator().getIconListHTML(list,key,'');
		break;

	case 'widget-common-control-target':
		// list of target widget names
		content.title = $$$Text('Control Targets','%DeepSee');
		var model = zenPage.getDefinition();
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		var list = [];
		list[list.length] = { caption:$$$Text('This Widget','%DeepSee'), value:''};
		list[list.length] = { caption:$$$Text('All Widgets','%DeepSee'), value:'*'};

		if (model) {
			for (var n = 0; n < model.widgets.length; n++) {
				if (widgetDef.name != model.widgets[n].name) {
					list[list.length] = { value:model.widgets[n].name};
				}
			}
		}
		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.target),$$$Text('Target','%DeepSee'),$$$Text('Choose a target for this control','%DeepSee'));
		break;

	case 'widget-common-control-action':
		// action for control
		content.title = $$$Text('Control Action','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		// get list
		var options = zenPage.fetchOptionList('control-actions',widgetDef.dataSource);
		var list = options.children;

		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.action),$$$Text('Action','%DeepSee'),$$$Text('The Action setting defines what this control does','%DeepSee'));
		break;

	case 'widget-common-control-targetProperty':
		// target property for control
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		switch(control.action) {
		case 'applyFilter':
		case 'setFilter':
			content.title = $$$Text('Filter','%DeepSee');
			var options = zenPage.fetchOptionList('control-filters',widgetDef.dataSource);
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.targetProperty),$$$Text('Filter','%DeepSee'),$$$Text('Select a Filter Value','%DeepSee'));
			break;
		case 'applyVariable':
			content.title = $$$Text('Pivot Variable','%DeepSee');
			var options = zenPage.fetchOptionList('control-pivotVariables',widgetDef.dataSource);
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.targetProperty),$$$Text('Pivot Variable','%DeepSee'),$$$Text('Select a Pivot Variable','%DeepSee'));
			break;
		case 'showListing':
			content.title = $$$Text('Listing','%DeepSee');
			var options = zenPage.fetchOptionList('control-listing',widgetDef.dataSource);
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,'');
			break;
		case 'showGeoListing':
			content.title = $$$Text('GeoListing','%DeepSee');
			// get geolisting list
			var options = zenPage.fetchOptionList('control-geolisting',widgetDef.dataSource);
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,'');
			break;
		case 'showBreakdown':
			content.title = $$$Text('Analysis','%DeepSee');
			// get analysis list
			var options = zenPage.fetchOptionList('control-breakdown',widgetDef.dataSource);
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,'');
			break;
		// + WAL083 (3) -- Use the chart picker to set the chart type
		case 'setChartType':
		case 'chooseChartType':
			content.title = $$$Text('Choose Chart Type','%DeepSee');
			var widgetType = '';
			var widgetSubtype = '';
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			if (widgetDef) {
				widgetType = widgetDef.type;
				widgetSubtype = widgetDef.subtype;
			}
			// show subtypes for the current widget
			var types = zenPage.getWidgetTypes();
			var list = [];
			if (types && types.children) {
				for (var n = 0; n < types.children.length; n++) {
					var type = types.children[n];
					if (type.name == widgetType) {
						if (type.children) {
							content.items[content.items.length] = {display:'section', caption:type.title };
							for (var j = 0; j < type.children.length; j++) {
								var subtype = type.children[j];
								var listValue = subtype.name;
								// WAL083 -- everything else wants to see it be called 'table'
								if (listValue == 'pivot') listValue = 'table';
								list[list.length] = { image:subtype.image, value:listValue, style:''};
							}
						}
					}
				}
				if (control.action == 'setChartType') {
					var contentHTML = zenPage.getNavigator().getIconListHTML(list,key,'');
				}
				else if (control.action == 'chooseChartType') {
					var contentHTML = zenPage.getNavigator().getMultiSelectIconListHTML(list,key,value);
				}
				content.html = contentHTML;
			}
			break;
		// - WAL083 (3)
		}
		break;

	case 'widget-common-control-location':
		// location for control
		content.title = $$$Text('Control Location','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		var list = [
			{ caption:$$$Text('Widget','%DeepSee'), value:'widget',hint:$$$Text('Place this control in the widget toolbar','%DeepSee')},
			{ caption:$$$Text('Dashboard','%DeepSee'), value:'dashboard',hint:$$$Text('Place this control in the dashboard widget list','%DeepSee')},
			{ caption:$$$Text('Click','%DeepSee'), value:'click',hint:$$$Text('This control responds to clicking on the widget','%DeepSee')},
		];

		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.location),$$$Text('Location','%DeepSee'),$$$Text('The Location setting defines where this control is displayed','%DeepSee'));
		break;

	case 'widget-common-control-type':
		// type of control
		content.title = $$$Text('Control Type','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		var list = [
			{ caption:$$$Text('Auto','%DeepSee'), value:'auto',hint:$$$Text('Automatically display the best control','%DeepSee')},
			{ caption:$$$Text('Search Box','%DeepSee'), value:'searchBox',hint:$$$Text('Display a search box','%DeepSee')},
			{ caption:$$$Text('Dropdown','%DeepSee'), value:'dropdown',hint:$$$Text('Display a simple dropdown','%DeepSee')},
			{ caption:$$$Text('Radio','%DeepSee'), value:'radioSet',hint:$$$Text('Display a simple set of radio buttons','%DeepSee')},
			{ caption:$$$Text('Button','%DeepSee'), value:'button',hint:$$$Text('Display a button','%DeepSee')},
			{ caption:$$$Text('Hidden','%DeepSee'), value:'hidden',hint:$$$Text('This control is hidden','%DeepSee')},
			{ caption:$$$Text('Timer','%DeepSee'), value:'timer',hint:$$$Text('Invoke the control action using a timer','%DeepSee')},
			{ caption:$$$Text('Custom','%DeepSee'), value:'custom',hint:$$$Text('Display a custom control','%DeepSee')},
		];

		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.type),$$$Text('Type','%DeepSee'),$$$Text('The Type setting defines what type of control is displayed','%DeepSee'));
		break;

	case 'widget-common-control-activeWhen':
		// activeWhen of control
		content.title = $$$Text('Active When','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var control = null;
		if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
			control = widgetDef.controls[keyNo];
		}

		var list = [
			{ caption:$$$Text('Always','%DeepSee'), value:'',hint:$$$Text('Always enable the control','%DeepSee')},
			{ caption:$$$Text('Item Selected','%DeepSee'), value:'itemSelected',hint:$$$Text('Only enable the control when an item is selected','%DeepSee')},
			{ caption:$$$Text('1 Listing Item Selected','%DeepSee'), value:'listingSelected1',hint:$$$Text('Only enable the control when one item in a listing is selected','%DeepSee')},
			{ caption:$$$Text('Listing Item Selected','%DeepSee'), value:'listingSelected',hint:$$$Text('Only enable the control when an item in a listing is selected','%DeepSee')},
		];
		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(control.activeWhen),$$$Text('Active When','%DeepSee'),$$$Text('The Active When setting defines when the control is enabled','%DeepSee'));
		break;

	case 'widget-common-dataProperties':
		// list of data properties (from widget def)
		content.title = $$$Text('Data Properties','%DeepSee');

		// "add data Prop" button
		content.headerButtons = [ 
			{key:'widget-common-dataPropertyAdd', caption:$$$Text('Add Data Property','%DeepSee'), image:'deepsee/ds2_plus_44_w.png'}
		];

		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef.dataProperties.length == 0) {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Widget has no Data Properties','%DeepSee'), value:$$$Text('Press the Add button to add a Data Property','%DeepSee'),captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;'};
		}

		if (widgetDef && widgetDef.dataProperties) {
			for (var n = 0; n < widgetDef.dataProperties.length; n++) {
				var dp = widgetDef.dataProperties[n];
				var image = 'deepsee/ds2_target_44.png';
				var caption = dp.dataValue;
				content.items[content.items.length] = {display:'image-caption', image:image, caption:caption, action:'drill', key:'widget-common-dataProperty:'+n, canDrag:true, closeButton:true};
			}
		}
		break;
	case 'widget-common-dataProperty':
		// details on one dataProp
		content.title = $$$Text('Data Property','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var dp = null;
		if (widgetDef && widgetDef.dataProperties && widgetDef.dataProperties.length) {
			dp = widgetDef.dataProperties[keyNo];
		}
		if (dp) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Hidden','%DeepSee'), value:zenGet(dp.display)=='hidden', edit:'switch', key:'widget-common-dataProperty-hidden:'+keyNo};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Name','%DeepSee'), value:zenGet(dp.name), edit:'string', key:'widget-common-dataProperty-name:'+keyNo, help:$$$Text('Name of this data property','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label','%DeepSee'), value:zenGet(dp.label), edit:'string', action:'drill', key:'widget-common-dataProperty-label:'+keyNo, help:$$$Text('Label to display for this data property','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Data Value','%DeepSee'), value:zenGet(dp.dataValue), edit:'string', action:'drill', key:'widget-common-dataProperty-dataValue:'+keyNo, help:$$$Text('Data value for this property','%DeepSee')};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Column','%DeepSee'), value:zenGet(dp.valueColumn), edit:'switch', key:'widget-common-dataProperty-valueColumn:'+keyNo};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Format','%DeepSee'), value:zenGet(dp.format), edit:'string', action:'drill', key:'widget-common-dataProperty-format:'+keyNo, help:$$$Text('Optional formatting to apply','%DeepSee')};
		}
		break;

	case 'widget-common-dataProperty-dataValue':
		// list of possible data values
		content.title = $$$Text('Properties','%DeepSee');

		// get data property list
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var options = zenPage.fetchOptionList('widget-property',widgetDef.dataSource);
		if (options && options.children) {
			var list = options.children;
			content.html = navigator.getChooserListHTML(list,key,value);
		}
		break;

	case 'widget-common-dataProperty-label':
		// label for dataProp
		content.title = $$$Text('Label','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var dp = null;
		if (widgetDef && widgetDef.dataProperties && widgetDef.dataProperties.length) {
			dp = widgetDef.dataProperties[keyNo];
		}

		var list = [
			{ caption:$$$Text('Auto','%DeepSee'), value:'$auto',hint:$$$Text('Select a default label automatically','%DeepSee')},
		];

		content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(dp.label),$$$Text('Label','%DeepSee'),$$$Text('Select a label for this data property','%DeepSee'));
		break;

	case 'widget-common-dataProperty-format':
		content.title = $$$Text('Numeric Format','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var dp = null;
		if (widgetDef && widgetDef.dataProperties && widgetDef.dataProperties.length) {
			dp = widgetDef.dataProperties[keyNo];
		}

		var list = [
			{ caption:$$$Text('###','%DeepSee'), value:'###'},
			{ caption:$$$Text('###.#','%DeepSee'), value:'###.#'},
			{ caption:$$$Text('###.##','%DeepSee'), value:'###.##'},
			{ caption:$$$Text('###.###','%DeepSee'), value:'###.###'},
			{ caption:$$$Text('#,##','%DeepSee'), value:'#,##'},
			{ caption:$$$Text('#,##.#','%DeepSee'), value:'#,##.#'},
			{ caption:$$$Text('#,##.##','%DeepSee'), value:'#,##.##'},
			{ caption:$$$Text('#,##.###','%DeepSee'), value:'#,##.###'},
			{ caption:$$$Text('##.##%','%DeepSee'), value:'##.##%'},
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(dp.format),$$$Text('Format','%DeepSee'),$$$Text('Choose a numeric format','%DeepSee'));
		break;
}
return content;
}

/// Re-arrange of a list in navigator.
ClientMethod navDataArrange(key, swap, final) [ Language = javascript ]
{
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	switch (key) {
	case 'widget-common-control':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (final && widgetDef && widgetDef.controls && widgetDef.controls.length) {
			var oldList = widgetDef.controls;

			var newList = [];
			for (var n = 0; n < oldList.length; n++) {
				newList[n] = oldList[n];
			}

			// swap items
			var x = newList[swap.oldPosition];
			newList[swap.oldPosition] = newList[swap.newPosition];
			newList[swap.newPosition] = x;

			widgetDef.controls = newList;

			if (widgetDef.controls[swap.newPosition].location=='dashboard') {
				zenPage._forceReload = 1;
			}
			zenPage.setModified(true);
			zenPage.recreateWidget(zenPage.currWidgetKey);
		}
		break;
	case 'widget-common-dataProperty':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (final && widgetDef && widgetDef.controls && widgetDef.controls.length) {
			var oldList = widgetDef.dataProperties;

			var newList = [];
			for (var n = 0; n < oldList.length; n++) {
				newList[n] = oldList[n];
			}

			// swap items
			var x = newList[swap.oldPosition];
			newList[swap.oldPosition] = newList[swap.newPosition];
			newList[swap.newPosition] = x;

			widgetDef.dataProperties = newList;
			zenPage.setModified(true);
			zenPage.recreateWidget(zenPage.currWidgetKey);
		}
		break;
	}
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	// key may take the form key:no
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}
	
	// key may take the form key/type
	var keyType = '';
	if (key.toString().indexOf('/')>0) {
		var t = key.split('/');
		key = t[0];
		keyType = t[1];
	}

	// pull 'widget-common-' off of key
	var kt = key.toString().split('-');
	kt.splice(0,2);
	var k2 = kt.join('-');
	var target = kt[0];
	switch(target) {
		
	// WAL095 -- fall through and apply like a normal setting
	case 'portletSettings':  
		if (final) {
			var attr = keyType;
		}
	case 'settings':
		// widget setting
		if (final) {
			var kt = k2.toString().split('-');
			// + WAL095 -- in that case we already have an attr as part of the key
			//             attr is the name of the setting from the portlet
			if ('portletSettings'!=target) {
				var attr = kt[1];
			}
			// - WAL095
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			// JMD1237: coerce
			if (value===false) {
				value = 0;
			}
			else if (value===true) {
				value = 1;
			}
			widgetDef.properties[attr] = value;
			// JMD1447
			if (attr == 'showDimensions') {
				zenPage._forceReload = 1;
			}
			zenPage.recreateWidget(zenPage.currWidgetKey);
			if (attr == 'opacity') { // JSL4483
				this.setProperty('opacity',value);
			}
			
		}
		break;

	case 'control':
		if (final) {
			var kt = k2.toString().split('-');
			var attr = kt[1];
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			var control = null;
			if (widgetDef && widgetDef.controls && widgetDef.controls.length) {
				control = widgetDef.controls[keyNo];
				if (control && (control[attr]!= value)) {
					var oldAction = control.action;
					var newAction = (attr=='action') ? value : oldAction;

					if (attr=='action') {
						// reset target when action changes
						// (unless change from set/apply filter)
						if ((oldAction=='setFilter' && newAction!='applyFilter') ||
							(oldAction=='applyFilter' && newAction!='setFilter')) {
							control.targetProperty = '';
							control.targetPropertyDisplay = '';
						}
					}
					else if ((attr=='targetProperty')||(attr=='location')) {
						if (control.action=='applyFilter' || control.action=='setFilter') {
							// work-around to make filter change work
							zenPage._forceReload = true;
						}
					}
					else if (attr=='location') {
						// work-around to make filter change work
						zenPage._forceReload = true;
					}

					// reload for any control change!
					// zenPage._forceReload = true;
					
					control[attr] = value;
					// find display name
					switch(attr) {
					case 'action':
					case 'type':
					case 'location':
					case 'targetProperty':
					case 'activeWhen':
						control[attr+'Display'] = zenPage.getNavigator().currDisplayValue;
						break;
					}
					// WAL084 -- pass 'EditControl' to handle case of updating an existing control
					zenPage.recreateWidget(zenPage.currWidgetKey,'EditControl',keyNo);
				}
			}
		}
		break;

	case 'theme':
		if (final) {
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			if (widgetDef && widgetDef.theme!=value) {
				// JMD1201
				this.resetOverrides(true);
				widgetDef.theme = value;
				zenPage._forceReload = true;
				zenPage.recreateWidget(zenPage.currWidgetKey);
			}
		}
		break;

	case 'dataProperty':
		if (final) {
			var kt = k2.toString().split('-');
			var attr = kt[1];
			if (attr=='hidden') {
				// map *hidden* to *display*
				attr = 'display';
				value = (value?'hidden':'');
			}
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			var dp = null;
			if (widgetDef && widgetDef.dataProperties && widgetDef.dataProperties.length) {
				dp = widgetDef.dataProperties[keyNo];
				if (dp && (dp[attr]!= value)) {
					dp[attr] = value;
					zenPage.recreateWidget(zenPage.currWidgetKey);
				}
			}
		}
		break;

	default:
		switch(k2) {
		case 'dataSource':
		case 'drillDownDataSource':
		case 'dataLink':
			var prop;
			switch (key) {
			case 'widget-common-drillDownDataSource':
				prop = 'drillDownDataSource';
				break;
			case 'widget-common-dataLink':
				prop = 'dataLink';
				break;
			default:
				prop = 'dataSource';
				break;
			}
			if (final) {
				var widgetDef = this.getDefinition(zenPage.currWidgetKey);
				if (widgetDef && widgetDef[prop] != value) {
					widgetDef[prop] = value;
					if (prop=='dataLink') {
						zenPage._forceReload = true;
					}
					else {
						zenPage.setModified(true);
					}
					zenPage.recreateWidget(zenPage.currWidgetKey);
				}
			}
			break;

		case 'name':
			if (final) {
				var widgetDef = this.getDefinition(zenPage.currWidgetKey);
				if (widgetDef && widgetDef.name!=value) {
					// see if name is unique
					var model = zenPage.getDefinition();
					if (model) {
						for (var n = 0; n < model.widgets.length; n++) {
							if (value == model.widgets[n].name) {
								alert($$$Text('There is already a widget with this name','%DeepSee'));
								return;
							}
						}

						// fix up dataLinks
						for (var n = 0; n < model.widgets.length; n++) {
							if (widgetDef.name == model.widgets[n].dataLink && model.widgets[n].dataLink!=='') {
								model.widgets[n].dataLink = value;
							}
						}
					}

					widgetDef.name = value;
					zenPage.setModified(true);
				}
			}
			break;
		case 'title':
			if (final) {
				var widgetDef = this.getDefinition(zenPage.currWidgetKey);
				widgetDef.title = value;
				zenPage.setModified(true);
			}
			this.setProperty('header',value);
			break;
		case 'showToolbar':
		case 'showToolbarBottomBorder':		// DTB171
		case 'showToolbarOnlyWhenMaximized': // WAL105
		case 'sidebarContent':
		case 'showSidebar':
		case 'sidebarWidth':		// DTB122
		case 'colorToolbar':
		case 'opacityToolbar':
			if (final) {
				var widgetDef = this.getDefinition(zenPage.currWidgetKey);
				widgetDef[k2] = value;
				zenPage.setModified(true);
			}
			this.setProperty(k2,value);
			break;
		}
		break;
	}
}

/// Select of item in navigator.
ClientMethod navSelectItem(key, value, which) [ Language = javascript ]
{
	// pull 'widget-' off of key
	var kt = key.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');

	if (which == 'select') {
		switch(k2) {
		case 'print-setup':
			if (zenPage.showPDFOptions) {
				zenPage.showPDFOptions();
			}
			break;
		case 'common-widgetSubtype':
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			if (widgetDef) {
				if (value!=widgetDef.subtype) {
					if (confirm('Do you wish to change the type of this widget?')) {
						this.subtype = value;
						widgetDef.subtype = value;
						// remove overrides
						for (var p in widgetDef.overrides) {
							widgetDef.overrides[p] = '';
						}
						this.resetOverrides(false,false);
						zenPage.setModified(true);
						zenPage.recreateWidget(zenPage.currWidgetKey);
					}
				}
			}
			zenPage.getNavigator().popSheet();
			break;

		case 'common-reset':
			if (confirm($$$Text('Do you want to reset the style of this widget?'))) {
				zenPage.setModified(true);
				this.resetOverrides();
			}
			break;
		case 'common-resetDataSource':
			var widgetDef = this.getDefinition(zenPage.currWidgetKey);
			if (widgetDef && widgetDef.localDataSource) {
				if (confirm($$$Text('Do you want to reset the data source for this widget?'))) {
					zenPage.setModified(true);
					widgetDef.localDataSource = '';
					// JMD1413
					widgetDef.resetDataSource = true;
					zenPage.recreateWidget(zenPage.currWidgetKey);
				}
			}
			break;
		case 'common-saveToCatalog':
			if (zenPage.saveWidgetToCatalog) {
				zenPage.saveWidgetToCatalog();
			}
			break;
		case 'common-saveToTheme':
			if (zenPage.saveWidgetToTheme) {
				zenPage.saveWidgetToTheme();
			}
			break;
		default:
			break;
		}
	}
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
	// key may take the form key:no
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	switch(key) {
	case 'widget-common-controlAdd':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		zenPage.addControlDef();
		break;
	case 'widget-common-dataPropertyAdd':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		zenPage.addDataPropertyDef();
		break;
	}
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
	// key may take the form key:no
	var keyNo = '';
	var keyName = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyName = t[1];
		keyNo = parseInt(t[1]);
	}

	switch(key) {
	case 'widget-common-theme':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && zenPage.DeleteTheme) {
			if (confirm($$$FormatText($$$Text('Do you wish to delete the theme \'%1?\'?'),keyName))) {
				var msg = zenPage.DeleteTheme(keyName);
				if (msg) {
					alert(msg);
				}
				var nav = zenPage.getNavigator();
				if (nav) {
					// clear cache of themes
					if (zen('jsonOptionWhich')) {
						zen('jsonOptionWhich').value = '';
					}
					nav.refreshTopSheet();
				}
			}
		}
		break;

	case 'widget-common-control':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			// + WAL064 -- pass control location and index for which
			// control to delete from widget definition to recreateWidget
			if (confirm('Do you wish to delete this control?')) {
				zenPage.setModified(true);
				zenPage.recreateWidget(zenPage.currWidgetKey,'RemoveControl',keyNo);
			}
			// - WAL064
		}
		break;

	case 'widget-common-dataProperty':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			if (confirm('Do you wish to delete this data property?')) {
				widgetDef.dataProperties.splice(keyNo,1);
				zenPage.setModified(true);
				zenPage.recreateWidget(zenPage.currWidgetKey);
			}
		}
		break;
	}
}

/// Popup action in navigator.
ClientMethod navPopupAction(key, value) [ Language = javascript ]
{
	// key may take the form key:no
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}
	
	switch(key) {
	case 'widget-common-control-targetProperty':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			control = widgetDef.controls[keyNo];
			if (control) {
				control.targetProperty = value;
				zenPage.setModified(true);
				zenPage.recreateWidget(zenPage.currWidgetKey);
			}
		}
		break;
	case 'widget-common-control-value':
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef) {
			control = widgetDef.controls[keyNo];
			if (control) {
				// DTB442 - Control default might be an object with logical and display values
				if ((value.defaultValue)||(''==value.defaultValue)) {
					control.value = value.defaultValue;
					control.text = value.defaultText;
				}
				else {
					control.value = value;
				}
				
				zenPage.setModified(true);
				zenPage._forceReload = true;
				zenPage.recreateWidget(zenPage.currWidgetKey);
			}
		}
		break;
	case 'widget-common-dataSource':
	case 'widget-common-drillDownDataSource':
		var prop;
		switch (key) {
		case 'widget-common-drillDownDataSource':
			prop = 'drillDownDataSource';
			break;
		default:
			prop = 'dataSource';
			break;
		}
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef[prop] != value) {
			widgetDef[prop] = value;
			zenPage.setModified(true);
			zenPage.recreateWidget(zenPage.currWidgetKey);
		}
		break;
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'sidebarContent':
		this.sidebarContent = value;
		var side = this.findComponent('sidebar');
		side.setContent(value);
		break;

	case 'showSidebar':
		this.showSidebar = value?true:false;
		var side = this.findComponent('sidebar');
		side.setHidden(!this.showSidebar);
		this.adjustSizes();
		break;
	
	case 'sidebarWidth':			// DTB122 - add case to handle sidebarWidth and update
		this.sidebarWidth = value;
		this.adjustSizes();
		break;
		
	case 'showToolbar':
		this.hideToolbar(!value);
		break;
		
	case 'showToolbarBottomBorder':		// DTB171
		this.showToolbarBottomBorder = value;
		this.adjustSizes();
		break;
	case 'showToolbarOnlyWhenMaximized':	// DTB171
		this.showToolbarOnlyWhenMaximized = value;
		this.adjustSizes();
		break;
		
	case 'colorToolbar':
		this.colorToolbar = value; // JSL4483
		this.setToolbarProperty('background-color',value);
		break;
	case 'opacityToolbar':
		this.opacityToolbar = value; // JSL4483
		this.setToolbarProperty('opacity', value);
		break;
	case 'opacity':
		//this.opacity = value; // JSL4483 for meters
		this.setOpacity(value);	// JSL4483
		break;
	case 'backgroundColor':
		this.backgroundColor = value; // JSL4483
		this.setOpacity(this.opacity);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Resize the active group to the given geometry.
ClientMethod resize(width, height) [ Language = javascript ]
{
	// JMD1053 -- override and add spacing
	var spacing = 4;
	if (!width.indexOf) width=(Math.floor(width)-spacing)+"px";
	if (!height.indexOf) height=(Math.floor(height)-spacing)+"px";
	var thisDiv = this.getEnclosingDiv();
	if (thisDiv) {
		// widget could be "closed"
		thisDiv.style.width=width;
		thisDiv.style.height=height;
	    this.adjustHandleWidth();
	    this.adjustChildArea();
	    this.onresizeHandler();
	}
}

/// Utility method.
/// Convert a component instance <var>obj</var> to JavaScript object literal syntax (JSON).
/// This is used to get user modifications to components.
ClientMethod componentToJSON(obj, level, skip) [ Internal, Language = javascript ]
{
	try {
		skip = skip ? skip : {};
		level = zenGet(level,0);

		// n.b. there is no cycle detection
		if (level > 100) {
			alert('componentToJSON: too many levels in JSON object');
			return null;
		}

		var t = [];
		switch (typeof obj) {
		case 'boolean':
			t[t.length] = obj ? 'true' : 'false';
			break;
		case 'string':
			var text = obj.toString();
			text = text.replace(/\\/g,'\\\\'); // escape any backslash
			text = text.replace(/\'/g,'\\\''); // escape any single quotes
			t[t.length] = '\'' + text + '\'';
			break;
		case 'number':
			t[t.length] = obj;
			break;
		case 'object':
			if (null == obj) {
				return 'null';
			}
			else if (Object.prototype.toString.call( obj[p] ) === '[object Function]') {		// DTB625 - Do not test the constructor directly
				return '';
			}
			else if (Object.prototype.toString.call( obj ) === '[object Array]') {		// DTB625 - Do not test the constructor directly
				t[t.length] = '[';
				for (var n = 0; n < obj.length; n++) {
					var sub = this.componentToJSON(obj[n],level+1,skip);
					if (null == sub) {
						return null;
					}
					t[t.length] = ((n>0)?',':'') + sub;
				}
				t[t.length] = ']';
			}
			else {
				var settings = null;
				if (obj.getSettings) {
					settings = {};
					obj.getSettings(settings);
				}

				var proto = null;
				if (obj._type) {
					// create prototype to test for default values
					// deal with namespace!
					switch (obj._type) {
					case 'scoreCard':
					case 'scoreCardColumn':
					case 'chartLegend':
					case 'pivotTable':
					case 'pivotLevel':
					case 'queryChunk': // WAL094
						proto = zenPage.createComponentNS('http://www.intersystems.com/deepsee',obj._type);
						break;
					default:
						proto = zenPage.createComponent(obj._type);
						// JMD1179: labels off by default
						if (obj._type=='pieChart') {
							proto.labelsVisible = false;
							proto.showMultiples = true; // Prodlog 110052 JSL4169
						}
						if (obj._type=='treeMapChart' || obj._type=='donutChart') { // JSL4169
							proto.showMultiples = true; // Prodlog 110052 JSL4169
						}
						break;
					}
				}

				var pc = 0;
				t[t.length] = '{';
				for (var p in obj) {
					if ((p=='_type')&& !skip[p]) {		// DTB147 - remove _type if it is in the skip list
						t[t.length] = ((pc++>0)?',':'') + p + ':\'' + obj[p] + '\'';
					}
					else if ((obj[p])&&('function' != typeof obj[p])) {
						try {
							// DTB565 - Protect access attempts with a Try block
							var isArray = (Object.prototype.toString.call( obj[p] ) === '[object Array]')		// DTB625 - Do not test the constructor directly
							var isType = !!(obj[p]._type);

							if (!settings||settings[p]||
								(obj[p] && 'object'== typeof obj[p] && (isArray || isType))) {
								// skip _props (except for _type)
								// skip event handlers
								if ((p.indexOf('_')==-1) && !skip[p] && (!settings || settings[p]!='eventHandler')) {
									// skip default values
									if (!proto || (obj[p]!==proto[p])) { 
										var sub = this.componentToJSON(obj[p],level+1,skip);
										if (null===sub) {
											return null;
										}
										if (sub!=="''" && sub!='null') {
											t[t.length] = ((pc++>0)?',':'') + p + ':' + sub;
										}
									}
								}
							}
						}
						catch(ex) {
							// DTB565 - Swallow the error. If debugging is needed, uncomment this log statement
							//console.log(ex.message);
						}
					}
				}
				t[t.length] = '}';
			}
			break;
		case 'function':
			break;
		default:
			break;
		}
		return t.join('');
	}
	catch(ex) {
		// fall through and return null
		alert('Error in componentToJSON: ' + level + "; " + ex.message);
	}

	// failure
	return null;
}

/// Test if there are any style overrides for this widget.
ClientMethod hasOverrides() [ Language = javascript ]
{
	return false;
}

/// Reset any style overrides for this widget.
ClientMethod resetOverrides(themeOnly, recreate) [ Language = javascript ]
{
}

/// Return an array of current style overrides for this widget.
/// Used to save to a theme.
ClientMethod getOverrides() [ Language = javascript ]
{
	return {};
}

/// Return the actual type used for a widget subtype (such as "barChart").
ClientMethod getSubtypeClass() [ Language = javascript ]
{
	return '';
}

/// Return a list of items that should not be saved in override JSON arrays.
/// The return is passed to <method>componentToJSON</method>. 
ClientMethod getOverrideSkipList(type) [ Language = javascript ]
{
	// Method added by DTB147
	switch (type) {
		case 'pivot':
			var skip = {
				autoExecute:true,
				calculatedMembers:true,
				changesPending:true,
				columnAxisOptions:true,
				columnLevels:true,
				columnList:true,		// DTB375
				controller:true, 
				controllerId:true, 
				crossJoinRowLimit:true,
				cubeName:true, 
				currListingPage:true,
				currPage:true,
				currentQueryText:true,
				dataSourceName:true, 
				drillLevels:true, 
				dropEnabled:true,
				filters:true,
				formatRules:true, 
				height:true, 
				hidden:true,
				initialExecute:true,
				kpi:true,			// DTB375
				listing:true,
				listingFields:true,
				listingFilters:true,
				listingSelect:true,
				listingSortColumn:true,
				listingSortDir:true,
				measures:true, 
				parameters:true, 
				parent:true, 
				pivotVariables:true,
				resolvedQueryText:true,
				rowAxisOptions:true, 
				rowLevels:true,
				selectedRange:true, 
				showPivotStats:true, 
				showStatus:true,
				singleTable:true,
				sortColumn:true,
				sortDir:true,
				superClass:true, 
				width:true,
				window:true,
				parent:true, 
				window:true, 
			};
			break
		case 'legend':
			var skip = {
				chart:true,
				chartId:true, 
				controller:true,
				controllerId:true, 
				parent:true, 
				window:true
			}
			break
		case 'chart':
			var skip = {
				controller:true, 
				controllerId:true, 
				endTime:true,
				height:true, 
				onelementClick:true,
				parent:true, 
				selectedItem:true,
				selectedItemStyle:true,
				selectedRange:true,		// DTB378
				selectedSeries:true,
				seriesCount:true,
				seriesNames:true,
				seriesSize:true, 
				startTime:true,
				superClass:true, 
				width:true,
				window:true
			}
			break
	}
	return skip;
}

/// Return the definition object for a given widget, if available. Use this widget by default.
ClientMethod getDefinition(key) [ Language = javascript ]
{
	key = zenGet(key,this.widgetKey);
	var widgetDef = null;
	if (zenPage.getWidgetDefinition) {
		widgetDef = zenPage.getWidgetDefinition(key);
	}
	return widgetDef;
}

/// Apply the given pivot variable value to the pivot.
ClientMethod applyPivotVariable(varName, value) [ Internal, Language = javascript ]
{
	// JMD1380
	var pivot = this.getDataController();
	if (!pivot || !pivot.pivotVariables) {
		return;
	}
	pivot.pivotVariables[varName.toString().toLowerCase()] = value;
	pivot.executeQuery(pivot.autoExecute);
}

ClientMethod setToolbarProperty(property, value) [ Language = javascript ]
{
	
	//+ JSL4483
	var id=this.id; // our widget id
	var divToolBar = document.getElementById(id+'/bkgheader');
	if (divToolBar) {
		divToolBar.style[property] = value;
	}
	//- JSL4483
}

ClientMethod setOpacity(opacity) [ Language = javascript ]
{
	
	var svgFrame=this.getSVGFrame(); // JSL4489 - simplify logic, encapsulate in getSVGFrame
	if (svgFrame != null) {
		if (opacity < 1.0) {
			svgFrame.style.background="transparent";
			//svgFrame.style.border = "none";
		} else {
			svgFrame.style.backgroundColor = "white";
		}
	}
	
	var dragGroup = document.getElementById(this.id);
	if (dragGroup) {
		if (opacity < 1.0 || dragGroup._transparent) { // JSL4503 - see if someone set dragGroup to transparent as background
			dragGroup.style.background="transparent";
			//dragGroup.style.backgroundColor="transparent";
			//dragGroup.style.opacity = opacity;
		} else {
			dragGroup.style.backgroundColor=this.backgroundColor;
		}
	}
}

/// This is called by dragGroupManager when it is given 'processAppMessage' method
ClientMethod processAppMessage(value) [ Language = javascript ]
{
	// Method added by JSL4488
	var messageType = value.messageType;
	switch (messageType) {
		case 'setSVGFrameBorder':
		
		var svgFrame=this.getSVGFrame(); // JSL4489
		if (svgFrame != null) {
			svgFrame.style.border = value.border;
		}
		break;
		
		default:
		break;
	}
}

ClientMethod getSVGFrame() [ Language = javascript ]
{
	// added JSL4489
	var svgFrameContainer = document.getElementById(this.id+'/svgFrame');
	if (svgFrameContainer) {
		var svgFrameId = 'svgdiv_'+svgFrameContainer.getAttribute('zen'); // magic id 
		return document.getElementById(svgFrameId);
	}
	return null;
}

ClientMethod getSettingLists(setting) [ Language = javascript ]
{
	// Method added by WAL095
	var settingLists = new Object();
	vlist = setting.type.toString().split('^')[1];
	dlist = zenGet(setting.displayList);
	// + WAL077 -- handle case where valueList contains captions
	//             looks like:   caption:value,caption:value etc.
	var valueList = vlist.toString().split(',');
	var newdlist = '';
	var newvlist = '';
	var noCaptions = true;
	for (var i=0; i < valueList.length; ++i) {
		var currItem = valueList[i].toString().split(':');
		if (i!=0) {
			newdlist += ',';
			newvlist += ',';
		}
		newdlist += currItem[0];
		if (currItem.length>1) {
			newvlist += currItem[1];
			noCaptions = false;
		}
		else {
			newvlist += currItem[0];
		}
	}
	vlist = newvlist;
	// If we found no captions, don't change the dlist
	if (!noCaptions) { 
		dlist = newdlist; 
	}
	// - WAL077
	settingLists['vlist'] = vlist;
	settingLists['dlist'] = dlist;
	return settingLists;
}

ClientMethod getSettingDisplayValue(setting, value) [ Language = javascript ]
{
	// Method added by WAL095
	var settingLists = this.getSettingLists(setting);
	var vlist = settingLists['vlist'].split(',');
	var dlist = settingLists['dlist'].split(',');
	var dvalue = '';
	for (var i=0; i < vlist.length; i++) {
		if (value==vlist[i]) {
			dvalue = dlist[i];
			break;	
		}	
	}
	if (dvalue) {
		return dvalue;
	}
	else {
		return value;	
	}
}

/// Print SVG content using the svgImageProvider. Parameters specific to the widget type may be passed in
/// via the parms object, and those parameters will be augmented using settings common to all widgets in
/// this clientMethod.<br>
/// The target content may be looked up in the current svgFrameId, or printable content can be passed in
/// directly as svgContent.
ClientMethod printSVGContent(svgFrameId, parms, svgContent, filename) [ Language = javascript ]
{
	// Method added by DTB250
	if (!parms) {
		var parms = {};
	}

	var util = zenPage.getComponentById("svgUtil");
	var isMasterWidget = this.isMasterWidget(this.id);		// DTB252 - check to see if the page settings are expected from this widget
	
	if (!filename) {
		var name = this.id + '-print'+zenPage.tempFileToken;	// DTB252 - Normalize the file name to the widget ID. DTB355 - Add session-derived token
	}
	else {
		// DTB684 - Use user supplied filename
		var name = filename;
	}

	var fullName = util.makeSVGFileName(name+".xsl");
	parms.fileName = fullName;
	
	if (!parms.printMultiple) {
		// DTB252 - Don't bother with an output file if in multi-print mode
		var outName = util.makeSVGFileName(name+".pdf");
	}
 		
	if (parms.printMultiple) {
		if (isMasterWidget) {
			// DTB252 - Set the common reference for other widgets in multi-print mode
			
			// Set the common reference to the print settings from this widget
			var parsedWidth = util.parseSize(parms.pageWidth);
			var parsedHeight = util.parseSize(parms.pageHeight);
			
			zenPage.printPageSize = parsedWidth.value + 'x' + parsedHeight.value + ' ' + parsedWidth.units;
			zenPage.printPageOrientation = 'portrait';		// Always assume portrait orientation in svg printing
			zenPage.printMarginLeft = (parseFloat(parms.marginLeft)/72)+'in';
			zenPage.printMarginRight = (parseFloat(parms.marginRight)/72)+'in';
			zenPage.printMarginTop = (parseFloat(parms.marginTop)/72)+'in';
			zenPage.printMarginBottom = (parseFloat(parms.marginBottom)/72)+'in';
		}
		else {
			// DTB252 - Inherit the master widget settings
			parms.marginLeft = (zenPage.printMarginLeft) ? util.convertSizeToPoint(zenPage.printMarginLeft).value+'pt' : '36pt';
			parms.marginRight = (zenPage.printMarginRight) ? util.convertSizeToPoint(zenPage.printMarginRight).value+'pt' : '36pt';
			parms.marginTop = (zenPage.printMarginTop) ? util.convertSizeToPoint(zenPage.printMarginTop).value+'pt' : '36pt';
			parms.marginBottom = (zenPage.printMarginBottom) ? util.convertSizeToPoint(zenPage.printMarginBottom).value+'pt' : '36pt';
			
			// Convert a size, in format 
			//  <width>x<height> <unit>
			// into distinct width and height. Account for page orientation, 
			// which does not exist in the svg printer.
			var pageSizeString = zenPage.printPageSize;
			var pageSize = pageSizeString.substring(0,pageSizeString.indexOf(' '));
			var pageUnit = pageSizeString.substring(pageSizeString.indexOf(' ')+1);
			
			if ('portrait'==zenPage.printPageOrientation) {
				parms.pageWidth = pageSize.substring(0,pageSize.indexOf('x')) + pageUnit;
				parms.pageHeight = pageSize.substring(pageSize.indexOf('x')+1) + pageUnit;		// DTB263 - Add unit
			}
			else {
				parms.pageWidth = pageSize.substring(pageSize.indexOf('x')+1) + pageUnit;		// DTB263 - Add unit
				parms.pageHeight = pageSize.substring(0,pageSize.indexOf('x')) + pageUnit;
			}
		}
	}
	
	// Call this after local pageWidth, margins are set!
	parms.imageWidth = util.calculateMaxImageWidth(parms);
	parms.imageHeight = util.calculateMaxImageHeight(parms);		// DTB561 - This limits the maximum height of printable image content
	parms.omitPageNumbers = !(parms.printMultiple);

	// Always create the XSLFO file.
	if (svgContent) {
		// DTB345 - Consume the svgContent directly. The utility expects the SVG content
		// to be wrapped in a parent container.
		util.saveDOMToXSLFile(svgContent, parms);
	}
	else {
		// DTB345 - Pass the id of the svgFrame and the utility will look 
		// up the svg content in the DOM.
		util.saveToXSLFile(svgFrameId, parms);
	}
	
	// If the widget is making the pdf, convert the xsl to pdf and 
	// open the MDXPDF viewer to view the completed output.
	if ((outName)&&(!parms.printMultiple)) {
		util.ConvertXSLToPDF(fullName,outName);
		var url = '_DeepSee.UI.MDXPDF.zen';
		url = url + '?FILEPDFROOT=' + encodeURIComponent(outName.split('.').slice(0,-1).join('.') || outName);
		if (zenPage.pdfPreserveTempFiles) {
			url += '&$NODELETE=1';
		}

		window.open(url,'pdf','');
	}
}

/// Find the filters defined for the current widget and return them in a JSON table
/// fit for consumption by the SVG printer.
ClientMethod getFilterTableForPrinting(parms) [ Language = javascript ]
{
	// Method added by DTB346
	// Find filter values and names from the data source
	var table = this.getDataController();
	var filterNames = [];
	var filterValues = [];
	var filterLabels = [];		// DTB551

	if (''!==table.kpi) {
		if (table&&table.filters) {
			// get filter values
			for (var n = 0; n < table.filters.length; n++) {
				var filter = table.filters[n];
				if (filter.text!='') {
					filterNames[filterNames.length] = this.GetKpiFilterCaption(this.dataSource,filter.spec);		// DTB367
					var val = filter.text.toString();
					// unquote
					if ('&'==val.charAt(0)) {
						val = val.substring(2,val.length-1);
					}
					filterValues[filterValues.length] = val;
				}
			}
		}
		else {
			// Try to print filters from the widget state
			for (var filter in this.filterText) {
				var filterValue = this.filterText[filter]
				if (filterValue) {
					filterNames[filterNames.length] = filter;
					filterValues[filterValues.length] = filterValue;
				}
			}	
		}
		
		// Try to add pivot variables
		for (prop in table.pivotVariables) {
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		table.getFilterInfo(filterNames,filterValues,filterLabels);		// DTB551 - Add filter labels
		table.getPivotVariableInfo(filterNames,filterValues);		// DTB489
	}
	
	for (f in filterLabels) {
		// DTB551 - Replace the names with labels if they exist.
		if (filterLabels[f]) {
			filterNames[f] = filterLabels[f];
		}
	}

	// DTB555 - Resolve localized names just before dispatching to prepareFilterTable
	var resolvedFilterNames = [];
	var resolvedFilterName = '';
	for (f in filterNames) {
		resolvedFilterNames[f] = this.ResolveText(filterNames[f]);
	}

	var util = zenPage.getComponentById("svgUtil");
	return util.prepareFilterTable(resolvedFilterNames,filterValues,parms);		// DTB405 - Pass parms through to the utility
}

ClientMethod isMasterWidget(widgetId) [ Language = javascript ]
{
	return (widgetId==zenPage.printMasterWidgetId);
}

/// Lookup a filter caption for a KPI
ClassMethod GetKpiFilterCaption(pKPIName, pSpec) As %String [ ZenMethod ]
{
	// DP-402897 - Use the utility function
	Quit ##class(%DeepSee.Dashboard.Utils).%GetKpiFilterCaption(pKPIName,pSpec)
}

/// Transform a set of printing parameters that are compatible with the ZenReport-based
/// %DeepSee.UI.MDXPDF, %DeepSee.UI.ChartPDF, etc, into the parameters expected by the
/// %DeepSee.Component.deepseeSvgImageProvider
ClientMethod prepareSvgPrintParameters(parms) [ Internal, Language = javascript ]
{
	// Method added by DTB367
	var util = zen('svgUtil');
	if (parms.PAGESIZE) {
		var printPageUnit = parms.PAGESIZE.substring(parms.PAGESIZE.indexOf(' ')+1);
	}
	else {
		var printPageUnit = 'pt';
	}

	
	// DTB250 - This could all be configurable with Print Setup that has svg mode
	// DTB252 - Set print page defaults
	parms.marginLeft = (parms.MARGINLEFT) ? util.convertSizeToPoint(parms.MARGINLEFT + printPageUnit).value+'pt' : '36pt';
	parms.marginRight = (parms.MARGINRIGHT) ? util.convertSizeToPoint(parms.MARGINRIGHT + printPageUnit).value+'pt' : '36pt';
	parms.marginTop = (parms.MARGINTOP) ? util.convertSizeToPoint(parms.MARGINTOP + printPageUnit).value+'pt' : '36pt';
	parms.marginBottom = (parms.MARGINBOTTOM) ? util.convertSizeToPoint(parms.MARGINBOTTOM + printPageUnit).value+'pt' : '36pt';

	if (parms.PAGESIZE) {
		// DTB366
		var printPageSize = parms.PAGESIZE.substring(0,parms.PAGESIZE.indexOf(' '));

		if ('landscape'==parms.ORIENTATION) {
			parms.pageWidth = printPageSize.substring(printPageSize.indexOf('x')+1) + printPageUnit;
			parms.pageHeight = printPageSize.substring(0,printPageSize.indexOf('x')) + printPageUnit;
		}
		else {
			parms.pageWidth = printPageSize.substring(0,printPageSize.indexOf('x')) + printPageUnit;
			parms.pageHeight = printPageSize.substring(printPageSize.indexOf('x')+1) + printPageUnit;
		}
	}
	else {
		parms.pageWidth = '8.5in';
		parms.pageHeight = '11in';
	}
	
	// The foIntro is used to inject XSL-FO directives in the generated
	// stylesheet. Note the use of buildFOBlock() and buildFOTable() to
	// turn the JavaScript object abstractions into actual FO
	// source 
	
	// If there are preamble items, build fo blocks to represent them (per widget)
	if (parms.TITLE) {
		// DTB366
		var resolvedTitle = this.ResolveText(parms.TITLE)		// DTB555 - Resolve translated text from the client
		var printTitle = {caption:resolvedTitle,
				style:{
					fontWeight:"bold",
					fontSize:"12pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintTitle = util.buildFOBlock(printTitle);
	}
	if (('on' == parms.SUBTITLEON) && ('' != parms.SUBTITLE)) {
		// DTB366
		var resolvedSubtitle = this.ResolveText(parms.SUBTITLE)		// DTB555 - Resolve translated text from the client
		var printSubtitle = {caption:resolvedSubtitle,
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintSubtitle = util.buildFOBlock(printSubtitle);
	}
	if ('on' == parms.SHOWUSER) {
		// DTB366
		var printUser = {caption:zenPage.userName,
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintUser = util.buildFOBlock(printUser);
	}
	if ('on' == parms.SHOWDATE) {
		// DTB366
		var dateObj = new Date;
		var printDate = {caption:dateObj.toLocaleString(),
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintDate = util.buildFOBlock(printDate);
	}

	// If there are filters defined, construct the fo table to display the filter values
	var filterTableStyle = (parms.FILTERTABLESTYLE) ? util.parseCssStyleString(parms.FILTERTABLESTYLE) : {};
	
	// DTB405 - Add styling from the filter table style provided from Print Settings
	var filterTitle = {caption:$$$Text("Filter Values"),
				style:{
					backgroundColor:((filterTableStyle['background-color']) ? filterTableStyle['background-color'] :'#B9B9B9'),
					fontWeight:((filterTableStyle['font-weight']) ? filterTableStyle['font-weight'].trim() :'bold'),
					fontSize:((filterTableStyle['font-size']) ? util.convertSizeToPoint(filterTableStyle['font-size']).value+'pt' :'8pt'),
					textAlign:((filterTableStyle['text-align']) ? filterTableStyle['text-align'].trim() :"center"),
					padding:((filterTableStyle['padding']) ? util.convertSizeToPoint(filterTableStyle['padding']).value+'pt' :'2pt'),
					color:(filterTableStyle['color'] ? filterTableStyle['color'] : '') }
				};
	if (filterTableStyle['font-style']) {
		// DTB421 - Only set this attribute if there is a real value
		filterTitle.style.fontStyle = filterTableStyle['font-style'];
	}
	if (filterTableStyle['font-family']) {
		// DTB421 - Only set this attribute if there is a real value
		filterTitle.style.fontFamily = filterTableStyle['font-family'];
	}

	var postFilterSpacer = {caption:"",
				style:{padding:"2pt"}
				};
	 	
 	var foFilterTable = '';
 	if ((parms.filterTable)&&(parms.filterTable.rows)&&(parms.filterTable.rows.length)) {
	 	foFilterTable = util.buildFOBlock(filterTitle) +'\n'+
 					util.buildFOTable(parms.filterTable) +'\n'+
 					util.buildFOBlock(postFilterSpacer);
 	}

	// Construct the parameter object for generation of the source files
 	if (parms.printMultiple) {
		// Replace the overall report title with the dashboad name
	 	parms.title = zenPage.getDefinition().title;
	 	if (typeof foPrintTitle == 'undefined') {
		 	// If printing multiple, prepend the filter table with the widget's title
		 	// DTB366 - IF the Print Settings have not already created a title 
		 	// for this widget!
		 	var widgetTitle = {caption:this.getDefinition().title,
					style:{
						//backgroundColor:"#B9B9B9",
						fontWeight:"bold",
						fontSize:"8pt",
						textAlign:"left",
						padding:"2pt"}
					};
		 	var foPrintTitle = util.buildFOBlock(widgetTitle);
	 	}
 	}
 	
 	// DTB366 - Assemble foIntro items
	parms.foIntro = ((typeof foPrintTitle != 'undefined') ? foPrintTitle : '') +
	 				((typeof foPrintSubtitle != 'undefined') ? '\n' + foPrintSubtitle : '') +
	 				((typeof foPrintUser != 'undefined') ? '\n' + foPrintUser : '') +
	 				((typeof foPrintDate != 'undefined') ? '\n' + foPrintDate : '') +
	 				((typeof foFilterTable != 'undefined') ? '\n' + foFilterTable : '')		// DTB385 - Check for the correct item!
	 				;
 	// End foIntro
}

/// Client-visible wrapper for the <method>%ResolveText</method> method to translate title text.
Method ResolveText(pEncodedText) As %String [ ZenMethod ]
{
	// Method added by DTB555
	Set tText = ""
	Try {
		Set tText = ##class(%DeepSee.UserPortal.Utils).%ResolveText(pEncodedText)
	}
	Catch ex {
		Set tText = $system.Status.GetErrorText(ex.AsStatus())
	}
	Quit tText
}

}
