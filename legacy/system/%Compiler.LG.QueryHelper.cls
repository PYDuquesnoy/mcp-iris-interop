/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.LG.QueryHelper Extends (%Library.RegisteredObject, %Collection.AbstractListOfObj) [ ClientName = com.intersystems.classes.ListOfObjects, Inheritance = right, System = 4 ]
{

Property RS As %Library.ScrollableResultSet [ Private ];

Property Count As %Integer [ Private ];

Property Cursor As %Integer [ Private ];

Property Class As %String [ Private ];

ClassMethod Query(class As %String, sql As %String, args) As QueryHelper [ ServerOnly = 1 ]
{
	s QueryHelper = ##class(QueryHelper).%New()
	s sc = QueryHelper.Init(class,sql,.args)
	s $ze=sc
	Q:$$$ISERR(sc) ""
	s $ZE=""
	Quit QueryHelper
}

Method Init(class As %String, sql As %String, args) As %Status [ ServerOnly = 1 ]
{
	s ..RS = ##class(%Library.ScrollableResultSet).%New("%DynamicQuery:SQL")
	s sc = ..RS.Prepare(sql)
	Q:$$$ISERR(sc) sc
	If args=0 s sc = ..RS.Execute() goto QueryExecuted
	If args=1 s sc = ..RS.Execute(args(1)) goto QueryExecuted
	If args=2 s sc = ..RS.Execute(args(1), args(2)) goto QueryExecuted
	If args=3 s sc = ..RS.Execute(args(1), args(2), args(3)) goto QueryExecuted
	If args=4 s sc = ..RS.Execute(args(1), args(2), args(3), args(4)) goto QueryExecuted
	If args=5 s sc = ..RS.Execute(args(1), args(2), args(3), args(4), args(5)) goto QueryExecuted
	If args=6 s sc = ..RS.Execute(args(1), args(2), args(3), args(4), args(5), args(6)) goto QueryExecuted
	If args=7 s sc = ..RS.Execute(args(1), args(2), args(3), args(4), args(5), args(6), args(7)) goto QueryExecuted
	If args=8 s sc = ..RS.Execute(args(1), args(2), args(3), args(4), args(5), args(6), args(7), args(8)) goto QueryExecuted
	s $ZE="Too many parameters to Prepare. Maximum is 8"
	Quit $$$ERROR(0,$ZE)
QueryExecuted	
	Q:$$$ISERR(sc) sc
	
	//d ..RS.SetIdInfo(1,class)
	
	s ..Count = ..RS.Count()
	s ..Class = class
	s ..Cursor = 0

	Quit $$$OK
}

/// Returns the number of elements contained in the list.
Method Count() As %Integer
{
	Quit ..Count
}

/// Finds and returns the value of the element at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %RegisteredObject
{
	s x = ..RS.Next()
	s ..Cursor = ..Cursor + 1
	
	If x=0  d ..RS.Close() Quit ""
	
	s id = ..RS.GetData(1)
	s obj = $classmethod(..Class,"%OpenId",id)
	Quit obj
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %RegisteredObject
{
	if (key > 0) s key = key - 1
	if (..Cursor'=key){
		s sc = ..RS.CurrRowSet(key)
		if $$$ISERR(sc) Quit ""
		s ..Cursor = key
	}
	Quit ..GetNext()
}

}
