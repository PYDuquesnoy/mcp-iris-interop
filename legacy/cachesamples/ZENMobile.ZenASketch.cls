/// Created using the page template: Default
Class ZENMobile.ZenASketch Extends %ZEN.Mobile.mobilePage
{

/// Turn off scroll and zoom defaults 
Parameter DEFAULTPREVENTGESTURES = 1;

/// Application this page belongs to.
Parameter APPLICATION = "ZENMobile.TestApplication";

Parameter PAGENAME = "Zen A Sketch";

Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#zen1 {
	background: #dd0000;
	width:100%;
	height:100%;
	position:relative;
	top:0px;
	left:0px;
}

.knobEdge {
	width:80px;
	height:80px;
	border:2px solid #777777;
	border-radius: 40px;
	-webkit-radius: 40px;
	position:absolute;
	bottom: 10px;
 	background: -webkit-linear-gradient(left, #aaaaaa, #ffffff, #cccccc);
	background: -moz-linear-gradient(left, #aaaaaa, #ffffff, #cccccc);  
	background: -ms-linear-gradient(left, #aaaaaa, #ffffff, #cccccc);
 	background: -o-linear-gradient(left, #aaaaaa, #ffffff, #cccccc);
}

.knobTop {
	width:60px;
	height:60px;
	position:absolute;
	top:8px;
	left:8px;
	border-radius:30px;
	-webkit-radius:30px;
	background:#ffffff;
	border:2px solid #f0f0f0;
	background: -webkit-radial-gradient(circle, #ffffff, #c7c7c7);
  	background: -moz-radial-gradient(circle, #ffffff, #c7c7c7);
	background: -ms-radial-gradient(circle, #ffffff, #c7c7c7);
}

.screen {
	position:absolute;
	top:35px;
	right:45px;
	left:45px;
	bottom:110px;
	border:10px solid #bb0000;
	border-radius:14px;
	-webkit-radius:14px;
	overflow:hidden;
	background:silver;
}

.logo {
	position:absolute;
	left:0px;
	right:0px;
	bottom:50px;
	text-align:center;
}

#logoLabel {
	font-size: 32px;
	font-weight: bold;
	font-family: "Comic Sans MS",cursive,sans-serif;
	color: gold;
	
}

#canvas {
	width:100%;
	height:100%;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="" layout="none" enclosingStyle="position:relative;top:0px;lef:0px;">
<group layout="none" enclosingClass="knobEdge" enclosingStyle="left:10px;">
<group layout="none" enclosingClass="knobTop" >
</group>
</group>
<group layout="none" enclosingClass="knobEdge" enclosingStyle="right:10px;">
<group layout="none" enclosingClass="knobTop" >
</group>
</group>
<group layout="none" enclosingClass="screen" >
<canvas id="canvas" onrender="zenPage.refreshCanvas();"/>
</group>
<group layout="none" enclosingClass="logo" >
<label id="logoLabel" value="Zen-A-Sketch" />
</group>
</page>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.ptX = 0;
	this.ptY = 0;
	this.deltaX = 0;
	this.deltaY = 0;

	setTimeout("zenPage.updateCanvas();",500);
}

ClientMethod ontouchstartHandler(event) [ Language = javascript ]
{
	var ww = zenPage.getNativeWindowWidth();
	var wh = zenPage.getNativeWindowHeight();
	
	this.vX = 50;
	this.vY = wh-50;
	this.hX = ww-50;
	this.hY = this.vY;
	// get knob centers
	this.vcX = 50;
	this.vcY = wh-50;
	this.hcX = ww-50;
	this.hcY = this.vY;
	
	this.vD = 0;
	this.hD = 0;
	
	var t=event.touches;
	for (var i=t.length-1;i>=0;i--) {
		var pt = t[i];
		var px = pt.pageX;
		var py = pt.pageY;
		// if the touch was in the right area, get the starting point
		if (py>wh-100) {
			if (px<100) {
				this.vX = px;
				this.vY = py;
			}
			else if (px>ww-100) {
				this.hX = px;
				this.hY = py;
			}
		}
	}
}

/// Process (potentially simultaneous) gestures on the knobs.  Because
/// both 'knobs' operate independently but in parallel, it's actually 
/// easier to process one combined event stream than to break out the 
/// knobs into separate widgets (where the simultaneous nature of their
/// updates might be lost in an event queue.  In effect, this is the 
/// diffeence between using both controls in parallel to make a diagonal
/// line, versus using them serially to create a stair-stepping one.
ClientMethod ontouchmoveHandler(event) [ Language = javascript ]
{
	var ww = zenPage.getNativeWindowWidth();
	var wh = zenPage.getNativeWindowHeight();
	
	// initialize potential destination points
	var vmX = -1;
	var vmY = -1;
	var hmX = -1;
	var hmY = -1;
		
	var t=event.touches;
	for (var i=t.length-1;i>=0;i--) {
		var pt = t[i];
		var px = pt.pageX;
		var py = pt.pageY;
		// it the touch is in the right region, mark it as a destination
		if (py>wh-100) {
			if (px<100) {
				vmX = px;
				vmY = py;
			}
			else if (px>ww-100) {
				hmX = px;
				hmY = py;
			}
		}
	}
	if (vmX> -1) { // movement detected on the vertical control
		var dx = vmX-this.vX;
		var dy = vmY-this.vY;
		var d = dx*dx+dy*dy;
		// Figure out the major axis of motion
		if (Math.abs(dx)>Math.abs(dy)) dy=0;
		else dx=0;
		
		// Figure out which quandrant we started in
		var q = 1;
		if (this.vX<this.vcX) q++;
		if (this.vY>this.vcY) q+=2;
		
		var val = 0; // no motion yet
		if (d>5) { // enough motion to test
			if (q==1) {
				if (dx<0 || dy<0) val++; // ccw
				else if (dx>0 || dy>0) val--; // cw
			} else if (q==2) {
				if (dx<0 || dy>0) val++;
				else if (dx>0 || dy<0) val--;
			} else if (q==3) {
				if (dx>0 || dy<0) val++;
				else if (dx<0 || dy>0) val--;
			} else {
				if (dx>0 || dy>0) val++;
				else if (dx<0 || dy<0) val--;
			}
			if (val!=0) {
				this.vY = vmY;
				this.vX = vmX;
				this.deltaY -= val;
			}
		}
	}
	if (hmX> -1) { // movement detected on the horizontal control
		var dx = hmX-this.hX;
		var dy = hmY-this.hY;
		var d = dx*dx+dy*dy;
		// Figure out the major axis of motion
		if (Math.abs(dx)>Math.abs(dy)) dy=0;
		else dx=0;
		// Figure out which quandrant we started in
		var q = 1;
		if (this.hX<this.hcX) q++;
		if (this.hY>this.hcY) q+=2;
		
		var val = 0; // no motion yet
		if (d>5) { // enough motion to test
			if (q==1) {
				if (dx<0 || dy<0) val++; // ccw
				else if (dx>0 || dy>0) val--; // cw
			} else if (q==2) {
				if (dx<0 || dy>0) val++;
				else if (dx>0 || dy<0) val--;
			} else if (q==3) {
				if (dx>0 || dy<0) val++;
				else if (dx<0 || dy>0) val--;
			} else {
				if (dx>0 || dy>0) val++;
				else if (dx<0 || dy<0) val--;
			}
			if (val!=0) {
				this.hY = hmY;
				this.hX = hmX;
				this.deltaX -= val;
			}
		}
	}
}

/// Watch for a simple, face down shake to clear the screen.
ClientMethod ondevicemotionHandler(event) [ Language = javascript ]
{
	if (event.accelerationIncludingGravity.z > 10.5) {
		zenPage.clearCanvas();
	}
}

/// Periodically update the canvas based on the movement deltas registered 
/// since the last update.
ClientMethod updateCanvas() [ Language = javascript ]
{
	if (this.context) {
		var ctx = this.context;
		ctx.strokeStyle = "#111111";
		ctx.fillStyle = "#111111";
		ctx.lineWidth = "5px";
		ctx.lineCap = "round";
		var len = this.path.length;
		if (len==0) {
			this.path.push({"x":this.ptX,"y":this.ptY});
			ctx.beginPath();
			ctx.moveTo(this.ptX,this.ptY);
			ctx.lineTo(this.ptX,this.ptY);
			ctx.stroke();
		}
		else if (this.deltaX!=0 || this.deltaY!=0) {
			var obj = this.path[len-1];
			var newX = obj.x+3*this.deltaX;
			var newY = obj.y+3*this.deltaY;
			if (newX<0) newX = 0;
			if (newY<0) newY = 0;
			if (newX>this.cvsWidth) newX = this.cvsWidth;
			if (newY>this.cvsHeight) newY = this.cvsHeight;
			this.deltaX = 0;
			this.deltaY = 0;
			ctx.beginPath();
			ctx.moveTo(obj.x,obj.y);
			ctx.lineTo(newX,newY);
			ctx.stroke();
			this.ptX = newX;
			this.ptY = newY;
			this.path.push({"x":newX,"y":newY});
		}
	}
	setTimeout("zenPage.updateCanvas();",100);
}

/// Clear the screen
ClientMethod clearCanvas() [ Language = javascript ]
{
	var ctx = this.context;
	if (ctx) {
		ctx.fillStyle="silver";
		ctx.fillRect(0,0,this.cvsWidth,this.cvsHeight);
	}
}

/// Initialize the canvas and save certain values for faster processing later
ClientMethod initCanvas() [ Language = javascript ]
{
	this.canvasInitialized = true;

	this.canvas = zen("canvas");
	this.context = this.canvas.getContext();
	var div = this.canvas.getEnclosingDiv();
	this.cvsWidth = div.offsetWidth;
	this.cvsHeight = div.offsetHeight;
	
	var ctrl = this.canvas.findElement('canvas');
	ctrl.width = this.cvsWidth;
	ctrl.height = this.cvsHeight;
	
	this.ptX = this.cvsWidth/2;
	this.ptY = this.cvsHeight/2;
	this.path = [];
	if (this.cvsHeight<1) this.canvasInitialized = false;
}

/// Initialize and or refresh the canvas as needed
ClientMethod refreshCanvas() [ Language = javascript ]
{
	if (!this.canvasInitialized) {
		this.initCanvas();
		setTimeout("zenPage.refreshCanvas();",100);
	}
	else {
//		var ctx = this.context;
		zenPage.clearCanvas();
	}
}

}

