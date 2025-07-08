/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Cover view component.<br/>
/// This provides an way to display a set of options as "book covers".
/// Each cover is defined by a javaScript object or its string equivalent in JSON format.
Class %DeepSee.Component.coverView Extends (%ZEN.Component.component, %ZEN.Component.dataView) [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter DEFAULTENCLOSINGCLASS = "dsCoverDiv";

/// onselect event handler:
/// If defined, this event is fired when the user clicks on a cover.<br/>
Property onselect As %ZEN.Datatype.eventHandler;

/// onactivate event handler:
/// If defined, this event is fired when the user invokes an action on a cover.<br/>
Property onactivate As %ZEN.Datatype.eventHandler;

/// ongetdetails event handler:
/// If defined, this event is fired in order to get a list of popup details for a cover.<br/>
Property ongetdetails As %ZEN.Datatype.eventHandler;

/// Index (0-based) of selected cover.
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// True for cover editor page.
Property designMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Category to use for items with no category.
Property defaultCategory As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Others","%DeepSee")} ];

/// Zoom level (1,2 or 3).
Property zoomLevel As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 1 ];

/// Used by cover editor.
Property selectedElement As %ZEN.Datatype.string(ZENSETTING = 0);

/// onselectelement event handler:
/// Design mode only. If defined, this event is fired when the user clicks on a cover element.<br/>
Property onselectelement As %ZEN.Datatype.eventHandler;

/// ongetdata event handler:
/// If defined, this event is returns an array of items to be displayed within this component.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// ongetitemcontext event handler:
/// If defined, this returns a context object for the given cover. This is used to resolve $var
/// references within covers.
Property ongetitemcontext As %ZEN.Datatype.eventHandler;

/// Style applied to coverView background and category labels.
Property backgroundStyle As %ZEN.Datatype.style;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

.dsCoverDiv {
	overflow: auto;
	background: none;
	border: 1px solid #C0C0C0;
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

.bookCoverCategory {
	clear: both;
}

.bookCoverCategoryTitle {
	color: #606060;
	font-size: 20px;
	padding-top: 15px;
	padding-left: 15px;
	font-variant:small-caps;
}

.bookCoverSet {
}

.bookCover {
	position: relative;
	float: left;
	font-size: 10px;
	font-family: arial;
	font-style: normal;
	font-weight: normal;
	text-decoration: none;

	border: 4px solid rgba(240,240,240,0.8);
	box-shadow: 2px 2px 2px #808080;
	border-radius: 4px;
	width: 134px;
	height: 190px;
	font-family: arial;
	margin: 10px;
	overflow: hidden;
}

.bookCover:hover {
	box-shadow: 2px 2px 8px #8080FF;
}

.bookCover:active {
	box-shadow: 2px 2px 8px blue, -2px -2px 8px blue;
}

.bookCover-activate,
.bookCover-activatePopup {
	position:absolute;
	z-index: 20;
	font-size: 10px;
	background: white;
	padding: 6px;
	border: 1px solid #808080;
	border-radius: 25px;
	left: 42px;
	top: 136px;
	box-shadow: 2px 2px 4px #808080;
}

.bookCover-activate {
	display: none;
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

.bookCover-activatePopup {
	z-index: 120;
}

.bookCover-activate:hover, .bookCover-activatePopup:hover {
	background: #FFEEAA;
}

.bookCoverBackground {
	position: absolute;
	width: 134px;
	height: 190px;
}

.bookCoverHeader {
	position: absolute;
	top: 0px;
	left: 0px;
	right: 0px;
	font-family: arial;
	font-size: 8pt;
	text-align: center;
	background: rgb(53,107,141);
	color: #F0F0F0;
	z-index: 10;
	overflow: hidden;
}

.bookCoverTitle {
	position: absolute;
	top: 30px;
	left: 0px;
	right: 0px;
	font-family: arial;
	font-size: 11pt;
	color: #404040;
	text-align: center;
	z-index: 6;
	overflow: hidden;
	word-break: hyphenate;
}

.bookCoverSubtitle {
	position: absolute;
	top: 150px;
	left: 0px;
	right: 0px;
	font-family: arial;
	font-size: 8pt;
	color: #606060;
	text-align: center;
	z-index: 5;
	overflow: hidden;
}

.bookCoverFooter {
	position: absolute;
	bottom: 0px;
	left: 0px;
	right: 0px;
	font-family: arial;
	font-size: 8pt;
	text-align: center;
	background: rgb(53,107,141);
	color: #F0F0F0;
	z-index: 9;
	overflow: hidden;
}

.bookCoverImage {
	position: absolute;
	top: 70px;
	left: 0px;
	right: 0px;
	text-align: center;
	font-family: arial;
	font-size: 8pt;
	color: #404040;
	z-index: 1;
}

/* selector: indicates current element */
.bookCoverSelector {
	z-index: 100;
	position: absolute;
	border: 1px dotted #404040;
	width: 100px;
	height: 25px;
	background: none;
}

/* sizing handle for selector */
.bookCoverSizeHandle {
	z-index: 101;
	position: absolute;
	border: 1px solid white;
	border-radius: 2px;
	background: black;
	width: 4px;
	height: 4px;
}

.bookCover-mouseTrap {
	position: fixed;
	top: 0px;
	left: 0px;
	display: none;
	opacity: 0.0;
	background: black;
	z-index: 100;

	-webkit-transition-property: opacity,height;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity,height;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.bookCover-popup {
	position: fixed;
	font-size: 15px;
	font-family: arial;
	font-style: normal;
	font-weight: normal;
	text-decoration: none;
	top: 0px;
	left: 0px;
	width: 0px;
	display: block;
	opacity: 0.0;
	background: white;
	z-index: 101;
	border: 6px solid rgb(23,87,121);
	border-radius: 5px;
	box-shadow: 2px 2px 4px #F0F0F0;

	-webkit-transition-property: opacity,height;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity,height;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.bookCover-popupLabel {
	font-size: 10px;
	font-weight: bold;
	color: #606060;
	padding-top: 5px;
}

.bookCover-popupValue {
	font-size: 14px;
	color: #404040;
}

.bookCover-popupButton {
	opacity: 0.8;
}

.bookCover-popupButton:hover {
	opacity: 1.0;
}

.bookCover-popupButton:active {
	border-radius: 5px;
	background: #808080;
	box-shadow: 2px 2px 8px #808080,-2px -2px 8px #808080;
}

.bookCover-popupAction {
	opacity: 0.8;
	padding: 2px;
	padding-right: 20px;
	font-size: 18px;
	font-weight: bold;
	color: #202060;
}

.bookCover-popupAction:hover {
	opacity: 1.0;
}

.bookCover-popupAction:active {
	text-shadow: 2px 2px 8px #808080,-2px -2px 8px #808080;
}

</style>
}

Method %DrawHTML()
{
	Do ##super()
}

/// Client-side method to render this control.
ClientMethod renderContents() [ Language = javascript ]
{
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	// build DHTML for the component
	var html = [];

	// mouse-trap div
	html[html.length] = '<div id="'+this.makeId('mouseTrap')+'" class="bookCover-mouseTrap" onclick="zenPage.getComponent('+this.index+').hidePopup();">';
	html[html.length] = '</div>';

	// popup div
	html[html.length] = '<div id="'+this.makeId('popup')+'" class="bookCover-popup" style="">';
	html[html.length] = '</div>';

	// sort items
	var categories = {};
	var data = this.getModel();
	if (data) {
		if (this.designMode) {
			var n = 0;
			var book = data[n];
			var cat = ' ';
			if (!categories[cat]) {
				categories[cat] = [];
			}
			categories[cat][categories[cat].length] = {index:n, book:book};
		}
		else {
			// make sure default is always listed first
			categories['<none>'] = [];

			for (var n = 0; n < data.length; n++) {
				var book = data[n];
				var cat = book.category&&book.category!=='' ? book.category : '<none>';
				if (!categories[cat]) {
					categories[cat] = [];
				}
				categories[cat][categories[cat].length] = {index:n, book:book};
			}
		}
	}

	// display by category
	for (var cat in categories) {
		if (categories[cat].length) {
			var catName = (cat=='<none>') ? this.defaultCategory : cat;
			html[html.length] = '<div class="bookCoverCategory">';
			html[html.length] = '<div class="bookCoverCategoryTitle" style="'+this.backgroundStyle+'">'+zenEscapeXML(catName)+'</div>';
			html[html.length] = '<div class="bookCoverSet">';
			for (var n = 0; n < categories[cat].length; n++) {
				var info = categories[cat][n];
				html[html.length] = this.getCoverArt(info.index,info.book,false);
			}
			html[html.length] = '</div>';
			html[html.length] = '</div>';
		}
	}

	// render
	var div = this.getEnclosingDiv();
	div.innerHTML = html.join('');
	var info = this.parseStyle(this.backgroundStyle);

	for (var p in info) {
		switch (p) {
		case 'color':
		case 'backgroundColor':
			div.style[p] = info[p] ? info[p] : '';
			break;
		default:
			break;
		}
	}

	// update selection
	if (this.designMode && this.selectedElement) {
		this.selectElement(this.selectedElement,false);
	}
}

/// Get HTML for one book cover.
/// A spec is a ^-delimited string of rendering instructions.
/// Each piece takes the form: "type:header;text:ABC;style:prop:val;"
/// style is always at the end.
ClientMethod getCoverArt(index, book, popupMode) [ Language = javascript ]
{
	popupMode = zenGet(popupMode,false);
	var html = [];

	var title = book.title ? book.title : '';
	var tooltip = book.tooltip ? book.tooltip : '';
	var spec = book.spec ? book.spec : '';

	var specObject = this.evalSpec(spec);
	if (typeof specObject == 'string') {
		return specObject;
	}
	else if (!specObject || typeof specObject != 'object') {
		return 'Invalid cover spec';
	}

	var context = null;
	if (this.ongetitemcontext!='') {
		context = zenInvokeCallbackMethod(this.ongetitemcontext,this,'ongetitemcontext','index',index);
	}

	var style = '';
	if (this.zoomLevel>2) {
		var style = '-webkit-transform:scale(2.5,2.5);top:150px;left:125px;';
		style += '-moz-transform:scale(2.5,2.5);top:150px;left:125px;';
		style += '-ms-transform:scale(2.5,2.5);top:150px;left:125px;';
	}
	else if (this.zoomLevel>1) {
		var style = '-webkit-transform:scale(1.5,1.5);top:50px;left:50px;';
		style += '-moz-transform:scale(1.5,1.5);top:50px;left:50px;';
		style += '-ms-transform:scale(1.5,1.5);top:50px;left:50px;';
	}

	html[html.length] = '<div class="bookCover" id="'+this.makeId('cover_'+index)+'" style="'+style+'"';
	if (!popupMode) {
		html[html.length] = ' title="'+zenEscapeXML(tooltip)+'" onclick="zenPage.getComponent('+this.index+').itemClick('+index+');" onmouseover="zenPage.getComponent('+this.index+').showActivateButton('+index+');" onmouseout="zenPage.getComponent('+this.index+').hideActivateButton('+index+');"';
	}
	else {
		html[html.length] = ' onclick="zenPage.getComponent('+this.index+').activateCover(event,'+index+',\'navigate\');"';
	}
	html[html.length] = '>';

	// "activate button" -- this is hidden until the cover is active
	if (popupMode || (!this.designMode && this.onactivate)) {
		var cls = popupMode ? 'bookCover-activatePopup' : 'bookCover-activate'; 
		html[html.length] = '<div id="'+this.makeId('activate:'+(popupMode?-1:index))+'" class="'+cls+'" onclick="zenPage.getComponent('+this.index+').activateCover(event,'+index+',\'navigate\');" >';
		html[html.length] = '<image src="deepsee/ds2_arrow_east_44.png"/>';
		html[html.length] = '</div>';
	}

	// div used to indicate current selection
	if (this.designMode && index==0) {
		html[html.length] = '<div id="'+this.makeId('selector')+'" style="display:none;" class="bookCoverSelector" onmousedown="zenPage.getComponent('+this.index+').selectorMouseDown(event);" >';
		html[html.length] = '</div>';
	}
	// handles for selector
	for (var n = 0; n < 4; n++) {
		html[html.length] = '<div id="'+this.makeId('sizeHandle:'+n)+'" style="display:none;" class="bookCoverSizeHandle" onmousedown="zenPage.getComponent('+this.index+').sizeHandleMouseDown(event);" >';
		html[html.length] = '</div>';
	}

	// interpret spec

	// background
	if (specObject.background) {
		var item = specObject.background;
		var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'background\');"';
		html[html.length] = '<div id="'+this.makeId('background:'+index)+'" class="bookCoverBackground" style="'+zenGet(item.style)+'" '+click+'>';
		if (zenGet(item.src)!='') {
			var istyle = zenGet(item.imageStyle);
			html[html.length] = '<image style="'+istyle+'" src="'+item.src+'"/>';
		}
		else {
			html[html.length] = '&nbsp;';
		}
		html[html.length] = '</div>';
	}

	// header
	if (specObject.header) {
		var item = specObject.header;
		var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'header\');"';
		html[html.length] = '<div id="'+this.makeId('header:'+index)+'" class="bookCoverHeader" style="'+zenGet(item.style)+'" '+click+'>'+this.getText(item.text,context)+'</div>';
	}

	// footer
	if (specObject.footer) {
		var item = specObject.footer;
		var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'footer\');"';
		html[html.length] = '<div id="'+this.makeId('footer:'+index)+'" class="bookCoverFooter" style="'+zenGet(item.style)+'" '+click+'>'+this.getText(item.text,context)+'</div>';
	}

	// foreground image
	if (specObject.image) {
		var item = specObject.image;
		if (zenGet(item.src)!='') {
			var istyle = 'width:96px;height:96px;' + zenGet(item.imageStyle);
			var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'image\');"';
			html[html.length] = '<div id="'+this.makeId('image:'+index)+'" class="bookCoverImage" style="'+zenGet(item.style)+'" '+click+'><image style="'+istyle+'" src="'+item.src+'"/>'+(zenGet(item.text,context)==''?'':('<br/>'+this.getText(item.text,context)))+'</div>';
		}
	}

	// subtitle
	if (specObject.subtitle) {
		var item = specObject.subtitle;
		var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'subtitle\');"';
		html[html.length] = '<div id="'+this.makeId('subtitle:'+index)+'" class="bookCoverSubtitle" style="'+zenGet(item.style)+'" '+click+'>'+this.getText(item.text,context)+'</div>';
	}

	// title
	if (specObject.title) {
		var item = specObject.title;
		var click = !this.designMode ? '' : 'onclick="zenPage.getComponent('+this.index+').selectElement(\'title\');"';
		html[html.length] = '<div id="'+this.makeId('title:'+index)+'" class="bookCoverTitle" style="'+zenGet(item.style)+'" '+click+'>'+this.getText(item.text,context)+'</div>';
	}

	html[html.length] = '</div>';

	return html.join('');
}

/// Get text to display.
/// Resolve any $vars using the context array if present.
ClientMethod getText(text, context) [ Internal, Language = javascript ]
{
	text = zenGet(text);
	if (text==='') {
		text = '&nbsp;';
	}
	else if (context && context[text]) {
		text = zenEscapeXML(context[text]);
	}
	else {
		text = zenEscapeXML(text);
	}
	return text;
}

/// User click on an item.
ClientMethod itemClick(idx) [ Internal, Language = javascript ]
{
	var info = null;
	var data = this.getModel();
	if (data) {
		info = data[parseInt(idx)];
	}

	var ok = this.selectCover(idx);
	if (ok && !this.designMode && this.onactivate && zenGet(info.active,1)) {
		this.showPopup(idx);
	}
}

/// Given its index (0-based), return the book object for a cover.
ClientMethod getCoverObject(index) [ Language = javascript ]
{
	var book = null;
	var data = this.getModel();
	if (data) {
		book = data[index];
	}
	return book;
}

/// Given its index (0-based), set the book object for a cover.
ClientMethod setCoverObject(index, book) [ Language = javascript ]
{
	var data = this.getModel();
	if (data) {
		data[index] = book;
		this.render();
		this.selectCover(this.selectedIndex,true);
	}
	return book;
}

/// Select a cover given its index (0-based).
ClientMethod selectCover(index, force) [ Language = javascript ]
{
	if (this.selectedIndex>=0) {
		// select
		var div = this.findElement('cover_'+this.selectedIndex);
		if (div) {
			div.style.border = '';
		}
	}
	this.selectedIndex = parseInt(index);
	var ok = true;
	if (this.onselect!='' && !force) {
		ok = zenInvokeCallbackMethod(this.onselect,this,'onselect','index',index);
	}

	if (this.selectedIndex>=0) {
		// select
		var div = this.findElement('cover_'+this.selectedIndex);
		if (div && !this.designMode) {
			div.style.border = '4px solid #FFEEAA';
		}
	}

	return ok;
}

/// Invoke the given action for the given cover.
ClientMethod activateCover(evt, index, action) [ Language = javascript ]
{
	evt = evt ? evt : event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	this.selectedIndex = parseInt(index);
	var ok = true;
	if (this.onactivate!='') {
		ok = zenInvokeCallbackMethod(this.onactivate,this,'onactivate','index',index,'action',action);
		this.hidePopup();
	}
	return ok;
}

/// Convert a spec string into a spec object.
ClientMethod evalSpec(spec) [ Language = javascript ]
{
	var specObject = null;
	if (spec == '') {
		specObject = {};
	}
	else if (typeof spec == 'object') {
		specObject = spec;
	}
	else {
		// evaluate json
		try {
			eval('specObject = ' + spec);
		}
		catch(ex) {
			specObject = ex.message;
		}
	}
	return specObject;
}

/// Convert a display spec back into a json string.
ClientMethod specToString(specObj) [ Language = javascript ]
{
	var specList = [];
	var list = ['background','header','title','image','subtitle','footer'];
	var attrs = ['text','style','src','imageStyle'];

	for (var n = 0; n < list.length; n++) {
		var name = list[n];
		if (specObj[name]) {
			var spec = [];
			for (var a = 0; a < attrs.length; a++) {
				if (zenGet(specObj[name][attrs[a]])!='') {
					spec[spec.length] = attrs[a]+':\'' + this.escapeJS(specObj[name][attrs[a]]) + '\'';
				}
			}
			specList[specList.length] = name+': {' + spec.join(',') + '}';
		}
	}

	// assemble
	return '{' + specList.join(',') + '}';
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'backgroundStyle':
		this[property] = value;
		//this.getEnclosingDiv().style.cssText = this.backgroundStyle;
		this.render();
		break;

	case 'zoomLevel':
		this[property] = value;
		this.render();
		break;
	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// Notification that the dataController associated with this dataView
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
	case 'chartUpdate':
		this.renderContents();
		break;
	case 'seriesChange':
	case 'modelChange':
		this.renderContents();
		break;
	}
}

/// Select an element within the cover.
ClientMethod selectElement(which, notify) [ Language = javascript ]
{
	notify = zenGet(notify,true);
	this.selectedElement = which;
	var targetDiv = null;

	switch(which) {
	case 'title':
		targetDiv = this.findElement('title:'+this.selectedIndex);
		break;
	case 'subtitle':
		targetDiv = this.findElement('subtitle:'+this.selectedIndex);
		break;
	case 'image':
		targetDiv = this.findElement('image:'+this.selectedIndex);
		break;
	case 'header':
		targetDiv = this.findElement('header:'+this.selectedIndex);
		break;
	case 'footer':
		targetDiv = this.findElement('footer:'+this.selectedIndex);
		break;
	case 'background':
		targetDiv = this.findElement('background:'+this.selectedIndex);
		break;
	}

	// n.b. second click will be on target and *which* will be ''
	this.moveSelector(targetDiv);
	if (notify) {
		zenInvokeCallbackMethod(this.onselectelement,this,'onselectelement','which',which);
	}
}

/// Move the element selector.
ClientMethod moveSelector(targetDiv) [ Internal, Language = javascript ]
{
	var div = this.findElement('selector');
	if (!div) return;

	var szHandle = [];
	for (var n = 0; n < 4; n++) {
		szHandle[n] = this.findElement('sizeHandle:'+n);
	}

	if (!targetDiv) {
		div.style.display = 'none';
		for (var n = 0; n < 4; n++) {
			if (szHandle[n]) {
				szHandle[n].style.display = 'none';
			}
		}
	}
	else {
		div.style.display = 'block';
		var top = targetDiv.offsetTop;
		var left = targetDiv.offsetLeft;
		var hgt = targetDiv.offsetHeight;
		var wid = targetDiv.offsetWidth;
		if (left < 0) {
			top += 4;
			left += 4;
		}

		div.style.top = top + 'px';
		div.style.left = left + 'px';
		div.style.width = wid + 'px';
		div.style.height = hgt + 'px';

		for (var n = 0; n < 4; n++) {
			var adj = 3;
			if (szHandle[n]) {
				szHandle[n].style.display = 'block';
				switch(n) {
				case 0:
					szHandle[n].style.top = top-adj + 'px';
					szHandle[n].style.left = left-adj + 'px';
					//szHandle[n].style.cursor = 'se-resize';
					break;
				case 1:
					szHandle[n].style.top = top-adj + 'px';
					szHandle[n].style.left = left+wid-adj + 'px';
					//szHandle[n].style.cursor = 'ne-resize';
					break;
				case 2:
					szHandle[n].style.top = top+hgt-adj + 'px';
					szHandle[n].style.left = left+wid-adj + 'px';
					//szHandle[n].style.cursor = 'se-resize';
					break;
				case 3:
					szHandle[n].style.top = top+hgt-adj + 'px';
					szHandle[n].style.left = left-adj + 'px';
					//szHandle[n].style.cursor = 'ne-resize';
					break;
				}
			}
		}
	}
}

/// User has clicked on the element selector.
ClientMethod selectorMouseDown(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	this.selectElement('');
}

/// Utility method. Escape a javascript string.
ClientMethod escapeJS(str) [ Language = javascript ]
{
	return str.toString().replace(/\'/g,'\\\'');
}

/// Get the model used to drive the view.
ClientMethod getModel() [ Language = javascript ]
{
	// See if there is user-supplied data to drive the control
	var model = null;
	if (this.ongetdata!='') {
		model = zenInvokeCallbackMethod(this.ongetdata,this,'ongetdata');
	}
	else {
		// if not see if there is a data controller
		var controller = this.getController();
		if (null == controller) {
			// try to connect to dataController
			this.connectToController();
			controller = this.getController();
		}
		if (controller) {
			if (controller.getContentObject) {
				// json provider-- use children array directly
				var data = controller.getContentObject();
				var model = data&&data.children ? data.children : null;
			}
			else {
				// build model from controller data!!!
			}
		}
	}
	return model;
}

/// Show a popup info box for the current item.
ClientMethod showPopup(index) [ Internal, Language = javascript ]
{
	// get details
	// {key:'title', caption:'Name', value:'My Book'}
	var details = [];
	if (this.ongetdetails) {
		details = zenInvokeCallbackMethod(this.ongetdetails,this,'ongetdetails','index',index);
	}
	// find title and other details
	var title = '';
	for (var n = 0; n < details.length; n++) {
		var detail = details[n];
		switch(detail.key) {
		case 'title':
			title = detail.value;
			details.splice(n,1);
			break;
		}
	}

	var trapDiv = this.findElement('mouseTrap');
	var popupDiv = this.findElement('popup');

	trapDiv.style.display = 'block';
	trapDiv.style.opacity = 0.6;
	trapDiv.style.width = '10000px';
	trapDiv.style.height = '10000px';

	var width = 500;
	var height = 320;
	var x = (zenGetWindowWidth()-width)/2;
	var y = (zenGetWindowHeight()-height)/2;

	popupDiv.style.left = x + 'px';
	popupDiv.style.top = y + 'px';
	popupDiv.style.width = width + 'px';
	popupDiv.style.height = height + 'px';
	popupDiv.style.overflow = 'hidden';
	popupDiv.style.border = '';
	popupDiv.style.display = 'block';

	// create HTML for the popup
	var html = [];

	// title bar
	html[html.length] = '<table style="position:absolute;top:0px;background:rgb(53,107,141);width:'+width+'px;">';
	html[html.length] = '<tr>'
	if (title) {
		html[html.length] = '<td style="color:#F0F0F0;font-weight:bold;padding:2px;">' + zenEscapeXML(title) + '</td>';
	}
	html[html.length] = '<td style="text-align:right;"><image class="bookCover-popupButton" src="deepsee/ds2_x_44_w.png" style="padding:4px;width:16px;height:16px;" title="'+$$$Text('Close this window')+'" onclick="zenPage.getComponent('+this.index+').hidePopup();"/></td>';
	html[html.length] = '</tr>'
	html[html.length] = '</div>';

	// "cover"
	var book = null;
	var data = this.getModel();
	if (data) {
		book = data[index];
		if (book) {
			html[html.length] = '<div style="position:absolute;top:30px;width:100px;">';
			html[html.length] = this.getCoverArt(index,book,true);
			html[html.length] = '</div>';
		}
	}

	var iconOptions = {};

	// details
	html[html.length] = '<div style="position:absolute;top:40px;left:180px;">';
	for (var n = 0; n < details.length; n++) {
		var detail = details[n];
		// $keys are used to control options
		if (detail.key.toString().charAt(0)=='$') {
			iconOptions[detail.key] = detail.value;
		}
		else {
			html[html.length] = '<div class="bookCover-popupLabel">' + zenEscapeXML(detail.caption) + '</div>';
			html[html.length] = '<div class="bookCover-popupValue">' + zenEscapeXML(detail.value) + '</div>';
		}
	}
	html[html.length] = '</div>';

	// option bar
	var options = [];
	if (zenGet(iconOptions.$navigate,true)) {
		options[options.length] = {key:'navigate', caption:$$$Text('View this item'), image:'deepsee/ds2_magnify_44.png'};
	}
	if (zenGet(iconOptions.$configure,true)) {
		options[options.length] = {key:'configure', caption:$$$Text('Configure this item'),image:'deepsee/ds2_gear_44.png'};
	}
	if (zenGet(iconOptions.$designCover,true)) {
		options[options.length] = {key:'designCover', caption:$$$Text('Change the cover design'),image:'deepsee/ds2_bookmarks_44.png'};
	}
	if (zenGet(iconOptions.$addFavorite,true)) {
		options[options.length] = {key:'addFavorite', caption:$$$Text('Add this item to Favorites'), image:'deepsee/ds2_star_44.png'};
	}
	if (zenGet(iconOptions.$remove,true)) {
		options[options.length] = {key:'remove', caption:$$$Text('Delete this item'), image:'deepsee/ds2_x_44.png'};
	}
	html[html.length] = '<div style="background:#F0F0F0;position:absolute;height:34px;top:'+(height-34)+'px;width:'+width+'px;">&nbsp;&nbsp;&nbsp;';
	for (var n = 0; n < options.length; n++) {
		var option = options[n];
		html[html.length] = '<image class="bookCover-popupButton" src="'+option.image+'" style="padding:4px;width:24px;height:24px;" title="'+option.caption+'" onclick="zenPage.getComponent('+this.index+').activateCover(event,'+index+',\''+option.key+'\');"/>&nbsp;&nbsp;';
	}
	html[html.length] = '</div>';

	popupDiv.innerHTML = html.join('');
	popupDiv.style.display = 'block';
	popupDiv.style.opacity = 1.0;
}

/// Show a popup info box for the current item.
ClientMethod hidePopup() [ Internal, Language = javascript ]
{
	// set opacity to cause fade in/out
	var trapDiv = this.findElement('mouseTrap');
	var popupDiv = this.findElement('popup');

	trapDiv.style.height = '0px';
	trapDiv.style.opacity = 0.0;

	popupDiv.style.height = '0px';
	popupDiv.style.opacity = 0.0;

	if (zenPage.cssLevel<3) {
		trapDiv.style.display = 'none';
		popupDiv.style.display = 'none';
	}
}

/// Show the activate button for the given cover.
ClientMethod showActivateButton(index) [ Internal, Language = javascript ]
{
	var div = this.findElement('activate:'+index);
	if (div) {
		div.style.display = 'block';
		div.style.opacity = 1.0;
	}
}

/// Hide the activate button for the given cover.
ClientMethod hideActivateButton(index) [ Internal, Language = javascript ]
{
	var div = this.findElement('activate:'+index);
	if (div) {
		if (zenPage.cssLevel<3) {
			div.style.display = 'none';
		}
		div.style.opacity = 0.0;
	}
}

/// Utility method. Split a css value into individual style values.
/// Return an object containing these values.
ClientMethod parseStyle(style) [ Language = javascript ]
{
	// JMD1128: copy of logic in navigator
	var result = {};
	var enc = this.getEnclosingDiv();
	var encStyle = enc.style.cssText;

	// use div to pull apart styles
	enc.style.cssText = style + 'visibility:hidden;';

	result.bold = false;
	result.italic = false;
	result.underline = false;
	result.shadow = false;
	result.smallCaps = false;

	// list of styles with default logic
	var list = ['color','backgroundColor','textAlign','fontFamily','fontSize','margin','padding','opacity'];

	for (var n = 0; n < list.length; n++) {
		result[list[n]] = '';
		if (enc.style[list[n]]!=='') {
			result[list[n]] = enc.style[list[n]];
		}
	}

	if (enc.style.fontWeight!='') {
		result.bold = (enc.style.fontWeight == 'bold');
	}
	if (enc.style.fontStyle!='') {
		result.italic = (enc.style.fontStyle == 'italic');
	}
	if (enc.style.fontVariant!='') {
		result.smallCaps = (enc.style.fontVariant == 'small-caps');
	}
	if (enc.style.textDecoration!='') {
		result.underline = (enc.style.textDecoration == 'underline');
	}
	if (enc.style.textShadow!='') {
		result.shadow = (enc.style.textShadow != 'inherit') && (enc.style.textShadow != '');
	}

	// restore
	enc.style.cssText = encStyle;

	return result;
}

}
