/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %ZEN.Utils)

/// Execute an MDX query and render it to PDF by using the Zen reports infrastructure.
/// The encrypted query to process is passed in via the URL parameter MDX.
Class %DeepSee.UI.MDXPDF Extends %ZEN.Report.reportPage [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

Parameter DEFAULTMODE = "pdf";

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
name='MyReport' call="GetTableData">
</report>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
id="report"
name='MyReport' title='Pivot Printout' style='standard'>
<document id="document" width="8.5in" height="11in" marginLeft="1.0in" marginRight="1.0in" marginTop="1.0in" marginBottom="1.0in" >
</document>
<pageheader id="pageheader" />
<pagefooter id="pagefooter" />
<body>
<p id="pivotTitle"/>
<div id="pivotSubtitle"/>
<div id="date"/>
<div id="user"/>
<div id="filterDiv"/>
<div id="listingFilterDiv"/>
<group name="table1">
<item createtable="true" field="worksheet"/>
</group>
</body>

</report>
}

ClassMethod Test(pMDX As %String) [ Internal ]
{
	If '$IsObject(%request) {			// DTB191 - Initiate request objct if none exists
		Set %request = ##class(%CSP.Request).%New()
	}
	Set tSC = ..%WriteXMLForMDX(,,pMDX)		// DTB191 - Pass query through correct argument
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
}

/// Fill in the context array from the current URL parameters.
/// Also fill in the parameter array used to resolve expression references in %ParseExpr.
ClassMethod %GetContext(Output pContext, Output pParms)
{
	Kill pContext
	Kill pParms

	If $IsObject($G(%request)) {
		// JMD1197 test for query passed in via a nonce
		Set tNonce = $G(%request.Data("NONCE",1))
		If (tNonce'="") {
			// (delete when we actually execute)
			Set tMDX = $G($$$DeepSeeQueryNonceGLVN(tNonce))
		}
		Else {
			Set tMDX = $G(%request.Data("MDX",1))
			If (tMDX'="") {
				// WAL075 -- query is no longer encrypted
				//Set tMDX = ..Decrypt(tMDX)
				// WAL075 (3) -- since we didn't encrypt/decrypt we don't need to convert from UTF8 
				//Set tMDX = $ZCVT(tMDX,"I","UTF8")
			}
		}

		Set pContext("NONCE") = tNonce
		Set pContext("MDX") = tMDX
		Set pContext("KPI") = $G(%request.Data("KPI",1))
		
		// WAL104 -- determine if we are displaying a listing
		Set pContext("IsListing") = $G(%request.Data("ISLISTING",1))

		// JMD1332: Cell selection context for listing
		Set pContext("SelectedRange") = $G(%request.Data("SELECTEDRANGE",1)) 
		Set pContext("SelectedItems") = ..%FetchNoncedParmData("SELECTEDITEMS")		// DP-402876
		Set pContext("SortColumn") = $G(%request.Data("LISTINGSORTCOLUMN",1)) 
		Set pContext("SortDir") = $G(%request.Data("LISTINGSORTDIR",1)) 

		Set pContext("ShowRowTotals") = +$G(%request.Data("ROWTOTALS",1))
		Set pContext("ShowColumnTotals") = +$G(%request.Data("COLUMNTOTALS",1))
		Set pContext("RowTotalAgg") = $G(%request.Data("ROWTOTALAGG",1))
		Set pContext("ColumnTotalAgg") = $G(%request.Data("COLUMNTOTALAGG",1))

		Set pContext("RowCaption") = $G(%request.Data("ROWCAPTION",1))
		
		Set pContext("RowCaptions") = $G(%request.Data("ROWCAPTIONS",1)) // + WAL239

		Set pContext("ShowZebra") = +$G(%request.Data("ZEBRA",1))
		Set pContext("FontSize") = $G(%request.Data("FONTSIZE",1),"6pt")
		
		Set pContext("EvenRowStyle") = ..%FetchNoncedParmData("EVENROWSTYLE","")		// DP-402876
		
		Set pContext("ColumnHeaderStyle") = ..%FetchNoncedParmData("COLUMNSTYLE","")		// DP-402876
		Set pContext("RowHeaderStyle") = ..%FetchNoncedParmData("ROWSTYLE","")		// DP-402876
		Set pContext("CellStyle") = ..%FetchNoncedParmData("CELLSTYLE","")		// DP-402876

		// parse page width
		Set pContext("Orientation") = $G(%request.Data("ORIENTATION",1),"portrait") // JSL4297 - changed from PageOrientation
		Set pContext("PageSize") = $G(%request.Data("PAGESIZE",1),"8.5x11 in")
		Set pContext("PageWidth") = $P($P(pContext("PageSize")," ",1),"x",1)
		Set pContext("PageHeight") = $P($P(pContext("PageSize")," ",1),"x",2)
		Set pContext("PageUnits") = $P(pContext("PageSize")," ",2)

		Set pContext("MarginTop") = $G(%request.Data("MARGINTOP",1),"1.0")
		Set pContext("MarginLeft") = $G(%request.Data("MARGINLEFT",1),"0.5")
		Set pContext("MarginBottom") = $G(%request.Data("MARGINBOTTOM",1),"1.0")
		Set pContext("MarginRight") = $G(%request.Data("MARGINRIGHT",1),"0.5")

		Set pContext("CellWidth") = $G(%request.Data("CELLWIDTH",1),"")
		Set pContext("LabelWidth") = $G(%request.Data("LABELWIDTH",1),"")

		Set pContext("Title") = $G(%request.Data("TITLE",1),"")
		Set pContext("Subtitle") = $G(%request.Data("SUBTITLE",1),"")
		Set pContext("SubtitleOn") = $G(%request.Data("SUBTITLEON",1),"on") // JSL4302
		Set pContext("ShowUser") = $G(%request.Data("SHOWUSER",1),"off") // JSL4302

		// JSL4128 - get border styles
		// WAL100  - include font related settings
		Set pContext("BorderLeftCell") = $G(%request.Data("BORDERLEFTCELL",1))
		Set pContext("BorderRightCell") = $G(%request.Data("BORDERRIGHTCELL",1))
		Set pContext("BorderTopCell") = $G(%request.Data("BORDERTOPCELL",1))
		Set pContext("BorderBottomCell") = $G(%request.Data("BORDERBOTTOMCELL",1))
		Set pContext("FontFamilyCell") = $G(%request.Data("FONTFAMILYCELL",1))
		Set pContext("FontSizeCell") = $G(%request.Data("FONTSIZECELL",1))
		Set pContext("BorderLeftCol") = $G(%request.Data("BORDERLEFTCOL",1))
		Set pContext("BorderRightCol") = $G(%request.Data("BORDERRIGHTCOL",1))
		Set pContext("BorderTopCol") = $G(%request.Data("BORDERTOPCOL",1))
		Set pContext("BorderBottomCol") = $G(%request.Data("BORDERBOTTOMCOL",1))
		Set pContext("FontFamilyCol") = $G(%request.Data("FONTFAMILYCOL",1))
		Set pContext("FontSizeCol") = $G(%request.Data("FONTSIZECOL",1))
		Set pContext("BorderLeftRow") = $G(%request.Data("BORDERLEFTROW",1))
		Set pContext("BorderRightRow") = $G(%request.Data("BORDERRIGHTROW",1))
		Set pContext("BorderTopRow") = $G(%request.Data("BORDERTOPROW",1))
		Set pContext("BorderBottomRow") = $G(%request.Data("BORDERBOTTOMROW",1))
		Set pContext("FontFamilyRow") = $G(%request.Data("FONTFAMILYROW",1))
		Set pContext("FontSizeRow") = $G(%request.Data("FONTSIZEROW",1))

		// get filters
		Set pContext("ShowFilters") = $G(%request.Data("SHOWFILTERS",1),"byTable")
		Set tFilterNames = ..%FetchNoncedParmData("FILTERNAMES")		// DP-402876
		Set tFilterValues = ..%FetchNoncedParmData("FILTERVALUES")	// DP-402876

		// JSL4308 - now display format
		Set pContext("NowDisplayFormat") = $G(%request.Data("NOWDISPLAYFORMAT",1))
		Set tNowDisplayFormat= $G(pContext("NowDisplayFormat")) // JSL4308

		If (tFilterNames'="") {
			Set pContext("FilterTableStyle") = ..%FetchNoncedParmData("FILTERTABLESTYLE","border:1pt solid gray;font-family:Arial",.tSC) // JSL4184		// DP-402876
			Set pContext("FilterTableCaptionStyle") = ..%FetchNoncedParmData("FILTERTABLECAPTIONSTYLE","border:none;color:white;background-color:#6f6fff;text-align:left;font-weight:bold;font-size:6pt;font-family:Arial,SimSun;") // JSL4184, JSL4500 - add font-family		// DP-402876
			Set pContext("FilterTableItemStyle") = ..%FetchNoncedParmData("FILTERTABLEITEMSTYLE","border:none;text-align:left;font-weight:normal;font-size:6pt;font-family:Arial,SimSun") // JSL4184, JSL4500 - add font-family		// DP-402876
			
			Set tCubeName = ""
			If (tMDX'="") {
				// DTB155 - If this is not an MDX query then don't try to parse it
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDX(tMDX,.tQuery)		// DTB115
				Set:$IsObject(tQuery) tCubeName = tQuery.cube	
			}											
			
			For p=1:1:$L(tFilterNames,$C(10)) {
				Set tName = $P(tFilterNames,$C(10),p)
				Set tValue = $P(tFilterValues,$C(10),p)
				
				// DTB115
				// PFS034 - Compare against localized version
				If ($$$UPPER(tName)[$$$UPPER($$$Text("Selected Cell Context"))) {
					Set pParms("selectionFilter",$$$UPPER(tName)) = ""
				}
				ElseIf ($E($$$UPPER(tName),1,12)="CELL CONTEXT")&&($G(tCubeName)'="") {
					// DTB115 - "Cell Context" indicates that this is a filter imposed by the cell selection while in listing mode
					// This MDX filter needs to be transformed before it can be displayed.
					Do ##class(%DeepSee.UserPortal.Utils).%ParseCellSelectionContext(tValue,tCubeName,.tContextFilters)
					Set tName="" 
					Set tValue=""
					For f=1:1:tContextFilters {
						// PFS038 - Populate both tName and tValue and append tValue to currently existing values for the current tName
						Set tName = tName _ $S($L(tName):" / ",1:"") _ $$$UPPER($LG(tContextFilters(f),1))
						Set tValue = tValue _ $S($L(tValue):" / ",1:"") _ $$$UPPER($LG(tContextFilters(f),2))
						If '$D(tContextFilters(f,"ch")) {
							Set tCurrentVal = $G(pParms("selectionFilter",tName))
							Set pParms("selectionFilter",tName) = tCurrentVal _ $Select(tCurrentVal'="":"+ ",1:"") _ tValue
							Set tName = ""
							Set tValue=""
						}
					}
				}
				ElseIf (tName'="") {
					if tNowDisplayFormat '= "" { // JSL4308
						Set tValue=$replace(tValue,":NOW",":"_$zdt($P($h,","),tNowDisplayFormat))
					}
					// WAL081 & PFS -- add $$$UPPER
					Set pParms("filter",$$$UPPER(tName)) = tValue
				}
			}
		}
		// JSL4250 - add listing filter support
		Set pContext("ShowListingFilters")=$G(%request.Data("SHOWLISTINGFILTERS",1),"off")
		Set tListingFilters = ..%FetchNoncedParmData("LISTINGFILTERS")		// DP-402876
		if (tListingFilters'="") {
			For p=1:1:$L(tListingFilters,$C(10)) {
				Set tName = $P(tListingFilters,$C(10),p)
				If (tName'="") {
					Set pParms("listingfilter",tName) = ""
				}
			}			
		}
		Set pContext("ShowDate")=$G(%request.Data("SHOWDATE",1),"off")
		Set pContext("ShowZebraStripes")=$G(%request.Data("SHOWZEBRASTRIPES",1),"on")

		// JSL4279
		Set pContext("ListingFontSize")=$G(%request.Data("LISTINGFONTSIZE",1),"6pt")
		
		// JSL4280
		Set pContext("EvenRowStyle")=$G(%request.Data("EVENROWSTYLE",1),"")
				
	}
}

/// Get the data, as xml, for the current query.
ClassMethod GetTableData()
{
	Set tSC = $$$OK
	Try {
		Kill ^DeepSee.LastMDXPDF

		// get context from URL params
		Do ..%GetContext(.tContext,.tExprParms)

		If $D(tContext("FILEPDFROOT",1)) Quit		// DTB252 - Skip this work if simply loading a pdf

		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		// see if we are passed a KPI
		Set tKPI = $G(tContext("KPI"))
		If (tKPI '= "") {
			Set tSC = ..%WriteXMLForKPI(.tContext,.tExprParms,tKPI)
			If $$$ISERR(tSC) Quit
			Quit
		}

		// see if we are passed a query
		Set tMDX = $G(tContext("MDX"))
		If (tMDX'="") {
			Set tNonce = $G(tContext("NONCE"))
			// Kill:tNonce'="" $$$DeepSeeQueryNonceGLVN(tNonce) JSL4125

			Set ^DeepSee.LastMDXPDF = tMDX

			Set tSC = ..%WriteXMLForMDX(.tContext,.tExprParms,tMDX)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// no query: show test message
			Do ..%WriteXMLMessage("","Nothing to print")
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Write "<!-- ",$system.Status.DisplayError(tSC)," -->",!
	}
}

/// Write out the contents of an MDX query in a way that can be consumed by a Zen report.
/// <var>pMDX</var> is the query.
ClassMethod %WriteXMLForMDX(ByRef pContext, ByRef pParms, pMDX As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// execute query
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareMDX(pMDX)
		If $$$ISERR(tSC) Quit

		// see if we are passed a LISTINGNAME
		Set tListingName = $G(%request.Data("LISTINGNAME",1))
		If (tListingName '= "") {
			Set tSC = tRS.%SetListing(tListingName)
			If $$$ISERR(tSC) Quit
		}

		// override maxrows for listing query
		Set tQuery = tRS.%GetQuery()
		Set tQuery.%MaxListingRows = $G(%request.Data("MAXROWS",1),10000)
		Set tRS.listingPageSize = $G(%request.Data("MAXROWS",1),10000)

		// DP-407946 - Execute async in the backgound unless it is explicitly suppressed by the client request.
		Set tAsync = 0
		If '$D(%request.Data("ASYNC",1),tAsync)||(+$G(tAsync)) { 
			// Use a wait loop instead of the execute's wait parameter so the page can 
			// make an attempt to quit out before reaching the gateway timeout
			Set tSC = tRS.%ExecuteAsynch()
			If $$$ISERR(tSC) Quit
			
			// Calculate the max number of polling attempts 
			Set tHangTime = 0.5
			Set tMaxTries = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5)/tHangTime,1:1)
		
			Set tTries = 0
			While ( (tRS.%GetStatus(.tPercent,.tSC,.tPending)<100) && $$$ISOK(tSC) && 
					(tPercent<100) && (tTries<tMaxTries) ) {
				Hang tHangTime
				Set tTries = tTries + 1
			}
		}
		Else {
			Set tSC = tRS.%Execute()
		}
		If $$$ISERR(tSC) Quit

		If $IsObject(tRS) {
			If (tRS.%IsDrillThrough()) {
				Set tCaption = tRS.%GetCubeName()
				Set tSC = tRS.%GetListingResultSet(.tListingRS,.tListingFields)
				If $$$ISERR(tSC) Quit

				// + WAL104 -- indicate that this is a listing for %GetContext
				Set %request.Data("ISLISTING",1) = 1
				// - WAL104

				Set tSC = ..%WriteXMLForListing(.pContext,.pParms,tListingRS,tCaption,tListingFields)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tCaption = tRS.%GetCubeName()
				
				// + WAL104 -- indicate that this is not a listing for %GetContext
				Set %request.Data("ISLISTING",1) = 0
				// - WAL104
				
				Set tSC = ..%WriteXMLForPivot(.pContext,.pParms,tRS,tCaption)
				If $$$ISERR(tSC) Quit
			}
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write out result set as XML for PDF.
ClassMethod %WriteXMLForPivot(ByRef pContext, ByRef pParms, pRS As %DeepSee.ResultSet, pCaption As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// context
		Set tShowRowTotals = +$G(pContext("ShowRowTotals"))
		Set tShowColumnTotals = +$G(pContext("ShowColumnTotals"))
		Set tRowTotalAgg = $G(pContext("RowTotalAgg"))
		Set tColumnTotalAgg = $G(pContext("ColumnTotalAgg"))
		Set tZebra = +$G(pContext("ShowZebra"))
		Set tMaxRows = $G(%request.Data("MAXROWS",1)) // JSL4535

		// JMD988 Do we have cell format overrides?
		Set tHasOverride = pRS.%HasCellFormatOverride()

		Set msgRowTotal = $Case(tColumnTotalAgg,
			"avg":$$$Text("Average","%DeepSee"),
			"count":$$$Text("Count","%DeepSee"),
			"min":$$$Text("Min","%DeepSee"),
			"max":$$$Text("Max","%DeepSee"),
			"pct":$$$Text("% of Total","%DeepSee"),
			:$$$Text("Total","%DeepSee"))

		Set msgColumnTotal = $Case(tRowTotalAgg,
			"avg":$$$Text("Average","%DeepSee"),
			"count":$$$Text("Count","%DeepSee"),
			"min":$$$Text("Min","%DeepSee"),
			"max":$$$Text("Max","%DeepSee"),
			"pct":$$$Text("% of Total","%DeepSee"),
			:$$$Text("Total","%DeepSee"))

		// WAL100 -- this is where we add the new settings re font family and font size
		//           we just need to set this stuff for Cell, Row, Col
		//           Use current styles as defaults
		Set tDefFont = "Arial,SimSun"
		Set tDefFontSize = $G(pContext("FontSize"),"8pt")
		Set tCellFontFamily = $S($G(pContext("FontFamilyCell"))'="":pContext("FontFamilyCell"),1:tDefFont)
		Set tCellFontSize = $S($G(pContext("FontSizeCell"))'="":pContext("FontSizeCell"),1:tDefFontSize)
		Set tRowFontFamily = $S($G(pContext("FontFamilyRow"))'="":pContext("FontFamilyRow"),1:tDefFont)
		Set tRowFontSize = $S($G(pContext("FontSizeRow"))'="":pContext("FontSizeRow"),1:tDefFontSize)
		Set tColFontFamily = $S($G(pContext("FontFamilyCol"))'="":pContext("FontFamilyCol"),1:tDefFont)
		Set tColFontSize = $S($G(pContext("FontSizeCol"))'="":pContext("FontSizeCol"),1:tDefFontSize)
		// - WAL100
		// JSL4280
		Do ..%ParseStyle($G(pContext("EvenRowStyle")),.tEvenRowStyle)

		Do ..%ParseStyle($G(pContext("CellStyle")),.tBaseCellStyle)
		Do ..%ParseStyle($G(pContext("RowHeaderStyle")),.tBaseRowStyle)
		Do ..%ParseStyle($G(pContext("ColumnHeaderStyle")),.tBaseColStyle)

		// borders
		Set tCellBorderTop = $G(pContext("BorderTopCell"))
		Set tRowBorderTop = $G(pContext("BorderTopRow"))
		Set tColBorderTop = $G(pContext("BorderTopCol"))

		Set tCellBorderBtm = $G(pContext("BorderBottomCell"))
		Set tRowBorderBtm = $G(pContext("BorderBottomRow"))
		Set tColBorderBtm = $G(pContext("BorderBottomCol"))

		Set tCellBorderLft = $G(pContext("BorderLeftCell"))
		Set tRowBorderLft = $G(pContext("BorderLeftRow"))
		Set tColBorderLft = $G(pContext("BorderLeftCol"))

		Set tCellBorderRgt = $G(pContext("BorderRightCell"))
		Set tRowBorderRgt = $G(pContext("BorderRightRow"))
		Set tColBorderRgt = $G(pContext("BorderRightCol"))
		
		// padding
		Set tCellPaddingTop = "0.01in"
		Set tRowPaddingTop = "0.01in"
		Set tColPaddingTop = "0.03in"

		Set tCellPaddingBtm = "0.01in"
		Set tRowPaddingBtm = "0.01in"
		Set tColPaddingBtm = "0.02in"

		Set tCellPaddingLft = "0.01in"
		Set tRowPaddingLft = "0.01in"
		Set tColPaddingLft = "0.01in"

		Set tCellPaddingRgt = "0.01in"
		Set tRowPaddingRgt = "0.01in"
		Set tColPaddingRgt = "0.01in"

		// colors
		Set tCellBgColor = ""
		Set tRowBgColor = "#F8F8F8"
		Set tColBgColor = "#F8F8F8"

		Set tColAlign = "right"

		Set tOddColor = "" // JSL4281
		Set tEvenColor = $g(tEvenRowStyle("color"))

		Set tOddBgColor = ""
		Set tEvenBgColor = $g(tEvenRowStyle("background-color"),"#F8F8F8") // JSL4280

		Set tTitle = pCaption
		Set tAxisCount = pRS.%GetAxisCount()
		Set tKey = pRS.%QueryKey
		Set tDefaultFormat = pRS.%GetDefaultFormat()

		Set tVolume = 0
		For a = 1:1:tAxisCount {
			Set tAxisSize(a) = pRS.%GetAxisSize(a)
			Set tVolume = $S(tVolume=0:tAxisSize(a),1:tVolume*tAxisSize(a))
		}
		Set tColCount = +$G(tAxisSize(1))
		Set tRowCount = +$G(tAxisSize(2))
		Set tColLabelCount = 1

		For c = 1:1:tColCount {
			Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,1,c,.tFormat,.tSolveOrder,.tStyle,.tHeaderStyle)
			Set tColLabelCount = $S(tColLabelCount>tLabelCount:tColLabelCount,1:tLabelCount)
			Set tColFormat(c) = tFormat
			Set tColSolveOrder(c) = tSolveOrder
			Set tColStyle(c) = tStyle
			Set tColHeaderStyle(c) = tHeaderStyle
		}

		Set tRowLabelCount = 1
		For r = 1:1:tRowCount {
			Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r,.tFormat,.tSolveOrder,.tStyle,.tHeaderStyle)
			Set tRowLabelCount = $S(tRowLabelCount>tLabelCount:tRowLabelCount,1:tLabelCount)
		}

		Set tOrient = $G(pContext("Orientation")) // JSL4297
		Set tPageWidth = $S(tOrient="landscape":$G(pContext("PageHeight")),1:$G(pContext("PageWidth")))
		Set tTableWidth = ""
		Set tTableBorder = "0.5px solid #F0F0F0"

		// compute widths
		Set tUnits = $G(pContext("PageUnits"),"in")
		Set tMinCellWidth = 1
		If (tUnits="in") {
			Set tMinCellWidth = 0.5
		}
		ElseIf (tUnits="mm") {
			Set tMinCellWidth = 12
		}

		//Set tMarginLeft = $S(tOrient="landscape":$G(pContext("MarginTop")),1:$G(pContext("MarginLeft")))
		//Set tMarginRight = $S(tOrient="landscape":$G(pContext("MarginBottom")),1:$G(pContext("MarginRight")))
		Set tMarginLeft = $G(pContext("MarginLeft")) // JSL4297
		Set tMarginRight = $G(pContext("MarginRight")) // JSL4297
		Set tAvailWidth = tPageWidth - (tMarginLeft + tMarginRight)

		// truncate if too many columns
		Set tTruncated = 0

		If (tColCount <= 0) {
			Set tCellWidth = tMinCellWidth * 10
			Set tTableWidth = (tCellWidth * 2) _ tUnits
		}
		ElseIf ((tAvailWidth/(tColCount+tRowLabelCount)) < tMinCellWidth) {
			Set tColCount = (tAvailWidth \ tMinCellWidth) - (tRowLabelCount+tShowRowTotals)
			Set tTruncated = 1
		}

		Set tLabelWidth = $G(pContext("CellWidth"))
		Set:'$D(tCellWidth) tCellWidth = $G(pContext("LabelWidth"))
		If (tCellWidth="") {
			// find # of col labels
			//Set tAdjColCount = $S(tColCount>3:tColCount,1:3)
			Set tAdjColCount=tColCount // JSL4297 - don't make 3 the minimum
			Set tCellWidth = (tAvailWidth / (tAdjColCount + (tRowLabelCount*1.25) + $S(tShowRowTotals:1,1:0)))
			Set tCellWidth = ((tCellWidth * 100)\1)/100		// round to 2 decimal points
			Set tCellWidth = tCellWidth _ tUnits
		}
		If (tLabelWidth="") {
			Set tLabelWidth = (tCellWidth * 1.25) _ tUnits
		}

		// Caption
		Write "<table1>",!
		Write "<worksheet "_$s(tTableWidth'="":"width="""_tTableWidth_"""",1:"")_" border=""",tTableBorder,""">",!
		// Write "<title>",..%EscapeHTML(tTitle),"</title>",!

		If (tAxisCount = 0) {
			// single value answer
			Set tValue = pRS.%GetValue()
			Set tAll = $$$Text("All","%DeepSee")
			Write "<column-headers>",!
			Kill tHdrAttrs
			Merge tHdrAttrs = tBaseColStyle // WAL100 (3) -- print settings override table settings
			Set tHdrAttrs("text-align") = "right"
			Set:((tColFontSize'=tDefFontSize)||($G(tHdrAttrs("font-size"))="")) tHdrAttrs("font-size") = tColFontSize // WAL100 (4)
			Set:((tColFontFamily'=tDefFont)||($G(tHdrAttrs("font-family"))="")) tHdrAttrs("font-family") = tColFontFamily // WAL100 (4)
			//Set tHdrAttrs("font-family") = tDefFont
			Set tHdrAttrs("background-color") = tColBgColor
			Set tHdrAttrs("border-top") = tColBorderTop
			Set tHdrAttrs("border-left") = tColBorderLft
			Set tHdrAttrs("border-bottom") = tColBorderBtm
			Set tHdrAttrs("border-right") = tColBorderRgt
			Set tHdrAttrs("padding-before") = tColPaddingTop
			Set tHdrAttrs("padding-start") = tColPaddingLft
			Set tHdrAttrs("padding-after") = tColPaddingBtm
			Set tHdrAttrs("padding-end") = tColPaddingRgt

			//Merge tHdrAttrs = tBaseColStyle
			Set tHdrAttrs("column-width") = tCellWidth

			Set tHdrAttrs("column-width") = tCellWidth
			Do ..%DrawHeader(tAll,.tHdrAttrs)

			Write "</column-headers>",!
			Write "<data>",!
			Write "<row>",!
			Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tDefaultFormat,.tType,.tFormatStyle)

			Kill tCellAttrs
			Merge tCellAttrs = tBaseCellStyle  // WAL100 (3)
			Set tCellAttrs("text-align") = "right"
			// + WAL100
			Set:((tCellFontSize'=tDefFontSize)||($G(tCellAttrs("font-size"))="")) tCellAttrs("font-size") = tCellFontSize   // WAL100 (4)
			Set:((tCellFontFamily'=tDefFont)||($G(tCellAttrs("font-family"))="")) tCellAttrs("font-family") = tCellFontFamily // WAL100 (4)
			// - WAL100
			Set tCellAttrs("background-color") = tCellBgColor
			Set tCellAttrs("border-top") = tCellBorderTop
			Set tCellAttrs("border-left") = tCellBorderLft
			Set tCellAttrs("border-bottom") = tCellBorderBtm
			Set tCellAttrs("border-right") = tCellBorderRgt
			Set tCellAttrs("padding-before") = tCellPaddingTop
			Set tCellAttrs("padding-start") = tCellPaddingLft
			Set tCellAttrs("padding-after") = tCellPaddingBtm
			Set tCellAttrs("padding-end") = tCellPaddingRgt

			//Merge tCellAttrs = tBaseCellStyle
			Set tCellAttrs("column-width") = tCellWidth

			Do ..%DrawCell(tDisplay,.tCellAttrs)

			Write "</row>",!
			Write "</data>",!
			Write "</worksheet>",!
			Write "</table1>",!
			Quit
		}

		If (tVolume = 0) {
			Kill tCellAttrs
			Merge tCellAttrs = tBaseCellStyle  // WAL100 (3)
			Set tCellAttrs("text-align") = "right"
			Set:((tCellFontSize'=tDefFontSize)||($G(tCellAttrs("font-size"))="")) tCellAttrs("font-size") = tCellFontSize // WAL100 (4)
			Set:((tCellFontFamily'=tDefFont)||($G(tCellAttrs("font-family"))="")) tCellAttrs("font-family") = tCellFontFamily // WAL100 (4)
			//Set tCellAttrs("font-family") = tDefFont
			Set tCellAttrs("background-color") = tCellBgColor
			Set tCellAttrs("border-top") = tCellBorderTop
			Set tCellAttrs("border-left") = tCellBorderLft
			Set tCellAttrs("border-bottom") = tCellBorderBtm
			Set tCellAttrs("border-right") = tCellBorderRgt
			Set tCellAttrs("padding-before") = tCellPaddingTop
			Set tCellAttrs("padding-start") = tCellPaddingLft
			Set tCellAttrs("padding-after") = tCellPaddingBtm
			Set tCellAttrs("padding-end") = tCellPaddingRgt
			//Merge tCellAttrs = tBaseCellStyle

			Set tCellAttrs("column-width") = tCellWidth

			Write "<data>",!
			Write "<row>",!
			Do ..%DrawCell($$$Text("No results","%DeepSee"),.tCellAttrs)
			Write "</row>",!
			Write "</data>",!
			Write "</worksheet>",!
			Write "</table1>",!
			Quit
		}

		// Get row and column info
		Set tHasRows = 1
		If (tRowCount < 1) {
			Set tHasRows = 0
			Set tRowCount = 1
		}

		// find styles of labels
		If (tHasRows) {
			For r = 1:1:tRowCount {
				Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r,.tFormat,.tSolveOrder,.tStyle,.tHeaderStyle)
				// Set tRowLabelCount = $S(tRowLabelCount>tLabelCount:tRowLabelCount,1:tLabelCount)
				Set tRowFormat(r) = tFormat
				Set tRowSolveOrder(r) = tSolveOrder
				Set tRowStyle(r) = tStyle
				Set tRowHeaderStyle(r) = tHeaderStyle
			}
		}

		For c = 1:1:tColCount+1 {
			Set tColTotal(c) = 0
		}

		Set tRowOffset = tColLabelCount + 2
		Set tColOffset = tRowLabelCount

		// column headers
		If (tColCount > 0) {
			Kill tHdrAttrs
			Merge tHdrAttrs = tBaseColStyle  // WAL100(3)
			Set tHdrAttrs("text-align") = "right"
			// + WAL100
			Set:((tColFontSize'=tDefFontSize)||($G(tHdrAttrs("font-size"))="")) tHdrAttrs("font-size") = tColFontSize  // WAL100 (4)
			Set:((tColFontFamily'=tDefFont)||($G(tHdrAttrs("font-family"))="")) tHdrAttrs("font-family") = tColFontFamily // WAL100 (4)
			//Set tHdrAttrs("font-family") = tDefFont
			// - WAL100
			Set tHdrAttrs("background-color") = tColBgColor
			Set tHdrAttrs("border-top") = tColBorderTop
			Set tHdrAttrs("border-left") = tColBorderLft
			Set tHdrAttrs("border-bottom") = tColBorderBtm
			Set tHdrAttrs("border-right") = tColBorderRgt
			Set tHdrAttrs("padding-before") = tColPaddingTop
			Set tHdrAttrs("padding-start") = tColPaddingLft
			Set tHdrAttrs("padding-after") = tColPaddingBtm
			Set tHdrAttrs("padding-end") = tColPaddingRgt
			Set tHdrAttrs("font-weight") = "bold"

			//Merge tHdrAttrs = tBaseColStyle

			For r=tColLabelCount:-1:1 {
				Write "<column-headers>",!

				Merge tNubAttrs = tHdrAttrs
				Set tNubAttrs("text-align") = "left"
				Set tNubAttrs("font-weight") = "normal"

				//Set tRowCaption = $G(pContext("RowCaption"))
				Set tRowCaption = $G(pContext("RowCaptions")) // + WAL239
				For n=1:1:tRowLabelCount {
					// nub
					If (r=1) {
						//Do ..%DrawHeader($P(tRowCaption,"-",n),.tNubAttrs)
						Do ..%DrawHeader($P(tRowCaption,$c(10),n),.tNubAttrs) // + WAL239
					}
					Else {
						Do ..%DrawHeader("",.tNubAttrs)
					}
				}
				For c = 1:1:tColCount {
					Kill tNames
					Set tLabelCount = pRS.%GetOrdinalLabel(.tNames,1,c,,,,.tHeaderStyle)

					// JMD988 Test for format override
					If ((tAxisCount>1) && tHasOverride) {
						Set tFO = pRS.%GetCellFormatOverride(c,1)
						If (tFO="%string%") {
							Set tHeaderStyle = tHeaderStyle _ "text-align:left;"
						}
					}
					If (tHeaderStyle'="") {
						Kill tLocalHdrAttrs
						Merge tLocalHdrAttrs = tHdrAttrs
						Do ..%ParseStyle(tHeaderStyle,.tCSS)
						// more styles
						Set:$G(tCSS("color"))'="" tLocalHdrAttrs("color") = tCSS("color")
						Set:$G(tCSS("background"))'="" tLocalHdrAttrs("background-color") = tCSS("background")
						Set:$G(tCSS("text-align"))'="" tLocalHdrAttrs("text-align") = tCSS("text-align")
						Set:$G(tCSS("font-size"))'="" tLocalHdrAttrs("font-size") = tCSS("font-size")
						Set:$G(tCSS("font-style"))'="" tLocalHdrAttrs("font-style") = tCSS("font-style")
						Set:$G(tCSS("font-weight"))'="" tLocalHdrAttrs("font-weight") = tCSS("font-weight")
						Set:$G(tCSS("font-family"))'="" tLocalHdrAttrs("font-family") = tCSS("font-family")

						Do ..%DrawHeader($G(tNames(r)),.tLocalHdrAttrs)
					}
					Else {
						Do ..%DrawHeader($G(tNames(r)),.tHdrAttrs)
					}
				}
				If (tShowColumnTotals) {
					If (r>1) {
						Do ..%DrawHeader("",.tHdrAttrs)
					}
					Else {
						Set tHdrAttrs("font-weight") = "bold"
						Do ..%DrawHeader(msgColumnTotal,.tHdrAttrs)
						Kill tHdrAttrs("font-weight")
					}
				}
			}
			For r=tColLabelCount:-1:1 {
				Write "</column-headers>",!
			}
		}

		Set tGrandTotal = ""
		Write "<data>",!
		if tMaxRows'="" { // JSL4535
			Set tRowCount = tMaxRows
		}
		For r = 1:1:tRowCount {
			If (tZebra) {
				If (r#2) {
					Set tColor = tOddColor // JSL4281
					Set tRowBgColor = tOddBgColor
					Set tCellBgColor = tOddBgColor
				}
				Else {
					Set tColor = tEvenColor // JSL4281
					Set tRowBgColor = tEvenBgColor
					Set tCellBgColor = tEvenBgColor
				}
			} else {
				Set tColor=tOddColor // JSL4296
				Set tRowBgColor = tOddBgColor // JSL4296
				Set tCellBgColor = tOddBgColor // JSL4296
			}

			Write "<row>",!
			Kill tLabels
			Set tHeaderStyle = ""
			If (tHasRows) {
				Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r,,,,.tHeaderStyle)
			}
			Else {
				Set tLabels(1) = $$$Text("Results","%DeepSee")
			}
			For n=tRowLabelCount:-1:1 {
				Kill tLblAttrs
				Merge tLblAttrs = tBaseRowStyle // WAL100 (3)
				Set tLblAttrs("color") = tColor // JSL4281
				Set tLblAttrs("text-align") = "left"
				// + WAL100
				Set:((tRowFontSize'=tDefFontSize)||($G(tLblAttrs("font-size"))="")) tLblAttrs("font-size") = tRowFontSize    // WAL100 (4)
				Set:((tRowFontFamily'=tDefFont)||($G(tLblAttrs("font-family"))="")) tLblAttrs("font-family") = tRowFontFamily  // WAL100 (4)
				// - WAL100
				Set tLblAttrs("background-color") = tRowBgColor
				Set tLblAttrs("border-top") = tRowBorderTop
				Set tLblAttrs("border-left") = tRowBorderLft
				Set tLblAttrs("border-bottom") = tRowBorderBtm
				Set tLblAttrs("border-right") = tRowBorderRgt
				Set tLblAttrs("padding-before") = tRowPaddingTop
				Set tLblAttrs("padding-start") = tRowPaddingLft
				Set tLblAttrs("padding-after") = tRowPaddingBtm
				Set tLblAttrs("padding-end") = tRowPaddingRgt
				Set tLblAttrs("font-weight") = "bold"

				//Merge tLblAttrs = tBaseRowStyle

				If (tHeaderStyle'="") {
					Do ..%ParseStyle(tHeaderStyle,.tCSS)
					// more styles
					Set:$G(tCSS("color"))'="" tLblAttrs("color") = tCSS("color")
					Set:$G(tCSS("background"))'="" tLblAttrs("background-color") = tCSS("background")
					Set:$G(tCSS("text-align"))'="" tLblAttrs("text-align") = tCSS("text-align")
					Set:$G(tCSS("font-size"))'="" tLblAttrs("font-size") = tCSS("font-size")
					Set:$G(tCSS("font-style"))'="" tLblAttrs("font-style") = tCSS("font-style")
					Set:$G(tCSS("font-weight"))'="" tLblAttrs("font-weight") = tCSS("font-weight")
					Set:$G(tCSS("font-family"))'="" tLblAttrs("font-family") = tCSS("font-family")
				}

				If (tZebra&&(r#2)) {
					Set tLblAttrs("background-color") = "white"
				}
				// label width
				Set tLblAttrs("column-width") = tLabelWidth
				Do ..%DrawCell($G(tLabels(n)),.tLblAttrs)
			}

			For c = 1:1:tColCount {
				Set tValue = $Case(tAxisCount,
					1:pRS.%GetOrdinalValue(c),
					:pRS.%GetOrdinalValue(c,r))

				Set tCellStyle = ""
				If (+$G(tColSolveOrder(c))>=+$G(tRowSolveOrder(r))) {
					Set tFormat = $S($G(tColFormat(c))'="":tColFormat(c),$G(tRowFormat(r))'="":tRowFormat(r),1:tDefaultFormat)
					Set tCellStyle = $G(tRowStyle(r))_$G(tColStyle(c))
				}
				Else {
					Set tFormat = $S($G(tRowFormat(r))'="":tRowFormat(r),$G(tColFormat(c))'="":tColFormat(c),1:tDefaultFormat)
					Set tCellStyle = $G(tColStyle(c))_$G(tRowStyle(r))
				}

				// JMD988 Test for format override
				If ((tAxisCount>1) && tHasOverride) {
					Set tFO = pRS.%GetCellFormatOverride(c,r)
					Set:tFO'="" tFormat = tFO
				}

				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set align = $Case(tType,"integer":"right","date":"right","number":"right",:"left")

				Kill tCellAttrs
				Merge tCellAttrs = tBaseCellStyle // WAL100 (3)
				Set tCellAttrs("color") = tColor // JSL4281
				Set tCellAttrs("text-align") = align
				// + WAL100
				Set:((tCellFontSize'=tDefFontSize)||($G(tCellAttrs("font-size"))="")) tCellAttrs("font-size") = tCellFontSize  // WAL100 (4)
				Set:((tCellFontFamily'=tDefFont)||($G(tCellAttrs("font-family"))="")) tCellAttrs("font-family") = tCellFontFamily // WAL100 (4)
				//Set tCellAttrs("font-family") = tDefFont
				// - WAL100
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt

				//Merge tCellAttrs = tBaseCellStyle

				If (tCellStyle'="") {
					Do ..%ParseStyle(tCellStyle,.tCSS)
					Set:$G(tCSS("color"))'="" tCellAttrs("color") = tCSS("color")
					Set:$G(tCSS("background"))'="" tCellAttrs("background-color") = tCSS("background")
					Set:$G(tCSS("text-align"))'="" tCellAttrs("text-align") = tCSS("text-align")
					Set:$G(tCSS("font-size"))'="" tCellAttrs("font-size") = tCSS("font-size")
					Set:$G(tCSS("font-style"))'="" tCellAttrs("font-style") = tCSS("font-style")
					Set:$G(tCSS("font-weight"))'="" tCellAttrs("font-weight") = tCSS("font-weight")
					Set:$G(tCSS("font-family"))'="" tCellAttrs("font-family") = tCSS("font-family")
				}
				If (tZebra&&(r#2)) {
					Set tCellAttrs("background-color") = "white"
				}
				// cell width
				Set tCellAttrs("column-width") = $G(tCellWidths(c),tCellWidth)
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}

			If (tShowColumnTotals) {
				Set tFormat = $G(tRowFormat(r))
				Set:tFormat="" tFormat = tDefaultFormat
				Set tRowTotal = pRS.%GetRowTotal(r,tRowTotalAgg)
				Set tGrandTotal = tRowTotal + tGrandTotal
				If (tRowTotalAgg="pct") {
					Set tFormat = "#,#.##%"
				}
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tRowTotal,tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Merge tCellAttrs = tBaseCellStyle   // WAL100(3)
				Set tCellAttrs("text-align") = align
				// + WAL100
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tCellFontFamily
				//Set tCellAttrs("font-family") = tDefFont
				// - WAL100
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt

				//Merge tCellAttrs = tBaseCellStyle

				Set tCellStyle = $G(tRowStyle(r))
				If (tCellStyle'="") {
					Do ..%ParseStyle(tCellStyle,.tCSS)
					Set:$G(tCSS("color"))'="" tCellAttrs("color") = tCSS("color")
					Set:$G(tCSS("background"))'="" tCellAttrs("background-color") = tCSS("background")
					Set:$G(tCSS("text-align"))'="" tCellAttrs("text-align") = tCSS("text-align")
					Set:$G(tCSS("font-size"))'="" tCellAttrs("font-size") = tCSS("font-size")
					Set:$G(tCSS("font-style"))'="" tCellAttrs("font-style") = tCSS("font-style")
					Set:$G(tCSS("font-weight"))'="" tCellAttrs("font-weight") = tCSS("font-weight")
					Set:$G(tCSS("font-family"))'="" tCellAttrs("font-family") = tCSS("font-family")
				}

				// cell width
				Set tCellAttrs("column-width") = tCellWidth

				If (tZebra&&(r#2)) {
					Set tCellAttrs("background-color") = "white"
				}

				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}
			Write "</row>",!
		}

		If (tShowRowTotals) {
			If (tZebra) {
				If ((tRowCount+1)#2) {
					Set tRowBgColor = tOddBgColor
					Set tCellBgColor = tOddBgColor
				}
				Else {
					Set tRowBgColor = tEvenBgColor
					Set tCellBgColor = tEvenBgColor
				}
			}
			Write "<row>",!
			For n=1:1:tRowLabelCount {
				If (n>1) {
					Kill tLblAttrs
					Merge tLblAttrs = tBaseRowStyle  // WAL100 (3)
					Set tLblAttrs("text-align") = "left"
					Set:((tRowFontSize'=tDefFontSize)||($G(tLblAttrs("font-size"))="")) tLblAttrs("font-size") = tRowFontSize  // WAL100 (4)
					Set:((tRowFontFamily'=tDefFont)||($G(tLblAttrs("font-family"))="")) tLblAttrs("font-family") = tRowFontFamily // WAL100 (4)
					//Set tLblAttrs("font-family") = tDefFont  
					Set tLblAttrs("background-color") = tRowBgColor
					Set tLblAttrs("border-top") = tRowBorderTop
					Set tLblAttrs("border-left") = tRowBorderLft
					Set tLblAttrs("border-bottom") = tRowBorderBtm
					Set tLblAttrs("border-right") = tRowBorderRgt
					Set tLblAttrs("padding-before") = tRowPaddingTop
					Set tLblAttrs("padding-start") = tRowPaddingLft
					Set tLblAttrs("padding-after") = tRowPaddingBtm
					Set tLblAttrs("padding-end") = tRowPaddingRgt

					//Merge tLblAttrs = tBaseRowStyle
					If (tZebra&&((tRowCount+1)#2)) {
						Set tLblAttrs("background-color") = "white"
					}
					Do ..%DrawCell("",.tLblAttrs)
				}
				Else {
					Kill tLblAttrs
					Merge tLblAttrs = tBaseRowStyle // WAL100 (3)
					Set tLblAttrs("text-align") = "left"
					Set:((tRowFontSize'=tDefFontSize)||($G(tLblAttrs("font-size"))="")) tLblAttrs("font-size") = tRowFontSize  // WAL100 (4)
					Set:((tRowFontSize'=tDefFontSize)||($G(tLblAttrs("font-size"))="")) tLblAttrs("font-family") = tRowFontFamily // WAL100 (4)
					//Set tLblAttrs("font-family") = tDefFont
					Set tLblAttrs("font-weight") = "bold"
					Set tLblAttrs("background-color") = tRowBgColor
					Set tLblAttrs("border-top") = tRowBorderTop
					Set tLblAttrs("border-left") = tRowBorderLft
					Set tLblAttrs("border-bottom") = tRowBorderBtm
					Set tLblAttrs("border-right") = tRowBorderRgt
					Set tLblAttrs("padding-before") = tRowPaddingTop
					Set tLblAttrs("padding-start") = tRowPaddingLft
					Set tLblAttrs("padding-after") = tRowPaddingBtm
					Set tLblAttrs("padding-end") = tRowPaddingRgt
					//Merge tLblAttrs = tBaseRowStyle
					If (tZebra&&((tRowCount+1)#2)) {
						Set tLblAttrs("background-color") = "white"
					}
					Do ..%DrawCell(msgRowTotal,.tLblAttrs)
				}
			}
			For c = 1:1:tColCount {
				Set tFormat = $G(tRowFormat)
				Set:tFormat="" tFormat = $G(tColFormat(c))
				Set:tFormat="" tFormat = tDefaultFormat
				Set tColTotal = pRS.%GetColumnTotal(c,tColumnTotalAgg)
				If (tColumnTotalAgg="pct") {
					Set tFormat = "#,#.##%"
				}
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tColTotal,tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Merge tCellAttrs = tBaseCellStyle  // WAL100 (3)
				Set tCellAttrs("color") = tColor // JSL4281
				Set tCellAttrs("text-align") = align
				Set:((tCellFontSize'=tDefFontSize)||($G(tCellAttrs("font-size"))="")) tCellAttrs("font-size") = tCellFontSize  // WAL100 (4)
				Set:((tCellFontFamily'=tDefFont)||($G(tCellAttrs("font-family"))="")) tCellAttrs("font-family") = tCellFontFamily // WAL100 (4)
				//Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt

				//Merge tCellAttrs = tBaseCellStyle

				Set tCellStyle = $G(tColStyle(c))
				If (tCellStyle'="") {
					Do ..%ParseStyle(tCellStyle,.tCSS)
					Set:$G(tCSS("color"))'="" tCellAttrs("color") = tCSS("color")
					Set:$G(tCSS("background"))'="" tCellAttrs("background-color") = tCSS("background")
					Set:$G(tCSS("text-align"))'="" tCellAttrs("text-align") = tCSS("text-align")
					Set:$G(tCSS("font-size"))'="" tCellAttrs("font-size") = tCSS("font-size")
					Set:$G(tCSS("font-style"))'="" tCellAttrs("font-style") = tCSS("font-style")
					Set:$G(tCSS("font-weight"))'="" tCellAttrs("font-weight") = tCSS("font-weight")
					Set:$G(tCSS("font-family"))'="" tCellAttrs("font-family") = tCSS("font-family")
				}

				If (tZebra&&((tRowCount+1)#2)) {
					Set tCellAttrs("background-color") = "white"
				}
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}

			If (tShowColumnTotals) {
				Set cno = tColCount + 1
				Set tFormat = $G(tColFormat(tColCount))
				Set:$G(tFormat)="" tFormat = tDefaultFormat
				If (tRowTotalAgg="pct") {
					Set tFormat = "#,#.##%"
				}
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tGrandTotal,tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Merge tCellAttrs = tBaseCellStyle  // WAL1000 (3)
				Set tCellAttrs("color") = tColor // JSL4281				
				Set tCellAttrs("text-align") = align
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tCellFontFamily // WAL100
				//Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				//Merge tCellAttrs = tBaseCellStyle
				If (tZebra&&((tRowCount+1)#2)) {
					Set tCellAttrs("background-color") = "white"
				}
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}
			Write "</row>",!
		}
		Write "</data>",!

		Write "</worksheet>",!
		Write "</table1>",!
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write out listing results as XML for PDF
ClassMethod %WriteXMLForListing(ByRef pContext, ByRef pParms, pRS As %SQL.StatementResult, pCaption As %String = "", pListingFields As %List = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// styles
		Set tZebra = $s($G(pContext("ShowZebraStripes"))="on":1,1:0)	// always on for listing
		Set tRowNums = 1

		Do ..%ParseStyle($G(pContext("ColumnHeaderStyle")),.tBaseColStyle)

		Set tDefFont = "Arial,SimSun"
		Set tCellFontSize = $G(pContext("ListingFontSize"),"6pt")
		Set tColFontSize = $G(pContext("ListingFontSize"),"6pt")

		Set tCellColor = ""
		Set tColColor = ""

		// compute widths
		Set tOrient = $G(pContext("Orientation")) 
		Set tPageWidth = $S(tOrient="landscape":$G(pContext("PageHeight")),1:$G(pContext("PageWidth")))
		Set tUnits = $G(pContext("PageUnits"),"in")
		Set tMinCellWidth = 1

		// figure out column widths
		// fetch first row to determine header alignment
		Set tHasData = pRS.%Next(.tSC)
		If $$$ISERR(tSC) Quit
		
		// BDB413 - skip certain columns not meant for printing
		kill tSkipColumns

		// figure size for columns
		Set tColSizeTotal = $S(tRowNums:1,1:0) + 1
		Set tColumnMeta = pRS.%GetMetaData().columns
		If (pListingFields'="") {		
			Set tColCount = $LL(pListingFields)
			For c=1:1:tColCount {
				Set tColSize(c) = 1
				Set tColSizeTotal = tColSizeTotal + tColSize(c)
				
				// BDB413 - skip ___IKLINK column (stems from $$$IKLINK tag)
				set:($p($lg(pListingFields,c)," ",1)="___IKLINK") tSkipColumns(c) = ""
			}
		}
		Else {
			Set tColCount = tColumnMeta.Count()
			For c=1:1:tColCount {
				Set tColInfo = tColumnMeta.GetAt(c)
				// JMD1358: we cannot trust IsNumeric! use ODBCType
				#; type--> 2:float,4:integer,12:string,8:double ???
				Set tIsNumeric = $Case(tColInfo.ODBCType,2:1,4:1,8:1,:0)
				Set tColNumeric(c) = tIsNumeric
				If (tIsNumeric) {
					// fudge for long labels!
					If ($L(tColInfo.colName) > 6) {
						Set tColSize(c) = 2
					}
					Else {
						Set tColSize(c) = 1
					}
				}
				Else {
					If ($L(tColInfo.colName) > 6) {
						Set tColSize(c) = 2
					}
					Else {
						Set tColSize(c) = 1.5
					}
				}
				Set tColSizeTotal = tColSizeTotal + tColSize(c)
				
				// BDB413 - skip ___IKLINK column (stems from $$$IKLINK tag)
				set:($p(tColInfo.colName," ",1)="___IKLINK") tSkipColumns(c) = ""
			}
		}

		Set tMarginLeft = $S(tOrient="landscape":$G(pContext("MarginTop")),1:$G(pContext("MarginLeft")))
		Set tMarginRight = $S(tOrient="landscape":$G(pContext("MarginBottom")),1:$G(pContext("MarginRight")))
		Set tAvailWidth = tPageWidth - (tMarginLeft + tMarginRight)

		// assign widths to columns
		Set tCellWidth = (tAvailWidth / tColSizeTotal)
		Set tCellWidth = ((tCellWidth * 100)\1)/100		// round to 2 decimal points

		For c=1:1:tColCount {
			Set tColWidth(c) = tCellWidth * $G(tColSize(c),1)
		}

		// borders
		Set tCellBorderTop = $G(pContext("BorderTopCell"))
		Set tColBorderTop = $G(pContext("BorderTopCol"))

		Set tCellBorderBtm = $G(pContext("BorderBottomCell"))
		Set tColBorderBtm = $G(pContext("BorderBottomCol"))

		Set tCellBorderLft = $G(pContext("BorderLeftCell"))
		Set tColBorderLft = $G(pContext("BorderLeftCol"))

		Set tCellBorderRgt = $G(pContext("BorderRightCell"))
		Set tColBorderRgt = $G(pContext("BorderRightCol"))

		// padding
		Set tCellPaddingTop = "0.01in"
		Set tColPaddingTop = "0.03in"

		Set tCellPaddingBtm = "0.01in"
		Set tColPaddingBtm = "0.02in"

		Set tCellPaddingLft = "0.01in"
		Set tColPaddingLft = "0.01in"

		Set tCellPaddingRgt = "0.01in"
		Set tColPaddingRgt = "0.01in"

		// colors
		Set tCellBgColor = ""
		Set tColBgColor = "#F0F0F0"

		Set tColAlign = "right"

		Set tOddBgColor = ""
		Set tEvenBgColor = "#F8F8F8"

		// Caption
		Write "<table1>",!
		Write "<worksheet>",!
		// Write "<title>",..%EscapeHTML(pCaption),"</title>",!

		Kill tHdrAttrs
		Set tHdrAttrs("color") = tColColor
		Set tHdrAttrs("text-align") = "right"
		Set tHdrAttrs("font-size") = tColFontSize
		Set tHdrAttrs("font-family") = tDefFont
		Set tHdrAttrs("background-color") = tColBgColor
		Set tHdrAttrs("border-top") = tColBorderTop
		Set tHdrAttrs("border-left") = tColBorderLft
		Set tHdrAttrs("border-bottom") = tColBorderBtm
		Set tHdrAttrs("border-right") = tColBorderRgt
		Set tHdrAttrs("padding-before") = tColPaddingTop
		Set tHdrAttrs("padding-start") = tColPaddingLft
		Set tHdrAttrs("padding-after") = tColPaddingBtm
		Set tHdrAttrs("padding-end") = tColPaddingRgt
		Merge tHdrAttrs = tBaseColStyle

		// column headers
		Write "<column-headers>",!
		If (tRowNums) {
			Do ..%DrawHeader("#",.tHdrAttrs)
		}
		If (pListingFields="") {
			For c=1:1:tColCount {
				continue:$d(tSkipColumns(c))
				
				Set tValue = pRS.%GetData(c)
				// JMD1358: if we know this is non-numeric, use %string%
				Set tFormat = $S($G(tColNumeric(c))=0:"%string%",1:"")
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set align = $Case(tType,"integer":"right","date":"right","number":"right",:"left")
				Set:tDisplay["%" align="right"
				Set tHdrAttrs("text-align") = align

				Set tColInfo = tColumnMeta.GetAt(c)
				Do ..%DrawHeader(tColInfo.colName,.tHdrAttrs)
			}
		}
		Else {
			For c=1:1:tColCount {
				continue:$d(tSkipColumns(c))
				
				Set tValue = pRS.%Get($LG(pListingFields,c))
				Set tFormat = ""
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set align = $Case(tType,"integer":"right","date":"right","number":"right",:"left")
				Set:tDisplay["%" align="right"

				Set tHdrAttrs("text-align") = align
				Do ..%DrawHeader($LG(pListingFields,c),.tHdrAttrs)
			}
		}
		Write "</column-headers>",!

		Write "<data>",!
		Set r = 0
		
		If tHasData {
			While (((r=0) || pRS.%Next(.tSC))) {
				If $$$ISERR(tSC) Quit
				Set r = r+1

				If (tZebra) {
					If (r#2) {
						Set tCellBgColor = tOddBgColor
					}
					Else {
						Set tCellBgColor = tEvenBgColor
					}
				}

				Write "<row>",!
				If (tRowNums) {
					Kill tCellAttrs
					Set tCellAttrs("color") = tCellColor
					Set tCellAttrs("text-align") = "right"
					Set tCellAttrs("font-size") = tCellFontSize
					Set tCellAttrs("font-family") = tDefFont
					Set tCellAttrs("background-color") = tCellBgColor
					Set tCellAttrs("border-top") = tCellBorderTop
					Set tCellAttrs("border-left") = tCellBorderLft
					Set tCellAttrs("border-bottom") = tCellBorderBtm
					Set tCellAttrs("border-right") = tCellBorderRgt
					Set tCellAttrs("padding-before") = tCellPaddingTop
					Set tCellAttrs("padding-start") = tCellPaddingLft
					Set tCellAttrs("padding-after") = tCellPaddingBtm
					Set tCellAttrs("padding-end") = tCellPaddingRgt
					Set tCellAttrs("column-width") = (tCellWidth/2) _ tUnits
					Do ..%DrawCell($FN(r,",",0),.tCellAttrs)
				}
				For c=1:1:tColCount {
					continue:$d(tSkipColumns(c))
					
					If (pListingFields="") {
						Set tValue = pRS.%GetData(c)
					}
					Else {
						Set tValue = pRS.%Get($LG(pListingFields,c))
					}
					Set tFormat = ""
					// JMD1358: if we know this is non-numeric, use %string%
					Set tFormat = $S($G(tColNumeric(c))=0:"%string%",1:"")
					Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
					Set align = $Case(tType,"integer":"right","date":"right","number":"right",:"left")
					Set:tDisplay["%" align="right"

					Kill tCellAttrs
					Set tCellAttrs("color") = tCellColor
					Set tCellAttrs("text-align") = align
					Set tCellAttrs("font-size") = tCellFontSize
					Set tCellAttrs("font-family") = tDefFont
					Set tCellAttrs("background-color") = tCellBgColor
					Set tCellAttrs("border-top") = tCellBorderTop
					Set tCellAttrs("border-left") = tCellBorderLft
					Set tCellAttrs("border-bottom") = tCellBorderBtm
					Set tCellAttrs("border-right") = tCellBorderRgt
					Set tCellAttrs("column-width") = tColWidth(c) _ tUnits
					Set tCellAttrs("padding-before") = tCellPaddingTop
					Set tCellAttrs("padding-start") = tCellPaddingLft
					Set tCellAttrs("padding-after") = tCellPaddingBtm
					Set tCellAttrs("padding-end") = tCellPaddingRgt
					Do ..%DrawCell(tDisplay,.tCellAttrs)
				}
				Write "</row>",!
			}
		}
		Else {
			// DTB810 - There is no data in the listing. A blank row still needs to be
			// added to the table to get printing to work
			Write "<row>",!
			If (tRowNums) {
				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = "right"
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				Set tCellAttrs("column-width") = "1in"
				Do ..%DrawCell($$$Text("Listing Contains No Data","%DeepSee"),.tCellAttrs)
			}
			For c=1:1:tColCount {
				
				Set tValue = ""

				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = "right"
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("column-width") = tColWidth(c) _ tUnits
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}
			Write "</row>",!
		}

		Write "</data>",!
		Write "</worksheet>",!
		Write "</table1>",!
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write out KPI results as XML for PDF.
ClassMethod %WriteXMLForKPI(ByRef pContext, ByRef pParms, pKPI As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// context
		Set tShowRowTotals = +$G(pContext("ShowRowTotals"))
		Set tShowColumnTotals = +$G(pContext("ShowColumnTotals"))
		Set tZebra = +$G(pContext("ShowZebra"))
		//Set tZebra = 1		// DTB361

		// styles
		Set tDefFont = "Arial,SimSun"
		Set tCellFontSize = $G(pContext("FontSize"),"8pt")
		Set tRowFontSize = $G(pContext("FontSize"),"8pt")
		Set tColFontSize = $G(pContext("FontSize"),"8pt")

		Set tCellColor = ""
		Set tRowColor = ""
		Set tColColor = ""

		// borders
		// +DTB359 - Add border context from the Print Settings
		Set tCellBorderTop = $G(pContext("BorderTopCell"))
		Set tRowBorderTop = $G(pContext("BorderTopRow"))
		Set tColBorderTop = $G(pContext("BorderTopCol"))

		Set tCellBorderBtm = $G(pContext("BorderBottomCell"))
		Set tRowBorderBtm = $G(pContext("BorderBottomRow"))
		Set tColBorderBtm = $G(pContext("BorderBottomCol"))

		Set tCellBorderLft = $G(pContext("BorderLeftCell"))
		Set tRowBorderLft = $G(pContext("BorderLeftRow"))
		Set tColBorderLft = $G(pContext("BorderLeftCol"))

		Set tCellBorderRgt = $G(pContext("BorderRightCell"))
		Set tRowBorderRgt = $G(pContext("BorderRightRow"))
		Set tColBorderRgt = $G(pContext("BorderRightCol"))
		// -DTB359

		// padding
		Set tCellPaddingTop = "0.01in"
		Set tRowPaddingTop = "0.01in"
		Set tColPaddingTop = "0.03in"

		Set tCellPaddingBtm = "0.01in"
		Set tRowPaddingBtm = "0.01in"
		Set tColPaddingBtm = "0.02in"

		Set tCellPaddingLft = "0.01in"
		Set tRowPaddingLft = "0.01in"
		Set tColPaddingLft = "0.01in"

		Set tCellPaddingRgt = "0.01in"
		Set tRowPaddingRgt = "0.01in"
		Set tColPaddingRgt = "0.01in"

		// colors
		Set tCellBgColor = ""
		Set tRowBgColor = "#F0F0F0"
		Set tColBgColor = "#F0F0F0"

		Set tColAlign = "right"

		Set tOddBgColor = ""
		Set tEvenBgColor = "#F8F8F8"

		// use a dataController to drive the KPI
		New %datacontroller
		New %page		// prevent temp components from being added to page!

		Set tDataSource = $G(%request.Data("SOURCE",1))
		Set tShowFilters = $G(%request.Data("SHOWFILTERS",1),"byTable")
		Set tFilterNames = ..%FetchNoncedParmData("FILTERNAMES")		// DP-402876
		Set tFilterValues = ..%FetchNoncedParmData("FILTERVALUES")		// DP-402876

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
			Set f = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTER",n)))		// DP-412279 - Fetch from nonce global
			If (f'="") {
				Set tFilterDisplayName = $zcvt($P(f,":",1),"I","URI")
				Set tFilterLogicalName = $zcvt($P(f,":",2),"I","URI")
				Set tValue = $P(f,":",3,*)
				Set:tFilterLogicalName'="" $property(tCriteria,tFilterLogicalName) = tValue
				Set:(tFilterDisplayName'="")&&(tValue'="") tFilters(tFilterDisplayName) = tValue		// DTB214 - Distinguish between filter printing and application
			}
			Set n = $O(%request.Data("FILTER",n))
		}

		Set tListing = +$G(%request.Data("LISTING",1))
		If (tListing) {
			// KPI-based listing
			Set tListingName = ""

			// JMD1332
			Set tSelection("selectedRange") = $G(pContext("SelectedRange")) 
			Set tSelection("rowValues") = $G(pContext("SelectedItems")) 
    		Set tSelection("sortColumn") = $G(pContext("SortColumn")) 
    		Set tSelection("sortDir") = $G(pContext("SortDir")) 

			Set tSC = $classmethod(pKPI,"%GetListingResultSet",.tFilters,.tSelection,tListingName,.tListingRS)
			If $$$ISERR(tSC) Quit

			Set tSC = ..%WriteXMLForListing(.pContext,.pParms,tListingRS,tCaption)
			If $$$ISERR(tSC) Quit
			Quit
		}

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit
		
		// +DTB374
		Set tModel = tController.%model
		
		If (tModel.%IsAsync()) {
			// Watch the cache to know when results are complete. Default is 5 seconds less than the gateway timeout.
			Set tClassU = $$$UPPER(tModel.%ClassName(1))
			Set tCacheKey = tModel.%cacheKey
			If ((tClassU'="")&&(tCacheKey'="")) {
				Set tSC = $G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"error"),$$$OK)
				If $$$ISERR(tSC) Quit
				
				Set tWaitTimeout = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5),1:5)
				Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				While (tPctComplete<100)&&($G(tWait)<tWaitTimeout) {
					h 1
					Set x = $I(tWait)
					Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				}
				
				Set tSC = tController.%model.%LoadKPIFromCache()
				If $$$ISERR(tSC) Quit
				
				Set tSC = tController.%AcquireData()
				If $$$ISERR(tSC) Quit
			}
		}
		// -DTB374

		If (tController.modelError'="") {
			Do ..%WriteXMLMessage("Error getting data from KPI",$ZCVT(tController.modelError,"O","HTML"))
			Quit
		}

		#; compute size/shape of columns & rows
		Set tRowCount = tController.dataBag.seriesCount
		Set tColCount = 0

		Set tColumnList = $G(%request.Data("COLUMNLIST",1))
		Set tSC = ##class(%DeepSee.Component.pivotTable).%GetKPIColumns(tController,.tColCount,.tColProps,tColumnList)
		If $$$ISERR(tSC) Quit

		Set tRowCount = $S(tRowCount>0:tRowCount,1:1) // WAL278 && SK
		Set tColCount = $S(tColCount>0:tColCount,1:1)

		For c = 1:1:tColCount+1 {
			Set tColTotal(c) = 0
		}

		// compute widths
		Set tOrient = $G(pContext("Orientation"))
		Set tPageWidth = $S(tOrient="landscape":$G(pContext("PageHeight")),1:$G(pContext("PageWidth")))
		Set tUnits = $G(pContext("PageUnits"),"in")
		Set tMinCellWidth = 1

		// figure out column widths

		// figure size for columns
		Set tColSizeTotal = $S(tShowColumnTotals:1,1:0) + 1
		For c=1:1:tColCount {
			Set tColSize(c) = 1
			Set tColSizeTotal = tColSizeTotal + tColSize(c)
		}

		Set tMarginLeft = $S(tOrient="landscape":$G(pContext("MarginTop")),1:$G(pContext("MarginLeft")))
		Set tMarginRight = $S(tOrient="landscape":$G(pContext("MarginBottom")),1:$G(pContext("MarginRight")))
		Set tAvailWidth = tPageWidth - (tMarginLeft + tMarginRight)

		// assign widths to columns
		Set tCellWidth = (tAvailWidth / tColSizeTotal)
		Set tCellWidth = ((tCellWidth * 100)\1)/100		// round to 2 decimal points

		For c=1:1:tColCount {
			Set tColWidth(c) = tCellWidth * $G(tColSize(c),1)
		}

		// Caption
		Write "<table1>",!
		Write "<worksheet>",!
		Write "<title>",..%EscapeHTML(tCaption),"</title>",!

		Set tRowLabelCount = 1
		Set tColLabelCount = 1

		Set tDefaultFormat = ""
		Set tRowOffset = tColLabelCount + 2
		Set tColOffset = tRowLabelCount
		Set msgTotal = $$$Text("Total","%DeepSee")

		// column headers
		If (tColCount > 0) {
			Write "<column-headers>",!
			Kill tHdrAttrs
			Set tHdrAttrs("color") = tColColor
			Set tHdrAttrs("text-align") = "right"
			Set tHdrAttrs("font-size") = tColFontSize
			Set tHdrAttrs("font-family") = tDefFont
			Set tHdrAttrs("background-color") = tColBgColor
			Set tHdrAttrs("border-top") = tColBorderTop
			Set tHdrAttrs("border-left") = tColBorderLft
			Set tHdrAttrs("border-bottom") = tColBorderBtm
			Set tHdrAttrs("border-right") = tColBorderRgt
			Set tHdrAttrs("padding-before") = tColPaddingTop
			Set tHdrAttrs("padding-start") = tColPaddingLft
			Set tHdrAttrs("padding-after") = tColPaddingBtm
			Set tHdrAttrs("padding-end") = tColPaddingRgt

			// JMD921
			If ($G(tColProps(c,"headerStyle"))'="") {
				Do ..%ParseStyle(tColProps(c,"headerStyle"),.tKPIAttrs)
				Merge tHdrAttrs = tKPIAttrs
			}
			If ($G(tColProps(c,"style"))'="") {
				Do ..%ParseStyle(tColProps(c,"style"),.tKPIAttrs)
				Merge tCellBase(c) = tKPIAttrs
			}

			For n=1:1:tRowLabelCount {
				Do ..%DrawHeader("",.tHdrAttrs)
			}
			For c = 1:1:tColCount {
				Set tName = $S($D(tColProps(c,"caption")):tColProps(c,"caption"),1:tColProps(c))
				Do ..%DrawHeader(tName,.tHdrAttrs)
			}
			If (tShowColumnTotals) {
				Set tHdrAttrs("font-weight") = "bold"
				Do ..%DrawHeader(msgTotal,.tHdrAttrs)
				Kill tHdrAttrs("font-weight")
			}
			Write "</column-headers>",!
		}

		Write "<data>",!
		For r = 1:1:tRowCount {
			If (tZebra) {
				If (r#2) {
					Set tRowBgColor = tOddBgColor
					Set tCellBgColor = tOddBgColor
				}
				Else {
					Set tRowBgColor = tEvenBgColor
					Set tCellBgColor = tEvenBgColor
				}
			}

			Write "<row>",!
			Set tName = $G(tModel.%seriesNames(r))

			Kill tLblAttrs
			Set tLblAttrs("color") = tRowColor
			Set tLblAttrs("text-align") = "left"
			Set tLblAttrs("font-size") = tRowFontSize
			Set tLblAttrs("font-family") = tDefFont
			Set tLblAttrs("background-color") = tRowBgColor
			Set tLblAttrs("border-top") = tRowBorderTop
			Set tLblAttrs("border-left") = tRowBorderLft
			Set tLblAttrs("border-bottom") = tRowBorderBtm
			Set tLblAttrs("border-right") = tRowBorderRgt
			Set tLblAttrs("column-width") = tCellWidth _ tUnits
			Set tLblAttrs("padding-before") = tRowPaddingTop
			Set tLblAttrs("padding-start") = tRowPaddingLft
			Set tLblAttrs("padding-after") = tRowPaddingBtm
			Set tLblAttrs("padding-end") = tRowPaddingRgt
			Do ..%DrawCell(tName,.tLblAttrs)

			Set tRowTotal = 0
			For c = 1:1:tColCount {
				Set tValue = ""
				Set tProp = $G(tColProps(c))
				If (tProp'="") {
					Set tValue = tController.dataBag.%GetValue(tProp,r)
					Set:tValue=$$$ZENMISSING tValue = ""
				}
			
				// JMD921: get format from KPI
				Set tFormat = $G(tColProps(c,"format"))
				Set:tFormat="" tFormat = $S($IsValidNum(tValue):$S(tValue=(tValue\1):"#,#",1:"#,#.##"),1:"")

				Set tRowTotal = tRowTotal + $S($IsValidNum(tValue):tValue,1:0)
				Set tColTotal(c) = tColTotal(c) + $S($IsValidNum(tValue):tValue,1:0)

				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set align = $Case(tType,"integer":"right","date":"right","number":"right",:"left")

				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = align
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("column-width") = tColWidth(c) _ tUnits
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt

				// JMD921
				Merge tCellAttrs = tCellBase(c)

				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}

			If (tShowColumnTotals) {
				Set tFormat = $G(tColFormat(c))
				Set:tFormat="" tFormat = tDefaultFormat
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tRowTotal,tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = align
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("column-width") = tCellWidth _ tUnits
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				Do ..%DrawCell(tDisplay,.tCellAttrs)

				Set tColTotal(tColCount+1) = tColTotal(tColCount+1) + $S($IsValidNum(tRowTotal):tRowTotal,1:0)
			}
			Write "</row>",!
		}

		If (tShowRowTotals) {
			If (tZebra) {
				If ((tRowCount+1)#2) {
					Set tRowBgColor = tOddBgColor
					Set tCellBgColor = tOddBgColor
				}
				Else {
					Set tRowBgColor = tEvenBgColor
					Set tCellBgColor = tEvenBgColor
				}
			}
			Write "<row>",!
			For n=1:1:tRowLabelCount {
				If (n>1) {
					Kill tLblAttrs
					Set tLblAttrs("color") = tRowColor
					Set tLblAttrs("text-align") = "left"
					Set tLblAttrs("font-size") = tRowFontSize
					Set tLblAttrs("font-family") = tDefFont
					Set tLblAttrs("background-color") = tRowBgColor
					Set tLblAttrs("border-top") = tRowBorderTop
					Set tLblAttrs("border-left") = tRowBorderLft
					Set tLblAttrs("border-bottom") = tRowBorderBtm
					Set tLblAttrs("border-right") = tRowBorderRgt
					Set tLblAttrs("padding-before") = tRowPaddingTop
					Set tLblAttrs("padding-start") = tRowPaddingLft
					Set tLblAttrs("padding-after") = tRowPaddingBtm
					Set tLblAttrs("padding-end") = tRowPaddingRgt
					Do ..%DrawCell("",.tLblAttrs)
				}
				Else {
					Kill tLblAttrs
					Set tLblAttrs("color") = tRowColor
					Set tLblAttrs("text-align") = "left"
					Set tLblAttrs("font-size") = tRowFontSize
					Set tLblAttrs("font-family") = tDefFont
					Set tLblAttrs("font-weight") = "bold"
					Set tLblAttrs("background-color") = tRowBgColor
					Set tLblAttrs("border-top") = tRowBorderTop
					Set tLblAttrs("border-left") = tRowBorderLft
					Set tLblAttrs("border-bottom") = tRowBorderBtm
					Set tLblAttrs("border-right") = tRowBorderRgt
					Set tLblAttrs("padding-before") = tRowPaddingTop
					Set tLblAttrs("padding-start") = tRowPaddingLft
					Set tLblAttrs("padding-after") = tRowPaddingBtm
					Set tLblAttrs("padding-end") = tRowPaddingRgt
					Do ..%DrawCell(msgTotal,.tLblAttrs)
				}
			}
			For c = 1:1:tColCount {
				Set tFormat = $G(tRowFormat)
				Set:tFormat="" tFormat = $G(tColFormat(c))
				Set:tFormat="" tFormat = tDefaultFormat
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber($G(tColTotal(c)),tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = align
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}

			If (tShowColumnTotals) {
				Set cno = tColCount + 1
				Set tFormat = $G(tColFormat(tColCount))
				Set:$G(tFormat)="" tFormat = tDefaultFormat
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber($G(tColTotal(cno)),tFormat,.tType,.tFormatStyle)
				Set align = "right"

				Kill tCellAttrs
				Set tCellAttrs("color") = tCellColor
				Set tCellAttrs("text-align") = align
				Set tCellAttrs("font-size") = tCellFontSize
				Set tCellAttrs("font-family") = tDefFont
				Set tCellAttrs("font-weight") = "bold"
				Set tCellAttrs("background-color") = tCellBgColor
				Set tCellAttrs("border-top") = tCellBorderTop
				Set tCellAttrs("border-left") = tCellBorderLft
				Set tCellAttrs("border-bottom") = tCellBorderBtm
				Set tCellAttrs("border-right") = tCellBorderRgt
				Set tCellAttrs("padding-before") = tCellPaddingTop
				Set tCellAttrs("padding-start") = tCellPaddingLft
				Set tCellAttrs("padding-after") = tCellPaddingBtm
				Set tCellAttrs("padding-end") = tCellPaddingRgt
				Do ..%DrawCell(tDisplay,.tCellAttrs)
			}
			Write "</row>",!
		}
		Write "</data>",!
		Write "</worksheet>",!
		Write "</table1>",!
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse a CSS style directive.
ClassMethod %ParseStyle(pStyle As %String, Output pCSS As %String)
{
	Kill pCSS
	For n=1:1:$L(pStyle,";") {
		Set t = $P(pStyle,";",n)
		Set tName = $P(t,":",1)
		Set tValue = $P(t,":",2)
		Set:tName'="" pCSS(tName)=tValue
	}
}

/// Create a simplified XML report for displaying an error message.
ClassMethod %WriteXMLMessage(pTitle As %String, pMessage As %String)
{
   Write !,"<table1>"
   Write !,"<worksheet> "
   Write !,"<title>",$ZCVT(pTitle,"O","HTML"),"</title> "
   Write !,"<column-headers> "
   Write !,"<header value='Message' background-color='lightgray' border-style='solid solid solid solid'/>"
   Write !,"</column-headers> "
   Write !,"<data> "
   Write !,"<row> "
   Write !,"<cell value='",$ZCVT(pMessage,"O","HTML"),"' border-style='solid solid solid solid'/>"
   Write !,"</row> "
   Write !,"</data> "
   Write !,"</worksheet>"
   Write !,"</table1>"
}

/// Format a string value for HTML output.
/// This means escaping UNICODE characters.
ClassMethod %EscapeHTML(pValue As %String) As %String
{
	Set tOut = ""
	If $system.Version.IsUnicode() {
		For n=1:1:$L(pValue) {
			Set ch = $E(pValue,n)
			Set a = $A(ch)
			Set tOut = tOut _ $S(a>128:"&#"_a_";",1:$ZCVT(ch,"O","HTML"))
		}
	} Else {
		Set tOut = $ZCVT(pValue,"O","HTML")
	}
	Quit tOut
}

/// Format a value for output.
ClassMethod %FormatNumber(pValue As %String, pFormat As %String = "") As %String [ CodeMode = expression ]
{
$ZCVT(pValue,"O","HTML")
}

/// Update the Report Display
ClassMethod OnAfterCreateDisplay()
{
	// get context from URL params
	Do ..%GetContext(.tContext,.tParms)

	// modify the display document
	#dim tDocument As %ZEN.Report.Display.document
	
	Set tUnits = $G(tContext("PageUnits"),"in")
	Set tDocument = ..%GetComponentById("document")
	
	//Set tDocument.orientation = $G(tContext("PageOrientation")) comment out JSL4248
	
	if ($G(tContext("Orientation"))'="landscape") {
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
	Set tText=##class(%DeepSee.UserPortal.Utils).%ResolveText(tText) // JSL4199
	If (tText["{@") {
		// WAL081 & PFS -- use the parms we have
		Set tText = ..%ParseExpr(tText,.tParms)
	}
	Set tTitle.content = tText

	// modify page header element
	Set tHeader = ..%GetComponentById("pageheader")

	// modify page footer element
	Set tFooter = ..%GetComponentById("pagefooter")

	Set tItem = ##class(%ZEN.Report.Display.item).%New()
	Set tItem.value=$$$Text("Page","%DeepSee")
	Set tItem.style="font-size:6pt;text-align:center;color:#606060;padding-right:0.5em;padding-left:3.0in;font-family:"_tDefFont_";"
	Do tFooter.children.Insert(tItem)

	// page number
	Set tItem = ##class(%ZEN.Report.Display.item).%New()
	Set tItem.special="page-number-of"
	Set tItem.style="font-size:6pt;text-align:center;color:#606060;font-family:"_tDefFont_";"
	Do tFooter.children.Insert(tItem)
	
	// modify table - JSL4184
	Set tFilterDiv = ..%GetComponentById("filterDiv")

	Set tShowFilters = 	$G(tContext("ShowFilters"))
	Set tShowListingFilters = $G(tContext("ShowListingFilters"))		// DTB228 - Use Print Options setting
	
	If tShowFilters="byTable" {
		If ($D(tParms("filter"))||((tShowListingFilters="on")&&$D(tParms("selectionFilter")))) { ; JSL4184		// DTB115 - add selectionFilter condition
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
		for { 
			Set filterName=$o(tParms("filter",filterName),1,filterValue) 
			Quit:filterName=""
			
			Set tItem = ##class(%ZEN.Report.Display.item).%New()
			Set tCaption=##class(%ZEN.Report.Display.caption).%New()
			Set tCaption.style = $G(tContext("FilterTableCaptionStyle"))
			Set tCaption.value=filterName
			Do tItem.children.Insert(tCaption)
			Set tItem.value=filterValue
			Set tItem.style=$G(tContext("FilterTableItemStyle"))
			Do tFilterTable.children.Insert(tItem)
		}
		// +DTB115 - process listing selectionFilters after the traditional filters so they appear last in the printed table
		Set filterName="" 
		If (tShowListingFilters="on") {		// DTB228 - Listing filters can be turned off
			for { 
				Set filterName=$o(tParms("selectionFilter",filterName),1,filterValue)
				Quit:filterName=""
				
				Set tItem = ##class(%ZEN.Report.Display.item).%New()
				Set tCaption=##class(%ZEN.Report.Display.caption).%New()
				Set tCaption.style = $G(tContext("FilterTableCaptionStyle")) 
				Set tCaption.value=filterName
				Do tItem.children.Insert(tCaption)
				Set tItem.value=filterValue
				Set tItem.style=$G(tContext("FilterTableItemStyle")) 
				Do tFilterTable.children.Insert(tItem)
				
			}
		}
		// -DTB115
	} elseif (tShowFilters="byTitle") {
		Set includeFilterText=1
	}
	
	do ##class(%DeepSee.UI.MDXPDF).GetFilterText(..%GetComponentById("pivotSubtitle"),.tParms, .tContext,+$g(includeFilterText))
	
	;Set tSubTitle.content = tSubTitleText
	// JSL4250
	Set tShowDate = $G(tContext("ShowDate"))
	if (tShowDate = "on") {
		Set tDateDiv = ..%GetComponentById("date")
		Set tItem = ##class(%ZEN.Report.Display.item).%New()
		Do tDateDiv.children.Insert(tItem)
		Set tItem.value=$zdatetime($H)		// DTB228 - Print the local time
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
}

/// Draw one cell within a table.
ClassMethod %DrawCell(pValue As %String, ByRef pAttrs) [ Internal ]
{
	Write "<cell value='",..%EscapeHTML(pValue),"' "
	For tAttr = "column-width","text-align","color","background-color","font-size","font-family","font-weight","font-style","border-top","border-left","border-bottom","border-right","text-decoration","padding-start","padding-end","padding-before","padding-after" {
		Write:$G(pAttrs(tAttr))'="" tAttr_"='",..%EscapeHTML(pAttrs(tAttr)),"' "
	}
	Write "/>",!
}

/// Draw one header within a table.
ClassMethod %DrawHeader(pValue As %String, ByRef pAttrs) [ Internal ]
{
	Write "<header value='",..%EscapeHTML(pValue),"' "
	For tAttr = "text-align","color","background-color","font-family","font-size","font-weight","font-style","border-top","border-left","border-bottom","border-right","text-decoration","padding-start","padding-end","padding-before","padding-after" {
		Write:$G(pAttrs(tAttr))'="" tAttr_"='",..%EscapeHTML(pAttrs(tAttr)),"' "
	}
	Write "/>",!
}

/// Take a string containing {@PROP.PARM} expressions and return a new string with the
/// expressions replaced.
/// E.g.:  turns "hello  {@date.7} into<br/>
/// "hello January 1, 2011"<br/>
ClassMethod %ParseExpr(pText As %String, ByRef pParms) As %String [ Internal ]
{
	Set tOut = ""

	#; list of allowable "variable" names
	Set tObjNames("date")=""	// current date
	Set tObjNames("filter")=""	// value of filter
	// WAL081 & PFS
	Set tObjNames("variable")=""

	Set start=1,next=1
	While (start>0) {
		Set next = $Find(pText,"{",next)
		#; look ahead for {@
		Set ch = $E(pText,next)
		If ((ch'="@")&&(ch'="")) {
			#; accumulate; keep going
		}
		Else {
			#; write out what we found so far
			Set accum = $E(pText,start,$S((next=0)||(next>$L(pText)):$L(pText),1:next-2))
			
			#; test for " in literal text
			If (accum["""") {
				Set s = ""
				For n=1:1:$L(accum) {
					Set s2 = $E(accum,n)
					Set s = s _ $S(s2="""":"""""",1:s2)
				}
				Set accum = s
			}

			Set:(accum'="") tOut = tOut_accum
			Quit:ch=""

			#; start of {@, find: }
			Set found=0,p=next+1
			While ('found) {
				Set ch=$E(pText,p) Quit:(ch="")
				If (ch = "}") {	Set found = 1 }
				Set p=p+1
			}
			#; got to end with no }
			If ('found) { Set tOut=tOut_$E(pText,next-1,$L(pText)),next=0 }
			#; expression
			Else { 
				Set tExpr=$E(pText,next+1,p-2)
				#; expression
				#; var.arg
				Set tPropName=$$$LOWER($P(tExpr,".",1))
				// + WAL081 & PFS -- runtime variable lookups are case sensitive, don't uppercase the variable name
				Set tArg = $P(tExpr,".",2)
				Set:(tPropName'="variable") tArg = $$$UPPER(tArg)
				// - WAL081 & PFS
				If (tPropName="date") {
					If (tArg'="") {
						Try {
							Set tExpr = $ZDT($H,tArg)
						}
						Catch(ex) {
							Set tExpr = "Invalid Date Format"
						}
					}
					Else {
						Set tExpr = $ZDT($H)
					}
				}
				ElseIf (tPropName="filter") {
					If (tArg'="") {
						If '$D(pParms("filter",tArg)) {
							Set tExpr = $$$FormatText($$$Text("(No filter %1)","%DeepSee"),tArg)
						}
						Else {
							Set tExpr = $G(pParms("filter",tArg),$$$Text("All","%DeepSee"))
						}
					}
				}
				// + WAL081 & PFS
				ElseIf (tPropName="variable") {
					If (tArg'="") {
						Set tExpr = ##class(%DeepSee.UserPortal.Utils).%GetUserSetting(tArg,.tSC)
						If $$$ISERR(tSC) {
							Set tExpr = tSC	
						}
					}
					Else {
						Set tExpr = $$$FormatText($$$Text("(No variable %1)","%DeepSee"),tArg)
					}
				}
				// - WAL081 & PFS
				Set tOut=tOut_tExpr
				Set next=p
			}
			Set start = next
		}
	}
	Quit tOut
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $System.Security.Check("%DeepSee_Portal","USE")
}

ClassMethod GetFilterText(ByRef pContainer As %ZEN.Report.Display.div, ByRef pParms As %String, ByRef pContext As %String, pIncludeFilterText As %Boolean = 0)
{
	Set tDefFont = "Arial,SimSun"
	Set style="font-size:6pt;color:#606060;padding-bottom:0.25in;font-family:"_tDefFont_";"
	
	Set tSubTitle=##class(%ZEN.Report.Display.inline).%New()
	Set tSubTitle.style = style
	Set tSubTitleText = $P(pContext("Subtitle"),"$FILTERS",1)
	Set tSubTitleTextOn = $G(pContext("SubtitleOn"),"on") // JSL4302
	Set tNowDisplayFormat = $G(pContext("NowDisplayFormat")) // JSL4308
	if tSubTitleTextOn="on"  { // JSL4302 - make display of subtitle be conditional
		Set tSubTitleText=##class(%DeepSee.UserPortal.Utils).%ResolveText(tSubTitleText) // JSL4249
		If (tSubTitleText["{@") {
			// WAL081 & PFS -- pass in pParms
			Set tSubTitleText = ##class(%DeepSee.UI.MDXPDF).%ParseExpr(tSubTitleText,.pParms)
		}
		Set tSubTitle.content=tSubTitleText
		do pContainer.children.Insert(tSubTitle)
	}
	if pIncludeFilterText {
		Set sep=""
		Set tFilterText=""
		Set Count=0
		Set filterName="" for { Set filterName=$o(pParms("filter",filterName),1,filterValue) q:filterName=""
			Set Count=Count+1
		}
		Set leftParen=""
		Set rightParen=""
		if Count>1 {
			Set leftParen="("
			Set rightParen=")"
		}
		Set filterName="" for { Set filterName=$o(pParms("filter",filterName),1,filterValue) q:filterName=""
			Set BoldName=##class(%ZEN.Report.Display.inline).%New()
			Set BoldName.style=style_"font-weight:bold;"
			Set BoldName.content=sep_leftParen_filterName_" ="
			do pContainer.children.Insert(BoldName)
			Set Value=##class(%ZEN.Report.Display.inline).%New()
			Set Value.style=style
			if tNowDisplayFormat '= "" { // JSL4308
				Set filterValue=$replace(filterValue,":NOW",":"_$zdt($P($h,","),tNowDisplayFormat))
			}
			Set Value.content=filterValue_rightParen
			do pContainer.children.Insert(Value)
			Set sep=" & "
		}
		// +DTB115 - process listing selectionsFilters after the traditional filters
		Set filterName="" 
		// PFS035 - Use ShowListingFilters to show/hide Selected Cell Context
		Set tShowListingFilters = $G(pContext("ShowListingFilters"))
		If (tShowListingFilters="on") {
			for { 
				Set filterName=$o(pParms("selectionFilter",filterName),1,filterValue) 
				q:filterName=""
				Set BoldName=##class(%ZEN.Report.Display.inline).%New()
				Set BoldName.style=style_"font-weight:bold;"
				Set BoldName.content=sep_leftParen_filterName_" ="
				do pContainer.children.Insert(BoldName)
				Set Value=##class(%ZEN.Report.Display.inline).%New()
				Set Value.style=style
				if tNowDisplayFormat '= "" { // JSL4308
					Set filterValue=$replace(filterValue,":NOW",":"_$zdt($P($h,","),tNowDisplayFormat))
				}
				Set Value.content=filterValue_rightParen
				do pContainer.children.Insert(Value)
				Set sep=" & "
			}
		}
		// -DTB115
		if tSubTitleTextOn="on" { // JSL4302 make displaying of subtitle be conditional
			Set tSubTitle=##class(%ZEN.Report.Display.inline).%New()
			Set tSubTitle.style = style
			Set tSubTitleText = $P(pContext("Subtitle"),"$FILTERS",2)
			Set tSubTitleText=##class(%DeepSee.UserPortal.Utils).%ResolveText(tSubTitleText) // JSL4249
			If (tSubTitleText["{@") {
				// WAL081 & PFS -- pass in pParms
				Set tSubTitleText = ##class(%DeepSee.UI.MDXPDF).%ParseExpr(tSubTitleText,.pParms)
			}
			Set tSubTitle.content=tSubTitleText
			do pContainer.children.Insert(tSubTitle)
		}
	} // end-if pIncludeFilterText
}

/// Render the contents of this ZEN report.
ClassMethod OnPage() As %Status
{
	Set tSC = ##class(%ZEN.Utils).%JavaInstalled()
	Quit:$$$ISERR(tSC) tSC

	// Method overridden by DTB250
	n %report
	n %noncedParm		// DP-402876
	Set tSC = $$$OK
	Do {
		#; default mode is specified by DEFAULTMODE
		Set tStyleSheetMode=$$$GETPARAMETER("STYLESHEETDEFAULTMODE")
		if (tStyleSheetMode="none") {
			Set tMode = $$$GETPARAMETER("DEFAULTMODE")
		} else {
			Set tMode = "tohtml"
		}
		Set tDisplayLog = 0
		Set tDatasource=""
		Set tEMBEDXSL=0
		Set tStripPI=$$$GETPARAMETER("STRIPPI")
		If $IsObject($G(%request)) {
			//Set tPS = $G(%request.Data("$PS",1),$$$GETPARAMETER("PS"))
			Set tMode = $zconvert($G(%request.Data("$MODE",1),tMode),"L")
			Set tSuppressExcelHeaders = $zconvert($G(%request.Data("$SUPPRESSEXCELHEADERS",1),$$$GETPARAMETER("SUPPRESSEXCELHEADERS")),"L")
			Set tDisplayLog = $G(%request.Data("$LOG",1),0)
			Set tRootName=..GetSafeRootName()
			If tRootName'="" Set tDisplayLog=1
			Set tDatasource=$G(%request.Data("$DATASOURCE",1))
			Set tStripPI=$G(%request.Data("$STRIPPI",1),$$$GETPARAMETER("STRIPPI"))
			;Set tSubReport=$G(%request.Data("$SUBREPORT",1),"")
			Set tSubReport=""
			Set tXSLTVERSION = $G(%request.Data("$XSLTVERSION",1),$$$GETPARAMETER("XSLTVERSION"))
			Set tXSLT = $zconvert($G(%request.Data("$XSLT",1),$$$GETPARAMETER("XSLTMODE")),"L")
			Set tRenderServer = $G(%request.Data("$RENDERSERVER",1),$$$GETPARAMETER("RENDERSERVER"))
			//Set tPrintServer = $G(%request.Data("$PRINTSERVER",1),$$$GETPARAMETER("PRINTSERVER"))
			if (tXSLTVERSION="2.0") Set tXSLT="server"
			Set tEMBEDXSL = $zconvert($G(%request.Data("$EMBEDXSL",1),$$$GETPARAMETER("EMBEDXSL")),"L")
			if ..hasDataSource() Set tEMBEDXSL=0
			if tMode="xlsx" {
				Set tXSLT="server"
				Set tEMBEDXSL=0
			}
			if tEMBEDXSL set tXSLT="browser" ; can't use EMBEDXSL in server mode
			Set tUseTempFiles=0
			if 'tEMBEDXSL Set tUseTempFiles = $zconvert($G(%request.Data("$USETEMPFILES",1),$$$GETPARAMETER("USETEMPFILES")),"L")
			Set tOldBehaviorLineFeedOnBreak=$g(%request.Data("$OLDBEHAVIORLINLEFEEDONBREAK",1),$$$GETPARAMETER("OLDBEHAVIORLINEFEEDONBREAK"))  // JSL4660
		}
		if $IsObject($G(%session)) {
			s tBrowserName=$G(%request.Data("$BROWSER",1))
			if tBrowserName'="" s %session.BrowserName=tBrowserName
		}
	
		#; create instance of *this* report
		Set tUserReport = ..%New()
		d ..%checkNameSpace(tEMBEDXSL, tUserReport)		
		#; handle datasource URL parameter
		If tDatasource'="" {
			Set tUserReport.Datasource=tDatasource
		}
		If $IsObject($G(%request)) {
			Set tConnectTimeOut = $G(%request.Data("$CONNECTTIMEOUT",1),$$$GETPARAMETER("CONNECTTIMEOUT"))
			Set tRenderTimeOut = $G(%request.Data("$RENDERTIMEOUT",1),$$$GETPARAMETER("RENDERTIMEOUT"))
			Set tRenderDirectlyOnTimeOut = $G(%request.Data("$RENDERDIRECTLYONTIMEOUT",1),$$$GETPARAMETER("RENDERDIRECTLYONTIMEOUT"))
			Set tPrintTimeOut = $G(%request.Data("$PRINTTIMEOUT",1),$$$GETPARAMETER("PRINTTIMEOUT"))
			Set tTimeOut = $G(%request.Data("$TIMEOUT",1),$$$GETPARAMETER("TIMEOUT"))
			Set tSplitAndMerge = $G(%request.Data("$SPLITANDMERGE",1),$$$GETPARAMETER("SPLITANDMERGE"))
			Set tRepeatingElement = $G(%request.Data("$REPEATINGELEMENT",1),$$$GETPARAMETER("REPEATINGELEMENT"))
			Set tCountRepeatingElement = $G(%request.Data("$COUNTREPEATINGELEMENT",1),$$$GETPARAMETER("COUNTREPEATINGELEMENT"))
			Set tCheckPDFNotZeroLength = $G(%request.Data("$CHECKPDFNOTZEROLENGTH",1),$$$GETPARAMETER("CHECKPDFNOTZEROLENGTH"))
			Set:tSplitAndMerge'="" tUserReport.SplitAndMerge = tSplitAndMerge
			Set:tRepeatingElement'="" tUserReport.RepeatingElement = tRepeatingElement
			Set:tCountRepeatingElement'="" tUserReport.CountRepeatingElement = tCountRepeatingElement
			Set:tSuppressExcelHeaders'="" tUserReport.SuppressExcelHeaders=tSuppressExcelHeaders
			Set:tCheckPDFNotZeroLength'="" tUserReport.CheckPDFNotZeroLength=tCheckPDFNotZeroLength
			Set:tOldBehaviorLineFeedOnBreak'="" tUserReport.OldBehaviorLineFeedOnBreak=tOldBehaviorLineFeedOnBreak
		}
		#; Set null properties to parameter values
		Set tSC = tUserReport.%InitProperties()
		If $$$ISERR(tSC) Quit
		#; copy URL parameters into specially marked properties.
		Set tSC = tUserReport.%ApplyURLParms()
		If $$$ISERR(tSC) Quit

		#; invoke callback
		Set tSC = tUserReport.%OnBeforeReport()
		If $$$ISERR(tSC) Quit

		// +DTB250 - Allow this page to load a pdf file and forget about the rendering
		Set tFilePDFRoot = $G(%request.Data("FILEPDFROOT",1))
		If (tFilePDFRoot'="") {
			Set tSC = tUserReport.%LoadFilePDFToStream(tFilePDFRoot,.tTempFiles)
			
			// Clean up the temporary files
			Do tUserReport.DeleteTempFiles(,,,,,.tTempFiles)
			
			Set tSC = tUserReport.%OnAfterReport()		// DTB562
			Quit
		}
		// -DTB250

		#; Set Mode which we use in generating the XML for the report
		Set tUserReport.Mode=tMode
		#; serve appropriate content based on $MODE query parameter
		If (tMode = "xml") {
			#; serve raw xml report data
			If tRootName'="" {
				Set tSC = tUserReport.%MakeXMLDataFile(.xmlfile,tStripPI) Quit:$$$ISERR(tSC)
				
			} else {
				Set tSC = tUserReport.%DrawXML(tStripPI,tEMBEDXSL,"xml",tMode)
			}
		} ElseIf (tMode = "tohtml") {
			#; serve xslt stylesheet for xml->html transformation
			Set tSC = tUserReport.%DrawToHTML(0,0,0,tSubReport,.XSL,.delay)
		} ElseIf (tMode = "toexcel") {
			#; serve xslt stylesheet for xml->excel transformation
			Set tSC = tUserReport.%DrawToExcel(0,0,0,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf (tMode = "toxslfo") {
			#; serve xslt stylesheet for xml->xslfo transformation
			Set tSC = tUserReport.%DrawToXSLFO(0,tSubReport,.XSL,.delay)
		} ElseIf (tMode = "xslfo") {
			#; serve XSL-FO document without processing it into a .PDF
			Set tSC=tUserReport.%DisplayFO(tDisplayLog,0,(tXSLT="server"),"",0)
		} ElseIf tMode="html" {
			#; serve HTML report
			Set tSC=tUserReport.%DisplayHTML(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,.txslfile)
		} ElseIf tMode="excel" {
			#; serve Excel report
			Set tSC=tUserReport.%DisplayExcel(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf tMode="xlsx" {
			#; serve Excel report
			Set tSC=tUserReport.%DisplayXlsx(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf (tMode = "pdf") {
			#; serve PDF report
			Set tSC = tUserReport.%DisplayPDF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"")
		} ElseIf (tMode = "fo2pdf") {
			Set tSC = tUserReport.%DisplayFO2PDF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"",0)
		} ElseIf (tMode = "foandpdf") {
				Set tSC=tUserReport.%DisplayFO(tDisplayLog,0,(tXSLT="server"),.fofile,1)
				If '$$$ISERR(tSC) {
					Set tSC = tUserReport.%DisplayFO2PDF(tDisplayLog, tRenderServer,0,fofile,"",.pdffile,.lockfile,0,"",1)
				}
		} ElseIf (tMode = "ps") {
			#; print PostScript
			Set tSC = tUserReport.%PrintPS(tDisplayLog)
		} ElseIf (tMode = "pdfprint") {
			#; print PDF
			Set tSC = tUserReport.%PrintPDF(tDisplayLog)
		} ElseIf (tMode = "tiff") {
			#; serve tiff report
			Set tSC = tUserReport.%DisplayTIFF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"")
		} ElseIf (tMode="displayxlsx") {
			#; server Excel report
			Set tSC = tUserReport.%DisplayAnnotatedExcel(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,0,"element")
		} Else {
			#; when in doubt, use HTML
			if (tStyleSheetMode="none") {
				Set tSC=tUserReport.%DisplayHTML(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,.txslfile)
			} else {
				Set tSC = tUserReport.%DrawToHTML(tDisplayLog,0,0,tSubReport,.XSL,.delay)
			}
		}
		If $$$ISERR(tSC) Quit

		#; notify that report is complete
		Set tSC = tUserReport.%OnAfterReport()
		;if $g(txslfile)'="" d ##class(%File).Delete(txslfile)
		If $$$ISERR(tSC) Quit

	} While(0)
	Quit tSC
}

/// Directly load a pdf file from the OS and stream it into the content of this window.
Method %LoadFilePDFToStream(pFileRoot = "", ByRef pTempFiles) As %Status [ Internal ]
{
	// Method added by DTB250
	Set tSC = $$$OK
	Try {
		If (pFileRoot'="") {
			// Make sure the pFileRoot does *not* have a pdf extension so this method can return the correct temp file names
			If ($P(pFileRoot,".",*)="pdf") {
				Set pFileRoot = $P(pFileRoot,".",1,*-1)
			}
			// DP-436689 - Scope all file requests to mgr/Temp
			Set tFileName = ##class(%File).NormalizeFilename(##class(%File).GetFilename(pFileRoot_".pdf"),##class(%SYS.System).TempDirectory())
			Set tFileInfo = ##class(%File).%New(tFileName)
			
			Set tSize = 0
			Set tTimeout = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5),1:5)
			
			While ($G(tCounter,0)<(tTimeout*2))&&(tSize'=($G(tSize2,0))||(tSize<=0)) {
				// DTB280 - The file might currently be getting written by the FOP engine!
				
				// Check to make sure the file size has stabilized before moving on to load
				// the contents into the stream.
				Set tSize = tFileInfo.SizeGet()
				
				// If the wait has been longer than the timeout, give up. The timeout is the greater of either:
				//   GatewayTimeout - 5 seconds
				//   5 seconds
				// DTB562 - Make the per-iteration wait time longer to allow for actual movement.
				Hang 0.5
				
				Set tSize2 = tFileInfo.SizeGet()		// DTB562 - Change when the size is checked
				
				Set tCounter = $I(tCounter)		
			}

			Set tFileStream=##class(%Stream.FileBinary).%New()
			Set tSC=tFileStream.LinkToFile(tFileName)
			If tFileStream'=$$$NULLOREF Set tSC = tFileStream.OutputToDevice()
			
			// Return the temporary file names
			Set pTempFiles(1) = tFileName
			Set pTempFiles(2) = pFileRoot _ ".xsl"
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This provides a means of fetching a nonced value from the key provided in an incoming request parameter.
/// The <var>pDataLabel</var> is the named reference to the URL parameter which is expectd to be available
/// in the available %request data.
/// Once fetched from the nonce global, the value is cached locally for continued availability via this method using the 
/// same nonce key in the %request data.
ClassMethod %FetchNoncedParmData(pDataLabel As %String, pDefault As %String = "", Output pStatus As %Status) As %String
{
	// Method added by DP-402876
	Set pStatus = $$$OK
	Set tReturn = ""
	Set tDataLabelU = $$$UPPER(pDataLabel)
	
	Try {
		If ($G(%noncedParm(tDataLabelU))'="") {
			// If this has been loaded from a nonce before, use that value again
			Set tReturn = %noncedParm(tDataLabelU)
		}
		Else {
			// This hasn't been seen before, fetch the nonced value and store it in the local cache
			// A nonce key is an integer, and this should only be called if we know a nonce is being used
			Set tValue = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data(tDataLabelU,1)))
			If (tValue="") {
				Set tValue = pDefault
			}
			
			Set (tReturn,%noncedParm(tDataLabelU)) = tValue
		}			
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = ""
	}
	
	Quit tReturn
}

}
