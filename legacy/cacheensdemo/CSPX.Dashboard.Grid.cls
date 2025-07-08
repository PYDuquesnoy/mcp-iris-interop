/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Grid Meter for Dashboard.
/// The Grid Meter displays a set of data as a simple table.
Class CSPX.Dashboard.Grid Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINWIDTH = 75;

Parameter MINHEIGHT = 75;

/// Data specification for grid columns.
Property Columns As GridDimension(XMLNAME = "Columns", XMLPROJECTION = "ELEMENT");

/// Data specification for grid rows.
Property Rows As GridDimension(XMLNAME = "Rows", XMLPROJECTION = "ELEMENT");

/// Display height (in logical units) of each row in the grid.
Property RowHeight As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 10 ];

/// Display height (in logical units) of the upper labels in the grid.
Property LabelHeight As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 10 ];

/// Display width (in logical units) of the side labels in the grid.
Property LabelWidth As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 25 ];

/// Maximum number of rows to display in the grid.
Property MaxRows As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 40 ];

/// Maximum number of columns to display in the grid.
Property MaxColumns As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 40 ];

/// Default CSS Style applied to grid cells. E.g. "fill: blue;"
Property CellStyle As %String(MAXLEN = 100, XMLPROJECTION = "ATTRIBUTE");

/// CSS Style applied to grid labels. E.g. "fill: blue;"
Property LabelStyle As %String(MAXLEN = 100, XMLPROJECTION = "ATTRIBUTE");

/// Not supported at this time.
Property LabelSource As %String(MAXLEN = 64, XMLPROJECTION = "NONE");

/// Internal flag for unsupport row/columns combinations.
Property Unsupported As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Internal holder for initial column labels.
Property ColLabels As %String(MAXLEN = 10000, XMLPROJECTION = "NONE");

/// Internal holder for initial row labels.
Property RowLabels As %String(MAXLEN = 10000, XMLPROJECTION = "NONE");

ClassMethod OnSVGStyle()
{
	&html<
.Grid-OuterPanel {
	fill: #000040;
	stroke: darkgray;
	stroke-width: 1;
	filter: url(#dropShadow);
}

.Grid-InnerPanel {
	fill: #EEEEFF;
	stroke: none;
}

.Grid-CellLine {
	fill: none;
	stroke: gray;
	stroke-width: 0.33;
	opacity: 1.0;
}
	>
}

ClassMethod OnSVGHead()
{
	// include js file
	Write "<script type='text/ecmascript' xlink:href='svggrid.js'/>",!
}

ClassMethod OnSVGScript()
{
	
	&js<
function Grid_setProperty(property,value,idx)	
{
	switch (property) {
	default:
		return false;

	case 'series':
		// value is a ":" delimited set of points
		if (this.seriesData[idx] == value) {
			return;
		}
		this.seriesData[idx] = value;

		// find values to display
		var plotVals
		plotVals = value.split(":");
		this.grid.setData(idx,plotVals);
		break;

	case 'xlabels':
		// value is a ":" delimited set of labels
		var labels = value.split(':');
		
		// apply to either rows or columns
		if ('instances' == this.columns) {
			this.grid.setColLabels(labels);
		}
		else {
			this.grid.setRowLabels(labels);
		}
		break;
	}
	return true;
}
	>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	&html<<g id="#(..MeterId)#_grid" transform="translate(5,5)" />>
}

Method OnSVGInitJS()
{
	// find source of data: col, rows, or default
	Set tList = ""
	Set flow = ""
	Set tColType = $S($IsObject(..Columns):..Columns.Source,1:"")
	Set tRowType = $S($IsObject(..Rows):..Rows.Source,1:"")
	Set tColReverse = $S($IsObject(..Columns):..Columns.Reverse,1:0)
	Set tRowReverse = $S($IsObject(..Rows):..Rows.Reverse,1:0)
	Set tColAgg = $S($IsObject(..Columns):..Columns.Aggregate,1:"")
	Set tRowAgg = $S($IsObject(..Rows):..Rows.Aggregate,1:"")
	Set tColAggLbl = $S($IsObject(..Columns):..Columns.AggregateLabel,1:"")
	Set tRowAggLbl = $S($IsObject(..Rows):..Rows.AggregateLabel,1:"")

	If (tColType = "series") {
		Set tList = ..Columns.SeriesList
		Set flow = "vertical"
	}
	ElseIf (tRowType = "series") {
		Set tList = ..Rows.SeriesList
		Set flow = "horizontal"
	}
	ElseIf (tColType = "instances") {
		Set tList = ..Rows.SeriesList
		Set flow = "vertical"
	}
	ElseIf (tRowType = "instances") {
		Set tList = ..Columns.SeriesList
		Set flow = "horizontal"
	}

	// build the grid
	&js<meter.grid = new Grid(meter,#(..MeterId)#,document.getElementById("#(..MeterId)#_grid"),#(..Width-10)#,#(..Height-25)#,#(..LabelWidth)#,#(..LabelHeight)#,#(..MaxRows)#,#(..MaxColumns)#,'#(..LabelStyle)#','#(..CellStyle)#',#($Case(+..Unsupported,1:"true",:"false"))#,'#(flow)#',#($Case(tColReverse,1:"true",:"false"))#,#($Case(tRowReverse,1:"true",:"false"))#,'#(tColAgg)#','#(tRowAgg)#','#(tColAggLbl)#','#(tRowAggLbl)#');>

	// set up initial data for grid
	&js<meter.seriesData = new Array();>
	&js<meter.seriesProperty = new Array();>
	&js<meter.seriesInstance = new Array();>
	&js<meter.seriesLabel = new Array();>

	If $IsObject(tList) {
		For i = 1:1:tList.Count() {
			Set tItem = tList.GetAt(i)
			&js<meter.seriesProperty[#(i-1)#] = '#(tItem.Property)#';>
			&js<meter.seriesInstance[#(i-1)#] = '#(tItem.Instance)#';>
			&js<meter.seriesLabel[#(i-1)#] = '#(tItem.Label)#';>

			// special processing for instance v. history
			If (((tColType = "instances")&&(tRowType = "history")) ||
				((tRowType = "instances")&&(tColType = "history")) ){
				For n = 1:1:$L(tItem.Data,"^") {
					&js<meter.seriesData[#(n-1)#] = '#($P(tItem.Data,"^",n))#';>
				}
			}
			Else {
				&js<meter.seriesData[#(i-1)#] = '#(tItem.Data)#';>
			}
		}
	}

	// test for labels
	&js<
	if (meter.colLabels != '') {
		var labels = meter.colLabels.split(':');
		meter.grid.setColLabels(labels);
	}
	if (meter.rowLabels != '') {
		var labels = meter.rowLabels.split(':');
		meter.grid.setRowLabels(labels);
	}
	>
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do ##super(pCode)

	Do:(..LabelSource'="") pCode.WriteLine(" Set tMeter.LabelSource=""" _ ..LabelSource _ """")
	Do:(..CellStyle'="") pCode.WriteLine(" Set tMeter.CellStyle=""" _ ..CellStyle _ """")
	Do:(..LabelStyle'="") pCode.WriteLine(" Set tMeter.LabelStyle=""" _ ..LabelStyle _ """")
	Do:(..RowHeight'="") pCode.WriteLine(" Set tMeter.RowHeight=""" _ ..RowHeight _ """")
	Do:(..MaxRows'="") pCode.WriteLine(" Set tMeter.MaxRows=""" _ ..MaxRows _ """")
	Do:(..MaxColumns'="") pCode.WriteLine(" Set tMeter.MaxColumns=""" _ ..MaxColumns _ """")
	Do:(..LabelHeight'="") pCode.WriteLine(" Set tMeter.LabelHeight=""" _ ..LabelHeight _ """")
	Do:(..LabelWidth'="") pCode.WriteLine(" Set tMeter.LabelWidth=""" _ ..LabelWidth _ """")

	// dimension definitions
	If '$IsObject(..Rows) {
		// create default rows object
		Do pCode.WriteLine(" Set tMeter.Rows = ##class(CSPX.Dashboard.GridDimension).%New() // default")
		Do pCode.WriteLine(" Set tMeter.Rows.Source = ""series""")
		Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
		Do pCode.WriteLine(" Set tSeries.Property=""" _ ..Property _ """")
		Do pCode.WriteLine(" Set tSeries.Label=""" _ ..Property _ """")
		Do pCode.WriteLine(" Do tMeter.Rows.SeriesList.Insert(tSeries)")
	}
	Else {
		Set:..Rows.Source=$C(0) ..Rows.Source=""
		Do pCode.WriteLine(" Set tMeter.Rows = ##class(CSPX.Dashboard.GridDimension).%New()")
		Do pCode.WriteLine(" Set tMeter.Rows.Source = """ _ ..Rows.Source _ """")
		Do pCode.WriteLine(" Set tMeter.Rows.Aggregate = """ _ ..Rows.Aggregate _ """")
		Do pCode.WriteLine(" Set tMeter.Rows.AggregateLabel = """ _ ..Rows.AggregateLabel _ """")
		Do pCode.WriteLine(" Set tMeter.Rows.Size = " _ +..Rows.Size)
		Do pCode.WriteLine(" Set tMeter.Rows.Reverse = " _ +..Rows.Reverse)

		Set count = ..Rows.SeriesList.Count()
		If (count = 0) {
			// if no series, use Property for this object
			Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
			Do pCode.WriteLine(" Set tSeries.Property=""" _ ..Property _ """")
			Do pCode.WriteLine(" Set tSeries.Label=""" _ ..Label _ """")
			Do pCode.WriteLine(" Do tMeter.Rows.SeriesList.Insert(tSeries)")
		}
		Else {
			If ((..Rows.Source = "history") || (..Rows.Source = "instances")) {
				// we only care about the first series in this case
				Set count = 1
			}
			
			For i=1:1:count {
				Set tSeries = ..Rows.SeriesList.GetAt(i)
				Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
				Do:(tSeries.Property'="") pCode.WriteLine(" Set tSeries.Property=""" _ tSeries.Property _ """")
				Do:(tSeries.Instance'="") pCode.WriteLine(" Set tSeries.Instance=""" _ tSeries.Instance _ """")
				If (tSeries.Label'="") {
					Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Label _ """")
				}
				Else {
					Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Property _ """")
				}
				Do pCode.WriteLine(" Do tMeter.Rows.SeriesList.Insert(tSeries)")
			}
		}
	}

	If '$IsObject(..Columns) {
		// create default columns object
		Do pCode.WriteLine(" Set tMeter.Columns = ##class(CSPX.Dashboard.GridDimension).%New() // default")
		Do pCode.WriteLine(" Set tMeter.Columns.Source = ""series""")
		Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
		Do pCode.WriteLine(" Set tSeries.Property=""" _ ..Property _ """")
		Do pCode.WriteLine(" Set tSeries.Label=""" _ ..Property _ """")
		Do pCode.WriteLine(" Do tMeter.Columns.SeriesList.Insert(tSeries)")
	}
	Else {
		Set:..Columns.Source=$C(0) ..Columns.Source=""
		Do pCode.WriteLine(" Set tMeter.Columns = ##class(CSPX.Dashboard.GridDimension).%New()")
		Do pCode.WriteLine(" Set tMeter.Columns.Source = """ _ ..Columns.Source _ """")
		Do pCode.WriteLine(" Set tMeter.Columns.Aggregate = """ _ ..Columns.Aggregate _ """")
		Do pCode.WriteLine(" Set tMeter.Columns.AggregateLabel = """ _ ..Columns.AggregateLabel _ """")
		Do pCode.WriteLine(" Set tMeter.Columns.Size = " _ +..Columns.Size)
		Do pCode.WriteLine(" Set tMeter.Columns.Reverse = " _ +..Columns.Reverse)

		Set count = ..Columns.SeriesList.Count()
		If (count = 0) {
			// if no series, use Property for this object
			Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
			Do pCode.WriteLine(" Set tSeries.Property=""" _ ..Property _ """")
			Do pCode.WriteLine(" Set tSeries.Label=""" _ ..Label _ """")
			Do pCode.WriteLine(" Do tMeter.Columns.SeriesList.Insert(tSeries)")
		}
		Else {
			If ((..Columns.Source = "history") || (..Columns.Source = "instances")) {
				// we only care about the first series in this case
				Set count = 1
			}
			For i=1:1:count {
				Set tSeries = ..Columns.SeriesList.GetAt(i)
				Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.GridSeries).%New()")
				Do:(tSeries.Property'="") pCode.WriteLine(" Set tSeries.Property=""" _ tSeries.Property _ """")
				Do:(tSeries.Instance'="") pCode.WriteLine(" Set tSeries.Instance=""" _ tSeries.Instance _ """")
				If (tSeries.Label'="") {
					Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Label _ """")
				}
				Else {
					Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Property _ """")
				}
				Do pCode.WriteLine(" Do tMeter.Columns.SeriesList.Insert(tSeries)")
			}
		}
	}

	Quit $$$OK
}

}
