/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility class supplies the methods needed to control a pivotTable using a navigator component.
Class %DeepSee.Component.PivotContent [ Abstract, System = 3 ]
{

/// Return an object describing what to display for this level.
ClientMethod pivotTableGetContentForLevel(navigator, pivot, level, key, value) [ Language = javascript ]
{
	var title = $$$Text('Pivot Table Options','%DeepSee');
	var content = { title: title, items:[] };
	var widgetDef = this.getDefinition(); // JSL4483

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
	case 'pivot-PivotSettings':
		// root
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Size &amp; Appearance','%DeepSee'), action:'drill', key:'pivot-PivotTableSize'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Colors &amp; Style','%DeepSee'), action:'drill', key:'pivot-PivotTableColors'};
		break;

	case 'pivot-PivotTableSize':
		title = $$$Text('Size and Appearance','%DeepSee');
		
		// +DTB124 - create localized labels for the drill control
		var aggregateLabels = {'sum':$$$Text('Sum','%DeepSee'),
								'count':$$$Text('Count','%DeepSee'),
								'avg':$$$Text('Average','%DeepSee'),
								'min':$$$Text('Min','%DeepSee'),
								'max':$$$Text('Max','%DeepSee'),
								'pct':$$$Text('Percentage','%DeepSee')};
		// -DTB124
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Width','%DeepSee'), edit:'string', value:zenGet(pivot.cellWidth),  key:'pivot-cellWidth'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Height','%DeepSee'), edit:'string', value:zenGet(pivot.cellHeight),  key:'pivot-cellHeight'};

		content.items[content.items.length] = {display:'section', caption:$$$Text('Rows','%DeepSee')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Empty','%DeepSee'), edit:'switch', value:zenGet(pivot.showEmptyRows),  key:'pivot-showEmptyRows'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Span Labels','%DeepSee'), edit:'switch', value:zenGet(pivot.rowLabelSpan),  key:'pivot-rowLabelSpan'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Totals','%DeepSee'), edit:'switch', value:zenGet(pivot.rowTotals),  key:'pivot-rowTotals'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Summary','%DeepSee'), action:'drill', value:aggregateLabels[zenGet(pivot.rowTotalAgg)],  key:'pivot-rowTotalAgg'};			// DTB124 - show value from localized list
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Sum Over','%DeepSee'), edit:'choice', value:zenGet(pivot.rowTotalSource),  key:'pivot-rowTotalSource', valueList:'page,all', displayList:$$$Text('Page,All Rows','%DeepSee')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Caption','%DeepSee'), edit:'switch', value:zenGet(pivot.showRowCaption),  key:'pivot-showRowCaption'};
		
		content.items[content.items.length] = {display:'section', caption:$$$Text('Columns','%DeepSee')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Empty','%DeepSee'), edit:'switch', value:zenGet(pivot.showEmptyColumns),  key:'pivot-showEmptyColumns'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Span Labels','%DeepSee'), edit:'switch', value:zenGet(pivot.columnLabelSpan),  key:'pivot-columnLabelSpan'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Totals','%DeepSee'), edit:'switch', value:zenGet(pivot.columnTotals),  key:'pivot-columnTotals'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Summary','%DeepSee'), action:'drill', value:aggregateLabels[zenGet(pivot.columnTotalAgg)],  key:'pivot-columnTotalAgg'};	// DTB124 - show value from localized list
		break;

	case 'pivot-rowTotalAgg':
	case 'pivot-columnTotalAgg':
		title = $$$Text('Summary','%DeepSee');

		var list = [
			{ caption:$$$Text('Sum','%DeepSee'), value:'sum', hint:$$$Text('Show the sum of the values','%DeepSee')},
			{ caption:$$$Text('Count','%DeepSee'), value:'count', hint:$$$Text('Show the number of values','%DeepSee')},
			{ caption:$$$Text('Average','%DeepSee'), value:'avg', hint:$$$Text('Show the average of the values','%DeepSee')},
			{ caption:$$$Text('Min','%DeepSee'), value:'min', hint:$$$Text('Show the smallest of the values','%DeepSee')},
			{ caption:$$$Text('Max','%DeepSee'), value:'max', hint:$$$Text('Show the largest of the values','%DeepSee')},
			{ caption:$$$Text('Percentage','%DeepSee'), value:'pct', hint:$$$Text('Show the percentage total of the values','%DeepSee')},
		];
		content.html = navigator.getChooserListHTML(list,key,zenGet(pivot[attr]),$$$Text('Summary','%DeepSee'),$$$Text('The Summary setting defines how to display row and column totals','%DeepSee'));
		break;

	case 'pivot-PivotTableColors':
		title = $$$Text('Colors and Style','%DeepSee');
		var which = key; // JSL4483
		var idx = ''; // JSL4483
		var background = this.backgroundColor; // JSL4483
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Style','%DeepSee'), action:'drill', value:zenGet(pivot.cellStyle),	key:'pivot-cellStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Style','%DeepSee'), action:'drill', value:zenGet(pivot.rowHeaderStyle),	key:'pivot-rowHeaderStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Style','%DeepSee'), action:'drill', value:zenGet(pivot.columnHeaderStyle),	key:'pivot-columnHeaderStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripes','%DeepSee'), edit:'switch', value:zenGet(pivot.showZebra),  key:'pivot-showZebra'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripe Style','%DeepSee'), action:'drill', value:zenGet(pivot.evenRowStyle),	key:'pivot-evenRowStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:'pivot-table-background'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'}; // JSL4483
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:this.opacity,	key:'pivot-table-opacity'+idx, minValue:0, maxValue:1}; // JSL4483
		break;

		// text styles
	case 'pivot-evenRowStyle':
	case 'pivot-rowHeaderStyle':
	case 'pivot-columnHeaderStyle':
	case 'pivot-cellStyle':
		title = $$$Text('Style','%DeepSee');

		var style = zenGet(pivot[attr]);
		var info = navigator.parseStyle(style);
		var color = info.color;
		var background = info.backgroundColor;
		var fontFamily = info.fontFamily;
		var fontSize = info.fontSize;
		var align = zenGet(info.textAlign);
		
		var fs = [];
		if (info.bold) { fs[fs.length] = 'bold'; }
		if (info.underline) { fs[fs.length] = 'underline'; }
		if (info.italic) { fs[fs.length] = 'italic'; }
		if (info.smallCaps) { fs[fs.length] = 'smallCaps'; }
		if (info.shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');
		var opacity = zenGet(info.opacity);
		opacity = opacity === '' ? 1.0 : opacity;
		var which = key;
		var idx = '';

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:'',	key:which+'-color'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:which+'-background'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:'',	key:which+'-opacity'+idx}; // JSL4483
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:which+'-font-family'+idx, valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size'+idx, minValue:2, maxValue:75, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:which+'-textStyle'+idx, valueList:'bold,italic,underline,smallCaps,shadow', displayList:'B,I,U,Cc,S', valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^text-decoration:underline;^font-variant:small-caps;^text-shadow:1px 1px 2px #F0F0F0;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align','%DeepSee'), edit:'choice', value:align,	key:which+'-text-align'+idx, valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Padding','%DeepSee'), edit:'slider-toggle', value:zenGet(info.padding),	key:which+'-padding'+idx, minValue:0, maxValue:25};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'slider-toggle', value:zenGet(info.width),	key:which+'-width'+idx, minValue:0, maxValue:1200};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%DeepSee'), edit:'slider-toggle', value:zenGet(info.height),	key:which+'-height'+idx, minValue:0, maxValue:250};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider-toggle', value:opacity,		key:which+'-opacity'+idx, minValue:0, maxValue:1};
		break;

	case 'pivot-evenRowStyle-color':
	case 'pivot-rowHeaderStyle-color':
	case 'pivot-columnHeaderStyle-color':
	case 'pivot-cellStyle-color':
		// choose a color
		var t = key.toString().split('-');
		var which = t[1];
		title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'pivot-evenRowStyle-background':
	case 'pivot-rowHeaderStyle-background':
	case 'pivot-columnHeaderStyle-background':
	case 'pivot-cellStyle-background':
		// choose a color
		var t = key.toString().split('-');
		var which = t[1];
		title = $$$Text('Background','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;
	case 'pivot-table-background':
		// choose a color
		var t = key.toString().split('-');
		var which = t[1];
		title = $$$Text('Background','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;
	case 'pivot-evenRowStyle-font-family':
	case 'pivot-rowHeaderStyle-font-family':
	case 'pivot-columnHeaderStyle-font-family':
	case 'pivot-cellStyle-font-family':
		// choose a font
		var t = key.toString().split('-');
		var which = t[1];
		title = $$$Text('Font','%DeepSee');

		content.html = navigator.getFontChooserHTML(which+'-font-family',value);
		break;
	}

	content.title = title;
	return content;
}

/// This is called when a list within the navigator is rearranged.
/// <var>key</var> is the key for the item and <var>swap</var> indicates what items to rearrange.
/// <var>final</var> is true if this is the final value (controls such as a slider
/// may provide intermediate values as well while the user is actively dragging it).
ClientMethod pivotTableDataArrange(navigator, pivot, key, swap, final) [ Language = javascript ]
{
}

/// Button clicked in navigator header.
ClientMethod pivotTableHeaderButtonClick(navigator, pivot, key) [ Language = javascript ]
{
	switch(key) {
	default:
		break;
	}
}

/// Button clicked in navigator close button.
ClientMethod pivotTableCloseButtonClick(navigator, pivot, key) [ Language = javascript ]
{
}

/// This is called when a data value within the navigator is changed.
/// <var>key</var> is the key for the item and <var>value</var> is the new value.
/// <var>final</var> is true if this is the final value (controls such as a slider
/// may provide intermediate values as well while the user is actively dragging it).
ClientMethod pivotTableDataChange(navigator, pivot, key, value, final) [ Language = javascript ]
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
	t.splice(0,1);
	var attr = t[0];

	t.splice(0,1);
	var k2 = t.join('-');

	var object = pivot;	

	//console.log('attr='+attr+' k2='+k2+' value='+value);
	// apply change to pivot
	switch (attr) {

	case 'showZebra':
	case 'showRowCaption':
	case 'rowTotals':
	case 'columnTotals':
	case 'rowTotalAgg':
	case 'rowTotalSource':
	case 'columnTotalAgg':
	case 'cellWidth':
	case 'cellHeight':
	case 'showEmptyRows':
	case 'showEmptyColumns':
	case 'rowLabelSpan':
	case 'columnLabelSpan':
	default:
		object.setProperty(attr,value);
		if (final) {
			// force update
			object.executeQuery(true);
		}
		break;

	case 'table':
		switch (k2) {
			case 'background':
				var dragGroup = document.getElementById(this.id);
				dragGroup.style.backgroundColor = value;
				this.setProperty('backgroundColor', value);
				break;
			case 'opacity': // JSL4483
				this.opacity = value;
				if (value < 1.0) {
					this.setProperty('opacity', value);
					this.setBkgOpacity(value);
				} else {
				}
				break;
				
		}
		break;
	case 'evenRowStyle':
	case 'rowHeaderStyle':
	case 'columnHeaderStyle':
	case 'cellStyle':
		var style = zenGet(object[attr]);
		switch(k2) {
		case 'color':
		case 'background':
		case 'font-family':
		case 'opacity':
		case 'displayed':
		case 'text-align':
			style = navigator.setStyleIntoCSS(style,k2,value);
			break;
		case 'textStyle':
			var styleValues = {};
			var cv = value.toString().split(',');
			for (var n = 0; n < cv.length; n++) {
				styleValues[cv[n]] = true;
			}
			var list = ['bold','underline','italic','smallCaps','shadow'];
			for (var n = 0; n < list.length; n++) {
				style = navigator.setStyleIntoCSS(style,list[n],styleValues[list[n]]?true:false);
			}
			break;
		case 'border-radius':
		case 'font-size':
		case 'padding':
		case 'margin':
		case 'top':
		case 'left':
		case 'height':
		case 'width':
			value = value!=='' ? value+'px' : value;
			style = navigator.setStyleIntoCSS(zenGet(style),k2,value);
			break;
		}
		object.setProperty(attr,style);
		if (final) {
			// force update
			object.executeQuery(true);
		}
		break;
	}
}

}
