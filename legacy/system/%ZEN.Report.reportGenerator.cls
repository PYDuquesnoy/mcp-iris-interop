/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %ZEN.ReportUtil)

/// 
Class %ZEN.Report.reportGenerator Extends %RegisteredObject [ Deprecated, System = 4 ]
{

XData ReportHeader
{
<document width="210mm" height="297mm" marginLeft="10mm" marginRight="10mm" marginTop="10mm" marginBottom="10mm" orientation="landscape" footerHeight="25.2mm" headerHeight="25.2mm"  >
<class name="table.leftpageheader">
<att name="width" value="277mm"/>
<att name="text-align" value="left"/>
</class>
<class name="th.leftpageheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="left"/>
</class>
<class name="td.leftpageheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="left"/>
</class>
<class name="table.rightpageheader">
<att name="width" value="100%"/>
</class>
<class name="th.rightpageheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="8pt"/>
<att name="font-weight" value="bold"/>
<att name="text-align" value="right"/> 
</class>
<class name="td.rightpageheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="18pt"/>
<att name="font-weight" value="bold"/>
<att name="text-align" value="right"/>
</class>

<class name="table.pagenumber">
<att name="width" value="100%"/>
</class>
<class name="th.pagenumber">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="right"/>
</class>
<class name="td.pagenumber">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="right"/>
</class>
<class name="table.datefooter">
<att name="width" value="100%"/>
</class>
<class name="th.datefooter">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="left"/>
</class>
<class name="td.datefooter">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="text-align" value="left"/>
</class>

<class name="table.mainheader">
<att name="width" value="100%"/>
</class>
<class name="th.mainheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="16pt"/>
<att name="font-weight" value="bold"/>
<att name="padding-right" value="10px"/>
<att name="text-align" value="center"/>
</class>
<class name="td.mainheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="14pt"/>
<att name="padding-right" value="10px"/>
<att name="text-align" value="center"/>
</class>
<class name="table.timeheader">
<att name="width" value="100%"/>
</class>
<class name="th.timeheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="10pt"/>
<att name="padding-right" value="10px"/>
<att name="text-align" value="center"/>
<att name="width" value="100%"/>
</class>
<class name="td.timeheader">
<att name="font-family" value="Arial"/>
<att name="text-align" value="center"/>
<att name="width" value="100%"/>
</class>

<class name="table.reportheader">
<att name="width" value="100%"/>
</class>
<class name="th.reportheader">
<att name="width" value="100%"/>
<att name="font-family" value="Arial"/>
<att name="font-size" value="12pt"/>
<att name="text-align" value="center"/>
<att name="padding-right" value="10px"/>
<att name="width" value="100%"/>
</class>
<class name="td.reportheader">
<att name="width" value="100%"/>
<att name="font-family" value="Arial"/>
<att name="font-size" value="12pt"/>
<att name="text-align" value="center"/>
<att name="padding-right" value="10px"/>
<att name="width" value="100%"/>
</class>

 <class name="table.data">
<att name="width" value="100%"/>
</class>
<class name="th.data">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="font-weight" value='bold' /> 
<att name="padding-right" value="10px"/>
<att name="border-bottom-style" value="solid"/>
</class>
<class name="td.data">
<att name="font-family" value="Arial"/>
<att name="font-size" value="9pt"/>
<att name="padding-right" value="10px"/>
</class>

<class name="p.mainheader">
<att name="width" value="100%"/>
<att name="font-family" value="Arial"/>
<att name="font-size" value="14pt"/>
<att name="text-align" value="center"/>
</class>
<class name="p.reportheader">
<att name="font-family" value="Arial"/>
<att name="font-size" value="12pt"/>
<att name="text-align" value="center"/>
</class>
</document>
}

/// Generate a ZEN Report<br>
/// className - name that generated ZEN Report will have, for instance pkgname.GeneratedReport<br>
/// reportName - name of ZEN Report, root element of generated XML<br>
/// queryClass - name of class for which report is generated<br>
/// queryName - name of query for which report is generated<br>
/// sortandgroup - if 1, we sort and group and next four parameters used, otherwise we don't sort and group<br>
/// GroupOption - name of option that determines grouping <br>
/// <ul>
/// <li>GroupOption's value determines the name of the GroupOption Property in the report.  A good name for this is "GroupOption".<br>
/// <li>If the GroupOption property is set to a non-null value this is used in %OnBeforeReport to set the "group".<br>
/// <li>A non-null "group" causes detail records to be placed under a value for the "group" in the report.  Each value for "group" will print on its own line.  Under "group" will be the 
/// other values in the report for which the group has a constant value.<br>
/// </ul>
/// SortOption - name of option that determines sorting of detail records.<br>
/// <ul>
/// <li>SortOption's value determines the name of the SortOption property in the report. A good name for this is "SortOption".
/// <li>The value of the property named in SortOption determines is used in %OnBeforeReport to select what field will sort the values that appear in the report.
/// <li>By default UniqueId is used for sorting.
/// </ul>
/// SortBy - name of support internal - set by SortOption, a good value for this is "SortBy" if no column in query named "SortBy"<br>
/// UniqueId - default sorting field of query, one can set this outside query, will be used to sort report columns if one group in report/columns within group if several groups within report<br>
ClassMethod Generate(className As %String, reportName As %String, queryClass As %String, queryName As %String, sortandgroup As %Boolean, GroupOption As %String, SortOption As %String, SortBy As %String, UniqueId) As %Status
{
	s Status=$$$OK
	do {
		Set Status=$ZObjClassMethod(queryClass,queryName_"GetInfo",.colinfo,.paraminfo,.idinfo,.qHandle)
		If $$$ISERR(Status) Quit 		
		
		For i=1:1:$LL(colinfo) {
			Set colname=$LI($LI(colinfo,i),1)
			Set colarray(colname)=colname
		}

		s Status= ..UrGenerate(className, reportName, $LL(colinfo), .colarray, "", queryClass, queryName , sortandgroup, GroupOption , SortOption , SortBy , UniqueId) 
	} while (0)
	q Status
}

/// Generate a ZEN Report<br>
/// className - name that generated ZEN Report will have, for instance pkgname.GeneratedReport<br>
/// reportName - name of ZEN Report, root element of generated XML<br>
/// sql - sql used in report generation<br>
/// sortandgroup - if 1, we sort and group and next four parameters used, otherwise we don't sort and group<br>
/// GroupOption - name of option that determines grouping <br>
/// <ul>
/// <li>GroupOption's value determines the name of the GroupOption Property in the report.  A good name for this is "GroupOption".<br>
/// <li>If the GroupOption property is set to a non-null value this is used in %OnBeforeReport to set the "group".<br>
/// <li>A non-null "group" causes detail records to be placed under a value for the "group" in the report.  Each value for "group" will print on its own line.  Under "group" will be the 
/// other values in the report for which the group has a constant value.<br>
/// </ul>
/// SortOption - name of option that determines sorting of detail records.<br>
/// <ul>
/// <li>SortOption's value determines the name of the SortOption property in the report. A good name for this is "SortOption".
/// <li>The value of the property named in SortOption determines is used in %OnBeforeReport to select what field will sort the values that appear in the report.
/// <li>By default UniqueId is used for sorting.
/// </ul>
/// SortBy - name of support internal - set by SortOption, a good value for this is "SortBy" if no column in query named "SortBy"<br>
/// UniqueId - default sorting field of query, one can set this outside query, will be used to sort report columns if one group in report/columns within group if several groups within report<br>
ClassMethod GenerateForSQL(className As %String, reportName As %String, sql As %String, sortandgroup As %Boolean, GroupOption As %String, SortOption As %String, SortBy As %String, UniqueId) As %Status
{
	s Status=$$$OK
	do {
		// Get meta-information for SQL statement
		
		Set rset = ##class(%ResultSet).%New()
		Do rset.Prepare(sql)
        Set columns = rset.GetColumnCount()
 		// Execute the query
 		Set sc = rset.Execute()
 		// Now fetch the results
        For col = 1:1:columns {
            Set colname=rset.GetColumnName(col)
            Set colarray(colname)=colname
        }

		Do rset.Close()


		s Status= ..UrGenerate(className, reportName, columns, .colarray, sql, "", "" , sortandgroup, GroupOption , SortOption , SortBy , UniqueId) 
	} while (0)
	q Status
}

/// Generate a ZEN Report<br>
/// className - name that generated ZEN Report will have, for instance pkgname.GeneratedReport<br>
/// reportName - name of ZEN Report, root element of generated XML<br>
/// colarray<br> 
/// sql - sql string - if "" using queryClass and queryName<br>
/// queryClass - name of class for which report is generated<br>
/// queryName - name of query for which report is generated<br>
/// GroupOption - name of option that determines grouping <br>
/// SortOption - name of option that determined sorting of detail records <br>
/// SortBy - name of support internal - set by SortOption, a good value for this is "SortBy" if no column in query named "SortBy"<br>
/// UniqueId - default sorting field of query, one can set this outside query, will be used to sort report columns if one group in report/columns within group if several groups within report<br>
ClassMethod UrGenerate(className As %String, reportName As %String, columns As %Integer, ByRef colarray As %String, sql As %String, queryClass As %String, queryName As %String, sortandgroup As %Boolean, GroupOption As %String, SortOption As %String, SortBy As %String, UniqueId) As %Status [ Internal ]
{
		do {
		
			s Status=$$$OK

			Set classdef=##class(%Dictionary.ClassDefinition).%OpenId(className)
			if classdef'="" {
				write !,"Deleting"_className
				do ##class(%Dictionary.ClassDefinition).%DeleteId(className)
			} 
			Set classdef=##class(%Dictionary.ClassDefinition).%New(className)
			Set classdef.Super="%ZEN.Report.reportPage"
			Set classdef.ProcedureBlock=1
			Set Status=classdef.%Save()
			If $$$ISERR(Status) Quit 
			; Create Report parameters such as XSLTMODE
			Set Status=..CreateParameter(className,"XSLTMODE","server")
			If $$$ISERR(Status) Quit 
			; Create ZENURL properties corresponding to parameters
			Set paraminfo=""
			if (sql="") {
				Set Status=$ZObjClassMethod(queryClass,queryName_"GetInfo",.colinfo,.paraminfo,.idinfo,.qHandle)
			} else {
				Set colname=""
				Set colname=$o(colarray(colname))
				Set colinfo=""
				while (colname'="") {
					Set colinfo=colinfo_$LB($LB(colname))
					Set colname=$o(colarray(colname))
				}
			}
			If $$$ISERR(Status) Quit 
			if sortandgroup Set Status=..CreateProperty(className,"GroupBy","%String",0)
			If $$$ISERR(Status) Quit 
			Set GroupOptionPresent=0
			Set SortOptionPresent=0
			Set SortByPresent=0
			for i=1:1:$ListLength(paraminfo) {
				if $List($List(paraminfo,i),1)=GroupOption Set GroupOptionPresent=1
				if $List($List(paraminfo,i),1)=SortOption Set SortOptionPresent=1
				if $List($List(paraminfo,i),1)=SortBy Set SortByPresent=1
				Set Status=..CreateProperty(className,$List($List(paraminfo,i),1),..decodetype($List($List(paraminfo,i),2)),1)
				If $$$ISERR(Status) quit
			}			
			if (sortandgroup) {
				if GroupOptionPresent=0 Set Status=..CreateProperty(className,GroupOption,"%String",1)
				If $$$ISERR(Status) quit 
				if SortOptionPresent=0 Set Status=..CreateProperty(className,SortOption,"%String",1)
				If $$$ISERR(Status) quit 
				if SortByPresent=0 Set Status=..CreateProperty(className,SortBy,"%String",0)
				If $$$ISERR(Status) quit 
			}
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set xdataname="ReportDefinition"
			Set stream=..CreateReportDefinition(reportName, sql, queryClass, queryName,sortandgroup,.colarray,colinfo,paraminfo,UniqueId)
			Set Status=..CreateXDataSection(className, xdataname,stream,"http://www.intersystems.com/zen/report/definition")
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set xdataname="ReportDisplay"
			Set stream=..CreateReportDisplay(reportName,.colarray,colinfo,sortandgroup,GroupOption,SortOption,SortBy)
			Set Status=..CreateXDataSection(className, xdataname,stream,"http://www.intersystems.com/zen/report/display")
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			if sortandgroup Set Status=..CreateOnBeforeReportMethod(className,.colarray,colinfo,GroupOption,SortOption,SortBy,UniqueId)
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set Status=##class(%SYSTEM.OBJ).Compile(className,"k")	
			If $$$ISERR(Status) quit 
		
		} while(0) 
		q Status
}

ClassMethod CreateReportDefinition(reportName As %String, sql As %String, queryClass As %String, queryName As %String, sortandgroup As %Boolean, ByRef colarray As %String, colinfo As %List, paraminfo As %List, UniqueId As %String) [ Internal ]
{
		if (sql'="") {
			; replace single-quotes ' in sql with &apos;
			Set tSql=$$$REPLACE(sql,"'","&apos;")

		}
		Set stream = ##class(%Stream.TmpCharacter).%New()
		Do stream.WriteLine("<report xmlns='http://www.intersystems.com/zen/report/definition'")
		if (sql="") {
			Do stream.Write("   queryClass='"_ queryClass_"' queryName='"_queryName_"' ")
		} else {

			Do stream.Write(" sql='"_tSql_"' ")
		}
		Do stream.WriteLine(" top='1' name='"_reportName_"'>")
		For i=1:1:$LL(paraminfo) {
			Do stream.WriteLine("  <parameter expression='.."_$LI($LI(paraminfo,i),1)_"'/>")
		}
		Do stream.WriteLine("  <group name=""ReportTime"">")
		Do stream.WriteLine("  <attribute name='timestamp' expression='$ZDATETIME($H, 2, 2)'/>")
		Do stream.WriteLine("  </group>")

		if (sql="") {
			Do stream.WriteLine("      <group name='Details' queryClass='"_queryClass_"' queryName='"_queryName_"'"_$s(sortandgroup:" orderby='!..GroupBy'",1:"")_" >")
		} else {
			Do stream.WriteLine("      <group name='Details' sql='"_tSql_"' "_$s(sortandgroup:" orderby='!..GroupBy'",1:"")_" >")
		}
		For i=1:1:$LL(paraminfo) {
		    Do stream.WriteLine("         <parameter expression='.."_$LI($LI(paraminfo,i),1)_"'/>")
		}
		Do stream.WriteLine("         <aggregate name='TotalEpisodes' type='CUSTOM' field='"_UniqueId_"' class='%ZEN.Report.Aggregate.CountDistinct'/>")
		if sortandgroup Do stream.WriteLine("         <group name='GroupBy1' breakOnField='!..GroupBy'>")
		Do stream.WriteLine("           <group name='Detail'>")
		if sortandgroup Do stream.WriteLine("            <element field='!..GroupBy' name='groupby'/>")
		if sortandgroup Do stream.WriteLine("            <element name='groupbynull' field='!..GroupBy' expression='%val=""""'/>")
		For i=1:1:$LL(colinfo) {
			Set colname=$LI($LI(colinfo,i),1)
			if $D(colarray(colname)) {
				Do stream.WriteLine("            <attribute field='"_colname_"' name='"_colname_"'/>")
			}
		}
		Do stream.WriteLine("           </group>")
		if sortandgroup Do stream.WriteLine("         <aggregate name='groupbycount' type='CUSTOM' field='"_UniqueId_"' class='%ZEN.Report.Aggregate.CountDistinct'/>")
		Do stream.WriteLine("         </group>")
		if sortandgroup Do stream.WriteLine("      </group>")
		Do stream.WriteLine("</report>")
		quit stream
}

ClassMethod CreateReportDisplay(reportName As %String, ByRef colarray As %String, colinfo As %List, sortandgroup As %Boolean, GroupOption As %String, SortOption As %String, SortBy As %String) [ Internal ]
{
	Set stream = ##class(%Stream.TmpCharacter).%New()
	Do stream.WriteLine("<report xmlns='http://www.intersystems.com/zen/report/display'")
	Do stream.WriteLine("   name='"_reportName_"'>")
		
	do ..CopyReportPageXdata(stream, "ReportHeader")
	
	; page header
	do stream.WriteLine("<pageheader width='277mm' >")
	do stream.WriteLine("<table orient='col' width='100%'   >")

	do stream.WriteLine("<item class='leftpageheader' value='Current Admissions' width='50%'/> ")
	do stream.WriteLine("<item class='rightpageheader' value='XYZ Company' width='50%'/>")
	do stream.WriteLine("</table>")
	do stream.WriteLine("<line pattern='solid' width='100%'></line> ")
	do stream.WriteLine("</pageheader>")
	
	; page footer
	do stream.WriteLine("<pagefooter width='277mm'>")
	do stream.WriteLine("<line pattern='solid' width='100%'></line>")
	do stream.WriteLine("<table width='100%'>")
	do stream.WriteLine("<item field=""concat(&quot;Created on &quot;, ReportTime/@timestamp, &quot; by &quot;, /CurrentAdmissions/username )"" class='datefooter' width='5in' literalSpaces='1'/>")
	do stream.WriteLine("<item special='page-number-of' class='pagenumber'  width='5in'/>")
	do stream.WriteLine("</table>")
	do stream.WriteLine("</pagefooter>")
	
	; report body
	do stream.WriteLine("<body>")
	do stream.WriteLine("<!-- REPORT HEADER -->")
	do stream.WriteLine("<header>")
	do stream.WriteLine("<table class='reportheader' orient='row' defaultWidth='none' layout='auto'>")
	do stream.WriteLine("<item value=' '>")
	do stream.WriteLine("<caption class='mainheader' value='Report Header'/>")
	do stream.WriteLine("</item>")
	do stream.WriteLine("<item value= "" "">")
	do stream.WriteLine("<caption class=""timeheader"" field=""concat(&quot;As at &quot;,ReportTime/@timestamp)""/>")
	do stream.WriteLine("</item>")
	do stream.WriteLine("</table>")
	do stream.WriteLine("<line style=""none""/>")
	do stream.WriteLine("</header>")

	do stream.WriteLine("<group name='Details'>")
	if sortandgroup {
		do stream.WriteLine("  <group name='GroupBy1' pagebreak='true'>")
		do stream.WriteLine("     <table orient='row'>")
	    do stream.WriteLine("       <item field='Detail/groupby' unlessexpression='%report."_GroupOption_"=""""' />")
		do stream.WriteLine("     </table>")
	}
	do stream.WriteLine("     <table class='data' orient='col' group='Detail'  "_$s(sortandgroup:"orderby='!%report."_SortBy_"'",1:"")_">")
	for i=1:1:$LL(colinfo) {
		Set colname=$LI($LI(colinfo,i),1)
		if $D(colarray(colname)) {
			Do stream.WriteLine("        <item field='@"_colname_"'"_$s(sortandgroup:" includeColUnlessExpression='%report."_GroupOption_"="""_$LI($LI(colinfo,i),1)_"""'",1:"")_">")
			Do stream.WriteLine("            <caption value='"_colarray(colname)_"'"_$s(sortandgroup:" includeColUnlessExpression='%report."_GroupOption_"="""_colname_"""'",1:"")_"/>")
			Do stream.WriteLine("        </item>")
		}
	}
	Do stream.WriteLine("     </table>")
	if (sortandgroup) {
		Do stream.WriteLine("<table orient=""row"" width=""6in"">")
		Do stream.WriteLine("<item field='concat(""Total for "",Detail/groupby,"": "",groupbycount, "" Episodes"")' style=""text-align:left"" ifxpath=""number(Detail/groupbynull)=0"" /> ")
		Do stream.WriteLine("<item field='concat(""Total for "",""Not Recorded"","": "",groupbycount, "" Episodes"")' style=""text-align:left"" ifxpath=""number(Detail/groupbynull)=1"" unlessexpression='%report."_GroupOption_"=""""'/> ")
		Do stream.WriteLine("</table>")
	}
	Do stream.WriteLine("<line pattern=""empty"" width=""100%""></line> ")
	Do stream.WriteLine("   </group>")
	if sortandgroup Do stream.WriteLine("</group>")
	Do stream.WriteLine("<footer foStyle='text-align=&quot;end&quot;'>")
	Do stream.WriteLine("<table orient='row' width='6in' style='text-align:left'>")
	Do stream.WriteLine("<item field='concat(""Total for "","" Details "", Details/TotalEpisodes,"" Episodes"")'/>")
	Do stream.WriteLine("</table>")
	Do stream.WriteLine("</footer>")
	Do stream.WriteLine("</body>")
	Do stream.WriteLine("</report>")
	quit stream
}

ClassMethod CreateXDataSection(className As %String, xdataname As %String, stream As %Stream.TmpCharacter, namespace As %String) As %Status [ Internal ]
{
		Set xdata=##class(%Dictionary.XDataDefinition).%New(className_":"_xdataname)
		Set xdata.XMLNamespace=namespace
		Set xdata.Data=stream
		Set Status=xdata.%Save()
		q Status
}

ClassMethod CreateProperty(className As %String, Name As %String, Type As %String, isZENURL As %Boolean) [ Internal ]
{
	s Status=$$$OK
	do {
		Set property=##class(%Dictionary.PropertyDefinition).%New(className_":"_Name)
		Set property.Type=Type
		if isZENURL {
			Set Status=property.Parameters.SetAt($zcvt(Name,"u"),"ZENURL")
		}
		If $$$ISERR(Status) q 
		Set Status=property.%Save()
	} while (0)
	q Status
}

ClassMethod CreateParameter(className As %String, Name As %String, Default As %String) [ Internal ]
{
	s Status=$$$OK
	do {
		Set parameter=##class(%Dictionary.ParameterDefinition).%New(className_":"_Name)
		Set parameter.Default=Default
		Set Status=parameter.%Save()
	} while (0)
	q Status
}

ClassMethod decodetype(clientdatatypeenum As %Integer) As %String [ Internal ]
{
		
#define VOID             0
#define BINARY           1
#define DATE             2
#define DOUBLE           3
#define HANDLE           4
#define INTEGER          5
#define LIST             6
#define LONGVARCHAR      7
#define TIME             8
#define TIMESTAMP        9
#define VARCHAR         10
#define STATUS          11
#define BINARYSTREAM    12
#define CHARACTERSTREAM 13
#define NUMERIC         14
#define CURRENCY        15
#define BOOLEAN         16
#define OID             17
 ; below same as BIGINT
#define LONG            18 
#define FDATE           19
#define FTIMESTAMP      20
	;
	Set val=""
	If clientdatatypeenum=$$$BINARY      Set val="%Binary"
	If clientdatatypeenum=$$$BOOLEAN     Set val="%Boolean"
	If clientdatatypeenum=$$$CURRENCY    Set val="%Currency"
	If clientdatatypeenum=$$$DATE        Set val="%Date"
	If clientdatatypeenum=$$$FDATE       Set val="%FilemanDate"
	If clientdatatypeenum=$$$DOUBLE      Set val="%Double"
	If clientdatatypeenum=$$$HANDLE      Set val="%ObjectHandle"
	If clientdatatypeenum=$$$INTEGER     Set val="%Integer"
	If clientdatatypeenum=$$$LIST        Set val="%List"
	If clientdatatypeenum=$$$LONG        Set val="%BigInt"
	If clientdatatypeenum=$$$OID         Set val="%ObjectIdentity"
	If clientdatatypeenum=$$$LONGVARCHAR Set val="%String"
	If clientdatatypeenum=$$$NUMERIC     Set val="%Numeric"
	If clientdatatypeenum=$$$STATUS      Set val="%Status"
	If clientdatatypeenum=$$$TIME        Set val="%Time"
	If clientdatatypeenum=$$$TIMESTAMP   Set val="%TimeStamp"
	If clientdatatypeenum=$$$FTIMESTAMP  Set val="%FilemanTimeStamp"
	If clientdatatypeenum=$$$VARCHAR     Set val="%String"
	If clientdatatypeenum=$$$VOID        Set val=""
	If clientdatatypeenum=$$$BINARYSTREAM Set val="%GlobalCharacterStream"
	If clientdatatypeenum=$$$CHARACTERSTREAM Set val="%GlobalBinaryStream"
	Quit val
}

ClassMethod CopyReportPageXdata(ByRef stream As %GlobalCharacterStream, XdataName As %String) As %Status [ Internal ]
{
	s Status=$$$OK
	Set me = ##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1))
	if ($isObject(me)) {
		Set idx = me.XDatas.FindObjectId(..%ClassName(1)_"||"_XdataName)
		if (idx="") quit
		Set data = me.XDatas.GetAt(idx).Data
		if $isObject(data) {
			Do data.Rewind()
			Do stream.CopyFrom(data)
		}
	} else {
		Set Status=$$$ERROR(-777,"Could not open Xdata "_XdataName)	
	}
	quit Status
}

ClassMethod CreateOnBeforeReportMethod(className As %String, ByRef colarray As %String, colinfo As %List, GroupOption As %String, SortOption As %String, SortBy As %String, UniqueId As %String) As %Status [ Internal ]
{
	Set Status=$$$OK
	do {
		set method=##class(%Dictionary.MethodDefinition).%New(className_":"_"%OnBeforeReport")
		set method.ReturnType="%Status"
		Set stream = ##class(%Stream.TmpCharacter).%New()		
		Do stream.WriteLine(" Set Status=$$$OK")
		Do stream.WriteLine(" if .."_GroupOption_"="""" {")
		Do stream.WriteLine("   Set ..GroupBy=""""")
		Do stream.WriteLine(" }")
		for i=1:1:$LL(colinfo) {
			Set colname=$LI($LI(colinfo,i),1)
			if '$D(colarray(colname)) continue
			Do stream.WriteLine(" elseif .."_GroupOption_"="""_colname_""" {")
			Do stream.WriteLine("   Set ..GroupBy="""_colname_"""")
			Do stream.WriteLine(" }")
		}
		for i=1:1:$LL(colinfo) {
			Set colname=$LI($LI(colinfo,i),1)
			if '$D(colarray(colname)) continue
			if i=1 Do stream.WriteLine(" if .."_SortOption_"="""_colname_""" {")
			if i'=1 Do stream.WriteLine(" elseif .."_SortOption_"="""_colname_""" {")
			Do stream.WriteLine("   Set .."_SortBy_"=""@"_colname_"""")
			Do stream.WriteLine(" }")
		}
		Do stream.WriteLine(" else {")
		if $LL(colinfo)'=0 Do stream.WriteLine("  Set .."_SortBy_"=""@"_UniqueId_"""")
		Do stream.WriteLine(" }")
		Do stream.WriteLine(" Quit Status")
		Set method.Implementation=stream
		set Status=method.%Save()
	} while (0)
	q Status
}

ClassMethod GetMetaData(queryClass As %String, queryName As %String, ByRef ColNames, ByRef Params) [ Internal ]
{
	set Status=$$$OK
	do {
		Set Status=$ZObjClassMethod(queryClass,queryName_"GetInfo",.colinfo,.paraminfo,.idinfo,.qHandle)
		If $$$ISERR(Status) Quit 
		for i=1:1:$LL(colinfo) {
			Set ColNames($LI($LI(colinfo,i),1))=""
		}
		for i=1:1:$LL(paraminfo) {
			Set Params($LI($LI(paraminfo,i),1))=""
		}

	} while(0)
	quit Status
}

}
