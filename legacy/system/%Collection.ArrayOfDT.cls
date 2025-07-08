/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Collection.ArrayOfDT">Working with Collections</a>.</p>
/// The <CLASS>%Collection.ArrayOfDataTypes</CLASS> class represents an array of literal (i.e., data type) elements, 
/// each of which is associated with a unique key value. Keys can have any value, string or numeric.
/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they cannot be used as 'standalone' collections, for this use the <class>%ArrayOfDataTypes</class>.
Class %Collection.ArrayOfDT Extends (%Collection.AbstractArrayOfDT, Super) [ Inheritance = right, System = 2 ]
{

/// Returns the number of elements contained in the array.
Method Count() As %Integer
{
	Set container=$zobjref(i%Owner),storage=i%Storage
	Set key="" For count=0:1 Set key=$order($zobjval(container,storage,0,3,storage,key)) Quit:key=""
	Quit count
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ CodeMode = expression ]
{
$select(key="":0,1:$data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
}

/// <b>This method is deprecated.</b>
/// <p>Please use <METHOD>IsDefined</METHOD> instead.
Method Define(key As %String) As %Boolean [ CodeMode = expression, Deprecated ]
{
$data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key))
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %String, key As %String) As %String
{
	Set k=$get(key),container=$zobjref(i%Owner),storage=i%Storage
	For  Set k=$order($zobjval(container,storage,0,3,storage,k),1,data) Quit:k=""||(data=element)
	Quit k
}

/// Finds and returns the value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String = "") As %String
{
	Quit $select(key="":"",1:$get($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
}

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %String
{
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),1,val)
	Quit $get(val)
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %String
{
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),-1,val)
	Quit $get(val)
}

/// Finds and returns the key value of the element at the location following <var>key</var> in the array. 
/// If key is a null string (""), then <b>Next</b> returns the key value for the first element in the array.
Method Next(key As %String = "") As %String [ CodeMode = expression ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key))
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <METHOD>Previous</METHOD> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ CodeMode = expression ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key),-1)
}

/// Removes the element associated with <var>key</var> in the array.
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %String) As %String
{
	If i%ReadOnly Set tmp=$$$ERROR($$$ReadOnlyCollection) Quit ""
	Set container=$zobjref(i%Owner),storage=i%Storage
	If key=""||($data($zobjval(container,storage,0,3,storage,key),removed)=0) Quit ""
	Kill $zobjval(container,storage,0,3,storage,key)
	Set $zobjmod(container,i%OrefStorage)=1
	Quit removed
}

/// Sets the value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %String) As %Status
{
	If key="" Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage
	Set $zobjval(container,storage,0,3,storage,key)=element,$zobjmod(container,i%OrefStorage)=1
	Quit $$$OK
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",key="",owner=$zobjref(i%Owner),storage=i%Storage
	For {
		Set key = $order($zobjval(owner,storage,0,3,storage,key),1,data) Quit:key=""
		set list = list_$listbuild($listbuild(key,data))
	}
	Quit list
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	If ..Serialize()=serialized Quit $$$OK
	Set sc=..Clear() If $$$ISERR(sc) Quit sc
	Set ptr=0,owner=$zobjref(i%Owner),storage=i%Storage
    While $listnext(serialized,ptr,item) {
	    Set $zobjval(owner,storage,0,3,storage,$list(item))=$list(item,2)
    }
    Set $zobjmod(owner,i%OrefStorage)=1
    Quit $$$OK
}

/// Converts the serial state of this array object to a delimited string 
/// using <var>delim</var> as a delimiter.
ClassMethod LogicalToDisplay(val As %String = "", delim As %String = {$c(13,10)}, class As %String = "", method As %String = "") As %String
{
	Set display=""
	Set ptr=0
	While $listnext(val,ptr,data) {
		For j=1:1:2 {
			Set item=$list(data,j)
			If method'="",j=2 Set item=$classmethod(class,method,item)
			If item'["""",item'[delim,$length($zstrip(item,"<>W"))=$length(item) Set display=display_delim_item Continue
			Set display=display_delim_""""_$replace(item,"""","""""")_""""
		}
	}
	Quit $extract(display,$length(delim)+1,*)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using <var>delim</var> as a delimiter.
ClassMethod DisplayToLogical(val As %String = "", delim As %String = {$c(13,10)}, class As %String = "", method As %String = "") As %String
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
