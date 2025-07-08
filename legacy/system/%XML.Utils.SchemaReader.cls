/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occSAX, %soap)

/// This class reads an XML schema and builds class definitions from it.<BR>
/// Schema reading works as follows:<BR>
/// First, the Parser class builds a tree structure 
/// representing the elements within the schema file,
/// then this class processes the tree to build class definitions.<BR>
/// 
/// This class is used by the XML Schema Wizard; it is not
/// for direct use within applications except through the Process and Reset methods.
/// Properties which are not marked as internal may be used to control the Process method.
/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Utils.SchemaReader">Generating Classes from XML Schemas</a>.
Class %XML.Utils.SchemaReader Extends %RegisteredObject [ System = 3 ]
{

/// Input property to control persistence of generated classes.
///  If true(1) create persistent classes, else create registered classes.  
///  Default is true. 
Property MakePersistent As %Boolean [ InitialExpression = 1 ];

/// Input property to control if generated classes are serial.
///  If true(1) and 'MakePersistent create serial classes, else create registered classes.
///  Default is true. 
Property MakeSerial As %Boolean [ InitialExpression = 0 ];

/// Input property to control creation of relationships in generated classes.
///  If true(1), convert list collections of persistent classes to relationships.
///  Default is true. 
Property MakeRelationships As %Boolean [ InitialExpression = 1 ];

/// Input property to control nature of relationships in generated classes.
///  The ParentChildRelationship property is only meaningful if MakeRelationships is true(1).
///  If ParentChildRelationship is true(1), the relationships that are created are parent-child relationsips.
///  Otherwise the relationships are many-one.
Property ParentChildRelationship As %Boolean [ InitialExpression = 0 ];

/// Input property to control nature of relationships in generated classes.
///  The IndexRelationship property is only meaningful if MakeRelationships is true(1)
///  and the relationship is many-one (ParentChildRelationship is false(0).
///  If IndexRelationship is true(1), the many-one relationships that are created are indexed.
Property IndexRelationship As %Boolean [ InitialExpression = 0 ];

/// Input property to control if a %OnDelete method is generated for persistent classes
/// in order to cascade deletes.
Property CascadeDeletes As %Boolean [ InitialExpression = 0 ];

/// Input property to control generation of XML namespace information.
///  If true(1), add NAMESPACE parameter to generated classes.  
///  Default is false(0) unless there are multiple targetNamespaces in which case the default is true(1). 
Property MakeNamespace As %Boolean;

/// Input property to control compilation of created classes.
/// Default is to compile classes.
Property CompileClasses As %Boolean [ InitialExpression = 1 ];

/// Flags to be used for class compiles.
Property CompileFlags As %String [ InitialExpression = "dk" ];

/// Input property to control removal of unused classes with no properties.<br>
/// If true(1), keep unused classes with no properties.<br>
/// Default is false(0).
Property KeepEmptyClasses As %Boolean [ InitialExpression = 0 ];

/// Input property to force creating classes for elements defined by 
/// referencing a type.<br>
/// This property is only meant for internal usage by the SOAP wizard.
Property KeepEmptyElements As %Boolean [ InitialExpression = 0, Internal ];

/// Input property to control use of arrays in created classes.<br>
///  If true(1), do not reduce properties to use array of cnostruct.<br>
///  Default is false(0).
Property NoArrayProperties As %Boolean [ InitialExpression = 0 ];

/// Input property to control the generation of the XMLNIL property parameter.
/// If GenerateXMLNIL = 1, then generate property parameter XMLNIL=1 for elements with nillable="true".
Property GenerateXMLNIL As %Boolean;

/// Input property to control the generation of the XMLNILNOOBJECT property parameter.
/// If GenerateXMLNILNOOBJECT = 1, then generate property parameter XMLNILNOOBJECT=1 for elements with nillable="true".
Property GenerateXMLNILNOOBJECT As %Boolean;

/// Input property to optionally add an identity property to persistent classes 
///  that contains an ID, OID or GUID.
///  Possible values for AddIdentity are "" (none), "ID", "OID" or "GUID".
Property AddIdentity As %String;

/// User supplied mapping of namespaces to package names which will override the default 
/// package used for a specified namespace.<br>
/// The format is PackageMapping(namespace)=package for each mapped namespace<br>
/// If package="", then the client classes are put in the default package.
/// If package begins with a period (.), then the package is appended to the default package.
/// Otherwise the package is used as specified.<br>
/// The PackageMapping property may only be used with the Process method.
Property PackageMapping As %String [ MultiDimensional ];

/// The name of the activated TLS/SSL configuration to use for https requests.
Property SSLConfiguration As %String;

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean;

/// This property should be set to a combination of flags (see %occSAX.inc for details) if
/// the default behavior of the parser is required to be modified.
/// The $$$SAXVALIDATIONPROHIBITDTDS flag is added by default in order to not allow DTDs.
Property SAXFlags As %Integer [ InitialExpression = {$$$SAXFULLDEFAULT+$$$SAXVALIDATIONPROHIBITDTDS} ];

/// This property should be set to an instance of %XML.SAX.EntityResolver OR a user-defined
/// subclass IF the default EntityResolver is not required.
Property EntityResolver As %XML.SAX.EntityResolver;

/// The %Net.HttpRequest instance to be used for all web requests for 
/// schema documents.  This property may optionally be set by the caller
/// in order to specify %Net.HttpRequest properties Username, ProxyPort, etc.
Property HttpRequest As %Net.HttpRequest [ Internal ];

/// Control display of debugging info
///  Debug level.  Additional output for levels >0. 
///  Default is 0. 
Property Debug As %Integer [ InitialExpression = 0 ];

/// Control test mode.
/// If true, make output repeatable for unit test, e.g. no dates.  
/// Default is false(0). 
Property TestFlag As %Boolean [ InitialExpression = 0 ];

/// Integer tree id within ^IRIS.Temp
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Tree As %Integer [ Internal ];

/// Number of elements in <property>ElTree</property>.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ElCount As %Integer [ InitialExpression = 0, Internal ];

/// Index of named tags used to resolve refs:<BR>
/// ElIndex(name) = elno<BR>
/// This gets built by the Parser
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ElIndex As %String [ Internal, MultiDimensional ];

/// Index of class XML type to # in class tree
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property TypeIndex As %String [ Internal, MultiDimensional ];

/// Index of class name to # in class tree
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ClassIndex As %String [ Internal, MultiDimensional, Private ];

/// Count of how many times we've found a given class name
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ClassCount As %Integer [ Internal, MultiDimensional, Private ];

/// Index of class # in order of who-uses-who
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ClassOrder As %String [ Internal, MultiDimensional, Private ];

/// List of element sources.  The src field is index into this array.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ElementSrc As %String [ Internal, MultiDimensional ];

/// Index into all top level elements.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Elements As %Integer [ Internal, MultiDimensional ];

/// Name of current package, if any.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property CurrentPackage As %String [ Internal, Private ];

/// The current namespace, if any.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property CurrentNamespace As %String [ Internal, Private ];

/// Name of default package, if any.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property DefaultPackage As %String [ Internal ];

/// List of elements that have already been processed
/// (used for cycle detection)
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Visits As %String [ Internal, MultiDimensional, Private ];

/// The output trace file (if any) used for debugging.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property TraceFile As %String [ Internal, Private ];

/// The subscript used if this schema has been saved to disk.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property SchemaId As %String [ Internal ];

/// Info on XML namespaces:<BR>
/// NSInfo(#,"uri")= uri<BR>
/// NSInfo(#,"Package")= package<BR>
/// NSInfo(#,"msdata")= 1, if Microsoft dataset in namespace<BR>
/// NSInfo(#,"ElementQualified")= 1, if elementFormDefault  = true<BR>
/// NSInfo(#,"AttributeQualified")= 1, if attributeFormDefault  = true<BR>
/// NSInfo(#,"Prefix") = fixedprefix
/// NSInfo(#,"NoClassPrefix") = 1 if no prefix because default namespace
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property NSInfo As %String [ Internal, MultiDimensional ];

/// Index of Namespace uri to Namespace #:<BR>
/// NSIndex(uri) = num
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property NSIndex As %String [ Internal, MultiDimensional ];

/// Target namespace for the containing Schema
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property TargetNS As %String [ Internal ];

/// True if multiple targetNamepsace's are defined.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property MultipleTargetNS As %Boolean [ Internal ];

/// List of include files:
/// an array subscripted by filename and namespace; 
/// nodes are set to 1 when they are processed<BR>
/// On Windows, the filename subscript is always lower case.
/// ..Includes(filename,ns) = "" or 1 for include
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Includes As %String [ Internal, MultiDimensional ];

/// Optional prefix (first part of package name--sans dot-- for all generated classes)
/// If we are reading a WSDL, this gets set from the content handler...
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ClassPrefix As %String [ Internal ];

/// Set NoClassPrefix=1 to prevent setting ClassPrefix from the WSDL.
Property NoClassPrefix As %Boolean [ Internal ];

/// ElementQualified for no namespace
Property NoNamespaceElementQualified As %Boolean [ Internal ];

/// AttributeQualified for no namespace
Property NoNamespaceAttributeQualified As %Boolean [ Internal ];

/// Class names in upper case
Property namesUpper As %Boolean [ Internal, MultiDimensional ];

/// Class names restricted to max unique length
Property names25 As %Boolean [ Internal, MultiDimensional ];

/// Get elementqualified for the specified namespace
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetElementQualified(namespace As %String) As %Boolean [ Internal ]
{
	If namespace '= "", namespace '= """""" {
		Set num=$get(..NSIndex(namespace))
		If num'="" Quit $get(..NSInfo(num,"ElementQualified"))
	} Else {
		Quit ..NoNamespaceElementQualified
	}
	Quit ""
}

/// Get attributequalified for the specified namespace
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetAttributeQualified(namespace As %String) As %Boolean [ Internal ]
{
	If namespace '= "", namespace '= """""" {
		Set num=$get(..NSIndex(namespace))
		If num'="" Quit $get(..NSInfo(num,"AttributeQualified"))
	} Else {
		Quit ..NoNamespaceAttributeQualified
	}
	Quit ""
}

/// Add a namespace to our list of known namespaces
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method AddNS(uri As %String, prefix As %String, elementQualified As %Boolean, attributeQualified As %Boolean) [ Internal ]
{
	// see if this is a NS we have not seen yet
	If uri '= "" {
		If '$data(..NSIndex(uri)) {
			Set new=1
			Set num = $O(..NSInfo(""),-1) + 1
			Set ..NSInfo(num,"uri") = uri
			Set fixedprefix = $select(prefix="$defaultNS":"",1:prefix)
			Set ..NSInfo(num,"Prefix") = fixedprefix
			Kill ..NSInfo(num,"NoClassPrefix")
			If $data(..PackageMapping(uri)) {
				Set pkg=..PackageMapping(uri)
				If $extract(pkg)="." {
					Set ..NSInfo(num,"Package")=$extract(pkg,2,*)
				} Else {
					Set ..NSInfo(num,"Package")=pkg
					If pkg'="" Set ..NSInfo(num,"NoClassPrefix")=1
				}
			} Else {
				Set ..NSInfo(num,"Package") = ..MakeClassName(fixedprefix)
			}
			Set ..NSInfo(num,"ElementQualified") = elementQualified
			Set ..NSInfo(num,"AttributeQualified") = attributeQualified
			Set ..NSIndex(uri) = num
		} Else {
			Set new=0
			Set num=..NSIndex(uri)
			If (prefix'="") && $case(..NSInfo(num,"Package"),"":1,"$defaultNS":1,:0) {
				Set fixedprefix = $select(prefix="$defaultNS":"",1:prefix)
				Set ..NSInfo(num,"Prefix") = fixedprefix
				Kill ..NSInfo(num,"NoClassPrefix")
				If $data(..PackageMapping(uri)) {
					Set pkg=..PackageMapping(uri)
					If $extract(pkg)="." {
						Set ..NSInfo(num,"Package")=$extract(pkg,2,*)
					} Else {
						Set ..NSInfo(num,"Package")=pkg
						If pkg'="" Set ..NSInfo(num,"NoClassPrefix")=1
					}
				} Else {
					Set ..NSInfo(num,"Package") = ..MakeClassName(fixedprefix)
				}
			}
			If (elementQualified'="") && ($get(..NSInfo(num,"ElementQualified"))="") {
				Set ..NSInfo(num,"ElementQualified") = elementQualified
			}
			If (attributeQualified'="") && ($get(..NSInfo(num,"AttributeQualified"))="") {
				Set ..NSInfo(num,"AttributeQualified") = attributeQualified
			}
		}
		Do:(..Debug>1) ..TraceMsg("Add Namespace: " _ uri _ ", " _ prefix _ ", " _ elementQualified _ ", " _ $get(num))
		Do:(..Debug>1) ..TraceMsg($select(new:"New",1:"Found")_", Prefix: " _ ..NSInfo(num,"Prefix") _ ", Package: " _ ..NSInfo(num,"Package"))
	} Else {
		If ..NoNamespaceElementQualified="" {
			Set ..NoNamespaceElementQualified=elementQualified
		}
		If ..NoNamespaceAttributeQualified="" {
			Set ..NoNamespaceAttributeQualified=attributeQualified
		}
	}
}

/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method %OnNew(initvalue As %RawString) As %Status [ Internal, Private ]
{
	// !!!
	If ($data(^XML.trace)) {
		Set ..TraceFile = "\temp\trace.txt"
		Open ..TraceFile:"WSN"
	}
	
	Quit $$$OK
}

/// Reset this class instance for reuse.
Method Reset()
{
	If ..Tree'="" {
		Kill $$$ElTreeRoot
		Set ..Tree=""
	}
	Kill ..ElIndex
	Kill ..TypeIndex
	Kill ..ClassIndex
	Kill ..ClassCount
	Kill ..ClassOrder
	Set ..CurrentPackage = ""
	Set ..CurrentNamespace = ""
	Set ..DefaultPackage = ""
	Kill ..Visits
	Kill ..Includes
	Set nsindex=$order(..NSInfo(""))
	While nsindex '= "" {
		Kill ..NSInfo(nsindex,"msdata"),..NSInfo(nsindex,"dataset")
		Set nsindex=$order(..NSInfo(nsindex))
	}
}

/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method %OnClose() As %Status [ Internal, Private ]
{
	// Cleanup the tree created by %XML.Utils.SchemaHandler
	If ..Tree'="" Kill $$$ElTreeRoot

	If (..TraceFile '= "") {
		Close ..TraceFile
	}
	Quit $$$OK
}

/// Test if element <var>elno</var> has any sub-elements
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method HasSubElements(elno As %Integer) As %Boolean [ Internal, Private ]
{
	Set result = 0

	Set ch = $O($$$ElTree(elno,"ch",""))
	While (ch '= "") {
		If '$case($get($$$ElTree(ch,"local")),"annotation":1,"key":1,"keyref":1,"unique":1,:0) {
			Set result = 1
			Quit
		}

		Set ch = $O($$$ElTree(elno,"ch",ch))
	}
	
	Quit result
}

/// Test if sequence <var>elno</var> contains exactly one element
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method HasSingleSubElement(elno As %Integer) As %Boolean [ Internal, Private ]
{
	Set result = 1
	Set num = 0

	Set ch = $O($$$ElTree(elno,"ch",""))
	While (ch '= "") {
		If ($get($$$ElTree(ch,"local")) '= "annotation") {
			If $get($$$ElTree(ch,"local")) '= "element" Set result = 0 Quit
			Set num = num + 1
			If num > 1 Set result = 0 Quit
		}

		Set ch = $O($$$ElTree(elno,"ch",ch))
	}
	
	If num = 0 Set result = 0
	
	Quit result
}

/// Deprecated command line interface to Schema Wizard
/// Use Process method
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod ProcessSchema(LocationURL As %String, Package As %String, Debug As %Integer = 0, TestFlag As %Boolean = 0, MakeRelationships As %Boolean = 1, MakeNamespace As %Boolean = 0, Output Reader As SchemaReader, compileFlags As %String) As %Status [ Deprecated, Internal ]
{

 	// Create the schema reader
	Set Reader = ##class(%XML.Utils.SchemaReader).%New()
	Set Reader.Debug=Debug
	Set Reader.TestFlag=TestFlag
	Set Reader.MakeRelationships=MakeRelationships
	Set Reader.MakeNamespace=MakeNamespace
	If $data(compileFlags) Set Reader.CompileFlags=compileFlags
	
	Quit Reader.Process(LocationURL,.Package)
}

/// Command line interface to Schema Wizard
/// LocationURL is the filename or the URL of an XML schema.
/// Package is the name of the package in which the method should place the generated classes.
/// Features is a Multidimensional Array to Store Additional Settings.
/// The possible nodes are as follows:<br>
///    Features("DEFAULTSEQUENCE") If this node exists, the wizard does not set the XMLSEQUENCE parameter in the generated classes.<br>
///    Features("JAVA") If this node exists, each class includes a Java projection.<br>
///    Features("NOSEQUENCE") If this node exists, the wizard sets the XMLSEQUENCE parameter to 0 in the generated classes.<br>
///    Features("POPULATE") If this node exists, each class extends %Populate in addition to %XML.Adaptor.<br>
///    Features("SQLCOLUMNS") If this node exists, each class property specifies a value for the SqlColumnNumber keyword, so that the properties have the same order in SQL that they have in the schema.<br>
///    Features("IGNORENULL") If this node is set, the XMLIGNORENULL parameter is set to this value for each class.
///    Features("BINARYASSTREAM") If this node exists, then use %Stream.GlobalBinary for base64Binary type
Method Process(LocationURL As %String, Package As %String = "Test", ByRef Features As %String) As %Status
{
 	Set sc=$$$OK
 	Set $ZT = "Trap"

 	Do {
	 	// Save the package information
 		Set ..ClassPrefix = Package
 		Set ..NoClassPrefix=0

 		Set sc = ..ParseSchema("",LocationURL)
 		If $$$ISERR(sc) Quit
 		
		// Return error if no schema in file
		If $order($$$ElTree(0,"ch",""))="" {
			Set sc=$$$ERROR($$$XSDNoSchema)
			Quit
		}

 		// generate classes so they are ready for use
 		Set result = ##class(%XML.Utils.SchemaResult).CreateResult($this,,.Features)
  		If '$IsObject(result) {
	  		Set sc = $$$ERROR($$$XMLSchemaWizardError,"Unable to create SchemaResult")
	  		Quit
  		}
  		
		Set sc = result.SaveClasses((..Debug>4),..TestFlag)
  		If $$$ISERR(sc) Quit

		If ..CompileClasses {
			Set sc = result.CompileClasses((..Debug>4),..CompileFlags)
  			If $$$ISERR(sc) Quit
		}
  		
 	} While (0)

Exit
	If ((..Debug > 0) && $$$ISERR(sc)) {
		Do $system.Status.DisplayError(sc)
	}

	Quit sc 	
Trap
	Set $ZT = ""
	Set sc = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Command line interface to create an internal XSchema format file from an XML schema.<br>
/// locationURL is the location of the input XML schema.<br>
/// filepath is the file path for the new file containing the XSchema. 
Method XSchema(locationURL As %String, filepath As %String) As %Status
{
 	Set $ZT = "XSchemaTrap"

 	// Temp package information
	Set ..ClassPrefix = "XSchema"
	
	// Setup for registered classes with namespace information
	Set ..MakePersistent=0
	Set ..MakeSerial=0
	Set ..MakeRelationships=0
	Set ..ParentChildRelationship=0
	Set ..IndexRelationship=0
	Set ..MakeNamespace=1

	Set sc = ..ParseSchema("",locationURL)
	
	If $$$ISOK(sc) {
 		Set result = ##class(%XML.Utils.SchemaResult).CreateResult($this)
  		If '$IsObject(result) {
	  		Set sc = $$$ERROR($$$XMLSchemaWizardError,"Unable to create SchemaResult")
  		}
	}
  		
	If $$$ISOK(sc) Set sc=result.XSchemaToFile(filepath)
 		
	If ((..Debug > 0) && $$$ISERR(sc)) {
		Do $system.Status.DisplayError(sc)
	}

	Quit sc 	

XSchemaTrap  Set $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Fix classname of element references
/// Cannot set classname until this late to allow class to be created.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixElementRefClassName() [ Internal, Private ]
{
	// find all the ref attrs...

	Set elno = $order($$$ElTree(""))

	While (elno '= "") {
		// Look for element with a ref attribute
		If $data($$$ElTree(elno,"attrs","ref")) && ($get($$$ElTree(elno,"local"))="element") {
			Set refno = $get($$$ElTree(elno,"attrs","ref#"))
			If (refno '= "") {
				Set cls = $order($$$ElTree(elno,"parent",""))
				While cls'="" {
					Set refcls = $get($$$ClassTree(refno,"ClassName"))
					Set reftype = $get($$$ClassTree(refno,"Type"))
					Set pno = $list($$$ElTree(elno,"parent",cls),1)
					If (refcls'="") Set $$$ClassTree(cls,"Property",pno,"Type") = reftype
					Do:(..Debug>1) ..TraceMsg(" Fixed Element Ref: ["_reftype_":"_refcls_":"_cls_":"_$$$ClassTree(cls,"Property",pno,"Name")_"]")
					Set cls = $order($$$ElTree(elno,"parent",cls))
				}
			}
		}
		Set elno = $order($$$ElTree(elno))
	}
}

/// Loop over the initial parsetree and fix up any refs
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixReferences() [ Internal, Private ]
{
	// find all the ref attrs...

	Set elno = $O($$$ElTree(""))

	While (elno '= "") {
		// see if this element has a ref attribute
		If ($D($$$ElTree(elno,"attrs","ref"))) {
			Set ref = $$$ElTree(elno,"attrs","ref")
			
			Set src = ""
			Set:ref'="" src = $G(..ElIndex(ref))
			
			If ..Debug>1 Write "**** fix ref: ref="_ref_", src="_src,!
			
			If (src '= "") {
				// remember elno this ref points to
				Set $$$ElTree(elno,"attrs","ref#") = src
				
				// copy ref'd element attrs into target
				// attributes in this node override the ref'ed attributes
				Kill saveAttrs
				Merge saveAttrs = $$$ElTree(elno,"attrs")
				Merge $$$ElTree(elno) = $$$ElTree(src)
				Merge $$$ElTree(elno,"attrs") = saveAttrs
			} ElseIf (ref[":") && ($piece(ref,":",1)="xml") {
				// xml: namespace
				Set $$$ElTree(elno,"attrs","type") = ref
				If ..Debug>1 Write "**** fix ref for xml namespace: ref="_ref,!
			} Else {
				// test if this is ref to a SOAP or other predefined type
				
				Set uri = ""
				Set ns = $piece(ref,"^",1)
				Set:ns'="" uri = $get(..NSInfo(ns,"uri"))
				If ..IsXMLSchemaNS(uri) {
					// a SOAP type: OK
					Set $$$ElTree(elno,"attrs","type") = ref
					If ..Debug>1 Write "**** fix ref for system namespace: ref="_ref_", uri="_uri,!
				}
				Else {
					// unresolved reference
					Kill $$$ElTree(elno,"attrs","ref#")
					Kill $$$ElTree(elno,"attrs","ref")
					Do ..TraceMsg("(SchemaReader) Reference to an undefined element: '" _ ref _ "'",elno)
				}
			}
		}
		Set elno = $O($$$ElTree(elno))
	}
}

/// Invoked by the Wizard to find all referenced namespaces
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method PreParseSchema(filename As %String, url As %String = "", ByRef multipleNamespace As %Boolean, ByRef noSchema As %Boolean) As %Status [ Internal ]
{
	Set noSchema=0
	// Prepare Tree
	If ..Tree'="" Kill $$$ElTreeRoot
	Set ..Tree=$$$ElTreeIncrement
	Kill $$$ElTreeRoot
	Set ..MultipleTargetNS = 0
	Set ..TargetNS=$c(1)
	
	If (url '= "") {
		// Parse the schema url
		If $$$isWINDOWS && ($extract($zcvt(url,"L"),1,7)="file://") Set url=$zcvt(url,"L")
		Set sc=##class(SchemaHandler).ParseURL(url, $this)
		If $$$ISERR(sc) Quit sc
		// mark this as visited
		Set ..Includes(url,$select(..TargetNS'="":..TargetNS,1:$c(2))) = 1
	}
	Else {
		// Parse the schema file
		If $$$isWINDOWS Set filename=$zcvt(filename,"L")
		Set sc=##class(SchemaHandler).ParseFile(filename, $this)
		If $$$ISERR(sc) Quit sc
		// mark this as visited
		Set ..Includes(filename,$select(..TargetNS'="":..TargetNS,1:$c(2))) = 1
	}

	// process includes
	Set sc=..ProcessIncludes()
	If $$$ISERR(sc) Quit sc
	
	// Return if multiple targetNamespace's found.
	Set multipleNamespace = ..MultipleTargetNS
	
	// Indicate if no schema found
	If $order($$$ElTree(0,"ch",""))="" Set noSchema=1

	Quit $$$OK
}

/// Invoked by the EnsLib.EDI.XML.SchemaXSD:Import() method...
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method PreParseLocation(location As %String) As %Status [ Internal ]
{
	// Prepare Tree
	If ..Tree'="" Kill $$$ElTreeRoot
	Set ..Tree=$$$ElTreeIncrement
	Kill $$$ElTreeRoot
	Set ..MultipleTargetNS = 0
	Set ..TargetNS=$c(1)

	If '$IsObject(location) {
		If location'["://" {
			// Parse the schema file
			Set sc = ##class(%XML.Utils.SchemaHandler).ParseFile(location, $this)  Quit:$$$ISERR(sc) sc
		} Else {
			// Parse the schema url
			Set sc = ##class(%XML.Utils.SchemaHandler).ParseURL(location, $this)  Quit:$$$ISERR(sc) sc
		}
		Set ..Includes(location,$select(..TargetNS'="":..TargetNS,1:$c(2))) = 1 ; mark as visited
	} Else {
		// Parse the schema stream object
		Set stream=location
		Set sc = ##class(%XML.Utils.SchemaHandler).ParseStream(stream, $this)  Quit:$$$ISERR(sc) sc
		Set srcname=$S(stream.%Extends("%Library.AbstractStream"):$G(stream.Attributes("Filename")),stream.%Extends("%CSP.Stream"):stream.GetAttribute("Filename"),1:"") ; put in ParseStream?
		Set:""'=srcname ..Includes(srcname,$S(..TargetNS'="":..TargetNS,1:$c(2))) = 1 ; mark as visited
	}
	// process includes
	Set sc=..ProcessIncludes()  Quit:$$$ISERR(sc) sc

	If ..MultipleTargetNS && (..MakeNamespace="") Set ..MakeNamespace=1
	If ..TargetNS=$c(1) Set ..TargetNS=""

	Do ..FixReferences()

	// if there is a class prefix, then do not use a package name
	// for the TargetNS schema unless explictiely set using PackageMapping.
	If ..TargetNS'="",..ClassPrefix'="",'$data(..PackageMapping(..TargetNS)) {
		Set idx = ..NSIndex(..TargetNS)
		Set ..NSInfo(idx,"Package")=""
	}
	Quit sc
}

/// Invoked by the Wizard to actually create classes...
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ParseSchema(filename As %String, url As %String = "") As %Status [ Internal ]
{
	Set sc = $$$OK, $ZT = "Trap"
	Do {
		If (url '= "") {
			// Parse the schema url
			Write:(..Debug>1) "PARSE URL: ",url,!
			Set sc = ..PreParseLocation(url)
		}
		Else {
			// Parse the schema file
			Write:(..Debug>1) "PARSE FILE: ",filename,!
			Set sc = ..PreParseLocation(filename)
		}
		Quit:$$$ISERR(sc)
		
		// now walk over the parse tree
		Do ..ProcessTree()
		
		// now go back and fixup classname in element ref=... 
		// with inline complexType
		Do ..FixElementRefClassName()
		
		// decorate the parse tree
		Do ..BuildClassInfo()
	
		// remove extraneous classes
	 	Do ..ReduceClasses()
	 	
	 	// redecorate the parse tree
		Do ..BuildClassInfo()
	
		// remove extraneous classes
	 	If '..NoArrayProperties Do ..ReducePairClasses()
	 	
	 	// redecorate the parse tree
		Do ..BuildClassInfo()
	
		// Fix names to meet Cache constraints.
		Set sc=..FixClassNames(0)
		Set sc=..FixClassNames(1)
		If $$$ISERR(sc) Quit
		Do ..FixPropertyNames()
		
		// If NAMESPACE parameters not desired, remove them.
		If '..MakeNamespace Do ..RemoveClassNamespace()
		
		// Resolve restriction by adding in attributes
		// Change unreferenced serial classes to persistent or registered.
		// Remove XMLINLCUDEINGROUP where not needed.
		Do ..FixupClasses()
		
		// convert collections to relationships
		If ..MakeRelationships Do ..FindRelationships(..ParentChildRelationship,..IndexRelationship)
	
		Do ..FindCompileAfter()
	} While (0)

Exit	
	Quit sc
Trap
	Set $ZT = ""
	Set sc = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Process the include and/or import files for this schema
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessIncludes() As %Status [ Internal, Private ]
{
	// repeat this loop until there are no more includes...
	Set tSC=$$$OK
	Set done = 0
	While ('done) {
		Set done = 1

		Set filename = $order(..Includes(""))
		While (filename '= "") {
			Set ns = $order(..Includes(filename,""))
			While ns'="" {
				If (..Includes(filename,ns) '= 1) {
					Set done = 0 // this is not the last pass...
					Set ..Includes(filename,ns) = 1 // mark this as visited
					
					Write:(..Debug>1) "PARSE URL (included): ",filename,!
					Set tSC = ##class(SchemaHandler).ParseURL(filename,$this,$select(ns=$c(2):"",1:ns),1)
	
					If ($$$ISERR(tSC)) {
						Do $System.Status.DecomposeStatus(tSC,.err)
						Do ..TraceMsg("Unable to find include/import file: " _ filename _ " [" _ err(1) _ "]")
						Quit
					}
				}		
				Set ns = $order(..Includes(filename,ns))
			}
			Set filename = $order(..Includes(filename))
		}
	}
	Quit tSC
}

/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method Trace(method As %String, elno As %Integer = "", cls As %Integer = "", prop As %Integer = "") [ Internal, Private ]
{
	// suppress output in CSP
	//QUIT:($D(%request)&&(..TraceFile=""))

	QUIT:((..Debug=0)&&(..TraceFile=""))
	
	If (..TraceFile '= "") {
		Set io = $IO
		USE ..TraceFile
	}
	
	Write:method="TopElement" !
	Write ?5,"TRACE: ",method,"(",elno,",",cls,",",prop,")"
	If (elno '= "") {
		Write ?30,$J(elno,3)," ",$G($$$ElTree(elno,"local")),?50,$G($$$ElTree(elno,"attrs","name"))
		Write " ",$G($$$ElTree(elno,"attrs","type"))
		Write:$D($$$ElTree(elno,"attrs","ref")) " ",$G($$$ElTree(elno,"attrs","ref#"))
	}
	
	If ($IsObject($G(%response))) {
		Write "<BR>",!
		Do %response.Flush()
	}
	Else {
		Write !
	}

	If (..TraceFile '= "") {
		USE io
	}
}

/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method TraceMsg(msg As %String, elno As %Integer = "") [ Internal, Private ]
{
	// suppress output in CSP
	//QUIT:($D(%request)&&(..TraceFile=""))

	QUIT:((..Debug=0)&&(..TraceFile=""))

	If (..TraceFile '= "") {
		Set io = $IO
		USE ..TraceFile
	}

	Write msg
	Write:elno'="" ?30,$J(elno,3)," ",$G($$$ElTree(elno,"local"))

	If ($IsObject($G(%response))) {
		Write "<BR>",!
		Do %response.Flush()
	}
	Else {
		Write !
	}

	If (..TraceFile '= "") {
		USE io
	}
}

/// Save the class tree to disk; Returns the SchemaId
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method Save() As %String [ Internal ]
{
	If (..SchemaId = "") {
		// allocate a new ID #
		Set ..SchemaId = $I(^IRIS.TempSchemaWiz)
	}
	
	// Save the Class Tree to Disk
	Merge ^IRIS.TempSchemaWiz(..SchemaId,"Classes") = $$$ClassTreeRoot
	Merge ^IRIS.TempSchemaWiz(..SchemaId,"ElementSrc") = ..ElementSrc

	Merge ^IRIS.TempSchemaWiz(..SchemaId,"NSInfo") = ..NSInfo
	Merge ^IRIS.TempSchemaWiz(..SchemaId,"NSIndex") = ..NSIndex
	Merge ^IRIS.TempSchemaWiz(..SchemaId,"TypeIndex") = ..TypeIndex

	Quit ..SchemaId
}

/// Retreive a class tree from disk
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod Open(id As %String) As SchemaReader [ Internal ]
{
	If ((id = "") || ('$D(^IRIS.TempSchemaWiz))) {
		Quit ""
	}
	
	Set reader = ..%New()
	Set reader.SchemaId = id

	Do reader.OpenSetup(id)
	
	Quit reader
}

/// Setup a class tree after open from disk
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method OpenSetup(id As %String) As SchemaReader [ Internal ]
{
	// Prepare Tree
	If ..Tree'="" Kill $$$ElTreeRoot
	Set ..Tree=$$$ElTreeIncrement
	Kill $$$ElTreeRoot

	Merge $$$ClassTreeRoot = ^IRIS.TempSchemaWiz(id,"Classes")
	Merge ..ElementSrc = ^IRIS.TempSchemaWiz(id,"ElementSrc")

	Merge ..NSInfo = ^IRIS.TempSchemaWiz(id,"NSInfo")
	Merge ..NSIndex = ^IRIS.TempSchemaWiz(id,"NSIndex")
	Merge ..TypeIndex = ^IRIS.TempSchemaWiz(id,"TypeIndex")

	Do ..BuildClassInfo()
}

/// Delete a class tree from disk
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod Delete(id As %String) [ Internal ]
{
	If (id '= "") {
		Kill ^IRIS.TempSchemaWiz(id)
	}
}

/// Set class type for XML Schema Wizard
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method WizardSetClassType(cls As %String, type As %String) [ Internal ]
{
	Set idx = $get(..ClassIndex(cls))
	If ((idx '= "") && ($data($$$ClassTree(idx)))) {
		If ($get($$$ClassTree(idx,"ClassType")) '= type) {
			Set $$$ClassTree(idx,"ClassType") = $select(type="registered":"",1:type)
			If (type = "persistent") {
				Set $$$ClassTree(idx,"Super") = "%Persistent,%XML.Adaptor"
			}
			ElseIf (type = "serial") {
				Set $$$ClassTree(idx,"Super") = "%SerialObject,%XML.Adaptor"
			}
			ElseIf (type = "registered") {
				Set $$$ClassTree(idx,"Super") = "%RegisteredObject,%XML.Adaptor"
			}
		}
	}
}

/// Add an index to a property for the XML Schema Wizard
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method WizardAddIndex(cls As %String, pname As %String) [ Internal ]
{
	Set idx = $get(..ClassIndex(cls))
	If ((idx '= "") && ($data($$$ClassTree(idx)))) {
		// find prop
		Set pno = $order($$$ClassTree(idx,"Property",""))
		While (pno '= "") {
			If ($get($$$ClassTree(idx,"Property",pno,"Name")) = pname) {
				// add an index for this class
				Set $$$ClassTree(idx,"Index",pno,"Name") = pname
				// !!! Set $$$ClassTree(idx,"Index",pno,"Type") = "bitmap"
				Set $$$ClassTree(idx,"Index",pno,"Property") = pname
			}
			Set pno = $order($$$ClassTree(idx,"Property",pno))
		}
	}
}

/// Remove a class from the list of classes
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method RemoveClassFromList(key As %String)
{
	If (key'="") && '$data($$$ClassTree(key,"UsedBy")) {
		Set $$$ClassTree(key,"Removed")=1
	}
}

/// Get element given namespace and element name for WSDL reader
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetCacheElement(pNamespace, pTypeName, ByRef pCacheType, ByRef pTypeNamespace As %String, Output elno) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set elno=""
	
	Do {
		Set pTypeNamespace=""
		If (pNamespace = "") {
			Set tSC = $$$ERROR($$$SOAPMessagePartError,"Missing Namespace")
			Quit
		}
		Set elno = $get(..Elements(..NSIndex(pNamespace)_"^"_pTypeName))
		If elno'="" {
			Set type = $get($$$ClassTree(elno,"Type"))
			// If no type specified in schema or wsdl, this is OK.
			if type="" Set pCacheType=type Quit
			
			If type'="" Set type = ..TypeToClass(type,.isdt)
			If (type'="") && 'isdt && ($get(..ClassIndex(type))="") Set type=""
			If type'="" {
				Set key=$get(..ClassIndex(type))
				If key'="" Set pTypeNamespace=$get($$$ClassTree(key,"Parameter","NAMESPACE"))
			}
		} Else {
			Set type=""
		}

		If type'="" {
			Set pCacheType=type
		} Else {
			Set tSC = $$$ERROR($$$SOAPMessagePartError,"Classname not found for "_pNamespace_"::"_pTypeName)
			Quit
		}
	} While (0)
	
	Quit tSC
}

/// Get ObjectScript type given namespace and typename for WSDL reader
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetCacheType(pNamespace, pTypeName, ByRef pCacheType, Output key) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set key=""
	
	Do {
		If (pNamespace '= "") && (..IsXMLSchemaNS(pNamespace)) {
			// built-in schema type
			Set pCacheType = ..XSTypeToClass(pTypeName)
		}
		ElseIf (pTypeName = "DataSet") {
			// !!!
			Set pCacheType = "%String"
		}
		Else {
			// complex type
			// find namespace in index
			If pNamespace '= "",pNamespace'="""""" {
				Set tNSIDX = $get(..NSIndex(pNamespace))
				If (tNSIDX = "") {
					Set tSC = $$$ERROR($$$SOAPMessagePartError,"Unknown Namespace: " _ pNamespace)
					Quit
				}
				Set tPKG = $get(..NSInfo(tNSIDX,"Package"))
				If tPKG = "$defaultNS" Set tPKG = ""
			} Else {
				Set tNSIDX = ""
				Set tPKG = ..DefaultPackage
			}
			Set type=tNSIDX_"^"_pTypeName
			Set key=$get(..TypeIndex(type))
			If key'="" {
				If $get($$$ClassTree(key,"Removed")) = 1 {
					Set $$$ClassTree(key,"Removed") = 0
				}
				Set pCacheType=$get($$$ClassTree(key,"ClassName"))
				If pCacheType'="" Quit
			}

			// now convert type to a class name (it should match the discovered name)
			Set pCacheType = ..MakeClassName(pTypeName)
			If (tPKG '= "") {
				Set pCacheType = tPKG _ "." _ pCacheType
			}
		
			If ..ClassPrefix'="",(tNSIDX="") || '$get(..NSInfo(tNSIDX,"NoClassPrefix")) {
				Set pCacheType = ..ClassPrefix _ "." _ pCacheType
			}
		}
		
	} While (0)
	
	Quit tSC
}

/// Check the depth of the ELTree (for debugging)
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method CheckDepth() [ Internal, Private ]
{
	Set level = 0
	Set max = 0
	Set stack = 0
	Set stack(0) = 0

	// loop over children of top node
	Set child = $O($$$ElTree(stack(stack),"ch",""))
	While (child '= "" && (level < 70)) {
		Write:(..Debug>1) ?level,child,!
		Set visit(child) = ""
		
		// does this child have children
		Set gchild = $O($$$ElTree(child,"ch",""))
		If (gchild '= "") {
			// go down this branch
			Set level = level + 1
			Set stack = stack + 1
			Set stack(stack) = child
			
			Set child = gchild
		}
		Else {
			// next sibling
			Set done = 0
			While ('done) {
				Set next = $O($$$ElTree(stack(stack),"ch",child))
				
				If (next = "") {
					// popup one level
					If (stack = 0) {
						Set child = ""
						Set done = 1
					}
					Else {
						Set level = level - 1
						Set child = stack(stack)
						Set stack = stack - 1
					}
				}
				Else {
					Set child = next
					If ($D(visit(next))) {
						// already been here, skip it
					}
					Else {
						Set done = 1
					}
				}
			}			
		}
	}
}

/// There may be duplicate class definitions; this
/// method will remove the extras.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method RemoveDuplicateClasses() As %Boolean [ Internal, Private ]
{
	Write:(..Debug>1) "Testing for duplicate classes:",!
	Set duplicateRemoved = 0
	
	// remove duplicate classes
	// iterate in used by order to process in correct order.
	
	Set o = $O(..ClassOrder(""),-1)
	While (o '= "") {
		Set key = $O(..ClassOrder(o,""))

		Set root = $G($$$ClassTree(key,"ClassName"))

		If ((root '= "") && $D(..ClassCount(root))) {
			// compare each of the classes in this set
			Set count = ..ClassCount(root)
			If (count > 1) {
				For i = 1:1:count {
					Set nameA = root _ $S(i = 1:"",1:"/"_i)
					Set clsA = $G(..ClassIndex(nameA),"!!!") // why would this be undef?
					
					If ((clsA '= "!!!") && $G($$$ClassTree(clsA,"Removed")) '= 1) {
						Write:(..Debug>1) nameA,!
						For j = i+1:1:count {
							Set nameB = root _ "/" _ j
							Set clsB = $G(..ClassIndex(nameB),"!!!") // !!!
							If (clsB '= "!!!") && ($G($$$ClassTree(clsB,"Removed")) '= 1) {
								Write:(..Debug>1) ?5,nameB_",clsA="_clsA_",clsB="_clsB

								If (..AreClassesDuplicate(clsA,clsB)) {
									Write:(..Debug>1) " duplicate"
									Set $$$ClassTree(clsB,"Removed") = 1
									Set duplicateRemoved = 1
									
									// Fix TypeIndex references to clsB
									Set type=$order(..TypeIndex(""),1,cls)
									While type'="" {
										If cls=clsB {
											Write:(..Debug>1) " TypeIndex("_type_") fixed"
											Set ..TypeIndex(type)=clsA
										}
										Set type=$order(..TypeIndex(type),1,cls)
									}
									
									// Fix all properties that refer to clsB
									Set uc = $O($$$ClassTree(clsB,"UsedBy",""))
									While (uc '= "") {
										Set up = $O($$$ClassTree(clsB,"UsedBy",uc,""))
										While (up '= "") {
											Set $$$ClassTree(uc,"Property",up,"Type") = $G($$$ClassTree(clsA,"Type"),"!!!")
											Kill $$$ClassTree(clsB,"UsedBy",uc,up)
											Set $$$ClassTree(clsA,"UsedBy",uc,up) = ""
											Set up = $O($$$ClassTree(clsB,"UsedBy",uc,up))
										}
										Set uc = $O($$$ClassTree(clsB,"UsedBy",uc))
									}
									
									//Fix super class references
									Set uc = $O($$$ClassTree(clsB,"SuperBy",""))
									While (uc '= "") {
										If $data($$$ClassTree(uc)) {
											Set $$$ClassTree(uc,"Super") = $get($$$ClassTree(clsA,"Type"),"!!!")
										}
										Set uc = $O($$$ClassTree(clsB,"SuperBy",uc))
									}

								}
								Write:(..Debug>1) !
							}
						}
					}
				}
			}	
		}

		Set o = $O(..ClassOrder(o),-1)
	}
	
	Quit duplicateRemoved
}

/// Correct names of any potential duplicate classes who were created with a name
/// containing a "/"
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method CorrectClassNames() [ Internal, Private ]
{
	//  Fix remaining class names
	Set root = $O(..ClassCount(""))
	While (root '= "") {
		Set count = ..ClassCount(root)
		Write:(..Debug>1) " ClassCount("_root_")="_count,!
		Set num = 0
		For i = 2:1:count {
			Set oldname = root _ "/" _ i
			Set cls = $G(..ClassIndex(oldname),"!!!") // !!!
			If ((cls '= "!!!") && $G($$$ClassTree(cls,"Removed")) '= 1) {
					Write:(..Debug>1) " fix class with /: "_$$$ClassTree(cls,"ClassName"),!
					Set num = num + 1
					Set newname = root _ num

					// test if new name is already used
					While ($D(..ClassIndex(newname))) {
						Set num = num + 1
						Set newname = root _ num
					}
					
					Set $$$ClassTree(cls,"ClassName") = newname
					Set ..ClassIndex(newname) = cls
					Kill ..ClassIndex(oldname)
			}
		}

		Set root = $O(..ClassCount(root))
	}
	
	Write:(..Debug>1) !
}

/// Test if the two classes are duplicate
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method AreClassesDuplicate(clsA As %Integer, clsB As %Integer) As %Boolean [ Internal, Private ]
{
	Set duplicate = 1

	Set pcountA = +$G($$$ClassTree(clsA,"PropCount"))
	Set pcountB = +$G($$$ClassTree(clsB,"PropCount"))
	If (pcountA '= pcountB) Quit 0
	
	If $get($$$ClassTree(clsA,"Super"))'=$get($$$ClassTree(clsB,"Super")) Quit 0
	If $get($$$ClassTree(clsA,"ClassType"))'=$get($$$ClassTree(clsB,"ClassType")) Quit 0
	If $get($$$ClassTree(clsA,"SOAPArrayType"))'=$get($$$ClassTree(clsB,"SOAPArrayType")) Quit 0
	If $get($$$ClassTree(clsA,"Description"))'=$get($$$ClassTree(clsB,"Description")) Quit 0
	If $data($$$ClassTree(clsA,"abstract"))'=$data($$$ClassTree(clsB,"abstract")) Quit 0
	If $data($$$ClassTree(clsA,"isc:classname"))'=$data($$$ClassTree(clsB,"isc:classname")) Quit 0
	If $get($$$ClassTree(clsA,"restriction"))'=$get($$$ClassTree(clsB,"restriction")) Quit 0
	
	Set nameA=$order($$$ClassTree(clsA,"Parameter",""))
	Set nameB=$order($$$ClassTree(clsB,"Parameter",""))
	While nameA'="" {
		If nameA'=nameB {
			Set duplicate = 0
			Quit
		}
		If $$$ClassTree(clsA,"Parameter",nameA)'=$$$ClassTree(clsB,"Parameter",nameB) {
			Set duplicate = 0
			Quit
		}
		Set nameA=$order($$$ClassTree(clsA,"Parameter",nameA))
		Set nameB=$order($$$ClassTree(clsB,"Parameter",nameB))
	}
	If 'duplicate Quit 0

	// test if all the properties are the same
	Set prop = $O($$$ClassTree(clsA,"Property",""))
	While duplicate && (prop '= "") {
		If ($get($$$ClassTree(clsA,"Property",prop,"Name"))'=$get($$$ClassTree(clsB,"Property",prop,"Name"))) {
			Set duplicate = 0
		}
		If ($get($$$ClassTree(clsA,"Property",prop,"Type"))'=$get($$$ClassTree(clsB,"Property",prop,"Type"))) {
			Set duplicate = 0
		}
		If ($get($$$ClassTree(clsA,"Property",prop,"Collection"))'=$get($$$ClassTree(clsB,"Property",prop,"Collection"))) {
			Set duplicate = 0
		}
		If ($get($$$ClassTree(clsA,"Property",prop,"Description"))'=$get($$$ClassTree(clsB,"Property",prop,"Description"))) {
			Set duplicate = 0
		}
		If ($get($$$ClassTree(clsA,"Property",prop,"Required"))'=$get($$$ClassTree(clsB,"Property",prop,"Required"))) {
			Set duplicate = 0
		}
		If ($get($$$ClassTree(clsA,"Property",prop,"InitialExpression"))'=$get($$$ClassTree(clsB,"Property",prop,"InitialExpression"))) {
			Set duplicate = 0
		}

		If ($get($$$ClassTree(clsA,"Property",prop,"ReadOnly"))'=$get($$$ClassTree(clsB,"Property",prop,"ReadOnly"))) {
			Set duplicate = 0
		}

		Set nameA=$order($$$ClassTree(clsA,"Property",prop,"Parameter",""))
		Set nameB=$order($$$ClassTree(clsB,"Property",prop,"Parameter",""))
		While nameA'="" {
			If nameA'=nameB {
				Set duplicate = 0
				Quit
			}
			If $$$ClassTree(clsA,"Property",prop,"Parameter",nameA)'=$$$ClassTree(clsB,"Property",prop,"Parameter",nameB) {
				Set duplicate = 0
				Quit
			}
			Set nameA=$order($$$ClassTree(clsA,"Property",prop,"Parameter",nameA))
			Set nameB=$order($$$ClassTree(clsB,"Property",prop,"Parameter",nameB))
		}

		Set prop = $O($$$ClassTree(clsA,"Property",prop))
	}		
	
	Quit duplicate
}

/// Process Microsoft .Net datasets
/// Compute Rowspec and remove classes.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessDatasets() [ Internal, Private ]
{
	Set nsindex=$order(..NSInfo(""))
	While nsindex'="" {
		Set dselement=$get(..NSInfo(nsindex,"msdata"))
		If dselement'="" {
			Write:(..Debug>1) "Reducing dataset: [",dselement,"] ",$get($$$ClassTree(dselement,"ClassName")),"(",+$get($$$ClassTree(dselement,"PropCount")),")",!
			Set dsprop = $order($$$ClassTree(dselement,"Property",""))
			If dsprop '= "" {
				Set type = $get($$$ClassTree(dselement,"Property",dsprop,"Type"))
				Set ds = $get(..TypeIndex(type))
				If ds '= "" {
			    	Write:(..Debug>1) "dataset table: [",ds,"] ",$get($$$ClassTree(ds,"ClassName")),"(",+$get($$$ClassTree(ds,"PropCount")),") type=",type,!
			    	Set rowspec=""
					Set prop = $order($$$ClassTree(ds,"Property",""))
					While prop '= "" {
						Set proptype=$get($$$ClassTree(ds,"Property",prop,"Type"))
						Set cls=..TypeToClass(proptype,.isdt)
						Set name=$get($$$ClassTree(ds,"Property",prop,"Parameter","XMLNAME"))
						If name="" Set name=$get($$$ClassTree(ds,"Property",prop,"Name"))
			    		Write:(..Debug>1) "dataset table field: name=",name,", type=",proptype,", cls=",cls,!
						If (cls'="") && isdt {
							Set rowspec=rowspec_name_":"_proptype_","
						}
						Set prop = $order($$$ClassTree(ds,"Property",prop))
					}
					Set $extract(rowspec,$length(rowspec))=""
					Set ..NSInfo(nsindex,"dataset")=
					  $listbuild($$$ClassTree(dselement,"Parameter","XMLNAME"),
					  $piece($$$ClassTree(ds,"Parameter","XMLNAME"),"/",1),
					  rowspec)
					Set $$$ClassTree(ds,"Removed") = 1
				} Else {
			    	Write:(..Debug>1) "dataset table missing for type=",type,!
				}
			}
			Set $$$ClassTree(dselement,"Removed") = 1
		}
		Set nsindex=$order(..NSInfo(nsindex))
	}
}

/// Remove any empty classes created for elements defined by type reference.
/// For use only by the SOAP wizard
Method RemoveTemporaryClasses() [ Internal ]
{
	Set cls=""
	For {
		Set cls=$order($$$ClassTree(cls))
		If cls="" Quit
		If ($get($$$ClassTree(cls,"Removed"))'=1) {
			If $get($$$ClassTree(cls,"temporary")) {
				Set $$$ClassTree(cls,"Removed")=1
				Write:(..Debug>1) "Temporary class removed=",cls,", name=",$get($$$ClassTree(cls,"ClassName")),!
				// Also remove super class if it has no remaining subclasses
				Set superName=$get($$$ClassTree(cls,"Super"))
				Set super=$select(superName="":"",1:$get(..TypeIndex(superName)))
				If $extract(superName)'="%",super'="",'$get($$$ClassTree(super,"Removed")),
				   $get($$$ClassTree(super,"wrapper")),'..HasSubClasses(super,1) {
						Set $$$ClassTree(super,"Removed")=1
						Write:(..Debug>1) "Temporary class super removed=",super,", name=",superName,!
				}
			}
		}
	}
}

/// Loop over class tree and try to simplify it.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ReduceClasses() [ Internal, Private ]
{
	// For dataset classes, generate rowspec and remove classes
	Do ..ProcessDatasets()
	
	// Remove duplicate classes
	Set num=1
	While ..RemoveDuplicateClasses() {
		Write:(..Debug>1) "Pass "_num_" of duplicate removal.",!
		Set num=num+1
	}
	Write:(..Debug>1) num_" passes of duplicate removal completed.",!

	// Fixup class names that were generated for inline complexTypes
	Do ..CorrectClassNames()
	
	// Remove UsedBy is the used by class is Removed
	Set i = $O(..ClassOrder(""),-1)
	While (i '= "") {
		Set cls = $O(..ClassOrder(i,""))
		If ($get($$$ClassTree(cls,"Removed"))'=1) {
			// Look at all UsedBy for this clas
			Set uc = $O($$$ClassTree(cls,"UsedBy",""))
			While (uc '= "") {
				Set up = $O($$$ClassTree(cls,"UsedBy",uc,""))
				While (up '= "") {
					If ($get($$$ClassTree(uc,"Removed"))=1) {
						Kill $$$ClassTree(cls,"UsedBy",uc,up)
						Write:(..Debug>1) "Removed UsedBy("_uc_","_up_") killed for cls",!
					}
					Set up = $O($$$ClassTree(cls,"UsedBy",uc,up))
				}
				Set uc = $O($$$ClassTree(cls,"UsedBy",uc))
			}
		}
		Set i = $O(..ClassOrder(i),-1)
	}

	// now reduce using simple rules
	Set i = $O(..ClassOrder(""),-1)
	While (i '= "") {
		Set key = $O(..ClassOrder(i,""))
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			Set src = $get($$$ClassTree(key,"src"))
			Set name = $get($$$ClassTree(key,"ClassName"))
			Set type = $get($$$ClassTree(key,"Super"))
			Set pcount = +$get($$$ClassTree(key,"PropCount"))

			// if super is non-%, then we are a subclass of a new class
			Set isSubClass = ($E(type,1) '= "%")
			
			// test if we are a special "SOAP" type
			Set isSOAPType = $E(type,1,5) = "$SOAP"
						
			Write:(..Debug>1) "Reducing: [",key,"] ",name,"(",pcount,") ",$select(src'="":..ElementSrc(src),1:""),!
			
			If (isSOAPType) {
				// a SOAP-encoded array: 
				// convert this to a subclass of %ListOfXXX
				// also fold it into referencing class
				Write:(..Debug>1) "SOAP array: [",key,"] ",type,!

				// get type "array" or "list"				
				Set ctype = $P(type,".",2)

				Set itemtype = $G($$$ClassTree(key,"SOAPArrayType"),"UndefinedSoapArrayType")
				Set itemkey=$get(..TypeIndex(itemtype))
				Set itemdesc = $get($$$ClassTree(key,"Description"))
		
				// check all users of this class
				Set usedby = $O($$$ClassTree(key,"UsedBy",""))
				While (usedby '= "") {
					Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
					While (prop '= "") {
						// set used by prop to a collection
						
						Write:(..Debug>1) "SOAP type used by: [",usedby,"] ",prop,!

						Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION") = "COLLECTION"
						Set $$$ClassTree(usedby,"Property",prop,"Collection") = ctype
						Set $$$ClassTree(usedby,"Property",prop,"Type") = itemtype
						Set propdesc=$get($$$ClassTree(usedby,"Property",prop,"Description"))
						If itemdesc'="" {
							If propdesc'="" Set propdesc=propdesc_$c(13,10)
							Set propdesc=propdesc_itemdesc
						}
						If itemtype'="" {
							Set propcls=$get(..TypeIndex(itemtype))
							If propcls'="" {
								Set description=$get($$$ClassTree(propcls,"Description"))
								If description'="" {
									If propdesc'="" Set propdesc=propdesc_$c(13,10)
									Set propdesc=propdesc_description
								}
							}
						}
						Set $$$ClassTree(usedby,"Property",prop,"Description")=propdesc
						if itemkey'="" {
							Set $$$ClassTree(itemkey,"UsedBy",usedby,prop)=""
						}
						
						Set prop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
					}
					Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
				}
				
				// Type no longer used
				Kill $$$ClassTree(key,"UsedBy")

				If (ctype = "list") {
					// convert this class to a subclass of a library collection..
					// correct super class filled in %XML.Utils.SchemaResult
					Set $$$ClassTree(key,"Super") = "%ListOf"
					Set $$$ClassTree(key,"Parameter","ELEMENTTYPE") = itemtype
					Set $$$ClassTree(key,"ClassType") = "serial"
					
					// remove properties of this class
					Kill $$$ClassTree(key,"Property")
				}
				Else {
					// remove ???
					Write:(..Debug>1) "Removing(d): ",$G($$$ClassTree(key,"ClassName")),!
					//Set $$$ClassTree(key,"Super")="%RegisteredObject" // !!!
					Set $$$ClassTree(key,"Removed") = 1
				}
			}
			ElseIf (pcount = 0) {
				Set usedby = $O($$$ClassTree(key,"UsedBy",""))
				If (usedby = "") {
					
					Set hasSubClass = ..HasSubClasses(key)
					
					// a class with no properties that is
					// not used by anyone is not useful!
					// unless it is a datatype or it has subclasses
					If (((name = "")&&($G($$$ClassTree(key,"Type"))="")) || '..KeepEmptyClasses) &&
					   'hasSubClass && ($G($$$ClassTree(key,"ClassType")) '= "datatype") {
						Write:(..Debug>1) "Removing(a): ",name,!
						Set $$$ClassTree(key,"Removed") = 1
					}
				}
			}
			ElseIf (pcount = 1) && 'isSubClass {
				// A class containing only a single, collection
				// property is most likely a wrapper class...
				
				// Or, a class with one non-collection property 
				// that is only used as a collection...
				
				// see if we are a wrapper...
				
				// get property of this class
				Set keyprop = $order($$$ClassTree(key,"Property",""))
				Set keytype = $get($$$ClassTree(key,"Property",keyprop,"Type"))
				Set keycollect = $get($$$ClassTree(key,"Property",keyprop,"Collection"),"list")
				Set keydesc = $get($$$ClassTree(key,"Description"))
				Set desc = $get($$$ClassTree(key,"Property",keyprop,"Description"))
				If desc'="" {
					If keydesc'="" Set keydesc=keydesc_$c(13,10)
					Set keydesc=keydesc_desc
				}

				If $get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")) = "ANY" {
					// Process subclasses of %XML.DataSet.
					// XML schema of form:
					//	<s:complexType name="....">
					//		<s:sequence>
					//			<s:any namespace="...."/>
					//		</s:sequence>
					//	</s:complexType>
					//	Becomes with subclass of %XML.DataSet with a Query defining the
					//	columns based on the dataset in the specified namespace.
					Set keynamespace = $G($$$ClassTree(key,"Property",keyprop,"namespace"))
					If keynamespace'="" {
						Set nsindex=$get(..NSIndex(keynamespace))
						If nsindex'="" {
							Set dataset=$get(..NSInfo(nsindex,"dataset"))
							If dataset'="" {
								Set $$$ClassTree(key,"dataset")=dataset
								Set $$$ClassTree(key,"Parameter","NAMESPACE")=keynamespace
								Set $$$ClassTree(key,"Super")="%XML.DataSet"
								Set $$$ClassTree(key,"ClassType")=""
								Set $$$ClassTree(key,"PropCount")=0
								Kill $$$ClassTree(key,"Property")
							}
						}
					}
				// ******* Case of just mixed content  Should remove only inline.
				//	Set usedby = $O($$$ClassTree(key,"UsedBy",""))
				//	While (usedby '= "") {
				//		Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
				//		While (prop '= "") {
				//			Set $$$ClassTree(usedby,"Property",prop,"Type") = keytype
				//			Set prop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
				//		}
				//		Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
				//	}
					
				//	// remove this class
				//	Write:(..Debug>1) "Removing(e): ",$G($$$ClassTree(key,"ClassName")),!
				//	Set $$$ClassTree(key,"Removed") = 1

				} ElseIf ($get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION"),"ELEMENT")="ELEMENT") &&
						 ($get($$$ClassTree(key,"Property",keyprop,"Collection")) = "") &&
						 ($get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLREF"))="") &&
						 ($get($$$ClassTree(key,"Property",keyprop,"Parameter","ELEMENTQUALIFIED"))="") {
					Set keyxmlname=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNAME"))
					If keyxmlname="" Set keyxmlname=$get($$$ClassTree(key,"Property",keyprop,"Name"))
					If keytype'="" {
						Set classname=..TypeToClass(keytype,.isdt,.xmlname)
					} Else {
						Set (classname,xmlname)=""
					}
					Write:(..Debug>1) "wrapped test:  type="_classname_", xmlname="_xmlname_" ,keyxmlname="_keyxmlname,!
					If xmlname = keyxmlname {
						// Wrapped element
						Set xmlnil=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNIL"))
						Set xmlnilnoobject=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNILNOOBJECT"))
	
						// check all users
						Set usedby = $O($$$ClassTree(key,"UsedBy",""))
						Set wrapper = (usedby '= "")
						While (usedby '= "") {
							Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
							While (prop '= "") {
								Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
								Write:(..Debug>1) "keyprop=",keyprop,",keytype=",keytype,",keycollect=",keycollect,",keyProjection=",$G($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")),",propcollect=",$G($$$ClassTree(usedby,"Property",prop,"Collection")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
								If ($G($$$ClassTree(usedby,"Property",prop,"Collection")) = "") &&
								   ($get($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION"),"ELEMENT")="ELEMENT") &&
								   ($get($$$ClassTree(key,"Parameter","NAMESPACE"))=$get($$$ClassTree(usedby,"Parameter","NAMESPACE"))) &&
								   '$get($$$ClassTree(usedby,"Property",prop,"Parameter","XMLNILNOOBJECT")) &&
								   '$get($$$ClassTree(usedby,"Property",prop,"Parameter","XMLNIL")) {
									// we're used by a non-collection in the same namespace
									Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION") = "WRAPPED"
									Set $$$ClassTree(usedby,"Property",prop,"Type") = keytype
									If keydesc'="" {
										Set desc=$get($$$ClassTree(usedby,"Property",prop,"Description"))
										If desc'="" Set desc=desc_$c(13,10)
										Set $$$ClassTree(usedby,"Property",prop,"Description")=desc_keydesc
									}
									If xmlnil {
									   Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLNIL")=1
									}
									If xmlnilnoobject {
									   Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLNILNOOBJECT")=1
									}
									Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
								} Else {
									Set wrapper = 0
								}
								Write:(..Debug>1) "Adjusting(b1): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
								Set prop=nextprop
							}
							Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
						}
						
						If wrapper {
							If ..HasSubClasses(key) {
								Write:(..Debug>1) "Wrapped with sub classes(b1): ",$G($$$ClassTree(key,"ClassName")),!
								Set $$$ClassTree(key,"wrapper")=1
							} Else {
								// remove this class
								Write:(..Debug>1) "Removing(b1): ",$G($$$ClassTree(key,"ClassName")),!
								Set $$$ClassTree(key,"Removed") = 1
							}
						}
					}

				} ElseIf ($get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION"))'="COLLECTION") &&
						 ($get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLREF"))="") &&
						 ($get($$$ClassTree(key,"Property",keyprop,"Parameter","ELEMENTQUALIFIED"))="") {
					Set tCollect = $get($$$ClassTree(key,"Property",keyprop,"Collection"))
					If ((tCollect = "list") || (tCollect = "array")) {
						// single, collection property
						Set xmlnil=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNIL"))
						Set xmlnilnoobject=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNILNOOBJECT"))

						Set keyxmlname=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNAME"))
						If keyxmlname="" Set keyxmlname=$get($$$ClassTree(key,"Property",keyprop,"Name"))
						If keytype'="" {
							Set classname=..TypeToClass(keytype,.isdt,.xmlname)
						} Else {
							Set (classname,xmlname)=""
						}
						Write:(..Debug>1) "wrapped collection test:  type="_classname_", xmlname="_xmlname_" ,keyxmlname="_keyxmlname,!
						
						// check all users
						Set usedby = $O($$$ClassTree(key,"UsedBy",""))
						Set wrapper = (usedby '= "")
						While (usedby '= "") {
							Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
							While (prop '= "") {
								Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
								Write:(..Debug>1) "keyprop=",keyprop,",keytype=",keytype,",keycollect=",keycollect,",keyProjection=",$G($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")),",propcollect=",$G($$$ClassTree(usedby,"Property",prop,"Collection")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
								If ($get($$$ClassTree(usedby,"Removed"))'=1) &&
								   ($get($$$ClassTree(usedby,"Property",prop,"Collection")) = "") &&
								   ($get($$$ClassTree(key,"Parameter","NAMESPACE"))=$get($$$ClassTree(usedby,"Parameter","NAMESPACE"))) &&
								   '$get($$$ClassTree(usedby,"Property",prop,"Parameter","XMLNILNOOBJECT")) &&
								   '$get($$$ClassTree(usedby,"Property",prop,"Parameter","XMLNIL")) {
									// we're used by a non-collection in the same namespace
									Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION") = "COLLECTION"
									Set xmlname=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNAME"))
									If xmlname="" Set xmlname=$get($$$ClassTree(key,"Property",keyprop,"Name"))
									Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLITEMNAME") = xmlname
									Set $$$ClassTree(usedby,"Property",prop,"Collection") = keycollect
									If xmlnil {
									   Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLNIL")=1
									If xmlnilnoobject {
									   Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLNILNOOBJECT")=1
									}
									}
									If keydesc'="" {
										Set desc=$get($$$ClassTree(usedby,"Property",prop,"Description"))
										If desc'="" Set desc=desc_$c(13,10)
										Set $$$ClassTree(usedby,"Property",prop,"Description")=desc_keydesc
									}
									Set $$$ClassTree(usedby,"Property",prop,"Type") = keytype
									Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
								} Else {
									Set wrapper = 0
								}
								Write:(..Debug>1) "Adjusting(b2): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
								Set prop=nextprop
							}
							Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
						}
						
						If wrapper {
							If ..HasSubClasses(key) {
								Write:(..Debug>1) "Wrapped with sub classes(b2): ",$G($$$ClassTree(key,"ClassName")),!
								Set $$$ClassTree(key,"wrapper")=1
							} Else {
								// remove this class
								Write:(..Debug>1) "Removing(b2): ",$G($$$ClassTree(key,"ClassName")),!
								Set $$$ClassTree(key,"Removed") = 1
							}
						}
					}
				}
			}
			ElseIf pcount >= 2 {
				// Look for %XML.DataSet
				// XML schema of form:
				//	<s:complexType>
				//		<s:sequence>
				//			<s:element ref="s:schema"/>
				//			<s:any/>
				//		</s:sequence>
				//     [<s:attribute      /> ...]
				//	</s:complexType>
				// Any attributes may be included and will be ignored.
				Do {
					// Collect all non-attribute properties since attributes will be ignored
					Set keyprop=""
					kill propArray
					For {
						Set keyprop = $order($$$ClassTree(key,"Property",keyprop))
						If keyprop = "" Quit
						If $get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" Continue
						Set propArray($i(propArray))=keyprop
					}
					
					// Check for 2 non-attribute properties
					If $get(propArray)'=2 Quit
					// Check for <s:element ref="s:schema"/>
					Set keyprop = propArray(1)
					Set keytype = $get($$$ClassTree(key,"Property",keyprop,"Type"))
					If $piece(keytype,"^",2)'="schema" Quit
					Set ns = $piece(keytype,"^",1)
					If ns="" Quit
					If '..IsXMLSchemaNS($get(..NSInfo(ns,"uri"))) Quit
					// Check for <s:any:/>
					Set keyprop = propArray(2)
					If $get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")) '= "ANY" Quit
					If $get($$$ClassTree(key,"Property",keyprop,"namespace")) '= "" Quit
					
					// Replace all references with %XML.DataSet
					Set usedby = $O($$$ClassTree(key,"UsedBy",""))
					While (usedby '= "") {
						Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
						While (prop '= "") {
							Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
							Write:(..Debug>1) "keyprop=",keyprop,",keytype=",keytype,",keyProjection=",$G($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
							Set $$$ClassTree(usedby,"Property",prop,"Type") = "%XML.DataSet"
							Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
							Write:(..Debug>1) "Adjusting(ds): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
							Set prop=nextprop
						}
						Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
					}
					
					// remove this class
					Write:(..Debug>1) "Removing(ds): ",$G($$$ClassTree(key,"ClassName")),!
					Set $$$ClassTree(key,"Removed") = 1
				} While (0)
			}
		}
		
		Set i = $O(..ClassOrder(i),-1)
	}
}

/// Loop over class tree and try to simplify pair classes for arrays.
Method ReducePairClasses() [ Internal, Private ]
{
	// Second pass of reduction to remove pair types
	Set i = $O(..ClassOrder(""),-1)
	While (i '= "") {
		Set key = $O(..ClassOrder(i,""))
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			Set src = $G($$$ClassTree(key,"src"))
			Set name = $G($$$ClassTree(key,"ClassName"))
			Set type = $G($$$ClassTree(key,"Super"))
			Set pcount = +$G($$$ClassTree(key,"PropCount"))

			// if super is non-%, then we are a subclass of a new class
			Set isSubClass = (type '= "") && ($E(type,1) '= "%")
			
			Write:(..Debug>1) "Pass 2 Reducing: [",key,"] ",name,"(",pcount,") ",$select(src'="":..ElementSrc(src),1:""),!
			
			If (pcount=2) && ($$$ClassTree(key,"Super") = "%ListOf") && 'isSubClass {
				// Look for PairOf... referenced by SOAP encoded list
				Set key1prop = $O($$$ClassTree(key,"Property",""))
				Set key1type = $G($$$ClassTree(key,"Property",keyprop,"Type"))
				Set key1collect = $G($$$ClassTree(key,"Property",keyprop,"Collection"))
				Set key1projection = $get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION"),"ELEMENT")
				Set key2prop = $O($$$ClassTree(key,"Property",key1prop))
				Set key2type = $G($$$ClassTree(key,"Property",key2prop,"Type"))
				Set key2collect = $G($$$ClassTree(key,"Property",key2prop,"Collection"))
				Set key2projection = $get($$$ClassTree(key,"Property",key2prop,"Parameter","XMLPROJECTION"),"ELEMENT")
				Set key2SubClass = (key2type '= "") && ($E(key2type,1) '= "%")

				If (key1projection="ELEMENT") && (key2projection="ELEMENT") &&
				   (key1collect="") && (key2collect="") && ..isString(key1type) && key2SubClass &&
				   ($get($$$ClassTree(key,"Property",key1prop,"Parameter","XMLREF"))="") &&
				   ($get($$$ClassTree(key,"Property",key2prop,"Parameter","XMLREF"))="") {
					// single %String property
					
					// check all users
					Set key1xmlname=$get($$$ClassTree(key,"Property",key1prop,"Parameter","XMLNAME"))
					If key1xmlname="" Set key1xmlname=$get($$$ClassTree(key,"Property",key1prop,"Name"))
					Set usedby = $O($$$ClassTree(key,"UsedBy",""))
					Set wrapper = (usedby '= "")
					While (usedby '= "") {
						Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
						While (prop '= "") {
							Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
							Write:(..Debug>1) "1-keyprop=",key1prop,",keytype=",key1type,",keycollect=",key1collect,",keyProjection=",$G($$$ClassTree(key,"Property",key1prop,"Parameter","XMLPROJECTION")),",propcollect=",$G($$$ClassTree(usedby,"Property",prop,"Collection")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
							If ($G($$$ClassTree(usedby,"Property",prop,"Collection")) = "list") &&
							   ($get($$$ClassTree(key,"Parameter","NAMESPACE"))=$get($$$ClassTree(usedby,"Parameter","NAMESPACE"))) {
								// we're used by a collection in the same namespace
								Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLKEYNAME") = key1xmlname
								Set $$$ClassTree(usedby,"Property",prop,"Collection") = "array"
								Set $$$ClassTree(usedby,"Property",prop,"Type") = key2type
								Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
							} Else {
								Set wrapper = 0
							}
							Write:(..Debug>1) "Adjusting(pb1): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
							Set prop=nextprop
						}
						Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
					}
					
					If wrapper {
						If ..HasSubClasses(key) {
							Write:(..Debug>1) "Wrapped with sub classes(pb1): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"wrapper")=1
						} Else {
							// remove this class
							Write:(..Debug>1) "Removing(pb1): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"Removed") = 1
						}
					}
				}
			} ElseIf (pcount=2) && 'isSubClass {
				// Look for PairOf... for literal type
				Set key1prop = $O($$$ClassTree(key,"Property",""))
				Set key1type = $G($$$ClassTree(key,"Property",key1prop,"Type"))
				Set key1collect = $G($$$ClassTree(key,"Property",key1prop,"Collection"))
				Set key1projection = $get($$$ClassTree(key,"Property",key1prop,"Parameter","XMLPROJECTION"),"ELEMENT")
				Set key2prop = $O($$$ClassTree(key,"Property",key1prop))
				Set key2type = $G($$$ClassTree(key,"Property",key2prop,"Type"))
				Set key2collect = $G($$$ClassTree(key,"Property",key2prop,"Collection"))
				Set key2projection = $get($$$ClassTree(key,"Property",key2prop,"Parameter","XMLPROJECTION"),"ELEMENT")

				If (key1projection="CONTENT") && (key2projection="ATTRIBUTE") &&
				   (key1collect="") && (key2collect="") && ..isString(key2type) &&
				   ($get($$$ClassTree(key,"Property",key1prop,"Parameter","XMLREF"))="") &&
				   ($get($$$ClassTree(key,"Property",key2prop,"Parameter","XMLREF"))="") {
					// single %String property
					
					// check all users
					Set key2xmlname=$get($$$ClassTree(key,"Property",key2prop,"Parameter","XMLNAME"))
					If key2xmlname="" Set key2xmlname=$get($$$ClassTree(key,"Property",key2prop,"Name"))
					Set usedby = $O($$$ClassTree(key,"UsedBy",""))
					Set wrapper = (usedby '= "")
					While (usedby '= "") {
						Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
						While (prop '= "") {
							Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
							Write:(..Debug>1) "2-keyprop=",key1prop,",keytype=",key1type,",",",propcollect=",$G($$$ClassTree(usedby,"Property",prop,"Collection")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
							If ($G($$$ClassTree(usedby,"Property",prop,"Collection")) = "list") &&
							   ($get($$$ClassTree(key,"Parameter","NAMESPACE"))=$get($$$ClassTree(usedby,"Parameter","NAMESPACE"))) {
								// we're used by a collection in the same namespace
								Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLKEYNAME") = key2xmlname
								Set $$$ClassTree(usedby,"Property",prop,"Collection") = "array"
								Set $$$ClassTree(usedby,"Property",prop,"Type") = key1type
								Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
							} Else {
								Set wrapper = 0
							}
							Write:(..Debug>1) "Adjusting(pb2): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
							Set prop=nextprop
						}
						Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
					}
					
					If wrapper {
						If ..HasSubClasses(key) {
							Write:(..Debug>1) "Wrapped with sub classes(pb2): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"wrapper")=1
						} Else {
							// remove this class
							Write:(..Debug>1) "Removing(pb2): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"Removed") = 1
						}
					}
				}
			} ElseIf (pcount=1) && isSubClass {
				// Look for PairOf... referenced by list
				Set keyprop = $O($$$ClassTree(key,"Property",""))
				Set keytype = $G($$$ClassTree(key,"Property",keyprop,"Type"))
				Set keycollect = $G($$$ClassTree(key,"Property",keyprop,"Collection"))
				Set keyprojection = $get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION"))
				Set keysuper= $get($$$ClassTree(key,"Super"))
				Set keySubClass = (keysuper '= "") && ($E(keysuper,1) '= "%")

				If (keyprojection="ATTRIBUTE") && (keycollect="") && ..isString(keytype) && keySubClass &&
				   ($get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLREF"))="") {
					// single %String property
					
					// check all users
					Set usedby = $O($$$ClassTree(key,"UsedBy",""))
					Set wrapper = (usedby '= "")
					While (usedby '= "") {
						Set prop = $O($$$ClassTree(key,"UsedBy",usedby,""))
						While (prop '= "") {
							Set nextprop = $O($$$ClassTree(key,"UsedBy",usedby,prop))
							Write:(..Debug>1) "3-keyprop=",keyprop,",keytype=",keytype,",keycollect=",keycollect,",keyProjection=",$G($$$ClassTree(key,"Property",keyprop,"Parameter","XMLPROJECTION")),",propcollect=",$G($$$ClassTree(usedby,"Property",prop,"Collection")),",propProjection=",$G($$$ClassTree(usedby,"Property",prop,"Parameter","XMLPROJECTION")),!
							If ($G($$$ClassTree(usedby,"Property",prop,"Collection")) = "list") &&
							   ($get($$$ClassTree(key,"Parameter","NAMESPACE"))=$get($$$ClassTree(usedby,"Parameter","NAMESPACE"))) {
								// we're used by a collection in the same namespace
								Set xmlname=$get($$$ClassTree(key,"Property",keyprop,"Parameter","XMLNAME"))
								If xmlname="" Set xmlname=$get($$$ClassTree(key,"Property",keyprop,"Name"))
								Set $$$ClassTree(usedby,"Property",prop,"Parameter","XMLKEYNAME") = xmlname
								Set $$$ClassTree(usedby,"Property",prop,"Collection") = "array"
								Set $$$ClassTree(usedby,"Property",prop,"Type") = keysuper
								Kill $$$ClassTree(key,"UsedBy",usedby,prop) // no longer used
							} Else {
								Set wrapper = 0
							}
							Write:(..Debug>1) "Adjusting(pb3): ",$G($$$ClassTree(key,"ClassName")),",usedby=",$G($$$ClassTree(usedby,"ClassName"))," property=",$G($$$ClassTree(usedby,"Property",prop,"Name")),!
							Set prop=nextprop
						}
						Set usedby = $O($$$ClassTree(key,"UsedBy",usedby))
					}
					
					If wrapper {
						If ..HasSubClasses(key) {
							Write:(..Debug>1) "Wrapped with sub classes(pb3): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"wrapper")=1
						} Else {
							// remove this class
							Write:(..Debug>1) "Removing(pb3): ",$G($$$ClassTree(key,"ClassName")),!
							Set $$$ClassTree(key,"Removed") = 1
						}
					}
				}
			}
		}
		
		Set i = $O(..ClassOrder(i),-1)
	}
}

/// Loop over potential classes:
/// Fix any class or member names that are too long...
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixClassNames(fixTemporary As %Boolean = 0) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1),$data($$$ClassTree(key,"temporary"))=fixTemporary {
			Set name = $get($$$ClassTree(key,"ClassName"))
			Set uname = $zcvt(name,"U")
			If uname'="",'$data(..namesUpper(uname)) {
				Set ..namesUpper(uname) = 0
			}
		}
		
		Set key = $order($$$ClassTree(key))
	}

	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1),$data($$$ClassTree(key,"temporary"))=fixTemporary {
			Set name = $get($$$ClassTree(key,"ClassName"))
			Do:(..Debug>3) ..TraceMsg("class name="_name)
			if name="" Do:(..Debug>1) ..TraceMsg("*****Empty class name")
			If (name'="") && ($get($$$ClassTree(key,"Removed"))'=1) {
	
				// see if name is unique without case sensitivity
				Set uname = $zcvt(name,"U") ;;w !,uname break
				If ..namesUpper(uname) {
					// not unique, make an alias
					// test if new name is already used
					Set num = 1
					While $data(..ClassIndex(name_num)) || $data(..namesUpper(uname_num)) {
						Set num = num + 1
					}
	
					Do:(..Debug>1) ..TraceMsg("FIX CASE name="_name_", new="_name_num)
					Set ..namesUpper(uname_num) = 1
					Set name = name _ num
					
					Do ..FixClassReferences(key, name)
				}
				Else {
					// Keep name unchanged
					Set ..namesUpper(uname) = 1
				}
			}
		}

		Set key = $O($$$ClassTree(key))
	}

	// keep list of names25 (first 25 chars of classname)
	// Upgrade to use longer lengths supplied by macros
	Set uniqueClassLen=$$$MAXCLASSIDLENGTH
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1),$data($$$ClassTree(key,"temporary"))=fixTemporary {
			Set name = $get($$$ClassTree(key,"ClassName"))
			If (name'="") && ($get($$$ClassTree(key,"Removed"))'=1) {
				Set pkg = $piece(name,".",1,$length(name,".")-1)
				Set pkg32=$extract(pkg,1,$$$MAXPACKAGEIDLENGTH)
				Set cls = $piece(name,".",$length(name,"."))
	
				// see if name is unique within $$$MAXCLASSIDLENGTH chars
				If $data(..names25(pkg32,$extract(cls,1,uniqueClassLen))) {
					// not unique, make an alias
					Set cls = $extract(cls,1,uniqueClassLen-3) _ $zcrc(cls,1,888)
					Do:(..Debug>3) ..TraceMsg("Test unique "_uniqueClassLen_" characters="_name_", pkg32="_pkg32, "new="_cls)
					Set ..names25(pkg32,$extract(cls,1,uniqueClassLen)) = ""
					
					If (pkg '= "") {
						Set cls = pkg_"."_cls
					}
					
					Do ..FixClassReferences(key,cls)
				}
				Else {
					// Keep name unchanged
					Set ..names25(pkg32,$extract(cls,1,uniqueClassLen)) = ""
				}
			}
		}

		Set key = $O($$$ClassTree(key))
	}

	// Need XMLTYPE for cases in which class name was modified for XML name and type
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1),$data($$$ClassTree(key,"temporary"))=fixTemporary {
			Set name = $get($$$ClassTree(key,"ClassName"))
			Set xmlname = $get($$$ClassTree(key,"Parameter","XMLNAME"))
			If (xmlname'="") && (name'="") && (xmlname'=$$$ClassShortName(name)) {
				Set $$$ClassTree(key,"Parameter","XMLTYPE") = xmlname
			}
		}
		
		Set key = $order($$$ClassTree(key))
	}
	
Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,"FixClassNames: " _ $ZE)
	Goto Exit
}

/// Fix references to a class
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixClassReferences(classKey As %Integer, newClassName As %String) [ Internal, Private ]
{
	// Set new class name
	Do:(..Debug>1) ..TraceMsg("FIX references name="_newClassName_", old="_$$$ClassTree(classKey,"ClassName"))
	Kill ..ClassIndex($$$ClassTree(classKey,"ClassName"))
	Set ..ClassIndex(newClassName) = classKey
	Set $$$ClassTree(classKey,"ClassName") = newClassName
}

/// Loop over potential classes:
/// Remove NAMESPACE parameter from classes 
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method RemoveClassNamespace() As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			Kill $$$ClassTree(key,"Parameter","NAMESPACE"),$$$ClassTree(key,"Parameter","ELEMENTQUALIFIED"),$$$ClassTree(key,"Parameter","ATTRIBUTEQUALIFIED")
		}
		Set key = $order($$$ClassTree(key))
	}
	
Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,"RemoveClassNamespace " _ $ZE)
	Goto Exit
}

/// Test if a class has any subclasses
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method HasSubClasses(cls As %Integer, tempTest As %Boolean = 0) As %Boolean [ Internal, Private ]
{
	Set sub = 0
	Set type = $G($$$ClassTree(cls,"Type"))
	If (type = "") {
		Quit 0
	}

	Set super=$get(..TypeIndex(type))
	Set key = $O($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Super")) = type) {
			If 'tempTest || ((key'="")&&'$get($$$ClassTree(key,"Removed"))) {
				Set sub = 1
				Quit
			}
		}

		Set key = $O($$$ClassTree(key))
	}

	Quit sub
}

/// Set class type: persistent, serial or registered
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method SetClassType(cls As %Integer) [ Internal ]
{
	If ..MakePersistent { 
		Set $$$ClassTree(cls,"ClassType") = "persistent"
		Set $$$ClassTree(cls,"Super") = "%Persistent"
	} ElseIf ..MakeSerial {
		Set $$$ClassTree(cls,"ClassType") = "serial"
		Set $$$ClassTree(cls,"Super") = "%SerialObject"
	} Else {
		Set $$$ClassTree(cls,"ClassType") = ""
		Set $$$ClassTree(cls,"Super") = "%RegisteredObject"
	}
}

/// Make property name different than the specified name
Method MakeNameUnique(cls As %Integer, prop As %Integer, ByRef name As %String, ByRef namesUpper)
{
	// Make an alias
	// test if new name is already used
	Set uname = $zcvt(name,"U")
	Set num = 1
	For {
		While $length(uname_num)>$$$MAXNAMELENGTH {
			Set $extract(uname,$length(uname))=""
			Set $extract(name,$length(uname))=""
			Set num=1
		}
		If '$data(namesUpper(uname_num)) Quit
		Set num=num+1
	}

	Do:(..Debug>1) ..TraceMsg("FIX CASE property name="_name_", new="_name_num)
	Kill namesUpper(uname)
	Set namesUpper(uname_num) = 1
	Set name = name _ num
	
	If $get($$$ClassTree(cls,"Property",prop,"Parameter","XMLNAME"))="" {
		Set $$$ClassTree(cls,"Property",prop,"Parameter","XMLNAME")=$$$ClassTree(cls,"Property",prop,"Name")
	}
	Set $$$ClassTree(cls,"Property",prop,"Name")=name
	Set $$$ClassTree(cls,"Property",prop,"Description") = 
		"ERROR: Duplicate Property name in Schema. " _ $get($$$ClassTree(cls,"Property",prop,"Description"))
}

/// Loop over classes for final fixups. 
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixupClasses() [ Internal, Private ]
{
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			If $get($$$ClassTree(key,"restriction"))'="" {
				// Copy attributes from base type for restriction
				Set description = $get($$$ClassTree(key,"Description"))
				If description'="" Set description = description _ $c(13,10)
				Set $$$ClassTree(key,"Description") = 
				  description _ "This class is a restriction of "_$$$ClassTree(key,"restriction")
				Kill attrs
				Set lastpno=$get($$$ClassTree(key,"Property"),0)
				Set pno = $order($$$ClassTree(key,"Property",""))
				While (pno '= "") {
					If $get($$$ClassTree(key,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
						Set name = $get($$$ClassTree(key,"Property",pno,"Name"))
						If name'="" Set attrs(name)=""
					}
					Set pno = $order($$$ClassTree(key,"Property",pno))
				}

				Set cls=key
				For {
					Set super=$$$ClassTree(cls,"Super")
					If (super="") || ($extract(super)="%") Quit
					Set cls=$get(..TypeIndex(super))
					If cls=""  Quit
					Set pno = $order($$$ClassTree(cls,"Property",""))
					While (pno '= "") {
						If $get($$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
							Set name = $get($$$ClassTree(cls,"Property",pno,"Name"))
							If '$data(attrs(name)) {
								Set attrs(name)=""
								Set lastpno=lastpno+1
								Set $$$ClassTree(key,"Property") = lastpno
								Merge $$$ClassTree(key,"Property",lastpno)=$$$ClassTree(cls,"Property",pno)
							}
						}
						Set pno = $order($$$ClassTree(cls,"Property",pno))
					}
				}
	
			} ElseIf $case($extract($get($$$ClassTree(key,"Super"))),"":0,"%":0,:1) {
				// Resolve name clash between attribute and element in class and the classes it extends.
				// This is an issue because an attribute and an element may have the same name in XML.
				//
				// Get list of attributes and elements in this class
				Kill attrs,elements,namesUpper
				Set pno = $order($$$ClassTree(key,"Property",""))
				While (pno '= "") {
					Set name = $get($$$ClassTree(key,"Property",pno,"Name"))
					If name'="" {
						Set uname=$zcvt(name,"U")
						Set namesUpper(uname)=""
						If $get($$$ClassTree(key,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
							Set attrs(uname)=$lb(pno,name)
						} Else {
							Set elements(uname)=$lb(pno,name)
						}
					}
					Set pno = $order($$$ClassTree(key,"Property",pno))
				}

				// Loop over all properties in super classes
				Set cls=key
				For {
					Set super=$$$ClassTree(cls,"Super")
					If (super="") || ($extract(super)="%") Quit
					Set cls=$get(..TypeIndex(super))
					If cls=""  Quit
					Set pno = $order($$$ClassTree(cls,"Property",""))
					While (pno '= "") {
						Set name = $get($$$ClassTree(cls,"Property",pno,"Name"))
						Set uname=$zcvt(name,"U")
						If name'="" {
							If $get($$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
								If $data(elements(uname)) {
									// element has the same name as an attribute in a super class
									Set basepno=$list(elements(uname),1)
									Set basename=$list(elements(uname),2)
									Do ..MakeNameUnique(key,basepno,.basename,.namesUpper)
									Set elements($zcvt(basename,"U"))=$lb(pno,basename)
									Kill elements(uname)
								}
							} Else {
								If $data(attrs(uname)) {
									// attribute has the same name as an element in a super class
									Set basepno=$list(attrs(uname),1)
									Set basename=$list(attrs(uname),2)
									Do ..MakeNameUnique(key,basepno,.basename,.namesUpper)
									Set attrs($zcvt(basename,"U"))=$lb(pno,basename)
									Kill attrs(uname)
								}
							}
						}
						Set pno = $order($$$ClassTree(cls,"Property",pno))
					}
				}

			} ElseIf $get($$$ClassTree(key,"simpleContent")) '= "" {
				// Handle the case of XMLPROJECTION = "CONTENT" by moving any attributes of
				// complexType to the referencing class
				Kill attrs
				Set lastpno=$$$ClassTree(key,"Property")
				Set pno = $order($$$ClassTree(key,"Property",""))
				While (pno '= "") {
					If $get($$$ClassTree(key,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
						Set name = $get($$$ClassTree(key,"Property",pno,"Name"))
						If name'="" Set attrs(name)=""
					}
					Set pno = $order($$$ClassTree(key,"Property",pno))
				}

				Set cls = key
				For {
					Set contentpno = $get($$$ClassTree(cls,"simpleContent"))
					If contentpno = "" Quit
					Set type = $get($$$ClassTree(cls,"Property",contentpno,"Type"))
					If (type="") || ($extract(type)="%") Quit
					Set cls=$get(..TypeIndex(type))
					If (cls="") || ($$$ClassTree(cls,"ClassType") = "datatype")  Quit
					Set pno = $order($$$ClassTree(cls,"Property",""))
					While (pno '= "") {
						If $get($$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE" {
							Set name = $get($$$ClassTree(cls,"Property",pno,"Name"))
							If '$data(attrs(name)) {
								Set attrs(name)=""
								Set lastpno=lastpno+1
								Set $$$ClassTree(key,"Property") = lastpno
								Merge $$$ClassTree(key,"Property",lastpno)=$$$ClassTree(cls,"Property",pno)
							}
						}
						Set pno = $order($$$ClassTree(cls,"Property",pno))
					}

				}
				// Fix type of content property
				Set $$$ClassTree(key,"Property",$$$ClassTree(key,"simpleContent"),"Type") = type
			}
		}

		Set key = $order($$$ClassTree(key))
	}

	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			// Remove super class information for restriction
			If $get($$$ClassTree(key,"restriction"))'="" {
				Do ..SetClassType(key)
				Kill $$$ClassTree(key,"restriction")
			}

			Set pno = $order($$$ClassTree(key,"Property",""))
			While (pno '= "") {
				If $get($$$ClassTree(key,"Property",pno,"prohibited")) {
					// Remove prohibited properties
					Kill $$$ClassTree(key,"Property",pno)
				} Else {
					If $get($$$ClassTree(key,"Property",pno,"Parameter","XMLPROJECTION")) [ "ATTRIBUTE",
							 $case($extract($get($$$ClassTree(key,"Property",pno,"Type"))),"":0,"%":0,:1) {
						// Force attribute to not be converted to binary stream
						Set cls=$get($$$ClassTree(key,"Property",pno,"Type"))
						For {
							Set cls=$get(..TypeIndex(cls))
							If cls=""  Quit
							Set super=$$$ClassTree(cls,"Super")
							If super["base64Binary",..TypeToClass(super)="%xsd.base64Binary" {
								Set $$$ClassTree(cls,"SuperAttribute")=1
								Quit
							}
							If (super="") || ($extract(super)="%") Quit
							Set cls=super
						}
					}

					Set type=$get($$$ClassTree(key,"Property",pno,"Type"))
					Set initialExpression=$get($$$ClassTree(key,"Property",pno,"InitialExpression"))
					Set minval=$get($$$ClassTree(key,"Property",pno,"Parameter","MINVAL"))
					Set xminval=$get($$$ClassTree(key,"Property",pno,"Parameter","XMINVAL"))
					Set maxval=$get($$$ClassTree(key,"Property",pno,"Parameter","MAXVAL"))
					Set xmaxval=$get($$$ClassTree(key,"Property",pno,"Parameter","XMAXVAL"))
					Set fractionDigits=$get($$$ClassTree(key,"Property",pno,"Parameter","XMLFractionDigits"),0)
					Set decimalPrecision = 0.1**fractionDigits
					If (initialExpression'="") || (minval'="") || (xminval'="") || (maxval'="") || (xmaxval'="") {
						Set cls=..GetSuperDatatype(type,.hasXSDToLogical)
						If cls'="",hasXSDToLogical {
							If initialExpression'="" {
								Set $$$ClassTree(key,"Property",pno,"InitialExpression")=
								  $classmethod(cls,"XSDToLogical",initialExpression)
							}
							If minval'="" {
								Set $$$ClassTree(key,"Property",pno,"Parameter","MINVAL")=
								  $classmethod(cls,"XSDToLogical",minval)
							} ElseIf xminval'="" {
								Set $$$ClassTree(key,"Property",pno,"Parameter","MINVAL")=
								  $classmethod(cls,"XSDToLogical",xminval)+decimalPrecision
								Kill $$$ClassTree(key,"Property",pno,"Parameter","XMINVAL")
								Set xminval=""
							}
							If maxval'="" {
								Set $$$ClassTree(key,"Property",pno,"Parameter","MAXVAL")=
								  $classmethod(cls,"XSDToLogical",maxval)
							} ElseIf xmaxval'="" {
								Set $$$ClassTree(key,"Property",pno,"Parameter","MAXVAL")=
								  $classmethod(cls,"XSDToLogical",xmaxval)-decimalPrecision
								Kill $$$ClassTree(key,"Property",pno,"Parameter","XMAXVAL")
								Set xmaxval=""
							}
						}
					}
					
					If (xminval'="") || (xmaxval'="") {
						If xminval'="" {
							Set $$$ClassTree(key,"Property",pno,"Parameter","MINVAL")=xminval+decimalPrecision
							Kill $$$ClassTree(key,"Property",pno,"Parameter","XMINVAL")
						}
						If xmaxval'="" {
							Set $$$ClassTree(key,"Property",pno,"Parameter","MAXVAL")=xmaxval-decimalPrecision
							Kill $$$ClassTree(key,"Property",pno,"Parameter","XMAXVAL")
						}
					}
				}

				// We need to add CLASSNAME=1 property parameter for serial classes which have a sub classe.
				If ..MakeSerial {
					Set baseType=$get($$$ClassTree(key,"Property",pno,"Type"))
					If baseType'="" {
						Set baseKey=$get(..TypeIndex(baseType))
						If baseKey'="",
						   $case($$$ClassTree(baseKey,"ClassType"),"":1,"serial":1,:0),
						   $order($$$ClassTree(baseKey,"SuperBy",""))'="" {

							Set $$$ClassTree(key,"Property",pno,"Parameter","CLASSNAME")=1
						}
					}
				}
			
				Set pno = $order($$$ClassTree(key,"Property",pno))
			}
			
			// look for any classes not used by anyone
			// if serial, convert to persistent.
			If (($order($$$ClassTree(key,"UsedBy","")) = "") && ($get($$$ClassTree(key,"ClassType")) = "serial"))  {
				If ($get($$$ClassTree(key,"Super")) = "%SerialObject") {
					Do ..SetClassType(key)
				}
			}

			// Consider two classes
			// Class APersist Extends %Persistent
			// {
			//	Property MySerial as ASerial;  // This is optional
			// }
			// Class ASerial Extends %SerialObject
			// {
			//  Parameter "VALIDIFNULL"=1;
			//  Property RequiredProperty as %String [ Required ];
			// }
			// For Serial Class ( ASerial) ( for example used in persistent integration messages ).
			// When ALL occurrences of property ( MySerial), using the serial class ( ASerial) as named type,
			// are optional, across ALL implementing classes derived from the schema.
			// Allow a persistent class ( APersist) to pass validation and save, 
			// when sub-properties ( RequiredProperty) on serial type ( ASerial) are not set.
			// Parameter "VALIDIFNULL" = Behaves as though an optional property  ( MySerial) was null for validation
			If ((..MakeSerial) && ($get($$$ClassTree(key,"Super"))="%SerialObject")) {
				// Loop over ALL classes looking for Property with THIS classname as type.
				Set vinCounterClass=""
				Set vinAnyRequired=0
				for {
					Quit:vinAnyRequired // Quit on first detected "Required" usage of the class type in property
					Set vinCounterClass=$Order($$$ClassTree(vinCounterClass))
					Quit:vinCounterClass=""
					Continue:vinCounterClass=key // Skip current class being analyzed
					Set vinCounterProperty=""
					for {
						Quit:vinAnyRequired  // Quit on first detected "Required" usage of the class type in property
						Set vinCounterProperty=$Order($$$ClassTree(vinCounterClass,"Property",vinCounterProperty))
						Quit:vinCounterProperty=""
						// Not considering subclasses. Allow override in subclass only.

						Set vinPropType=$G($$$ClassTree(vinCounterClass,"Property",vinCounterProperty,"Type"))
						Continue:vinPropType=""
						Set vinPropType=$get(..TypeIndex(vinPropType))  // "^^21" => "21"
						Continue:vinPropType'=key  // Property not of type interested in
						// "Required" property usage detected
						Set:+$G($$$ClassTree(vinCounterClass,"Property",vinCounterProperty,"Required")) vinAnyRequired=1
					}
				}
				// checking whether ANY have Required parameter enabled
				set:'vinAnyRequired $$$ClassTree(key,"Parameter","VALIDIFNULL")=1
			}
			
			// Remove XMLINCLUDEINGROUP parameter from classes that have a 
			// system class as their super class or are a datatype.
			// XMLINCLUDEINGROUP parameter is used to include inline classes in subclasses 
			// of the base class for choice lists.
			If $data($$$ClassTree(key,"Parameter","XMLINCLUDEINGROUP")) &&
			   ( ($extract($get($$$ClassTree(key,"Super"))) = "%") ||
				 ($$$ClassTree(key,"ClassType") = "datatype") ) {
				Kill $$$ClassTree(key,"Parameter","XMLINCLUDEINGROUP")
			}
		}

		Set key = $order($$$ClassTree(key))
	}
}

/// Determine ultimate super type of a datatype class
Method GetSuperDatatype(type As %String, Output hasXSDToLogical) As %String [ Internal ]
{
	Set subkey=""
	For {
		Set cls=$get(..TypeIndex(type))
		If cls=""  Quit
		Set type=$$$ClassTree(cls,"Super")
	}
	
	Set baseclass=..TypeToClass(type,.isdt)
	If isdt,$extract(baseclass,1)="%" {
		Set baseclass=$$$NormalizeClassname(baseclass)
		Set hasXSDToLogical=''$$$comMemberKeyGet(baseclass,$$$cCLASSmethod,"XSDToLogical",$$$cMETHrunnable)
	} Else {
		Set baseclass=""
		Set hasXSDToLogical=0
	}
	Quit baseclass
}

/// Walk the class tree and make sure that all properties are less 32 characters long.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FixPropertyNames() [ Internal, Private ]
{
	// loop over all classes
	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			kill namesUpper
			// loop over all properties
			Set prop = $order($$$ClassTree(key,"Property",""))
			While (prop '= "") {
				Set name = $get($$$ClassTree(key,"Property",prop,"Name"))
				If name'="" {
					If $length(name)>$$$MAXNAMELENGTH {
						Set name=$extract(name,1,$$$MAXNAMELENGTH-5)_$zcrc(name,5,999)
						If $get($$$ClassTree(key,"Property",prop,"Parameter","XMLNAME"))="" {
							Set $$$ClassTree(key,"Property",prop,"Parameter","XMLNAME")=$$$ClassTree(key,"Property",prop,"Name")
						}
						Set $$$ClassTree(key,"Property",prop,"Name")=name
					}
		
					Set uname = $zcvt(name,"U")
					Set namesUpper(uname) = 0
				}
	
				Set prop = $order($$$ClassTree(key,"Property",prop))
			}
		
			Set prop = $order($$$ClassTree(key,"Property",""))
			While (prop '= "") {
				Set name = $get($$$ClassTree(key,"Property",prop,"Name"))
				If name '= "" {
					// see if name is unique without case sensitivity
					Set uname = $zcvt(name,"U")
					If namesUpper(uname)  {
						// not unique, make an alias
						// test if new name is already used
						Set num = 1
						For {
							While $length(uname_num)>$$$MAXNAMELENGTH {
								Set $extract(uname,$length(uname))=""
								Set $extract(name,$length(uname))=""
								Set num=1
							}
							If '$data(namesUpper(uname_num)) Quit
							Set num=num+1
						}
		
						Do:(..Debug>1) ..TraceMsg("FIX CASE property name="_name_", new="_name_num)
						Set namesUpper(uname_num) = 1
						Set name = name _ num
						
						If $get($$$ClassTree(key,"Property",prop,"Parameter","XMLNAME"))="" {
							Set $$$ClassTree(key,"Property",prop,"Parameter","XMLNAME")=$$$ClassTree(key,"Property",prop,"Name")
						}
						Set $$$ClassTree(key,"Property",prop,"Name")=name
						Set $$$ClassTree(key,"Property",prop,"Description") = 
							"ERROR: Duplicate Property name in Schema. " _ $get($$$ClassTree(key,"Property",prop,"Description"))
					}
					Else {
						// Keep name unchanged
						Set namesUpper(uname) = 1
					}
				}
	
				Set prop = $order($$$ClassTree(key,"Property",prop))
			}
		}

		Set key = $order($$$ClassTree(key))
	}
}

/// Walk the class tree and change collections into
/// relationships where appropriate.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FindRelationships(parentChildRelationship As %Boolean, indexRelationship As %Boolean) [ Internal ]
{
	// Search for relationship candidates
	Set key = $O($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			// check for collection properties
			Set prop = $O($$$ClassTree(key,"Property",""))
			While (prop '= "") {
				Set type = $get($$$ClassTree(key,"Property",prop,"Type"))
				If ((type '= "") && $data(..TypeIndex(type))) {
					If ($get($$$ClassTree(key,"Property",prop,"Collection")) = "list") {
	
						// other (one) side
						Set cls = ..TypeIndex(type)
	
						If (..FindClassType(cls) = "persistent") {
						 	
						 	// figure out name of "one" side; check for dups
							// test for case insensitive duplicate prop names:
							// get list of existing props
							Kill proplist
							Do ..FindProperties(cls, .proplist)
							Set pname=""
							For {
								Set pname=$order(proplist(pname))
								If pname="" Quit
								Kill proplist(pname)
								Set proplist($zcvt(pname,"U"))=""
							}
	
							// use the short class name for the prop name
							Set n = 0						
							Set invname = $$$ClassTree(key,"ClassName")
							If invname["." Set invname = $piece(invname,".",$length(invname,"."))
							Set invname = ..MakePropName(invname)
							If $length(invname)>$$$MAXNAMELENGTH {
								Set invname=$extract(invname,1,$$$MAXNAMELENGTH-5)_$zcrc(invname,5,999)
							}
							Set invnameUpper=$zcvt(invname,"U")
							While $data(proplist(invnameUpper)) || $data(invlist(invnameUpper)) {
								// make a new name
								Set n = n + 1
								Set invname = $$$ClassTree(key,"ClassName") _ n
								If invname["." Set invname = $piece(invname,".",$length(invname,"."))
								Set invname = ..MakePropName(invname)
								If $length(invname)>$$$MAXNAMELENGTH {
									Set invname=$extract(invname,1,$$$MAXNAMELENGTH-5)_$zcrc(invname,5,999)
								}
								Set invnameUpper=$zcvt(invname,"U")
							}
							Set invlist(invnameUpper)=""
							
						 	// add "many" side of relationship
							Set $$$ClassTree(key,"Property",prop,"Relationship") = 1
							Set $$$ClassTree(key,"Property",prop,"Inverse") = invname
							Set $$$ClassTree(key,"Property",prop,"Cardinality") = $select(parentChildRelationship:"children",1:"many")
							Kill $$$ClassTree(key,"Property",prop,"Collection")
							Kill $$$ClassTree(key,"Property",prop,"Required")
							
							/// add property to other side of relationship
							Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
							Set pno = $$$ClassTree(cls,"Property")
							
							Set $$$ClassTree(cls,"Property",pno,"Name") = invname
							Set $$$ClassTree(cls,"Property",pno,"Type") = $$$ClassTree(key,"Type")
							Set $$$ClassTree(cls,"Property",pno,"Relationship") = 1
							Set $$$ClassTree(cls,"Property",pno,"Cardinality") = $select(parentChildRelationship:"parent",1:"one")
							Set $$$ClassTree(cls,"Property",pno,"Inverse") = $$$ClassTree(key,"Property",prop,"Name")
							Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "NONE"
							
							// add index if requested
							If 'parentChildRelationship,indexRelationship {
								Set $$$ClassTree(cls,"Index",pno,"Name") = invname_"Index"
								Set $$$ClassTree(cls,"Index",pno,"Property") = invname
							}
							
					 	}
					}
				}
	
				Set prop = $O($$$ClassTree(key,"Property",prop))
			}
		}
	
		Set key = $O($$$ClassTree(key))
	}
}

/// Get a list of all the properties for this class
/// and its super classes
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FindProperties(cls As %Integer, ByRef proplist, ByRef proporder, removeDuplicates As %Boolean = 0) [ Internal ]
{
	Set superlist=1
	Set superlist(1)=cls
	For {
		Set super = $get($$$ClassTree(cls,"Super"))
		Set cls=$select(super="":"",1:$get(..TypeIndex(super)))
		If cls="" Quit
		Set superlist($i(superlist))=cls
	}
	
	Set propnum=0
	For i=superlist:-1:1 {
		Set cls=superlist(i)
		Set pno = $order($$$ClassTree(cls,"Property",""))
		While (pno '= "") {
			Set propname = $get($$$ClassTree(cls,"Property",pno,"Name"))
			If propname '= "" {
				Set propnum=propnum+1
				If removeDuplicates,$get(proplist(propname))'="" {
					Kill proporder(proplist(propname))
				}
				Set proplist(propname) = propnum
				Set proporder(propnum) = $lb(cls,pno,propname)
			}
			Set pno = $order($$$ClassTree(cls,"Property",pno))
		}
	}
}

/// Mark classes with Compile After as required to have datatypes compile first.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FindCompileAfter() [ Internal, Private ]
{
	// Loop over classes and set the CompilerAfter flag
	// to work around compile order problems...

	Set key = $order($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed"))'=1) {
			// check for properties that are references to other generated classes
			Kill list
			Set prop = $O($$$ClassTree(key,"Property",""))
			While (prop '= "") {
				If $get($$$ClassTree(key,"Property",prop,"Relationship")) '= 1 {
					Set type = $get($$$ClassTree(key,"Property",prop,"Type"))
					// Only generate compileAfter for data type classes
					Set cls = $select(type="":"",1:$get(..TypeIndex(type)))
					Set classname = $select(cls="":"",1:$get($$$ClassTree(cls,"ClassName")))
					If (classname '= "") && ($extract(classname)'="%") &&
					   ($$$ClassTree(cls,"ClassType") = "datatype") {
						Set list(classname) = ""
					}
				}
				
				Set prop = $O($$$ClassTree(key,"Property",prop))
			}
			
			// now build CompileAfter list
			Set (sep,after) = ""
			Set classname = $order(list(""))
			While (classname '= "") {
				Set after = after _ sep _ classname
				Set sep = ","
				Set classname = $order(list(classname))
			}
			Set $$$ClassTree(key,"CompileAfter") = after
		}
	
		Set key = $order($$$ClassTree(key))
	}
}

/// Decorate the class tree
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method BuildClassInfo() [ Internal, Private ]
{
	Kill ..ClassIndex
	Kill ..ClassOrder
	
	// next slots in ClassOrder
	Set top = 0
	Set bottom = 0

	// build class index
	Set key = $O($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed")) '= 1) {
			Set name = $G($$$ClassTree(key,"ClassName"))
			
			If (name '= "") {
				Set ..ClassIndex(name) = key
				//Set ..ClassIndex($zcvt(name,"U"),"U")=key
			}
	
			// build work list for building ClassOrder
			Set work(key) = ""
		}

		Set key = $O($$$ClassTree(key))
	}

	// count properties, figure out usedBy
	
	Set key = $O($$$ClassTree(""))
	While (key '= "") {
		If ($get($$$ClassTree(key,"Removed")) '= 1) {
			Do:(..Debug>1) ..TraceMsg("ClassTree: "_$G($$$ClassTree(key,"ClassName")))
			// keep track of super class references
			Set type=$G($$$ClassTree(key,"Super"))
			If (type'="") && ($extract(type,1)'="%") {
				if $get(..TypeIndex(type))'="" {
					Set $$$ClassTree(..TypeIndex(type),"SuperBy",key) = ""
				} Else {
					Do:(..Debug>1) ..TraceMsg("Super references an unknown class: "_$G($$$ClassTree(key,"ClassName"))_" references "_type)
				}
			}
			
			// count properties & get list of usedBy
			Set pcount = 0
			Set prop = $O($$$ClassTree(key,"Property",""))
			While (prop '= "") {
				Set pcount = pcount + 1
	
				Set type = $get($$$ClassTree(key,"Property",prop,"Type"))
				
				If (type '= "") && ($get(..TypeIndex(type))'="") {
					// self-references don't count!
					If (..TypeIndex(type) '= key) {
						Set $$$ClassTree(..TypeIndex(type),"UsedBy",key,prop) = ""
						// temp flag removed in next step
						Set $$$ClassTree(..TypeIndex(type),"UsedByTemp",key) = ""
					}
				}
	
				Set prop = $O($$$ClassTree(key,"Property",prop))
			}
			
			Set $$$ClassTree(key,"PropCount") = pcount
		}
		Set key = $O($$$ClassTree(key))
	}
	
	// now use work array to build ClassOrder
	Set count = 100
	While ($D(work) && (count > 0))  {
		
		// add all items with no usedby to list
		Kill test
		Set key = $O(work(""))
		While (key '= "") {
			Set next = $O(work(key))
			If ('$D($$$ClassTree(key,"UsedByTemp")))||(count=1) {
				Kill work(key) // remove from work queue
				Set test(key) = ""
				Set top = top + 1
				Set ..ClassOrder(top,key) = ""
				Do:(..Debug>1) ..TraceMsg("ClassOrder: "_$G($$$ClassTree(key,"ClassName")))
			}
			Set key = next			
		}
		
		// now remove ref's to the items just removed
		Set key = $O(work(""))
		While (key '= "") {
			Set t = $O(test(""))
			While (t '= "") {
				If ($D($$$ClassTree(key,"UsedByTemp",t))) {
					Kill $$$ClassTree(key,"UsedByTemp",t)
				}
				Set t = $O(test(t))
			}
		
			Set key = $O(work(key))
		}
		
		Set count = count - 1
	}
}

/// Display classes to console
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ShowClasses() [ Internal ]
{
	// Use the SchemaResult class
	Set tResult = ##class(SchemaResult).CreateResult($this,"PACKAGE")
	Do tResult.DisplayClasses()
}

/// Make the class associated with an top element or type be a SOAP header.
/// This entry point is used by %SOAP.WSDL.Reader to build header classes.
/// 
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method MakeSOAPHeader(elementNamespace As %String, elementName As %String, isType As %Boolean, use As %String, ByRef parameterType As %String) As %Boolean [ Internal ]
{
	Set ok = 0
	Do {
		Set (parameterType,elno) = ""
		If elementNamespace = "" Quit
		If ..IsXMLSchemaNS(elementNamespace) Quit
		If $get(..NSIndex(elementNamespace)) = "" Quit
		
		If $get(isType) {
			If $$$ISERR(..GetCacheType(elementNamespace,elementName,.parameterType)) Quit
			Set elno = ..ClassIndex(parameterType)
		
		} Else {
			Set elno = $get(..Elements(..NSIndex(elementNamespace)_"^"_elementName))
			If elno = "" Quit
			
			If '..HasSubElements(elno) {
				Set cacheType = ..TypeToClass($get($$$ElTree(elno,"attrs","type")),.isdt)
				// For now, skip creating class for header element whose type is simpleType
				If isdt Quit
				If $get($$$ClassTree(elno,"ClassName"))="" {
					Set elno = $get(..ClassIndex(cacheType))
					If elno="" Quit
				}
			}
			Set parameterType = $get($$$ClassTree(elno,"ClassName"))
		}

		// If element class is temporary, then change to keep it
		If $get($$$ClassTree(elno,"temporary")) {
			Set $$$ClassTree(elno,"temporary")=0
		}
		
		If elementName="CSPCHD",elementNamespace="http://www.intersystems.com/SOAPheaders" {
			Do ..RemoveClassFromList(elno)
			Set ok=1
			Quit
		}
		
		Set super=$get($$$ClassTree(elno,"Super"))
		If super="%RegisteredObject" {
			Set $$$ClassTree(elno,"Super")="%SOAP.Header"
			Set ok=1
		} ElseIf (super="%SerialObject") || (super="%Persistent") {
			Set $$$ClassTree(elno,"Super")=$$$ClassTree(elno,"Super")_",%SOAP.Header"
			Set ok=1
		} ElseIf (super'="") && (super'["%SOAP.Header") {
			Set $$$ClassTree(elno,"Super")=$$$ClassTree(elno,"Super")_",%SOAP.Header"
			Set ok=1
		}
		If ok && (use'="") {
			Set $$$ClassTree(elno,"Parameter","XMLFORMAT") = use
		}
	} While (0)
	
	Quit ok
}

/// Get a top element in the form that may be used to build
/// an argument list in the form:
///     output(i) = &lt;Name&gt;
///     output(i,"type") = &lt;ObjectScript type&gt;
/// This entry point is used by %SOAP.WSDL.Reader to build document/literal methods.
/// 
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetElementProperties(elementNamespace As %String, elementName As %String, ByRef output, ByRef parameterType As %String, ByRef elno As %String, isType As %Boolean) As %Status [ Internal ]
{
	Set ok = 0
	Kill output
	Do {
		Set refnamespace=""
		Set (parameterType,elno) = ""
		If elementNamespace = "" Quit
		If ..IsXMLSchemaNS(elementNamespace) Quit
		If elementNamespace="""""" {
			Set nsindex=""
		} Else {
			Set nsindex=$get(..NSIndex(elementNamespace))
			If nsindex = "" Quit
		}
		
		If $get(isType) {
			If $$$ISERR(..GetCacheType(elementNamespace,elementName,.parameterType)) Quit
			Set elno = ..ClassIndex(parameterType)
			
		} Else {
			Set elno = $get(..Elements(nsindex_"^"_elementName))
			If elno = "" Quit
			
			If '..HasSubElements(elno) {
				Set cacheType = ..TypeToClass($get($$$ElTree(elno,"attrs","type")),.isdt)
				If isdt {
					Set output = 1
					Set output(1) = elementName
					Set output(1,"type")=cacheType
					Set output(1,"persistent")=0
					Set ok = 1
					Quit
				}
				Set elno = $get(..ClassIndex(cacheType))
				If elno="" Quit
				Set ns=$get($$$ClassTree(elno,"Parameter","NAMESPACE"))
				If ns'="",ns'=elementNamespace {
					Set refnamespace=ns
				}
			}
	
			Set parameterType = $get($$$ClassTree(elno,"ClassName"))
		}

		Set output = 0
		Kill proplist
		Do ..FindProperties(elno,,.proplist)
		Set pindex=""
		For {
			Set pindex=$order(proplist(pindex))
			If pindex="" Quit
			
			Set prop=proplist(pindex)
			Set pcls=$list(prop,1)
			Set pno=$list(prop,2)
			Set pname=$list(prop,3)

			If $get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLPROJECTION"))="NONE" Continue

			Set output = output + 1
			Set output(output) = pname
			Set type = $$$ClassTree(pcls,"Property",pno,"Type")
			Set cacheType = ..TypeToClass(type,.isdt)
			/// test for collection
			Set parms=""
			Set isList=($get($$$ClassTree(pcls,"Property",pno,"Collection")) = "list")
			Set isArray=($get($$$ClassTree(pcls,"Property",pno,"Collection")) = "array")
			If isList || isArray {
				Set parms="ELEMENTTYPE="""_cacheType_""""
				If isList {
					Set cacheType=$select(isdt:"%ListOfDataTypes",1:"%ListOfObjects")
				} Else {
					Set cacheType=$select(isdt:"%ArrayOfDataTypes",1:"%ArrayOfObjects")
				}
				If $get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLPROJECTION"))="" {
					Set parms=parms_",XMLPROJECTION=""element"""
				}
				If $get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLNAME"))="" {
					Set $$$ClassTree(pcls,"Property",pno,"Parameter","XMLNAME")=output(output)
				}
			}
			If $get($$$ClassTree(pcls,"Property",pno,"Parameter","REFNAMESPACE"))="" {
				If $case($get($$$ClassTree(pcls,"Property",pno,"ELEMENTNAMESPACE")),"":0,elementNamespace:0,:1) {
					If parms'="" Set parms=parms_","
					Set parms=parms_"XMLREF=1,REFNAMESPACE="""_$$$ClassTree(pcls,"Property",pno,"ELEMENTNAMESPACE")_""""
				} ElseIf refnamespace'="" {
					If parms'="" Set parms=parms_","
					Set parms=parms_"XMLREF=1,REFNAMESPACE="""_refnamespace_""""
				}
			}
			// merge in other parms
			Set pm=""
			For {
				Set pm = $O($$$ClassTree(pcls,"Property",pno,"Parameter",pm))
				If pm="" Quit
				Set pvalue=$$$ClassTree(pcls,"Property",pno,"Parameter",pm)
				If (pm="XMLNAME") && (pvalue=output(output)) && 
				   ($get($$$ClassTree(pcls,"Property",pno,"Parameter","ELEMENTTYPE"))'="") {
					Continue
				}
				If (pm="XMLPROJECTION") {
					Set pvalue=$zcvt(pvalue,"L")
					If isList && (pvalue="collection") Continue
					If 'isList && (pvalue="element") Continue
				}
				If parms'="" Set parms=parms_","
	  			If pvalue'=+pvalue {
		  			Set a=""
		  			For i=1:1:$length(pvalue,"""") {
			  			s a=a_""""_$piece(pvalue,"""",i)_"""" 
			  		}
			  		Set pvalue=a
	  			}
				Set parms=parms_pm_"="_pvalue
			}
			Set output(output,"type")=cacheType_$select(parms'="":"("_parms_")",1:"")
			Set index=$get(..TypeIndex(type))
			Set output(output,"persistent")=$select(index="":0,1:..FindClassType(index)="persistent")
			If $get($$$ClassTree(pcls,"Property",pno,"Required")) {
				Set output(output,"required")=1
			}
		}

		Set ok = 1
	} While (0)
	
	Quit $select(ok:$$$OK,1:$$$ERROR($$$SOAPTSchemaCorrelationError,elementName,elementNamespace))
}

/// Add a new class entry to the Class<BR>
/// <var>target</var> is optional target namespace (if not default).
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method AddNewClass(elno As %Integer, name As %String, type As %String, ByRef uri As %String, target As %String = "") As %Boolean [ Internal, Private ]
{
	// check if we have already made a class for this element
	If ($D($$$ClassTree(elno,"ClassName"))) {
		Do:(..Debug>1) ..TraceMsg("NEW CLASS: class already defined",elno)
		Quit 0
	}
	
	// resolve NS Info
	
	Set pkg = ""
	If (name [ "^") {
		Set nsno = $P(name,"^",1)
		Set name = $P(name,"^",2)
		
		// if there is no nsno, then this is an unqualified name
		// from a schema with no target NS
		
		If (nsno = "") {
			// use default for unqualified name
			Set pkg = ..DefaultPackage
			Set uri=""
		}
		Else {
			Set pkg = $get(..NSInfo(nsno,"Package"))
			Set uri = $get(..NSInfo(nsno,"uri"))
		}
		
		If ..ClassPrefix'="",(nsno="") || '$get(..NSInfo(nsno,"NoClassPrefix")) {
			Set pkg=..ClassPrefix_##class(%SOAP.WebBase).NormalizeName($select(pkg'="":".",1:"")_pkg,$$$MAXPACKAGEIDLENGTH)
		}
	}
	Else {
		If (target = 1) {
			Set pkg = ..CurrentPackage
			Set uri = ..CurrentNamespace
		}
		Else {
			Set pkg = ..ClassPrefix
			Set uri = ..TargetNS
		}
	}
	
	// !!! test for no package
	If (pkg = "") Set pkg = "Default"

	Set cls = ..MakeClassName(name)
	Set:pkg'="" cls = pkg _ "." _ cls
	//Set:..ClassPrefix'="" cls=..ClassPrefix _ "." _ cls
	
	// is name already in Class Counter index?
	If ($D(..ClassCount(cls))) {
		Set ..ClassCount(cls) = ..ClassCount(cls) + 1
		// use a fake class name until we reduce later...
		// fake class name is "name/#"
		Set cls = cls _ "/" _ ..ClassCount(cls)
	}
	Else {
		Set ..ClassCount(cls) = 1
	}
	
	Set $$$ClassTree(elno,"ClassName") = cls
	
	If type="" Set type = "^^"_elno
	Set $$$ClassTree(elno,"Type") = type
	Set ..TypeIndex(type) = elno
	
	// remember orginal name as XMLNAME parameter
	Set $$$ClassTree(elno,"Parameter","XMLNAME") = name
	
	// If needed set the NAMESPACE parameter.
	Set $$$ClassTree(elno,"Parameter","NAMESPACE")=uri
	If uri'="",uri'="""""" {
		Set num=$get(..NSIndex(uri))
		If num'="" {
			Set eq=$get(..NSInfo(num,"ElementQualified"))
			If eq'="" Set $$$ClassTree(elno,"Parameter","ELEMENTQUALIFIED")=eq
			Set aq=$get(..NSInfo(num,"AttributeQualified"))
			If aq Set $$$ClassTree(elno,"Parameter","ATTRIBUTEQUALIFIED")=''aq
		}
	} Else {
		Set eq=..NoNamespaceElementQualified
		If eq'="" Set $$$ClassTree(elno,"Parameter","ELEMENTQUALIFIED")=eq
		Set aq=..NoNamespaceAttributeQualified
		If aq Set $$$ClassTree(elno,"Parameter","ATTRIBUTEQUALIFIED")=''aq
	}
	
	Do:(..Debug>1) ..TraceMsg("NEW CLASS: [" _ cls_ "] (" _ pkg _ ", " _ name _ ", " _ type _ ", " _ ..CurrentPackage _ ", " _ uri _ ")",elno)
	
	Quit 1
}

/// Convert a schema name to a valid class name
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method MakeClassName(name As %String) [ Internal, Private ]
{
	Set name = $TR(name,"_-","")
	
	If (name = "Status") {
		// !!!
		Set name = "XStatus"
	}
	
	// Any part of the name which is just numeric gets a leading X
 	For i=1:1:$length(name,".") {
	 	Set part=$piece(name,".",i)
	 	If $extract(part,1)?1N Set $piece(name,".",i)="X"_part
	}

	// Remove leading dots.
	While $extract(name,1)="." {
		Set $extract(name,1)=""
	}
	
	// Remove trailing dots
	While $extract(name,*)="." {
		Set name=$extract(name,1,*-1)
	}
	
	// Convert multiple consecutive dots to a single dot
	For {
		Set ddpos=$find(name,"..")
		If ddpos=0 Quit
		Set $extract(name,ddpos-1)=""
	}
	
	Quit name
}

/// Convert a schema name to a valid property name
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod MakePropName(name As %String, ByRef xmlname) [ Internal ]
{
	// remove NS Info
	Set:name["^" name=$P(name,"^",2)
	Set leadingPercent=($extract(name,1)="_")
	Set cacheName=$TR(name,"_.-","")
	If $extract(cacheName,1)?1N {
		Set cacheName="X"_cacheName
	} ElseIf leadingPercent {
		Set cacheName="%"_cacheName
	}
	Set xmlname=$select(name'=cacheName:name,1:"")
	Quit cacheName
}

/// Find the class type (persistent, etc.) for 
/// class with key <var>key</var>.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method FindClassType(key As %Integer, ByRef visits As %String) As %String [ Internal ]
{
	If ($get($$$ClassTree(key,"ClassType")) '= "") {
		Quit $$$ClassTree(key,"ClassType")
	}
	ElseIf ($get($$$ClassTree(key,"Super")) '= "") {
		Set super = $$$ClassTree(key,"Super")
		Set skey = $get(..TypeIndex(super))
		If (skey '= "") {
			If ('$data(visits(skey))) {
				Set visits(skey) = ""
				Quit ..FindClassType(skey,.visits)
			}
			Else {
				Do ..TraceMsg("LOOP encountered IN FindClassType: " _ $G($$$ClassTree(key,"ClassName")),key)
				Quit ""
			}
		}
	}

	Quit ""
}

/// Convert an XML type to a class name
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method TypeToClass(itype As %String, ByRef isdt As %Boolean, ByRef xmlname) As %String [ Internal ]
{
	If ($O(..NSInfo("")) = "") {
		Write "TypeToClass: No NS Info!",!
	}

	// if this is already a class name, return it and assume datatype class
	Set isdt = 1
	If (itype '[ "^") {
		Set xmlname=$$$ClassShortName(itype)
		Quit itype
	}
	
	// If type we've seen, return it.
	Set key=$get(..TypeIndex(itype))
	If key'="" {
		Set isdt = ( $get($$$ClassTree(key,"ClassType")) = "datatype" )
		Set xmlname = $get($$$ClassTree(key,"Parameter","XMLNAME"))
		If xmlname="" Set xmlname=$$$ClassShortName(itype)
		Quit $get($$$ClassTree(key,"ClassName"))
	}

	// find the namespace for this type
	Set nsno = $P(itype,"^",1)
	Set type = $P(itype,"^",2)
	Set uri = "",pkg = ""
	
	If (nsno = "") {
		// unqualifed name
		Set pkg = ..DefaultPackage
	}
	Else {
		Set uri = $G(..NSInfo(nsno,"uri"))
		Set pkg = $G(..NSInfo(nsno,"Package"))
		If pkg = "$defaultNS" Set pkg = ""
	}
	
	If (type = "") {
		Set isdt = 0
		Set xmlname="Unknown"
		Quit "Unknown"
	}

	If (..IsXMLSchemaNS(uri)) {
		Set x = ..XSTypeToClass(type)
		Set xmlname=type
		Quit x
	}
	
	Set isdt = 0
	
	Set cls = ..MakeClassName(type)

	// add package name from URI
	Set:pkg'="" cls = pkg _ "." _ cls
	If ..ClassPrefix'="",(nsno="") || '$get(..NSInfo(nsno,"NoClassPrefix")) {
		Set cls=..ClassPrefix _ "." _ cls
	}
	
	Set xmlname=$$$ClassShortName(cls)
	Quit cls
}

/// Test if this is type xsd:anyType
Method isAnyType(type As %String) As %Boolean [ Internal, Private ]
{
	If $piece(type,"^",2)'="anyType" Quit 0
	Set ns = $piece(type,"^",1)
	If ns="" Quit 0
	Quit ..IsXMLSchemaNS($get(..NSInfo(ns,"uri")))
}

/// Test if this is type %String
Method isString(type As %String) As %Boolean [ Internal, Private ]
{
	If $piece(type,"^",2)'="string" Quit 0
	Set ns = $piece(type,"^",1)
	If ns="" Quit 0
	Quit ..IsXMLSchemaNS($get(..NSInfo(ns,"uri")))
}

/// Test if this uri is the XML Schema uri
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsXMLSchemaNS(uri As %String) As %Boolean [ Internal ]
{
	Quit (((uri [ "www.w3.org") && (uri [ "XMLSchema")) || (uri [ "//schemas.xmlsoap.org/soap/encoding/"))
}

/// Convert an XSD datatype to an ObjectScript type.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod XSTypeToClass(type As %String) As %String [ Internal, Private ]
{
	If (type = "string") {
		Quit "%String"
	}
	ElseIf (type = "language") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "normalizedString") {
		Quit "%String"
	}
	ElseIf (type = "token") {
		Quit "%String"
	}
	ElseIf (type = "boolean") {
		Quit "%Boolean"
	}
	ElseIf (type = "anyURI") {
		Quit "%xsd.anyURI"  //!!!
	}
	ElseIf (type = "ID") {
		Quit "%String"  //!!!
	}
	ElseIf (type = "NMTOKEN") {
		Quit "%String"  //!!!
	}
	ElseIf (type = "NMTOKENS") {
		Quit "%String"  //!!!
	}
	ElseIf (type = "float") {
		Quit "%xsd.float"
	}
	ElseIf (type = "double") {
		Quit "%xsd.double"
	}
	ElseIf (type = "decimal") {
		Quit "%Numeric" // ?
	}
	ElseIf (type = "integer") {
		Quit "%Integer"
	}
	ElseIf (type = "nonPositiveInteger") {
		Quit "%xsd.nonPositiveInteger"
	}
	ElseIf (type = "negativeInteger") {
		Quit "%xsd.negativeInteger"
	}
	ElseIf (type = "long") {
		Quit "%Integer"
	}
	ElseIf (type = "int") {
		Quit "%xsd.int"
	}
	ElseIf (type = "short") {
		Quit "%xsd.short"
	}
	ElseIf (type = "byte") {
		Quit "%xsd.byte"
	}
	ElseIf (type = "nonNegativeInteger") {
		Quit "%xsd.nonNegativeInteger"
	}
	ElseIf (type = "unsignedLong") {
		Quit "%xsd.unsignedLong"
	}
	ElseIf (type = "unsignedInt") {
		Quit "%xsd.unsignedInt"
	}
	ElseIf (type = "unsignedShort") {
		Quit "%xsd.unsignedShort"
	}
	ElseIf (type = "unsignedByte") {
		Quit "%xsd.unsignedByte"
	}
	ElseIf (type = "positiveInteger") {
		Quit "%xsd.positiveInteger"
	}
	ElseIf (type = "date") {
		Quit "%Date"
	}
	ElseIf (type = "time") {
		Quit "%Time"
	}
	ElseIf (type = "gMonth") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "gYear") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "gYearMonth") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "gMonthDay") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "gDay") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "duration") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "dateTime") {
		// !!!
		Quit "%TimeStamp"
	}
	ElseIf (type = "timeInstant") {
		// e.g., 1998-08-15T03:59.000-05:00
		// !!!
		Quit "%TimeStamp"
	}
	ElseIf (type = "base64Binary") {
		// this gets converted to a stream property further down the line
		Quit "%xsd.base64Binary"
	}
	ElseIf (type = "hexBinary") {
		// !!!
		Quit "%xsd.hexBinary"
	}
	ElseIf (type = "anyType") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "anySimpleType") {
		Quit "%String"
	}
	ElseIf (type = "IDREF") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "IDREFS") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "ENTITY") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "ENTITIES") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "Name") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "NCName") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "QName") {
		// !!!
		Quit "%String"
	}
	ElseIf (type = "NOTATION") {
		// !!!
		Quit "%String"
	}
	
	Quit type // !!! unknown type
}

/// Loop over top level of schema
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessTree() [ Internal, Private ]
{
	Kill ..Visits
	
	// loop over children of root node
	Set elno = $O($$$ElTree(0,"ch",""))
	While (elno '= "") {
		Do ..ProcessTopElement(elno)
		Set elno = $O($$$ElTree(0,"ch",elno))
	}
}

/// Check for cycles in schema
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method CycleCheck(elno As %Integer, msg As %String = "") [ Internal, Private ]
{
	// loop prevention
	If ($G(..Visits(elno)) > 0) {
		Do ..TraceMsg("Too many visits "_msg,elno)
		Quit 0
	}
	Set ..Visits(elno) = $G(..Visits(elno)) + 1
	Quit 1
}

/// Process topmost elements (children of schema)
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessTopElement(elno As %Integer) [ Internal, Private ]
{
	If ((..Debug>0) && $IsObject($G(%response))) {
		Write "<DIV CLASS=""feedback"">",$G($$$ElTree(elno,"local")),"&nbspl",$P($G($$$ElTree(elno,"attrs","name")),"^",2),"</DIV>",!
		Do %response.Flush()
	}

	
	Do:(..Debug>1) ..Trace("TopElement",elno)

	// we only need to test for cycles within each 
	// top level element
	
	// Reset Cycle test
	Kill ..Visits
	
	Set local = $G($$$ElTree(elno,"local"))
	Set src = $G($$$ElTree(elno,"src"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set type = $G($$$ElTree(elno,"attrs","type"))
	Set abstract = ($get($$$ElTree(elno,"attrs","abstract"))="true")
	
	Set (..CurrentPackage,..CurrentNamespace) = ""	

	If (local = "complexType") {
		// check if we have already made a class for this
		If ('$D($$$ClassTree(elno,"ClassName"))) {
		
			// Define an inline class
			Set mixed = ($G($$$ElTree(elno,"attrs","mixed")) = "true")
			
			If (..AddNewClass(elno,name,name,.namespace)) {
				// remember our package for any sub-elements
				Set ..CurrentPackage = ..getPackage($$$ClassTree(elno,"ClassName"))
				Set ..CurrentNamespace = namespace
		
				Set $$$ClassTree(elno,"src") = src
				Set $$$ClassTree(elno,"Parameter","XMLSEQUENCE") = 1
				If abstract Set $$$ClassTree(elno,"abstract") = ""
				
				If $data($$$ElTree(elno,"attrs","isc:classname")) {
					Set $$$ClassTree(elno,"Parameter","SOAPCLASSNAME")=$$$ElTree(elno,"attrs","isc:classname")
				}

				Do ..SetClassType(elno)
				
				If mixed {
					Set $$$ClassTree(elno,"Property") = $G($$$ClassTree(elno,"Property")) + 1
					Set pno = $$$ClassTree(elno,"Property")
			
					Set $$$ClassTree(elno,"Property",pno,"Name") = "content"
					Set $$$ClassTree(elno,"Property",pno,"Type") = "%XML.String"
					Set $$$ClassTree(elno,"Property",pno,"Parameter","XMLPROJECTION") = "CONTENT"
				}
				// loop over children of this node
				Set ch = $order($$$ElTree(elno,"ch",""))
				While (ch '= "") {
					Do ..ProcessElement(ch,elno,,mixed)
					Set ch = $order($$$ElTree(elno,"ch",ch))
				}
			}
		}
	}
	ElseIf (local = "simpleType") {
		// check if we have already made a class for this
		If ('$D($$$ClassTree(elno,"ClassName"))) {

			// Add test for class already defined
			If (..AddNewClass(elno,name,name,.namespace)) {
				Set $$$ClassTree(elno,"src") = src
		
				Set $$$ClassTree(elno,"Super") = "%String"
				Set $$$ClassTree(elno,"ClassType") = "datatype"
				// Do not specify XMLNAME for datatype class since this will be
				// made into a property parameter by the class compiler.
				Kill $$$ClassTree(elno,"Parameter","XMLNAME")
				
				// remember our package for any sub-elements
				Set ..CurrentPackage = ..getPackage($$$ClassTree(elno,"ClassName"))
				Set ..CurrentNamespace = namespace
	
				// loop over children of this node
				Set ch = $O($$$ElTree(elno,"ch",""))
				While (ch '= "") {
					Do ..ProcessSimpleType(ch,elno)
					Set ch = $O($$$ElTree(elno,"ch",ch))
				}
			}
		}
	}
	ElseIf (local = "element") {
		
		// check if we have already made a class for this
		//If '$data($$$ClassTree(elno,"ClassName")) && '$data(..Elements(name)) {
		If '$data($$$ClassTree(elno,"ClassName")) {
			
			// Save index of top level elements
			If '$data(..Elements(name)) Set ..Elements(name) = elno
			
			// Save namespace of top level elements for use in resolving ref's
			If (name [ "^") {
				Set nsno = $P(name,"^",1)
				Set namespace = $select(nsno="":"",1:$get(..NSInfo(nsno,"uri")))
				Set name2=$piece(name,"^",2)
			} Else {
				Set namespace = ..TargetNS
				Set name2=name
			}
			If ..HasSubElements(elno) {
				// make this a class if there are sub elements !!!
				If (..AddNewClass(elno,name,"",.namespace)) {
					Do ..SetClassType(elno)
					If abstract Set $$$ClassTree(elno,"abstract") = ""

					// remember our package for any sub-elements
					Set ..CurrentPackage = ..getPackage($$$ClassTree(elno,"ClassName"))
					Set ..CurrentNamespace = namespace
	
					Set $$$ClassTree(elno,"Parameter","XMLSEQUENCE") = 1
					Set $$$ClassTree(elno,"Parameter","XMLINCLUDEINGROUP") = 0
				}
			} ElseIf type'="" {
				If ..KeepEmptyElements {
				    If type["^" {
					    Set typeName=$piece(type,"^",2)
					    If $piece(type,"^",1)="" {
						    Set typeNamespace=""
					    } Else {
					    	Set typeNamespace=$get(..NSInfo($piece(type,"^",1),"uri"))
					    }
				    } Else {
					    Set typeName=type
					    Set typeNamespace=""
				    }
					If (typeName'=name2)||(typeNamespace'=namespace),
					   ..AddNewClass(elno,name,"",.namespace) {
						Set $$$ClassTree(elno,"Super") = type
						// Class will later be removed if not used for SOAP headers
						Set $$$ClassTree(elno,"temporary") = 1
					}
				}
				Set $$$ClassTree(elno,"Type") = type
			}
			
			// loop over children of this node
			Set ch = $O($$$ElTree(elno,"ch",""))
			While (ch '= "") {
				Do ..ProcessElement(ch,elno)
				Set ch = $O($$$ElTree(elno,"ch",ch))
			}
		}
	}
}

/// Get the namespace for a member based on the name
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetElementNamespace(elno As %Integer) As %String [ Internal, Private ]
{
	Set name = $G($$$ElTree(elno,"attrs","name"))
	// Save namespace of top level attributes and groups for use in resolving ref's
	If (name [ "^") {
		Set nsno = $P(name,"^",1)
		Set namespace = $select(nsno="":"",1:$get(..NSInfo(nsno,"uri")))
	} Else {
		Set namespace = ..TargetNS
	}

	Quit namespace
}

/// Process elements for a sequence
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessSequence(elno As %Integer, cls As %Integer, choice As %Boolean, containerMinOccurs As %Integer = 1, containerMaxOccurs As %String = 1, mixed As %Boolean = 0) [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("Sequence",elno)

	// loop prevention
	If ('..CycleCheck(elno,"Sequence")) {
		Quit
	}

	Set local = $get($$$ElTree(elno,"local"))
	Set name = $get($$$ElTree(elno,"attrs","name"))
	Set type = $get($$$ElTree(elno,"attrs","type"))
	Set maxOccurs = $get($$$ElTree(elno,"attrs","maxOccurs"),1)
	Set minOccurs = $get($$$ElTree(elno,"attrs","minOccurs"),1)
	Set refno = $get($$$ElTree(elno,"attrs","ref#"))
	
	If (containerMaxOccurs = "unbounded") || ((+containerMaxOccurs=containerMaxOccurs) && (+containerMaxOccurs>1)) {
		Set maxOccurs = "unbounded"
	}
	If containerMinOccurs=0 Set minOccurs=0

	If (local = "element") {
		// add a property to the class
		// that refers to this element
		// the element may already be a known type
		// or may introduce a new type
		
		Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
		Set pno = $$$ClassTree(cls,"Property")
		
		// see if this is a ref to another class
		Set refcls = ""
		If (refno '= "") {
			Set refcls = $get($$$ClassTree(refno,"ClassName"))
			If refcls="" {
				// If class not yet resolved remember cls.
				Set $$$ElTree(elno,"parent",cls) = $lb(pno,..CurrentNamespace)
			} Else {
				Set type=$get($$$ClassTree(refno,"Type"))
			}
			Set refNamespace=..GetElementNamespace(refno)
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLREF")=1
			If ..MakeNamespace || (..CurrentNamespace'=refNamespace) {
				Set $$$ClassTree(cls,"Property",pno,"Parameter","REFNAMESPACE")=refNamespace
				If refNamespace'="" {
					Set num=$get(..NSIndex(refNamespace))
					If num'="" {
						Set eq=$get(..NSInfo(num,"ElementQualified"))
						If eq'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","REFELEMENTQUALIFIED")=eq
					}
				} Else {
					Set eq=..NoNamespaceElementQualified
					If eq'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","REFELEMENTQUALIFIED")=eq
				}
			}
			Do:(..Debug>1) ..TraceMsg(" Initial Element Ref: ["_refcls_":"_cls_":"_name_"] ("_..CurrentNamespace_", "_$get(refNamespace)_")")
		} Else {
			Set refNamespace=..GetElementNamespace(elno)
			If refNamespace'="" {
				Set $$$ClassTree(cls,"Property",pno,"ELEMENTNAMESPACE")=refNamespace
			}
		}

		Write:((..Debug>0)&&(name="")) "Missing Prop Name (1): ",local," ",elno,!
		
		If $data($$$ElTree(elno,"attrs","isc:property")) {
			Set $$$ClassTree(cls,"Property",pno,"Name") = $$$ElTree(elno,"attrs","isc:property")
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=$select(name["^":$piece(name,"^",2),1:name)
		} Else {
			Set $$$ClassTree(cls,"Property",pno,"Name") = ..MakePropName(name,.xmlname)
			If xmlname'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=xmlname
		}
		Do:(..Debug>1) ..TraceMsg(" NEW PROPERTY (1): [" _ $G($$$ClassTree(cls,"ClassName"))_ ":" _ ..MakePropName(name) _ "] ("_type_", "_refcls_", "_$get(refNamespace)_") ",elno)
		
		// assume missing type is %String
		// A missing type means either: default of uriAny (sic)
		// or further specialization by sub elements of the element tag
		Set $$$ClassTree(cls,"Property",pno,"Type") = $S(type'="":type,1:"%String")

		/// test for collection
		If maxOccurs = 0 {
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "NONE"
		} ElseIf maxOccurs '= 1 {
			Set $$$ClassTree(cls,"Property",pno,"Collection") = "list"
			If ($$$ClassTree(cls,"Super")="$SOAP.list") {
				// this is a SOAP-encoded array (pull off [] from type)
				Do ..MakeSoapArray(cls,pno,$$$ClassTree(cls,"Property",pno,"Type"))
			}
		}
		
		// Process nillable attribute
		Set nillable=($get($$$ElTree(elno,"attrs","nillable"))="true")
		If nillable,..GenerateXMLNIL || $get(^ISC.SOAP("GenerateXMLNIL")) {
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNIL") = 1
		}
		If nillable,..GenerateXMLNILNOOBJECT {
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNILNOOBJECT") = 1
		}

		/// test for required
		// Hack for now -- never use required for properties in choice group
		If (minOccurs > 0) && 'nillable && 'choice {
			Set $$$ClassTree(cls,"Property",pno,"Required") = 1
		}
		
		Set fixed = $G($$$ElTree(elno,"attrs","fixed"))
		If fixed'="" {
			Set $$$ClassTree(cls,"Property",pno,"ReadOnly") = 1
			Set $$$ClassTree(cls,"Property",pno,"InitialExpression") = fixed
		}

		Set form = $G($$$ElTree(elno,"attrs","form"))
		Set qualified=$case(form,"qualified":1,"unqualified":0,:"")
		If qualified'="" {
			Set $$$ClassTree(cls,"Property",pno,"Parameter","ELEMENTQUALIFIED") = qualified
		}

		// process members of this element
		// if this is a ref to a class already created
		// do not recurse
		If refno = "" {
			Set ch = $O($$$ElTree(elno,"ch",""))
			While (ch '= "") {
				Do ..ProcessElement(ch,cls,cls_"^"_pno)
				Set ch = $O($$$ElTree(elno,"ch",ch))
			}
		}
	}
	ElseIf (local="any") && 'mixed {
		Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
		Set pno = $$$ClassTree(cls,"Property")

		Set $$$ClassTree(cls,"Property",pno,"Name") = "any"
		Set $$$ClassTree(cls,"Property",pno,"Type") = "%XML.String"
		Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "ANY"

		/// test for collection
		If maxOccurs = 0 {
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "NONE"
		} ElseIf maxOccurs '= 1 {
			Set $$$ClassTree(cls,"Property",pno,"Collection") = "list"
		}
		
		// Save namespace attribute
		Set namespace = $get($$$ElTree(elno,"attrs","namespace"))
		If namespace'="" Set $$$ClassTree(cls,"Property",pno,"namespace") = namespace
	}
	ElseIf local="sequence" {
		// process members of sequence (all is not valid in sequence)
		// make a property for every element in the sequence
		// the object should enforce that only one is non-null
		
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			// for now, no difference between sequence and choice
			// only possible difference is in constraints
			Do ..ProcessSequence(ch,cls,choice,minOccurs,maxOccurs)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}

		// If we are pushing down unbounded and not exactly one contained element
		// force XMLSEQUENCE = 0
		If (maxOccurs = "unbounded") && '..HasSingleSubElement(elno) {
			Set $$$ClassTree(cls,"Parameter","XMLSEQUENCE") = 0
		}
	}
	ElseIf (local="choice") {
		// process members of choice
		// make a property for every "choice"
		// the object should enforce that only one is non-null
		
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			// for now, no difference between sequence and choice
			// only possible difference is in constraints
			Do ..ProcessSequence(ch,cls,1,minOccurs,maxOccurs)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
		Set $$$ClassTree(cls,"Parameter","XMLSEQUENCE") = 0
	}
	ElseIf (local = "group") {
		// a group within a type
		// this will add one or more properties to the class
		// depending on the group and the elements it contains.
		
		// loop over the children
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSequence(ch,cls,choice,minOccurs,maxOccurs)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
}

/// Process child elements for a suspected class
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessElement(elno As %Integer, cls As %Integer, prop As %String = "", mixed As %Boolean = 0) [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("Element",elno,cls,prop)
	
	// loop prevention
	If ('..CycleCheck(elno,"Element")) {
		Quit
	}

	Set local = $G($$$ElTree(elno,"local"))
	Set src = $G($$$ElTree(elno,"src"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set type = $G($$$ElTree(elno,"attrs","type"))
	Set use = $G($$$ElTree(elno,"attrs","use"))
	Set arrayType = $G($$$ElTree(elno,"attrs","arrayType"))
	Set refno = $get($$$ElTree(elno,"attrs","ref#"))

	If (local = "annotation") {
		Do ..ProcessAnnotation(elno,cls,prop)
	}
	ElseIf (local = "attribute") {
		// attribute within a type
		// add a property to the class
		Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
		Set pno = $$$ClassTree(cls,"Property")
		
		If (arrayType '= "") && ($$$ClassTree(cls,"Super")="$SOAP.list") {
			// this is a SOAP-encoded array (pull off [] from type)
			Set arrayType = $P(arrayType,"[",1)
			Do ..MakeSoapArray(cls,pno,arrayType)
		}
		Else {
	
			Write:((..Debug>0)&&(name="")) "Missing Prop Name (2): ",local," ",elno,?50,$G($$$ElTree(elno,"attrs","name")),!
	
			If $extract(type,1,4)="xml:" {
				Set name=$extract(type,5,$length(type))
				Set type="%String"
				Set projection="XMLATTRIBUTE"
			} Else {
				Set projection="ATTRIBUTE"
				// see if this is a ref to another class
				If (refno '= "") {
					Set refNamespace=..GetElementNamespace(refno)
					Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLREF")=1
					If ..MakeNamespace || (..CurrentNamespace'=refNamespace) {
						Set $$$ClassTree(cls,"Property",pno,"Parameter","REFNAMESPACE")=refNamespace
					}
					Set refname = $select(refno'="":$G($$$ElTree(refno,"attrs","name")),1:"--")
					Do:(..Debug>1) ..TraceMsg(" Initial Attribute Ref: ["_cls_":"_name_":"_refname_"] ("_..CurrentNamespace_", "_$get(refNamespace)_")")
				} Else {
					Set refNamespace=..GetElementNamespace(elno)
					If refNamespace'="" {
						Set $$$ClassTree(cls,"Property",pno,"ELEMENTNAMESPACE")=refNamespace
					}
				}

			}
			If $data($$$ElTree(elno,"attrs","isc:property")) {
				Set $$$ClassTree(cls,"Property",pno,"Name") = $$$ElTree(elno,"attrs","isc:property")
				Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=$select(name["^":$piece(name,"^",2),1:name)
			} Else {
				Set $$$ClassTree(cls,"Property",pno,"Name") = ..MakePropName(name,.xmlname)
				If xmlname'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=xmlname
			}
			Set $$$ClassTree(cls,"Property",pno,"Type") = $select(type="":"%String",1:type)
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = projection
			Do:(..Debug>1) ..TraceMsg(" NEW PROPERTY (2): [" _ $G($$$ClassTree(cls,"ClassName"))_ ":" _ ..MakePropName(name) _ "]",elno)
	
			If (use = "required") {
				Set $$$ClassTree(cls,"Property",pno,"Required") = 1
			} ElseIf use = "prohibited" {
				Set $$$ClassTree(cls,"Property",pno,"prohibited") = 1
			}
			
			Set fixed = $G($$$ElTree(elno,"attrs","fixed"))
			If fixed'="" {
				Set $$$ClassTree(cls,"Property",pno,"ReadOnly") = 1
				Set $$$ClassTree(cls,"Property",pno,"InitialExpression") = fixed
			}
		}
		
		// there may be additional specifiers for the attribute
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessAttribute(ch,cls,cls_"^"_pno)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "attributeGroup") {
		// an attribute group within a type
		// this will add one or more properties to the class
		// depending on the contained attribute tags
		
		// loop over the children (attributes)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessAttributeGroup(ch,cls)

			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "group") {
		// a group within a type
		// this will add one or more properties to the class
		// depending on the group and the elements it contains.
		
		// loop over the children (attributes)
		Set maxOccurs = $get($$$ElTree(elno,"attrs","maxOccurs"),1)
		Set minOccurs = $get($$$ElTree(elno,"attrs","minOccurs"),1)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSequence(ch,cls,0,minOccurs,maxOccurs)

			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf local = "sequence" {
		// process members of sequence
		// treat "all" same as sequence

		Set maxOccurs = $get($$$ElTree(elno,"attrs","maxOccurs"),1)
		Set minOccurs = $get($$$ElTree(elno,"attrs","minOccurs"),1)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSequence(ch,cls,0,minOccurs,maxOccurs,mixed)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
		// If we are pushing down unbounded and not exactly one contained element
		// force XMLSEQUENCE = 0
		If (maxOccurs = "unbounded") && '..HasSingleSubElement(elno) {
			Set $$$ClassTree(cls,"Parameter","XMLSEQUENCE") = 0
		}
	}
	ElseIf local = "all" {
		// process members of all group
		// treat "all" same as sequence except that all set
		// XMLSEQUENCE parameter to 0 to not enforce ordering.
		// Safe to set XMLSEQUENCE for the entire class, since
		// all may only be used as the only

		Set maxOccurs = $get($$$ElTree(elno,"attrs","maxOccurs"),1)
		Set minOccurs = $get($$$ElTree(elno,"attrs","minOccurs"),1)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSequence(ch,cls,0,minOccurs,maxOccurs)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
		Set $$$ClassTree(cls,"Parameter","XMLSEQUENCE") = 0
	}
	ElseIf (local = "choice") {
		// process members of choice
		// make a property for every "choice"
		// the object should enforce that only one is non-null
		
		Set maxOccurs = $get($$$ElTree(elno,"attrs","maxOccurs"),1)
		Set minOccurs = $get($$$ElTree(elno,"attrs","minOccurs"),1)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			// for now, only difference between sequence and choice
			// is that choice cannot have required elements.
			// only possible difference is in constraints
			Do ..ProcessSequence(ch,cls,1,minOccurs,maxOccurs)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
		Set $$$ClassTree(cls,"Parameter","XMLSEQUENCE") = 0
	}
	ElseIf (local = "complexType") {
		Set mixed = ($G($$$ElTree(elno,"attrs","mixed")) = "true")
		
		// process members of complex type
		If (prop '= "") {
			If (name = "") {
				// this is an "anonymous" complex type within a property
				// assign it a name based on its container
				Set name = $G($$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMLNAME"))
				If name="" {
					Set name = $G($$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Name"),"anon")
				}
			}

			Set mixedWithAttribute = 0
			If mixed {
				Set ch = $order($$$ElTree(elno,"ch",""))
				While (ch '= "") {
					Set x = $get($$$ElTree(ch,"local"))
					If ((x = "attribute") || (x = "attributeGroup")) Set mixedWithAttribute = 1 Quit
					Set ch = $order($$$ElTree(elno,"ch",ch))
				}
			}
			
			If 'mixed || mixedWithAttribute {
				If (..AddNewClass(elno,name,"",,1)) {
					Set $$$ClassTree(elno,"src") = src
					Set $$$ClassTree(elno,"Parameter","XMLSEQUENCE") = 1
					Set $$$ClassTree(elno,"Parameter","XMLINCLUDEINGROUP") = 0
	
					Do ..SetClassType(elno)

					If mixedWithAttribute {
						Set $$$ClassTree(elno,"Property") = $G($$$ClassTree(elno,"Property")) + 1
						Set pno = $$$ClassTree(elno,"Property")
				
						Set $$$ClassTree(elno,"Property",pno,"Name") = "content"
						Set $$$ClassTree(elno,"Property",pno,"Type") = "%XML.String"
						Set $$$ClassTree(elno,"Property",pno,"Parameter","XMLPROJECTION") = "CONTENT"
					}
					// loop over children of this node
					Set ch = $order($$$ElTree(elno,"ch",""))
					While (ch '= "") {
						Do ..ProcessElement(ch,elno,,mixed)
						Set ch = $order($$$ElTree(elno,"ch",ch))
					}
				}
					
				// we "belong" to a property: fix it up
				Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Type") = $$$ClassTree(elno,"Type")
				
			} Else {
				Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Type") = "%XML.String"
				// loop over children of this node
				// but only process attribute and attributeGroups
				Set ch = $order($$$ElTree(elno,"ch",""))
				While (ch '= "") {
					Set x = $get($$$ElTree(ch,"local"))
					If ((x = "attribute") || (x = "attributeGroup")) {
						Do ..ProcessElement(ch,cls)
					}
					Set ch = $order($$$ElTree(elno,"ch",ch))
				}
			}
		}
		Else {
			If mixed {
				// mixed content
				
				// introduce a property to contain the
				// the mixed content
				// assume there is only 1 unwrapped mixed content per class!
				
				Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
				Set pno = $$$ClassTree(cls,"Property")
		
				Set $$$ClassTree(cls,"Property",pno,"Name") = "content"
				Set $$$ClassTree(cls,"Property",pno,"Type") = "%XML.String"
				Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "CONTENT"
			}

			// loop over children of this node
			Set ch = $order($$$ElTree(elno,"ch",""))
			While (ch '= "") {
				Do ..ProcessElement(ch,cls,,mixed)
				Set ch = $order($$$ElTree(elno,"ch",ch))
			}
		}
	}
	ElseIf (local = "simpleType") {
		If (prop = "") {
			// this is a candidate "class"
			// change it to a datatype class
			// !!! needed?
			Set $$$ClassTree(cls,"ClassType") = "datatype"
			Kill $$$ClassTree(cls,"Parameter","XMLSEQUENCE")
		}		
		
		// loop over children of this node
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSimpleType(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "complexContent") {
		// loop over children of this node
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessComplexContent(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "simpleContent") {
		
		// introduce a property to contain the
		// the simple content
		// assume there is only 1 simple content per class!
		
		If mixed {
			// If mixed override content property
			Set pno = $$$ClassTree(cls,"Property")
			Kill $$$ClassTree(cls,"Property",pno,"Type")
		} Else {
			Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
			Set pno = $$$ClassTree(cls,"Property")
		}

		If $data($$$ElTree(elno,"attrs","isc:property")) {
			Set $$$ClassTree(cls,"Property",pno,"Name") = $$$ElTree(elno,"attrs","isc:property")
		} Else {
			Set $$$ClassTree(cls,"Property",pno,"Name") = "content"
		}
		Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "CONTENT"
		Set $$$ClassTree(cls,"simpleContent") = pno
		
		// the type most likely will be set by the child elements
		// if not we set it below
		
		If (prop = "") {
			// make 'content' the property to be fixed up
			Set prop = cls_"^"_pno
		}
		
		// loop over children of this node
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSimpleContent(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}

		If ('$data($$$ClassTree(cls,"Property",pno,"Type"))) {
			Set $$$ClassTree(cls,"Property",pno,"Type") = "%String"
		}
	}
}

/// Create dummy property and mark class as a SOAP array
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method MakeSoapArray(cls As %Integer, pno As %Integer, arraytype As %String) [ Internal, Private ]
{
	Set $$$ClassTree(cls,"SOAPArrayType") = arraytype
	Set name="SOAP"
			
	// add a property so that dependency will generate correctly...
	Set $$$ClassTree(cls,"Property",pno,"Name") = ..MakePropName(name,.xmlname)
	If xmlname'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=xmlname
	Set $$$ClassTree(cls,"Property",pno,"Type") = arraytype
	Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = "ELEMENT" // ignored

	Do:(..Debug>1) ..TraceMsg(" NEW PROPERTY (SOAP): [" _ $G($$$ClassTree(cls,"ClassName"))_ ":" _ arraytype _ "]")
}

/// Process child elements of an attributeGroup
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessAttributeGroup(elno As %Integer, cls As %Integer) [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("AttributeGroup",elno)

	// loop prevention !!!
	//If ('..CycleCheck(elno,"AttrGroup")) {
	//	Quit
	//}
	
	Set local = $G($$$ElTree(elno,"local"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set type = $G($$$ElTree(elno,"attrs","type"))
	Set use = $G($$$ElTree(elno,"attrs","use"))
	Set refno = $get($$$ElTree(elno,"attrs","ref#"))

	If (local = "attribute") {
		// add a property to the class
		Set $$$ClassTree(cls,"Property") = $G($$$ClassTree(cls,"Property")) + 1
		Set pno = $$$ClassTree(cls,"Property")

		Write:((..Debug>0)&&(name="")) "Missing Prop Name (3): ",local," ",elno,!

		If $extract(type,1,4)="xml:" {
			Set name=$extract(type,5,$length(type))
			Set type="%String"
			Set projection="XMLATTRIBUTE"
		} Else {
			Set projection="ATTRIBUTE"
			If (refno '= "") {
				Set refNamespace=..GetElementNamespace(refno)
				Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLREF")=1
				If ..MakeNamespace || (..CurrentNamespace'=refNamespace) {
					Set $$$ClassTree(cls,"Property",pno,"Parameter","REFNAMESPACE")=refNamespace
				}
				Set refname = $select(refno'="":$G($$$ElTree(refno,"attrs","name")),1:"--")
				Do:(..Debug>1) ..TraceMsg(" AG - Initial Attribute Ref: ["_cls_":"_name_":"_refname_"] ("_..CurrentNamespace_", "_$get(refNamespace)_")")
			} Else {
				Set refNamespace=..GetElementNamespace(elno)
				If refNamespace'="" {
					Set $$$ClassTree(cls,"Property",pno,"ELEMENTNAMESPACE")=refNamespace
				}
			}
		}
		If $data($$$ElTree(elno,"attrs","isc:property")) {
			Set $$$ClassTree(cls,"Property",pno,"Name") = $$$ElTree(elno,"attrs","isc:property")
			Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=$select(name["^":$piece(name,"^",2),1:name)
		} Else {
			Set $$$ClassTree(cls,"Property",pno,"Name") = ..MakePropName(name,.xmlname)
			If xmlname'="" Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLNAME")=xmlname
		}
		Set $$$ClassTree(cls,"Property",pno,"Type") = $select(type="":"%String",1:type)
		Set $$$ClassTree(cls,"Property",pno,"Parameter","XMLPROJECTION") = projection
		Do:(..Debug>1) ..TraceMsg(" NEW PROPERTY (3): [" _ $G($$$ClassTree(cls,"ClassName"))_ ":" _ ..MakePropName(name) _ "]",elno)
		
		If (use = "required") {
			Set $$$ClassTree(cls,"Property",pno,"Required") = 1
		}
		
		Set fixed = $G($$$ElTree(elno,"attrs","fixed"))
		If fixed'="" {
			Set $$$ClassTree(cls,"Property",pno,"ReadOnly") = 1
			Set $$$ClassTree(cls,"Property",pno,"InitialExpression") = fixed
		}

		// there may be additional specifiers for the attribute
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessAttribute(ch,cls,cls_"^"_pno)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "attributeGroup") {
		// an attribute group within a type
		// this will add one or more properties to the class
		// depending on the contained attribute tags
		
		// loop over the children (attributes)
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessAttributeGroup(ch,cls)

			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
}

/// Process child elements for a simpleType
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessSimpleType(elno As %Integer, cls As %Integer, prop As %String = "") [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("SimpleType",elno)

	// loop prevention
	If ('..CycleCheck(elno,"SimpleType")) {
		Quit
	}
	
	Set local = $G($$$ElTree(elno,"local"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set type = $G($$$ElTree(elno,"attrs","type"))
	Set base = $G($$$ElTree(elno,"attrs","base"))
	if (base'="") && ..isAnyType(base) Set base=""

	If (local = "annotation") {
		Do ..ProcessAnnotation(elno,cls,prop)
	}
	ElseIf (local = "restriction") {
		// this is a restriction of another class
		// fix up our class type

		If (base '= "") {
			If (prop = "") {
				Set $$$ClassTree(cls,"Super") = base
				Set $$$ClassTree(cls,"DataType") = "datatype"
			}
			Else {
				// we "belong" to a property: fix it up
				Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Type") = base
			}
		}

		// process members of this restriction
		Set enumSep=""
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessRestrictList(ch,elno,cls,prop,.enumSep)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}		

	}
}

/// Process child elements for an attribute
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessAttribute(elno As %Integer, cls As %Integer, prop As %String = "") [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("Attribute",elno)

	// loop prevention
	If ('..CycleCheck(elno,"Attr")) {
		Quit
	}

	Set local = $G($$$ElTree(elno,"local"))

	If (local = "annotation") {
		Do ..ProcessAnnotation(elno,cls,prop)
	}
	ElseIf (local = "simpleType") {
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessSimpleType(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
}

/// Process child elements for a simpleContent
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessSimpleContent(elno As %Integer, cls As %Integer, prop As %String = "") [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("SimpleContent",elno)

	// loop prevention
	If ('..CycleCheck(elno,"SimpleContent")) {
		Quit
	}

	Set local = $G($$$ElTree(elno,"local"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set base = $G($$$ElTree(elno,"attrs","base"))
	if (base'="") && ..isAnyType(base) Set base=""

	If (local = "annotation") {
		Do ..ProcessAnnotation(elno,cls,"")
	}
	ElseIf (local = "extension") || (local = "restriction") {
		// this is an extension of another class
		// fix up our class type

		If (base '= "") {
			
			// if there is a "prop", apply the type to it.
			If ('$data($$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Type"))) {
				Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Type") = base
			}
		}

		Set $$$ClassTree(cls,"Super") = "%SerialObject" // !!!guess
		Set $$$ClassTree(cls,"ClassType") = "serial"

		// process members of this extension or restriction
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessElement(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
}

/// Process child elements for a complexContent
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessComplexContent(elno As %Integer, cls As %Integer, prop As %String = "") [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("ComplexContent",elno)

	// loop prevention
	If ('..CycleCheck(elno,"ComplexContent")) {
		Quit
	}

	Set local = $G($$$ElTree(elno,"local"))
	Set name = $G($$$ElTree(elno,"attrs","name"))
	Set type = $G($$$ElTree(elno,"attrs","type"))
	Set base = $G($$$ElTree(elno,"attrs","base"))
	if (base'="") && ..isAnyType(base) Set base=""

	If (local = "annotation") {
		Do ..ProcessAnnotation(elno,cls,"")
	}
	ElseIf (local = "extension") {
		// this is an extension of another class
		// fix up our class type

		If (base '= "") {
			Set $$$ClassTree(cls,"Super") = base
			Set $$$ClassTree(cls,"ClassType") = ""
			// By default keep sequence of super class. Later choice element may force XMLSEQUENCE=0
			Kill $$$ClassTree(cls,"Parameter","XMLSEQUENCE")
		}

		// process members of this extension
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessElement(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
	ElseIf (local = "restriction") {
		// this is a restriction of a complex content
		// in general do nothing ???
		// if this is a SOAP array, then this is a special case...
		Set uri = ""
		Set ns = $piece(base,"^",1)
		Set basetype = $piece(base,"^",2)
		Set:ns'="" uri = $get(..NSInfo(ns,"uri"))

		If (basetype = "Array") && ((uri [ $$$SOAPENCns) || (uri [ $$$SOAP12ENCns)) {
			// SOAP-encoded Array

			// set this to $SOAP.list pseudo-type
			// It will be reduced before we are done		
			Set $$$ClassTree(cls,"Super") = "$SOAP.list"
			Set $$$ClassTree(cls,"ClassType") = ""
		} Else {
			If (base '= "") {
				Set $$$ClassTree(cls,"Super") = base
				Set $$$ClassTree(cls,"ClassType") = ""
			}
			Set $$$ClassTree(cls,"restriction") = basetype
		}

		// process members of this restriction
		Set ch = $O($$$ElTree(elno,"ch",""))
		While (ch '= "") {
			Do ..ProcessElement(ch,cls,prop)
			Set ch = $O($$$ElTree(elno,"ch",ch))
		}
	}
}

/// Process elements for a restriction
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessRestrictList(elno As %Integer, parentElno As %Integer, cls As %Integer, prop As %String = "", ByRef enumSep As %String) [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("RestrictList",elno)
	
	Set local = $G($$$ElTree(elno,"local"))
	Set value = $G($$$ElTree(elno,"attrs","value"))

	// loop prevention
	If ('..CycleCheck(elno,"Restrict")) {
		Quit
	}
	
	If local="enumeration",enumSep="" {
		Set enumSep=..DetermineEnumSeparator(parentElno)
	}

	If (prop = "") {
		If (local = "enumeration") {
			// add value to enumeration list
			Set $$$ClassTree(cls,"Parameter","VALUELIST") = $G($$$ClassTree(cls,"Parameter","VALUELIST")) _ enumSep _ value
		}
		ElseIf (local = "maxLength") {
			Set $$$ClassTree(cls,"Parameter","MAXLEN") = value
		}
		ElseIf (local = "minLength") {
			Set $$$ClassTree(cls,"Parameter","MINLEN") = value
		}
		ElseIf (local = "length") {
			Set $$$ClassTree(cls,"Parameter","MINLEN") = value
			Set $$$ClassTree(cls,"Parameter","MAXLEN") = value
		}
		ElseIf (local = "fractionDigits") {
			Set $$$ClassTree(cls,"Parameter","XMLFractionDigits") = value
		}
		ElseIf (local = "totalDigits") {
			Set $$$ClassTree(cls,"Parameter","XMLTotalDigits") = value
		}
		ElseIf (local = "pattern") {
			// pattern is kept as XML pattern to be used when creating a schema from the class
			Set pattern=$get($$$ClassTree(cls,"Parameter","XMLPATTERN"))
			If pattern'="" Set pattern=pattern_"|"
			Set pattern=pattern_value
			Set $$$ClassTree(cls,"Parameter","XMLPATTERN") = pattern
		}
	}
	Else {
		If (local = "enumeration") {
			// add value to enumeration list
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","VALUELIST") = $G($$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","VALUELIST")) _ enumSep _ value
		}
		ElseIf (local = "maxLength") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MAXLEN") = value
		}
		ElseIf (local = "minLength") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MINLEN") = value
		}
		ElseIf (local = "length") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MINLEN") = value
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MAXLEN") = value
		}
		ElseIf (local = "maxExclusive") {
			// !!!
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMAXVAL") = value
		}
		ElseIf (local = "maxInclusive") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MAXVAL") = value
		}
		ElseIf (local = "minExclusive") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMINVAL") = value
		}
		ElseIf (local = "minInclusive") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","MINVAL") = value
		}
		ElseIf (local = "fractionDigits") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMLFractionDigits") = value
		}
		ElseIf (local = "totalDigits") {
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMLTotalDigits") = value
		}
		ElseIf (local = "pattern") {
			// pattern is kept as XML pattern to be used when creating a schema from the class
			Set pattern=$get($$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMLPATTERN"))
			If pattern'="" Set pattern=pattern_"|"
			Set pattern=pattern_value
			Set $$$ClassTree($P(prop,"^",1),"Property",$P(prop,"^",2),"Parameter","XMLPATTERN") = pattern
		}
	}
}

Method DetermineEnumSeparator(elno As %Integer) As %String
{
	// Any printable ASCII character allowed as the separator.  Favor , for compatibility.
	Set sepList=",:#$%&!*+-.~;<=>?@[/\]^_`'(){|}0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

	// Default enumeration separator is ,.
	Set enumSep=","

	// fetch enumeration values
	Set enumvalues=""
	Set ch=$order($$$ElTree(elno,"ch",""))
	While ch'="" {		
		If $get($$$ElTree(ch,"local"))="enumeration" {
			Set enumvalues=enumvalues_$get($$$ElTree(ch,"attrs","value"))
		}
		Set ch=$order($$$ElTree(elno,"ch",ch))
	}
	
	// determine enumseparator
	if enumvalues'="" {
		For i=1:1:$length(sepList) {
			If enumvalues'[$extract(sepList,i) {
				Set enumSep=$extract(sepList,i)
				Quit
			}
		}
	}
	
	Quit enumSep
}

/// Process an annotation element
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method ProcessAnnotation(elno As %Integer, cls As %Integer, prop As %String = "") [ Internal, Private ]
{
	Do:(..Debug>1) ..Trace("Annotation",elno)

	Set ch = $order($$$ElTree(elno,"ch",""))
	While (ch '= "") {
		If ($get($$$ElTree(ch,"local")) = "documentation") {
			Set xsddesc = $get($$$ElTree(ch,"chars"),"N.A")
			If $extract(xsddesc,1)=$c(10) Set $extract(xsddesc,1)=""
			For {
				set xsddesc=$zstrip(xsddesc,">W")
				Set len=$length(xsddesc)
				If $extract(xsddesc,len)'=$c(10) Quit
				Set $extract(xsddesc,len)=""
			}
			Set desc=""
			Set num=$length(xsddesc,$c(10))
			For i=1:1:num {
				Set line=$zstrip($piece(xsddesc,$c(10),i),"<>W")
				Set desc=desc_$select(desc="":"",1:$c(13,10))_line
			}
			If (prop = "") {
				Set $$$ClassTree(cls,"Description") = desc
			} Else {
				// document the property
				Set $$$ClassTree($piece(prop,"^",1),"Property",$piece(prop,"^",2),"Description") = desc
			}
		}
		Set ch = $order($$$ElTree(elno,"ch",ch))
	}
}

/// Get package part of class name.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method getPackage(classname As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$piece(classname,".",1,$length(classname,".")-1)
}

}
