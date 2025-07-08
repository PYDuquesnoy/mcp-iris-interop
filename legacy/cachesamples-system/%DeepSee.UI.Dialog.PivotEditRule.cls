/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog adds (or edits) a new formatting rule definition to a DeepSee pivot.
Class %DeepSee.UI.Dialog.PivotEditRule Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Index of rule within parent dialog list or "" for new.
Property ruleNumber As %ZEN.Datatype.string(ZENURL = "NUMBER");

/// Name of icon in effect.
/// Names starting with "@" are user-defined names from the user icon list.
Property cellIcon As %ZEN.Datatype.string(ZENURL = "ICON");

/// Url of current icon.
Property sampleIcon As %ZEN.Datatype.string;

/// Range of cells for which this rule applies.
Property range As %ZEN.Datatype.string(ZENURL = "RANGE");

/// Condition operator.
Property operator As %ZEN.Datatype.string(ZENURL = "OPERATOR");

/// Value (or values) to test.
/// For IN and BETWEEN this is a comma-delimited list.
Property value As %ZEN.Datatype.csv(ZENURL = "VALUE");

/// CSS style to apply to cells that match this condition.
Property style As %ZEN.Datatype.style(ZENURL = "STYLE");

/// If defined, replace value with this text.
Property text As %ZEN.Datatype.string(ZENURL = "TEXT");

/// Icon.
Property icon As %ZEN.Datatype.uri(ZENURL = "ICON");

/// Icon count.
Property iconCount As %ZEN.Datatype.integer(ZENURL = "ICONCOUNT");

XData Style
{
<style type="text/css">

#cellIconBox {
	width: 650px;
	height: 60px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: auto;
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

#sample {
	border: 1px solid #808080;
	background: white;
	font-family: arial;
	font-size: 20px;
	width: 250px;
	height: 40px;
	white-space:nowrap;
	overflow: hidden;
	box-shadow: 2px 2px 2px #808080;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">

<hgroup cellVAlign="top" label="Apply formatting to all cells where the value is:" labelPosition="left">
<select id="controlOperator" valueList="=,&lt;&gt;,&gt;,&gt;=,&lt;,&lt;=,IN,BETWEEN,IS NULL" onchange="zenPage.updateOperator();"/>
<spacer width="10"/>
<text id="controlValue"/>
<spacer width="10"/>
<text id="controlValue2" label="AND" hidden="true"/>
</hgroup>

<hgroup cellVAlign="top" label="Optional. Apply formatting to cell in:" labelPosition="left">
<text id="controlRow" label="Row #" size="5"/>
<spacer width="10"/>
<text id="controlColumn" label="Column #" size="5"/>
<spacer width="10"/>
<button caption="Clear range" onclick="zenPage.clearRange();"/>
</hgroup>

<spacer height="10"/>
<html id="sample" label="Sample">1000</html>

<spacer height="5"/>

<hgroup cellVAlign="top">
<deepsee:styleEdit label="Style" id="controlStyle" onchange="zenPage.updateSample();"/>
</hgroup>
<spacer height="5"/>
<text id="controlText" label="Replace cell contents with" hint="Optional replacement text" onchange="zenPage.updateSample();"/>

<html label="Display icon within cell" id="cellIconBox" OnDrawContent="DrawCellIcons" />
<select label="Number of icons to display" id="controlIconCount" valueList="0,1,2,3,4,5,6,7,8,9,10" showEmpty="false" value="1" onchange="zenPage.updateSample();"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Conditional Formatting Rule Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add a conditional formatting rule.")
}

/// Draw contents of cell icon box.
Method DrawCellIcons(pSeed As %String) As %Status
{
	Set tInfo($I(n)) = $LB("",$$$Text("No Icon"),"portal/view_box.png")
	Set tInfo($I(n)) = $LB("deepsee/star_24.png",$$$Text("Star"),"deepsee/star_24.png")
	Set tInfo($I(n)) = $LB("deepsee/green_dot_24.gif",$$$Text("Green Dot"),"deepsee/green_dot_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/yellow_dot_24.gif",$$$Text("Yellow Dot"),"deepsee/yellow_dot_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/red_dot_24.gif",$$$Text("Red Dot"),"deepsee/red_dot_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/ok_24.png",$$$Text("OK"),"deepsee/ok_24.png")
	Set tInfo($I(n)) = $LB("deepsee/lamp_24.png",$$$Text("Lamp"),"deepsee/lamp_24.png")
	Set tInfo($I(n)) = $LB("deepsee/user_24.png",$$$Text("Person"),"deepsee/user_24.png")
	Set tInfo($I(n)) = $LB("deepsee/calendar_48.gif",$$$Text("Calendar"),"deepsee/calendar_48.gif")
	Set tInfo($I(n)) = $LB("deepsee/home_24.png",$$$Text("Home"),"deepsee/home_24.png")
	Set tInfo($I(n)) = $LB("deepsee/world_24.png",$$$Text("World"),"deepsee/world_24.png")
	Set tInfo($I(n)) = $LB("deepsee/flag_square_24.gif",$$$Text("Flag"),"deepsee/flag_square_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/product_24.gif",$$$Text("Product"),"deepsee/product_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/trophy_24.gif",$$$Text("Trophy"),"deepsee/trophy_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/doctor_24.gif",$$$Text("Doctor"),"deepsee/doctor_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/hospital_bed_24.gif",$$$Text("Bed"),"deepsee/hospital_bed_24.gif")
	Set tInfo($I(n)) = $LB("deepsee/patient_24.gif",$$$Text("Patient"),"deepsee/patient_24.gif")

	// tack on any user-defined icons
	Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserIconList(.tUserList)
	If $$$ISERR(tSC) Quit tSC
	Set k = $O(tUserList(""))
	While (k'="") {
		Set tName = $LG(tUserList(k),1)
		Set tPath = $LG(tUserList(k),2)
		Set tInfo($I(n)) = $LB("@"_tName,tName,tPath)
		Set k = $O(tUserList(k))
	}

	&html<<table border="0"><tr valign="middle">>
	Set tItem = $O(tInfo(""))
	While (tItem'="") {
		Set tName = $LG(tInfo(tItem),1)
		Set tTitle = $LG(tInfo(tItem),2)
		Set tImage = $LG(tInfo(tItem),3)
		&html<<td><a id="icon_#(tName)#" class="#($S(tName=..cellIcon:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectIcon('#($ZCVT(tName,"O","JS"))#','#($ZCVT(tImage,"O","JS"))#');return false;"><img height=24" src="#(tImage)#" title="#($ZCVT(tTitle,"O","HTML"))#"/></a></td>>
		Set tItem = $O(tInfo(tItem))
	}
	&html<</tr></table>>
	Quit $$$OK
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// convert set of values to JSON
	var def = {};

	def.operator = zen('controlOperator').getValue();
	if ('BETWEEN' == def.operator) {
		def.value = zen('controlValue').getValue() + "," + zen('controlValue2').getValue();
	}
	else if ('IS NULL' == def.operator) {
		def.value = '';
	}
	else {
		def.value = zen('controlValue').getValue();
	}

	def.text = zen('controlText').getValue();
	def.iconCount = zen('controlIconCount').getValue();
	def.style = zen('controlStyle').getValue();
	def.icon = this.cellIcon;
	var row = zen('controlRow').getValue();
	var col = zen('controlColumn').getValue();
	if ('' !== col) {
		def.range = row + ',' + col;
	}
	else if ('' !== row) {
		def.range = row;
	}
	else {
		def.range = '';
	}
	return JSON.stringify(def);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('controlOperator').setValue(this.operator);
		zen('controlValue').setValue(this.value);
		zen('controlText').setValue(this.text);
		zen('controlIconCount').setValue(this.iconCount);

		if (this.operator=='BETWEEN') {
			zen('controlValue').setHidden(false);
			zen('controlValue2').setHidden(false);
			var v1 = this.value.toString().split(',')[0];
			var v2 = this.value.toString().split(',')[1];
			zen('controlValue').setValue(v1?v1:'');
			zen('controlValue2').setValue(v2?v2:'');
		}
		else if (this.operator=='IS NULL') {
			zen('controlValue').setHidden(true);
			zen('controlValue2').setHidden(true);
			zen('controlValue').setValue('');
			zen('controlValue2').setValue('');
		}
		else {
			zen('controlValue').setHidden(false);
			zen('controlValue2').setHidden(true);
		}
		zen('controlStyle').setValue(this.style);

		var range = this.range;
		if ('' !== range) {
			var row = range.toString().split(',')[0];
			var col = range.toString().split(',')[1];
			var endrow = range.toString().split(',')[2];
			var endcol = range.toString().split(',')[3];

			// crude check for col/row selection
			if (row!=endrow && col == endcol) {
				row = '';
			}
			else if (row==endrow && col != endcol) {
				col = '';
			}

			zen('controlRow').setValue(row ? row : '');
			zen('controlColumn').setValue(col ? col : '');
		}
		this.updateSample();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Update the sample.
ClientMethod updateSample() [ Language = javascript ]
{
	var sample = zen('sample');
	var text = zen('controlText').getValue();
	var content = ('' === text) ? 1000 : text;

	if (''!==this.cellIcon) {
		content = '';
		var icount = parseInt(zen('controlIconCount').getValue());
		for (var n = 0; n < icount; n++) {
			content += '<image alt="*" style="padding-right:2px;" height="20px" src="'+this.sampleIcon+'"/>';
		}
	}
	sample.setContent(content);
	sample.getEnclosingDiv().style.cssText = zen('controlStyle').getValue();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..sampleIcon = ..cellIcon
		If ($E(..sampleIcon)="@") {
			Set ..sampleIcon = ##class(%DeepSee.UserPortal.Utils).%GetUserIcon($E(..sampleIcon,2,$L(..sampleIcon)))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Click on a new cell icon.
ClientMethod selectIcon(type, href) [ Language = javascript ]
{
	if (this.cellIcon != type) {
		var a = self.document.getElementById('icon_' + this.cellIcon);
		if (a) {
			a.className = 'Icon';
		}

		this.cellIcon = type;
		this.sampleIcon = href;

		var a = self.document.getElementById('icon_' + this.cellIcon);
		if (a) {
			a.className = 'IconSelected';
		}
		this.updateSample();
	}
}

/// Click on clear range button.
ClientMethod clearRange() [ Language = javascript ]
{
	zen('controlRow').setValue('');
	zen('controlColumn').setValue('');
}

/// Click on a new operator value.
ClientMethod updateOperator(type) [ Language = javascript ]
{
	var value = zen('controlValue').getValue();
	value = ('' == value) ? value : value.toString().split(',')[0];
	var operator = zen('controlOperator').getValue();
	if (operator=='BETWEEN') {
		zen('controlValue').setHidden(false);
		zen('controlValue2').setHidden(false);
		zen('controlValue2').setValue('');
	}
	else if (operator=='IS NULL') {
		value = '';
		zen('controlValue').setHidden(true);
		zen('controlValue2').setHidden(true);
	}
	else {
		zen('controlValue').setHidden(false);
		zen('controlValue2').setHidden(true);
	}
	zen('controlValue').setValue(value);
}

}
