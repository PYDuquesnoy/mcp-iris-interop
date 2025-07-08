/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.ArrayOfDataTypes">Working with Collections</a>.</p>
/// The <CLASS>%ArrayOfDataTypes</CLASS> class represents an array of literal (i.e., data type) elements, 
/// each of which is associated with a unique key value. 
/// Keys can have any value, string or numeric.
/// 
/// <p>Refer to <CLASS>%Collection.AbstractArray</CLASS> for a description of 
/// the various array methods.
/// These classes can be used 'standalone' to store a collection.
Class %Library.ArrayOfDataTypes Extends (%Collection.AbstractArrayOfDT, %SerialObject) [ ClassType = serial, OdbcType = VARCHAR, StorageStrategy = Custom, System = 2 ]
{

/// The type (classname:propertyname) of the elements stored in the collection.
Property ElementType As %String(MAXLEN = 256) [ InitialExpression = {..#ELEMENTTYPE} ];

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "%String";

/// <var>Data</var> is a private property used to hold the 
/// contents of the array.
Property Data As %String [ MultiDimensional ];

/// Clears the contents of the array.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	Kill i%Data
	Quit $$$OK
}

/// Returns the number of elements contained in the array.
Method Count() As %Integer [ ProcedureBlock = 1 ]
{
	Set key="" For count=0:1 Set key=$order(i%Data(key)) Quit:key=""
	Quit count
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ CodeMode = expression, Final ]
{
$data(i%Data(key))
}

/// <b>This method is deprecated.</b>
/// <p>Please use <METHOD>IsDefined</METHOD> instead.
Method Define(key As %String) As %Boolean [ CodeMode = expression, Deprecated, Final ]
{
$data(i%Data(key))
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %String, key As %String) As %String
{
	Set k=$get(key)
	For  Set k=$order(i%Data(k)) Quit:k=""||(i%Data(k)=element)
	Quit k
}

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %String
{
	Set key=$order(i%Data($get(key)))
	Quit $select(key="":"",1:$get(i%Data(key)))
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %String
{
	Set key=$order(i%Data($get(key)),-1)
	Quit $select(key="":"",1:$get(i%Data(key)))
}

/// Finds and returns the key value of the element at the location following <var>key</var> in the array. 
/// If key is a null string (""), then <b>Next</b> returns the key value for the first element in the array.
Method Next(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%Data(key))
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <METHOD>Next</METHOD> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%Data(key),-1)
}

/// Removes the element associated with <var>key</var> in the array.
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %String) As %String
{
	Set removed=$get(i%Data(key))
	Kill i%Data(key)
	Quit removed
}

/// Sets the value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %String) As %Status
{
	Set i%Data(key)=element
	Quit $$$OK
}

Method %ValidateObject(force As %Integer) As %Status
{
	Set iv=$$$OK
	If i%ElementType="" Quit $$$OK
	Set class=$piece(i%ElementType,":",1),prop=$piece(i%ElementType,":",2)
	Set key="" For  Set key=$order(i%Data(key)) Quit:key=""  Set iv=$classmethod(class,prop_"IsValid",i%Data(key)) Quit:$$$ISERR(iv)
	Quit iv
}

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	Set ptr=0
	For i=1:1 {
		If '$listnext(serialized,ptr,item) Quit
		Set array($list(item))=$list(item,2)
	}
	Quit $$$OK
}

/// Finds and returns the value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$get(i%Data(key))
}

Method %GetSerial(force As %Integer = 0) As %String [ Private ]
{
	Set key="",list="" For  Set key=$order(i%Data(key)) Quit:key=""  Set list=list_$listbuild($listbuild(key,i%Data(key)))
	Quit list
}

Method %SetSerial(serialized As %String) As %Status [ Private ]
{
	Kill i%Data
	Set i%ElementType=""
	Set ptr=0
	For i=1:1 {
		If '$listnext(serialized,ptr,item) Quit
		Set i%Data($list(item))=$list(item,2)
	}
	Quit $$$OK
}

/// Converts the serial state of this array object to a delimited string 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod LogicalToOdbc(val As %String = "") As %String
{
	Quit ##class(%Collection.ArrayOfDT).LogicalToOdbc(val)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod OdbcToLogical(val As %String = "") As %String
{
	Quit ##class(%Collection.ArrayOfDT).OdbcToLogical(val)
}

Storage Custom
{
<StreamLocation>^%Library.ArrayOfDataTypesS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
