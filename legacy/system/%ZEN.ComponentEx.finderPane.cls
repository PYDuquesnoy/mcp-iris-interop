/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component implements a simple Finder-like component for browsing
/// hierarchically organized data. It is similar to the original SmallTalk
/// Finder (later adopted by Mac/OS).<br/>
Class %ZEN.ComponentEx.finderPane Extends %ZEN.Component.component [ Deprecated, System = 3 ]
{

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// If provided, this text is displayed as a caption
/// along the top of the finder. The text is *not*
/// HTML escaped, so that it can contain markup.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// How the contents of the finder component are displayed.
Property viewType As %ZEN.Datatype.string(VALUELIST = ",icons,list,columns") [ InitialExpression = "columns" ];

/// If defined, this is a list of properties that supply the column values
/// in 'list' mode.
Property listColumns As %ZEN.Datatype.csv;

/// This is a list of numbers (0-based) indicating the current selected item(s).
/// The first number is the index in the top-most list of items;
/// the second is the index within the children of the top-most item and so on.
Property selectedList As %ZEN.Datatype.csv;

/// Width of columns in the finder when in "columns" mode.
/// The default is 200 pixels.
Property columnWidth As %ZEN.Datatype.length;

/// User-defined set of parameters. These are currently not used by the finder.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// ondrawitem event handler:
/// If defined, this event is fired when
/// an item within the finder is about to be drawn.
/// If this event handler returns a value, then it is used
/// as DHTML to render the item contents.
Property ondrawitem As %ZEN.Datatype.eventHandler;

/// ondrawdetails event handler:
/// If defined, this event is fired when
/// an item with no children is selected.
/// If this event handler returns a value, then it is used
/// as DHTML to render the item details.
Property ondrawdetails As %ZEN.Datatype.eventHandler;

/// ondrawempty event handler:
/// If defined, this event is fired when
/// there is no data available to display within the finder.
/// If this event handler returns a value, then it is used
/// as DHTML providing content for the empty finder.
Property ondrawempty As %ZEN.Datatype.eventHandler;

/// ongetdata event handler:
/// This defines the client-side code that returns
/// an graph of javascript objects used to provide the contents
/// of the finder.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// onlazyload event handler:
/// Used to partially load data into the finder.
/// This defines the client-side code that returns
/// an graph of javascript objects that are used as the children of the current node.
Property onlazyload As %ZEN.Datatype.eventHandler;

/// onselectitem event handler:
/// If defined, this event is fired when the user clicks on an item within the finder.
Property onselectitem As %ZEN.Datatype.eventHandler;

/// oncancel event handler:
/// If defined, this event is fired when the user presses the escape key within the finder.
Property oncancel As %ZEN.Datatype.eventHandler;

/// ongeticon event handler:
/// If defined, this event is fired when the finder is in "icons" view and returns the url
/// of the icon to use; if it returns "", then the default icon is used.<br/>
/// The current item is passed as <var>item</var>.
Property ongeticon As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// If defined, this event is fired when the user double-clicks on an item within the finder.
Property ondblclick As %ZEN.Datatype.eventHandler;

/// If true (default is true), then animate the appearance
/// of the finder.
Property animate As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true (default is true), the first item is preselected on drilldown in icon 
/// mode.
Property selectFirstOnIconDrillDown As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true (default is false), then hilight the top-level rows in "list" mode.
Property hilightTop As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Default icon to display for items that do not supply an icon.
Property itemIcon As %ZEN.Datatype.uri [ InitialExpression = "portal/document_48.gif" ];

/// Default icon to display for folder items that do not supply an icon.
Property folderIcon As %ZEN.Datatype.uri [ InitialExpression = "portal/folder_48.gif" ];

/// Up icon to display in icons mode.
Property upIcon As %ZEN.Datatype.uri [ InitialExpression = "portal/up_48.gif" ];

Property msgNoPriv As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("You do not have privilege to view this page.","%ZEN")} ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* fade in for hover */
.finderItem a,
.finderItemOdd a,
.finderItemSelected a,
.finderIconItem,
.finderIconItemSelected,
tr.finderListRowOdd,
tr.finderListRowEven,
tr.finderListRowSelected {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.33s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.33s;
	-moz-transition-timing-function: ease;
}

/* div around finder columns */
.finderColumnWrapper {
	position: relative;
	height: 100%;
	overflow: hidden;
}

.finderColumn {
	position: absolute;
	vertical-align: top;
	overflow-x: hidden;
	overflow-y: scroll;
	border-right: gray solid 1px;
	top: 0px;
	height: 100%;
}

.finderDetailColumn {
	position: absolute;
	vertical-align: top;
	overflow-x: hidden;
	overflow-y: hidden;
	top: 0px;
	bottom: 0px;
}

.finderItem {
	background: #FFFFFF;
}

.finderItemOdd {
	background: #EEEEEE;
}

.finderItemSelected {
	font-weight: bold;
	background: darkblue;
	color: white;
}

.finderItemDisabled {
	background: silver;
	color: gray;
}

.finderItem a,.finderItemOdd a {
	color: black;
	padding: 5px;
	display: block;
	text-decoration: none;
	word-wrap: break-word;
}

.finderItemDisabled a {
	padding: 5px;
	display: block;
	text-decoration: none;
	word-wrap: break-word;
}

.finderItemSelected a {
	color: white;
	padding: 5px;
	display: block;
	text-decoration: none;
	word-wrap: break-word;
}

/* show item with focus */
.finderItem a:focus,.finderItemOdd a:focus,.finderItemSelected a:focus {
	font-weight: bold;
}

.finderItem a:hover,
.finderItemOdd a:hover {
	background: #FFEEAA;
	color: black;
}

.finderItemSelected a:hover {
	color: #FFEEAA;
}

.finderItem a:active,
.finderItemOdd a:active,
.finderItemSelected a:active {
	text-shadow: 0px 0px 20px #FFEEAA, -0px -0px 20px #FFEEAA;
}

/* div around icons */
.finderIconsWrapper {
	width: 100%;
	height: 100%;
	overflow: auto;
}

.finderIconItem,.finderIconItemSelected {
	float: left;
	text-decoration: none;
	font-size: 10pt;
	overflow: hidden;
	color: black;
	text-align: center;
	margin: 1px;
	padding: 1px;
	width: 200px;
	height: 90px;
	color: #404040;
}

.finderIconItemSelected {
	font-weight: bold;
	color: black;
}

.finderIconItemSelected img {
	border: 1px solid darkgray;
}

.finderIconItem img {
	border: 1px solid transparent;
}

.finderIconItem:link,.finderIconItemSelected:link {
	color: black;
}

.finderIconItem:hover,.finderIconItemSelected:hover {
	color: black;
	background: #FFEEAA;
	padding: 0px;
	border: 1px solid #DDCC88;
}

/* div around list view */
.finderListWrapper {
	width: 100%;
	height: 100%;
	overflow-x: hidden;
	overflow-y: auto;
}

table.finderListTable {
	width: 100%;
	-webkit-user-select: none;
}

table.finderListTable td {
	padding: 3px;
	border-bottom: 1px solid #DDDDDD;
}

.finderListRowSelected .finderListName {
	text-decoration: none;
	color: white;
}

.finderListName {
	text-decoration: none;
	color: #404040;
}

.finderListName:hover {
	text-decoration: underline;
}

/* top level rows in sort mode */
.finderListTopRow {
	background: #AAAAFF;
}

.finderListRowOdd {
	background: #EEEEEE;
}

.finderListRowEven {
	background: white;
}

.finderListRowSelected {
	background: darkblue;
	color: white;
}

tr.finderListRowOdd:hover,
tr.finderListRowEven:hover {
	background: #FFEEAA;
}

tr.finderListRowSelected:hover {
	background: rgb(73,127,161);
}

</style>
}

/// Refresh the contents of the finder.
/// If <var>reset</var> is true, unhighlight and unscroll the contents.
ClientMethod update(reset) [ Language = javascript ]
{
	if (reset) {
		var enc = this.getEnclosingDiv();
		enc.scrollTop = 0;
		enc.scrollLeft = 0;
		this.selectedList = '';
	}
	this.render();
}

/// Draw contents of finder.
ClientMethod renderContents() [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) return;

	var graph = this.getObjectGraph();

	if (null == graph) {
		var usercode = '';
		if (''!=this.ondrawempty) {
			usercode = zenInvokeCallbackMethod(this.ondrawempty,this,'ondrawempty');
		}
		div.innerHTML = usercode;
		return;
	}
	
	var html = '';
	switch (this.viewType) {
	case 'list':
		html = this.getListViewContent(graph);
		break;
	case 'icons':
		html = this.getIconsViewContent(graph);
		break;
	case 'columns':
	default:
		html = this.getColumnsViewContent(graph);
		break;
	}

	div.innerHTML = html;
}

/// Return HTML for list mode.
ClientMethod getListViewContent(graph) [ Language = javascript ]
{
	var html = new Array();
	var array = graph.children;
	var selectedList = this.selectedList.split(',');

	this._rowCount = 0;
	html[html.length] = '<div class="finderListWrapper" id="'+this.makeId('listWrapper')+'">';
	html[html.length] = '<table class="finderListTable" border="0" cellspacing="0" cellpadding="0">';
	html[html.length] = this.getListRowsHTML(array,selectedList,0,'');
	html[html.length] = '</table>';
	html[html.length] = '</div>';
	return html.join('');
}

/// Return HTML for rows within list mode.
/// <var>array</array> is the data model to display.<br/>
/// <var>selectedList</array> is an array containing the selected list.<br/>
/// <var>level</array> is how many levels we are nested.<br/>
/// <var>parentIdx</array> an array of indexs for all levels above this one.<br/>
ClientMethod getListRowsHTML(array, selectedList, level, parentIdx) [ Language = javascript ]
{
	var html = new Array();
	for (var n = 0; n < array.length; n++) {
		var item = array[n];
		var idx = (''==parentIdx ? '' : parentIdx+',') + n;
		var hasKids = item.children && item.children.length > 0;
		var indent = (level == 0) ? '' : '<img height="1px" width="'+(level*16)+'px" src="images/spacer.gif"/>';
		var expanded = hasKids && (item._expanded != false);
		var enabled = ('undefined' == typeof item.disabled || 0==item.disabled);

		var disc = '<img width="16px" src="' + (hasKids ? (expanded ? 'images/arrow1D.gif' : 'images/arrow1R.gif') : 'images/spacer.gif') + '" onmousedown="zenPage.getComponent('+this.index+').rowDisclosureClick(event,\''+idx+'\');"/>';
		var cls;
		if (this.hilightTop && level == 0) {
			cls = 'finderListTopRow';
		}
		else {
			cls = this._rowCount%2 ? 'finderListRowEven' :  'finderListRowOdd';
		}
		var dcls = cls;
		if (idx == this.selectedList) {
			cls = 'finderListRowSelected';
		}
		this._rowCount++;

		var tip = '';
		if (item.title && '' != item.title) {
			tip = 'title="'+item.title+'" ';
		}

		var name = (item.caption ? item.caption : (item.name ? item.name : ''));
		var colProps = null;

		if ('' != this.listColumns) {
			colProps = this.listColumns.split(',');
			var prop = colProps[0];
			if ('' != prop) {
				name = item[prop];
				name = (name ? name : '');
			}
		}

		name = zenEscapeHTML(name);
		// YSD2539 html[html.length] = '<tr '+tip+'defclass="'+dcls+'" class="'+cls+'" id="'+this.makeId('row_'+idx)+'" onmousedown="return zenPage.getComponent('+this.index+').rowClickHandler(event,\''+idx+'\');">';
		if (enabled) {
			// JMD1079 add dblclick
			if (hasKids) {
				var dbl = 'zenPage.getComponent('+this.index+').rowDisclosureClick(event,\''+idx+'\')';
			}
			else {
				var dbl = 'return zenPage.getComponent('+this.index+').itemDblClickHandler(event,\''+idx+'\');';
			}
			html[html.length] = '<tr '+tip+'defclass="'+dcls+'" class="'+cls+'" id="'+this.makeId('row_'+idx)+'" onclick="return zenPage.getComponent('+this.index+').rowClickHandler(event,\''+idx+'\');" ondblclick="'+dbl+'">';
		}
		else {
			html[html.length] = '<tr '+tip+'defclass="'+dcls+'" class="'+cls+'" style="color:#D0D0D0;" id="'+this.makeId('row_'+idx)+'" >';
		}
		html[html.length] = '<td width="10">' + '&nbsp;' + '</td>';
		html[html.length] = '<td width="40%" ' + (hasKids ? 'style="font-weight: bold;"' :'')+ '>' + indent + disc + '&nbsp;' + '<a class="finderListName" href="#" onclick="return false;" '+(enabled?'':'style="color:#D0D0D0;"')+'>'+name + '</a></td>';

		// additional columns
		if (colProps) {
			for (var c = 1; c < colProps.length; c++) {
				var prop = colProps[c]
				if ('' != prop) {
					var text = item[prop];
					text = (text ? text : '');
					html[html.length] = '<td>' + text + '&nbsp;</td>';
				}
			}
		}

		// invoke callback for details column
		if ('' != this.ondrawdetails) {
			var usercode = zenInvokeCallbackMethod(this.ondrawdetails,this,'ondrawdetails','item',item,'finder',this,'index',idx);
			html[html.length] = '<td  width="20%" id="'+ this.makeId('detail_'+idx)+'">' + usercode + '&nbsp;</td>';
		}

		html[html.length] = '</tr>';
		if (hasKids && expanded) {
			html[html.length] = this.getListRowsHTML(item.children,selectedList,level+1,idx);
		}
	}
	return html.join('');
}

/// Return HTML for icons mode.
ClientMethod getIconsViewContent(graph) [ Language = javascript ]
{
	var html = new Array();
	var array = graph.children;
	var baseIdx = '';
	var hasUp = false;
	// find current selected list
	if ('' != this.selectedList) {
		var t = this.selectedList.split(',');
		for (var n = 0; n < t.length - 1; n++) {
			var child = array[t[n]];
			if (child && child.children) {
				hasUp = true;
				baseIdx = baseIdx + ((''==baseIdx)?'':',') + t[n];
				array = child.children;
			}
			else {
				break;
			}
		}
	}

	html[html.length] = '<div class="finderIconsWrapper">';
	if (hasUp) {
		// draw up icon
		var title = $$$Text('Go up one level','%ZEN');
		var btnUp = $$$Text('Up','%ZEN');
		var imgsrc = this.upIcon;
		html[html.length] = '<a class="finderIconItem" title="'+title+'" href="#" onclick="zenPage.getComponent('+this.index+').iconGoUp(event);">';
		html[html.length] = '<img src="'+imgsrc+'" /><br/>' + btnUp;
		html[html.length] = '</a>';
	}

	for (var n = 0; n < array.length; n++) {
		var idx = baseIdx + ((''==baseIdx)?'':',') + n;
		var item = array[n];
		var hasKids = item.children && item.children.length>0;
		var title = item.title ? item.title : '';
		var imgsrc = item.icon ? item.icon : (hasKids ? this.folderIcon : this.itemIcon);
		var enabled = ('undefined' == typeof item.disabled || 0==item.disabled);

		// invoke callback for icon
		if ('' != this.ongeticon) {
			var usericon = zenInvokeCallbackMethod(this.ongeticon,this,'ongeticon','item',item,'finder',this,'index',idx);
			if ('' != usericon) {
				imgsrc = usericon;
			}
		}

		var cls = (idx == this.selectedList) ? 'finderIconItemSelected' : 'finderIconItem';
		if (item.name) {
			var name = zenEscapeHTML(item.caption ? item.caption : item.name);
			if (enabled) {
				html[html.length] = '<a id="'+this.makeId('icon_' + idx)+'" class="'+cls+'" title="'+title+'" href="#" onclick="return false;" onmousedown="zenPage.getComponent('+this.index+').iconClickHandler(event,\''+idx+'\');" ondblclick="zenPage.getComponent('+this.index+').iconDblClickHandler(event,\''+idx+'\');" onkeydown="zenPage.getComponent('+this.index+').iconKeyPressHandler(event,\''+idx+'\');">'+
				((''!=imgsrc) ? '<img src="'+imgsrc+'" /><br/>':'') + name;
			}
			else {
				html[html.length] = '<a id="'+this.makeId('icon_' + idx)+'" class="'+cls+'" style="color:#D0D0D0;" title="'+title+'" href="#" onclick="return false;">'+
				((''!=imgsrc) ? '<img style="opacity:0.25;" src="'+imgsrc+'" /><br/>':'') + name;
			}
			if (hasKids) {
				html[html.length] = '&nbsp;&raquo;';
			}

			// invoke callback for details area
			if ('' != this.ondrawdetails) {
				var usercode = zenInvokeCallbackMethod(this.ondrawdetails,this,'ondrawdetails','item',item,'finder',this,'index',idx);
				if ('' != usercode) {
					html[html.length] = '<div id="'+ this.makeId('detail_'+idx)+'">' + usercode + '&nbsp;</div>';
				}
			}
			html[html.length] = '</a>';
		}
	}
	html[html.length] = '</div>';
	return html.join('');
}

/// Return HTML for columns mode.
ClientMethod getColumnsViewContent(graph) [ Language = javascript ]
{
	var html = new Array();
	var selectedList = this.selectedList.split(',');

	var wid = '';
	var cwid = parseFloat(this.columnWidth);
	cwid = (isNaN(cwid)||cwid<=0) ? 200 : cwid;
	wid = 'style="width:' + ((selectedList.length+1)*cwid) + 'px;"';

	// loop over top level items
	html[html.length] = '<div '+wid+' id="'+this.makeId('wrapper')+'" class="finderColumnWrapper">';
	for (var n = 0; n <= selectedList.length; n++) {
		html[html.length] = this.getFinderColumnHTML(graph,n,selectedList);
	}
	html[html.length] = '</div>';
	return html.join('');
}

/// Return the HTML to render one column of the finder.<br/>
/// <var>graph</var> is the object graph describing the contents of the finder.<br/>
/// <var>column</var> is the column number to render (0 based).<br/>
/// <var>selectedList</var> is an array containing of the selected item for each column.
ClientMethod getFinderColumnHTML(graph, column, selectedList) [ Language = javascript ]
{
	// find the actual array to plot
	var msgToolTip = $$$Text("Click this item for additional options or details.","%ZEN");
	var spanToolTip = $$$Text("Navigate to this item.","%ZEN");
	var list = '';
	var array = graph.children;
	var detailItem = null;
	for (var c = 0; c < column; c++) {
		list = list + (''==list?'':',') + selectedList[c];
		var child = array[selectedList[c]];
		array = (child && child.children) ? child.children : null;
		if (array == null) {
			detailItem = child;
			break;
		}
	}

	// check for details
	if (''==this.ondrawdetails && (!array || array.length==0)) {
		return;
	}

	var wid = '';
	var cwid = parseFloat(this.columnWidth);
	cwid = (isNaN(cwid)||cwid<=0) ? 150 : cwid;
	wid = 'style="width:'+cwid+'px;left:'+(column*(cwid+1))+'px;"';
	var click = '';
	var dblclick = '';
	var keypress = '';
	var spanclick = '';
	var html = new Array();
	if (array && array.length>0) {
		html[html.length] = '<div class="finderColumn" id="'+this.makeId('fc_'+column)+'" '+wid+'>';
		for (var n = 0; n < array.length; n++) {
			var item = array[n];
			var selected = (''!=selectedList[column] && selectedList[column]==n);
			var hasKids = item.children && item.children.length > 0;
			var list2 = list + (''==list?'':',') + n;
			var cls = ((column+n)%2) ? 'finderItem' : 'finderItemOdd';
			cls = selected ? 'finderItemSelected' : cls;
			var enabled = ('undefined' == typeof item.disabled || 0==item.disabled);
			if (enabled) {
				click = 'onclick="return false;" onmousedown="return zenPage.getComponent('+this.index+').itemClickHandler(event,\''+list2+'\');";'
				dblclick = ' ondblclick="return zenPage.getComponent('+this.index+').itemDblClickHandler(event,\''+list2+'\');";'
				keypress = ' onkeydown="return zenPage.getComponent('+this.index+').itemKeyPressHandler(event,\''+list2+'\');";'
			}
			else {
				click = 'onclick="return false;";'
				dblclick = '';
				keypress = '';
				cls = selected ? 'finderItemDisabled' : 'finderItemDisabled';
			}
			var style = '';
			if (item.style && '' != item.style) {
				style = ' style="'+item.style+'" ';
			}
			html[html.length] = '<div class="'+cls+'"'+style+'>';
			var tip = '';
			if (item.title && '' != item.title) {
				tip = 'title="'+item.title+'" ';
			}
			else {
				tip = 'title="'+msgToolTip+'" ';
			}
			var aid = 'id="'+this.makeId('a_'+list2)+'" ';
			html[html.length] = '<a '+aid+tip+(enabled?'href="#" ':'')+click +dblclick+keypress+ '>';

			var usercode = '';
			if (this.ondrawitem) {
				// add additional information to item so that callback has it
				item.column = c;
				usercode = zenInvokeCallbackMethod(this.ondrawitem,this,'ondrawitem','item',item);
				delete item.column;
			}
			if (usercode && '' != usercode) {
				html[html.length] = usercode;
			}
			else {
				if (hasKids) {
					html[html.length] = zenEscapeHTMLSafe(item.name);
					html[html.length] = '&nbsp;&raquo;';
				}
				else {
					var lbl = zenEscapeHTML(item.caption ? item.caption : item.name);
					if (enabled) {
						spanclick = ' onclick="zenPage.getComponent('+this.index+').itemDblClickHandler(event,\''+list2+'\');return true;";'
						html[html.length] = '<span title="'+spanToolTip+'" onmousedown="return zenPage.getComponent('+this.index+').cancelEvent(event);" '+spanclick+' onmouseover="this.style.textDecoration=\'underline\';" onmouseout="this.style.textDecoration=\'none\';">' + lbl + '</span>';
					}
					else {
						html[html.length] = lbl;
					}
				}
			}
			html[html.length] = '</a></div>';
		}
	}
	else {
		html[html.length] = '<div class="finderDetailColumn" id="'+this.makeId('fc_'+column)+'" '+wid+'>';
		if (selectedList.length > (column+1)) {
			// selected list is too long; truncate
			selectedList.length = column;
		}

		// draw details
		if (1 == column && null == detailItem) {
			detailItem = (''!=selectedList[0]) ? graph.children[selectedList[0]] : null;
		}
		var item = detailItem;
		var usercode = zenInvokeCallbackMethod(this.ondrawdetails,this,'ondrawdetails','item',item,'finder',this,'index',list2);
		html[html.length] = usercode;
	}
	html[html.length] = '<br/>';
	html[html.length] = '</div>';
	return html.join('');
}

/// Mouse disclosure click handler for items in finder (in "list" mode).
ClientMethod rowDisclosureClick(evt, idx) [ Language = javascript ]
{
	var item = this.getItem(idx);
	if (item) {
		item._expanded = ('undefined' == typeof item._expanded || item._expanded) ? false : true;

		// preserve scrolling
		var scroll = null;
		var wrap = this.findElement('listWrapper');
		if (wrap) {
			scroll = wrap.scrollTop;
		}
		this.render();
		wrap = this.findElement('listWrapper');
		if (wrap && scroll != null) {
			wrap.scrollTop = scroll;
		}
	}
}

/// Mouse click handler for items in finder (in "list" mode).
ClientMethod rowClickHandler(evt, idx) [ Language = javascript ]
{
	// unselect
	if ('' != this.selectedList) {
		var tr = this.findElement('row_' + this.selectedList);
		if (tr) {
			tr.className = tr.getAttribute('defClass');
		}

		if ('' != this.ondrawdetails) {
			var td = this.findElement('detail_' + this.selectedList);
			if (td) {
				td.innerHTML = zenInvokeCallbackMethod(this.ondrawdetails,this,'ondrawdetails','item',item,'finder',this,'index',idx) + '&nbsp';
			}
		}
	}

	if ('' != this.onselectitem) {
		var item = this.getItem(idx);
		// YSD2518 - if item is disabled then display message when clicked.
		if (item.disabled == 1) {
			alert(this.msgNoPriv);
			return false;
		}

		var ret = zenInvokeCallbackMethod(this.onselectitem,this,'onselectitem','item',item);
		if (!ret) {
			return true;
		}
	}

	this.selectedList = idx;

	// select
	if ('' != this.selectedList) {
		var tr = this.findElement('row_' + this.selectedList);
		if (tr) {
			tr.className = 'finderListRowSelected';
		}
		if ('' != this.ondrawdetails) {
			var td = this.findElement('detail_' + this.selectedList);
			if (td) {
				td.innerHTML = zenInvokeCallbackMethod(this.ondrawdetails,this,'ondrawdetails','item',item,'finder',this,'index',idx) + '&nbsp';
			}
		}
	}
	
	return true;
}

/// Mouse down handler for items in finder (in "columns" mode).
ClientMethod itemClickHandler(evt, list) [ Language = javascript ]
{
	if (list == this.selectedList) {
		// do nothing so that double click can work
		return true;
	}

	// find scroll offsets of each panel
	var scroll = new Array();
	var s = list.toString().split(',');
	for (var n = 0; n < s.length; n++) {
		var panel = this.findElement('fc_' + n);
		if (panel) {
			scroll[n] = panel.scrollTop;
		}
	}

	if ('' != this.onselectitem) {
		var item = this.getItem(list);
		var ret = zenInvokeCallbackMethod(this.onselectitem,this,'onselectitem','item',item);
		if (!ret) {
			return false;
		}
	}

	var t = this.selectedList.toString().split(',');
	this.selectedList = list;
	if (this.animate) {
		if (false && s.length > 2 && (s.length < t.length)) {
			this.scrollFinder('left');
			return true;
		}
	}

	// if _isEmpty is set, then lazy load the children of this node
	if ((''!=this.onlazyload) && item.children && (item.children.length>0) && (item.children[0]._isEmpty)) {
		var newChildren = zenInvokeCallbackMethod(this.onlazyload,this,'onlazyload','item',item);
		if (newChildren) {
			item.children = newChildren;
		}
	}
	this.render();

	// re-apply old vertical scroll offsets
	for (var n = 0; n < s.length; n++) {
		var panel = this.findElement('fc_' + n);
		if (panel) {
			panel.scrollTop = scroll[n];
		}
	}
	
	// make sure enclosure is scrolled to show right-most columns
	this.scrollFinder('right');

	// give focus to element
	// (use different timer!)
	if (this._timerId2) {
		self.clearTimeout(this._timerId2);
	}
	this._timerId2 = self.setTimeout('zenPage.getComponent('+this.index+').giveFocus("'+list+'");',20);
	return true;
}

/// Give focus to an item in the list.
ClientMethod giveFocus(list) [ Internal, Language = javascript ]
{
	try {
		this._timerId = null;
		var el = this.findElement('a_'+list);
		if (el) {
			el.focus();
		}
	}
	catch(ex) {
	}
}

/// Swallow a mouse event.
ClientMethod cancelEvent(evt) [ Language = javascript ]
{
	evt ? evt : window.event
	evt.cancelBubble = true;
	if (evt.stopPropagation) {
		evt.stopPropagation();
	}
	return true;
}

/// Mouse double-click handler for items in finder (in "columns" mode).
ClientMethod itemDblClickHandler(evt, list) [ Language = javascript ]
{
	evt ? evt : window.event
	evt.cancelBubble = true;
	if (evt.stopPropagation) {
		evt.stopPropagation();
	}
	if ('' != this.ondblclick) {
		var item = this.getItem(list);
		zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick','item',item);
	}

	return true;
}

/// Key press handler for items in finder (in "columns" mode).
ClientMethod itemKeyPressHandler(evt, list) [ Language = javascript ]
{
	evt = evt ? evt : event;
	switch(evt.keyCode) {
	case zenENTER:
		// first, try to go down
		var item = this.getItem(list);
		if (item.children && item.children.length>0) {
			list += ',0';
			if (this.getItem(list)) {
				this.itemClickHandler(evt,list);
				break;
			}
		}
		// else, act like a click
		if (this.viewType == 'columns') {
			this.itemDblClickHandler(evt,list);
		}
		else {
			this.itemClickHandler(evt,list);
		}
		break;
	case zenUP:
		var t = list.split(',');
		var n = parseInt(t[t.length-1]);
		if (!isNaN(n) && n>0) {
			t[t.length-1] = n - 1;
			list = t.join(',');
			this.itemClickHandler(evt,list);
		}
		break;
	case zenDOWN:
		var t = list.split(',');
		var n = parseInt(t[t.length-1]);
		if (!isNaN(n)) {
			t[t.length-1] = n + 1;
			list = t.join(',');
			if (this.getItem(list)) {
				this.itemClickHandler(evt,list);
			}
		}
		break;
	case zenRIGHT:
		var item = this.getItem(list);
		if (item.children && item.children.length>0) {
			list += ',0';
			if (this.getItem(list)) {
				this.itemClickHandler(evt,list);
			}
		}
		break;
	case zenLEFT:
		var t = list.split(',');
		t.length--;
		list = t.join(',');
		if (this.getItem(list)) {
			this.itemClickHandler(evt,list);
		}
		break;
	case zenESC:
		zenInvokeCallbackMethod(this.oncancel,this,'oncancel');
		break;
	}
	return true;
}

/// Go up one level in "icon" mode.
ClientMethod iconGoUp(evt) [ Language = javascript ]
{
	if ('' != this.selectedList) {
		var t = this.selectedList.split(',');
		t.length = t.length - 1;
		this.selectedList = t.join(',');
		if ('' != this.onselectitem) {
			var item = this.getItem(this.selectedList);
			var ret = zenInvokeCallbackMethod(this.onselectitem,this,'onselectitem','item',item);
			if (!ret) {
				return false;
			}
		}
		this.render();
	}
	return true;
}

/// Mouse down handler for items in finder (in "icon" mode).
ClientMethod iconClickHandler(evt, list) [ Language = javascript ]
{
	var item = this.getItem(list);
	if (item && item.children && item.children.length > 0) {
		// drill down
		this.selectedList = list + (this.selectFirstOnIconDrillDown?',0':',-1');
		this.render();
		return;
	}

	if (list == this.selectedList) {
		// do nothing so that double click will work
		return true;
	}

	if (item && (item.disabled == 1)) {
		alert(this.msgNoPriv);
		return false;
	}
	if ('' != this.onselectitem) {
		var ret = zenInvokeCallbackMethod(this.onselectitem,this,'onselectitem','item',item);
		if (!ret) {
			return false;
		}
	}
	
	this.selectedList = list;
	this.render(); // quick way!!
	return true;
}

/// Key press handler for items in finder (in "icons" mode).
ClientMethod iconKeyPressHandler(evt, list) [ Language = javascript ]
{
	evt = evt ? evt : event;
	switch(evt.keyCode) {
	case zenENTER:
		this.iconClickHandler(evt,list);
		break;
	}
}

/// Mouse double-click handler for items in finder (in "icon" mode).
ClientMethod iconDblClickHandler(evt, list) [ Language = javascript ]
{
	var item = this.getItem(list);
	// YSD2518 - if item is disabled then display message when clicked.
	if (item.disabled == 1) {
		alert(this.msgNoPriv);
		return;
	}

	if (item.children && item.children.length > 0) {
		// drill down
		this.selectedList = this.selectedList + ',-1';
		this.render();
		return;
	}

	if ('' != this.ondblclick) {
		zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick','item',item);
	}
	return true;
}

/// Scroll the finder so that the right-most column is visible.
/// (in columns mode).
ClientMethod scrollFinder(which) [ Internal, Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	var wrapper = this.findElement('wrapper')
	if (enc && wrapper) {
		var	scroll;
		if ('right' == which) {
			scroll = wrapper.offsetWidth - enc.offsetWidth;
		}
		else {
			scroll = 0;
		}
		
		scroll = scroll < 0 ? 0 : scroll;
		if (enc.scrollLeft == scroll) {
			if (scroll != 0) {
				this.render();
			}
			return;
		}

		if (!this.animate) {
			enc.scrollLeft = scroll;
		}
		else {
			if (this._timerId) {
				window.clearTimeout(this._timerId);
			}
			// start timer
			this._scrollTarget = scroll;
			var delta = (this._scrollTarget - enc.scrollLeft) / 10;
			this._timerId = self.setTimeout("zenPage.getComponent("+this.index+").animateScroll("+delta+",'"+which+"')",20);
		}
	}
}

/// Apply animation to scrolling.
ClientMethod animateScroll(delta, which) [ Internal, Language = javascript ]
{
	delete this._timerId;
	var enc = this.getEnclosingDiv();
	if (Math.abs(enc.scrollLeft - this._scrollTarget) < 10) {
		// done
		enc.scrollLeft = this._scrollTarget;
		if ('left' == which) {
			this.render();
		}
	}
	else {
		enc.scrollLeft = enc.scrollLeft + parseFloat(delta);
		this._timerId = self.setTimeout("zenPage.getComponent("+this.index+").animateScroll("+delta+",'"+which+"')",20);
	}
}

/// Find the item in the object graph with the given address.
/// <var>addr</var> is a list of array offsets starting with
/// the topmost array in the graph: '2,4,2'.
ClientMethod getItem(addr) [ Language = javascript ]
{
	var graph = this.getObjectGraph();
	var item = graph;

	var s = addr.toString().split(',');
	for (var n = 0; n < s.length; n++) {
		if (isNaN(s[n])) break;
		item = item.children[s[n]];
	}
	return item;
}

/// Get object graph for finder.
ClientMethod getObjectGraph() [ Language = javascript ]
{
	return zenInvokeCallbackMethod(this.ongetdata,this,'ongetdata');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'columnWidth':
		this.columnWidth = value;
		this.render();
		break;
	case 'caption':
		this.caption = value;
		break;
	case 'viewType':
		this.setViewType(value);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Set the current view type.
ClientMethod setViewType(type) [ Language = javascript ]
{
	if (type != this.viewType) {
		switch(type) {
		case 'icons':
		case 'list':
		case 'columns':
			this.viewType = type;
			this.render();
			break;
		default:
			alert('Finder: unsupported viewType: ' + type);
			break;
		}
	}
}

}
