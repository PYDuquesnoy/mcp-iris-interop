/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized lookup control that provides a way to select
/// a value from a list of options.
Class %ZEN.Component.lookup Extends %ZEN.Component.control [ Deprecated, System = 3 ]
{

/// Context string used to determine the selection list for this component.<br/>
/// A context string take the form of a URL:<br/>
/// SearchClass/SearchName?parm1=value&parm2=value<br/>
/// <i>SearchClass</i> is the name of a <class>%ZEN.Portal.ContextSearch</class>
/// search class that contains the search to perform.<br/>
/// <i>SearchName</i> is the name of the search method to invoke within
/// the search class.<br/>
/// You can omit the search class and name and use the context to pick up value from
/// other controls on the current page. In this case the context string should start take the form:<br/>
/// ?parm1=value<br/>
/// At this time, search class and name are not supported by this control.
Property context As %ZEN.Datatype.uri;

/// Display value for this control.<br/>
/// <property>value</property> contains the logical value.
Property text As %ZEN.Datatype.string;

/// Optional. If this control belongs to a form that is associated with
/// a dataController, this specifies the name of the property within the dataController
/// that will provide the display value for this control.
Property displayBinding As %ZEN.Datatype.string;

/// Title to display within popup.
Property popupLabel As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Search","%Utility")} ];

/// Size (width * 10 pixels) of the base (non popup) portion of this control.
Property size As %ZEN.Datatype.integer;

/// Specify if there should be a filter text box within the pop up.
Property showFilter As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This flag is not implemented at this time.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This property is not used at this time.
Property separator As %ZEN.Datatype.string [ InitialExpression = "," ];

/// Image to use to invoke lookup popup.
Property lookupIcon As %ZEN.Datatype.uri [ InitialExpression = "deepsee/zoom_16.png" ];

/// Message to show when no results are present.
Property noResultsMessage As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Nothing to show!","%Utility")} ];

/// onshowPopup event handler:
/// This event is fired just before the popup is displayed.
Property onshowPopup As %ZEN.Datatype.eventHandler;

/// Name of property within data element that supplies the id value.
Property idProperty As %ZEN.Datatype.string;

/// Name of property within data element that supplies the text value.
Property textProperty As %ZEN.Datatype.string;

/// Name of property within data element that supplies an image src value.
/// If defined, and the property exists, show the image in the popup instead of the text value.
Property imageProperty As %ZEN.Datatype.string;

/// List of property values to display in the popup list.
/// This is a csv-list of property names.
Property propertyList As %ZEN.Datatype.csv;

/// List of CSS styles to apply to cells within the popup list.
/// This is a csv-list of CSS styles.
Property styleList As %ZEN.Datatype.csv;

/// ongetdata event handler:
/// Return a javascript array of data to display in the popup.
/// This can be any array of object or literal values.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Style for div around the control." */
.lookupDiv {
	border-top: 1px solid #C0C0C0;
	border-left: 1px solid #D0D0D0;
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	background: white;
	position: relative;
	font-family: arial;
	font-size: 14px;
	color: #606060;
	overflow: hidden;
}

.lookupBtn, .lookupBtnInactive {
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
	border: 1px solid white;
	background: white;
	border-radius: 2px;
}

.lookupBtnInactive {
	opacity: 0.25;
}

.lookupBtn:hover {
	border: 1px solid #D0D0D0;
	border-radius: 2px;

background: -moz-linear-gradient(top,  rgb(255,255,255) 0%, rgb(241,241,241) 50%, rgb(225,225,225) 51%, rgb(246,246,246) 100%); /* FF3.6+ */
background: -webkit-linear-gradient(top,  rgb(255,255,255) 0%,rgb(241,241,241) 50%,rgb(225,225,225) 51%,rgb(246,246,246) 100%); /* Chrome10+,Safari5.1+ */
background: -ms-linear-gradient(top,  rgb(255,255,255) 0%,rgb(241,241,241) 50%,rgb(225,225,225) 51%,rgb(246,246,246) 100%); /* IE10+ */
background: linear-gradient(top,  rgb(255,255,255) 0%,rgb(241,241,241) 50%,rgb(225,225,225) 51%,rgb(246,246,246) 100%); /* W3C */
filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#adffffff', endColorstr='#a1f6f6f6',GradientType=0 ); /* IE6-9 */
}

/* div within popup */
.lookupResults {
	border-top: 1px solid #D0D0D0;
}

table.lookupResultTable {
	color: #404040;
	background: white;
	font-size: 12px;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

table.lookupResultTable td {
	border-bottom: 1px solid #F0F0F0;
	padding: 2px;
	padding-left: 4px;
	padding-right: 4px;
}

table.lookupResultTable tr {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
}

table.lookupResultTable tr.lookupOdd:hover,
table.lookupResultTable tr.lookupEven:hover {
	background: #FFEEAA;
	color: #404040;

	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

table.lookupResultTable tr.lookupSelected:hover {
	color: #FFFFFF;
}

.lookupOdd {
}

.lookupEven {
	background: #F4F4F4;
}

.lookupSelected {
	background: rgb(53,107,141);
	color: #F0F0F0;
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgb(53,107,141)), color-stop(100%,rgb(33,87,121)));
}

/* image item within popup */
.lookupImage {
	max-width: 96px;
	max-height: 96px;
}
/* each non-image item within popup */
.lookupItem {
	cursor: default;
}

/* filter control within popup */
.lookupFilter {
	font-size: 10px;
	color: #404040;
}

</style>
}

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	if (!div) return;

	var text = this.value;
	if (text.toString().length > 22) {
		text = text.substr(0,20)+'...';
	}

	var html = [];

	html.push('<div class="lookupDiv" id="'+this.makeId('wrapper')+'" onclick="zenPage.getComponent('+this.index+').focus();">');

	var width = '';
	if (this.size!=='') {
		width = parseInt(this.size) * 10;
	}
	if (width != '') {
		width = 'width:'+width+'px;';
	}

	var active = !this.readOnly && !this.disabled;

	html.push('<div style="position:absolute;left:1px;top:1px;white-space:nowrap;'+width+'" nowrap="1" id="'+this.makeId('text')+'" onclick="zenPage.getComponent('+this.index+').focus();">');
	html.push(zenEscapeXML(text));
	html.push('</div>');

	var click = active ? 'zenPage.getComponent('+this.index+').selectorClick();return false;' : 'return false;';
	var keydown = active ? 'return zenPage.getComponent('+this.index+').selectorKeyDown(event);' : '';
	html.push('<div class="lookupBtn'+((active)?'':'Inactive')+'" style="width:16px;height:16px;position:absolute;right:0px;" id="'+this.makeId('image')+'">');
	html.push('<a id="'+this.makeId('anchor')+'" href="#" onclick="'+click+'" onkeydown="'+keydown+'"><image style="border:none;" src="'+this.lookupIcon+'"/></a>');
	html.push('</div>');

	html.push('</div>');
	div.innerHTML = html.join('');
	this.adjustSize();
}

/// Adjust the size of the control.
ClientMethod adjustSize() [ Language = javascript ]
{
	var wrapperDiv = this.findElement('wrapper');
	var textDiv = this.findElement('text');
	var imageDiv = this.findElement('image');
	if (wrapperDiv && textDiv) {
		var hgt = textDiv.offsetHeight;
		hgt = hgt < 18 ? 18 : hgt;
		var wid = textDiv.offsetWidth;
		wid = wid < 50 ? 50 : wid;
		wrapperDiv.style.width = (wid+25) + 'px';
		wrapperDiv.style.height = (hgt+2) + 'px';
		if (imageDiv) {
			imageDiv.style.top = (hgt-16)/2 + 'px';
		}
	}
}

/// User has pressed the selector button.
ClientMethod selectorClick() [ Language = javascript ]
{
	if (this.disabled || this.readOnly) return;
	var wrapperDiv = this.findElement('wrapper');

	// get control value
	var value = this.value;

	// compute context for popup
	var contextParms = {};
	if ('' != this.context) {
		// resolve parameters within the context string
		// these are preceded by @:  var=@id

		var context = this.context.toString();
		var t = context.split('?');
		if (t.length > 1) {
			var parmList = t[1];
			var t2 = parmList.split('&');
			for (var n = 0; n < t2.length; n++) {
				var t3 = t2[n].split('=');
				var name = t3[0];
				var value = t3[1];
				if (value.charAt(0)=='@') {
					var id = value.substr(1,value.length);
					// find control with given id
					var ctrl = zenPage.getComponentById(id);
					value = (ctrl && ctrl.getValue) ? ctrl.getValue() : '';
				}
				if (name!='') {
					contextParms[name] = value;
				}
			}
		}
	}

	// find position of control
	var top,left;
	var top = zenGetTop(wrapperDiv) + wrapperDiv.offsetHeight - zenGetTopScroll(wrapperDiv);
	var left = zenGetLeft(wrapperDiv) - zenGetLeftScroll(wrapperDiv);

	var array = zenInvokeCallbackMethod(this.ongetdata,this,'ongetdata','context',contextParms);

	// adjust for window scroll bars
	top += zenGetPageScrollTop(this.window);
	left += zenGetPageScrollLeft(this.window);

	var spec = {
		title:(this.popupLabel!='')?this.popupLabel:this.label,
		data:array,
		idProperty:this.idProperty,
		textProperty:this.textProperty,
		imageProperty:this.imageProperty,
		propertyList:this.propertyList,
		styleList:this.styleList,
		top:top,
		left:left,
		value:value
	};
	this.showPopup(spec);
}

/// Display the dropdown popup window.
/// <var>spec</var> is an object with any of the following properties:<br/>
/// top - top edge of popup.<br/>
/// left - left edge of popup.<br/>
/// parentDiv - if supplied, use this to place the popup.<br/>
/// value - current logical value.<br/>
/// data - array of data elements to display; can be an array of objects or literal values.<br/>
/// propertyList - if data contains objects, this is a csv-list of properties to display.<br/>
/// styleList - this is a csv-list of styles to apply to the columns in the popup.<br/>
/// idProperty - if data contains objects, this the name of the property supplying the id value.<br/>
/// textProperty - if data contains objects, this the name of the property supplying the display value.<br/>
/// title - title to display in popup.<br/>
/// applyValue - function to call a value is selected within the popup.<br/>
ClientMethod showPopup(spec) [ Language = javascript ]
{
	spec = spec ? spec : {};
	var value = zenGet(spec.value,'');
	var top = spec.top ? spec.top : null;
	var left = spec.left ? spec.left : null;

	if (spec.parentDiv) {
		top = zenGetTop(spec.parentDiv) + spec.parentDiv.offsetHeight - zenGetTopScroll(spec.parentDiv);
		left = zenGetLeft(spec.parentDiv) - zenGetLeftScroll(spec.parentDiv);
	}

	var hgt = zenGetWindowHeight();
	var dSpace = hgt-top;	
	var dropDownHgt = 275;

	if (dropDownHgt > dSpace) {
		top = hgt - dropDownHgt;
	}

	// create modal group; remember it for later use
	var group = this._group;
	if (!group) {
		group = zenPage.createComponent('modalGroup');
	}
	this._group = group;

	group.onshowGroup = 'zenPage.getComponent('+this.index+').showGroupHandler();';

	// callback to get contents of the popup
	// pass spec to callback via group
	group._spec = spec;
	var func = new Function('group','return zenPage.getComponent('+this.index+').getPopupContent(group);');

	this._applyFunction = null;
	if (spec.applyFunction && 'function' == typeof spec.applyFunction) {
		this._applyFunction = spec.applyFunction;
	}

	group.show(spec.title?spec.title:(this.popupLabel?this.popupLabel:$$$Text('Search','%Utility')),'callback',func,top,left);
}

/// Notification that the popup group is displayed.
ClientMethod showGroupHandler() [ Language = javascript ]
{
	// invoke callback for this control
	zenInvokeCallbackMethod(this.onshowPopup,this,'onshowPopup');

	// adjust size of popup
	var div = this._group.getFloatingDiv();
	if (div) {
		var table = this.findElement('table');
		var tw = table ? table.offsetWidth : 150;
		if (tw < 150) {
			tw = 150;
			if (table) {
				table.style.width = tw + 'px';
			}
		}

		var sd = this.getSearchDiv();
		if (sd) {
			sd.style.width = tw + 20 + 'px';

			div.style.border = '5px solid rgb(53,107,141)';
			div.style.width = sd.offsetWidth + (10) + 'px';
			var ctrl = this.findElement('filter');
			if (ctrl) {
				ctrl.style.width = sd.offsetWidth<160?sd.offsetWidth-40:140 + 'px';
			}
		}
	}

	// give focus to popup
	var ctrl = this.findElement('filter');
	if (ctrl) {
		ctrl.focus();
	}

	// try to make selected item visible
	if (this._selectedIndex>=0) {
		this.selectPopupItem(this._selectedIndex);
	}
}

/// Value applied from popup.
ClientMethod applyValue(value, text) [ Language = javascript ]
{
	if (this._applyFunction && 'function' == typeof this._applyFunction) {
		this._applyFunction(value,text);
		this._applyFunction = null;
		zenPage.endModal();
	}
	else {
		this.setValue(value,text);
		// notify control of change to display value as well
		var form = this.getForm();
		if (form) {
			var controller = form.getController();
			if (controller) {
				if (''!=this.displayBinding) {
					form.sendEventToController('propertyChange',this.displayBinding,text);
				}
				if (''!=this.dataBinding) {
					form.sendEventToController('propertyChange',this.dataBinding,value);
				}
			}
		}
		// call user event handler 
		zenInvokeCallbackMethod(this.onchange,this,'onchange');
		zenPage.endModal();
		this.focus();
	}
}

/// Override to get current value of control.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'value':
		return this.value;
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		this.value = value;
		this.text = value2 ? value2 : this.text;

		var textDiv = this.findElement('text');
		if (textDiv) {
			var text = this.text;
			if (text.toString().length > 22) {
				text = text.substr(0,20)+'...';
			}
			//textDiv.innerHTML = value+(value==''?'':":")+zenEscapeXML(text);
			textDiv.innerHTML = zenEscapeXML(text);
			this.adjustSize();
		}
		break;

	case 'idProperty':
	case 'textProperty':
	case 'imageProperty':
	case 'propertyList':
	case 'styleList':
	case 'context':
	case 'multiSelect':
	case 'popupLabel':
		this[property] = value;
		break;

	case 'showFilter':
		this[property] = value ? true : false;
		break;

	case 'lookupIcon':
		this[property] = value;
		this.render();
		break;

	case 'size':
		this[property] = value;
		this.adjustSize();
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Find the search results div (wrapper around results table).
ClientMethod getSearchDiv() [ Internal, Language = javascript ]
{
	return this.findElement('lookupResults');
}

/// Return the content for the popup/dropdown.
ClientMethod getPopupContent(group) [ Language = javascript ]
{
	var spec = group._spec;
	var html = [];

	// header
	var hstyle = this.showFilter ? 'white-space:nowrap;' : 'height:0px; width:0px; overflow:hidden; font-size:0px; line-height:0px';
	html.push('<div style="'+hstyle+'" nowrap="1">');

	// filter input control
	html.push('<input id="'+this.makeId('filter')+'" class="lookupFilter" onkeydown="return zenPage.getComponent('+this.index+').filterKeyDown(event);" onkeyup="return zenPage.getComponent('+this.index+').filterKeyUp(event);" type="text"/>');
	// html.push('<image style="height:16px;" src="deepsee/loop_24.gif" onclick="zenPage.getComponent('+this.index+').applyFilter();"/>');
	html.push('</div>');

	// search results
	html.push('<div id="'+this.makeId('lookupResults')+'" class="lookupResults" style="height:200px; overflow-x:auto;overflow-y:scroll;" id="'+this.makeId('results')+'">');
	html.push(this.getLookupTableHTML(spec));
	html.push('</div>');

	var info = {
		style:'width:auto;background:#F0F0F0;',
		content: html.join('')
	};
	return info;
}

/// Get the HTML contents of the popup lookup table.
ClientMethod getLookupTableHTML(spec, filter) [ Internal, Language = javascript ]
{
	filter = zenGet(filter);
	filter = filter.toString().toLowerCase();
	var array = spec ? spec.data : null;
	var value = spec ? spec.value : null;

	// index of item within popup
	this._selectedIndex = -1;
	this._itemCount = 0;

	// map displayed row# to data row#
	this._rowIndex = [];

	var styles = null;
	if (spec.styleList && spec.styleList!=='') {
		styles = spec.styleList.toString().split(',');
	}

	var html = [];
	if (!array || !array.length) {
		html.push('<div>');
		html.push(this.noResultsMessage?this.noResultsMessage:$$$Text('Nothing to show!','%Utility'));
		html.push('</div>');
	}
	else {
		html.push('<table id="'+this.makeId('table')+'" class="lookupResultTable" cellspacing="0" border="0" cellpadding="0">');
		for (var n = 0; n < array.length; n++) {
			var record = array[n];
			if ('object' == typeof record) {
				var id = spec.idProperty&&spec.idProperty!=='' ? record[spec.idProperty] : null;
				var text = spec.textProperty&&spec.textProperty!=='' ? record[spec.textProperty] : null;
				id = (null === id) ? n : id;
				text = (null === text) ? id : text;
				var image = spec.imageProperty&&spec.imageProperty!=='' ? record[spec.imageProperty] : null;
			}
			else {
				var id = record;
				var text = record;
				var image = null;
			}

			// get values to display
			var values = [];
			if ('object' == typeof record) {
				if (image) {
				}
				else if (spec.propertyList && spec.propertyList!=='') {
					// multiple values
					var t = spec.propertyList.toString().split(',');
					for (var i = 0; i < t.length; i++) {
						values[i] = record[t[i]];
					}
				}
				else {
					values[0] = text;
				}
			}
			else {
				values[0] = record;
			}

			// filter?
			var skip = false;
			if (filter!='') {
				skip = true;
				for (var i = 0; i < values.length; i++) {
					if (values[i].toString().toLowerCase().indexOf(filter)>=0) {
						skip = false;
						break;
					}
				}
			}

			if (!skip) {
				this._rowIndex[this._itemCount] = n;
				var cls = this._itemCount%2 ? 'lookupEven' : 'lookupOdd';
				if (id == value) {
					cls = 'lookupSelected';
					this._selectedIndex = this._itemCount;
				}

				html.push('<tr class="'+cls+'" id="'+this.makeId('tr_'+this._itemCount)+'" onclick="zenPage.getComponent('+this.index+').applyValue(\''+id+'\',\''+zenEscapeHTML(zenEscapeJS(text))+'\');">');

				if (image) {
					html.push('<td>' + '<image class="lookupImage" src="'+image+'"/>' + '</td>');
				}
				else {
					for (var i = 0; i < values.length; i++) {
						var style = styles&&styles[i] ? styles[i] : '';
						html.push('<td class="lookupItem" style="'+style+'">' + zenEscapeXML(values[i]) + '</td>');
					}
				}
				html.push('</tr>');
				this._itemCount++;
			}
		}
		html.push('</table>');
	}
	return html.join('');
}

/// Apply contents of filter control.
ClientMethod applyFilter() [ Internal, Language = javascript ]
{
	this._selectedIndex = -1;
	var ctrl = this.findElement('filter');
	if (ctrl) {
		var table = this.findElement('table');
		var tw = table ? table.offsetWidth : 150;

		var div = this.findElement('lookupResults');
		if (div) {
			div.innerHTML = this.getLookupTableHTML(this._group._spec,ctrl.value);
			div.scrollTop = 0;
			var table = this.findElement('table');
			if (table) {
				table.style.width = tw + 'px';
			}
		}
		ctrl.focus();
	}
}

/// Keydown in popup.
ClientMethod filterKeyDown(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	case zenESC:
		ret = false;
		zenPage.endModal();
		break;
	case zenENTER:
		ret = false;
		var spec = this._group._spec;
		var array = spec ? spec.data : null;
		if (this._selectedIndex>=0 && array && array[this._selectedIndex]) {
			var rno = this._rowIndex[this._selectedIndex]
			var record = array[rno];
			if ('object' == typeof record) {
				var id = spec.idProperty&&spec.idProperty!=='' ? record[spec.idProperty] : null;
				var text = spec.textProperty&&spec.textProperty!=='' ? record[spec.textProperty] : null;
				id = (null === id) ? n : id;
				text = (null === text) ? id : text;
			}
			else {
				var id = record;
				var text = record;
			}
			this.applyValue(id,text);
		}
		break;
	case zenDOWN:
		var index = this._selectedIndex>=0 ? this._selectedIndex+1 : 0;
		if (index < this._itemCount) {
			this.selectPopupItem(index);
		}
		ret = false;
		break;
	case zenUP:
		var index = this._selectedIndex>=1 ? this._selectedIndex-1 : 0;
		if (index >= 0) {
			this.selectPopupItem(index);
		}
		ret = false;
		break;
	case zenPAGEUP:
		this.selectPopupItem(0);
		ret = false;
		break;
	case zenPAGEDN:
		this.selectPopupItem(this._itemCount - 1);
		ret = false;
		break;
	default:
		break;
	}

	if (!ret) {
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}

	return ret;
}

/// Key up in popup.
ClientMethod filterKeyUp(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	case zenESC:
	case zenENTER:
	case zenDOWN:
	case zenUP:
	case zenPAGEUP:
	case zenPAGEDN:
		ret = false;
		break;
	default:
		this.applyFilter();
		break;
	}

	return ret;
}

/// Keydown on lookup icon.
ClientMethod selectorKeyDown(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// test for user callback
	if ('' != this.onkeydown) {
		ret = zenFireEvent(this.index, this.onkeydown, 'onkeydown', evt);
		if (!ret) return ret;
	}

	// trap keys
	switch(evt.keyCode) {
	case zenDOWN:
	case zenENTER:
		ret = false;
		this.selectorClick();
		break;
	default:
		break;
	}

	if (!ret) {
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}

	return ret;
}

/// Client-side method to give input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	// give focus to invisible control
	var inv = this.findElement('anchor');
	if (inv) {
		inv.focus();
	}
}

/// Select an item within the popup (used by keyboard handling).
ClientMethod selectPopupItem(index) [ Language = javascript ]
{
	if ('undefined' != typeof this._selectedIndex && this._selectedIndex>=0) {
		var tr = this.findElement('tr_'+this._selectedIndex);
		if (tr) {
			tr.className = index%2 ? 'lookupOdd' : 'lookupEven';
		}
	}

	this._selectedIndex = index;

	if (this._selectedIndex>=0) {
		var tr = this.findElement('tr_'+this._selectedIndex);
		if (tr) {
			tr.className = 'lookupSelected';
		}
	}

	// scroll item into view
	var div = this.findElement('lookupResults');
	if (tr && div) {
		var top = tr.offsetTop;
		var bottom = tr.offsetTop + tr.offsetHeight;
		if (bottom > (div.offsetHeight+div.scrollTop)) {
			div.scrollTop = (bottom - div.offsetHeight);
		}
		else if (top < div.scrollTop) {
			div.scrollTop = top;
		}
	}
}

}
