/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble, EnsSAPJCO)

/// SAP connectivity through SAPJCo. Supporting SAPJCo 3.07+
Class EnsLib.SAP.Operation Extends Ens.BusinessOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Domain for $$$Text()
Parameter DOMAIN = "EnsSAP";

Parameter INVOCATION = "Queue";

/// MM20131001
/// Typical tracelevels for SAPJCO are:
/// <ul>
/// <li> 0 - nothing</li>
/// <li> 1 - errors and warnings</li>
/// <li> 2 - execution path, errors and warnings</li>
/// <li> 3 - full execution path, errors and warnings</li>
/// <li> 4 - execution path, info messages, errors and warnings</li>
/// <li> 6 - full execution path, info messages, errors and warnings</li>
/// <li> 7 - debug messages, full execution path, info messages, errors and warnings</li>
/// <li> 8 - verbose debug messages, full execution path, info messages, errors and warnings</li>
/// </ul>
Property SAPTraceLevel As %String(VALUELIST = ",0,1,2,3,4,5,6,7,8,9,10") [ InitialExpression = 0 ];

/// MM20171219
/// Directory path for output of SAPJCO trace.
Property SAPTracePath As %String [ InitialExpression = {$system.Util.DataDirectory()} ];

/// MM 20130917 added to allow Type B+D connection
/// Settings
Parameter SETTINGS = "SAPType:Connect,SAPHost:ConnectA,SAPClient:Connect,SAPSystemNumber:ConnectA,SAPCredentials:Connect,SAPLanguage:Connect,SAPTraceLevel:Connect,SAPTracePath:Connect,SAPMSHost:ConnectB,SAPGWHost:ConnectB,SAPGWServ:ConnectB,SAPGroup:ConnectB,SAPR3Name:ConnectB,JavaGatewayConfigItemName:Basic,SAPTransactionAutoCommit:Basic,SAPResponseHandler:Basic";

/// MM 20130917 
/// SAP Type for connect: "A" means direct connect, "B" means load balanced connect
Property SAPType As %String(VALUELIST = ",A,B") [ InitialExpression = "A", Required ];

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Message Server Host (jco.client.mshost).
Property SAPMSHost As %String(MAXLEN = 1024);

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Gateway Host (jco.client.gwhost).
Property SAPGWHost As %String(MAXLEN = 1024);

/// MM 20130917
/// Used for loadbalanced Type "B" connect. Gateway Service (jco.client.gwserv).
Property SAPGWServ As %String(TRUNCATE = 1);

/// MM 20130917
/// Used for loadbalanced Type "B" connect. SAP Group (jco.client.group).
Property SAPGroup As %String(TRUNCATE = 1);

/// MM 20130917
/// Used for loadbalanced Type "B" connect. SAP Group (jco.client.r3name).
Property SAPR3Name As %String(TRUNCATE = 1);

/// SAP Client e.g 000
Property SAPClient As %String(TRUNCATE = 1);

/// This is the ID name of the set of credentials values to be used to access the external system
Property SAPCredentials As %String;

Property SAPLanguage As %String(TRUNCATE = 1);

/// MM 20130917
/// SAPHost is the SAP server's network name or IP address (jco.client.ashost).
Property SAPHost As %String(MAXLEN = 1024);

/// SAP SystemNumber e.g 00
Property SAPSystemNumber As %String(TRUNCATE = 1);

/// After a successful BAPI/RFC-call this setting decides if
/// automatically the BAPI "BAPI_TRANSACTION_COMMIT" will be executed.
Property SAPTransactionAutoCommit As %Boolean [ InitialExpression = 1 ];

/// Errorhandler, typically a BO or BP. The Errorhandler will get the SAP Response.
Property SAPResponseHandler As %String(MAXLEN = 100);

/// This is the name of the (required) configuration item which hosts the JavaGateway.
Property JavaGatewayConfigItemName As %String(MAXLEN = 100);

/// Java gateway address is the server (name or IP address) where the java gateway runs on,
/// derived during initialization from the JavaGateway named configuration item in the containing
/// production
Property JavaGatewayAddress As %String(TRUNCATE = 1);

/// The port on which the javagateway listens, derived during initialization from the 
/// JavaGateway named configuration item in the containing production
Property JavaGatewayPort As %String(TRUNCATE = 1);

/// Derived during initialization from SAPCredentials (Not A Setting)
Property SAPUser As %String(TRUNCATE = 1);

/// Derived during initialization from SAPCredentials (Not A Setting)
Property SAPPassword As %String(TRUNCATE = 1);

/// MM20171201 Fix Session-Handling
Property connJavaGateway As %RegisteredObject;

/// MM20171201 Fix Session-Handling
Property connJCoDestination As %RegisteredObject;

/// MM20171201 Fix Session-Handling
Property connJCoRespository As %RegisteredObject;

/// initialize Business Host object
Method %OnNew(pConfigName As %String) As %Status
{
	Quit $method($this,"initConfig",.pConfigName) ; call subclass
}

/// This is the default message handler.  All request types not declared in the message map are delivered here
Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Quit ..CallSAP(pRequest,.pResponse)
}

/// Create and initialize a Connection and Repositiory
Method Connect(ByRef pGateway As EnsLib.JavaGateway.JavaGateway, ByRef pConnection As %ObjectHandle, ByRef pRepository As %ObjectHandle) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tPropName As %String
	#dim tUtils As EnsLib.SAP.Utils

	try {
		#; Create a new instance of the SAPBAPI.Meta class
		Kill %objlasterror
		Set tUtils = ##class(EnsLib.SAP.Utils).%New()
		If '$IsObject(tUtils) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.SAP.Utils")) Quit

		#; Initialize it copies of this objects properties
		/// MM 20130917 Added Parameters
		For tPropName="SAPClient","SAPHost","SAPLanguage","SAPUser","SAPPassword","SAPSystemNumber","JavaGatewayAddress","JavaGatewayPort","SAPType","SAPMSHost","SAPGWHost","SAPGWServ","SAPGroup","SAPR3Name" {
			set $zobjproperty(tUtils,tPropName)=$zobjproperty($this,tPropName)
		}
		#; Perform a connection and initialize the output parameters
		Set tSC=tUtils.Connect(.pGateway,.pConnection,.pRepository)
		/// MM 20131001 Toggle SAP Trace
		if tSC do ##class(com.sap.conn.jco.JCo).setTrace(pGateway,..SAPTraceLevel,$REPLACE(##class(%File).NormalizeDirectory(..SAPTracePath),"\","\\"))

	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Call SAP
Method CallSAP(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status [ Private ]
{
	#dim tSC,tSC2 As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tBAPI As %String
	#dim tJavaGateway As EnsLib.JavaGateway.JavaGateway
	#dim tTableFieldCount As %Integer
	#dim tJavaGatewayConnected As %Boolean = 0

	#; Java Objects
	#dim tJCoDestination As com.sap.conn.jco.JCoDestination
	#dim tJCoFunction As com.sap.conn.jco.JCoFunction
	#dim tJCoRespository As com.sap.conn.jco.JCoRepository
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList

	try {

		#; Connect to the SAP instance
		set tSC=..EasyConnect(.tJavaGateway,.tJCoDestination,.tJCoRespository) // MM20170318

		If $$$ISERR(tSC) Quit

		#; Assert we have the all the necessary objects
		$$$ASSERT($IsObject(tJavaGateway))
		$$$ASSERT($IsObject(tJCoDestination))
		$$$ASSERT($IsObject(tJCoRespository))

		#; Set the Connected Flag ( will need for tidy up later )
		Set tJavaGatewayConnected=1

		#; Retrieve the name of the BAPI from the request parameter
		Set tBAPI=pRequest.%GetParameter("BAPI")

		#; BAPI parameter cannnot be empty string
		$$$ASSERT(tBAPI'="")

		#; Retrieve the BAPI function handle
		Kill %objlasterror
		Set tJCoFunction=tJCoRespository.getFunction(tBAPI)

		If '$IsObject(tJCoFunction) {
			Set tSC=$Get(%objlasterror,$$$ERROR($$$EnsErrGeneral,$$$Text("Unable to retrieve function handle from repository for '%1'"),tBAPI)) 
			Quit
		}

		#; Marshal any input parameters
		Set tSC=..MarshalParameters(pRequest,tJCoFunction,$$$ENS2SAP)
		If $$$ISERR(tSC) Quit

		#; Marshal any tables
		Set tSC=..MarshalTables(pRequest,tJCoFunction,$$$ENS2SAP)
		If $$$ISERR(tSC) Quit

		#; Create an instance of the related response object
		Set tSC=pRequest.NewResponse(.pResponse)
		If $$$ISERR(tSC) Quit

		#; Persist it
		Set tSC=pResponse.%Save()
		If $$$ISERR(tSC) Quit

		#; Execute the function, catching errors
		try {

			$$$catTRACE("protocol","Function Called")

			do ..StartTransactionIfNotAlready()  // MM20170318
			
			Do tJCoFunction.execute(tJCoDestination)		

			$$$catTRACE("protocol","Function Succeeded")

		} catch (e) {

			$$$catTRACE("protocol","Function Failed")

			#; Function Failure is NOT a hard IRIS failure, fill in the error message
			Set pResponse.ISCuIsOK=0
			Set pResponse.ISCuErrorMessage=e.Name_":"_e.Data_":"_$ZE
			
			$$$LOGWARNING(pResponse.ISCuErrorMessage)
			If $PIECE($ZE,">")="<ZJGTW" {
				Set tSC = $G(%objlasterror, $$$ERROR(5001,pResponse.ISCuErrorMessage))
			}
		}

		#; No further processing required?
		If pResponse.ISCuIsOK=0 Quit

		#; Marshal any output parameters
		Set tSC=..MarshalParameters(pResponse,tJCoFunction,$$$SAP2ENS)
		If $$$ISERR(tSC) Quit

		#; Marshal any output tables
		Set tSC=..MarshalTables(pResponse,tJCoFunction,$$$SAP2ENS)
		If $$$ISERR(tSC) Quit

		#; Handle any error response
		Set tSC=..ProcessError(tJCoFunction,pResponse)
		If $$$ISERR(tSC) Quit

		#; Send the message to the appropriate response handler
		If ..SAPResponseHandler'="" {
			Set tSC=..SendRequestAsync(..SAPResponseHandler,pResponse)
			If $$$ISERR(tSC) Quit
		}
		 // MM20170318
		 if ..SAPTransactionAutoCommit {
			do ..Transaction("COMMIT")
		} elseif (tJCoFunction.getName()="BAPI_TRANSACTION_ROLLBACK")||(tJCoFunction.getName()="BAPI_TRANSACTION_COMMIT") {
			set tSC=..DisconnectJavaGateway(tJavaGateway,tSC)
		}

	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}

	Quit tSC
}

/// MM20171201 Fix Session-Handling
Method DisconnectJavaGateway(pJavaGateway, tSC) As %Status
{
	#Dim tSC2 as %Status
	Set tSC2=pJavaGateway.%Disconnect()

	Set (..connJavaGateway,..connJCoDestination,..connJCoRespository)=""
	
	If $$$ISERR(tSC2) {
		If $$$ISERR(tSC) {
			Set tSC=$$$ADDSC(tSC,tSC2)
		} Else {
			Set tSC=tSC2
		}
	}
	Return tSC
}

/// MM20171201 Fix Session-Handling
Method EasyConnect(ByRef tJavaGateway, ByRef tJCoDestination, ByRef tJCoRespository)
{
	#Dim tSC=$$$OK
	if ..connJavaGateway="" {
		set tSC=..Connect(.tJavaGateway,.tJCoDestination,.tJCoRespository)
		if tSC {
			Set ..connJavaGateway=tJavaGateway
			Set ..connJCoDestination=tJCoDestination
			set ..connJCoRespository=tJCoRespository
		}
	} else {
		set tJavaGateway=..connJavaGateway,tJCoDestination=..connJCoDestination,tJCoRespository=..connJCoRespository
	}
	Return tSC
}

/// MM20171201 Fix Session-Handling
Method StartTransactionIfNotAlready()
{
	$$$TRACE("StartTransactionIfNotAlready....")
	if '##class(com.sap.conn.jco.JCoContext).isStateful(..connJavaGateway,..connJCoDestination) {
		do ##class(com.sap.conn.jco.JCoContext).begin(..connJavaGateway,..connJCoDestination)
		$$$TRACE("JCoContext.begin()...")
	}
}

/// MM20171201 Fix Session-Handling
Method Transaction(pCommitOrRollback = "") As %Status
{
	Return:'$CASE(pCommitOrRollback,"COMMIT":1,"ROLLBACK":1,:0) $$$ERROR(5001,"Input parameter for method Transaction() has to be either 'COMMIT' or 'ROLLBACK'")
	$$$TRACE("Transaction "_pCommitOrRollback)
	#Dim tJCoFunction,tJCoParameterList
	#Dim e as %Exception.AbstractException
	#Dim tSC=$$$OK
	
	try {
		Set tJCoFunction=..connJCoRespository.getFunction("BAPI_TRANSACTION_"_pCommitOrRollback)
		If '$IsObject(tJCoFunction) Quit

		#; Set wait value 
		Set tJCoParameterList=tJCoFunction.getImportParameterList()
		If $IsObject(tJCoParameterList) {
			Do tJCoParameterList.setValue("WAIT","X")
		}
		Do tJCoFunction.execute(..connJCoDestination)
		
		#; Evaluate RETURN Structure to see if Commit/Rollback was done
		#Dim tJCoStructure as %RegisteredObject
		set tJCoParameterList=tJCoFunction.getExportParameterList()
		Set tJCoStructure=tJCoParameterList.getStructure("RETURN")
		
		if $CASE(tJCoStructure.getString("TYPE"),"":1,$C(0):1,"S":1,:0) {
			#; Absence of Type-value and TYP S for successindicates correct Commit/Rollback
			$$$TRACE("Transaction "_pCommitOrRollback_ " successful")
		} else {
			$$$TRACE($ASCII(tJCoStructure.getString("TYPE")))
			set tSC=$$$ERROR(5001, pCommitOrRollback_" Error of TYPE: "_tJCoStructure.getString("TYPE")_" with MESSAGE: "_tJCoStructure.getValue("MESSAGE"))
		}
		
	} catch e {
		set tSC=$$$ERROR(5001,e.DisplayString())
	}

	if ##class(com.sap.conn.jco.JCoContext).isStateful(..connJavaGateway,..connJCoDestination) {
		$$$TRACE("JCoContext.end()...")
		do ##class(com.sap.conn.jco.JCoContext).end(..connJavaGateway,..connJCoDestination)
	}
	set tSC=..DisconnectJavaGateway(..connJavaGateway,tSC)
	Set (..connJavaGateway,..connJCoDestination,..connJCoRespository)=""
	Return tSC
}

/// Marshal parameters
ClassMethod MarshalParameters(pObject As %RegisteredObject, pJCoFunction As %ObjectHandle, pDirection As %Integer) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tI As %Integer
	#dim tObjPropName,tObjPropValue,tSapFieldName,tSapFieldValue,tValueType As %String
	#dim tSapPropName As %ObjectHandle

	#; Java Objects
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoMetaData As com.sap.conn.jco.JCoMetaData
	#dim tJCoStructure As com.sap.conn.jco.JCoStructure

	try {

		#; Determine input parameters (direct properties & structures)
		Kill %objlasterror

		If pDirection=$$$ENS2SAP {
			Set tJCoParameterList=pJCoFunction.getImportParameterList()
		} Else {
			Set tJCoParameterList=pJCoFunction.getExportParameterList()
		}

		#; There may NOT be any Parameters
		If $IsObject(tJCoParameterList) {

			Set tJCoMetaData=tJCoParameterList.getListMetaData()
			$$$ASSERT($IsObject(tJCoMetaData))

			If pDirection=$$$ENS2SAP {
				$$$catTRACE("protocol",$$$Text("Marshalling Input Parameters"))
			} Else {
				$$$catTRACE("protocol",$$$Text("Marshalling Output Parameters"))
			}

			#; Fields are indexed from 0 - (n-1)
			for tI=0:1:(tJCoParameterList.getFieldCount()-1) {

				#; Get the name of the SapField
				Set tSapFieldName=tJCoMetaData.getName(tI)
				$$$ASSERT(tSapFieldName'="")

				#; Convert SAP field name to IRIS request property name  	
				Set tObjPropName=$$$SapName2EnsName(tSapFieldName)

				#; We are marshalling a structure or an atom
				If tJCoMetaData.getTypeAsString(tI)="STRUCTURE" {
					#; Structure
					Set tJCoStructure=tJCoParameterList.getStructure(tSapFieldName)
					$$$ASSERT($IsObject(tJCoStructure))

					#; Marshal the structure
					Set tSC=..MarshalStructure(tJCoStructure,$zobjproperty(pObject,tObjPropName),pDirection)	
					If $$$ISERR(tSC) Quit
				} Else {
					$$$catTRACE("protocol",$$$Text("Marshalling Value"))

					#; Get the SAP name (object) for the specified field
					Set tSapPropName=tJCoMetaData.getName(tI)

					If (pDirection = $$$ENS2SAP) {

						#; Now fetch the property from the object
						Set tObjPropValue=$zobjproperty(pObject,tObjPropName)

						#; Set the value
						/// MM 20130922 Only set value if '="", otherwise default settings get overwritten
						Do:tObjPropValue'="" tJCoParameterList.setValue(tSapPropName,tObjPropValue)

						$$$catTRACE("protocol",$$$Text("Set SAP Field: ")_tSapFieldName_$$$Text(" with Object Prop value: ")_tObjPropValue)

					} Else {

						#; MM 20171219 don't use getValue here (which get object references) but use getString() 
						#; to get the values behind and then translate Date/Time by removing "-:"
						#; Fetch the value from SAP
						Set tSapFieldValue=tJCoParameterList.getString(tSapPropName)

						#; Act on Value Type
						Set tValueType=tJCoParameterList.getMetaData().getTypeAsString(tI) //tJCoRecordMetaData.getTypeAsString(tI)
			
						#; If the value type is a DATE or a TIME
						If (tValueType=$$$FieldTypeDate)||(tValueType=$$$FieldTypeTime) {

							#; String out extraneous characters
							Set tSapFieldValue=$TR(tSapFieldValue,"-:")
						}

						#; Set the object property value
						Set $zobjproperty(pObject,tObjPropName)=tSapFieldValue

						$$$catTRACE("protocol",$$$Text("Set Object Prop: ")_tObjPropName_$$$Text(" with SAP Field value: ")_tSapFieldValue)
					}
				}
			}
		}
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Marshals a SAP structure
ClassMethod MarshalStructure(pJCoStructure As %ObjectHandle, pObject As %RegisteredObject, pDirection As %Integer) As %Status [ Private ]
{

	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tI As %Integer
	#dim tObjPropName,tObjPropValue,tSapFieldName,tSapFieldValue As %String

	#; Java objects
	#dim tJCoRecordMetaData As com.sap.conn.jco.JCoRecordMetaData
	#dim tSapPropName As %ObjectHandle

	try {

		Kill %objlasterror

		$$$catTRACE("protocol",$$$Text("Marshalling Structure"))

		#; Get the field meta-data for the structure
		Set tJCoRecordMetaData=pJCoStructure.getRecordMetaData()

			#; For each field
		For tI=0:1:pJCoStructure.getFieldCount()-1 {
			Set tSapFieldName=tJCoRecordMetaData.getName(tI)
			Set tObjPropName=$$$SapName2EnsName(tSapFieldName)
			Set tSapPropName=tJCoRecordMetaData.getName(tI)
			try {

				If pDirection=$$$ENS2SAP {

					#; Get corresponding property from object
					Set tObjPropValue=$zobjproperty(pObject,tObjPropName)

					#; Store the property value
					Do pJCoStructure.setValue(tSapPropName,tObjPropValue)

					$$$catTRACE("protocol",$$$Text("Set SAP Field: ")_tSapFieldName_$$$Text(" with Object Prop value: ")_tObjPropValue)

				} Else {

					#; Fetch the value from SAP
					/// MM 20130922 don't use getValue here (which get object references) but use getString() to get the values behind
					Set tSapFieldValue=pJCoStructure.getString(tSapPropName)
					#; Act on Value Type
					Set tValueType=tJCoRecordMetaData.getTypeAsString(tI)
		
					#; If the value type is a DATE or a TIME
					If (tValueType=$$$FieldTypeDate)||(tValueType=$$$FieldTypeTime) {

						#; String out extraneous characters
						Set tSapFieldValue=$TR(tSapFieldValue,"-:")
					}

					#; Store in the object
					Set $zobjproperty(pObject,tObjPropName)=tSapFieldValue

					$$$catTRACE("protocol",$$$Text("Set Object Prop: ")_tObjPropName_$$$Text(" with SAP Field value: ")_tSapFieldValue)
				}
			} catch (e) {
				#; Property not found
				If e.Name="<PROPERTY DOES NOT EXIST>" {
					$$$LOGWARNING($$$Text("No corresponding property for SAP Field: ")_tSapFieldName_$$$Text(" in object: ")_pObject.%ClassName(1)_$$$Text(" : ignored"))
				}
			}
		}

	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Marshals SAP Tables
ClassMethod MarshalTables(pObject As %RegisteredObject, pJCoFunction As %ObjectHandle, pDirection As %Integer) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tI,tJ,tTableFieldCount,tRowCount As %Integer = 0
	#dim tSapTableName,tClassName As %String
	#dim tObjColl,tObjCollItem As %ObjectHandle
	#dim tObject As %RegisteredObject
	#dim tResultSet As %ResultSet
	#dim tCompiledClass As %CompiledClass

	#; Java objects
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoListMetaData As com.sap.conn.jco.JCoListMetaData
	#dim tJCoTable As com.sap.conn.jco.JCoTable

	try {

		#; Find the number of fields in the BAPI which are tables
		Set tSC=..GetTableFieldCount(pJCoFunction,.tTableFieldCount)
		If $$$ISERR(tSC) Quit

		#; If there is nothing to do then quit
		If tTableFieldCount=0 Quit

		Kill %objlasterror
		Set tJCoParameterList=pJCoFunction.getTableParameterList()
		$$$ASSERT($IsObject(tJCoParameterList))

		Set tJCoListMetaData=tJCoParameterList.getListMetaData()
		$$$ASSERT($IsObject(tJCoListMetaData))

		#; For each table field
		For tI=0:1:tTableFieldCount-1 {

			#; Get the table name as a string
			Set tSapTableName=tJCoListMetaData.getName(tI)

			#; Now get the actual table
			/// MM 20130920 //getTable(tSapTableName) is wrong
			Set tJCoTable=tJCoParameterList.getTable(tI) 
			$$$ASSERT($IsObject(tJCoTable))

			#; Get the corresponding property (collection) from the request
			Set tObjColl=$property(pObject,$$$SapName2EnsName(tSapTableName))

			If pDirection=$$$ENS2SAP {

				#; For each item in the collection
				For tJ=1:1:tObjColl.Count() {

					#; Append a row to the JavaTable
					Do tJCoTable.appendRow()

					#; Get the object representing the row
					Set tObjCollItem=tObjColl.GetAt(tJ)

					#; Now Marshal that object
					Set tSC=..MarshalStructure(tJCoTable,tObjCollItem,pDirection)
					If $$$ISERR(tSC) Quit
				}
			} Else {

				#; Derive the class name for each object to be inserted into the collection
				Set tClassName=pObject.%ClassName(1)
				Set $Piece(tClassName,".",$Length(tClassName,"."))=$$$SapName2EnsName(tSapTableName)

				#; Open the %Dictionary definition
				Set tCompiledClass=##class(%Dictionary.CompiledClass).%OpenId(tClassName,,.tSC)
				If $$$ISERR(tSC) Quit

				$$$ASSERT($IsObject(tCompiledClass))

				#; For each row in the SAP table
				Set tRowCount=tJCoTable.getNumRows()

				#; Metadata cache
				Kill metadata
				Set metadata = ""

				For tJ=0:1:tRowCount-1 {

					#; Set the row of the JCo Table from SAP
					/// MM 20130921 setRow() wasn't called at all
    				Do tJCoTable.setRow(tJ)
    
					#; Get the marshalling code as SQL
					Set tSC = ..MarshalViaSQL(tJCoTable, tClassName, pObject, .metadata)
					If $$$ISERR(tSC) Quit
				}
				If $$$ISERR(tSC) Quit
			}
		}
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Determine the number of fields in a SAP Table
ClassMethod GetTableFieldCount(pJCoFunction As %ObjectHandle, Output pCount As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#; Java objects
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList

	Kill %objlasterror

	#; Optimistically set the output parmeter 
	Set pCount=0
	try {
		Set tJCoParameterList=pJCoFunction.getTableParameterList()
		If '$IsObject(tJCoParameterList) Quit

		Set pCount=tJCoParameterList.getFieldCount()

	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Marshal return table values via SQL ( Needed to handle possibly HUGE result sets)
ClassMethod MarshalViaSQL(pJCoTable As %ObjectHandle, pClassName As %String, pResponse As Ens.Response, ByRef pMetadata As %String) As %Status [ Private ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tI, tFieldCount As %Integer
	#dim tObjPropName,tValue,tValueType As %String

	#; Java objects
	#dim tJCoListMetaData As com.sap.conn.jco.JCoListMetaData = ""

	#dim populateMetadata As %Boolean = '$$$HasMetadata(pMetadata)

	try {

		Kill %objlasterror

		If populateMetadata {
			Set tJCoListMetaData = pJCoTable.getRecordMetaData()
			Set $$$MetadataFieldCount(pMetadata) = pJCoTable.getFieldCount()
		}
		
		Set tFieldCount = $$$MetadataFieldCount(pMetadata)

		Quit:'tFieldCount // Only proceed if tFieldCount > 0

		Kill %objlasterror
		Set row = $classmethod(pClassName, "%New")

		#; For each field
		for tI=0:1:tFieldCount-1 {
			If populateMetadata {
				Set $$$MetadataFieldEnsName(pMetadata, tI) = $$$SapName2EnsName(tJCoListMetaData.getName(tI))
				Set $$$MetadataFieldType(pMetadata, tI) = tJCoListMetaData.getTypeAsString(tI)
			}
		
			#; Determine the object property name
			Set tObjPropName = $$$MetadataFieldEnsName(pMetadata, tI)
		
			#; Act on Value Type
			Set tValueType = $$$MetadataFieldType(pMetadata, tI)
		
			#; Determine the value
			Set tValue = pJCoTable.getString(tI) If tValue=$C(0) Set tValue=""
		
			#; If the value type is a DATE or a TIME
			If (tValueType=$$$FieldTypeDate)||(tValueType=$$$FieldTypeTime) {
			
				#; String out extraneous characters
				Set tValue=$TR(tValue,"-:")
			}

			#; Set the row property
			Set $PROPERTY(row, tObjPropName) = tValue
		}

		#; Set response
		Do row.ISCuResponseSetObjectId(pResponse.%Id())

		$$$catTRACE("protocol", "About to save row - class: " _ pClassName _ ", responseId: " _ pResponse.%Id())

		#; Save the row
		Set tSC=row.%Save()
		If $$$ISERR(tSC) Quit
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// This list will appear in the testing wizard facility in the Management Portal
ClassMethod GetMessageList() As %String
{
	&sql(select list(origin) into :stringlist from %dictionary.compiledparameter where name='BAPI')
	Quit $LISTFROMSTRING(stringlist,",")
}

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tThisProductionName,tConfigItemId,tJavaGatewayConfigItemName,tJavaGatewayAddress,tJavaGatewayPort,tSAPUser,tSAPPassword,tCredentials As %String = ""
	#dim tConfigItem As Ens.Config.Item

	try {
		#; Query the containing production for its name
		Set tSC=##class(Ens.Director).GetProductionStatus(.tThisProductionName)
		If $$$ISERR(tSC) Quit

		#; Get the id of the JavaGateway configuration item
		Set tJavaGatewayConfigItemName=..JavaGatewayConfigItemName
		&sql(select id into :tConfigItemId from ens_config.item where name=:tJavaGatewayConfigItemName and production=:tThisProductionName)
		If SQLCODE'=0 {
			Set tSC=$$$ERROR($$$EnsErrGeneral,$$$Text("Couldn't determine JavaGateway configuration item from supplied JavaGatewayConfigItemName"))
			Quit
		}

		#; Open up the configuration item
		Set tConfigItem=##class(Ens.Config.Item).%OpenId(tConfigItemId,,.tSC)
		If $$$ISERR(tSC) Quit

		Set tSC=tConfigItem.PopulateModifiedSettings()
		If $$$ISERR(tSC) Quit

		#; Get the JavaGateway Address
		If tConfigItem.GetModifiedSetting("Address",.tJavaGatewayAddress) {
			Set ..JavaGatewayAddress=tJavaGatewayAddress
		}

		#; Must have a valid address
		If ..JavaGatewayAddress="" {
			Set tSC=$$$ERROR($$$EnsErrGeneral,$$$Text("Failed to determine valid JavaGateway 'Address' setting from named JavaGatewayConfigItem"))
			Quit
		}

		#; Get the JavaGateway Port
		If tConfigItem.GetModifiedSetting("Port",.tJavaGatewayPort) {
			Set ..JavaGatewayPort=tJavaGatewayPort
		}

		#; Must have a valid port
		If ..JavaGatewayPort="" {
			Set tSC=$$$ERROR($$$EnsErrGeneral,$$$Text("Failed to determine valid JavaGateway 'Port' setting from named JavaGatewayConfigItem"))
			Quit
		}

		Set ..JavaGatewayPort=tJavaGatewayPort

		#; Use the supplied credentials to determine the SAP username and password
		Set tCredentials=..SAPCredentials
		&sql(select Username,Password into :tSAPUser,:tSAPPassword  from ens_config.credentials where ID=:tCredentials)
		If SQLCODE'=0 {
			Set tSC=$$$ERROR($$$EnsErrGeneral,$$$Text("Failed to initialize SAPUsername and SAPPassword from supplied Credentials"))
			Quit
		}
		
		/// MM 20131001 Check for valid directory path of SAPTracePath setting.
		if '##class(%File).DirectoryExists(##class(%File).NormalizeDirectory(..SAPTracePath)) {
			set tSC=$$$ERROR(5001,"SAPTracePath: Directory does not exist.")
			Quit
		}


		#; Store the values, needed when a connection is made
		Set ..SAPUser=tSAPUser,..SAPPassword=tSAPPassword

	} catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Search the supplied parameter list for a named field.
ClassMethod HaveSapFieldNamed(pJCoParameterList As %ObjectHandle, pSapFieldName As %String, Output pFound As %Boolean, pSapFieldType As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tSapFieldName As %String
	#dim tI,tFieldCount As %Integer

	#; Java objects
	#dim tJCoListMetaData As com.sap.conn.jco.JCoListMetaData
	#dim tJCoTable As com.sap.conn.jco.JCoTable

	try {

		#; Assume NOT found
		Set pFound=0,pSapFieldType=""

		Set tJCoListMetaData=pJCoParameterList.getListMetaData()
		$$$ASSERT($IsObject(tJCoListMetaData))

		Set tFieldCount=pJCoParameterList.getFieldCount()
		#; Fields are indexed from 0 - (n-1)
		For tI=0:1:tFieldCount-1 {

			#; Get the name of the SapField
			Set tSapFieldName=tJCoListMetaData.getName(tI)
			If tSapFieldName=pSapFieldName {
				Set pFound=1,pSapFieldType=tJCoListMetaData.getTypeAsString(tI) Quit
			}
		}
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Process Return Value From SAP and derive any error message
ClassMethod ProcessError(pJCoFunction As %ObjectHandle, pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tFieldFound As %Boolean
	#dim tFieldType,tSubType,tError As %String
	#dim tI,tRowCount As %Integer

	#; Java objects
	#dim tJCoListMetaData As com.sap.conn.jco.JCoListMetaData
	#dim tJCoParameterList As com.sap.conn.jco.JCoParameterList
	#dim tJCoTable As com.sap.conn.jco.JCoTable
	#dim tJCoStructure As com.sap.conn.jco.JCoStructure

	#; Optimistically Fill in the response OK flag
	Set pResponse.ISCuIsOK=1

	try {

		#; First Try Table
		Kill %objlasterror
		Set tJCoParameterList=pJCoFunction.getTableParameterList()
		If $IsObject(tJCoParameterList) {

			Set tSC=..HaveSapFieldNamed(tJCoParameterList,"RETURN",.tFieldFound,.tFieldType)
			If $$$ISERR(tSC) Quit

			If tFieldFound {

				$$$ASSERT(tFieldType="TABLE")

				Set tJCoTable=tJCoParameterList.getTable("RETURN")
				If $IsObject(tJCoTable) {

					Set tRowCount=tJCoTable.getNumRows()

					#; For each row in the table
					for tI=0:1:tRowCount-1 {

						#; Select the row
						Do tJCoTable.setRow(tI)

						Set tSubType=tJCoTable.getString("TYPE") If tSubType=$C(0) Set tSubType=""

						#; If any type in any row of the table is 'E' or 'A'
						If ((tSubType="E")||(tSubType="A")) {

							#; Response has errored
							Set pResponse.ISCuIsOK=0

							#; Record the error message
							Set tError=tJCoTable.getString("MESSAGE") If tError=$C(0) Set tError=""

							Set pResponse.ISCuErrorMessage=tError
						}
					}
				}
				#; It WAS a table, all done
				Quit
			}
		}

		#; Try Structure?
		Set tJCoParameterList=pJCoFunction.getExportParameterList()
		If $IsObject(tJCoParameterList) {

			Set tSC=..HaveSapFieldNamed(tJCoParameterList,"RETURN",.tFieldFound,.tFieldType)
			If $$$ISERR(tSC) Quit

			If tFieldFound {

				#; If its a structure
				If tFieldType="STRUCTURE" {

					#; Yes, attempt to get return member
					Set tJCoStructure=tJCoParameterList.getStructure("RETURN")
					If $IsObject(tJCoStructure) {

						Set tSubType=tJCoStructure.getString("TYPE") If tSubType=$C(0) Set tSubType=""

						If ((tSubType="E")||(tSubType="A")) {

							#; Response has errored
							Set pResponse.ISCuIsOK=0

							#; Record the error message
							Set tError=tJCoStructure.getString("MESSAGE") If tError=$C(0) Set tError=""

							Set pResponse.ISCuErrorMessage=tError
						}
					}
				}
			}
		}
	} catch (e) {
		If e.Name="<ZJGTW>",$Data(%objlasterror) Set tSC=%objlasterror Quit
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

}
