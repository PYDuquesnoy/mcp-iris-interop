/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An array collection represents an array of data type elements, 
/// each of which is associated with a unique key value. 
/// Keys can have any value, string or numeric.
/// 
/// <p>The <CLASS>%Collection.AbstractArray</CLASS> class provides the basic functionality of the	
/// various array collection classes.
/// <p>The non-abstract array classes derived from <CLASS>%AbstractArray</CLASS> include 
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
Class %Collection.AbstractArray Extends %Collection.AbstractIterator [ Abstract, ClientDataType = HANDLE, System = 2 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE As STRING = "%String";

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	Set ptr=0
    While $listnext(serialized,ptr,item) {
    	Set array($list(item))=$lg(item,2)
    }
	Quit $$$OK
}

/// A collection is null if it does not contain any elements
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
..Count()=0
}

/// Clears the contents of the array.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status [ Abstract ]
{
}

/// Returns the number of elements contained in the array.
Method Count() As %Integer [ Abstract ]
{
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ Abstract ]
{
}

/// <b>This method is deprecated.</b>
/// <p>Please use <METHOD>IsDefined</METHOD> instead.
Method Define(key As %String) As %Boolean [ Abstract, Deprecated ]
{
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %RawString, key As %String) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %RawString [ Abstract ]
{
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <METHOD>Previous</METHOD> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ Abstract ]
{
}

/// Removes the element associated with <var>key</var> in the array.
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %String) As %RawString [ Abstract ]
{
}

/// Sets the value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %RawString, key As %String) As %Status [ Abstract ]
{
}

/// Converts the serial state of this array object to a delimited string 
/// using <var>delim</var> as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	Set odbc=""
	Set ptr=0
    While $listnext(val,ptr,data) {
		For j=1:1:2 {
			Set item=$lg(data,j)
			If method'="",j=2 Set item=$classmethod(class,method,item)
			If item'["""",item'[delim,$length($zstrip(item,"<>W"))=$length(item) Set odbc=odbc_delim_item Continue
			Set odbc=odbc_delim_""""_$replace(item,"""","""""")_""""
		}
    }
	Quit $extract(odbc,$length(delim)+1,*)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using <var>delim</var> as a delimiter.
ClassMethod OdbcToLogical(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	If val="" Quit ""
	Set logical="",out="",tmp=""
hloop  If $extract(val,1,$length(delim))=delim { Goto hdel } If $extract(val)="""" { Goto hquote }
hdefault	Set stuff=$piece(val,delim),out=out_stuff,val=$extract(val,$length(stuff)+1,*) If val="" { Goto hdel } Goto hloop
hquote	Set stuff=$find(val,"""",2) If stuff=0 Set stuff=$length(val)+10
	Set out=out_$extract(val,2,stuff-2),val=$extract(val,stuff,*)
	If $extract(val)="""" { Set out=out_"""" Goto hquote } Else { Goto hdefault }
hdel	If tmp'="" { Set logical=logical_$listbuild($listbuild(tmp,$select(method="":out,1:$classmethod(class,method,out)))),tmp="" } Else { Set tmp=out }
	Set out="",val=$extract(val,$length(delim)+1,*)
	If val="" Quit logical
	Goto hloop
}

}
