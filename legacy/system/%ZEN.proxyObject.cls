/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// The Zen Proxy class provides a way to assemble data that can be
/// conveniently passed between the web client and the server.
/// It works in conjunction with the <b>zenProxy</b> JavaScript class
/// defined in <i>zenutils.js</i>. The <b>zenProxy</b> class is
/// the client-side representation of the server-side <class>%ZEN.proxyObject</class>
/// class and vice versa.<br/>
/// The <class>%ZEN.proxyObject</class> class is useful for cases where
/// you do not know what run-time properties will exist when you are designing
/// your application (perhaps it is user-configurable).<br/>
/// The proxy class can be used in several ways. You can use it to send
/// an arbitrary set of data values from the client to a server-side method.
/// To do this, create an instance of <b>zenProxy</b> in a client-side JavaScript method:
/// <example language="javascript">
/// 	// create instance of zenProxy
/// 	var obj = new zenProxy();
/// 	obj.name = 'Smith';
/// 	obj.code = 'CRM114';
/// </example>
/// The <b>zenProxy</b> object is basically a generic JavaScript object with
/// a few pre-defined behaviors. You can dynamically add properties to it
/// simply by setting them.
/// These properties should have <em>literal</em> values, that is, they
/// should not refer to other JavaScript objects.<br/>
/// If you define a server-side ZenMethod whose signature includes an
/// argument of type <class>%ZEN.proxyObject</class>, then you can invoke
/// this method from the client passing it an instance of a <b>zenProxy</b>
/// object. Zen will automatically marshal the values in the <b>zenProxy</b>
/// object into an instance of the <class>%ZEN.proxyObject</class> object.<br/>
/// For example, suppose you have defined a server method:
/// <example language="cls!member">
/// ClassMethod MyMethod(pProxy as %ZEN.proxyObject) As %Boolean [ZenMethod]
/// {
/// 	Set tName = pProxy.name
/// 	Set tCode = pProxy.code
/// 	Quit 1
/// }
/// </example>
/// The client can invoke this method as it would any other Zen method, passing
/// an instance of <b>zenProxy</b> as the <var>pProxy</var> argument:
/// <example language="javascript">
/// 	var obj = new zenProxy();
/// 	obj.name = 'Smith';
/// 	obj.code = 'CRM114';
/// 	var ok = this.MyMethod(obj);
/// </example>
/// The <method>MyMethod</method> method will see the values 'Smith' and 'CRM114' for the properties
/// <property>name</property> and <property>code</property>, respectively.<br/>
/// You can also use the <class>%ZEN.proxyObject</class> class to pass values
/// from a server method back to the client. To do this, create a server method
/// whose return type is <class>%ZEN.proxyObject</class>:
/// <example language="cls!member">
/// ClassMethod GetServerInfo() As %ZEN.proxyObject [ZenMethod]
/// {
/// 	Set tProxy = ##class(%ZEN.proxyObject).%New()
/// 	Set tProxy.whatever = "Some server value"
/// 	Quit tProxy
/// }
/// </example>
/// The client can invoke this method and use its return value as an object:
/// <example language="javascript">
/// 	var obj = this.GetServerInfo();
/// 	alert(obj.whatever);
/// </example>
/// The <class>%ZEN.proxyObject</class> does not actually define any
/// properties. Instead it maintains an internal array of property names
/// along with their corresponding values and uses dynamic dispatch
/// to handle references to specific properties. This means that there
/// is no name checking for properties of <class>%ZEN.proxyObject</class> 
/// (the same behavior as JavaScript objects). You can remove the current set of
/// properties within a <class>%ZEN.proxyObject</class> object using
/// the <method>%Clear</method> method. You can find out what the
/// current set of properties is (as a local array) or supply a new set
/// using the <method>%CopyToArray</method> and <method>%CopyFromArray</method> methods.<br/>
/// The client-side <b>zenProxy</b> class defines only one public method,
/// <method>clear</method>, which deletes the current set of properties
/// from the object. In all other ways, you can treat is an instance
/// of JavaScript <b>Object</b>.<br/>
/// You can get the set of values within a <class>%ZEN.Auxiliary.dataController</class>
/// objects using its <method>getDataAsObject</method> method.<br/>
/// When using the <class>%ZEN.proxyObject</class> class keep the following
/// things in mind:
/// <ul>
/// <li>All properties must have literal values (numbers or strings).</li>
/// <li>You have to use property names that are valid in both the client
/// and server environments. This means that names have to agree in case. It
/// also means that you cannot have two properties with the same name
/// but different case.</li>
/// </ul>
/// Note that <class>%ZEN.proxyObject</class> DOES support
/// various property names that are valid in Javascript but were not traditionally
/// valid Objectscript property names. In general, these property names include symbols like
/// "$" and "_" that are relatively common in Javascript. To reference such a property in a
/// <class>%ZEN.proxyObject</class> instance, simply delimit the property name using quotes:
/// <example>
/// Set myProperty = tProxy."my_property"
/// Set tProxy."$$foo" = "bar"
/// </example>
Class %ZEN.proxyObject Extends %RegisteredObject [ Deprecated, Final, System = 3 ]
{

///  Internal property used to track if this object is modified.
Property %changed As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0, Internal ];

///  Internal property used to client index of this object.
Property %index As %ZEN.Datatype.integer(XMLPROJECTION = "NONE") [ Internal ];

///  Internal array of data values within the proxy, indexed by series and property name.
Property %data As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ Internal, MultiDimensional ];

///  Property dispatch method to catch references to 
///  virtual properties.<br>
///  This should not be called directly.<br>
Method %DispatchGetProperty(pProperty As %String) [ Final, Internal ]
{
	Quit $G(..%data(pProperty))
}

///  Property dispatch method to catch references to 
///  virtual properties.<br>
///  This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %String, pValue As %String) [ Final, Internal ]
{
	If ('$D(..%data(pProperty)) || (..%data(pProperty)'=pValue)) {
		Set ..%changed = 1
		Set ..%data(pProperty) = pValue
	}
}

///  Delete all properties and data currently in the proxy object.
Method %Clear() [ Final ]
{
	Kill ..%data
}

///  Copy the properties in this proxyObject into
///  a local array subscripted by property name.
Method %CopyToArray(Output pArray) [ Final ]
{
	Kill pArray
	Merge pArray = ..%data
}

///  Copy the values from a local array 
///  (subscripted by property name) into
///  this proxyObject.
Method %CopyFromArray(ByRef pArray) [ Final ]
{
	Kill ..%data
	Merge ..%data = pArray
}

Method %ZENDeserialize(pState As %String, ByRef pObjSet) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	// CRC is class name in this case
	If ("%ZEN.proxyObject"'=$P(pState,$C(1),1)) { Quit $$$ERROR($$$GeneralError,"Server version of object does not match version sent from the client."_..%ClassName(1)) } 

	Set ..%index = $P(pState,$C(1),2)
	Kill ..%data
	Set tLen = $L(pState,$C(1))
	For n = 3:1:tLen {
		Set x = $P(pState,$C(1),n)
		Set tProp = $P(x,$C(5),1)
		Set tValue = $P(x,$C(5),2)
		Set:tProp'="" ..%data(tProp) = tValue
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,"%OnZENDeserialize: " _ $ZE)
	Goto Done
}

///  Synchronize this object with its client version.
Method %ObjectSynch() As %Status [ Final, Internal ]
{
	Write "o.clear();",!
	Set tProp = $O(..%data(""))
	While (tProp '= "") {
		Write "o['",$zcvt(tProp,"O","JS"),"']='",$ZCVT($G(..%data(tProp)),"O","JS"),"';",!
		Set tProp = $O(..%data(tProp))
	}
	Quit $$$OK
}

///  Serialize this object so that it can be shipped to the client.
Method %Serialize() As %Status [ Final, Internal ]
{
	Set tState = ""
	Set tProp = $O(..%data(""))
	While (tProp '= "") {
		Set tState = tState _ $S(tState="":"",1:$C(1)) _ tProp_$C(5)_$G(..%data(tProp))
		Set tProp = $O(..%data(tProp))
	}
	Quit "%ZEN.proxyObject"_$C(1,1)_tState
}

///  Given a string from the client,
///  see if it contains a packed representation of a proxyObject.
///  If it does, unpack and return a new object, otherwise
///  return "".
ClassMethod %Create(pState As %String) As %ZEN.proxyObject [ Internal ]
{
	Set tObj = ""
	If ($IsObject(pState) && pState.%IsA("%ZEN.proxyObject")) {
		#; if we are passed an object, return it.
		Quit pState
	}

	If ($P(pState,$C(6),1)="%ZEN.proxyObject") {
		Set tObj = ..%New()
		Set tLen = $L(pState,$C(6))
		For n = 3:1:tLen {
			Set x = $P(pState,$C(6),n)
			Set tProp = $P(x,$C(5),1)
			Set tValue = $P(x,$C(5),2)
			Set:tProp'="" tObj.%data(tProp) = tValue
		}
	}
	Quit tObj
}

/// Drill down just enough to find out if the object has any content displayable as JSON given the current pFormat options
Method hasJSONContent(pFormat As %String) As %Boolean [ Internal ]
{
	Set tHas=0, tProp="" For { Set tProp=$O(..%data(tProp),1,tValue)  Quit:""=tProp
		If $IsObject(tValue) {
			If tValue.%IsA("%ZEN.proxyObject") {
				If pFormat["o" || tValue.hasJSONContent(pFormat) {
					Set tHas=1  Quit
				}
			} ElseIf pFormat["o" || ##class(%ZEN.Auxiliary.jsonProvider).hasObjContent(tValue,.tVisited,pFormat) {
				Set tHas=1  Quit
			}
		} Else {
			If ""'=tValue Set tHas=1  Quit
		}
	}
	Quit tHas
}

/// Write out the contents of this proxy object to the current device in JSON format.<br/>
/// This method is called when a proxy object is used in conjunction with
/// the <class>%ZEN.Auxiliary.jsonProvider</class> component.<br/>
/// <var>pFormat</var> is a flags string to control output formatting options.<br/>
/// The following character option codes are supported:<br/>
/// 1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)<br/>
/// a - output null arrays/objects<br/>
/// b - line break before opening { of objects<br/>
/// c - output the ObjectScript-specific "_class" and "_id" properties (if a child property is an instance of a concrete object class)<br/>
/// e - output empty object properties<br/>
/// i - indent with 4 spaces unless 't' or 1-9<br/>
/// l - output empty lists<br/>
/// n - newline (lf)<br/>
/// o - output empty arrays/objects<br/>
/// q - output numeric values unquoted even when they come from a non-numeric property<br/>
/// s - use strict JSON output - <strong>NOTE:</strong> special care should be taken when sending data to a browser, as using this flag 
/// may expose you to cross site scripting (XSS) vulnerabilities if the data is sent inside <code>&lt;script&gt;</code> tags. Zen uses
/// this technique extensively, so this flag should <strong>NOT</strong> be specified for jsonProviders in Zen pages.<br/>
/// t - indent with tab character<br/>
/// u - output pre-converted to UTF-8 instead of in native internal format<br/>
/// w - Windows-style cr/lf newline<br/>
Method %ToJSON(pLevel As %Integer = 0, pFormat As %String = "aelotw") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tLF=$S(pFormat["w":$C(13,10), pFormat["n":$C(10), 1:"")
		If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,pFormat["t":1,1:4))="" }
		Else { Set tTab="" }
		Set tIncludeWhitespace = (tLF_tTab'="")

		If pFormat["o" || 'pLevel {
			Set tPropCount = ""
			If (tIncludeWhitespace && pLevel) Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write $S(pFormat["b":tLF_tIndent,1:" ")
			Write "{"
		} Else {
			Set tPropCount = 0
		}
		Set tProp="" For { Set tProp=$O(..%data(tProp),1,tValue)  Quit:""=tProp
			If $IsObject(tValue) {
				If tValue.%IsA("%ZEN.proxyObject") {
					If pFormat["o" || tValue.hasJSONContent(pFormat) {
						Do nextProp
						Write $$$ZENJSONPROP(tProp,pFormat)_":"
						Set tSC = tValue.%ToJSON(pLevel+1,pFormat)
						Quit:$$$ISERR(tSC)
					}
				} ElseIf pFormat["o" || ##class(%ZEN.Auxiliary.jsonProvider).hasObjContent(tValue,.tVisited,pFormat) {
					Do nextProp
					Write $$$ZENJSONPROP(tProp,pFormat)_":"
					Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ObjectToJSON(tValue,.tVisited, pLevel+1, pFormat)
					Quit:$$$ISERR(tSC)
				}
			} ElseIf pFormat["e" || $L(tValue) {
				Do nextProp
				Write $$$ZENJSONPAIR(tProp,tValue,pFormat)
			}
		}
		If tPropCount'=0 {
			#; either we wrote at least one property or we wrote an empty '{' due to "o" mode or level zero
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write tLF_tIndent
			Write "}"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write !,"/* Error in JSON output:",$System.Status.DisplayError(tSC),!,"*/",!
	}
	Quit tSC

nextProp
	If tPropCount=0 {
		If (tIncludeWhitespace && pLevel) Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write $S(pFormat["b":tLF_tIndent,1:" ")
		Write "{"
	} ElseIf tPropCount {
		Write ","
	} ; else tPropCount="" means we already did the starting '{' due to "o" mode
	Set tPropCount = tPropCount + 1
	If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,pLevel+2)="" Write tLF_tIndent
	Quit
}

///  Utility method.<br/>
///  Print out contents of this proxy object to the current device.
Method %Print(pLevel As %Integer = 0) [ Internal ]
{
	Write ?(pLevel*4),"-----------------",!
	Set tProp = $O(..%data(""))
	While (tProp '= "") {
		Write ?(pLevel*4),tProp,": "
		Set tValue = $G(..%data(tProp))
		If $IsObject(tValue) {
			If tValue.%IsA("%ZEN.proxyObject") {
				Do tValue.%Print(pLevel+1)
			}
			ElseIf (tValue.%IsA("%Collection.AbstractList")) {
				Write !
				For n=1:1:tValue.Count() {
					Write ?(pLevel+2),"[",n,"] "
					Set tItem = tValue.GetAt(n)
					If ($IsObject(tItem)&&tItem.%IsA("%ZEN.proxyObject")) {
						Do tItem.%Print(pLevel+1)
					}
					Else {
						Write tItem,!
					}
				}
			}
			Else {
				Write "(",tValue,")"
			}
		}
		Else {
			Write $$$quote(tValue)
		}
		Write !
		Set tProp = $O(..%data(tProp))
	}
}

/// Enumerate the contents of this proxy object, calling Client for each node
Method Enumerate(Client As %ZEN.proxyObjectEnumeratee, pLevel As %Integer = 0) As %Status [ Internal ]
{
	#Dim tSC,tPropCount,tProp,tValue,n,tItem,ex
	
	Set tSC = $$$OK
	Try {

		// tell client to start a new object
		Do Client.BeginNested()
		
		// for each property of the current object ..
		Set tPropCount = 0
		Set tProp = $O(..%data(""))
		While (tProp '= "") {
			
			// bump property count and tell client the property name
			Set tPropCount = tPropCount + 1
			Do Client.PropertyName(tProp)
			
			// the property value
			Set tValue = $G(..%data(tProp))
			
			If $IsObject(tValue) {
				
				// if it's a nested proxy object ..
				If tValue.%IsA("%ZEN.proxyObject") {
					
					// recurse
					Set tSC = tValue.Enumerate(Client,pLevel+1) If $$$ISERR(tSC) Quit
				}
				
				// .. if it's a list ..
				ElseIf (tValue.%IsA("%Collection.AbstractList")) {
					
					// tell client to start a new list
					Do Client.BeginList()
					
					// for each list item ..
					For n=1:1:tValue.Count() {
						
						Set tItem = tValue.GetAt(n)
						If ($IsObject(tItem)) {
							
							// if it's a nested proxy object ..
							If (tItem.%IsA("%ZEN.proxyObject")) {
								
								// recurse
								Set tSC = tItem.Enumerate(Client,pLevel+1) If $$$ISERR(tSC) Quit
							}
							Else {
								Do Client.CacheObject(tItem)
							}
						}
						Else {
							Do Client.Simple(tItem)
						}
					}
					
					// for each named property ..
					Set n=$Char(0) // I believe that this collates earlier than any other non-numeric key
					While 1 {
						
						Set n=tValue.Next(n) If n="" {Quit}
						Do Client.PropertyName(n)					
						Set tItem = tValue.GetAt(n)
						If ($IsObject(tItem)) {
							
							// if it's a nested proxy object ..
							If (tItem.%IsA("%ZEN.proxyObject")) {
								
								// recurse
								Set tSC = tItem.Enumerate(Client,pLevel+1) If $$$ISERR(tSC) Quit
							}
							Else {
								Do Client.CacheObject(tItem)
							}
						}
						Else {
							Do Client.Simple(tItem)
						}
					}
					
					Do Client.EndList()
					If $$$ISERR(tSC) Quit
				}
				Else {
					Do Client.CacheObject(tValue)
				}
			}
			Else {
				Do Client.Simple(tValue)
			}
			Set tProp = $O(..%data(tProp))
		}
		Do Client.EndNested()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// DeleteDocument will delete a document identified by ID from the specified global or local variable reference (GLVN)</var>. 
/// If a document with the specified ID does not exist in that GLVN then DeleteDocument will return an error in the returned %Status value. 
/// 	<p>
/// <table border=1>
/// <th>
/// Parameters
/// </th>
/// <tr>
/// 		<td>pWhere</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>Global or local variable reference. This is the location from where the proxyObject instance will be deleted.</p>
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
ClassMethod DeleteDocument(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string = "") As %Status
{
	try {
		if $Data(@pWhere@(pDocumentID)) {
			kill @pWhere@(pDocumentID)
		}
		else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$DeleteObjectNotFound,pWhere,pDocumentID,pWhere))
		}
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	quit tStatus
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
ClassMethod OpenDocument(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, Output pStatus As %Status = "") As %ZEN.proxyObject
{
	try {
		if $Data(@pWhere@(pDocumentID)) {
			set tObjectID = $Order(@pWhere@(pDocumentID,""),1,tType)
			if tObjectID '= "" {
				if tType = "" {
					set tMe = ..%New()
				}
				else {
					set tMe = ##class(%Library.ListOfDataTypes).%New()
				}
				set tOQ = 1, tOQPtr = 1
					// Initialize the Object Queue
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
						if (tOQ(tOQPtr,1).%IsA("%ZEN.proxyObject")) {
							set $property(tOQ(tOQPtr,1),tOQ(tOQPtr,2)) = tObject
						}
						else {
							do $method(tOQ(tOQPtr,1),"InsertAt",tObject,tOQ(tOQPtr,2))
						}
					}
						// If we stop supporting generic collection objects for dynamic lists then we can change this code.
					if (tObject.%IsA("%ZEN.proxyObject")) {
						do ..loadObject(tObject,pWhere,pDocumentID,tObjectID,.tOQ,.tOREF)
					}
					else {
						do ..loadList(tObject,pWhere,pDocumentID,tObjectID,.tOQ,.tOREF)
					}

					set tOQPtr = $Order(tOQ(tOQPtr))
				} while tOQPtr
				set pStatus = $$$OK
			}
			else {
				set tMe = ..%New()
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

/// OpenEmbeddedDocument will retrieve a document embedded in a previously saved document from the specified global or local variable reference (GLVN) with the specified <var>pDocumentID</var> 
/// and return an oref referencing an instance of %ZEN.proxyObject. 
/// If a document with the specified documentID does not exist in that GLVN then OpenDocument will return an error in the output pStatus parameter. 
/// If an embedded document with the specified objectID does not exist in that GLVN then OpenDocument will return an error in the output pStatus parameter. 
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
/// 				<p>The ID of the document containing the embedded document.</p>
/// 		</td>
/// <tr>
/// <tr>
/// 		<td>pObjectID</td>
/// 		<td>Input</td>
/// 		<td>
/// 				<p>The objectID of the document embedded in the specified <var>pDocumentID</var>.</p>
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
ClassMethod OpenEmbeddedDocument(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, pObjectID As %ZEN.Datatype.string, Output pStatus As %Status = "") As %ZEN.proxyObject
{
	try {
		if $Data(@pWhere@(pDocumentID,pObjectID),tType) {
			if tType = "" {
				set tMe = ..%New()
			}
			else {
				set tMe = ##class(%Library.ListOfDataTypes).%New()
			}
			set tOQ = 1, tOQPtr = 1
				// Initialize the Object Queue
				//	tOQ(ptr) is the object ID
				//	tOQ(ptr,0) is the object Type - null or 'list'
				//	tOQ(ptr,1) is the containing object's oref
				//	tOQ(ptr,2) is the containing object's property
			set tOQ(1) = pObjectID, tOQ(1,0) = tMe, tOQ(1,1) = ""
			do {
				set tObjectID = tOQ(tOQPtr)
				set tObject = tOQ(tOQPtr,0)
					// tOREF is an index on objectID so that we can resolve object references from multiple properties/objects
				set tOREF(tObjectID) = tObject
				if $Isobject(tOQ(tOQPtr,1)) {
					if (tOQ(tOQPtr,1).%IsA("%ZEN.proxyObject")) {
						set $property(tOQ(tOQPtr,1),tOQ(tOQPtr,2)) = tObject
					}
					else {
						do $method(tOQ(tOQPtr,1),"InsertAt",tObject,tOQ(tOQPtr,2))
					}
				}
					// If we stop supporting generic collection objects for dynamic lists then we can change this code.
				if (tObject.%IsA("%ZEN.proxyObject")) {
					do ..loadObject(tObject,pWhere,pDocumentID,tObjectID,.tOQ,.tOREF)
				}
				else {
					do ..loadList(tObject,pWhere,pDocumentID,tObjectID,.tOQ,.tOREF)
				}
				set tOQPtr = $Order(tOQ(tOQPtr))
			} while tOQPtr
			set pStatus = $$$OK
		}
		else {
				// Document doesn't exist
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LoadObjectNotFound,pWhere,pDocumentID))
		}
	}
	catch tException {
		set pStatus = tException.AsStatus()
	}
	quit tMe
}

/// SaveDocument will save the proxyObject to a global or local variable reference (GLVN) with the specified <var>pDocumentID</var>.
/// If a document with the same ID already exists in that GLVN then SaveDocument will return an error in the returned %Status value.
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
/// 				<p>The document ID. This value must be unique within the GLVN specified in <var>pWhere</var>.</p>
/// 		</td>
/// </tr>
/// </table>
/// </p>
Method SaveDocument(pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string = "") As %Status
{
#define pdbEncodeLiteral(%value)			$select(%value="":"",'$f("@#",$e(%value)):%value,1:"/"_%value)
	// Internal Document reference
#define pdbEncodeReference(%value)			$select(%value'="":"@"_%value,1:"")
	// Reference to any Cache Object
#define pdbEncodeObject(%value)				$select(%value'="":"#"_%value,1:"")

	try {
		if pDocumentID = "" { set pDocumentID = .."_documentID" }
		if $Data(@pWhere@(pDocumentID)) {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$IDKeyNotUnique,pWhere,pDocumentID,pWhere))
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
			if tObject.%IsA("%ZEN.proxyObject") {
				set tProperty = $Order(tObject.%data(""),1,tValue)
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
						elseif (tValue.%IsA("%ZEN.proxyObject")) || (tValue.%IsA("%Collection.AbstractList")) {
							set tOQ = tOQ + 1
							set tOQ(tOQ) = tValue
							set tOQ(tOQ,1) = tObjectID
							set tOQ(tOQ,2) = tProperty
						}
						else {
			/// TODO: This is some other object - just serialize it and get its ID
						}
						set tProperty = $Order(tObject.%data(tProperty),1,tValue)
					} while tProperty '= ""
				}
				set @pWhere@(pDocumentID,tObjectID) = ""
			}
			elseif tObject.%IsA("%Collection.AbstractList") {
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
						elseif tValue.%IsA("%ZEN.proxyObject") {
								// This mechanism does not allow for one oref to be referenced from multiple locations
							set tOQ = tOQ + 1
							set tOQ(tOQ) = tValue
							set tOQ(tOQ,1) = tObjectID
							set tOQ(tOQ,2) = tElement
						}
						else {
			/// TODO: This is some other object - just serialize it and get its ID
						}
						set tValue = tObject.GetNext(.tElement)
					} while tElement '= ""
				}
				set @pWhere@(pDocumentID,tObjectID) = "list"
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

ClassMethod loadObject(pObject As %Library.RegisteredObject, pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, pObjectID As %ZEN.Datatype.integer, ByRef pOQ, ByRef pOREF) [ Internal ]
{
	set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,""),1,tValue)
	if tProperty '= "" {
		do {
			if ('$Find("#@",$Extract(tValue))) || (tValue = "") {
				if '$Find("/@/#",$Extract(tValue,1,2)) {
					set $property(pObject,tProperty) = tValue
				}
				else {
					set $property(pObject,tProperty) = $Extract(tValue,2,*)
				}
			}
			elseif $Isobject($Get(pOREF($Extract(tValue,2,*)))) {
				set $property(pObject,tProperty) = pOREF(tValue)
			}
			else {
				set tValueType = $Extract(tValue)
				set tObjectID = $Extract(tValue,2,*)
				// Queue the object so we can load it later
				set tType = $Get(@pWhere@(pDocumentID,tObjectID))
				set pOQ = pOQ + 1
				set pOQ(pOQ) = tObjectID
				set pOQ(pOQ,0) = $Select(tType="":##class(%ZEN.proxyObject).%New(),1:##class(%Library.ListOfDataTypes).%New())
				set pOQ(pOQ,1) = pObject
				set pOQ(pOQ,2) = tProperty
			}
			set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,tProperty),1,tValue)
		} while tProperty '= ""
	}
}

ClassMethod loadList(pObject As %Collection.AbstractList, pWhere As %ZEN.Datatype.string, pDocumentID As %ZEN.Datatype.string, pObjectID As %ZEN.Datatype.integer, ByRef pOQ, ByRef pOREF) [ Internal ]
{
	set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,""),1,tValue)
	if tProperty '= "" {
		do {
			if ('$Find("#@",$Extract(tValue))) || (tValue = "") {
				if '$Find("/@/#",$Extract(tValue,1,2)) {
					do pObject.InsertAt(tValue,tProperty)
				}
				else {
					do pObject.InsertAt($Extract(tValue,2,*),tProperty)
				}
			}
			elseif $Isobject($Get(pOREF($Extract(tValue,2,*)))) {
					do pObject.InsertAt($Extract(tValue,2,*),pOREF(tValue))
			}
			else {
				set tValueType = $Extract(tValue)
				set tObjectID = $Extract(tValue,2,*)
				// Queue the object so we can load it later
				set tType = $Get(@pWhere@(pDocumentID,tObjectID))
				set pOQ = pOQ + 1
				set pOQ(pOQ) = tObjectID
				set pOQ(pOQ,0) = $Select(tType="":##class(%ZEN.proxyObject).%New(),1:##class(%Library.ListOfDataTypes).%New())
				set pOQ(pOQ,1) = pObject
				set pOQ(pOQ,2) = tProperty
			}
			set tProperty = $Order(@pWhere@(pDocumentID,pObjectID,tProperty),1,tValue)
		} while tProperty '= ""
	}
}

}
