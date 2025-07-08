/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee score card component.
/// This is a subclass of chart as it shares the same data acquisition logic
/// (and uses many of the same style properties).
Class %DeepSee.Component.SVG.scoreCard Extends %ZEN.SVGComponent.chart [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter INCLUDEFILES = "dsparser.js";

/// Default viewBoxWidth of this component.
/// Turn off for score card.
Parameter DEFAULTVIEWBOXWIDTH;

/// Default viewBoxHeight of this component.
Parameter DEFAULTVIEWBOXHEIGHT;

/// Localization domain
Parameter DOMAIN = "%DeepSee";

/// Specification for columns within the scoreCard.
Property columns As list Of scoreCardColumn(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// How big to show items within this score card.
/// This can be "big" or "" (regular).
Property cardSize As %ZEN.Datatype.string;

/// Height (pixels) of rows within the scorecard.
Property rowHeight As %ZEN.Datatype.integer;

/// Computed height (pixels) of the scorecard.
Property cardHeight As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// Index of selected row (0-based).
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Optional. Style to apply to outer rectangle in plotBox.
Property plotBoxStyle As %ZEN.Datatype.svgStyle;

/// Optional. Style to apply to cell captions.
Property cellCaptionStyle As %ZEN.Datatype.svgStyle;

/// Optional. Style to apply to labels within lamps.
Property lampLabelStyle As %ZEN.Datatype.svgStyle;

/// Optional. Radius (as a percentage between 0 and 1) of a lamp.
Property lampSize As %ZEN.Datatype.float [ InitialExpression = 0.6 ];

/// Optional. Size (as a percentage between 0 and 1) of an arrow.
Property arrowSize As %ZEN.Datatype.float [ InitialExpression = 0.8 ];

/// Optional. Height (as a percentage between 0 and 1) of a plot box.
Property plotBoxHeight As %ZEN.Datatype.float [ InitialExpression = 0.8 ];

/// Optional. Height (as a percentage between 0 and 1) of the value bar within a plot box.
Property plotBoxValueHeight As %ZEN.Datatype.float [ InitialExpression = 0.5 ];

/// Optional. Style to apply to value bar in plotBox.
Property plotBoxValueStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill:rgb(47,98,128);" ];

/// Optional. Style to apply to negative value bar in plotBox.
Property plotBoxValueStyleNeg As %ZEN.Datatype.svgStyle [ InitialExpression = "fill:rgb(128,47,47);" ];

/// Optional. Style to apply to lower range rectangle in plotBox.
Property plotBoxLowerStyle As %ZEN.Datatype.svgStyle;

/// Optional. Style to apply to mid range rectangle in plotBox.
Property plotBoxMidStyle As %ZEN.Datatype.svgStyle;

/// Optional. Style to indicator arrows in plotBox.
Property arrowStyle As %ZEN.Datatype.svgStyle;

/// Optional. Color of indicator lamp.
Property lampColor As %ZEN.Datatype.string [ InitialExpression = "#80F080" ];

/// Optional. Color of negative indicator lamp.
Property lampColorNeg As %ZEN.Datatype.string [ InitialExpression = "#F08080" ];

/// Optional. Style for trendLine in plotBox.
Property trendLineStyle As %ZEN.Datatype.svgStyle;

/// Optional. Height (as a percentage between 0 and 1) of a trend line.
Property trendLineHeight As %ZEN.Datatype.float [ InitialExpression = 0.8 ];

/// Optional. Style for trendBars in plotBox.
Property trendBarsStyle As %ZEN.Datatype.svgStyle;

/// Optional. Height (as a percentage between 0 and 1) of a trend bar chart.
Property trendBarsHeight As %ZEN.Datatype.float [ InitialExpression = 0.8 ];

/// Optional. Style for column headers in plotBox.
Property columnHeaderStyle As %ZEN.Datatype.svgStyle;

/// Optional. Style for targetLine in plotBox.
Property targetLineStyle As %ZEN.Datatype.svgStyle;

/// If true, swap rows and columns within the data source for this scoreCard.
Property pivotData As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onclickrow event handler:
/// If defined, this event is fired when
/// the user clicks on a row within the score card.
Property onclickrow As %ZEN.Datatype.eventHandler;

/// Optional: alignment for title and subtitle.
/// (Default is left for scorecard).
Property titleAlign As %ZEN.Datatype.string(VALUELIST = ",center,left,right") [ InitialExpression = "left" ];

/// Optional: if true, display the title area.
Property titleVisible As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Optional: if true, display column headers.
Property headersVisible As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Optional: if true, display column footers.
Property footersVisible As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Optional: URL of image to display within the title area.
Property titleImage As %ZEN.Datatype.uri;

/// Optional. Style for titleImage: left,top,width, and height.
Property titleImageStyle As %ZEN.Datatype.svgStyle;

XData SVGStyle
{
<style type="text/css">

.scoreCardBackground {
	fill: #FFFFFE;
	stroke: none;
}

.scoreCardRowEven {
	fill: white;
	fill-opacity: 0;
	stroke: none;
}
.scoreCardRowOdd {
	fill: rgb(206,205,165);
	fill-opacity: 0.2;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardRowSelected {
	fill: #FFEEAA;
	stroke: blue;
	stroke-width: 0.1px;
}

/* line on top and bottom of card */
.scoreCardSeparator {
	fill: none;
	stroke: #404040;
	stroke-width: 0.25px;
	stroke-linecap: round;
}

.scoreCardTitle {
	pointer-events: none;
	font-size: 16pt;
	fill: rgb(164,57,39);
	stroke: none;
}

.scoreCardSubtitle {
	pointer-events: none;
	font-size: 10pt;
	fill: rgb(164,164,164);
	stroke: none;
}

.scoreCardHeader {
	pointer-events: none;
	font-size: 11pt;
	font-weight: bold;
	fill: #404040;
	stroke: none;
}

.scoreCardLabel {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardLabelBig {
	pointer-events: none;
	font-size: 18pt;
	fill: #404040;
	stroke: none;
}

.scoreCardCellCaption {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValue {
	pointer-events: none;
	font-size: 10pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValueBig {
	pointer-events: none;
	font-size: 20pt;
	fill: #404040;
	stroke: none;
}

.scoreCardTrendLine {
	fill: none;
	stroke: rgb(164,57,39);
	stroke-width: 2px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardTrendBars {
	fill: rgb(47,98,128);
	stroke: none;
	stroke-width: 1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardArrow {
	fill: #AA6666;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardLamp {
	stroke: none;
	stroke-width: 0.5px;
}

.scoreCardPlotBoxOuter {
	fill: #D0D0D0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxMiddle {
	fill: #B0B0B0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxInner {
	fill: #909090;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxValue {
	fill: #202020;
	stroke: none;
}

.scoreCardPlotBoxTarget {
	stroke: #202060;
	stroke-width: 2px;
	stroke-linecap: round;
	fill: none;
}

.scoreCardScale {
	stroke: #404040;
	stroke-width: 0.5px;
	fill: none;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.scoreCardScaleLabel {
	pointer-events: none;
	font-size: 7pt;
	fill: #404040;
	stroke: none;
}

</style>
}

/// No axes for a score card.
ClientMethod hasAxes() [ Language = javascript ]
{
	return false;
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	try {
		if (!this.hidden) {
			// get data from controller, if present.
			this.acquireData();

			// draw the contents of the score card.
			if (this.svgGroup) {
				this.unrender();
				this.renderScoreCard();
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in scoreCard.renderContents');
	}
}

/// Render the contents of this component.
ClientMethod renderScoreCard() [ Language = javascript ]
{
	try {
		var msg = null;
		this.cardHeight = 0;
		var smallTitle = false;
		var controller = this.getController();
		if (null == controller) {
			msg = $$$Text('Not connected to data source');
		}
		else if ('' !== zenGet(controller.modelError)) {
			msg = controller.modelError;
			smallTitle = true;
		}
		else if (this.columns.length == 0) {
			msg = $$$Text('There are no columns defined for this scorecard...');
		}
		else if (controller.hasData && !controller.hasData()) {
			msg = $$$Text('loading...');
		}

		var marginTop = (this.titleVisible || this.headersVisible) ? 5 : 0;
		var marginRight = 10;
		var marginLeft = 10;

		var titleText = this.title;
		var subtitleText = this.subtitle;
		var titleStyle = this.titleStyle;

		// array of logical row values
		this._rowValues = new Array();

		// JMD1107 2D array of cell information
		// used for items that are plotted *after* cell sizes are know
		var cellInfoEx = [];

		// background
		var rect = this.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('id',this.makeId('background'));
		rect.setAttribute('class','scoreCardBackground');
		rect.setAttribute("style",this.backgroundStyle);
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width',this.width);
		rect.setAttribute('height',this.height);
		this.svgGroup.appendChild(rect);

		var y = marginTop;

		// map base data to property names
		var scount = this.getSeriesCount();
		var ssize = this.getSeriesSize();
		var rowCount = !this.pivotData ? scount : ssize;

		var data = new Object();
		// values used for formula functions in expressions
		this._dataMinValue = new Object();
		this._dataMaxValue = new Object();
		this._dataCount = new Object();
		this._dataSum = new Object();

		// values used for summary row
		var colDataMinValue = new Array();
		var colDataMaxValue = new Array();
		if (controller) {
			if (!this.pivotData) {
				for (i = 0; i < ssize; i++) {
					// JMD997 use prop name and not label
					//var name = controller.getLabel(i,1);
					var name = controller.getPropertyName(i);
					if (name && '' !== name) {
						name = name.toString().toUpperCase();
						data[name] = new Array();
						for (var n = 0; n < scount; n++) {
							var val = this._dataSeries[n] ? this._dataSeries[n][i] : '';
							data[name][n] = val;
						}
					}
				}
			}
			else {
				// rotate data source 90 degrees
				for (i = 0; i < scount; i++) {
					//var name = controller.getLabel(i,2);
					var name = controller.getPropertyName(i);
					if (name && '' !== name) {
						name = name.toString().toUpperCase();
						data[name] = new Array();
						for (var n = 0; n < ssize; n++) {
							var val = this._dataSeries[i] ? this._dataSeries[i][n] : '';
							data[name][n] = val;
						}
					}
				}
			}
		}

		// compute values on properties
		for (var prop in data) {
			for (var r = 0; r < rowCount; r++) {
				var propU = prop.toString().toUpperCase();
				var val = data[propU][r];

				if (!isNaN(parseFloat(val))) {
					val = parseFloat(val);
					this._dataMinValue[propU] = ((null==this._dataMinValue[propU])||(val<this._dataMinValue[propU])) ? val : this._dataMinValue[propU];
					this._dataMaxValue[propU] = ((null==this._dataMaxValue[propU])||(val>this._dataMaxValue[propU])) ? val : this._dataMaxValue[propU];
					this._dataCount[propU] = (null==this._dataCount[propU]) ? 1 : this._dataCount[propU]+1;
					this._dataSum[propU] = (this._dataSum[propU] && 'number'==typeof this._dataSum[propU]) ? this._dataSum[propU]+val : val;
				}
			}
		}

		// see if there is a dataProperty supplying the title
		// remove these from list of columns
		var columnDefs = new Array();
		for (var c = 0; c < this.columns.length; c++) {
			var column = this.columns[c];
			if ('title' == column.display) {
				if ('' !== column.label) {
					titleText = column.label;
				}
				else if ('' !== column.dataValue) {
					var prop = this.getPropName(column.dataValue);
					var propU = prop.toString().toUpperCase();
					titleText = ('' === prop || null == data[propU]) ? column.dataValue : ((null == data[propU][0]) ? column.dataValue : data[propU][0]);
				}
			}
			else {
				// JMD997: test if column is conditional
				var hidden = false;
				if ('conditional'==column.showAs) {
					if ('' !== column.dataValue) {
						var prop = this.getPropName(column.dataValue);
						if (prop!=='') {
							var propU = prop.toString().toUpperCase();
							hidden = null==data[propU];
						}
					}
				}
				if (!hidden) {
					columnDefs[columnDefs.length] = column;
				}
			}
		}

		// now map data to dataValue name
		var hasFooter = false;
		var hasScale = false;
		for (var r = 0; r < rowCount; r++) {
			cellInfoEx[r] = [];
			this._rowValues[r] = '';
			for (var c = 0; c < columnDefs.length; c++) {
				var column = columnDefs[c];
				var val = (''===column.dataValue) ? '' : this.evaluate(column.dataValue,data,r);
				if (!isNaN(parseFloat(val))) {
					val = parseFloat(val);

					// these values are used for summary row
					colDataMinValue[c] = ((null==colDataMinValue[c])||(val<colDataMinValue[c])) ? val : colDataMinValue[c];
					colDataMaxValue[c] = ((null==colDataMaxValue[c])||(val>colDataMaxValue[c])) ? val : colDataMaxValue[c];
				}
				// if we are the value column, store the value
				if (column.valueColumn) {
					this._rowValues[r] = val;
				}
			
				// see if there is a totals row
				if ((r==0)&&((''!==column.summary)||('plotBox'!==column.display))) {
					hasFooter = this.footersVisible ? true : false;
					if ('plotBox'!==column.display) {
						hasScale = this.footersVisible ? true : false;
					}
				}
			}
		}

		// title
		if (null != msg) {
			titleText = msg;
			subtitleText = '';
			titleStyle = 'font-size:20pt;fill:darkred;';
			y += 10;
		}
		
		// image & image size
		var imageLeft = 0;
		var imageTop = 0;
		var imageWidth = 0;
		var imageHeight = 0;

		// use absolute URL for to render properly for PDF export
		if (this.titleImage) {
			var currUrl = window.location.href.split("/");
			var imageURL = currUrl[0] + "//" + currUrl[2] + "/csp/sys/" + this.titleImage;
			var imageStyle = this.titleImageStyle;
		}
		
		if (imageURL) {
			imageWidth = 50;
			imageHeight = 50;
			if (imageStyle) {
				var t = imageStyle.toString().split(';');
				for (var ti = 0; ti < t.length; ti++) {
					var t2 = t[ti].toString().split(':');
					switch (t2[0]) {
					case 'left':
						imageLeft = parseInt(t2[1]);
						break;
					case 'top':
						imageTop = parseInt(t2[1]);
						break;
					case 'width':
						imageWidth = parseInt(t2[1]);
						break;
					case 'height':
						imageHeight = parseInt(t2[1]);
						break;
					}
				}
			}
		}

		switch (this.titleAlign) {
		case 'right':
			var tx = parseInt(this.width) - marginRight;
			var anch = 'end';
			break;

		case 'center':
			var tx = parseInt(this.width) / 2;
			var anch = 'middle';
			break;

		case 'left':
		default:
			var tx = marginLeft + (imageLeft) + imageWidth;
			var anch = 'start';
			break;
		}

		if (this.titleVisible || msg!=null) {
			// rectangle under title (normally not shown)
			var trect = this.document.createElementNS(SVGNS,"rect");
			trect.setAttribute("class","chart-titleBox");
			trect.setAttribute("id",this.makeId('chartTitleBox'));
			trect.setAttribute("style",this.titleBoxStyle);
			this.svgGroup.appendChild(trect);

			if ('' !== titleText) {
				var title = this.document.createElementNS(SVGNS,'text');
				title.setAttribute('class','scoreCardTitle');
				title.setAttribute('style',titleStyle + (smallTitle?'font-size:8pt;':''));

				var textNode = this.document.createTextNode(titleText);
				title.appendChild(textNode);
				this.svgGroup.appendChild(title);
				var th = zenGetBBox(title).height;
				y += th;
				title.setAttribute('x',tx);
				title.setAttribute('y',y);
				title.setAttribute('text-anchor',anch);
				if (null != msg) {
					y += 10;
				}
			}
			if ('' !== subtitleText) {
				var subtitle = this.document.createElementNS(SVGNS,'text');
				subtitle.setAttribute('class','scoreCardSubtitle');
				subtitle.setAttribute('style',this.subtitleStyle);

				var textNode = this.document.createTextNode(subtitleText);
				subtitle.appendChild(textNode);
				this.svgGroup.appendChild(subtitle);
				var th = Math.floor(zenGetBBox(subtitle).height * 1.2);
				y += th;
				subtitle.setAttribute('x',tx);
				subtitle.setAttribute('y',y-3);
				subtitle.setAttribute('text-anchor',anch);
			}

			// move title box
			trect.setAttribute("x", 0);
			trect.setAttribute("y", 0);
			trect.setAttribute("width", this.width);
			trect.setAttribute("height",y?(y+10):0);
		} // title

		if (null != msg) {
			this.cardHeight = y;
			return;
		}

		if (imageURL) {
			var image = document.createElementNS(SVGNS,'image');
			image.setAttributeNS('http://www.w3.org/1999/xlink','xlink:href',imageURL);
			image.setAttribute('preserveAspectRatio','none');
			image.setAttribute('x',imageLeft);
			image.setAttribute('y',imageTop);
			image.setAttribute('width',imageWidth);
			image.setAttribute('height',imageHeight);
			this.svgGroup.appendChild(image);

			if (y < (imageHeight + imageTop)) {
				y = imageHeight + imageTop;
				trect.setAttribute("height",y?(y+imageTop):0);
			}
		}

		if (this.titleVisible || imageHeight) {
			y += 5;
		}

		var padding = parseFloat(this.width) / 10;
		padding = (padding < 5) ? 5 : padding;
		padding = (padding > 20) ? 20 : padding;
		var width = parseFloat(this.width) - (marginLeft + marginRight) - ((columnDefs.length-1) * padding);
		var colWidth = 100; // place holder

		// max width of value in column
		var colMaxWidths = new Array(columnDefs.length);

		// width of header label
		var colHeaderWidths = new Array(columnDefs.length);

		var nameToPosition = null;

		// draw column headers
		var x = marginLeft;
		var headerHeight = 0;
		var headerBoxes = [];
		if (this.headersVisible) {
			for (var c = 0; c < columnDefs.length; c++) {
				var column = columnDefs[c];
				var label = column.label;
				// JMD997 Test for $auto
				if (label=='$auto' && column.dataValue != '') {
					var axisNo = this.pivotData ? 2 : 1;
					label = '';
					if (!nameToPosition) {
						nameToPosition = {};
						// create map of source names to positions
						var props = controller.getDimSize(axisNo);
						for (var p1 = 0; p1 < props; p1++) {
							var pn = controller.getPropertyName(p1);
							if (pn!='') {
								nameToPosition[pn] = p1;
							}
						}
					}

					var propx = this.getPropName(column.dataValue);
					if (propx!='') {
						var p1 = nameToPosition[propx];
						if ('undefined' != typeof p1) {
							label = controller.getLabel(p1,axisNo);
						}
						else {
							label = propx;
						}
					}
				} else if (label=='$auto' && column.display=='label') {
					// PFS020 - Handle the label display column
					label = controller.rowCaptionList.join('/')
				}
				var align = column.align;
				var hdrAlign = column.headerAlign;
				if ('' !== label && 'hidden' != column.display) {
					// clip box for header
					var svg = this.document.createElementNS(SVGNS,'svg');
					this.svgGroup.appendChild(svg);
					headerBoxes[c] = svg;

					// split text by '\n' within the text
					var th = 0;
					var totalH = 0;
					var headers = new Array();
					var labelt = label.split('\\n');
					for (var t = 0;t < labelt.length;t++) {
						var header = this.document.createElementNS(SVGNS,'text');
						headers[headers.length] = header;

						header.setAttribute('class','scoreCardHeader');
						header.setAttribute('style',this.columnHeaderStyle);
						if (column.display == 'value' || column.display == '') {
							header.setAttribute('text-anchor','end');
							header.setAttribute('x','98%');
						}
						else {
							header.setAttribute('x',0);
						}
						// if hdrAlign is defined, apply it
						if (hdrAlign=='left') {
							header.setAttribute('x','5%');
							header.setAttribute('text-anchor','start');
						}
						else if (hdrAlign=='right') {
							header.setAttribute('x','95%');
							header.setAttribute('text-anchor','end');
						}
						else if (hdrAlign=='center') {
							header.setAttribute('x','50%');
							header.setAttribute('text-anchor','middle');
						}

						var textNode = this.document.createTextNode(labelt[t]);
						header.appendChild(textNode);
						svg.appendChild(header);
						var bbox = zenGetBBox(header);
						th = bbox.height * 1.2;
						totalH += th;

						var tw = bbox.width * 1.2;
						// note the widths
						colHeaderWidths[c] = (null == colHeaderWidths[c] || tw > colHeaderWidths[c]) ? tw : colHeaderWidths[c];
					}

					if (0 == headerHeight) {
						headerHeight = totalH;
					}
					svg.setAttribute('x',x);
					svg.setAttribute('y',y);
					svg.setAttribute('width',colWidth + 'px');
					svg.setAttribute('height',headerHeight + 'px');

					// place text items
					var hy = headerHeight - 3
					for (var h = headers.length-1;h >= 0;h--) {
						headers[h].setAttribute('y',hy);
						hy -= (th*0.8);
					}
				}
				if ('hidden'!= column.display) {
					x += parseFloat(colWidth) + padding;
				}
			}
			y += 2 + headerHeight;
		} // headers

		// separator
		var line = this.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',0);
		line.setAttribute('x1',this.width);
		line.setAttribute('y1',y);
		line.setAttribute('y2',y);
		line.setAttribute('class','scoreCardSeparator');
		// use grid style for override
		line.setAttribute('style',this.gridStyle);
		this.svgGroup.appendChild(line);

		if (columnDefs.length == 0) {
			this.cardHeight = y;
			return;
		}

		// determine rowHeight
		var rowHeight = this.rowHeight;
		if (''==rowHeight) {
			var text = this.document.createElementNS(SVGNS,'text');
			text.setAttribute('class',this.cardSize=='big' ? 'scoreCardLabelBig' : 'scoreCardLabel');
			text.setAttribute('x',0);
			text.setAttribute('y',20);
			var textNode = this.document.createTextNode('Ap');
			text.appendChild(textNode);
			this.svgGroup.appendChild(text);
			rowHeight = zenGetBBox(text).height * 1.5;
			this.svgGroup.removeChild(text);
		}
		rowHeight = parseInt(rowHeight);
		rowHeight = (rowHeight < 0) ? 0 : rowHeight;
		
		// cells
		var plotMinValues = new Array(columnDefs.length);
		var plotMaxValues = new Array(columnDefs.length);
		var plotBaseValues = new Array(columnDefs.length);

		var summaryValues = new Array(columnDefs.length);
		var rowCells = new Array(rowCount); // array of svg elements
		for (var r = 0; r < rowCount; r++) {
			y += rowHeight;
			var itemNo = (r+1);
			var label = '';
			if (controller) {
				if (this.pivotData) {
					label = controller.getLabel(r,1);
				}
				else {
					label = controller.getLabel(r,2);
				}
			}

			// backing rect for row
			var rect = this.document.createElementNS(SVGNS,'rect');
			rect.setAttribute('id',this.makeId('row_'+r));
			rect.setAttribute('class',(r == this.selectedIndex) ? 'scoreCardRowSelected' : r%2?'scoreCardRowEven':'scoreCardRowOdd');
			if (r%2==0) {
				rect.setAttribute('style',this.stripeStyle);
			}
			rect.setAttribute('x',0);
			rect.setAttribute('y',y-rowHeight);
			rect.setAttribute('width',this.width);
			rect.setAttribute('height',rowHeight);
			this.svgGroup.appendChild(rect);

			var eventHandler = new Function('evt','row','return zenPage.getComponent('+this.index+').rowClickHandler(evt,"'+r+'");');
			rect.addEventListener('click',eventHandler,false);

			// draw columns
			var x = marginLeft;
			rowCells[r] = new Array(columnDefs.length);
			for (var c = 0; c < columnDefs.length; c++) {

				var column = columnDefs[c];
				var value = '';
				var minValue = 0;
				var maxValue = 100;
				var baseValue = null;
				var targetValue = 0;
				var thresholdLower = 0;
				var thresholdUpper = 0;
				var rangeUpper = null;
				var rangeLower = null;
				var isPct = false;
				var align = column.align;
				var hdrAlign = column.headerAlign;

				var prop = this.getPropName(column.dataValue);
				value = this.evaluate(column.dataValue,data,r);
				var colStyle = column.style;
				if ('' != colStyle && (colStyle.toString().charAt(0)=='=')) {
					colStyle = this.evaluate(colStyle,data,r);
				}

				if (''!==value && !isNaN(value)) {
					if (''!==column.dataValue) {
						maxValue = colDataMaxValue[c];
					}
					if (''!==column.dataValue) {
						minValue = colDataMinValue[c];
					}
					if (minValue > 0) {
						minValue = 0;
					}

					var v = this.evaluate(column.targetValue,data,r);
					if (''!==v && !isNaN(v)) {
						targetValue = v;
					}
					var v = this.evaluate(column.rangeLower,data,r);
					if (''!==v && !isNaN(v)) {
						rangeLower = v;
					}
					var v = this.evaluate(column.rangeUpper,data,r);
					if (''!==v && !isNaN(v)) {
						rangeUpper = v;
					}
					if ('' !== column.baseValue) {
						var v = this.evaluate(column.baseValue,data,r);
						if (''!==v && !isNaN(v)) {
							baseValue = v;
						}
					}

					if (null != rangeUpper) {
						maxValue = rangeUpper;
					}
					if (null != rangeLower) {
						minValue = rangeLower;
					}

					if ('' != column.thresholdLower) {
						var v = this.evaluate(column.thresholdLower,data,r);
						if (''!==v && !isNaN(v)) {
							thresholdLower = v;
						}
					}
					if ('' != column.thresholdUpper) {
						var v = this.evaluate(column.thresholdUpper,data,r);
						if (''!==v && !isNaN(v)) {
							thresholdUpper = v;
						}
					}

					// apply showAs
					var propU = prop.toString().toUpperCase();
					switch(column.showAs) {
					case 'sum':
						value = (''==propU || null==this._dataSum[propU]) ? 0 : this._dataSum[propU];
						break;
					case 'sum%':
						var dsum = (''==propU || null==this._dataSum[propU]) ? 0 : this._dataSum[propU];
						value = (dsum!=0) ? (value / dsum) : 0;
						isPct = true;
						break;
					case 'target':
						value = targetValue;
						break;
					case 'target%':
						value = (targetValue>0) ? (value / targetValue) : 0;
						maxValue = (targetValue>0) ? (maxValue / targetValue) : 0;
						isPct = true;
						break;
					case 'value':
					case 'hidden':
					default:
						break;
					}
				}

				if (isPct) {
					var format = (''===column.format) ? '#.##%' : column.format;
					var valueFmt = ('number'== typeof value) ? zenFormatNumber(value,format) : value;
				}
				else {
					var format = (''===column.format) ? '#,#' : column.format;
					// JMD1202: see if value is a number!
					if (parseFloat(value) == value) {
						var valueFmt = zenFormatNumber(value,format);
					}
					else {
						var valueFmt = value;
					}
				}
				var display = column.display;
				
				// accumulate values for summary (footer) row
				var avalue = parseFloat(value);
				if (!isNaN(avalue)) {

					switch(column.summary) {
					case 'sum':
					case 'avg':
						summaryValues[c] = (summaryValues[c]?summaryValues[c]+avalue:avalue);
						break;
					case 'min':
						summaryValues[c] = (summaryValues[c]?(summaryValues[c]<avalue?summaryValues[c]:avalue):avalue);
						break;
					case 'max':
						summaryValues[c] = (summaryValues[c]?(summaryValues[c]>avalue?summaryValues[c]:avalue):avalue);
						break;
					case 'value':
					default:
						// compute at end
						summaryValues[c] = '';
						break;
					}
				}

				// clip box for cell
				if ('hidden' != display) {
					var svg = this.document.createElementNS(SVGNS,'svg');
					svg.setAttribute('x',x);
					svg.setAttribute('y',y-rowHeight);
					if (colWidth!='') {
						svg.setAttribute('width',colWidth + 'px');
					}
					if (rowHeight!='') {
						svg.setAttribute('height',rowHeight + 'px');
					}
					this.svgGroup.appendChild(svg);
					rowCells[r][c] = svg;
				}

				// cell caption and labels if present
				var cellCaption = zenGet(column.cellCaption);
				if ('' != cellCaption && (cellCaption.toString().charAt(0)=='=')) {
					cellCaption = this.evaluate(cellCaption,data,r);
				}

				var cellCaptionH = 0;
				if (cellCaption && display!='hidden' && rowHeight > 10) {
					var text = this.document.createElementNS(SVGNS,'text');
					text.setAttribute('class','scoreCardCellCaption');
					text.setAttribute('style',this.cellCaptionStyle);
					text.setAttribute('x',0);
					text.setAttribute('y',(rowHeight*0.9));
					
					if (align=='right') {
						text.setAttribute('x','95%');
						text.setAttribute('text-anchor','end');
					}
					else if (align=='center') {
						text.setAttribute('x','50%');
						text.setAttribute('text-anchor','middle');
					}

					var textNode = this.document.createTextNode(cellCaption);
					text.appendChild(textNode);
					svg.appendChild(text);
					var tw = zenGetBBox(text).width *1.2;
					cellCaptionH = zenGetBBox(text).height;
					colMaxWidths[c] = (null == colMaxWidths[c] || tw > colMaxWidths[c]) ? tw : colMaxWidths[c];
				}

				switch(display) {
				case 'hidden':
					colWidth = 0;
					break;
				case 'trendLine':
					// render in 2nd pass
					var vals = value.toString().split(',');
					
					// remember values for 2nd pass
					cellInfoEx[r][c] = { vals:vals, cellCaptionH:cellCaptionH};

					colMaxWidths[c] = width / 10;
					break;

				case 'trendBars':
					// render in 2nd pass
					var vals = value.toString().split(',');

					// remember values for 2nd pass
					cellInfoEx[r][c] = { vals:vals, cellCaptionH:cellCaptionH};

					colMaxWidths[c] = width / 10;
					break;

				case 'arrow':
					if (minValue < 0) {
						var arrowValue = (isNaN(parseFloat(value))) ? 0 : ((parseFloat(value))/maxValue);
					}
					else {
						var arrowValue = (isNaN(parseFloat(value))) ? 0 : ((parseFloat(value)-minValue)/maxValue);
					}
					if (!isNaN(parseFloat(arrowValue)) && parseFloat(arrowValue)!=0) {
						var path = this.document.createElementNS(SVGNS,'path');
						path.setAttribute('class','scoreCardArrow');
						path.setAttribute('style',this.arrowStyle + colStyle);
						var cx = (rowHeight-cellCaptionH)*0.5;
						var p1 = (rowHeight-cellCaptionH)*(0.5-(parseFloat(this.arrowSize)/2));
						var p2 = (rowHeight-cellCaptionH)*(0.5+(parseFloat(this.arrowSize)/2));
						if (parseFloat(arrowValue)>0) {
							var d = 'M '+cx+' '+p1+' L '+p1+' '+p2+' '+p2+' '+p2+' z'; // up
						}
						else {
							var d = 'M '+cx+' '+p2+' L '+p1+' '+p1+' '+p2+' '+p1+' z'; // down
						}
						path.setAttribute('d',d);
						svg.appendChild(path);
						path.addEventListener('click',eventHandler,false);
						cellInfoEx[r][c] = { shape: path, width:cx*2 };
					}
					colMaxWidths[c] = rowHeight;
					break;

				case 'lamp':
				case 'lamp-value':
					if (maxValue < 0) {
						var lampValue = (isNaN(parseFloat(value))) ? 0 : -((parseFloat(value))/maxValue);
					}
					else {
						var lampValue = (isNaN(parseFloat(value))) ? 0 : ((parseFloat(value))/maxValue);
					}
					if (!isNaN(parseFloat(lampValue)) && parseFloat(lampValue)!=0) {
						var g = this.document.createElementNS(SVGNS,'g');
						svg.appendChild(g);

						var lamp = this.document.createElementNS(SVGNS,'circle');
						lamp.setAttribute('class','scoreCardLamp');
						if (lampValue > 0) {
							var lcr = (this.lampColor == "") ? '#80F080' : this.lampColor;
						}
						else {
							var lcr = (this.lampColorNeg == "") ? '#F08080' : this.lampColorNeg;
							lampValue = -lampValue;
						}
						var ls = 'fill:'+lcr+';';
						lamp.setAttribute('fill-opacity',lampValue);
						var rad = ((rowHeight-cellCaptionH)*0.5*parseFloat(this.lampSize));
						lamp.setAttribute('cx',rad);
						lamp.setAttribute('cy',((rowHeight-cellCaptionH)*0.5));
						lamp.setAttribute('r',rad);
						if (''!=colStyle) {
							ls = ls + colStyle;
						}
						lamp.setAttribute('style',ls);
						g.appendChild(lamp);
						lamp.addEventListener('click',eventHandler,false);
						
						var text = null;
						if (display=='lamp-value') {
							// show value within lamp
							text = this.document.createElementNS(SVGNS,'text');
							text.setAttribute('class',this.cardSize=='big' ? 'scoreCardValueBig' : 'scoreCardValue');
							text.setAttribute('style',this.lampLabelStyle);
							text.setAttribute('text-anchor','middle');
							var textNode = this.document.createTextNode(valueFmt);
							text.appendChild(textNode);
							g.appendChild(text);
							var tw = zenGetBBox(text).width*1.2;
							var th = zenGetBBox(text).height;
							text.setAttribute('x',rad);
							text.setAttribute('y',((rowHeight-cellCaptionH)*0.5)+((th*0.7)/2));
							if (tw>(rad*1.8)) {
								var oldNode = text.firstChild;
								text.removeChild(oldNode);
								textNode = this.document.createTextNode('#');
								text.appendChild(textNode);
								text.setAttribute('style',this.lampLabelStyle+'font-size:10px;');
								var th = zenGetBBox(text).height;
								text.setAttribute('y',((rowHeight-cellCaptionH)*0.5)+((th*0.7)/2));
							}
						}
						cellInfoEx[r][c] = { shape: g, width:rad*2 };
					}
					colMaxWidths[c] = rowHeight;
					break;

				case 'plotBox':
					// render in 2nd pass

					// compute sizes
					var range = (maxValue-minValue);
					if (range == 0) break;
					var outerX = 95;
					var middleX = (isNaN(parseFloat(thresholdUpper))) ? 0 : ((parseFloat(thresholdUpper)-minValue)/range)*outerX;
					var innerX = (isNaN(parseFloat(thresholdLower))) ? 0 : ((parseFloat(thresholdLower)-minValue)/range)*outerX;
					var targetX = (isNaN(parseFloat(targetValue))) ? 0 : ((parseFloat(targetValue)-minValue)/range)*outerX;

					if ('' === baseValue) {
						var valueX1 = 0;
						var valueX2 = (isNaN(parseFloat(value))) ? 0 : ((parseFloat(value)-minValue)/range)*outerX;
					}
					else {
						var valueX1 = (isNaN(parseFloat(baseValue))) ? 0 : ((parseFloat(baseValue)-minValue)/range)*outerX;
						var valueX2 = (isNaN(parseFloat(value))) ? 0 : ((parseFloat(value)-minValue)/range)*outerX;
					}
					if (r==0) {	
						plotMinValues[c] = minValue;
						plotMaxValues[c] = maxValue;
						plotBaseValues[c] = baseValue;
					}

					// remember values for 2nd pass
					cellInfoEx[r][c] = {
						outerX:outerX,
						middleX:middleX,
						innerX:innerX,
						targetX:targetX, 
						valueX1:valueX1,
						valueX2:valueX2,
						cellCaptionH:cellCaptionH,
						eventHandler:eventHandler };

					break;

				case 'label':
					var text = this.document.createElementNS(SVGNS,'text');
					text.setAttribute('class',this.cardSize=='big' ? 'scoreCardLabelBig' : 'scoreCardLabel');
					text.setAttribute('style',this.labelStyle + colStyle);
					text.setAttribute('x',0);
					text.setAttribute('y',((rowHeight-cellCaptionH)*0.8));

					if (align=='right') {
						text.setAttribute('x','95%');
						text.setAttribute('text-anchor','end');
					}
					else if (align=='center') {
						text.setAttribute('x','50%');
						text.setAttribute('text-anchor','middle');
					}

					var textNode = this.document.createTextNode(label);
					text.appendChild(textNode);
					svg.appendChild(text);
					var tw = zenGetBBox(text).width *1.2;
					var th = zenGetBBox(text).height;
					colMaxWidths[c] = (null == colMaxWidths[c] || tw > colMaxWidths[c]) ? tw : colMaxWidths[c];
					cellInfoEx[r][c] = { text: text, height:th, cellCaptionH:cellCaptionH };

					break;
				case 'value':
				case 'itemNo':
				default:
					var text = this.document.createElementNS(SVGNS,'text');
					text.setAttribute('class',this.cardSize=='big' ? 'scoreCardValueBig' : 'scoreCardValue');
					text.setAttribute('style',this.valueLabelStyle + colStyle);
					text.setAttribute('y',((rowHeight-cellCaptionH)*0.8));
					if (align=='left') {
						text.setAttribute('x','5%');
						text.setAttribute('text-anchor','start');
					}
					else if (align=='center') {
						text.setAttribute('x','50%');
						text.setAttribute('text-anchor','middle');
					}
					else {
						text.setAttribute('x','95%');
						text.setAttribute('text-anchor','end');
					}
					if ('itemNo'==display) {
						var itemFmt = format ? zenFormatNumber(itemNo,format):(itemNo+".");
						var textNode = this.document.createTextNode(itemFmt);
					}
					else {
						var textNode = this.document.createTextNode(valueFmt);
					}
					text.appendChild(textNode);
					svg.appendChild(text);
					var tw = zenGetBBox(text).width*1.2;
					var th = zenGetBBox(text).height;
					colMaxWidths[c] = (null == colMaxWidths[c] || tw > colMaxWidths[c]) ? tw : colMaxWidths[c];
					cellInfoEx[r][c] = { text: text, height:th,cellCaptionH:cellCaptionH };
					break;
				}
				if ('hidden' != display) {
					x += parseFloat(colWidth) + padding;
				}
			} // row
		}

		// draw footer row and text
		var footerBoxes = null;
		if (hasFooter) {
			// backing rect for row
			var rect = this.document.createElementNS(SVGNS,'rect');
			rect.setAttribute('class',rowCount%2?'scoreCardRowEven':'scoreCardRowOdd');
			rect.setAttribute('x',0);
			rect.setAttribute('y',y);
			rect.setAttribute('width',this.width);
			rect.setAttribute('height',rowHeight);
			this.svgGroup.appendChild(rect);

			// separator
			var line = this.document.createElementNS(SVGNS,'line');
			line.setAttribute('x1',0);
			line.setAttribute('x1',this.width);
			line.setAttribute('y1',y);
			line.setAttribute('y2',y);
			line.setAttribute('class','scoreCardSeparator');
			// use grid style for override
			line.setAttribute('style',this.gridStyle);
			this.svgGroup.appendChild(line);

			// set up summary data in case there are formulae based on it
			var summaryData = {};
			for (var c = 0; c < columnDefs.length; c++) {
				var column = columnDefs[c];
				if ('' !== column.label) {
					var lu = column.label.toString().toUpperCase();
					summaryData[lu] = [summaryValues[c]];
				}
			}

			var x = marginLeft;
			footerBoxes = new Array(columnDefs.length);
			for (var c = 0; c < columnDefs.length; c++) {
				var column = columnDefs[c];
				var align = column.align;
				var hdrAlign = column.headerAlign;
				if ('hidden' != column.display) {
					var footerValue = '';
					if (''!==column.summary) {
						footerValue = (null==summaryValues[c])?'':summaryValues[c];
						if ('avg'==column.summary) {
							footerValue = (rowCount>0) ? footerValue/rowCount : 0;
						}
						else if ('value'==column.summary) {
							// use column summaries as values
							// assume there are no references to items that are not resolved yet
							var v = this.evaluate(column.summaryValue,summaryData,0);
							if (''!==v && !isNaN(v)) {
								footerValue = v;
							}
						}
					}

					if ('' !== footerValue) {
						// show footer text
						if ('target%' == column.showAs || 'sum%' == column.showAs) {
							var format = (''===column.format) ? '#,#.##%' : column.format;
						}
						else {
							var format = (''===column.format) ? '#,#' : column.format;
						}
						var valueFmt = zenFormatNumber(footerValue,format);

						// clip box for footer
						var svg = this.document.createElementNS(SVGNS,'svg');
						this.svgGroup.appendChild(svg);
						footerBoxes[c] = svg;

						var footer = this.document.createElementNS(SVGNS,'text');
						footer.setAttribute('class',this.cardSize=='big' ? 'scoreCardLabelBig' : 'scoreCardLabel');
						footer.setAttribute('y',(rowHeight*0.75));
						footer.setAttribute('x','95%');
						if (align=='left') {
							footer.setAttribute('x','5%');
							footer.setAttribute('text-anchor','start');
						}
						else if (align=='center') {
							footer.setAttribute('x','50%');
							footer.setAttribute('text-anchor','middle');
						}
						else {
							footer.setAttribute('x','95%');
							footer.setAttribute('text-anchor','end');
						}
						footer.setAttribute('style','font-weight:bold;');
						var textNode = this.document.createTextNode(valueFmt);
						footer.appendChild(textNode);
						svg.appendChild(footer);

						var tw = zenGetBBox(footer).width * 1.2;
						// use header widths
						colHeaderWidths[c] = (null == colHeaderWidths[c] || tw > colHeaderWidths[c]) ? tw : colHeaderWidths[c];

						svg.setAttribute('x',x);
						svg.setAttribute('y',y);
						svg.setAttribute('width',colWidth + 'px');
						svg.setAttribute('height',rowHeight + 'px');
						footer.setAttribute('y',rowHeight - 3);
					}
					x += parseFloat(colWidth) + padding;
				}
			}
			y += rowHeight;
		}

		// compute column widths
		var colWidths = new Array(columnDefs.length);
		var budget = width * 0.9;
		var unbudgeted = 0;
		for (var c = 0; c < columnDefs.length; c++) {
			var column = columnDefs[c];
			if ('hidden' == column.display) {
				colWidths[c] = 0;
			}
			else {
				var w = parseFloat(column.width);
				if (isNaN(w)) {
					if (null == colMaxWidths[c]) {
						unbudgeted++;
					}
					else {
						w = colMaxWidths[c];
						if ('number'!=typeof w) {
							w = 0;
						}
						w = (null!=colHeaderWidths[c] && w<colHeaderWidths[c]) ? colHeaderWidths[c] : w;
						w = (w<0) ? 0 : w;
						colWidths[c] = w;
						budget -= w;
					}
				}
				else if(column.width.toString().indexOf('%') > 0) {
					w = (w/100) * width;
					w = (w<0) ? 0 : w;
					colWidths[c] = w;
					budget -= w;
				}
				else {
					w = (w<0) ? 0 : w;
					colWidths[c] = w;
					budget -= w;
				}
			}
		}
		budget = budget < 0 ? 0 : budget;
		if (unbudgeted > 0) {
			for (var c = 0; c < columnDefs.length; c++) {
				if (null == colWidths[c]) {
					colWidths[c] = budget / unbudgeted;
					// don't let items be too big or too small
					colWidths[c] = (colWidths[c] < (width/3)) ? colWidths[c] : width/3;
					colWidths[c] = (colWidths[c] > 20) ? colWidths[c] : 20;
				}
			}
		}

		// adjust widths
		var x = padding/2;
		for (var c = 0; c < headerBoxes.length; c++) {
			var svg = headerBoxes[c];
			if (svg) {
				svg.setAttribute('x',x);
				svg.setAttribute('width',colWidths[c]);
				// fix for justify
				for (var hn = 0; hn < svg.childNodes.length; hn++) {
					var anc = svg.childNodes[hn] ? svg.childNodes[hn].getAttribute('text-anchor') : '';
					if (anc=='end') {
						svg.childNodes[hn].setAttribute('x',colWidths[c]);
					}
					else if (anc=='middle') {
						svg.childNodes[hn].setAttribute('x',colWidths[c]/2);
					}
				}
			}

			var svg = footerBoxes ? footerBoxes[c] : null;
			if (svg) {
				svg.setAttribute('x',x);
				svg.setAttribute('width',colWidths[c]);

				// fix for justify
				for (var hn = 0; hn < svg.childNodes.length; hn++) {
					var anc = svg.childNodes[hn] ? svg.childNodes[hn].getAttribute('text-anchor') : '';
					if (anc=='end') {
						svg.childNodes[hn].setAttribute('x',colWidths[c]);
					}
					else if (anc=='middle') {
						svg.childNodes[hn].setAttribute('x',colWidths[c]/2);
					}
				}
			}

			// debug rects
			/*
			var drect = this.document.createElementNS(SVGNS,'rect');
			drect.setAttribute('style','fill: none; stroke:red;');
			drect.setAttribute('x',x);
			drect.setAttribute('y',20);
			drect.setAttribute('width',colWidths[c] + 'px');
			drect.setAttribute('height',10 + 'px');
			this.svgGroup.appendChild(drect);
			*/

			if (colWidths[c] > 0) {
				x += colWidths[c] + padding;
			}
		}

		for (var r = 0; r < rowCells.length; r++) {
			var x = padding/2;
			for (var c = 0; c < rowCells[r].length; c++) {
				var svg = rowCells[r][c];
				if (svg) {
					svg.setAttribute('x',x);
					svg.setAttribute('width',colWidths[c]);
					// fix for right-justify
					for (var hn = 0; hn < svg.childNodes.length; hn++) {
						var anc = svg.childNodes[hn] ? svg.childNodes[hn].getAttribute('text-anchor') : '';
						if (anc=='end') {
							svg.childNodes[hn].setAttribute('x',colWidths[c]);
						}
						else if (anc=='middle') {
							svg.childNodes[hn].setAttribute('x',colWidths[c]/2);
						}
					}
				}

				// JMD1107
				// some columns need rendering/adjusting at this point (as we know the size)
				var column = columnDefs[c];
				var colStyle = column.style;
				var display = column.display;
				var	cellScaleX = parseInt(colWidths[c])/100;
				var align = column.align;

				if (cellInfoEx && cellInfoEx[r] && cellInfoEx[r][c]) {
					switch(display) {
					case 'label':
					case 'value':
					case 'itemNo':
					default:
						// vertical align
						var text = cellInfoEx[r][c].text;
						var hgt = cellInfoEx[r][c].height;
						var cellCaptionH = zenGet(cellInfoEx[r][c].cellCaptionH);
						cellCaptionH = cellCaptionH ? cellCaptionH : 0;
						if (text && hgt) {
							text.setAttribute('y',(rowHeight/2)+(hgt*0.35)-(cellCaptionH/2));
						}
						break;

					case 'lamp':
					case 'lamp-value':
					case 'arrow':
						// apply alignment
						var shape = cellInfoEx[r][c].shape;
						var wid = cellInfoEx[r][c].width;
						var text = cellInfoEx[r][c].text;
						if (shape && wid) {
							var dx = 0;
							switch(align) {
							case 'right':
								dx = colWidths[c] - wid;
								break;
							case 'center':
								dx = colWidths[c]/2 - wid/2;
								break;
							}
							shape.setAttribute('transform','translate('+dx+',0)');
						}
						break;

					case 'trendLine':
						// DTB106 - This section is where the path is drawn
						// get cached values
						var vals = cellInfoEx[r][c].vals; 
						var path = this.document.createElementNS(SVGNS,'path');
						
						path.setAttribute('class','scoreCardTrendLine');
						path.setAttribute('style',this.trendLineStyle + colStyle);
						svg.appendChild(path);
						
						var cellCaptionH = cellInfoEx[r][c].cellCaptionH;
						var cellScaleY = parseInt(rowHeight-cellCaptionH)/100;

						// size
						var tlPct = parseFloat(this.trendLineHeight);
						var tlBot = 50 + (50 * tlPct);
						var tlHeight = (100 * tlPct);
						
						// find range of values for all values in this trendLine element
						var min = null;
						var max = null;
						for (var j = 0; j < vals.length; j++) {
							var v = parseFloat(vals[j]);
							if (!isNaN(v)) {
								min = (min==null || v < min) ? v : min;
								max = (max==null || v > max) ? v : max;
							}
						}
						// now construct path
						// DTB106 - the path supports multiple disconnected segments
						var d = '';
						if (vals.length > 1 && min!=null && max!=null && max>min) {
							var px = 0;
							var seg = 100 / (vals.length-1);
							var inSegment = 0;		// DTB106
							var start = 0;			// DTB106
							for (var j = 0; j < vals.length; j++) {
								var v = parseFloat(vals[j]);
								if (!isNaN(v)) {
									v = Math.round(tlBot - (tlHeight*((v - min) / (max - min))));
									if (!inSegment) {	
										// DTB106 - This is the first real value in a potential set.
										// Issue the M command and mark this as the starting position 
										inSegment = 1;
										start = j
										d += d.length ? ' ' : '';
										d += 'M ' + (px*cellScaleX).toFixed(2) + ' ' + (v*cellScaleY);
									}
									else {
										// DTB106 - this is a continuing set, add elements
										if (j-1 == start) {
											// DTB106 - if this is the second value, issue an L command 
											d += ' L'; 
										}
										d += ' ' + (px*cellScaleX).toFixed(2) + ' ' + (v*cellScaleY);
									}
								}
								else {
									// DTB106 - a null value indicates a segment is completed
									inSegment = 0;
								}
								px += seg;
							}
						}
						if (vals.length == 1 && min!=null && max!=null && max>min) {
							var v = parseFloat(vals[0]);
							if (!isNaN(v)) {
								v = Math.round(tlBot - (tlHeight*((v - min) / (max - min))));
								d = 'M 0 ' + (v*cellScaleY) + ' L '+(100*cellScaleX)+' ' + (v*cellScaleY);
							}
						}

						// DTB106 - Use the data built above.
						// Leave the trendLine blank if there is no data
						path.setAttribute('d',d);
						break;

					case 'trendBars':
						// get cached values
						var vals = cellInfoEx[r][c].vals;
						var cellCaptionH = cellInfoEx[r][c].cellCaptionH;
						var cellScaleY = parseInt(rowHeight-cellCaptionH)/100;

						// size
						var tbPct = parseFloat(this.trendBarsHeight);
						var tbBot = 50 + (50 * tbPct);
						var tbHeight = (100 * tbPct);

						// find range of values
						var min = null;
						var max = null;
						for (var j = 0; j < vals.length; j++) {
							var v = parseFloat(vals[j]);
							if (!isNaN(v)) {
								min = (min==null || v < min) ? v : min;
								max = (max==null || v > max) ? v : max;
							}
						}
						// now create bars
						var d = '';
						if (vals.length > 0 && min!=null && max!=null && max>min) {
							var px = 0;
							var seg = 100 / (vals.length);
							for (var j = 0; j < vals.length; j++) {
								var v = parseFloat(vals[j]);
								
								if (!isNaN(v)) {
									v = Math.round(tbBot - (tbHeight*((v - min) / (max - min))));

									var bar = this.document.createElementNS(SVGNS,'rect');
									bar.setAttribute('class','scoreCardTrendBars');
									bar.setAttribute('style',this.trendBarsStyle + colStyle);

									bar.setAttribute('x',Math.round(px*cellScaleX));
									bar.setAttribute('y',Math.round(v*cellScaleY));
									bar.setAttribute('width',Math.round(seg*cellScaleX) - (seg>2?2:0));
									var bh = tbHeight-v;
									// !!! negative bars
									bh = (bh<0) ? 0 : bh;
									bar.setAttribute('height',Math.round(bh*cellScaleY)+0.5);
									svg.appendChild(bar);
								}
								px += seg;
							}
						}
						break;

					case 'plotBox':
						// get cached values
						var innerX = cellInfoEx[r][c].innerX;
						var middleX = cellInfoEx[r][c].middleX;
						var outerX = cellInfoEx[r][c].outerX;
						var targetX = cellInfoEx[r][c].targetX;
						var valueX1 = cellInfoEx[r][c].valueX1;
						var valueX2 = cellInfoEx[r][c].valueX2;
						var eventHandler = cellInfoEx[r][c].eventHandler;
						var cellCaptionH = cellInfoEx[r][c].cellCaptionH;

						var cellScaleY = parseInt(rowHeight-cellCaptionH)/100;

						var boxPct = parseFloat(this.plotBoxHeight);
						var boxTop = 50 - (50 * boxPct);
						var boxHeight = (100 * boxPct);

						var outerBox = this.document.createElementNS(SVGNS,'rect');
						outerBox.setAttribute('class','scoreCardPlotBoxOuter');
						outerBox.setAttribute('style',this.plotBoxStyle);
						outerBox.setAttribute('x',Math.round(0*cellScaleX));
						outerBox.setAttribute('y',Math.round(boxTop*cellScaleY));
						outerBox.setAttribute('width',Math.round(outerX*cellScaleX));
						outerBox.setAttribute('height',Math.round(boxHeight*cellScaleY));
						svg.appendChild(outerBox);

						outerBox.addEventListener('click',eventHandler,false);

						if (middleX > 0) {
							var middleBox = this.document.createElementNS(SVGNS,'rect');
							middleBox.setAttribute('class','scoreCardPlotBoxMiddle');
							middleBox.setAttribute('style',this.plotBoxMidStyle);
							middleBox.setAttribute('x',Math.round(innerX*cellScaleX));
							middleBox.setAttribute('y',Math.round(boxTop*cellScaleY));
							middleBox.setAttribute('width',Math.round((middleX - innerX)*cellScaleX));
							middleBox.setAttribute('height',Math.round(boxHeight*cellScaleY));
							svg.appendChild(middleBox);
							middleBox.addEventListener('click',eventHandler,false);
						}

						if (innerX > 0) {
							var innerBox = this.document.createElementNS(SVGNS,'rect');
							innerBox.setAttribute('class','scoreCardPlotBoxInner');
							innerBox.setAttribute('style',this.plotBoxLowerStyle);
							innerBox.setAttribute('x',0);
							innerBox.setAttribute('y',Math.round(boxTop*cellScaleY));
							innerBox.setAttribute('width',Math.round(innerX*cellScaleX));
							innerBox.setAttribute('height',Math.round(boxHeight*cellScaleY));
							svg.appendChild(innerBox);
							innerBox.addEventListener('click',eventHandler,false);
						}

						if (valueX2 >= 0 && valueX1 <= 100) {
							var valueBox = this.document.createElementNS(SVGNS,'path');
							valueBox.setAttribute('class','scoreCardPlotBoxValue');
							if (valueX2 >= valueX1) {
								valueBox.setAttribute('style',this.plotBoxValueStyle + colStyle);
							}
							else {
								valueBox.setAttribute('style',this.plotBoxValueStyleNeg + colStyle);
							}

							var vboxPct = parseFloat(this.plotBoxValueHeight);
							var vboxTop = 50 - (50 * vboxPct);
							var vboxBottom = 50 + (50 * vboxPct);
							valueX1 = valueX1 < 0 ? 0 : valueX1;
							if (valueX2 > outerX) {
								// add jagged edge to the end
								var d = 'M '+Math.round(valueX1*cellScaleX)+' '+Math.round(vboxTop*cellScaleY)+' L '+Math.round((outerX+4)*cellScaleX)+' '+Math.round(vboxTop*cellScaleY)+' '+Math.round((outerX+2)*cellScaleX)+' '+Math.round(50*cellScaleY)+' '+Math.round((outerX+4)*cellScaleX)+' '+Math.round(50*cellScaleY)+' '+Math.round((outerX+2)*cellScaleX)+' '+Math.round(vboxBottom*cellScaleY)+' '+Math.round(valueX1*cellScaleX)+' '+Math.round(vboxBottom*cellScaleY)+' z';
							}
							else {
								var d = 'M '+Math.round(valueX1*cellScaleX)+' '+Math.round(vboxTop*cellScaleY)+' L '+Math.round(valueX2*cellScaleX)+' '+Math.round(vboxTop*cellScaleY)+' '+Math.round(valueX2*cellScaleX)+' '+Math.round(vboxBottom*cellScaleY)+' '+Math.round(valueX1*cellScaleX)+' '+Math.round(vboxBottom*cellScaleY)+' z';
							}
							valueBox.setAttribute('d',d);
							svg.appendChild(valueBox);
							valueBox.addEventListener('click',eventHandler,false);
						}
						if (targetX > 0) {
							var target = this.document.createElementNS(SVGNS,'line');
							target.setAttribute('class','scoreCardPlotBoxTarget');
							target.setAttribute('style',this.targetLineStyle);
							target.setAttribute('x1',Math.round(targetX*cellScaleX));
							target.setAttribute('x2',Math.round(targetX*cellScaleX));
							target.setAttribute('y1',Math.round((boxTop+5)*cellScaleY));
							target.setAttribute('y2',Math.round((boxTop+boxHeight-5)*cellScaleY));
							svg.appendChild(target);
						}

						break;

					} // end switch(display)
				}

				// move to next column
				if (colWidths[c] > 0) {
					x += colWidths[c] + padding;
				}
			}
		}
		this.cardHeight = y;

		// place plot scales in footer, if present
		// do this last, as we know the true sizes at this point.
		if (hasScale) {
			var x = padding/2;
			for (var c = 0; c < columnDefs.length; c++) {
				var column = columnDefs[c];
				if ('plotBox' == column.display && ('undefined'!=typeof plotMinValues[c]) && ('undefined'!=typeof plotMaxValues[c])) {
					var scale = this.document.createElementNS(SVGNS,'path');
					scale.setAttribute('class','scoreCardScale');
					var sx1 = x;
					var sx2 = x + (colWidths[c]*0.95);
					var sy1 = y - rowHeight + 2;
					var sy2 = y - rowHeight + 8;
					var baseValue = (plotBaseValues[c]!=null) ? plotBaseValues[c] : '';
					var sxb = '';
					if ('' !== baseValue) {
						sxb = x + ((baseValue-plotMinValues[c])/(plotMaxValues[c]-plotMinValues[c])*(colWidths[c]*0.95));
					}

					var path = "M " + sx1 + ' ' + sy1 + ' L ' + sx2 + ' ' + sy1;
					// ticks
					path += "M " + sx1 + ' ' + sy1 + ' L ' + sx1 + ' ' + sy2;
					path += "M " + sx2 + ' ' + sy1 + ' L ' + sx2 + ' ' + sy2;
					if (''!==sxb) {
						path += "M " + sxb + ' ' + sy1 + ' L ' + sxb + ' ' + sy2;
					}
					else {
						for (var t = 1; t < 4; t++) {
							var tx = (sx2-sx1) * (t/4) + sx1;
							path += "M " + tx + ' ' + sy1 + ' L ' + tx + ' ' + sy2;
						}
					}

					scale.setAttribute('d',path);
					this.svgGroup.appendChild(scale);

					// labels
					var format = ''===column.format ? "#,#" : column.format;
					var minv = zenFormatNumber(plotMinValues[c],format);
					var maxv = zenFormatNumber(plotMaxValues[c],format);

					if (''===baseValue) {
						var lt = [{x:sx1,text:minv},{x:sx2,text:maxv}];
					}
					else {
						var basev = zenFormatNumber(baseValue,format);
						var lt = [{x:sx1,text:minv},{x:sx2,text:maxv},{x:sxb,text:basev}];
					}
					for (var n = 0; n < lt.length; n++) {
						var slabel = this.document.createElementNS(SVGNS,'text');
						slabel.setAttribute('class','scoreCardScaleLabel');
						slabel.setAttribute('text-anchor','middle');

						var textNode = this.document.createTextNode(lt[n].text);
						slabel.appendChild(textNode);
						this.svgGroup.appendChild(slabel);
						var th = zenGetBBox(title).height;
						slabel.setAttribute('x',lt[n].x);
						slabel.setAttribute('y',y - rowHeight + 17);
					}
				}
				if (colWidths[c] > 0) {
					x += colWidths[c] + padding;
				}
			}
		}

		this.setProperty("height",this.cardHeight ? this.cardHeight : 0);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in scoreCard.renderScoreCard');
	}

	this._dataMinValue = null;
	this._dataMaxValue = null;
	this._dataCount = null;
	this._dataSum = null;
}

/// Given a column property, see if it is a property name and return it.
/// Otherwise return '';
ClientMethod getPropName(prop) [ Internal, Language = javascript ]
{
	if (!isNaN(parseFloat(prop))) {
		return '';
	}
	prop = prop.toString();
	
	// !!! strip off is wrong !!!
	
	if (prop.charAt(0)=='=') {
		// strip off =	
		prop = prop.substring(1,prop.length-1);
	}

	// see if this is a formula (crude test)
	if (prop.charAt(0)=='[') {
		var index = prop.indexOf(']');
		if (index>0) {
			prop = prop.substring(1,index);
		}
	}
	return prop;
}

/// Implentation of max() function within formulae.
/// Return max value of given property within current data set.
/// or max of values within a list of items.
ClientMethod getMaxValue(args) [ Internal, Language = javascript ]
{
	var max = null;
	for (var n = 0; n < args.length; n++) {
		var val = null;
		var prop = args[n];
		if (null != prop && '' !== prop) {
			var ident = prop.toString().substring(1,prop.length-1).toUpperCase();
			if (!isNaN(parseFloat(prop))) {
				val = parseFloat(prop);
			}
			else if (''!=ident && this._dataMaxValue && this._dataMaxValue[ident]) {
				val = this._dataMaxValue[ident];
			}
		}
		max = (null==max) ? val : (null==val) ? max : (max>val) ? max : val;
	}
	return (null!==max) ? max : '';
}

/// Implentation of min() function within formulae.
/// Return min value of given property within current data set.
ClientMethod getMinValue(args) [ Internal, Language = javascript ]
{
	var min = null;
	for (var n = 0; n < args.length; n++) {
		var prop = args[n];
		var val = null;
		if (null != prop && '' !== prop) {
			var ident = prop.toString().substring(1,prop.length-1).toUpperCase();
			if (!isNaN(parseFloat(prop))) {
				val = parseFloat(prop);
			}
			else if (''!=ident && this._dataMinValue && this._dataMinValue[ident]) {
				val = this._dataMinValue[ident];
			}
		}
		min = (null==min) ? val : (null==val) ?min : (min<val) ? min : val;
	}
	return (null!==min) ? min : '';
}

/// Implentation of count() function within formulae.
/// Return count of items within current data set.
ClientMethod getCountValue(args) [ Internal, Language = javascript ]
{
	var count = 0;
	for (var n = 0; n < args.length; n++) {
		var prop = args[n];
		var val = 0;
		if (null != prop && '' !== prop) {
			var ident = prop.toString().substring(1,prop.length-1).toUpperCase();
			if (!isNaN(parseFloat(prop))) {
				val++;
			}
			else if (''!=ident && this._dataCount && this._dataCount[ident]) {
				val = this._dataCount[ident];
			}
		}
		count += val;
	}
	return count;
}

/// Implentation of avg() function within formulae.
/// Return average of items within current data set.
ClientMethod getAvgValue(args) [ Internal, Language = javascript ]
{
	var avg = '';
	var count = this.getCountValue(args);
	if (count > 0) {
		var sum = this.getSumValue(args);
		avg = sum / count;
	}
	return avg;
}

/// Implentation of sum() function within formulae.
/// Return sum of items within current data set.
ClientMethod getSumValue(args) [ Internal, Language = javascript ]
{
	var sum = 0;
	for (var n = 0; n < args.length; n++) {
		var prop = args[n];
		var val = 0;
		if (null != prop && '' !== prop) {
			var ident = prop.toString().substring(1,prop.length-1).toUpperCase();
			if (!isNaN(parseFloat(prop))) {
				val = parseFloat(prop);
			}
			else if (''!=ident && this._dataSum && this._dataSum[ident]) {
				val = parseFloat(this._dataSum[ident]);
			}
		}
		if (null !== val) {
			sum += val;
		}
	}
	return sum;
}

/// Evaluate a value expression.
/// expr is the expression;
/// data is an array of data values subscripted by name and row;
/// r is the row.
ClientMethod evaluate(expr, data, r) [ Language = javascript ]
{
	var value = '';
	try {
		if ('undefined' != typeof dsFormulaParser && (expr.toString().charAt(0)=='=')) {
			var parser = new dsFormulaParser();

			// associate local functions with parser
			// n.b. keep this list in sync with the one in %DeepSee.UI.Dialog.DashboardEditDataProperty
			var funcSet = {
			max: new Function('args','return zenPage.getComponent('+this.index+').getMaxValue(args);'),
			min: new Function('args','return zenPage.getComponent('+this.index+').getMinValue(args);'),
			count: new Function('args','return zenPage.getComponent('+this.index+').getCountValue(args);'),
			sum: new Function('args','return zenPage.getComponent('+this.index+').getSumValue(args);'),
			avg: new Function('args','return zenPage.getComponent('+this.index+').getAvgValue(args);')
			}
			parser.setFunctionSet(funcSet);

			// remove '=' from start of expression
			parser.parse(expr.toString().substring(1));
			if (parser.errorHTML != '') {
				value = dsFormulaLastError ? dsFormulaLastError : 'error';
			}
			else {
				// make data visible
				self._widgetData = data;
				self._widgetRow = r;
				// use local lookup() method to resolve identifiers
				var lookup = new Function('key','return zenPage.getComponent('+this.index+').lookup(key);');
				value = parser.eval(lookup);

				// DO NOT USE "DELETE" OR YOU WILL WASTE HOURS OF YOUR LIFE
				// DEBUGGING INTERNET EXPLODER!
				self._widgetData = null;
				self._widgetRow = null;
			}
		}
		else {
			// default (non-formula) behavior
			if (''!==expr && 0==expr) {
				value = 0;
			}
			else if ('"'==expr.toString().charAt(0) && '"'==expr.toString().charAt(expr.length-1)) {
				// string literal
				value = expr.toString().substring(1,expr.length-1);
			}
			else if (''!==expr) {
				if (isNaN(expr)) {
					var exprU = expr.toString().toUpperCase();
					value = (null == data[exprU]) ? '' : ((null == data[exprU][r]) ? '' : data[exprU][r]);
				}
				else {
					value = expr;
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in scoreCard.evaluate');
		throw {message:'Error in evaluate method'};
		value = '';
	}
	return value;
}

/// Lookup function for formula engine.
ClientMethod lookup(key) [ Language = javascript ]
{
	key = key.toString().toUpperCase();
	// key is quoted;
	key = key.substr(1,key.length-2);

	return (null == self._widgetData[key]) ? "" : ((null == self._widgetData[key][self._widgetRow]) ? "" : self._widgetData[key][self._widgetRow]);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'headersVisible':
	case 'footersVisible':
	case 'titleVisible':
	case 'cardSize':
	case 'rowHeight':
	case 'cellCaptionStyle':
	case 'lampLabelStyle':
	case 'plotBoxStyle':
	case 'plotBoxValueStyle':
	case 'plotBoxValueStyleNeg':
	case 'plotBoxLowerStyle':
	case 'plotBoxMidStyle':
	case 'arrowStyle':
	case 'lampColor':
	case 'lampColorNeg':
	case 'trendLineStyle':
	case 'trendBarsStyle':
	case 'targetLineStyle':
	case 'columnHeaderStyle':
	case 'trendLineHeight':
	case 'trendBarsHeight':
	case 'plotBoxHeight':
	case 'plotBoxValueHeight':
	case 'lampSize':
	case 'arrowSize':
	case 'onclickrow':
	case 'titleImage':
	case 'titleImageStyle':
		this[property] = value;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Row click handler.
ClientMethod rowClickHandler(evt, row) [ Language = javascript ]
{
	evt.stopPropagation();
	this.selectRow(row);
	var value = (this._rowValues ? (this._rowValues[row]?this._rowValues[row]:'') : '');
	zenInvokeCallbackMethod(this.onclickrow,this,'onclickrow','row',row,'value',value);
}

/// Return the logical value associated with the given row (0-based).
ClientMethod getRowValue(row) [ Language = javascript ]
{
	var value = (this._rowValues ? (this._rowValues[row]?this._rowValues[row]:'') : '');
	return value;
}

/// Select the given row.
ClientMethod selectRow(row) [ Language = javascript ]
{
	if (this.selectedIndex >= 0) {
		var rect = this.findSVGElement('row_'+this.selectedIndex);
		if (rect) {
			// unselect
			rect.setAttribute('class',this.selectedIndex%2?'scoreCardRowEven':'scoreCardRowOdd');
			if (this.selectedIndex%2==0) {
				rect.setAttribute('style',this.stripeStyle);
			}
		}
	}

	this.selectedIndex = row;
	if (this.selectedIndex >= 0) {
		var rect = this.findSVGElement('row_'+this.selectedIndex);
		if (rect) {
			rect.setAttribute('class','scoreCardRowSelected');
			rect.setAttribute('style','');
		}
	}
}

}
