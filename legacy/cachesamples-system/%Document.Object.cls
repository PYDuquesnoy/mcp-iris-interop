/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

Class %Document.Object Extends (%Library.SerialObject, %XML.Adaptor) [ OdbcType = VARCHAR, StorageStrategy = custom, System = 3 ]
{

///  Internal property used to track if this object is modified.
Property %changed As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0, Internal, Transient ];

Property %columnIndex As %ZEN.Datatype.string(MAXLEN = "") [ Internal, MultiDimensional, Transient ];

/// 	Internal property used to define this document as a simple document or a collection
Property %isList As %ZEN.Datatype.integer(XMLPROJECTION = "NONE") [ InitialExpression = 0, Internal, Transient ];

///  Internal property used to client index of this object.
Property %index As %ZEN.Datatype.integer(XMLPROJECTION = "NONE") [ Internal, Transient ];

///  Internal array of data values within the proxy, indexed by series and property name.
Property "_data" As %ZEN.Datatype.string [ Internal, MultiDimensional ];

Property "_documentID" As %Binary [ Internal ];

Property "_location" As %String(MAXLEN = 512) [ Internal, Transient ];

///  Property dispatch method to catch references to 
///  virtual properties.<br>
///  This should not be called directly.<br>
Method %DispatchGetProperty(pProperty As %String) [ Final, Internal ]
{
	Quit $G(.."_data"(pProperty))
}

///  Property dispatch method to catch references to 
///  virtual properties.<br>
///  This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %String, pValue As %String) [ Final, Internal ]
{
	if '$Data(.."_data"(pProperty)) {
		set ..%columnIndex = ..%columnIndex + 1, ..%columnIndex(..%columnIndex) = pProperty
		set ..%changed = 1
		set .."_data"(pProperty) = pValue
	}
	elseif .."_data"(pProperty) '= pValue {
		set ..%changed = 1
		set .."_data"(pProperty) = pValue
	}
}

///  This callback method is invoked by the <METHOD>%New</METHOD> method to 
///  provide notification that a new instance of an object is being created.
/// 
///  <P>If this method returns an error then the object will not be created.
///  <p>It is passed the arguments provided in the %New call.
///  When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
///  For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
///  <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
///  If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
///  class then this oref will be the one returned to the caller of %New method.
Method %OnNew(pObjectValue As %String(MAXLEN="") = "", pIsList As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	set ..%columnIndex = 0
	if pObjectValue = "" {
		set ..%isList = pIsList
	}
	elseif $Extract(pObjectValue) = "{" {
		if $Extract(pObjectValue,*) '= "}" { throw ##class(%Exception.General).%New("CSONSYNTAX","CSONSYNTAX",,"CSON: Invalid serial object - '"_pObjectValue_"'") }
		do ..swizzle(pObjectValue)
	}
	elseif $Extract(pObjectValue) = "[" {
		if $Extract(pObjectValue,*) '= "]" { throw ##class(%Exception.General).%New("CSONSYNTAX","CSONSYNTAX",,"CSON: Invalid serial list - '"_pObjectValue_"'") }
		set ..%isList = 1
		do ..swizzle(pObjectValue)
	}
	else {
		throw ##class(%Exception.General).%New("CSONSYNTAX","CSONSYNTAX",,"CSON:Expected '{' or '[' found '"_$Extract(pObjectValue)_"' in '" _ pObjectValue _ "'")
	}
	Quit $$$OK
}

Method %ValidateObject(force As %Integer) As %Status
{
	Quit $$$OK
}

/// Clears the contents of the array.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	kill i%"_data"
	if i%%isList {
		set .."_data" = 0
	}
	Quit $$$OK
}

/// Returns the number of elements contained in the array.
Method Count() As %Integer [ ProcedureBlock = 1 ]
{
	if 'i%%isList { set key="" For tCount=0:1 Set key=$order(i%"_data"(key)) Quit:key="" }
	else { set tCount = +$order(.."_data"(""),-1) }
	quit tCount
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array with value equal to <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %String, key As %String) As %String
{
	if '..%isList {
		set tFound = $get(key)
		for  set tFound = $order(i%"_data"(tFound)) quit:tFound=""||(i%"_data"(tFound)=element)
	}
	else {
		set tStart = $Get(key) + 1, tFound = ""
		for tPtr = tStart:1:.."_data" { if .."_data"(tPtr)=element { set tFound = tPtr quit } }
	}
	quit tFound
}

///  Finds and returns the value of the element at position 
///  <var>key</var> in the list.
/// 
///  <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
///  or null string ("") if no element is found.
Method GetAt(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$select(key="":"",1:$get(i%"_data"(key)))
}

/// Finds and returns the value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %String
{
	set key=$order(.."_data"($get(key)),1,val)
	quit $get(val)
}

/// Finds and returns the value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the value of the last element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %String
{
	set key=$order(.."_data"($get(key)),-1,val)
	quit $get(val)
}

///  Inserts an element with value <var>element</var> at the end of the list.
/// 
///  <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(element As %RawString) As %Status
{
	set .."_data"(+$order(.."_data"(""),-1)+1) = element
	quit $$$OK
}

///  Inserts an element with value <var>element</var> at position <var>key</var>.
/// 
///  <p>To make room for the new element, the elements previously at or following position 
///  <var>key</var> are moved up by one position.
///  <p><var>key</var> must be in the following range: 
///  <blockquote><code>
///  1 &lt= key &lt= Count() + 1
///  </blockquote></code>
/// 
///  Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertAt(element As %RawString, key As %Integer) As %Status
{
	If ..ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set key=+key,count=+$order(.."_data"(""),-1)
	If key<1||(key>(count+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	For i=count:-1:key Set .."_data"(i+1)=.."_data"(i)
	Set .."_data"(key)=element
	Quit $$$OK
}

///  Inserts a list with value <var>inslist</var> at the end of the list.
/// 
///  <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertList(inslist As %RawString) As %Status
{
	if i%%isList {
		set size = +$order(.."_data"(""),-1)
		set ptr = 0
		for i = 1:1 {
			if '$listnext(inslist,ptr,item) quit
			set .."_data"(size+i) = $get(item)
		}
		set tStatus = $$$OK
	}
	else { set tStatus = $$$ERROR($$$GeneralError,"Cannot insert a list into a non-list document") }
	quit tStatus
}

///  Inserts an element with value <var>element</var> into the list at the correct ordered 
///  position. The elements in the list are shifted to accommodate the new element as necessary.
/// 
///  <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertOrdered(element As %RawString) As %Status
{
	set count=+$order(.."_data"(""),-1)+1
	for i=1:1:count quit:(i=count)||(.."_data"(i)]element)
	quit ..InsertAt(element,i)
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ CodeMode = expression, Final ]
{
$data(i%"_data"(key))
}

Method Next(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%"_data"(key))
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <METHOD>Next</METHOD> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%"_data"(key),-1)
}

///  Removes the element at position <var>key</var> in the list. 
///  The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
///  <p><b>RemoveAt</b> returns the value of the removed element or null string ("") 
///  if no element was removed.
Method RemoveAt(key As %Integer) As %RawString
{
	if '..%isList {
		set removed = ..GetAt(key)
		kill i%"_data"(key)
	}
	else {
		set count = +$order(.."_data"(""),-1)
		if (key = "") || ($data(.."_data"(key),removed) = 0) { quit "" }
		for i = key:1:count-1 { set .."_data"(i)=.."_data"(i+1) }
		kill .."_data"(count)
	}
	quit removed
}

///  Sets the value of the element at position <var>key</var> to <var>element</var>.
///  <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(element As %RawString, key As %Integer) As %Status
{
	if '..%isList {
		set i%"_data"(key) = element
	}
	else {
		if ('+key)||((+key'=1)&&($data(.."_data"(key-1))=0)) quit $$$ERROR($$$CollectionKeyInvalid,key)
		set .."_data"(key) = element
	}
	quit $$$OK
}

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	For i=1:1:$listlength(serialized) Set item=$list(serialized,i),array($list(item))=$list(item,2)
	Quit $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ Private ]
{
	quit ..deswizzle()
}

Method %SetSerial(serialized As %String) As %Status [ Private ]
{
	try {
		do ..swizzle(serialized)
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	quit tStatus
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

///  Write out the contents of this proxy object to 
///  the current device in JSON format.<br/>
///  This method is used a proxy object is used in
///  conjunction with the <class>%ZEN.Auxiliary.jsonProvider</class>
///  component.
Method %ToJSON(pLevel As %Integer = 0) As %Status [ Internal ]
{
	#define TAB(%l) ?(4*(%l))
	set tSC = $$$OK
	try {
		write $$$TAB(pLevel),"{",!
		set tPropCount = 0
		set tProp = $order(.."_data"(""))
		while (tProp '= "") {
			set tPropCount = tPropCount + 1
			write $$$TAB(pLevel+1),""""_$ZCVT(tProp,"O","JSON")_"""",": "
			set tValue = $get(.."_data"(tProp))
			if $isobject(tValue) {
				if '(tValue.%isList) {
					set tSC = tValue.%ToJSON(pLevel+1)
					if $$$ISERR(tSC) quit
				}
				elseif (tValue.%isList) {
					write "[",!
					write:tValue.Count()>0 $$$TAB(pLevel+2)
					for n=1:1:tValue.Count() {
						set tItem = tValue.GetAt(n)
						if ($isobject(tItem)) {
							if (tItem.%isList) || (tValue.%IsA("%Document.Object")) {
								set tSC = tItem.%ToJSON(pLevel+2)
								if $$$ISERR(tSC) quit
							}
							else {
								write $$$TAB(pLevel+2),"null"
							}
						}
						else {
							write $select($isvalidnum(tItem)&&(tItem=+tItem):tItem,1:""""_$zconvert(tItem,"O","JSON")_"""")
						}
						write:n<tValue.Count() ", "
						write:$isobject(tItem) !
					}
					write !,$$$TAB(pLevel+1),"]"
					if $$$ISERR(tSC) quit
				}
				else {
					write "null"
				}
			}
			else {
				write $select($isvalidnum(tValue)&&(tValue=+tValue):tValue,1:""""_$zconvert(tValue,"O","JS")_"""")
			}
			set tProp = $order(.."_data"(tProp))
			write:tProp'="" ","
			write !
		}
		write $$$TAB(pLevel),"}"
		write:'pLevel !
	}
	catch(ex) {
		set tSC = ex.AsStatus()
		write !,"/* Error in JSON output:",$system.Status.DisplayError(tSC),!,"*/",!
	}
	quit tSC
}

/// 
/// Write the document as JSON to a stream.
/// 
Method %ToJSONStream(ByRef pStream As %Stream.Object, pRewindStream As %Boolean = 0) As %Status [ ProcedureBlock = 0 ]
{
	New %ISCJSONStream, tSC, ex, tInitIO, tRedirected, tWasRedirected, tOldMnemonic
	#dim ex As %Exception.AbstractException
	#dim tSC As %Status = $$$OK
	#dim tRedirected, tWasRedirected As %Boolean = 0
	#dim tInitIO, tOldMnemonic
	Try {
		Set tWasRedirected = 0
		Set tOldMnemonic = ""

		Set:'$IsObject($G(pStream)) pStream=##class(%Stream.TmpBinary).%New()

		Set tInitIO = $IO
		Set tWasRedirected = ##class(%Library.Device).ReDirectIO()
		Set tOldMnemonic = ##class(%Library.Device).GetMnemonicRoutine()
		Set %ISCJSONStream = pStream
		Use tInitIO::("^"_$ZNAME)
		Set tRedirected = 1
		Do ##class(%Library.Device).ReDirectIO(1)

		// Use %ToJSON to write the JSON
		Set tSC = ..%ToJSON()
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If tRedirected && ##class(%Library.Device).ReDirectIO(0) {
		Use tInitIO
	}
	If ($get(tOldMnemonic) '= "") {
		Set tOldMnemonic = "^"_tOldMnemonic
		Use tInitIO::(tOldMnemonic)
	}
	If $get(tWasRedirected) {
		Do ##class(%Library.Device).ReDirectIO(1)
	}
	If pRewindStream && $$$ISOK(tSC) {
		Do pStream.Rewind()
	}
	
	Quit tSC

#; Public entry points for redirection - any changes made here should
#; also be reflected in redirects() in the jsonSQLProvider class
wstr(s)	Do %ISCJSONStream.Write(s) Quit
wchr(a) Do %ISCJSONStream.Write($char(a)) Quit
wnl 	Do %ISCJSONStream.WriteLine() Quit
wff 	Do %ISCJSONStream.WriteLine() Quit
wtab(n) Do %ISCJSONStream.Write($J("",$S(n>$X:n-$X,1:0))) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

ClassMethod CSON(pObjectValue As %String(MAXLEN="")) As %Document.Object
{
	quit ..%New(pObjectValue)
}

/// 	%Document.Object contructor that populates the document content from an XML source.
/// 	pXML can either be a counted array of lines, a stream object, or...
ClassMethod XML(pXML As %Binary = "") As %Document.Object
{
#dim tXMLDocument as %XML.Document
#dim tXMLNode as %XML.Node
	try {
		if ($Isobject(pXML)) && (pXML.%IsA("%Stream.Object")) {
			set tStatus = ##class(%XML.Document).GetDocumentFromStream(pXML,.tXMLDocument)
			if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
				// Stream containing XML
			set tXMLNode = tXMLDocument.GetDocumentElement()
		}
		elseif ($Isobject(pXML)) && (pXML.%IsA("%XML.Node")) {
			set tXMLNode = pXML
		}
		elseif (pXML = +pXML) && (pXML > 0) {
				// Counted array
		}
		else {
			set tInputStream = ##class(%Stream.FileCharacter).%New()
			do tInputStream.LinkToFile(pXML)
			set tStatus = ##class(%XML.Document).GetDocumentFromStream(tInputStream,.tXMLDocument)
			if $$$ISERR(tStatus) { throw ##class(%Exception.StatusException).CreateFromStatus(tStatus) }
				// Stream containing XML
			set tXMLNode = tXMLDocument.GetDocumentElement()
		}
		if tXMLNode.NodeType = $$$xmlELEMENTNODE {
			set tDocument = ##class(%Document.Object).%New("{}")
			do tDocument.loadXML(tXMLNode)
		}
		else {
			set tDocument = $$$NULLOREF
		}
	}
	catch tException {
		break
		set tDocument = $$$NULLOREF
	}
	quit tDocument
}

Method loadXML(pXMLNode As %XML.Node)
{
		// Process attributes
	set tAttribute = pXMLNode.NextAttributeName("")
	while tAttribute '= "" {
		set $property($this,tAttribute) = pXMLNode.GetAttributeValue(tAttribute)
		set tAttribute = pXMLNode.NextAttributeName(tAttribute)
	}
		// Process child elements
	if pXMLNode.HasChildNodes(1) {
		if pXMLNode.MoveToFirstChild(1) {
			do {
				try {
					set tField = pXMLNode.LocalName
				}
				catch tInner {
					break
				}
				set tFieldCount = $Increment(tList(tField))
					// If this field has already been defined in this document then convert the field to a list
				if tFieldCount = 2 {
						// Convert this singleton to a list
					set tFieldValue = $property($this,tField)
					set tList = ##class(%Document.Object).%New(,1)
					do tList.Insert(tFieldValue)
					set $property($this,tField) = tList
				}
					// Also, if this element has attributes then we have a nested object, not just a simple property
				kill tElementText
				if ((pXMLNode.HasChildNodes(1)) && (pXMLNode.GetText(.tElementText))) {
					set tFieldValue = $Get(tElementText)
				}
				elseif (pXMLNode.HasChildNodes(1)) || (pXMLNode.NextAttributeName("") '= "") {
						// What if this element is a simple element? We can detect with HasChildNodes
						// in combination with attribute count
					set tFieldValue = ##class(%Document.Object).%New()
					do tFieldValue.loadXML(pXMLNode)
				}
				else {
					set tFieldValue = ""
				}
				if tList(tField) '> 1 {
					set $property($this,tField) = tFieldValue
				}
				else {
					set tList = $property($this,tField)
					do tList.Insert(tFieldValue)
				}
			} while pXMLNode.MoveToNextSibling(1)
		}
		do pXMLNode.MoveToParent()
	}
}

Method loadResultSet(pResultSet As %SQL.IResultSet, pFieldName As %String(MAXLEN="") = "results")
{
	if '$Isobject($property($this,pFieldName)) {
		set tCollection = ..%New("[]")
		set $property($this,pFieldName) = tCollection
	}
	else {
		set tCollection = $property($this,pFieldName)
	}
	set tRSMD = pResultSet.%GetMetadata()
	set tColumnCount = tRSMD.columns.Count()
	for tPtr = 1:1:tRSMD.columns.Count() {
		set tColumn(tPtr) = tRSMD.columns.GetAt(tPtr).colName
	}
	while pResultSet.%Next() {
		set tRow = ..%New()
		do tCollection.Insert(tRow)
		for tPtr = 1:1:tColumnCount {
			set $property(tRow,tColumn(tPtr)) = pResultSet.%GetData(tPtr)
		}
	}
}

/// deswizzle serializes a %Document object into CSON format.
Method deswizzle() As %String(MAXLEN="")
{
#define CSONVAL(%val)		$Select('$f($tr(%val,""",:",$c(0,0,0)),$c(0)):%val,1:$$$quote(%val))
	try {
		if '..%isList {
			set tSerial = "{"
			for tPtr = 1:1:..%columnIndex {
				set tProp = ..%columnIndex(tPtr)
				set tSerial = tSerial _ tProp _ ":"
				set tValue = $get(.."_data"(tProp))
				if $isobject(tValue) {
					set tSerial = tSerial _ tValue.deswizzle()
				}
				else { set tSerial = tSerial _ $$$CSONVAL(tValue) }
				set tSerial = tSerial _ ","
				set tProp = $order(.."_data"(tProp))
			}
			set tSerial = $Extract(tSerial,1,*-1) _ "}"
		}
		else {
			set tSerial = "["
			set tCount = ..Count()
			for tPtr = 1:1:tCount {
				set tValue = ..GetAt(tPtr)
				if $isobject(tValue) {
					set tSerial = tSerial _ tValue.deswizzle()
				}
				else { set tSerial = tSerial _ $$$CSONVAL(tValue) }
				set tSerial = tSerial _ ","
			}
			set tSerial = $Extract(tSerial,1,*-1) _ "]"
		}
	}
	catch tException {
		write !,"/* Error in deswizzle:",tException.DisplayString(),!,"*/",!
	}
	quit tSerial
}

/// swizzle converts a CSON object value into the current object.
Method swizzle(pObjectValue As %String(MAXLEN="") = "")
{
#define StripQuotes(%s) $replace($e(%s,2,*-1),"""""","""")
	try {
		kill .."_data",..%columnIndex
		set tIsList = $Extract(pObjectValue,1) = "["
		set tObjectValue = $Extract(pObjectValue,2,*-1)
		do ..parse(tObjectValue,.tToken)
		if 'tIsList {
			for tPtr = 1:1:tToken {
				do ..parse(tToken(tPtr),.tValue,":")
				if tValue < 2 {
					set tValue = 2
					set tValue(2) = ""
				}
				if $Extract(tValue(2)) '= """" {
					set .."_data"(tValue(1)) = $Case($Extract(tValue(2)),
							"{": ..CSON(tValue(2)),
							"[": ..CSON(tValue(2)),
							: tValue(2)
							)
				}
				else {
					xecute ("(t) { s t="_tValue(2) _ "}",.tTemp)
					set .."_data"(tValue(1)) = tTemp
				}
				set ..%columnIndex(tPtr) = tValue(1)
			}
			set ..%columnIndex = tToken
		}
		else {
			set tObjectValue = $Extract(pObjectValue,2,*-1)
			do ..parse(tObjectValue,.tToken)
			set .."_data" = tToken
			for tPtr = 1:1:tToken {
				if $Extract(tToken(tPtr)) '= """" {
					set .."_data"(tPtr) = $Case($Extract(tToken(tPtr)),
							"{": ..CSON(tToken(tPtr)),
							"[": ..CSON(tToken(tPtr)),
							: tToken(tPtr)
							)
				}
				else {
					set .."_data"(tPtr) = $$$StripQuotes(tToken(tPtr))
				}
			}
		}
	}
	catch tException {
		throw tException
	}
}

/// Display the current object and all nested objects.
Method show(pLevel As %ZEN.Datatype.integer = 0)
{
#define CSONVAL(%val)	$Select('$f($tr(%val,""",:",$c(0,0,0)),$c(0)):%val,1:$$$quote(%val))

	try {
		if '..%isList {
			write "<oref>"
			set $Piece(tIndent,$Char(9),pLevel+1) = ""
			for tPtr = 1:1:..%columnIndex {
				set tProp = ..%columnIndex(tPtr)
				write !,tIndent,tProp,":",$Char(9)
				set tValue = $get(.."_data"(tProp))
				if $isobject(tValue) {
					do tValue.show(pLevel+1)
				}
				else {
					write $$$CSONVAL(tValue)
				}
				set tProp = $order(.."_data"(tProp))
			}
		}
		else {
			write "<<array>>"
			set $Piece(tIndent,$Char(9),pLevel+1) = ""
			set tCount = ..Count()
			for tPtr = 1:1:tCount {
				set tValue = ..GetAt(tPtr)
				write !,tIndent,$Justify(tPtr,$l(tCount)),":"
				if $isobject(tValue) {
					do tValue.show(pLevel+1)
				}
				else {
					write $$$CSONVAL(tValue)
				}
			}
		}
	}
	catch tException {
		write !,"/* Error in show:",tException.DisplayString(),!,"*/",!
	}
}

/// Document string parser
ClassMethod parse(pLex As %String(MAXLEN="") = "", ByRef pToken As %String(MAXLEN=""), pDelimiter As %String = ",") [ Internal ]
{
	set tObjectOpen = "{", tObjectClose = "}", tListOpen = "[", tListClose = "]"
	set tLexEnc = $Translate($ZConvert(pLex,"U"),"{}[]"""_pDelimiter,$Char(0,0,0,0,0,0))
	set tLexPtr = 1, tLexLen = $Length(tLexEnc)
	set pToken = 0, tQuote = 0, tParens = 0, tLists = 0
	set tLexStart = 1
	while tLexPtr '> tLexLen {
		set tLexPtr = $Find(tLexEnc,$Char(0),tLexPtr)
			#; No more terminators found, must be EOL
		if tLexPtr {
			set tLexTerminator = $Extract(pLex,tLexPtr-1)
			if tLexTerminator = """" { set tQuote = 'tQuote }
			elseif tLexTerminator = tObjectOpen { if 'tQuote { set tParens = tParens + 1 } }
			elseif tLexTerminator = tObjectClose { if 'tQuote { set tParens = tParens - 1 } }
			elseif tLexTerminator = tListOpen { if 'tQuote { set tLists = tLists + 1 } }
			elseif tLexTerminator = tListClose { if 'tQuote { set tLists = tLists - 1 } }
			elseif (tLexTerminator = pDelimiter) && ('tQuote) && ('tParens) && ('tLists) { set tValue = $Extract(pLex,tLexStart,tLexPtr - 2) if tValue '= "" { set pToken = pToken + 1, pToken(pToken) = tValue } set tLexStart = tLexPtr }
		}
		else { set tLexPtr = tLexLen + 1 }
	}
	if tLexStart '> tLexLen { set tValue = $Extract(pLex,tLexStart,*) if tValue '= "" { set pToken = pToken + 1, pToken(pToken) = tValue } }
	if tQuote || tParens || tLists { throw ##class(%Exception.General).%New("CSONSYNTAX","CSONSYNTAX",,"CSON: Unbalanced "_$Select(tQuote:"quotes",tParens:"curly braces",tLists:"brackets",1:"delimiters")_" - '"_pLex_"'") }
}

/// DocumentExists() returns a boolean value indicate whether or not the documentID exists in the global/local variable reference (GLVN). 
/// 	<p>
/// <table border=1>
/// <th>
/// Parameters
/// </th>
/// <tr>
/// 		<td>pWhere</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>Global or local variable reference where documents are stored.</p>
/// 		</td>
/// </tr>
/// <tr>
/// 		<td>pDocumentID</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>The document ID.</p>
/// 		</td>
/// </tr>
/// </table>
/// </p>
ClassMethod DocumentExists(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string = "") As %ZEN.Datatype.boolean
{
	try {
		set tReturn = 0
		if $Data(@pWhere@(pDocumentID)) {
			set tReturn = 1
		}
	}
	catch tException {
		set tReturn = 0
	}
	quit tReturn
}

/// OpenDocument will retrieve a previously saved document from the specified global or local variable reference (GLVN) with the specified <var>pDocumentID</var> 
/// and return an oref referencing an instance of %ZEN.proxyObject. 
/// If a document with the specified ID does not exist in that GLVN then OpenDocument will return an error in the output pStatus parameter.
/// 	<p>
/// <table border=1>
/// <th>
/// Parameters
/// </th>
/// <tr>
/// 		<td>pWhere</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>Global or local variable reference. This is the location where the proxyObject instance will be saved.</p>
/// 		</td>
/// </tr>
/// <tr>
/// 		<td>pDocumentID</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>The ID of the document to be opened.</p>
/// 		</td>
/// <tr>
/// 		<td>pStatus</td>
/// 		<td>Output</td>
/// 		<td>
/// 				<p>The returned %Status value, indicating success or failure.</p>
/// 		</td>
/// </tr>
/// </table>
/// </p>
ClassMethod open(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, Output pStatus As %Status = "") As %Document.Object
{
	try {
		if $Data(@pWhere@(pDocumentID)) {
			set tObjectID = $Order(@pWhere@(pDocumentID,""),1,tType)
			if tObjectID '= "" {
				if tType = "" {
					set tMe = ..%New("",0)
				}
				elseif tType = "list" {
					set tMe = ..%New("",1)
				}
				else {
					// huh???
				}
				set tOQ = 1, tOQPtr = 1
					// Initialize the Object Queue
					/// tOQ			The current Queue Pointer
					//	tOQ(ptr) is the object ID
					//	tOQ(ptr,0) is the current object's oref
					//	tOQ(ptr,1) is the containing object's oref
					//	tOQ(ptr,2) is the containing object's property
				set tOQ(1) = tObjectID, tOQ(1,0) = tMe, tOQ(1,1) = ""
				do {
					set tObjectID = tOQ(tOQPtr)
					set tObject = tOQ(tOQPtr,0)
						// tOREF is an index on objectID so that we can resolve object references from multiple properties/objects
					set tOREF(tObjectID) = tObject
					if $Isobject(tOQ(tOQPtr,1)) {
						set $property(tOQ(tOQPtr,1),tOQ(tOQPtr,2)) = tObject
					}
					do tObject.load(pWhere,pDocumentID,tObjectID,.tOQ,.tOREF)
					set tOQPtr = $Order(tOQ(tOQPtr))
				} while tOQPtr
				set pStatus = $$$OK
			}
			else {
				set tMe = ..%New("",0)
			}
		}
		else {
				// Document doesn't exist
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound,pWhere,pDocumentID))
		}
	}
	catch tException {
		set tMe = $$$NULLOREF
		set pStatus = tException.AsStatus()
	}
	quit tMe
}

/// Save the Document to a global or local variable reference (GLVN) with the specified <var>pDocumentID</var>.
/// If a document with the same ID already exists in that GLVN then an error %Status value is returned.
/// 	<p>
/// <table border=1>
/// <th>
/// Parameters
/// </th>
/// <tr>
/// 		<td>pWhere</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>Global or local variable reference. This is the location where the %Document instance will be saved.</p>
/// 		</td>
/// </tr>
/// <tr>
/// 		<td>pDocumentID</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>The document ID. This value must be unique within the GLVN specified in <var>pWhere</var>.</p>
/// 		</td>
/// </tr>
/// </table>
/// </p>
Method save(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string = "", pUpdate As %Integer = 1) As %Status
{
#define pdbEncodeLiteral(%value)			$select(%value="":"",'$f("@#",$e(%value)):%value,1:"/"_%value)
	// Internal Document reference
#define pdbEncodeReference(%value)			$select(%value'="":"@"_%value,1:"")
	// Reference to any Cache Object
#define pdbEncodeObject(%value)				$select(%value'="":"#"_%value,1:"")

	try {
		if pWhere = "" { set pWhere = "_location" }
		if pDocumentID = "" { set pDocumentID = .."_documentID" }
		if pDocumentID = "" { set pDocumentID = 1 }
		if $Data(@pWhere@(pDocumentID)) {
			if pUpdate {
				kill @pWhere@(pDocumentID)
			}
			else {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$IDKeyNotUnique,pWhere,pDocumentID,pWhere))
			}
		}
			// Initialize the Object ID counter
		set tObjectID = 0
			// Initialize the Object Queue
		set tOQ = 1, tOQ(1) = $this, tOQ(1,1) = 0
			// and the Queue Ptr
		set tOQPtr = 1
			// Save the Document header
		set @pWhere@(pDocumentID) = $h
		do {
			set tObject = tOQ(tOQPtr)
			set tObjectID = tObjectID + 1
				// tOID is an index on +oref so that we can resolve object references from multiple properties/objects
			set tOID(+tObject) = tObjectID
			if tOQ(tOQPtr,1) {
					// Tell the outer object about me
					// Encode this value as an object
				set @pWhere@(pDocumentID,tOQ(tOQPtr,1),tOQ(tOQPtr,2)) = $$$pdbEncodeReference(tObjectID)
			}
			if tObject.%IsA("%Document.Object") {
				if 'tObject.%isList {
					set tProperty = $Order(tObject."_data"(""),1,tValue)
					if tProperty '= "" {
						do {
							if '$Isobject(tValue) {
									// Need to encode tProperty - % vs. _, delimited, etc. ??
								set @pWhere@(pDocumentID,tObjectID,tProperty) = $$$pdbEncodeLiteral(tValue)
							}
							elseif $Get(tOID(+tValue)) '= "" {
								set @pWhere@(pDocumentID,tObjectID,tProperty) = $$$pdbEncodeReference(tOID(+tValue))
							}
								// Queue the object so we can serialize it later
							elseif (tValue.%IsA("%Document.Object")) {
								set tOQ = tOQ + 1
								set tOQ(tOQ) = tValue
								set tOQ(tOQ,1) = tObjectID
								set tOQ(tOQ,2) = tProperty
							}
							else {
				/// TODO: This is some other object - just serialize it and get its ID
							}
							set tProperty = $Order(tObject."_data"(tProperty),1,tValue)
						} while tProperty '= ""
					}
					set @pWhere@(pDocumentID,tObjectID) = ""
				}
				else {
					set tElement = ""
					set tValue = tObject.GetNext(.tElement)
					if tElement '= "" {
						do {
							if '$Isobject(tValue) {
									// Need to encode tElement - % vs. _, delimited, etc. ??
				/// TODO Encode this as a literal
								set @pWhere@(pDocumentID,tObjectID,tElement) = $$$pdbEncodeLiteral(tValue)
							}
							elseif $Get(tOID(+tValue)) '= "" {
								set @pWhere@(pDocumentID,tObjectID,tElement) = $$$pdbEncodeReference(tOID(+tValue))
							}
								// Queue the object so we can serialize it later
							elseif tValue.%IsA("%Document.Object") {
									// This mechanism does not allow for one oref to be referenced from multiple locations
								set tOQ = tOQ + 1
								set tOQ(tOQ) = tValue
								set tOQ(tOQ,1) = tObjectID
								set tOQ(tOQ,2) = tElement
							}
							elseif tObject.%IsA("%Library.SwizzleObject") {
									// Object link
									// Beware of recursion, near and far.
								
							}
							else {
				/// TODO: This is some other object - just serialize it and get its ID
							}
							set tValue = tObject.GetNext(.tElement)
						} while tElement '= ""
					}
					set @pWhere@(pDocumentID,tObjectID) = "list"
				}
			}
			set tOQPtr = $Order(tOQ(tOQPtr))
		} while tOQPtr
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	quit tStatus
}

Method load(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, pObjectID As %ZEN.Datatype.integer, ByRef pOQ, ByRef pOREF) [ Internal ]
{
	if '..%isList {
		set .."_location" = pWhere
		set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,""),1,tValue)
		if tProperty '= "" {
			do {
				if ('$Find("#@",$Extract(tValue))) || (tValue = "") {
					if '$Find("/@/#",$Extract(tValue,1,2)) {
						set $property($this,tProperty) = tValue
					}
					else {
						set $property($this,tProperty) = $Extract(tValue,2,*)
					}
				}
				elseif $Isobject($Get(pOREF($Extract(tValue,2,*)))) {
					set $property($this,tProperty) = pOREF(tValue)
				}
				else {
					set tValueType = $Extract(tValue)
					set tObjectID = $Extract(tValue,2,*)
					// Queue the object so we can load it later
					set tType = $Get(@pWhere@(pDocumentID,tObjectID))
					set pOQ = pOQ + 1
					set pOQ(pOQ) = tObjectID
					set pOQ(pOQ,0) = $Select(tType="":..%New("",0),1:..%New("",1))
					set pOQ(pOQ,1) = $this
					set pOQ(pOQ,2) = tProperty
				}
				set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,tProperty),1,tValue)
			} while tProperty '= ""
		}
	}
	else {
		set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,""),1,tValue)
		if tProperty '= "" {
			do {
				if ('$Find("#@",$Extract(tValue))) || (tValue = "") {
					if '$Find("/@/#",$Extract(tValue,1,2)) {
						do ..InsertAt(tValue,tProperty)
					}
					else {
						do ..InsertAt($Extract(tValue,2,*),tProperty)
					}
				}
				elseif $Isobject($Get(pOREF($Extract(tValue,2,*)))) {
						do ..InsertAt($Extract(tValue,2,*),pOREF(tValue))
				}
				else {
					set tValueType = $Extract(tValue)
					set tObjectID = $Extract(tValue,2,*)
					// Queue the object so we can load it later
					set tType = $Get(@pWhere@(pDocumentID,tObjectID))
					set pOQ = pOQ + 1
					set pOQ(pOQ) = tObjectID
					set pOQ(pOQ,0) = $Select(tType="":..%New("",0),1:..%New("",1))
					set pOQ(pOQ,1) = $this
					set pOQ(pOQ,2) = tProperty
				}
				set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,tProperty),1,tValue)
			} while tProperty '= ""
		}
	}
}

Storage custom
{
<StreamLocation>^Document.ObjectS</StreamLocation>
<Type>%Library.CompleteCustomStorage</Type>
}

}
