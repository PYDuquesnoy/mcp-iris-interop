/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Collection.MV.ArrayOfDT Extends %Collection.ArrayOfDT [ System = 2 ]
{

/// Converts the serial state of this list object to a delimited string 
/// using "," as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "") As %String [ CodeMode = expression ]
{
$tr(val,$mvv(2),",")
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using "," as a delimiter.
ClassMethod OdbcToLogical(val As %String = "") As %String [ CodeMode = expression ]
{
$tr(val,",",$mvv(2))
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	#; delimited array
	Set list="",key="",owner=$zobjref(i%Owner),storage=i%Storage
	For {
		Set key = $order($zobjval(owner,storage,0,3,storage,key),1,data) Quit:key=""
		set list = list_$mvv(2)_key_$mvv(3)_data
	}
	Quit $extract(list,$length($mvv(2))+1,*)
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	If ..Serialize()=serialized Quit $$$OK
	Set sc=..Clear() If $$$ISERR(sc) Quit sc
	Set ptr=0,owner=$zobjref(i%Owner),storage=i%Storage
	For i=1:1:$length(serialized,$mvv(2)) {
		Set item=$piece(serialized,$mvv(2),i)
	    Set $zobjval(owner,storage,0,3,storage,$piece(item,$mvv(3)))=$piece(item,$mvv(3),2)
    }
    Set $zobjmod(owner,i%OrefStorage)=1
    Quit $$$OK
}

}
