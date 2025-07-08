/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user change the properties of a level within a DeepSee pivot table.
Class %DeepSee.UI.Dialog.PivotLevelOptions Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Mode ("axis" -- options for entire axis, "level", or "measures").
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "level" ];

/// Type of member specified (determined from spec).
Property memberType As %ZEN.Datatype.string [ InitialExpression = "mbr" ];

/// Subject Area.
Property subjectArea As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Saved pivot (if present).
/// Used to get local calculated members.
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOTNAME");

/// Index of component that launched this dialog.
Property compIndex As %ZEN.Datatype.integer(ZENURL = "INDEX");

/// Text of current member.
Property memberText As %ZEN.Datatype.string(ZENURL = "TEXT");

/// Spec of current member.
Property memberSpec As %ZEN.Datatype.string(ZENURL = "SPEC");

/// If true, apply the HEAD function to this level.
Property headEnabled As %ZEN.Datatype.boolean(ZENURL = "HEAD");

/// Count argument for HEAD function.
Property headCount As %ZEN.Datatype.integer(ZENURL = "HEADCOUNT");

/// If true, apply the FILTER function to this level.
Property filterEnabled As %ZEN.Datatype.boolean(ZENURL = "FILTER");

/// Filter expression for FILTER function.
Property filterExpression As %ZEN.Datatype.string(ZENURL = "FILTEREXPR");

/// If true, apply the ORDER function to this level.
Property orderEnabled As %ZEN.Datatype.boolean(ZENURL = "ORDER");

/// Sort expression for ORDER function.
Property orderExpression As %ZEN.Datatype.string(ZENURL = "ORDEREXPR");

/// Direction argument for ORDER function.
Property orderDirection As %ZEN.Datatype.string(ZENURL = "ORDERDIR");

/// If true, apply an aggregate function to this level.
Property aggEnabled As %ZEN.Datatype.boolean(ZENURL = "AGG");

/// If enabled, aggregate function for this level.
Property aggFunction As %ZEN.Datatype.string(ZENURL = "AGGFUNC");

/// If enabled, aggregate function parameter for this level.
Property aggFunctionParm As %ZEN.Datatype.string(ZENURL = "AGGFUNCPARM");

/// Optional caption to apply to this element.
Property levelCaption As %ZEN.Datatype.string(ZENURL = "LEVELCAPTION");

/// Optional format to apply to this element.
Property levelFormat As %ZEN.Datatype.string(ZENURL = "LEVELFORMAT");

/// Optional style to apply to this element.
Property levelStyle As %ZEN.Datatype.string(ZENURL = "LEVELSTYLE");

/// Optional style to apply to this element.
Property levelHeaderStyle As %ZEN.Datatype.string(ZENURL = "LEVELHEADERSTYLE");

/// Optional summary aggregate for this element.
Property levelSummary As %ZEN.Datatype.string(ZENURL = "LEVELSUMMARY");

/// For row/column options, indicates the type of member defined.
Property levelType As %ZEN.Datatype.string(ZENURL = "LEVELTYPE");

/// Value of this option (for mdx and value types).
Property levelValue As %ZEN.Datatype.string(ZENURL = "VALUE");

/// If true, apply the 80/20 suppression to this level.
Property suppress8020 As %ZEN.Datatype.boolean(ZENURL = "SUPPRESS");

/// Value of the drilldown spec option.
Property drilldownSpec As %ZEN.Datatype.string(ZENURL = "DRILLDOWNSPEC");

/// Value for measureLocation.
Property measureLocation As %ZEN.Datatype.string(ZENURL = "MEASURELOCATION");

/// Value for hideMeasures.
Property hideMeasures As %ZEN.Datatype.string(ZENURL = "HIDEMEASURES");

/// Create an isCalculated property with 0 as default:
Property isCalculated As %Integer [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">

textarea {
	white-space: pre;
	word-wrap: normal;
	overflow-x: scroll;
}

.expandoNode {
	border-top: 1px solid #D0D0D0;
	color: #606060;
	font-size: 10pt;
}

#styleHTML,#headerStyleHTML {
	border: 1px solid black;
	background: white;
	font-family: arial;
	font-size: 20px;
	width: 250px;
	height: 25px;
	white-space:nowrap;
	overflow: hidden;
}

#chartIconBox, #gridLineBox, #textSizeBox {
	width: 500px;
	height: 52px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: auto;
}

#chartIconBox {
	height: 150px;
}

#ctrlFilter,#ctrlHead,#ctrlOrder,#ctrlAgg,#ctrlSuppress,#ctrlDrilldown {
	padding-top: 8px;
	font-weight: bold;
	color: #404040;
	font-size: 12pt;
}

.specLabel {
	color: #404040;
	font-size: 9pt;
}

.helpLabel {
	color: #404040;
	font-size: 11pt;
}

.Icon,.IconSelected {
	padding: 4px;
	display: block;
	text-decoration: none;
	color: black;
}

.IconSelected {
	padding: 1px;
	border: 2px solid darkred;
}

.Icon:hover, .IconSelected:hover {
	background: #FFEEAA;
}

.Icon img {
	border: none;
}

.radioSetCaption {
	color: #404040;
	font-size: 9pt;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<vgroup id="measuresGroup" enclosingStyle="display:none;">
<radioSet id="radioMeasureLocation" label="Place measures on:" valueList="columns,rows" displayList="Columns,Rows"/>
<spacer height="10"/>
<radioSet id="radioHideMeasures" label="Display measure headers:" valueList="1,0,2" displayList="If More Than 1 Measure,Always,Never"/>
</vgroup>

<vgroup id="mainGroup" enclosingStyle="display:none;">
<!-- hide for more space -->
<text id="member" label="Dimension" hidden="true" value="#(%page.memberText)#" readOnly="true" size="40"/>

<label id="spec" value="#(%page.memberSpec)#" title="#(%page.memberSpec)#" controlClass="specLabel"/>

<!-- options are set in %OnAfterPage -->
<radioSet id="radioType" label="Show" onchange="zenPage.changeType(true);"/>

<hgroup id="groupCaption" cellVAlign="top">
<text id="ctrlCaption" label="Caption" value="#(%page.levelCaption)#" size="25" title="Optional caption to apply" hint="For example, Year *"/>
</hgroup>

<expando animate="false" expanded="false" caption="Format and Style">
<hgroup cellVAlign="top" label="Format" title="Optional format to apply" hint="For example, #,###.#">
<text id="ctrlFormat" value="#(%page.levelFormat)#" size="25" />
<image src="deepsee/zoom_16.png" width="16px" onclick="zenPage.editFormatString();" title="Launch format builder"/>
</hgroup>

<select id="ctrlSummary" label="Total Override" hint="Override aggregate used for pivot total" valueList="sum,count,min,max,avg,pct,none" displayList="Sum,Count,Min,Max,Average,% of Total,None" />

<spacer height="10"/>
<deepsee:styleEdit id="styleCell" label="Cell Style" onchange="zenPage.applyChange('styleCell','cell');"/>
<spacer height="10"/>
<deepsee:styleEdit id="styleHeader" label="Header Style" onchange="zenPage.applyChange('styleHeader','header');"/>
<spacer height="10"/>
</expando>

<vgroup id="groupMembers" hidden="true">
<expando animate="false" caption="Member Options">
<checkbox id="ctrlFilter" value="#(%page.filterEnabled)#" caption="Filter members" hint="Only include members that meet the following condition" onchange="zenPage.updateState('filter',zenThis.value);"/>
<hgroup cellVAlign="bottom" containerStyle="padding-left:12px;">
<radioButton id="rbFilterMsr" name="rbFilter" optionValue="msr" onchange="zenPage.updateState();"/>
<select id="ctrlFilterExprMsr" label="Measure" disabled="true" required="true" showEmpty="false"/>
<spacer width="20"/>
<radioButton id="rbFilterProp" name="rbFilter"  optionValue="prop" onchange="zenPage.updateState();"/>
<select id="ctrlFilterExprProp" label="Property"  disabled="true" required="true" showEmpty="false"/>
<spacer width="20"/>
<select id="ctrlFilterOp" disabled="true" required="true" showEmpty="false" valueList="=,&gt;,&gt;=,&lt;,&lt;=,&lt;&gt;"/>
<spacer width="20"/>
<text id="ctrlFilterValue" label="Value" disabled="true" size="6"/>
</hgroup>

<checkbox id="ctrlOrder" value="#(%page.orderEnabled)#" caption="Sort members" hint="Sort members by the following condition" onchange="zenPage.updateState('order',zenThis.value);"/>

<hgroup cellVAlign="bottom" containerStyle="padding-left:12px;">
<radioButton id="rbOrderMsr" name="rbOrder" optionValue="msr" onchange="zenPage.updateState();"/>
<select id="ctrlOrderExprMsr" label="Sort by measure" disabled="true" required="true" showEmpty="false"/>
<spacer width="20"/>
<radioButton id="rbOrderProp" name="rbOrder"  optionValue="prop" onchange="zenPage.updateState();"/>
<select id="ctrlOrderExprProp" label="Sort by property"  disabled="true" required="true" showEmpty="false"/>
</hgroup>

<select id="ctrlOrderDir" label="Sort order" value="#(%page.orderDirection)#" 
containerStyle="padding-left:38px;"
valueList="BASC,BDESC" displayList="Ascending,Descending" required="true" disabled="true"/>

<checkbox id="ctrlHead" value="#(%page.headEnabled)#" caption="Return the first n members" onchange="zenPage.updateState('head',zenThis.value);"/>

<text id="ctrlHeadCount" label="Count" value="#(%page.headCount)#" size="10" disabled="true" containerStyle="padding-left:38px;"/>

<checkbox id="ctrlAgg" value="#(%page.aggEnabled)#" caption="Compute Aggregate" hint="Compute a function on the members" onchange="zenPage.updateState('agg',zenThis.value);"/>
<hgroup cellVAlign="top">
<select id="ctrlAggFunc" label="Aggregate" disabled="true" required="true" 
containerStyle="padding-left:38px;"
onchange="zenPage.updateState();"
showEmpty="false" valueList="SUM,AVG,MIN,MAX,COUNT,COUNT NONEMPTY,AGGREGATE,MEDIAN,STDDEV,VARIANCE,PERCENTILE"/>
<spacer width="20"/>
<text id="ctrlAggFuncParm" label="Percentile" hint="0 to 100" value="#(%page.aggFunctionParm)#" size="10" disabled="true"/>
</hgroup>

<checkbox id="ctrlSuppress" value="#(%page.suppress8020)#" caption="Apply 80/20 Suppression" onchange="zenPage.updateState('suppress',zenThis.value);" hint="Show only the top 80% and group the rest."/>

</expando>

<expando animate="false" id="drillDownGroup" caption="Drilldown Options">

<checkbox id="ctrlDrilldown" caption="Disable drilldown" onchange="zenPage.disableDrilldown();"/>
<hgroup cellVAlign="top">
<textarea id="ctrlDrilldownSpec" label="Drilldown Expression" hint="What to show when an item is double-clicked. One expression per line." cols="50" rows="8"/>
<vgroup>
<spacer height="25px"/>
<image src="deepsee/ds2_plus_44.png" width="16px" onclick="zenPage.buildExpression();" title="Launch the expression builder to add a drill down term"/>
</vgroup>
</hgroup>
</expando>

</vgroup>

<vgroup id="groupValue" hidden="true">
<label label="Place a constant value in this axis." labelClass="helpLabel"/>
<spacer height="5"/>
<text id="ctrlValue" label="Value" hint="Display a constant value in cells; use quotes for string values" size="30"/>
</vgroup>
<vgroup id="groupMDX" hidden="true">
<label label="Add an MDX expression to this axis." labelClass="helpLabel"/>
<spacer height="5"/>
<textarea id="ctrlMDX" label="MDX Expression" hint="MDX expression to place in this axis" cols="55" rows="5"/>
</vgroup>
<vgroup id="groupSpace" hidden="true">
<label label="Place an empty space in this axis" labelClass="helpLabel"/>
</vgroup>

<vgroup id="groupMeasure" hidden="true">
<spacer height="10"/>

<label label="Modify the measure in this axis"  labelClass="helpLabel"/>
<select id="ctrlMsrAgg" label="Measure Aggregate" required="true" 
hint="Override the default aggregate applied to this measure"
showEmpty="true" valueList="SUM,AVG,MIN,MAX,COUNT"/>

</vgroup>

</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..mode,"axis":$$$TextHTML("Axis Options"),"measures":$$$TextHTML("Measure Options"),:$$$TextHTML("Level Options"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $Case(..mode,"axis":$$$TextHTML("Change options for a Pivot Table axis."),"measures":$$$TextHTML("Change options for measures."),:$$$TextHTML("Change options for a Pivot Table level."))
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	if (this.mode=='measures') {
		// + WAL114 -- use object to return measure settings
		var measureSettings = new Object();
		measureSettings.measureLocation = zen('radioMeasureLocation').getValue();
		measureSettings.hideMeasures = zen('radioHideMeasures').getValue();
		return measureSettings;
		// - WAL114
	}
	return '';
}

ClientMethod getPivotObject() [ Language = javascript ]
{
	var main = this.getOpener() ? this.getOpener() : window.opener;
	return main.zenPage.getPivot();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.mode=='measures') {
			return true;
		}
		// get arg values
		var newTarget = new Object();
		newTarget.headEnabled = this.headEnabled;
		newTarget.headCount = zen('ctrlHeadCount').getValue();

		newTarget.suppress8020 = this.suppress8020;

		// JMD1276: fix undefined spec
		newTarget.spec = this.memberSpec;

		newTarget.filterEnabled = this.filterEnabled;
		newTarget.canDrillDown = this.getPivotObject().canDrillDown;
		// figure out the filter expression
		var expr = '';
		if (this.filterEnabled) {
			// JMD1276: do not apply filter expression unless it is on!
			if ('prop' == zen('rbFilterMsr').getValue()) {
				expr = zen('ctrlFilterExprProp').getValue();
			}
			else {
				expr = zen('ctrlFilterExprMsr').getValue();
			}
		
			var val = zen('ctrlFilterValue').getValue();
			if (''==val) { val = 0; }
			if (val.toString().charAt(0)=='.') {
				// number must have leading 0
				val = '0' + val;
			}
			expr = expr + zen('ctrlFilterOp').getValue() + val; 
		}
		newTarget.filterExpression = expr;

		newTarget.orderEnabled = this.orderEnabled;
		newTarget.orderDirection = zen('ctrlOrderDir').getValue();
		
		// assemble drilldown spec
		newTarget.drilldownSpec = '';
		var dspec = zen('ctrlDrilldownSpec').getValue();
		if (dspec) {
			// WAL017 
  			var t = dspec.toString().replace('\r',''); 
  			t = t.toString().split('\n'); 
			newTarget.drilldownSpec = t.join('^');
		}

		// figure out the sort expression
		if (this.orderEnabled) {
			if ('prop' == zen('rbOrderMsr').getValue()) {
				newTarget.orderExpression = zen('ctrlOrderExprProp').getValue();
			}
			else {
				newTarget.orderExpression = zen('ctrlOrderExprMsr').getValue();
			}
		}

		if (this.memberType=='msr') {
			newTarget.aggEnabled = false;
			newTarget.aggFunction = zen('ctrlMsrAgg').getValue();
			newTarget.aggFunctionParm = '';
		}
		else {
			newTarget.aggEnabled = this.aggEnabled;
			newTarget.aggFunction = zen('ctrlAggFunc').getValue();
			newTarget.aggFunctionParm = zen('ctrlAggFuncParm').getValue();
		}

		newTarget.levelCaption = zen('ctrlCaption').getValue();
		newTarget.levelFormat = zen('ctrlFormat').getValue();
		newTarget.levelType = zen('radioType').getValue();
		newTarget.levelStyle = this.levelStyle;
		newTarget.levelHeaderStyle = this.levelHeaderStyle;
		newTarget.levelSummary = zen('ctrlSummary').getValue();

		switch (newTarget.levelType) {
		case 'value':
			newTarget.value = zen('ctrlValue').getValue();
			break;
		case 'mdx':
			newTarget.value = zen('ctrlMDX').getValue();
			break;
		default:
			newTarget.value = '';
			break;
		}

		// JMD: support older versions!
		var main = this.getOpener ? this.getOpener() : window.opener;
		var control = main.zenPage.getComponent(this.compIndex);
		control._newTarget = newTarget; // use this to pass back values
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Update state of controls on this page.
ClientMethod updateState(which, flag) [ Language = javascript ]
{
	switch(which) {
	case 'head':
		this.headEnabled = flag ? true : false;
		break;
	case 'suppress':
		this.suppress8020 = flag ? true : false;
		break;
	case 'filter':
		this.filterEnabled = flag ? true : false;
		break;
	case 'order':
		this.orderEnabled = flag ? true : false;
		break;
	case 'agg':
		this.aggEnabled = flag ? true : false;
		break;
	}
	
	// turn controls on/off
	// head
	zen('ctrlHeadCount').setProperty('disabled',!this.headEnabled);

	// filter
	zen('rbFilterProp').setProperty('disabled',!this.filterEnabled);
	zen('rbFilterMsr').setProperty('disabled',!this.filterEnabled);

	var isprop = ('prop' == zen('rbFilterMsr').getValue());
	zen('ctrlFilterExprMsr').setProperty('disabled',!this.filterEnabled || isprop);
	zen('ctrlFilterExprProp').setProperty('disabled',!this.filterEnabled || !isprop);
	zen('ctrlFilterOp').setProperty('disabled',!this.filterEnabled);
	zen('ctrlFilterValue').setProperty('disabled',!this.filterEnabled);

	// order
	zen('ctrlOrderDir').setProperty('disabled',!this.orderEnabled);
	zen('rbOrderProp').setProperty('disabled',!this.orderEnabled);
	zen('rbOrderMsr').setProperty('disabled',!this.orderEnabled);

	var isprop = ('prop' == zen('rbOrderMsr').getValue());
	zen('ctrlOrderExprMsr').setProperty('disabled',!this.orderEnabled || isprop);
	zen('ctrlOrderExprProp').setProperty('disabled',!this.orderEnabled || !isprop);

	// agg
	zen('ctrlAggFunc').setProperty('disabled',!this.aggEnabled);
	var parmEnabled = this.aggEnabled && zen('ctrlAggFunc').getValue()=='PERCENTILE';
	zen('ctrlAggFuncParm').setProperty('disabled',!parmEnabled);
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	// remember if drilldown was previously disabled
	document.getElementById("ctrlDrilldown").getElementsByClassName("checkbox")[0].checked = !this.getPivotObject().canDrillDown;
	if (!this.getPivotObject().canDrillDown) {
		this.disableDrilldown();
	}
	
	if (this.mode=='measures') {
		zen('radioMeasureLocation').setValue(this.measureLocation);
		zen('radioHideMeasures').setValue(this.hideMeasures); // + WAL114
		zen('measuresGroup').setProperty('enclosingStyle','display:block;');
		return;
	}
	
	this.updateStyleControls();

	zen('ctrlOrderDir').setValue(this.orderDirection);
	zen('ctrlAggFunc').setValue(this.aggFunction);
	zen('ctrlAggFuncParm').setValue(this.aggFunctionParm);

	zen('ctrlCaption').setValue(this.levelCaption);
	zen('ctrlFormat').setValue(this.levelFormat);
	zen('radioType').setValue(this.levelType);
	zen('ctrlSummary').setValue(this.levelSummary);

	switch (this.levelType) {
	case 'value':
		zen('ctrlValue').setValue(this.levelValue);
		zen('ctrlMDX').setValue('');
		break;
	case 'mdx':
		zen('ctrlValue').setValue('');
		zen('ctrlMDX').setValue(this.levelValue);
		break;
	default:
		zen('ctrlValue').setValue('');
		zen('ctrlMDX').setValue('');
		break;
	} 

	this.updateState();
	this.changeType(false);

	// reveal
	zen('mainGroup').setProperty('enclosingStyle','display:block;');
}

/// Disable/enable drilldown.
ClientMethod disableDrilldown() [ Language = javascript ]
{
	var textarea = document.getElementById("ctrlDrilldownSpec").childNodes[0];
	textarea.disabled = !textarea.disabled;
	var plusButton = document.getElementById("drillDownGroup").getElementsByClassName("imageLink")[0];
	plusButton.style.display = plusButton.style.display == "none" ? "block" : "none";
	this.getPivotObject().canDrillDown = !textarea.disabled;
}

/// Launch format dialog.
ClientMethod buildExpression() [ Language = javascript ]
{
	// Method added by DTB444
	//var value = zen('ctrlDrilldownSpec').getValue();
	var parms = {
			CUBE:this.subjectArea,
			PIVOT:this.pivotName,
			VALUE:''
			};
	zenLaunchPopupWindow("%DeepSee.UI.Dialog.ExpressionBuilder.zen","ExpressionBuilder",'status,scrollbars,resizable=yes,width=640,height=680',parms);
}

Method %OnAfterCreatePage() As %Status
{
	If (..mode="measures") {
		Quit $$$OK
	}
	// Look at spec and see if we can find dim/hier/level names
	// pull apart [Dim].[Hier].[Level].Members
	Set tDimName = $E($P(..memberSpec,"].",1),2,*)
	Set tHierName = $E($P(..memberSpec,"].",2),2,*)
	Set tLevelName = $E($P(..memberSpec,"].",3),2,*)
	Set tFunction = $P(..memberSpec,"].",4)

	// determine type of spec
	Set tType = "mbr"
	If ($$$UPPER(tDimName)="MEASURES") {
		Set tType = "msr"
	}
	ElseIf (..memberSpec="") {
		Set tType = "special"
	}
	Set ..memberType = tType
	
	// radio options are based on type
	Set tRadio = ..%GetComponentById("radioType")
	If (tType = "msr") {
		// DTB632 - Get the measures defined in the cube and check if current measure is defined is there
		Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(..subjectArea,.tMeasures)
		If $$$ISERR(tSC) Quit tSC
		
		// DTB632 - Check if the current measure is defined in the cube
		Set indexFound = 0
		Set i=$O(tMeasures(""))
		While (i'=""){
			if (%page.memberText=$LG(tMeasures(i),2)) {
				Set indexFound = i
				Quit
				}
			Set i=$O(tMeasures(i))
		}
		
		// DTB632 - If the current measure is not found or the third index of tMeasures is "numeric", it is a calculated measure
		If ((indexFound=0)||($LG(tMeasures(indexFound),3)="numeric")) {
			Set ..isCalculated = 1		
		} 
		Else {
			Set tRadio.displayList = $$$Text("Measure")
			Set tRadio.valueList=""
			Set tCtrlAgg = ..%GetComponentById("ctrlMsrAgg")
			Set tCtrlAgg.value = ..aggFunction
		} 
	}
	ElseIf (tType = "special") {
		Set tRadio.displayList = $$$Text("Value,Space,Advanced")
		Set tRadio.valueList="value,space,mdx" 
	}
	Else {
		Set tRadio.displayList = $$$Text("Members,Value,Space,Advanced")
		Set tRadio.valueList=",value,space,mdx"
	}

	If (..mode="axis") {
		Set tText = ..%GetComponentById("member")
		Set tText.label = $$$Text("Axis")
		Set tText.value = $Case(..memberText,"rows":$$$Text("Rows"),:$$$Text("Columns"))
		Set ..%GetComponentById("radioType").hidden = 1
		Set ..levelType = ""
	}
	Else {
		// 80/20 does not apply to levels
		Set tCB = ..%GetComponentById("ctrlSuppress")
		Set tCB.hidden = 1

		// drilldownSpec does not apply to levels
		Set tGroup = ..%GetComponentById("drillDownGroup")
		Set tGroup.hidden = 1
	}

	// pull apart drilldown spec
	Set tSpec  = $Replace(..drilldownSpec,"^",$C(10))
	Set ..%GetComponentById("ctrlDrilldownSpec").value = tSpec

	// what kind of sort is in play, if any
	Set tSortBy = "msr"
	if (..orderExpression [ ".Properties(") {
		Set tSortBy = "prop"
	}

	// pull apart filter expression
	Set tFilterBy = "msr"
	if (..filterExpression [ ".Properties(") {
		Set tFilterBy = "prop"
	}
	Set tFilterExpr = ""
	Set tFilterOp = ""
	Set tFilterValue = ""

	If (..filterExpression [ "<=") {
		Set tFilterOp = "<="
	}
	ElseIf (..filterExpression [ ">=") {
		Set tFilterOp = ">="
	}
	ElseIf (..filterExpression [ "=") {
		Set tFilterOp = "="
	}
	ElseIf (..filterExpression [ ">") {
		Set tFilterOp = ">"
	}
	ElseIf (..filterExpression [ "<") {
		Set tFilterOp = "<"
	}
	
	If (tFilterOp'="") {
		Set tFilterExpr = $P(..filterExpression,tFilterOp,1)
		Set tFilterValue = $P(..filterExpression,tFilterOp,2)
	}
	Else {
		Set tFilterOp = "="
	}

	Set ..%GetComponentById("ctrlFilterOp").value = tFilterOp
	Set ..%GetComponentById("ctrlFilterValue").value = tFilterValue

	Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(..subjectArea,.tMeasures)
	If $$$ISERR(tSC) Quit tSC

	// list of measures
	Set tCombo = ..%GetComponentById("ctrlOrderExprMsr")
	Set tComboFilter = ..%GetComponentById("ctrlFilterExprMsr")
	Set tValueList = ""
	Set tDisplayList = ""
	Set n = $O(tMeasures(""))
	While (n '= "") {
		// PFS068 - Skip hidden measures
		If ($LG(tMeasures(n),3)'="string")&&('$LG(tMeasures(n),4)) {
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tMeasures(n),2)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "Measures.["_$LG(tMeasures(n),1)_"]"
		}
		Set n = $O(tMeasures(n))
	}

	// check for local calc members (measures)
	If (..pivotName'="") {
		Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..pivotName,.tSC)
		If $$$ISERR(tSC) Quit
		If $IsObject(tPivot) {
			// get local calc members
			For n = 1:1:tPivot.calculatedMembers.Count() {
				Set tCalcMbr = tPivot.calculatedMembers.GetAt(n)
				If (($$$UPPER(tCalcMbr.dimension)="MEASURES")&&(tCalcMbr.memberName'="")) {
					Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ tCalcMbr.memberName
					Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "Measures.["_tCalcMbr.memberName_"]"
				}
			}
		}
	}

	Set tCombo.displayList = tDisplayList
	Set tCombo.valueList = tValueList
	Set tCombo.value = ..orderExpression
	Set tComboFilter.displayList = tDisplayList
	Set tComboFilter.valueList = tValueList
	Set tComboFilter.value = tFilterExpr

	// list of property values
	If ((tDimName '= "")&&(tHierName '= "")&&(tLevelName '= "")) {
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionProperties(..subjectArea,$$$UPPER(tDimName),$$$UPPER(tHierName),$$$UPPER(tLevelName),.tProps)
		If $$$ISERR(tSC) Quit tSC
	}

	Set tCombo = ..%GetComponentById("ctrlOrderExprProp")
	Set tRB = ..%GetComponentById("rbOrderProp")
	Set tComboFilter = ..%GetComponentById("ctrlFilterExprProp")
	Set tRBFilter = ..%GetComponentById("rbFilterProp")

	If ('$D(tProps)) {
		Set tCombo.hidden = 1
		Set tRB.hidden = 1
		Set tRB.value = "msr"
		Set tComboFilter.hidden = 1
		Set tRBFilter.hidden = 1
		Set tRBFilter.value = "msr"
	}
	Else {
		Set tValueList = ""
		Set tDisplayList = ""
		Set n = $O(tProps(""))
		While (n '= "") {
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tProps(n),2)
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ "["_tDimName_"].["_tHierName_"].["_tLevelName_"].CurrentMember.Properties("""_$LG(tProps(n),1)_""")"
			Set n = $O(tProps(n))
		}
		Set tCombo.displayList = tDisplayList
		Set tCombo.valueList = tValueList
		Set tCombo.value = ..orderExpression
		Set tRB.value = tSortBy

		Set tComboFilter.displayList = tDisplayList
		Set tComboFilter.valueList = tValueList
		Set tComboFilter.value = tFilterExpr
		Set tRBFilter.value = tFilterBy
	}

	Quit $$$OK
}

/// Launch format dialog.
ClientMethod editFormatString() [ Language = javascript ]
{
	var value = zen('ctrlFormat').getValue();
	var parms = {
			CUBE:this.subjectArea,
			VALUE:value
			};
	zenLaunchPopupWindow("%DeepSee.UI.Dialog.FormatString.zen","FormatString",'status,scrollbars,resizable=yes,width=640,height=680',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'FormatString':
		zen('ctrlFormat').setValue(value);
		break;
	case 'ExpressionBuilder':
		// DTB444 - Add the expression produced by the ExpressionBuilder dialog
		var text = zen('ctrlDrilldownSpec').getValue();
		if (text.length) {
			text += '\n' + value;
		}
		else {
			text = value;
		}
		zen('ctrlDrilldownSpec').setValue(text);
		break;
	}
}

/// This client event is fired when user selects a type radio button choice.
ClientMethod changeType(clear) [ Language = javascript ]
{
	zen('groupCaption').setHidden(false);

	var type = zen('radioType').getValue();
	switch(type) {
	case 'value':
		zen('groupMembers').setHidden(true);
		zen('groupValue').setHidden(false);
		zen('groupSpace').setHidden(true);
		zen('groupMDX').setHidden(true);
		zen('groupCaption').setHidden(false);
		zen('groupMeasure').setHidden(true);
		break;
	case 'mdx':
		zen('groupMembers').setHidden(true);
		zen('groupValue').setHidden(true);
		zen('groupSpace').setHidden(true);
		zen('groupMDX').setHidden(false);
		zen('groupCaption').setHidden(false);
		zen('groupMeasure').setHidden(true);
		break;
	case 'space':
		zen('groupMembers').setHidden(true);
		zen('groupValue').setHidden(true);
		zen('groupSpace').setHidden(false);
		zen('groupMDX').setHidden(true);
		zen('groupCaption').setHidden(true);
		zen('groupMeasure').setHidden(true);
		break;
	default:
		zen('groupValue').setHidden(true);
		zen('groupSpace').setHidden(true);
		zen('groupMDX').setHidden(true);
		zen('groupCaption').setHidden(false);

		if (this.memberType=='msr') {
			zen('groupMembers').setHidden(true);
			if (0==this.isCalculated) {
				zen('groupMeasure').setHidden(false);		// DTB632
			}
		}
		else {
			zen('groupMembers').setHidden(false);
			zen('groupMeasure').setHidden(true);
		}
		break;
	}
}

/// Change in style control.
ClientMethod applyChange(deltaId, target) [ Language = javascript ]
{
	target = 'undefined' == typeof target ? 'cell' : target;
	var who = zen(deltaId);
	var value = who.getValue();

	if (target=='header') {
		this.levelHeaderStyle = value;
	}
	else {
		this.levelStyle = value;
	}
}

/// Make style controls match current style.
ClientMethod updateStyleControls() [ Language = javascript ]
{
	zen('styleCell').setValue(this.levelStyle);
	zen('styleHeader').setValue(this.levelHeaderStyle);
}

/// Reset styles.
ClientMethod reset(which) [ Language = javascript ]
{
	if (which == 'header') {
		this.levelHeaderStyle = '';
	}
	else {
		this.levelStyle = '';
	}
	this.updateStyleControls();
}

}
