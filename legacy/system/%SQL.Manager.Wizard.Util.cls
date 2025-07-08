/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL Manager CSP Wizard Utility Methods
Class %SQL.Manager.Wizard.Util Extends %RegisteredObject [ System = 3 ]
{

/// Change namespace if the current namespace is not the desired namespace
ClassMethod ChangeNamespace(Namespace As %String) As %String
{
	set current = $namespace
    if Namespace = "" set Namespace = current
	if current '= Namespace do $zutil(5,Namespace)
	quit current
}

/// This is the normal (not SQL Gateway) properties for a table
/// <br>Input:  Namespace by value
/// <br>Input:  SchemaName by value
/// <br>Input:  TableName by value
/// <br>Output: array properties by reference
/// <br>Return: longest property name
ClassMethod listProperties(Namespace As %String, SchemaName As %String, TableName As %String, ByRef properties As %String) As %String
{
	set current = ..ChangeNamespace(Namespace)
	set cnt=0
	set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
	do rs.Execute(SchemaName,TableName)
	set longest = ""
	while rs.Next() {
	  	if rs.Get("COLUMN_NUMBER")'=1,rs.Get("HIDDEN")'="Yes" {
			set cnt = cnt + 1
	  		set colname = rs.Get("FIELD_NAME")
	  		set datatype = rs.Get("DATATYPE")
	  		set colwidth = rs.Get("MAXLEN")
	  		set colwidth = $s(colwidth=0&(datatype["%Boolean"):3,1:17)
	  		set whole = colname_"^"_datatype_"^"_colwidth
	  		if $l(colname) > $l(longest) set longest = colname
			set properties(colname) = whole
	  	}
	}
	if current '= Namespace do $zutil(5,current)
	quit longest
}

/// This is the normal tables given by Namespace and Schema
/// <br>Input:  Namespace by value
/// <br>Input:  SchemaName by value
/// <br>Output: array schems by reference
ClassMethod listTables(Namespace As %String, SchemaName As %String, ByRef tables As %String) As %Status
{
	set current = ..ChangeNamespace(Namespace)
	set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Tables")
	do rs.Execute(SchemaName)
	while rs.Next() {
		if rs.Get("TYPE") = "TABLE" {
	  	set TableName = rs.Get("RELATION_NAME")
	  	if TableName '= "" set tables(TableName) = ""
		}
	}
	if current '= Namespace do $zutil(5,current)
	quit $$$OK
}

/// This is the normal schemas for a given Namespace, not SQL Gateway.
/// <br>Input:  Namespace by value
/// <br>Output: array schems by reference
ClassMethod listSchemas(Namespace As %String, ByRef schemas As %String)
{
	set current = ..ChangeNamespace(Namespace)
	set rs = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Schemas")
	do rs.Execute()
	while rs.Next() {
	  set SchemaName = rs.Get("SCHEMA_NAME")
      if rs.Get("TABLE_EXISTS") = 1 set schemas(SchemaName) = 1
	}
	if current '= Namespace do $zutil(5,current)
	quit $$$OK
}

/// List SQL Gateway tables given by Namespace and DSN (configuration name)
/// <br>Input:  pagename by value (this is used for building links)
/// <br>Input:  Wizard by value ("LinkTable", "LinkProcedure", or "DataMigration")
/// <br>Input:  Namespace by value (current connected Namespace)
/// <br>Input:  dsnname by value (DSN connected)
/// <br>Input:  schemaname by value (schema selected from DSN)
/// <br>Input:  Page by value (page number)
/// list external tables based on cache gateway connection - you must have a DSN (configuration name) passed in.
ClassMethod listExtTables(pagename As %String, Wizard As %String, Namespace As %String, dsnname As %String, schemaname As %String, Page As %Integer)
{
	set cnt = 0
	if Wizard '= $g(%session.Data("Wizard",1)) Kill %session.Data
	if Wizard = "LinkTable" {
		set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLTables")
		do rs.Execute(dsnname,"","",schema)
		set TYPE = "TABLE_TYPE"
		set NAME = "TABLE_NAME"
		set nextpage = "wtable.csp"
	} else {
		set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLProcedures")
		do rs.Execute(dsnname,"",schema)
		set TYPE = "PROC_TYPE"
		set NAME = "PROC_NAME"
		set nextpage = "wfinish.csp"
	}
	&html<<h3 class="para1">Schema: #(schema)#</h3>>
	&html<<div class="para1">Following is a list of #(rs.GetColumnName(3))# for this schema:</div>>
	&html<<ul>>

	while rs.Next() {
	  if rs.Get(TYPE) '= "VIEW" {
	  	set sname = rs.Get("SCHEMA_NAME")
	  	if $a(sname) = 0 set sname="[empty]" 
	  	set tablename = rs.Get(NAME)
	  	//set type = $s(rs.Get(TYPE)'="":rs.Get(TYPE),1:"&nbsp;")
	  	//set remarks = $s(rs.Get("REMARKS")'="":rs.Get("REMARKS"),1:"&nbsp;")
	  	set cnt = cnt + 1,linecolor=$s(cnt#2:"light",1:"dark")
	  	//&html<<tr class=#(linecolor)#>>
	  	&html<<li><a href="#(nextpage)#?dsnname=#(dsnname)#&Wizard=#(Wizard)#&Namespace=#(Namespace)#&schemaname=#(sname)#&tname=#(tablename)#">#(tablename)#</a></li>>
	  	//&html<</tr>>
	  }
	}
	&html<</ul>>
	&html<<input type="hidden" name="total" value=#(cnt)#>>
}

/// list schemas based on cache gateway connection - you must have a DSN (configuration name) passed in.
ClassMethod listExtSchemas(pagename As %String, Wizard As %String, Namespace As %String, dsnname As %String, Page As %Integer)
{
	if Wizard = "LinkProcedure" Set QUERYNAME = "%GTWCatalog:SQLProcedures"
	else  set QUERYNAME = "%GTWCatalog:SQLTables"
	set rs = ##class(%ResultSet).%New(QUERYNAME)
	do rs.Execute(dsnname,"")
	kill sche
	while rs.Next() {
	  set schemaname = rs.Get("SCHEMA_NAME")
	  set:schemaname="" schemaname="[empty]"
	  if schemaname'="",$a(schemaname) = 0 set schemaname="[empty]"
	  set sche(schemaname) = +$g(sche(schemaname))+1
	}
	&html<<ul>>	
	set s = ""
	for  set s = $o(sche(s)) q:s=""  &html<<li><a href="#(pagename)#?dsnname=#(dsnname)#&Wizard=#(Wizard)#&Namespace=#(Namespace)#&schemaname=#(s)#&PAGE=#(Page)#">#(s)# (#(+sche(s))#)</a></li>>
	&html<</ul>>
}

/// Set up DSN names for Link Table, Link Procedure and Data Migration Wizards
ClassMethod listDSN(pagename As %String, Wizard As %String, Namespace As %String, Page As %Integer = 2)
{
	set rs = ##class(%ResultSet).%New("%SQLConnection:ByName")
	do rs.Execute("")
	while rs.Next() {
	  set dsnname = rs.Get("Connection_Name")
	  &html<<li><b><a href="#(pagename)#?dsnname=#(dsnname)#&Wizard=#(Wizard)#&Namespace=#(Namespace)#&PAGE=#(Page)#">#(dsnname)#</a></b></li> (#(rs.Get("DSN"))#)>  
	}
}

/// Display A TEXT file
ClassMethod DisplayTextFile(FileName As %String)
{
	set $zt = "logDone"
	set thisdevice = $i
	&html<
	<a href="#bottom">Go Bottom</a>
	<table class="box"><tr><td><pre>
	>
	open FileName::5 if '$t &html<<br>Cannot open file> quit
	set line = ""
	for  use FileName read line use thisdevice set line = ##class(%CSP.Page).EscapeHTML(line) &html<<br>#(line)#>
	do logDone
	Quit
logDone	;
	close FileName
	use thisdevice 
	&html<</pre>
	</td></tr></table><a name="bottom" href="#top">Go Top</a>
	>
	Quit
}

/// Go back to the previous page
ClassMethod PreviousButton()
{
 &html<
 <input type="button" class="wizbuttons" name="Previous" value="Previous" onClick=history.back();>
 >
}

/// Write out generic Cancel button
ClassMethod CancelButton()
{
 &html<
	<input type="button" class="wizbuttons" name="Cancel" value=" Cancel " onClick="popupCancel();">
 >
}

/// Write out generic Cancel button
ClassMethod NextButton()
{
 &html<
	<input type="submit" class="wizbuttons" name="Next" value=" Next ">
 >
}

/// Write out generic Cancel button
ClassMethod ExitButton()
{
 &html<
	<input type="button" class="wizbuttons" name="Exit" value=" Exit " onClick="popupCancel();">
 >
}

}
