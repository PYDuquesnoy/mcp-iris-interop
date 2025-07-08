/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user specificy conditional formatting for a pivot table.
Class %DeepSee.UI.Dialog.CellFormatOptions Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 1;

/// Name of color scale in effect.
Property colorScale As %ZEN.Datatype.string(ZENURL = "COLORSCALE");

/// Default Range for new rules.
Property defRange As %ZEN.Datatype.string;

/// List of formatting rules for the table.
Property formatRules As list Of %DeepSee.Component.pivotCondition(XMLNAME = "formatRule", XMLPROJECTION = "ELEMENT");

XData Style
{
<style type="text/css">

#colorIconBox {
	width: 400px;
	height: 52px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: hidden;
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

#ruleList {
	width: 500px;
	height: 200px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: auto;
}

table.RuleListTable {
	width: 100%;
	background: white;
	color: #404040;
}

table.RuleListTable td,table.RuleListTable th {
	vertical-align: middle;
	padding: 1px;
	border-bottom: 1px solid darkgray;
	font-size: 12px;
	padding-left: 4px;
	padding-right: 4px;
}

table.RuleListTable th {
	background: #F0F0F0;
	font-size: 11px;
	text-align: left;
	font-weight: bold;
}

.expandoNode a {
	color: black;
	font-weight: bold;
	font-size: 12px;
}

table.customColors {
	font-size: 8px;
}

table.customColors td input {
	font-size: 10px;
	width: 30px;
	color: #404040;
	border: 1px solid #808080;
}

table td.preview {
	text-align: center;
	background: white;
	color: #808080;
	font-size: 10px;
	width: 30px;
	border: 1px solid #808080;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">
<button id="btnClear" controlClass="commandButton" caption="Clear rules" title="Remove all formatting rules" onclick="zenPage.clearRules();" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>
<hgroup cellVAlign="top" label="Color all cells proportionally according to value">
<html id="colorIconBox" OnDrawContent="DrawColorScale" />
<spacer width="5"/>
<hgroup id="customColors" cellVAlign="middle" label="My Colors">
<deepsee:styleEdit id="customStart" title="Start" mode="color" caption="Start Color" onchange="zenPage.ccChange(true);"/>
<image src="deepsee/ds2_arrow_east_44.png" controlStyle="height:16px;padding:2px;padding-top:6px;"/>
<deepsee:styleEdit id="customEnd" title="End" mode="color" caption="End Color" onchange="zenPage.ccChange(true);"/>
</hgroup>
</hgroup>

<expando caption="Additional formatting rules" animate="true">
<hgroup cellVAlign="top" hint="Conditional formatting rules to apply to the table">
<html id="ruleList" OnDrawContent="DrawRuleList"/>
<image src="deepsee/ds2_plus_16.png" controlStyle="padding:2px;" title="Add a rule" onclick="zenPage.addRule();"/>
</hgroup>
</expando>

</pane>
}

/// Draw contents of color scale icon box.
Method DrawColorScale(pSeed As %String) As %Status
{
	Set tInfo($I(n)) = $LB("",$$$Text("No color scale"),"portal/view_box.png")
	Set tInfo($I(n)) = $LB("red-to-black",$$$Text("Red to black"),"deepsee/cs_red_to_black.png")
	Set tInfo($I(n)) = $LB("green-to-black",$$$Text("Green to black"),"deepsee/cs_green_to_black.png")
	Set tInfo($I(n)) = $LB("blue-to-black",$$$Text("Blue to black"),"deepsee/cs_blue_to_black.png")
	Set tInfo($I(n)) = $LB("purple-to-black",$$$Text("Purple to black"),"deepsee/cs_purple_to_black.png")
	Set tInfo($I(n)) = $LB("salmon-to-black",$$$Text("Salmon to black"),"deepsee/cs_salmon_to_black.png")
	Set tInfo($I(n)) = $LB("gray-to-black",$$$Text("Gray to black"),"deepsee/cs_gray_to_black.png")

	&html<<table border="0"><tr style="vertical-align:middle;">>
	Set tItem = $O(tInfo(""))
	While (tItem'="") {
		Set tName = $LG(tInfo(tItem),1)
		Set tTitle = $LG(tInfo(tItem),2)
		Set tImage = $LG(tInfo(tItem),3)
		&html<<td><a id="cscale_#(tName)#" class="#($S(tName=..colorScale:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectColorScale('#(tName)#');return false;"><img src="#(tImage)#" title="#(tTitle)#"/></a></td>>
		Set tItem = $O(tInfo(tItem))
	}

	// custom colors
	Set tName = "custom"
	Set tHlp = $$$Text("Use my color range")
	&html<<td><a id="cscale_custom" title="#(tHlp)#" class="#($S(..colorScale["custom:":"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectColorScale('#(tName)#');return false;" style="height:28px;width:28px;background:rgb(200,200,200);">&nbsp;</a></td>>

	&html<</tr></table>>
	Quit $$$OK
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	Quit 1
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Conditional Formatting")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Define conditional formatting for cells")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		var main = this.getOpener ? this.getOpener() : window.opener;
		if (!main) return;
		var pivot = main.zenPage.getPivot();
		if (pivot && pivot.formatRules) {
			for (var n = 0; n < pivot.formatRules.length; n++) {
				var rule = pivot.formatRules[n];
				var def = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotCondition');
				def.operator = rule.operator;
				def.range = rule.range;
				def.value = rule.value;
				def.style = rule.style;
				def.text = rule.text;
				def.icon = rule.icon;
				def.iconCount = rule.iconCount;
				this.formatRules[this.formatRules.length] = def;
			}
			zen('ruleList').refreshContents();
			this.defRange = pivot.selectedRange;

			var colorStart = 'rgb(0,0,0)';
			var colorEnd = 'rgb(255,255,255)';
			if (pivot.colorScale.toString().indexOf('custom:')>=0) {
				var t = pivot.colorScale.split(':');
				var t1 = t[1].toString().split(',');
				var t2 = t[2].toString().split(',');
				colorStart = 'rgb('+(t1[0]?t1[0]:0)+','+(t1[1]?t1[1]:0)+','+(t1[2]?t1[2]:0)+')';
				colorEnd = 'rgb('+(t2[0]?t2[0]:255)+','+(t2[1]?t2[1]:255)+','+(t2[2]?t2[2]:255)+')';
			}
			zen('customStart').setValue(colorStart);
			zen('customEnd').setValue(colorEnd);

			// set up custom colors
			this.ccChange(false);
		}

		try {
			zen('btnClear').focus();
		}
		catch(ex) {
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener ? this.getOpener() : window.opener;
		var pivot = main.zenPage.getPivot();
		if (pivot) {
			if (pivot && pivot.formatRules) {
				pivot.formatRules.length = 0;
				for (var n = 0; n < this.formatRules.length; n++) {
					var rule = this.formatRules[n];
					var def = main.zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotCondition');
					def.operator = rule.operator;
					def.range = rule.range;
					def.value = rule.value;
					def.style = rule.style;
					def.text = rule.text;
					def.icon = rule.icon;
					def.iconCount = rule.iconCount;
					pivot.formatRules[pivot.formatRules.length] = def;
				}
			}

			pivot.selectedRange = '';
			pivot.colorScale = this.colorScale;
			pivot.executeQuery();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Click on a new color scale.
ClientMethod selectColorScale(type) [ Language = javascript ]
{
	if (this.colorScale != type) {
		var oldType = this.colorScale.toString().split(':')[0];
		var a = self.document.getElementById('cscale_' + this.colorScale);
		if (a) {
			a.className = 'Icon';
		}

		this.colorScale = type;
		if (type=='custom') {
			this.ccChange(true);
		}

		var a = self.document.getElementById('cscale_' + type);
		if (a) {
			a.className = 'IconSelected';
		}
	}
}

/// Clear the rules
ClientMethod clearRules() [ Language = javascript ]
{
	this.selectColorScale('');
	this.formatRules.length = 0;
	zen('ruleList').refreshContents();
}

/// Draw contents of rule list box.
Method DrawRuleList(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set hlpEdit = $$$Text("Edit this rule")
		Set hlpRemove = $$$Text("Remove this rule")
		Set hlpMoveUp = $$$Text("Move this item up")
		Set hlpMoveDown = $$$Text("Move this item down")

		&html<<table class="RuleListTable" border="0" cellspacing="0">>
		&html<<tr>>
			&html<<th>#($$$Text("Condition","%DeepSee"))#</td>>
			&html<<th>#($$$Text("Style","%DeepSee"))#</td>>
			&html<<th>#($$$Text("Row","%DeepSee"))#</td>>
			&html<<th>#($$$Text("Col","%DeepSee"))#</td>>
			&html<<th>&nbsp;</td>>
			&html<<th>&nbsp;</td>>
		&html<</tr>>
		For n = 1:1:..formatRules.Count() {
			&html<<tr ondblclick="zenPage.editRule(#(n)#);">>
			Set tRule = ..formatRules.GetAt(n)

			Set tCondition = $$$Text("Cell","%DeepSee")
			If (tRule.operator="BETWEEN") {
				Set tCondition = tCondition _ " " _ $$$Text("BETWEEN","%DeepSee") _ " "_$$$quote($ZCVT($P(tRule.value,",",1),"O","HTML"))_ " " _ $$$Text("AND","%DeepSee") _ " "_$$$quote($ZCVT($P(tRule.value,",",2),"O","HTML"))
			}
			ElseIf (tRule.operator="IS NULL") {
				Set tCondition = tCondition _ " " _ $$$Text("Is Null","%DeepSee")
			}
			ElseIf (tRule.operator="IN") {
				Set tCondition = tCondition _ " " _ $$$Text("IN","%DeepSee") _ " "_$$$quote($ZCVT(tRule.value,"O","HTML"))
			}
			ElseIf (tRule.operator="") {
				Set tCondition = $$$Text("Always","%DeepSee")
			}
			Else {
				Set tCondition = tCondition _ " " _ tRule.operator _ " "_$$$quote($ZCVT($P(tRule.value,",",1),"O","HTML"))
			}
			Set tStyle = tRule.style
			Set tStyleText = $ZCVT(tRule.text,"O","HTML")
			Set:tStyleText="" tStyleText = $$$Text("Sample","%DeepSee")

			Set tRow = $P(tRule.range,",",1)
			Set tCol = $P(tRule.range,",",2)

			If (tRule.icon'="") {
				Set tStyleText = ""
				For ic = 1:1:tRule.iconCount {
					Set tIcon = tRule.icon
					If ($E(tIcon)="@") {
						// user-icon
						Set tIcon = ##class(%DeepSee.UserPortal.Utils).%GetUserIcon($E(tIcon,2,$L(tIcon)))
					}
					Set tStyleText = tStyleText _ "<image alt=""*"" style=""padding-right:2px;"" height=""22"" src="""_tIcon_"""/>"
				}
				Set tStyle = tStyle_"text-align:center;"
			}

			&html<<td nowrap="1">#(tCondition)#&nbsp;</td>>
			&html<<td nowrap="1" style="#(tStyle)#">#(tStyleText)#&nbsp;</td>>
			&html<<td nowrap="1">#(tRow)#&nbsp;</td>>
			&html<<td nowrap="1">#(tCol)#&nbsp;</td>>
			&html<<td nowrap="1">&nbsp;
			<image title="#(hlpEdit)#" src="deepsee/notepad_16.png" onclick="zenPage.editRule(#(n)#);"/>
			<image title="#(hlpRemove)#" src="deepsee/close_a_16.gif" onclick="zenPage.removeRule(#(n)#);"/>
			<image title="#(hlpMoveUp)#" src="deepsee/up_16.png" onclick="zenPage.moveRuleUp(#(n)#);"/>
			<image title="#(hlpMoveDown)#" src="deepsee/down_16.png" onclick="zenPage.moveRuleDown(#(n)#);"/>
			&nbsp;</td>>
			&html<<td width="50%">&nbsp;</td>>
			&html<</tr>>
		}
		&html<</table>>
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add a rule definition.
ClientMethod addRule() [ Language = javascript ]
{
	this._editRuleNo = '';
	var parms = {
		NUMBER:'',
		RANGE:this.defRange
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotEditRule.zen','AddRule','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Edit a rule definition.
ClientMethod editRule(n) [ Language = javascript ]
{
	var rule = this.formatRules[n-1];
	if (!rule) {
		this.addRule();
	}
	else {
		this._editRuleNo = n-1;
		var parms = {
			NUMBER:n,
			ICON:rule.icon,
			RANGE:rule.range,
			OPERATOR:rule.operator,
			VALUE:rule.value,
			TEXT:rule.text,
			ICONCOUNT:rule.iconCount,
			STYLE:rule.style
		};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotEditRule.zen','AddRule','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

/// Remove a rule definition.
ClientMethod removeRule(n) [ Language = javascript ]
{
	this.formatRules.splice((n-1),1);
	zen('ruleList').refreshContents();
}

/// Move a rule definition up.
ClientMethod moveRuleUp(n) [ Language = javascript ]
{
	n--;
	if (n > 0) {
		var t = this.formatRules[n-1];
		this.formatRules[n-1] = this.formatRules[n];
		this.formatRules[n] = t;
		zen('ruleList').refreshContents();
	}
}

/// Move a rule definition up.
ClientMethod moveRuleDown(n) [ Language = javascript ]
{
	n--;
	if (n < (this.formatRules.length - 1)) {
		var t = this.formatRules[n+1];
		this.formatRules[n+1] = this.formatRules[n];
		this.formatRules[n] = t;
		zen('ruleList').refreshContents();
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'AddRule':
		// value is JSON string
		if (value) {
			var def = JSON.parse(value);
			if (!isNaN(parseInt(this._editRuleNo,10))) {
				var rule = this.formatRules[parseInt(this._editRuleNo,10)];
			}
			else {
				var rule = this.createComponentNS('http://www.intersystems.com/deepsee','pivotCondition');
				this.formatRules.push(rule);
			}
			for (var p in def) {
				rule[p] = def[p];
			}
		}
		zen('ruleList').refreshContents();
		break;
	}
}

/// Change to custom color
ClientMethod ccChange(apply) [ Language = javascript ]
{
	// auto select custom
	if (apply) {
		this.selectColorScale('custom');
	}
	var startColor = zen('customStart').getValue();
	var endColor = zen('customEnd').getValue();

	var r1=255,g1=255,b1=255;
	if (startColor.toString().substr(0,4)=='rgb(') {
		var t = startColor.substr(4,startColor.length).split(',');
		r1 = parseInt(t[0],10);
		g1 = parseInt(t[1],10);
		b1 = parseInt(t[2],10);
	}
	else if (startColor.toString().substr(0,1)=='#') {
		// ie may give us #rrggbb;
		r2 = parseInt(startColor.substr(1,2),16);
		g2 = parseInt(startColor.substr(3,2),16);
		b2 = parseInt(startColor.substr(5,2),16);
	}

	var r2=255,g2=255,b2=255;
	if (endColor.toString().substr(0,4)=='rgb(') {
		var t = endColor.substr(4,endColor.length).split(',');
		r2 = parseInt(t[0],10);
		g2 = parseInt(t[1],10);
		b2 = parseInt(t[2],10);
	}
	else if (endColor.toString().substr(0,1)=='#') {
		// ie may give us #rrggbb;
		r2 = parseInt(endColor.substr(1,2),16);
		g2 = parseInt(endColor.substr(3,2),16);
		b2 = parseInt(endColor.substr(5,2),16);
	}

	// update custom div
	var el = self.document.getElementById('cscale_custom');
	if (el) {
		var who = navigator.userAgent;
		var isWebKit = who.indexOf("WebKit")>=0;
		if (isWebKit) {
			el.style.background = '-webkit-linear-gradient(top, '+startColor+', '+endColor+')';
		}
		else if (!zenIsIE) {
			el.style.background = '-moz-linear-gradient(top, '+startColor+', '+endColor+')';
		}
		else if (zenIsIE) {
			if (who.indexOf("MSIE 8")>=0 || who.indexOf("MSIE 9")>=0) {
				el.style.background = endColor;
			}
			else {
				el.style.background = '-ms-linear-gradient(top, '+startColor+', '+endColor+')';
			}
		}
	}
	if (apply) {
		this.colorScale = 'custom:'+(r1?r1:0)+','+(g1?g1:0)+','+(b1?b1:0)+':'+(r2?r2:0)+','+(g2?g2:0)+','+(b2?b2:0);
	}
}

}
