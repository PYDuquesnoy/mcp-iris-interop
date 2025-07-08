/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Style edit control.<br/>
/// This provides a way to edit CSS styling for text elements.
/// The value for this control is a css style string.
Class %DeepSee.Component.styleEdit Extends %ZEN.Component.control [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter DEFAULTENCLOSINGCLASS;

/// Set of features to display when in "style" mode:
/// These include: "font", "background", "color", "align", "reset".
Property features As %ZEN.Datatype.csv;

/// Operating mode of the control.<br/>
/// "style" (the default) edit a css style spec.<br/>
/// "color" edit a single color value.<br/>
Property mode As %ZEN.Datatype.string(VALUELIST = ",style,color") [ InitialExpression = "style" ];

/// Caption to display when in "color" mode.
Property caption As %ZEN.Datatype.caption;

/// Internal use only; client flag used to track if the
/// dropdown is visible.
Property isDropdownVisible As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Current color set.
Property currColorSet As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Logical names of color sets.
Property colorSetNames As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Captions of color sets.
Property colorSetCaptions As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// List of ;-delimited color set values for drop down.
Property colorSets As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

.seBox {
	user-select: none;
	border: 1px solid #D0D0D0;
	background: #F0F0F0;
}

.seDropdown {
	position: absolute;
	z-index: 2;
	border: 1px solid #808080;
	width: 200px;
	height: 220px;
	background: #FDFDFD;
	box-shadow: 2px 2px 2px black;
	display: none;
}

.seColorSet {
	color: #404040;
	font-size: 10px;
}

table.seColorTable td {
}

table.seColorTable td:hover {
	box-shadow: 1px 1px 1px #4040F0,-1px -1px 1px #4040F0;
}

</style>
}

Method %DrawHTML()
{
	// Get list of color sets
	Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetColorSets(.tSets)
	Set k = $O(tSets(""))
	While (k'="") {
		Do ..colorSetNames.Insert($LG(tSets(k),1))
		Do ..colorSetCaptions.Insert($LG(tSets(k),2))
		Do ..colorSets.Insert($LG(tSets(k),3))
		Set k = $O(tSets(k))
	}

	Do ##super()
}

/// Client-side method to render this control.
ClientMethod renderContents() [ Language = javascript ]
{
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	var enc = this.getEnclosingDiv();
	if (this.mode=='color') {
		// value is css color
		var result = this.value;
	}
	else {
		// value is css style
		var result = this.parseStyle(this.value);
	}
	var features = null;

	if (this.mode=='style') {
		// get list of features
		if (this.features=='') {
			features = { font: true, background: true, color: true, align: true, reset: true };
		}
		else {
			features = { font: false, background: false, color: false, align: false, reset: false };
			var f = this.features.toString().split(',');
			for (var n = 0; n < f.length; n++) {
				if (f[n]!='') {
					features[f[n]] = true;
				}	
			} 
		}
	}

	var html=[];

	html[html.length] = '<div class="seBox" style="position:relative;">';
	html[html.length] = '<table border="0" cellpadding="0" cellspacing="0">';
	html[html.length] = '<tr>';

	if (this.mode=='color') {
		// show one color box
		var style = 'background:#C0C0C0;box-shadow:1px 1px 2px #808080; border-radius:4px;width:25px;height:20px;padding-bottom:2px;padding-top:2px;border:1px solid #808080;background:'+(result==''?'#C0C0C0':result)+';text-align:center;';
		html[html.length] = '<td style="padding:4px;vertical-align:middle;font-family:arial;font-size:12pt;font-weight:bold;"><div id="'+this.makeId('background')+'" title="'+$$$Text('Set background color')+'" style="'+style+'" onclick="zenPage.getComponent('+this.index+').showDropdown(\'background\');" >';
		html[html.length] = '&nbsp;';
		html[html.length] = '</div></td>';
	}
	else {
		// show complete style edit
		// font
		if (features['font']) {
			var fontName = result.fontFamily ? result.fontFamily : '';
			var style = 'background:'+(result.background==''?'#C0C0C0':result.background)+
					';color:'+(result.color==''?'#404040':result.color)+
					';box-shadow:1px 1px 2px #808080; border-radius:4px;width:70px;height:20px;overflow:hidden;padding-bottom:2px;padding-top:2px;border:1px solid #808080;text-align:left;vertical-align:middle;';
			html[html.length] = '<td style="padding:4px;font-family:'+fontName+';font-size:11pt;"><div id="'+this.makeId('font')+'" title="'+$$$Text('Set font')+'" style="'+style+'" onclick="zenPage.getComponent('+this.index+').showDropdown(\'font\');" >';
			html[html.length] = fontName.toString().split(' ')[0];
			html[html.length] = '</div>'
			if (!zenIsIE) {
				// disclosure
				html[html.length] = '<div style="position:absolute; top:15px; left:65px;" onclick="zenPage.getComponent('+this.index+').showDropdown(\'font\');"><image src="images/disclosure-expanded.gif"/></div>';
			}
			html[html.length] = '</td>';

			// font-size
			var fontSize = result.fontSize ? result.fontSize : '';
			var style = 'background:white;box-shadow:1px 1px 2px #808080; border-radius:4px;width:35px;height:20px;overflow:hidden;padding-bottom:2px;padding-top:2px;border:1px solid #808080;text-align:left;vertical-align:middle;';
			html[html.length] = '<td style="padding:4px;font-family:arial;font-size:9pt;"><div id="'+this.makeId('fontSize')+'" title="'+$$$Text('Set font size')+'" style="'+style+'" onclick="zenPage.getComponent('+this.index+').showDropdown(\'fontSize\');" >';
			html[html.length] = fontSize;
			html[html.length] = '</div>'
			if (!zenIsIE) {
				html[html.length] = '<div style="position:absolute; top:15px; left:110px;" onclick="zenPage.getComponent('+this.index+').showDropdown(\'fontSize\');"><image src="images/disclosure-expanded.gif"/></div>';
			}
			html[html.length] = '</td>';
		}

		if (features['background']) {
			// background
			var style = 'background:#C0C0C0;box-shadow:1px 1px 2px #808080; border-radius:4px;width:25px;height:20px;padding-bottom:2px;padding-top:2px;border:1px solid #808080;background:'+(result.background==''?'#C0C0C0':result.background)+';text-align:center;';
			html[html.length] = '<td style="padding:4px;vertical-align:middle;font-family:arial;font-size:12pt;font-weight:bold;"><div id="'+this.makeId('background')+'" title="'+$$$Text('Set background color')+'" style="'+style+'" onclick="zenPage.getComponent('+this.index+').showDropdown(\'background\');" >';
			html[html.length] = '&nbsp;';
			html[html.length] = '</div></td>';
		}

		// color
		if (features['color']) {
			var style = 'background:#404040;box-shadow:1px 1px 1px #808080; border-radius:4px;width:25px;height:20px;padding-bottom:2px;padding-top:2px;border:1px solid #808080;background:'+(result.color==''?'#404040':result.color)+';text-align:center;';
			html[html.length] = '<td style="color:#808080;text-shadow:1px 1px 3px white; padding:4px;vertical-align:middle;font-family:arial;font-size:12pt;font-weight:bold;"><div id="'+this.makeId('color')+'" title="'+$$$Text('Set foreground color')+'" style="'+style+'" onclick="zenPage.getComponent('+this.index+').showDropdown(\'color\');" >';
			html[html.length] = 'a';
			html[html.length] = '</div></td>';
		}

		// bold etc.
		if (features['align']) {
			html[html.length] = '<td style="width:10px;">&nbsp;</td>';

			var src = result.bold ? 'portal/boldButtonB.png' : 'portal/boldButton.png';
			html[html.length] = '<td style="padding:4px;">'
			html[html.length] = '<input type="image" id="'+this.makeId('bold')+'" onclick="zenPage.getComponent('+this.index+').textStyle(\'bold\');" src="'+src+'"/>';

			var src = result.italic ? 'portal/italicButtonB.png' : 'portal/italicButton.png';
			html[html.length] = '<input type="image" id="'+this.makeId('italic')+'" onclick="zenPage.getComponent('+this.index+').textStyle(\'italic\');" src="'+src+'"/>';

			var src = result.underline ? 'portal/underlineButtonB.png' : 'portal/underlineButton.png';
			html[html.length] = '<input type="image" id="'+this.makeId('underline')+'" onclick="zenPage.getComponent('+this.index+').textStyle(\'underline\');" src="'+src+'"/>';

			// alignment.
			html[html.length] = '<br/>';

			var src = result.textAlign =='left' ? 'portal/justLeftButtonB.png' : 'portal/justLeftButton.png';
			html[html.length] = '<input type="image" id="'+this.makeId('alignLeft')+'" onclick="zenPage.getComponent('+this.index+').textAlign(\'left\');" src="'+src+'"/>';

			var src = result.textAlign =='center' ? 'portal/justCenterButtonB.png' : 'portal/justCenterButton.png';
			html[html.length] = '<input type="image" id="'+this.makeId('alignCenter')+'" onclick="zenPage.getComponent('+this.index+').textAlign(\'center\');" src="'+src+'"/>';

			var src = result.textAlign =='right' ? 'portal/justRightButtonB.png' : 'portal/justRightButton.png';
			html[html.length] = '<input type="image" id="'+this.makeId('alignRight')+'" onclick="zenPage.getComponent('+this.index+').textAlign(\'right\');" src="'+src+'"/>';
			html[html.length] = '</td>';
		}

		// reset
		if (features['reset']) {
			html[html.length] = '<td style="padding:0px;">'
			var hlpReset = $$$Text('Reset styles');
			html[html.length] = '<input title="'+hlpReset+'" type="image" onclick="zenPage.getComponent('+this.index+').resetStyles();" onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';" src="images/MacCloseX.png"/>';
			html[html.length] = '</td>';
		}
	}

	html[html.length] = '</tr>';
	html[html.length] = '</table>';

	html[html.length] = '</div>';

	// render
	enc.innerHTML = html.join('');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		this.value = value;
		this.render();
		break;

	default:
		// this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// Show the drop down.
ClientMethod showDropdown(which) [ Language = javascript ]
{
	if (!this.disabled && !this.readOnly) {
		// make drop down appear as modal element
		this._whichDropdown = which;
		zenPage.startModal(this);
	}
}

/// Notification that this component is about to become modal.
ClientMethod onStartModalHandler(zindex) [ Language = javascript ]
{
	// show the dropdown box
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find dropdown div',arguments);

	// add event handler to div
	// (this is because IE raise mouse events if the scroll bar is clicked)
	div.onmousedown = new Function("event","zenPage.getComponent("+this.index+").mouseDown=true;");
	div.onmouseup = new Function("event","zenPage.getComponent("+this.index+").mouseDown=null;");

	// set up style for div
	div.className = 'seDropdown';
	div.style.overflow = 'hidden';
	div.style.overflowY = 'auto';

	// make sure we are placed above mouse trap
	div.style.zIndex = zindex;
	div.style.display = "";	
	this.adjustDropdownPosition();
	// display the contents of the drop down
	this.renderDropdown();
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	if (this._timerId) {
		self.clearTimeout(this._timerId);
		this._timerId = null;
	}

	// copy contents of dropdown to our cache div
	var div = this.getDropDownDiv();

	// hide the DropDown box
	div.style.cssText = "display:none;";

	// restore state
	div.className = "";
	div.mousedown = null;
	div.mouseup = null;
	this.isDropdownVisible = false;
	this.keyMode = null;
}

/// Show the drop down contents.
ClientMethod renderDropdown() [ Language = javascript ]
{
	var which = this._whichDropdown;
	var div = this.getDropDownDiv();

	if (this._timerId) {
		self.clearTimeout(this._timerId);
		this._timerId = null;
	}

	var html = [];

	var caption = '&nbsp;';

	if (this.mode == 'style') {
		switch(which) {
		case 'font':
			caption = $$$Text('Font family');
			break;
		case 'fontSize':
			caption = $$$Text('Font size');
			break;
		case 'background':
			caption = $$$Text('Background');
			var result = this.parseStyle(this.value);
			this._customBackground = result.background;
			break;
		case 'color':
			caption = $$$Text('Text color');
			var result = this.parseStyle(this.value);
			this._customColor = result.color;
			break;
		}
	}
	else if (this.mode=='color') {
		caption = this.caption ? this.caption : $$$Text('Color');
		this._customBackground = this.value ? this.value : null;
	}
	
	html[html.length] = '<table border="0" cellspacing="0" cellpadding="0" style="width:100%;"><tr style="background:#F0F0F0;border-bottom:1px solid #D8D8D8;"><td nowrap="1" style="color:#808080; font-size:8pt;padding-left:4px;">'+caption+'<td style="text-align:right;width:99%;"><image src="deepsee/ds2_x_44.png" style="height:16px;padding:2px;" onclick="zenPage.getComponent('+this.index+').hideDropDown();"  onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';"/>&nbsp;</td></tr></table>';

	var msgDefault = $$$Text('Default');

	// fill in dropdown
	switch(which) {
	case 'font':
		var stdFonts = ['arial','courier new','century schoolbook','helvetica','times roman','verdana','comic sans ms'];
		html[html.length] = '<table style="width:100%;">';
		html[html.length] = '<td onclick="zenPage.getComponent('+this.index+').selectFont(\''+which+'\',\'inherit\');"><div onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';">'+msgDefault+'</div></td>';

		for (var r = 0; r < stdFonts.length; r++) {
			html[html.length] = '<tr>';
			var font = stdFonts[r];
			html[html.length] = '<td style="font-family:'+font+';" onclick="zenPage.getComponent('+this.index+').selectFont(\''+which+'\',\''+font+'\');"><div onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';">'+font+'</div></td>';
			html[html.length] = '</tr>';
		}
		html[html.length] = '</table>';
		break;

	case 'fontSize':
		var stdSizes = [6,7,8,9,10,11,12,13,14,15,16,18,20,24,30,40,48];
		html[html.length] = '<div style="padding:2px;overflow:hidden;">';
		html[html.length] = '<a style="font-family:'+font+';" onclick="zenPage.getComponent('+this.index+').selectFontSize(\''+which+'\',\'inherit\');" onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';">'+msgDefault+'</a><br/>';
		for (var r = 0; r < stdSizes.length; r++) {
			var font = 'arial';
			var size = stdSizes[r] + 'pt';
			html[html.length] = '<a style="font-family:'+font+';font-size:'+size+';" onclick="zenPage.getComponent('+this.index+').selectFontSize(\''+which+'\',\''+size+'\');" onmouseover="this.style.background=\'#FFEEAA\';" onmouseout="this.style.background=\'none\';">'+size+'</a> ';
		}
		html[html.length] = '</div';
		break;

	case 'color':
	case 'background':
		html[html.length] = '<div style="background:#F0F0F0;padding:1px;">';
		html[html.length] = '<select class="seColorSet" id="'+this.makeId('colorSet')+'" onchange="zenPage.getComponent('+this.index+').colorSetChange(\''+which+'\');">';
		//html[html.length] = '<option value="">' + $$$Text('Standard') + '</option>';
		for (var n = 0; n < this.colorSetNames.length; n++) {
			html[html.length] = '<option '+(this.colorSetNames[n]==this.currColorSet?'selected="1"':'')+' value="'+this.colorSetNames[n]+'">' + this.colorSetCaptions[n] + '</option>';
		}
		html[html.length] = '</select>';
		html[html.length] = '</div>';

		html[html.length] = '<div id="'+this.makeId('colorTable')+'">';
		html[html.length] = this.getColorTableHTML(which);
		html[html.length] = '</div>';

		// rgb
		html[html.length] = '<table border="0" cellspacing="1" cellpadding="0" style="margin-top:5px;width:100%;font-size:10px;color:#606060;">';

		bdr = '#808080';
		var r=255,g=255,b=255;
		if (which == 'color') {
			var clr = this._customColor ? this._customColor : 'white';
			if (clr.toString().substr(0,4)=='rgb(') {
				var t= clr.substr(4,clr.length).split(',');
				r = parseInt(t[0],10);
				g = parseInt(t[1],10);
				b = parseInt(t[2],10);
			}
		}
		else {
			var clr = this._customBackground ? this._customBackground : 'white';
			if (clr.toString().substr(0,4)=='rgb(') {
				var t= clr.substr(4,clr.length).split(',');
				r = parseInt(t[0],10);
				g = parseInt(t[1],10);
				b = parseInt(t[2],10);
			}
		}
		html[html.length] = '<tr><td title="'+$$$Text('Custom color')+'" id="'+this.makeId('sample')+'" style="border:1px solid '+bdr+';background:'+clr+';font-size:1px; width:16px;height:16px;" onclick="zenPage.getComponent('+this.index+').selectColor(\''+which+'\',\'custom\');">&nbsp;</td>';

		var press = 'onkeyup="zenPage.getComponent('+this.index+').customColorChange(\''+which+'\');"';
		html[html.length] = '<td>&nbsp;<input id="'+this.makeId('red')+'" type="text" style="border:none;background:#800000;color:#F0F0F0;width:40px;font-size:10px;" value="'+r+'" '+press+'/></td>';
		html[html.length] = '<td><input id="'+this.makeId('green')+'" type="text" style="border:none;background:#008000;color:#F0F0F0;width:40px;font-size:10px;" value="'+g+'" '+press+'/></td>';
		html[html.length] = '<td><input id="'+this.makeId('blue')+'" type="text" style="border:none;background:#000080;color:#F0F0F0;width:40px;font-size:10px;" value="'+b+'" '+press+'/></td>';
		html[html.length] = '<td style="width:20%;">&nbsp;</td>';

		html[html.length] = '</tr>';
		html[html.length] = '</table>';

		break;
	}

	div.innerHTML = html.join('');

	this._steps = 0;
	this._mode = 'show';
	this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
}

/// Show the drop down.
ClientMethod hideDropDown() [ Language = javascript ]
{
	if (this._timerId) {
		self.clearTimeout(this._timerId);
	}
	this._steps = 0;
	this._mode = 'hide';
	this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
}

/// Timer handler for hide/reveal of drop down.
ClientMethod reveal() [ Language = javascript ]
{
	var div = this.getDropDownDiv();
	this._steps++;
	var maxSteps = 20;

	if (this._mode == 'show') {
		if (this._steps >= maxSteps) {
			div.style.display = 'block';
			div.style.opacity = 1.0;
		}
		else {
			div.style.display = 'block';
			div.style.opacity = this._steps/maxSteps;
			this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
		}
	}
	else {
		if (this._steps >= maxSteps) {
			div.style.display = 'none';
			zenPage.endModal();
		}
		else {
			div.style.display = 'block';
			div.style.opacity = 1 - this._steps/maxSteps;
			this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
		}
	}
}

/// Select color in drop down.
ClientMethod selectColor(which, color) [ Language = javascript ]
{
	var div = this.findElement(which);
	var custom = (color=='custom');
	
	if (custom) {
		if (which=='color') {
			color = this._customColor ? this._customColor : 'white';
		}
		else {
			color = this._customBackground ? this._customBackground : 'white';
		}
	}

	switch(which) {
	case 'color':
		this.setStyle('color',color);
		break;
	case 'background':
		this.setStyle('background',color);
		break;
	}
	if (this.mode=='color') {
		var result = {background:this.value?this.value:''};
	}
	else {
		var result = this.parseStyle(this.value);
	}

	if (div) {
		switch(which) {
		case 'color':
			div.style.background = result.color;
			var fontDiv = this.findElement('font');
			if (fontDiv) {
				fontDiv.style.color = result.color==''?'#404040':result.color;
			}
			break;
		case 'background':
			div.style.background = result.background;
			var fontDiv = this.findElement('font');
			if (fontDiv) {
				fontDiv.style.background = result.background==''?'#C0C0C0':result.background;
			}
			break;
		} 
	}
	this.hideDropDown();
}

/// Select font in drop down.
ClientMethod selectFont(which, font) [ Language = javascript ]
{
	var div = this.findElement(which);

	switch(which) {
	case 'font':
		this.setStyle('font-family',font);
		break;
	}

	var result = this.parseStyle(this.value);
	if (div) {
		switch(which) {
		case 'font':
			div.style.fontFamily = result.fontFamily;
			div.innerHTML = result.fontFamily.toString().split(' ')[0];
			break;
		} 
	}
	this.hideDropDown();
}

/// Select font size in drop down.
ClientMethod selectFontSize(which, size) [ Language = javascript ]
{
	var div = this.findElement(which);

	switch(which) {
	case 'fontSize':
		this.setStyle('font-size',size);
		break;
	}
	
	var result = this.parseStyle(this.value);
	
	if (div) {
		switch(which) {
		case 'fontSize':
			div.innerHTML = result.fontSize;
			break;
		} 
	}
	this.hideDropDown();
}

/// Toggle text style.
ClientMethod textStyle(which) [ Language = javascript ]
{
	switch(which) {
	case 'bold':
		var el = this.findElement('bold');
		var sel = el.src.indexOf('boldButtonB.png')!=-1;
		this.setStyle('bold',!sel);
		var result = this.parseStyle(this.value);
		el.src = result.bold ? 'portal/boldButtonB.png' : 'portal/boldButton.png';
		break;
	case 'italic':
		var el = this.findElement('italic');
		var sel = el.src.indexOf('italicButtonB.png')!=-1;
		this.setStyle('italic',!sel);
		var result = this.parseStyle(this.value);
		el.src = result.italic ? 'portal/italicButtonB.png' : 'portal/italicButton.png';
		break;
	case 'underline':
		var el = this.findElement('underline');
		var sel = el.src.indexOf('underlineButtonB.png')!=-1;
		this.setStyle('underline',!sel);
		var result = this.parseStyle(this.value);
		el.src = result.underline ? 'portal/underlineButtonB.png' : 'portal/underlineButton.png';
		break;
	}
}

/// Set text align.
ClientMethod textAlign(which) [ Language = javascript ]
{
	var elLeft = this.findElement('alignLeft');
	var elCenter = this.findElement('alignCenter');
	var elRight = this.findElement('alignRight');

	switch(which) {
	case 'left':
		var sel = elLeft.src.indexOf('justLeftButtonB.png')!=-1;
		this.setStyle('align',sel?'':'left');
		break;
	case 'center':
		var sel = elCenter.src.indexOf('justCenterButtonB.png')!=-1;
		this.setStyle('align',sel?'':'center');
		break;
	case 'right':
		var sel = elRight.src.indexOf('justRightButtonB.png')!=-1;
		this.setStyle('align',sel?'':'right');
		break;
	}

	var result = this.parseStyle(this.value);
	elLeft.src = result.textAlign=='left' ? 'portal/justLeftButtonB.png' : 'portal/justLeftButton.png';
	elCenter.src = result.textAlign=='center' ? 'portal/justCenterButtonB.png' : 'portal/justCenterButton.png';
	elRight.src = result.textAlign=='right' ? 'portal/justRightButtonB.png' : 'portal/justRightButton.png';
}

/// Set a specific css value into the style values supported by this control.
ClientMethod setStyle(style, value) [ Language = javascript ]
{
	if (style!='') {
		var color = '';	// for color mode
		if (this.mode=='color') {
			var test = this.value ? ('background:' + this.value+';') : '';
		}
		else {
			var test = this.value;
		}
		switch (style) {
		case 'align':
			test += 'text-align:' + (value==''?'inherit':value) + ';';
			break;
		case 'bold':
			test += 'font-weight:' + (value?'bold':'normal') + ';';
			break;
		case 'underline':
			test += 'text-decoration:' + (value?'underline':'none') + ';';
			break;
		case 'italic':
			test += 'font-style:' + (value?'italic':'normal') + ';';
			break;
		case 'color':
			test += 'color:' + (value&&value!=''?value:'inherit') + ';';
			break;
		case 'background':
			test += 'background:' + (value&&value!=''?value:'inherit') + ';';
			break;
		case 'font-family':
			test += 'font-family:' + (value&&value!=''?value:'inherit') + ';';
			break;
		case 'font-size':
			test += 'font-size:' + (value&&value!=''?value:'inherit') + ';';
			break;
		default:
			break;
		}

		var result = this.parseStyle(test);

		var s = '';
		if (result.textAlign && result.textAlign!='inherit') {
			s += 'text-align: ' + result.textAlign+';';
		}
		if (result.bold) {
			s += 'font-weight: bold;';
		}
		if (result.italic) {
			s += 'font-style: italic;';
		}
		if (result.underline) {
			s += 'text-decoration: underline;';
		}
		if (result.color) {
			if (result.color&&result.color!==''&&result.color!='inherit') {
				s += 'color:'+result.color+ ';';
			}
		}
		if (result.background) {
			if (result.background&&result.background!==''&&result.background!='inherit') {
				s += 'background:'+ result.background + ';';
				color = result.background;	// for color mode
			}
		}
		if (result.fontFamily && result.fontFamily!='inherit') {
			s += 'font-family:'+(result.fontFamily&&result.fontFamily!==''?result.fontFamily:'inherit')+ ';';
		}	
		if (result.fontSize && result.fontSize!='inherit') {
			s += 'font-size:'+(result.fontSize&&result.fontSize!==''?result.fontSize:'inherit')+ ';';
		}
		if (this.mode=='color') {
			this.value = color;
		}
		else {
			this.value = s;
		}
		this.onchangeHandler();
	}
}

/// Split a css value into the style values supported by this control.
/// Return an object containing these values.
ClientMethod parseStyle(style) [ Language = javascript ]
{
	var result = {};
	var enc = this.getEnclosingDiv();
	var encStyle = enc.style.cssText;

	// use div to pull apart styles
	enc.style.cssText = style + 'display:none;';

	result.color = '';
	result.background = '';
	result.bold = false;
	result.italic = false;
	result.underline = false;
	result.fontSize = '';
	result.fontFamily = '';

	if (enc.style.color!='') {
		result.color = enc.style.color;
	}
	if (enc.style.backgroundColor!='') {
		result.background = enc.style.backgroundColor;
	}
	if (enc.style.textAlign!='') {
		result.textAlign = enc.style.textAlign;
	}
	if (enc.style.fontWeight!='') {
		result.bold = (enc.style.fontWeight == 'bold');
	}
	if (enc.style.fontStyle!='') {
		result.italic = (enc.style.fontStyle == 'italic');
	}
	if (enc.style.textDecoration!='') {
		result.underline = (enc.style.textDecoration == 'underline');
	}
	if (enc.style.fontFamily!='') {
		result.fontFamily = enc.style.fontFamily;
	}
	if (enc.style.fontSize!='') {
		result.fontSize = enc.style.fontSize;
	}

	// restore
	enc.style.cssText = encStyle;

	return result;
}

/// Clear the styles
ClientMethod resetStyles() [ Language = javascript ]
{
	this.setValue('');
	this.onchangeHandler();
}

/// Find the div element used to display the dropdown box.
ClientMethod getDropDownDiv() [ Language = javascript ]
{
	return self.document.getElementById('zenModalDiv');
}

/// Adjust the placement and size of the dropdown box based on
/// current screen geometry and scrolling conditions.
ClientMethod adjustDropdownPosition() [ Language = javascript ]
{
	// find position of input element
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find dropdown div',arguments);
	var input = this.getEnclosingDiv();
	zenASSERT(input,'Unable to find input element',arguments);

	var inputHeight = input.offsetHeight;
	var winScrollTop = zenGetPageScrollTop();
	var top,left;
	var controlOffsets = zenGetPageOffsets(input);
	left = controlOffsets.left;

	// SAM010 
	if (div.nativeHeight) div.style.height = div.nativeHeight + "px";
	var divHeight = Math.max(div.offsetHeight,224); // ensure we handle the height being 0
	
	var winHeight = zenGetWindowHeight();
	var uSpace = controlOffsets.top - winScrollTop;	
	var dSpace = winHeight - uSpace - inputHeight - 2;

	if (divHeight > dSpace) { // dropdown won't fit as is
		if (dSpace > uSpace) { // beneath is best option but must shorten menu
			if (!div.nativeHeight) div.nativeHeight = divHeight;
			div.style.height = (dSpace - 2) + 'px';
			top = controlOffsets.top + inputHeight;
		}
		else { // open dropdown upwards
			if (divHeight > uSpace) {
				if (!div.nativeHeight) div.nativeHeight = divHeight;
				div.style.height= (uSpace-2) + 'px';
			}
			top = controlOffsets.top - Math.max(div.offsetHeight,divHeight);
		}
	}
	else {  // Dropdown is fine where it is but needs to be in page coordinates
		top = controlOffsets.top + inputHeight;
	}

	var winWidth = zenGetWindowWidth();
	var winScrollLeft = zenGetPageScrollLeft();
	var divWidth = Math.max(div.offsetWidth,204);
	if (((left - winScrollLeft) + divWidth) > winWidth) {
		left = winScrollLeft + winWidth - divWidth;
		var scrollHeight = (document.documentElement ? Math.max(document.documentElement.scrollHeight,document.body.scrollHeight) : document.body.scrollHeight);
		if (scrollHeight > winHeight) {
			left -= 20;
		}
	}
	div.style.top = top + 'px';
	div.style.left = left + 'px';
}

ClientMethod onresizeHandler() [ Language = javascript ]
{
	if (this.isDropdownVisible) {
		this.adjustDropdownPosition();
	}
}

ClientMethod customColorChange(which) [ Language = javascript ]
{
	var ctrlRed = this.findElement('red');
	var ctrlGreen = this.findElement('green');
	var ctrlBlue = this.findElement('blue');
	var sample = this.findElement('sample');

	var red = parseInt(ctrlRed.value,10);
	if (ctrlRed.value==='') {
		red = 0;
	}
	else {
		red = isNaN(red) ? 0 : red;
		red = (red > 255) ? 255 : (red < 0) ? 0 : red;
		ctrlRed.value = red;
	}

	var green = parseInt(ctrlGreen.value,10);
	if (ctrlGreen.value==='') {
		green = 0;
	}
	else {
		green = isNaN(green) ? 0 : green;
		green = (green > 255) ? 255 : (green < 0) ? 0 : green;
		ctrlGreen.value = green;
	}

	var blue = parseInt(ctrlBlue.value,10);
	if (ctrlBlue.value==='') {
		blue = 0;
	}
	else {
		blue = isNaN(blue) ? 0 : blue;
		blue = (blue > 255) ? 255 : (blue < 0) ? 0 : blue;
		ctrlBlue.value = blue;
	}
	
	var color = 'rgb(' + red + ',' + green + ',' + blue + ')';
	sample.style.background = color;
	if (which=='color') {
		this._customColor = color;
	}
	else {
		this._customBackground = color;
	}
}

/// Change the displayed color set.
ClientMethod colorSetChange(which) [ Language = javascript ]
{
	var cb = this.findElement('colorSet');
	if (cb) {
		if (cb.value!=this.currColorSet) {
			this.currColorSet = cb.value;
			var div = this.findElement('colorTable');
			if (div) {
				div.innerHTML = this.getColorTableHTML(which);
			}
		}
	}
}

/// Return a HTML for the table of color choices for the current color set.
ClientMethod getColorTableHTML(which) [ Language = javascript ]
{
	var html = [];

	var stdColors = this.getColorSet();

	html[html.length] = '<table class="seColorTable">';
	for (var r = 0; r < stdColors.length; r++) {
		html[html.length] = '<tr>';
		for (var c = 0; c < stdColors[r].length; c++) {
			var color = stdColors[r][c];
			var bdr = (color=='inherit')?'black':'#D0D0D0';
			html[html.length] = '<td title="'+color+'" style="border:1px solid '+bdr+';font-size:1px; width:17px;height:17px;background:'+color+';" onclick="zenPage.getComponent('+this.index+').selectColor(\''+which+'\',\''+color+'\');">';
			html[html.length] = '&nbsp;';
			html[html.length] = '</td>';
		}
		html[html.length] = '</tr>';
	}
	html[html.length] = '</table>';
	return html.join('');
}

/// Return an array of (arrays of) the current color set.
ClientMethod getColorSet() [ Language = javascript ]
{
	// find color set index
	var index = -1;
	if (this.currColorSet!='') {
		for (var n = 0; n < this.colorSetNames.length; n++) {
			if (this.colorSetNames[n]==this.currColorSet) {
				index = n;
				break;
			}
		}
	}

	if (index < 0) {
		// built-in colors
		var colors = [
			[ 'inherit','#000000','#0000F0','#00F000','#F00000','#F000F0','#00F0F0','#F0F000'],
			[ '#C0C0C0','#404040','#4040D0','#40D040','#D04040','#D040D0','#40D0D0','#D0D040'],
			[ '#D0D0D0','#606060','#6060D0','#60D060','#D06060','#D060D0','#60D0D0','#D0D060'],
			[ '#E0E0E0','#808080','#8080FF','#80FF80','#FF8080','#FF80FF','#80F0F0','#FFFF80'],
			[ '#F0F0F0','#909090','#B0B0FF','#B0FFB0','#FFB0B0','#FFB0FF','#B0FFFF','#FFFFB0'],
			[ '#F4F4F4','#A0A0A0','#D0D0FF','#D0FFD0','#FFD0D0','#FFD0FF','#D0FFFF','#FFFFD0'],
			[ '#F8F8F8','#B0B0B0','#F0F0F8','#F0F8F0','#F8F0F0','#FFF0FF','#F0FFFF','#FFFFF0'],
			[ '#FFFFFF','#FEFEFE','#F0F0FF','#F0FFF0','#FFF0F0','#FFF8FF','#F8FFFF','#FFFFF8']
		];
	}
	else {
		var set = this.colorSets[index];
		var t = set.toString().split(';');

		// create a rows x cols grid of colors
		var rows = 8;
		var cols = 8;
		var colors = [];
		for (var r = 0; r < rows; r++) {
			var list = [];
			colors[r] = list;
			for (var c = 0; c < cols; c++) {
				var x = (c*rows)+r;
				list[c] = t[x] ? t[x] : '#FFFFFF';
			}
		}
	}

	return colors;
}

}
