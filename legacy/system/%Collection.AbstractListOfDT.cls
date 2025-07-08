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
Class %Collection.AbstractListOfDT Extends %Collection.AbstractList [ System = 2 ]
{

/// Starting from, but not including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list with value equal to <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %String, key As %Integer) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %Integer) As %String [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %String) As %Status [ Abstract ]
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
Method InsertAt(element As %String, key As %Integer) As %Status [ Abstract ]
{
}

/// Inserts a list with value <var>inslist</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %String) As %Status [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> into the list at the correct ordered 
/// position. The elements in the list are shifted to accommodate the new element as necessary.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertOrdered(element As %String) As %Status [ Abstract ]
{
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %Integer) As %String [ Abstract ]
{
}

/// Sets the value of the element at position <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %Integer) As %Status [ Abstract ]
{
}

}
