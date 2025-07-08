/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occCPTJSruntime, %occCPTJSgendb, %occCPT)

Class %CPT.JS.TracingEnumeratee Extends %ZEN.proxyObjectEnumeratee [ System = 4 ]
{

Property Level As %Integer [ Private ];

/// Each entry is $LB(seenany,listindex,commacount)
/// 
/// seenany=0 => seen nothing
/// seenany=1 => seen item
/// seenany=2 => seen prop
Property Stack As %List [ MultiDimensional, Private ];

Method %OnNew() As %Status
{
	Set ..Level=0
	Set ..Stack(..Level)=$ListBuild(0,0,0) // $LB(seenany,index,commacount)
	
	Quit $$$OK
}

Method PropertyName(Prop As %String) [ Internal ]
{
	Do ..WriteProp(..MaybeUnquote(Prop)_": ")
}

Method BeginNested() [ Internal ]
{
	Do ..WriteItem("{")
	Do ..Push()
}

Method EndNested() [ Internal ]
{
	Do ..Pop()
	Write "}"
}

Method ListIndex(Index) [ Internal ]
{
	#Dim skipped
	
	If ##class(%CPT.JS.Runtime.COS).IsCanonicalNumber(Index) {
		Set skipped=Index-$List(..Stack(..Level),2)
		If skipped<0 {$$$JSTRAP($Classname()_":ListIndex: Fatal error in Index sequence")}
		Set $List(..Stack(..Level),2)=Index
		Set $List(..Stack(..Level),3)=skipped+1 // we need one, anyway
	}
	Else {
		Set $List(..Stack(..Level),3)=1 // we need one, anyway
	}
}

Method BeginList() [ Internal ]
{
	Do ..WriteItem("[")
	Do ..Push()
}

Method EndList() [ Internal ]
{
	Do ..Pop()
	Write "]"
}

Method CacheObject(Obj As %RegisteredObject) [ Internal ]
{
	Do ..WriteItem($$$JSTOSTRING(Obj))
}

Method Simple(Item) [ Internal ]
{
	Do ..WriteItem(##class(%XSQL.Format).ListFormat(Item))
}

Method Indent() As %String [ CodeMode = expression, Internal ]
{
$Justify("",..Level+1)
}

Method MaybeUnquote(Prop As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$Select(Prop?1""""1A1.AN1"""":$Extract(Prop,2,*-1),1:Prop)
}

Method Top() As %List [ CodeMode = expression, Internal, Private ]
{
..Stack(..Level)
}

Method TopSeenAny() As %Integer [ CodeMode = expression, Internal, Private ]
{
$List(..Top())
}

Method SetTopSeenAny(SeenAny As %Integer) [ Internal, Private ]
{
	Set $List(..Stack(..Level))=SeenAny
}

Method TopCommaCount() As %Integer [ CodeMode = expression, Internal, Private ]
{
$List(..Top(),3)
}

Method Push() [ Internal, Private ]
{
	Set ..Level=..Level+1
	Set ..Stack(..Level)=$ListBuild(0,0,0) // $LB(seenany,index,commacount)
}

Method Pop() [ Internal, Private ]
{
	Kill ..Stack(..Level)
	Set ..Level=..Level-1
}

Method WriteProp(Prop As %String) [ Internal, Private ]
{
	If ..TopSeenAny() {Write ..Commas(..TopCommaCount())," "}
	Write Prop
	Do ..SetTopSeenAny(2)
}

Method WriteItem(Item As %String) [ Internal, Private ]
{
	If ..TopSeenAny()=1 {Write ..Commas(..TopCommaCount())," "}
	Do ..SetTopSeenAny(1)
	Write Item
}

ClassMethod Commas(CommaCount As %Integer) [ CodeMode = expression, Internal, Private ]
{
##class(%CPT.JS.Runtime.Primitive).Replicate(",",CommaCount)
}

}
