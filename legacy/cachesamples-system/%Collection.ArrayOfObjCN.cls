/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A version of the <CLASS>%Collection.ArrayOfObj</CLASS> collection class that stores 
/// class names in OIDs.
/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they can not be used as 'stand alone' collections, for this use the <class>%ArrayOfObjectsWithClassName</class>.
Class %Collection.ArrayOfObjCN Extends %Collection.ArrayOfObj [ System = 2 ]
{

Method Find(element As %ObjectIdentity, key As %String) As %String
{
	Set key=$get(key)
	For  Set oid=..GetObjectNext(.key) Quit:key=""||(oid=element)
	Quit key
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",key="",owner=$zobjref(i%Owner),storage=i%Storage
	For {
		Set key = $order($zobjval(owner,storage,0,3,storage,key)) Quit:key=""
		Set oid = ..GetObjectAt(key,.force), list = list _$listbuild($listbuild(key,$select($$$oidClassName(oid)="":$$$oidInsertClassName(oid,i%ElementType),1:oid)))
	}
	Quit list
}

}
