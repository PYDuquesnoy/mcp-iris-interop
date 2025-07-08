/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This dialog lets the user create or edit an Advanced filter definition for a DeepSee pivot.<br/>
/// This can also be used to create or edit a Named Filter for a DeepSee Subject Area.
Class %DeepSee.UI.Dialog.AdvancedFilter Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 1;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Initial filter expression.
Property expression As %ZEN.Datatype.string(ZENURL = "EXPRESSION");

/// List of possible filter (cube element) names (captions).
Property filterNames As %ZEN.Datatype.string;

/// List of possible filter (cube element) values.
Property filterValues As %ZEN.Datatype.string;

/// List of possible filter (cube element) types.
Property filterTypes As %ZEN.Datatype.string;

/// List of possible filter (cube element) subtypes (measures only)
Property filterMsrTypes As %ZEN.Datatype.string;

/// Index of current item.
Property selectedIndex As %ZEN.Datatype.integer;

/// Current search Key
Property searchKey As %ZEN.Datatype.string;

/// If true, this is a Named Filter
Property isNamedFilter As %ZEN.Datatype.boolean(ZENURL = "NAMEDFILTER");

/// For named filters, this is the filter name.
Property filterName As %ZEN.Datatype.string(ZENURL = "FILTERNAME");

XData CSS3Style
{
<style type="text/css">

#ruleCommandsBody select {
	width: 200px;
}

#ruleCommandsBody select option {
	background-color: #FFFFFF;
}

#ruleCommandsBody select option:nth-of-type(odd) {
	background-color: #F8F8F8;
}


#mainGroup {
	opacity: 0.0;
	transition-property: opacity;
	transition-duration: 0.5s;
	transition-timing-function: ease;
}

#leftGroup {
	background: -moz-linear-gradient(-45deg,  #ffffff 0%, #f3f3f3 50%, #ededed 51%, #ffffff 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, right bottom, color-stop(0%,#ffffff), color-stop(50%,#f3f3f3), color-stop(51%,#ededed), color-stop(100%,#ffffff)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* Chrome10+,Safari5.1+ */
	background: linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* W3C */
}

#ruleCommands {
	border-top: 1px solid gray;
	border-left: 1px solid gray;
	border-right: 1px solid gray;
	background: none;
	font-family: arial;
	color: #404040;
	overflow: auto;
	width: 240px;
	height: 300px;
}

#ruleCommandsSearchBox {
	padding:8px;
}

#ruleHelp {
	border-bottom: 1px solid gray;
	border-left: 1px solid gray;
	border-right: 1px solid gray;
	background: none;
	font-family: arial;
	color: #404040;
	overflow: hidden;
	width: 240px;
	position: relative;
}

.ruleHelpBoxOuter {
	width: 100%;
	height: 100%;
	overflow: hidden;
	position: relative;
}

.ruleHelpBoxInner {
	position: absolute;
	top: 10px;
	bottom: 10px;
	left: 10px;
	right: 10px;
	overflow: auto;
	border: 1px solid gray;
	background: white;
	color: #404040;
	font-family: arial;
	font-size: 12px;
	padding: 5px;
	line-height: 140%;
	border-radius: 5px;
}

#ruleTree {
	border: 1px solid gray;
	background: #F0F0F0;
	font-family: arial;
	color: #404040;
	overflow: auto;
}

.EmptyMsg {
	padding: 10px;
	color: #804040;
	font-size: 20pt;
}

input.optButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
	border: 1px solid #808080;
	border-radius: 4px;
}

input.optButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}

input.optButtonRemove {
	background: rgb(141,53,53);
	color: #E0E0E0;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
	border: 1px solid #808080;
	border-radius: 4px;
}

input.optButtonRemove:hover {
	background: rgb(141,53,53);
	color: white;
	background-image: url(portal/button_red_hover.png);
	background-repeat: repeat-x;
}

input.optButton:focus,
input.optButtonRemove:focus {
	outline: none;
}

input.optButton:active,
input.optButtonRemove:active {
	text-shadow: 2px 2px 8px white, -2px -2px 8px white;
}

input.optButtonDisabled {
	background: gray;
	color: darkgray;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
	border: 1px solid #404040;
	border-radius: 4px;
}

div.commandTitle {
	width: 100%;
	text-align: center;
	background: rgb(53,107,141);
	color: white;
	padding-top: 3px;
	padding-bottom: 6px;
	overflow: hidden;
	font-weight: bold;
	border-bottom: 1px solid silver;
}

div.searchTitle {
	font-size: 10px;
}

div.commandTitleHeading {
	font-size: 10px;
}

div.commandTitleMain {
}

div.commandOptions {
	width: 100%;
	text-align: center;
	padding-top: 3px;
	padding-bottom: 3px;
	overflow: hidden;
}

div.CommandOptionCurr, div.CommandOption {
	float: left;
	padding: 3px;
	color: black;
	background: white;
	margin-left: 4px;
	border: 1px solid black;
	border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
	min-width: 20px;
	font-size: 14px;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	-ms-transition-property: background;
	-ms-transition-duration: 0.5s;
	-ms-transition-timing-function: ease;
}

div.CommandOptionCurr:hover,
div.CommandOption:hover {
	background: #FFEEAA;
}

div.CommandOptionCurr:active,
div.CommandOption:active {
	text-shadow: 2px 2px 10px #D0D0D0, -2px -2px 20px #808080;
}

div.CommandOptionCurr {
	color: black;
	font-weight: bold;
	background: #80F040;
	background: yellow;
	cursor: pointer;
}

div.CommandOption {
	color: black;
	background: #D0D0D0;
	cursor: pointer;
}

table.logicTable {
}

table.opTable {
}

.itemSelected,
.memberSelector,
.measureSelector,
.keySelector,
.literalSelector,
.operatorSelector,
.measureOperatorSelector,
.logicSelector {

	text-align: center;
	cursor: pointer;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
	min-width: 30px;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
	-ms-transition-property: background;
	-ms-transition-duration: 0.5s;
	-ms-transition-timing-function: ease;
}

.itemSelected {
	border: 1px solid rgb(53,107,141);
	font-size: 16px;
	padding: 4px;
	border-radius: 5px;
	box-shadow: 2px 2px 4px #808080;
	background: rgb(53,107,141);
	background: yellow;
	color: black;
}

.memberSelector,
.measureSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: white;
}

.keySelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #F0FFD8;
}

.literalSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #F0FFD8;
}

.operatorSelector,
.measureOperatorSelector,
.logicSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #D0D0F0;
}

.itemSelected:hover,
.memberSelector:hover,
.measureSelector:hover,
.keySelector:hover,
.literalSelector:hover,
.operatorSelector:hover,
.measureOperatorSelector:hover,
.logicSelector:hover {
	background: #FFEEAA;
}

.itemSelected:active,
.memberSelector:active,
.measureSelector:active,
.keySelector:active,
.literalSelector:active,
.operatorSelector:active,
.measureOperatorSelector:active,
.logicSelector:active {
	text-shadow: 2px 2px 10px #D0D0D0, -2px -2px 20px #808080;
}

</style>
}

XData Style
{
<style type="text/css">

#ruleCommandsBody select {
	width: 200px;
}

#mainGroup {
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

#leftGroup {
	background: #ffffff; /* Old browsers */
	background: -moz-linear-gradient(-45deg,  #ffffff 0%, #f3f3f3 50%, #ededed 51%, #ffffff 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, right bottom, color-stop(0%,#ffffff), color-stop(50%,#f3f3f3), color-stop(51%,#ededed), color-stop(100%,#ffffff)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* IE10+ */
	background: linear-gradient(-45deg,  #ffffff 0%,#f3f3f3 50%,#ededed 51%,#ffffff 100%); /* W3C */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#ffffff',GradientType=1 ); /* IE6-9 fallback on horizontal gradient */
}

#ruleCommands {
	border-top: 1px solid gray;
	border-left: 1px solid gray;
	border-right: 1px solid gray;
	background: none;
	font-family: arial;
	color: #404040;
	overflow: auto;
	width: 240px;
	height: 300px;
}

#ruleCommandsSearchBox {
	padding:8px;
}

#ruleHelp {
	border-bottom: 1px solid gray;
	border-left: 1px solid gray;
	border-right: 1px solid gray;
	background: none;
	font-family: arial;
	color: #404040;
	overflow: hidden;
	width: 240px;
	position: relative;
}

.ruleHelpBoxOuter {
	width: 100%;
	height: 100%;
	overflow: hidden;
	position: relative;
}

.ruleHelpBoxInner {
	position: absolute;
	top: 10px;
	bottom: 10px;
	left: 10px;
	right: 10px;
	overflow: auto;
	border: 1px solid gray;
	background: white;
	color: #202020;
	font-family: arial;
	font-size: 14px;
	padding: 5px;
	line-height: 150%;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
}

#ruleTree {
	border: 1px solid gray;
	background: #F0F0F0;
	font-family: arial;
	color: #404040;
	overflow: auto;
}

.EmptyMsg {
	padding: 10px;
	color: #804040;
	font-size: 20pt;
}

input.optButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
}

input.optButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}

input.optButtonRemove {
	background: rgb(141,53,53);
	color: #E0E0E0;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
}

input.optButtonRemove:hover {
	background: rgb(141,53,53);
	color: white;
	background-image: url(portal/button_red_hover.png);
	background-repeat: repeat-x;
}

input.optButtonDisabled {
	background: gray;
	color: darkgray;
	padding-top: 2px;
	padding-bottom: 2px;
	width: 180px;
}

div.commandTitle {
	width: 100%;
	text-align: center;
	background: rgb(53,107,141);
	color: white;
	padding-top: 3px;
	padding-bottom: 6px;
	overflow: hidden;
	font-weight: bold;
	border-bottom: 1px solid silver;
}

div.searchTitle {
	font-size: 10px;
}

div.commandTitleHeading {
	font-size: 10px;
}

div.commandTitleMain {
}

div.commandOptions {
	width: 100%;
	text-align: center;
	padding-top: 3px;
	padding-bottom: 3px;
	overflow: hidden;
}

div.CommandOptionCurr, div.CommandOption {
	float: left;
	padding: 3px;
	color: black;
	background: white;
	margin-left: 4px;
	border: 1px solid black;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
}

div.CommandOptionCurr {
	color: black;
	font-weight: bold;
	background: #80F040;
	background: yellow;
}

div.CommandOption {
	color: black;
	background: #D0D0D0;
}

table.logicTable {
}

table.opTable {
}

.itemSelected {
	border: 2px solid rgb(53,107,141);
	font-size: 16px;
	padding: 4px;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: rgb(53,107,141);
	color: white;

	background: yellow;
	color: black;
	text-align: center;
}

.memberSelector,
.measureSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #F9F9F9;
	background: white;
	text-align: center;
}

.keySelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #FFF0F0;
	background: #F0FFD8;
	text-align: center;
}

.literalSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #F9F9F9;
	background: #F0FFD8;
	text-align: center;
}

.operatorSelector,
.measureOperatorSelector,
.logicSelector {
	border: 1px solid gray;
	font-size: 16px;
	padding: 4px;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	box-shadow: 2px 2px 2px #808080;
	background: #F0D8FF;
	background: #D0D0F0;
	text-align: center;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<!-- contains the list of members for a given element -->
<jsonProvider id="memberList" OnGetArray="GetMemberList">
<parameter id="pCube" paramName="cube"/>
<parameter id="pDimension" paramName="dimension"/>
<parameter id="pSearch" paramName="search"/>
</jsonProvider>

<!-- contains the parse tree for the filter expression -->
<jsonProvider id="filterGraph" OnGetArray="BuildFilterGraph">
<parameter id="fCube" paramName="cube"/>
<parameter id="fExpression" paramName="expression"/>
</jsonProvider>

<hgroup id="namedFilterGroup" hidden="true" cellVAlign="top">
<text id="ctrlFilterName" label="Filter Name" size="40"/>
<spacer width="10"/>
<text id="ctrlFilterTooltip" label="Description" size="40"/>
</hgroup>

<hgroup cellVAlign="top" id="mainGroup">
<vgroup id="leftGroup">
<group id="ruleCommands" layout="none">
<html id="ruleCommandsHeader"/>
<html id="ruleCommandsBody"/>

<group id="ruleCommandsSearchBox" layout="none">
<hgroup cellVAlign="top" label="Select a value">
<radioButton name="type" id="rbFilter" optionValue="filter" onclick="zenPage.rbChanged();" />
<deepsee:searchBox id="controlFilter" size="25" multiSelect="false" onchange="zenPage.rbChanged();" onrefresh="zenPage.verifySearchBox();"/>
</hgroup>
<hgroup cellVAlign="top" label="MDX Key">
<radioButton name="type" id="rbKey" optionValue="key" onclick="zenPage.rbChanged();"/>
<selector id="controlKey" hint="Enter a single MDX Key" size="25" onchange="zenPage.rbChanged();"/>
</hgroup>
</group>

<html id="ruleCommandsButtons"/>
</group>
<html id="ruleHelp"><div class="ruleHelpBoxOuter" style=""><div class="ruleHelpBoxInner" id="helpDiv"/></div></html>
</vgroup>
<html id="ruleTree"/>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..isNamedFilter) {
		Quit $$$TextHTML("Named Filter Editor")
	}
	Quit $$$TextHTML("Advanced Filter Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	If (..isNamedFilter) {
		Quit $$$TextHTML("Create or modify named filters")
	}
	Quit $$$TextHTML("Create or modify advanced filters")
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		// build array of possible filter names
		this._filterNames = this.filterNames.toString().split("\n");		// DTB765 - Break on new line to support commas
		this._filterValues = this.filterValues.toString().split(",");
		this._filterTypes = this.filterTypes.toString().split(",");
		this._filterMsrTypes = this.filterMsrTypes.toString().split(",");
		
		// n.b. clear out these values to avoid serialization trouble
		this.filterNames = '';
		this.filterValues = '';
		this.filterTypes = '';
		this.filterMsrTypes = '';
		
		this.renderTree();
		this.renderCommands();

		var ctrlKey = zen("controlKey");
	
		var zenNumber = ctrlKey.getEnclosingDiv().getAttribute("zen");
		this._selectorDiv = document.getElementById("div_"+zenNumber);
		this._selectorInput = document.getElementById("control_"+zenNumber);

		// reveal
		var div = zen('mainGroup').getEnclosingDiv();
		div.style.opacity = 1.0;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	if (this.isNamedFilter) {
		// save named filter

		var fname = zen('ctrlFilterName').getValue();
		if (''==fname) {
			alert($$$Text('Please provide a name for this named filter'));
			return false;
		}

		var fdesc = zen('ctrlFilterTooltip').getValue();
		var spec = this.convertToMDX();
		if (this._error!='') {
			alert(this._error);
			return false;
		}

		var msg = this.SaveNamedFilter(this.cubeName,fname,fdesc,spec);
		if (msg != '') {
			alert(msg);
			return false;
		}
	}
	else {
		// validate
		var value = encodeURIComponent(this.convertToMDX());
		if (this._error!='') {
			alert(this._error);
			return false;
		}
	}
	return true;
}

/// Get return value for dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		var value = '';
		if (!this.isNamedFilter) {
			value = encodeURIComponent(this.convertToMDX());
		}
		else {
			// return name of filter
			value = zen('ctrlFilterName').getValue();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return value;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		If (..isNamedFilter) {
			Set tExpression = ""
			Set tGroup = ..%GetComponentById("namedFilterGroup")
			Set tGroup.hidden = 0
			If (..filterName'="") {
				Set tSC = ##class(%DeepSee.Utils).%GetNamedFilterInfo(..cubeName,..filterName,.tInfo)
				Set ..%GetComponentById("ctrlFilterName").value = $G(tInfo("name"))
				Set ..%GetComponentById("ctrlFilterTooltip").value = $G(tInfo("tooltip"))
				Set tExpression = $G(tInfo("spec"))
				Set:tExpression'="" ..expression = tExpression // WAL228 -- fill in expression if we have it
			}
		}
		Else {
			Set tExpression = ..expression
		}

		// DTB336 - set up context so that we can parse the filter expression
		Set tFCube = ..%GetComponentById("fCube")
		Set tFExpression = ..%GetComponentById("fExpression")
		Set tFCube.value = ..cubeName
		Set tFExpression.value = tExpression

		Set tSC = ..GetFiltersBySearchKey() 
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method recalculates the available filters in this cube, taking into account a search key.
Method GetFiltersBySearchKey() As %Status [ ZenMethod ]
{
	// Method added by DTB289	
	Set tSC = $$$OK
	Try {
		
		Set tSearchKey = ..searchKey
		// parse current expression and convert to JSON
		// get list of possible "elements" for the cube
		Set tDataSource = $S(..cubeName'="":..cubeName_".cube",1:"")
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(tDataSource,.tFilters,,,tSearchKey,$S(tSearchKey'="":6,1:3))
		If $$$ISERR(tSC) Quit

		Set tDisplayList = ""
		Set tValueList = ""
		Set tTypeList = ""
		Set tMsrTypeList = ""

		// JMD1411 relax string limit if big strings are on!
#ifdef MaxLocalLength
		Set tStringLimit = $$$MaxLocalLength - 2000
#else
		Set tStringLimit = 30000
#endif

		// JMD901: loop twice: first time to get non-calc, 2nd time for calc members
		For x = 1:1:2 {
			Set a = $O(tFilters(""))
			While (a'="") {
				// type could be ""
				Set tType = $LG(tFilters(a),3)
				If ((tType'="$NAMEDFILTER") && ((x=1)&&(tType'="calc"))||((x=2)&&(tType="calc"))) {
					Set tTypeList = tTypeList _ $S(tDisplayList="":"",1:",") _ tType
					Set tMsrTypeList = tMsrTypeList _ $s(tMsrTypeList="":"",1:",") _ " "
					Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:$C(10)) _ $LG(tFilters(a),1)		// DTB765 - Signal the real break with a new line character
					Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $LG(tFilters(a),2)
					// avoid serialize error
					If (($L(tDisplayList)>tStringLimit)||($L(tValueList)>tStringLimit)) {
						Set x = 3
						Quit
					}
				}
				Set a = $O(tFilters(a))
			}
		}

		// add *searchable* measures to the lists
		Set tSC = ##class(%DeepSee.Utils).%GetCubeSearchableMeasures(..cubeName,.tMeasures)
		If $$$ISERR(tSC) Quit

		Set n = $O(tMeasures(""))
		While (n'="") {
			Set tTypeList = tTypeList _ $S(tDisplayList="":"",1:",") _ "measure"
			Set tMsrTypeList = tMsrTypeList _ $S(tMsrTypeList="":"",1:",") _ $LG(tMeasures(n),3)
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:$C(10)) _ "Measures."_$LG(tMeasures(n),2)		// DTB765 - Signal the real break with a new line character
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "[Measures].["_$LG(tMeasures(n),1)_"]"
			If (($L(tDisplayList)>tStringLimit)||($L(tValueList)>tStringLimit)) {
				Quit
			}
			Set n = $O(tMeasures(n))
		}
		// JSL - these are names and associated values in pull-down list
		Set ..filterValues = tValueList
		Set ..filterNames = tDisplayList
		Set ..filterTypes = tTypeList
		Set ..filterMsrTypes = tMsrTypeList
	}	
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust sizes components on the page.
ClientMethod adjustSize() [ Language = javascript ]
{
	try {
		this.invokeSuper('adjustSize',arguments);
		
		var tree = zen('ruleTree');
		var divTree = tree.getEnclosingDiv();
		var commands = zen('ruleCommands');
		var divCommands = commands.getEnclosingDiv();
		var help = zen('ruleHelp');
		var divHelp = help.getEnclosingDiv();

		var nfGroup = zen('namedFilterGroup');
		var nfDiv = nfGroup.getEnclosingDiv();

		// find size of window (in this case, display area)
		var body = zenPage.getComponentById('body');
		var divBody = body.getEnclosingDiv();
		var winHeight = divBody.offsetHeight - (nfDiv.offsetHeight + 3);
		var winWidth = divBody.offsetWidth;
		var tw = (winWidth-25);
		var trh = 0;

		if (divCommands) {
			tw = tw - divCommands.offsetWidth;
			if (divHelp) {
				trh = Math.round((winHeight-25)*0.65);
				divCommands.style.height = trh + 'px';
			}
			else {
				divCommands.style.height = (winHeight-25) + 'px';
			}
		}

		if (divHelp) {
			divHelp.style.height = (winHeight-25-trh) + 'px';
		}

		if (divTree) {
			divTree.style.width = tw + 'px';
			divTree.style.height = (winHeight-25) + 'px';
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSize');
	}
}

/// Return the object graph that describes the filter.
ClientMethod getFilterGraph() [ Language = javascript ]
{
	try {
		var json = zen('filterGraph');
		var graph = json.getContentObject();
		if (graph && graph.children && graph.children.length > 0) {
			var topChild = graph.children[0];
			// make sure top of graph is a logic node!
			if (topChild.type!='logic') {
				var newNode = new Object();
				graph.children[0] = newNode;

				newNode.children = new Array();
				newNode.children[0] = topChild;
				topChild = newNode;
				newNode.type = 'logic';
				newNode.text = $$$Text('AND');
				newNode.value = 'AND';
			}
			return topChild;
		}
		else {
			return null;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

ClientMethod renderCommandButtons() [ Internal, Language = javascript ]
{
	if (this._commandButtonsInitialized) return;
	this._commandButtonsInitialized = true;
	var buttonDiv = zen('ruleCommandsButtons');
	var html = [];
	html.push('<br/>');
	html.push('<div style="text-align:center;">');
	html.push('<div>'+'<input id="cmdAddCondition" class="optButton" type="button" value="'+$$$Text('Add condition')+'" onclick="zenPage.addCondition();"/>'+ '</div>');
	html.push('<div>'+'<input id="cmdAddBranch" class="optButton" type="button" value="'+$$$Text('Add branch')+'" onclick="zenPage.addBranch();"/>'+ '</div>');
	html.push('<div>'+'<input id="cmdRemoveItem" class="optButtonRemove" type="button" value="'+$$$Text('Remove item')+'" title="'+$$$Text('Remove the current item')+'" onclick="zenPage.removeCondition();"/>'+ '</div>');
	html.push('<div>'+'<input id="cmdClear" class="optButtonRemove" type="button" value="'+$$$Text('Clear')+'" title="'+$$$Text('Remove all conditions')+'" onclick="zenPage.clearNodes(true);"/>'+ '</div>');
	html.push('<div>'+'<input id="cmdUndo" class="optButtonDisabled" disabled="1" type="button" value="'+$$$Text('Undo')+'" onclick="zenPage.undo();"/>'+ '</div>');
	html.push('</div>');
	buttonDiv.setContent(html.join(""));
	this._cmdAddConditionPtr = document.getElementById("cmdAddCondition");
	this._cmdAddBranchPtr = document.getElementById("cmdAddBranch");
	this._cmdRemoveItemPtr = document.getElementById("cmdRemoveItem");
	this._cmdClearPtr = document.getElementById("cmdClear");
	this._cmdUndoPtr = document.getElementById("cmdUndo");
}

ClientMethod configureCommandButtons(node, graph, undo) [ Internal, Language = javascript ]
{
	if (!this._commandButtonsInitialized) this.renderCommandButtons();

	if ((!graph) || (node && node.type=='logic')) {
		this._cmdAddConditionPtr.style.display="";
	}
	else this._cmdAddConditionPtr.style.display="none";
	
	if ((node && node.type=='logic')) {
		this._cmdAddBranchPtr.style.display = "";
	}
	else this._cmdAddBranchPtr.style.display = "none";
		
	if (node && node._parent) {
		this._cmdRemoveItemPtr.style.display = "";
	}
	else this._cmdRemoveItemPtr.style.display = "none";

	if (graph && graph.children && graph.children[0]) {
		this._cmdClearPtr.style.display = "";
	}
	else this._cmdClearPtr.style.display = "none";
	
	if (undo) {
		this._cmdUndoPtr.className = "optButton";
		this._cmdUndoPtr.disabled = false;
	}
	else {
		this._cmdUndoPtr.className = "optButtonDisabled";
		this._cmdUndoPtr.disabled = true;
	}
}

ClientMethod renderCommandsHeader(node, graph) [ Internal, Language = javascript ]
{
	var ruleCommandsHeader = zen('ruleCommandsHeader');
	var html = [];
	var title = '';
	var typeLabel = '';
	if (node) {
		switch(node.type) {
		case 'logic':
		case 'operator':
		case 'measureOperator':
			type = 'Operator';
			typeLabel = $$$Text('Operator');
			break;
		case 'member':
			type = 'Dimension';
			typeLabel = $$$Text('Dimension');
			break;
		case 'measure':
			type = 'Measure';
			typeLabel = $$$Text('Measure');
			break;
		case 'key':
		case 'literal':
			type = 'Value';
			typeLabel = $$$Text('Value');
			break;
		}

		html.push('<div class="commandTitle">');
		html.push('<div class="commandTitleHeading">' + zenEscapeXML(typeLabel) + '</div>');
		html.push('<div class="commandTitleMain">' + zenEscapeXML(node.text) + '</div>');
		html.push('</div>');
	}
	else {
		if (graph && graph.children) {
			html.push('<div class="commandTitle">' + '<i>'+$$$Text('No selection')+'</i>' + '</div>');
		}
 		else {
			html.push('<div class="commandTitle">' + '<i>'+$$$Text('Empty')+'</i>' + '</div>');
 		}
	}
	ruleCommandsHeader.setContent(html.join(''));
}

ClientMethod renderCommandsOperatorPanel(node) [ Internal, Language = javascript ]
{
  	var ruleCommands = zen('ruleCommandsBody');
	
	if (node.type=='logic') {
		var options = [{text:$$$Text('AND'),value:'AND'},
						{text:'&nbsp;'+$$$Text('OR')+'&nbsp;',value:'OR'}];
	}
	else if (node.type=='measureOperator') {
		// BDB510 - check if this is a text measure
		var msr = (node.children && node.children[0]) ? node.children[0].value : '';
		var msrtype = '';
		for (var f=0;f<this._filterValues.length;f++) {
			// DTB089 - use upper case for search comparison
			if (this._filterValues[f].toUpperCase()==msr.toUpperCase()) {
				msrtype = this._filterMsrTypes[f];
				break;
			}
		}
		if ((msrtype == 'text') || (msrtype == 'string')) {
			var options = [{text:'=',value:'='},
							{text:'<>',value:'<>'},
							{text:'LIKE',value:'LIKE'}];
		} else {
			var options = [{text:'=',value:'='},
							{text:'<>',value:'<>'},
							{text:'>',value:'>'},
							{text:'>=',value:'>='},
							{text:'<',value:'<'},
							{text:'<=',value:'<='}];
		}
	}
	else {
		var member = (node.children && node.children[0]) ? node.children[0].value : '';

		// find type for the current member
		var mbrtype = '';
		for (var f=0;f<this._filterValues.length;f++) {
			// DTB089 - use upper case for search comparison
			if (this._filterValues[f].toUpperCase()==member.toUpperCase()) {
				mbrtype = this._filterTypes[f];
				break;
			}
		}

		// JMD: no conditional operators for calc members
		if (mbrtype == 'calc') {
			var options = [{text:$$$Text('IS'),value:'='},
							{text:$$$Text('IS NOT'),value:'<>'}];
		}
		else {
			var options = [{text:$$$Text('IS'),value:'='},
							{text:$$$Text('IS NOT'),value:'<>'},
							{text:'>',value:'>'},
							{text:'>=',value:'>='},
							{text:'<',value:'<'},
							{text:'<=',value:'<='}
							];
		}
	}
	var html=[];
	html.push('<div class="commandOptions">');
	for (var o=0;o<options.length;o++) {
		var cls = (options[o].value===node.value) ? 'CommandOptionCurr' : 'CommandOption';
		html.push('<div class="'+cls+'" onclick="zenPage.changeNode('+node._index+',\''+node.type+'\',\''+options[o].value+'\',\''+options[o].text+'\');">'+options[o].text+ '</div>');
	}
	html.push('</div>');
	ruleCommands.setContent(html.join(''));
}

ClientMethod renderCommandsLiteralPanel(node) [ Internal, Language = javascript ]
{
 	var ruleCommands = zen('ruleCommandsBody');
	var html=[];
	html.push('<div class="commandOptions">');
	html.push('<div class="searchTitle">');
	html.push('<form>');
	html.push('<input id="literalBox" type="search" size="8" value="'+node.value+'"/>');
	html.push('<input type="submit" value="'+$$$Text('Apply')+'" onclick="zenPage.applyLiteral();return false;"/>');
	html.push('</form>');
	html.push('</div><br/>');
	html.push('</div>');
	ruleCommands.setContent(html.join(''));
}

ClientMethod renderCommandsMemberPanel(node) [ Internal, Language = javascript ]
{
 	var ruleCommands = zen('ruleCommandsBody');
	var html=[];
	// show list of dimensions and measures
	var uval = node.value.toString().toUpperCase();
				
	// +DTB289 - Recalculate the list of dimensions
	this.GetFiltersBySearchKey(this.cubeName,this.searchKey)
				
	this._filterNames = this.filterNames.toString().split("\n");		// DTB765 - Break on new line to support commas
	this._filterValues = this.filterValues.toString().split(",");
	this._filterTypes = this.filterTypes.toString().split(",");
	this._filterMsrTypes = this.filterMsrTypes.toString().split(",");
	// -DTB289
				
	// DTB289 - Add a search box and button
	html.push('<div class="commandOptions">');
	html.push('<div class="searchTitle" style="padding-bottom:8px;">');
	html.push('<form>');
	html.push('<input id="searchBox" type="search" size="8" value="'+this.searchKey+'"/>');
	html.push('<input type="submit" value="'+$$$Text('Search')+'" onclick="zenPage.changeSearchKey();return false;"/>');
	html.push('</form>');
	html.push('</div>');
	html.push('<div class="searchTitle">' + $$$Text('Values') + '</div>');
	html.push('<select onchange="zenPage.changeMember('+node._index+',this);">');
	for (var f=0;f<this._filterValues.length;f++) {
		html.push('<option '+ (this._filterValues[f].toString().toUpperCase()==uval?'selected="1" ':'') +'value="'+zenEscapeXML(this._filterValues[f])+'">' + zenEscapeXML(this._filterNames[f]) + '</option>');
	}
	html.push('</select>');
	html.push('</div>');
	ruleCommands.setContent(html.join(''));
}

/// User selected a radio button.
ClientMethod rbChanged() [ Internal, Language = javascript ]
{
	var rbFilter = zen('rbFilter');
	this.searchBoxMode = rbFilter.getValue();
	this.updateSearchBoxControls();
}

ClientMethod initializeSearchBoxControls(node, member, mbrType) [ Internal, Language = javascript ]
{
	var rbFilter = zen('rbFilter');
	var rbKey = zen('rbKey');

	var ctrlFilter = zen("controlFilter");
	var ctrlKey = zen("controlKey");
		
	ctrlFilter.editable = 1;
	ctrlFilter.multiSelect = 0;		// DTB497 - Turn multi-select off in this context
	ctrlFilter.dataSourceName = this.cubeName + '.cube';		// DTB709 - Add extension
	ctrlFilter.filterName = member;
	ctrlFilter.appendPivotVariables = true;		// DTB837
	
	node.text+='';		// DTB497 - Force string type so indexOf works!
	if (node.text=='' || node.text.indexOf('&')==0 || rbKey.getValue()=='key') { // start off in MDX Key state
		this.searchBoxMode = "key";
		ctrlFilter.setProperty('disabled',true);
		ctrlKey.setProperty('disabled',false);
		ctrlKey.setValue(this.keyToMDX(node.value));		// DTB837 - This method handles pivot variables
		if (node.text == '' || node.text.indexOf('&')==0) ctrlFilter.setValue("");
		else ctrlFilter.setValue(ctrlKey.getValue());
	}
	else {
		this.searchBoxMode = "filter";
		ctrlFilter.setProperty('disabled',false);
		ctrlKey.setProperty('disabled',true);
		ctrlFilter.setValue(node.value);
		ctrlKey.setValue(this.keyToMDX(ctrlFilter.getValue()));		// DTB837
	}
	
	ctrlFilter.refreshContents();
	if (mbrType == 'day') ctrlFilter.displayMode = 'calendar';
	else ctrlFilter.displayMode = 'list';
	ctrlFilter._nodeIndex = node._index;
	rbKey.setValue(this.searchBoxMode);
	rbFilter.setValue(this.searchBoxMode);
	
	if (this._selectorDiv) this._selectorDiv.style.width = "";
	if (this._selectorInput) this._selectorInput.style.width = "200px";

	var json = zen('memberList');
	zen('pCube').value = this.cubeName;
	zen('pDimension').value = member;
	json.reloadContents();

	this.searchBoxOptions = json.getContentObject();
	this.searchBoxNode = node;
}

ClientMethod verifySearchBox() [ Internal, Language = javascript ]
{
	var controlFilter = zen('controlFilter');
	if (this.searchBoxNode && this.searchBoxNode.value != "" &&
		controlFilter.getValue() == this.searchBoxNode.value && 
		controlFilter.text != this.searchBoxNode.text) {
			
		var zenNumber=controlFilter.getEnclosingDiv().getAttribute("zen");
		var inDiv = document.getElementById("input_"+zenNumber);
		if (inDiv) inDiv.innerHTML = this.searchBoxNode.text;
	}
}

/// Update controls to match current state.
ClientMethod updateSearchBoxControls() [ Language = javascript ]
{
	var controlFilter = zen('controlFilter');
	var controlKey = zen('controlKey');
	
	if (this.searchBoxMode=='filter') {
		controlFilter.setProperty('disabled',false);
		controlKey.setProperty('disabled',true);		// DTB442
		
		var value = controlFilter.getValue();
		
		if (value && this.searchBoxNode.value!=value) {		
			controlKey.setValue(this.keyToMDX(value));		// DTB837
			this.changeNode(controlFilter._nodeIndex,'key',value,controlFilter.text);
		}
	}
	else if (this.searchBoxMode=='key') {
		// DTB442 - Settings for new option
		controlFilter.setProperty('disabled',true);
		controlKey.setProperty('disabled',false);
		
		var enteredKey = controlKey.getValue();
		var text = '';
		controlFilter.setValue('');
		if (enteredKey!='') {
			text = enteredKey;
			enteredKey = enteredKey.toUpperCase();
			var options = this.searchBoxOptions.children;
			var len = options.length;
			for (var i=0;i<len;i++) {			
				if (enteredKey == options[i].value.toUpperCase()) {
					text = options[i].text;
					controlFilter.setValue(enteredKey);
					controlFilter.refreshContents();
					i=len;
				}
			}		
		}
		else {
			text = '<' + $$$Text('select a value') + '>';
		}		
		this.changeNode(controlFilter._nodeIndex,'key',controlKey.getValue(),text);
	}
}

ClientMethod remapQueryToDisplayKey(node) [ Internal, Language = javascript ]
{
	if (node && node._parent && node._parent.children && node._parent.children[0]) {
		var json = zen('memberList');
		zen('pCube').value = this.cubeName;
		zen('pDimension').value = node._parent.children[0].value;
		json.reloadContents();
		var options = json.getContentObject().children;
		var len = options.length;
		var key = node.value;
		var text = '';
		for (var i=0;i<len;i++) {			
			if (key == options[i].value) {
				text = options[i].text;
				i=len;
			}
		}		
		if (text!='') node.text = text;
	}
}

ClientMethod renderCommandsKeyPanel(node, ruleSearchBox) [ Internal, Language = javascript ]
{
	ruleSearchBox.getEnclosingDiv().style.display="block";

	// find node type
	var member = '';
	var op = '';
	var pnode = node._parent;
	if (pnode) {
		if ((pnode.type=='operator')||(pnode.type=='measureOperator')) {
			op = pnode.value;
		}
		member = pnode.children[0].value;
	}

	// find type for the current member
	var mbrType = '';
	for (var f=0;f<this._filterValues.length;f++) {
		// DTB089 - use upper case for search comparison
		if (this._filterValues[f].toUpperCase()==member.toUpperCase()) {
			mbrType = this._filterTypes[f];
			break;
		}
	}
	this.initializeSearchBoxControls(node,member,mbrType);
	
	var html=[];
 	var ruleCommands = zen('ruleCommandsBody');
	ruleCommands.setContent(html.join(''));
	return;
}

/// Update the command panel.
ClientMethod renderCommands() [ Language = javascript ]
{
	try {
  		var ruleCommands = zen('ruleCommandsBody');
  		var ruleSearchBox = zen('ruleCommandsSearchBox');
		ruleSearchBox.getEnclosingDiv().style.display="none";

		var graph = this.getFilterGraph();

		var node = null;
		if ('' !== this.selectedIndex && this._nodeIndex && this._nodeIndex[this.selectedIndex]) node = this._nodeIndex[this.selectedIndex];
		this.renderCommandsHeader(node,graph);
		
		if (node) {
			switch(node.type) {
			case 'logic':
			case 'operator':
			case 'measureOperator':
				this.renderCommandsOperatorPanel(node);
				break;

			case 'member':
			case 'measure':
				this.renderCommandsMemberPanel(node);
				break;

			case 'key':
				this.renderCommandsKeyPanel(node,ruleSearchBox);
				break;

			case 'literal':
				this.renderCommandsLiteralPanel(node);
				break;
			}
		}
		else {
			if (graph && graph.children && (graph.children.length == 0)) {
		 		node = graph;
				type = 'Operator';
		 	}
 		}
		this.configureCommandButtons(node,graph,this.canUndo());

		var ctrl = self.document.getElementById('searchBox');
		if (ctrl) ctrl.focus();		
		this.renderHelp();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Update the help box.
ClientMethod renderHelp() [ Language = javascript ]
{
	try {
		var helpDiv = self.document.getElementById('helpDiv');
		if (!helpDiv) {
			return;
		}

		var msgSelect = $$$Text('Select an item to modify it.');
		var msgAddCond = $$$Text('Use Add Condition to add a condition to this filter.');
		var msgAddBranch = $$$Text('Use Add Branch to add an AND or OR branch to this filter.');
		var msgEditMbr = $$$Text('Use the control to change the dimension or measure used for this condition.');
		var msgEditKey = $$$Text('Use the Values control to change the value of this condition.');
		var msgSearch = $$$Text('You can use the search box to narrow down the list of possible values.');
		var msgOperator = $$$Text('Click on an item above to change the operator for this condition.');
		var msgLogic = $$$Text('Click on an item above to change this logical condition.');

		var graph = this.getFilterGraph();
		var html = new Array();
		var node = null;
		if (graph==null || (graph && graph.children && graph.children.length == 0)) {
			html[html.length] = '<div>'+msgAddCond+'</div>';
		}
		else if ('' !== this.selectedIndex && this._nodeIndex && this._nodeIndex[this.selectedIndex]) {
			node = this._nodeIndex[this.selectedIndex];
			var title = '';
			switch(node.type) {
			case 'logic':
				html[html.length] = '<div>'+msgLogic+'</div>';
				html[html.length] = '<div>'+msgAddCond+'</div>';
				html[html.length] = '<div>'+msgAddBranch+'</div>';
				break;
			case 'measureOperator':
			case 'operator':
				html[html.length] = '<div>'+msgOperator+'</div>';
				break;
			case 'member':
			case 'measure':
				html[html.length] = '<div>'+msgEditMbr+'</div>';
				break;
			case 'key':
			case 'literal':
				html[html.length] = '<div>'+msgEditKey+'</div>';
				html[html.length] = '<div>'+msgSearch+'</div>';
				break;
			}
		}
		else {
			html[html.length] = '<div>'+msgSelect+'</div>';
			html[html.length] = '<div>'+msgAddCond+'</div>';
 		}

		helpDiv.innerHTML = html.join('');
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Update the expression tree.
ClientMethod renderTree() [ Language = javascript ]
{
	try {
		var ruleTree = zen('ruleTree');
		var graph = this.getFilterGraph();

		this._nodeIndex = new Array();
		this.buildNodeIndex(graph);

		var html = new Array();

		if (graph && graph.children && graph.children.length > 0) {
			html[html.length] = this.renderNode(graph,0);
		}
		else {
			var emptyMsg1 = $$$Text('This filter is empty.');
			html[html.length] = '<div class="EmptyMsg">' + emptyMsg1 + '</div>';
		}
		ruleTree.setContent(html.join(''));
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Build index of nodes
/// Set _index and _parent as side effect.
ClientMethod buildNodeIndex(node, parent) [ Language = javascript ]
{
	if (node) {
		node._index = this._nodeIndex.length;
		node._parent = parent;
		this._nodeIndex[this._nodeIndex.length] = node;
		if (node.children) {
			for (var n = 0; n < node.children.length; n++) {
				this.buildNodeIndex(node.children[n],node);
			}
		}
	}
}

/// Get HTML for a node within the expression graph.
ClientMethod renderNode(node, level) [ Language = javascript ]
{
	var html = new Array();
	switch(node.type) {
	case 'logic':
		html[html.length] = '<table class="logicTable" border="0" cellspacing="10">';
		html[html.length] = '<tr>';
		html[html.length] = this.renderOperatorSelector(node);
		if (node.children) {
			html[html.length] = '<td>';
			for (var n = 0; n < node.children.length; n++) {
				html[html.length] = this.renderNode(node.children[n],level+1);
			}
			html[html.length] = '</td>';
		}
		html[html.length] = '</tr>';
		html[html.length] = '</table>';
		break;
	case 'operator':
		html[html.length] = this.renderOperatorNode(node);
		break;
	case 'measureOperator':
		html[html.length] = this.renderMeasureOperatorNode(node);
		break;
	default:
		html[html.length] = 'Unknown node type: ' + node.type;
		break;
	}
	return html.join('');
}

/// Get HTML for an operator node within the expression graph;
ClientMethod renderOperatorNode(node) [ Language = javascript ]
{
	var html = new Array();
	switch(node.value) {
	case '=':
	case '<>':
	case '>':
	case '>=':
	case '<':
	case '<=':
		html[html.length] = '<table class="opTable" border="0" cellspacing="10" cellpadding="5">';
		html[html.length] = '<tr>';
		var child1 = (node.children && node.children[0]) ? node.children[0] : null;
		var child2 = (node.children && node.children[1]) ? node.children[1] : null;
		html[html.length] = (child1) ? this.renderValueNode(child1) : 'N/A';
		html[html.length] = this.renderOperatorSelector(node);
		html[html.length] = (child2) ? this.renderValueNode(child2) : 'N/A';
		html[html.length] = '</tr>';
		html[html.length] = '</table>';
		break;
	default:
		html[html.length] = 'Unknown operator type: ' + node.value;
		break;
	}
	return html.join('');
}

/// Get HTML for a measure operator node within the expression graph;
ClientMethod renderMeasureOperatorNode(node) [ Language = javascript ]
{
	var html = new Array();
	switch(node.value) {
	case '=':
	case '<>':
	case '>':
	case '>=':
	case '<':
	case '<=':
	case 'LIKE':
		html[html.length] = '<table class="opTable" border="0" cellspacing="10" cellpadding="5">';
		html[html.length] = '<tr>';
		var child1 = (node.children && node.children[0]) ? node.children[0] : null;
		var child2 = (node.children && node.children[1]) ? node.children[1] : null;
		html[html.length] = (child1) ? this.renderValueNode(child1) : 'N/A';
		html[html.length] = this.renderOperatorSelector(node);
		html[html.length] = (child2) ? this.renderValueNode(child2) : 'N/A';
		html[html.length] = '</tr>';
		html[html.length] = '</table>';
		break;
	default:
		html[html.length] = 'Unknown operator type: ' + node.value;
		break;
	}
	return html.join('');
}

/// Get HTML for an operator selector the expression graph;
ClientMethod renderOperatorSelector(node) [ Language = javascript ]
{
	var html = new Array();
	var cls = node.type+'Selector';
	if (node._index === this.selectedIndex) {
		cls = 'itemSelected';
	}
	html[html.length] = '<td><div id="node_'+node._index+'" class="'+cls+'" onclick="zenPage.selectItem('+node._index+');" >' + node.text + '</div></td>';
	return html.join('');
}

/// Get HTML for a value selector the expression graph;
ClientMethod renderValueNode(node) [ Language = javascript ]
{
	if (node.text=="Query" && node.value.indexOf("&[SELECT")==0) {
		zenPage.remapQueryToDisplayKey(node);
	}
	var html = [];
	var cls = '';
	var text = node.text;
	switch(node.type) {
	case 'measure':
	case 'member':
		cls = "memberSelector";
		break;
	case 'literal':
		cls = "literalSelector";
		break;
	case 'key':
		cls = "keySelector";
		// test for range
		if (node.value.toString().indexOf(':&[')>=0) {
			if (text=='') text = node.value;
			else {
				var t = text.split(':');
				if (t.length>2) {
					// DTB849 - The provided display text contains ':' characters. This cannot be easily 
					// split and the true names need to be looked up from the keys
					var k = node.value.split(']:&[')
					k[0] = k[0].substr(2);
					k[1] = k[1].substr(0,k[1].length-1)
					
					// Attempt to convert keys to names
					var level = node._parent.children[0].value
					if (level) {
						t[0] = this.LookupMemberByKey(this.cubeName,level,k[0]);
						t[1] = this.LookupMemberByKey(this.cubeName,level,k[1]);
					}
				}
				
				text = $$$FormatText($$$Text('Between %1 AND %2'),t[0],t[1]);
			}
		}
		break;
	default:
		alert('Unknown node type: ' + node.type);
		break;
	}

	if ('' != cls) {
		if (node._index === this.selectedIndex) {
			cls = 'itemSelected';
		}
		if (text=='') text = node.value;
		html.push('<td><div id="node_'+node._index+'" class="'+cls+'" onclick="zenPage.selectItem('+node._index+');">' + zenEscapeXML(text) + '</div></td>');
	}

	return html.join('');
}

/// Mouse click on item in diagram.
ClientMethod selectItem(idx) [ Language = javascript ]
{
	if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
		// unhilight
		var div = self.document.getElementById('node_' + this.selectedIndex);
		if (div) {
			div.className = this._nodeIndex[this.selectedIndex].type + 'Selector';
		}
	}
	this.selectedIndex= idx;
	this.searchKey = '';
	if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
		// highlight
		var div = self.document.getElementById('node_' + this.selectedIndex);
		if (div) {
			div.className = 'itemSelected';
		}
	}
	// update commands
	this.renderCommands();
}

/// Change of search key.
ClientMethod changeSearchKey() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('searchBox');
	if (ctrl && this.searchKey != ctrl.value) {
		this.searchKey = ctrl.value;
		this.renderCommands();
	}
}

/// Change of literal value.
ClientMethod applyLiteral() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('literalBox');
	if (ctrl) {
		if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
			node = this._nodeIndex[this.selectedIndex];
			node.text = ctrl.value;
			node.value = ctrl.value;
			this.renderTree();
			this.renderCommands();
		}
	}
}

/// The user has selected a new item in the *member* select list.
ClientMethod changeMember(idx, ctrl) [ Language = javascript ]
{
	var option = ctrl.options[ctrl.selectedIndex];
	if (option) {
		// apply change to diagram
		this.changeNode(idx,'member',option.value,option.text);
	}
}

/// Change of key type.
ClientMethod changeKey(idx) [ Language = javascript ]
{
	var ctrl1 = self.document.getElementById('ctrl1');

	// defined for range types
	var ctrl2 = self.document.getElementById('ctrl2');

	if (ctrl1 && !ctrl2) {	
		var option = ctrl1.options[ctrl1.selectedIndex];
		if (option) {
			this.changeNode(idx,'key',option.value,option.text);
		}
	}
	else if (ctrl1 && ctrl2) {
	
		var option1 = ctrl1.options[ctrl1.selectedIndex];
		var option2 = ctrl2.options[ctrl2.selectedIndex];
		if (option1 && option2) {
			var value = option1.value;
			var text = option1.text;
			if (option1.value!="" && option2.value != "") {
				value = option1.value + ":" + option2.value;
				text = option1.text + ":" + option2.text;
			}
			this.changeNode(idx,'key',value,text);
		}
	}
}

/// Change of node type.
ClientMethod changeNode(idx, type, value, text) [ Language = javascript ]
{
	node = this._nodeIndex[idx];
	if (node) {
		if (node.type!=type || node.value != value || node.text != text) {
			this.addUndoAction();

			// check for measure/member
			if (type=='member') {
				if (value.indexOf('[Measures].')!=-1) {
					type = 'measure';
				}
			}
			node.type = type;
			node.value = value;
			node.text = text;

			// for some cases we have to change other nodes
			switch(type) {
			case 'operator':
				// remove range from right side of expression
				if (value!='=' && value!='<>') {
					if (node.children[1].value.indexOf(':&[')>=0) {
						node.children[1].value = node.children[1].value.split(':&[')[0];
						node.children[1].text = node.children[1].text.split(':')[0];
					}
				}
				break;

			case 'measure':
				// reset other side of expression
				var pnode = node._parent;
				if (pnode && pnode.children) {
					if (pnode.type == 'operator') {
						pnode.type = 'measureOperator';
						pnode.value = '=';
						pnode.text = '=';
					}

					for (var n = 1; n < pnode.children.length; n++) {
						pnode.children[n].type = 'literal';
						pnode.children[n].text = '0';
						pnode.children[n].value = '0';
					}
				}
				break;

			case 'member':
				// reset other side of expression
				var pnode = node._parent;
				if (pnode && pnode.children) {
					if (pnode.type != 'operator') {
						pnode.type = 'operator';
						pnode.value = '=';
						pnode.text = $$$Text('IS');
					}

					// find type for the new member
					var mbrtype = '';
					for (var f=0;f<this._filterValues.length;f++) {
						// DTB089 - use upper case for search comparison
						if (this._filterValues[f].toUpperCase()==node.value.toUpperCase()) {
							mbrtype = this._filterTypes[f];
							break;
						}
					}

					for (var n = 1; n < pnode.children.length; n++) {
						pnode.children[n].type = 'key';
						if (mbrtype=='calc') {
							pnode.children[n].text = '<' + $$$Text('select a value') + '>';
							pnode.value = '=';
							pnode.text = $$$Text('IS');
						}
						else {
							// + WAL143 -- treat standard members like calculated members
							//pnode.children[n].text = $$$Text('All');
							pnode.children[n].text = '<' + $$$Text('select a value') + '>';
							// + WAL143
						}
						pnode.children[n].value = '';
					}
				}
				break;
			}
		}
	}
	this.renderTree();
	this.renderCommands();
}

/// Reset the expression graph.
ClientMethod clearNodes(render) [ Language = javascript ]
{
	var graph = this.getFilterGraph();
	if (graph) {
		this.addUndoAction();
	}

	graph = new Object();
	graph.children = new Array();

	var topNode = new Object();
	topNode.children = new Array();

	topNode.type = 'logic';
	topNode.text = $$$Text('AND');
	topNode.value = 'AND';
	graph.children[graph.children.length] = topNode;

	var json = zen('filterGraph');
	json.setContentObject(graph);
	this.selectedIndex = '';

	if (render) {
		this.renderCommands();
		this.renderTree();
	}
}

/// Add a new branch.
ClientMethod addBranch() [ Language = javascript ]
{
	var node = null;
	if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
		node = this._nodeIndex[this.selectedIndex];
	}
	else {
		var graph = this.getFilterGraph();
		if ((graph == null) || (graph && graph.children && graph.children.length == 0)) {
			this.clearNodes(false);
			node = this.getFilterGraph();
		}
	}

	if (node) {
		this.addUndoAction();
		switch(node.type) {
		case 'logic':
			// see if this node already has branches
			if (node.children && node.children[0] && node.children[0].type == 'logic') {
				// append
				var newNode = new Object();
				newNode.children = new Array();
				newNode.type = 'logic';
				newNode.text = $$$Text('AND');
				newNode.value = 'AND';
				node.children[node.children.length] = newNode;
			}
			else {
				// insert between
				var newNode = new Object();
				newNode.children = node.children;
				newNode.type = 'logic';
				newNode.text = $$$Text('AND');
				newNode.value = 'AND';

				node.children = new Array();
				node.children[node.children.length] = newNode;
			}
			break;
		default:
			alert('Branch can only be added to logic operators');
			break;
		}

		this.renderCommands();
		this.renderTree();
	}
}

/// Add a new condition.
ClientMethod addCondition() [ Language = javascript ]
{
	var node = null;
	
	// find node to add condition to
	if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
		node = this._nodeIndex[this.selectedIndex];
	}
	else {
		var graph = this.getFilterGraph();
		if ((graph == null) || (graph && graph.children && graph.children.length == 0)) {
			this.clearNodes(false);
			node = this.getFilterGraph();
		}
	}

	if (node) {
		this.addUndoAction();
		switch(node.type) {
		case 'logic':
			var newNode = new Object();
			newNode.children = new Array();
			newNode.type = 'operator';
			newNode.text = $$$Text('IS');
			newNode.value = '=';
			node.children[node.children.length] = newNode;

			// add default node
			var node1 = new Object();
			node1.text = this._filterNames[0] ? this._filterNames[0] : '?';
			node1.value = this._filterValues[0] ? this._filterValues[0] : '';
			node1.type = 'member';
			newNode.children[newNode.children.length] = node1;

			// calc members have only one part to their spec
			var isCalc = (node1.value!='') && (node1.value.indexOf('].[')<0);
			var node2 = new Object();
			// + WAL143 -- this is where 'All' in the branches comes from
			//             now treat all members like calculated members
			node2.text = '<' + $$$Text('select a value') + '>';
			/*
			if (isCalc) {
				node2.text = '<' + $$$Text('select a value') + '>';
			}
			else {
				//node2.text = $$$Text('All');
			}
			*/
			// - WAL143
			node2.value = '';
			node2.type = 'key';
			newNode.children[newNode.children.length] = node2;
			break;
		default:
			alert($$$Text('Condition can only be added to logic operators'));
			break;
		}

		this.renderCommands();
		this.renderTree();
	}
}

/// Remove the current condition.
ClientMethod removeCondition() [ Language = javascript ]
{
	if (''!==this.selectedIndex && this._nodeIndex[this.selectedIndex]) {
		this.addUndoAction();
		var node = this._nodeIndex[this.selectedIndex];
		switch(node.type) {
		case 'logic':
			if (node._parent) {
				// remove node from parent
				for (var n = 0; n < node._parent.children.length; n++) {
					if (node._parent.children[n] === node) {
						node._parent.children.splice(n,1);
					}
				}
				// move node children to parent
				for (var n = 0; n < node.children.length; n++) {
					node._parent.children[node._parent.children.length] = node.children[n];
				}
			}
			break;

		case 'measure':
		case 'member':
		case 'key':
		case 'literal':
			node = (node._parent);
			// fall through
		case 'operator':
		case 'measureOperator':
			if (node && node._parent) {
				for (var n = 0; n < node._parent.children.length; n++) {
					if (node._parent.children[n] === node) {
						node._parent.children.splice(n,1);
					}
				}
			}
			break;
		}

		this.renderCommands();
		this.renderTree();
	}
}

/// Convert the expression graph to an MDX clause.<br/>
/// This is used to convert the current graphical expression into the MDX that
/// will be used as a %FILTER clause.
ClientMethod convertToMDX() [ Language = javascript ]
{
	this._error = '';
	var graph = this.getFilterGraph();
	var result = this.convertNodeToMDX(graph);
	if (result.error) {
		this._error = result.error;
		return '';
	}
	return result.text;
}

/// Convert the expression to an MDX clause.
/// Return an object containing: {text, hasSet, levelName}
ClientMethod convertNodeToMDX(node) [ Language = javascript ]
{
	var obj = new Object();
	var hasSet = false;
	var levelName = '';	// [dim].[hier].[level] if present
	var text = '';

	if (null != node) {
		switch(node.type) {
		case 'logic':
			// get children info
			var anysets = false;
			var cnodes = new Array();
			for (var n = 0; n < node.children.length; n++) {
				var r = this.convertNodeToMDX(node.children[n]);
				if (r.error) {
					obj.error = r.error;
					return obj;
				}
				if (''!==r.text) {
					if (r.hasSet) {
						anysets = true;
					}
					cnodes[cnodes.length] = r;
				}
			}

			// put nodes together
			switch (node.value) {
			case 'OR':
				var c = 0;
				var useOR = true;
				var orLevel = '';
				for (var n = 0; n < cnodes.length; n++) {
					var r = cnodes[n];
					if (''!==r.text) {
						c++;
						text = text + (''===text ? '':',') + r.text;
						// see if all legs of OR are from same level
						if (r.levelName == '') {
							//JMD1453 useOR = false;
						}
						else if (useOR) {
							if (orLevel=='') {
								orLevel = r.levelName;
							}
							else if (orLevel!=r.levelName) {
								//JMD1453 useOR = false;
							}
						}
					}
				}
				if (''!==text) {
					hasSet = true;		// DTB159 - All OR nodes in the graph are sets
					if ((c>1)||(text.indexOf('$variable')>0)) {		// DP-426144 - Keep the %OR text when $variable is in play
						if (useOR) {
							text = '%OR({' + text + '})';
						}
						else {
							text = '{' + text + '}';
						}
					}
					else if (c==1) {
						// DTB159 - The presence of '{}' is what indicates an OR is to be used on load
						text = '{' + text + '}';
					}
				}
				break;
			case 'AND':
				if (anysets) {
					if (cnodes.length==1) {
						// DTB159 - Do not make this a set. Set notation indicates OR is to be used on reload
						text = cnodes[0].text;
					}
					else if (cnodes.length>1) {
						hasSet = true;
						// we have to use CROSSJOIN
						for (var n = cnodes.length-1; n >= 0; n--) {
							var r = cnodes[n];
							if (n == cnodes.length-1) {
								text = r.text
							}
							else {
								// JMD: nonempty has trouble with complex expressions!
								text = 'CROSSJOIN(' + r.text + ',' + text + ')\n';
							}
						}
					}
				}
				else {
					if (cnodes.length==1) {
						// no parens
						text = cnodes[0].text;
					}
					else {
						// create tuple
						for (var n = 0; n < cnodes.length; n++) {
							var r = cnodes[n];
							if (''!==r.text) {
								text = text + (''===text ? '':',') + r.text;
							}
						}
						if (''!==text) {
							text = '(' + text + ')';
						}
					}
				}
				break;
			}
			break;

		case 'measureOperator':
			if (node.value=='LIKE') {
				text = '%Search.&['+node.children[0].value + ' ' + node.value + ' ' + node.children[1].value+']';
			} else {
				text = '%Search.&['+node.children[0].value + node.value + node.children[1].value+']';
			}
			break;

		case 'operator':
			// JMD - validate calc mbrs
			// + WAL013 -- allow '<null>' as a filter option
			//if (node.children[1] && node.children[1].text.toString().charAt(0) == '<') {
			if (node.children[1] && node.children[1].text.toString().charAt(0) == '<' && node.children[1].text!='<null>') {
			// - WAL013
				obj.error = $$$FormatText($$$Text('Please select a value for %1'),node.children[0].value);
				return obj;
			}

			switch (node.value) {
			case '=':
				if (node.children[1]) {
					text = node.children[0].value;
					levelName = text;
					if (''!==node.children[1].value) {
						if (node.children[1].value.indexOf(':&[')>=0) {
							// range: wrap with %OR()
							hasSet = true;
							text = '%OR(' + text + '.' + node.children[1].value + ')';
						}
						else {
							text = text + '.' + zenPage.keyToMDX(node.children[1].value);
						}
					}
				}
				break;
			case '<>':
				if (node.children[1] && ''!==node.children[1].value) {
					if (node.children[1].value.indexOf(':&[')>=0) {
						// range
						// use EXCEPT() for not
						hasSet = true;
						if (node.children[1] && ''!==node.children[1].value) {
							text = 'EXCEPT('+node.children[0].value + '.Members,' + node.children[0].value + '.'+node.children[1].value+ ')';
						}
					}
					else if (node.children[1].value == '') {
						// JMD1041: %NOT ALL is meaningless
						text = node.children[0].value;
					}
					else {
						// use %NOT
						text = node.children[0].value + '.'+ zenPage.keyToMDX(node.children[1].value) + '.%NOT';
					}
				}
				break;
			case '>':
			case '>=':
			case '<':
			case '<=':
				hasSet = true;
				// JMD1041
				// find type for the current member
				var mbrtype = '';
				for (var f=0;f<this._filterValues.length;f++) {
					// DTB089 - use upper case for search comparison
					if (this._filterValues[f].toUpperCase()==node.children[0].value.toUpperCase()) {
						mbrtype = this._filterTypes[f];
						break;
					}
				}

				// is this a time dimension?
				if ((mbrtype=='year')||(mbrtype=='month')||(mbrtype=='day')||(mbrtype=='quarter')||(mbrtype=='week')) {
					var val = zenPage.keyToMDX(node.children[1].value);
					if (val=='') {
						// ALL
						text = node.children[0].value;
					}
					else {
						// time: use %TimeRange()
						switch (node.value) {
						case '>':
							text = '%TimeRange(' + node.children[0].value + '.' + val + ',,EXCLUSIVE)';
							break;
						case '>=':
							text = '%TimeRange(' + node.children[0].value + '.' + val + ',)';
							break;
						case '<':
							text = '%TimeRange(,' + node.children[0].value + '.' + val + ',EXCLUSIVE)';
							break;
						case '<=':
							text = '%TimeRange(,' + node.children[0].value + '.' + val + ')';
							break;
						}
					}
				}
				else {
					var val = node.children[1].text;
					val = isNaN(val) ? '\"'+val+'\"' : val;
					
					// + DTB851 - Search up the parent change to count OR/AND flips.
					var testNode = node;
					var currentType = 'OR';		// Start with the OR since this is potentially about to add a %OR to the FILTER
					var flipCount = 0;		// Count the number of times the operator switches from 'OR' to 'AND' or vice versa
					while (testNode) {
						if (('logic'==testNode.type) && (currentType!=testNode.value)) {
							currentType = ('OR' == currentType) ? 'AND' : 'OR';
							flipCount++;
						}

						testNode = testNode._parent;
					}
					// - DTB851
					
					// data: Use %OR(FILTER(X.members,NAME OP value))
					// DTB259 - Wrap FILTER in a set within the %OR
					// DTB851 - Check the operator flipCount in the parent chain to decide whether adding the %OR is tolerable
					if (flipCount<2) {
						text = '%OR({FILTER(' + node.children[0].value + '.Members,' + node.children[0].value +'.CurrentMember.Properties(\"NAME\")' + node.value + val + ')})';
					}
					else {
						text = 'FILTER(' + node.children[0].value + '.Members,' + node.children[0].value +'.CurrentMember.Properties(\"NAME\")' + node.value + val + ')';				
					}
				}
				break;
			}

			break;
		}
	}
	obj.text = text;
	obj.hasSet = hasSet;
	obj.levelName = levelName;
	return obj;
}

/// Convert a key value to MDX.
ClientMethod keyToMDX(key) [ Language = javascript ]
{
	// JMD1276: check for $VARIABLE$
	if (key.toString().indexOf('&[$VARIABLE$')>=0) {
		key = '$variable.' + key.substring(12,key.length-1);	// DTB114 - don't strip extra character
	}
	return key;
}

/// Return the initial filter graph for a given cube and MDX expression.<br/>
/// pParameters("cube") = cube name<br/>
/// pParameters("expression") = MDX expression<br/>
Method BuildFilterGraph(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("type","text","value")

		Set tCube = $G(pParameters("cube"))
		// DTB336 - Look up data from the currently active cube version
		Set tCube = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tCube)
		
		Set tExpression = $G(pParameters("expression"))

		// + WAL228 -- expression is not getting passed in in this case
		If (..isNamedFilter) {
			Set:tExpression="" tExpression = ..expression
			Set:tCube="" tCube = ..cubeName
		}
		// - WAL228

		// parse expression
		If ((tCube'="") && (tExpression'="")) {
			Set tSC = ..%ConvertExpressionToGraph(.pData,tCube,tExpression)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// default

			/*
			Set pData(1) = $LB("logic","AND","AND")
			Set pData(1,1) = $LB("operator","IS","=")
			Set pData(1,1,1) = $LB("member","Product Category","[Product].[P1].[Product Category]")
			Set pData(1,1,2) = $LB("key","Dairy","&[Dairy]")
			*/
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert the given filter expression to a graph.
ClassMethod TEST(pExpression = "", pCube = "") [ Internal ]
{
	Set tCube = pCube
	Set:tCube="" tCube = "HOLEFOODS"
	Set:pExpression="" pExpression = "[Product].[P1].[Product Category].&[Dairy]"
	Set tSC = ..%ConvertExpressionToGraph(.pData,tCube,pExpression)
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
	ZW pData
}

/// Convert the given filter expression to a graph.
ClassMethod %ConvertExpressionToGraph(Output pData, pCubeName As %String, pExpression As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD1276: find all pivot variables in the expression
		// replace with a $VARIABLE$name so that it will parse
		Set tMarker = "$variable."
		Set tMDXLower = $$$LOWER(pExpression)
		If (tMDXLower[tMarker) {
			Set tMDX = ""
			Set p=1,next=1
			While (next>0) {
				Set next = $Find(tMDXLower,tMarker,next)
				If (next=0) {
					Set tMDX = tMDX _ $E(pExpression,p,*)
					Quit
				}
				Else {
					Set tMDX = tMDX _ $E(pExpression,p,next-$L(tMarker)-1)
					Set p = next
					While (($E(pExpression,next)'="")&&($ZNAME("X"_$E(pExpression,next)))) {
						Set next = next+1
					}
					Set tVar = $$$LOWER($E(pExpression,p,next-1))
					If (tVar="") {
						Set tMDX = tMDX _ tMarker
					}
					Else {
						Set tMDX = tMDX _ "$VARIABLE$"_tVar
					}
				}
				Set p = next
			}
			Set tExpression = tMDX
		}
		Else {
			Set tExpression = pExpression
		}

		// turn the expression into something we can parse!
		Set tMDX = "SELECT "_tExpression_" ON COLUMNS FROM [" _ pCubeName_ "]"

		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%ParseMDX(tMDX,.tQuery)		// DTB848 - Just parse the expression, %PrepareMDX can apply transforms
		If $$$ISERR(tSC) Quit

		If $IsObject(tQuery) {
			Set tAxis = tQuery.axes.GetAt(1)
			// convert axis to expression tree format!
			// axis should have only one child:
			Set tNode = tAxis.children.GetAt(1)
			If $IsObject(tNode) {
				New %nodeData
				Kill %nodeData
				Set tLVN = $Name(%nodeData(1))
				Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,tNode)
				If $$$ISERR(tSC) Quit
				Merge pData = %nodeData
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert the given DeepSee Axis Node to a graph.<br/>
/// <var>pLVN</var> is the name of the local variable in which results are placed.
ClassMethod %ConvertAxisNodeToGraph(pLVN As %String, pCubeName As %String, pNode As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		
		// Note: TIMERANGE is split apart and converted to multiple items
		// we *should* recombine them here

		If (pNode.%IsA("%DeepSee.Query.range")) {
			// range without %OR() wrapper
			// parse start and end specs into pieces
			Set tSC = ..%GetSpecInfo(pCubeName,pNode.startMember.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
			If $$$ISERR(tSC) Quit

			Set tSC = ..%GetSpecInfo(pCubeName,pNode.endMember.spec,.tSpec2,.tMemberCaption2,.tKey2,.tKeyCaption2)
			If $$$ISERR(tSC) Quit

			Set @pLVN = $LB("operator",$$$Text("IS"),"=")		// DTB849
			Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
			Set @pLVN@(2) = $LB("key",tKeyCaption_":"_tKeyCaption2,"&["_$$$dsEscapeIdent(tKey)_"]:&["_$$$dsEscapeIdent(tKey2)_"]")
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.calculatedMember")) {
			Set tSC = ..%GetSpecInfo(pCubeName,pNode.%ToString(),.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
			If $$$ISERR(tSC) Quit
			Set @pLVN = $LB("operator",$$$Text("IS"),"=")		// DTB849
			Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
			Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.memberSpec")) {
			Set tSC = ..%GetSpecInfo(pCubeName,pNode.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption,.tIsNot,.tIsRange)
			If $$$ISERR(tSC) Quit
			If ($$$UPPER(tSpec)="%SEARCH") {
				Set tSC = ..%ConvertSearchKeyToGraph(pLVN,pCubeName,tKey)
				If $$$ISERR(tSC) Quit
			}
			Else {
				If (tIsNot) {
					Set @pLVN = $LB("operator",$$$Text("IS NOT"),"<>")		// DTB849
				}
				Else {
					Set @pLVN = $LB("operator",$$$Text("IS"),"=")		// DTB849
				}
				Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
				
				If tIsRange {
					// DTB849 - The range key was returned with complete syntax
					Set @pLVN@(2) = $LB("key",tKeyCaption,tKey)
				}
				Else {
					Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
				}
			}
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.tuple")) {
			// note: tuple is a type of set, so test first!
			Set @pLVN = $LB("logic",$$$Text("AND"),"AND")		// DTB849
			For n=1:1:pNode.children.Count() {
				Set tLVN = $Name(@pLVN@(n))
				Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,pNode.children.GetAt(n))
				If $$$ISERR(tSC) Quit
			}
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.memberFunction")) {
			If (pNode.function="%NOT") {
				// IS NOT
				Set tChild = pNode.children.GetAt(1)
				Set tSC = ..%GetSpecInfo(pCubeName,tChild.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
				If $$$ISERR(tSC) Quit

				Set @pLVN = $LB("operator",$$$Text("IS NOT"),"<>")		// DTB849
				Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
				Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
			}
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.setFunction")) {
			If ((pNode.function="CROSSJOIN") || (pNode.function="NONEMPTYCROSSJOIN")) {
				Set @pLVN = $LB("logic",$$$Text("AND"),"AND")		// DTB849
				For n=1:1:pNode.children.Count() {
					Set tLVN = $Name(@pLVN@(n))
					Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,pNode.children.GetAt(n))
					If $$$ISERR(tSC) Quit
				}
			}
			ElseIf (pNode.function="EXCEPT") {
				// IS NOT
				Set tChild = pNode.children.GetAt(2)
				If (tChild.%IsA("%DeepSee.Query.range")) {
					Set tSC = ..%GetSpecInfo(pCubeName,tChild.startMember.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
					If $$$ISERR(tSC) Quit

					Set tSC = ..%GetSpecInfo(pCubeName,tChild.endMember.spec,.tSpec2,.tMemberCaption2,.tKey2,.tKeyCaption2)
					If $$$ISERR(tSC) Quit

					Set @pLVN = $LB("operator",$$$Text("IS NOT"),"<>")		// DTB849
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
					Set @pLVN@(2) = $LB("key",tKeyCaption_":"_tKeyCaption2,"&["_$$$dsEscapeIdent(tKey)_"]:&["_$$$dsEscapeIdent(tKey2)_"]")
				}
				Else {
					Set tSC = ..%GetSpecInfo(pCubeName,tChild.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
					If $$$ISERR(tSC) Quit

					Set @pLVN = $LB("operator",$$$Text("IS NOT"),"<>")		// DTB849
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
					Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
				}
			}
			ElseIf ($$$UPPER(pNode.function)="%TIMERANGE") {
				// JMD1041: operator on time member
				Set tArg1 = pNode.children.GetAt(1)
				Set tArg2 = pNode.children.GetAt(2)
				Set tFlag = pNode.children.GetAt(3)
				
				Set tInclusive = '($IsObject(tFlag)&&(tFlag.%GetValue()="EXCLUSIVE"))
				If (tArg1.%IsA("%DeepSee.Query.constant")) {
					Set tSC = ..%GetSpecInfo(pCubeName,tArg2.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
					If $$$ISERR(tSC) Quit
					Set @pLVN = $LB("operator",$S(tInclusive:"<=",1:"<"),$S(tInclusive:"<=",1:"<"))
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
					Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
				}
				Else {
					Set tSC = ..%GetSpecInfo(pCubeName,tArg1.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
					If $$$ISERR(tSC) Quit
					Set @pLVN = $LB("operator",$S(tInclusive:">=",1:">"),$S(tInclusive:">=",1:">"))
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
					Set @pLVN@(2) = $LB("key",tKeyCaption,"&["_$$$dsEscapeIdent(tKey)_"]")
				}
			}
			ElseIf (pNode.function="AGGREGATE") {
				// JMD1453 unwrap
				Set tChild = pNode.children.GetAt(1)
				Set tSC = ..%ConvertAxisNodeToGraph(pLVN,pCubeName,tChild)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (pNode.function="%OR") {
				// JMD875: this could %OR({A,B}), %OR(A:B), or %OR(FILTER...)
				Set tChild = pNode.children.GetAt(1)
				If (tChild.%IsA("%DeepSee.Query.setFunction")) {
					If (tChild.function="FILTER") {
						Set tArg1 = tChild.children.GetAt(1)
						// JMD1217 test for different types
						If (tArg1.%IsA("%DeepSee.Query.memberSpec")) {
							Set tSpec1 = tArg1.spec
						}
						Else {
							Set tSpec1 = tArg1.children.GetAt(1).spec
						}
						Set tArg2 = tChild.children.GetAt(2)
						Set tSC = ..%GetSpecInfo(pCubeName,tSpec1,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
						If $$$ISERR(tSC) Quit

						If (tArg2.%IsA("%DeepSee.Query.expression")) {
							Set tOp = tArg2.operator
							Set tValue = tArg2.children.GetAt(2).%GetValue()
							Set @pLVN = $LB("operator",tOp,tOp)
							Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)

							// find the key for the given name
							// there is no API for this; use brute force
							// Get members of the given filter
							// tFilters(n) = $LB(text,value)
							Kill tMbrList
							Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(pCubeName_".cube",tSpec1,.tMbrList)
							If $$$ISERR(tSC) Quit

							Set tKey = ""
							Set k = $O(tMbrList(""))
							While (k'="") {
								If ($LG(tMbrList(k),1)=tValue) {
									Set tKey = $LG(tMbrList(k),2)
									Quit
								}
								Set k = $O(tMbrList(k))
							}

							Set @pLVN@(2) = $LB("key",tValue,tKey)
						}
					}
				}
				ElseIf (tChild.%IsA("%DeepSee.Query.set")) {

					// DP-426144 - In the special case where this is reached for the very top node of the graph, do add an OR operator
					If (tChild.children.Count()=1)&&($O(@pLVN@(""))'="") {
						// DTB553 - Recurse straight into the set
						Set tLVN = $Name(@pLVN)
						Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,tChild.children.GetAt(1))
						If $$$ISERR(tSC) Quit
					}
					Else {
						// DTB553 - Add this node when there are multiple children		// DTB849
						Set @pLVN = $LB("logic",$$$Text("OR"),"OR")
						For n=1:1:tChild.children.Count() {
							Set tLVN = $Name(@pLVN@(n))
							Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,tChild.children.GetAt(n))
							If $$$ISERR(tSC) Quit
						}
					}
				}
				ElseIf (tChild.%IsA("%DeepSee.Query.memberSpec")) {
					// JMD1453 dispatch
					Set tChild = pNode.children.GetAt(1)
					Set tSC = ..%ConvertAxisNodeToGraph(pLVN,pCubeName,tChild)
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tChild.%IsA("%DeepSee.Query.range")) {
					// parse start and end specs into pieces
					Set tSC = ..%GetSpecInfo(pCubeName,tChild.startMember.spec,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
					If $$$ISERR(tSC) Quit

					Set tSC = ..%GetSpecInfo(pCubeName,tChild.endMember.spec,.tSpec2,.tMemberCaption2,.tKey2,.tKeyCaption2)
					If $$$ISERR(tSC) Quit

					Set @pLVN = $LB("operator",$$$Text("IS"),"=")		// DTB849
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)
					Set @pLVN@(2) = $LB("key",tKeyCaption_":"_tKeyCaption2,"&["_$$$dsEscapeIdent(tKey)_"]:&["_$$$dsEscapeIdent(tKey2)_"]")
				}
			}
			ElseIf (pNode.function="FILTER") {
				// DTB553 - FILTER is passed in directly
				Set tArg1 = pNode.children.GetAt(1)
				// JMD1217 test for different types
				If (tArg1.%IsA("%DeepSee.Query.memberSpec")) {
					Set tSpec1 = tArg1.spec
				}
				Else {
					Set tSpec1 = tArg1.children.GetAt(1).spec
				}
				Set tArg2 = pNode.children.GetAt(2)
				Set tSC = ..%GetSpecInfo(pCubeName,tSpec1,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
				If $$$ISERR(tSC) Quit

				If (tArg2.%IsA("%DeepSee.Query.expression")) {
					Set tOp = tArg2.operator
					Set tValue = tArg2.children.GetAt(2).%GetValue()
					Set @pLVN = $LB("operator",tOp,tOp)
					Set @pLVN@(1) = $LB("member",tMemberCaption,tSpec)

					// find the key for the given name
					// there is no API for this; use brute force
					// Get members of the given filter
					// tFilters(n) = $LB(text,value)
					Kill tMbrList
					Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(pCubeName_".cube",tSpec1,.tMbrList)
					If $$$ISERR(tSC) Quit

					Set tKey = ""
					Set k = $O(tMbrList(""))
					While (k'="") {
						If ($LG(tMbrList(k),1)=tValue) {
							Set tKey = $LG(tMbrList(k),2)
							Quit
						}
						Set k = $O(tMbrList(k))
					}

					Set @pLVN@(2) = $LB("key",tValue,tKey)
				}
			}
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.set")) {
			// Use of {} for OR
			Set @pLVN = $LB("logic",$$$Text("OR"),"OR")		// DTB849
			For n=1:1:pNode.children.Count() {
				Set tLVN = $Name(@pLVN@(n))
				Set tSC = ..%ConvertAxisNodeToGraph(tLVN,pCubeName,pNode.children.GetAt(n))
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a measure search key to a graph. "[Measures].[X].100"<br/>
/// <var>pLVN</var> is the name of the local variable in which results are placed.
ClassMethod %ConvertSearchKeyToGraph(pLVN As %String, pCubeName As %String, pKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.Query.Parser).%Tokenize(pKey,.tTokens)
		If $$$ISERR(tSC) Quit

		// for now, we only support very simple expressions of the form
		// measure op value

		Set tState = 0
		Set tMeasure = ""
		Set tOp = ""
		Set tValue = ""

		Set k = $O(tTokens(""))
		While (k'="") {
			Set tType = $LG(tTokens(k),1)
			Set tToken = $LG(tTokens(k),2)
			If (tState = 0) {
				If (tType = "OP") {
					Set tState = 1
					Set tOp = tToken
				}
				ElseIf (tType = "STR") && (tToken = "LIKE") {
					Set tState = 1
					Set tOp = tToken
				}
				Else {
					Set tMeasure = tMeasure _ tToken
				}
			}
			ElseIf (tState=1) {
				// JMD1081 concatenate as ' quotes are sent separately
				Set tValue = tValue _ tToken
			}

			// next
			Set k = $O(tTokens(k))
		}

		Set tSC = ..%GetSpecInfo(pCubeName,tMeasure,.tSpec,.tMemberCaption,.tKey,.tKeyCaption)
		If $$$ISERR(tSC) Quit

		Set @pLVN = $LB("measureOperator",tOp,tOp)
		Set @pLVN@(1) = $LB("measure","Measures."_tMemberCaption,tMeasure)
		Set @pLVN@(2) = $LB("literal",tValue,tValue)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility. Get information on the given member spec.<br/>
/// <var>pSpec</var> takes the form: "dim.hier.level.member"<br/>
/// On return, <var>pMemberSpec</var> contains: "dim.hier.level",
/// <var>pMemberCaption</var> contains the caption for the member,
/// <var>pKey</var> contains the key value for the member, and
/// <var>pKeyCaption</var> contains the caption for the member.
ClassMethod %GetSpecInfo(pCubeName As %String, pSpec As %String, Output pMemberSpec As %String, Output pMemberCaption As %String, Output pKey As %String, Output pKeyCaption As %String, Output pIsNot As %Boolean, Output pIsRange As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// used for relationships
		Set pIsNot = 0
		Set pIsRange = 0		// DTB849

		// lookup spec, parse into pieces
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName, pSpec, .tDimNo, .tHierNo, .tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo,,0)
		If $$$ISERR(tSC) Quit

		// check for relationship
		If (tRelationName '="") {
			Kill tSpecInfo(1)
			Set tSpec = ""
			Set tSpec1 = ""		// DTB849 - It's possible this is a range. If ":" is found, accumulate a second spec
			Set k = $O(tSpecInfo(""))
			While (k'="") {
				If ($G(tSpecInfo(k))="%NOT") {
					Set pIsNot = 1
				}
				ElseIf (tSpecInfo(k)=":") {
					Set pIsRange = 1
					Kill tSpecInfo(k+1)		// DTB849 - Kill the nex range relation name, analogous to tSpecInfo(1)
				}
				ElseIf pIsRange {
					Set tSpec1 = tSpec1 _ $S(tSpec1="":"",1:".") _ "["_$G(tSpecInfo(k))_"]"
				}
				Else {
					Set tSpec = tSpec _ $S(tSpec="":"",1:".") _ "["_$G(tSpecInfo(k))_"]"
				}

				Set k = $O(tSpecInfo(k))
			}
			
			Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"relations",$$$UPPER(tRelationName),"relatedCube"))
			Set tSC = ..%GetSpecInfo(tRelatedCube,tSpec,.tMemberSpec,.tMemberCaption,.tKey,.tKeyCaption)
			If $$$ISERR(tSC) Quit

			// JMD1216: tack relation name onto caption
			Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(pCubeName, tRelationName,,,.tRelationCaption)
			If $$$ISERR(tSC) Quit

			If pIsRange {
				// Rebuild range from both specs 
				Set tSC = ..%GetSpecInfo(tRelatedCube,tSpec1,.tMemberSpec1,.tMemberCaption1,.tKey1,.tKeyCaption1)
				If $$$ISERR(tSC) Quit
				
				Set pMemberSpec = "["_tRelationName_"]." _ tMemberSpec
				Set pMemberCaption = tRelationCaption_"." _ tMemberCaption
				
				Set pKey = "&[" _ $$$dsEscapeIdent(tKey) _ "]:&[" _ $$$dsEscapeIdent(tKey1) _ "]"
				Set pKeyCaption = tKeyCaption _ ":" _ tKeyCaption1
			}
			Else {
				// tack relation name onto spec
				Set pMemberSpec = "["_tRelationName_"]." _ tMemberSpec
				Set pKey = tKey
				Set pKeyCaption = tKeyCaption
				Set pMemberCaption = tRelationCaption_"." _ tMemberCaption
			}
			Quit
		}

		Set tSpec = "["_$G(tSpecInfo(1))_"]"
		Set:$G(tSpecInfo(2))'="" tSpec = tSpec _ ".["_$G(tSpecInfo(2))_"]"
		Set:$G(tSpecInfo(3))'="" tSpec = tSpec _ ".["_$G(tSpecInfo(3))_"]"
		Set pKey = $G(tSpecInfo(4))

		If ($$$UPPER($G(tSpecInfo(1))) = "%SEARCH") {
			// this is a search on a measure
			Set pMemberSpec = tSpecInfo(1)
			Set pMemberCaption = "SEARCH"
			Quit
		}

		If (tDimNo="") {
			Set tSC = $$$ERROR($$$GeneralError,"No dimension found for spec: " _ pSpec)
			Quit
		}
		
		If (tDimNo < 0) {
			// calc member
			// calculated member
			Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(pCubeName, $$$UPPER($G(tSpecInfo(1))),,,.pMemberCaption)
			If $$$ISERR(tSC) Quit
			Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(pCubeName, $$$UPPER($G(tSpecInfo(1))), $$$UPPER($G(tSpecInfo(2))),,.pKeyCaption)
			If $$$ISERR(tSC) Quit
			
			Set pMemberSpec = "["_$G(tSpecInfo(1))_"]"
			Set pKey = $G(tSpecInfo(2))
			Quit
		}

		// get captions
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName, tDimNo, tHierNo, tLevelNo, .pMemberCaption)
		If $$$ISERR(tSC) Quit

		If (pKey="") {
			Set pKeyCaption = $$$Text("All","%DeepSee")
		}
		Else {
			// JMD1276: check for $VARIABLE$
			If ($E(pKey,1,10)="$VARIABLE$") {
				Set pKeyCaption = "$variable."_$E(pKey,11,*)
			}
			Else {
				Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(pCubeName, tSpec, pKey, .pKeyCaption)
				If $$$ISERR(tSC) Quit
			}
		}
		Set pMemberSpec = tSpec
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the list of members for a given cube and dimension.<br/>
/// pParameters("cube") = cube name<br/>
/// pParameters("dimension") = cube element<br/>
/// pParameters("search") = search key<br/>
Method GetMemberList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		
		Set pMetaData = $LB("text","value","isCalc")

		Set tCube = $G(pParameters("cube"))
		// DTB336 - Look up data from the currently active cube version
		Set tCube = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tCube)
		
		Set tDataSource = $S(tCube'="":tCube_".cube",1:"")
		Set tElement = $G(pParameters("dimension"))
		Set tSearchKey = $G(pParameters("search"))

		// test for calc members
		Set tIsCalc = 0
		Set tCube = $$$UPPER($G(pParameters("cube")))
		Set tName = $$$UPPER(tElement)
		If ((tCube'="")&&(tName'="")) {
			// remove []
			Set:$E(tName)="[" tName = $E(tName,2,*-1)
			Set tIsCalc = ''$D($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tName))
		}

		// Get members of the given filter
		// tFilters(n) = $LB(text,value)
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(tDataSource,tElement,.tFilters,.tDefaultFilterValue,tSearchKey)
		If $$$ISERR(tSC) Quit

		Set k = $O(tFilters(""))
		While (k'="") {
			Set pData($I(pData)) = tFilters(k)
			Set k = $O(tFilters(k))
		}

		// JMD1276: add pivot variables to the list (move to end)
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetPivotVariablesForDataSource(tDataSource,.tVariables)
		If $$$ISERR(tSC) Quit
		Set k = $O(tVariables(""))
		While (k'="") {
			// use logical value!
			Set pData($I(pData)) = $LB("$variable."_$LG(tVariables(k),1),"$variable."_$LG(tVariables(k),1))
			Set k = $O(tVariables(k))
		}

		// add isCalc to first item in list
		If $D(pData(1)) {
			Set $List(pData(1),3) = tIsCalc
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return true if it is possible to undo an action
ClientMethod canUndo() [ Language = javascript ]
{
	return this._undoBuffer && (this._undoIndex > 0);
}

/// Undo the most recent change.
ClientMethod undo() [ Language = javascript ]
{
	if (this.canUndo()) {
		this._undoIndex--;
		var oldgraph = this._undoBuffer[this._undoIndex];
		var json = this.getComponentById('filterGraph');
		json.setContentObject(oldgraph);
		this.renderTree();
		this.renderCommands();

		if (this._undoIndex == 0) {
			// change undo button state
			var undo = self.document.getElementById('cmdUndo');
			if (undo) {
				undo.disabled = true;
				undo.className = 'optButtonDisabled';
			}
		}
	}
}

ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	delete this._undoBuffer;
	delete this._undoIndex;

	// change undo button state
	var undo = self.document.getElementById('cmdUndo');
	if (undo) {
		undo.disabled = true;
		undo.className = 'optButtonDisabled';
	}
}

/// Remember the current state in the undo buffer.
ClientMethod addUndoAction() [ Language = javascript ]
{
	if (null == this._undoBuffer) {
		this._undoBuffer = new Array();
		this._undoIndex = 0;
	}

	// remember copy of current graph as state
	var graph = this.getFilterGraph();
	var oldgraph = new Object();
	oldgraph.children = new Array();
	oldgraph.children[0] = this.cloneObject(graph);
	this._undoBuffer[this._undoIndex] = oldgraph;
	this._undoIndex++;

	// change undo button state
	var undo = self.document.getElementById('cmdUndo');
	if (undo) {
		undo.disabled = false;
		undo.className = 'optButton';
	}
}

/// Create a clone of the given object.
ClientMethod cloneObject(obj, clone) [ Language = javascript ]
{
	var clone = clone ? clone : new Object();
	for (var i in obj) {
		if ((i == '_parent')||(i == '_index')) {
			// skip back pointers
		}
		else if (null == obj[i]) {
			clone[i] = null;
		}
		else if (typeof obj[i] === 'object') {
			clone[i] = (obj[i].constructor === Array) ? new Array(): new Object();
			this.cloneObject(obj[i],clone[i]);
		}
		else {
			clone[i] = obj[i];
		}
	}
	return clone;
}

/// Save a named filter.
ClassMethod SaveNamedFilter(pCube As %String, pFilterName As %String, pTooltip As %String, pSpec As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tSC = ##class(%DeepSee.Utils).%SaveNamedFilter(pCube,pFilterName,pTooltip,pSpec)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Given a complete reference to a key, look up the display text. 
ClassMethod LookupMemberByKey(pCubeName = "", pLevelSpec = "", pKey = "") As %String [ ZenMethod ]
{
	// Method added by DTB849
	Set tReturn = ""
	
	Try {
		// Don't bother continuing if there is no key to begin with
		If (pKey="") {
			Quit
		}
		
		// The incoming key needs to be parsed to make sure the &[] is properly removed and
		// the string being considered is the true key
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pKey,.tInfo)
		If $$$ISERR(tSC) Quit
		Set tKey = $O(tInfo(""),-1)		// It's possible the incoming key is actually a multi-pieced reference. Take only the final piece as the key.
		
		If (pCubeName="")||(pLevelSpec="") {
			// No way to find a translated member with provided information, return the key
			Set tReturn = tKey
		}
		
		Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(pCubeName, pLevelSpec, pKey, .tReturn)
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tReturn = ""
	}
	
	Quit tReturn
}

}
