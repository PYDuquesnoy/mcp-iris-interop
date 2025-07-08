/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility class supplies the methods needed to control a chart using a navigator component.
Class %ZEN.Auxiliary.ChartContent [ Abstract, Deprecated, System = 3 ]
{

/// Implementation of the getContentForLevel method for charts.
ClientMethod chartGetContentForLevel(navigator, chart, level, key, value) [ Language = javascript ]
{
	var title = $$$Text('Chart Settings','%ZEN');
	var content = { title: title, items:[] };

	var settings = {};
	chart.getSettings(settings);

	// key for axis may take the form yAxis:no
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// get attribute name from key
	var t = key.toString().split('-');
	var attr = t[1];

	switch (key) {
	case 'chart-ChartSettings':
		// root
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_linechart_44.png',caption:$$$Text('Chart Type','%ZEN'), action:'drill', key:'chart-ChartType'};
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_wrench2_44.png',caption:$$$Text('Size &amp; Appearance','%ZEN'), action:'drill', key:'chart-ChartSize'};
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_text_44.png',caption:$$$Text('Titles &amp; Labels','%ZEN'), action:'drill', key:'chart-ChartLabels'};
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_text_44.png',caption:$$$Text('No Data Warning','%ZEN'), action:'drill', key:'chart-ChartNoData'}; // JSL4478
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_palette_44.png', caption:$$$Text('Colors &amp; Style','%ZEN'), action:'drill', key:'chart-ChartColors'};
		// content.items[content.items.length] = {display:'caption', caption:$$$Text('Legends','%ZEN'), action:'drill', key:'chart-ChartLegends'};
		if (chart.hasAxes()) {
			content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_ruler_44.png', caption:$$$Text('x Axis','%ZEN'), action:'drill', key:'chart-xAxis'};
			content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_ruler_44.png', caption:$$$Text('y Axis','%ZEN'), action:'drill', key:'chart-yAxisList'};
		}
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_bar_chart_44.png', caption:$$$Text('Series Details','%ZEN'), action:'drill', key:'chart-seriesList'};
		break;

	case 'chart-ChartSize':
		title = $$$Text('Size and Appearance','%ZEN');
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%ZEN'), edit:'integer', value:zenGet(chart.width),  key:'chart-width'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%ZEN'), edit:'integer', value:zenGet(chart.height),  key:'chart-height'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Margins','%ZEN'), action:'drill', key:'chart-ChartMargins'};

		if ((chart._type!='bubbleChart')) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Multiples','%ZEN'), edit:'switch', value:zenGet(chart.showMultiples),	key:'chart-showMultiples'};
		}

		if (!chart.timeBased && typeof settings['chartPivot'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Pivot','%ZEN'), edit:'switch', value:zenGet(chart.chartPivot),	key:'chart-chartPivot'};
		}
		if (typeof settings['chartStacked'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stacked','%ZEN'), edit:'switch', value:zenGet(chart.chartStacked),	key:'chart-chartStacked'};
		}
		if (typeof settings['chartFilled'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Filled','%ZEN'), edit:'switch', value:zenGet(chart.chartFilled),	key:'chart-chartFilled'};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Appearance','%ZEN'), edit:'choice', value:zenGet(chart.appearance),  key:'chart-appearance',valueList:'2D,3D', displayList:'2D,3D'};
		if (typeof settings['pieHeight'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Pie Height','%ZEN'), edit:'slider', value:zenGet(chart.pieHeight),	key:'chart-pieHeight', maxValue:1.0};
		}
		if (typeof settings['pieScale'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Pie Size','%ZEN'), edit:'slider', value:zenGet(chart.pieScale),	key:'chart-pieScale', maxValue:2.0};
		}
		if (typeof settings['holeSize'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Pie Hole Size','%ZEN'), edit:'slider', value:zenGet(chart.holeSize),	key:'chart-holeSize', maxValue:1.0};
		}
		else {
			// show for non-pie
			if (!chart.timeBased && (chart._type!='treeMapChart')) {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Zoom','%ZEN'), edit:'switch', value:zenGet(chart.hasZoom),	key:'chart-hasZoom'};
			}
		}
		// JSL4277
		if (typeof settings['separateSeriesScale'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Separate Series Scale','%ZEN'), edit:'switch', value:zenGet(chart.separateSeriesScale),	key:'chart-separateSeriesScale'};
		}		
		if (typeof settings['invert'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Invert','%ZEN'), edit:'switch', value:zenGet(chart.invert),	key:'chart-invert'};
		}
		if (typeof settings['gap'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Gap','%ZEN'), edit:'slider', value:zenGet(chart.gap),	key:'chart-gap', minValue:0, maxValue:135, stepSize:1};
		}
		if (typeof settings['plotBy'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plot By','%ZEN'), edit:'choice', value:zenGet(chart.plotBy),	key:'chart-plotBy', valueList:'items,series', displayList:'items,series' };
		}

		if (typeof settings['showQuadrant'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Quadrant','%ZEN'), edit:'switch', value:zenGet(chart.showQuadrant),	key:'chart-showQuadrant'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Radius','%ZEN'), edit:'slider', value:zenGet(chart.radius),	key:'chart-radius', minValue:1, maxValue:20, stepSize:1};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%ZEN'), edit:'slider', value:zenGet(chart.opacity),	key:'chart-opacity', minValue:0, maxValue:1, stepSize:0.1};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Regression','%ZEN'), edit:'switch', value:zenGet(chart.showRegression),	key:'chart-showRegression'};
		}
		break;

	case 'chart-ChartMargins':
		title = $$$Text('Chart Margins','%ZEN');

		// separate margin info into value + units
		var info = this.chartParseLength(chart.marginTop);
		this.marginTopUnits = info.units;
		this.marginTop = info.value;
		var info = this.chartParseLength(chart.marginBottom);
		this.marginBottomUnits = info.units;
		this.marginBottomTop = info.value;
		var info = this.chartParseLength(chart.marginLeft);
		this.marginLeftUnits = info.units;
		this.marginLeft = info.value;
		var info = this.chartParseLength(chart.marginRight);
		this.marginRightUnits = info.units;
		this.marginRightTop = info.value;

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Top','%ZEN'), edit:'slider', value:this.marginTop,	key:'chart-marginTop', minValue:0, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Top Units','%ZEN'), edit:'choice', value:this.marginTopUnits,	key:'chart-marginTopUnits', valueList:'auto,%,px', displayList:$$$Text('Auto,%,px','%ZEN')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Left','%ZEN'), edit:'slider', value:this.marginLeft,	key:'chart-marginLeft', minValue:0, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Left Units','%ZEN'), edit:'choice', value:this.marginLeftUnits,	key:'chart-marginLeftUnits', valueList:'auto,%,px', displayList:$$$Text('Auto,%,px','%ZEN')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Right','%ZEN'), edit:'slider', value:this.marginRight,	key:'chart-marginRight', minValue:0, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Right Units','%ZEN'), edit:'choice', value:this.marginRightUnits,	key:'chart-marginRightUnits', valueList:'auto,%,px', displayList:$$$Text('Auto,%,px','%ZEN')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Bottom','%ZEN'), edit:'slider', value:this.marginBottom,	key:'chart-marginBottom', minValue:0, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Bottom Units','%ZEN'), edit:'choice', value:this.marginBottomUnits,	key:'chart-marginBottomUnits', valueList:'auto,%,px', displayList:$$$Text('Auto,%,px','%ZEN')};
		break;

	case 'chart-ChartLabels':
		title = $$$Text('Chart Labels','%ZEN');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Size','%ZEN'), edit:'choice', value:zenGet(chart.textSize),  key:'chart-textSize',valueList:'small,medium,large', displayList:$$$Text('Small,Medium,Large','%ZEN')};
		content.items[content.items.length] = {display:'section', caption:$$$Text('Titles','%ZEN')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%ZEN'), edit:'string', value:zenGet(this.origChartTitle,zenGet(chart.title)),  key:'chart-title'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Style','%ZEN'), action:'drill', value:zenGet(chart.titleStyle),	key:'chart-titleStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle','%ZEN'), edit:'string', value:zenGet(this.origChartSubtitle,zenGet(chart.subtitle)),  key:'chart-subtitle'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle Style','%ZEN'), action:'drill', value:zenGet(chart.subtitleStyle),	key:'chart-subtitleStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Align','%ZEN'), edit:'choice', value:zenGet(chart.titleAlign),	key:'chart-titleAlign', valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Box','%ZEN'), action:'drill', value:zenGet(chart.titleBoxStyle),	key:'chart-titleBoxStyle', text:''};

		if (zenPage.fetchOptionList) {
			content.items[content.items.length] = {display:'caption', caption:$$$Text('Title Image','%ZEN'), action:'drill', value:zenGet(chart.titleImage),	key:'chart-titleImage'};
		
			var imageLeft = 0;
			var imageTop = 0;
			var imageWidth = 50;
			var imageHeight = 50;
			var imageStyle = chart.titleImageStyle;
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

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Width','%ZEN'), edit:'slider-toggle', value:imageWidth, key:'chart-titleImageStyle-width', minValue:0, maxValue:150};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Height','%ZEN'), edit:'slider-toggle', value:imageHeight, key:'chart-titleImageStyle-height', minValue:0, maxValue:150};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Top','%ZEN'), edit:'slider-toggle', value:imageTop, key:'chart-titleImageStyle-top', minValue:0, maxValue:150};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Left','%ZEN'), edit:'slider-toggle', value:imageHeight, key:'chart-titleImageStyle-left', minValue:0, maxValue:150};
		}

		content.items[content.items.length] = {display:'section', caption:$$$Text('Labels','%ZEN')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Labels','%ZEN'), edit:'switch', value:zenGet(chart.labelsVisible),	key:'chart-labelsVisible'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Style','%ZEN'), action:'drill', value:zenGet(chart.labelStyle),	key:'chart-labelStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Length','%ZEN'), edit:'stepper-value', value:zenGet(chart.maxLabelLen),	key:'chart-maxLabelLen', minValue:1, maxValue:50};

		if (typeof settings['holeSize'] == 'undefined') {
			// skip for pie
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Axis Title','%ZEN'), action:'drill', value:zenGet(chart.axisTitleStyle),	key:'chart-axisTitleStyle', text:''};
			if (typeof settings['labelValue'] != 'undefined') {
				// bullseye
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Label','%ZEN'), edit:'choice', value:zenGet(chart.labelValue),	key:'chart-labelValue', displayList:$$$Text(',#,%Sum,%Max','%ZEN'),valueList:'none,value,pctOfTotal,pctOfMax' };
			}
			else {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Labels','%ZEN'), edit:'switch', value:zenGet(chart.valueLabelsVisible),	key:'chart-valueLabelsVisible'};
			}
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Style','%ZEN'), action:'drill', value:zenGet(chart.valueLabelStyle),	key:'chart-valueLabelStyle', text:''};
		}
		if (typeof settings['showValue'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Value','%ZEN'), edit:'switch', value:zenGet(chart.showValue),	key:'chart-showValue' };
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Format','%ZEN'), edit:'string', action:'drill', value:zenGet(chart.valueLabelFormat),	key:'chart-valueLabelFormat'};

		if (typeof settings['showPercentage'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show %','%ZEN'), edit:'switch', value:zenGet(chart.showPercentage),	key:'chart-showPercentage' };
		}
		if (typeof settings['labelRadius'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Position','%ZEN'), edit:'slider-toggle', value:zenGet(chart.labelRadius),	key:'chart-labelRadius', maxValue:1.5, minValue:0.5};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Box Style','%ZEN'), action:'drill', value:zenGet(chart.valueBoxStyle),	key:'chart-valueBoxStyle', text:''};
		break;

	case 'chart-titleImage':
		// get icon list
		title = $$$Text('Title Image','%ZEN');		// DTB236
		if (zenPage.fetchOptionList) {
			var options = zenPage.fetchOptionList('image-list','');
			var list = options.children;
			content.html = zenPage.getNavigator().getIconListHTML(list,key,'');
		}
		break;

	case 'chart-valueLabelFormat':
		title = $$$Text('Numeric Format','%ZEN');
		var list = [
			{ caption:$$$Text('###','%ZEN'), value:'###'},
			{ caption:$$$Text('###.#','%ZEN'), value:'###.#'},
			{ caption:$$$Text('###.##','%ZEN'), value:'###.##'},
			{ caption:$$$Text('###.###','%ZEN'), value:'###.###'},
			{ caption:$$$Text('#,##','%ZEN'), value:'#,##'},
			{ caption:$$$Text('#,##.#','%ZEN'), value:'#,##.#'},
			{ caption:$$$Text('#,##.##','%ZEN'), value:'#,##.##'},
			{ caption:$$$Text('#,##.###','%ZEN'), value:'#,##.###'},
			{ caption:$$$Text('##.##%','%ZEN'), value:'##.##%'},
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(chart.valueLabelFormat),$$$Text('Format','%ZEN'),$$$Text('Choose a numeric format','%ZEN'));
		break;

	case 'chart-ChartLegends':
		title = $$$Text('Chart Legends','%ZEN');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Legend','%ZEN'), edit:'choice', value:zenGet(chart.legendVisible),	key:'chart-legendVisible', valueList:'auto,true,false', displayList:$$$Text('Auto,On,Off','%ZEN')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Legend Title','%ZEN'), edit:'string', value:zenGet(chart.legendTitle),  key:'chart-legendTitle'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Legend Style','%ZEN'), action:'drill', value:zenGet(chart.legendStyle),	key:'chart-legendStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Legend Label','%ZEN'), action:'drill', value:zenGet(chart.legendLabelStyle),	key:'chart-legendLabelStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Legend Rect','%ZEN'), action:'drill', value:zenGet(chart.legendRectStyle),	key:'chart-legendRectStyle', text:''};
		break;

	case 'chart-ChartColors':
		title = $$$Text('Chart Colors','%ZEN');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Series Scheme','%ZEN'), action:'drill', value:zenGet(chart.seriesColorScheme),	key:'chart-seriesColorScheme'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%ZEN'), action:'drill', value:zenGet(chart.backgroundStyle),	key:'chart-backgroundStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plot Area','%ZEN'), action:'drill', value:zenGet(chart.plotAreaStyle),	key:'chart-plotAreaStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plot Style','%ZEN'), action:'drill', value:zenGet(chart.plotStyle),	key:'chart-plotStyle', text:''};
		
		// MES search non-pie charts
		if (typeof settings['holeSize'] == 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Grid Style','%ZEN'), action:'drill', value:zenGet(chart.gridStyle),	key:'chart-gridStyle', text:''};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Axis Line Style','%ZEN'), action:'drill', value:zenGet(chart.axisLineStyle),	key:'chart-axisLineStyle', text:''};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Base Line Style','%ZEN'), action:'drill', value:zenGet(chart.baseLineStyle),	key:'chart-baseLineStyle', text:''};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Style','%ZEN'), action:'drill', value:zenGet(chart.lineStyle),	key:'chart-lineStyle', text:''};

			// MES003 display all marker controls for these chart types only (add to list as necessary)
			if (chart._type == 'lineChart' || chart._type == 'comboChart' || chart._type == 'xyChart') {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Markers Visible','%ZEN'), value:zenGet(chart.markersVisible),	key:'chart-markersVisible', edit:'switch'};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Marker Size','%ZEN'), edit:'slider', value:zenGet(chart.markerScale),	key:'chart-markerScale', maxValue:3.0};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Marker Style','%ZEN'), action:'drill', value:zenGet(chart.markerStyle),	key:'chart-markerStyle', text:''};
			}
			// only for line charts
			if (chart._type == 'lineChart') {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Indicators','%ZEN'), edit:'switch', value:zenGet(chart.indicatorsVisible),	key:'chart-indicatorsVisible'};
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Indicator Style','%ZEN'), action:'drill', value:zenGet(chart.indicatorStyle),	key:'chart-indicatorStyle', text:''};
			}

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Band Upper','%ZEN'), edit:'number', value:zenGet(chart.bandUpper),	key:'chart-bandUpper'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Upper Style','%ZEN'), action:'drill', value:zenGet(chart.bandUpperStyle),	key:'chart-bandUpperStyle', text:''};

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Band Lower','%ZEN'), edit:'number', value:zenGet(chart.bandLower),	key:'chart-bandLower'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower Style','%ZEN'), action:'drill', value:zenGet(chart.bandLowerStyle),	key:'chart-bandLowerStyle', text:''};

			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripes','%ZEN'), edit:'switch', value:zenGet(chart.stripesVisible),	key:'chart-stripesVisible'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripe Style','%ZEN'), action:'drill', value:zenGet(chart.stripeStyle),	key:'chart-stripeStyle', text:''};
		}

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Style','%ZEN'), action:'drill', value:zenGet(chart.borderStyle),	key:'chart-borderStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Offset','%ZEN'), edit:'slider', value:zenGet(chart.borderOffset),	key:'chart-borderOffset', minValue:0, maxValue:25, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Radius','%ZEN'), edit:'slider', value:zenGet(chart.borderRadius),	key:'chart-borderRadius', minValue:0, maxValue:25, stepSize:1};

		if (typeof settings['upperRightStyle'] != 'undefined') {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Upper Right','%ZEN'), action:'drill', value:zenGet(chart.upperRightStyle),	key:'chart-upperRightStyle', text:''};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower Left','%ZEN'), action:'drill', value:zenGet(chart.lowerLeftStyle),	key:'chart-lowerLeftStyle', text:''};
		}

		if (chart.appearance == '3D') {
			if (typeof settings['holeSize'] == 'undefined') {
				content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('3D Edge Style','%ZEN'), action:'drill', value:zenGet(chart.plotEdgeStyle),	key:'chart-plotEdgeStyle', text:''};
			}
		}
		break;

	case 'chart-seriesList':
		// display list of data series values
		// key is seriesDetail:n
		title = $$$Text('Data Series','%ZEN');

		// get series colors
		var colors = chart.getColorSchemeArray(chart.seriesColorScheme);
		var seriesColors = this.chartParseColorList(zenGet(chart.seriesColorsOverride));
		if ('undefined' == typeof this.seriesCount) {
			var scount = 8;
		}
		else {
			var scount = parseInt(this.seriesCount);
		}

		var types = zenGet(chart.seriesTypes).toString().split(',');

		// always show at least 8
		scount = scount < 8 ? 8 : scount;
		for (var n = 0; n < scount; n++) {
			var fill = colors&&colors.length ? colors[n%colors.length] : 'none';
			if (seriesColors && seriesColors[n]) {
				fill = seriesColors[n];
			}
			var fillColor = navigator.transformColor(fill);
			var scaption = $$$Text('Series','%ZEN') + ' ' + (n+1);
			if (chart._type == 'comboChart') {
				scaption = (types[n] ? types[n] : (chart.isTimeBased()?'line':'bar')) + ' ' + (n+1);
			}
			content.items[content.items.length] = {display:'caption-value-hz', caption:scaption, action:'drill', key:'chart-seriesDetail:'+n, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';',value:fill, text:'', canDrag:true};
		}
		break;

	case 'chart-seriesDetail':
		title = $$$Text('Data Series','%ZEN') + ' ' + (keyNo+1);
		this._seriesNo = keyNo;
		// name
		var list = zenGet(chart.seriesNames).toString().split(',');
		var sname = list[this._seriesNo] ? list[this._seriesNo] : '';

		// color
		var seriesColors = this.chartParseColorList(zenGet(chart.seriesColorsOverride));
		var fill = seriesColors[keyNo] ? seriesColors[keyNo] : 'none';
		var fillColor = navigator.transformColor(fill);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%ZEN'), action:'drill', value:'', key:key+'-fill', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';',value:fill,text:''};

		// yaxis
		var list = chart.yAxisList;
		if (list && list.length>1) {
			var axes = zenGet(chart.seriesYAxes).toString().split(',');
			var yNo = (axes[this._seriesNo]&&axes[this._seriesNo]!=='') ? axes[this._seriesNo] : 0;
			var vlist = [];
			var dlist = [];
			for (var n = 0; n < list.length; n++) {
				vlist[n] = n;
				dlist[n] = n+1;
			}
			vlist = vlist.join(',');
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('y Axis','%ZEN'), edit:'choice', value:yNo,	key:key+'-yAxisNo', valueList:vlist,displayList:dlist};
		}

		// plot type
		if (chart._type == 'comboChart') {
			var types = zenGet(chart.seriesTypes).toString().split(',');
			var plotType = types[this._seriesNo] ? types[this._seriesNo] : 'bar';
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plot Type','%ZEN'), edit:'choice', value:plotType,	key:key+'-plotType', valueList:'bar,line,area,target', displayList:$$$Text('Bar,Line,Area,Tgt','%ZEN')};
		}

		// marker shape
		if (chart._type == 'lineChart' || chart._type == 'comboChart') {
			var markers = zenGet(chart.markerShapes).toString().split(',');
			if (markers.length>0) {
				var markerShape = markers[this._seriesNo%markers.length] ? markers[this._seriesNo%markers.length] : 'circle';
			}
			else {
				var markerShape = 'circle';
			}
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Marker Shape','%ZEN'), edit:'choice', value:markerShape,	key:key+'-markerShape', valueList:'circle,up,down,square', displayList:'&#x25CF;,&#x25B2;,&#x25BC;,&#x25A0;'};
		}

		break;

	case 'chart-yAxisList':
		// display list of y axes

		// make sure chart has at least one yAxis
		var list = chart.yAxisList;
		if (!list) {
			chart.yAxisList = [];
		}
		if (!list.length) {
			var axis = zenPage.createComponent('axis');
			chart.yAxisList[0] = axis;
			list = chart.yAxisList;
		}

		// "add axis" button
		if (list.length < 8) {
			content.headerButtons = [ 
				{key:'chart-addYAxis', caption:$$$Text('Add Y Axis','%ZEN'), image:'deepsee/ds2_plus_44_w.png'}
			];
		}

		// key is yAxis:n
		for (var n = 0; n < list.length; n++) {
			content.items[content.items.length] = {display:'caption', caption:$$$Text('yAxis ','%ZEN') + ((list.length>1)?(n+1):''), action:'drill', key:'chart-yAxis:'+n, closeButton:true, canDrag:true};
		}
		break;

	case 'chart-yAxis':
	case 'chart-xAxis':
		// tack on yAxis # to key
		var k2 = '';

		switch(attr) {
		case 'xAxis':
			title = $$$Text('x Axis','%ZEN');
			var axis = chart.xAxis;
			// make sure chart has an xAxis
			if (null == axis) {
				var axis = zenPage.createComponent('axis');
				chart.xAxis = axis;
				axis.parent = chart;
			}
			var vlist = 'top,bottom';
			var dlist = 'Top,Bottom';
			var labelPos = zenGet(axis.labelPosition);
			labelPos = labelPos ? labelPos : 'bottom';
			var axisTitle = zenGet(this.origChartXAxisTitle,zenGet(axis.title));
			break;
		default:
			title = $$$Text('y Axis','%ZEN');
			k2 = ':'+keyNo;
			var axis = chart.yAxisList[keyNo];
			if (!axis.parent) {
				axis.parent = chart;
			}
			// "remove axis" button
			/*
			if (chart.yAxisList.length>1) {
				content.headerButtons = [ 
					{key:'chart-removeYAxis', caption:$$$Text('Remove','%ZEN'), image:'deepsee/ds2_x_44_w.png'}
				];
			}
			*/
			var vlist = 'left,right';
			var dlist = 'Left,Right';
			var labelPos = zenGet(axis.labelPosition);
			labelPos = labelPos ? labelPos : 'left';

			if (this.origChartYAxisTitles && this.origChartYAxisTitles[keyNo]) {
				var axisTitle = this.origChartYAxisTitles[keyNo];
			}
			else {
				var axisTitle = zenGet(axis.title);
			}
			break;
		}

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Axis Title','%ZEN'), edit:'string', value:axisTitle,  key:key+'-title'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Major Grid','%ZEN'), edit:'switch', value:zenGet(axis.majorGridLines),key:key+'-majorGridLines'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Major Style','%ZEN'), action:'drill', value:zenGet(chart.majorGridStyle),	key:key+'-majorGridStyle'+k2, text:'' };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Minor Grid','%ZEN'), edit:'switch', value:zenGet(axis.minorGridLines),key:key+'-minorGridLines'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Minor Style','%ZEN'), action:'drill', value:zenGet(chart.minorGridStyle),	key:key+'-minorGridStyle'+k2, text:'' };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Position','%ZEN'), edit:'choice', value:labelPos,key:key+'-labelPosition'+k2, valueList:vlist, displayList:dlist};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Style','%ZEN'), action:'drill', value:zenGet(axis.labelStyle),	key:key+'-labelStyle'+k2, text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Angle','%ZEN'), edit:'slider-toggle', value:zenGet(axis.labelAngle),  key:key+'-labelAngle'+k2, minValue:0, maxValue:90};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Axis Type','%ZEN'), edit:'choice', value:zenGet(axis.axisType),key:key+'-axisType'+k2, valueList:',percent', displayList:$$$Text('Auto,%','%ZEN')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Min Value','%ZEN'), edit:'string', value:zenGet(axis.minValue),  key:key+'-minValue'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Max Value','%ZEN'), edit:'string', value:zenGet(axis.maxValue),  key:key+'-maxValue'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Base Value','%ZEN'), edit:'string', value:zenGet(axis.baseValue),  key:key+'-baseValue'+k2};

		break;

	case 'chart-ChartNoData': // JSL4478
		title = $$$Text('Chart No Data Warning','%ZEN');
		var noDataMsg = chart.msgIfNoData;
		var warnIfNoData = chart.warnIfNoData;
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('No Data Message','%ZEN'), edit:'string', value:noDataMsg,  key:'chart-msgIfNoData'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Warn if no data?','%ZEN'), edit:'switch', value:warnIfNoData, key:'chart-warnIfNoData'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background opacity','%ZEN'), edit:'slider', value:zenGet(chart.noDataOpacity),	key:'chart-noDataOpacity', maxValue:1.0};
		var background = chart.noDataFill;
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background color','%ZEN'), action:'drill', key:'chart-noDataFill', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		var foreground = chart.noDataStroke;
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Message color','%ZEN'), action:'drill', key:'chart-noDataStroke', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+foreground+';'};
		break;
	case 'chart-noDataFill':
	case 'chart-noDataStroke':
		// choose a color
		var html = navigator.getColorChooserHTML(key+k2,value,'svg');
		content.html = html;
		break;

	case 'chart-ChartType':
		title = $$$Text('Chart Type','%ZEN');

		// 158x158 -> 64X64
		var list = [
			{ image:'deepsee/ds_chart_line.png', value:'lineChart', caption:$$$Text('Line Chart','%ZEN')},
			{ image:'deepsee/ds_chart_marker.png', value:'lineChartMarkers', caption:$$$Text('Line Chart Marker','%ZEN')},
			{ image:'deepsee/ds_chart_bar.png', value:'barChart', caption:$$$Text('Bar Chart','%ZEN')},
			{ image:'deepsee/ds_chart_bar_stack.png', value:'barChartStacked', caption:$$$Text('Stacked Bar Chart','%ZEN')},
			{ image:'deepsee/ds_chart_column.png', value:'columnChart', caption:$$$Text('Column Chart','%ZEN')},
			{ image:'deepsee/ds_chart_bar3D.png', value:'columnChart3D', caption:$$$Text('Column Chart 3D','%ZEN')},
			{ image:'deepsee/ds_chart_column_stack.png', value:'columnChartStacked', caption:$$$Text('Stacked Column Chart','%ZEN')},
			{ image:'deepsee/ds_chart_area.png', value:'areaChart', caption:$$$Text('Area Chart','%ZEN')},
			{ image:'deepsee/ds_chart_combo.png', value:'comboChart', caption:$$$Text('Combo Chart','%ZEN')},
			{ image:'deepsee/ds_chart_pie.png', value:'pieChart', caption:$$$Text('Pie Chart','%ZEN')},
			{ image:'deepsee/ds_chart_pie3d.png', value:'pieChart3D', caption:$$$Text('Pie Chart 3D','%ZEN')},
			{ image:'deepsee/ds_chart_donut.png', value:'donutChart', caption:$$$Text('Donut Chart','%ZEN')},
			{ image:'deepsee/ds_chart_donut3d.png', value:'donutChart3D', caption:$$$Text('Donut Chart 3D','%ZEN')},
			{ image:'deepsee/ds_chart_bubble.png', value:'bubbleChart', caption:$$$Text('Bubble Chart','%ZEN')},
			{ image:'deepsee/ds_chart_treemap.png', value:'treeMapChart', caption:$$$Text('TreeMap Chart','%ZEN')},
			{ image:'deepsee/ds_chart_xy.png', value:'xyChart', caption:$$$Text('X-Y Chart','%ZEN')},
			{ image:'deepsee/ds_chart_hilow.png', value:'hiLowChart', caption:$$$Text('HiLow Chart','%ZEN')},
			{ image:'deepsee/ds_chart_time.png', value:'timeChart', caption:$$$Text('Time Chart','%ZEN')},
			{ image:'deepsee/ds_chart_bullseye.png', value:'bullseyeChart', caption:$$$Text('Bullseye Chart','%ZEN')},
			{ image:'deepsee/ds_chart_swirl.png', value:'swirlChart', caption:$$$Text('Swirl Chart','%ZEN')},
		];
		content.html = navigator.getIconListHTML(list,key,zenGet(this.chartType));
		break;

	case 'chart-seriesColorScheme':
		title = $$$Text('Color Scheme','%ZEN');
		var list = [
			{ caption:$$$Text('Bright','%ZEN'), value:'bright'},
			{ caption:$$$Text('Caribbean','%ZEN'), value:'caribbean'},
			{ caption:$$$Text('Gray','%ZEN'), value:'gray'},
			{ caption:$$$Text('Pastel','%ZEN'), value:'pastel'},
			{ caption:$$$Text('Rust belt','%ZEN'), value:'rustbelt'},
			{ caption:$$$Text('Tuscan','%ZEN'), value:'tuscan'},
			{ caption:$$$Text('Urban','%ZEN'), value:'urban'}
		];
		content.html = navigator.getChooserListHTML(list,key,zenGet(chart.seriesColorScheme));
		break;
		// text styles
	case 'chart-titleStyle':
	case 'chart-subtitleStyle':
	case 'chart-labelStyle':
	case 'chart-axisTitleStyle':
	case 'chart-valueLabelStyle':
	case 'chart-legendLabelStyle':
	case 'chart-xAxis-labelStyle':
	case 'chart-yAxis-labelStyle':
		switch (key) { // JSL4541 - use $$$Text to localize title
			case 'chart-titleStyle':
				title = $$$Text('Title Style','%ZEN');
				break;
			case 'chart-subtitleStyle':
				title = $$$Text('Subtitle Style','%ZEN');
				break;
			case 'chart-labelStyle':
				title = $$$Text('Label Style','%ZEN');
				break;
			case 'chart-axisTitleStyle':
				title = $$$Text('Axis Title Style','%ZEN');
				break;
			case 'chart-valueLabelStyle':
				title = $$$Text('Value Label Style','%ZEN');
				break;
			case 'chart-legendLabelStyle':
				title = $$$Text('Legend Label Style','%ZEN');
				break;
			case 'chart-xAxis-labelStyle':
				title = $$$Text('xAxis Label Style','%ZEN');
				break;
			case 'chart-yAxis-labelStyle':
				title = $$$Text('yAxis Label Style','%ZEN');
				break;
			default:
				title = key.split('-')[1]; // JSL4541 - not localized and we punt

		}
		var style = '';
		var which = key.split('-')[1];
		switch(which) {
		case 'xAxis':
			//title = 'xAxis ' + key.split('-')[2];
			style = chart.xAxis.labelStyle;
			break;
		case 'yAxis':
			//title = 'yAxis ' + key.split('-')[2];
			style = chart.yAxisList[keyNo].labelStyle;
			break;
		default:
			//title = key.split('-')[1];
			style = zenGet(chart[attr]);
			break;
		}

		// pull apart style
		var info = navigator.parseStyleSVG(style);

		var fill = info['fill'] ? info['fill'] : 'transparent';
		var fillColor = navigator.transformColor(fill);
		var stroke = info['stroke'] ? info['stroke'] : 'none';
		var strokeWidth = zenGet(info['stroke-width']);

		var fontFamily = zenGet(info['font-family']);
		var fontSize = zenGet(info['font-size']);
		var opacity = zenGet(info['opacity']);
		opacity = opacity==='' ? 1.0 : opacity;

		// webkit only for now!
		var shadow = zenGet(info['text-shadow']);
		shadow = shadow ? true : false;

		var bold = zenGet(info['font-weight']);
		bold = bold ? true : false;

		var italic = zenGet(info['font-style']);
		italic = italic ? true : false;

		var smallCaps = zenGet(info['font-variant']);
		smallCaps = smallCaps ? true : false;

		var fs = [];
		if (bold) { fs[fs.length] = 'bold'; }
		if (italic) { fs[fs.length] = 'italic'; }
		if (smallCaps) { fs[fs.length] = 'smallCaps'; }
		if (shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');

		var k2 = '';
		if (key=='chart-yAxis-labelStyle') {
			k2 = ':' + keyNo;
		}

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%ZEN'), action:'drill', value:fill,	key:key+'-fill'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';', value:fill,text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke','%ZEN'), action:'drill', value:stroke,	key:key+'-stroke'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke Width','%ZEN'), edit:'slider-toggle', value:strokeWidth,	key:key+'-stroke-width'+k2, minValue:0, maxValue:5, stepSize:0.05};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%ZEN'), edit:'slider', value:opacity,	key:key+'-opacity'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%ZEN'), action:'drill', value:fontFamily,	key:key+'-font-family'+k2, valueStyle:'font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Size','%ZEN'), edit:'slider-toggle', value:fontSize,	key:key+'-font-size'+k2, minValue:2, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%ZEN'), edit:'choice-multi', value:fontStyle,	key:key+'-textStyle'+k2, valueList:'bold,italic,smallCaps,shadow', displayList:'B,I,Cc,S', valueStyle:'font-size:12px;font-family:times new roman;', choiceStyles:'font-weight:900;^font-style:italic;^font-variant:small-caps;^text-shadow:1px 1px 2px #F0F0F0;'};
		break;

	case 'chart-backgroundStyle':
	case 'chart-plotAreaStyle':
	case 'chart-stripeStyle':
	case 'chart-bandUpperStyle':
	case 'chart-bandLowerStyle':
	case 'chart-borderStyle':
	case 'chart-plotStyle':
	case 'chart-lineStyle':
	case 'chart-markerStyle':
	case 'chart-indicatorStyle':
	case 'chart-axisLineStyle':
	case 'chart-baseLineStyle':
	case 'chart-plotEdgeStyle':
	case 'chart-legendStyle':
	case 'chart-gridStyle':
	case 'chart-titleBoxStyle':
	case 'chart-legendStyle':
	case 'chart-legendRectStyle':
	case 'chart-upperRightStyle':
	case 'chart-lowerLeftStyle':
	case 'chart-xAxis-majorGridStyle':
	case 'chart-xAxis-minorGridStyle':
	case 'chart-yAxis-majorGridStyle':
	case 'chart-yAxis-minorGridStyle':
	case 'chart-valueBoxStyle':
		switch (key) { // JSL4541 - localize title
			case 'chart-backgroundStyle':
				title = $$$Text('Background Style','%ZEN');
				break;
			case 'chart-plotAreaStyle':
				title = $$$Text('PlotArea Style','%ZEN');
				break;
			case 'chart-stripeStyle':
				title = $$$Text('Stripe Style','%ZEN');
				break;
			case 'chart-bandUpperStyle':
				title = $$$Text('Upper Band Style','%ZEN');
				break;
			case 'chart-bandLowerStyle':
				title = $$$Text('Lower Band Style','%ZEN');
				break;
			case 'chart-borderStyle':
				title = $$$Text('Border Style','%ZEN');
				break;
			case 'chart-plotStyle':
				title = $$$Text('Plot Style','%ZEN');
				break;			
			case 'chart-lineStyle':
				title = $$$Text('Line Style','%ZEN');
				break;			
			case 'chart-markerStyle':
				title = $$$Text('Marker Style','%ZEN');
				break;			
			case 'chart-indicatorStyle':
				title = $$$Text('Indicator Style','%ZEN');
				break;			
			case 'chart-axisLineStyle':
				title = $$$Text('Axis Line Style','%ZEN');
				break;			
			case 'chart-baseLineStyle':
				title = $$$Text('Baseline Style','%ZEN');
				break;			
			case 'chart-plotEdgeStyle':
				title = $$$Text('Plot Edge Style','%ZEN');
				break;			
			case 'chart-legendStyle':
				title = $$$Text('Legend Style','%ZEN');
				break;			
			case 'chart-gridStyle':
				title = $$$Text('Grid Style','%ZEN');
				break;			
			case 'chart-titleBoxStyle':
				title = $$$Text('Titlebox Style','%ZEN');
				break;
			case 'chart-legendStyle':
				title = $$$Text('Legend Style','%ZEN');
				break;
			case 'chart-legendRectStyle':
				title = $$$Text('Legend Rect Style','%ZEN');
				break;			
			case 'chart-upperRightStyle':
				title = $$$Text('Upper Right Style','%ZEN');
				break;
			case 'chart-lowerLeftStyle':
				title = $$$Text('Lower Left Style','%ZEN');
				break;			
			case 'chart-xAxis-majorGridStyle':
				title = $$$Text('xAxis Major Grid Style','%ZEN');
				break;
			case 'chart-xAxis-minorGridStyle':
				title = $$$Text('xAxis Minor Grid Style','%ZEN');
				break;
			case 'chart-yAxis-majorGridStyle':
				title = $$$Text('yAxis Major Grid Style','%ZEN');
				break;
			case 'chart-yAxis-minorGridStyle':
				title = $$$Text('yAxis Minor Grid Style','%ZEN');
				break;
			case 'chart-valueBoxStyle':
				title = $$$Text('Value Box Style','%ZEN');
				break;
			default: // no localization so punt
				title = key.split('-')[1];
		}
		var style = '';
		var which = key.split('-')[1];
		switch(which) {
		case 'xAxis':
			//title = 'xAxis ' + key.split('-')[2];
			attr = t[2];
			style = chart.xAxis[attr];
			break;
		case 'xAxis':
			//title = 'yAxis ' + key.split('-')[2];
			attr = t[2];
			style = chart.yAxisList[keyNo][attr];
			break;
		default:
			//title = key.split('-')[1];
			style = zenGet(chart[attr]);
			break;
		}

		// pull apart style
		var info = navigator.parseStyleSVG(style);

		var k2 = '';
		if (which=='yAxis') {
			k2 = ':' + keyNo;
		}

		var fill = info['fill'] ? info['fill'] : 'transparent';
		var fillColor = navigator.transformColor(fill);
		var stroke = info['stroke'] ? info['stroke'] : 'none';
		var strokeWidth = zenGet(info['stroke-width']);
		var opacity = zenGet(info['opacity']);
		var strokeDashArray = info['stroke-dasharray'];
		switch (strokeDashArray) {
		case '1,2':
			strokeDashArray = 'dotted';
			break;
		case '10,10':
			strokeDashArray = 'dashed';
			break;
		default:
			strokeDashArray = 'solid';
			break;
		}

		opacity = opacity==='' ? 1.0 : opacity;

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Fill','%ZEN'), action:'drill', value:fill,	key:key+'-fill'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%ZEN'), edit:'slider', value:opacity,	key:key+'-opacity'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line','%ZEN'), action:'drill', value:'',	key:key+'-stroke'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Width','%ZEN'), edit:'slider-toggle', value:strokeWidth,	key:key+'-stroke-width'+k2, minValue:0, maxValue:25, stepSize:0.25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Style','%ZEN'), edit:'choice', value:strokeDashArray,	key:key+'-stroke-dasharray'+k2, valueList:'solid,dashed,dotted', displayList:$$$Text('solid,dashed,dotted','%ZEN')};
		break;

	case 'chart-backgroundStyle-fill':
	case 'chart-backgroundStyle-stroke':
	case 'chart-plotAreaStyle-fill':
	case 'chart-plotAreaStyle-stroke':
	case 'chart-stripeStyle-fill':
	case 'chart-stripeStyle-stroke':
	case 'chart-bandUpperStyle-fill':
	case 'chart-bandUpperStyle-stroke':
	case 'chart-bandLowerStyle-fill':
	case 'chart-bandLowerStyle-stroke':
	case 'chart-borderStyle-fill':
	case 'chart-borderStyle-stroke':
	case 'chart-upperRightStyle-fill':
	case 'chart-upperRightStyle-stroke':
	case 'chart-lowerLeftStyle-fill':
	case 'chart-lowerLeftStyle-stroke':
	case 'chart-titleStyle-fill':
	case 'chart-titleStyle-stroke':
	case 'chart-subtitleStyle-fill':
	case 'chart-subtitleStyle-stroke':
	case 'chart-labelStyle-fill':
	case 'chart-labelStyle-stroke':
	case 'chart-legendLabelStyle-fill':
	case 'chart-legendLabelStyle-stroke':
	case 'chart-axisTitleStyle-fill':
	case 'chart-axisTitleStyle-stroke':
	case 'chart-valueLabelStyle-fill':
	case 'chart-valueLabelStyle-stroke':
	case 'chart-valueBoxStyle-fill':
	case 'chart-valueBoxStyle-stroke':
	case 'chart-lineStyle-fill':
	case 'chart-lineStyle-stroke':
	case 'chart-markerStyle-fill':
	case 'chart-markerStyle-stroke':
	case 'chart-indicatorStyle-fill':
	case 'chart-indicatorStyle-stroke':
	case 'chart-axisLineStyle-fill':
	case 'chart-axisLineStyle-stroke':
	case 'chart-baseLineStyle-fill':
	case 'chart-baseLineStyle-stroke':
	case 'chart-plotStyle-fill':
	case 'chart-plotStyle-stroke':
	case 'chart-plotEdgeStyle-fill':
	case 'chart-plotEdgeStyle-stroke':
	case 'chart-legendStyle-fill':
	case 'chart-legendStyle-stroke':
	case 'chart-gridStyle-fill':
	case 'chart-gridStyle-stroke':
	case 'chart-titleBoxStyle-fill':
	case 'chart-titleBoxStyle-stroke':
	case 'chart-legendStyle-fill':
	case 'chart-legendStyle-stroke':
	case 'chart-legendRectStyle-fill':
	case 'chart-legendRectStyle-stroke':
	case 'chart-seriesDetail-fill':
	case 'chart-xAxis-labelStyle-fill':
	case 'chart-xAxis-labelStyle-stroke':
	case 'chart-xAxis-majorGridStyle-fill':
	case 'chart-xAxis-majorGridStyle-stroke':
	case 'chart-xAxis-minorGridStyle-fill':
	case 'chart-xAxis-minorGridStyle-stroke':
	case 'chart-yAxis-labelStyle-fill':
	case 'chart-yAxis-labelStyle-stroke':
	case 'chart-yAxis-majorGridStyle-fill':
	case 'chart-yAxis-majorGridStyle-stroke':
	case 'chart-yAxis-minorGridStyle-fill':
	case 'chart-yAxis-minorGridStyle-stroke':
		switch (key) { // JSL4541 - localize title
		case 'chart-backgroundStyle-fill':
			title = $$$Text('Background Style Fill','%ZEN');
			break;
		case 'chart-backgroundStyle-stroke':
			title = $$$Text('Background Style Stroke','%ZEN');
			break;	
		case 'chart-plotAreaStyle-fill':
			title = $$$Text('Plot Area Style Fill','%ZEN');
			break;
		case 'chart-plotAreaStyle-stroke':
			title = $$$Text('Plot Area Style Stroke','%ZEN');
			break;
		case 'chart-stripeStyle-fill':
			title = $$$Text('Stripe Style Fill','%ZEN');
			break;
		case 'chart-stripeStyle-stroke':
			title = $$$Text('Stripe Style Stroke','%ZEN');
			break;	
		case 'chart-bandUpperStyle-fill':
			title = $$$Text('Upper Band Style Fill','%ZEN');
			break;
		case 'chart-bandUpperStyle-stroke':
			title = $$$Text('Upper Band Style Stroke','%ZEN');
			break;
		case 'chart-bandLowerStyle-fill':
			title = $$$Text('Lower Band Style Fill','%ZEN');
			break;
		case 'chart-bandLowerStyle-stroke':
			title = $$$Text('Lower Band Style Stroke','%ZEN');
			break;
		case 'chart-borderStyle-fill':
			title = $$$Text('Border Style Fill','%ZEN');
			break;
		case 'chart-borderStyle-stroke':
			title = $$$Text('Border Style Stroke','%ZEN');
			break;
		case 'chart-upperRightStyle-fill':
			title = $$$Text('Upper Right Style Fill','%ZEN');
			break;
		case 'chart-upperRightStyle-stroke':
			title = $$$Text('Upper Right Style Stroke','%ZEN');
			break;
		case 'chart-lowerLeftStyle-fill':
			title = $$$Text('Lower Left Style Fill','%ZEN');
			break;
		case 'chart-lowerLeftStyle-stroke':
			title = $$$Text('Lower Left Style Stroke','%ZEN');
			break;
		case 'chart-titleStyle-fill':
			title = $$$Text('Title Style Fill','%ZEN');
			break;
		case 'chart-titleStyle-stroke':
			title = $$$Text('Title Style Stroke','%ZEN');
			break;
		case 'chart-subtitleStyle-fill':
			title = $$$Text('Subtitle Style Fill','%ZEN');
			break;
		case 'chart-subtitleStyle-stroke':
			title = $$$Text('Subtitle Style Stroke','%ZEN');
			break;
		case 'chart-labelStyle-fill':
			title = $$$Text('Label Style Fill','%ZEN');
			break;
		case 'chart-labelStyle-stroke':
			title = $$$Text('Label Style Stroke','%ZEN');
			break
		case 'chart-legendLabelStyle-fill':
			title = $$$Text('Legend Label Style Fill','%ZEN');
			break;
		case 'chart-legendLabelStyle-stroke':
			title = $$$Text('Legend Label Style Stroke','%ZEN');
			break;
		case 'chart-axisTitleStyle-fill':
			title = $$$Text('Axis Title Style Fill','%ZEN');
			break;
		case 'chart-axisTitleStyle-stroke':
			title = $$$Text('Axis Title Style Stroke','%ZEN');
			break;
		case 'chart-valueLabelStyle-fill':
			title = $$$Text('Value Label Style Fill','%ZEN');
			break;
		case 'chart-valueLabelStyle-stroke':
			title = $$$Text('Value Label Style Stroke','%ZEN');
			break;
		case 'chart-valueBoxStyle-fill':
			title = $$$Text('Value Box Style Fill','%ZEN');
			break;
		case 'chart-valueBoxStyle-stroke':
			title = $$$Text('Value Box Style Stroke','%ZEN');
			break;
		case 'chart-lineStyle-fill':
			title = $$$Text('Line Style Fill','%ZEN');
			break;
		case 'chart-lineStyle-stroke':
			title = $$$Text('Line Style Stroke','%ZEN');
			break;
		case 'chart-markerStyle-fill':
			title = $$$Text('Marker Style Fill','%ZEN');
			break;
		case 'chart-markerStyle-stroke':
			title = $$$Text('Marker Style Stroke','%ZEN');
			break;
		case 'chart-indicatorStyle-fill':
			title = $$$Text('Indicator Style Fill','%ZEN');
			break;
		case 'chart-indicatorStyle-stroke':
			title = $$$Text('Indicator Style Stroke','%ZEN');
			break;
		case 'chart-axisLineStyle-fill':
			title = $$$Text('Axis Line Style Fill','%ZEN');
			break;
		case 'chart-axisLineStyle-stroke':
			title = $$$Text('Axis Line Style Stroke','%ZEN');
			break;
		case 'chart-baseLineStyle-fill':
			title = $$$Text('Baseline Style Fill','%ZEN');
			break;
		case 'chart-baseLineStyle-stroke':
			title = $$$Text('Baseline Style Stroke','%ZEN');
			break;
		case 'chart-plotStyle-fill':
			title = $$$Text('Plot Style Fill','%ZEN');
			break;
		case 'chart-plotStyle-stroke':
			title = $$$Text('Plot Style Stroke','%ZEN');
			break;
		case 'chart-plotEdgeStyle-fill':
			title = $$$Text('Plot Edge Style Fill','%ZEN');
			break;
		case 'chart-plotEdgeStyle-stroke':
			title = $$$Text('Plot Edge Style Stroke','%ZEN');
			break;
		case 'chart-legendStyle-fill':
			title = $$$Text('Legend Style Fill','%ZEN');
			break;
		case 'chart-legendStyle-stroke':
			title = $$$Text('Legend Style Stroke','%ZEN');
			break;
		case 'chart-gridStyle-fill':
			title = $$$Text('Grid Style Fill','%ZEN');
			break;
		case 'chart-gridStyle-stroke':
			title = $$$Text('Grid Style Stroke','%ZEN');
			break;
		case 'chart-titleBoxStyle-fill':
			title = $$$Text('Title Box Style Fill','%ZEN');
			break;
		case 'chart-titleBoxStyle-stroke':
			title = $$$Text('Title Box Style Stroke','%ZEN');
			break;
		case 'chart-legendRectStyle-fill':
			title = $$$Text('Legend Rectangle Style Fill','%ZEN');
			break;
		case 'chart-legendRectStyle-stroke':
			title = $$$Text('Legend Rectangle Style Stroke','%ZEN');
			break;
		case 'chart-seriesDetail-fill':
			title = $$$Text('Series Detail Style Fill','%ZEN');
			break;
		case 'chart-xAxis-labelStyle-fill':
			title = $$$Text('xAxis Label Style Fill','%ZEN');
			break;
		case 'chart-xAxis-labelStyle-stroke':
			title = $$$Text('xAxis Label Style Stroke','%ZEN');
			break;
		case 'chart-xAxis-majorGridStyle-fill':
			title = $$$Text('xAxis Major Grid Style Fill','%ZEN');
			break;
		case 'chart-xAxis-majorGridStyle-stroke':
			title = $$$Text('xAxis Major Grid Style Stroke','%ZEN');
			break;
		case 'chart-xAxis-minorGridStyle-fill':
			title = $$$Text('xAxis Minor Grid Style Fill','%ZEN');
			break;
		case 'chart-xAxis-minorGridStyle-stroke':
			title = $$$Text('xAxis Minor Grid Style Stroke','%ZEN');
			break;
		case 'chart-yAxis-labelStyle-fill':
			title = $$$Text('yAxis Label Style Fill','%ZEN');
			break;
		case 'chart-yAxis-labelStyle-stroke':
			title = $$$Text('yAxis Label Style Stroke','%ZEN');
			break;
		case 'chart-yAxis-majorGridStyle-fill':
			title = $$$Text('yAxis Major Grid Style Fill','%ZEN');
			break;
		case 'chart-yAxis-majorGridStyle-stroke':
			title = $$$Text('yAxis Major Grid Style Stroke','%ZEN');
			break;
		case 'chart-yAxis-minorGridStyle-fill':
			title = $$$Text('yAxis Minor Grid Style Fill','%ZEN');
			break;
		case 'chart-yAxis-minorGridStyle-stroke':
			title = $$$Text('yAxis Minor Grid Style Stroke','%ZEN');
			break;
		default:
			title = key.split('-')[1] + ' ' + key.split('-')[2]; // don't localize punt
			
		}
		var which = key.split('-')[1];
		switch(which) {
		case 'xAxis':
			//title = 'xAxis ' + key.split('-')[2] + ' ' + key.split('-')[3];
			break;
		case 'xAxis':
			//title = 'yAxis ' + key.split('-')[2] + ' ' + key.split('-')[3];
			break;
		default:
			//title = key.split('-')[1] + ' ' + key.split('-')[2];
			break;
		}

		var k2 = (keyNo === '') ? '' : ':' + keyNo;

		// choose a color
		var html = navigator.getColorChooserHTML(key+k2,value,'svg');
		content.html = html;
		break;

	case 'chart-titleStyle-font-family':
	case 'chart-subtitleStyle-font-family':
	case 'chart-labelStyle-font-family':
	case 'chart-axisTitleStyle-font-family':
	case 'chart-valueLabelStyle-font-family':
	case 'chart-legendLabelStyle-font-family':
	case 'chart-xAxis-labelStyle-font-family':
	case 'chart-yAxis-labelStyle-font-family':
		switch (key) { // JSL4541, localize using $$$Text
			case 'chart-titleStyle-font-family':
				title = $$$Text('Title Style Font Family','%ZEN');
				break;
			case 'chart-subtitleStyle-font-family':
				title = $$$Text('Subtitle Style Font Family','%ZEN');
				break;
			case 'chart-labelStyle-font-family':
				title = $$$Text('Label Style Font Family','%ZEN');
				break;
			case 'chart-axisTitleStyle-font-family':
				title = $$$Text('Axis Title Style Font Family','%ZEN');
				break;
			case 'chart-valueLabelStyle-font-family':
				title = $$$Text('Value Label Style Font Family','%ZEN');
				break;
			case 'chart-legendLabelStyle-font-family':
				title = $$$Text('Legend Label Style Font Family','%ZEN');
				break;
			case 'chart-xAxis-labelStyle-font-family':
				title = $$$Text('yAxis Label Style Font Family','%ZEN');
				break;
			case 'chart-yAxis-labelStyle-font-family':
				title = $$$Text('yAxis Label Style Font Family','%ZEN');
				break;
			default:
				title = key.split('-')[1] + ' Font'; // don't localize, punt
		}	
		var which = key.split('-')[1];
		switch(which) {
		case 'xAxis':
			//title = 'xAxis ' + key.split('-')[2] + ' Font';
			break;
		case 'xAxis':
			//title = 'yAxis ' + key.split('-')[2] + ' Font';
			break;
		default:
			//title = key.split('-')[1] + ' Font';
			break;
		}

		var k2 = (keyNo === '') ? '' : ':' + keyNo;
		content.html = navigator.getFontChooserHTML(key+k2,value);
		break;
	}

	content.title = title;
	return content;
}

/// Implementation of the dataArrange method for charts.
ClientMethod chartDataArrange(navigator, chart, key, swap, final) [ Language = javascript ]
{
	// key may take the form <item>:keyNo
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	switch(key) {
	case 'chart-seriesDetail':
		if (!this._oldColors) {
			this._oldColors = zenGet(chart.seriesColorsOverride);
		}
		if (!this._oldTypes) {
			this._oldTypes = zenGet(chart.seriesTypes);
		}
		if (!this._oldMarkers) {
			this._oldMarkers = zenGet(chart.markerShapes);
		}

		// rearrange all the lists
		// colors
		var seriesColors = this.chartParseColorList(this._oldColors);
		var newList = [];
		for (var n = 0; n < seriesColors.length; n++) {
			newList[n] = seriesColors[n];
		}
		var x = newList[swap.oldPosition];
		newList[swap.oldPosition] = newList[swap.newPosition];
		newList[swap.newPosition] = x;
		chart.setProperty('seriesColorsOverride',newList.join(','));

		// seriesTypes
		var types = this._oldTypes.toString().split(',');
		var newList = [];
		for (var n = 0; n < types.length; n++) {
			newList[n] = types[n];
		}
		var x = newList[swap.oldPosition];
		newList[swap.oldPosition] = newList[swap.newPosition];
		newList[swap.newPosition] = x;
		chart.setProperty('seriesTypes',newList.join(','));

		// markerShapes
		var shapes = this._oldMarkers.toString().split(',');
		var newList = [];
		for (var n = 0; n < shapes.length; n++) {
			newList[n] = shapes[n];
		}
		var x = newList[swap.oldPosition];
		newList[swap.oldPosition] = newList[swap.newPosition];
		newList[swap.newPosition] = x;
		chart.setProperty('markerShapes',newList.join(','));

		if (final) {
			delete this._oldColors;
			delete this._oldTypes;
			delete this._oldMarkers;
		}
		// skip name and yAxis

		break;

	case 'chart-yAxis':
		if (!this._oldYAxis) {
			this._oldYAxis = zenGet(chart.yAxisList);
		}
		var newList = [];
		for (var n = 0; n < this._oldYAxis.length; n++) {
			newList[n] = this._oldYAxis[n];
		}
		var x = newList[swap.oldPosition];
		newList[swap.oldPosition] = newList[swap.newPosition];
		newList[swap.newPosition] = x;
		chart.yAxisList = newList;
		chart.render();

		if (final) {
			delete this._oldYAxis;
		}
		break;

	default:
		break;
	}
}

/// Implementation of the dataChange method for charts.
ClientMethod chartDataChange(navigator, svg, chart, key, value, final) [ Language = javascript ]
{
	// key may take the form <item>:keyNo
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// pull apart key (remove 'chart-')
	var t = key.toString().split('-');
	var attr = t[1];

	var object = chart;	

	// if true; apply the change
	var apply = final || (chart.getSeriesSize()<50);

	// check if we are referring to an axis
	var which = '';
	if (attr == 'xAxis') {
		which = attr;
		t.splice(0,1);
		key = t.join('-');
		var t = key.toString().split('-');
		var attr = t[1];
		object = chart.xAxis;
		if (!object.parent) {
			object.parent = chart;
		}
	}
	else if (attr == 'yAxis') {
		which = attr;
		t.splice(0,1);
		key = t.join('-');
		var t = key.toString().split('-');
		var attr = t[1];
		object = chart.yAxisList[keyNo];
		if (!object.parent) {
			object.parent = chart;
		}
	}

	// apply change to chart
	switch (attr) {
	case 'msgIfNoData': // JSL4478
	case 'warnIfNoData': // JSL4478
	case 'noDataOpacity': // JSL4478
	case 'noDataFill': // JSL4478
	case 'noDataStroke': // JSL4478
		if (apply) {
			chart.setProperty(attr,value); // JSL4478
		}
		break;			
	case 'ChartType':
		// change chart class if needed
		if (apply) {
			this.chartSetChartType(svg,chart,value);
		}
		break;

	case 'seriesCount':
	case 'seriesSize':
		if (final) {
			this[attr] = parseInt(value);
			chart.setProperty(key,value);
			this.updateChartData();
		}
		break;

	case 'width':
	case 'height':
		zen('svg').setProperty(attr,value);
		chart.setProperty(attr,value);
		break;

	case 'marginTop':
	case 'marginTopUnits':
		if (apply) {
			var refresh = false;
			this[attr] = value;
			if (attr=='marginTop' && this.marginTopUnits=='auto') {
				this.marginTopUnits = '%';
				refresh = true;
			}
			object.setProperty('marginTop',this.chartCreateLength(this.marginTop,this.marginTopUnits));
			if (refresh) {
				navigator.refreshTopSheet();
			}
		}
		break;
	case 'marginBottom':
	case 'marginBottomUnits':
		if (apply) {
			var refresh = false;
			this[attr] = value;
			if (attr=='marginBottom' && this.marginBottomUnits=='auto') {
				this.marginBottomUnits = '%';
				refresh = true;
			}
			object.setProperty('marginBottom',this.chartCreateLength(this.marginBottom,this.marginBottomUnits));
			if (refresh) {
				navigator.refreshTopSheet();
			}
		}
		break;
	case 'marginLeft':
	case 'marginLeftUnits':
		if (apply) {
			var refresh = false;
			this[attr] = value;
			if (attr=='marginLeft' && this.marginLeftUnits=='auto') {
				this.marginLeftUnits = '%';
				refresh = true;
			}
			object.setProperty('marginLeft',this.chartCreateLength(this.marginLeft,this.marginLeftUnits));
			if (refresh) {
				navigator.refreshTopSheet();
			}
		}
		break;
	case 'marginRight':
	case 'marginRightUnits':
		if (apply) {
			var refresh = false;
			this[attr] = value;
			if (attr=='marginRight' && this.marginRightUnits=='auto') {
				this.marginRightUnits = '%';
				refresh = true;
			}
			object.setProperty('marginRight',this.chartCreateLength(this.marginRight,this.marginRightUnits));
			if (refresh) {
				navigator.refreshTopSheet();
			}
		}
		break;

	case 'title':
		if (apply) {
			if (typeof this.origChartTitle != 'undefined') {
				if (which == 'xAxis') {
					this.origChartXAxisTitle = value;
				}
				else if (which == 'yAxis') {
					this.origChartYAxisTitles[keyNo] = value;
				}
				else {
					this.origChartTitle = value;
				}
			}
			object.setProperty(attr,value);
		}
		break;

	case 'subtitle':
		if (apply) {
			if (typeof this.origChartSubtitle != 'undefined') {
				this.origChartSubtitle = value;
			}
			object.setProperty(attr,value);
		}
		break;

	case 'title':
	case 'seriesCount':
	case 'seriesSize':
	case 'radius':
	case 'legendVisible':
	case 'gap':
	default:
		if (apply) {
			object.setProperty(attr,value);
		}
		break;

	case 'labelsVisible':
	case 'maxLabelLen':
		if (apply) {
			object.setProperty(attr,value);
		}
		break;

	case 'titleImageStyle':
	case 'backgroundStyle':
	case 'plotAreaStyle':
	case 'titleStyle':
	case 'subtitleStyle':
	case 'labelStyle':
	case 'axisTitleStyle':
	case 'valueLabelStyle':
	case 'valueBoxStyle':
	case 'stripeStyle':
	case 'bandUpperStyle':
	case 'bandLowerStyle':
	case 'borderStyle':
	case 'upperRightStyle':
	case 'lowerLeftStyle':
	case 'lineStyle':
	case 'markerStyle':
	case 'indicatorStyle':
	case 'axisLineStyle':
	case 'baseLineStyle':
	case 'plotStyle':
	case 'plotEdgeStyle':
	case 'legendStyle':
	case 'gridStyle':
	case 'titleBoxStyle':
	case 'legendStyle':
	case 'legendLabelStyle':
	case 'legendRectStyle':
	case 'majorGridStyle':
	case 'minorGridStyle':
		if (apply) {
			t.splice(0,2);
			var styleProp = t.join('-');

			// fold attr into style
			var styleValues = {};
			if (styleProp && styleProp.length) {
				switch(styleProp) {
				case 'textStyle':
					var cv = value.toString().split(',');
					for (var n = 0; n < cv.length; n++) {
						styleValues[cv[n]] = true;
					}
					styleProp = null;
					break;
				case 'opacity':
					value = value >=1 ? '' : value;
					chart.setSeeThrough(value); // JSL4483
					break;
				case 'stroke-dasharray':
					switch (value) {
					case 'dotted':
						value = '1,2';
						break;
					case 'dashed':
						value = '10,10';
						break;
					case 'solid':
					default:
						value = '';
						break;
					}
					break;
				}

				var style = object.getProperty(attr);

				var info = navigator.parseStyleSVG(style);
				if (styleProp) {
					info[styleProp] = value;
				}
				else {
					if (styleValues.bold) {
						info['font-weight'] = 'bold';
					}
					else {
						delete info['font-weight'];
					}
					if (styleValues.italic) {
						info['font-style'] = 'italic';
					}
					else {
						delete info['font-style'];
					}
					if (styleValues.smallCaps) {
						info['font-variant'] = 'small-caps';
					}
					else {
						delete info['font-variant'];
					}
					if (styleValues.shadow) {
						info['text-shadow'] = '1px 1px 1px #808080';
					}
					else {
						delete info['text-shadow'];
					}
				}
				if (info['font-size']) {
					info['font-size'] = parseInt(info['font-size']) + 'px';
				}
				
				// search for svgFrame div element containing chart object - JSL4483

				style = navigator.convertCSSToText(info);
				object.setProperty(attr,style);
				if (which=='yAxis') {
				}

				// make sure navigator shows current value
				var spec = navigator.getParentSpec();
				spec.value = style;
			}
		}
		break;
	case 'seriesDetail':
		if (apply) {
			t.splice(0,2);
			var styleProp = t.join('-');
			switch (styleProp) {
			case 'fill':
				var seriesColors = this.chartParseColorList(zenGet(chart.seriesColorsOverride));
				seriesColors[this._seriesNo] = value;
				chart.setProperty('seriesColorsOverride',seriesColors.join(','));
				break;
			case 'plotType':
				var types = zenGet(chart.seriesTypes).toString().split(',');
				types[this._seriesNo] = value;
				chart.setProperty('seriesTypes',types.join(','));
				break;
			case 'markerShape':
				var shapes = zenGet(chart.markerShapes).toString().split(',');
				shapes[this._seriesNo] = value;
				chart.setProperty('markerShapes',shapes.join(','));
				break;
			case 'name':
				var names = zenGet(chart.seriesNames).toString().split(',');
				names[this._seriesNo] = value;
				chart.setProperty('seriesNames',names.join(','));
				// apply names to sample data !!!!
				zen('chartData').setProperty('propertyList',names.join(','));
				this.updateChartData();
				break;
			case 'yAxisNo':
				var axes = zenGet(chart.seriesYAxes).toString().split(',');
				axes[this._seriesNo] = value;
				// make sure there are no gaps in the axis list
				for (var n = 0; n < axes.length; n++) {
					axes[n] = axes[n]&&axes[n]!=='' ? axes[n] : 0;
				}
				chart.setProperty('seriesYAxes',axes.join(','));
				break;
			}
		}
		break;
	}
	return true;
}

/// Parse a "css" length into value and units.
ClientMethod chartParseLength(length, info) [ Language = javascript ]
{
	var units = (length==''?'auto':((length.toString().indexOf('px')>=0)?'px':'%'));
	var	value = (units=='auto'?'':parseInt(length));
	return {value:value, units:units};
}

/// Take a value and units (auto,%,px) and return a css length.
ClientMethod chartCreateLength(value, units) [ Language = javascript ]
{
	var len = '';
	value = ('undefined' == typeof value)||(''===value) ? 0 : value;
	switch(units) {
	case '%':
		len = value;
		break;
	case 'px':
		len = value + 'px';
		break;
	}
	return len;
}

/// Split apart a list of color values.
ClientMethod chartParseColorList(colors) [ Language = javascript ]
{
	var colorList = [];

	var str = colors.toString()+',';
	var inParen = false;
	var token = '';
	for (var n = 0; n < str.length; n++) {
		var ch = str.charAt(n);
		if (inParen) {
			token += ch;
			if (ch == ')') {
				inParen = false;
			}
		}
		else {
			if (ch == ',') {
				colorList[colorList.length] = token ? token : '';
				token = '';
			}
			else if (ch == '(') {
				inParen = true;
				token += ch;
			}
			else {
				token += ch;
			}
		}
	}

	return colorList;
}

/// Set the type of the displayed chart.
ClientMethod chartSetChartType(svg, chart, type) [ Language = javascript ]
{
	if (''==type) {
		if (zenPage._oldChartType) {
			// restore to cached type
			type = zenPage._oldChartType;
		}
		else {
			return;
		}
	}
	if (null==chart) return;
	var newType = '';
	var change = false; // JSL4165
	
	// make sure correct chart is in place
	switch(type) {
	case 'pivot':
		change = true;
		type = chart._type;
		newType = type;
		break;
	case 'barChart':
	case 'barChart3D':
	case 'columnChart':
	case 'columnChart3D':
	case 'barChartStacked':
	case 'columnChartStacked':
		newType = 'barChart';
		break;
	case 'lineChart':
	case 'lineChartMarkers':
	case 'areaChart':
		newType = 'lineChart';
		break;
	case 'hiLowChart':
		newType = 'hilowChart';
		break;
	case 'xyChart':
		newType = 'xyChart';
		break;
	case 'timeChart':
	case 'comboChart':
		newType = 'comboChart';
		break;
	case 'bubbleChart':
		newType = 'bubbleChart';
		break;
	case 'bullseyeChart':
		newType = 'bullseyeChart';
		break;
	case 'treeMapChart':
		newType = 'treeMapChart';
		break;
	case 'pieChart':
	case 'pieChart3D':
	case 'donutChart':
	case 'donutChart3D':
		newType = 'pieChart';
		break;
	case 'swirlChart':
		// JSL4277
		newType = 'swirlChart';
		break;
	default:
		alert('Unhandled type(1) in setChartType: ' + type);
		return;
	}

	if (newType != chart._type || change) {
		var newChart = zenPage.createComponent(newType);
		newChart.setProperty('controllerId',chart.controllerId);
		newChart.setProperty('width',chart.width);
		newChart.setProperty('height',chart.height);

		// copy over other settings
		newChart.appearance = chart.appearance;
		newChart.legendVisible= chart.legendVisible;
		newChart.titleStyle = chart.titleStyle;
		newChart.titleBoxStyle = chart.titleBoxStyle;
		newChart.subtitleStyle = chart.subtitleStyle;
		newChart.borderRadius = chart.borderRadius;
		newChart.borderStyle = chart.borderStyle;
		newChart.backgroundStyle = chart.backgroundStyle;
		newChart.plotAreaStyle = chart.plotAreaStyle;
		newChart.plotEdgeStyle = chart.plotEdgeStyle;
		newChart.selectedItemStyle = chart.selectedItemStyle;
		newChart.unselectedItemStyle = chart.unselectedItemStyle;
		newChart.titleAlign = chart.titleAlign;
		newChart.title = chart.title;
		newChart.subtitle = chart.subtitle;
		newChart.legendTitle = chart.legendTitle;
		newChart.stripesVisible = chart.stripesVisible;
		newChart.stripeStyle = chart.stripeStyle;
		newChart.seriesColors = chart.seriesColors;
		newChart.seriesColorScheme = chart.seriesColorScheme;
		newChart.seriesColorsOverride = chart.seriesColorsOverride;
		newChart.seriesNames = chart.seriesNames;
		newChart.markerScale = chart.markerScale;
		newChart.gridStyle = chart.gridStyle;
		newChart.lineStyle = chart.lineStyle;
		newChart.markerStyle = chart.markerStyle;
		newChart.indicatorStyle = chart.indicatorStyle;
		newChart.indicatorsVisible = chart.indicatorsVisible;
		newChart.markerShapes = chart.markerShapes;
		newChart.axisLineStyle = chart.axisLineStyle;
		newChart.bandUpper = chart.bandUpper;
		newChart.bandUpperStyle = chart.bandUpperStyle;
		newChart.bandLower = chart.bandLower;
		newChart.bandLowerStyle = chart.bandLowerStyle;
		newChart.seriesYAxes = chart.seriesYAxes;
		newChart.baseLineStyle = chart.baseLineStyle;
		newChart.titleImage = chart.titleImage;
		newChart.titleImageStyle = chart.titleImageStyle;

		newChart.marginRight = chart.marginRight;
		newChart.marginLeft = chart.marginLeft;
		newChart.marginTop = chart.marginTop;
		newChart.marginBottom = chart.marginBottom;

		newChart.valueLabelsVisible = chart.valueLabelsVisible;
		newChart.valueLabelStyle = chart.valueLabelStyle;
		newChart.valueBoxStyle = chart.valueBoxStyle;
		newChart.valueLabelFormat = chart.valueLabelFormat;
		newChart.onelementClick = chart.onelementClick;
		newChart.labelStyle = chart.labelStyle;

		newChart.ongetSeriesColor = chart.ongetSeriesColor;
		newChart.onrenderData = chart.onrenderData;
		
		newChart.msgIfNoData = chart.msgIfNoData; // JSL4478
		newChart.warnIfNoData = chart.warnIfNoData; // JSL4478
		newChart.noDataOpacity = chart.noDataOpacity; // JSL4478
		newChart.noDataFill = chart.noDataFill; // JSL4478
		
		// JSL4277
		if (false) {
			newChart.invert = chart.invert;
			newChart.gap = chart.gap;
			newChart.plotBy = chart.plotBy;
			newChart.separateSeriesScale = chart.separateSeriesScale;
			newChart.ongetLabelX = chart.ongetLabelX;
		}

		if (chart.xAxis) {
			newChart.xAxis = chart.xAxis;
		}
		
		// yAxisList
		if (chart.yAxisList) {
			newChart.yAxisList = [];
			for (var ya = 0; ya < chart.yAxisList.length; ya++) {
				var axis = chart.yAxisList[ya];
				if (axis && axis._type) {
					var newAxis = zenPage.createComponent(axis._type);
					newAxis.minValue = axis.minValue;
					newAxis.maxValue = axis.maxValue;
					newAxis.title = axis.title;
					newAxis.baseValue = axis.baseValue;
					newAxis.majorUnits = axis.majorUnits;
					newAxis.minorUnits = axis.minorUnits;
					newAxis.labelUnits = axis.labelUnits;
					newAxis.labelAngle = axis.labelAngle;
					newAxis.labelStyle = axis.labelStyle;
					newAxis.majorGridLines = axis.majorGridLines;
					newAxis.minorGridLines = axis.minorGridLines;
					newAxis.majorGridStyle = axis.majorGridStyle;
					newAxis.minorGridStyle = axis.minorGridStyle;
					newAxis.labelPosition = axis.labelPosition;
					newAxis.axisType = axis.axisType;

					newChart.yAxisList[newChart.yAxisList.length] = newAxis;
				}
			}
		}

		chart.unrender();
		// svg.addChild(newChart);
		// jmd: insert newChart before oldChart
		for (var n = 0; n < svg.children.length; n++) {
			if (svg.children[n] == chart) {
				svg.children.splice(n,0,newChart);
				newChart.parent = svg;
				if (svg.document && svg.svgGroup) {
					newChart.renderSVG(svg.document,svg.svgGroup);
				}
				break;
			}
		}

		svg.removeChild(chart);
		newChart.setProperty('id',chart.id);
		chart = newChart;
	}

	chart.appearance = '2D';
	chart.timeBased = false;

	switch(type) {
	case 'barChart':
		chart.chartPivot = true;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'barChart3D':
		chart.appearance = '3D';
		chart.chartPivot = true;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'columnChart3D':
		chart.appearance = '3D';
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'columnChart':
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = true;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = false;
		}
		break;
	case 'barChartStacked':
		chart.chartPivot = true;
		chart.chartStacked = true;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'columnChartStacked':
		chart.chartPivot = false;
		chart.chartStacked = true;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = true;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = false;
		}
		break;
	case 'timeChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.chartFilled = false;
		chart.plotToEdge = true;
		chart.seriesTypes = 'line,line,line,line,line,line,line,line';
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		chart.timeBased = true;
		chart.hasZoom = false;
		break;

	case 'lineChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.chartFilled = false;
		chart.plotToEdge = true;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'lineChartMarkers':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.chartFilled = false;
		chart.plotToEdge = true;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'areaChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.chartStacked = true;
		chart.chartFilled = true;
		chart.plotToEdge = true;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'hiLowChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.plotToEdge = false;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'comboChart':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.plotToEdge = false;
		chart.seriesTypes = 'bar,bar,line';
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'xyChart':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.plotToEdge = true;
		chart.xAxis.majorGridLines = false;
		if (chart.yAxisList[0]) {
			chart.yAxisList[0].majorGridLines = true;
		}
		break;
	case 'pieChart':
		chart.holeSize = 0;
		chart.marginLeft = "";
		chart.showMultiples = true;
		chart.labelsVisible = false;
		break;
	case 'pieChart3D':
		chart.holeSize = 0;
		chart.appearance = '3D';
		chart.marginLeft = "";
		chart.showMultiples = true;
		chart.labelsVisible = false;
		break;
	case 'donutChart':
		chart.holeSize = 0.25;
		chart.marginLeft = "";
		chart.showMultiples = true;
		chart.labelsVisible = false;
		break;
	case 'donutChart3D':
		chart.holeSize = 0.25;
		chart.appearance = '3D';
		chart.marginLeft = "";
		chart.showMultiples = true;
		chart.labelsVisible = false;
		break;
	case 'bubbleChart':
		break;
	case 'bullseyeChart':
		break;
	case 'treeMapChart':
		break;
	case 'swirlChart':
		// JSL4277
		chart.animate = 'none';
		chart.ongetLabelX = "return zenPage.getComponentById('"+chart.id+"').seriesNames.split(',')[value];";
		break;
	default:
		alert('Unhandled type in setChartType: ' + type);
		break;
	}

	if (chart.markersVisible == true) { // JSL4486
		chart.plotToEdge = false;       // JSL4486
	}
	// apply changes
	chart.hzZoomStep = 0;
	chart.scrollLeft = 0;
	chart.unrender();
	chart.render();
}

/// Button clicked in navigator header.
ClientMethod chartHeaderButtonClick(navigator, chart, key) [ Language = javascript ]
{
	switch(key) {
	case 'chart-addYAxis':
		var axis = zenPage.createComponent('axis');
		axis.parent = chart;
		chart.yAxisList[chart.yAxisList.length] = axis;
		navigator.refreshTopSheet();
		break;
	default:
		break;
	}
}

/// Button clicked in navigator close button.
ClientMethod chartCloseButtonClick(navigator, chart, key) [ Language = javascript ]
{
	var t = key.toString().split(':');

	switch(t[0]) {
	case 'chart-yAxis':
		if (confirm('Do you wish to remove this y axis?')) {
			var axisNo = parseInt(t[1]);
			// remove references to this axis
			var isEmpty = true;
			var st = chart.seriesYAxes.toString().split(',');
			for (var d = 0; d < st.length; d++) {
				if (st[d] == axisNo) {
					st[d] = 0;
				}
				else if (st[d]) {
					isEmpty = false;
				}
			}
			chart.seriesYAxes = isEmpty ? '' : st.join(',');
			chart.yAxisList.splice(axisNo,1);
			chart.currYAxis = 0;
			chart.unrender();
			chart.render();
			navigator.refreshTopSheet();
		}
		break;
	default:
		break;
	}
}

}
