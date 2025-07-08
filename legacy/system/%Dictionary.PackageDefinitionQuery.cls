/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.PackageDefinitionQuery [ Abstract, Not ProcedureBlock, System = 2 ]
{

/// The <b>SubPackage</b> query provides a list of sub-package names.
/// This query works in a hierarchical way, 
/// it returns only one level of sub-package under a specified <var>SuperPackage</var> name.
Query SubPackage(SuperPackage As %String = "") As %Query(ROWSPEC = "Name")
{
}

ClassMethod SubPackageExecute(ByRef QHandle As %Binary, SuperPackage As %String) As %Status
{
 Set QHandle=$lb($g(SuperPackage),$zcvt($g(SuperPackage),"u"))
 Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod SubPackageFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..SubPackageFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod SubPackageFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ ProcedureBlock = 1 ]
{
	Set supername=$list(QHandle,1)
	Set superlength=$l(supername)
	Set subpiece=$s(supername="":1,1:$l(supername,".")+1)
	If '$get(FetchCount) Set FetchCount=10000
	If $get(AtEnd) Set QHandle="" Quit $$$OK
	Set AtEnd=0,RowSet="",ReturnCount=0
	Set class=$list(QHandle,2)
	For  {
		Set class=$o(^rINDEXCLASS(class))
		If class="" Set AtEnd=1 Quit
		Set package=$$$ClassPackageName($li(^rINDEXCLASS(class),2))
		If $e(package,1,superlength)'=supername Set AtEnd=1 Quit
		If superlength,$l(package)>superlength,$e(package,superlength+1)'="." Set AtEnd=1 Quit
		Set subpackage=$p(package,".",subpiece)
		If subpackage'="" {
			Set RowSet=RowSet_$lb(subpackage)
			Set ReturnCount=ReturnCount+1
			Set header=$p($li(^rINDEXCLASS(class),2),".",1,subpiece)
			Set class=$piece(class,".",1,subpiece)_"/"
			If ReturnCount'<FetchCount Quit
			If $length(RowSet)>20000 Quit
		}
	}
	Set QHandle=$lb(supername,class)
	Quit $$$OK
}

ClassMethod SubPackageClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

/// The <b>FlatPackage</b> query provides a list of flattened out package names.
/// Starting with ones beginning with <var>Prefix</var>
Query FlatPackage(Prefix As %String = "") As %Query(ROWSPEC = "Name")
{
}

ClassMethod FlatPackageExecute(ByRef QHandle As %Binary, Prefix As %String) As %Status
{
 Set QHandle=$lb($zcvt($g(Prefix),"U"),$zcvt($g(Prefix),"U"),"")
 Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod FlatPackageFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..FlatPackageFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod FlatPackageFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ ProcedureBlock = 1 ]
{
	Set prefix=$list(QHandle,1)
	Set prefixlength=$l(prefix)
	Set lastpackage=$list(QHandle,2)
	If '$get(FetchCount) Set FetchCount=10000
	If $get(AtEnd) Set QHandle="" Quit $$$OK
	Set AtEnd=0,RowSet="",ReturnCount=0
	Set class=$list(QHandle,2)
	For  {
		Set class=$o(^rINDEXCLASS(class))
		
		// Check for the end
		If class="" Set AtEnd=1 Quit
		
		// Grab the package name
		Set pkg=$$$ClassPackageName($li(^rINDEXCLASS(class),2))
		Set package=$ZCVT(pkg,"U")_"."

		// Check for a prefix match, ending if the prefix differs
		If $e(package,1,prefixlength)'=prefix Set AtEnd=1 Quit

		If $E(lastpackage,1,$L(package))'=package {
			// Add this to the results
			Set RowSet=RowSet_$lb(pkg)
			Set ReturnCount=ReturnCount+1
			Set lastpackage=package

			If ReturnCount'<FetchCount Quit
			If $length(RowSet)>20000 Quit
		}
	}
	// We need to remember where we were
	Set QHandle=$lb(prefix,package,lastpackage)
	Quit $$$OK
}

ClassMethod FlatPackageClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

}
