/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%PVA, %sySystem, %syGluedef)

/// <p><b>For information on the API provided by this superclass</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.DynamicAbstractObject">Using Dynamic Entities</a>.</p>
/// 
/// Dynamic Entity base class.
Class %Library.DynamicAbstractObject Extends %Library.AbstractSet [ Abstract, ClassType = dynamic, System = 1 ]
{

/// remove all elements of the current set, throws an exception if this operation is
/// not supported or the set cannot be cleared. 
Method clear() [ CodeMode = call ]
{
..%Clear()
}

/// return true if the <b>key</b> is currently an element of the set, false otherwise. 
Method contains(key As %DataType) As %Boolean [ CodeMode = expression ]
{
..%IsDefined(key)
}

/// return true if the set contains() all <b>key[n]</b> where 0&leq;n&leq; size(<b>array</b>) 
Method containsAll(array As %Library.DynamicArray) As %Boolean
{
	set response = 0
	set it = array.iterator()
	while it.hasNext() {
		set response = response + ..contains(it.next().value)
	}
	return response = array.size()
}

/// get the element identified by <b>key</b> 
Method get(key As %DataType) As %Library.Any [ CodeMode = expression ]
{
..%Get(key)
}

///             return an iterator over the elements of this set 
Method iterator() As %Iterator [ CodeMode = call ]
{
..%GetIterator()
}

/// put the <b>value</b> into the set with the element name (id) of <b>key</b>. 
/// If an element with this <b>key</b> is already present in the set then that element's value is replaced 
/// by <b>value</b> 
/// </p><p>
/// parameters:
/// <ul>
/// <li>key: key to put into the set</li>
/// <li>value: value to put into the set</li>
/// <li>type: type of the value, refer to <method>%GetTypeOf</method> for a list of supported types</li>
/// </ul>
/// </p><p>
/// returns:<ul><li>oref referencing the modified DAO, this may be different from the current oref</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method put(key As %DataType, value As %Library.Any, type As %Library.String) As %Library.DynamicAbstractObject [ CodeMode = call ]
{
..%Set(.key, .value, .type)
}

/// <p>
/// put all {<b>keys[n]</b>, <b>values[n]</b>} elements where 0&leq;n&leq; size(<b>keys</b>) into the DAO 
/// </p><p>
/// parameters:
/// <ul>
/// <li>keys: array of keys to put into the DAO</li>
/// <li>values: array of values to put into the DAO</li>
/// </ul>
/// </p><p>
/// returns:<ul><li>oref referencing the modified DAO</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method putAll(key As %Library.DynamicAbstractObject, value As %Library.DynamicArray) As %Library.DynamicAbstractObject
{
	if '$data(key) { return $this }
	set this = $this
	set it = key.iterator()
	if ('$data(value)) && (key."_isLabeled"()) {
		while it.hasNext() {
			set next = it.next()
			set this = ..put(next.key, next.value)
		}
	} else {
		while it.hasNext() {
			set next = it.next()
			set this = ..put(next.value, value.get(next.key))
		}
	}
	return this
}

/// <p>
/// put the {<b>key</b>, <b>value</b>} element into the set.
/// If contains(<b>key</b>) is false or get(<b>key</b>) is null then put(<b>key</b>,<b>value</b>) 
/// </p><p>
/// parameters:
/// <ul>
/// <li>key: key to put into the set</li>
/// <li>value: value to put into the set</li>
/// </ul>
/// returns:<ul><li>oref referencing the modified set</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method putIfAbsent(key As %DataType, value As %Library.Any) As %Library.AbstractSet
{
	if ($data(key)) && ('..contains(key)) {
		return ..put(.key, .value)
	} else {
		return $this
	}
}

/// <p>
/// put all {<b>keys[n]</b>, <b>values[n]</b>} elements where 0&leq;n&leq; size(<b>keys</b>) 
/// and <b>keys[n]</b> is not already associated with a value in the set. 
/// </p><p>
/// parameters:
/// <ul>
/// <li>keys: array of keys to be put into the set</li>
/// <li>values: array of values to be put into the set</li>
/// </ul>
/// </p><p>
/// returns:<ul><li>oref referencing the modified set</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method putAllIfAbsent(key As %Library.DynamicAbstractObject, value As %Library.DynamicArray) As %Library.DynamicAbstractObject
{
	if '$data(key) { return $this }
	set this = $this
	set it = key.iterator()
	if ('$data(value)) && (key."_isLabeled"()) {
		while it.hasNext() {
			set next = it.next()
			if '(this.contains(next.key)) {
				set this = ..put(next.key, next.value)
			}
		}
	} else {
		while it.hasNext() {
			set next = it.next()
			if '(this.contains(next.value)) {
				set this = ..put(next.value, value.get(next.key))
			}
		}
	}
	return this
}

/// <p>
/// remove the element identified by <b>key</b> from the set 
/// </p><p>
/// parameters:
/// <ul><li>key: key of element to be removed from the set</li></ul>
/// </p><p>
/// returns:<ul><li>the removed element or null if that element doesn't exist</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method remove(key As %DataType) As %Library.Any [ CodeMode = expression ]
{
..%Remove(.key)
}

/// <p>
/// remove all elements identified by <b>keys[n]</b> where 0&leq;n&leq; size(<b>keys</b>) from the set 
/// </p><p>
/// parameters:
/// <ul><li>keys: array of keys to be removed from the set</li></ul>
/// </p><p>
/// returns:<ul><li>array of removed elements (null element if key doesn't exist)</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method removeAll(key As %Library.DynamicArray) As %Library.DynamicArray
{
	set response = []
	set it = key.iterator()
	if .."_isLabeled"() {
		while it.hasNext() {
			set next = it.next()
			if $isobject(next) {
				do response.add(..remove(next.value))
			}
		}
	} else {
		// consume the iterator and remove in descending order
		// we remove from the right to preserve offsets
		// (arrays are dense, removing 1 from [0,1,2] still has a valid 1 offset but it now references what used to be offset 2)
		kill temp
		while it.hasNext() {
			set next = it.next()
			set:'$data(temp(next.value)) temp(next.value) = next.key
		}
		set idx = $order(temp(""),-1)
		while idx '= "" {
			do response.%Set(temp(idx),..remove(idx))
			set idx = $order(temp(idx),-1)
		}
	}
	return response
}

/// remove all of the elements matching the <b>expression</b> 
/// <p>
/// parameters:
/// <ul><li>expression: elements matching <b>expression</b> are to be removed</li></ul>
/// </p><p>
/// returns:<ul><li>array of removed elements (null element if key doesn't exist)</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method removeIf(expression As %RawString) As %Library.DynamicArray [ Abstract ]
{
}

/// replace the key of the element identified by <b>currentKey</b> with <b>newKey</b>
/// </p><p>
/// parameters:
/// <ul>
/// <li>currentkey - current key of the element to be renamed</li>
/// <li>newkey - new key to assign to the element</li>
/// </ul>
/// returns:<ul><li>the current key if the element exists, null otherwise</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method rename(currentkey As %DataType, newkey As %DataType) As %DataType
{
	if .."_isLabeled"() && (..contains(currentkey)) && ('(..contains(newkey))) {
		do ..%Set(newkey, ..%Get(currentkey), ..%GetTypeOf(currentkey))
		do ..remove(currentkey)
		return currentkey
	}
	return ""
}

/// replace the value of the element identified by <b>key</b> with <b>value</b> 
/// </p><p>
/// parameters:
/// <ul>
/// <li>key - key of the element to be replaced</li>
/// <li>value - new value of the element</li>
/// </ul>
/// returns:<ul><li>return the previous value of the element</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method replace(key As %DataType, value As %Library.Any) As %Library.Any
{
	if ..contains(key) {
		set response = ..get(key)
	} else {
		set response = ""
	}
	do ..put(.key,.value)
	return response
}

/// replace all {<b>keys[n]</b>, <b>values[n]</b>} members, return an array containing the replaced values 
/// </p><p>
/// parameters:
/// <ul>
/// <li>keys: array of keys of the elements to be replaced</li>
/// <li>values: array of values of the elements</li>
/// </ul>
/// </p><p>
/// returns:<ul><li>array of previous element values</li></ul>
/// </p><p>
/// throws:<ul><li>exception</li></ul>
/// </p>
Method replaceAll(key As %Library.DynamicArray, value As %Library.DynamicArray) As %Library.DynamicArray
{
	set response = []
	set it = key.iterator()
	while it.hasNext() {
		set next = it.next()
		if $isobject(next) && ..contains(next.value) {
			do response.add(..replace(next.value, value.get(next.key)))
		}
	}
	return response
}

/// return the number of elements in the current set 
Method size() As %Integer [ CodeMode = call ]
{
..%Size()
}

/// The toString() method returns the contents of a set as a string.
/// <p>
Method toString() As %String [ CodeMode = expression ]
{
..%ToJSON()
}

Method %OnClose() As %Status
{
	try {
		do $zutil(210,1)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
    quit $$$OK
}

/// Find out the type of value. 
/// <p><b>Returns</b> One of the following strings are returned.
/// <br> "null"                  - JSON null
/// <br> "boolean"               - Either "true" or "false"
/// <br> "number"                - Any numeric value
/// <br> "oref"                  - An %ObjectHandle (an ObjectScript oref)
/// <br> "object"                - A nested object
/// <br> "array"                 - A nested array 
/// <br> "string"                - Normal text string
/// <br> "unassigned"            - The value is unassigned
/// 
Method %GetTypeOf(key As %DataType) As %String
{
	return $$$JSONGetTypeOf($this,key)
}

/// Find the size of an %DynamicArray or a %DynamicObject.
/// <p>
/// <b>Returns</b> An integer showing the size of the array or object. In the
/// case of an array, the size includes unassigned entries within the array.  In
/// the case of an object, the size only includes elements that have assigned
/// values.
Method %Size() As %Integer
{
    try {
	return $zu(210,40)
    } catch { do $$$APPERROR1($$$LASTERROR) }
}

/// Given a JSON source, parse the source and return an object of type
/// <class>%DynamicAbstractObject</class>. If an error occurs during parsing,
/// an exception will be thrown.
/// <p><b>str</b> The input can be from a number of sources
/// <p>
///    (1) A string value containing the source.
/// <br>
///    (2) A stream object to read the source from.
/// <p>
/// <b>Returns</b> An object of type %DynamicAbstractObject containing the
/// parsed JSON. 
/// <p>
/// <b>NOTE:</b> RFC 7159 specifies that the default encoding for JSON values 
/// uses UTF-8.  This implies
/// that for streams not containing 16-bit Unicode it <i>may</i>
/// be necessary to explicitly convert individual character values via a call to
/// $ZCONVERT (e.g. $zcvt(value,"I","UTF8") ) or entire streams by setting
/// the TranslateTable attribute of the stream to "UTF8".
/// <EXAMPLE>
///  
///    set filename = "c:/iscsrc/json/greg4.json"
///    set stream = ##class(%Stream.FileCharacter).%New()
///    set sc = stream.LinkToFile(filename)
///    if ('sc) { w "Error on linking file "_filename,!   q }
///    try {
///        set obj = ##class(%DynamicAbstractObject).%FromJSON(stream)
///    } catch ex {
///        w "Error. Unable to parse file "_filename,!
///        w "Error type   "_ex.Name,!
///        w "Error code   "_ex.Code,!
///        w "Error location "_ex.Location,!
///        set obj = ""
///    }
///    q obj
/// </EXAMPLE>
/// <p>
/// <EXAMPLE>
///    set src = "{""name"" : ""greg"", ""weight"" : 220 }"
///    set obj = ##class(%DynamicAbstractObject).%FromJSON(src)
/// </EXAMPLE>
/// <p>
/// An alternative in the catch block, to see formatted exception information, is
/// to do $SYSTEM.OBJ.DisplayError(%objlasterror).
ClassMethod %FromJSON(str As %RawString) As %DynamicAbstractObject
{
	// If the source is a stream, rewind to the start
	if ($isobject($g(str))) {
	    try {
		do str.Rewind()
	    } catch {
	    }
	    if (str.AtEnd) && (str.Size=0) {
		throw ##class(%Exception.General).%New("Unable to read any data from stream")
	    }
	}
	set genvar1="",genvar2=""
	merge objerr=%objlasterror kill %objlasterror
	try { 
	    set ans = $zu(210,0,.str,0,.keymap,.genvar1,.genvar2)
	} catch {
	    do $$$APPERROR1($$$LASTERROR)
	}
	if (ans = 0) {
	    // Finished okay
		kill %objlasterror merge %objlasterror=objerr
	    return genvar1
	}
	if $D(%objlasterror) {
		set objerr=%objlasterror
		set inner=##class(%Exception.General).%New($lg(genvar2,4),$lg(genvar2,1),"Line "_$lg(genvar2,5)_" Offset "_$lg(genvar2,7)).AsStatus()
		set status=$$EmbedStatus^%apiOBJ(objerr,inner)
		throw ##class(%Exception.StatusException).CreateFromStatus(status)
	}
	// An error occurred
	throw ##class(%Exception.General).%New($lg(genvar2,4),$lg(genvar2,1),"Line "_$lg(genvar2,5)_" Offset "_$lg(genvar2,7))
}

/// Given a filename, parse the contents and return an object of type
/// <class>%DynamicAbstractObject</class>. If an error occurs during parsing,
/// an exception will be thrown. See the example in <method>%FromJSON</method>
/// for how to handle an exception.
/// <p><b>filename</b> 
/// A file URI where the JSON source can be read. By default, the file must be
/// encoded as UTF8.
/// <p><b>TranslateTable</b> An optional parameter specifying the character encoding
/// used in the JSON source file.  If the parameter is missing, the file will use
/// the "UTF8" encoding.  See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>
/// for other available Translation Tables.
/// <p><b>Returns</b> An object of type %DynamicAbstractObject containing the parsed JSON. 
ClassMethod %FromJSONFile(filename As %RawString, TranslateTable As %String = "UTF8") As %DynamicAbstractObject
{
	set stream = ##class(%Stream.FileCharacter).%New()
	set stream.TranslateTable = TranslateTable
	if $$$ISERR(stream.LinkToFile(filename)) {
		throw ##class(%Exception.General).%New("%FromJSONFile - unable to link file "_filename)
	}
	do stream.Rewind()
	set genvar1="",genvar2=""
	merge objerr=%objlasterror kill %objlasterror
	try { 
		set ans = $zu(210,0,.stream,0,.keymap ,.genvar1,.genvar2)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	if (ans = 0) {
		// Finished okay
		kill %objlasterror merge %objlasterror=objerr
		return genvar1
	}
	if $D(%objlasterror) {
		set objerr=%objlasterror
		set inner=##class(%Exception.General).%New($lg(genvar2,4),$lg(genvar2,1),"Line "_$lg(genvar2,5)_" Offset "_$lg(genvar2,7)).AsStatus()
		set status=$$EmbedStatus^%apiOBJ(objerr,inner)
		throw ##class(%Exception.StatusException).CreateFromStatus(status)
	}
	// An error occurred
	throw ##class(%Exception.General).%New($lg(genvar2,4),$lg(genvar2,1),"Line "_$lg(genvar2,5)_" Offset "_$lg(genvar2,7))
}

/// INTERNAL ONLY!
/// <br><p>
/// The %FromJSONStats(...) method is for internal use only.  The
/// actions taken by this method may change in the future as additional
/// capabilities are added to %DynamicAbstractObject class objects.
/// 
ClassMethod %FromJSONStats(str As %RawString, stats As %RawString) As %DynamicAbstractObject [ Internal ]
{
	// If the source is a stream, rewind to the start
	if ($isobject($g(str))) {
	    try {
		do str.Rewind()
	    } catch { }
	    if (str.AtEnd) && (str.Size=0) {
		throw ##class(%Exception.General).%New("Unable to read any data from stream")
	    }
	}
	set genvar1="",genvar2=""
	try { 
	    set ans = $zu(210,0,.str,16,.keymap,.genvar1,.genvar2)
	} catch {
	    do $$$APPERROR1($$$LASTERROR)
	}
	if ans {
	    // Try this as a file stream if str is not an object and the
	    //leading character doesn't indicate a JSON array or object
	    if ('$isObject(str)) && ('$Find("{[",$Extract($zstrip(str,"<W")))) {
		set stream = ##class(%Stream.FileCharacter).%New()
		set stream.TranslateTable = "UTF8"
		set sc = stream.LinkToFile(str)
		throw:'sc ##class(%Exception.General).%New("%FromJSON - unable to link file "_str)
		do stream.Rewind()
		try { 
		    set ans = $zu(210,0,.stream,16,.keymap,.genvar1,.genvar2)
		} catch {
		    do $$$APPERROR1($$$LASTERROR)
		}
	    }
	}
	if (ans = 0) {
	    // Finished okay
	    set stats = genvar2
	    return genvar1
	}
	// An error occurred
	set stats = genvar2
	throw ##class(%Exception.General).%New($lg(genvar2,4),$lg(genvar2,1),"Line "_$lg(genvar2,5)_" Offset "_$lg(genvar2,7))
}

/// Convert a %DynamicAbstractObject into a JSON string.
/// <p> 
/// <b>outstrm</b> is optional. There are a number of possibilities: 
/// <br>(1) Parameter <b>outstrm</b> is not defined and the method is called via
/// 'DO'. In this case the JSON string is written to the current output device. 
/// <br>(2) Parameter <b>outstrm</b> is not defined and the method is called as an
/// expression. In this case the JSON string becomes the value of the expression. 
/// <br>(3) Parameter <b>outstrm</b> is defined. If it is %Stream object then the
/// JSON string will be written to the stream. If <b>outstrm</b> is
/// present but not an object then it is presumed to be a fully qualified
/// file specification. In that case, a <class>%Stream.FileCharacter</class>
/// stream is created, linked to that file 
/// and the JSON string is written to that stream. On completion, this
/// stream is saved. The full path to the file must be defined. If
/// <b>outstrm</b> is an object but is not 
/// an instance of %Stream.Object then an exception will be thrown. 
/// <p>
/// <b>NOTE:</b> RFC 7159 specifies that the default encoding for JSON values 
/// uses UTF-8.  When writing a stream containing 8-bit characters this implies
/// that it <i>may</i>
/// be necessary to explicitly convert individual values via a call to
/// $ZCONVERT (e.g. $zcvt(value,"O","UTF8") ) or entire streams by setting
/// the TranslateTable attribute of the stream to "UTF8"
/// <EXAMPLE>
/// set obj = {"title" : "MR" , "lastname" : "JONES"}
/// set obj.firstname = "JIMMY"
/// do obj.%ToJSON()
///     {"title":"MR","lastname":"JONES","firstname":"JIMMY"}
/// set source = obj.%ToJSON()
/// write source
///     {"title":"MR","lastname":"JONES","firstname":"JIMMY"}
/// </EXAMPLE>
/// 
Method %ToJSON(outstrm As %Stream.Object) As %String
{
	if $D(outstrm) {
	    if $isobject(outstrm) {
		if '(outstrm.%IsA("%Stream.Object")) {
		    throw ##class(%Exception.General).%New("%ToJSON - argument passed is not an instance of %Stream.Object")
		}
		try {
		    set ans = $zu(210,27,outstrm)
		} catch {
		    do $$$APPERROR1($$$LASTERROR)
		}
	    } elseif outstrm '= "" {
		// Write to a file stream.
		set stream = ##class(%Stream.FileCharacter).%New()
		set stream.TranslateTable = "UTF8"
		set sc = stream.LinkToFile(outstrm)
		throw:'sc ##class(%Exception.General).%New("%ToJSON - unable to link file "_outstrm)
		do stream.Rewind()
		try {
		    set ans = $zu(210,27,stream)
		    $$$THROWONERROR(sc,stream.%Save())
		} catch {
		    do $$$APPERROR1($$$LASTERROR)
		}
	    } else {
		#; 'outstrm' must be an object
		do $$$APPERROR1($$$ERVALUE)
	    }
	} else {
	    try { 
		set ans = $zu(210,27,$QUIT)
	    } catch {
		do $$$APPERROR1($$$LASTERROR)
	    }
	}
	return ans
}

/// This method is for INTERNAL USE only.  It's specifications will change in 
/// the future.
/// <p>
/// Convert the Packed Vector Array binary representation (PVA
/// representation) stored in a global array into a tree of class objects
/// defined the <class>%DynamicAbstractObject</class>
/// subclasses.  The PVA binary representation can be created by executing:
/// <p style="margin-left:5%;"><b>DO DynObj.%ToPVA(global)</b></p>
/// The conversion can be done by evaluating:
/// <p style="margin-left:5%;"><b>SET dao=##class(%DynamicAbstractObject).%FromPVA(global,keymap,flags)</b></p>
/// which sets the local variable <b>dao</b> to be a
/// reference of the root of
/// a tree of <class>%DynamicAbstractObject</class>-s described in
/// the global array <b>global</b>.
/// <p> 
/// <b>global</b> is the $NAME representation of the root of a global subtree.
/// <p>
/// <b>keymap</b> argument is optional.  If present, it is 
/// the <class>%DynamicKeyMap</class> to replace the key maps
/// currently used by the tree of <class>%DynamicAbstractObject</class> objects
/// rooted at <b>dao</b>.
/// <p>
/// <b>flags</b> is optional.  When present it is a bit encoded integer of flag
/// values.
/// <p>    The 0x01 bit clears the key map value used by any
/// <class>%DynamicArray</class> in the tree of
/// <class>%DynamicAbstractObject</class>-s.
/// <p>    The 0x02 bit clears the key map value used by any
/// <class>%DynamicObject</class>
/// in the tree of <class>%DynamicAbstractObject</class>-s, <b>BUT</b> the key
/// index arrays of the <class>%DynamicObject</class> are modified to conform to
/// the new <b>keymap</b> key map ordering.
/// <p>
/// If you execute
/// <p style="margin-left:5%;"><b>SET dao=##class(%DynamicAbstractObject).%FromPVA("^Docs(""alpha"",""book1"")")</b></p>
/// or execute
/// <p style="margin-left:5%;"><b>SET dao=##class(%DynamicAbstractObject).%FromPVA($NAME(^Docs("alpha","book1"))</b></p>
/// then the binary PVA will be extracted from the data under the global
/// <b>^Docs(alpha,book1)</b>.
/// <p>
/// NOTE:  The execution of
/// <p style="margin-left:5%;"><b>DO dao.%FromPVA(global,keymap,flags)</b></p>
/// <p>is the equivalent of executing:
/// <p style="margin-left:5%;"><b>DO dao.%FromPVA(global),dao.%SetKeyMapRecursive(keymap,flags)</b></p>
/// 
ClassMethod %FromPVA(global As %String, keymap As %DynamicKeyMap = "", flags As %Integer = 0) As %DynamicAbstractObject [ Internal ]
{
	return $ZU(210,34,global,keymap,flags)
}

/// This method is for INTERNAL USE only.  It's specifications will change in 
/// the future.
/// <p>
/// Convert an object of the <class>%DynamicAbstractObject</class>
/// subclass into the binary
/// Packed Vector Array representation which will be stored into global tree
/// by executing <b>DO DynObj.%ToPVA(global,keymap,flags)</b>.
/// <p><b>Parameters:</b></p>
/// <ul> 
/// <li><b>global:</b> the $NAME representation of the root of a global subtree.
/// <p>
/// <li><b>keymap:</b> the <class>%DynamicKeyMap</class> to replace the key map
/// currently used by the <class>%DynamicAbstractObject</class>.
/// <p>
/// <li><b>flags:</b> optional.  When present it is a bit encoded integer of flag
/// values.
/// <p>    The 0x01 bit clears the key map value used by any
/// <class>%DynamicArray</class> in the tree of nested
/// <class>%DynamicAbstractObject</class>-s.
/// <p>    The 0x02 bit clears the key map value used by any
/// <class>%DynamicObject</class>
/// in the tree of <class>%DynamicAbstractObject</class>-s, <b>BUT</b> the key
/// index arrays of the <class>%DynamicObject</class> are modified to conform to
/// the new <b>keymap</b> key map ordering.
/// </ul>
/// <p>
/// If you execute
/// <p style="margin-left:5%;"><b>DO DynObj.%ToPVA("^Docs(""alpha"",""book1"")")</b></p>
/// <p>or execute</p>
/// <p style="margin-left:5%;"><b>DO DynObj.%ToPVA($NAME(^Docs("alpha","book1"))</b></p>
/// <p>then binary data will be created under <b>^Docs(alpha,book1)</b>.</p>
/// <p>
/// The preexisting data at <b>^Docs(alpha,book1)</b> will be KILL-ed.
/// <p>The newly created data
/// will look like: <b>^Docs(alpha,book1,0,0),...,^Docs(alpha,book1,0,N0-1)</b>
/// where the binary data is broken in <b>N0</b> chunks of binary strings.  The
/// binary strings always contain 8-bit binary bytes, even on Unicode
/// instances of IRIS.  Complicated <class>%DynamicAbstractObject</class>
/// objects may
/// also generate additional subtrees of the form <b>^Docs(alpha,book1,1,0),
/// ..., ^Docs(alpha,book1,1,N1-1)</b> where additional binary data is broken
/// into <b>N1</b> chunks of binary strings.  And <method>%ToPVA</method>
/// may need to generate
/// additional chunks, like <b>^Docs(alpha,book1,i,j)</b>, when necessary.
/// These additional chunks are created to simplify generation and
/// retrieval of the binary Packed Vector Array data.
/// <p>
/// NOTE:  The execution of
/// <p style="margin-left:5%;"><b>DO dao.%ToPVA(global,keymap,flags)</b></p>
/// <p>is the equivalent of executing:</p>
/// <p style="margin-left:5%;"><b>DO dao.%SetKeyMapRecursive(keymap,flags),dao.%ToPVA(global)</b></p>
/// <p>If during execution of <b>DO dao.%ToPVA(global,keymap)</b>
/// an error signal occurs
/// (like &lt;STORE&gt; if the execution runs out of resources,
/// or &lt;INVALID CLASS&gt; if
/// an unsupported oref class value is encountered) then the recusive walk of
/// nested objects and arrays under <b>dao</b> terminates.  The dynamic
/// objects and nested arrays not yet encountered in the recursive walk
/// will not be associated with the new <b>keymap</b>.  You may need to execute
/// <b>dao.%SetKeyMapRecursive(keymap)</b> to complete the assignments the the new
/// <b>keymap</b> to the all the objects and arrays nested under <b>dao</b>.
/// 
Method %ToPVA(global As %String, keymap As %DynamicKeyMap = "", flags As %Integer = 0) As %Status [ Internal ]
{
	DO $ZU(210,32,global,keymap,flags)
	return $$$OK
}

/// The parameter 'value' must be a %Stream.  The contents of 'value' will be
/// placed in a <class>%DynamicString</class>, <class>%DynamicBinary</class>
/// or <class>%DynamicBase64</class> object.
/// <p>
/// <b>Returns</b> The generated <class>%DynamicString</class>,
/// <class>%DynamicBinary</class> or <class>%DynamicBase64</class> object.
/// 
Method ConvertStreamToValue(value) As %DynamicAbstractObject [ Internal, Private ]
{
    Try {
	If value.%IsA("%Stream.DynamicCharacter") { Return value.DAOData }
	// <ILLEGAL VALUE> if not a %Stream
	If 'value.%IsA("%Stream.Object") do $$$APPERROR1($$$ERVALUE)
	Set size=value.Size
	// We do not support %Stream not implementing 'Size' property
	If size=-1 do $$$APPERROR1($$$ERUNIMP)
	// Must use PV_BufChar since we do not yet know if %Stream.xxx
	// contains any Unicode.  Maybe we should read it first
	// then rewind when we know the answer.
	Set buf=$ZU(210,$$$PVSstringBuf,size,$$$PVTYPECHAR)
	Do value.Rewind()
	While 'value.AtEnd { Do $ZU(210,$$$PVSWriteBuf,buf,value.Read()) }
	Return $ZU(210,$$$PVSCompressBuf,buf)
    } Catch { do $$$APPERROR1($$$LASTERROR) }
}

Method %GetObjectType() As %Integer [ Internal ]
{
	#; Get the type of the top object
	try {
	    set ans = $zu(210,6) 
	} catch { do $$$APPERROR1($$$LASTERROR) }
	return ans
}

/// <p>
/// Performs an iteration over all the values in a %DynamicAbstractObject
/// subclass.  Adding or removing an element of the %DynamicAbstractObject subclass
/// will cause further calls on the %GetNext(.key,.value,.type) method to have
/// undefined behavior.
/// <p>
/// In the example below, we will output all values contained in a
/// <class>%DynamicArray</class> or a <class>%DynamicObject</class>.
/// <EXAMPLE>
///    set iter = AbstractObject.%GetIterator()
///    while iter.%GetNext(.key, .value, .type ) {
///       write "key = "_key_", value = "_value_", type = "_type,!
///    }
/// </EXAMPLE>
/// See the descriptions of the <method class="%Iterator.AbstractIterator">%GetNext</method> in the <class>%Iterator.Array</class> and <class>%Iterator.Object</class> classes for more details.
Method %GetIterator() As %Iterator.AbstractIterator [ Abstract ]
{
}

/// INTERNAL USE ONLY.
/// <br><p>
/// The ToZWrite() method is for internal use only.  It
/// provides output for the ZWRITE command.  It returns the contents of a
/// %DynamicAbstractObject as a %String using combined JSON/%String
/// syntax.
/// <p> 
/// <EXAMPLE>
/// set obj = {"NaNvalue" : ($DOUBLE("NAN")), "Infinity":($DOUBLE("Inf"))}
/// write obj.ToZWrite()
/// </EXAMPLE>
/// 
Method ToZWrite() As %String [ Internal ]
{
	return $zu(210,27,-1)
}

/// INTERNAL ONLY!
/// <br><p>
/// The <b>%SetKeyMap(keymap)</b> method is for internal use only.  The
/// actions taken by this method may change in the future as additional
/// capabilities are added to <class>%DynamicAbstractObject</class> class objects.
/// <p>
/// The statement <b>SET count=dao.%SetKeyMap(keymap)</b> will attach the
/// <class>%DynamicKeyMap</class> <b>keymap</b> to the
/// <class>%DynamicAbstractObject</class> <b>dao</b>, replacing
/// the key map that was previously attached
/// to <b>dao</b>.  If <b>dao</b> is a
/// <class>%DynamicObject</class> then its internal key index array will be
/// modified to use the <b>keymap</b>
/// <class>%DynamicKeyMap</class>.  If necessary,
/// additional key names will be added
/// to the <b>keymap</b>.  The <b>count</b> value returned by the
/// <b>%SetKeyMap(keymap)</b>
/// call is a count of the number of the key name strings added to the
/// <b>keymap</b>.  If the <b>keymap</b> key map is not modified by
/// <method>%SetKeyMap</method>
/// then the value zero is returned.
/// <p>
/// <b>keymap</b> is the <class>%DynamicKeyMap</class> to replace the key map
/// currently used by the <class>%DynamicAbstractObject</class>.
/// <p>
/// <b>flags</b> is optional.  When present it is a bit encoded integer of flag
/// values.
/// <p>    The 0x01 bit clears the key map value used by a
/// <class>%DynamicArray</class>.
/// <p>    The 0x02 bit clears the key map value used by a
/// <class>%DynamicObject</class> <b>BUT</b> the key
/// index arrays of the <class>%DynamicObject<class> are modified to conform
/// to the new <b>keymap</b> key map ordering.
/// <p>
/// <b>Returns</b> The count of the number of key name strings added to the
/// <b>keymap</b>.
/// 
Method %SetKeyMap(keymap As %DynamicKeyMap, flags As %Integer = 0) As %Integer [ Internal ]
{
    try {
	return $zu(210,30,keymap,flags)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ""
}

/// INTERNAL ONLY!
/// <br><p>
/// The <b>%SetKeyMapRecursive(keymap)</b> method is for internal use only.  The
/// actions taken by this method may change in the future as additional
/// capabilities are added to <class>%DynamicAbstractObject</class> class objects.
/// <p>
/// The statement <b>SET count=dao.%SetKeyMapRecursive(keymap)</b>
/// will attach the <class>%DynamicKeyMap</class> <b>keymap</b> to the
/// <class>%DynamicAbstractObject</class> <b>dao</b>
/// and to all decendant <class>%DynamicAbstractObject</class>-s in the tree
/// rooted at <b>dao</b>.
/// Every <class>%DynamicObject</class> in the tree rooted at <b>dao</b>
/// will have its internal key index array modified to use
/// the <b>keymap</b> <class>%DynamicKeyMap</class>.  If necessary, additional
/// key names will be added
/// to the <b>keymap</b>.  The <b>count</b> value returned by the
/// <b>%SetKeyMap(keymap)</b> method
/// call is a count of the number of the key name strings added to the
/// <b>keymap</b>.  If the <b>keymap</b> is not modified by
/// <b>%SetKeyMapRecursive</b> then the value zero is returned.
/// <p>
/// <b>keymap</b> is the <class>%DynamicKeyMap</class> to replace the key maps
/// currently used by the <class>%DynamicAbstractObject</class>-s in the
/// tree rooted at <b>dao</b>.
/// <p>
/// <b>flags</b> is optional.  When present it is a bit encoded integer of flag
/// values.
/// <p>    The 0x01 bit clears the key map value used by any
/// <class>%DynamicArray</class> in the tree of
/// <class>%DynamicAbstractObject</class>-s.
/// <p>    The 0x02 bit clears the key map value used by any
/// <class>%DynamicObject</class>
/// in the tree of <class>%DynamicAbstractObject</class>-s, <b>BUT</b> the key
/// index arrays of the <class>%DynamicObject</class> are modified to conform to
/// the new <b>keymap</b> key map ordering.
/// <p>
/// <b>Returns</b> The count of the number of key name strings added to the
/// <b>keymap</b>.
/// 
Method %SetKeyMapRecursive(keymap As %DynamicKeyMap, flags As %Integer = 0) As %Integer [ Internal ]
{
    try {
	return $zu(210,48,keymap,flags)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    q ""
}

/// INTERNAL ONLY!
/// <br><p>
/// The <method>%GetKeyMap</method> method is for internal use only.
/// It returns a reference to the <class>%DynamicKeyMap</class> associated with
/// a <class>%DynamicAbstractObject</class>.
/// The formats and semantics of a key map are known only to the routines
/// and methods that implement the <class>%DynamicAbstractObject</class> class
/// and its subclasses.  These formats, semantics, routines and methods may change
/// in the future as additional capabilities are added to
/// <class>%DynamicAbstractObject</class> class objects.
/// <p>
/// The <method>%GetKeyMap</method> method returns a reference to the
/// <class>%DynamicKeyMap</class>
/// used by the <class>%DynamicArray</class> or <class>%DynamicObject</class>.
/// Adding additional key names to this key map will also affect the key map
/// currently attached to the <class>%DynamicAbstractObject</class>, and vice
/// versa.  If a <class>%DynamicArray</class> or <class>%DynamicObject</class>
/// has no associated key map then <method>%GetKeyMap</method> returns
/// the empty string.
/// <p>
/// Most <class>%DynamicObject</class> class objects have a KeyMap attached.  When
/// a <class>%DynamicObject</class> is created by the <method>%FromJSON</method>
/// method, and when there are other <class>%DynamicObject</class>-s created in
/// the same <method>%FromJSON</method> call then all those
/// <class>%DynamicObject</class>-s will share the same KeyMap.
/// A <class>%DynamicArray</class> created by the <method>%FromJSON</method> method
/// may also have a shared KeyMap attached if there was a
/// <class>%DynamicObject</class> created in the same <class>%FromJSON</class>
/// method call.
/// 
Method %GetKeyMap() As %DynamicKeyMap [ Internal ]
{
    try {
	set ans = $zu(210,31)
    } catch { do $$$APPERROR1($$$LASTERROR) }
    return ans
}

Method %GetSwizzleObject(force As %Integer = 0, ByRef oid As %ObjectIdentity) As %Status [ ServerOnly = 1 ]
{
	set id = ..%GetSerial(force)
	if id = "" {
	    set oid = $$$NULLOID
	} else {
	    set class = $classname()
	    set class = $$$DenormalizeClassname(class)
	    set oid = $$$oidCompose(id,class)
	}
	return $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
..%ToJSON()
}

ClassMethod %SetSerial(val As %String) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
..%FromJSON(val)
}

Method %SetDocumentMetadata(documentID As %RawString, documentVersion As %Integer, collectionName As %String(MAXLEN=""), localID As %Integer(MINVALUE=1) = "")
{
	try {
		do $zu(210,25,collectionName,"$c")
		do $zu(210,25,documentID,"$i")
		do $zu(210,25,documentVersion,"$v")
		do $zu(210,25,localID,"$l")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %GetDocumentCollection() As %RawString
{

    try {
	set ans = $zu(210,26,"$c")
    } catch { do $$$APPERROR1($$$LASTERROR) }
    return ans
}

Method getDocumentCollection() As %RawString [ CodeMode = call ]
{
..%GetDocumentCollection()
}

Method getDocumentId() As %RawString [ CodeMode = call ]
{
..%GetDocumentID()
}

Method toJson(outstrm As %Stream.Object) As %RawString [ CodeMode = call ]
{
..%ToJSON(.outstrm)
}

Method getDocumentVersion() As %Integer [ CodeMode = call ]
{
..%GetDocumentVersion()
}

Method %GetDocumentID() As %RawString
{
    try {
		set ans = $zu(210,26,"$i")
    } catch { do $$$APPERROR1($$$LASTERROR) }
    return ans
}

Method %GetDocumentLID() As %RawString [ Internal ]
{
	try {
		set ans = $zu(210,26,"$l")
	} catch { do $$$APPERROR1($$$LASTERROR) }
	return ans
}

Method %GetDocumentVersion() As %Integer
{
	try {
		set ans = $zu(210,26,"$v")
	} catch { do $$$APPERROR1($$$LASTERROR) }
	return ans
}

Method %GetDocumentMetadata(Output documentID As %RawString, Output documentVersion As %Integer, Output collectionName As %String(MAXLEN=""), Output localID As %Integer(MINVALUE=1) = "") [ Internal ]
{
	try {
		set collectionName = $zu(210,26,"$c")
		set documentID = $zu(210,26,"$i")
		set documentVersion = $zu(210,26,"$v")
		set localID = $zu(210,26,"$l")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %SetDocumentCollection(collection As %RawString) [ Internal ]
{
	try {
		do $zu(210,25,collection,"$c")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %SetDocumentID(documentID As %RawString) [ Internal ]
{
	try {
		do $zu(210,25,documentID,"$i")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %SetDocumentLID(localID As %RawString) [ Internal ]
{
	try {
		do $zu(210,25,localID,"$l")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %SetDocumentVersion(version As %Integer) [ Internal ]
{
	try {
		do $zu(210,25,version,"$v")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
}

Method %SetMetadata(key As %DataType, value As %RawString) [ Internal ]
{
	try {
		set ans = $zu(210,25,value,key)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

Method %GetMetadata(key As %DataType) As %RawString [ Internal ]
{
	try {
		set ans = $zu(210,26,key)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

/// INTERNAL ONLY!
/// <br>
/// <p>
/// $toPVA() serializes an AbstractObject instance into a packed vector array. The key names can be optionally included, excluded or only the key names
/// included (no data). The form of the packed vector array is not public and the only way to access data serialized as PVA is to extract it from the
/// PVA using $<method>fromPVA</method>.
/// </p>
/// <p>
/// This method accepts two arguments. The first is the name of the reference where the PVA will be placed. That reference can be
/// a local variable expression or a global variable expression. Typically, this is produced using the $Name function.
/// <br>
/// <pre>
/// USER>set obj = {"name":"test PVA","stuff":"misc"}
/// USER>set id = 6 do obj.$toPVA($Name(mypva(id)))
/// USER>zw mypva
/// mypva(6,1)=<data is encoded as a byte array>
/// </pre>
/// <p>
/// The above example is using a local variable but it could be a global reference, simply place the '^' in front of the variable name.
/// </p>
/// <p>
/// The encoding of the data is proprietary and direct access is not supported.
/// </p>
/// <p>
/// The second argument, <b>options</b>, is used to control whether or not the key names are included in the packed vector array.
/// <p>    0x00 - do not include the key names, only include data </p>
/// <p>    0x01 - include the key names and the data </p>
/// <p>    0x02 - means this is the key map being dumped.</p>
/// <p>
/// If the key name map is not included in the packed vector array (options = 1) then the key names cannot be recovered when extracting the
/// contents of the packed vector array. Normally the key name map would be supplied as a separate argument passed to $<method>fromPVA</method> in that case.
/// </p>
/// <p>
/// This function returns the length of the packed vector.
/// </p>
Method toPVA(gloref, options = 0) As %Integer [ Internal ]
{
	set @gloref = ..%ToJSON()
	return $length(@gloref)
	/*
    set chunksize = 910286
    set firstsubs = 1
    if (options '= 0) {
		if ($zboolean(options,2,1) > 0) {
			#; This IS the key name map to dump
			set firstsubs = 0
		}
	}
	kill:(firstsubs=1) @gloref
	#;
	#; Create the serialised form from the in-memory model.
	#;
	try {
		set (remaining , size)  = $zutil(210,32,chunksize)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	#;
	#; Write the newly created serialised string to a global in chunks.
	#;
	set offset = 0, chunk = 0
	while (remaining > 0) {
		if (offset = 0) {
			try {
				set @gloref@(firstsubs) = $zutil(210,33,offset,chunksize)
			} catch {
				do $$$APPERROR1($$$LASTERROR)
			}
		} else {
			try {
				set @gloref@(firstsubs,chunk) = $zutil(210,33,offset,chunksize)
			} catch {
				do $$$APPERROR1($$$LASTERROR)
			}
			set chunk = chunk + 1
		}
		set offset = offset + chunksize
		set remaining = remaining - chunksize
	}
	#;
	#; Kill the serialised form in the object.
	#;
	try {
		do $zutil(210,36,$this)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	#;
	#; Dump the key name map
	#;
	if (options '= 0) {
		if ($zboolean(options,1,1) > 0) {
			#; This means to dump the keyname map
			set keynamemap = ..%GetKeyNameMap()
			if ($isobject(keynamemap)) {
				do keynamemap.toPVA(gloref , 2 )
			}
		}
	}
	#;
	return size
	*/
}

/// INTERNAL ONLY!
/// <br>
/// <p>
/// fromPVA() extracts the contents of a packed vector array (PVA) into an instance AbstractObject. The form of the packed vector array is
/// not public and the only way to construct a PVA is to invoke $<method>toPVA</method>.
/// This method accepts two arguments. The first is the name of the variable where the PVA is located. That reference can be
/// a local variable expression or a global variable expression. Typically, this is produced using the $Name function.
/// The optional second argument is the key name map. If the packed vector array contained in the reference passed as the first argument
/// includes the key name map then the key name map does not need to be passed as a separate argument. If the packed vector array does not
/// contain the key name map then it must be supplied. The key name map is expected to be an instance of
/// <class>%Library.Array</class>. The key name map can be extracted from a packed vector array or it can be retrieved by invoking
/// $<method>getKeyNameMap</method>. To serialize the key name map as a packed vector array, refer to $<method>toPVA</method>.
/// <br>
/// <pre>
/// USER>k
/// USER>set obj = {"name":"test PVA","stuff":"misc"}
/// USER>set id = 6 do obj.$toPVA($Name(mypva(id)),$zh("1"))
/// USER>set obj2 = ##class(%Library.AbstractObject).$fromPVA($Name(mypva(id)))
/// USER>write obj2.$toJSON()
/// {"name":"test PVA","stuff":"misc"}
/// </pre>
/// <br>
/// <p>
/// The encoding of the data is proprietary and direct access is not supported.
/// </p>
/// <p>
/// The above example is using a local variable but it could be a global reference, simply place the '^' in front of the variable name.
/// </p>
ClassMethod fromPVA(gloref As %RawString, keymap As %DynamicKeyMap = "") As %Library.DynamicAbstractObject [ Internal ]
{
	return ..%FromJSON(@gloref)
	/*
	#;
	#; If there isn't a key name map supplied, see if we can
	#; restore a map from when it was saved.
	#;
	if ('$data(keymap)) || ('$isobject(keymap)) {
		set keymap = $$getdata(gloref , 0 )
		if ($isobject(keymap)) {
			#; Transform the serial to the array
			try {
				set rc = $zutil(210,34,keymap)
				throw:rc ##class(%Exception.General).%New("fromPVA() Unable to restore from serial data key map")
				#; Kill the serialised keymap
				do $zutil(210,36,keymap)
			} catch { do $$$APPERROR1($$$LASTERROR) }
		}
	}
	#;
	#; Read in the actual data.
	#;
	set rtn = $$getdata(gloref , 1 )
	throw:('$isobject(rtn)) ##class(%Exception.General).%New("fromPVA() unable to read data from "_gloref)
	#;
	#; Set the key name map for this object.
	#;
	do:$isobject(keymap) rtn.%SetKeyNameMap(keymap)
	#;
	#; Now do the transformation from serialised form to in-memory form.
	#;
	try {
		set rc= $zutil(210,34,rtn)
		throw:rc ##class(%Exception.General).%New("fromPVA() Unable to restore from serial data key map")
		#;
		#; Kill the serialised form in the object.
		#;
		do $zutil(210,36,rtn)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	#;
	#; Return with the created object (minus the serialised form)
	#;
	return rtn
getdata(gloref , sub)
	set nxt = $get(@gloref@(sub))	// Get first chunk of any potential map
	quit:(nxt = "") ""
	try {
		set newobj = $zutil(210,35,0,nxt,"")
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	set chunksize = 910286
	if ($length(nxt) >= chunksize) {
		#; There are extra data chunks to read in.
		set offset = $length(nxt), chunk = 0
		for {
			set nxt = $get(@gloref@(sub,chunk),"")
			quit:'$length(nxt)
			try {
				set newobj = $zutil(210,35,offset,nxt,newobj)
			} catch {
				do $$$APPERROR1($$$LASTERROR)
			}
			set offset = offset + $length(nxt)
			set chunk = chunk + 1
		}
	}
	quit newobj
	*/
}

///             Remove all the data from the dynamic object, leaving a blank object intact.
///             return $this to allow chaining. 
Method %Clear() As %Library.DynamicAbstractObject
{
	try {
		do $zu(210,16)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return $this
}

Method %Clone() As %DynamicAbstractObject [ Internal ]
{
	try {
		set ans = $zu(210,9)
	} catch {
		do $$$APPERROR1($$$LASTERROR)
	}
	return ans
}

/// %FromOref() will return an instance of %DynamicAbstractObject populated from the <b>source</b> object.
/// <h4>request object</h4>
/// <p>
/// <table border="1" title="Request">
/// 	<tr>
/// 		<th>Name</th><th>Description</th>
/// 	</tr>
/// 	<tr>
/// 		<td>source</td>
/// 		<td>Oref of the object to be cast as a DynamicAbstractObject.</td>
/// 	</tr>
/// 	<tr>
/// 		<td>returnValue</td>
/// 		<td>An oref referencing the DynamicAbstractObject.</td>
/// 	</tr>
/// </table>
/// <br>
/// <pre>
/// set person = ##class(Sample.Person).%OpenId(50)
/// set object = ##class(%DynamicObject).%FromOref(person)
/// </pre>
/// </p>
ClassMethod %FromOref(source As %Library.AbstractSet) As %DynamicAbstractObject
{
	try {
		new %objlasterror
		if source.%IsA("%Library.DynamicObject") || (source.%IsA("%Collection.AbstractArray")) {
			return ##class(%Library.DynamicObject).%FromOref(source)
		} elseif (source.%IsA("%Library.DynamicArray")) || (source.%IsA("%Collection.AbstractList")) {
			return ##class(%Library.DynamicArray).%FromOref(source)
		} elseif source.%IsA("%Library.RegisteredObject") {
			return ##class(%Library.DynamicObject).%FromOref(source)
		} else {
				// Huh? We don't know how to process this object. Perhaps the object can cast itself to something we know?
			set aet = ..%FromJSON(source.%ToJSON())
			if aet.%IsA("%Library.DynamicObject") {
				return ##class(%Library.DynamicObject).%FromOref(aet)
			} elseif aet.%IsA("%Library.DynamicArray") {
				return ##class(%Library.DynamicArray).%FromOref(aet)
			} elseif $data(%objlasterror)#2 {
					// we failed perhaps a null object? - this should not be possible as an exception should have
					// been thrown already. Make sure that happens
				throw ##class(%Exception.StatusException).CreateFromStatus(%objlasterror)
			} else {
					// we failed perhaps a null object? - this should not be possible as an exception should have
					// been thrown already. Make sure that happens
				throw ##class(%Exception.SQL).CreateFromSQLCODE(-400, "%FromOref: Unknown error encountered while attempting to cast object to DAO")
			}
		}
	} catch exception {
		throw exception
	}
	return $$$NULLOREF
}

ClassMethod %FromObject(source As %Any) As %DynamicAbstractObject
{
	if $IsObject(source)<=0 {
		do $$$APPERROR1($$$ERBADOREF)
	}
	new %objlasterror
	try {
		set json=$ZU(223,source)
	} catch {
		set json={"%error%":($E($ZE,1,$F($ZE,">")-1))}
	}
	set type=$S(source.%IsA("%Collection.AbstractArrayOfDT"):1,
		source.%IsA("%Collection.AbstractListOfDT"):2,
		source.%IsA("%Collection.AbstractArrayOfObj"):3,
		source.%IsA("%Collection.AbstractListOfObj"):4,
		source.%IsA("%Library.DynamicAbstractObject"):5,
		1:0)
	if type do ..addList(type,.json,.source)
	quit json
}

ClassMethod %FromObjectSwizzle(oref As %Any, property As %String) As %DynamicAbstractObject
{
	new %objlasterror
	try {
		set swzl=$Method(oref,property_"GetSwizzled")
	} catch {
		return {"%error%":($E($ZE,1,$F($ZE,">")-1))}
	}
	if swzl="" return ""
	return ..%FromObject(swzl)
}

ClassMethod %FromObjectMulti(oref As %Any, property As %String) As %DynamicAbstractObject
{
	new %objlasterror
	try {
		s dd=$D(@("$zobjref("_+oref_")."_property))
		if dd=0 return []
		kill js,subs
		if dd#2 set js(0)=[(@("$zobjref("_+oref_")."_property))]
		else  set js(0)=[null]
		if dd<10 return js(0)
		set nsubs=0,subs="("""""
		set keepnsubs=0
loop0 ;	
		set subscript=$O(@("$zobjref("_+oref_")."_property_subs_")"))
		if subscript="" {
			set nsubs=nsubs-1
			if nsubs=0 return js(0)
			set subs=$E(subs,1,sublen(nsubs))
			goto loop0
		}
loop1 ;
		if 'keepnsubs {
			set nsubs=nsubs+1
			if nsubs=1 set subs="("
			else  set subs=subs_","
			set subs=subs_"subval("_nsubs_")",sublen(nsubs)=$L(subs)
		}
		set subval(nsubs)=subscript
		set dd=$D(@("$zobjref("_+oref_")."_property_subs_")"))
		if dd#2 {
			set tmp=@("$zobjref("_+oref_")."_property_subs_")")
			if $IsObject(tmp) set tmp=..%FromObject(tmp)
			set js(nsubs)=[(tmp)]
		} else { set js(nsubs)=[null] }
		set subscript=$O(@("$zobjref("_+oref_")."_property_subs_","""")"))
		if subscript="" {
			set tmp={} do tmp.%Set(subval(nsubs),js(nsubs))
			do js(nsubs-1).%Push(tmp) kill tmp,js(nsubs)
			set keepnsubs=1
			goto loop0
		}
		set tmp={} do tmp.%Set(subval(nsubs),js(nsubs))
		do js(nsubs-1).%Push(tmp) kill tmp
		set keepnsubs=0
		goto loop1
	} catch { return {"%error%":($E($ZE,1,$F($ZE,">")-1))} }
}

ClassMethod addList(type, ByRef json, ByRef source)
{
	if type=1 {		; array of DT
		set arr={},key=""
		while source.GetNext(.key)'="" {
			do arr.%Set(key,source.GetAt(key))
		}
		set json.Values=arr	
	} elseif type=2 {		; list of DT
		set list=[]
		for i=1:1:source.Count() {
			do list.%Push(source.GetAt(i))
		}
		set json.Values=list
	} elseif type=3 {		; array of Objects
		set arr={},key=""
		while source.GetNext(.key)'="" {
			set tmp=source.GetAt(key)
			if $IsObject(tmp) set tmp=..%FromObject(tmp)
			do arr.%Set(key,tmp)
		}
		set json.Values=arr	
	} elseif type=4 {		; list of Objects
		set list=[]
		for i=1:1:source.Count() {
			set tmp=source.GetAt(i)
			if $IsObject(tmp) set tmp=..%FromObject(tmp)
			do list.%Push(tmp)
		}
		set json.Values=list
	} elseif type=5 {		; %DynamicAbstractObject
		if source.%IsA("%Library.DynamicArray") {
			set list=[]
			set it=source.%GetIterator(),key=""
			while it.%GetNext(.key,.value,.type) {
				do list.%Push(value,type)
			}
			set json.Values=list
		} elseif source.%IsA("%Library.DynamicObject") {
			set list={}
			set it=source.%GetIterator(),key=""
			while it.%GetNext(.key,.value,.type) {
				do list.%Set(key,value,type)
			}
			set json.Values=list
		}
		; else internal types String, Binary, Base64
	}
}

///             @Override
Method "_isLabeled"() As %Boolean [ CodeMode = expression ]
{
$select(..%IsA("%Library.DynamicObject"):1,1:0)
}

}
