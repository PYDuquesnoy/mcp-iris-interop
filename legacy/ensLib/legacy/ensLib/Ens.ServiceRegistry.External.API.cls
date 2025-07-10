/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.ServiceRegistry.External.API Extends %RegisteredObject
{

Parameter DOMAIN = "Ensemble";

// ------------------------------Check Existance of Objects------------------------------------------------

ClassMethod ExistsService(pName As %String, pDomain As %String, pVersion As %String) As %Boolean
{
	Set tID = pName_"||"_pDomain_"||"_pVersion
	&sql(SELECT ID FROM ENS_SERVICEREGISTRY_EXTERNAL.SERVICE WHERE ID=:tID)
	Quit 'SQLCODE
}

ClassMethod ExistsAttribute(pID) As %Boolean
{
	&sql(SELECT ID FROM ENS_SERVICEREGISTRY_EXTERNAL.ATTRIBUTE WHERE ID=:pID)
	Quit 'SQLCODE
}

ClassMethod ExistsContact(pID) As %Boolean
{
	&sql(SELECT ID FROM ENS_SERVICEREGISTRY_EXTERNAL.CONTACT WHERE ID=:pID)
	Quit 'SQLCODE
}

ClassMethod ExistsAction(pID) As %Boolean
{
	&sql(SELECT ID FROM ENS_SERVICEREGISTRY_EXTERNAL.ACTION WHERE ID=:pID)
	Quit 'SQLCODE
}

ClassMethod ExistsFile(pID) As %Boolean
{
	&sql(SELECT ID FROM ENS_SERVICEREGISTRY_EXTERNAL.FILESTORE WHERE ID=:pID)
	Quit 'SQLCODE
}

// --------------------------------------Delete Objects --------------------------------------------------

ClassMethod DeleteService(pID As %String) As %String
{
	Quit:'..ExistsService($p(pID,"||"),$p(pID,"||",2),$p(pID,"||",3)) "No registered service has ID "_pID
	&sql(DELETE FROM ENS_SERVICEREGISTRY_EXTERNAL.SERVICE WHERE ID=:pID)
	If SQLCODE {
		Quit "SQL Error deleting registered service: SQLCODE="_SQLCODE_" / "_$G(%msg)
	}
	Quit ""
}

ClassMethod DeleteAttribute(pID) As %Status
{
	Quit ##class(Ens.ServiceRegistry.External.Attribute).%DeleteId(pID)
}

ClassMethod DeleteContact(pID) As %Status
{
	Quit ##class(Ens.ServiceRegistry.External.Contact).%DeleteId(pID)
}

ClassMethod DeleteAction(pID) As %Status
{
	Quit ##class(Ens.ServiceRegistry.External.Action).%DeleteId(pID)
}

ClassMethod DeleteFile(pID) As %Status
{
	Quit ##class(Ens.ServiceRegistry.External.FileStore).%DeleteId(pID)
}

// ---------------------------------Misc-------------------------------------------------------------------

ClassMethod CloneService(pID As %String, pName As %String, pDomain As %String, pVersion As %String) As %Status
{
	Set oldSvc = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pID,,.tSC)
	Quit:$$$ISERR(tSC) tSC
	Quit:'$IsObject(oldSvc) $$$ERROR($$$EnsErrGeneral,"No existing service has ID "_pID)
	Set newSvc = oldSvc.%ConstructClone(1)
	Quit:'$IsObject(newSvc) $$$ERROR($$$EnsErrGeneral,"Failed to construct new service from old")
	Set newSvc.Name = pName
	Set newSvc.Domain = pDomain
	Set newSvc.Version = pVersion
	Set tSC = newSvc.%Save()
	Quit tSC
}

ClassMethod Count() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount FROM Ens_ServiceRegistry_External.Service)
	Quit tCount
}

ClassMethod DisplayLastModified(pID As %String) As %TimeStamp [ Internal ]
{
	Set tSvc = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pID,,.tSC)
	Quit:'$IsObject(tSvc)||($$$ISERR(tSC)) ""
	Set tUTC = tSvc.LastModified
	Quit ##class(Ens.DataType.UTC).timeUTCtoLocal(tUTC)
}

// -------------------------------------Make Lists------------------------------------------------------------------

/// Returns an alphabetically sorted list of all non-blank topic names that are used in Registry services
Query EnumerateTopics() As %Query(ROWSPEC = "Topic:%String") [ Internal, SqlProc ]
{
}

ClassMethod EnumerateTopicsExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set tSC=$$$OK, SQLCODE=0
	Set qHandle=""
	&sql(DECLARE C2 CURSOR FOR
		SELECT Topics INTO :tTopicList FROM Ens_ServiceRegistry_External.Service)
	&sql(OPEN C2) 
	For {
		&sql(FETCH C2)  Quit:SQLCODE
		Set tCount=$LL(tTopicList)
		For i=1:1:tCount {
			Set tTopic=$ZStrip($LG(tTopicList,i),"<>WC")
			Set:tTopic'="" qHandle(tTopic)=""
		}
	}
	Set tCode=SQLCODE
	&sql(CLOSE C2)
	Set:'SQLCODE SQLCODE=tCode
	Set:SQLCODE'=100&&SQLCODE tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrGeneral,"SQL error enumerating Topics: SQLCODE="_SQLCODE_" / "_$G(%msg)))
	Quit tSC
}

ClassMethod EnumerateTopicsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = EnumerateTopicsExecute ]
{
	Set qHandle=$O(qHandle(qHandle))
	Set:""=qHandle Row="", AtEnd=1
	Set:""'=qHandle Row=$LB(qHandle)
	Quit $$$OK
}

ClassMethod EnumerateTopicsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = EnumerateTopicsFetch ]
{
	Kill qHandle
	Quit $$$OK
}

Query ListContactTypes() As %SQLQuery [ Internal ]
{
	Select Distinct %Exact(Type) As Type from Ens_ServiceRegistry_External.Contact Where Type is not Null
}

Query ListSchemaTypes() As %SQLQuery [ Internal ]
{
	Select Distinct Type from (
		Select Distinct Schema_Type As Type from Ens_ServiceRegistry_External.Service
	Union
		Select Distinct ResponseSchema_Type As Type from Ens_ServiceRegistry_External.Action
	Union
		Select Distinct RequestSchema_Type As Type from Ens_ServiceRegistry_External.Action
	) Where Type is not Null
}

Query ListVerbs() As %SQLQuery [ Internal ]
{
	Select Distinct Verb As Verb from Ens_ServiceRegistry_External.Action Where Verb is not Null
}

Query ListProtocols() As %SQLQuery [ Internal ]
{
	Select Distinct %Exact(Protocol) As Protocol from Ens_ServiceRegistry_External.Service
}

Query ListDomains() As %SQLQuery [ Internal ]
{
	Select Distinct %Exact("Domain") As "Domain" from Ens_ServiceRegistry_External.Service
}

Query ListVersions() As %SQLQuery [ Internal ]
{
	Select Distinct %Exact(Version) As Version from Ens_ServiceRegistry_External.Service
}

Query ListAttributes() As %SQLQuery [ Internal ]
{
	Select Distinct Name from Ens_ServiceRegistry_External.Attribute
}

// ------------------------------------Get Proxy Objects------------------------------------------------------------

ClassMethod ListServices(Output tStreamString)
{
	Set tSQL = "select ID from ens_serviceregistry_external.service"
	Set tStmnt=##class(%SQL.Statement).%New()
	Set tSC = tStmnt.%Prepare(tSQL)
	If 'tSC Do $system.OBJ.DisplayError(tSC)
	Set tResult = tStmnt.%Execute()
	Set tFirst = 1
	While tResult.%Next() {
		Set tID = tResult.ID
		Set tPubService  = ##class(Ens.ServiceRegistry.External.Service).%OpenId(tID)
		Set tCopyService = tPubService.%ConstructClone()
		Set k = ""
		For  {
			Set tFile = tCopyService.Files.GetNext(.k) Quit:""=k
			Do tFile.Contents.Clear()
		}
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tJSONStream,tCopyService,"","",1,"twu")
		If 'tSC Do $system.OBJ.DisplayError(tSC)
		Set tStreamString($i(tStreamString)) = tJSONStream.Read()
	}
	Quit
}

ClassMethod GetServiceDetails(pID As %String, pShowEmpty As %Boolean = 0, Output pSvc) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pSvc = "", tFormat = "twu"_$S(pShowEmpty:"elo",1:"")
	If ..ExistsService($P(pID,"||"),$P(pID,"||",2),$P(pID,"||",3)) {
		Set tSvc = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pID)
		Set tClone = tSvc.%ConstructClone()
		Set k=""
		For  {
			Set tFile = tClone.Files.GetNext(.k) Quit:""=k
			Do tFile.Contents.Clear()
		}
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tJSONStream,tClone,"","",1,tFormat)
		While 'tJSONStream.AtEnd {
			Set pSvc = pSvc_tJSONStream.Read()
		}
	}
	Quit tSC
}

ClassMethod GetServiceProxy(pID As %String, Output pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ..ExistsService($P(pID,"||"),$P(pID,"||",2),$P(pID,"||",3)) {
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set tSvc = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pID)
		
		For tProp = "Name","Domain","Version","LastModified","Protocol","Stage","Endpoint","Description","ResponseStyle"
		{
			Set $Property(pProxy,tProp) = $Property(tSvc,tProp)
		}
	
		Set k = "", tTopicsList = ""
		For {
			Set tTopic = tSvc.Topics.GetNext(.k)  Quit:k=""
			Set tTopicsList = tTopicsList_","_tTopic
		}
		Set pProxy.Topics = $E(tTopicsList,2,*)
		
		Set tSchemaProxy = ##class(%ZEN.proxyObject).%New()

		For tProp = "Type","Ref","Notes","Thumbnail","Content" {
			Set $Property(tSchemaProxy,tProp) = $Select($IsObject(tSvc.Schema):$Property(tSvc.Schema,tProp),1:"")
		}
		Set pProxy.Schema = tSchemaProxy
		
		If $IsObject(tSvc.Contacts) {
			Set tProxyContacts = ##class(%Library.ListOfObjects).%New()
			Set k=""
			For {
				Set tContact = tSvc.Contacts.GetNext(.k) Quit:k=""
				Set tContactProxy = ##class(%ZEN.proxyObject).%New()
				For tProp = "Identity","Type","BusinessPartner" {
					Set $Property(tContactProxy,tProp) = $Property(tContact,tProp)
				}
				Set tSC=tProxyContacts.Insert(tContactProxy) Quit:$$$ISERR(tSC)
			}
			Quit:$$$ISERR(tSC) tSC
			Set pProxy.Contacts = tProxyContacts
		}
		
		If $IsObject(tSvc.Actions) {
			Set tProxyActions = ##class(%Library.ListOfObjects).%New()
			Set k=""
			For {
				Set tAction = tSvc.Actions.GetNext(.k) Quit:k=""
				Set tActionProxy = ##class(%ZEN.proxyObject).%New()
				For tProp = "Name","Ref","Verb"{
					Set $Property(tActionProxy,tProp) = $Property(tAction,tProp)
				}
				Set tSC=tProxyActions.Insert(tActionProxy) Quit:$$$ISERR(tSC)
			}
			Quit:$$$ISERR(tSC) tSC
			Set pProxy.Actions = tProxyActions
		}
		
		If $IsObject(tSvc.Files) {
			Set tProxyFiles = ##class(%Library.ListOfObjects).%New()
			Set k=""
			For {
				Set tFile = tSvc.Files.GetNext(.k) Quit:k=""
				Set tFileProxy = ##class(%ZEN.proxyObject).%New()
				For tProp = "Filename","MIMEType"{
					Set $Property(tFileProxy,tProp) = $Property(tFile,tProp)
				}
				Set tSC=tProxyFiles.Insert(tFileProxy) Quit:$$$ISERR(tSC)
			}
			Quit:$$$ISERR(tSC) tSC
			Set pProxy.Files = tProxyFiles
		}
		
		If $IsObject(tSvc.Attributes) {
			Set tProxyAttributes = ##class(%Library.ListOfObjects).%New()
			Set k=""
			For {
				Set tAttribute = tSvc.Attributes.GetNext(.k) Quit:k=""
				Set tAttributeProxy = ##class(%ZEN.proxyObject).%New()
				For tProp = "Name","Value"{
					Set $Property(tAttributeProxy,tProp) = $Property(tAttribute,tProp)
				}
				Set tSC=tProxyAttributes.Insert(tAttributeProxy) Quit:$$$ISERR(tSC)
			}
			Quit:$$$ISERR(tSC) tSC
			Set pProxy.Attributes = tProxyAttributes
		}
		
	} Else {
		Set pProxy = $$$NULLOREF
	}
	Quit tSC
}

ClassMethod GetActionProxy(pID As %String, pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ..ExistsAction(pID) {
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set tAction = ##class(Ens.ServiceRegistry.External.Action).%OpenId(pID)

		For tProp = "Name","Ref","Verb","Description","RequestSchema","ResponseSchema","ReadOnly","Idempotent" {
			Set $Property(pProxy,tProp) = $Property(tAction,tProp)
		}
		
		Set tRequestProxy = ##class(%ZEN.proxyObject).%New()
		For tProp = "Type","Ref","Content","Thumbnail","Notes" {
			Set $Property(tRequestProxy,tProp) = $Select($IsObject(tAction.RequestSchema):$Property(tAction.RequestSchema,tProp),1:"")
		}
		Set pProxy.RequestSchema = tRequestProxy
		
		Set tResponseProxy = ##class(%ZEN.proxyObject).%New()
		For tProp = "Type","Ref","Content","Thumbnail","Notes" {
			Set $Property(tResponseProxy,tProp) = $Select($IsObject(tAction.ResponseSchema):$Property(tAction.ResponseSchema,tProp),1:"")
		}
		Set pProxy.ResponseSchema = tResponseProxy
		
	} Else {
		Set pProxy = $$$NULLOREF
	}
	Quit tSC
}

ClassMethod GetContactProxy(pID As %String, pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ..ExistsContact(pID) {
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set tContact = ##class(Ens.ServiceRegistry.External.Contact).%OpenId(pID)

		For tProp = "Identity","Type","Details","BusinessPartner","Notes" {
			Set $Property(pProxy,tProp) = $Property(tContact,tProp)
		}
	} Else {
		Set pProxy = $$$NULLOREF
	}
	Quit tSC
}

ClassMethod GetAttributeProxy(pID As %String, pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ..ExistsAttribute(pID) {
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set tAttribute = ##class(Ens.ServiceRegistry.External.Attribute).%OpenId(pID)

		For tProp = "Name","Value" {
			Set $Property(pProxy,tProp) = $Property(tAttribute,tProp)
		}
	} Else {
		Set pProxy = $$$NULLOREF
	}
	Quit tSC
}

ClassMethod GetFileProxy(pID As %String, pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ..ExistsFile(pID) {
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set tFile = ##class(Ens.ServiceRegistry.External.FileStore).%OpenId(pID)

		For tProp = "Filename","MIMEType","CharEncoding","FileSize" {
			Set $Property(pProxy,tProp) = $Property(tFile,tProp)
		}
	} Else {
		Set pProxy = $$$NULLOREF
	}
	Quit tSC
}

// ---------------------------------Save Major Property or Service-----------------------------------------------------------

ClassMethod ImportFile(pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
		
	Quit:(pProxy.FilePath="")||('##class(%File).Exists(pProxy.FilePath)) $$$ERROR($$$EnsErrGeneral,"No file to import")
	Quit:(pProxy.Service="")||(pProxy.Name="") $$$ERROR($$$EnsErrGeneral,"Cannot import a file without an associated service and a name")
	
	Set tObject = ##class(Ens.ServiceRegistry.External.FileStore).%New()
	Set tObject.Filename = pProxy.Name
	Set tObject.MIMEType = pProxy.MIMEType
	Set tObject.CharEncoding = pProxy.CharSet
		
	Do tObject.ServiceSetObjectId(pProxy.Service)

	Set ext = $S(pProxy.FilePath [ "." : $P(pProxy.FilePath,".",*), 1:"")
	Do ##class(%CSP.StreamServer).FileClassify(ext,.type,.binary,.charset)
	
	
	If binary=1 {
		Set tObject.Contents = ##class(%Stream.GlobalBinary).%New()
		Set importFile = ##class(%Stream.FileBinary).%New()
	} Else {
		Set tObject.Contents = ##class(%Stream.GlobalCharacter).%New()
		Set importFile = ##class(%Stream.FileCharacter).%New()
	}
	
	Do tObject.Contents.Rewind()
	Set importFile.Filename = pProxy.FilePath
	Set tSC = tObject.Contents.CopyFromAndSave(importFile)
	Quit:$$$ISERR(tSC) tSC
	
	Set tObject.FileSize = $FNumber((importFile.Size/1024),",",2)_" KB"
		
	Quit tObject.%Save()
}

ClassMethod SaveContact(pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	 
	Quit:(pProxy.Service="")||(pProxy.Identity="") $$$ERROR($$$EnsErrGeneral,"Cannot save contact without an identity and service")
	Set tID = pProxy.Service_"||"_pProxy.Identity
	
	If ..ExistsContact(tID) {
		Set tContact = ##class(Ens.ServiceRegistry.External.Contact).%OpenId(tID)
	} Else {
		Set tContact = ##class(Ens.ServiceRegistry.External.Contact).%New()
		Set tContact.Identity = pProxy.Identity
		Do tContact.ServiceSetObjectId(pProxy.Service)
	}
	For tProp = "Type","Details","BusinessPartner","Notes" {
		Set $Property(tContact,tProp) = $Property(pProxy,tProp)
	}
	
	Quit tContact.%Save()
}

ClassMethod SaveAttribute(pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Quit:(pProxy.Service="")||(pProxy.Name="") $$$ERROR($$$EnsErrGeneral,"Cannot save attribute without a name and service")
	Set tID = pProxy.Service_"||"_pProxy.Name
	
	If ..ExistsAttribute(tID) {
		Set tAttr = ##class(Ens.ServiceRegistry.External.Attribute).%OpenId(tID)
	} Else {
		Set tAttr = ##class(Ens.ServiceRegistry.External.Attribute).%New()
		Set tAttr.Name = pProxy.Name
		Do tAttr.ServiceSetObjectId(pProxy.Service)
	}	
	Set tAttr.Value = pProxy.Value
			
	Quit tAttr.%Save()
}

ClassMethod SaveAction(pProxy As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Quit:(pProxy.Service="")||(pProxy.Name="") $$$ERROR($$$EnsErrGeneral,"Cannot save action without a name and service")
	Set tID = pProxy.Service_"||"_pProxy.Name
	
	If ..ExistsAction(tID) {
		Set tAction = ##class(Ens.ServiceRegistry.External.Action).%OpenId(tID)
	} Else {
		Set tAction = ##class(Ens.ServiceRegistry.External.Action).%New()
		Set tAction.Name = pProxy.Name
		Do tAction.ServiceSetObjectId(pProxy.Service)
	}
	
	For tProp = "Ref","Verb","Description","RequestSchema","ResponseSchema","ReadOnly","Idempotent" {
		Set $Property(tAction,tProp) = $Property(pProxy,tProp)
	}
	
	Set tRequestSchema = ##class(Ens.ServiceRegistry.Schema).%New()
	If $IsObject(pProxy.RequestSchema) {
		For tProp = "Type","Ref","Content","Thumbnail","Notes" {
			Set $Property(tRequestSchema,tProp) = $Property(pProxy.RequestSchema,tProp)
		}
	}
	Set tAction.RequestSchema = tRequestSchema
	
	Set tResponseSchema = ##class(Ens.ServiceRegistry.Schema).%New()
	If $IsObject(pProxy.ResponseSchema) {
		For tProp = "Type","Ref","Content","Thumbnail","Notes" {
			Set $Property(tResponseSchema,tProp) = $Property(pProxy.ResponseSchema,tProp)
		}
	}
	Set tAction.ResponseSchema = tResponseSchema
	
	Quit tAction.%Save()
}

ClassMethod SaveService(pProxy As %ZEN.proxyObject) As %Status
{
	Set tSC = $$$OK
		
	Quit:(pProxy.Name="")||(pProxy.Version="")||(pProxy.Domain="") $$$ERROR($$$EnsErrGeneral,"Missing name, version, or domain.  No service can be created without these properties.")
	If ..ExistsService(pProxy.Name,pProxy.Domain,pProxy.Version) {
		Set tSvc = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pProxy.Name_"||"_pProxy.Domain_"||"_pProxy.Version)
	} Else {
		Set tSvc = ##class(Ens.ServiceRegistry.External.Service).%New()
	}
		
	For tProp = "Name","Domain","Version","Protocol","Stage","Endpoint","Description","ResponseStyle"
	{
		Set $Property(tSvc,tProp) = $Property(pProxy,tProp)
	}
	Do tSvc.Topics.Clear()
	Set tTopics = $Property(pProxy,"Topics")
	For i=1:1:$l(tTopics,",") {
		Do tSvc.Topics.Insert($p(tTopics,",",i))
	}

	If $IsObject(tSvc.Schema) {
		Set tSchema = tSvc.Schema
	} Else {
		Set tSchema = ##class(Ens.ServiceRegistry.Schema).%New()
	}
	For tProp = "Type","Ref","Notes","Thumbnail","Content" {
		Set $Property(tSchema,tProp) = $Property(pProxy,"Schema."_tProp)
	}
	Set tSvc.Schema = tSchema
	Quit tSvc.%Save()
}

// ----------------------------- Extended Criteria ------------------------------------------

Query ExtendedCriteria(pCriteria, pExtendedCriteria, pDisplayList) As %Query(ROWSPEC = "ID:%String,Name:%String,Domain:%String,Version:%String,Protocol:%String,Stage:%String,Extra0:%String,Extra1:%String,Extra2:%String,Extra3:%String,Extra4:%String") [ Internal, SqlProc ]
{
}

ClassMethod ExtendedCriteriaExecute(ByRef qHandle As %Binary, pCriteria, pExtendedCriteria, pDisplayList) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set qHandle="", qHandle("display") = pDisplayList
	Set tRS = ..Search(pCriteria,pExtendedCriteria,.pStatus)
	Quit:$$$ISERR(pStatus) pStatus
	
	set tCount = 0
	While tRS.%Next(.tSC) {
		Quit:$$$ISERR(tSC)
		Set tCount = tCount+1
		Set qHandle("results",tCount)=$lb(tRS.%Get("ID"),tRS.%Get("Name"),tRS.%Get("Domain"),tRS.%Get("Version"),tRS.%Get("Protocol"),tRS.%Get("Stage"))
	}
	Quit tSC
}

ClassMethod ExtendedCriteriaFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ExtendedCriteriaExecute ]
{
	Set qHandle=$O(qHandle("results",qHandle))
	If ""=qHandle {
		Set Row="", AtEnd=1
	} Else {
		Set Row=qHandle("results",qHandle)
		Set displayList = qHandle("display")
		Set tSvcID = $lg(qHandle("results",qHandle),1)
		For i=1:1:$L(displayList,",") {
			Set tAttr = $p(displayList,",",i)
			&sql(Select Value into :tVal From Ens_ServiceRegistry_External.Attribute where Name = :tAttr and Service = :tSvcID)
			If 'SQLCODE {
				Set Row = Row_$lb(tVal)
			} Else {
				Set Row = Row_$lb("")
			}
		} For j=i:1:5 {
			Set Row = Row_$lb("")
		}
	}
	Quit $$$OK
}

ClassMethod ExtendedCriteriaClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ExtendedCriteriaFetch ]
{
	Kill qHandle
	Quit $$$OK
}

// -------------------------------------Search Registry----------------------------------------------------

ClassMethod Search(pSearchCriteria As %ZEN.proxyObject, pExtendedCriteria, pStatus As %Status = {$$$OK}) As %SQL.Statement [ Internal ]
{
	set tExtArr = "", k = ""
	For {
		Set tCriterion = pExtendedCriteria.GetNext(.k)  Quit:k="" 
		If '$IsObject(tCriterion)  Set tSC = $$$ERROR($$$EnsErrGeneral,"Problem retrieving extended criteria") Quit
		set i = ""
		For {
			Set tCondition = tCriterion.GetNext(.i)  Quit:i=""
			If '$IsObject(tCondition)  Set tSC = $$$ERROR($$$EnsErrGeneral,"Problem retrieving extended criteria conditions") Quit
			If i=1 {
				Set tExtArr(k) = tCondition.Type
			} Else {
				Set tExtArr(k,i) = tCondition.Type
				Set tExtArr(k,i,"attr") = tCondition.Attribute
				Set tExtArr(k,i,"op") = tCondition.Operator
				Set tExtArr(k,i,"val") = tCondition.Value
			}
		}
	}
	
	Kill tArray
	Do pSearchCriteria.%CopyToArray(.tArray)
	
	Set sub = "Protocols."
	For {
		Set sub = $O(tArray(sub)) Quit:$E(sub,1,10)'="Protocols."
		Set tArray("Protocols",$E(sub,11,*)) = tArray(sub)
		Kill tArray(sub)
	}
	Set sub = "Stages."
	For {
		Set sub = $O(tArray(sub)) Quit:$E(sub,1,7)'="Stages."
		Set tArray("Stages",$E(sub,8,*)) = tArray(sub)
		Kill tArray(sub)
	}

	Set tResult = ..PerformSearch(.tArray, .tExtArr, .pStatus)
	Quit tResult
}

/// Search the Registry for services which match the provided set of <var>pSearchCriteria</var> and <var>pExtendedCriteria</var>.  
/// Both sets of criteria will take the form of arrays. </br></br>
/// Allowed subscripts for <var>pSearchCriteria</var> are: <ul><li>'Version' as a single version</li><li>'WordMatch' as a string of text contained in a service's name domain description endpoint or topics list</li>
/// <li>'DomainMatch' which requires a precise match of Domain to the string value</li>
/// <li>'Protocols' which has subscripts 'File','FTP','HL7','HTTP','REST','SOAP','SQL','X12', and 'Other' as boolean values</li>
/// <li>'Stages' which has subscripts 'Concept','Defunct','Deprecated','Development','Live','Staging', and 'Test' as boolean values</li></ul>
/// Any extra subscripts will be ignored. </br></br>
/// The <var>pExtendedCriteria</var> array takes the following form:
/// <ul><li><var>pExtendedCriteria(Criterion)</var> = Type, where Criterion is a number and Type is either 'AND' or 'OR'</li>
/// <li><var>pExtendedCriteria(Criterion,Condition)</var> = Type, where Condition is a number and Type is 'IF','AND', or 'OR'.  The first condition in a criterion set should be of type 'IF'.</li>
/// <li><var>pExtendedCriteria(Criterion,Condition,"attr")</var> is the name of an attribute</li>
/// <li><var>pExtendedCriteria(Criterion,Condition,"op")</var> is the name of a comparison operation to be performed on the attribute.  Allowed operations are =,!=,>,<,>=,<=,CONTAINS,DOESNOTCONTAIN</li>
/// <li><var>pExtendedCriteria(Criterion,Condition,"val")</var> is the value which the attribute's value is being compared to.</li></ul> </br>
ClassMethod PerformSearch(ByRef pSearchCriteria, ByRef pExtendedCriteria, pStatus As %Status = {$$$OK}) As %SQL.Statement
{
	Set tSelect = "svc.ID,svc.Name,svc.""Domain"",svc.Version,svc.Protocol,svc.Stage"
		
	Set pStatus = ..GetExtendedWhereClause(.pExtendedCriteria,.tExtWhere)
	
	Set tTables = "Ens_ServiceRegistry_External.Service As svc"
	
	Set tStatement = "SELECT "_tSelect_" FROM "_tTables
		
	Set pStatus= ..GetWhereClause(.pSearchCriteria,.tWhere)
	
	Set:tExtWhere'="" tWhere = $S(tWhere'="":tWhere_" AND ", 1:"")_tExtWhere
	Set:tWhere'="" tStatement = tStatement_" WHERE "_tWhere
		
	Set tSort = $Case($G(pSearchCriteria("SortBy")),"":"svc.Name","Domain":"svc.""Domain""",:"svc."_pSearchCriteria("SortBy"))
	Set tOrder=" ORDER BY %SQLUPPER("_$Case(tSort,"Domain":"""Domain""",:tSort)_")"
	Set tDesc=$S($G(pSearchCriteria("Descending")):" DESC", 1:"")
	Set tStatement = tStatement_tOrder_tDesc
	
	Set tSQL=##class(%SQL.Statement).%New()
	Set tResult = ##class(%SQL.Statement).%ExecDirect(.tSQL,tStatement)
	If tResult.%SQLCODE&&(tResult.%SQLCode'=100) {
		Set pStatus = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("SQL error in search.  SQLCODE=%1 / %2"),tResult.%SQLCODE,tResult.%Message))
		Quit $$$NULLOREF
	}
	
	Quit tResult
}

/// Build the basic where clause
ClassMethod GetWhereClause(ByRef pSearchCriteria, Output pWhere As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK, pWhere=""
	
	Set tInList = "", tCount = 0
	Set tStage = ""
	For {
		Set tStage = $O(pSearchCriteria("Stages",tStage),1,tInclude) Quit:tStage=""
		If tInclude&&$Case(tStage,"Concept":1,"Defunct":1,"Deprecated":1,"Development":1,"Live":1,"Staging":1,"Test":1,:0) {
			Set tCount = tCount + 1
			Set tInList = tInList _ ",'"_tStage_"'"
		}
	}
	Set pWhere = $Case(tCount, 7: "", 0:"", 1: "svc.STAGE = "_$E(tInList,2,*), : "svc.STAGE IN ("_$E(tInList,2,*)_")")	

	Set tInList = "", tOutList="", tCount = 0	
	Set tOther = $G(pSearchCriteria("Protocols","Other"),0)
	Set tProtocol = ""
	For tProtocol = "File","FTP","HL7","HTTP","REST","SOAP","SQL","X12" {
		Set tListed = $Data(pSearchCriteria("Protocols",tProtocol),tInclude)
		If tListed && tInclude && 'tOther{
			Set tCount = tCount + 1
			Set tInList = tInList_",'"_tProtocol_"'"
		} Elseif ('tListed || 'tInclude) && tOther {
			Set tCount = tCount + 1
			Set tOutList = tOutList_",'"_tProtocol_"'"
		}
	}
	If 'tOther {
		Set:tCount pWhere = $S(pWhere'="":pWhere_" AND ", 1:"")_$Case(tCount, 1:"svc.PROTOCOL = "_$E(tInList,2,*),:"svc.PROTOCOL IN ("_$E(tInList,2,*)_")")
	} Elseif tCount {
		Set pWhere = $S(pWhere'="":pWhere_" AND (", 1:"(")_$Case(tCount, 1:"svc.PROTOCOL <> "_$E(tOutList,2,*),:"svc.PROTOCOL NOT IN ("_$E(tOutList,2,*)_")")_" OR svc.PROTOCOL IS NULL)"
	}
	
	Set tVersion = $G(pSearchCriteria("Version"))
	If tVersion'="All"&&(tVersion'="") {
		Set tVersion = ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tVersion)
		Set pWhere = $S(pWhere'="":pWhere_" AND ", 1:"")_"svc.VERSION = "_tVersion
	}
	
	Set tWordMatch = $G(pSearchCriteria("WordMatch"))
	If tWordMatch'="" {
		Set tWordMatch = ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tWordMatch)
		Set pWhere = $S(pWhere'="":pWhere_" AND (",1:"(")
		For tAttr = "Topics","Name","""Domain""","Description","Endpoint"{
			Set pWhere = pWhere_"%UPPER(svc."_tAttr_") [ "_$zcvt(tWordMatch,"U")_$Case(tAttr,"Endpoint":")",:" OR ")
		}
	}
		
	Set tDomainMatch = $G(pSearchCriteria("DomainMatch"))
	If tDomainMatch'="" {
		Set tDomainMatch = ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tDomainMatch)
		Set pWhere = $S(pWhere'="":pWhere_" AND (",1:"(")
		Set pWhere = pWhere_"svc.""Domain"" = "_tDomainMatch_")"
	}

	Quit tSC
}

/// Build the where clause for extended criteria.
ClassMethod GetExtendedWhereClause(ByRef pExtendedCriteria, Output pWhere As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tCriterion = "", count = 0, pWhere = ""
	For {
		Set tCriterion = $O(pExtendedCriteria(tCriterion),1,tType) Quit:tCriterion=""
		Set tCondition = "", tWhere = ""
		For {
			Set tCondition = $O(pExtendedCriteria(tCriterion,tCondition),1,tCType) Quit:tCondition=""
			Set tAttr = $G(pExtendedCriteria(tCriterion,tCondition,"attr"))
			Continue:""=tAttr
			Set tAttr = ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tAttr)
			
			Set tOperator = $G(pExtendedCriteria(tCriterion,tCondition,"op"),"=")
			Set tValue = $G(pExtendedCriteria(tCriterion,tCondition,"val"))
			Set:(tValue'="")&&(tValue'=+tValue) tValue = ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tValue)
			
			If tValue="" {
				If tOperator = "=" {
					Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name ="_tAttr_" AND attr.Value Is NULL)"
				} ElseIf tOperator = "!=" {
					Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name ="_tAttr_" AND attr.Value Is NOT NULL)"
				} Else {
					Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Operator %1 not valid for attribute value NULL."),tOperator))
				}
			}
			ElseIf $Case(tOperator,"=":1,">":1,">=":1,"<":1,"<=":1,:0)&&(tValue'=+tValue) {
				Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name ="_tAttr_" AND attr.Value "_tOperator_tValue_")"
			} ElseIf $Case(tOperator,"=":1,">":1,">=":1,"<":1,"<=":1,:0) {
				Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name ="_tAttr_" AND CAST(attr.Value AS NUMERIC) "_tOperator_tValue_")"
			}ElseIf tOperator="!=" {
				Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name ="_tAttr_" AND (attr.Value "_tOperator_tValue_" OR attr.Value Is NULL))" 
			} ElseIf $zcvt(tOperator,"U") = "CONTAINS" {
				Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name= "_tAttr_" AND %SQLUPPER(attr.Value) [ "_$zcvt(tValue,"U")_")"
			} ElseIf $zcvt(tOperator,"U") = "DOESNOTCONTAIN" {
				Set tExp = "EXISTS (Select ID FROM Ens_ServiceRegistry_External.Attribute as attr WHERE attr.Service = svc.ID AND attr.Name= "_tAttr_" AND NOT %SQLUPPER(attr.Value) [ "_$zcvt(tValue,"U")_")"
			} Else {
				Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Operator %1 not valid for extended criteria."),tOperator))
			}
			Quit:$$$ISERR(tSC)
							
			Set tWhere = tWhere _ $Case(tCType,"AND":" AND ","OR":" OR ", :"") _ tExp
		}
		Quit:$$$ISERR(tSC)
		If tWhere'="" {
			Set count = count + 1
			Set:count>1 pWhere=pWhere_$Case($zcvt(tType,"U"),"OR":" OR ",:" AND ")
			Set pWhere=pWhere_"( "_tWhere_" )"
		}
	}
	Set:pWhere'="" pWhere = " ( "_pWhere_" ) "
	Quit tSC
}

ClassMethod ParseServiceEndPoint(pExternalService As %String = "", ByRef pEndPointArray As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tService As Ens.ServiceRegistry.External.Service
	#dim tServiceAttribute As Ens.ServiceRegistry.External.Attribute
	
	#dim tURLProtocol,tServer,tPort,tURL As %String
	
	#dim tFTPProtocol,tPath As %String
	
	#dim tC As %Integer
	#dim tSetting, tTarget As %String
	
	#dim tServiceProtocol,tServiceEndpoint As %String
	
	Try {
		Set tService = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pExternalService,,.tSC)
		If $$$ISERR(tSC) Quit
		Set tServiceProtocol = tService.Protocol
		Set tServiceEndpoint = tService.Endpoint
		
		If (tServiceEndpoint'="") {
			If (tServiceProtocol="HL7")||(tServiceProtocol="X12") {
				If $ZCVT($E(tServiceEndpoint,1,4),"L")="tcp:" {
					Set tServiceProtocol = "TCP"
					Set tServiceEndpoint=$E(tServiceEndpoint,5,*)
				} ElseIf $ZCVT($E(tServiceEndpoint,1,3),"L")="ftp" {
					Set tServiceProtocol = "FTP"
				} ElseIf $ZCVT($E(tServiceEndpoint,1,4),"L")="http" {
					Set tServiceProtocol = "HTTP"
				} ElseIf $ZCVT($E(tServiceEndpoint,1,5),"L")="file:" {
					Set tServiceProtocol = "File"
					Set tServiceEndpoint=$E(tServiceEndpoint,6,*)
				}
			}
			If (tServiceProtocol = "HTTP")||(tServiceProtocol = "REST") {
				Set tSC = ..ParseHTTPEndPoint(tServiceEndpoint,.tURLProtocol,.tServer,.tPort,.tURL)
				If $$$ISERR(tSC) Quit
				Set pEndPointArray("Adapter","HTTPServer")=tServer
				Set pEndPointArray("Adapter","HTTPPort")=tPort
				Set pEndPointArray("Adapter","URL")=tURL
			} ElseIf (tServiceProtocol = "FTP") {
				Set tSC = ..ParseFTPEndPoint(tServiceEndpoint,.tFTPProtocol,.tServer,.tPort,.tPath)
				If $$$ISERR(tSC) Quit
				Set pEndPointArray("Adapter","FTPServer")=tServer
				Set pEndPointArray("Adapter","FTPPort")=tPort
				Set pEndPointArray("Adapter","FilePath")=tPath
				If (tFTPProtocol = "sftp") Set pEndPointArray("Adapter","Protocol")="SFTP"
			} ElseIf (tServiceProtocol = "SQL") {
				Set pEndPointArray("Adapter","DSN")=tServiceEndpoint
			} ElseIf (tServiceProtocol = "SOAP") {
				Set pEndPointArray("Adapter","WebServiceURL")=tServiceEndpoint
			} ElseIf (tServiceProtocol = "File") {
				Set pEndPointArray("Adapter","FilePath")=tServiceEndpoint
			} ElseIf (tServiceProtocol = "TCP") {
				Set tSC = ..ParseTCPEndPoint(tServiceEndpoint,.tServer,.tPort)
				If tServer'="" Set pEndPointArray("Adapter","IPAddress")=tServer
				If tPort'="" Set pEndPointArray("Adapter","Port")=tPort
			}
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	
	Quit tSC
}

/// pURLProtocol default to https if not specified.
ClassMethod ParseHTTPEndPoint(pEndPoint As %String = "", Output pURLProtocol As %String, Output pServer As %String, Output pPort As %Integer, Output pURL As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tAddr, tSvr As %String
	
	Try {
		Set pURLProtocol=$P(pEndPoint,"://",1), tAddr=$P(pEndPoint,"://",2)
		Set:""=tAddr tAddr=pURLProtocol, pURLProtocol=""
		
		If pURLProtocol = "" {Set pURLProtocol = "https"} Else {Set pURLProtocol = $ZCVT(pURLProtocol,"L")}
		Set tSvr=$P(tAddr,"/")
		Set pURL=$E(tAddr,$L(tSvr)+1,*)

		#; handle IPv4 notation and 2 sorts of IPv6 notation: [a:b:c]:port and a:b:c|port
		Set pPort=$P(tSvr,"|",2)  Set:""=pPort pPort=$P(tSvr,":",2,$L(tSvr,":"))  Set:pPort["]" pPort=""
		Set pServer=$E(tSvr,1,*-$S(""=pPort:0,1:$L(pPort)+1))
		If "["=$E(tSvr) {
			Set pServer=$E($P(tSvr,"]"),2,*)
		}
		If pPort ="" Set pPort=$S(pURLProtocol="http":80,1:443)
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// pURLProtocol default to ftp if not specified.
ClassMethod ParseFTPEndPoint(pEndPoint As %String = "", Output pFTPProtocol As %String, Output pServer As %String, Output pPort As %Integer, Output pPath As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tAddr, tSvr As %String
	
	Try {
		Set pFTPProtocol=$P(pEndPoint,"://",1), tAddr=$P(pEndPoint,"://",2)
		Set:""=tAddr tAddr=pFTPProtocol, pFTPProtocol=""
		
		If pFTPProtocol = "" {Set pFTPProtocol = "ftp"} Else {Set pFTPProtocol = $ZCVT(pFTPProtocol,"L")}
		Set tSvr=$P(tAddr,"/")
		Set pPath=$E(tAddr,$L(tSvr)+1,*)

		#; handle IPv4 notation and 2 sorts of IPv6 notation: [a:b:c]:port and a:b:c|port
		Set pPort=$P(tSvr,"|",2)  Set:""=pPort pPort=$P(tSvr,":",2,$L(tSvr,":"))  Set:pPort["]" pPort=""
		Set pServer=$E(tSvr,1,*-$S(""=pPort:0,1:$L(pPort)+1))
		If "["=$E(tSvr) {
			Set pServer=$E($P(tSvr,"]"),2,*)
		}
		If pPort ="" Set pPort=$S(pFTPProtocol="sftp":22,1:21)
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod ParseTCPEndPoint(pEndPoint As %String = "", Output pServer As %String, Output pPort As %Integer) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
		
	Try {
		#; handle IPv4 notation and 2 sorts of IPv6 notation: [a:b:c]:port and a:b:c|port
		Set pPort=$P(pEndPoint,"|",2)  Set:""=pPort pPort=$P(pEndPoint,":",2,$L(pEndPoint,":"))  Set:pPort["]" pPort=""
		Set pServer=$E(pEndPoint,1,*-$S(""=pPort:0,1:$L(pPort)+1))
		If "["=$E(pEndPoint) {
			Set pServer=$E($P(pEndPoint,"]"),2,*)
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	
	Quit tSC
}

}
