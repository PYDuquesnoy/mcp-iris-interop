/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component is a subclass of the ZEN finderPane taylored for ISC's System Management Portal.
Class %CSP.UI.Component.SMPFinderPane Extends %ZEN.ComponentEx.finderPane [ System = 3 ]
{

/// The XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zen/hs";

/// If true, then the include files generated for this component, are placed in the
/// common /csp/broker directory and not the local /csp/*namespace* directory.<br/>
/// This is intended for use with packages that are mapped so as to be visible to every namespace.<br/>
/// All Zen classes within the same package must have the same value for this parameter.
/// It is the developer's responsibility to ensure this.
Parameter USECOMMONDIRECTORY As BOOLEAN = 1;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
.finderColumn {
	overflow-x: hidden;
	overflow-y: scroll;
	border-right: 1px solid #CBCBCB;
	top: 0px;
	height: 100%;
}
.finderItem a,.finderItemOdd a {
	color: #000000;
	font-size: 14px;
	font-weight: 600;
	padding: 10px;
}
/*  this new design no longer distinguishes Odd/Even */
.finderItemOdd {
	background: #FFFFFF;  /*#EEEEEE;*/
}
.finderItemSelected a {
	font-size: 14px;
	padding: 10px;
}
.finderItemSelected a:hover {
	background: #BFE4E3;
	color: #000000;
	font-size: 14px;
	padding: 10px;
}
.finderItem a:hover,
.finderItemOdd a:hover {
	background: #F7F7F7;
	color: #000000;
	font-size: 14px;
	font-weight: 600;
	padding: 10px;	
}
.finderItemDisabled a {
	color: #000000;
	font-size: 14px;
	padding: 10px;
}
.finderListRowSelected .finderListName {
	text-decoration: underline;
	color: white;
}
table.finderListTable {
	font-size: 14px;
}
/* category name for List View with kids */
.finderListCategory {
	color: black;
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	font-weight: 600;
}
.finderListDisabled {
	color:#D0D0D0;
}
.finderListName {
	text-decoration: underline;
	color: #333695;
}
.finderListName:hover {
	background: #F7F7F7;
}
.finderListRowSelected {
	background: white;
	color: #000000;
}
tr.finderListRowSelected:hover {
	background: #F7F7F7;
}
tr.finderListRowOdd:hover,
tr.finderListRowEven:hover {
	background: #F7F7F7;
}

tr.finderListRowSelected:hover {
	background: rgb(73,127,161);
}
.columnImageSpace {
	width:5%;
	float:right;
}
</style>
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
			var style = 'style="display: flex; justify-content: space-between;" ';
			html[html.length] = '<a '+aid+style+tip+(enabled?'href="#" ':'')+click +dblclick+keypress+ '>';

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
					html[html.length] = item.name;
					html[html.length] = '<div class="columnImageSpace"><img src="portal/images/icon-arrow-blue-right.png" style="padding-left: 3px;" width="5" height="10"/></div>';
				}
				else {
					var lbl = item.caption ? item.caption : item.name;
					if (enabled) {
						spanclick = ' onclick="zenPage.getComponent('+this.index+').itemDblClickHandler(event,\''+list2+'\');return true;";'
						html[html.length] = '<span title="'+spanToolTip+'" onmousedown="return zenPage.getComponent('+this.index+').cancelEvent(event);" '+spanclick+' onmouseover="this.style.textDecoration=\'underline\';" onmouseout="this.style.textDecoration=\'none\';">' + lbl + '</span>';
						html[html.length] = '<div class="columnImageSpace"><img src="portal/images/icon_info.png" width="10" height="10"/></div>';
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

		var disc = '<img width="8" height="6" src="' + (hasKids ? (expanded ? 'images/icon-arrow-blue-down.png' : 'images/icon-arrow-blue-right.png') : 'images/spacer.gif') + '" onmousedown="zenPage.getComponent('+this.index+').rowDisclosureClick(event,\''+idx+'\');"/>';
		var cls;
		if (this.hilightTop && level == 0) {
			cls = 'finderListTopRow';
		}
		else {
			//cls = this._rowCount%2 ? 'finderListRowEven' :  'finderListRowOdd';
			cls = 'finderListRowEven';
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
		html[html.length] = '<td width="10">' + '&nbsp;&nbsp;' + '</td>';
		if (hasKids) {
			var cls = (enabled?'finderListCategory':'finderListDisabled');
			html[html.length] = '<td width="40%" class="'+cls+'">' + indent + disc + '&nbsp;&nbsp;'+name + '</td>';
		} else {
			var cls = (enabled?'finderListName':'finderListDisabled');
			html[html.length] = '<td width="40%">' + indent + disc + '&nbsp;' + '<a class="'+cls+'" href="#" onclick="return false;" >'+name + '</a></td>';
		}

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

}
