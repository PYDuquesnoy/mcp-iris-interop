/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Collection.ListOfDT">Working with Collections</a>.</p>
/// The <CLASS>%Collection.ListOfDT</CLASS> class represents a list of literal (i.e., data type) values
/// each of which is associated with a numeric position in the list. 
/// The first element in the list is stored at position 1.
/// <p>These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they cannot be used as 'standalone' collections; for this, use the <class>%ListOfDataTypes</class>.</p>
Class %Collection.ListOfDT Extends (%Collection.AbstractListOfDT, Super) [ Inheritance = right, System = 2 ]
{

/// <var>Size</var> is the number of elements contained in the list. This is the same value returned by the <method>Count</method>.
Property Size As %Integer [ Calculated ];

Method SizeSet(newvalue As %Integer) As %Status [ Abstract ]
{
}

Method SizeGet() As %Integer [ CodeMode = expression ]
{
+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
}

/// Returns the number of elements contained in the list.
Method Count() As %Integer [ CodeMode = expression, Final ]
{
+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %Integer) As %Boolean [ CodeMode = expression ]
{
$select(key="":0,1:$data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
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
	For k=k:1:+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1) If $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,k)=element Set found=k Quit
	Quit found
}

/// Finds and returns the value of the element at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer = 0) As %String [ CodeMode = expression, Final ]
{
$select(key="":"",1:$get($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
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
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),1,val)
	Quit $get(val)
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
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),-1,val)
	Quit $get(val)
}

/// Inserts an element with value <var>element</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %String) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)+1)=element,$zobjmod($zobjref(i%Owner),i%OrefStorage)=1
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
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set key=+key,count=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
	If key<1||(key>(count+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	For i=count:-1:key Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,i+1)=$zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,i)
	Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)=element,$zobjmod($zobjref(i%Owner),i%OrefStorage)=1
	Quit $$$OK
}

/// Inserts a list with value <var>inslist</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %String) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set size=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
	Set ptr=0
	For i=1:1 {
		If '$listnext(inslist,ptr,item) Quit
		Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,size+i)=$get(item)
	}
	Set $zobjmod($zobjref(i%Owner),i%OrefStorage)=1
	Quit $$$OK
}

/// Inserts an element with value <var>element</var> into the list at the correct ordered 
/// position. The elements in the list are shifted to accommodate the new element as necessary.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertOrdered(element As %String) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set count=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)+1
	For i=1:1:count Quit:(i=count)||($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,i)]element)
	Quit ..InsertAt(element,i)
}

/// Finds and returns the index value of the element at the location following <var>key</var> in the list. 
/// If key is a null string (""), then <b>Next</b> returns the position of the first element in the list (1).
Method Next(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key))
}

/// Finds and returns the index value of the element at the location preceding <var>key</var> in the list. 
/// If key is a null string (""), then <b>Next</b> returns the position of the last element in the list.
Method Previous(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key),-1)
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
/// if no element was removed.
Method RemoveAt(key As %Integer) As %String
{
	If i%ReadOnly Set tmp=$$$ERROR($$$ReadOnlyCollection) Quit ""
	Set count=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
	If key=""||($data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key),removed)=0) Quit ""
	For i=key:1:count-1 Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,i)=$zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,i+1)
	Kill $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,count)
	Set $zobjmod($zobjref(i%Owner),i%OrefStorage)=1
	Quit removed
}

/// Sets the value of the element at position <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %String, key As %Integer) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	If ('+key)||((+key'=1)&&($data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key-1))=0)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)=element,$zobjmod($zobjref(i%Owner),i%OrefStorage)=1
	Quit $$$OK
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>%delim</var> argument as a delimiter.
ClassMethod LogicalToDisplay(val As %String = "", delim As %String = {$char(13,10)}, class As %String = "", method As %String = "") As %String
{
	If method="" {
		Set display=$lts(val,delim)
		If display'["""",$length(display,delim)=$listlength(val) Quit display
	}
	Set display="",ptr=0
	While $listnext(val,ptr,item) {
		If method'="" Set item=$classmethod(class,method,item)
		If item'["""",item'[delim,$length($zstrip(item,"<>W"))=$length(item) Set display=display_delim_item Continue
		Set display=display_delim_""""_$replace(item,"""","""""")_""""
	}
	Quit $extract(display,$length(delim)+1,*)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>delim</var> argument as a delimiter.
ClassMethod DisplayToLogical(val As %String = "", delim As %String = {$char(13,10)}, class As %String = "", method As %String = "") As %String
{
	If val="" Quit ""
	If method="",val'["""" Quit $lfs(val,delim)
	Set logical="",out="",delimlen=$length(delim)
hloop	If $extract(val,1,delimlen)=delim { Goto hdel } If $extract(val)="""" { Goto hquote }
hdefault	Set stuff=$piece(val,delim),out=out_stuff,val=$extract(val,$length(stuff)+1,*) If val="" { Goto hdel } Goto hloop
hquote	Set stuff=$find(val,"""",2) Set:stuff=0 stuff=$length(val)+10
	Set out=out_$extract(val,2,stuff-2),val=$extract(val,stuff,*)
	If $extract(val)="""" { Set out=out_"""" Goto hquote } Else { Goto hdefault }
hdel	Set logical=logical_$listbuild($select(method="":out,1:$classmethod(class,method,out))),out="",val=$extract(val,delimlen+1,*)
	If val="" Quit logical
	Goto hloop
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>%delim</var> argument as a delimiter.
ClassMethod LogicalToFDBMS(val As %String = "", delim As %String = {$char(13,10)}) As %String [ CodeMode = expression ]
{
$lts(val,delim)
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>delim</var> argument as a delimiter.
ClassMethod FDBMSToLogical(val As %String = "", delim As %String = {$char(13,10)}) As %String [ CodeMode = expression ]
{
$lfs(val,delim)
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",owner=$zobjref(i%Owner),storage=i%Storage
	For key=1:1:+$order($zobjval(owner,storage,0,3,storage,""),-1) {
		set list = list_$listbuild($get($zobjval(owner,storage,0,3,storage,key)))
	}
	Quit list
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	Set ptr=0,key=0,changed=0,owner=$zobjref(i%Owner),storage=i%Storage,oldcount=+$order($zobjval(owner,storage,0,3,storage,""),-1)
	If oldcount'=$listlength(serialized) {
		Set changed=1,sc=..Clear()
		If $$$ISERR(sc) Quit sc
	    While $listnext(serialized,ptr,item) {
		    Set $zobjval(owner,storage,0,3,storage,$increment(key))=item
	    }
	} Else {
		If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	    While $listnext(serialized,ptr,item) {
		    If $zobjval(owner,storage,0,3,storage,$increment(key))'=item {
		    	Set $zobjval(owner,storage,0,3,storage,key)=item,changed=1
		    }
	    }
	}
	If changed Set $zobjmod(owner,i%OrefStorage)=1
    Quit $$$OK
}

}
