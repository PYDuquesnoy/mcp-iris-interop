/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Definition of iterator methods that all our collections classes use to ensure consistency.
Class %Collection.AbstractIterator [ Abstract, System = 2 ]
{

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the iteration. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %RawString) As %RawString [ Abstract ]
{
}

/// Finds and returns the key value of the element at the location following <var>key</var> in the iteration. 
/// If key is a null string (""), then <b>Next</b> returns the key value for the first element in the array.
Method Next(key As %RawString = "") As %RawString [ Abstract ]
{
}

/// Finds and returns the value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %RawString = "") As %RawString [ Abstract ]
{
}

}
