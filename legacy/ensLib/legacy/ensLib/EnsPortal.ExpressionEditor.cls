/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.ExpressionEditor Extends (EnsPortal.Dialog.standardDialog, EnsPortal.Util.RuleSVGCommon) [ System = 4 ]
{

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

Parameter APPLYBUTTON = 0;

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter RESOURCE = "%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ,%Ens_Code:READ";

/// User needs WRITE permissions on one of the following resources to make changes on this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter EDITRESOURCE = "%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE,%Ens_Code:WRITE";

/// the expression string to be parsed
Property EXP As %String(MAXLEN = "", ZENURL = "EXP");

/// the editing mode, either logical or expression
Property MODE As %String(MAXLEN = "", ZENURL = "MODE") [ InitialExpression = "expression" ];

/// when the editing mode is logical, this sets the default checkbox state
Property VIEWEXPANDED As %String(MAXLEN = "", ZENURL = "VIEWEXPANDED") [ InitialExpression = 0 ];

/// Flag to indicate whether the main rule is open in ReadOnly mode, which should also apply here.
Property readOnly As %ZEN.Datatype.boolean(ZENURL = "READONLY") [ InitialExpression = 0 ];

/// spacing between boxes
Property SPACING As %Integer [ InitialExpression = 15 ];

/// height of the text box
Property BOXHEIGHT As %Integer [ InitialExpression = 22 ];

/// distance of the vertical offset for the text y-attribute
Property TEXTVOFFSET As %Integer [ InitialExpression = 16 ];

/// length of the horizontal connecting lines
Property HLINELENGTH As %Integer [ InitialExpression = 20 ];

/// distance of the horizontal indentation
Property HINDENT As %Integer [ InitialExpression = 30 ];

/// size of the margin of the text inside the text box
Property TEXTMARGIN As %Integer [ InitialExpression = 10 ];

/// radius of the rounded corners
Property RADIUS As %Integer [ InitialExpression = 6 ];

/// This Style block contains page-specific CSS style definitions.
XData SVGStyle
{
<style type="text/css">

.rectOPERATOR { fill:rgb(56,113,139); stroke:black; }
.textOPERATOR { fill:white; stroke:none; font-family:arial; font-size:11pt; }

.rectVALUE  { fill:rgb(250,236,226); stroke:rgb(150,150,150); }
.textVALUE  { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectFocused { fill:#FFEEAA; stroke:rgb(53,107,141); stroke-width:2; }
.textFocused { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectBase { fill:#BBBBBB; stroke:#BBBBBB; }
.textBase { fill:white; stroke:none; font-family:arial; font-size:9pt; }

</style>
}

XData Style
{
<style type="text/css">
.svgFrame { border: none; }
.imageLink { cursor:default; }
.csActiveMenuItem { background:#EEEEEE; }
body { background:white; }

.descriptionBox {
	background: #FFEEAA;
	webkit-border-radius: 6px;
	moz-border-radius: 6px;
	border-radius: 6px;
	padding: 5px;
	border-style: solid;
	border-width:2px;
	border-color:rgb(53,107,141);
}
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" width="100%">

<jsonProvider id="model" OnGetTargetObject="GetContentObject" OnSubmitContent="PutContentObject"/>
<jsonProvider id="functionList" OnRenderJSON="GetFunctions" />

<group layout="none">
<contextMenu id="menuOperator"/>
<contextMenu id="menuFunction"/>
</group>

<vgroup layout="none" id="bar">
<hgroup containerStyle="background:#C0D9F8;" width="100%">
<spacer width="20px" containerStyle="background:#C0D9F8;" />
<!-- <label id="labelEXP" containerStyle="background:#C0D9F8;" controlStyle="width:100%; white-space: nowrap;"></label> -->
<label id="labelEXP" containerStyle="background:#C0D9F8;" controlStyle="width:100%;"></label>
</hgroup>
<spacer height="4px"/>
<hgroup>
<image id="imgBlank"                             width="11px" height="27px" src="rule/blank.png"
onclick="zenPage.debugClicked()"
/>
<image id="imgUp"        title="move the node up" width="27px" height="27px" src="rule/up_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgDown"      title="move the node down" width="27px" height="27px" src="rule/down_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgLeft"      title="merge with the parent node" width="27px" height="27px" src="rule/left_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgOperator" title="make the focused node an operand of an operator" width="27px" height="27px" src="rule/operator_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgFunction"  title="make the focused node an argument of a function" width="27px" height="27px" src="rule/function_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgAdd"       title="add a sibling node" width="27px" height="27px" src="rule/add_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgDelete"    title="delete the node" width="27px" height="27px" src="rule/delete_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>

<spacer width="8px"/>
<group layout="none"  width="100%;">
<hgroup id="emptyBar" width="100%; font-family:arial; font-size:11pt;">
<text id="emptyEditor" height="22px" disabled="true" controlStyle="width:99%;"/>
</hgroup>
<hgroup id="logicalBar" hidden="true">
<select height="22px" id="logicalEditor" onchange="zenPage.logicalEditorChanged();" valueList="AND,OR" showEmpty="false"/>
</hgroup>
<hgroup id="xyzBar" width="100%; font-family:arial; font-size:11pt;" hidden="true">
<html id="htmlPanel">
<div style="position:relative;top:0px;left:0px;overflow:visible;">
<div id="xyzSelectorParent" style="position:relative; top:0px; left:0px; width:100%;">
<select id="xyzSelector" size="5" style="position:absolute; display:none; top:26px; left:0px; width:100%;" onchange="zenPage.xyzSelectorChanged();" onfocus="zenPage.xyzSelectorFocused();" ondblclick="zenPage.xyzSelectorDblClicked();"/>
</div>
<input id="xyzGrayText" 
type="text" style="position:absolute;top:0px;left:0px; width:100%;border:1px solid #7F9DB9;color:#C0C0C0;" readOnly="true"
onfocus="zenPage.xyzGrayTextGotFocus();">
</input>
<input id="xyzEditor" onkeydown="zenPage.xyzEditorKeyPressed(event);" onblur="zenPage.xyzEditorOnBlur(event);"
type="text" style="position:relative;top:0px;left:0px; width:100%;border:1px solid #7F9DB9;background:transparent;">
</input>
</div>
</html>
<spacer width="10px"/>
<button id="xyzOK" width="60px" caption="OK" controlStyle="width:60px;" onclick="zenPage.xyzOKClicked()"/>
</hgroup>
<hgroup id="operatorBar" hidden="true">
<html>
<table>
<tr>
<td>
<select id="comboType" height="22px" style="width:100px;" onchange="zenPage.comboTypeChanged();">
<option value="OPERATOR">operator</option>
<option value="FUNCTION">function</option>
</select>
</td>
<td width="4px">
</td>
<td>
<select id="comboOperator" height="22px" style="width:250px;" onchange="zenPage.comboOperatorChanged();"/>
</td>
</tr>
</table>
</html>
</hgroup>
</group>

<html id="htmlViewFull" enclosingStyle="display:none;">
<nobr><image width="8px" height="1px" src="rule/blank.png"/>view expanded<input type="checkbox" id="checkViewExpanded" onchange="zenPage.checkViewExpandedChanged();"/></nobr>
</html>

</hgroup>
<spacer height="5px"/>
<hgroup>
<hgroup id="funcDesc" enclosingClass="descriptionBox" width="100%" hidden="true">
<html id="htmlDesc" containerStyle="font-size:8pt;"></html>
</hgroup>
<spacer width="2px"/>
</hgroup>

<group enclosingStyle="display:block; height:3px; width:100%; background:white;" layout="none"/>
</vgroup>

<group id="svgScrollingArea" layout="none" onclick="zenPage.backgroundClicked();">
<svgFrame id="svg" height="1" width="1" layout="none" onmouseWheel="zenPage.doScroll(delta);">
<ownerDraw height="0" onrender="zenPage.doOwnerDraw();" />
</svgFrame>
</group>

</pane>
}

ClientMethod doOwnerDraw() [ Language = javascript ]
{
	var json = this.getComponentById("model");
	var obj = json.getContentObject();
	this.moJsonRootObject = obj;
	if ( this.moJsonRootObject == null ) return;
	this.suggestedRefocusIndex = 0;
	this.suggestedRefocusObject = null;
	this.suggestedRefocusProperty = "";
	this.popupMenuShown = "";
	this.drawScreen();
	this.updateButtons();
	return;
}

ClientMethod drawScreen() [ Language = javascript ]
{
	var SPACING = parseInt(this.SPACING);
	var endPoint = new EnsPortal_ExpressionEditor_point();
	var svg = zen('svg');

	if ( this.groupMain ) zen('svg').svgGroup.removeChild(this.groupMain);
	if ( this.moMainMap ) delete this.moMainMap;

	// create the main layer
	this.groupMain = zen('svg').document.createElementNS(SVGNS,'g');
	zen('svg').svgGroup.appendChild(this.groupMain);

	zen('svg').svgGroup.setAttribute("onclick","zenPage.backgroundClicked();");

	this.moMainMap = new Array();
	this.moNextMainIndex = 0;

	this.moFocusedIndex = -1;
	
	var value = this.EXP != "" ? zenEscapeHTML(this.EXP) : "&nbsp;";
	zen("labelEXP").setValue(value);

	this.moJsonRootObject.defaultValue = "";
	var points = this.drawData(SPACING,SPACING,this.moJsonRootObject);
	endPoint = points[0];

	this.moMinWidth = Math.max(endPoint.x+SPACING,100);
	this.moMinHeight = endPoint.y+SPACING;

	svg.setProperty("height",this.moMinHeight);
	svg.setProperty("width",this.moMinWidth);

	return;
}

ClientMethod drawData(x, y, pData, pParentObject, pParentArrayObject, pParentArrayIndex) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var HLINELENGTH = parseInt(this.HLINELENGTH);
	var HINDENT = parseInt(this.HINDENT);
	var SPACING = parseInt(this.SPACING);
	var anchorPoint = new EnsPortal_ExpressionEditor_point();
	var endPoint = new EnsPortal_ExpressionEditor_point();
	var svg=zen('svg');

	if ( this.jsonType(pData) === "value" ) {
		var p = this.drawTextBox(svg,x,y,pData,"value",pParentObject,pParentArrayObject,pParentArrayIndex,null);
		anchorPoint.x = x;
		anchorPoint.y = y+BOXHEIGHT/2;
		endPoint.x=p.x;
		endPoint.y=p.y;
	} else if ( this.jsonType(pData) === "unary" ) {
		// draw the operator box
		var p = this.drawTextBox(svg,x,y,pData,"operator",pParentObject,pParentArrayObject,pParentArrayIndex,pData.operands);
		var group = this.lastGroup;
		var points = this.drawData(p.x+HINDENT,y,pData.operands[0],pData,pData.operands,0);
		endPoint = points[0];
		anchorPoint = points[1];
		// move the operator box to line up with the anchor point
		for ( var child = group.firstChild; child != null ; child = child.nextSibling ) {
			child.setAttribute("y",parseInt(child.getAttribute("y"))-y+anchorPoint.y-BOXHEIGHT/2);
			child.setAttribute("cy",parseInt(child.getAttribute("cy"))-y+anchorPoint.y-BOXHEIGHT/2);
		}
		this.drawLine(svg,p.x,anchorPoint.y,anchorPoint.x,anchorPoint.y);
		anchorPoint.x = x;
	} else {
		// draw the operator box
		var pointOperatorEnd = this.drawTextBox(svg,x,y,pData,"operator",pParentObject,pParentArrayObject,pParentArrayIndex,pData.operands);
		var group = this.lastGroup;
		var xmax = 0;
		var ymover = y;
		var middle = new Array();
		var i, points, p, ap;
		var length = pData.operands.length;
		// draw the operands of the AND/OR first, indented
		for ( var i=0 ; i<length ; i++ ) {
			points = this.drawData(pointOperatorEnd.x+HINDENT,ymover,pData.operands[i],pData,pData.operands,i);
			p = points[0];
			xmax = Math.max(xmax,p.x);
			middle[i] = points[1].y;
			ymover = p.y+SPACING;
		}
		ymover = ymover - SPACING;
		// initially set the center of the box to be middle between first and last child
		var ycenter = (middle[0]+middle[length-1])/2;
		// if the center of the box if slightly off wih one child, line up the center with this child's middle
		for ( i=0 ; i<length ; i++ ) {
			if ( (middle[i]>ycenter-BOXHEIGHT/2)&&(middle[i]<ycenter+BOXHEIGHT/2) ) {
				ycenter = middle[i];
				break;
			}
		}
		// move the operator box, center between the first and the last connector line
		for ( var child = group.firstChild; child != null ; child = child.nextSibling ) {
			child.setAttribute("y",parseInt(child.getAttribute("y"))-y+ycenter-BOXHEIGHT/2);
			child.setAttribute("cy",parseInt(child.getAttribute("cy"))-y+ycenter-BOXHEIGHT/2);
		}
		anchorPoint.x = x;
		anchorPoint.y = ycenter;
		
		// adjust starting point for connector lines if there is a base box behind this box 
		var xbase = x;
		var width = pointOperatorEnd.x-x;
		if ((this.jsonType(pData) != "value")&&(pParentObject)&&(pParentObject.type==="function")) {
			var functionList = this.getFunctionList();
			var fName = pParentObject.operator.toUpperCase();
			if (functionList[fName]) {
				var f = functionList[fName];
				if (f.argSpec[pParentArrayIndex]) {
					var argDef = f.argSpec[pParentArrayIndex];
				 	tag = argDef.name + ' ' + (argDef.optional ? '['+$$$Text('Optional')+']' : '');
					if (tag != "") {
						var extraTagLength = 5 * tag.toString().length + parseInt(this.TEXTMARGIN)*2;
						xbase = x + extraTagLength;
						width = width - extraTagLength;
					}
				}
			}
		}
		
		// draw connector lines
		for ( i=0 ; i<length ; i++ ) {
			this.drawSpiderLine(svg,xbase,ycenter-BOXHEIGHT/2,width,BOXHEIGHT,pointOperatorEnd.x+HINDENT,middle[i]);
		}
		endPoint.x=xmax;
		endPoint.y=ymover;
	}

	return [endPoint, anchorPoint];
}

ClientMethod drawTextBox(svg, x, y, jsonObject, jsonProperty, jsonParentObject, jsonParentArrayObject, jsonParentArrayIndex, jsonChildrenArrayObject) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var TEXTVOFFSET = parseInt(this.TEXTVOFFSET);
	var TEXTMARGIN = parseInt(this.TEXTMARGIN);
	var RADIUS = parseInt(this.RADIUS);
	var caption = jsonObject[jsonProperty];
	var classSuffix = jsonProperty.toUpperCase();
	
	if ( jsonProperty === "operator" ) {
		if ( caption === "&&" ) { caption = "AND"; }
		if ( caption === "||" ) { caption = "OR"; }
	}
	
	// draw variable names for function parameters
	var tag = "";
	if ((jsonParentObject)&&(jsonParentObject.type==="function")) {
		var functionList = this.getFunctionList();
		var fName = jsonParentObject.operator.toUpperCase();
		if (functionList[fName]) {
			var f = functionList[fName];
			if (f.argSpec[jsonParentArrayIndex]) {
				var argDef = f.argSpec[jsonParentArrayIndex];
				tag = argDef.name + ' ' + (argDef.optional ? '['+$$$Text('Optional')+']' : '');
			}
		}
	}

	// create group
	var group = svg.document.createElementNS(SVGNS,'g');
	group.setAttribute("class","rect"+classSuffix);
	this.groupMain.appendChild(group);
	
	// create base for function values
	if (tag!="") {
		var baseRect = svg.document.createElementNS(SVGNS,'rect');
		var baseText = svg.document.createElementNS(SVGNS,'text');
		var baseCover = svg.document.createElementNS(SVGNS,'rect');
		group.appendChild(baseRect);
		group.appendChild(baseText);
		group.appendChild(baseCover);
		// modify baseRect
		baseRect.setAttribute("x",x);
		baseRect.setAttribute("y",y);
		baseRect.setAttribute("rx",RADIUS);
		baseRect.setAttribute("height",BOXHEIGHT);
		baseRect.setAttribute("width",0);
		baseRect.setAttribute("class","rectBase");
		// modify baseText
		baseText.setAttribute("x",x+TEXTMARGIN);
		baseText.setAttribute("y",y+TEXTVOFFSET);
		baseText.setAttribute("class","textBase");
		baseText.appendChild(svg.document.createTextNode(tag));
		var computedBaseTextLength = 0;
		// on IE, text.getComputedTextLength() crashes when caption===""
		var computedBaseTextLength = 0;
		try {
			computedBaseTextLength = (tag==="" ? 0 : baseText.getComputedTextLength() + TEXTMARGIN*2);
		}
		catch(ex) { // catch exception when IE10 doesn't render due to IE security popups
			computedBaseTextLength = 5 * tag.toString().length + TEXTMARGIN*2;
		}
		// modify baseCover
		baseCover.setAttribute("x",x);
		baseCover.setAttribute("y",y);
		baseCover.setAttribute("rx",RADIUS);
		baseCover.setAttribute("height",BOXHEIGHT);
		baseCover.setAttribute("width",0);
		baseCover.setAttribute("style","opacity:0.01");
	} else {
		var computedBaseTextLength = 0;
	}
	
	// create rect and text
	var rect = svg.document.createElementNS(SVGNS,'rect');
	var text = svg.document.createElementNS(SVGNS,'text');
	var cover = svg.document.createElementNS(SVGNS,'rect'); // to avoid I-cursor
	group.appendChild(rect);
	group.appendChild(text);
	group.appendChild(cover);
	
	// modify group
	var newIndex = this.insertMainMap(rect,text,jsonObject,jsonProperty,jsonParentObject,jsonParentArrayObject,jsonParentArrayIndex,jsonChildrenArrayObject);
	group.setAttribute("id",newIndex);
	this.addClickHandler(group,'objectClicked');
	this.lastGroup = group;

	// modify rect
	rect.setAttribute("x",x+computedBaseTextLength);
	rect.setAttribute("y",y);
	rect.setAttribute("rx",RADIUS);
	rect.setAttribute("height",BOXHEIGHT);
	rect.setAttribute("width",0);
	rect.setAttribute("class","rect"+classSuffix);
	if ( this.moFocusedIndex === newIndex ) {
		this.moFocusedOriginalRectClass = rect.getAttribute("class");
		rect.setAttribute("class","rectFocused");
	}

	// modify text
	text.setAttribute("x",x+computedBaseTextLength+TEXTMARGIN);
	text.setAttribute("y",y+TEXTVOFFSET);
	text.setAttribute("class","text"+classSuffix);
	text.appendChild(svg.document.createTextNode(caption));
	if ( this.moFocusedIndex === newIndex ) {
		this.moFocusedOriginalTextClass = text.getAttribute("class");
		text.setAttribute("class","textFocused");
	}
	
	// modify cover
	cover.setAttribute("x",x+computedBaseTextLength);
	cover.setAttribute("y",y);
	cover.setAttribute("rx",RADIUS);
	cover.setAttribute("height",BOXHEIGHT);
	cover.setAttribute("width",0);
	cover.setAttribute("style","opacity:0.01");

	// on IE, text.getComputedTextLength() crashes when caption===""
	var computedTextLength = 0;
	try {
		computedTextLength = caption==="" ? 0 : text.getComputedTextLength();
	}
	catch(ex) { // catch exception when IE10 doesn't render due to IE security popups
		var compTextWidth = (caption.toString() === parseInt(caption,10) ? 8.5 : 9.5).toString();
		computedTextLength = compTextWidth * caption.toString().length;
	}

	// set rect width to the text width plus margins
	rect.setAttribute("width",computedTextLength+TEXTMARGIN*2);
	cover.setAttribute("width",computedTextLength+TEXTMARGIN*2);

	// compute endPoint
	var endPoint = new EnsPortal_ExpressionEditor_point();
	endPoint.x=x+computedBaseTextLength+computedTextLength+TEXTMARGIN*2;
	endPoint.y=y+BOXHEIGHT;
	
	if (tag!="") {
		baseRect.setAttribute("width",computedBaseTextLength+computedTextLength+TEXTMARGIN*2);
		baseCover.setAttribute("width",computedBaseTextLength+computedTextLength+TEXTMARGIN*2);
	}
	
	// add error symbol
	this.checkOperandRange(jsonObject);
	var errorText = jsonObject.errorText;
	var errorColor = "red";
	if ( errorText === "" ) {
		var errorText = jsonObject.warningText;
		var errorColor = "red";
	}
	if ( errorText != "" ) {
	    var alertCircle = svg.document.createElementNS(SVGNS,'circle');
	    group.appendChild(alertCircle);
	    alertCircle.setAttribute('cx',endPoint.x);
	    alertCircle.setAttribute('cy',y);
	    alertCircle.setAttribute('r',6);
		alertCircle.setAttribute('style','fill:'+errorColor+'; stroke:'+errorColor+'; ');
		var alertText = svg.document.createElementNS(SVGNS,'text');
	    group.appendChild(alertText);
		alertText.setAttribute("x",endPoint.x-1);
		alertText.setAttribute("y",y+4);
		alertText.setAttribute("style","fill:white; stroke:none; font-family:arial; font-size:9pt; font-weight:bold;");
		alertText.appendChild(svg.document.createTextNode("!"));
	    var alertCover = svg.document.createElementNS(SVGNS,'circle');
	    group.appendChild(alertCover);
	    alertCover.setAttribute('cx',endPoint.x);
	    alertCover.setAttribute('cy',y);
	    alertCover.setAttribute('r',10);
	    alertCover.setAttribute("style","opacity:0.01");
		alertCover.setAttribute("onclick","alert('"+errorText+"');");
	}
	
	// add default value symbol
	this.checkOperandDefaultVals(jsonObject);
	var defaultVal = jsonObject.defaultValue;
	var infoColor = "blue";
	if (defaultVal != '') {
	    var defCircle = svg.document.createElementNS(SVGNS,'circle');
	    group.appendChild(defCircle);
	    defCircle.setAttribute('cx',endPoint.x);
	    defCircle.setAttribute('cy',y+BOXHEIGHT);
	    defCircle.setAttribute('r',6);
		defCircle.setAttribute('style','fill:'+infoColor+'; stroke:'+infoColor+'; ');
		var defText = svg.document.createElementNS(SVGNS,'text');
	    group.appendChild(defText);
		defText.setAttribute("x",endPoint.x-2);
		defText.setAttribute("y",y+BOXHEIGHT+3);
		defText.setAttribute("style","fill:white; stroke:none; font-family:palatino linotype; font-style: italic; font-size:8pt; font-weight:bold;");
		defText.appendChild(svg.document.createTextNode("i"));
	    var defCover = svg.document.createElementNS(SVGNS,'circle');
	    group.appendChild(defCover);
	    defCover.setAttribute('cx',endPoint.x);
	    defCover.setAttribute('cy',y+BOXHEIGHT);
	    defCover.setAttribute('r',10);
	    defCover.setAttribute("style","opacity:0.01");
		defCover.setAttribute("onclick","alert('"+$$$Text('default value: ')+zenEscapeJS(defaultVal)+"');");
	}

  	return endPoint;
}

ClientMethod drawFrameBox(svg, x, y, width, height) [ Language = javascript ]
{
	var RADIUS = parseInt(this.RADIUS);
	
	var rect = svg.document.createElementNS(SVGNS,'rect');
	rect.setAttribute("x",x);
	rect.setAttribute("y",y);
	rect.setAttribute("rx",RADIUS);
	rect.setAttribute("width",width);
	rect.setAttribute("height",height);
	rect.setAttribute("style","stroke:grey;fill:none");
	this.groupMain.appendChild(rect);
  	return;
}

/// we draw a connect line from a box to the target
/// the starting points can be the middle-top, middle-bottom or the right-middle
ClientMethod drawSpiderLine(svg, xbase, ybase, width, height, xtarget, ytarget) [ Language = javascript ]
{
	if ( ybase > ytarget ) {
		this.drawElbowLine(svg,xbase+width/2,ybase,xtarget,ytarget);
	} else if ( ybase+height < ytarget ) {
		this.drawElbowLine(svg,xbase+width/2,ybase+height,xtarget,ytarget);
	} else {
		this.drawLine(svg,xbase+width,ybase+height/2,xtarget,ytarget);
	}
  	return;
}

/// draw an elbow line between (x1,y1) and (x2,y2)
/// we assume x1<x2
ClientMethod drawElbowLine(svg, x1, y1, x2, y2) [ Language = javascript ]
{
	var RADIUS = parseInt(this.RADIUS);
	var d;
	if ( y1 > y2 ) {
		d = "M " + x1 + " " + y1 + " V " + (y2+RADIUS) + " A " + RADIUS + " " + RADIUS + " 0 0 1 " + (x1+RADIUS) + " " + y2+ " H " + x2;
	} else {
		d = "M " + x1 + " " + y1 + " V " + (y2-RADIUS) + " A " + RADIUS + " " + RADIUS + " 0 0 0 " + (x1+RADIUS) + " " + y2+ " H " + x2;
	}
	var path = svg.document.createElementNS(SVGNS,'path');
	path.setAttribute('style','stroke: grey; fill:none; stroke-width: 1;');
	path.setAttribute('d',d);
    this.groupMain.appendChild(path);
	return;
}

ClientMethod drawLine(svg, x1, y1, x2, y2) [ Language = javascript ]
{
    var line = svg.document.createElementNS(SVGNS,'line');
    line.setAttribute('x1',x1);
    line.setAttribute('y1',y1);
    line.setAttribute('x2',x2);
    line.setAttribute('y2',y2);
    line.setAttribute('style','stroke: grey; stroke-width: 1;');
    this.groupMain.appendChild(line);
  	return;
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	var area = zen("svgScrollingArea");
	var body = zen("body");
	body.getEnclosingDiv().style.overflow = "hidden";
	area.getEnclosingDiv().style.overflow = "auto";

	var combo = document.getElementById("comboType");
	for ( var i=0 ; i<combo.options.length ; i++ ) {
		if ( combo.options[i].value === "OPERATOR" ) {
			combo.options[i].text = $$$Text("operator");
		}
		if ( combo.options[i].value === "FUNCTION" ) {
			combo.options[i].text = $$$Text("function");
		}
	}

	if (this.readOnly || !this.canEdit) {
		var controls = ['comboType','comboOperator','xyzEditor'];
		for (var i=0; i<controls.length; i++) {
			var control = document.getElementById(controls[i]);
			if (control) {
				control.disabled = true;
			}
		}
	}
	if ( this.MODE === "logical" ) {
		document.getElementById('htmlViewFull').style.display = "block";
	}
	this.onresizeHandler();
	this.xyzBase = "\0";
	this.xyzblurHandler = null;
	if ( zenIsIE && !zenIsHTML5 ) { document.getElementById("xyzEditor").style.top = "-1px"; }
	this.menuPopulate();
	return;
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var areaDiv = zen("svgScrollingArea").getEnclosingDiv();
	var bodyDiv = zen("body").getEnclosingDiv();
	var bodyHeight = (zenGetWindowHeight()-121);
	bodyDiv.style.height = bodyHeight + "px";
	areaDiv.style.height = (bodyHeight - zen('bar').getEnclosingDiv().offsetHeight) + "px";
	// enable horizontal and vertical scrollbars for the SVG region
	var newWidth = (zenGetWindowWidth() - 10) + "px";
	bodyDiv.style.width = newWidth; 
	areaDiv.style.width = newWidth;	
	return;
}

ClientMethod insertMainMap(svgRectObject, svgTextObject, jsonObject, jsonProperty, jsonParentObject, jsonParentArrayObject, jsonParentArrayIndex, jsonChildrenArrayObject) [ Language = javascript ]
{
	var newIndex = this.moNextMainIndex++;
	this.moMainMap[newIndex] = {
		"svgRectObject": svgRectObject,
		"svgTextObject": svgTextObject,
		"jsonObject": jsonObject,
		"jsonProperty": jsonProperty,
		"jsonParentObject": jsonParentObject,
		"jsonParentArrayObject": jsonParentArrayObject,
		"jsonParentArrayIndex": jsonParentArrayIndex,
		"jsonChildrenArrayObject": jsonChildrenArrayObject
	};
	if ( (newIndex===this.suggestedRefocusIndex) || ((jsonObject===this.suggestedRefocusObject)&&(jsonProperty===this.suggestedRefocusProperty)) ) {
		this.getFocus(newIndex);
	}
	return newIndex;
}

ClientMethod objectClicked(event, isDoubleClick) [ Language = javascript ]
{
	if ( isDoubleClick ) {
		// double click action here
		if ( (this.MODE==="logical")&&(document.getElementById("checkViewExpanded").checked==false)&&(this.moFocusedIndex>-1) ) {
			var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
			if ( jsonProperty === "value" ) {
				document.getElementById("checkViewExpanded").checked = true;
				this.checkViewExpandedChanged();
			}
		}
	} else {
		this.loseFocus(false);
		this.getFocus(event.currentTarget.getAttribute("id"));
	}
	return (ZLM.killEvent(event));
}

ClientMethod doScroll(delta) [ Language = javascript ]
{
	var area = zen("svgScrollingArea");
	area.getEnclosingDiv().scrollTop = area.getEnclosingDiv().scrollTop + delta*(-54);
	return;
}

ClientMethod backgroundClicked() [ Language = javascript ]
{
	this.menuHide();
	this.loseFocus(false);
	this.updateButtons();
	return;
}

ClientMethod getFocus(id) [ Language = javascript ]
{
	this.moFocusedIndex = id;
	this.suggestedRefocusIndex = id;
	this.suggestedRefocusObject = null;
	this.suggestedRefocusProperty = "";
	this.moFocusedOriginalRectClass = this.moMainMap[this.moFocusedIndex].svgRectObject.getAttribute("class");
	this.moMainMap[this.moFocusedIndex].svgRectObject.setAttribute("class","rectFocused");
	this.moFocusedOriginalTextClass = this.moMainMap[this.moFocusedIndex].svgTextObject.getAttribute("class");
	this.moMainMap[this.moFocusedIndex].svgTextObject.setAttribute("class","textFocused");
	// change the title bar
	if ( this.moMainMap[this.moFocusedIndex].jsonProperty === "operator" ) {
		if ( (this.MODE==="logical")&&(document.getElementById("checkViewExpanded").checked==false) ) {
			zen("emptyBar").getEnclosingDiv().style.display = "none";
			zen("xyzBar").getEnclosingDiv().style.display = "none";
			zen("operatorBar").getEnclosingDiv().style.display = "none";
			zen("funcDesc").setProperty("hidden",true);
			this.onresizeHandler();
			zen("logicalBar").getEnclosingDiv().style.display = "block";
			zen("logicalEditor").setValue(this.moMainMap[id].jsonObject[this.moMainMap[id].jsonProperty]==="&&"?"AND":"OR");
			if (this.canEdit && !this.readOnly) {
				zen("logicalEditor").focus();
			}
		} else  {
			zen("emptyBar").getEnclosingDiv().style.display = "none";
			zen("xyzBar").getEnclosingDiv().style.display = "none";
			zen("operatorBar").getEnclosingDiv().style.display = "block";
			zen("logicalBar").getEnclosingDiv().style.display = "none";
			var type = (this.jsonType(this.moMainMap[this.moFocusedIndex].jsonObject)==="function")?"function":"operator";
			this.setComboValue(document.getElementById("comboType"),type);
			this.comboTypeChanged(true);
			var selection = this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty];
			this.setComboValue(document.getElementById("comboOperator"),selection);
			
			if (type === "function") {
				var functionList = this.getFunctionList();
				if (functionList[selection.toUpperCase()]) {
					var f = functionList[selection.toUpperCase()];
					var desc = f.description;
					if (desc != "") {
						zen("htmlDesc").setProperty("content",desc);
						zen("funcDesc").setProperty("hidden",false);
					} else {
						zen("funcDesc").setProperty("hidden",true);
					}
					this.onresizeHandler();  // to adjust for space taken up by the function description
				}
			} else {
				zen("funcDesc").setProperty("hidden",true);
				this.onresizeHandler();  // function description no longer taking up space
			}
			
			if (this.canEdit && !this.readOnly) {
				document.getElementById("comboOperator").focus();
			}
		}
	} else {
		zen("emptyBar").getEnclosingDiv().style.display = "none";
		zen("xyzBar").getEnclosingDiv().style.display = "block";
		zen("operatorBar").getEnclosingDiv().style.display = "none";
		zen("funcDesc").setProperty("hidden",true);
		this.onresizeHandler(); // function description no longer taking up space
		zen("logicalBar").getEnclosingDiv().style.display = "none";
		if ( document.getElementById("xyzEditor").value != this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty] ) {
			document.getElementById("xyzEditor").value = this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty];
			document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value;
		}
		if (this.canEdit && !this.readOnly) {
			document.getElementById("xyzEditor").focus();
		}
		if ( this.moMainMap[id].jsonObject.errorText!="" ) {
			var offset = this.moMainMap[id].jsonObject.errorOffset;
			this.setSelection(document.getElementById("xyzEditor"),offset,offset)
		}
	}
	this.updateButtons();

	return;
}

ClientMethod loseFocus(attemptRefocusOnNextDraw) [ Language = javascript ]
{
	this.transferEditorData();
	if ( this.moFocusedIndex > -1 ) {
		this.moMainMap[this.moFocusedIndex].svgRectObject.setAttribute("class",this.moFocusedOriginalRectClass);
		this.moMainMap[this.moFocusedIndex].svgTextObject.setAttribute("class",this.moFocusedOriginalTextClass);
		this.suggestedRefocusIndex = attemptRefocusOnNextDraw ? this.moFocusedIndex : -1;
		this.suggestedRefocusObject = null;
		this.suggestedRefocusProperty = "";
		this.moFocusedIndex = -1;
		zen("emptyBar").getEnclosingDiv().style.display = "block";
		zen("xyzBar").getEnclosingDiv().style.display = "none";
		zen("operatorBar").getEnclosingDiv().style.display = "none";
		zen("funcDesc").setProperty("hidden",true);
		this.onresizeHandler(); // function description no longer taking up space
		zen("logicalBar").getEnclosingDiv().style.display = "none";
	}
	return;
}

ClientMethod transferEditorData() [ Language = javascript ]
{
	if (this.readOnly || !this.canEdit) { return; }
	
	if ( zen("xyzBar").getEnclosingDiv().style.display === "block" ) {
		this.xyzOKClicked();
	}
	return;
}

ClientMethod updateButtons() [ Language = javascript ]
{
	if ( this.canEdit && (!this.readOnly) && (this.moFocusedIndex > -1) ) {
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		var jsonChildrenArrayObject = this.moMainMap[this.moFocusedIndex].jsonChildrenArrayObject;

		this.changeImage("imgUp",(jsonParentArrayObject!=null)&&(jsonParentArrayIndex>0));
		this.changeImage("imgDown",(jsonParentArrayObject!=null)&&(jsonParentArrayIndex<(jsonParentArrayObject.length-1)));
		this.changeImage("imgLeft",(this.jsonType(jsonObject)==="binary")&&(jsonParentObject)&&(jsonObject.operator===jsonParentObject.operator)&&this.jsonIsMultiary(jsonObject.operator));
		this.changeImage("imgOperator",true);
		this.changeImage("imgFunction",true);
		this.changeImage("imgAdd",jsonParentArrayObject!=null);
		this.changeImage("imgDelete",(this.jsonType(jsonObject)!="value")||((jsonParentArrayObject!=null)&&(jsonParentArrayObject.length>1)));
	} else {
		this.changeImage("imgUp",false);
		this.changeImage("imgDown",false);
		this.changeImage("imgLeft",false);
		this.changeImage("imgOperator",false);
		this.changeImage("imgFunction",false);
		this.changeImage("imgAdd",false);
		this.changeImage("imgDelete",false);
	}
	
	return;
}

ClientMethod changeImage(imageId, enabled) [ Language = javascript ]
{
	var newsrc = zen(imageId).src;
	if ( enabled ) {
		if ( this.moPointInImage === zen(imageId) ) {
			newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_hover.png";
		} else {
			newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_enabled.png";
		}
	} else {
		newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_disabled.png";
	}
	zen(imageId).setProperty("src",newsrc);
	return;
}

ClientMethod mouseOver(image) [ Language = javascript ]
{
	if ( image.src.indexOf("disabled") != -1 ) return;
	this.moPointInImage = image;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_hover.png");
	return;
}

ClientMethod mouseOut(image) [ Language = javascript ]
{
	if ( image.src.indexOf("disabled") != -1 ) return;
	if ( (image.id==="imgOperator")&&(this.popupMenuShown==="Operator") ) return;
	if ( (image.id==="imgFunction")&&(this.popupMenuShown==="Function") ) return;
	this.moPointInImage = null;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_enabled.png");
	return;
}

ClientMethod mouseDown(event, image) [ Language = javascript ]
{
	var button = zenIsIE && !zenIsHTML5 ? event.button : event.which;
	if ( button != 1 ) return;
	if ( image.src.indexOf("disabled") != -1 ) return;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_pressed.png");
	if ( image.id === "imgOperator" ) this.buttonOperatorMouseDown();
	if ( image.id === "imgFunction" ) this.buttonFunctionMouseDown();
	return;
}

ClientMethod mouseUp(event, image) [ Language = javascript ]
{
	var button = zenIsIE && !zenIsHTML5 ? event.button : event.which;
	if ( button != 1 ) return;
	if ( image.src.indexOf("disabled") != -1 ) return;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_hover.png");
	switch ( image.id ) {
		case "imgUp":
			setTimeout("zenPage.buttonUpClicked()",0);
			break;
		case "imgDown":
			setTimeout("zenPage.buttonDownClicked()",0);
			break;
		case "imgLeft":
			setTimeout("zenPage.buttonLeftClicked()",0);
			break;
		case "imgAdd":
			setTimeout("zenPage.buttonAddClicked()",0);
			break;
		case "imgDelete":
			setTimeout("zenPage.buttonDeleteClicked()",0);
			break;
	}
	return;
}

ClientMethod debugClicked() [ Language = javascript ]
{
	return;
}

ClientMethod buttonUpClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		if ( (jsonParentArrayObject!=null)&&(jsonParentArrayIndex>0) ) {
			var savedObject = jsonParentArrayObject[jsonParentArrayIndex];
			jsonParentArrayObject[jsonParentArrayIndex] = jsonParentArrayObject[jsonParentArrayIndex-1];
			jsonParentArrayObject[jsonParentArrayIndex-1] = savedObject;
			this.suggestedRefocusIndex = -1;
			this.suggestedRefocusObject = savedObject;
			this.suggestedRefocusProperty = (savedObject.type==="value" ? "value" : "operator");
			this.drawScreen();
		}
	}
	return;
}

ClientMethod buttonDownClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		if ( (jsonParentArrayObject!=null)&&(jsonParentArrayIndex<(jsonParentArrayObject.length-1)) ) {
			var savedObject = jsonParentArrayObject[jsonParentArrayIndex];
			jsonParentArrayObject[jsonParentArrayIndex] = jsonParentArrayObject[jsonParentArrayIndex+1];
			jsonParentArrayObject[jsonParentArrayIndex+1] = savedObject;
			this.suggestedRefocusIndex = -1;
			this.suggestedRefocusObject = savedObject;
			this.suggestedRefocusProperty = (savedObject.type==="value" ? "value" : "operator");
			this.drawScreen();
		}
	}
	return;
}

ClientMethod buttonLeftClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		if ( (jsonParentObject)&&(jsonObject.operator===jsonParentObject.operator)&&(this.jsonType(jsonObject)==="binary")&&(this.jsonIsMultiary(jsonObject.operator)) ) {
			var childIndex = -1;
			var i;
			if (typeof jsonParentObject.operands.indexOf == 'function') {
				childIndex = jsonParentObject.operands.indexOf(jsonObject);
			}
			else {
				for ( i=0 ; i<jsonParentObject.operands.length ; i++ ) { if ( jsonParentObject.operands[i]===jsonObject ) childIndex=i; }
			}
			if ( childIndex>-1 ) {
				jsonParentObject.operands.splice(childIndex,1);
				for ( i=0 ; i<jsonObject.operands.length ; i++ ) {
					jsonParentObject.operands.splice(childIndex+i,0,jsonObject.operands[i]);
				}
			}
		}
		this.drawScreen();
	}
	return;
}

ClientMethod buttonOperatorMouseDown() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	if ( zen("imgOperator").src.indexOf("disabled") != -1 ) return;
	this.menuShow("Operator",97,115);
	return;
}

ClientMethod buttonFunctionMouseDown() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	if ( zen("imgFunction").src.indexOf("disabled") != -1 ) return;
	this.menuShow("Function",124,115);
	return;
}

ClientMethod menuPopulate() [ Language = javascript ]
{
	var functionList = this.getFunctionList();
	for ( f in functionList ) {
		this.menuInsertItem("Function",functionList[f].name);
	}
	this.menuInsertItem("Operator","AND","&&");
	this.menuInsertItem("Operator","OR","||");
	this.menuInsertItem("Operator","+");
	this.menuInsertItem("Operator","-");
	this.menuInsertItem("Operator","!");
	this.menuInsertItem("Operator","*");
	this.menuInsertItem("Operator","/");
	this.menuInsertItem("Operator","!=");
	this.menuInsertItem("Operator","=");
	this.menuInsertItem("Operator",">=");
	this.menuInsertItem("Operator","<=");
	this.menuInsertItem("Operator",">");
	this.menuInsertItem("Operator","<");
	this.menuInsertItem("Operator","&");
	this.menuInsertItem("Operator","[");
	this.menuInsertItem("Operator","_");
	this.menuUpdateGeometry("Function");
	this.menuUpdateGeometry("Operator");
}

ClientMethod menuInsertItem(menuName, caption, logical) [ Language = javascript ]
{
	if ( !logical ) { logical = caption; }
	var menu = this.getComponentById("menu"+menuName);
	var menuCore = menu.getEnclosingDiv().item;
	var wrapper = ZLM.makeElement("div");
	var pick = ZLM.simulateTag("div class='csMenuItem' caption='"+caption+"'");
	if (pick.className === '') pick.className = 'csMenuItem';
	if (menuName === 'Function') {
		var functionList = this.getFunctionList();
		if (functionList[caption.toUpperCase()]) {
			var num = functionList[caption.toUpperCase()].argSpec.length;
		}
	}
	else {
		var range = this.getOperatorOperandRange(logical);
		var num = range.min;
	}
	pick.setAttribute('onselect',"zenPage.menuSelected(\""+menuName.toLowerCase()+":"+logical+":"+num+"\");");
	wrapper.appendChild(pick);
	menuCore.appendChild(wrapper);
	ZMS.createMenuItemSubtree(pick,20);
}

ClientMethod menuUpdateGeometry(menuName) [ Language = javascript ]
{
	var menu = zen("menu"+menuName);
	if (menu) {
		var menuCore = menu.getEnclosingDiv().item;
		if (menuCore) {
			ZMS.estimateContextMenuSize(menuCore);
			ZMS.setContextMenuSize(menuCore);
		}
	}
}

ClientMethod menuShow(menuName, x, y) [ Language = javascript ]
{
	var menu = this.getComponentById("menu"+menuName);
	var menuCore = menu.getEnclosingDiv().item;
	var maxHeight = zenGetWindowHeight() - y - 50;
	menuCore.style.overflowY = 'auto';
	menuCore.style.overflowX = 'hidden';
	ZMS.showPullDownMenu(x,y,menuCore);
	if (menuCore.clientHeight > maxHeight) {
		ZMS.cropMenu(menuCore,maxHeight);
	}
	else if (menuCore.scrollHeight < maxHeight) {
		ZMS.cropMenu(menuCore,menuCore.scrollHeight + 10);
	}
	else if ((menuCore.clientHeight < maxHeight) && (menuCore.scrollHeight >= maxHeight)) {
		ZMS.cropMenu(menuCore,maxHeight);
	}
	zenPage.correctIELayering(menuCore);  
	if (ZMS.mouseTrap) {
		ZLM.setLocalAttribute(ZMS.mouseTrap,"onclick","zenPage.menuOnClose(event);"); 
		ZLM.setLocalAttribute(ZMS.mouseTrap,"oncontextmenu","zenPage.menuOnClose(event);");
	}
	this.popupMenuShown = menuName;
	return;
}

ClientMethod menuHide() [ Language = javascript ]
{
	if ( this.popupMenuShown != "" ) {
		var menuName = this.popupMenuShown;
		this.popupMenuShown = "";
		this.mouseOut(zen("img"+menuName));
		ZMS.closeMenu(null);
	}
	return;
}

ClientMethod menuOnClose(event) [ Language = javascript ]
{
	var menuName = this.popupMenuShown;
	this.popupMenuShown = "";
	this.mouseOut(zen("img"+menuName));
	ZMS.closeMenu(event);
	return;
}

ClientMethod menuSelected(menuSelection) [ Language = javascript ]
{
	this.menuHide();
	if ((!this.checkEdit()) || this.readOnly) { return; }

	var itemType = menuSelection.split(":")[0];
	var itemValue = menuSelection.split(":")[1];
	var minOperands = menuSelection.split(":")[2];
	if ( this.moFocusedIndex > -1 ) {
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		if ( (jsonParentArrayObject!=null)||(jsonObject===this.moJsonRootObject) ) {
			if ( (this.MODE==="logical")&&(document.getElementById("checkViewExpanded").checked==false) ) {
				var newOperator = this.reverseOperator(jsonObject.operator);
				if ( (newOperator==="")&&(jsonParentObject!=null) ) newOperator = this.reverseOperator(jsonParentObject.operator);
				if ( newOperator==="" ) newOperator="&&";
				var newObject = this.jsonNewLogical(newOperator, jsonObject, this.jsonNewExpression("value",""));
			} else {
				var newObject = this.jsonNewExpression(itemType,itemValue);
				newObject.operands[0] = jsonObject;
			}
			if ( jsonParentArrayObject!=null ) {
				jsonParentArrayObject[jsonParentArrayIndex] = newObject;
			} else {
				this.moJsonRootObject = newObject;
			}
			for ( var i=newObject.operands.length ; i<minOperands ; i++ ) {
				newObject.operands.push(this.jsonNewExpression("value",""));
			}
			this.reparse(true);
			this.drawScreen();
		}
	}
	return;
}

ClientMethod reverseOperator(operator) [ Language = javascript ]
{
	if ( operator==="&&" ) return "||";
	if ( operator==="||" ) return "&&";
	return "";
}

ClientMethod buttonAddClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		if ( jsonParentArrayObject != null ) {
			var newExpression = this.jsonNewExpression("value","");
			jsonParentArrayObject.splice(jsonParentArrayIndex+1,0,newExpression);
			this.suggestedRefocusIndex = -1;
			this.suggestedRefocusObject = newExpression;
			this.suggestedRefocusProperty = "value";
			jsonParentObject.warningText = "";
			this.reparse(false);
			this.drawScreen();
		}
	}
	return;
}

ClientMethod buttonDeleteClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		if ( this.jsonType(jsonObject) === "value" ) {
			if ( jsonParentArrayObject == null ) {
				// logic in updateButtons() should ensure we never reach here
				alert($$$Text("Cannot remove root node"));
			} else {
				jsonParentArrayObject.splice(jsonParentArrayIndex,1);
				var jsonNextSiblingNode = jsonParentArrayObject[Math.min(jsonParentArrayIndex,jsonParentArrayObject.length-1)];
				this.suggestedRefocusIndex = -1;
				this.suggestedRefocusObject = jsonNextSiblingNode;
				this.suggestedRefocusProperty = this.jsonType(jsonNextSiblingNode)==="value" ? "value" : "operator";
			}
		} else {
			if ( jsonObject.operands.length > 1 ) {
				if ( this.jsonType(jsonObject) === "function" ) {
					var answer = confirm("OK to delete the function and all of its arguments and replace it with the first argument?");
				} else {
					var answer = confirm("OK to delete the operator and all of its operands and replace it with the first operand?");
				}
			} else {
				var answer = 1;
			}
			if ( answer ) {
				if ( jsonParentArrayObject != null ) {
					jsonParentArrayObject[jsonParentArrayIndex] = jsonObject.operands[0];
				} else {
					this.moJsonRootObject = jsonObject.operands[0];
				}
				this.suggestedRefocusIndex = -1;
				this.suggestedRefocusObject = jsonObject.operands[0];
				this.suggestedRefocusProperty = this.jsonType(jsonObject.operands[0])==="value" ? "value" : "operator";	
			}
		}
		if ( jsonParentObject != null ) jsonParentObject.warningText = "";
		this.reparse(false);
		this.drawScreen();
	}
	return;
}

ClientMethod checkViewExpandedChanged() [ Language = javascript ]
{
	this.VIEWEXPANDED = document.getElementById("checkViewExpanded").checked ? 1 : 0;
	this.reparse(true);
	this.loseFocus();
	this.updateButtons();
	this.drawScreen();
	return;
}

ClientMethod reparse(updateJsonObject) [ Language = javascript ]
{
	var json = this.getComponentById('model');
	json.setContentObject(this.moJsonRootObject);
	json.submitContent('save');
	if ( updateJsonObject ) {
		json.reloadContents();
		var obj = json.getContentObject();
		this.moJsonRootObject = obj;
	}
	return;
}

ClientMethod jsonType(object) [ Language = javascript ]
{
	var alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

	if ( object.operator === "" ) {
		return "value";
	} else if ( alpha.indexOf(object.operator.substr(0,1)) != -1 ) {
		return "function";
	} else if ( object.operands.length === 1 ) {
		return "unary";
	} else {
		return "binary";
	}
}

ClientMethod jsonIsMultiary(operator) [ Language = javascript ]
{
	if ( operator === "&&" ) return 1;
	if ( operator === "||" ) return 1;
	if ( operator === "+" ) return 1;
	if ( operator === "*" ) return 1;
	if ( operator === "&" ) return 1;
	if ( operator === "_" ) return 1;
	return 0;
}

ClientMethod jsonNewLogical(operator, operand1, operand2) [ Language = javascript ]
{
	var newObject = {
		"_class": "Ens.Rule.Model.expression",
		"type": "binary",
		"errorText": "",
		"warningText": "",
		"operator": operator,
		"operands": [ operand1, operand2 ]
	};
	return newObject;
}

ClientMethod jsonNewExpression(type, value) [ Language = javascript ]
{
	var newObject = {
		"_class": "Ens.Rule.Model.expression",
		"type": type,
		"errorText": "",
		"warningText": "",
		"operator": value,
		"operands": [],
		"value": ""
	};
	return newObject;
}

ClientMethod logicalEditorChanged() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty] = zen("logicalEditor").getValue()==="AND"?"&&":"||";
		this.reparse(false);
		this.drawScreen();
	}
	return;
}

ClientMethod xyzEditorKeyPressed(event) [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }

	// the current value is before the keyPreess is applied, save it for comparision later
	this.oldTextValue = document.getElementById("xyzEditor").value;
	
	// right arrow on the last character completes the string
	if ( event.keyCode===39 ) {
		var selection = this.getSelection(document.getElementById("xyzEditor"));
		if ( (selection.start===selection.end) && (selection.start===this.oldTextValue.length) ) {
			document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
		}
	}
	// tab or enter key at any position completes the string
	if ( (event.keyCode===9) || ((event.keyCode===13)) ) {
		document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
		// kill event to prevent focus being changed
		ZLM.killEvent(event);
	}
	/*
	// return means all done (this has been disabled, return/enter key now is the same as the tab key
	if ( event.keyCode===13 ) {
		if ( document.getElementById("xyzGrayText").value === document.getElementById("xyzEditor").value ) {
			this.xyzOKClicked();
		} else {
			document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value;
			if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
			document.getElementById("xyzSelector").style.display = "none";
		}
	}
	*/
	// escape key means all done
	if ( event.keyCode===27 ) {
		// On FireFox, under ESC, the value of xyzEditor is somehow rolled back if the previous action was the TAB key.
		// To reproduce this, do the following key sequence: %, TAB, ESC.
		// This probably is caused by the ZLM.killEvent(event) call in the TAB handling,
		// but we have no control over this rolling back.
		// We work around this problem by deferring the ESC action until after the rolling back has occured.
		setTimeout("zenPage.deferredEscapeAction()",1);
		return;
	}
	// up and down arrow changes the selection in the xyzSelector
	if ( event.keyCode===38 ) {
		if ( document.getElementById("xyzSelector").selectedIndex > 0 ) {
			document.getElementById("xyzSelector").selectedIndex --; 
		}
		this.xyzSelectorChanged();
	}
	if ( event.keyCode===40 ) {
		if ( document.getElementById("xyzSelector").selectedIndex < (document.getElementById("xyzSelector").options.length)-1 ) {
			document.getElementById("xyzSelector").selectedIndex ++;
		}
		this.xyzSelectorChanged();
	}
	setTimeout("zenPage.xyzDoAction()",1);
	return;
}

ClientMethod deferredEscapeAction() [ Language = javascript ]
{
	document.getElementById("xyzEditor").value = this.oldTextValue;
	document.getElementById("xyzGrayText").value = this.oldTextValue;
	if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
	document.getElementById("xyzSelector").style.display = "none";
	return;
}

ClientMethod xyzEditorOnBlur(event) [ Language = javascript ]
{
	this.xyzblurHandler = setTimeout("zenPage.xyzEditorLostFocus();",100);
	return;
}

ClientMethod xyzGrayTextGotFocus(event) [ Language = javascript ]
{
	// this is to handle IE9 problem that the control textbox is clicked through to the ghost textbox
	var length = document.getElementById("xyzEditor").value.length;
	this.setSelection(document.getElementById("xyzEditor"),length,length);
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzEditorLostFocus() [ Language = javascript ]
{
	document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value
	if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
	document.getElementById("xyzSelector").style.display = "none";
	return;
}

ClientMethod xyzSelectorFocused() [ Language = javascript ]
{
	if ( this.xyzblurHandler != null ) {
		clearTimeout(this.xyzblurHandler);
		this.xyzblurHandler = null;
	}
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzSelectorChanged() [ Language = javascript ]
{
	var select = document.getElementById("xyzSelector");
	document.getElementById("xyzGrayText").value = select.options[select.selectedIndex].text;
	return;
}

ClientMethod xyzSelectorDblClicked() [ Language = javascript ]
{
	document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
	this.xyzDoAction();
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzDoAction() [ Language = javascript ]
{
	var textValue = document.getElementById("xyzEditor").value;
	if ( textValue === this.oldTextValue ) return;
	
	// check to see if we need to reload data
	var curlPos = textValue.lastIndexOf('.(');
	var bracePos = textValue.lastIndexOf('{');
	if ((curlPos >= 0) && ((bracePos < 0) || (bracePos > curlPos))) {
		curlPos += 1; // cater for second character
	}
	else {
		curlPos = -1;
	}
	var lastIndex = Math.max(textValue.lastIndexOf("."),bracePos,textValue.lastIndexOf(":"),curlPos);
	var updatedData = false;
	var xyzBase = textValue.substr(0,lastIndex+1);
	if ( xyzBase != this.xyzBase ) {
		this.xyzLoadData(xyzBase);
		updatedData = true;
	}
	var textProperty = textValue.substr(lastIndex+1);
	var textPropertyLength = textProperty.length;
	var propertyFound = "";
	var propertyListFiltered = new Array();
	var exactMatchFound = false;
	
	// find out if this field represents a lookup table. we will auto-complete with lookup table names instead of properties if so.
	var isLookup = false;
	var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
	if (jsonParentObject&&(this.jsonType(jsonParentObject)==="function")){
		var operator = jsonParentObject.operator.toUpperCase();
		var functionList = this.getFunctionList();
		if (functionList[operator]) {
			var f = functionList[operator];
			var index = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
			if ((f.argSpec[index]) && (f.argSpec[index].isLookup)) {
				isLookup = true;
			}
		}
	}
	
	// search to see if partial match exists
	if (isLookup) {
		// add lookup tables to auto-complete text if appropriate to do so
		for (var i=0; i<this.lookupTables.length; i++) {
			if ( this.lookupTables[i].substr(0,textPropertyLength) === textProperty ) {
				propertyListFiltered.push(this.lookupTables[i]);
				if ( propertyFound === "" ) {
					propertyFound = this.lookupTables[i];
					exactMatchFound = (propertyFound === textValue);
				}
			}
		}
	} else {
		// add properties to auto-complete text
		for ( var i=0 ; i<this.propertyListComplete.length ; i++ ) {
			if ( this.propertyListComplete[i].substr(0,textPropertyLength) === textProperty ) {
				propertyListFiltered.push(xyzBase + this.propertyListComplete[i]);
				if ( propertyFound === "" ) {
					propertyFound = xyzBase + this.propertyListComplete[i];
					exactMatchFound = (propertyFound === textValue);
				}
			}
		}
	}

	// update the auto-complete text in grayText
	if ( propertyFound === "" ) {
		document.getElementById("xyzGrayText").value = textValue
	} else {
		document.getElementById("xyzGrayText").value = propertyFound;
	}

	// update the xyzSelector
	if ( propertyListFiltered.length < 1 ) {
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else if ( (propertyListFiltered.length===1) && (exactMatchFound==true) ) { 
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else if ( (updatedData==false) && (exactMatchFound==true) ) {
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else {
		if ((!this.iFrameCreated)) { //SAM055
			var div = document.getElementById("xyzSelectorParent");
			var iFrame = document.createElement("iframe");
			iFrame.id = 'xyzSelectorIFrame';
			iFrame.src = '';
			iFrame.frameBorder = '0';
			var s = iFrame.style;
			s.filter = 'alpha(opacity=0)';
			s.zIndex = '0';
			s.position = 'absolute'; 
			s.top = '0px'; 
			s.left = '0px'; 
			s.width = '100%'; 
			s.height = '100%'; 
			s.border = '0px solid black';
			s.background = 'transparent';
			div._iFrame = iFrame;
			div.insertBefore(div._iFrame,div.firstChild);
			this.iFrameCreated = true;
		}
		document.getElementById("xyzSelectorIFrame").style.display = "block";
		document.getElementById("xyzSelector").style.display = "block";
		// update the Combo has to be done after the stack is cleared so the screen can be painted correctly
		this.propertyListFiltered = propertyListFiltered;
		setTimeout("zenPage.deferredComboUpdate()",0);
	}
	return;
}

ClientMethod deferredComboUpdate() [ Language = javascript ]
{
	var propertyListFiltered = this.propertyListFiltered;
	var options = "";
	for ( var i=0 ; i<propertyListFiltered.length ; i++ ) {
		options = options + "," + propertyListFiltered[i];
	}
	this.setComboOptions(document.getElementById("xyzSelector"),options.substr(1),false);
	document.getElementById("xyzSelector").selectedIndex = 0;
	return;
}

ClientMethod xyzLoadData(xyzBase) [ Language = javascript ]
{
	this.xyzBase = xyzBase;
	if ( xyzBase==="@" ) {
		if ( window.opener ) {
			this.propertyListComplete = new Array();
			for ( var i=0 ; i<window.opener.zenPage.moRuleDefinitionObject.variables.length ; i++ ) {
				this.propertyListComplete[i] = window.opener.zenPage.moRuleDefinitionObject.variables[i].name;
			}
		}
	} else {
		var context = new zenProxy();
		this.getRuleContext(context);
		var data = this.ServerGetPropertyList(context,xyzBase);
		this.propertyListComplete = new Array();
		this.propertyListComplete = data.split(",");
	}
	var list = this.ServerGetTableList();
	this.lookupTables = new Array();
	this.lookupTables = list.split(",");
	return;
}

ClientMethod getRuleContext(context) [ Language = javascript ]
{
	var opener = this.getOpener();
	if ( opener ) {
		opener.zenPage.getRuleContext(context);
	}
	return;
}

ClientMethod xyzOKClicked() [ Language = javascript ]
{
	if ((!this.checkEdit()) || this.readOnly) { return; }
	
	if ( this.moFocusedIndex > -1 ) {
		var focusedObject = this.moMainMap[this.moFocusedIndex];
		var xyzEditorValue = document.getElementById("xyzEditor").value;
		// ensure we strip trailing "."
		if (xyzEditorValue.substring(xyzEditorValue.length - 1) == '.') {
			xyzEditorValue = xyzEditorValue.substring(0,xyzEditorValue.length-1);
			document.getElementById("xyzEditor").value = xyzEditorValue;
		}
		if ( focusedObject.jsonObject[focusedObject.jsonProperty] != xyzEditorValue ) {
			focusedObject.jsonObject[focusedObject.jsonProperty] = xyzEditorValue;
			this.reparse(true);
			this.loseFocus(true);
			this.drawScreen();
		}
	}
	return;
}

ClientMethod comboTypeChanged(noCheck) [ Language = javascript ]
{
	if ((!noCheck) && ((!this.checkEdit()) || this.readOnly)) { return; }
	
	var combo = document.getElementById("comboType");
	// use item() accessor for IE8 AND make sure the selected index is >= 0
	var currOption = (combo.selectedIndex >= 0 ? combo.options.item(combo.selectedIndex) : null);
	var value = (currOption ? currOption.value : '');

	switch ( value ) {
		case "OPERATOR":
			this.setComboOptions(document.getElementById("comboOperator"),"&&,||,+,-,!,*,/,!=,=,>=,<=,>,<,&,[,_",false,"AND,OR,+,-,!,*,/,!=,=,>=,<=,>,<,&,[,_");
			if ( this.moFocusedIndex > -1 ) {
				this.setComboValue(document.getElementById("comboOperator"),this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty]);
			}
			break;
		case "FUNCTION":
			this.setComboOptions(document.getElementById("comboOperator"),this.getFunctionSelections().toUpperCase(),false,this.getFunctionSelections());
			if ( this.moFocusedIndex > -1 ) {
				this.setComboValue(document.getElementById("comboOperator"),this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty]);
			}
			break;
		default:
			this.setComboOptions(document.getElementById("comboOperator"),"",false);
	}
	return;
}

ClientMethod comboOperatorChanged() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	
	var combo = document.getElementById("comboOperator");
	if ( this.moFocusedIndex > -1 ) {
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
		var selection = combo.options[combo.selectedIndex].value;
		if ( selection != "" ) {
			var selector = document.getElementById("comboType");
			var type = selector.options[selector.selectedIndex].text;
			jsonObject.type = type;
			jsonObject.warningText = "";
			if (type.toUpperCase() === "FUNCTION") {
				var functionList = this.getFunctionList();
				if (functionList[selection] ) {
					var numOperands = functionList[selection].argSpec.length;
					for ( var i=jsonObject.operands.length ; i<numOperands ; i++ ) {
						jsonObject.operands.push(this.jsonNewExpression("value",""));
					}
					selection = (functionList[selection].name);
				}
			}
			jsonObject[jsonProperty] = selection;
			this.suggestedRefocusIndex = -1;
			this.suggestedRefocusObject = jsonObject;
			this.suggestedRefocusProperty = "operator";
			this.reparse(false);
			this.drawScreen();
		}
	}
	return;
}

ClientMethod checkOperandRange(jsonObject) [ Language = javascript ]
{
	if ( jsonObject.type === "function" ) {
		var functionList = this.getFunctionList();
		var fName = jsonObject.operator.toUpperCase();
		if (functionList[fName]) {
			var f = functionList[fName];
			var args = f.argSpec;
			if ((args.length === 0) && (jsonObject.operands.length > 1)) {
				jsonObject.warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes one null argument");
			} else if ((args.length === 1) && (jsonObject.operands.length != 1)) {
				jsonObject.warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes one argument");
			} else if ((args.length != 0) && (jsonObject.operands.length != args.length)) {
				jsonObject.warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes") + " " + args.length + " " + $$$Text("arguments");
			}
			for (var i=0 ; i<jsonObject.operands.length ; i++) {
				if ( (args[i])&&(!args[i].optional)&&(jsonObject.operands[i].type==="value")&&(jsonObject.operands[i].value==="") ) {
					jsonObject.operands[i].warningText = $$$Text("value is required");
				} else if ((args.length === 0) && ((i>0)||(jsonObject.operands[i].value != ""))) {
					jsonObject.operands[i].warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes one null argument");
				} else if ((i >= args.length) && (args.length ==1)) {
					jsonObject.operands[i].warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes only one argument");
				} else if ((i >= args.length)&&(args.length!=0)) {
					jsonObject.operands[i].warningText = $$$Text("function") + " \"" + jsonObject.operator + "\" " + $$$Text("takes only") + " " + args.length + " " +$$$Text("arguments");
				} else {
					jsonObject.operands[i].warningText = "";
				}
			}
		}

		else {
			jsonObject.warningText = $$$Text("invalid function name");
		} 
		
	} else if ( jsonObject.type != "value" ) {
		
		var range = this.getOperatorOperandRange(jsonObject.operator);
		if ( (range.max!=-1)&&(jsonObject.operands.length > range.max) ) {
			jsonObject.warningText = $$$Text("operator") + " \"" + jsonObject.operator + "\" " + $$$Text("takes a maximum of") + " " + range.max + " " + $$$Text("operands");
		}
		if ( jsonObject.operands.length < range.min ) {
			jsonObject.warningText = $$$Text("operator") + " \"" + jsonObject.operator + "\" " + $$$Text("takes a minimum of") + " " + range.min + " " + $$$Text("operands");
		}
		for ( var i=0 ; i<jsonObject.operands.length ; i++ ) {
			if ( (jsonObject.operands[i].type==="value")&&(jsonObject.operands[i].value==="") ) {
				jsonObject.operands[i].warningText = $$$Text("value is required")
			}
		}
	}
	return;
}

ClientMethod checkOperandDefaultVals(jsonObject) [ Language = javascript ]
{
	if ( jsonObject.type === "function" ) {
		var functionList = this.getFunctionList();
		var fName = jsonObject.operator.toUpperCase();
		if (functionList[fName]) {
			var f = functionList[fName];
			var args = f.argSpec;
			for ( var i=0 ; i<jsonObject.operands.length ; i++ ) {
				if ((args[i])&&(args[i].defaultValue!="")) {
					jsonObject.operands[i].defaultValue = args[i].defaultValue;
				} else {
					jsonObject.operands[i].defaultValue = '';
				}
			}
		} else {
			for ( var i=0 ; i<jsonObject.operands.length ; i++ ) {
				jsonObject.operands[i].defaultValue = '';
			}
		}
	} else {
		for ( var i=0 ; i<jsonObject.operands.length ; i++ ) {
			jsonObject.operands[i].defaultValue = '';
		}
	}
}

ClientMethod getOperatorOperandRange(operator) [ Language = javascript ]
{
	var rangeObject = {};
	switch ( operator ) {
		case "!":
			rangeObject.min=1; rangeObject.max=1;
			break;
		case "-":
			rangeObject.min=1; rangeObject.max=2;
			break;
		case "/":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "!=":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "=":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case ">=":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "<=":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case ">":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "<":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "[":
			rangeObject.min=2; rangeObject.max=2;
			break;
		case "+":
			rangeObject.min=1; rangeObject.max=-1;
			break;
		case "*":
			rangeObject.min=2; rangeObject.max=-1;
			break;
		case "&&":
			rangeObject.min=2; rangeObject.max=-1;
			break;
		case "||":
			rangeObject.min=2; rangeObject.max=-1;
			break;
		case "&":
			rangeObject.min=2; rangeObject.max=-1;
			break;
		case "_":
			rangeObject.min=2; rangeObject.max=-1;
			break;
		default:
			rangeObject.min=1; rangeObject.max=-1;
	}
	return rangeObject;
}

ClientMethod getFunctionSelections() [ Language = javascript ]
{
	var functionArray = new Array();
	var functionList = this.getFunctionList();
	for ( f in functionList ) {
		functionArray.push(functionList[f].name);
	}
	return functionArray.join(",");
}

ClientMethod setComboOptions(combo, options, insertBlank, optionsDisplay) [ Language = javascript ]
{
	if ( zenIsIE ) {
		while ( combo.options.length > 0 ) { combo.options.remove(0); }
		if ( insertBlank ) { combo.options.add(new Option("")); }
		var optionsArray = options.split(",")
		if ( !optionsDisplay ) { optionsDisplay = options; }
		var optionsDisplayArray = optionsDisplay.split(",");
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			var opt = new Option(optionsDisplayArray[i],optionsArray[i]);
			combo.options.add(opt);
		}
	} else {
		var optionsArray = options.split(",")
		if ( !optionsDisplay ) { optionsDisplay = options; }
		var optionsDisplayArray = optionsDisplay.split(",");
		var innerHTML = "";
		if ( insertBlank) { innerHTML = "<option></option>"; }
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			innerHTML = innerHTML + "<option value='"+ optionsArray[i] + "'>" + optionsDisplayArray[i] + "</option>"
		}
		combo.innerHTML = innerHTML;
	}
	return;
}

ClientMethod setComboValue(combo, value) [ Language = javascript ]
{
	combo.selectedIndex = -1;
	if ( zenIsIE ) {
		for ( var i=0 ; i<combo.options.length ; i++ ) {
			var currOption = combo.options[i];
			var currValue = (currOption.value != '' ? currOption.value : currOption.text);
			if ( currValue === value.toUpperCase() ) {
				combo.selectedIndex = i;
			}
		}
	} else {
		combo.value = value.toUpperCase();
	}
	return;
}

ClientMethod getSelection(ctrl) [ Language = javascript ]
{
	var selectionObject = {};
	if (document.selection) {
		// IE support
		ctrl.focus ();
		var Sel = document.selection.createRange();
		selectionObject.text = Sel.text;
		Sel.moveStart ('character', -ctrl.value.length);
		selectionObject.end = Sel.text.length;
		selectionObject.start = selectionObject.end - selectionObject.text.length;
	} else if (ctrl.selectionStart || ctrl.selectionStart === '0') {
		// Firefox support
		selectionObject.start = ctrl.selectionStart;
		selectionObject.end = ctrl.selectionEnd;
		selectionObject.text = ctrl.value.substring(selectionObject.start,selectionObject.end);
	}
	return selectionObject;
}

ClientMethod setSelection(ctrl, pos1, pos2) [ Language = javascript ]
{
	if(ctrl.setSelectionRange) {
		ctrl.focus();
		ctrl.setSelectionRange(pos1,pos2);
	} else if (ctrl.createTextRange) {
		var range = ctrl.createTextRange();
		range.collapse(true);
		range.moveEnd('character', pos2);
		range.moveStart('character', pos1);
		range.select();
	}
}

ClientMethod point(x, y) [ Language = javascript ]
{
	this.x=x;
	this.y=y;
}

/// Helper method to get the object tree of defined functions.
ClientMethod getFunctionList() [ Language = javascript ]
{
	return zen('functionList').getContentObject();
}

ClassMethod GetFunctions(ByRef pParameters) As %Status
{
	Set tStatus = ##class(Ens.Rule.Utilities).GetFunctionSet(.tFuncs)
	If $$$ISERR(tStatus) Quit tStatus
	
	Write "{",!
	
	Set tIsFirst = 1
	Set tUpName = ""
	For {
		Set tUpName = $order(tFuncs(tUpName))
		Quit:(tUpName = "")
		Set tClassName = $listget(tFuncs(tUpName), 1)
		Set tFunctionName = $listget(tFuncs(tUpName), 2)
		Set tSpec = $listget(tFuncs(tUpName), 3)
		
		If tIsFirst { Set tIsFirst = 0 }
		Else { Write ",",! }
		Write "'"_tUpName_"': { "
		Write !,"name:'"_tFunctionName_"'"
		Write !,",description:'"_$zconvert($$$comMemberKeyGet(tClassName,$$$cCLASSmethod,tFunctionName,$$$cMETHdescription),"O","JS")_"'"
		Write !,",argSpec: ["
		For i=1:1:$listlength(tSpec) {
			Set tCurrSpec = $listget(tSpec, i)
			If i>1 {
				Write ","
			}
			#Define CurrName	$listget(tCurrSpec, 1)
			#Define CurrType	$listget(tCurrSpec, 2)
			#Define CurrDefVal	$listget(tCurrSpec, 4)
			
			Set tIsLookup = ((tClassName = "Ens.Rule.FunctionSet") || (tClassName = "Ens.Util.FunctionSet")) && ((tFunctionName = "Lookup") || (tFunctionName = "Exists"))
			Set tIsLookup = tIsLookup && ($$$CurrName = "table")
			
			Write "{"
			Write "name:'"_$zconvert($$$CurrName,"O","JS")_"'"
			Write ",defaultValue:'"_$zconvert($$$CurrDefVal,"O","JS")_"'"
			Write ",optional:"_$select(($$$CurrName '= "value") && ($$$CurrDefVal '= "") && 'tIsLookup : "true", 1: "false")
			Write ",isLookup:"_$select(tIsLookup: "true", 1: "false")
			Write "}"
		}
		Write "]",!,"}"
	}
	Write "};",!
	
	Quit $$$OK
}

ClassMethod GetContentObject(ByRef Params, Output pObject As %RegisteredObject) As %Status
{
	set tExpression=%page.EXP
	set tLogicalOnly=$s(%page.MODE'="logical":0,%page.VIEWEXPANDED:0,1:1)
	set tSC=##class(Ens.Rule.Model.expression).parse(tExpression,.pObject,tLogicalOnly) quit:$$$ISERR(tSC) tSC
	quit tSC
}

/// Object submit handler JSON provider.
/// This is called when the client submits the Cube definition.
Method PutContentObject(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	set ..EXP = pSubmitObject.constructExpression()
	quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Expression Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(this.EXP);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	if (this.canEdit && !this.readOnly) {
		this.transferEditorData();
		var json = this.getComponentById('model');
		json.setContentObject(this.moJsonRootObject);
		var ok = json.submitContent('save');
	}
	return true;
}

ClassMethod ServerGetPropertyList(proxy As %ZEN.proxyObject, pBase As %String) As %String [ ZenMethod ]
{
	do proxy.%CopyToArray(.tArray)
	set tAssistClass=$g(tArray("%assistClass"))
	if tAssistClass="" set tAssistClass="Ens.Rule.Assist"
	quit $classmethod(tAssistClass,"GetPropertyList",.tArray,pBase)
}

/// Get a list of lookup tables for use as suggested text when function is EXISTS or LOOKUP
ClassMethod ServerGetTableList() As %String [ ZenMethod ]
{
	Set tTableList = ""
	Set tTable = ""
	For {
		Set tTable = $order(^Ens.LookupTable(tTable))
		Quit:(tTable = "")
		Set tTableList = tTableList _ "," _ $C(34)_tTable_ $C(34)
	}
	Quit $E(tTableList, 2, *)
}

/// Disable components if the user doesn't have permissions to edit the expression.
Method %OnAfterCreatePage() As %Status
{
	If ..readOnly || ('..canEdit) {
		For tControl = "logicalEditor","xyzOK" {
			Set ..%GetComponentById(tControl).disabled = 1
		}
	}
	Quit $$$OK
}

/// Prevent feedback loops in resize logic, primarily on IE8.
ClientMethod adjustSize() [ Language = javascript ]
{
	if (typeof this._adjustSizeCount == 'undefined') this._adjustSizeCount = 0;
	this._adjustSizeCount++;
	if (!this._blockResize) {
		this._blockResize = true;
		this.invokeSuper('adjustSize',arguments);
		
		setTimeout('zenPage._blockResize = false;',30);
	}
}

Method %OnDrawHTMLMeta() As %Status
{
/// Ensure that we force Internet Explorer to use its most recent rendering engine.
/// *** Overriden in this dialog because rendering of the dropdown control had become broken.
	If $$$ZENISIE {
		// Find out IE mode, force edge if IE9 or later
		Set mode = 0
		Try {
			Set ua = %request.UserAgent
			If ua'["Trident/" {
				Set mode = 7 // IE7 or earlier
			}
			Else {
				Set mode = +$P(ua,"MSIE ",2)
			}
		}
		Catch {
		}
		If mode>8 {
			&html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
		}
	}

	Quit $$$OK
}

}
