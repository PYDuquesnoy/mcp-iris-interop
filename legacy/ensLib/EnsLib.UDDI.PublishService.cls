/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class implements Spec from 
/// http://www.oasis-open.org/committees/uddi-spec/doc/tn/uddi-spec-tc-tn-wsdl-v2.htm
Class EnsLib.UDDI.PublishService Extends (EnsLib.UDDI.Saver, EnsLib.UDDI.UDDIStandardKeys) [ System = 4 ]
{

/// This Method implements spec given at:
/// http://www.oasis-open.org/committees/uddi-spec/doc/tn/uddi-spec-tc-tn-wsdl-v2.htm#_Toc76437775
Method PublishPortTypeTModel(pName As %String, pNameSpace As %String, pWsdlUrl As %String, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status

	#dim tTModel As EnsLib.UDDI.uddi.tModel
	#dim tCategoryBag As EnsLib.UDDI.uddi.categoryBag
	
	/// Use for Categorization
	#dim tKeyName   As %String
	#dim tKeyValue  As %String
	#dim tTModelKey As %String

	$$$PROLOGUE
	
	#; Create an instance of tModel
	Set tSC=..NewTModel(pName, pWsdlUrl, .tTModel)
	If $$$ISERR(tSC) Quit 
	
	#; This TModel may be categorized as a PortType
	#;
	#; The tModel MUST contain a categoryBag, and the 
	#; categoryBag MUST contain a keyedReference with a tModelKey 
	#; of the WSDL Entity Type category system and a keyValue of "portType". 
	
	$$$NEW(tCategoryBag,"EnsLib.UDDI.uddi.categoryBag")

	Set tKeyName   = ..#UddiOrgWsdlEntityKeyName
	Set tKeyValue  = ..#UddiOrgWsdlEntityPortTypeKeyValue
	Set tTModelKey = ..#UddiOrgWsdlEntityTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit
	
	#; Check if wsdl:portType has a targetNamespace 
	Set tSC = ..AddNamespaceCategory(tCategoryBag,pNameSpace)
	If $$$ISERR(tSC) Quit

	Set tTModel.categoryBag = tCategoryBag
	
	Set tSC = ..PublishTModel(tTModel, .pTModelKey)

	$$$EPILOGUE
}

/// This Method implements spec given at:
/// http://www.oasis-open.org/committees/uddi-spec/doc/tn/uddi-spec-tc-tn-wsdl-v2.htm#_Toc76437776
Method PublishBindingTModel(pName As %String, pNameSpace As %String, pWsdlUrl As %String, pPortTypeKey As %String, pSOAPBinding As %Boolean, pSOAPTransportURI As %String, pHTTPBinding As %Boolean, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status

	#dim tTModel As EnsLib.UDDI.uddi.tModel
	#dim tCategoryBag As EnsLib.UDDI.uddi.categoryBag
	
	/// Use for Categorization
	#dim tKeyName   As %String
	#dim tKeyValue  As %String
	#dim tTModelKey As %String

	$$$PROLOGUE
	
	#; Create an instance of tModel
	Set tSC=..NewTModel(pName, pWsdlUrl, .tTModel)
	If $$$ISERR(tSC) Quit 
	
	#; The tModel MUST contain a categoryBag, and the categoryBag MUST contain 
	#; at least the following keyedReference elements:
	#;
   	#; 1. A keyedReference with a tModelKey of the WSDL Entity Type category system 
   	#;		and a keyValue of "binding".
   	#; 2. A keyedReference with a tModelKey of the WSDL portType Reference category system 
   	#;		and a keyValue of the tModelKey that models the wsdl:portType to which the wsdl:binding relates.
   	#; 3. A keyedReference with a tModelKey of the UDDI Types category system 
   	#;		and a keyValue of "wsdlSpec" for backward compatibility.
   	#; 4. One or two keyedReferences as required to capture the protocol 
   	#;		and optionally the transport information
	
	$$$NEW(tCategoryBag,"EnsLib.UDDI.uddi.categoryBag")

	Set tKeyName   = ..#UddiOrgWsdlEntityKeyName
	Set tKeyValue  = ..#UddiOrgWsdlEntityBindingKeyValue
	Set tTModelKey = ..#UddiOrgWsdlEntityTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit
	
	Set tKeyName   = ..#UddiOrgPortTypeRefKeyName
	Set tKeyValue  = pPortTypeKey
	Set tTModelKey = ..#UddiOrgPortTypeRefTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit
	
	Set tKeyName   = ..#UddiOrgTypesKeyName
	Set tKeyValue  = ..#UddiOrgTypesWsdlKeyValue
	Set tTModelKey = ..#UddiOrgTypesTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit
	
	if (pSOAPBinding){
		Set tKeyName   = ..#UddiOrgProtocolCategorizationKeyName
		Set tKeyValue  = ..#UddiOrgProtocolCategorizationSoapV3KeyValue
		Set tTModelKey = ..#UddiOrgProtocolCategorizationTmodelKeyV3
		Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
		If $$$ISERR(tSC) Quit
		
		if ("http://schemas.xmlsoap.org/soap/http"=pSOAPTransportURI){
			Set tKeyName   = ..#UddiOrgTransportCategorizationKeyName
			Set tKeyValue  = ..#UddiOrgTransportCategorizationHttpV3KeyValue
			Set tTModelKey = ..#UddiOrgTransportCategorizationTmodelKeyV3
			Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
			If $$$ISERR(tSC) Quit
		}
	}
	
	if (pHTTPBinding) {
		Set tKeyName   = ..#UddiOrgProtocolCategorizationKeyName
		Set tKeyValue  = ..#UddiOrgProtocolCategorizationHttpV3KeyValue
		Set tTModelKey = ..#UddiOrgProtocolCategorizationTmodelKeyV3
		Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
		If $$$ISERR(tSC) Quit
	}
	
	#; Check if wsdl:binding has a targetNamespace 
	Set tSC = ..AddNamespaceCategory(tCategoryBag,pNameSpace)
	If $$$ISERR(tSC) Quit

	Set tTModel.categoryBag = tCategoryBag
	
	Set tSC = ..PublishTModel(tTModel, .pTModelKey)

	$$$EPILOGUE
}

Method PublishTModel(pTModel As EnsLib.UDDI.uddi.tModel, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status
	#dim tSave As EnsLib.UDDI.SaveTModel
	#dim tTModels As %ListOfObjects
	#dim tTruncated As %Boolean

	$$$PROLOGUE

	#; What to save TModels
	$$$NEW(tSave,"EnsLib.UDDI.SaveTModel")
	Set tTModels = ""

	#; Add the TModel to the list of those to be published
	Set tSC=tSave.AddTModel(pTModel)
	If $$$ISERR(tSC) Quit 
	
	
	#; Now publish
	Set tSC=tSave.Send(..Connection,.tTModels,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"Save TModel was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetTModelDetail).DisplayTModels(tTModels)
	
	#; Retrieve the key and assign the output
	Set pTModelKey=tTModels.GetAt(1).tModelKey

	$$$EPILOGUE
}

/// This Method implements spec given at:
/// http://www.oasis-open.org/committees/uddi-spec/doc/tn/uddi-spec-tc-tn-wsdl-v2.htm#_Toc76437778
Method PublishBinding(pServiceKey As EnsLib.UDDI.uddi.serviceKey, pDescription As %String, pLocationURI As %String, pLocationURIType As %String, pPortName As %String, pPortTypeRef As EnsLib.UDDI.uddi.tModelKey, pBindingRef As EnsLib.UDDI.uddi.tModelKey, Output pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	#dim tSC As %Status

	#dim tBindingTemplates As %ListOfObjects
	#dim tSave As EnsLib.UDDI.SaveBinding
	#dim tBindingTemplate As EnsLib.UDDI.uddi.bindingTemplate
	#dim tAccessPoint As EnsLib.UDDI.uddi.accessPoint
	#dim tModelInstanceInfo As EnsLib.UDDI.uddi.tModelInstanceInfo
	#dim tModelInstanceDetails As EnsLib.UDDI.uddi.tModelInstanceDetails
	#dim tTruncated As %Boolean
	#dim tListDescription As EnsLib.UDDI.uddi.listDescription
	
	$$$PROLOGUE
	
	#; Want to save a Binding
	$$$NEW(tSave,"EnsLib.UDDI.SaveBinding")

	#; Create an instance of a binding template
	$$$NEW(tBindingTemplate,"EnsLib.UDDI.uddi.bindingTemplate")
	
	#; Create an access point for the binding template
	$$$NEW(tAccessPoint,"EnsLib.UDDI.uddi.accessPoint")
	
	#; Access point is bogus (need to substitute a reference to a preexisting web service here)
	Set tAccessPoint.useType=pLocationURIType
	Set tAccessPoint.content=pLocationURI
	
	Set tBindingTemplate.accessPoint=tAccessPoint
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tBindingTemplate.bindingKey=$c(0)
	
	#; Must specify the service key, key MUST reference a pre-existing Service in the registry
	Set tBindingTemplate.serviceKey=pServiceKey
	
	#; Add a description
	if (pDescription) {
		Set tSC=..addDescriptionToList(tBindingTemplate.description,pDescription)
		If $$$ISERR(tSC) Quit
	}
	
	#; The bindingTemplate tModelInstanceDetails element MUST contain 
	#; at least the following tModelInstanceInfo elements:
	
	$$$NEW(tModelInstanceDetails,"EnsLib.UDDI.uddi.tModelInstanceDetails")

	#; 1. A tModelInstanceInfo with a tModelKey of the tModel that models the wsdl:binding 
	#; that this port implements. The instanceParms of this tModelInstanceInfo MUST contain 
	#; the wsdl:port local name.

	$$$NEW(tModelInstanceInfo,"EnsLib.UDDI.uddi.tModelInstanceInfo")
	
	#; Use the tModelKey for Binding TModel
	Set tModelInstanceInfo.tModelKey=pBindingRef
	
	$$$NEW(tModelInstanceInfo.instanceDetails,"EnsLib.UDDI.uddi.instanceDetails")
	Set tModelInstanceInfo.instanceDetails.instanceParms = "<port name="""_pPortName_"""/>"
	
	#; Add the tModelInfo to the binding template
	Do tModelInstanceDetails.tModelInstanceInfo.Insert(tModelInstanceInfo)

	#; 2. A tModelInstanceInfo with a tModelKey of the tModel that models the wsdl:portType.
	$$$NEW(tModelInstanceInfo,"EnsLib.UDDI.uddi.tModelInstanceInfo")
	
	#; Use the tModelKey for PortType TModel
	Set tModelInstanceInfo.tModelKey=pPortTypeRef
	
	#; Add the tModelInfo to the binding template
	Do tModelInstanceDetails.tModelInstanceInfo.Insert(tModelInstanceInfo)
	
	#; Add the instance details to the binding template
	Set tBindingTemplate.tModelInstanceDetails=tModelInstanceDetails
	
	#; Add this to the binding templates to save/update
	Set tSC=tSave.AddBindingTemplate(tBindingTemplate)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(..Connection,.tTruncated,.tBindingTemplates)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The SaveBinding operation was truncated"
	}
		
	Do ##class(EnsLib.UDDI.GetBindingDetail).DisplayBindingTemplates(tBindingTemplates)
	
	#; Retrieve the key and assign the output
	Set pBindingKey=tBindingTemplates.GetAt(1).bindingKey
	
	$$$EPILOGUE
}

/// This method implements spec given at:
/// http://www.oasis-open.org/committees/uddi-spec/doc/tn/uddi-spec-tc-tn-wsdl-v2.htm#_Toc76437777
/// 
/// NB: This Method does not publish Port Bindings as required by spec. Port Bindings are published
/// separately.
Method PublishBusinessService(pBusinessKey As EnsLib.UDDI.uddi.businessKey, pHumanName As %String, pLocalName As %String, pDescription As %String, pNameSpace As %String, pImplementedBy As %String, Output pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	#dim tSC As %Status
	#dim tTruncated As %Boolean
	#dim tSave As EnsLib.UDDI.SaveService
	#dim tBusinessService As EnsLib.UDDI.uddi.businessService
	#dim tBusinessServices As %ListOfObjects
	#dim tCategoryBag As EnsLib.UDDI.uddi.categoryBag
	
	/// Use for Categorization
	#dim tKeyName   As %String
	#dim tKeyValue  As %String
	#dim tTModelKey As %String	
	
	$$$PROLOGUE

	Set tSC = ..EnsureCacheTModel()
	If $$$ISERR(tSC) Quit

	#; Want to save a Service
	$$$NEW(tSave,"EnsLib.UDDI.SaveService")
	
	#; Create an instance of BusinessService
	$$$NEW(tBusinessService,"EnsLib.UDDI.uddi.businessService")
	
	#; MUST Set the BusinessKey to that was acquired when we saved a business above
	Set tBusinessService.businessKey=pBusinessKey
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign key 
	Set tBusinessService.serviceKey=$c(0)
	
	#; Set the service name
	if (pHumanName=""){
		Set pHumanName = pLocalName
	}
	Set tSC=..addNameToList(tBusinessService.name,pHumanName)
	If $$$ISERR(tSC) Quit
	
	#; Add a description
	if (pDescription){
		Set tSC=..addDescriptionToList(tBusinessService.description,pDescription)
		If $$$ISERR(tSC) Quit
	}
	
	#; The businessService MUST contain a categoryBag, 
	#; and the categoryBag MUST contain at least the following keyedReference elements:
	
	$$$NEW(tCategoryBag,"EnsLib.UDDI.uddi.categoryBag")

	#; 1. A keyedReference with a tModelKey of the WSDL Entity Type category system and 
	#; 		a keyValue of "service".
	
	Set tKeyName   = ..#UddiOrgWsdlEntityKeyName
	Set tKeyValue  = ..#UddiOrgWsdlEntityServiceKeyValue
	Set tTModelKey = ..#UddiOrgWsdlEntityTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit

	#; 2. A keyedReference with a tModelKey of the XML Local Name category system and a keyValue 
	#; 		that is the value of the name attribute of the wsdl:service.

	Set tKeyName   = ..#UddiOrgXmlLocalNameKeyName
	Set tKeyValue  = pLocalName
	Set tTModelKey = ..#UddiOrgXmlLocalNameTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit

	#; 3. A keyedReference with a tModelKey to InterSystems Web Service

	Set tKeyName   = ..#InterSystemsComWebServiceImplentedKeyName
	Set tKeyValue  = pImplementedBy
	Set tTModelKey = ..#InterSystemsComWebServiceTModelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit

	#; Check if wsdl:service has a targetNamespace 
	Set tSC = ..AddNamespaceCategory(tCategoryBag,pNameSpace)
	If $$$ISERR(tSC) Quit

	Set tBusinessService.categoryBag = tCategoryBag
		
	#; Add this to the business services to save/update
	Set tSC=tSave.AddBusinessService(tBusinessService)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(..Connection,.tBusinessServices,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The Save Service operation was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetServiceDetail).DisplayBusinessServices(tBusinessServices)
	
	#; Retrieve the service key and assign the output
	Set pServiceKey=tBusinessServices.GetAt(1).serviceKey
	
	$$$EPILOGUE
}

ClassMethod NewTModel(pName As %String, pWsdlUrl As %String, Output pTModel As EnsLib.UDDI.uddi.tModel) As %Status
{
	#dim tSC As %Status
	#; Create an instance of tModel
	$$$NEW(pTModel,"EnsLib.UDDI.uddi.tModel")
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set pTModel.tModelKey=$c(0)
	
	#; Set the name
	Set pTModel.name.content=pName
	
	#; Add an overview document
	Set tSC=..AddOverviewDocToTModel(pTModel, pWsdlUrl)
	Quit tSC
}

ClassMethod CreateOverviewDoc(pWsdlUrl As %String, Output pOverviewDoc As EnsLib.UDDI.uddi.overviewDoc) As %Status
{
	#dim tSC As %Status

	#; Create an overview document
	$$$NEW(pOverviewDoc,"EnsLib.UDDI.uddi.overviewDoc")
	
	#; Add a description of what the document is
	Set tSC=..addDescriptionToList(pOverviewDoc.description,"Reference to WSDL URL")
	If $$$ISERR(tSC) Quit tSC
	
	#; Set the URL
	Set pOverviewDoc.overviewURL.content=pWsdlUrl
	Set pOverviewDoc.overviewURL.useType="wsdlInterface"
	Quit $$$OK
}

ClassMethod AddOverviewDocToTModel(pTModel As EnsLib.UDDI.uddi.tModel, pWsdlUrl As %String) As %Status
{
	#dim tSC As %Status
	#dim tOverviewDoc As EnsLib.UDDI.uddi.overviewDoc
	
	#; Create an overview document
	Set tSC=..CreateOverviewDoc(pWsdlUrl, .tOverviewDoc)
	If $$$ISERR(tSC) Quit tSC
	
	#; Add the document to the tModel
	Set tSC=pTModel.overviewDoc.Insert(tOverviewDoc)
	Quit tSC
}

ClassMethod AddNamespaceCategory(pCategoryBag As EnsLib.UDDI.uddi.categoryBag, pNameSpace As %String) As %Status
{
	#; If the wsdl:portType has a targetNamespace then the categoryBag MUST also contain 
	#; an additional keyedReference with a tModelKey of the XML Namespace category system 
	#; and a keyValue of the target namespace of the wsdl:definitions element that contains 
	#; the wsdl:portType. If the targetNamespace is absent from the portType, a categoryBag 
	#; MUST NOT contain a keyedReference to the XML Namespace category system. 

	#dim tSC As %Status
	#dim tKeyName   As %String
	#dim tKeyValue  As %String
	#dim tTModelKey As %String

	if (pNameSpace'="") {
		Set tKeyName   = ..#UddiOrgXmlNamespaceKeyName
		Set tKeyValue  = pNameSpace
		Set tTModelKey = ..#UddiOrgXmlNamespaceTmodelKeyV3
		Set tSC=..addReferenceToList(pCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
		If $$$ISERR(tSC) Quit tSC
	}
	
	Quit $$$OK
}

Method PublishPTTModel(pPortType As EnsLib.UDDI.wsdl.PortType, pWsdlUrl As %String, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status [ Private ]
{
	#dim tSC As %Status
	Set tSC = ..PublishPortTypeTModel(pPortType.LocalName, pPortType.Namespace, pWsdlUrl, .pTModelKey)
	Quit tSC
}

Method PublishBTModel(pBinding As EnsLib.UDDI.wsdl.Binding, pWsdlUrl As %String, pPortTypeKey As %String, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status [ Private ]
{
	#dim tSC As %Status
	Set tSC = ..PublishBindingTModel(pBinding.LocalName, pBinding.Namespace, pWsdlUrl, pPortTypeKey, pBinding.SOAPBinding, pBinding.SOAPTransportURI, pBinding.HTTPBinding, .pTModelKey)
	Quit tSC
}

Method PublishBT(pServiceKey As EnsLib.UDDI.uddi.serviceKey, pPort As EnsLib.UDDI.wsdl.Port, pPortTypeRef As EnsLib.UDDI.uddi.tModelKey, pBindingRef As EnsLib.UDDI.uddi.tModelKey, Output pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status [ Private ]
{
	#dim tSC As %Status
	Set tSC = ..PublishBinding(pServiceKey, "", pPort.LocationURI, pPort.LocationURIType, pPort.BindingLocalName, pPortTypeRef, pBindingRef, .pBindingKey)
	Quit tSC
}

Method PublishBSOnly(pBusinessKey As EnsLib.UDDI.uddi.businessKey, pSOAPService As EnsLib.UDDI.wsdl.SOAPService, Output pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status [ Private ]
{
	#dim tSC As %Status
	Set tSC = ..PublishBusinessService(pBusinessKey, pSOAPService.HumanName, pSOAPService.LocalName, pSOAPService.Description,pSOAPService.TargetNamespace, pSOAPService.ImplementedBy, .pServiceKey)
	Quit tSC
}

Method MapServiceToUDDI(pBusinessKey As EnsLib.UDDI.uddi.businessKey, pServiceData As EnsLib.UDDI.wsdl.BusinessService, Output pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	#dim tSC as %Status
	#dim tBindingTModelKeys As %Collection.ArrayOfDT
	#dim tPortTypeTModelKeys As %Collection.ArrayOfDT
	#dim tServiceKey As EnsLib.UDDI.uddi.serviceKey
	#dim tPortTypeKey As EnsLib.UDDI.uddi.tModelKey
	#dim tBindingKey As EnsLib.UDDI.uddi.tModelKey
	#dim tBTKey As EnsLib.UDDI.uddi.bindingKey
	
	#dim tCurKey As %String
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey
	#dim tLocalName As %String
	
	#dim tPortType As EnsLib.UDDI.wsdl.PortType
	#dim tBinding As EnsLib.UDDI.wsdl.Binding
	#dim tSOAPService As EnsLib.UDDI.wsdl.SOAPService
	#dim tPort As EnsLib.UDDI.wsdl.Port
	
	#dim count as %Integer
	
	Set tSC = $$$OK
	
	Set tPortTypeTModelKeys = ##class(%Library.ArrayOfDataTypes).%New()
	Set tBindingTModelKeys  = ##class(%Library.ArrayOfDataTypes).%New()
	
	Set tCurKey = ""
	Do {
		Set tPortType = pServiceData.PortTypes.GetNext(.tCurKey)
		Continue:tPortType=""
		Set tSC = ..PublishPTTModel(tPortType, pServiceData.WSDLLocation,  .tTModelKey)
		if $$$ISERR(tSC) Quit 
		Set tSC = tPortTypeTModelKeys.SetAt(tTModelKey, tPortType.LocalName)
		if $$$ISERR(tSC) Quit 
		w tCurKey, ! 
	} While (tCurKey'="")
	if $$$ISERR(tSC) Quit tSC

	Set tCurKey = ""
	Do {
		Set tBinding = pServiceData.Bindings.GetNext(.tCurKey)
		Continue:tBinding=""
		Set tPortTypeKey = tPortTypeTModelKeys.GetAt(tBinding.PortType)
		Set tSC = ..PublishBTModel(tBinding, pServiceData.WSDLLocation, tPortTypeKey, .tTModelKey)
		if $$$ISERR(tSC) Quit 
		Set tSC = tBindingTModelKeys.SetAt(tTModelKey, tBinding.LocalName)
		if $$$ISERR(tSC) Quit 
	} While (tCurKey'="")
	if $$$ISERR(tSC) Quit tSC
	
	Set tCurKey = ""
	Set count = 0
	Do {
		Set tSOAPService = pServiceData.Services.GetNext(.tCurKey)
		Continue:tSOAPService=""
		Set tSC = ..PublishBSOnly(pBusinessKey, tSOAPService, .pServiceKey)
		if $$$ISERR(tSC) Quit 

		#dim tListKey As %Integer
		Set tListKey = ""
		Do {
			Set tPort = tSOAPService.Ports.GetNext(.tListKey)
			Continue:tPort=""
			Set tPortTypeKey = tPortTypeTModelKeys.GetAt(tPort.PortTypeLocalName)
			Set tBindingKey = tBindingTModelKeys.GetAt(tPort.BindingLocalName)
			Set tSC = ..PublishBT(pServiceKey, tPort, tPortTypeKey, tBindingKey, .tBTKey)
			if $$$ISERR(tSC) Quit 
		} While (tListKey'="")
		if $$$ISERR(tSC) Quit 
		Set count = count + 1
	} While (tCurKey'="")
	if $$$ISERR(tSC) Quit tSC
	
	W count_" SOAP Services Mapped to UDDI. Last Service Key: "_pServiceKey
	Quit tSC
}

Method FindBusiness(pName As %String, Output tBusinesskey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	#dim tSC As %Status
	
	#dim tFind As EnsLib.UDDI.FindBusiness
	#dim tListHead As %Integer
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	#dim tBusinessInfos,tServices As %ListOfObjects
	#dim tTruncated As %Boolean
	#dim tInfo As EnsLib.UDDI.uddi.businessInfo

	$$$NEW(tFind,"EnsLib.UDDI.FindBusiness")

	Set tSC=tFind.AddName(pName),tListHead=0
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tFind.Send(..Connection,tListHead,.tDescription,.tBusinessInfos,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	Set tBusinesskey = ""
	Quit:tBusinessInfos="" tSC
	Set tInfo = tBusinessInfos.businessInfo.GetNext("")
	Quit:tInfo="" tSC
	
	Set tBusinesskey = tInfo.businessKey
	Quit tSC
}

Method PublishBusiness(pName As %String, pDescription As %String, pHomePage As %String, Output pBusinessKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	#dim tSC As %Status

	#dim tSave As EnsLib.UDDI.SaveBusiness
	#dim tBusinessEntity As EnsLib.UDDI.uddi.businessEntity
	#dim tDiscoveryURLs As EnsLib.UDDI.uddi.DiscoveryUrls
	#dim tContacts As EnsLib.UDDI.uddi.contacts
	#dim tBusinessEntities As %ListOfObjects
	#dim tTruncated As %Boolean
	
	$$$PROLOGUE
	
	#; What to save a Business
	$$$NEW(tSave,"EnsLib.UDDI.SaveBusiness")
		
	#; Create an instance of a business entity
	$$$NEW(tBusinessEntity,"EnsLib.UDDI.uddi.businessEntity")
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tBusinessEntity.businessKey=$c(0)
	
	#; Set the business name
	Set tSC=..addNameToList(tBusinessEntity.name,pName)
	If $$$ISERR(tSC) Quit
	
	#; Add a description
	Set tSC=..addDescriptionToList(tBusinessEntity.description,pDescription)
	If $$$ISERR(tSC) Quit
	
	$$$NEW(tDiscoveryURLs,"EnsLib.UDDI.uddi.discoveryURLs")
	
	#; Add a discovery URL
	Set tSC=..addDiscoveryURLToList(tDiscoveryURLs.discoveryURL,"Home Page",pHomePage)
	If $$$ISERR(tSC) Quit
	
	Set tBusinessEntity.discoveryURLs=tDiscoveryURLs
	
	#; Add this to the business entities to save/update
	Set tSC=tSave.AddBusinessEntity(tBusinessEntity)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(..Connection,.tBusinessEntities,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The SaveBusiness operation was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetBusinessDetail).DisplayBusinessEntities(tBusinessEntities)
	
	#; Retrieve the key and assign the output
	Set pBusinessKey=tBusinessEntities.GetAt(1).businessKey
	
	$$$EPILOGUE
}

Method EnsureCacheTModel() As %Status
{
	#dim tSC As %Status
	#dim tGetDetail As EnsLib.UDDI.GetTModelDetail
	#dim tModels As %ListOfObjects
	#dim tTruncated As %Boolean
	#dim tTModel As EnsLib.UDDI.uddi.tModel
	#dim tCategoryBag As EnsLib.UDDI.uddi.categoryBag
	#dim tOverviewDoc As EnsLib.UDDI.uddi.overviewDoc

	/// Use for Categorization
	#dim tKeyName   As %String
	#dim tKeyValue  As %String
	#dim tTModelKey As %String

	$$$PROLOGUE

	#; Want to retrieve a specific service
	$$$NEW(tGetDetail,"EnsLib.UDDI.GetTModelDetail")
	
	#; Retrieve a specific tmodel
	Set tSC=tGetDetail.AddTModelKey(..#InterSystemsComWebServiceTModelKeyV3)
	If $$$ISERR(tSC) Quit 

	#; Send the request to the Server
	Set tSC=tGetDetail.Send(..Connection,.tModels,.tTruncated)
	If $$$ISERR(tSC) {
		if (tSC["faultstring=The UDDI key uddi:intersystems.com:webservice is invalid") {
			/// Create new
		} else {
			Quit
		}
	} else {
		Set tTModel = tModels.GetNext("")
		Quit:tTModel.tModelKey=..#InterSystemsComWebServiceTModelKeyV3
	}
		
	#; Create an instance of tModel
	$$$NEW(tTModel,"EnsLib.UDDI.uddi.tModel")
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tTModel.tModelKey=..#InterSystemsComWebServiceTModelKeyV3
	
	#; Set the name
	Set tTModel.name.content="InterSystems Cache Web Service"
	 
	$$$NEW(tCategoryBag,"EnsLib.UDDI.uddi.categoryBag")

	Set tKeyName   = "uddi:uddi.org:specification"
	Set tKeyValue  = "categorization"
	Set tTModelKey = ..#UddiOrgTypesTmodelKeyV3
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,tTModelKey,tKeyName,tKeyValue)
	If $$$ISERR(tSC) Quit

	Set tTModel.categoryBag = tCategoryBag

	#; Create an overview document
	$$$NEW(tOverviewDoc,"EnsLib.UDDI.uddi.overviewDoc")
	
	#; Add a description of what the document is
	Set tSC=..addDescriptionToList(tOverviewDoc.description,"InterSystems Cache Web Service")
	If $$$ISERR(tSC) Quit 
	
	#; Set the URL
	Set tOverviewDoc.overviewURL.content="http://docs.intersystems.com/cache20101/csp/docbook/DocBook.UI.Page.cls?KEY=GSOP"
	Set tOverviewDoc.overviewURL.useType="text"

	#; Add the document to the tModel
	Set tSC=tTModel.overviewDoc.Insert(tOverviewDoc)

	Set tTModelKey = ""
	Set tSC = ..PublishTModel(tTModel, .tTModelKey)
	w "Published: "_tTModelKey, !

	$$$EPILOGUE
}

ClassMethod Test(serverIP As %String)
{
	#dim tPublisher As PublishService
	#dim tSC As %Status
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey

	
	$$$NEW(tPublisher,"EnsLib.UDDI.PublishService")
	
	Set tSC = tPublisher.Connect(serverIP)
	Quit:$$$ISERR(tSC)
	
	w "Connected to OpenUDDI Server at "_serverIP, !
	
	#; Publishing Port Type
	
	#dim tName       As %String
	#dim tNameSpace  As %String
	#dim tWsdlUrl    As %String
	
	Set tName      = "SOAPServiceSoap"
	Set tNameSpace = "http://tempuri.org"
	Set tWsdlUrl   = "http://localhost:57776/csp/user/SOAPTutorial.SOAPService.cls?wsdl=1"

	Set tSC = tPublisher.PublishPortTypeTModel(tName,tNameSpace,tWsdlUrl,.tTModelKey)
	If $$$ISERR(tSC) {
		d $system.OBJ.DisplayError(tSC)
		Quit
	}

	w "Port Type TModel Published with Key = "_tTModelKey, !
}

ClassMethod DeleteISCTModel(serverIP As %String)
{
	#dim tPublisher As PublishService
	#dim tSC As %Status
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey
	#dim tDelete As EnsLib.UDDI.DeleteTModel

	$$$NEW(tPublisher,"EnsLib.UDDI.PublishService")
	
	Set tSC = tPublisher.Connect(serverIP)
	Quit:$$$ISERR(tSC)
	
	w "Connected to OpenUDDI Server at "_serverIP, !
	
	$$$PROLOGUE
		
	Write !!!,"Test Delete TModel",!!
		
	#; Want to delete TModels
	$$$NEW(tDelete,"EnsLib.UDDI.DeleteTModel")
	
	Set tSC=tDelete.AddTModelKey(..#InterSystemsComWebServiceTModelKeyV3)
	
	#; Now delete
	Set tSC=tDelete.Send(tPublisher.Connection)
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

}
