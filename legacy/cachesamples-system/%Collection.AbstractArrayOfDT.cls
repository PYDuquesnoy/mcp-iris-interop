/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An array collection represents an array of data type elements, 
/// each of which is associated with a unique key value. 
/// Keys can have any value, string or numeric.
/// 
/// <p>The <CLASS>%Collection.AbstractArrayOfDT</CLASS> class provides the basic functionality of the	
/// various array collection classes.
/// <p>The non-abstract array classes derived from <CLASS>%AbstractArrayOfDT</CLASS> include 
/// <CLASS>%ArrayOfDataTypes</CLASS>, <CLASS>%ArrayOfObjects</CLASS>, <CLASS>%Collection.ArrayOfObj</CLASS>
/// and <CLASS>%Collection.ArrayOfDT</CLASS>.<p>
/// 
/// You can use an array object as follows:
/// <EXAMPLE>
/// Set arr=##class(%ArrayOfDataTypes).%New()
/// 
/// ; place items into the array
/// Do arr.SetAt("red","color")
/// Do arr.SetAt("large","size")
/// Do arr.SetAt("expensive","price")
/// 
/// ; iterate over contents of array
/// Set key=""
/// For  Set value=arr.GetNext(.key) Quit:key=""  Write key,":",value,!
/// </EXAMPLE>
Class %Collection.AbstractArrayOfDT Extends %Collection.AbstractArray [ Abstract, System = 2 ]
{

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %String, key As %String) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String = "") As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %String [ Abstract ]
{
}

/// Removes the element associated with <var>key</var> in the array.
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %String) As %String [ Abstract ]
{
}

/// Sets the value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %String) As %Status [ Abstract ]
{
}

}
