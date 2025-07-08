/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page provides a means of exploring the cube relationships that are defined on the system.
Class %DeepSee.UI.ModelBrowser Extends %DeepSee.UI.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Analytics Model Browser";

Parameter DOCBOOKID = "D2MODADV_rel_model_browser";

/// Id of current item in the diagram.
Property CurrItemId As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Id of last visited item in the diagram.
Property LastItemId As %ZEN.Datatype.string;

/// Color of the previously selected node
Property LastColor As %String [ InitialExpression = "#A0FFB0;" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenLabelDisabled {
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

.dynaTreeItem {
	color: rgb(71,72,67);
}

.detailLabel {
	font-weight: bold;
	color: rgb(71,72,67);
	font-size: 10pt;
}

#editorPane {
	position: relative;
}

#modelTableHeader {
	height: 40px;
	top: 0px;
	background: #F0F0F0;
	overflow: hidden;
}

#modelTableBody {
	top: 40px;
	height: 200px;
	border: 1px solid gray;
	overflow: auto;
	background: white;
}

#tree {
	background: white;
	width: 200px;
	overflow: auto;
	border-top: 1px solid gray;
	border-bottom: 1px solid gray;
}

#propertyPane {
	position: relative;
	background: rgb(156,154,141);
	height: 449px;
	width: 350px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
}

/* styles for tabs */
#tabDetails,#tabTools {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

td.tabGroupButtonOff:hover {
	color: #FFEEAA;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 300px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn:not([ie]) {
	background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}
td.tabGroupButtonOff:hover {
	background: #C0C0C0;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}

#propertyTitle {
	height: 40px;
	width: 40px;
}

#spanArrow {
	padding-left: 10px;
	color: white;
	font-size: 20pt;
	text-shadow: black 1px 1px 1px;
}

#propertyCommands {
	color: white;
}

table.modelTable {
	background: white;
	width: 100%;
	font-size: 10pt;
}

table.modelTable td {
	padding: 2px;
	border-bottom: 1px solid rgb(241,240,231);
}

.modelError {
	color: #404040;
	font-size: 24px;
	padding: 10px;
	background: lightgray;
}

span.selector {
	visibility: hidden;
}

.modelRowGroupsSelected span.selector,
.modelRowGroupSelected span.selector,
.modelRowGroupCubeSelected span.selector,
.modelRowSASelected span.selector,
.modelRowGroupSelected span.selector {
	visibility: visible;
}
.modelRowGroups {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.modelRowGroupsSelected {
	font-size: 1.2em;
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowGroup {
	color: rgb(67,67,67);
	font-weight: bold;
	background: #F0F0FF;
}
.modelRowGroupSelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowGroupCube {
	color: rgb(67,67,67);
	font-weight: bold;
}
.modelRowGroupCubeSelected {
	color: white;
	font-weight: bold;
	background: rgb(53,107,141);
}
.modelRowGroup {
	color: rgb(67,67,67);
}
.modelRowGroupSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowSA {
	font-style: italic;
	color: rgb(67,67,67);
}
.modelRowSASelected {
	font-style: italic;
	color: white;
	background: rgb(53,107,141);
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: #3b84bc;
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
	color: #98923a;
}

</style>
}

XData SVGStyle
{
<style type="text/css">
.rnavBackground {
	fill: #E0E0E0;
	stroke: none;
}

.rnavTitle {
	fill: black;
	stroke: none;
	font-size: 2pt;
	font-weight: bold;
	font-family: tahoma;
}

/* label for node */
.rnavLabel {
	fill: black;
	fill-opacity: 0.8;
	stroke: none;
	font-size: 1.5pt;
}

.rnavLabelHilight {
	fill: #004080;
	stroke: none;
	font-size: 1.4pt;
	font-weight: bold;
}

.rnavConnector {
	fill: none;
	stroke: black;
	stroke-width: 0.5;
}

.rnavHub {
	stroke: black;
	stroke-width: 0.5;
	fill: #FFFF80;
}
.rnavHubHilight {
	stroke: black;
	stroke-width: 0.5;
	fill: #004080;
}

.rnavHubSelected {
	stroke: blue;
	stroke-width: 0.5;
	fill: yellow;
}

.rnavNode {
	stroke: black;
	stroke-width: 0.5;
	fill: #80C0FF;
}

.rnavNodeHilight {
	stroke: black;
	stroke-width: 0.5;
	fill: #004080;
}

.rnavNodeSelected {
	stroke: blue;
	stroke-width: 0.5;
	fill: yellow;
}

.slider-body {
	stroke-width: 1px;
	stroke: black;
	fill: darkgray;
	opacity: 0.30;
}

</style>
}

/// This Style block contains page-specific CSS style definitions.
XData CSS3Style
{
<style type="text/css">

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenLabelDisabled {
	font-size: 10pt;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

.dynaTreeNode {
	font-size: 10pt;
	white-space: nowrap;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}

.detailLabel {
	color: rgb(71,72,67);
	font-size: 10pt;
	font-weight: bold;
}

#editorPane {
	position: relative;
}

#modelTableHeader {
	background: #F0F0F0;
	height: 40px;
	top: 0px;
	overflow: hidden;
}

#modelTableBody {
	background: white;
	border: 1px solid gray;
	height: 200px;
	top: 40px;
	overflow: auto;
}

#tree {
	background: white;
	border-top: 1px solid gray;
	border-bottom: 1px solid gray;
	overflow: auto;
	width: 250px;
}

#propertyPane {
	background: rgb(156,154,141);
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
	height: 449px;
	position: relative;
	width: 350px;
}

/* styles for tabs */
#tabDetails,#tabTools {
	color: #404040;
	padding-left: 3px;
	overflow: auto;
}

td.tabGroupButtonOff:hover {
	color: #FFEEAA;
}

.tabGroupBody {
	background: #E0E0D0;
	min-height: 300px;
	width: 399px;
}

td.tabGroupButtonOn {
	color: #404040;
	background: #E0E0D0;
	background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
	height: 30px;
	font-size: 10pt;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	background: #C0C0C0;
	background-image: none;
	background-repeat: repeat-x;
	color: #404040;
	font-size: 10pt;
	height: 30px;
}
td.tabGroupButtonOff:hover {
	background: #C0C0C0;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}
.tabGroupGap {
	width: 0px;
}
#propertyTitle {
	height: 40px;
	width:  40px;
}
#spanArrow {
	color: white;
	font-size: 20pt;
	padding-left: 10px;
	text-shadow: black 1px 1px 1px;
}
#propertyCommands {
	color: white;
}
table.modelTable {
	background: white;
	font-size: 10pt;
	width: 100%;
}
table.modelTable td {
	border-bottom: 1px solid rgb(241,240,231);
	padding: 2px;
}
.modelError {
	background: lightgray;
	color: #404040;
	font-size: 24px;
	padding: 10px;
}
span.selector {
	visibility: hidden;
}
.modelRowGroups {
	background: #D0D0FF;
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
}
.modelRowGroupsSelected {
	background: rgb(53,107,141);
	color: white;
	font-size: 1.2em;
	font-weight: bold;
}
.modelRowGroup {
	background: #F0F0FF;
	color: rgb(67,67,67);
	font-weight: bold;
}
.modelRowGroupSelected {
	background: rgb(53,107,141);
	color: white;
	background: rgb(53,107,141);
	font-weight: bold;
}
.modelRowGroupCube {
	color: rgb(67,67,67);
	font-weight: normal;
}
.modelRowGroupCubeSelected {
	background: rgb(53,107,141);
	color: white;
	font-weight: bold;
}
.modelRowGroup {
	color: rgb(67,67,67);
}
.modelRowGroupSelected {
	background: rgb(53,107,141);
	color: white;
}

.hdrLink {
	color: #3b84bc;
	font-size: 10pt;
	font-weight: normal;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	color: gray;
	font-size: 10pt;
	font-weight: normal;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: #98923a;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="Analytics Model Browser" >

<hgroup>

<vgroup width="100%" >
<hgroup width="100%" cellVAlign="top" cellAlign="left" >
<pane id="svgContent" paneName="svgContent" />
<spacer width="20px" />
<vgroup>
<spacer height="10px"/>
<combobox id="cubeList" onchange="zenPage.selectCube(zenThis.getValue());" width="300" size="50"/>
<spacer height="10px" />
<pane id="cubeElements" paneName="cubeElements" />
</vgroup>
</hgroup>
</vgroup>

</hgroup>

</pane>
}

XData svgContent [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
  <svgFrame id="svgFrame" layout="horizontal" width="850" height="800" backgroundStyle="fill: #E0E0E0;" >
   <slider id="zoomLevel" hidden="false" position="fixed" constrained="true"
  	x="15" y="-10" rangeLower="0" rangeUpper="12" height="230" width="23"
	 tickMarks="12" value="4" onchange="zenPage.sliderChange(zenThis);"/>
	 <svgSpacer width="20"/>
	<radialNavigator id="navigator" width="800" height="800" onselectNode="zenPage.selectNode(zenThis)" />
	</svgFrame>
  </pane>
}

XData cubeElements [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup id="treeWrapper">
<dynaTree id="dimTree"
dragEnabled="false"
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
showLines="false" showFolders="false"
OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="cube" value="#(%page.CurrItemId)#" />
</dynaTree>
</vgroup>

</pane>
}

/// sliderChange
/// User has moved the zoom slider.
ClientMethod sliderChange(slider) [ Language = javascript ]
{
	try {
		var svg = zen('svgFrame');

		// Set the zoom level to the current slider value.
		svg.setZoomIndex(slider.value);
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// selectCube
/// User has selected a new cube from the combobox
ClientMethod selectCube(value) [ Language = javascript ]
{
	try {
		//alert(combo.getValue());
		var node = zen('navigator');
		this.CurrItemId = value;
		//var rc = this.DrawDiagram(combo.getValue(),'');
		this.updateDiagram(node);
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// selectNode
/// Callback for handling selection of a new node
ClientMethod selectNode(node) [ Language = javascript ]
{
	try {
		// If the hub is selected, just quit
		if (node.getCurrNode()==null) {
			return;
		}
		
		// Save previous and current cube ID
		this.LastItemId = this.CurrItemId;
		this.CurrItemId = node.getCurrNode().getProperty('value');
		
		//Make sure to update the combobox
		var combo = zen('cubeList');
		combo.setValue(node.getCurrNode().getProperty('value'));
		zenPage.selectCube(combo.getValue());
	
		// Update the diagram
		this.updateDiagram(node);		
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod updateDiagram(node) [ Language = javascript ]
{
	try {
		// Remove current child nodes
		var numNodes = node.nodes.length
		for(i=0;i<numNodes;i++) {
			zenPage.removeChild(node.nodes[i]);
		}
		node.clearNodes();
	
		// Force diagram to be redrawn with new cube at the center	
		rc = this.DrawDiagram(this.CurrItemId, this.LastItemId);
		node.renderContents();
		
		// Update the cube dimensions
		zen('dimTree').refreshContents();
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Draw the diagram
/// Return a string to force synchronous call from the client
Method DrawDiagram(pID As %String, pLastID As %String) As %String [ ZenMethod ]
{
	Try {
		// Construct the model
		Set sc = ..CreateModel(pID, .tModel)
	
		// Draw the model
		Set sc = ..DrawModel(.tModel, pLastID)		
	}
	Catch(ex) {
		&js<alert('Error in Server method:\n#($ZCVT(ex.DisplayString(),"O","JS"))#');>
	}
	Quit "OK"
}

/// Create an array that describes the model to be diagrammed.
/// model is of the form:<br>
/// 		model("id") = cube name<br>
/// 		model("Name") = cube caption<br>
/// 		model("ch",n) = ""<br>
/// 		model("ch",n,"id") = child cube name<br>
/// 		model("ch",n,"label") = child cube caption<br>
Method CreateModel(pID As %String, Output pModel) As %Status
{
	#define CubeBrowser	^DeepSee.CubeBrowser

	#; if no id, find first item and use that
	If (pID = "") {
		Set pID = $O($$$CubeBrowser(""))
	}

	#; make sure id exists
	If '$D($$$CubeBrowser(pID)) {
		Quit $$$ERROR($$$CubeIdLoadFail,pID)
	}
	
	#; top node
	Set pModel("id") = pID
	Set pModel("Name") = $lg($$$CubeBrowser(pID),2)
	
	#; child nodes: walk down $$$CubeBrowser global
	Set n = 0
	Set key = $O($$$CubeBrowser(pID,""))
	While (key '= "") {
		Set n = n + 1
		Set pModel("ch",n) = ""
		Set pModel("ch",n,"id") = key

		Set cubeCaption=$lg($$$CubeBrowser(key),2)
		Set pModel("ch",n,"label") = cubeCaption

		#; how many connections does this item have?
		Set c = 0
		Set k2 = $O($$$CubeBrowser(key,""))
		While (k2 '= "") {
			Set c = c + 1
			Set k2 = $O($$$CubeBrowser(key,k2))
		}

		//Set:c>1 
		Set pModel("ch",n,"count") = c

		Set key = $O($$$CubeBrowser(pID,key))
	}
	Quit $$$OK
}

/// DrawModel
/// Method that sets the properties of the radialNavigator and
/// adds child nodes to the navigator<br>
/// If pLastID is not empty, the previously selected node will be filled in using LastColor;
Method DrawModel(ByRef pModel, pLastID As %String = "") As %Status
{
	Try {
		Set sc = $$$OK
		
		#; get size of model (number of children)
		Set tSize = $O(pModel("ch",""),-1)

		// Add nodes to the navigator
		#dim navigator As %ZEN.SVGComponent.radialNavigator
		Set navigator = %page.%GetComponentById("navigator")
		Set navigator.mainLabel = $G(pModel("Name"))_" ("_+tSize_") "
	
		#; related items
		If (tSize > 0) {
			For n = 1:1:tSize {
				Set id = $G(pModel("ch",n,"id"))
				Set label = $G(pModel("ch",n,"label"))
				
				Set node = ##class(%ZEN.Auxiliary.radialNode).%New()
				Set node.caption = label _ " ("_$G(pModel("ch",n,"count"))_")"
				Set node.value = $G(pModel("ch",n,"id"))
				Set node.id = "node"_n
			
				If (pLastID = id) {
					Set node.style = node.style_"fill: "_..LastColor
				}
			
				Set sc = navigator.nodes.Insert(node)
				Quit:$$$ISERR(sc)
			
				Set sc = ..%AddChild(node)
				Quit:$$$ISERR(sc)
			}
		}
	}
	Catch(ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Build sample data for the browser based on all the cubes in this namespace
/// Note that this does not include subject areas<br><br>
Method BuildData() As %Status
{
	#define CubeBrowser	^DeepSee.CubeBrowser

	Try {
		Set tSC = $$$OK
		
		#; we will create a multi-dimensional array to hold related cubes
		#; kill old data
		Kill $$$CubeBrowser
	
		#; create list of cubes
		#; include only concrete (non-abstract) cubes
		//Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(,.pMetaData,.pData,"cubes",1)
		Set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tCubeList,"cubes",1)
		Set tCube="",tCount=0
		
		Set tCube=$O(tCubeList(""))
		While tCube'="" {
			Set tData = tCubeList(tCube)
			// Standardize the cube reference IDs by always making them uppercase
			// DTB1134 - Use the logical cube identifier if $LG(tData,1) is null
			Set tName = $S(($LG(tData,1)'=""):$$$UPPER($LG(tData,1)),1:$$$UPPER(tCube))
			Set $LI(tData,1) = tName
			
			Set tCount = tCount + 1
			Set tCubeList(tName) = tCount
			Set tCubeIndex(tCount) = tName 
		
			#; Store cube info in global
			Set $$$CubeBrowser(tName) = tData
			
			Set tCube=$O(tCubeList(tCube))
		}
	
	
		#; create connections
		// This doesn't work for cubes that inheritFrom other cubes and the base cubes have relationships!
		Set n=""
		For {
			Set n = $O(tCubeIndex(n),1,tFromName)
			Quit:(n="")
			
			Set cubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tFromName,.tSC)
			Quit:$$$ISERR(tSC)
			Set model = $Classmethod(cubeClass,"%GetModel")
			Continue:(model=$$$NULLOREF)		// DTB1134 - Skip this cube if the ID resulted in no model loaded

			Set tSC = model.%ApplyOverrides($Name(^DeepSee.Overrides))		// DTB621
			Quit:$$$ISERR(tSC)
			Set relcount = model.relationships.Count()
			For i=1:1:relcount {
				set tToName = $$$UPPER(model.relationships.GetAt(i).relatedCube)
				If ('model.relationships.GetAt(i).disabled) &&
						##class(%DeepSee.Utils).%CubeExists(tToName) &&		// DTB674 - Check for existence of both cubes
						##class(%DeepSee.Utils).%CubeExists(tFromName) {
					// DTB383 - Only add enabled relationships to the browser index
					set $$$CubeBrowser(tFromName,tToName)=""
					set $$$CubeBrowser(tToName,tFromName)=""
				}
			}
			
			#; If this cube is inherited, look at the base cube's relationships
			/*
			If (model.inheritsFrom '= "") {
				Set baseCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(model.inheritsFrom)
				Set baseModel = $ClassMethod(baseCubeClass,"%GetModel")
				Set relCount = baseModel.relationships.Count()
				For i=1:1:relCount {
					Set tTo = baseModel.relationships.GetAt(i).relatedCube
					Set $$$CubeBrowser(tFromName,tTo)=""
					Set $$$CubeBrowser(tTo,tFromName)=""
				}
			}
			*/
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "Model Browser"
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC=##super()
	Quit:$$$ISERR(tSC)
	
	// Standardize the cube reference IDs by always making them uppercase
	Set ..CurrItemId = $$$UPPER(..CurrItemId)
	
	Set tSC = ..BuildData()
	
	If (..CurrItemId="")||'$D(^DeepSee.CubeBrowser(..CurrItemId)) {
		Set ..CurrItemId = $O(^DeepSee.CubeBrowser(""))
	}

	Do ..DrawDiagram(..CurrItemId,..LastItemId)
	
	Set tSC = ..PopulateCubeDropDown()
	
	Quit tSC
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit ..#PAGENAME
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%GetPageName()

	Quit $$$OK
}

/// Provide contents of the dimension tree.
Method GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))

		Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tCube,.pTree,,,pRoot,.tCalcMbrs,.tNamedSets)
		If $$$ISERR(tSC) Quit
		
		/*
		// Set all identifiers (second list item) to "" to prevent draggability 
		Set tIndex = $O(pTree(""))
		While tIndex'="" {
			Set $LI(pTree(tIndex),2)=""
			Set tIndex = $O(pTree(tIndex))
		}
		*/
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method PopulateCubeDropDown() As %Status
{
	Try {
		Set sc = $$$OK
		
		Set combo = %page.%GetComponentById("cubeList")
		
		//Set sc = ##class(%DeepSee.Utils).%GetCubeList(.pData,"cubes",1)
		//Quit:$$$ISERR(sc)
		Merge tData = ^DeepSee.CubeBrowser 
		
		Set tCube="" 
		Set tCube = $O(tData(""))
		While tCube'="" {
			Set tCubeName = $S(($LG(tData(tCube),2)'=""):$LG(tData(tCube),2),1:tCube)		// DTB1134 - Default to the cube ID
			Set tNameArray(tCubeName) = tCube
			
			Set tRelated = $O(tData(tCube,""))
			While tRelated '="" {
				Set tRelatedName = $S(($LG(tData(tRelated),2)'=""):$LG(tData(tRelated),2),1:tRelated)		// DTB1134 - Default to the related cube ID
				Set tNameArray(tCubeName,tData(tRelated)) = ""
				Set tRelated = $O(tData(tCube,tRelated))
			}
			Set tCube = $O(tData(tCube))
		}		
		
		Set tCubeName="",tCount=0
		Set tCubeName = $O(tNameArray("")) 
		While tCubeName'=""  {
			Set tRelCount = 0
			
			Set tIndex = $O(tNameArray(tCubeName,""))
			While tIndex '="" {
				Set tRelCount = tRelCount + 1
				Set tIndex = $O(tNameArray(tCubeName,tIndex))
			}
			
			Set tCube = $G(tNameArray(tCubeName))
			Set name = $LG(tData(tCube),1)
			Set display = tCubeName_" ("_tRelCount_")"
			
			Set option = ##class(%ZEN.Auxiliary.option).%New()
			Set option.value = name
			Set option.text = display
			
			Set sc = %page.%AddChild(option)
			Set sc = $$$ISERR(sc)
			
			Set sc = combo.options.Insert(option)
			Quit:$$$ISERR(sc)
			
			Set tCubeName = $O(tNameArray(tCubeName))
		}
		Set combo.value = ..CurrItemId
	}
	Catch(ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Subclass need to include the case "switchNamespace" if it is enabling "Switch" next to namespace.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}	
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.ModelBrowser.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	}
}

}
