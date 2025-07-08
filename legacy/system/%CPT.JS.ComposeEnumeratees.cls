/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CPT.JS.ComposeEnumeratees Extends %ZEN.proxyObjectEnumeratee [ System = 4 ]
{

Property Enum1 As %ZEN.proxyObjectEnumeratee [ Private ];

Property Enum2 As %ZEN.proxyObjectEnumeratee [ Private ];

Method %OnNew(Enum1 As %ZEN.proxyObjectEnumeratee, Enum2 As %ZEN.proxyObjectEnumeratee) As %Status
{
	Set ..Enum1=Enum1
	Set ..Enum2=Enum2
	
	Quit $$$OK
}

Method PropertyName(Prop As %String) [ Internal ]
{
	Do ..Enum1.PropertyName(Prop)
	Do ..Enum2.PropertyName(Prop)
}

Method BeginNested() [ Internal ]
{
	Do ..Enum1.BeginNested()
	Do ..Enum2.BeginNested()
}

Method EndNested() [ Internal ]
{
	Do ..Enum1.EndNested()
	Do ..Enum2.EndNested()
}

Method ListIndex(Index) [ Internal ]
{
	Do ..Enum1.ListIndex(Index)
	Do ..Enum2.ListIndex(Index)
}

Method BeginList() [ Internal ]
{
	Do ..Enum1.BeginList()
	Do ..Enum2.BeginList()
}

Method EndList() [ Internal ]
{
	Do ..Enum1.EndList()
	Do ..Enum2.EndList()
}

Method CacheObject(Obj As %RegisteredObject) [ Internal ]
{
	Do ..Enum1.CacheObject(Obj)
	Do ..Enum2.CacheObject(Obj)
}

Method Simple(Item) [ Internal ]
{
	Do ..Enum1.Simple(Item)
	Do ..Enum2.Simple(Item)
}

}
