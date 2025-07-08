/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The colorWheel widget is an interactive color picker that models a 24-bit RGB color 
/// space using cylindrical coordinates.<p/>
/// Visually, this projects as a circle (a cross section of the cylinder when looking down
/// the Z-axis) with the true blue baseline at zero degrees, true red at 120 degrees, and
/// true green at 240 degrees.  A slider beneath the circle determines which cross section 
/// of the color cylinder is shown; at zero the base plane is presented and the very center
/// of the circle (the orgin of the color coordinate system) is black (#000000).  As the 
/// value of the slider increases, equal amounts of red green and blue are added to the 
/// color space until, at the max value, the entire disk is saturated with white (#ffffff) <p/>
/// The value of the widget may be selected by adjusting the white saturation via the slider
/// and clicking on the wheel itself, or by manipulating the RGB contributions directly via 
/// the three sliders provided in the RGB control panel beneath the main color wheel.<p/>
/// The nominal value of the widget is a string of the form "#xxxxxx" where 'x' is a 
/// hexadecimal digit.  The hex values, in order, represent 8 bit contributions of red, green
/// and blue color guns needed to produce the indicated color in HTML documents
Class %ZEN.ComponentEx.colorWheel Extends %ZEN.Component.control [ Deprecated, System = 3 ]
{

/// Default image for close group button.
Parameter INCLUDEFILES = "zenCSLM.js";

Property value As %ZEN.Datatype.value(ZENEXPRESSION = 1) [ InitialExpression = "#7f7f7f" ];

/// Show the three slider panel that allows micromanagement of the RGB color guns
Property showRGBPanel As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Show the preview box at the bottom of the widget that is filled with the currently
/// selected color and stamped with the HTML Hex color specification
Property showPreview As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
.colorSliderWest {
	position:absolute;
	display:block;
	width:4px;
	height:17px;
	bottom:1px;
	left:0px;
	background-image:url(portal/hSliderWestEnd.png);
}

.colorSliderEast {
	position:absolute;
	display:block;
	width:4px;
	height:17px;
	bottom:1px;
	right:0px;
	background-image:url(portal/hSliderEastEnd.png);
}

.colorSliderMiddle {
	position:absolute;
	display:block;
	left:4px;
	right:4px;
	height:17px;
	bottom:1px;
	background-image:url(portal/hSliderTroughEW.png);
	background-repeat:repeat-x;
	width:auto;
}

.colorSliderTrough {
	position:absolute;
	display:block;
	left:0;
	bottom:0;
	height:19px;
	width:100%;
}

.colorSliderValueBox {
	position:absolute;
	display:none;
	overflow:hidden;
	right:0px;
	bottom:0px;
}

.colorSliderHandle {
	position:absolute;
	bottom:0px;
	left:50px;
	background-image:url(portal/slideHandleNorth.png);
	height:17px;
	width:11px;
}

.colorSlider {
	position:relative;
	width:100%;
	height:19px;
}

.colorPickerValueBox {
	position:absolute;
	top:0px;
	left:5px;
	width:35px;
	height:100%;
	text-align:center;
	font-family:monospace;
	border:1px solid #000000;
	border-radius: 3px;
	-moz-border-radius: 3px;
	-webkit-border-radius: 3px;
}

.colorPickerPreviewBox {
	margin-left:5px;
	margin-right:5px;
	font-size:24px;
	text-align:center;
	font-family:monospace;
	font-weight:bold;
	width:249px;
	height:30px;
	background:#ffffff; 
	border:2px solid black;
	border-radius: 4px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
}
</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	&html<
	<div id="#(..%MakeId("diskspace"))#" onclick="this.controller.moveCrosshair(event);"
		style="position:relative;top:0px;left:0px;width:259px;height:259px;">
		<img id="#(..%MakeId("basecolor"))#" src="csp/broker/images/rgbdisk_255.png"  
			style="position:absolute;top:2px;left:2px;width:255px;height:255px;" />
		<img id="#(..%MakeId("whitemask"))#" src="csp/broker/images/whitedisk_255.png" width="257px" height="257px"
			style="position:absolute;top:1px;left:1px;width:257px;height:257px;opacity:0.5;" />
		<img id="#(..%MakeId("crosshair"))#" src="csp/broker/images/crosshair.png" 
			style="position:absolute;top:100px;left:100px;" />
	</div>

	<!-- MaskCtrl -->
		<div id="#(..%MakeId("baseMask"))#" class="colorSlider" style="margin:5px;margin-left:10px;width:249px"> 
			<div id="#(..%MakeId("troughMask"))#" class="colorSliderTrough" >
				<div class="colorSliderWest"></div>
				<div id="#(..%MakeId("troughSpanMask"))#"class="colorSliderMiddle"></div>
				<div class="colorSliderEast"></div>
				<div id="#(..%MakeId("handleMask"))#" class="colorSliderHandle"></div>
			</div>			
		</div>
		
	<div  id="#(..%MakeId("rgbPanel"))#"style="margin-bottom:5px;">

		<div id="#(..%MakeId("redGroup"))#" style="position:relative;top:0px;left:0px;margin:4px;">
			<input id="#(..%MakeId("redGun"))#" class="colorPickerValueBox" style="background:#FF0000;color:#00ffff" onkeydown="this.controller.verifyHex(event,'r');" ></input>
		<div id="#(..%MakeId("baseRed"))#" class="colorSlider" style="margin:5px;margin-left:55px;width:199px"> 
			<div id="#(..%MakeId("troughRed"))#" class="colorSliderTrough" >
				<div class="colorSliderWest"></div>
				<div id="#(..%MakeId("troughSpanRed"))#"class="colorSliderMiddle"></div>
				<div class="colorSliderEast"></div>
				<div id="#(..%MakeId("handleRed"))#" class="colorSliderHandle"></div>
			</div>			
		</div>

		</div>
		<div id="#(..%MakeId("greenGroup"))#" style="position:relative;top:0px;left:0px;margin:4px;">
			<input id="#(..%MakeId("greenGun"))#" class="colorPickerValueBox" style="background:#00FF00;color:#ff00ff;" onkeydown="this.controller.verifyHex(event,'g');"></input>
		<div id="#(..%MakeId("baseGreen"))#" class="colorSlider" style="margin:5px;margin-left:55px;width:199px"> 
			<div id="#(..%MakeId("troughGreen"))#" class="colorSliderTrough" >
				<div class="colorSliderWest"></div>
				<div id="#(..%MakeId("troughSpanGreen"))#"class="colorSliderMiddle"></div>
				<div class="colorSliderEast"></div>
				<div id="#(..%MakeId("handleGreen"))#" class="colorSliderHandle"></div>
			</div>			
		</div>

		</div>
		<div id="#(..%MakeId("blueGroup"))#" style="position:relative;top:0px;left:0px;margin:4px;">
			<input id="#(..%MakeId("blueGun"))#" class="colorPickerValueBox" style="background:#0000FF;color:#ffff00" onkeydown="this.controller.verifyHex(event,'b');"></input>
		<div id="#(..%MakeId("baseBlue"))#" class="colorSlider" style="margin:5px;margin-left:55px;width:199px"> 
			<div id="#(..%MakeId("troughBlue"))#" class="colorSliderTrough" >
				<div class="colorSliderWest"></div>
				<div id="#(..%MakeId("troughSpanBlue"))#"class="colorSliderMiddle"></div>
				<div class="colorSliderEast"></div>
				<div id="#(..%MakeId("handleBlue"))#" class="colorSliderHandle"></div>
			</div>			
		</div>

		</div>
	</div>

		<!-- preview box -->
		<input type="text" id="#(..%MakeId("value"))#" class="colorPickerPreviewBox" onchange="this.controller.cleanUpMainUserEntry();"/>

	>
}

/// Build an internal map of oointers to key DOM nodes to speed 
/// processing during drag operations.
ClientMethod findParts() [ Language = javascript ]
{
	this.diskspace = this.findElement("diskspace");
	this.diskspace.controller = this;
	this.rgbPanel = this.findElement("rgbPanel");
	this.redCtrl = this.findElement("redCtrl");
	this.greenCtrl = this.findElement("greenCtrl");
	this.blueCtrl = this.findElement("blueCtrl");
	this.crosshair = this.findElement("crosshair");
	this.valueBox = this.findElement("value");
	this.valueBox.controller = this;
	this.whitemask = this.findElement("whitemask");
	this.redGun = this.findElement("redGun");
	this.redGun.controller = this;
	this.greenGun = this.findElement("greenGun");
	this.greenGun.controller = this;
	this.blueGun = this.findElement("blueGun");
	this.blueGun.controller = this;

	this.maskCtrl = {};
	this.maskCtrl.value = 50;
	this.maskCtrl.maxValue = 100;
	this.maskCtrl.range = 100;
	this.maskCtrl.base = this.findElement("baseMask");
	this.maskCtrl.handle = this.findElement("handleMask");
	this.maskCtrl.trough = this.findElement("troughMask");
	this.maskCtrl.handle.controller = this;
	this.maskCtrl.handle.jsObjName = "maskCtrl";
	this.maskCtrl.base.controller = this;
	this.maskCtrl.trough.controller = this;
	this.maskCtrl.onchange = "this.updateMask();"

	this.redCtrl = {};
	this.redCtrl.value = 128;
	this.redCtrl.maxValue = 255;
	this.redCtrl.range = 255;
	this.redCtrl.base = this.findElement("baseRed");
	this.redCtrl.handle = this.findElement("handleRed");
	this.redCtrl.trough = this.findElement("troughRed");
	this.redCtrl.handle.controller = this;
	this.redCtrl.handle.jsObjName = "redCtrl";
	this.redCtrl.base.controller = this;
	this.redCtrl.trough.controller = this;
	this.redCtrl.onchange = "this.mixGuns();"

	this.greenCtrl = {};
	this.greenCtrl.value = 128;
	this.greenCtrl.maxValue = 255;
	this.greenCtrl.range = 255;
	this.greenCtrl.base = this.findElement("baseGreen");
	this.greenCtrl.handle = this.findElement("handleGreen");
	this.greenCtrl.trough = this.findElement("troughGreen");
	this.greenCtrl.handle.controller = this;
	this.greenCtrl.handle.jsObjName = "greenCtrl";
	this.greenCtrl.base.controller = this;
	this.greenCtrl.trough.controller = this;
	this.greenCtrl.onchange = "this.mixGuns();"

	this.blueCtrl = {};
	this.blueCtrl.value = 128;
	this.blueCtrl.maxValue = 255;
	this.blueCtrl.range = 255;
	this.blueCtrl.base = this.findElement("baseBlue");
	this.blueCtrl.handle = this.findElement("handleBlue");
	this.blueCtrl.trough = this.findElement("troughBlue");
	this.blueCtrl.handle.controller = this;
	this.blueCtrl.handle.jsObjName = "blueCtrl";
	this.blueCtrl.base.controller = this;
	this.blueCtrl.trough.controller = this;
	this.blueCtrl.onchange = "this.mixGuns();"
}

/// Perform client-side initialization of elements that have no server side projection
ClientMethod initializeDOM() [ Language = javascript ]
{
	this.findParts();
	this.cX = 127;
	this.cY = 127;
	this.maxR = 128;
	this.r = 0;
	this.theta = 0;
	this.z = 0;

	ZLM.registerDragItem(this.maskCtrl.handle,this);
	ZLM.setLocalAttribute(this.maskCtrl.handle,"onmousedown","ZLM.drag(this,event);");
	ZLM.setLocalAttribute(this.maskCtrl.handle,"ontouchstart","ZLM.touch(this,event);");
	this.positionHandle(this.maskCtrl);

	ZLM.registerDragItem(this.redCtrl.handle,this);
	ZLM.setLocalAttribute(this.redCtrl.handle,"onmousedown","ZLM.drag(this,event);");
	ZLM.setLocalAttribute(this.redCtrl.handle,"ontouchstart","ZLM.touch(this,event);");
	this.positionHandle(this.redCtrl);
	
	ZLM.registerDragItem(this.greenCtrl.handle,this);
	ZLM.setLocalAttribute(this.greenCtrl.handle,"onmousedown","ZLM.drag(this,event);");
	ZLM.setLocalAttribute(this.greenCtrl.handle,"ontouchstart","ZLM.touch(this,event);");
	this.positionHandle(this.greenCtrl);
	
	ZLM.registerDragItem(this.blueCtrl.handle,this);
	ZLM.setLocalAttribute(this.blueCtrl.handle,"onmousedown","ZLM.drag(this,event);");
	ZLM.setLocalAttribute(this.blueCtrl.handle,"ontouchstart","ZLM.touch(this,event);");
	this.positionHandle(this.blueCtrl);

	this.setValueHex(this.value);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.initializeDOM();
}

ClientMethod onRefreshContents() [ Language = javascript ]
{
	this.initializeDOM();
}

/// Initialize drag operations for the embedded sliders
ClientMethod startDrag(mgr, wrapper) [ Language = javascript ]
{
	var who=this[wrapper.node.jsObjName];
	
	who.maxSlide=who.trough.clientWidth-who.handle.offsetWidth;
	who.slotSize=who.maxSlide/who.range;
	who.roundOff=who.slotSize/2;
	who.roundOff=0;
}

/// Force drag operations in embedded sliders to be purely horizontal
ClientMethod constrainDragY(mgr, wrapper, newY) [ Language = javascript ]
{
	return(2);
}

/// Prorate slider values based on slider activity.
ClientMethod constrainDragX(mgr, wrapper, newX) [ Language = javascript ]
{
	var who=this[wrapper.node.jsObjName];

	if (newX<0) return(0);
	var mx=who.trough.clientWidth-who.handle.offsetWidth;
	if (newX>mx) return(mx);
	var newV=(who.handle.offsetLeft+who.roundOff)/who.slotSize;
	if (newV!=who.value) {
		who.value=newV;
		if (who.onchange) eval(who.onchange);
	}
	return(newX);
}

/// Wrap up drag activity on embedded sliders
ClientMethod endDrag(mgr, wrapper) [ Language = javascript ]
{
	var who=this[wrapper.node.jsObjName];

	var newV=(who.handle.offsetLeft+who.roundOff)/who.slotSize;
	if (newV!=who.value) {
		who.value=newV;
		if (who.onchange) eval(who.onchange);
	}
}

/// Ensure that the handle of embedded sliders accurately reflects the internal value thereof.
ClientMethod positionHandle(who) [ Language = javascript ]
{
	var tW = who.trough.clientWidth;
	var hW = who.handle.offsetWidth;
	if (tW==0) { // slider not currently visible do it the hard way
		tW = parseInt(ZLM.getComputedNodeStyle(who.trough,'width'),10);
		hW = parseInt(ZLM.getComputedNodeStyle(who.handle,'width'),10);
	}
	var mx = tW - hW;
	var slot=mx/who.range;
	who.handle.style.left=Math.round(who.value*slot)+"px";
}

/// Initialized or reset the internal value associated with a slider and update its
/// avatar accordingly.
ClientMethod setSliderValue(who, value) [ Language = javascript ]
{
	if (value==null) who.value=0;
	else {
		if (typeof(value)=="string") who.value=parseFloat(value);
		else who.value=value;
		if (who.value<0) who.value=0;
		if (who.value>who.maxValue) who.value=who.maxValue;
	}
	this.positionHandle(who);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		this.value = "#000000"
		var r = 0;
		var g = 0;
		var b = 0;
		if (value) {
			var rgbStr = ZLM.convertColorToRGB(value);
			if (rgbStr) {
				var rgb =rgbStr.split(",");
				r = rgb[0];
				g = rgb[1];
				b = rgb[2];
			}
		}
		this.setValueRGB(r,g,b);
		break;
	case 'showRGBPanel':
		this.showRGBPanel = value;
		this.updateVisibleAreas();
		break;
	case 'showPreview':
		this.showPreview = value;
		this.updateVisibleAreas();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Limit the input of hex boxes to hex digits
ClientMethod verifyHex(event, gun) [ Language = javascript ]
{
	  var code = event.keyCode;
	  var charVal = String.fromCharCode(code);
	  var pending = setTimeout("zenPage.getComponentById('"+this.id+"').cleanUpUserEntry();",0);
	  if (event.ctrlKey == true) return;
	  if (code<32) return;
	  var value = ZLM.parseHexDigit(charVal); 
	  if (value!="BAD DIGIT") {  // test to see if total string in control is valid
	    var ctrl = null;
	    if (gun == 'r') ctrl = this.redGun;
	    if (gun == 'g') ctrl = this.greenGun;
	    if (gun == 'b') ctrl = this.blueGun;
	    var inValue = ctrl.value;
	    if (ctrl!=null) { // interested in keeping things in the 00-ff range
		
			var isSelected = false;
  			if (typeof ctrl.selectionStart == "number") {
       			isSelected = (ctrl.selectionStart == 0 && ctrl.selectionEnd == ctrl.value.length);
   			} 
   			else if (typeof document.selection != "undefined") {
        		ctrl.focus();
        		isSelected = (document.selection.createRange().text == ctrl.value);
   			}
   			if (isSelected) inValue="00";
			var len = inValue.length;
			if (len<2 || inValue.charAt(0)=="0") {
				return;
			};
	    };
	  };
	  clearTimeout(pending);
	  return(ZLM.killEvent(event));
}

/// User entered values for color guns should always be exactly two hex digits
/// Sanitize and truncate as needed.
ClientMethod cleanUpUserColorGunEntry(gun) [ Language = javascript ]
{
	var v = gun.value;
	var len = v.length;
	if (len==2) return;
	v = v.replace(/^[0]+/g,"")
	len = v.length;
	switch (len) {
		case 2: gun.value = v;
				return;
		case 1: gun.value = "0"+v;
				return;
		case 0: gun.value = "00";
				return;
		default: // must be more than two
			gun.value = v.substring(0,1);
	}
}

/// In the event that the user has entered specific hex values, verify that
/// all of the inputs, previews and controls are in sync with the latest data 
/// and that that data represents a valid Web color spec 
ClientMethod cleanUpUserEntry() [ Language = javascript ]
{
	var r = this.redGun;
	this.cleanUpUserColorGunEntry(r);
	var g = this.greenGun;
	this.cleanUpUserColorGunEntry(g);
	var b = this.blueGun;
	this.cleanUpUserColorGunEntry(b);
	
	this.value = "#"+r.value+g.value+b.value;
	this.setValueHex(this.value);
}

/// In the event that the user has entered specific hex color value in the
/// main value box, verify that
/// all of the inputs, previews and controls are in sync with the latest data 
/// and that that data represents a valid Web color spec 
ClientMethod cleanUpMainUserEntry() [ Language = javascript ]
{
	var val = this.valueBox.value;
	val = val.split(' ').join("");
	if (val.charAt(0)=='#') val = val.substring(1)
	if (val.length!=6) { // must be six hex digits or abort edit
		this.setProperty("value",this.value);
		return
	}
	var digits = [];
	for (var i=0;i<6;i++) {
		var c = val.substring(i,i+1);
		if (ZLM.parseHexDigit(c)=="BAD DIGIT") {
			this.setProperty("value",this.value);
			return
		}
		digits.push(c);
	}
	val = "#"+digits.join("");
	this.setProperty("value",val);
}

/// Position the crosshair on the color wheel in response to a user action
ClientMethod moveCrosshair(e) [ Language = javascript ]
{
	var x = 0;
	var y = 0;
	if (e.offsetX || e.offsetY) {
		x = e.offsetX;
		y = e.offsetY;
	}
	else {	
		var ofsX = ZLM.getPageOffsetLeft(this.diskspace);
		var ofsY = ZLM.getPageOffsetTop(this.diskspace);
		x = e.pageX-ofsX;
		y = e.pageY- ofsY;
	}
	
	var r = this.getRadius(x,y);
	if (r>this.cX) r = this.cX;
	var theta = this.getAngle(x,y);
	var z = parseInt(this.maskCtrl.value)/100;
	
	this.r = r;
	this.theta = theta;
	this.z = z;

	this.positionCrosshair(r,theta);
	this.updatePreview(r,theta,z);
}

/// Reset the value of the widget based on user interaction with the RGB sliders
ClientMethod mixGuns() [ Language = javascript ]
{
	this.setValueRGB(
		parseInt(this.redCtrl.value),
		parseInt(this.greenCtrl.value),
		parseInt(this.blueCtrl.value));
}

/// Position the crosshair indicator based on the latest Rho, Theta values in the 
/// color space.
ClientMethod positionCrosshair(r, theta) [ Language = javascript ]
{
	var pip = this.crosshair;
	pip.style.top=(this.getY(r,theta)-10)+"px";
	pip.style.left=(this.getX(r,theta)-10)+"px";
}

/// Update the rendering of the widget to reflect the current value
ClientMethod updatePreview(r, theta, z) [ Language = javascript ]
{
	var clrStr = this.getShade(r,theta,z);
	var div = this.valueBox;
	div.style.background=clrStr;
	div.innerHTML = clrStr;
	div.value = clrStr;
	if (ZLM.isDarkRGB(this.red+","+this.green+","+this.blue)) div.style.color="#ffffff";
	else div.style.color="#000000";

	this.setSliderValue(this.redCtrl,this.red);
	this.setSliderValue(this.greenCtrl,this.green);
	this.setSliderValue(this.blueCtrl,this.blue);
	this.setSliderValue(this.maskCtrl,this.z*100);
	
	this.redGun.value = ZLM.toHexString(this.red,2);
	this.greenGun.value = ZLM.toHexString(this.green,2);
	this.blueGun.value = ZLM.toHexString(this.blue,2);

	this.whitemask.style.opacity= this.z;
	if (ZLM.isIE) {
		this.whitemask.style.filter = "alpha(opacity=" + (this.z*100) + ")";
	}	
	this.value = clrStr;
	if (this.onchange) zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

/// Adjust the white saturation of the color wheel based on the current settings
/// of the slider control
ClientMethod updateMask() [ Language = javascript ]
{
	var ctrl = this.maskCtrl;
	var percent = parseInt(this.maskCtrl.value)/100;
	this.z = percent;
	this.updatePreview(this.r, this.theta, percent);
}

/// Hide or show optional parts of the widget
ClientMethod updateVisibleAreas() [ Language = javascript ]
{
	if (this.showRGBPanel==1 || this.showRGBPanel=="true" || this.showRGBPanel==true) {
		this.rgbPanel.style.display="block";
	}
	else {
		this.rgbPanel.style.display="none";
	}
	if (this.showPreview==1||this.showPreview=="true" || this.showPreview==true) {
		this.valueBox.style.display="block";
	}
	else {
		this.valueBox.style.display="none";
	}
}

/// Given an HTML color specification in Hex notation, break it up into explicit RGB values
/// and call setValueRGB to update the value and appearance of this widget. 
ClientMethod setValueHex(hexStr) [ Language = javascript ]
{
	var rgbStr = ZLM.convertHexColorString(hexStr);
	var rgb =rgbStr.split(",");
	this.setValueRGB(rgb[0],rgb[1],rgb[2]);
}

/// Given discrete RGB color gun settings, update the value and appearance of this widget. 
ClientMethod setValueRGB(r, g, b) [ Language = javascript ]
{
	this.red = r;
	this.green = g;
	this.blue = b;
	var min = Math.min(r,g);
	min = Math.min(min,b);
	
	var z = min/255;
	var zf = z*255;
	var mz = 1-z;
	var rho = 0;
	var theta = 0;
	
	if (z==1) {
		r=0;
		g=0;
		b=0;
	}
	else {
		r = (r-zf)/mz;
		g = (g-zf)/mz;
		b = (b-zf)/mz;
	}	
	if (r==0) {
		if (g>b) {
			rho = Math.round(g/255*this.cX);
			theta = Math.round(240+60*b/g)
		}
		else { // b>=g
			rho = Math.round(b/255*this.cX);
			if (b==0) theta=0;
			else theta = Math.round(360-60*g/b);
		}
	}
	else if (g==0) {
		if (r>b) {
			rho = Math.round(r/255*this.cX);
			theta = Math.round(120-60*b/r);
		}
		else { // b>=r
			rho = Math.round(b/255*this.cX);
			if (b==0) theta = 0;
			else theta = Math.round(60*r/b);
		}
	}
	else { //b==0
		if (r>g) {			
			rho = Math.round(r/255*this.cX);
			theta = Math.round(120+60*g/r);
		}
		else { // g>=r
			rho = Math.round(g/255*this.cX);
			if (g==0) theta = 0;
			else theta = Math.round(240-60*r/g);
		}
	}
	
	this.r = rho;
	this.theta = theta;
	this.z = z;
	
	this.positionCrosshair(rho,theta);
	this.updatePreview(rho,theta,z);
}

/// Convert polar color coordinates to X pixel value
ClientMethod getX(r, theta) [ Language = javascript ]
{
	return(Math.round(r*Math.cos(theta*Math.PI/180))+this.cX);
}

/// Convert polar color coordinates to Y pixel value
ClientMethod getY(r, theta) [ Language = javascript ]
{
	return(this.cY-Math.round(r*Math.sin(theta*Math.PI/180)));
}

/// Given an XY location on the rendering of the color wheel 
/// calculate the Rho value of the color space
ClientMethod getRadius(x, y) [ Language = javascript ]
{
	var deltaX = x-this.cX;
	var deltaY = y-this.cY;
	var r = Math.sqrt(deltaX*deltaX+deltaY*deltaY);
	return(r);
}

/// Given the XY location on the rendering of the color wheel
/// calculate the Theta (in degrees) value of the color space
ClientMethod getAngle(x, y) [ Language = javascript ]
{
	var lx = x-this.cX;
	var ly = this.cY - y;
	if (lx==0) {
		if (ly>0) return(90);
		return(270);
	}
	if (ly==0) {
		if (lx>0) return(0);
		return(180);
	}
	var theta = Math.atan(ly/lx)*180/Math.PI;

	if (lx < 0 ) { 
		theta = 180 + theta;
	}
	else if (ly<0) { // native negative
		theta = 360 + theta;
	}
	return(theta);
}

/// Given Rho, Theta values in the color space, calculate the associate Blue
/// color gun contribution
ClientMethod getShadeBlue(r, theta) [ Language = javascript ]
{
	var base = 0;
	if (r<this.maxR) {
		if (theta>180) { 
			theta = 360-theta;
		}
		if (theta<0) theta = 180+theta;

		if (theta>=120) return(0);

		if (theta<=60) base = 255;
		else {
			base = ((120-theta)/60)*255;
		}
		var grad = Math.min(base*r/this.cX,255)
		return(Math.round(grad));
	}
	else return(255);
}

/// Given Rho, Theta values in the color space, calculate the associate Red
/// color gun contribution
ClientMethod getShadeRed(r, theta) [ Language = javascript ]
{
	if (r>=this.maxR) return(255);
	theta = theta-120;
	if (theta<0) theta += 360;
	return(this.getShadeBlue(r,theta));
}

/// Given Rho, Theta values in the color space, calculate the associate Green
/// color gun contribution
ClientMethod getShadeGreen(r, theta) [ Language = javascript ]
{
	if (r>=this.maxR) return(255);
	theta = theta-240;
	if (theta<0) theta += 360;
	return(this.getShadeBlue(r,theta));
}

/// Given a point in the abstract color space (rho, theta, zed), calculate the
/// resulting color and return its HTML hex color specification.
ClientMethod getShade(r, theta, z) [ Language = javascript ]
{
	var wash = 255*z;
	var blue = Math.min(Math.round(this.getShadeBlue(r,theta)*(1-z)+wash,255));
	var red = Math.min(Math.round(this.getShadeRed(r,theta)*(1-z)+wash),255);
	var green = Math.min(Math.round(this.getShadeGreen(r,theta)*(1-z)+wash),255);
	this.red = red;
	this.green = green;
	this.blue = blue;
	var rgbStr = "rgb("+red+","+green+","+blue+")";
	return(ZLM.toHTMLColorSpec(rgbStr));
}

}
