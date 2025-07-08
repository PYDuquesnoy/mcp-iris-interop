/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %PVA)

/// Iterator over elements in a %DynamicObject
Class %Iterator.Object Extends %Iterator.Array [ System = 3 ]
{

/// %GetNext() advances the iterator and returns true if the iterator is
/// positioned on a valid 
/// element, and returns false if it is beyond the last element.
/// <p>
/// Adding an element to the %DynamicObject object
/// can cause further calls on the %GetNext(.key,.value,.type) method to have
/// undefined behavior.  It is undefined whether the %GetNext iteration method
/// will visit or skip the added element.
/// <p>
/// The first argument is an output argument .<b><var>key</var></b>
/// which contains the key name string for the element that is returned.
/// <p>
/// The second argument is an output argument .<b><var>value</var></b>
/// which contains the value for the returned element which is usually
/// converted to ObjectScript.
/// <p>
/// The optional third output argument .<b><var>type</var></b>,
/// when it is present, will be modified to contain the 
/// %GetTypeOf(</b><var>key</var></b>) string representing the original
/// type of the returned %DynamicObject element.  
/// When this third argument
/// variable is present it changes some of the conversion rules for converting
/// a %DynamicObject element into an ObjectScript value.
/// <p>
/// The optional fourth output argument .<b><var>keytype</var></b> is igored
/// on a Unicode IRIS instance.  When .<b><var>keytype</var></b> is present on a
/// non-Unicode IRIS instance, it will be modified to contain the type of
/// the .<b><var>key</var></b> argument string.
/// This is almost always "string" but it can contain "json" when
/// the key string contains a UTF-16 character larger than
/// $CHAR(255).  A .<b><var>keytype</var></b> argument value of "json" indicates
/// the .<b><var>key</var></b> argument value is formatted as a JSON
/// format string including a leading " mark, a trailing " mark, and where required,
/// the string will include JSON format character escapes.
/// <p>
/// If the optional third argument is not present then a &lt;MAXNUMBER&gt;
/// error signal may occur if the element value is a JSON number that
/// is too large to be converted to an ObjectScript computational
/// canonical number.
/// <p>
/// If the optional third argument is not present then
/// a &lt;MAXSTRING&gt; error signal may occur if the element value is a
/// JSON string that when converted to ObjectScript string format
/// exceeds the length limit for ObjectScript strings.
/// <p>
/// If the optional third argument is not present on a non-Unicode IRIS
/// instance, then a &lt;WIDE CHAR&gt; error signal may occur
/// if the key name string in .<b><var>key</var></b> or the
/// %DynamicObject element value in .<b><var>value</var></b> are JSON strings
/// containing a UTF-16 character with a value larger than $CHAR(255).
/// <p>
/// If the optional third argument, .<b><var>type</var></b>, is present
/// then these conversion errors will be avoided.
/// <p>
/// If the third parameter variable, .<b><var>type</var></b>, is present 
/// then an element
/// which was originally a JSON format number will always be returned as
/// an ObjectScript string containing the JSON format number.  If the element
/// was originally an ObjectScript number then the returned value will be an
/// ObjectScript canonical computational number.  In either case, the
/// third .<b><var>type</var></b> argument will contain "number".  If the
/// third parameter variable, .<b><var>type</var></b>, is not present then
/// the JSON format number will be converted to an ObjectScript computational
/// number before assignment to the .<b><var>value</var></b> argument variable.
/// <p>
/// If the .<b><var>value</var></b> element in the %DynamicObject was originally
/// an ObjectScript oref then the .<b><var>type</var></b> argument will
/// contain "oref".  If the element was originally a long JSON
/// string that would exceed the supported length for an ObjectScript string then
/// the .<b><var>value</var></b> argument will contain the oref for a
/// readonly ObjectScript <b><class>%Stream.DynamicCharacter</class></b> or
/// <b><class>%Stream.DynamicBinary</class></b> class object
/// containing the string characters but the <b><var>type</var></b>
/// argument will still contain "string" and not "oref".  This conversion from
/// a string to %Stream does not occur if the third .<b><var>type</var></b> argument
/// is not present.
/// <p>
/// On a non-Unicode instance, if a element in the %DynamicObject
/// was originally a normal length JSON string containing
/// UTF-16 characters larger than $CHAR(255), then
/// the .<b><var>value</var></b> will be converted to
/// an ObjectScript string containing a JSON format string including a
/// leading " mark, a trailing " mark, and where required, the string will
/// include JSON format character escapes. Also the <b><var>type</var></b>
/// argument will contain "json" instead of containing "string".  This
/// conversion to JSON format does not occur if the
/// third .<b><var>type</var></b> argument is not present.
/// <p>
/// On a non-Unicode instance, if the key name was originally a JSON string
/// containing a UTF-16 character larger than $CHAR(255), then
/// the .<b><var>key</var></b> will be an ObjectScript string containing a JSON
/// format string including a leading " mark, a trailing " mark, and where
/// required, the string will include JSON format character escapes.   This
/// conversion to JSON format does not occur if the
/// third .<b><var>type</var></b> argument is not present.  If the optional
/// fourth  argument .<b><var>keytype</var></b> is present then it contains
/// "json" to indicate the conversion of the key string to JSON format
/// has occurred.
/// <p>
/// The .<b><var>type</var></b> argument
/// allows you to deterimine whether a %Stream oref returned in
/// the .<b><var>value</var></b>
/// argument was originally an ObjectScript oref or a long JSON string
/// converted to a %Stream object.
/// <p>
/// The .<b><var>type</var></b> can also allow you to determine whether
/// a .<b><var>value</var></b> containing the ObjectScript empty string, "",
/// was originally
/// type "string" or type "null" or whether a .<b><var>value</var></b>
/// containing 0 or 1 was originally type "number" or type "boolean".
/// <p>
/// On a non-Unicode instance, if the element in the %DynamicObject
/// was originally a normal length JSON string containing
/// UTF-16 characters that could not be converted to an 8-bit ObjectScript string
/// then the .<b><var>value</var></b> argument will contain an ObjectScript string
/// containing a JSON format string constant and the .<b><var>type</var></b>
/// argument will be "json" instead of "string" to specify the formatting type of
/// the .<b><var>value</var></b> string.
/// <p>
/// On a non-Unicode instance, if the key string in the %DynamicObject was
/// originally a JSON string containing UTF-16 characters that could not
/// be converted to an 8-bit ObjectScript string then
/// the .<b><var>key</var></b> argument will contain an ObjectScript string
/// containing a JSON format string constant.  And if present, the optional
/// fourth argument .<b><var>keytype</var></b> will contain "json" instead
/// of "string" to indicate the coversion of .<b><var>key</var></b> to JSON format.
/// <p>
/// To call %GetNext(.key,.value,.type) method, pass the .<b><var>key</var></b> and 
/// .<b><var>value</var></b> arguments, and optionally the .<b><var>type</var></b>
/// argument, by reference to receive their return values.
/// To iterate over a <class>%DynamicObject</class> on a Unicode IRIS instance
/// use the following pattern:  <EXAMPLE>
///     while iterator.%GetNext(.key,.value,.type) {
///         // key contains the element key name
///         // and value contains the value
///         // and type contains a %GetTypeOf string
///     }
/// </EXAMPLE>
/// On a non-Unicode IRIS instance you might choose to include the optional
/// fourth .<b><var>keytype</var></b> argument on the
/// iterator.%GetNext(.key,.value,.type,.keytype) method evaluation.
/// 
Method %GetNext(Output key, Output value, Output type...) As %Boolean
{
    set pointer = ..pointer
    if $get(type,0)>0 {
        set value = $zu(210, $$$PVSGetNext2, ..pvaoref, .pointer, .key, .VType)
	if '$$$USEUNICODE {
	    if VType >= $$$PVVALUEUTF16KEY {
		set VType = VType - $$$PVVALUEUTF16KEY
		set:$get(type,0)>1 type(2) = "json"
	    } else { set:$get(type,0)>1 type(2)="string" }
	    if VType = $$$PVVALUEUTF16 && '$IsObject(value) {
		set type(1) = "json"
		goto skiptype
	    }
	}
	set type(1) = $$$JSONConvertType(VType)
skiptype
	if (pointer < 0) {
	    set:$get(type,0)>1 type(2) = ""
	    return 0
	}
	set ..pointer = pointer
	if $IsObject(value) {
	    if VType=$$$PVVALUEUTF16 {
		set value = ##class(%Stream.DynamicCharacter).%New(value)
	    } elseif VType=$$$PVVALUEBYTE {
		set value = ##class(%Stream.DynamicBinary).%New(value)
	    }
	}
	return 1
    } else {
        set ans = $zu(210, 23, ..pvaoref, .pointer, .key, .value)
	set ..pointer = pointer
	return ans
    }
}

}
