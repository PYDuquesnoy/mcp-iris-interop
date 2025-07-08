/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines how tables are displayed within a generated
/// ZEN report stylesheet.
Class %ZEN.Report.Display.table Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

/// Defines the orientation of the table. Acceptable values are "row" and "col."  If
/// orient is "row," each child tag of table will be placed in a new row.  Similarly,
/// if orient is "col" each child tag will be placed in a new column.
Property orient As %ZEN.Datatype.string(VALUELIST = ",row,col") [ InitialExpression = "col" ];

/// Specifies a group of data for the table to display. See the &lt;group&gt; class for more
/// information on displaying groups. In this case, each record contained within the group will
/// appear as a new row/column of the table.
Property group As %ZEN.Datatype.string;

/// Specifies sql for the table to display.  In this case, each record in the sql result set will appear as a new row/column of the table.
Property sql As %ZEN.Datatype.sql;

/// Specifies query for the table to display.  In this case, each record in the sql result set will appear as a new row/column of the table.<br>
/// queryName specifies the query in queryClass.
Property queryName As %ZEN.Datatype.classMember;

/// Specifies class for query that the table will display.  In this case, each record in the sql result set will appear as a new row/column of the table.<br>
/// queryClass is the class containing the query specified by queryName.
Property queryClass As %ZEN.Datatype.className;

/// Specifies callback method which returns ResultSe
Property onCreateResultSet As %ZEN.Datatype.string;

/// Specifies %SELECTMODE of sql or query. 0=Logical, 1=ODBC, 2=Display. 
Property selectmode As %ZEN.Datatype.integer(VALUELIST = ",0,1,2");

/// Specifies call back method to get data for table, method must fill in two dimensional array where rows are first index and columns are second index.<p>
/// When retrieving data, only works with fieldNum in item.  Cannot use fieldname.
Property ongetData As %ZEN.Datatype.string;

/// This property specifies the background color of the alternate rows (2, 4, 6, ...).  
/// This is only possible when <property>orient</property>="col" and <property>group</property> 
/// is defined.  Currently only works with <property>orient</property>="col".
Property altcolor As %ZEN.Datatype.color;

/// Possible values are "auto" and "fixed."<br>
/// Currently, Apache's FOP rendering engine only supports "fixed."
Property layout As %ZEN.Datatype.string(VALUELIST = ",none,fixed,auto") [ InitialExpression = "fixed" ];

/// Specifies the alignment of the table within the page or its current container
/// (table cell, etc.)
Property align As %ZEN.Datatype.align;

/// If orient is row and removeEmpty is 1 then empty rows are removed from the table display
Property removeEmpty As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property foStyle As %ZEN.Datatype.string;

Property foHeaderStyle As %ZEN.Datatype.string;

Property defaultWidth As %ZEN.Datatype.string;

Property foBlockStyle As %ZEN.Datatype.string;

/// comma separated list of xpaths by which the table will be sorted
Property orderby As %ZEN.Datatype.string;

/// specify type of data used in table sort orderby - text, number or qname
Property dataType As %ZEN.Datatype.string(VALUELIST = ",text,number,qname", XMLNAME = "data-type") [ InitialExpression = "text" ];

/// xpath by which the group will be group-by
Property groupby As %ZEN.Datatype.string;

/// xpath by which the group will be group-starting-with
Property groupstartingwith As %ZEN.Datatype.string;

Property crosstab As %ZEN.Datatype.boolean;

Property oldSummary As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// if suppressFoTableColumn is true then don't generate fo:table-column
Property suppressFoTableColumn As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// if staticTable is set we draw table as is specified by <thead> <tbody> <th> <td> elements etc.
Property staticTable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Boolean value used to trigger "keep-together" logic within the 
/// <fo:table-row> element to not allow a row to split across a page
Property rowAcrossPages As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property preserveLineFeed As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// writing-mode XML attribute.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingMode As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode");

/// Set the linefeed-treatment (a property defined by XSL-FO standard)
Property linefeedTreatment As %ZEN.Datatype.string(VALUELIST = ",ignore,preserve,treat-as-space,treat-as-zero-width-space", XMLNAME = "linefeed-treatment");

/// User-defined list of query parameters. These are used to supply
/// parameter values for the sql,queryName, or onCreateResultSet if they are used by this table.
Property parameters As list Of %ZEN.Report.Display.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

Property excelSheetName As %ZEN.Datatype.caption [ InitialExpression = "sheet" ];

Property excelGroupName As %ZEN.Datatype.caption [ InitialExpression = "group" ];

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	New %number
	If ..layout="fixed",..width="" Set ..width="100%" ; prevent FOP info message.  If you really want auto (which is the default) specify auto
	If ..group'="" $$$groupNumInc
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set context("tablenesting")=$i(context("tablenesting"))	
	Do XSL.WriteLine("<fo:block"_$s(..foBlockStyle'="":" "_..foBlockStyle,1:"")_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">") 
	Do:..align'="" XSL.WriteLine("<xsl:attribute name='text-align'>"_..align_"</xsl:attribute>")
	if ..group'="" Do XSL.WriteLine("<xsl:if test='"_..qualify(..group)_"'>")	
	Do XSL.WriteLine("  <fo:table"_$s(..foStyle'="":" "_..foStyle,1:"")_$s(..layout'="none":" table-layout='"_..layout_"' ",1:"")_$$$applyclass("table",.context)_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_">") 
	If 'incell $$$stylefo
	d ..tagChildren()
	Set i = ..children.Next("")
	// give children parent and class of containing table
	Set i = ..children.Next("")	
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set i= ..children.Next(i)
	}
	
	if (..staticTable=0) {
		If ..orient = "row"{
			Set sc = ..%DisplayTableByRowsFO(.context,.XSL,.delay)
		} Else {	
			Set sc = ..%DisplayTableByColsFO(.context,.XSL,.delay)
		}
	} else {
			d ..tagChildren()
			Set i = ..children.Next("")
			While (i'="") {
				Set child = ..children.GetAt(i)
				d ..updateFromTemplate(.child)	
				Set child.parent=##this
				Set child.xpath=..parent.xpath
				Set:child.class="" child.class=..class
				if child.tag'="caption" Set sc = child.%DrawToXSLFO(.context,.XSL,.delay) // reverted this aspect of JSL5023
				Quit:$$$ISERR(sc)
				Set i= ..children.Next(i)
			}

	}
	Do XSL.Write("</fo:table>")
	if ..group'="" Do XSL.WriteLine("</xsl:if>")
	Do XSL.WriteLine("</fo:block>")
	Set context("tablenesting")=(context("tablenesting")-1)
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit sc
}

/// This method outputs the stylesheet that converts the input xml to the xml with Excel annotations
/// report, table and item should override this method.  Nested tables not supported.
Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	If ..group'="" $$$groupNumInc
	d ..tagChildren()
	Set mode = "table"_$$$groupNum
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set context("tablenesting")=$i(context("tablenesting"))	
	Set context("tablenesting")=(context("tablenesting")-1)
	Set footdata=##class(%GlobalCharacterStream).%New()

	if (..group = "") {
		d ..tagChildren()
		Set i = ..children.Next("")
		Do XSL.WriteLine("<xsl:element name='sheet'>")
		Do XSL.WriteLine("<xsl:attribute name='excelSheetName'>")
		Do XSL.WriteLine("<xsl:value-of select='"""_%report.%getDisplayUniqueExcelSheetName(..excelSheetName,.context)_"""'/>")
		Do XSL.WriteLine("</xsl:attribute>")
		if '..staticTable Do XSL.WriteLine("<xsl:element name='"_..excelGroupName_"'>")
		While (i'="") {
			Set child = ..children.GetAt(i)
			d ..updateFromTemplate(.child)	
			Set child.parent=##this
			Set child.xpath=..parent.xpath
			Set:child.class="" child.class=..class
			if child.tag'="caption" Set sc = child.%DrawToAnnotatedXML(.context,.XSL,.delay)
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawFooterToAnnotatedXML(.context,.footdata,.delay) q:$$$ISERR(sc)
			Quit:$$$ISERR(sc)
			Set i= ..children.Next(i)
			
		}
		if '..staticTable Do XSL.WriteLine("</xsl:element>")
		If ..containsFooter() {
			Do XSL.WriteLine("<!-- footer row -->")
			Do XSL.CopyFrom(footdata)
		} 
		Do XSL.WriteLine("</xsl:element>")
	} else {
		Do XSL.WriteLine("<xsl:element name='sheet'>")
		Do XSL.WriteLine("<xsl:attribute name='excelSheetName'>")
		Do XSL.WriteLine("<xsl:value-of select='"""_%report.%getDisplayUniqueExcelSheetName(..excelSheetName,.context)_"""'/>")
		Do XSL.WriteLine("</xsl:attribute>")
		Do XSL.WriteLine("<xsl:apply-templates select='"_..group_"' mode='"_mode_"'/>")
		// look for footer
		Set i = ..children.Next("")
		While (i'="") {
			Set child = ..children.GetAt(i)
			d ..updateFromTemplate(.child)	
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawFooterToAnnotatedXML(.context,.footdata,.delay) q:$$$ISERR(sc)
			Quit:$$$ISERR(sc)
			Set i= ..children.Next(i)
		}
		If ..containsFooter() {
			Do XSL.WriteLine("<!-- footer row -->")
			Do XSL.CopyFrom(footdata)
		} 
		
		Do XSL.WriteLine("</xsl:element>")
		Set delay2=##class(%GlobalCharacterStream).%New()
		Do delay.WriteLine("<xsl:template match='"_..group_"' mode='"_mode_"'>")
		d ..tagChildren()
		Set i = ..children.Next("")
		Do delay.WriteLine("<xsl:element name='"_..excelGroupName_"'>")
		While (i'="") {
			Set child = ..children.GetAt(i)
			d ..updateFromTemplate(.child)	
			Set child.parent=##this
			Set child.xpath=..parent.xpath
			Set:child.class="" child.class=..class

			if child.tag'="caption" Set sc = child.%DrawToAnnotatedXML(.context,.delay,.delay2)
			Quit:$$$ISERR(sc)
			Set i= ..children.Next(i)
		}
		Do delay.WriteLine("</xsl:element>")
		Do delay.WriteLine("</xsl:template>")
		Do delay.CopyFrom(delay2)
	}

	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit sc
}

Method %DisplayTableByColsFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	if ..group '= "" {
		Set ..applyLevel=..applyLevel+1
	}
	d ..tagChildren()
	Set mode = "table"_$$$groupNum

	Set headdata=##class(%GlobalCharacterStream).%New(),rowdata=##class(%GlobalCharacterStream).%New(),footdata=##class(%GlobalCharacterStream).%New()
	set thead=""
	set tfoot=""
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath_"/"_..group

		// ignore summary/caption children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter") {
			Set i=..children.Next(i) Continue
		}
		If (child.tag="thead") {
			set thead=child
			Set i=..children.Next(i) Continue
		}
		If (child.tag="tfoot") {
			set tfoot=child
			Set i=..children.Next(i) Continue
		}

		If ..canDisplay(child) {
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			Set:child.class="" child.class=..class
			Set width=child.%Width()
			if (child.crosstabHeaderGroup="") {
				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("<xsl:if test="""_child.xpath_"/"_child.field_"/text()"">")
				}
	
				Set width=$s((width="")&&(..defaultWidth=""):"proportional-column-width(1)",(width="")&&(..defaultWidth'=""):..defaultWidth,width="none":"none",1:width)
				if 'child.%Extends("%ZEN.Report.Display.xslt") if ..childHasWidth(),..suppressFoTableColumn=0 Do XSL.WriteLine("<fo:table-column"_$s(width'="none":" column-width='"_..XpathWidthExpression(width)_"'",1:"")_"/>")
				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("</xsl:if>")
				}
			}
			if (child.crosstabHeaderGroup'="") {
	  			Do XSL.WriteLine("<xsl:for-each select='"_child.crosstabHeaderGroup_"'>")
				Set width=$s((width="")&&(..defaultWidth=""):"proportional-column-width(1)",(width="")&&(..defaultWidth'=""):..defaultWidth,width="none":"none",1:width)
				If ..childHasWidth(),..suppressFoTableColumn=0 Do XSL.WriteLine("<fo:table-column"_$s(width'="none":" column-width='"_..XpathWidthExpression(width)_"'",1:"")_"/>")
    			Do XSL.WriteLine("</xsl:for-each>")
			}
	
			#; store header data
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawHeaderFO(.context,.headdata,.delay,..orient) q:$$$ISERR(sc)
			#; store row data(added to different places depending on group)
			if ..UseXSLT() { 
				if child.tag'="variable" { // JSL5217
					Set sc=child.%DrawCellFO(.context,.rowdata,.delay,..orient) q:$$$ISERR(sc)
				} else {
					;Do child.%DrawToXSLFO(.context,.rowdata,.delay)
				}
			}
			#; store footer data (might need to insert row data first)
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawFooterFO(.context,.footdata,.delay,..oldSummary,..orient) q:$$$ISERR(sc)

		} Else {
	
			Do XSL.WriteLine("<fo:table-column column-width='5.in'/><fo:table-body><fo:table-row><fo:table-cell><fo:block color='red'> Cannot display table element: "_child.tag_".")
			Do XSL.WriteLine(" It must extend %ZEN.Report.Display.tableOutput</fo:block></fo:table-cell></fo:table-row></fo:table-body>")
			Set badchild=1 Quit
		}
		Set i= ..children.Next(i)
	}
	Quit:$g(badchild) $$$OK

	Do headdata.Rewind(),rowdata.Rewind(),footdata.Rewind()

	#; write header
	If ..containsHeader() {
		Do XSL.WriteLine("<fo:table-header"_$s(..foHeaderStyle'="":" "_..foHeaderStyle,1:"")_">")
		Do XSL.WriteLine("<fo:table-row>")
		Do XSL.CopyFrom(headdata)
		Do XSL.WriteLine("</fo:table-row>")
		Do XSL.WriteLine("</fo:table-header>")
	}
	if thead'="" Set sc= thead.%DrawToXSLFO(.context,.XSL,.delay,1)
	if tfoot'="" Set sc= tfoot.%DrawToXSLFO(.context,.XSL,.delay,1)

	Do XSL.WriteLine("<fo:table-body>")
	If ..group="" {
		If ..UseXSLT() {
			Do XSL.Write("<fo:table-row")
			If '..rowAcrossPages {
				Do XSL.Write(" keep-together.within-page='0'")
			}
			Do XSL.WriteLine(">")
			;rowdata may have more than 32767 bytes
			While (rowdata.AtEnd = 0) {
		    	Set len = 32000
		    	Do XSL.Write(rowdata.Read(.len))
			}
			Do XSL.WriteLine("</fo:table-row>")
		} else {
			if ..UseSQL() {
				// use sql to generate table
				// Execute SQL and get back ResultSet that will be passed to loopitem children
				Set sc=..GetResultSet(.context,.tLevel,.orderby,.top,.runonce,.tUpperCase)
				if $$$ISERR(sc) quit sc
			    do CalcCache^%occZENReports(tLevel,1,orderby,top,runonce,tUpperCase)
			} elseif (..UseCallBack()) { // use methodCallBack 
				Set orderby=..orderby
				//Set tLevel=0 ; tables with ongetDatas don't allow nesting of tables within tables
				Set tLevel=context("tablenesting")
			    kill %tParams
				Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"%tParams",.Count)
				if $g(tParameters)'="" X " Set "_tParameters
				do $zobjmethod(%report,..ongetData,.var,.%tParams)
			    do CalcCacheFrom2DimArray^%occZENReports(tLevel,orderby,.var)
			}
			// loop over children given by loop element and draw them
			WHILE $$Next^%occZENReports(1,tLevel,.tSCdummy) {
				Do XSL.WriteLine("<fo:table-row")
				If '..rowAcrossPages {
					Do XSL.Write(" keep-together.within-page='0'")
				}
				Do XSL.WriteLine(">")
				Set sc=..DisplayFOChildrenByCols(.context,.XSL,.delay,tLevel)
				Do XSL.WriteLine("</fo:table-row>")
				If $$$ISERR(sc) quit
			}


		}
	} Else {
		;d ..%BeginDrawFo(.context,.XSL,.delay)
		$$$tableNumInc
		Set call="table"_$$$tableNum
		Do ..%BeginGroupNoInc(.context,.XSL,.delay,mode,..qualify(..group))
		Do ..%DrawSort(.context,.XSL,.delay,..orderby,..dataType)
		Do ..%EndGroup(.context,.XSL,.delay,mode,..qualify(..group))
		Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
		Do ..%DeclareLevelParameters(.context,.delay,.delay2)
		Do delay.WriteLine("<xsl:param name='prevmatch' select='position()'/>") //JSL4323
		Do delay.Write("<fo:table-row")
		If '..rowAcrossPages {
			Do delay.Write(" keep-together.within-page='0'")
		}
		Do delay.WriteLine(">")		
		if ..altcolor="" {
			Set altcolor=%report.TableAltColor
		} else {
			Set altcolor=..altcolor
		}
		If altcolor'="" {
			Do delay.WriteLine("<xsl:if test='(position() mod 2 = 0)'>")
			Do delay.WriteLine("<xsl:attribute name='background-color'>"_altcolor_"</xsl:attribute>")
			Do delay.WriteLine("</xsl:if>")
		}
		Do delay.CopyFrom(rowdata)
		Do delay.WriteLine("</fo:table-row>")
		Do delay.WriteLine("</xsl:template>")
		do ..%EndLevel(.context,.delay,.delay2)
	}
	If ..containsFooter() {
		Do XSL.WriteLine("<fo:table-row>")
		Do XSL.WriteLine("<!-- footer row -->")
		Do XSL.CopyFrom(footdata)
		Do XSL.WriteLine("</fo:table-row>")
	} 

	Do XSL.WriteLine("</fo:table-body>")
	
	Quit sc
}

Method %DisplayTableByRowsFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set sc=$$$OK
	d ..tagChildren()	

	Set containsHeader=..containsHeader()
	Set containsFooter=..containsFooter()
	If ..group="" {
#if 1 // Prodlog 74505
		if ..UseXSLT() {
			If containsHeader {
				if ..getColumnWidth("header")'="none",..suppressFoTableColumn=0 Do XSL.WriteLine("<fo:table-column"_$s(..getColumnWidth("header")'="none":" column-width='"_..XpathWidthExpression(..getColumnWidth("header"))_"'",1:"")_"/>")
			}
			if (..getColumnWidth("body")'="none")||(containsHeader&&(..getColumnWidth("header")'="none"))||(containsFooter&&(..getColumnWidth("footer")'="none")),..suppressFoTableColumn=0 Do XSL.WriteLine("<fo:table-column"_$s(..getColumnWidth("body")'="none":" column-width='"_..XpathWidthExpression(..getColumnWidth("body"))_"'",1:"")_"/>")
			If containsFooter {
				if ..getColumnWidth("footer")'="none",..suppressFoTableColumn=0 Do XSL.WriteLine("<fo:table-column"_$s(..getColumnWidth("footer")'="none":" column-width='"_..XpathWidthExpression(..getColumnWidth("footer"))_"'",1:"")_"/>")
			}
		}
#endif
		if ..UseXSLT() {
			Set tLevel=..level // 106764
			Set sc=..DisplayFOChildrenByRows(.context,.XSL,.delay,tLevel, containsHeader, containsFooter,0,"table-body")
			If $$$ISERR(sc) RETURN sc
		} else { ; group="", sql'=""
			if ..UseSQL() {
				// use sql to generate table
				// Execute SQL and get back ResultSet that will be passed to loopitem children
				set sc=..GetResultSet(.context,.tLevel,.orderby,.top,.runonce,.tUpperCase)
				if $$$ISERR(sc) quit sc
				do CalcCache^%occZENReports(tLevel,1,orderby,top,runonce,tUpperCase)
			} elseif (..UseCallBack()) { // use methodCallBack 
				Set orderby=..orderby
				//Set tLevel=0 ; tables with ongetDatas don't allow nesting of tables within tables				
				Set tLevel=context("tablenesting")
			    kill %tParams
				Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"%tParams",.Count)
				if $g(tParameters)'="" X " Set "_tParameters				
				do $zobjmethod(%report,..ongetData,.var,.%tParams)
			    do CalcCacheFrom2DimArray^%occZENReports(tLevel,orderby,.var)
			}
			Set sc=..DisplayFOChildrenByRows(.context,.XSL,.delay,tLevel, containsHeader, containsFooter,1,"table-body")
			If $$$ISERR(sc) RETURN sc
		}
	} Else { // group '=""
		Set context("tableSection")="table-body"
		Set sc=..%DisplayRowCellsFO(.context,XSL,delay,.incell,"table-body") // JSL5216
		Kill context("tableSection")
	}

	Quit sc
}

Method %DisplayRowCellsFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, tableSection As %String) As %Status
{
		Set sc=$$$OK
		if tableSection="table-header" {
			Do XSL.WriteLine("<fo:table-header>")
			Do XSL.WriteLine("<fo:table-row>")
		}
		
		Set i = ..children.Next("")
		While i'="" {
			Set child = ..children.GetAt(i)
			d ..updateFromTemplate(.child)			
			Set child.parent=$$$THIS
			Set child.xpath=..parent.xpath_"/"_..group
			
			;If tableSection="table-body" {
			// ignore summary/caption/parameter children...these apply to the table itself.
				If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
					Set i=..children.Next(i) Continue
				}
			;}
			If ..canDisplay(child),'child.%Extends("%ZEN.Report.Display.xslt") {
				Set:child.class="" child.class=..class
				If tableSection="table-body" {
					Set mode="table"_$$$groupNum_"row"_i
				} ElseIf tableSection="table-header" {
					Set mode="tableheader"_$$$groupNum_"row"_i
				}
				// +Prodlog 102823
				Do XSL.WriteLine("<!-- Prodlog 102823 if -->")
				Do child.IfIncludeCol(.context,.XSL,.delay)
				// -Prodlog 102823

				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("<xsl:if test="""_child.xpath_"/"_child.field_"/text()"">")
				}
				If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
					Do XSL.WriteLine("<xsl:if test=""string("_child.field_")"">")
				}
				Do:tableSection="table-body" XSL.WriteLine("<fo:table-body>")
				If '..crosstab,child.crosstabHeaderGroup="",tableSection="table-body" {
					Do XSL.Write("<fo:table-row")
					If '..rowAcrossPages {
						Do XSL.Write(" keep-together.within-page='0'")
					}
					Do XSL.WriteLine(">")
				}
				if 'child.%Extends("%ZEN.Report.Display.xslt") {
					If tableSection="table-body" {
						Set:..containsHeader() sc = child.%DrawHeaderFO(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
					} else {
						Do:..containsHeader() XSL.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")
					}
					
				}
				$$$tableNumInc
				if tableSection="table-body" {
					Set call="table"_$$$tableNum
					Do ..%BeginGroup(.context,.XSL,.delay,mode,..qualify(..group))
					Do ..%DrawSort(.context,.XSL,.delay,..orderby,..dataType)
					Do ..%EndGroup(.context,.XSL,.delay,mode,..qualify(..group))
				} ElseIf tableSection="table-header" {
					Set call="table"_$$$tableNum
					Do ..%BeginGroupNoInc(.context,.XSL,.delay,mode,..qualify(..group))
					Do ..%EndGroup(.context,.XSL,.delay,mode,..qualify(..group))

				}
				if 'child.%Extends("%ZEN.Report.Display.xslt"),tableSection="table-body" Set:..containsFooter() sc = child.%DrawFooterFO(.context,.XSL,.delay,..oldSummary,..orient) q:$$$ISERR(sc)
				if '..crosstab,child.crosstabHeaderGroup="",(tableSection="table-body") Do XSL.WriteLine("</fo:table-row>")
				Do:tableSection="table-body" XSL.WriteLine("</fo:table-body>")
				Set delay2=##class(%GlobalCharacterStream).%New()
				Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
				Do ..%DeclareLevelParameters(.context,.delay,.delay2)
				Do delay.WriteLine("<xsl:param name='prevmatch' select='position()'/>") //JSL4323
				if $D(xslt) {
					if tableSection="table-body" { // JSL4285
						Set sc = xslt.%DrawCellFO(.context,.delay,.delay2) // JSL4285
					} ElseIf tableSection="table-header" {
						Do delay.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")
					}
				}
				If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
					Do XSL.WriteLine("</xsl:if>")
				}

				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("</xsl:if>")
				}

				// Prodlog 102823
				Do XSL.WriteLine("<!-- Prodlog 102823 endif -->")
				Do child.EndIfIncludeCol(.context,.XSL,.delay)
				// -Prodlog 102823
				if 'child.%Extends("%ZEN.Report.Display.xslt") {
					if tableSection="table-body" {
						Set sc = child.%DrawCellFO(.context,.delay,.delay2,..orient)
					} ElseIf tableSection="table-header" {
						Do delay.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")

					}
				} 
				do ..%EndLevel(.context,.delay,.delay2)
				Do delay.WriteLine("</xsl:template>")
				Do delay.CopyFrom(delay2)

			} Else {
				if child.%Extends("%ZEN.Report.Display.xslt") {
					Set xslt = child
				} else {
					// Could just ignore, but let's give feedback
					Do XSL.WriteLine("<tr><td style='font-weight:bold;color:red'>Cannot display table element: "_child.tag_".")
					Do XSL.WriteLine(" <br/>It must extend %ZEN.Report.Display.tableOutput</td></tr>")
				}
			}
			Set i= ..children.Next(i)
		}
		If tableSection="table-header" {
			Do XSL.WriteLine("</fo:table-row>")
			Do XSL.WriteLine("</fo:table-header>")
		}

		Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	New %number
	If ..group'="" $$$groupNumInc
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set context("tablenesting")=$i(context("tablenesting"))	
	Set tHasHtml5=1
	if $D(%request),$isobject(%request) {
		Set tHasHtml5=$s(%report.UseHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent),1:%report.UseHTML5)
	} else {
		Set tHasHtml5=%report.UseHTML5
	}
	// if HTML5 use float style attribute rather than obsolete align attribute
	// JSL for HTML5 add border-spacing attribute
	Do XSL.WriteLine("<table"_$s(tHasHtml5:"",1:" cellspacing='0' cellpadding='0.25'")_">") Do ..%StyleHTML(.context,.XSL,.delay,"",1,$s(tHasHtml5&(..align'=""):"float:"_..align_";",1:""))
	if 'tHasHtml5 {
		Do:..align'="" XSL.WriteLine("  <xsl:attribute name='align'>"_..align_"</xsl:attribute>")
	}
	// give children parent and class of containing table
	Set i = ..children.Next("")	
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set i= ..children.Next(i)
	}
	If ..staticTable=0 {
		If ..orient = "row"{
			Set sc = ..%DisplayTableByRows(.context,.XSL,.delay)
		} Else {	
			Set sc = ..%DisplayTableByCols(.context,.XSL,.delay)
		}
	} else {
			d ..tagChildren()
			Set i = ..children.Next("")
			While (i'="") {
				Set child = ..children.GetAt(i)
				d ..updateFromTemplate(.child)	
				Set child.parent=##this
				Set child.xpath=..parent.xpath
				Set:child.class="" child.class=..class
				if child.tag'="caption" Set sc = child.%DrawToHTML(.context,.XSL,.delay)
				Quit:$$$ISERR(sc)
				Set i= ..children.Next(i)
			}

	}

	Do XSL.WriteLine("</table>")
	Set context("tablenesting")=(context("tablenesting")-1)	
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DisplayTableByRows(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	d ..tagChildren()
	If ..group="" {
		If ..UseXSLT() {
			Set tLevel=..level // Prodlog 106764
			Set sc=..DisplayHTMLChildrenByRows(.context,.XSL,.delay,tLevel,0)
		} else { ; group="",sql'=""
			if ..UseSQL() {
				// use sql to generate table
				// Execute SQL and get back ResultSet that will be passed to loopitem children
				Set sc=..GetResultSet(.context,.tLevel,.orderby,.top,.runonce,.tUpperCase)
				if $$$ISERR(sc) quit sc
				do CalcCache^%occZENReports(tLevel,1,orderby,top,runonce,tUpperCase)
			} elseif (..UseCallBack()) { // use methodCallBack 
				Set orderby=..orderby
				//Set tLevel=0 ; tables with ongetDatas don't allow nesting of tables within tables
				Set tLevel=context("tablenesting")
			    kill %tParams
				Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"%tParams",.Count)
				if $g(tParameters)'="" X " Set "_tParameters				
				do $zobjmethod(%report,..ongetData,.var,.%tParams)
			    do CalcCacheFrom2DimArray^%occZENReports(tLevel,orderby,.var)
			}

			// loop over children given by loop element and draw them
			;WHILE $$Next^%occZENReports(1,tLevel,.tSCdummy) {
				Set sc=..DisplayHTMLChildrenByRows(.context,.XSL,.delay,tLevel,1)
				If $$$ISERR(sc) quit
			;}
		}
	} Else {
		Set i = ..children.Next("")
		While i'="" {
			Set child = ..children.GetAt(i)
			d ..updateFromTemplate(.child)			
			Set child.parent=$$$THIS
			Set child.xpath=..parent.xpath_"/"_..group
			
			// ignore summary/caption/parameter children...these apply to the table itself.
			If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
				Set i=..children.Next(i) Continue
			}

			If ..canDisplay(child) {
				Set:child.class="" child.class=..class
				Set mode="table"_$$$groupNum_"row"_i
				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("<xsl:if test="""_child.xpath_"/"_child.field_"/text()"">")
				}
				If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
					Do XSL.WriteLine("<xsl:if test=""string("_child.field_")"">")
				}



				if '..crosstab,child.crosstabHeaderGroup="" Do XSL.WriteLine("<tr>")
				if 'child.%Extends("%ZEN.Report.Display.xslt") Set:..containsHeader() sc = child.%DrawHeaderToHTML(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
				;d ..%BeginDrawFo(.context,.XSL,.delay)				
				$$$tableNumInc
				Set call="table"_$$$tableNum
				Do ..%BeginGroup(.context,.XSL,.delay,mode,..qualify(..group))
				Do ..%DrawSort(.context,.XSL,.delay,..orderby,..dataType)
				Do ..%EndGroup(.context,.XSL,.delay,mode,..qualify(..group))
				if 'child.%Extends("%ZEN.Report.Display.xslt") Set:..containsFooter() sc = child.%DrawFooterToHTML(.context,.XSL,.delay,..oldSummary,..orient) q:$$$ISERR(sc)
				if '..crosstab,child.crosstabHeaderGroup="" Do XSL.WriteLine("</tr>")
				If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
					Do XSL.WriteLine("</xsl:if>")
				}
					
				If ..removeEmpty,child.field'="" {
					Do XSL.WriteLine("</xsl:if>")
				}
			
				Set delay2=##class(%GlobalCharacterStream).%New()
				;Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"' name='"_call_"'>")
				Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
				Do ..%DeclareLevelParameters(.context,.delay,.delay2)
				Do delay.WriteLine("<xsl:param name='prevmatch' select='position()'/>") //JSL4323
				if ($D(xslt)) { // JSL4285
					Set sc = xslt.%DrawCellToHTML(.context,.delay,.delay2,..orient) // JSL4285
				}
				if 'child.%Extends("%ZEN.Report.Display.xslt") { // JSL4285
					Set sc = child.%DrawCellToHTML(.context,.delay,.delay2,..orient) // JSL4285
				} else {
					Set xslt=child // JSL4285
				}
				do ..%EndLevel(.context,.delay,.delay2)
				Do delay.WriteLine("</xsl:template>")
				Do delay.CopyFrom(delay2)

			} Else {
				// Could just ignore, but let's give feedback
				Do XSL.WriteLine("<tr><td style='font-weight:bold;color:red'>Cannot display table element: "_child.tag_".")
				Do XSL.WriteLine(" <br/>It must extend %ZEN.Report.Display.tableOutput</td></tr>")
			}
			Set i= ..children.Next(i)
		}
	}

	Quit sc
}

Method %DisplayTableByCols(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	if ..group '= "" {
		Set ..applyLevel=..applyLevel+1
	}
	d ..tagChildren()	
	Set mode = "table"_$$$groupNum
	Set headdata=##class(%GlobalCharacterStream).%New(),rowdata=##class(%GlobalCharacterStream).%New(),footdata=##class(%GlobalCharacterStream).%New()
	Set thead=""
	Set tfoot=""
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath_"/"_..group
		
		// ignore summary/caption/parameter children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter") {
			Set i=..children.Next(i) Continue
		}
		If (child.tag="thead") {
			Set thead=child
			Set i=..children.Next(i) Continue
		}
		If (child.tag="tfoot") {
			set tfoot=child
			Set i=..children.Next(i) Continue
		}

		If ..canDisplay(child) {
			Set:child.class="" child.class=..class
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}
			#; store header data
			
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawHeaderToHTML(.context,.headdata,.delay,..orient) q:$$$ISERR(sc)
			#; store row data(added to different places depending on group)
			if ..UseXSLT() Set sc=child.%DrawCellToHTML(.context,.rowdata,.delay,..orient) q:$$$ISERR(sc)
			#; store footer data (might need to insert row data first)
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc=child.%DrawFooterToHTML(.context,.footdata,.delay,..oldSummary,..orient) q:$$$ISERR(sc)
			
		} Else {
			Do XSL.WriteLine("<tr><td style='font-weight:bold;color:red'>Cannot display table element: "_child.tag_".")
			Do XSL.WriteLine(" <br/>It must extend %ZEN.Report.Display.tableOutput</td></tr>")
		}
		Set i= ..children.Next(i)
	}

	Do headdata.Rewind(),rowdata.Rewind(),footdata.Rewind()
	
	#; write header

	If ..containsHeader() {
		Do XSL.WriteLine("<thead><tr>")
		Do XSL.CopyFrom(headdata)
		Do XSL.WriteLine("</tr></thead>")
	}
	If thead'="" Set sc= thead.%DrawToHTML(.context,.XSL,.delay,1)
	If tfoot'="" Set sc= tfoot.%DrawToHTML(.context,.XSL,.delay,1)
	If ..group="" {
		If ..UseXSLT() {
			;rowdata may have more than 32767 bytes
			Do XSL.Write("<tbody><tr>")
			While (rowdata.AtEnd = 0) {
		    	Set len = 32000
		    	Do XSL.Write(rowdata.Read(.len))
			}
			Do XSL.WriteLine("</tr></tbody>")
		} else {
			if ..UseSQL() {
				// use sql to generate table
				// Execute SQL and get back ResultSet that will be passed to loopitem children
				set sc=..GetResultSet(.context,.tLevel,.orderby,.top,.runonce,.tUpperCase)
				if $$$ISERR(sc) quit sc
				do CalcCache^%occZENReports(tLevel,1,orderby,top,runonce,tUpperCase)
			} elseif (..UseCallBack()) { // use methodCallBack 
				Set orderby=..orderby
				//Set tLevel=0 ; tables with ongetDatas don't allow nesting of tables within tables				
				Set tLevel=context("tablenesting")
			    kill %tParams
				Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"%tParams",.Count)
				if $g(tParameters)'="" X " Set "_tParameters				
				do $zobjmethod(%report,..ongetData,.var,.%tParams)
			    do CalcCacheFrom2DimArray^%occZENReports(tLevel,orderby,.var)
			}
			// loop over children given by loop element and draw them
			WHILE $$Next^%occZENReports(1,tLevel,.tSCdummy) {
				Do XSL.WriteLine("<tr>")
				Set sc=..DisplayHTMLChildrenByCols(.context,.XSL,.delay,tLevel)
				Do XSL.WriteLine("</tr>")
				If $$$ISERR(sc) quit
			}
		}
	} Else {
		Do XSL.WriteLine("<tbody>")
		;d ..%BeginDrawFo(.context,.XSL,.delay)				
		$$$tableNumInc
		Set call="table"_$$$tableNum
		Do ..%BeginGroupNoInc(.context,.XSL,.delay,mode,..qualify(..group))
		Do ..%DrawSort(.context,.XSL,.delay,..orderby,..dataType)
		Do ..%EndGroup(.context,.XSL,.delay,mode,..qualify(..group))
		Do XSL.WriteLine("</tbody>")

		;Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"' name='"_call_"'><tr>")
		Do delay.WriteLine("<!-- by column table -->")
		Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
		Do ..%DeclareLevelParameters(.context,.delay,.delay2)		
		Do delay.WriteLine("<xsl:param name='prevmatch' select='position()'/>") //JSL4323
		Do delay.WriteLine("<!-- ordinary tr -->")
		Do delay.WriteLine("<tr>")
		if ..altcolor="" {
			Set altcolor=%report.TableAltColor
		} else {
			Set altcolor=..altcolor
		}

		If altcolor'="" {
			Do delay.WriteLine("<xsl:if test='(position() mod 2 = 0)'>")
			Do delay.WriteLine("<xsl:attribute name='style'>background-color:"_altcolor_";</xsl:attribute>")
			Do delay.WriteLine("</xsl:if>")
		}
		Do delay.CopyFrom(rowdata)
		Do delay.WriteLine("</tr></xsl:template>")
		do ..%EndLevel(.context,.delay,.delay2)
	}
	If ..containsFooter() {
		Do XSL.WriteLine("<tfoot><tr>")
		Do XSL.CopyFrom(footdata)
		Do XSL.WriteLine("</tr></tfoot>")
	}
	Quit sc
}

Method containsHeader() As %Boolean
{
	Set header=0,i = ..children.Next("")
	d ..tagChildren()
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		If ..canDisplay(child) {
			If child.hasHeader Set header=1 Quit
		} Else {
			//handle the error when displaying the table
			Quit
		}
		Set i= ..children.Next(i)
	}

	Quit header
}

Method containsFooter() As %Boolean
{
	Set footer=0,i=..children.Next("")
	d ..tagChildren()
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		If ..canDisplay(child) {
			If child.hasFooter Set footer=1 Quit
			If child.crosstabFooterGroup'="" Set footer=1 Quit
		} Else {
			//handle the error when displaying the table
			Quit
		}
		Set i= ..children.Next(i)
	}
	Quit footer
}

Method canDisplay(node As %RegisteredObject) As %Boolean [ Private ]
{
	Quit node.%Extends("%ZEN.Report.Display.tableOutput")
}

/// Note: <var>colType</var> is either "header", "body", or "footer"
/// used only in tables by row
Method getColumnWidth(colType As %String) As %String
{
	d ..tagChildren()
	Set width="",i=..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		// ignore summary/caption/parameter children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
			Set i=..children.Next(i) Continue
		}
		Set width=$case(colType,"header":child.%HeaderWidth(),"body":child.%Width(),"footer":child.%FooterWidth(),:"")
		If width'="" Quit
		
		Set i=..children.Next(i)
	}

	Quit $s((width="")&&(..defaultWidth=""):"proportional-column-width(1)",(width="")&&(..defaultWidth'=""):..defaultWidth,width="none":"none",1:..XpathWidthExpression(width))
}

Method childHasWidth() As %String
{
	d ..tagChildren()
	Set width="",i=..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		// ignore summary/caption/parameter children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
			Set i=..children.Next(i) Continue
		}
		Set width=child.%Width()
		If width'="" Quit
		
		Set i=..children.Next(i)
	}

	if ..defaultWidth="none",width="" quit 0
	quit 1
}

Method DisplayFOChildrenByCols(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pLevel As %Integer) As %Status
{
	Set sc=$$$OK
	d ..tagChildren() // JSL5217
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		If ..canDisplay(child),child.tag'="caption",child.tag'="summary",child.tag'="thead",child.tag'="tfoot",child.tag'="variable" {
			Set child.level = pLevel
			Set sc = child.%DrawCellFO(.context,.XSL,.delay,..orient)
		}
		If child.tag="variable" { // JSL5217
			Do child.%DrawToXSLFO(.context,.XSL,.delay)
		}
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}

	Quit sc
}

Method DisplayFOChildrenByRows(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pLevel As %Integer, containsHeader, containsFooter, IsSQL As %Boolean, tableSection As %String)
{

	Set sc=$$$OK
	Set i = ..children.Next("")
	Do XSL.WriteLine("<fo:"_tableSection_">")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)			
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
	
		// ignore summary/caption/parameter children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
			Set i=..children.Next(i) Continue
		}
	
		If ..canDisplay(child) {
			Set:child.class="" child.class=..class
			// +Prodlog 102823
			Do XSL.WriteLine("<!-- Prodlog 102823 if -->")
			Do child.IfIncludeCol(.context,.XSL,.delay)
			// -Prodlog 102823
			If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
				Do XSL.WriteLine("<xsl:if test=""string("_child.field_")"">")
			}

			If '..crosstab,child.crosstabHeaderGroup="" {
				Do XSL.Write("<fo:table-row")
				If '..rowAcrossPages {
					Do XSL.Write(" keep-together.within-page='0'")
				}
				Do XSL.WriteLine(">")
			}
			If containsHeader {
				If tableSection="table-body" {
					If 'child.%Extends("%ZEN.Report.Display.xslt") Set sc = child.%DrawHeaderFO(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
				} ElseIf tableSection="table-header" {
					Do XSL.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")
				}
					
			}
		
			Set child.level=pLevel ; needed for call-back tables directly populate by SQL, class queries, result sets, or call back methods
			if (IsSQL) {
				Do InitLoop^%occZENReports(pLevel)
				WHILE $$Next^%occZENReports(1,pLevel,.tSCdummy) {
					Set sc = child.%DrawCellFO(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
				}
			} else {
				If tableSection="table-body" {
					Set sc = child.%DrawCellFO(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
				} ElseIf tableSection="table-header" {
					Do XSL.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")					
				}
			}
		
			If containsFooter {
				if 'child.%Extends("%ZEN.Report.Display.xslt") Set sc = child.%DrawFooterFO(.context,.XSL,.delay,..oldSummary,..orient) q:$$$ISERR(sc)
			}

			if '..crosstab,child.crosstabHeaderGroup="" Do XSL.WriteLine("</fo:table-row>")
			If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
				Do XSL.WriteLine("</xsl:if>")
			}
			// Prodlog 102823
			Do XSL.WriteLine("<!-- Prodlog 102823 endif -->")
			Do child.EndIfIncludeCol(.context,.XSL,.delay)
			// -Prodlog 102823


		} Else {
			Do XSL.WriteLine("<fo:table-body><fo:table-row><fo:table-cell><fo:block color='red'> Cannot display table element: "_child.tag_".")
			Do XSL.WriteLine(" It must extend %ZEN.Report.Display.tableOutput</fo:block></fo:table-cell></fo:table-row></fo:table-body>")
			Quit
		}
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</fo:"_tableSection_">")
	quit sc
}

Method DisplayHTMLChildrenByRows(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pLevel As %Integer, IsSQL As %Boolean) As %Status
{
	Set sc=$$$OK
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)			
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
	
		// ignore summary/caption/parameter children...these apply to the table itself
		If (child.tag="summary")||(child.tag="caption")||(child.tag="parameter")||(child.tag="thead")||(child.tag="tfoot") {
			Set i=..children.Next(i) Continue
		}

		If ..canDisplay(child) {
			Set:child.class="" child.class=..class
			If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
				Do XSL.WriteLine("<xsl:if test=""string("_child.field_")"">")
			}
			if '..crosstab,child.crosstabHeaderGroup="" Do XSL.WriteLine("<tr>")

			if 'child.%Extends("%ZEN.Report.Display.xslt") Set:..containsHeader() sc = child.%DrawHeaderToHTML(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
			Set child.level=pLevel ; needed for call-back tables directly populate by SQL, class queries, result sets, or call back methods
			if (IsSQL) {
				Do InitLoop^%occZENReports(pLevel)
				WHILE $$Next^%occZENReports(1,pLevel,.tSCdummy) {
					Set sc = child.%DrawCellToHTML(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
				}
			} else {
				Set sc = child.%DrawCellToHTML(.context,.XSL,.delay,..orient) q:$$$ISERR(sc)
			}
			if 'child.%Extends("%ZEN.Report.Display.xslt") Set:..containsFooter() sc = child.%DrawFooterToHTML(.context,.XSL,.delay,..oldSummary,..orient) q:$$$ISERR(sc)
			if '..crosstab,child.crosstabHeaderGroup="" Do XSL.WriteLine("</tr>")
			If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
				Do XSL.WriteLine("</xsl:if>")
			}

		} Else {
			// Could just ignore, but let's give feedback
			Do XSL.WriteLine("<tr><td style='font-weight:bold;color:red'>Cannot display table element: "_child.tag_".")
			Do XSL.WriteLine(" <br/>It must extend %ZEN.Report.Display.tableOutput</td></tr>")
		}
		Set i= ..children.Next(i)
	}
	quit sc
}

Method DisplayHTMLChildrenByCols(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pLevel As %Integer)
{
	Set sc=$$$OK
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		;if child.tag="item" { // only draw items
		If ..canDisplay(child),child.tag'="caption",child.tag'="summary",child.tag'="thead",child.tag'="tfoot" {
			Set child.level = pLevel
			Set sc = child.%DrawCellToHTML(.context,.XSL,.delay,..orient)
		}
		;}
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	quit sc
}

Method UseXSLT()
{
	if ..sql="",..queryName="",..ongetData="",..onCreateResultSet="" {
		quit 1
	} else {
		quit 0
	}
}

Method UseSQL()
{
	if ..sql'=""||(..queryName'="")||(..onCreateResultSet'="") {
		quit 1
	} else {
		quit 0
	}
}

Method UseCallBack()
{
	if ..ongetData="" {
		quit 0
	} else {
		quit 1
	}
}

Method GetResultSet(ByRef context, ByRef tLevel, ByRef orderby, ByRef top, ByRef runonce, ByRef tUpperCase) As %Status [ Internal ]
{
	Set sc=$$$OK
	if ..onCreateResultSet="" {
		SET %tStatement = ##class(%SQL.Statement).%New()
		if ..selectmode'="" Set %tStatement.%SelectMode=..selectmode
		if ..sql'="" {
			SET sc = %tStatement.%Prepare(..sql)
			Set tUpperCase = 1 ; sql result sets have case-insensitive %Field(arg) - arg can be column name in *any* case
		} elseif ..queryName'="" {
			If ..queryClass="" {
				Set ..queryClass=%report.%ClassName(1)
			}
			Set sc = %tStatement.%PrepareClassQuery(..queryClass,..queryName)
			Set tUpperCase = 0 ; Class query result sets don't have case-insensitive %Field(arg) - arg has to be exact case
		} else {
			Set sc=$$$ERROR($$$GeneralError,"We are using SQL but sql, queryName, and onCreateResultSet are all null")
		}
		IF $$$ISERR(sc) Quit sc
		//Set tLevel=$i(^||%ISC.ZENReport.level)
		Set tLevel=+$g(context("tablenesting"))
		Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"",.Count)
		X " Set %rset = %tStatement.%Execute("_tParameters_")"
	    //Set tLevel=0 ; tables with sql or classqueries don't allow nesting of tables within tables
	    Set %query(tLevel)=%rset
		if %query(tLevel).%SQLCODE < 0 { quit $$$ERROR($$$SQLCode,%query(tLevel).%SQLCODE,%query(tLevel).%Message) }
	    Set orderby=..orderby
	    Set top=""
	    Set runonce=0
	} else {
	    Set tLevel=+$g(context("tablenesting"))		
	    kill %tParams
		Set tParameters=..%NormalizeParamList(..parameters,tLevel-1,0,"%tParams",.Count)
		if $g(tParameters)'="" X " Set "_tParameters
		Set rset=$zobjmethod(%report, ..onCreateResultSet,.sc,.%tParams)
		if $$$ISERR(sc) quit sc
	    //Set tLevel=0 ; tables with sql or classqueries don't allow nesting of tables within tables
	    //Set tLevel=$i(^||%ISC.ZENReport.level)
	    Set %query(tLevel)=rset
	    Set orderby=..orderby
	    Set top=""
	    Set tUpperCase=0
	    Set runonce=0

	}
	Quit sc
}

/// This internal method converts the parameter list for this group
/// into a run-time expression used to execute the query.
/// If <var>pArray</var> is defined, then it the expression will fill in
/// elements of an array named <var>pArray</var>.
Method %NormalizeParamList(pParameters As %ListOfObjects, pLevel As %Integer, setBreaks As %Boolean, pArray As %String = "", ByRef Count) As %String [ Internal ]
{
 #define quote(%val) $zutil(144,1,%val)
 //#define opr(%val) %val
	Set tCode = ""
	Set Count=pParameters.Count()
	For n=1:1:pParameters.Count() {
		Set tParm = pParameters.GetAt(n)
		Set tValue = $ZSTRIP(tParm.value,"<>W")
		Set tExpr = ""

		If (tParm.fieldnum'= "") {
			#; value is based on a field in the current query, identified by number
			Set tExpr="$$FieldLookupNum^%occZENReports("""_tParm.fieldnum_""","_pLevel_","_1_")"
		}
		ElseIf (tParm.fieldname '= "") {
			#; value is based on a field in the current query
			Set tExpr="$$FieldLookup^%occZENReports("""_tParm.fieldname_""","_pLevel_","_1_")"
		}
		Else {
			#; literal value
			Set tExpr = $$$quote(tValue)
		}

		#; test for expression
		If (tParm.expression '= "") {
			If ((tValue = "")&&(tParm.fieldname="")&&(tParm.fieldnum="")) {
				#; use expression directly
				Set tExpr = "(" _ tParm.expression _ ")"
			}
			Else {
				#; replace "%val" with current expression
				if (setBreaks) {
					if (tParm.fieldname'="") {
						Set tExpr="$$FieldLookup^%occZENReports("""_tParm.fieldname_""","_pLevel_","_1_")"
					} elseif (tParm.fieldnum'="") {
						Set tExpr="$$FieldLookupNum^%occZENReports("""_tParm.fieldnum_""","_pLevel_","_1_")"
					}
				}
				
				Set expr = tParm.expression 
				Set x = ""
				For p=1:1:$L(expr,"%val") {
					Set x = x _ $S(p=1:"",1:"("_tExpr_")") _ $P(tParm.expression,"%val",p)
				}
				Set tExpr = x
			}
		}
		If (pArray = "") {
			Set tCode = tCode _ $S(tCode="":"",1:",") _ tExpr
		}
		Else {
			Set tCode = tCode _ $S(tCode="":"",1:",") _ pArray _ "(" _ n _ ")=" _ tExpr
		}
	}
	Quit tCode
}

ClassMethod XpathWidthExpression(width As %String)
{
	Set width=$zstrip(width,"<>W") ; strip leading and trailing whitespace
	If $E(width)="$" { 
        quit "{"_width_"}"
    } Else { 
        quit width
    }
}

}
