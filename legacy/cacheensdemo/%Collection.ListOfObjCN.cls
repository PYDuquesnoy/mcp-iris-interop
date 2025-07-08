/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A version of the <CLASS>%Collection.ListOfObj</CLASS> collection class that stores 
/// class names in OIDs.
/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they can not be used as 'stand alone' collections, for this use the <class>%ListOfObjectsWithClassName</class>.
Class %Collection.ListOfObjCN Extends %Collection.ListOfObj [ System = 2 ]
{

/// Starting from, but not including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list whose OID value equals <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %ObjectIdentity, key As %Integer) As %String
{
	Set key=$get(key)
	For  Set oid=..GetObjectNext(.key) Quit:key=""||(oid=element)
	Quit key
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",owner=$zobjref(i%Owner),storage=i%Storage
	For key=1:1:+$order($zobjval(owner,storage,0,3,storage,""),-1) {
		set oid = ..GetObjectAt(key,.force), list = list _$listbuild($select($$$oidClassName(oid)="":$$$oidInsertClassName(oid,i%ElementType),1:oid))
	}
	Quit list
}

}
