/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %ZEN.Utils)

/// Render a chart to PDF by using the Zen reports infrastructure.
Class %DeepSee.UI.ChartPDF Extends %ZEN.Report.reportPage [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

Parameter DEFAULTMODE = "pdf";

Parameter EMBEDXSL As BOOLEAN = 0;

/// MDX to run.
Property mdx As %ZEN.Datatype.string;

/// KPI to run.
Property kpi As %ZEN.Datatype.string;

/// Holder for chart labels.
Property axisLabels As %ZEN.Datatype.string [ MultiDimensional ];

/// Holder for DeepSee result set.
Property RS As %DeepSee.ResultSet;

/// Holder for data.
Property dataValues As %ZEN.Datatype.string [ MultiDimensional ];

/// Holder for seriesSize.
Property seriesSize As %ZEN.Datatype.integer;

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition" name='MyReport' 
call="GetTableData">
</report>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
id="report"
name='MyReport' title='Pivot Printout' style='standard'>
<document id="document" width="8.5in" height="11in" marginLeft="1.0in" marginRight="1.0in" marginTop="0.5in" marginBottom="0.5in" >
</document>
<pageheader id="pageheader" />
<pagefooter id="pagefooter" />
<body id="body">
<p id="pivotTitle"/>
<div id="pivotSubtitle"/>
<div id="date"/>
<div id="user"/>
<div id="filterDiv"/>
<div id="chartDiv"/>
</body>

</report>
}

/// Get the data, as xml, for the current query.
ClassMethod GetTableData()
{
	// Do nothing; this is a trick to get the report to work without having a query!
}

/// Return the axis labels for this chart.
Method getNames(val, yAxisNo, pChart)
{
	Quit $G(..axisLabels(val))
}

/// Return the array of data to be displayed within the chart.
Method getchartdata(ByRef var, pChart)
{
	Set tSC = $$$OK
	Try {
		
		If (..kpi'="") {
			// if we are passed a KPI, get data from it
			Set tSC = ..%GetKPIData(.tContext,.tExprParms,..kpi,.var)
			If $$$ISERR(tSC) Quit
		}
		ElseIf '$IsObject(..RS) {
			Merge var = ..dataValues
		}
		Else {
			// execute query or KPI
			Set tRS = ..RS
			Set tSC = tRS.%Execute()
			If $$$ISERR(tSC) Quit

			// get results
			Set tAxisCount = tRS.%GetAxisCount()
			Set tKey = tRS.%QueryKey

			If (tAxisCount = 0) {
				// single value answer
				Set tValue = tRS.%GetValue()
				Set var(0,0) = tValue
				Quit
			}

			For a = 1:1:tAxisCount {
				Set tAxisSize(a) = tRS.%GetAxisSize(a)
			}

			// Get row and column info
			Set tColCount = +$G(tAxisSize(1))

			// column headers
			For c=1:1:tColCount {
				Set tLabelCount = tRS.%GetOrdinalLabel(.tNames,1,c)
				Set tName = $G(tNames(1))
				Set tColNames(c) = tName
			}
		
			Set tHasRows = 1
			Set tRowCount = +$G(tAxisSize(2))
			If (tRowCount < 1) {
				Set tHasRows = 0
				Set tRowCount = 1
			}

			Kill ..axisLabels
			For r = 1:1:tRowCount {
				If (tHasRows) {
					Set tName = ""
					Set tLabelCount = tRS.%GetOrdinalLabel(.tLabels,2,r)
					For n=tLabelCount:-1:1 {
						Set tName = tName _ $S(tName="":"",1:"->")_ tLabels(n) ; JSL4185 - don't escape > since COS Charts already do XML escaping
					}
				}
				Else {
					Set tName = $$$Text("Results","%DeepSee")
				}

				Set ..axisLabels(r-1) = tName

				For c = 1:1:tColCount {
					Set tValue = $Case(tAxisCount,
						1:tRS.%GetOrdinalValue(c),
						:tRS.%GetOrdinalValue(c,r))
						Set var(c-1,r-1) = tValue
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Kill ^DeepSee.PDFError
	If $$$ISERR(tSC) {
		Set ^DeepSee.PDFError = tSC
	}
}

/// Create a chart and add it to the page.
/// 
Method %OnAfterCreateDisplay(pDisplay As %ZEN.Report.Display.report)
{
	Set tSC = $$$OK
	;Try {
		Kill ^DeepSee.LastMDXPDF

		// get context from URL params
		Do ..%GetContext(.tContext,.tParms)

		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		// data
		Set tSeriesSize = +$G(tContext("SeriesSize"))
		Set tKPI = $G(tContext("KPI"))

		If (tSeriesSize'=0) {
			Set ..seriesSize = tSeriesSize
			Set tData = $G(tContext("Data"))
			// copy data into ..dataValues
			For n=1:1:$L(tData,"^") {
				Set tSeries = (n-1)\tSeriesSize
				Set x = $P(tData,"^",n)
				Set ..dataValues(tSeries,(n-1)#tSeriesSize) = x
			}
		}
		ElseIf (tKPI '= "") {
			// see if we are passed a KPI
			Set ..kpi = tKPI
		}
		Else {
			// see if we are passed a query
			Set tMDX = $G(tContext("MDX"))
			If (tMDX'="") {
				Set tNonce = $G(tContext("NONCE"))
				;Kill:tNonce'="" $$$DeepSeeQueryNonceGLVN(tNonce) JSL4171 allow $LOG=1 to work

				Set ^DeepSee.LastMDXPDF = tMDX
				Set ..mdx = tMDX

				// create a result set and validate the query
				Set tRS = ##class(%DeepSee.ResultSet).%New()
				Set tSC = tRS.%PrepareMDX(tMDX)
				If $$$ISERR(tSC) Quit

				Set ..RS = tRS
			}
			Else {
				// no query: show error
				Set tSC = $$$ERROR($$$GeneralError,"No Query To Run")
				Quit
			}
		}

		// modify the display document
		#dim tDocument As %ZEN.Report.Display.document
	
		Set tUnits = $G(tContext("PageUnits"),"in")
		Set tDocument = ..%GetComponentById("document")
	
		;Set tDocument.orientation = $G(tContext("PageOrientation")) commented out JSL4248
	
		if ($G(tContext("PageOrientation"))'="landscape") {
			Set tDocument.width = $G(tContext("PageWidth"),"8.5")_tUnits
			Set tDocument.height = $G(tContext("PageHeight"),"11.0")_tUnits
		} else { // JSL4248
			Set tDocument.width = $G(tContext("PageHeight"),"11.0")_tUnits
			Set tDocument.height = $G(tContext("PageWidth"),"8.5")_tUnits
		}
		Set tDocument.marginLeft = $G(tContext("MarginLeft"),"1.0")_tUnits
		Set tDocument.marginRight = $G(tContext("MarginRight"),"1.0")_tUnits
		Set tDocument.marginTop = $G(tContext("MarginTop"),"1.0")_tUnits
		Set tDocument.marginBottom = $G(tContext("MarginBottom"),"1.0")_tUnits

		// modify the title and subtitle elements
		Set tTitle = ..%GetComponentById("pivotTitle")
		Set tDefFont = "Arial,SimSun"
		Set tTitle.style = "font-size:12pt;font-family:"_tDefFont_";"
		Set tText = $G(tContext("Title")) 
		Set tText=##class(%DeepSee.UserPortal.Utils).%ResolveText(tText) // JSL4232
		If (tText["{@") {
			// WAL081 & PFS -- use the parms we actually have
			Set tText = ##class(%DeepSee.UI.MDXPDF).%ParseExpr(tText,.tParms)
		}
		Set tTitle.content = tText
		Set tSubTitleContainer = ..%GetComponentById("pivotSubtitle")

		// DTB257 - Add date to chart print
		Set tShowDate = $G(tContext("ShowDate"))
		if (tShowDate = "on") {
			Set tDateDiv = ..%GetComponentById("date")
			Set tItem = ##class(%ZEN.Report.Display.item).%New()
			Set tTitle.style = "font-size:12pt;font-family:"_tDefFont_";"		// DTB293 - Add styling to chart font
			Do tDateDiv.children.Insert(tItem)
			Set tItem.value=$zdatetime($H)
		}
		// JSL4230
		Set tShowUser = $G(tContext("ShowUser"))
		if (tShowUser = "on") {
			Set tUserDiv = ..%GetComponentById("user")
			Set tItem = ##class(%ZEN.Report.Display.item).%New()
			Set tItem.style="font-size:12pt;font-family:"_tDefFont_";"
			Do tUserDiv.children.Insert(tItem)
			Set tItem.value=##class(%DeepSee.UserPortal.Utils).%ResolveText("User: ")_##class(%DeepSee.UserPortal.Utils).%GetUserName()
		}

		// modify page header element
		Set tHeader = ..%GetComponentById("pageheader")

		// modify page footer element
		Set tFooter = ..%GetComponentById("pagefooter")

		Set tItem = ##class(%ZEN.Report.Display.item).%New()
		Set tItem.value=$$$Text("Page","%DeepSee")
		Set tItem.style="font-size:6pt;text-align:center;color:#606060;padding-right:0.5em;padding-left:3.0in;font-family:"_tDefFont_";"	// DTB293
		Do tFooter.children.Insert(tItem)

		// page number
		Set tItem = ##class(%ZEN.Report.Display.item).%New()
		Set tItem.special="page-number-of"
		Set tItem.style="font-size:6pt;text-align:center;color:#606060;font-family:"_tDefFont_";"		// DTB293
		Do tFooter.children.Insert(tItem)

		Set tBody = pDisplay.children.GetAt(2)

		// get XML definition of Zen chart
		Set tChartXML = $G(tContext("XML"))

		Set tXNonce = $G(tContext("XNONCE"))
		;Kill:tXNonce'="" $$$DeepSeeQueryNonceGLVN(tXNonce) JSL4171 allow $LOG=1 to work

		// default test chart
		Set:tChartXML="" tChartXML = "<barChart title=""My Chart"" legendVisible=""false"" titleStyle=""fill:rgb(100,100,180);"" labelStyle=""font-size:5px;"" plotAreaStyle=""fill:white;"" height=""500"" width=""1000""><yAxis/></barChart>"
		Set ^DeepSee.LastChartXML = tChartXML

		// convert xml to Zen chart
		Set tSC = ..%XMLtoZenChart(tChartXML,.tZenChart)
		If $$$ISERR(tSC) Quit

		// convert zen chart to COS chart
		Set tSC = ..%ZenChartToCOS(.tZenChart,.tCOSChart)
		If $$$ISERR(tSC) Quit

		// test for non-inches
		Set tPixelsPerUnit = $S(tUnits="mm":(72*0.0393700787),1:72)
		; 1 point =  0.01388888889 inch
		; 12 points = 4.23333333 mm
		Set tLineHeight = $s(tUnits="mm":4.23333333,1:.16666666668)

		Set tChartLeft = $G(tContext("ChartLeft"))
		Set tChartRight = $G(tContext("ChartRight"))
		Set tChartTop = $G(tContext("ChartTop"))
		Set tChartBottom = $G(tContext("ChartBottom"))

		Set tAvailWidth = +tDocument.width - (+tDocument.marginLeft+tDocument.marginRight) - (+tChartLeft+tChartRight)

		Set tShowFilters = $G(tContext("ShowFilters"))
		if tShowFilters="byTitle" {
			Set includeFilterText=1 // filters are on subtitle
		} else {
			Set includeFilterText=0 // filters are in their own table
		}
		
		// Count filters since this is part of available height
		if includeFilterText=1 {
			Set tFilterCount=0
		} else {
			Set tFilterCount=0
			Set filterName="" for { Set filterName=$o(tParms("filter",filterName)) q:filterName=""
				Set tFilterCount=tFilterCount+1
			}
		}
		
		// count legends if on top or bottom since this is part of available height
		Set tLegendPos= $G(tContext("LegendPosition"))
		Set tLegendLabels=$G(tContext("LegendLabels"))
		Set tLegendTitle=$G(tContext("LegendTitle"))
		// legends - JSL4144
		// Set tLegendVisible = $s(($G(tContext("LegendPosition"))'="") && ($G(tContext("LegendPosition"))'="none"):"true",1:"false") // JSL4144
		// Set tCOSChart.legendVisible = tLegendVisible // JSL4144 commented out JSL4291
		Set tLegendColors=$G(tContext("LegendColors")) // JSL4291
		Set tCOSChart.legendLabels = tLegendLabels // JSL4144
		//Set tCOSChart.legendPosition = $G(tContext("LegendPosition"))
		Set tLegendStyle = $zcvt($G(tContext("LegendStyle")),"I","XML") // JSL4171
		Set legendBackgroundStyle=""
		Set legendLabelStyle=""
		Set sep1=""
		Set sep2=""
		Set legendFontHeight=""
		For i=1:1:$L(tLegendStyle,";") {
			Set attrpair = $P(tLegendStyle,";",i)
			Set attr=$zstrip($P(attrpair,":",1),"<>W")
			Set value=$zstrip($P(attrpair,":",2),"<>W")
			if attr="font-size" Set legendFontHeight=value
			If $e(value)="'" Set $e(value)="&apos;"
			If $e(value,*)="'" Set $e(value,$l(value))="&apos;"
			If $e(value)="""" Set $e(value)="&quot;"
			If $e(value,*)="""" Set $e(value,$l(value))="&quot;"
			If attr="color" Set attr="fill"
			If attr'="background-color" {
				Set legendLabelStyle=legendLabelStyle_sep1_attr_":"_value
				Set sep1=";"
			} else {
				Set legendBackgroundStyle=legendBackgroundStyle_sep2_"fill"_":"_value
				Set sep2=";"
			}

		}
		Set tLegendHeight=tLineHeight
		if legendFontHeight'="" {
			// font-size is in pixels according to Joe's design, there are 22 points in 29 pixels
			Set tLegendHeight=((22/29)*legendFontHeight/12)*tLineHeight*1.33 // 1.33 is a fudge factor
		}
				
		Set titleCount=2 // title and subtitle
		Set colCount=0
		if (tLegendPos="top" || (tLegendPos="bottom"))&&($L(tLegendLabels,",")>0) {
			Set tLegendCount=$L(tLegendLabels,",")
			Set rowCount = 1
			Set items = tLegendCount
			if (items > 6) {
				Set rowCount = 3
			}
			elseif (items > 3) {
				Set rowCount = 2
			}
			Set colCount = $$$CEIL(items / rowCount)

		}

		if tLegendTitle'="" {
			Set colCount=colCount+1 // legendTitle has height determined by legendStyle
		}
	
		if tShowUser="on" {
			Set titleCount = titleCount+1
		}	
		// in tAvailHeight - account for room needed by title, subtitle, filters, and legends if legends are on top or bottom
		// fudge factor - we don't know how much room will be taken up by legend word-wrap in legend table - so we stipulate a fudge factor of 2
		// filter tables can have custom table settings governing font-size, we don't currently support custom sizes in filter tables - only defaults
		Set tAvailHeight = +tDocument.height - (+tDocument.marginTop+tDocument.marginBottom) - (+tChartTop+tChartBottom) - (tFilterCount*tLineHeight)-(titleCount*tLineHeight)-(2*colCount*tLegendHeight)

		Set tCOSChart.width = tPixelsPerUnit*tAvailWidth

		// preserve screen ratio (if possible)
		Set tCOSChart.height = 1.5 * (tZenChart.height/tZenChart.width) * tCOSChart.width
		If (tCOSChart.height > (tPixelsPerUnit*tAvailHeight)) {
			Set tCOSChart.height = tPixelsPerUnit*tAvailHeight
		}
		
		// additional decoration !!!!
		Set tCOSChart.seriesColors = ""
		Set tCOSChart.dataDrivenSeriesColors = $G(tContext("DataDrivenSeriesColors")) // JSL4332
		Set tCOSChart.ongetData="getchartdata"
		
		//Set legendLabelStyle = $replace(legendLabelStyle,"'","&apos;")
		//Set legendLabelStyle = $replace(legendLabelStyle,"color","fill") ; this needs to be replaced by a better HTML to SVG parser
		Set tCOSChart.legendLabelStyle=legendLabelStyle
		Set tCOSChart.legendStyle=legendBackgroundStyle
		
		// title - JSL4146
		Set tCOSChart.seriesNames = $G(tContext("SeriesNames")) // JSL4146
				
		// axis labels
		// JSL4145 - add || pieChart to test JSL4149 - add || bullseyeChart to test JSL4151 add || treeMap
		If ((tZenChart.%IsA("%ZEN.SVGComponent.barChart")||tZenChart.%IsA("%ZEN.SVGComponent.lineChart")) && tZenChart.chartPivot)||(tZenChart.%IsA("%ZEN.SVGComponent.pieChart")||(tZenChart.%IsA("%ZEN.SVGComponent.bullseyeChart"))||(tZenChart.%IsA("%ZEN.SVGComponent.treeMapChart"))) {
			Set tCOSChart.ongetLabelY="getNames"
		}
		ElseIf (tZenChart.%IsA("%ZEN.SVGComponent.xyChart")||tZenChart.%IsA("%ZEN.SVGComponent.bubbleChart")) {
			; don't set ongetLabelXXX method // JSL4211
		}
		Else {
			Set tCOSChart.ongetLabelX="getNames"
		}
	
		Do tZenChart.XMLExportToString(.xml)

		Do tCOSChart.XMLExportToString(.xml)

		// modify table - JSL4184
		Set tFilterDiv = ..%GetComponentById("filterDiv")

		Set tShowFilters = $G(tContext("ShowFilters"))
		Set tNowDisplayFormat= $G(tContext("NowDisplayFormat")) // JSL4308
		if (tShowFilters="byTable") {		
			If $D(tParms("filter")) { ; JSL4184
				Set tFilterTable=##class(%ZEN.Report.Display.table).%New()
				Set tFilterTable.orient="row"
				Set tFilterTable.style=$G(tContext("FilterTableStyle")) 
				Set tParagraph = ##class(%ZEN.Report.Display.p).%New()
				Set tParagraph.content = $$$Text("Filter Values")
				Set tParagraph.style="font-size:6pt;font-family:"_tDefFont_";text-align:center;"		// DTB293 - Add font family
				Do tFilterDiv.children.Insert(tParagraph)
				Do tFilterDiv.children.Insert(tFilterTable)
				Set tParagraph1 = ##class(%ZEN.Report.Display.p).%New()
				Do tFilterDiv.children.Insert(tParagraph1)
			}
			
			// add filters to table - JSL4184
			Set filterName="" 
			For { 
				Set filterName=$o(tParms("filter",filterName),1,filterValue) 
				Quit:filterName=""
				
				Set tItem = ##class(%ZEN.Report.Display.item).%New()
				Set tCaption=##class(%ZEN.Report.Display.caption).%New()
				Set tCaption.style = $G(tContext("FilterTableCaptionStyle"))
				Set tCaption.value=filterName
				Do tItem.children.Insert(tCaption)
				if tNowDisplayFormat '= "" {
					Set filterValue=$replace(filterValue,":NOW",":"_$zdt($P($h,","),tNowDisplayFormat))
				}
				Set tItem.value=filterValue
				Set tItem.style=$G(tContext("FilterTableItemStyle"),"font-family:"_tDefFont_";") 	// DTB293 - Use default font
				Do tFilterTable.children.Insert(tItem)
			}
		} elseif (tShowFilters="byTitle") {
			Set includeFilterText=1
		}
		do ##class(%DeepSee.UI.MDXPDF).GetFilterText(tSubTitleContainer,.tParms, .tContext,+$g(includeFilterText))	
		Set tChartDiv = ..%GetComponentById("chartDiv")
		// add zen chart to report
		//Do tChartDiv.children.Insert(tCOSChart) ; JSL4184
		
		if (tLegendPos="right" || (tLegendPos="left"))&&($L(tLegendLabels,",")>0) { // JSL4291
			Set tChartTable = ##class(%ZEN.Report.Display.table).%New()
			
			Do tChartDiv.children.Insert(tChartTable)
		
			Set tChartInnerTable=##class(%ZEN.Report.Display.table).%New()
			Do tChartInnerTable.children.Insert(tCOSChart)
			Set tChartTable.orient="col"
	
			Set tChartInnerTable.width="75%"
			Set tCOSChart.width=tCOSChart.width * 0.75
			Set tLegendTable=##class(%ZEN.Report.Display.table).%New()
			Set tLegendTable.width="25%"
			Set tLegendTable.orient="row"
			Set tLegendTable.staticTable=1
			//border="0" cellpadding="3" cellspacing="0"
			k removeOpacityArr
			Do ##class(%ZEN.Utils).ParseCSS(tLegendStyle,.stylearray)
			Set i="" for { Set i=$O(stylearray(i),1,attrval) q:i=""
				Set attr=$LI(attrval,1)
				Set val=$LI(attrval,2)
				Set:attr'="opacity" removeOpacityArr($i(removeOpacityArr))=stylearray(i)
			}
			Set tLegendStyleMinusOpacity = ##class(%ZEN.Utils).BuildCSSString(.removeOpacityArr)
			Set tLegendTable.style="background:white;font-size:8pt;text-align:left;color:#404040;"_tLegendStyleMinusOpacity
			Set tLegendBody=##class(%ZEN.Report.Display.tbody).%New()
			if (tLegendTitle'="") { // JSL4291
				Set legendHeader=##class(%ZEN.Report.Display.thead).%New()
				Do tLegendTable.children.Insert(legendHeader)
				Set tr=##class(%ZEN.Report.Display.tr).%New()
				Do legendHeader.children.Insert(tr)
				Set thTitle=##class(%ZEN.Report.Display.th).%New()
				Set thTitle.colspan=2
				//Set thTitle.style="text-align:center;"			
				Do tr.children.Insert(thTitle)
				Set itemTitle=##class(%ZEN.Report.Display.item).%New()
				Set itemTitle.value=tLegendTitle
				Do thTitle.children.Insert(itemTitle)
		
			}
			Do tLegendTable.children.Insert(tLegendBody)			
			For itemNo=1:1:$L(tLegendLabels,",") {
				Set tr=##class(%ZEN.Report.Display.tr).%New()
				Do tLegendBody.children.Insert(tr)
				Set tdBox=##class(%ZEN.Report.Display.td).%New()
				Set color=$P(tLegendColors,";",itemNo) // JSL4291							
				Set color = ..transformColor(color)
				Set tdBox.style="border:1px solid #606060;margin:3px;font-size:0px;height:10px;background-color:"_color_";"
				Set tdBox.width=20
				Do tr.children.Insert(tdBox)
				Set itemBox=##class(%ZEN.Report.Display.item).%New()
				Set itemBox.value=" "
				Set itemBox.literalSpaces=1
				//Set itemBox.style=tdBox.style
				Set itemBox.style="background-color:"_color_";"
				Do tdBox.children.Insert(itemBox)				
				Set itemLabel=##class(%ZEN.Report.Display.item).%New()
				Set itemLabel.value=$P(tLegendLabels,",",itemNo)
				Set tdLabel=##class(%ZEN.Report.Display.td).%New()
				Do tdLabel.children.Insert(itemLabel)
				Do tr.children.Insert(tdLabel)
			}
			if (tLegendPos="right") {
				Do tChartTable.children.Insert(tChartInnerTable)
				Do tChartTable.children.Insert(tLegendTable)
			} else {
				Do tChartTable.children.Insert(tLegendTable)
				Do tChartTable.children.Insert(tChartInnerTable)
			}
		
		} elseif (tLegendPos="top" || (tLegendPos="bottom"))&&($L(tLegendLabels,",")>0) {
			Set tChartTable = ##class(%ZEN.Report.Display.table).%New()
			Do tChartDiv.children.Insert(tChartTable)
			Set tChartInnerTable=##class(%ZEN.Report.Display.table).%New()
			Do tChartInnerTable.children.Insert(tCOSChart)
			Set tChartTable.orient="row"
		
			Set tChartInnerTable.width="100%"
			Set tLegendTable=##class(%ZEN.Report.Display.table).%New()
			Set tLegendTable.width="100%"
			Set tLegendTable.orient="col"
			Set tLegendTable.staticTable=1
			k removeOpacityArr
			Do ##class(%ZEN.Utils).ParseCSS(tLegendStyle,.stylearray)
			Set i="" for { Set i=$O(stylearray(i),1,attrval) q:i=""
				Set attr=$LI(attrval,1)
				Set val=$LI(attrval,2)
				Set:attr'="opacity" removeOpacityArr($i(removeOpacityArr))=stylearray(i)
			}
			Set tLegendStyleMinusOpacity = ##class(%ZEN.Utils).BuildCSSString(.removeOpacityArr)
			Set tLegendTable.style="background:white;font-size:8pt;text-align:left;color:#404040;"_tLegendStyleMinusOpacity
			if (tLegendPos="top") {
				Do tChartTable.children.Insert(tLegendTable)			
				Do tChartTable.children.Insert(tChartInnerTable)
			} else {
				Do tChartTable.children.Insert(tChartInnerTable)
				Do tChartTable.children.Insert(tLegendTable)					
			}
			Set tLegendCount=$L(tLegendLabels,",")
			Set rowCount = 1
			Set items = tLegendCount
			if (items > 6) {
				Set rowCount = 3
			}
			elseif (items > 3) {
				Set rowCount = 2
			}
			Set colCount = $$$CEIL(items / rowCount)

			Set legendBody=##class(%ZEN.Report.Display.tbody).%New()
			;Set itemBody.orient="col"
			;Set itemBody.suppressFoTableColumn=1
			if (tLegendTitle'="") { // JSL4291
				Set legendHeader=##class(%ZEN.Report.Display.thead).%New()
				Do tLegendTable.children.Insert(legendHeader)
				Set tr=##class(%ZEN.Report.Display.tr).%New()
				Do legendHeader.children.Insert(tr)
				Set thTitle=##class(%ZEN.Report.Display.th).%New()
				Set thTitle.colspan=2
				//Set thTitle.style="text-align:center;"				
				Do tr.children.Insert(thTitle)
				Set itemTitle=##class(%ZEN.Report.Display.item).%New()
				Set itemTitle.value=tLegendTitle
				Do thTitle.children.Insert(itemTitle)
		
			}

			For i=1:1:rowCount {
				Set tr=##class(%ZEN.Report.Display.tr).%New()
				;Set tr.colspan=2
				Do legendBody.children.Insert(tr)
				for j=1:1:colCount {
					Set itemNo = ((j-1) * rowCount) + i						
					if (itemNo > items) {
						//html[html.length] = '<td colspan="2">&nbsp;</td>';
						Set tdFiller=##class(%ZEN.Report.Display.td).%New()
						Set tdFiller.colspan=2
						Set itemFiller=##class(%ZEN.Report.Display.item).%New()
						Set itemFiller.literalSpaces=1
						Set itemFiller.value=" "
						Do tdFiller.children.Insert(itemFiller)
						Do tr.children.Insert(tdFiller)
					} else {
						Set tdBox=##class(%ZEN.Report.Display.td).%New()
						Set color=$P(tLegendColors,";",itemNo) // JSL4291							
						Set color = ..transformColor(color)
						Set tdBox.style="border:1px solid #606060;margin:3px;font-size:0;height:10px;background-color:"_color_";"
						Set tdBox.width=18
						Do tr.children.Insert(tdBox)
						Set itemBox=##class(%ZEN.Report.Display.item).%New()
						//Set itemBox.style=tdBox.style
						Set itemBox.value=" "
						Set itemBox.literalSpaces=1
						Set itemBox.style="background-color:"_color_";"
						Do tdBox.children.Insert(itemBox)
						Set itemLabel=##class(%ZEN.Report.Display.item).%New()
						Set itemLabel.value=$P(tLegendLabels,",",itemNo)
						Set tdLabel=##class(%ZEN.Report.Display.td).%New()
						Do tdLabel.children.Insert(itemLabel)
						Do tr.children.Insert(tdLabel)
					}
				}	
			} // end for
			Do tLegendTable.children.Insert(legendBody)
		} else {
			Do tChartDiv.children.Insert(tCOSChart) ; JSL4184
		}
	;}
	;Catch(ex) {
	;	Set tSC = ex.AsStatus()
	;}
	
	// error reporting
	If $$$ISERR(tSC) {
		Set p = ##class(%ZEN.Report.Display.p).%New()
		Set p.content = $System.Status.GetErrorText(tSC)

		Set tBody = pDisplay.children.GetAt(2)
		Do tBody.children.Insert(p)
	}
}

/// Convert XML into a ZEN chart component.
ClassMethod %XMLtoZenChart(pXML As %String, Output pChart As %ZEN.SVGComponent.chart) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tReader = ##class(%XML.Reader).%New()
		Do tReader.OpenString(pXML)
		Set pChart = ""

		// get full list of chart classes and correlate them
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%ZEN.SVGComponent.chart")
		While (tRS.Next(.tSC)) {
			Quit:$$$ISERR(tSC)
			Set tName = $G(tRS.Data("Name"))
			Set tShortName = $P(tName,".",$L(tName,"."))
			Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
			If ('tAbstract) {
				Do tReader.Correlate(tShortName,tName)
			}
		}

		While (tReader.Next(.tChart,.tSC)) {
			Set pChart = tChart
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a Zen chart into a COS chart.
ClassMethod %ZenChartToCOS(pChart As %ZEN.SVGComponent.chart, Output pCOSChart As %ZEN.Report.Display.COSChart.cchart) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pCOSChart = ""

		// !!! make sure this is complete
		Set tClassName = $Case(pChart.%ClassName(0),
			"lineChart":"%ZEN.Report.Display.COSChart.clineChart",
			"barChart":"%ZEN.Report.Display.COSChart.cbarChart",
			"pieChart":"%ZEN.Report.Display.COSChart.cpieChart",
			"comboChart":"%ZEN.Report.Display.COSChart.ccomboChart",
			"bubbleChart":"%ZEN.Report.Display.COSChart.cbubbleChart",
			"xyChart":"%ZEN.Report.Display.COSChart.cxyChart",
			"hilowChart":"%ZEN.Report.Display.COSChart.chilowChart",
			"treeMapChart":"%ZEN.Report.Display.COSChart.ctreeMapChart",
			"diffChart":"%ZEN.Report.Display.COSChart.cdiffChart",
			"bullseyeChart":"%ZEN.Report.Display.COSChart.cbullseyeChart",
			"swirlChart":"%ZEN.Report.Display.COSChart.cswirlChart",
			:"")

		If (tClassName="") {
			Set tSC = $$$ERROR($$$GeneralError,"Unhandled Zen Chart: " _ pChart.%ClassName())
			Quit
		}
		
		Set pCOSChart = $classmethod(tClassName,"%New")
		// copy over basic attributes
		Set pCOSChart.appearance = pChart.appearance
		Set pCOSChart.autoScaleText = pChart.autoScaleText
		Set pCOSChart.axisLineStyle = pChart.axisLineStyle
		Set tAxisTitleStyle = pChart.axisTitleStyle
		k removeOpacityArr
		Do ##class(%ZEN.Utils).ParseCSS(tAxisTitleStyle,.stylearray)
		Set i="" for { Set i=$O(stylearray(i),1,attrval) q:i=""
			Set attr=$LI(attrval,1)
			Set val=$LI(attrval,2)
			Set:attr'="opacity" removeOpacityArr($i(removeOpacityArr))=stylearray(i)
		}
		Set axisTitleStyleMinusOpacity = ##class(%ZEN.Utils).BuildCSSString(.removeOpacityArr)
		Set pCOSChart.axisTitleStyle = axisTitleStyleMinusOpacity
		
		Set pCOSChart.backgroundStyle = pChart.backgroundStyle
		Set pCOSChart.bandLower = pChart.bandLower
		Set pCOSChart.bandLowerStyle = pChart.bandLowerStyle
		Set pCOSChart.bandUpper = pChart.bandUpper
		Set pCOSChart.bandUpperStyle = pChart.bandUpperStyle
		Set pCOSChart.borderOffset = pChart.borderOffset
		Set pCOSChart.borderRadius = pChart.borderRadius
		Set pCOSChart.borderStyle = pChart.borderStyle
		Set pCOSChart.gridStyle = pChart.gridStyle
		Set pCOSChart.labelStyle = pChart.labelStyle
		Set pCOSChart.labelsVisible = pChart.labelsVisible
		if (pChart.%Extends("%ZEN.SVGComponent.pieChart")) {
			Set pCOSChart.showValue = pChart.showValue
		}
		Set pCOSChart.legendHeight = pChart.legendHeight
		// Set pCOSChart.legendLabelStyle = pChart.legendLabelStyle JSL4171 - comment out
		Set pCOSChart.legendRectStyle = pChart.legendRectStyle
		Set pCOSChart.legendStyle = pChart.legendStyle 
		Set pCOSChart.legendTitle = pChart.legendTitle
		Set pCOSChart.legendVisible = pChart.legendVisible // JSL4317
		Set pCOSChart.legendWidth = pChart.legendWidth
		Set pCOSChart.legendX = pChart.legendX
		Set pCOSChart.legendY = pChart.legendY
		Set pCOSChart.lineStyle = pChart.lineStyle
		Set pCOSChart.marginBottom = pChart.marginBottom	
		Set pCOSChart.marginTop = pChart.marginTop	
		Set pCOSChart.marginRight = pChart.marginRight	
		Set pCOSChart.marginLeft = pChart.marginLeft
		Set pCOSChart.markerScale = pChart.markerScale
		Set pCOSChart.markerShapes = pChart.markerShapes
		Set pCOSChart.markerStyle = pChart.markerStyle
		Set pCOSChart.markersVisible = pChart.markersVisible
		Set pCOSChart.maxLabelLen = pChart.maxLabelLen
		Set pCOSChart.plotAreaStyle = pChart.plotAreaStyle
		Set pCOSChart.plotEdgeStyle = pChart.plotEdgeStyle
		Set pCOSChart.plotStyle = pChart.plotStyle
		Set pCOSChart.plotToEdge = pChart.plotToEdge
		Set pCOSChart.seriesColors = pChart.seriesColors
		Set pCOSChart.seriesColorScheme = pChart.seriesColorScheme
		Set pCOSChart.seriesColorsOverride = pChart.seriesColorsOverride
		Set pCOSChart.seriesYAxes = pChart.seriesYAxes
		Set pCOSChart.showMultiples = pChart.showMultiples
		Set pCOSChart.startTime = pChart.startTime
		Set pCOSChart.endTime = pChart.endTime // JSL4344
		Set pCOSChart.stripeStyle = pChart.stripeStyle
		Set pCOSChart.stripesVisible = pChart.stripesVisible
		Set pCOSChart.subtitle = pChart.subtitle
		Set pCOSChart.subtitleStyle = pChart.subtitleStyle
		Set pCOSChart.textSize = pChart.textSize
		Set pCOSChart.title = pChart.title
		Set pCOSChart.titleAlign = pChart.titleAlign
		Set pCOSChart.titleBoxStyle = pChart.titleBoxStyle
		Set pCOSChart.titleStyle = pChart.titleStyle
		Set pCOSChart.titleX = pChart.titleX
		Set pCOSChart.titleY = pChart.titleY
		Set pCOSChart.valueLabelsVisible = pChart.valueLabelsVisible
		Set pCOSChart.valueLabelStyle = pChart.valueLabelStyle
		Set pCOSChart.valueLabelFormat = pChart.valueLabelFormat
		Set pCOSChart.timeBased = pChart.timeBased // JSL4152
		Set pCOSChart.currYAxis = pChart.currYAxis // JSL4260
		Set pCOSChart.warnIfNoData = pChart.warnIfNoData // JSL4478
		Set pCOSChart.msgIfNoData = pChart.msgIfNoData // JSL4478
		//Set pCOSChart.noDataOpacity = pChart.noDataOpacity // JSL4478
		Set pCOSChart.noDataFill = pChart.noDataFill // JSL4478
		Set pCOSChart.noDataStroke = pChart.noDataStroke // JSL4478

		//Set pCOSChart.titleImage = pChart.titleImage
		//Set pCOSChart.titleImageStyle = pChart.titleImageStyle

		// size adjustments
		Set pCOSChart.markerScale = pCOSChart.markerScale * 0.5	// make markers smaller

		// default values
		Set:pCOSChart.backgroundStyle="" pCOSChart.backgroundStyle = "fill:white;"
		Set:pCOSChart.plotAreaStyle="fill:url(#glow-silverDiag);" pCOSChart.plotAreaStyle = "fill:white;"

		// axes
		If $IsObject(pChart.xAxis) {
			Set tSC = ..%ZenAxisToCOS("x",pChart.xAxis,.tCOSAxis)
			If $$$ISERR(tSC) Quit

			Set pCOSChart.xAxis = tCOSAxis
			Set tCOSAxis.parent = pCOSChart
			
			// Set:tCOSAxis.minValue="" tCOSAxis.minValue = 0 JSL4153
		}
		
		For n=1:1:pChart.yAxisList.Count() {
			Set tSC = ..%ZenAxisToCOS("y",pChart.yAxisList.GetAt(n),.tCOSAxis)
			If $$$ISERR(tSC) Quit

			Do pCOSChart.yAxisList.Insert(tCOSAxis)
			Set tCOSAxis.parent = pCOSChart

			//Set:tCOSAxis.minValue="" tCOSAxis.minValue = 0 JSL4153
		}
		
		// specialized attributes
		If (pChart.%IsA("%ZEN.SVGComponent.lineChart")||pChart.%IsA("%ZEN.SVGComponent.barChart")) {
			Set pCOSChart.chartPivot = pChart.chartPivot
			Set pCOSChart.chartStacked = pChart.chartStacked
		}
		
		If (pChart.%IsA("%ZEN.SVGComponent.lineChart")) {
			Set pCOSChart.chartFilled = pChart.chartFilled
		}

		If (pChart.%IsA("%ZEN.SVGComponent.pieChart")) {
			Set pCOSChart.plotBy = pChart.plotBy
			Set pCOSChart.pieScale = pChart.pieScale
			Set pCOSChart.showPercentage = pChart.showPercentage
			Set pCOSChart.pieHeight = pChart.pieHeight
			Set pCOSChart.holeSize = pChart.holeSize
		}

		If (pChart.%IsA("%ZEN.SVGComponent.comboChart")) {
			Set pCOSChart.seriesTypes = pChart.seriesTypes
		}
		If (pChart.%IsA("%ZEN.SVGComponent.swirlChart")) {
			// JSL4277
			Set pCOSChart.plotBy = pChart.plotBy
			Set pCOSChart.gap = pChart.gap
			Set pCOSChart.separateSeriesScale = pChart.separateSeriesScale
			Set pCOSChart.invert = pChart.invert
		}

		// !!! add more
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a Zen axis into a COS axis.
ClassMethod %ZenAxisToCOS(pWhich As %String, pAxis As %ZEN.Auxiliary.axis, Output pCOSAxis As %ZEN.Report.Display.COSChart.caxis) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pCOSAxis = ""
		If '$IsObject(pAxis) {
			Quit
		}
		Set pCOSAxis = ##class(%ZEN.Report.Display.COSChart.caxis).%New()

		// copy over basic attributes
		Set pCOSAxis.labelAngle = pAxis.labelAngle
		Set pCOSAxis.labelStyle = pAxis.labelStyle
		Set pCOSAxis.labelUnits = pAxis.labelUnits
		Set pCOSAxis.labelPosition = pAxis.labelPosition
		If (pWhich="y") {
			Set:pCOSAxis.labelPosition="" pCOSAxis.labelPosition = "left"
		}
		Else {
			Set:pCOSAxis.labelPosition="" pCOSAxis.labelPosition = "bottom"
		}
	
		Set pCOSAxis.majorGridLines = pAxis.majorGridLines
		Set pCOSAxis.majorGridStyle = pAxis.majorGridStyle
		Set pCOSAxis.majorUnits = pAxis.majorUnits
		Set pCOSAxis.maxValue = pAxis.maxValue
		Set pCOSAxis.minorGridLines = pAxis.minorGridLines
		Set pCOSAxis.minorGridStyle = pAxis.minorGridStyle
		Set pCOSAxis.minorUnits = pAxis.minorUnits
		Set pCOSAxis.minValue = pAxis.minValue
		Set pCOSAxis.title = pAxis.title
		Set pCOSAxis.axisType = pAxis.axisType ; JSL4170
		Set pCOSAxis.baseValue = pAxis.baseValue ; JSL4335
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Fill in the context array from the current URL parameters.
/// Also fill in the parameter array used to resolve expression references in %ParseExpr.
ClassMethod %GetContext(Output pContext, Output pParms)
{
	Kill pContext
	Kill pParms
	
	If $IsObject($G(%request)) {
		// chart definition
		// JMD1207 test for XML passed in via a nonce
		Set tXNonce = $G(%request.Data("XNONCE",1))
		If (tXNonce'="") {
			// (delete when we actually execute)
			Set tXML = $G($$$DeepSeeQueryNonceGLVN(tXNonce))
		}
		Else {
			Set tXML = $G(%request.Data("XML",1))
		}
		Set pContext("XNONCE") = tXNonce
		Set pContext("XML") = tXML

		// test data passed in
		Set pContext("SeriesSize") = $G(%request.Data("SERIESSIZE",1))
		Set pContext("Data") = $G(%request.Data("DATA",1))

		// JMD1207 test for query passed in via a nonce
		Set tNonce = $G(%request.Data("NONCE",1))
		If (tNonce'="") {
			// (delete when we actually execute)
			Set tMDX = $G($$$DeepSeeQueryNonceGLVN(tNonce))
		}
		Else {
			Set tMDX = $G(%request.Data("MDX",1))
			If (tMDX'="") {
				Set tMDX = ..Decrypt(tMDX)
				// convert utf-8
				Set tMDX = $ZCVT(tMDX,"I","UTF8")
			}
		}

		Set pContext("NONCE") = tNonce
		Set pContext("MDX") = tMDX

		Set pContext("KPI") = $G(%request.Data("KPI",1))

		// parse page width
		Set pContext("PageOrientation") = $G(%request.Data("ORIENTATION",1),"portrait")
		Set pContext("PageSize") = $G(%request.Data("PAGESIZE",1),"8.5x11 in")
		Set pContext("PageWidth") = $P($P(pContext("PageSize")," ",1),"x",1)
		Set pContext("PageHeight") = $P($P(pContext("PageSize")," ",1),"x",2)
		Set pContext("PageUnits") = $P(pContext("PageSize")," ",2)

		Set tDefSize = $S(pContext("PageUnits")="mm":25,1:1)

		Set pContext("MarginTop") = $G(%request.Data("MARGINTOP",1),tDefSize)
		Set pContext("MarginLeft") = $G(%request.Data("MARGINLEFT",1),tDefSize/2)
		Set pContext("MarginBottom") = $G(%request.Data("MARGINBOTTOM",1),tDefSize)
		Set pContext("MarginRight") = $G(%request.Data("MARGINRIGHT",1),tDefSize/2)

		Set pContext("ChartTop") = $G(%request.Data("CMARGINTOP",1))
		Set pContext("ChartLeft") = $G(%request.Data("CMARGINLEFT",1))
		Set pContext("ChartBottom") = $G(%request.Data("CMARGINBOTTOM",1))
		Set pContext("ChartRight") = $G(%request.Data("CMARGINRIGHT",1))

		Set pContext("Title") = $G(%request.Data("TITLE",1),"")
		Set pContext("Subtitle") = $G(%request.Data("SUBTITLE",1),"")
		Set pContext("SubtitleOn") = $G(%request.Data("PRINTSUBTITLEON",1),"on") // JSL4302		
		
		Set pContext("LegendPosition") = $G(%request.Data("LEGENDPOSITION",1),"") // JSL4144
		Set pContext("LegendLabels") = $G(%request.Data("LEGENDLABELS",1),"") // JSL4144
		Set pContext("LegendTitle") = $G(%request.Data("LEGENDTITLE",1),"") // JSL4291
		Set pContext("LegendColors") = $G(%request.Data("LEGENDCOLORS",1),"") // JSL4291
		if $G(%request.Data("LEGENDSTYLE",1),"")'="" Set pContext("LegendStyle")= ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("LEGENDSTYLE",1),"")) // JSL4171
		
		Set pContext("WidgetTitle") = $G(%request.Data("WIDGETTITLE",1),"") // JSL4146
		if $G(%request.Data("SERIESNAMES",1),"")'="" Set pContext("SeriesNames") = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("SERIESNAMES",1),"")) // JSL4146 JSL4171

		// JSL4308 - now display format
		Set pContext("NowDisplayFormat") = $G(%request.Data("NOWDISPLAYFORMAT",1))
		
		// DTB252 - Add username to chart print
		Set pContext("ShowDate")=$G(%request.Data("SHOWDATE",1),"off")
		
		// JSL4320 - show user
		Set pContext("ShowUser") = $G(%request.Data("SHOWUSER",1),"off")
		
		// JSL4332 - data-driven series colors
		Set pContext("DataDrivenSeriesColors") = $G(%request.Data("DATADRIVENSERIESCOLORS",1))
		                                                       
		// get filters
		Set pContext("ShowFilters") = $G(%request.Data("SHOWFILTERS",1),"byTable")
		Set tFilterNames = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERNAMES",1)))
		Set tFilterValues = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERVALUES",1)))

		If (tFilterNames'="") { // JSL4184
			Set pContext("FilterTableStyle")=$G(%request.Data("FILTERTABLESTYLE",1),"border:1pt solid gray;") // JSL4184
			Set pContext("FilterTableCaptionStyle")=$G(%request.Data("FILTERTABLECAPTIONSTYLE",1),"border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;font-family:Arial,SimSun;") // JSL4184, JSL4500 - add font-family
			Set pContext("FilterTableItemStyle")=$G(%request.Data("FILTERTABLEITEMSTYLE",1),"border:none;text-align:left;font-weight:normal;font-size:6pt;font-family:Arial,SimSun;") // JSL4184, JSL4500 - add font-family
			For p=1:1:$L(tFilterNames,$C(10)) {
				Set tName = $P(tFilterNames,$C(10),p)
				Set tValue = $P(tFilterValues,$C(10),p)
				If (tName'="") {
					// WAL081 & PFS -- Uppercase the filter name since this is how the comparison works
					//                 in %DeepSee.UI.MDXPDF::%ParseExpr
					Set pParms("filter",$$$UPPER(tName)) = tValue
				}
			}
		}
	}
}

/// Get data from the given KPI.
Method %GetKPIData(ByRef pContext, ByRef pParms, pKPI As %String, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pData
		Kill ..axisLabels
		
		// use a dataController to drive the KPI
		New %datacontroller
		New %page		// prevent temp components from being added to page!

		Set tDataSource = $G(%request.Data("SOURCE",1))
		Set tFilterNames = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERNAMES",1)))
		Set tFilterValues = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERVALUES",1)))

		Set tKPIName = $P(pKPI,".",1,$L(pKPI,".")-1)
		Set tCaption = ##class(%DeepSee.Utils).%GetKPICaption(tKPIName)

		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set %datacontroller = tController
		Set tController.modelClass = pKPI
		If ($P(tDataSource,".",$L(tDataSource,"."))="metric") {
			Set tController.modelId = tDataSource
			Set tController.modelClass = "Ens.BusinessMetricKPI"
		}
		ElseIf ($P(tDataSource,".",$L(tDataSource,"."))="worksheet") {
			Set tController.modelId = tDataSource
			Set tController.modelClass = "%DeepSee.KPIWorksheet"
		}
		Else {
			Set tController.modelId = ""
		}

		Set tController.criteria = ##class(%ZEN.proxyObject).%New()
		Set tCriteria = tController.criteria

		// apply filter values
		Set n = $O(%request.Data("FILTER",""))
		While (n'="") {
			Set f = $G(%request.Data("FILTER",n))
			If (f'="") {
				Set tFilterName = $P(f,":",1)
				Set tValue = $P(f,":",2,999)
				Set:tFilterName'="" $Property(tCriteria,tFilterName) = tValue
				Set:(tFilterName'="")&&(tValue'="") tFilterValues(tFilterName) = tValue
			}
			Set n = $O(%request.Data("FILTER",n))
		}

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit

		If (tController.modelError'="") {
			Set tSC = $$$ERROR($$$GeneralError,"Error getting data from KPI: "_$ZCVT(tController.modelError,"O","HTML"))
			Quit
		}

		Set tModel = tController.%model

		#; compute size/shape of columns & rows
		Set tRowCount = tController.dataBag.seriesCount
		Set tColCount = 0

		Set tColumnList = $G(%request.Data("COLUMNLIST",1))
		Set tSC = ##class(%DeepSee.Component.pivotTable).%GetKPIColumns(tController,.tColCount,.tColProps,tColumnList)
		If $$$ISERR(tSC) Quit

		Set tRowCount = $S(tRowCount>=0:tRowCount,1:1)
		Set tColCount = $S(tColCount>0:tColCount,1:1)

		// data
		For r = 1:1:tRowCount {
			Set ..axisLabels(r-1) = $G(tModel.%seriesNames(r))
			For c = 1:1:tColCount {
				Set tValue = ""
				Set tProp = $G(tColProps(c))
				If (tProp'="") {
					Set tValue = tController.dataBag.%GetValue(tProp,r)
					Set:tValue=$$$ZENMISSING tValue = ""
					
				}
				Set pData(c-1,r-1) = tValue
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $System.Security.Check("%DeepSee_Portal","USE")
}

Method transformColor(color)
{
	quit $case(color,
	 "url(#deep-silver)":"silver",
	 "url(#shade-silver)":"silver",
	 "url(#glow-silver)":"silver",
	 "url(#glow-silverHz)":"silver",
	 "url(#glow-silverDiag)":"silver",
	 "url(#deep-red)":"red",
	 "url(#shade-red)":"red",
	 "url(#glow-red)":"red",
	 "url(#glow-redHz)":"red",
	 "url(#glow-redDiag)":"red",
	 "url(#deep-green)":"green",
	 "url(#shade-green)":"green",
	 "url(#glow-green)":"green",
	 "url(#glow-greenHz)":"green",
	 "url(#glow-greenDiag)":"green",
	 "url(#deep-yellow)":"yellow",
	 "url(#shade-yellow)":"yellow",
	 "url(#glow-yellow)":"yellow",
	 "url(#glow-yellowHz)":"yellow",
	 "url(#glow-yellowDiag)":"yellow",
	 "url(#deep-blue)":"blue",
	 "url(#shade-blue)":"blue",
	 "url(#glow-blue)":"blue",
	 "url(#glow-blueHz)":"blue",
	 "url(#glow-blueDiag)":"blue",
	 "url(#deep-teal)":"teal",
	 "url(#shade-teal)":"teal",
	 "url(#glow-teal)":"teal",
	 "url(#glow-tealHz)":"teal",
	 "url(#glow-tealDiag)":"teal",
	 "url(#deep-purple)":"purple",
	 "url(#shade-purple)":"purple",
	 "url(#glow-purple)":"purple",
	 "url(#glow-purpleHz)":"purple",
	 "url(#glow-purpleDiag)":"purple",
	 "url(#deep-orange)":"orange",
	 "url(#shade-orange)":"orange",
	 "url(#glow-orange)":"orange",
	 "url(#glow-orangeHz)":"orange",
	 "url(#glow-orangeDiag)":"orange",
	 :color)
}

}
