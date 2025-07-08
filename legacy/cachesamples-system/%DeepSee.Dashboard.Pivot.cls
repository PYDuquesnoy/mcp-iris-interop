/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This persistent class represents a saved DeepSee pivot table.<br/>
Class %DeepSee.Dashboard.Pivot Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

Parameter XMLNAME = "pivot";

Parameter ITEMTYPE = "pivot";

Parameter ICON = "deepsee/ds2_layers2_44.png";

Parameter LARGEICON = "deepsee/ds2_layers2_44.png";

/// Default value of public property for the class.
Parameter PUBLIC = 0;

/// If defined and <property>dataSource</property> is set to "manual", then 
/// this is the MDX statement used to provide the contents of the pivot table.
Property mdx As %ZEN.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// This is the width (in pixels) used for all cells within the table.
Property cellWidth As %ZEN.Datatype.integer(XMLPROJECTION = "attribute") [ InitialExpression = 120 ];

/// Optional style to apply to column headers.
Property columnHeaderStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Optional style to apply to row headers.
Property rowHeaderStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Optional style to apply to cells.
Property cellStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// This specifies how parent row labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property rowLabelSpan As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// This specifies how parent column labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property columnLabelSpan As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// This is the height (in pixels) used for all cells within the table.
/// The default is 22.
Property cellHeight As %ZEN.Datatype.integer(XMLPROJECTION = "attribute") [ InitialExpression = 22 ];

/// If true, display rows containing only empty values.<br/>
/// If <var>mdx</var> is specified, this is ignored.
Property showEmptyRows As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, display columns containing only empty values.<br/>
/// If <var>mdx</var> is specified, this is ignored.
Property showEmptyColumns As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Name of the cube that will provide data for this pivot table.
Property cubeName As %ZEN.Datatype.className(XMLPROJECTION = "attribute");

/// Caption to display. If not specified, the caption for the cube will be used.
Property caption As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Name of listing to use for detail listings. If not specified, the default listing for the cube will be used.
Property listing As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Maximum number of rows to show in a listing.
/// If not specified, the default value used.
Property listingRows As %ZEN.Datatype.integer(XMLPROJECTION = "attribute");

/// If true, show status area along the bottom of the table.
Property showStatus As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// This is used to define functions to apply to the entire row axis.
Property rowAxisOptions As PivotLevel;

/// This is used to define functions to apply to the entire column axis.
Property columnAxisOptions As PivotLevel;

/// This contains the definition of the row dimensions for this pivot table.
Property rowLevels As list Of PivotLevel(XMLNAME = "rowLevel", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the column dimensions for this pivot table.
Property columnLevels As list Of PivotLevel(XMLNAME = "columnLevel", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the filters for this pivot table.
Property filters As list Of PivotLevel(XMLNAME = "filter", XMLPROJECTION = "ELEMENT");

/// This contains an SQL restriction that should be applied to this pivot table.
Property sqlRestriction As %ZEN.Datatype.string(XMLNAME = "sqlRestriction", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the listing filters for this pivot table.
Property listingFilters As list Of PivotLevel(XMLNAME = "listingFilter", XMLPROJECTION = "ELEMENT");

/// This contains the default measure(s) (e.g., "[Measures].[Sales]") to show for this pivot table.
Property measures As list Of PivotLevel(XMLNAME = "measure", XMLPROJECTION = "ELEMENT");

Property canDrillDown As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// This contains the drillLevels for this pivot table.
Property drillLevels As list Of PivotLevel(XMLNAME = "drillLevel", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the listing fields for this pivot table.
Property listingFields As list Of PivotLevel(XMLNAME = "listingField", XMLPROJECTION = "ELEMENT");

/// This contains the formatting rule for this pivot table.
Property formatRules As list Of PivotCondition(XMLNAME = "formatRule", XMLPROJECTION = "ELEMENT");

/// Number of result rows to show at one time.
Property pageSize As %ZEN.Datatype.integer(XMLPROJECTION = "attribute") [ InitialExpression = 100 ];

/// If set, this is the name of the color-scaling scheme to apply.
/// red-to-black,green-to-black,blue-to-black,salmon-to-black,purple-to-black,gray-to-black
/// or "custom:r1,g1,b1:r2,g2,b2".
Property colorScale As %ZEN.Datatype.string;

/// If true, then display row totals.
Property rowTotals As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, then display column totals.
Property columnTotals As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Aggregate for row totals.
Property rowTotalAgg As %ZEN.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "sum" ];

/// Aggregate for column totals.
Property columnTotalAgg As %ZEN.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "sum" ];

/// Where row totals come from.
Property rowTotalSource As %ZEN.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "page" ];

/// This contains the (local) calculated memmers for this pivot table.
Property calculatedMembers As list Of CalculatedMember(XMLNAME = "calculatedMember", XMLPROJECTION = "ELEMENT");

/// If true, then display zebra striping.
Property showZebra As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, then display row captions.
Property showRowCaption As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Title to display when pivot is printed.
Property printTitle As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Subtitle to display when pivot is printed.
Property printSubtitle As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Display subtitle when exporting to PDF
Property printSubtitleOn As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Display the user when exporting to PDF
Property showUser As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Page size when pivot is printed. This takes the form "8.5x11 in" (w x h).
Property printPageSize As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Orientation when pivot is printed.
Property printOrientation As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Page top margin when pivot is printed. This is in the same units as the page size.
Property printMarginTop As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page left margin when pivot is printed. This is in the same units as the page size.
Property printMarginLeft As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page right margin when pivot is printed. This is in the same units as the page size.
Property printMarginRight As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page bottom margin when pivot is printed. This is in the same units as the page size.
Property printMarginBottom As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Width of row labels when the pivot is printed. This is in the same units as the page size.
Property printLabelWidth As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Width of data cells when the pivot is printed. This is in the same units as the page size.
Property printCellWidth As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// pivotTable autoExecute flag.
Property autoExecute As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Save of previewMode setting. The Analyzer will transfer this value to the previewMode property,
/// widgets will not.
Property previewMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// pivotTable manualMode (dataSource) flag.
Property manualMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// pivotTable manualMode query.
Property userMDX As %ZEN.Datatype.string(MAXLEN = 5000);

/// Page top margin when chart is printed. This is in the same units as the page size.
Property chartMarginTop As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page left margin when chart is printed. This is in the same units as the page size.
Property chartMarginLeft As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page right margin when chart is printed. This is in the same units as the page size.
Property chartMarginRight As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Page bottom margin when chart is printed. This is in the same units as the page size.
Property chartMarginBottom As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Max rows exported to PDF
Property maxRows As %ZEN.Datatype.integer(XMLPROJECTION = "attribute");

/// Table borders
Property borderLeftCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderRightCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderTopCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderBottomCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderLeftCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderRightCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderTopCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderBottomCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderLeftRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderRightRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderTopRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property borderBottomRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Table styles
Property fontFamilyCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property fontSizeCell As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property fontFamilyCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property fontSizeCol As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property fontFamilyRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

Property fontSizeRow As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// showFilters - byTable, byTitle, off
Property showFilters As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// showListingFilters - on, off
Property showListingFilters As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// showDate - on, off
Property showDate As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Font size for listings
Property listingFontSize As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// showZebraStripes - on, off
Property showZebraStripes As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// filterTableStyle
Property filterTableStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// filterTableCaptionStyle;
Property filterTableCaptionStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// filterTableItemStyle;
Property filterTableItemStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// nowDisplayFormat
Property nowDisplayFormat As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// measureLocation for pivot.
Property measureLocation As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// hide measure captions or not for pivot.
Property hideMeasures As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional image to show in background of pivot table.
Property backgroundImage As %ZEN.Datatype.uri;

/// Opacity (0 to 1) of pivot table background image.
Property backgroundOpacity As %ZEN.Datatype.float [ InitialExpression = 0.12 ];

/// Copy the contents of this pivot definition to pivot table <var>pPivot</var>.
Method %CopyToComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pPivot.mdx = ..mdx
		Set pPivot.sqlRestriction = ..sqlRestriction		// DTB723
		If ($E(..mdx,1,12)="DRILLTHROUGH") {
			Set pPivot.isDrillThrough = 1
		}
		Set pPivot.cellStyle = ..cellStyle
		Set pPivot.columnHeaderStyle = ..columnHeaderStyle
		Set pPivot.rowHeaderStyle = ..rowHeaderStyle
		Set pPivot.cellWidth = ..cellWidth
		Set pPivot.cellHeight = ..cellHeight
		Set pPivot.rowLabelSpan = ..rowLabelSpan
		Set pPivot.columnLabelSpan = ..columnLabelSpan
		Set pPivot.showEmptyRows = ..showEmptyRows
		Set pPivot.showEmptyColumns = ..showEmptyColumns
		Set pPivot.cubeName = ..cubeName
		Set pPivot.caption = ..caption
		Set pPivot.listing = ..listing
		Set pPivot.defaultListing = ..listing		// DTB732 (2) - Remember the original listing as the default whenever the defintion is loaded into the component
		Set pPivot.listingRows = ..listingRows
		Set pPivot.showStatus = ..showStatus
		Set pPivot.pageSize = ..pageSize
		Set pPivot.colorScale = ..colorScale
		Set pPivot.rowTotals = ..rowTotals
		Set pPivot.showZebra = ..showZebra
		Set pPivot.showRowCaption = ..showRowCaption
		Set pPivot.columnTotals = ..columnTotals
		Set pPivot.columnTotalAgg = ..columnTotalAgg
		Set pPivot.rowTotalAgg = ..rowTotalAgg
		Set pPivot.rowTotalSource = ..rowTotalSource
		Set pPivot.measureLocation = $S(..measureLocation="":"columns",1:..measureLocation)
		// + WAL120 -- fix default so that pivots pre-dating WAL114 load with
		//             "If more than one measure"
		//Set pPivot.hideMeasures = $S(..hideMeasures="":0,1:..hideMeasures) // + WAL114
		Set pPivot.hideMeasures = $S(..hideMeasures="":1,1:..hideMeasures)
		// - WAL120

		Set pPivot.printPageSize = ..printPageSize
		Set pPivot.printOrientation = ..printOrientation
		Set pPivot.printTitle = ..printTitle
		Set pPivot.printSubtitle = ..printSubtitle
		Set pPivot.printSubtitleOn = ..printSubtitleOn // JSL4302
		Set pPivot.showUser = ..showUser // JSL4320
		Set pPivot.printMarginLeft = ..printMarginLeft
		Set pPivot.printMarginTop = ..printMarginTop
		Set pPivot.printMarginRight = ..printMarginRight
		Set pPivot.printMarginBottom = ..printMarginBottom
		Set pPivot.printLabelWidth = ..printLabelWidth
		Set pPivot.printCellWidth = ..printCellWidth
		// JSL4219
		Set pPivot.maxRows = ..maxRows
		// JSL4218
		Set pPivot.borderLeftCell = ..borderLeftCell
		Set pPivot.borderRightCell = ..borderRightCell
		Set pPivot.borderTopCell = ..borderTopCell		
		Set pPivot.borderBottomCell = ..borderBottomCell
		
		Set pPivot.backgroundImage = ..backgroundImage
		Set pPivot.backgroundOpacity = ..backgroundOpacity

		Set pPivot.borderLeftCol = ..borderLeftCol
		Set pPivot.borderRightCol = ..borderRightCol
		Set pPivot.borderTopCol = ..borderTopCol
		Set pPivot.borderBottomCol = ..borderBottomCol

		Set pPivot.borderLeftRow = ..borderLeftRow
		Set pPivot.borderRightRow = ..borderRightRow
		Set pPivot.borderTopRow = ..borderTopRow
		Set pPivot.borderBottomRow = ..borderBottomRow
		
		// + WAL100 -- table styles
		/// Table styles
		Set pPivot.fontFamilyCell = ..fontFamilyCell 
		Set pPivot.fontSizeCell  = ..fontSizeCell
		Set pPivot.fontFamilyCol = ..fontFamilyCol
		Set pPivot.fontSizeCol = ..fontSizeCol
		Set pPivot.fontFamilyRow = ..fontFamilyRow
		Set pPivot.fontSizeRow  = ..fontSizeRow
		// - WAL100

		// JSL4184
		Set pPivot.showFilters = ..showFilters
		Set pPivot.filterTableStyle = ..filterTableStyle
		Set pPivot.filterTableCaptionStyle = ..filterTableCaptionStyle
		Set pPivot.filterTableItemStyle = ..filterTableItemStyle

		// JSL4308
		Set pPivot.nowDisplayFormat = ..nowDisplayFormat
				
		// JSL4250
		Set pPivot.showListingFilters = ..showListingFilters
		Set pPivot.showDate = ..showDate
		// JSL4279
		Set pPivot.listingFontSize = ..listingFontSize
		
		// JSL4526
		Set pPivot.showZebraStripes = ..showZebraStripes
						
		// JMD1025
		Set pPivot.autoExecute = $S(..autoExecute="":1,1:..autoExecute)
		Set pPivot.previewMode = $S(..previewMode="":0,1:..previewMode)		// DTB701
		Set pPivot.canDrillDown = $S(..canDrillDown="":1,1:..canDrillDown)		// DTB978
		
		
		Set pPivot.dataSource = $S((+..manualMode):"manual",1:"automatic")		// DP-427658
		Set pPivot.userMDX = ..userMDX

		Set tSC = ..rowAxisOptions.%CopyToComponent(pPivot.rowAxisOptions)
		If $$$ISERR(tSC) Quit
		Set tSC = ..columnAxisOptions.%CopyToComponent(pPivot.columnAxisOptions)
		If $$$ISERR(tSC) Quit

		Do pPivot.rowLevels.Clear()
		For n=1:1:..rowLevels.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..rowLevels.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.rowLevels.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.columnLevels.Clear()
		For n=1:1:..columnLevels.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..columnLevels.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.columnLevels.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.filters.Clear()
		For n=1:1:..filters.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..filters.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.filters.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		// JMD1360
		Do pPivot.listingFilters.Clear()
		For n=1:1:..listingFilters.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..listingFilters.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.listingFilters.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.drillLevels.Clear()
		For n=1:1:..drillLevels.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..drillLevels.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.drillLevels.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.measures.Clear()
		For n=1:1:..measures.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..measures.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.measures.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.listingFields.Clear()
		For n=1:1:..listingFields.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..listingFields.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivot.listingFields.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.formatRules.Clear()
		For n=1:1:..formatRules.Count() {
			Set tRule = ##class(%DeepSee.Component.pivotCondition).%New()
			Set tSC = ..formatRules.GetAt(n).%CopyToComponent(tRule)
			If $$$ISERR(tSC) Quit
			Do pPivot.formatRules.Insert(tRule)
			Do:$IsObject($G(%page)) %page.%AddComponent(tRule)
		}
		If $$$ISERR(tSC) Quit

		Do pPivot.calculatedMembers.Clear()
		For n=1:1:..calculatedMembers.Count() {
			Set tCalcMbr = ##class(%DeepSee.Component.calculatedMember).%New()
			Set tSC = ..calculatedMembers.GetAt(n).%CopyToComponent(tCalcMbr)
			If $$$ISERR(tSC) Quit
			Do pPivot.calculatedMembers.Insert(tCalcMbr)
			Do:$IsObject($G(%page)) %page.%AddComponent(tCalcMbr)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the contents of this pivot definition from pivot table <var>pPivot</var>.
Method %CopyFromComponent(pPivot As %DeepSee.Component.pivotTable) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// +DTB130 - do not persist the version number, store the cube's generic reference identifier
		Set tCubeName = pPivot.cubeName
		If ##class(%DeepSee.CubeVersion.Utils).%IsVersion(tCubeName) {
			Set tCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(tCubeName)
		}
		Set ..cubeName = tCubeName	
		// -DTB130
		
		Set ..mdx = pPivot.mdx
		Set ..sqlRestriction = pPivot.sqlRestriction		// DTB723
		Set ..cellStyle = pPivot.cellStyle
		Set ..columnHeaderStyle = pPivot.columnHeaderStyle
		Set ..rowHeaderStyle = pPivot.rowHeaderStyle
		Set ..cellWidth = pPivot.cellWidth
		Set ..cellHeight = pPivot.cellHeight
		Set ..rowLabelSpan = pPivot.rowLabelSpan
		Set ..columnLabelSpan = pPivot.columnLabelSpan
		Set ..showEmptyRows = pPivot.showEmptyRows
		Set ..showEmptyColumns = pPivot.showEmptyColumns
		Set ..caption = pPivot.caption
		Set ..listing = pPivot.listing // JMD1024
		Set ..listingRows = pPivot.listingRows
		Set ..showStatus = pPivot.showStatus
		Set ..pageSize = pPivot.pageSize
		Set ..colorScale = pPivot.colorScale
		Set ..rowTotals = pPivot.rowTotals
		Set ..showZebra = pPivot.showZebra
		Set ..showRowCaption = pPivot.showRowCaption
		Set ..columnTotals = pPivot.columnTotals
		Set ..columnTotalAgg = pPivot.columnTotalAgg
		Set ..rowTotalAgg = pPivot.rowTotalAgg
		Set ..rowTotalSource = pPivot.rowTotalSource
		Set ..measureLocation = pPivot.measureLocation
		Set ..hideMeasures = pPivot.hideMeasures // + WAL114

		Set ..printPageSize = pPivot.printPageSize
		Set ..printOrientation = pPivot.printOrientation
		Set ..printTitle = pPivot.printTitle
		Set ..printSubtitle = pPivot.printSubtitle
		Set ..printSubtitleOn = pPivot.printSubtitleOn
		Set ..showUser = pPivot.showUser // JSL4320
		Set ..printMarginLeft = pPivot.printMarginLeft
		Set ..printMarginTop = pPivot.printMarginTop
		Set ..printMarginRight = pPivot.printMarginRight
		Set ..printMarginBottom = pPivot.printMarginBottom
		Set ..printLabelWidth = pPivot.printLabelWidth
		Set ..printCellWidth = pPivot.printCellWidth
		// JSL4219
		Set ..maxRows = pPivot.maxRows
		// JSL4218
		Set ..borderLeftCell = pPivot.borderLeftCell
		Set ..borderRightCell = pPivot.borderRightCell
		Set ..borderTopCell = pPivot.borderTopCell		
		Set ..borderBottomCell = pPivot.borderBottomCell

		Set ..borderLeftCol = pPivot.borderLeftCol
		Set ..borderRightCol = pPivot.borderRightCol
		Set ..borderTopCol = pPivot.borderTopCol
		Set ..borderBottomCol = pPivot.borderBottomCol

		Set ..borderLeftRow = pPivot.borderLeftRow
		Set ..borderRightRow = pPivot.borderRightRow
		Set ..borderTopRow = pPivot.borderTopRow
		Set ..borderBottomRow = pPivot.borderBottomRow
		
		// + WAL100 -- table styles
		/// Table styles
		Set ..fontFamilyCell  = pPivot.fontFamilyCell
		Set ..fontSizeCell = pPivot.fontSizeCell
		Set ..fontFamilyCol = pPivot.fontFamilyCol 
		Set ..fontSizeCol = pPivot.fontSizeCol
		Set ..fontFamilyRow = pPivot.fontFamilyRow
		Set ..fontSizeRow = pPivot.fontSizeRow 
		// - WAL100
		
		Set ..backgroundImage = pPivot.backgroundImage
		Set ..backgroundOpacity = pPivot.backgroundOpacity

		// JSL4184
		Set ..showFilters = pPivot.showFilters
		Set ..filterTableStyle = pPivot.filterTableStyle
		Set ..filterTableCaptionStyle = pPivot.filterTableCaptionStyle
		Set ..filterTableItemStyle = pPivot.filterTableItemStyle

		// JSL4308
		Set ..nowDisplayFormat = pPivot.nowDisplayFormat
		
		// JSL4250
		Set ..showListingFilters = pPivot.showListingFilters
		Set ..showDate = pPivot.showDate
		// JSL4256
		Set ..showZebraStripes = pPivot.showZebraStripes
		// JSL4279
		Set ..listingFontSize = pPivot.listingFontSize
				
		// JMD1025
		Set ..autoExecute = $S(pPivot.autoExecute="":1,1:pPivot.autoExecute)
		Set ..previewMode = $S(pPivot.previewMode="":0,1:pPivot.previewMode)		// DTB701
		Set ..canDrillDown = pPivot.canDrillDown		// DTB958

		// JMD1031
		Set ..manualMode = $S(pPivot.dataSource="manual":1,1:0)
		Set ..userMDX = pPivot.userMDX

		Set tSC = ..rowAxisOptions.%CopyFromComponent(pPivot.rowAxisOptions)
		If $$$ISERR(tSC) Quit
		Set tSC = ..columnAxisOptions.%CopyFromComponent(pPivot.columnAxisOptions)
		If $$$ISERR(tSC) Quit

		Do ..rowLevels.Clear()
		For n=1:1:pPivot.rowLevels.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.rowLevels.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..rowLevels.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..columnLevels.Clear()
		For n=1:1:pPivot.columnLevels.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.columnLevels.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..columnLevels.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..filters.Clear()
		For n=1:1:pPivot.filters.Count() {
			If ('pPivot.filters.GetAt(n).transient) {
				Set tLevel = ##class(PivotLevel).%New()
				Set tSC = tLevel.%CopyFromComponent(pPivot.filters.GetAt(n))
				If $$$ISERR(tSC) Quit
				Do ..filters.Insert(tLevel)
			}
		}
		If $$$ISERR(tSC) Quit

		// JMD1360
		Do ..listingFilters.Clear()
		For n=1:1:pPivot.listingFilters.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.listingFilters.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..listingFilters.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..drillLevels.Clear()
		For n=1:1:pPivot.drillLevels.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.drillLevels.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..drillLevels.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..measures.Clear()
		For n=1:1:pPivot.measures.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.measures.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..measures.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..listingFields.Clear()
		For n=1:1:pPivot.listingFields.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pPivot.listingFields.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..listingFields.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Do ..formatRules.Clear()
		For n=1:1:pPivot.formatRules.Count() {
			Set tRule = ##class(PivotCondition).%New()
			Set tSC = tRule.%CopyFromComponent(pPivot.formatRules.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..formatRules.Insert(tRule)
		}
		If $$$ISERR(tSC) Quit

		Do ..calculatedMembers.Clear()
		For n=1:1:pPivot.calculatedMembers.Count() {
			Set tMember = ##class(CalculatedMember).%New()
			Set tSC = tMember.%CopyFromComponent(pPivot.calculatedMembers.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..calculatedMembers.Insert(tMember)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy the contents of this pivot definition to an Dao.
Method %CopyToDao(Output pPivotJSON As %DynamicObject) As %Status
{
	Set tSC = $$$OK

	Try {
		Set pPivotJSON = {}

		Set pPivotJSON.mdx = ..mdx
		Set pPivotJSON.sqlRestriction = ..sqlRestriction		// DTB723
		If ($E(..mdx,1,12)="DRILLTHROUGH") {
			Set pPivotJSON.isDrillThrough = 1
		}
		Set pPivotJSON.cellStyle = ..cellStyle
		Set pPivotJSON.columnHeaderStyle = ..columnHeaderStyle
		Set pPivotJSON.rowHeaderStyle = ..rowHeaderStyle
		Set pPivotJSON.cellWidth = ..cellWidth
		Set pPivotJSON.cellHeight = ..cellHeight
		Set pPivotJSON.rowLabelSpan = ..rowLabelSpan
		Set pPivotJSON.columnLabelSpan = ..columnLabelSpan
		Set pPivotJSON.showEmptyRows = ..showEmptyRows
		Set pPivotJSON.showEmptyColumns = ..showEmptyColumns
		Set pPivotJSON.cubeName = ..cubeName
		Set pPivotJSON.caption = ..caption
		Set pPivotJSON.listing = ..listing
		Set pPivotJSON.defaultListing = ..listing		// DTB732 (2) - Remember the original listing as the default whenever the defintion is loaded into the component
		Set pPivotJSON.listingRows = ..listingRows
		Set pPivotJSON.showStatus = ..showStatus
		Set pPivotJSON.pageSize = ..pageSize
		Set pPivotJSON.colorScale = ..colorScale
		Set pPivotJSON.rowTotals = ..rowTotals
		Set pPivotJSON.showZebra = ..showZebra
		Set pPivotJSON.showRowCaption = ..showRowCaption
		Set pPivotJSON.columnTotals = ..columnTotals
		Set pPivotJSON.columnTotalAgg = ..columnTotalAgg
		Set pPivotJSON.rowTotalAgg = ..rowTotalAgg
		Set pPivotJSON.rowTotalSource = ..rowTotalSource
		Set pPivotJSON.measureLocation = $S(..measureLocation="":"columns",1:..measureLocation)
		// + WAL120 -- fix default so that pivots pre-dating WAL114 load with
		//             "If more than one measure"
		Set pPivotJSON.hideMeasures = $S(..hideMeasures="":1,1:..hideMeasures)
		// - WAL120
						
		// JMD1025
		Set pPivotJSON.autoExecute = $S(..autoExecute="":1,1:..autoExecute)
		Set pPivotJSON.previewMode = $S(..previewMode="":0,1:..previewMode)		// DTB701
		Set pPivotJSON.canDrillDown = $S(..canDrillDown="":1,1:..canDrillDown)		// DTB978
		
		// JMD1031
		If (+..manualMode) {
			Set pPivotJSON.dataSource = "manual"
			Set pPivotJSON.userMDX = ..userMDX
			Set pPivotJSON.baseMDX = ..userMDX
		}
		Else {
			Set pPivotJSON.dataSource = "automatic"
			Set pPivotJSON.baseMDX = ..%GetBaseMDX()
		}

		Set tSC = ..rowAxisOptions.%CopyToDao(pPivotJSON.rowAxisOptions)
		If $$$ISERR(tSC) Quit
		Set tSC = ..columnAxisOptions.%CopyToDao(pPivotJSON.columnAxisOptions)
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.rowLevels = []
		For n=1:1:..rowLevels.Count() {
			Set tLevel = {}
			Set tSC = ..rowLevels.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.rowLevels.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.columnLevels = []
		For n=1:1:..columnLevels.Count() {
			Set tLevel = {}
			Set tSC = ..columnLevels.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.columnLevels.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.filters = []
		For n=1:1:..filters.Count() {
			Set tLevel = {}
			Set tSC = ..filters.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.filters.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.listingFilters = []
		For n=1:1:..listingFilters.Count() {
			Set tLevel = {}
			Set tSC = ..listingFilters.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.listingFilters.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.drillLevels = []
		For n=1:1:..drillLevels.Count() {
			Set tLevel = {}
			Set tSC = ..drillLevels.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.drillLevels.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.measures = []
		For n=1:1:..measures.Count() {
			Set tLevel = {}
			Set tSC = ..measures.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.measures.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.listingFields = []
		For n=1:1:..listingFields.Count() {
			Set tLevel = {}
			Set tSC = ..listingFields.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.listingFields.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.formatRules = []
		For n=1:1:..formatRules.Count() {
			Set tRule = {}
			Set tSC = ..formatRules.GetAt(n).%CopyToComponent(.tRule)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.formatRules.%Push(tRule)
		}
		If $$$ISERR(tSC) Quit

		Set pPivotJSON.calculatedMembers = []
		For n=1:1:..calculatedMembers.Count() {
			Set tCalcMbr = {}
			Set tSC = ..calculatedMembers.GetAt(n).%CopyToComponent(.tCalcMbr)
			If $$$ISERR(tSC) Quit
			Do pPivotJSON.calculatedMembers.%Push(tCalcMbr)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %GetBaseMDX() As %String
{
	Set tPivot = ##class(%DeepSee.Component.pivotTable).%New()
	Set tSC = ..%CopyToComponent(.tPivot)
	Quit tPivot.SynthesizeMDX()
}

/// Return a list of all other folder items (including cubes or kpis) that this item depends upon.
Method %GetDependencies(pList As %String) As %Status
{
	// !!! what about ..mdx
	If (..cubeName'="") {
		Set tName = ..cubeName_".cube"
		Set pList($$$UPPER(tName)) = tName
	}
	Quit ##super(.pList)
}

/// Return the cube name that provides data for this pivot.
Method %GetCubeName() As %String
{
	/// !!!!
	Quit ..cubeName
}

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = "_DeepSee.UserPortal.Analyzer.zen"
	Set tURL = tURL _ "?PIVOT="_$ZCVT($ZCVT(..fullName,"O","UTF8"),"O","URL")
	Quit tURL
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit $$$Text("Pivot","%DeepSee")
}

Storage Default
{
<Data name="PivotDefaultData">
<Subscript>"Pivot"</Subscript>
<Value name="1">
<Value>mdx</Value>
</Value>
<Value name="2">
<Value>cellWidth</Value>
</Value>
<Value name="3">
<Value>rowLabelSpan</Value>
</Value>
<Value name="4">
<Value>columnLabelSpan</Value>
</Value>
<Value name="5">
<Value>cellHeight</Value>
</Value>
<Value name="6">
<Value>showEmptyRows</Value>
</Value>
<Value name="7">
<Value>showEmptyColumns</Value>
</Value>
<Value name="8">
<Value>cubeName</Value>
</Value>
<Value name="9">
<Value>caption</Value>
</Value>
<Value name="10">
<Value>showFilters</Value>
</Value>
<Value name="11">
<Value>showStatus</Value>
</Value>
<Value name="12">
<Value>rowAxisOptions</Value>
</Value>
<Value name="13">
<Value>columnAxisOptions</Value>
</Value>
<Value name="14">
<Value>rowLevels</Value>
</Value>
<Value name="15">
<Value>columnLevels</Value>
</Value>
<Value name="16">
<Value>filters</Value>
</Value>
<Value name="17">
<Value>measures</Value>
</Value>
<Value name="18">
<Value>pageSize</Value>
</Value>
<Value name="19">
<Value>drillLevels</Value>
</Value>
<Value name="20">
<Value>colorScale</Value>
</Value>
<Value name="21">
<Value>formatRules</Value>
</Value>
<Value name="22">
<Value>listing</Value>
</Value>
<Value name="23">
<Value>rowTotals</Value>
</Value>
<Value name="24">
<Value>columnTotals</Value>
</Value>
<Value name="25">
<Value>calculatedMembers</Value>
</Value>
<Value name="26">
<Value>columnHeaderStyle</Value>
</Value>
<Value name="27">
<Value>rowHeaderStyle</Value>
</Value>
<Value name="28">
<Value>cellStyle</Value>
</Value>
<Value name="29">
<Value>listingRows</Value>
</Value>
<Value name="30">
<Value>showZebra</Value>
</Value>
<Value name="31">
<Value>showRowCaption</Value>
</Value>
<Value name="32">
<Value>rowTotalAgg</Value>
</Value>
<Value name="33">
<Value>columnTotalAgg</Value>
</Value>
<Value name="34">
<Value>rowTotalSource</Value>
</Value>
<Value name="35">
<Value>printTitle</Value>
</Value>
<Value name="36">
<Value>printSubtitle</Value>
</Value>
<Value name="37">
<Value>printPageSize</Value>
</Value>
<Value name="38">
<Value>printOrientation</Value>
</Value>
<Value name="39">
<Value>printMarginTop</Value>
</Value>
<Value name="40">
<Value>printMarginLeft</Value>
</Value>
<Value name="41">
<Value>printMarginRight</Value>
</Value>
<Value name="42">
<Value>printMarginBottom</Value>
</Value>
<Value name="43">
<Value>printLabelWidth</Value>
</Value>
<Value name="44">
<Value>printCellWidth</Value>
</Value>
<Value name="45">
<Value>autoExecute</Value>
</Value>
<Value name="46">
<Value>manualMode</Value>
</Value>
<Value name="47">
<Value>userMDX</Value>
</Value>
<Value name="48">
<Value>chartMarginTop</Value>
</Value>
<Value name="49">
<Value>chartMarginLeft</Value>
</Value>
<Value name="50">
<Value>chartMarginRight</Value>
</Value>
<Value name="51">
<Value>chartMarginBottom</Value>
</Value>
<Value name="52">
<Value>listingFields</Value>
</Value>
<Value name="53">
<Value>filterTableStyle</Value>
</Value>
<Value name="54">
<Value>filterTableCaptionStyle</Value>
</Value>
<Value name="55">
<Value>filterTableItemStyle</Value>
</Value>
<Value name="56">
<Value>borderLeftCell</Value>
</Value>
<Value name="57">
<Value>borderRightCell</Value>
</Value>
<Value name="58">
<Value>borderTopCell</Value>
</Value>
<Value name="59">
<Value>borderBottomCell</Value>
</Value>
<Value name="60">
<Value>borderLeftCol</Value>
</Value>
<Value name="61">
<Value>borderRightCol</Value>
</Value>
<Value name="62">
<Value>borderTopCol</Value>
</Value>
<Value name="63">
<Value>borderBottomCol</Value>
</Value>
<Value name="64">
<Value>borderLeftRow</Value>
</Value>
<Value name="65">
<Value>borderRightRow</Value>
</Value>
<Value name="66">
<Value>borderTopRow</Value>
</Value>
<Value name="67">
<Value>borderBottomRow</Value>
</Value>
<Value name="68">
<Value>maxRows</Value>
</Value>
<Value name="69">
<Value>showListingFilters</Value>
</Value>
<Value name="70">
<Value>showDate</Value>
</Value>
<Value name="71">
<Value>showZebraStripes</Value>
</Value>
<Value name="72">
<Value>listingFontSize</Value>
</Value>
<Value name="73">
<Value>printSubtitleOn</Value>
</Value>
<Value name="74">
<Value>nowDisplayFormat</Value>
</Value>
<Value name="75">
<Value>showUser</Value>
</Value>
<Value name="76">
<Value>listingFilters</Value>
</Value>
<Value name="77">
<Value>measureLocation</Value>
</Value>
<Value name="78">
<Value>backgroundImage</Value>
</Value>
<Value name="79">
<Value>backgroundOpacity</Value>
</Value>
<Value name="80">
<Value>fontFamilyCell</Value>
</Value>
<Value name="81">
<Value>fontSizeCell</Value>
</Value>
<Value name="82">
<Value>fontFamilyCol</Value>
</Value>
<Value name="83">
<Value>fontSizeCol</Value>
</Value>
<Value name="84">
<Value>fontFamilyRow</Value>
</Value>
<Value name="85">
<Value>fontSizeRow</Value>
</Value>
<Value name="86">
<Value>hideMeasures</Value>
</Value>
<Value name="87">
<Value>previewMode</Value>
</Value>
<Value name="88">
<Value>sqlRestriction</Value>
</Value>
<Value name="89">
<Value>canDrillDown</Value>
</Value>
</Data>
<DefaultData>PivotDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
