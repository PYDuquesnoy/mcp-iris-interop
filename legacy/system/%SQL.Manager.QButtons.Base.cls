/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Manager.QButtons.Base Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Stores the actual query statement, if you really need more than 32k, enable long strings and change the MAXLEN
Property QueryStatement As %String(MAXLEN = 32000) [ Required ];

/// Stream containing the query's plan as built by the optimizer
Property QueryPlan As %Stream.GlobalCharacter(CLASSNAME = 2);

/// Property to tell if QueryPlan was built and is valid, otherwise contains the query's compilation error
Property QueryCompileStatus As %Status [ InitialExpression = 0, Required ];

/// Stream containing compiled int code as exported XML
Property QueryIntCode As %Stream.GlobalCharacter(CLASSNAME = 2);

/// Array of %plan for query plan
Property QueryPlanArray As list Of %String(MAXLEN = 32000);

Parameter XMLNAME = "QButton";

/// List of all classes referenced by the query statement
Property ClassList As list Of %String(MAXLEN = 500);

/// Stream containing XML export of all class definitions referenced by the query statement
Property ClassDefXml As %Stream.GlobalCharacter(CLASSNAME = 2);

/// simply contains $zv
Property VersionString As %String(MAXLEN = 500) [ Required ];

Parameter ROWLEVELSECURITY = 1;

/// Stream containing the results of the query as %XML.Dataset output
Property QueryResultData As %Stream.GlobalCharacter(CLASSNAME = 2);

/// WRC Number provided by the user
Property WRCNumber As %Integer [ Required ];

Property TimeInserted As %String [ SqlComputeCode = { s {TimeInserted}=$zdt($zts,3,3)}, SqlComputed ];

Property UserInserted As %String [ SqlComputeCode = { s {UserInserted}=$username}, SqlComputed ];

Property QueryCompileDecomposedStatus As %String [ SqlComputeCode = { s {QueryCompileDecomposedStatus}=##class(%Status).LogicalToOdbc({QueryCompileStatus})}, SqlComputed ];

/// This property has no effect, but remains available for compatibility. 
/// Use %SQL.Statement to generate query results
Property IncludeResults As %Boolean;

Property AllowDelimitedIdentifiers As %Boolean;

Property DefaultSchema As %String;

Property BackgroundJobNumber As %Integer;

ClassMethod %SecurityPolicy(UserInserted As %String) As %String [ SqlProc ]
{
    QUIT UserInserted_",%All,%Developer"
}

/// This method builds the query plan and stores it in a stream that will be part of the report.
Method FetchPlan() As %Status [ Internal ]
{
	new %plan
	s i=1,sc=1
	s sql=1,sql(1)=..QueryStatement
	s tStream=##class(%Stream.TmpCharacter).%New()
	s myio=$IO
	s devnull=$s($$$isWINDOWS:"//./nul",$$$isUNIX:"/dev/null/",$$$isVMS:"NL:")
	o devnull
	u devnull
	set arr = 1
	set showstats = 1
	set verbose = 1
	d ShowPlan^%apiSQL(.sql,arr,,showstats,,,,,,,,,verbose)
	set jobnumber = $J
	set ..BackgroundJobNumber = jobnumber
	u myio
	i ($d(%plan)){
		s ..QueryCompileStatus=1
		s ..QueryPlanArray = %plan
		f i=1:1:%plan {
			s sc=tStream.Write(%plan(i))
			do ..QueryPlanArray.SetAt(%plan(i),i)	
			q:$$$ISERR(sc)
		}
		s sc=..QueryPlan.CopyFromAndSave(tStream)
	}
	else {
		s stmterr=##class(%SQL.Statement).%New()
		s ..QueryCompileStatus=stmterr.%Prepare(.sql)
		
	}
	q sc
}

/// This method exports the class definitions for each of the classes referenced in the query statement into a stream that is stored inside the report
Method FetchClassDef() As %Status [ Internal ]
{
	s sc=1,key="",cur=""
	for {
	 s class=..ClassList.GetNext(.key)
	 q:key=""
	 s $p(cur,",",key)=class_".cls"
	}
	i (cur'=""){
	 s sc=$system.OBJ.ExportToStream(cur,.output,"/nodisplay/exportselectivity/recursive",.error)
	 //insert error checking
	 s sc=..ClassDefXml.CopyFromAndSave(output)
	}
	//insert error checking
	q sc
}

/// This method uses the mtc array created by the query compilation process to find all the classes referenced by the query statement
Method BuildClassList() As %Status [ ProcedureBlock = 0 ]
{
	n sql,d,i,mtc,classname,SQLCODE
	s sql=1,sql(1)=..QueryStatement
	d comp^%qaqqt("query",.sql,"info","",0,"","%qsc(%qscacn")
	i $g(SQLCODE)<0 { q 0  //clean up later
	}
	s i="",d=""
	For  { 
		s i=$o(mtc(0,0,"table",i),1,d) q:i=""
		s classname=$p(d,$c(1),5)
		i (..ClassList.Find(classname)=""){
			d ..ClassList.Insert(classname)
		}
	}
	q $$$OK
}

Method GetVersion() [ Internal ]
{
	s ..VersionString=$zv
}

/// Adds a query to the report, writes out report if a file name is provided
/// This is the main method customer will use to generate reports to be sent to InterSystems Support
ClassMethod InsertQuery(query As %String = "", wrcnum As %String = "NoWRCProvided", includeresults As %Boolean = 0, debug As %Boolean = 0) As %Status
{
	s sc=$$InsertQuery^%SYS.PTools(query, wrcnum, includeresults, debug)
	QUIT sc
}

ClassMethod ListCharStrip(ByRef stream As %Stream.TmpCharacter)
{
	d stream.Rewind()
	s output=##class(%Stream.TmpCharacter).%New()
	while 1 {
		s buffer = stream.Read(32000)
		q:buffer=""
		s buffer=$tr(buffer,$c(1,5,6,7,8))
		d output.Write(buffer)
	}
	s stream=output
}

/// Delete any previous queries that have been added to the report
ClassMethod ClearData(wrcnum As %String = "") As %Status
{
	i (wrcnum="") &sql(delete from %SQL_Manager_QButtons.Base)
	i (wrcnum'="") &sql(delete from %SQL_Manager_QButtons.Base where WRCNumber = :wrcnum)
    /*
	i 'SQLCODE=0 {
		q $$$ERROR()
	}
	*/
	q $$$OK
}

ClassMethod ClearRow(filter As %String) As %Status
{
	&sql(delete from %SQL_Manager_QButtons.Base where ID = :filter)
	q $S(SQLCODE<0:0,1:1)
}

ClassMethod WRCRowExists(wrc As %String) As %Boolean
{
	&sql(select count(*) into :result from %SQL_Manager_QButtons.Base where WRCNumber = :wrc)
	q:(SQLCODE=0 && result'=0) 1
	q 0
}

ClassMethod FindQueryById(id As %String) As %String
{
    &sql(select QueryStatement into :result from %SQL_Manager_QButtons.Base where id = :id)
	q:(SQLCODE=0) result
	q ""
}

/// Writes XML report of all queries added so far
ClassMethod WriteAllToFile(wrcnum As %String, ByRef filename As %String) As %Status
{
	QUIT $$WriteAllToFile^%SYS.PTools(wrcnum,.filename)
}

/// consume report.  This is intended to be used by Intersystems Support to consume the report generated by the customer
/// It is best to run this in an empty namespace as it will import and compile class definitions and routines
ClassMethod ConsumeReport(filename As %String, qspec As %String = "ck", loadcode As %Boolean = 1, NameSpace As %String) As %Status
{
		// Create a new XML Reader class
	
	q $$ConsumeReport^%SYS.PTools(filename,qspec,loadcode,NameSpace)
}

/// Import and compile the class definitions in the report
Method LoadClassDefs(qspec As %String = "ck", ByRef loadedlist) As %Status
{
	s sc=$system.OBJ.LoadStream(..ClassDefXml,qspec,.error,.loadedlist)
	q sc
}

/// Import and compile the query routine int code in the report
Method LoadIntCode(qspec As %String = "ck", ByRef loadedlist) As %Status
{
	s sc=$system.OBJ.LoadStream(..QueryIntCode,qspec,.error,.loadedlist)
	q sc
}

Storage Default
{
<Data name="BaseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>QueryStatement</Value>
</Value>
<Value name="3">
<Value>QueryPlan</Value>
</Value>
<Value name="4">
<Value>QueryCompileStatus</Value>
</Value>
<Value name="5">
<Value>QueryIntCode</Value>
</Value>
<Value name="6">
<Value>ClassList</Value>
</Value>
<Value name="7">
<Value>ClassDefXml</Value>
</Value>
<Value name="8">
<Value>VersionString</Value>
</Value>
<Value name="9">
<Value>QueryResultData</Value>
</Value>
<Value name="10">
<Value>WRCNumber</Value>
</Value>
<Value name="11">
<Value>TimeInserted</Value>
</Value>
<Value name="12">
<Value>UserInserted</Value>
</Value>
<Value name="13">
<Value>QueryCompileDecomposedStatus</Value>
</Value>
<Value name="14">
<Value>IncludeResults</Value>
</Value>
<Value name="15">
<Value>%READERLIST</Value>
</Value>
<Value name="16">
<Value>AllowDelimitedIdentifiers</Value>
</Value>
<Value name="17">
<Value>DefaultSchema</Value>
</Value>
<Value name="18">
<Value>QueryPlanArray</Value>
</Value>
<Value name="19">
<Value>BackgroundJobNumber</Value>
</Value>
</Data>
<DataLocation>^IRIS.QButtons.BaseD</DataLocation>
<DefaultData>BaseDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.QButtons.BaseD</IdLocation>
<IndexLocation>^IRIS.QButtons.BaseI</IndexLocation>
<StreamLocation>^IRIS.QButtons.BaseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

Query SavedQueries() As %SQLQuery
{
	SELECT ID, IncludeResults, TimeInserted, WRCNumber, QueryStatement, QueryCompileDecomposedStatus, AllowDelimitedIdentifiers, DefaultSchema
	FROM %SQL_Manager_QButtons.Base
	ORDER BY WRCNumber
}

}
