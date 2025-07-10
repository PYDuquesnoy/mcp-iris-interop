/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syLDAP, EnsLDAP)

/// This is an Ensemble operation that uses the EnsLib.LDAP.Adapter.Outbound
/// to make LDAP operation requests using the request classes: 
/// EnsLib.LDAP.Message.Add,
/// EnsLib.LDAP.Message.Compare,
/// EnsLib.LDAP.Message.Delete,
/// EnsLib.LDAP.Message.Modify,
/// EnsLib.LDAP.Message.Rename,
/// EnsLib.LDAP.Message.Search
Class EnsLib.LDAP.Operation.Standard Extends Ens.BusinessOperation [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.LDAP.Adapter.Outbound";

Property Adapter As EnsLib.LDAP.Adapter.Outbound;

Parameter INVOCATION = "Queue";

/// For LDAP Status errors that are not category Unavailable return $$$OK <br>
/// so that an LDAP status response is returned.<br>
Property ReturnLDAPErrorAsOK As %Boolean [ InitialExpression = 1 ];

/// If the object definition being searched does not exist in DIT do not treat as error.<br>
/// The default is to examine if set in the Search Message request and and if not use
/// this operation setting. The Default operation setting is not to treat as an error <br>
Property IgnoreSearchObjectNotInDIT As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "ReturnLDAPErrorAsOK:LDAP,IgnoreSearchObjectNotInDIT:LDAP";

/// Search LDAP Server using <CLASS>EnsLib.LDAP.Message.Search</CLASS> <br>
/// Results returned in <CLASS>EnsLib.LDAP.Message.Results</CLASS> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response is a <CLASS>EnsLib.LDAP.Message.Status</CLASS> <br>
Method ProcessSearch(pRequest As EnsLib.LDAP.Message.Search, Output pResultsResponse As EnsLib.LDAP.Message.Results) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK

	#dim tCountOfEntries As %Integer = 0

	Try {

			Set pResultsResponse = ##class(EnsLib.LDAP.Message.Results).%New()

			#dim tScope As %Integer
			If pRequest.Scope '= "" {

				Set tScope = pRequest.Scope

			} Else {

				Set tScope = $$$LDAPSCOPESUBTREE

			}

			#dim tAttributesAsList As %List = $LISTFROMSTRING(pRequest.AttributesToReturn)

			#dim tAttributesOnly As %Boolean =  pRequest.AttributesOnly

			#dim tSearchTimeout As %String
			If pRequest.SearchTimeout '= "" {

				Set tSearchTimeout = pRequest.SearchTimeout

			} Else {

				Set tSearchTimeout = ..Adapter.SearchTimeout

			}

			#dim tSearchBase As %String
			If pRequest.SearchBase '= "" {

				Set tSearchBase = pRequest.SearchBase

			} Else {

				Set tSearchBase = ..Adapter.BaseDN

			}

			#dim tAuthenticate As %Boolean = 1
			If pRequest.Authenticate '="" Set tAuthenticate = ''pRequest.Authenticate

			#dim tIgnoreObjectNotInDIT As %Boolean = ..IgnoreSearchObjectNotInDIT
			if pRequest.IgnoreObjectNotInDIT '="" Set tIgnoreObjectNotInDIT = ''pRequest.IgnoreObjectNotInDIT

			If $$$ISWINDOWS && (pRequest.PageSize '= "") {

				Set tSC = ..Adapter.SearchWithPages(
										tScope,
										pRequest.Filter,
										tAttributesAsList,
										tAttributesOnly,
										tSearchTimeout,
										pRequest.PageSize,
										tSearchBase,
										tAuthenticate
										)

			} Else {

				#dim tSizeLimit As %String
				If pRequest.SearchSizeLimit '= "" {

					Set tSizeLimit = pRequest.SearchSizeLimit

				} Else {

					Set tSizeLimit = ..Adapter.SearchSizeLimit

				}

				/* Perform search. Ignore Count of Entries */
				Set tSC = ..Adapter.Search(.tCountOfEntries,
									tScope,
									pRequest.Filter,
									tAttributesAsList,
									tAttributesOnly,
									tSearchTimeout,
									tSizeLimit,
									tSearchBase,
									1 /* Count Results */,
									tAuthenticate
									)
			}

			If $$$ISERR(tSC) {

				#; If object does not exist in DIT ignore and return empty results
				If tIgnoreObjectNotInDIT && (..Adapter.%LDAPSession.LastStatusCode = $$$LDAPNOSUCHOBJECT) {

					Set tSC = $$$OK

				} Else {

					Set pResultsResponse = ..CreateStatusResponse(.tSC)
				}

				Quit
			}

			If (..Adapter.%LDAPSession.%Page>0) || (tCountOfEntries > 0) {

				Set tSC1 = ..CreateSearchResultsResponse(.pResultsResponse,pRequest.BinaryAttributes)
				If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC1,tSC)

			}

			Set pResultsResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Method to construct response following Search. Called by ProcessSearch.
Method CreateSearchResultsResponse(ByRef pResultsResponse As EnsLib.LDAP.Message.Results, pListOfBinaryAttributes As %List = "") As %Status
{

	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK

	#dim tResults

	Try {

		Set tSC = ..Adapter.CreateResultsArray(.tResults,pListOfBinaryAttributes)

		If $$$ISERR(tSC) {
			#; tResults might now be an array of Status information but create a Status response from same LDAP Session.
			Set pResultsResponse = ..CreateStatusResponse(.tSC)
			Quit
		}

		#; Take results array and populate object
		#dim tAttributeNumber, tNumberOfAttributes As %Integer
		#dim tAttributeName As %String = ""

		#dim tAttributeNameValue As EnsLib.LDAP.Message.Attribute

		#dim tResultID
		#dim tResultNumber As %Integer  = 0

		Set tSC = pResultsResponse.%Save()
		If $$$ISERR(tSC) Quit

		#dim tResultsResponseID = pResultsResponse.%Id()

		For tResultNumber = 1:1:$Get(tResults,0) {

			Set tResult = ##class(EnsLib.LDAP.Message.Result).%New()
			Set tResult.DN = $Get(tResults(tResultNumber))

			Do tResult.ResultsSetObjectId(tResultsResponseID)

			Set tSC = tResult.%Save()
			If $$$ISERR(tSC) Quit
			Set tResultID = tResult.%Id()

			Set tAttributeName = $Order(tResults(tResultNumber,""),1,tNumberOfAttributes)

			While (tAttributeName'="") {

				For tAttributeNumber = 1:1:tNumberOfAttributes {

					Set tAttributeNameValue = ##class(EnsLib.LDAP.Message.Attribute).%New()
					Set tAttributeNameValue.Name = tAttributeName
					Set tAttributeNameValue.Value = $Get(tResults(tResultNumber,tAttributeName,tAttributeNumber))
					Do tAttributeNameValue.ResultSetObjectId(tResultID)
					Set tSC = tAttributeNameValue.%Save()
					If $$$ISERR(tSC) Quit

				}

				Set tAttributeName = $Order(tResults(tResultNumber,tAttributeName),1,tNumberOfAttributes)

			}

			If $$$ISERR(tSC) Quit

		}

		#; Delete any objects we saved before error and recreate response
		If $$$ISERR(tSC) {

			Set tSC1 = ##class(EnsLib.LDAP.Message.Results).%DeleteId(tResultsResponseID)
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC1,tSC)

			Set pResultsResponse = ..CreateStatusResponse(.tSC)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Add to an LDAP Server using <class>EnsLib.LDAP.Message.Add</class>.<br>
/// Status of call returned in <class>EnsLib.LDAP.Message.Status</class> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response  <CLASS>EnsLib.LDAP.Message.Status</CLASS>
/// contains the LDAP status information<br>
/// The Adapter setting BaseDN is used as the default when calculating the DN from the request<br>
Method ProcessAdd(pRequest As EnsLib.LDAP.Message.Add, Output pResponse As EnsLib.LDAP.Message.Status) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#;Identify calculated DN and Escape
		#dim tNewDNtoAdd = pRequest.CalculatedDN(..Adapter.BaseDN,1)

		If tNewDNtoAdd  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required RDN or DN for Add Entry needed")
			Quit
		}

		#dim tNumberOfAllAttributes As %Integer = 0
		#dim tAttributeArray
		#dim tArrayPosition As %Integer
		#dim tType, tProperty As %String

		For tType ="","Binary" {

			Set tProperty = tType_"Attributes"

			For tArrayPosition = 1:1:$method($property(pRequest,tProperty),"Count") {

				Set tNumberOfAllAttributes=tNumberOfAllAttributes+1
				Set tAttributeArray(tNumberOfAllAttributes) = $method($property(pRequest,tProperty),"GetAt",tArrayPosition)
				Set tAttributeArray(tNumberOfAllAttributes,"IsBinary") = (tType="Binary")

			}

		}

		Set tAttributeArray = tNumberOfAllAttributes

		Set tSC = ..Adapter.AddNewEntryParmArray(pRequest.objectClass, tNewDNtoAdd,"", .tAttributeArray)

		Set pResponse = ..CreateStatusResponse(.tSC)

		Set pResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Modify LDAP Server using <class>EnsLib.LDAP.Message.Modify</class>.<br>
/// Status of call returned in <class>EnsLib.LDAP.Message.Status</class> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response  <CLASS>EnsLib.LDAP.Message.Status</CLASS>
/// contains the LDAP status information<br>
/// The Adapter setting BaseDN is used as the default when calculating the DN from the request<br>
Method ProcessModify(pRequest As EnsLib.LDAP.Message.Modify, Output pResponse As EnsLib.LDAP.Message.Status) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#;Identify calculated DN and Escape
		#dim tNewDNtoModify = pRequest.CalculatedDN(..Adapter.BaseDN,1)

		If tNewDNtoModify  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required RDN or DN for Add Entry needed")
			Quit
		}

		#dim tNumberOfAllAttributes As %Integer = 0
		#dim tAttributeArray
		#dim tArrayPosition As %Integer
		#dim tOperation, tType, tProperty As %String

		For tOperation = "Add","Replace","Delete" {

			For tType ="","Binary" {

				Set tProperty = tOperation_tType_"Attributes"

				For tArrayPosition = 1:1:$method($property(pRequest,tProperty),"Count") {

					Set tNumberOfAllAttributes=tNumberOfAllAttributes+1
					Set tAttributeArray(tNumberOfAllAttributes) = $method($property(pRequest,tProperty),"GetAt",tArrayPosition)
					Set tAttributeArray(tNumberOfAllAttributes,tOperation)=1
					Set tAttributeArray(tNumberOfAllAttributes,"IsBinary")=(tType="Binary")

				}

			}

		}

		Set tAttributeArray = tNumberOfAllAttributes

		Set tSC = ..Adapter.ModifyEntryParmArray(tNewDNtoModify,"", .tAttributeArray)

		Set pResponse = ..CreateStatusResponse(.tSC)

		Set pResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Delete an entry from a LDAP Server using <class>EnsLib.LDAP.Message.Delete</class>.<br>
/// Status of call returned in <class>EnsLib.LDAP.Message.Status</class> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response  <CLASS>EnsLib.LDAP.Message.Status</CLASS>
/// contains the LDAP status information<br>
/// The Adapter setting BaseDN is used as the default when calculating the DN from the request<br>
Method ProcessDelete(pRequest As EnsLib.LDAP.Message.Delete, Output pResponse As EnsLib.LDAP.Message.Status) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#;Identify calculated DN and Escape
		#dim tDNtoDelete = pRequest.CalculatedDN(..Adapter.BaseDN,1)

		If tDNtoDelete  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required RDN or DN for Delete Entry needed")
			Quit
		}

		Set tSC=..Adapter.DeleteLDAPEntry(tDNtoDelete)

		Set pResponse = ..CreateStatusResponse(.tSC)

		Set pResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Compare an Attribute value on an LDAP Server using <class>EnsLib.LDAP.Message.Compare</class>.<br>
/// Comparison of call returned in <class>EnsLib.LDAP.Message.Comparison</class> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response  <CLASS>EnsLib.LDAP.Message.Status</CLASS>
/// contains the LDAP status information<br>
/// The Adapter setting BaseDN is used as the default when calculating the DN from the request<br>
Method ProcessCompare(pRequest As EnsLib.LDAP.Message.Compare, Output pResponse As EnsLib.LDAP.Message.Comparison) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#;Identify calculated DN and Escape
		#dim tDNtoCompare = pRequest.CalculatedDN(..Adapter.BaseDN,1)

		If tDNtoCompare  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required RDN or DN for Compare Entry needed")
			Quit
		}

		#dim tAttribute = pRequest.AttributeName
		#dim tValueToCompare = pRequest.AttributeValue

		#;We have already included Base
		#dim tBase As %String = ""
		#dim tValuesAreSame As %Boolean

		Set tSC=..Adapter.CompareLDAPEntryAttributeValue(tDNtoCompare,tBase,tAttribute,tValueToCompare,.tValuesAreSame,pRequest.AttributeIsBinary)

		If $$$ISOK(tSC) {

			Set pResponse =##class(EnsLib.LDAP.Message.Comparison).%New()
			Set pResponse.ComparesToServer =  tValuesAreSame
			Set pResponse.ComparisonTimeUTC = $zdatetime($ztimestamp,3,,3)

		} Else {

			Set pResponse = ..CreateStatusResponse(.tSC)

		}

		Set pResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Rename an Object on the LDAP Server using <CLASS>EnsLib.LDAP.Message.Rename</CLASS> <br>
/// If <property>MakeLDAPErrorOK</property> is True then the method returns $$$OK
/// on LDAP Status error and the response  <CLASS>EnsLib.LDAP.Message.Status</CLASS>
/// contains the LDAP status information<br>
/// The Adapter setting BaseDN is used as the default when calculating the DN from the request<br>
Method ProcessRename(pRequest As EnsLib.LDAP.Message.Rename, Output pResponse As EnsLib.LDAP.Message.Status) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#dim tDNtoRename As %String = pRequest.CalculatedDN(..Adapter.BaseDN,1)

		If tDNtoRename  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required RDN or DN for Rename/Move Entry needed")
			Quit
		}

		#; Already included base
		#dim tBase As %String = ""

		// RenameLDAPEntry
		Set tSC=..Adapter.RenameLDAPEntry(tDNtoRename, pRequest.NewRDN,pRequest.NewParent,pRequest.DeleteOldRDN,tBase)

		Set pResponse = ..CreateStatusResponse(.tSC)

		Set pResponse.Request = pRequest

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Helper method to create Status Response <br>
/// Uses <property>ReturnLDAPErrorAsOK</property> if Category is not Unavailable <br>
Method CreateStatusResponse(ByRef pStatus As %Status) As EnsLib.LDAP.Message.Status
{

	#dim tStatusArray
	#dim tResponse As EnsLib.LDAP.Message.Status

	Do ..Adapter.CreateStatusArray(pStatus, .tStatusArray)

	Set tResponse = ##class(EnsLib.LDAP.Message.Status).%New()

	Set tResponse.LastStatusCode = $Get(tStatusArray("LastStatusCode"))
	Set tResponse.LastStatusText = $Get(tStatusArray("LastStatusText"))
	Set tResponse.LastStatusCategory = $Get(tStatusArray("LastStatusCategory"))
	Set tResponse.LastCall = $Get(tStatusArray("LastCall"))
	Set tResponse.LastGeneratedStatus = $Get(tStatusArray("LastGeneratedStatus"))

	/*	If an LDAP Error and not an LDAP Unavailable error then
		allow the status response to be returned as a valid LDAP
	*/

	If $$$ISERR(pStatus) && ($$$StatusDisplayString(pStatus)["EnsLDAP") && ..ReturnLDAPErrorAsOK &&
			(..Adapter.%LDAPSession.LastStatusCategory'=$$$EnsLDAPStatusUnavailable) {

			Set pStatus = $$$OK
	}
	Quit tResponse
}

XData MessageMap
{
<MapItems>

  <MapItem MessageType="EnsLib.LDAP.Message.Search">
    <Method>ProcessSearch</Method>
  </MapItem>
  <MapItem MessageType="EnsLib.LDAP.Message.Add">
    <Method>ProcessAdd</Method>
  </MapItem>
  <MapItem MessageType="EnsLib.LDAP.Message.Modify">
    <Method>ProcessModify</Method>
  </MapItem>
  <MapItem MessageType="EnsLib.LDAP.Message.Delete">
    <Method>ProcessDelete</Method>
  </MapItem>
  <MapItem MessageType="EnsLib.LDAP.Message.Compare">
    <Method>ProcessCompare</Method>
  </MapItem>
  <MapItem MessageType="EnsLib.LDAP.Message.Rename">
    <Method>ProcessRename</Method>
  </MapItem>
</MapItems>
}

}
