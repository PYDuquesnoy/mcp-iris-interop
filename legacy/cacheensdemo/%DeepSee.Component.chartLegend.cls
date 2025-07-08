/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Chart legend component.<br/>
/// This provides an alternate way to display a legend for a Zen chart component.<br/>
/// To use the chart legend you must connect it to a data source using the 
/// <property>controllerId</property> property as well as a chart using the 
/// <property>chartId</property> property. The <property>orientation</property> property
/// specifies how the legend is layed out.
Class %DeepSee.Component.chartLegend Extends (%ZEN.Component.component, %ZEN.Component.dataView) [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Localization domain
Parameter DOMAIN = "%DeepSee";

Parameter DEFAULTENCLOSINGCLASS = "dslegendDiv";

/// id of <class>%DeepSee.SVGComponent.chart</class> component this
/// legend is associated with.<br>
/// Note: if this component is placed within a composite element, then the
/// chart must be within the same composite element.
Property chartId As %ZEN.Datatype.id(COMPONENTTYPE = "chart");

/// Style to apply to the legend table.
Property legendStyle As %ZEN.Datatype.style;

/// Style to apply to border lines in the legend.
Property legendBorderStyle As %ZEN.Datatype.style;

/// Style to apply to the legendBox
Property legendBoxStyle As %ZEN.Datatype.style;

/// Specify which way the legend is layed out.
Property orientation As %ZEN.Datatype.string(VALUELIST = "horizontal,vertical") [ InitialExpression = "vertical" ];

/// Remember the legend position.
Property legendPosition As %ZEN.Datatype.string(VALUELIST = "top,left,bottom,right,none", XMLPROJECTION = "none");

/// Store legend Labels here so available to UI.ChartPDF and Widget.pivot
Property legendLabels As %ZEN.Datatype.csv(XMLPROJECTION = "none");

/// Store legend title here so available to UI.ChartPDF and Widget.pivot
Property legendTitle As %ZEN.Datatype.caption(XMLPROJECTION = "none");

Property showLegendTitle As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 1 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

.dslegendDiv {
	overflow: auto;
	background: white;
	border: 1px solid #C0C0C0;
	min-width: 100px;
}

table.dslegendTable {
	width: 100%;
	background: white;
	font-size: 8pt;
	text-align: center;
	color: #404040;
}

table.dslegendTable th {
	border-bottom:1px solid #C0C0C0;
	padding-left: 4px;
	padding-right: 4px;
	font-weight: bold;
}

table.dslegendTable td {
	padding-right: 4px;
}

.dslegendBox {
	border: 1px solid #606060;
	margin: 3px;
	font-size: 1px;
	height: 10px;
	width: 10px;
	border-radius: 3px;
	box-shadow: 2px 2px 2px #D0D0D0;
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

	// set up association with the chart
	this.chart = null;
	if (this.chartId!='') {
		if (this.composite) {
			this.chart = this.composite.getChildById(this.chartId);
		}
		else {
			this.chart = zenPage.getComponentById(this.chartId);
		}
	}

	// connect to controller
	this.acquireData();

	// build DHTML for the component
	var html = [];
	var chart = this.chart;
	
	var title = this.legendTitle; // WAL098 -- pick up title from legend settings
	var legends = null;
	this.legendLabels = ""; // JSL4252
	this.legendTitle = ""; // JSL4291
		
	// PFS026 - Use titleAxis to determine where to get the dimension name from
	var titleAxis=1;
	
	if (chart) {
		var yaCount = chart.getYAxisCount();
		var currYAxis = chart.currYAxis;

		var controller = this.getController();
		
		this.legendTitle=title;

		if (controller && chart.hasMultiples && chart.hasMultiples() && !chart.hasAxes()) {
			// for pie chart, show item names
			var sz = controller.getDimSize(1);
			legends = [];
			for (var n = 0; n < sz; n++) {
				legends[legends.length] = controller.getLabel(n,1);
			}
			titleAxis=0;
		}
		else if (controller && !chart.hasAxes()) {
			// for pie chart (non-multiple), show series names
			var sz = controller.getDimSize(2);
			legends = [];
			for (var n = 0; n < sz; n++) {
				legends[legends.length] = controller.getLabel(n,2);
			}
		}
		else if (chart._type == 'bubbleChart') {
			// JMD1443 special case; 3rd series drives radius; use it for legend
			legends = [controller.getLabel(2,2)];
		}
		else {
			legends = chart.getLegendLabels();
		}
		
		if ((title=='') && controller && controller.getDimName) {
			title=controller.getDimName(titleAxis);
			if (title=='') {
				// PFS026 - If title = '' this means we have nothing on columns so display Measures
				title=$$$Text("Measures");
			}
		}
		
		if (!this.showLegendTitle) title = ''; // + WAL098 -- don't use title if user has configured legend title to off
	}
	
	// PFS070 - Confirm measure exists on title axis before hiding measure text
	var containsMeasures = ((controller.measureLocation=="columns") && (titleAxis==1)) || ((controller.measureLocation=="rows") && (titleAxis==0))
	// + WAL118 -- if this pivot table is set to hide measure labels remove them from the legend
	if (legends && controller && controller.hideMeasures && (controller.hiddenMeasureText.length>=1) && containsMeasures) {
		for (var i = 0; i < legends.length; ++i) {
			var legendText = legends[i].split('/');
			for (var j = 0; j < legendText.length; ++j) {
				for (var k = 0; k < controller.hiddenMeasureText.length; ++k) {
					if (legendText[j] == controller.hiddenMeasureText[k]) {
						legendText.splice(j,1);	
						break;
					}
				}
			}
			legends[i] = legendText.join('/');
		}
	}
	// - WAL118
	
	this.legendLabels = legends.join(","); // JSL4252
	var enclosingDiv = this.getEnclosingDiv();
	
	// Prepare Legend Styling 
	var legendBoxStyle = zenGet(this.legendBoxStyle);		// DTB170
	
	//+ JSL4504 - move out of it
	var attrs = this.parseStyleSVG(this.legendStyle); // JSL4483
	var backgroundColor = attrs['background-color']; // JSL4483
	var opacity = attrs['opacity'];
	if (typeof(backgroundColor)=='undefined' && typeof(opacity) != 'undefined' && opacity < 1.0) {
		// We will be constructing an rgba value with the opacity
		backgroundColor = 'rgb(255,255,255)';
		attrs['background-color'] = backgroundColor;
	}
	
	//+ JSL4504 normalize legendStyle
	var legendStyle = '';
	// DTB171 - Use a different style for padding in the cells, not the overall table
	var legendPadding = '';
	var legendPaddingLeft = '';
	var legendPaddingRight = '';
	for (var attr in attrs) {
		if ('padding' == attr) {
			// DTB171 - Redirect padding information to legend cells
			legendPadding = 'padding:' + attrs[attr] +';';
			legendPaddingLeft = 'padding-left:' + attrs[attr] + '; padding-top:' + attrs[attr] + '; padding-bottom:' + attrs[attr];
			legendPaddingRight = 'padding-right:' + attrs[attr] + '; padding-top:' + attrs[attr] + '; padding-bottom:' + attrs[attr];
		}
		else if (typeof(opacity) != 'undefined' && opacity < 1.0) { // change background-color to rgba value
			if (attr == 'opacity') continue;
			if (attr == 'background-color') {
				var rgba = ZLM.convertColorToRGBA(backgroundColor, opacity);
				legendStyle += attr + ':' + 'rgba('+rgba+')' + ';';
			} else {
				legendStyle += attr + ':' + attrs[attr]+';';
			}
		}
		else {
			legendStyle += attr + ':' + attrs[attr]+';';
		}
	}
	//- JSL4504 normalize legendStyle
	//- JSL4504 - move out of if
	
	// DTB169 - Incorporate the border style for the legend
	var legendBorderStyle = '';
	
	// +DTB - Normalize legend border color containing opacity
	var legBorderAttrs = this.parseStyleSVG(this.legendBorderStyle);
	var legBorderOpacity = legBorderAttrs['opacity'];
	for (var attr in legBorderAttrs) {
		if (typeof(legBorderOpacity) != 'undefined' && legBorderOpacity < 1.0) { // change background-color to rgba value
			if (attr == 'opacity') continue;
			if (attr == 'border-color') {
				var rgba = ZLM.convertColorToRGBA(legBorderAttrs[attr], legBorderOpacity);
				legendBorderStyle += attr + ':' + 'rgba('+rgba+')' + ';';
			} else {
				legendBorderStyle += attr + ':' + legBorderAttrs[attr]+';';
			}
		}
		else {
			legendBorderStyle += attr + ':' + legBorderAttrs[attr]+';';
		}
	}
	// -DTB
	enclosingDiv.style.cssText += legendBorderStyle;
	
	// Render the legend
	if (this.orientation == 'vertical') {
		// vertical list
	
		html[html.length] = '<table style="'+legendStyle+'" class="dslegendTable" border="0" cellpadding="3" cellspacing="0">'; // JSL4504 - use normalized legendStyle

		if (title != '') {
			if (''!=legendBorderStyle) {
				// DTB169 - Convert the general border style to the border-bottom style that 
				// is used in the headers of the legend table
				var bottomBorderStyle = '';
				var legendBorderArray = this.parseStyleSVG(legendBorderStyle);
				for (var key in legendBorderArray) {
					var bottomKey = key;
					var bottomKeyArray = bottomKey.split('-');
					bottomKeyArray.splice(1,0,'bottom');
					bottomKey = bottomKeyArray.join('-');
					bottomBorderStyle += bottomKey + ':' + legendBorderArray[key] + ';';
				}

				html[html.length] = '<tr><th colspan="2" style="' + bottomBorderStyle + legendPadding +'">'+zenEscapeXML(title)+'</th></tr>';
			}
			else {
				html[html.length] = '<tr><th colspan="2" style="'+legendPadding+'">'+zenEscapeXML(title)+'</th></tr>';
			}
		}
		if (legends && chart) {
			for (var r = 0; r < legends.length; r++) {
				//this.legendLabels += (this.legendLabels=="") ? legends[r] : ","+legends[r]; // JSL4144
				var style = '';
				if (yaCount>1 && chart.getYAxisIndexForSeries(r)==chart.currYAxis) {
					//style += 'background:#FFFFDD;';
					style += 'font-weight: bold;';
				}

				html[html.length] = '<tr style="'+style+'" onclick="zenPage.getComponent('+this.index+').itemClick('+r+');">';
				var color = chart.getSeriesColor(r);
				color = this.transformColor(color);
				html[html.length] = '<td align="left" width="20" title="'+zenEscapeXML(legends[r])+'" style="'+legendPaddingLeft+'"><div class="dslegendBox" style="background:'+color+';'+legendBoxStyle+'">&nbsp;</div></td>';	// DTB170 - include styling for the legend box
				html[html.length] = '<td align="left" style="'+legendPaddingRight+'">'+zenEscapeXML(legends[r])+'</td>';
				html[html.length] = '</tr>';
			}
		}
		html[html.length] = '</table>';
	}
	else {
		// split labels into columns
		var colCount = 1;
		var rowCount = 1;
		var items = 0;
		if (legends && chart) {
			items = legends.length;
			if (items > 6) {
				rowCount = 3;
			}
			else if (items > 3) {
				rowCount = 2;
			}
			colCount = Math.ceil(items / rowCount);
		}

		html[html.length] = '<table style="'+legendStyle+'" class="dslegendTable" border="0" cellpadding="3" cellspacing="0">'; // JSL4504 - normalized legendStyle

		if (title != '') {
			if (''!=legendBorderStyle) {
				// DTB169 - Convert the general border style to the border-bottom style that 
				// is used in the headers of the legend table
				var bottomBorderStyle = '';
				var legendBorderArray = this.parseStyleSVG(legendBorderStyle);
				for (var key in legendBorderArray) {
					var bottomKey = key;
					var bottomKeyArray = bottomKey.split('-');
					bottomKeyArray.splice(1,0,'bottom');
					bottomKey = bottomKeyArray.join('-');
					bottomBorderStyle += bottomKey + ':' + legendBorderArray[key] + ';';
				}
				
				html[html.length] = '<tr><th style="' + bottomBorderStyle + legendPadding +'" colspan="'+(2*(colCount>3?3:colCount))+'">'+zenEscapeXML(title)+'</th><th style="' + bottomBorderStyle + legendPadding +'" colspan="'+(1+(colCount>3?(2*(colCount-3)):0))+'">&nbsp;</th></tr>';
			}
			else {	
				html[html.length] = '<tr><th colspan="'+(2*(colCount>3?3:colCount))+'" style="'+legendPadding+'">'+zenEscapeXML(title)+'</th><th colspan="'+(1+(colCount>3?(2*(colCount-3)):0))+'" style="'+legendPadding+'">&nbsp;</th></tr>';
			}
		}
		if (items) {
			for (var r = 0; r < rowCount; r++) {
				html[html.length] = '<tr>';
				for (var c = 0; c < colCount; c++) {
					itemNo = (c * rowCount) + r;
					if (itemNo >= items) {
						html[html.length] = '<td colspan="2">&nbsp;</td>';
					}
					else {
						var style = '';
						if (yaCount>1 && chart.getYAxisIndexForSeries(itemNo)==chart.currYAxis) {
							//style += 'background:#FFFFDD;';
							style += 'font-weight: bold;';
						}
						var color = chart.getSeriesColor(itemNo);
						color = this.transformColor(color);
						//if (r==0) { 
						//	this.legendLabels += (this.legendLabels=="") ? legends[itemNo] : ","+legends[itemNo]; // JSL4144
						//}
						html[html.length] = '<td onclick="zenPage.getComponent('+this.index+').itemClick('+itemNo+');" style="'+style+legendPaddingLeft+'" align="left" width="18" title="'+zenEscapeXML(legends[itemNo])+'"><div class="dslegendBox" style="background:'+color+';'+legendBoxStyle+'">&nbsp;</div></td>';		// DTB170 - include styling for the legend box
						html[html.length] = '<td onclick="zenPage.getComponent('+this.index+').itemClick('+itemNo+');" style="'+style+legendPaddingRight+'" align="left" nowrap="1">'+zenEscapeXML(legends[itemNo])+'&nbsp;</td>';
					}
				}
				html[html.length] = '<td align="left" width="50%">&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		html[html.length] = '</table>';
	}

	// render
	var enc = this.getEnclosingDiv();
	enc.innerHTML = html.join('');

	// pick up table background
	if (enc.firstChild) {	
		var attrs = this.parseStyleSVG(this.legendStyle); // JSL4483
		var opacity = attrs['opacity'];
		if (typeof(opacity)=='undefined') {
			opacity = 1.0;
		}
		this.setOpacity(opacity); // JSL4483
	}
}

/// Some charts may have use SVG colors. This is a crude translator.
ClientMethod transformColor(color) [ Language = javascript ]
{
	switch(color) {
	case 'url(#deep-silver)':
	case 'url(#shade-silver)':
	case 'url(#glow-silver)':
	case 'url(#glow-silverHz)':
	case 'url(#glow-silverDiag)':
		return 'silver';
	case 'url(#deep-red)':
	case 'url(#shade-red)':
	case 'url(#glow-red)':
	case 'url(#glow-redHz)':
	case 'url(#glow-redDiag)':
		return 'red';
	case 'url(#deep-green)':
	case 'url(#shade-green)':
	case 'url(#glow-green)':
	case 'url(#glow-greenHz)':
	case 'url(#glow-greenDiag)':
		return 'green';
	case 'url(#deep-yellow)':
	case 'url(#shade-yellow)':
	case 'url(#glow-yellow)':
	case 'url(#glow-yellowHz)':
	case 'url(#glow-yellowDiag)':
		return 'yellow';
	case 'url(#deep-blue)':
	case 'url(#shade-blue)':
	case 'url(#glow-blue)':
	case 'url(#glow-blueHz)':
	case 'url(#glow-blueDiag)':
		return 'blue';
	case 'url(#deep-teal)':
	case 'url(#shade-teal)':
	case 'url(#glow-teal)':
	case 'url(#glow-tealHz)':
	case 'url(#glow-tealDiag)':
		return 'teal';
	case 'url(#deep-purple)':
	case 'url(#shade-purple)':
	case 'url(#glow-purple)':
	case 'url(#glow-purpleHz)':
	case 'url(#glow-purpleDiag)':
		return 'purple';
	case 'url(#deep-orange)':
	case 'url(#shade-orange)':
	case 'url(#glow-orange)':
	case 'url(#glow-orangeHz)':
	case 'url(#glow-orangeDiag)':
		return 'orange';
	}
	return color;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'chartId':
		this.chartId = value;
		this.renderContents();
		break;

	case 'orientation': // JSL4503 - don't process orientation in same switch tag as legendStyle
	case 'legendTitle': //  WAL098 - make sure to render contents for the legendTitle as well 
	case 'showLegendTitle': // WAL098 - same with showing/hiding the title
		this[property] = value;
		this.renderContents();
		break;
	case 'legendStyle':
		this[property] = value;
		this.renderContents();
		var attrs = this.parseStyleSVG(value); // JSL4483
		var opacity = attrs['opacity']; // JSL4483
		this.setOpacity(opacity); // JSL4483
		break;
	case 'legendBoxStyle':
		// DTB170
		this[property] = value;
		this.renderContents();
		break;

	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// Utility method. Split an SVG css value into individual style values.
/// Return an object containing these values.
ClientMethod parseStyleSVG(style) [ Language = javascript ]
{
	// added method - JSL4483 - copy-and-pasted from navigator
	var result = {};

	// for svg we have to parse
	var items = style.toString().toLowerCase().split(';');
	for (var i=0; i<items.length; i++) {
		if (items[i]) {
			var pair = items[i].split(':');
			if (pair && pair.length==2) {
				newAttr = zenTrim(pair[0]);
				if (newAttr && newAttr.length>0) {
					newVal = zenTrim(pair[1]);
					if (newVal !== '') {
						result[newAttr] = newVal;
					}
				}
			}
		}
	}
	return result;
}

/// Connect to controller.
ClientMethod acquireData() [ Internal, Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		// try to connect to dataController
		this.connectToController();
		controller = this.getController();
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

/// User click on legend item.
ClientMethod itemClick(idx) [ Internal, Language = javascript ]
{
	if (this.chart && this.chart.getYAxisIndexForSeries) {
		var ya = this.chart.getYAxisIndexForSeries(idx);
		if (ya >= 0) {
			this.chart.setCurrYAxis(ya);
		}
	}
}

ClientMethod setOpacity(opacity) [ Language = javascript ]
{
	// JSL4483 - add this method
	var widgetId = this.id.split('/')[0];	
	var dragGroup = document.getElementById(widgetId);	
	var legendDiv = document.getElementById(widgetId+'/chartLegend');	
	if (typeof(opacity)!='undefined' && opacity < 1.0) {
		if (dragGroup != null) {
			dragGroup.style.background="transparent";
		}
		//var legendDiv = this.getEnclosingDiv();
		if (legendDiv != null) {
			dragGroup._transparent = 1; // JSL4503
			//legendDiv.style.background = 'transparent';
			var attrs = this.parseStyleSVG(this.legendStyle); // JSL4483
			var backgroundColor = attrs['background-color']; // JSL4483
			if (backgroundColor) {
				//var test = ZLM.convertColorToRGBA('RGBA(40,90,130,.50)', .50);
				//alert('test='+test);
				var rgba = ZLM.convertColorToRGBA(backgroundColor, opacity);
				legendDiv.style.backgroundColor = 'rgba('+rgba+')';
			} else {
				legendDiv.style.backgroundColor = 'rgba(255,255,255,'+opacity+')';
			}
			
			if (legendDiv.firstChild) {
				// DTB169 - Can't have a <table> backgroundColor in this case to make
				// sure there is no recursive opacity.
				legendDiv.firstChild.style.backgroundColor = 'rgba(255,255,255,0)';
			}
		} else {
			// how did we get here with no chart legend?
		}
	} else {
		if (legendDiv) {
			if (legendDiv.firstChild) {
				legendDiv.style.backgroundColor = legendDiv.firstChild.style.backgroundColor; // From Joe's code - some magic
			}
			if (dragGroup != null && !dragGroup._transparent) { // JSL4503 don't set background color to #F0F0F0 if dragGroup has been set to transparent
				dragGroup.style.backgroundColor = '#F0F0F0';
			}
		}
	}
}

/// Insert a single style item into the multi-item legendBorderStyle
ClientMethod setBorderStyle(borderStyleAttribute, value) [ Language = javascript ]
{
	// Method added by DTB169
	var legendArray = this.parseStyleSVG(this.legendBorderStyle);
	
	switch(borderStyleAttribute) {
		case 'stroke':
			// Border color
			legendArray['border-color'] = value;
			break;
		case 'stroke-width':
			legendArray['border-width'] = value + 'px';
			break;
		case 'stroke-dasharray':
			// solid, dashed, dotted
			legendArray['border-style'] = value;
			break;
		case 'opacity':						// DTB171 - Add opacity
			legendArray['opacity'] = value; 
			break;
	}
	
	this.legendBorderStyle = '';
	for (var key in legendArray) {
		this.legendBorderStyle += key + ':' + legendArray[key] + ';';
	}
	
 	this.renderContents();
}

}
