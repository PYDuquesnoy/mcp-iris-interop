/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An array collection of objects
Class %Collection.AbstractArrayOfObj Extends %Collection.AbstractArray [ Abstract, System = 2 ]
{

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %ObjectIdentity, key As %String) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String = "") As %RegisteredObject [ Abstract ]
{
}

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %RegisteredObject [ Abstract ]
{
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %RegisteredObject [ Abstract ]
{
}

/// Removes the element associated with <var>key</var> in the array.
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed. It also has a <var>success</var> output argument that
/// returns true if the item was removed and false if it was not.
Method RemoveAt(key As %String, Output success As %Boolean) As %ObjectIdentity [ Abstract ]
{
}

/// Sets the value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %RegisteredObject, key As %String) As %Status [ Abstract ]
{
}

/// Starting from, but not including, position <var>key</var>, <b>FindObjectId</b> finds 
/// the next element in the list whose ObjectId equals <var>id</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method FindObjectId(id As %String, key As %Integer) As %String [ Abstract ]
{
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose Oref value equals <var>oref</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>FindOref</b> returns the key associated with the found element or null string ("") if no element is found.
/// 
/// Unswizzled references are compared to oref.%Oid() and if equal, swizzling will occur.
Method FindOref(oref As %RegisteredObject, key As %String = "", id As %String) As %String [ Abstract ]
{
}

/// Finds and returns the OID value of the element associated with <var>key</var>.
/// <p><b>GetObjectAt</b> returns the OID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectAt(key As %String, force As %Integer = 0) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value of the element associated with <var>key</var>.
/// <p><b>GetObjectIdAt</b> returns the ID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectIdAt(key As %String, force As %Integer = 0) As %String [ Abstract ]
{
}

/// Finds and returns the OID value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetObjectNext(ByRef key As %String) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the ID value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetObjectIdNext(ByRef key As %String) As %String [ Abstract ]
{
}

/// Finds and returns the OID value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OID value of the last element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetObjectPrevious(ByRef key As %String) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the ID value of the last element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetObjectIdPrevious(ByRef key As %String) As %String [ Abstract ]
{
}

/// Sets the OID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %String) As %Status [ Abstract ]
{
}

/// Sets the ID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectIdAt(id As %String, key As %String) As %Status [ Abstract ]
{
}

}
