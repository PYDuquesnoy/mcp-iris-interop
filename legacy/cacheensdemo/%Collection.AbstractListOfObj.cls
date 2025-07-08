/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A list collection represents a list of data type elements, 
/// each of which is associated with a numeric position in the list. 
/// The first element in the list is stored at position 1.
/// 
/// <p>The <CLASS>%Collection.AbstractList</CLASS> class provides the basic functionality of the	
/// various list collection classes.
/// 
/// <p>The non-abstract list classes derived from <CLASS>%AbstractList</CLASS> include 
/// <CLASS>%ListOfDataTypes</CLASS>, <CLASS>%ListOfObjects</CLASS>, <CLASS>%Collection.ListOfObj</CLASS>
/// and <CLASS>%Collection.ListOfDT</CLASS>.
/// 
/// You can use a list object as follows:
/// <EXAMPLE>
/// Set list=##class(%ListOfDataTypes).%New()
/// 
/// ; add items to the list
/// Do list.Insert("Harpo")
/// Do list.Insert("Groucho")
/// Do list.Insert("Chico")
/// Do list.Insert("Karl")
/// 
/// ; iterate over contents of list
/// For i=1:1:list.Count()  Write list.GetAt(i),!
/// </EXAMPLE>
Class %Collection.AbstractListOfObj Extends %Collection.AbstractList [ System = 2 ]
{

/// Starting from, but not including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list with value equal to <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %ObjectIdentity, key As %Integer) As %String [ Abstract ]
{
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose Oref value equals <var>oref</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>FindOref</b> returns the key associated with the found element or null string ("") if no element is found.
/// 
/// Unswizzled references are compared to oref.%Oid() and if equal, swizzling will occur.
Method FindOref(oref As %RegisteredObject, key As %Integer = "", id As %String = "") As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %RegisteredObject [ Abstract ]
{
}

/// Finds and returns the value of the element at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %RegisteredObject [ Abstract ]
{
}

/// Finds and returns the value of the element at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %Integer) As %RegisteredObject [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %RegisteredObject) As %Status [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= key &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertAt(element As %RegisteredObject, key As %Integer) As %Status [ Abstract ]
{
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed. It also has a <var>success</var> output argument that
/// returns true if the item was removed and false if it was not.
Method RemoveAt(key As %Integer, Output success As %Boolean) As %ObjectIdentity [ Abstract ]
{
}

/// Sets the value of the element at position <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %RegisteredObject, key As %Integer) As %Status [ Abstract ]
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

/// Finds and returns the OID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectAt(key As %Integer, force As %Integer = 0) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectIdAt(key As %Integer, force As %Integer = 0) As %String [ Abstract ]
{
}

/// Finds and returns the OID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetObjectNext(ByRef key As %Integer) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the ID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetObjectIdNext(ByRef key As %Integer) As %String [ Abstract ]
{
}

/// Finds and returns the OID value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetObjectPrevious(ByRef key As %Integer) As %ObjectIdentity [ Abstract ]
{
}

/// Finds and returns the ID value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the ID value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetObjectIdPrevious(ByRef key As %Integer) As %String [ Abstract ]
{
}

/// Inserts an element with OID value <var>oid</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObject(oid As %ObjectIdentity) As %Status [ Abstract ]
{
}

/// Inserts an element with ID value <var>id</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectId(id As %String) As %Status [ Abstract ]
{
}

/// Inserts an element with OID value <var>oid</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= index &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectAt(oid As %ObjectIdentity, key As %Integer) As %Status [ Abstract ]
{
}

/// Inserts an element with ID value <var>id</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= index &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectIdAt(id As %String, key As %Integer) As %Status [ Abstract ]
{
}

/// Sets the OID value of the element at position <var>key</var> to <var>oid</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %Integer) As %Status [ Abstract ]
{
}

/// Sets the ID value of the element at position <var>key</var> to <var>id</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectIdAt(id As %String, key As %Integer) As %Status [ Abstract ]
{
}

}
