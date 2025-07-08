/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG Smiley meter.<br>
/// This displays a range of values using a stylized smiling (or frowning) face.
Class %ZEN.SVGComponent.smiley Extends meter [ Deprecated, System = 3 ]
{

/// Specifies what type of face to show.
Property persona As %ZEN.Datatype.string(VALUELIST = ",classic,alien,pirate") [ InitialExpression = "classic" ];

XData SVGStyle
{
<style type="text/css">
.smiley-face {
	stroke: black;
	stroke-width: 0.5px;
}

.smiley-eye {
	fill: none;
	stroke: black;
	stroke-width: 2px;
}

.smiley-eyePatch {
	fill: black;
	stroke: black;
	stroke-width: 2px;
}

.smiley-eyeBand {
	fill: black;
	stroke: black;
	stroke-width: 1px;
	stroke-linecap: round;
}

.smiley-mouth {
	fill: none;
	stroke: black;
	stroke-width: 2px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.smiley-pirate-mouth {
	fill: white;
	stroke: black;
	stroke-width: 2px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.smiley-alien-face {
	stroke: black;
	stroke-width: 0.5px;
}

.smiley-alien-eye {
	fill: black;
	stroke: black;
	stroke-width: 2px;
	stroke-opacity: 0.1;
}


</style>
}

XData SVGDef
{
<defs>
<radialGradient id="smiley-faceGrad" cx="50" cy="45" r="35" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:#FFFFE0" />
<stop offset="90%" style="stop-color:yellow" />
<stop offset="100%" style="stop-color:#404000" />
</radialGradient>

<radialGradient id="smiley-faceAlienGrad" cx="500" cy="45" r="1500" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:yellow" />
<stop offset="90%" style="stop-color:darkgreen" />
<stop offset="100%" style="stop-color:black" />
</radialGradient>

<pattern id="teeth" patternUnits="userSpaceOnUse"
 x="0" y="0" width="12" height="10"
 viewBox="0 0 12 10" >
<rect x="0" y="0" height="10" width="12" fill="white" stroke="black" stroke-width="0.2"/>
</pattern> 

</defs>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	switch(this.persona) {
	case 'alien':
		this.renderAlien();
		break;
	default:
		this.renderFace();
		break;
	}
}

/// Draw a smiley face
ClientMethod renderFace() [ Language = javascript ]
{
	// face
	var face = this.document.createElementNS(SVGNS,'circle');
	face.setAttribute('id',this.makeId('face'));
	face.setAttribute('class','smiley-face');
	face.setAttribute('style','fill: url(#smiley-faceGrad);');
	face.setAttribute('cx',50);
	face.setAttribute('cy',45);
	face.setAttribute('r',35);
	this.svgGroup.appendChild(face);

	// eyes
	var eye = this.document.createElementNS(SVGNS,'circle');
	eye.setAttribute('id',this.makeId('reye'));
	eye.setAttribute('class','smiley-eye');
	eye.setAttribute('cx',33);
	eye.setAttribute('cy',35);
	eye.setAttribute('r',3);
	this.svgGroup.appendChild(eye);

	var eye = this.document.createElementNS(SVGNS,'circle');
	eye.setAttribute('id',this.makeId('leye'));
	eye.setAttribute('class','smiley-eye');
	eye.setAttribute('cx',67);
	eye.setAttribute('cy',35);
	eye.setAttribute('r',3);
	this.svgGroup.appendChild(eye);

	if ('pirate'==this.persona) {
		// eye patch

		var band = this.document.createElementNS(SVGNS,'path');
		band.setAttribute('class','smiley-eyeBand');
		band.setAttribute('d','M 27 18 L 65 35 84.5 42 84 40 65 32 z');
		this.svgGroup.appendChild(band);

		var patch = this.document.createElementNS(SVGNS,'rect');
		patch.setAttribute('class','smiley-eyePatch');
		patch.setAttribute('x',61);
		patch.setAttribute('y',30);
		patch.setAttribute('width',10);
		patch.setAttribute('height',10);
		patch.setAttribute('rx',3);
		this.svgGroup.appendChild(patch);
	}

	// X-eyes
	var brow = this.document.createElementNS(SVGNS,'path');
	brow.setAttribute('id',this.makeId('rx'));
	brow.setAttribute('class','smiley-eye');
	brow.setAttribute('style','display: none;');
	brow.setAttribute('d','M 31 33 L 35 37 M 31 37 L 35 33');
	this.svgGroup.appendChild(brow);

	var brow = this.document.createElementNS(SVGNS,'path');
	brow.setAttribute('id',this.makeId('lx'));
	brow.setAttribute('class','smiley-eye');
	brow.setAttribute('style','display: none;');
	brow.setAttribute('d','M 65 33 L 69 37 M 65 37 L 69 33');
	this.svgGroup.appendChild(brow);

	// brows
	var brow = this.document.createElementNS(SVGNS,'path');
	brow.setAttribute('id',this.makeId('rbrow'));
	brow.setAttribute('class','smiley-eye');
	brow.setAttribute('style','');
	brow.setAttribute('d','M 28 30 a 1 1.6 -45 1 1 10 3');
	this.svgGroup.appendChild(brow);

	if ('pirate'!=this.persona) {
		var brow = this.document.createElementNS(SVGNS,'path');
		brow.setAttribute('id',this.makeId('lbrow'));
		brow.setAttribute('class','smiley-eye');
		brow.setAttribute('style','');
		brow.setAttribute('d','M 72 30 a 1 1.6 45 1 0 -10 3');
		this.svgGroup.appendChild(brow);
	}

	// mouth
	var mouth = this.document.createElementNS(SVGNS,'path');
	mouth.setAttribute('id',this.makeId('mouth'));
	if ('pirate'==this.persona) {
		mouth.setAttribute('class','smiley-pirate-mouth');
		mouth.setAttribute('style','fill: url(#teeth);');
	}
	else {
		mouth.setAttribute('class','smiley-mouth');
	}
	mouth.setAttribute('d','M 28 55 a 10 5 0 1 0 44 0');
	this.svgGroup.appendChild(mouth);
	
	// label
	this.renderLabel('50%',95);

	// move mouth to initial position
	this.updateMouth();
}

/// Internal method: update position of smiley mouth
ClientMethod updateMouth() [ Language = javascript ]
{
	// calculate amount of smile
	// display range is 0 to 5, sweep for sign
	var smile = 0;
	var sweep = 1;
	
	var xeyes = false;
	var brows = false;
	
	var range = parseFloat(this._rangeUpper) - parseFloat(this._rangeLower);
	if (range != 0) {
		smile = -((((parseFloat(this.value) - parseFloat(this._rangeLower)) / range) * 10) - 5);
	}
	
	// max smile
	if (smile >= 5) {
		smile = 5;
		xeyes = true;
	}
	if (smile <=-5) {
		smile = -5;
		brows = true;
	}
	if (smile <= 0) {
		sweep = 0;
		smile = -smile;
	}
	
	// work-around for IE math bugs
	if (smile == 0) {
		smile = 0.001;
	}
	
	// mouth
	var mouth = this.findSVGElement("mouth");
	var path = "M 28 55 a 10 " + smile + " 0 1 " + sweep + " 44 0";
	if ('pirate'==this.persona) {
		path += ' z';
	}
	mouth.setAttribute("d", path);

	if (this.persona=='alien') {
		if (xeyes) {
			this.findSVGElement("reye").setAttribute("style","fill:url(#glow-red);");
			this.findSVGElement("leye").setAttribute("style","fill:url(#glow-red);");
		}
		else if (brows) {
			this.findSVGElement("reye").setAttribute("style","fill:url(#glow-blue);");
			this.findSVGElement("leye").setAttribute("style","fill:url(#glow-blueDiag);");
		}
		else {
			this.findSVGElement("reye").setAttribute("style","");
			this.findSVGElement("leye").setAttribute("style","");
		}
		return;
	}

	// eyes
	if (xeyes) {
		this.findSVGElement("reye").setAttribute("style","display:none;");
		this.findSVGElement("leye").setAttribute("style","display:none;");
		this.findSVGElement("rx").setAttribute("style","");
		this.findSVGElement("lx").setAttribute("style","");
	}
	else {
		this.findSVGElement("reye").setAttribute("style","");
		this.findSVGElement("leye").setAttribute("style","");
		this.findSVGElement("rx").setAttribute("style","display:none;");
		this.findSVGElement("lx").setAttribute("style","display:none;");
	}

	// brows
	if (brows) {
		this.findSVGElement("rbrow").setAttribute("style","");
		if ('pirate'!=this.persona) {
			this.findSVGElement("lbrow").setAttribute("style","");
		}
	}
	else {
		this.findSVGElement("rbrow").setAttribute("style","display:none;");
		if ('pirate'!=this.persona) {
			this.findSVGElement("lbrow").setAttribute("style","display:none;");
		}
	}
}

/// Draw an alien face
ClientMethod renderAlien() [ Language = javascript ]
{
	// face
	var face = this.document.createElementNS(SVGNS,'path');
	face.setAttribute('id',this.makeId('face'));
	face.setAttribute('class','smiley-alien-face');
	face.setAttribute('style','fill: url(#smiley-faceAlienGrad);');
	face.setAttribute('d',"M 1307.8479,24.348421 c -148.5,0 -353.5,93.7 -353.5,337.5 0,0.8 0,1.7 0,2.5 1.7,242.7 248.6,445.9 353.5,445.90 105.3,0 353.5,-204.62263 353.5,-448.42263 0,-243.8 -205,-337.5 -353.5,-337.5 z");
	face.setAttribute('transform','scale(0.1) translate(-800,50)');
	this.svgGroup.appendChild(face);
	
	var eye = this.document.createElementNS(SVGNS,'ellipse');
	eye.setAttribute('id',this.makeId('reye'));
	eye.setAttribute('class','smiley-alien-eye');
	eye.setAttribute('cx',33);
	eye.setAttribute('cy',45);
	eye.setAttribute('rx',10);
	eye.setAttribute('ry',5);
	eye.setAttribute('transform','rotate(45,33,45)');
	this.svgGroup.appendChild(eye);

	var eye = this.document.createElementNS(SVGNS,'ellipse');
	eye.setAttribute('id',this.makeId('reyeInner'));
	eye.setAttribute('class','smiley-alien-eye');
	eye.setAttribute('style','opacity: 0.7;');
	eye.setAttribute('cx',33);
	eye.setAttribute('cy',45);
	eye.setAttribute('rx',9);
	eye.setAttribute('ry',4);
	eye.setAttribute('transform','rotate(45,33,45)');
	this.svgGroup.appendChild(eye);

	var eye = this.document.createElementNS(SVGNS,'ellipse');
	eye.setAttribute('id',this.makeId('leye'));
	eye.setAttribute('class','smiley-alien-eye');
	eye.setAttribute('cx',67);
	eye.setAttribute('cy',45);
	eye.setAttribute('rx',10);
	eye.setAttribute('ry',5);
	eye.setAttribute('transform','rotate(-45,67,45)');
	this.svgGroup.appendChild(eye);

	var eye = this.document.createElementNS(SVGNS,'ellipse');
	eye.setAttribute('id',this.makeId('leyeInner'));
	eye.setAttribute('class','smiley-alien-eye');
	eye.setAttribute('style','opacity: 0.7;');
	eye.setAttribute('cx',67);
	eye.setAttribute('cy',45);
	eye.setAttribute('rx',9);
	eye.setAttribute('ry',4);
	eye.setAttribute('transform','rotate(-45,67,45)');
	this.svgGroup.appendChild(eye);

	// mouth
	var mouth = this.document.createElementNS(SVGNS,'path');
	mouth.setAttribute('id',this.makeId('mouth'));
	mouth.setAttribute('class','smiley-mouth');
	mouth.setAttribute('d','M 28 55 a 10 5 0 1 0 44 0');
	mouth.setAttribute('transform','translate(0,12)');
	this.svgGroup.appendChild(mouth);
	
	// label
	this.renderLabel('50%',95);

	// move mouth to initial position
	this.updateMouth();
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {

	case 'persona':
		this.persona = value;
		this.unrender();
		this.render();
		break;

	case 'value':
		this.value = value;
		this.updateMouth();
		break;

	case 'width':
	case 'height':
		return this.invokeSuper('setProperty',arguments);

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
