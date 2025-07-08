/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.scoreCard Extends %ZEN.Report.Display.COSChart.cchart [ Deprecated, System = 4 ]
{

/// DeepSee score card component.
/// This is a subclass of chart as it shares the same data acquisition logic
/// (and uses many of the same style properties).
Parameter INCLUDEFILES = "dsparser.js";

/// Default viewBoxWidth of this component.
/// Turn off for score card.
Parameter DEFAULTVIEWBOXWIDTH;

/// Default viewBoxHeight of this component.
Parameter DEFAULTVIEWBOXHEIGHT;

/// Localization domain
Parameter DOMAIN = "%DeepSee";

/// Specification for columns within the scoreCard.
Property columns As list Of scoreCardColumn(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

/// How big to show items within this score card.
/// This can be "big" or "" (regular).
Property cardSize As %ZEN.Datatype.string;

/// Height (pixels) of rows within the scorecard.
Property rowHeight As %ZEN.Datatype.integer;

/// Computed height (pixels) of the scorecard.
Property cardHeight As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 0 ];

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

/// internal properties of a scoreCard
Property %rowValues As %Integer(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

Property %dataMinValue As %Double(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

Property %dataMaxValue As %Double(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

Property %dataCount As %Double(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

Property %dataSum As %Double(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

Property %columnDefs As list Of scoreCardColumn(XMLPROJECTION = "none") [ Internal ];

XData SVGStyle
{
<style type="text/css">

.scoreCardBackgroundOriginal {
	fill: #FFFFFE;
	stroke: none;
}

.scoreCardBackground {
	fill: white;
	stroke: black;
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
Method hasAxes()
{
	quit 0
}

/// Render the inner SVG contents of this component.
Method renderContents()
{
	Set this=##this
	// JMD1100
	// if view box is turned off; find scaling factors
	if ((this.viewBoxWidth = "") && (this.viewBoxHeight = "")) {
		Set this.%scaleX = $$$PARSEINT(this.width)/100
		Set this.%scaleY = $$$PARSEINT(this.height)/100
	}
	else {
		Set this.%scaleX = 1
		Set this.%scaleY = 1
	}

	Set scaleX = this.%scaleX
	Set scaleY = this.%scaleY

	// get data from controller, if present.
	do ..acquireData()

	// draw the contents of the score card.
	if ($isObject(..svgGroup)) {
		do ..unrender()
	}
	do ..setupTopLevel(scaleX,scaleY)
	do ..renderScoreCard()
	
	quit $$$OK
}

Method setupTopLevel(scaleX, scaleY)
{
	Set pane=##class(%ZEN.Report.Display.COSChart.node).%New()
	Do pane.createElementSVG("rect")
	Do pane.setAttribute("id",..makeId("background"))
	Do pane.setAttribute("class","chart-background")
	Do pane.setAttribute("style",..backgroundStyle)
	Do pane.setAttribute("rx",..borderRadius)
	Do pane.setAttribute("x",0)
	Do pane.setAttribute("y",0)
	Do pane.setAttribute("width",100*scaleX)
	Do pane.setAttribute("height",100*scaleY)

	Set ..svgGroup=##class(%ZEN.Report.Display.COSChart.node).%New()
	do ..svgGroup.createElementSVG("svg")
	Set ..topLevel=##class(%ZEN.Report.Display.COSChart.node).%New()
	do ..topLevel.createElementSVG("svg")
	do ..topLevel.setAttribute("x",0) ; magic to make PDF display
	do ..topLevel.setAttribute("y",0)
	do ..topLevel.setAttribute("shape-rendering","geometricPrecision")
	if ..height'="" {
		do ..svgGroup.setAttribute("height",..height)
		do ..topLevel.setAttribute("height",..height)
	} else {
		do ..svgGroup.setAttribute("height",100)
		do ..topLevel.setAttribute("height",100)
	}
	if ..width'="" {
		do ..svgGroup.setAttribute("width",..width)
		do ..topLevel.setAttribute("width",..width)
	} else {
		do ..svgGroup.setAttribute("width",100)
		do ..topLevel.setAttribute("width",100)
		
	}
	do ..svgGroup.setAttribute("viewBox",..calculateViewBox()) ; JMD1100 - this is in canvas in ZEN code
	do ..svgGroup.setAttribute("preserveAspectRatio","none")	
	Set defs=##class(node).%New()
	do defs.createElementSVG("defs")
	do ..svgGroup.appendChild(defs)
	do ..svgGroup.appendChild(pane)
	do ..topLevel.appendChild(..svgGroup)
}

/// Render the contents of this component.
Method renderScoreCard()
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	//try {
		Set msg = null
		Set this.cardHeight = 0
		Set smallTitle = false

		Set controller= ..getController()

		Set marginTop = $s(this.titleVisible || this.headersVisible : 5, 1 : 0)
		Set marginRight = 10
		Set marginLeft = 10

		Set titleText = this.title
		Set subtitleText = this.subtitle
		Set titleStyle = this.titleStyle

		// array of logical row values
		//Set this._rowValues = new Array();

		// JMD1107 2D array of cell information
		// used for items that are plotted *after* cell sizes are know
		//var cellInfoEx = [];

		// background
		Set rect = ##class(node).newElementSVG("rect")
		do rect.setAttribute("id",this.makeId("background"))
		do rect.setAttribute("class","scoreCardBackground")
		do rect.setAttribute("style",this.backgroundStyle)
		do rect.setAttribute("x",0)
		do rect.setAttribute("y",0)
		do rect.setAttribute("width",this.width)
		do rect.setAttribute("height",this.height)
		do this.svgGroup.appendChild(rect)

		Set y = marginTop

		// map base data to property names
		Set scount = this.getSeriesCount()
		Set ssize = this.getSeriesSize()
		Set rowCount = $s('this.pivotData : scount, 1 : ssize)
#if 0		
		// swap scount and ssize if pivot
		if this.pivotData {
			Set temp=scount
			Set scount=ssize
			Set ssize=temp
		}
#endif		
		//var data = new Object();
		// values used for formula functions in expressions
		// this._dataMinValue = new Object();
		// this._dataMaxValue = new Object();
		// this._dataCount = new Object();
		// this._dataSum = new Object();

		// values used for summary row
		//var colDataMinValue = new Array();
		//var colDataMaxValue = new Array();
		if (controller'="") {
			if ('this.pivotData) {
				for i = 0:1:ssize-1 {
					// JMD997 use prop name and not label
					//var name = controller.getLabel(i,1);
					//var name = controller.getPropertyName(i);
					Set name = controller.getPropertyName(i)
					if (name '= "") {
						Set name = $$$TOUPPERCASE(name)
						//data[name] = new Array();
						for n = 0:1:scount-1 {
							Set val = $s($D(this.%dataSeries(n,i)) : this.%dataSeries(n,i), 1 : "")
							Set data(name,n) = val
						}
					}
				}
			}
			else {
				// rotate data source 90 degrees
				for i = 0:1:scount-1 {
					//var name = controller.getLabel(i,2);
					// var name = controller.getPropertyName(i);
					Set name = controller.getPropertyName(i)
					if (name '= "") {
						Set name = $$$TOUPPERCASE(name)
						//data[name] = new Array();
						for n = 0:1:ssize-1 {
							Set val = $s($D(this.%dataSeries(n,i)) : this.%dataSeries(n,i), 1 : "")
							Set data(name,n) = val
						}
					}
				}
			}
		}
#if 0
		s t=$io u 0
		w !,"dumping data after initial",!
		zw data	
		u t
#endif		
		// compute values on properties
		Set prop="" for { Set prop=$O(data(prop)) q:prop=""
			for r = 0:1: rowCount-1 {
				Set propU = $$$TOUPPERCASE(prop)
				Set val = data(propU,r)

				if ('$$$ISNAN($$$PARSEFLOAT(val))) {
					Set val = $$$PARSEFLOAT(val)
					Set this.%dataMinValue(propU) = $s(('$D(this.%dataMinValue(propU)))||(val<this.%dataMinValue(propU)) : val, 1 : this.%dataMinValue(propU))
					Set this.%dataMaxValue(propU) = $s(('$D(this.%dataMaxValue(propU))||(val>this.%dataMaxValue(propU))) : val, 1 : this.%dataMaxValue(propU))
					Set this.%dataCount(propU) = $s(('$D(this.%dataCount(propU))) : 1, 1 : this.%dataCount(propU)+1)
					Set this.%dataSum(propU) = $s(($D(this.%dataSum(propU))) : this.%dataSum(propU)+val, 1 : val)
				}
			}
		}

		// see if there is a dataProperty supplying the title
		// remove these from list of columns
		//var columnDefs = new Array();
		for c = 0:1:this.columns.Size-1 {
			Set column = this.columns.GetAt(c+1)
			if ("title" = $s($isObject(column):column.display,1:"")) {
				if ("" '= $s($isObject(column):column.label,1:"")) {
					Set titleText = column.label
				}
				elseif ("" '= $s($isObject(column):column.dataValue,1:"")) {
					Set prop = this.getPropName(column.dataValue)
					Set propU = $$$TOUPPERCASE(prop)
					Set titleText = $s(("" = prop) || (null = data(propU)) : column.dataValue, 1 : $s('$D(data(propU,0)) : column.dataValue, 1 : data(propU,0)))
				}
			}
			else {
				// JMD997: test if column is conditional
				Set hidden = false
				if ("conditional"=$s($isObject(column):column.showAs,1:"")) {
					if ("" '= $s($isObject(column):column.dataValue,1:"")) {
						Set prop = this.getPropName($s($isObject(column):column.dataValue,1:""))
						if (prop'="") {
							Set propU = $$$TOUPPERCASE(prop)
							Set hidden = '$D(data(propU))
						}
					}
				}
				if ('hidden) {
					do ..%columnDefs.Insert(column)
				}
			}
		}

		// now map data to dataValue name
		Set hasFooter = false
		Set hasScale = false
		for r = 0:1:rowCount-1 {
			//cellInfoEx[r] = [];
			Set this.%rowValues(r) = ""
			for c = 0:1:..%columnDefs.Size-1 {
				Set column = ..%columnDefs.GetAt(c+1)
				Set val = $s(""=$s($isObject(column):column.dataValue,1:"") : "", 1 : this.evaluate(column.dataValue,.data,r))
				if ('$$$ISNAN($$$PARSEFLOAT(val))) {
					Set val = $$$PARSEFLOAT(val)

					// these values are used for summary row
					Set colDataMinValue(c) = $s(('$D(colDataMinValue(c)))||(val<colDataMinValue(c)) : val, 1 : colDataMinValue(c))
					Set colDataMaxValue(c) = $s(('$D(colDataMaxValue(c)))||(val>colDataMaxValue(c)) : val, 1 : colDataMaxValue(c))
				}
				// if we are the value column, store the value
				if ($s($isObject(column):column.valueColumn,1:"")'="") {
					Set this.%rowValues(r) = val
				}
			
				// see if there is a totals row
				if ((r=0)&&((""'=$s($isObject(column):column.summary,1:"")||("plotBox"'=$s($isObject(column):column.display,1:""))))) {
					Set hasFooter = $s(this.footersVisible : true, 1 : false)
					if ("plotBox"'=$s($isObject(column):column.display,1:"")) {
						Set hasScale = $s(this.footersVisible : true, 1 : false)
					}
				}
			}
		}

		// title
		if (null '= msg) {
			Set titleText = msg
			Set subtitleText = ""
			Set titleStyle = "font-size:20pt;fill:red;"
		}

		// image & image size
		Set imageLeft = 0
		Set imageTop = 0
		Set imageWidth = 0
		Set imageHeight = 0

		Set imageURL = this.titleImage
		Set imageStyle = this.titleImageStyle

		if (imageURL'="") {
			Set imageWidth = 50
			Set imageHeight = 50
			if (imageStyle'="") {
				Set t = imageStyle.split(";")
				for ti=1:1:$LL(t) {
					Set t2 = $LG(t,ti).split(":")
					//switch (t2[0]) {
					if $LG(t2,1)="left" {
						Set imageLeft = $$$PARSEINT($LG(t2,2))
					}
					elseif $LG(t2,1)="top" {
						Set imageTop = $$$PARSEINT($LG(t2,2))
					}
					elseif $LG(t2,1)="width" {
						Set imageWidth = $$$PARSEINT($LG(t2,2))
					}
					elseif $LG(t2,1)="height" {
						Set imageHeight = $$$PARSEINT($LG(t2,2))
					}
				}
			}
		}

		
		if (this.titleAlign = "right") {
			Set tx = $$$PARSEINT(this.width) - marginRight
			Set anch = "end"
		} elseif (this.titleAlign = "center") {
			Set tx = $$$PARSEINT(this.width) / 2
			Set anch = "middle"
		} else {
		//case 'left':
		//default:
			Set tx = marginLeft+ (imageLeft) + imageWidth
			Set anch = "start"

		}

		if (this.titleVisible || (msg'=null)) {
			// rectangle under title (normally not shown)
			Set trect = ##class(node).newElementSVG("rect")
			do trect.setAttribute("class","chart-titleBox")
			do trect.setAttribute("id",this.makeId("chartTitleBox"))
			do trect.setAttribute("style",this.titleBoxStyle)
			do this.svgGroup.appendChild(trect)

			if ("" '= titleText) {
				Set title = ##class(node).newElementSVG("text")
				do title.setAttribute("class","scoreCardTitle")
				do title.setAttribute("style",titleStyle _ $s(smallTitle:"font-size:8pt;", 1:""))
				do title.setAttribute("font-size", "16pt") // TBD, need way of getting font-size from class and style
				do title.setText(titleText)
				do this.svgGroup.appendChild(title)
				Set th = ..GetBBox(title).height
				Set y = y + th
				do title.setAttribute("x",tx)
				do title.setAttribute("y",y)
				do title.setAttribute("text-anchor",anch)
			}
			if ("" '= subtitleText) {
				Set subtitle = ##class(node).newElementSVG("text")
				do subtitle.setAttribute("class","scoreCardSubtitle")
				do subtitle.setAttribute("style",this.subtitleStyle)
				do subtitle.setAttribute("font-size","10pt") // TBD, need way of getting font-size from class and style
				do subtitle.setText(subtitleText)
				do this.svgGroup.appendChild(subtitle)
				Set th = $$$FLOOR(..GetBBox(subtitle).height * 1.2)
				Set y = y + th
				do subtitle.setAttribute("x",tx)
				do subtitle.setAttribute("y",y-3)
				do subtitle.setAttribute("text-anchor",anch)
			}

			// move title box
			do trect.setAttribute("x", 0)
			do trect.setAttribute("y", 0)
			do trect.setAttribute("width", this.width)
			do trect.setAttribute("height",$s(y:(y+10), 1:0))
		} // title

		if (null '= msg) {
			Set this.cardHeight = y
			quit
		}

		if (imageURL'="") {
			Set image = ##class(node).newElementSVG("image")
			do image.setAttribute("id",this.makeId("chartTitleImage"_this.currMultiple))
			do image.setAttribute("xmlns:xlink","http://www.w3.org/1999/xlink")
			do image.setAttribute("xlink:href",imageURL)
			do image.setAttribute("preserveAspectRatio","none")
			do image.setAttribute("x",imageLeft)
			do image.setAttribute("y",imageTop)
			do image.setAttribute("width",imageWidth)
			do image.setAttribute("height",imageHeight)
			do this.svgGroup.appendChild(image)

			if (y < (imageHeight + imageTop)) {
				Set y = imageHeight + imageTop
				do trect.setAttribute("height",$s(y:(y+imageTop),1:0))
			}
		}

		if (this.titleVisible || imageHeight) {
			Set y = y + 5
		}

		Set padding = $$$PARSEFLOAT(this.width) / 10
		Set padding = $s(padding < 5 : 5, 1 : padding)
		Set padding = $s(padding > 20 : 20, 1 : padding)
		Set width = $$$PARSEFLOAT(this.width) - (marginLeft + marginRight) - ((..%columnDefs.Size-1) * padding)
		Set colWidth = 100 // place holder

		// max width of value in column
		//var colMaxWidths = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set colMaxWidths(i)=0
		}

		// width of header label
		//var colHeaderWidths = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set colHeaderWidths(i)=0
		}

		Set nameToPosition = null

		// draw column headers
		Set x = marginLeft
		Set headerHeight = 0
		//var headerBoxes = [];
		if (this.headersVisible) {
			for c = 0:1:..%columnDefs.Size-1 {
				Set headerBoxes(c)=""
				Set column = ..%columnDefs.GetAt(c+1)
				Set label = $s($isObject(column):column.label,1:"")
				// JMD997 Test for $auto
				if ((label="$auto") && ($s($isObject(column):column.dataValue,1:"") '= "")) {
					Set axisNo = $s(this.pivotData : 2, 1 : 1)
					Set label = ""
					if ('nameToPosition) {
						// nameToPosition = {};
						// create map of source names to positions
						Set props = controller.getDimSize(axisNo)
						for p1 = 0:1:props-1 {
							Set pn = controller.getPropertyName(p1)
							if (pn'="") {
								Set nameToPosition(pn) = p1
							}
						}
					}

					Set propx = this.getPropName($s($isObject(column):column.dataValue,1:""))
					if (propx'="") {
						Set p1 = $g(nameToPosition(propx))
						if ('$D(nameToPosition(propx))) {
							Set label = controller.getLabel(p1,axisNo)
						}
						else {
							Set label = propx
						}
					}
				}
				Set align = $s($isObject(column):column.align,1:"")
				Set hdrAlign = $s($isObject(column):column.headerAlign,1:"")
				if (("" '= label) && ("hidden" '= $s($isObject(column):column.display,1:""))) {
					// clip box for header
					Set svg = ##class(node).newElementSVG("svg")
					do this.svgGroup.appendChild(svg)
					Set headerBoxes(c) = svg

					// split text by "\n" within the text
					Set th = 0
					Set totalH = 0
					//var headers = new Array();
					kill headers
					Set labelt = ..split(label, "\n")
					for t = 0:1:$LL(labelt)-1 {
						Set header = ##class(node).newElementSVG("text")
						Set headers($i(headers)) = header

						do header.setAttribute("class","scoreCardHeader")
						do header.setAttribute("style",this.columnHeaderStyle)
						do header.setAttribute("font-size","11pt") // hack to deal with lack of class, style parsing TBD
						do header.setAttribute("font-weight","bold")
						if (($s($isObject(column):column.display,1:"") = "value") || ($s($isObject(column):column.display,1:"") = "")) {
							do header.setAttribute("text-anchor","end")
							do header.setAttribute("x","98%")
						}
						else {
							do header.setAttribute("x",0)
						}
						// if hdrAlign is defined, apply it
						if (hdrAlign="left") {
							do header.setAttribute("x","5%")
							do header.setAttribute("text-anchor","start")
						}
						elseif (hdrAlign="right") {
							do header.setAttribute("x","95%")
							do header.setAttribute("text-anchor","end")
						}
						elseif (hdrAlign="center") {
							do header.setAttribute("x","50%")
							do header.setAttribute("text-anchor","middle")
						}
						//var textNode = this.document.createTextNode(labelt[t]);
						//header.appendChild(textNode);
						do header.setText($LG(labelt,t+1))
						do svg.appendChild(header)
						Set bbox = ..GetBBox(header)
						Set th = bbox.height * 1.2
						Set totalH = totalH + th

						Set tw = bbox.width * 1.2
						// note the widths
						Set colHeaderWidths(c) = $s(('$D(colHeaderWidths(c))) || (tw > colHeaderWidths(c)) : tw, 1 : colHeaderWidths(c))
					}

					if (0 = headerHeight) {
						Set headerHeight = totalH 
					}
					do svg.setAttribute("x",x)
					do svg.setAttribute("y",y)
					do svg.setAttribute("width",colWidth _ "px")
					do svg.setAttribute("height",headerHeight _ "px")

					// place text items
					Set hy = headerHeight - 3
					// length of headers array stored in headers itself
					for h = headers-1:-1:0 {
						do headers(h+1).setAttribute("y",hy)
						Set hy = hy - (th*0.8)
					}
				}
				if ("hidden"'= $s($isObject(column):column.display,1:"")) {
					Set x = x + $$$PARSEFLOAT(colWidth) + padding
				}
			} // end for
			Set y = y + 2 + headerHeight
		} // headers

		// separator
		Set line = ##class(node).newElementSVG("line")
		do line.setAttribute("x1",0)
		do line.setAttribute("x1",this.width)
		do line.setAttribute("y1",y)
		do line.setAttribute("y2",y)
		do line.setAttribute("class","scoreCardSeparator")
		// use grid style for override
		do line.setAttribute("style",this.gridStyle)
		do this.svgGroup.appendChild(line)

		if (..%columnDefs.Size = 0) {
			Set this.cardHeight = y
			quit
		}

		// determine rowHeight
		Set rowHeight = this.rowHeight
		if (""=rowHeight) {
			Set text = ##class(node).newElementSVG("text")
			do text.setAttribute("class",$s(this.cardSize="big" : "scoreCardLabelBig", 1 : "scoreCardLabel"))
			do text.setAttribute("x",0)
			do text.setAttribute("y",20)
			//var textNode = this.document.createTextNode("Ap");
			//text.appendChild(textNode);
			do text.setText("Ap")
			do this.svgGroup.appendChild(text)
			Set rowHeight = ..GetBBox(text).height * 1.5
			do this.svgGroup.removeChild(text)
		}
		Set rowHeight = $$$PARSEINT(rowHeight)
		Set rowHeight = $s(rowHeight < 0 : 0, 1 : rowHeight)
		
		// cells
		//var plotMinValues = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set plotMinValues(i)=0
		}

		//var plotMaxValues = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set plotMaxValues(i)=0
		}

		//var plotBaseValues = new Array(..%columnDefs.length);
			for i=0:1:..%columnDefs.Size-1 {
			Set plotBaseValues(i)=0
		}


		//var summaryValues = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set summaryValues(i)=0
		}

		//var rowCells = new Array(rowCount); // array of svg elements
		for i=0:1:rowCount-1 {
			Set rowCells(i)=0
		}

		for r = 0 : 1: rowCount-1 {
			Set y = y + rowHeight
			Set itemNo = (r+1)
			Set label = ""
			if (controller'="") {
				if (this.pivotData) {
					Set label = controller.getLabel(r,1)
				}
				else {
					Set label = controller.getLabel(r,2)
				}
			}

			// backing rect for row
			Set rect = ##class(node).newElementSVG("rect")
			do rect.setAttribute("id",this.makeId("row_"_r))
			do rect.setAttribute("class",$s(r = this.selectedIndex : "scoreCardRowSelected", 1 : $s(r#2:"scoreCardRowEven", 1 :"scoreCardRowOdd")))
			if (r#2=0) {
				do rect.setAttribute("style",this.stripeStyle)
			}
			do rect.setAttribute("x",0)
			do rect.setAttribute("y",y-rowHeight)
			do rect.setAttribute("width",this.width)
			do rect.setAttribute("height",rowHeight)
			do this.svgGroup.appendChild(rect)

     		// no event listeners in a Zen Report
			//var eventHandler = new Function("evt","row","return zenPage.getComponent("+this.index+").rowClickHandler(evt,""+r+"");");
			//rect.addEventListener("click",eventHandler,false);

			// draw columns
			Set x = marginLeft
			//rowCells[r] = new Array(..%columnDefs.length);
			for i=0:1:..%columnDefs.Size-1 {
				Set rowCells(r,i)=0
			}

			for c = 0:1:..%columnDefs.Size-1 {

				Set column = ..%columnDefs.GetAt(c+1)
				Set value = ""
				Set minValue = 0
				Set maxValue = 100
				Set baseValue = null
				Set targetValue = 0
				Set thresholdLower = 0
				Set thresholdUpper = 0
				Set rangeUpper = null
				Set rangeLower = null
				Set isPct = false
				Set align = $s($isObject(column):column.align, 1:"")
				Set hdrAlign = $s($isObject(column):column.headerAlign, 1:"")

				Set prop = this.getPropName($s($isObject(column):column.dataValue,1:""))
				Set value = this.evaluate($s($isObject(column):column.dataValue,1:""),.data,r)
				Set colStyle = $s($isObject(column):column.style,1:"")
				if (("" '= colStyle) && ($e(colStyle)="=")) {
					Set colStyle = this.evaluate(colStyle,.data,r)
				}

				if (""'=value && '$$$ISNAN(value)) {
					if (""'=$s($isObject(column):column.dataValue,1:"")) {
						Set maxValue = colDataMaxValue(c)
					}
					if (""'=$s($isObject(column):column.dataValue,1:"")) {
						Set minValue = colDataMinValue(c)
					}
					if (minValue > 0) {
						Set minValue = 0
					}

					Set v = this.evaluate($s($isObject(column):column.targetValue,1:""),.data,r)
					if ((""'=v) && '$$$ISNAN(v)) {
						Set targetValue = v
					}
					Set v = this.evaluate($s($isObject(column):column.rangeLower,1:""),.data,r)
					if ((""'=v) && '$$$ISNAN(v)) {
						Set rangeLower = v
					}
					Set v = this.evaluate($s($isObject(column):column.rangeUpper,1:""),.data,r)
					if ((""'=v) && '$$$ISNAN(v)) {
						Set rangeUpper = v
					}
					if ("" '= $s($isObject(column):column.baseValue,1:"")) {
						Set v = this.evaluate($s($isObject(column):column.baseValue,1:""),.data,r)
						if ((""'=v) && '$$$ISNAN(v)) {
							Set baseValue = v
						}
					}

					if (null '= rangeUpper) {
						Set maxValue = rangeUpper
					}
					if (null '= rangeLower) {
						Set minValue = rangeLower
					}

					if ("" '= $s($isObject(column):column.thresholdLower,1:"")) {
						Set v = this.evaluate($s($isObject(column):column.thresholdLower,1:""),.data,r)
						if ((""'=v) && '$$$ISNAN(v)) {
							Set thresholdLower = v
						}
					}
					if ("" '= $s($isObject(column):column.thresholdUpper,1:"")) {
						Set v = this.evaluate($s($isObject(column):column.thresholdUpper,1:""),.data,r)
						if ((""'=v) && '$$$ISNAN(v)) {
							Set thresholdUpper = v
						}
					}

					// apply showAs
					Set propU = $$$TOUPPERCASE(prop)
					if ($s($isObject(column):column.showAs,1:"")="sum") {
						Set value = $s((""=propU) || '$D(this.%dataSum(propU)) : 0, 1 : this.%dataSum(propU))
					} elseif ($s($isObject(column):column.showAs,1:"")="sum%") {
						Set dsum = $s((""=propU) || '$D(this.%dataSum(propU)) : 0, 1 : this.%dataSum(propU))
						Set value = $s(dsum'=0 : (value / dsum), 1 : 0)
						Set isPct = true
					} elseif ($s($isObject(column):column.showAs,1:"")="target") {
						Set value = targetValue
					} elseif ($s($isObject(column):column.showAs,1:"")="target%") {
						Set value = $s(targetValue>0 : (value / targetValue), 1 : 0)
						Set maxValue = $s(targetValue>0 : (maxValue / targetValue), 1 : 0)
						Set isPct = true
					} else {
					//case "value":
					//case "hidden":
					//default:

					}
				}

				if (isPct) {
					Set format = $s('$isObject(column)||(""=column.format) : "#.##%", 1 : column.format)
					Set valueFmt = $s('$$$ISNAN(value) : ##class(%DeepSee.ResultSet).%FormatNumber(value,format), 1 : value)
				}
				else {
					Set format = $s('$isObject(column)||(""=column.format) : "#,#", 1 : column.format)
					Set valueFmt = ##class(%DeepSee.ResultSet).%FormatNumber(value,format)
				}
				Set display = $s($isobject(column):column.display,1:"")
				
				// accumulate values for summary (footer) row
				Set avalue = $$$PARSEFLOAT(value)
				if ('$$$ISNAN(avalue)) {

					if ($s($isObject(column):column.summary,1:"")="sum" || $s($isObject(column):column.summary,1:"")="avg") {
						Set summaryValues(c) = $s($D(summaryValues(c)):summaryValues(c)+avalue, 1:avalue)
					}
					elseif ($s($isObject(column):column.summary,1:"")="min") {
						Set summaryValues(c) = $s($D(summaryValues(c)):$s(summaryValues(c)<avalue:summaryValues(c), 1:avalue), 1:avalue)
					} elseif ($s($isObject(column):column.summary,1:"")="max") {
						Set summaryValues(c) = $s($D(summaryValues(c)):$s(summaryValues(c).avalue:summaryValues(c), 1:avalue), 1:avalue)
					} else {
						//case "value":
						//default:
						// compute at end
						Set summaryValues(c) = ""
					}
				}

				// clip box for cell
				if ("hidden" '= display) {
					Set svg = ##class(node).newElementSVG("svg")
					do svg.setAttribute("x",x)
					do svg.setAttribute("y",y-rowHeight)
					if (colWidth'="") {
						do svg.setAttribute("width",colWidth _ "px")
					}
					if (rowHeight'="") {
						do svg.setAttribute("height",rowHeight _ "px")
					}
					do this.svgGroup.appendChild(svg)
					Set rowCells(r,c) = svg
				}

				// cell caption and labels if present
				// var cellCaption = zenGet(column.cellCaption)
				Set cellCaption = $s($isObject(column):column.cellCaption,1:"")
				if (("" '= cellCaption) && ($e(cellCaption)="=")) {
					Set cellCaption = this.evaluate(cellCaption,.data,r)
				}

				Set cellCaptionH = 0
				if ((cellCaption'="") && (display'="hidden") && (rowHeight > 10)) {
					Set text = ##class(node).newElementSVG("text")
					do text.setAttribute("class","scoreCardCellCaption")
					do text.setAttribute("style",this.cellCaptionStyle)
					do text.setAttribute("x",0)
					do text.setAttribute("y",(rowHeight*0.9))
					
					if (align="right") {
						do text.setAttribute("x","95%")
						do text.setAttribute("text-anchor","end")
					}
					elseif (align="center") {
						do text.setAttribute("x","50%")
						do text.setAttribute("text-anchor","middle")
					}

					//var textNode = this.document.createTextNode(cellCaption);
					//text.appendChild(textNode);
					do text.setText(cellcaption)
					do svg.appendChild(text)
					Set tw = ..GetBBox(text).width *1.2
					Set cellCaptionH = ..GetBBox(text).height
					Set colMaxWidths(c) = $s('$D(colMaxWidths(c)) || (tw > colMaxWidths(c)) : tw, 1 : colMaxWidths(c))
				}

				if (display = "hidden") {
					Set colWidth = 0
				}
				elseif (display = "trendLine") {
					// render in 2nd pass
					Set vals = ..split(value,",")

					Set path = ##class(node).newElementSVG("path")
					do path.setAttribute("class","scoreCardTrendLine")
					do path.setAttribute("style",this.trendLineStyle _ colStyle)
					do svg.appendChild(path)

					// remember values for 2nd pass
					Set cellInfoEx(r,c,"vals") = vals
					Set cellInfoEx(r,c,"path") = path
					Set cellInfoEx(r,c,"cellCaptionH")=cellCaptionH

					Set colMaxWidths(c) = width / 10
				} elseif (display = "trendBars") {

					// render in 2nd pass
					Set vals = ..split(value,",")

					// remember values for 2nd pass
					Set cellInfoEx(r,c,"vals") = vals
					Set cellInfoEx(r,c,"cellCaptionH")=cellCaptionH

					Set colMaxWidths(c) = width / 10
				} elseif (display = "arrow") {

					if (minValue < 0) {
						Set arrowValue = $s($$$ISNAN($$$PARSEFLOAT(value)) : 0, 1 : (($$$PARSEFLOAT(value))/maxValue))
					}
					else {
						Set arrowValue = $s($$$ISNAN($$$PARSEFLOAT(value)) : 0, 1 : (($$$PARSEFLOAT(value) - minValue)/maxValue))
					}
					if ('$$$ISNAN($$$PARSEFLOAT(arrowValue)) && ($$$PARSEFLOAT(arrowValue)'=0)) {
						Set path = ##class(node).newElementSVG("path")
						do path.setAttribute("class","scoreCardArrow")
						do path.setAttribute("style",this.arrowStyle _ colStyle)
						Set cx = (rowHeight-cellCaptionH)*0.5
						Set p1 = (rowHeight-cellCaptionH)*(0.5-($$$PARSEFLOAT(this.arrowSize)/2))
						Set p2 = (rowHeight-cellCaptionH)*(0.5+($$$PARSEFLOAT(this.arrowSize)/2))
						if ($$$PARSEFLOAT(arrowValue)>0) {
							Set d = "M "_cx_" "_p1_" L "_p1_" "_p2_" "_p2_" "_p2_" z" // up
						}
						else {
							Set d = "M "_cx_" "_p2_" L "_p1_" "_p1_" "_p2_" "_p1_" z" // down
						}
						do path.setAttribute("d",d)
						do svg.appendChild(path)
						//path.addEventListener("click",eventHandler,false);
						//cellInfoEx[r][c] = { shape: path, width:cx*2 };
						Set cellInfoEx(r,c,"shape")=path
						Set cellInfoEx(r,c,"width")=cx*2
					}
					Set colMaxWidths(c) = rowHeight
				} elseif (display = "lamp" || (display="lamp-value")) {

					if (maxValue < 0) {
						Set lampValue = $s($$$ISNAN($$$PARSEFLOAT(value)): 0, 1 : -(($$$PARSEFLOAT(value))/maxValue))
					}
					else {
						Set lampValue = $s($$$ISNAN($$$PARSEFLOAT(value)): 0, 1 : (($$$PARSEFLOAT(value))/maxValue))
					}
					if ('$$$ISNAN($$$PARSEFLOAT(lampValue)) && ($$$PARSEFLOAT(lampValue)'=0)) {
						Set g = ##class(node).newElementSVG("g")
						do svg.appendChild(g)
						Set lamp = ##class(node).newElementSVG("circle")
						do lamp.setAttribute("class","scoreCardLamp")
						if (lampValue > 0) {
							Set lcr = $s(this.lampColor = "" : "#80F080", 1 : this.lampColor)
						}
						else {
							Set lcr = $s(this.lampColorNeg = "" : "#F08080", 1 : this.lampColorNeg)
							Set lampValue = -lampValue
						}
						Set ls = "fill:"_lcr_";"
						do lamp.setAttribute("fill-opacity",lampValue)
						Set rad = ((rowHeight-cellCaptionH)*0.5*$$$PARSEFLOAT(this.lampSize))
						do lamp.setAttribute("cx",rad)
						do lamp.setAttribute("cy",((rowHeight-cellCaptionH)*0.5))
						do lamp.setAttribute("r",rad)
						if (""'=colStyle) {
							Set ls = ls _ colStyle
						}
						do lamp.setAttribute("style",ls)
						do g.appendChild(lamp)
						//lamp.addEventListener("click",eventHandler,false);
						if (display="lamp-value") {
							// show value within lamp
							Set text = ##class(node).newElementSVG("text")
							do text.setAttribute("class",$s(this.cardSize="big" : "scoreCardValueBig", 1 : "scoreCardValue"))
							do text.setAttribute("style",this.lampLabelStyle)
							do text.setAttribute("text-anchor","middle")
							do text.setText(valueFmt)
							do g.appendChild(text)
							Set tw = ..GetBBox(text).width*1.2
							Set th = ..GetBBox(text).height
							do text.setAttribute("x",rad)
							do text.setAttribute("y",((rowHeight-cellCaptionH)*0.5)+((th*0.7)/2))
							if (tw>(rad*1.8)) {
								Set oldNode = text.firstChild()
								do text.removeChild(oldNode)
								do text.setText("#")
								do text.setAttribute("style",this.lampLabelStyle_"font-size:10px;")
								Set th = ..GetBBox(text).height
								do text.setAttribute("y",((rowHeight-cellCaptionH)*0.5)+((th*0.7)/2))
							}
						}
				
						// cellInfoEx[r][c] = { shape: lamp, width:rad*2 };
						Set cellInfoEx(r,c,"shape")=g
						Set cellInfoEx(r,c,"width")=rad*2

					}
					Set colMaxWidths(c) = rowHeight
				} elseif (display="plotBox") {

					// render in 2nd pass

					// compute sizes
					Set range = (maxValue-minValue)
					if (range = 0) quit
					Set outerX = 95
					Set middleX = $s($$$ISNAN($$$PARSEFLOAT(thresholdUpper)) : 0, 1 : (($$$PARSEFLOAT(thresholdUpper)-minValue)/range)*outerX)
					Set innerX = $s($$$ISNAN($$$PARSEFLOAT(thresholdLower)) : 0, 1 : (($$$PARSEFLOAT(thresholdLower)-minValue)/range)*outerX)
					Set targetX = $s($$$ISNAN($$$PARSEFLOAT(targetValue)) : 0, 1 : (($$$PARSEFLOAT(targetValue)-minValue)/range)*outerX)

					if ("" = baseValue) {
						Set valueX1 = 0
						Set valueX2 = $s($$$ISNAN($$$PARSEFLOAT(value)) : 0, 1 : (($$$PARSEFLOAT(value)-minValue)/range)*outerX)
					}
					else {
						Set valueX1 = $s(($$$ISNAN($$$PARSEFLOAT(baseValue))) : 0, 1 : (($$$PARSEFLOAT(baseValue)-minValue)/range)*outerX)
						Set valueX2 = $s($$$ISNAN($$$PARSEFLOAT(value)) : 0, 1 : (($$$PARSEFLOAT(value)-minValue)/range)*outerX)
					}
					if (r=0) {	
						Set plotMinValues(c) = minValue
						Set plotMaxValues(c) = maxValue
						Set plotBaseValues(c) = baseValue
					}

					// remember values for 2nd pass
					/*
					cellInfoEx[r][c] = {
						outerX:outerX,
						middleX:middleX,
						innerX:innerX,
						targetX:targetX, 
						valueX1:valueX1,
						valueX2:valueX2,
						cellCaptionH:cellCaptionH,
						eventHandler:eventHandler };
					*/
					Set cellInfoEx(r,c,"outerX")=outerX
					Set cellInfoEx(r,c,"middleX")=middleX
					Set cellInfoEx(r,c,"innerX")=innerX
					Set cellInfoEx(r,c,"targetX")=targetX
					Set cellInfoEx(r,c,"valueX1")=valueX1
					Set cellInfoEx(r,c,"valueX2")=valueX2
					Set cellInfoEx(r,c,cellCaptionH)=cellCaptionH

				} elseif (display = "label") {

					Set text = ##class(node).newElementSVG("text")
					do text.setAttribute("class",$s(this.cardSize="big" : "scoreCardLabelBig", 1 : "scoreCardLabel"))
					do text.setAttribute("style",this.labelStyle _ colStyle)
					do text.setAttribute("x",0)
					do text.setAttribute("y",((rowHeight-cellCaptionH)*0.8))

					if (align="right") {
						do text.setAttribute("x","95%")
						do text.setAttribute("text-anchor","end")
					}
					elseif (align="center") {
						do text.setAttribute("x","50%")
						do text.setAttribute("text-anchor","middle")
					}

					//var textNode = this.document.createTextNode(label);
					//text.appendChild(textNode);
					do text.setText(label)
					do svg.appendChild(text)
					Set tw = ..GetBBox(text).width *1.2
					Set th = ..GetBBox(text).height
					Set colMaxWidths(c) = $s(('$D(colMaxWidths(c)) || tw > colMaxWidths(c)) : tw, 1 : colMaxWidths(c))
					// cellInfoEx[r][c] = { text: text, height:th };
					Set cellInfoEx(r,c,"text")=text
					Set cellInfoEx(r,c,"height")=th
					Set cellInfoEx(r,c,"cellCaptionH")=cellCaptionH

				} else {
					//case "value":
					//case "itemNo":
					//default:
					Set text = ##class(node).newElementSVG("text")
					do text.setAttribute("class",$s(this.cardSize="big" : "scoreCardValueBig", 1 : "scoreCardValue"))
					do text.setAttribute("style",this.valueLabelStyle _ colStyle)
					do text.setAttribute("y",((rowHeight-cellCaptionH)*0.8))
					if (align="left") {
						do text.setAttribute("x","5%")
						do text.setAttribute("text-anchor","start")
					}
					elseif (align="center") {
						do text.setAttribute("x","50%")
						do text.setAttribute("text-anchor","middle")
					}
					else {
						do text.setAttribute("x","95%")
						do text.setAttribute("text-anchor","end")
					}
					if ("itemNo"=display) {
						Set itemFmt = $s(format'="" : ##class(%DeepSee.ResultSet).%FormatNumber(itemNo,format), 1:(itemNo+"."))
						Set textNode = itemFmt
						
					}
					else {
						Set textNode = valueFmt
					}
					//text.appendChild(textNode);
					//svg.appendChild(text);
					do text.setText(textNode)
					do svg.appendChild(text)
					Set tw = ..GetBBox(text).width*1.2
					Set th = ..GetBBox(text).height
					Set colMaxWidths(c) = $s(('$D(colMaxWidths(c)) || tw > colMaxWidths(c)) : tw, 1 : colMaxWidths(c))
					// cellInfoEx[r][c] = { text: text, height:th };
					Set cellInfoEx(r,c,"text")=text
					Set cellInfoEx(r,c,"height")=th
					Set cellInfoEx(r,c,"cellCaptionH")=cellCaptionH
				}
				if ("hidden" '= display) {
					Set x = x + $$$PARSEFLOAT(colWidth) + padding
				}
			} // row
		}

		// draw footer row and text
		Set footerBoxes = null
		if (hasFooter) {
			// backing rect for row
			Set rect = ##class(node).newElementSVG("rect")
			do rect.setAttribute("class",$s(rowCount#2:"scoreCardRowEven", 1:"scoreCardRowOdd"))
			do rect.setAttribute("x",0)
			do rect.setAttribute("y",y)
			do rect.setAttribute("width",this.width)
			do rect.setAttribute("height",rowHeight)
			do this.svgGroup.appendChild(rect)

			// separator
			Set line = ##class(node).newElementSVG("line")
			do line.setAttribute("x1",0)
			do line.setAttribute("x1",this.width)
			do line.setAttribute("y1",y)
			do line.setAttribute("y2",y)
			do line.setAttribute("class","scoreCardSeparator")
			// use grid style for override
			do line.setAttribute("style",this.gridStyle)
			do this.svgGroup.appendChild(line)

			// set up summary data in case there are formulae based on it
			//var summaryData = {};
			for c = 0:1:..%columnDefs.Size-1 {
				Set column = ..%columnDefs.GetAt(c+1)
				if ("" '= $s($isObject(column):column.label,1:"")) {
					Set lu = $$$TOUPPERCASE(column.label)
					Set summaryData(lu) = summaryValues(c)
				}
			}

			Set x = marginLeft
			//footerBoxes = new Array(..%columnDefs.length);
			for i=0:1:..%columnDefs.Size-1 {
				Set footerBoxes(i)=0
			}

			for c = 0:1:..%columnDefs.Size-1 {
				Set column = ..%columnDefs.GetAt(c+1)
				Set align = $s($isObject(column):column.align,1:"")
				Set hdrAlign = $s($isObject(column):column.headerAlign,1:"")
				if ("hidden" '= $s($isObject(column):column.display,1:"")) {
					Set footerValue = ""
					if (""'=$s($isObject(column):column.summary,1:"")) {
						Set footerValue = $s(('$D(summaryValues(c))):"", 1:summaryValues(c))
						if ("avg"=$s($isObject(column):column.summary,1:"")) {
							Set footerValue = $s((rowCount>0) : footerValue/rowCount, 1 : 0)
						}
						elseif ("value"=$s($isObject(column):column.summary,1:"")) {
							// use column summaries as values
							// assume there are no references to items that are not resolved yet
							Set v = this.evaluate($s($isObject(column):column.summaryValue,1:""),.summaryData,0)
							if ((""'=v) && '$$$ISNAN(v)) {
								Set footerValue = v
							}
						}
					}

					if ("" '= footerValue) {
						// show footer text
						if ("target%" = $s($isObject(column):column.showAs,1:"") || "sum%" = $s($isObject(column):column.showAs,1:"")) {
							Set format = $s(""=$s($isObject(column):column.format,1:"") : "#,#.##%", 1 : column.format)
						}
						else {
							Set format = $s(""=$s($isObject(column):column.format,1:"") : "#,#", 1 : column.format)
						}
						Set valueFmt = ..FormatNumber(footerValue,format)

						// clip box for footer
						Set svg = ##class(node).newElementSVG("svg")
						do this.svgGroup.appendChild(svg)
						Set footerBoxes(c) = svg

						Set footer = ##class(node).newElementSVG("text")
						do footer.setAttribute("class",$s(this.cardSize="big" : "scoreCardLabelBig", 1 : "scoreCardLabel"))
						do footer.setAttribute("y",(rowHeight*0.75))
						do footer.setAttribute("x","95%")
						if (align="left") {
							do footer.setAttribute("x","5%")
							do footer.setAttribute("text-anchor","start")
						}
						elseif (align="center") {
							do footer.setAttribute("x","50%")
							do footer.setAttribute("text-anchor","middle")
						}
						else {
							do footer.setAttribute("x","95%")
							do footer.setAttribute("text-anchor","end")
						}
						do footer.setAttribute("style","font-weight:bold;")
						//var textNode = this.document.createTextNode(valueFmt);
						//footer.appendChild(textNode);
						do footer.setText(valueFmt)
						do svg.appendChild(footer)

						Set tw = ..GetBBox(footer).width * 1.2
						// use header widths
						Set colHeaderWidths(c) = $s(('$D(colHeaderWidths(c)) || tw > colHeaderWidths(c)) : tw, 1 : colHeaderWidths(c))

						do svg.setAttribute("x",x)
						do svg.setAttribute("y",y)
						do svg.setAttribute("width",colWidth _ "px")
						do svg.setAttribute("height",rowHeight _ "px")
						do footer.setAttribute("y",rowHeight - 3)
					}
					Set x = x + $$$PARSEFLOAT(colWidth) + padding
				}
			}
			Set y = y + rowHeight
		}

		// compute column widths
		//var colWidths = new Array(..%columnDefs.length);
		for i=0:1:..%columnDefs.Size-1 {
			Set colWidths(i)=0
		}
		Set budget = width * 0.9
		Set unbudgeted = 0
		for c = 0:1:..%columnDefs.Size-1 {
			Set column = ..%columnDefs.GetAt(c+1)
			if ("hidden" = $s($isObject(column):column.display,1:"")) {
				Set colWidths(c) = 0
			}
			else {
				Set w = $$$PARSEFLOAT($s($isObject(column):column.width,1:""))
				if ($$$ISNAN(w)) {
					if ('$D(colMaxWidths(c))) {
						Set unbudgeted = unbudgeted + 1
					}
					else {
						Set w = colMaxWidths(c)
						if ($$$ISNAN(w)) {
							Set w = 0
						}
						Set w = $s(('$D(colHeaderWidths(c)) && (w<colHeaderWidths(c))) : colHeaderWidths(c), 1 : w)
						Set w = $s(w<0 : 0, 1 : w)
						Set colWidths(c) = w
						Set budget = budget - w
					}
				}
				elseif ($find($s($isObject(column):column.width,1:""),"%") > 0) {
					Set w = (w/100) * width
					Set w = $s(w<0 : 0, 1 : w)
					Set colWidths(c) = w
					Set budget = budget - w
				}
				else {
					Set w = $s(w<0 : 0, 1 : w)
					Set colWidths(c) = w
					Set budget = budget - w
				}
			}
		}
		Set budget = $s(budget < 0 : 0, 1 : budget)
		if (unbudgeted > 0) {
			for c = 0:1:..%columnDefs.Size-1 {
				if ('$D(colWidths(c))) {
					Set colWidths(c) = budget / unbudgeted
					// don"t let items be too big or too small
					Set colWidths(c) = $s((colWidths(c) < (width/3)) : colWidths(c), 1 : width/3)
					Set colWidths(c) = $s((colWidths(c) > 20) : colWidths(c), 1 : 20)
				}
			}
		}

		// adjust widths
		Set x = padding/2
		for c = 0:1:..length(.headerBoxes)-1 {
			#dim svg As node
			if (headerBoxes(c)'="") {
				Set svg = headerBoxes(c)
			} else {
				Set svg=""
			}
			if ($isObject(svg)) {
				do svg.setAttribute("x",x)

				do svg.setAttribute("width",colWidths(c))
				// fix for justify
				Set size=svg.children.Size
				
				for hn = 0:1:svg.children.Size-1 {
					Set anc = $s($isObject(svg.children.GetAt(hn+1)) : svg.children.GetAt(hn+1).getAttribute("text-anchor"), 1 : "")
					if (anc="end") {
						do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c))
					}
					elseif (anc="middle") {
						do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c)/2)
					}
				}
				
			}

			Set svg = $s($D(footerBoxes(c)) : footerBoxes(c), 1 : null)
			if ($isObject(svg)) {
				do svg.setAttribute("x",x)
				do svg.setAttribute("width",colWidths(c))

				// fix for justify
				for hn = 0:1:svg.children.Size-1 {
					Set anc = $s($isObject(svg.children.GetAt(hn+1)) : svg.children.GetAt(hn+1).getAttribute("text-anchor"), 1 : "")
					if (anc="end") {
						do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c))
					}
					elseif (anc="middle") {
						do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c)/2)
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

			if (colWidths(c) > 0) {
				Set x = x + colWidths(c) + padding
			}
		}

		for r = 0:1:..length(.rowCells)-1 {
			Set x = padding/2
			merge tRowCell=rowCells(r)
			for c = 0:1:..length(.tRowCell)-1 {
				Set svg = $g(rowCells(r,c))
				if ($isObject(svg)) {
					do svg.setAttribute("x",x)
					do svg.setAttribute("width",colWidths(c))
					// fix for right-justify
					for hn = 0:1:svg.children.Size-1 {
						Set anc = $s($isObject(svg.children.GetAt(hn+1)) : svg.children.GetAt(hn+1).getAttribute("text-anchor"), 1 : "")
						if (anc="end") {
							do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c))
						}
						elseif (anc="middle") {
							do svg.children.GetAt(hn+1).setAttribute("x",colWidths(c)/2)
						}
					}
				}

				// JMD1107
				// some columns need rendering/adjusting at this point (as we know the size)
				Set column = ..%columnDefs.GetAt(c+1)
				Set colStyle = column.style
				Set display = $s($isobject(column):column.display,1:"")
				Set cellScaleX = $$$PARSEINT($g(colWidths(c)))/100
				Set align = $s($isObject(column):column.align,1:"")

				if ($D(cellInfoEx) && $D(cellInfoEx(r)) && $D(cellInfoEx(r,c))) {
					if ((display="label")||(display="value")||(display="itemNo")) {
					//case "label":
					//case "value":
					//case "itemNo":
					//default:
						// vertical align
						Set text = $g(cellInfoEx(r,c,"text"))
						Set hgt = $g(cellInfoEx(r,c,"height"))
						Set cellCaptionH = $g(cellInfoEx(r,c,"cellCaptionH"))
						Set cellCaptionH = $s(cellCaptionH : cellCaptionH, 1 : 0)
						if ((text'="") && (hgt'="")) {
							do text.setAttribute("y",(rowHeight/2)+(hgt*0.35)-(cellCaptionH/2))
						}
					} elseif (display="lamp")||(display="arrow") {
					//case "lamp":
					//case "arrow":
						// apply alignment
						Set shape = $g(cellInfoEx(r,c,"shape"))
						Set wid = $g(cellInfoEx(r,c,"width"))
						Set text = $g(cellInfoEx(r,c,"text"))
						if ((shape'="") && (wid'="")) {
							Set dx = 0
							if align="right" {
								Set dx = colWidths(c) - wid
							}
							elseif (align="center") {
								Set dx = colWidths(c)/2 - wid/2
							}
				
							do shape.setAttribute("transform","translate("_dx_",0)")
						}
					} elseif (display="trendLine") {
						// get cached values
						Set vals = $g(cellInfoEx(r,c,"vals"))
						Set path = $g(cellInfoEx(r,c,"path"))
						Set cellCaptionH = cellInfoEx(r,c,"cellCaptionH")
						Set cellScaleY = $$$PARSEINT(rowHeight-cellCaptionH)/100

						// size
						Set tlPct = $$$PARSEFLOAT(this.trendLineHeight)
						Set tlBot = 50 + (50 * tlPct)
						Set tlHeight = (100 * tlPct)

						// find range of values
						Set min = null
						Set max = null
						for j = 0:1:$LL(vals)-1 {
							Set v = $$$PARSEFLOAT($LG(vals,j+1))
							if ('$$$ISNAN(v)) {
								Set min = $s((min=null) || (v < min) : v, 1 : min)
								Set max = $s((max=null) || (v > max) : v, 1 : max)
							}
						}
						// now construct path
						Set d = ""
						if (($LL(vals) > 1) && (min'=null) && (max'=null) && (max>min)) {
							Set px = 0
							Set seg = 100 / ($LL(vals)-1)
							for j = 0:1:$LL(vals)-1 {
								Set v = $$$PARSEFLOAT($LG(vals,j+1))
								if ('$$$ISNAN(v)) {
									Set v = $$$ROUND(tlBot - (tlHeight*((v - min) / (max - min))))
									if (d = "") {
										Set d = "M " _ $$$TOFIXED(px*cellScaleX,2) _ " " _ (v*cellScaleY) _ " L"
									}
									else {
										Set d = d _ " " _ $$$TOFIXED((px*cellScaleX),2) _ " " _ (v*cellScaleY)
									}
								}
								Set px = px + seg
							}
						}
						if (($LL(vals) = 1) && (min'=null) && (max'=null) && (max>min)) {
							Set v = $$$PARSEFLOAT($LG(vals,0))  // Joe has j here but j is probably <UNDEFINED>
							if ('$$$ISNAN(v)) {
								Set v = $$$ROUND(tlBot - (tlHeight*((v - min) / (max - min))))
								Set d = "M 0 " _ (v*cellScaleY) _ " L "_(100*cellScaleX)_" " _ (v*cellScaleY)
							}
						}

						// if no data, show flatline
						if (d="") {
							Set d = "M 0 "_($$$ROUND(tlBot*cellScaleY))_" L "_(100*cellScaleX)_" "_($$$ROUND(tlBot*cellScaleY))
							do path.setAttribute("opacity",0.4)
						}
						do path.setAttribute("d",d)
					} elseif (display="trendBars") {
						// get cached values
						Set vals = $g(cellInfoEx(r,c, "vals"))
						Set cellCaptionH = $g(cellInfoEx(r,c,"cellCaptionH"))
						Set cellScaleY = $$$PARSEINT(rowHeight-cellCaptionH)/100

						// size
						Set tbPct = $$$PARSEFLOAT(this.trendBarsHeight)
						Set tbBot = 50 + (50 * tbPct)
						Set tbHeight = (100 * tbPct)

						// find range of values
						Set min = null
						Set max = null
						for j = 0:1:$LL(vals)-1 {
							Set v = $$$PARSEFLOAT($LG(vals,j+1))
							if ('$$$ISNAN(v)) {
								Set min = $s(min=null || v < min : v, 1: min)
								Set max = $s(max=null || v > max : v, 1: max)
							}
						}
						// now create bars
						Set d = ""
						if ($LL(vals) > 0 && (min'=null) && (max'=null) && (max>min)) {
							Set px = 0
							Set seg = 100 / $LL(vals)
							for j = 0:1:$LL(vals)-1 {
								Set v = $$$PARSEFLOAT($LG(vals,j+1))
								
								if ('$$$ISNAN(v)) {
									Set v = $$$ROUND(tbBot - (tbHeight*((v - min) / (max - min))))

									Set bar = ##class(node).newElementSVG("rect")
									do bar.setAttribute("class","scoreCardTrendBars")
									do bar.setAttribute("style",this.trendBarsStyle _ colStyle)

									do bar.setAttribute("x",$$$ROUND(px*cellScaleX))
									do bar.setAttribute("y",$$$ROUND(v*cellScaleY))
									do bar.setAttribute("width",$$$ROUND(seg*cellScaleX) - $s(seg>2:2,1:0))
									Set bh = tbHeight-v
									// !!! negative bars
									Set bh = $s(bh<0 : 0, 1 : bh)
									do bar.setAttribute("height",$$$ROUND(bh*cellScaleY)+0.5)
									do svg.appendChild(bar)
								}
								Set px = px + seg
							}
						}

					} elseif (display="plotBox") {
						// get cached values
						Set innerX = $g(cellInfoEx(r,c,"innerX"))
						Set middleX = $g(cellInfoEx(r,c,"middleX"))
						Set outerX = $g(cellInfoEx(r,c,"outerX"))
						Set targetX = $g(cellInfoEx(r,c,"targetX"))
						Set valueX1 = $g(cellInfoEx(r,c,"valueX1"))
						Set valueX2 = $g(cellInfoEx(r,c,"valueX2"))
						Set eventHandler = $g(cellInfoEx(r,c,"eventHandler"))
						Set cellCaptionH = $g(cellInfoEx(r,c,"cellCaptionH"))

						Set cellScaleY = $$$PARSEINT(rowHeight-cellCaptionH)/100

						Set boxPct = $$$PARSEFLOAT(this.plotBoxHeight)
						Set boxTop = 50 - (50 * boxPct)
						Set boxHeight = (100 * boxPct)

						Set outerBox = ##class(node).newElementSVG("rect")
						do outerBox.setAttribute("class","scoreCardPlotBoxOuter")
						do outerBox.setAttribute("style",this.plotBoxStyle)
						do outerBox.setAttribute("x",$$$ROUND(0*cellScaleX))
						do outerBox.setAttribute("y",$$$ROUND(boxTop*cellScaleY))
						do outerBox.setAttribute("width",$$$ROUND(outerX*cellScaleX))
						do outerBox.setAttribute("height",$$$ROUND(boxHeight*cellScaleY))
						do svg.appendChild(outerBox)

						//outerBox.addEventListener("click",eventHandler,false);

						if (middleX > 0) {
							Set middleBox = ##class(node).newElementSVG("rect")
							do middleBox.setAttribute("class","scoreCardPlotBoxMiddle")
							do middleBox.setAttribute("style",this.plotBoxMidStyle)
							do middleBox.setAttribute("x",$$$ROUND(innerX*cellScaleX))
							do middleBox.setAttribute("y",$$$ROUND(boxTop*cellScaleY))
							do middleBox.setAttribute("width",$$$ROUND((middleX - innerX)*cellScaleX))
							do middleBox.setAttribute("height",$$$ROUND(boxHeight*cellScaleY))
							do svg.appendChild(middleBox)
							//middleBox.addEventListener("click",eventHandler,false);
						}

						if (innerX > 0) {
							Set innerBox = ##class(node).newElementSVG("rect")
							do innerBox.setAttribute("class","scoreCardPlotBoxInner")
							do innerBox.setAttribute("style",this.plotBoxLowerStyle)
							do innerBox.setAttribute("x",0)
							do innerBox.setAttribute("y",$$$ROUND(boxTop*cellScaleY))
							do innerBox.setAttribute("width",$$$ROUND(innerX*cellScaleX))
							do innerBox.setAttribute("height",$$$ROUND(boxHeight*cellScaleY))
							do svg.appendChild(innerBox)
							//innerBox.addEventListener("click",eventHandler,false);
						}

						if ((valueX2 >= 0) && (valueX1 <= 100)) {
							Set valueBox = ##class(node).newElementSVG("path")
							do valueBox.setAttribute("class","scoreCardPlotBoxValue")
							if (valueX2 >= valueX1) {
								do valueBox.setAttribute("style",this.plotBoxValueStyle _ colStyle)
							}
							else {
								do valueBox.setAttribute("style",this.plotBoxValueStyleNeg _ colStyle)
							}

							Set vboxPct = $$$PARSEFLOAT(this.plotBoxValueHeight)
							Set vboxTop = 50 - (50 * vboxPct)
							Set vboxBottom = 50 + (50 * vboxPct)
							Set valueX1 = $s(valueX1 < 0 : 0, 1 : valueX1)
							if (valueX2 > outerX) {
								// add jagged edge to the end
								Set d = "M "_$$$ROUND(valueX1*cellScaleX)_" "_$$$ROUND(vboxTop*cellScaleY)_" L "_$$$ROUND((outerX+4)*cellScaleX)_" "_$$$ROUND(vboxTop*cellScaleY)_" "_$$$ROUND((outerX+2)*cellScaleX)_" "_$$$ROUND(50*cellScaleY)_" "_$$$ROUND((outerX+4)*cellScaleX)_" "_$$$ROUND(50*cellScaleY)_" "_$$$ROUND((outerX+2)*cellScaleX)_" "_$$$ROUND(vboxBottom*cellScaleY)_" "_$$$ROUND(valueX1*cellScaleX)_" "_$$$ROUND(vboxBottom*cellScaleY)_" z"
							}
							else {
								Set d = "M "_$$$ROUND(valueX1*cellScaleX)_" "_$$$ROUND(vboxTop*cellScaleY)_" L "_$$$ROUND(valueX2*cellScaleX)_" "_$$$ROUND(vboxTop*cellScaleY)_" "_$$$ROUND(valueX2*cellScaleX)_" "_$$$ROUND(vboxBottom*cellScaleY)_" "_$$$ROUND(valueX1*cellScaleX)_" "_$$$ROUND(vboxBottom*cellScaleY)_" z"
							}
							do valueBox.setAttribute("d",d)
							do svg.appendChild(valueBox)
							//valueBox.addEventListener("click",eventHandler,false);
						}
						if (targetX > 0) {
							Set target = ##class(node).newElementSVG("line")
							do target.setAttribute("class","scoreCardPlotBoxTarget")
							do target.setAttribute("style",this.targetLineStyle)
							do target.setAttribute("x1",$$$ROUND(targetX*cellScaleX))
							do target.setAttribute("x2",$$$ROUND(targetX*cellScaleX))
							do target.setAttribute("y1",$$$ROUND((boxTop+5)*cellScaleY))
							do target.setAttribute("y2",$$$ROUND((boxTop+boxHeight-5)*cellScaleY))
							do svg.appendChild(target)
						}

					} else {
						// default - copy of first if display above
						Set text = $g(cellInfoEx(r,c,"text"))
						Set hgt = $g(cellInfoEx(r,c,"height"))
						if ((text'="") && (hgt'="")) {
							do text.setAttribute("y",(rowHeight/2)+(hgt*0.35))
						}


					} // end switch(display)
				}

				// move to next column
				if (colWidths(c) > 0) {
					Set x = x + colWidths(c) + padding
				}
			}
		}
		Set this.cardHeight = y

		// place plot scales in footer, if present
		// do this last, as we know the true sizes at this point.
		if (hasScale) {
			Set x = padding/2
			for c = 0:1:..%columnDefs.Size-1 {
				Set column = ..%columnDefs.GetAt(c+1)
				if (("plotBox" = $s($isObject(column):column.display,1:"")) && $D(plotMinValues(c)) && $D(plotMaxValues(c))) {
					Set scale = ##class(node).newElementSVG("path")
					do scale.setAttribute("class","scoreCardScale")
					Set sx1 = x
					Set sx2 = x + (colWidths(c)*0.95)
					Set sy1 = y - rowHeight + 2
					Set sy2 = y - rowHeight + 8
					Set baseValue = $s($D(plotBaseValues(c)) : plotBaseValues(c), 1 : "")
					Set sxb = ""
					if ("" '= baseValue) {
						Set sxb = x + ((baseValue-plotMinValues(c))/(plotMaxValues(c)-plotMinValues(c))*(colWidths(c)*0.95))
					}

					Set path = "M " _ sx1 _ " " _ sy1 _ " L " _ sx2 _ " " _ sy1
					// ticks
					Set path = path _ "M " _ sx1 _ " " _ sy1 _ " L " _ sx1 _ " " _ sy2
					Set path = path _ "M " _ sx2 _ " " _ sy1 _ " L " _ sx2 _ " " _ sy2
					if (""'=sxb) {
						Set path = path _ "M " _ sxb _ " " _ sy1 _ " L " _ sxb _ " " _ sy2
					}
					else {
						for t = 1:1:4-1 {
							Set tx = (sx2-sx1) * (t/4) + sx1
							Set path = path _ "M " _ tx _ " " _ sy1 _ " L " _ tx _ " " _ sy2
						}
					}

					do scale.setAttribute("d",path)
					do this.svgGroup.appendChild(scale)

					// labels
					Set format = $s(""=$s($isObject(column):column.format,1:"") : "#,#", 1 : column.format)
					Set minv = ..FormatNumber(plotMinValues(c),format)
					Set maxv = ..FormatNumber(plotMaxValues(c),format)

					if (""=baseValue) {
						//var lt = [{x:sx1,text:minv},{x:sx2,text:maxv}];
						Set length=2
						Set lt(0,"x")=sx1
						Set lt(0,"text")=minv
						Set lt(1,"x")=sx2
						Set lt(1,"text")=maxv
					}
					else {
						Set length=3
						Set basev = ..FormatNumber(baseValue,format)
						//var lt = [{x:sx1,text:minv},{x:sx2,text:maxv},{x:sxb,text:basev}];
						Set lt(0,"x")=sx1
						Set lt(0,"text")=minv
						Set lt(1,"x")=sx2
						Set lt(1,"text")=maxv
						Set lt(2,"x")=sxb
						Set lt(2,"text")=basev
					}
					for n = 0:1:length-1 {
						Set slabel = ##class(node).newElementSVG("text")
						do slabel.setAttribute("class","scoreCardScaleLabel")
						do slabel.setAttribute("text-anchor","middle")
		
						//var textNode = this.document.createTextNode(lt[n].text);
						//slabel.appendChild(textNode);
						do slabel.setText(lt(n,"text"))
						do this.svgGroup.appendChild(slabel)
						Set th = ..GetBBox(title).height
						do slabel.setAttribute("x",lt(n,"x"))
						do slabel.setAttribute("y",y - rowHeight + 17)
					}
				}
				if (colWidths(c) > 0) {
					Set x = x + colWidths(c) + padding
				}
			}
		}

		// TBD - setProperty brings in walking supers in the SVG client hierarchy of classes
		// We don't want to emulate whole hierarchy in ZR
		// Need to find another way of doing it. 08-23-2012
		//do this.setProperty("height",$s(this.cardHeight : this.cardHeight, 1 : 0))
 //}
 //catch {
		// zenExceptionHandler(ex,arguments,"Error in scoreCard.renderScoreCard");
 //}

	Set this.%dataMinValue = null
	Set this.%dataMaxValue = null
	Set this.%dataCount = null
	Set this.%dataSum = null
}

/// Given a column property, see if it is a property name and return it.
/// Otherwise return '';
Method getPropName(prop) [ Internal ]
{
	if ('$$$ISNAN($$$PARSEFLOAT(prop))) {
		quit ""
	}
	//prop = prop.toString();
	
	// !!! strip off is wrong !!!
	
	if ($e(prop)="=") {
		// strip off =	
		Set prop = $e(prop,2,*)
	}

	// see if this is a formula (crude test)
	if ($e(prop)="[") {
		Set index = $find(prop,"]")
		if (index>0) {
			Set prop = $e(prop,2,index-1)
		}
	}
	quit prop
}

/// Implementation of max() function within formulae.
/// Return max value of given property within current data set.
/// or max of values within a list of items.
Method getMaxValue(ByRef args)
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	Set max = null
	for n = 0:1:..length(.args)-1 {
		Set val = null
		Set prop = args(n)
		if ((null '= prop) && ("" '= prop)) {
			Set ident = $$$TOUPPERCASE($e(prop,2,*-1))
			if ('$$$ISNAN($$$PARSEFLOAT(prop))) {
				Set val = $$$PARSEFLOAT(prop)
			}
			elseif ((""'=ident) && $D(this.%dataMaxValue) && $D(this.%dataMaxValue(ident))) {
				Set val = this.%dataMaxValue(ident)
			}
		}
		Set max = $s(null=max : val, 1 : $s(null=val:  max, 1 : $s(max>val : max, 1 : val)))
	}
	quit $s(null'=max : max, 1 : "")
}

/// Implementation of min() function within formulae.
/// Return min value of given property within current data set.
Method getMinValue(ByRef args)
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	Set max = null

	Set min = null
	for n = 0:1:..length(.args)-1 {
		Set val = null
		Set prop = args(n)
		if ((null '= prop) && ("" '= prop)) {
			Set ident = $$$TOUPPERCASE($e(prop,2,*-1))
			if ('$$$ISNAN($$$PARSEFLOAT(prop))) {
				Set val = $$$PARSEFLOAT(prop)
			}
			elseif ((""'=ident) && $D(this.%dataMinValue) && $D(this.%dataMinValue(ident))) {
				Set val = this.%dataMinValue(ident)
			}
		}
		Set min = $s(null=min : val, 1 : $s(null=val:  min, 1 : $s(min<val : min, 1 : val)))
	}
	quit $s(null'=min : min, 1 : "")
}

/// Implementation of count() function within formulae.
/// Return count of items within current data set.
Method getCountValue(ByRef args) [ Internal ]
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	Set max = null

	Set count = 0
	for n = 0:1:..length(.args)-1 {
		Set prop = args(n)
		Set val = 0
		if ((null '= prop) && ("" '= prop)) {
			Set ident = $$$TOUPPERCASE($e(prop,2,*-1))
			if ('$$$ISNAN($$$PARSEFLOAT(prop))) {
				Set val=val+1
			}
			elseif ((""'=ident) && $D(this.%dataCount) && $D(this.%dataCount(ident))) {
				Set val = this.%dataCount(ident)
			}
		}
		Set count = count + val
	}
	quit count
}

/// Implementation of avg() function within formulae.
/// Return average of items within current data set.
Method getAvgValue(ByRef args)
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	Set max = null

	Set avg = ""
	Set count = this.getCountValue(args)
	if (count > 0) {
		Set sum = this.getSumValue(args)
		Set avg = sum / count
	}
	quit avg
}

/// Implementation of sum() function within formulae.
/// Return sum of items within current data set.
Method getSumValue(ByRef args)
{
	Set this=##this
	Set null=""
	Set true=1
	Set false=0
	Set max = null

	Set sum = 0
	for n = 0:1:..length(.args)-1 {
		Set prop = args(n)
		Set val = 0
		if ((null '= prop) && ("" '= prop)) {
			Set ident = $$$TOUPPERCASE($e(prop,2,*-1))
			if ('$$$ISNAN($$$PARSEFLOAT(prop))) {
				Set val = $$$PARSEFLOAT(prop)
			}
			elseif ((""'=ident) && $D(this.%dataSum) && $D(this.%dataSum(ident))) {
				Set val = $$$PARSEFLOAT(this.%dataSum(ident))
			}
		}
		if (null '= val) {
			Set sum = sum + val
		}
	}
	quit sum
}

/// Evaluate a value expression.
/// expr is the expression;
/// data is an array of data values subscripted by name and row;
/// r is the row.
Method evaluate(expr, ByRef data, r)
{
	Set value = ""
	//try {
		if ($e(expr)="=") {

			Set parser=##class(dsFormulaParser).%New()

			// associate local functions with parser
			// n.b. keep this list in sync with the one in %DeepSee.UI.Dialog.DashboardEditDataProperty

			Set funcSet = ##class(%ListOfObjects).%New()
			do funcSet.Insert(##class(function).%New("max", $this, "getMaxValue"))
			do funcSet.Insert(##class(function).%New("min", $this, "getMinValue"))
			do funcSet.Insert(##class(function).%New("count", $this, "getCountValue"))
			do funcSet.Insert(##class(function).%New("sum", $this, "getSumValue"))
			do funcSet.Insert(##class(function).%New("avg", $this, "getSumValue"))

			do parser.setFunctionSet(funcSet)

			// remove "=" from start of expression
			do parser.parse($e(expr,2,*))
			if (parser.errorHTML '= "") {
				Set value = $s(parser.dsFormulaLastError'="" : parser.dsFormulaLastError,1  : "error")
			}
			else {
				// make data visible
				//self._widgetData = data;
				//self._widgetRow = r;
				// Cache' runs in a process so alright to use process private global to store information shared with instance of dsFormulaParser
				merge ^||%ISC.ZENReport.ScoreCard.Data=data
				Set ^||%ISC.ZENReport.ScoreCard.Row=r
#if 0
				s t=$io u 0
				w !,"dumping data"
				zw data
				u t
				
#endif				
				// use local lookup() method to resolve identifiers
				Set lookup = ##class(function).%New("lookup",$this, "lookup")
				Set value = parser.eval(lookup)

				//self._widgetData = null;
				//self._widgetRow = null;
				kill ^||%ISC.ZENReport.ScoreCard.Data
				kill ^||%ISC.ZENReport.ScoreCard.Row
				
			}
		}
		else {
			// default (non-formula) behavior
			if ((""'=expr) && (0=expr)) {
				Set value = 0
			}
			elseif ((""""=$e(expr)) && (""""= $e(expr,*))) {
				// string literal
				Set value = $e(expr,2,*-1) // TBD - double check this computation with a test
			}
			elseif (""'=expr) {
				if ($$$ISNAN(expr)) {
					Set exprU = $$$TOUPPERCASE(expr)
					Set value = $g(data(exprU,r))
				}
				else {
					Set value = expr
				}
			}
		}
	//}
	//catch {
		//zenExceptionHandler(ex,arguments,"Error in scoreCard.evaluate");
		//throw {message:"Error in evaluate method"};
		//Set value = ""
	//}
	quit value
}

/// Lookup function for formula engine.
ClassMethod lookup(key)
{
	Set key = $$$TOUPPERCASE(key)
	// key is quoted;
	Set key = $e(key,2,*-1)
	Set r = ^||%ISC.ZENReport.ScoreCard.Row
	quit $g(^||%ISC.ZENReport.ScoreCard.Data(key,r))
}

Method getController()
{
	Set controller=""
	try {
		Set controller=##class(%ZEN.Report.reportPage).%GetComponentById(..controllerId)
		//Set ..seriesCount = controller.dataBag.seriesCount
	}
	catch {}
	quit controller
}

Method FormatNumber(value, format)
{
	if (($$$ISNAN(value)&&("" '= value)&&(0 =value)) || (""=format)) {
		quit val
	}

	quit ##class(%DeepSee.ResultSet).%FormatNumber(value,format)
}

ClassMethod length(ByRef array)
{
	Set length=0
	Set node="" for { Set node=$O(array(node)) q:node=""
		Set length=length+1
	}
	quit length
}

ClassMethod Test()
{
#if 1
	s rpt1=$zobjclassmethod("%ZEN.Report.Display.COSChart.COSScoreCard","%New")
	s Status=rpt1.GenerateReport("c:\temp\scorecard.html",1)
	i 'Status d DecomposeStatus^%apiOBJ(Status,.Err) w !,Err(Err) ;'
	w !,Status
#endif
}

}
