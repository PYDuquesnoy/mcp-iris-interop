/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Color selection pane.
/// This component displays a grid containing various colored
/// cells.
Class %ZEN.Component.colorPane Extends component [ Deprecated, System = 3 ]
{

/// Current color selection.
Property value As %ZEN.Datatype.string [ InitialExpression = "#FFFFFF" ];

/// Which view of the color cube is showing: 1,2, or 3.
Property face As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Current selected slice: 0-based.
Property currSlice As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Row of current selected cell: 0-based.
Property currRow As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Column of current selected cell: 0-based.
Property currCol As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// onchange event handler:
/// This event is fired when the user selects a new color.
Property onchange As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// This event is fired when the mouse is double-clicked.
Property ondblclick As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
table.colorPane {
	background: silver;
	border: 1px solid black;
	font-family: arial;
	font-size: 0.8em;
	padding: 1px;
}

table.colorPane td {
	padding: 0px;
}

.colorPaneRotator {
	border: 1px black solid;
	cursor: pointer;
}

.colorPaneCell {
	border: 1px silver solid;
	cursor: pointer;
}

.colorPaneCellSelected1 {
	border: 1px green solid;
	cursor: pointer;
}
.colorPaneCellSelected2 {
	border: 1px red solid;
	cursor: pointer;
}
.colorPaneCellSelected3 {
	border: 1px blue solid;
	cursor: pointer;
}

</style>
}

Method %DrawHTML()
{
	#; this component is rendered using dynamic html
	#; color indicator
	&html<<div id="colorInd_#(..index)#"></div><br>>

	#; color cells
	&html<<div id="colorPane_#(..index)#"></div>>
	Quit
}

/// Client-method to draw contents of this pane.
ClientMethod renderContents() [ Language = javascript ]
{
	var div = this.window.document.getElementById('colorPane_' + this.index);
	zenASSERT(div,'Unable to find div element',arguments);
	zenASSERT((this.face>0&&this.face<7),'Out of range value for face',arguments);

	var hues = new Array('00','10','20','30','40','50','60','70','80','90','A0','B0','C0','D0','E0','F0','FF');
	var rgb,sv,rv,cv,xv;

	// color of current slice
	xv = hues[this.currSlice*1];
	rv = hues[this.currRow*1];
	cv = hues[this.currCol*1];

	// find side colors and calculate current value based on face
	switch (this.face*1) {
	case 1:
		rgb = cv + xv + rv;
		rgbBottom = '0000FF';
		rgbRight = 'FF0000';
		break;
	case 2:
		rgb = xv + rv + cv;
		rgbBottom = '00FF00';
		rgbRight = '0000FF';
		break;
	case 3:
		rgb = rv + cv + xv;
		rgbBottom = 'FF0000';
		rgbRight = '00FF00';
		break;
	}

	// update indicator
	this.renderIndicator();

	var html = new Array();
	html[html.length] = '<table class="colorPane" border="0" cellpadding="0" cellspacing="0">';

	// header
	for (var r = 0; r < hues.length; r++) {
		html[html.length] = '<tr>';
		// "slice" picker 
		sv = hues[r];

		// find slice color based on face
		switch (this.face*1) {
		case 1:
			rgb = '00' + sv + '00';
			break;
		case 2:
			rgb = sv + '00' + '00';
			break;
		case 3:
			rgb = '00' + '00' + sv;
			break;
		}

		// slice indicator
		html[html.length] = ((r==this.currSlice)?'<td style="font-size:1.2em;"><b>&#187;</b></td>':'<td>&nbsp;</td>');
		html[html.length] = '<td nowrap="1" class="colorPaneCell" width="16" onclick="zenPage.getComponent('+this.index+').selectSlice('+r+');">';
		html[html.length] = '<div style="background: #' + rgb + '; border:1px solid black;">&nbsp;</div>';
		html[html.length] = '</td>';

		if (0 == r) {
			// left spacer
			html[html.length] = '<td rowspan="' + hues.length + '" align="center" width="16" >&nbsp;</td>';
		}

		// cells
		rv = hues[r];
		for (var c = 0; c < hues.length; c++) {
			cv = hues[c];
			
			// find color based on face
			switch (this.face*1) {
			case 1:
				rgb = cv + xv + rv;
				break;
			case 2:
				rgb = xv + rv + cv;
				break;
			case 3:
				rgb = rv + cv + xv;
				break;
			}

			html[html.length] = '<td id="td_'+r+'_'+c+'_'+this.index+'" class="'+((r==this.currRow && c==this.currCol)?'colorPaneCellSelected'+this.face:'colorPaneCell')+'" width="16" onclick="zenPage.getComponent('+this.index+').selectCell('+r+','+c+');" ondblclick="zenPage.getComponent('+this.index+').dblclickHandler();" zenValue="'+rgb+'">';
			html[html.length] = '<div style="background: #' + rgb + '; border:1px solid black;">&nbsp;</div>';
			html[html.length] = '</td>';
		}

		if (0 == r) {
			// right spacer & rotator
			html[html.length] = '<td rowspan="' + hues.length + '" align="center" width="16" >&nbsp;</td>';
			html[html.length] = '<td rowspan="' + hues.length + '" class="colorPaneRotator" style="background: #'+rgbRight+'" align="center" width="16" onclick="zenPage.getComponent('+this.index+').rotateCube(1);">&nbsp;</td>';
		}

		html[html.length] = '</tr>';
	}

	// bottom spacer & rotator
	html[html.length] = '<tr><td colspan="' + (4+hues.length) + '" >&nbsp;</td></tr>';
	html[html.length] = '<tr><td colspan="3">&nbsp;</td><td colspan="' + hues.length + '" class="colorPaneRotator" style="background: #'+rgbBottom+'" align="center"  onclick="zenPage.getComponent('+this.index+').rotateCube(0);">&nbsp;</td><td>&nbsp;</td></tr>';

	html[html.length] = '</table>';

	div.innerHTML = html.join('');
}

/// Client-method to draw contents of the current color indicator.
ClientMethod renderIndicator() [ Language = javascript ]
{
	var div = this.window.document.getElementById('colorInd_' + this.index);
	zenASSERT(div,'Unable to find div element',arguments);

	// split value into rgb values;
	var r = 0, g = 0, b = 0;
	if ('' != this.value) {
		r = parseInt('0x' + this.value.substr(1,2));
		g = parseInt('0x' + this.value.substr(3,2));
		b = parseInt('0x' + this.value.substr(5,2));
	}

	var html = new Array();
	//html[html.length] = '<table width="100%" cellspacing="0" border="0"><form onsubmit="zenPage.getComponent('+this.index+').rgbChanged();">';
	html[html.length] = '<table width="100%" cellspacing="0" border="0">';
	html[html.length] = '<tr><td style="white-space:nowrap; background: #DDDDDD; border: 1px black solid; color: darkblue;">';
	html[html.length] = '&nbsp;R<input id="R_'+this.index+'" type="text" size="1" value="'+r+'" onchange="zenPage.getComponent('+this.index+').rgbChanged();">&nbsp;';
	html[html.length] = '&nbsp;G<input id="G_'+this.index+'" type="text" size="1" value="'+g+'" onchange="zenPage.getComponent('+this.index+').rgbChanged();">&nbsp;';
	html[html.length] = '&nbsp;B<input id="B_'+this.index+'" type="text" size="1" value="'+b+'" onchange="zenPage.getComponent('+this.index+').rgbChanged();">&nbsp;';
	html[html.length] = '</td>';

	// color for value display
	var clr = 'rgb('+(r<128?255:0)+','+(g<128?255:0)+','+(b<128?255:0)+')'

	html[html.length] = '<td style="width:90%; border: 1px black solid; color: '+clr+'; font-family:courier new; font-weight: bold; text-align:center; background:' + this.value + ';">'+this.value+'</td></tr>';
	html[html.length] = '</table>';
	div.innerHTML = html.join('');
}

/// User click on a cell.
ClientMethod selectCell(r, c) [ Language = javascript ]
{
	// find old cell
	var td = this.findElement('td_' + this.currRow + '_' + this.currCol);
	if (td) {
		td.className = 'colorPaneCell';
	}

	// update values 
	this.currRow = r;
	this.currCol = c;
	this.value = '';

	// find new cell
	var td = this.findElement('td_' + this.currRow + '_' + this.currCol);
	if (td) {
		td.className = 'colorPaneCellSelected'+this.face;

		// get logical value of cell
		this.value = '#' + td.getAttribute('zenValue');
	}
	this.renderIndicator()

	// invoke callback, if present
	zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

/// User has entered a new rgb value.
ClientMethod rgbChanged() [ Language = javascript ]
{
	var r = this.findElement('R').value * 1;
	var g = this.findElement('G').value * 1;
	var b = this.findElement('B').value * 1;
	
	r = isNaN(r) ? 0 : r;
	g = isNaN(g) ? 0 : g;
	b = isNaN(b) ? 0 : b;
	
	r = r < 0 ? 0 : r;
	g = g < 0 ? 0 : g;
	b = b < 0 ? 0 : b;
	r = r > 255 ? 255 : r;
	g = g > 255 ? 255 : g;
	b = b > 255 ? 255 : b;

	var rgb = '#' + (r<10?'0':'') + r.toString(16) + (g<10?'0':'') + g.toString(16) + (b<10?'0':'') + b.toString(16);
	this.setValue(rgb);
}

/// User click on a new slice
ClientMethod selectSlice(slice) [ Language = javascript ]
{
	this.currSlice = slice;
	this.render();
}

/// User click on a rotate button
ClientMethod rotateCube(direction) [ Language = javascript ]
{
	// direction: 0:down 1:right
	
	// rotate table (index by face)
	var table = new Array();
	table[1] = new Array(2,3);
	table[2] = new Array(3,1);
	table[3] = new Array(1,2);

	// find new face
	this.face = table[this.face][direction];

	// draw new face
	this.render();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// draw initial colorPane
	this.setValue(this.value);
}

/// Handler for double-clicks.
ClientMethod dblclickHandler() [ Language = javascript ]
{
	// invoke callback, if present
	zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		// value is of the form '#FFFFFF'
		// break value into closest rgb and redisplay
		this.value = value;
		var r = 0, g = 0, b = 0;
		if ('' != this.value) {
			r = parseInt('0x' + this.value.substr(1,2));
			g = parseInt('0x' + this.value.substr(3,2));
			b = parseInt('0x' + this.value.substr(5,2));
		}

		// find closest cell in current face
		// find side colors and calculate current value based on face
		switch (this.face*1) {
		case 1: //(RxB)
			this.currRow = Math.floor((r+1) / 16);
			this.currCol = Math.floor((b+1) / 16);
			this.currSlice = Math.floor((g+1) / 16);
			break;
		case 2: //(GxB)
			this.currRow = Math.floor((g+1) / 16);
			this.currCol = Math.floor((b+1) / 16);
			this.currSlice = Math.floor((r+1) / 16);
			break;
		case 3: //(RxG)
			this.currRow = Math.floor((r+1) / 16);
			this.currCol = Math.floor((g+1) / 16);
			this.currSlice = Math.floor((b+1) / 16);
			break;
		}
		this.render();
		break;

	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// Client-side method to set the value associated with this control.
ClientMethod setValue(value) [ Final, Language = javascript ]
{
	this.setProperty('value',value);
}

/// Client-side method to return the value associated with this control.
ClientMethod getValue() As %String [ Final, Language = javascript ]
{
	return this.getProperty('value');
}

}
