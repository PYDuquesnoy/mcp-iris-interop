/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Collection.MV.ListOfDT Extends %Collection.ListOfDT [ System = 2 ]
{

/// Converts the serial state of this list object to a delimited string 
/// using <i>delim</i> (default delim is ",") as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	if method=""||(val="") { QUIT $replace(val,$mvv(2),delim) }
	for i=1:1:$l(val,$mvv(2)) { set $p(return,delim,i)=$classmethod(class,method,$p(val,$mvv(2),i)) }
	QUIT return
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using <i>delim</i> (default delim is ",") as a delimiter.
ClassMethod OdbcToLogical(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	if method=""||(val="") { QUIT $replace(val,delim,$mvv(2)) }
	for i=1:1:$l(val,delim) { set $p(return,$mvv(2),i)=$classmethod(class,method,$p(val,delim,i)) }
	QUIT return
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>%delim</var> argument as a delimiter.
ClassMethod LogicalToDisplay(val As %String = "", delim As %String = {$char(13,10)}, class As %String = "", method As %String = "") As %String
{
	if method=""||(val="") { QUIT $replace(val,$mvv(2),delim) }
	for i=1:1:$l(val,$mvv(2)) { set $p(return,delim,i)=$classmethod(class,method,$p(val,$mvv(2),i)) }
	QUIT return
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>delim</var> argument as a delimiter.
ClassMethod DisplayToLogical(val As %String = "", delim As %String = {$char(13,10)}, class As %String = "", method As %String = "") As %String
{
	if method=""||(val="") { QUIT $replace(val,delim,$mvv(2)) }
	for i=1:1:$l(val,delim) { set $p(return,$mvv(2),i)=$classmethod(class,method,$p(val,delim,i)) }
	QUIT return
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",owner=$zobjref(i%Owner),storage=i%Storage
	For key=1:1:+$order($zobjval(owner,storage,0,3,storage,""),-1) {
		set list = list _ $mvv(2) _$get($zobjval(owner,storage,0,3,storage,key))
	}
	Quit $extract(list,$length($mvv(2))+1,*)
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	Set ptr=0,key=0,changed=0,owner=$zobjref(i%Owner),storage=i%Storage,oldcount=+$order($zobjval(owner,storage,0,3,storage,""),-1)
	If oldcount'=$length(serialized,$mvv(2)) {
		Set changed=1,sc=..Clear()
		If $$$ISERR(sc) Quit sc
		For i=1:1:$length(serialized,$mvv(2)) {
			Set $zobjval(owner,storage,0,3,storage,$increment(key))=$piece(serialized,$mvv(2),i)
		}
	} Else {
		If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
		For i=1:1:$length(serialized,$mvv(2)) {
			Set item=$piece(serialized,$mvv(2),i)
		    If $zobjval(owner,storage,0,3,storage,$increment(key))'=item {
		    	Set $zobjval(owner,storage,0,3,storage,key)=item,changed=1
		    }
	    }
	}
	If changed Set $zobjmod(owner,i%OrefStorage)=1
    Quit $$$OK
}

/// Inserts a list with value <var>inslist</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %String) As %Status
{
	If ..ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set size=..Count()
	if inslist '= "" { For i=1:1:$length(inslist,$mvv(2)) { Set $zobjval($zobjref(..Owner),..Storage,0,3,..Storage,size+i)=$piece(inslist,$mvv(2),i) } }
	Set $zobjmod($zobjref(..Owner),..OrefStorage)=1
	Quit $$$OK
}

}
