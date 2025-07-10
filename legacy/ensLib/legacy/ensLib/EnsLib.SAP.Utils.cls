/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble, EnsSAPJCO)

Class EnsLib.SAP.Utils Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Domain for $$$Text()
Parameter DOMAIN = "EnsSAP";

/// SAP Client e.g 000
Property SAPClient As %String(TRUNCATE = 1);

/// Name of InterSystems IRIS Credentials to use for the connection
Property SAPUser As %String(TRUNCATE = 1);

/// Derived from Credentials
Property SAPPassword As %String(TRUNCATE = 1);

/// Derived from Credentials
Property SAPLanguage As %String(TRUNCATE = 1);

/// IP Address of the SAP Host
Property SAPHost As %String(TRUNCATE = 1);

/// SAP System Number 00
Property SAPSystemNumber As %String(TRUNCATE = 1);

/// Dervied from JavaGateway
Property JavaGatewayAddress As %String(TRUNCATE = 1);

/// Dervied from JavaGateway
Property JavaGatewayPort As %String(TRUNCATE = 1);

/// Should perform Auto Commit
Property SAPTransactionAutoCommit As %Boolean [ InitialExpression = 0 ];

/// MM 20130917
/// SAP Type for connect: "A" means direct application server connect, "B" means load balanced connect
Property SAPType As %String(VALUELIST = ",A,B") [ InitialExpression = "A", Required ];

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Message Server Host (jco.client.mshost).
Property SAPMSHost As %String(MAXLEN = "");

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Gateway Host (jco.client.gwhost).
Property SAPGWHost As %String(MAXLEN = "");

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Gateway Service (jco.client.gwserv).
Property SAPGWServ As %String(MAXLEN = "");

/// MM 20130917
/// Used for loadbalanced Type "B" connect. SAP Group (jco.client.group).
Property SAPGroup As %String(MAXLEN = "");

/// MM 20130917
/// Used for loadbalanced Type "B" connect. SAP Group (jco.client.r3name).
Property SAPR3Name As %String(MAXLEN = "");

/// Connect to SAP, returns an instance of the JavaGateway, SAP Destination and SAP Respository
Method Connect(Output pGateway As EnsLib.JavaGateway.JavaGateway, Output pJCoDestination As %ObjectHandle, Output pJCoRespository As %ObjectHandle) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tFileStream As %FileCharacterStream
	#dim tFileName As %String
	#dim tFileCreated As %Boolean = 0
	
	#; Java objects
	#dim tDestinationManager As com.sap.conn.jco.JCoDestinationManager
	
	try {
		
		#; Create an instance of the JavaGateway
		Kill %objlasterror
		Set pGateway=##class(EnsLib.JavaGateway.JavaGateway).%New()
		If '$IsObject(pGateway) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.JavaGateway.JavaGateway")) Quit
		
		#; Connect the gateway
		Set tSC=pGateway.%Connect(..JavaGatewayAddress,..JavaGatewayPort,,,,,,0) 
		If $$$ISERR(tSC) Quit
		
		#; Create a new file
		Kill %objlasterror
		Set tFileStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tFileStream) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%FileCharacterStream")) Quit
		
		Set tFileName=$Job_".jcoDestination"
		
		#; Assign the name (must have this format)
		Set tFileStream.Filename=tFileName
		
		#; TODO: What is the significance of this parameter?
		Set tSC=tFileStream.WriteLine("jco.destination.pool_capacity=5")
	    If $$$ISERR(tSC) Quit
	    
	    #; TODO: What is the significance of this parameter?
	    Set tSC=tFileStream.WriteLine("jco.destination.peak_limit=10")
	    If $$$ISERR(tSC) Quit
	    
	    #; Fill in Language
		Set tSC=tFileStream.WriteLine("jco.client.lang="_..SAPLanguage)
		If $$$ISERR(tSC) Quit
		
		#; Fill in Client
	    Set tSC=tFileStream.WriteLine("jco.client.client="_..SAPClient)
	    If $$$ISERR(tSC) Quit
	    
	    #; Fill in User
	    Set tSC=tFileStream.WriteLine("jco.client.user="_..SAPUser)
	    If $$$ISERR(tSC) Quit
	    
	    #; Fill in Password
	    Set tSC=tFileStream.WriteLine("jco.client.passwd="_..SAPPassword)
	    If $$$ISERR(tSC) Quit
	    
	    #; Fill in System Number
	    Set tSC=tFileStream.WriteLine("jco.client.sysnr="_..SAPSystemNumber)
	    If $$$ISERR(tSC) Quit
	    
	    #; Fill in Host
	    Set tSC=tFileStream.WriteLine("jco.client.ashost="_..SAPHost)
		If $$$ISERR(tSC) Quit
		
		/// MM20130917 Handle Type B connect
		Set tSC=tFileStream.WriteLine("jco.client.type="_..SAPType)
		If $$$ISERR(tSC) Quit
		#; Fill in Host
		if ..SAPType="B" {
			Set tSC=tFileStream.WriteLine("jco.client.mshost="_..SAPMSHost)
			If $$$ISERR(tSC) Quit
			Set tSC=tFileStream.WriteLine("jco.client.gwhost="_..SAPGWHost)
			If $$$ISERR(tSC) Quit
			Set tSC=tFileStream.WriteLine("jco.client.gwserv="_..SAPGWServ)
			If $$$ISERR(tSC) Quit
			Set tSC=tFileStream.WriteLine("jco.client.group="_..SAPGroup)
			If $$$ISERR(tSC) Quit
			Set tSC=tFileStream.WriteLine("jco.client.r3name="_..SAPR3Name)
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
		
		#; Save the file
		Set tSC=tFileStream.%Save()
		If $$$ISERR(tSC) Quit
		
		#; Flag for cleanup
		Set tFileCreated=1
		
		#; Create a new instance of the DestinationManager
		Kill %objlasterror
		
		#; Get the destination (passing the index of the file name that was created)
		Set pJCoDestination=##class(com.sap.conn.jco.JCoDestinationManager).getDestination(pGateway,$Job)
		
		If '$IsObject(pJCoDestination) {
			
			#; TODO: Localize
			Set tSC=$$$ERROR($$$GeneralError,$$$Text("Unable to obtain specified destination (connection)"))
			Quit
		}
	
		#; Get the repository
		Set pJCoRespository=pJCoDestination.getRepository()
		If '$IsObject(pJCoRespository) {
			
			#; TODO: Localize
			Set tSC=$$$ERROR($$$GeneralError,$$$Text("Unable to obtain repository from specified destination (connection)"))
			Quit
		}
	
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	If tFileCreated=1 Do ##class(%File).Delete(tFileName)
	
	Quit tSC
}

/// Create a Property
Method CreateProperty(Output pProperty As %Dictionary.PropertyDefinition, pName As %String, pType As %String, pLength As %Integer = 0, pDescription As %String, pSequenceNumber As %Integer) [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	try {
		#; Create a new instance of the %Dictionary.PropertyDefinition
		Kill %objlasterror
		Set pProperty = ##class(%Dictionary.PropertyDefinition).%New()
		If '$IsObject(pProperty) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Dictionary.PropertyDefinition")) Quit
		
		#; Name
		Set pProperty.Name=$$$SapName2EnsName(pName)
		
		/// MM 20130919 Use pProperty.Name
		Set tSC=pProperty.Parameters.SetAt(pProperty.Name,"XMLNAME")
		If $$$ISERR(tSC) Quit
		
		#; Type
		Set pProperty.Type=pType
		If pType="%String" {
			Set tSC=pProperty.Parameters.SetAt("1","TRUNCATE")
			If $$$ISERR(tSC) Quit
		}
		
		#; Length
		If pLength {
			Set tSC=pProperty.Parameters.SetAt(pLength,"MAXLEN")
			If $$$ISERR(tSC) Quit
		}
		
		#; Description
		Set pProperty.Description=pName_$Char(13,10)_pDescription
		
		#; Sequence Number
		If pSequenceNumber Set pProperty.SequenceNumber=pSequenceNumber
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Create a Parameter
Method CreateParameter(Output pParameter As %Dictionary.ParameterDefinition, pName As %String, pType As %String, pDefault As %String = "", pDescription = "") As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	try {
		
		#; Create a new instance of the %Dictionary.ParameterDefinition
		Kill %objlasterror
		Set pParameter = ##class(%Dictionary.ParameterDefinition).%New()
		If '$IsObject(pParameter) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Dictionary.ParameterDefinition")) Quit
		
		#; Fill in the details
		Set pParameter.Name=pName
		Set pParameter.Type=pType
		Set pParameter.Default=pDefault
		Set pParameter.Description=pDescription
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Create a Class Definition
Method CreateClassDefinition(Output pClassDefinition As %Dictionary.ClassDefinition, pPackageName As %String, pClassName As %String, pSuperClass As %String) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tFullClassName As %String
	#dim tParameterDefinition As %Dictionary.ParameterDefinition
	
	try {
		
		#; Form the full class name	
		Set tFullClassName=pPackageName_"."_$$$SapName2EnsName(pClassName)
		If '$ZName(tFullClassName,4) {
			
			#; TODO: Localize
			Set tSC=$$$ERROR($$$GeneralError,$$$Text("Class name is invalid: ")_tFullClassName)
			Quit
		}
		
		#; If the class already exists, delete it
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tFullClassName) {
			Set tSC=##class(%Dictionary.ClassDefinition).%DeleteId(tFullClassName)
			If $$$ISERR(tSC) Quit
		}
		
		#; Create a new instance of the %Dictionary.ClassDefinition
		Kill %objlasterror
		Set pClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
		If '$IsObject(pClassDefinition) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Dictionary.ClassDefinition")) Quit
	
		#; Fill in the details
		Set pClassDefinition.Name=tFullClassName
		Set pClassDefinition.Super=pSuperClass
		Set pClassDefinition.ProcedureBlock = 1
	
		#; SqlTableName
		Set pClassDefinition.SqlTableName=pClassName
	
		#; Create the XMLNAME parameter
		Set tSC=..CreateParameter(.tParameterDefinition,"XMLNAME","%String",pClassName)
		If $$$ISERR(tSC) Quit
	
		#; Add it to the definition
		Set tSC=pClassDefinition.Parameters.Insert(tParameterDefinition)
		If $$$ISERR(tSC) Quit
		
		#; Save the parameter
		Set tSC=tParameterDefinition.%Save()
		If $$$ISERR(tSC) Quit
	
		#; Finally save the definition
		Set tSC=pClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This method creates the classes which represent the structure of the specified SAP call. 
/// Classes ISCuRequest and ISCuResponse and supporting structural classes are generated within
/// the named package. To avoid conflict with external names, the names of InterSystems specific structures
/// are prefixed with the 'ISCu' prefix. In addition the SAP names containing underscores will be
/// converted to equivalent ObjectScript compatible names with an alternate character replacing the underscore
Method CreateClasses(pSAPName As %String, pPackage As %String) As %Status
{
	#dim tSC,tSC2 As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tJavaGatewayConnected As %Boolean = 0
	#dim tRequestClassDefinition,tResponseClassDefinition As %Dictionary.ClassDefinition
	#dim tRequestSequenceNumber,tResponseSequenceNumber As %Integer = 0
	
	#; Java objects
	#dim tJCoDestination As com.sap.conn.jco.JCoDestination
	#dim tJCoRepository As com.sap.conn.jco.JCoRepository
	#dim tJCoFunction As com.sap.conn.jco.JCoFunction
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	try {
		
		#; Connect to the target SAP system
		Set tSC=..Connect(.tJavaGateway,.tJCoDestination,.tJCoRepository)
		If $$$ISERR(tSC) Quit
		
		#; Connected
		Set tJavaGatewayConnected=1
		
		#; Get a handle to the named function
	    Set tJCoFunction=tJCoRepository.getFunction(pSAPName)
	    If '$IsObject(tJCoFunction) {
		 
		 	#; It's an error to request class generation for a function that does not exist
		 	#; TODO: Localize
		 	Set tSC=$$$ERROR($$$GeneralError,$$$Text("SAP function (")_pSAPName_$$$Text(") NOT available"))
		 	Quit   
	    }
	    
	    #; Create the request class definition and return an object handle, this will represent the import parameters
	    #; for the sap function
	    Set tSC=..CreateRequestClass(.tRequestClassDefinition,.tRequestSequenceNumber,pSAPName,pPackage,tJCoFunction.getImportParameterList())
	    If $$$ISERR(tSC) Quit
	     
	    #; Create the response class definition and return an object handler, this will reprsent the output parameters
	    #; for the sap function
	    Set tSC=..CreateResponseClass(.tResponseClassDefinition,.tResponseSequenceNumber,pPackage,tJCoFunction.getExportParameterList())
	    If $$$ISERR(tSC) Quit
	    
	    #; Create any table classes required, the tables have relationships to the base request and response classes
	    Set tSC=..CreateTableClasses(pPackage,tJCoFunction,tRequestClassDefinition,tRequestSequenceNumber,tResponseClassDefinition,tResponseSequenceNumber)
	    If $$$ISERR(tSC) Quit
	
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	#; If the JavaGateway is connected, then release it's resources
	If tJavaGatewayConnected {
		
		Set tSC2=tJavaGateway.%Disconnect()
		If $$$ISERR(tSC2) {
			If $$$ISERR(tSC) {
				Set tSC=$$$ADDSC(tSC,tSC2)
			} else {
				Set tSC=tSC2
			}
		}
	}
	Quit tSC
}

/// Create the class which represents the SAP request, parameter list represents the SAP functions ImportParameterList
Method CreateRequestClass(Output pClassDefinition As %Dictionary.ClassDefinition, ByRef pSeqNum As %Integer, pSAPName As %String, pPackage As %String, pJCoParameterList As %ObjectHandle) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tDescriptionText,tSapFieldName,tEnsTypeName,tSapTypeName As %String
	#dim tI,tJ
	
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tParameterDefinition As %Dictionary.ParameterDefinition
	#dim tPropertyDefinition As %Dictionary.PropertyDefinition
	
	#; Java objects
	#dim tJCoStructure As com.sap.conn.jco.JCoStructure
	#dim tJCoMetaData,tJCoStructureMetaData As com.sap.conn.jco.JCoMetaData

	try {
		#; Create Ens.Request subclass, 'PackageName'.ISCuRequest
		Set tSC=..CreateClassDefinition(.pClassDefinition,pPackage,"ISCuRequest","Ens.Request")
		If $$$ISERR(tSC) Quit
		
		#; Create the BAPI parameter, this is the name of the BAPI/RFC which to which the request relates
		
		#; TODO: Localize
		Set tDescriptionText=$$$Text("This Request message corresponds to SAP BAPI/RFC: ")_pSAPName
		Set tSC=..CreateParameter(.tParameterDefinition,"BAPI","%String",pSAPName,tDescriptionText)
		If $$$ISERR(tSC) Quit
	
		Set tSC=pClassDefinition.Parameters.Insert(tParameterDefinition)
		If $$$ISERR(tSC) Quit
		
		#; Save the parameter
		Set tSC=tParameterDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
		#; Bump
		Set pSeqNum=pSeqNum+1
		
		#; Create the RESPONSECLASSNAME parameter, this is the name of the BAPI/RFC which to which the response relates
		
		#; TODO: Localize
		Set tDescriptionText=$$$Text("This Response message corresponds this Request ")
		Set tSC=..CreateParameter(.tParameterDefinition,"RESPONSECLASSNAME","%String",pPackage_".ISCuResponse",tDescriptionText)
		If $$$ISERR(tSC) Quit
	
		Set tSC=pClassDefinition.Parameters.Insert(tParameterDefinition)
		If $$$ISERR(tSC) Quit
		
		#; Save the parameter
		Set tSC=tParameterDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
		#; Bump
		Set pSeqNum=pSeqNum+1
		
		#; Create properties for atomic types and structures
		If $IsObject(pJCoParameterList) {
			Set tSC=..CreateFieldProperties(pClassDefinition,.pSeqNum,pPackage,pJCoParameterList)
			If $$$ISERR(tSC) Quit
		}
		
		#; Save our work
		Set tSC=pClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Create the class which represents the SAP response
Method CreateResponseClass(Output pClassDefinition As %Dictionary.ClassDefinition, ByRef pSeqNum As %Integer, pPackage As %String, pJCoParameterList As %ObjectHandle) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tDescriptionText,tSapFieldName,tEnsTypeName,tSapTypeName As %String
	#dim tI,tJ
	
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tPropertyDefinition As %Dictionary.PropertyDefinition
	
	#; Java objects
	#dim tJCoStructure As com.sap.conn.jco.JCoStructure
	#dim tJCoMetaData,tJCoStructureMetaData As com.sap.conn.jco.JCoMetaData

	try {
		#; Create the base definition
		Set tSC=..CreateClassDefinition(.pClassDefinition,pPackage,"ISCuResponse","Ens.Response")
		If $$$ISERR(tSC) Quit
		
   		#; TODO: Localize
		Set tDescriptionText=$$$Text("This property holds the success status of the BAPI/RFC call")
		Set tSC=..CreateProperty(.tPropertyDefinition,"ISCuIsOK","%Boolean",,tDescriptionText,$Increment(pSeqNum))
   		If $$$ISERR(tSC) Quit
   	
   		Set tSC=pClassDefinition.Properties.Insert(tPropertyDefinition)
   		If $$$ISERR(tSC) Quit
   		
   		#; Save the property
   		Set tSC=tPropertyDefinition.%Save()
   		If $$$ISERR(tSC) Quit
  
		#; TODO: Localize
   		Set tDescriptionText=$$$Text("This property holds any error message produced by the BAPI/RFC call")
   		Set tSC=..CreateProperty(.tPropertyDefinition,"ISCuErrorMessage","%String",1024,tDescriptionText,$Increment(pSeqNum))
   		If $$$ISERR(tSC) Quit
   	
   		Set tSC=pClassDefinition.Properties.Insert(tPropertyDefinition)
   		If $$$ISERR(tSC) Quit
   		
   		#; Save the property
   		Set tSC=tPropertyDefinition.%Save()
   		If $$$ISERR(tSC) Quit
		
   		#; Create properties for atomic types and structures
		If $IsObject(pJCoParameterList) {
			Set tSC=..CreateFieldProperties(pClassDefinition,.pSeqNum,pPackage,pJCoParameterList)
			If $$$ISERR(tSC) Quit
		}
		
		#; Save our work
		Set tSC=pClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Create those classes corresponding to SAP table definitions
Method CreateTableClasses(pPackage As %String, pJCoFunction As %ObjectHandle, pRequestClassDefinition As %Dictionary.ClassDefinition, pRequestSequenceNumber As %Integer, pResponseClassDefinition As %Dictionary.ClassDefinition, pResponseSequenceNumber As %Integer) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tI,tJ,tSeqNum As %Integer
	#dim tClassDefinitionCopyName,tTableName,tSapFieldName,tSapTypeName,tEnsTypeName,tDescriptionText As %String
	#dim tClassDefinition,tClassDefinitionCopy As %Dictionary.ClassDefinition
	#dim tPropertyDefinition As %Dictionary.ProjectionDefinition
	
	#; Java classes
	#dim tJCoTableParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoTableMetaData,tJCoRecordMetaData As com.sap.conn.jco.JCoMetaData
	#dim tJCoTable As com.sap.conn.jco.JCoTable
	
	try {
	
		#; Attempt to get table parameter list
		Set tJCoTableParameterList = pJCoFunction.getTableParameterList()
		
		#; It's not an error to have no tables
		If '$IsObject(tJCoTableParameterList) Quit
		
		#; Get the meta data
		Set tJCoTableMetaData=tJCoTableParameterList.getListMetaData()
			
		#; For each table parameter
		For tI=0:1:tJCoTableParameterList.getFieldCount()-1 {
			
			#; Get the table name
			Set tTableName=tJCoTableMetaData.getName(tI)
			
			#; Create a class definition to represent the table
			Set tSC=..CreateClassDefinition(.tClassDefinition,pPackage,tTableName,"%Persistent,%XML.Adaptor")
			If $$$ISERR(tSC) Quit
			
			#; Initialize the property sequence number for this class
			Set tSeqNum = 0
			
			#; Get a hande to the table itself
			Set tJCoTable=tJCoTableParameterList.getTable(tI)
			
			#; Get the MetaData object
			Set tJCoRecordMetaData=tJCoTable.getRecordMetaData()
		
			#; For each 'field'
			For tJ=0:1:tJCoTable.getFieldCount()-1 {
			
				#; Get the SAP field name
				/// MM 2013092013 pass tJ into getName() (wrong was tI!)
				Set tSapFieldName=tJCoRecordMetaData.getName(tJ)
				#; Get the type of the field as a String
				/// MM 2013092013 pass tJ into getName() (wrong was tI!)
				Set tSapTypeName=tJCoRecordMetaData.getTypeAsString(tJ)
			
				If tSapTypeName'="STRUCTURE" {
		  			Set tEnsTypeName="%String"
				} else {
					Set tEnsTypeName=$$$SapName2EnsName(tSapFieldName)
				}
					
		  		#; Create the property to represent the type
				Set tSC=..CreateProperty(.tPropertyDefinition,tJCoRecordMetaData.getName(tJ),tEnsTypeName,tJCoRecordMetaData.getLength(tJ),"["_tSapTypeName_"] "_tJCoRecordMetaData.getDescription(tJ),$Increment(tSeqNum))
				If $$$ISERR(tSC) Quit
	
				#; Insert it into the class
				Set tSC=tClassDefinition.Properties.Insert(tPropertyDefinition)
				If $$$ISERR(tSC) Quit
				
				#; Save the property
				Set tSC=tPropertyDefinition.%Save()
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
			
			Set tSC=tClassDefinition.%Save()
			If $$$ISERR(tSC) Quit
			
			#; Construct a clone of the new class definition
			Kill %oblasterror
			Set tClassDefinitionCopy=tClassDefinition.%ConstructClone(1)
			If '$IsObject(tClassDefinitionCopy) Set tSC=$Get(%objlasterror,$$$ERROR($$$GeneralError,$$$Text("Failed to clone instance"))) Quit
			
			#; Form a name for the clone
			Set tClassDefinitionCopyName=pPackage_"."_$$$SapName2EnsName(tTableName)_"req"
			
			#; Fix up the copy name
			Set tClassDefinitionCopy.Name=tClassDefinitionCopyName
			
			#; Delete any pre-existing class definition of that name
			If ##class(%Dictionary.ClassDefinition).%ExistsId(tClassDefinitionCopyName) {
				Set tSC=##class(%Dictionary.ClassDefinition).%DeleteId(tClassDefinitionCopyName)
				If $$$ISERR(tSC) Quit
			}
	
			#; Fix up the SqlTableName by appending 'req'		
			Set tClassDefinitionCopy.SqlTableName=tClassDefinitionCopy.SqlTableName_"req"
		
			#; Response 
			
			#; Create the ISCuResponse property of type ISCuResponse
			Set tDescriptionText=$$$Text("[Relationship many side] object reference to the response message")
		   	Set tSC=..CreateProperty(.tPropertyDefinition,"ISCuResponse","ISCuResponse",,tDescriptionText,$Increment(tSeqNum))
		   	If $$$ISERR(tSC) Quit
		   	
		   	Set tPropertyDefinition.Relationship=1
		   	Set tPropertyDefinition.Inverse=$$$SapName2EnsName(tTableName)
		   	Set tPropertyDefinition.Cardinality="parent"
		   	
		   	#; Insert this property into the original class definition
		   	Set tSC=tClassDefinition.Properties.Insert(tPropertyDefinition)
		   	If $$$ISERR(tSC) Quit
		   	
		   	#; Save the property
			Set tSC=tPropertyDefinition.%Save()
			If $$$ISERR(tSC) Quit
		   	
		   	#; Create relationship master side (TODO: Localize)
		   	Set tDescriptionText=$$$Text("[Relationship master side] object reference to ")_tTableName_$$$Text(" details")
		   	Set tSC=..CreateProperty(.tPropertyDefinition,tTableName,$$$SapName2EnsName(tTableName),,tDescriptionText,$Increment(tSeqNum))
		   	If $$$ISERR(tSC) Quit
		   	
		   	Set tPropertyDefinition.Relationship=1
		   	Set tPropertyDefinition.Inverse="ISCuResponse"
		   	Set tPropertyDefinition.Cardinality="children"
		   	
		   	#; Insert the property into the passed response class
		   	Set tSC=pResponseClassDefinition.Properties.Insert(tPropertyDefinition)
		   	If $$$ISERR(tSC) Quit
		   	
		   	#; Save the property
			Set tSC=tPropertyDefinition.%Save()
			If $$$ISERR(tSC) Quit
		   	
			#; Request
			
			#; Create the ISCuRequest property of type ISCuRequest
			Set tDescriptionText="[Relationship detail side] object reference to the request message"
		   	Set tSC=..CreateProperty(.tPropertyDefinition,"ISCuRequest","ISCuRequest",,tDescriptionText,$Increment(tSeqNum))
		   	If $$$ISERR(tSC) Quit
		   	
		   	Set tPropertyDefinition.Relationship=1
		   	Set tPropertyDefinition.Inverse=$$$SapName2EnsName(tTableName)
		   	Set tPropertyDefinition.Cardinality="parent"
		   	
		   	#; Insert it into the copy
		   	Set tSC=tClassDefinitionCopy.Properties.Insert(tPropertyDefinition)
		   	If $$$ISERR(tSC) Quit
		   	
		   	#; Save the property
			Set tSC=tPropertyDefinition.%Save()
			If $$$ISERR(tSC) Quit
		   	 	
		   	#; TODO: Localize
		   	Set tDescriptionText=$$$Text("[Relationship master side] object reference to ")_tTableName_$$$Text(" details")
		   	Set tSC=..CreateProperty(.tPropertyDefinition,tTableName,$$$SapName2EnsName(tTableName)_"req",,tDescriptionText,$Increment(pRequestSequenceNumber))
		   	If $$$ISERR(tSC) Quit
		   	
		   	Set tPropertyDefinition.Relationship=1
		   	Set tPropertyDefinition.Inverse="ISCuRequest"
		   	Set tPropertyDefinition.Cardinality="children"
		   	
		   	#; Insert it into the request class definition
		   	Set tSC=pRequestClassDefinition.Properties.Insert(tPropertyDefinition)
		   	If $$$ISERR(tSC) Quit
		   	
		   	#; Save the property
			Set tSC=tPropertyDefinition.%Save()
			If $$$ISERR(tSC) Quit
		   	
		   	#; Save the class
			Set tSC=tClassDefinition.%Save()
			If $$$ISERR(tSC) Quit
			
			#; Save the copy
			Set tSC=tClassDefinitionCopy.%Save()
			If $$$ISERR(tSC) Quit
			
		   	#; Save the request definition to persist updates
		   	Set tSC=pRequestClassDefinition.%Save()
			If $$$ISERR(tSC) Quit

			 #; Save the response class to persist updates
		   	Set tSC=pResponseClassDefinition.%Save()
		   	If $$$ISERR(tSC) Quit
		}
		
		If $$$ISERR(tSC) Quit
		
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Create the properties which correspond to SAP 'fields', the parameter list may be the import or export parameters of the BAPI/RFC
Method CreateFieldProperties(pClassDefinition As %Dictionary.ClassDefinition, ByRef pSeqNum As %Integer, pPackage As %String, pJCoParameterList As %ObjectHandle) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tSapFieldName,tEnsTypeName,tSapTypeName As %String
	#dim tI,tJ
	
	#dim tClassDefinition As %Dictionary.ClassDefinition
	#dim tParameterDefinition As %Dictionary.ParameterDefinition
	#dim tPropertyDefinition As %Dictionary.PropertyDefinition
	
	#; Java objects
	#dim tJCoStructure As com.sap.conn.jco.JCoStructure
	#dim tJCoMetaData,tJCoStructureMetaData As com.sap.conn.jco.JCoMetaData

	try {
	
		#; Get the MetaData object
		Set tJCoMetaData=pJCoParameterList.getMetaData()
		
		#; For each 'field'
		For tI=0:1:pJCoParameterList.getFieldCount()-1 {
			
			#; Get the SAP field name
			Set tSapFieldName=tJCoMetaData.getName(tI)
			
			#; Get the type of the field as a String
			Set tSapTypeName=tJCoMetaData.getTypeAsString(tI)
			
			If tSapTypeName'="STRUCTURE" {
	  			Set tEnsTypeName="%String"
			} else {
				Set tEnsTypeName=$$$SapName2EnsName(tSapFieldName)
			}
			
	  		#; Create the property to represent the type
			Set tSC=..CreateProperty(.tPropertyDefinition,tJCoMetaData.getName(tI),tEnsTypeName,tJCoMetaData.getLength(tI),"["_tSapTypeName_"] "_tJCoMetaData.getDescription(tI),$Increment(pSeqNum))
			If $$$ISERR(tSC) Quit
	
			Set tSC=pClassDefinition.Properties.Insert(tPropertyDefinition)
			If $$$ISERR(tSC) Quit
			
			#; Save the property
			Set tSC=tPropertyDefinition.%Save()
			If $$$ISERR(tSC) Quit
			
			If tSapTypeName="STRUCTURE" {
				
				#; Create a class definition for the structure
				Set tSC=..CreateClassDefinition(.tClassDefinition,pPackage,tSapFieldName,"%SerialObject,%XML.Adaptor")
				If $$$ISERR(tSC) Quit
		
				#; Get the structure itself
				Set tJCoStructure=pJCoParameterList.getStructure(tSapFieldName)
				
				#; And its metadata
				Set tJCoStructureMetaData=tJCoStructure.getRecordMetaData()
				
				#; For each field in the structure
			   	For tJ=0:1:tJCoStructureMetaData.getFieldCount()-1 {
				   	
				   	Set tSC=..CreateProperty(.tPropertyDefinition,tJCoStructureMetaData.getName(tJ),"%String",tJCoStructureMetaData.getLength(tJ),"["_tJCoStructureMetaData.getTypeAsString(tJ)_"] "_tJCoStructureMetaData.getDescription(tJ),tJ+1)
				   	If $$$ISERR(tSC) Quit
				   	
				   	Set tSC=tClassDefinition.Properties.Insert(tPropertyDefinition)
				   	If $$$ISERR(tSC) Quit
				   	
				   	#; Save the property
					Set tSC=tPropertyDefinition.%Save()
					If $$$ISERR(tSC) Quit
				}
				
				If $$$ISERR(tSC) Quit
				
				Set tSC=tClassDefinition.%Save()
				If $$$ISERR(tSC) Quit
			}
		}
		
		#; Save our work
		Set tSC=pClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Return the version number of the SAPJCO library [ Private ]
Method GetJCoVersion(pGateway As EnsLib.JavaGateway.JavaGateway, Output pVersion As %String) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#; Java objects
	#dim tJCo As com.sap.conn.jco.JCo
	
	try {
		
		#; Create an instance of the JCo object
		Kill %objlasterror
		Set tJCo=##class(com.sap.conn.jco.JCo).%New(pGateway)
		If '$IsObject(tJCo) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"com.sap.conn.jco.JCo")) Quit
		
		#; Return the version
		Set pVersion=tJCo.getVersion(pGateway)
			
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Connect to SAP and perform a dynamic invocation of the STFC_CONNECTION function
/// to test connectivity.
/// 
/// Note: This method relies on pre-knowlege of the structure of the STFC_CONNECTION function
/// which should not vary between SAP JCO versions. 
Method PingSAP(Output pOK As %Boolean) As %Status
{
	#dim tSC,tSC2 As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tJavaGatewayConnected As %Boolean = 0
	
	#; Java objects
	#dim tJCoDestination As com.sap.conn.jco.JCoDestination
	#dim tJCoRepository As com.sap.conn.jco.JCoRepository
	#dim tJCoFunction As com.sap.conn.jco.JCoFunction
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	
	try {
		#; Pessimitically assume we can't ping
		Set pOK=0
		
		#; Connect to the target SAP system
		Set tSC=..Connect(.tJavaGateway,.tJCoDestination,.tJCoRepository)
		If $$$ISERR(tSC) Quit
		
		#; Connected
		Set tJavaGatewayConnected=1
		
		#; Get a handle to the STFC_CONNECTION function
	    Set tJCoFunction=tJCoRepository.getFunction("STFC_CONNECTION")
	    If '$IsObject(tJCoFunction) {
		 
		 	#; TODO: Localize
		 	Set tSC=$$$ERROR($$$GeneralError,$$$Text("STFC_CONNECTION function not available"))
		 	Quit   
	    }
	    
	    #; Get the input parameter list
	    Set tJCoParameterList=tJCoFunction.getImportParameterList()
	    $$$ASSERT($IsObject(tJCoParameterList))

	    #; Set the first (and only) import parameter
	    Do tJCoParameterList.setValue("REQUTEXT","PING")
	    
	    #; Call the function
	    Do tJCoFunction.execute(tJCoDestination)

		#; Get the output parameter list
	    Set tJCoParameterList=tJCoFunction.getExportParameterList()
	    $$$ASSERT($IsObject(tJCoParameterList))
	
	    #; Test the return value
	    Set pOK=("PING"=tJCoParameterList.getString("ECHOTEXT"))
	    	
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	If tJavaGatewayConnected {
		
		Set tSC2=tJavaGateway.%Disconnect()
		If $$$ISERR(tSC2) {
			If $$$ISERR(tSC) {
				Set tSC=$$$ADDSC(tSC,tSC2)
			} else {
				Set tSC=tSC2
			}
		}
	}
	
	Quit tSC
}

/// Retrieve a list of Know BPIs from the SAP repository
/// 
/// Note: This method relies on pre-knowlege of the structure of the SWO_QUERY_API_METHODS function
/// which should not vary between SAP JCO versions.
Method GetBAPIList(Output pList As %ListOfDataTypes, pFilterString As %String = "") As %Status
{
	#dim tSC,tSC2 As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tJavaGatewayConnected As %Boolean = 0
	#dim tI,tJ As %Integer
	#dim tName,tNameArray,tSubString As %Name
	#dim tInclude As %Boolean
	
	#; Java objects
	#dim tJCoDestination As com.sap.conn.jco.JCoDestination
	#dim tJCoRepository As com.sap.conn.jco.JCoRepository
	#dim tJCoFunction As com.sap.conn.jco.JCoFunction
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoTable As com.sap.conn.jco.JCoTable
	
	try {
		
		#; Connect to the target SAP system
		Set tSC=..Connect(.tJavaGateway,.tJCoDestination,.tJCoRepository)
		If $$$ISERR(tSC) Quit
		
		#; Connected
		Set tJavaGatewayConnected=1
		
		#; Create the list of data types to be returned
		Kill %objlasterror
		Set pList=##class(%Library.ListOfDataTypes).%New()
		If '$IsObject(pList) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Library.ListOfDataTypes")) Quit
		
		#; Attempt to get the function, its not an error for it not to be available
		Set tJCoFunction=tJCoRepository.getFunction("SWO_QUERY_API_METHODS")
		
		#; Not available
	    If '$IsObject(tJCoFunction) Quit
	    
	    #; Execute the function
	    Do tJCoFunction.execute(tJCoDestination)
	    
	    #; Get the table parameter list
		Set tJCoParameterList=tJCoFunction.getTableParameterList()
	    If $IsObject(tJCoParameterList) {
		    
		    #; Get the named tabled
			Set tJCoTable=tJCoParameterList.getTable("API_METHODS")
			If $IsObject(tJCoTable) {
				
				#; For each row
				For tI=0:1:tJCoTable.getNumRows()-1 {
					
					#; Select the row
					Do tJCoTable.setRow(tI)
					
					Set tName=tJCoTable.getString("FUNCTION")
					If tName'="" {
						
						If pFilterString="" {
							Set tNameArray(tName)=""
						} else {
							Set tInclude=1
							For tJ=1:1:$Length(pFilterString," ") {
								Set tSubString=$Piece(pFilterString," ",tJ)
								if ((tSubString'="")&&'(tName[$$$UPPER(tSubString))) {
									Set tInclude=0
								}
							}
							If tInclude Set tNameArray(tName)=""
						}
					}
				}
				
				#; Insert into list of datatypes
				Set tName="" For {
					
					Set tName=$Order(tNameArray(tName)) If tName="" Quit
					
					Set tSC=pList.Insert(tName)
					If $$$ISERR(tSC) Quit
				}
				If $$$ISERR(tSC) Quit
			}
	    }
		
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	If tJavaGatewayConnected {
		
		Set tSC2=tJavaGateway.%Disconnect()
		If $$$ISERR(tSC2) {
			If $$$ISERR(tSC) {
				Set tSC=$$$ADDSC(tSC,tSC2)
			} else {
				Set tSC=tSC2
			}
		}
	}
	
	Quit tSC
}

/// Retrieve a list of Known RFCs from the SAP repository
/// 
/// Note: This method relies on pre-knowlege of the structure of the SWO_QUERY_API_METHODS function
/// which should not vary between SAP JCO versions.
Method GetRFCList(Output pList As %ListOfDataTypes, pFilterString As %String = "") As %Status
{
	#dim tSC,tSC2 As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tJavaGatewayConnected,tExecuteFailed As %Boolean = 0
	#dim tI,tJ As %Integer
	#dim tName,tNameArray,tSubString As %String
	#dim tInclude As %Boolean
	
	#; Java objects
	#dim tJCoDestination As com.sap.conn.jco.JCoDestination
	#dim tJCoRepository As com.sap.conn.jco.JCoRepository
	#dim tJCoFunction As com.sap.conn.jco.JCoFunction
	#dim tJCoTableParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoInputParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoTable As com.sap.conn.jco.JCoTable
	
	try {
			
		#; Connect to the target SAP system
		Set tSC=..Connect(.tJavaGateway,.tJCoDestination,.tJCoRepository)
		If $$$ISERR(tSC) Quit
		
		#; Connected
		Set tJavaGatewayConnected=1
		
		#; Create the list of data types to be returned
		Kill %objlasterror
		Set pList=##class(%Library.ListOfDataTypes).%New()
		If '$IsObject(pList) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Library.ListOfDataTypes")) Quit
		
		#; Attempt to get the function, its not an error for it not to be available
		Set tJCoFunction=tJCoRepository.getFunction("RFC_FUNCTION_SEARCH")
		
		#; Not available
	    If '$IsObject(tJCoFunction) Quit
	    	
		Set tJCoTableParameterList=tJCoFunction.getTableParameterList()
		If $IsObject(tJCoTableParameterList) {
					
			Set tJCoInputParameterList=tJCoFunction.getImportParameterList()
			If $IsObject(tJCoInputParameterList) {
				
				#; Set the filter for the function name
				Do tJCoInputParameterList.setValue("FUNCNAME","*"_$TR(pFilterString," ","*")_"*")
				
				#; Execute the function
				Set tExecuteFailed=0
				try {
	    			Do tJCoFunction.execute(tJCoDestination)
				} catch (e) {
					Set tExecuteFailed=1
				}
				
				#; No matches
				If tExecuteFailed Quit
	    
	    		Set tJCoTable=tJCoTableParameterList.getTable("FUNCTIONS")
	    		If $IsObject(tJCoTable) {
		    		
		    		#; For each row
					For tI=0:1:tJCoTable.getNumRows()-1 {
						
						#; Select the row
						Do tJCoTable.setRow(tI)
						
						#; Get the function name
						Set tName=tJCoTable.getString("FUNCNAME")
						If tName'="" {
						
							If pFilterString="" {
								Set tNameArray(tName)=""
							} else {
								Set tInclude=1
								For tJ=1:1:$Length(pFilterString," ") {
									Set tSubString=$Piece(pFilterString," ",tJ)
									if ((tSubString'="")&&'(tName[$$$UPPER(tSubString))) {
										Set tInclude=0
									}
								}
								If tInclude Set tNameArray(tName)=""
							}
						}	
					}
					
					#; Insert into list of datatypes
					Set tName="" For {
					
						Set tName=$Order(tNameArray(tName)) If tName="" Quit
					
						Set tSC=pList.Insert(tName)
						If $$$ISERR(tSC) Quit
					}
					If $$$ISERR(tSC) Quit
	    		}		
			}
		}

	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	
	If tJavaGatewayConnected {
		
		Set tSC2=tJavaGateway.%Disconnect()
		If $$$ISERR(tSC2) {
			If $$$ISERR(tSC) {
				Set tSC=$$$ADDSC(tSC,tSC2)
			} else {
				Set tSC=tSC2
			}
		}
	}
	
	Quit tSC
}

}
