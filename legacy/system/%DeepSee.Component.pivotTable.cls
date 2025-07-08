/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Pivot table component.<br/>
/// This component gives users the ability to view and interact with a DeepSee cube
/// or subject area.<br/>
/// The data displayed by the pivot table can be supplied in various ways.
/// This is specified using the <property>dataSource</property>:
/// <ul>
/// <li>"manual" - Setting the value of the <property>userMDX</property> property to
/// a valid MDX statement will cause the pivotTable to display the results of the query.
/// This includes DRILLTHROUGH queries (which provide a listing of source data values).</li>
/// <li>"automatic" - The user can drag and drop member specifications onto one of the various
/// drop zones (supplied by the pivotController component) and the pivot table will automatically construct and execute an MDX query.
/// In this case, you must supply a value for the <property>cubeName</property> property.<br/>
/// This is the mode in which the DeepSee Analyzer works.</li>
/// </ul>
Class %DeepSee.Component.pivotTable Extends %ZEN.Component.component [ System = 3 ]
{

/// Pick up formula code.
Parameter JSINCLUDES = "DeepSee.js,dsparser.js";

Property absolutePositioning As %ZEN.Datatype.string [ InitialExpression = 0 ];

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Localization domain
Parameter DOMAIN = "%DeepSee";

Parameter DEFAULTENCLOSINGCLASS = "dsPivotEnclosingDiv";

Parameter MAXCOLUMNS = 100;

Parameter MAXLISTINGROWS = 1000;

/// Specifies how this pivot table gets data from a DeepSee source.
Property dataSource As %ZEN.Datatype.string(VALUELIST = ",manual,automatic") [ InitialExpression = "automatic" ];

Property singleTable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property staleCache As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

Property reinitialized As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Name of data source associated with this pivot.
Property dataSourceName As %ZEN.Datatype.string [ Internal ];

/// If defined and <property>dataSource</property> is set to "manual", then 
/// this is the MDX statement used to provide the contents of the pivot table.
Property mdx As %ZEN.Datatype.string(ZENENCRYPT = 1, ZENSETTING = 0);

/// If defined, then this holds the user-supplied MDX statement used to 
/// provide the contents of the pivot table.
Property userMDX As %ZEN.Datatype.string(ZENSETTING = 0);

/// If defined, then this is the name of the DeepSee KPI class used to provide 
/// the contents of the pivot table.
Property kpi As %ZEN.Datatype.string;

/// Text of most recently executed query
Property currentQueryText As %ZEN.Datatype.string(ZENENCRYPT = 1, ZENSETTING = 0);

/// Resolved text of most recently executed query
Property resolvedQueryText As %ZEN.Datatype.string(ZENENCRYPT = 1, ZENSETTING = 0);

/// If defined, then this is a list of columns to display when displaying a KPI-based pivot.
/// Each item in the list can also define a caption: "property:caption,..."
/// as well as a format: "property:caption:format,..." <br/>
/// "," and ":" can be escaped with "\," and "\:"
Property columnList As %ZEN.Datatype.csv;

/// If defined, then this is the name of the column that provides the value for 
/// a row within this pivot. This value is used when a row is selected, and a dashboard
/// *action* is invoked on the pivot.<br/>
/// This only applies to KPI-based pivots.
/// If not provided, then the first column is used.
Property valueColumn As %ZEN.Datatype.string;

/// Indicates if and how measures should be displayed
/// 0 = Always
/// 1 = If More Than 1 Measure
/// 2 = Never
Property hideMeasures As %ZEN.Datatype.string [ InitialExpression = 1 ];

Property hiddenMeasureText As list Of %ZEN.Datatype.string(XMLPROJECTION = "ELEMENT");

Property rowCaptionList As list Of %ZEN.Datatype.string(XMLPROJECTION = "ELEMENT");

/// If true, execute a show plan for the query.
Property showPlan As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This is the minimum width (in pixels) used for all cells within the table.
/// The default is 120.
Property cellWidth As %ZEN.Datatype.integer [ InitialExpression = 120 ];

/// This specifies how parent row labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property rowLabelSpan As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This specifies how parent column labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property columnLabelSpan As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This is the height (in pixels) used for all cells within the table.
/// The default is 22.
Property cellHeight As %ZEN.Datatype.integer [ InitialExpression = 22 ];

/// If true, display rows containing only empty values.<br/>
/// If <var>mdx</var> is specified, this is ignored.
Property showEmptyRows As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, display columns containing only empty values.<br/>
/// If <var>mdx</var> is specified, this is ignored.
Property showEmptyColumns As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Name of the cube that will provide data for this pivot table.
Property cubeName As %ZEN.Datatype.className(ZENEXPRESSION = 1);

/// Caption to display. If not specified, the caption for the cube will be used.
Property caption As %ZEN.Datatype.string;

/// Name of listing to use for the current detail listing. If empty, the default listing is used.
Property listing As %ZEN.Datatype.string;

/// Name of listing to use for the default detail listing. If empty, the default listing for the cube is used.
Property defaultListing As %ZEN.Datatype.string;

/// If true, then listings are enabled for this pivot.
Property listingEnabled As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specifies the select mode for a detail listing: none, "single", or "multi".
Property listingSelect As %ZEN.Datatype.string(VALUELIST = ",single,multi");

/// Specifies the type of detail listing to show: "table", or "map".
Property listingType As %ZEN.Datatype.string(VALUELIST = ",table,map", XMLPROJECTION = "none") [ InitialExpression = "table", Internal ];

/// Maximum number of total rows to display within a detail listing.
/// If empty, the default value (1000) is used.
Property listingRows As %ZEN.Datatype.integer;

/// Number of rows to display within one page of a detail listing.
/// If empty, the default value (100) is used.
Property listingPageSize As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// Specifies the select mode for the pivot table: none, "single", or "multi".
/// Turning this on displays check boxes for each row in the pivot table.
/// This is different from the built-in cell range selection mechanism.<br/>
/// This only applies to KPI-based pivots.
Property pivotSelect As %ZEN.Datatype.string(VALUELIST = ",single,multi");

/// Internal property used to remember the normalized cube name for this table.
Property cubeKey As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to remember the query key for this table.
Property queryKey As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to caching listing results for this table.
Property listingKey As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property to track this specific pivot instance. This is used to cancel query execution.
Property pivotNonce As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = {$R(1000000000)}, Internal ];

/// Internal property used to track the current total of cell values.
Property totalValue As %ZEN.Datatype.float(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to track the number of cells.
Property cellCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to track if we truncated the number of displayed columns.
Property columnsTruncated As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// Internal property used to track the current query status.
Property queryStatus As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// Internal property used to track the completion percentage of the current query.
Property queryComplete As %ZEN.Datatype.float(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to track number of calls to track the current query.
Property queryCalls As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to track whether the current query has pending results 
/// (such as async KPIs being computed).
Property queryPending As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// If true, show status area along the bottom of the table.
Property showStatus As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, show pivot cell count and total in status area along the bottom of the table.
Property showPivotStats As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, show the query used to get results for this table.<br/>
/// This is a intended for use as a troubleshooting aid.
Property showQuery As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can drill down by double-clicking on row captions.
/// This is only enabled for queries automatically generated by the pivot table.
Property canDrillDown As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 1, Internal ];

/// This is used to define functions to apply to the entire row axis.
Property rowAxisOptions As pivotLevel;

/// This is used to define functions to apply to the entire column axis.
Property columnAxisOptions As pivotLevel;

/// This contains the definition of the row dimensions for this pivot table.
Property rowLevels As list Of pivotLevel(XMLNAME = "rowLevel", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the column dimensions for this pivot table.
Property columnLevels As list Of pivotLevel(XMLNAME = "columnLevel", XMLPROJECTION = "ELEMENT");

/// This contains the definition of the filters for this pivot table.
Property filters As list Of pivotLevel(XMLNAME = "filter", XMLPROJECTION = "ELEMENT");

/// This contains an SQL restriction that should be applied to this pivot table.
Property sqlRestriction As %ZEN.Datatype.string(XMLNAME = "sqlRestriction", XMLPROJECTION = "ELEMENT");

/// Externally applied filter spec. This should contain a valid %FILTER clause.
/// If it starts with "%FILTER" then it is one or more %FILTER clauses.
Property contextFilterSpec As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Externally applied COLUMNS spec. This should contain a valid MDX expression (without "ON COLUMNS").
Property overrideColumnSpec As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Text value associated with overrideColumnSpec. Used as a label.
Property overrideColumnText As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Externally applied ROWS spec. This should contain a valid MDX expression (without "ON ROWS").
Property overrideRowSpec As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Text value associated with overrideRowSpec. Used as a label.
Property overrideRowText As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// This contains the default measure(s) (e.g., "[Measures].[Sales]") to show for this pivot table.
Property measures As list Of pivotLevel(XMLNAME = "measure", XMLPROJECTION = "ELEMENT");

/// When there are multiple measures in the measures list, speficies where to 
/// place them: "rows", or "columns".
Property measureLocation As %ZEN.Datatype.string(VALUELIST = "rows,columns") [ InitialExpression = "columns" ];

/// This contains the current set of "drill into" levels for this pivot table.
Property drillLevels As list Of pivotLevel(XMLNAME = "drillLevel", XMLPROJECTION = "ELEMENT");

Property drillRowNumbers As list Of %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// This is the set of filters that describe the cell(s) used for the current listing for this pivot table.
Property listingFilters As list Of pivotLevel(XMLNAME = "listingFilter", XMLPROJECTION = "ELEMENT") [ Internal ];

/// This is the set of fields that describe the columnns used for the current custom listing for this pivot table.
Property listingFields As list Of pivotLevel(XMLNAME = "listingField", XMLPROJECTION = "ELEMENT") [ Internal ];

/// If true, user can select their own fields for listing.
Property canUseListingFields As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// Number of pivot result rows to show at one time.
Property pageSize As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// This is the number (1-based) of the "page" within the query
/// results that is currently displayed.
Property currPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If not 0, then sort the results by the values within this column.
Property sortColumn As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// If column sorting is on, then this is the sort direction.
Property sortDir As %ZEN.Datatype.string(VALUELIST = "ASC,DESC") [ InitialExpression = "ASC" ];

/// This is the number (1-based) of the "page" within the listing that is currently displayed.
/// If this is set to -1, then the first page will be displayed AND the listing will be recomputed.
Property currListingPage As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// If not 0, then sort the listing table by the values within this column.
Property listingSortColumn As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// If listing column sorting is on, then this is the sort direction.
Property listingSortDir As %ZEN.Datatype.string(VALUELIST = "ASC,DESC") [ InitialExpression = "ASC" ];

/// If present, this is the number of rows returned by the current
/// query. This is calculated in both user query and
/// automatic query modes.<br/>
Property rowCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0);

/// Maximum number of data rows emitted as JSON to drive charts.
/// If empty, the default value (2500) is used.
Property jsonRows As %ZEN.Datatype.integer [ InitialExpression = 2500 ];

/// If present, this is the total number of rows returned by the current listing.
Property listingRowCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0);

/// If present, this is the number of columns returned by the current
/// query. This is calculated in both user query and
/// automatic query modes.<br/>
Property columnCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0);

/// This contains any conditional formatting rules for the table.
Property formatRules As list Of pivotCondition(XMLNAME = "formatRule", XMLPROJECTION = "ELEMENT");

/// This contains any local calculated members for the table.
Property calculatedMembers As list Of calculatedMember(XMLNAME = "calculatedMember", XMLPROJECTION = "ELEMENT");

/// This specifies the current selected range of cells as a
/// comma-separated list of integers. The list is of the form:<br/>
/// startRow,startCol,endRow,endCol,allRows,allCols<br/>
/// All cells numbers are 1-based and represent the ordinal position of cells as they
/// are displayed and not their position within the underlying query 
/// (e.g., when columns are sorted, these are still 1,2,3).<br/>
/// If allRows is 1, then all rows for indicated columns are selected.<br/>
/// If allCols is 1, then all columns for indicated rows are selected.<br/>
/// If the range is equal to "", then no cells are selected.
Property selectedRange As %ZEN.Datatype.csv;

/// Background color applied to the selected cell range.
Property selectedCellBackground As %ZEN.Datatype.style [ InitialExpression = "rgb(47,98,128)" ];

/// Color applied to the selected cell range.
Property selectedCellColor As %ZEN.Datatype.style [ InitialExpression = "white" ];

/// Optional style to apply to column headers.
Property columnHeaderStyle As %ZEN.Datatype.style;

/// Optional style to apply to row headers.
Property rowHeaderStyle As %ZEN.Datatype.style;

/// Optional style to apply to cells.
Property cellStyle As %ZEN.Datatype.style;

/// Optional style to apply to entire table
Property tableStyle As %ZEN.Datatype.style [ InitialExpression = "background-color:white" ];

/// If true, show zebra striping.
Property showZebra As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, show a caption above the row headers.
Property showRowCaption As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Holder for row caption text.
Property rowCaptionText As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Optional style to apply to even rows in zebra stripe mode.
Property evenRowStyle As %ZEN.Datatype.style;

/// If set, this is the name of the color-scaling scheme to apply.
/// red-to-black,green-to-black,blue-to-black,salmon-to-black,purple-to-black,gray-to-black
/// or "custom:r1,g1,b1:r2,g2,b2".
Property colorScale As %ZEN.Datatype.string;

/// Special flag to indicate use of pivot within the Analyzer.
/// For now this turns on a background image.
Property analyzerMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional image to show in background of pivot table.
Property backgroundImage As %ZEN.Datatype.uri;

/// Opacity (0 to 1) of pivot table background image.
Property backgroundOpacity As %ZEN.Datatype.float [ InitialExpression = 0.12 ];

/// When set true, the current query is executed as a DRILLTHROUGH.<br/>
/// If the current data source is a KPI, then execute a listing provided by the KPI (if available).
Property isDrillThrough As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// User-defined set of parameters. These values are passed on
/// to the user callback functions that provides the contents of 
/// this table. Typically this is used to hold search parameters.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// If set, then only one cell is displayed with this message text.
Property %message As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// If set this will contain the current message for display in the progress indicator.
Property progressMessage As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// If true, then display row totals.
Property rowTotals As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, then display column totals.
Property columnTotals As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Indicate which aggregate to use for row totals: sum,min,max,count,avg,pct.
Property rowTotalAgg As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "sum", Internal ];

/// Indicate which aggregate to use for column totals: sum,min,max,count,avg,pct.
Property columnTotalAgg As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "sum", Internal ];

/// Indicate the source for row totals: "page" or "all".
Property rowTotalSource As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "page", Internal ];

/// Current DeepSee result set being processed.
Property %ResultSet As %DeepSee.ResultSet(XMLPROJECTION = "none") [ Internal ];

/// Current data controller used to get KPI data.
Property %KPIController As %ZEN.Auxiliary.dataController(XMLPROJECTION = "none") [ Internal ];

/// The client-side object graph referred to by this property contains the most recent
/// data for this pivot table.
Property data As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// oncellClick event handler:
/// This event handler is called by the pivot
/// when the user clicks the mouse on a cell within the pivot table.<br/>
/// The event handler is passed an argument, <var>pivot</var>,
/// that is <i>this</i> pivot table object.
Property oncellClick As %ZEN.Datatype.eventHandler;

/// oncellDblClick event handler:
/// This event handler is called by the pivot
/// when the user double clicks the mouse on a cell within the pivot table.<br/>
/// The event handler is passed an argument, <var>pivot</var>,
/// that is <i>this</i> pivot table object.
Property oncellDblClick As %ZEN.Datatype.eventHandler;

/// ondrill event handler:
/// This event handler is called by the pivot
/// whenever the drill down state of the pivot is changed.<br/>
/// The event handler is passed an argument, <var>pivot</var>,
/// that is <i>this</i> pivot table object.
Property ondrill As %ZEN.Datatype.eventHandler;

/// onlistingSelect event handler:
/// This event handler is called by the pivot
/// when the user selects or unselected an item within a pivot listing.<br/>
/// The event handler is passed an argument, <var>pivot</var>,
/// that is <i>this</i> pivot table object.
Property onlistingSelect As %ZEN.Datatype.eventHandler;

/// Internal flag. Set true when paging among query results.
Property isPaging As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, then automatically execute queries when this pivot is first displayed.
Property initialExecute As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true then automatically execute queries when filters, rows, or columns are changed.
Property autoExecute As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Initial value of previewMode setting for the Analyzer
Property previewMode As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Allow the user to interact with the pivot even in preview mode.
Property allowPreviewInteraction As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 1 ];

/// The row limit used to truncate while in SAMPLE mode.
Property previewRowCount As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 25 ];

/// This flag is set when the resultset has seen its rows truncated by a HEAD function.
Property rowsTruncated As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// If autoExecute is off, then this tracks that a refresh is needed.
Property changesPending As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Internal property used to remember the set of selected row values.
Property selectedRowValues As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Title to display when pivot is printed.
Property printTitle As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Subtitle to display when pivot is printed.
Property printSubtitle As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Orientation when pivot is printed: "portrait" or "landscape".
Property printOrientation As %ZEN.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Display the subtitle when exporting to PDF
Property printSubtitleOn As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Display the user when exporting to PDF
Property showUser As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Page size when pivot is printed. This takes the form "8.5x11 in" (w x h).
Property printPageSize As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

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

/// showZebraStripes - on, off
Property showZebraStripes As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Font fize used in listing
Property listingFontSize As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// filterTableStyle
Property filterTableStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// filterTableCaptionStyle;
Property filterTableCaptionStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// filterTableItemStyle;
Property filterTableItemStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// nowDisplayFormat
Property nowDisplayFormat As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// If true, then write out HTML for this pivot
/// otherwise only serve up JSON data (to drive other components).
Property showPivot As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Maximum number of rows to display for a CROSSJOIN.
Property crossJoinRowLimit As %ZEN.Datatype.integer [ InitialExpression = 2000 ];

/// Flag to indicate a HEAD function has been added to an axis by the Analyzer
Property headFunctionAdded As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Run-time value of pivot variables used by this pivot.
Property pivotVariables As array Of %String(XMLPROJECTION = "NONE") [ Internal ];

/// Certain chart types may have different maximum sizes that make sense.
Property maxChartSize As %ZEN.Datatype.integer(XMLPROJECTION = "NONE") [ InitialExpression = 400 ];

/// Saves the session key of the latest executed query for access and clean-up of local cache
Property LastSessionKey As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Saves the cube name of the latest executed query for clean-up of local cache
Property LastCube As %ZEN.Datatype.string;

/// Saves the query key of the latest executed query for clean-up of local cache
Property LastQueryKey As %ZEN.Datatype.string;

/// defines the style sheet used by this component.
XData Style
{
<style type="text/css">

	/* WAL */
	/* WAL nub */
div.dsNub {
	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
	
	text-align: left;
	vertical-align: bottom;
	color: #404040;
	font-size: 7pt;
	overflow: hidden;
}

div.dsNubInner {
	font-weight: bold;
	padding-left:2px;
	vertical-align: bottom;
	display: table-cell;
	
	border-bottom: 1px solid #D0D0D0;
}	

div.dsNubZebra {
	
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;

	background: #F0F0F0;
	background-image: none;
	text-align: left;
	vertical-align: bottom;

	color: #404040;
	font-size: 7pt;
	
	padding-left: 2px;
	overflow: hidden;
}

div.dsNub:hover,
div.dsNubZebra:hover {
	background: #FFEEAA;
}

div.dsPivotCompleteTable .dsPivotRowEven:hover,
div.dsPivotCompleteTable .dsPivotRowOdd:hover {
	background: #FFEEAA;
}


div.dsPivotCompleteTableDiv .dsPivotRowEven:hover,
div.dsPivotCompleteTableDiv .dsPivotRowOdd:hover {
	background: #FFEEAA;
}

.topTable, .sideTable, .dataTable, .nubTable {
	position: absolute;	
}

/* column label */
/*div.dsPivotColumn,*/
div.dsPivotColumnSort {
	font-weight: bold;
	font-size: 10pt;
	padding: 0px;
	text-align: center;
	vertical-align: middle;

	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
}
div.dsPivotColumnSort:hover {
	background: #FFEEAA;
}


div.dsPivotCompleteTable .dsPivotColumnZebra {
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	font-weight: bold;
	color: #404040;
	padding: 0px;
	text-align: center;
	vertical-align: middle;
	background: #F0F0F4;
	background-image: none;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

div.dsPivotCompleteTableDiv .dsPivotColumnZebra {
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	font-weight: bold;
	color: #404040;
	padding: 0px;
	text-align: center;
	vertical-align: middle;
	background: #F0F0F4;
	background-image: none;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

.dataTable .dsPivotRowEven {
	color: #404040;
	text-align: right;
	vertical-align: middle;
	background: #F0F0F4;
	background-image: none;
	border-right: none;
	border-bottom: none;
}

.dataTable .dsPivotRowOdd {
	color: #404040;
	text-align: right;
	vertical-align: middle;
	background: white;
	background-image: none;
	border-right: none;
	border-bottom: none;
}
.dataTable .dsPivotRowEven:hover{
	background: #FFEEAA;
}

.dataTable .dsPivotRowOdd:hover {
		background: #FFEEAA;
}

/* zebra stuff */
div.dsPivotCompleteTable .dsPivotColumnSortZebra {
	font-weight: bold;
	color: #404040;
	padding: 0px;
	text-align: center;
	vertical-align: middle;
	background: #F0F0F4;
	overflow: hidden;
	background-image: none;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

div.dsPivotCompleteTableDiv .dsPivotColumnSortZebra {
	font-weight: bold;
	font-size: 10pt;
	color: #404040;
	padding: 0px;
	text-align: center;
	vertical-align: middle;
	background: #F0F0F4;
	overflow: hidden;
	background-image: none;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

.sideTable .dsPivotRowEven {
	font-weight: bold;
	color: #404040;
	text-align: left;
	vertical-align: middle;
	background: #F0F0F4;
	background-image: none;
	border-right: none;
	border-bottom: none;
}

.sideTable .dsPivotRowOdd {
	font-weight: bold;
	color: #404040;
	text-align: left;
	vertical-align: middle;
	background: white;
	background-image: none;
	border-right: none;
	border-bottom: none;
}

div.dsPivotCompleteTable .dsPivotColumn:hover,
div.dsPivotCompleteTable .dsPivotRow:hover	{
	background: #FFEEAA;
	color: #404080;
}


div.dsPivotCompleteTableDiv .dsPivotColumn:hover,
div.dsPivotCompleteTableDiv .dsPivotRow:hover	{
	background: #FFEEAA;
	color: #404080;
}

div.dsPivotCompleteTable .dsPivotNum:hover,
div.dsPivotCompleteTable .dsPivotColumnZebra:hover,
div.dsPivotCompleteTable .dsPivotColumnSortZebra:hover {
	background: #FFEEAA;
}

div.dsPivotCompleteTableDiv .dsPivotNum:hover,
div.dsPivotCompleteTableDiv .dsPivotColumnZebra:hover,
div.dsPivotCompleteTableDiv .dsPivotColumnSortZebra:hover {
	background: #FFEEAA;
}

/* wrapper around row header */
/* WAL */
/* this makes sure the clickable area takes up the full amount of space */
/* PFS058 - Add white-space:nowrap to account for 1px difference in WebKit vs Gecko, padding will prevent display errors */
div.dsPivotRowDiv {
	padding-top: 2px;
	padding-left: 2px;
	padding-right: 10px;
	height:100%;
	width:100%;
	vertical-align: middle;
	display:table-cell;
	white-space:nowrap;
}

/* wrapper around column header */
/* PFS030 - Add text-align: center; to center column header text */
div.dsPivotColumnDiv {
	padding-top: 2px;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 2px;
	overflow: hidden;
	background: none;
	text-align: center;
	display:table-cell;
}

div.dsPivotColumnOuter {
	display: table;
	height: 100%;
	width: 100%;
}

/* WAL -- div version */
div.dsPivotCompleteTable {
	position: absolute;
	left:0;
	top:0;
	background: #D0D0D0;
	font-size: 10pt;
	padding: 0px;
	height: auto;
	font-family: Arial;
	border-collapse: collapse;
	box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
	/*border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;*/
}

/* row label */
div.dsPivotCompleteTable .dsPivotRow {
	text-align: left;
	vertical-align: middle;
	font-weight: bold;
	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

	border-bottom: 1px solid #D0D0D0;
}	

/* pick up row height from the cell height? */
div.dsPivotCompleteTable .dsPivotRow {
	/*height: 22px;*/
	overflow: hidden;
	vertical-align: middle;

	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0s;
	transition-timing-function: ease;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

/* row label */
div.dsPivotCompleteTableDiv .dsPivotRow {
	text-align: left;
	vertical-align: middle;
	font-weight: bold;
	font-size: 10pt;
	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

	border-bottom: 1px solid #D0D0D0;
}	

/* pick up row height from the cell height? */
div.dsPivotCompleteTableDiv .dsPivotRow {
	/*height: 22px;*/
	overflow: hidden;
	vertical-align: middle;

	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0s;
	transition-timing-function: ease;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

div.dsPivotCompleteTable .dsPivotColumn {
	text-align: left;
	vertical-align: middle;
	font-weight: bold;
	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

	border-bottom: 1px solid #D0D0D0;
}	

div.dsPivotCompleteTable .dsPivotColumn {
	/*height: 22px;*/
	overflow: hidden;
	vertical-align: middle;

	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	
	/*display: inline-block;*/

	-webkit-transition-property: background;
	-webkit-transition-duration: 0s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0s;
	transition-timing-function: ease;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}


div.dsPivotCompleteTableDiv .dsPivotColumn {
	font-weight: bold;
	font-size: 10pt;
	background: #C0C0C0;
	background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
	background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

	border-bottom: 1px solid #D0D0D0;
}	

div.dsPivotCompleteTableDiv .dsPivotColumn {
	/*height: 22px;*/
	overflow: hidden;

	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	
	/*display: inline-block;*/

	-webkit-transition-property: background;
	-webkit-transition-duration: 0s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0s;
	transition-timing-function: ease;

	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
}

.dsPivotNum {
	text-align: right;
}

div.dsPivotCompleteTable .dsptCellDiv {
	width: 100%;
	height: 100%;
	padding-top: 1px;
	/*
	padding-right: 2px;
	/*padding-left: 2px;
	
	padding-bottom: 1px;
	*/
	text-align: right;
	overflow: hidden;
	word-wrap: break-word;
}

div.dsPivotCompleteTable  .dsptCellDiv:hover {
	background: #FFEEAA;
}


div.dsPivotCompleteTable .dsPivotNum {
	
	border-right: 1px solid #E9E9E9;
	border-bottom: 1px solid #E9E9E9;

	overflow: hidden;
	vertical-align: middle;
	
	background: white;
	font-size: 10pt;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0.25s;
	transition-timing-function: ease;
}

div.dsPivotCompleteTable .dsPivotString {
	
	border-right: 1px solid #E9E9E9;
	border-bottom: 1px solid #E9E9E9;

	overflow: hidden;
	vertical-align: middle;
	
	background: white;
	font-size: 10pt;

	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
	transition-property: background;
	transition-duration: 0.25s;
	transition-timing-function: ease;
}
/* WAL */

	.dsPivotEnclosingDiv {
		/* hack for IE to make scroll bars appear */
		display: block;
		overflow: hidden;
	}

	.dsPivotTableWrapper {
		position: relative;

		height:100%;
		width:100%;
		display:block;
		overflow:hidden;
	}

	/* background image within wrapper */
	.dsPivotTableImage {
		position: absolute;
		top: 0px;
		left: 0px;
		height: 100%;
		width: 100%;
		background-image: none;
		background-repeat: no-repeat;
		background-size: 100% 100%;
		opacity: 0.1;
		filter: alpha(opacity=10);
	}


	/* used to display error message on bottom */
	.dsPivotError {
		position: absolute;
		padding: 2px;
		border-top: 1px solid black;
		font-weight: bold;
		color: red;
		background: white;
	}

	/* error displayed in main body of pivot */
	.pivotError {
		color: #404040;
		font-size: 24px;
		padding: 10px;
	}

	table.dsPivotTable {
		border: none;
		font-size: 10pt;
		table-layout:fixed;
		padding: 0px;
		height: auto;
		box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
	}

	table.dsPivotDataTable {
		background: white;
		font-size: 10pt;
		table-layout:fixed;
		padding: 0px;
		box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
	}

	table.dsPivotDataTableCB {
		background: white;
		font-size: 10pt;
		table-layout:fixed;
		padding: 0px;
		box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
	}

	.dsPivotSummary {
		font-size: 0.8em;
		margin: 20px;
	}

	/* message box displayed while pivot is updating. */
	.dsPivotMessage {
		z-index: 3;
		padding: 10px;
		top: 100px;
		left: 100px;
		position: absolute;
		border: 1px solid #808080;
		background: #F0F0FF;
		opacity: 0.9;
		color: #404040;
		padding: 2px;
		font-size: 1.2em;
		border-radius: 4px;
		box-shadow: 2px 2px 2px #808080;
	}

	/* percentage complete */
	.dsptPct {
		font-size: 2.0em;
		font-weight: bold;
	}

	.dsptDropMsg:hover {
		background: #FFEEAA;
	}

	.dsPivotRowSection {
		padding-top: 2px;
		padding-left: 5px;
		font-weight: bold;
	}

	/* column label */
	table th.dsPivotColumn,
	table th.dsPivotColumnSort {
		padding: 0px;
		text-align: center;
		vertical-align: middle;

		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
	}

	/* wrapper around column header */
	.dsPivotColumnDiv {
		padding-top: 2px;
		padding-left: 2px;
		padding-right: 2px;
		padding-bottom: 2px;
		overflow: hidden;
		background: none;
		display:table-cell;
	}
	
	/* zebra styles */
	.dsptRowOdd td {
		border-right: none;
		border-bottom: none;
	}

	.dsptRowEven td {
		background: #F0F0F4;
	}

	.dsptRowEven td {
		border-right: none;
		border-bottom: none;
	}

	table.dsPivotTable th.dsPivotColumnZebra {
		color: #404040;
		padding: 0px;
		text-align: center;
		vertical-align: middle;
		background: #F0F0F4;
		background-image: none;
		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}

	table.dsPivotTable th.dsPivotColumnSortZebra {
		color: #404040;
		padding: 0px;
		text-align: center;
		vertical-align: middle;
		background: #F0F0F4;
		overflow: hidden;
		background-image: none;

		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}

	table.dsPivotTable th.dsPivotRowEven {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: #F0F0F4;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}

	table.dsPivotTable th.dsPivotRowOdd {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: white;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}
	
	/* row label */
	table.dsPivotTable th.dsPivotRow {
		text-align: left;
		vertical-align: middle;
		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

		border-bottom: 1px solid #D0D0D0;
	}
	
	th.dsPivotRow {
		text-align: left;
		vertical-align: middle;
		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

		border-bottom: 1px solid #D0D0D0;
	}

	/* wrapper around row header */
	.dsPivotRowDiv {
		padding-top: 2px;
		padding-left: 2px;
		padding-right: 10px;
	}

	table.dsPivotTable th:hover {
		background: #FFEEAA;
		color: #404080;
	}

	table.dsPivotTable td, 
	table.dsPivotTable th {
		height: 22px;
		overflow: hidden;
		vertical-align: middle;

		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;

		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}

	table.dsPivotDataTable td {
		border-right: 1px solid #E8E8E8;
		border-bottom: 1px solid #E8E8E8;
		width: 100px;
		height: 22px;
		overflow: hidden;
		vertical-align: middle;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;
	}
	
	table.dsPivotDataTable td:hover {
		background: #FFEEAA;
	}

	table.dsPivotDataTableCB td {
		border-right: 1px solid #E8E8E8;
		border-bottom: 1px solid #E8E8E8;
		width: 100px;
		height: 22px;
		overflow: hidden;
		vertical-align: middle;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;
	}

	.dsPivotString {
	}

	.dsPivotDate {
	}

	.dsPivotNum {
		text-align: right;
	}

	.dsPivotIcon {
		text-align: center;
	}

	span.dsptDrillUp {
		cursor: pointer;
		padding-left: 4px;
		padding-right: 4px;
	}

	span.dsptDrillUp:hover {
		background: #DDCC88;
		border-radius: 4px;
	}

	span.dsptDrillUp:active {
		background: darkblue;
		color: white;
	}

	/* outer-most div used for layout */
	/* this div will also need to be resized based on the size of the table */
	.dsptOuterDiv {
		position: relative;
		width: 400px;
		height: 400px;
		overflow: hidden;
		visibility: hidden;
		z-index: 1;
	}
	
	.dsptHeaderDiv {
		position: absolute;
		top: 0px;
		left: 0px;
		right: 0px;
		height: 22px;
		overflow: hidden;
		text-align: center;
		font-weight: bold;

		border-right: 1px solid gray;
		border-bottom: 1px solid gray;

		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
	}

	.dsptTopLeftDiv {
		position: absolute;
		top: 0px;
		left: 0px;
		overflow: hidden;

		padding: 0px;

		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

		text-align: center;
		vertical-align: bottom;
		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;

		color: #404040;
		font-size: 10pt;
		font-weight: bold;
		cursor: pointer;
	}

	.dsptTopLeftDivZebra {
		position: absolute;
		top: 0px;
		left: 0px;
		overflow: hidden;

		padding: 0px;
		background: #F0F0F0;
		background-image: none;
		text-align: center;
		vertical-align: bottom;
		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;

		color: #404040;
		font-size: 10pt;
		font-weight: bold;
		cursor: pointer;
	}

	.dsptTopLeftDiv:hover,
	.dsptTopLeftDivZebra:hover {
		background: #FFEEAA;
	}

	/* wrapper around nub text */
	.dsNubDiv {
		position: absolute;
		bottom: 0px;
		left: 0px;
		text-align: left;
		vertical-align: bottom;
		color: #404040;
		font-size: 9pt;
		overflow: hidden;
		padding-bottom: 2px;
	}

	div.dsNubDiv table td {
		text-align: left;
		vertical-align: bottom;
		color: #404040;
		font-weight: bold;
		font-size: 7pt;
		padding-left: 2px;
		overflow: hidden;
	}

	.dsptTopRightDiv {
		position: absolute;
		top: 0px;
		left: 100px;
		width: 300px;
		height: 5px;
		overflow-y: hidden;
		overflow-x: hidden;
	}

	.dsptBottomLeftDiv {
		position: absolute;
		top: 5px;
		left: 0px;
		width: 100px;
		height: 345px;
		overflow-y: hidden;
		overflow-x: hidden;
		border-bottom: 1px solid #D0D0D0;
	}

	.dsptBottomRightDiv {
		position: absolute;
		top: 5px;
		left: 100px;
		width: 300px;
		height: 345px;
		overflow: hidden;
		border-bottom: 1px solid #D0D0D0;
	}

	/* this runs along the bottom of the component */
	.dsptStatusDiv {
		border-top: 1px solid #808080;

		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

		position: absolute;
		top: 350px;
		left: 0px;
		right: 0px;
		height: 32px;
		overflow: hidden;
		padding: 1px;
		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}

	.dsptStatusLabel {
		font-size: 11px;
	}

	.dsptStatusValue {
		padding-left: 5px;
		font-weight: bold;
		font-size: 11px;
	}

	.dsptDropMsg,
	.dsptDropMsg:link,
	.dsptDropMsg:active,
	.dsptDropMsg:visited {
		font-size: 0.8em;
		color: #909090;
		font-style: italic;	
		text-decoration: none;
	}

	.dsptTitle {
		font-weight: bold;
		font-size: 1.1em;
		border-left: 1px solid darkgray;
	}

	/* image */
	.dsptIconBar {
		vertical-align: bottom;
	}

	.dsptIcon,.dsptIconDisabled,.dsptIconHover,.dsptIconDropdown,.dsptIconDropdownSelect {
		border: 1px solid transparent;
		vertical-align: bottom;
		margin-left: 1px;
		margin-right: 1px;
		padding: 1px;
		border: 1px solid transparent;
		border-radius: 4px;
		-webkit-transition-property: background,opacity,transform;
		-webkit-transition-duration: 0.5s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background,opacity,transform;
		-moz-transition-duration: 0.5s;
		-moz-transition-timing-function: ease;
		transition-property: background,opacity,transform;
		transition-duration: 0.5s;
		transition-timing-function: ease;
	}

	.dsptIcon {
		cursor: pointer;
	}

	.dsptIcon:hover, .dsptIconHover {
		background: #FFEEAA;
		border: 1px solid rgba(120,120,120,0.25);
		vertical-align: bottom;
	}

	.dsptIcon:active,.dsptIconHover:active {
		background: white;
		border: 1px solid white;
		box-shadow: 2px 2px 2px #FFEEAA, -2px -2px 2px #FFEEAA;
	}

	.dsptIconDisabled {
		opacity:0.40;
		filter:alpha(opacity=40);
	}
	
	.dsptIconDropdown:hover {
		background: #FFEEAA;
		border: 1px solid rgba(120,120,120,0.25);
		vertical-align: bottom;
	}
	
	.dsptIconDropdownSelect {
		background: #80808040;
		border: 1px solid rgba(120,120,120,0.25);
	}
	
	.dsptIconDropdownMenu {
		font-size: 11px;
		display: none;
  		position: absolute;
  		min-width: 120px;
  		z-index: 1;
  		background-color: #f1f1f1;
  		border:0.5px;
  		border-color:black;
  		border-style:solid;
	}
	
	.dsptIconDropdownMenu a {
		display: block;
		padding:10px;
	}
	
	.dsptIconDropdownMenu a:hover {
		background-color: #ddd;
	}

	/* scroll bars: use 22px instead of "auto" for ie! */
	.dsptVtScroll {
		z-index: 2;
		position: absolute;
		width: 22px;
		overflow-y: scroll;
		overflow-x: hidden;
	}
	.dsptVtScrollInner {
		height: 100px;
		width: 15px;
	}

	.dsptHzScroll {
		z-index: 2;
		position: absolute;
		height: auto;
		overflow-x: scroll;
		overflow-y: hidden;
		height: 20px;
	}
	.dsptHzScrollInner {
		height: 15px;
		width: 100px;
	}

	/* listing table */
	table.dsListingTable {
		background: white;
		font-size: 10pt;
		table-layout:fixed;
	}

	table.dsListingTable tr.selectedRow {
		background: rgb(47,98,128);
	}

	table.dsListingTable tr.evenRow {
		background: #F8F8F8;
	}

	table.dsListingTable tr.oddRow {
		background: white;
	}

	table.dsListingTable th {
		color: #404040;
		text-align: left;
		padding: 0px;
	}

	table.dsListingTable th.dsListingColumn,
	table.dsListingTable th.dsListingColumnSort {
		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
	}

	table.dsListingTable td {
		padding: 0px;
		padding-top: 2px;
		padding-bottom: 2px;
		color: #404040;
	}

	table.dsListingTable td.number {
		text-align: right;
		color: #404040;
	}

	table.dsListingTable tr.selectedRow td {
		color: white;
	}

	table.dsListingTable tr.selectedRow td.number {
		color: white;
	}

	.dsptCellDiv {
		padding-right: 2px;
		padding-left: 2px;
		padding-top: 1px;
		padding-bottom: 1px;
		text-align: right;
		overflow: hidden;
		word-wrap: break-word;
	}

	.dsptListCellDiv {
		padding-right: 4px;
		padding-left: 4px;
		padding-top: 1px;
		padding-bottom: 1px;
		background: none;
		text-align: left;
		overflow: hidden;
	}

	.dsptPlanItem {
		font-size: 11pt;
		border: 1px solid #404040; 
		border-radius: 4px;
		padding: 4px;
		box-shadow: 2px 2px 2px #808080;
	}

	table td.dsptShowMore {
		font-size: 10pt;
		font-weight: bold;
		color: #404040;
		border: 1px solid #808080; 
		border-radius: 4px;
		padding: 2px;
		background: #F0F0F0;
	}

	.dsptShowMore:hover {
		background: #FFEEAA;
	}

	.dsptShowMore:active {
		background: white;
		box-shadow: 2px 2px 2px white, -2px -2px 2px white;
	}
	
	/* + WAL106 -- div that wraps the single table */
	.dsPivotCompleteTableDiv {
		position: absolute;
		width: 400px;
		height: 400px;
		overflow: hidden;
		visibility: hidden;
		z-index: 1;
	}
	/* - WAL106 */

	/* + WAL106 -- styling for single pivot table */
	table.dsPivotCompleteTable {
		position: relative;
		/*border: none;*/
		background: #D0D0D0;
		font-size: 10pt;
		table-layout:fixed;
		padding: 0px;
		height: auto;
		font-family: Arial;
		border-collapse: collapse;
		box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;
	}
	/* - WAL106 -- styling for single pivot table */
	
	/* WAL -- div version */
	div.dsPivotCompleteTable {
		
		width: 400px;
		height: 400px;
		
		position: relative;
		/*border: none;*/
		background: #D0D0D0;
		font-size: 10pt;
		padding: 0px;
		height: auto;
		font-family: Arial;
		border-collapse: collapse;
		box-shadow: 2px 2px 25px rgba(0,0,0,0.25);
		/*border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;*/
	}
	
	/* WAL */
	.topLabels {
		position: absolute;	
	}
	
	/* + WAL106 -- top/side table styling */
	table.dsPivotCompleteTable th {
		height: 22px;
		overflow: hidden;
		vertical-align: middle;

		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;

		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}
	
	/* row label */
	table.dsPivotCompleteTable th.dsPivotRow {
		text-align: left;
		vertical-align: middle;
		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */

		border-bottom: 1px solid #D0D0D0;
	}
	
	table.dsPivotCompleteTable th.dsPivotColumnZebra {
		color: #404040;
		padding: 0px;
		text-align: center;
		vertical-align: middle;
		background: #F0F0F4;
		background-image: none;
		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}
	
	/* zebra stuff */
	table.dsPivotCompleteTable th.dsPivotColumnSortZebra {
		color: #404040;
		padding: 0px;
		text-align: center;
		vertical-align: middle;
		background: #F0F0F4;
		overflow: hidden;
		background-image: none;

		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
	}
	
	table.dsPivotCompleteTable th.dsPivotRowEven {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: #F0F0F4;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}

	table.dsPivotCompleteTable th.dsPivotRowOdd {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: white;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}
	
	table.dsPivotCompleteTable th:hover {
		background: #FFEEAA;
		color: #404080;
	}
	/* + WAL106 - top/side table styling */
	
	/* + WAL106 data table styling */	 
	table.dsPivotCompleteTable td {
		border-right: 1px solid #E8E8E8;
		border-bottom: 1px solid #E8E8E8;
		width: 100px;
		height: 22px;
		overflow: hidden;
		vertical-align: middle;
		
		background: white;
		font-size: 10pt;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;
	}
	
	table.dsPivotCompleteTableKPI td {
		border-right: 1px solid #E8E8E8;
		border-bottom: 1px solid #E8E8E8;
		width: 100px;
		height: 22px;
		overflow: hidden;
		vertical-align: middle;
		
		background: white;
		font-size: 10pt;

		-webkit-transition-property: background;
		-webkit-transition-duration: 0.25s;
		-webkit-transition-timing-function: ease;
		-moz-transition-property: background;
		-moz-transition-duration: 0.25s;
		-moz-transition-timing-function: ease;
		transition-property: background;
		transition-duration: 0.25s;
		transition-timing-function: ease;
	}

	/* zebra stuff */
	table.dsPivotCompleteTable td.dsPivotRowEven {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: #F0F0F4;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}

	table.dsPivotCompleteTable td.dsPivotRowOdd {
		color: #404040;
		text-align: left;
		vertical-align: middle;
		background: white;
		background-image: none;
		border-right: none;
		border-bottom: none;
	}
	
	table.dsPivotCompleteTable td:hover {
		background: #FFEEAA;
	}
	/* - WAL106 data table styling */
	
	/* + WAL106 nub table styling */
	table.dsPivotCompleteTable th.dsNub {

		background: #C0C0C0;
		background: -moz-linear-gradient(top,  #f8f8f8 0%, #c0c0c0 100%); /* FF3.6+ */
		background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f8f8f8), color-stop(100%,#c0c0c0)); /* Chrome,Safari4+ */
		background: -webkit-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Chrome10+,Safari5.1+ */
		background: -o-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* Opera 11.10+ */
		background: -ms-linear-gradient(top,  #f8f8f8 0%,#c0c0c0 100%); /* IE10+ */
		background: linear-gradient(to bottom,  #f8f8f8 0%,#c0c0c0 100%); /* W3C */
		
		text-align: left;
		vertical-align: bottom;
		color: #404040;
		font-size: 7pt;
		padding-left: 2px;
		overflow: hidden;
		
		/*border: none; */
		/* WAL106 -- override right border when needed in %DrawTable */
		border-right: 1px solid #D0D0D0;
		border-bottom: 1px solid #D0D0D0;
	}
	
	table.dsPivotCompleteTable th.dsNubZebra {

		background: #F0F0F0;
		background-image: none;
		text-align: left;
		vertical-align: bottom;

		color: #404040;
		font-size: 7pt;
		
		padding-left: 2px;
		overflow: hidden;
	}
	
	table.dsPivotCompleteTable th.dsNub:hover,
	table.dsPivotCompleteTable th.dsNubZebra:hover {
		background: #FFEEAA;
	}
	/* - WAL106 nub table styling */

	/* +DTB701 */
	.coverPaneActive {
		position:absolute;
		left:0px;
		right:0px;
		top:0px;
		bottom:0px;
		opacity:.2;
		background:grey;
		display:block;
	}
	
	.coverPaneInactive {
		position:absolute;
		left:0px;
		top:0px;
		width:0px;
		height:0px;
		display:block;
	}
	/* -DTB701 */

	</style>
}

/// Execute a query after a short pause (to allow for window updates, etc.
ClientMethod deferredExecuteQuery(force) [ Internal, Language = javascript ]
{
	window.setTimeout('zenPage.getComponent('+this.index+').executeQuery('+(force?'true':'false')+');',10);
}

/// Execute the current query for this pivot table and
/// update the display.<br/>
/// If <var>force</var> is true, then force the query
/// to be prepared.
ClientMethod executeQuery(force) [ Language = javascript ]
{
	if (force) {
		this.currPage = 1;
		this.currListingPage = -1;
		this.isPaging = false;
		this.queryKey = '';
	}
	else if (!this.autoExecute && !this.isPaging) {
		// do nothing
		this.changesPending = true;
		this.updateController();
		return;
	}

	this.changesPending = false;
	this.queryCalls = 0;
	this.queryStatus = 0;
	if (this.isDrillThrough) {
		this.showMessage($$$Text('Generating listing...'),'',true);
	}
	else {
		this.showMessage($$$Text('Working...'),this.queryComplete);
	}
	this._runningQuery = true;
	// JMD1023 - make async
	// this.refreshContents(true);
	// JMD1101 - make sync again!
	
	var prevCanDrillDown = this.canDrillDown;
	this.refreshContents(true);
	this.canDrillDown = prevCanDrillDown;
	this.updateController();
	
	// DTB714 - Reset table's previewMode from the environment setting
	if (zenPage.previewMode) {
		this.previewMode = zenPage.previewMode;
	}
	
	// reset limit
	// DP-408943 - If the pivot is in preview mode, reset the CJ row limit to default to 
	// limit display of large resultsets at 20 pages.
	if (this.previewMode) {
		this.crossJoinRowLimit = parseInt(this.pageSize,10) * 20;
	}
}

/// Execute a drill through for the current selected cell.
ClientMethod executeListing() [ Language = javascript ]
{
	this.showMessage($$$Text('Generating listing...'),'',true);
	this.refreshContents();
}

/// Cancel the current query for this pivot table and
/// update the display.
ClientMethod cancelQuery() [ Language = javascript ]
{
	if (null == this._inCancel) {
		if (this._queryTimerId) {
			this._inCancel = true;
			this.stopQueryTimer();
			this.showMessage($$$Text('Cancelling...'),'');
			this.sendEventToViews('endWait');
			var ok = this.KillQuery(this.cubeName,this.queryKey,'');
			if (!ok) {
				alert($$$Text('Unable to cancel query...'));
			}
			delete this._inCancel;
			this.resetTable();
		}
		else if (this._runningQuery && false) {
			// query is not fully set up yet
			this._inCancel = true;
			this.stopQueryTimer();
			var ok = this.KillQuery('','',this.pivotNonce);
			if (!ok) {
				alert($$$Text('Unable to cancel query...'));
			}
			delete this._inCancel;
		}
	}
}

/// Swap the row and column definitions for this table and refresh it.
ClientMethod swapRowsAndColumns() [ Language = javascript ]
{
	// do not allow swap when drilled down
	if (this.drillLevels.length>0) {
		return;
	}

	if (this.rowLevels.length > 0 || this.columnLevels.length > 0) {
		this.pushState();

		var temp = this.rowLevels;
		this.rowLevels = this.columnLevels;
		this.columnLevels = temp;
		temp = this.rowAxisOptions;
		this.rowAxisOptions = this.columnAxisOptions;
		this.columnAxisOptions = temp;

		this.currPage = 1;
		this.currListingPage = -1;
		this.selectedRange = '';
		this.sortColumn = 0;
		this.sortDir = 'ASC';
		this.executeQuery(this.autoExecute);
	}
}

/// Return the range of selected cells or null if nothing selected.<br/>
/// The range is returned as an array of startRow,startCol,endRow,endCol,allRows,allCols.
ClientMethod getSelectedRange() [ Language = javascript ]
{
	if (''==this.selectedRange) {
		return null;
	}
	return this.selectedRange.split(',');
}

/// Reset this table to default settings.
ClientMethod resetTable() [ Language = javascript ]
{
	this.pushState();
	this.isPaging = false;
	this.currPage = 1;
	this.currListingPage = -1;
	this.queryKey = '';
	this.queryCalls = 0;
	this.measures = new Array();
	this.measureLocation = 'columns';
	this.selectedRange = '';
	this.sortColumn = 0;
	this.sortDir = 'ASC';
	this.filters = new Array();
	this.rowLevels = new Array();
	this.columnLevels = new Array();
	this.drillLevels = new Array();
	this.drillRowNumbers = new Array(); // WAL224
	this.listingFilters = new Array();
	this.crossJoinRowLimit = parseInt(this.pageSize,10) * 20; 	// JMD1129, JMD1304

	this.pivotVariables = {};

	this.LastSessionKey = 0;
	this.LastCube = '';
	this.LastQueryKey = '';

	this.overrideRowSpec = '';
	this.overrideColumnSpec = '';
	this.overrideRowText = '';
	this.overrideColumnText = '';

	this.rowAxisOptions = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
	this.columnAxisOptions = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');

	if (this.isDrillThrough) {
		this.mdx = '';
		this.isDrillThrough = false;
		this.executeQuery(true);
	}
	else {
		this.executeQuery();
	}

	if (zenPage.UpdateFilterControls) {
		var msg = zenPage.UpdateFilterControls(this.cubeName,zen('filterGroup'),this);
		if (''!==msg) {
			alert(msg);
		}
	}
}

/// Test if this pivot supports drill through.
ClientMethod canDrillThrough() [ Language = javascript ]
{
	// JMD1031 Allow listing in manual mode
	if (''===this.kpi) {
		return this.listingEnabled;
	}
	else if(''!==this.kpi) {
		return true;
	}
	return false;
}

/// Toggle drill through state of this pivot.
/// If not in drill through mode, execute a drill through: show a listing for the current selected range of cells.
/// else restore normal view.
/// Return true if the operation took place.
ClientMethod drillThrough() [ Language = javascript ]
{
	return this.setDrillThrough(!this.isDrillThrough);
}

/// Set the drill through state of this pivot to <var>flag</var>.<br/>
/// If true, execute a drill through: show a listing for the current selected range of cells.
/// else restore normal view.
/// Return true if the operation took place.
ClientMethod setDrillThrough(flag, force) [ Language = javascript ]
{
	force = ('undefined' == typeof force) ? false : force;
	if (!this.canDrillThrough()) {
		return false;
	}

	if (flag == this.isDrillThrough && !force) {
		return false;
	}
	
	if (flag) {
		if ('' == this.selectedRange && '' == this.kpi) {
			alert($$$Text('Please select a cell to display a listing for.\nNote that you can select multiple adjacent cells by holding the Shift key down while clicking the mouse.'));
			return false;
		}

		this.selectedRowValues = '';
		if ('' != this.kpi) {
			// get values for selected rows
			var list = this.getSelectedItems();
			// escape ',' in values with \,
			if (list) {
				for (var n = 0; n < list.length; n++) {
					if (list[n] && list[n]!='' && 'string'==typeof list[n]) {
						list[n] = list[n].replace(/\,/g,'\\,');
					}
				} 
			}
			this.selectedRowValues = list ? list.join(',') : '';
		}

		// DTB118 - drillUp no longer uses goBack(), the listing can be remembered. 
		this.pushState();
			
		// reset sort
		this.listingSortColumn = '';
		this.listingSortDir = 'ASC';
		this.isDrillThrough = true;

		this.executeListing();
	}
	else {
		if (this.drillLevels.length==0) {
			this.pushState();
		}
		this.mdx = '';
		this.queryKey = '';
		this.isDrillThrough = false;

		this.executeQuery(true);
	}
	return true;
}

/// Toggle display of the current query.
ClientMethod showMDXQuery() [ Language = javascript ]
{
	this.setProperty('showQuery',!this.getProperty('showQuery'));
	this.refreshContents();
}

/// Make sure any text within this list of pivot levels is localized!
Method %LocalizeElements(pCubeClass As %String, pList As %ListOfObjects) [ Internal ]
{
	For n = 1:1:pList.Count() {
		Set tPivotLevel = pList.GetAt(n)
		If ($IsObject(tPivotLevel)&&(tPivotLevel.spec'="")) {
			Set tValue = tPivotLevel.value
			If $E(tValue,1,8)="$$$FIELD" {
				// DTB309 - This is a saved listing field. Query its localized caption from the cube.
				Set tCaption = $classmethod(pCubeClass,"%GetListingFieldCaption",$E(tValue,10,*))
			}
			Else {
				// Standard MDX pivotLevel
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tPivotLevel.spec,.tSpecInfo,.tQuoted)
				Set tDim = $$$UPPER($G(tSpecInfo(1)))
				Set tHier = $$$UPPER($G(tSpecInfo(2)))
				Set:tHier="%TOPMEMBERS" tHier = ""
				Set tLevel = $$$UPPER($G(tSpecInfo(3)))
				Set tKey = $$$UPPER($G(tSpecInfo(4)))

				// check for property reference
				Set tProp = ""
				If ($P($$$UPPER(tPivotLevel.spec),".CURRENTMEMBER.PROPERTIES(""",2)'="") {
					Set tProp = $P($$$UPPER(tPivotLevel.spec),".CURRENTMEMBER.PROPERTIES(""",2)
					Set tProp = $P(tProp,""")",1)
				}
				Set tCaption = ""
				If ((tDim="MEASURES")&&(tHier'="")) {
					Set tCaption = $classmethod(pCubeClass,"%GetMemberCaption",tDim,tHier)
				}
				// + WAL042 -- handle ALL member
				ElseIf ((tLevel="")&&(tHier["ALL")) {
					Set tCaption = $classmethod(pCubeClass,"%GetMemberCaption",tDim,tHier)
				}
				// - WAL042
				ElseIf (tLevel'="") {
					If (tProp'="") {
						Set tCaption = $classmethod(pCubeClass,"%GetMemberCaption",tDim,tHier,tLevel,tProp)
					}
					// JMD857
					ElseIf ((tKey="MEMBERS")||(tKey="ALLMEMBERS")) {
						Set tCaption = $classmethod(pCubeClass,"%GetMemberCaption",tDim,tHier,tLevel)
					}
				}
			}

			// PFS091 - Always update caption, even if tCaption is empty
			Set tPivotLevel.caption = tCaption
			// WAL246 -- comment this out since it causes problems with excel/pdf export
			//           filter names
			//Set tPivotLevel.text = tCaption		// DTB309 - Both of these get used
			Do ..%LocalizeElements(pCubeClass, tPivotLevel.childLevels)
		}
	}
}

/// Updates the SessionKey, Cube, and QueryKey properties with the current session data, and deletes the previous session data from the cache
Method %UpdateLocalSession() As %Status
{
	Set tSC = $$$OK

	Try {
		Do ..DeleteLastResult()

		Set ..LastSessionKey = ..%ResultSet.%SessionKey
		Set ..LastCube = ..%ResultSet.%Cube
		Set ..LastQueryKey = ..%ResultSet.%QueryKey

		Set ..%ResultSet.%KeepLocalResults = 1

	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Deletes the previous session data from the local cache. Called from the frontend
Method DeleteLastResult() As %String [ ZenMethod ]
{
	Set tSC = $$$OK

	Try {
		Set tRS = ##class(%DeepSee.ResultSet).%New()

		Set tRS.%SessionKey = ..LastSessionKey
		Set tRS.%Cube = ..LastCube
		Set tRS.%QueryKey = ..LastQueryKey

		Do tRS.%ClearLocalResult()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit $system.Status.GetOneErrorText(tSC)		// DP-414702
}

/// Delete the latest query from local cache in asynchronous mode before unloading
ClientMethod onunloadHandler() [ Language = javascript ]
{
	var modeTemp = zenSynchronousMode;
	zenSynchronousMode = false;
	this.DeleteLastResult();
	zenSynchronousMode = modeTemp;
}

/// Draw HTML for this component.
Method %DrawHTML()
{
	Set tSC = $$$OK
	Try {
		Set tQueryText = ""
		Set tErrorMsg = ""
		Set tTableDrawn = 0
		Set ..totalValue = "ERROR"
		Set tCubeName = $$$ZENVAL(..cubeName)
		Set tCubeIndex = $S((tCubeName'=""):$$$DeepSeeIndex(tCubeName),(..cubeKey'=""):..cubeKey,1:"")		// DTB618
		Set tIsPaging = ..isPaging
		Set ..isPaging = 0
		Set ..columnsTruncated = 0
		Set ..queryPending = 0
		Set tPending = 0
		Set tExecuteBaseQuery = 0		// DTB107

		// if there is a pending error message, show it
		If (..%message'="") {
			Set tErrorMsg = ..%message
			Set ..%message = ""
			Quit
		}
		Set ..%message = ""

		// reset cancel flag
		New %dsPivotNonce
		If (..pivotNonce'="") {
			Set %dsPivotNonce = ..pivotNonce
			Kill ^DeepSee.Cancel(..pivotNonce)
			//Lock +^DeepSee.Pivot(..pivotNonce)
		}

		// !!! let other requests get through
		// need for cancel, but interferes with dashboards !!!
		// Do %session.Unlock(0)

		// create a new session (or use the one currently in scope)
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			If $$$ISERR(tSC) {
				Set tErrorMsg = $$$Text("Error creating DeepSee session.","%DeepSee")
			}
			Set tSession = $G($$$DeepSeeSession)
		}

		// n.b., create session before drawing KPI so that user init code is run
		If (..kpi'="") {
			// JMD978: If initial execute is off, don't run the query
			If (('..initialExecute) && ($G(%zenContext) = "page")) {
				Quit
			}
			Set tSC = ..%DrawKPITable()
			Quit
		}

		If ((..userMDX=" ")||((..userMDX="")&&(tCubeName=""))) {
			Set tErrorMsg = $$$Text("Please select a subject area to display.","%DeepSee")
			Quit
		}

		// Set cubeKey to normalized cube index name
		Set tAutoMode = 0
		If (..userMDX'="") {
			// JMD1031 add userMDX
			Set tAutoMode = 1

			// JMD1057 test for missing cubename
			If ($$$ZENVAL(..cubeName)="") {
				// find the cube name from the query
				Set tQuery = ##class(%DeepSee.Query.query).%New()
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDX(..userMDX,tQuery)
				If $$$ISERR(tSC) {
					Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (10)"
					Quit
				}
				Set tCubeName = tQuery.cube
				Set ..cubeName = tCubeName
			}
			Set ..mdx = ..userMDX
		}
		ElseIf ((tCubeName'="") && (..dataSource="automatic")) {
			Set tAutoMode = 1
		}
		Set ..cubeKey = $$$DeepSeeIndex($$$UPPER(tCubeName))
		
		// test if the cube is available
		If (tCubeName'="") {
			If ('##class(%DeepSee.Utils).%IsCubeAvailable(tCubeName,.tReason)) {
				Set tErrorMsg = tReason
				Quit
			}
		}
		If (..mdx = " ") {
			Set tErrorMsg = " "
			Quit
		}

		// JMD: make sure any references to cube elements are localized
		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName)
		Do ..%LocalizeElements(tCubeClass,..rowLevels)
		Do ..%LocalizeElements(tCubeClass,..columnLevels)
		Do ..%LocalizeElements(tCubeClass,..measures)
		Do ..%LocalizeElements(tCubeClass,..filters)
		Do ..%LocalizeElements(tCubeClass,..listingFields)		// DTB309 - Localize listingFields too

		&html<<div class="dsPivotTableWrapper">>

		#; scroll bars (initially hidden)
		&html<<div class="dsptVtScroll" style="display:none;" id="#(..%MakeId("vtScroll"))#" onscroll="zenPage.getComponent(#(..index)#).cellScrollVt();"><div class="dsptVtScrollInner" id="#(..%MakeId("vtScrollInner"))#">&nbsp;</div></div>>
		&html<<div class="dsptHzScroll" style="display:none;" id="#(..%MakeId("hzScroll"))#" onscroll="zenPage.getComponent(#(..index)#).cellScrollHz();"><div class="dsptHzScrollInner" id="#(..%MakeId("hzScrollInner"))#">&nbsp;</div></div>>

		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $$$ZENVAL(value)
			Set key = ..parameters.Next(key)
		}

		#; get filter information
		If (tAutoMode) {
			Set tSC = ..%GetFilterInfo(.tFilterInfo,.tAdvancedFilters)
			If $$$ISERR(tSC) Quit
		}
		
		If (..queryKey '= "") {
			// re-open existing query
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tRS.%Recompute = 1
			Set ..%ResultSet = tRS
			Set tSC = tRS.%PrepareKey(##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(..cubeName),..queryKey)
			If $$$ISERR(tSC) {
				// This condition is encountered if a reset happens between load of the MDX
				// and execution of the listing
				// try anew
				Set ..queryKey = ""
				Set tSC = $$$OK
				// reset listing filters
				Set tExecuteBaseQuery = 1		// DTB107
				Do ..listingFilters.Clear()
			}
			ElseIf (..isDrillThrough) {
				// DTB857 - Execute the query prepared by key to make results available
				Set tSC = tRS.%ExecuteParameters(.tParms)		// DTB857 (2) - Use %ExecuteParameters
				If $$$ISERR(tSC) Quit
					
				// JMD1360: listing filters are the filters based on the 
				// selected cell(s) for the drillthrough; not the filter control values
				// only compute the listing filters the first time
				If (..listingFilters.Count()=0) {
					Do ..listingFilters.Clear()

					// create drill through out of current query
					Set r1 = +$P(..selectedRange,",",1)
					Set c1 = +$P(..selectedRange,",",2)
					Set r2 = +$P(..selectedRange,",",3)
					Set c2 = +$P(..selectedRange,",",4)
					Set tAllRows = +$P(..selectedRange,",",5)
					Set tAllCols = +$P(..selectedRange,",",6)
					Set:r1=0 r1=1
					Set:c1=0 c1=1
					Set:r2=0 r2=r1
					Set:c2=0 c2=c1
					
					// + WAL170
					Set tSC = tRS.%GetFiltersForCellRange(.tListingFilters,r1,c1,r2,c2,,tAllRows,tAllCols,..sortColumn,..sortDir,.tPlugInInfo)
					Merge tPlugInInfo("FILTERS") = tListingFilters
					// - WAL170
					
					Set tSC = tRS.%GetFiltersForCellRange(.tListingFilters,r1,c1,r2,c2,,tAllRows,tAllCols,..sortColumn,..sortDir)
					
					If $$$ISERR(tSC) {
						Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (1)"
						Quit
					}
					
					// + WAL190				
					Set tSC = ..%CollectMeasures(..queryKey,.tCollectedMeasures,1)
					If $$$ISERR(tSC) Quit
					// - WAL190

					// JMD1360: we do not need the slicer for the cell range
					// we will recompute it from the filters
					// JMD1387: if we are running a user query then
					// we need to keep the slicer
					If (..userMDX="") {
						// DTB157 - Do not put any measures in listingFilters since they add no contextual information
						// to the set of facts selected
						Kill tListingFilters(0)
					}
					Else {	
						// DTB108 - check the slicer term in the user query.
						// If it contains $$CMBR keys, remove this term and reconstruct 
						// the executable slicer terms from the original query text
						If ($G(tListingFilters(0))["$$CMBR") {			// DTB117 - protect with $G()
							Kill tListingFilters(0)
							Set tTempRS = ##class(%DeepSee.ResultSet).%New()
							Set tSC = tTempRS.%ParseMDX(..GetCurrentQueryText(),.tTempQuery)
							For ii= 1:1:tTempQuery.filters.Count() {
								Set tListingFilters(-ii) = tTempQuery.filters.GetAt(ii).%ToString()
							}
							Kill tTempRS
						}
					}

					Set kf = $O(tListingFilters(""))
					While (kf'="") {
						Set tClause = tListingFilters(kf)
						If (tClause'="") {
							// JMD1211: quick workaround for some listing issues
							// ignore any unprocessed CMBRS
							If (tClause'["$$CMBR") {
								Set ..mdx = ..mdx _ " %FILTER " _ tClause
								
								// JMD993: save this filter in the listingFilters array
								Set tLFilter = ##class(%DeepSee.Component.pivotLevel).%New()
								Set tLFilter.spec = tClause
								Do ..listingFilters.Insert(tLFilter)
								Do:$IsObject($G(%page)) %page.%AddComponent(tLFilter)
							}
						}
						Set kf = $O(tListingFilters(kf))
					}

					// + WAL190 -- add any listing influencing measures to the query
					Set tMeasure = $O(tCollectedMeasures(""))
					While (tMeasure'="") {
						
						If ($G(tCollectedMeasures(tMeasure,"calcListingFilter"))'="") {
							Set tClause = tCollectedMeasures(tMeasure,"calcListingFilter")
						}
						Else {
							// + WAL190 (2)
							// + WAL236 (2) -- add $G
							If (($G(tCollectedMeasures(tMeasure,"listingFilterOperator"))="MAX") || ($G(tCollectedMeasures(tMeasure,"listingFilterOperator"))="MIN")) {
								If ((r1=r2)&&(c1=c2)) {
									Set tValue = tRS.%GetOrdinalValue(c1,r1)
									Set tClause = "%Search.&[[Measures].["_tMeasure_"]="_tValue_"]"
								}
								Else {
									Set tClause=""
								}
							}
							// - WAL190 (2)
							ElseIf ($G(tCollectedMeasures(tMeasure,"listingFilterOperator"))'="") { // WAL220
								Set tClause = "%Search.&[[Measures].["_tMeasure_"]"_tCollectedMeasures(tMeasure,"listingFilterOperator")_tCollectedMeasures(tMeasure,"listingFilter")_"]"
							}
						}
						If ($G(tClause)'="") {  // WAL190 (3) -- add $G
							Set tLFilter = ##class(%DeepSee.Component.pivotLevel).%New()
							Set tLFilter.spec = tClause
							Do ..listingFilters.Insert(tLFilter)
							Do:$IsObject($G(%page)) %page.%AddComponent(tLFilter)
						}
						Set tMeasure = $O(tCollectedMeasures(tMeasure))	
					}
					// - WAL190
				}
				Set tWITH = ""

				// WITH clause if any
				For n = 1:1:..calculatedMembers.Count() {
					Set tCalcMbr = ..calculatedMembers.GetAt(n)
					Set tDimName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(tCalcMbr.dimension)
					Set tMemberName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(tCalcMbr.memberName)
					If ((tDimName'="")&&(tMemberName'="")) {
						// DTB158 - Escape identifiers before quoting
						Set tWITH = tWITH _ " MEMBER ["_$$$dsEscapeIdent(tDimName)_"].["_$$$dsEscapeIdent(tMemberName)_"] AS '" _ tCalcMbr.valueExpression _ "'"
					}
					If (tCalcMbr.formatString'="") {
						Set tWITH = tWITH _ ",FORMAT_STRING='"_$Replace(tCalcMbr.formatString,"'","''")_"'"
					}
					If (+tCalcMbr.solveOrder>0) {
						Set tWITH = tWITH _ ",SOLVE_ORDER="_tCalcMbr.solveOrder
					}
				}

				Set:tWITH'="" tWITH = " WITH " _ tWITH _ " "

				Set ..queryKey = ""
				Set tMaxRows = ""
				If (+..listingRows>0) {
					Set tMaxRows = " MAXROWS "_..listingRows
				}
				Set ..mdx = "DRILLTHROUGH"_tMaxRows_tWITH_" SELECT FROM [" _ tRS.%GetCubeName() _"]"

				// check for custom field list
				Set tRETURN = "$LISTING"
				If ((..listing="$$$CUSTOM")&&(..listingFields.Count()>0)) {
					Set tRETURN = ""
					For lf=1:1:..listingFields.Count() {
						Set tSpec = ..listingFields.GetAt(lf).spec
						Set tAlias = ..listingFields.GetAt(lf).caption		// DTB509
						Set tRETURN = tRETURN _ $S(tRETURN="":"",1:",") _ tSpec
						
						Set tSpecHasAlias = ($L(tSpec," ")>1)&'($E($ZSTRIP(tSpec,"<>W"),*)=")")		// DTB508 - New test for alias
						If ((tAlias'="")&&'tSpecHasAlias) {
							Set tRETURN = tRETURN _ " """ _ tAlias _ """"
						}
					}
				}
				If (..listingSortColumn>0) {
					If (tRETURN="$LISTING") {
						Set ..mdx = ..mdx _ " RETURN "_tRETURN_" %ORDER BY " _ ..listingSortColumn _ " " _ ..listingSortDir
					}
					Else {
						Set ..mdx = ..mdx _ " %ORDER BY " _ ..listingSortColumn _ " " _ ..listingSortDir
					}
				}
			}
			Else {
				// DTB857 - Execute the query prepared by key to make results available
				Set tSC = tRS.%ExecuteParameters(.tParms)		// DTB857 (2) - Use %ExecuteParameters
				If $$$ISERR(tSC) Quit
				
				// reset listing filters
				Do ..listingFilters.Clear()

				If (tIsPaging) {
					// do not recompute when paging
					Set tRS.%Recompute = 0
				}
				Set ..queryStatus = tRS.%GetStatus(.tComplete,,.tPending)
				Set ..queryComplete = tComplete
				Set ..queryPending = tPending
				If (..queryStatus = 30) {
					// finish computing
					Set tSC = tRS.%ExecuteAsynch(,.tParms)		// DTB704 - Straight to %ExecuteAsynch		// DTB868 - Add processing of parms

					Set ..queryStatus = tRS.%GetStatus(.tComplete,,.tPending)
					Set ..queryComplete = tComplete		// DTB868 - Store percent complete in state
					Set ..queryKey = tRS.%GetQueryKey()
				}
				// + WAL266 (3) 
				ElseIf (..staleCache && '..reinitialized) { // WAL304 -- add '..reinitialized
					Set $$$DeepSeeResultsGLVN($$$UPPER(##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(..cubeName)),..queryKey,"timestamp")=0
					Set tSC = tRS.%PrepareKey(##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(..cubeName),..queryKey,1)
					Set tSC = tRS.%ExecuteAsynch(,.tParms)		// DTB704 - Straight to %ExecuteAsynch		// DTB857 - Add available parms
					
					Set ..queryStatus = tRS.%GetStatus(.tComplete,,.tPending)
					Set ..queryComplete = tComplete		// DTB868 - Store percent complete in state
					Set ..queryKey = tRS.%GetQueryKey()
					Set ..staleCache=0 
					Set ..reinitialized=1
				}
				// - WAL266 (3)
			}
		}
		
		If (..queryKey = "") {
			
			Set tStart = $ZH
			Set ..queryStatus = 0
			Set ..queryComplete = 0
			Set ..queryPending = 0
			Set tComplexQuery = 0

			#; Create the result set to get data
			Set tRS = ..%CreateResultSet(.tSC,.tParms,.tFilterInfo,.tAdvancedFilters,.tQueryText,,,.tComplexQuery,tExecuteBaseQuery)
			If $$$ISERR(tSC) {
				Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (2)"
				Set ..error = ..%message			// DTB150
				
				Quit
			}

			Set ..%ResultSet = tRS
			
			// + WAL202 -- consider related cube queries to be complex queries
			//             creating the join index *might* be expensive, so run the query in 
			//             the background
			// + WAL204 -- also run compound cube queries in the background since they might
			//             be unexpectedly expensive
			Set:(..%ResultSet.%Query.%hasRelationship) tComplexQuery = 1
			Set:(##class(%DeepSee.Utils).%IsCubeCompound(..cubeName)) tComplexQuery = 1
			// - WAL202/WAL204
			
			If $$$UPPER(tRS.%GetQueryText())["%SEARCH.&[" {
				// DTB663 - Trigger background processing for searchable measures
				Set tComplexQuery = 1
			}
			
			// If initial execute is off, don't run the query
			If (('..initialExecute) && ($G(%zenContext) = "page")) {
				Quit
			}

			Set tRS.%Recompute = 1

			Set %dsUpToDate = 1 // WAL266 (3)

			#; make sure parameters are executed before we go further
			#; for now, we do not supply parameters
			Kill tParms
			Set tSC = tRS.%ExecuteParameters(.tParms)
			If $$$ISERR(tSC) {
				Set ^DeepSee.QueryLog($UserName,$I(^DeepSee.QueryLog($UserName))) = ..GetCurrentQueryText("resolved")  // WAL075
				Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (3)"
				Set ..error = ..%message			// DTB150
				Quit
			}

			// + WAL266 (3)
			Set:($G(%dsUpToDate)=0) ..staleCache = 1
			Set %dsUpToDate=1
			// - WAL266 (3)

			Set ..queryStatus = tRS.%GetStatus(.tComplete,,.tPending)
			Set ..queryComplete = tComplete		// DTB868 - Log percent complete in the state 
			Set ..queryKey = tRS.%GetQueryKey()

			// execute in background
			If ((..%message="")&&((..queryStatus < 100) || tRS.%Recompute)) {		// DTB863 - Respond to forced recompute as discovered by the resultset 
				// JMD1156: if this is a "bad" query,
				// then compute its axes in the background!
				
				// DTB704 - Use %ExecuteAsynch
				Set tSC = tRS.%ExecuteAsynch(,.tParms)		// DTB868 - Execute with available parms
				Set ..queryStatus = tRS.%GetStatus() //APV024

				If $$$ISERR(tSC) {
					Set ..%message = $System.Status.GetErrorText(tSC) _ " (4)"
					Set ..error = ..%message			// DTB150
					Quit
				}
				Else {
					// DP-434472 - Remove polling loop which waited for results here. The client will be responsible for requesting information from the server
					// at reasonable intervals and the server's job is to deliver information as fast as possible.
					Set ..queryStatus = tRS.%GetStatus(.tComplete,,.tPending)
					Set ..queryComplete = tComplete
					Set ..queryPending = tPending
				}
			}
		}

		// show listing?
		Set tSQL = ""
		If (tRS.%IsDrillThrough() && '..showPlan) {
			Set ^DeepSee.QueryLog($UserName,$I(^DeepSee.QueryLog($UserName))) = ..GetCurrentQueryText("resolved")  // WAL075

			// + WAL170
			If ($G(tPlugInInfo("NAME"))'="") Set tRS.%PlugInContextName = tPlugInInfo("NAME")
			If ($G(tPlugInInfo("PROP"))'="") Set tRS.%PlugInContextProp = tPlugInInfo("PROP")
			Merge tRS.%PlugInFilters = tPlugInInfo("FILTERS")
			Merge tRS.%PlugInArguments = tPlugInInfo("ARGUMENTS") // WAL262 -- pass along plugIn arguments
			// - WAL170

			// JMD1331
			Set tSC = ..%MaterializeListing(tRS)
			If $$$ISERR(tSC) {
				Set tSQL = tRS.%GetListingSQL()
				Quit
			}
			//Set tSC = ..%DrawListing(tRS)
			Set tSC = ..%DrawListing()
			If $$$ISERR(tSC) {
				Set tSQL = tRS.%GetListingSQL()
			}
			Quit
		}

		// log
		Set ^DeepSee.QueryLog($UserName,$I(^DeepSee.QueryLog($UserName))) = ..GetCurrentQueryText("resolved")  // WAL075

		Set tAxisCount = 0
		If (..queryStatus > 30) {
			// axes are available
			#; get axis info: tAxis(axisno) = axisnode
			Set tAxisCount = tRS.%GetAxisCount(.tAxis)
			Set tVolume = tRS.%GetCellCount(..cubeKey,..queryKey,.tSC)

			If (..queryStatus>=100) {		// DTB873 - Check for status complete before displaying any final messages
				If $$$ISERR(tSC) {	// DTB167 - Only report an error if the query is complete
					Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (5)"
				}
				ElseIf (tVolume = 0) {
					Set:..%message="" ..%message = $$$Text("No results","%DeepSee") _ " (6)"
				}
			}
		}
		Else {
			// DP-408943 - Currently the work is still in the axis processing or before.
			// Set sizes to 0 in order to allow construction of placeholder html while the message
			// reports the progress details.
			Set tAxisCount = 0
			Set tVolume = 0
		}

		If (..showPlan && (..queryStatus >= 100)) {
			Set tSC = ..%ShowPlan(tRS)
			Quit
		}

		#; JMD900
		If (+$G(tPending) && (..queryStatus >= 100)) {
			Do ##class(%DeepSee.Query.Engine).%UpdatePendingResults(..cubeName,..queryKey,.tPending)
			Set ..queryPending = tPending
		}
		// + WAL304 -- *this* is a fine time to reinitialize the variables
		If (..queryStatus >= 100) {
			Set ..reinitialized = 0
		}
		// - WAL304

		#; draw the table
		Set (tColAxis,tRowAxis) = ""
		Set tColAxis = $G(tAxis(1))
		Set tRowAxis = $G(tAxis(2))

		#; if sorting is enabled, build sort index here
		Set tCubeIndex = ..cubeKey
		Set tQueryKey = ..queryKey

		Set tUseSort = 0
		If ((tAxisCount>1)&&(..sortColumn>0)) {
			Set tRowCount = ..%GetAxisSize(2)
			If (tRowCount > 1) {
				Set tUseSort = 1
				// JMD1468 save sort in cache global
				If '$D($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"sort",..sortColumn,..sortDir)) {
					Kill ^||ds.sort
					For r=1:1:tRowCount {
						Set tValue = tRS.%GetOrdinalValue(..sortColumn,r)
						Set:tValue="" tValue=1E-14
						Set ^||ds.sort(tValue,r) = ""
					}

					Kill $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"sort",..sortColumn,..sortDir)
					Set tDir = $S(..sortDir="DESC":-1,1:1)
					Set n = 0
					Set k = $O(^||ds.sort(""),tDir)
					While (k'="") {
						Set r = $O(^||ds.sort(k,""),tDir)
						While (r'="") {
							Set $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"sort",..sortColumn,..sortDir,$I(n)) = r
							Set r = $O(^||ds.sort(k,r),tDir)
						}
						Set k = $O(^||ds.sort(k),tDir)
					}
				}
			}
		}

		If (..%message="") {
			// DTB716 - Only draw the table if there is no error at this point
			Set tTableDrawn = 1
			Set tSC = ..%DrawTable(tAxisCount,tColAxis,tRowAxis,.tFilterInfo,tUseSort)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If (..pivotNonce'="") {
		// Lock -^DeepSee.Pivot(..pivotNonce)
	}

	If $$$ISERR(tSC) {
		// PFS077 - Protect against tRS undefined when ..%message is populated upon calling %DrawHTML
		If (($G(tCubeIndex)'="")&&$IsObject($G(tRS))&&(tRS.%QueryKey'="")) {
			// DTB602 - Cancel any query that might have been running
			Do ##class(%DeepSee.ResultSet).%CancelQuery(tCubeIndex,tRS.%QueryKey)
		}
		
		If (..%message="") {
			Do $System.Status.DecomposeStatus(tSC,.tErr)
			Set tErrorMsg = $G(tErr(1)) _ " (8) "
		}
		Else {
			Set tErrorMsg = ..%message
		}
		Set ^DeepSee.PivotError = tErrorMsg
	}
	
	If (..%message'="") && (tErrorMsg="") {
		// DTB716 - Expose the stored error message if there has not been a more recent message set 
		Set tErrorMsg = ..%message
	}

	If (tErrorMsg '= "") {
		If ('tTableDrawn) {
			&html<<div class="pivotError" id="#(..%MakeId("errorDiv"))#">>
			Write $ZCVT(tErrorMsg,"O","HTML")
			&html<</div>>
		}
		Else {
			&html<<div class="dsPivotError" id="#(..%MakeId("errorDiv"))#">>
			Write $ZCVT(tErrorMsg,"O","HTML")
			&html<</div>>
		}
		If (..showQuery) {
			&html<<textarea rows="3" style="width:100%;">>
			Write $ZCVT(tQueryText,"O","HTML")
			&html<</textarea>>
		}

		If ($G(tSQL)'="") {
			&html<<div rows="3" style="color:red; width:100%;">>
			Write $ZCVT(tSQL,"O","HTML")
			Set ^DeepSee.SQLError = tSQL
			&html<</div>>
		}
	}
	// JMD1462
	If (%page.cssLevel>=3)&&(tErrorMsg="") {
		Set tBackgroundOpacity = ..backgroundOpacity
		Set tBackgroundImage = ..backgroundImage
		If (+..analyzerMode) {
			Set tBackgroundOpacity = 0.12
			Set tBackgroundImage = "deepsee/pivottable.jpg"
		}
		If ((tBackgroundOpacity>0)&&(tBackgroundImage'="")) {
			&html<<div class="dsPivotTableImage" style="background-image:url(#(tBackgroundImage)#);opacity:#(+tBackgroundOpacity)#;"></div>>
		}
	}

	&html<</div>>
}

/// Draw the tables that make up this component.<br/>
/// <var>pAxisCount</var> is the number of axes within the result.<br/>
/// <var>pColAxis</var> specifies which axis should be used for columns.<br/>
/// <var>pRowAxis</var> specifies which axis should be used for rows.<br/>
/// <var>pFilterInfo</var> is an array of filter information.<br/>
/// <var>pUseSort</var> indicates that row sorting is in play.
Method %DrawTable(pAxisCount As %Integer, pColAxis As %Integer, pRowAxis As %Integer, ByRef pFilterInfo, pUseSort As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {	
		// WAL106
		Set ..singleTable = 1			
		
		Set tCubeIndex = ..cubeKey
		Set tShowNodeNums = +$G(^DeepSee.Settings("ShowNodes")) // debugging

		Set tCellHeight = ..cellHeight

		Set tColumnTotals = ..columnTotals
		Set tRowTotals = ..rowTotals

		#; ordinal numbers for axes
		Set tColAxisNo = 1
		Set tRowAxisNo = 2
		Set tRowRoot = pRowAxis
		Set tColRoot = pColAxis
		Set tColLabelSpan = ..columnLabelSpan
		Set tRowLabelSpan = ..rowLabelSpan&&('pUseSort)

		Set tColAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,..queryKey,"axis",tColAxisNo))
		Set tRowAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,..queryKey,"axis",tRowAxisNo))

		// DTB716 - Do one last check for an error in the results global
		Set tQueryStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..queryKey,"error"))
		If tQueryStatus'="" {
			Set ..%message = $System.Status.GetErrorText(tQueryStatus)
			Set ..error = ..%message
		}

		If (..%message '= "") {
			// 1 cell, displaying message
			Set tRowCount = 1
			Set tColCount = 1
			Set tRowLevels = 1
			Set tColLevels = 1
			Set tPageSize = ..pageSize
			Set tStartRow = 1
			Set tEndRow = 1
			Set tMaxCols = 8
			Set tCellWidth = 500 // make sure there is room
		}
		Else {
			#; compute size/shape of columns & rows
			Set tTempStatus = ..%ResultSet.%GetStatus()		// DTB868 - Copy to local cache if the query is complete
			
			// + DP-408448 - indicate to resultset to keep local result, save session key to clear local cache later
			// return status of 100 means the query is complete
			If (tTempStatus = 100) {
				Set tSC = ..%UpdateLocalSession()
				If $$$ISERR(tSC) Quit
			} 
			// - DP-408448

			Set tRowCount = ..%GetAxisSize(tRowAxisNo)
			Set tColCount = ..%GetAxisSize(tColAxisNo)

			Set tRowCount = $S(tRowCount>0:tRowCount,1:1)
			Set tColCount = $S(tColCount>0:tColCount,1:1)
			Set ..rowCount = tRowCount

			If (..queryStatus < 100) {
				// only show partial table until complete
				Set tPageSize = $S(..pageSize<25:..pageSize,1:25)
				Set tMaxCols = 8
				Set tStartRow = 1
			}
			Else {
				Set tPageSize = ..pageSize
				Set tMaxCols = ..#MAXCOLUMNS
				Set tStartRow = ((..currPage-1) * ..pageSize) + 1
			}
			Set tEndRow = tStartRow + tPageSize - 1
			Set tEndRow = $S(tEndRow>tRowCount:tRowCount,1:tEndRow) 

			#; get details for each axis
			Set tSC = ..%GetAxisSpecs(tColAxisNo,tColLabelSpan,1,tMaxCols,.tColLevels,.tColInfoX)
			If $$$ISERR(tSC) Quit
			
			Set tSC = ..%GetAxisSpecs(tRowAxisNo,tRowLabelSpan,tStartRow,tEndRow,.tRowLevels,.tRowInfoX,pUseSort)
			If $$$ISERR(tSC) Quit
		}

		#; if we support drag & drop we need additional mouse event handling
		Set dnd = %page.dragAndDrop

		#; message box
		&html<<div id="#(..%MakeId("message"))#" class="dsPivotMessage" style="display: none;">&nbsp;</div>>

		#; Use divs to layout 4 tables
		#; (plus status area on the bottom)
		&html<<div class="dsptOuterDiv" id="#(..%MakeId("outerDiv"))#">>

		Set tDrillCount = ..drillLevels.Count()
		Set tCanDrillUp = (tDrillCount>0)
		Set tDrillHelp = $$$TextHTML("Drill up from the current level")
		Set tUnselectHelp = $$$TextHTML("Click here to unselect cells")

		// force load of images used by message box
		&html<
			<div style="display:none;">
			<img src="deepsee/cancel_24.png"/>
			<img src="deepsee/insert_table_64.png"/>
			<img src="deepsee/insert_table_fav_64.png"/>
			<img src="deepsee/insert_table_clock_64.png"/>
			</div>
		>

		Set tTLStyle = ..columnHeaderStyle
		Set:(tTLStyle["background") tTLStyle = tTLStyle_"background-image:none;"

		// turn off border if there is a header style
		// (with ie hacks!)
		If ((tTLStyle'="")&&(..showZebra)) {
			// JMD1470: remove
			If ($$$ZENISIE) {
				//Set tTLStyle = tTLStyle _ "border: none; border-bottom: none;border-right: none;"
			}
			Else {
				//Set tTLStyle = tTLStyle _ "border-bottom: 1px solid transparent;border-right: 1px solid transparent;"
			}
		}
				
		// + WAL114 -- determine here whether we need to hide measures or not
		//             use a combination of %CountMeasures and ..hideMeasures to make this determination
		Set tHideMeasures = ..%HideMeasures()		// DTB175
		Set tHiddenMeasureText = "" // + WAL118
		// - WAL114
		
		Set ..rowCaptionList = "" // WAL241
		
		#; nub
		#; show caption for row headers, if available
		If ((+..showRowCaption)||(..showRowCaption="")) {
			Set nr = 0
			If (..overrideRowSpec="") {
				Set tLevel = ..rowLevels.GetAt(1)
				While $IsObject(tLevel) {
					If (tLevel.drillLevel = tDrillCount) {
						// + WAL240 -- handle case when we have text but not caption
						//             this applies to related cubes
						If (tLevel.caption'="") {
							Set tRowCaptions($I(nr)) = tLevel.caption
							Do ..rowCaptionList.SetAt(tLevel.caption,nr) // WAL241
						}
						ElseIf(tLevel.text'="") {
							Set tRowCaptions($I(nr)) = tLevel.text
							Do ..rowCaptionList.SetAt(tLevel.text,nr) // WAL241
						}
						// - WAL240
					}
					Set tLevel = tLevel.childLevels.GetAt(1)
				}
			}
			ElseIf (..overrideRowText'="") {
				Set tRowCaptions($I(nr)) = ..overrideRowText
				Do ..rowCaptionList.SetAt(..overrideRowText,nr) // WAL241
			}
			
			// PFS059 - Fill tRowCaptions with empty nodes if the first row level is not the longest
			// DTB842 - Do not accumulate captions for the original levels if a drill down
			// is in effect.
			Set tDepth = $S(tDrillCount:0,1:..%GetMaxRowLevelDepth(..rowLevels))
			For i = 1:1:tDepth {
				While nr<tDepth {
					Set tRowCaptions($I(nr)) = ""
					Do ..rowCaptionList.SetAt("",nr)
				}
			}
			
			Do ..%CountMeasures(.tMeasureCount)
			If ('tHideMeasures)&&(..measureLocation="rows")&&(tMeasureCount>=1) {
				Set tRowCaptions($I(nr)) = $$$Text("Measures","%DeepSee")		// DTB666 - Measures caption for the nub table
			}
		}

		Set tRowCaptionText = ""
		Set tNubTableAttributes("captions",1)="" // WAL
		Set tNubTableAttributes("ids",1) = ..%MakeId("rcap_"_1)
			
		Set tStyle = ..columnHeaderStyle
		Set:(tStyle["background") tStyle = tStyle_"background-image:none;"
			
		// WAL
		Set tNubTableAttributes("style") = tStyle
		Set tNubTableHTML("metadata","style") = tStyle
		
		If ((..userMDX="") && $D(tRowCaptions) && ($G(nr)>0) && $D(tRowInfoX)) {		// DTB846 - check for actual row info

			Set k = $O(tRowCaptions(""))
			Kill tNubTableAttributes("captions",1) // WAL
			While (k'="") {
				Set tNubTableHTML("content",k) = "<td nowrap=""1"" id="""_..%MakeId("rcap_"_nr)_""" style="""_tStyle_""">"
				Set nr = nr - 1
				Set tNubTableHTML("content",k,"captions") = $ZCVT(tRowCaptions(k),"O","HTML")
				Set tNubTableHTML("content",k,"style") = tStyle
				
				// WAL
				Set tNubTableAttributes("captions",k)=$ZCVT(tRowCaptions(k),"O","HTML")
				Set tNubTableAttributes("style",k) = tStyle
				Set tNubTableAttributes("ids",k) = ..%MakeId("rcap_"_(k))
				
				Set k = $O(tRowCaptions(k))
			}
		}
		
		Set tNubTableHTML("metadata","unselect") = tUnselectHelp // + WAL114
		Set tNubTableHTML("metadata","zebra")=..showZebra // + WAL114
		Set ..rowCaptionText = tRowCaptionText
	
		// WAL
		Set tNubTableAttributes("title") = $ZCVT(tUnselectHelp,"O","HTML")
		Set tNubTableAttributes("class") = $S(..showZebra:"dsNubZebra",1:"dsNub")
		Set tNubTableAttributes("onclick") = "zenPage.getComponent("_..index_").cellClickHandler(event,'','');"

		#; column headers
		Set tColSpan = 0
		
		Set hw = $S(..cellWidth="":100,1:..cellWidth)
		If '$D(tColInfoX) {
			Set tColumnTotals = 0
			Set tStyle = ""
			// JMD1465 Set tStyle = tStyle_"width:"_hw_"px;"
			Set tStyle = tStyle_..columnHeaderStyle
			Set:tStyle["background" tStyle = tStyle_"background-image:none;"
			Set tDStyle = tStyle // WAL capture before quoting
			Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)
			#; no columns
			If (..%message '= "") {
				Set tName = "&#160;"
				Set tTitle = ""
			}
			Else {
				Set tName = $$$Text("All","%DeepSee")
				Set tTitle = tName
			}
			Set tColClass = $S(..showZebra:"dsPivotColumnZebra",1:"dsPivotColumn")
			// WAL -- hw means width I believe
			Set id = ..%MakeId("col_"_"1:1")
			Set tTopTableHTML(1,1) = "<th id="""_id_""" "_tStyle_" class="""_tColClass_""" nowrap=""1"" colspan=""1"" rowspan=""1"" title="""_$ZCVT(tTitle,"O","HTML")_"""><div class=""dsPivotColumnOuter""><div class=""dsPivotColumnDiv"">"_tName_"&nbsp;</div></div></th>"
			
			// WAL
			Set tTopTableAttributes(1,1,"id") = id
			Set tTopTableAttributes(1,1,"style") = tDStyle
			Set tTopTableAttributes(1,1,"class") = tColClass
			Set tTopTableAttributes(1,1,"colspan") = 1
			Set tTopTableAttributes(1,1,"rowspan") = 1
			Set tTopTableAttributes(1,1,"title") = $ZCVT(tTitle,"O","HTML")
			Set tTopTableAttributes(1,1,"contents","class") = "dsPivotColumnDiv"
			Set tTopTableAttributes(1,1,"contents","contents") = tName_"&nbsp;"
		}
		Else {
			// + WAL152 -- will I skip level 1 of the sort column??? If so take note of this 
			//             so we render the sort column appropriately
			Set tSkipSort = 0
			If (..sortColumn'=0) {
				Set tInfo = $G(tColInfoX(1,..sortColumn))
				If (tInfo'="") {
					Set tSortNodeNo = +$LG(tInfo,1)
					Set tType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tSortNodeNo),1)
					Set:(tHideMeasures&&((tType="msr")||(tType="agg")||(tType="exp")||(tType="lit"))) tSkipSort = 1
				}
			}
			// - WAL152
		
			For tLevel = tColLevels:-1:1 {
				// force width of header to avoid browser paint issue
				Set tStyle = "width:"_hw_"px;"
				Set tDivStyle = "vertical-align:middle;"
				If (..columnHeaderStyle'="") {
					Set tStyle = tStyle_..columnHeaderStyle
				}
				
				#; labels within this level
				Set n = $O(tColInfoX(tLevel,""))
				Set tEndCol = 0		// DTB850
				Set tCol = 0
				Set c = 0
				Set mc = 0
				While (n '= "") {
					Set:(n>tEndCol) tEndCol=n		// DTB850
					Set tColStyle = tStyle
					Set tNodeNo = +$LG(tColInfoX(tLevel,n),1)
					Set tColSpan = +$LG(tColInfoX(tLevel,n),2)
					Set tRowSpan = +$LG(tColInfoX(tLevel,n),3)
					
					// + WAL180 (2)
					Set tHasChildren = +$LG(tColInfoX(tLevel,n),4)
					Set tChildRowSpan = 1
					If (tHasChildren) {
						For tThisLevel = tLevel:-1:1 {
							Set:$D(tColInfoX(tThisLevel)) tChildRowSpan = $LG(tColInfoX(tThisLevel,n),3)
							Set:$D(tColInfoX(tThisLevel)) tChildNodeNo = $LG(tColInfoX(tThisLevel,n),1)
							If (tChildRowSpan > 1) {
								Quit
							} 	
						}	
					}
					Set tSkipChild = 0
					If (tChildRowSpan > 1) {
						Set tChildType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tChildNodeNo),1)
						Set tSkipChild = (tHideMeasures&&((tChildType="msr")||(tChildType="exp")||(tChildType="lit")))		// DTB666 - Remove "agg"
					}
					// - WAL180 (2)

					Set c = c + tColSpan
					
					Set tType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tNodeNo),1)
					
					// + WAL114 -- skip? yes if its a measure, hideMeasures is on, AND this isn't the only thing on columns
					If ((tColLevels=1)||'(tHideMeasures&&((tType="msr")||(tType="exp")||(tType="lit")))) {		// DTB666 - Remove "agg"
						Set tName = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tNodeNo),5)
						// JMD1475
						Set tDesc = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tNodeNo),23)
						Set tTooltip = $S(tDesc'="":(tName_" - "_tDesc),1:tName)
						Set tTooltip2 = $$$Text("Double-click to sort by this column")

						// go up and find first node with a format / header style
						Set tFormat = ""
						Set tColHeaderStyle = ""
						Set tTestNodeNo = tNodeNo
						While ((tTestNodeNo'="")) {
							Set tSNodeType = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),1)
							If ((tSNodeType="msr")||(tSNodeType="exp")||(tSNodeType="cmbr")) {
								Set:(tFormat="") tFormat = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),12)
							}
							Set:(tColHeaderStyle="") tColHeaderStyle = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),19)
							Set tTestNodeNo = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),4)
						}

						Set tColStyle = tColStyle _ tColHeaderStyle 
						If ($P(tFormat,"^",4)'="") {
							Set tColStyle = tColStyle _$P(tFormat,"^",4)
						}
						Set:tShowNodeNums tName = tName _ " ["_tNodeNo_"]"
						If (..showZebra) {
							Set tCls = $S(((..sortColumn=n)&&((tLevel=1)||(tSkipSort&&(tLevel=2)))):"dsPivotColumnSortZebra",1:"dsPivotColumnZebra") // WAL152
						}
						Else {
							Set tCls = $S(((..sortColumn=n)&&((tLevel=1)||(tSkipSort&&(tLevel=2)))):"dsPivotColumnSort",1:"dsPivotColumn") // WAL152
						}
						Set tSortChar = $S((..sortColumn=n)&&((tLevel=1)||(tSkipSort&&(tLevel=2))):$S(..sortDir="DESC":"&#x25BC;",1:"&#x25B2;"),1:"") // WAL152

						If (..%HideMeasures()&&(..measureLocation="columns"))&&(tType="agg")&&(tRowSpan>1)&&'+$G(tColReduced(n)) {
							// DTB666 - Reduce row span to account for hidden measures.
							// Only do this once per column.
							Set tRowSpan = tRowSpan-1
							Set tColReduced(n)=1
						}

						Set:(tColStyle["background") tColStyle = tColStyle_"background-image:none;"
						
						Set tDColStyle = tColStyle // WAL -- intercept style for adjustment later
						
						Set:tColStyle'="" tColStyle = "style="_$$$quote(tColStyle)
						Set tIStyle = ""
						Set tDIStyle = tDivStyle   // WAL -- intercept style for later
						Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
						Set:(tSkipChild) tRowSpan = tRowSpan + (tChildRowSpan-1) // + WAL180 (2)
						
						// WAL -- I think using n for a span indicator is fine
						Set id = ..%MakeId("col_"_tLevel_":"_n)
						Set tTopTableHTML(tLevel,n) = "<th id="""_id_""" class="""_tCls_""" colspan="""_tColSpan_""" rowspan="""_tRowSpan_""" "_tColStyle_" title="""_$ZCVT(tTooltip,"O","HTML")_" &#10;"_tTooltip2_""" onclick=""zenPage.getComponent("_..index_").columnClickHandler(event,"_n_");"" ondblclick=""zenPage.getComponent("_..index_").columnDblClickHandler(event,"_n_");""><div class=""dsPivotColumnOuter""><div class=""dsPivotColumnDiv"" "_tIStyle_">"_$ZCVT(tName,"O","HTML")_"&nbsp;"_tSortChar_"</div></div></th>"
						
						// WAL
						Set tTopTableAttributes(tLevel,n,"id") = id
						Set tTopTableAttributes(tLevel,n,"style") = tDColStyle
						Set tTopTableAttributes(tLevel,n,"class") = tCls
						Set tTopTableAttributes(tLevel,n,"colspan") = tColSpan
						Set tTopTableAttributes(tLevel,n,"rowspan") = tRowSpan
						Set tTopTableAttributes(tLevel,n,"title") = $ZCVT(tTooltip,"O","HTML")_" &#10;"_tTooltip2
						Set tTopTableAttributes(tLevel,n,"onclick") = "zenPage.getComponent("_..index_").columnClickHandler(event,"_n_");"
						Set tTopTableAttributes(tLevel,n,"ondblclick") = "zenPage.getComponent("_..index_").columnDblClickHandler(event,"_n_");"
						Set tTopTableAttributes(tLevel,n,"contents","class") = "dsPivotColumnDiv"
						Set tTopTableAttributes(tLevel,n,"contents","style") = tDIStyle
						Set tTopTableAttributes(tLevel,n,"contents","contents") = $ZCVT(tName,"O","HTML")_"&nbsp;"_tSortChar
					}
					Else {
						// + WAL118 -- remember the label for the hidden measure
						If ($LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tNodeNo),5)'="") {
							Set tHiddenMeasureText($LG($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tNodeNo),5)) = ""
						}
						// - WAL118
					}
					// - WAL114
					Set n = $O(tColInfoX(tLevel,n))
				}
				// total
				If (tColumnTotals&&(tLevel=tColLevels)) {
					Set msgTotal = $Case(..columnTotalAgg,
						"avg":$$$Text("Average","%DeepSee"),
						"count":$$$Text("Count","%DeepSee"),
						"min":$$$Text("Min","%DeepSee"),
						"max":$$$Text("Max","%DeepSee"),
						"pct":$$$Text("% of Total","%DeepSee"),
						:$$$Text("Total","%DeepSee"))

					Set tColStyle = tStyle
					Set:(tColStyle["background") tColStyle = tColStyle_"background-image:none;"
					
					Set tDColStyle = ""
					
					Set:tColStyle'="" tColStyle = "style="_$$$quote(tColStyle)
					Set tDColStyle = tColStyle // WAL
					Set tColClass = $S(..showZebra:"dsPivotColumnZebra",1:"dsPivotColumn")
					Set tIStyle = ""
					Set tDIStyle = tDivStyle // WAL -- intercept for later
					Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
					
					// + WAL180 -- adjust span for column total header if we are hiding measures
					Set tColTotalSpan = $S((..%HideMeasures() && (tColLevels>1) && (..measureLocation = "columns")):tColLevels-1,1:tColLevels)
					// make sure total header collates last
					// if you have this many columns the total header is the least of your worries
					
					// PFS044 - Generate ID to use in both tTopTableHTML and tTopTableAttributes
					Set id = ..%MakeId("coltotal")
					
					// WAL
					Set n = tEndCol+1		// DTB850
					Set tTopTableHTML(tLevel,n) = "<th id="""_id_""" rowspan="""_tColTotalSpan_""" nowrap=""1"" "_tColStyle_" class="""_tColClass_"""><div class=""dsPivotColumnOuter""><div class=""dsPivotColumnDiv"" "_tIStyle_">&nbsp;"_msgTotal_"&nbsp;</div></div></th>"
					// - WAL180
					
					// PFS044 - Use unique value of n for total column
					// WAL
					Set tTopTableAttributes(tLevel,n,"id") = id
					Set tTopTableAttributes(tLevel,n,"style") = tDColStyle
					Set tTopTableAttributes(tLevel,n,"class") = tColClass
					Set tTopTableAttributes(tLevel,n,"colspan") = 1
					Set tTopTableAttributes(tLevel,n,"rowspan") = tColTotalSpan
					Set tTopTableAttributes(tLevel,n,"contents","class") = "dsPivotColumnDiv"
					Set tTopTableAttributes(tLevel,n,"contents","style") = tDIStyle
					Set tTopTableAttributes(tLevel,n,"contents","contents") = "&nbsp;"_msgTotal_"&nbsp;"
				}
			}
		}

		#; side table: row labels
		#; row headers
		For x = 1:1:tRowLevels {
			Set tNumRows(x) = 0
		}

		For tRow = tStartRow:1:tEndRow {
			Set tStyle = ..rowHeaderStyle
			
			// WAL
			Set tSideTableHTML(tRow) = "<tr id="""_..%MakeId("tr_"_tRow)_""">"

			If ('$D(tRowInfoX)) {
				// no rows
				Set tRowTotals = 0
				If (..%message '= "")||$D(tColInfoX) {
					// DTB141 - Don't label rows if there is something on columns
					Set tName = "&#160;"
					Set tTitle = ""
				}
				Else {
					Set tName = $$$Text("Count","%DeepSee")
					Set tTitle = tName
				}
				Set:(tStyle["background") tStyle = tStyle_"background-image:none;"
				
				Set tDStyle = tStyle // WAL -- intercept for attributes
				
				Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)
				Set tRowClass = $S(..showZebra:"dsPivotRowOdd",1:"dsPivotRow")
				
				// PFS045 - Assign proper row id when nothing placed on rows
				Set id = ..%MakeId("row_"_1_":"_1)
				
				// WAL
				Set tSideTableHTML(1,1) = "<th id="""_id_""" class="""_tRowClass_""" nowrap=""1"" "_tStyle_" rowspan=""1"" colSpan=""1"" title="""_$ZCVT(tTitle,"O","HTML")_"""><div class=""dsPivotRowDiv"" onclick=""zenPage.getComponent("_..index_").rowClickHandler(event,1);"">"_tName_"&nbsp;</div></th>"
				Set tNumRows(1) = 1
				
				// WAL
				Set tSideTableAttributes(1,1,"id") = id
				Set tSideTableAttributes(1,1,"class") = tRowClass
				Set tSideTableAttributes(1,1,"style") = tDStyle
				Set tSideTableAttributes(1,1,"rowspan") = 1
				Set tSideTableAttributes(1,1,"colspan") = 1
				Set tSideTableAttributes(1,1,"title") = $ZCVT(tTitle,"O","HTML")
				Set tSideTableAttributes(1,1,"contents","class") = "dsPivotRowDiv"
				Set tSideTableAttributes(1,1,"contents","onclick") = "zenPage.getComponent("_..index_").rowClickHandler(event,1);"
				Set tSideTableAttributes(1,1,"contents","contents") = tName_"&nbsp;"
			}
			Else {
				Set tTotalSpan = 0
				For tLevel = tRowLevels:-1:1 {
					// WAL029 - Increment nodes in all lower levels for this row before moving to the next row 
					// If (tTotalSpan >= tRowLevels) Quit
					If (tTotalSpan >= tRowLevels) { 
						Set tLevelCount = tLevel
						While (tLevelCount>=1) {
							Set tNumRows(tLevelCount) = tNumRows(tLevelCount) + 1
							Set tLevelCount=tLevelCount-1	
						}
						Quit
					}
					
					// WAL029
					If (tRow >= +$G(tNextRow(tLevel))) {
						Set tRowStyle = tStyle
						Set tRowItem(tLevel) = $O(tRowInfoX(tLevel,$G(tRowItem(tLevel))))
						If (tRowItem(tLevel)'="") {
							Set tNodeNo = +$LG(tRowInfoX(tLevel,tRowItem(tLevel)),1)
							Set tRowNo = +$LG(tRowInfoX(tLevel,tRowItem(tLevel)),5)
							Set:tRowNo="" tRowNo = tRow
							Set tRowSpan = +$LG(tRowInfoX(tLevel,tRowItem(tLevel)),2)
							Set tColSpan = +$LG(tRowInfoX(tLevel,tRowItem(tLevel)),3)
							Set tTotalSpan = tTotalSpan + tColSpan
							Set tHasChildren = +$LG(tRowInfoX(tLevel,tRowItem(tLevel)),4)
							// + WAL180 (2)
							Set tChildColSpan = 1
							If (tHasChildren) {
								For tThisLevel = tLevel:-1:1 {
									Set:$D(tRowInfoX(tThisLevel)) tChildColSpan = $LG(tRowInfoX(tThisLevel,tRowItem(tLevel)),3)
									Set:$D(tRowInfoX(tThisLevel)) tChildNodeNo = $LG(tRowInfoX(tThisLevel,tRowItem(tLevel)),1)
									If (tChildColSpan > 1) {
										Quit
									} 	
								}	
							}
							// - WAL180 (2)
							If ('tHasChildren && (tLevel>1)) {
								Set tNextRow(tLevel-1) = tRow + 1
								For kk=tLevel-2:-1:1 {
									Set tNextRow(kk) = tRow + 1
								}
							}
							Set tNextRow(tLevel) = tRow + tRowSpan
							
							If (tRow >= tStartRow) {
								// + WAL114 -- what type of node is this??
								Set tType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tNodeNo),1)
								// + WAL114 -- skip? yes if its a measure, hideMeasures is on AND this isn't the only thing on rows
								
								// + WAL180 (2)
								Set tSkipChild = 0
								If (tChildColSpan > 1) {
									Set tChildType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tChildNodeNo),1)	
									Set tSkipChild = (tHideMeasures&&(..measureLocation="rows")&&		// DTB661 - Only apply this to measures placed on rows
											((tChildType="msr")||(tChildType="exp")||(tChildType="lit")))		// DTB666 - Remove "agg"
								}
								// - WAL180 (2)
								
								// + WAL206 -- add (..measureLocation="rows") to the condition, use ..%HideMeasures()
								// DTB666 - Take "agg" out of the condition
								If ((tRowLevels=1)||'(..%HideMeasures()&&(..measureLocation="rows")&&((tType="msr")||(tType="exp")||(tType="lit")))) {
								// - WAL206
									Set tName = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tNodeNo),5)
									// JMD1475
									Set tDesc = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tNodeNo),23)
									Set tTooltip = $S(tDesc'="":(tName_" - "_tDesc),1:tName)
									Set tFormat = ""
									Set tRowHeaderStyle = ""
									Set tTestNodeNo = tNodeNo
									
									If (..%HideMeasures()&&(..measureLocation="rows"))&&(tType="agg")&&(tColSpan>1)&&'+$G(tRowReduced(tRow)) {
										// DTB666 - Reduce the colspan of an aggregate node. Only do this once per row.
										Set tColSpan = tColSpan-1
										If (tRow=1) {
											Set tLevelCounter = 1
											Set tTestLevelNo = $O(tRowInfoX(""),-1)
											While (tTestLevelNo'="")&&(tTestLevelNo'=tLevel) {
												// DTB666 - Look through the original row axis information to count which position
												// This aggregate is in.
												Set tLevelCounter = tLevelCounter+1
												Set tTestLevelNo = $O(tRowInfoX(tTestLevelNo),-1)
											}

											If (tNubTableHTML("metadata","colSpans",tLevelCounter)>1) {
												// DTB666 - Reduce the colspan of this node in the nub table as well
												Set tNubTableHTML("metadata","colSpans",tLevelCounter) = tNubTableHTML("metadata","colSpans",tLevelCounter)-1
											}
										}
										
										Set tRowReduced(tRow) = 1		// DTB666 - Log that this row was reduced
									}
									
									While ((tTestNodeNo'="")) {
										Set tSNodeType = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),1)
										If ((tSNodeType="msr")||(tSNodeType="exp")||(tSNodeType="cmbr")) {
											Set:(tFormat="") tFormat = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),12)
										}
										Set:(tRowHeaderStyle="") tRowHeaderStyle = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),19)
										Set tTestNodeNo = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),4)
									}
									Set tRowStyle = tRowStyle _ tRowHeaderStyle
									If ($P(tFormat,"^",4)'="") {
										Set tRowStyle = tRowStyle _$P(tFormat,"^",4)
									}
									Set:tShowNodeNums tName = tName _ " ["_tNodeNo_"]"
									If (..showZebra && (..rowHeaderStyle'="")) {
										Set tRowStyle = tRowStyle _ $S('(tNumRows(tLevel)#2):"background:white;",1:"")
									}
									Set:(tRowStyle["background") tRowStyle = tRowStyle_"background-image:none;"
									
									Set tDRowStyle = tRowStyle // WAL
									
									Set:tRowStyle'="" tRowStyle = "style="_$$$quote(tRowStyle)
									Set tRowClass = $S(..showZebra:$S('(tNumRows(tLevel)#2):"dsPivotRowOdd",1:"dsPivotRowEven"),1:"dsPivotRow")
									Set:(tSkipChild) tColSpan = tColSpan + (tChildColSpan-1) // + WAL180 (2)
									// JMD1055: force entire th into one long line
									If (tCanDrillUp && (tLevel=1)) {
										// DTB118 - use removeDrillLevel()
										// WAL221 -- use tRow as index for rowClickHandler
										// WAL224 -- pass event to removeDrillLevel()
										// WAL237 -- switch argument for removeDrillLevel() from
										//           event,index to index,event
										//           because other calls to removeDrillLevel don't pass event (and don't need to)
										
										// WAL
										Set id = ..%MakeId("row_"_tLevel_":"_tRow)
										Set tSideTableHTML(tRow,tLevel) = "<th id="""_id_""" class="""_tRowClass_""" rowNo="""_tRowNo_""" nowrap=""1"" "_tRowStyle_" rowspan="""_tRowSpan_""" colSpan="""_tColSpan_""" title="""_$ZCVT(tTooltip,"O","HTML")_"""><div class=""dsPivotRowDiv"" onclick=""zenPage.getComponent("_..index_").rowClickHandler(event,"_(tRow)_");"" ondblclick=""zenPage.getComponent("_..index_").rowDblClickHandler(event,"_tLevel_","_tRowNo_");""><span title="""_tDrillHelp_""" onclick=""zenPage.getComponent("_..index_").removeDrillLevel("_(tDrillCount-1)_",event);"" class=""dsptDrillUp"">&nbsp;&#9664;&nbsp;</span>"_$ZCVT(tName,"O","HTML")_"</div></th>"
									
										Set tSideTableAttributes(tRow,tLevel,"id")=id
										Set tSideTableAttributes(tRow,tLevel,"class")=tRowClass
										Set tSideTableAttributes(tRow,tLevel,"rowNo")=tRowNo
										Set tSideTableAttributes(tRow,tLevel,"style")=tDRowStyle
										Set tSideTableAttributes(tRow,tLevel,"rowspan")=tRowSpan
										Set tSideTableAttributes(tRow,tLevel,"colspan")=tColSpan
										Set tSideTableAttributes(tRow,tLevel,"title")=$ZCVT(tTooltip,"O","HTML")
										Set tSideTableAttributes(tRow,tLevel,"contents","class")="dsPivotRowDiv"
										Set tSideTableAttributes(tRow,tLevel,"contents","onclick")="zenPage.getComponent("_..index_").rowClickHandler(event,"_(tRow)_");"
										Set tSideTableAttributes(tRow,tLevel,"contents","ondblclick")="zenPage.getComponent("_..index_").rowDblClickHandler(event,"_tLevel_","_tRowNo_");"
										Set tSideTableAttributes(tRow,tLevel,"contents","contents") = "<span title="""_tDrillHelp_""" onclick=""zenPage.getComponent("_..index_").removeDrillLevel("_(tDrillCount-1)_",event);"" class=""dsptDrillUp"">&nbsp;&#9664;&nbsp;</span>"_$ZCVT(tName,"O","HTML")
									}
									Else {
										// WAL221 -- use tRow as index for rowClickHandler
										
										Set id = ..%MakeId("row_"_tLevel_":"_tRow)
										// WAL
										Set tSideTableHTML(tRow,tLevel) = "<th id="""_..%MakeId("row_"_tLevel_":"_tRow)_""" class="""_tRowClass_""" rowNo="""_tRowNo_""" nowrap=""1"" "_tRowStyle_" rowspan="""_tRowSpan_""" colSpan="""_tColSpan_""" title="""_$ZCVT(tTooltip,"O","HTML")_"""><div class=""dsPivotRowDiv"" onclick=""zenPage.getComponent("_..index_").rowClickHandler(event,"_(tRow)_");"" ondblclick=""zenPage.getComponent("_..index_").rowDblClickHandler(event,"_tLevel_","_tRowNo_");"">&nbsp;"_$ZCVT(tName,"O","HTML")_"</div></th>"
									
										// I believe the only difference between this and the above is the contents,
										// so I should change the code to simplify for this case
										Set tSideTableAttributes(tRow,tLevel,"id")=id
										Set tSideTableAttributes(tRow,tLevel,"class")=tRowClass
										Set tSideTableAttributes(tRow,tLevel,"rowNo")=tRowNo
										Set tSideTableAttributes(tRow,tLevel,"style")=tDRowStyle
										Set tSideTableAttributes(tRow,tLevel,"rowspan")=tRowSpan
										Set tSideTableAttributes(tRow,tLevel,"colspan")=tColSpan
										Set tSideTableAttributes(tRow,tLevel,"title")=$ZCVT(tTooltip,"O","HTML")
										Set tSideTableAttributes(tRow,tLevel,"contents","class")="dsPivotRowDiv"
										Set tSideTableAttributes(tRow,tLevel,"contents","onclick")="zenPage.getComponent("_..index_").rowClickHandler(event,"_(tRow)_");"
										Set tSideTableAttributes(tRow,tLevel,"contents","ondblclick")="zenPage.getComponent("_..index_").rowDblClickHandler(event,"_tLevel_","_tRowNo_");"
										Set tSideTableAttributes(tRow,tLevel,"contents","contents") = "&nbsp;"_$ZCVT(tName,"O","HTML")
									}
								}
								// + WAL114 -- if hiding measures adjust nub table captions
								//             else case means that tHideMeasures=1 AND we have 
								//             found a measure
								//             So we need to remove the row label for the measure
								//             we are removing
								Else {
									
									// + WAL118 -- remember the label for the hidden measure
									// + WAL130 -- fix copy paste error, use row axis key
									If ($LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tNodeNo),5)'="") { 
										Set tHiddenMeasureText($LG($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tNodeNo),5)) = ""
										Set tRowReduced(tRow) = 1		// DTB666 - Log that a measure was removed from the row
									}
									// - WAL130
									// - WAL118
									
									If ($G(tKill)="") {
										Set tItem = ""
										For i=1:1:tLevel {
											Set tItem = $O(tNubTableHTML("content",tItem),-1)	
										}
										
										Set tNubLevel = $O(tNubTableHTML("content",""))
										Set tNubLevelCount = 0
										While (tNubLevel'="") {
											Set tNubLevelCount = $i(tNubLevelCount)
											Set tNubLevel = $O(tNubTableHTML("content",tNubLevel))
										}
										// If this node doesn't have a caption there are likely no row captions,
										// so don't kill anything
										// If there is a different number of nub headers and row headers deal with this later in %MergeTables
										If (($G(tItem)'="") && ($G(tNubTableHTML("content",tItem,"captions"))'="") && '(tNubLevelCount < tRowLevels)) {
											Kill tNubTableHTML("content",tItem)
											Set tKill = 1
										}
									}
								}
								// - WAL114
								Set tNumRows(tLevel) = tNumRows(tLevel) + 1
							}
						}
					}
				} // for tLevel
			}
		}

		// total
		If (tRowTotals) {
			Set msgTotal = $Case(..rowTotalAgg,
				"avg":$$$Text("Average","%DeepSee"),
				"count":$$$Text("Count","%DeepSee"),
				"min":$$$Text("Min","%DeepSee"),
				"max":$$$Text("Max","%DeepSee"),
				"pct":$$$Text("% of Total","%DeepSee"),
				:$$$Text("Total","%DeepSee"))
			If ((..rowTotalAgg="sum")&&(..rowTotalSource="all")) {
				Set msgTotal = $$$Text("Grand Total","%DeepSee")
			}

			Set tRowStyle = ..rowHeaderStyle
			If (..showZebra && (..rowHeaderStyle'="")) {
				Set tRowStyle = tRowStyle _ $S('(tNumRows(1)#2):"background:white;",1:"")
			}
			Set:(tRowStyle["background") tRowStyle = tRowStyle_"background-image:none;"
			Set tDRowStyle = tRowStyle // WAL
			Set:tRowStyle'="" tRowStyle = "style="_$$$quote(tRowStyle)
			Set tRowClass = $S(..showZebra:$S('(tNumRows(1)#2):"dsPivotRowOdd",1:"dsPivotRowEven"),1:"dsPivotRow")
			// don't close row (WAL106)
			// + WAL180 -- adjust column span for row total header if we are hiding measures from rows
			Set tRowTotalSpan = $S((..%HideMeasures() && (tRowLevels>1) && (..measureLocation = "rows")):tRowLevels-1,1:tRowLevels)
			
			Set id = ..%MakeId("rowtotal")
			// WAL
			Set tSideTableHTML("rowtotal") = "<tr><th id="""_id_""" colspan="""_tRowTotalSpan_""" class="""_tRowClass_""" "_tRowStyle_"><div class=""dsPivotRowDiv"">&nbsp;"_msgTotal_"</div></th>"
			// - WAL180
			
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"id")=id
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"class")=tRowClass
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"colspan")=tRowTotalSpan
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"style")=tDRowStyle
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"id")=id
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"contents","class")="dsPivotRowDiv"
			Set tSideTableAttributes((tEndRow+1),tRowLevels,"contents","contents")="&nbsp;"_msgTotal
		}
		
		// + WAL118 -- remember which measures were hidden so the client code can adjust
		//             tooltips and legends accordingly
		Set tSC = ..hiddenMeasureText.Clear()
		Set tKey = ""
		Set tMeasureText = $O(tHiddenMeasureText(""))
		While (tMeasureText'="") {
			Do ..hiddenMeasureText.SetAt(tMeasureText,$i(tKey))
			Set tMeasureText = $O(tHiddenMeasureText(tMeasureText))	
		}
		// - WAL118

		#; cell table
		Set tCellRowCount = tRowCount
		Set:tCellRowCount>tPageSize tCellRowCount = tPageSize
		Set:tColCount>tMaxCols tColCount = tMaxCols
		Set tSC = ..%DrawDataTable(pAxisCount,tColRoot,tRowRoot,tStartRow,tEndRow,tColumnTotals,tRowTotals,pUseSort,tMaxCols,.tDataTableHTML,.tDataTableHTMLAttributes)
		If $$$ISERR(tSC) Quit

		// + WAL106 -- merge the html arrays for the 4 tables into a single table
		Set tSC = ..%MergeTables(.tNubTableHTML,.tTopTableHTML,.tSideTableHTML,.tDataTableHTML, .tNubTableAttributes, .tTopTableAttributes, .tSideTableAttributes, .tDataTableHTMLAttributes)
		If $$$ISERR(tSC) Quit
		// - WAL106

		// JMD1129 truncated rows?
		// DTB710 - Use the new property to keep track of row truncation
		Set:tRowAxisKey'="" ..rowsTruncated = +$G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"truncated"))

		#; status area
		Set tPageCount = (tRowCount \ tPageSize) + $S(tRowCount#tPageSize:1,1:0)
		If (..showStatus || (tPageCount>1) || ..rowsTruncated) {		// DTB710
			Set tStatusStyle = ""
		}
		Else {
			Set tStatusStyle = "height:0px;border-top:none;"
		}
		&html<<div class="dsptStatusDiv" style="#(tStatusStyle)#" id="#(..%MakeId("statusDiv"))#">>
		If (..showQuery) {
			Set tQueryText = ""
			Set:^DeepSee.QueryLog($UserName)'="" tQueryText = $G(^DeepSee.QueryLog($UserName,^DeepSee.QueryLog($UserName)))
			&html<<textarea rows="3" style="width:100%;" id="#(..%MakeId("queryText"))#">>
			Write $ZCVT(tQueryText,"O","HTML"),!
			&html<</textarea>>
		}

		// only show if needed
		If ((tPageCount>1)||..showPivotStats||..rowsTruncated) {		// DTB710 - Use new property
			Set tSC = ..%DrawStatusArea(tPageCount,"pivot",..rowsTruncated)
		}
		&html<</div>> // outer

		&html<</div>> // outer
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod %GetMaxRowLevelDepth(pRow, pDepth As %Integer = 0) As %Integer
{
	Set tDepth = pDepth
	For i=1:1:pRow.Count() {
		Set tTemp = ..%GetMaxRowLevelDepth(pRow.GetAt(i).childLevels,pDepth+1)
		Set:(tTemp>tDepth) tDepth = tTemp
	}
	Quit tDepth
}

Method %CalculateSpans(ByRef pTopTableHTML, ByRef pSideTableHTML, Output pRowSpan, Output pColSpan, Output pFirstSpan = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tNode = $O(pTopTableHTML(""),-1)
		Set tNubRowSpan=0
		Set tNubRow = $O(pTopTableHTML(""))
		While (tNubRow'="") {
			Set:$O(pTopTableHTML(tNubRow,""))'="MaxLength" tNubRowSpan=$i(tNubRowSpan)
			Set tNubRow = $O(pTopTableHTML(tNubRow))	
		}
		// + WAL169
		// + WAL114
		Set tSideTableIdx = $O(pSideTableHTML("")) 
		If tSideTableIdx'="" {
			Set tLevel = $O(pSideTableHTML(tSideTableIdx,""))
			While tLevel '= "" {
				Set pFirstSpan = $I(pFirstSpan)
				Set tLevel = $O(pSideTableHTML(tSideTableIdx,tLevel))
			}
		}
		Set tMaxSpan = 0
		While (tSideTableIdx'="") {
			Set tNubColLevel = $O(pSideTableHTML(tSideTableIdx,""))
			Set tNubColSpan=0
			While (tNubColLevel'="") {
				Set tNubColSpan = $i(tNubColSpan)
				Set tNubColLevel = $O(pSideTableHTML(tSideTableIdx,tNubColLevel))
			}
			If (tNubColSpan > tMaxSpan) Set tMaxSpan = tNubColSpan
			Set tSideTableIdx = $O(pSideTableHTML(tSideTableIdx))
		}
		Set tNubColSpan = tMaxSpan
		
		// output variables
		Set pRowSpan = tNubRowSpan
		Set pColSpan = tNubColSpan
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method DivMerge(tNubTable = "", tTopTable = "", tSideTable = "", tDataTable = "", pNubTableHTML, pTopTableHTML, pSideTableHTML, pDataTableHTML)
{
	// I think I can generalize this by having an iterate/emit method. It will need to be able to
	// be parameterized with a transformation
	//
	// Will be in pivot table class
	// might have to pick up updated width/height in some cases
	
	Set tSC = ..%CalculateSpans(.tTopTable, .tSideTable, .tRowSpan, .tColSpan, .tFirstSpan)

	// test style sheet
	//W "<link href=""stylesheet.css"" rel=""stylesheet"">"
	
	// just given these divs, I should be able to position everything within my emit method

		Set tIgnore("colspan") = ""
		Set tIgnore("rowspan") = ""
		
		Set tTopTableLeft = ..cellWidth * tColSpan
		Set tSideTableTop = ..cellHeight * tRowSpan
		Set tSideTableWidth = tTopTableLeft
		Set tTopTableHeight = tSideTableTop
		
	// Need to be able to pass a transformation to each of these iterations
	//
		// For zebra, remove borders for side and data tables ( pass 0 for arg 6 )
		// check ..showZebra for this
		
		// PFS048 - Reorder and use old dataTable
		&html<<div id="#(..%MakeId("sideTable"))#" class="sideTable" style="#("overflow:hidden;position:absolute;top:"_ tSideTableTop _"px;height:600px;width:"_ tTopTableLeft _"px;z-index:2;")#">>
			Set tSC = ..%Emit(.tSideTable,"side",.tIgnore,tRowSpan,tColSpan)
		&html<</div>>
	
		&html<<div id="#(..%MakeId("topTable"))#" style="#("overflow:hidden;position:absolute;left:"_ tTopTableLeft _"px;top:0px;width:600px;height:"_ (tSideTableTop-1) _"px;z-index:2;")#">>
			Set tSC = ..%Emit(.tTopTable,"top",.tIgnore,tRowSpan,tColSpan)
		&html<</div>>
		
		&html<<div id="#(..%MakeId("nubTable"))#" style="#("overflow:hidden;position:absolute;left:0px;top:0px;height:"_ tSideTableTop _"px;width:"_(tSideTableWidth-1)_";z-index:3;")#">>
			Set tSC = ..%DrawNub(.tNubTable,tRowSpan,tColSpan,tFirstSpan)
		&html<</div>>
}

Method %DrawNub(ByRef pNub, pRowSpan As %String, pColSpan As %String, pFirstSpan As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		
		Set tHTML = "<div "
		Set tHTML = tHTML _ "class=" _ $$$quote(pNub("class"))
		Set tHTML = tHTML _ " style="_ $$$quote("width:"_((..cellWidth*pColSpan)-1)_"px;height:"_((..cellHeight*pRowSpan)-1)_"px;"_$S($G(pNub("style"))'="":pNub("style"),1:""))
		Set tHTML = tHTML _ "title=" _ $$$quote(pNub("title")) 
		Set:$G(pNub("onclick"))'="" tHTML = tHTML _ "onclick=" _ $$$quote(pNub("onclick")) 
		
		Set tHTML = tHTML  _ ">"
		
		Set tCount = 1

		Set tLastCaption = $O(pNub("captions",""),-1)
		// write captions, dump contents, or both
		While (tCount<=tLastCaption) {
			Set tHTML = tHTML _ "<div class=""dsNubInner"" id=""new"_pNub("ids",tCount)_""" style=""width:"_(..cellWidth-1) _ "px;left:"_(..cellWidth*(tCount-1))_"px;"_$select(tCount=tLastCaption:"border-right: 1px solid #D0D0D0;",1:"")_""">"_ $ZCVT(pNub("captions",tCount),"O","HTML") _"</div>"
			Set tCount = $I(tCount)
		}
		If $D(pNub("contents")) {
			Set tHTML = tHTML _ pNub("contents")	
		}
		
		Set tHTML = tHTML  _ "</div>"
		&html<#(tHTML)#>
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method %Emit(ByRef pTable, pTransform As %String = "", ByRef pIgnore = "", pRowSpan As %String, pColSpan As %String, pBorderWidth As %String = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		// Need to handle special cases, like 
		Set tNodeDirection = $S(pTransform="top":-1,1:1)		// DTB829 - Control the direction of element processing based on the table position
		Set tNode = $O(pTable(""),tNodeDirection)
		Set tOuterOffset = tNode-1
		While tNode'="" {
			Set tNode2 = $O(pTable(tNode,""))
			While (tNode2'="") {
				// WAL -- this handles paging offsets. When paging, the side and data table
				//        end up with indices where the position I need is off by (currPage*pages), 
				//        so I remember the offset from the first index (above).
				//        If the first index is 1 (page 1) then applying the index does nothing. Otherwise
				//        it scales the page down to the position I need.
				// Set up iterators
				// only use these for placement; never for references
				// handle paging if exists
				If (pTransform="data") || (pTransform="side") {
					Set tOuter = tNode - tOuterOffset
					Set tInner = tNode2
				}
				ElseIf (pTransform="top") {
					Set tLast = $O(pTable(""),-1)
					Set tOuterOffset = tLast - pRowSpan
					Set tOuter = tNode - tOuterOffset
					Set tInner = tNode2
				}
				Else {
					Set tOuter = tNode
					Set tInner = tNode2
				}

				// Start string
				Set tHTML = "<div"
				
				// Make these available for entire processing of the node
				Set tRowSpan = $G(pTable(tNode,tNode2,"rowspan"),1)
				Set tColSpan = $G(pTable(tNode,tNode2,"colspan"),1)
				
				// main loop -- handle all attributes
				Set tAttr = $O(pTable(tNode,tNode2,""))
				While tAttr '= "" {
					If pTransform'="" {
						// Check and apply -- ignore any attributes specified in the
						
						// adjust style
						If tAttr="style" {
							// add to style
							Set tStyle = pTable(tNode,tNode2,tAttr)
						
							// Since I'm doing inline styles I need to strip the quotes
							// if there are any (conditional formatting might add them,
							// user formatting might add them
							Set tStyle = $Replace(tStyle,"""","")
							
							If pTransform="top" {
								Set tStyle = "position:absolute;" _ tStyle
								Set tStyle = "left:" _ ((tInner-1) * ..cellWidth) _ "px;" _ tStyle 
								Set tStyle = "top:" _ ((pRowSpan-tOuter) * ..cellHeight) _ "px;" _ tStyle
								
								// the -pBorderWidth below preserves the border. I don't know why this is only needed in this case
								Set tStyle = tStyle _ "width:"_((..cellWidth*tColSpan)-pBorderWidth)_"px;"
								Set tStyle = tStyle _ "height:"_(..cellHeight*tRowSpan)_"px;"
							}
							ElseIf pTransform="side" {
								Set tStyle = "position:absolute;" _ tStyle
								Set tStyle = "top:" _ ((tOuter-1) * ..cellHeight) _ "px;" _ tStyle
								Set tStyle = "left:" _ ((pColSpan-tInner) * ..cellWidth) _ "px;" _ tStyle 
								// set width?
								Set tStyle = tStyle _ "width:"_((..cellWidth*tColSpan)-pBorderWidth)_"px;"
								// -pBorderWidth to leave room for border
								Set tStyle = tStyle _ "height:"_((..cellHeight*tRowSpan)-pBorderWidth)_"px;"
							}
							// -pBorderWidth in following styles leaves room for the border
							ElseIf pTransform="data" {
								Set tStyle = "position:absolute;" _ tStyle
								Set tStyle = "top:" _ ((tOuter-1) * ..cellHeight) _ "px;" _ tStyle
								Set tStyle = "left:" _ ((tInner-1) * ..cellWidth) _ "px;" _ tStyle
								Set tStyle = tStyle _ "height:" _ (..cellHeight-pBorderWidth) _ "px;"
								Set tStyle = tStyle _ "width:" _ (..cellWidth-pBorderWidth) _ "px;"
							}
							//Set:tAttr'="contents" tHTML = tHTML _ " " _ tAttr _ "=" _ $$$quote(tStyle)
							Set:tAttr'="contents" tHTML = tHTML _ " " _ tAttr _ "=" _ $$$quote(tStyle)
						}
						// PFS - Add new to beginning so we can reference old table for sizes
						ElseIf tAttr="id" {
							Set tHTML = tHTML _ " " _ tAttr _ "=" _ $$$quote("new"_pTable(tNode,tNode2,tAttr))
						}
						// OR, write out what we find, if it isn't ignored
						ElseIf '$D(pIgnore(tAttr)) {
							Set:tAttr'="contents" tHTML = tHTML _ " " _ tAttr _ "=" _ $$$quote(pTable(tNode,tNode2,tAttr))
						}
					}	
					Else {
						Set:tAttr'="contents" tHTML = tHTML _ " " _ tAttr _ "=" _ $$$quote(pTable(tNode,tNode2,tAttr))
					}
					Set tAttr = $O(pTable(tNode,tNode2,tAttr))
				}
				
				// close div
				Set tHTML = tHTML _ ">"
				
				// contents loop
				// if true we have contents to emit
				If $D(pTable(tNode,tNode2,"contents")) {
					
					// open contents div
					Set tHTML = tHTML _ "<div"
					
					Set tContentsAttr = $O(pTable(tNode,tNode2,"contents",""))
					While tContentsAttr'="" {
						// write out a div containing the contents
						Set:tContentsAttr'="contents" tHTML = tHTML _ " " _ tContentsAttr _ "=" _ $$$quote(pTable(tNode,tNode2,"contents",tContentsAttr))
						Set tContentsAttr = $O(pTable(tNode,tNode2,"contents",tContentsAttr))
					}
					
					// close contents div and write contents
					Set tHTML = tHTML _ ">" _ pTable(tNode,tNode2,"contents","contents") _  "</div>"
				}
				
				// close html
				Set tHTML = tHTML _ "</div>"
				
				// Actually emit the HTML that has been built for this node
				&html<#(tHTML)#>
				
				Set tNode2 = $O(pTable(tNode,tNode2))	
			}	
			Set tNode = $O(pTable(tNode),tNodeDirection)		// DTB829 - Add node processing direction	
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method %MergeTables(ByRef pNubTableHTML As %String, ByRef pTopTableHTML As %String, ByRef pSideTableHTML As %String, ByRef pDataTableHTML As %String, ByRef pNubTableAttributes As %String, ByRef pTopTableAttributes As %String, ByRef pSideTableAttributes As %String, ByRef pDataTableAttributes As %String) As %Status
{
	Set tSC = $$$OK	
	Try {
		&html<<div class="dsPivotCompleteTableDiv" id="#(..%MakeId("dsPivotCompleteTableDiv"))#">>
		&html<<div id="#(..%MakeId("dsPivotCompleteTable"))#" class="dsPivotCompleteTableDiv">>
		
		// WAL106 -- Merge logic

		&html<<div class="dsPivotCompleteTableDiv" id="#(..%MakeId("dataTableDiv"))#" style="position:absolute;z-index:1;">>
		&html<<table id="#(..%MakeId("dataTable"))#" class="dsPivotCompleteTable">>
		Set tSideDepth = $O(pSideTableHTML(1,""),-1)		// DTB861
		Set tNub=$O(pNubTableHTML("content",""))
		Set tLastNub = $O(pNubTableHTML("content",""),-1)
		If (tLastNub>tSideDepth) {
			// DTB861 - The nub table might have extra entries based on the particular row header content of the current
			// results page. Remove extra nubs to avoid alignment problems with the top headers and the data.
			Set tRemoveCount = tLastNub-tSideDepth
			For tNubKillNo=(tLastNub):-1:(tLastNub-tRemoveCount+1) {
				Kill pNubTableHTML("content",tNubKillNo)
			}
		}
		
		Set tNubRowLast = $O(pTopTableHTML(""),-1)
		Set tSC = ..%CalculateSpans(.pTopTableHTML, .pSideTableHTML, .tNubRowCount, .tNubColSpan)
		Set tNode = $O(pTopTableHTML(""),-1)
		While (tNode'="") {
			// start a new row
			&html<<tr>>
			// write the nub
			If (tNode=tNubRowLast) {
				If ($G(pNubTableHTML("metadata","zebra"))) {
					Set tCls = "dsNubZebra"
				}
				Else {
					Set tCls = "dsNub"
				}
				If ($G(pNubTableHTML("metadata","style"))) {
					Set tStyle = pNubTableHTML("metadata","style")	
				}
				Else {
					Set tStyle = ""
				}
				If ($G(pNubTableHTML("metadata","unselect"))'="") {
					Set tUnselectHelp = pNubTableHTML("metadata","unselect")
				}
				Else {
					Set tUnselectHelp = ""
				}
				
				// This makes the nubtable look good for zebra stuff
				// one nub for the whole column section
				Set tNub=$O(pNubTableHTML("content",""))
				Set tLastNub = $O(pNubTableHTML("content",""),-1)
				
				// Also need to trigger this if we are in a situation where the table isn't ready to be written out yet
				// ..%message '= "" means that we aren't actually drawing the pivot table yet
				// don't want to just create a nub in that case
				// also need to not show the nub when the data table is not complete (we drew the empty table)
				If ((tNub="") || (..%message'="") || ($G(pDataTableHTML("empty"))'="")) {
					
					// + WAL113 -- do we have rows?
					If (tNubColSpan>1) {
						// pad nub table
						&html<<th class="#(tCls)#" colspan="#(tNubColSpan)#" rowspan="#(tNubRowCount)#" style="#(tStyle)#" nowrap="1" id="#(..%MakeId("rcap_1"))#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).cellClickHandler(event,'','');">>
						// + WAL252
						If (($G(tNub)'="") && ($G(pNubTableHTML("content",tNub,"input"))'="")) {
							&html<#(pNubTableHTML("content",tNub,"input"))#>
						}
						// - WAL252
						&html<</th>>
					}
					Else {
						// empty nub table
						Set:(tNubRowCount<1) tNubRowCount = 1
						&html<<th class="#(tCls)#" rowspan="#(tNubRowCount)#" style="#(tStyle)#" nowrap="1" id="#(..%MakeId("rcap_1"))#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).cellClickHandler(event,'','');">>
						// + WAL252
						If (($G(tNub)'="") && ($G(pNubTableHTML("content",tNub,"input"))'="")) {
							&html<#(pNubTableHTML("content",tNub,"input"))#>
						}	
						// - WAL252					
						&html<</th>>	
					}
					// - WAL113
				}
				Else {
					While ((tNub '= "")&&(+tNub)) {
						Set tStyle = pNubTableHTML("content",tNub,"style")
						If tStyle=""
						// + WAL114
						// If this isn't the last nub cell, don't give it a right border
						// Condition checks to see if it is the last nub we have AND if we won't need any padding
						If ((tLastNub'=tNub)||(tLastNub<tNubColSpan)) { Set tStyle=tStyle_"border-right:none;" }
						// - WAL114
						&html<<th class="#(tCls)#" rowspan="#(tNubRowCount)#" id="#(..%MakeId("rcap_"_tNub))#" style="#(tStyle)#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).cellClickHandler(event,'','');" nowrap="1" >>
						If ($D(pNubTableHTML("content",tNub,"captions"))) {
							&html<#(pNubTableHTML("content",tNub,"captions"))#>
						}
						// + WAL252
						If ($G(pNubTableHTML("content",tNub,"input"))'="") {
							&html<#(pNubTableHTML("content",tNub,"input"))#>
						}
						// - WAL252
						&html<</th>>
						
						Set tNub=$O(pNubTableHTML("content",tNub))
					}
					// + WAL114 -- if the nub has fewer captions than cells, just pad with empty cells
					Set tLastNubUsed = tLastNub
					While (tLastNubUsed<tNubColSpan) {
						Set tLastNubUsed = $i(tLastNubUsed)
						If tLastNubUsed=tNubColSpan { Set tStyle = "" }
						&html<<th class="#(tCls)#" rowspan="#(tNubRowCount)#" style="#(tStyle)#" nowrap="1" id="#(..%MakeId("rcap_1"))#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).cellClickHandler(event,'','');">>
						&html<</th>>
					}
					// - WAL114
				}
			}
			Set tNode2 = $O(pTopTableHTML(tNode,"")) 
			While (tNode2'="") {
				&html<#(pTopTableHTML(tNode,tNode2))#>
				Set tNode2 = $O(pTopTableHTML(tNode,tNode2)) 	
			}
			&html<</tr>>
			Set tNode = $O(pTopTableHTML(tNode),-1)
		}

		Set tNode = $O(pSideTableHTML(""))
		While (tNode'="") {
			&html<#(pSideTableHTML(tNode))#>
			Set tNode2 = $O(pSideTableHTML(tNode,""),-1) 
			While (tNode2'="") {
				// DP-413188 - This element is a placeholder in the HTML DOM that will be used for determining rendered sizes when
				// the single table is produced. The original ID is picked up in the production of the div table and is the
				// base for all interactivity, so this ID is the one that gets changed as it is rendered.
				Set tSideNodeHTML = $Replace(pSideTableHTML(tNode,tNode2),"id=""cb_","disabled id=""deadcb_")
				&html<#(tSideNodeHTML)#>			
				Set tNode2 = $O(pSideTableHTML(tNode,tNode2),-1)	
			}
			
			// then write out the data
			Set tDataNode = $O(pDataTableHTML(tNode,"")) 
			While (tDataNode '="") {
				&html<#(pDataTableHTML(tNode,tDataNode))#>
				Set tDataNode = $O(pDataTableHTML(tNode,tDataNode)) 
			}
			// Write total if exists
			If ($D(pDataTableHTML("ctot",tNode))) {
				&html<#(pDataTableHTML("ctot",tNode))#>	
			}
			
			// Handle row totals
			If (tNode="rowtotal") {
				Set tDataNode = $O(pDataTableHTML("rtot","")) 
				While (tDataNode '="") {
					&html<#(pDataTableHTML("rtot",tDataNode))#>
					Set tDataNode = $O(pDataTableHTML("rtot",tDataNode)) 	
				}
				If ($D(pDataTableHTML("gtot"))) {
					&html<#(pDataTableHTML("gtot"))#>
				}
			}
			
			&html<</tr>>
			Set tNode = $O(pSideTableHTML(tNode))
		}
		&html<</table>>
		&html<</div>> 
		
		If $G(^%DIV,1) {
			Set ..absolutePositioning = 1
			Do ..DivMerge(.pNubTableAttributes, .pTopTableAttributes, .pSideTableAttributes, .pDataTableAttributes, .pNubTableHTML, .pTopTableHTML, .pSideTableHTML, .pDataTableHTML)
		}
		
		&html<</div>> 
		&html<</div>> 
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Draw table using KPI class as a source.
Method %DrawKPITable() As %Status
{
	Set tSC = $$$OK
	Try {
		// Set to 100 first in case we error out
		Set ..queryStatus = 100
		Set ..queryComplete = 100
		Set ..queryPending = 0
		
		//Set ..singleTable = 0 // WAL106
		Set ..singleTable = 1 // WAL252

		Set msgKPIError = $$$TextHTML("Error getting data from KPI:","%DeepSee")

		// pull range apart
		Set tRangeRow1 = $P(..selectedRange,",",1)
		Set tRangeCol1 = $P(..selectedRange,",",2)
		Set tRangeRow2 = $P(..selectedRange,",",3)
		Set tRangeCol2 = $P(..selectedRange,",",4)

		#; set up format conditions
		Set tFormatRuleCount = ..formatRules.Count()
		
		// show checkboxes?
		Set tShowCB = (..pivotSelect'="")

		#; set up color scaling
		Set tMinRed = 0
		Set tMaxRed = 255
		Set tMinGreen = 0
		Set tMaxGreen = 255
		Set tMinBlue = 0
		Set tMaxBlue = 255
		Set tRedScale = 0
		Set tBlueScale = 0
		Set tGreenScale = 0
		If (..colorScale = "red-to-black") {
			Set tRedScale = 1
		}
		ElseIf (..colorScale = "green-to-black") {
			Set tGreenScale = 1
		}
		ElseIf (..colorScale = "blue-to-black") {
			Set tBlueScale = 1
		}
		ElseIf (..colorScale = "salmon-to-black") {
			Set tRedScale = 1
			Set tGreenScale = 0.65
			Set tBlueScale = 0.45
		}
		ElseIf (..colorScale = "purple-to-black") {
			Set tBlueScale = 1
			Set tRedScale = 1
		}
		ElseIf (..colorScale = "gray-to-black") {
			Set tRedScale = 0.75
			Set tBlueScale = 0.75
			Set tGreenScale = 0.75
		}
		ElseIf ($P(..colorScale,":",1) = "custom") {
			// JMD1063: custom:r1,g1,b1:r2,g2,b2
			Set tRGB1 = $P(..colorScale,":",2)
			Set tRGB2 = $P(..colorScale,":",3)
			Set r1 = +$P(tRGB1,",",1)
			Set g1 = +$P(tRGB1,",",2)
			Set b1 = +$P(tRGB1,",",3)
			Set r2 = +$P(tRGB2,",",1)
			Set g2 = +$P(tRGB2,",",2)
			Set b2 = +$P(tRGB2,",",3)
			Set r1=$S(r1<0:0,r1>255:255,1:r1)
			Set g1=$S(g1<0:0,g1>255:255,1:g1)
			Set b1=$S(b1<0:0,b1>255:255,1:b1)
			Set r2=$S(r2<0:0,r2>255:255,1:r2)
			Set g2=$S(g2<0:0,g2>255:255,1:g2)
			Set b2=$S(b2<0:0,b2>255:255,1:b2)
			Set tMinRed = r1,tMaxRed=r2,tRedScale = (r2-r1)/255
			Set tMinGreen = g1,tMaxGreen=g2,tGreenScale = (g2-g1)/255
			Set tMinBlue = b1,tMaxBlue=b2,tBlueScale = (b2-b1)/255
		}

		#; if we support drag & drop we need additional mouse event handling
		Set dnd = %page.dragAndDrop
		Set tZenPage = %page

		// use a dataController to drive the KPI
		New %datacontroller
		New %page		// prevent temp components from being added to page!

		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set %datacontroller = tController
		Set ..%KPIController = tController
		Set tController.modelClass = ..kpi
		Set tController.modelId = ..dataSourceName

		Set tController.criteria = ##class(%ZEN.proxyObject).%New()
		Set tCriteria = tController.criteria

		// apply filter values
		For n = 1:1:..filters.Count() {
			Set tFilter = ..filters.GetAt(n)
			Set tFilterName = tFilter.spec
			If ((tFilterName'="")&&(tFilter.enabled'=0)) {
				Set tValue = tFilter.value
				Set $zobjproperty(tCriteria,tFilterName) = tValue
				Set:tValue'="" tFilterValues(tFilterName) = tValue
			}
		}

		&html<<div class="dsPivotTableWrapper">>

		#; scroll bars (initially hidden)
		&html<<div class="dsptVtScroll" style="display:none;" id="#(..%MakeId("vtScroll"))#" onscroll="zenPage.getComponent(#(..index)#).cellScrollVt();"><div class="dsptVtScrollInner" id="#(..%MakeId("vtScrollInner"))#">&nbsp;</div></div>>
		&html<<div class="dsptHzScroll" style="display:none;" id="#(..%MakeId("hzScroll"))#" onscroll="zenPage.getComponent(#(..index)#).cellScrollHz();"><div class="dsptHzScrollInner" id="#(..%MakeId("hzScrollInner"))#">&nbsp;</div></div>>

		If (..isDrillThrough) {
			// check for listing
			Set tListingName = ""
			Kill tSelection
			Set tSelection("rowValues") = ..selectedRowValues
			Set tSelection("selectedRange") = ..selectedRange
			Set tSelection("sortColumn") = ..listingSortColumn
			Set tSelection("sortDir") = ..listingSortDir
			
			Set tSC = $classmethod(..kpi,"%GetListingResultSet",.tFilterValues,.tSelection,tListingName,.tSQLRS)
			If $$$ISERR(tSC) Quit
			
			Set ..listingRows = $classmethod(..kpi,"%GetMaxListingRows")		// DTB924 - Check listing rows defined by the KPI

			If $IsObject(tSQLRS) {
				// JMD1331
				Set tSC = ..%MaterializeListing("",tSQLRS)
				If $$$ISERR(tSC) Quit
				
				//Set tSC = ..%DrawListing("",tSQLRS)
				Set tSC = ..%DrawListing()
				If $$$ISERR(tSC) Quit
				Quit
			}
			// pass through for now
		}

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		// WAL252 -- if we get an error, don't worry about Merge tables since we don't have a table to deal with

		If $$$ISERR(tSC) {
			//Set tMsg = $$$TextHTML("KPI is abstract or has invalid data model","%DeepSee")
			Set tErr = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
			&html<<div style="padding:5px;">#(msgKPIError)#</div>>
			&html<<div style="padding:5px;color:darkred;">#(tErr)#</div>>
			Set tSC = $$$OK
			Quit
		}

		If (tController.modelError'="") {
			&html<<div style="padding:5px;">#(msgKPIError)#</div>>
			&html<<div style="padding:5px;color:darkred;">#($ZCVT(tController.modelError,"O","HTML"))#</div>>
			Quit
		}

		Set tModel = tController.%model
		If ('$IsObject(tModel)) {
			Set tMsg = $$$TextHTML("KPI has no data model","%DeepSee")
			&html<<div style="padding:5px;">#(msgKPIError)#</div>>
			&html<<div style="padding:5px;color:darkred;">#(tMsg)#</div>>
			Quit
		}

		// JMD900-test for async KPI
		If (tModel.%IsCacheable()) {
			// take a peek at the cache
			Set ..queryStatus = 100
			Set ..queryComplete = 100
			Set tClass = $$$UPPER(tModel.%ClassName(1))
			Set tCacheKey = tModel.%cacheKey
			If ((tClass'="")&&(tCacheKey'="")) {
				Set tKPISC = $G($$$DeepSeeKPIGLVN(tClass,tCacheKey,"error"),$$$OK)
				If $$$ISERR(tKPISC) {
					Set tKPIError = $System.Status.GetErrorText(tKPISC)
					&html<<div style="padding:5px;">#(msgKPIError)#</div>>
					&html<<div style="padding:5px;color:darkred;">#($ZCVT(tKPIError,"O","HTML"))#</div>>
					Quit
				}
				Set tPctComplete = $G($$$DeepSeeKPIGLVN(tClass,tCacheKey,"pctComplete"),100)
				If (tPctComplete<=100) {
					Set ..queryStatus = tPctComplete
					Set ..queryComplete = tPctComplete
					Set ..queryKey = tCacheKey
				}
			}
		}

		Set tCellWidth = ..cellWidth
		Set tCellHeight = ..cellHeight
		Set tRowTotals = 0
		Set tStyle = ""
		Set tRowCount = 0

		If (..%message '= "") {
			// 1 cell, displaying message
			Set tRowCount = 1
			Set tColCount = 1
			Set tCellWidth = 500 // make sure there is room
		}
		Else {
			#; compute size/shape of columns & rows
			Set tRowCount = tController.dataBag.seriesCount
			Set tColCount = 0

			Set tSC = ..%GetKPIColumns(tController,.tColCount,.tColProps,..columnList)
			If $$$ISERR(tSC) Quit

			Set tRowCount = $S(tRowCount>=0:tRowCount,1:1)
			Set tColCount = $S(tColCount>0:tColCount,1:1)
			Set ..rowCount = tRowCount
		}

		#; message box
		&html<<div id="#(..%MakeId("message"))#" class="dsPivotMessage" style="display: none;">&nbsp;</div>>

		#; Use divs to layout 4 tables
		#; (plus status area on the bottom)
		&html<<div class="dsptOuterDiv" id="#(..%MakeId("outerDiv"))#">>
		
		Set tUnselectHelp = $$$TextHTML("Click here to unselect cells")

		// force load of images used by message box
		&html<
			<div style="display:none;">
			<img src="deepsee/cancel_24.png"/>
			<img src="deepsee/insert_table_64.png"/>
			<img src="deepsee/insert_table_fav_64.png"/>
			<img src="deepsee/insert_table_clock_64.png"/>
			</div>
		>

		Set tTLStyle = ..columnHeaderStyle
		// JMD1377
		// turn off border if there is a header style
		// (with ie hacks!)
		If ((tTLStyle'="")&&(..showZebra)) {
			If ($$$ZENISIE) {
				Set tTLStyle = tTLStyle _ "border: none; border-bottom: none;border-right: none;"
			}
			Else {
				Set tTLStyle = tTLStyle _ "border-bottom: 1px solid transparent;border-right: 1px solid transparent;"
			}
		}
		// WAL252n -- topLeftDiv
		If tShowCB {	// DTB101
			//&html<<div class="dsptTopLeftDiv#($S(..showZebra:"Zebra",1:""))#" style="#(tTLStyle)#text-align:left;" id="#(..%MakeId("topLeftDiv"))#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#">>
		}
		Else {
			//&html<<div class="dsptTopLeftDiv#($S(..showZebra:"Zebra",1:""))#" style="#(tTLStyle)#text-align:left;" id="#(..%MakeId("topLeftDiv"))#" title="#($ZCVT(tUnselectHelp,"O","HTML"))#" onclick="zenPage.getComponent(#(..index)#).cellClickHandler(event,'','');">>
		}
		
		// WAL
		Set tTitle = tUnselectHelp

		#; nub
		If (..pivotSelect = "multi") {
			Set hlpAll = $$$Text("Select or unselect all items","%DeepSee")
			Set tTitle = hlpAll // WAL
			//&html<<input style="margin-left:6px;" type="checkbox" id="#(..%MakeId("cb_all"))#" title="#(hlpAll)#" onclick="zenPage.getComponent(#(..index)#).allClickPivot(event);"/>>
			// WAL252
			Set tNubTableHTML("content",1,"input") = "<input style=""margin-left:6px;"" type=""checkbox"" id="""_..%MakeId("cb_all")_""" title="""_hlpAll_""" onclick=""zenPage.getComponent("_..index_").allClickPivot(event);""/>"
			
			// WAL -- grab content
			Set tNubTableAttributes("contents") = "<input style=""margin-left:6px;"" type=""checkbox"" id="""_..%MakeId("cb_all")_""" title="""_hlpAll_""" onclick=""zenPage.getComponent("_..index_").allClickPivot(event);""/>"
		}
		//&html<</div>>
		
		
		// WAL252 -- nub table
		Set tNubTableHTML("content",1,"style")=""
		Set tNubTableHTML("metadata","style")=""
		Set tNubTableHTML("metadata","unselect")="Click here to unselect cells"
		Set tNubTableHTML("metadata","zebra")=$S(..showZebra:1,1:0)
		
		// WAL -- KPI nub (has no captions)
		Set tNubTableAttributes("onclick") = "zenPage.getComponent("_..index_").allClickPivot(event);"
		Set tNubTableAttributes("class") = $S(..showZebra:"dsNubZebra",1:"dsNub")
		Set tNubTableAttributes("style") = tTLStyle
		Set tNubTableAttributes("title") = tTitle
	
		#; top table: column headers
		
		#; column headers
		Set tColSpan = 0

		For c = 1:1:tColCount {
			Set tStyle = ..columnHeaderStyle
			Set tDivStyle = ""

			// JMD921
			If ($G(tColProps(c,"headerStyle"))'="") {
				Set tStyle = tStyle _ tColProps(c,"headerStyle")
			}

			Set tDStyle = tStyle // WAL
			Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)
			Set tDIStyle = tDivStyle // WAL
			Set:tDivStyle'="" tDivStyle = "style="_$$$quote(tDivStyle)

			Set tName = $S($D(tColProps(c,"caption")):tColProps(c,"caption"),1:$G(tColProps(c)))
			// JMD1377
			If (..showZebra) {
				Set tCls = $S((..sortColumn=c):"dsPivotColumnSortZebra",1:"dsPivotColumnZebra")
			}
			Else {
				Set tCls = $S((..sortColumn=c):"dsPivotColumnSort",1:"dsPivotColumn")
			}
			Set tSortChar = $S(..sortColumn=c:$S(..sortDir="DESC":"&#x25BC;",1:"&#x25B2;"),1:"")

			Set id = ..%MakeId("col_1:"_c)
			If tShowCB {	// DTB101
				Set tTopTableHTML(1,c) = "<th nowrap=""1"" id="""_id_""" class="""_tCls_""" "_tStyle_" title="""_$ZCVT(tName,"O","HTML")_"""><div class=""dsPivotColumnOuter""><div class=""dsPivotColumnDiv"" ondblclick=""zenPage.getComponent("_..index_").columnDblClickHandler(event,"_c_");"" "_tDivStyle_">"_$ZCVT(tName,"O","HTML")_" "_tSortChar_"</div></div></th>" // WAL252t
				//Set tContents = ""
				
				Set tTopTableAttributes(1,c,"contents","class") = "dsPivotColumnDiv"
				Set tTopTableAttributes(1,c,"contents","contents") = $ZCVT(tName,"O","HTML")_" "_tSortChar
				Set tTopTableAttributes(1,c,"contents","ondblclick") = "zenPage.getComponent("_..index_").columnDblClickHandler(event,"_c_");"
				Set tTopTableAttributes(1,c,"contents","style") = tDIStyle
			}
			Else {
				Set tTopTableHTML(1,c) = "<th nowrap=""1"" id="""_id_""" class="""_tCls_""" "_tStyle_" title="""_$ZCVT(tName,"O","HTML")_"""><div class=""dsPivotColumnOuter""><div class=""dsPivotColumnDiv"" onclick=""zenPage.getComponent("_..index_").columnClickHandler(event,"_c_");"" ondblclick=""zenPage.getComponent("_..index_").columnDblClickHandler(event,"_c_");"" "_tDivStyle_">"_$ZCVT(tName,"O","HTML")_" "_tSortChar_"</div></div></th>" // WAL252t
			
				Set tTopTableAttributes(1,c,"contents","class") = "dsPivotColumnDiv"
				Set tTopTableAttributes(1,c,"contents","contents") = $ZCVT(tName,"O","HTML")_" "_tSortChar
				Set tTopTableAttributes(1,c,"contents","onclick") = "zenPage.getComponent("_..index_").columnClickHandler(event,"_c_");"
				Set tTopTableAttributes(1,c,"contents","ondblclick") = "zenPage.getComponent("_..index_").columnDblClickHandler(event,"_c_");"
				Set tTopTableAttributes(1,c,"contents","style") = tDIStyle
			}
			
			// WAL -- KPI top table
			Set tTopTableAttributes(1,c,"id") = id
			Set tTopTableAttributes(1,c,"class") = tCls
			Set tTopTableAttributes(1,c,"style") = tDStyle
			Set tTopTableAttributes(1,c,"title") = $ZCVT(tName,"O","HTML")
		}

		#; if sorting is enabled, build sort index here
		Set tUseSort = 0
		If ((tRowCount > 1)&&(..sortColumn>0)) {
			Kill ^||ds.sort
			Kill ^||ds.rowsort
			For r=1:1:tRowCount {
				Set tProp = $G(tColProps(..sortColumn))
				If (tProp'="") {
					Set tValue = tController.dataBag.%GetValue(tProp,r)
					Set:tValue=$$$ZENMISSING tValue = 1E-14
					Set:tValue="" tValue=1E-14
					Set ^||ds.sort(tValue,r) = ""
				}
			}

			Set tDir = $S(..sortDir="DESC":-1,1:1)
			Set n = 0
			Set k = $O(^||ds.sort(""),tDir)
			While (k'="") {
				Set r = $O(^||ds.sort(k,""),tDir)
				While (r'="") {
					Set ^||ds.rowsort($I(n)) = r
					Set r = $O(^||ds.sort(k,r),tDir)
				}
				Set k = $O(^||ds.sort(k),tDir)
			}
			Set tUseSort = 1
		}

		#; side table: row labels
		//&html<<<div class="dsptBottomLeftDiv" id="#(..%MakeId("bottomLeftDiv"))#">>
		//&html<<<table id="#(..%MakeId("leftTable"))#" class="dsPivotTable" cellspacing="0"  >>

		#; row headers
		For tRowIndex = 1:1:tRowCount {
			If (tUseSort) {
				Set tRow = $G(^||ds.rowsort(tRowIndex))
			}
			Else {
				Set tRow = tRowIndex
			}
			// JMD1377
			Set tRowClass = $S(..showZebra:$S((tRowIndex#2):"dsPivotRowOdd",1:"dsPivotRowEven"),1:"dsPivotRow")
			Set tStyle = ..rowHeaderStyle
			If (..showZebra && (..rowHeaderStyle'="")) {
				Set tStyle = tStyle _ $S((tRowIndex#2):"background:white;",1:"")
			}

			Set tDStyle = tStyle // WAL
			Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)

			Set tName = $G(tModel.%seriesNames(tRow))

			// +DTB450 - Look for a valueColumn when setting the rowValue
			Set tRowValue = ""
			If (..valueColumn'="") {
				Set tRowValue = tController.dataBag.%GetValue(..valueColumn,tRow)
			}
			Else {
				// use first column
				Set tProp = $G(tColProps(1))
				Set tRowValue = tController.dataBag.%GetValue(tProp,tRow)
			}
			Set:tRowValue=$$$ZENMISSING tRowValue = ""
			// -DTB450

			// JMD1468 use row index
			Set trID = ..%MakeId("tr_"_tRowIndex)
			Set tSideTableHTML(tRowIndex) = "<tr id="""_trID_""" value="""_$ZCVT(tRowValue,"O","HTML")_""">" // WAL252	// DTB450 - Add value to the row
			
			Set id = ..%MakeId("row_"_1_":"_tRowIndex)
			Set tSideTableHTMLString = ""
			If tShowCB {	// DTB101
				Set tSideTableHTMLString = tSideTableHTMLString_"<th id="""_id_""" class="""_tRowClass_""" "_tStyle_" rowspan=""1"" colspan=""1""><div class=""dsPivotRowDiv"">" // WAL252
				Set tSideTableHTMLString = tSideTableHTMLString_"<input type=""checkbox"" id="""_..%MakeId("cb_"_tRowIndex)_""" onclick=""zenPage.getComponent("_..index_").cbClickPivot(event,this);""/>" // WAL252s
		
				// WAL
				Set tSideTableAttributes(tRowIndex,1,"id") = id
				Set tSideTableAttributes(tRowIndex,1,"class") = tRowClass
				Set tSideTableAttributes(tRowIndex,1,"style") = tDStyle
				Set tSideTableAttributes(tRowIndex,1,"contents","class") = "dsPivotRowDiv"
				Set tSideTableAttributes(tRowIndex,1,"contents","contents") = "<input type=""checkbox"" id="""_..%MakeId("cb_"_tRowIndex)_""" onclick=""zenPage.getComponent("_..index_").cbClickPivot(event,this);""/>&nbsp;"_tName
			}
			Else {
				Set tSideTableHTMLString = tSideTableHTMLString_"<th id="""_id_""" class="""_tRowClass_""" nowrap=""1"" "_tStyle_" rowspan=""1"" colSpan=""1"" title="""_$ZCVT(tName,"O","HTML")_"""><div class=""dsPivotRowDiv"" onclick=""zenPage.getComponent("_..index_").rowClickHandler(event,"_tRowIndex_");"">" // WAL252s
			
				// WAL
				Set tSideTableAttributes(tRowIndex,1,"id") = id
				Set tSideTableAttributes(tRowIndex,1,"class") = tRowClass
				Set tSideTableAttributes(tRowIndex,1,"style") = tDStyle
				Set tSideTableAttributes(tRowIndex,1,"title") = $ZCVT(tName,"O","HTML")
				Set tSideTableAttributes(tRowIndex,1,"contents","class") = "dsPivotRowDiv"
				Set tSideTableAttributes(tRowIndex,1,"contents","onclick") = "zenPage.getComponent("_..index_").rowClickHandler(event,"_tRowIndex_");"
				Set tSideTableAttributes(tRowIndex,1,"contents","contents") = "&nbsp;"_tName
			}
			Set tSideTableHTML(tRowIndex,1) = tSideTableHTMLString_"&nbsp;"_tName_"</div></th>" // WAL252s
		}
		
		// total
		If (tRowTotals) {
			Set msgTotal = $$$Text("Total","%DeepSee")
			Set tRowClass = $S(..showZebra:"dsPivotRowOdd",1:"dsPivotRow")
			
			// WAL -- is this ok?
			Set tRowLevels = 1
			
			// WAL252 -- totals
			Set tSideTableHTML(10000000,1) = "<th colspan="""_tRowLevels_""" class="""_tRowClass_""">&nbsp;"_msgTotal_"</th>" // WAL252s
			
			Set tSideTableAttributes(tRowCount+1,1,"style") = tRowClass 
			Set tSideTableAttributes(tRowCount+1,1,"contents","contents") = msgTotal 
			Set tSideTableAttributes(tRowCount+1,1,"contents","class") = "dsPivotRowDiv"
		}
		
		// WAL -- KPI row totals

		#; cell table
		Set tCellRowCount = tRowCount

		For tRowIndex = 1:1:tRowCount {
			If (tUseSort) {
				Set tRow = $G(^||ds.rowsort(tRowIndex))
			}
			Else {
				Set tRow = tRowIndex
			}
			Set tRowFormat = ""
			Set tRange = 0
			Set tMinValue = 0

			// JMD1377 apply zebra stripes
			If (..showZebra) {
				Set tZebraClass = $S('(tRowIndex#2):"dsptRowEven",1:"dsptRowOdd")
				If (..cellStyle'="") {
					Set tZebraStyle = $S('(tRowIndex#2):..evenRowStyle,1:"background:white;")
				}
				Else {
					Set tZebraStyle = $S('(tRowIndex#2):..evenRowStyle,1:"background:none;")
				}
			}
			Else {
				Set tZebraClass = ""
				Set tZebraStyle = ""
			}

			// JMD1468 use rowIndex
			//Set tDataTableHTML($i(tDataTableHTML)) = "<tr id="""_..%MakeId("dtr_"_tRowIndex)_""" class="""_tZebraClass_""" value="""_$ZCVT(tRowValue,"O","HTML")_""">" 
			// data cells
			For c=1:1:tColCount {
				Set tProp = $G(tColProps(c))
				If (tProp'="") {
					Set tIcon = ""
					Set tIconCount = 1
					Set tStyle = ..cellStyle
					Set tValue = tController.dataBag.%GetValue(tProp,tRow)
					Set:tValue=$$$ZENMISSING tValue = ""

					// JMD1377
					Set tStyle = tStyle _ tZebraStyle

					Set tCls = "dsPivotNum"
					If (tCellWidth'="") {
						//JMD1465 Set tStyle = tStyle _ "width:"_(tCellWidth)_"px;"
						// WAL261 -- undo JMD1465 and uncomment this line so width can be manipulated
						Set tStyle = tStyle _ "width:"_(tCellWidth)_"px;"
					}
					If (tCellHeight'="") {
						Set tStyle = tStyle _ "height:"_(tCellHeight)_"px;"
					}

					// JMD921
					If ($G(tColProps(c,"style"))'="") {
						Set tStyle = tStyle _ tColProps(c,"style")
					}
					If ($G(tColProps(c,"format"))'="") {
						Set tFormat = tColProps(c,"format")
					}
					ElseIf (tRowFormat'="") {
						Set tFormat = tRowFormat
					}
					Else {
						Set tFormat = ""
					}

					// format cell
					Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
					Set tCls = $Case(tType,"integer":"dsPivotNum",
											"date":"dsPivotDate",
											"number":"dsPivotNum",
											:"dsPivotString")
						
					// + WAL260 -- account for zebra styling
					If (..showZebra) {
						Set tZebraClass = $S('(tRowIndex#2):"dsptRowEven",1:"dsptRowOdd")
						If (..cellStyle'="") {
							Set tZebraStyle = $S('(tRowIndex#2):..evenRowStyle,1:"background:white;")
						}
						Else {
							Set tZebraStyle = $S('(tRowIndex#2):..evenRowStyle,1:"background:white;")
						}
					}
					Else {
						Set tZebraClass = ""
						Set tZebraStyle = ""
					}				
					If (tZebraClass'="") {
						//Set tCls = tZebraClass	
						If (tZebraClass [ "Odd") { Set tCls = tCls_" dsPivotRowOdd" }
						Else { Set tCls = tCls_" dsPivotRowEven" }
					}
					Set tStyle = tStyle _ tZebraStyle
					// - WAL260
											
					// 3rd piece of format is cell style (undocumented)
					If ($P(tFormat,"^",3)'="") {
						Set tStyle = tStyle_$P(tFormat,"^",3)
					}
					// color scaling
					If ($IsValidNum(tValue)&&(tRange>0)&&(..colorScale'="")) {
						// special case for pct values
						If (tFormat["%") {
							Set tPct = $S(tValue<0:0,tValue>1:1,1:tValue)
						}
						Else {
							Set tPct = (tValue-tMinValue/tRange)
						}
						Set cvr = $S(tMinRed<tMaxRed:(tMinRed + (tRedScale * tPct * tMaxRed)\1),1:(tMaxRed + (-tRedScale * (1-tPct) * tMinRed)\1))
						Set cvg = $S(tMinGreen<tMaxGreen:(tMinGreen + (tGreenScale * tPct * tMaxGreen)\1),1:(tMaxGreen + (-tGreenScale * (1-tPct) * tMinGreen)\1))
						Set cvb = $S(tMinBlue<tMaxBlue:(tMinBlue + (tBlueScale * tPct * tMaxBlue)\1),1:(tMaxBlue + (-tBlueScale * (1-tPct) * tMinBlue)\1))
						Set tBright = (cvr*cvr*0.241)+(cvg*cvg*0.691)+(cvb*cvb*0.068)
						Set tFG = $S(tBright>16900:"black",1:"white")
						Set tStyle = tStyle_"background:rgb("_cvr_","_cvg_","_cvb_");color:"_tFG_";"
					}

					// conditional format
					For n = 1:1:tFormatRuleCount {
						Set tCondition = ..formatRules.GetAt(n)
						If (tCondition.%EvaluateCondition(tRow,c,tValue)) {
							Set tStyle = tStyle _ tCondition.style
							Set:tCondition.text'="" tDisplay = tCondition.text
							Set:tCondition.icon'="" tIcon = tCondition.icon
							Set:tCondition.iconCount'="" tIconCount = tCondition.iconCount
							If (($E(tIcon)="@")&&(tIcon'="@")) {
								// user icon: resolve
								Set ik = $E(tIcon,2,$L(tIcon))
								If $D(tLocalIconList(ik)) {
									Set tIcon = tLocalIconList(ik)
								}
								Else {
									Set tIcon = ##class(%DeepSee.UserPortal.Utils).%GetUserIcon(ik)
									Set tLocalIconList(ik) = tIcon
								}
							}
						}
					}
					If (tFormatStyle'="") {
						Set tStyle = tStyle _ "color:"_tFormatStyle_";"
					}

					If (tIcon'="") {
						Set tDisplay = ""
						For ic = 1:1:tIconCount {
							Set tDisplay = tDisplay _ "<image alt=""*"" style=""padding-right:2px;"" height="""_(tCellHeight-4)_""" src="""_tIcon_"""/>"
						}
						Set tCls = "dsPivotIcon"
					}
					ElseIf ($E(tDisplay,*)'=")") { // align negative numbers
						Set tDisplay = tDisplay _ "&nbsp;"
					}

					// apply align to inner div
					Set tDivStyle = ""
					Set tTestStyle = $TR(tStyle," ","")
					If ((tCls'="dsPivotNum")||(tTestStyle["text-align:left;")) {
						Set tDivStyle = "text-align:left;"
					}
					If (tTestStyle["text-align:center;") {
						Set tDivStyle = "text-align:center;"
					}
					ElseIf (tTestStyle["text-align:right;") {
						Set tDivStyle = "text-align:right;"
					}

					Set tDStyle = tStyle // WAL
					Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)
					Set tIStyle = ""
					Set tDIStyle = tDivStyle // WAL
					Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
					Set id = ..%MakeId("cell_"_tRowIndex_"_"_c)
					If tShowCB {	// DTB101 - do not allow cell selection if check boxes are being used
						// WAL252d
						Set tDataTableHTML(tRowIndex,c) = "<td class="""_tCls_""" "_tStyle_" id="""_id_"""><div class=""dsptCellDiv"" "_tIStyle_">&nbsp;"_tDisplay_"</div></td>"
						
						//WAL
						Set tDataTableAttributes(tRowIndex,c,"id") = id
						Set tDataTableAttributes(tRowIndex,c,"class") = tCls 
						Set tDataTableAttributes(tRowIndex,c,"style") = tDStyle
						Set tDataTableAttributes(tRowIndex,c,"contents","class") = "dsptCellDiv"
						Set tDataTableAttributes(tRowIndex,c,"contents","style") = tDIStyle
						Set tDataTableAttributes(tRowIndex,c,"contents","contents") = "&nbsp;"_tDisplay
					}
					Else {
						// WAL252d
						Set tDataTableHTML(tRowIndex,c) = "<td class="""_tCls_""" "_tStyle_" id="""_id_""" onmousedown=""return zenPage.getComponent("_..index_").cellMouseDownHandler(event);"" onclick=""zenPage.getComponent("_..index_").cellClickHandler(event,"_tRowIndex_","_c_");"" ondblclick=""zenPage.getComponent("_..index_").cellDblClickHandler(event,"_tRowIndex_","_c_");"" zenValue="""_tValue_""" title="""_$ZCVT(tValue,"O","HTML")_"""><div class=""dsptCellDiv"" "_tIStyle_">&nbsp;"_tDisplay_"</div></td>"
					
						// WAL
						Set tDataTableAttributes(tRowIndex,c,"id") = id
						Set tDataTableAttributes(tRowIndex,c,"class") = tCls 
						Set tDataTableAttributes(tRowIndex,c,"style") = tDStyle
						Set tDataTableAttributes(tRowIndex,c,"onmousedown") = "return zenPage.getComponent("_..index_").cellMouseDownHandler(event);"
						Set tDataTableAttributes(tRowIndex,c,"onclick") =  "zenPage.getComponent("_..index_").cellClickHandler(event,"_tRowIndex_","_c_");"
						Set tDataTableAttributes(tRowIndex,c,"ondblclick")="zenPage.getComponent("_..index_").cellDblClickHandler(event,"_tRowIndex_","_c_");"
						Set tDataTableAttributes(tRowIndex,c,"zenValue") = tValue
						Set tDataTableAttributes(tRowIndex,c,"title") = $ZCVT(tValue,"O","HTML")
						Set tDataTableAttributes(tRowIndex,c,"contents","class") = "dsptCellDiv"
						Set tDataTableAttributes(tRowIndex,c,"contents","style") = tDIStyle
						Set tDataTableAttributes(tRowIndex,c,"contents","contents") = "&nbsp;"_tDisplay
					}
				}
				Set tProp = $O(tInfo(tProp))
			}
		}
		If $$$ISERR(tSC) Quit

		// WAL252 -- merge
		Set tSC = ..%MergeTables(.tNubTableHTML,.tTopTableHTML,.tSideTableHTML,.tDataTableHTML, .tNubTableAttributes, .tTopTableAttributes, .tSideTableAttributes, .tDataTableAttributes)
		If $$$ISERR(tSC) Quit

		// JMD1462
		If (tZenPage.cssLevel>=3) {
			Set tBackgroundOpacity = ..backgroundOpacity
			Set tBackgroundImage = ..backgroundImage
			If (+..analyzerMode) {
				Set tBackgroundOpacity = 0.12
				Set tBackgroundImage = "deepsee/pivottable.jpg"
			}
			If ((tBackgroundOpacity>0)&&(tBackgroundImage'="")) {
				&html<<div class="dsPivotTableImage" style="background-image:url(#(tBackgroundImage)#);opacity:#(+tBackgroundOpacity)#;"></div>>
			}
		}

		&html<</div>> // outer

		Set ..columnCount = tColCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return information on the set of columns to display for the current KPI.
/// Returns:<br/>
/// pColInfo(n) = property<br/>
/// pColInfo(n,"caption") = caption (if different)<br/>
/// This is a class method that is also called from Excel and PDF export.<br/>
/// If <var>pColumnList</var> is provided, it is a csv-list that specifies the columns 
/// and column order from the KPI to display. Otherwise all columns are displayed in the order
/// defined by the KPI.
ClassMethod %GetKPIColumns(pController As %ZEN.Auxiliary.dataController, Output pColCount As %Integer, Output pColInfo, pColumnList As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pColCount = 0
		Set tModel = pController.%model

		// +DTB457 - Check for a single hidden column
		Set tHideColumn = ""
		If ($E(pColumnList)="!") {
			Set tHideColumn = $E(pColumnList,2,*)
			Set pColumnList = ""
		}
		// -DTB457

		If (pColumnList'="") {
			// get captions from KPI
			If ($IsObject(tModel) && (tModel.%IsA("%DeepSee.KPI"))) {
				// KPIs have more information
				Set tSC = tModel.%GetKPIPropertyInfo(.tInfo)
				If $$$ISERR(tSC) Quit

				Set n = $O(tInfo(""))
				While (n'="") {
					Set tSeqNo = $G(tInfo(n,"columnNo"),99999)
					Set tName = $G(tInfo(n))
					Set tCaption = $G(tInfo(n,"caption"))
					Set tIndex(tName) = tCaption
					Set tFormats(tName) = $G(tInfo(n,"format"))
					Set tStyles(tName) = $G(tInfo(n,"style"))
					Set tHeaderStyles(tName) = $G(tInfo(n,"headerStyle"))
					Set n = $O(tInfo(n))
				}
			}

			// pull columns out of list
			// handle escaped characters
			Set tColList = pColumnList
			Set tColList = $Replace(tColList,"\,",$C(1))
			Set tColList = $Replace(tColList,"\:",$C(2))

			For p=1:1:$L(tColList,",") {
				Set pColCount = pColCount + 1
				Set tItem = $ZSTRIP($P(tColList,",",p),"<>W")
				Set tName = $$UNESC($P(tItem,":",1))
				If (tName'="") {
					Set tCaption = $$UNESC($P(tItem,":",2))
					Set tFormat = $$UNESC($P(tItem,":",3))
					Set:tFormat="" tFormat = $G(tFormats(tName))
					Set tStyle = $G(tStyles(tName))
					Set tHeaderStyle = $G(tHeaderStyles(tName))

					Set pColInfo(pColCount) = tName
					If ($G(tIndex(tName))'="") {
						Set pColInfo(pColCount,"caption") = tIndex(tName)
					}
					If ((tCaption'="")&&(tCaption'="$auto")) {
						// local override
						Set pColInfo(pColCount,"caption") = tCaption
					}
					If (tFormat'="") {
						// local override
						Set pColInfo(pColCount,"format") = tFormat
					}
					If (tStyle'="") {
						Set pColInfo(pColCount,"style") = tStyle
					}
					If (tHeaderStyle'="") {
						Set pColInfo(pColCount,"headerStyle") = tHeaderStyle
					}
				}
			}
			Quit
		}

		// get info from controller
		If ($IsObject(tModel) && (tModel.%IsA("%DeepSee.KPI"))) {
			// KPIs have more information
			Set tSC = tModel.%GetKPIPropertyInfo(.tInfo)
			If $$$ISERR(tSC) Quit

			Set n = $O(tInfo(""))
			While (n'="") {
				Set tSeqNo = $G(tInfo(n,"columnNo"),99999)
				Set tCaption = $G(tInfo(n,"caption"))
				// JMD921
				Set tFormat = $G(tInfo(n,"format"))
				Set tStyle = $G(tInfo(n,"style"))
				Set tHeaderStyle = $G(tInfo(n,"headerStyle"))
				Set tList(tSeqNo,n) = $LB(tInfo(n),tCaption,tFormat,tStyle,tHeaderStyle)
				Set n = $O(tInfo(n))
			}

			// now put items into the output list
			Set pColCount = 0
			Set k = $O(tList(""))
			While (k'="") {
				Set n = $O(tList(k,""))
				While (n'="") {
					If $LG(tList(k,n),1)'=tHideColumn {
						// DTB457 - There might be a single column removal
						Set pColCount = pColCount + 1
						Set pColInfo(pColCount) = $LG(tList(k,n),1)
						Set:($LG(tList(k,n),2)'="") pColInfo(pColCount,"caption") = $LG(tList(k,n),2)
						Set:($LG(tList(k,n),3)'="") pColInfo(pColCount,"format") = $LG(tList(k,n),3)
						Set:($LG(tList(k,n),4)'="") pColInfo(pColCount,"style") = $LG(tList(k,n),4)
						Set:($LG(tList(k,n),5)'="") pColInfo(pColCount,"headerStyle") = $LG(tList(k,n),5)
					}
					Set n = $O(tList(k,n))
				}
				Set k = $O(tList(k))
			}
		}
		Else {
			// use generic information
			Set tSC = pController.%GetModelPropertyInfo(.tInfo)
			If $$$ISERR(tSC) Quit

			// first get non % props from controller in sequence order
			Set tProp = $O(tInfo(""))
			While (tProp'="") {
				If (tProp '[ "%") {
					Set tList(tInfo(tProp)) = tProp
				}
				Set tProp = $O(tInfo(tProp))
			}

			// now put them in the output list
			Set pColCount = 0
			Set k = $O(tList(""))
			While (k'="") {
				If tList(k)'=tHideColumn {
					// DTB457 - There might be a single column removal
					Set pColCount = pColCount + 1
					Set pColInfo(pColCount) = tList(k)
				}
				Set k = $O(tList(k))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
UNESC(x)
	Set x = $Replace(x,$C(1),",")
	Set x = $Replace(x,$C(2),":")
	Quit x
}

/// Draw the contents of the status area.
/// <var>pMode</var> indicates whether this is a pivot status or a listing status.
Method %DrawStatusArea(pPageCount As %Integer, pMode As %String = "pivot", pTruncated As %Boolean = 0) As %Status [ Internal ]
{
	&html<<table><tr>>

	If (pMode="listing") {
		Set tMsgRows = $$$Text("Records:","%DeepSee")

		Set tCurrPage = ..currListingPage
		Set tListingCount = $S(..listingRowCount="":"",1:$FN(..listingRowCount,","))
		
		// PFS104 - Add info message to inform users that more rows may exist
		Set tListingMax = ""
		If ( ..listingRowCount >= $S(+..listingRows:..listingRows,1:..#MAXLISTINGROWS) ) {		// DTB924 - Check the table's listingRows setting first
			Set tListingMax = $$$Text("Maximum listing rows reached. Additional rows may exist.")
		}

		&html<<td valign="middle" nowrap="1">>
		&html<<span class="dsptStatusLabel">#(tMsgRows)#</span><span id="#(..%MakeId("listingCount"))#" class="dsptStatusValue">#(tListingCount)#</span>&nbsp;<span id="#(..%MakeId("listingMax"))#" class="dsptStatusValue">#(tListingMax)#</span>&nbsp;>
		&html<</td>>
	}
	Else {
		// pivot
		Set tValue = $S(..totalValue="":$$$Text("working...","%DeepSee"),..totalValue="ERROR":$$$Text("ERROR","%DeepSee"),..totalValue'=(..totalValue\1):$FN(..totalValue,",",2),1:$FN(..totalValue,","))
		Set tCellCount = $S(..cellCount="":"",1:$FN(..cellCount,","))

		Set tMsgTotal = $$$Text("Total:","%DeepSee")
		Set tMsgCells = $$$Text("Cells:","%DeepSee")
		Set tCurrPage = ..currPage

		If (..showPivotStats) {
			&html<<td valign="middle" nowrap="1">>
			&html<<span class="dsptStatusLabel">#(tMsgCells)#</span><span id="#(..%MakeId("cellCount"))#" class="dsptStatusValue">#(tCellCount)#</span>&nbsp;>
			&html<<span class="dsptStatusLabel">#(tMsgTotal)#</span><span id="#(..%MakeId("total"))#" class="dsptStatusValue">#(tValue)#</span>&nbsp;>
			If (..columnsTruncated) {
				Set msgTooMany = $$$FormatText($$$Text("Too many columns: Only the first %1 are displayed","%DeepSee"),..#MAXCOLUMNS)
				&html<<span class="dsptStatusLabel" style="color:#802020;padding:1px;">&nbsp;#(msgTooMany)#&nbsp;</span>&nbsp;>
			}
			&html<</td>>
		}
		// JMD900 - pending results indicator
		Set msgComputing = $$$Text("Computing...","%DeepSee")
		Set tStyle = $S(..queryPending:"",1:"display:none;")
		&html<<td>&nbsp;&nbsp;&nbsp;</td><td valign="middle" nowrap="1" id="#(..%MakeId("pending"))#" style="#(tStyle)#"><span class="dsptStatusLabel">#(msgComputing)#</span></td>>
	}

	// JMD1129
	If (pTruncated)&&(..headFunctionAdded) {		// DTB201
		Set hlpShow = $$$Text("Click here to load all results")
		Set msgShow = $$$Text("Show All")
		&html<<td class="dsptShowMore" valign="middle" nowrap="1" onclick="zenPage.getComponent(#(..index)#).showAllRows();" title="#(hlpShow)#">#(msgShow)#</td>>

		// DP-424297 - Set the informational message indicating why the Show All button is present
		If ..previewMode {
			Set reasonShow = $$$Text("Preview Mode selected, results are truncated")
		}
		Else {
			Set reasonShow = $$$Text("Crossjoin results have been truncated")
		}
		&html<<td>&nbsp;&nbsp;&nbsp;</td><td class="dsptStatusLabel" style="color:#802020;padding:1px;" nowrap="1">#(reasonShow)#</td>>

		Set ..rowsTruncated = pTruncated		// DTB712
	}

	#; navigation buttons
	&html<<td nowrap="1" align="right" valign="middle" width="90%">>
	If (pPageCount>1) {
		// JMD1304 indicate truncated results
		Set tPageCountMsg = pPageCount _ $S(pTruncated:"+",1:"")
		Set msgPage = $$$FormatText($$$Text("Page %1 of %2","%DeepSee"),tCurrPage,tPageCountMsg)
		Set hlpFirst = $$$Text("View first page of results","%DeepSee")
		Set hlpPrev = $$$Text("View previous page of results","%DeepSee")
		Set hlpNext = $$$Text("View next page of results","%DeepSee")
		Set hlpLast = $$$Text("View last page of results","%DeepSee")

		&html<<span class="dsptStatusLabel">#(msgPage)#&nbsp;</span>>
		&html<</td>>
		&html<<td nowrap="1" align="right" valign="middle" width="5%">>
		&html<<div class="dsptIconBar" style="font-size:0.8em;vertical-align:top;">>
			
			If (tCurrPage > 1) {
				&html<<img class="dsptIcon" title="#(hlpFirst)#" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_skip_backward.png" onclick="zenPage.getComponent(#(..index)#).firstPage();" />>
				&html<<img class="dsptIcon" title="#(hlpPrev)#" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_rewind.png" onclick="zenPage.getComponent(#(..index)#).previousPage();"/>>
			}
			Else {
				&html<<img class="dsptIconDisabled" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_skip_backward.png"/>>
				&html<<img class="dsptIconDisabled" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_rewind.png"/>>
			}
			If (tCurrPage < pPageCount) {
				&html<<img class="dsptIcon" style="height:18px;width:18px;padding:2px;" title="#(hlpNext)#" src="deepsee/ds2_fast_forward.png" onclick="zenPage.getComponent(#(..index)#).nextPage();" />>
				&html<<img class="dsptIcon" title="#(hlpLast)#" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_skip_forward.png" onclick="zenPage.getComponent(#(..index)#).lastPage();"/>>
			}
			Else {
				&html<<img class="dsptIconDisabled" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_fast_forward.png" />>
				&html<<img class="dsptIconDisabled" style="height:18px;width:18px;padding:2px;" src="deepsee/ds2_skip_forward.png"/>>
			}		
		&html<</div>>
	}
	&html<</td>>
	&html<</tr></table>>
	Quit $$$OK
}

/// Draw the table containing the data cells.<br/>
/// <var>pColRoot</var> is node number for top node along the column axis.<br/>
/// <var>pRowRoot</var> is node number for top node along the row axis.<br/>
/// <var>pStartRow</var> is the ordinal number of the first row to display.<br/>
/// <var>pEndRow</var> is the ordinal number of the last row to display.<br/>
Method %DrawDataTable(pAxisCount As %Integer, pColRoot As %Integer, pRowRoot As %Integer, pStartRow As %Integer, pEndRow As %Integer, pColumnTotals As %Boolean = 0, pRowTotals As %Boolean = 0, pUseSort As %Boolean = 0, pMaxCols As %Boolean = 1000, ByRef pHTML As %String, ByRef pHTMLAttributes As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tTotal = ""
		Set tCellCount = 0
		Set tCellWidth = ..cellWidth
		Set tMaxCols = pMaxCols

		Set tCellHeight = ..cellHeight
		Set tCubeIndex = ..cubeKey
		Set tKey = ..queryKey
		
		// WAL106
		Set tDataTableOffset = pStartRow-1

		// pull range apart
		Set tRangeRow1 = $P(..selectedRange,",",1)
		Set tRangeCol1 = $P(..selectedRange,",",2)
		Set tRangeRow2 = $P(..selectedRange,",",3)
		Set tRangeCol2 = $P(..selectedRange,",",4)

		#; set up format conditions
		Set tFormatRuleCount = ..formatRules.Count()

		#; set up color scaling
		Set tMinRed = 0
		Set tMaxRed = 255
		Set tMinGreen = 0
		Set tMaxGreen = 255
		Set tMinBlue = 0
		Set tMaxBlue = 255
		Set tRedScale = 0
		Set tBlueScale = 0
		Set tGreenScale = 0
		If (..colorScale = "red-to-black") {
			Set tRedScale = 1
		}
		ElseIf (..colorScale = "green-to-black") {
			Set tGreenScale = 1
		}
		ElseIf (..colorScale = "blue-to-black") {
			Set tBlueScale = 1
		}
		ElseIf (..colorScale = "salmon-to-black") {
			Set tRedScale = 1
			Set tGreenScale = 0.65
			Set tBlueScale = 0.45
		}
		ElseIf (..colorScale = "purple-to-black") {
			Set tBlueScale = 1
			Set tRedScale = 1
		}
		ElseIf (..colorScale = "gray-to-black") {
			Set tRedScale = 0.75
			Set tBlueScale = 0.75
			Set tGreenScale = 0.75
		}
		ElseIf ($P(..colorScale,":",1) = "custom") {
			// JMD1063: custom:r1,g1,b1:r2,g2,b2
			Set tRGB1 = $P(..colorScale,":",2)
			Set tRGB2 = $P(..colorScale,":",3)
			Set r1 = +$P(tRGB1,",",1)
			Set g1 = +$P(tRGB1,",",2)
			Set b1 = +$P(tRGB1,",",3)
			Set r2 = +$P(tRGB2,",",1)
			Set g2 = +$P(tRGB2,",",2)
			Set b2 = +$P(tRGB2,",",3)
			Set r1=$S(r1<0:0,r1>255:255,1:r1)
			Set g1=$S(g1<0:0,g1>255:255,1:g1)
			Set b1=$S(b1<0:0,b1>255:255,1:b1)
			Set r2=$S(r2<0:0,r2>255:255,1:r2)
			Set g2=$S(g2<0:0,g2>255:255,1:g2)
			Set b2=$S(b2<0:0,b2>255:255,1:b2)
			Set tMinRed = r1,tMaxRed=r2,tRedScale = (r2-r1)/255
			Set tMinGreen = g1,tMaxGreen=g2,tGreenScale = (g2-g1)/255
			Set tMinBlue = b1,tMaxBlue=b2,tBlueScale = (b2-b1)/255
		}

		Set tRowRoot = pRowRoot
		Set tColRoot = pColRoot
		Set tColAxisNo = 1
		Set tRowAxisNo = 2
		Set tPageAxisNo = 3
		Set tPageNodeNo = ""		// can only be one value

		Set tMessage = $ZCVT(..%message,"O","HTML")

		// WAL -- draw empty table
		If ((tCubeIndex="")||(tKey="")) {
			If (..dataSource="automatic") {
				Do ..%DrawEmptyTable($$$Text("No cube"),.tDataTableHTML,.tDataTableHTMLAttributes)
				Merge pHTML = tDataTableHTML
				Merge pHTMLAttributes = tDataTableHTMLAttributes // WAL
			}
			Else {
				Do ..%DrawEmptyTable($$$Text("No results"),.tDataTableHTML,.tDataTableHTMLAttributes)
				Merge pHTML = tDataTableHTML
				Merge pHTMLAttributes = tDataTableHTMLAttributes // WAL
			}
			Quit
		}

		// get keys used to find axis info
		Set tColAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",tColAxisNo))
		Set tRowAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",tRowAxisNo))
		Set tPageAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",tPageAxisNo))

		If (pAxisCount>3) {
			Do ..%DrawEmptyTable($$$Text("Pivot table cannot show more than 3 dimensional results"),.tDataTableHTML,.tDataTableHTMLAttributes)
			Merge pHTML = tDataTableHTML
			Merge pHTMLAttributes = tDataTableHTMLAttributes // WAL
			Quit
		}

		Set tMinValue = +$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"stats","min"))
		Set tMaxValue = +$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"stats","max"))
		Set tRange = tMaxValue - tMinValue

		// count number of columns; build local index
		Set tColCount = 0
		If (tMessage '= "") {
			Set tCellWidth = 500 + 3 // extra space for message
			Set tColCount = 1
			Set tColIndex(1) = ""
		}
		ElseIf (tColRoot="") {
			Set tColCount = 1
			Set tColIndex(1) = ""
		}
		Else {
			Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"leaf",tColAxisNo,""),1,data)
			While (c'="") {
				If (tColCount >= tMaxCols) {
					Set ..columnsTruncated = 1
				}
				Else {
					Set tColCount = tColCount + 1
					Set tColIndex(tColCount) = data
					Set tFmt = ""
					Set tCSO = 0
					Set tCStyle = ""
					Set tTestNodeNo = data
					While ((tTestNodeNo'="")) {
						Set tSNodeType = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),1)
						Set tCF = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),12)
						Set:(tCF'="")&&(tFmt="") tFmt = tCF
						Set tCS = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),18)
						Set:(tCS'="")&&(tCStyle="") tCStyle = tCS
						Set tSO = +$LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),15)
						Set:tSO>0 tCSO = tSO
						Set tTestNodeNo = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tColAxisKey,"axes",tTestNodeNo)),4)
					}

					Set tCAgg = ""
					Set:tCStyle["summary:" tCStyle = ..%GetSummaryFromCSS(tCStyle,.tCAgg)

					Set:tFmt'="" tColFormat(tColCount) = tFmt
					Set:tCStyle'="" tColStyle(tColCount) = tCStyle
					Set:tCAgg'="" tColAgg(tColCount) = tCAgg
					Set:tCSO>0 tColSolveOrder(tColCount) = tCSO
				}
				Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"leaf",tColAxisNo,c),1,data)
			}
		}

		If (tPageAxisKey'="") {
			Set p = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"leaf",tPageAxisNo,""),1,data)
			If (p'="") { 
				Set tPageIndex = data
				// JMD1406
				Set tPageFormat = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tPageAxisKey,"axes",data),12)
			}
		}

		#; cell table
		Set tNotCalculated = "?"
		Set tNull = $S(..queryStatus>=100:"",1:tNotCalculated)
		Set tTableStarted = 0

		// JMD988
		Set tHasCmbr = $D($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"cmbrMap"))

		#; rows
		Set tRowCount = 0
		Set tRow = 0
		If (tRowRoot="") {
			Set r = 1
		}
		Else {
			Set r = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tRowRoot,"all",""))
		}

		#; display rows
		For tRowIndex = pStartRow:1:pEndRow {
			If (pUseSort) {
				Set tRow = $$$DeepSeeResultsGLVN(tCubeIndex,tKey,"sort",..sortColumn,..sortDir,tRowIndex)
			}
			Else {
				Set tRow = tRowIndex
			}
			Set tRowCount = tRowCount + 1
			If ('tTableStarted) {
				Set tTableStarted = 1
			}

			#; determine default format
			Set tDefaultFormat = $G(tPageFormat)
			Set tDefaultStyle = ""
			Set tSlicer = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"slicer"))
			If (tSlicer'="") {
				Set tSlicerKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",0))
				If (tSlicerKey'="") {
					Set s = $O($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",1,"all",""))
					If (s'="") {
						Set tSNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",s))
						Set tSNodeType = $LG(tSNode,1)
						If ((tSNodeType="msr")||(tSNodeType="exp")||(tSNodeType="cmbr")) {
							Set tDefaultFormat = $LG(tSNode,12)
						}
						Else {
							// look at parent node
							Set sp = $LG(tSNode,4)
							While (sp'="") {
								Set tSNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",sp))
								Set tSNodeType = $LG(tSNode,1)
								If ((tSNodeType="msr")||(tSNodeType="exp")||(tSNodeType="cmbr")) {
									Set tDefaultFormat = $LG(tSNode,12)
									Quit
								}
								Set sp = $LG(tSNode,4)
							}
						}
					}
				}
			}

			If (..showZebra) {
				Set tZebraClass = $S('(tRowCount#2):"dsptRowEven",1:"dsptRowOdd")
				If (..cellStyle'="") {
					Set tZebraStyle = $S('(tRowCount#2):..evenRowStyle,1:"background:white;")
				}
				Else {
					// WAL106
					//Set tZebraStyle = $S('(tRowCount#2):..evenRowStyle,1:"background:none;")
					Set tZebraStyle = $S('(tRowCount#2):..evenRowStyle,1:"background:white;")
				}
			}
			Else {
				Set tZebraClass = ""
				Set tZebraStyle = ""
			}

			#; get value for cells
			#; use -1 to avoid subscript error
			Set tRowNode = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"leaf",tRowAxisNo,tRow))
			Set:tRowNode="" tRowNode = -1
			Set tRowFormat = ""
			Set tRowCStyle = ""
			Set tRowSolveOrder = 0

			If (tRowAxisKey'="") {
				Set tTestNodeNo = tRowNode
				While ((tTestNodeNo'="")) {
					Set tSNodeType = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),1)
					Set tRF = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),12)
					Set:(tRF'="")&&(tRowFormat="") tRowFormat = tRF
					Set tRCS = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),18)
					Set:(tRCS'="")&&(tRowCStyle="") tRowCStyle = tRCS
					Set tSO = +$LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),15)
					Set:tSO>0 tRowSolveOrder = tSO
					Set tTestNodeNo = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tTestNodeNo)),4)
				}
			}

			Set tRowAgg = ""
			Set:tRowCStyle["summary:" tRowCStyle = ..%GetSummaryFromCSS(tRowCStyle,.tRowAgg)
			
			For c = 1:1:tColCount {
				Set tIcon = ""
				Set tIconCount = 1
				Set tColNode = tColIndex(c)
				Set tCmbrFormat = ""

				// put node #s in canonic order
				If (pAxisCount<2) {
					Set tNodeIdx(1) = tColNode
					Set tNodeIdx(2) = ""
					Set:$G(tPageIndex)'="" tNodeIdx(3) = tPageIndex
				}
				Else {
					Set tNodeIdx(1) = tColNode
					Set tNodeIdx(2) = tRowNode
					Set:$G(tPageIndex)'="" tNodeIdx(3) = tPageIndex
				}
				If (tMessage'="") {
					Set tValue = tMessage
					Set tTotal = 0
				}
				Else {
					Set tValue = $$GETVAL(pAxisCount,.tNodeIdx)
					Set:$IsValidNum(tValue) tTotal = tTotal + tValue		// DTB363

					// JMD988 Test for cmbr override of format
					If (tHasCmbr&&($G(tNodeIdx(1))'="")&&($G(tNodeIdx(2))'="")) {
						Set tCmbrFormat = $LG($G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"cmbrMap",tNodeIdx(1),tNodeIdx(2),0)),12)
					}
				}

				Set tCls = "dsPivotNum"
				Set tStyle = ..cellStyle
				If (tCellWidth'="") {
					Set tStyle = tStyle _ "min-width:"_(tCellWidth-3)_"px;"		// DP-407877 - Make sure the user setting is actually applied using the min-width
				}
				If (tCellHeight'="") {
					Set tStyle = tStyle _ "height:"_(tCellHeight)_"px;"
				}
				Set tStyle = tStyle _ tZebraStyle

				If (+$G(tColSolveOrder(c))>=tRowSolveOrder) {
					If ($G(tColFormat(c))'="") {
						Set tFormat = tColFormat(c)
					}
					ElseIf (tRowFormat'="") {
						Set tFormat = tRowFormat
					}
					Else {
						Set tFormat = tDefaultFormat
					}
					If ($G(tColStyle(c))'="") {
						Set tCStyle = tRowCStyle_tColStyle(c)
					}
					ElseIf (tRowCStyle'="") {
						Set tCStyle = $G(tColStyle(c))_tRowCStyle
					}
					Else {
						Set tCStyle = tDefaultStyle
					}
				}
				Else {
					If (tRowFormat'="") {
						Set tFormat = tRowFormat
					}
					ElseIf ($G(tColFormat(c))'="") {
						Set tFormat = tColFormat(c)
					}
					Else {
						Set tFormat = tDefaultFormat
					}
					If (tRowCStyle'="") {
						Set tCStyle = $G(tColStyle(c))_tRowCStyle
					}
					ElseIf ($G(tColStyle(c))'="") {
						Set tCStyle = tRowCStyle_tColStyle(c)
					}
					Else {
						Set tCStyle = tDefaultStyle
					}
				}
				Set:tCmbrFormat'="" tFormat = tCmbrFormat

				// format cell
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set tCls = $Case(tType,"integer":"dsPivotNum",
										"date":"dsPivotDate",
										"number":"dsPivotNum",
										:"dsPivotString")

				// 3rd piece of format is cell style
				If ($P(tFormat,"^",3)'="") {
					Set tStyle = tStyle_$P(tFormat,"^",3)
				}

				// color scaling
				If (..queryStatus < 100) {
					// partial results
					Set tStyle = tStyle_"color:blue;"
				}
				ElseIf ($P(tValue," ") = "@Computing") {
					// JMD900: pending results: pct is 0 to 100
					Set tPct = +$P(tValue," ",2)
					Set tStyle = tStyle_"background:rgb(180,180,"_(200+(tPct\2))_");color:#404040;white-space:nowrap;font-size:0.8em;"
					Set tDisplay = $$$Text("Computing","%DeepSee")_": " _ $FN(tPct,"",2) _ "%"
				}
				ElseIf ($IsValidNum(tValue)&&(tRange>0)&&(..colorScale'="")) {
					// special case for pct values
					If (tFormat["%") {
						Set tPct = $S(tValue<0:0,tValue>1:1,1:tValue)
					}
					Else {
						Set tPct = (tValue-tMinValue/tRange)
					}
					Set cvr = $S(tMinRed<tMaxRed:(tMinRed + (tRedScale * tPct * tMaxRed)\1),1:(tMaxRed + (-tRedScale * (1-tPct) * tMinRed)\1))
					Set cvg = $S(tMinGreen<tMaxGreen:(tMinGreen + (tGreenScale * tPct * tMaxGreen)\1),1:(tMaxGreen + (-tGreenScale * (1-tPct) * tMinGreen)\1))
					Set cvb = $S(tMinBlue<tMaxBlue:(tMinBlue + (tBlueScale * tPct * tMaxBlue)\1),1:(tMaxBlue + (-tBlueScale * (1-tPct) * tMinBlue)\1))
					Set tBright = (cvr*cvr*0.241)+(cvg*cvg*0.691)+(cvb*cvb*0.068)
					Set tFG = $S(tBright>16900:"black",1:"white")
					Set tStyle = tStyle_"background:rgb("_cvr_","_cvg_","_cvb_");color:"_tFG_";"
				}

				// conditional format
				For n = 1:1:tFormatRuleCount {
					Set tCondition = ..formatRules.GetAt(n)
					If (tCondition.%EvaluateCondition(tRow,c,tValue)) {
						Set tStyle = tStyle _ tCondition.style
						Set:tCondition.text'="" tDisplay = tCondition.text
						Set:tCondition.icon'="" tIcon = tCondition.icon
						Set:tCondition.iconCount'="" tIconCount = tCondition.iconCount
						If (($E(tIcon)="@")&&(tIcon'="@")) {
							// user icon: resolve
							Set ik = $E(tIcon,2,$L(tIcon))
							If $D(tLocalIconList(ik)) {
								Set tIcon = tLocalIconList(ik)
							}
							Else {
								Set tIcon = ##class(%DeepSee.UserPortal.Utils).%GetUserIcon(ik)
								Set tLocalIconList(ik) = tIcon
							}
						}
					}
				}
				Set tCellCount = tCellCount + 1
				If (tCStyle'="") {
					Set tStyle = tStyle _ tCStyle
				}
				If (tFormatStyle'="") {
					Set tStyle = tStyle _ "color:"_tFormatStyle_";"
				}

				If (tIcon'="") {
					Set tDisplay = ""
					For ic = 1:1:tIconCount {
						Set tDisplay = tDisplay _ "<image alt=""*"" style=""padding-right:2px;"" height="""_(tCellHeight-4)_""" src="""_tIcon_"""/>"
					}
					Set tCls = "dsPivotIcon"
				}
				ElseIf ($E(tDisplay,*)'=")") { // align negative numbers
					Set tDisplay = tDisplay _ "&nbsp;&nbsp;"
				}

				// apply align to inner div
				Set tDivStyle = ""
				Set tTestStyle = $TR(tStyle," ","")
				If ((tCls'="dsPivotNum")||(tTestStyle["text-align:left;")) {
					Set tDivStyle = "text-align:left;"
				}
				If (tTestStyle["text-align:center;") {
					Set tDivStyle = "text-align:center;"
				}
				ElseIf (tTestStyle["text-align:right;") {
					Set tDivStyle = "text-align:right;"
				}

				
				Set tDStyle = tStyle // WAL -- leave style adjustable
				Set tDIStyle = tDivStyle // WAL -- stick with the same format
				Set:tStyle'="" tStyle = "style="_$$$quote(tStyle)
				Set tIStyle = ""
				Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
				
				// WAL106
				Set tDCls = tCls
				If (tZebraClass'="") {
					//Set tCls = tZebraClass	
					If (tZebraClass [ "Odd") { 
						Set tCls = tCls_" dsPivotRowOdd" 
						Set tDCls = "dsPivotRowOdd" // WAL	
					}
					Else {
						Set tCls = tCls_" dsPivotRowEven" 
						Set tDCls = "dsPivotRowEven" // WAL
					}
				}

				Set id = ..%MakeId("cell_"_tRowCount_"_"_c)
				// DTB828 [PFS010] - Use offset to assign absolute ID value
				Set tDataTableHTML((tRowCount+tDataTableOffset),c) = "<td nowrap=""1"" class="""_tCls_""" "_tStyle_" id="""_..%MakeId("cell_"_(tRowCount+tDataTableOffset)_"_"_c)_""" onmousedown=""return zenPage.getComponent("_..index_").cellMouseDownHandler(event);"" onclick=""zenPage.getComponent("_..index_").cellClickHandler(event,"_(tRowCount+tDataTableOffset)_","_c_");"" ondblclick=""zenPage.getComponent("_..index_").cellDblClickHandler(event,"_(tRowCount+tDataTableOffset)_","_c_");"" zenValue="""_tValue_""" title="""_$ZCVT(tValue,"O","HTML")_"""><div class=""dsptCellDiv"" "_tIStyle_">&nbsp;"_tDisplay_"</div></td>"
				
				// when I convert these to strings, all the values need to be quoted
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"id")=id
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"class")=tDCls
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"style")=tDStyle
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"onmousedown")="return zenPage.getComponent("_..index_").cellMouseDownHandler(event);"
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"onclick")="zenPage.getComponent("_..index_").cellClickHandler(event,"_tRowCount+tDataTableOffset_","_c_");"			// DTB828
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"ondblclick")="zenPage.getComponent("_..index_").cellDblClickHandler(event,"_tRowCount+tDataTableOffset_","_c_");"		// DTB828
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"zenValue")=tValue
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"title")=$ZCVT(tValue,"O","HTML")
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"contents","class")="dsptCellDiv"
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"contents","style")=tDIStyle
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),c,"contents","contents")="&nbsp;"_tDisplay			
			}

			If (pColumnTotals) {
				// holder for totals
				Set tStyle = ""
				If ('..showZebra) {
					Set tStyle = tStyle _ "background:#F8F8F8;"
				}
				Set tStyle = tStyle _ ..cellStyle
				Set tStyle = tStyle _ tRowCStyle
				Set tAgg = tRowAgg
				Set tDivStyle = ""
				If (tCellWidth'="") {
					//JMD1465 Set tDivStyle = tDivStyle_"width:"_(tCellWidth-3)_"px;"
				}
				Set tDivStyle = tDivStyle _ "height:auto;"
				If (tCellHeight'="") {
					// JMD1462 don't set height
					// Set tDivStyle = tDivStyle _ "height:"_(tCellHeight)_"px;"
				}
				Set tStyle = tStyle _ "font-weight:bold;"_tZebraStyle
				
				Set tFormat = $G(tRowFormat)
				Set:tFormat="" tFormat = tDefaultFormat
				Set tIStyle = ""
				Set tDIStyle = tDivStyle // WAL
				Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
				
				Set tCls = "dsPivotNum"
				If (tZebraClass'="") {
					//Set tCls = tZebraClass	
					If (tZebraClass [ "Odd") { Set tCls = "dsPivotRowOdd" }
					Else { Set tCls = "dsPivotRowEven" }
				}

				// WAL106 -- this is the end cell in each row -- zebra seems to look good now; will need to review whether or not
				//           icon, num, etc. things still work
				
				Set id = ..%MakeId("ctot_"_tRowCount)
				Set divId = ..%MakeId("ctotd_"_tRowCount)
				// WAL
				Set tDataTableHTML("ctot",(tRowCount+tDataTableOffset)) = "<td style="""_tStyle_""" agg="""_tAgg_""" format="""_$G(tFormat)_""" id="""_id_""" row="""_tRow_""" nowrap=""1"" class="""_tCls_"""><div class=""dsptCellDiv"" id="""_divId_""" "_tIStyle_">&nbsp;</div></td>"
			
				// WAL
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"id")=id
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"class")=tCls
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"row")=tRow
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"format")=$G(tFormat)
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"agg")=tAgg
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"style")=tStyle
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"contents","class")="dsptCellDiv"
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"contents","id") = divId
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"contents","style") = tDIStyle
				Set tDataTableHTMLAttributes((tRowCount+tDataTableOffset),(tColCount+1),"contents","contents") = "&nbsp;"
			}
		}
		
		If ('tTableStarted || (tCellCount=0)) {
			If (..queryStatus < 100) {
				Do ..%DrawEmptyTable($$$Text("Working..."),.tDataTableHTML,.tDataTableHTMLAttributes)
				Merge pHTML = tDataTableHTML
				Merge pHTMLAttributes = tDataTableHTMLAttributes // WAL
			}
			Else {
				Do ..%DrawEmptyTable($$$Text("No results"),.tDataTableHTML,.tDataTableHTMLAttributes)
				Merge pHTML = tDataTableHTML
				Merge pHTMLAttributes = tDataTableHTMLAttributes // WAL
			}
			Quit
		}
		Else {
			If (pRowTotals) {
				Set tRowCount = tRowCount + 1
				If (..showZebra) {
					Set tZebraClass = $S('(tRowCount#2):"dsptRowEven",1:"dsptRowOdd")
					If (..cellStyle'="") {
						Set tZebraStyle = $S('(tRowCount#2):..evenRowStyle,1:"background:white;")
					}
					Else {
						Set tEvenRowStyle=""
						If (..evenRowStyle = "") {
							Set tEvenRowStyle="background:#F0F0F4;"
						}
						Set tZebraStyle = $S('(tRowCount#2):tEvenRowStyle,1:"background:white;")
					}
				}
				Else {
					Set tZebraClass = ""
					Set tZebraStyle = ""
				}
				
				// WAL106
				Set tCls = "dsPivotNum"
				If (tZebraClass'="") {	
					If (tZebraClass [ "Odd") { Set tCls = "dsPivotRowOdd" }
					Else { Set tCls = "dsPivotRowEven" }
				}
				
				For c = 1:1:tColCount {
					Set tAgg = $G(tColAgg(c))
					Set tFormat = $G(tColFormat(c))
					Set:tFormat="" tFormat = tDefaultFormat
					Set tStyle = ..cellStyle _ $G(tColStyle(c))
					Set tDivStyle = ""
					If (tCellWidth'="") {
						// JMD1462 don't set width for totals
						//Set tDivStyle = tDivStyle_"width:"_(tCellWidth-3)_"px;"
					}
					Set tStyle = tStyle _ tZebraStyle
					Set tIStyle = ""
					Set tDIStyle = tDivStyle // WAL
					Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
					// WAL106 -- add tCls
					
					Set id = ..%MakeId("rtot_"_c)
					Set divId = ..%MakeId("rtotd_"_c)
					// WAL
					Set tDataTableHTML("rtot",c) = "<td style=""font-weight:bold;background:#F8F8F8;"_tStyle_""" agg="""_$G(tAgg)_""" format="""_tFormat_""" id="""_id_""" nowrap=""1"" class="""_tCls_"""><div class=""dsptCellDiv"" id="""_divId_""" "_tIStyle_">&nbsp;</div></td>"
				
					// WAL 
					Set tDataTableHTMLAttributes(tRowCount,c,"id") = id
					Set tDataTableHTMLAttributes(tRowCount,c,"style") = "font-weight:bold;background:#F8F8F8;"_tStyle
					Set tDataTableHTMLAttributes(tRowCount,c,"agg") = $G(tAgg)
					Set tDataTableHTMLAttributes(tRowCount,c,"format") = tFormat
					Set tDataTableHTMLAttributes(tRowCount,c,"class") = tCls
					Set tDataTableHTMLAttributes(tRowCount,c,"contents","class") = "dsptCellDiv"
					Set tDataTableHTMLAttributes(tRowCount,c,"contents","id") = divId
					Set tDataTableHTMLAttributes(tRowCount,c,"contents","style") = tDIStyle
					Set tDataTableHTMLAttributes(tRowCount,c,"contents","contents") = "&nbsp;"
				}
				If (pColumnTotals) {
					Set tStyle = ..cellStyle
					Set tDivStyle = ""
					If (tCellWidth'="") {
						// JMD1462 don't set width for totals
						//Set tDivStyle = tDivStyle_"width:"_(tCellWidth-3)_"px;"
					}
					Set tStyle = tStyle _ tZebraStyle
					Set tFormat = $G(tColFormat(tColCount))
					Set:$G(tFormat)="" tFormat = tDefaultFormat
					Set tIStyle = ""
					Set tDIStyle = tDivStyle // WAL
					Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
					
					Set id = ..%MakeId("gtot")
					Set divId = ..%MakeId("gtotd")
					// WAL
					Set tDataTableHTML("gtot") = "<td style=""font-weight:bold;background:#F8F8F8;"_tStyle_""" format="""_tFormat_""" id="""_id_""" nowrap=""1"" class=""dsPivotNum""><div class=""dsptCellDiv"" id="""_divId_""" "_tIStyle_">&nbsp;</div></td>"
				
					// WAL -- grand total node
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"style") = "font-weight:bold;background:#F8F8F8;"_tStyle
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"format") = tFormat
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"id") = id
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"class") = "dsPivotNum"
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"contents","class") = "dsptcellDiv"
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"contents","id") = divId
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"contents","style") = tDIStyle
					Set tDataTableHTMLAttributes(tRowCount,(tColCount+1),"contents","contents") = "&nbsp;"
				}
			}
		}
		
		Merge pHTML = tDataTableHTML
		Merge pHTMLAttributes = tDataTableHTMLAttributes
		
		Set ..totalValue = tTotal
		Set ..cellCount = tCellCount
		Set ..columnCount = tColCount
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC

	// lookup value in result cache; tNodeNo is array of subscripts in axis order
	Set tAxisCount = ""
GETVAL(tAxisCount,tNodeNo)
	Quit $Case(tAxisCount,
		0:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0)),
		1:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1))),
		2:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2))),
		3:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2),tNodeNo(3))),
		4:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2),tNodeNo(3),tNodeNo(4))),
		5:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2),tNodeNo(3),tNodeNo(4),tNodeNo(5))),
		6:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2),tNodeNo(3),tNodeNo(4),tNodeNo(5),tNodeNo(6))),
		7:$G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",0,tNodeNo(1),tNodeNo(2),tNodeNo(3),tNodeNo(4),tNodeNo(5),tNodeNo(6),tNodeNo(7))),
		:"")
}

/// Draw a one-cell data table with the given message.
Method %DrawEmptyTable(pMessage As %String, ByRef pHTML As %String, ByRef pHTMLAttributes) As %Status
{
	Set tRow = 1
	Set c = 1
	Set tRowCls = $S(..showZebra:"dsPivotRowOdd",1:"")
	Set tCls = ""
	Set tStyle = ""
	Set tCellWidth = ..cellWidth
	Set id = ..%MakeId("cell_"_tRow_"_"_c)

	// + WAL106 -- instead of drawing the empty table, return the HTML for the one data table cell
	//  		   let the caller know we create the empty table so it won't write out the nub
	Set pHTML(1,1) = "<td nowrap=""1"" class="""_tCls_""" """_tStyle_""" id="""_id_""" zenValue="""" title="""_$ZCVT(pMessage,"O","HTML")_"""><div class=""dsptCellDiv"" style=""width:"_tCellWidth_"px;"">&nbsp;"_$ZCVT(pMessage,"O","HTML")_"</div></td>"
	Set pHTML("empty") = 1
	// - WAL106
	
	// WAL
	Set pHTMLAttributes(1,1,"class") = tCls
	Set pHTMLAttributes(1,1,"style") = tStyle
	Set pHTMLAttributes(1,1,"id") = id
	Set pHTMLAttributes(1,1,"zenValue") = ""
	Set pHTMLAttributes(1,1,"title") = $ZCVT(pMessage,"O","HTML")
	Set pHTMLAttributes(1,1,"contents","class") = "dsptCellDiv"
	Set pHTMLAttributes(1,1,"contents","style") = "width:"_tCellWidth_"px;"
	Set pHTMLAttributes(1,1,"contents","contents") = "&nbsp;"_$ZCVT(pMessage,"O","HTML")

	Set ..totalValue = 0
	Set ..cellCount = 1
	Set ..columnCount = 1
	Quit $$$OK
}

/// Find the number of displayed leaf nodes in the given axis.<br/>
/// <var>pAxisNo</var> is the axis number.<br/>
Method %GetAxisSize(pAxisNo As %Integer) As %Integer [ Internal ]
{
	Set tSize = 0
	Try {
		If $IsObject(..%ResultSet) {
			// DTB868 - Use the current resultset if available
			Set tSize = ..%ResultSet.%GetAxisSize(pAxisNo)
		}
		Else {
			Set tCubeIndex = ..cubeKey
			Set tQueryKey = ..queryKey

			#; walk down leaf nodes and count
			Set tItemNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"leaf",pAxisNo,""))
			While (tItemNo '= "") {
				Set tSize = tSize + 1
				Set tItemNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"leaf",pAxisNo,tItemNo))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tSize = 0
	}
	Quit tSize
}

/// Compute information needed to draw the labels and cells of this table for the
/// given axis.<br/>
/// <var>pAxisNo</var> is the axis number.<br/>
/// <var>pSpan</var> indicates whether we should span parent labels.<br/>
/// <var>pStart</var> is the (ordinal) number of the first cell to show.<br/>
/// <var>pEnd</var> is the (ordinal) number of the end cell to show.<br/>
/// <var>pLevels</var> returns the number of levels within the axis.<br/>
/// <var>pItems</var> returns an array of items to plot.
/// This takes the form:<br/>
/// pItems(level,index) = $LB(nodeNo,colSpan,rowSpan,hasChildren,[itemNo(presorted #)])
/// (along the column axis, otherwise flip the row and col spans).<br/>
Method %GetAxisSpecs(pAxisNo As %Integer, pSpan As %Boolean, pStart As %Integer, pEnd As %Integer, Output pLevels As %Integer, Output pItems, pUseSort As %Boolean = 0) As %Status [ Internal ]
{
	// +DTB254 - Introduce index for testing whether this node is a candidate for display
	Set tVisibleNodeTypes("mbr") = ""
	Set tVisibleNodeTypes("msr") = ""
	Set tVisibleNodeTypes("lit") = ""
	Set tVisibleNodeTypes("agg") = ""
	Set tVisibleNodeTypes("exp") = ""  // WAL186 -- add "exp" so non-"agg" calculated members display properly
	Set tVisibleNodeTypes("cmbr") = "" // WAL198 -- add "cmbr" so properties and current members
	Set tVisibleNodeTypes("cell") = ""	// DTB680
	// -DTB254
	
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = ..cubeKey
		Set tQueryKey = ..queryKey
		Set tSpanParents = pSpan

		Set tAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"axis",pAxisNo))

		Kill pItems
		Set pLevels = 0

		// walk down leaf nodes to find number of levels
		// and remember depth of each node
		Kill tDepth
		For tItemIndex = pStart:1:pEnd {
			// + WAL230 -- use tItemIndex to iterate and tItemNo to identify the item, as below
			//             this ensures that we build tAllNodes correctly even in the case of sorting
			If (pUseSort) {
				Set tItemNo = $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"sort",..sortColumn,..sortDir,tItemIndex)
			}
			Else {
				Set tItemNo = tItemIndex
			}
			// - WAL230
			
			// +DTB248
			Set tSC = ..%ResultSet.%GetOrdinalLabelNodes(pAxisNo,tItemNo,.tNodes)		//Use common resultset API
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			
			Merge tAllNodes(tItemNo) = tNodes		// Store these locally for the second pass where the label graph is actually built
			If '$D(tNodes) {
				Quit
			}
				
			// Each path up the label chain may skip some axis nodes that should not end up in the label.
			// Use $O through the local array rather than going back to the global with parent $LG(node,4)
			Set tNodeNo = $O(tNodes(""),-1,tNode)
			Set tLevel=0
			// -DTB248
			
			// DTB175 - Remember which nodes have measures, and whether display of measures will 
			// have an effect for this node.
			Set tNodeType = $LG(tNode,1)
			Set tHasMeasure(tItemNo) = ((tNodeType = "msr")||(tNodeType = "lit")||(tNodeType="agg"))
			Set tHasMeasure = $G(tHasMeasure,0) || tHasMeasure(tItemNo)

			While (tNodeNo'="") {
				Set tNodeType = $LG(tNode,1)
				If (tNodeType'="")&&$D(tVisibleNodeTypes(tNodeType)) {		// DTB254	// DP-427830 - Make sure node type is non-null
					// JMD1097 If no label, skip
					If (($LG(tNode,5)'="")||(tNodeType="lit")) { // WAL251 -- protect spaces, which are literal values with label ""
						Set tLevel = tLevel + 1
					}
				}
				Set tNodeNo = $O(tNodes(tNodeNo),-1,tNode)		// DTB248 - Use new loop condition
			}
			Set tDepth(tItemNo) = tLevel
			Set pLevels = $S(tLevel>pLevels:tLevel,1:pLevels)
		}
		
		Set tMeasuresThisAxis = ((..measureLocation="columns")&&(pAxisNo=1)) || ((..measureLocation="rows")&&(pAxisNo=2))		// DTB666
		
		If (pLevels = 0) Quit

		// now walk down leaf nodes again to get details
		For tItemIndex = pStart:1:pEnd {
			If (pUseSort) {
				Set tItemNo = $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"sort",..sortColumn,..sortDir,tItemIndex)
			}
			Else {
				Set tItemNo = tItemIndex
			}
			Kill tNodes
			Merge tNodes = tAllNodes(tItemNo)	// DTB248 - pull from stored values
			If '$D(tNodes) {
				Quit
			}
			
			Set tNodeNo = $O(tNodes(""),-1,tNode)

			// + WAL207 -- use tItemNo not tItemIndex, since tDepth is based on itemNo and is created
			//             before we think about sorting.
			//      JMD -- start level # depends on depth of this item
			Set tLevel = pLevels - tDepth(tItemNo) + 1
			// - WAL207
			Set tBottomSpan = tLevel
			
			// +DTB175 - Separate level from span
			Set tItemLevel = tLevel
			Set tNodeType = $LG(tNode,1)
			If (tHasMeasure&&'tHasMeasure(tItemNo)&&(..%HideMeasures())&&tMeasuresThisAxis) {		// DTB666 - Only do this if the measures are on *this* axis!
				// If the axis has measures that are being turned off, but *this* node does not have measures, reduce its span
				Set tBottomSpan = $S((tBottomSpan-1)>=1:tBottomSpan-1,1:1)
			}
			// -DTB175
			
			// DTB248 - We are now walking up a reduced, ordered chain
			Set tParent = $O(tNodes(tNodeNo),-1,tNode)

			While (tParent '= "") {
				Set tNodeType = $LG(tNode,1)
				If $D(tVisibleNodeTypes(tNodeType)) {		// DTB254
					// JMD1097 If no label, skip
					If ($LG(tNode,5)'="") {
						Set tLevel = tLevel + 1
						If ('tSpanParents) {
							Set pItems(tLevel,tItemIndex) = $LB(+tParent,1,1,1)
						}
						Else {
							If ($G(tLastParent(tLevel))=tParent) {
								#; increase span
								Set $List(pItems(tLevel,tLastItem(tLevel)),2) = $List(pItems(tLevel,tLastItem(tLevel)),2)+1
							}
							Else {
								#; add parent node
								#; check if this item is alone at the top
								Set tTestParent = $O(tNodes(tParent),-1,tParentNode)
								Set tParentNodeType = $LG(tParentNode,1)
								
								If $D(tVisibleNodeTypes(tParentNodeType)) {		// DTB254
									Set pItems(tLevel,tItemIndex) = $LB(+tParent,1,1,1)
								}
								Else {
									Set pItems(pLevels,tItemIndex) = $LB(+tParent,1,1,1)
								}
								Set tLastParent(tLevel) = tParent
								Set tLastItem(tLevel) = tItemNo
							}
						}
					}
				}
				Set tParent = $O(tNodes(tParent),-1,tNode)		// DTB248 - Use new loop condition
			}
			Set pItems(tItemLevel,tItemIndex) = $LB(+tNodeNo,1,tBottomSpan,0,tItemNo)		// DTB175 - Use tItemLevel
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Get information for filters.<br/>
/// <var>pInfo</var> returns the list of filters in the first subscript:<br/>
/// pInfo(i) = $LB(idx,spec,value,text,isMsr,isMember)<br/>
/// If the <var>pReturnMembers</var> flag is set, the list of members for the filter will
/// be returned in:<br>
/// pInfo(i,j) = $LB(value,name,memberId,memberKey) for the j-th member of the i-th filter.<br/>
/// There may be advanced filters:<br/>
/// pAdvancedFilters(i) = $LB(idx,spec,text)<br/>
Method %GetFilterInfo(Output pInfo, Output pAdvancedFilters, pReturnMembers = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		Kill pAdvancedFilters
		Set tCubeName = $$$ZENVAL(..cubeName)
		If (tCubeName = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name missing")
			Quit
		}

		Set tContext = ""

		// get local calc members
		For n = 1:1:..calculatedMembers.Count() {
			Set tCalcMbr = ..calculatedMembers.GetAt(n)
			If ($IsObject(tCalcMbr)&&(tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
				Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName)
			}
		}

		// first, organize filters by dimension
		// group filters from same dimension together,
		// organized by level
		// separate advanced items

		For n = 1:1:..filters.Count() {
			Set tFilter = ..filters.GetAt(n)
			If ('$IsObject(tFilter) || (tFilter.enabled=0)) {
				Continue	
			}
			If (tFilter.advanced) {
				// for advanced filters, the spec includes the key value
				// for named filters, the spec is "%FILTER"
				Set pAdvancedFilters($I(pAdvancedFilters)) = $LB(n,tFilter.spec,tFilter.text)
				Continue
			}
			ElseIf ($$$LOWER($E(tFilter.value,1,10))="$variable.") {
				// JMD1276: treat pivot variable as advanced filter (if context is expression)
				Set tVarName = $E(tFilter.value,11,*)
				// only use if context is expression
				Kill tVInfo
				Do ##class(%DeepSee.Utils).%GetPivotVariableInfo(..cubeName,tVarName,.tVInfo)
				If ($G(tVInfo("context"))="expression") {
					Set pAdvancedFilters($I(pAdvancedFilters)) = $LB(n,tFilter.value,tFilter.text)
				}
				Continue
			}
			
			// DTB268 - Check for shared items. Strip any %SHAREDx token if present
			Set tFilterSpec = tFilter.spec
			If $E(tFilterSpec,1,7)="%SHARED" {
				Set tFilterSpec = $P(tFilterSpec,".",2,*)
			}
			
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName,tFilterSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo,.tCalcMbrs)
			If $$$ISERR(tSC) Quit

			If (tDimNo<0) {
				// calc member or named set: make up hier no
				Set tHierNo = $ZCRC(tFilter.spec,6)
			}

			Set tMemberSpec = ""
			// we assume that all filter specs are fully qualified
			// [dim].[hier].[level].Members|AllMembers for a list OR
			// [dim].[hier].[level].&[key] for a specific member
			// !!!
			// OR {a,b,c} for a specific set!
			// there *could* be relationship names at the start of the spec
			// also: the key can be a range

			// JMD1407 process list and check for range
			// first find number of items within the "key"
			Set tCount = 0
			Set tKeyCount = 1
			Set k = $O(tSpecInfo(""))
			While (k'="") {
				Set tCount = tCount + 1
				Set tToken = tSpecInfo(k)
				If (tToken=":") {
					Set tKeyCount = 3
				}
				Set k = $O(tSpecInfo(k))
			}

			For t=1:1:tCount-tKeyCount {
				Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_tSpecInfo(t)_"]"
			}

			Set tMemberKey = ""
			If (tKeyCount = 1) {
				// single key
				Set tMemberKey = tSpecInfo(tCount)
			}
			ElseIf (tKeyCount=3) {
				// range
				Set tMemberKey = "&["_tSpecInfo(tCount-2)_"]:&["_tSpecInfo(tCount)_"]"
			}

			// named set
			If (tDimNo=-2) {
				Set tMemberSpec = "["_$G(tSpecInfo(1))_"]"
				Set tMemberKey = ""
			}

			If (($$$UPPER(tMemberKey)'="MEMBERS")&&($$$UPPER(tMemberKey)'="ALLMEMBERS")) {
				// reference to a specific member (i.e., not a set of members)
				// figure out levelSpec,key,and levelName
				// spec,key,level name,text
				If (tRelationName'="") {
					Set tSpecificMember(n,0) = $LB(tMemberSpec,tMemberKey,tSpecInfo(3),tFilter.text)
				}
				Else {
					// use dhl numbers as a unique key
					Set k = tDimNo_":"_tHierNo_":"_tLevelNo
					Set k2 = $I(tSpecificMember(k))
					Set tSpecificMember(k,k2) = $LB(tMemberSpec,tMemberKey,tSpecInfo(3),tFilter.text)
				}
			}
			Else {
				If (tRelationName'="") {
					Set tFilterList(n,0) = n
					Merge tFilterList(n,0,"info") = tSpecInfo
				}
				Else {
					// skip relations here
					// remove duplicates
					// JMD951 allow duplicates
					//If ('$D(tLevel(tDimNo,tHierNo,tLevelNo))) {
						Set tLevel(tDimNo,tHierNo,tLevelNo) = ""
						// sort within hierarchy, preserve original order otherwise
						//If '$D(tHier(tDimNo,tHierNo)) {
							Set tHier(tDimNo,tHierNo) = $S(tDimNo=0:0,1:n) // measures first
						//}
						Set tIndex = tHier(tDimNo,tHierNo)
						Set tFilter.filterDim = tDimNo
						Set tFilter.filterHier = tHierNo
						Set tFilterList(tIndex,tLevelNo) = n
						Merge tFilterList(tIndex,tLevelNo,"info") = tSpecInfo
					//}
				}
			}
		}
		If $$$ISERR(tSC) Quit

		// process specific member references
		Set n = 0
		Set k = $O(tSpecificMember(""))
		While (k'="") {
			Set tKeyList = ""
			Set tText = ""
			Set tLevelSpec = ""
			Set k2 = $O(tSpecificMember(k,""))
			While (k2'="") {
				Set n = n + 1
				Set tLevelSpec = $LG(tSpecificMember(k,k2),1)
				Set tKey = $LG(tSpecificMember(k,k2),2)
				Set tLevelName = $LG(tSpecificMember(k,k2),3)

				// use ~~ as delim for multiple keys, if present
				Set tKeyList = tKeyList _ $S(tKeyList="":"",1:"~~") _ tKey

				Set tText = tText _ $S(tText="":"",1:",") _ $S(tLevelName'="":tLevelName_"=",1:"")_$LG(tSpecificMember(k,k2),4)

				Set tFilter.position = n
				Set k2 = $O(tSpecificMember(k,k2))
			}

			// JMD1095 Get real value of tDimNo
			Set tDimNo = $P(k,":",1)
			If (tLevelSpec'="") {
				If (tDimNo = -2) {
					// named set
					Set pAdvancedFilters($I(pAdvancedFilters)) = $LB(n,tLevelSpec,tText)
				}
				Else {
					// Set isMember flag to prevent drop down from listing
					Set pInfo(n) = $LB(n,tLevelSpec,tKeyList,tText,0,1)
				}
			}
			Set k = $O(tSpecificMember(k))
		}

		// loop over other filters defined for pTable, get information
		Set i = $O(tFilterList(""))
		While (i'="") {
			Set j = $O(tFilterList(i,""))
			While (j'="") {
				Set tFilter = ..filters.GetAt(tFilterList(i,j))
				Kill tSpecInfo
				Merge tSpecInfo = tFilterList(i,j,"info")
				Kill tMembers
				// check for measures
				Set t = $G(tSpecInfo(1))
				If ($$$UPPER(t) = "MEASURES") {
					Set n = n + 1
					Set tFilter.position = n
					Set pInfo(n) = $LB(tFilterList(i,j),tFilter.spec,tFilter.key,tFilter.text,1,0)
				}
				Else {
					// convert current key value(s) to name value(s)
					Set tFilterValue = ""
					Set tNumKeys = $L(tFilter.key,"~~")
					Set tAbbr = $S(tNumKeys>5:3,tNumKeys>1:11,1:20)
					For t = 1:1:tNumKeys {
						Set tFKey = $P(tFilter.key,"~~",t)
						If (tFKey="") {
							Set tName = ""
						}
						Else {
							Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(tCubeName,tFilter.spec,tFKey,.tName)
							If $$$ISERR(tSC) Quit
						}
						Set tFilterValue = tFilterValue _ $S(tFilterValue="":"",1:"+") _ $E(tName,1,tAbbr)
					}
					If $$$ISERR(tSC) Quit

					Set n = n + 1
					If pReturnMembers {
						// DTB894 - only return the actual members by request
					  	Set tSC = ##class(%DeepSee.Utils).%GetDimensionMembers(tCubeName,tFilter.spec,"",.tMembers)		// DTB599 - explicitly pass null context parameter
					  	If $$$ISERR(tSC) Quit
						Merge pInfo(n) = tMembers
					}
					Set tFilter.position = n
					Set pInfo(n) = $LB(tFilterList(i,j),tFilter.spec,tFilter.key,tFilter.text,,,tFilterValue)

					#; Set context for next filter
					#; assume that filters are grouped and displayed in level order
					If (tFilter.key '= "") {
						// !!! no longer used?
						Set tContext = $LB(tFilter.spec,tFilter.key)
					}
				}
				Set j = $O(tFilterList(i,j))
			}
			If $$$ISERR(tSC) Quit
			Set i = $O(tFilterList(i))
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}	
	Quit tSC
}

/// Create the DeepSee ResultSet needed to get data for this table.<br/>
/// Does not execute the query.<br/>
/// <var>pSC</var> is a status code.<br/>
/// <var>pParms</var> is an array of input parameter values.<br/>
/// <var>pFilterInfo</var> is an array of filter details.<br/>
/// <var>pAdvancedFilters</var> is an array of advanced filter details.<br/>
/// <var>pAxes</var> is an array of top nodes for each axis.<br/>
/// <var>pDataReady</var> is true if the query results are in the cache.<br/>
/// <var>pQueryText</var> is the text of the query.<br/>
/// <var>pComplexQuery</var> is true if this is a "complex" query that should have its axes executed first.<br/>
Method %CreateResultSet(Output pSC As %Status, ByRef pParms, ByRef pFilterInfo, ByRef pAdvancedFilters, Output pQueryText As %String, Output pAxes, Output pDataReady As %Boolean, Output pComplexQuery As %Boolean, pExecuteBaseQuery As %Boolean = 0) As %DeepSee.ResultSet
{
	Set pSC = $$$OK
	Set tRS = ""

	Try {
		Set pComplexQuery = 0
		Set pQueryText = ""
		Set tMeasureCount = 0
		Set tSingleSimpleMeasure = 0

		// invoke callback
		Set tRS = ""
		Set pSC = ..%OnCreateResultSet(.tRS, .pParms)
		If $$$ISERR(pSC) Quit
		Set tCubeName = $$$ZENVAL(..cubeName)

		If (tRS = "") {
			// DTB595 - Create a resultset object and find the current MDX text
			Set tMDX = ..SynthesizeMDX(.pSC, .tRS, .pParms, .pFilterInfo, .pAdvancedFilters, .pQueryText, .pAxes, .pDataReady, .pComplexQuery, pExecuteBaseQuery)
			If $$$ISERR(pSC) Quit
		} 

		If (tMDX '= "") {
			// Use query
			Set pQueryText = tMDX
			Set ^DeepSee.LastQuery = tMDX

			// + WAL075
			Set tSC = ..SetCurrentQueryText("current",tMDX)
			If $$$ISERR(tSC) Quit
			Set tSC = ..SetCurrentQueryText("resolved",tMDX)
			If $$$ISERR(tSC) Quit
			// - WAL075

			// JMD1276: assemble list of pivot variables
			// test for overrides
			Kill tVariables
			If (..cubeName'="") {
				// DTB572 - Always assemble the list of available variables
				Set pSC = ##class(%DeepSee.Utils).%GetPivotVariables(..cubeName,.tVariableList)
				If $$$ISERR(pSC) Quit
				Set vk = $O(tVariableList(""))
				While (vk'="") {
					Set tVName = $$$LOWER($LG(tVariableList(vk),1))
					Set tVDefValue = $LG(tVariableList(vk),3)
					Set tVariables(tVName) = tVDefValue
					Set tVRuntime = ..pivotVariables.GetAt(tVName)
					Set:tVRuntime'="" tVariables(tVName) = tVRuntime
					Set vk = $O(tVariableList(vk))
				}
			}
			Set pSC = tRS.%PrepareMDX(tMDX,.tVariables,.tResolvedMDX)
			If $$$ISERR(pSC) Quit
			
			// DP-403962 - The listing needs to be set into the ResultSet after %PrepareMDX 
			// since %PrepareMDX includes a re-initialization of listing to ""
			Set tSC = tRS.%SetListing(..listing)
			If $$$ISERR(pSC) Quit
			
			// + WAL075
			Set tSC = ..SetCurrentQueryText("resolved",tResolvedMDX)		// DTB411 - Set resolved text
			If $$$ISERR(tSC) Quit
			// - WAL075

			Set ..cubeName = tRS.%GetCubeName()
			Set ..cubeKey = $$$DeepSeeIndex(..cubeName)
		}
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	
	Set:$$$ISERR(pSC) tRS = ""
	Quit tRS
}

/// This callback is invoked when the pivot table is about to
/// create a result set.<br/>
/// If the callback creates a <class>%DeepSee.ResultSet</class> object and returns it
/// via <var>pRS</var>, then the pivot table will use this result set to display results.
Method %OnCreateResultSet(Output pRS As %DeepSee.ResultSet, ByRef pParms) As %Status
{
	Quit $$$OK
}

/// Return the total number of measures and how many are computed measures.
Method %CountMeasures(Output pMeasures As %Integer, Output pComputedMeasures As %Integer) [ Internal ]
{
	Set pComputedMeasures = 0
	Set pMeasures = ..measures.Count()
	If (..cubeName="") Quit
	Set tCube = $$$UPPER(..cubeName)

	For n=1:1:pMeasures {
		// see if this is a computed measure
		Set tMeasure = ..measures.GetAt(n)
		
		Set tSpec = $$$UPPER(tMeasure.spec)
		If ($P(tSpec,"[MEASURES].",1)="") {
			Set tName = $P(tSpec,"[MEASURES].",2,999)
			// unescape
			If ($E(tName,1)="[") {
				Set tName = $E(tName,2,$L(tName)-1)
			}
			If (tName'="") {
				If ($D($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs","MEASURES",tName))) {
					Set pComputedMeasures = pComputedMeasures + 1
				} ElseIf (..calculatedMembers.Count()) {
					// DTB064: This is not defined in the cube--check for any calculated members stored with the table
					For k=1:1:..calculatedMembers.Count() {
						Set tCalcMemberName = $$$UPPER(..calculatedMembers.GetAt(k).memberName)
						Set:(tName=tCalcMemberName) pComputedMeasures = pComputedMeasures + 1	
		 			}	
				}
			}
		} ElseIf ($P($$$UPPER(tSpec),"[%QUALITYMEASURE].",1)="") {
			// DTB064: All quality measures are assumed to be computed
			Set pComputedMeasures = pComputedMeasures + 1
		}
	}
}

Method %CollectMeasures(pQueryKey As %String, Output pCollectedMeasures As %String, pListingFilters As %Boolean) As %Status
{
	// + WAL190 -- collect measures
	Set r1 = +$P(..selectedRange,",",1)
	Set c1 = +$P(..selectedRange,",",2)
	Set r2 = +$P(..selectedRange,",",3)
	Set c2 = +$P(..selectedRange,",",4)
	
	For i=r1:1:r2 {
		Set tTempObj = ##class(%ZEN.proxyObject).%New()
		// this.GetItemSpec(itemInfo,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,tgtType,itemno,1);
		Set tSC = ..GetItemSpec(.tTempObj,..cubeName,pQueryKey,..sortDir,..sortColumn,"row",i,1)
		Set:tTempObj.measureLogical'="" pCollectedMeasures(tTempObj.measureLogical)=""
	}
	For i=c1:1:c2 {
		Set tTempObj = ##class(%ZEN.proxyObject).%New()
		// this.GetItemSpec(itemInfo,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,tgtType,itemno,1);
		Set tSC = ..GetItemSpec(.tTempObj,..cubeName,pQueryKey,..sortDir,..sortColumn,"col",i,1)
		Set:tTempObj.measureLogical'="" pCollectedMeasures(tTempObj.measureLogical)=""
	}

	// Prune the list if we only want measures with listing filters	
	If (pListingFilters) {
		Set tMeasureName = $O(pCollectedMeasures(""))
		While (tMeasureName'="") {
			Set tCalcName = $G($$$DeepSeeMetaGLVN("cubes",..cubeName,"calcMbrs","MEASURES",$$$UPPER(tMeasureName)))
			If (tCalcName'="") {
				Set tListingFilter = $LG($$$DeepSeeMetaGLVN("cubes",..cubeName,"calcMbrs","MEASURES",$$$UPPER(tMeasureName)),6)
				If (tListingFilter'="") {
					Set pCollectedMeasures(tMeasureName,"calcListingFilter") = tListingFilter
				}
				Else {
					Kill pCollectedMeasures(tMeasureName)
				}
			}
			Else {
				// WAL232 -- use more granular metadata location to distinguish between measures that have the same
				//           source property
				Set tMsrInfo = $G($$$DeepSeeMetaGLVN("cubes",..cubeName,"mbrs","MEASURES",$$$UPPER(tMeasureName))) // WAL234
				If (tMsrInfo'="") {
				Set tMsrNumber = $LG(tMsrInfo,2)
					If (tMsrNumber'="") {
						Set tMsrInfo = $$$DeepSeeMetaGLVN("cubes",..cubeName,"mbr#",0,tMsrNumber,0)
						// PFS019 - Use nodes 15 and 16
						Set tListingFilterOperator = $LG(tMsrInfo,15)
						Set tListingFilter = $LG(tMsrInfo,16)
						// WAL232 -- fix typo
						If ((tListingFilter = "")&&((tListingFilterOperator'="MAX")&&(tListingFilterOperator'="MIN"))) { // WAL190 (2)
							Kill pCollectedMeasures(tMeasureName)	
						}
						Else {
							Set pCollectedMeasures(tMeasureName,"listingFilter")=tListingFilter
							Set pCollectedMeasures(tMeasureName,"listingFilterOperator")=tListingFilterOperator
						}	
					}
					Else {
						Kill pCollectedMeasures(tMeasureName)
					}
				}
			}
			Set tMeasureName = $O(pCollectedMeasures(tMeasureName))
		}	
	}
	// - WAL190
	Quit $$$OK
}

/// Return true if the Measures setting stipulates the measures should be hidden from view.
Method %HideMeasures() As %Boolean
{
	// Method added by DTB175 - Reusable implementation of WAL114 logic
	Set tHideMeasures=0
	Try {
		If (..hideMeasures) {
			// Hide only when 1 measure
			If (..hideMeasures = 1) {
				Do ..%CountMeasures(.tMeasureCount)
				If (tMeasureCount=1) {
					Set tHideMeasures = 1
				}
			}
			// Hide always
			ElseIf (..hideMeasures = 2) {
				Set tHideMeasures = 1
			}
		}
	}
	Catch {
	}

	Quit tHideMeasures
}

/// Construct the MDX WHERE clause for the pivot table.
Method %GetWhereClause(ByRef pFilterInfo) As %String [ Internal ]
{
	Set tClause = ""

	// use new %NOT function
	Set tUseNOT = 1

	// use new %OR function
	Set tUseOR = 1

	// assemble slicer from filters & measure
	Set tParenCount = 0

	// count items in slicer
	Set tTermCount = 0

	// JMD866: Do not add measures to WHERE clause;
	// They will either be in %FILTER or in the COLUMNS axis

	Set n = $O(pFilterInfo(""))
	While (n '= "") {
		Set tValue = $LG(pFilterInfo(n),3)
		Set tIsMsr = +$LG(pFilterInfo(n),5)
		If ((tValue '= "")||(tIsMsr)) {
			Set tTermCount = tTermCount + 1
		}
		Set n = $O(pFilterInfo(n))
	}

	If (tTermCount > 0) {
		Set tCount = 0

		// now loop over filter terms
		Set n = $O(pFilterInfo(""))
		While (n '= "") {
			Set tSpec = $LG(pFilterInfo(n),2)
			Set tValue = $LG(pFilterInfo(n),3)
			Set tIsMsr = +$LG(pFilterInfo(n),5)

			// strip function off end of spec, if present
			If ($P($$$UPPER(tSpec),".",$L(tSpec,"."))="MEMBERS") {
				Set tSpec = $P($$$UPPER(tSpec),".",1,$L(tSpec,".")-1)
			}
			ElseIf ($P($$$UPPER(tSpec),".",$L(tSpec,"."))="ALLMEMBERS") {
				Set tSpec = $P($$$UPPER(tSpec),".",1,$L(tSpec,".")-1)
			}

			// test for NO RELATION member!
			Set tNullRef = ""
			Set tDim = $P($$$UPPER(tSpec),".",1)
			Set:$E(tDim)="[" tDim = $E(tDim,2,*-1)
			If (..cubeName'="") {
				Set tNullRef = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cubeName),"relations",$$$UPPER(tDim),"nullReplacement"))
				If (tNullRef'="") {
					Set tNullRef = "&["_$$$UPPER(tNullRef) _ "]"
					Set tDim = "["_tDim_"]"
				}
			}

			If ((tValue '= "")||(tIsMsr)) {
				Set tCount = tCount + 1
				If (tCount > 1) {
					Set tClause = tClause _ ","
				}

				If (tTermCount > tCount) {
					Set tClause = tClause _ "NONEMPTYCROSSJOIN("
					Set tParenCount = tParenCount + 1
				}

				If ('tIsMsr) {
					Set tIsNot = 0
					If ($E(tValue,1,5)="%NOT ") {
						Set tValue = $E(tValue,6,$L(tValue))
						Set tIsNot = 1
					}

					If ($E(tValue,1,2)="&[") {
						If ('tIsNot) {
							If ($$$UPPER(tValue)=tNullRef) {
								Set tClause = tClause _ tDim_"."_tNullRef
							}
							Else {
								If (tUseOR && (tValue["]:&[")) {
									Set tClause = tClause _ "%OR("_tSpec_"."_tValue_")"
								}
								Else {
									Set tClause = tClause _ tSpec_"."_tValue
								}
							}
						}
						Else {
							If (tUseNOT) {
								If ($$$UPPER(tValue)=tNullRef) {
									Set tClause = tClause _ tDim_"."_tNullRef_".%NOT"
								}
								Else {
									Set tClause = tClause _ tSpec_"."_tValue_".%NOT"
								}
							}
							Else {
								If ($$$UPPER(tValue)=tNullRef) {
									Set tClause = tClause _ "EXCEPT("_tSpec_".Members,"_tDim_"."_tNullRef_")"
								}
								Else {
									Set tClause = tClause _ "EXCEPT("_tSpec_".Members,"_tSpec_"."_tValue_")"
								}
							}

						}
					}
					ElseIf ($E(tValue,1)="{") {
						// split value
						Set tValue = $E(tValue,2,$L(tValue)-1)

						Set tKeySet = ""
						Set tLength=$L(tValue,"],&[") ; JSL4424
						For x = 1:1:tLength {
							// v is not quite the original key because the $P strips off &[ unless first key and ] unless last key
							Set v = $P(tValue,"],&[",x)
							;Set:($E(v)="&")&&($L(tValue,"],&[")'=x) v = v_"]" // JSL4424, tenative solution
							Set:$E(v)'="&" v = "&["_v ; the code in the $PIECE strips off "&[" of the next element and here we add it back on - JSL
							;Set:$E(v,$L(v))'="]" v = v_"]" comment out this line of Joe's code JSL4424
							Set:tLength'=x v=v_"]" ; $PIECE stripped it off, this puts it back on JSL4424
							If ($$$UPPER(v)=tNullRef) {
								Set tKeySet = tKeySet _ $S(tKeySet="":"",1:",") _ tDim_"."_tNullRef
							}
							Else {
								Set tKeySet = tKeySet _ $S(tKeySet="":"",1:",") _ tSpec_"."_v
							}
						}
						Set tKeySet = "{"_tKeySet_"}"
						If ('tIsNot) {
							If (tUseOR) {
								Set tClause = tClause _ "%OR("_tKeySet_")"
							}
							Else {
								Set tClause = tClause _ tKeySet
							}
						}
						Else {
							// + WAL034
							Set tNotSet = $E(tKeySet,2,*-1)
							//APV022 - Delimitting by '],' instead of by ',' to account for commas in member names. Assumption: No member name contains the string "],"
							For i=1:1:$L(tNotSet,"],") {
								Set tClause = tClause _ $s(i=1:"(",1:",") _ $p(tNotSet,"],",i) 
								If (i=$L(tNotSet,"],")){
									Set tClause = tClause _ ".%NOT"
								}
								Else{
									Set tClause = tClause _ "].%NOT"
								}
							}
							Set tClause = tClause _ ")"
							// - WAL034
						}
					}
					Else {
						// tValue is one or more KEY values for the current level
						// JMD951 -- these should be ANDed not ORed
						Set p = $L(tValue,"~~")
						If (p = 1) {
							Set tClause = tClause _ tSpec_".&["_$$$dsEscapeIdent(tValue)_"]"
						}
						Else {
							Set tClause = tClause _ "("
							For vp = 1:1:p {
								Set t = $P(tValue,"~~",vp)
								Set tClause = tClause _ $S(vp>1:",",1:"") _ tSpec_".&["_$$$dsEscapeIdent(t)_"]"
							}
							Set tClause = tClause _ ")"
						}
					}
				}
				Else {
					Set tClause = tClause _ tSpec_$S(tIsMsr:"",1:".["_tValue_"]")
				}
			}
			Set n = $O(pFilterInfo(n))
		}
	}

	If (tParenCount > 0) {
		// close parens
		Set tClause = tClause _ $TR($J(")",tParenCount)," ",")")
	}
	Quit tClause
}

/// Convert an array of pivot levels into an MDX axis clause
/// that will serve as part of the query executed for the pivot.
Method %GetAxisClauseFromLevels(pLevels As %AbstractList, pShowEmpty As %Boolean = 0, Output pComplexQuery As %Boolean, pDrillLevel As %Integer = "", pMaxItems As %Integer = "", pShowAll As %Boolean = 0) As %String [ Internal ]
{
	Set tClause = ""
	Set tItemCount = pLevels.Count()
	Set tHasJOIN = 0
	Set pComplexQuery = 0

	Set tCount = 0
	For n = 1:1:tItemCount {
		Set tLevel = pLevels.GetAt(n)
		If ((pDrillLevel'="")&&(tLevel.drillLevel'=pDrillLevel)) {
			Continue
		}
		Set tCount = tCount + 1

		If (tLevel.levelType = "space") {
			Set tSpec = "%SPACE()"
		}
		ElseIf (tLevel.levelType = "value") {
			Set tSpec = tLevel.value
		}
		ElseIf (tLevel.levelType = "mdx") {
			// JMD1276: check for pivot variable
			If ($$$LOWER($E(tLevel.value,1,10))="$variable.") {
				Set tVarName = $E(tLevel.value,11,*)
				// only use if context is expression
				Kill tVInfo
				Do ##class(%DeepSee.Utils).%GetPivotVariableInfo(..cubeName,tVarName,.tVInfo)
				If ($G(tVInfo("context"))="expression") {
					Set tSpec = tLevel.value
				}
				Else {
					Set tSpec = ""
				}
			}
			Else {
				Set tSpec = tLevel.value
			}
		}
		Else {
			// value, text, spec
			Set tSpec = tLevel.spec

			// apply SET functions, if any
			If (tLevel.filterEnabled) {
				Set tSpec = "FILTER(" _ tSpec
				Set tExpr = tLevel.filterExpression
				Set:tExpr="" tExpr = "1"

				Set tSpec = tSpec _ "," _ tExpr
				Set tSpec = tSpec _ ")"
			}

			If (tLevel.orderEnabled) {
				Set tSpec = "ORDER(" _ tSpec
				Set tExpr = tLevel.orderExpression
				Set tCountName = ##class(%DeepSee.Utils).%GetCountName(..cubeName,.tSC)
				Set:tExpr="" tExpr = "MEASURES.["_$S(tCountName="":"%COUNT",1:tCountName)_"]"

				Set tDirection = tLevel.orderDirection
				Set:tDirection="" tDirection = "BDESC"

				Set tSpec = tSpec _ "," _ tExpr
				Set tSpec = tSpec _ "," _ tDirection
				Set tSpec = tSpec _ ")"
			}
			If (tLevel.headEnabled) {
				Set tSpec = "HEAD(" _ tSpec
				Set:((+tLevel.headCount)>1) tSpec = tSpec _ "," _ tLevel.headCount
				Set tSpec = tSpec _ ")"
			}
			If (($P($$$UPPER(tLevel.spec),".",1)="[MEASURES]")&&(tLevel.aggFunction'="")) {
				// apply aggregate to measure
				Set tSpec = tSpec _ "." _ tLevel.aggFunction
			}
			
			// DTB268 - Check for shared items. Strip any %SHAREDx token if present
			If $$$UPPER(tLevel.spec["%SHARED") {
				// DTB715 - Snip the %SHARED token from the spec
				Set tSpecAsList = $ListFromString(tLevel.spec,".")
				For n = 1:1:$LL(tSpecAsList) {
					If $$$UPPER($LG(tSpecAsList,n)["%SHARED") {
						Set tSpecAsList = $LI(tSpecAsList,1,n-1)_$LI(tSpecAsList,n+1,*)
					}
				}
				Set tSpec = $ListToString(tSpecAsList,".")
			}
		}

		If (tLevel.childLevels.Count() > 0) {
			Set tSubClause = ..%GetAxisClauseFromLevels(tLevel.childLevels,pShowEmpty,.tComplexQuery,,,pShowAll)		// DTB835
			If (pShowEmpty) {
				Set tSpec = "CROSSJOIN("_tSpec_","_tSubClause_")"
			}
			Else {
				Set tSpec = "NONEMPTYCROSSJOIN("_tSpec_","_tSubClause_")"
			}
			Set pComplexQuery = 1
			Set tHasJOIN = 1
		}

		// JMD861 Apply aggregate *after* processing child levels
		If (tLevel.aggEnabled && (tLevel.aggFunction'="") && ($P($$$UPPER(tLevel.spec),".",1)'="[MEASURES]")) {
			If (($$$UPPER(tLevel.aggFunction)="PERCENTILE") && (tLevel.aggFunctionParm'="")) {
				// make sure 2nd argument is present!
				Set tSpec = tLevel.aggFunction _ "(" _ tSpec _ ",,"_tLevel.aggFunctionParm_")"
			}
			ElseIf (($$$UPPER(tLevel.aggFunction)="COUNT NONEMPTY")) {
				Set tSpec = "COUNT(" _ tSpec _ ",EXCLUDEEMPTY)"
			}
			Else {
				Set tSpec = tLevel.aggFunction _ "(" _ tSpec _ ")"
			}
		}

		// JMD861: tack on label after all else
		If ((tLevel.levelCaption'="")||(tLevel.levelFormat'="")||(tLevel.levelStyle'="")||(tLevel.levelHeaderStyle'="")||(tLevel.levelSummary'="")) {
			Set tSpec = "%LABEL(" _ tSpec _ ","_ $$$quote(tLevel.levelCaption) _ ","_ $$$quote(tLevel.levelFormat)
			// JMD: tack summary onto style
			Set tLevelStyle = tLevel.levelStyle
			Set:(tLevel.levelSummary'="") tLevelStyle = tLevelStyle_"summary:"_tLevel.levelSummary_";"
			Set:(tLevelStyle'="") tSpec = tSpec _ ",,"_ $$$quote(tLevelStyle)
			Set:(tLevel.levelHeaderStyle'="") tSpec = tSpec _ $S((tLevel.levelStyle=""):",,,",1:",")_ $$$quote(tLevel.levelHeaderStyle)
			Set tSpec = tSpec _ ")"
		}


		Set tClause = tClause _ $S(tCount>1:",",1:"") _ tSpec
	}

	If (tCount>1) {
		Set tClause = "{" _ tClause _ "}"
	}
	
	// JMD1129
	// DTB701 - Consider previewMode setting
	// DTB835 - Add override to include all results in exports
	If 'pShowAll && ((tHasJOIN && +pMaxItems)||..previewMode) {
		Set ..headFunctionAdded = 1		// DTB201 - Track the addition of the HEAD function
		Set tClause = "HEAD("_tClause_","_$S(..previewMode:..previewRowCount,1:pMaxItems)_",SAMPLE)"		// DTB326 - Use flag for fast results		// DTB - Change to 25
	}
	Else {
		Set ..headFunctionAdded = 0
	}

	Quit tClause
}

/// Convert array of levels (from <var>pStart</var>) into a parse tree
/// that can be handed to a query.
Method ProcessLevels(pList As %AbstractList, pStart As %Integer, ByRef pTree, pParent As %Integer) [ Internal ]
{
	#; either make a set of the first item
	#; or make it a set and join it with the next item
	If (pStart = pList.Count()) {
		#; last item: set
		Set tName = pList.GetAt(pStart).spec
		Set pTree(pTree) = $LB("set")
		Set pTree(pParent,"ch",pTree) = ""
		Set pTree(pTree,"ch",$I(pTree)) = ""
		Set pTree(pTree) = $LB("dim",tName)
	}
	Else {
		#; join
		Set pTree(pTree) = $LB("join")
		Set pTree(pParent,"ch",pTree) = ""
		Set tJoinParent = pTree
		Set x = $I(pTree)

		#; make set for this item
		Set tName = pList.GetAt(pStart).spec
		Set pTree(pTree) = $LB("set")
		Set pTree(tJoinParent,"ch",pTree) = ""
		Set pTree(pTree,"ch",$I(pTree)) = ""
		Set pTree(pTree) = $LB("dim",tName)
		Set x = $I(pTree)

		#; join in rest of list
		Do ..ProcessLevels(pList,pStart+1,.pTree, tJoinParent)
	}
}

/// Mouse down within a cell.
/// Try to prevent text select when selecting multiple cells.
ClientMethod cellMouseDownHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.shiftKey && evt.preventDefault) {
		evt.preventDefault();
	}
	return true;
}

/// Notification that a cell is clicked.<br/>
/// <var>row</var> and <var>col</var> give the ordinal (logical) position of the cell.
ClientMethod cellClickHandler(evt, row, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.shiftKey && '' != this.selectedRange) {
		// expand range
		var p = this.selectedRange.split(',');
		p[0] = (row < p[0]) ? row : p[0];
		p[1] = (col < p[1]) ? col : p[1];
		p[2] = (row > p[2]) ? row : p[2];
		p[3] = (col > p[3]) ? col : p[3];
		this.selectCellRange(p[0],p[1],p[2],p[3],false,false);
	}
	else {
		this.selectCellRange(row,col,row,col,false,false);
	}
	this.updateToolbar();
	zenInvokeCallbackMethod(this.oncellClick,this,'oncellClick','pivot',this);
	return true;
}

/// Notification that a cell is double-clicked.<br/>
/// <var>row</var> and <var>col</var> give the ordinal position of the cell.
ClientMethod cellDblClickHandler(evt, row, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	zenInvokeCallbackMethod(this.oncellDblClick,this,'oncellDblClick','pivot',this);
	return true;
}

/// Notification that a column header is clicked.<br/>
ClientMethod columnClickHandler(evt, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.shiftKey && '' != this.selectedRange) {
		return this.cellClickHandler(evt,1,col);
	}
	this.selectCellRange(1,col,this.rowCount,col,true,false);
	zenInvokeCallbackMethod(this.oncellClick,this,'oncellClick','pivot',this);
	this.updateToolbar();
	return true;
}

/// Notification that a column header is double-clicked.<br/>
ClientMethod columnDblClickHandler(evt, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	// sort by column
	if (col != this.sortColumn) {
		this.sortColumn = col;
		this.sortDir = 'ASC';
	}
	else if ('ASC'==this.sortDir) {
		this.sortDir = 'DESC';
	}
	else {
		this.sortColumn = 0;
		this.sortDir = 'ASC';
	}
	this.selectedRange = '';

	// JMD1462
	this.showMessage($$$Text('sorting...'),'',true);
	this.deferredExecuteQuery(true);
	return true;
}

/// Notification that a listing header is double-clicked.<br/>
ClientMethod listingHeaderDblClickHandler(evt, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	// sort by column
	if (col != this.listingSortColumn) {
		this.listingSortColumn = col;
		this.listingSortDir = 'ASC';
	}
	else if ('ASC'==this.listingSortDir) {
		this.listingSortDir = 'DESC';
	}
	else {
		this.listingSortColumn = 0;
		this.listingSortDir = 'ASC';
	}
	// JMD1331 reset paging
	this.currListingPage = -1;
	this.showMessage($$$Text('sorting...'),'',true);
	this.deferredExecuteQuery(true);
	return true;
}

/// Notification that a row header is clicked.<br/>
ClientMethod rowClickHandler(evt, row) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.shiftKey && '' != this.selectedRange) {
		return this.cellClickHandler(evt,row,1);
	}
	this.selectCellRange(row,1,row,this.columnCount,false,true);
	zenInvokeCallbackMethod(this.oncellClick,this,'oncellClick','pivot',this);
	this.updateToolbar();
	return true;
}

/// Notification that a row header is double clicked.<br/>
ClientMethod rowDblClickHandler(evt, level, row) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (level == 1 && this.canDrillDown) {
		// only worry about lowest level

		// get spec for this item
		var itemInfo = new zenProxy();
		var ok = this.GetItemSpec(itemInfo,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,'row',row,1); // WAL088 - note that itemno is already sorted
		if (!ok) {
			if (itemInfo.error) {
				alert(itemInfo.error);
			}
			return;
		}

		// JMD1311: see if there is a drilldownSpec for this item
		var drilldownSpec = itemInfo.childSpec;
		var dspec = this.rowAxisOptions.drilldownSpec;
		if (dspec) {
			if (dspec == 'none') {
				// no drill down
				return;
			}
			else {
				var t = dspec.toString().split('^');
				drilldownSpec = t[this.getDrillLevel()];
				drilldownSpec = drilldownSpec ? drilldownSpec : '';
			}
		}

		if (drilldownSpec == '' || drilldownSpec == 'none') {
			return;
		}

		this.pushState();

		// JMD1445: clear override for drill down
		// DTB745 - Keep the override in place. It will only be applied to the base level.
		//this.overrideRowSpec = '';
		//this.overrideRowText = '';

		// add a drill level
		if (itemInfo.spec != '') {
			var drill = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
			drill.spec = itemInfo.spec;
			drill.text = itemInfo.text;
			this.drillLevels[this.drillLevels.length] = drill;
			
			// WAL224 -- remember which row should be selected after returning from drill down
			this.drillRowNumbers[this.drillRowNumbers.length] = row;
		}

		// add a new row level
		var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
		parm.spec = drilldownSpec;
		parm.text = itemInfo.text;
		parm.drillLevel = this.getDrillLevel();
		this.rowLevels[this.rowLevels.length] = parm;

		this.sortColumn = 0;
		this.sortDir = 'ASC';
		this.selectedRange = '';
		var ret = zenInvokeCallbackMethod(this.ondrill,this,'ondrill','pivot',this);
		if (!ret) {
			this.executeQuery(this.autoExecute);
		}
	}
	return true;
}

/// Set the selected cell range. Addresses are 1-based.<br/>
ClientMethod selectCellRange(startRow, startCol, endRow, endCol, allRows, allCols, selectOnly) [ Language = javascript ]
{
	allRows = 'undefined' == typeof allRows ? false : allRows;
	allCols = 'undefined' == typeof allCols ? false : allCols;
	selectOnly = 'undefined' == typeof selectOnly ? false : selectOnly;

	// unselect current range
	if (!selectOnly && ('' != this.selectedRange)) {
		var p = this.selectedRange.split(',');
		for (var r = parseInt(p[0]); r <= parseInt(p[2]); r++) {
			for (var c = parseInt(p[1]); c <= parseInt(p[3]); c++) {
				var cell = this.findElement('cell_'+r+'_'+c);
				if (cell) {
					var color = cell._oldColor ? cell._oldColor : '';
					cell.style.color = color;
					cell._oldcolor = null;		// PFS018
					var bg = cell._oldBackground ? cell._oldBackground : '';
					cell.style.background = bg;
					cell._oldBackground = null;		// PFS018
				}
			}
		}
	}

	var total = 0;
	var cellCount = 0;

	if ('' == startRow) {
		this.selectedRange = '';
	}
	else {
		this.selectedRange = startRow + ',' + startCol + ',' + endRow + ',' + endCol + ',' + (allRows?1:0) + ',' + (allCols?1:0);
		var p = this.selectedRange.split(',');
		for (var r = parseInt(p[0]); r <= parseInt(p[2]); r++) {
			for (var c = parseInt(p[1]); c <= parseInt(p[3]); c++) {
				var cell = this.findElement('cell_'+r+'_'+c);
				if (cell) {
					cellCount++;
					if (cell.getAttribute && cell.getAttribute('zenValue')) {
						total += parseFloat(cell.getAttribute('zenValue'));
					}
					// PFS018 - Store old values if they are null, which means this cell is not currently selected
					if (cell._oldColor == null) {
						cell._oldColor = cell.style.color ? cell.style.color : '';
					}
					if (cell._oldBackground == null) {
						cell._oldBackground = cell.style.background ? cell.style.background : '';
					}
					cell.style.color = this.selectedCellColor;
					cell.style.background = this.selectedCellBackground;
				}
			}
		}
	}

	// update status area
	var format = ('number'!=typeof total) ? '' : (total == parseInt(total,10)) ?  '#,#' : '#,#.##';
	if (isNaN(parseInt(total,10))) {
		this.totalValue = '';
	}
	else {
		this.totalValue = zenFormatNumber(total,format);
	}
	this.cellCount = zenFormatNumber(cellCount,'#,#');
	var span = this.findElement('total');
	if (span) {
		span.innerHTML = this.totalValue;
	}
	var span = this.findElement('cellCount');
	if (span) {
		span.innerHTML = this.cellCount;
	}
}

/// For multi-page display, calculate the number of pages.
ClientMethod getPageCount() [ Language = javascript ]
{
	var rc = parseInt(this.rowCount,10);
	if (!isNaN(rc) && rc > 0 && this.pageSize > 0) {
		return Math.floor(rc / this.pageSize) + ((rc % this.pageSize) ? 1 : 0);
	}
	return 1;
}

/// For multi-page listing display, calculate the number of pages.
ClientMethod getListingPageCount() [ Language = javascript ]
{
	var rc = parseInt(this.listingRowCount,10);
	if (!isNaN(rc) && rc > 0 && this.listingPageSize > 0) {
		return Math.floor(rc / this.listingPageSize) + ((rc % this.listingPageSize) ? 1 : 0);
	}
	return 1;
}

/// For multi-page display, go to previous page, if possible.
ClientMethod previousPage() [ Language = javascript ]
{
	if (this.isDrillThrough) {
		if (this.currListingPage > 1) {
			this.currListingPage--;
			this.isPaging = true;
			this.showMessage($$$Text('working...'),'',true);
			this.deferredExecuteQuery();
		}
	}
	else {
		if (this.currPage > 1) {
			this.currPage--;
			this.isPaging = true;
			this.executeQuery();
		}
	}
}

/// For multi-page display, go to next page, if possible.
ClientMethod nextPage() [ Language = javascript ]
{
	if (this.isDrillThrough) {
		if (this.currListingPage < this.getListingPageCount()) {
			this.currListingPage++;
			this.isPaging = true;
			this.showMessage($$$Text('working...'),'',true);
			this.deferredExecuteQuery();
		}
	}
	else {
		if (this.currPage < this.getPageCount()) {
			this.currPage++;
			this.isPaging = true;
			this.executeQuery();
		}
	}
}

/// For multi-page display, go to the first page.
ClientMethod firstPage() [ Language = javascript ]
{
	if (this.isDrillThrough) {
		if (1 != this.currListingPage) {
			this.currListingPage = 1;
			this.isPaging = true;
			this.showMessage($$$Text('working...'),'',true);
			this.deferredExecuteQuery();
		}
	}
	else {
		if (1 != this.currPage) {
			this.currPage = 1;
			this.isPaging = true;
			this.executeQuery();
		}
	}
}

/// For multi-page display, go to the last page.
ClientMethod lastPage() [ Language = javascript ]
{
	if (this.isDrillThrough) {
		if (this.getListingPageCount() != this.currListingPage) {
			this.currListingPage = this.getListingPageCount();
			this.isPaging = true;
			this.showMessage($$$Text('working...'),'',true);
			this.deferredExecuteQuery();
		}
	}
	else {
		if (this.getPageCount() != this.currPage) {
			this.currPage = this.getPageCount();
			this.isPaging = true;
			this.executeQuery();
		}
	}
}

/// For multi-page display, go to specified page (1 is first page), if possible.
ClientMethod gotoPage(page) [ Language = javascript ]
{
	page = parseInt(page);
	if (page >= 1 && page != this.currPage && page <= this.getPageCount()) {
		this.currPage = page;
		this.isPaging = true;
		this.executeQuery();
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'showStatus':
	case 'pivot':
	case 'rowTotals':
	case 'columnTotals':
	case 'showEmptyRows':
	case 'showEmptyColumns':
	case 'rowLabelSpan':
	case 'columnLabelSpan':
		value = value ? true : false;
		if (this[property] != value) {
			this[property] = value;
			this.executeQuery();
		}
		break;

	case 'currPage':
		// alternate API for going to a page (within this table)
		this.gotoPage(value);
		break;

	case 'pageSize':
		if (value != this.pageSize) {
			this.currPage = 1; // go back to start
			this.selectedRange = '';
			this.pageSize = value;
			this.executeQuery();
		}
		break;

	case 'colorScale':
		if (value != this.colorScale) {
			this.selectedRange = '';
			this.colorScale = value;
			this.executeQuery();
		}
		break;

	case 'rowTotalSource':
	case 'showZebra':
	case 'showRowCaption':
	case 'evenRowStyle':
	case 'cellStyle':
	case 'columnHeaderStyle':
	case 'rowHeaderStyle':
	case 'rowTotalAgg':
	case 'columnTotalAgg':
	case 'cellWidth':
	case 'cellHeight':
	case 'backgroundImage':
	case 'backgroundOpacity':
		if (this[property] != value) {
			this[property] = value;
			this.executeQuery();
		}
		break;

	case 'text':
	case 'value':
		// readonly
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Built-in drag handler for pivot table component.
/// Let the user drag the selected node.
ClientMethod dragStartHandler(dragData) [ Language = javascript ]
{
	var ok = false;

	// drag item is type:#
	var dragItem = this._dragSource;

	if (null != dragItem) {
		dragData.sourceItem = dragItem;
		delete this._dragSource;

		var t = dragItem.split(':');
		var n = t[1] - 1;
		var tgtType = t[0];

		switch(tgtType) {
		case 'rowLevel':
			if (this.rowLevels[n]) {
				ok = true;
				dragData.value = this.rowLevels[n].spec;
				dragData.text = this.rowLevels[n].text;
			}
			break;
		case 'colLevel':
			if (this.columnLevels[n]) {
				ok = true;
				dragData.value = this.columnLevels[n].spec;
				dragData.text = this.columnLevels[n].text;
			}
			break;
		case 'row':
		case 'col':
			break;
		case 'filter':
			if (this.filters[n]) {
				ok = true;
				dragData.value = this.filters[n].spec;
				dragData.text = this.filters[n].text;
			}
			break;	
		case 'measure':
			if (this.measures[0]) {
				ok = true;
				dragData.value = this.measures[0].spec;
				dragData.text = this.measures[0].text;
			}
			break;	
		}

		if (ok) {
			ZLM.setDragCaption(dragData.text);
		}
	}

	return ok;
}

/// Used to provide label related info when required.
ClientMethod callGetItemSpec(labelInfo, rowItem, columnItem) [ Language = javascript ]
{
	// get spec for this item
	var itemInfoRow = new zenProxy();
	var ok = this.GetItemSpec(itemInfoRow,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,'row',rowItem,0);
	
	var itemInfoCol = new zenProxy();
	var ok = this.GetItemSpec(itemInfoCol,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,'col',columnItem,0);
	
	// Replace %Search -- should only appear on rows
	labelInfo.rowCaption = itemInfoRow.tooltipText=='%Search' ? $$$Text('Series') : itemInfoRow.tooltipText;
	labelInfo.colCaption = itemInfoCol.tooltipText=='%Search' ? $$$Text('Series') : itemInfoCol.tooltipText;

	if (itemInfoRow.measure != '') {
		labelInfo.measure = itemInfoRow.measure;
	}
	else if (itemInfoCol.measure != '') {
		labelInfo.measure = itemInfoCol.measure;
	}
	else {
		labelInfo.measure = $$$Text("Value");	
	}
}

/// Used to provide label related info when required.
ClientMethod callFormatValue(value, formattedValue, rowItem, columnItem) [ Language = javascript ]
{
	var ok = this.FormatValue(this.cubeName, this.queryKey, value, formattedValue, rowItem, columnItem);
}

ClientMethod removeMeasureLabels(values, measureCaption) [ Language = javascript ]
{
	if (values && measureCaption) {
		for (i=1; i < values.length; ++i) {
			var valueText = values[i].toString().split('/');		// DP-416572 - values[i] could be a numeric!
			for (var j = 0; j < valueText.length; ++j) {
				if (this.hiddenMeasureText.length>=1) {
					for (var k = 0; k < this.hiddenMeasureText.length; ++k) {
						if (valueText[j] == this.hiddenMeasureText[k]) {
							valueText.splice(j,1);	
							break;
						}
					}
				}
				else if (valueText[j] == measureCaption) {
					valueText.splice(j,1);	
					break;	
				}
			}
			values[i] = valueText.join('/');	
		}
	}
	return values;
}

/// Drop handler. This is called when an item is dropped onto the table.
ClientMethod dropStartHandler(dragData) [ Language = javascript ]
{
	var value = dragData.value;
	var text = dragData.text;

	var tgtId = ZLM.getDragInnerDestination().id;
	if ('' == tgtId) {
		tgtId = ZLM.getDragInnerDestination().parentNode.id;
	}
	var tgtIndex = -1;
	var tgtType = '';
	var grpIndex = -1;

	if (tgtId) {
		if (tgtId.indexOf('rowdim_')!=-1) {
			tgtType = 'rowLevel';
			grpIndex = tgtId.split('_')[1];
			tgtIndex = tgtId.split('_')[2];
		}
		else if (tgtId.indexOf('coldim_')!=-1) {
			tgtType = 'colLevel';
			grpIndex = tgtId.split('_')[1];
			tgtIndex = tgtId.split('_')[2];
		}
		else if (tgtId.indexOf('row')!=-1) {
			tgtType = 'row';
			grpIndex = tgtId.split('_')[1];
			tgtIndex = tgtId.split('_')[2];
		}
		else if (tgtId.indexOf('col')!=-1) {
			tgtType = 'col';
			grpIndex = tgtId.split('_')[1];
			tgtIndex = tgtId.split('_')[2];
		}
		else if (tgtId.indexOf('filters')!=-1) {
			tgtType = 'filter';
		}
		else if (tgtId.indexOf('measure')!=-1) {
			tgtType = 'measure';
		}
		else if (tgtId.indexOf('filter_')!=-1) {
			tgtType = 'filter';
			tgtIndex = tgtId.split('_')[1];
		}
	}
	else if ('' == tgtId) {
		tgtType = 'rowLevel'; // we don't get an id for the nub!!!
	}
	dragData.targetItem = tgtIndex;

	// find dimension name
	var s = value.toString().split('.');
	var dimName = s[0] ? s[0].toUpperCase() : '';

	var changed = false;
	switch(tgtType) {
	case 'row':
		// drill into this item
		var t = grpIndex.toString().split(':');
		var levelno = t[0];
		var itemno = t[1];

		if (levelno > 1) {
			// drill down only works on lowest level
			break;
		}

		// WAL -- keep in mind that this is looking for a th, but we might need
		//           a different kind of element
		//           THEN AGAIN this might just seamlessly work since th is just a name
		// get unsorted item number
		var th = ZLM.getDragInnerDestination().parentNode;
		if (th && th.getAttribute('rowNo')) {
			itemno = th.getAttribute('rowNo');
		}

		// get spec for this item
		var itemInfo = new zenProxy();
		var ok = this.GetItemSpec(itemInfo,this.cubeName,this.queryKey,this.sortDir,this.sortColumn,tgtType,itemno,1);  // WAL088 - note that itemno is already sorted

		if (!ok) {
			if (itemInfo.error) {
				alert(itemInfo.error);
			}
			return;
		}

		this.pushState();

		// add a drill level
		if (itemInfo.spec != '') {
			var drill = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
			drill.spec = itemInfo.spec;
			drill.text = itemInfo.text;
			this.drillLevels[this.drillLevels.length] = drill;
			
			// WAL224 -- remember which row should be selected after returning from drill down
			this.drillRowNumbers[this.drillRowNumbers.length] = itemno;
		}

		// add a new row level
		var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
		parm.spec = value;
		parm.text = text;
		parm.drillLevel = this.getDrillLevel();
		this.rowLevels[this.rowLevels.length] = parm;
		var ret = zenInvokeCallbackMethod(this.ondrill,this,'ondrill','pivot',this);
		if (!ret) {
			changed = true;
		}
		else {
			changed = false;
		}
		break;
	case 'col':
		break;
	case 'measure':
		if ((dimName == '[MEASURES]')||(dimName == 'MEASURES')) {
			this.pushState();
			if (this.measures[0]) {
				this.measures[0].spec = value;
				this.measures[0].text = text;
			}
			else {
				// create
				var msr = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				msr.spec = value;
				msr.text = text;
				this.measures[0] = msr;
			}
			changed = true;
		}
		break;
	case 'rowLevel':
		this.pushState();
		if (tgtIndex > 0 && this.rowLevels[tgtIndex-1]) {
			this.rowLevels[tgtIndex-1].spec = value;
			this.rowLevels[tgtIndex-1].text = text;
		}
		else {
			// append
			var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
			parm.spec = value;
			parm.text = text;
			this.rowLevels[this.rowLevels.length] = parm;
		}
		changed = true;
		break;
	case 'colLevel':
		this.pushState();
		if (tgtIndex > 0 && this.columnLevels[tgtIndex-1]) {
			this.columnLevels[tgtIndex-1].spec = value;
			this.columnLevels[tgtIndex-1].text = text;
		}
		else {
			// append
			var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
			parm.spec = value;
			parm.text = text;
			this.columnLevels[this.columnLevels.length] = parm;
		}
		changed = true;
		break;
	case 'filter':
		if ((dimName != '[MEASURES]')&&(dimName != 'MEASURES')) {
			this.pushState();
			if (tgtIndex > 0 && this.filters[tgtIndex-1]) {
				this.filters[tgtIndex-1].spec = value;
				this.filters[tgtIndex-1].text = text;
				this.filters[tgtIndex-1].value = '';
				this.filters[tgtIndex-1].key = '';
			}
			else {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				parm.spec = value;
				parm.text = text;
				this.filters[this.filters.length] = parm;
			}
			changed = true;
		}
		break;

	default:
		break;
	}

	if (changed) {
		this.sortColumn = 0;
		this.sortDir = 'ASC';
		this.selectedRange = '';
		this.executeQuery(this.autoExecute);
	}
	return true;
}

/// This is called when a drag operation started within this component is completed.<br/>
ClientMethod dragFinishHandler(dragData) [ Language = javascript ]
{
	// remove the dragged item
	// find what was dragged
	var srcId = ZLM.getDragInnerSource().id;
	var srcIndex = -1;
	var srcType = '';
	if (srcId) {
		if (srcId.indexOf('rowdim_')!=-1) {
			srcType = 'rowLevel';
			srcIndex = srcId.split('_')[2];
		}
		else if (srcId.indexOf('coldim_')!=-1) {
			srcType = 'colLevel';
			srcIndex = srcId.split('_')[2];
		}
		else if (srcId.indexOf('row')!=-1) {
			srcType = 'row';
		}
		else if (srcId.indexOf('col')!=-1) {
			srcType = 'col';
		}
		else if (srcId.indexOf('filters')!=-1) {
			srcType = 'filter';
		}
		else if (srcId.indexOf('measure')!=-1) {
			srcType = 'measure';
		}
		else if (srcId.indexOf('filter_')!=-1) {
			srcType = 'filter';
			srcIndex = srcId.split('_')[1];
		}
	}
	else if ('' == srcId) {
		srcType = 'rowLevel'; // !!! we don't get an id for the nub!!!
	}

	var changed = false;
	switch(srcType) {
	case 'rowLevel':
		if (srcIndex > 0 && this.rowLevels[srcIndex-1]) {
			this.pushState();
			changed = true;
			this.rowLevels.splice(srcIndex-1,1);
		}
		break;
	case 'colLevel':
		if (srcIndex > 0 && this.columnLevels[srcIndex-1]) {
			this.pushState();
			changed = true;
			this.columnLevels.splice(srcIndex-1,1);
		}
		break;
	case 'filter':
		if (srcIndex > 0 && this.filters[srcIndex-1]) {
			this.pushState();
			changed = true;
			this.filters.splice(srcIndex-1,1);
		}
		break;
	case 'measure':
		if (this.measures) {
			this.pushState();
			changed = true;
			this.measures = new Array();
		}
		break;
	default:
		break;
	}
	if (changed) {
		this.executeQuery(this.autoExecute);
	}
}

/// Hide the message box.
ClientMethod hideMessage() [ Language = javascript ]
{
	// JMD1462
	self.document.body.style.cursor = 'auto';
	if (!this.isDrillThrough && this.controller && this.controller.hideMessage) {
		// dispatch
		this.controller.hideMessage();
		return;
	}

	var div = this.findElement('message');
	if (div) {
		// PFS092 - Remove innerHTML so printing to PDF does not pick this up
		div.innerHTML = '';
		div.style.display = 'none';
	}
}

/// Show (or hide) the "computing..." message.
ClientMethod showPendingMsg(flag, msg) [ Language = javascript ]
{
	var div = this.findElement('pending');
	if (div) {
		if (flag) {
			div.style.display = 'block';
		}
		else {
			div.style.display = 'none';
		}
	}
}

/// Display the message box. This message will store the incoming <var>msg</var> for use as the message default for subsequent calls.</br>
/// If a controller with its own showMessage is present for this pivotTable, dispatch the message display to that method.
ClientMethod showMessage(msg, pct, listing) [ Language = javascript ]
{
	// JMD1462
	self.document.body.style.cursor = 'wait';

	// DP-408943 - If the progressMessage is established use that as the default for this refresh
	// of the message display. Any message passed in is displayed and resets the current progressMessage
	// as the new default.
	if (!msg) {
		msg = this.progressMessage;
	}
	else {
		this.progressMessage = (msg = $$$Text(msg));
	}

	var units = '%';
	if (this.queryStatus < 30) {
		units = $$$Text(' items');
	}
	else if (this.queryStatus >= 50) {
		// Tasks have completed, query is in consolidation phase
		pct = 100;
	}
	
	if (!this.isDrillThrough && this.controller && this.controller.showMessage) {
		// dispatch
		this.controller.showMessage(this,msg,pct,listing,units);
		return;
	}

	var div = this.findElement('message');
	if (div) {
		var html = '';
		var icon = "deepsee/insert_table_clock_64.png";

		html += '<table><tr><td width="80" valign="middle" align="center">';
		html += '<img src="'+icon+'"/><br/><br/>';
		html += '</td><td width="200" valign="top">';
		
		if (listing) {
			// listing message
			html += '<div><i>' + msg + '</i></div>';
		}
		else {
			// DP-408943 - Round for easy readability of changing numbers.
			// Replace NaN, undefined, '', etc with 0.  
			pct = !pct ? '0' : parseInt(pct,10);

			if (!isNaN(this.queryStatus) && this.queryStatus >= 50 && this.queryStatus < 100) {
				icon = "deepsee/insert_table_fav_64.png";
			}
			else if (!isNaN(this.queryStatus) && this.queryStatus < 35) {
				icon = "deepsee/insert_table_64.png";
			}

			html += '<div><i>' + msg + '</i></div>';
			html += '<div class="dsptPct">' + pct + '<span style="font-size:0.8em;">'+units+'</span></div>';
			html += '<div style="font-size:0.8em; color: darkblue;"><i>' + $$$Text('Cells Calculated') + '</i></div>';
			var pos = (this.queryCalls % 10) * 10;
			html += '<div style="width:100px;border-top:1px solid darkblue;"><div style="border:1px solid black; background: darkblue; color:darkblue; font-size: 8pt; width:10px; left:'+pos+'px;position:relative;">X</div></div>';
		}
		html += '</td>';
		html += '</tr></table>';

		div.innerHTML = html;
		div.style.display = 'block';
	}
}

/// Mouse down handler for nodes.
ClientMethod itemMouseDown(evt, idx) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		this._dragSource = idx;
	}
}

/// Mouse up handler for nodes.
ClientMethod itemMouseUp(evt) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		delete this._dragSource;
	}
}

ClientMethod absoluteAdjustLayout() [ Language = javascript ]
{
	// Added by WAL
	try {
		// divs
		var enc = this.getEnclosingDiv();
		var outer = this.findElement('outerDiv');
		var singleTable = this.findElement('dsPivotCompleteTable');
		var singleTableDiv = this.findElement('dsPivotCompleteTableDiv');
		
		var vtScroll = this.findElement('vtScroll');
		var hzScroll = this.findElement('hzScroll');
		var vtScrollInner = this.findElement('vtScrollInner');
		var hzScrollInner = this.findElement('hzScrollInner');
		var errorDiv = this.findElement('errorDiv');
		var	status = this.findElement('statusDiv');
		
		var dataTable = this.findElement('dataTable'); 
		var dataTableDiv = this.findElement('dataTableDiv');
		var sideTable = this.findElement('sideTable');
		var topTable = this.findElement('topTable');
		var nubTable = this.findElement('nubTable');

		var adjustArray=[];
		
		// Loop through top table, use old table to assign sizes
		var topHeights=[];
		var topWidths=[];
		var topOffsets = undefined;		// DTB842 - Offsets will be initialized on the first pass of the loop
		var multipleRows=0;
		var maxRow=0;
		var childOffsetWidth="";
		var childOffsetHeight="";
		var parentOffsetWidth="";
		var parentOffsetHeight="";
		if (topTable) {		// DTB867 - Test for existence of the topTable
			for (var cell=0;cell<topTable.children.length;cell++) {
				var tempNew = topTable.children[cell];
				var tempOld = document.getElementById(tempNew.id.substring(3,tempNew.id.length));
				if ((tempNew) && (tempOld)) {
					if ((childOffsetHeight=="") && (childOffsetWidth=="")) {
						// PFS111 - Added outer div, so we need to go down 2 child levels
						var childOffsetStyle=window.getComputedStyle(tempOld.children[0].children[0]);
						childOffsetHeight=parseInt(childOffsetStyle.paddingTop)+parseInt(childOffsetStyle.paddingBottom);
						childOffsetWidth=parseInt(childOffsetStyle.paddingRight)+parseInt(childOffsetStyle.paddingLeft);
					}
					if ((parentOffsetHeight=="") && (parentOffsetWidth=="")) {
						var parentOffsetStyle=window.getComputedStyle(tempOld);
						parentOffsetHeight=parseInt(parentOffsetStyle.borderTopWidth)+parseInt(parentOffsetStyle.borderBottomWidth);
						parentOffsetWidth=parseInt(parentOffsetStyle.borderRightWidth)+parseInt(parentOffsetStyle.borderLeftWidth);
					}
					var idArray=tempOld.id.split("_");
					if (idArray[0]=="coltotal") {
						var colNum=101;
						var rowNum=maxRow;
						for (r=rowNum;r>=1;r--) {
							// DTB861 - Set for all rows of the offset table
							topOffsets[r][colNum] = topOffsets[r][topOffsets[r].length-1];		// DTB850 - Set the column total offset to be the final offset previously logged
						}
					} else {
						var colNum=parseInt(idArray[1].split(":")[1]);
						var rowNum=parseInt(idArray[1].split(":")[0]);
					}
					
					if (!(topOffsets)) {
						// DTB842 - Initialize the offset array. This replaces topWidths for setting
						// left position of each cell
						topOffsets = [];
						for (r=rowNum;r>=1;r--) {
							topOffsets[r] = [];
							topOffsets[r][colNum] = 0;
						}
					}
					
					var rect=tempOld.getBoundingClientRect()
					tempWidth=rect.width;
					tempHeight=rect.height;
					var tempAdjust={};
					tempAdjust.id=tempNew.id;
					tempAdjust.height=tempHeight-parentOffsetHeight;
					tempAdjust.width=tempWidth-parentOffsetWidth;
					tempAdjust.left=topOffsets[rowNum][colNum];		// DTB842 - Directly look up the offset for this cell
					tempAdjust.offsetHeight=childOffsetHeight;
					tempAdjust.offsetWidth=childOffsetWidth;
					adjustArray.push(tempAdjust);
					
					colSpan=tempOld.colSpan ? parseInt(tempOld.colSpan) : 1;
					rowSpan=tempOld.rowSpan ? parseInt(tempOld.rowSpan) : 1;
					multipleRows = rowNum>1 ? 1 : multipleRows;
					maxRow = rowNum>maxRow ? rowNum: maxRow;
					
					for (var r=rowNum;r>=1;r--) {
						// DTB842 - Fill in the current spanned offset for the next cell, for all rows below this one
						topOffsets[r][colNum+colSpan] = topOffsets[r][colNum] + tempWidth
					}
					
					// DTB842 - Leave topWidths and topHeights exactly as they were in case they get used later
					for (var r=rowNum;r>(rowNum-rowSpan);r--) {
						if (topWidths[r]) {
							topWidths[r]+=tempWidth;
						} else {
							topWidths[r]=tempWidth;
						}
					}
					
					for (var c=colNum;c<(colNum+colSpan);c++) {
						if (!topHeights[c]) {
							topHeights[c]=[];
						}
						topHeights[c][rowNum]=tempHeight;
					}
				}
			}
		}
		
		// Reverse for crossjoins 
		if (multipleRows) {
			var childrenLength=topTable.children.length;
			for (var cell=childrenLength-1;cell>=0;cell--) {
				var tempNew = topTable.children[cell];
				var tempOld = document.getElementById(tempNew.id.substring(3,tempNew.id.length));
				if ((tempNew) && (tempOld)) {
					var idArray=tempOld.id.split("_");
					if (idArray[0]=="coltotal") {
						var colNum=101;
						var rowNum=maxRow;
					} else {
						var colNum=parseInt(idArray[1].split(":")[1]);
						var rowNum=parseInt(idArray[1].split(":")[0]);
					}
					var tempHeight=0;
					for (var r=rowNum+1;r<topHeights[colNum].length;r++) {
						tempHeight+=topHeights[colNum][r];
					}
					
					adjustArray[adjustArray.length-(adjustArray.length-cell)].top=tempHeight;
				}
			}
		}
		
		// Loop through nub table, use old table to assign sizes
		// Nub table can ignore height calculations, top table will certainly be taller
		var totalLeft=0;
		if (nubTable) {		// DTB783 - Test for existence of the nubTable
			for (var cell=0;cell<nubTable.children[0].children.length;cell++) {
				var tempNew = nubTable.children[0].children[cell];
				var tempOld = document.getElementById(tempNew.id.substring(3,tempNew.id.length));
				if ((tempNew) && (tempOld)) {
					var offsetStyle=window.getComputedStyle(tempNew);
					offsetHeight=parseInt(offsetStyle.borderTopWidth)+parseInt(offsetStyle.borderBottomWidth)+parseInt(offsetStyle.paddingTop)+parseInt(offsetStyle.paddingBottom);
					offsetWidth=parseInt(offsetStyle.borderRightWidth)+parseInt(offsetStyle.borderLeftWidth)+parseInt(offsetStyle.paddingRight)+parseInt(offsetStyle.paddingLeft);
					var rect=tempOld.getBoundingClientRect()
					tempWidth=rect.width;
					tempHeight=rect.height;
					var tempAdjust={};
					tempAdjust.id=tempNew.id;
					tempAdjust.height=tempHeight;
					tempAdjust.width=tempWidth;
					tempAdjust.left=totalLeft;
					tempAdjust.offsetHeight=offsetHeight;
					tempAdjust.offsetWidth=offsetWidth;
					adjustArray.push(tempAdjust);
					totalLeft+=tempWidth;
				}
			}
		}
		
		// Loop through side table, use old table to assign sizes
		var sideHeights=[];
		var sideWidths=[];
		var multipleCols=0;
		var maxCol=0;
		var childOffsetWidth="";
		var childOffsetHeight="";
		var parentOffsetWidth="";
		var parentOffsetHeight="";
		if (sideTable) {		// DTB783 - Test for existence of the sideTable
			for (var cell=0;cell<sideTable.children.length;cell++) {
				var tempNew = sideTable.children[cell];
				var tempOld = document.getElementById(tempNew.id.substring(3,tempNew.id.length));
				if ((tempNew) && (tempOld)) {
					if ((childOffsetHeight=="") && (childOffsetWidth=="")) {
						var childOffsetStyle=window.getComputedStyle(tempOld.children[0]);
						childOffsetHeight=parseInt(childOffsetStyle.paddingTop)+parseInt(childOffsetStyle.paddingBottom);
						childOffsetWidth=parseInt(childOffsetStyle.paddingRight)+parseInt(childOffsetStyle.paddingLeft);
					}
					if ((parentOffsetHeight=="") && (parentOffsetWidth=="")) {
						var parentOffsetStyle=window.getComputedStyle(tempOld);
						parentOffsetHeight=parseInt(parentOffsetStyle.borderTopWidth)+parseInt(parentOffsetStyle.borderBottomWidth);
						parentOffsetWidth=parseInt(parentOffsetStyle.borderRightWidth)+parseInt(parentOffsetStyle.borderLeftWidth);
					}
					var idArray=tempOld.id.split("_");
					if (idArray[0]=="rowtotal") {
						var colNum=maxCol;
						var rowNum = (this.currPage*100)+1;		// DTB861 - Assign a row total just after the final row ID for the current page
					} else {
						var colNum=parseInt(idArray[1].split(":")[0]);
						var rowNum=parseInt(idArray[1].split(":")[1]);
					}
					var rect=tempOld.getBoundingClientRect()
					tempWidth=rect.width;
					tempHeight=rect.height;
					var tempAdjust={};
					tempAdjust.id=tempNew.id;
					tempAdjust.height=tempHeight-parentOffsetHeight;
					tempAdjust.width=tempWidth-parentOffsetWidth;
					tempAdjust.top=sideHeights[colNum];
					tempAdjust.offsetHeight=childOffsetHeight;
					tempAdjust.offsetWidth=childOffsetWidth;
					adjustArray.push(tempAdjust);
					
					colSpan=tempOld.colSpan ? parseInt(tempOld.colSpan) : 1;
					rowSpan=tempOld.rowSpan ? parseInt(tempOld.rowSpan) : 1;
					multipleCols = colNum>1 ? 1 : multipleCols;
					maxCol = colNum>maxCol ? colNum : maxCol;
					
					for (var c=colNum;c>(colNum-colSpan);c--) {
						if (sideHeights[c]) {
							sideHeights[c]+=tempHeight;
						} else {
							sideHeights[c]=tempHeight;
						}
					}
					
					for (var r=rowNum;r<(rowNum+rowSpan);r++) {
						if (!sideWidths[r]) {
							sideWidths[r]=[];
						}
						sideWidths[r][colNum]=tempWidth;
					}
				}
			}
		}
		
		// Use totalWidths array to reposition sideTable
		if (multipleCols) {
			var childrenLength=sideTable.children.length;
			for (var cell=0;cell<sideTable.children.length;cell++) {
				var tempNew = sideTable.children[cell];
				var tempOld = document.getElementById(tempNew.id.substring(3,tempNew.id.length));
				if ((tempNew) && (tempOld)) {
					var idArray=tempOld.id.split("_");
					if (idArray[0]=="rowtotal") {
						var colNum=maxCol;
						var rowNum = (this.currPage*100)+1;		// DTB861 - Assign a row total just after the final row ID for the current page
					} else {
						var colNum=parseInt(idArray[1].split(":")[0]);
						var rowNum=parseInt(idArray[1].split(":")[1]);
					}
					var tempLeft=0;
					for (var c=colNum+1;c<sideWidths[rowNum].length;c++) {
						tempLeft+=sideWidths[rowNum][c];
					}
					adjustArray[adjustArray.length-(childrenLength-cell)].left=tempLeft;
				}
			}
		}
		
		for (var pos in adjustArray) {
			var tempAdjust=adjustArray[pos];
			this.adjustCellSize(tempAdjust.id,tempAdjust.height,tempAdjust.width,tempAdjust.top,tempAdjust.left,tempAdjust.offsetHeight,tempAdjust.offsetWidth);
		}
	
	
		// Apply height and width to table divs
		// Loop through top height array to get max height - this is faster than looking at the table element
		var totalTop=0;
		for (var colNum in topHeights) {
			var tempTop=0;
			for (var rowNum in topHeights[colNum]) {
				tempTop+=topHeights[colNum][rowNum]
			}
			totalTop = tempTop>totalTop ? tempTop : totalTop;
		}
		
		// Loop through side width array to get max width - this is faster than looking at the table element
		var totalSide=0;
		for (var rowNum in sideWidths) {
			var tempSide=0;
			for (var colNum in sideWidths[rowNum]) {
				tempSide+=sideWidths[rowNum][colNum]
			}
			totalSide = tempSide>totalSide ? tempSide : totalSide;
		}
		
		if (sideTable) {		// DTB783 - Protect against missing sideTable
			sideTable.style.top=totalTop+'px';
			sideTable.style.height=(dataTableDiv ? (parseInt(dataTableDiv.style.height)-totalTop) : 0)+'px';
			sideTable.style.width=totalSide+'px';
		}
		
		if (topTable) {		// DTB783 - Protect against missing topTable
			topTable.style.height=totalTop+'px';
			topTable.style.left=totalSide+'px';
			topTable.style.width=(dataTableDiv ? (parseInt(dataTableDiv.style.width)-totalSide) : 0)+'px'
		}
		
		//Apply height and width to the nub table
		if (nubTable) {		// DTB783 - Protect against missing nubTable
			nubTable.style.height=totalTop+'px';
			nubTable.style.width=totalSide+'px';
			nubTable.children[0].style.height=totalTop+'px';
			nubTable.children[0].style.width=totalSide+'px';
		}
	}
	catch(ex) {
		alert('Error in absoluteAdjustLayout: ' + ex.message);
	}
}

ClientMethod adjustCellSize(cellid, height, width, top, left, offsetHeight, offsetWidth) [ Language = javascript ]
{
	var celldiv=document.getElementById(cellid);
	var child=celldiv.children[0];
	var tempStyle=celldiv.style;
	if (child) {
		child=child.style;
		child.height=((height-offsetHeight)!=undefined ? (height-offsetHeight) : child.height)+'px';
		child.width=((width-offsetWidth)!=undefined ? (width-offsetWidth) : child.width)+'px';
		tempStyle.height=(height!=undefined ? height: tempStyle.height)+'px';
		tempStyle.width=(width!=undefined ? width: tempStyle.width)+'px';
	} else {
		tempStyle.height=((height-offsetHeight)!=undefined ? (height-offsetHeight) : tempStyle.height)+'px';
		tempStyle.width=((width-offsetWidth)!=undefined ? (width-offsetWidth) : tempStyle.width)+'px';
	}
	tempStyle.top=(top!=undefined ? top : tempStyle.top)+'px';
	tempStyle.left=(left!=undefined ? left : tempStyle.left)+'px';
}

ClientMethod singleTableAdjustLayout() [ Language = javascript ]
{
	try {
		// divs
		var enc = this.getEnclosingDiv();
		var outer = this.findElement('outerDiv');
		var singleTable = this.findElement('dsPivotCompleteTable');
		var singleTableDiv = this.findElement('dsPivotCompleteTableDiv');
		var dataTable = this.findElement('dataTable');
		var dataTableDiv = this.findElement('dataTableDiv');
		
		var vtScroll = this.findElement('vtScroll');
		var hzScroll = this.findElement('hzScroll');
		var vtScrollInner = this.findElement('vtScrollInner');
		var hzScrollInner = this.findElement('hzScrollInner');
		var errorDiv = this.findElement('errorDiv');
		var	status = this.findElement('statusDiv');

		// show scroll bar divs (but make visible only if needed)
		if (vtScroll) {
			vtScroll.style.display = 'block';
		}
		if (hzScroll) {
			hzScroll.style.display = 'block';
			if (zenIsIE) {
				// JMD1023 another #^$%& workaround
				hzScroll.style.height = '30px';
			}
		}
		
		if (singleTable) {
			singleTable.style.visibility='visible';
		}
		if (dataTable) {
			dataTable.style.visibility='visible';
		}
		
		// DTB701 - hide scrollbars if previewMode is on
		// DTB712 - check interactivity
		if (this.previewMode&&!this.allowPreviewInteraction) {
			vtScroll.style.display = 'none';
			hzScroll.style.display = 'none';
		}

		vtScrollWid = vtScroll ? vtScroll.offsetWidth : 0;
		hzScrollHgt = hzScroll ? hzScroll.offsetHeight : 0;

		if (!singleTable) {
			if (vtScroll) {
				vtScroll.style.display = 'none';
			}
			if (hzScroll) {
				hzScroll.style.display = 'none';
			}
		}
		
		// WAL -- steal some old dt sizing logic for scroll bar

		var errHgt = errorDiv ? errorDiv.offsetHeight : 0;
		var dtHgt = dataTable ? dataTable.offsetHeight : singleTable ? singleTable.offsetHeight : 0;
		var dtWid = dataTable ? dataTable.offsetWidth : singleTable ? singleTable.offsetWidth : 0;

		if (vtScrollInner) {
			vtScrollInner.style.height = dtHgt + 'px';
		}
		if (hzScrollInner) {
			hzScrollInner.style.width = dtWid + 'px';
		}

		// outer div
		if (outer && enc) {
			outer.style.height = enc.offsetHeight + 'px';
			outer.style.width = enc.offsetWidth + 'px';
		}

		var st_h = 0;
		var st_w = 0
		if (status && enc) {
			st_h = status.offsetHeight;
			st_w = status.offsetWidth;
			status.style.top = (enc.offsetHeight - st_h) + 'px';
			status.style.left = '0px';
			status.style.right = '0px';
			
			/*
			// DTB171 - Completely hide pivot status if it is empty
			if (status.children.length) {
				status.style.display = 'block';
			}
			else {
				status.style.display = 'none';
			}
			*/
		}

		if (errorDiv) {
			errorDiv.style.bottom = st_h + 'px';
			errorDiv.style.left = '0px';
			errorDiv.style.right = '0px';
		}
		
		if (dataTableDiv && outer && hzScroll && vtScroll) {
			dataTableDiv.style.width = outer.offsetWidth - hzScroll.offsetHeight + 'px';
			if (this.kpi==='' && status) {
				dataTableDiv.style.height = outer.offsetHeight - status.offsetHeight - vtScroll.offsetWidth + 'px';
			}
			else {
				dataTableDiv.style.height = outer.offsetHeight - vtScroll.offsetWidth + 'px';
			}
		}
		if (singleTableDiv && outer && hzScroll && vtScroll) {
			singleTableDiv.style.width = outer.offsetWidth - hzScroll.offsetHeight + 'px';
			if (this.kpi==='' && status) {
				singleTableDiv.style.height = outer.offsetHeight - status.offsetHeight - vtScroll.offsetWidth + 'px';
			}
			else {
				singleTableDiv.style.height = outer.offsetHeight - vtScroll.offsetWidth + 'px';
			}
		}

		var singleTableWidth = singleTable ? singleTable.offsetWidth : 0;
		var singleTableHeight = singleTable ? singleTable.offsetHeight : 0;
		
		// + WAL258 -- take vertical scroll into account
		// DTB171 - Completely hide pivot status if it is empty
		if (status) {
			if (status.children.length || (singleTableDiv.clientHeight < singleTableDiv.scrollHeight)) {
				status.style.display = 'block';
			}
			else {
				status.style.display = 'none';
			}
		}
		// - WAL258

		if (vtScroll && outer) {
			vtScroll.style.right = '0px';
			if (this.kpi==='' && status) {
				vtScroll.style.height = outer.offsetHeight - status.offsetHeight - hzScroll.offsetHeight + 'px';
			}
			else {
				vtScroll.style.height = outer.offsetHeight - hzScroll.offsetHeight + 'px';
			}
		}
		// + WAL258 (2) -- make sure we don't use the status width when
		//                 the status area is hidden
		if (hzScroll && outer) {
			if ( (this.kpi==='') && status  && (st_w!=0) ) {
				hzScroll.style.bottom = status.offsetHeight + 'px';
				hzScroll.style.width = st_w - vtScroll.offsetWidth + 'px';
			}
			else {
				hzScroll.style.bottom = '0px';
				hzScroll.style.width = (enc.offsetWidth - vtScroll.offsetWidth) + 'px';	
			}
		}
		// - WAL258
		if (outer) {
			outer.style.visibility = 'visible';
		}
		if (singleTableDiv) {
			singleTableDiv.style.visibility = 'visible';	
		}
		
		// WAL106 -- hide scrollbars if we don't need to scroll in that direction
		if (vtScroll && dataTableDiv && (dataTableDiv.clientHeight >= dataTableDiv.scrollHeight)) {
			vtScroll.style.display = 'none';
		}
		if (hzScroll && dataTableDiv && (dataTableDiv.clientWidth >= dataTableDiv.scrollWidth)) {
			hzScroll.style.display = 'none';
		}

		// WAL106 -- wheel handling for single table
		// JMD814 add wheel handling
		if (singleTable) {
			var handler = new Function('evt','zenPage.getComponent('+this.index+').wheelHandler(evt);');

			if (singleTable.addEventListener) {
				singleTable.addEventListener('DOMMouseScroll', handler, false);  
				singleTable.addEventListener('mousewheel', handler, false);
			}
			else if(singleTable.attachEvent) {
				singleTable.attachEvent('onmousewheel', handler);
			}
		}
		
		if (singleTable) {
			singleTable.style.height=singleTableDiv.style.height;
			singleTable.style.width=singleTableDiv.style.width;
		}
		if (dataTableDiv) {
			dataTableDiv.style.height=singleTableDiv.style.height;
			dataTableDiv.style.width=singleTableDiv.style.width;
			dataTableDiv.style.visibility='visible';
		}
		if (!errorDiv) {
			if (this.absolutePositioning==1) {
				this.absoluteAdjustLayout();
			}
			
			if (singleTableDiv) {		// DTB783 - Do not add the pivot coverPane if there is no table div
				this.addPivotCoverPane(singleTableDiv);		// DTB701
				this.setPivotDisabled((this.previewMode||this.headFunctionAdded)&&this.rowsTruncated);		// DTB714 - Adjust coverPane test conditions
			}
		}
	}
	catch(ex) {
		alert('Error in singleTableAdjustLayout: ' + ex.message);
	}
}

/// Adjust size and position of the layout divs that contain the table
/// as well as the cells and headers in the table.
ClientMethod adjustTableLayout() [ Language = javascript ]
{
	try {
		// + WAL106 -- different handler for single table case
		if (this.singleTable) {
			this.singleTableAdjustLayout();
			return;	
		}
		// - WAL106
		
		// there is a cell height difference with webkit
		// use this as a work-around
		var who=navigator.userAgent;
		var isWebKit = who.indexOf("WebKit")>=0;

		// JMD1055: chrome fudge factors
		var fudgeW = isWebKit ? 0 : 0;
		var fudgeH = isWebKit ? 0 : 0;

		var colLevels = 1;

		// JMD1465 use cellWidth as min-width
		var minCellWidth = this.cellWidth!=='' ? parseInt(this.cellWidth,10) : 0;

		// JMD1023: skip for CSS=2
		var oldIE = false;
		if (zenPage.cssLevel<3) {
			fudgeH = 0;
			oldIE = zenIsIE;
		}

		// divs
		var enc = this.getEnclosingDiv();
		var outer = this.findElement('outerDiv');
		var topLeft = this.findElement('topLeftDiv');
		var topRight = this.findElement('topRightDiv');
		var bottomLeft = this.findElement('bottomLeftDiv');
		var bottomRight = this.findElement('bottomRightDiv');
		var vtScroll = this.findElement('vtScroll');
		var hzScroll = this.findElement('hzScroll');
		var vtScrollInner = this.findElement('vtScrollInner');
		var hzScrollInner = this.findElement('hzScrollInner');
		var errorDiv = this.findElement('errorDiv');
		var nubDiv = this.findElement('nubDiv');
		var	status = this.findElement('statusDiv');


		// show scroll bar divs (but make visible only if needed)
		if (vtScroll) {
			vtScroll.style.display = 'block';
		}
		if (hzScroll) {
			hzScroll.style.display = 'block';
			if (zenIsIE) {
				// JMD1023 another #^$%& workaround
				hzScroll.style.height = '30px';
			}
		}

		vtScrollWid = vtScroll ? vtScroll.offsetWidth : 0;
		hzScrollHgt = hzScroll ? hzScroll.offsetHeight : 0;

		// tables within divs
		var topTable = this.findElement('topTable');
		var leftTable = this.findElement('leftTable');
		var dataTable = this.findElement('dataTable');

		if (!dataTable) {
			if (vtScroll) {
				vtScroll.style.display = 'none';
			}
			if (hzScroll) {
				hzScroll.style.display = 'none';
			}
		}
		


		var errHgt = errorDiv ? errorDiv.offsetHeight : 0;
		var dtHgt = dataTable ? dataTable.offsetHeight : 0;
		var dtWid = dataTable ? dataTable.offsetWidth : 0;
		if (vtScrollInner) {
			vtScrollInner.style.height = dtHgt + 'px';
		}
		if (hzScrollInner) {
			hzScrollInner.style.width = dtWid + 'px';
		}

		// outer div
		if (outer) {
			outer.style.height = enc.offsetHeight + 'px';
			outer.style.width = enc.offsetWidth + 'px';
		}

		var st_h = 0;
		if (status) {
			st_h = status.offsetHeight;
			status.style.top = (enc.offsetHeight - st_h) + 'px';
			status.style.left = '0px';
			status.style.right = '0px';
		}

		if (errorDiv) {
			errorDiv.style.bottom = st_h + 'px';
			errorDiv.style.left = '0px';
			errorDiv.style.right = '0px';
		}

		// WAL106 -- there is only one box now
		// find top,left,wid,hgt for each of the four boxes
		var tl_t,tl_l,tl_w,tl_h;
		var tr_t,tr_l,tr_w,tr_h;
		var bl_t,bl_l,bl_w,bl_h;
		var br_t,br_l,br_w,br_h;

		// tl
		tl_t = 0;
		tl_l = 0;
		tl_w = leftTable ? leftTable.offsetWidth : 0;
		tl_h = topTable ? topTable.offsetHeight : 0;

		// adjust left side to show row header
		// JMD-add magic number to prevent slow increase in label width!
		if (nubDiv && nubDiv.offsetWidth > (tl_w + 5)) {
			tl_w = nubDiv.offsetWidth;
			leftTable.style.width = tl_w + 'px';
		}

		var w = (parseInt(enc.offsetWidth) - tl_w - 3 - vtScrollWid);
		w = (w > 0) ? w : 0;

		// tr
		tr_t = 0;
		tr_l = tl_w;
		tr_w = w;
		tr_h = tl_h;

		var h = (parseInt(enc.offsetHeight) - tr_h - 3 - st_h - 0 - hzScrollHgt - errHgt);
		h = (h > 0) ? h : 0;

		// bl
		bl_t = tl_h + 0;
		bl_l = 0;
		bl_w = tl_w
		bl_h = h;

		// br
		br_t = bl_t;
		br_l = bl_w;
		br_w = w;
		br_h = h;
		
		var nubadj = zenIsIE ? -1 : 0;

		// apply changes
		if (topLeft) {
			topLeft.style.top = tl_t + 'px';
			topLeft.style.left = tl_l + 'px';
			topLeft.style.width = ((tl_w>0)?(tl_w - 1 - nubadj):0) + 'px';
			topLeft.style.height = ((tl_h>0)?(tl_h-1):0) + 'px';
		}
		if (topRight) {
			topRight.style.top = tr_t + 'px';
			topRight.style.left = tr_l + 'px';
			topRight.style.width = tr_w + 'px';
			topRight.style.height = tr_h + 'px';
		}
		if (bottomLeft) {
			bottomLeft.style.top = bl_t + 'px';
			bottomLeft.style.left = bl_l + 'px';
			bottomLeft.style.width = bl_w + 'px';
			bottomLeft.style.height = bl_h + 'px';
		}
		if (bottomRight) {
			bottomRight.style.top = br_t + 'px';
			bottomRight.style.left = br_l + 'px';
			bottomRight.style.width = br_w + 'px';
			bottomRight.style.height = br_h + 'px';
		}

		if (vtScroll) {
			vtScroll.style.top = br_t + 'px';
			vtScroll.style.right = '0px';
			vtScroll.style.height = br_h + 'px';
		}
		if (hzScroll) {
			hzScroll.style.bottom = (st_h + errHgt) + 'px';
			hzScroll.style.right = vtScrollWid + 'px';
			hzScroll.style.width = br_w + 'px';
		}
		if (outer) {
			outer.style.visibility = 'visible';
		}

		if (dataTable && dataTable.offsetWidth >= 0) {
			// adjust size of column headers
			if (!leftTable) {
				// listing

				var ttw = 0;
				var hasRows = false;
				for (var c = 1;;c++) {
					var r = 1;
					var cell = this.findElement('cell_1_'+c);
					var c1 = this.findElement('col_'+r+':'+c);

					if ((!cell || !c1)&&c>1) break;
					if (cell && c1) {
						hasRows = true;
						// JMD1055 look at inner div
						// JMD1465
						var cellSz = this.computeDivSize(cell.firstChild,isWebKit);
						cellw = cellSz.width;
						var hdrSz = this.computeDivSize(c1.firstChild,isWebKit);
						hw = hdrSz.width;

						// JMD1506 look at *every* row!
						if (!isWebKit) {
							for (var rx = 2;;rx++) {
								var cellx = this.findElement('cell_'+rx+'_'+c);
								if (!cellx) break;
								var cellxSz = this.computeDivSize(cellx.firstChild,isWebKit);
								cellxw = cellxSz.width;
								cellw = cellw>cellxw ? cellw : cellxw;
							}
						}

						cellw = (hw>cellw) ? hw : cellw;

						if (cellw>0) {
							c1.style.width = cellw+fudgeW + 'px';
							cell.style.width = cellw+fudgeW + 'px';
							ttw += cellw;
						}
					}
				}
				// JMD1506 check for header with no cell
				if (!hasRows) {
					var ttw = 0;
					for (var c = 1;;c++) {
						var r = 1;
						var c1 = this.findElement('col_'+r+':'+c);
						if (!c1) break;
						var hdrSz = this.computeDivSize(c1.firstChild,isWebKit);
						cellw = hdrSz.width;
						c1.style.width = cellw+fudgeW + 'px';
						ttw += cellw;
					}
				}

				// fudge size of table!
				if (!oldIE) {
					// JMD remove fudge
					topTable.style.width = (ttw) + 'px';
					dataTable.style.width = topTable.offsetWidth + 'px';
					if (!isWebKit && !hasRows) {
						// JMD1484: if listing has no data, make sure ie shows headers
						dataTable.style.tableLayout = 'fixed';
					}
				}
				else {
					topTable.style.width = (ttw) + 'px';
					dataTable.style.width = topTable.offsetWidth + 'px';
					// JMD1274 we need to give ie a kick in the pants to do the right thing
					self.setTimeout("zenPage.getComponent("+this.index+").ieLayout()",10);
				}
			}
			else {
				// first make the tables really big!
				// JMD1091 - skip for old IE
				if (!oldIE) {
					topTable.style.width = 'auto';
					dataTable.style.width = topTable.offsetWidth + 'px';
				}
				else {
					// JMD1338
					dataTable.style.width = topTable.offsetWidth + 'px';
				}

				// set widths for pivot data columns
				var ttw = 0;
				for (var c = 1;;c++) {
					var r = 1;
					var cr = 1; // JMD1462 + (this.pageSize * (this.currPage-1));
					var cell = this.findElement('cell_'+cr+'_'+c);
					var c1 = this.findElement('col_'+r+':'+c);
					if (cell && !c1) {
						// check higher row
						for (r=2;r<10;r++) {
							var c1 = this.findElement('col_'+r+':'+c);
							if (c1) break;
						}
					}

					if (!cell || !c1) break;
					// JMD1055 look at inner div
					// JMD1465 use function, not offsetWidth
					// (this will *not* find a wide cell if it is not in the first row)
					var cellSz = this.computeDivSize(cell.firstChild,isWebKit);
					cellw = cellSz.width;
					var hdrSz = this.computeDivSize(c1.firstChild,isWebKit);
					hw = hdrSz.width;

					// JMD1506 look at *every* row!
					if (!isWebKit) {
						for (var rx = 2;;rx++) {
							var cellx = this.findElement('cell_'+rx+'_'+c);
							if (!cellx) break;
							var cellxSz = this.computeDivSize(cellx.firstChild,isWebKit);
							cellxw = cellxSz.width;
							cellw = cellw>cellxw ? cellw : cellxw;
						}
					}
					
					// +DTB093 - check the cell containing the column total
					var rtot = this.findElement('rtot_'+c);
					if (rtot) {
						var rtotSz = this.computeDivSize(rtot.firstChild,isWebKit);
						var rtotw = rtotSz.width;
						cellw = cellw>rtotw ? cellw : rtotw;
					}
					// -DTB093

					cellw = (hw>cellw) ? hw : cellw;
					// JMD1465
					cellw = (cellw<minCellWidth) ? minCellWidth : cellw;

					if (cellw>0) {
						c1.style.width = cellw+fudgeW + 'px';
						cell.style.width = cellw+fudgeW + 'px';
						
						if (zenIsIE) {
							// JMD1506 this appears to help!
							c1.firstChild.innerHTML = c1.firstChild.innerHTML;
							cell.firstChild.innerHTML = cell.firstChild.innerHTML;
						}
						ttw += cellw;
					}

					// look for headers in higher rows
					r++;
					for (;;r++) {
						var cn = this.findElement('col_'+r+':'+c);
						if (!cn) break;

						colLevels++;
						var span = parseInt(cn.colSpan);
						if (cellw>0) {
							cn.style.width = ((cellw+fudgeW)*span)-1+'px';
						}

						// inner div
						var adj = zenIsIE ? 0 : 4;
						// JMD846: compensate for colspan
						var span = parseInt(cn.colSpan);
						var divw = cellw * span;
						cn.firstChild.style.width = ((divw>adj)?(divw-adj):0) + 'px';
					}
				}
			
				// calculate width of the row totals column
				
				// +DTB093 - check for a grand total, it is likely the largest 
				var gtotal = this.findElement('gtot');
				if (gtotal) {
					var gtSz = this.computeDivSize(gtotal.firstChild,isWebKit);
					var gtxw = gtSz.width;
					hw = hw>gtxw ? hw : gtxw;
				}
				
				// WAL184 -- handle rare case where hw is undefined
				if (hw) {
					hw = (hw>minCellWidth) ? hw : minCellWidth;  // enforce min cell width
				}
				else {
					var hw = minCellWidth;	
				}
				// - WAL184
				
				var c1 = this.findElement('coltotal');
				if (c1) {	
					// Check all rows in totals column for width and keep the largest
					var hdrSz = this.computeDivSize(c1.firstChild,isWebKit);
					var hxw = hdrSz.width;
					hw = hw>hxw ? hw : hxw;
				
					for (var rt = 1;;rt++) {
						var cell = this.findElement('ctot_'+rt);
						if (!cell) break;
						var cellSz = this.computeDivSize(cell.firstChild,isWebKit);
						cellxw = cellSz.width;
						cellw = cellw>cellxw ? cellw : cellxw;
						cellw = (hw>cellw) ? hw : cellw;
						if (cellw>0) {
							cell.style.width = cellw+fudgeW + 'px';
						}
					}

					if (cellw>0) {
						c1.style.width = cellw+fudgeW + 'px';
						ttw += cellw;
					}
				}
				// -DTB093

				// fudge size of table!
				if (!oldIE) {
					// JMD1462 if fudge is 10 then columns do not always line up
					// if fudge is too big, then simple cases will fail
					// will columns *creep* in size with 20?
					var fdg = Math.round(ttw*0.05);
					fdg = fdg<10 ?10 : fdg;
					if (colLevels>1) {
						fdg = 100;
					}
					topTable.style.width = (ttw+fdg) + 'px';
				}
				else {
					// JMD1338
					// cannot use fudge factor for ie8 or else we get column "creep"
					topTable.style.width = (ttw) + 'px';
				}
				dataTable.style.width = topTable.offsetWidth + 'px';
				// JMD1465
				topTable.style.width = dataTable.offsetWidth + 'px';

				// adjust height of row headers
				// JMD1055
				for (var r = 1;;r++) {
					var r1 = this.findElement('row_1:'+r);
					var c1 = this.findElement('ctot_'+r);
					if (!c1) {
						var c1 = this.findElement('cell_'+r+'_1');
					}
					if (!c1||!r1) break;

					var rh = r1.firstChild.offsetHeight;
					var cellh = c1.firstChild.offsetHeight;

					if (cellh > rh) {
						r1.style.height = cellh+1 + 'px';
						c1.style.height = cellh+1 + 'px';
					}
					else if (cellh < rh) {
						c1.style.height = rh+1 + 'px';
						r1.style.height = rh+1 + 'px';
					}
					r1.parentNode.style.height = c1.offsetHeight + 'px';
					c1.parentNode.style.height = c1.offsetHeight + 'px';

					// JMD1506 do every cell across!
					if (oldIE) {
						var ieHeight = Math.max(0,c1.offsetHeight-4);
						for (var c = 2;;c++) {
							var cx = this.findElement('cell_'+r+'_'+c);
							if (!cx) break;
							cx.firstChild.style.height = ieHeight + 'px';
						}
					}
				}

				// total row
				var c1 = this.findElement('rtot_'+1);
				var r1 = this.findElement('rowtotal');
				if (c1 && r1) {
					var rh = r1.firstChild.offsetHeight;
					var cellh = c1.firstChild.offsetHeight;
					if (cellh > rh) {
						r1.style.height = cellh+1 + 'px';
						c1.style.height = cellh+1 + 'px';
					}
					else if (cellh < rh) {
						c1.style.height = rh+1 + 'px';
						r1.style.height = rh+1 + 'px';
					}
					r1.parentNode.style.height = c1.offsetHeight + 'px';
					c1.parentNode.style.height = c1.offsetHeight + 'px';
				}
			}
		}

		// re-adjust sizes
		tl_w = leftTable ? leftTable.offsetWidth : 0;
		tl_h = topTable ? topTable.offsetHeight : 0;
		var h = (parseInt(enc.offsetHeight) - tr_h - 3 - st_h - 0 - hzScrollHgt - errHgt);
		h = (h > 0) ? h : 0;

		// bl
		bl_t = tl_h + 0;
		bl_l = 0;
		bl_w = tl_w
		bl_h = h;

		// br
		br_t = bl_t;
		br_l = bl_w;
		br_w = w;
		br_h = h;
		if (topLeft) {
			topLeft.style.height = ((tl_h>0)?(tl_h-1):0) + 'px';
		}
		if (topRight) {
			// JMD1023
			topRight.style.height = ((tl_h>0)?(tl_h):0) + 'px';
		}
		if (bottomLeft) {
			bottomLeft.style.top = bl_t + 'px';
			bottomLeft.style.height = bl_h + 'px';
		}
		if (bottomRight) {
			bottomRight.style.top = br_t + 'px';
			bottomRight.style.height = br_h + 'px';
		}

		if (vtScroll) {
			vtScroll.style.top = br_t + 'px';
			vtScroll.style.height = br_h + 'px';
		}

		var dtHgt = dataTable ? dataTable.offsetHeight : 0;
		var dtWid = dataTable ? dataTable.offsetWidth : 0;
		if (vtScrollInner) {
			vtScrollInner.style.height = dtHgt + 'px';
			vtScroll.style.visibility = (dtHgt<br_h) ? 'hidden' : 'visible';
		}
		if (hzScrollInner) {
			hzScrollInner.style.width = dtWid + 'px';
			// JMD1055: use br_w not br_h
			hzScroll.style.visibility = (dtWid<br_w) ? 'hidden' : 'visible';
		}

		// adjust row captions
		var rcTable = this.findElement('rcTable');
		if (rcTable) {
			for (var r = 1;;r++) {
				var r1 = this.findElement('row_'+r+':1');
				if (!r1) break;
				var rcap = this.findElement('rcap_' + r);
				if (rcap) {
					rcap.style.width = (r1.offsetWidth>2?r1.offsetWidth-2:0) + 'px';
				}
			}
		}

		// JMD814 add wheel handling
		if (dataTable) {
			var handler = new Function('evt','zenPage.getComponent('+this.index+').wheelHandler(evt);');

			if (dataTable.addEventListener) {
				dataTable.addEventListener('DOMMouseScroll', handler, false);  
				dataTable.addEventListener('mousewheel', handler, false);
			}
			else if(dataTable.attachEvent) {
				dataTable.attachEvent('onmousewheel', handler);
			}
		}
	}
	catch(ex) {
		alert('Error in adjustTableLayout: ' + ex.message);
	}
}

/// Compute and return the size of the given html.
ClientMethod computeDivSize(theDiv, isWebKit) [ Internal, Language = javascript ]
{
	var size = {width:0, height:0};

	if (isWebKit) {
		size.width = theDiv.offsetWidth;
		size.height = theDiv.offsetHeight;
		return size;
	}

	var div = this.getEnclosingDiv();
	var element = document.createElement('div');
	element.className = theDiv.className;
	element.style.position = 'absolute';
	element.style.top = '0px';

	if (window.getComputedStyle) {
		var cStyle = window.getComputedStyle(theDiv,null);
		var fSize = cStyle.getPropertyValue('font-size');
		element.style.fontSize = fSize;
		var fWeight = cStyle.getPropertyValue('font-weight');
		element.style.fontWeight = fWeight;
		var fFamily = cStyle.getPropertyValue('font-family');
		element.style.fontFamily = fFamily;
	}
	else if (theDiv.currentStyle) {
		// ie8
		// JMD1506 add test for missing currentStyles
		element.style.fontSize = theDiv.currentStyle['font-size'] ? theDiv.currentStyle['font-size'] : '';
		element.style.fontWeight = theDiv.currentStyle['font-weight'] ? theDiv.currentStyle['font-weight'] : '';
		element.style.fontFamily = theDiv.currentStyle['font-family'] ? theDiv.currentStyle['font-family'] : '';
	}

	element.innerHTML = theDiv.innerHTML;
	div.appendChild(element);

	size.width = element.offsetWidth;
	size.height = element.offsetHeight;
	div.removeChild(element);
	
	return size;
}

/// Work-around for ie8!
ClientMethod ieLayout() [ Language = javascript ]
{
	// JMD1274
	var dataTable = this.findElement('dataTable');
	dataTable.style.tableLayout = 'fixed';
}

/// Mouse wheel handler.
ClientMethod wheelHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var wheelDelta = evt.detail ? evt.detail * -1 : evt.wheelDelta;
	var vtScroll = this.findElement('vtScroll');
	if (vtScroll) {
		var c1 = this.findElement('cell_1_1');
		var d = c1 ? c1.offsetHeight : 40;
		vtScroll.scrollTop = vtScroll.scrollTop + ((wheelDelta>0) ? -d : d);
		this.cellScrollVt();
	}
}

/// Vertical Scroll handler.
ClientMethod cellScrollVt() [ Language = javascript ]
{
	var vtScroll = this.findElement('vtScroll');
	
	// WAL
	// PFS037 - Do not handle listings here
	if ((this.absolutePositioning==1)&&(!this.isDrillThrough)) {
		this.findElement('sideTable').scrollTop = vtScroll.scrollTop;
		this.findElement('dataTableDiv').scrollTop = vtScroll.scrollTop;
		return	
	}
	
	// + WAL106
	if (this.singleTable) {
		var singleTableDiv = this.findElement('dataTableDiv');
		singleTableDiv.scrollTop = vtScroll.scrollTop;
		return;
	}
	// - WAL106
	
	var bottomLeft = this.findElement('bottomLeftDiv');
	var bottomRight = this.findElement('bottomRightDiv');
	if (bottomLeft && vtScroll) {
		bottomLeft.scrollTop = vtScroll.scrollTop;
	}
	if (bottomRight && vtScroll) {
		bottomRight.scrollTop = vtScroll.scrollTop;
	}
}

/// Horizontal Scroll handler..
ClientMethod cellScrollHz() [ Language = javascript ]
{
	var hzScroll = this.findElement('hzScroll');
	
	// WAL
	// PFS037 - Do not handle listings here
	if ((this.absolutePositioning==1)&&(!this.isDrillThrough)) {
		this.findElement('topTable').scrollLeft = hzScroll.scrollLeft;
		this.findElement('dataTableDiv').scrollLeft = hzScroll.scrollLeft;
		return	
	}
	
	// + WAL106
	if (this.singleTable) {	
		// need a div that just wraps the table
		var singleTableDiv = this.findElement('dataTableDiv');
		singleTableDiv.scrollLeft = hzScroll.scrollLeft;
		return;
	}
	// - WAL106
	
	
	var topRight = this.findElement('topRightDiv');
	var bottomRight = this.findElement('bottomRightDiv');
	if (topRight && hzScroll) {
		topRight.scrollLeft = hzScroll.scrollLeft;
	}
	if (bottomRight && hzScroll) {
		bottomRight.scrollLeft = hzScroll.scrollLeft;
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this._registeredCounter = 0; // + WAL259
	this._initialLoad = true;		// DP-434472
	
	this.adjustTableLayout();

	if (('' != this.queryKey) && (!this.queryStatus || this.queryStatus < 100)) {
		this.showMessage($$$Text('Working...'),this.queryComplete);
		this.sendEventToViews('beginWait');
		this.startQueryTimer();
	}
	else if (this.queryPending) {
		this.sendEventToViews('beginWait');
		this.showPendingMsg(true);
		this.startQueryTimer();
	}
	else {
		this.computeTotals();
	}
}

/// This client method, if present, is fired when the object is updated from the server.
/// This is called *after* changes have been synched.
ClientMethod onupdateHandler() [ Language = javascript ]
{
	this._runningQuery = false;
	// JMD1128 test hidden
	if (!zenPage._noUpdate && !this.hidden) {
		// JMD1023: prevent size change during save
		this.adjustTableLayout();
	}

	// JMD1269
	var ready = true;
	if (('' != this.queryKey) && (!this.queryStatus || this.queryStatus < 100)) {
		// DP-408943 - If nothing else has set the progressMessage, establish the initial default.
		// Otherwise, update the current message display with the current message and updated queryComplete
		// value.
		this.progressMessage = (!this.progressMessage) ? $$$Text('Working...') : this.progressMessage;
			
		this.showMessage('',this.queryComplete);
		this.sendEventToViews('beginWait');
		this.showPendingMsg(false);
		this.startQueryTimer();
		ready = false;
	}
	else {
		this.hideMessage();
		// DP-408943 - Clear the current progressMessage once the conditions are met for 
		// a graceful exit from its display
		this.progressMessage = '';
		
		if (this.queryPending) {
			this.sendEventToViews('beginWait');
			this.showPendingMsg(true,'update');
			this.startQueryTimer();
		}
		else {
			// JMD1462
			this.showPendingMsg(false);
		}
	}
	if (!zenPage._noUpdate && ready) {
		this.raiseDataChange();

		// JMD1063
		// JMD1128 test hidden
		if (zenPage.adjustSizes && !this.hidden) {
			zenPage.adjustSizes();
		}
	}
	// JMD1063: apply selected color
	if ('' != this.selectedRange && !this.isDrillThrough) {
		var p = this.selectedRange.split(',');
		this.selectCellRange(p[0],p[1],p[2],p[3],false,false,true);
	}
}

/// Start the timer used to update during query calculation.
ClientMethod startQueryTimer(needsRefresh) [ Language = javascript ]
{
	this.stopQueryTimer();
	var interval = 100;

	// JMD1462
	if (zenGet(needsRefresh,false)) {
		this.sendEventToViews('beginWait');
		this.showPendingMsg(true);
		this._needsRefresh = true;
		var interval = 50;
	}
	else if (this._initialLoad) {
		// DP-434472 - Account for polling that is no longer happening on the server to allow 
		// setup of the background agents before begginning to poll the query status.
		delete this._initialLoad;
		interval = 500;
	}

	this.queryCalls++;
	this._queryTimerId = self.setTimeout("zenPage.getComponent("+this.index+").queryTimerHandler()",interval);
}

/// Stop the query timer.
ClientMethod stopQueryTimer() [ Language = javascript ]
{
	if (this._queryTimerId) {
		this.showPendingMsg(false);
		self.clearTimeout(this._queryTimerId);
		this._queryTimerId = null;
	}
}

/// Internal method.<br>
/// Timer event handler used by the query timer bar.
ClientMethod queryTimerHandler() [ Internal, Language = javascript ]
{
	this._queryTimerId = null;
	if (this._inCancel) {
		return;
	}
	
	// JMD1462
	if (this._needsRefresh) {
		delete this._needsRefresh;
		this.executeQuery();
		this.sendEventToViews('beginWait');
		this.startQueryTimer();
		return;
	}

	var proxy = new zenProxy();
	// pass id to server as a diagnostic
	proxy.id = this.id;
	var oldStatus = this.queryStatus;

	var ok = this.GetQueryStatus(proxy,this.cubeKey,this.queryKey,this.kpi);
	if (ok) {
		this.queryStatus = parseInt(proxy.queryStatus,10);
		this.queryComplete = proxy.queryComplete;		// DP-408943 - Maintain direct value in state variable
		this.queryComplete = isNaN(this.queryComplete) ? 0 : this.queryComplete;
		this.queryPending = (proxy.queryPending==1)?true:false;

		// query failed due to exception
		if (proxy.error) {
			this.sendEventToViews('endWait');
			this.hideMessage();
			// DTB716 - Suppress this alert. This will now be displayed in the table content.
			//alert($$$FormatText($$$Text("There has been an error in processing this query:\n%1","%DeepSee"),proxy.error));
			//return;
		}

		var doRefresh = 0;		// DTB823 - Signal flag to decide behavior after all tests
		if (this.queryStatus >= 100) {
			if (this.queryPending) {
				// try again
				this.showPendingMsg(true,'timer');
				doRefresh = 1;		// DTB823
			}
			else {
				this.showPendingMsg(false);
				this.sendEventToViews('endWait');
				doRefresh = 1;		// DTB823
			}
		}
		else if (this.queryStatus < 0) {
			this.sendEventToViews('endWait');
			this.hideMessage();
			alert($$$Text('Error on server!'));
			return;
		}
		else if (this.kpi != '') {
			// JMD1144
			if (this.queryComplete>=0) {
				this.showMessage($$$Text('Calculating...'),this.queryComplete);
			}
			else if ((this.queryStatus!=oldStatus)) {
				doRefresh = 1;		// DTB823
			}
			// JMD1339: make sure charts get wait event
			this.sendEventToViews('beginWait');
		}
		else {
			if (this.queryStatus<100) {
				// DTB868 - Signal a refresh under all remaining conditions that are not complete
				doRefresh = 1;
			}
			
			// DTB868 - Determine the appropriate message based on current status
			if (this.queryStatus >= 50) {
				this.showMessage($$$Text('Preparing final result...'),100);
			}
			else if (this.queryStatus < 30) {
				this.showMessage($$$Text('Computing axes...'),this.queryComplete);
			}
			else {
				this.showMessage($$$Text('Calculating...'),this.queryComplete);
			}
			// JMD1339: make sure charts get wait event
			this.sendEventToViews('beginWait');
		}
		
		// DTB823 - Either refresh contents or initiate a timer to refresh later as needed
		if (doRefresh) {
			this.refreshContents();
		}
		else {
			this.startQueryTimer();
		}
	}
	else {
		this.sendEventToViews('endWait');
		if (!zenPage.limitPopups) {
			// DTB789 - Check the page setting before throwing an alert window
			alert('Error from server.');
		}
	}
}

/// Return the caption associate with given cube element.
ClassMethod GetItemCaption(pCubeName As %String, pSpec As %String) As %String [ ZenMethod ]
{
	If ($$$LOWER($P(pSpec,".",*))="variable") {
		// DTB489 - Add support for pivot variable captions
		Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(pCubeName,$P(pSpec,".",1,*-1),.tPivotVariableInfo)
		If $$$ISERR(tSC) Quit pSpec
		
		Set tCaption = $G(tPivotVariableInfo("displayName"))
		If (tCaption="") {
			Set tCaption = $G(tPivotVariableInfo("name"),pSpec)
		}
	}
	Else {
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName,pSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
		If $$$ISERR(tSC) Quit pSpec
		
		If (tRelationName'="") {
			Set tRelCube = ##class(%DeepSee.Utils).%GetRelatedCube(pCubeName,tRelationName)
			Quit ..GetItemCaption(tRelCube,tRelationSpec)
		}

		Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName,tDimNo,tHierNo,tLevelNo,.tCaption)
		If $$$ISERR(tSC) Quit pSpec
	}

	Quit tCaption
}

ClassMethod FormatValue(pCubeName As %String, pQueryKey As %String, pValue As %String, pFormattedValue As %ZEN.proxyObject, pRowNo As %Integer, pColNo As %Integer) As %Boolean [ ZenMethod ]
{
	// Method added by WAL122
	// re-open existing query
	Set tRS = ##class(%DeepSee.ResultSet).%New()
	Set tSC = tRS.%PrepareKey(pCubeName,pQueryKey)
	// If there's an error just return the original value
	If $$$ISERR(tSC) {
		Set pFormattedValue.formatted = 0
		Set pFormattedValue.value = pValue		
		Quit $$$OK
	}
	Set tSC = tRS.%GetOrdinalLabel(.tLabel,1,pColNo,.tFormat)
	Set tSC = tRS.%GetOrdinalLabel(.tLabel,2,pRowNo,.tFormat)
	Set pFormattedValue.formatted = $S($G(tFormat)'="":1,1:0)
	Set pFormattedValue.value = $S($G(tFormat)'="":tRS.%FormatNumber(pValue,tFormat),1:pValue)
	Quit $$$OK
}

/// Get the tuple spec for the given item within the query result and place it into the proxy object.
/// <var>pAxisName</var> is "row" or "col".<br/>
/// Return true, if ok.
ClassMethod GetItemSpec(pSpec As %ZEN.proxyObject, pCubeName As %String, pQueryKey As %String, pSortDir As %String, pSortColumn As %String, pAxisName As %String, pItemNo As %Integer, pItemNoSorted As %Boolean = 0) As %Boolean [ ZenMethod ]
{
	Set tHasChildren = 0
	Set tIsRelation = 0
	Set tAxisNo = $Case(pAxisName,"row":2,"col":1,:-1)
	If (tAxisNo < 0) {
		Set pSpec.error = "Invalid axis name"
		Quit 0
	}

	// WAL088 -- when GetItemSpec is called in rowDblClickHandler and dropStartHandler the item number is already sorted
	//           so we don't need this lookup ('pItemNoSorted)
	if (pSortColumn>0 && (tAxisNo=2) && ('pItemNoSorted)) { // JSL4418
		Set pItemNo = $G($$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"sort",pSortColumn,pSortDir,pItemNo),pItemNo) // JSL4418
	}

	Set tChildSpec = ""

	// re-open existing query
	Set tRS = ##class(%DeepSee.ResultSet).%New()
	Set tSC = tRS.%PrepareKey(pCubeName,pQueryKey)
	If $$$ISERR(tSC) {
		Set pSpec.error = $System.Status.GetOneErrorText(tSC)
		Quit 0
	}

	Set tSC = tRS.%GetAxisMembers(tAxisNo,.tKey,pItemNo)
	If $$$ISERR(tSC) {
		Set pSpec.error = $System.Status.GetOneErrorText(tSC)
		Quit 0
	}

	// JMD1456 loop over items and pull out measures
	// WAL102 -- maybe we can grab measure info here
	Set pSpec.measure = ""
	Set k = $O(^||DeepSee.AxisMembers(tKey,tAxisNo,pItemNo,""),1,tInfo)
	While ((k'="") && ($G(tInfo)'="")) { // WAL236
		Set tDimNo = $LG(tInfo,7)		
		// + WAL227 -- check for calculated first, before concluding this isn't a measure
		//             calculated measures don't *always* belong to dimension 0
		// WAL229 -- avoid <SUBSCRIPT> error by checking ($LG(tInfo,2)'="")
		If (($LG(tInfo,2)'="") &&
			($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"calcMbrs","MEASURES",$$$UPPER($LG(tInfo,2))))'="")) {
			Set pSpec.measure = $LG(tInfo,2)
			Set pSpec.measureLogical = $LG(tInfo,2)
		}
		// - WAL227
		ElseIf (tDimNo'=0) {
			Set tItemList($I(tItemList)) = tInfo
		}
		Else {
			// + WAL102 -- Maintain list of measures for tooltip
			// Item 2 from the %GetAxisMembers list is the text
			Set pSpec.measure = $LG(tInfo,2)
			Set pSpec.measureLogical = $LG(tInfo,4) // WAL190
			Set:pSpec.measureLogical="" pSpec.measureLogical = pSpec.measure
			// - WAL102
		}
		Set k = $O(^||DeepSee.AxisMembers(tKey,tAxisNo,pItemNo,k),1,tInfo)
	}

	Set tSpec = ""
	Set tText = ""
	Set tTooltipText = "" // WAL102
	Set c = 0

	Set k = $O(tItemList(""),1,tInfo)
	While (k'="") {
		Set c = c + 1
		Set tIsAgg = 0
		Set tDimName = $LG(tInfo,3)
		Set tRelSpec = $LG(tInfo,10)
		Set tIsLastItem = ($O(tItemList(k))="")

		// JMD1361 Check for %OR
		If (tRelSpec'="") {
			Set tUseChildren = ($$$UPPER(tRelSpec)[".CHILDREN")		// DTB486 - Note the presence of CHILDREN on the axis
 			
			If ($E(tRelSpec,1,4)'="%OR(") {
				// strip off children and key
				Set tRelSpec = $P(tRelSpec,".children",1)
				Set tRelSpec = $P(tRelSpec,".&[",1)
			}
		}
		If (tRelSpec'="") {
			// JMD1289 try to find names for relationship
			Set tRCubeCaption = tDimName
			Set tRelCube = $$$UPPER(##class(%DeepSee.Utils).%GetRelatedCube(pCubeName,tDimName))

			// JMD1361
			If ($E(tRelSpec,1,4)="%OR(") {
				// strip off %OR, decorate each item, and reapply %OR
				// assume no commas in spec!
				Set t = $E(tRelSpec,6,*-2)
				If (tRelCube'="") {
					// use first OR term to get caption
					Set tRCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(tRelCube)
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,$P(t,",",1),.tRelDimNo)
					If $$$ISERR(tSC) Quit
				}
				Set ts = ""
				For tp = 1:1:$L(t,",") {
					Set ts = ts _ $S(ts="":"",1:",") _ "["_tDimName_"]"_"."_$P(t,",",tp)
				}
				Set tItemSpec = "%OR({"_ts_"})"

				Set:tItemSpec'="" tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
				If (tIsLastItem) {
					If (c>1) {
						Set tSpec = "("_tSpec_")"
					}
				}
				// + WAL102
				If (tAxisNo=1) {
					Set tTooltipText = tRCubeCaption _ $S(tText="":"",1:"/") _ tTooltipText
				}
				Else {
					Set tTooltipText = tTooltipText _ $S(tText="":"",1:"/") _ tRCubeCaption
				}
				// - WAL102
				Set tThisText = tRCubeCaption_":"_$LG(tInfo,2)
				Set tText = tText _ $S(tText="":"",1:" / ") _ tThisText
				Set:tIsLastItem tIsRelation = 1
			}
			ElseIf ($$$UPPER(tRelSpec) '[ ".%TOPMEMBERS") {
				If (tRelCube'="") {
					Set tRCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(tRelCube)
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,tRelSpec,.tRelDimNo,.tRelHierNo,.tRelLevelNo)		// DTB486 - Return all 3 numeric level coordinates
					If $$$ISERR(tSC) Quit
					
					Set tTempRelCube = tRelCube
					Set tLastRelCube = tRelCube
					Set tTempRelSpec = tRelSpec
					While (tRelDimNo="") {
						// DTB626 - The remaining spec might still have relatinships in it. Test them to work down to the real spec and collect labels as we go.
						Kill tSpecInfo
						Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tTempRelSpec,.tNewSpecInfo)
						Set tTempRelDim = tNewSpecInfo(1)
						Set tTempRelCube = $$$UPPER(##class(%DeepSee.Utils).%GetRelatedCube(tLastRelCube,tTempRelDim))
						
						Set tRCubeCaption = tRCubeCaption _ ":" _ ##class(%DeepSee.Utils).%GetCubeCaption(tTempRelCube)
						
						Set tTempRelSpecList = ""
						Set tSpecNo = $O(tNewSpecInfo(1),1,tSpecItem)
						While (tSpecNo'="") {
							Set tTempRelSpecList = tTempRelSpecList _ $LB(tSpecItem)
							Set tSpecNo = $O(tNewSpecInfo(tSpecNo),1,tSpecItem)
						}
						
						Set tTempRelSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec(tTempRelSpecList)

						Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tTempRelCube,tTempRelSpec,.tRelDimNo,.tRelHierNo,.tRelLevelNo)
						If $$$ISERR(tSC) Quit
						
						Set tLastRelCube = tTempRelCube
					}
					
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(tTempRelCube,tRelDimNo,tRelHierNo,tRelLevelNo,.tCaption)
					If $$$ISERR(tSC) Quit
					Set tRCubeCaption = tCaption		// DTB626 - Use only the final level caption to match what is returned by filters.
					
					// DTB486 - If the original level was defined using CHILDREN, try to find the next level down
					If tUseChildren {
						Set tRelLevelNo = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tRelCube),"mbr#",tRelDimNo,tRelHierNo,tRelLevelNo))
						
						If tRelLevelNo'="" {
							Set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(tRelCube,.tRelSpec,tRelDimNo,tRelHierNo,tRelLevelNo)
							If $$$ISERR(tSC) Quit
						}
						Else {
							Quit
						}
					}
				}
				Set tItemSpec = "[" _ tDimName _ "]." _ tRelSpec

				// JMD862: Test for and use "All level"
				// we should test if there are children of this related level!
				If ($LG(tInfo,6)'="") {
					Set tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo,6))_"]"
					If (tIsLastItem) {
						Set tChildSpec = tItemSpec_".children"
					}
					Else {
						Set tChildSpec = tItemSpec
					}
				}
				Else {
					If (tRelCube'="") {
						Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,tRelSpec,.tRelDimNo)
						If $$$ISERR(tSC) Quit
						If (tRelDimNo'="") {
							// is there an All level?
							Set tAllLevel = $LG($G($$$DeepSeeMetaGLVN("cubes",tRelCube,"mbr#",tRelDimNo,0,0)),4)
							If (tAllLevel'="") {
								If (tIsLastItem) {
									Set tChildSpec = tItemSpec_".["_tAllLevel_"].children"
								}
								Else {
									Set tChildSpec = tItemSpec_".["_tAllLevel_"]"
								}
							}
						}
					}
				}
				
				Set:tItemSpec'="" tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
				If (tIsLastItem) {
					If (c>1) {
						Set tSpec = "("_tSpec_")"
					}
				}

				// + WAL102
				If (tAxisNo=1) {
					Set tTooltipText = tRCubeCaption _ $S(tText="":"",1:"/") _ tTooltipText
				}
				Else {
					Set tTooltipText = tTooltipText _ $S(tText="":"",1:"/") _ tRCubeCaption
				}
				// - WAL102
				Set tThisText = tRCubeCaption_":"_$LG(tInfo,2)
				Set tText = tText _ $S(tText="":"",1:" / ") _ tThisText
				Set:tIsLastItem tIsRelation = 1
			}
			Quit:tIsLastItem
		}
		ElseIf (tDimName="") {
			// assume an aggregate; loop over children, build set
			Set tIsAgg = 1
			Set tSetSpec = ""
			// JMD1366: try to be smarter about text for computed dimension
			// with %OR in it!
			Set tText = $LG(tInfo,2)
			Set tAgg = $LG(tInfo,4)
			Set tNeedText = 1
			If (tText=tAgg) {
				Set tText = ""
			}
			Else {
				Set tNeedText = 0
			}

			Set k2 = $O(^||DeepSee.AxisMembers(tKey,tAxisNo,pItemNo,k,""),1,tInfo2)
			While (k2'="") {
				// !!! change to recursive function!
				Set tDimNo = $LG(tInfo2,7)
				Set tHierNo = $LG(tInfo2,8)
				Set tLevelNo = $LG(tInfo2,9)
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName,tDimNo,tHierNo,tLevelNo,.tCaption)
				If $$$ISERR(tSC) Quit

				If (tNeedText) {
					// WAL102
					If (tAxisNo=1) {
						Set tTooltipText = tCaption _ $S(tText="":"",1:"/") _ tTooltipText
					}
					Else {
						Set tTooltipText = tTooltipText _ $S(tText="":"",1:"/") _ tCaption
					}
					// - WAL102
					Set tText = tText _ $S(tText="":"",1:" / ") _ tCaption_":"_$LG(tInfo2,2)
				}
				Set tItemSpec = "["_$LG(tInfo2,3) _ "]"
				Set:$LG(tInfo2,4)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo2,4) _ "]"
				Set:$LG(tInfo2,5)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo2,5) _ "]"
				Set:$LG(tInfo2,6)'="" tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo2,6))_"]"
				Set tSetSpec = tSetSpec _ $S(tSetSpec="":"",1:",") _ tItemSpec
				Set k2 = $O(^||DeepSee.AxisMembers(tKey,tAxisNo,pItemNo,k,k2),1,tInfo2)
			}
			Set tSetSpec = "{"_tSetSpec_"}"
			Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tSetSpec
		}
		Else {
			Set tDimNo = $LG(tInfo,7)
			Set tHierNo = $LG(tInfo,8)
			Set tLevelNo = $LG(tInfo,9)
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName,tDimNo,tHierNo,tLevelNo,.tCaption)
			If $$$ISERR(tSC) Quit

			// WAL102
			If (tAxisNo=1) {
				Set tTooltipText = tCaption _ $S(tText="":"",1:"/") _ tTooltipText
			}
			Else {
				Set tTooltipText = tTooltipText _ $S(tText="":"",1:"/") _ tCaption
			}
			// - WAL102
			Set tText = tText _ $S(tText="":"",1:" / ") _ tCaption_":"_$LG(tInfo,2)
			
			// WAL032 -- handle %OR members
			Set tORSpec=$LG(tInfo,11)
			// WAL032

			// JMD976: test for null relationship
			If (($LG(tInfo,3)'="")&&($LG(tInfo,4)="")&&##class(%DeepSee.Utils).%IsRelationship(pCubeName,$LG(tInfo,3))) {
				Set tItemSpec = "["_$LG(tInfo,3) _ "].&[<null>]"
			}
			ElseIf (tORSpec'="") {
				// WAL032
				Set tBaseItemSpec = "["_$LG(tInfo,3) _ "]"
				Set:$LG(tInfo,4)'="" tBaseItemSpec = tBaseItemSpec _ ".[" _ $LG(tInfo,4) _ "]"
				Set:$LG(tInfo,5)'="" tBaseItemSpec = tBaseItemSpec _ ".[" _ $LG(tInfo,5) _ "]"
				
				Set tSC = ##class(%DeepSee.Utils).%MemberHasChildren(pCubeName,tDimNo,tHierNo,tLevelNo,.tHasChildren)
				If $$$ISERR(tSC) Quit
				
				Set tIsLastItem = ($O(^||DeepSee.AxisMembers(tKey,tAxisNo,pItemNo,k))="")	
				
				// Use next level in hierarchy for final child spec
				If (tIsLastItem && tHasChildren) {
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(pCubeName,.tChildLevelSpec,tDimNo,tHierNo,tLevelNo+1)
					If $$$ISERR(tSC) Quit
					Set tItemSpecForChild=tChildLevelSpec_".MEMBERS"
				}
				Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
				Set tDimensionInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tMemberClass = $lg(tDimensionInfo,6)
				// Loop through the OR members specs
				Set tOrTermCount = 0
				For i=1:1:$length(tORSpec,"|") {
					Set tORMember = $p(tORSpec,"|",i)
					Set tORMemberKey = $classmethod(tMemberClass,"%GetMemberSpec",tORMember,"Patients",tDimNo,tHierNo,tLevelNo)
	
					If ($G(tORMemberKey)'="")&&(tORMember'="NO MEMBER") {
						// DTB598 - Only add real executable members to this set
						Set tItemSpec = tBaseItemSpec _ "." _ $G(tORMemberKey)
						Set tCompleteItemSpec = $G(tCompleteItemSpec) _ $S($G(tCompleteItemSpec)="":"",1:",") _ tItemSpec
						Set x = $I(tOrTermCount)
					}
				}
				// Add %OR to tItemSpec
				Set:(($G(tCompleteItemSpec)'="")&&(tOrTermCount>1)) tCompleteItemSpec="%OR({"_tCompleteItemSpec_"})"
				Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tCompleteItemSpec
				Set tItemSpec = tCompleteItemSpec
				If (c > 1) {
					Set tChildSpec = "CROSSJOIN("_tChildSpec_","_$S($G(tItemSpecForChild)'="":tItemSpecForChild,1:tItemSpec)
				}
				Else {
					Set tChildSpec = $S($G(tItemSpecForChild)'="":tItemSpecForChild,1:tItemSpec)
				}
			}
			Else {
				Set tItemSpec = "["_$LG(tInfo,3) _ "]"
				Set:$LG(tInfo,4)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo,4) _ "]"
				Set:$LG(tInfo,5)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo,5) _ "]"
				Set:$LG(tInfo,6)'="" tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo,6))_"]"
				Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
				If (c > 1) {
					Set tChildSpec = "CROSSJOIN("_tChildSpec_","_tItemSpec
				}
				Else {
					Set tChildSpec = tItemSpec
				}
			}
			// WAL032
		}

		// next item
		Set k = $O(tItemList(k),1,tInfo)
		If ('tIsAgg&&(k="")) {
			// last item, test for children
			Set tSC = ##class(%DeepSee.Utils).%MemberHasChildren(pCubeName,tDimNo,tHierNo,tLevelNo,.tHasChildren)
			If $$$ISERR(tSC) Quit

			// WAL032 -- don't add ".children" if we are dealing with a %OR spec
			If (tHasChildren&&($LG(tInfo,11)="")) {
				Set tChildSpec = tChildSpec _ ".children"
			}
			// WAL032
		}
		If ('tIsAgg&&(c > 1)) {
			Set tChildSpec = tChildSpec_")"
		}
	}
	If $$$ISERR(tSC) {
		Set pSpec.error = $System.Status.GetOneErrorText(tSC)
		Quit 0
	}

	// make a tuple
	If ('tIsRelation) {
		If (c > 1) {
			Set tSpec = "("_tSpec_")"
		}
		If ('tHasChildren) {
			Set tChildSpec = ""
		}
	}
	Set pSpec.spec = tSpec
	Set pSpec.text = tText
	Set pSpec.childSpec = tChildSpec
	Set pSpec.tooltipText = tTooltipText // WAL102
	Quit 1
}

/// Return the filter spec for the given cell range.
ClientMethod getFilterForCells(r1, c1, r2, c2, allRows, allCols) [ Language = javascript ]
{
	// JMD1468

	allRows = ('undefined' == typeof allRows) ? false : (parseInt(allRows,10)==1);
	allCols = ('undefined' == typeof allCols) ? false : (parseInt(allCols,10)==1);

	var filter = '';
	if (''!=this.kpi) return filter;
	
	if (''==this.cubeKey || ''==this.queryKey) return filter;
	
	// DTB397 - Test typeof for 'undefined'
	c2 = ('undefined' == typeof c2) ? c1 : c2;
	r2 = ('undefined' == typeof r2) ? r1 : r2;
	
	// DTB828 [PFS010] - Cells now indexed by absolute value, do not apply any offset
	r1 = parseInt(r1)
	r2 = parseInt(r2)

	var proxy = new zenProxy();
	var ok = this.GetSlicerSpecForCells(proxy,this.cubeKey,this.queryKey,r1,c1,r2,c2,allRows,allCols,this.sortColumn,this.sortDir);
	// JMD1394 if query has been deleted; re-execute.
	if (proxy.nokey) {
		this.executeQuery(true);
		return '';
	}

	if (!ok) {
		alert(proxy.error);
	}
	else {
		filter = proxy.filter;
	}
	
	return filter;
}

/// Get the slicer spec for the given cell within the query result and place it into the proxy object.
/// Return true, if ok.
ClassMethod GetSlicerSpecForCells(pSpec As %ZEN.proxyObject, pCubeName As %String, pQueryKey As %String, pStartRow As %Integer, pStartCol As %Integer, pEndRow As %Integer = "", pEndCol As %Integer = "", pAllRows As %Boolean = 0, pAllCols As %Boolean = 0, pSortCol As %Integer = 0, pSortDir As %String = "ASC") As %Boolean [ ZenMethod ]
{
	Set:pEndCol="" pEndCol = pStartCol
	Set:pEndRow="" pEndRow = pStartRow
	Set pSortCol = +pSortCol

	// re-open existing query
	Set tRS = ##class(%DeepSee.ResultSet).%New()
	Set tSC = tRS.%PrepareKey(pCubeName,pQueryKey)
	If $$$ISERR(tSC) {
		// JMD1394 tell the client that the query has been deleted
		Set pSpec.nokey = 1
		Set pSpec.error = $System.Status.GetOneErrorText(tSC)
		Quit 0
	}

 	// JMD1347 use %GetFiltersForCellRange
	Set tSC = tRS.%GetFiltersForCellRange(.tFilters,pStartRow,pStartCol,pEndRow,pEndCol,.tMsr,+pAllRows,+pAllCols,pSortCol,pSortDir)
	If $$$ISERR(tSC) {
		Set pSpec.error = $System.Status.GetOneErrorText(tSC)
		Quit 0
	}

	Set tSlicer = ""
	Set k = $O(tFilters(""))
	While (k'="") {
		Set tSlicer = tSlicer _ "%FILTER " _ tFilters(k) _ " "
		Set k = $O(tFilters(k))
	}
	Set pSpec.filter = tSlicer
	Quit 1
}

/// Check on the status of the given query.
/// Return true, if ok.
ClassMethod GetQueryStatus(pObject As %ZEN.proxyObject, pCubeName As %String, pQueryKey As %String, pKPI As %String = "") As %Boolean [ ZenMethod ]
{
	Set tOK = 1
	Set pObject.queryPending = 0
	// JMD1339 report error
	Set pObject.error = ""

	If (pKPI'="") {
		// JMD900 Get status from KPI (pKPI is the KPI class name)
		Set pObject.queryStatus = 100
		Set pObject.queryComplete = 100

		// take a peek at the cache
		Set tClass = $$$UPPER(pKPI)
		If ((tClass'="")&&(pQueryKey'="")) {
			Set tPctComplete = $G($$$DeepSeeKPIGLVN(tClass,pQueryKey,"pctComplete"),100)
			If (tPctComplete<100) {
				Set pObject.queryStatus = tPctComplete
				Set pObject.queryComplete = tPctComplete
			}
		}
	}
	Else {
		Set tStatus = ##class(%DeepSee.ResultSet).%GetQueryStatus(pCubeName, pQueryKey, .tComplete,.tSC,.tPending)
		Set pObject.queryStatus = tStatus
		Set pObject.queryComplete = tComplete
		Set pObject.queryPending = tPending
		If $$$ISERR(tSC) {
			Set pObject.error = $System.Status.GetErrorText(tSC)
		}
	}
	Quit tOK
}

/// Get the MDX text for the current query.
ClassMethod GetQueryText(pCubeName As %String, pQueryKey As %String, pEncrypt As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tMDX = ""
	// re-open existing query
	Set tRS = ##class(%DeepSee.ResultSet).%New()
	Set tSC = tRS.%PrepareKey(pCubeName,pQueryKey)
	If $$$ISERR(tSC) {
		Set tMDX = $System.Status.GetOneErrorText(tSC)
	}
	Else {
		Set tMDX = tRS.%GetQueryText()
		If (pEncrypt) {
			// DTB611 - Do not run encryption
			// Set tMDX = $ZCVT(tMDX,"O","UTF8")
			// Set tMDX = ##class(%CSP.Page).Encrypt(tMDX)
			Set tSC = $$$ERROR($$$NotImplemented)
			Set tMDX = $System.Status.GetOneErrorText(tSC)
		}
	}
	Quit tMDX
}

Method SetCurrentQueryText(pWhich As %String = "current", pMDX As %String) As %Status [ ZenMethod ]
{
	// + WAL075 -- method added
	Set tSC = $$$OK
	Try {
		// DP-434602 - Revert the chunked storage for the query text in favor of a single property that does
		// not require adding components to the page.
		If (pWhich="resolved") {
			Set ..resolvedQueryText = pMDX
		}
		ElseIf (pWhich="current") {
			Set ..currentQueryText = pMDX
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method GetCurrentQueryText(pWhich As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	
	Try {
		Set tMDX=""
		Set:(pWhich="") pWhich = "current"		// DP-434709 - This needs to be set here, not in the signature
	
		// DP-434602 - QueryText containers now have the text directly set
		If (pWhich="resolved") {
			Set tMDX = ..resolvedQueryText
		}
		ElseIf (pWhich="current") {
			Set tMDX = ..currentQueryText
		}
		ElseIf (pWhich="export") {
			// DTB835 - The export mode pulls directly from the current pivotTable object without truncations, and resolves the text
			Set tRawMDX = ..SynthesizeMDX(.tSC,,,,,,,,,,1)
			If $$$ISERR(tSC) Quit
			
			// Resolve pivot variables
			Kill tVariables
			If (..cubeName'="") {
				// DTB572 - Always assemble the list of available variables
				Set tSC = ##class(%DeepSee.Utils).%GetPivotVariables(..cubeName,.tVariableList)
				If $$$ISERR(tSC) Quit
				Set vk = $O(tVariableList(""))
				While (vk'="") {
					Set tVName = $$$LOWER($LG(tVariableList(vk),1))
					Set tVDefValue = $LG(tVariableList(vk),3)
					Set tVariables(tVName) = tVDefValue
					Set tVRuntime = ..pivotVariables.GetAt(tVName)
					Set:tVRuntime'="" tVariables(tVName) = tVRuntime
					Set vk = $O(tVariableList(vk))
				}
			}
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tRawMDX,.tVariables,.tMDX)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		// DTB835 - Return text of errors in the return string
		Set tMDX = $system.Status.GetErrorText(tSC)
	}
	
	Quit tMDX
}

/// Cancel the query specified by <var>pCubeName</var> and  <var>pQueryKey</var>.
/// Return true, if ok.
ClassMethod KillQuery(pCubeName As %String, pQueryKey As %String, pNonce As %String) As %Boolean [ ZenMethod ]
{
	Set tOK = 1
	If (pQueryKey="") {
		// query is still setting up; set cancel global
		If (pNonce'="") {
			Set ^DeepSee.Cancel(pNonce) = ""
		}
	}
	Else {
		// query is already running
		Set tSC = ##class(%DeepSee.ResultSet).%CancelQuery(pCubeName, pQueryKey)
		If $$$ISERR(tSC) {
			Set tOK = 0
		}
	}
	Quit tOK
}

ClientMethod showIKnowMeasureValue(cubeName, measure, objId) [ Language = javascript ]
{
	var parms = {
			CUBE:cubeName,
			MEASURE:measure,
			OBJIDS:objId
			};
			
	zenLaunchPopupWindow('_iKnow.DeepSee.UI.MeasureValue.zen',measure,'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Execute the listing for a drillthrough query and save it to a cache global.<br/>
/// If <var>pSQLRS</var> is provided, use it.
Method %MaterializeListing(pRS As %DeepSee.ResultSet, pSQLRS As %SQL.StatementResult = "") As %Status [ Internal ]
{
	// JMD1331
	Set tSC = $$$OK
	Try {
		If (..listingType = "map") {
			Quit
		}

		Set tDayNo = +$H
		If (..listingKey="") {
			Set ..listingKey = $I($$$DeepSeeListingResultsGLVN(tDayNo))
		}
		Set tPivotNo = ..listingKey

		// if we are on a different "page" of existing results, we can use the cached values
		If ($D($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo))&&(..currListingPage>0)) {
			Quit
		}

		If (..currListingPage<1) {
			Set ..currListingPage = 1
		}

		Kill $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo)

		// listing is written to $$$DeepSeeListingResultsGLVN(DAY,PIVOT#)
		// ...("rows",row#) = $LB(row)
		// ...("cols",col#) = $LB(colName,ODBCtype,style)

		Set tStart = $ZH
		Set $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"lastExec") = $ZDT($H,3)
		Set:$IsObject(pRS) $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"sql") = pRS.%GetListingSQL()

		If $IsObject(pSQLRS) {
			// use sql result set provided by caller
			Set tRS = pSQLRS
			Set tListingFields = ""
		}
		Else {
			// make sure listing is executed
			// these sizes are ignored for page=1;
			// which is the only case we should ever see!
			Set pRS.listingPage = ..currListingPage
			Set pRS.listingPageSize = ..listingPageSize

			Set tSC = pRS.%ExecuteListing()
			If $$$ISERR(tSC) Quit

			// use SQL result set to get answers
			Set tSC = pRS.%GetListingResultSet(.tRS,.tListingFields)
			If $$$ISERR(tSC) Quit
		}

		// JMD987: get information from result set after exec
		Set ..listingRowCount = +..%ResultSet.listingRows
		Set tFormatList = $S($IsObject(pRS):pRS.listingFormatList,1:"")

		Set tColumnMeta = tRS.%GetMetaData().columns
		If (tListingFields = "") {
			Set tColCount = tColumnMeta.Count()
		}
		Else {
			Set tColCount = $LL(tListingFields)
		}

		Merge tColIndex=tRS.%GetMetaData().columnIndex
		// headers
		kill tIKLinkCols
		For c = 1:1:tColCount {
			If (tListingFields = "") {
				Set tColInfo = tColumnMeta.GetAt(c)
				Set tColName = tColInfo.colName
			} Else {
				set tColName = $LG(tListingFields,c)
				Set tColInfo = tColumnMeta.GetAt($LG(tColIndex($$$UPPER(tColName)),1))
			}
			Set tColStyle = $P(tFormatList,"^",c)
			
			Set $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"cols",c) = $LB(tColName,tColInfo.ODBCType,tColStyle)
		}

		// get results
		Set tRow = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tRow = tRow + 1
			Set tRowData = ""
			For c = 1:1:tColCount {
				If (tListingFields = "") {
					Set tValue = tRS.%GetData(c)
				}
				Else {
					Set tValue = tRS.%Get($LG(tListingFields,c))
				}
				Set $List(tRowData,c) = tValue
			}
			If ('..listingRows)||(tRow<=..listingRows) {
				// DTB924 - Only materialize rows that can ultimately be displayed in the listing!
				Set $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"rows",tRow) = tRowData
			}
			Else {
				Quit
			}
		}
		If $$$ISERR(tSC) Quit

		Set $$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"xecTime") = $ZH - tStart

		Set ..listingRowCount = +..%ResultSet.listingRows

		#; JMD1318 recompute actual listingSize
		If (tRow <..listingRowCount) {
			Set ..listingRowCount = tRow
		}
		// + WAL138 -- needed for KPIs since they don't set ..listingRowCount
		//             anywhere else. If it remains 0 paging doesn't work
		// WAL257 && SK -- if condition more permissive to handle custom SQL listings as well
		If ((..listingRowCount<tRow) && (tRow <= ..listingRows)) { // WAL257 (2) -- respect max
			Set ..listingRowCount = tRow	
		}
		ElseIf (tRow > ..listingRows ) { // WAL257 (2) -- report correct number of records if truncating
			Set ..listingRowCount = ..listingRows
			// + WAL309 -- this case means that the user has not configured a max listing row number for this pivot 
			If (..listingRows="") {
				If (tRow>=..#MAXLISTINGROWS) {
					Set ..listingRowCount = ..#MAXLISTINGROWS 
				}
				Else {
					Set ..listingRowCount = tRow		
				}
			}
			// - WAL309
		}
		// - WAL138
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the listing table for a drillthrough query.<br/>
/// Assume the listing has been materialized to a listing global.
Method %DrawListing() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set hlpAll = $$$Text("Select or unselect all items","%DeepSee")
		
		Set ..singleTable = 0 // WAL106

		#; message box
		&html<<div id="#(..%MakeId("message"))#" class="dsPivotMessage" style="display: none;">&nbsp;</div>>

		#; Use divs to layout 2 tables
		#; (plus status area on the bottom)
		&html<<div class="dsptOuterDiv" id="#(..%MakeId("outerDiv"))#">>

		If (..listingType = "map") {
			// do not show table
			// show a neutral message in case this is visible
			Write "<div style=""padding:10px; color: #808080;"">",$$$Text("Formatting results..."),"</div>"
			Write "</div>"
			Quit
		}

		// get column meta data from cache
		Set tDayNo = +$H
		Set tPivotNo = ..listingKey

		If ((tPivotNo="")||'$D($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo))) {
			Write "<div style=""padding:10px;padding-top:50px;color:#804040;"">",$$$Text("Unable to find listing results..."),"</div>"
			Write "</div>"
		}

		Set tColCount = 0
		Set c = $O($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"cols",""),1,tInfo)
		While (c'="") {
			Set tColCount = tColCount + 1
			Set tColName(c) = $LG(tInfo,1)
			Set tColStyle(c) = $LG(tInfo,3)

			#; type--> 2:float,4:integer,12:string,8:double ???
			Set tColClass(c) = $Case($LG(tInfo,2),2:"number",4:"number",8:"number",:"")

			Set c = $O($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"cols",c),1,tInfo)
		}

		If (..showQuery) {
			&html<<textarea rows="3" style="width:100%;margin-top:40px;">>
			Write $ZCVT($G($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"sql")),"O","HTML")
			&html<</textarea>>
		}

		// + WAL299 -- check for no data, adjust styling to show column headers in this case
		Set tOffset = (..currListingPage-1)*(..listingPageSize)
		Set r = $O($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"rows",""))
		Set n = 0
		Set tNoData=1
		For tRowNo = (tOffset+1):1:(tOffset+..listingPageSize) {
			Set tRowData = $G($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"rows",tRowNo))
			If (tRowData="") Quit
			Set n = n+1
		}
		Set:n>0 tNoData=0
		// - WAL299

		// show checkboxes?
		Set tShowCB = (..listingSelect'="")
		Set tHdrStyle = ""
		If (..columnHeaderStyle'="") {
			Set tHdrStyle = tHdrStyle_..columnHeaderStyle
		}
		Else {
			Set:tNoData tHdrStyle = "width:20px;"  // WAL299
		}
		Set tNumStyle = "style="_$$$quote("text-align:center;"_tHdrStyle)
		Set:tNoData tHdrStyle = tHdrStyle_"width:100px;"  // WAL299

		#; top table: column headers
		&html<<div class="dsptTopRightDiv" id="#(..%MakeId("topRightDiv"))#">>

		&html<<table id="#(..%MakeId("topTable"))#" border="0" cellpadding="0" cellspacing="0" class="dsListingTable">>
		&html<<tr>>
		If (..listingSelect = "multi") {
			&html<<th width="1" class="dsListingColumn" id="#(..%MakeId("col_"_1_":"_1))#" style="#(tHdrStyle)#"><div class="dsptListCellDiv"><input type="checkbox" id="#(..%MakeId("cb_all"))#" title="#(hlpAll)#" onclick="zenPage.getComponent(#(..index)#).allClick(event);"/></div></th>>
		}
		ElseIf (tShowCB) {
			&html<<th width="1" class="dsListingColumn" id="#(..%MakeId("col_"_1_":"_1))#" style="#(tHdrStyle)#"><div class="dsptListCellDiv">&nbsp;</div></th>>
		}
		&html<<th class="dsListingColumn" id="#(..%MakeId("col_"_1_":"_2))#" #(tNumStyle)#><div class="dsptListCellDiv">#</div></th>>

		// headers
		kill tIKLinkCols
		For c = 1:1:tColCount {

			Set tCls = $S(..listingSortColumn=c:"dsListingColumnSort",1:"dsListingColumn")
			Set tSortChar = $S(..listingSortColumn=c:$S(..listingSortDir="DESC":"&#x25BC;",1:"&#x25B2;"),1:"")
			Set tXStyle = $S($G(tColStyle(c))["display:none;":"display:none;",1:"")

			// BDB296: check if this is an $$$IKLINK column (prefixed with ___IKLINK)
			set tColName = tColName(c)
			set:$p(tColName," ",1)="___IKLINK" tColName = $p(tColName," ",2,999), tIKLinkCols(c) = tColName

			// apply align to inner div
			Set tDivStyle = ""
			Set tTestStyle = $TR(tHdrStyle," ","")
			If ((tTestStyle["text-align:left;")) {
				Set tDivStyle = "text-align:left;"
			}
			If (tTestStyle["text-align:center;") {
				Set tDivStyle = "text-align:center;"
			}
			Set tIStyle = ""
			Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)

			&html<<th class="#(tCls)#" style="#(tHdrStyle_tXStyle)#" id="#(..%MakeId("col_"_1_":"_(c+2)))#" ondblclick="zenPage.getComponent(#(..index)#).listingHeaderDblClickHandler(event,#(c)#);"><div class="dsptListCellDiv" #(tIStyle)#>#($ZCVT(tColName,"O","HTML"))# #(tSortChar)#</div></th>>
		}
		&html<</tr>>
		&html<</table>>

		&html<</div>>

		// show results (for current page)
		&html<<div class="dsptBottomRightDiv" id="#(..%MakeId("bottomRightDiv"))#">>
		&html<<table id="#(..%MakeId("dataTable"))#" border="0" cellpadding="0" cellspacing="0" class="dsListingTable">>

		Set tOffset = (..currListingPage-1)*(..listingPageSize)
		Set r = $O($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"rows",""))
		Set n = 0
		For tRowNo = (tOffset+1):1:(tOffset+..listingPageSize) {
			Set n = n + 1
			Set tRowData = $G($$$DeepSeeListingResultsGLVN(tDayNo,tPivotNo,"rows",tRowNo))
			If (tRowData="") Quit
			Set tRowValue = $LG(tRowData)	// use first column

			&html<<tr id="#(..%MakeId("tr_"_n))#" rowno="#(n)#" value="#($ZCVT(tRowValue,"O","HTML"))#" class="#($S(n#2:"oddRow",1:"evenRow"))#">>
			If (tShowCB) {
				&html<<td id="#(..%MakeId("cell_"_n_"_"_1))#"><div class="dsptListCellDiv"><input type="checkbox" id="#(..%MakeId("cb_"_n))#" onclick="zenPage.getComponent(#(..index)#).cbClick(event,this);"/></div></td>>
			}
			&html<<td style="text-align:right;width:2.0em;" id="#(..%MakeId("cell_"_n_"_"_2))#"><div class="dsptListCellDiv">#(n+tOffset)#&nbsp;</div></td>>
			For c = 1:1:tColCount {
				Set tValue = $LG(tRowData,c)
				If $ListValid(tValue) {
					// DP-408396 - Convert list data to a comma-delimited string for display
					Set tValue = $ListToString(tValue,", ",3)		// DP-411542 - Make sure data containing the delimiter is quoted
				}
				
				Set tCls = $S(tColClass(c)="":"",1:"class="""_tColClass(c)_"""")

				// BDB296: if this is an iKnow measure column, show the link
				if ($d(tIKLinkCols(c), tColName)) {
					set tValue = "<a href=""#"" onclick=""zenPage.getComponent("_..index_").showIKnowMeasureValue("_tValue_");""><img style=""height:16px;"" src=""deepsee/ds2_magnify_44.png"" title="""_tColName_""" /></a>"
				} else {
					set tValue = $ZCVT(tValue,"O","HTML")
				}
				// JMD1023
				Set:tValue="" tValue="&nbsp;"

				// apply align to inner div
				Set tDivStyle = ""
				Set tTestStyle = $TR($G(tColStyle(c))," ","")
				//+ MES001 Changed if to elseif
				If ((tTestStyle["text-align:left;")) {
					Set tDivStyle = "text-align:left;"
				}
				ElseIf (tTestStyle["text-align:center;") {
					Set tDivStyle = "text-align:center;"
				}
				ElseIf ((tCls["number") || (tTestStyle["text-align:right;")) {
					Set tDivStyle = "text-align:right;"
				}
				//- MES001
				Set tIStyle = ""
				Set:tDivStyle'="" tIStyle = "style="_$$$quote(tDivStyle)
				&html<<td #(tCls)# style="#($G(tColStyle(c)))#" id="#(..%MakeId("cell_"_n_"_"_(c+2)))#" nowrap="1"><div class="dsptListCellDiv" #(tIStyle)#>#(tValue)#</div></td>>
			}
			&html<</tr>>
		}
		If $$$ISERR(tSC) Quit

		&html<</table>>
		&html<</div>>

		#; status area
		#; JMD1313: show buttons if we need to
		Set tPageCount = (..listingRowCount \ ..listingPageSize) + $S(..listingRowCount#..listingPageSize:1,1:0)
		If (..showStatus || (tPageCount>1)) {
			&html<<div class="dsptStatusDiv" id="#(..%MakeId("statusDiv"))#">>
			Set tSC = ..%DrawStatusArea(tPageCount,"listing")
			&html<</div>> // outer
		}

		// outer div
		&html<</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Show execution plan for the query
Method %ShowPlan(pRS As %DeepSee.ResultSet) As %Status
{
	Set tSC = $$$OK
	Try {
		// make sure listing is executed
		Set tSC = pRS.%GetPlan(.tPlan)
		If $$$ISERR(tSC) Quit

		&html<<div style="overflow:auto; height:100%; width:100%;">>
		Set tKey = $O(tPlan(""))
		Do ..%ShowPlanItem(.tPlan, tKey)
		&html<<br/></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Show one item in a query plan.
Method %ShowPlanItem(ByRef pPlan, pNodeNo As %Integer, pLevel As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tType = $LG(pPlan(pNodeNo),1)
		Set tParm = $LG(pPlan(pNodeNo),2)
		Set tParm2 = $LG(pPlan(pNodeNo),3)
		Set tText = ""
		Set tBgColor = "white"
		If (tType="query") {
			Set tText = "<b>Query execution plan:</b><hr/><span style=""color:#404040;"">"_$ZCVT(tParm,"O","HTML")_"</span>"
		}
		ElseIf (tType="subquery") {
			Set tText = "<b>Execute subquery:</b><hr/><span style=""color:#404040;"">"_$ZCVT(tParm,"O","HTML")_"</span>"
		}
		ElseIf (tType="consolidate") {
			Set tText = "<b>Consolidate answers</b>"
			Set tBgColor = "#E0E0F0"
		}
		ElseIf (tType="execA") {
			Set tText = "<b>Compute cell values in parallel</b><hr/>"_(tParm*tParm2)_"&nbsp;("_tParm_" x "_tParm2_")&nbsp;"_"Tasks"
		}
		ElseIf (tType="exec") {
			Set tText = "<b>Compute cell values</b><hr/>"
		}
		ElseIf (tType="listing") {
			Set tText = "<b>Execute listing query:</b><hr/><span style=""color:#404040;"">"_$ZCVT(tParm,"O","HTML")_"</span>"
		}
		ElseIf (tType="dim") {
			Set tText = "<b>Execute dimension query: ("_tParm2_")</b><hr/><span style=""color:#404040;"">"_$ZCVT(tParm,"O","HTML")_"</span>"
		}
		Else {
			Set tText = tType
		}

		&html<<div class="dsptPlanItem" style="background:#(tBgColor)#; width:#(800-((pLevel+2)*20))#px; margin-top:10px; margin-left:#((pLevel+2)*20)#px;">#(tText)#</div>>

		Set tChild = $O(pPlan(pNodeNo,"ch",""))
		While (tChild'="") {
			Do ..%ShowPlanItem(.pPlan, tChild, pLevel + 1)
			Set tChild = $O(pPlan(pNodeNo,"ch",tChild))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Click on an item label within the filter dropdown.
ClientMethod filterLabelClick(evt, filterValue) [ Language = javascript ]
{
	var ctrl = this._cbIndex[(''==filterValue)?' ':filterValue];
	ctrl.checked = !ctrl.checked;
	this.filterItemClick(evt,filterValue);
}

/// Push the current state of the pivot onto the "history" stack.
ClientMethod pushState() [ Internal, Language = javascript ]
{
	if (null == this._history) {
		this._history = new Array();
		this._historyStack = 0;
	}

	var state = new Object();
	state.rowAxisOptions = this.rowAxisOptions.clone();
	state.columnAxisOptions = this.columnAxisOptions.clone();

	// override spec
	state.overrideRowSpec = this.overrideRowSpec;
	state.overrideRowText = this.overrideRowText;
	state.overrideColumnSpec = this.overrideColumnSpec;
	state.overrideColumnText = this.overrideColumnText;

	state.rowLevels = new Array();
	for (n = 0; n < this.rowLevels.length; n++) {
		state.rowLevels[n] = this.rowLevels[n].clone();
	} 
	state.columnLevels = new Array();
	for (n = 0; n < this.columnLevels.length; n++) {
		state.columnLevels[n] = this.columnLevels[n].clone();
	} 
	state.filters = new Array();
	for (n = 0; n < this.filters.length; n++) {
		state.filters[n] = this.filters[n].clone();
	} 
	state.measures = new Array();
	for (n = 0; n < this.measures.length; n++) {
		state.measures[n] = this.measures[n].clone();
	} 
	state.drillLevels = new Array();
	state.drillRowNumbers = new Array(); // WAL224
	for (n = 0; n < this.drillLevels.length; n++) {
		state.drillLevels[n] = this.drillLevels[n].clone();
		state.drillRowNumbers[n] = this.drillRowNumbers[n]; // WAL224
	} 
	state.listingFilters = new Array();
	for (n = 0; n < this.listingFilters.length; n++) {
		state.listingFilters[n] = this.listingFilters[n].clone();
	} 

	state.isDrillThrough = this.isDrillThrough;
	state.selectedRange = this.selectedRange;
	this._history[this._historyStack] = state;
	this._historyStack++;
}

/// Pop the current state of the pivot from the "history" stack.
ClientMethod popState() [ Internal, Language = javascript ]
{
	if (null == this._history || this._historyStack == 0) {
		return;
	}
	this._historyStack--;
	var state = this._history[this._historyStack];

	this.rowAxisOptions = state.rowAxisOptions.clone(true);
	this.columnAxisOptions = state.columnAxisOptions.clone(true);

	// override spec
	this.overrideRowSpec = state.overrideRowSpec;
	this.overrideRowText = state.overrideRowText;
	this.overrideColumnSpec = state.overrideColumnSpec;
	this.overrideColumnText = state.overrideColumnText;

	this.rowLevels = new Array();
	for (n = 0; n < state.rowLevels.length; n++) {
		this.rowLevels[this.rowLevels.length] = state.rowLevels[n].clone(true);
	} 

	this.columnLevels = new Array();
	for (n = 0; n < state.columnLevels.length; n++) {
		this.columnLevels[this.columnLevels.length] = state.columnLevels[n].clone(true);
	} 

	this.filters = new Array();
	for (n = 0; n < state.filters.length; n++) {
		this.filters[this.filters.length] = state.filters[n].clone(true);
	}

	this.measures = new Array();
	for (n = 0; n < state.measures.length; n++) {
		this.measures[this.measures.length] = state.measures[n].clone(true);
	}

	this.drillLevels = new Array();
	this.drillRowNumbers = new Array(); // WAL224
	for (n = 0; n < state.drillLevels.length; n++) {
		this.drillLevels[this.drillLevels.length] = state.drillLevels[n].clone(true);
		// WAL224 -- remember which row should be selected after returning from drill down
		this.drillRowNumbers[this.drillRowNumbers.length] = state.drillRowNumbers[n];
	}
	this.listingFilters = new Array();
	for (n = 0; n < state.listingFilters.length; n++) {
		this.listingFilters[this.listingFilters.length] = state.listingFilters[n].clone(true);
	}

	if (state.isDrillThrough) {
		this.selectedRange = state.selectedRange;
		this.isDrillThrough = true;
		this.executeListing();
	}
	else {
		if (this.isDrillThrough) {
			this.mdx = '';
			this.isDrillThrough = false;
		}
		this.executeQuery(true);
	}

	// JMD1362
	this.updateController();

	if (zenPage.UpdateFilterControls) {
		var msg = zenPage.UpdateFilterControls(this.cubeName,zen('filterGroup'),this);
		if (''!==msg) {
			alert(msg);
		}
	}
}

/// Copy the (most of the) current state of another pivot into this one.
/// Used by linked pivots.
ClientMethod copyState(master) [ Internal, Language = javascript ]
{
	this.rowLevels = new Array();
	for (n = 0; n < master.rowLevels.length; n++) {
		this.rowLevels[this.rowLevels.length] = master.rowLevels[n].clone(true);
	} 

	this.columnLevels = new Array();
	for (n = 0; n < master.columnLevels.length; n++) {
		this.columnLevels[this.columnLevels.length] = master.columnLevels[n].clone(true);
	} 

	/*
	this.filters = new Array();
	for (n = 0; n < master.filters.length; n++) {
		this.filters[this.filters.length] = master.filters[n].clone(true);
	}
	*/

	this.measures = new Array();
	for (n = 0; n < master.measures.length; n++) {
		this.measures[this.measures.length] = master.measures[n].clone(true);
	}

	this.drillLevels = new Array();
	this.drillRowNumbers = new Array();
	for (n = 0; n < master.drillLevels.length; n++) {
		this.drillLevels[this.drillLevels.length] = master.drillLevels[n].clone(true);
		// WAL224 -- remember which row should be selected after returning from drill down
		this.drillRowNumbers[this.drillRowNumbers.length] = master.drillRowNumbers[n];
	}
}

/// Indicate if there are any formatting rules in play.
ClientMethod hasFormatRules() [ Language = javascript ]
{
	return (this.colorScale || (this.formatRules && this.formatRules.length > 0)) ? true : false;
}

/// Indicate if we can go back to a prior state.
ClientMethod canGoBack() [ Language = javascript ]
{
	return this._historyStack ? true : false;
}

/// Go back to the previous state.
ClientMethod goBack(notify) [ Language = javascript ]
{
	this.pushState();
	this._historyStack--;
	this.popState();
	if (notify) {
		zenInvokeCallbackMethod(this.ondrill,this,'ondrill','pivot',this);
	}
}

/// Indicate if we can go forward to a visited state.
ClientMethod canGoForward() [ Language = javascript ]
{
	if (null == this._history || null == this._history[this._historyStack+1]) {
		return false;
	}
	return true;
}

/// Go forward to the next state (if there is one).
ClientMethod goForward() [ Language = javascript ]
{
	if (null == this._history || null == this._history[this._historyStack+1]) {
		return;
	}
	this._historyStack += 2;
	this.popState();
}

/// Clear the (shadow) modified bit for the data property.
Method %ClearDataModified() [ CodeMode = objectgenerator, Internal ]
{
#if ($p($p($p($ZV,") ",2)," ",1),".",1))>=2011
	Do %code.WriteLine(" Set s%data = 0")
#else
	Set tModBit = $P($$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSinstancevar,"data",$$$cIVARslot),",")
	Do %code.WriteLine(" Set $zobjmod(,/*data*/"_tModBit_")=0")
#endif
	Quit $$$OK
}

/// Set the (shadow) modified bit for the data property.
Method %SetDataModified() [ CodeMode = objectgenerator, Internal ]
{
#if ($p($p($p($ZV,") ",2)," ",1),".",1))>=2011
	Do %code.WriteLine(" Set s%data = 1")
#else
	Set tModBit = $P($$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSinstancevar,"data",$$$cIVARslot),",")
	Do %code.WriteLine(" Set $zobjmod(,/*data*/"_tModBit_")=1")
#endif
	Quit $$$OK
}

/// Render the JSON content of the target object
/// along with the other properties of the provider.
Method %OnDrawObjectProperties() [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Write "// JSON: OnDrawObjectProperties",!
		Write "o.data = "
		Set tSC = ..%DrawJSON()
		Write ";",!

		// clear modbit so that we don't later update content
		Do ..%ClearDataModified()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	}
}

/// Render the JSON content of the target object
/// along with the other properties of the provider.
Method %OnObjectSynch() As %Status [ Internal ]
{
	Set tSC = $$$OK
	// if user has set or modified the target object
	// then update the client content

	// DEBUG OUTPUT
	If (0) {
		Set io = $io
		Set tFile = "c:/temp/json.txt"
		Open tFile:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,tFile)
		Use tFile
		Set tSC = ..%DrawJSON()
		Use io
		Close tFile
	}

	Write "// JSON: %OnObjectSynch",!
	Write "o.data = "
	Set tSC = ..%DrawJSON()
	Write ";",!
	
	// raise notification that new data is present
	Write "zenPage.getComponent("_..index_").newDataHandler();",!

	// clear modbit so that we don't later update content
	Do ..%ClearDataModified()
	Quit tSC
}

/// Draw JSON output for the current query results.
Method %DrawJSON() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (..kpi'="") {
			Set tSC = ..%OutputJSONForKPI()
			Quit
		}

		// JMD: if there is no result set then it could be that there is a request
		// to refresh this component without rendering its HTML
		// Try to recreate the result set in that case

		If '$IsObject(..%ResultSet) {
			If (..queryKey '= "") {
				// re-open existing query
				Set tRS = ##class(%DeepSee.ResultSet).%New()
				Set tRS.%Recompute = 0
				Set ..%ResultSet = tRS
				Set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
				Set ..%ResultSet = tRS
			}
		}

		If '$IsObject(..%ResultSet) {
			Write "null"
		}
		ElseIf (..%ResultSet.%IsDrillThrough()) {
			If (..listingType="map") {
				// write out JSON data for geolisting
				Set tSC = ..%OutputJSONForGeoListing(..%ResultSet)
			}
			Else {
				If (..showPivot) {
					Write "null"
				}
				Else {
					// write out JSON data for listing
					Set tSC = ..%OutputJSONForGeoListing(..%ResultSet)
				}
			}
		}
		Else {
			Set tDrillCount = ..drillLevels.Count()
			Set nr = 0
			Set tLevel = ..rowLevels.GetAt(1)
			While $IsObject(tLevel) {
				If (tLevel.drillLevel = tDrillCount) {
					Set tRowCaptions($I(nr)) = tLevel.caption
				}
				Set tLevel = tLevel.childLevels.GetAt(1)
			}
			Set tSC = ..%ResultSet.%OutputJSON(..pageSize,..currPage,.tRowCaptions,..jsonRows)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tText = $System.Status.GetOneErrorText(tSC)
		Write "'",$ZCVT(tText,"O","JS"),"'"
	}
	Quit tSC
}

/// Draw JSON output for a geolisting.
Method %OutputJSONForGeoListing(pRS As %DeepSee.ResultSet, pSQLRS As %SQL.StatementResult = "") As %Status [ Internal ]
{
	// n.b. zu(144) does not handle quotes correctly for JS!
#define JS(%x) $S($IsValidNum(%x):+%x,1:""""_$ZCVT(%x,"O","JS")_"""")

	Set tSC = $$$OK
	Try {
		If $IsObject(pSQLRS) {
			// use sql result set provided by caller
			Set tRS = pSQLRS
			Set tListingFields = ""
		}
		Else {
			// make sure listing is executed
			Set tSC = pRS.%ExecuteListing()
			If $$$ISERR(tSC) Quit

			// use SQL result set to get answers
			Set tSC = pRS.%GetListingResultSet(.tRS,.tListingFields)
			If $$$ISERR(tSC) Quit
		}

		Set tColumnMeta = tRS.%GetMetaData().columns
		If (tListingFields = "") {
			Set tColCount = tColumnMeta.Count()
			For c = 1:1:tColCount {
				Set tColInfo = tColumnMeta.GetAt(c)
				Set tPropName(c) = tColInfo.colName
			}
		}
		Else {
			Set tColCount = $LL(tListingFields)
			For c = 1:1:tColCount {
				Set tColInfo = tColumnMeta.GetAt(c)
				Set tPropName(c) = $LG(tListingFields,c)
			}
		}
		
		// !!! compute range of map !!!

		Write "{"
		Write "_isListing:true,"
		Write "axes:[],"
		Write "rows:[],"

		Write "listingRows:[",!

		// loop over results
		Set n = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Write:n>0 ","
			Write "{"
			Set n = n + 1
			For c = 1:1:tColCount {
				If (tListingFields = "") {
					Set tValue = tRS.%GetData(c)
				}
				Else {
					Set tValue = tRS.%Get($LG(tListingFields,c))
				}

				Write:c>1 ","

				// check for valid prop names
				Set tProp = tPropName(c)
				Set tProp = $Translate(tProp," %'+-*/""$#@^&","_")

				Write tProp,":",$$$JS(tValue),!
			}
			Write "}",!
		}

		Write "]",!
		Write "}",!

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tText = $System.Status.GetOneErrorText(tSC)
		Write "'",$ZCVT(tText,"O","JS"),"'"
	}
	Quit tSC
}

/// Draw JSON output for the current KPI class.
Method %OutputJSONForKPI() As %Status [ Internal ]
{
#define JS(%x) $S($IsValidNum(%x):+%x,1:""""_$ZCVT(%x,"O","JS")_"""")

	Set tSC = $$$OK
	Try {
		If '$IsObject(..%KPIController) {
			Write "null"
			Quit
		}
		Set tController = ..%KPIController
		If ('$IsObject(tController)) {
			Write "null"
			Quit
		}

		Set tRowCount = tController.dataBag.seriesCount
		Set tModel = tController.%model

		If ('$IsObject(tModel)) {
			Write "null"
			Quit
		}

		Set tSC = ..%GetKPIColumns(tController,.tColCount,.tColProps,..columnList)
		If $$$ISERR(tSC) Quit

		Write "{"
		Write "cubeName:",$$$JS(..kpi),",",!
		Write "cubeClass:",$$$JS(..kpi),",",!
		Write "axes:[",!

		// column axis
		Write "{",! // axis object
		//Write "key:",$$$JS(tAxisKey),",",!
		Write "tuples:[",!
		Set n = 0

		For c=1:1:tColCount {
			Set tCaption = $S($D(tColProps(c,"caption")):tColProps(c,"caption"),1:$G(tColProps(c)))
			Write:c>1 ","
			Write "{" // tuple object
			Write "caption:",$$$JS(tCaption)
			Write "}",! // tuple object
		}

		Write "]",! // tuples

		Write "}",! // axis object

		// row axis
		Write ",{",! // axis object
		//Write "key:",$$$JS(tAxisKey),",",!

		Write "tuples:[",!
		For tRow = 1:1:tRowCount {
			Write:tRow>1 ","
			Write "{" // tuple object
			Write "caption:",$$$JS($G(tModel.%seriesNames(tRow)))
			Write "}",! // tuple object
		}

		Write "]",! // tuples

		Write "}",! // axis object


		Write "],",! // axes

		// data

		// JMD1227: simplify JSON for data
		// fastest way is to not use pure JSON!
		// instead, define an array of known-size and explicitly insert values into it.
		// data is written out as [R1C1,R1C2,R1C3,R2C1,R2C2,R2C3]
		// write out size of data;
		// this allows us to use 1 array for all data values

		Write $$$ZENJSPAIR("rowCount",tRowCount),",",!
		Write $$$ZENJSPAIR("columnCount",tColCount),",",!

		Write """cells"":[],",!

		Write "status:",$$$JS(100),! // last property
		Write "}"

		// JMD1227: violate JSON rules for speed's sake:
		Write ";",!

		// cells
		Write "var a = new Array(",tRowCount*tColCount,");",!
		Write "o.data.cells = a;",!
		Set tCellCount = 0
		For tRow=1:1:tRowCount {
			For c=1:1:tColCount {
				Set tProp = tColProps(c)
				Set tValue = tController.dataBag.%GetValue(tProp,tRow)
				Set:tValue=$$$ZENMISSING tValue = ""
				Write "a["_tCellCount_"]="_$$$ZENJSVALUE(tValue)_";",!
				Set tCellCount = tCellCount + 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "/*"
		Do $System.OBJ.DisplayError(tSC)
		Write "*/"
	}
	Quit tSC
}

ClientMethod getContent() [ Final, Internal, Language = javascript ]
{
	return this.data;
}

/// Send an event to all listeners (dataViews) connected to this dataController.
/// <var>reason</var> is the name of the event.<br>
/// <var>source</var>, if not null, if the dataView that raised the event.<br>
/// <var>data1</var>,<var>data2</var>, and <var>data3</var> contain event-specific data passed along with the event.<br>
ClientMethod sendEventToViews(reason, source, data1, data2, data3) [ Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			if (this._listeners[n] && (this._listeners[n]!=source)) {
				this._listeners[n].notifyView(reason,data1,data2,data3);
			}
		}
	}
}

/// Internal method.<br>
/// Establish a connection between this pivotTable and a chart component
ClientMethod register(component) [ Final, Internal, Language = javascript ]
{
	// + WAL259
	if(null == this._registeredCounter) {
		this._registeredCounter = 1;
	}
	else {
		this._registeredCounter += 1;
	}
	// - WAL259
	if (null == this._listeners) {
		this._listeners = new Array();
	}
	this._listeners[this._listeners.length] = component;
}

/// Internal method.<br>
/// Break the a connection between this pivotTable and a chart component
ClientMethod unregister(component) [ Final, Internal, Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			// + WAL083 (5) -- check *this* item not the last one
			if (this._listeners[n] == component) { 
			//if (this._listeners[this._listeners.length] == component) {
			// - WAL083 (5)
				this._listeners.splice(n,1);
				break;
			}
		}
	}
}

/// Send notification to listeners that the data associated with this pivotTable has changed.<br/>
ClientMethod raiseDataChange() [ Final, Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			if (this._listeners[n]) {
				this._listeners[n].notifyView('dataChange',null);
			}
		}
	}
}

/// Return number of dimensions in this pivot.
ClientMethod getDimensions() [ Internal, Language = javascript ]
{
	return 2;
}

/// Return the number of items in the specified dimension
/// (<var>dim</var> is 1,2, or 3).
ClientMethod getDimSize(dim) [ Final, Language = javascript ]
{
	var size = 0;
	var data = this.getContent();
	switch (dim) {
	case 1:
		size = data ? data.rowCount : 0;
		// JMD1462 limit chart size
		var maxChartSize = this.maxChartSize;		// DTB384 - Use the pivot setting
		if (maxChartSize>0) {
			size = size>maxChartSize ? maxChartSize : size;
		}
		break;
	case 2:
		size = data ? data.columnCount : 0;
		break;
	}
	return size;
}

/// Special method: return if the given dimension has hierarchical groupings
/// (to indicate that a chart should display them).
ClientMethod getDimGrouping(dim) [ Final, Internal, Language = javascript ]
{
	var ret = false;
	var data = this.getContent();
	if (!data) return false;

	switch (dim) {
	case 1:
		var axis = data.axes[1];
		break;
	case 2:
		var axis = data.axes[0];
		break;
	}
	if (axis) {
		ret = axis.hasGroups ? true : false;
	}
	return ret;
}

/// This is a specialized variant of <method>getData</method> that
/// return the data in this controller as an array of arrays (used by charts).
ClientMethod getDataAsArrays() [ Final, Language = javascript ]
{
	var array = null;
	var data = this.getContent();
	if (data) {
		var items = data.rowCount;
		var series = data.columnCount;

		if (series) {
			array = new Array(series);
			for (var s = 0; s < series; s++) {
				array[s] = new Array(items);
				for (var i = 0; i < items; i++) {
					var idx = (i*series) + s;
					array[s][i] = data.cells[idx];
				}
			}
		}
	}
	return array;
}

/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim, noformat) [ Final, Language = javascript ]
{
	try {
		var label = '';
		var data = this.getContent();
		if (!data) {
			return '';
		}
		noformat = zenGet(noformat,false);

		switch (dim) {
		case 1:
			// item name from rows axis
			var axis = data.axes[1];
			if (axis) {
				var tuple = axis.tuples[n];
				label = tuple ? this.computeCaption(tuple,noformat) : 'N/A';		// DTB387 - Add noformat
				if (tuple && tuple.g && axis.groups) {
					// JMD1148 use g
					var group = axis.groups[parseInt(tuple.g,10)];
					while (group) {
						var caption = this.computeCaption(group,noformat);
						if (caption!=='') {
							label = caption + '/' + label;
						}
						if (group.g) {
							group = axis.groups[parseInt(group.g,10)];
						}
						else {
							group = null;
						}
					}
				}
			}
			break;
		case 2:
			// series names from columns axis
			var axis = data.axes[0];
			if (axis) {
				var tuple = axis.tuples[n];
				label = tuple ? this.computeCaption(tuple,noformat) : '';
				// JMD1011
				// JMD1148 use g
				if (tuple && tuple.g && axis.groups) {
					var group = axis.groups[parseInt(tuple.g,10)];
					while (group) {
						var caption = this.computeCaption(group,noformat);
						if (caption!=='') {
							label = caption + '/' + label;
						}
						if (group.g) {
							group = axis.groups[parseInt(group.g,10)];
						}
						else {
							group = null;
						}
					}
				}
				if (label==='') {
					label = data.defaultCaption;
				}
			}
			break;
		}
	}
	catch(ex) {
		alert('Error in pivot.getLabel: ' + ex.message);
	}
	return label;
}

/// Resolve the caption for a given axis item.
/// (This is used to get logical values for time axis members).
ClientMethod computeCaption(item, noformat) [ Final, Internal, Language = javascript ]
{
	noformat = zenGet(noformat,false);

	var caption = (item.caption!=='') ? item.caption : '';
	if (item.type && item.key) {
		switch(item.type) {
		case 'month':
			var year = item.key.toString().substr(0,4);
			var month = item.key.toString().substr(4,2);
			// JMD1263.2
			if (noformat) {
				caption = year + '-' + month;
			}
			else {
				caption = item.caption ? item.caption : year + '-' + month;
			}
			break;
		case 'quarter':
			var year = item.key.toString().substr(0,4);
			var quarter = item.key.toString().substr(4,1);
			var month = (quarter-1) * 3;
			month = (month < 10) ? ('0'+month) : month;
			// JMD1263.2
			if (noformat) {
				caption = year + '-' + month;
			}
			else {
				caption = item.caption ? item.caption : year + '-' + month;
			}
			break;
		case 'day':
			// JMD1263
			if (noformat) {
				caption = this.dateFromHorolog(item.key);
			}
			else { 
				caption = item.caption ? item.caption : this.dateFromHorolog(item.key);
			}
			break;
		}
	}
	return caption;
}

/// Convert a $H to yyyy-mm-dd date.
ClientMethod dateFromHorolog(val) [ Language = javascript ]
{
	if (''!==val && !isNaN(val) && 'NOW' != val) {
		var text = val;
		var days1970 = parseInt(val) - 47117;
		var date = new Date((days1970 * 24 * 3600 * 1000));

		var mon = date.getUTCMonth();
		mon = (mon<9?'0':'') + (mon+1);
		var day = date.getUTCDate();
		day = (day<10?'0':'') + (day);
		var yr = date.getUTCFullYear();
		val = yr+'-'+mon+'-'+day;
	}
	return val;
}

/// Return a name for the given dimension (1,2, or 3).
/// This provides the axis label for a chart.
ClientMethod getDimName(dim) [ Final, Language = javascript ]
{
	var name = '';
	var drillLevel = this.drillLevels.length;
	switch(dim) {
	case 0:
		if (this.overrideRowSpec) {
			name = this.overrideRowText;
		}
		else if (this.rowLevels) {
			// multiple top-level items for rows
			// JMD1148 only show 3 top items at most and nested items
			// JMD1300 test drillLevel
			var nc = 0;
			for (var n = 0; n < this.rowLevels.length; n++) {
				var level = this.rowLevels[n];
				if (level.drillLevel == drillLevel) {
					if (nc++ >= 3) {
						name += '...';
						break;
					}
					var text = level.caption ? level.caption : level.text;
					var childLevel = level.childLevels ? level.childLevels[0] : null;
					while (childLevel) {
						if (childLevel.caption) {
							text = text + ((text=='')?'':'/') + childLevel.caption;
						}
						else if (childLevel.text) {
							text = text + ((text=='')?'':'/') + childLevel.text;
						}
						childLevel = childLevel.childLevels ? childLevel.childLevels[0] : null;
					}
					if (text) {
						name = name + ((name=='')?'':' & ') + text;
					}
				}
			}
		}
		break;
	case 1:
		if (this.overrideColumnSpec) {
			name = this.overrideColumnText;
		}
		else if (this.columnLevels && (this.columnLevels.length == 1)) {
			name = this.columnLevels[0].text;
		}
		break;
	}
	return name;
}

/// Given a 0-based index, return the corresponding property name.
ClientMethod getPropertyName(n) [ Language = javascript ]
{
	return this.getLabel(n,2);
}

/// Return a label for the values returned by the data source.
/// This provides the axis label for a chart.
ClientMethod getValueName() [ Final, Language = javascript ]
{
	if (this.overrideColumnSpec) {
		return this.overrideColumnText;
	}
	else if (this.measures.length==1 && '' != this.measures[0].text) {
		return this.measures[0].text;
	}
	else if (this.columnLevels && (this.columnLevels.length > 0)) {
		// JMD1148
		// return this.columnLevels[0].text;
		// JMD1300
		return $$$Text('Value');
	}
	//return $$$Text('Value');
	// JMD1300
	return this.getLabel(0,2);
}

/// Return a title to display for this data source.
/// This provides the title for a chart.
ClientMethod getDataSourceCaption(which, title) [ Final, Language = javascript ]
{
	var caption = '';
	// test for special title values:
	switch (title) {
	case '$caption':
		caption = this.caption!==''?this.caption:null;
		break;
	/*	
	case '$date':
		// !!!format
		var d = new Date();
		caption = zenDateToString(d,'yyyy-mm-dd');
		break;
	*/

	case '':		
		switch (which) {
		case 'title':
			caption = this.caption;
			break;
		case 'subtitle':
			break;
		}
		break;
	}
	return caption;
}

ClientMethod getDataByName(property, series) [ Language = javascript ]
{
	var value = '';
	var data = this.getContent();
	if (!data) {
		return '';
	}

	series = ('undefined'==typeof series) ? 0 : parseInt(series,10);
	
	// JMD1432 if property is a numeric literal return it as the value
	if (!isNaN(parseFloat(property))) {
		return parseFloat(property);
	}

	// JMD1432 if property is enclosed within =[xxx], remove
	if ((property.toString().substr(0,2)=='=[')&&(property.toString().substr(property.length-1,1)==']')) {
		property = property.substr(2,property.length-3);
	}

	// find column whose caption matches property name
	var colNo = -1;
	var axis = data.axes[0];
	if (axis && axis.tuples) {
		// special case for queries with no columns
		if (axis.tuples.length==1 && axis.tuples[0].caption=='' && property==data.defaultCaption) {
			// get value from first row,column
			colNo = 0;
		}
		else {
			for (var n = 0; n < axis.tuples.length; n++) {
				if (this.getLabel(n,2) == property) {		// DTB559 - Add support for retrieving nested labels and try to match that
					colNo = n;
					break;
				}
			}
		}
	}

	switch (property) {
	case '%rangeUpper':
		// get range from totals (which column !!!)
		if (data.rowTotals && data.rowTotals[0]) {
			value = data.rowTotals[0].max;
			if (value) {
				// round up
				value = Math.pow(10,Math.ceil(Math.log(value)/Math.log(10)));
			}
		}
		break;
	case '%rangeLower':
	case '%thresholdUpper':
	case '%thresholdLower':
		break;

	default:
		// JMD1432
		if (colNo<0) {
			value = property;
		}
		else {
			// get value from cells
			// JMD1219: single array
			var colCount = data.columnCount;
			if (colNo>=0 && colCount) {
				value = data.cells[(series*colCount) + colNo];
			}
		}
		break;
	}

	return value;
}

/// dataSet API
/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var value = '';
	var data = this.getContent();
	if (!data || !data.cells) {
		return '';
	}

	var row = d1;
	var col = (null===d2) ? 0 : d2;
	value = data.cells[(row*data.columnCount) + col];
	return value;
}

/// Return information on current filters.<br/>
/// <var>fnames</var> is an array in which the filter names will be placed.<br/>
/// <var>fvalues</var> is an array in which the filter values will be placed.<br/>
/// <var>flabels</var> is an array in which the filter labels will be placed.<br/>
ClientMethod getFilterInfo(fnames, fvalues, flabels) [ Final, Language = javascript ]
{
	for (var n = 0; n < this.filters.length; n++) {
		var filter = this.filters[n];
		if (('' != filter.key)&&(filter.enabled)) {		// DTB634
			if ('' === filter.caption) {
				// find caption for filter if the caption is missing
				if ('' != filter.baseSpec) {
					// use the baseSpec to look up the caption
					filter.caption = this.GetItemCaption(this.cubeName,filter.baseSpec);
				}
				else if ('' != filter.spec) {
					// DTB858 - If the baseSpec is also missing, attempt to pull the baseSpec from the complete spec
					// and use that to find the caption
					var baseSpec = '';
					var baseSpecArray = filter.spec.split('.').slice(0,-1);
					baseSpec = baseSpecArray.join('.');
					
					filter.caption = this.GetItemCaption(this.cubeName,baseSpec);
				}
			}

			// JMD: for some saved filters, we may not have baseSpec
			// in this case, do not use %OR etc as caption
			if (filter.caption && filter.caption.toString().indexOf('%OR(')<0) {
				fnames[fnames.length] = filter.caption;
				var text = filter.text.toString();
				
				// apply some unescapes to the text!
				var t = text.split('&#160;');
				text = t.join(' ');
				fvalues[fvalues.length] = text;
				
				// DTB551 - Add labels here if requested
				if (flabels) {
					flabels[flabels.length] = ((filter._label) ? filter._label : filter.caption);
				}
			}
		}
	}
	
	if (this.contextFilterSpec) {
		// DTB648 - Parse the context into a collection of cell addresses which can be displayed
		var contextArray = this.ParseMDXExpression(this.contextFilterSpec,this.cubeKey).split('\n');
		
		var counter = 0;
		for (n in contextArray) {
			counter++
			fnames[fnames.length] = $$$Text('Other Filter ') + counter.toString();
			fvalues[fvalues.length] = contextArray[n];
			if (flabels) {
				flabels[flabels.length] = '';
			}
		}
	}
		
	// +DTB115	 
	// If applicable, add information about drill-down filters
	if (this.getDrillLevel()>0) {
		for (var d=0 ; d < this.getDrillLevel() ; d++) {
			// DTB115 - Indicate this came from a drilldown
			fnames[fnames.length] = $$$Text('Drilldown Level','%DeepSee') + ' ' + (d+1);		//DTB309 - Localize label
			fvalues[fvalues.length] = this.drillLevels[d].text;
			if (flabels) {		// DTB648
				flabels[flabels.length] = '';
			}
		}
	}

	// If applicable, add information about cell selection context in a detail listing	
	if ((this.isDrillThrough)&&(this.listingFilters.length)) {		// DTB157 - add condition to test for existence of any listingFilters
		fnames[fnames.length] = '- ' + $$$Text('Selected Cell Context','%DeepSee') + ' -';
		fvalues[fvalues.length] = ' ';
		if (flabels) {		// DTB648
			flabels[flabels.length] = '';
		}
		for (var f=0 ; f < this.listingFilters.length ; f++) {
			fnames[fnames.length] = 'Cell Context ' + f;			// N.B. This is not displayed, and so is not localized
			fvalues[fvalues.length] = this.listingFilters[f].spec;
			if (flabels) {		// DTB648
				flabels[flabels.length] = '';
			}
		}
	}
	// -DTB115
}

/// Parse an MDX clause representing a collection of cell addresses into a $C(10)-delimited list that can be pssed back to the client. This is designed to parse contextual filters.  
ClassMethod ParseMDXExpression(pExpression, pCubeName) As %String [ ZenMethod ]
{
	// Method added by DTB648
	Set tMessage = ""
	
	Try {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%ParseCellSelectionContext(pExpression,pCubeName,.tContextFilters)
		If $$$ISERR(tSC) Quit		// DTB662 - Quit on error
		
		Set tName="" 
		Set tValue=""
		For f=1:1:tContextFilters {
			Set tName = tName _ $S($L(tName):" / ",1:"") _ $LG(tContextFilters(f),1) _ ":" _ $LG(tContextFilters(f),2)
			If '$D(tContextFilters(f,"ch")) {
				// This node contains the end of a chain, add it to the filters as a group
				Set tMessage = tMessage _ $S($L(tMessage):$C(10),1:"") _ tName
				Set tName = ""
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {		
		// DTB662 - Different error reporting
		Set tMessage = $system.Status.GetOneErrorText(tSC)
	}

	Quit tMessage
}

/// Return information on current pivot variables.<br/>
/// <var>pnames</var> is an array in which the variable names will be placed.<br/>
/// <var>pvalues</var> is an array in which the variable values will be placed.<br/>
ClientMethod getPivotVariableInfo(pnames, pvalues) [ Final, Language = javascript ]
{
	// Method added by DTB489
	for (variableName in this.pivotVariables) {
		var pdata = new zenProxy;
		
		// DTB515 - Get the full pivot information on each pivot variable
		pdata = this.GetPivotVariableData(this.cubeName,variableName+'.variable',this.pivotVariables[variableName]);
		
		if (pdata.text) {
			// DTB568 - Only add to the pivot variable array if the value is defined
			pnames[pnames.length] = pdata.caption;
			pvalues[pvalues.length] = pdata.text;
		}
		
		if (pdata.error) {
			// Report a data error if present
			alert(pdata.error)
		}

	}
}

/// Return names and values of current pivot variables.<br/>
/// <var>pnames</var> is an array in which the variable names will be placed.<br/>
/// <var>pvalues</var> is an array in which the variable values will be placed.<br/>
ClientMethod getPivotVariablesValues(pnames, pvalues) [ Final, Language = javascript ]
{
	// Method added by APV020
	for (variableName in this.pivotVariables) {
		var pdata = new zenProxy;
		// DTB515 - Get the full pivot information on each pivot variable
		pdata = this.GetPivotVariableData(this.cubeName,variableName+'.variable',this.pivotVariables[variableName]);	
		if (pdata.value) {
			// DTB568 - Only add to the pivot variable array if the value is defined
			pnames[pnames.length] = variableName;
			pvalues[pvalues.length] = pdata.value;
		}
		
		if (pdata.error) {
			// Report a data error if present
			alert(pdata.error)
		}

	}
}

/// Associate a controller component with this pivotTable.
/// This is called by the controller component.
ClientMethod addController(ctrl) [ Internal, Language = javascript ]
{
	this.controller = ctrl;
}

/// Remove the controller component associated with this pivotTable.
/// This is called by the controller component.
ClientMethod removeController() [ Internal, Language = javascript ]
{
	this.controller = null;
}

/// Update the controller component associated with this pivotTable, if any.
/// This is called internally when the state of the pivot table changes.
ClientMethod updateController() [ Internal, Language = javascript ]
{
	// DP-434472 -  Reinitialize state variables
	this._initialLoad = true;
	this.queryCalls = 0;

	if (this.controller && this.controller.updateState) {
		this.controller.updateState();
	}
}

/// Update the toolbar on the controller component associated with this pivotTable, if any.
/// This is called internally when the state of the pivot table changes.
ClientMethod updateToolbar() [ Internal, Language = javascript ]
{
	if (this.controller && this.controller.updateToolbar) {
		this.controller.updateToolbar();
	}
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..rowAxisOptions = ##class(%DeepSee.Component.pivotLevel).%New()
	Set ..rowAxisOptions.filterEnabled = 0
	Do:$IsObject($G(%page)) %page.%AddComponent(..rowAxisOptions)

	Set ..columnAxisOptions = ##class(%DeepSee.Component.pivotLevel).%New()
	Set ..columnAxisOptions.filterEnabled = 0
	Do:$IsObject($G(%page)) %page.%AddComponent(..columnAxisOptions)

	Quit ##super($G(initvalue))
}

/// Return current drill level for this pivot.
ClientMethod getDrillLevel() [ Language = javascript ]
{
	return this.drillLevels.length;
}

/// Go to the given drill level.
ClientMethod gotoDrillLevel(idx) [ Language = javascript ]
{
	idx = parseInt(idx);
	if (this.drillLevels.length == idx + 1) return;
	this.pushState();
	this.drillLevels.length = idx + 1;

	// remove extra row levels
	for (var n = this.rowLevels.length - 1; n >=0; n--) {
		if (this.rowLevels[n].drillLevel > (idx+1)) {
			this.rowLevels.splice(n,1);
		}
	}

	this.isDrillThrough = false;
	this.selectedRange = '';
	this.sortColumn = 0;
	this.sortDir = 'ASC';
	this.mdx = '';
	var ret = zenInvokeCallbackMethod(this.ondrill,this,'ondrill','pivot',this);
	if (!ret) {
		this.executeQuery(true);
	}
}

/// Remove a drill level. The input parameter <var>idx</var> is the 0-based index of the level to remove.
ClientMethod removeDrillLevel(idx, evt) [ Language = javascript ]
{
	var prevCanDrillDown = this.canDrillDown;
	idx = parseInt(idx);
	this.pushState();
	var drillRowNumber = this.drillRowNumbers.splice(idx,1);
	this.drillLevels.splice(idx,1);
	
	// + WAL224 -- prevent this event from being handled by 
	//             rowClickHandler as well
	//             Some browsers use stopPropagation(), some use
	//             cancelBubble
	// + WAL237 -- check if evt is undefined -- order of args switched
	if (evt !== undefined) {
	    if (typeof evt.stopPropagation != "undefined") {
	        evt.stopPropagation();
	    } else {
	        evt.cancelBubble = true;
	    }
	}
    // - WAL224

	// remove row levels
	for (var n = this.rowLevels.length - 1; n >=0; n--) {
		if (this.rowLevels[n].drillLevel == (idx+1)) {
			this.rowLevels.splice(n,1);
		}
		else if (this.rowLevels[n].drillLevel > (idx+1)) {
			this.rowLevels[n].drillLevel--;
		}
	}
	this.isDrillThrough = false;
	// + WAL224 -- onUpdateHandler will use the range set here
	this.selectedRange = drillRowNumber + ',1,' + drillRowNumber + ',' + this.columnCount + ',0,0';
	//this.selectedRange = '';
	// - WAL224

	this.sortColumn = 0;
	this.sortDir = 'ASC';
	this.mdx = '';
	var ret = zenInvokeCallbackMethod(this.ondrill,this,'ondrill','pivot',this);
	if (!ret) {
		this.executeQuery(true);
	}
	this.canDrillDown = prevCanDrillDown;
}

/// Clear all current drill levels and reset the table back to its resting state.
ClientMethod removeAllDrillLevels() [ Language = javascript ]
{
	// Method added by DTB745
	if ( (this.drillLevels) && (this.drillLevels.length>0) ) {
		// Work backward through the drillLevels and remove each in turn.
		for (var level = (this.drillLevels.length-1) ; level>=0 ; level--) {
			this.removeDrillLevel(level)
		}
	}
}

/// Set the name of the listing (and listing type) to show for this pivot.
ClientMethod setListing(listing, type) [ Language = javascript ]
{
	if (listing) {
		// DTB732 - Only set the pivot's listing if there is something to set!
		this.listing = listing;
	}
	else {
		this.listing = this.defaultListing;		// DTB732 (2) - Reset to default listing if nothing is selected
	}

	if (type=='map' || type == 'table') {
		this.listingType = type;
	}
}

/// Click on all check box (in detail listing).
ClientMethod allClick(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt) {
		if (evt.stopPropagation) {
			evt.stopPropagation();
		}
		else {
			evt.cancelBubble = true;
		}
	}
	var cbAll = this.findElement('cb_all');

	for (var r = 1;;r++) {
		var cb = this.findElement('cb_'+r);
		if (cb) {
			cb.checked = cbAll.checked;
			var tr = this.findElement('tr_'+r);
			if (tr) {
				if (cb.checked) {
					tr.className = 'selectedRow';
				}
				else {
					var rowno = tr.getAttribute('rowno');
					tr.className = rowno%2 ? 'evenRow' : 'oddRow';
				}
			}
		}
		else {
			break;
		}
	}
	zenInvokeCallbackMethod(this.onlistingSelect,this,'onlistingSelect','pivot',this);
}

/// Click on checkbox.
ClientMethod cbClick(evt, currCb) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt) {
		if (evt.stopPropagation) {
			evt.stopPropagation();
		}
		else {
			evt.cancelBubble = true;
		}
	}

	var cbAll = this.findElement('cb_all');
	if (cbAll) {
		cbAll.checked = false;
	}

	for (var r = 1;;r++) {
		var cb = this.findElement('cb_'+r);
		var tr = this.findElement('tr_'+r);
		if (cb && tr) {
			if ('single' == this.listingSelect && cb !== currCb) {
				cb.checked = false;
			}

			if (cb.checked) {
				tr.className = 'selectedRow';
			}
			else {
				var rowno = tr.getAttribute('rowno');
				tr.className = rowno%2 ? 'evenRow' : 'oddRow';
			}
		}
		else {
			break;
		}
	}
	zenInvokeCallbackMethod(this.onlistingSelect,this,'onlistingSelect','pivot',this);
}

/// Click on all check box (in pivot).
ClientMethod allClickPivot(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt) {
		if (evt.stopPropagation) {
			evt.stopPropagation();
		}
		else {
			evt.cancelBubble = true;
		}
	}
	var cbAll = this.findElement('cb_all');

	for (var r = 1;;r++) {
		var cb = this.findElement('cb_'+r);
		if (cb) {
			cb.checked = cbAll.checked;
			var th = this.findElement('row_1:'+r);
			if (th) {
				if (cb.checked) {
					th.style.background = '#B0B0F0';
					this.selectCellRange(r,1,r,this.columnCount,false,true,true);	// DTB101
				}
				else {
					th.style.background = '';
					// DTB101 - unselect this row
					for (var c = 1; c <= this.columnCount; c++) {
						var cell = this.findElement('cell_'+r+'_'+c);
						if (cell) {
							var color = cell._oldColor ? cell._oldColor : '';
							cell.style.color = color;
							var bg = cell._oldBackground ? cell._oldBackground : '';
							cell.style.background = bg;
						}
					}	
				}
			}
		}
		else {
			break;
		}
	}
}

/// Click on checkbox in pivot.
ClientMethod cbClickPivot(evt, currCb) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt) {
		if (evt.stopPropagation) {
			evt.stopPropagation();
		}
		else {
			evt.cancelBubble = true;
		}
	}
	var cbAll = this.findElement('cb_all');
	if (cbAll) {
		cbAll.checked = false;
	}
	for (var r = 1;;r++) {
		var cb = this.findElement('cb_'+r);
		var tr = this.findElement('tr_'+r);
		if (cb && tr) {
			if ('single' == this.pivotSelect && cb !== currCb) {
				cb.checked = false;
			}
			
			var th = this.findElement('row_1:'+r);
			if (cb.checked) {
				th.style.background = '#B0B0F0';
				this.selectCellRange(r,1,r,this.columnCount,false,true,true);	// DTB101
			}
			else {
				th.style.background = '';
				
				// DTB101 - unselect this row
				for (var c = 1; c <= this.columnCount; c++) {
					var cell = this.findElement('cell_'+r+'_'+c);
					if (cell) {
						var color = cell._oldColor ? cell._oldColor : '';
						cell.style.color = color;
						var bg = cell._oldBackground ? cell._oldBackground : '';
						cell.style.background = bg;
					}
				}						
			}
		}
		else {
			break;
		}
	}
}

/// Return an array of the values of the selected items in the pivot table.
/// For listing mode, this is the set of ids for the selected rows.
/// For pivot mode, this is the values of the value column for each selected row.
ClientMethod getSelectedItems() [ Language = javascript ]
{
	var cellSelection = this.selectedRange.split(',');
	
	// DTB898 - If the pivot is in drillthrough mode, the 'tr'/'dtr' elements will have paged IDs 1-100. If the pivot is displaying
	// the MDX resultset, these elements have absolute-position IDs which will be captured in the selectedRange.
	var firstRow = this.isDrillThrough ? 1 : cellSelection[0];
	
	var array = new Array();
	for (var r = firstRow;;r++) {		// DTB898 - Use the start point which works in both MDX and drillthrough mode
		// NB: Since this traverses the currently visible DOM, this loop should never execute more than 100 times (pivotTable pageSize)
		var cb = this.findElement('cb_'+r);
		var tr = this.findElement('tr_'+r);
		var dtr = this.findElement('dtr_'+r);
		
		// +DTB101 - For each row of the table, determine if it is a "selected item"
		// This could be defined by: 
		//  - cell selection in a pivot
		//  - check box selection in a pivot (overrides cell selection)
		//  - check box selection in a listing
		if (tr||dtr) {	 
			if (cb) {	
				// Use check boxes if they are present, ignore the selection
				if (cb.checked) {
					if ((''!=this.valueColumn) || (this.isDrillThrough)) {
						// In a listing valueColumn has no meaning
						var value = dtr ? dtr.getAttribute('value') : tr.getAttribute('value');
					}
					else {
						// There is no column defined as the valueColumn, use the seriesName
						var div = tr.getElementsByTagName('div');
						var value = div[0].innerText;	// tr should contain only one div
					}
					array[array.length] = value;
					if ('single' == this.listingSelect) {
						break;
					}
				}
			}
			else if (!this.isDrillThrough) {	// pivot mode
				// Use cell selection to obtain row values for execution of a KPI listing. 
				if ('' != this.selectedRange) { 
					var inSelectedRange = ((r >= cellSelection[0]) && (r <= cellSelection[2]));
				}
				else {
					var inSelectedRange = false;
				}

				if (inSelectedRange) {
					if (''!=this.valueColumn) {
						var value = dtr ? dtr.getAttribute('value') : tr.getAttribute('value');
					}
					else {
						// there is no column defined as the valueColumn, use the seriesName
						var div = tr.getElementsByTagName('div');
						// DTB202 - Use cross-browser read statement
						var value = div[0].innerText || div[0].textContent;	// tr should contain only one div
						if ('\n'==value[0]) {
							// DTB202 - Remove newLine prepended by FireFox!
							value = value.slice(1,value.length);
						}
						value = value.trim();
					}
					array[array.length] = value;
				}
			}
		}
		else {
			// no more rows to process in the current table
			break;
		}
		// -DTB101
	}
	return array;
}

/// Notification that new data is available.
ClientMethod newDataHandler() [ Language = javascript ]
{
	delete this._rowDescriptors;
	delete this._columnDescriptors;
	this.computeTotals();
}

/// Compute row and columns totals, as needed.
ClientMethod computeTotals() [ Language = javascript ]
{
	var data = this.getContent();
	if (!data) return;

	if (!this.rowTotals && !this.columnTotals) return;
	this.rowTotalAgg = this.rowTotalAgg=='' ? 'sum' : this.rowTotalAgg;
	this.columnTotalAgg = this.columnTotalAgg=='' ? 'sum' : this.columnTotalAgg;

	var gtotal = null;
	var grandTotal = data.grandTotal ? data.grandTotal : 0;

	// JMD1148: compute "page" totals locally; get grand totals from JSON
	if (this.rowTotals && this.rowTotalSource!='all') {
		var colTotals = [];
		var startRow = (parseInt(this.currPage,10)-1) * parseInt(this.pageSize,10);
		var endRow = startRow + parseInt(this.pageSize,10) - 1;
		endRow = endRow>(data.rowCount-1)?(data.rowCount-1):endRow;
		for (var r = startRow; r<=endRow; r++) {
			for (var c = 0; c<data.columnCount; c++) {
				var idx = (r*data.columnCount)+c;
				var val = (null==data.cells[idx]) ? null : parseFloat(data.cells[idx]);
				val = isNaN(val) ? null : val;
				if (null != val) {
					if (null == colTotals[c]) {
						colTotals[c] = {};
					}
					colTotals[c].count = (colTotals[c].count?colTotals[c].count:0) + 1;
					colTotals[c].sum = (colTotals[c].sum?colTotals[c].sum:0) + val;
					colTotals[c].min = (colTotals[c].min&&colTotals[c].min<val?colTotals[c].min:val);
					colTotals[c].max = (colTotals[c].max&&colTotals[c].max>val?colTotals[c].max:val);
				}
			}
		}

		// avg and pct
		for (var c = 0; c<data.columnCount; c++) {
			if (null != colTotals[c]) {
				colTotals[c].avg =(colTotals[c].count?colTotals[c].sum/colTotals[c].count:'');
				colTotals[c].pct =(grandTotal?colTotals[c].sum/grandTotal:'');
			}
		}
	}

	// JMD1148: revise
	if (this.rowTotals) {
		for (var c = 0; c<data.columnCount; c++) {
			var rowTotalAgg = this.rowTotalAgg;
			var td = this.findElement('rtot_'+(c+1));
			var tddiv = this.findElement('rtotd_'+(c+1));
			if (td&&tddiv) {
				// override of agg?
				var agg = td.getAttribute('agg');
				if (agg && agg!=='') {
					rowTotalAgg = agg;
				}
				var fmt = td.getAttribute('format');
				fmt = fmt ? fmt : '#,#';
				if (rowTotalAgg=='pct') {
					fmt = '#,#.##%';
				}
				else if (rowTotalAgg=='count') {
					fmt = '#,#';
				}
				styleObj = { color: '' };
				if (rowTotalAgg=='none') {
					var val = '';
				}
				else if (this.rowTotalSource=='all') {
					var val = (data&&data.columnTotals&&data.columnTotals[c])?data.columnTotals[c][rowTotalAgg] : null;
				}
				else {
					var val = colTotals&&colTotals[c]?colTotals[c][rowTotalAgg]:null;
				}
				
				var disp = ((null!=val)?zenFormatNumber(val,fmt,styleObj):'');
				if (disp.toString().indexOf(')')==-1) {
					disp += '&nbsp;';
				}
				// JMD1462 match data cells
				tddiv.innerHTML = '&nbsp;'+disp+'&nbsp;';
				tddiv.title = val;
				if (styleObj.color && styleObj.color!='') {
					tddiv.style.color = styleObj.color;
				}
			}
		}
	}
	if (this.columnTotals) {
		for (var r = 0; r<data.rowCount; r++) {
			var td = this.findElement('ctot_'+(r+1));
			var tddiv = this.findElement('ctotd_'+(r+1));
			if (td&&tddiv) {
				var columnTotalAgg = this.columnTotalAgg;
				// override of agg?
				var agg = td.getAttribute('agg');
				if (agg && agg!=='') {
					columnTotalAgg = agg;
				}
				var fmt = td.getAttribute('format');
				fmt = fmt ? fmt : '#,#';
				if (columnTotalAgg=='pct') {
					fmt = '#,#.##%';
				}
				else if (columnTotalAgg=='count') {
					fmt = '#,#';
				}
				styleObj = { color: '' };
				//var var = colTotals[r];
				var rIndex = td.getAttribute('row')-1;
				if (columnTotalAgg=='none') {
					var val = '';
				}
				else {
					var val = (data&&data.rowTotals&&data.rowTotals[rIndex])?data.rowTotals[rIndex][columnTotalAgg] : null;
				}
				if (null != val) {
					gtotal = (gtotal?gtotal:0) + val;
				}
				var disp = ((null!=val)?zenFormatNumber(val,fmt,styleObj):'');
				if (disp.toString().indexOf(')')==-1) {
					disp += '&nbsp;';
				}
				// JMD1462 match data cells
				tddiv.innerHTML = '&nbsp;'+disp+'&nbsp;';
				if (styleObj.color && styleObj.color!='') {
					tddiv.style.color = styleObj.color;
				}
			}
		}
	}

	var td = this.findElement('gtot');
	var tddiv = this.findElement('gtotd');
	if (td&&tddiv) {
		var fmt = td.getAttribute('format');
		fmt = fmt ? fmt : '#,#';
		if (this.columnTotalAgg=='pct') {
			fmt = '#,#.##%';
		}
		styleObj = { color: '' };
		
		// + WAL117 -- if we have both row and column totals
		//             and the row totals are for all rows and not just this page,
		//             use the provided grand total number from the JSON data
		if (this.columnTotals&&this.rowTotals&&grandTotal&&(this.rowTotalSource=='all')) {
			gtotal = grandTotal;
		}
		// - WAL117
		
		var disp = ((null!=gtotal)?zenFormatNumber(gtotal,fmt,styleObj):'');
		if (disp.toString().indexOf(')')==-1) {
			disp += '&nbsp;';
		}
		// JMD1462 match data cells
		tddiv.innerHTML = '&nbsp;'+disp+'&nbsp;';
		if (styleObj.color && styleObj.color!='') {
			tddiv.style.color = styleObj.color;
		}
	}
}

/// Parse a CSS style directive and remove any "summary:val" directives within it.
ClassMethod %GetSummaryFromCSS(pStyle As %String, Output pAgg As %String) As %String
{
	Set pAgg=""
	Set tCSS = ""
	For n=1:1:$L(pStyle,";") {
		Set t = $P(pStyle,";",n)
		If (t'="") {
			If ($P(t,":",1)="summary") {
				Set pAgg = $P(t,":",2)
			}
			Else {
				Set tCSS = tCSS _ t_";"
			}
		}
	}
	Quit tCSS
}

/// Return an array of column descriptors for use by a dataGrid connected to this pivot.
ClientMethod getColumnDescriptors() [ Language = javascript ]
{
	var data = this.getContent();
	var isListing = (data && data._isListing);

	if (this._columnDescriptors && this._isListingCol==isListing) {
		return this._columnDescriptors;
	}
	this._isListingCol = isListing;
	var list = [];

	if (isListing) {
		// ORDER, TEST FOR EXIST!!!
		for (var p in data.listingRows[0]) {
			list[list.length] = {caption:p};
		}
	}
	else {

		// build list from pivot data
		if (data && data.axes && data.axes[0]) {
			var groups = data.axes[0].groups;
			if (groups && groups.length) {
				this.processAxisColumns(list,groups,data.axes[0].tuples);
			}
			else {
				// no groups: emit tuples
				for (var t = 0; t < data.axes[0].tuples.length; t++) {
					var caption = data.axes[0].tuples[t].caption;
					list[list.length] = {caption:caption};
				}
			}
		}
	}
	this._columnDescriptors = list;
	return list;
}

/// Convert an axis group to descriptors.
ClientMethod processAxisColumns(list, groups, tuples) [ Internal, Language = javascript ]
{
	for (var n = 0; n < groups.length; n++) {
		var idx = list.length;
		list[idx] = {caption:groups[n].caption};
		if (groups[n].groups) {
			var glist = [];
			list[idx].columns = glist;
			this.processAxisColumns(glist,groups[n].groups,tuples);
		}
		else if (groups[n].tuples) {
			var glist = [];
			list[idx].columns = glist;
			for (var t = 0; t < groups[n].tuples.length; t++) {
				// !!! format !!!
				var caption = tuples[groups[n].tuples[t]-1].caption;
				glist[glist.length] = { caption:caption};
			}
		}
	}
}

/// Return an array of row descriptors for use by a dataGrid connected to this pivot.
ClientMethod getRowDescriptors() [ Language = javascript ]
{
	var data = this.getContent();
	var isListing = (data && data._isListing);

	if (this._rowDescriptors && this._isListingRow == isListing) {
		return this._rowDescriptors;
	}

	this._isListingRow = isListing;

	// build list from pivot data
	var list = [];
	if (isListing) {
		// TEST FOR EXIST!!!
		var maxRows = parseInt(this.listingPageSize);
		for (var n=0;n<maxRows && n<data.listingRows.length; n++) {
			list[list.length] = {caption:n+1};
		}
	}
	else {
		if (data && data.axes && data.axes[1]) {
			var groups = data.axes[1].groups;
			if (groups && groups.length) {
				this.processAxisRows(list,groups,data.axes[1].tuples);
			}
			else {
				// no groups: emit tuples
				for (var t = 0; t < data.axes[1].tuples.length; t++) {
					var caption = data.axes[1].tuples[t].caption;
					list[list.length] = {caption:caption};
				}
			}
		}
	}
	this._rowDescriptors = list;
	return list;
}

/// Convert an axis group to descriptors.
ClientMethod processAxisRows(list, groups, tuples) [ Internal, Language = javascript ]
{
	for (var n = 0; n < groups.length; n++) {
		var idx = list.length;
		list[idx] = {caption:groups[n].caption};
		if (groups[n].groups) {
			var glist = [];
			list[idx].rows = glist;
			this.processAxisRows(glist,groups[n].groups,tuples);
		}
		else if (groups[n].tuples) {
			var glist = [];
			list[idx].rows = glist;
			for (var t = 0; t < groups[n].tuples.length; t++) {
				// !!! format !!!
				var caption = tuples[groups[n].tuples[t]-1].caption;
				glist[glist.length] = { caption:caption};
			}
		}
	}
}

/// Return total number of pages to support dataGrid paging.
ClientMethod getPageSize() [ Internal, Language = javascript ]
{
	return parseInt(this.pageSize);
}

/// Return total number of records to support dataGrid paging.
ClientMethod getRecordCount() [ Internal, Language = javascript ]
{
	var data = this.getContent();
	var isListing = (data && data._isListing);
	if (isListing) {
		return data.listingRows.length;
	}

	return parseInt(this.rowCount,10);
}

/// Number of the current "page" when paging (1-based).
ClientMethod getCurrPage() [ Internal, Language = javascript ]
{
	return parseInt(this.currPage);
}

/// Set the current "page" when paging (1-based).
ClientMethod setCurrPage(page) [ Internal, Language = javascript ]
{
	this.gotoPage(page);
}

/// Return an array of row captions (shown above headers).
ClientMethod getRowCaptions() [ Internal, Language = javascript ]
{
	// + WAL241 -- if populated, use rowCaptionList
	if (this.rowCaptionList.length > 0) {
		return this.rowCaptionList;
	}
	// - WAL241
	var rowCaptions = [];
	var data = this.getContent();
	if (data && data.rowCaptions) {
		rowCaptions = data.rowCaptions;
	}
	return rowCaptions;
}

/// Notification that a listing header is double-clicked.<br/>
ClientMethod showAllRows() [ Language = javascript ]
{
	this.crossJoinRowLimit = 0;
	if (this.previewMode) {
		// DTB714 - Remove calls to the zenPage. Pivot actions only effect the pivot display.
		this.previewMode = !this.previewMode;
		this.executeQuery(true);
	}
	else {
		this.executeQuery(true);
	}
}

/// Return the ordinal number of the dimension supplying property names for this controller.
ClientMethod getPropertyDim() [ Language = javascript ]
{
	return 2;
}

/// Retrieves the meta data about the pivot variable and can convert the logical value
/// display value.
ClassMethod GetPivotVariableData(pCubeName, pVariableName, pValue = "") As %ZEN.proxyObject [ ZenMethod ]
{
	// Method added by DTB515
	Set tData = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(pCubeName,$P(pVariableName,".",1,*-1),.tPivotVariableInfo)
		If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		
		Set tData.value = pValue		// Default to the incoming value
		Set tData.text = pValue			// DTB550 - Default Text value as well
		Set tData.type = tPivotVariableInfo("type")
		Set tData.caption = tPivotVariableInfo("displayName")
		Set tData.name = tPivotVariableInfo("name")
		
		Set tData.caption = $G(tPivotVariableInfo("displayName"))
		If (tData.caption="") {
			Set tData.caption = $G(tPivotVariableInfo("name"),pVariableName)
		}
		
		// DTB550 - Prepare the value for translation to a human-readable display value
		If ($E(pValue,1,4)="%NOT") {
			Set tIsNot = 1
			Set pValue = $E(pValue,6,*)
		}
		
		// Examine the incoming value and see if there is a display value
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pValue,.tInfo)
		If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		
		Set tTermCount = $O(tInfo(""),-1)
		If ((tTermCount>1)&&($G(tInfo(2))=":")) {
			// Value is a range
			If (tPivotVariableInfo("type")="day") {
				Set tValue = ##class(%DeepSee.Time.DayMonthYear).%KeyToValue(tInfo(1)) _ ":" _ 
							##class(%DeepSee.Time.DayMonthYear).%KeyToValue(tInfo(3))
				Set tData.text = $S($G(tIsNot):$$$Text("NOT","%DeepSee")_" "_tValue,1:tValue)	// DTB550 - Add NOT back in
			}
		}
		Else {
			// Single item or a set
			Set tTerm = $G(tInfo(1))		// DTB568
			If (tPivotVariableInfo("type")="day") {
				Set tValue = ##class(%DeepSee.Time.DayMonthYear).%KeyToValue(tTerm)
			}
			Else {
				Set tValue = tTerm
			}
			Set tData.text = $S($G(tIsNot):$$$Text("NOT","%DeepSee")_" "_tValue,1:tValue)		// DTB550 - Add NOT back in
		}
	}
	Catch ex {
		Set tData.error = $system.Status.GetOneErrorText(ex.AsStatus())
	}

	Quit tData
}

/// Build the current MDX query text from the current contents of this component
Method SynthesizeMDX(Output pSC As %Status, ByRef pRS As %DeepSee.ResultSet, ByRef pParms, ByRef pFilterInfo, ByRef pAdvancedFilters, Output pQueryText As %String, Output pAxes, Output pDataReady As %Boolean, Output pComplexQuery As %Boolean, pExecuteBaseQuery As %Boolean = 0, pShowAll As %Boolean = 0) As %String [ ZenMethod ]
{
	// Method added by DTB595
	Set tSC = $$$OK
	Set tMDX = ""
	
	Try {
		Set tSC = ..%GetFilterInfo(.pFilterInfo,.pAdvancedFilters)
		If $$$ISERR(tSC) Quit
		
		Set pComplexQuery = 0
		Set pQueryText = ""
		Set tMeasureCount = 0
		Set tSingleSimpleMeasure = 0

		Set tCubeName = $$$ZENVAL(..cubeName)
		
		Set pRS = ##class(%DeepSee.ResultSet).%New()

		// construct query
		Set tSELECT = ""
		Set tSLICER = ""
		Set tWITH = ""
		Set tShowTotals = 0

		If (..userMDX="") {
			Set tCountName = ##class(%DeepSee.Utils).%GetCountName(tCubeName,.tSC)

			// WITH clause if any
			For n = 1:1:..calculatedMembers.Count() {
				Set tCalcMbr = ..calculatedMembers.GetAt(n)
				Set tDimName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(tCalcMbr.dimension)
				Set tMemberName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(tCalcMbr.memberName)
				If ((tDimName'="")&&(tMemberName'="")) {
					// DTB158 - Escape identifiers before quoting 
					Set tWITH = tWITH _ " MEMBER ["_$$$dsEscapeIdent(tDimName)_"].["_$$$dsEscapeIdent(tMemberName)_"] AS '" _ tCalcMbr.valueExpression _ "'"
				}
				If (tCalcMbr.formatString'="") {
					Set tWITH = tWITH _ ",FORMAT_STRING='"_$Replace(tCalcMbr.formatString,"'","''")_"'"
				}
				If (+tCalcMbr.solveOrder>0) {
					Set tWITH = tWITH _ ",SOLVE_ORDER="_tCalcMbr.solveOrder
				}
			}

			Set:tWITH'="" tWITH = " WITH " _ tWITH _ " "
		}

		Set tWHERE = ..%GetWhereClause(.pFilterInfo)
		
		// JMD1013: use %FILTER
		// JMD1360: gather all filters into one list
		Set:tWHERE'="" tFilterClauses($I(tFilterClauses)) = tWHERE

		If (..userMDX="") {
			Do ..%CountMeasures(.tMeasureCount,.tComputedMeasures)

			// DTB208 - Removed section of code setting 
			//  tSingleSimpleMeasure
			//  tSingleCalcMeasure
			//  tMultipleMeasures
			// that is overridden by WAL114 below.				
		}
		
		// + WAL114 -- override tests so that tMultipleMeasures is always true
		//             this means that the measure will always be added to the axis
		//             specified in measure location and will never be in the slicer
		//             or on axis 2
		Set tSingleSimpleMeasure = 0
		Set tSingleCalcMeasure = 0
		Set tMultipleMeasures = 1
		// - WAL114
		
		// built filters from drill levels
		Set tDrillLevel = 0
		For n = 1:1:..drillLevels.Count() {
			Set tDrill = ..drillLevels.GetAt(n)
			If $IsObject(tDrill) {
				Set tFSpec = tDrill.spec
				If (tFSpec '= "") {
					Set tDrillLevel = tDrillLevel + 1
					Set:tFSpec'="" tFilterClauses($I(tFilterClauses)) = tFSpec
				}
			}
		}

		// add more filters for advanced filters
		Set n = $O(pAdvancedFilters(""))
		While (n'="") {
			Set tFSpec = $LG(pAdvancedFilters(n),2)
			If (tFSpec="%FILTER") {
				// lookup filter spec
				Set tFName = $LG(pAdvancedFilters(n),3)
				Set tSC = ##class(%DeepSee.Utils).%GetNamedFilterInfo(tCubeName,tFName,.tNFilterInfo)
				Set tFSpec = $G(tNFilterInfo("spec"))
			}
			ElseIf (tFSpec["$NAMEDFILTER") {
				// DTB516 - Remove the $NAMEDFILTER tag and leave the actual spec
				Set tFSpec = $Replace(tFSpec,"$NAMEDFILTER.","")
			}

			If (tFSpec'="") {
				// if this is a named filter, then its spec will be "%FILTER"
				Set:tFSpec'="" tFilterClauses($I(tFilterClauses)) = tFSpec
			}
			Set n = $O(pAdvancedFilters(n))
		}

		// JMD993
		// if drillthrough, add listing filters, create drillthrough query
		If (..isDrillThrough) {
			// Collect the current listingFilters
			Set tChunkedSpec = ""
			For n = 1:1:..listingFilters.Count() {
				Set tLFilter = ..listingFilters.GetAt(n)
				If tLFilter.%IsA("%DeepSee.Component.queryChunk") {
					// DTB783 - There might be a set of queryChunk items representing one larger statement.
					Set tChunkedSpec = tChunkedSpec _ tLFilter.chunkText
				}
				ElseIf $IsObject(tLFilter) {
					Set tFSpec = tLFilter.spec
					If (tFSpec '= "") {
						Set:tFSpec'="" tFilterClauses($I(tFilterClauses)) = tFSpec
					}
				}
			}
			
			Set:(tChunkedSpec'="") tFilterClauses($I(tFilterClauses)) = tChunkedSpec		// DTB783
			
			Set tMaxRows = ""
			If (+..listingRows>0) {
				Set tMaxRows = " MAXROWS "_..listingRows
			}

			If (..contextFilterSpec '= "") {
				If ($E(..contextFilterSpec,1,8)="%FILTER ") {
					Set tFilterClauses($I(tFilterClauses)) = $E(..contextFilterSpec,8,*)
				}
				Else {
					Set tFilterClauses($I(tFilterClauses)) = ..contextFilterSpec
				}
			}
			
			// +DTB107
			// This method is called if the queryKey is not cached when
			// called from %DrawHTML. Gather the cell selection filters in the
			// context of this base query
			If pExecuteBaseQuery {

				Set tBaseRS = ##class(%DeepSee.ResultSet).%New()
				Set tSC = tBaseRS.%PrepareMDX(..GetCurrentQueryText())
				If $$$ISERR(tSC) {
					Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (1)"
					Quit
				}
				
				Set tSC = tBaseRS.%ExecuteAsynch(,.pParms)		// DTB704 - Always use %ExecuteAsynch		// DTB868 - Execute with avialable parms

				If $$$ISERR(tSC) {
					Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (1)"
					Set ..error = ..%message			// DTB150
					Quit
				} 
				
				// create drill through out of current query
				Set r1 = +$P(..selectedRange,",",1)
				Set c1 = +$P(..selectedRange,",",2)
				Set r2 = +$P(..selectedRange,",",3)
				Set c2 = +$P(..selectedRange,",",4)
				Set tAllRows = +$P(..selectedRange,",",5)
				Set tAllCols = +$P(..selectedRange,",",6)
				Set:r1=0 r1=1
				Set:c1=0 c1=1
				Set:r2=0 r2=r1
				Set:c2=0 c2=c1
				
				// Use a temporary listing filter array for the cell selection
				// + WAL170
				Set tSC = tBaseRS.%GetFiltersForCellRange(.tCellSelectionFilters,r1,c1,r2,c2,,tAllRows,tAllCols,..sortColumn,..sortDir,.tPlugInInfo)
				If ($G(tPlugInInfo("NAME"))'="") Set pRS.%PlugInContextName = tPlugInInfo("NAME")
				If ($G(tPlugInInfo("PROP"))'="") Set pRS.%PlugInContextProp = tPlugInInfo("PROP")
				// - WAL170
				If $$$ISERR(tSC) {
					Set:..%message="" ..%message = $System.Status.GetErrorText(tSC) _ " (1)"
					Quit
				}
				
				// +DTB108
				// Check the slicer term in the user query.
				// If it contains $$CMBR keys, remove this term and reconstruct 
				// the executable slicer terms from the original query text
				If ($G(tCellSelectionFilters(0))["$$CMBR") {		// DTB117 - protect with $G()
					Kill tCellSelectionFilters(0)
					Set tTempRS = ##class(%DeepSee.ResultSet).%New()
					Set tSC = tTempRS.%ParseMDX(..GetCurrentQueryText(),.tTempQuery)
					For ii= 1:1:tTempQuery.filters.Count() {
						Set tFilterClauses($I(tFilterClauses)) = tTempQuery.filters.GetAt(ii).%ToString()
					}
					Kill tTempRS
				}
				// -DTB108
				
				// Transfer to the full list of filter clauses
				Set c = $O(tCellSelectionFilters(""))
				While c'="" {
					Set tFilterClauses($I(tFilterClauses)) = tCellSelectionFilters(c)
					Set c = $O(tCellSelectionFilters(c))
				}
				
				// + WAL170
				Merge pRS.%PlugInFilters = tFilterClauses
				// - WAL170
			}
			// -DTB107

			Set tSLICER = ""
			Set k = $O(tFilterClauses(""),1,tClause)
			While (k'="") {
				// DTB107 - emulate JMD1211: quick workaround for some listing issues
				// ignore any unprocessed CMBRS
				If (tClause'["$$CMBR") {
					Set tSLICER = tSLICER _ " %FILTER " _ tClause
				}
				Set k = $O(tFilterClauses(k),1,tClause)
			}
			
			Set tMDX = "DRILLTHROUGH"_tMaxRows_tWITH_" SELECT FROM [" _ $$$dsEscapeIdent(##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(tCubeName)) _ "]" _ tSLICER		// DTB130 - generated query text should never show a version number

			// check for custom field list
			Set tRETURN = "$LISTING"
			If ((..listing="$$$CUSTOM")&&(..listingFields.Count()>0)) {
				Set tRETURN = ""
				For lf=1:1:..listingFields.Count() {
					Set tSpec = ..listingFields.GetAt(lf).spec
					Set tAlias = ..listingFields.GetAt(lf).caption		// DTB509
					Set tRETURN = tRETURN _ $S(tRETURN="":"",1:",") _ tSpec
					
					Set tSpecHasAlias = ($L(tSpec," ")>1)&'($E($ZSTRIP(tSpec,"<>W"),*)=")")		// DTB508 - New test for alias
					If ((tAlias'="")&&'tSpecHasAlias) {
						Set tRETURN = tRETURN _ " """ _ tAlias _ """"
					}
				}
			}

			If (..listingSortColumn>0) {
				Set tMDX = tMDX _ " RETURN "_tRETURN_" %ORDER BY " _ ..listingSortColumn _ " " _ ..listingSortDir
			}
			ElseIf (tRETURN'="$LISTING") {
				Set tMDX = tMDX _ " RETURN "_tRETURN
			}
			
			// Save query in MDX so that SavePivot will remember the drilldown state
			Set ..mdx = tMDX
		}
		ElseIf (..userMDX'="") {
			Do ..listingFilters.Clear()

			// JMD1031
			Set tSLICER = ""
			Set k = $O(tFilterClauses(""))
			While (k'="") {
				Set tSLICER = tSLICER _ " %FILTER " _ tFilterClauses(k)
				Set k = $O(tFilterClauses(k))
			}
			Set tMDX = ..userMDX_tSLICER
		}
		Else {
			Do ..listingFilters.Clear()
			Set tMsrClause = ""

			// if more than one measure, create msrClause and add to columns or rows
			// JMD1462 if no columns, put measure into columns
			If ((tMeasureCount>0) && (tMultipleMeasures || (..columnLevels.Count()=0)||(..rowLevels.Count()=0))) {		// DTB141 - use new tMultipleMeasures test
				Set:(tMeasureCount>1) tMsrClause = "{"					// DTB117
				For n = 1:1:tMeasureCount {
					Set tMsr = ..measures.GetAt(n)
					Set tMsrSpec = tMsr.spec
					If (tMsr.aggFunction'="") {
						Set tMsrSpec = tMsrSpec _ "." _ tMsr.aggFunction
					}
					If ((tMsr.levelCaption'="")||(tMsr.levelFormat'="")||(tMsr.levelStyle'="")||(tMsr.levelHeaderStyle'="")||(tMsr.levelSummary'="")) {
						Set tMsrSpec = "%LABEL("_tMsrSpec_","_$$$quote(tMsr.levelCaption)_","_$$$quote(tMsr.levelFormat)
						// JMD: tack summary onto style
						Set tLevelStyle = tMsr.levelStyle
						Set:(tMsr.levelSummary'="") tLevelStyle = tLevelStyle_"summary:"_tMsr.levelSummary_";"
						Set:(tLevelStyle'="") tMsrSpec = tMsrSpec _ ",,"_ $$$quote(tLevelStyle)
						Set:(tMsr.levelHeaderStyle'="") tMsrSpec = tMsrSpec _ $S((tMsr.levelStyle=""):",,,",1:",") _ $$$quote(tMsr.levelHeaderStyle)
						Set tMsrSpec = tMsrSpec _ ")"
					}
					Set tMsrClause = tMsrClause _ $S(n>1:",",1:"") _ tMsrSpec
				}
				Set:(tMeasureCount>1) tMsrClause = tMsrClause _ "}"		// DTB117
			}

			// JMD1148
			If (..overrideColumnSpec'="") {
				Set:'..showEmptyColumns tSELECT = "NON EMPTY "
				Set tSELECT = tSELECT _ ..overrideColumnSpec _ " ON 0"
			}
			ElseIf (tMultipleMeasures&&(..measureLocation'="rows")&&(..columnLevels.Count()=0)&&(tMsrClause'="")) {		// DTB141 - use new tMultipleMeasures test
				Set tSELECT = tSELECT _ tMsrClause _ " ON 0"
			}
			ElseIf (..columnLevels.Count()>0) {
				Set:'..showEmptyColumns tSELECT = tSELECT _ "NON EMPTY "
				Set tClause = ..%GetAxisClauseFromLevels(..columnLevels,..showEmptyColumns,.tComplexQuery,,,pShowAll)		// DTB835
				// n.b. ignore complex query on the columns side

				If ($IsObject(..columnAxisOptions)) {
					// apply SET functions, if any
					If (..columnAxisOptions.filterEnabled) {
						Set tClause = "FILTER(" _ tClause
						Set tExpr = ..columnAxisOptions.filterExpression
						Set:tExpr="" tExpr = "1"

						Set tClause = tClause _ "," _ tExpr
						Set tClause = tClause _ ")"
					}

					If (..columnAxisOptions.orderEnabled && '..columnAxisOptions.suppress8020) {
						Set tClause = "ORDER(" _ tClause
						Set tExpr = ..columnAxisOptions.orderExpression
						Set:tExpr="" tExpr = "MEASURES.["_tCountName_"]"

						Set tDirection = ..columnAxisOptions.orderDirection
						Set:tDirection="" tDirection = "BDESC"

						Set tClause = tClause _ "," _ tExpr
						Set tClause = tClause _ "," _ tDirection
						Set tClause = tClause _ ")"
					}
					If (..columnAxisOptions.headEnabled) {
						Set tClause = "HEAD(" _ tClause
						Set:((+..columnAxisOptions.headCount)>1) tClause = tClause _ "," _ ..columnAxisOptions.headCount
						Set tClause = tClause _ ")"
					}
					If (..columnAxisOptions.aggEnabled && (..columnAxisOptions.aggFunction'="")) {
						If (($$$UPPER(..columnAxisOptions.aggFunction)="PERCENTILE") && (..columnAxisOptions.aggFunctionParm'="")) {
							// make sure 2nd argument is present!
							Set tClause = ..columnAxisOptions.aggFunction _ "(" _ tClause _ ",,"_..columnAxisOptions.aggFunctionParm_ ")"
						}
						ElseIf (($$$UPPER(..columnAxisOptions.aggFunction)="COUNT NONEMPTY")) {
							Set tClause = "COUNT(" _ tClause _ ",EXCLUDEEMPTY)"
						}
						Else {
							Set tClause = ..columnAxisOptions.aggFunction _ "(" _ tClause _ ")"
						}
					}

					// JMD916
					If (..columnAxisOptions.suppress8020) {
						// JMD1293: apply sort order
						Set tSortExpr = ""
						Set tF1 = "TOPPERCENT"
						Set tF2 = "BOTTOMPERCENT"
						If (..columnAxisOptions.orderEnabled) {
							Set tSortExpr = ..columnAxisOptions.orderExpression
							If (..columnAxisOptions.orderDirection="BASC") {
								Set tF1 = "BOTTOMPERCENT"
								Set tF2 = "TOPPERCENT"
							}
						}
						Set:tSortExpr'="" tSortExpr = ","_tSortExpr
						Set tClause = "{"_tF1_"(" _ tClause _ ",80"_tSortExpr_"),%LABEL(SUM("_tF2_"(" _ tClause _ ",20"_tSortExpr_")),"""_$$$Text("Other","%DeepSee")_""",,,,""font-style:italic;"")}"
					}

					If ((..columnAxisOptions.levelCaption'="")||(..columnAxisOptions.levelFormat'="")||(..columnAxisOptions.levelStyle'="")||(..columnAxisOptions.levelHeaderStyle'="")||(..columnAxisOptions.levelSummary'="")) {
						Set tClause = "%LABEL(" _ tClause _ ","_ $$$quote(..columnAxisOptions.levelCaption) _ ","_ $$$quote(..columnAxisOptions.levelFormat)
						// JMD: tack summary onto style
						Set tLevelStyle = ..columnAxisOptions.levelStyle
						Set:(..columnAxisOptions.levelSummary'="") tLevelStyle = tLevelStyle_"summary:"_..columnAxisOptions.levelSummary_";"
						Set:(tLevelStyle'="") tClause = tClause _ ",,"_ $$$quote(tLevelStyle)
						Set:(..columnAxisOptions.levelHeaderStyle'="") tClause = tClause _ $S((..columnAxisOptions.levelStyle=""):",,,",1:",")_ $$$quote(..columnAxisOptions.levelHeaderStyle)
						Set tClause = tClause _ ")"
					}
				}

				// if there is more than one measure, put it in the column by default
				If ((..measureLocation'="rows")&&(tMsrClause'="") && tMultipleMeasures) {		// DTB141 - use new tMultipleMeasures test
					If $E(tClause,1,6)="%LABEL" {
						// DTB208 - If the clause has a label, remove it before crossjoining, then place it around the entire crossjoin.
						// This structure provides the signal to the engine that the first term  of the crossjoin should be labeled.
						Set tClauseQuery = "SELECT " _ tClause _ " ON 0 FROM [" _ ..cubeName _"]"		// A new query to build the object form
						Set tTempRS = ##class(%DeepSee.ResultSet).%New()
						Set tSC = tTempRS.%PrepareMDX(tClauseQuery)
						If $$$ISERR(tSC) Quit
						
						Set tClauseOBJ = tTempRS.%GetQuery().axes.GetAt(1).children.GetAt(1)
						
						Set tSC = ##class(%DeepSee.Query.query).%RemoveLabel(tClauseOBJ,.tAbstractLabelOBJ,.tInnerClauseOBJ)
						If $$$ISERR(tSC) Quit
						Set tLabelArgs = $P(tAbstractLabelOBJ.%ToString(),",",2,*)
						
						Set tClause = "%LABEL(NONEMPTYCROSSJOIN("_tInnerClauseOBJ.%ToString()_","_tMsrClause_")," _ tLabelArgs			
					}
					Else {
						Set tClause = "NONEMPTYCROSSJOIN("_tClause_","_tMsrClause_")"
					}
				}

				Set tSumClause = tClause
				If (tShowTotals) {
					Set tSELECT = tSELECT _ "{"_tClause_",SUM("_tSumClause_")}"
				}
				Else {
					Set tSELECT = tSELECT_tClause
				}
				Set tSELECT = tSELECT _ " ON 0"
			}
			Else {
				// put measures along columns, if more than 1
				If ((..measureLocation'="rows")&&(tMsrClause'="") && tMultipleMeasures) {		// DTB141 - use new tMultipleMeasures test
					Set tClause = tMsrClause

					Set tSumClause = tClause
					If (tShowTotals) {
						Set tSELECT = tSELECT _ "{"_tClause_",SUM("_tSumClause_")}"
					}
					Else {
						Set tSELECT = tSELECT_tClause
					}
					Set tSELECT = tSELECT _ " ON 0"
				}
			}

			// JMD1148
			// DTB745 - Only apply the overrideRowSpec if there are no drillLevels. The override applies only to the base level of the table.
			If (..overrideRowSpec'="")&&('..drillLevels.Count()) {
				Set:tSELECT'="" tSELECT = tSELECT _ ","
				Set:'..showEmptyRows tSELECT = tSELECT _ "NON EMPTY "
				Set tSELECT = tSELECT _ ..overrideRowSpec _ " ON 1"
			}
			// WAL076 -- only if measure location is rows, simple single measures go in the slicer
			ElseIf ((..measureLocation="rows")&&(tMsrClause'="")&&tMultipleMeasures&&(..rowLevels.Count()=0)&&(..columnLevels.Count()>0)) { 	// DTB141 - use new tMultipleMeasures test
				// JMD1462
				Set:tSELECT'="" tSELECT = tSELECT _ ","
				Set tSELECT = tSELECT _ tMsrClause _ " ON 1"
			}
			ElseIf (..rowLevels.Count()>0) {
				Set tClause = ..%GetAxisClauseFromLevels(..rowLevels,..showEmptyRows,.tComplexQuery,tDrillLevel,..crossJoinRowLimit,pShowAll)		// DTB835
				Set:tComplexQuery pComplexQuery = 1
				If (tClause'="") {
					Set:tSELECT'="" tSELECT = tSELECT _ ","
					Set:'..showEmptyRows tSELECT = tSELECT _ "NON EMPTY "

					If ($IsObject(..rowAxisOptions)) {
						// apply SET functions, if any
						If (..rowAxisOptions.filterEnabled) {
							Set tClause = "FILTER(" _ tClause
							Set tExpr = ..rowAxisOptions.filterExpression
							Set:tExpr="" tExpr = "1"

							Set tClause = tClause _ "," _ tExpr
							Set tClause = tClause _ ")"
						}

						If (..rowAxisOptions.orderEnabled && '..rowAxisOptions.suppress8020) {
							Set tClause = "ORDER(" _ tClause
							Set tExpr = ..rowAxisOptions.orderExpression
							Set:tExpr="" tExpr = "MEASURES.["_tCountName_"]"

							Set tDirection = ..rowAxisOptions.orderDirection
							Set:tDirection="" tDirection = "BDESC"

							Set tClause = tClause _ "," _ tExpr
							Set tClause = tClause _ "," _ tDirection
							Set tClause = tClause _ ")"
						}
						If (..rowAxisOptions.headEnabled) {
							Set tClause = "HEAD(" _ tClause
							Set:((+..rowAxisOptions.headCount)>1) tClause = tClause _ "," _ ..rowAxisOptions.headCount
							Set tClause = tClause _ ")"
						}
						If (..rowAxisOptions.aggEnabled && (..rowAxisOptions.aggFunction'="")) {
							If (($$$UPPER(..rowAxisOptions.aggFunction)="PERCENTILE") && (..rowAxisOptions.aggFunctionParm'="")) {
								// make sure 2nd argument is present!
								Set tClause = ..rowAxisOptions.aggFunction _ "(" _ tClause _ ",,"_..rowAxisOptions.aggFunctionParm_ ")"
							}
							ElseIf (($$$UPPER(..rowAxisOptions.aggFunction)="COUNT NONEMPTY")) {
								Set tClause = "COUNT(" _ tClause _ ",EXCLUDEEMPTY)"
							}
							Else {
								Set tClause = ..rowAxisOptions.aggFunction _ "(" _ tClause _ ")"
							}
						}

						// JMD916
						If (..rowAxisOptions.suppress8020) {
							// JMD1293: apply sort order
							Set tSortExpr = ""
							Set tF1 = "TOPPERCENT"
							Set tF2 = "BOTTOMPERCENT"
							If (..rowAxisOptions.orderEnabled) {
								Set tSortExpr = ..rowAxisOptions.orderExpression
								If (..rowAxisOptions.orderDirection="BASC") {
									Set tF1 = "BOTTOMPERCENT"
									Set tF2 = "TOPPERCENT"
								}
							}
							Set:tSortExpr'="" tSortExpr = ","_tSortExpr
							Set tClause = "{"_tF1_"(" _ tClause _ ",80"_tSortExpr_"),%LABEL(SUM("_tF2_"(" _ tClause _ ",20"_tSortExpr_")),"""_$$$Text("Other","%DeepSee")_""",,,,""font-style:italic;"")}"
						}

						If ((..rowAxisOptions.levelCaption'="")||(..rowAxisOptions.levelFormat'="")||(..rowAxisOptions.levelStyle'="")||(..rowAxisOptions.levelHeaderStyle'="")||(..rowAxisOptions.levelSummary'="")) {
							Set tClause = "%LABEL(" _ tClause _ ","_ $$$quote(..rowAxisOptions.levelCaption) _ ","_ $$$quote(..rowAxisOptions.levelFormat)
							// JMD: tack summary onto style
							Set tLevelStyle = ..rowAxisOptions.levelStyle
							Set:(..rowAxisOptions.levelSummary'="") tLevelStyle = tLevelStyle_"summary:"_..rowAxisOptions.levelSummary_";"
							Set:(tLevelStyle'="") tClause = tClause _ ",,"_ $$$quote(tLevelStyle)
							Set:(..rowAxisOptions.levelHeaderStyle'="") tClause = tClause _ $S((..rowAxisOptions.levelStyle=""):",,,",1:",")_ $$$quote(..rowAxisOptions.levelHeaderStyle)
							Set tClause = tClause _ ")"
						}
					}

					// if there is more than one simple measure, put it in the rows
					If ((..measureLocation="rows")&&(tMsrClause'="") && tMultipleMeasures) {		// DTB141 - use new tMultipleMeasures test
						If $E(tClause,1,6)="%LABEL" {
							// DTB208 - If the clause has a label, remove it before crossjoining, then place it around the entire crossjoin.
							// This structure provides the signal to the engine that the first term  of the crossjoin should be labeled.
							Set tClauseQuery = "SELECT " _ tClause _ " ON 0 FROM [" _ ..cubeName _"]"		// A new query to build the object form
							Set tTempRS = ##class(%DeepSee.ResultSet).%New()
							Set tSC = tTempRS.%PrepareMDX(tClauseQuery)
							If $$$ISERR(tSC) Quit

							Set tClauseOBJ = tTempRS.%GetQuery().axes.GetAt(1).children.GetAt(1)
							
							Set tSC = ##class(%DeepSee.Query.query).%RemoveLabel(tClauseOBJ,.tAbstractLabelOBJ,.tInnerClauseOBJ)
							If $$$ISERR(tSC) Quit
							Set tLabelArgs = $P(tAbstractLabelOBJ.%ToString(),",",2,*)
							
							Set tClause = "%LABEL(NONEMPTYCROSSJOIN("_tInnerClauseOBJ.%ToString()_","_tMsrClause_")," _ tLabelArgs			
					}
						Else {
							Set tClause = "NONEMPTYCROSSJOIN("_tClause_","_tMsrClause_")"
						}
					}
					Set tSumClause = tClause

					If (tShowTotals) {
						Set tSELECT = tSELECT _ "{"_tClause_",SUM("_tSumClause_")}"
					}
					Else {
						Set tSELECT = tSELECT_tClause
					}
					Set tSELECT = tSELECT _ " ON 1"
				}
			}
			Else {
				// put measures along rows, if more than 1
				If ((..measureLocation="rows")&&(tMsrClause'="") && tMultipleMeasures) {		// DTB141 - use new tMultipleMeasures test
					Set tClause = tMsrClause
					Set:tSELECT'="" tSELECT = tSELECT _ ","

					Set tSumClause = tClause
					If (tShowTotals) {
						Set tSELECT = tSELECT _ "{"_tClause_",SUM("_tSumClause_")}"
					}
					Else {
						Set tSELECT = tSELECT_tClause
					}
					Set tSELECT = tSELECT _ " ON 1"
				}
			}

			// JMD1347
			If (..contextFilterSpec '= "") {
				If ($E(..contextFilterSpec,1,8)="%FILTER ") {
					Set tFilterClauses($I(tFilterClauses)) = $E(..contextFilterSpec,8,*)
				}
				Else {
					Set tFilterClauses($I(tFilterClauses)) = ..contextFilterSpec
				}
			}

			// DTB141 - A single, simple measure may be added as a filter, single computed measures
			// are moved to third axis
			If ((tSingleSimpleMeasure || tSingleCalcMeasure)&&(..userMDX="")) {	// DTB141
				Set tMsr = ..measures.GetAt(1)
				Set tMsrSpec = tMsr.spec
				If (tMsr.aggFunction'="") {
					Set tMsrSpec = tMsrSpec _ "." _ tMsr.aggFunction
				}
				// WAL076 -- remove %LABEL handling here; measures with formatting 
				//           etc. are no longer considered simple measures
				If tSingleSimpleMeasure {
					Set:tMsrSpec'="" tFilterClauses($I(tFilterClauses)) = tMsrSpec
				} ElseIf tSingleCalcMeasure {
					// DTB141 - push calculated measure to third axis
					Set tSELECT = tSELECT _ $S(tSELECT[" ON ":", ",1:"") _ tMsrSpec _ " ON 2"
				}
			}

			// construct query from current settings
			Set tSLICER = ""
			Set k = $O(tFilterClauses(""))
			While (k'="") {
				Set tSLICER = tSLICER _ " %FILTER " _ tFilterClauses(k)
				Set k = $O(tFilterClauses(k))
			}
			Set tMDX = tWITH _ "SELECT "_tSELECT_" FROM ["_##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(tCubeName)_"]"_tSLICER		// DTB130 - generated query text should never show a version number
		} // not-a-listing
		
		If (..sqlRestriction'="") {
			// DTB723 - If the sqlRestriction is defined, add it as the final filter in the current query
			Set tMDX = tMDX _ " %FILTER %SQLRESTRICT.&[" _ ..sqlRestriction _ "]"
		}
		
		Set tSC = ..SetCurrentQueryText("current",tMDX)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Set tMDX = $system.Status.GetErrorText(tSC)
	}
	Set pSC = tSC
	
	Quit tMDX
}

/// Adds a coverpane to the pivot in the DOM. This is used to disable the pivot interaction.
ClientMethod addPivotCoverPane(parentDiv) [ Internal, Language = javascript ]
{
	// Method added by DTB701
	//var pivotContent = zen('dsPivotCompleteTable');
	//var parentDiv = pivotContent.getEnclosingDiv();
	if (!parentDiv) {		// DTB783 - Protect against a call with a null prentDiv. Do nothing in this case.
		return;
	}
	var newDiv = document.createElement('div');
	var coverPaneId = this.makeId('pivotCoverPane');
	var coverPane = document.getElementById(coverPaneId);
	
	// DTB714 - Define the svgTextGroup tiled repitition limits of the coverPane text
	var tileColCount = 4;
	var tileRowCount = 3;
	
	if (!coverPane) {
		// Only add a cover pane if one does not exist already
		newDiv.setAttribute('id',coverPaneId);
		newDiv.setAttribute('class','coverPaneInactive');
		
		// Draw the word 'PREVIEW' and add it as a watermark to the pane
		var svgWatermark = document.createElementNS(SVGNS,'svg');
		svgWatermark.setAttribute('id',this.makeId('previewWatermark'));
		svgWatermark.setAttribute('height',parentDiv.offsetHeight);
		svgWatermark.setAttribute('width',parentDiv.offsetWidth);
		
		// DTB714 - Render several text tiles
		var svgTextGroup = document.createElementNS(SVGNS,'g');
		var tileWidth = parentDiv.offsetWidth/tileColCount;
		var tileHeight = parentDiv.offsetHeight/tileRowCount;
		for ( r = 0 ; r<tileRowCount ; r++ ) {
			for ( c = 0 ; c<tileColCount ; c++ ) {
				var svgText = document.createElementNS(SVGNS,'text');
				var centerX = tileWidth*c + (tileWidth/2);
				var centerY = tileHeight*r + (tileHeight/2);
				
				svgText.setAttribute('transform','rotate(-30 '+centerX+','+centerY+')');
				svgText.setAttribute('font-size',(tileHeight/(1.1*3.16))+'px');
				svgText.setAttribute('text-anchor','middle');
				svgText.setAttribute('alignment-baseline','central');
				svgText.setAttribute('x',centerX);
				svgText.setAttribute('y',centerY);
				svgText.appendChild(document.createTextNode('PREVIEW'));
				
				svgTextGroup.appendChild(svgText);
			}
		}
		svgWatermark.appendChild(svgTextGroup);
		newDiv.appendChild(svgWatermark);
		newDiv.style.zIndex=2;		// DTB710 - Add zIndex to make sure this div is on top
		if (this.allowPreviewInteraction) {
			// DTB712 - Make the coverpane transparent to events if interaction is allowed
			newDiv.style.pointerEvents='none';
		}
		
		parentDiv.style.position='relative';
		parentDiv.appendChild(newDiv);
	}
}

/// This prevents a user from interacting with the pivot by using the cover pane.
ClientMethod setPivotDisabled(setDisabled) [ Language = javascript ]
{
	// Method added by DTB701
	var coverPaneId = this.makeId('pivotCoverPane');
	var coverPane = document.getElementById(coverPaneId);
	var svgWatermark = this.findElement('previewWatermark');
	
	if (coverPane) {
		// Switch the css class to hide the coverPane objects
		if (setDisabled) {
			this.selectCellRange('');
			coverPane.setAttribute('class','coverPaneActive');
			svgWatermark.setAttribute('visibility','visible');
		}
		else {
			coverPane.setAttribute('class','coverPaneInactive');
			svgWatermark.setAttribute('visibility','hidden');
		}
	}
}

/// This entry point triggers an execution and printing of the current table in SVG format.
ClientMethod exportToPDF(parms) [ Language = javascript ]
{
	// Method added by DP-416722
	this.selectCellRange();		// Turn off cell selection to avoid picking up styling problems
	this.updateToolbar();
	var query = this.GetCurrentQueryText();
	var application = window.location.pathname.substring(0,window.location.pathname.indexOf('/csp')) + '/api/deepsee/v3';	// DP-432957
	var pageMeta = zenPage.getPageMeta();		// DP-420135 - Use metadata set into the page
	var namespace = pageMeta[0];
	
	
	var configuration = {};
	configuration.type = 'MDX';
	configuration.initialMDX = query;
	configuration.pivotName = '';
	configuration.showTotals = false;

	// Currently the connection is relying on the session context to log in
	configuration.connection = new DeepSeeConnection('','',window.location.origin,application,namespace);

	var jsDC = new DeepSeeDataController(configuration,this.callbackExportRStoPDF,this.callbackRSPending);
	jsDC.parms = parms;
	jsDC.pivotZenId = parseInt(this.index);		// Store the Zen index of this table to retrieve the component in the DC context
	if (!zenPage._rsStart) {zenPage._rsStart = []};
	zenPage._rsStart[parseInt(this.index)] = Date.now();	// Note the start time in case the pending callback needs to report the elapsed wait time.

	jsDC.runQuery();
}

/// This method is designed to be used as a callback from the DeepSeeDataController. It takes a resultset from the supplied
/// datacontroller and uses it to print to PDF. This method expects the printing parameters needed by the svgImageProvider
/// are supplied in an object <var>dc.parms</var>.
ClientMethod callbackExportRStoPDF(dc) [ Language = javascript ]
{
	// Method added by DP-416722
	if ((zenPage._rsStart)&&(zenPage._rsStart[dc.pivotZenId])) {delete zenPage._rsStart[dc.pivotZenId]};		// Reset the pending timestamp
	
	var table = zenGetComponent(dc.pivotZenId);
	table.hideMessage();


	if (!dc) {
		// Exit with no action if the callback wasn't supplied with the DataController
		return;
	}

	// Get the resultset to be converted to the full svg table
	var jsRS = dc.getCurrentData();
	
	if (jsRS.isError()) {
		// DP-416722 - If we have an error alert the user
		alert(jsRS.getErrorMessage());
		return;		
	}
	
	// Load the SVG image provider for utilities
	var svgUtil = new _DeepSee_Component_deepseeSvgImageProvider;
	svgUtil.setPrintParameters(dc.parms);

	// Create the SVG resultset
	var svgPrintFrame = svgUtil.createSVGTableFromResultSet(jsRS,table.id,dc.parms);

	// Wrap the raw table content in a container for printing
	var svgTableDiv = document.createElement('div');
	svgTableDiv.appendChild(svgPrintFrame);

	// Record the original width to prevent massive upward scaling
	dc.parms.imageWidth = svgPrintFrame.getAttribute('width');
	dc.parms.svgUtil = svgUtil;		// Make this imageprovider available in all contexts through the parms object

	// This can now be printed to PDF with the svgImageProvider. Fire the actual print with a setTimeout-0
	setTimeout(svgUtil.printSVGContent,0,'',dc.parms,svgTableDiv);
}

/// This method is designed to be used as a callback from the DeepSeeDataController. It reports the number of seconds
/// the client has been waiting for the DeepSeeResultSet data to be returned from the server.
ClientMethod callbackRSPending(dc) [ Language = javascript ]
{
	if (!zenPage._rsStart) {
		zenPage._rsStart = [];
	}
	if (!zenPage._rsStart[dc.pivotZenId]) {
		zenPage._rsStart[dc.pivotZenId] = Date.now();
	}
	var elapsedSecs = Math.floor((Date.now() - zenPage._rsStart[dc.pivotZenId])/1000)
	zenGetComponent(dc.pivotZenId).controller.showMessage(zenGetComponent(dc.pivotZenId),'Export PDF... ',elapsedSecs,'',' seconds');
}

}
