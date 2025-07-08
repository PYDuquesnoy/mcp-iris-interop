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
Class %Collection.AbstractList Extends %Collection.AbstractIterator [ Abstract, ClientDataType = HANDLE, System = 2 ]
{

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	Set ptr=0,i=1
	While $listnext(serialized,ptr,item) {
		Set array(i)=$g(item),i=i+1
	}
	Quit $$$OK
}

/// A collection is null if it does not contain any elements
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
..Count()=0
}

/// Clears the contents of the list.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status [ Abstract ]
{
}

/// Returns the number of elements contained in the list.
Method Count() As %Integer [ Abstract ]
{
}

/// Starting from, but not including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list with value equal to <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %RawString, key As %Integer) As %String [ Abstract ]
{
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %RawString [ Abstract ]
{
}

/// Finds and returns the value of the element at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %RawString [ Abstract ]
{
}

/// Finds and returns the value of the element at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %Integer) As %RawString [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %RawString) As %Status [ Abstract ]
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
Method InsertAt(element As %RawString, key As %Integer) As %Status [ Abstract ]
{
}

/// Inserts a list with value <var>inslist</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %RawString) As %Status [ Abstract ]
{
}

/// Inserts an element with value <var>element</var> into the list at the correct ordered 
/// position. The elements in the list are shifted to accommodate the new element as necessary.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertOrdered(element As %RawString) As %Status [ Abstract ]
{
}

/// Finds and returns the index value of the element at the location following <var>key</var> in the list. 
/// If key is a null string (""), then <b>Next</b> returns the position of the first element in the list (1).
Method Next(key As %Integer = 0) As %Integer [ Abstract ]
{
}

/// Finds and returns the index value of the element at the location preceding <var>key</var> in the list. 
/// If key is a null string (""), then <b>Previous</b> returns the position of the last element in the list.
Method Previous(key As %Integer = 0) As %Integer [ Abstract ]
{
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %Integer) As %RawString [ Abstract ]
{
}

/// Sets the value of the element at position <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %RawString, key As %Integer) As %Status [ Abstract ]
{
}

/// Converts the serial state of this list object to a delimited string 
/// using "," as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	If method="" {
		Set odbc=$lts(val,delim,1)
		If odbc'["""",$length(odbc,delim)=$listlength(val) Quit odbc
	}
	Set odbc="",ptr=0
	While $listnext(val,ptr,item) {
		Set item=$g(item)
		If method'="" Set item=$classmethod(class,method,item)
		If item'["""",item'[delim,$length($zstrip(item,"<>W"))=$length(item) Set odbc=odbc_delim_item Continue
		Set odbc=odbc_delim_""""_$replace(item,"""","""""")_""""
	}
	Quit $extract(odbc,$length(delim)+1,*)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using "," as a delimiter.
ClassMethod OdbcToLogical(val As %String = "", delim As %String = ",", class As %String = "", method As %String = "") As %String
{
	If val="" Quit ""
	If method="",val'["""" Quit $lfs(val,delim)
	Set logical="",out="",delimlen=$length(delim)
hloop  If $extract(val,1,delimlen)=delim { Goto hdel } If $extract(val)="""" { Goto hquote }
hdefault	Set stuff=$piece(val,delim),out=out_stuff,val=$extract(val,$length(stuff)+1,*) If val="" { Goto hdel } Goto hloop
hquote	Set stuff=$find(val,"""",2) If stuff=0 Set stuff=$length(val)+10
	Set out=out_$extract(val,2,stuff-2),val=$extract(val,stuff,*)
	If $extract(val)="""" { Set out=out_"""" Goto hquote } Else { Goto hdefault }
hdel	Set logical=logical_$listbuild($select(method="":out,1:$classmethod(class,method,out))),out="",val=$extract(val,delimlen+1,*) If val="" Quit logical
	Goto hloop
}

}
