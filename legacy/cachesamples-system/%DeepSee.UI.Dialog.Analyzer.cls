/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Special version of the analyzer that runs within a dialog.
/// This is displayed when a user uses the Analyze option in a widget.
Class %DeepSee.UI.Dialog.Analyzer Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 1;

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "pivot";

/// If this page has "views", this is the current view type.
Property currViewMode As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTVIEWMODE} ];

/// Name of cube to explore.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Key (within its dashboard) of widget that launched this dialog.
Property widgetKey As %ZEN.Datatype.string(ZENURL = "KEY");

/// Name of saved pivotTable to view (overrides CUBE if present).
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOT");

/// If provided, use this name to save the pivot.
Property localPivotName As %ZEN.Datatype.string(ZENURL = "LOCALNAME");

/// If provided, state of filters on widget that launched this dialog.
Property filterState As %ZEN.Datatype.string(MAXLEN = 5000, ZENURL = "FILTERSTATE");

/// Description of the saved pivot (if any).
Property pivotDescription As %ZEN.Datatype.string;

/// Keywords of the saved pivot (if any).
Property pivotKeywords As %ZEN.Datatype.string;

/// If true, reset the data source when the dialog is applied.
Property resetData As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">

#body {
	overflow: hidden;
}

table.dsptcHeaderTable {
	font-size: 12px;
}

#table {
	border: 1px #808080 solid;
	background: #C0C0C0;
	width: 1100px;
	height: 550px;
	overflow: hidden;
}

#filterGroup {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	border: 1px solid gray;
	overflow: hidden;
	padding: 0px;
	color: #404040;
	vertical-align: middle;
	height: 42px;
}

.filterGroupCaption {
	font-size: 11px;
	font-weight: bold;
	color: #808080;
}

.iPivotTable {
	font-size: 1.2em;
}

select {
	font-size: 0.9em;
}

.iPivotDataTable {
	font-size: 1.2em;
}

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

.dynaTreeNode {
	white-space: nowrap;
	font-size: 10pt;
}

a.dynaTreeItem {
	color: rgb(71,72,67);
}

#groupTree {
	width: 250px;
	overflow-y: auto;
	overflow-x: auto;
	border: 1px solid black;
	background: white;
}

#dimTree {
	overflow: hidden;
	display: hidden;
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: darkblue;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	font-size: 10pt;
	font-weight: normal;
	color: gray;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: orange;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;"
import="%DeepSee.Component.pivotLevel,%DeepSee.Component.searchBox" >

<hgroup cellVAlign="top">
<spacer width="10"/>
<vgroup id="groupTree">
<dynaTree id="dimTree" 
 imageContracted="images/arrow1R.gif"
 imageExpanded="images/arrow1D.gif"
 imageNode="deepsee/ds2_brightness_44.png"
  ondblclick="zenPage.treeDoubleClick(zenThis);"
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="ppivotd" paramName="pivot" value="#(%page.pivotName)#" />
</dynaTree>
</vgroup>

<vgroup id="groupPivot">
<deepsee:pivotController id="pivotController" miniAnalyzer="1" pivotTableId="table" dropEnabled="true"/>
<hgroup id="filterGroup"  labelPosition="left" cellStyle="padding:2px;padding-right:4px;"></hgroup>
<hgroup cellVAlign="top">
<deepsee:pivotTable
	id="table"
	cubeName="#(%page.cubeName)#"
	dragEnabled="true"
	dropEnabled="true"
	showQuery="false"
	jsonRows="10"
	 >
</deepsee:pivotTable>

<vgroup id="chartGroup" cellVAlign="top">
<svgFrame id="svg" width="0" height="0" layout="vertical">
<barChart id="chart"  width="500" height="500" 
	appearance="2D" 
	controllerId="table" 
	 borderStyle="stroke:darkgray;"
	 onelementClick="zenPage.chartElementClick(chart);"
	selectedItemStyle="stroke:red;stroke-dasharray:0.5,0.5;"
	>
<xAxis majorGridLines="true" labelAngle="0"/>
<yAxis majorGridLines="true" labelAngle="0"/>
</barChart>
</svgFrame>
</vgroup>
</hgroup>
</vgroup>
</hgroup>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Analyzer")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Explore a DeepSee data model")
}

/// Provide contents of the dimension tree.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))
		Set tPivotName = $G(pParms("pivot"))

		If (tCube'="") {
			If (tPivotName'="") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tPivotName,.tSC)
				If $$$ISERR(tSC) Quit
				If $IsObject(tPivot) {
					// get local calc members
					For n = 1:1:tPivot.calculatedMembers.Count() {
						Set tCalcMbr = tPivot.calculatedMembers.GetAt(n)
						If ((tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
							Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName,tCalcMbr.valueExpression)
						}
					}

					// get local named sets
				}
			}
			Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tCube,.pTree,,,pRoot,.tCalcMbrs,.tNamedSets)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// Return flag if data source is reset
	return this.resetData;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var msg = this.SavePivotTable(this.resetData);
		if (msg!="") {
			alert(msg);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..dragAndDrop = 1

		// first check for named PIVOT
		If (..pivotName'="") {
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..pivotName,.tSC)
			If $$$ISERR(tSC) Quit
			If $IsObject(tPivot) {
				Set ..pivotName = tPivot.fullName
				Set ..cubeName = tPivot.cubeName
				Set ..pivotDescription = tPivot.description
				Set ..pivotKeywords = tPivot.keywords

				Set tTable = ..%GetComponentById("table")
				Set tSC = tPivot.%CopyToComponent(tTable)
				If $$$ISERR(tSC) Quit

				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("pivot",tPivot.fullName)
				If $$$ISERR(tSC) Quit

				// If there is a current filter state, add filters for it
				If (..filterState'="") {
					Set tFilterState = $ZCVT($TR(..filterState,$C(13),""),"I","URL")
					For f=1:1:$L(tFilterState,$C(10)) {
						Set tSpec = $P($P(tFilterState,$C(10),f),$C(9),1)
						Set tValue = $P($P(tFilterState,$C(10),f),$C(9),2)

						If ((tSpec'="")&&(tValue'="")) {
							Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
							If ($E(tValue,1,8)="%SEARCH.") {
								Set tLevel.spec = tValue
								Set tLevel.text = tValue
								Set tLevel.advanced = 1
							}
							Else {
								Set tLevel.spec = tSpec_"."_tValue
								Set tLevel.text = tValue
							}
							Set tLevel.transient = 1
							If $$$ISERR(tSC) Quit
							Do tTable.filters.Insert(tLevel)
							Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
						}
					}
				}
			}
		}

		If ('##class(%DeepSee.Utils).%CubeExists(..cubeName, .tSC)) {
			Set ..cubeName = ""
			Quit
		}
		Else {
			// Get original case of cube name
			Set ..cubeName = ##class(%DeepSee.Utils).%GetCubeName(..cubeName,.tSC)
		}

		Set tGroup = ..%GetComponentById("filterGroup")
		Set tTable = ..%GetComponentById("table")
		Set tSC = ##class(%DeepSee.UI.Analyzer).%CreateFilterControls(..cubeName,tGroup,tTable)
		If $$$ISERR(tSC) Quit

		// JMD1074: add reset button to dialog buttons
		Set tGroup = ..%GetComponentById("buttonHolder")
		Set tApply = ..%GetComponentById("btnApply")
		If ($IsObject(tGroup)&&$IsObject(tApply)) {
			Set tButton = ##class(%ZEN.Component.button).%New()
			Set tButton.caption = $$$Text("Reset","%DeepSee")
			Set tButton.title = $$$Text("Reset local data source","%DeepSee")
			Set tButton.controlClass="commandButton"
			Set tButton.onclick="zenPage.resetLocalDataSource();"
			Do tGroup.%AddChildBefore(tButton,tApply)

			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
			Set tSpacer.width = 20
			Do tGroup.%AddChildBefore(tSpacer,tApply)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User has double-clicked on an element in the tree control.
/// This is copied from the same method in the main Analyzer page.
ClientMethod treeDoubleClick(tree) [ Language = javascript ]
{
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);
	if (value && '' != value) {
		// check for special relationship marker
		if (value.toString().substr(0,2)=='@@') {
			return;
		}
		var pivot = this.getPivot();
		if (pivot) {
			pivot.pushState();
			var isNamedFilter = (value == '%FILTER');
			var isMsr = (value.substr(0,10).toUpperCase() == '[MEASURES]');
			if (isNamedFilter) {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.filters[pivot.filters.length] = parm;

				parm.spec = value;
				parm.text = text;
				parm.advanced = true;
			}
			else if (isMsr) {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.measures[pivot.measures.length] = parm;

				parm.spec = value;
				parm.text = text;
			}
			else {
				if (pivot.rowLevels.length == 0) {
					// append
					var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
					pivot.rowLevels[pivot.rowLevels.length] = parm;
				}
				else {
					var parm = pivot.rowLevels[pivot.rowLevels.length-1];
				}
				parm.spec = value;
				parm.text = text;
			}
			parm.drillLevel = pivot.getDrillLevel();
			if (pivot.isDrillThrough) {
				pivot.mdx = '';
				pivot.isDrillThrough = false;
			}
			pivot.selectedRange = '';
			pivot.executeQuery(true);
		}
	}
}

/// Return the current pivot table.
ClientMethod getPivot() [ Language = javascript ]
{
	return zen('table');
}

/// Adjust sizes of analyzer components on the page.
ClientMethod adjustSize() [ Language = javascript ]
{
	try {
		this.invokeSuper('adjustSize',arguments);
		
		var tree = zen('groupTree');
		var divTree = tree.getEnclosingDiv();

		var table = zen('table');
		var divTable = table.getEnclosingDiv();

		var ctrl = zen('pivotController');
		var divCtrl = ctrl.getEnclosingDiv();

		var filterGroup = zen('filterGroup');
		var divFilterGroup = filterGroup ? filterGroup.getEnclosingDiv() : null;

		// show tree
		divTree.style.display = '';

		// find size of window (in this case, display area)
		var body = zenPage.getComponentById('body');
		var divBody = body.getEnclosingDiv();
		var winHeight = divBody.offsetHeight;
		var winWidth = divBody.offsetWidth;
		var th = 0;

		var wx = winWidth - (25 + divTree.offsetWidth);
		wx = (wx < 0) ? 0 : wx;
		divCtrl.style.width = wx + 'px';
		var fgHgt = 0;
		if (divFilterGroup) {
			wx = winWidth - (25 + divTree.offsetWidth);
			wx = (wx < 0) ? 0 : wx;
			divFilterGroup.style.width = wx + 'px';
			fgHgt = divFilterGroup.offsetHeight;
		}

		if (divTable && divTree) {
			var svg = zen('svg');
			var svgDiv = svg.getEnclosingDiv();
			var chart = zen('chart');
			var svgWid = 0;
			var svgHgt = 0;
			var pivotWid = 0;
			var h = winHeight - (10 + th);
			h = (h < 0) ? 0 : h;

			switch(this.currViewMode) {
			case 'pivot':
				divTable.style.display = '';
				svgDiv.style.visibility = 'hidden';
				pivotWid = winWidth - (25 + divTree.offsetWidth);
				pivotWid = (pivotWid < 0) ? 0 : pivotWid;
				break;
			case 'chart':
				divTable.style.display = 'none';
				svgDiv.style.visibility = 'visible';
				pivotWid = 0;
				svgHgt = h - divCtrl.offsetHeight - fgHgt;
				svgHgt = (svgHgt < 0) ? 0 : svgHgt;
				svgWid = winWidth - (25 + divTree.offsetWidth);
				break;
			case 'both':
				divTable.style.display = '';
				svgDiv.style.visibility = 'visible';
				svgHgt = h - divCtrl.offsetHeight - fgHgt;
				svgHgt = (svgHgt < 0) ? 0 : svgHgt;
				svgWid = (winWidth - (25 + divTree.offsetWidth)) / 2;
				pivotWid = winWidth - (25 + divTree.offsetWidth) - svgWid;
				pivotWid = (pivotWid < 0) ? 0 : pivotWid;
				break;
			}

			svg.setProperty('height',svgHgt);
			svg.setProperty('width',svgWid);
			if (chart) {
				// make a good guess at chart size
				var chartWid = svgWid;
				var chartHgt = svgHgt;
				if (chartWid > (chartHgt*1.5)) {
					chartWid = chartHgt * 1.5;
				}
				if (chartHgt > (chartWid*1.5)) {
					chartHgt = chartWid * 1.5;
				}
				chartHgt = (chartHgt <= 0) ? 1 : chartHgt;
				chartWid = (chartWid <= 0) ? 1 : chartWid;
				chart.setProperty('height',chartHgt);
				chart.setProperty('width',chartWid);
			}
			divTable.style.width = pivotWid + 'px';
			var hx = (h - divCtrl.offsetHeight- fgHgt);
			hx = (hx < 0) ? 0 : hx;
			divTable.style.height = hx + 'px';
			divTree.style.height = h + 'px';
			table.adjustTableLayout();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSize');
	}
}

/// Save the pivot table.
Method SavePivotTable(pResetData As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// JMD1074
		If (pResetData) {
			If (..localPivotName'="") {
				// delete local copy
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..localPivotName)) {
					Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(..localPivotName)
					If $$$ISERR(tSC) Quit
				}
			}
		}
		Else {
			If (..localPivotName'="") {
				// create a new local copy
				// test for overwrite
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..localPivotName)) {
					Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(..localPivotName)
					If $$$ISERR(tSC) Quit
				}

				Set tPivot = ##class(%DeepSee.Dashboard.Pivot).%New()
				Set tPivot.fullName = ..localPivotName
			}
			Else {
				// save pivot
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..pivotName,.tSC)
				If '$IsObject(tPivot) {
					Set tPivot = ##class(%DeepSee.Dashboard.Pivot).%New()
				}
				If $$$ISERR(tSC) Quit
				Set tPivot.fullName = ..pivotName
			}

			Set tPivot.description = ..pivotDescription
			Set tPivot.keywords = ..pivotKeywords

			Set tTable = ..%GetComponentById("table")

			// Copy pivot settings into definition object
			Set tSC = tPivot.%CopyFromComponent(tTable)
			If $$$ISERR(tSC) Quit

			Set tSC = tPivot.%Save()
			If $$$ISERR(tSC) Quit

			If (..localPivotName="") {
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("folder",tPivot.folderName)
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Launch the cell format options dialog.
ClientMethod showFormatOptions() [ Language = javascript ]
{
	var table = this.getPivot();

	var parms = {
			COLORSCALE:table.colorScale
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CellFormatOptions.zen','CellFormatOptions','status=no,scrollbars=no,resizable,width=550,height=600',parms);
}

/// Called from client to update list of filters.
ClassMethod UpdateFilterControls(pCubeName As %String, pGroup As %ZEN.Component.group, pPivotTable As %DeepSee.Component.pivotTable) As %String [ ZenMethod ]
{
	Set tMsg = ""
	If ($IsObject(pPivotTable)) {
		Set tSC = ##class(%DeepSee.UI.Analyzer).%CreateFilterControls(pCubeName,pGroup,pPivotTable)
		If $$$ISERR(tSC) {
			Set tMsg = $System.Status.GetOneErrorText(tSC)
		}
	}
	Quit tMsg
}

/// User has changed a filter control value.
ClientMethod filterChangeHandler(ctrl, filterNo) [ Language = javascript ]
{
	var pivot = this.getPivot();
	if (pivot) {
		var filter = pivot.filters[filterNo-1];
		if (filter) {
			filter.key = ctrl.value;
			pivot.executeQuery(pivot.autoExecute);
		}
	}
}

/// Launch the show query dialog.
ClientMethod showQuery() [ Language = javascript ]
{
	var table = this.getPivot();
	var manualMode = (table && table.dataSource=='manual');
	if (table && (manualMode || ((''!=table.cubeName) && (''!=table.queryKey)))) {
		// JMD1031
		this._oldDataSource = table.dataSource;
		this._oldMDX = table.userMDX;
		var mdx = manualMode ? table.userMDX : table.GetCurrentQueryText();
		// + WAL075 -- use nonce
		var nonce = zenPage.CreateQueryNonce(mdx); 
		if (nonce.toString().indexOf('ERROR:')>=0) {
			// error
			alert(nonce);
			return;
		}
		var parms = {
			CUBE:this.cubeName,
			LISTINGNAME:table.listing,
			MANUAL:manualMode?1:0,
			NONCE:nonce
		};
		// - WAL075
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.ShowQuery.zen','Query','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

/// Launch the pivot options dialog.
ClientMethod showPivotOptions() [ Language = javascript ]
{
	var table = this.getPivot();

	var parms = {
			CUBE:this.cubeName,
			LISTING:table.listing,
			LISTINGROWS:table.listingRows,
			ROWTOTALS:table.rowTotals?1:0,
			COLUMNTOTALS:table.columnTotals?1:0,
			ROWTOTALAGG:table.rowTotalAgg,
			COLUMNTOTALAGG:table.columnTotalAgg,
			ROWTOTALSOURCE:table.rowTotalSource,
			ROWSPAN:table.rowLabelSpan?1:0,
			COLUMNSPAN:table.columnLabelSpan?1:0,
			ROWEMPTY:table.showEmptyRows?1:0,
			COLUMNEMPTY:table.showEmptyColumns?1:0,
			ROWSTYLE:table.rowHeaderStyle,
			COLUMNSTYLE:table.columnHeaderStyle,
			CELLSTYLE:table.cellStyle,
			CELLWIDTH:table.cellWidth,
			CELLHEIGHT:table.cellHeight,
			ZEBRA:table.showZebra?1:0,
			ROWCAPTION:table.showRowCaption?1:0
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotOptions.zen','PivotOptions','status=no,scrollbars=no,resizable,width=850,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'PivotOptions':
		var table = this.getPivot();
		table.executeQuery();
		break;

	case 'Query':
		// JMD1031
		var table = this.getPivot();
		if (table.dataSource!=this._oldDataSource || (table.dataSource=='manual'&&(table.userMdx!=this._oldMDX))) {
			if (table.dataSource!='manual') {
				table.cubeName = this.cubeName;
			}
			else {
				// JMD1453 remove filters so they don't get doubled up
				table.filters.length = 0;
				var msg = zenPage.UpdateFilterControls(table.cubeName,zen('filterGroup'),table);
				if (''!==msg) {
					alert(msg);
				}
			}
			table.executeQuery(true);
			table.updateController();
		}
		break;
	}
}

/// Drop down is about to appear for filter control.
ClientMethod filterDropDown(ctrl) [ Language = javascript ]
{
	try {
		// get list of current filter values
		// assume these are all from the same data source

		var specList = [];
		var keyList = [];

		var pivot = this.getPivot();
		if (pivot) {
			for (var n = 0; n < pivot.filters.length; n++) {
				var filter = pivot.filters[n];
				if (!filter.enabled) {
					// DTB164 - Ignore filters that are disabled
					continue;
				}
				
				if (filter && filter.key != '') {
					var spec = filter.spec;
					if (spec.toUpperCase().indexOf('.MEMBERS')!=-1) {
						// strip off .members
						var s = spec.split('.');
						s.length--;
						spec = s.join('.'); 
					}
					if (ctrl.filterName.toUpperCase() != spec.toUpperCase()) {
						specList[specList.length] = spec;
						keyList[keyList.length] = filter.key;
					}
				}
				else if (filter && (filter.spec != '')) {
					// DTB164 - Add JMD947: use advanced filters for restriction
					var spec = filter.spec.toString();
					while (spec.charCodeAt(spec.length-1)==10) {
						spec = spec.substr(0,spec.length-1);
					}
					if ((spec[0]=='{' && spec[spec.length-1]=='}')||(spec[spec.length-1]==')')) {
						specList[specList.length] = spec;
						keyList[keyList.length] = '';
					}
				}
			}
		}

		ctrl.relatedFilterSpecs = specList;
		ctrl.relatedFilterKeys = keyList;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in filterDropDown');
	}
	return true;
}

/// Reset the local data source for our widget.
ClientMethod resetLocalDataSource() [ Language = javascript ]
{
	this.resetData = true;
	this.dialogFinish();
}

/// Generate a nonce for an MDX query.
ClassMethod CreateQueryNonce(pQuery As %String) As %String [ Internal, ZenMethod ]
{
	// WAL075 added this method
	Quit ##class(%DeepSee.Utils).%CreateQueryNonce(pQuery)
}

}
