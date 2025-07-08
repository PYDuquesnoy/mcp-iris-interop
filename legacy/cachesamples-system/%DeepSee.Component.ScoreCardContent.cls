/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility class supplies the methods needed to control a scoreCard using a navigator component.
Class %DeepSee.Component.ScoreCardContent [ Abstract, System = 3 ]
{

/// Return an object describing what to display for this level.
ClientMethod scorecardGetContentForLevel(navigator, chart, level, key, value) [ Language = javascript ]
{
	var title = $$$Text('Scorecard Options','%DeepSee');
	var content = { title: title, items:[] };

	var settings = {};
	chart.getSettings(settings);

	// key may take the form <item>:keyNo
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// get attribute name from key
	var t = key.toString().split('-');
	t.splice(0,1);
	var attr = t.join('-');

	switch (key) {
	case 'card-ScoreCardSettings':
		// root
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Size &amp; Appearance','%DeepSee'), action:'drill', key:'card-ScoreCardSize'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Titles','%DeepSee'), action:'drill', key:'card-ScoreCardTitle'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Colors &amp; Style','%DeepSee'), action:'drill', key:'card-ScoreCardColors'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Columns','%DeepSee'), action:'drill', key:'card-ScoreCardColumnList'};
		break;

	case 'card-ScoreCardSize':
		title = $$$Text('Size and Appearance','%DeepSee');
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'integer', value:zenGet(chart.width),  key:'width'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%DeepSee'), edit:'integer', value:zenGet(chart.height),  key:'height'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Size','%DeepSee'), edit:'choice', value:zenGet(chart.cardSize),  key:'card-cardSize',valueList:',big', displayList:$$$Text('Regular,Big','%DeepSee')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Title','%DeepSee'), edit:'switch', value:zenGet(chart.titleVisible),  key:'card-titleVisible'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Headers','%DeepSee'), edit:'switch', value:zenGet(chart.headersVisible),  key:'card-headersVisible'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Footers','%DeepSee'), edit:'switch', value:zenGet(chart.footersVisible),  key:'card-footersVisible'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Height','%DeepSee'), edit:'slider-toggle', value:zenGet(chart.rowHeight),	key:'card-rowHeight', minValue:1, maxValue:150 };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Arrow Size','%DeepSee'), edit:'slider', value:zenGet(chart.arrowSize),	key:'card-arrowSize', minValue:0, maxValue:1 };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lamp Size','%DeepSee'), edit:'slider', value:zenGet(chart.lampSize),	key:'card-lampSize', minValue:0, maxValue:1 };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('TrendLine Hgt','%DeepSee'), edit:'slider', value:zenGet(chart.trendLineHeight),	key:'card-trendLineHeight', minValue:0, maxValue:1 };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('TrendBars Hgt','%DeepSee'), edit:'slider', value:zenGet(chart.trendBarsHeight),	key:'card-trendBarsHeight', minValue:0, maxValue:1 };

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plotbox Height','%DeepSee'), edit:'slider', value:zenGet(chart.plotBoxHeight),	key:'card-plotBoxHeight', minValue:0, maxValue:1 };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Plotbox Value','%DeepSee'), edit:'slider', value:zenGet(chart.plotBoxValueHeight),	key:'card-plotBoxValueHeight', minValue:0, maxValue:1 };

		// column widths shortcut
		var list = chart.columns;
		if (!list) {
			chart.columns = [];
		}

		if (list.length) {
			// section header
			content.items[content.items.length] = {display:'section', caption:$$$Text('Column Widths','%DeepSee')};
		}

		// key is column:n
		for (var n = 0; n < list.length; n++) {
			var column = list[n];
			var name = zenGet(column.label);
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column ','%DeepSee') + (n+1), edit:'slider-toggle', value:zenGet(column.width),	key:'card-column-width:'+n, minValue:0, maxValue:500 };
		}
		break;

	case 'card-ScoreCardTitle':
		title = $$$Text('Titles','%DeepSee');
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), edit:'string', value:zenGet(chart.title),  key:'card-title'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Style','%DeepSee'), action:'drill', value:zenGet(chart.titleStyle),	key:'card-titleStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle','%DeepSee'), edit:'string', value:zenGet(chart.subtitle),  key:'card-subtitle'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle Style','%DeepSee'), action:'drill', value:zenGet(chart.subtitleStyle),	key:'card-subtitleStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Align','%DeepSee'), edit:'choice', value:zenGet(chart.titleAlign),	key:'card-titleAlign', valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Box','%DeepSee'), action:'drill', value:zenGet(chart.titleBoxStyle),	key:'card-titleBoxStyle', text:''};

		content.items[content.items.length] = {display:'caption', caption:$$$Text('Title Image','%DeepSee'), action:'drill', value:zenGet(chart.titleImage),	key:'card-titleImage'};
		
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

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Width','%DeepSee'), edit:'slider-toggle', value:imageWidth, key:'card-titleImageStyle-width', minValue:0, maxValue:150};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Height','%DeepSee'), edit:'slider-toggle', value:imageHeight, key:'card-titleImageStyle-height', minValue:0, maxValue:150};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Top','%DeepSee'), edit:'slider-toggle', value:imageTop, key:'card-titleImageStyle-top', minValue:0, maxValue:150};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Image Left','%DeepSee'), edit:'slider-toggle', value:imageHeight, key:'card-titleImageStyle-left', minValue:0, maxValue:150};

		break;

	case 'card-titleImage':
		// get icon list
		title = $$$Text('Title Image','%DeepSee');		// DTB236
		var options = zenPage.fetchOptionList('image-list','');
		var list = options.children;
		content.html = zenPage.getNavigator().getIconListHTML(list,key,'');
		break;

	case 'card-ScoreCardColors':
		title = $$$Text('Scorecard Colors','%DeepSee');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:zenGet(chart.backgroundStyle),	key:'card-backgroundStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripe Style','%DeepSee'), action:'drill', value:zenGet(chart.stripeStyle),	key:'card-stripeStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Separator Style','%DeepSee'), action:'drill', value:zenGet(chart.gridStyle),	key:'card-gridStyle', text:''};
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Style','%DeepSee'), action:'drill', value:zenGet(chart.labelStyle),	key:'card-labelStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Style','%DeepSee'), action:'drill', value:zenGet(chart.valueLabelStyle),	key:'card-valueLabelStyle', text:''};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Caption Style','%DeepSee'), action:'drill', value:zenGet(chart.cellCaptionStyle),	key:'card-cellCaptionStyle', text:''};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Header Style','%DeepSee'), action:'drill', value:zenGet(chart.columnHeaderStyle),	key:'card-columnHeaderStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('TrendLine Style','%DeepSee'), action:'drill', value:zenGet(chart.trendLineStyle),	key:'card-trendLineStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('TrendBars Style','%DeepSee'), action:'drill', value:zenGet(chart.trendBarsStyle),	key:'card-trendBarsStyle', text:''};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Arrow Style','%DeepSee'), action:'drill', value:zenGet(chart.arrowStyle),	key:'card-arrowStyle', text:''};

		var fill = zenGet(chart.lampColor);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lamp Color','%DeepSee'), action:'drill', value:'',	key:'card-lampColor-fill', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';'};

		var fill = zenGet(chart.lampColorNeg);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lamp Negative','%DeepSee'), action:'drill', value:'',	key:'card-lampColorNeg-fill', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lamp Value Style','%DeepSee'), action:'drill', value:zenGet(chart.lampLabelStyle),	key:'card-lampLabelStyle', text:''};

		// group for plotbox
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Plotbox','%DeepSee'), 	action:'drill', key:'card-ScoreCardPlotBox'};
		break;

	case 'card-ScoreCardPlotBox':
		title = $$$Text('Plotbox Styles','%DeepSee');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Style','%DeepSee'), action:'drill', value:zenGet(chart.plotBoxValueStyle),	key:'card-plotBoxValueStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Box Style','%DeepSee'), action:'drill', value:zenGet(chart.plotBoxStyle),	key:'card-plotBoxStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower Style','%DeepSee'), action:'drill', value:zenGet(chart.plotBoxLowerStyle),	key:'card-plotBoxLowerStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Mid Style','%DeepSee'), action:'drill', value:zenGet(chart.plotBoxMidStyle),	key:'card-plotBoxMidStyle', text:''};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Target Line','%DeepSee'), action:'drill', value:zenGet(chart.targetLineStyle),	key:'card-targetLineStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Below Base Style','%DeepSee'), action:'drill', value:zenGet(chart.plotBoxValueStyleNeg),	key:'card-plotBoxValueStyleNeg', text:''};
		break;

	case 'card-ScoreCardColumnList':
		// display list of columns
		title = $$$Text('Columns','%DeepSee');

		// "add" button
		content.headerButtons = [ 
			{key:'card-addColumn', caption:$$$Text('Add Column','%DeepSee'), image:'deepsee/ds2_plus_44_w.png'}
		];

		var list = chart.columns;
		if (!list) {
			chart.columns = [];
			list = chart.columns;
		}

		if (list.length == 0) {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Scorecard has no Columns','%DeepSee'), value:'Press the Add button to add a Column', captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;' };
		}

		// key is column:n
		for (var n = 0; n < list.length; n++) {
			var column = list[n];
			var name = zenGet(column.label);
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column ','%DeepSee') + (n+1), value:name, action:'drill', key:'card-column:'+n, closeButton:true, canDrag:true};
		}
		break;

	case 'card-column':
		// details on one column
		title = $$$Text('Column','%DeepSee');
		var column = chart.columns[keyNo];
	
		content.items[content.items.length] = {display:'info', caption:$$$Text('Column','%DeepSee'), value:'Set the options for a score card column'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Display','%DeepSee'), action:'drill', value:zenGet(column.display),  key:key+'-display:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value','%DeepSee'), edit:'string', action:'drill', value:zenGet(column.dataValue),  key:key+'-dataValue:'+keyNo};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label','%DeepSee'), edit:'string', value:zenGet(column.label),  key:key+'-label:'+keyNo};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Caption','%DeepSee'), edit:'string', value:zenGet(column.cellCaption),  key:key+'-cellCaption:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Header Align','%DeepSee'), edit:'choice', value:zenGet(column.headerAlign),	key:key+'-headerAlign:'+keyNo, valueList:'left,center,right,', displayList:'&#9664;,&#9632;,&#9654;,'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align','%DeepSee'), edit:'choice', value:zenGet(column.align),	key:key+'-align:'+keyNo, valueList:'left,center,right,', displayList:'&#9664;,&#9632;,&#9654;,'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'slider-toggle', value:zenGet(column.width), key:key+'-width:'+keyNo, minValue:0, maxValue:500};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show As','%DeepSee'), action:'drill', value:zenGet(column.showAs),  key:key+'-showAs:'+keyNo};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Summary','%DeepSee'), action:'drill', value:zenGet(column.summary),  key:key+'-summary:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Format','%DeepSee'), edit:'string', action:'drill', value:zenGet(column.format),  key:key+'-format:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Style','%DeepSee'), action:'drill', value:zenGet(column.style),	key:key+'-style:'+keyNo, text:''};

		content.items[content.items.length] = {display:'section', caption:$$$Text('Range and Target','%DeepSee')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Min Value','%DeepSee'), edit:'string', value:zenGet(column.rangeLower),  key:key+'-rangeLower:'+keyNo, action:'drill'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Max Value','%DeepSee'), edit:'string', value:zenGet(column.rangeUpper),  key:key+'-rangeUpper:'+keyNo, action:'drill'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Target Value','%DeepSee'), edit:'string', value:zenGet(column.targetValue),  key:key+'-targetValue:'+keyNo, action:'drill'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Lower','%DeepSee'), edit:'string', value:zenGet(column.thresholdLower),  key:key+'-thresholdLower:'+keyNo, action:'drill'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Upper','%DeepSee'), edit:'string', value:zenGet(column.thresholdUpper),  key:key+'-thresholdUpper:'+keyNo, action:'drill'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Base Value','%DeepSee'), edit:'string', value:zenGet(column.baseValue),  key:key+'-baseValue:'+keyNo,action:'drill'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Value Column','%DeepSee'), edit:'switch', value:zenGet(column.valueColumn),  key:key+'-valueColumn:'+keyNo, hint:$$$Text('Make this the value column','%DeepSee')};

		break;

	case 'card-column-dataValue':
	case 'card-column-targetValue':
	case 'card-column-baseValue':
	case 'card-column-rangeLower':
	case 'card-column-rangeUpper':
	case 'card-column-thresholdLower':
	case 'card-column-thresholdUpper':

		// list of possible data values
		title = $$$Text('Properties','%DeepSee');

		// get propname
		var p = key.toString().split('-');
		var propName = p[p.length-1];

		// get data property list
		var column = chart.columns[keyNo];
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var options = zenPage.fetchOptionList('widget-property',widgetDef.dataSource);
		var list = options.children;
		content.html = navigator.getChooserListHTML(list,key,zenGet(column[propName]));
		break;

	case 'card-column-format':
		title = $$$Text('Numeric Format','%DeepSee');
		var column = chart.columns[keyNo];

		var list = [
			{ caption:$$$Text('###','%DeepSee'), value:'###'},
			{ caption:$$$Text('###.#','%DeepSee'), value:'###.#'},
			{ caption:$$$Text('###.##','%DeepSee'), value:'###.##'},
			{ caption:$$$Text('###.###','%DeepSee'), value:'###.###'},
			{ caption:$$$Text('#,##','%DeepSee'), value:'#,##'},
			{ caption:$$$Text('#,##.#','%DeepSee'), value:'#,##.#'},
			{ caption:$$$Text('#,##.##','%DeepSee'), value:'#,##.##'},
			{ caption:$$$Text('#,##.###','%DeepSee'), value:'#,##.###'},
			{ caption:$$$Text('##.##%','%DeepSee'), value:'##.##%'},
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(column.display),$$$Text('Format','%DeepSee'),$$$Text('Choose a numeric format','%DeepSee'));
		break;

	case 'card-column-display':
		title = $$$Text('Column Display','%DeepSee');
		var column = chart.columns[keyNo];

		var list = [
			{ caption:$$$Text('Item Number','%DeepSee'), value:'itemNo', hint:$$$Text('Show the item number','%DeepSee')},
			{ caption:$$$Text('Label','%DeepSee'), value:'label', hint:$$$Text('Show the item label','%DeepSee')},
			{ caption:$$$Text('Value','%DeepSee'), value:'value', hint:$$$Text('Show the item value','%DeepSee')},
			{ caption:$$$Text('Arrow','%DeepSee'), value:'arrow', hint:$$$Text('Show an arrow based on the value','%DeepSee')},
			{ caption:$$$Text('Lamp','%DeepSee'), value:'lamp', hint:$$$Text('Show a lamp based on the value','%DeepSee')},
			{ caption:$$$Text('Lamp with Value','%DeepSee'), value:'lamp-value', hint:$$$Text('Show a lamp and the value','%DeepSee')},
			{ caption:$$$Text('Trend Line','%DeepSee'), value:'trendLine', hint:$$$Text('Show a trendline based on a comma list of values','%DeepSee')},
			{ caption:$$$Text('Trend Bars','%DeepSee'), value:'trendBars', hint:$$$Text('Show a column chart based on a comma list of values','%DeepSee')},
			{ caption:$$$Text('Plotbox','%DeepSee'), value:'plotBox', hint:$$$Text('Show a plot box based on the value','%DeepSee')},
			{ caption:$$$Text('Hidden','%DeepSee'), value:'hidden', hint:$$$Text('Do not show this column','%DeepSee')}
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(column.display),$$$Text('Display','%DeepSee'),$$$Text('The Display setting defines how to display this item','%DeepSee'));
		break;

	case 'card-column-showAs':
		title = $$$Text('Column Show As','%DeepSee');
		var column = chart.columns[keyNo];
		var list = [
			{ caption:$$$Text('Value','%DeepSee'), value:'value',hint:$$$Text('Base the display on the value of this item.','%DeepSee')},
			{ caption:$$$Text('Conditional','%DeepSee'), value:'conditional',hint:$$$Text('Do not show this item if its value does not exist','%DeepSee')},
			{ caption:$$$Text('Sum','%DeepSee'), value:'sum',hint:$$$Text('Base the display on the sum of all values for this item.','%DeepSee')},
			{ caption:$$$Text('Sum%','%DeepSee'), value:'sum%',hint:$$$Text('Base the display on the percentage of the total for this item.','%DeepSee')},
			{ caption:$$$Text('Target','%DeepSee'), value:'target',hint:$$$Text('Base the display on the target value for this item.','%DeepSee')},
			{ caption:$$$Text('Target %','%DeepSee'), value:'target%',hint:$$$Text('Base the display on the percentage of the target value of this item.','%DeepSee')}
		];

		content.html = navigator.getChooserListHTML(list,key,zenGet(column.showAs),$$$Text('Show As','%DeepSee'),$$$Text('The ShowAs setting defines what value to display for this item','%DeepSee'));
		break;

	case 'card-column-summary':
		title = $$$Text('Column Summary','%DeepSee');
		var column = chart.columns[keyNo];
		var list = [
			{ caption:$$$Text('None','%DeepSee'), value:''},
			{ caption:$$$Text('Sum','%DeepSee'), value:'sum'},
			{ caption:$$$Text('Average','%DeepSee'), value:'avg'},
			{ caption:$$$Text('Min','%DeepSee'), value:'min'},
			{ caption:$$$Text('Max','%DeepSee'), value:'max'},
			{ caption:$$$Text('Value','%DeepSee'), value:'value'}
		];
		content.html = navigator.getChooserListHTML(list,key,zenGet(column.summary),$$$Text('Summary','%DeepSee'),$$$Text('Specify what summary value to show for this column','%DeepSee'));
		break;

		// text styles
	case 'card-titleStyle':
	case 'card-subtitleStyle':
	case 'card-columnHeaderStyle':
	case 'card-labelStyle':
	case 'card-valueLabelStyle':
	case 'card-lampLabelStyle':
	case 'card-cellCaptionStyle':
		title = $$$Text('Style','%DeepSee');

		var style = zenGet(chart[attr]);

		// pull apart style from incoming value
		var info = navigator.parseStyleSVG(style);

		var fill = info['fill'] ? info['fill'] : 'transparent';
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

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:fill,	key:key+'-fill', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke','%DeepSee'), action:'drill', value:stroke,	key:key+'-stroke', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stroke Width','%DeepSee'), edit:'slider-toggle', value:strokeWidth,	key:key+'-stroke-width', minValue:0, maxValue:5, stepSize:0.05};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:key+'-opacity'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:key+'-font-family', style:'font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:key+'-font-size', minValue:4, maxValue:100, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:key+'-textStyle', valueList:'bold,italic,smallCaps,shadow', displayList:'B,I,Cc,S', valueStyle:'font-size:12px;font-family:times new roman;', choiceStyles:'font-weight:900;^font-style:italic;^font-variant:small-caps;^text-shadow:1px 1px 2px #F0F0F0;'};
		break;

	case 'card-backgroundStyle':
	case 'card-trendLineStyle':
	case 'card-trendBarsStyle':
	case 'card-arrowStyle':
	case 'card-plotBoxStyle':
	case 'card-plotBoxValueStyle':
	case 'card-plotBoxValueStyleNeg':
	case 'card-plotBoxLowerStyle':
	case 'card-plotBoxMidStyle':
	case 'card-targetLineStyle':

	case 'card-stripeStyle':
	case 'card-gridStyle':
	case 'card-titleBoxStyle':
	case 'card-lampColor':
	case 'card-lampColorNeg':
	case 'card-column-style':
		title = $$$Text('Style','%DeepSee');
		// pull apart style
		if (key=='card-column-style') {
			var style = chart.columns[keyNo].style;
		}
		else {
			var style = zenGet(chart[attr]);
		}
		var info = navigator.parseStyleSVG(style);

		var fill = info['fill'] ? info['fill'] : 'transparent';
		var stroke = info['stroke'] ? info['stroke'] : 'none';
		var strokeWidth = zenGet(info['stroke-width']);
		var opacity = zenGet(info['opacity']);
		var strokeDashArray = info['stroke-dasharray'];
		switch (strokeDashArray) {
		case '3,3':
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
		var k2 = '';
		if (key=='card-column-style') {
			k2 = ':' + keyNo;
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Fill','%DeepSee'), action:'drill', value:fill,	key:key+'-fill'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fill+';', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:key+'-opacity'+k2};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line','%DeepSee'), action:'drill', value:'',	key:key+'-stroke'+k2, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Width','%DeepSee'), edit:'slider-toggle', value:strokeWidth,	key:key+'-stroke-width'+k2, minValue:0, maxValue:25, stepSize:0.25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Style','%DeepSee'), edit:'choice', value:strokeDashArray,	key:key+'-stroke-dasharray'+k2, valueList:'solid,dashed,dotted', displayList:'solid,dashed,dotted'};
		break;

	case 'card-backgroundStyle-fill':
	case 'card-backgroundStyle-stroke':
	case 'card-titleStyle-fill':
	case 'card-titleStyle-stroke':
	case 'card-subtitleStyle-fill':
	case 'card-subtitleStyle-stroke':
	case 'card-columnHeaderStyle-fill':
	case 'card-columnHeaderStyle-stroke':
	case 'card-labelStyle-fill':
	case 'card-labelStyle-stroke':
	case 'card-valueLabelStyle-fill':
	case 'card-valueLabelStyle-stroke':
	case 'card-cellCaptionStyle-fill':
	case 'card-cellCaptionStyle-stroke':
	case 'card-lampLabelStyle-fill':
	case 'card-lampLabelStyle-stroke':

	case 'card-trendLineStyle-fill':
	case 'card-trendLineStyle-stroke':
	case 'card-trendBarsStyle-fill':
	case 'card-trendBarsStyle-stroke':
	case 'card-arrowStyle-fill':
	case 'card-arrowStyle-stroke':

	case 'card-lampColor-fill':
	case 'card-lampColorNeg-fill':

	case 'card-plotBoxStyle-fill':
	case 'card-plotBoxStyle-stroke':
	case 'card-plotBoxValueStyle-fill':
	case 'card-plotBoxValueStyle-stroke':
	case 'card-plotBoxValueStyleNeg-fill':
	case 'card-plotBoxValueStyleNeg-stroke':
	case 'card-plotBoxLowerStyle-fill':
	case 'card-plotBoxLowerStyle-stroke':
	case 'card-plotBoxMidStyle-fill':
	case 'card-plotBoxMidStyle-stroke':
	case 'card-targetLineStyle-fill':
	case 'card-targetLineStyle-stroke':

	case 'card-gridStyle-fill':
	case 'card-gridStyle-stroke':
	case 'card-stripeStyle-fill':
	case 'card-stripeStyle-stroke':
	case 'card-titleBoxStyle-fill':
	case 'card-titleBoxStyle-stroke':

	case 'card-column-style-fill':
	case 'card-column-style-stroke':
		title = $$$Text('Color','%DeepSee');
		var k2 = (keyNo === '') ? '' : ':' + keyNo;

		// choose a color
		content.html = navigator.getColorChooserHTML(attr+k2,value,'svg');
		break;

	case 'card-titleStyle-font-family':
	case 'card-subtitleStyle-font-family':
	case 'card-columnHeaderStyle-font-family':
	case 'card-labelStyle-font-family':
	case 'card-valueLabelStyle-font-family':
	case 'card-cellCaptionStyle-font-family':
	case 'card-lampLabelStyle-font-family':
		title = $$$Text('Font','%DeepSee');
		var k2 = (keyNo === '') ? '' : ':' + keyNo;
		content.html = navigator.getFontChooserHTML(attr+k2,value);
		break;
	}

	content.title = title;
	return content;
}

/// This is called when a list within the navigator is rearranged.
/// <var>key</var> is the key for the item and <var>swap</var> indicates what items to rearrange.
/// <var>final</var> is true if this is the final value (controls such as a slider
/// may provide intermediate values as well while the user is actively dragging it).
ClientMethod scorecardDataArrange(navigator, chart, key, swap, final) [ Language = javascript ]
{
	// remember original list
	if (!this._oldList) {
		this._oldList = chart.columns;
	}

	var newList = [];
	for (var n = 0; n < this._oldList.length; n++) {
		newList[n] = this._oldList[n];
	}

	// swap items
	var x = newList[swap.oldPosition];
	newList[swap.oldPosition] = newList[swap.newPosition];
	newList[swap.newPosition] = x;

	chart.columns = newList;
	chart.render();

	if (final) {
		delete this._oldList;
	}
}

/// Button clicked in navigator header.
ClientMethod scorecardHeaderButtonClick(navigator, chart, key) [ Language = javascript ]
{
	switch(key) {
	case 'card-addColumn':
		var column = zenPage.createComponentNS("http://www.intersystems.com/deepsee",'scoreCardColumn');
		column.parent = chart;
		chart.columns[chart.columns.length] = column;
		navigator.refreshTopSheet();
		break;
	default:
		break;
	}
}

/// Button clicked in navigator close button.
ClientMethod scorecardCloseButtonClick(navigator, chart, key) [ Language = javascript ]
{
	var t = key.toString().split(':');
	switch(t[0]) {
	case 'card-column':
		if (confirm('Do you wish to remove this column?')) {
			var columnNo = parseInt(t[1]);
			chart.columns.splice(columnNo,1);
			chart.render();
			navigator.refreshTopSheet();
		}
		break;
	default:
		break;
	}
}

/// This is called when a data value within the navigator is changed.
/// <var>key</var> is the key for the item and <var>value</var> is the new value.
/// <var>final</var> is true if this is the final value (controls such as a slider
/// may provide intermediate values as well while the user is actively dragging it).
ClientMethod scorecardDataChange(navigator, svg, chart, key, value, final) [ Language = javascript ]
{
	// key may take the form <item>:keyNo
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// pull apart key
	var t = key.toString().split('-');
	var attr = t[1];

	var object = chart;	

	// check if we are referring to a column
	if (attr == 'column') {
		t.splice(0,1);
		var attr = t[1];
		object = chart.columns[keyNo];
	}

	// apply change to chart
	switch (attr) {
	case 'seriesCount':
	case 'seriesSize':
		if (final) {
			this[attr] = parseInt(value);
			chart.setProperty(attr,value);
			this.updateChartData();
		}
		break;

	case 'width':
	case 'height':
		if (object._type=='scoreCardColumn') {
			object.setProperty(attr,value);
			chart.render();
		}
		else {
			zen('svg').setProperty(attr,value);
			chart.setProperty(attr,value);
		}
		break;


	case 'title':
	case 'subtitle':
	case 'seriesCount':
	case 'seriesSize':
	case 'cardSize':
	default:
		object.setProperty(attr,value);
		if (object._type=='scoreCardColumn') {
			chart.render();
		}
		break;

	case 'titleImageStyle':
	case 'backgroundStyle':
	case 'stripeStyle':
	case 'gridStyle':
	case 'titleStyle':
	case 'subtitleStyle':
	case 'columnHeaderStyle':
	case 'labelStyle':
	case 'valueLabelStyle':
	case 'lampLabelStyle':
	case 'cellCaptionStyle':

	case 'trendLineStyle':
	case 'trendBarsStyle':
	case 'arrowStyle':
	case 'plotBoxStyle':
	case 'plotBoxValueStyle':
	case 'plotBoxValueStyleNeg':
	case 'plotBoxLowerStyle':
	case 'plotBoxMidStyle':
	case 'targetLineStyle':
	case 'titleBoxStyle':
	case 'style':
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
				break;
			case 'stroke-dasharray':
				switch (value) {
				case 'dotted':
					value = '3,3';
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
			style = navigator.convertCSSToText(info);
			object.setProperty(attr,style);
			if (object._type=='scoreCardColumn') {
				chart.render();
			}

			// make sure navigator shows current value
			var spec = navigator.getParentSpec();
			spec.value = style;
		}
		break;

	case 'lampColor':
	case 'lampColorNeg':
		chart.setProperty(attr,value);
		break;

	case 'seriesDetail':
		t.splice(0,1);
		var styleProp = t.join('-');
		switch (styleProp) {
		case 'fill':
			var seriesColors = this.parseColorList(zenGet(chart.seriesColorsOverride));
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
			// !!! this.updateChartData();
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
		break;

	}
}

}
