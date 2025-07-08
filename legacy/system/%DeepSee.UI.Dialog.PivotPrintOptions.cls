/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user change the print properties for a DeepSee pivot table.
Class %DeepSee.UI.Dialog.PivotPrintOptions Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// "table", "chart", or "dashboard".
Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "table" ];

Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property units As %ZEN.Datatype.string;

Property columnCount As %ZEN.Datatype.integer(ZENURL = "COLUMNCOUNT");

Property rowTotals As %ZEN.Datatype.boolean(ZENURL = "ROWTOTALS");

Property columnTotals As %ZEN.Datatype.boolean(ZENURL = "COLUMNTOTALS");

Property rowHeaderStyle As %ZEN.Datatype.string(ZENURL = "ROWSTYLE");

Property columnHeaderStyle As %ZEN.Datatype.string(ZENURL = "COLUMNSTYLE");

Property dataCellStyle As %ZEN.Datatype.string(ZENURL = "CELLSTYLE");

Property cellWidth As %ZEN.Datatype.string(ZENURL = "CELLWIDTH");

Property cellHeight As %ZEN.Datatype.string(ZENURL = "CELLHEIGHT");

Property showZebra As %ZEN.Datatype.boolean(ZENURL = "ZEBRA");

Property showRowCaption As %ZEN.Datatype.boolean(ZENURL = "ROWCAPTION");

/// Title to display when pivot is printed.
Property printTitle As %ZEN.Datatype.string(MAXLEN = 2000, ZENURL = "TITLE");

/// Subtitle to display when pivot is printed.
Property printSubtitle As %ZEN.Datatype.string(MAXLEN = 2000, ZENURL = "SUBTITLE");

/// Display Subtitle when pivot is printed.
Property printSubtitleOn As %ZEN.Datatype.string(ZENURL = "SUBTITLEON") [ InitialExpression = "on" ];

/// Display User when pivot is printed.
Property showUser As %ZEN.Datatype.string(ZENURL = "SHOWUSER") [ InitialExpression = "off" ];

/// Page size when pivot is printed. This takes the form "8.5x11 in" (w x h).
Property printPageSize As %ZEN.Datatype.string(ZENURL = "PAGESIZE");

/// Orientation when pivot is printed.
Property printOrientation As %ZEN.Datatype.string(ZENURL = "ORIENTATION") [ InitialExpression = "portrait" ];

/// Page top margin when pivot is printed. This is in the same units as the page size.
Property printMarginTop As %ZEN.Datatype.float(ZENURL = "MARGINTOP");

/// Page left margin when pivot is printed. This is in the same units as the page size.
Property printMarginLeft As %ZEN.Datatype.float(ZENURL = "MARGINLEFT");

/// Page right margin when pivot is printed. This is in the same units as the page size.
Property printMarginRight As %ZEN.Datatype.float(ZENURL = "MARGINRIGHT");

/// Page bottom margin when pivot is printed. This is in the same units as the page size.
Property printMarginBottom As %ZEN.Datatype.float(ZENURL = "MARGINBOTTOM");

/// Width of row labels when the pivot is printed. This is in the same units as the page size.
Property printLabelWidth As %ZEN.Datatype.float(ZENURL = "PRINTLABELWIDTH");

/// Width of data cells when the pivot is printed. This is in the same units as the page size.
Property printCellWidth As %ZEN.Datatype.float(ZENURL = "PRINTCELLWIDTH");

/// Page top margin when pivot is printed. This is in the same units as the page size.
Property chartMarginTop As %ZEN.Datatype.float(ZENURL = "CMARGINTOP");

/// Page left margin when pivot is printed. This is in the same units as the page size.
Property chartMarginLeft As %ZEN.Datatype.float(ZENURL = "CMARGINLEFT");

/// Page right margin when pivot is printed. This is in the same units as the page size.
Property chartMarginRight As %ZEN.Datatype.float(ZENURL = "CMARGINRIGHT");

/// Page bottom margin when pivot is printed. This is in the same units as the page size.
Property chartMarginBottom As %ZEN.Datatype.float(ZENURL = "CMARGINBOTTOM");

/// max rows to export to PDF
Property maxRows As %ZEN.Datatype.integer(ZENURL = "MAXROWS");

/// Table borders
Property borderLeftCell As %ZEN.Datatype.string(ZENURL = "BORDERLEFTCELL");

Property borderRightCell As %ZEN.Datatype.string(ZENURL = "BORDERRIGHTCELL");

Property borderTopCell As %ZEN.Datatype.string(ZENURL = "BORDERTOPCELL");

Property borderBottomCell As %ZEN.Datatype.string(ZENURL = "BORDERBOTTOMCELL");

Property fontFamilyCell As %ZEN.Datatype.string(ZENURL = "FONTFAMILYCELL");

Property fontSizeCell As %ZEN.Datatype.string(ZENURL = "FONTSIZECELL");

Property borderLeftCol As %ZEN.Datatype.string(ZENURL = "BORDERLEFTCOL");

Property borderRightCol As %ZEN.Datatype.string(ZENURL = "BORDERRIGHTCOL");

Property borderTopCol As %ZEN.Datatype.string(ZENURL = "BORDERTOPCOL");

Property borderBottomCol As %ZEN.Datatype.string(ZENURL = "BORDERBOTTOMCOL");

Property fontFamilyCol As %ZEN.Datatype.string(ZENURL = "FONTFAMILYCOL");

Property fontSizeCol As %ZEN.Datatype.string(ZENURL = "FONTSIZECOL");

Property borderLeftRow As %ZEN.Datatype.string(ZENURL = "BORDERLEFTROW");

Property borderRightRow As %ZEN.Datatype.string(ZENURL = "BORDERRIGHTROW");

Property borderTopRow As %ZEN.Datatype.string(ZENURL = "BORDERTOPROW");

Property borderBottomRow As %ZEN.Datatype.string(ZENURL = "BORDERBOTTOMROW");

Property fontFamilyRow As %ZEN.Datatype.string(ZENURL = "FONTFAMILYROW");

Property fontSizeRow As %ZEN.Datatype.string(ZENURL = "FONTSIZEROW");

/// showFilters
Property showFilters As %ZEN.Datatype.string(ZENURL = "SHOWFILTERS") [ InitialExpression = "byTable" ];

/// showListingFilters
Property showListingFilters As %ZEN.Datatype.string(ZENURL = "SHOWLISTINGFILTERS") [ InitialExpression = "off" ];

/// showDate
Property showDate As %ZEN.Datatype.string(ZENURL = "SHOWDATE") [ InitialExpression = "off" ];

/// showZebraStripes
Property showZebraStripes As %ZEN.Datatype.string(ZENURL = "SHOWZEBRASTRIPES") [ InitialExpression = "on" ];

/// Font size for listings
Property listingFontSize As %ZEN.Datatype.string(ZENURL = "LISTINGFONTSIZE") [ InitialExpression = "6pt" ];

/// filterRowCount - used in preview
Property filterRowCount As %ZEN.Datatype.integer(ZENURL = "FILTERROWCOUNT");

/// listingFilterRowCount - used in preview
Property listingFilterRowCount As %ZEN.Datatype.integer(ZENURL = "LISTINGFILTERROWCOUNT");

/// filterTableStyle
Property filterTableStyle As %ZEN.Datatype.style(ZENURL = "FILTERTABLESTYLE") [ InitialExpression = "border:1pt solid gray;" ];

/// filterTableCaptionStyle;
Property filterTableCaptionStyle As %ZEN.Datatype.style(ZENURL = "FILTERTABLECAPTIONSTYLE") [ InitialExpression = "border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;" ];

/// filterTableItemStyle;
Property filterTableItemStyle As %ZEN.Datatype.style(ZENURL = "FILTERTABLEITEMSTYLE") [ InitialExpression = "border:none;text-align:left;font-weight:normal;font-size:6pt;" ];

/// nowDisplay
Property nowDisplayFormat As %ZEN.Datatype.string(ZENURL = "NOWDISPLAYFORMAT");

/// List of page size values.
Property pageSizeValues As %ZEN.Datatype.csv;

/// List of page size names.
Property pageSizeNames As %ZEN.Datatype.csv;

/// id of current selected item.
Property selectedItem As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

.zenLabel {
	color: #404040;
	font-size: 11px;
}

select {
	color: #404040;
	font-size: 11px;
}

.checkboxCaption {
	color: #404040;
	font-size: 11px;
}

.radioSetCaption {
	color: #404040;
	font-size: 11px;
}

#preview {
	overflow: hidden;
	background: #808080;
}

div.previewPage {
	position: relative;
	overflow: hidden;
	border: 1px solid #404040;
	background: #FEFEFE;
	box-shadow: 2px 2px 2px #404040;
}

div.previewDoc {
	border: 1px dotted #A0A0FF;
	background: white;
}

table.previewTable {
	border: 1px solid #404040;
	font-family: arial;
	font-size: 4pt;
	color: #404040;
}

table.previewTable td.nub {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.previewTable td.columnHeader {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	overflow: hidden;
}

table.previewTable td.rowHeader {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	font-weight: bold;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	text-align: left;
	vertical-align: middle;
	background: #C0C0C0;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	overflow: hidden;
}

table.previewTable td.cell {
	border-right: 1px solid #404040;
	border-bottom: 1px solid #404040;
	text-align: right;
	padding: 1px;
	padding-right: 2px;
	padding-left: 2px;
	vertical-align: middle;
	overflow: hidden;
}

/* selector: indicates current element */
.previewSelector {
	z-index: 100;
	position: absolute;
	border: 1px dotted #404040;
	width: 100px;
	height: 25px;
	background: none;
}

/* sizing handle for selector */
.previewSizeHandle {
	z-index: 101;
	position: absolute;
	border: 1px solid white;
	border-radius: 2px;
	background: black;
	width: 4px;
	height: 4px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<!-- this provider supplies the print definition -->
<jsonProvider id="printDefinition" OnGetTargetObject="GetPrintDefinition"/>

<hgroup cellVAlign="top">
<navigator id="navigator" 
headerHeight="40"
showSliderValue="true"
 showDisclosure="false"
onarrange="zenPage.dataArrange(key,swap,final);"
onindent="zenPage.dataIndent(key,swap,final);"
onchange="zenPage.dataChange(key,value,final);"
onselect="zenPage.selectItem(key,value,which);"
onbuttonclick="zenPage.headerButtonClick(key);"
onclosebuttonclick="zenPage.closeButtonClick(key);"
ongetcontent="return zenPage.getContentForLevel(level,key,value);"/>
<spacer width="20"/>

<hgroup cellVAlign="top" labelPosition="top">
<vgroup>
<hgroup cellStyle="padding:3px;">
<!--
<radioSet id="ctrlMode" onchange="zenPage.updatePreview();" value="table" valueList="table,chart" displayList="Table Settings,Chart Settings"/>
-->
<!--
<button caption="Add Pivot" controlClass="commandButton" onclick="zenPage.addItem('pivot');"/>
<button caption="Add Chart" controlClass="commandButton" onclick="zenPage.addItem('chart');"/>
<button caption="Add Text" controlClass="commandButton" onclick="zenPage.addItem('text');"/>
<button caption="Add Table" controlClass="commandButton" onclick="zenPage.addItem('table');"/>
-->
</hgroup>
<html id="preview" label="Preview"/>
</vgroup>
</hgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Pivot Print Options")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Change options for pivot table PDF output.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// return options as an object
	var options = {};
	options.printTitle = this.printTitle;
	options.printSubtitle = this.printSubtitle;
	options.printSubtitleOn = this.printSubtitleOn;
	options.showUser = this.showUser;
	options.printPageSize = this.printPageSize;
	options.printOrientation = this.printOrientation;
	options.printMarginTop = this.roundOff(this.printMarginTop,2);
	options.printMarginBottom = this.roundOff(this.printMarginBottom,2);
	options.printMarginLeft = this.roundOff(this.printMarginLeft,2);
	options.printMarginRight = this.roundOff(this.printMarginRight,2);
	options.printLabelWidth = this.roundOff(this.printLabelWidth,0);
	options.printCellWidth = this.roundOff(this.printCellWidth,0);
	// JSL4219
	options.maxRows = this.maxRows;
	// JSL4218
	options.borderLeftCell = this.borderLeftCell;
	options.borderRightCell = this.borderRightCell;
	options.borderTopCell = this.borderTopCell;
	options.borderBottomCell = this.borderBottomCell;
	options.fontFamilyCell = this.fontFamilyCell; // WAL100
	options.fontSizeCell = this.fontSizeCell;     // WAL100
	options.borderLeftCol = this.borderLeftCol;
	options.borderRightCol = this.borderRightCol;
	options.borderTopCol = this.borderTopCol;
	options.borderBottomCol = this.borderBottomCol;
	options.fontFamilyCol = this.fontFamilyCol;  // WAL100
	options.fontSizeCol = this.fontSizeCol;      // WAL100
	options.borderLeftRow = this.borderLeftRow;
	options.borderRightRow = this.borderRightRow;
	options.borderTopRow = this.borderTopRow;
	options.borderBottomRow = this.borderBottomRow;
	options.fontFamilyRow = this.fontFamilyRow;  // WAL100
	options.fontSizeRow = this.fontSizeRow;      // WAL100

	options.showFilters = this.showFilters;
	options.filterTableStyle = this.filterTableStyle;
	options.filterTableCaptionStyle = this.filterTableCaptionStyle;
	options.filterTableItemStyle = this.filterTableItemStyle;
	
	// JSL4308
	options.nowDisplayFormat = this.nowDisplayFormat;
	
	// JSL4250
	options.showListingFilters = this.showListingFilters;
	options.showDate = this.showDate;

	// JSL4279
	options.listingFontSize = this.listingFontSize;
	
	// JSL4256
	options.showZebraStripes = this.showZebraStripes
	
	// not used yet
	//options.chartMarginTop = this.roundOff(this.chartMarginTop,2);
	//options.chartMarginBottom = this.roundOff(this.chartMarginBottom,2);
	//options.chartMarginLeft = this.roundOff(this.chartMarginLeft,2);
	//options.chartMarginRight = this.roundOff(this.chartMarginRight,2);
	return options;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	// compute units
	var printDef = this.getPrintDef();
	var pageSize = printDef ? printDef.pageSize : zenGet(this.printPageSize);
	this.units = pageSize.toString().split(' ')[1];

	// apply values
	this.updatePreview();
}

/// Reset styles.
ClientMethod clearStyles() [ Language = javascript ]
{
	this.updatePreview();
}

/// Key press handler.
ClientMethod keyPress() [ Language = javascript ]
{
	/*
	if (event && event.keyCode == zenENTER) {
		this.updatePreview();
	}
	*/
}

/// Change in page size.
ClientMethod changePageSize() [ Language = javascript ]
{
	var pgSize = this.printPageSize;
	pgSize = (''==pgSize) ? '8.5x11 in' : pgSize;

	// wXh units
	var t = pgSize.toString().split(' ');
	var units = t[1];
	var d = t[0].toString().split('x');

	// change in units?
	if (units != this.units) {
		// change margins
		var list = ['printMarginTop','printMarginBottom','printMarginLeft','printMarginRight','chartMarginTop','chartMarginBottom','chartMarginLeft','chartMarginRight'];
		if (units == 'mm') {
			for (var n = 0; n < list.length; n++) {
				if (this[list[n]]!=='') {
					this[list[n]] = this[list[n]]*25;
				}
			}
		}
		else {
			for (var n = 0; n < list.length; n++) {
				if (this[list[n]]!=='') {
					this[list[n]] = this[list[n]]/25;
				}
			}
		}
		this.units = units;
	}
	this.updatePreview();
}

ClientMethod getPreviewImage() [ Language = javascript ]
{
	this.previewSrc = null;
	if (document.implementation && document.implementation.hasFeature && document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure", "1.1")) {
		var opener = this.getOpener();
		if (opener && opener.zenPage && opener.zenPage.getPreviewImage) {
			// use synchronous mode in our parent to avoid FireFox async issues
			// place try block to catch random IE permission errors!
			try {
				var mode = opener.zenSynchronousMode;
				opener.zenSynchronousMode = true;
				this.previewSrc = opener.zenPage.getPreviewImage();
				opener.zenPopupWindow = null;
				opener.zenSynchronousMode = mode;
				var head = this.previewSrc[3].split(' ');
				var headLen = head.length;
				var srcWidth = 0;
				var srcHeight = 0;
				var srcViewBox = headLen;
				for (var headIdx = 1;headIdx<headLen;headIdx++) {
					var item = head[headIdx];
					if (item.indexOf("width")==0) {
						srcWidth = parseInt(item.substring(7));
						head[headIdx]= 'width="100%"';
					}
					if (item.indexOf("height")==0) {
						srcHeight = parseInt(item.substring(8));
						head[headIdx]= 'height="100%"';
					}
					if (item.indexOf("zoomAndPan")==0) srcViewBox = headIdx;
				}
				head[srcViewBox]='viewBox="0 0 '+srcWidth+' '+srcHeight+'"';
				this.previewSrc[3] = head.join(' ');			
			}
			catch(ex) {
			}
		}
	}
	else {
	}
}

/// Draw contents of preview component.
ClientMethod updatePreview() [ Language = javascript ]
{
	var mode = this.mode;

	// get settings from printDef if present
	var printDef = this.getPrintDef();

	var pgSize = printDef ? printDef.pageSize : this.printPageSize;
	pgSize = (''==pgSize) ? '8.5x11 in' : pgSize;

	// wXh units
	var t = pgSize.toString().split(' ');
	var units = t[1];
	var d = t[0].toString().split('x');

	var pageWidth = parseFloat(d[0]);
	var pageHeight = parseFloat(d[1]);

	var html = new Array();

	var div = zen('preview').getEnclosingDiv();

	// base size of preview on size of page
	var body = zen('body');
	var divBody = body.getEnclosingDiv();
	var pw = divBody.offsetWidth - 320 - 50;
	var ph = divBody.offsetHeight - 63;
	pw = pw<0 ? 0 : pw;
	ph = ph<0 ? 0 : ph;

	var prevWidth = 360;
	if (pw > ph) {
		prevWidth = ph;
	}
	else {
		prevWidth = pw;
	}

	var prevHeight = prevWidth;	// keep square!
	div.style.width = prevWidth + 'px';
	div.style.height = prevHeight + 'px';

	var showZebra = true;

	// sizes in actual units
	var marginTop = parseFloat(printDef ? printDef.marginTop : this.printMarginTop);
	var marginBottom = parseFloat(printDef ? printDef.marginBottom : this.printMarginBottom);
	var marginRight = parseFloat(printDef ? printDef.marginRight : this.printMarginRight);
	var marginLeft = parseFloat(printDef ? printDef.marginLeft : this.printMarginLeft);
	var cellHeight = 0.5;
	var cellWidth = parseFloat(this.printCellWidth);
	var headerWidth = parseFloat(this.printLabelWidth);

	marginTop = isNaN(marginTop) ? 1 : marginTop;
	marginBottom = isNaN(marginBottom) ? 1 : marginBottom;
	marginRight = isNaN(marginRight) ? 0.5 : marginRight;
	marginLeft = isNaN(marginLeft) ? 0.5 : marginLeft;
	cellWidth = isNaN(cellWidth) ? 0.5 : cellWidth;
	headerWidth = isNaN(headerWidth) ? 1 : headerWidth;

	var orient = printDef ? printDef.orientation : this.printOrientation;
	if (orient == 'landscape') {
		var t = pageWidth;
		pageWidth = pageHeight;
		pageHeight	= t;
	}

	// find ratio of units to local pixels
	if (pageWidth > pageHeight) {
		var w = prevWidth * 0.9;
		var scale = w/pageWidth;
		var h = pageHeight * scale;
	}
	else {
		var h = prevHeight * 0.9;
		var scale = h/pageHeight;
		var w = pageWidth * scale;
	}

	// sizes in pixels
	var pxPageWidth = w;
	var pxPageHeight = h;
	var pxPageMarginTop = (prevHeight - h)/2;
	var pxPageMarginLeft = (prevWidth - w)/2;

	var pxDocWidth = (pageWidth - (marginLeft + marginRight)) * scale;
	var pxDocHeight = (pageHeight - (marginTop + marginBottom)) * scale;
	var pxDocMarginTop = marginTop * scale;
	var pxDocMarginLeft = marginLeft * scale;

	var pxCellWidth = cellWidth * scale;
	var pxCellHeight = cellHeight * scale;
	var pxHeaderWidth = headerWidth * scale;

	var rowCount = 5;
	var colCount = parseInt(this.columnCount) + (this.rowTotals ? 1 : 0);

	var title = printDef ? printDef.title : this.printTitle;
	var subtitle = printDef ? printDef.subtitle : this.printSubtitle;

	html[html.length] = '<div class="previewPage" id="previewPage" style="width:'+pxPageWidth+'px;height:'+pxPageHeight+'px;margin-top:'+pxPageMarginTop+'px;margin-left:'+pxPageMarginLeft+'px;" onclick="zenPage.selectElement(event,\'\');">';
	html[html.length] = '<div class="previewDoc" style="width:'+pxDocWidth+'px;height:'+pxDocHeight+'px;margin-top:'+pxDocMarginTop+'px;margin-left:'+pxDocMarginLeft+'px;">';

	var titleStyle = printDef ? printDef.titleStyle : 'font-size:12px;';
	var subtitleStyle = printDef ? printDef.subtitleStyle : 'font-size:6px;';

	var titleHeight = 0;
	var subtitleHeight = 0;
	var showDate = this.showDate;
	if (showDate == "on") {
		html[html.length] = 'date-time<br/>';
	}
	
	if (title) {
		var titleHTML = '<div style="'+titleStyle+'">' + zenEscapeXML(title) + '</div>';
		html[html.length] = titleHTML;
		var sz = this.computeDivSize(titleHTML);
		titleHeight = sz.height / scale;
	}
	if (subtitle && ('on'==this.printSubtitleOn)) {
		var subtitleHTML = '<div style="'+subtitleStyle+'">' + zenEscapeXML(subtitle) + '</div>';
		html[html.length] = subtitleHTML;
		var sz = this.computeDivSize(subtitleHTML);
		subtitleHeight = sz.height / scale;
	}

	var showUser = this.showUser;
	if (showUser == "on") {
		var userHTML = '<div>' + zenEscapeXML("User") + '</div>';
		html[html.length] = userHTML;
	}
	// show preview of filters
	var showFilters = this.showFilters;
	if (showFilters == "byTable") {
		var filterRowCount = this.filterRowCount;
		var filterColCount = 2;
		if (filterRowCount>0) {
			html[html.length] = '<table class="previewTable" border="0" cellspacing="0">';
			// rows
			for (var r = 0; r < filterRowCount; r++) {
				html[html.length] = '<tr>';
				for (var c = 0; c < filterColCount; c++) {
					if ((c % 2) == 0) {
						html[html.length] = '<td class="rowHeader">';
						html[html.length] = 'nnn';
						html[html.length] = '</td>';
					} else {
						html[html.length] = '<td class="cell">';
						html[html.length] = 'fff';
						html[html.length] = '</td>';
						
					}
				}
				html[html.length] = '</tr>';
			}
			html[html.length] = '</table>';
		}
	}

	// show preview of listing filters
	var showListingFilters = this.showListingFilters;
	if (showListingFilters == "on") {
		var listingFilterRowCount = this.listingFilterRowCount;
		var listingFilterColCount = 1;
		html[html.length] = '<table class="previewTable" border="0" cellspacing="0">';
		// rows
		for (var r = 0; r < 2; r++) {
			html[html.length] = '<tr>';
			for (var c = 0; c < listingFilterColCount; c++) {
				html[html.length] = '<td class="cell">';
				html[html.length] = 'lll';
				html[html.length] = '</td>';
			}
			html[html.length] = '</tr>';
		}
		html[html.length] = '</table>';
	}

	// !!! remove other branch
	if (printDef) {
		var printDef = this.getPrintDef();
		if (printDef) {
			// try to render the print definition
			var availSize = { 
				width:pageWidth-(marginLeft+marginRight), 
				height:pageHeight-(marginTop+marginBottom+titleHeight+subtitleHeight)
			};
			html[html.length] = '<div style="position:absolute;">';
			var pos = {y:0,x:0};
			html[html.length] = this.getHTMLForItems('vt','',printDef.items,availSize,scale,pos);
			html[html.length] = '</div>';
		}
	}
	else {
		if (mode=='chart') {
			var chartTop = parseFloat(this.chartMarginTop);
			var chartBottom = parseFloat(this.chartMarginBottom);
			var chartRight = parseFloat(this.chartMarginRight);
			var chartLeft = parseFloat(this.chartMarginLeft);
			chartTop = marginTop + (isNaN(chartTop) ? 0 : chartTop) + titleHeight + subtitleHeight;
			chartBottom = marginBottom + (isNaN(chartBottom) ? 0 : chartBottom);
			chartRight = marginRight + (isNaN(chartRight) ? 0 : chartRight);
			chartLeft = marginLeft + (isNaN(chartLeft) ? 0 : chartLeft);

			var pxChartWidth = (pageWidth - (chartLeft + chartRight)) * scale;
			var pxChartHeight = (pageHeight - (chartTop + chartBottom)) * scale;
			var pxChartTop = chartTop * scale;
			var pxChartLeft = chartLeft * scale;

			var istyle = 'position:absolute;' + 'top:'+pxChartTop+'px;' + 'left:'+pxChartLeft+'px;' + 
						'width:'+pxChartWidth+'px;' + 'height:'+pxChartHeight+'px;' +
						'border:1px solid #808080;';

			if (!this.previewSrc) this.getPreviewImage();
			if (this.previewSrc) {
				html.push('<div class="previewChart" style="'+istyle+'">');
					for (var idx = 3; idx<this.previewSrc.length; idx++) html.push(this.previewSrc[idx]);
				html.push('</div>');
			}
			else {
				html.push('<image class="previewChart" src="deepsee/chartprint.png" style="'+istyle+'"/>');
			}	
		}
		else {
			html[html.length] = '<table class="previewTable" border="0" cellspacing="0">';
			html[html.length] = '<tr>';

			// headers
			html[html.length] = '<td class="nub">&nbsp;</td>';
			for (var c = 0; c < colCount; c++) {
				if (this.rowTotals && c==colCount-1) {
					var lbl = 'Total';
				}
				else {
					var lbl = 'YYY '+(c+1);
				}
				html[html.length] = '<td class="columnHeader" nowrap="1" style="width:'+pxCellWidth+'px;">' + lbl + '</td>';
			}
			html[html.length] = '</tr>';

			// rows
			for (var r = 0; r < rowCount; r++) {
				html[html.length] = '<tr>';
				html[html.length] = '<td  class="rowHeader" nowrap="1" style="width:'+pxHeaderWidth+'px;"> XXX '+(r+1)+'</td>';
				for (var c = 0; c < colCount; c++) {
					html[html.length] = '<td class="cell">';
					html[html.length] = 'xxx';
					html[html.length] = '</td>';
				}
				html[html.length] = '</tr>';
			}
			html[html.length] = '</table>';
		}
	}

	// div used to indicate current selection
	html[html.length] = '<div id="'+this.makeId('selector')+'" style="display:none;" class="previewSelector" onmousedown="zenPage.selectorMouseDown(event);" >';
	html[html.length] = '</div>';

	// handles for selector
	for (var n = 0; n < 4; n++) {
		html[html.length] = '<div id="'+this.makeId('sizeHandle:'+n)+'" style="display:none;" class="previewSizeHandle" onmousedown="zenPage.sizeHandleMouseDown(event);" >';
		html[html.length] = '</div>';
	}

	html[html.length] = '</div>';
	html[html.length] = '</div>';

	zen('preview').setContent(html.join(''));
}

/// Get the HTML for a list of print items.
ClientMethod getHTMLForItems(dir, parentKey, items, availSize, scale, pos) [ Language = javascript ]
{
	var html = [];
	var itemsInRow = 1;
	if (dir=='hz') {
		itemsInRow = items.length;
	}
	for (var n = 0; n < items.length; n++) {
		var item = items[n];
		var itemKey = (parentKey==='') ? n : (parentKey+','+n);
		var top = parseFloat(item.marginTop);
		var bottom = parseFloat(item.marginBottom);
		var right = parseFloat(item.marginRight);
		var left = parseFloat(item.marginLeft);
		var width = parseFloat(item.width);
		width = isNaN(width) ? availSize.width/itemsInRow : width;
		var height = parseFloat(item.height);
		height = isNaN(height) ? width * 0.5 : height;

		top = (isNaN(top) ? 0 : top)
		bottom = (isNaN(bottom) ? 0 : bottom);
		right = (isNaN(right) ? 0 : right);
		left = (isNaN(left) ? 0 : left);
		
		var pxWidth = Math.round((width - (left + right)) * scale);
		var pxHeight = (height * scale);
		var pxTop = pos.y + Math.round(top * scale);
		var pxLeft = pos.x + Math.round(left * scale);

		var title = zenGet(item.title);
		var titleStyle = zenGet(item.titleStyle);
		var titleHeight = 0;
		var titleHTML = '';
		if (title) {
			titleHTML = '<div style="'+titleStyle+'">' + zenEscapeXML(title) + '</div>';
			var sz = this.computeDivSize(titleHTML);
			titleHeight = sz.height;
		}

		switch(item.type) {
		case 'table':
			html[html.length] = this.getHTMLForItems('hz',itemKey,item.items,(availSize.width - (left + right)),scale,pos);
			break;

		case 'text':
			var tstyle = 'position:absolute;' + 'top:'+pxTop+'px;' + 'left:'+pxLeft+'px;' + 
						'width:'+pxWidth+'px;' + 'font-size:8px;padding:2px;' + 
						zenGet(item.style);

			var div = '<div id="pv_'+itemKey+'" style="'+tstyle+'" onclick="zenPage.selectElement(event,\''+itemKey+'\');">' + titleHTML + zenGet(item.content) +'</div>';
			html[html.length] = div;
			var sz = this.computeDivSize(div);
			pxHeight = (sz.height);
			break;

		case 'pivot':
			var pxCellWidth = 0.5 * scale;
			var pxCellHeight = 0.2 * scale;
			var pxHeaderWidth = 0.2 * scale;
			// !!!
			var rowCount = 5;
			var colCount = parseInt(this.columnCount) + (this.rowTotals ? 1 : 0);
			colCount = 3; // !!!

			var tstyle = 'position:absolute;' + 'top:'+pxTop+'px;' + 'left:'+pxLeft+'px;' + 
						'width:'+pxWidth+'px;';

			pxHeight = (pxCellHeight * (rowCount+1));
			html[html.length] = '<table id="pv_'+itemKey+'" onclick="zenPage.selectElement(event,\''+itemKey+'\');" class="previewTable" style="'+tstyle+'" border="0" cellspacing="0">';
			html[html.length] = '<tr>';
			// headers
			html[html.length] = '<td class="nub">&nbsp;</td>';
			for (var c = 0; c < colCount; c++) {
				if (this.rowTotals && c==colCount-1) {
					var lbl = 'Total';
				}
				else {
					var lbl = 'YYY '+(c+1);
				}
				html[html.length] = '<td class="columnHeader" nowrap="1" style="width:'+pxCellWidth+'px;">' + lbl + '</td>';
			}
			html[html.length] = '</tr>';

			// rows
			for (var r = 0; r < rowCount; r++) {
				html[html.length] = '<tr>';
				html[html.length] = '<td  class="rowHeader" nowrap="1" style="width:'+pxHeaderWidth+'px;"> XXX '+(r+1)+'</td>';
				for (var c = 0; c < colCount; c++) {
					html[html.length] = '<td class="cell">';
					html[html.length] = 'xxx';
					html[html.length] = '</td>';
				}
				html[html.length] = '</tr>';
			}
			html[html.length] = '</table>';
			break;
		case 'chart':
			var tstyle = 'position:absolute;' + 'top:'+pxTop+'px;' + 'left:'+pxLeft+'px;' +
					'height:'+(titleHeight + pxHeight)+'px;' +
					item.style;

			var istyle = 'width:'+pxWidth+'px;' + 'height:'+(pxHeight)+'px;' +
						'border:1px solid #808080;';

			html[html.length] = '<div id="pv_'+itemKey+'" onclick="zenPage.selectElement(event,\''+itemKey+'\');" class="previewChart" src="deepsee/chartprint.png" style="'+tstyle+'">';
			html[html.length] = titleHTML;
			html[html.length] = '<image class="previewChart" src="deepsee/chartprint.png" style="'+istyle+'"/>';
			html[html.length] = '</div>';
			break;
		}

		if (dir=='vt') {
			pos.y += pxHeight + titleHeight + (bottom*scale) + (top*scale);
			pos.x = 0;
		}
		else {
			pos.x += pxWidth + (left*scale) + (right*scale);
		}
	}
	return html.join('');
}

Method %OnAfterCreatePage() As %Status
{
	// list of page sizes
	Set tSC = ##class(%DeepSee.Utils).%GetPaperSizeList(.tPage)

	Set tValueList = ""
	Set tDisplayList = ""
	Set k = $O(tPage(""))
	While (k'="") {
		Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $LG(tPage(k),1) _ "  (" _ $LG(tPage(k),2)_")"
		Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $LG(tPage(k),2)
		Set k = $O(tPage(k))
	}

	Set ..pageSizeValues = tValueList
	Set ..pageSizeNames = tDisplayList

	Set:..printPageSize="" ..printPageSize="8.5x11 in"
	Set:..printOrientation="" ..printOrientation="portrait"

	Set:..showFilters="" ..showFilters="byTable"
	Set:..filterTableStyle="" ..filterTableStyle="border:1pt solid gray;"
	Set:..filterTableCaptionStyle="" ..filterTableCaptionStyle="border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;"
	Set:..filterTableItemStyle="" ..filterTableItemStyle="border:none;text-align:left;font-weight:normal;font-size:6pt;"

	// JSL4250
	Set:..showListingFilters="" ..showListingFilters="off"
	Set:..showDate="" ..showDate="off"
	// JSL4320
	Set:..showUser="" ..showUser="off"
	// JSL4279
	Set:..listingFontSize="" ..listingFontSize="6pt"
	
	// JSL4256
	Set:..showZebraStripes="" ..showZebraStripes="on"
	Set:..printSubtitleOn="" ..printSubtitleOn="on"		// DTB228
	
	Quit $$$OK
}

/// Adjust sizes components on the page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	var body = zen('body');
	var divBody = body.getEnclosingDiv();

	var width = divBody.offsetWidth;
	var height = divBody.offsetHeight;

	var navigator = zen('navigator');
	navigator.setHeight(height - 25);
	this.updatePreview();
}

/// Return an object describing what to display for this level.
ClientMethod getContentForLevel(level, key, value) [ Language = javascript ]
{
	if (key == "filterStyles") {
		var title = $$$Text('Filter Settings');
	} else if (key == "tableSettings") {
		var title = $$$Text('Table Settings');
	} else if (key == "colSettings") {
		var title = $$$Text('Column Settings');
	} else if (key == "rowSettings") {
		var title = $$$Text('Row Settings');
	} else if (key == "cellSettings") {
		var title = $$$Text('Cell Settings');
	} else if (key == "listingSettings") {
		var title = $$$Text('ListingSettings');
	} else {
		var title = $$$Text('Settings');
	}
	var content = { title: title, items:[] };
	var navigator = zen('navigator');
	var printDef = this.getPrintDef();

	// key may take the form <item>:keyNo
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = t[1];

		if (this.selectedItem) {
			keyNo = this.selectedItem;
		}
	}

	var item = null;
	if (printDef) {
		if (keyNo==='') {
			item = printDef;
		}
		else {
			item = this.getLayoutItem(keyNo);
		}
		// remove item-
		if (key.toString().indexOf('item-')==0) {
			var t = key.split('-');
			t.splice(0,1);
			key = t.join('-');
		}
	}

	var pageSize = printDef ? printDef.pageSize : zenGet(this.printPageSize);
	var units = pageSize.toString().split(' ')[1];

	switch (key) {
	case '':
		// root
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Page Setup'), action:'drill', key:'pageSettings'};
		switch(this.mode) {
		case 'dashboard':
			content.items[content.items.length] = {display:'caption', caption:$$$Text('Layout'), action:'drill', key:'pageItems'};
			break;
		case 'table':
			// content.items[content.items.length] = {display:'caption', caption:$$$Text('Pivot Setup'), action:'drill', key:'pivot'};
			break;
		}
		break;

	case 'pageSettings':
		content.title = $$$Text('Page Settings');
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Reset'), action:'select', key:'reset', style:'color:darkblue;'};

		// page size
		var orientation = printDef ? printDef.orientation : zenGet(this.printOrientation);
		var title = printDef ? printDef.title : zenGet(this.printTitle);
		var subtitle = printDef ? printDef.subtitle : zenGet(this.printSubtitle);
		var subtitleOn = printDef ? printDef.printSubtitleOn : zenGet(this.printSubtitleOn);

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Page Size'), action:'drill', value:pageSize, key:'pageSize'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Units'), value:this.units}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Orientation'), edit:'choice', value:orientation, key:'orientation', valueList:'portrait,landscape', displayList:$$$Text('Portrait,Landscape','%DeepSee')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title'), edit:'string', value:title, key:'title'};
		if (printDef) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Style'), action:'drill', value:printDef.titleStyle, key:'titleStyle', text:''};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle'), edit:'string', value:subtitle, key:'subtitle'};
		subtitleOn = ('on'==subtitleOn)?1:0;	// DTB228
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Subtitle'), edit:'switch', value:subtitleOn, key:'printSubtitleOn'};		// DTB137 - use 'switch' to edit
		if (printDef) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Subtitle Style'), action:'drill', value:printDef.subtitleStyle, key:'subtitleStyle',text:''};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Table Settings'), action:'drill', key:'tableSettings', value:'' };		// DTB645 - Turn this back on
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Listing Settings'), action:'drill', key:'listingSettings', value:'' };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Filter Settings'), action:'drill', key:'filterStyles', value:'' };
		// JSL4250
		var showDate = printDef ? printDef.showDate : zenGet(this.showDate);
		showDate = ('on'==showDate)?1:0;	// DTB228
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Date'), edit:'switch', value:showDate, key:'showDate'};		// DTB137 - use 'switch' to edit	
		// JSL4320
		var showUser = printDef ? printDef.showUser : zenGet(this.showUser); // JSL4320
		showUser = ('on'==showUser?1:0);	// DTB228
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show User'), edit:'switch', value:showUser, key:'showUser'};		// DTB137 - use 'switch' to edit	
		
		// margins
		var stepSize = units=='mm' ? 5 : 0.1;
		var maxMgn = units=='mm' ? 200 : 10;

		var marginTop = printDef ? printDef.marginTop : zenGet(this.printMarginTop);
		var marginLeft = printDef ? printDef.marginLeft : zenGet(this.printMarginLeft);
		var marginBottom = printDef ? printDef.marginBottom : zenGet(this.printMarginBottom);
		var marginRight = printDef ? printDef.marginRight : zenGet(this.printMarginRight);
		marginTop = isNaN(marginTop) ? 1 : marginTop;
		marginBottom = isNaN(marginBottom) ? 1 : marginBottom;
		marginRight = isNaN(marginRight) ? 0.5 : marginRight;
		marginLeft = isNaN(marginLeft) ? 0.5 : marginLeft;

		content.items[content.items.length] = {display:'section', caption:$$$Text('Page Margins')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Top'), edit:'stepper-value', value:marginTop,	key:'marginTop', minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Bottom'), edit:'stepper-value', value:marginBottom,	key:'marginBottom', minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Left'), edit:'stepper-value', value:marginLeft,	key:'marginLeft', minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Right'), edit:'stepper-value', value:marginRight,	key:'marginRight', minValue:0, maxValue:maxMgn, stepSize:stepSize};

		break;
	case 'filterStyles':
		var showFilters = printDef ? printDef.showFilters : zenGet(this.showFilters);
		// +DTB377 - Display the current setting
		var showFiltersText = ''
		switch (showFilters) {
			case 'byTable':
				showFiltersText = $$$Text('By Table','%DeepSee');
			break;
			case 'byTitle':
				showFiltersText = $$$Text('By Title','%DeepSee');
			break;
			default:
				showFiltersText = $$$Text('Off','%DeepSee');
			break;
			
		}
		// -DTB377

		var filterTableStyle = printDef ? printDef.filterTableStyle : zenGet(this.filterTableStyle);
		var filterTableCaptionStyle = printDef ? printDef.filterTableCaptionStyle : zenGet(this.filterTableCaptionStyle); 
		var filterTableItemStyle = printDef ? printDef.filterTableItemStyle : zenGet(this.filterTableItemStyle);
		var nowDisplayFormat = printDef ? printDef.nowDisplayFormat : zenGet(this.nowDisplayFormat);
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Filters'), action:'drill', value:showFilters, key:'showFilters', text:showFiltersText};		// DTB377 - Change to drill
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Table Style'), action:'drill', value:filterTableStyle, key:'filterTableStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Header Style'), action:'drill', value:filterTableCaptionStyle, key:'filterTableCaptionStyle', text:''};		// DTB405 - Change label
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Item Style'), action:'drill', value:filterTableItemStyle, key:'filterTableItemStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Display Format for NOW'), edit:'string', value:nowDisplayFormat, key:'nowDisplayFormat' };		
		break;
	case 'listingSettings':
		var showListingFilters = printDef ? printDef.showListingFilters : zenGet(this.showListingFilters);
		showListingFilters = ('on'==showListingFilters)?1:0;		// DTB228
		var showZebraStripes = printDef ? printDef.showZebraStripes : zenGet(this.showZebraStripes);
		showZebraStripes = ('on'==showZebraStripes)?1:0;			// DTB228
		var listingFontSize= printDef ? printDef.listingFontSize : zenGet(this.listingFontSize);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Listing Filters'), edit:'switch', value:showListingFilters, key:'showListingFilters', valueList:'on,off', displayList:$$$Text('On,Off','%DeepSee')};		// DTB137 - use 'switch' to edit		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Zebra Stripes'), edit:'switch', value:showZebraStripes, key:'showZebraStripes', valueList:'on,off', displayList:$$$Text('On,Off','%DeepSee')};				// DTB137 - use 'switch' to edit
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size'), edit:'string', value:listingFontSize, key:'listingFontSize', };		
		break;
	case 'pageSize':
		content.title = $$$Text('Page Size');

		// list of page sizes
		var pgSzVal = this.pageSizeValues.toString().split(',');
		var pgSzName = this.pageSizeNames.toString().split(',');

		var list = [];
		for (var n = 0; n < pgSzVal.length; n++) {
			list[list.length] = { caption:pgSzName[n], value:pgSzVal[n]};
		}
		content.html = navigator.getChooserListHTML(list,key,pageSize);
		break;

	case 'pageItems':
		// list of page items
		content.title = $$$Text('Layout')
		// "add" button
		/*
		content.headerButtons = [ 
			{key:'addItem', caption:'Add Item', image:'deepsee/ds2_plus_44_w.png'}
		];
		*/

		// build graph of all print items with indentation
		content.items = this.getLayoutTree(printDef.items,0);
		break;

	case 'pivot':
		// stand-alone pivot
		content.title = $$$Text('Pivot Settings');
		var cellWidth = parseFloat(this.printCellWidth);
		cellWidth = isNaN(cellWidth) ? '' : cellWidth;

		// units are print units!
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Width'), edit:'slider-toggle', value:cellWidth, key:'cellWidth', minValue:0, maxValue:6, stepSize:0.25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Width'), edit:'string', value:cellWidth, key:'cellWidth'};
		break;

	case 'item':
		content.title = $$$Text('Item');
		if (printDef) {
			var item = this.getLayoutItem(keyNo);
		}
		var stepSize = units=='mm' ? 5 : 0.1;
		var maxMgn = units=='mm' ? 200 : 10;

		// type
		var type = zenGet(item.type);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Type'), action:'drill', value:type,  key:'type:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title'), edit:'string', value:zenGet(item.title),  key:'title:'+keyNo};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Title Style'), 	action:'drill', key:'item-titleStyle:'+keyNo};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width'), edit:'slider-toggle', value:zenGet(item.width),	key:'width:'+keyNo, minValue:0, maxValue:10};

		switch(type) {
		case 'text':
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Content'), edit:'string', value:zenGet(item.content),  key:'content:'+keyNo};
			break;
		case 'chart':
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height'), edit:'slider-toggle', value:zenGet(item.height),	key:'height:'+keyNo, minValue:0, maxValue:10};
			break;
		}
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Style'), 			action:'drill', key:'item-style:'+keyNo};

		content.items[content.items.length] = {display:'section', caption:$$$Text('Margins')};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Top'), edit:'stepper-value', value:zenGet(this.marginTop),	key:'marginTop:'+keyNo, minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Bottom'), edit:'stepper-value', value:zenGet(this.marginBottom),	key:'marginBottom:'+keyNo, minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Left'), edit:'stepper-value', value:zenGet(this.marginLeft),	key:'marginLeft:'+keyNo, minValue:0, maxValue:maxMgn, stepSize:stepSize};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Right'), edit:'stepper-value', value:zenGet(this.marginRight),	key:'marginRight:'+keyNo, minValue:0, maxValue:maxMgn, stepSize:stepSize};
		break;

	case 'tableSettings':
		content.items[content.items.length] = {display:'section', caption:$$$Text('Multiple Page Printing Only','%DeepSee') };		// DTB645 - Communicate that this only applies to non-SVG printing
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Settings'), action:'drill', key:'colSettings', value:'' };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Settings'), action:'drill', key:'cellSettings', value:'' };
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Settings'), action:'drill', key:'rowSettings', value:'' };
		// JSL4219
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Max Rows'), edit:'integer', value:zenGet(this.maxRows), key:'maxRows'};
		break;
	case 'colSettings':
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Left'), edit:'string', value:zenGet(this.borderLeftCol),	key:'borderLeftCol'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Right'), edit:'string', value:zenGet(this.borderRightCol),	key:'borderRightCol'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Top'), edit:'string', value:zenGet(this.borderTopCol),	key:'borderTopCol'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Bottom'), edit:'string', value:zenGet(this.borderBottomCol),	key:'borderBottomCol'};
		// + WAL100 (3)
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font'), action:'drill', value:zenGet(this.fontFamilyCol),	key:'fontFamilyCol'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size'), edit:'slider-toggle', minValue:2, maxValue:75, stepSize:1, value:zenGet(this.fontSizeCol),	key:'fontSizeCol'};
		// - WAL100 (3)
		break;
	case 'cellSettings':
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Left'), edit:'string', value:zenGet(this.borderLeftCell), key:'borderLeftCell'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Right'), edit:'string', value:zenGet(this.borderRightCell),	key:'borderRightCell'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Top'), edit:'string', value:zenGet(this.borderTopCell),	key:'borderTopCell'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Bottom'), edit:'string', value:zenGet(this.borderBottomCell),	key:'borderBottomCell'};
		// + WAL100 (3)
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font'), action:'drill', value:zenGet(this.fontFamilyCell),	key:'fontFamilyCell'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size'), edit:'slider-toggle', minValue:2, maxValue:75, stepSize:1, value:zenGet(this.fontSizeCell),	key:'fontSizeCell'};
		// - WAL100 (3)
		break;
	case 'rowSettings':
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Left'), edit:'string', value:zenGet(this.borderLeftRow),	key:'borderLeftRow'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Right'), edit:'string', value:zenGet(this.borderRightRow),	key:'borderRightRow'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Top'), edit:'string', value:zenGet(this.borderTopRow),	key:'borderTopRow'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Bottom'), edit:'string', value:zenGet(this.borderBottomRow),	key:'borderBottomRow'};
		// + WAL100 (3)
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font'), action:'drill', value:zenGet(this.fontFamilyRow),	key:'fontFamilyRow'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size'), edit:'slider-toggle', minValue:2, maxValue:75, stepSize:1, value:zenGet(this.fontSizeRow),	key:'fontSizeRow'};
		// - WAL100 (3)
		break;
	case 'showFilters':
		// DTB377 - Add a new drill down menu for filter display
		content.title = $$$Text("Show Filters");
		
		list = [];
		list[list.length] = { caption:$$$Text('By Table'), value:'byTable'};
		list[list.length] = { caption:$$$Text('By Title'), value:'byTitle'};
		list[list.length] = { caption:$$$Text('Off'), value:'off'};
		content.html = navigator.getChooserListHTML(list,key,showFilters);
		break;
	case 'style':
	case 'titleStyle':
	case 'subtitleStyle':
	case 'filterTableStyle':
	case 'filterTableCaptionStyle':
	case 'filterTableItemStyle':
		content.title = $$$Text('Style');
		switch (key) {
			case 'filterTableStyle':
				content.title = $$$Text('Table Style');
				break;
			case 'filterTableCaptionStyle':
				content.title = $$$Text('Header Style');		// DTB405 - Change label
			break;
			case 'filterTableItemStyle':
				content.title = $$$Text('Item Style');
			break;
		}
		var which = key;

		var idx = keyNo?(':'+keyNo):'';

		// pull apart style from incoming value
		var style = '';
		if (item) {
			var style = item[key];
		} else {
			var style = this[key];
		}

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
		var fontStyle = fs.join(',');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color'), action:'drill', value:'',	key:which+'-color'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background'), action:'drill', value:'',	key:which+'-background'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font'), action:'drill', value:fontFamily,	key:which+'-font-family'+idx, valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size'+idx, minValue:2, maxValue:75, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style'), edit:'choice-multi', value:fontStyle,	key:which+'-textStyle'+idx, valueList:'bold,italic,underline', displayList:$$$Text('B,I,U','%DeepSee'), valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^text-decoration:underline;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align'), edit:'choice', value:align,	key:which+'-text-align'+idx, valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Padding'), edit:'slider-toggle', value:zenGet(info.padding),	key:which+'-padding'+idx, minValue:0, maxValue:25};
		break;
		
	// + WAL100 (3) -- handle return from font family drill menu
	case 'fontFamilyCol':
	case 'fontFamilyCell':
	case 'fontFamilyRow':
		content.html = navigator.getFontChooserHTML(key,value);
		break;
	// - WAL100 (3)

	case 'style-color':
	case 'titleStyle-color':
	case 'subtitleStyle-color':
	case 'filterTableStyle-color':
	case 'filterTableCaptionStyle-color':
	case 'filterTableItemStyle-color':
		// choose a color
		content.title = $$$Text('Color');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'style-background':
	case 'titleStyle-background':
	case 'subtitleStyle-background':
	case 'filterTableStyle-background':
	case 'filterTableCaptionStyle-background':
	case 'filterTableItemStyle-background':
		// choose a color
		content.title = $$$Text('Background');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'style-font-family':
	case 'titleStyle-font-family':
	case 'subtitleStyle-font-family':
	case 'filterTableStyle-font-family':
	case 'filterTableCaptionStyle-font-family':
	case 'filterTableItemStyle-font-family':		// DTB396 - fix Item Key
	
		content.title = $$$Text('Font');
		// choose a font
		content.html = navigator.getFontChooserHTML(key,value);
		break;
	case 'filterTableStyle-border':
		// when we have a border UI this will be filled in		
		break;		
	}

	
	return content;
}

/// Item selected in navigator.
ClientMethod selectItem(key, value, which) [ Language = javascript ]
{
	var printDef = this.getPrintDef();
	if (which=='drill') {
		var keyNo = '';
		if (key.toString().indexOf(':')>0) {
			var t = key.split(':');
			key = t[0];
			keyNo = t[1];
		}
		switch(key) {
		case 'item':
			this.selectElement('none',keyNo);
			break;
		}
	}
	else if (which=='select') {
		switch(key) {
		case 'reset':
			if (printDef) {
				printDef.title = '';
				printDef.subtitle = '';
				printDef.printSubtitleOn = 'on';		// DTB228
				printDef.showDate = 'off';				// DTB228
				printDef.showListingFilters = 'off';	// DTB228
				printDef.showZebraStripes = 'on';		// DTB228
				printDef.showUser = 'off'; // JSL4320
				printDef.marginTop = '';
				printDef.marginBottom = '';
				printDef.marginLeft = '';
				printDef.marginRight = '';
				// JSL4219
				printDef.maxRows = '';
				// JSL4218
				printDef.borderLeftCell = '';
				printDef.borderRightCell = '';
				printDef.borderTopCell = '';
				printDef.borderBottomCell = '';
				printDef.fontFamilyCell = '';  // WAL100
				printDef.fontSizeCell = '';    // WAL100
				printDef.borderLeftCol = '';
				printDef.borderRightCol = '';
				printDef.borderTopCol = '';
				printDef.borderBottomCol = '';
				printDef.fontFamilyCol = '';   // WAL100
				printDef.fontSizeCol = '';     // WAL100
				printDef.borderLeftRow = '';
				printDef.borderRightRow = '';
				printDef.borderTopRow = '';
				printDef.borderBottomRow = '';
				printDef.fontFamilyRow = '';   // WAL100
				printDef.fontSizeRow = '';     // WAL100
				
				printDef.filterTableStyle = 'border:1pt solid gray;';
				printDef.filterTableCaptionStyle = 'border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;';
				printDef.filterTableItemStyle = 'border:none;text-align:left;font-weight:normal;font-size:6pt;';
			}
			else {
				this.printTitle = '';
				this.printSubtitle = '';
				this.printSubtitleOn = 'on';
				this.showDate = 'off';				// DTB228
				this.showListingFilters = 'off';	// DTB228
				this.showZebraStripes = 'on';		// DTB228
				this.showUser = 'off'; // JSL4320
				this.printMarginTop = '';
				this.printMarginBottom = '';
				this.printMarginLeft = '';
				this.printMarginRight = '';
				this.chartMarginTop = '';
				this.chartMarginBottom = '';
				this.chartMarginLeft = '';
				this.chartMarginRight = '';
				// JSL4219
				this.maxRows = '';
				// JSL4218
				this.borderLeftCell = '';
				this.borderRightCell = '';
				this.borderTopCell = '';
				this.borderBottomCell = '';
				this.fontFamilyCell = '';  // WAL100
				this.fontSizeCell = '';    // WAL100
				this.borderLeftCol = '';
				this.borderRightCol = '';
				this.borderTopCol = '';
				this.borderBottomCol = '';
				this.fontFamilyCol = '';   // WAL100
				this.fontSizeCol = '';     // WAL100
				this.borderLeftRow = '';
				this.borderRightRow = '';
				this.borderTopRow = '';
				this.borderBottomRow = '';
				this.fontFamilyRow = '';   // WAL100
				this.fontSizeRow = '';     // WAL100

				this.filterTableStyle = 'border:1pt solid gray;';
				this.filterTableCaptionStyle = 'border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;';
				this.filterTableItemStyle = 'border:none;text-align:left;font-weight:normal;font-size:6pt';
			}
			this.updatePreview();
			zen('navigator').refreshTopSheet();
			break;
		}
	}
}

/// Button clicked in navigator header.
ClientMethod headerButtonClick(key) [ Language = javascript ]
{
}

/// Button clicked in navigator close button.
ClientMethod closeButtonClick(key) [ Language = javascript ]
{
	var navigator = zen('navigator');
	var printDef = this.getPrintDef();

	var t = key.toString().split(':');

	switch(t[0]) {
	case 'item':
		// find parent
		t.splice(0,1);
		t = t.join(':').split(',');
		var idx = t[t.length-1];
		t.length--;
		var keyNo = t.join(',');
		if (keyNo=='') {
			var item = printDef;
		}
		else {
			var item = this.getLayoutItem(keyNo);
		}
		if (confirm('Do you wish to remove this item?')) {
			item.items.splice(idx,1);

			navigator.refreshTopSheet();
			this.updatePreview();
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
ClientMethod dataChange(key, value, final) [ Language = javascript ]
{
	var navigator = zen('navigator');
	var printDef = this.getPrintDef();

	// key may take the form <item>:keyNo
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = t[1];
		if (this.selectedItem) {
			keyNo = this.selectedItem;
		}
	}

	if (keyNo==='') {
		var item = printDef;
	}
	else {
		var item = this.getLayoutItem(keyNo);
	}

	// key is which-element
	var t = key.toString().split('-');
	var which = '';
	if (t.length>1) {
		which = t[0];
		t.splice(0,1);
	}
	var k2 = t.join('-');
	var style = '';
	switch(which) {
	case 'style':
	case 'titleStyle':
	case 'subtitleStyle':
	case 'filterTableStyle':
	case 'filterTableCaptionStyle':
	case 'filterTableItemStyle':
		style = (item) ? item[which] : this[which];
		break;
	default:
		break;
	}

	switch (k2) {
	case 'title':
	case 'subtitle':
	case 'content':
	case 'height':
	case 'width':
	case 'orientation':
	case 'marginTop':
	case 'marginBottom':
	case 'marginLeft':
	case 'marginRight':
	case 'cellWidth':
		if (item) {
			item[key] = value;
		}
		else {
			// convert key to prop name
			var prop = 'print' + key.charAt(0).toString().toUpperCase() + key.substr(1);
			this[prop] = value;
		}
		if (k2=='cellWidth' && final) {
			navigator.refreshTopSheet();
		}
		this.updatePreview();
		break;

	case 'pageSize':
		if (item) {
			item[key] = value;
		}
		else {
			this.printPageSize = value;
		}
		this.changePageSize();
		break;
	case 'textStyle':
		var styleValues = {};
		var cv = value.toString().split(',');
		for (var n = 0; n < cv.length; n++) {
			styleValues[cv[n]] = true;
		}
		var list = ['bold','underline','italic','shadow'];
		for (var n = 0; n < list.length; n++) {
			style = navigator.setStyleIntoCSS(zenGet(style),list[n],styleValues[list[n]]?true:false);
		}
		break;

	case 'color':
	case 'background':
	case 'font-family':
	case 'opacity':
	case 'displayed':
	case 'text-align':
	case 'border':
		style = navigator.setStyleIntoCSS(zenGet(style),k2,value);
		break;

	case 'border-radius':
	case 'font-size':
	case 'padding':
	case 'margin':
	case 'top':
	case 'left':
	case 'height':
	case 'width':
		value = value!=='' && value.toString().substr(value.length-2)!="pt" ? value+'px' : value;
		style = navigator.setStyleIntoCSS(zenGet(style),k2,value);
		break;
	}

	switch(which) {
	case 'style':
	case 'titleStyle':
	case 'subtitleStyle':
	case 'filterTableStyle':
	case 'filterTableCaptionStyle':
	case 'filterTableItemStyle':
		if (item) {
			item[which] = style;
		} else {
			this[which] = style;

		}
		this.updatePreview();
		break;
	}
	switch (key) {
		case 'printSubtitleOn':			// DTB228
		case 'showZebraStripes':		// DTB228
		case 'showDate':				// DTB228
		case 'showUser':				// DTB228
		case 'showListingFilters': 		// DTB228
			value = (value?'on':'off');	// DTB228 - Convert above values back to on/off
		case 'showFilters':
		case 'listingFontSize':
		case 'borderLeftCell':
		case 'borderRightCell':
		case 'borderTopCell':
		case 'borderBottomCell':
		case 'fontFamilyCell': // WAL100
		case 'fontSizeCell':   // WAL100
		case 'borderLeftCol':
		case 'borderRightCol':
		case 'borderTopCol':
		case 'borderBottomCol':
		case 'fontFamilyCol': // WAL100
		case 'fontSizeCol':   // WAL100
		case 'borderLeftRow':
		case 'borderRightRow':
		case 'borderTopRow':
		case 'borderBottomRow':
		case 'fontFamilyRow': // WAL100
		case 'fontSizeRow':   // WAL100
		case 'maxRows':
		case 'nowDisplayFormat':
			if (item) {
				item[key] = value;
			} else {
				this[key] = value;

			}
			this.updatePreview();
			break;
	}
}

/// Re-indent list of values.
ClientMethod dataIndent(key, swap, final) [ Language = javascript ]
{
	var navigator = zen('navigator');
	var printDef = this.getPrintDef();
	var docView = zen('document');

	// copy tree
	// first time, remember the original layout
	if (!this._originalLayout) {
		this._originalLayout = this.cloneTree(printDef);
	}

	if (!final) {
		// make changes to trialLayout which is a copy of the original layout
		var trialLayout = this.cloneTree(this._originalLayout);

		// build flattened list of all children with indentation
		var flatList = this.getLayoutTree(trialLayout.items,0);

		// find item in original list
		var moveFromSect = flatList[swap.index]._item;

		// find position of items within tree
		var array = [];
		var arrayIdx = [];
		var depth = 0;
		array[depth] = trialLayout.items;
		arrayIdx[depth] = 0;
		var moveFromArray = null;
		var moveFromIndex = -1;
		while (depth>=0) {
			var testSect = array[depth][arrayIdx[depth]];
			if (testSect===moveFromSect) {
				// found it
				moveFromArray = array[depth];
				moveFromIndex = arrayIdx[depth];
				break;
			}
			// next item
			if (testSect.items&&testSect.items.length) {
				depth++;
				array[depth] = testSect.items;
				arrayIdx[depth] = 0;
			}
			else {
				while (depth>=0) {
					arrayIdx[depth]++;
					if (arrayIdx[depth]<array[depth].length) {
						break;
					}
					depth--;
				}
			}
		}
	
		if (moveFromIndex>=0 && moveFromArray) {
			// !!!
			if (moveFromIndex>0 && swap.newIndent > depth) {
				// make this a child of the prior item
				var prior = moveFromArray[moveFromIndex-1];
				if (!prior.items) {
					prior.items = [];
				}
				prior.items[prior.items.length] = moveFromSect;
				moveFromArray.splice(moveFromIndex,1);
			}

			// update view
			printDef.items = trialLayout.items;

			this.updatePreview();
		}
	}

	if (final) {
		// clear out old list
		delete this._originalLayout;
	}
}

/// Rearrange of list of values.
ClientMethod dataArrange(key, swap, final) [ Language = javascript ]
{
	var navigator = zen('navigator');
	var printDef = this.getPrintDef();

	// copy tree
	// first time, remember the original layout
	if (!this._originalLayout) {
		this._originalLayout = this.cloneTree(printDef);
	}

	// !!! select item
	// !!! we have to find the final resting spot of the item!!!
	this.selectedItem = swap.index;

	if (!final) {
		// make changes to trialLayout which is a copy of the original layout
		var trialLayout = this.cloneTree(this._originalLayout);

		// build flattened list of all children with indentation
		var flatList = this.getLayoutTree(trialLayout.items,0);

		// find item in original list
		var moveFromSect = flatList[swap.index]._item;

		// find position of items within tree
		var array = [];
		var arrayIdx = [];
		var depth = 0;
		array[depth] = trialLayout.items;
		arrayIdx[depth] = 0;
		var moveFromArray = null;
		var moveFromIndex = -1;
		while (depth>=0) {
			var testSect = array[depth][arrayIdx[depth]];
			if (testSect===moveFromSect) {
				// found it
				moveFromArray = array[depth];
				moveFromIndex = arrayIdx[depth];
				break;
			}
			// next item
			if (testSect.items&&testSect.items.length) {
				depth++;
				array[depth] = testSect.items;
				arrayIdx[depth] = 0;
			}
			else {
				while (depth>=0) {
					arrayIdx[depth]++;
					if (arrayIdx[depth]<array[depth].length) {
						break;
					}
					depth--;
				}
			}
		}
	
		if (moveFromIndex>=0 && moveFromArray) {
			moveFromArray.splice(swap.oldPosition,1);
			moveFromArray.splice(swap.newPosition,0,moveFromSect);

			// update view
			printDef.items = trialLayout.items;
			this.updatePreview();
		}
	}

	if (final) {
		// clear out old list
		delete this._originalLayout;
	}
}

/// Get the client-side print definition.
ClientMethod getPrintDef() [ Language = javascript ]
{
	return zen('printDefinition').getContentObject();
}

/// Get Print Definition data for JSON provider.
Method GetPrintDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK

	Set pObject = ""
	If (..mode="dashboard") {
		// open instance of PrintDefinition
		Set tSC = ##class(%DeepSee.UI.DashboardPDF).%GetPrintDefinition(.tPrintDef)
		If $$$ISERR(tSC) Quit
		Set pObject = tPrintDef
	}
	Quit tSC
}

/// Compute and return the size of the given html.
ClientMethod computeDivSize(html) [ Internal, Language = javascript ]
{
	var size = {width:0, height:0};

	var div = this.getEnclosingDiv();
	var element = document.createElement('div');
	element.innerHTML = html;
    div.appendChild(element);

	size.width = element.offsetWidth;
	size.height = element.offsetHeight;
   	div.removeChild(element);
	return size;
}

/// Construct a single list of content items from a graph of items.
ClientMethod getLayoutTree(list, level, parentKey) [ Language = javascript ]
{
	var tree = [];
	for (var n = 0; n < list.length; n++) {
		var key = (parentKey ? (parentKey+',') : '') + n;
		var sect = list[n];
		var name = zenGet(sect.title);
		var type = zenGet(sect.type,'');
		var caption = type + ' ' + (n+1);	// !!!

		var pad = 20 * level;
		// add reference to printItem to item
		// this is used by arrangeData
		tree[tree.length] = {_item: sect, display:'caption-value-hz', caption:caption, value:name, action:'drill', key:'item:'+key, closeButton:true,canDrag:true, style:'font-style:italic;', indent:level, selected:(this.selectedItem==key) };
		if (sect.items && sect.items.length) {
			var xlist = this.getLayoutTree(sect.items,level+1,key);
			for (var j = 0; j < xlist.length; j++) {
				tree[tree.length] = xlist[j];
			}
		}
	}
	return tree;
}

/// Find the item within the print definition graph with the given key.
/// The key takes the form: "n1,n2,n3..."
ClientMethod getLayoutItem(key) [ Language = javascript ]
{
	var printDef = this.getPrintDef();
	var item = null;
	var array = printDef.items;
	var t = key.toString().split(',');
	for (var n = 0; n < t.length && array && array.length; n++) {
		var x = array[t[n]];
		if (n == t.length-1) {
			item = x;
		}
		else {
			array = x.items;
		}
	}
	return item;
}

/// Create a copy of a tree (printDef).
ClientMethod cloneTree(tree) [ Language = javascript ]
{
	var clone = {};
	for (var p in tree) {
		if (p=='items') {
			clone.items = [];
			for (var n = 0; n < tree.items.length; n++) {
				clone.items[clone.items.length] = this.cloneTree(tree.items[n]);
			}
		}
		else {
			clone[p] = tree[p];
		}
	}
	return clone;
}

/// Move the element selector.
ClientMethod moveSelector(targetDiv) [ Internal, Language = javascript ]
{
	var div = this.findElement('selector');
	if (!div) return;

	var szHandle = [];
	for (var n = 0; n < 4; n++) {
		szHandle[n] = this.findElement('sizeHandle:'+n);
	}

	if (!targetDiv) {
		div.style.display = 'none';
		for (var n = 0; n < 4; n++) {
			if (szHandle[n]) {
				szHandle[n].style.display = 'none';
			}
		}
	}
	else {
		div.style.display = 'block';
		// !!!
		var top = targetDiv.offsetTop + targetDiv.parentNode.offsetTop;
		var left = targetDiv.offsetLeft + targetDiv.parentNode.offsetLeft;
		var hgt = targetDiv.offsetHeight;
		var wid = targetDiv.offsetWidth;
		if (left < 0) {
			top += 4;
			left += 4;
		}

		div.style.top = top + 'px';
		div.style.left = left + 'px';
		div.style.width = wid + 'px';
		div.style.height = hgt + 'px';

		for (var n = 0; n < 4; n++) {
			var adj = 3;
			if (szHandle[n]) {
				szHandle[n].style.display = 'block';
				switch(n) {
				case 0:
					szHandle[n].style.top = top-adj + 'px';
					szHandle[n].style.left = left-adj + 'px';
					break;
				case 1:
					szHandle[n].style.top = top-adj + 'px';
					szHandle[n].style.left = left+wid-adj + 'px';
					break;
				case 2:
					szHandle[n].style.top = top+hgt-adj + 'px';
					szHandle[n].style.left = left+wid-adj + 'px';
					break;
				case 3:
					szHandle[n].style.top = top+hgt-adj + 'px';
					szHandle[n].style.left = left-adj + 'px';
					break;
				}
			}
		}
	}
}

/// Select an element within the preview.
ClientMethod selectElement(evt, which) [ Language = javascript ]
{
	if (evt=='none') {
		// force null
		evt = null;
	}
	else {
		evt = evt ? evt : window.event;
	}
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	this.selectedItem = which;
	var targetDiv = null;

	switch(which) {
	case '':
		targetDiv = self.document.getElementById('previewPage');
		break;
	default:
		targetDiv = self.document.getElementById('pv_'+which);
		break;
	}

	this.moveSelector(targetDiv);
	zen('navigator').refreshTopSheet();
}

/// Add a new item to the print definition.
ClientMethod addItem(type) [ Language = javascript ]
{
	var printDef = this.getPrintDef();
	if (printDef) {
		var item = null;
		switch(type) {
		case 'table':
			item = {type:'table',items:[]};
			break;
		case 'chart':
			item = {type:'chart'};
			break;
		case 'text':
			item = {type:'text',content:'Add text here...'};
			break;
		case 'pivot':
			item = {type:'pivot'};
			break;
		}
		if (item) {
			printDef.items[printDef.items.length] = item;
		}
		this.updatePreview();
		zen('navigator').refreshTopSheet();
	}
}

/// Round off a numer to the given number of places.
ClientMethod roundOff(value, places) [ Language = javascript ]
{
	if (value==='') return '';
	val = parseFloat(value);
	return isNaN(val) ? value : val.toFixed(places);
}

}
