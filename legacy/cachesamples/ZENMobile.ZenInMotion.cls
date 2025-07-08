/// Created using the page template: Default
Class ZENMobile.ZenInMotion Extends %ZEN.Mobile.mobilePage
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMobile.TestApplication";

Parameter PAGENAME = "Zen In Motion";

Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#goal {
	width:60px;
	height:60px;
	border-radius: 30px;
	-webkit-radius: 30px;
	position: absolute;
	background-color: #000042;
}

#ball {
	width: 40px;
	height: 40px;
	border-radius: 20px;
	-webkit-radius: 20px;
	background-color: red;
	position:absolute;
	top: 0px;
	left: 0px;
}

.bumber {
	position:absolute;
	width: 25px;
	height: 25px;
	border-radius: 3px;
	-webkit-radius: 3px;
	border: 2px solid #00aa00;
	background: #55ff66;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<group layout="none" id="timestamp" enclosingStyle="text-align:center;font:bold 24px Arial;">
</group>
</page>
}

ClientMethod buildScreen() [ Language = javascript ]
{
	var body = document.getElementById("zenBody");
	if (this.noJoy) {
		body.innerHTML = "Your browser or device does not support Device Orientation and Motion API. Try this sample with iPhone, iPod or iPad with iOS 4.2+.";
	}
	else {
		var w = zenPage.activeWidth;
		var h = zenPage.activeHeight;
		
		var gd = document.createElement("DIV");
		gd.setAttribute("id","goal");
		gd.ux = w/2-45;
		gd.uy = h/2-45;
		gd.lx = gd.ux+35;
		gd.ly = gd.uy+35
		gd.style.top = (gd.uy+15)+"px";
		gd.style.left = (gd.ux+15)+"px";
		body.appendChild(gd);
		this.goalDiv = gd;

		this.bumpers = [];
		var xSlice = w/8;
		var ySlice = h/8;
		for (var i=0;i<20;i++) {
			var b = document.createElement("DIV");
			b.setAttribute("class","bumber");
			var x = Math.round(Math.random()*2*xSlice);
			var y = Math.round(Math.random()*2*ySlice);
			if (Math.random()>0.5) x+=5*xSlice;
			else x+=xSlice;
			if (Math.random()>0.5) y+=5*ySlice;
			else y+=ySlice;
			b.style.top = y + "px";
			b.style.left = x + "px";
			b.ux = x;
			b.uy = y;
			b.lx = x+25;
			b.ly = y+25;
			body.appendChild(b);
			this.bumpers.push(b);
		}	
		this.ballDiv = document.createElement("DIV");
		this.ballDiv.setAttribute("id","ball");
		body.appendChild(this.ballDiv);
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	// Ball position
	this.x = 0;
	this.y = 0;
	
	// Ball Speed
	this.vx = 0;
	this.vy = 0;

	// Acceleration
	this.ax = 0;
	this.ay = 0;

	this.delay = 10;
	this.vMultiplier = 0.01;
	this.noJoy = true;
	if (zenPage.featureDeviceMotion) {
		this.noJoy = false;
		setTimeout("zenPage.moveBall();",1000);
	}		
	setTimeout("zenPage.buildScreen();",0);
	this.startTime = "new";
	this.timeDiv = zen("timestamp").getEnclosingDiv();
}

ClientMethod ondevicemotionHandler(event) [ Language = javascript ]
{
	this.ax = event.accelerationIncludingGravity.x;
	this.ay = event.accelerationIncludingGravity.y;
	// if, for some reason, orientation isn't locked, we need
	// to accound for the fact that the display is rotated but the
	// coordinate system of the gyroscopes is not.
	if (window.orientation == 180) { // upside down portrait reverse sign
		this.ax = -this.ax;
		this.ay = -this.ay;
	}
	else if (window.orientation == -90) { // landscape 
		var t = this.ax;
		this.ax = this.ay;
		this.ay = -t;
	}
	else if (window.orientation == 90) { // other landscape
		var t = this.ax;
		this.ax = -this.ay;
		this.ay = t;
	}
	
/*
	if (event.accelerationIncludingGravity.z > 10.5 && !this.tripped) {
		this.tripped = true;
		alert("Clear!");
	}
*/
}

ClientMethod intersect(x1, y1, r1, x2, y2, r2) [ Language = javascript ]
{
	var dSquare = (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2);
	var rSquare = (r1+r2)*(r1+r2);
	return(dSquare<rSquare);
}

ClientMethod moveBall() [ Language = javascript ]
{
	var now = Date.now();
	if (this.startTime=="new") this.startTime = now;
	var deltaT = Math.round((now-this.startTime)/100)/10;
	this.timeDiv.innerHTML = "Ellapsed Time: "+deltaT;
	
	var e = 0.5;
	var done=false;
	
	this.vy += -(this.ay);
	this.vx += this.ax;

	this.y = Math.floor(this.y + this.vy * this.vMultiplier);
	this.x = Math.floor(this.x + this.vx * this.vMultiplier);
		
	var bux = this.x;
	var buy = this.y;
	var blx = bux+40;
	var bly = buy+40;
	
	for (var i=this.bumpers.length-1;i>=0;i--) {
		var b = this.bumpers[i];
		if (this.intersect(bux+20,buy+20,20,(b.ux+b.lx)/2,(b.uy+b.ly)/2,(b.lx-b.ux)/2)) {		
			if (bux<b.lx && bux>b.ux) { // bump to the right?
				this.x = b.lx;
				this.vx = -2*e*this.vx;	
			}
			else if (this.x+40>b.ux && this.x+40<b.lx){ // bump to left
				this.x = b.ux-40;
				this.vx = -2*e*this.vx;
			}
			if (this.y<b.ly && this.y>b.uy) { // bump down
				this.y = b.ly;
				this.vy = -2*e*this.vy;
			}
			else if (this.y+40>b.uy && this.y+40<b.ly) { // bump up
				this.y = b.uy-40;
				this.vy = -2*e*this.vy;
			}
		}
	}
	if (this.x<0) { 
		this.x = 0; 
		this.vx = -e*this.vx; 
	}
	if (this.y<0) { 
		this.y = 0; 
		this.vy = -e*this.vy; 
	}
	if (this.x>zenPage.activeWidth-40) { 
		this.x = zenPage.activeWidth-40;
		this.vx = -e*this.vx; 
	}
	if (this.y>zenPage.activeHeight-40) { 
		this.y = zenPage.activeHeight-40; 
		this.vy = -e*this.vy; 
	}

	if (this.x>this.goalDiv.ux && this.x<this.goalDiv.lx &&
		this.y>this.goalDiv.uy && this.y<this.goalDiv.ly) {
			done = true;
			this.x = zenPage.activeWidth/2-20;
			this.y = zenPage.activeHeight/2-20;
			this.ballDiv.style.background = "#aa0000";
	}
	if (this.ballDiv) {
		this.ballDiv.style.top = this.y + "px";
		this.ballDiv.style.left = this.x + "px";
	}
	if (!done) setTimeout("zenPage.moveBall();",zenPage.delay);
}

}

