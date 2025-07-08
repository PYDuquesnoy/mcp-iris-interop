/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Render a Worksheet to PDF by using the Zen reports infrastructure.
/// The name of the worksheet to process is passed in via the URL parameter WORKSHEET.
Class %DeepSee.UI.WorksheetPDF Extends %ZEN.Report.reportPage [ System = 4 ]
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
name='MyReport' title='Worksheet Printout' style='standard'>
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in" >
</document>
<body>
<group name="table1">
<item createtable="true" field="worksheet"/>
</group>
</body>

</report>
}

ClassMethod Test(pWorkSheetName As %String)
{
	Do ..%WriteXMLForReport(pWorkSheetName)
}

/// Write out sample data
ClassMethod SampleData()
{
   w !,"<table1>"
   w !,"<worksheet> "
   w !,"<title>My Worksheet</title> "
   w !,"<column-headers> "
   w !,"<header value='' background-color='lightgray'/>"
   w !,"<header value='' background-color='lightgray'/>"
   w !,"<header value='2009' colspan='2' background-color='lightgray' border-style='solid solid solid solid'>"
   w !,"</header>"
   w !,"<header value='2010' colspan='2' background-color='lightgray' border-style='solid solid solid solid'>"
   w !,"</header>"
   w !,"<column-headers>"
   w !,"<header value='' background-color='lightgray' />"
   w !,"<header value='' background-color='lightgray' />"
   w !,"<header value='Q1' background-color='lightgray' border-style='solid solid solid solid'/> "
   w !,"<header value='Q2' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<header value='Q1' background-color='lightgray' border-style='solid solid solid solid'/> "
   w !,"<header value='Q2' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"</column-headers>"
   w !,"</column-headers> "
   w !,"<data> "
   w !,"<row> "
   w !,"<cell value='USA' rowspan='2' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<cell value='Pencils' background-color='lightgray' border='5px solid red' color='blue' font-weight='bold' font-style='italic' text-decoration='underline' text-align='right' font-size='12pt' font-family='Courier'/>"
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"</row> "
   w !,"<row>"
   w !,"<cell value='Pretzels' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"</row>"
   w !,"<row> "
   w !,"<cell value='Canada' rowspan='2' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<cell value='Pencils' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"</row> "
   w !,"<row>"
   w !,"<cell value='Pretzels' background-color='lightgray' border-style='solid solid solid solid'/>"
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"<cell value='100' format='$#,###.##' text-align='right' border-style='solid solid solid solid'/> "
   w !,"</row>"
   w !,"</data> "
   w !,"</worksheet>"
   w !,"</table1>"
}

/// Write out sample data
ClassMethod SampleData2()
{
	&html<<table1>
<worksheet>
<title>My Worksheet</title>
<column-headers>
<header value='' background-color='lightgray'/>
<header value='Cost' background-color='lightgray' />
<header value='Sales' background-color='lightgray' />
</column-headers>
<data>
<row>
<cell value='2006' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='1000' text-align='right' border-style='solid solid solidsolid'/>
<cell value='2011' text-align='right' border-style='solid solid solidsolid'/>
</row>
<row>
<cell value='2007' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='1100' text-align='right' border-style='solid solid solidsolid'/>
<cell value='1300' text-align='right' border-style='solid solid solidsolid'/>
</row>
<row>
<cell value='2008' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='1200' text-align='right' border-style='solid solid solidsolid'/>
<cell value='2400' text-align='right' border-style='solid solid solidsolid'/>
</row>
<row>
<cell value='2009' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='1300' text-align='right' border-style='solid solid solidsolid'/>
<cell value='2600' text-align='right' border-style='solid solid solidsolid'/>
</row>
<row>
<cell value='2010' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='1400' text-align='right' border-style='solid solid solidsolid'/>
<cell value='2800' text-align='right' border-style='solid solid solidsolid'/>
</row>
<row>
<cell value='2011' background-color='lightgray' border-style='solid solid solidsolid'/>
<cell value='4500' text-align='right' border-style='solid solid solidsolid'/>
<cell value='5800' text-align='right' border-style='solid solid solidsolid'/>
</row>
</data>
</worksheet>
</table1>
	>
}

/// Get the data, as xml, for the current worksheet.
ClassMethod GetTableData()
{
	Set tWorkSheetName = $G(%request.Data("WORKSHEET",1))
	If (1) {
		Do ..%WriteXMLForReport(tWorkSheetName)
		Quit
	}
}

/// Write out the contents of a report in a way that can be consumed by a Zen report.
/// <var>pID</var> is the full name of the worksheet.
ClassMethod %WriteXMLForReport(pID As %String)
{
	Set tSC = $$$OK
	Try {
		Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pID)
		If '$IsObject(tWorksheet) {
			Do ..%WriteXMLMessage(pID,"Worksheet not found")
			Quit
		}

		// pick up font-size, etc.


		Set tTitle = tWorksheet.title

		Set tColumnHeaderColor = "lightgray"
		Set tRowHeaderColor = "blue"
		Set tBorderStyle = "none none none none"
		Set tOddRowColor = "white"
		Set tEvenRowColor = "#F0F0F0"
		Set tUseZebra = 1
		Set tGridFormat = tWorksheet.format
		Set tGridStyle = tWorksheet.style

		Write "<table1>",!
		Write "<worksheet>",!
		Write "<title>",$ZCVT(tTitle,"O","HTML"),"</title>",!

		// columns
		Write "<column-headers>",!
		Write "<header value='' background-color='lightgray'/>",!
		Set tColCount = tWorksheet.columnHeaders.Count()
		For c = 1:1:tColCount {
			Set tCol = tWorksheet.columnHeaders.GetAt(c)
			Write "<header value='",$ZCVT(tCol.name,"O","HTML"),"' background-color='",tColumnHeaderColor,"' />",!
		}
		Write "</column-headers>",!

		// recalc
		Set tSC = tWorksheet.%Calculate()
		If $$$ISERR(tSC) Quit

		// get values from worksheet
		// (use resolved values)
		Write "<data>",!

		// cell overrides
		/*
		Set tCellCount = tWorksheet.cells.Count()
		For cc = 1:1:tCellCount {
			Set tCellDef = tWorksheet.cells.GetAt(cc)
			If ((+tCellDef.row>0)&&(+tCellDef.column>0)) {
				Set tCellDefs(+tCellDef.row,+tCellDef.column) = tCellDef
			}
		}
		*/

		// rows
		Set tRowCount = tWorksheet.rowHeaders.Count()
		For r = 1:1:tRowCount {
			Set tIsOdd = r#2
			Set tRow = tWorksheet.rowHeaders.GetAt(r)
			// apply precedence!

			Write "<row>",!
			Set tHeaderColor = $S(tUseZebra:$S(tIsOdd:tOddRowColor,1:tEvenRowColor),1:tRowHeaderColor)
			Write "<cell value='",$ZCVT(tRow.name,"O","HTML"),"' background-color='",tHeaderColor,"' border-style='",tBorderStyle,"'/>",!
			For c = 1:1:tColCount {
				// lookup cell override
				// Set tCellDef = $G(tCellDefs(r,c))

				Set tCol = tWorksheet.columnHeaders.GetAt(c)
				Set tValue = $G(tWorksheet.%values(r,c))
				Set tFormat = $S(tCol.format'="":tCol.format,tRow.format'="":tRow.format,1:tGridFormat)
				
				// concatenate styles
				Set tStyle = $S(tCol.style'="":tCol.style,tRow.style'="":tRow.style,1:tGridStyle)
				Set tDisplay = ##class(%DeepSee.ResultSet).%FormatNumber(tValue,tFormat,.tType,.tFormatStyle)
				Set tCellColor = $S(tUseZebra:$S(tIsOdd:tOddRowColor,1:tEvenRowColor),1:"")
	
				Kill tCSS
				If (tStyle'="") {
					Do ..%ParseStyle(tStyle,.tCSS)
				}
				//Set tDisplay=tStyle

				Write "<cell value='",$ZCVT(tDisplay,"O","HTML"),"' "
				Write:tCellColor'="" "background-color='",tCellColor,"' "

				For s="font-weight","font-size","color","text-align","text-decoration","font-family" {
					If ($G(tCSS(s))'="") {
						Write s,"='",tCSS(s),"' "
					}
				}
				Write "border-style='",tBorderStyle,"'/>",!
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
	If $$$ISERR(tSC) {
		Write "<!-- ",$system.Status.DisplayError(tSC)," -->",!
	}
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

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $System.Security.Check("%DeepSee_Portal","USE")
}

}
