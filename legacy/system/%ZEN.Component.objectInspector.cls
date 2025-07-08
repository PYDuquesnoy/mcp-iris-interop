/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Displays contents of a given client component.<br>
/// This is used by ZEN tools.
Class %ZEN.Component.objectInspector Extends dynaGrid [ Deprecated, SqlRowIdPrivate, System = 3 ]
{

/// Subclasses can set this to change default css class used for grids.
Parameter DEFAULTGRIDCLASS = "inspectorGrid";

Parameter DEFAULTGRIDLABEL = "Property";

Parameter DEFAULTROWLABELWIDTH = 150;

/// If true show all properties of component, else just show
/// settable properties.
Property showAll As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, values in the inspector cannot be edited.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then the id property can be edited.
Property idEditable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onselect event handler:
/// This event is fired when the user selects a property in the inspector.
Property onselect As %ZEN.Datatype.eventHandler;

/// onedit event handler:<br>
/// This event is fired when the user presses the edit property button in the inspector.
/// If not present, then the default action of launching the <class>%ZEN.Dialog.componentValueEditor</class>
/// popup window is carried out.
Property onedit As %ZEN.Datatype.eventHandler;

/// Client property that holds name of current property.
Property currMember As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Client property that holds type of current property.
Property currMemberType As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Main table for objectInspector." */
table.inspectorGrid {
	background: white;
	table-layout: fixed;
	padding: 0px;
	width: 100%;
}

/* @doc="Label for objectInspector." */
table.inspectorGrid th.dynaGridLabel {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	background: #DDEEFF;
	text-align: left;
	white-space: nowrap;
	overflow: hidden;
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Column labels for objectInspector." */
table.inspectorGrid th.dynaGridColumn {
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	text-align: left;
	white-space: nowrap;
	overflow: hidden;
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Row labels for objectInspector." */
table.inspectorGrid th.dynaGridRow {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	background: #DDEEFF;
	text-align: left;
	white-space: nowrap;
	overflow: hidden;
	font-weight: normal;
	color: darkblue;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Cells within objectInspector." */
table.inspectorGrid td {
	border-bottom: 1px solid gray;
	padding: 0px;
	margin: 0px;
	cursor: pointer;
	text-align: right;
}

table.inspectorGrid th.dynaGridLabel:hover,
table.inspectorGrid th.dynaGridRow:hover,
table.inspectorGrid th.dynaGridColumn:hover {
	color: white;
	background: #808080;
}

table.inspectorGrid td div {
	width: 100%;
	height: 100%;
	overflow: hidden;
}

/* @doc="Current cell with focus within objectInspector." */
table.inspectorGrid td div.focus {
	color: white;
	background: #000040;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
}

/* @doc="Selected cell within objectInspector." */
table.inspectorGrid td div.selected {
	background: #E0E0E0;
}

.objectInspectorButton {
	font-size: 0.8em;
	height: 20px;
	width: 20px;
	background-image: url(images/inspector.gif);
	background-repeat: no-repeat;
	background-color: #C0C0C0;
}

/* div containing popup button */
.objectInspectorButtonDiv {
	width: 100%;
	height: 100%;
	background: #000040;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
}

</style>
}

/// Initialize additional client-side variables
ClientMethod onCreate() [ Language = javascript ]
{
	this.ondblclick = 'zenPage.getComponent('+this.index+').dblClickHandler();'
	
	// current object being inspected
	this.currObject = null;

	// name of selected member
	this.currMember = '';

	return this.invokeSuper('onCreate',arguments);
}

/// Return current object.
ClientMethod getCurrObject() [ Language = javascript ]
{
	return this.currObject;
}

/// Update the values displayed within the inspector.
ClientMethod update() [ Language = javascript ]
{
	this.renderInspector();
}

/// Make given component the current inspector target.
ClientMethod setCurrObject(obj) [ Language = javascript ]
{
	this.currObject = obj;
	this.currMember = '';
	this.renderInspector();
}

/// Return name of selected object member.
ClientMethod getCurrMember() [ Language = javascript ]
{
	return this.currMember;
}

/// Return type of selected object member.
ClientMethod getCurrMemberType() [ Language = javascript ]
{
	return this.currMemberType;
}

/// Set selected object member (given its name).
ClientMethod setCurrMember(name) [ Language = javascript ]
{
	this.currMember = name;
	// find row & select it
	var r = 0;
	for (var n = 0; n < this._labels.length; n++) {
		if (this._labels[n] == name) {
			r = n+1;
			break;
		}
	}
	if (r > 0) {
		this.selectCell(r, 1);
	}
}

/// Redraw contents of object inspector
ClientMethod renderInspector() [ Language = javascript ]
{
	this._dataLoaded = false;
	this.render();
}

/// User click on edit member button within inspector.
ClientMethod editMember(name) [ Language = javascript ]
{
	if (typeof this.currObject[this.currMember] == 'object') {
		this.setCurrObject(this.currObject[this.currMember]);
		return;
	}
	
	// invoke callback, if present
	if ('' != this.onedit) {
		zenInvokeCallbackMethod(this.onedit,this,'onedit');
		return;
	}
	
	var obj = this.getCurrObject();
	var mbr = name!=""?name:this.getCurrMember();
	
	if (zenPage && obj && '' != mbr) {
		// launch the built-in component value editor dialog
		var value = obj.getProperty(mbr);
		var mbrType = this.getCurrMemberType();
		if (mbrType == 'boolean') {
			value = (value) ? '1' : '0';
		}
		var parms = new Object();
		parms.property = mbr;
		parms.className = obj._serverClass;
		parms.value = value;
		parms.type = mbrType;
		zenPage.launchPopupWindow(zenLink('%ZEN.Dialog.componentValueEditor.cls'),'ValueEditor','resizable,width=500,height=500',parms,this);
	}
}

/// This client event, if present, is fired when a popup page has specified
/// this component as its parent and fires an action.<br>
/// <var>popupName</var> is the name of the popup window sending the action.<br>
/// <var>action</var> is the name of the action.<br>
/// <var>value</var> is the value associated with the action.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'ValueEditor':
		switch (action) {
		case 'ok':
		case 'apply':
			var mbr = this.getCurrMember();
			var r = 0;
			for (var n = 0; n < this._labels.length; n++) {
				if (this._labels[n] == mbr) {
					r = n+1;
					break;
				}
			}
			if (r > 0) {
				this.setCellValue(value, r, 1);
			}
			if ('ok' == action) {
				this.setCurrMember('');
			}
			break;
		}
		break;
	}
}

/// Apply a value to the target object.
ClientMethod applyValue(property, value) [ Language = javascript ]
{
	var obj = this.getCurrObject();
	var mbrType = this._dataTypes ? this._dataTypes[property] : null;
	mbrType = (null == mbrType) ? 'string' : mbrType;

	if (mbrType == 'boolean') {
		value = zenBool(value);
	}

	var handled = obj.setProperty(property,value);
	if (!handled && obj.refreshContents) {
		// if object did not handle set, go to server!
		obj.refreshContents();
	}
}

/// Return the dataSet object associated with this grid.
/// The inspector will serve as its own dataSet.
ClientMethod getDataSet() [ Language = javascript ]
{
	return this;
}

/// Get the properties and values from the target object.
ClientMethod acquireData() [ Language = javascript ]
{
	// test if we have loaded data from target object
	if (!this._dataLoaded) {

		var obj = this.currObject;
	
		// array of values
		this._labels = new Array();
		this._data = new Array();
		this._dataTypes = new Object();  // indexed by property
	
		if (null == obj) {
		}
		else if (obj instanceof Array) {
			// array property
			/* !!!
			for (var n = 0; n < obj.length; n++) {
				var mbr = n;
				var cls = '';
				var btn = '';
				var dblclk = '';
				if (mbr == this.currMember) {
					cls = 'class="objectInspectorSelected"';
					if (!this.readOnly) {
						btn = '<input type="button" class="objectInspectorButton" value="" onclick="zenPage.getComponent('+this.index+').editArrayItem(\''+mbr+'\');">';
						dblclk = 'ondblclick="zenPage.getComponent('+this.index+').editArrayItem(\''+mbr+'\');"';
					}
				}
				
				var val;
				var lblCls;
				lblCls = 'objectInspectorSetting';
				val = obj[n];
				val = (null != val) ? val : '<i>null</i>';
				val = (typeof(val) == 'function') ? '<i>method</i>' : val;
				if (val.length && val.length > 30) {
					val = val.substr(0,30) + '&#8230;'; // clip
				}
				html[html.length] = '<tr '+cls+' '+dblclk+' onclick="zenPage.getComponent('+this.index+').selectMember(\''+mbr+'\',\''+mbrType+'\');"><td width="50%" class="'+lblCls+'" title="'+mbr+'">&nbsp;'+mbr+'&nbsp;</td><td nowrap width="50%">'+btn+'&nbsp;'+val+'&nbsp;</td></tr>';
			}
			*/
		}
		else {
			// show properties
			// find which properties are *settable*
			var settings = new Object();
			obj.getSettings(settings);
	
			// for Zen components, type and index are shown first
			
			var props = new Array();
			if ('undefined' != typeof obj._type) {
				this._labels[this._labels.length] = 'type';
				this._data[this._data.length] = obj._type;
				this._dataTypes['type'] = 'readonly';
	
				this._labels[this._labels.length] = 'index';
				this._data[this._data.length] = obj.index;
				this._dataTypes['index'] = 'readonly';
			}

			// build sorted list of settings
			for (var mbr in obj) {
				// skip type & index & constructor!!!
				if ((this.showAll || (null!=settings[mbr]) || ('parent'==mbr)) && (mbr != 'index') && (mbr != '_type') && (mbr != 'constructor')) {
					props[props.length] = mbr;
				}
			}
			props.sort();
	
			for (var i = 0; i < props.length; i++) {
				var mbr = props[i];
				var mbrType = settings[mbr];
				if (mbr == this.currMember) {
				}
				
				if (settings[mbr] && obj.getProperty) {
					// ask for value
					val = obj.getProperty(mbr);
				}
				else {
					// get directly
					val = obj[mbr];
				}

				val = this.getDisplayValue(val);

				this._labels[this._labels.length] = mbr;
				this._data[this._data.length] = val;
				if ('id' == mbr && !this.idEditable) {
					this._dataTypes[mbr] = 'readonly';
				}
				else {
					this._dataTypes[mbr] = mbrType;
				}
			}
		}
		this._dataLoaded = true;
	}
}

/// Get the string to display for a given value.
ClientMethod getDisplayValue(val) [ Language = javascript ]
{
	switch(typeof val) {
	case 'function':
		val = '(method)';
		break;
	case 'object':
		val = '(object)';
		break;
	case 'boolean':
		val = val ? 'true' : 'false';
		break;
	case 'undefined':
		val = '(null)';
		break;
	case 'string':
	case 'number':
		break;
	}
	val = (null != val) ? val : '(null)';
	return val;
}

/// Return the number of dimensions in the dataSet.
ClientMethod getDimensions() [ Language = javascript ]
{
	return 2;
}

/// Return the number of items in the specified dimension
/// (dim is 1,2, or 3).
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	this.acquireData();

	switch(dim) {
	case 1:
		return this._data.length;
	case 2:
		return 2;
	default:
		return 0;
	}
}

/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	var label = null;
	switch(dim) {
	case 1:
		label = this._labels[n];
		break;
	case 2:
		label = (0==n) ? 'Value' : '';
		break;
	default:
		break;
	}

	return (null == label) ? '' : label;
}

/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var data = (0==d2) ? this._data[d1] : null;
	return (null == data) ? '' : data;
}

/// Set the data contained in the specified location.
/// Location is 0-based;
ClientMethod setData(value, d1, d2, d3) [ Language = javascript ]
{
	var property = this._labels[d1];
	this._data[d1] = this.getDisplayValue(value);
	this.applyValue(property,value);
}

/// Set the value of grid cell; Row and column are 1-based.
ClientMethod setCellValue(value, r, c) [ Language = javascript ]
{
	var type = this.getRowType(r-1);
	if ('boolean' == type) {
		value = zenBool(value);
	}
	value = this.getDisplayValue(value);
	return this.invokeSuper('setCellValue',arguments);
}

/// If this method is defined, and returns true, then a button is
/// displayed within the selected cell.
ClientMethod showCellButton(r, c) [ Language = javascript ]
{
	return true;
}

/// Return an object containing display information for column <var>c</var>
/// (0-based).
ClientMethod getColumnInfo(c) [ Language = javascript ]
{
	var info = null;
	if (1 == c) {
		info = new Object();
		info.readOnly = true;
		info.width = 20;
		info.style = 'padding:0px;height:20px;text-align:center;';
		info.label = '';
	}
	return info;
}

/// Notification that user is about to move to a new cell.
ClientMethod selectCellHandler(r, c) [ Language = javascript ]
{
	var type = this.getRowType(r-1);
	this.currMemberType = type;
	this.currMember = this.getRowMemberName(r-1);

	// invoke callback, if present
	zenInvokeCallbackMethod(this.onselect,this,'onedit');

	if (this._oldRow) {
		var oldbtn = this.findElement('puBtn_'+this._oldRow);
		if (oldbtn) {
			oldbtn.style.display = 'none';
		}
	}
	this._oldRow = r;
	var newbtn = this.findElement('puBtn_'+r);
	if (newbtn) {
		newbtn.style.display = '';
	}
}

/// Prepares data for display within a given cell.
/// If there is an <method>ondrawcell</method> callback,
/// it is invoked. This callback has a chance to chance the contents
/// that will be displayed within the cell.
ClientMethod getCellContents(data, r, c) [ Language = javascript ]
{
	if (c == 2) {
		// button column
		var mbr = this.getRowMemberName(r-1);
		var type = this.getRowType(r-1);
		data = '<div id="'+this.makeId('puBtn_'+r)+'" class="objectInspectorButtonDiv" style="display:none;">';
		if ('readonly' != type) {
			data += '<input class="objectInspectorButton" title="Launch the Value Editor" type="button" onclick="zenPage.getComponent('+this.index+').editMember(\''+mbr+'\');"/>';
		}
		data += '</div>';
	}
	else {
		var usercode = '';
		if (this.ondrawcell) {
			// set up transient row & column properties to
			// pass information to the callback
			this.row = r;
			this.column = c;
			usercode = zenInvokeCallbackMethod(this.ondrawcell,this,'ondrawcell','data',data);
			delete this.row;
			delete this.column;
		}
	
		if (usercode && '' != usercode) {
			data = usercode;
		}
		else {
			if ('' == data) {
				data = '&nbsp;';
			}
			else {
				data = zenEscapeXML(data);
			}
		}
	}
	return data;
}

/// Return an object containing display information for row <var>r</var>
/// (0-based).
ClientMethod getRowInfo(r) [ Language = javascript ]
{
	var type = this.getRowType(r);
	var info = new Object();
	if ('readonly' == type) {
		info.readOnly = true;
	}
	info.title = this.getRowMemberName(r);
	info.format = '';
	info.label = info.title;
	return info;
}

/// Find the property name associated with row <var>r</var> (0-based).
ClientMethod getRowMemberName(r) [ Language = javascript ]
{
	var lbl = this._labels ? this._labels[r] : '';
	return (null == lbl) ? '' : lbl;
}

/// Find what type of data should be in row <var>r</var> (0-based).
ClientMethod getRowType(r) [ Language = javascript ]
{
	var type = '';
	var mbr = this.getRowMemberName(r);
	if ('' != mbr) {
		type = this._dataTypes[mbr];
	}
	return type;
}

/// Return the HTML that renders the cell editor for the given cell.
/// <var>r</var> and <var>c</var> are 1-based.
/// Override to provide custom-behavior.
ClientMethod getEditCellHTML(r, c, value) [ Language = javascript ]
{
	var html = '';
	var type = this.getRowType(r-1);

	switch(type) {
	case 'boolean':
		value = zenBool(value);
		html = '<select class="dynaGridInput" id="cellEditor" type="text" onblur="zenPage.getComponent('+this.index+').stopEditCell();" onchange="zenPage.getComponent('+this.index+').stopEditCell();"><option value="true"'+(value?' selected':'')+'>true</option><option value="false" '+(!value?' selected':'')+'>false</option></select>';
		break;
	default:
		html = '<input class="dynaGridInput" id="cellEditor" type="text" value="'+zenEscapeXML(value)+'" onkeydown="zenPage.getComponent('+this.index+').cellEditKeyHandler(event);" onblur="zenPage.getComponent('+this.index+').stopEditCell();">';
		break;
	}
	var usercode = '';
	if (this.oneditcell) {
		usercode = zenInvokeCallbackMethod(this.oneditcell,this,'oneditcell','value',value);
	}
	if (usercode && '' != usercode) {
		html = usercode;
	}
	else {
	}
	return html;
}

/// User double click on a cell.
ClientMethod dblClickHandler() [ Language = javascript ]
{
	var r = this.currRow - 1;
	var type = this.getRowType(r);
	var mbr = this.getRowMemberName(r);

	if ('boolean' == type && 1==this.currColumn) {
		// toggle value
		var b = !zenBool(this.getData(r,0));
		this.setCellValue(b, this.currRow, 1);
	}
	else if ('readonly' != type) {
		this.editMember(mbr);
	}
}

}
