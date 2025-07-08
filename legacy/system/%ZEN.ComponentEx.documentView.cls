/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Experimental Document view component.<br/>
/// This provides an way to display a "document" -- data supplied as a graph of JavaScript
/// objects and rendered using a model supplied by another object graph.
Class %ZEN.ComponentEx.documentView Extends (%ZEN.Component.abstractGroup, %ZEN.Component.dataView) [ Deprecated, System = 3 ]
{

Parameter DEFAULTENCLOSINGCLASS = "dvEnclosingClass";

/// If false, show a generic view of the data with no layout applied.
Property useLayout As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Style for overall document.
Property documentStyle As %ZEN.Datatype.style;

/// Style for blocks (sections) within the document.
/// A block encloses a title and paragraph or a table.
Property blockStyle As %ZEN.Datatype.style;

/// Style for titles within the document.
Property titleStyle As %ZEN.Datatype.style;

/// Style for paragraphs within the document.
Property paraStyle As %ZEN.Datatype.style;

/// Style for tables within the document.
Property tableStyle As %ZEN.Datatype.style;

/// Display borders for tables.
Property tableBorder As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Style for header rows within tables.
Property headerRowStyle As %ZEN.Datatype.style [ InitialExpression = "background:#E0E0FF;" ];

/// Style for odd rows within tables.
Property oddRowStyle As %ZEN.Datatype.style;

/// Style for even rows within tables.
Property evenRowStyle As %ZEN.Datatype.style [ InitialExpression = "background:#F8F8F8;" ];

/// ongetlayout event handler:
/// If defined, this event is returns the layout model for the document.
Property ongetlayout As %ZEN.Datatype.eventHandler;

/// ongetdata event handler:
/// If defined, this event is returns the source data to be displayed within this component.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// Defines the style sheet used by this component.
XData Style
{
<style type="text/css">

.dvEnclosingClass {
	overflow: auto;
	background: none;
	border: 1px solid #C0C0C0;
}

.dvBody {
	color: #404040;
	font-family: arial;
	padding: 10px;
}

.dvTitle {
	padding-top: 5px;
	font-weight: bold;
	color: #606060;
}

.dvBlock {
	overflow: hidden;
}

.dvPara {
}

table.dvTable th {
	padding: 2px;
	padding-right: 5px;
	text-align: left;
}

table.dvTable td {
	text-align: left;
}

.dvGenericTitle {
	padding-top: 10px;
	color: #606060;
	font-size: 12px;
	font-weight: bold;
}

.dvGenericValue {
	color: #404040;
	font-size: 14px;
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

	// !!! kill children !!!
	for (var n = 0; n < this.children.length; n++) {
		//this.removeChild(this.children[n]);
	}

	var layout = this.getLayout();
	var data = this.getSourceData();

	// build DHTML for the component
	var html = [];

	var style = this.documentStyle;
	html[html.length] = '<div class="dvBody" style="'+style+'">';

	if (!this.useLayout) {
		// generic view: for design time
		var counter = {count:0};
		html[html.length] = this.renderGeneric(data,0,counter);
	}
	else {
		if (layout && layout.children) {
			var key = '';
			html[html.length] = this.renderList(key,data,layout.children,null,'div');
		}
		else {
			html[html.length] = 'No layout defined.';
		}
	}

	html[html.length] = '</div>';

	// render
	this.getEnclosingDiv().innerHTML = html.join('');

	// render children
	var mode = zenRefreshMode;
	zenRefreshMode = 0;
	for (var n = 0; n < this.children.length; n++) {
		if (this.children[n].getEnclosingDiv()) {
			this.children[n].refreshContents(true);
		}
	}
	zenRefreshMode = mode;
}

/// Render the HTML for a "generic" view of the given source data.
ClientMethod renderGeneric(data, level, counter) [ Language = javascript ]
{
	var html = [];
	if (data) {
		var indent = level * 10;
		var bg = counter.count%2==0 ? 'none' : '#F0F0F0';
		html[html.length] = '<div style="padding-left:'+indent+'px;background:'+bg+';">';

		for (var p in data) {
			counter.count++;
			html[html.length] = '<div class="dvGenericTitle">' + p + '</div>';
			var val = data[p];
			if (val===null || val==='') {
				html[html.length] = '<div class="dvGenericValue" style="color:#D08080;">' + '{none}' + '</div>';
			}
			else if (typeof val == 'object') {
				if ('undefined' != typeof val.length) {
					// array
					for (var n = 0; n < val.length; n++) {
						var val2 = val[n];
						if (typeof val2 == 'object') {
							html[html.length] = this.renderGeneric(val2,level+1,counter);
						}
						else {
							html[html.length] = '<div class="dvGenericValue" style="color:#8080D0;">' + val2 + '</div>';
						}
					}
				}
				else {
					html[html.length] = this.renderGeneric(data[p],level+1,counter);
				}
			}
			else {
				html[html.length] = '<div class="dvGenericValue">' + data[p] + '</div>';
			}
		}
		html[html.length] = '</div>';
	}
	return html.join('');
}

/// Get the layout model the defineds the layout and display of the document.
ClientMethod getLayout() [ Language = javascript ]
{
	// See if there is user-supplied data to drive the control
	var model = null;
	if (this.ongetlayout!='') {
		model = zenInvokeCallbackMethod(this.ongetlayout,this,'ongetlayout');
	}
	return model;
}

/// Get the source data for the document.
ClientMethod getSourceData() [ Language = javascript ]
{
	// See if there is user-supplied data.
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
				var data = controller.getContentObject();
				if (controller.contentType=='array') {
					// json provider-- use children array directly
					var model = data&&data.children ? data.children : null;
				}
				else if (controller.contentType=='object') {
					// json provider-- use data directly
					var model = data;
				}
			}
			else {
				// build model from controller data!!!
			}
		}
	}
	return model;
}

/// Render a list of items.<br/>
/// <var>key</var> is the key (prefix) used to assign key values to the items.<br/>
/// <var>data</var> is the source data.<br/>
/// <var>list</var> is the list of items.<br/>
/// <var>context</var> is the inherited data context.<br/>
/// <var>displat</var> specifies how to display the items: 'div' or 'td'.<br/>
ClientMethod renderList(key, data, list, context, display) [ Language = javascript ]
{
	var html = [];
	
	for (var n = 0; n < list.length; n++) {
		var sect = list[n];
		var type = zenGet(sect.type,'para');
		var blockStyle = this.blockStyle;
		if (sect.blockNamedStyle) {
			blockStyle += this.resolveNamedStyle(sect.blockNamedStyle);
		}
		blockStyle += zenGet(sect.blockStyle);
		var ckey = key + (key===''?'':':') + n;

		switch (type) {
		case 'table':
		case 'vgroup':
		case 'hgroup':
			if (display=='td') {
				var tdstyle = '';
				if (this.tableBorder) {
					tdstyle += 'border-right: 1px solid #808080;border-bottom: 1px solid #808080;';
				}
				html[html.length] = '<td style="'+tdstyle+'">';
			}
			else {
				// wrap table/group in block
				html[html.length] = '<div class="dvBlock" style="'+blockStyle+'">';
				if (sect.title) {
					var tstyle = this.titleStyle;
					if (sect.titleNamedStyle) {
						tstyle += this.resolveNamedStyle(sect.titleNamedStyle);
					}
					tstyle += zenGet(sect.titleStyle);
					html[html.length] = '<div class="dvTitle" style="'+tstyle+'">';
					html[html.length] = this.eval(data,sect.title,context);
					html[html.length] = '</div>';
				}
			}

			if (type=='table') {
				var style = '';
				if (this.tableBorder && display!='td') {
					style += 'border-top: 1px solid #808080;border-left: 1px solid #808080;';
				}
				style += zenGet(this.tableStyle) + zenGet(sect.style);
				html[html.length] = '<table class="dvTable" border="0" cellspacing="0" cellpadding="0" style="'+style+'">';

				// get column headers
				var hdrs = [];
				var hasHeader = false;
				if (sect.children && sect.children.length) {
					for (var c = 0; c < sect.children.length; c++) {
						var column = sect.children[c];
						var hdr = zenGet(column.title);
						if (hdr!=='') {
							hasHeader = true;
						}
						else {
							hdr = '&nbsp;';
						}
						hdrs[hdrs.length] = hdr;
					}
				}
				
				// if no non-empty headers, do not add a header section
				if (hasHeader) {
					var hstyle = this.headerRowStyle;
					html[html.length] = '<tr style="'+hstyle+'">';
					for (var c = 0; c < hdrs.length; c++) {
						var thstyle = '';
						if (this.tableBorder) {
							thstyle = 'border-right: 1px solid #808080;border-bottom: 1px solid #808080;' + thstyle;
						}
						html[html.length] = '<th style="'+thstyle+'">';
						html[html.length] = (hdrs[c] ? hdrs[c] : '&nbsp;');
						html[html.length] = '</th>';
					}
					html[html.length] = '</tr>';
				}
			}
			else if(type=='hgroup') {
				// table without headers or border
				var style = '';
				style += zenGet(sect.style);
				html[html.length] = '<table class="dvTable" border="0" cellspacing="0" cellpadding="0" style="'+style+'">';
			}


			var loop = this.eval(data,sect.value,context);
			if (typeof loop == 'string') {
				loop = loop.split(',');
			}
			var context2 = {};
			for (var j = 0; j < loop.length; j++) {
				if (zenGet(sect.value)!='') {
					context2.$parent = context;
					context2.$loopVal = loop[j];
					context2.$loopNo = j;
					context2.$loop = sect.value;
				}
				else {
					// pass on current context
					context2 = context;
				}

				if (sect.children) {
					if (type=='table') {
						var rstyle = j%2==0 ? this.oddRowStyle : this.evenRowStyle;
						html[html.length] = '<tr style="'+rstyle+'">';
					}
					var d2 = 'div';
					switch(type) {
					case 'table':
						d2 = 'td';
						break;
					case 'hgroup':
						d2 = 'tdg';
						break;
					}
					html[html.length] = this.renderList(ckey,data,sect.children,context2,d2);
					if (type=='table') {
						html[html.length] = '</tr>';
					}
				}
			}
			if (type=='table'||type=='hgroup') {
				html[html.length] = '</table>';
				html[html.length] = '</div>';		// section
			}
			if (display=='td') {
				html[html.length] = '</td>';
			}
			break;
		case 'image':
			// wrap in a block
			html[html.length] = '<div class="dvBlock" style="'+blockStyle+'">';
			html[html.length] = this.renderImage(ckey,data,sect,context,display);
			html[html.length] = '</div>';
			break;
		case 'chart':
			// wrap in a block
			html[html.length] = '<div class="dvBlock" style="'+blockStyle+'">';
			html[html.length] = this.renderChart(ckey,data,sect,context,display);
			html[html.length] = '</div>';
			break;
		case 'para':
		default:
			// wrap in a block
			html[html.length] = '<div class="dvBlock" style="'+blockStyle+'">';
			html[html.length] = this.renderPara(ckey,data,sect,context,display);
			html[html.length] = '</div>';
			break;
		}
	}
	return html.join('');
}

/// Render a paragraph.
ClientMethod renderPara(key, data, sect, context, display) [ Language = javascript ]
{
	var html = [];

	var style = this.paraStyle;
	if (sect.namedStyle) {
		style += this.resolveNamedStyle(sect.namedStyle);
	}
	style += zenGet(sect.style);
	var value = this.eval(data,zenGet(sect.value),context);
	
	var format = zenGet(sect.format);
	if (format) {
		value = zenFormatNumber(value,format);
	}

	if (display=='td') {
		if (this.tableBorder) {
			style = 'border-right: 1px solid #808080;border-bottom: 1px solid #808080;' + style;
		}
		style = 'padding:2px;vertical-align:top;' + style;
		html[html.length] = '<td style="'+style+'">';
		html[html.length] = value==='' ? '&nbsp;' : value;
		html[html.length] = '</td>';
	}
	else {
		if (display=='tdg') {
			var tdstyle = 'padding-right:4px;vertical-align:top;';
			html[html.length] = '<td style="'+tdstyle+'">';
		}
		if (sect.title) {
			var tstyle = this.titleStyle;
			if (sect.titleNamedStyle) {
				tstyle += this.resolveNamedStyle(sect.titleNamedStyle);
			}
			tstyle += zenGet(sect.titleStyle);

			html[html.length] = '<div class="dvTitle" style="'+tstyle+'">';
			html[html.length] = this.eval(data,sect.title,context);
			html[html.length] = '</div>';
		}
		html[html.length] = '<div class="dvPara" style="'+style+'">';
		html[html.length] = value==='' ? '&nbsp;' : value;
		html[html.length] = '</div>';
		if (display=='tdg') {
			html[html.length] = '</td>';
		}
	}
	return html.join('');
}

/// Render an image.
ClientMethod renderImage(key, data, sect, context, display) [ Language = javascript ]
{
	var html = [];

	var src = this.eval(data,zenGet(sect.src),context);
	var value = this.eval(data,zenGet(sect.value),context);

	var style = this.paraStyle;
	if (sect.namedStyle) {
		style += this.resolveNamedStyle(sect.namedStyle);
	}
	style += zenGet(sect.style);

	var istyle = '';
	if (sect.imageNamedStyle) {
		istyle += this.resolveNamedStyle(sect.imageNamedStyle);
	}
	istyle += zenGet(sect.imageStyle);

	var repeat = this.eval(data,zenGet(sect.repeatCount,1),context);
	repeat = (''===repeat) ? 1 : repeat;

	if (display=='td') {
		if (this.tableBorder) {
			style = 'border-right: 1px solid #808080;border-bottom: 1px solid #808080;' + style;
		}
		style = 'padding:2px;' + style;
		html[html.length] = '<td style="'+style+'">';
		if (src=='') {
			html[html.length] = '&nbsp;';
		}
		else {
			for (var r = 0; r < repeat; r++) {
				html[html.length] = '<image src="'+src+'" style="'+istyle+'"/>';
			}
		}
		html[html.length] = '</td>';
	}
	else {
		if (display=='tdg') {
			var tdstyle = 'padding-right:4px;';
			html[html.length] = '<td style="'+tdstyle+'">';
		}
		if (sect.title) {
			var tstyle = this.titleStyle;
			if (sect.titleNamedStyle) {
				tstyle += this.resolveNamedStyle(sect.titleNamedStyle);
			}
			tstyle += zenGet(sect.titleStyle);
			html[html.length] = '<div class="dvTitle" style="'+tstyle+'">';
			html[html.length] = this.eval(data,sect.title,context);
			html[html.length] = '</div>';
		}
		html[html.length] = '<div class="dvPara" style="position:relative;'+style+'">';
		if (src=='') {
			html[html.length] = '&nbsp;';
		}
		else {
			for (var r = 0; r < repeat; r++) {
				html[html.length] = '<image src="'+src+'" style="'+istyle+'"/>';
			}
		}

		if (value!=='') {
			html[html.length] = '<div style="z-index:2;position:absolute;top:5px;">';
			html[html.length] = value;
			html[html.length] = '</div>';
		}

		html[html.length] = '</div>';
		if (display=='tdg') {
			html[html.length] = '</td>';
		}
	}
	return html.join('');
}

/// Render an embedded chart.
ClientMethod renderChart(key, data, sect, context, display) [ Language = javascript ]
{
	var html = [];

	var value = this.eval(data,zenGet(sect.value),context);
	var style = this.paraStyle;
	if (sect.namedStyle) {
		style += this.resolveNamedStyle(sect.namedStyle);
	}
	style += zenGet(sect.style);

	var cHeight = zenGet(sect.chartHeight);
	cHeight = (cHeight==='') ? 100 : cHeight;
	var cWidth = zenGet(sect.chartWidth);
	cWidth = (cWidth==='') ? 200 : cWidth;

	// create a frame and chart
	var comp = zenPage.createComponent('svgFrame');
	comp.backgroundStyle = 'fill:none;';
	comp.frameStyle = 'border:none;';
	comp.height = cHeight;
	comp.width = cWidth;

	var chart = zenPage.createComponent('barChart');
	chart.height = cHeight;
	chart.width = cWidth;
	chart.backgroundStyle = 'fill:transparent;stroke:none;';
	chart.plotAreaStyle = 'fill:none;';
	chart.labelsVisible = false;
	chart.legendVisible = false;

	// !!!
	if (!this._chartData) {
		this._chartData = {};
	}
	var cdata = value;
	if ('object' != typeof cdata) {
		cdata = cdata.toString().split(',');
	}
	
	this._chartData[key] = cdata;
	chart.seriesCount = 1;
	chart.seriesSize = cdata.length;
	chart.ongetData = 'return zenPage.getComponent('+this.index+')._chartData[\''+key+'\'];';
	comp.addChild(chart);

	this.addChild(comp);

	html[html.length] = '<div class="dvPara" style="position:relative;'+style+'">';
	html[html.length] = '<div class="zenDiv" id="zen'+comp.index+'" zen="'+comp.index+'">';
	html[html.length] = '</div>';
	html[html.length] = '</div>';
	var chartHTML = html.join('');
	
	var html = [];

	if (display=='td') {
		// !!!
		if (this.tableBorder) {
			style = 'border-right: 1px solid #808080;border-bottom: 1px solid #808080;' + style;
		}
		style = 'padding:2px;' + style;
		html[html.length] = '<td style="'+style+'">';
		html[html.length] = chartHTML;
		html[html.length] = '</td>';
	}
	else {
		if (display=='tdg') {
			var tdstyle = 'padding-right:4px;';
			html[html.length] = '<td style="'+tdstyle+'">';
		}
		if (sect.title) {
			var tstyle = this.titleStyle;
			if (sect.titleNamedStyle) {
				tstyle += this.resolveNamedStyle(sect.titleNamedStyle);
			}
			tstyle += zenGet(sect.titleStyle);
			html[html.length] = '<div class="dvTitle" style="'+tstyle+'">';
			html[html.length] = this.eval(data,sect.title,context);
			html[html.length] = '</div>';
		}
		html[html.length] = '<div class="dvPara" style="position:relative;'+style+'">';
		html[html.length] = chartHTML;
		html[html.length] = '</div>';
		if (display=='tdg') {
			html[html.length] = '</td>';
		}
	}
	return html.join('');
}

/// Evaluate a display value expression and return the result.<br/>
/// <var>data</var> is the data source object supplying the data.<br/>
/// <var>expr</var> is the expression. If is starts with "=", it is interpreted as an expression.<br/>
/// An expression can refer to a property within the data source object:<br/>
/// "=[prop]" evaluates to sourceData.prop<br/>
/// "=[propA.propB]" evaluates to sourceData.propA.propB (if propA is not an object, return "")<br/>
/// "=[prop[0]]" evaluates to sourceData.prop[0]<br/>
/// <var>context</var> is current context object (which modifies the reference to the data source object).<br/>
ClientMethod eval(data, expr, context) [ Language = javascript ]
{
	var value = '';
	expr = zenGet(expr);
	var prop = expr.toString();

	if (prop.charAt(0)=='=') {
		// strip off =	
		// !!! original code is wrong !!!
		prop = prop.substring(1,prop.length);
		// !!! trim ???
		// remove outer []
		if (prop.charAt(0)=='[' && prop.charAt(prop.length-1)==']') {
			prop = prop.substring(1,prop.length-1);
		}
		if (prop!='') {
			if (prop.charAt(0)=='$') {
				// !!! add $data to refer to root data source
				// $ prop comes from context
				value = zenGet(context[prop],'N/A');
			}
			else {
				// pull value from source data
				// if there is a context, use it navigate the data source
				var source = data;
				if (context) {
					source = context.$loopVal;
				}

				// split prop by .
				var plist = prop.toString().split('.');
				if (plist.length > 0) {
					for (var n = 0; n < plist.length &&(''!==typeof source); n++) {
						var pname = plist[n].toString();
						var i1 = pname.indexOf('[');
						var idx = '';
						if (i1>=0) {
							var i2 = pname.indexOf(']');
							if (i2>=0) {
								// !!! what about non-numeric index?
								idx = pname.substring(i1+1,i2);
								pname = pname.substring(0,i1);
							}
						}
						
						if (idx==='') {
							source = zenGet(source[pname]);
						}
						else {
							source = zenGet(source[pname][idx]);
						}
						
						if (n < plist.length-1 && ('object'!=typeof source)) {
							source = "";
						}
					}
					value = source;
				}
			}
		}
	}
	else {
		value = prop;
	}
	return value;
}

/// Resolve the value of a named style.
/// evaluate and lookup the style in the local list of named styles.
ClientMethod resolveNamedStyle(namedStyle, data, context) [ Language = javascript ]
{
	var style = '';
	var name = this.eval(data,namedStyle,context);
	if (name) {
		// !!! we could support a list of names: style+style
		var layout = this.getLayout();
		if (layout && layout.namedStyles && layout.namedStyles[name]) {
			style = layout.namedStyles[name];
		}
	}
	return style;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'useLayout':
		this[property] = value?true:false;
		this.render();
		break;

	case 'documentStyle':
	case 'titleStyle':
	case 'blockStyle':
	case 'paraStyle':
	case 'tableStyle':
	case 'headerRowStyle':
	case 'oddRowStyle':
	case 'evenRowStyle':
	case 'tableBorder':
		this[property] = value;
		this.render();
		break;
	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

}
