/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Collection.MV.ArrayOfStream Extends %Collection.ArrayOfStream [ System = 4 ]
{

Parameter IdCollection As BOOLEAN = 1;

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	#; $Piece delimited string of array of objects without extentname in the oid
	Set list="",key="",owner=$zobjref(i%Owner),storage=i%Storage
	For {
		Set key = $order($zobjval(owner,storage,0,3,storage,key)) Quit:key=""
		Set id = ..GetObjectIdAt(key,.force), list = list _$mvv(2)_key_$mvv(3)_id
	}
	Quit $extract(list,$length($mvv(2))+1,*)
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	If ..Serialize()=serialized Quit $$$OK
	Set sc=..Clear() If $$$ISERR(sc) Quit sc
	Set ptr=0,owner=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	For i=1:1:$length(serialized,$mvv(2)) {
		Set item=$piece(serialized,$mvv(2),i),key=$piece(item,$mvv(3))
	    Set $zobjval(owner,storage,0,3,storage,key)=$piece(item,$mvv(3),2),$zobjval(owner,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
    }
    Quit $$$OK
}

}
