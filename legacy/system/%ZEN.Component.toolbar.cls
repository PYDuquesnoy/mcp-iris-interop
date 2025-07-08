/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements a simple HTML5 toolbar component.<br/>
/// This is an HTML5 component; it will only correctly run on HTML5 compliant browsers.
/// 
/// A toolbar can show drop down menu choice, tabs, messages, choice boxes and other items.
/// It is controlled by a JSON data model.
/// 
Class %ZEN.Component.toolbar Extends (component, dataView) [ Deprecated, System = 3 ]
{

/// Do not include in "form" module.
Parameter SYSMODULE;

Parameter DEFAULTENCLOSINGCLASS = "ztb-menu";

/// onselect event handler:
/// If defined, this event is fired when
/// the user clicks on a item within the menu.
/// This is passed: <var>key</var>, <var>action</var>, and <var>targetId</var>
/// from the data element associated with the menu choice.
Property onselect As %ZEN.Datatype.eventHandler;

/// onchange event handler:
/// Notification that a control within the toolbar (such as a "choice") has changed value.
/// This event is passed 3 arguments: <var>key</var>, <var>value</var>, and <var>final</var>.
/// <var>final</var> is true when a value is finished changing.
Property onchange As %ZEN.Datatype.eventHandler;

/// ongetdata event handler:
/// If defined, this event is returns an array of items to be displayed within the menu.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// onpagechange event handler:
/// If defined, this event is fired when
/// the user selects a new page number from a "pages" item.
/// This is passed: <var>key</var> and <var>page</var> (selected page, 1-based).
/// from the data element associated with the menu choice.
Property onpagechange As %ZEN.Datatype.eventHandler;

/// Additional style to apply to items in the menu.<br/>
Property style As %ZEN.Datatype.style;

/// Additional style to apply to images in the menu.<br/>
/// Use this to change the size of images.
Property imageStyle As %ZEN.Datatype.style;

/// Index (0-based) of selected item within the top-level menu.<br/>
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Index (0-based) first top-level item to display when scrolled.<br/>
Property scrollOffset As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

/* wrapper */
.ztb-menu {
	position: relative;
	width: 800px;
	height: 10px;
	white-space: nowrap;
	font-family: arial;
}

/* main menu bar */
.ztb-menuBar {
	position: relative;

	background: rgb(53,107,141);
	background: -moz-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* FF3.6+ */
	background: -webkit-linear-gradient(top,  rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* IE10+ */
	background: linear-gradient(top, rgb(53,107,141) 0%,rgb(53,107,161) 40%,rgb(53,107,161) 60%,rgb(53,107,141) 100%); /* W3C */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#cedce7', endColorstr='#596a72',GradientType=0 ); /* IE6-9 */
}

table.ztb-pages {
	padding: 4px;
	padding-left: 6px;
	padding-right: 6px;
	margin: 0px;
	color: #fdfdfd;
	text-decoration: none;
	white-space: nowrap;
	font-size: 12px;
}

td.ztb-pageNo {
	padding-left: 3px;
	padding-right: 3px;
	opacity: 0.75;
	height: 26px;
	border-radius: 3px;
	min-width: 16px;
	text-align: center;
}

td.ztb-pageNoCurr {
	padding-left: 3px;
	padding-right: 3px;
	font-weight: bold;
	height: 26px;
	background: rgb(100,100,100);/*fallback*/
	background: rgba(100,100,100,0.2);
	border-radius: 3px;
	min-width: 16px;
	text-align: center;
}

td.ztb-pageNo:hover,td.ztb-pageNoCurr:hover {
	background: #F0F0F0;
	color: #404040;
}

td.ztb-pageNo:active {
	background: white;
	color: black;
	opacity: 1.0;
	box-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

.ztb-menuItem-1,
.ztb-menuItemSelected-1 {
	position: absolute;
	top: 0px;
	left: 0px;
	overflow: hidden;

	margin: 0px;
	padding: 0px;
	-moz-user-select: -moz-none;
	-khtml-user-select: none;
	-webkit-user-select: none;
	user-select: none;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.ztb-menuItemSelected-1 {
	background: white;
	border-bottom: 1px solid white;
}

.ztb-menuItemSelected-1
.ztb-caption-1 {
	color: #202020;
}

.ztb-menuItemSelected-1
.ztb-caption-1:hover {
	color: #000000;
}

.ztb-menuItemInner {
	padding: 0px;
}

.ztb-hz-separator {
	position: absolute;
	top: 0px;
	bottom: 0px;
	width: 2px;
	background: #808080;
}

.ztb-message,
.ztb-caption-1,
.ztb-caption-2,
.ztb-caption-3 {
	display: block;
	padding: 4px;
	padding-left: 6px;
	padding-right: 6px;
	margin: 0px;
	color: #fdfdfd;
	text-decoration: none;
	white-space: nowrap;

	opacity: 0.8;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.ztb-caption-1 {
	font-size: 16px;
	font-weight: bold;
}
.ztb-caption-2 {
	font-size: 13px;
	font-weight: bold;
	padding-left: 10px;
}
.ztb-caption-3 {
	font-size: 13px;
	font-weight: bold;
	font-style: italic;
	padding-left: 20px;
}

.ztb-message {
	opacity: 1.0;
}

.ztb-caption-1:hover,
.ztb-caption-2:hover,
.ztb-caption-3:hover {
	opacity: 1.0;
	color: white;
}

.ztb-caption-1:active,
.ztb-caption-2:active,
.ztb-caption-3:active {
	text-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

.ztb-image {
	width: 12px;
	height: 12px;
	padding: 2px;
	margin: 2px;
	background: white;
	border-radius: 2px;
	vertical-align: top;
}

.ztb-captionInner {
	background: red;
}

.ztb-mouseTrap {
	position: fixed;
	top: 0px;
	left: 0px;
	display: none;
	background: transparent;
	z-index: 5;
}

.ztb-menuChildren {
	position: absolute;
	overflow: hidden;
	display: none;
	z-index: 10;
	-webkit-transition-property: height,opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: height,opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

    background: #6c6e74;
	background: -moz-linear-gradient(top,  #6c6e74 0%, #4b4d51 100%);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#6c6e74), color-stop(100%,#4b4d51));
	background: -webkit-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: -o-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: -ms-linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	background: linear-gradient(top,  #6c6e74 0%,#4b4d51 100%);
	border: 1px solid #404040;
	box-shadow: 2px 2px 2px white;
}

/* choice button */
td.ztb-choice,
td.ztb-choiceSelected {
	white-space: nowrap;
	height: 16px;
	color: #606060;
	font-size: 10px;
	font-weight: bold;
	padding: 2px;
	padding-left: 4px;
	padding-right: 4px;
	text-align: center;
	overflow:hidden;
	opacity: 0.8;
	
	background: #f5f6f6; /* Old browsers */
	background: -moz-linear-gradient(top,  #f5f6f6 0%, #dbdce2 21%, #b8bac6 49%, #dddfe3 80%, #f5f6f6 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f5f6f6), color-stop(21%,#dbdce2), color-stop(49%,#b8bac6), color-stop(80%,#dddfe3), color-stop(100%,#f5f6f6)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* IE10+ */
	background: linear-gradient(top,  #f5f6f6 0%,#dbdce2 21%,#b8bac6 49%,#dddfe3 80%,#f5f6f6 100%); /* W3C */

	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

td.ztb-choiceSelected {
	background: rgb(53,107,141);
	color: white;
}

td.ztb-choice:hover {
	opacity: 1.0;
}

td.ztb-choiceSelected:hover {
	opacity: 1.0;
}

td.ztb-choice:active {
	text-shadow: -1px 1px 8px #8080CC, 1px -1px 8px #8080FF;
}

td.ztb-choiceSelected:active {
	text-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

.ztb-controlDefault {
	color: #808080;
}

.ztb-control {
	color: #202020;
}

</style>
}

/// Client-side method to render this component.
ClientMethod renderContents() [ Language = javascript ]
{
	try {
		var encDiv = this.getEnclosingDiv();
		// test if we have not been rendered yet
		if (encDiv == null) return;

		// get meta data
		var model = this.getModel();
		if (model && model.children && model.children.length) {

			// render
			var menuId = this.id=='' ? this.index : this.id;
			encDiv.innerHTML = this.getMenuHTML(model,menuId);
			
			var width = encDiv.offsetWidth;

			// find info and size for top-level items
			var infoList = [];
			for (var n = 0; n < model.children.length; n++) {
				var info = model.children[n];
				var div = this.findElement('menu_'+n);
				info._width = div ? div.offsetWidth : 0;
				info._height = div ? div.offsetHeight : 0;
				infoList[n] = info;
			}

			// find max height & total width
			var totalWidth = 0;
			var height = 0;
			for (var n = 0; n < infoList.length; n++) {
				var info = infoList[n];
				height = info._height > height ? info._height : height;
				totalWidth += parseInt(info._width);
			}

			var scrollWid = 36;
			var hasScroll = (totalWidth>(width-scrollWid*2));
			if (!hasScroll) {
				this.scrollOffset = 0;
			}
			var firstItem = parseInt(this.scrollOffset);

			encDiv.style.height = (height) + 'px';
			var menuBar = this.findElement('menuBar');
			if (menuBar) {
				menuBar.style.height = (height) + 'px';
			}

			// arrange sizes of top-level items
			var left = 0;
			
			this._maxScroll = 0;
			var hiddenItems = firstItem;

			// hide items before first item
			for (var n = 0; n < firstItem; n++) {
				var div = this.findElement('menu_'+n);
				div.style.display = 'none';
			}

			for (var n = firstItem; n < infoList.length; n++) {
				var info = infoList[n];
				// wrapper
				var div = this.findElement('menu_'+n);

				if ((n>firstItem) && ((left + info._width) > (width-scrollWid*2))) {
					// hide everyone after the right edge
					div.style.display = 'none';
					hiddenItems++;
				}
				else {
					// compensate for border
					var adj = 1;
					div.style.display = 'block';
					div.style.left = left + 'px';
					div.style.height = (height-adj) + 'px';

					// inner
					var divInner = this.findElement('inner_'+n);
					if (divInner) {
						divInner.style.height = (height-adj) + 'px';

						// !!!type
						if (info.image) {
							var image = this.findElement('image_'+n);
							if (image) {
							}
						}

					}
					var td = this.findElement('td_'+n);
					if (td) {
						// 6 = magic
						td.style.height = (height-adj-6) + 'px';
					}
					left += parseInt(info._width);
				}
			}

			if (hasScroll) {
				this._maxScroll = hiddenItems;
				
				var adj = 2;
				var scrollLeft = this.findElement('scrollLeft');
				var scrollRight = this.findElement('scrollRight');
				var scrollLeftIn = this.findElement('scrollLeftInner');
				var scrollRightIn = this.findElement('scrollRightInner');

				scrollLeft.style.display = 'block';
				scrollRight.style.display = 'block';

				scrollLeft.style.left = left + 'px';
				scrollLeftIn.style.height = (height-adj) + 'px';
				scrollLeftIn.style.width = scrollWid + 'px';
				if (firstItem==0) {
					scrollLeftIn.innerHTML = '';
				}
				if (firstItem==0) {
					scrollLeftIn.innerHTML = '';
				}

				left += scrollLeft.offsetWidth;

				scrollRight.style.left = left + 'px';
				scrollRightIn.style.height = (height-adj) + 'px';
				scrollRightIn.style.width = scrollWid + 'px';
				if ((hiddenItems-firstItem)<=0) {
					scrollRightIn.innerHTML = '';
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in renderContents.');
	}
}

/// Get the model used to drive the menu.
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
				// json provider-- use object directly
				model = controller.getContentObject();
			}
			else {
				// build model from controller data!!!
			}
		}
	}
	return model;
}

/// Get HTML for a dynamic menu based on the given content object graph.
/// Each node in the graph may define <var>key</var>, <var>caption</var>,<var>action</var>,
/// <var>targetId</var>, <var>image</var>, and <var>children</var>.
ClientMethod getMenuHTML(content, menuId) [ Internal, Language = javascript ]
{
	var html = [];

	var encDiv = this.getEnclosingDiv();
	
	// mouse-trap div
	html[html.length] = '<div id="'+this.makeId('mouseTrap')+'" class="ztb-mouseTrap" onclick="zenPage.getComponent('+this.index+').hideAll();">';
	html[html.length] = '</div>';

	// menu bar
	html[html.length] = '<div id="'+this.makeId('menuBar')+'" class="ztb-menuBar">';

	// draw top-level menu items horizontally
	if (content && content.children && content.children.length) {
		for (var n = 0; n < content.children.length; n++) {
			var info = content.children[n];
			var id = n;
			var hasChildren = (info.children && info.children.length);
			
			html[html.length] = this.getTopItemHTML(info,n);
			if (hasChildren) {
				html[html.length] = '<div class="ztb-menuChildren" id="'+this.makeId('children_'+id)+'" style="height:0px;opacity:'+1.0+';">';
				for (var j = 0; j < info.children.length; j++) {
					var cinfo = info.children[j];
					var image = zenGet(cinfo.image);
					var ctype = zenGet(cinfo.type);
					var cseparator = zenGet(cinfo.separator);
					var cid = n + "_" + j;
					html[html.length] = '<div class="ztb-menuItem-2" id="'+this.makeId('menu_'+cid)+'">';
					if (cseparator) {
						html[html.length] = '<hr/>'
					}
					else {
						html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('inner_'+cid)+'">';
						html[html.length] = '<a class="ztb-caption-2" id="'+this.makeId('caption_'+cid)+'" onclick="zenPage.getComponent('+this.index+').menuClickHandler(event,\''+ctype+'\',\''+cid+'\',\''+zenGet(cinfo.key)+'\',\''+zenGet(cinfo.action)+'\',\''+zenGet(cinfo.targetId)+'\');">';
						if (image!='') {
							html[html.length] = '<image src="'+image+'"/>';
						}
						html[html.length] = zenGet(cinfo.caption);
						html[html.length] = '</a>'
						html[html.length] = '</div>';
					}
					html[html.length] = '</div>';
				}
				html[html.length] = '</div>';
			}
		}
	}

	// left scroll
	var style = this.style;
	html[html.length] = '<div class="ztb-menuItem-1" id="'+this.makeId('scrollLeft')+'" style="width:24px;display:none;">';
	html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('scrollLeftInner')+'">';
	html[html.length] = '<a class="ztb-caption-1" style="'+style+'" onclick="zenPage.getComponent('+this.index+').scrollClickHandler(event,\'left\');">';
	html[html.length] = '&laquo';
	html[html.length] = '</a>'
	html[html.length] = '</div>';
	html[html.length] = '</div>';

	// right scroll
	var style = this.style;
	html[html.length] = '<div class="ztb-menuItem-1" id="'+this.makeId('scrollRight')+'" style="width:24px;display:none;">';
	html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('scrollRightInner')+'">';
	html[html.length] = '<a class="ztb-caption-1" style="'+style+'" onclick="zenPage.getComponent('+this.index+').scrollClickHandler(event,\'right\');">';
	html[html.length] = '&raquo';
	html[html.length] = '</a>'
	html[html.length] = '</div>';
	html[html.length] = '</div>';

	html[html.length] = '</div>';
	return html.join('');
}

/// Get HTML for one top-level menu item.
ClientMethod getTopItemHTML(info, index) [ Language = javascript ]
{
	var html = [];

	var id = index;

	var image = zenGet(info.image);
	var cellHTML = zenGet(info.html);
	var caption = zenGet(info.caption);
	var value = zenGet(info.value);
	var type = zenGet(info.type,'item');
	var selected = zenGet(info.selected,false);
	if (selected) {
		// selected attr resets selectedIndex
		this.selectedIndex = index;
	}

	var isSelected = (index == this.selectedIndex);
	var hasChildren = (info.children && info.children.length);

	var cls = isSelected ? 'ztb-menuItemSelected-1' : 'ztb-menuItem-1';
	var style = this.style + zenGet(info.style);
	var imageStyle = this.imageStyle + zenGet(info.imageStyle);

	html[html.length] = '<div class="'+cls+'" id="'+this.makeId('menu_'+id)+'">';
	switch (type) {
	case 'separator':
		// insert a spacer into the toolbar
		html[html.length] = '<div class="ztb-hz-separator" id="'+this.makeId('inner_'+id)+'">&nbsp;</div>';
		break;
	case 'field':
		// show a caption and value
		html[html.length] = '<div style="color:#F0F0F0;" class="ztb-menuItemInner" id="'+this.makeId('inner_'+id)+'">';
		html[html.length] = zenEscapeXML(value);
		html[html.length] = '</div>';
		break;
		
	case 'string':
		// show a text edit control
		html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('inner_'+id)+'">';
		html[html.length] = '<a class="ztb-caption-1" style="'+style+'" id="'+this.makeId('caption_'+id)+'">';

		var tcls = 'ztb-control';
		var val = value;
		if (val==='') {
			var defValue = zenGet(info.defaultValue);
			if (defValue!=='') {
				val = defValue;
				tcls = 'ztb-controlDefault';
			}
		}
		html[html.length] = '<input id="'+this.makeId('control_'+id)+'" type="text" size="20" class="'+tcls+'" value="'+zenEscapeXML(val)+'" onfocus="zenPage.getComponent('+this.index+').controlFocus(\''+id+'\');" onchange="zenPage.getComponent('+this.index+').controlChange(\''+id+'\',\''+index+'\');" onkeypress="zenPage.getComponent('+this.index+').controlKeyPress(event,\''+id+'\',\''+index+'\');" />';
		html[html.length] = '</a>';
		html[html.length] = '</div>';
		break;

	case 'choice':
		// show one or more choice buttons
		html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('inner_'+id)+'">';

		// show small set of choices as buttons
		var valueList = zenGet(info.valueList);
		var displayList = zenGet(info.displayList);
		displayList = displayList=='' ? valueList : displayList;
		var value = zenGet(info.value,zenGet(info.caption));

		var vlist = valueList.toString().split(',');
		var dlist = displayList.toString().split(',');
		var count = vlist.length;

		// use table to force one-line layout
		html[html.length] = '<a class="ztb-message" style="'+style+'" ">';
		html[html.length] = '<table style="width:100%;" cellspacing="0" border="0" cellpadding="0">';
		html[html.length] = '<tr>';

		if (count > 0) {
			for (var n = 0; n<count; n++) {
				var st = '';
				if (n==0) {
					st += 'border-top-left-radius:5px;border-bottom-left-radius:5px;';
				}
				if (n==(count-1)) {
					st += 'border-top-right-radius:5px;border-bottom-right-radius:5px;';
				}

				if (zenGet(vlist[n])==value) {
					// current choice
					var cls = 'ztb-choiceSelected';
				}
				else {
					var cls = 'ztb-choice';
				}

				html[html.length] = '<td id="'+this.makeId('choice_'+index+'_'+n)+'" class="'+cls+'" style="border:1px solid #808080;'+st+'" onclick="zenPage.getComponent('+this.index+').choiceClick(event,'+index+','+n+',\''+zenGet(vlist[n])+'\');">'+zenGet(dlist[n])+'</td>';
			}
		}
		html[html.length] = '</tr></table>';
		html[html.length] = '</a>'
		html[html.length] = '</div>';
		break;

	case 'pages':
		// display data paging controls
		html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('inner_'+id)+'">';
		html[html.length] = this.getPagingHTML(index);
		html[html.length] = '</div>';
		break;

	case 'message':
	case 'item':
	case 'tab':
	default:
		html[html.length] = '<div class="ztb-menuItemInner" id="'+this.makeId('inner_'+id)+'">';
		if (type == 'message') {
			html[html.length] = '<a class="ztb-message" style="'+style+'" id="'+this.makeId('caption_'+id)+'">';
		}
		else {
			html[html.length] = '<a class="ztb-caption-1" style="'+style+'" id="'+this.makeId('caption_'+id)+'" onclick="zenPage.getComponent('+this.index+').menuClickHandler(event,\''+type+'\',\''+id+'\',\''+zenGet(info.key)+'\',\''+zenGet(info.action)+'\',\''+zenGet(info.targetId)+'\');">';
		}

		if (cellHTML!='') {
			html[html.length] = cellHTML;
		}
		else  {
			// enough with the css: use a table to arrange the image and caption!
			html[html.length] = '<table cellspacing="0" border="0" cellpadding="0">';
			html[html.length] = '<tr>';
		
			if (image!='') {
				html[html.length] = '<td><image class="ztb-image" id="'+this.makeId('image_'+id)+'" src="'+image+'" style="'+imageStyle+'"/></td>';
			}
			if (caption!='') {
				html[html.length] = '<td id="'+this.makeId('td_'+id)+'" style="'+style+'">';
				html[html.length] = caption;
				if (hasChildren) {
					// !!! remove???
					html[html.length] = '&nbsp;&#9660;';
				}
				html[html.length] = '</td>';
			}
			html[html.length] = '</tr>';
			html[html.length] = '</table>';
		}
		html[html.length] = '</a>'
		html[html.length] = '</div>';
	}
	html[html.length] = '</div>';

	return html.join('');
}

/// GetHTML for a "page" item.
ClientMethod getPagingHTML(index, pageNo) [ Language = javascript ]
{
	var html = [];

	var info = null;
	var content = this.getModel();
	if (content && content.children) {
		info = content.children[index];
	}
	if (!info) {
		return '';
	}
	
	var id = index;
	var caption = zenGet(info.caption);
	var style = zenGet(info.style);
	var image = zenGet(info.image);

	html[html.length] = '<div>';
	html[html.length] = '<table class="ztb-pages" cellspacing="0" border="0" cellpadding="0">';
	html[html.length] = '<tr>';

	// pages
	var startPage = zenGet(info.minValue,1);
	if ('undefined' == typeof pageNo) {
		var currPage = zenGet(info.value,startPage);
	}
	else {
		var currPage = parseInt(pageNo);
	}
	var endPage = zenGet(info.maxValue,startPage);
	var pageCount = endPage - startPage + 1;
	var maxPages = 10;		// after this show gaps

	// if there are gaps, these are the pages in the center
	var centerStart = -1;
	var centerEnd = 100000;
	if (pageCount > maxPages) {
		// show 5 in the middle
		if (currPage > (startPage+3)) {
			centerStart = currPage - 3;
			if (centerStart > endPage-5) {
				centerStart = endPage-5;
			}
		}

		if (currPage < endPage) {
			centerEnd = currPage + 3;
			if (centerEnd < (startPage+6)) {
				centerEnd = startPage+6;
			}
		}
	}

	if (image!='') {
		html[html.length] = '<td><image class="ztb-image" id="'+this.makeId('image_'+id)+'" src="'+image+'" style="'+imageStyle+'"/></td>';
	}
	if (caption!='') {
		html[html.length] = '<td id="'+this.makeId('td_'+id)+'" style="padding-right:10px;'+style+'">';
		html[html.length] = caption;
		html[html.length] = '</td>';
	}

	if (centerStart > 1) {
		html[html.length] = '<td class="ztb-pageNo" style="'+style+'" onclick="zenPage.getComponent('+this.index+').pageChangeHandler(event,\''+id+'\',\''+zenGet(info.key)+'\',\''+(parseInt(currPage)-1)+'\');" >';
		html[html.length] = '&laquo;';
		html[html.length] = '</td>';
	}

	for (var page = startPage; page <= endPage; page++) {
		var skip = false;
		if ((centerStart!=-1 || centerEnd!=100000) && page!=startPage && page!= endPage) {
			if (page <= centerStart || page >= centerEnd) {
				skip = true;
			}
		}

		if (!skip) {
			if (page == currPage) {
				html[html.length] = '<td class="ztb-pageNoCurr" style="'+style+'">';
			}
			else {
				html[html.length] = '<td class="ztb-pageNo" style="'+style+'" onclick="zenPage.getComponent('+this.index+').pageChangeHandler(event,\''+id+'\',\''+zenGet(info.key)+'\',\''+page+'\');" >';
			}
			html[html.length] = page;
			html[html.length] = '</td>';
		}
		else if (page==centerStart || page==centerEnd) {
			html[html.length] = '<td>';
			html[html.length] = '&#8230;';
			html[html.length] = '</td>';
		}
	}

	if (currPage < endPage) {
		html[html.length] = '<td class="ztb-pageNo" style="'+style+'" onclick="zenPage.getComponent('+this.index+').pageChangeHandler(event,\''+id+'\',\''+zenGet(info.key)+'\',\''+(parseInt(currPage)+1)+'\');" >';
		html[html.length] = '&raquo;';
		html[html.length] = '</td>';
	}

	html[html.length] = '</tr>';
	html[html.length] = '</table>';
	html[html.length] = '</div>';
	return html.join('');
}

/// User click on scroll button.
ClientMethod scrollClickHandler(evt, which) [ Language = javascript ]
{
	if (which == 'left') {
		if (this.scrollOffset > 0) {
			this.scrollOffset--;
			this.render();
		}
	}
	else {
		if (this.scrollOffset < this._maxScroll) {
			this.scrollOffset++;
			this.render();
		}
	}
}

/// User click on a menu item.
ClientMethod menuClickHandler(evt, type, id, key, action, targetId) [ Language = javascript ]
{
	if (evt.stopPropagation) {
		evt.stopPropagation();
	}

	// work-around for ie
	if (zenIsIE) {
		this.hideAll();
	}

	var trapDiv = this.findElement('mouseTrap');
	var menuDiv = this.findElement('menu_'+id);
	var childDiv = this.findElement('children_'+id);
	if (childDiv) {
		trapDiv.style.display = 'block';
		trapDiv.style.width = '10000px';
		trapDiv.style.height = '10000px';

		// reveal children
		childDiv.style.display = 'block';
		childDiv.style.left = menuDiv.offsetLeft + 'px';
		var adj = 2;
		childDiv.style.top = menuDiv.offsetTop + menuDiv.offsetHeight + adj + 'px';
		childDiv.style.height = 'auto';
		childDiv.style.opacity = 1.0;
	}
	else {
		if (!zenIsIE) {
			this.hideAll();
		}
	}
	
	// invoke action handler
	this.menuActionHandler(id,type,key,action,targetId);
}

/// Hide all dropdowns
ClientMethod hideAll() [ Language = javascript ]
{
	var content = this.getModel();
	if (content && content.children && content.children.length) {
		for (var n = 0; n < content.children.length; n++) {
			var childDiv = this.findElement('children_'+n);
			if (childDiv) {
				childDiv.style.display = 'none';
				childDiv.style.height = 0 + 'px';
				childDiv.style.opacity = 0.0;
			}
		}
	}

	var trapDiv = this.findElement('mouseTrap');
	trapDiv.style.display = 'none';
}

/// Action handler for menu item.
ClientMethod menuActionHandler(itemId, type, key, action, targetId) [ Language = javascript ]
{
	// test for click on top-level item
	if (type=='tab') {
		if (itemId == (parseInt(itemId,10))) {
			if (this.selectedIndex!=itemId) {
				var menuDiv = this.findElement('menu_'+this.selectedIndex);
				if (menuDiv) {
					menuDiv.className = 'ztb-menuItem-1';
				}
				this.selectedIndex = itemId;
				var menuDiv = this.findElement('menu_'+this.selectedIndex);
				if (menuDiv) {
					menuDiv.className = 'ztb-menuItemSelected-1';
				}
			}
		}
	}
	zenInvokeCallbackMethod(this.onselect,this,'onselect','key',key,'action',action,'targetId',targetId);
}

/// Click handler for paging item.
ClientMethod pageChangeHandler(evt, itemId, key, page) [ Language = javascript ]
{
	page = parseInt(page);

	// update
	var divInner = this.findElement('inner_'+itemId);
	if (divInner) {
		var height = divInner.offsetHeight;

		divInner.innerHTML = this.getPagingHTML(itemId,page);
		divInner.style.height = height + 'px';
		
	}

	// invoke callback
	zenInvokeCallbackMethod(this.onpagechange,this,'onpagechange','key',key,'page',page);
}

/// Select a tab item given its key.
ClientMethod selectTab(key) [ Language = javascript ]
{
	var index = -1;
	var content = this.getModel();
	if (key!=='' && content && content.children && content.children.length) {
		for (var n = 0; n < content.children.length; n++) {
			if (content.children[n].key == key) {
				index = n;
				break;
			}
		}
	}
	this.setProperty('selectedIndex',index);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'style':
	case 'imageStyle':
	case 'selectedIndex':
		this[property] = value;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Set the width (in pixels) of this component.
ClientMethod setWidth(width) [ Language = javascript ]
{
	var encDiv = this.getEnclosingDiv();
	if (encDiv) {
		encDiv.style.width = width + 'px';
		this.render();
	}
}

/// Mouse click handler for choice control.
ClientMethod choiceClick(evt, index, choiceNo, newValue) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// unselect
	for (var n = 0; n < 99; n++) {
		var div = this.findElement('choice_'+index+'_'+n);
		if (div) {
			div.className = 'ztb-choice';
		}
		else {
			break;
		}
	}

	// select new item
	var div = this.findElement('choice_'+index+'_'+choiceNo);
	if (div) {
		div.className = 'ztb-choiceSelected';
	}
	var model = this.getModel();
	if (model && model.children && model.children.length) {
		var item = model.children[index];
		if (item) {
			// invoke callback
			var key = zenGet(item.key);
			if (item.value != newValue) {
				item.value = newValue;
				zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',true);
			}
		}
	}
}

/// Focus handler for text control.
ClientMethod controlFocus(id) [ Language = javascript ]
{
	var ctrl = this.findElement('control_'+id);
	if (ctrl && ctrl.className=='ztb-controlDefault') {
		ctrl.className = 'ztb-control';
		ctrl.value = '';
	}
}

/// Change handler for text control.
ClientMethod controlChange(id, index) [ Language = javascript ]
{
	var ctrl = this.findElement('control_'+id);
	if (ctrl && ctrl.className=='ztb-controlDefault') {
		return;
	}

	var newValue = ctrl.value;
	
	var model = this.getModel();
	if (model && model.children && model.children.length) {
		var item = model.children[index];
		if (item) {
			// invoke callback
			var key = zenGet(item.key);
			if (item.value != newValue) {
				item.value = newValue;
				zenInvokeCallbackMethod(this.onchange,this,'onchange','value',item.value,'key',key,'final',true);
			}
		}
	}
}

/// Key press handler for text control.
ClientMethod controlKeyPress(evt, id, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.keyCode == zenENTER) {
		this.controlChange(id, index);
	}
}

}
