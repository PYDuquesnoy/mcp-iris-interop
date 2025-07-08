/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occDynamicDispatch, %PVA)

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.DynamicArray">Using Dynamic Entities</a>.</p>
/// Dynamic Object type class.
Class %Library.DynamicObject Extends %Library.DynamicAbstractObject [ Final, System = 1 ]
{

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
    	try {
	    d $zu(210,7,$$$PVTYPEOBJECT)
	} catch { do $$$APPERROR1($$$LASTERROR) }
	return $$$OK
}

///  Property dispatch method to catch references to 
///  virtual properties. <br>
///  This should not be called directly.<br>
Method %DispatchGetProperty(propertyName As %String(MAXLEN="")) [ Internal, ServerOnly = 1 ]
{
    try {
	set ans = $zu(210,4,.propertyName)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ans
}

///  Property dispatch method to catch references to 
///  virtual properties.<br>
///  This should not be called directly.<br>
Method %DispatchSetProperty(propertyName As %String(MAXLEN=""), value As %String(MAXLEN="")) [ Internal, ServerOnly = 1 ]
{
	try {
		set ans = $zu(210,5, .propertyName, .value)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

/// Given the key name of a key/value pair in an object, return the actual
/// value that corresponds to the key name.  If the value is the JSON <i>null</i> value
/// then an empty string "" is returned.  By default an empty string "" is also
/// returned if the value does not exist.  You can
/// differentiate between a <i>null</i> value or an unassigned value
/// that returns a "" string or a real "" string value by using the
/// <method class="%DynamicAbstractObject">%GetTypeOf</method> method.
/// <p>
/// <b><var>key</var></b> The 'key' argument contains the key name value
/// of the object element that you wish to retrieve.
/// <p>
/// <b><var>default</var></b> The 'default' argument is optional and if missing
/// then it is assumed to contain the empty string.  The 'default'
/// value is returned when the selected object element is undefined.
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
/// <p>
/// <b>Returns</b> The value of the object data element as selected by the
/// key name of the <var>key</var> argument.
/// <p>
/// If the 'type' argument is the empty string then the selected object element
/// is converted to the corresponding ObjectScript value.
/// <p>
/// If the 'type' argument is the text value "string", then the value of the
/// object element is converted to an ObjectScript string value.
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
/// the object element is converted to a string value and 
/// then that string value is
/// loaded into a newly created <class>%Stream.DynamicCharacter</class> object
/// or a newly created <class>%Stream.DynamicBinary</class> object.  The oref
/// of the newly created %Stream becomes the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large object element into a
/// <class>%Stream.DynamicCharacter</class> object or a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream" 'type' will convert object
/// elements using the same conventions and conversions
/// as the "string" 'type' value.
/// <p>
/// If the 'type' argument is "stream&gt;base64" then the value of
/// the object element is first converted to a string value.  Then
/// that string value is encoded using Base64 conventions and
/// loaded into a newly created <class>%Stream.DynamicBinary</class>
/// object whose oref will become the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large object element into a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream&gt;base64" 'type' will convert object
/// elements using the same conventions, conversions, restrictions and errors
/// as the "string&gt;base64" 'type' value.
/// <p>
/// If the 'type' argument is "stream&lt;base64" then the value of
/// the object element is first converted to a string value.  Then
/// that string value is decoded using Base64 conventions and
/// loaded into a newly created <class>%Stream.DynamicBinary</class>
/// object whose oref will become the return value of %Get(...).  Unlike
/// ObjectScript string values, converting a large object element into a
/// <class>%Stream.DynamicBinary</class> object will never signal the
/// &lt;MAXSTRING&gt; error (although it may signal &lt;STORE&gt; if the memory
/// capacity of the process is exceeded.)
/// The "stream&lt;base64" 'type' will convert object
/// elements using the same conventions, conversions, restrictions and errors
/// as the "string&lt;base64" 'type' value.
/// <p>
/// If the 'type' argument is "json" then the value of
/// the selected object element is converted to the corresponding JSON
/// value.  Note that converting the following object element
/// values to JSON will signal the &lt;ILLEGAL VALUE&gt; error: the
/// <var>$DOUBLE</var> values for a <b>NaN</b> and an <b>Infinity</b>.
/// Converting any oref value that does not refer to an object of the
/// <class>%DynamicObject</class> class or the <class>%DynamicArray</class> class
/// will signal some form of illegal value or not supported error.
/// <p>
/// There is a possible workaround for the case where dao.%Get(key,,"json")
/// signals a not
/// supported error when the dao element is an ObjectScript oref value.
/// You can modify the class of that object to be "JSON enabled" by inheriting
/// the <class>%JSON.Adaptor</class> class.  You will then be able to
/// call the %JSONExportToString()
/// method to convert that class object to JSON text that can be imported
/// back into an IRIS system.
/// <EXAMPLE>
/// Set Result = dao.%Get(key,,"json")
/// ;; could be replaced by
/// Set Status=dao.%Get(key).%JSONExportToString(.Result)
/// </EXAMPLE>
/// 
Method %Get(key As %String, default As %Any, type As %String) As %Any
{
    Try {
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream" {
	    Set ans = $zu(210,4,.key,"",.type)
	    If ans="" Return $Get(default)
	    If ans.%IsA("%DynamicString") {
		Return ##class(%Stream.DynamicCharacter).%New(ans)
	    } Else {
		Return ##class(%Stream.DynamicBinary).%New(ans)
	    }
	}
	Return $ZU(210,4,.key,.default,.type)
    } Catch { do $$$APPERROR1($$$LASTERROR) }
}

/// INTERNAL ONLY!
/// <br><p>
/// The <method>%GetTypeCodeOf</method> method is for internal use only.  The
/// actions taken by this method may change in the future as additional
/// capabilities are added to <class>%DynamicAbstractObject</class> class objects.
/// 
Method %GetTypeCodeOf(key As %String) As %Integer [ Internal ]
{
	try {
		set ans = $zutil(210,13, .key)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

/// <p>
/// Generates a %Iterator.Object object which contains a %GetNext(.key,.value,.type)
/// method which will iterate over all the defined elements in the %DynamicObject
/// object.
/// <p>
/// Warning:  Adding elements to the %DynamicArray object during an interation
/// can cause possible unexpected results during future  calls on the
/// %GetNext(.key,.value,.type) method.  It is undefined whether an added
/// element is part of the iteration.  An element added during an iteration may
/// be returned by %GetNext iteration method or the added
/// element may be skipped by the %GetNext iteration method.
/// <p>
/// In the example below, we will output all values contained in a
/// <class>%DynamicObject</class>.
/// <EXAMPLE>
///    set iter = DynObject.%GetIterator()
///    while iter.%GetNext(.key, .value, .type ) {
///       write "key = "_key_", value = "_value_", type = "_type,!
///    }
/// </EXAMPLE>
/// See the descriptions of the <method class="%Iterator.Object">%GetNext</method> method in the <class>%Iterator.Object</class> class for more details.
Method %GetIterator() As %Iterator.Object
{
	return ##class(%Iterator.Object).%New($this)
}

/// Tests if a key is defined within an object.
/// <p>
/// <b>key</b> The key name of the value you wish to test.
/// <p>
/// <b>Returns</b> A <class>%Boolean</class> value to show if a value
/// is defined (1) or not (0).
Method %IsDefined(key As %String) As %Boolean
{
	try {
		set type = $zu(210,13, .key)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return $case(type,$$$PVVALUEUNASSIGNED:0,$$$PVVALUEEOF:0,:1)
}

/// Remove the element with the named key from the <class>%DynamicObject</class>.
/// <p>
/// <b>key</b> The key name of the <class>%DynamicObject</class>
/// element you wish to remove.
/// <p>
/// <b>Returns</b> The value of the removed
/// <class>%DynamicObject</class> element.
Method %Remove(key As %String) As %DynamicAbstractObject
{
	try {
		set ans = $zu(210,21, .key)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

/// Create a new value or update an existing value. 
/// <p>
/// <b>key</b> The key name of the value you wish to create or update.
/// <p>
/// <b>value</b> The new value with which to update the previous value
/// or create a new value.
/// <p>
/// <b>type</b> OPTIONAL, the 'type' of the value being assigned. 
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
/// <b>Returns</b> An OREF to the current modified object, allowing calls to
/// <method>%Set</method> to be nested.
/// <p>
/// If the 'type' argument is the empty string then ObjectScript 'value' argument
/// is stored in the object without conversion.
/// <p>
/// If the 'type' argument is "null" and the 'value' argument contains the
/// empty string then the JSON value <i>null</i> is stored in the object element;
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
/// object element as a string value.
/// <p>
/// If the 'type' argument is "stream&gt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The entire contents of the %Stream must consist of binary
/// characters and the Base64 encoding of those characters are stored in
/// the object element as a string value.  The characters in the %Stream
/// must be values
/// between $CHAR(0) and $CHAR(255) because only those character values
/// can be converted using Base64 encoding. If the %Stream contains a
/// character value greater than $CHAR(255) then a &lt;WIDE CHAR&gt;
/// error is signaled.
/// <p>
/// If the 'type' argument is "stream&lt;base64" then the 'value' argument must
/// contain a reference to an object which is a subclass of the %Stream.Object
/// class.  The contents of that %Stream are decoded using Base64 conventions
/// and the result is stored in the object element as a string value.
/// If a character not supported by the Base64 encoding is encountered in
/// the %Stream then an &lt;ILLEGAL VALUE&gt; error is signaled. The
/// white-space characters supported by the Base64 encoding may appear
/// in the string and those characters will be ignored. Decoding stops
/// when either the "=" termination character is encountered or the end
/// of the string is encountered.
/// </p>
Method %Set(key As %String, value As %Library.Any, type As %String) As %DynamicAbstractObject
{
    Try {
	Set type=$Zcvt($Get(type),"l")
	If $Extract(type,1,6)="stream",$IsObject(value) {
	    #; Convert 'value' from a %Stream to a %DynamicString
	    Set value = ..ConvertStreamToValue(value)
	}
	Return $ZU(210,5,.key,.value,.type)
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

ClassMethod %FromOref(source As %Library.AbstractSet = "", laxMode As %Integer = 1) As %Library.DynamicObject [ Internal ]
{
	try {
		#; if '$Isobject(target) {
		#; 	if 'source.%IsA("%Library.DynamicObject") {
				set returnValue = {}
		#; 	} else {
		#; 			// Early out for now - just clone the source array and return
		#; 		return source.%Clone()
		#; 	}
		#; } else {
		#; 	set returnValue = target
		#; }

		if '$isobject(source) {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError, "Cannot project non-object value to DynamicObject"))
		}

		if (source.%IsA("%Library.RegisteredObject")) {
				// we invert the normal rule of always going "from" something to "to" so that users have the ability to override the default behavior.
			set returnValue = ##class(%Library.EntityProjectionUtil).projectObjectFromOref(source)
		} elseif source.%IsA("%Library.DynamicArray") {
				// What does it mean to compose an object from an array?
			set it = source.%GetIterator()
			while it.%GetNext(.key,.value) {
				do returnValue.%Set(""_key,value)
			}
		} else {
				// must be another object - merge it into me:
			set it = source.%GetIterator()
			while it.%GetNext(.key,.value) {
				do returnValue.%Set(key,value)
			}
		}
	} catch exception {
		set returnValue = ""
		throw exception
	}
	return returnValue
}

}
