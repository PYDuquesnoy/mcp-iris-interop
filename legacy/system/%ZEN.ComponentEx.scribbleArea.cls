/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Free pen input control.<br>
/// This input control is intended for capturing free pen gestures such as signatures and "initial here" marks
Class %ZEN.ComponentEx.scribbleArea Extends %ZEN.Component.control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "text";

Parameter INCLUDEFILES = "zenCSLM.js";

Property controlClass As %ZEN.Datatype.cssClass [ InitialExpression = "scribbleArea" ];

/// The level of post processing smoothing to apply to the input curve.  A setting of
/// zero indicate no smoothing. Smoothing is achieved by applying weighted averages to the 
/// sampled data points in an effort to reduce jitter resulting from certain input devices.
/// When set to a small value (1 or 2) this can help curves entered with a bulky device (such 
/// as an optical mouse) more closely approximate those of a more precise input device (such 
/// as a tablet).  This is, however, only an approximation and the original data is lost in 
/// the conversion.
Property smoothness As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// The level of post processing culling to apply to the input curve.  A setting of zero indicates
/// that all non-colinear data points should be retained.  Higher values allow the system to cull 
/// additional points based on how much information they actually contain (information in this case 
/// being a function of change in slope of the curve at the given point)  Raising the culling level
/// reduces the memory requirements for the control's value but does so at the risk of exaggerating
/// cusps and jitter.
Property culling As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// The thickness of the virtual pen point. The higher the nib number the bolder the input curve
/// will appear.
Property nib As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for text (input)." */
.scribbleArea {
	width:800px;
	height:200px;
	overflow:hidden;
	border:1px solid gray;
	background:#eeeeee;
	color:#000044;
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled=""1""",1:"")
	Set ro = $S(..readOnly:"readonly=""1""",1:"")

	&html<<div class="#(..controlClass)#" #(..%Attr("title",..title))#  #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers())#/>
	<input type="text" id="#(..%MakeId("control"))#" style="display:none;" />
	</div>>
}

ClientMethod supportsCanvasAPI() [ Language = javascript ]
{
  var canvas = document.createElement('canvas');
  if (!canvas) return (false);
  return ('getContext' in canvas);
}

ClientMethod initialize() [ Language = javascript ]
{
	this.sig = [];
	this.touchBaseX = "unset";
	this.touchBaseY = "unset";
	this.touchStroke = "m";
	
	var e = this.getEnclosingDiv();
	var d = null;
	for (var n=e.firstChild;n!=null;n=n.nextSibling) {
		if (n.className && n.className==this.controlClass) {
			d = n;
			n = e.lastChild;
		}
	}
	if (!d) d = e;
	this.extractInkColor(d);
	ZLM.setLocalAttribute(d,"onmousedown","zenPage.getComponent("+this.index+").track(this,event);");

ZLM.setLocalAttribute(d,"ontouchstart","zenPage.getComponent("+this.index+").touchStart(this,event);");
ZLM.setLocalAttribute(d,"ontouchmove","zenPage.getComponent("+this.index+").touchMove(this,event);");
ZLM.setLocalAttribute(d,"ontouchend","zenPage.getComponent("+this.index+").touchEnd(this,event);");

	var w = d.clientWidth;
	var h = d.clientHeight;
	this.canvasWidth = w;
	this.canvasHeight = h;
	this.sig.push({connect:'z',x:this.canvasWidth,y:this.canvasHeight});
	this.setValue("z "+this.canvasWidth+" "+this.canvasHeight);
	var cvs = null;
	if (!this.supportsCanvasAPI() && document.namespaces) {
		this.renderMode = "VML";

		if(!document.documentMode || document.documentMode<8) { 
			document.namespaces.add("v","urn:schemas-microsoft-com:vml");
	 		document.createStyleSheet().addRule('v\\:*', "behavior: url(#default#VML);"); 
		} 

		if(document.documentMode && document.documentMode>=8) { 
			document.writeln('<?import namespace="v" implementation="#default#VML" ?>'); 
		}

		cvs = document.createElement("v:group");
		cvs.style.width = w+"px";
		cvs.style.height = h+"px";
		cvs.setAttribute("coordsize",w+" "+h);
		d.appendChild(cvs);
	}
	else {
		this.renderMode = "CVS";
		cvs = document.createElement("canvas");
		cvs.width = w;
		cvs.height = h;
		var g = cvs.getContext("2d");
		d.appendChild(cvs);
		this.canvasContext = g;
	}
	this.canvas = cvs;
}

ClientMethod extractInkColor(div) [ Language = javascript ]
{
	this.inkColor = "#000000";
	if (div.currentStyle) {
		this.inkColor = div.currentStyle.color;
	}
	else if (window.getComputedStyle) {
		this.inkColor = window.getComputedStyle(div,null).color;
	}
}

ClientMethod clearCanvas() [ Language = javascript ]
{
	if (this.renderMode == "CVS" ) {
		var g = this.canvasContext;
		g.clearRect(0,0,this.canvasWidth,this.canvasHeight);
	}
	else if (this.renderMode == "VML") {
		var q = null;
		for (var p=this.canvas.firstChild; p!=null; p=q) {
			q = p.nextSibling;
			this.canvas.removeChild(p);
		}
	}
}

ClientMethod clear() [ Language = javascript ]
{
	this.sig=[];
	this.sig.push({connect:'z',x:this.canvasWidth,y:this.canvasHeight});
	this.setValue("z "+this.canvasWidth+" "+this.canvasHeight);
	this.clearCanvas();
}

ClientMethod showSource() [ Language = javascript ]
{
	var str = this.exportAsPath(this.sig,1,1);
	alert(str);
}

ClientMethod smoothSignature(s) [ Language = javascript ]
{
	var l=[];
	var sIdx = 0;
	if (s.length>0 && s[0].connect=="z") {
		l.push({connect:"z",x:s[0].x,y:s[0].y});
		sIdx++;
	}
	var x = 0;
	var y = 0;
	for (var n=sIdx;n<s.length-1;n++) {
		if (s[n].connect=="m" || s[n+1].connect=="m") {
			l.push({connect:s[n].connect,x:s[n].x,y:s[n].y});
		}
		else if (s[n].connect=="l" ){
			var dx = Math.abs(s[n].x-s[n-1].x);
			var dy = Math.abs(s[n].y-s[n-1].y);
			if (dx>10 || dy>10) {
				// too big a gap, probably intentional
				l.push({connect:s[n].connect,x:s[n].x,y:s[n].y});
			}
			else {	
				x = Math.round(s[n-1].x/4 + s[n].x/2 + s[n+1].x/4);
				y = Math.round(s[n-1].y/4 + s[n].y/2 + s[n+1].y/4);		
				l.push({connect:"l",x:x,y:y});
			}
		}
	}
	
	if (s[n]) {
		l.push({connect:s[n].connect,x:s[n].x,y:s[n].y});
	}
	return(l);
}

ClientMethod trimSignature(s, cull) [ Language = javascript ]
{
	var clip = 1-cull*0.005
	var max = s.length;
	for (var n=0;n<max;n++) {
		s[n].keep = true;
		if (n==max-1 || s[n].connect=="m" || s[n+1].connect=="m" || s[n].connect=="z") {
			s[n].keep = true;
		}
		else if (n>0) {
			var x0 = s[n-1].x;
			var y0 = s[n-1].y;
			var x1 = s[n].x;
			var y1 = s[n].y;
			var x2 = s[n+1].x;
			var y2 = s[n+1].y;
			if (y0==y1 && y0==y2) s[n].keep=false;
			else if (x0==x1 && x0==x2) s[n].keep=false;
			else {
				var dx10 = x1-x0;
				var dy10 = y1-y0;
				var dx20 = x2-x0;
				var dy20 = y2-y0;				
				if (Math.abs(dx10*dy20-dx20*dy10)<cull) s[n].keep=false;
				else if (cull>0) {
					var cosTh = ((dx10*dx20+dy10*dy20)/Math.sqrt((dx10*dx10+dy10*dy10)*(dx20*dx20+dy20*dy20)));
					if (cosTh>clip) s[n].keep=false;
				}
			}
		}
	}
	var l=[];
	for (var n=0;n<max;n++) {
		if (s[n].keep==true) {
			l.push({connect:s[n].connect,x:s[n].x,y:s[n].y});
		}
	}
	return(l);
}

/// Render the given curve using HTML 5 canvas tag methods
ClientMethod renderSignatureCVS(s) [ Language = javascript ]
{
	var g = this.canvasContext;
	g.strokeStyle = this.inkColor;
	g.lineWidth = this.nib;
	var active = false;
	for (var i=0; i<s.length; i++) {
		var o=s[i];
		if (o.connect=="m") {
			if (active) g.stroke();
			g.beginPath();
			g.moveTo(o.x,o.y);		
			active = true;
		}
		if (o.connect=="l") {
			g.lineTo(o.x,o.y);
		}
	}		
	if (active) g.stroke();
}

/// Render the given curve using IE's VML technology
ClientMethod renderSignatureVML(s) [ Language = javascript ]
{
	var sx = 0;
	var sy = 0;
	for (var i=0; i<s.length; i++) {
		var o=s[i];
		if (o.connect=="m") {
			sx = o.x;
			sy = o.y;
		}
		if (o.connect=="l") {
			var l = document.createElement("v:line");
			l.setAttribute("from",sx+" "+sy);
			l.setAttribute("to",o.x+" "+o.y);
			l.setAttribute("strokecolor",this.inkColor);
			l.setAttribute("strokeweight",this.nib);
			this.canvas.appendChild(l);
			sx = o.x;
			sy = o.y;
		}
	}
}

/// Render the given curve, s, in the drawing area
ClientMethod renderSignature(s, smoothingLevel, compressionLevel) [ Language = javascript ]
{
	if (!smoothingLevel) smoothingLevel = 0;
	if (!compressionLevel) compressionLevel = 0;
	for (var i=0;i<smoothingLevel;i++) {
		var s = this.trimSignature(s,0);
		s = this.smoothSignature(s);
	}
	this.updateControlValue();
	s = this.trimSignature(s,compressionLevel);
	if (this.renderMode == "CVS") this.renderSignatureCVS(s);
	else if (this.renderMode == "VML") this.renderSignatureVML(s);
}

/// Return the structure of the given curve, s, as a JSON object
ClientMethod exportSignature(s, smoothingLevel, compressionLevel) [ Language = javascript ]
{
	if (!smoothingLevel) smoothingLevel = 0;
	if (!compressionLevel) compressionLevel = 0;
	for (var i=0;i<smoothingLevel;i++) {
		var s = this.trimSignature(s,0);
		s = this.smoothSignature(s);
	}
	s = this.trimSignature(s,compressionLevel);
	var o = [];
	o.push('[');
	for (var n = 0;n<s.length;n++) {
		var pt = s[n];
		if (n>0) o.push(",");
		o.push('{"s":"'+pt.connect+'","x":'+pt.x+',"y":'+pt.y+'}');
	}
	o.push(']');
	var l = o.join('');
	return(l);
}

/// Return the structure of the given curve, s, as a turtle graphics-ish path string where
/// data points take the form of penCommand x y.  The penCommand is either moveTo (m)
/// or lineTo (l). The x value is measured with respect to the left-most side of the 
/// control's bounds and increases to the right.  The y value is measured with respect 
/// to the top edge of the control and increases down the screen.  This format is also
/// used as the nominal value of the control.
ClientMethod exportAsPath(s, smoothingLevel, compressionLevel, showSize) [ Language = javascript ]
{
	if (!smoothingLevel) smoothingLevel = 0;
	if (!compressionLevel) compressionLevel = 0;
	for (var i=0;i<smoothingLevel;i++) {
		var s = this.trimSignature(s,0);
		s = this.smoothSignature(s);
	}
	s = this.trimSignature(s,compressionLevel);
	var o = [];
	for (var n = 0;n<s.length;n++) {
		var pt = s[n];
		var c = pt.connect;
		if (c=='m' || c=='l' || (c=='z' && showSize)) {
			if (n>0) o.push(",");
			o.push(pt.connect+" "+pt.x+" "+pt.y);
		}
	}
	var l = o.join("");
	return(l);
}

/// Add a line segment to the drawing area
ClientMethod addLine(sx, sy, ex, ey) [ Language = javascript ]
{
	if (this.renderMode == "CVS") {
		var g = this.canvasContext;
		g.lineWidth = this.nib;
		g.beginPath();
		g.moveTo(sx,sy);
		g.lineTo(ex,ey);
		g.stroke();
	}
	else if (this.renderMode == "VML") {
		var l = document.createElement("v:line");
		l.setAttribute("from",sx+" "+sy);
		l.setAttribute("to",ex+" "+ey);
		l.setAttribute("strokecolor",this.inkColor);
		l.setAttribute("strokeweight",this.nib);
		this.canvas.appendChild(l);
	}
}

/// Start or extend a given stroke for the current curve
ClientMethod addStroke(c, x, y) [ Language = javascript ]
{
	if (this.sig.length>0 && this.sig[0].connect=="b") this.sig.pop();
	if (c=="m") {
		this.sig.push({connect:c, x:x, y:y});
	}
	else {
		var s = this.sig.pop();
		this.sig.push(s);
		this.sig.push({connect:c, x:x, y:y});
		setTimeout("zenPage.getComponent("+this.index+").addLine("+s.x+","+s.y+","+x+","+y+");",0);
	}
}

/// Track pointer gestures and generate curve data
ClientMethod track(who, event) [ Language = javascript ]
{
	if (navigator.userAgent.indexOf("Mobile")>0) return;
	var baseX = ZLM.getPageOffsetLeft(who)-zenGetPageScrollLeft();
	var baseY = ZLM.getPageOffsetTop(who)-zenGetPageScrollTop();
	var obj = this;
	
	if (document.addEventListener) { // real browsers
		document.addEventListener("mouseup",upHandler,true);
		document.addEventListener("mousemove",moveHandler,true);
	}
	else if (document.attachEvent) { // IE 5+
		who.setCapture();
		who.attachEvent("onmousemove",moveHandler);
		who.attachEvent("onmouseup",upHandler);
		who.attachEvent("onlosecapture",upHandler);
	}

	var lastX = event.clientX-baseX;
	var lastY = event.clientY-baseY;
	var stroke = "m";

	function moveHandler(e) {
		if (!e) e = window.event; // IE
		var x = e.clientX-baseX;
		var y = e.clientY-baseY;
		if ((stroke=="m") || (Math.abs(lastX-x)+Math.abs(lastY-y)>2)) {
			lastX = x;
			lastY = y;
			obj.addStroke(stroke,x,y);
			stroke = "l";
		}
		ZLM.killEvent(e);
	}

	function upHandler(e) {
		if (!e) e = window.event; // IE
		if (document.removeEventListener) { // real browsers
			document.removeEventListener("mouseup",upHandler,true);
			document.removeEventListener("mousemove",moveHandler,true);
		}
		else if (document.detachEvent) { // IE 5+
			who.detachEvent("onlosecapture",upHandler);
			who.detachEvent("onmouseup",upHandler);
			who.detachEvent("onmousemove",moveHandler);
			who.releaseCapture();
		}
		obj.clearCanvas();
		obj.renderSignature(obj.sig,obj.smoothness,obj.culling);
		obj.updateControlValue();
		ZLM.killEvent(e);			
	}

	ZLM.killEvent(event);
}

ClientMethod touchStart(node, event) [ Language = javascript ]
{
	if (event.touches.length==1) {
		this.touchBaseX = ZLM.getPageOffsetLeft(node)-zenGetPageScrollLeft();
		this.touchBaseY = ZLM.getPageOffsetTop(node)-zenGetPageScrollTop();
		ZLM.killEvent(event);
	}
}

/// Track touch gestures and generate curve data for mobile devices
ClientMethod touchMove(node, event) [ Language = javascript ]
{
	
	if (event.touches.length==1) {
		var t = event.touches[0];
		var lastX = t.clientX-this.touchBaseX;
		var lastY = t.clientY-this.touchBaseY;
		this.addStroke(this.touchStroke,lastX,lastY);
		this.touchStroke = "l";
	}
	ZLM.killEvent(event);
}

/// Commit the latest gesture to the signature curve
ClientMethod touchEnd(node, event) [ Language = javascript ]
{
	this.touchStroke = "m";
	this.clearCanvas();
	this.renderSignature(this.sig,this.smoothness,this.culling);
	this.updateControlValue();
	ZLM.killEvent(event);
}

/// Extract current rendering information and abstract it into the nominal value
/// of this control
ClientMethod updateControlValue() [ Language = javascript ]
{
	var str = this.exportAsPath(this.sig,this.smoothness,this.culling,true);
	this.value = str;
	var el = this.findElement('control');
	el.value = str;
	this.onchangeHandler();
}

/// Parse a new nominal value into the graphical context
ClientMethod parseValue() [ Language = javascript ]
{
	this.sig=[];
	if (this.value.length>1) {
		var pts = this.value.split(",");
		for (var i = 0; i<pts.length; i++) {
			var d = pts[i].split(" ");
			if (d.length==3) this.sig.push({connect:d[0], x:d[1], y:d[2]});
		 }
	}
	this.clearCanvas();
	this.renderSignature(this.sig,this.smoothness,this.culling);
}

ClientMethod onRefreshContents() [ Language = javascript ]
{
	this.initialize();
	this.clearCanvas();
	this.renderSignature(this.sig,this.smoothness,this.culling);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.initialize();
	this.parseValue();
}

/// Override to get current value of control.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'value':
		return this.normalizeValue(this.value);
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
		case 'compression':
			var v = parseInt(value,10);
			if (v<0) v=0;
			this.compression = v;
			break;
		case 'culling':
			var v = parseInt(value,10);
			if (v<0) v=0;
			this.culling = v;
			break;
		case 'nib':
			var v = parseInt(value,10);
			if (v<1) v = 1;
			this.nib = v;
			this.clearCanvas();
			this.renderSignature(this.sig,this.smoothness,this.culling);	
			break;
		case 'value':
			this.value=value;
			this.parseValue();
			this.updateControlValue();
			break;
		default:
			// dispatch
			return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Export the vector description of the scribble to an external file
/// The data stream, vector, may be either a JSON string (as returned
/// from exportSignature() or in the internal format returned by 
/// exportAsPath().  The provided filename should be a fully qualified 
/// path-filename where the directory is either the temp directory for the 
/// instance or one of the custom whitelisted directories given in 
/// ^%SYS("ZEN","fsDirectoryWhitelist")
ClassMethod Export(fileName As %ZEN.Datatype.string, vector As %ZEN.Datatype.string) As %ZEN.Datatype.integer [ ZenMethod ]
{
	// Need to validate data stream against expected format
	If ('..ValidateDataStream(vector)) Quit 0
	// Need to validate filename against whitelisted directories
	Set dName = ##class(%Library.File).GetDirectory(fileName)
	Set fName = ##class(%Library.File).GetFilename(fileName)
	Set mgrTmp = $GET(^%SYS("TempDir"),"")
	If ((dName="")&&(mgrTmp'="")) {
		Set fileName=##class(%File).NormalizeFilename(fName,mgrTmp)
	}
	Else {
		Set fileName=##class(%File).NormalizeFilename(fName,dName)
	}
    If (fileName '= "") {
		If ('..ValidateDestination(fileName)) Quit 0
		Set file=##class(%File).%New(fileName)
 		Do file.Open("WSN")
		Do file.WriteLine(vector)
	 	Quit file.Size
	}
 	Quit 0
}

ClassMethod ValidateDestination(fileName As %ZEN.Datatype.string) As %Boolean
{
	Set dName = ##class(%Library.File).GetDirectory(fileName)
	Set fName = ##class(%Library.File).GetFilename(fileName)
	Set mgrTmp = ##class(%File).NormalizeFilename("XxXxX",$GET(^%SYS("TempDir"),""))
	Set mgrTmp = $Piece(mgrTmp,"XxXxX",1)
 	Set fsWhitelist = $GET(^%SYS("ZEN","fsDirectoryWhitelist"),"")
	Set accept = 0 
	If (dName=mgrTmp) {
 		Set accept = 1
	}
	ElseIf (fsWhitelist'="") {
		If ($LISTVALID(fsWhitelist)) {
			Set ptr = 0
			Set extract = ""
			While $LISTNEXT(fsWhitelist,ptr,extract) {
   				If (($DATA(extract)) && (extract = dName)) {
   					Set accept = 1
   				}
			}
  		 }
  		 Else {
	   		Set len=$LENGTH(fsWhitelist,",")
			Set idx=1
			While (idx<=len) {
				Set extract=$PIECE(fsWhitelist,",",idx)
 				If ((extract'="")&&(extract=dName)) {
					Set accept = 1
					Set idx=len+1
				}
				Else {
					Set idx=idx+1
				}
		   }
		}
	}
	Quit accept
}

ClassMethod ValidateDataStream(vector As %ZEN.Datatype.string) As %Boolean
{
	Set accept = 0
	
 	Try {
 		Set obj = ##class(%DynamicAbstractObject).%FromJSON(vector)
 		Set accept = 1
 	}
 	Catch (e) {	
		// Test stream for internal CSV format
		Set accept = 1
		Set len=$LENGTH(vector,",")
		Set idx=1
		While (idx<=len) {
			Set extract=$PIECE(vector,",",idx)
			If (extract'="") {
				Set subLen = $LENGTH(extract," ")
				If (subLen'=3) {
					Set accept = 0
					Set idx=len+1
				}
			}
			Set idx=idx+1
	   }
	}
	Quit accept
}

}
