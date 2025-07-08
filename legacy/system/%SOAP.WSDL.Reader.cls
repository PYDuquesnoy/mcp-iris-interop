/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%assert, %occSAX, %soap)

/// This class reads a WSDL and builds a web service client and associated class definitions from it.<BR>
/// 
/// This class is used by the SOAP Client Wizard; it is not
/// for direct use within applications except through the Process method.
/// Properties which are not marked as internal may be used to control the Process method.
Class %SOAP.WSDL.Reader Extends %RegisteredObject [ System = 3 ]
{

/// Control display of debugging info
///  Debug level.  Additional output for levels >0. 
///  Default is 0. 
Property Debug As %Integer [ InitialExpression = 0 ];

/// Input property to control compilation of created classes.
/// Default is to compile classes.
Property CompileClasses As %Boolean [ InitialExpression = 1 ];

/// Flags to be used for class compiles.
Property CompileFlags As %String [ InitialExpression = "dk" ];

/// Input property to control persistence of generated classes.
///  If true (1), create persistent classes, else create registered classes.  
///  Default is true. 
Property MakePersistent As %Boolean [ InitialExpression = 0 ];

/// Input property to control if generated classes are serial.
///  If true (1) and 'MakePersistent create serial classes, else create registered classes.
///  Default is true. 
Property MakeSerial As %Boolean [ InitialExpression = 0 ];

/// Input property to control creation of relationships in generated classes.
///  If true(1), convert list collections of persistent classes to relationships.
///  Default is true. 
Property MakeRelationships As %Boolean [ InitialExpression = 0 ];

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

/// Supplemental flag to suppress use of defined target Namespace.
/// Causes NAMESPACE parameter to be empty on SOAP client and server classes,
/// even if Namespace use is reactivated for other necessary schema processing reasons.
/// Anticipated usage is for SOAP Clients in conjunction with OutputTypeAttribute flag disablement.
Property SuppressNamespace As %Boolean;

/// Flag to enable the URL Escape of SOAPAction header for SOAP1.1 requests.
/// This is to complement the existing URL Decode of SOAP1.1 SOAPAction by IRIS WebServices.
/// For example a "%" character in soap action is expanded to "%25" in transmission of the HTTP Header.
/// Allows consistency in different SOAP client platforms accessing same IRIS WebService.<br>
/// Default Reader action is to enable SOAPAction header to be URL Escaped for new generated SOAP Clients.
/// Programmtically set reader property to "0" to resume previous behavior of generating clients with 
/// unescaped SOAPAction header being transmitted for SOAP1.1
Property ClientURLEscapeSoapAction As %Boolean [ InitialExpression = 1 ];

/// Input property to control creation of web service client classes.
/// If true (1), then the client classes are created. 
/// The default is to create client classes.
Property MakeClient As %Boolean [ InitialExpression = 1 ];

/// If MakeClient is true, then ClientPackage is the name of the package to contain the client classes.
/// If ClientPackage="", then the client classes are put in the default package.
/// If ClientPackage begins with a period (.), then the ClientPackage is appended to the default package.
/// Otherwise the ClientPackage is used as specified.
Property ClientPackage As %String;

/// Input property to control creation of web service classes.
/// If true (1), then the web service classes are created. 
/// The default is to not create web service classes.
Property MakeService As %Boolean [ InitialExpression = 0 ];

/// If MakeService is true, then ServicePackage is the name of the package to contain the web service classes.
/// If ServicePackage="", then the web service classes are put in the default package.
/// If ServicePackage begins with a period (.), then the ClientPackage is appended to the default package.
/// Otherwise the ServicePackage is used as specified.
Property ServicePackage As %String [ InitialExpression = ".Service" ];

/// If ConfigPackage = "", then create the configuration class in the same package as
/// the client or service with 'Config' appended to the client or service name.
/// If ConfigPackage '= "", then create the configuration class in the subpackage
/// given by ConfigPackage of the package containing the client or service.
Property ConfigPackage As %String;

/// Input property to control generation of production-related classes for the Business Operation
/// Request Object and Response Object from a WSDL.
///  If true (1), create an business operation and related request and response objects.
Property MakeEnsembleClasses As %Boolean [ InitialExpression = 0 ];

/// If MakeEnsembleClasses is true,
/// OperationPackage is the name of the package to contain the Business Operation.  
Property OperationPackage As %String [ InitialExpression = "Operation" ];

/// If MakeEnsembleClasses is true,
/// RequestPackage is the name of the package to contain the production request object.  
Property RequestPackage As %String [ InitialExpression = "Request" ];

/// If MakeEnsembleClasses is true,
/// ResponsePackage is the name of the package to contain the production request object.  
Property ResponsePackage As %String [ InitialExpression = "Response" ];

/// If MakeEnsembleClasses is true, then MakeBusinessOperation and BusinessOperationPackage are ignored.
/// Input property to control generation of an business operation for a WSDL
///  If true (1), create an business process and related request and response objects.
Property MakeBusinessOperation As %Boolean [ InitialExpression = 0 ];

/// User supplied mapping of namespaces to package names which will override the default 
/// package used for a specified namespace.  
/// This mapping does not apply to the client or service class - only the referenced classes.<br>
/// The format is PackageMapping(namespace)=package for each mapped namespace<br>
/// If package="", then the client classes are put in the default package.
/// If package begins with a period (.), then the package is appended to the default package.
/// Otherwise the package is used as specified.<br>
/// The PackageMapping property may only be used with the Process method.
Property PackageMapping As %String [ MultiDimensional ];

/// The MakeMessageStyle property specifies whether the generated client uses a message format in which 
/// each request message part (not the elements of the part's type) is an argument
/// and each response message part is a return value or output argument. 
/// The generation of the class using the message or wrapped format is specified by 
/// the MakeMessageStyle property which causes this class to have an ARGUMENTSTYLE parameter 
/// of "" (for false) or "message" (for true).
/// The default value for ArgumentStyle is false. 
/// The generated ARGUMENTSTYLE parameter will be ignored if the SoapBindingStyle is not document. 
/// If MakeMessageStyle is true, then NAMESPACE parameters are created as if MakeNamespace is true.
Property MakeMessageStyle As %Boolean;

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

/// If MakeBusinessOperation is true,
/// the name of the sub-package to contain the Business Operation
Property BusinessOperationPackage As %String [ InitialExpression = "BusOp" ];

/// If <property>OutputTypeAttribute</property> = 1, then the Process method will add the OUTPUTTYPEATTRIBUTE
/// parameter to the web client which is created.   This parameter forces the inclusion of the xsi:type
/// attribute for each element of object output.
Property OutputTypeAttribute As %Boolean [ InitialExpression = 0 ];

/// The SecurityInParameter property allows the SECURITYIN parameter to be added to created classes.
/// If SecurityInParameter'="", then add the SECURITYIN parameter to the class created for the web service or web client.
/// The value of the SECURITYIN parameter will be taken from the SecurityInParameter property.
/// The only valid values for this property are "", "ALLOW", "IGNORE", "IGNOREALL", and "REQUIRE".
Property SecurityInParameter As %String(VALUELIST = ",ALLOW,IGNORE,IGNOREALL,REQUIRE");

/// If the NoSequence property is true, the XMLSEQUENCE parameter is set to 0 in the generated classes.
Property NoSequence As %Boolean;

/// If the IgnoreNull property is set, the web client/service and the generated classes are created with the
/// XMLIGNORENULL parameter to the value in IgnoreNull.
Property IgnoreNull As %String;

/// If the BinaryAsStream property is true, then use %Stream.GlobalBinary for base64Binary type.
Property BinaryAsStream As %Boolean;

/// The name of the activated TLS/SSL configuration to use for https requests.
Property SSLConfiguration As %String;

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean;

/// The %Net.HttpRequest instance to be used for all web requests for 
/// WSDL and XML schema documents.  This property may optionally be set by the caller
/// in order to specify %Net.HttpRequest properties Username, ProxyPort, etc.
Property HttpRequest As %Net.HttpRequest;

/// This property should be set to a combination of flags (see %occSAX.inc for details) if
/// the default behavior of the parser is required to be modified.
/// The $$$SAXVALIDATIONPROHIBITDTDS flag is added by default in order to not allow DTDs.
Property SAXFlags As %Integer [ InitialExpression = {$$$SAXFULLDEFAULT+$$$SAXVALIDATIONPROHIBITDTDS} ];

/// This property should be set to an instance of %XML.SAX.EntityResolver OR a user-defined
/// subclass IF the default EntityResolver is not required.
Property EntityResolver As %XML.SAX.EntityResolver;

/// This property holds the current ^IRIS.Temp Key
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property IRISTempTarget As %String [ Internal, Private ];

/// This property holds the current key where the 'definitions' element is store
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property DefinitionsKey As %Integer [ Internal, Private ];

/// This property holds the URL locations that have been visited so far
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Locations As %String [ Internal, MultiDimensional, Private ];

/// This multidimensional property holds an index of service names found within the
/// parsed WSDL
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Services As %String [ Internal, MultiDimensional, Private ];

/// This multidimensional property holds an index of bindings found within the
/// parsed WSDL
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property Bindings As %String [ Internal, MultiDimensional, Private ];

/// This property holds the current target namespace
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property TargetNamespace As %String [ Internal, Private ];

/// This property holds the keys where parsed WSDL data is stored
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property WSDLKeys As %Integer [ Internal, MultiDimensional, Private ];

/// This property holds the global key where the extracted definitions
/// are stored
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property WSDLTarget As %Integer [ Internal, Private ];

/// The schema reader used to find any complex types within the WSDL
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property SchemaReader As %XML.Utils.SchemaReader [ Internal ];

/// An array of the names of classes that have to be created (for clients):
/// ClientClassList(name) = ""
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property ClientClassList As %String [ Internal, MultiDimensional ];

/// An array of the names of classes that correspond to SOAP messages.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property MessageClassList As %String [ Internal, MultiDimensional, Private ];

/// An array of the names of classes that have to be created (for types)
/// TypeClassList(name) = ""
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property TypeClassList As %String [ Internal, MultiDimensional ];

/// An array of the names of classes are created for an business operation:
/// BOClassList(name) = ""
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Property BOClassList As %String [ Internal, MultiDimensional ];

/// Cleanup temporary global nodes that were used.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method %OnClose() As %Status [ Internal, Private ]
{
	Set key=$order(i%WSDLKeys(""))
	While key'="" {
		Do ##class(%XML.ImportHandler).KillDocument(key)
		Set key=$order(i%WSDLKeys(key))
	}
	
	If i%WSDLTarget'="" Kill ^IRIS.Temp(i%WSDLTarget)
	
	Quit $$$OK
}

/// Reset this class instance for reuse.
Method Reset()
{
	Do ..%OnClose()

	Kill ..Locations,..Services,..Bindings,..WSDLKeys,..ClientClassList,..MessageClassList,..TypeClassList,..BOClassList
	Set ..IRISTempTarget=""
	Set ..DefinitionsKey=""
	Set ..TargetNamespace=""
	Set ..WSDLTarget=""
	Set ..SchemaReader=""
}

/// Create a parameter
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method CreateParameter(CDefArg, pName, pValue, pDocs, pSeqNo) As %Status [ Internal, Private ]
{
 	Set tSC=$$$OK
 	If $get(CDefArg)="" {
	 	Set CDefList=2
	 	Set CDefList(1)=%clientCDef
	 	Set CDefList(2)=%serviceCDef
 	} Else {
	 	Set CDefList=1
	 	Set CDefList(1)=CDefArg
 	}
	For i=1:1:CDefList {
		Set CDef=CDefList(i)
		If CDef="" Continue
		Set className=CDef.Name
 		#; Create a new parameter
		Set tClassName=className_":"_pName
		Kill %objlasterror
 		Set tCDef=##class(%Dictionary.ParameterDefinition).%New(tClassName)
 		If tCDef=$$$NULLOREF {
	 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,tClassName) )
	 		Quit
 		}

 		#; Fill in the type, value and description
 		Set tCDef.Default=pValue,tCDef.Description=$Get(pDocs)

 		#;	Insert into the class definition
 		If $get(pSeqNo)'="" Set tCDef.SequenceNumber=pSeqNo
 		Set tSC=CDef.Parameters.Insert(tCDef)
 	}
	Quit tSC
}

/// Create a property
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method CreateProperty(pClassName, pCDef, pName, pType, pSeqNo, persistent, ByRef persistentProperties) As %Status [ Internal, Private ]
{
 	Set tSC=$$$OK
 	do { 

 		#; Create a new parameter
		Set tClassName=pClassName_":"_pName
		Kill %objlasterror
 		Set tCDef=##class(%Dictionary.PropertyDefinition).%New(tClassName)
 		If tCDef=$$$NULLOREF {
	 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,tClassName) )
	 		Quit
 		}

 		#; Fill in the type
 		Set isCollection=0
 		Set type=$piece(pType,"(",1)
 		Set parameters=$piece(pType,"(",2)
 		If (parameters["ELEMENTTYPE=""") &&
 		  $case(type,"%ArrayOfDataTypes":1,"%ArrayOfObjects":1,"%ListOfDataTypes":1,"%ListOfObjects":1,:0) {
	 		Set tCDef.Collection=$select(type["%Array":"array",1:"list")
	 		Set type=$piece($piece(parameters,"ELEMENTTYPE=""",2),"""",1)
	 		Set isCollection=1
		}
 		Set tCDef.Type=type
 		
 		#; Setup property information used to create %OnDelete method.
 		If persistent {
			Set persistentProperties($i(persistentProperties))=$lb(pName,type,isCollection)
		}
		
 		#;	Insert into the class definition
 		If $get(pSeqNo)'="" Set tCDef.SequenceNumber=pSeqNo
 		Set tSC=pCDef.Properties.Insert(tCDef)
 	} while (0)

 	Quit tSC
}

/// Determine if this is a SOAP service
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method IsService(pService, pNamespace, pPort) As %Boolean [ Internal, Private ]
{
	#; Get the binding
	Set tBinding=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"binding")
	Set tBindingNS=$List(tBinding,1)
	Set tBindingName=$List(tBinding,2)

	#; soap:address element must be present for SOAP service unless we created missing service.
	#; If not present, then not SOAP and we will ignore.
	Set isPlaceHolder=(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService)="placeholder")
	If '$data(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort)),'isPlaceHolder Quit 0
	#; Transport must be specified in a soap:binding element.  Otherwise not SOAP and we will ignore.
	Set tTransport=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"transport"))
	If tTransport="" Quit 0
	
	Quit 1
}

/// Make a class definition for service or client
Method CreateCDef(className As %String, Output CDef As %Dictionary.ClassDefinition) As %Status [ Internal, Private ]
{
	Set CDef=""
	If className="" Quit $$$OK
	
 	#; Delete any pre-existing definition
	Do Delete^%apiOBJ(className,"-d")

	#; Create a new class definition
	Kill %objlasterror
	Set CDef=##class(%Dictionary.ClassDefinition).%New(className)
	If '$isobject(CDef) {
		Quit $Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,className))
	}
	Set CDef.ProcedureBlock=1
	#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
	Set CDef.ClassVersion=25

	#; Add class to list of client classes
	Set ..ClientClassList(className) = ""

	Quit $$$OK
}

/// Make a method definition for service or client method
Method CreateMDef(CDef As %Dictionary.ClassDefinition, methodName As %String, Output MDef As %Dictionary.MethodDefinition) As %Status [ Internal, Private ]
{
	Set MDef=""
	If CDef="" Quit $$$OK
	
	Set MethodSpec=CDef.Name_":"_methodName
	Kill %objlasterror
	Set MDef=##class(%Dictionary.MethodDefinition).%New(MethodSpec)
 	If '$isobject(MDef) {
	 	Quit $Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,"Method "_MethodSpec))
 	}
 			
 	Set MDef.Final=1
 	Set MDef.Private=0
 	Set MDef.WebMethod=1
 	Set MDef.ClassMethod=0
 	Set MDef.ProcedureBlock=1

	Quit $$$OK
}

/// Set a property of method definitions for both client and service
Method SetMethodProperty(name As %String, value As %String, MDef As %Dictionary.MethodDefinition) [ Internal, Private ]
{
	If $get(MDef)'="" {
		Set $property(MDef,name)=value
	} Else {
		If %clientMDef'="" Set $property(%clientMDef,name)=value
		If %serviceMDef'="" Set $property(%serviceMDef,name)=value
	}
}

/// Generate a SOAP service
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GenerateService(pService As %String, pNamespace As %String, pPort As %String, PackageName As %String, ClientClassName As %String, ServiceClassName As %String) As %Status [ Internal, Private ]
{
 	Set tSC=$$$OK
 	Set needArgumentStyle=0
 	New %clientCDef,%serviceCDef,%clientMDef,%serviceMDef
 	Set (%clientCDef,%serviceCDef)=""
 	do {
		#; Get the binding
		Set tBinding=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"binding")
		Set tBindingNS=$List(tBinding,1)
		Set tBindingName=$List(tBinding,2)

 		#; Inspect and cross-reference the port
		Set tPortType=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"portType"))
		Set tPortTypeNS=$listget(tPortType,1),tPortTypeName=$listget(tPortType,2)
		If (tPortType="") || '$Data(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName)) {
			Set tSC=$$$ERROR($$$WSDLNoCorrespondence,"wsdl:binding","portType definition",tPortTypeName_" : "_tPortTypeNS)
			Quit
		}

 		#; soap:address element must be present for SOAP service unless we created missing service.
 		#; If not present, then not SOAP and we will ignore.
		Set isPlaceHolder=(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService)="placeholder")
		If '$data(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort)),'isPlaceHolder Quit
		Set tLocation=$Get(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"location"))
 		#; Transport must be specified in a soap:binding element.  Otherwise not SOAP and we will ignore.
		Set tTransport=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"transport"))
		If tTransport="" Quit

		#; Inspect and cross-reference the binding
		If '$Data(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName)) {
			Set tSC=$$$ERROR($$$WSDLNoCorrespondence,"wsdl:service:port","binding definition",tBindingName_" : "_tBindingNS)
	 		Quit
 		}

		#; Create client definition
		Set makeEnsemble=0
		Set tSC=..CreateCDef(ClientClassName,.%clientCDef)
		If $$$ISERR(tSC) Quit
		If %clientCDef'="" {
	 		#; This class will inherit from %SOAP.WebClient
	 		Set %clientCDef.Super="%SOAP.WebClient"

	 		#; Create the LOCATION parameter
	 		If tLocation'="" {
		 		Set tSC=..CreateParameter(%clientCDef,"LOCATION",tLocation,"This is the URL used to access the web service.")
		 		If $$$ISERR(tSC) Quit
	 		}

	 		#; Make Ensemble Business Operation if requested
	 		If ..MakeEnsembleClasses {
		 		Set makeEnsemble=1
		 		Set busopPkg=..OperationPackage
		 		If busopPkg="" Set busopPkg="Operation"
		 		Set requestPkg=..RequestPackage
		 		If requestPkg="" Set requestPkg="Request"
		 		Set responsePkg=..ResponsePackage
		 		If responsePkg="" Set responsePkg="Response"
	 		} ElseIf ..MakeBusinessOperation {
		 		Set makeEnsemble=1
		 		Set busopPkg=..BusinessOperationPackage
		 		If busopPkg="" Set busopPkg="BusOp"
	 			Set busopPkg=PackageName_"."_busopPkg
	 			Set requestPkg=busopPkg
	 			Set responsePkg=busopPkg
	 		}
		}

		Set tSC=..CreateCDef(ServiceClassName,.%serviceCDef)
		If $$$ISERR(tSC) Quit
		If %serviceCDef'="" {
	 		#; This class will inherit from %SOAP.WebService
	 		Set %serviceCDef.Super="%SOAP.WebService"

	 		Set tSC=..CreateParameter(%serviceCDef,"USECLASSNAMESPACES",1,"Namespaces of referenced classes will be used in the WSDL.")
	 		If $$$ISERR(tSC) Quit
		}

 		If makeEnsemble {
	 		Set tBOClassName=busopPkg_$extract(ClientClassName,$length(PackageName)+1,$length(ClientClassName))
	 		Set ..BOClassList(tBOClassName)=""
 		
	 		#; Delete any pre-existing definition
		 	Do Delete^%apiOBJ(tBOClassName,"-d")

	 		#; Create a new class definition
	 		Set tBODef=##class(%Dictionary.ClassDefinition).%New(tBOClassName)
	 		If tBODef=$$$NULLOREF {
		 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,tBOClassName))
		 		Quit
	 		}
	 		Set tBODef.ProcedureBlock=1
			#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
			Set tBODef.ClassVersion=25

	 		#; This class will inherit from Ens.BusinessOperation
	 		Set tBODef.Super="Ens.BusinessOperation"

	 		#; Create the ADAPTER parameter
	 		Set tSC=..CreateParameter(tBODef,"ADAPTER","EnsLib.SOAP.OutboundAdapter","")
	 		If $$$ISERR(tSC) Quit

 			#; Create the Message Map for the Business Operation
 			Set tXData=##class(%Dictionary.XDataDefinition).%New(tBOClassName_":MessageMap")
			Set tSC=tXData.Data.WriteLine("<MapItems>") If $$$ISERR(tSC) Quit
 		}

 		#; And the Style
		Set tDefaultBindingStyle=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"style"))
		
 		#; Create the SERVICENAME parameter
		// Allow other bindings than SOAP over HTTP, but no special code for them.
		// Just comment the SERVICENAME parameter.
		Set description="This is the name of the Service"
		If tTransport'=$$$SOAPhttp {
			Set description=description_$c(13,10)_"transport specified was not HTTP: "_tTransport
		}
 		Set tSC=..CreateParameter(,"SERVICENAME",pService,description)
 		If $$$ISERR(tSC) Quit

 		#; Create the NAMESPACE parameter
 		Set ns=$Select(..SuppressNamespace:"",1:pNamespace)
 		If ns="""""" Set ns=""
 		Set tSC=..CreateParameter(,"NAMESPACE",ns,"This is the namespace used by the Service")
 		If $$$ISERR(tSC) Quit
 		
 		#; Optional create the SOAPBINARY parameter
		If $get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"isc")) {
			Set tSC=..CreateParameter(,"SOAPBINARY",0,"This Service supports the Cache binary SOAP protocol.  Default is to use XML based SOAP")
			If $$$ISERR(tSC) Quit
			Set soapBinaryCharset=^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"isccharset")
			Set tSC=..CreateParameter(,"SOAPBINARYCHARSET",soapBinaryCharset,"Cache charset of the service.")
			If $$$ISERR(tSC) Quit
		}
		
		#; Create the SOAPVERSION parameter
 		Set %SOAPns=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"soapns"))
 		If %SOAPns="" {
	 		Set soapVersion=""
 			Set soapVersionDesc="This service supports both SOAP 1.1 and SOAP 1.2."
 		} Else {
	 		Set soapVersion=$select(%SOAPns=$$$SOAP12ns:"1.2",1:"1.1")
 			Set soapVersionDesc="This is the SOAP version supported by the service."
 		}
		Set tSC=..CreateParameter(,"SOAPVERSION",soapVersion,soapVersionDesc)
		If $$$ISERR(tSC) Quit

		#; Create the SECURITYIN parameter
		If ..SecurityInParameter'="" {
			Set tSC=..CreateParameter(,"SECURITYIN",..SecurityInParameter,"Determines handling of Security header.")
			If $$$ISERR(tSC) Quit
		}

		#; Create the XMLIGNORENULL parameter
		If ..IgnoreNull'="" {
			Set tSC=..CreateParameter(,"XMLIGNORENULL",..IgnoreNull,"Overrides default handling of string arguments.")
			If $$$ISERR(tSC) Quit
		}

		#; For each operation create and fixup the method names, see if bodyUse is consistent, 
		#; scan xmlelement and scan typenamespace.
		Kill tFormalParms
		Set ConsistentBodyUse=0
		Set classBodyUse=""
		Set classTypeNamespace=$char(1)
		Set classElementQualified=$char(1)
		Set classAttributeQualified=$char(1)
		Set classElement=""
		Set classDefaultElement=1
		Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",""))
		while (tOperation'="") {
			Set MethodNames($increment(MethodNames))=##class(%SOAP.WebBase).NormalizeName(tOperation,$$$MAXNAMELENGTH,1)
			Set typeNamespace(MethodNames)=$char(1)
			
			#; Look at all messages
			Set tOpMsg=""
		    For {
				Set tOpMsg=$Order(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg))
				If tOpMsg="" Quit
			    If $extract(tOpMsg)="%" Continue
 				#; Inspect and cross-reference operation message with binding
				If '$Data(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg)) {
					Set tSC=$$$ERROR($$$WSDLNoCorrespondence,"wsdl:portType","message definition",tOpMsg_" : "_tBindingNS)
					Quit
				}

 				#; Get the (optional) body use. Although it's optional it better be there or we don't know what to do with this
 				#; message. The WSDL specification conflicts with the WSDL schema here as the spec says it's required but the
 				#; schema defines it as optional.
				Set tBodyUse=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"use"))
				If (tBodyUse="") {
					Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:portType:operation:msg","use")
					Quit
				}

 				#; Get the (optional) encoding style. If body use is 'encoded' then validate the encoding style against soap encoding
				Set tEncodingStyle=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"encodingStyle"))
				if (tBodyUse="encoded"&&(tEncodingStyle'="")) {				

 				#; The encoding style is a single-space delimited list of URIs. we only support SOAP encoding at present.
					for tI=1:1:$Length(tEncodingStyle," ") {
						If soapVersion="1.2" {
							If ($Piece(tEncodingStyle," ",tI)'=$$$SOAP12ENCns) {
								Set tSC=$$$ERROR($$$WSDLBadEncoding,tEncodingStyle)
								Quit
							}
						} Else {
							If ($Piece(tEncodingStyle," ",tI)'=$$$SOAPENCns) {
								Set tSC=$$$ERROR($$$WSDLBadEncoding,tEncodingStyle)
								Quit
							}
						} 
					}
					If $$$ISERR(tSC) Quit
				}
				
 				#; Inspect and cross-reference message definition
				Set tMessageName=^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg)
				Set tMessageNS=$List(tMessageName,1)
				Set tMessageName=$List(tMessageName,2)
				If '$Data(^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName)) {
					Set tSC=$$$ERROR($$$WSDLNoCorrespondence,"wsdl:binding:operation:msg","message",tMessageName_" : "_tMessageNS)
					Quit
				}
				
				#; Only look at input and output messages
				#; This code depends on input collating (and therefore processed) before output
				If (tOpMsg="input") || (tOpMsg="output") {
					#; If we have a consistent BodyUse for each message, we can default the ElementQualified
					#; based on BodyUse (1 for literal, 0 for encoded)
					If classBodyUse="" {
						Set classBodyUse=tBodyUse
						Set ConsistentBodyUse=1
					} Else {
						If classBodyUse'=tBodyUse Set ConsistentBodyUse=0
					}

					#; Scan element usage of parts
					Set xmlelement=^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName,"xmlelement")
					If xmlelement'="" {
						If (xmlelement=$char(0)) || (xmlelement'=(tBodyUse="literal")) Set classDefaultElement=0
						If classElement="" {
							Set classElement=xmlelement
						} ElseIf classElement'=xmlelement {
							Set classElement=$char(0)
						}
					}


					#; Get list of SoapTypeNameSpace for this message.
					Set typeNamespaceList=$get(^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName,"typenamespace"))
					Set opTypeNamespace=$listget(typeNamespaceList,1)
					
					#; Do not consider namespaces for parts that are not in parts list
					Set tParts=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"parts"))
					if tParts'="" {
						Kill distinctParts
						#; Get distinct parts from list.
						For tI=1:1:$Length(tParts," ") {
							Set distinctParts($piece(tParts," ",tI))=0
						}
						#; Use namespace from first message part in parts list
						Merge tFormalParms(tOpMsg)=^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName)
						For tI=1:1:tFormalParms(tOpMsg) {
							If $data(distinctParts(tFormalParms(tOpMsg,tI))) {
								Set opTypeNamespace=$listget(typeNamespaceList,tI)
								Quit
							}
						}
					}
					
					#; Use first namespace as typenamespace
					If (typeNamespace(MethodNames)=$char(1)) || (typeNamespace(MethodNames)="") {
						Set typeNamespace(MethodNames)=opTypeNamespace
					}
					
				}
		    }
		    #; Update class-wide typenamespace based on SoapTypeNamespace for this method
		    If classTypeNamespace=$char(1) {
			    Set classTypeNamespace=typeNamespace(MethodNames)
		    } ElseIf (typeNamespace(MethodNames)'=$char(1)) && (typeNamespace(MethodNames)'=classTypeNamespace) {
			    Set classTypeNamespace=$char(0)
		    }
		    If typeNamespace(MethodNames)'=$char(1) {
		 		Set elementQualified=..SchemaReader.GetElementQualified(typeNamespace(MethodNames))
			    If classElementQualified=$char(1) {
				    Set classElementQualified=elementQualified
			    } ElseIf (elementQualified'="") && (elementQualified'=classElementQualified) {
				    Set classElementQualified=$char(0)
			    }
		 		Set attributeQualified=..SchemaReader.GetAttributeQualified(typeNamespace(MethodNames))
			    If classAttributeQualified=$char(1) {
				    Set classAttributeQualified=attributeQualified
			    } ElseIf (attributeQualified'="") && (attributeQualified'=classAttributeQualified) {
				    Set classAttributeQualified=$char(0)
			    }
		    }
			Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation))
		}
		If $$$ISERR(tSC) Quit

		#; Fix up method names
		Do ..fixNames($$$MAXNAMELENGTH,.MethodNames)
		
		#; Create TYPENAMESPACE, ATTRIBUTEQUALIFIED and ELEMENTQUALIFIED class parameters
 		If classTypeNamespace=$char(0) Set classTypeNamespace=$char(1)
 		If classTypeNamespace'=$char(1) {
	 		If classTypeNamespace'=pNamespace,classTypeNamespace'="" {
				Set tSC=..CreateParameter(,"TYPENAMESPACE",classTypeNamespace,"This is the namespace used for types by the Service")
				If $$$ISERR(tSC) Quit
	 		}
 		}

 		If classElementQualified=$char(0) Set classElementQualified=$char(1)
		If (classElementQualified'=$char(1)) && 
		   ('ConsistentBodyUse || ((classBodyUse = "encoded")=classElementQualified)) {
			Set tSC=..CreateParameter(,"ELEMENTQUALIFIED",classElementQualified,"Non-default elementFormQualified for types XML namespace.")
			If $$$ISERR(tSC) Quit
		}
 		
		If classAttributeQualified'=$char(1),classAttributeQualified {
			Set tSC=..CreateParameter(,"ATTRIBUTEQUALIFIED",''classAttributeQualified,"Non-default attributeFormQualified for types XML namespace.")
			If $$$ISERR(tSC) Quit
		}
 		
 		#; Create XMLELEMENT class parameter
 		If (classElement=$char(0)) || classDefaultElement Set classElement=""
 		If classElement'="" {
			Set tSC=..CreateParameter(,"XMLELEMENT",classElement,"Non-default use of element/type attribute in parts.")
			If $$$ISERR(tSC) Quit
 		}

 		#; Optional create the OUTPUTTYPEATTRIBUTE parameter
 		If ..OutputTypeAttribute {
			Set tSC=..CreateParameter(,"OUTPUTTYPEATTRIBUTE",1,"Use xsi:type attribute for literal types.")
			If $$$ISERR(tSC) Quit
 		}

 		#; For each operation in the binding
 		Set responseNamespace=""
 		Set responseNamespaceValid=1
 		Set namespaceNoMatchOperation=""
 		Set responseTypeNamespace=""
 		Set responseTypeNamespaceValid=1
 		Set typeNamespaceNoMatchOperation=""
 		Set methodIndex=0
		Kill SoapHeaders,Actions
		Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",""))
		// Detect if ANY SoapAction would require URL encoding
		Set doesSoap11ActionRequireURLEncoding=0
		while (tOperation'="") {

 			#; Inspect and cross-reference the port operation
			If '$Data(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation)) {
				Set tSC=$$$ERROR($$$WSDLNoCorrespondence,"wsdl:binding","operation definition",tOperation_" : "_tPortTypeNS)
				Quit
			}
	
 			#; Pick-out the soapBindingStyle
			Set tBindingStyle=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,"style"),tDefaultBindingStyle)
			If (tBindingStyle="") {
				Set tSC=$$$ERROR($$$WSDLNoValue,"wsdl:binding","soap binding style",tOperation_" : "_tBindingNS)
				Quit
			}

 			#; Pick-out the soapAction, may be empty string
			Set tSoapAction=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,"soapAction"))
			// Default suppress adding URLESCAPESOAPACTION parameter if the only differences for ALL soapActons are as below.
			// ":/#?&" - Ignoring URL tokens 
			// "/=" - Ignoring Base64 tokens (except "+" which unescapes to " ")
			// Rationale: URL unescaping these literals results in same value.
			// Avoids unnecessary change for existing customer WSDL UnitTests and regenerated soap clients.
			// Reported problem literals like space (" ") and percent ("%") will engage URL encode behavior.
			// If any soapAction requires escaping then ALL will be escaped when transmitted for generated class.
			// For lesser edge case, can manually override URLESCAPESOAPACTION parameter to "1" in generated class
			Set:'doesSoap11ActionRequireURLEncoding doesSoap11ActionRequireURLEncoding=($ZCVT($TR(tSoapAction,":#?&/="),"O","URL")'=$TR(tSoapAction,":#?&/="))

 			#; Get the optional ParameterOrder (NMTOKENS)
			Set tParameterOrder=..NormalizeTokens($listget($Get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation)),1))
 
 			#; Create the method definition correspoding to the operation
 			Set methodIndex=methodIndex+1
 			Set tSC=..CreateMDef(%clientCDef,MethodNames(methodIndex),.%clientMDef)
 			If $$$ISERR(tSC) Quit
 			Set tSC=..CreateMDef(%serviceCDef,MethodNames(methodIndex),.%serviceMDef)
 			If $$$ISERR(tSC) Quit
 			
 			#; These local arrays will record the soap parameters and the formal parameters
			Kill tSoapParms,tFormalParms

 			#; Process the operation messages for this port
			Set tOpMsg=""
		    For {
				Set tOpMsg=$Order(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg))
				If tOpMsg="" Quit
			    If $extract(tOpMsg)="%" Continue
 				#; Get the body use -- already validated.
				Set tBodyUse=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"use"))

 				#; Get the (optional) namespace. WSDL spec declares that for encoded types the namespace only applies to elements
 				#; not specifically defined in the namespace which defines the encoded types.
				Set tNS=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"namespace"))
				If tNS="" Set tNS=pNamespace
				
				#; If all output namespaces are the same, then responseNamespaceValid=1
				#; and responseNamespace is set
				If (tOpMsg="output") && responseNamespaceValid {
					If responseNamespace="" {
						Set responseNamespace=tNS
					} Else {
						if responseNamespace'=tNS Set responseNamespaceValid=0
					}
				}

				#; The Namespace (if present) is specified at the msg level, not the operation level so we need to make sure
 				#; that they are the same for both input and output
				If $Data(tSoapParms("Namespace")) {
					if (tSoapParms("Namespace")'=tNS) && (namespaceNoMatchOperation="") {
				 		Set namespaceNoMatchOperation=tOperation
					}
				} else {
					Set tSoapParms("Namespace")=tNS
				}

 				#; Inspect and cross-reference message definition
				Set tMessageName=^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg)
				Set tMessageNS=$List(tMessageName,1)
				Set tMessageAction=$listget(tMessageName,3)
				Set tMessageName=$List(tMessageName,2)
				Set tOpMsgName(tOpMsg)=tMessageName
				
				#; Save Action attributes from portType input and output elements
				If tMessageAction'="" {
					If tOpMsg="input" Set Actions(MethodNames(methodIndex),"request")=tMessageAction
					If tOpMsg="output" Set Actions(MethodNames(methodIndex),"response")=tMessageAction
				}

 				#; Get the formal parms from the set of messages
				Merge tFormalParms(tOpMsg)=^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName)
				
				#; If MakeMessageStyle=0 (wrapped), then ignore parts of the message that are declared 
				#; as MIME parts by the MIME binding
				If '..MakeMessageStyle {
					Set part=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"mimeparts",""))
					While part'="" {
						For tI=1:1:tFormalParms(tOpMsg) {
							Set partname=tFormalParms(tOpMsg,tI)
							If partname=part {
								For tJ=tI:1:tFormalParms(tOpMsg)-1 {
									Kill tFormalParms(tOpMsg,tJ)
									Merge tFormalParms(tOpMsg,tJ)=tFormalParms(tOpMsg,tJ+1)
								}
								Kill tFormalParms(tOpMsg,tFormalParms(tOpMsg))
								Set tFormalParms(tOpMsg)=tFormalParms(tOpMsg)-1
								Quit
							}
						}
						Set part=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"mimeparts",part))
					}
				}

 				#; Get the (optional) parts. Parts (if present) indicate which parts appear within the soap body. 
 				#; This is relevant when SOAP is used (for example) with the multipart/MIME binding. 
 				#; If parts is specified, verify that all parts of the message are specified.
				Set tParts=$Get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"parts"))
				if (tParts'="") && (tOpMsg'["header") {
					Kill distinctParts
					Set tSC=$$$OK
					#; Get distinct parts from list.
					For tI=1:1:$Length(tParts," ") {
						Set partname=$piece(tParts," ",tI)
						If '$data(distinctParts(partname)) {
							Set distinctParts(partname)=0
						} Else {
							#; Part multiply defined in list.
							Set tSC=$$$ERROR($$$WSDLBindingNotSupported,"wsdl:binding:operation:msg:"_partname)
							Quit
						}
					}
					If $$$ISERR(tSC) Quit
					#; Mark parts of message for removal that are not in parts list
					For tI=1:1:tFormalParms(tOpMsg) {
						Set partname=tFormalParms(tOpMsg,tI)
						If $get(distinctParts(partname)) {
							#; Part multiply defined in message.
							Set tSC=$$$ERROR($$$WSDLBindingNotSupported,"wsdl:binding:operation:msg:"_partname)
							Quit
						} ElseIf $data(distinctParts(partname)) {
							Set distinctParts(partname)=1
						} Else {
							#; Mark part for removal from message
							Set tFormalParms(tOpMsg,tI)=""
						}
					}
					If $$$ISERR(tSC) Quit
					Set tJ=0
					#; Remove parts from message that are marked
					For tI=1:1:tFormalParms(tOpMsg) {
						If tFormalParms(tOpMsg,tI)'="" {
							Set tJ=tJ+1
							If tI'=tJ {
								Merge tFormalParms(tOpMsg,tJ)=tFormalParms(tOpMsg,tI)
							}
						} Else {
							Kill tFormalParms(tOpMsg,tI)
						}
					}
					Set tFormalParms(tOpMsg)=tJ
					#; Check that all parts in the list are found in message
					For tI=1:1:$Length(tParts," ") {
						Set partname=$piece(tParts," ",tI)
						If 'distinctParts(partname) {
							#; Part from list is not defined.
							Set tSC=$$$ERROR($$$WSDLBindingNotSupported,"wsdl:binding:operation:msg:"_partname)
							Quit
						}
					}
					If $$$ISERR(tSC) Quit
				}

 				#; The SoapBindingStyle is specified at the msg level, not the operation level so we need to make sure
 				#; that they are the same for both input and output
				If $Data(tSoapParms("BindingStyle")) {
					if (tSoapParms("BindingStyle")'=tBindingStyle) {
						Set tSC=$$$ERROR($$$WSDLInconsistentForOperation,"wsdl:binding:operation","soap:bindingStyle",tOperation)
						Quit
					}
				} else {
					Set tSoapParms("BindingStyle")=tBindingStyle
				}

 				#; The SoapBodyUse is specified at the msg level, not the operation level so we need to make sure
 				#; that they are the same for both input and output			
				If $Data(tSoapParms("BodyUse")) {
					if (tSoapParms("BodyUse")'=tBodyUse) {
						Set tSC=$$$ERROR($$$WSDLInconsistentForOperation,"wsdl:binding:operation","soap:bodyUse",tOperation)
						Quit
					}
				} else {
					Set tSoapParms("BodyUse")=tBodyUse
				}
			}
			If $$$ISERR(tSC) Quit
		
			#; Find any header elements and make referenced classes inherit from %SOAP.Header.
			For tOpMsg="inputheader","outputheader" {
				Set message=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,""))
				While message'="" {
					Set tMessageNS=$list(message,1)
					Set tMessageName=$list(message,2)
					Set partName=$list(message,3)
					If (tMessageName'="") &&  (partName'="") {
						Set use=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,message,"use"))
						Set partindex=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"message",tMessageName,""))
						While partindex'="" {
							If partName=^IRIS.Temp(i%WSDLTarget,tBindingNS,"message",tMessageName,partindex) {
								Set tParmType=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"message",tMessageName,partindex,"type"))
								Set tParmElement=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"message",tMessageName,partindex,"element"))
								Set telement=(tParmType="")
								If telement Set tParmType=tParmElement
								Set tElementNamespace=$list(tParmType,1)
								Set tElementName=$list(tParmType,2)
								Do ..SchemaReader.MakeSOAPHeader(tElementNamespace,tElementName,'telement,use,.className)
								If telement {
									Set headerName=tElementName
									Set headerNamespace=tElementNamespace
								} Else {
									Set headerName=partName
									Set headerNamespace=tMessageNS
								}
								If className'="" {
									If tOpMsg["output",headerName'="CSPCHD" {
										Set SoapHeaders(MethodNames(methodIndex),"response",headerNamespace,headerName)=className
									}
									If tOpMsg["input" Set SoapHeaders(MethodNames(methodIndex),"request",headerNamespace,headerName)=className
								}
								Quit
							}
							Set partindex=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"message",tMessageName,partindex))
						}
					}
					Set message=$order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,message))
				}
			}
 
 			#; Set the SoapBindingStyle and the SoapBodyUse
 			Do ..SetMethodProperty("SoapBindingStyle",$get(tSoapParms("BindingStyle")))
 			Do ..SetMethodProperty("SoapBodyUse",$get(tSoapParms("BodyUse")))

			#; Set method description from portType operation documentation element 			
			Set description=$listget($Get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation)),2)
			If description'="" {
	 			Do ..SetMethodProperty("Description",description)
			}
 			
			
			#; Set the (optional) SoapNameSpace and SoapTypeNameSpace
			If ($get(tSoapParms("Namespace"))'="") {
				Set tNS=tSoapParms("Namespace")
				If (tNS'=pNamespace) {
					Do ..SetMethodProperty("SoapNameSpace",tNS)
				}
			} Else {
				Set tNS=pNamespace
			}
			If (classTypeNamespace=$char(1)) {
				Set methodTypeNamespace=$get(typeNamespace(methodIndex))
				If (methodTypeNamespace'=$char(1)) && (methodTypeNamespace'=tNS) &&
				   ('..MakeMessageStyle || (tSoapParms("BindingStyle")'="document")) {
					Do ..SetMethodProperty("SoapTypeNameSpace",methodTypeNamespace)
				}
			} Else {
				Set methodTypeNamespace=classTypeNamespace
			}
			
			#; Set the default wrapping element name
			Set methodElement=tOperation
			Set (responseElement,defaultResponseElement)=MethodNames(methodIndex)_"Response"
			
 			#; Document style, extracted directly from document style operation messages
 			#; this must be transformed into the RPC style format before further processing
  
 			#; tFormalParms("input")=1
 			#; tFormalParms("input",1)=parameters
 			#; tFormalParms("input",1,"element")=$LB(http:#;www.tempuri.org,multiply)
 			#; tFormalParms("output")=1
 			#; tFormalParms("output",1)=parameters
 			#; tFormalParms("output",1,"element")=$LB(http:#;www.tempuri.org,multiplyResponse)

  		    #; RPC style, Formal Parameters extracted directly from operation messages
 
 			#; tFormalParms("input")=2
 			#; tFormalParms("input",1)=a
 			#; tFormalParms("input",1,"type")=$LB(http:#;www.w3.org/2001/XMLSchema,long)
 			#; tFormalParms("input",2)=b
 			#; tFormalParms("input",2,"type")=$LB(http:#;www.w3.org/2001/XMLSchema,long)
 			#; tFormalParms("output")=1
 			#; tFormalParms("output",1)=MultiplyResult
 			#; tFormalParms("output",1,"type")=$LB(http:#;www.w3.org/2001/XMLSchema,long)
 
 			Set inputElementNamespace=""
			For tDirection="input","output" {
				For tI=1:1:+$get(tFormalParms(tDirection)) {
					Set tParmType=$get(tFormalParms(tDirection,tI,"type"))
					Set tParmElement=$get(tFormalParms(tDirection,tI,"element"))
			 		If (tParmElement="") && (tParmType="") {
						Set tSC=$$$ERROR($$$WSDLPartElement,"wsdl:part",tMessageName)
						Quit
					}
			 		If (tParmElement'="") && (tParmType'="") {
				 		Set tSC=$$$ERROR($$$WSDLPartAttribute,"wsdl:part",tMessageName)
				 		Quit
			 		}
					Set xmlelement=(tParmType="")
					If xmlelement Set tParmType=tParmElement

					If tSoapParms("BindingStyle")="document" {
						If '..MakeMessageStyle {
							#; More than one part not supported unless MakeMessageStyle
							If tFormalParms(tDirection)>1 {
								Set tSC=$$$ERROR($$$WSDLMessageStyleNeeded,"wsdl:binding:operation:msg:"_tDirection,tMessageName)
								Quit
							}

	 						#; Need to transform Document style FormalParms into RPC style format
							//If $Get(tFormalParms(tDirection,tI))'="parameters" {
							If $Get(tFormalParms(tDirection,tI))="" {
								Set tSC=$$$ERROR($$$WSDLLiteralEncodingParams,"wsdl:binding:operation:msg:"_tDirection,tMessageName)
								Quit
							}

	 						#; Pick out the element namespace and name
							Set tElementNamespace=$List(tParmType,1)
							Set tElementName=$List(tParmType,2)
							Set MessageClassList(tElementName)=""
						
							#; If document/literal and element name specified,
							#; then use this name for the message element
							If xmlelement && (tDirection="input") {
								Set methodElement=tElementName
							}

							#; If all output type namespaces are the same, then responseTypeNamespaceValid=1
							#; and responseTypeNamespace is set
							If (tDirection="input") {
								Set inputElementNamespace=tElementNamespace
							}
							If (tDirection="output") {
								If responseTypeNamespaceValid {
									If responseTypeNamespace="" {
										Set responseTypeNamespace=tElementNamespace
									} Else {
										if (responseTypeNamespace'=tElementNamespace) { 
											Set responseTypeNamespaceValid=0
										}
									}
								}
								If tElementNamespace'=inputElementNamespace {
									Set typeNamespaceNoMatchOperation=tOperation
								}
								If xmlelement {
									Set responseElement=tElementName
								}
							}
						
	 						#; Now search the schemas and form parameter list
							Kill tOutput
							Set tSC=..SchemaReader.GetElementProperties(tElementNamespace,tElementName,.tOutput,.parameterType,.elno,'xmlelement)
							If $$$ISERR(tSC) Quit

					 		#; Remove message classes from schema
					 		If parameterType'="" {
								Kill ..TypeClassList(parameterType)
								Do ..SchemaReader.RemoveClassFromList(elno)
					 		}

							Kill tFormalParms(tDirection)
							Merge tFormalParms(tDirection)=tOutput
						} Else {
							Set needArgumentStyle=1
							set refnamespace=""
							Set tFormalParms(tDirection,tI) = 
							  ..SchemaReader.MakePropName(tFormalParms(tDirection,tI),.xmlname)
							Set tCacheType=""
							If xmlelement {
								Set tSC=..GetCacheElement($List(tParmType,1),$List(tParmType,2),.tCacheType,.tTypeNamespace,.cls)
								Set xmlname=$List(tParmType,2)
								If xmlname=tFormalParms(tDirection,tI) Set xmlname=""
								If tTypeNamespace'=$List(tParmType,1) {
									Set refnamespace=$List(tParmType,1)
								}
							} Else {
								Set tSC=..GetCacheType($List(tParmType,1),$List(tParmType,2),.tCacheType,.cls)
							}
							If $$$ISERR(tSC) Quit
							Set tParmPersistent=((cls'="")&&(..SchemaReader.FindClassType(cls)="persistent"))
							If (xmlname'="") || (refnamespace'="") {
								Set tCacheType=tCacheType_"("
								If xmlname'="" Set tCacheType=tCacheType_"XMLNAME="""_xmlname_""","
								If refnamespace'="" {
									Set tCacheType=tCacheType_"XMLREF=1,REFNAMESPACE="""_refnamespace_""","
								}
								Set $extract(tCacheType,$length(tCacheType))=")"
							}
							Set tFormalParms(tDirection,tI,"type") = tCacheType
							Set tFormalParms(tDirection,tI,"persistent") = tParmPersistent
							Set tFormalParms("output",1,"message")=1
						}
					} Else {
						Set tFormalParms(tDirection,tI) = 
						  ..SchemaReader.MakePropName(tFormalParms(tDirection,tI),.xmlname)
						Set tCacheType=""
						If xmlelement {
							Set tSC=..GetCacheElement($List(tParmType,1),$List(tParmType,2),.tCacheType,,.cls)
							Set xmlname=$List(tParmType,2)
						} Else {
							Set tSC=..GetCacheType($List(tParmType,1),$List(tParmType,2),.tCacheType,.cls)
						}
						If $$$ISERR(tSC) Quit
						Set tParmPersistent=((cls'="")&&(..SchemaReader.FindClassType(cls)="persistent"))
						If classElement="" {
							Set elementref=(xmlelement'=(tSoapParms("BodyUse")="literal"))
						} Else {
							Set elementref=(xmlelement'=classElement)
						}
						If (xmlname'="") || elementref {
							Set tCacheType=tCacheType_"("
							If xmlname'="" Set tCacheType=tCacheType_"XMLNAME="""_xmlname_""","
							If elementref {
								Set tCacheType=tCacheType_"XMLREF="_xmlelement_","
								If xmlelement {
									Set ns=$List(tParmType,1)
									If methodTypeNamespace'=ns {
										Set tCacheType=tCacheType_"REFNAMESPACE="""_ns_""","
								 		Set elementQualified=..SchemaReader.GetElementQualified(ns)
										If (elementQualified'="") Set tCacheType=tCacheType_"REFELEMENTQUALIFIED="_elementQualified_","
									}
								}
							}
							Set $extract(tCacheType,$length(tCacheType))=")"
						}
						Set tFormalParms(tDirection,tI,"type") = tCacheType
						Set tFormalParms(tDirection,tI,"persistent") = tParmPersistent
						If (tDirection="output") && (tI=1) {
							Set tFormalParms("output",1,"required")=1
						}

					}
				}
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
			
 			#; Compose the Args array
			Kill tArgs Set tArgs = 0
 			Set numOutput=+$Get(tFormalParms("output"))
 			Set iOutput=0
			Set tReturnType=""
			For tI=1:1:+$Get(tFormalParms("input")) {

 				#; Pick out the parameter name and type			
				Set tParmName=tFormalParms("input",tI)
				Set tCacheType=tFormalParms("input",tI,"type")
				Set tCacheTypePersistent=tFormalParms("input",tI,"persistent")
				Set tRequired=$get(tFormalParms("input",tI,"required"))

 				#; Is the name defined in the output list too? If so the parameter is a reference parameter			
				Set tByRef=0 For tJ=(iOutput+1):1:+$Get(tFormalParms("output")) {
					If (tFormalParms("output",tJ)=tParmName) &&
					   (tFormalParms("output",tJ,"type")=tFormalParms("input",tI,"type")) {
						Set tByRef=1 Quit
					}
				}
				
				#; If requested replace base64Binary with a stream
				If ..BinaryAsStream,tCacheType["%xsd.base64Binary",tCacheType'["XMLPROJECTION=""attribute""" {
					Set tCacheType=$replace(tCacheType,"%xsd.base64Binary","%Stream.GlobalBinary")
				}
				
				#; If we find a ByRef argument, then put the earlier output arguments in the list
				If tByRef,tCacheType'["XMLPROJECTION=""attribute""" {
					For {
						Set iOutput=iOutput+1
						If iOutput>=tJ Quit

		 				#; Pick out the output parameter name			
						Set oParmName=tFormalParms("output",iOutput)
						Set oCacheType=tFormalParms("output",iOutput,"type")
						Set oCacheTypePersistent=tFormalParms("output",iOutput,"persistent")
						Set required=$get(tFormalParms("output",iOutput,"required"))

	 					#; The first output parameter that does not appear in the input list is the return type
						If (iOutput=1) && ($get(tFormalParms("output",1,"required")) || (numOutput=1)) {
							Set tReturnType=oCacheType
							Set tReturnTypePersistent=tCacheTypePersistent
							If $get(tFormalParms("output",1,"message")) || (oParmName'=(MethodNames(methodIndex)_"Result")), 
							   (tReturnType'["(XMLNAME="),(tReturnType'[",XMLNAME=") {
								   If $extract(tReturnType,*)=")" {
									   Set $extract(tReturnType,$length(tReturnType))=","
								   } Else {
									   Set tReturnType=tReturnType_"("
								   }
								   Set tReturnType=tReturnType_"XMLNAME="""_oParmName_""")"
							}
							Set tReturnParmName=##class(%SOAP.WebBase).NormalizeName(oParmName)
						} else {
	 						#; others are indeed output parameters
							Set tArgs($Increment(tArgs))=$ListBuild(oParmName,"*",oCacheType,required,oCacheTypePersistent)
						}
					}
				}
				
 				#; Record Arg details
				Set tArgs($Increment(tArgs))=$ListBuild(tParmName,$select(tByRef:"&",1:""),tCacheType,tRequired,tCacheTypePersistent)
			}
			
			#; Put the remainder of the output arguments in the list
			For {
				Set iOutput=iOutput+1
				If iOutput>numOutput Quit

 				#; Pick out the output parameter name			
				Set oParmName=tFormalParms("output",iOutput)
				Set oCacheType=tFormalParms("output",iOutput,"type")
				Set oCacheTypePersistent=tFormalParms("output",iOutput,"persistent")
				Set required=$get(tFormalParms("output",iOutput,"required"))

 				#; Is the name defined in the input list too? If so the parameter is a reference parameter
 				#; and has already been accounted for			
				Set tByRef=0 For tJ=1:1:+$Get(tFormalParms("input")) {
					If (tFormalParms("input",tJ)=oParmName) &&
					   (tFormalParms("input",tJ,"type")=tFormalParms("output",iOutput,"type")) {
						Set tByRef=1 Quit
					}
				}
				
				#; If requested replace base64Binary with a stream
				If ..BinaryAsStream,oCacheType["%xsd.base64Binary",oCacheType'["XMLPROJECTION=""attribute""" {
					Set oCacheType=$replace(oCacheType,"%xsd.base64Binary","%Stream.GlobalBinary")
				}
				
				If (tByRef=0) {

					#; The first output parameter that does not appear in the input list is the return type
					If (iOutput=1) && (required || (numOutput=1)) {
						Set tReturnType=oCacheType
						Set tReturnTypePersistent=oCacheTypePersistent
						If $get(tFormalParms("output",1,"message")) || (oParmName'=(MethodNames(methodIndex)_"Result")), 
						   (tReturnType'["(XMLNAME="),(tReturnType'[",XMLNAME=") {
							   If $extract(tReturnType,*)=")" {
								   Set $extract(tReturnType,$length(tReturnType))=","
							   } Else {
								   Set tReturnType=tReturnType_"("
							   }
							   Set tReturnType=tReturnType_"XMLNAME="""_oParmName_""")"
						}
						Set tReturnParmName=##class(%SOAP.WebBase).NormalizeName(oParmName)
					} else {
						#; others are indeed output parameters
						Set tArgs($Increment(tArgs))=$ListBuild(oParmName,"*",oCacheType,required,oCacheTypePersistent)
					}
				}
			}

 			#; Now apply the parameter order
			if (tParameterOrder'="") && (tSoapParms("BindingStyle")="rpc"){
				Kill tNewArgs 
				Set tNewArgs=0
				For tI=1:1:$Length(tParameterOrder," ") {
					Set tParmName=..SchemaReader.MakePropName($Piece(tParameterOrder," ",tI),.xmlname)
					For tJ=1:1:tArgs {
						If $List(tArgs(tJ),1)=tParmName Set tNewArgs($Increment(tNewArgs))=tArgs(tJ)
					}
				}
				If tArgs'=tNewArgs {
					Set tSC=$$$ERROR($$$WSDLParmCountMismatch,"wsdl:operation",tOperation)
					Quit
				}
				Kill tArgs Merge tArgs=tNewArgs Kill tNewArgs
			}
			
			#; Adjust duplicate parameter names
			Set pnames=$Get(tArgs)
			For tI=1:1:$Get(tArgs) Set pnames(tI)=$List(tArgs(tI),1)
			Do ..fixNames($$$MAXVARIABLELENGTH,.pnames)
			For tI=1:1:$Get(tArgs) {
				If $List(tArgs(tI),1)'=pnames(tI) {
					Set type=$List(tArgs(tI),3)
					If type["(" {
						If (type'["(XMLNAME=") && (type'[",XMLNAME=") {
							Set $extract(type,$length(type))=""
							Set type=type_",XMLNAME="""_$List(tArgs(tI),1)_""")"
						}
					} Else {
						Set type=type_"(XMLNAME="""_$List(tArgs(tI),1)_""")"
					}
					Set $List(tArgs(tI),3)=type
					Set $List(tArgs(tI),1)=pnames(tI)
					
				}
			}

 			#; Generate the code
			Set tFormalSpec=""
			If tReturnType'="" {
				Set clientCode=" Quit "
			} else {
				Set clientCode=" Do ("
			}
			If methodElement'=tOperation {
				Set clientCode=clientCode_"..WebMethod("""_tOperation_""","""_methodElement_""")"
			} Else {
				Set clientCode=clientCode_"..WebMethod("""_tOperation_""")"
			}
			If tReturnType="" Set clientCode=clientCode_")"
			Set clientCode=clientCode_".Invoke($this,"""_tSoapAction_""""
			For tI=1:1:$Get(tArgs) {
				Set argName=##class(%SOAP.WebBase).NormalizeName($List(tArgs(tI),1))
				Set argType=$List(tArgs(tI),3)
				Set tFormalSpec=tFormalSpec_$List(tArgs(tI),2)_argName
				If $List(tArgs(tI),1)'=argName {
					Set argType=$List(tArgs(tI),3)
					If $extract(argType,*)=")" {
						If (argType'["(XMLNAME=") && (argType'[",XMLNAME=") {
							Set $extract(argType,$length(argType))=""
							Set argType=argType_",XMLNAME="""_$List(tArgs(tI),1)_""")"
						}
					} Else {
						Set argType=argType_"(XMLNAME="""_$List(tArgs(tI),1)_""")"
					}
				}
				Set tFormalSpec=tFormalSpec_":"_argType
				If $List(tArgs(tI),4) {
					If $extract(tFormalSpec,*)=")" {
						Set tFormalSpec=$extract(tFormalSpec,1,*-1)_",REQUIRED=1)"
					} Else {
						Set tFormalSpec=tFormalSpec_"(REQUIRED=1)"
					}
				}
				Set tFormalSpec=tFormalSpec_","
				Set clientCode=clientCode_",."_##class(%SOAP.WebBase).NormalizeName($List(tArgs(tI),1))
			}
			Set clientCode=clientCode_")",$Extract(tFormalSpec,$Length(tFormalSpec))=""

			#; Set return type
			If $get(tFormalParms("output"))'="" {
				If ($length(tReturnType,"(")=1) {
					Do ..SetMethodProperty("ReturnType",tReturnType)
				} Else {
					Do ..SetMethodProperty("ReturnType",$piece(tReturnType,"(",1))
					Do ..SetMethodProperty("ReturnTypeParams",$piece($piece(tReturnType,"(",2),")",1))
				}
			} Else {
				#; One-way SOAP message is no output message is specified.
				#; Mark with %SOAP.OneWay return type
				Do ..SetMethodProperty("ReturnType","%SOAP.OneWay")
			}

 			#; Add the method to the class definition
			Do ..SetMethodProperty("FormalSpec",tFormalSpec)
			Do ..SetMethodProperty("CodeMode","code")
			If %clientMDef'="" {
				Set tSC=%clientMDef.Implementation.WriteLine(clientCode)
				If $$$ISERR(tSC) Quit
 				Do %clientCDef.Methods.Insert(%clientMDef)
			}
			If %serviceMDef'="" {
				Do ..SetMethodProperty("SoapAction",tSoapAction,%serviceMDef)
				If methodElement'=tOperation {
					Do ..SetMethodProperty("SoapRequestMessage",methodElement,%serviceMDef)
				}
				If responseElement'=defaultResponseElement {
					Do ..SetMethodProperty("SoapMessageName",responseElement,%serviceMDef)
				}
				Set tSC=%serviceMDef.Implementation.WriteLine(" // Web Service Method Implementation Goes Here." )
				If $$$ISERR(tSC) Quit
 				Do %serviceCDef.Methods.Insert(%serviceMDef)
			}
 			
	 		#; Add a method and associated request/response to the Ensemble Business Operation, if requested
	 		If makeEnsemble {
				Set tBOMethodSpec=tBOClassName_":"_MethodNames(methodIndex)
	 			Set tBORequestName=requestPkg_"."_MethodNames(methodIndex)_"Request"
	 			Set tBOResponseName=responsePkg_"."_MethodNames(methodIndex)_"Response"
				Kill %objlasterror
				Set tBOMDef=##class(%Dictionary.MethodDefinition).%New(tBOMethodSpec)
	 			If tBOMDef=$$$NULLOREF {
		 			Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,"Method "_tBOMethodSpec))
		 			Quit
	 			}
	 			
	 			Set tBOMDef.Private=0
	 			Set tBOMDef.ClassMethod=0
	 			
	 			#; Generate code for arguments
	 			Set tBOMarshal=""
				If tReturnType'="" {
					Set tBOArgList=",."_tReturnParmName
					Set tBOUnMarshal="pResponse."_tReturnParmName_"=$get("_tReturnParmName_"),"
				} Else {
					Set tBOArgList=","
					Set tBOUnMarshal=""
				}
				For tI=1:1:$Get(tArgs) {
					Set tBOArgName=##class(%SOAP.WebBase).NormalizeName($List(tArgs(tI),1))
					If $list(tArgs(tI),2)'="" {
						If $list(tArgs(tI),2)="&" {
							Set tBOMarshal=tBOMarshal_tBOArgName_"=pRequest."_tBOArgName_","
						}
						Set tBOArgList=tBOArgList_",."_tBOArgName
						Set tBOUnMarshal=tBOUnMarshal_"pResponse."_tBOArgName_" = $get("_tBOArgName_"),"
					} Else {
						Set tBOArgList=tBOArgList_",pRequest."_tBOArgName
					}
				}

				#; Set method return type and arguments
				Set tBOMDef.ReturnType="%Library.Status"
				Set tBOMDef.FormalSpec="pRequest:"_tBORequestName_",*pResponse:"_tBOResponseName
				Set tBOMDef.CodeMode="code"
				Set tSC=tBOMDef.Implementation.WriteLine(" Set ..Adapter.WebServiceClientClass = """_ClientClassName_"""")
				If $$$ISERR(tSC) Quit
				If tBOMarshal'="" {
					Set $extract(tBOMarshal,$length(tBOMarshal))=""
					Set tSC=tBOMDef.Implementation.WriteLine(" Set "_tBOMarshal)
					If $$$ISERR(tSC) Quit
				}
				Set tSC=tBOMDef.Implementation.WriteLine(" Set tSC = ..Adapter.InvokeMethod("""_MethodNames(methodIndex)_""""_tBOArgList_")  Quit:$$$ISERR(tSC) tSC")
				If $$$ISERR(tSC) Quit
				Set tSC=tBOMDef.Implementation.WriteLine(" Set tSC = pRequest.NewResponse(.pResponse)  Quit:$$$ISERR(tSC) tSC")
				If $$$ISERR(tSC) Quit
				If tBOUnMarshal'="" {
					Set $extract(tBOUnMarshal,$length(tBOUnMarshal))=""
					Set tSC=tBOMDef.Implementation.WriteLine(" Set "_tBOUnMarshal)
					If $$$ISERR(tSC) Quit
				}
				Set tSC=tBOMDef.Implementation.WriteLine(" Quit $$$OK")
				If $$$ISERR(tSC) Quit
	 			Do tBODef.Methods.Insert(tBOMDef)
	 			
	 			#; Message map for request class
				Set tSC=tXData.Data.WriteLine($c(9)_"<MapItem MessageType="""_tBORequestName_""">") If $$$ISERR(tSC) Quit
				Set tSC=tXData.Data.WriteLine($c(9,9)_"<Method>"_MethodNames(methodIndex)_"</Method>") If $$$ISERR(tSC) Quit
				Set tSC=tXData.Data.WriteLine($c(9)_"</MapItem>") If $$$ISERR(tSC) Quit

	 			#; Create the request class
			 	Do Delete^%apiOBJ(tBORequestName,"-d")
		 		Set tBORequestDef=##class(%Dictionary.ClassDefinition).%New(tBORequestName)
		 		If tBORequestDef=$$$NULLOREF {
			 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,tBORequestName))
			 		Quit
		 		}
	 			Set tBORequestDef.ProcedureBlock=1
				#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
				Set tBORequestDef.ClassVersion=25
		 		Set tBORequestDef.Super="Ens.Request"
		 		Set tSeqNo=1
		 		Set tSC=..CreateParameter(tBORequestDef,"RESPONSECLASSNAME",tBOResponseName,"",tSeqNo)
		 		If $$$ISERR(tSC) Quit
		 		Kill persistentProperties
				For tI=1:1:$Get(tArgs) {
					#; Exclude Output Arguments from Ens.Request subclass. ("*"==Output, "&"==ByRef and ""==Input)
					If $list(tArgs(tI),2)'="*" {
						Set tBOArgName=##class(%SOAP.WebBase).NormalizeName($List(tArgs(tI),1))
						Set tSeqNo=tSeqNo+1
			 			Set tSC=..CreateProperty(tBORequestName,tBORequestDef,tBOArgName,$list(tArgs(tI),3),tSeqNo,$list(tArgs(tI),5),.persistentProperties)
			 			If $$$ISERR(tSC) Quit
					}
				}
				If ..CascadeDeletes {
					Set tSC=##class(%XML.Utils.SchemaResult).AddOnDeleteMethod(tBORequestDef,.persistentProperties,tSeqNo)
			 		If $$$ISERR(tSC) Quit
				}
				Set tBORequest(methodIndex)=tBORequestDef
	 			Set ..BOClassList(tBORequestName)=""

	 			#; Create the response class
			 	Do Delete^%apiOBJ(tBOResponseName,"-d")
		 		Set tBOResponseDef=##class(%Dictionary.ClassDefinition).%New(tBOResponseName)
		 		If tBOResponseDef=$$$NULLOREF {
			 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,tBOResponseName))
			 		Quit
		 		}
	 			Set tBOResponseDef.ProcedureBlock=1
				#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
				Set tBOResponseDef.ClassVersion=25
		 		Set tBOResponseDef.Super="Ens.Response"
		 		Set tSeqNo=1
		 		Kill persistentProperties
				If tReturnType'="" {
					Set tSeqNo=tSeqNo+1
			 		Set tSC=..CreateProperty(tBOResponseName,tBOResponseDef,tReturnParmName,tReturnType,tSeqNo,tReturnTypePersistent,.persistentProperties)
			 		If $$$ISERR(tSC) Quit
				}
				For tI=1:1:$Get(tArgs) {
					If $list(tArgs(tI),2)'="" {
						Set tBOArgName=##class(%SOAP.WebBase).NormalizeName($List(tArgs(tI),1))
						Set tSeqNo=tSeqNo+1
				 		Set tSC=..CreateProperty(tBOResponseName,tBOResponseDef,tBOArgName,$list(tArgs(tI),3),tSeqNo,$list(tArgs(tI),5),.persistentProperties)
				 		If $$$ISERR(tSC) Quit
					}
				}
				If ..CascadeDeletes {
					Set tSC=##class(%XML.Utils.SchemaResult).AddOnDeleteMethod(tBOResponseDef,.persistentProperties,tSeqNo)
			 		If $$$ISERR(tSC) Quit
				}
				Set tBOResponse(methodIndex)=tBOResponseDef
	 			Set ..BOClassList(tBOResponseName)=""
	 		}

 			#; Get the next operation
			Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation))
		}
		If $$$ISERR(tSC) Quit

		// For Soap1.1 clients, if SoapAction contains characters that should be URL escaped, AND wizard is enabled
		// to escape SoapAction Header when transmitting, then override Client Parameter to enable URL escaping behavior.
		// Only overrides parameter when needed, to prevent unnecessary source control change in customer 
		// regenerated SOAP clients. Also mitigates changes to dependent UnitTests that generate Clients from WSDL.
		If ((%clientCDef'="")&&(doesSoap11ActionRequireURLEncoding)&&(soapVersion="1.1")&&(..ClientURLEscapeSoapAction)) {
			Set tSC=..CreateParameter(%clientCDef,"URLESCAPESOAPACTION",1,"Send URL ESCAPED SOAPAction Header for SOAP 1.1.")
			If $$$ISERR(tSC) Quit
		}

		#; Deal with input and output namespace not matching
		If (namespaceNoMatchOperation'="") {
			If responseNamespaceValid {
	 			#; Create the RESPONSENAMESPACE parameter
	 			Set tSC=..CreateParameter(,"RESPONSENAMESPACE",responseNamespace,"This is the namespace for all response messages.")
	 			If $$$ISERR(tSC) Quit
			} Else {
				#; Inconsistent namespace error
				Set tSC=$$$ERROR($$$WSDLInconsistentForOperation,"wsdl:binding:operation","soap:namespace",namespaceNoMatchOperation)
				Quit
			}
		}
		
		#; Deal with input and output type namespace not matching
		If (typeNamespaceNoMatchOperation'="") {
			If responseTypeNamespaceValid {
				If (responseTypeNamespace'="") && (responseTypeNamespace'=classTypeNamespace) {
		 			#; Create the RESPONSETYPENAMESPACE parameter
		 			Set tSC=..CreateParameter(,"RESPONSETYPENAMESPACE",responseTypeNamespace,"This is the type namespace for all response messages.")
		 			If $$$ISERR(tSC) Quit
				}
			} Else {
				#; Inconsistent type namespace error
				Set tSC=$$$ERROR($$$WSDLInconsistentForOperation,"wsdl:binding:operation","soap:typenamespace",typeNamespaceNoMatchOperation)
				Quit
			}
		}
		
		#; Create the ARGUMENTSTYLE parameter
		If needArgumentStyle {
 			Set tSC=..CreateParameter(,"ARGUMENTSTYLE","message","Use unwrapped message style for document binding style.")
 			If $$$ISERR(tSC) Quit
		}

		If %clientCDef'="" {
			#; Create the SOAPHEADERS parameter
			Set tSC=..CreateSoapHeaders(%clientCDef,.SoapHeaders,.Actions)
 			If $$$ISERR(tSC) Quit
 			
 			#; Save the class definition
 			Set tSC=%clientCDef.%Save()
 			If $$$ISERR(tSC) Quit
		}
		
		If %serviceCDef'="" {
			#; Create the SOAPHEADERS parameter
			Set tSC=..CreateSoapHeaders(%serviceCDef,.SoapHeaders,.Actions)
 			If $$$ISERR(tSC) Quit
 			
 			#; Save the class definition
 			Set tSC=%serviceCDef.%Save()
 			If $$$ISERR(tSC) Quit
		}

 		If makeEnsemble {
	 		#; Finish XData
			Set tSC=tXData.Data.WriteLine("</MapItems>")
			If $$$ISERR(tSC) Quit
	 		Do tBODef.XDatas.Insert(tXData)
	 		#; Save Business Operation
	 		Set tSC=tBODef.%Save()
	 		If $$$ISERR(tSC) Quit
	 		#; Save Request and Response classes
	 		For tI=1:1:methodIndex {
		 		Set tSC=tBORequest(tI).%Save()
		 		If $$$ISERR(tSC) Quit
		 		Set tSC=tBOResponse(tI).%Save()
		 		If $$$ISERR(tSC) Quit
	 		}
	 		If $$$ISERR(tSC) Quit
 		}
 		
 		#; Create configuration class if any Policy found
 		If $get(^IRIS.Temp(i%WSDLTarget,"%anyPolicy")) {
	 		For CDef=%clientCDef,%serviceCDef {
		 		If CDef="" Continue
		 		
		 		Set ClassName=CDef.Name
		 		If ..ConfigPackage="" {
			 		Set configClassname=ClassName_"Config"
		 		} Else {
					Set classPackage=$piece(ClassName,".",1,$length(ClassName,".")-1)
			 		Set configClassname=classPackage_"."_..ConfigPackage_"."_$piece(ClassName,".",$length(ClassName,"."))
		 		}
 		
 				Set tSC=..CreateConfigurationClass(pService,pNamespace,pPort,ClassName,configClassname)
		 		If $$$ISERR(tSC) Quit
	 		}
	 		If $$$ISERR(tSC) Quit
 		}

	} while(0)
 	Quit tSC
}

/// Create a configuration class based on the policies in the WSDL<br><br>
/// <pre>
/// Parsed policies
/// 	  ^IRIS.Temp(key,namespace)
/// 	  ^IRIS.Temp(key,namespace,"service",servicename)
/// 	  ^IRIS.Temp(key,namespace,"service",servicename,"port",portname)
/// 	  ^IRIS.Temp(key,namespace,"binding",bindingname)
/// 	  ^IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname)
/// 	  ^IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"input")
/// 	  ^IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"output")
/// 	  ^IRIS.Temp(key,namespace,"portType",porttypename)
/// 	  ^IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname)
/// 	  ^IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"input")
/// 	  ^IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"output")
/// 	  ^IRIS.Temp(key,namespace,"message",msgname)
/// </pre>
Method CreateConfigurationClass(pService As %String, pNamespace As %String, pPort As %String, className As %String, configClassname As %String) [ Internal ]
{
	#; Get the binding
	Set tBinding=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"binding")
	Set tBindingNS=$List(tBinding,1)
	Set tBindingName=$List(tBinding,2)

	#; Inspect and cross-reference the port
	Set tPortType=$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"portType"))
	Set tPortTypeNS=$listget(tPortType,1),tPortTypeName=$listget(tPortType,2)
	If (tPortType="") || '$Data(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName)) {
		Quit $$$ERROR($$$WSDLNoCorrespondence,"wsdl:binding","portType definition",tPortTypeName_" : "_tPortTypeNS)
	}

	#; Delete any pre-existing definition
 	Do Delete^%apiOBJ(configClassname,"-d")

	#; Create a new class definition
	Kill %objlasterror
	Set tCDefConfig=##class(%Dictionary.ClassDefinition).%New(configClassname)
	If tCDefConfig=$$$NULLOREF {
 		Quit $Get(%objlasterror,$$$ERROR($$$FailedToCreateClass,configClassname))
	}
	Set ..ClientClassList(configClassname) = ""

	Set tCDefConfig.Super="%SOAP.Configuration"
	Set tCDefConfig.ProcedureBlock=1
	#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
	Set tCDefConfig.ClassVersion=25
	Set tSC=..CreateParameter(tCDefConfig,"REPORTANYERROR",0,"Ignore any alternatives in Policy that are not understood.")
	If $$$ISERR(tSC) Quit tSC

	For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,"%policy"),0) {
		Set xdata=##class(%Dictionary.XDataDefinition).%New(configClassname_":policy"_i)
		Set writer=##class(%XML.Writer).%New()
		Set writer.Indent=1
		Set writer.SuppressXmlns=1
		Set writer.NoXMLDeclaration=1
		Set tSC=writer.OutputToStream(.stream)
		If $$$ISERR(tSC) Quit

		Do writer.StartDocument()
		Do writer.AddNamespace($$$SOAPWSISCConfig,"cfg")
		Set desc=^IRIS.Temp(i%WSDLTarget,"%policy",i)
		Do ..WritePolicy(writer,desc,"")
		Do writer.EndDocument()
		Do stream.Rewind()
		Set xdata.Data=stream
 		Do tCDefConfig.XDatas.Insert(xdata)
	}
	If $$$ISERR(tSC) Quit tSC

	Set xdata=##class(%Dictionary.XDataDefinition).%New(configClassname_":service")
	Set writer=##class(%XML.Writer).%New()
	Set writer.Indent=1
	Set writer.SuppressXmlns=1
	Set writer.NoXMLDeclaration=1
	Set tSC=writer.OutputToStream(.stream)
	If $$$ISERR(tSC) Quit tSC
	Do writer.StartDocument()
	Do writer.AddNamespace($$$SOAPWSISCConfig,"cfg")

	Do writer.RootElement("configuration",$$$SOAPWSISCConfig)
	Do writer.WriteAttribute("name","service")
	Do writer.Element("service",$$$SOAPWSISCConfig)
	Do writer.WriteAttribute("classname",className)
	For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"%policy"),0) {
		Set desc=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"%policy",i)
		Set tSC=..WritePolicy(writer,desc,"service")
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC

	For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"%policy"),0) {
		Set desc=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",pPort,"%policy",i)
		Set tSC=..WritePolicy(writer,desc,"port")
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC

	For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"%policy"),0) {
		Set desc=^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"%policy",i)
		Set tSC=..WritePolicy(writer,desc,"binding")
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC

	For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"%policy"),0) {
		Set desc=^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"%policy",i)
		Set tSC=..WritePolicy(writer,desc,"portType")
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC

	Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",""))
	while (tOperation'="") {
		Do writer.Element("method",$$$SOAPWSISCConfig)
		Do writer.WriteAttribute("name",##class(%SOAP.WebBase).NormalizeName(tOperation,$$$MAXNAMELENGTH))

		For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,"%policy"),0) {
			Set desc=^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,"%policy",i)
			Set tSC=..WritePolicy(writer,desc,"binding")
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,"%policy"),0) {
			Set desc=^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,"%policy",i)
			Set tSC=..WritePolicy(writer,desc,"portType")
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	
		For tOpMsg="input","output" {
			Set type=$select(tOpMsg="input":"request",1:"response")
			For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"%policy"),0) {
				Set desc=^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation,tOpMsg,"%policy",i)
				If type'="" {
					Do writer.Element(type,$$$SOAPWSISCConfig)
					Set type=""
				}
				Set tSC=..WritePolicy(writer,desc,"binding")
				If $$$ISERR(tSC) Quit

			}
			If $$$ISERR(tSC) Quit

			For i=1:1:$get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg,"%policy"),0) {
				Set desc=^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg,"%policy",i)
				If type'="" {
					Do writer.Element(type,$$$SOAPWSISCConfig)
					Set type=""
				}
				Set tSC=..WritePolicy(writer,desc,"portType")
				If $$$ISERR(tSC) Quit

			}
			If $$$ISERR(tSC) Quit

			Set tMessageName=$get(^IRIS.Temp(i%WSDLTarget,tPortTypeNS,"portType",tPortTypeName,"operation",tOperation,tOpMsg))
			If tMessageName'="" {
				Set tMessageNS=$List(tMessageName,1)
				Set tMessageName=$List(tMessageName,2)
				For j=1:1:$get(^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName,"%policy"),0) {
					Set desc=^IRIS.Temp(i%WSDLTarget,tMessageNS,"message",tMessageName,"%policy",j)
					If type'="" {
						Do writer.Element(type,$$$SOAPWSISCConfig)
						Set type=""
					}
					Set tSC=..WritePolicy(writer,desc,"message")
					If $$$ISERR(tSC) Quit
				}
				If $$$ISERR(tSC) Quit
			}

			If type="" Do writer.EndElement()    ; request or response
		}
		If $$$ISERR(tSC) Quit

		Do writer.EndElement()	; method

		Set tOperation=$Order(^IRIS.Temp(i%WSDLTarget,tBindingNS,"binding",tBindingName,"operation",tOperation))
	}

	Do writer.EndElement()		; service
	Do writer.EndRootElement()		; configuration
	Do writer.EndDocument()
	
	If $$$ISERR(tSC) Quit tSC

	Do stream.Rewind()
	Set xdata.Data=stream
	Do tCDefConfig.XDatas.Insert(xdata)
	Set tSC=tCDefConfig.%Save()
	
	Quit tSC
}

/// Create the SOAPHEADERS parameter
Method CreateSoapHeaders(CDef As %Dictionary.ClassDefinition, ByRef SoapHeaders, ByRef Actions) As %Status [ Internal, Private ]
{
	Set sc=$$$OK

	If CDef'="",$data(SoapHeaders) || $data(Actions) {
		Kill loopref
		Set methodName=""
		For {
			Set methodName=$order(SoapHeaders(methodName))
			If methodName="" Quit
			If $data(SoapHeaders(methodName)) Set loopref(methodName)=""
			Set kind=""
			For {
				Set kind=$order(SoapHeaders(methodName,kind))
				If kind="" Quit
				If $data(SoapHeaders(methodName,kind)) Set loopref(methodName,kind)=""
			}
		}
		Set methodName=""
		For {
			Set methodName=$order(Actions(methodName))
			If methodName="" Quit
			Set kind=""
			For {
				Set kind=$order(Actions(methodName,kind))
				If kind="" Quit
				If $data(Actions(methodName,kind)) Set loopref(methodName,kind)=""
			}
		}
		
		Set xdata=##class(%Dictionary.XDataDefinition).%New(CDef.Name_":parameters")
		Set writer=##class(%XML.Writer).%New()
		Set writer.Indent=1
		Set writer.NoXMLDeclaration=1
		Set sc=writer.OutputToStream(.stream)
		If $$$ISERR(sc) Quit sc

		Do writer.StartDocument()
		Do writer.AddNamespace($$$SOAPWSISCConfig,"cfg")

		Do writer.RootElement("parameters",$$$SOAPWSISCConfig)
		Set methodName=""
		For {
			Set methodName=$order(loopref(methodName))
			If methodName="" Quit
			Do writer.Element("method",$$$SOAPWSISCConfig)
			Do writer.WriteAttribute("name",methodName)
			Set kind=""
			For {
				Set kind=$order(loopref(methodName,kind))
				If kind="" Quit
				Do writer.Element(kind,$$$SOAPWSISCConfig)
				If $get(Actions(methodName,kind))'="" {
					Do writer.Element("Action",$$$SOAPWSISCConfig)
					Do writer.WriteChars(Actions(methodName,kind))
					Do writer.EndElement()	; Action
				}
				Set namespace=""
				For {
					Set namespace=$order(SoapHeaders(methodName,kind,namespace))
					If namespace="" Quit
					Set name=""
					For {
						Set name=$order(SoapHeaders(methodName,kind,namespace,name),1,className)
						If name="" Quit
						Do writer.Element("header",$$$SOAPWSISCConfig)
						Do writer.WriteAttribute("name",name)
						Do writer.WriteAttribute("class",className)
						Do writer.EndElement()	; header
					}
				}
				Do writer.EndElement()	; request or response
			}
			Do writer.EndElement()	; method
		}
		Do writer.EndRootElement()		; parameters

		Do writer.EndDocument()
		Do stream.Rewind()
		Set xdata.Data=stream
 		Do CDef.XDatas.Insert(xdata)
	}

	Quit sc
}

/// Get ObjectScript type given namespace and typename
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetCacheType(pNamespace, pTypeName, ByRef pCacheType, Output cls) As %Status [ Internal, Private ]
{
 	Set tSC=$$$OK
 	do {
	 	// handle this directly using Reader
	 	
	 	Set tSC = ..SchemaReader.GetCacheType(pNamespace, pTypeName, .pCacheType, .cls)
	 	If $$$ISERR(tSC) Quit

		// pNamespace'=$$$XSDns
		If (pCacheType '[ "%") {
			// add class to list of type classes to generate
			Set ..TypeClassList(pCacheType) = ""
		}
 	} while(0)
 	Quit tSC
}

/// Get element given namespace and element name
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetCacheElement(pNamespace, pTypeName, ByRef pCacheType, ByRef pTypeNamespace As %String, Output cls) As %Status [ Internal, Private ]
{
 	Set tSC=$$$OK
 	do {
	 	// handle this directly using Reader
	 	
	 	Set tSC = ..SchemaReader.GetCacheElement(pNamespace, pTypeName, .pCacheType, .pTypeNamespace, .cls)
	 	If $$$ISERR(tSC) Quit

		// pNamespace'=$$$XSDns
		If pCacheType'="",pCacheType'["%" {
			// add class to list of type classes to generate
			Set ..TypeClassList(pCacheType) = ""
		}
 	} while(0)
 	Quit tSC
}

/// Validate if a URI
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsANYURI(pUri) [ Internal, Private ]
{
 	#; TO DO: Implement, for now assume match
 	Quit 1
}

/// Validate if string is an NCName
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsNCNAME(pName) As %Boolean [ Internal, Private ]
{
	#; [4]  NCName      ::=  (Letter | '_') (NCNameChar)* /*  An XML Name, minus the ":" */ 
	#; [5]  NCNameChar  ::=  Letter | Digit | '.' | '-' | '_' | CombiningChar | Extender 

 #;	Combining characters and Extender are characters within certain ranges specified by
 #;	the unicode statndard. We don't have anygood way of testing for these at present.
 
 #;	TO DO: Although the WSDL Schema mandates that names should be NCNAMES,
 #;	I've found at least one WSDL instance that violates this rule. For testing, the rule
 #;	will be relaxed to allow just about anything through for NOW
 	Quit 1
 	Set tGood=0
 	If $Extract(pName)?1(1A,1"_") {
		Set tGood=1
		For tI=2:1:$Length(pName) {
			If ($Extract(pName,tI)'?1(1A,1N,1".",1"-",1"_")) {
				Set tGood=0 Quit
		 	}
	 	}
 	}
 	Quit tGood
}

/// Validate if string is an Nmtoken
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsNMTOKEN(pName) As %Boolean [ Internal, Private ]
{
	#; [4]  NameChar    ::=     Letter | Digit | '.' | '-' | '_' | ':' | CombiningChar | Extender 
	#; [7]  Nmtoken     ::=    (NameChar)+ 
  #; Combining characters and Extender are characters within certain ranges specified by
  #; the unicode statndard. We don't have anygood way of testing for these at present.
 	Set tGood=0
 	if ($Length(pName)) {
		Set tGood=1 For tI=1:1:$Length(pName) {
			if ($Extract(pName,tI)'?1(1A,1N,1".",1"-",1"_",1":")) {
				Set tGood=0 Quit
			}
 		}
 	}
 	Quit tGood
}

/// Validate if string is a list of Nmtokens
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsNMTOKENS(pName) As %Boolean [ Internal, Private ]
{
	#; [4]  NameChar    ::=     Letter | Digit | '.' | '-' | '_' | ':' | CombiningChar | Extender 
	#; [7]  Nmtoken     ::=    (NameChar)+ 
	#; [8]  Nmtokens    ::=     Nmtoken (#x20 Nmtoken)*
	#; Combining characters and Extender are characters within certain ranges specified by
 	#; the unicode statndard. We don't have anygood way of testing for these at present.
 	Set tGood=0
 	if ($Length(pName)) {
		Set tGood=1
 		For tI=1:1:$Length(pName," ") {
			If '..IsNMTOKEN($Piece(pName," ",tI)) {
				Set tGood=0 Quit
	 		}
 		}
 	}
 	Quit tGood
}

/// Validate if string is an QName
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod IsQNAME(pName) As %Boolean [ Internal, Private ]
{
	#; [6]  QName       ::=  (Prefix ':')? LocalPart 
	#; [7]  Prefix      ::=  NCName 
	#; [8]  LocalPart   ::=  NCName 
 	If '..IsNCNAME($Piece(pName,":",1)) Quit 0
 	If $Length(pName,":")>2 Quit 0
 	If $Length(pName,":")=2 {
		If '..IsNCNAME($Piece(pName,":",2)) Quit 0	 
 	}
 	Quit 1
}

/// Get the local name part of a QName
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod GetName(name) As %String [ Internal, Private ]
{
 	Quit $piece(name,":",$length(name,":"))
}

/// Get the default namespace for the specified element
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method GetDefaultNamespace(node As %String) As %String [ Internal, Private ]
{
	Set ns=""
	While '$$$xmlaIsTop(i%IRISTempTarget,node) {
		If $$$xmlGetAttrQName(i%IRISTempTarget,node,"xmlns")="xmlns" {
	 		Set ns=$$$xmlGetAttribute(i%IRISTempTarget,node,"xmlns")
	 		Quit
		}
		Set node=$$$xmlaParentNode(i%IRISTempTarget,node)
	}
 	Quit ns
}

/// Normalize a NMTOKENS string by removing leading and trailing spaces
/// and setting any internal spaces to a single space
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod NormalizeTokens(pTokens) As %String [ Internal, Private ]
{
 	Set pTokens=$tr($zStrip(pTokens,"<>W"),$c(9,10,13),"   ")
 	Set tPos=0 
 	For  {
		Set tPos=$Find(pTokens,"  ",tPos) If tPos=0 Quit
		Set $Extract(pTokens,tPos-1)="",tPos=tPos-2
 	}
 	Quit pTokens
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod fixNames(uniquelen As %Integer, ByRef names) [ Internal, Private ]
{
	If +$get(names)=0 Quit

	For i=1:1:names {
		Set name=names(i)
		If name="" Continue
		Set uname=$extract($zcvt(name,"U"),1,uniquelen)
		Set namesUpper(uname,$increment(namesUpper(uname)))=i
	}

	Set extraDigits=$zlog(names)\1 + 1

	Set uname=$order(namesUpper(""))
	While uname'="" {
		For i=2:1:namesUpper(uname) {
			// not unique, make an alias
			// test if new name is already used
			Set num = 0
			Set rname=$extract(uname,1,uniquelen-extraDigits)
			Do {
				Set num=num+1
				Set rnum=$tr($justify(num,extraDigits)," ","0")
			} While $data(namesUpper(rname_rnum))
			Set index=namesUpper(uname,i)
			Set namesUpper(rname_rnum)=1
			Set namesUpper(rname_rnum,1)=index
			Set names(index)=$extract(names(index),1,uniquelen-extraDigits)_rnum
		}
		Set uname=$order(namesUpper(uname))
	}
	Quit
}

/// Combine the ports of a service which are identical except for the SOAP version.
/// The SOAPVERSION parameter will later be set to indicate multiple versions.
Method CombineVersions(pService As %String, pNamespace As %String) [ Internal, Private ]
{
	#; Check each port of service for other identical ports
	Set tPort1=$Order(i%Services(pService,pNamespace,""))
	while (tPort1'="") {
		Set tPort2=$Order(i%Services(pService,pNamespace,tPort1))
		while (tPort2'="") {
			Set location1=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",tPort1,"location")
			Set location2=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",tPort2,"location")
			If location1=location2 {
				Set tBinding1=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",tPort1,"binding")
				Set tBinding1NS=$list(tBinding1,1)
				Set tBinding1Name=$list(tBinding1,2)
				Set tBinding2=^IRIS.Temp(i%WSDLTarget,pNamespace,"service",pService,"port",tPort2,"binding")
				Set tBinding2NS=$list(tBinding2,1)
				Set tBinding2Name=$list(tBinding2,2)
				If tBinding1NS=tBinding2NS {
					If ..IsBindingEqual(tBinding1NS,tBinding1Name,tBinding2Name) {
						Set soapns1=^IRIS.Temp(i%WSDLTarget,pNamespace,"binding",tBinding1Name,"soapns")
						Set soapns2=^IRIS.Temp(i%WSDLTarget,pNamespace,"binding",tBinding2Name,"soapns")
						If soapns1'=soapns2 {
							If soapns1=$$$SOAP12ns {
								Kill i%Services(pService,pNamespace,tPort1)
								Set ^IRIS.Temp(i%WSDLTarget,pNamespace,"binding",tBinding2Name,"soapns")=""
								Set tPort2=""
							} Else {
								Kill i%Services(pService,pNamespace,tPort2)
								Set ^IRIS.Temp(i%WSDLTarget,pNamespace,"binding",tBinding1Name,"soapns")=""
							}
						} Else {
							Kill i%Services(pService,pNamespace,tPort2)
						}
					}
				}
			}
			If tPort2'="" Set tPort2=$Order(i%Services(pService,pNamespace,tPort2))
		}
		Set tPort1=$Order(i%Services(pService,pNamespace,tPort1))
	}
}

/// Return true if the two specified bindings are identical.
Method IsBindingEqual(namespace As %String, binding1 As %String, binding2 As %String) As %Boolean [ Internal, Private ]
{
	Kill ^||%xmlb1
	Merge ^||%xmlb1=^IRIS.Temp(i%WSDLTarget,namespace,"binding",binding1)
	Kill ^||%xmlb1("soapns")
	Set ref1=$query(^||%xmlb1(""))

	Kill ^||%xmlb2
	Merge ^||%xmlb2=^IRIS.Temp(i%WSDLTarget,namespace,"binding",binding2)
	Kill ^||%xmlb2("soapns")
	Set ref2=$query(^||%xmlb2(""))

	While (ref1'="") && (ref2'="") {
		If $get(@ref1)'=$get(@ref2) Quit
		Set ref1=$query(@ref1)
		Set ref2=$query(@ref2)
	}

	Quit ((ref1="") && (ref2=""))
}

/// Setup Schema Reader
Method SetupSchemaReader(pPackage As %String, schemaReader As %XML.Utils.SchemaReader) As %Status [ Internal ]
{
 	Kill %objlasterror

	If schemaReader="" {
		Set ..SchemaReader = ##class(%XML.Utils.SchemaReader).%New()
		If ..SchemaReader=$$$NULLOREF {
	 		Quit $Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.Utils.SchemaReader"))
		}
		Set ..SchemaReader.ClassPrefix = pPackage
		Set ..SchemaReader.NoClassPrefix=0
	} Else {
 		Set ..SchemaReader=schemaReader
		Set ..SchemaReader.ClassPrefix = ""
		Set ..SchemaReader.NoClassPrefix=(pPackage'="")
	}

	If ..HttpRequest="" Set ..HttpRequest = ##class(%Net.HttpRequest).%New()
	Set ..HttpRequest.SSLConfiguration=..SSLConfiguration
	Set ..SchemaReader.SSLConfiguration=..SSLConfiguration
	If ..SSLCheckServerIdentity'="" {
		Set ..HttpRequest.SSLCheckServerIdentity=..SSLCheckServerIdentity
		Set ..SchemaReader.SSLCheckServerIdentity=..SSLCheckServerIdentity
	}
	
	Set ..SchemaReader.EntityResolver=..EntityResolver
	Set ..SchemaReader.SAXFlags=..SAXFlags

	Set ..SchemaReader.Debug=..Debug
	Set ..SchemaReader.MakePersistent = ..MakePersistent
	Set ..SchemaReader.CascadeDeletes = ..CascadeDeletes
	Set ..SchemaReader.MakeNamespace = ..MakeNamespace
	// Force NAMESPACE parameters for message style classes.
	If ..MakeMessageStyle Set ..SchemaReader.MakeNamespace = 1
	Set ..SchemaReader.MakeSerial = ..MakeSerial
	Set ..SchemaReader.MakeRelationships = 0
	Set ..SchemaReader.ParentChildRelationship = 0
	Set ..SchemaReader.IndexRelationship = 0
	Set ..SchemaReader.KeepEmptyClasses = 1 
	Set ..SchemaReader.KeepEmptyElements = 1 
	Set ..SchemaReader.HttpRequest = ..HttpRequest
	Set ..SchemaReader.NoArrayProperties=..NoArrayProperties
	Set ..SchemaReader.GenerateXMLNIL=..GenerateXMLNIL
	Set ..SchemaReader.GenerateXMLNILNOOBJECT=..GenerateXMLNILNOOBJECT
	Merge ..SchemaReader.PackageMapping=..PackageMapping
	
	Quit $$$OK
}

/// This method pre-processes the XML schemas for the WSDL to get list of namespaces.
Method PreProcess(pLocationURL As %String, ByRef multipleNamespace As %Boolean) As %Status [ Internal ]
{
	Do ..Reset()

 	// First process WSDL to find any classes (types) we need to create
 	Set tSC=..SetupSchemaReader("","")
	If $$$ISERR(tSC) Quit

	Set tSC = ..SchemaReader.PreParseSchema("",pLocationURL,.multipleNamespace)
	Quit tSC
}

/// parse WSDL, the new Atelier SOAP wizard need to show the operations supported by this web service
Method parseWSDL(pLocationURL As %String, pPackage As %String = "") As %String [ Internal ]
{
	kill ^ISC.Atelier.SOAP
	Set tSC=..SetupSchemaReader(pPackage,"")
 	If $$$ISERR(tSC) Quit
 	Set tSC = ..SchemaReader.ParseSchema("",pLocationURL)
 	If $$$ISERR(tSC) Quit
	Set tSC=..ProcessServices(pLocationURL,pPackage)
	Set tSC=..ReadServices(pLocationURL)
	merge ^ISC.Atelier.SOAP = ^IRIS.Temp(i%WSDLTarget)	
	do ..Reset()
	set nodes = ..fetchOperations()
	quit nodes
}

/// parse the global structure and fetch the defined operations
Method fetchOperations() As %String [ Internal, Private ]
{
	kill uniqueNodes
	set uniqueNodes = ""
	set ret = ""
	set node = $Query(^ISC.Atelier.SOAP(""))
	while (node '= "")
	{
		set posStart = $find(node,"""operation"",")
		if posStart '= 0
		{
			set opStart = $find(node,"""",posStart)
			if opStart '= 0
			{
				set opEnd = $find(node,"""",opStart)
				if opEnd '= 0
				{
					set uniqueNodes($extract(node,opStart,opEnd-2)) = 1
				}
			}
		}
		Set node = $Query(@node)
	}
	set idx = ""
	for
	{
		set idx = $order(uniqueNodes(idx),1,val)
		quit:idx=""
		if ret = ""
		{
			set ret = idx
		}
		else
		{
			set ret = ret_":"_idx
		}
	}
	quit ret
}

/// This method call processes the WSDL found at the specified location. The
/// WSDL is retrieved and parsed into ^IRIS.Temp. The definitions are then processed
/// creating one or more SOAP client classes. These client classes may be used to
/// access the services defined with the WSDL.
/// The reader argument is for internal usage by system classes only.
Method Process(pLocationURL As %String, pPackage As %String = "", pTest As %Boolean = 0, schemaReader As %XML.Utils.SchemaReader = "") As %Status
{
	New %WSDLns,%SOAPns,%xmlns
	
	Do ..Reset()
	
 	Set tSC=$$$OK
 	do {
	 	// First process WSDL to find any classes (types) we need to create
	 	Set tSC=..SetupSchemaReader(pPackage,schemaReader)
 		If $$$ISERR(tSC) Quit
 		Set tSC = ..SchemaReader.ParseSchema("",pLocationURL)
 		If $$$ISERR(tSC) Quit

		#; Verify the SECURITYIN parameter
		If $case($zcvt(..SecurityInParameter,"L"),"":0,"allow":0,"ignore":0,"ignoreall":0,"require":0,:1) {
			Set tSC=$$$ERROR($$$SOAPInvalidSECURITYIN,..SecurityInParameter)
			Quit
		}
		
		// Verify the XMLIGNORENULL parameter
		If $case(..IgnoreNull,"":0,0:0,1:0,"inputonly":0,:1) {
			Set tSC=$$$ERROR($$$XMLInvalidIgnoreNULL,..IgnoreNull)
			Quit
		}

		If ..MakeClient || ..MakeService { 		
 			Set tSC=..ProcessServices(pLocationURL,pPackage)
 			If $$$ISERR(tSC) Quit
		}

		#; Create relationships if required
		If ..MakeRelationships Do ..SchemaReader.FindRelationships(..ParentChildRelationship,..IndexRelationship)
		
		#; Remove any temproary classes
		Do ..SchemaReader.RemoveTemporaryClasses()
 		
 		// Generate classes so they are ready for use
 		Kill %objlasterror

		If ..NoSequence Set Features("NOSEQUENCE")=1
		If ..IgnoreNull'="" Set Features("IGNORENULL")=..IgnoreNull
		If ..BinaryAsStream Set Features("BINARYASSTREAM")=1
 		Set tResult = ##class(%XML.Utils.SchemaResult).CreateResult(..SchemaReader,,.Features)
 		If tResult=$$$NULLOREF {
	 		Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.Utils.SchemaResult"))
	 		Quit
 		}
 		
 		// Save type classes
		Set tSC = tResult.SaveClasses(0,pTest)
  		If $$$ISERR(tSC) Quit

		If ..CompileClasses {
	 		// Compile type classes
			Set tSC = tResult.CompileClasses(0,..CompileFlags)
  			If $$$ISERR(tSC) Quit

	 		// Compile service classes
	 		Set tClassName=$order(..ClientClassList(""))
	 		While tClassName'="" {
				Set tSC = $System.OBJ.Compile(tClassName,..CompileFlags)
	  			If $$$ISERR(tSC) Quit
	 			Set tClassName=$order(..ClientClassList(tClassName))
	 		}
	  		If $$$ISERR(tSC) Quit
  		
	 		// Compile Ensemble Business Operation Classes
	 		Set tClassName=$order(..BOClassList(""))
	 		While tClassName'="" {
				Set tList(tClassName_".cls")=""
	 			Set tClassName=$order(..BOClassList(tClassName))
	 		}
			If $data(tList) Set tSC = $System.OBJ.CompileList(.tList,..CompileFlags)
	  		If $$$ISERR(tSC) Quit
		}
  		
  		// Add type classes from schema to the list.
  		Merge ..TypeClassList=tResult.Classes
 		
 	} while (0)
	Quit tSC
}

/// The <method>ProcessPolicy</method> method creates a configuration class for a web service client
/// which contains the policy specified by the service's WSDL.  
/// If there is no policy in the WSDL an empty configuration class is created.
/// The configuration class will be compiled, if the CompileClasses property is true.<br>
/// Note that it is the caller's responsibility to insure that the WSDL URL corresponds to the same
/// web service as the client.<br>
/// The current implementation of this method is limited to WSDLs which have only one port specified.<br>
/// <ul>
/// <li><var>wsdlURL</var> is URL of the WSDL which contains the policy.</li>
/// <li><var>clientWebServiceClass</var> is the name of the web service client.  
/// If the client already has a configuration class, the configuration class will be deleted.</li>
/// <li><var>policyConfigClass</var> is the name of the configuration class to be created.
/// If a class named <var>policyConfigClass</var> already exists, the existing class will be deleted.</li>
/// </ul>
Method GeneratePolicyFromWSDL(wsdlURL As %String, clientWebServiceClass As %String, policyConfigClass As %String) As %Status
{
	New %WSDLns,%SOAPns,%xmlns
	
	Do ..Reset()
	
	#; Read the services into internal format
	Set sc=..ReadServices(wsdlURL)
	If $$$ISERR(sc) Quit sc
	 	
	Set numPorts=0
	Set service=""
	While (numPorts<=1) && $$$ISOK(sc) {
		Set service=$order(..Services(service))
		If service="" Quit
		Set namespace=""
		While (numPorts<=1) && $$$ISOK(sc) {
			Set namespace=$order(..Services(service,namespace))
			If namespace="" Quit
			Set port=""
			While (numPorts<=1) && $$$ISOK(sc) {
				Set port=$order(..Services(service,namespace,port))
				If port="" Quit
				Set numPorts=numPorts+1
				If numPorts=1 {
					Set configService=service
					Set configNamespace=namespace
					Set configPort=port
				}
			}
		}
	}
	If $$$ISERR(sc) Quit sc
	
	If numPorts=1 {
		Set className=$$$NormalizeClassname(clientWebServiceClass)
		If '$$$defClassDefined(className) {
			Quit $$$ERROR($$$WSDLPolicyNoClient,clientWebServiceClass)
		}
		
		Set configId=##class(%SOAP.Configuration).GetConfigId(className)
		If configId'="" {
			Set oldConfigClassName=$piece(configId,":",1)
			Set numSOAPClasses=0
			Do ##class(%SOAP.Configuration).GetSOAPClasses(configId,.SOAPClasses)
			Set class=""
			For {
				Set class=$order(SOAPClasses(class))
				If class="" Quit
				Set numSOAPClasses=numSOAPClasses+1
			}
			If numSOAPClasses=1 {
				#; Delete any pre-existing definition
				Do Delete^%apiOBJ(oldConfigClassName,"-d")
			} ElseIf numSOAPClasses>1 {
				Quit $$$ERROR($$$WSDLPolicyMultiConfig,clientWebServiceClass,oldConfigClassName)
			}
		}

		Set sc=..CreateConfigurationClass(configService,configNamespace,configPort,clientWebServiceClass,policyConfigClass)
		If $$$ISERR(sc) Quit sc

		If ..CompileClasses {
			Set sc=$System.OBJ.Compile(policyConfigClass,..CompileFlags)
		}

	} Else {
		Quit $$$ERROR($$$WSDLPolicyService,clientWebServiceClass)
	}
	
	Quit sc
}

/// Method to handle creation of classes
Method ProcessServices(pLocationURL As %String, pPackage As %String) As %Status [ Internal, Private ]
{
	Set tSC=$$$OK
 	do {
	 	#; Read the services into internal format
	 	Set tSC=..ReadServices(pLocationURL)
	 	If $$$ISERR(tSC) Quit
	 	
	 	#; Create client and service names
 		Set clientPackageBase=..ClientPackage
 		If clientPackageBase="." Set clientPackageBase=""
 		Set servicePackageBase=..ServicePackage
 		If servicePackageBase="." Set servicePackageBase=""
 		
 		#; Get and fixup class names based on service and port.
 		Set maxPackageLen=$$$MAXPACKAGEIDLENGTH
 		Set maxClassLen=$$$MAXCLASSNAMELENGTH-32
 		Set uniqueClassLen=$$$MAXCLASSIDLENGTH
 		Set tService=$Order(i%Services(""))
 		while (tService'="") {
	 		Set PackageName=$select(pPackage'="":pPackage,1:##class(%SOAP.WebBase).NormalizeName(tService,maxPackageLen))
	 		If ..MakeClient {
		 		If clientPackageBase="" {
			 		Set clientPackageName=PackageName
		 		} ElseIf $extract(clientPackageBase)="." {
			 		Set clientPackageName=PackageName_clientPackageBase
		 		} Else {
			 		Set clientPackageName=clientPackageBase
		 		}
	 		}
	 		If ..MakeService {
		 		If servicePackageBase="" {
			 		Set servicePackageName=PackageName
		 		} ElseIf $extract(servicePackageBase)="." {
			 		Set servicePackageName=PackageName_servicePackageBase
		 		} Else {
			 		Set servicePackageName=servicePackageBase
		 		}
			 	// Make sure separate package supplied for client and service
			 	If ..MakeClient,clientPackageName=servicePackageName {
				 	Set tSC=$$$ERROR($$$WSDLPackageNeeded,clientPackageName)
				 	Quit
			 	}
	 		}
	 		Set tNamespace=$Order(i%Services(tService,""))
	 		while (tNamespace'="") {
 				#; For each port
				Set tPort=$Order(i%Services(tService,tNamespace,""))
				while (tPort'="") {
					Set PortName=##class(%SOAP.WebBase).NormalizeName(tPort,uniqueClassLen)
		 			Set ClientClassNames($increment(ClientClassNames))=$select(..MakeClient:clientPackageName_"."_PortName,1:"")
		 			If ..MakeClient,..MakeEnsembleClasses {
						Set PackageNames(ClientClassNames) = clientPackageName
		 			} Else {
						Set PackageNames(ClientClassNames) = PackageName
		 			}
		 			Set ServiceClassNames($increment(ServiceClassNames))=$select(..MakeService:servicePackageName_"."_PortName,1:"")

					Set tPort=$Order(i%Services(tService,tNamespace,tPort))
				}
		 		Set tNamespace=$Order(i%Services(tService,tNamespace))
	 		}
 			Set tService=$Order(i%Services(tService))
 		}
 		If $$$ISERR(tSC) Quit
 		Do ..fixNames(maxClassLen,.ClientClassNames)
 		Do ..fixNames(maxClassLen,.ServiceClassNames)

 		#; For each service
 		Set classIndex=0
 		Set tService=$Order(i%Services(""))
 		while (tService'="") {

 			#; For each namespace
	 		Set tNamespace=$Order(i%Services(tService,""))
	 		while (tNamespace'="") {

 				#; For each port
				Set tPort=$Order(i%Services(tService,tNamespace,""))
				while (tPort'="") {
					#; Generate a Service
					Set classIndex=classIndex+1
					Set tSC=..GenerateService(tService,tNamespace,tPort,PackageNames(classIndex),ClientClassNames(classIndex),ServiceClassNames(classIndex))
	 				If $$$ISERR(tSC) Quit

					Set tPort=$Order(i%Services(tService,tNamespace,tPort))
				}
			 	If $$$ISERR(tSC) Quit
		 		Set tNamespace=$Order(i%Services(tService,tNamespace))
	 		}
	 		If $$$ISERR(tSC) Quit
	 		Set tService=$Order(i%Services(tService))
 		}
 		If $$$ISERR(tSC) Quit
 	} while (0)
 	Quit tSC
}

/// Read services in WSDL and store in internal format
Method ReadServices(locationURL As %String) As %Status [ Internal ]
{
 	// Now continue with WSDL processing
	Set tSC=..read(locationURL,"")
	If $$$ISERR(tSC) Quit tSC

	#; Walk through the WSDL keys and extract the schema specifications and definitions
	Set i%IRISTempTarget=$Order(i%WSDLKeys("")),i%WSDLTarget=$Increment(^IRIS.Temp)
	while (i%IRISTempTarget'="") {
 		Set tNamespace=i%WSDLKeys(i%IRISTempTarget)
		Set %xmlns=$$$xmlNamespaceToIndex(i%IRISTempTarget,$$$XMLNSns)
 		Set %WSDLns=$$$xmlNamespaceToIndex(i%IRISTempTarget,$$$WSDLns)
 		Set tSC=..definitions(tNamespace)
 		If $$$ISERR(tSC) Quit
 		Set i%IRISTempTarget=$Order(i%WSDLKeys(i%IRISTempTarget))
	}
	If $$$ISERR(tSC) Quit tSC
	
	// If there are no services defined (UDDI WSDL is an example),
	// then define a service for each binding.
	If $Order(i%Services(""))="" {
 		Set binding = $order(i%Bindings(""))
 		While binding'="" {
	 		Set tNamespace=$Order(i%Bindings(binding,""))
	 		// Use binding name as service name and the port name.
	 		Set i%Services(binding,tNamespace)=""
	 		Set ^IRIS.Temp(i%WSDLTarget,tNamespace,"service",binding)="placeholder"
	 		Set ^IRIS.Temp(i%WSDLTarget,tNamespace,"service",binding,"port",binding,"binding")=$ListBuild(tNamespace,binding)

 			Set binding = $order(i%Bindings(binding))
 		}
	}
	
	#; Mark services that are real SOAP services.
	Set tService=$Order(i%Services(""))
	while (tService'="") {
 		Set tNamespace=$Order(i%Services(tService,""))
 		while (tNamespace'="") {
			#; For each port
			Set tPort=$Order(^IRIS.Temp(i%WSDLTarget,tNamespace,"service",tService,"port",""))
			while (tPort'="") {
	 			If ..IsService(tService,tNamespace,tPort) {
		 			Set i%Services(tService,tNamespace,tPort)=""		 			
	 			}
	 			Set tPort=$Order(^IRIS.Temp(i%WSDLTarget,tNamespace,"service",tService,"port",tPort))
			}
			#; Combine ports which are identical except for SOAP version
			Do ..CombineVersions(tService,tNamespace)
			
	 		Set tNamespace=$Order(i%Services(tService,tNamespace))
 		}
		Set tService=$Order(i%Services(tService))
	}
	
	Quit $$$OK
}

/// This method provides a means of testing the Reader
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
ClassMethod Test(pUrl As %String, Output pReader) [ Internal ]
{
 	#; Get a WSDL reader
 	Set tSC=$$$OK
 	do {
	 	Kill %objlasterror
 		Set pReader=##Class(%SOAP.WSDL.Reader).%New()
 		If pReader=$$$NULLOREF {
 			Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%SOAP.WSDL.Reader"))
 			Quit
 		}
 		Set tSC=pReader.Process(pUrl)
 		
 	} while(0)
 	If $$$ISERR(tSC) Do DisplayError^%apiOBJ(tSC)
}

/// Bindings(bindingname,namespace)=""
/// IRIS.Temp(key,namespace,"binding",bindingname,"soapns")= SOAP 1.1 or SOAP 1.2 WSDL namespace
/// IRIS.Temp(key,namespace,"binding",bindingname,"portType")= $List(namespace,port name)
/// IRIS.Temp(key,namespace,"binding",bindingname,"transport")= optional soap binding transport
/// IRIS.Temp(key,namespace,"binding",bindingname,"style") = optional default soap binding style
/// IRIS.Temp(key,namespace,"binding",bindingname,"isccharset") = optional charset from isc:binding
/// IRIS.Temp(key,namespace,"binding",bindingname,"isc") = optional isc:binding element emcountered
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname)= ""
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"style")= soap binding style
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"soapAction")= soap action
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,messagename,"encodingStyle")= soap body encoding style
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,messagename,"namespace")= soap body namespac
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,messagename,"parts")= soap body parts
/// IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,messagename,"use")= soap body use
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method binding(pIndex, baseChildlist) [ Internal, Private ]
{
 	#; element MUST be "binding"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MUST contain the 'type' attribute (QNAME)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain the wsdl: 'documentation' or 'bindingOperation' elements
 	#; element MAY contain other elements for extensibility e.g. soap:binding
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="binding")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tBindingName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tBindingName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:binding","name") Quit
 		}
 		If '..IsNCNAME(tBindingName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding","name",tBindingName_"  NCNAME") Quit
 		}

 		#; binding name must be unique
 		If $Data(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName))#10=1 {
	    	Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:binding",tBindingName) Quit
 		}

 		#; Finished with 'name' attribute
 		Kill tAttrs("name")

 		#; Validate 'type' attribute
 		Set tBindingType=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("type")))
		If tBindingType="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:binding","type") Quit
 		}
		If '..IsQNAME(tBindingType) {
			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding","type",tBindingType_" : QNAME") Quit
		}

 		#; Pick out the namespace and localname for the port
 		Set tNS=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,$get(tAttrs("type")))
 		If tNS="" Set tNS=..GetDefaultNamespace(pIndex)
 		If tNS="" Set tNS=""""""
 		Set tPortName=..GetName(tBindingType)
 		$$$ASSERT(tNS'="")
 		$$$ASSERT(tPortName'="")


 		#; Finished with the 'type' attribute
 		Kill tAttrs("type")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:binding") Quit
 		}

 		#; Record the binding and port type
 		Set ..Bindings(tBindingName,i%TargetNamespace)=""
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"portType")=$ListBuild(tNS,tPortName)
 		Set %SOAPns=$get(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"soapns"))

 		#; The default soap binding style is 'document', transport has no default (WSDL spec section 3.3 soap:binding)
		Set tSoapBindingStyle="document",tSoapBindingTransport="",isccharset=""

 		#; Process the soap:binding child of the 'binding' element first,
 		#; since style may be specified in soap:binding and overriden in operation.
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			If %SOAPns="" {
		 			If tNS=$$$SOAPns {
			 			Set %SOAPns=tNS
			 			Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"soapns")=tNS
		 			} ElseIf tNS=$$$SOAP12ns {
			 			Set %SOAPns=tNS
			 			Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"soapns")=tNS
		 			}
	 			}
		 		If (tNS=%SOAPns & (tType="binding")) {
 					Set tSC=..soapBinding(tChild,childlist,.tSoapBindingStyle,.tSoapBindingTransport)
 					If '$$$ISERR(tSC) {
	 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"style")=tSoapBindingStyle
	 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"transport")=tSoapBindingTransport	 				
	 				} 
	 			} ElseIf (tNS=$$$ISCSOAPns) && (tType="binding") {
 					Set tSC=..iscBinding(tChild,childlist,.isccharset)
 					If '$$$ISERR(tSC) {
	 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"isccharset")=isccharset
	 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",tBindingName,"isc")=1
	 				} 
	 			} ElseIf tType["Policy" { 
		 			Set tSC=..policy(tChild,childlist,$lb("binding",tBindingName))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
 			If $$$ISERR(tSC) Quit
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 		If $$$ISERR(tSC) Quit
 		
 		#; If no soap:binding element, just quit
 		If %SOAPns="" Quit

 		#; Process the children of the 'binding' element except soap:binding
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process 'operation' elements which are qualified with the WSDL namespace OR
 			#; 'binding' elements which are qualified with the SOAP namespace	 			
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=%WSDLns) {
		 			if (tType="operation") {
	 					Set tSC=..bindingOperation(tChild,childlist,tBindingName,tSoapBindingStyle,tSoapBindingTransport)
		 			} elseif (tType="documentation") {
	 					Set tSC=..documentation(tChild,childlist)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding","binding",tType)
		 			}
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 		If $$$ISERR(tSC) Quit
 	} while (0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method bindingOperation(pIndex, baseChildlist, pBindingName, pSoapBindingStyle, pSoapBindingTransport) [ Internal, Private ]
{
 	#; element MUST be "operation"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain wsdl: documentation or bindingOperationMessages ('input', 'output' or 'fault')
    #; element MAY contain other elements for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="operation")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tOperationName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tOperationName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:binding:operation","name") Quit
 		}
 		If '..IsNCNAME(tOperationName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation","name",tOperationName_" : NCNAME") Quit
 		}

 		#; Finished with 'name' attribute
 		Kill tAttrs("name")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:binding:operation") Quit
 		}


 		#; Record the operation
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",tOperationName)=""

 		#; Process the children of the 'bindingOperation' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process 'input','output' or 'fault' elements which are qualified with the WSDL namespace OR
 			#; 'operation' elements which are qualified with the SOAP namespace
			Set tSoapBindingStyle=pSoapBindingStyle,tSoapAction=""
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=$$$WSDLns) {
		 			if ((tType="input")||(tType="output")||(tType="fault")) {
	 					Set tSC=..bindingOperationMessage(tChild,childlist,pBindingName,tOperationName)
		 			} elseif (tType="documentation") {
			 			Set tSC=..documentation(tChild,childlist)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation","wsdl",tType)
		 			}
 				} ElseIf $get(%SOAPns)="" {
			 		Set tSC = $$$ERROR($$$NoSOAPNamespace,i%TargetNamespace)
		 		} ElseIf (tNS=%SOAPns) {
	 				If (tType="operation") {
 						Set tSC=..soapOperation(tChild,childlist,.tSoapBindingStyle,.tSoapAction)
 						If '$$$ISERR(tSC) {
	 						Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",tOperationName,"style")=tSoapBindingStyle
	 						Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",tOperationName,"soapAction")=tSoapAction
 						}
 					} Else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation","soap",tType)
		 			}
	 			} ElseIf tType["Policy" { 
		 			Set tSC=..policy(tChild,childlist,$lb("binding",pBindingName,"operation",tOperationName))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 		If $$$ISERR(tSC) Quit
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method bindingOperationMessage(pIndex, baseChildlist, pBindingName, pOperationName) [ Internal, Private ]
{
 	#; element MUST be "input,output or fault"
 	#; element MUST be in the WSDL namespace
 	#; element MAY contain the 'name' attribute (NCNAME)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain the wsdl 'documentation' element
 	#; element MAY contain other elements for extensibility (e.g. soap:body)
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	Set tOpMsg=$$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)
 	Set tHdrMsg=tOpMsg_"header"
 	Set bodyFound=0
 	$$$ASSERT((tOpMsg="input")||(tOpMsg="output")||(tOpMsg="fault"))
 	do {
 		#; Process the children of the 'bindingOperationMessage' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process 'body' elements which are qualified with the SOAP namespace OR
 			#; 'documentation' elements qualified with the WSDL namespace
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=$$$WSDLns) {
		 			if (tType="documentation") {
			 			Set tSC=..documentation(tChild,childlist)
		 			} elseif (tType="fault") {
			 			Set tSC=..fault(tChild,childlist)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation:msg","wsdl",tType)
		 			}
	 			} ElseIf tNS=$$$WSDLMIMEns {
		 			If tType="multipartRelated" {
	 					Set tSC=..mimeMultipartRelated(tChild,childlist,pBindingName,pOperationName,tOpMsg,.bodyFound)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation:msg","soap",tType)
		 			}
	 			} ElseIf $get(%SOAPns)="" {
			 		Set tSC = $$$ERROR($$$NoSOAPNamespace,i%TargetNamespace)
		 		} ElseIf (tNS=%SOAPns) {
		 			If (tType="body") {
			 			Set bodyFound=1
	 					Set tSC=..soapBody(tChild,childlist,pBindingName,pOperationName,tOpMsg)
		 			} elseif (tType="fault") {
			 			Set tSC=..fault(tChild,childlist)
		 			} elseif (tType="header") {
			 			Kill tSoapHeaderEncodingStyle,tSoapHeaderNamespace,tSoapHeaderPart,tSoapHeaderUse,tSoapHeaderNS,tSoapHeaderMessageName
			 			Set tSC=..header(tChild,childlist,tOpMsg,.tSoapHeaderEncodingStyle,.tSoapHeaderNamespace,.tSoapHeaderPart,.tSoapHeaderUse,.tSoapHeaderNS,.tSoapHeaderMessageName)
	 					If $$$ISOK(tSC) {
		 					Set tSoapHeaderMessage=$lb(tSoapHeaderNS,tSoapHeaderMessageName,tSoapHeaderPart)
		 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tHdrMsg,tSoapHeaderMessage,"encodingStyle")=tSoapHeaderEncodingStyle
		 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tHdrMsg,tSoapHeaderMessage,"namespace")=tSoapHeaderNamespace
		 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tHdrMsg,tSoapHeaderMessage,"use")=tSoapHeaderUse
	 					}
	 				} elseif (tType="documentation") {
		 				Set tSC=..documentation(tChild,childlist)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation:msg","soap",tType)
		 			}
	 			} ElseIf (tType["Policy") && ((tOpMsg="input")||(tOpMsg="output")) { 
		 			Set tSC=..policy(tChild,childlist,$lb("binding",pBindingName,"operation",pOperationName,tOpMsg))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)

 	// If no soap:body for input or output default to use=literal
 	If 'bodyFound && ((tOpMsg="input")||(tOpMsg="output")) {
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tOpMsg,"encodingStyle")=""
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tOpMsg,"namespace")=""
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tOpMsg,"parts")=""
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,tOpMsg,"use")="literal"
 	}

 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method definitions(pNamespace) [ Internal, Private ]
{
 	#; element MUST be "definitions"
 	#; element MUST be present in a WSDL instance as the top-level element
 	#; element MAY contain namespace declarations
 	#; element MAY contain the 'name' or 'targetNamespace' attributes
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain the wsdl: 'documentation', 'import', 'types', 'message', 'portType', 'binding' and 'service' elements
 	#; element MAY contain other elements from other namespaces for extensibility

 	#; A well-formed XML document has one top-level element
 	Set tIndex=$$$xmlGetDocumentElement(i%IRISTempTarget)
 	Set tSC=$$$OK
 	do {

 		#; Search for 'definition' element
		$$$xmlaGetChildList(i%IRISTempTarget,tIndex,baseChildlist,d)
 		If $$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)'="definitions" {
 			#; No 'definition' found, perhaps this file contains 'schema' information?
			If $$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)'="schema" {
 				#; No 'schema found', that's an error condition
	  			Set tSC=$$$ERROR($$$WSDLMissingElement,"'definitions' or 'schema'")
			}
			Quit
 		}

 		#; Record index of 'definitions'
		Set i%DefinitionsKey=tIndex

		#; Verify WSDL and SOAP namespaces are defined.
 		If %WSDLns="" {
	 		Set tSC = $$$ERROR($$$NoWSDLNamespace,pNamespace)
	 		Quit
 		}
 		#; Check namespace, we only accept 'wsdl'
 		Set tNS=$$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)
 		If tNS'=%WSDLns {
 			Set tNS=$select(tNS=0:"",1:$$$xmlIndexToNamespace(i%IRISTempTarget,tNS))
	 		Set tSC=$$$ERROR($$$WSDLBadNamespace,tNS,"'http:#;schemas.xmlsoap.org/wsdl/'")
	 		Quit
 		}
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Pick out the target namespace, elements defined within the wsdl document will be associated with this namespace
		Set pNamespace=$Get(pNamespace),i%TargetNamespace=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("targetNamespace")))
		if (i%TargetNamespace="") {

 		#; Target namespace not specified
			if (pNamespace'="") {
				Set i%TargetNamespace=pNamespace
			} else {
				Set i%TargetNamespace=""""""
			}
		}

 		#; Finished with the 'name' and 'targetNamespace' attributes
 		Kill tAttrs("name"),tAttrs("targetNamespace")

 		#; Process the children of the 'definitions' element
		$$$xmlaFirstChild(i%IRISTempTarget,tIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are elements and are qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 					if (tType="binding") {
	 					Set tSC=..binding(tChild,childlist)
	 				} elseif (tType="documentation") {
	 					Set tSC=..documentation(tChild,childlist)
 					} elseif (tType="import") {
	 					Set tSC=..import(tChild,childlist)
 					} elseif (tType="message") {
	 					Set tSC=..message(tChild,childlist)
 					} elseif (tType="portType") {
	 					Set tSC=..portType(tChild,childlist)
 					} elseif (tType="service") {
	 					Set tSC=..service(tChild,childlist)
 					} elseif (tType="types") {
	 					Set tSC=..types(tChild,childlist)
 					} else {
	 					Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:definitions","wsdl",tType)
 					}
 					If $$$ISERR(tSC) Quit
 			} ElseIf ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 					 ($$$xmlaGetLocalName(i%IRISTempTarget,childlist)="Policy") {
	 			Set tSC=..policy(tChild,childlist,"")
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,tIndex,baseChildlist,tChild,descriptor)
 		}
 		If $$$ISERR(tSC) Quit
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method documentation(pIndex, baseChildlist, ByRef text) [ Internal, Private ]
{
 	#; Not interested in documenation unless text argument is specified (usually as ""),
 	#; this function just acknowledges that documentation may be present
 	If $data(text) {
		Do ##class(%XML.ImportHandler).SerializeNode(i%IRISTempTarget,pIndex,0,1,.text,,,baseChildlist)
		Set text=$replace($zcvt(text,"I","XML"),$c(10),($c(13,10)))
 	}
	Quit $$$OK
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method fault(pIndex, baseChildlist, pPortTypeName, pOperationName) [ Internal, Private ]
{
 	#; Not interested in fault for now
 	Quit $$$OK
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method header(pIndex, baseChildlist, pOp, pEncodingStyle, pNamespace, pPart, pUse, pNS, pMessageName) [ Internal, Private ]
{
 	#; element MUST be "header"
 	#; element MUST be in the SOAP namespace
 	#; element MUST contain the 'message' attribute (qname)
 	#; element MAY contain the 'encodingStyle' attribute (anyURI)
 	#; element MAY contain the 'namespace' attribute (anyURI)
 	#; element MAY contain the 'use' attribute (ncname)
 	#; element MAY contain the 'part' attribute (nmtoken)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain headerfault element which is ignored.
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="header")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=%SOAPns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'message' attribute
 		Set pMessageName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("message")))
 		If pMessageName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:binding:operation:"_pOp_":header","message") Quit
 		}
 		If '..IsQNAME(pMessageName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation:"_pOp_":header","message",pMessageName_" : QNAME") Quit
 		}

 		#; Pick out the namespace and localname for the message
 		Set pNS=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,$get(tAttrs("message")))
 		If pNS="" Set pNS=..GetDefaultNamespace(pIndex)
 		If pNS="" Set pNS=""""""
 		Set pMessageName=..GetName(pMessageName)
 		$$$ASSERT(pNS'="")
 		$$$ASSERT(pMessageName'="")


 		#; Finished with 'message' attribute
 		Kill tAttrs("message")

 		#; Validate the optional 'encodingStyle' attribute
 		Set pEncodingStyle=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("encodingStyle")))
 		If pEncodingStyle'="" {
 			If '..IsANYURI(pEncodingStyle) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation:"_pOp_":header","encodingStyle",pEncodingStyle_" : anyURI") Quit
 			}
 		}

 		#; Finished with 'encodingStyle' attribute
 		Kill tAttrs("encodingStyle")

 		#; Validate the optional 'namespace' attribute
 		Set pNamespace=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("namespace")))
 		If pNamespace'="" {
 			If '..IsANYURI(pNamespace) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation:"_pOp_":header","namespace",pNamespace_" : anyURI") Quit
 			}
 		}

 		#; Finished with 'namespace' attribute
 		Kill tAttrs("namespace")

 		#; Validate the optional 'part' attribute
 		Set pPart=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("part")))
 		If pPart'="" {
 			If '..IsNMTOKEN(pPart) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation:"_pOp_":header","parts",pPart_" : NMTOKEN") Quit
 			}
 			Set pPart=$zstrip(pPart,"<>W")
 		}

 		#; Finished with the 'part' attribute
		Kill tAttrs("part")

 		#; Validate 'use' attribute
 		Set pUse=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("use")))
		If pUse'="" {
			if (pUse'="encoded"&&(pUse'="literal")) {
				Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:binding:operation:"_pOp_":header","use",pUse_" : body use") Quit
			}
		}

 		#; Finished with the 'use' attribute
		Kill tAttrs("use")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:binding:operation:"_pOp_":header") Quit
 		}
		If $$$ISERR(tSC) Quit
 	} while (0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method import(pIndex, baseChildlist) [ Internal, Private ]
{
 	#; element MUST be 'import'
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'namespace' attribute
 	#; element MUST contain the 'location' attribute
 	#; element MAY contain any other attributes for extensibility
 	#; element MAY contain any other elements for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="import")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'namespace' attribute
		Set tNS=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("namespace")))
 		If tNS="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:import","namespace") Quit
 		}
 		If '..IsANYURI(tNS) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:import","namespace",tNS_" : anyURI") Quit
 		}

 		#; Finished with 'namespace' attribute
 		Kill tAttrs("namespace")

 		#; Validate 'location' attribute
		Set tLocation=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("location")))
 		If tLocation="" {
			Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:import","location") Quit
 		}
 		If '..IsANYURI(tLocation) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:import","location",tLocation_" : anyURI") Quit
 		}

 		#; Finished with 'location' attribute
 		Kill tAttrs("location") 

 		#; Process children of the 'import' element 
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are 'documentation' elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				if (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist)
 				} else {
	 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:import","wsdl",tType)
 				}
 				If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}	
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method input(pIndex, baseChildlist, pPortTypeName, pOperationName) [ Internal, Private ]
{
 	#; element MUST be "input"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'message' attribute
 	#; element MAY contain the 'name' attribute (NCNAME)
 	#; element MAY contain other attributes for extensibility
 	#; element MUST NOT contain any other elements
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="input")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tInputName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tInputName'="",'..IsNCNAME(tInputName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation:input","name",tInputName_" : NCNAME") Quit
 		}

 		#; Finished with the 'name' attribute
 		Kill tAttrs("name") 

 		#; Validate 'message' attribute
 		Set tMessageName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("message")))
 		If tMessageName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:portType:operation:input","message") Quit
 		}
 		If '..IsQNAME(tMessageName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation:input","message",tMessageName_" : QNAME") Quit
 		}

 		#; Pick out the namespace and localname for the message
 		Set tNS=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,$get(tAttrs("message")))
 		If tNS="" Set tNS=..GetDefaultNamespace(pIndex)
 		If tNS="" Set tNS=""""""
 		Set tMessageName=..GetName(tMessageName)
 		$$$ASSERT(tNS'="")
 		$$$ASSERT(tMessageName'="")


 		#; Finished with 'message' attribute
 		Kill tAttrs("message")

 		#; Look for wsaw:Action attribute
 		Set action=""
 		If $data(tAttrs("Action")),
 		   $$$xmlaGetAttrNamespaceURI(i%IRISTempTarget,tAttrs("Action"))=$$$SOAPWSAWns {
	 		   Set action=$$$xmlaGetAttribute(i%IRISTempTarget,tAttrs("Action"))
 		}

 		#; Record Input
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"portType",pPortTypeName,"operation",pOperationName,"input")=$ListBuild(tNS,tMessageName,action)

 		#; Process the children of the 'input' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=$$$WSDLns) {
	 				If (tType="documentation") {
	 					Set tSC=..documentation(tChild,childlist)
	 				} Else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:portType:operation:input","wsdl",tType)
	 				}
	 			} ElseIf tType["Policy" { 
		 			Set tSC=..policy(tChild,childlist,$lb("portType",pPortTypeName,"operation",pOperationName,"input"))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)
 	Quit tSC
}

/// IRIS.Temp(key,namespace,"message",msgname)
/// IRIS.Temp(key,namespace,"message",msgname,"xmlelement")=summary of element attribute use
///           1 = all element, 0 = all type, $char(0) = mixed, "" = no parts
/// IRIS.Temp(key,namespace,"message",msgname,"typenamespace")=non-XSI namespace for parts.
/// IRIS.Temp(key,namespace,"message",msgname)= number of parts
/// IRIS.Temp(key,namespace,"message",msgname,partindex)=partname
/// IRIS.Temp(key,namespace,"message",msgname,partindex,"type")=$listbuild(type namespace,type)
/// IRIS.Temp(key,namespace,"message",msgname,partindex,"element")=$listbuild(element namespace,element)
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method message(pIndex, baseChildlist) [ Internal, Private ]
{
 	#; element MUST be "message"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MUST NOT contain any other attributes
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="message")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	set (xmlelement,typenamespace)=""
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tMessageName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tMessageName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:message","name") Quit
 		}
 		If '..IsNCNAME(tMessageName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:message","name",tMessageName_" : NCNAME") Quit
 		}

 		#; Finished with 'name' attribute
 		Kill tAttrs("name") 

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:message") Quit
 		}
 
  		#; message name must be unique
 		If $Data(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",tMessageName)) {
	    	Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:message",tMessageName) Quit
 		}
 
  		#; Record message
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",tMessageName)=""
 
  		#; Process children of the 'message' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are 'documentation' or 'part' elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				If tType="part" {
	 				Set tSC=..part(tChild,childlist,tMessageName,.xmlelement,.typenamespace)
 				} elseif (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist)
 				} else {
	 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:message","wsdl",tType)	
 				}
 				If $$$ISERR(tSC) Quit
 			} ElseIf ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   		 ($$$xmlaGetLocalName(i%IRISTempTarget,childlist)["Policy") { 
	 			Set tSC=..policy(tChild,childlist,$lb("message",tMessageName))
 				If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while(0)

	If $$$ISOK(tSC) {
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",tMessageName,"xmlelement")=xmlelement
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",tMessageName,"typenamespace")=typenamespace
	}
 
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method operation(pIndex, baseChildlist, pPortTypeName) [ Internal, Private ]
{
 	#; element MUST be "operation"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MAY contain the 'parameterOrder' attribute (NMTOKENS)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain wsdl 'documentation','input', 'output' or 'fault' elements
 	#; element MAY contain other elements for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="operation")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tOperationName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tOperationName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:portType:operation","name") Quit
 		}
 		If '..IsNCNAME(tOperationName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation","name",tOperationName_" : NCNAME") Quit
 		}

 		#; Finished with 'name' attribute
		Kill tAttrs("name")

 		#; Validate optional 'parameterOrder' attribute
 		Set tParameterOrder=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("parameterOrder")))
 		If tParameterOrder'="",'..IsNMTOKENS(tParameterOrder) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation","parameterOrder",tParameterOrder_" : NMTOKENS") Quit
 		}

 		#; Finished with 'parameterOrder' attribute	
 		Kill tAttrs("parameterOrder")

 		#; No other attributes allowed
 		#;If $Data(tAttrs)\2 {
	 	#;	Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:portType:operation") Quit
 		#;}

 		#; Process children of the 'operation' element 
 		Set description=""
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are 'documentation','input','output' or 'fault' elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				If (tType="input") {
	 				Set tSC=..input(tChild,childlist,pPortTypeName,tOperationName)
 				} elseif (tType="output") {
	 				Set tSC=..output(tChild,childlist,pPortTypeName,tOperationName)
 				} elseif (tType="fault") {
	 				Set tSC=..fault(tChild,childlist,pPortTypeName,tOperationName)
 				} elseif (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist,.description)
 				} else {
	 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:portType:operation","wsdl",tType) Quit
 				}
 				If $$$ISERR(tSC) Quit
 			} ElseIf ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) && 
 					 ($$$xmlaGetLocalName(i%IRISTempTarget,childlist) ["Policy") { 
	 			Set tSC=..policy(tChild,childlist,$lb("portType",pPortTypeName,"operation",tOperationName))
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}

 		#; Record the parameter order if present
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"portType",pPortTypeName,"operation",tOperationName)=$lb(tParameterOrder,description)
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method output(pIndex, baseChildlist, pPortTypeName, pOperationName) [ Internal, Private ]
{
 	#; element MUST be "output"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'message' attribute
 	#; element MAY contain the 'name' attribute (NCNAME)
 	#; element MAY contain other attributes for extensibility
 	#; element MUST NOT contain any other elements
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="output")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tOutputName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tOutputName'="",'..IsNCNAME(tOutputName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation:output","name",tOutputName_" : NCNAME") Quit
 		}

 		#; Finished with 'name' attribute
 		Kill tAttrs("name") 

 		#; Validate 'message' attribute
 		Set tMessageName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("message")))
 		If tMessageName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:portType:operation:output","message") Quit
 		}
 		If '..IsQNAME(tMessageName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType:operation:output","message",tMessageName_" : QNAME") Quit
 		}

 		#; Pick out the namespace and localname for the message
 		Set tNS=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,$get(tAttrs("message")))
 		If tNS="" Set tNS=..GetDefaultNamespace(pIndex)
 		If tNS="" Set tNS=""""""
 		Set tMessageName=..GetName(tMessageName)
 		$$$ASSERT(tNS'="")
 		$$$ASSERT(tMessageName'="")

 		#; Finished with 'message' attribute
 		Kill tAttrs("message")

 		#; Look for wsaw:Action attribute
 		Set action=""
 		If $data(tAttrs("Action")),
 		   $$$xmlaGetAttrNamespaceURI(i%IRISTempTarget,tAttrs("Action"))=$$$SOAPWSAWns {
	 		   Set action=$$$xmlaGetAttribute(i%IRISTempTarget,tAttrs("Action"))
 		}

 		#; Record Output
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"portType",pPortTypeName,"operation",pOperationName,"output")=$ListBuild(tNS,tMessageName,action)

 		#; Process the children of the 'output' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=$$$WSDLns) {
	 				If (tType="documentation") {
	 					Set tSC=..documentation(tChild,childlist)
	 				} Else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:portType:operation:output","wsdl",tType)
	 				}
	 			} ElseIf tType["Policy" { 
		 			Set tSC=..policy(tChild,childlist,$lb("portType",pPortTypeName,"operation",pOperationName,"output"))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method part(pIndex, baseChildlist, pMsgName, xmlelement, typenamespace, elementqualified) [ Internal, Private ]
{
 	#; element MUST be "part"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MAY contain the 'element' attribute (QNAME)
 	#; element MAY contain the 'type' attribute (QNAME)
 	#; element MAY contain other unspecified attributes for extensibility
 	#; element MAY contain the wsdl 'documentation' element
 	#; element MAY contain any other element for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="part")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
	 	Set tPartNamespace=""
	 	
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
	
 		#; Validate 'name' attribute
 		Set tPartName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tPartName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:message:part","name") Quit
 		}
 		If '..IsNCNAME(tPartName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:message:part","name",tPartName_" : NCNAME") Quit
 		}

 		#; part name must be unique within message
		For tSeq=1:1:+$Get(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName)) {
 			If $Get(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName,tSeq))=tPartName {
	    		Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:message:part",tPartName) Quit
 			}
		}
		If $$$ISERR(tSC) Quit

 		#; Validate optional 'element' attribute
 		Set tPartElement=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("element")))
 		If tPartElement'="" {
	 		If '..IsQNAME(tPartElement) {
		 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:part","element",tPartElement_" : QNAME") Quit
	 		}
 			Set tPartNamespace=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,tAttrs("element"))
	 		Set tPartElement=..GetName(tPartElement)
 		}

 		#; Validate optional 'type' attribute
 		Set tPartType=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("type")))
		If tPartType'="" {
			If '..IsQNAME(tPartType) {
				Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:part","type",tPartType_" : QNAME") Quit
			}
 			Set tPartNamespace=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,tAttrs("type"))
			Set tPartType=..GetName(tPartType)
 		}

		#; If no prefix, use the default namespace
		Set tTypeNamespace=tPartNamespace
 		If tPartNamespace="" Set tPartNamespace=..GetDefaultNamespace(pIndex)
 		If tPartNamespace="" Set tPartNamespace=""""""
		
 		#; Record part
 		Set tIndex=$Increment(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName))
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName,tIndex)=tPartName
		If tPartElement'="" {
			Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName,tIndex,"element")=$ListBuild(tPartNamespace,tPartElement)
		} ElseIf tPartType'="" {
			Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"message",pMsgName,tIndex,"type")=$ListBuild(tPartNamespace,tPartType)
			If ##class(%XML.Utils.SchemaReader).IsXMLSchemaNS(tPartNamespace) Set tTypeNamespace=""
		}
		
		Set typenamespace=typenamespace_$lb(tTypeNamespace)

		Set isElement=(tPartElement'="")
		If xmlelement="" {
			Set xmlelement=isElement
		} ElseIf xmlelement'=isElement {
			Set xmlelement=$char(0)
		}
		
 		#; Process children of the 'part' element 
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are 'documentation' elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				if (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist)
 				} else {
	 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:part","wsdl",tType)
 				}
 				If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}	
 	} while(0)
 	Quit tSC
}

/// IRIS.Temp(key,namespace,"portType",porttypename)
/// IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname)= parameter order
/// IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"output")= $List(namespace, message name, [action])
/// IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"input")= $List(namespace, message name, [action])
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method portType(pIndex, baseChildlist) [ Internal, Private ]
{
 	#; element MUST be "portType"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MAY contain other unspecified attributes for extensibility
 	#; element MAY contain wsdl 'documentation' or 'operation' elements
 	#; element MAY contain other elements for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="portType")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tPortTypeName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tPortTypeName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:portType","name") Quit
 		}
 		If '..IsNCNAME(tPortTypeName) {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:portType","name",tPortTypeName_" : NCNAME") Quit
 		}

 		#; portType name must be unique
 		If $Data(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"portType",tPortTypeName)) {
	    	Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:portType",tPortTypeName) Quit
 		}

 		#; Record the port type
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"portType",tPortTypeName)=""
 		
 		#; Process children of the 'portType' element 
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are 'documentation' or 'operation' elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				If (tType="operation") {
	 				Set tSC=..operation(tChild,childlist,tPortTypeName)	
 				} elseif (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist)
 				} else {
	 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:portType","wsdl",tType)
 				}
 				If $$$ISERR(tSC) Quit
 			} ElseIf ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) && 
 					 ($$$xmlaGetLocalName(i%IRISTempTarget,childlist) ["Policy") { 
	 			Set tSC=..policy(tChild,childlist,$lb("portType",tPortTypeName))
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)
 	Quit tSC
}

/// This method reads the WSDL at the specified URL and places the parsed data
/// into ^IRIS.Temp. Types information is stored in ^IRIS.Temp at
/// the key(s) found in the TypesKeys multidimensional property. Data
/// parsed from other sections of the WSDL file is stored in ^IRIS.Temp at
/// the keys(s) found in the WSDLKeys multidimensional property. There may
/// be multiple keys in each property as each WSDL file may import other
/// files (by specifying 'location' and 'namespace' urls) which in turn may
/// have imports themselves. The keys have the following formats
/// TypesKeys(key)="",WSDLKeys(key)=target namespace of data (if available)
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method read(pLocationURL As %String, pNamespaceURL As %String) As %Status [ Internal, Private ]
{
	Set tSC=$$$OK
	do {

		#; Test to see if we have already visited this location
		if $Data(i%Locations(pLocationURL)) {
			Quit
		}
		
		#; Create a handler
		Kill %objlasterror
		Set tHandler=##class(%XML.ImportHandler).%New() 
 		If tHandler=$$$NULLOREF {
 			Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.ImportHandler"))
 			Quit
 		}

		#; Parse the XML data at the specified URL
		Set resolver=..EntityResolver
		If resolver="" {
			Set resolver=##class(%XML.SAX.EntityResolver).%New()
			Set resolver.Timeout=10
		}
		Set tSC=##Class(%XML.SAX.Parser).ParseURL(pLocationURL,tHandler,resolver,..SAXFlags,,,..HttpRequest) If $$$ISERR(tSC) Quit
		Set tKey=tHandler.CopyDocument()
		Set tHandler=$$$NULLOREF

 		Set WSDLns=$$$xmlNamespaceToIndex(tKey,$$$WSDLns)
		Set xmlns=$$$xmlNamespaceToIndex(tKey,$$$XMLNSns)

		#; Record that this location has been visited
		Set i%Locations(pLocationURL)=""
		
		#; Record the document key where the data has been stored 
		Set i%WSDLKeys(tKey)=$Get(pNamespaceURL)
		
		#; Read any imports found in the data key
		#; Only interested in imports which are immediate children of definitions
		#; AND are members of the WSDL namespace
		Set root=$$$xmlGetDocumentElement(tKey)
		$$$xmlaGetChildList(tKey,root,rootChildlist,d)
		$$$xmlaFirstChild(tKey,root,rootChildlist,tIndex,descriptor)
 		while tIndex'="" {
			$$$xmlaGetChildListFromDescriptor(tKey,descriptor,childlist)
			#; Check for import
 			If ($$$xmlaGetNodeType(tKey,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(tKey,childlist)=WSDLns) &&
	 		   ($$$xmlaGetLocalName(tKey,childlist)="import") {
	  			
	  			#; Get the location and namespace attributes
				$$$xmlaForEachAttribute(tKey,childlist,o,attribute)
					Set attr=$$$xmlaGetAttributeName(tKey,attribute)
					If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(tKey,attribute)'=xmlns) {
						Set tAttrs(attr)=attribute
					}
				$$$xmlaEndForEachAttribute(tKey,childlist,o,attribute)
		
		 		#; Validate attributes
		 		Set tLocationURL=$$$xmlaGetAttribute(tKey,$get(tAttrs("location")))
		 		Set tNamespaceURL=$$$xmlaGetAttribute(tKey,$get(tAttrs("namespace")))
  				if (tLocationURL'="") {
	  				#; Go and read that specified file
					Set tLocationURL =##class(%XML.Utils.SchemaHandler).GetFullPath(pLocationURL,tLocationURL)
	  				Set tSC=..read(tLocationURL,tNamespaceURL)
	  				If $$$ISERR(tSC) Quit
  				}
 			}
		$$$xmlaNextChild(tKey,root,rootChildlist,tIndex,descriptor)
 		}
	} while(0)
	Quit tSC
}

/// IRIS.Temp(key,namespace,"service",servicename)=""
/// IRIS.Temp(key,namespace,"service",servicename,"port",portname,"binding")= $List(namespace,associated binding name)
/// IRIS.Temp(key,namespace,"service",servicename,"port",portname,"location")= soap address location
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method service(pIndex, baseChildlist) [ Internal, Private ]
{
 	#; element MUST be "service"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain the wsdl: 'documentation' and 'port' elements
 	#; element MAY contain other elements for extensibility
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="service")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tServiceName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tServiceName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:service","name") Quit
 		}
 		If '..IsNCNAME(tServiceName) {
			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:service","name",tServiceName_" : NCNAME") Quit
 		}

 		#; Finished with the 'name' attribute
		Kill tAttrs("name")

 		#; Service name must be unique
 		If $Data(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"service",tServiceName)) {
	    	Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:service",tServiceName) Quit
 		}

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:service") Quit
 		}

 		#; Record the service
 		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"service",tServiceName)=""
 		Set i%Services(tServiceName,i%TargetNamespace)=""

 		#; Process children of the 'service' element 
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process nodes which are elements qualified with the WSDL namespace.
 			If ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   ($$$xmlaGetNamespaceIndex(i%IRISTempTarget,childlist)=%WSDLns) { 
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
 				If (tType="documentation") {
	 				Set tSC=..documentation(tChild,childlist)
 				} elseif (tType="port") {
	 				Set tSC=..servicePort(tChild,childlist,tServiceName)	
 				} else {
 					Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:service","wsdl",tType)
 				}
 				If $$$ISERR(tSC) Quit
 			} ElseIf ($$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE) &&
 			   		 ($$$xmlaGetLocalName(i%IRISTempTarget,childlist)["Policy") { 
	 			Set tSC=..policy(tChild,childlist,$lb("service",tServiceName))
 				If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method servicePort(pIndex, baseChildlist, pServiceName) [ Internal, Private ]
{
 	#; element MUST be "port"
 	#; element MUST be in the WSDL namespace
 	#; element MUST contain the 'name' attribute (NCNAME)
 	#; element MUST contain the 'binding' attribute (QNAME)
 	#; element MUST NOT contain any other attributes
 	#; element MAY contain other elements for extensibility (e.g soap:address)
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="port")
 	$$$ASSERT($$$xmlaGetNamespaceIndex(i%IRISTempTarget,baseChildlist)=%WSDLns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate 'name' attribute
 		Set tPortName=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("name")))
 		If tPortName="" {
	 		Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:service:port","name") Quit
 		}
 		If '..IsNCNAME(tPortName) {
			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:service:port","name",tPortName_" : NCNAME") Quit
 		} 	

 		#; port name must be unique
 		If $Data(^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"service",pServiceName,"port",tPortName)) {
	    	Set tSC=$$$ERROR($$$WSDLDuplicate,"wsdl:service:port",tPortName) Quit
 		}

 		#; Finished with 'name' attribute
 		Kill tAttrs("name")

 		#; Validate 'binding' attribute
 		Set tBindingType=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("binding")))
		If tBindingType="" {
			Set tSC=$$$ERROR($$$WSDLMissingAttribute,"wsdl:service:port","binding") Quit
 		}
		If '..IsQNAME(tBindingType) {
			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:service:port","binding",tBindingType_" : QNAME") Quit
		}

 		#; Pick out the namespace and localname for the port
 		Set tNS=$$$xmlaGetAttrValueNsURI(i%IRISTempTarget,$get(tAttrs("binding")))
		If tNS="" Set tNS=..GetDefaultNamespace(pIndex)
 		If tNS="" Set tNS=""""""
 		Set tBindingName=..GetName(tBindingType)
 		$$$ASSERT(tNS'="")
 		$$$ASSERT(tBindingName'="")


 		#; Finished with the 'binding' attribute
 		Kill tAttrs("binding")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"wsdl:service:port") Quit
 		}

 		#; Record the binding
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"service",pServiceName,"port",tPortName,"binding")=$ListBuild(tNS,tBindingName)

 		#; Process the children of the 'servicePort' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)

 			#; Only process 'address' elements which are qualified with the SOAP namespace or
 			#; 'documentation' elements qualified with the WSDL namespace
			Set tSoapLocation="" 
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If (tNS=$$$WSDLns) {
		 			if (tType="documentation") {
			 			Set tSC=..documentation(tChild,childlist)
		 			} else {
		 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:service:port","wsdl",tType)
	 				}
		 		} ElseIf (tNS=$$$SOAPns) || (tNS=$$$SOAP12ns){
	 				If (tType="address") {
		 				Set tSC=..soapAddress(tChild,childlist,.tSoapLocation)
						if ('$$$ISERR(tSC)) {
		 					Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"service",pServiceName,"port",tPortName,"location")=tSoapLocation
						}
	 				} else {
		 				Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:service:port","soap",tType)
	 				}
	 			} ElseIf tType["Policy" { 
		 			Set tSC=..policy(tChild,childlist,$lb("service",pServiceName,"port",tPortName))
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method soapAddress(pIndex, baseChildlist, pLocation) [ Internal, Private ]
{
 #; element MUST be "address"
 #; element MUST be in the SOAP namespace
 #; element MUST contain the 'location' attribute (anyURI)
 #; element MUST NOT contain any other attributes
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="address")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=%SOAPns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate the 'location' attribute
 		Set pLocation=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("location")))
 		If pLocation'="" {
 			If '..IsANYURI(pLocation) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"wsdl:address","location",pLocation_" : anyURI") Quit
 			}
 		}

 		#; Finished with 'location' attribute
 		Kill tAttrs("location")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"soap:address") Quit
 		}
 		If $$$ISERR(tSC) Quit
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method soapBinding(pIndex, baseChildlist, pBindingStyle, pBindingTransport) [ Internal, Private ]
{
 	#; element MUST be "binding"
 	#; element MUST be in the SOAP namespace
 	#; element MAY contain the 'transport' attribute (anyURI)
 	#; element MAY contain the 'style' attribute (NCNAME)
 	#; element MUST NOT contain any other attributes
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="binding")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=%SOAPns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

		#; Validate the optional 'transport' attribute
 		Set pBindingTransport=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("transport")))
 		If pBindingTransport="" Set pBindingTransport=$$$SOAPhttp
		If '..IsANYURI(pBindingTransport) {
			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:binding","transport",pBindingTransport_" : anyURI") Quit
		}

 		#; Finished with 'transport' attribute
 		Kill tAttrs("transport")

 		#; Validate 'style' attribute
 		Set style=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("style")))
		If style'="" Set pBindingStyle=style
		If pBindingStyle'="" {
			if (pBindingStyle'="document"&&(pBindingStyle'="rpc")) {
				Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:binding","style",pBindingStyle_" : style") Quit
			}
		}

 		#; Finished with the 'style' attribute
		Kill tAttrs("style")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"soap:binding") Quit
 		}
 		If $$$ISERR(tSC) Quit
 	} while(0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method iscBinding(pIndex, baseChildlist, charset) [ Internal, Private ]
{
 	#; element MUST be "binding"
 	#; element MUST be in the ISC SOAP namespace
 	#; element MAY contain the 'charset' attribute (anyURI)
 	#; element MUST NOT contain any other attributes
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="binding")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=$$$ISCSOAPns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

		#; Validate the optional 'charset' attribute
 		Set charset=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("charset")))

 		#; Finished with 'charset' attribute
 		Kill tAttrs("charset")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"isc:binding") Quit
 		}
 		If $$$ISERR(tSC) Quit
 	} while(0)
 	Quit tSC
}

/// multipartRelated element for MIME binding
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method mimeMultipartRelated(pIndex, baseChildlist, pBindingName, pOperationName, pOpMsg, ByRef bodyFound) [ Internal, Private ]
{
 	#; element MUST be "multipartRelated"
 	#; element MUST be in the WSDL MIME namespace
 	#; element MAY contain the 'mime:part' element
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="multipartRelated")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=$$$WSDLMIMEns)
 	Set tSC=$$$OK
 	do {
 		#; Process the children of the 'bindingOperationMessage' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If tNS=$$$WSDLMIMEns {
		 			If tType="part" {
	 					Set tSC=..mimePart(tChild,childlist,pBindingName,pOperationName,pOpMsg,.bodyFound)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation:multipartRelated","mime",tType)
		 			}
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)
 	Quit tSC
}

/// part element for MIME binding
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method mimePart(pIndex, baseChildlist, pBindingName, pOperationName, pOpMsg, ByRef bodyFound) [ Internal, Private ]
{
 	#; element MUST be "part"
 	#; element MUST be in the WSDL MIME namespace
 	#; element MAY contain the 'soap:body' or 'mime:content' elements
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="part")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=$$$WSDLMIMEns)
 	Set tSC=$$$OK
 	do {
 		#; Process the children of the 'bindingOperationMessage' element
		$$$xmlaFirstChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		while (tChild'="") {
			$$$xmlaGetChildListFromDescriptor(i%IRISTempTarget,descriptor,childlist)
	 		If $$$xmlaGetNodeType(i%IRISTempTarget,descriptor)=$$$xmlELEMENTNODE {
	 			Set tNS=$$$xmlaGetNamespaceURI(i%IRISTempTarget,childlist)
	 			Set tType=$$$xmlaGetLocalName(i%IRISTempTarget,childlist) 
	 			If tNS=$$$WSDLMIMEns {
		 			If tType="content" {
	 					Set tSC=..mimeContent(tChild,childlist,pBindingName,pOperationName,pOpMsg)
		 			}
	 			} ElseIf $get(%SOAPns)="" {
			 		Set tSC = $$$ERROR($$$NoSOAPNamespace,i%TargetNamespace)
		 		} ElseIf (tNS=%SOAPns) {
		 			If tType="body" {
			 			Set bodyFound=1
	 					Set tSC=..soapBody(tChild,childlist,pBindingName,pOperationName,pOpMsg)
		 			} else {
			 			Set tSC=$$$ERROR($$$WSDLUnrecognizedElement,"wsdl:binding:operation:multipartRelated","mime",tType)
		 			}
	 			}
	 			If $$$ISERR(tSC) Quit
 			}
			$$$xmlaNextChild(i%IRISTempTarget,pIndex,baseChildlist,tChild,descriptor)
 		}
 	} while (0)

 	Quit tSC
}

/// content element for MIME binding
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method mimeContent(pIndex, baseChildlist, pBindingName, pOperationName, pOpMsg) [ Internal, Private ]
{
 	#; element MUST be "content"
 	#; element MUST be in the WSDL MIME namespace
 	#; element MAY contain the 'part' attribute
 	#; element MAY contain the 'type' attribute
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="content")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=$$$WSDLMIMEns)
 	Set tSC=$$$OK
 	do {
		Set (tPart,tType)=""
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate the optional 'part' attribute
 		Set tPart=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("part")))
 		If tPart'="" {
 			If '..IsNMTOKEN(tPart) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"mime:cxontent","part",tPart_" : NMTOKEN") Quit
 			}
 		}

 		#; Finished with 'part' attribute
 		Kill tAttrs("part")

 		#; Validate the optional 'type' attribute
 		Set tType=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("type")))

 		#; Finished with 'type' attribute
 		Kill tAttrs("type")

 		If tPart'="" {
			Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,pOpMsg,"mimeparts",tPart)=""
 		}
 	} while (0)
 	Quit tSC
}

/// body element for SOAP binding
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method soapBody(pIndex, baseChildlist, pBindingName, pOperationName, pOpMsg) [ Internal, Private ]
{
 	#; element MUST be "body"
 	#; element MUST be in the SOAP namespace
 	#; element MAY contain the 'encodingStyle' attribute (anyURI)
 	#; element MAY contain the 'namespace' attribute (anyURI)
 	#; element MAY contain the 'use' attribute (NCNAME)
 	#; element MAY contain the 'parts' attribute (NMTOKENS)
 	#; element MUST NOT contain any other attributes
 	#; element MUST NOT contain any other elements
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="body")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=%SOAPns)
 	Set tSC=$$$OK
 	do {
		Set (tEncodingStyle,tNamespace,tParts,tUse)=""
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate the optional 'encodingStyle' attribute
 		Set tEncodingStyle=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("encodingStyle")))
 		If tEncodingStyle'="" {
 			If '..IsANYURI(tEncodingStyle) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:body","encodingStyle",tEncodingStyle_" : anyURI") Quit
 			}
 		}

 		#; Finished with 'encodingStyle' attribute
 		Kill tAttrs("encodingStyle")

 		#; Validate the optional 'namespace' attribute
 		Set tNamespace=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("namespace")))
 		If tNamespace'="" {
 			If '..IsANYURI(tNamespace) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:body","namespace",tNamespace_" : anyURI") Quit
 			}
 		}

 		#; Finished with 'namespace' attribute
 		Kill tAttrs("namespace")

 		#; Validate the optional 'parts' attribute
 		Set tParts=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("parts")))
 		If tParts'="" {
 			If '..IsNMTOKENS(tParts) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:body","parts",tParts_" : NMTOKENS") Quit
 			}
 			Set tParts=..NormalizeTokens(tParts)
 		}

 		#; Finished with the 'parts' attribute
		Kill tAttrs("parts")

 		#; Validate 'use' attribute
 		Set tUse=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("use")))
		If tUse'="" {
			if (tUse'="encoded"&&(tUse'="literal")) {
				Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:body","use",tUse_" : body use") Quit
			}
		}

 		#; Finished with the 'use' attribute
		Kill tAttrs("use")
		
		#; Ignore the wsdl:required attribute
		Kill tAttrs("required")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"soap:body") Quit
 		}
		If $$$ISERR(tSC) Quit

		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,pOpMsg,"encodingStyle")=tEncodingStyle
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,pOpMsg,"namespace")=tNamespace
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,pOpMsg,"parts")=tParts
		Set ^IRIS.Temp(i%WSDLTarget,i%TargetNamespace,"binding",pBindingName,"operation",pOperationName,pOpMsg,"use")=tUse
 	} while (0)
 	Quit tSC
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method soapOperation(pIndex, baseChildlist, pSoapBindingStyle, pSoapAction) [ Internal, Private ]
{
	#; element MUST be "operation"
 	#; element MUST be in the SOAP namespace
 	#; element MAY contain the 'soapAction' attribute (anyURI)
 	#; element MAY contain the 'style' attribute (NCNAME)
    #; element MUST NOT contain any other attributes
 	#; element MUST NOT contain any other elements
 	$$$ASSERT($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="operation")
 	$$$ASSERT($$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)=%SOAPns)
 	Set tSC=$$$OK
 	do {
		$$$xmlaForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)
			Set attr=$$$xmlaGetAttributeName(i%IRISTempTarget,attribute)
			If (attr'="xmlns") && ($$$xmlaGetAttrNamespaceIndex(i%IRISTempTarget,attribute)'=%xmlns) {
				Set tAttrs(attr)=attribute
			}
		$$$xmlaEndForEachAttribute(i%IRISTempTarget,baseChildlist,o,attribute)

 		#; Validate the optional 'soapAction' attribute
 		Set pSoapAction=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("soapAction")))
 		If pSoapAction'="" {
 			If '..IsANYURI(pSoapAction) {
	 			Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:binding:operation","soapAction",pSoapAction_" : anyURI") Quit	 		
 			}
 		}

 		#; Finished with 'soapAction' attribute
 		Kill tAttrs("soapAction")

 		#; Validate 'style' attribute
 		Set style=$$$xmlaGetAttribute(i%IRISTempTarget,$get(tAttrs("style")))
 		If style'="" Set pSoapBindingStyle=style
		If pSoapBindingStyle'="" {
			if (pSoapBindingStyle'="document"&&(pSoapBindingStyle'="rpc")) {
				Set tSC=$$$ERROR($$$WSDLBadAttributeValue,"soap:binding:operation","style",pSoapBindingStyle_" : binding style") Quit
			}
		}

 		#; Finished with the 'style' attribute
		Kill tAttrs("style")
		
		#; Skip soapActionRequired attribute
		Kill tAttrs("soapActionRequired")

 		#; No other attributes allowed
 		If $Data(tAttrs)\2 {
	 		Set tSC=$$$ERROR($$$WSDLBadAttributes,"soap:binding:operation") Quit
 		}
		If $$$ISERR(tSC) Quit
 	} while (0)
 	Quit tSC
}

/// Skip types
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method types(pIndex) As %Status [ Internal, Private ]
{
	Quit $$$OK
}

/// @loc@("%policy")=number of policies at this location
/// @loc@("%policy",index)=index of a policy as string
/// IRIS.Temp(key,"%anyPolicy")=1 if any policy
/// 
/// loc my be one of the following
/// 	IRIS.Temp(key,namespace)
/// 	IRIS.Temp(key,namespace,"service",servicename)
/// 	IRIS.Temp(key,namespace,"service",servicename,"port",portname)
/// 	IRIS.Temp(key,namespace,"binding",bindingname)
/// 	IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname)
/// 	IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"input")
/// 	IRIS.Temp(key,namespace,"binding",bindingname,"operation",operationname,"output")
/// 	IRIS.Temp(key,namespace,"portType",porttypename)
/// 	IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname)
/// 	IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"input")
/// 	IRIS.Temp(key,namespace,"portType",porttypename,"operation",operationname,"output")
/// 	IRIS.Temp(key,namespace,"message",msgname)
///  		
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method policy(pIndex, baseChildlist, subscripts As %String) As %Status [ Internal, Private ]
{
 	#; element MUST be "Policy" or "PolicyReference"
 	#; element MUST be in the WS-Policy 1.2 or 1.5 namespace
 	$$$ASSERT(($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="Policy") || ($$$xmlaGetLocalName(i%IRISTempTarget,baseChildlist)="PolicyReference"))
 	
 	Set ns=$$$xmlaGetNamespaceURI(i%IRISTempTarget,baseChildlist)
 	If (ns=$$$SOAPWSPolicy12) || (ns=$$$SOAPWSPolicy15) {
	 	If subscripts="" {
			Set loc="^IRIS.Temp("""_i%WSDLTarget_""",""%policy"")"
	 	} Else {
			Set loc="^IRIS.Temp("""_i%WSDLTarget_""","""_i%TargetNamespace_""""
			For i=1:1:$listlength(subscripts) {
				Set loc=loc_","""_$list(subscripts,i)_""""
			}
			Set loc=loc_",""%policy"")"
	 	}
		Set policyIndex=$get(@loc,0)+1
		Set @loc=policyIndex
		// elementId value is invariant across updates to DOM which will happen later.
		Set elementId=$$$xmlaNodeIdToElementId(i%IRISTempTarget,pIndex)
		Set @loc@(policyIndex)=$lb(i%IRISTempTarget,elementId)
		Set ^IRIS.Temp(i%WSDLTarget,"%anyPolicy")=1
 	}
	
	Quit $$$OK
}

/// Output Policy to the current writer.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method WritePolicy(writer As %XML.Writer, nodeDesc As %List, wsdlElement As %String) As %Status [ Internal, Private ]
{
	Set node=##class(%XML.Node).%New()
	Set docId=$list(nodeDesc,1)
	Set elementId=$list(nodeDesc,2)
	Set node.DocId=docId
	Set node.NodeId=$$$xmlaElementIdToNodeId(docId,elementId)

	If wsdlElement'="" {
		Do node.SetAttribute("wsdlElement",$$$SOAPWSISCConfig,wsdlElement)
	}

	If wsdlElement="" {
		Set sc=writer.Canonicalize(node,,1)
	} Else {
		Set sc=writer.CanonicalTree(node)
	}

	Quit sc
}

}
