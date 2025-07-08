/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Generate Pivot Table from information about the table
Class %ZEN.Report.pivotTableGenerator Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// class name of generated ZEN Report
Property className As %String;

/// class name of generated ZEN Report for totals (use get to add this report to XML)
Property classNameForTotals As %String;

/// report name of generated ZEN Report
Property reportName As %String [ InitialExpression = "MyReport" ];

/// report name of generated ZEN Report for totals
/// Property reportNameForTotals As %String [ InitialExpression = "MyReport" ];
/// table of data that will be object of pivot
Property table As %String;

/// group used in XML of generated ZEN Report
Property group As %String [ InitialExpression = "group1" ];

/// column that appears in columns 2-n of pivot table
Property cols As %String;

/// column that appears in column 1 of pivot table
Property rows As %String;

/// field that will be accumulated
Property value As %String;

/// aggregate that does the accumulating (SUM, COUNT, CUSTOM, etc.,)
Property aggs As list Of %ZEN.Report.aggregate;

Method genZenReport() As %Status
{
		do {
		
			s Status=$$$OK
			set className=..className
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
			; Create Report parameters such as DEFAULTMODE
			Set Status=..CreateParameter(className,"XSLTMODE","server")
			Set Status=..CreateParameter(className,"DEFAULTMODE","html")
			If $$$ISERR(Status) Quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set xdataname="ReportDefinition"
			Set stream=..genReportDefinition()
			Set Status=..CreateXDataSection(className, xdataname,stream,"http://www.intersystems.com/zen/report/definition")
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set xdataname="ReportDisplay"
			Set stream=..genReportDisplay()
			Set Status=..CreateXDataSection(className, xdataname,stream,"http://www.intersystems.com/zen/report/display")
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set Status=##class(%SYSTEM.OBJ).Compile(className,"k")	
			If $$$ISERR(Status) quit 
			Set Status=..genZenReportForTotals()
		} while(0) 
		q Status
}

Method genZenReportForTotals()
{
		do {
		
			s Status=$$$OK
			set className=..classNameForTotals
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
			; Create Report parameters such as DEFAULTMODE
			;Set Status=..CreateParameter(className,"XSLTMODE","server")
			Set Status=..CreateParameter(className,"DEFAULTMODE","xml")
			If $$$ISERR(Status) Quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set xdataname="ReportDefinition"
			Set stream=..genReportDefinitionForTotals()
			Set Status=..CreateXDataSection(className, xdataname,stream,"http://www.intersystems.com/zen/report/definition")
			If $$$ISERR(Status) quit 
			Set Status=classdef.%Save()
			If $$$ISERR(Status) quit 
			Set Status=##class(%SYSTEM.OBJ).Compile(className,"k")	
			If $$$ISERR(Status) quit 
		} while(0) 
		q Status
}

Method genReportDefinition() As %CharacterStream
{
		 Set stream = ##class(%Stream.TmpCharacter).%New()
		 Do stream.WriteLine("<report xmlns=""http://www.intersystems.com/zen/report/definition""")
 		 Do stream.WriteLine(" name="""_..reportName_""" sql=""SELECT "_..cols_","_..rows_","_..value_" From "_..table_" order by "_..rows_","_..cols_""">")
 		 for i=1:1:$L(..rows,",") {
	 		 s row=$P(..rows,",",i) 
	 		 Do stream.WriteLine("  <group name="""_row_""" breakOnField="""_row_""">")
 		 	 Do stream.WriteLine("  <attribute name="""_row_""" field="""_row_"""/>")
 		 	 Do ..generateTotals(.stream)
 		 }
	 	 Do stream.WriteLine("    <group name="""_..group_""">")
	 	 for k=1:1:$L(..cols,",") {
		 	s col=$P(..cols,",",k)
	 	 	Do stream.WriteLine("    <attribute name="""_col_""" field="""_col_"""/>")
	 	 }
	 	 Do stream.WriteLine("    <attribute name="""_..value_""" field="""_..value_"""/>")
		 Do stream.WriteLine("    </group>")
		 for i=1:1:$L(..rows,",") Do stream.WriteLine("    </group>")
		 Do ..generateTotals(.stream) 		 
		 ;Do stream.WriteLine(" </group>")
		 d ##class(%RoutineMgr).GetWebServerPort(.port)
		 Do stream.WriteLine(" <get host='localhost' port='"_port_"' url='/csp/"_$zcvt($namespace,"l")_"/"_..classNameForTotals_".cls?$MODE=xml&amp;$STRIPPI=1'/>")
		 Do stream.WriteLine(" </report>")
		 quit stream
}

Method generateTotals(ByRef stream As %CharacterStream)
{
 	 set query="SELECT "_..cols_" FROM "_..table_" GROUP BY "_..cols
 	 set rs=##class(%ResultSet.SQL).%Prepare(query,.tError)
     set pSC=$$$OK
	 if $isobject(tError) { set pSC = tError.Status } else { set pSC = $$$OK } 
	 if $$$ISERR(pSC) d DecomposeStatus^%apiOBJ(pSC,.Err) w !,Err(Err) ;'

	 While (rs.%Next(.tSC)) {
    	s sep=""
    	s aggname=""
    	s cond=""
    	for j=1:1:$L(..cols,",") {
        	s col=$P(..cols,",",j)
        	Set name=rs.%Get(col)
        	s aggname=aggname_sep_$tr(name," ","_")
        	s sep="_"
           	if j=1 s cond=..cond(col,name)
	       	if j>1 s cond="("_cond_") &amp;&amp; ("_..cond(col,name)_")"
			if '$D(Seen(aggname)) {	        	
			   	s Seen(aggname)=cond

        	}

    	}
    	
	 }
   	Set aggname=""
   	Set aggname=$o(Seen(aggname),1,cond)
   	while (aggname'="") {
	   	// process list of aggregates
	   	for i=1:1:..aggs.Size {
		   	Set agg=..aggs.GetAt(i)
    		Do stream.WriteLine("  <aggregate name="""_aggname_"_"_agg.name_""" field="""_..value_""" fields="""_..cols_""" accumIf='"_cond_"' type="""_agg.type_""" "_$s(agg.class'="":"class='"_agg.class_"'",1:"")_"/>")		    	
	   	}
    	Set aggname=$o(Seen(aggname),1,cond)
   	}
   	for i=1:1:..aggs.Size {
	   	Set agg=..aggs.GetAt(i)
		Do stream.WriteLine("  <aggregate name=""TOTAL_"_agg.name_""" field="""_..value_""" type="""_agg.type_""" "_$s(agg.class'="":"class='"_agg.class_"'",1:"")_"/>")
   	}
}

Method generateItems(ByRef stream As %CharacterStream)
{
 	 set query="SELECT "_..cols_" FROM "_..table_" GROUP BY "_..cols
 	 set rs=##class(%ResultSet.SQL).%Prepare(query,.tError)
     set pSC=$$$OK
	 if $isobject(tError) { set pSC = tError.Status } else { set pSC = $$$OK } 
	 if $$$ISERR(pSC) d DecomposeStatus^%apiOBJ(pSC,.Err) w !,Err(Err) ;'

	 While (rs.%Next(.tSC)) {
    	s sep=""
    	s aggname=""
    	s cond=""
    	for j=1:1:$L(..cols,",") {
        	s col=$P(..cols,",",j)
        	Set name=rs.%Get(col)
        	s aggname=aggname_sep_$tr(name," ","_")
        	s sep="_"
           	if j=1 s cond=name
	       	if j>1 s cond=cond_","_name
			if '$D(Seen(aggname)) {	        	
			   	s Seen(aggname)=cond

        	}

    	}
    	
	 }
   	Set aggname=""
   	Set aggname=$o(Seen(aggname),1,cond)
   	while (aggname'="") {
	   	for k=1:1:..aggs.Size {
		   	Set agg=..aggs.GetAt(k)

	       	Do stream.WriteLine("<item field="""_aggname_"_"_agg.name_""" formatNumber='###,###,###,###,###,###,##0.##'>")
			Do stream.WriteLine("</item>")
	   	}
       	Set aggname=$o(Seen(aggname),1,cond)
   	}
}

Method generateHeaders(ByRef stream As %CharacterStream, row As %Integer, pCol As %Integer)
{
 	 set query="SELECT "_..cols_" FROM "_..table_" GROUP BY "_..cols
 	 set rs=##class(%ResultSet.SQL).%Prepare(query,.tError)
     set pSC=$$$OK
	 if $isobject(tError) { set pSC = tError.Status } else { set pSC = $$$OK } 
	 if $$$ISERR(pSC) d DecomposeStatus^%apiOBJ(pSC,.Err) w !,Err(Err) ;'

	 While (rs.%Next(.tSC)) {
    	s sep=""
    	s aggname=""
    	s cond=""
    	for j=1:1:$L(..cols,",") {
	        	s col=$P(..cols,",",j)
	        	Set name=rs.%Get(col)
	        	s aggname=aggname_sep_$tr(name," ","_")
	        	s sep="_"
	           	if j=1 s cond=name
		       	if j>1 s cond=cond_","_name
				if '$D(Seen(aggname)) {	        	
				   	s Seen(aggname)=cond
	
        		}

    	}
    	
	 }
   	Set aggname=""
   	Set aggname=$o(Seen(aggname),1,cond)
   	while (aggname'="") {
	   	for k=1:1:..aggs.Size {
		   	Set agg=..aggs.GetAt(k)

#if 1		
			Do stream.WriteLine("<th style='text-align:right'>")
			for i=1:1:$L(cond,",") {
				Set header=$P(cond,",",i)
				;if i=1 Set sep=""
				;i i>1 Set sep="<br/>"
				if (i # $L(..cols,","))=(pCol# $L(..cols,",")) Do stream.WriteLine("<item value='"_header_"'/>")


			}
			Do stream.WriteLine("</th>")

#endif		
			
	   	}
       	Set aggname=$o(Seen(aggname),1,cond)
   	}
    for j=1:1:..aggs.Size {
        //totals
	   	Set agg=..aggs.GetAt(j)
	   	Do stream.WriteLine("<th style='text-align:right'>")
		if pCol=$L(..cols,",") Do stream.WriteLine("<item value='"_$zcvt("TOTAL","T")_"'/>")
		Do stream.WriteLine("</th>")
    }
	if ($L(..rows,",") > 1)&&(row<$L(..rows,",")) Do stream.WriteLine("<th></th>")
   	Do stream.WriteLine("</tr>")
   	Do stream.WriteLine("<tr>")
   	Write stream.WriteLine("<th></th>")
   	Set aggname=""
	Set aggname=$o(Seen(aggname),1,cond)
   	while (aggname'="") {
	   	for k=1:1:..aggs.Size {
		   	Set agg=..aggs.GetAt(k)
		   	Do stream.WriteLine("<th style='text-align:right'>")
		   	if pCol=$L(..cols,",") Do stream.WriteLine("<item value='"_agg.name_"'/>")
		   	Do stream.WriteLine("</th>")
	   	}
       	Set aggname=$o(Seen(aggname),1,cond)
   	}
    for j=1:1:..aggs.Size {
        //totals
	   	Set agg=..aggs.GetAt(j)
	   	Do stream.WriteLine("<th style='text-align:right'>")
		if pCol=$L(..cols,",") Do stream.WriteLine("<item value='"_agg.name_"'/>")
		Do stream.WriteLine("</th>")
    }
    if ($L(..rows,",")>1)&&(row<$L(..rows,",")) {
	    Write stream.WriteLine("<th></th>")
    }
}

Method genReportDefinitionForTotals() As %CharacterStream
{
		 Set stream = ##class(%Stream.TmpCharacter).%New()
		 Do stream.WriteLine("<report xmlns=""http://www.intersystems.com/zen/report/definition""")
		 Set row=$P(..rows,",",1)
		 Do stream.WriteLine(" name="""_$P(row,",",1)_""" sql=""SELECT "_..cols_","_..value_" From "_..table_" order by "_..cols_""">")
		 for i=1:1:$L(..rows,",") {
			Set row=$P(..rows,",",i)
			if i>1 Do stream.WriteLine("<group name="""_row_""" breakOnField="""_row_""">")
 		 	Do stream.WriteLine(" <attribute name='"_row_"' expression='""Total""'/>")
		 	Do ..generateTotals(.stream) 	
		 	
		 }
		 for i=1:1:$L(..rows,",") { if i>1 Do stream.WriteLine("</group>") }
         for i=1:1:..aggs.Size {
		   	Set agg=..aggs.GetAt(i)
			Do stream.WriteLine("  <aggregate name=""TOTAL_"_agg.name_""" field="""_..value_""" type="""_agg.type_""" "_$s(agg.class'="":"class='"_agg.class_"'",1:"")_"/>")
   		 }

   	 	 Do stream.WriteLine(" </report>")
		 quit stream
}

Method genReportDisplay() As %CharacterStream
{
		Set stream = ##class(%Stream.TmpCharacter).%New()
		;Do stream.WriteLine("/// This XML defines the display for of this report.")
		;Do stream.WriteLine("/// This is used to gen the XSLT stylesheets for both HTML and XSL-FO.")
		;Do stream.WriteLine("XData ReportDisplay [ XMLNamespace = ""http://www.intersystems.com/zen/report/display"" ]")
		;Do stream.WriteLine("{")
		Do stream.WriteLine("<report xmlns=""http://www.intersystems.com/zen/report/display""")
		Do stream.WriteLine("name="""_..reportName_""">")
		Do stream.WriteLine("<document width=""8.5in"" height=""11in"" marginLeft=""1.25in"" marginRight=""1.25in"" marginTop=""1.0in"" marginBottom=""1.0in"" >")
		Do stream.WriteLine("<class name='table.ptable'>")
		Do stream.WriteLine("</class>")
		Do stream.WriteLine("<class name='th.ptable'>")
		Do stream.WriteLine("<att name='text-align' value='right'/>")
		Do stream.WriteLine("</class>")
		Do stream.WriteLine("<class name='td.ptable'>")
		Do stream.WriteLine("<att name='text-align' value='right'/>")
		Do stream.WriteLine("</class>")

		Do stream.WriteLine("</document>")
		Do stream.WriteLine("<body>")
		for i=1:1:$L(..rows,",")  {
			s row=$P(..rows,",",i)
			;if i=1 Set width="100%"
			Set width=(($L(..rows,",")-i+1)/$L(..rows,","))*100_"%"
			Do stream.WriteLine("<table orient=""col"" group="""_row_""" class=""numeric"" style='padding:1pt' layout='fixed' width='"_width_"' >")
			Do stream.WriteLine("<thead>")
			for k=1:1:$L(..cols,",") {
				Do stream.WriteLine("<tr>")
				Do stream.WriteLine("<th>")
				if k=1 Do stream.WriteLine("<item value='"_$zcvt(row,"T")_"' style='text-align:left'/>")
				Do stream.WriteLine("</th>")
				Do ..generateHeaders(.stream,i,k)
		        Do stream.WriteLine("</tr>")
			}
			Do stream.WriteLine("</thead>")
			s row=$P(..rows,",",i)
			Do stream.WriteLine("<item field=""@"_row_""" style='text-align:left'>")
			Do stream.WriteLine("</item>")
			Do ..generateItems(.stream)	    
			s row=$P(..rows,",",i) 
	        for j=1:1:..aggs.Size {
		        //foobar
			   	Set agg=..aggs.GetAt(j)
				Do stream.WriteLine("<item field=""TOTAL_"_agg.name_""" formatNumber='###,###,###,###,###,###,###,###,###,###,###'>")
				Do stream.WriteLine("</item>")
	        }
		}
		
    	for i=1:1:$L(..rows,",") {
	    	
			Do stream.WriteLine("</table>")
    	}
		Do stream.WriteLine("</body>")
		Do stream.WriteLine("</report>")
		quit stream
}

ClassMethod CreateXDataSection(className As %String, xdataname As %String, stream As %Stream.TmpCharacter, namespace As %String) As %Status
{
		Set xdata=##class(%Dictionary.XDataDefinition).%New(className_":"_xdataname)
		Set xdata.XMLNamespace=namespace
		Set xdata.Data=stream
		Set Status=xdata.%Save()
		q Status
}

ClassMethod CreateProperty(className As %String, Name As %String, Type As %String, isZENURL As %Boolean)
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

ClassMethod CreateParameter(className As %String, Name As %String, Default As %String)
{
	s Status=$$$OK
	do {
		Set parameter=##class(%Dictionary.ParameterDefinition).%New(className_":"_Name)
		Set parameter.Default=Default
		Set Status=parameter.%Save()
	} while (0)
	q Status
}

ClassMethod q(s As %String) As %String
{
	q "&quot;&quot;"_s_"&quot;&quot;"
}

ClassMethod cond(col, name)
{
	q "$zcvt(%val("_..q(col)_"),"_..q("u")_")=$zcvt("_..q(name)_","_..q("u")_")"
}

}
