/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%xmlMap, %soap)

/// The <class>%XML.Schema</class> controls creation of an XML Schema from InterSystems IRIS.
/// It generates a complete XML document that contains the schema including the &lt;?xml&gt; tag.
/// XML types are added to the schema by using the <method>AddSchemaType</method> method.
/// The schema is build up in an XML DOM by <method>AddSchemaType</method> and may later
/// be output using %XML.Writer.  The <method>DocumentNode</method> or <method>Tree</method> methods of the
/// <class>%XML.Writer</class> class can be used to output the schema.<br>
/// 
/// XML namespace handling is for the most part automatic.  
/// <class>%XML.Schema</class> adds namespaces for which %XML.Writer then automatically
/// creates prefixes for the XML output as needed. The XML namespaces for which schemas
/// are created are listed in the Namespaces property which is a list of strings. 
/// The GetSchema method is used to get the XML DOM node for a namespace's schema.<br>
/// 
/// The following example can be executed in the SAMPLES namespace.<br>
/// 
/// <example>
/// 	; Get %XML.Schema instance.
/// 	set schema=##class(%XML.Schema).%New()
/// 	set namespace="http://tempuri.org/ISC/Samples"
/// 	set schema.DefaultNamespace=namespace
/// 	; Get %XML.Writer instance.
/// 	set writer=##class(%XML.Writer).%New()
/// 	set writer.Indent=1
/// 	do writer.AddSchemaNamespace()
/// 	do writer.AddNamespace(namespace,"sample")
/// 	; Add Company.  Note that referenced types are also added.
/// 	set status=schema.AddSchemaType("Sample.Company")
/// 	if $system.Status.IsError(status) do $system.Status.DisplayError(status) quit
/// 	; Add Vendor.
/// 	set status=schema.AddSchemaType("Sample.Vendor")
/// 	if $system.Status.IsError(status) do $system.Status.DisplayError(status) quit
/// 	; Verify that we have just our expected namespace.
/// 	; This is included for just for illustration.
/// 	if (schema.Namespaces.Count()'=1) || (schema.Namespaces.GetAt(1)'=namespace) {
/// 		write !,"Unexpected namespace found",!
/// 		write !,"List Of Namespace: ",!
/// 		for i=1:1:schema.Namespaces.Count() {
/// 			write "    ",schema.Namespaces.GetAt(i),!
/// 		}
/// 		write !
/// 		quit
/// 	}
/// 	; Output the schema.
/// 	set status=writer.DocumentNode(schema.GetSchema(namespace))
/// </example>
/// 
/// %XML.Schema automatically adds import elements to the generated schema.
/// It is the responsibility of the user code to 
/// use the DefineLocation method to define the schemaLocation.
/// See the following example of use DefineLocation for multiple namespaces:
/// 
/// <example>
///   // className is the name of a class which references classes defined in 
///   // multiple namespaces.  For example: className="test.A" in namespace "urn:testA",
///   // test.A references test.B (in namespace "urn:testB") and test.C (in namespace "urn:testC").
///   try {
/// 		#; get a schema writer
/// 		set schemaWriter = ##class(%XML.Schema).%New()
/// 		set sc = schemaWriter.AddSchemaType(className)
/// 		if ($$$ISOK(sc)) {
/// 			set namespaces = schemaWriter.Namespaces
/// 			for i=1:1:namespaces.Count() {
/// 				set ns=namespaces.GetAt(i)
/// 				// set file path according to application dependent formula
/// 				set locations(ns)="c:\temp\"_$piece(ns,":",2)_".xml"
/// 				do schemaWriter.DefineLocation(ns,locations(ns))
/// 			}
/// 			for i=1:1:namespaces.Count() {
/// 				set ns=namespaces.GetAt(i)
/// 				set schema = schemaWriter.GetSchema(ns)
/// 				set writer = ##class(%XML.Writer).%New()
/// 				do writer.OutputToFile(locations(ns))
/// 				set writer.Indent = 1
/// 				set sc=writer.DocumentNode(schema)
/// 				If $$$ISERR(sc) do $system.OBJ.DisplayError(sc) Quit
/// 				do writer.Reset()
/// 			}
/// 		} else {
/// 			do $system.OBJ.DisplayError(sc)
/// 		}
/// 	  } catch(tException) {
/// 		do $system.OBJ.DisplayError(tException.AsStatus())
/// 	  }
/// </example>
Class %XML.Schema Extends %RegisteredObject [ System = 3 ]
{

/// <property>DefaultNamespace</property> is the XML namespace to use
/// for any classes that do not have the NAMESPACE parameter
/// specified.  If the NAMESPACE parameter is specified for a class,
/// then the namespace specified in the class is always used.
Property DefaultNamespace As %String;

/// If <property>IncludeDocumentation</property> is true, then the class and property
/// comments are included in the schema as <xs:documentation> elements.
/// The default is to include the documentation.
Property IncludeDocumentation As %Boolean [ InitialExpression = 1 ];

/// If <property>AllowRedundantArrayName</property> is true, then an array name that is used for an ObjectScript list
/// or a pair type name that is used for an ObjectScript array will be allowed to have a type name = to the item name.<br>
/// <br>
/// The normal format of an array name for a List is ArrayOf<item name><type name>.
/// If <item name>=<type name>, then <type name> is not appended unless AllowRedundantArrayName is true.<br>
/// <br>
/// The normal format of an array name for an Array is ArrayOf<item name>PairOf<key name><type name>.
/// If <key name>=<type name>, then <type name> is not appended unless AllowRedundantArrayName is true.
Property AllowRedundantArrayName As %Boolean;

/// suppressDocumentation is a one class only override of IncludeDocumentation.
Property suppressDocumentation As %Boolean [ Internal, Private ];

/// Document to hold the schemas that we are creating.
/// The document consists of a root element that contains all the schemas as it's children.
/// This property should not be set by the caller.
Property Document As %XML.Document [ Internal ];

/// List of referenced namespaces
///    Namespaces = count of namespaces defined
///    Namespaces(namespaceIndex)=namespace
Property Namespaces As %ListOfDataTypes;

/// To suppress namespace handling in the schema, set NoNamespace=1.
/// Used to support old XMLSchema method.
Property NoNamespace As %Boolean [ Internal ];

/// If NoNamespace = true, then optional prefix to use for referenced XML types.
/// Used to support old XMLSchema method.
Property NamespacePrefix As %String [ Internal ];

Method NamespacePrefixSet(namespacePrefix As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	Set namespacePrefix=$get(namespacePrefix) 
	If (namespacePrefix'="")&&($extract(namespacePrefix,*)'=":") Set namespacePrefix=namespacePrefix_":"
	Set i%NamespacePrefix=namespacePrefix
	Quit $$$OK
}

/// List of XML elments and types defined for namespace.
/// <property>schema</property> defines the portion of the global for this schema.
///    ^||%xmlName(..schema,namespaceIndex,element,name)=$lb(class,encoded,input,summary)
/// namespaceIndex = index for XML namespace
/// index = order of definition within namespace
/// element = true for element with inline complexType, false for complexType
/// class = class name for "c" or "e", otherwise base type.
/// name = name of XML type/element
/// encoded = "e" for encoded or "" for literal
/// input = 1 or 0
/// summary = 1 or 0
Property schema As %Integer [ Internal, Private ];

/// The SOAP service name for a web service with SOAPBINARY=1 specified.
Property ServiceName As %String [ Internal ];

/// Index for each namespace.
/// namespaceIndices(namespace)=namespaceIndex
Property namespaceIndices As %String [ Internal, MultiDimensional, Private ];

/// Schema ElementQualified for each namespace.
/// namespaceElementQualified(namespace)=ElementQualified
Property namespaceElementQualified As %Boolean [ Internal, MultiDimensional, Private ];

/// Schema AttributeQualified for each namespace.
/// namespaceAttributeQualified(namespace)=AttributeQualified
Property namespaceAttributeQualified As %Boolean [ Internal, MultiDimensional, Private ];

/// Schema encoded for each namespace.
/// namespaceEncoded(namespace) = 1 for SOAP 1.1 encoded and 2 for SOAP 1.2 encoded
Property namespaceEncoded As %Integer [ Internal, MultiDimensional, Private ];

/// Schema node for each namespace.
/// namespaceSchema(namespace)=schema node id
Property namespaceSchema As %Integer [ Internal, MultiDimensional, Private ];

/// Namespaces which are imported by each namespace:
///     namespaceImport(namespaceIndex,importNamespace)=location
/// namespaceImport(namespaceIndex)=1 if the schema has already had import ele ments added.
Property namespaceImport As %String [ Internal, MultiDimensional, Private ];

/// Location of import for each namespace:
///     locations(importNamespace)=location
Property locations As %String [ Internal, MultiDimensional, Private ];

/// Initialize schema index and schema document on constuction of object,
/// <property>rootName</property> is the name used for the dummy root element
/// in the schema document.
Method %OnNew(rootName As %String) As %Status [ ServerOnly = 1 ]
{
	Set ..schema=$increment(^||%xmlName)
	Set ^||%xmlName=..schema

	Set ..Document=##class(%XML.Document).CreateDocument($get(rootName,"dummy"))
	
	Quit $$$OK
}

Method %OnClose() As %Status [ ServerOnly = 1 ]
{
	If ..schema'="" {
		Kill ^||%xmlName(..schema)
	}
	Quit $$$OK
}

/// Add a complexType to the schema.
/// 
/// <var>class</var> is the name of the class which corresponds to the complexType.<br>
/// 
/// <var>top</var> is the optional override of the type name.<br>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  In addition, the value "element" is the same as
/// "literal" formatting with an element at the top level.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// <var>summary</var>=true if summary type is to be created.
/// 
/// <var>input</var>=true means that the schema for the input XML will be generated, 
/// otherwise the schema for the output XML will be generated.  The default is 
/// <var>input</var>=false.  Normally, this argument is not relevant since the all properties
/// of a class participate in input and output.<br>
/// 
/// <var>refOnly</var>=true means that only the portions of the schema for
/// referenced types are generated.  The schema for this class is not generated.
/// Default is <var>refOnly</var>=false that generates the entire schema.<br>
Method AddSchemaType(class As %String, top As %String = "", format As %String, summary As %Boolean = 0, input As %Boolean = 0, refOnly As %Boolean = 0) As %Status [ ServerOnly = 1 ]
{
	If class="%Library.RegisteredObject" Quit $$$OK
	If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Quit $$$ERROR($$$XMLNotEnabled,class)
	}
	
	Set callerNamespace=$get(%namespace)

	New %class,%encoded,%soap12,%namespace,%refonly
	Set %class=class
	set %refonly=refOnly
	
	Set $ztrap="XMLSchemaTrap",sc=1
	Set fmt=$zcvt($get(format),"L")
	Set %encoded=$case($piece(fmt,",",1),"":0,"literal":0,"element":0,"literal-element":0,"encoded-element":1,"encoded":1,"encodedelement":1,"encoded12-element":1,"encoded12":1,"encoded12element":1,:"")
	If %encoded="" Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	Set %soap12=(fmt["12")
	Set element=(fmt["element")
	Try {
		If '$$$xmlsummary(class) Set summary=0
	} Catch {
		Set summary=0
	}
	Set classXmlnil=$$$defMemberKeyGet(class,$$$cCLASSparameter,"XMLNIL",$$$cPARAMdefault)
	Set ..suppressDocumentation=$$$defMemberKeyGet(class,$$$cCLASSparameter,"SUPPRESSDOCUMENTATION",$$$cPARAMdefault)
	If top="" {
		If element Set top = $$$defMemberKeyGet(class,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
		If top="" Set top = $$$defMemberKeyGet(class,$$$cCLASSparameter,"XMLTYPE",$$$cPARAMdefault)
		If top="" Set top = $$$ClassShortName(class)
		If summary Set top="s_"_top
	}
	Set namespace=""
	If input Set namespace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLIMPORTNAMESPACE",$$$cPARAMdefault)
	If namespace="" Set namespace=$zobjclassmethod(class,"XMLSchemaNamespace")
	If namespace=$c(0) Set namespace=callerNamespace
	If namespace="" Set namespace=..DefaultNamespace
	If 'refOnly {
		Set sc=..DefineNamespace(namespace,class)
		If $$$ISERR(sc) Quit sc
		If ..IsItemDefined(.namespace,element,top,class,input,summary,.sc) {
			Quit sc
		}
	} Else {
		Set sc=..DefineNamespace(.namespace,"")
		If $$$ISERR(sc) Quit sc
	}
	#; Create a node with which build the schema.
	Set node=..Document.GetDocumentElement()
	Set node.NodeId=..namespaceSchema(namespace)
	Set %namespace=namespace

	If $$$comMemberKeyGet(class,$$$cCLASSmethod,"XMLSchemaType",$$$cMETHrunnable) {
		If element && 'refOnly {
			Do node.AppendElement("element",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.SetAttribute("name",$$$XSDns,top)
			Do node.AppendElement("complexType",$$$XSDns)
			Do node.MoveToLastChild()
		}
		Quit $zobjclassmethod(class,"XMLSchemaType",$this,node,top,%encoded,summary,input,refOnly)
	}

	#; Get subclass lists.
	#; classdata(index,i)=$lb(elementName,type,summaryType,className)
	#;	index is index of the property
	#;	i is the derived class for the property
	#;	elementName is the name of the XML element to be used for the class
	#;	type is the XML type for the class
	#;	summaryType is the XML tpye for the class in summary mode
	#;	className is the derived class name.
	Set xmlbase=$$$xmlbase(class)
	Set xmlbasetype=$$$xmlbasetype(class)
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		If $$$xmlprojection(item)["xattribute" Continue
		If $$$xmlprojection(item)["xelement" Continue
		#; If an extension, skip properties from the base
		If (xmlbase'="") && $$$xmlinbase(item) && ('$$$xmlsummary(class) || '$$$xmlinsummary(item)) Continue

		Set type=$$$xmltype(item)
		Set xmlclasslist=$$$xmlclasslist(item)
		#; If choicelist specified, then copy it to runtime
		If xmlclasslist'="" {
			For i=1:1:$listlength(xmlclasslist) {
				Set derived=$piece($list(xmlclasslist,i),":",1)
				Set derivedtype=$piece($list(xmlclasslist,i),":",2)
				Set derivedname=$piece($list(xmlclasslist,i),":",3)
				If derivedtype["*+" {
					Set derivedtype=$tr(derivedtype,"*+","")
					Set classdata(index,i)=$listbuild(derivedname,derivedtype,$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)="":derivedtype,1:"s"_derivedtype),derived)
				} Else {
					Set classdata(index,i)=$listbuild(derivedname,derivedtype,derivedtype,derived)
				}
			}
		} Else {
			Kill xmldata Merge xmldata=^oddCOM(type,$$$cCLASSxmldata,"c"),xmldata=^oddXML(type,"c")
			Set type="",i=0
			For { 
        		Set type=$order(xmldata(type),1,list) Quit:type=""  
        		If $$$comClassDefined(type) {
					If $listget(list,3)="" Set $list(list,3)=$list(list,2)
        			Set i=i+1,classdata(index,i)=list_$listbuild(type)
        		}
        	}
		}
	}

	#; Check for presence of XMLPROJECTION=CONTENT			
	Set (attributes,elements,properties,content,xmlmixed,contentSummaryTest,contentSummaryTestIn,contentSummaryTestOut)=0
	Set (contenttypeIn,contenttypeOut)=""
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		Set xmlprojection=$$$xmlprojection(item)
		If xmlprojection["xattribute" Continue
		If xmlprojection["xelement" Continue
		#; If an extension, skip properties from the base
		If (xmlbase="") || '$$$xmlinbase(item) || ($$$xmlsummary(class) && $$$xmlinsummary(item)) {
			Set properties=properties+1
		}

		If xmlprojection["attribute" {
			Set attributes=1
		} ElseIf %encoded || (xmlprojection'["content") {
			Set elements=1
		}
	}
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		Set xmlprojection=$$$xmlprojection(item)
		If '%encoded && (xmlprojection["content") {
			If elements || (xmlbase'="") Set xmlmixed=1
			If elements || (xmlbase="") {
				Set content=1
				Set contentSummaryTest=($$$xmlsummary(class) && '$$$xmlinsummary(item))
				If $$$xmlio(item)'="OUT" {
					Set contentSummaryTestIn=($$$xmlsummary(class) && '$$$xmlinsummary(item))
					Set contenttypeIn=$$$xmlxsdtype(item)
					Set contentclassIn=$$$xmltype(item)
					Set contentPropertyIn=$$$xmlproperty(item)
				}
				If $$$xmlio(item)'="IN" {
					Set contentSummaryTestOut=($$$xmlsummary(class) && '$$$xmlinsummary(item))
					Set contenttypeOut=$$$xmlxsdtype(item)
					Set contentclassOut=$$$xmltype(item)
					Set contentPropertyOut=$$$xmlproperty(item)
				}
			}
		}
	}

	Set exportsOnly=0
	If refOnly {
		If 'element Set exportsOnly=1
		Goto SKIPCOMPLEXTYPE
	}

	If element {
		Do node.AppendElement("element",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("name",$$$XSDns,top)
		Do node.AppendElement("complexType",$$$XSDns)
		Do node.MoveToLastChild()
 	} Else {
		Do node.AppendElement("complexType",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("name",$$$XSDns,top)
		If ..ServiceName'="" {
			Do node.SetAttribute("classname",$$$ISCSOAPns,..ServiceName_":"_class)
		}
 	}
	If $$$comClassKeyGet(class,$$$cCLASSabstract) Do node.SetAttribute("abstract",$$$XSDns,"true")
	If xmlmixed && '%encoded Do node.SetAttribute("mixed",$$$XSDns,"true")
	If ..IncludeDocumentation && '..suppressDocumentation {
		Set classDescription=..FixDocumentation($$$defClassKeyGet(class,$$$cCLASSdescription))
		If classDescription'="" {
			Do node.AppendElement("annotation",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.AppendElement("documentation",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.AppendCharacter(classDescription,1)
			Do node.MoveToParent()				;  </s:documentation>
			Do node.MoveToParent()				;  </s:annotation>
		}
	}

	#; Output schema elements
	If xmlbase'="" {
		If '$$$xmlsummary(class) || 'summary {
			Do node.AppendElement("complexContent",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.AppendElement("extension",$$$XSDns)
			Do node.MoveToLastChild()
			If ..NoNamespace {
				Do node.SetAttribute("base",$$$XSDns,..NamespacePrefix_xmlbase)
			} Else {
				Set basenamespace=$select(xmlbasetype'="":$$$xmlnamespace(xmlbasetype),1:"")
				If basenamespace="" Set basenamespace=..DefaultNamespace
				Do node.SetAttribute("base",$$$XSDns,xmlbase,basenamespace)
				Do ..DefineImport(basenamespace)
			}
		}
	}
	If (properties>0) && (elements || (%encoded && ('contentSummaryTest || 'summary))) {
		Do node.AppendElement("sequence",$$$XSDns)
		Do node.MoveToLastChild()
	}
SKIPCOMPLEXTYPE 
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		#; If an extension, skip properties from the base
		If (xmlbase'="") && $$$xmlinbase(item) && ('$$$xmlsummary(class) || '$$$xmlinsummary(item)) Continue
		Set xmlprojection=$$$xmlprojection(item)
		If xmlprojection["xattribute" Continue
		If xmlprojection["xelement" Continue

		Set property=$$$xmlproperty(item)
		Set xmlname=$$$xmlname(item)
		Set xsdtype=$$$xmlxsdtype(item)
		Set type=$$$xmltype(item)
		Set membercat=$$$xmlmembercat(item)
		Set xmlclasslist=$$$xmlclasslist(item)
		If (membercat["OBJ") && $zobjclassmethod(type,"%IsA","%XML.DataSet") {
			Set xmlnamespace=..DefaultNamespace
		} Else {
			Set xmlnamespace=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If xmlnamespace="" Set xmlnamespace=..DefaultNamespace
		} 
		Set xmlelementref=$$$xmlelementref(item)
		Set elementref=('%encoded||%refonly)&&((xmlelementref'="")&&'$listget(xmlelementref,3))
		If elementref {
			Set refnamespace=$listget(xmlelementref,1)
			If refnamespace="" Set refnamespace=xmlnamespace,elementref=2
		} Else {
			Set refnamespace=namespace
		}
		If element && ((refnamespace=namespace) || ..NoNamespace) Set elementref=0
		Set valuelist=$select((membercat["Array")||(xmlprojection["wrapped"):"",1:$$$xmlvaluelist(item))
		Set facets=$select((membercat["Array")||(xmlprojection["wrapped"):"",1:$$$xmlfacets(item))
		Set xmlnil=$$$xmlnil(item)
		If xmlnil="" Set xmlnil=classXmlnil
		Set xmlio=$$$xmlio(item)
		#; Test of input arg.  
		#; Schema element for attribute only if encoded.
		If (xmlprojection["attribute") || (xmlprojection["content") {
			If $$$xmlsummary(class) && '$$$xmlinsummary(item) {
				Set guard='summary && %encoded
			} Else {
				Set guard=%encoded&&$select((xmlbase'="")&&$$$xmlinbase(item):summary,1:1)
			}
		} Else {
			If $$$xmlsummary(class) && '$$$xmlinsummary(item) {
				Set guard='summary
			} Else {
				Set guard=$select((xmlbase'="")&&$$$xmlinbase(item):summary,1:1)
			}
		}
		If xmlio="IN" {
			If 'input Set guard=0
		} ElseIf xmlio="OUT" {
			If input Set guard=0
		}
    
		#; Gen for list as XML array
		If membercat["Collection" {
			#; Remember that this array needs to be put in the schema
			Set export(index)=""
			If exportsOnly Continue

			Set arraytype=$$$xmlarraytype(item)
			#; The possibly repeated part of the name is separated by a ,
			If ..AllowRedundantArrayName {
				#; Keep repeated part
				Set arraytype=$tr(arraytype,",","")
			} Else {
				#; Drop repeated part
				Set arraytype=$piece(arraytype,",")
			}
			#; Gen arrays/lists inline if XMLPROJECTION="element"
			#;   i.e. support unwrapped arrays.
			If xmlprojection'["wrapped" {
				Set eguard=(guard && '%encoded)
				Set guard=(guard && %encoded)
				If refOnly {
					Set attrlist=""
				} ElseIf $$$xmlrequired(item) {
					Set attrlist=$lb($lb("maxOccurs","unbounded"))
				} Else {
					Set attrlist=$lb($lb("minOccurs",0),$lb("maxOccurs","unbounded"))
				}
				If eguard {
					Set sc=..SchemaElement(node,$select(membercat["Array":"",1:class),type,
								   property,xmlname,$$$xmlclassxmlname(item),
								   $select(membercat["Array":$$$xmlpairtype(item),1:xsdtype),
								   $$$xmlkeyname(item),
								   $select(xmlprojection["choice":index,1:""),
								   ((membercat'["Array")&&(xmlprojection["substitutiongroup")),
								   ((membercat["Array")||((membercat["OBJ")&&(xmlprojection'["id"))),
								   $$$xmlmixed(item),(xmlprojection["any"),
								   $select(xmlnil="":'$$$xmlrequired(item),1:''xmlnil),attrlist,
								   $$$xmlsummary(class),(xmlprojection["summary"),
								   $select(membercat["Array":"",1:valuelist),
								   $select(membercat["Array":"",1:facets),
								   $select(membercat["Array":refnamespace,1:xmlnamespace),
								   elementref,refnamespace,top,summary,
								   .classdata)
					If $$$ISERR(sc) Quit
				}
			}
			#; Wrap arrays/lists, if XMLPROJECTION="collection".
			If arraytype["*+" {
				Set typeCode=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(arraytype,"*+","s_"),1:$tr(arraytype,"*+",""))
			} Else {
				Set typeCode=arraytype
			}
			If guard {
				Set savenode=node.NodeId
				Set saveNamespace=%namespace
				Set sc=$$$OK
				Set attrs=$select('$$$xmlrequired(item)&&'refOnly:$lb($lb("minOccurs",0)),1:"")
				If '..RefElement(elementref,node,$get(refnamespace),xmlname,typeCode,attrs,.sc) {
					Do node.AppendElement("element",$$$XSDns)
					Do node.MoveToLastChild()
					Do node.SetAttribute("name",$$$XSDns,xmlname)
					If ..NoNamespace {
						Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_typeCode)
					} Else {
						Do node.SetAttribute("type",$$$XSDns,typeCode,$select(refnamespace="-":"",1:refnamespace))
						Do ..DefineImport(refnamespace)
					}
					Do ..PropertyAnnotation(node,property,xmlname)
					If 'elementref Do ..AddAttributes(node,attrs)
				}
				If $$$ISERR(sc) Quit
				Set node.NodeId=savenode
				Set %namespace=saveNamespace
			}

		#; Gen for literal, stream or object.
		} ElseIf membercat'="" {
			Set object=(($extract(membercat,1,3)="OBJ") && (xmlprojection'["id"))
			If xmlprojection["wrapped" {
				Set export(index)=""
				If exportsOnly Continue
				If xmlprojection["choice" {
					Set temptype=xmlname
				} Else {
					Set temptype=$select($length(xsdtype,":")=2:$piece(xsdtype,":",2),1:xsdtype)
					Set temptype=$select(xmlprojection["substitutiongroup":"_",1:"")_temptype
				}
				Set temptype="_"_temptype
				If guard {
					Set sc=..SchemaElement(node,class,
								   type,property,xmlname,$$$xmlclassxmlname(item),temptype,"","",
								   0,1,0,0,0,
								   $select(refOnly||$$$xmlrequired(item):"",1:$lb($lb("minOccurs",0))),
								   0,0,"","",xmlnamespace,elementref,refnamespace,top,
								   summary,.classdata)
					If $$$ISERR(sc) Quit
				}
			} Else {
				If object || ($extract(xsdtype,1,2)'="s:") Set export(index)=""
				If exportsOnly Continue
				If guard {
					Set sc=..SchemaElement(node,class,
								   type,property,xmlname,$$$xmlclassxmlname(item),xsdtype,"",
								   $select(xmlprojection["choice":index,1:""),
								   (xmlprojection["substitutiongroup"),
								   object,$$$xmlmixed(item),(xmlprojection["any"),''xmlnil,
								   $select(refOnly||$$$xmlrequired(item):"",1:$lb($lb("minOccurs",0))),
								   $$$xmlsummary(class),(xmlprojection["summary"),
								   valuelist,facets,xmlnamespace,elementref,refnamespace,top,
								   summary,.classdata)
					If $$$ISERR(sc) Quit
				}
			}
		}
	}
	If $$$ISERR(sc) Quit sc
	If refOnly Goto SKIPENDCOMPLEXTYPE
	If (properties>0) && (elements || (%encoded && ('contentSummaryTest || 'summary))) Do node.MoveToParent() ; sequence

	#; Gen schema attributes
	If (attributes || content) && '%encoded {
		If content && 'xmlmixed {
			If (contenttypeIn=contenttypeOut) && (contentSummaryTestIn=contentSummaryTestOut) {
				If 'contentSummaryTestIn || 'summary {
					Do node.AppendElement("simpleContent",$$$XSDns)
					Do node.MoveToLastChild()
					Do ..PropertyAnnotation(node,contentPropertyIn,"")
					Do node.AppendElement("extension",$$$XSDns)
					Do node.MoveToLastChild()
					If ..NoNamespace {
						Do node.SetAttribute("base",$$$XSDns,$select($extract(contenttypeOut,1,2)'="s:":..NamespacePrefix,1:"")_contenttypeOut)
					} Else {
						If $extract(contenttypeOut,1,2)="s:" {
							Do node.SetAttribute("base",$$$XSDns,$extract(contenttypeOut,3,*),$$$XSDns)
						} Else {
							Set ns=$$$comMemberKeyGet(contentclassOut,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
							If ns="" Set ns=..DefaultNamespace
							Do node.SetAttribute("base",$$$XSDns,contenttypeOut,ns)
							Do ..DefineImport(ns)
						}
					}
				}
			} Else {
				If contenttypeIn'="" {
					If input && ('contentSummaryTestIn || 'summary) {
						Do node.AppendElement("simpleContent",$$$XSDns)
						Do node.MoveToLastChild()
						Do ..PropertyAnnotation(node,contentPropertyIn,"")
						Do node.AppendElement("extension",$$$XSDns)
						Do node.MoveToLastChild()
						If ..NoNamespace {
							Do node.SetAttribute("base",$$$XSDns,$select($extract(contenttypeIn,1,2)'="s:":..NamespacePrefix,1:"")_contenttypeIn)
						} Else {
							If $extract(contenttypeOut,1,2)="s:" {
								Do node.SetAttribute("base",$$$XSDns,$extract(contenttypeIn,3,*),$$$XSDns)
							} Else {
								Set ns=$$$comMemberKeyGet(contentClassIn,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
								If ns="" Set ns=..DefaultNamespace
								Do node.SetAttribute("base",$$$XSDns,contenttypeIn,ns)
								Do ..DefineImport(ns)
							}
						}
					}
				}
				If contenttypeOut'="" {
					If 'input && ('contentSummaryTestOut || 'summary) {
						Do node.AppendElement("simpleContent",$$$XSDns)
						Do node.MoveToLastChild()
						Do ..PropertyAnnotation(node,contentPropertyOut,"")
						Do node.AppendElement("extension",$$$XSDns)
						Do node.MoveToLastChild()
						If ..NoNamespace {
							Do node.SetAttribute("base",$$$XSDns,$select($extract(contenttypeOut,1,2)'="s:":..NamespacePrefix,1:"")_contenttypeOut)
						} Else {
							If $extract(contenttypeOut,1,2)="s:" {
								Do node.SetAttribute("base",$$$XSDns,$extract(contenttypeOut,3,*),$$$XSDns)
							} Else {
								Set ns=$$$comMemberKeyGet(contentClassOut,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
								If ns="" Set ns=..DefaultNamespace
								Do node.SetAttribute("base",$$$XSDns,contenttypeOut,ns)
								Do ..DefineImport(ns)
							}
						}
					}
				}
			}
		}
		For index=1:1:$$$xmlpropertycount(class) {
			Set item=$$$xmlgetitem(class,index)
			#; If an extension, skip properties from the base
			If (xmlbase'="") && $$$xmlinbase(item) && ('$$$xmlsummary(class) || '$$$xmlinsummary(item)) Continue
			If $$$xmlprojection(item)["xattribute" Continue
			If $$$xmlprojection(item)["xelement" Continue

			#; Gen for not encoded case for attributes
			Set valuelist=$select($$$xmlprojection(item)["wrapped":"",1:$$$xmlvaluelist(item))
			Set facets=$select($$$xmlprojection(item)["wrapped":"",1:$$$xmlfacets(item))
			If $$$xmlprojection(item)["attribute" {
				Set type=$$$xmltype(item)
				Set xsdtype=$$$xmlxsdtype(item)
				Set xmlname=$$$xmlname(item)
				Set property=$$$xmlproperty(item)
				Set xmlelementref=$$$xmlelementref(item)
				Set elementref=((xmlelementref'="")&&'$listget(xmlelementref,3))
				If elementref {
					Set refnamespace=$listget(xmlelementref,1)
					If refnamespace="" Set refnamespace=namespace,elementref=2
				} Else {
					Set refnamespace=namespace
				}
				Set NotSummary=$$$xmlsummary(class) && '$$$xmlinsummary(item)
				If $case($$$xmlio(item),"IN":input,"OUT":'input,:1) &&
				   ( (NotSummary && 'summary) ||
				     ('NotSummary && $select((xmlbase'="")&&$$$xmlinbase(item):summary,1:1)) ) {
					Set savenode=node.NodeId
					Set saveNamespace=%namespace
					Set sc=$$$OK
					If 'elementref || '..RefAttribute(node,refnamespace,xmlname,$select($extract(xsdtype,1,2)="s:":xsdtype,1:type),.sc) {
						Do node.AppendElement("attribute",$$$XSDns)
						Do node.MoveToLastChild()
						If $$$xmlprojection(item)["xmlattribute" {
							Do node.SetAttribute("ref",$$$XSDns,"xml:"_xmlname)
						} Else {
							Do node.SetAttribute("name",$$$XSDns,xmlname)
							Do ..PropertyAnnotation(node,property,xmlname)
							If (valuelist="") && (facets="") {
								If $extract(xsdtype,1,2)="*+" {
									Set xdt=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$extract(xsdtype,3,*),1:xsdtype)
								} Else {
									Set xdt=xsdtype
								}
								If ..NoNamespace {
									Do node.SetAttribute("type",$$$XSDns,$select($extract(xsdtype,1,2)'="s:":..NamespacePrefix,1:"")_xdt)
								} Else {
									If $extract(xsdtype,1,2)="s:" {
										Do node.SetAttribute("type",$$$XSDns,$extract(xdt,3,*),$$$XSDns)
									} Else {
										Set ns=$$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
										If ns="" Set ns=..DefaultNamespace
										Do node.SetAttribute("type",$$$XSDns,xdt,$select(ns="-":"",1:ns))
										Do ..DefineImport(ns)
									}
								}
							}
						}
						If $$$xmlrequired(item) Do node.SetAttribute("use",$$$XSDns,"required")
						If (valuelist'="") || (facets'="") {
							Do ..SchemaSimpleType(node,"",$$$xmltype(item),xsdtype,valuelist,facets)
						}
						Do node.MoveToParent()		;  </s:attribute>
					}
					If $$$ISERR(sc) Quit
					Set node.NodeId=savenode
					Set %namespace=saveNamespace
				}
			}
		}
		If content && 'xmlmixed {
			If (contenttypeIn'="") && (contenttypeOut'="") && (contentSummaryTestIn=contentSummaryTestOut) {
				If 'contentSummaryTestIn || 'summary Do node.MoveToParent() Do node.MoveToParent()
			} Else {
				If contenttypeIn'="" {
					If input && ('contentSummaryTestIn || 'summary) Do node.MoveToParent() Do node.MoveToParent()
				}
				If contenttypeOut'="" {
					If 'input && ('contentSummaryTestOut || 'summary) Do node.MoveToParent() Do node.MoveToParent()
				}
			}
		}
	}

	If $$$xmlbase(class)'="" {
		If '$$$xmlsummary(class) || 'summary {
			Do node.MoveToParent()		;  </s:extension>
			Do node.MoveToParent()		;  </s:complexContent>
		}
	}
	Do node.MoveToParent()				;  </s:complexType>
	If element Do node.MoveToParent()	;  </s:element>

SKIPENDCOMPLEXTYPE  
	#; Generate schema for base class
	If xmlbase'="" {
		Set xmlbasetype=$$$xmlbasetype(class)
		If ('$$$xmlsummary(class) || 'summary) {
			Set sc=..AddSchemaType(xmlbasetype,"",fmt,summary,input,0)
			If $$$ISERR(sc) Quit sc
		}
	}

	#; Gen types for referenced objects and arrays
	Set sc=$$$OK
	Set index = $Order(export(""))
	If index'="" Set fmt=$select(%soap12:"encoded12",%encoded:"encoded",1:"literal")
	While index '= "" {
		Set item=$$$xmlgetitem(class,index)
		Set membercat=$$$xmlmembercat(item)
		Set arraytype=$$$xmlarraytype(item)
		#; The possibly repeated part of the name is separated by a ,
		If ..AllowRedundantArrayName {
			#; Keep repeated part
			Set arraytype=$tr(arraytype,",","")
		} Else {
			#; Drop repeated part
			Set arraytype=$piece(arraytype,",")
		}
		Set xsdtype=$$$xmlxsdtype(item)
		Set type=$$$xmltype(item)
		Set xmlprojection=$$$xmlprojection(item)
		Set NotSummary=$$$xmlsummary(class) && '$$$xmlinsummary(item)
		Set xmlio=$$$xmlio(item)
		Set summaryTest=$select(NotSummary:'summary,1:1) && $case(xmlio,"IN":input,"OUT":'input,:1)
		Set xmlnamespace=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
		If xmlnamespace="" Set xmlnamespace=..DefaultNamespace
		Set xmlelementref=$$$xmlelementref(item)
		Set elementref=('%encoded||%refonly)&&((xmlelementref'="")&&'$listget(xmlelementref,3))
		If elementref {
			Set refnamespace=$listget(xmlelementref,1)
			If refnamespace="" Set refnamespace=xmlnamespace,elementref=2
		} Else {
			Set refnamespace=namespace
		}
		If element && ((refnamespace=namespace) || ..NoNamespace) Set elementref=0
		Set savenode=node.NodeId
		Set saveNamespace=%namespace
		If elementref {
			Set sc=..DefineNamespace(.refnamespace,"")
			If $$$ISERR(sc) Quit
			Set node.NodeId=..namespaceSchema(refnamespace)
			Set %namespace=refnamespace
		}
		Set valuelist=$select(membercat["Array":"",1:$$$xmlvaluelist(item))
		Set facets=$select(membercat["Array":"",1:$$$xmlfacets(item))
		Set xmlnil=$$$xmlnil(item)
		If xmlnil="" Set xmlnil=classXmlnil
		Set object=(($extract(membercat,1,3)="OBJ") && (xmlprojection'["id"))
		#; Gen for Arrays and Lists objects
		If membercat["Collection" {
			Set xmlsummary=($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="")
			Set pairtype=$$$xmlpairtype(item)
			Set xmlclasslist=$$$xmlclasslist(item)
			#; Gen code to check for previous generated type
			If arraytype["*+" {
				Set typeCode=$select(xmlsummary:$tr(arraytype,"*+","s_"),1:$tr(arraytype,"*+",""))
			} Else {
				Set typeCode=arraytype
			}
			If summaryTest {
				If ..IsItemDefined(.refnamespace,0,typeCode,$select('object&&($extract(xsdtype,1,2)="s:"):xsdtype,1:type),0,0,.sc) {
					If $$$ISERR(sc) Quit
				} Else {
					#; Generate encoded case for ArrayOf...
					If %encoded {
						Do node.AppendElement("complexType",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("name",$$$XSDns,typeCode)
						Do node.AppendElement("complexContent",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("mixed",$$$XSDns,"false")
						Do node.AppendElement("restriction",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("base",$$$XSDns,"Array",$select(%soap12:$$$SOAP12ENCns,1:$$$SOAPENCns))
						Do node.AppendElement("attribute",$$$XSDns)
						Do node.MoveToLastChild()
						Set namespacePrefix=..NamespacePrefix
						Set line=""
						If membercat["Array" {
							If pairtype["*+" {
								Set line=line_$select(xmlsummary:$tr(pairtype,"*+","s_"),1:$tr(pairtype,"*+",""))
							} Else {
								Set line=line_pairtype
							}
							Set ns=refnamespace
						} Else {
							If xsdtype["*+" {
								Set line=line_$select(xmlsummary:$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
							} Else {
								Set line=line_xsdtype
							}
							Set ns=xmlnamespace
							If $extract(xsdtype,1,2)="s:" Set namespacePrefix=""
						}
						Set line=line_"[]"
						If ..NoNamespace {
							Do node.SetAttribute("arrayType",$$$WSDLns,namespacePrefix_line)
						} Else {
							If $extract(line,1,2)="s:" Set $extract(line,1,2)=""
							Do node.SetAttribute("arrayType",$$$WSDLns,line,$select((membercat'["Array")&&($extract(xsdtype,1,2)="s:"):$$$XSDns,1:ns))
						}
						Do node.SetAttribute("ref",$$$XSDns,"arrayType",$select(%soap12:$$$SOAP12ENCns,1:$$$SOAPENCns))
						Do node.MoveToParent()		; attribute
						Do node.MoveToParent()		; restriction
						Do node.MoveToParent()		; complexContent
						Do node.MoveToParent()		; complexType
		
						#; Generate literal case for ArrayOf...
					} ElseIf xmlprojection'["any" {
						Do node.AppendElement("complexType",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("name",$$$XSDns,typeCode)
						Do node.AppendElement("sequence",$$$XSDns)
						Do node.MoveToLastChild()
						Set attrlist=$lb($lb("minOccurs",0),$lb("maxOccurs","unbounded"))
						Set sc=..SchemaElement(node,$select(membercat["Array":"",1:class),type,
										   "",$$$xmlitemname(item),$$$xmlclassxmlname(item),
										   $select(membercat["Array":pairtype,1:xsdtype),
										   $$$xmlkeyname(item),
										   $select(xmlprojection["choice":index,1:""),
										   ((membercat'["Array")&&(xmlprojection["substitutiongroup")),
										   ((membercat["Array")||((membercat["OBJ")&&(xmlprojection'["id"))),
										   $$$xmlmixed(item),(xmlprojection["any"),
										   $select(xmlnil="":1,1:''xmlnil),attrlist,
										   $$$xmlsummary(class),(xmlprojection["summary"),
										   $select(membercat["Array":"",1:valuelist),
										   $select(membercat["Array":"",1:facets),
										   $select(membercat["Array":refnamespace,1:xmlnamespace),0,,
										   top,summary,.classdata)
						If $$$ISERR(sc) Quit
						Do node.MoveToParent()		; sequence
						Do node.MoveToParent()		; complexType
					}
				}
			}

			#; Generate Pair type for a Cache array
			If membercat["Array" {
				If xmlprojection["choice" {
					If %encoded {
						Set sc=..SchemaPair(node,type,xsdtype,pairtype,"",(xmlprojection["summary"),($$$xmlmembercat(item)["OBJ"),
										$$$xmlkeyname(item),NotSummary,summaryTest,
										xmlsummary,$$$xmlmembercat(item),refnamespace,"")
						If $$$ISERR(sc) Quit
					} Else {
						Set i=$order(classdata(index,""))
						While i'="" {
							Set pairtype="PairOf"_$$$xmlkeyname(item)
							Set classarray=classdata(index,i)
							Set derived=$list(classarray,4)
							Set sc=..SchemaPair(node,derived,"",pairtype,index,(xmlprojection["summary"),
											1,$$$xmlkeyname(item),NotSummary,summaryTest,
											xmlsummary,$$$xmlmembercat(item),refnamespace,classarray)
							If $$$ISERR(sc) Quit
							Set i=$order(classdata(index,i))
						}
						If $$$ISERR(sc) Quit
					}
				} Else {
					Set sc=..SchemaPair(node,type,xsdtype,pairtype,"",(xmlprojection["summary"),($$$xmlmembercat(item)["OBJ"),
									$$$xmlkeyname(item),NotSummary,summaryTest,
									xmlsummary,$$$xmlmembercat(item),refnamespace,"")
					If $$$ISERR(sc) Quit
				}
			}
		} ElseIf xmlprojection["wrapped" {
			If xmlprojection["choice" {
				Set temptype="_"_$$$xmlname(item)
			} Else {
				Set temptype=$select($length(xsdtype,":")=2:$piece(xsdtype,":",2),1:xsdtype)
				Set temptype=$select(xmlprojection["substitutiongroup":"_",1:"")_"_"_temptype
			}
			Set xmlsummary=($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="")
			If temptype["*+" {
				Set typeCode=$select(xmlsummary:$tr(temptype,"*+","s_"),1:$tr(temptype,"*+",""))
			} Else {
				Set typeCode=temptype
			}
			If summaryTest {
				If ..IsItemDefined(.namespace,0,typeCode,$select('object&&($extract(xsdtype,1,2)="s:"):xsdtype,1:type),0,0,.sc) {
					If $$$ISERR(sc) Quit
				} Else {
					#; Generate type for wrapped element
					Do node.AppendElement("complexType",$$$XSDns)
					Do node.MoveToLastChild()
					Do node.SetAttribute("name",$$$XSDns,typeCode)
					Do node.AppendElement("sequence",$$$XSDns)
					Do node.MoveToLastChild()
					Set typetag=xsdtype
					If $extract(typetag,1,2)="*+" Set $extract(typetag,1,2)=""
					If object && (typetag'=$$$xmlclassxmlname(item)) && %encoded {
						Set sc=..SchemaElement(node,class,
										   type,"",typetag,$$$xmlclassxmlname(item),xsdtype,"",
										   $select(xmlprojection["choice":index,1:""),
										   (xmlprojection["substitutiongroup"),
										   object,$$$xmlmixed(item),0,''xmlnil,"",
										   $$$xmlsummary(class),(xmlprojection["summary"),
										   valuelist,facets,xmlnamespace,0,,top,
										   summary,.classdata)
						If $$$ISERR(sc) Quit
					} Else {
						Set sc=..SchemaElement(node,class,
										   type,"",$$$xmlclassxmlname(item),$$$xmlclassxmlname(item),xsdtype,"",
										   $select(xmlprojection["choice":index,1:""),
										   (xmlprojection["substitutiongroup"),
										   object,$$$xmlmixed(item),0,''xmlnil,"",
										   $$$xmlsummary(class),(xmlprojection["summary"),
										   valuelist,facets,xmlnamespace,0,,top,
										   summary,.classdata)
						If $$$ISERR(sc) Quit
					}
	
					Do node.MoveToParent()		; sequence
					Do node.MoveToParent()		; complexType
				}
			}
		}
		Set node.NodeId=savenode
		Set %namespace=saveNamespace

		#; Call AddSchemaType at runtime for referenced objects
		If (membercat["OBJ") && (xmlprojection'["id") {
			If xmlprojection["substitutiongroup" {
				If xsdtype["*+" {
					Set typeCode=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
				} Else {
					Set typeCode=xsdtype
				}
				If summaryTest && '%encoded {
					If ..IsItemDefined(.xmlnamespace,1,typeCode,type,0,0,.sc) {
						If $$$ISERR(sc) Quit
					} Else {
						Do node.AppendElement("element",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("name",$$$XSDns,$$$xmlclassxmlname(item))
						If ..NoNamespace {
							Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_typeCode)
						} Else {
							Do node.SetAttribute("type",$$$XSDns,typeCode,$select(xmlnamespace="-":"",1:xmlnamespace))
							Do ..DefineImport(xmlnamespace)
						}
						If $$$comClassKeyGet(type,$$$cCLASSabstract) Do node.SetAttribute("abstract",$$$XSDns,"true")
						Do node.MoveToParent()
					}
				}
				Set i=$order(classdata(index,""))
				While i'="" {
					Set classarray=classdata(index,i)
					Set derived=$list(classarray,4)
					Set ns=$$$comMemberKeyGet(derived,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
					If ns="" Set ns=..DefaultNamespace
					If summaryTest && ($list(classarray,1)'=$$$xmlclassxmlname(item)) {
						If '%encoded {
							If ..IsItemDefined(.ns,1,$list(classarray,1),derived,0,0,.sc) {
								If $$$ISERR(sc) Quit
							} Else {
								If ns="-" Set ns=""
								Do node.AppendElement("element",$$$XSDns)
								Do node.MoveToLastChild()
								Do node.SetAttribute("name",$$$XSDns,$list(classarray,1))
								If ..NoNamespace {
									Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_$list(classarray,$select(xmlprojection["summary":3,1:2)))
								} Else {
									Do node.SetAttribute("type",$$$XSDns,$list(classarray,$select(xmlprojection["summary":3,1:2)),ns)
									Do ..DefineImport(ns)
								}
								If ..NoNamespace {
									Do node.SetAttribute("substitutionGroup",$$$XSDns,..NamespacePrefix_$$$xmlclassxmlname(item))
								} Else {
									Do node.SetAttribute("substitutionGroup",$$$XSDns,$$$xmlclassxmlname(item),ns)
								}
								Do node.MoveToParent()
							}
						}
						Set sc=..AddSchemaType(derived,"",fmt,(xmlprojection["summary"),input,0)
						If $$$ISERR(sc)  Quit
					}
					Set i=$order(classdata(index,i))
				} 
				If $$$ISERR(sc) Quit
			} ElseIf xmlprojection["choice" {
				Set i=$order(classdata(index,""))
				While i'="" {
					Set derived=$list(classdata(index,i),4)
					If summaryTest {
						Set sc=..AddSchemaType(derived,"",fmt,(xmlprojection["summary"),input,0)
						If $$$ISERR(sc) Quit
					}
					Set i=$order(classdata(index,i))
				}
				If $$$ISERR(sc) Quit
			} Else {
				If xmlprojection'["summary" || 
				   ($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)="") {
					Set i=$order(classdata(index,""))
					While i'="" {
						Set derived=$list(classdata(index,i),4)
						If summaryTest {
							Set sc=..AddSchemaType(derived,"",fmt,(xmlprojection["summary"),input,0)
							If $$$ISERR(sc) Quit
						}
						Set i=$order(classdata(index,i))
					}
					If $$$ISERR(sc) Quit
				}
			}
			If summaryTest {
				Set sc=..AddSchemaType(type,"",fmt,(xmlprojection["summary"),input,0)
				If $$$ISERR(sc) Quit
			}
		} ElseIf (membercat["LITERAL") && ($extract(xsdtype,1,2)'="s:") && summaryTest {
			Set ns=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If ns="" Set ns=..DefaultNamespace
			If ..IsItemDefined(.ns,0,xsdtype,type,0,0,.sc) {
				If $$$ISERR(sc) Quit
			} Else {
				Set basetype=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XSDTYPE",$$$cPARAMdefault)
				If basetype="" Set basetype="string"
				Set basetype = "s:"_basetype
				Set xmllist=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLLISTPARAMETER",$$$cPARAMdefault)
				If xmllist="" Set xmllist="VALUELIST"
				Set basevalues=$$$comMemberKeyGet(type,$$$cCLASSparameter,xmllist,$$$cPARAMdefault)
				Set basevaluelist=""
				If basevalues'="" {
					Set sep=$extract(basevalues)
					For i=2:1:$length(basevalues,sep) {
						Set basevaluelist=basevaluelist_$lb($piece(basevalues,sep,i))
					}
				}
	            Set basepattern=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLPATTERN",$$$cPARAMdefault)
	            Set basemaxlen=$$$comMemberKeyGet(type,$$$cCLASSparameter,"MAXLEN",$$$cPARAMdefault)
	            Set baseminlen=$$$comMemberKeyGet(type,$$$cCLASSparameter,"MINLEN",$$$cPARAMdefault)
	            If $case($$$comClassKeyGet(type,$$$cCLASSclientdatatype),"DATE":1,"TIME":1,"TIMESTAMP":1,:0) {
	            	Set basemaxval=""
	            	Set baseminval=""
	            	Set basetotaldigits=""
	            	Set basefractiondigits=""
	            } Else {
	            	Set basemaxval=$$$comMemberKeyGet(type,$$$cCLASSparameter,"MAXVAL",$$$cPARAMdefault)
	            	Set baseminval=$$$comMemberKeyGet(type,$$$cCLASSparameter,"MINVAL",$$$cPARAMdefault)
		            Set basetotaldigits=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLTotalDigits",$$$cPARAMdefault)
		            If $$$comClassKeyGet(type,$$$cCLASSclientdatatype)="NUMERIC" {
			            Set basefractiondigits=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLFractionDigits",$$$cPARAMdefault)
		            } Else {
		            	Set basefractiondigits=""
		            }
	            }
	            If (basepattern'="") || (basemaxlen'="") || (baseminlen'="") || 
	               (basemaxval'="") || (baseminval'="") ||
	               (basefractiondigits'="") || (basetotaldigits'="") {
		            Set basefacets=$lb(basepattern,basemaxlen,baseminlen,basemaxval,baseminval,basefractiondigits,basetotaldigits)
	            } Else {
					Set basefacets=""
	            }
				Set savenode=node.NodeId
				Set saveNamespace=%namespace
				Set node.NodeId=..namespaceSchema(ns)
				Set %namespace=ns
				Do ..SchemaSimpleType(node,xsdtype,type,basetype,basevaluelist,basefacets)
				Set node.NodeId=savenode
				Set %namespace=saveNamespace
			}
		}

		Set index = $Order(export(index))
	}

	Quit sc

XMLSchemaTrap Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Define a pair type to be used for ObjectScript arrays
Method SchemaPair(node, type, xsdtype, pairtype, choiceitem, bsummary, object, xmlkeyname, NotSummary, summaryTest, xmlsummary, membercat, namespace, classarray) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If choiceitem="" {
		If pairtype["*+" {
			Set typeCode=$select(xmlsummary:$tr(pairtype,"*+","s_"),1:$tr(pairtype,"*+",""))
		} Else {
			Set typeCode=pairtype
		}
	} Else {
		Set typeCode=pairtype_$list(classarray,$select(bsummary:3,1:2))
	}
	If 'summaryTest Quit $$$OK
	
	If ..IsItemDefined(.namespace,0,typeCode,$select('object&&($extract(xsdtype,1,2)="s:"):xsdtype,1:type),0,0,.sc) {
		Quit sc
	}

	Set savenode=node.NodeId
	Set saveNamespace=%namespace
	Set node.NodeId=..namespaceSchema(namespace)
	Set %namespace=namespace

	Do node.AppendElement("complexType",$$$XSDns)
	Do node.MoveToLastChild()
	Do node.SetAttribute("name",$$$XSDns,typeCode)
	If %encoded {
		Do node.AppendElement("sequence",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.AppendElement("element",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("name",$$$XSDns,xmlkeyname)
		If ..NoNamespace {
			Do node.SetAttribute("type",$$$XSDns,"s:string")
		} Else {
			Do node.SetAttribute("type",$$$XSDns,"string",$$$XSDns)
		}
		Do node.SetAttribute("minOccurs",$$$XSDns,1)
		Do node.MoveToParent()		; element
		Do node.AppendElement("element",$$$XSDns)
		Do node.MoveToLastChild()
		If choiceitem'="" {
			Set line=$list(classarray,$select(bsummary:3,1:2))
			Do node.SetAttribute("name",$$$XSDns,$list(classarray,2))
			If ..NoNamespace {
				Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_line)
			} Else {
				Set xmlnamespace=$$$comMemberKeyGet($list(classarray,4),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
				If xmlnamespace="" Set xmlnamespace=..DefaultNamespace
				Do node.SetAttribute("type",$$$XSDns,line,$select(xmlnamespace="-":"",1:xmlnamespace))
				Do ..DefineImport(xmlnamespace)
			}
		} ElseIf object && ($extract(xsdtype,1,2)'="s:") {
			Set elname=xsdtype
			If $extract(elname,1,2)="*+" Set $extract(elname,1,2)=""
			Do node.SetAttribute("name",$$$XSDns,elname)
			If $extract(xsdtype,1,2)="*+" {
				Set line=$select(xmlsummary:$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
			} Else {
				Set line=xsdtype
			}
			If ..NoNamespace {
				Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_line)
			} Else {
				Set xmlnamespace=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
				If xmlnamespace="" Set xmlnamespace=..DefaultNamespace
				Do node.SetAttribute("type",$$$XSDns,line,$select(xmlnamespace="-":"",1:xmlnamespace))
				Do ..DefineImport(xmlnamespace)
			}
		} Else {
			If $extract(xsdtype,1,2)="s:" {
				Do node.SetAttribute("name",$$$XSDns,$piece(xsdtype,":",2))
				If ..NoNamespace {
					Do node.SetAttribute("type",$$$XSDns,xsdtype)
				} Else {
					Do node.SetAttribute("type",$$$XSDns,$piece(xsdtype,":",2),$$$XSDns)
				}
			} Else {
				Do node.SetAttribute("name",$$$XSDns,xsdtype)
				If ..NoNamespace {
					Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_xsdtype)
				} Else {
					Set xmlnamespace=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
					If xmlnamespace="" Set xmlnamespace=..DefaultNamespace
					Do node.SetAttribute("type",$$$XSDns,xsdtype,$select(xmlnamespace="-":"",1:xmlnamespace))
					Do ..DefineImport(xmlnamespace)
				}
			}
		}
		Do node.SetAttribute("minOccurs",$$$XSDns,0)
		Do node.MoveToParent()		; element
		Do node.MoveToParent()		; sequence
	} Else {
		Do node.AppendElement($select(membercat["OBJ":"complexContent",1:"simpleContent"),$$$XSDns)
		Do node.MoveToLastChild()
		Do node.AppendElement("extension",$$$XSDns)
		Do node.MoveToLastChild()
		If choiceitem'="" {
			Set line=$list(classarray,$select(bsummary:3,1:2))
			Set ns=$$$comMemberKeyGet($list(classarray,4),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If ns="" Set ns=..DefaultNamespace
		} Else {
			If $extract(xsdtype,1,2)="*+" {
				Set line=$select(xmlsummary:$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
			} Else {
				Set line=xsdtype
			}
			Set ns=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If ns="" Set ns=..DefaultNamespace
		}
		If $extract(line,1,2)="s:" {
			If ..NoNamespace {
				Do node.SetAttribute("base",$$$XSDns,line)
			} Else {
				Do node.SetAttribute("base",$$$XSDns,$piece(line,":",2),$$$XSDns)
			}
		} Else {
			If ..NoNamespace {
				Do node.SetAttribute("base",$$$XSDns,..NamespacePrefix_line)
			} Else {
				Do node.SetAttribute("base",$$$XSDns,line,ns)
				Do ..DefineImport(ns)
			}
		}
		Do node.AppendElement("attribute",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("name",$$$XSDns,xmlkeyname)
		If ..NoNamespace {
			Do node.SetAttribute("type",$$$XSDns,"s:string")
		} Else {
			Do node.SetAttribute("type",$$$XSDns,"string",$$$XSDns)
		}
		Do node.SetAttribute("use",$$$XSDns,"required")
		Do node.MoveToParent()		; attribute
		Do node.MoveToParent()		; extension
		Do node.MoveToParent()		; complexContent or simpleContent
	}

	Do node.MoveToParent()		; complexType

	Set node.NodeId=savenode
	Set %namespace=saveNamespace
	Quit $$$OK
}

/// Define a simpleType
Method SchemaSimpleType(node, name, type, xsdtype, valuelist, facets) [ Internal, Private, ServerOnly = 1 ]
{
	Do node.AppendElement("simpleType",$$$XSDns)
	Do node.MoveToLastChild()
	If name'="" Do node.SetAttribute("name",$$$XSDns,name)
	Set namespacePrefix=..NamespacePrefix
	If $extract(xsdtype,1,2)="s:" Set namespacePrefix="s:",$extract(xsdtype,1,2)=""
	Do node.AppendElement("restriction",$$$XSDns)
	Do node.MoveToLastChild()
	If xsdtype["*+" {
		Set xsdtype=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))_""""
	}
	If ..NoNamespace {
		Do node.SetAttribute("base",$$$XSDns,namespacePrefix_xsdtype)
	} Else {
		If namespacePrefix="s:" {
			Do node.SetAttribute("base",$$$XSDns,xsdtype,$$$XSDns)
		} Else {
			Set namespace=$$$comMemberKeyGet(type,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If namespace="" Set namespace=..DefaultNamespace
			Do node.SetAttribute("base",$$$XSDns,xsdtype,namespace)
			Do ..DefineImport(namespace)
		}
	}
	If facets'="" {
		Set facetNames=$lb("pattern","maxLength","minLength","maxInclusive","minInclusive","fractionDigits","totalDigits")
		For i=1:1:$listlength(facetNames) {
			Set facetValue=$listget(facets,i)
		 	If facetValue'="" {
				Do node.AppendElement($list(facetNames,i),$$$XSDns)
				Do node.MoveToLastChild()
				Do node.SetAttribute("value",$$$XSDns,facetValue)
				Do node.MoveToParent()
		 	}
		}
	}
	If valuelist'="" {
		For i=1:1:$listlength(valuelist) {
			Do node.AppendElement("enumeration",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.SetAttribute("value",$$$XSDns,$list(valuelist,i))
			Do node.MoveToParent()
		}
	}
	Do node.MoveToParent()
	Do node.MoveToParent()
}

/// Define a property element
Method SchemaElement(node, class, type, property, xmlname, classxmlname, xsdtype, xmlkeyname, choiceitem, substitutiongroup, object, mixed, any, nillable, attributes, xmlsummary, bsummary, valuelist, facets, namespace, elementref, refnamespace, top, summary, ByRef classdata) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Set sc=$$$OK
	Set savenode=node.NodeId
	Set saveNamespace=%namespace

	If any Set mixed=0

	If (any || mixed || (valuelist'="") || (facets'="") || (choiceitem'="") || substitutiongroup) && '%encoded {

		#; Note that only one of choice, substitutiongroup, valuelist and mixed may be true, since
		#; choice and substitutiongroup are disjoint and  only true for object references and 
		#; mixed and valuelist are only true for literals.
		If choiceitem'="" {
			Do node.AppendElement("choice",$$$XSDns)
			Do node.MoveToLastChild()
			Do ..PropertyAnnotation(node,property,property)
			Set choicenode=node.NodeId
			Set choiceNamespace=%namespace
			Set type=$order(classdata(choiceitem,""))
			While type'="" {
				Set typename=$select(xmlkeyname'="":"PairOf"_xmlkeyname,1:"")_$list(classdata(choiceitem,type),$select(bsummary:3,1:2))
				If elementref=2 {
					Set ns=$$$comMemberKeyGet($list(classdata(choiceitem,type),4),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
					If ns="" Set ns=..DefaultNamespace
				} ElseIf elementref {
					Set ns=refnamespace
				}
				If '..RefElement(elementref,node,$get(ns),$list(classdata(choiceitem,type),1),$list(classdata(choiceitem,type),4),"",.sc) {
					Do node.AppendElement("element",$$$XSDns)
					Do node.MoveToLastChild()
					Do node.SetAttribute("name",$$$XSDns,$list(classdata(choiceitem,type),1))
					If ..NoNamespace {
						Do node.SetAttribute("type",$$$XSDns,..NamespacePrefix_typename)
					} Else {
						If xmlkeyname'="" {
							Set ns=namespace
						} Else {
							Set ns=$$$comMemberKeyGet($list(classdata(choiceitem,type),4),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
							If ns="" Set ns=..DefaultNamespace
						}
						Do node.SetAttribute("type",$$$XSDns,typename,$select(ns="-":"",1:ns))
						Do ..DefineImport(ns)
					}
				}
				Set node.NodeId=choicenode
				Set %namespace=choiceNamespace
				If $$$ISERR(sc) Quit
				Set type=$order(classdata(choiceitem,type))
			}
			Do ..AddAttributes(node,attributes)
			Do node.MoveToParent()
		} ElseIf substitutiongroup {
			Do node.AppendElement("element",$$$XSDns)
			Do node.MoveToLastChild()
			Do ..PropertyAnnotation(node,property,property)
			If ..NoNamespace {
				Do node.SetAttribute("ref",$$$XSDns,..NamespacePrefix_classxmlname)
			} Else {
				Do node.SetAttribute("ref",$$$XSDns,classxmlname,namespace)
				Do ..DefineImport(namespace)
			}
			Do ..AddAttributes(node,attributes)
			Do node.MoveToParent()
		} ElseIf any {
			Do node.AppendElement("any",$$$XSDns)
			Do node.MoveToLastChild()
			Do ..PropertyAnnotation(node,property,property)
			Do ..AddAttributes(node,attributes)
			Do node.MoveToParent()
		} ElseIf mixed {
			If '..RefElement(elementref,node,$get(refnamespace),xmlname,"","",.sc) {
				Do node.AppendElement("element",$$$XSDns)
				Do node.MoveToLastChild()
				Do node.SetAttribute("name",$$$XSDns,xmlname)
				Do ..PropertyAnnotation(node,property,xmlname)
					Do node.AppendElement("complexType",$$$XSDns)
					Do node.MoveToLastChild()
					Do node.SetAttribute("mixed",$$$XSDns,"true")
						Do node.AppendElement("choice",$$$XSDns)
						Do node.MoveToLastChild()
						Do node.SetAttribute("minOccurs",$$$XSDns,0)
						Do node.SetAttribute("maxOccurs",$$$XSDns,"unbounded")
							Do node.AppendElement("any",$$$XSDns)
							Do node.MoveToLastChild()
							Do node.SetAttribute("processContents",$$$XSDns,"lax")
							Do node.MoveToParent()
						Do node.MoveToParent()
					Do node.MoveToParent()
				Do node.MoveToParent()
			}
		} ElseIf (valuelist'="") || (facets'="") {
			If '..RefElement(elementref,node,$get(refnamespace),xmlname,$select($extract(xsdtype,1,2)="s:":xsdtype,1:type),attributes,.sc) {
				Do node.AppendElement("element",$$$XSDns)
				Do node.MoveToLastChild()
				Do node.SetAttribute("name",$$$XSDns,xmlname)
				Do ..PropertyAnnotation(node,property,xmlname)
				If nillable Do node.SetAttribute("nillable",$$$XSDns,"true")
				If 'elementref Do ..AddAttributes(node,attributes)
				Do ..SchemaSimpleType(node,"",type,xsdtype,valuelist,facets)
				Do node.MoveToParent()
			}
		}
	} Else {
		Set namespacePrefix=..NamespacePrefix
		If object {
			#; Remember that this object needs to be put in the schema
			If xmlsummary && (type=class) {
				Set stype=$select($extract(xsdtype,1,2)="*+":$extract(xsdtype,3,*),1:xsdtype)
				Set xsdtype=$select(bsummary=summary:top,1:$select(bsummary:"s_",1:"")_stype)
			} ElseIf type=class {
				Set xsdtype=top
			} Else {
				If xsdtype["*+" {
					Set xsdtype=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
				}
			}
		} Else {
			If $extract(xsdtype,1,2)="s:" Set namespacePrefix="s:",$extract(xsdtype,1,2)=""
			If xsdtype["*+" {
				Set xsdtype=$select($$$comMemberKeyGet(type,$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
			}
		}
		If '..RefElement(elementref,node,$get(refnamespace),xmlname,$select($extract(xsdtype,1,2)="s:":xsdtype,1:type),attributes,.sc) {
			Do node.AppendElement("element",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.SetAttribute("name",$$$XSDns,xmlname)
			Do ..PropertyAnnotation(node,property,xmlname)
			If ..NoNamespace {
				Do node.SetAttribute("type",$$$XSDns,namespacePrefix_xsdtype)
			} Else {
				If namespacePrefix="s:" {
					Do node.SetAttribute("type",$$$XSDns,xsdtype,$$$XSDns)
				} Else {
					Do node.SetAttribute("type",$$$XSDns,xsdtype,$select(namespace="-":"",1:namespace))
					Do ..DefineImport(namespace)
				}
			}
			If nillable Do node.SetAttribute("nillable",$$$XSDns,"true")
			If 'elementref Do ..AddAttributes(node,attributes)
			Do node.MoveToParent()
		}
	}
	Set node.NodeId=savenode
	Set %namespace=saveNamespace
	Quit sc
}

/// Introduce indirection of element to different namespace via ref attribute
Method RefElement(elementref As %Boolean, node As %XML.Node, refnamespace As %String, refname As %String, class As %String, attributes, ByRef status As %Status) As %Boolean [ Internal, Private, ServerOnly = 1 ]
{
	If 'elementref {
		Quit (%refonly && ..IsItemDefined(%namespace,1,refname,class,0,0,.status))
	}
	
	if '%refonly {
		Do node.AppendElement("element",$$$XSDns)
		Do node.MoveToLastChild()
		If ..NoNamespace {
			Do node.SetAttribute("ref",$$$XSDns,..NamespacePrefix_refname)
		} Else {
			Do node.SetAttribute("ref",$$$XSDns,refname,refnamespace)
			Do ..DefineImport(refnamespace)
		}
		Do ..AddAttributes(node,attributes)
		Do node.MoveToParent()
	}

	Set defined=..IsItemDefined(.refnamespace,1,refname,class,0,0,.status)
	
	If 'defined {
		Set node.NodeId=..namespaceSchema(refnamespace)
		Set %namespace=refnamespace
	}
	
	Quit defined
}

/// Introduce indirection of attribute to different namespace via ref attribute
Method RefAttribute(node As %XML.Node, refnamespace As %String, refname As %String, class As %String, ByRef status As %Status) As %Boolean [ Internal, Private, ServerOnly = 1 ]
{
	Do node.AppendElement("attribute",$$$XSDns)
	Do node.MoveToLastChild()
	If ..NoNamespace {
		Do node.SetAttribute("ref",$$$XSDns,..NamespacePrefix_refname)
	} Else {
		Do node.SetAttribute("ref",$$$XSDns,refname,refnamespace)
		Do ..DefineImport(refnamespace)
	}
	Do node.MoveToParent()

	Set defined=..IsItemDefined(.refnamespace,2,refname,class,0,0,.status)
	
	If 'defined {
		Set node.NodeId=..namespaceSchema(refnamespace)
		Set %namespace=refnamespace
	}
	
	Quit defined
}

/// Add attributes expressed as list of 2 member lists: name and value
Method AddAttributes(node As %XML.Node, attributes) [ Internal, Private, ServerOnly = 1 ]
{
	For i=1:1:$listlength(attributes)  {
		Set nv=$list(attributes,i)
		Do node.SetAttribute($list(nv,1),$$$XSDns,$list(nv,2))
	}
}

/// Return true if an element or complexType is already defined matching the arguments.
/// If a match is found, then status indicates if a duplicate definition
/// error is detected.
/// kind is 0 for complexType, 1 for element, 2 for attribute
Method IsItemDefined(ByRef namespace As %String, kind As %Integer, name As %String, class As %String, input As %Boolean, summary As %Boolean, ByRef status As %Status) As %Boolean [ Internal, Private, ServerOnly = 1 ]
{
	If ..NoNamespace Set namespace="-"

	Set status=..DefineNamespace(.namespace,"")
	If $$$ISERR(status) Quit 1
	
	Set nsIndex=..namespaceIndices(namespace)
	Set item=$get(^||%xmlName(..schema,nsIndex,kind,name))
	If item'="" {
		If (class'="") && ($extract(class,1,2)'="s:") && 
		   (($get($$$xmlpropertycount(class),0)=0) || $$$xmlinout(class)) {
			Set input=$list(item,3)
		}
		If (kind'=0) && (class="") Set class=$list(item,1)
		If (class'=$list(item,1)) || (%encoded'=$list(item,2)) || (summary'=$list(item,4)) {
			Set status=$$$ERROR($$$XMLSchemaDuplicate,$select(kind=1:"element",kind=2:"attribute",1:"complexType"),name,class)
		}
		Quit 1
	} Else {
		Set ^||%xmlName(..schema,nsIndex,kind,name)=$lb(class,%encoded,input,summary)
		Quit 0
	}
}

/// Define an XML namespace, if it is not already defined.
Method DefineNamespace(ByRef namespace As %String, class As %String, encoded As %Boolean, defaultElementQualified As %Boolean, defaultAttributeQualified As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	If namespace="" Set namespace="-"
	
	If $get(encoded)="" Set encoded=''$get(%encoded)
	If encoded && $get(%soap12) Set encoded=2

	If ..NoNamespace {
		Set namespace="-"
		Set elementQualified=1,attributeQualified=0
	} ElseIf class'="" {
		Set elementQualified=$$$comMemberKeyGet(class,$$$cCLASSparameter,"ELEMENTQUALIFIED",$$$cPARAMdefault)
		Set attributeQualified=$$$comMemberKeyGet(class,$$$cCLASSparameter,"ATTRIBUTEQUALIFIED",$$$cPARAMdefault)
	} Else {
		Set (elementQualified,attributeQualified)=""
	}
	If elementQualified="" Set elementQualified=$get(defaultElementQualified)
	If attributeQualified="" Set attributeQualified=$get(defaultAttributeQualified)

	If '$data(..namespaceIndices(namespace)) {
		Do ..Namespaces.Insert(namespace)
		Set ..namespaceIndices(namespace)=..Namespaces.Count()
		Set node=..Document.GetDocumentElement()
		Do node.AppendElement("schema",$$$XSDns)
		Do node.MoveToLastChild()
		If (namespace'="") && (namespace'="-") {
			Do node.SetAttribute("targetNamespace",$$$XSDns,namespace)
		} Else {
			Do node.SetAttribute("xmlns")
		}
		Set ..namespaceElementQualified(namespace)=elementQualified
		Set ..namespaceAttributeQualified(namespace)=attributeQualified
		Set ..namespaceEncoded(namespace)=encoded
		Set ..namespaceSchema(namespace)=node.NodeId
	} ElseIf class'="" {
		If $get(..namespaceEncoded(namespace))="" {
			Set ..namespaceEncoded(namespace)=encoded
		} ElseIf ..namespaceEncoded(namespace)'=encoded {
			Quit $$$ERROR($$$XMLSchemaBadEncoded,namespace)
		}
		
		If $get(..namespaceElementQualified(namespace))="" {
			Set ..namespaceElementQualified(namespace)=elementQualified
		} ElseIf (elementQualified'="") && (..namespaceElementQualified(namespace)'=elementQualified) {
			Quit $$$ERROR($$$XMLSchemaBadQualified,namespace)
		}
		If $get(..namespaceAttributeQualified(namespace))="" {
			Set ..namespaceAttributeQualified(namespace)=attributeQualified
		} ElseIf (attributeQualified'="") && (..namespaceAttributeQualified(namespace)'=attributeQualified) {
			Quit $$$ERROR($$$XMLSchemaBadQualified,namespace)
		}
	}
	
	Quit $$$OK
}

/// DefineImport defines that a schema is imported by the current namespace's schema.
/// The current schema is defined by the targetNamespace attribute of the schedma node
/// of the node parameter.
/// The namespace to be imported is defined by the importNamespace parameter.
Method DefineImport(importNamespace As %String) [ Internal, Private, ServerOnly = 1 ]
{
	;;If (importNamespace="") || (importNamespace="-") Quit
	If importNamespace="" Set importNamespace="-"
	Set namespace=$select(%namespace="":"-",1:%namespace)
	If namespace'=importNamespace {
		Do ..DefineNamespace(importNamespace,"")
		Set namespaceIndex=..namespaceIndices(namespace)
		Set ..namespaceImport(namespaceIndex,importNamespace)=""
	}
}

/// Get the node for the schema element that corresponds to the specified namespace.
Method GetSchema(namespace As %String) As %XML.Node [ ServerOnly = 1 ]
{
	If namespace="" Set namespace="-"
	Set nodeid=$get(..namespaceSchema(namespace))
	If nodeid'="" {
		Set node=..Document.GetDocumentElement()
		Set node.NodeId=nodeid
		If ..namespaceElementQualified(namespace)="" {
			Set ..namespaceElementQualified(namespace)='..namespaceEncoded(namespace)
		}
		If ..namespaceElementQualified(namespace) {
			Do node.SetAttribute("elementFormDefault",$$$XSDns,"qualified")
		}
		If ..namespaceAttributeQualified(namespace) {
			Do node.SetAttribute("attributeFormDefault",$$$XSDns,"qualified")
		}
		If node.HasChildNodes() {
			Set namespaceIndex=..namespaceIndices(namespace)
			If (namespaceIndex'="") && '$get(..namespaceImport(namespaceIndex)) {
				Do ..AddImports(node,namespaceIndex,..namespaceEncoded(namespace))
				Set ..namespaceImport(namespaceIndex)=1
			}
		} Else {
			Set node=""
		}
	} Else {
		Set node=""
	}
	Quit node
}

/// Define the location for import elements for a schema
Method DefineLocation(namespace As %String, location As %String) [ ServerOnly = 1 ]
{
	Set ..locations(namespace)=location
}

/// Define any additional import elements for a schema
/// The imports array is of the form imports(namespace)=location
Method DefineExtraImports(namespace As %String, ByRef imports) [ ServerOnly = 1 ]
{
	If namespace="" Set namespace="-"
	Set namespaceIndex=$get(..namespaceIndices(namespace))
	If namespaceIndex'="" {
		Merge ..namespaceImport(namespaceIndex)=imports
	}
}

/// Add the necessary import elements to a schema
Method AddImports(node As %XML.Node, namespaceIndex As %Integer, encoded As %Integer) [ Internal, Private, ServerOnly = 1 ]
{
	If 'node.MoveToFirstChild() Quit
	Set firstId=node.NodeId
	Do node.MoveToParent()
	Set namespace=$order(..namespaceImport(namespaceIndex,""))
	While namespace'="" {
		Set location=..namespaceImport(namespaceIndex,namespace)
		If location="",namespace'="-" Set location=$get(..locations(namespace))
		Set node.NodeId=node.InsertElement("import",$$$XSDns,.firstId)
		If namespace'="-" Do node.SetAttribute("namespace",$$$XSDns,namespace)
		If location'="" Do node.SetAttribute("schemaLocation",$$$XSDns,location)
		Do node.MoveToParent()
		Set namespace=$order(..namespaceImport(namespaceIndex,namespace))
	}
	If encoded {
		Set node.NodeId=node.InsertElement("import",$$$XSDns,.firstId)
		Do node.SetAttribute("namespace",$$$XSDns,$select(encoded=2:$$$SOAP12ENCns,1:$$$SOAPENCns))
		Do node.MoveToParent()
		Set node.NodeId=node.InsertElement("import",$$$XSDns,.firstId)
		Do node.SetAttribute("namespace",$$$XSDns,$$$WSDLns)
		Do node.MoveToParent()
	}
}

/// Implementation of override of XMLSchemaType for %XML.Dataset.
Method AddDatasetSchemaType(class As %String, node As %XML.Node, top As %String = "", encoded As %Boolean, summary As %Boolean = 0, input As %Boolean = 0, refOnly As %Boolean = 0) As %Status [ Internal, ServerOnly = 1 ]
{
	If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Quit $$$ERROR($$$XMLNotEnabled,class)
	}
	
	New %encoded,%soap12
	Set (%encoded,%soap12)=0

	If encoded Quit $$$ERROR($$$XMLInvalidEncoding,"encoded")

	Do node.AppendElement("complexType",$$$XSDns)
	Do node.MoveToLastChild()
	Do node.SetAttribute("name",$$$XSDns,top)
	Do node.AppendElement("sequence",$$$XSDns)
	Do node.MoveToLastChild()

	Set classNamespace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	If classNamespace'="" {
		Do node.AppendElement("any",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("namespace",$$$XSDns,classNamespace)
		Do node.MoveToParent()	; any
	} Else {
		Do node.AppendElement("element",$$$XSDns)
		Do node.MoveToLastChild()
		Do node.SetAttribute("ref",$$$XSDns,"schema",$$$XSDns)
		Do node.MoveToParent()	; element
		Do node.AppendElement("any",$$$XSDns)
	}
	Do node.MoveToParent()	; sequence
	Do node.MoveToParent()	; complexType
	Quit $$$OK
}

/// Fix up descriptions created from xs:documentation elements.
ClassMethod FixDocumentation(comment As %String) As %String [ Internal ]
{
	Set doc=""
	// This is to maintain untranslated CR
	Set comment=$tr(comment,$c(13),$c(0))
	Set pos=$find(comment,"<<")
	While pos>0 {
		Set doc=doc_$extract(comment,1,pos-3)
		Set comment=$extract(comment,pos,*)
		Set pos=$find(comment,">>")
		If pos>0 {
			Set comment=$extract(comment,pos,*)
			Set pos=$find(comment,"<<")
		}	
	}
	Set doc=doc_comment
	// This is to maintain untranslated CR
	Set doc=$tr($zcvt(doc,"O","XMLC"),$c(0),$c(13))
	Quit $zstrip(doc,"<>W")
}

/// Add property element to identify source of schema element.
Method PropertyAnnotation(node As %XML.Node, property As %String, xmlname As %String) [ Internal ]
{
	If property="" Quit
	
	If (..ServiceName'="") && (property'=xmlname) {
		Do node.SetAttribute("property",$$$ISCSOAPns,property)
	}
	If ..IncludeDocumentation && '..suppressDocumentation {
		Set propertyDescription=..FixDocumentation($$$comMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPdescription))
		If propertyDescription'="" {
			Do node.AppendElement("annotation",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.AppendElement("documentation",$$$XSDns)
			Do node.MoveToLastChild()
			Do node.AppendCharacter(propertyDescription,1)
			Do node.MoveToParent()				;  </s:documentation>
			Do node.MoveToParent()				;  </s:annotation>
		}
	}
}

}
