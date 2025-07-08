/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is the base class for Studio Assist schema generators that
/// are based on XML-enabled class definitions.
Class %Studio.SASchemaClass Extends %Studio.SASchema [ Abstract, System = 3 ]
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE As STRING;

/// This is a comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document separated with a ':' and the
/// XML tag name to correlate this with e.g. "User.Person:person,User.Company:company".
Parameter ROOTCLASSES As STRING;

/// Optional. This is a comma-separated list of category names. If specified,
/// only classes that contain an SACATEGORY parameter included in the list will be added to
/// the schema. This provides a way to create a subset of a larger set of components.
Parameter SACATEGORY As STRING;

/// Output SASchema definition into a stream
ClassMethod OutputToStream(pStream As %Stream.Object, Output pChecksum As %String, pParameter As %String) As %Status
{
	New %saPrefixMap  // keep track of what ns prefixes are in use
	Kill %saPrefixMap

	New %saKeyAttrs  // keep track of array key names
	Kill %saKeyAttrs

	New %saAliases  // keep track of aliases (property that refers to a specific type)
	Kill %saAliases

	New %saCategories	// keep track of categories
	Kill %saCategories

	If (..#SACATEGORY'="") {
		For p = 1:1:$L(..#SACATEGORY,",") {
			Set tCat = $P(..#SACATEGORY,",",p)
			Set:tCat'="" %saCategories($$$UPPER(tCat)) = ""
		}
	}

	#; make sure default zen prefix overrides user-defines
	Set %saPrefixMap("p","zen") = ""
	Set %saPrefixMap("s","http://www.intersystems.com/zen") = "zen"

	Set tSC = $$$OK
	If (..#ROOTCLASSES="") {
		Quit $$$ERROR($$$NotImplemented)
	}
	Set $ZT="Trap"

	#; do not allow concurrent building of the schema
	Lock +^IRIS.SASchema(pStream):30
	Quit:'$T $$$ERROR($$$GeneralError,"Unable to acquire lock for schema") 

	#; context variables needed for processesing
	New %VisitedClasses,%VisitedElements,%ElementCache

	#; use the time this schema was generated as a checksum
	Set pChecksum = $H

	#; cache checksum in the ^%IRIS.SASchema.Timestamp global
	If (..#XMLNAMESPACE '= "") {
		Set ^%IRIS.SASchema.Timestamp(..#XMLNAMESPACE) = pChecksum
	}
	For p = 1:1:$L(..#ROOTCLASSES,",") {
		Set tCls = $piece($P(..#ROOTCLASSES,",",p),":")
		Set:tCls'="" tClassList(tCls) = ""
	}
	kill ^||%Studio.Schema
	set tSC=..GetSchemaForClasses(.tClassList) quit:$$$ISERR(tSC) tSC
	set tSC=..loopGlobal(pStream)
	kill ^||%Studio.Schema
Done
	Lock -^IRIS.SASchema(pStream)
	Quit tSC
Trap
	Lock -^IRIS.SASchema(pStream) // JMD273
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Done
}

ClassMethod IsUpToDate(pChecksum As %String, pParameter As %String) As %Boolean
{
	Set tChecksum = ""
	If (..#XMLNAMESPACE '= "") {
		Set tChecksum = $G(^%IRIS.SASchema.Timestamp(..#XMLNAMESPACE))
	}
	Quit pChecksum = tChecksum
}

/// Internal method.
/// Given an array of class names, that correspond to the top-level elements
/// within an XML document, find the simplified SASchema used by the Studio
/// Assistant.<br>
/// <var>ppDefaultNS</var> is the default XML namespace for the schema.
ClassMethod GetSchemaForClasses(ByRef pClassList As %String) As %Status [ Private ]
{
	Set tSC = $$$OK
	Do {
		#; start with list of top-level elements
		#; find list of all possible elements
 		Set tClass = $O(pClassList(""))
		While (tClass '= "") {
			Set tTopName = ..GetXMLNameForClass(tClass)
			Set ppDefaultNS = ..XMLName2NameSpace(tTopName)

			If ppDefaultNS="" {
				Set tSC=$$$ERROR($$$NoDefaultNamespaceForClass,tClass) Quit
			}

			Set ppCurrentNS = ppDefaultNS
			Set %VisitedClasses(tClass) = ""
			Set %VisitedElements(tTopName) = ""
			Set tFixedTopName = ..XMLName2DisplayName(tTopName,ppCurrentNS)
			If ('+$G(%useronly) || (tClass'["%")) {
				set ^||%Studio.Schema(ppDefaultNS,ppCurrentNS,tFixedTopName,"top")=1
			}

			Kill tLocalList

			#; get list of elements within this top-level
			Set tSC = ..GetElementsForClass(tClass,.tLocalList,.tRefClasses)
			If $$$ISERR(tSC) Quit

			Set tEl = $O(tLocalList(""))
			While (tEl '= "") {
				#; Skip if INCLUDEGROUP = 0
				Set tIncGroup = $$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
				If (tIncGroup '= 0) {
					If ('+$G(%useronly) || (tLocalList(tEl)'["%")) {
						Set tSkip = 0
						If ($D(%saCategories)) {
							// check categories
							Set tCat = $$$UPPER($$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"SACATEGORY",$$$cPARAMdefault))
							If ((tCat="")||'$D(%saCategories(tCat))) {
								Set tSkip = 1
							}
						}
						If ('tSkip) {
							set ^||%Studio.Schema(ppDefaultNS,ppCurrentNS,tFixedTopName,"sub",..XMLName2DisplayName(tEl,ppCurrentNS))=""
						}
					}
				}
				Set tEl = $O(tLocalList(tEl))
			}

			#; merge elements into list of ALL elements
			Merge tElementList = tLocalList

			Set tClass = $O(pClassList(tClass))
		}
		If $$$ISERR(tSC) Quit

		#; now walk over set of possible elements
		#; and make list of what elements are contained by other elements
		Set tElement = $O(tElementList(""))
		While (tElement '= "") {
			#; skip if visited
			Set tClass = tElementList(tElement)

			If ('$D(%VisitedClasses(tClass)) && '$D(%VisitedElements(tElement))) {
				Set %VisitedClasses(tClass) = ""
				Set %VisitedElements(tElement) = ""
				Kill tLocalList
				
				#; see if we need to switch NS
				Set ppCurrentNS = ..XMLName2NameSpace(tElement)

				#; get list of elements within this element
				Set tSC = ..GetElementsForClass(tClass,.tLocalList,.tRefClasses)
				If $$$ISERR(tSC) Quit

				Set tFixedName = ..XMLName2DisplayName(tElement,ppCurrentNS)
				Set tEl = $O(tLocalList(""))
				While (tEl '= "") {
					#; Skip if INCLUDEGROUP = 0
					Set tIncGroup = $$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
					If (tIncGroup '= 0) {
						If ('+$G(%useronly) || (tLocalList(tEl)'["%")) {
							Set tSkip = 0
							If ($D(%saCategories)) {
								// check categories
								Set tCat = $$$UPPER($$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"SACATEGORY",$$$cPARAMdefault))
								If ((tCat="")||'$D(%saCategories(tCat))) {
									Set tSkip = 1
								}
							}
							If ('tSkip) {
								set ^||%Studio.Schema(ppDefaultNS,ppCurrentNS,tFixedName,"sub",..XMLName2DisplayName(tEl,ppCurrentNS))=""
							}
						}
					}
					Set tEl = $O(tLocalList(tEl))
				}
			}
			Set tElement = $O(tElementList(tElement))
		}

		Set count = 0 // loop counter
		Set done = '+$D(tRefClasses)
		While ('done && (count < 100)) {
			Set count = count + 1
			// now process list of classes that were referenced by other elements
			Kill tRefClasses2
			Set tClass = $O(tRefClasses(""))
			While (tClass '= "") {
				Set tElement = ..GetXMLNameForClass(tClass)

				If ((..XMLName2NameSpace(tElement)'="") && '$D(%VisitedClasses(tClass))&&'$D(%VisitedElements(tElement))) {
					Set %VisitedClasses(tClass) = ""
					Set %VisitedElements(tElement) = ""
					#; add to list to pick up attrs
					Set tElementList(tElement) = tClass

					Kill tLocalList

					#; write out subelements, if any
					#; see if we need to switch NS
					Set ppCurrentNS = ..XMLName2NameSpace(tElement)
		
					#; get list of elements within this element
					Set tSC = ..GetElementsForClass(tClass,.tLocalList,.tRefClasses2)
					If $$$ISERR(tSC) Quit
	
					Set tFixedName = ..XMLName2DisplayName(tElement,ppCurrentNS)
					Set tEl = $O(tLocalList(""))
					While (tEl '= "") {
						#; Skip if INCLUDEGROUP = 0
						Set tIncGroup = $$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
						If (tIncGroup '= 0) {
							If ('+$G(%useronly) || (tLocalList(tEl)'["%")) {
								Set tSkip = 0
								If ($D(%saCategories)) {
									// check categories
									Set tCat = $$$UPPER($$$comMemberKeyGet(tLocalList(tEl),$$$cCLASSparameter,"SACATEGORY",$$$cPARAMdefault))
									If ((tCat="")||'$D(%saCategories(tCat))) {
										Set tSkip = 1
									}
								}
								If ('tSkip) {
									set ^||%Studio.Schema(ppDefaultNS,ppCurrentNS,tFixedName,"sub",..XMLName2DisplayName(tEl,ppCurrentNS))=""
								}
							}
						}
						Set tEl = $O(tLocalList(tEl))
					}
				}
				Set tClass = $O(tRefClasses(tClass))
			}
			
			#; more to do
			If ($D(tRefClasses2)) {
				Set done = 0
				Kill tRefClasses
				Merge tRefClasses = tRefClasses2
			}
			Else {
				Set done = 1
			}
		}

		#; JMD544
		#; Make sure every topclass gets its attributes processed
 		Set tClass = $O(pClassList(""))
		While (tClass '= "") {
			Set tElementList(..GetXMLNameForClass(tClass)) = tClass
			Set tClass = $O(pClassList(tClass))
		}

		#; now walk over set of all possible elements
		#; and write out attribute definitions for each
		Set tElement = $O(tElementList(""))
		While (tElement '= "") {
			Kill tAttrList
			Set tClass = tElementList(tElement)
			Set tSC = ..GetAttrsForClass(tClass,.tAttrList)
			If $$$ISERR(tSC) Quit

			#; test for additional key attributes for this element
			#; JMD381
			If $D(%saKeyAttrs(tClass)) {
				Set parcls = $O(%saKeyAttrs(tClass,""))
				While (parcls '= "") {
					Set prop = $O(%saKeyAttrs(tClass,parcls,""))
					While (prop '= "") {
						Set a = $G(%saKeyAttrs(tClass,parcls,prop))
						If (a '= "") {
							Set tAttrList(a) = ""
						}
						Set prop = $O(%saKeyAttrs(tClass,parcls,prop))
					}
					Set parcls = $O(%saKeyAttrs(tClass,parcls))
				}
			}

			If ('+$G(%useronly) || (tClass'["%")) {
				If $D(tAttrList) {
					Set tSkip = 0
					If ($D(%saCategories)) {
						// check categories
						Set tCat = $$$UPPER($$$comMemberKeyGet(tClass,$$$cCLASSparameter,"SACATEGORY",$$$cPARAMdefault))
						If ((tCat="")||'$D(%saCategories(tCat))) {
							Set tSkip = 1
						}
					}
					If ('tSkip) {
						#; see if we need to switch NS
						Set ppCurrentNS = ..XMLName2NameSpace(tElement)
						Set n = 0
						set tFixedElementName=..XMLName2DisplayName(tElement,ppCurrentNS)
						Set tAttr = $O(tAttrList(""))
						While (tAttr '= "") {
							Set tType = tAttrList(tAttr)
							set ^||%Studio.Schema(ppDefaultNS,ppCurrentNS,tFixedElementName,"att",tAttr)=tType
							Set n = n + 1
							Set tAttr = $O(tAttrList(tAttr))
						}
					}
				}
			}
			Set tElement = $O(tElementList(tElement))
		}
		If $$$ISERR(tSC) Quit

	} While(0)

	Quit tSC
}

/// Given a class (and default namespace) find the list of XML elements
/// it can contain.
/// This list of the form: ^List(el) = class<br/>
ClassMethod GetElementsForClass(pClass As %String, Output pElementList, Output pReferencedClasses) As %Status
{
	Set tSC = $$$OK

	Do {
		#; only deal with compiled classes
		#; gather properties as attributes or elements
		If ($$$comClassDefined(pClass)) {
			Set tAbstract = +$$$comClassKeyGet(pClass,$$$cCLASSabstract)
			If ('tAbstract) {
				#; get all properties of this class
				Set tRS = ##class(%ResultSet).%New("%Dictionary.CompiledClass.MemberSummary")
				Set tSC = tRS.%Execute(pClass,"a")
				If $$$ISERR(tSC) Quit

				While (tRS.%Next(.tSC)) {
					If $$$ISERR(tSC) Quit
					Set tName = tRS.Data("Name")
					If (tName ["%%") Continue  // internal property
					Set tType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tName,$$$cPROPtype)
					Set tCollect = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tName,$$$cPROPcollection)
					Set tXML = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLPROJECTION")
					Set tXMLName = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLNAME")
					Set tXMLKey = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLKEYNAME")

					Set tXML = $ZCVT(tXML,"L")
					Set:tXML="" tXML="element"
					Set:tXMLName="" tXMLName = tName
	
					If (tXML = "element") {
						#; find out if this an object-valued property
						#; get normalized type of property
						#; figure out the classtype for the property
						#; first normalize the type name
						If ((tType '[ ".") && (tType '[ "%")) {
							#; assume this type belongs to our package
							Set tType = $P(pClass,".",1,$L(pClass,".")-1) _ "." _ tType
						}
						Set tType = $$$NormalizeClassname(tType)

						If (tCollect="array") {
							If (tXMLKey '= "") {
								#; We use the globally visible variable, %saKeyAttrs,
								#; to track additional elements used as array keys.
								#; This implementation is not correct; in the general case
								#; the same element could be used in different contexts with
								#; different key names. This is not very typical, however.
								Set %saKeyAttrs(tType,pClass,tName) = tXMLKey
							}
						}

						If ($$$classIsDataType(tType)) {
							#; add literal element to list
							Set tDTNS = ..XMLName2NameSpace(..GetXMLNameForClass(pClass))
							If (tDTNS'="") {
								Set pElementList($LB(tDTNS,tXMLName)) = tType
							}
						}
						Else {
							Set pReferencedClasses(tType) = ""
							#; Skip if INCLUDEGROUP = 0
							Set tIncGroup = $$$comMemberKeyGet(tType,$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
							If (tIncGroup '= 0) {
								Set tElements(tXMLName) = tType
								Set:tCollect="" tElementsRef(tXMLName,tName) = "" // JMD517
							}
						}
					}
				}
				If $$$ISERR(tSC) Quit

				#; process elements
				#; (for each element expand into available subclasses)
				Set tEl = $O(tElements(""))
				While (tEl '= "") {
					Kill tChoiceList
					Set tSubClass = tElements(tEl)

					if tSubClass'="%Library.RegisteredObject",tSubClass'="%Library.SerialObject",tSubClass'="%Library.Persistent" {
						Set tSC = ..GetXMLElementsForClass(tSubClass,.tChoiceList)
					}

					Set k = $O(tChoiceList(""))
					While (k'="") {
						If $D(tElementsRef(tEl)) { // non-collection, reference property
							// for each property that refers to this, there is an entry
							Set xn = $O(tElementsRef(tEl,""))
							While (xn'="") {
								Set k2 = k
								Set $List(k2,2) = xn
								Set pElementList(k2) = tChoiceList(k)
								Set tType = $$$NormalizeClassname(tChoiceList(k))
								If ('$$$classIsDataType(tType)) {
									// set up alias so that this name refers to correct class
									// n.b. this assumes that property names do not conflict!
									Set %saAliases($LG(k2,1),$LG(k2,2)) = $LG(k,2)
								}
								Set xn = $O(tElementsRef(tEl,xn))
							}
						}
						Else {
							Set tType = $$$NormalizeClassname(tChoiceList(k))
							If ('$$$classIsDataType(tType)) {
								#; JMD544
								#; Skip if INCLUDEGROUP = 0 OR abstract
								Set tIncGroup = $$$comMemberKeyGet(tType,$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
								Set tTypeAbstract = +$$$comClassKeyGet(tType,$$$cCLASSabstract)
								If ('tTypeAbstract && (tIncGroup '= 0)) {
									Set pElementList(k) = tChoiceList(k)		
									Set pReferencedClasses(tType) = ""
								}
							}
							Else {
								Set pElementList(k) = tChoiceList(k)
							}
						}
						Set k = $O(tChoiceList(k))
					}
					Set tEl = $O(tElements(tEl))
				}
			}
		}
	} While(0)

	Quit tSC
}

/// Given a class (and default namespace) find the list of XML attributes
/// it can contain.
ClassMethod GetAttrsForClass(pClass As %String, Output pAttrList) As %Status
{
	Set tSC = $$$OK
	Do {
		#; only deal with compiled classes
		#; gather properties as attributes or elements
		If ((pClass'="") && $$$comClassDefined(pClass)) {
			Set tAbstract = +$$$comClassKeyGet(pClass,$$$cCLASSabstract)
			If ('tAbstract) {
				#; get all properties of this class
				Set tRS = ##class(%ResultSet).%New("%Dictionary.CompiledClass.MemberSummary")
				Set tSC = tRS.%Execute(pClass,"a")
				If $$$ISERR(tSC) Quit

				While (tRS.%Next(.tSC)) {
					If $$$ISERR(tSC) Quit
					Set tName = tRS.Data("Name")
					Set tType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tName,$$$cPROPtype)
					Set tCollect = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tName,$$$cPROPcollection)
					Set tXML = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLPROJECTION")
					Set tXMLName = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLNAME")

					#; for VALUELIST, first look at property, then datatype
					Set tEnum = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"DISPLAYLIST")
					If tEnum="" Set tEnum = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"VALUELIST")
					If ((tType'="") && $$$comClassDefined(tType)) {
						If tEnum="" Set tEnum=$$$comMemberKeyGet(tType,$$$cCLASSparameter,"DISPLAYLIST",$$$cPARAMdefault)
						If tEnum="" Set tEnum=$$$comMemberKeyGet(tType,$$$cCLASSparameter,"VALUELIST",$$$cPARAMdefault)
					}
					#; JMD400: make sure XML values get escaped
					Set tEnum = $ZCVT(tEnum,"O","XML")

					Set tXML = $ZCVT(tXML,"L")
					Set:tXML="" tXML="element"
					Set:tXMLName="" tXMLName = tName
					
					If (tXML = "attribute") {
						#; see if this is a type with a known moniker

						Set tMoniker = ""
						If (tType = "%ZEN.Datatype.sql") {
							Set tMoniker = "@lang:SQL"
						}
						ElseIf ((tType = "%ZEN.Datatype.eventHandler")|| (tType = "%ZEN.Datatype.script")) {
							Set tMoniker = "@lang:JAVASCRIPT"
						}
						ElseIf ((tType = "%ZEN.Datatype.style")|| (tType = "%ZEN.Datatype.svgStyle")) {
							Set tMoniker = ""
							// Set tMoniker = "@lang:CSS!DECLNS"
						}
						ElseIf ((tType = "%ZEN.Datatype.expression")||(tType = "%ZEN.Datatype.glvn")) {
							#; for glvn, OBJECTSCRIPT is good enough
							Set tLang = $$$comMemberArrayGet(pClass,$$$cCLASSproperty,tName,$$$cPROPparameter,"LANGUAGE")
							Set:tLang="" tLang = "OBJECTSCRIPT"
							Set tMoniker = "@lang:"_tLang_"!EXPRESSION"
						}
						ElseIf ((tType = "%ZEN.Datatype.boolean")||(tType = "%Library.Boolean")) {
							Set tMoniker = "@enum:!,true,false"
						}
						ElseIf (tType="%ZEN.Datatype.className") {
							Set tMoniker = "@lang:OBJECTSCRIPT!CLASSNAME"
						}
						Else {
							If tEnum'="" Set tMoniker="@enum:!"_tEnum
						}

						Set pAttrList(tXMLName) = tMoniker
					}
				}
				If $$$ISERR(tSC) Quit
			}
		}
	} While(0)

	Quit tSC
}

/// Return an array of XML element names that could be used within a
/// document wherever <var>pClass</var> is expected.
ClassMethod GetXMLElementsForClass(pClass As %String, Output pElements) As %Status
{
	Set tSC = $$$OK
	Do {
		If $D(%ElementCache(pClass)) {
			Merge pElements = %ElementCache(pClass)
		}
		Else {
			If ($$$comClassDefined(pClass)) {
				#; Get XML name of this class
				Set tXMLName = ..GetXMLNameForClass(pClass)
				If (..XMLName2NameSpace(tXMLName)'="") {
					Set pElements(tXMLName) = pClass
				}

				#; Now find all subclasses of this class
				#; Unless INCLUDEGROUP = 0
				Set tIncGroup = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"XMLINCLUDEINGROUP",$$$cPARAMdefault)
				If (tIncGroup '= 0) {
					Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
					Set tSC = tRS.%Execute(pClass)
					If $$$ISERR(tSC) Quit

					While (tRS.%Next(.tSC)) {
						If $$$ISERR(tSC) Quit
						Set tSubClass = tRS.Data("Name")
						Set tXMLName = ..GetXMLNameForClass(tSubClass)
						If (..XMLName2NameSpace(tXMLName)'="") {
							Set pElements(tXMLName) = tSubClass
						}
					}
					If $$$ISERR(tSC) Quit
				}

				#; place in cache
				Merge %ElementCache(pClass) = pElements
			}
		}
	} While(0)

	Quit tSC
}

/// Return the XML name for the given class (or "" if there is none).
/// If the class is not in the default namespace, its namespace will
/// be prepended to the XML name.
ClassMethod GetXMLNameForClass(pClass As %String) As %String
{
	Set tXMLName = ""
	If ($$$comClassDefined(pClass)) {
		#; Get XML name of this class
		Set tXMLName = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
		Set:tXMLName="" tXMLName=$P(pClass,".",$L(pClass,"."))

		#; Get XML namespace of this class
		Set tNS = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
		Set tXMLName = $lb(tNS,tXMLName)
	}
	Quit tXMLName
}

/// Take an element and make sure it has the correct namespace prefix
/// to match the given local namespace context.
ClassMethod XMLName2DisplayName(pName As %String, pCurrentNS As %String) As %String
{
	Set tNameSpace = ..XMLName2NameSpace(pName)
	Set tShortName = ..XMLName2ShortName(pName)
	If (tNameSpace = pCurrentNS) {
		Quit tShortName
	} Else {
		Quit ..SchemaToPrefix(tNameSpace) _ ":" _ tShortName
	}
}

ClassMethod XMLName2NameSpace(pName) As %String [ CodeMode = expression ]
{
$ListGet(pName,1)
}

ClassMethod XMLName2ShortName(pName) As %String [ CodeMode = expression ]
{
$ListGet(pName,2)
}

/// Loop through the global to generate the output for the Studio.
ClassMethod loopGlobal(pStream As %Stream.Object) As %Status [ Private ]
{
	#; get the default namespace
	set tNamespace=$o(^||%Studio.Schema(""))
	#; output namespace prefix mappings
	do pStream.WriteLine("# start prefix-mapping section")
	set ns="" for  {
		set ns=$o(^||%Studio.Schema(tNamespace,ns)) quit:ns=""
		set prefix=..SchemaToPrefix(ns)
		do pStream.WriteLine("!prefix-mapping:"_prefix_":"_ns)
	}
	#; output default namespace
	do pStream.WriteLine("# define default-namespace")
	do pStream.WriteLine("!default-namespace:"_tNamespace)
	#; output one namespace at a time, always start with the default namespace
	set ns=tNamespace
	do {
		#; output namespace default prefix
		set prefix=..SchemaToPrefix(ns)
		do pStream.WriteLine("# element definition for '"_prefix_"'")
		do pStream.WriteLine("!default-prefix:"_prefix)
		#; output top elements
		set ele="" for  {
			set ele=$o(^||%Studio.Schema(tNamespace,ns,ele)) quit:ele=""
			if '$g(^||%Studio.Schema(tNamespace,ns,ele,"top")) continue
			do pStream.WriteLine("/#"_ele)
		}
		#; output element/subelement
		set ele="" for  {
			set ele=$o(^||%Studio.Schema(tNamespace,ns,ele)) quit:ele=""
			do pStream.WriteLine(ele)
			set sub="" for  {
				set sub=$o(^||%Studio.Schema(tNamespace,ns,ele,"sub",sub)) quit:sub=""
				do pStream.WriteLine(ele_"/#"_sub)
			}
		}
		#; output element attribute definition
		set ele="" for  {
			set ele=$o(^||%Studio.Schema(tNamespace,ns,ele)) quit:ele=""
			set att="" for  {
				set att=$o(^||%Studio.Schema(tNamespace,ns,ele,"att",att)) quit:att=""
				do pStream.WriteLine(ele_"|"_att_^||%Studio.Schema(tNamespace,ns,ele,"att",att))
			}
		}
		
		#; process aliases, if any JMD517
		If ($D(%saAliases(ns))) {
			Set k = $O(%saAliases(ns,""))
			While (k '= "") {
				#; output element/subelement
				set ele=$G(%saAliases(ns,k))
				If (ele'="") {
					do pStream.WriteLine(k)
					set sub="" for  {
						set sub=$o(^||%Studio.Schema(tNamespace,ns,ele,"sub",sub)) quit:sub=""
						do pStream.WriteLine(k_"/#"_sub)
					}
				}

				#; output element attribute definition
				set ele=$G(%saAliases(ns,k))
				If (ele'="") {
					set att="" for  {
						set att=$o(^||%Studio.Schema(tNamespace,ns,ele,"att",att)) quit:att=""
						do pStream.WriteLine(k_"|"_att_^||%Studio.Schema(tNamespace,ns,ele,"att",att))
					}
				}

				#; remove from list
				Kill %saAliases(ns,k)
				Set k = $O(%saAliases(ns,k))
			}
		}
		
		
		if ns=tNamespace set ns=""
		set ns=$o(^||%Studio.Schema(tNamespace,ns))
		if ns=tNamespace set ns=$o(^||%Studio.Schema(tNamespace,ns))
	} while (ns'="")

	Quit $$$OK
}

/// Convert a schema name to a reasonable "prefix".
ClassMethod SchemaToPrefix(pSchema As %String) As %String
{
	Quit:pSchema="" ""

	#; if present use map
	If $D(%saPrefixMap("s",pSchema)) {
		#; we have already defined a prefix for this schema
		Quit $G(%saPrefixMap("s",pSchema))
	}
	
	#; strip punctuation, return last word
	Set tPrefix = $TR(pSchema,"/;:\@#$%*()","           ")
	Set tPrefix = $ZCVT($P(tPrefix," ",$L(tPrefix," ")),"L")
	Set:tPrefix="" tPrefix="-na-"

	#; add to map; make sure prefix is not already in use
	Set n = ""
	While ($D(%saPrefixMap("p",tPrefix_n))) {
		Set n = n + 1
	}
	Set tPrefix = tPrefix_n
	Set %saPrefixMap("p",tPrefix) = ""
	Set %saPrefixMap("s",pSchema) = tPrefix
	Quit tPrefix
}

}
