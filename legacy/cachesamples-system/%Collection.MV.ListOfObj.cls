/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Collection.MV.ListOfObj Extends %Collection.ListOfObj [ System = 2 ]
{

Parameter IdCollection As BOOLEAN = 1;

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	#; $Piece delimited string of list of objects without extentname in the oid
	Set list="",owner=$zobjref(i%Owner),storage=i%Storage
	For key=1:1:+$order($zobjval(owner,storage,0,3,storage,""),-1) {
		set id = ..GetObjectIdAt(key,.force), list = $select(key=1:id,1:list_$mvv(2)_id)
	}
	Quit list
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	Set ptr=0,key=0,changed=0,owner=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage,oldcount=+$order($zobjval(owner,storage,0,3,storage,""),-1)
	If oldcount'=$length(serialized,$mvv(2)) {
		Set changed=1,sc=..Clear()
		If $$$ISERR(sc) Quit sc
	    For i=1:1:$length(serialized,$mvv(2)) {
		    Set $zobjval(owner,storage,0,3,storage,$increment(key))=$piece(serialized,$mvv(2),i),$zobjval(owner,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
	    }
	} Else {
		If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	    For i=1:1:$length(serialized,$mvv(2)) {
		    Set item=$piece(serialized,$mvv(2),i)
		    If $zobjval(owner,storage,0,3,storage,$increment(key))'=item {
		    	Set $zobjval(owner,storage,0,3,storage,key)=item,$zobjval(owner,orefstorage,0,3,orefstorage,key)=$$$NULLOREF,changed=1
		    }
	    }
	}
	If changed Set $zobjmod(owner,i%OrefStorage)=1
    Quit $$$OK
}

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

}
