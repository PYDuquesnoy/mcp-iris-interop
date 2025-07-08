/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Iterator base class for iterations over Dynamic Entity objects
Class %Iterator.AbstractIterator Extends %Library.Iterator [ Abstract, System = 3 ]
{

Property pvaoref As %Integer [ Internal, Private ];

Property pointer As %Integer [ Internal, Private ];

Method %OnNew(oref As %Library.DynamicAbstractObject) As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set i%pointer = -1
	set ..pvaoref = oref
	return $$$OK
}

/// %GetNext() advances the iterator and returns true if the iterator is
/// positioned on a valid 
/// element, and returns false if it is beyond the last element.
/// Adding or removing an element from the %DynamicObject or %DynamicArray object
/// will cause further calls on the %GetNext(.key,.value,.type) method to have
/// undefined behavior.
/// <p>The first argument is an output argument <b><var>key</var></b>
/// which contains the key value for the element that is returned.
/// <p>The second argument is an output argument <b><var>value</var></b>
/// which contains the value for the returned element converted to ObjectScript.
/// If the optional third argument is not pressent then a &lt;MAXNUMBER&gt;
/// error signal may occur if the element value is a JSON number that
/// is too large to be converted to an ObjectScript computational
/// canonical number.  If the optional third argument is not present then
/// a &lt;MAXSTRING&gt; error signal may occur if the element value is a
/// JSON string that exceeds the string length limit for ObjectScript
/// string values.  If the optional third argument is present
/// then these conversion errors will be avoided.
/// <p>The optional third output argument <b><var>type</var></b>,
/// when it is present, will be modified to contain the 
/// %GetTypeOf(</b><var>key</var></b>) string representing the original
/// type of the returned %DynamicObject or %DynamicArray element.  
/// When this third argument
/// variable is present it changes some of the conversion rules for converting
/// a %DynamicObject or a %DynamicArray element into an ObjectScript value.
/// <p>If the third parameter variable is present then an element
/// which was originally a JSON format number will be returned as an ObjectScript
/// string containing the JSON format number.  If the element was originally
/// an ObjectScript number then the returned value will be an ObjectScript
/// computational canonical number.
/// <p>If the element in the %DynamicObject or %DynamicArray was originally an
/// ObjectScript oref then the <b><var>type</var></b> argument will
/// contain "oref".  If the element was originally a very long JSON
/// string that could not be converted to an ObjectScript string then the
/// <b><var>value</var></b> argument will contain the oref for a
/// readonly ObjectScript <b><class>%Stream.DynamicCharacter</class></b> or
/// <b><class>%Stream.DynamicBinary</class></b> object
/// containing the JSON string characters
/// but the <b><var>type</var></b>
/// argument will still contain "string" and not "oref".
/// <p>The <b><var>type</var></b> value
/// allows you to deterimine whether a %Stream oref returned in the
/// <b><var>value</var></b>
/// argument was originally an ObjectScript oref or a long JSON string.
/// <p>The <b><var>type</var></b> can also allow you to determine whether
/// a <b><var>value</var></b> containing the ObjectScript empty string, "",
/// was originally
/// type "string" or "null" or whether a <b><var>value</var></b> containing 0 or 1
/// was originally type "number" or type "boolean".
/// <p>To call this method, pass the <b><var>key</var></b> and 
/// <b><var>value</var></b> arguments, and optionally the <b><var>type</var></b>
/// argument, by reference to receive their return values.
/// To iterate over a <class>%DynamicObject</class> or
/// a <class>%DynamicArray</class>, use the following pattern: <EXAMPLE>
///     while iterator.%GetNext(.key,.value,.type) {
///         // key contains the element key value
///         // and value contains the value
///         // and type contains a %GetTypeOf string
///     }
/// </EXAMPLE>
/// 
Method %GetNext(Output key, Output value, Output type...) As %Integer [ Abstract ]
{
}

}
