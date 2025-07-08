/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occDynamicDispatch, %PVA)

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.DynamicArray">Using Dynamic Entities</a>.</p>
/// Dynamic Array type class.
Class %Library.DynamicArray Extends %Library.DynamicAbstractObject [ Final, System = 1 ]
{

/// <p>
/// add <var>value</var> to the set.
/// </p>
/// <p>
/// It is left to the implementation to decide whether duplicates are allowed (multiset) or not (proper set).
/// </p>
/// </p><p>
/// parameters:
/// <ul><li>value: value to add to the set</li></ul>
/// </p><p>
/// returns:<ul><li>oref referencing the modified set</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method add(value As %Library.Any) As %Library.DynamicArray
{
	return ..%Push(value)
}

/// add() all <var>values[n]</var> where 0&leq;n&leq; size(<var>values</var>) 
/// </p><p>
/// parameters:
/// <ul><li>values: array of values to add to the set</li></ul>
/// </p><p>
/// returns:<ul><li>oref referencing the modified set</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method addAll(value As %Library.AbstractSet) As %Library.DynamicArray
{
	if '$isobject(value) || ('(value.%IsA("%Library.AbstractSet"))) {
		return $this
	}
	set ait = value.iterator()
	for  {
	    set next = ait.next()
	    quit:'$isobject(next)
	    do ..%Push(next.value)
	}
	return $this
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
    try {
	d $zu(210,7,$$$PVTYPEARRAY)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q $$$OK
}

/// Property dispatch method to catch references to
/// virtual properties. <br>
/// This should not be called directly.<br>
Method %DispatchGetProperty(propertyName As %String) [ Internal, ServerOnly = 1 ]
{
    try {
    	set ans = $zu(210,10, .propertyName)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

/// Property dispatch method to catch references to
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchSetProperty(propertyName As %String(MAXLEN=""), value As %String) [ Internal, ServerOnly = 1 ]
{
    try {
	set ans= $zu(210,17, .propertyName, .value)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

/// Returns the value of the last member of the array. The value is then removed from the array.  Nothing is removed if the array is empty.
/// <p>
/// Note:  Any of the 4 situations causes <method>%Pop</method> to return the empty string, "":
/// <ul>
/// <li> (1) Popping from an empty array
/// <li> (2) Last member is the empty string
/// <li> (3) Last member is the value <i>null</i>
/// <li> (4) Last member is unassigned
/// </ul>
/// <p>
/// If you want to differentiate between these 4 cases then you must test the array and its last element before calling the <method>%Pop</method> method.
/// <p>
/// <b>Returns</b> The value of the last member of the array.
/// <br>If the array is empty, the method returns the empty string, "".
/// 
Method %Pop() As %Library.Any
{
    try {
    	set ans = $zu(210,24)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

/// Remove the element at the specified index position from the 
/// <class>%DynamicArray</class>.  All <class>%DynamicArray</class>
/// elements following the removed
/// element will have their subscript position decremented by 1.  This may cause
/// problems with any <class>%Iterator.Array</class> object iterating over
/// this <class>%DynamicArray</class>.
/// <p>
/// <b>pos</b> Index position within the <class>%DynamicArray</class>
/// of the element you wish to remove.
/// <p>
/// <b>Returns</b> The value of the removed <class>%DynamicArray</class>
/// element.
Method %Remove(pos As %Integer) As %DynamicAbstractObject
{
    try {
	set ans = $zu(210,19, .pos)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

/// Given the index position of a value in an array, return the actual value
/// that corresponds to the index.  If the value is the JSON <i>null</i> value
/// then an empty string "" is returned.  By default an empty string "" is also
/// returned if the value does not exist.  You can
/// differentiate between a <i>null</i> value or an unassigned value
/// that returns a "" string or a real "" string value by using the
/// <method class="%Library.DynamicAbstractObject">%GetTypeOf</method> method.
/// <p>
/// <b><var>key</var></b> The 'key' argument contains the index value of
/// the array element that you wish to retrieve.  Note that the <var>key</var> of a
/// <class>%DynamicArray</class> is evaluated as an ObjectScript integer
/// expression so that dynarray.%Get("abc") gives the same value as
/// dynarray.%Get(0).
/// <p>
/// <b><var>default</var></b> The 'default' argument is optional, and if missing
/// then it is assumed to contain the empty string.  The 'default'
/// value is returned when the selected array element is undefined.
/// <p>
/// <b><var>type</var></b> The 'type' argument is optional, and if missing then
/// it is assumed to contain the empty string.
/// <p>If the 'type' argument is present then its value  must be one
/// of the following string values:
/// <br>
/// <br> "" &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp; - %Get(key) without conversions	
/// <br> "string" &emsp;&emsp;&emsp;&emsp;&ensp; - Convert to text string
/// <br> "string&gt;base64" &ensp;- Convert to text string then encode into base64
/// <br> "string&lt;base64" &ensp;- Convert to text string then decode from base64
/// <br> "stream" &emsp;&emsp;&emsp;&emsp; - Place string conversion into %Stream
/// <br> "stream&gt;base64"  - String encoded into base64 into %Stream
/// <br> "stream&lt;base64"  - String decoded from base64 into %Stream
/// <br> "json" &emsp;&emsp;&emsp;&emsp;&emsp;&ensp; - Convert to JSON representation
/// </p>
/// </p>
/// <p>
/// <b>Returns</b> The value of the array data element as selected by the index
/// value of the <var>key</var> argument.
/// <p>
/// If the 'type' argument is the empty string then the selected array element
/// is converted to the corresponding ObjectScript value.
/// <p>
/// If the 'type' argument is the text value "string", then the value of the
/// array element is converted to an ObjectScript string value.
/// The JSON <i>null</i> value is converted to the empty string;
/// the values dervied from JSON <i>false</i>, JSON <i>true</i> and a
/// JSON format number will keep their JSON textual representation;
/// an ObjectScript numeric value will use its ObjectScript canonical numeric
/// representation (this includes the IEEE floating-point values for $DOUBLE("nan")
/// and $DOUBLE("inf"));
/// JSON array and JSON object values (represented by
/// <class>%DynamicArray</class> and <class>%DynamicObject</class> oref values)
/// and any other ObjectScript oref values are given their default ObjectScript
/// conversion to string representation (e.g., "99@%Library.DynamicArray").
/// <p>
/// If the 'type' argument is "string&gt;base64" then the value is first
/// converted using the string type and then that result is encoded using
/// Base64 encoding.  The characters of the string
/// value must be values between $CHAR(0) and $CHAR(255) because only those
/// character values can be converted using Base64 encoding.
/// If the string contains a character
/// value greater than $CHAR(255) then a &lt;WIDE CHAR&gt; error is signaled.
/// <p>
/// If the 'type' argument is "string&lt;base64" then
/// the string value of the element
/// must contain a Base64 encoded string and the string characters are
/// decoded into binary bytes.  If a character not supported by
/// the Base64 encoding is
/// encountered then an &lt;ILLEGAL VALUE&gt; error is signaled.  The white-space
/// characters supported by the Base64 encoding may appear in the string and those
/// characters will be ignored.
/// Decoding stops when either the "=" termination character is encountered
/// or the end of the string is encountered.
/// <p>
/// If the 'type' argument is "stream" then the value of
/// the array element is converted to a string value and 
/// then that string value is
/// loaded into a newly created <class>%Stream.DynamicCharacter</class> object
/// or a newly created <class>%Stream.DynamicBinary</class> object.  The oref
/// of the newly created %Stream becomes the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large array element into a
/// <class>%Stream.DynamicCharacter</class> object or a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream" 'type' will convert array
/// elements using the same conventions and conversions
/// as the "string" 'type' value.
/// <p>
/// If the 'type' argument is "stream&gt;base64" then the value of
/// the array element is first converted to a string value.  Then
/// that string value is encoded using Base64 conventions and
/// loaded into a newly created <class>%Stream.DynamicBinary</class>
/// object whose oref will become the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large array element into a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream&gt;base64" 'type' will convert array
/// elements using the same conventions, conversions, restrictions and errors
/// as the "string&gt;base64" 'type' value.
/// <p>
/// If the 'type' argument is "stream&lt;base64" then the value of
/// the array element is first converted to a string value.  Then
/// that string value is decoded using Base64 conventions and
/// loaded into a newly created <class>%Stream.DynamicBinary</class>
/// object whose oref will become the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large array element into a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream&lt;base64" 'type' will convert array
/// elements using the same conventions, conversions, restrictions and errors
/// as the "string&lt;base64" 'type' value.
/// <p>
/// If the 'type' argument is "json" then the value of
/// the selected array element is converted to the corresponding JSON
/// value.  Note that converting the following array element
/// values to JSON will signal the &lt;ILLEGAL VALUE&gt; error: the
/// <var>$DOUBLE</var> values for a <b>NaN</b> and an <b>Infinity</b>.
/// Converting any oref value that does not refer to an object of the
/// <class>%DynamicObject</class> class or the <class>%DynamicArray</class> class
/// will signal some form of illegal value or not supported error.
/// <p>
/// There is a possible workaround for the case where dao.%Get(index,,"json")
/// signals a not
/// supported error when the dao element is an ObjectScript oref value.
/// You can modify the class of that object to be "JSON enabled" by inheriting
/// the <class>%JSON.Adaptor</class> class.  You will then be able to
/// call the %JSONExportToString()
/// method to convert that class object to JSON text that can be imported
/// back into an IRIS system.
/// <EXAMPLE>
/// Set Result = dao.%Get(index,,"json")
/// ;; could be replaced by
/// Set Status=dao.%Get(index).%JSONExportToString(.Result)
/// </EXAMPLE>
/// 
Method %Get(key As %Integer, default As %Any, type As %String) As %Any
{
    Try {
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream" {
	    Set ans = $zu(210,10,.key,"",.type)
	    If ans="" Return $Get(default)
	    If ans.%IsA("%DynamicString") {
		Return ##class(%Stream.DynamicCharacter).%New(ans)
	    } Else {
		Return ##class(%Stream.DynamicBinary).%New(ans)
	    }
	}
	Return $ZU(210,10,.key,.default,.type)
    } Catch { do $$$APPERROR1($$$LASTERROR) }
}

/// INTERNAL ONLY!
/// <br><p>
/// The <method>%GetTypeCodeOf</method> method is for internal use only.  The
/// actions taken by this method may change in the future as additional
/// capabilities are added to <class>%DynamicAbstractObject</class> class objects.
/// 
Method %GetTypeCodeOf(key As %Integer) As %Integer [ Internal ]
{
    
    try {
	set ans= $zu(210,11, .key)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

/// <p>
/// Generates a %Iterator.Array object which contains a %GetNext(.key,.value,.type)
/// method which will iterate over all the defined elements in the %DynamicArray
/// object.
/// <p>
/// Warning:  Adding or removing elements to the %DynamicArray during an
/// interation can cause further calls on the %GetNext(.key,.value,.type) method
/// to have undefined behavior.  This happens because adding or removing an array
/// element causes the following elements to have their index numbers modified.  The
/// modification of index numbers can cause elements to be skipped by the
/// %GetNext iteration method or can cause elements to be visited more than once
/// by the %GetNext iteration method.
/// <p>
/// In the example below, we will output all values contained in a
/// <class>%DynamicArray</class>.
/// <EXAMPLE>
///    set iter = DynArray.%GetIterator()
///    while iter.%GetNext(.key, .value, .type ) {
///       write "key = "_key_", value = "_value_", type = "_type,!
///    }
/// </EXAMPLE>
/// See the descriptions of the <method class="%Iterator.Array">%GetNext</method> method in the <class>%Iterator.Array</class> for more details.
Method %GetIterator() As %Iterator.Array
{
    return ##class(%Iterator.Array).%New($this)
}

/// Tests if a key is defined within an array.
/// <p>
/// <b>key</b> The index position of the value you wish to test, indexes
/// begin at position 0.  Note that the <var>key</var> of a
/// <class>%DynamicArray</class> is evaluated as an ObjectScript integer
/// expression so that dynarray.%IsDefined("abc") gives the same value as
/// dynarray.%IsDefined(0).
/// <p>
/// <b>Returns</b> A boolean value to show if a value is
/// defined (1) or not (0).
Method %IsDefined(key As %Integer) As %Boolean
{
    	try {
	    set type = $zu(210,11, .key)
	} catch { do $$$APPERROR1($$$LASTERROR) }
	return $case(type,$$$PVVALUEUNASSIGNED:0,$$$PVVALUEEOF:0,:1)
}

/// <p>
/// Given a new value, append it to the end of the current array,
/// increasing the length of the array. 
/// </p>
/// <p>
/// <b><var>value</var></b> The new value to push. 
/// </p>
/// <p>
/// <b><var>type</var></b> OPTIONAL, the 'type' of the value to push. 
/// </p>
/// <p>If the 'type' argument is present then its value must be one
/// of the following string values:
/// <br>
/// <br> "" &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp; - %Push(value) without conversions	
/// <br> "null" &emsp;&emsp;&emsp;&emsp;&emsp;&ensp; - "" becomes <i>null</i>; else  push with no conversion
/// <br> "boolean" &emsp;&emsp;&emsp;&ensp; - 0/nonzero becomes JSON <i>false</i>/<i>true</i>
/// <br> "number" &emsp;&emsp;&emsp;&ensp; - Convert to numeric value
/// <br> "string" &emsp;&emsp;&emsp;&emsp;&ensp; - Convert to text string
/// <br> "string&gt;base64" &ensp;- Convert to text string then encode into base64
/// <br> "string&lt;base64" &ensp;- Convert to text string then decode from base64
/// <br> "stream" &emsp;&emsp;&emsp;&emsp; - %Stream contents converted to text string
/// <br> "stream&gt;base64"  - %Stream contents are encoded into base64 string
/// <br> "stream&lt;base64"  - %Stream is decoded from base64 into byte string
/// </p>
/// <p>
/// <b>Returns</b> An OREF referencing the current modified array, allowing
/// calls to <method>%Push</method> to be nested. 
/// <p>
/// If the 'type' argument is the empty string then ObjectScript 'value' argument
/// is pushed onto the array without conversion.
/// <p>
/// If the 'type' argument is "null" and the 'value' argument contains the
/// empty string then the JSON value <i>null</i> is pushed onto the array;
/// all other ObjectScript values are pushed without conversion.
/// <p>
/// If the 'type' argument is "boolean" then the 'value' argument
/// is first converted to a number.  If
/// that value is zero then the JSON value <i>false</i> is pushed; otherwise
/// the JSON value <i>true</i> is pushed.
/// <p>
/// If the 'type' argument is "number" then the 'value' argument is converted
/// to an ObjectScript numeric representation before being pushed.
/// <p>
/// If the 'type' argument is "string" then the 'value' argument is converted to
/// string representation before being pushed.
/// <p>
/// If the 'type' argument is "string&gt;base64" then the 'value' argument is
/// converted to string representation and then the Base64 encoding of that
/// string is pushed.  The characters of the string value must be values
/// between $CHAR(0) and $CHAR(255) because only those character values
/// can be converted using Base64 encoding. If the string contains a
/// character value greater than $CHAR(255) then a &lt;WIDE CHAR&gt;
/// error is signaled.
/// <p>
/// If the 'type' argument is "string&lt;base64" then the 'value' argument is
/// converted to string representation and then the Base64 decoding of that
/// string is pushed.  If a character not supported by the Base64 encoding
/// is encountered then an &lt;ILLEGAL VALUE&gt; error is signaled. The
/// white-space characters supported by the Base64 encoding may appear
/// in the string and those characters will be ignored. Decoding stops
/// when either the "=" termination character is encountered or the end
/// of the string is encountered.
/// <p>
/// If the 'type' argument is "stream" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The entire contents of the %Stream are pushed onto the
/// array as a string value.
/// <p>
/// If the 'type' argument is "stream&gt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The entire contents of the %Stream must consist of binary
/// characters and the Base64 encoding of those characters are pushed onto
/// the array as a string value.  The characters in the %Stream must be values
/// between $CHAR(0) and $CHAR(255) because only those character values
/// can be converted using Base64 encoding. If the %Stream contains a
/// character value greater than $CHAR(255) then a &lt;WIDE CHAR&gt;
/// error is signaled.
/// <p>
/// If the 'type' argument is "stream&lt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The contents of that %Stream are decoded using Base64 conventions
/// and the result is pushed onto the array as a string value.
/// If a character not supported by the Base64 encoding is encountered in
/// the %Stream then an &lt;ILLEGAL VALUE&gt; error is signaled. The
/// white-space characters supported by the Base64 encoding may appear
/// in the string and those characters will be ignored. Decoding stops
/// when either the "=" termination character is encountered or the end
/// of the string is encountered.
/// </p>
Method %Push(value As %Library.Any, type As %String) As %DynamicAbstractObject
{
    Try {
#IF 1 ; // This can be removed once $zu(210,20) accepts a type argument
	if $Get(type) = "" {
	    Return $zu(210,20,.value)
	}
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream",$IsObject(value) {
	    #; Convert 'value' from a %Stream to a %DynamicString
	    Set value = ..ConvertStreamToValue(value)
	}
	set key = ..%Size()
	Return $zu(210,17,.key,.value,.type)
#ELSE ; // This should be the implementation of push
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream",$IsObject(value) {
	    #; Convert 'value' from a %Stream to a %DynamicString
	    Set value = ..ConvertStreamToValue(value)
	}
	Return $zu(210,20,.value,.type)
#ENDIF ;
    } Catch { do $$$APPERROR1($$$LASTERROR) }
}

/// Create a new value or update an existing value. 
/// <p>
/// <b><var>key</var></b> The index position of the value you wish to create,
/// indexes begin at position 0.  Note that the <var>key</var> of a
/// <class>%DynamicArray</class> is evaluated as an ObjectScript integer
/// expression so that dynarray.%Set("abc",value,type) provides the same
/// operation as dynarray.%Set(0,value,type).
/// <p>
/// <b><var>value</var></b> The new value with which to update the previous value
/// or create a new value.
/// <p>
/// <b><var>type</var></b> OPTIONAL, the type of the value being assigned. 
/// </p>
/// <p>If the 'type' argument is present then its value must be one
/// of the following string values:
/// <br>
/// <br> "" &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp; - %Set(key,value) without conversions	
/// <br> "null" &emsp;&emsp;&emsp;&emsp;&emsp;&ensp; - "" becomes <i>null</i>; else assign with no conversion
/// <br> "boolean" &emsp;&emsp;&emsp;&ensp; - 0/nonzero becomes JSON <i>false</i>/<i>true</i>
/// <br> "number" &emsp;&emsp;&emsp;&ensp; - Convert to numeric value
/// <br> "string" &emsp;&emsp;&emsp;&emsp;&ensp; - Convert to text string
/// <br> "string&gt;base64" &ensp;- Convert to text string then encode into base64
/// <br> "string&lt;base64" &ensp;- Convert to text string then decode from base64
/// <br> "stream" &emsp;&emsp;&emsp;&emsp; - %Stream contents converted to text string
/// <br> "stream&gt;base64"  - %Stream contents are encoded into base64 string
/// <br> "stream&lt;base64"  - %Stream is decoded from base64 into byte string
/// </p>
/// <p>
/// <b>Returns</b> An OREF to the current modified array, allowing calls to
/// <method>%Set</method> to be nested.
/// <p>
/// If the 'type' argument is the empty string then ObjectScript 'value' argument
/// is stored in the array without conversion.
/// <p>
/// If the 'type' argument is "null" and the 'value' argument contains the
/// empty string then the JSON value <i>null</i> is stored in the array element;
/// all other ObjectScript values are stored without conversion.
/// <p>
/// If the 'type' argument is "boolean" then the 'value' argument
/// is first converted to a number.  If
/// that value is zero then the JSON value <i>false</i> is stored; otherwise
/// the JSON value <i>true</i> is stored.
/// <p>
/// If the 'type' argument is "number" then the 'value' argument is converted
/// to an ObjectScript numeric representation before being stored.
/// <p>
/// If the 'type' argument is "string" then the 'value' argument is converted to
/// string representation before being stored.
/// <p>
/// If the 'type' argument is "string&gt;base64" then the 'value' argument is
/// converted to string representation and then the Base64 encoding of that
/// string is stored.  The characters of the string value must be values
/// between $CHAR(0) and $CHAR(255) because only those character values
/// can be converted using Base64 encoding. If the string contains a
/// character value greater than $CHAR(255) then a &lt;WIDE CHAR&gt;
/// error is signaled.
/// <p>
/// If the 'type' argument is "string&lt;base64" then the 'value' argument is
/// converted to string representation and then the Base64 decoding of that
/// string is stored.  If a character not supported by the Base64 encoding
/// is encountered then an &lt;ILLEGAL VALUE&gt; error is signaled. The
/// white-space characters supported by the Base64 encoding may appear
/// in the string and those characters will be ignored. Decoding stops
/// when either the "=" termination character is encountered or the end
/// of the string is encountered.
/// <p>
/// If the 'type' argument is "stream" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The entire contents of the %Stream are stored in the
/// array element as a string value.
/// <p>
/// If the 'type' argument is "stream&gt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The entire contents of the %Stream must consist of binary
/// characters and the Base64 encoding of those characters are stored in
/// the array element as a string value.  The characters in the %Stream
/// must be values
/// between $CHAR(0) and $CHAR(255) because only those character values
/// can be converted using Base64 encoding. If the %Stream contains a
/// character value greater than $CHAR(255) then a &lt;WIDE CHAR&gt;
/// error is signaled.
/// <p>
/// If the 'type' argument is "stream&lt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The contents of that %Stream are decoded using Base64 conventions
/// and the result is stored in the array element as a string value.
/// If a character not supported by the Base64 encoding is encountered in
/// the %Stream then an &lt;ILLEGAL VALUE&gt; error is signaled. The
/// white-space characters supported by the Base64 encoding may appear
/// in the string and those characters will be ignored. Decoding stops
/// when either the "=" termination character is encountered or the end
/// of the string is encountered.
/// </p>
Method %Set(key As %Integer, value As %Library.Any, type As %String) As %DynamicAbstractObject
{
    Try {
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream",$IsObject(value) {
	    #; Convert 'value' from a %Stream to a %DynamicString
	    Set value = ..ConvertStreamToValue(value)
	}
	Return $ZU(210,17,.key,.value,.type)
    } Catch { do $$$APPERROR1($$$LASTERROR) }
}

Method %DispatchMethod(methodName As %String(MAXLEN=""), args...)
{
	if $E(methodName,*-2,*)="Get" {
		if methodName="Get" {
			do $$$APPERROR1NOMETHOD(methodName,..%ClassName(1))
		}
		if $D(args)'=0 {
			do $$$APPERROR1($$$ERPARAM)
		}
		quit ..%DispatchGetProperty($E(methodName,1,*-3))
	}
	if $E(methodName,*-2,*)="Set" {
		if methodName="Set" {
			do $$$APPERROR1NOMETHOD(methodName,..%ClassName(1))
		}
		if $G(args)'=1 {
			do $$$APPERROR1($$$ERPARAM)
		}
		quit ..%DispatchSetProperty($E(methodName,1,*-3),args(1))
	}
    if (methodName '= "") && ($$$comMemberKeyGet($classname(), $$$cCLASSmethod, methodName, $$$cMETHabstract)) {
        $$$ThrowMethodIsAbstractError(methodName)
    }
	$$$ThrowMethodDoesNotExistError(methodName)
}

ClassMethod fromObject(source = "", returnValue = "", laxMode As %Integer = 1) As %Library.DynamicArray [ Internal ]
{
	try {
		if '$Isobject(returnValue) {
			if 'source.%IsA("%Library.DynamicArray") {
				set me = []
			} else {
					// Early out for now - just clone the source array and return
				return source.%Clone()
			}
		} else {
			if 'source.%IsA("%Library.DynamicArray") {
				set me = returnValue
			} else {
					// Early out for now - just append the source array to the returnValue
				set size = source.%Size() - 1
				for ptr = 0:1:size {
					do returnValue.%Push(source.%Get(ptr))
				}
				return returnValue
			}
		}
			// still here? Must be none of the shortcuts for a %DynamicArray source were taken. Now do the hard work
			// We recognize %Collection.AbstractList, everything else is inserted as a single %DynamicObject element
		if (source.%IsA("%Collection.AbstractList")) || (source.%IsA("%RegisteredObject")) {
				// We have to honor the class implementation of the composition - can't do it here.
				// we invert the normal rule of always going "from" something to "to" so that users have the ability to override the default behavior.
			do source.%ToDynamicArray(me,laxMode)
		} else {
				// The only other choice for an instantiable class is %AbstractObject and we've already dealt with the %DynamicArray case so...%DynamicObject it must be!
				// What does it mean to compose an array from an object?
			do me.%Push(element.fromObject(element))
		}
	} catch exception {
		set me = $$$NULLOREF
	}
	return me
}

}
