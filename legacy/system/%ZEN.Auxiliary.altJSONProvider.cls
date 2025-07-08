/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%PVA, %sySystem, %syGluedef)

/// The jsonProvider component provides a way to transport object data between a server and client
/// (and vice versa) using JavaScript Object Notation (commonly abbreviated as JSON), as defined in RFC4627.<br/>
/// JSON format refers to a common JavaScript programming technique where you
/// define a set of one or more objects using object literal syntax:<br/>
/// <example language="JavaScript">
/// var obj = { "name": "Bill" };
/// </example>
/// 
/// The jsonProvider works as follows:
/// <ul>
/// <li>You place an instance of the (invisible) jsonProvider component on your page.</li>
/// <li>You supply a callback method, <property>OnGetTargetObject</property>,
/// that creates an object or set of objects and returns it. This can be an 
/// instance of a specific class or classes or it can use the generic <class>%ZEN.proxyObject</class>.</li>
/// <li>The jsonProvider converts the target object to a set of JavaScript objects
/// when the page is rendered (which you can see if you view the source of the
/// page as sent to the client).</li>
/// <li>The jsonProvider has a client-side method, <method>getContentObject</method>,
/// which returns the client-side version of the target object. This is simply a 
/// graph of generic JavaScript Object objects. These objects will have
/// the same properties and values as the target objects. If the target objects refer
/// to other objects or have collections (literal or object-valued) then the 
/// JavaScript object will have corresponding object or collection properties.</li>
/// <li>The client can modify these client-side objects or replace them completely using
/// the <method>setContentObject</method> method.</li>
/// <li>The client can ship its content objects back to the server for processing by
/// calling the <method>submitContent</method> method. This converts the objects back into
/// server-side objects and invokes the callback method specified by the
/// <property>OnSubmitContent</property> property.</li>
/// <li>The callback defined by <property>OnSubmitContent</property> can modify the objects
/// shipped to it or return a completely different set of objects. This makes it
/// possible to use the jsonProvider as a way to execute different types of server operations.</li>
/// </ul>
/// 
/// Using the jsonProvider component as an object transport has advantages and disadvantages
/// when compared with other mechanisms provided by Zen, such as the built-in transport
/// provided for Zen components. The main advantage is that you can transport data
/// without having to create or modify server classes &mdash; you can ship most any
/// server-side object using this technique. The disadvantages are:
/// <ul>
/// <li>You can ship a set of objects, but the objects must form a graph from a "parent"
/// object down through levels of "children" (this is due to how JSON format data
/// is reconstituted on the client). You cannot have child objects refer to parents, siblings
/// or other objects outside of the graph.</li>
/// <li>This approach uses late binding so it is not as efficient as the code generated
/// approach used by Zen components.</li>
/// <li>Not all object properties are supported: you cannot ship binary streams or
/// values. Only references to "child" objects are transported. Any user-defined Javascript properties whose
/// name starts with "_" (an underscore) are not included in the content shipped back to the server.</li>
/// </ul>
/// 
/// The jsonProvider code may also be invoked from a non-Zen context by calling one of the following APIs:
/// <ul><li><method>%WriteJSONFromArray</method></li>
/// <li><method>%WriteJSONFromObject</method></li>
/// <li><method>%WriteJSONStreamFromArray</method></li>
/// <li><method>%WriteJSONStreamFromObject</method></li>
/// <li><method>%ConvertJSONToObject</method></li></ul>
Class %ZEN.Auxiliary.altJSONProvider Extends %ZEN.Auxiliary.abstractController [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "json";

/// This component is not visible.
Parameter DEFAULTVISIBLE = 0;

/// Class name of the target object expected to be served by this component.
/// Setting the target object will also set this as a side effect.
Property targetClass As %ZEN.Datatype.className;

/// Used to hold the target object.
Property %TargetObject As %RegisteredObject(XMLPROJECTION = "none") [ Internal, Private ];

/// Used to temporarily hold the response object returned by the <method>OnSubmitContent</method> callback.
Property %ObjectReplacement As %RegisteredObject(XMLPROJECTION = "none") [ Internal, Private ];

/// This property contains the JSON-notation content of the target object.<br/>
/// This is automatically set in any of the following ways:
/// <ul>
/// <li>When the server-side <property>OnGetTargetObject</property> callback is called.</li>
/// <li>When the server-side <method>%SetTargetObject</method> method is called.</li>
/// <li>When the client-side <method>setContentObject</method> method is called.</li>
/// <li>When the client-side <method>setContentText</method> method is called.</li>
/// </ul>
/// Use the <method>getContentObject</method> method to get the contents of this property.
Property content As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Run-time value. Set to indicate an error within this component.<br>
/// This is primarily used by controls.
/// It is defined here for flexibility.
Property error As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// User-defined set of parameters. These values are passed on
/// to the user callback function that provides the contents of 
/// this view. Typically this is used to hold search parameters.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// Flags string consisting of character options that control output formatting.<br/>
/// JSON written out using the <property>OnRenderJSON</property> callback is not affected by this value.
/// See the description of method <property>%ObjectToJSON</property>() for a list of options this value may include.
Property %Format As %ZEN.Datatype.string [ InitialExpression = "aceloqtw" ];

/// Supply data for the JSON provider as a set of server objects.<br/>
/// This callback method is invoked when the page containing this jsonProvider is 
/// rendered. It is expected to return (by reference) an instance of the object
/// whose data is to be provided to the client in JSON format.<br/>
/// For example:<br/>
/// <example language="cls!member">
/// Method GetTarget(
/// 	ByRef pParameters As %String,
/// 	Output pObject As %RegisteredObject) As %Status
/// {
///   Set pObject = ##class(MyApp.MyClass).%New()
///   Set pObject.Name = "Bob"
///   Quit $$$OK 
/// }
/// </example>
Property OnGetTargetObject As %ZEN.Datatype.delegator(FORMALSPEC = "&pParameters:%String,*pObject:%RegisteredObject", RETURNTYPE = "%Status");

/// Supply data for the JSON provider as a server-side array.<br/>
/// This callback method is invoked when the page containing this jsonProvider is 
/// rendered.<br/>
/// This callback provides an easy way to ship a set of identical objects to the client
/// by filling in a multidimensional array.
/// The callback method is expected to fill in two structures:<br/>
/// <var>pMetaData</var> is a $List containing the names of the properties
/// of the objects in the order in which they will appear.<br/>
/// <var>pData</var> is an array containing the data. Each node in the array
/// should be a $List containing values for properties. This should match the 
/// meta data provided in <var>pMetaData</var>. The array of data can use any subscript
/// value its wants. It is possible to define a hierarchical array. In this case,
/// children nodes are placed within a parent collection called <var>children</var>.<br/>
/// If this callback is defined, then the <property>OnGetTargetObject</property> callback will not be invoked.
/// For example:<br/>
/// <example language="cls!member">
/// Method GetArray(
/// 	ByRef pParameters As %String,
/// 	Output pMetaData,
/// 	Output pData) As %Status
/// {
///   Set pMetaData = $LB("name","rank","serialNo")
///   Set pData(1) = $LB("Smith","Captain","444-33-2222")
///   Set pData(1,1) = $LB("Jones","Corporal","333-22-3333")
///   Quit $$$OK
/// }
/// </example>
/// 
/// This would result in the two objects being shipped to the client (in JSON format):
/// <example language="javascript">
/// var content = {
/// 	"name": "Smith",
/// 	"rank": "Captain",
/// 	"serialNo": "444-33-2222",
/// 	"children": [
/// 		{
/// 			"name": "Jones",
/// 			"rank": "Corporal",
/// 			"serialNo": "333-22-3333"
/// 		}
/// 	]
/// };
/// </example>
/// 
Property OnGetArray As %ZEN.Datatype.delegator(FORMALSPEC = "&pParameters:%String,*pMetaData,*pData", RETURNTYPE = "%Status");

/// This callback method is invoked when the client submits an object to the
/// server by calling the <method>submitContent</method> method.
/// The callback is passed the submitted object in <var>pSubmitObject</var> after it has 
/// been converted from JSON format back into an object instance. It is also passed the 
/// command string supplied to the <method>submitContent</method> method in <var>pCommand</var>.<br/>
/// If the callback method returns an object via the <var>pResponseObject</var>
/// argument, then this object is returned to the client and becomes the
/// new content of the JSON provider.<br/>
/// For example:<br/>
/// <example language="cls!member">
/// Method SubmitHandler(
/// 	pCommand As %String,
/// 	pProvider As %ZEN.Auxiliary.jsonProvider,
/// 	pSubmitObject As %RegisteredObject,
/// 	Output pResponseObject As %RegisteredObject) As %Status
/// {
///   Set tSC = $$$OK
///   If ($IsObject(pObject)) {
///     Set tSC = pObject.%Save()
///   }
///   Quit tSC
/// }
/// </example>
Property OnSubmitContent As %ZEN.Datatype.delegator(FORMALSPEC = "pCommand:%String,pProvider:%ZEN.Auxiliary.jsonProvider,pSubmitObject:%RegisteredObject,&pResponseObject:%RegisteredObject", RETURNTYPE = "%Status");

/// Optional. If implemented this callback is expected to write out
/// to the current device the contents of a set of related 
/// objects in JSON format.<br/>
/// If present, this overrides the default behavior of this component and the
/// <property>OnGetTargetObject</property> callback is ignored.
Property OnRenderJSON As %ZEN.Datatype.delegator(FORMALSPEC = "&pParameters:%String", RETURNTYPE = "%Status");

/// Optional.
/// When this provider is used as a data controller, this is the name of the property
/// in the JSON data that provides the series names to view connected to the provider.
/// The default is "caption".
Property seriesNameProperty As %ZEN.Datatype.string [ InitialExpression = "caption" ];

/// Indicates what kind of data is supplied by this provider. This can be:
/// "object" (an object or graph of objects) or "array" (an array of objects).<br/>
/// This is set automatically. For custom JSON output, the user specified value is used.
Property contentType As %ZEN.Datatype.string [ Internal ];

/// Optional.
/// If supplied this is an comma-delimited list of property names. These names are used
/// to define the default ordering of properties supplied by this provider.
/// If a property name is in the list but not in the content data, it is used but will have a
/// value of ''. Properties in the content object but not in this list are listed at the end.
Property propertyList As %ZEN.Datatype.csv;

/// Name of class containing callback methods when this provider is used in direct (non-Zen) mode.
/// See <method>%WriteJSONFromArray</method> for details.
Property %containerClass As %ZEN.Datatype.string [ Internal ];

/// Optional. If provided (and no other callbacks are defined), then
/// this is the id of a document interface (subclass of <class>%ZEN.DataModel.AbstractDocument</class>) that is used to supply data to the provider.<br/>
/// A document id takes the form "docName/docInstance", where *docName* is the logical name of a
/// data document and *docInstance* is a instance id.
Property documentId As %ZEN.Datatype.string;

/// Draw JSON output for the target object.
Method %DrawJSON() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $S(..%containerClass="":$$$ZENVAL(value),1:value)
			Set key = ..parameters.Next(key)
		}

		#; draw js to create the graph of objects
		If (..OnRenderJSON '= "") {
			// Let callback do all the work
			Set tSC = ..%OnRenderJSON(.tParms)
			If $$$ISERR(tSC) {
				Write "null"
			}
		}
		ElseIf (..OnGetArray '= "") {
			// get target object instance and dispatch to it
			Set tSC = ..%OnGetArray(.tParms,.tMetaData,.tData)
			If ($$$ISOK(tSC)&&$D(tMetaData)&&$D(tData)) {
				// write out array in JSON format
				Set tSC = ..%ArrayToJSON(.tMetaData,.tData,..%Format)
			}
			Else {
				Write "null"
			}
		}
		ElseIf (..OnGetTargetObject '= "") {
			// get target object instance and dispatch to it
			Set tSC = ..%OnGetTargetObject(.tParms,.tObject)
			If ($$$ISOK(tSC)&&$IsObject(tObject)) {
				If (..targetClass="") {
					Set ..targetClass = $classname(tObject)
				}

				// write out object in JSON format
				Set tSC = ..%ObjectToJSON(tObject,,,..%Format)
			}
			Else {
				Write "null"
			}
		}
		ElseIf ($IsObject(..%TargetObject)) {
			// write out object in JSON format
			Set tSC = ..%ObjectToJSON(..%TargetObject,,,..%Format)
		}
		ElseIf (..documentId'="") {
			// JMD1154
			Set tSC = ##class(%ZEN.DataModel.DocumentUtils).%GetDocument(..documentId,.tParms,.tObject)
			If ($$$ISOK(tSC)&&$IsObject(tObject)) {
				// always set to "object" in this case
				Set ..contentType = "object"
				If (..targetClass="") {
					Set ..targetClass = $classname(tObject)
				}
				// write out object in JSON format
				Set tSC = ..%ObjectToJSON(tObject,,,..%Format)
			}
			Else {
				Write "null"
			}
		}
		Else {
			Write "null"
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set <var>pObject</var> as the target object for this provider.<br/>
/// Set <property>targetClass</property> to the target object class.
Method %SetTargetObject(pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%TargetObject = pObject
		If $IsObject(pObject) {
			Set ..targetClass = $classname(pObject)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Invoke the OnGetArray callback.
Method %OnGetArray(ByRef pParms, Output pMetaData, Output pData) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pObject = ""
		// JMD958
		If (..%containerClass'="") {
			Set tSC = $classmethod(..%containerClass,..OnGetArray,.pParms,.pMetaData,.pData)
		}
		Else {
			Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
			If ($IsObject(tHost) && (..OnGetArray '= "")) {
				Set tSC = $method(tHost,..OnGetArray,.pParms,.pMetaData,.pData)
			}
		}
		// always set to "array" in this case
		Set ..contentType = "array"
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Invoke the OnGetTargetObject callback.
Method %OnGetTargetObject(ByRef pParms, Output pObject As %RegisteredObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pObject = ""
		// JMD958
		If (..%containerClass'="") {
			Set tSC = $classmethod(..%containerClass,..OnGetTargetObject,.pParms,.pObject)
		}
		Else {
			Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
			If ($IsObject(tHost) && (..OnGetTargetObject '= "")) {
				Set tSC = $method(tHost,..OnGetTargetObject,.pParms,.pObject)
			}
		}
		Set:..contentType="" ..contentType = "object"
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Invoke the <property>OnSubmitContent</property> callback.<br/>
/// If <var>pResponseObject</var> is returned, then it is passed back to the client.
Method %OnSubmitContent(pCommand As %String, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
		If ($IsObject(tHost) && (..OnSubmitContent '= "")) {
			Set tSC = $method(tHost,..OnSubmitContent,pCommand,##this,pSubmitObject,.pResponseObject)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Invoke the <property>OnRenderJSON</property> callback.
Method %OnRenderJSON(ByRef pParms) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
		If ($IsObject(tHost) && (..OnRenderJSON '= "")) {
			Set tSC = $method(tHost,..OnRenderJSON,.pParms)
		}
		// assume an object
		Set:..contentType="" ..contentType = "object"
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This server-side method is called by the <method>submitContent</method> method.
Method SubmitToServer(pCommand As %String, pContent As %String, pTargetClass As %String) As %Boolean [ Internal, ZenMethod ]
{
	If (..OnSubmitContent="") {
		Set ..error = $$$Text("JSON Provider does not have a OnSubmitContent callback defined.","%ZEN")
		Quit 0
	}

	// note: pContent *could* be a stream
	Set ..targetClass = pTargetClass
	Set ..error = ""
	Set tSubmitObject = ""

	Set tSC = ..%ParseJSON(pContent,..targetClass,.tSubmitObject)
	If ($$$ISERR(tSC)) {
		Set ..error = $System.Status.GetErrorText(tSC)
		Quit 0
	}

	Set tResponseObject = ""
	Set tSC = ..%OnSubmitContent(pCommand, tSubmitObject,.tResponseObject)
	If (..error'="") {
		// user-reported error
		Quit 0
	}
	If ($$$ISERR(tSC)) {
		Set ..error = $System.Status.GetErrorText(tSC)
		Quit 0
	}

	// if there is a Response object, make sure it gets returned
	// to the client.
	If ($IsObject(tResponseObject)) {
		Set ..%ObjectReplacement = tResponseObject
		Do ..%SetContentModified()
	}
	Quit 1
}

/// This server-side method is called by the <method>submitContent</method> method in async mode.
Method SubmitToServerAsync(pCommand As %String, pContent As %String, pTargetClass As %String) [ Internal, ZenMethod ]
{
	Set tOK = ..SubmitToServer(pCommand,pContent,pTargetClass)

	// notify client: pass error
	&js<
		zenPage.getComponent(#(..index)#).error = '#($ZCVT(..error,"O","JS"))#';
		zenPage.getComponent(#(..index)#).submitHandler(true,false);
	>
}

/// This server-side method is called by the <method>reloadContents</method> method.
Method RefreshFromServer() As %Boolean [ Internal, ZenMethod ]
{
	// This will cause %OnObjectSynch to be fired
	Do ..%SetContentModified()
	Quit 1
}

/// This server-side method is called by the <method>reloadContentsAsynch</method> method.
Method RefreshFromServerAsynch() [ Internal, ZenMethod ]
{
	// This will cause %OnObjectSynch to be fired
	Do ..%SetContentModified()
	// notify client
	&js<zenPage.getComponent(#(..index)#).refreshHandler(true,false);>
}

/// Drill down just enough to find out if the object has any content displayable as JSON given the current <var>pFormat</var> options.
ClassMethod hasObjContent(pObject As %RegisteredObject, ByRef pVisited, pFormat As %String, pRecursing As %Boolean = 0) As %Boolean [ Internal ]
{
	Set tHas = 0
	If 'pRecursing {
		Merge tempVisited=pVisited
	}
	Try {
		If ((pObject="")||'$IsObject(pObject)||($D(pVisited(pObject)))) {
			// cycle
			Set tHas=(pFormat["a") Quit ; "null"
		}
		Set tClass = $classname(pObject)
		If (tClass = "%ZEN.proxyObject") {
			Set tHas = pObject.hasJSONContent(pFormat)
			Quit
		}
		Set pVisited(pObject) = ""
		If pFormat["c" Set tHas=1  Quit ; add class name to model
		
		If pObject.%Extends("%Collection.AbstractArray") {
			Set tHas=1  Quit
		}
		#; main object is not an array collection

		#; loop over properties using class meta-data
		Set tPropName=""  For { Set tPropName = $$$comMemberNext(tClass,$$$cCLASSproperty,tPropName)  Quit:""=tPropName

			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			Continue:tPrivate||(tPropName["%")

			Set tType = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPtype)
			Set tClsType = $$$getClassType(tType)
			Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)
			Set tCollection = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcollection)
			If (tClsType '= "datatype") {
				#; Check for the case where we have a property declared as a %ListOf**
				If ($classmethod(tType,"%IsA","%Collection.AbstractList")) {
					Set tCollection = "list"
					If ($classmethod(tType,"%IsA","%Collection.AbstractListOfDT")) {
						#; Reset object information for %ListOfDataTypes
						Set tClientType = "VARCHAR"
						Set tDataType = ""
					}
				}
			} Else {
				Set tDataType=$Case(tClientType, "BOOLEAN":"b", "INTEGER":"n","NUMERIC":"n","FLOAT":"n", "TIMESTAMP":"u", "DATE":"d", "TIME":"t", :"")
			}
			Set tMultiDim = 0
			If (tCollection="array") {
				Set tCardinality = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcardinality)
				Set tInverse = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPinverse)
				If ((tCardinality'="")&&(tInverse'="")) {
					// treat relationship as list
					Set tCollection = "list"
				}
			} ElseIf (tCollection = "") {
				Set tMultiDim = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPmultidimensional)
			}
			Continue:tMultiDim

			Set tValue = $property(pObject,tPropName)
			#; If the value is "" or $c(0) and we are NOT including empty properties, skip if we are not a collection, object or stream
			If (((tValue = "") || (tValue = $c(0))) && (pFormat'["e") && (tCollection = "") && $Case(tClientType, "HANDLE": 0, "CHARACTERSTREAM": 0, "BINARYSTREAM": 0, :1)) {
				Continue
			}
			// Write the property if not inhibited
			If (tCollection="list") {
				If pFormat["l" Set tHas=1  Quit ; found non-suppressable list

				If $IsObject(tValue) {
					Set tList = tValue
					Set tCount = tList.Count()
				} Else { Set tCount = 0 }
				For n = 1:1:tCount {
					Set tValue = tList.GetAt(n)
					If (tClientType = "HANDLE") {
						If $IsObject(tValue) {
							If ..hasObjContent(tValue,.pVisited,pFormat,1)  Set tHas=1  Quit
						} Else {
							Set tHas=1  Quit ; not conditional because it has to hold the place in the list
						}
					} Else {
						If $S(tDataType="b":1
							, $C(0)=tValue||$ListValid(tValue):pFormat["e"
							//, "dtu"[tDataType:1
							, 1:""'=tValue||(pFormat["e")) {
							Set tHas=1  Quit
						}
					}
				} Quit:tHas
			}
			ElseIf (tCollection="array") {
				// array collection (object on client)
				If pFormat["o" Set tHas=1  Quit ; found non-suppressable array

				If $IsObject(tValue) {
					Set tArray = tValue
					Set tKey = tArray.Next("")
				} Else { Set tKey = "" }
				While (tKey '= "") {
					Set tValue = tArray.GetAt(tKey)

					If (tClientType = "HANDLE") {
						If $IsObject(tValue) {
							If ..hasObjContent(tValue,.pVisited,pFormat,1) Set tHas=1  Quit
						} ElseIf (pFormat["a") {
							Set tHas=1  Quit
						}
					} Else {
						If $S(tDataType="b":1
							, $C(0)=tValue||$ListValid(tValue):pFormat["e"
							//, "dtu"[tDataType:1
							, 1:""'=tValue||(pFormat["e")) {
							Set tHas=1  Quit
						}
					}
					Set tKey = tArray.Next(tKey)
				} Quit:tHas
			}
			ElseIf (tClientType = "HANDLE") {
				If $IsObject(tValue) {
					If ..hasObjContent(tValue,.pVisited,pFormat,1) || (pFormat["o")  {
						Set tHas=1  Quit
					}
				} ElseIf (pFormat["a") {
					Set tHas=1  Quit
				}
			}
			ElseIf (tClientType = "CHARACTERSTREAM") {
				If $IsObject(tValue) {
					If tValue.Size || (pFormat["e") {
						Set tHas=1  Quit
					}
				} ElseIf (pFormat["a") {
					Set tHas=1  Quit
				}
			}
			ElseIf (tClientType = "BINARYSTREAM") {
				Set tHas=1  Quit
			}
			Else {
				If $S(tDataType="b":1
					, $C(0)=tValue||$ListValid(tValue):pFormat["e"
					//, "dtu"[tDataType:1
					, 1:""'=tValue||(pFormat["e")) {
					Set tHas=1  Quit
				}
			}
		} ; end properties loop
	}
	Catch ex {
		Set tHas=0
	}
	If 'pRecursing {
		Kill pVisited  Merge pVisited=tempVisited  ; restore
	}
	Quit tHas
}

/// Repack the contents of a Zen proxy object to an abstract entity tree.<br/>
/// <var>pFormat</var> is a flags string to control output formatting options.<br/>
/// The following character option codes are supported:<br/>
/// c - output the ObjectScript-specific "_class" and "_id" properties (if a child property is an instance of a concrete object class)<br/>
ClassMethod %ZPOToAET(pZPO As %ZEN.proxyObject, pLevel As %Integer = 0, pFormat As %String = "aelo") As %DynamicAbstractObject [ Internal ]
{
	Set aet = ##class(%DynamicObject).%New()
	Set tSC = $$$OK
	Try {
		Set tAbort = 0
		Set tProp="" 
		Set tProp=$O(pZPO.%data(tProp),1,tValue)
 		While (tProp'="" && 'tAbort) {
 			If $IsObject(tValue) {
				If tValue.%IsA("%ZEN.proxyObject") {
  						Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ZPOToAET(tValue,pLevel+1,pFormat)
						If (aetValue = -1) Set tAbort = 1
				} 
				Else {
  					Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(tValue,.tVisited, pLevel+1, pFormat)
					If (aetValue = -1) Set tAbort = 1
				}
			} 
			Else {
  				Set aetValue = tValue
			}
			If ('tAbort) {
				If ($IsValidNum(aetValue)) {
					Do aet.%Set(tProp,$FN(aetValue,"LON"),"number")
				}
				Else {
					Do aet.%Set(tProp,aetValue)
				}
				Set tProp=$O(pZPO.%data(tProp),1,tValue)
			}
 		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set aet = -1
	}
	Quit aet
}

/// Convert an instance of AbstractList to an AET structure
/// returning that structure is successful or -1 if the
/// structure cannot be converted for some reason
ClassMethod %AbstractListToAET(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "acelo") As %DynamicAbstractObject [ Internal ]
{
	Set tAbort = 0
 	Set aet = ##class(%DynamicArray).%New()
	Set tList = pObject
	Set tCount = tList.Count()
	For n = 1:1:tCount {
		If ('tAbort) {
			Set tValue = tList.GetAt(n)
			If $IsObject(tValue) {
				If (tValue.%IsA("%ZEN.proxyObject")) {
					Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ZPOToAET(tValue,pLevel,pFormat)
					If (aetValue = -1) Set tAbort = 1 
				} 
				Else {
	  				Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(tValue,.pVisited, pLevel+1, pFormat)
					If (aetValue = -1) Set tAbort = 1
				}
				Do aet.%Push(aetValue)
			} Else {
				Do aet.%Push(tValue)
  			}
		}
	}
	If (tAbort) Set aet = -1
	Quit aet
}

/// Convert an instance of AbstractArray to an AET structure
/// returning that structure is successful or -1 if the
/// structure cannot be converted for some reason
ClassMethod %AbstractArrayToAET(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "acelo") As %DynamicAbstractObject [ Internal ]
{
	Set tAbort = 0
	Set aet = ##class(%DynamicObject).%New()
	Set tClass = $classname(pObject)
 	If pFormat["c" {
		Do aet.%Set("_class",tClass)
		// add id for persistent objects
		If (pObject.%IsA("%Library.Persistent")) {
			Set tID = pObject.%Id()
			Do aet.%Set("_id",$Num(tID),"number")
		}
	}

	If pObject.%Extends("%Collection.AbstractArrayOfObj") { // object elements
		Set tKey=""
		Set tValue = pObject.GetNext(.tKey) 
		While tKey'="", tAbort=0 {
			If $IsObject(tValue) {
				If tValue.%Extends("%Stream.Object")||tValue.%Extends("%IO.I.Stream") {
					//DAO DOES NOT CURRENTLY SUPPORT STREAM PROPERTIES, NEED TO ABORT
					Set tAbort = 1
				} 
				Else {
					Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(tValue,.pVisited, pLevel+1,pFormat)
					If (aetValue = -1) {
						Set tAbort = 1
					}
					Else {
						If ($IsValidNum(aetValue)) {
							Do aet.%Set(tKey,$FN(aetValue,"LON"),"number")
						}
						Else {
							Do aet.%Set(tKey,aetValue)
						}
					}
				}
			} 
			Else {
				Do aet.%Set(tKey,"")
			}
			Set tValue = pObject.GetNext(.tKey)  
		} // END PROPERTY WHILE
	} // END ARRAY OF OBJECT
	Else { // scalar array elements
		Set tKey=""  For { Set tValue = pObject.GetNext(.tKey)  Quit:""=tKey
			If ($IsValidNum(tValue)) {
				Do aet.%Set(tKey,$FN(tValue,"LON"),"number")
			}
			Else {
				Do aet.%Set(tKey,tValue)
			}
		} // end tKey scalar array loop
	}
	If (tAbort) Set aet = -1
	Quit aet
}

/// Convert an instance of a COS Object to an AET structure
/// returning that structure is successful or -1 if the
/// structure cannot be converted for some reason
ClassMethod %COSObjectToAET(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "acelo") As %DynamicAbstractObject [ Internal ]
{
	Set tAbort = 0
 	If pObject.%Extends("%Collection.AbstractArray") {
 		Set aet = ##class(%ZEN.Auxiliary.altJSONProvider).%AbstractArrayToAET(pObject,.pVisited, pLevel+1,pFormat)
	}
	Else {
		Set tClass = $classname(pObject)
		#; else: main object is not a collection
 		#; loop over properties using class meta-data			
		Set aet = ##class(%DynamicObject).%New()
		If pFormat["c" {
			Do aet.%Set("_class",tClass)
			// add id for persistent objects
			If (pObject.%IsA("%Library.Persistent")) {
				Set tID = pObject.%Id()
				Do aet.%Set("_id",$Num(tID),"number")
			}
		}
 		Do ..getOrderedProps(tClass,.tProps)
					
		Set tSeq=""
		Set tSeq=$O(tProps(tSeq),1,tPropName)
		While (tSeq'="") {
			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			If (tPrivate||(tPropName["%")) {
			}
			Else {
				Set tType = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPtype)
				Set tClsType = $$$getClassType(tType)
				Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)
				Set tCollection = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcollection)
				If (tClsType '= "datatype") {
					#; Check for the case where we have a property declared as a %ListOf**
					If ($classmethod(tType,"%IsA","%Collection.AbstractList")) {
						Set tCollection = "list"
						If ($classmethod(tType,"%IsA","%Collection.AbstractListOfDT")) {
							#; Reset object information for %ListOfDataTypes
							Set tClientType = "VARCHAR"
							Set tDataType = ""
						}
					}
				} Else {
					Set tDataType=$Case(tClientType, "BOOLEAN":"b", "INTEGER":"n","NUMERIC":"n","FLOAT":"n", "TIMESTAMP":"u", "DATE":"d", "TIME":"t", :"")
				}
				Set tMultiDim = 0
				If (tCollection="array") {
					Set tCardinality = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcardinality)
					Set tInverse = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPinverse)
					If ((tCardinality'="")&&(tInverse'="")) {
						// treat relationship as list
						Set tCollection = "list"
					}
				} 
				ElseIf (tCollection = "") {
					Set tMultiDim = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPmultidimensional)
				}
				
				If ('tMultiDim) {
					Set tValue = $property(pObject,tPropName)
					If (tCollection="list") { // list collection
						If '$IsObject(tValue) {
							Set tCount = 0
						} Else {
							Set tList = tValue
							Set tCount = tList.Count()
						}
						Set nestedAET = ##class(%DynamicArray).%New()
						For n = 1:1:tCount {
							If ('tAbort) {
							 	Set tValue = tList.GetAt(n)		
								If ($IsObject(tValue)) {
									Set tClassName = tValue.%ClassName()
									If (tClassName = "%DynamicObject") Set tClientType = "HANDLE"
									If (tClassName = "%ZEN.proxyObject") Set tClientType = "HANDLE"
									If (tClassName = "%DynamicArray") Set tClientType = "HANDLE"
								}
	
								If (tClientType = "HANDLE") { // object items
									If $IsObject(tValue) {
										Set aetValue = ..%ObjectToAET(tValue,.pVisited, pLevel+1, pFormat)
										If (aetValue = -1) {
											Set tAbort = 1
											Set nestedAET = -1
										}
										Else {
											Do nestedAET.%Push(aetValue)
										}
									} Else {
										Do nestedAET.%Push("") // not conditional because it has to hold the place in the list
									}
								} 
								Else { // scalar array item ; converts $List to empty string!
									If (tDataType="b") {
										Do nestedAET.%Push(tValue,"boolean")
									} 
									Else {
										Set jsonValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ConvertAETScalar(tValue,tDataType,pFormat)
										Do nestedAET.%Push(jsonValue)
									}
								}
							}
						}
						If (nestedAET = -1) {
							Set tAbort = 1
							Set aet = -1
						}
						Else {
							Do aet.%Set(tPropName, nestedAET)
						}
					} // END COLLECTION LIST PROCESSING
								
					ElseIf (tCollection="array") {
						// array collection (object on client)
						If '$IsObject(tValue) {
							Set tKey = ""
						} Else {
							Set tArray = tValue
							Set tKey = tArray.Next("")
						}
						Set nestedAET = ##class(%DynamicObject).%New()
						If ('tAbort) Set tAbort = 0
						While (tKey '= "" && 'tAbort) { 
							Set tValue = tArray.GetAt(tKey)
							If (tClientType = "HANDLE") { // object elements
								If $IsObject(tValue) {
									Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(tValue,.pVisited, pLevel+1, pFormat)
									If (aetValue = -1) {
										Set tAbort = 1
										Set nestedAET = -1
									}
									Else {
										If ($IsValidNum(aetValue)) {
											Do nestedAET.%Set(tKey,$FN(aetValue,"LON"),"number")
										}
										Else {
											Do nestedAET.%Set(tKey,aetValue)
										}
									}
								} 
								Else {
									Do nestedAET.%Set(tKey,"")
								}
							} Else { // scalar array item ; converts $List to empty string!
								If (tDataType="b") {
									Do nestedAET.%Set(tPropName,tValue,"boolean")
								} 
								Else {
									Do nestedAET.%Set(tKey,##class(%ZEN.Auxiliary.altJSONProvider).%ConvertAETScalar(tValue,tDataType,pFormat))
								}
							}
							Set tKey = tArray.Next(tKey)
						}
						If (nestedAET = -1) {
							Set aet = -1
							Set tAbort = 1
						}
						Else {
							Do aet.%Set(tPropName,nestedAET)	
						}
					}  //END OF COLLECTION ARRAY PROCESSING
								
					ElseIf (tClientType = "HANDLE") {
						// object
						If $IsObject(tValue) {
							Set aetValue = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(tValue,.pVisited, pLevel+1, pFormat)
							If (aetValue = -1) {
								Set aet = -1
								Set tAbort = 1
							}
							Else {
								If ($IsValidNum(aetValue)) {
									Do aet.%Set(tPropName,$FN(aetValue,"LON"),"number")
								}
								Else {
									Do aet.%Set(tPropName,aetValue)
								}
							}
						} 
						Else {
							Do aet.%Set(tPropName,"")
						}
					} // END OF HANDLE PROCESSING (done)
								
					ElseIf (tClientType = "CHARACTERSTREAM") {
						If $IsObject(tValue) {
							// STREAMS NOT SUPPORTED BY DAO AT THIS POINT
							Set tAbort = 1
							Set aet = -1
						}
						Else {
							Do aet.%Set(tPropName,"")
						}
					} // END OF CHARACTER STREAM PROCESSING (done)
								
					ElseIf (tClientType = "BINARYSTREAM") {
						Do aet.%Set(tPropName,"")
					} // END OF BINARY STREAM PROCESSING (done - legacy behavior is to null out)
								
					Else {
						#; scalar item ; converts $List to empty string!
						If (tDataType="b") {
							Do aet.%Set(tPropName,tValue,"boolean")
						} 
						Else {
							Do aet.%Set(tPropName,##class(%ZEN.Auxiliary.altJSONProvider).%ConvertAETScalar(tValue,tDataType,pFormat))
						}
					} // END OF SCALAR PROCESSING (done)
								
				} //END OF SKIP MULTIDIMENSIONAL
			} // END OF SKIP PRIVATE AND SYSTEM STUFF
			Set tSeq=$O(tProps(tSeq),1,tPropName)

		} ; end properties loop
	}
	If (tAbort) Set aet = -1
	Quit aet
}

/// Convert the contents of object instance <var>pObject</var> to
/// an abstract entity tree.
/// <var>pFormat</var> is a flags string to control output options.</br>
/// The following character option codes are supported:<br/>
/// c - output the ObjectScript-specific "_class" and "_id" properties<br/>
/// d - output numeric properties that have value "" as null<br/>
ClassMethod %ObjectToAET(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "acelo") As %DynamicAbstractObject
{
	Try {
		// OBJECT IS NULL
		If ((pObject="")||'$IsObject(pObject)||($D(pVisited(pObject)))) { // cycle
			Set aet = ""
		}
		Else {
			Set pVisited(pObject) = ""
			Set tClass = $classname(pObject)
 
	 		// OBJECT IS ZPO
 			If (tClass = "%ZEN.proxyObject") {
				Set aet = ##class(%ZEN.Auxiliary.altJSONProvider).%ZPOToAET(pObject,pLevel,pFormat)
			}
			ElseIf ((tClass = "%Library.DynamicObject") || (tClass = "%Library.DynamicArray")) {
				Set aet = pObject
				If (pFormat["c") && (tClass = "%Library.DynamicObject") {
					Do aet.%Set("_class",tClass)
				}
			}
			ElseIf (pObject.%Extends("%Stream.Object")) {
				// CURRENTLY DAO CAN'T HANDLE THIS CASE
				// need to abort and use old jsonProvider scheme
				Set aet = -1
			}		 
 			ElseIf (pObject.%Extends("%Collection.AbstractList")) {
	 			Set aet = ##class(%ZEN.Auxiliary.altJSONProvider).%AbstractListToAET(pObject,.pVisited, pLevel+1, pFormat)
			}
			Else {
				 //IF WE MADE IT THIS FAR WE'RE EXTENDING OBJECT
	 			Set aet = ##class(%ZEN.Auxiliary.altJSONProvider).%COSObjectToAET(pObject,.pVisited, pLevel+1, pFormat)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Set aet = -1
	}

	Quit aet
}

ClassMethod %ConvertAETScalar(pValue As %String, pDataType As %String, pFormat As %String) As %String [ Internal ]
{
	Set tStr = pValue
	If (($C(0)=pValue)||$ListValid(pValue)) {
		Set tStr = ""
	}
	Elseif ((pDataType="n")&&(pValue="")&&(pFormat["d")) {
		Set tStr = ""
	}
	Elseif ((pDataType="n")&&$$$ZENJSISNUM(pValue)) {
		Set tStr = $$$ZENJSNUM(pValue)
	}
	Quit tStr
}

/// Write out the contents of object instance <var>pObject</var> to
/// the current device using JSON notation.
ClassMethod %ObjectToJSON(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "aceloqstw") As %Status
{
	Set tSC = $$$OK
	Try {
 // IF pLevel = 0 Try to make an AET, if that works call $toJSON on the root and
 // call it a day.  If no AET is produced (for whatever reason) back off to the old 
 // zen json provider behavior
 		Set tAET = ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(pObject, .pVisited, pLevel, pFormat)
 		If ($IsObject(tAET)) {
	 		Write tAET.%ToJSON()
	 		Write ""
			Quit
 		}	
 // Old jsonProvider scheme:		
	/*
		If ((pObject="")||'$IsObject(pObject)||((pVisited'="")&&($D(pVisited(pObject))))) {
			// cycle
			Write:pFormat["a"||'pLevel "null"
			Quit
		}
		Set pVisited(pObject) = ""
	*/
		Set tClass = $classname(pObject)
		If (tClass = "%ZEN.proxyObject") {
			Set tSC = pObject.%ToJSON(pLevel,pFormat)
			Quit
		}
		Set tLF=$S(pFormat["w":$C(13,10), pFormat["n":$C(10), 1:"")
		If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,pFormat["t":1,1:4))="" }
		Else { Set tTab="" }
		Set tIncludeWhitespace = (tLF_tTab'="")

		If (pObject.%Extends("%Collection.AbstractList")) {
			Set tList = pObject
			Set tCount = tList.Count()
			If (pFormat["l" || tCount) {
				Write "["
				For n = 1:1:tCount {
					Set tValue = tList.GetAt(n)
					Write:n>1 ","
					If $IsObject(tValue) {
						If (tValue.%IsA("%ZEN.proxyObject")) {
							Set tSC = tValue.%ToJSON(pLevel+1,pFormat)
							Quit:$$$ISERR(tSC)
						} Else {
							Set tSC = ..%ObjectToJSON(tValue,.pVisited, pLevel+1, pFormat)
							Quit:$$$ISERR(tSC)
						}
					} Else {
						Write $$$ZENJSONVALUE(tValue,pFormat)
					}
				}
				Quit:$$$ISERR(tSC)
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write tLF_tIndent
				Write "]"
			}
			Quit
		}
		ElseIf (pObject.%Extends("%Stream.Object")) {
			Write """"
			#; Initialize stream read length, if needed
			If '$data(tStreamMaxReadLen) Set tStreamMaxReadLen = ($$$MaxLocalLength\2)
			Do pObject.Rewind()
			While 'pObject.AtEnd {
				Write $$$ZENJSONESCAPE(pObject.Read(tStreamMaxReadLen),pFormat)
			}
			Write """"
			Quit
		}

		If pFormat["o" || 'pLevel {
			Set tPropCount = ""
			If (tIncludeWhitespace && pLevel) Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write $S(pFormat["b":tLF_tIndent,1:" ")
			Write "{"
		} Else {
			Set tPropCount = 0
		}
		If pFormat["c" {
			// add class name to model
			Do nextProp
			Write $$$ZENJSONPAIR("_class",tClass,pFormat)
			// add id for persistent objects
			If (pObject.%IsA("%Library.Persistent")) {
				Do nextProp
				Set tID = pObject.%Id()
				Write $$$ZENJSONPAIR("_id",tID,pFormat)
			}
		}

		#; Special treatment for top-level array: output no matter what
		If pObject.%Extends("%Collection.AbstractArray") {
			#; write out (eligible) array elements/properties
			If pObject.%Extends("%Collection.AbstractArrayOfObj") {
				#; object elements
				Set tKey=""  For { Set tValue = pObject.GetNext(.tKey)  Quit:""=tKey
					If $IsObject(tValue) {
						If tValue.%Extends("%Stream.Object")||tValue.%Extends("%IO.I.Stream") {
							Do tValue.Rewind()
							If (pFormat["e" || tValue.Size()) {
								Do nextProp
								Write $$$ZENJSONPROP(tKey,pFormat)_":"""
								#; Initialize stream read length, if needed
								If '$data(tStreamMaxReadLen) Set tStreamMaxReadLen = ($$$MaxLocalLength\2)
								#; Rewind non-%IO streams if needed
								If tValue.AtEnd && tValue.%Extends("%Stream.Object") Do tValue.Rewind()
								While 'tValue.AtEnd {
									Write $$$ZENJSONESCAPE(tValue.Read(tStreamMaxReadLen),pFormat)
								}
								Write """"
							}
						} ElseIf pFormat["o" || ..hasObjContent(tValue,.pVisited,pFormat) {
							Do nextProp
							Write $$$ZENJSONPROP(tKey,pFormat)_":"
							Set tSC = ..%ObjectToJSON(tValue,.pVisited, pLevel+1,pFormat)
							Quit:$$$ISERR(tSC)
						}
					} ElseIf pFormat["a" {
						Do nextProp
						Write $$$ZENJSONPROP(tKey,pFormat)_":null"
					}
				} ; end tKey object array loop
			} Else {
				#; scalar array elements
				Set tKey=""  For { Set tValue = pObject.GetNext(.tKey)  Quit:""=tKey
					If (pFormat["e") || (tValue'="") {
						Do nextProp
						Write $$$ZENJSONPAIR(tKey,tValue,pFormat)
					}
				} ; end tKey scalar array loop
			}
			If tPropCount'=0 {
				#; either we wrote at least one property or we wrote an empty '{' due to "o" mode or level zero
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write tLF_tIndent
				Write "}"
			}
			Quit
		}
		#; else: main object is not a collection

		#; loop over properties using class meta-data
		Do ..getOrderedProps(tClass,.tProps)
		Set tSeq="" For { Set tSeq=$O(tProps(tSeq),1,tPropName)  Quit:""=tSeq

			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			Continue:tPrivate||(tPropName["%")

			Set tType = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPtype)
			Set tClsType = $$$getClassType(tType)
			Set tClientType = $$$comClassKeyGet(tType,$$$cCLASSclientdatatype)
			Set tCollection = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcollection)
			If (tClsType '= "datatype") {
				#; Check for the case where we have a property declared as a %ListOf**
				If ($classmethod(tType,"%IsA","%Collection.AbstractList")) {
					Set tCollection = "list"
					If ($classmethod(tType,"%IsA","%Collection.AbstractListOfDT")) {
						#; Reset object information for %ListOfDataTypes
						Set tClientType = "VARCHAR"
						Set tDataType = ""
					}
				}
			} Else {
				Set tDataType=$Case(tClientType, "BOOLEAN":"b", "INTEGER":"n","NUMERIC":"n","FLOAT":"n", "TIMESTAMP":"u", "DATE":"d", "TIME":"t", :"")
			}
			Set tMultiDim = 0
			If (tCollection="array") {
				Set tCardinality = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcardinality)
				Set tInverse = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPinverse)
				If ((tCardinality'="")&&(tInverse'="")) {
					// treat relationship as list
					Set tCollection = "list"
				}
			} ElseIf (tCollection = "") {
				Set tMultiDim = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPmultidimensional)
			}
			Continue:tMultiDim

			Set tValue = $property(pObject,tPropName)
			#; If the value is "" or $c(0) and we are NOT including empty properties, skip if we are not a collection, object or stream
			If (((tValue = "") || (tValue = $c(0))) && (pFormat'["e") && (tCollection = "") && $Case(tClientType, "HANDLE": 0, "CHARACTERSTREAM": 0, "BINARYSTREAM": 0, :1)) {
				Continue
			}
			// Write the property if not inhibited
			If (tCollection="list") {
				// list collection
				If '$IsObject(tValue) {
					Set tCount = 0
				} Else {
					Set tList = tValue
					Set tCount = tList.Count()
				}
				If (pFormat["l" || tCount) {
					Do nextProp
					Write $$$ZENJSONPROP(tPropName,pFormat)_":["
					For n = 1:1:tCount {
						Set tValue = tList.GetAt(n)
						Write:n>1 ","
						If (tClientType = "HANDLE") {
							#; object items
							If $IsObject(tValue) {
								Set tSC = ..%ObjectToJSON(tValue,.pVisited, pLevel+1, pFormat)
								Quit:$$$ISERR(tSC)
							} Else {
								Write "null" ; not conditional because it has to hold the place in the list
							}
						} Else {
							#; scalar list item ; converts $List to empty string!
							Write $S((tDataType="b")&&(pFormat["e"):$S(tValue=1:"true",tValue=0:"false",1:"null")
								, (tDataType="b"):$S(tValue:"true",1:"false")
								, ((tDataType="n")||(pFormat["q"))&&$$$ZENJSISNUM(tValue):$$$ZENJSNUM(tValue)
								, (tDataType="n")&&(tValue="")&&(pFormat["d"):"null"
								, ($C(0)=tValue)||$ListValid(tValue):""""""
								, 1:$$$ZENJSONSTR(tValue,pFormat))
						}
					}
					Write "]"
				}
			}
			ElseIf (tCollection="array") {
				// array collection (object on client)
				If '$IsObject(tValue) {
					Set tKey = ""
				} Else {
					Set tArray = tValue
					Set tKey = tArray.Next("")
					If pFormat'["o" && (""'=tKey) {
						#; look ahead to see if there is any content
						Set tHasArrayContent=0, k=tKey  While (k '= "") { Set tValue = tArray.GetAt(k)
							If (tClientType = "HANDLE") {
								If $IsObject(tValue) {
									If ..hasObjContent(tValue,.pVisited,pFormat) Set tHasArrayContent=1  Quit
								} ElseIf (pFormat["a") {
									Set tHasArrayContent=1  Quit
								}
							} Else {
								If $S(tDataType="b":1
									, $C(0)=tValue||$ListValid(tValue):pFormat["e"
									//, "dtu"[tDataType:$S(pFormat["u":$$$ZENJSUSTR(..formatDateTime(tValue,tType,tDataType,pFormat)), 1:$$$ZENJSSTR(..formatDateTime(tValue,tType,tDataType,pFormat)))
									, 1:""'=tValue||(pFormat["e")) {
									Set tHasArrayContent=1  Quit
								}
							}
							Set k = tArray.Next(k)
						}
					}
				}
				If (pFormat["o" || (""'=tKey && tHasArrayContent)) {
					Do nextProp
					Write $$$ZENJSONPROP(tPropName,pFormat)_": {"
					Set n = 0
					While (tKey '= "") { Set tValue = tArray.GetAt(tKey)
						If (tClientType = "HANDLE") {
							#; object elements
							If $IsObject(tValue) {
								Set n = n+1
								Write $S(n>1:",",1:"")_$$$ZENJSONPROP(tKey,pFormat)_":"
								Set tSC = ..%ObjectToJSON(tValue,.pVisited, pLevel+1, pFormat)
								Quit:$$$ISERR(tSC)
							} ElseIf (pFormat["a") {
								Set n = n+1
								Write $S(n>1:",",1:"")_$$$ZENJSONPROP(tKey,pFormat)_":null"
							}
						} Else {
							#; scalar array item ; converts $List to empty string!
							Set tStr = $S((tDataType="b")&&(pFormat["e"):$S(tValue=1:"true",tValue=0:"false",1:"null")
								, (tDataType="b"):$S(tValue:"true",1:"false")
								, ((tDataType="n")||(pFormat["q"))&&$$$ZENJSISNUM(tValue):$$$ZENJSNUM(tValue)
								, (tDataType="n")&&(tValue="")&&(pFormat["d"):"null"
								, ($C(0)=tValue)||$ListValid(tValue):""""""
								//, "dtu"[tDataType:$S(pFormat["u":$$$ZENJSUSTR(..formatDateTime(tValue,tType,tDataType,pFormat)), 1:$$$ZENJSSTR(..formatDateTime(tValue,tType,tDataType,pFormat)))
								, 1:$$$ZENJSONSTR(tValue,pFormat))
							If (pFormat["e") || (tStr'="""""") {
								Set n = n+1
								Write $S(n>1:",",1:"")_$$$ZENJSONPROP(tKey,pFormat)_":"_tStr
							}
						}
						Set tKey = tArray.Next(tKey)
					}
					Write "}"
				}
			}
			ElseIf (tClientType = "HANDLE") {
				// object
				If $IsObject(tValue) {
					If ..hasObjContent(tValue,.pVisited,pFormat) || (pFormat["o")  {
						Do nextProp
						Write $$$ZENJSONPROP(tPropName,pFormat)_":"
						Set tSC = ..%ObjectToJSON(tValue,.pVisited, pLevel+1, pFormat)
						Quit:$$$ISERR(tSC)
					}
				} ElseIf (pFormat["a") {
					Do nextProp
					Write $$$ZENJSONPROP(tPropName,pFormat)_":null"
				}
			}
			ElseIf (tClientType = "CHARACTERSTREAM") {
				If $IsObject(tValue) {
					If tValue.Size || (pFormat["e") {
						Do nextProp
						Write $$$ZENJSONPROP(tPropName,pFormat)_":"""
						If tValue.Size {
							#; Initialize stream read length, if needed
							If '$data(tStreamMaxReadLen) Set tStreamMaxReadLen = ($$$MaxLocalLength\2)
							Do tValue.Rewind()
							While 'tValue.AtEnd {
								Write $$$ZENJSONESCAPE(tValue.Read(tStreamMaxReadLen),pFormat)
							}
						}
						Write """"
					}
				} ElseIf (pFormat["a") {
					Do nextProp
					Write $$$ZENJSONPROP(tPropName,pFormat)_":null"
				}
			}
			ElseIf (tClientType = "BINARYSTREAM") {
				Do nextProp
				Write $$$ZENJSONPROP(tPropName,pFormat)_":null"
			}
			Else {
				#; scalar item ; converts $List to empty string!
				Set tStr = $S((tDataType="b")&&(pFormat["e"):$S(tValue=1:"true",tValue=0:"false",1:"null")
					, (tDataType="b"):$S(tValue:"true",1:"false")
					, ((tDataType="n")||(pFormat["q"))&&$$$ZENJSISNUM(tValue):$$$ZENJSNUM(tValue)
					, (tDataType="n")&&(tValue="")&&(pFormat["d"):"null"
					, ($C(0)=tValue)||$ListValid(tValue):""""""
					//, "dtu"[tDataType:$S(pFormat["u":$$$ZENJSUSTR(..formatDateTime(tValue,tType,tDataType,pFormat)), 1:$$$ZENJSSTR(..formatDateTime(tValue,tType,tDataType,pFormat)))
					, 1:$$$ZENJSONSTR(tValue,pFormat))

				If (pFormat["e") || (tStr'="""""") {
					Do nextProp
					Write $$$ZENJSONPROP(tPropName,pFormat)_":"_tStr
				}
			}
		} ; end properties loop
		Quit:$$$ISERR(tSC)

		If tPropCount'=0 {
			#; either we wrote at least one property or we wrote an empty '{' due to "o" mode or level zero
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,pLevel+1)="" Write tLF_tIndent
			Write "}"
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
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

/// Convert the contents of the local array <var>pData</var> to an AET structure
/// <var>pMetaData</var> is a $List containing the names of the properties
/// of the objects in the order in which they will appear.<br/>
/// <var>pData</var> is an array containing the data. Each node in the array
/// should be a $List containing values for properties. This should match the 
/// meta data provided in <var>pMetaData</var>. The array of data can use any subscript
/// value its wants. It is possible to define a hierarchical array. In this case,
/// children nodes are placed within a parent collection called <var>children</var>.<br/>
ClassMethod %ArrayToAET(ByRef pMetaData, ByRef pData) As %DynamicAbstractObject [ PublicList = pData ]
{
	Try {
		Set tStackObj = ##class(%DynamicArray).%New()
		Set tStackArr = ##class(%DynamicArray).%New()
		If '$D(pData) {
			Set aet = ##class(%DynamicObject).%New()
		}
		Else {
			Set tLevel = 0
			Set tPropCount(tLevel) = 0
			Set aet = ##class(%DynamicObject).%New()		
			// process top node
			Set tNode = $G(pData)
			If $ListValid(tNode) {
				For n = 1:1:$LL(tNode) {
					Set tVal = $LG(tNode,n,$C(0))
					If (tVal'=$C(0)) {
						Set tName = $LG(pMetaData,n,"unknown")
						If ($IsValidNum(tVal)) {
							Do aet.%Set(tName,$FN(tVal,"LON"),"number")
						}
						Else {
							Do aet.%Set(tName,tVal)			
						}
						Set tPropCount(tLevel) = tPropCount(tLevel) + 1
					}
				}
			}
			// now process children of array
			Set tKey = $Query(pData)
			If (tKey '= "") {
				Set childArray = ##class(%DynamicArray).%New()
				Set node = aet
				Set tLevel = tLevel + 1
				Set tPropCount(tLevel) = 0
			}
			// loop over array
			While (tKey '= "") {
				Set tNewLevel = $ql(tKey)
				While (tLevel < tNewLevel) {
					If ($G(tPropCount(tLevel))=0) {
						Do tStackObj.%Push(node)
						Set node = ##class(%DynamicObject).%New()
					}
					Do tStackArr.%Push(childArray)
					Set childArray = ##class(%DynamicArray).%New()
					Set tLevel = tLevel + 1
				}
				While (tLevel > tNewLevel) {
					Do childArray.%Push(node)
					Set node = tStackObj.%Pop()		
					Kill tPropCount(tLevel)
					Set tLevel = tLevel - 1
	
					Do node.%Set("children",childArray)
					Set childArray = tStackArr.%Pop()
				}

				If ($G(tPropCount(tLevel))>0) {
					Do childArray.%Push(node)
					Set node = tStackObj.%Pop()		
				}

				Set tNode = $G(@tKey)
				Do tStackObj.%Push(node)

				Set tPropCount(tLevel) = 0
				If (tNode = "") {
					Set node = ##class(%DynamicAbstractObject).%FromJSON("{""_isEmpty"":true}")
					// no data for node, insert empty node
					Set tPropCount(tLevel) = tPropCount(tLevel) + 1
				} Else {
					Set node = ##class(%DynamicObject).%New()

					For n = 1:1:$LL(tNode) {
						Set tVal = $LG(tNode,n,$C(0))
						If (tVal'=$C(0)) {
							Set tName = $LG(pMetaData,n,"unknown")
							If ($IsValidNum(tVal)) {
								Do node.%Set(tName,$FN(tVal,"LON"),"number")
							}
							Else {
								Do node.%Set(tName,tVal)
							}
							Set tPropCount(tLevel) = tPropCount(tLevel) + 1
						}
					}
				}

				// get next item
				Set tKey = $Query(@tKey)
			}
		
			// finish off
			While (tLevel > 0) {
		
				If (childArray) {
					Do childArray.%Push(node)
					Set node = tStackObj.%Pop()	
				}	
				If (node) {
					Do node.%Set("children",childArray)
					Set childArray = tStackArr.%Pop()
				}
				Set tLevel = tLevel - 1
			}
			Set aet = node
		}
	}
	Catch ex {
		Set aet = -1
	}
	Quit aet
}

/// Write out the contents of the local array <var>pData</var> to the current device using JSON notation
/// <var>pMetaData</var> is a $List containing the names of the properties
/// of the objects in the order in which they will appear.<br/>
/// <var>pData</var> is an array containing the data. Each node in the array
/// should be a $List containing values for properties. This should match the 
/// meta data provided in <var>pMetaData</var>. The array of data can use any subscript
/// value its wants. It is possible to define a hierarchical array. In this case,
/// children nodes are placed within a parent collection called <var>children</var>.<br/>
/// <var>pFormat</var> is a flags string that controls output formatting options.<br/>
/// The following character option codes are supported:<br/>
/// 1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)<br/>
/// b - line break before opening { of objects<br/>
/// i - indent with 4 spaces unless 't' or 1-9<br/>
/// n - newline (lf)<br/>
/// s - use strict JSON output - <strong>NOTE:</strong> special care should be taken when sending data to a browser, as using this flag 
/// may expose you to cross site scripting (XSS) vulnerabilities if the data is sent inside <code>&lt;script&gt;</code> tags. Zen uses
/// this technique extensively, so this flag should <strong>NOT</strong> be specified for jsonProviders in Zen pages.<br/>
/// t - indent with tab character<br/>
/// u - output pre-converted to UTF-8 instead of in native internal format<br/>
/// w - Windows-style cr/lf newline<br/>
ClassMethod %ArrayToJSON(ByRef pMetaData, ByRef pData, pFormat As %String = "tw") As %Status [ PublicList = pData ]
{
	Set tSC = $$$OK
	Try {
		Set tAET = ##class(%ZEN.Auxiliary.altJSONProvider).%ArrayToAET(.pMetaData, .pData)
 		If ($IsObject(tAET)) {
	 		Write tAET.%ToJSON()
	 		Write ""
			Quit
 		}
 		// Else fall back to old style generation	
		If '$D(pData) {
			Write "null"
			Quit
		}
		Set tLevel = 0
		Set tChildCount(tLevel) = 0
		Set tPropCount(tLevel) = 0

		Set tLF=$S(pFormat["w":$C(13,10), pFormat["n":$C(10), 1:"")
		If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,pFormat["t":1,1:4))="" }
		Else { Set tTab="" }
		Set tIncludeWhitespace = (tLF_tTab'="")

		Write "{"
			
		// process top node
		Set tNode = $G(pData)
		If $ListValid(tNode) {
			For n = 1:1:$LL(tNode) {
				Set tVal = $LG(tNode,n,$C(0))
				If (tVal'=$C(0)) {
					Write:tPropCount(tLevel)>0 ","
					If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
					Write $$$ZENJSONPAIR($LG(pMetaData,n,"unknown"),tVal,pFormat)
					Set tPropCount(tLevel) = tPropCount(tLevel) + 1
				}
			}
		}
		// now process children of array
		Set tKey = $Query(pData)
		If (tKey '= "") {
			Write:$G(tPropCount(tLevel))>0 ","
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
			Write """children"":["
			Set tLevel = tLevel + 1
			Set tChildCount(tLevel) = 0
			Set tPropCount(tLevel) = 0
		}

		// loop over array
		While (tKey '= "") {
			Set tNewLevel = $ql(tKey)
			While (tLevel < tNewLevel) {
				If (tIncludeWhitespace && tLevel) Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write $S(pFormat["b":tLF_tIndent,1:" ")
				If ($G(tPropCount(tLevel))>0) {
					Write ","
				} Else {
					Write "{"
				}
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
				Write """children"":["
				Set tLevel = tLevel + 1
				Set tChildCount(tLevel) = 0
			}
			While (tLevel > tNewLevel) {
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
				Write "}"
				Kill tPropCount(tLevel),tChildCount(tLevel)
				Set tLevel = tLevel - 1
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
				Write "]"
			}

			If ($G(tPropCount(tLevel))>0) {
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
				Write "}"_$S($G(tChildCount(tLevel))>0:",",1:"")
			}
			Set tNode = $G(@tKey)
			Set tChildCount(tLevel) = tChildCount(tLevel) + 1
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
			Write "{"
			Set tPropCount(tLevel) = 0
			If (tNode = "") {
				// no data for node, insert empty node
				If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
				Write """_isEmpty"":true"
				Set tPropCount(tLevel) = tPropCount(tLevel) + 1
			} Else {
				For n = 1:1:$LL(tNode) {
					Set tVal = $LG(tNode,n,$C(0))
					If (tVal'=$C(0)) {
						Write:tPropCount(tLevel)>0 ","
						If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
						Write $$$ZENJSONPAIR($LG(pMetaData,n,"unknown"),tVal,pFormat)
						Set tPropCount(tLevel) = tPropCount(tLevel) + 1
					}
				}
			}
			// get next item
			Set tKey = $Query(@tKey)
		}
		// finish off
		While (tLevel >= 0) {
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel+1)="" Write tLF_tIndent
			Write "}"
			If tIncludeWhitespace Set tIndent="", $P(tIndent,tTab,tLevel)="" Write tLF_tIndent
			Write:tLevel>0 "]"
			Set tLevel = tLevel - 1
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Write "null"
	}
	Quit tSC
}

ClassMethod LogMessage(msg As %String) As %Status
{
	Set Idx = ^jsonMsgLog("length")
	Set ^jsonMsgLog(Idx)=msg
	Set ^jsonMsgLog("length")=(Idx+1)
	Quit $$$OK
}

/// Given an Abstract Entity Tree of potentially nested %DynamicObject and
/// %DynamicArray nodes, convert this memory structure to one using 
/// the legacy %ZEN.proxyObject and %Collection.AbstractList
ClassMethod %ConvertAETToZPO(obj As %DynamicAbstractObject, rootType As %String) As %ZEN.proxyObject [ Internal ]
{
	Set tSC = $$$OK
	Set returnObj = ""
	
	If (rootType = "array") {
		// Process array
		// If the array contains only values store it in a ListOfDataTypes
		// Otherwise use a ListOfObjects
		Set hasNestedObjects = 1
		Set aetKey = ""   // property name
		Set aetValue = "" //property value
		Set nodeIdx = obj.%GetIterator()
		While nodeIdx.%GetNext(.aetKey,.aetValue), hasNestedObjects = 1 {
			// Heuristic is null and empty string don't count in
			// picking object type
			If (aetValue'="") {
				Set nodeType = obj.%GetTypeOf(aetKey)
				If ('((nodeType="array") || (nodeType="object") ||(nodeType="oref"))) {
					Set hasNestedObjects = 0
				}
			}
		}
		If (hasNestedObjects=1) {
			Set returnObj = ##class(%Library.ListOfObjects).%New()
		}
		Else {
			Set returnObj = ##class(%Library.ListOfDataTypes).%New()
		}
		
		Kill nodeIdx
		Set nodeIdx = obj.%GetIterator()
	 	Kill aetKey 
		Kill aetValue
		While nodeIdx.%GetNext(.aetKey,.aetValue) {
			If (aetKey '= "") {
				Set nodeType = obj.%GetTypeOf(aetKey)
				If ((nodeType="array")||(nodeType="object")) { 
					// Need to recurse
					Do returnObj.Insert(..%ConvertAETToZPO(aetValue,nodeType))
				}
				Else {
					Set tsc=returnObj.Insert(aetValue)
				}
			}
		}
	}
	Elseif (rootType = "object") {
		// Process object
		Set returnObj = ##class(%ZEN.proxyObject).%New()
	
		Set nodeIdx = obj.%GetIterator()
		Set aetKey = ""   // property name
		Set aetValue = "" //property value
		While nodeIdx.%GetNext(.aetKey,.aetValue) {
			Set nodeType = obj.%GetTypeOf(aetKey)
			If ((nodeType="array")||(nodeType="object")) {
				// Need to recurse
				Do returnObj.%DispatchSetProperty(aetKey,..%ConvertAETToZPO(aetValue,nodeType))
			}
			Else {
				Do returnObj.%DispatchSetProperty(aetKey,aetValue)
			}
		}
	}
	Quit returnObj
}

ClassMethod %TestForNestedObjects(pObj As %DynamicArray) As %Boolean
{
	// If the array contains only values store it in a ListOfDataTypes
	// Otherwise use a ListOfObjects
	Set hasNestedObjects = 1
	
	Set nodeIdx = pObj.%GetIterator()
	While nodeIdx.%GetNext(.aetKey,.aetValue), hasNestedObjects = 1 {
		If (aetValue'="") {
			// Heuristic is null and empty string don't count in
			// picking object type
			Set nodeType = obj.%GetTypeOf(aetKey)
			If ('((nodeType="array")||(nodeType="object")||(nodeType="oref"))) {
				Set hasNestedObjects = 0
			}
		}
	}
	Quit hasNestedObjects
}

ClassMethod %GetTypeInfo(pClass As %String, pProperty As %String) As %DynamicObject
{
	/*
	For any given pProperty within pClass there exists several possible type
	outcomes:
	1) it is a simple data or object type
		in this case it will NOT extend Collection Abstract list and its
		propCollection will be null
	2) it is a list
		In this case its propCollection will be LIST and the child class will
		be some data type and the runtime type will be the list container
	3) it is a collection and we need to check the ELEMENTTYPE to know 
		what we're dealing with
	*/
	If (pClass="") {
		Set childClass = ""
		Set collection = ""
		Set collectionClass = ""
		Set isFormOfList = 0
	}
	Elseif (pProperty="") {
		Set collectionClass = pClass
		
		// CLASS is defined to extend list of objects but no specific property name provided
 		If ($classmethod(pClass,"%Extends","%Library.ListOfObjects")) {
			Set propElementType = $parameter(pClass,"ELEMENTTYPE")
			Set childClass = $select(propElementType = "%RegisteredObject": "", 1: propElementType)
			Set collection = "list"
			Set isFormOfList = 1
 		}
 		Else {
 			Set childClass = ""
			Set collection = ""
			Set isFormOfList = 0
		}
	}
	Else {				
		// Valid current class for arrays?
		Set classExtendsList = $classmethod(pClass,"%Extends","%Collection.AbstractList")
		Set isFormOfList = classExtendsList
		//NEED ACTUAL OBJECT TO TEST STREAM READY OR NOT
	
		// lookup type in meta data
		Set childClass = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPtype)
		Set collection = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPcollection)
		Set runtimeType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPruntimetype)
		If (runtimeType '= "") {
			Set collectionClass = runtimeType
			Set isFormOfList = $classmethod(runtimeType,"%Extends","%Collection.AbstractList")
		}

		If (childClass '= "") {
			Set childClassType = $$$comClassKeyGet(childClass,$$$cCLASSclasstype)
			Set childExtendsIterator = $classmethod(childClass,"%Extends","%Collection.AbstractIterator")
			If ((childClassType="datatype")||('childExtendsIterator)) {
				Set childClass = ""
			}
			If (childExtendsIterator=1) {
				Set collectionClass = runtimeType
				Set childClass = $parameter(collectionClass,"ELEMENTTYPE")			
			}
		}
	
		If (classExtendsList=1) {
			Set collectionClass = pClass
			// we have to get the element type from the collection class
			Set childClass = $parameter(collectionClass,"ELEMENTTYPE")
		}
	}
		
	Set obj = ##class(%DynamicObject).%New()

	Do obj.%Set("collection",collection)
	Do obj.%Set("collectionClass",collectionClass)
	Do obj.%Set("memberClass",childClass)
	Do obj.%Set("isFormOfList",isFormOfList)
	
	Quit obj
}

/// Given an AET Array node of potentially nested %DynamicObject and
/// %DynamicArray nodes, convert this memory structure to one using 
/// the the provided COS object class
ClassMethod %UnpackArrayToCOSObject(obj As %DynamicAbstractObject, targetObj As %RegisteredObject, pMember As %String, pIgnoreUnknownProps As %Boolean = 0) [ Internal ]
{
	If (targetObj = "") {
		If (..%TestForNestedObjects(obj)=1) {
			Set tClass = "%Library.ListOfObjects"
		}
		Else {
			Set tClass = "%Library.ListOfDataTypes"
		}
		Set targetObj = $classmethod(tClass,"%New")
	}	
	
	Set nodeIdx = obj.%GetIterator()
	While nodeIdx.%GetNext(.aetKey,.aetValue) {
		If (aetKey '= "") {
			Set nodeType = obj.%GetTypeOf(aetKey)
			If (nodeType="array") {
					
				Do targetObj.Insert(..%UnpackArrayToCOSObject(aetValue, pMember, "", pIgnoreUnknownProps))
			}
			Elseif (nodeType="object") {
				
				Do targetObj.Insert(..%UnpackObjectToCOSObject(aetValue, pMember, pIgnoreUnknownProps))
			}
			Else {
				Do targetObj.Insert(aetValue)
			}
		}
	}
	Quit
}

/// Given an AET Object node of potentially nested %DynamicObject and
/// %DynamicArray nodes, convert this memory structure to one using 
/// the the provided COS object class
ClassMethod %UnpackObjectToCOSObject(obj As %DynamicAbstractObject, pClass As %String, pIgnoreUnknownProps As %Boolean = 0) As %RegisteredObject [ Internal ]
{
	Set updateInPlace = 0
	If ($IsObject(pClass)) {
		Set updateInPlace = 1
		Set tClass = pClass.%ClassName(1)
	}
	Else {
		Set tClass = $S(pClass="":"%ZEN.proxyObject",1:pClass)
	}
	
	Set test = 1
	If (tClass = "%Collection.ListOfObj") {
		Set test=1
	}
		
	If ((updateInPlace) && (pClass.%Extends("%Collection.AbstractArray"))) { // All properties are unknown in this case
		Set pIgnoreUnknownProps=1
	}
			
	If ('updateInPlace) {
		Set nodeIdx = obj.%GetIterator()
		Set seekingClass = 1
		Set seekingId = 1
		While nodeIdx.%GetNext(.aetKey,.aetValue), seekingClass = 1, seekingId {
			If (aetKey = "_class") {
				Set pClass = aetValue
				Set tClass = aetValue
				Set seekingClass = 0
			}
			Elseif (aetKey = "_id") {
				Set tId = aetValue
				Set seekingId = 0
			}
		}
		Set pObject = $classmethod(tClass,"%New")
	}
	Else {
		Set pObject = pClass
	}
	
	Set nodeIdx = obj.%GetIterator()
	While nodeIdx.%GetNext(.aetKey,.aetValue) {
		If (aetKey '= "_class") && (aetKey '= "_id") {
			Set unknownProp = 0
			Try {
				Set nodeProp = $property(pObject,aetKey)
			}
			Catch ex {
				Set unknownProp = 1					
				If ('pIgnoreUnknownProps) Throw ex
			}					
			If (unknownProp=0) {
				Set nodeType = obj.%GetTypeOf(aetKey)
				If ((nodeType="array")||(nodeType="object")) {

					Set nodeInfo = ..%GetTypeInfo(tClass, aetKey)
					Set nodeClass = nodeInfo.%Get("collectionClass")
					Set nodeIsList = nodeInfo.%Get("isFormOfList")
					Set nodeChildClass = nodeInfo.%Get("memberClass")

					If ((nodeType="array")&&(nodeIsList)) { // process nested array

 						If (nodeProp="") {
 							Set targetObj = $classmethod(nodeClass,"%New")
							Set $Property(pObject,aetKey) = targetObj
 						}
 						Else {
	 						Set targetObj = nodeProp
 						}
						Do ..%UnpackArrayToCOSObject(aetValue, targetObj, nodeChildClass, pIgnoreUnknownProps)
					}
					Elseif ((nodeType="object")&&('nodeIsList)) { // process nested object
						Set nestedObject = $Property(pObject,aetKey)
						If (nestedObject.%Extends("%Collection.AbstractArray")) {
							Set tmp = ..%UnpackObjectToCOSObject(aetValue, nestedObject, pIgnoreUnknownProps)
						}
						Else {
							Set $Property(pObject,aetKey) = ..%UnpackObjectToCOSObject(aetValue, nodeClass, pIgnoreUnknownProps)
						}
					}
					Else {
						// EXCEPTION wrong schema on file for nesting			
					}
				}
				Else {
					Try {
						// test for stream property
						Set tStream = $property(pObject,aetKey)
						If ($IsObject(tStream) && (tStream.%Extends("%Stream.Object") || tStream.%Extends("%IO.I.Stream"))) {
							Do tStream.Rewind()
							Do tStream.Write(aetValue)
						}
						Else {
							Set $property(pObject,aetKey) = aetValue
						}
					}
					Catch ex {
						If $case(ex.Name, "<CANNOT SET THIS PROPERTY>" : 0, "<PROPERTY DOES NOT EXIST>": 'pIgnoreUnknownProps, :1) Throw ex
					}
				}
			}
			Else {
				If (pObject.%Extends("%Collection.AbstractArray")) {
					Do pObject.SetAt(aetValue,aetKey)
				}
			}
		}
	}
	Quit pObject
}

/// Given an Abstract Entity Tree of potentially nested %DynamicObject and
/// %DynamicArray nodes, convert this memory structure to one using 
/// the the provided COS object class
ClassMethod %UnpackAETToObject(obj As %DynamicAbstractObject, rootType As %String, pClass As %String, pIgnoreUnknownProps As %Boolean = 0) As %RegisteredObject [ Internal ]
{
	Set pObject = ""
	
	Set tClass = $S(pClass="":"%ZEN.proxyObject",1:pClass)

	Try {
		If (pClass = "") {  // Catch the no data type defined issue
			If ('pIgnoreUnknownProps) {
				Throw ##class(%Exception.General).%New("<UNDEFINED PROPERTY ERROR>",,,"<JSON PROPERTY DOES NOT EXIST IN OBJECT>")
			}
		}

		Set nodeInfo = ..%GetTypeInfo(pClass, "")	
		Set nodeClass = nodeInfo.%Get("collectionClass")
		Set nodeIsList = nodeInfo.%Get("isFormOfList")
		Set nodeChildClass = nodeInfo.%Get("memberClass")
	
		If ((rootType = "array")&&(nodeIsList=1)) { // Process array
			Set pObject = $classmethod(nodeClass,"%New")
			Do ..%UnpackArrayToCOSObject(obj, pObject, nodeChildClass, pIgnoreUnknownProps)
		}
		Elseif ((rootType = "object")&&(nodeIsList=0)) {	// Process object
			Set pObject = ..%UnpackObjectToCOSObject(obj, nodeClass, pIgnoreUnknownProps)
		}
		Else {
		}
 
  	}
	Catch ex {
		If $case(ex.Name, "<CANNOT SET THIS PROPERTY>" : 0, "<PROPERTY DOES NOT EXIST>": 'pIgnoreUnknownProps, :1) Throw ex
	}
 	Quit pObject
}

/// Parse the string <var>pJSON</var> containing JSON notation
/// and convert it to an object instance <var>pObject</var>.<br/>
/// <var>pJSON</var> could also be a character stream.<br/>
/// <var>pClass</var> is the name of the class to create to hold
/// the instantiated object. This class must match the data within the JSON
/// notation. If <var>pClass</var> is empty (""), then an instance
/// of the generic class <class>%ZEN.proxyObject</class> will be created.
/// <var>pCharsProcessed</var> and <var>pLevel</var> are used
/// internally and do not have to be supplied.
/// <var>pIgnoreUnknownProps</var> controls whether we will
/// ignore errors when we process a property that isn't expected. The default 
/// behaviour is to treat this as an error.<br/>
/// Note that this method assumes well-formed JSON notation: it does
/// not perform complete error checking.
ClassMethod %ParseJSON(pJSON As %String, pClass As %String = "", Output pObject As %RegisteredObject, Output pCharsProcessed As %Integer, pLevel As %Integer = 1, pFirstChar As %String = "", pIgnoreUnknownProps As %Boolean = 0) As %Status [ Internal ]
{
 	Set tSC = $$$OK
	Try {
 		// Call out to new stuff to do actual parsing and get back Abstract Entity Tree	
		Set obj = ##class(%DynamicAbstractObject).%FromJSONStats(pJSON , .stats)	
		If ('$isobject(obj)) { 
 			Quit
 		}
 		Elseif ($lg(stats,1) '= 0) {
			Set errMsg1 = "JSON Parse Error "_$lg(stats,1)
			Set errMsg2 = $lg(stats,2)_" occurred in line "_$lg(stats,3)_" at offset "_$lg(stats,4)
			Set parseEx = ##class(%Exception.General).%New(errMsg1,"999",,errMsg2)
			Throw parseEx		
		}
		Else {
	 		// If we're still here we must have a AET to process
			Set tOrigClass = pClass    // Class user asked us to create and hold 
 			Set tRootType = obj.%GetObjectType()
 			If (tRootType = $$$PVTYPEOBJECT) Set tRootType="object"
 			If (tRootType = $$$PVTYPEARRAY)  Set tRootType="array" 
 			
 	 		If ((pClass="%DynamicAbstractObject")|| (pClass="%Library.DynamicAbstractObject")) {
				// User asked for raw AET, just give it to them
				Set pObject=obj
 			}
 			
 			Elseif ((pClass="%DynamicObject")||(pClass="%Library.DynamicObject")){
	 			If (tRootType="object") {
		 			Set pObject=obj
	 			}
	 			Else {
		 			// Array source packed as an object
		 			Set pObject = {}
		 			Set iter = obj.%GetIterator()
		 			While iter.%GetNext(.key,.value){ 
		 				Do pObject.%Set(key,value) 
		 			}
	 			}		
 			}
 
 			Elseif ((pClass="%DynamicArray")||(pClass="%Library.DynamicArray")){
	 			If (tRootType="array") {
		 			Set pObject=obj
	 			}
	 			Else {
		 			Set pObject = []
		 			Set iter = obj.%GetIterator()
		 			While iter.%GetNext(.key,.value){ 
		 				Do pObject.%Push(key_"||"_value) 
		 			}
	 			}		
 			}
 			
			Elseif ((pClass="%ZEN.proxyObject")||(pClass="")) {
				// Convert AET to ZPO 
				Set pObject = ..%ConvertAETToZPO(obj,tRootType)
			}
			Else {
		 		// Unpack AET into given object
				Set pObject = ..%UnpackAETToObject(obj, tRootType, pClass, pIgnoreUnknownProps)
			}
		}
 	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Diagnostic method: write JSON content to the given file.
ClassMethod %WriteJSONToFile(pJSON As %String, pFileName As %String) As %Status [ Internal ]
{
	Set io = $io
	Set tFile = pFileName
	Open tFile:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,tFile)
	Use tFile
	If $IsObject(pJSON) {
		Do pJSON.OutputToDevice()
	}
	Else {
		Write pJSON
	}
	Use io
	Close tFile
	Quit $$$OK
}

/// Test method: process JSON content from the given file.
ClassMethod %ParseFile(pFileName As %String, pClass As %String = "", Output pObject As %RegisteredObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFile = ##class(%File).%New(pFileName)
		Do tFile.Open("R")
		Set tSC = ..%ParseJSON(tFile,pClass,.pObject)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Clear the (shadow) modified bit for the content property.
Method %ClearContentModified() [ Internal ]
{
	Set s%content = 0
}

/// Set the (shadow) modified bit for the content property.
Method %SetContentModified() [ Internal ]
{
	Set s%content = 1
}

/// Render the JSON content of the target object
/// along with the other properties of the provider.
Method %OnDrawObjectProperties() [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Write "// JSON: OnDrawObjectProperties (",..id,")",!
		Write "o.content = "
		Set tSC = ..%DrawJSON()
		Write ";",!

		// clear modbit so that we don't later update content
		Do ..%ClearContentModified()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Write "o.error = '",$zconvert($system.Status.GetErrorText(tSC),"O","JS"),"';",!
		Do ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	}
}

/// Render the JSON content of the target object
/// along with the other properties of the provider.
Method %OnObjectSynch() As %Status [ Internal ]
{
	Set tSC = $$$OK
	// if user has set or modified the target object
	// then update the client content

	Set errorMsg = ""
	If (..error '= "") {
		// don't update content if an error occurred
		Write "// JSON: %OnObjectSynch, error encountered so not updating content",!
		Set errorMsg = $zconvert(..error,"O","JS")
	}
	ElseIf ($IsObject(..%ObjectReplacement)) {
		Write "// JSON: %OnObjectSynch",!
		Write "// %ObjectReplacement: "_$classname(..%ObjectReplacement),!
		Write "o.content = "
		Set tSC = ..%ObjectToJSON(..%ObjectReplacement,,,..%Format)
		Write ";",!
		Set ..%ObjectReplacement = ""
	}
	ElseIf ((..OnRenderJSON '= "")||(..OnGetArray '= "")||(..OnGetTargetObject '= "") ) {
		Write "// JSON: %OnObjectSynch",!
		Write "o.content = "
		Set tSC = ..%DrawJSON()
		Write ";",!
	}
	ElseIf ($IsObject(..%TargetObject)) {
		// write out object in JSON format
		Write "// JSON: OnObjectSynch",!
		Write "// "_$classname(..%TargetObject),!
		Write "var json = "
		Set tSC = ..%ObjectToJSON(..%TargetObject,,,..%Format)
		Write ";",!
		Write "o.content = json;",!
	}
	ElseIf (..documentId'="") {
		// JMD1154
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $S(..%containerClass="":$$$ZENVAL(value),1:value)
			Set key = ..parameters.Next(key)
		}

		Set tSC = ##class(%ZEN.DataModel.DocumentUtils).%GetDocument(..documentId,.tParms,.tObject)
		If ($$$ISOK(tSC)&&$IsObject(tObject)) {
			// always set to "object" in this case
			Set ..contentType = "object"
			If (..targetClass="") {
				Set ..targetClass = $classname(tObject)
			}
			// write out object in JSON format
			Write "var json = "
			Set tSC = ..%ObjectToJSON(tObject,,,..%Format)
			Write ";",!
			Write "o.content = json;",!
		}
		Else {
			Write "null"
		}
	}

	If $$$ISERR(tSC) {
		Set errorMsg = errorMsg _ $select(errorMsg = "": "", 1: "\n") _ $zconvert($system.Status.GetErrorText(tSC),"O","JS")
	}
	If (errorMsg '= "") {
		Write "o.error = '",errorMsg,"';",!
	}

	// clear modbit so that we don't later update content
	Do ..%ClearContentModified()
	Quit tSC
}

/// Acquire data from the associated DataModel object.
/// This is typically called on the server before a page is served in order
/// to get initial values for bound components.
Method %AcquireData() As %Status [ Internal ]
{
	Quit $$$OK
}

/// Utility method to allow direct use of JSON from a non-ZEN context (such as a CSP page).<br/>
/// Calls the class method <var>pArrayMethod</var> within the class <var>pClass</var> and converts the
/// resulting array to an array of objects in JSON format using the convention of the <property>OnGetArray</property>
/// callback.<br/>
/// The JSON notation is written out to the current device.<br/>
/// <var>pVar</var> is the optional name of the client-side Javascript variable that refers to the JSON notation.<br/>
/// <var>pParms</var> is an optional array of parameter names and values that is passed to the callback method.<br/>
/// <var>pReturnStatus</var> is a flag to control whether the status code from the method should be returned to the caller.
/// If <var>pReturnStatus</var> is 0, an alert will be raised via Javascript. If <var>pReturnStatus</var> is 1, the status code
/// will be used as the return value from the method and an alert will NOT be raised.<br/>
/// <var>pFormat</var> is provided for signature compatibility with the 
/// legacy jsonProvider class, but using it to pretty-print the output
/// stream is not supported by this class.<br />
/// From a CSP page, you could invoke the method as follows:<br/>
/// <example language="CSP">
/// #(##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONFromArray("json",$classname(),"GetArray"))#
/// </example>
ClassMethod %WriteJSONFromArray(pVar As %String = "", pClass As %String = "", pArrayMethod As %String = "", ByRef pParms As %String, pReturnStatus As %Boolean = 0, pFormat As %String) As %String
{
	Set tSC = $$$OK
	Try {
		If (pVar'="") {
			// variable to hold the json object
			Write "var "_pVar_"="
		}
		If pClass'="" && (pArrayMethod'="") {
			If $IsObject(pClass) {
				Set tSC = $method(pClass,pArrayMethod,.pParms,.tMetaData,.tData)
			} ElseIf (pClass'="") {
				Set tSC = $classmethod(pClass,pArrayMethod,.pParms,.tMetaData,.tData)
			}
			If ($$$ISOK(tSC) && $D(tData)) {
				Set tSC = ..%ArrayToJSON(.tMetaData,.tData,.pFormat)
			} Else {
				Write "null"
			}
		} ElseIf pClass="" && $D(pParms) {
			If $D(pParms) {
				Set tSC = ..%ArrayToJSON(.pArrayMethod,.pParms,.pFormat)
			} Else {
				Write "null"
			}
		} Else {
			#; pClass was null xor pArrayMethod was null xor pParms was null
			Write "null"
		}
		If (pVar'="") {
			Write ";",!
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit:pReturnStatus tSC

	If $$$ISERR(tSC) {
		&js<alert('#($ZCVT($System.Status.GetErrorText(tSC),"O","JS"))#');>
	}
	// return an empty string to be #()# compatible
	Quit ""
}

/// Utility method to allow direct use of JSON from a non-ZEN context (such as a CSP page).<br/>
/// Calls the class method <var>pMethod</var> within the class <var>pClass</var> and converts the
/// resulting object to JSON format using the convention of the <property>OnGetTargetObject</property>
/// callback.<br/>
/// The JSON notation is written out to the current device.<br/>
/// <var>pVar</var> is the optional name of the client-side Javascript variable that refers to the JSON notation.<br/>
/// <var>pParms</var> is an optional array of parameter names and values that is passed to the callback method.<br/>
/// <var>pReturnStatus</var> is a flag to control whether the status code from the method should be returned to the caller.
/// If <var>pReturnStatus</var> is 0, an alert will be raised via Javascript. If <var>pReturnStatus</var> is 1, the status code
/// will be used as the return value from the method and an alert will NOT be raised.<br/>
/// <var>pFormat</var> is provided for signature compatibility with the 
/// legacy jsonProvider class, but using it to pretty-print the output
/// stream is not supported by this class.<br />
/// From a CSP page, you could invoke the method as follows:<br/>
/// <example language="CSP">
/// #(##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONFromObject("json",$classname(),"GetObject"))#
/// </example>
ClassMethod %WriteJSONFromObject(pVar As %String = "", pClass As %String = "", pMethod As %String = "", ByRef pParms As %String, pReturnStatus As %Boolean = 0, pFormat As %String) As %String
{
	Set tSC = $$$OK
	Try {
		If (pVar'="") {
			// variable to hold the JSON object
			Write "var "_pVar_"="
		}
		If $IsObject(pClass)&&'$IsObject(pMethod) {
			If ""=pMethod {
				Set tObject = pClass
			} Else {
				Set tSC = $method(pClass,pMethod,.pParms,.tObject)
			}
		} ElseIf $IsObject(pMethod) {
			Set tObject = pMethod
		} Else {
			Set tSC = $classmethod(pClass,pMethod,.pParms,.tObject)
		}
		Quit:$$$ISERR(tSC)

		If $IsObject(pClass)||$IsObject(pMethod) {
			Set p="" For { Set p=$O(pParms(p),1,value)  Quit:""=p
				Set pParms(p) = $$$ZENCVAL(value)
			}
		}
		If $IsObject(tObject) {
			Set tSC = ..%ObjectToJSON(tObject,,,.pFormat)
		} Else {
			Write "null"
		}
		If (pVar'="") {
			Write ";",!
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit:pReturnStatus tSC

	If $$$ISERR(tSC) {
		&js<alert('#($ZCVT($System.Status.GetErrorText(tSC),"O","JS"))#');>
	}
	// return an empty string to be #()# compatible
	Quit ""
}

/// Utility method to allow direct use of JSON from a non-ZEN context (such as a CSP page).<br/>
/// <var>pContent</var> is a string or a stream containing JSON notation.<br/>
/// <var>pTargetClass</var> is an optional class type for the resulting object; if not provided,
/// <class>%ZEN.proxyObject</class> is used.<br/>
/// <var>pObject</var> is the object created from the JSON.
/// <var>pIgnoreUnknownProps</var> controls whether properties that are not defined in the object
/// structure will be ignored or treated as an error condition. The default behaviour is to stop
/// processing the incoming JSON.
ClassMethod %ConvertJSONToObject(pContent As %String, pTargetClass As %String = "", Output pObject As %RegisteredObject, pIgnoreUnknownProps As %Boolean = 0) As %Status [ CodeMode = expression ]
{
..%ParseJSON(pContent,pTargetClass,.pObject,,,,pIgnoreUnknownProps)
}

/// Utility method to allow JSON output to be written to a stream from a general non-ZEN context.<br/>
/// Calls the class method <var>pArrayMethod</var> within the class <var>pClass</var> and converts the
/// resulting array to an array of objects in JSON format using the convention of the <property>OnGetArray</property>
/// callback.<br/>
/// The JSON notation is written out to the stream supplied in <var>pStream</var>.<br/>
/// <var>pParms</var> is an optional array of parameter names and values that is passed to the callback method.<br/>
/// <var>pRewindStream</var> is a flag to control whether the stream should be rewound after the data is written to it.<br/>
/// <var>pFormat</var> is provided for signature compatibility with the 
/// legacy jsonProvider class, but using it to pretty-print the output
/// stream is not supported by this class.<br />
ClassMethod %WriteJSONStreamFromArray(pStream As %Stream.Object, pClass As %String, pArrayMethod As %String, ByRef pParms As %String, pRewindStream As %Boolean = 0, pFormat As %String) As %Status [ ProcedureBlock = 0 ]
{
	New %ISCJSONStream, tSC, ex, tInitIO, tRedirected, tWasRedirected, tOldMnemonic
	Set tSC = $$$OK
	Set tRedirected = 0
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

		Set tSC = ..%WriteJSONFromArray(,.pClass,.pArrayMethod,.pParms,1,.pFormat)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Use tInitIO::($select(tOldMnemonic=""||(tOldMnemonic="%X364"):"",1:"^"_tOldMnemonic))
	If tWasRedirected'=tRedirected Do ##class(%Library.Device).ReDirectIO(tWasRedirected)
	If pRewindStream && $$$ISOK(tSC) {
		Do pStream.Rewind()
	}
	Quit tSC
}

/// Utility method to allow JSON output to be written to a stream from a general non-ZEN context.<br/>
/// Calls the class method <var>pMethod</var> within the class <var>pClass</var> and converts the
/// resulting object to JSON format using the convention of the <property>OnGetTargetObject</property>
/// callback. However, if an object is supplied in <var>pClass</var>, then the supplied object will be
/// used as the source object.<br/>
/// The JSON notation is written out to the stream supplied in <var>pStream</var>.<br/>
/// <var>pParms</var> is an optional array of parameter names and values that is passed to the callback method.
/// If <var>pClass</var> is an object, these parameters will be ignored.<br/>
/// <var>pRewindStream</var> is a flag to control whether the stream should be rewound after the data is written to it.<br/>
/// <var>pFormat</var> is provided for signature compatibility with the 
/// legacy jsonProvider class, but using it to pretty-print the output
/// stream is not supported by this class.<br />
ClassMethod %WriteJSONStreamFromObject(pStream As %Stream.Object, pObject As %String, pMethod As %String, ByRef pParms As %String, pRewindStream As %Boolean = 0, pFormat As %String) As %Status [ ProcedureBlock = 0 ]
{
	New %ISCJSONStream, tSC, ex, tInitIO, tRedirected, tWasRedirected, tOldMnemonic
	Set tSC = $$$OK
	Set tRedirected = 0
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

		Set tSC = ..%WriteJSONFromObject(,.pObject,.pMethod,.pParms,1,.pFormat)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Use tInitIO::($select(tOldMnemonic=""||(tOldMnemonic="%X364"):"",1:"^"_tOldMnemonic))
	If tWasRedirected'=tRedirected Do ##class(%Library.Device).ReDirectIO(tWasRedirected)
	If pRewindStream && $$$ISOK(tSC) {
		Do pStream.Rewind()
	}
	Quit tSC
}

ClassMethod redirects() [ Internal, Private, ProcedureBlock = 0 ]
{
	Quit
#; Public entry points for redirection - any changes made here should
#; also be reflected in redirects() in the jsonSQLProvider class
wstr(s) Do %ISCJSONStream.Write(s) Quit
wchr(a) Do %ISCJSONStream.Write($char(a)) Quit
wnl Do %ISCJSONStream.Write($char(13,10)) Quit
wff Do %ISCJSONStream.Write($char(13,10,13,10)) Quit
wtab(n) New chars Set $piece(chars," ",n+1)="" Do %ISCJSONStream.Write(chars) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

/// Build a list of super classes (indexed by number) starting from (and including) <var>pClass</var>.
/// Stop when any of the classes in the list <var>pSkip</var> are reached.
/// Skip any classes in any of the packages in the list <var>pSkipPackage</var> are reached.
ClassMethod getSuperClassList(pClass As %String, ByRef pList As %String, ByRef pSkip As %String, ByRef pSkipPackage As %String) [ Internal ]
{
	#; skip this package?
	Quit:pSkipPackage[("|"_$P(pClass,".",1,$L(pClass,".")-1)_".")
	Set pSkip(pClass) = "" // prevent duplicates

	Set tSupers = $$$comClassKeyGet(pClass,$$$cCLASSsuper)
	For p = $L(tSupers,","):-1:1 { Set tSuper = $P(tSupers,",",p)
		If tSuper '= "" && '$D(pSkip(tSuper)) {
			Do ..getSuperClassList(tSuper,.pList,.pSkip,.pSkipPackage)
		}
	}
	#; add current class to the list
	Set pList($I(pList)) = pClass
}

/// Build a list of properties in sequence order, including inherited properties.<br>
/// On return, <var>pList</var> is a list of properties names (subscripted by order number).
ClassMethod getOrderedProps(pClass As %Dictionary.CompiledClass, ByRef pList) [ Internal ]
{
	#; skip this package?
	Quit:pClass=""

	Do ..getSuperClassList(pClass, .tClassList, .pSkip,"|%Library.|%XML.|%Stream.|%SQL.|%ZEN.DataModel.")

	#; now build list of properties in sequence order
	Set tNext = 1

	Set tClassNo=""  For { Set tClassNo=$O(tClassList(tClassNo),1,tClass)  Quit:""=tClassNo
		Set n = 0 // used for props with no seq no
		Kill t
		Set tPropName=""  For { Set tPropName = $$$defMemberNext(tClass,$$$cCLASSproperty,tPropName)  Quit:""=tPropName
			// guarantee uniqueness of property sequence number vs. seq number of superclass properties or blank
			Set tSeq=$$$defMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPsequencenumber)
			If 'tSeq {
				#; missing seq no!
				Set n = n - 1
				Set tSeq = n
			}
			Set:""=$G(b(tPropName)) t(tSeq) = tPropName
			Set b(tPropName)=tSeq
		}

		#; now add these to the end of the main list, first restoring order of no-seq props
		Set n="" For { Set n=$O(t(n),-1,tPropName)  Quit:+n>=0
			For k=-n:1 { If ""=$G(t(k)) Set t(k)=tPropName  Kill t(n)  Quit }
		}
		Set key = "" For { Set key = $O(t(key))  Quit:""=key
			Set pList(tNext) = t(key), tNext = tNext + 1
		}
	}
}

/// Return the client-side JSON data as an object or null.
ClientMethod getContentObject() [ Language = javascript ]
{
	return ''==this.content ? null : this.content;
}

/// Return the type of the data supplied by this provider: "object" or "array".
ClientMethod getContentType() [ Language = javascript ]
{
	return this.contentType;
}

/// Set the type of the data supplied by this provider: "object" or "array".
ClientMethod setContentType(type) [ Language = javascript ]
{
	this.contentType = type;
}

/// Make <var>obj</var> the new target object for this provider.
ClientMethod setContentObject(obj) [ Language = javascript ]
{
	this.content = obj;
	this._metaData = null;
	this.raiseDataChange();
}

/// Set the content for this provider using the string <var>json</var>.
/// <var>json</var> is expected to contain object data in JSON format.
ClientMethod setContentText(json) [ Language = javascript ]
{
	try {
		eval('var newContent = ' + json);
		this.content = newContent;
		delete newContent;
		this._metaData = null;
		this.raiseDataChange();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in setContentText method for jsonProvider');
	}
}

/// Send the current target object for this provider to the server
/// for processing. This will recreate the object on the server and
/// invoke the <property>OnSubmitContent</property> callback.<br/>
/// This method will return true if successful and false otherwise.
/// If the method fails, an error string is placed in this object's
/// <property>error</property> property (accessible via the <method>getError</method> method).<br/>
/// <var>command</var> is an optional string that is passed on to the server
/// callback method to allow for different behaviors in the server logic.<br/>
/// <var>targetClass</var> is an optional argument that, if specified, should
/// be the name of the server-class that you wish to have instantiated on the server.
/// This has the same effect as setting the <property>targetClass</property> property.
/// This makes it possible to submit content for different object classes. If the
/// server cannot create an instance of the specified class, it will return 
/// an error.<br/>
/// Normally the submit operation is synchronous. If the optional <var>notify</var> parameter
/// is a function, then the operation will be invoked <i>asynchronously</i> and <var>notify</var>
/// will be invoked when the operation is complete. Note that only one asynchronous operation can be
/// handled at a time.<br/>
/// If <var>time</var> is defined, then raise the notify function every <var>time</var> milliseconds
/// until the task is complete.
ClientMethod submitContent(command, targetClass, notify, time) [ Language = javascript ]
{
	try {
		var ok = true;
		command = ('undefined' == typeof command) ? '' : command;
		notify = ('undefined' == typeof notify) ? null : notify;
		if ('undefined' != typeof targetClass && '' != targetClass) {
			this.targetClass = targetClass;
		}
		// test if we have a target class
		if ('' == this.targetClass) {
			alert('There is no targetClass for the jsonProvider (submitContent)');
			return false;
		}
		var json = this.toJSON(this.content);

		if (this.content && null == json) {
			alert('Error creating JSON content in the jsonProvider (submitContent)');
			return false;
		}
		json = json ? json : '';
		if ('function' == typeof notify) {
			// async
			if (!this._submitNotify) {
				this._submitNotify = notify;
				this._submitTimer = 0;
				this._submitTimerId = null;
				this.SubmitToServerAsync(command,json,this.targetClass);
				if (zenGet(time,0)>0) {
					this._submitTimer = time;
					this._submitTimerId = window.setTimeout('zenPage.getComponent('+this.index+').submitHandler(false,true);',this._submitTimer);
				}
			}
			else {
				ok = false;
			}
		}
		else {
			// sync
			ok = this.SubmitToServer(command,json,this.targetClass);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in submitContent method for jsonProvider');
		ok = false;
	}
	return ok;
}

/// Reload the contents of the provider with data from the server.<br/>
/// Unlike the <method>submitContent</method> method, 
/// this does not send data to the server.<br/>
/// This is typically used in conjunction with the <property>OnGetArray</property>
/// callback &mdash; this method will call the server and the server, in turn, will
/// invoke the <property>OnGetArray</property> callback to create new content to ship back to the client.
ClientMethod reloadContents() [ Language = javascript ]
{
	try {
		this.error = '';
		var ok = this.RefreshFromServer();
		this._metaData = null;
		this.raiseDataChange();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in reloadContents method for jsonProvider');
		ok = false;
	}
	return ok;
}

/// Reload the contents of the json provider asynchronously;
/// invoke the function <var>notify</var> when complete.
/// If <var>time</var> is defined, then raise the notify function every <var>time</var> ms
/// until the task is complete.
ClientMethod reloadContentsAsynch(notify, time) [ Language = javascript ]
{
	if (!this._notify) {
		this._notify = notify;
		this._timer = 0;
		this._timerId = null;
		this.error = '';
		this.RefreshFromServerAsynch();
		if (zenGet(time,0)>0) {
			this._timer = time;
			this._timerId = window.setTimeout('zenPage.getComponent('+this.index+').refreshHandler(false,true);',this._timer);
		}
	}
}

/// Called when async refresh is complete (final is true) or when the notifier timer fires.
ClientMethod refreshHandler(final, notify) [ Internal, Language = javascript ]
{
	if (final) {
		if (notify) {
			// final notice: after the dust has settled
			if (this._notify && 'function' == typeof this._notify) {
				this._notify(true);
				this._notify = null;
			}
		}
		else {
			if (this._timerId) {
				window.clearTimeout(this._timerId);
			}
			this._metaData = null;
			this._timer = 0;
			this._timerId = null;
			this.raiseDataChange();

			if (this._notify && 'function' == typeof this._notify) {
				// defer final notice
				this._timerId = window.setTimeout('zenPage.getComponent('+this.index+').refreshHandler(true,true);',10);
			}
		}
	}
	else if (this._timer) {
		if (this._notify && 'function' == typeof this._notify) {
			this._notify(false);
		}
		this._timerId = window.setTimeout('zenPage.getComponent('+this.index+').refreshHandler(false);',this._timer);
	}
}

/// Called when async submit is complete (final is true) or when the notifier timer fires.
ClientMethod submitHandler(final, notify) [ Internal, Language = javascript ]
{
	if (final) {
		if (notify) {
			// final notice: after the dust has settled
			if (this._submitNotify && 'function' == typeof this._submitNotify) {
				this._submitNotify(true);
				this._submitNotify = null;
			}
		}
		else {
			if (this._submitTimerId) {
				window.clearTimeout(this._submitTimerId);
			}
			this._submitTimer = 0;
			this._submitTimerId = null;

			if (this._submitNotify && 'function' == typeof this._submitNotify) {
				// defer final notice
				this._submitTimerId = window.setTimeout('zenPage.getComponent('+this.index+').submitHandler(true,true);',10);
			}
		}
	}
	else if (this._submitTimer) {
		if (this._submitNotify && 'function' == typeof this._submitNotify) {
			this._submitNotify(false);
		}
		this._submitTimerId = window.setTimeout('zenPage.getComponent('+this.index+').submitHandler(false);',this._submitTimer);
	}
}

/// Deprecated: use <method>reloadContents</method>.
ClientMethod refreshContent() [ Language = javascript ]
{
	return this.reloadContents();
}

/// Get the current value of the <property>error</property> property.
/// This is set when a server-side method encounters an error.
ClientMethod getError() [ Language = javascript ]
{
	return this.error;
}

/// Convert object <var>obj</var> to JavaScript
/// object literal syntax (JSON) so that it can be shipped
/// to the server.<br/>
/// Note that you cannot convert objects that refer to native types to JSON,
/// this includes any HTML elements or Zen components.
ClientMethod toJSON(obj, cycle, level) [ Internal, Language = javascript ]
{
//	if (JSON && JSON.stringify) return(JSON.stringify(obj))
	
	try {
		// cycle is a unique marker for *this* json-ization
		cycle = ('undefined' == typeof cycle) ? Math.floor(Math.random()*1000000) : cycle;
		level = ('undefined' == typeof level) ? 0 : level;
		if (level > 100) {
			alert('jsonProvider: too many levels in JSON object');
			return null;
		}
		if ('object' == typeof obj && null != obj) {
			// test for cycles
			if (null == obj.__cycle || cycle != obj.__cycle) {
				obj.__cycle = cycle;
			}
			else if (cycle == obj.__cycle) {
				// cycle in object graph
				return 'null';
			}
		}

		var t = new Array();

		switch (typeof obj) {
		case 'boolean':
			t.push(obj ? 'true' : 'false');
			break;
		case 'string':
			var text = obj.toString();
			text = text.replace(/\\/g,'\\\\'); // escape any backslash
			text = text.replace(/\"/g,'\\\"'); // escape any double quotes
			t.push('"' + text + '"');
			break;
		case 'number':
			t.push(obj);
			break;
		case 'object':
			if (null == obj) {
				return 'null';
			}
			else if (obj.constructor == Function) {
				return '';
			}
			else if (Object.prototype.toString.apply(obj) === '[object Array]') {
				t.push('[');
				for (var n = 0; n < obj.length; n++) {
					var sub = this.toJSON(obj[n],cycle,level+1);
					if (null == sub) return null;
					t.push(((n>0)?',':'') + sub);
				}
				t.push(']');
			}
			else {
				var pc = 0;
				t.push('{\n');
				for (var p in obj) {
					if ('function' != typeof obj[p]) {
						if ((p.indexOf('_')==-1)||(p=='_class')) {
							// skip _props (except for _class)
							var sub = this.toJSON(obj[p],cycle,level+1);
							if (null == sub) return null;
							t.push(((pc++>0)?',':'') + '"' + p + '":' + sub);
						}
					}
				}
				t.push('}\n');
			}
			break;
		case 'function':
			break;
		case 'undefined':
			t.push('null');
			break
		default:
			// alert('Unknown type in toJSON: ' + typeof obj);
			break;
		}
		return t.join('');
	}
	catch(ex) {
		// fall through and return null
		// alert('Error in toJSON: ' + level + "; " + ex.message);
	}

	// failure
	return null;
}

/// Set the value of a named property.<br/>
/// This is part of the data controller API.
ClientMethod setProperty(property, value, value2) [ Internal, Language = javascript ]
{
	switch(property) {
	case 'content':
		this.setContentText(value);
		break;

	case 'targetClass':
		this.targetClass = value;
		break;
	case 'includeClassMarkup':
	case 'includeWhitespace':
		this[property] = !!value;
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

/// Return number of dimensions in the data.
/// Fixed at 2 for JSON.
ClientMethod getDimensions() [ Internal, Language = javascript ]
{
	return 2;
}

/// Reset the metadata for this provider. When used as a data controller
/// this will force recalculation of the meta data (property names) when this
/// data is next used for rendering.
ClientMethod resetMetaData() [ Final, Internal, Language = javascript ]
{
	this._metaData = null;
}

/// Determine the property names for the current data.<br/>
/// If the content type is "array", then assume that the model is an array of children and all children are the same.
/// If the content type is "object", use the properties of the object.
ClientMethod findMetaData() [ Final, Internal, Language = javascript ]
{
	if ((this._metaData) && (this._metaData.length > 0)) {
		return this._metaData;
	}

	this._metaData = [];

	// test for property list
	var props = {};
	var propertyList = zenGet(this.propertyList);
	if (propertyList!='') {
		var t = propertyList.toString().split(',');
		for (var n = 0; n < t.length; n++) {
			if (t[n] && t[n]!=='') {
				this._metaData[this._metaData.length] = t[n];
				props[t[n]] = true;
			}
		}
	}

	var data = this.getContentObject();
	if (data) {
		if (this.getContentType()=='array') {
			var array = this.getContentArray();
			var record = array ? array[0] : null;
			if (record) {
				for (var p in record) {
					if (p != this.seriesNameProperty && !props[p]) {
						if ('object' != typeof data[p]) {
							if (p.toString().charAt(0)!='_') {
								this._metaData[this._metaData.length] = p;
							}
						}
					}
				}
			}
		}
		else {
			// object
			this.getObjectMetaData(data,this._metaData,props,'');
		}
	}
	return this._metaData;
}

/// Add the properties in object <var>data</var> to the metaData list.
/// Ignore any properties in <var>props</props>.
ClientMethod getObjectMetaData(data, metaData, props, parent) [ Internal, Language = javascript ]
{
	for (var p in data) {
		// skip object-valued props and anything in the propertyList
		if (!props[p]) {
			if ('object' == typeof data[p] && data[p]!=null) {
				if (!this.isArray(data[p])) {
					// recurse
					this.getObjectMetaData(data[p],metaData,props,p);
				}
			}
			else {
				metaData[metaData.length] = ((parent!='')? parent+'.' : '')  + p;
			}
		}
	}
}

/// Return the number of items in the specified dimension
/// (<var>dim</var> is 1,2, or 3).
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	var size = 0;
	var data = this.getContentObject();
	var contentType = this.getContentType();

	switch (dim) {
	case 1:
		if (contentType == 'array') {
			var array = this.getContentArray();
			size = array ? array.length : 0;
		}
		else {
			size = data ? 1 : 0;
		}
		break;
	case 2:
		var meta = this.findMetaData();
		size = meta ? meta.length : 0;
		break;
	}
	return size;
}

/// This is a specialized variant of <method>getData</method> that
/// returns the data in this controller as an array of arrays (used
/// by charts).
ClientMethod getDataAsArrays() [ Final, Language = javascript ]
{
	var arrayData = null;
	var data = this.getContentObject();
	var array = this.getContentArray();
	if (array) {
		var meta = this.findMetaData();
		var items = array.length;
		var series = meta ? meta.length : 0;

		arrayData = new Array(series);
		for (var s = 0; s < series; s++) {
			arrayData[s] = new Array(items);
			for (var i = 0; i < items; i++) {
				arrayData[s][i] = array[i][meta[s]];
				if (arrayData[s][i]==null) {
					arrayData[s][i] = '';
				}
			}
		}
	}
	return arrayData;
}

/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	var label = '';
	var data = this.getContentObject();
	if (!data) {
		return '';
	}
	var contentType = this.getContentType();
	
	switch (dim) {
	case 1:
		if (contentType == 'array') {
			// item name from caption property
			var array = this.getContentArray();
			if (array) {
				var record = array[n];
				if (record) {
					// if no caption, use row number
					label = (this.seriesNameProperty!='' && record[this.seriesNameProperty]) ? record[this.seriesNameProperty] : (n+1);
				}
			}
		}
		else {
			label = (this.seriesNameProperty!='' && data[this.seriesNameProperty]) ? this.findObjectValue(data,this.seriesNameProperty) : 1;
		}
		break;
	case 2:
		// series names from properties of JSON object
		var meta = this.findMetaData();
		label = meta ? meta[n] : (n+1);
		break;
	}
	return label;
}

/// Return a title to display for this data source.
/// This provides the title for a chart.<br/>
/// <var>which</var> indicates which type of caption: "title", "subtitle",etc.
/// <var>text</var> is the original text for the caption.
ClientMethod getDataSourceCaption(which, text) [ Language = javascript ]
{
	return '';
}

/// Data API.
/// Lookup a value by its name.
ClientMethod getDataByName(property, series) [ Internal, Language = javascript ]
{
	var value = '';
	var data = this.getContentObject();
	if (!data) {
		return '';
	}
	var meta = this.findMetaData();
	if (!meta) {
		return '';
	}

	var contentType = this.getContentType();
	series = ('undefined'==typeof series) ? (parseInt(this.defaultSeries,10)-1) : parseInt(series,10);

	// find property in meta data
	for (var n = 0; n < meta.length; n++) {
		if (meta[n] && property==meta[n]) {
			if (contentType == 'array') {
				var array = this.getContentArray();
				if (array && array[series]) {
					var record = array[series];
					if (record) {
						value = record[meta[n]];
					}
				}
			}
			else {
				value = this.findObjectValue(data,[meta[n]]);
			}
			break;
		}
	}
	if (typeof value == 'undefined') {
		value = '';
	}
	return value;
}

/// dataSet API<br/>
/// Return the data contained in the specified location.
/// Location is 0-based.
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var value = '';
	var data = this.getContentObject();
	if (!data) {
		return '';
	}

	var meta = this.findMetaData();
	var contentType = this.getContentType();

	var row = d1;
	var col = (null===d2) ? 0 : d2;
	if (contentType == 'array') {
		var array = this.getContentArray();
		if (array && array[row]) {
			var record = array[row];
			if (record && meta && meta[col]) {
				value = record[meta[col]];
			}
		}
	}
	else {
		value = this.findObjectValue(data,meta[col]);
	}
	if (typeof value == 'undefined') {
		value = '';
	}
	return value;
}

/// Set the data contained in the specified location.
/// Location is 0-based.<br/>
/// This is part of the dataController API.
ClientMethod setData(value, d1, d2, d3) [ Internal, Language = javascript ]
{
	var data = this.getContentObject();
	if (!data) {
		return;
	}
	var meta = this.findMetaData();
	var contentType = this.getContentType();

	var row = d1;
	var col = (null===d2) ? 0 : d2;
	if (contentType == 'array') {
		// JMD1054
		var array = this.getContentArray();
		if (array && array[row]) {
			var record = array[row];
			if (record && meta && meta[col]) {
				if (record[meta[col]] !== value) {
					record[meta[col]] = value;
					this.raiseDataChange();
				}
			}
		}
	}
	else {
		if (this.findObjectValue(data,meta[col]) !== value) {
			this.setObjectValue(data,meta[col],value);
			this.raiseDataChange();
		}
	}
}

/// Given a 0-based index, return the corresponding property name.
ClientMethod getPropertyName(n) [ Language = javascript ]
{
	var meta = this.findMetaData();
	if (!meta) {
		return '';
	}
	return meta[n];
}

/// This is part of the data controller API.
/// Set a data value, by property name, into this dataController.<br>
/// If <var>property</var> is "%id", then change the id of this controller.<br>
/// If <var>property</var> is "%series", then change the 
/// <property>defaultSeries</property> of this controller.
ClientMethod setDataByName(property, value, series) [ Internal, Language = javascript ]
{
	switch(property) {
	case '':
		break;
	case '%id':
		this.setModelId(value);
		break;
	case '%series':
		this.setProperty('defaultSeries',value);
		break;
	default:
		series = ('undefined'==typeof series) ? (parseInt(this.defaultSeries,10) - 1) : parseInt(series,10);
		// set data into content object
		var data = this.getContentObject();
		if (data) {
			if (this.getContentType()=='array') {
				var array = this.getContentArray();
				if (array && array[series]) {
					if (array[series][property] !== value) {
						array[series][property] = value;
						this.raiseDataChange();
					}
				}
				else if (array && (series==0)) {
					// JMD: special case; if no records insert one
					if (!array[0]) {
						array[0] = {};
					}
					array[0][property] = value;
				}
			}
			else {
				if (this.findObjectValue(data,property) !== value) {
					this.setObjectValue(data,property,value);
					this.raiseDataChange();
				}
			}
		}
		break;
	}
}

/// Return true if this controller currently contains data.
ClientMethod hasData() [ Language = javascript ]
{
	var data = this.getContentObject();
	return data ? true : false;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// notify data views
	this.raiseDataChange();
	this.invokeSuper('onloadHandler',arguments);
}

/// Decode a reference to a property within the given data and return its value.
ClientMethod findObjectValue(data, prop) [ Internal, Language = javascript ]
{
	if (!data || !prop) {
		return '';
	}

	// test for a.b
	if (prop.toString().indexOf('.')>=0) {
		var t = prop.toString().split('.');
		var p1 = t[0];
		t.splice(0,1);
		return this.findObjectValue(data[p1],t.join('.'));
	}
	return data[prop];
}

/// Decode a reference to a property within the given data and set its value.
ClientMethod setObjectValue(data, prop, value) [ Internal, Language = javascript ]
{
	if (!data || !prop) {
		return;
	}

	// test for a.b
	if (prop.toString().indexOf('.')>=0) {
		var t = prop.toString().split('.');
		var p1 = t[0];
		t.splice(0,1);
		this.setObjectValue(data[p1],t.join('.'),value);
	}
	else {
		data[prop] = value;
	}
}

/// Internal method. Test if an object is an array.
ClientMethod isArray(obj) [ Internal, Language = javascript ]
{
	if (obj.constructor.toString().indexOf("Array") == -1) {
		return false;
	}
	return true;
}

/// Save data from this dataController back to the DataModel on the server.
/// Return the id with which the model was saved or '' if it was not saved.
ClientMethod save() [ Language = javascript ]
{
	// invoke the submit method
	this.submitContent('save');
	return '';
}

/// Return the array within the content object that supplies the values to a dataView.
ClientMethod getContentArray() [ Internal, Language = javascript ]
{
	var data = this.getContentObject();
	return data && data.children ? data.children : null;
}

}
