/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.ListOfDataTypes">Working with Collections</a>.</p>
/// The <CLASS>%ListOfDataTypes</CLASS> class represents a list of literal (i.e., data type) values.
/// each of which is associated with a numeric position in the list. 
/// The first element in the list is stored at position 1. 
/// 
/// <p>Refer to <CLASS>%Collection.AbstractList</CLASS> for a description of 
/// the various array methods.
/// These classes can be used 'standalone' to store a collection.
Class %Library.ListOfDataTypes Extends (%Collection.AbstractListOfDT, %SerialObject) [ ClassType = serial, OdbcType = VARCHAR, StorageStrategy = Custom, System = 2 ]
{

/// The type (classname:propertyname) of the elements stored in the collection.
Parameter ELEMENTTYPE;

/// The type (classname:propertyname) of the elements stored in the collection.
Property ElementType As %RawString [ InitialExpression = {..#ELEMENTTYPE} ];

/// <var>Data</var> is a private property used to hold the contents of the list.
Property Data As %RawString [ MultiDimensional ];

/// <var>Size</var> is the number of elements contained in the list.
Property Size As %Integer [ InitialExpression = 0 ];

Method SizeSet(newvalue As %Integer) As %Status [ Private ]
{
}

/// Clears the contents of the list.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	Kill i%Data Set i%Size=0
	Quit $$$OK
}

/// Returns the number of elements contained in the list.
Method Count() As %Integer [ CodeMode = expression, Final ]
{
i%Size
}

/// Starting from, and including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list with value equal to <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %String, key As %Integer) As %String
{
	Set found="",k=$get(key,1)\1 Set:k<1 k=1
	For k=k:1:i%Size If i%Data(k)=element Set found=k Quit
	Quit found
}

/// Finds and returns the value of the element at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %String
{
	Set key=$select($get(key)+1>i%Size:"",1:$get(key)+1)
	Quit $select(key="":"",1:$get(i%Data(key)))
}

/// Finds and returns the value of the element at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %Integer) As %String
{
	Set key=$select($get(key)="":$select(i%Size=0:"",1:i%Size),key-1<1:"",1:key-1)
	Quit $select(key="":"",1:$get(i%Data(key)))
}

/// Inserts an element with value <var>element</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %String) As %Status
{
	Set i%Size=i%Size+1,i%Data(i%Size)=element
	Quit $$$OK
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
Method InsertAt(element As %String, key As %Integer) As %Status
{
	Set key=+key
	If key<1||(key>(i%Size+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	For i=i%Size:-1:key Set i%Data(i+1)=i%Data(i)
	Set i%Data(key)=element,i%Size=i%Size+1
	Quit $$$OK
}

/// Inserts a list with value <var>inslist</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %String) As %Status
{
	For i=1:1:$listlength(inslist) Set i%Size=i%Size+1,i%Data(i%Size)=$listget(inslist,i)
	Quit $$$OK
}

/// Inserts an element with value <var>element</var> into the list at the correct ordered 
/// position. The elements in the list are shifted to accommodate the new element as necessary.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertOrdered(element As %String) As %Status
{
	Set count=i%Size+1
	For i=1:1:count Quit:(i=count)||(i%Data(i)]element)
	Quit ..InsertAt(element,i)
}

/// Finds and returns the index value of the element at the location following <var>key</var> in the list. 
/// If key is a null string (""), then <b>Next</b> returns the position of the first element in the list (1).
Method Next(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$select(key+1>i%Size:"",1:key+1)
}

/// Finds and returns the index value of the element at the location preceding <var>key</var> in the list. 
/// If key is a null string (""), then <b>Next</b> returns the position of the last element in the list.
Method Previous(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$select(key="":i%Size,key-1<1:"",1:key-1)
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %Integer) As %String
{
	If key=""||($data(i%Data(key))=0) Quit ""
	Set removed=i%Data(key)
	For i=key:1:i%Size-1 Set i%Data(i)=i%Data(i+1)
	Kill i%Data(i%Size) Set i%Size=i%Size-1
	Quit removed
}

/// Sets the value of the element at position <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %Integer) As %Status
{
	If key=""||($data(i%Data(key))=0) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	Set i%Data(key)=element
	Quit $$$OK
}

Method %ValidateObject(force As %Integer) As %Status
{
 Set iv=$$$OK
 If i%ElementType="" Quit $$$OK
 Set class=$piece(i%ElementType,":",1),prop=$piece(i%ElementType,":",2)
 For i=1:1:i%Size Set iv=$classmethod(class,prop_"IsValid",i%Data(i)) Quit:$$$ISERR(iv)
 Quit iv
}

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	Set ptr=0,i=1
	While $listnext(serialized,ptr,item) {
		Set array(i)=item,i=i+1
	}
	Quit $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ Private ]
{
	Set list=""
	For i=1:1:i%Size Set list=list_$listbuild(i%Data(i))
	Quit list
}

Method %SetSerial(serialized As %String) As %Status [ Private ]
{
	Kill i%Data
	Set ptr=0,i=1
	While $listnext(serialized,ptr,item) {
		Set i%Data(i)=$get(item),i=i+1
	}
	Set i%ElementType="",i%Size=i-1
	Quit $$$OK
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "") As %String [ CodeMode = generator ]
{
	Set odbcdelim=%parameter("ODBCDELIMITER")
	#; Quote the delimiter. If odbcdelimiter was not specified, default to ","
	Set odbcdelim=""""_$select(odbcdelim'="":odbcdelim,1:",")_""""
	$$$GENERATE("	Quit ##class(%Collection.ListOfDT).LogicalToOdbc(val,"_odbcdelim_")")
	Quit $$$OK
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod OdbcToLogical(val As %String = "") As %String [ CodeMode = generator ]
{
	Set odbcdelim=%parameter("ODBCDELIMITER")
	#; Quote the delimiter. If odbcdelimiter was not specified, default to ","
	Set odbcdelim=""""_$select(odbcdelim'="":odbcdelim,1:",")_""""
	$$$GENERATE("	Quit ##class(%Collection.ListOfDT).OdbcToLogical(val,"_odbcdelim_")")
	Quit $$$OK
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>%delim</var> argument as a delimiter.
ClassMethod LogicalToDisplay(val As %String = "", delim As %String = {$char(13,10)}) As %String
{
	Quit $lts(val,delim)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>delim</var> argument as a delimiter.
ClassMethod DisplayToLogical(val As %String = "", delim As %String = {$char(13,10)}) As %String
{
	Quit $lfs(val,delim)
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %String [ CodeMode = expression, Final ]
{
$get(i%Data(key))
}

Storage Custom
{
<StreamLocation>^%Library.ListOfDataTypesS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
