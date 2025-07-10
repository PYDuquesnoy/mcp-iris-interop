/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Base class used to generate results for the various message viewer UI pages in the portal.
/// Users can override this class to provide custom code to parse and process conditions created in the UI pages.
/// It is more likely that users will wish to override one of the subclasses of this class (specifically
/// <class>EnsPortal.MsgFilter.Assistant</class> or <class>Ens.Enterprise.Portal.MsgFilter.Assistant</class>)
/// which are capable of parsing the incoming conditions and producing SQL queries. In addition, these subclasses
/// provide callbacks which allow users to manipulate the generated SQL in useful ways without major development effort.
/// Note: InterSystems is not responsible for user extensions to these classes.
Class EnsPortal.MsgFilter.AbstractAssistant Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Name of <class>Filter</class> to use for searches.
Parameter FilterClass = "EnsPortal.MsgFilter.Filter";

/// Subscript under temporary session data to use for storing the search history for the viewer.
/// The storage is activated by setting the <code>^Ens.Debug("UtilEnsMessages","sql")</code> debug node to a positive number.
Parameter SESSIONSUBSCRIPT As STRING;

/// The maximum number of queries to store when the session query history is being stored.
Parameter QUERYHISTORY As INTEGER = 5;

/// Callback to create the <class>Filter</class> class for this Assistant.
/// Note that the supplied proxyObject may contain information related to paging
/// which is not a part of the filter object model.
ClassMethod CreateFilter(pSearchCriteria As %ZEN.proxyObject, Output pFilter As EnsPortal.MsgFilter.Filter, pExcludeSequenceManager As %Boolean = 1, pVirtualKey As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = $classmethod(..#FilterClass,"LoadFromVirtualSession",pVirtualKey,.pFilter)
		If $$$ISERR(tStatus) Quit
		If pExcludeSequenceManager {
			// SequenceManagerSearch must NOT be used from saved data; it can't be unselected in UI.
			Set pFilter.SequenceManagerSearch = ""
		}

		For tProp="Type","SortOrder","MaxRows","TimeFormat","IsError","StartTime","StartId","Status","EndTime","EndId","Source","Target","Timeout","SequenceManagerSearch" {
			Set $property(pFilter, tProp) = $property(pSearchCriteria, tProp)
		}
		If pFilter.MaxRows="" {
			Set pFilter.MaxRows = pSearchCriteria.pageSize
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Set pFilter = ""
	}
	Quit tStatus
}

/// Callback to create a Zen proxyObject from a supplied <class>Filter</class>.
/// By default, sequence manager searches are excluded.
ClassMethod CreateProxy(pFilter As EnsPortal.MsgFilter.Filter, Output pSearchCriteria As %ZEN.proxyObject, pExcludeSequenceManager As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pSearchCriteria
		Set pSearchCriteria = ##class(%ZEN.proxyObject).%New()

		For tProp="Type","SortOrder","MaxRows","TimeFormat","IsError","StartTime","StartId","Status","EndTime","EndId","Source","Target","Timeout" {
			Set $property(pSearchCriteria, tProp) = $property(pFilter, tProp)
		}
		If 'pExcludeSequenceManager {
			Set pSearchCriteria.SequenceManagerSearch = pFilter.SequenceManagerSearch
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Set pSearchCriteria = "" 
	}
	Quit tStatus
}

/// Helper method to return a valid ResultSet for the supplied <class>Filter</class> object.
/// Subclasses must implement this method.
ClassMethod GetResultSet(pFilter As EnsPortal.MsgFilter.Filter, Output pResultSet As %ResultSet, pExecute As %Boolean = 1) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

ClassMethod CheckFilter(pFilter As EnsPortal.MsgFilter.Filter, Output pWarnings As %Library.ListOfDataTypes) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set pWarnings = ""
		Set tTermCount = pFilter.Terms.Count()
		For i=1:1:tTermCount {
			Set tTerm = pFilter.Terms.GetAt(i)
			If tTerm.Type = "SearchTable" {
				Set tIsCustomST = 0
				Try { Set tIsCustomST = $classmethod(tTerm.SourceClass,"%Extends","Ens.CustomSearchTable") }
				Catch {}
				If tIsCustomST {
					Set tCustomST(tTerm.SourceClass) = ""
				}
			}
		}
		If $data(tCustomST) {
			Set tWarnings = ##class(%Library.ListOfDataTypes).%New()
			Set tST = ""
			For {
				Set tST = $order(tCustomST(tST))
				Quit:(tST = "")
				Set tTmpWarnings = ##class(%Library.ListOfDataTypes).%New()
				Set tStatus = $classmethod(tST,"CheckFilter",pFilter,tTmpWarnings)
				If $$$ISERR(tStatus) Quit
				For i=1:1:tTmpWarnings.Count() { Do tWarnings.Insert(tTmpWarnings.GetAt(i)) }
			}
			If $$$ISERR(tStatus) Quit
			If tWarnings.Count() Set pWarnings = tWarnings
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// API to log data about queries in the current session context if viewer debugging is enabled via the
/// <code>^Ens.Debug("UtilEnsMessages","sql")</code> debug global.
/// The data for the current session can be retrieved via the <method>GetQueryHistory</method>() API.
/// Note that <method>UpdateQuery</method>() is also used to provide further runtime statistics for queries.
ClassMethod LogQuery(pQueryText As %String = "", Output pCounter As %Integer) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set pCounter = 0
		If (..#SESSIONSUBSCRIPT '= "") && (pQueryText '= "") && $IsObject($get(%session)) && $get(^Ens.Debug("UtilEnsMessages","sql")) {
			Do ##class(EnsPortal.SessionEvents).Initialize()
			Set pCounter = $increment(^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT))
			Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,pCounter) = $lb(pQueryText,$lb($now(0),"",""),$lb($zutil(67,9,$job),"",""))
			If (pCounter > ..#QUERYHISTORY) {
				#; Remove older queries
				Set tKey = ""
				For {
					Set tKey = $order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,tKey))
					Quit:(tKey = "")||(tKey > (pCounter - ..#QUERYHISTORY))
					Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,tKey)
				}
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// API to update the statistics for a previously logged query referenced by <var>pCounter</var>.
/// <var>pType</var> must currently be either <code>"execute"</code> or <code>"close"</code> for the 
/// query statistics to be updated.
ClassMethod UpdateQuery(pCounter As %Integer = 0, pType As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		If (..#SESSIONSUBSCRIPT '= "") && $IsObject($get(%session)) && pCounter && $data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,pCounter),tData)#2 && $listvalid(tData) {
			Set tListPos = $case(pType, "close": 3, "execute": 2, : 0)
			If tListPos {
				Set tTimes = $listget(tData,2)
				Set $list(tTimes,tListPos) = $now(0)
				Set $list(tData,2) = tTimes
				Set tRefs = $listget(tData,3)
				Set $list(tRefs,tListPos) = $zutil(67,9,$job)
				Set $list(tData,3) = tRefs
				Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,pCounter) = tData
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// API to retrieve the logged query data for the current session.
/// <var>pHistory</var> has the following structure: <br/>
/// <code>pHistory(n) = $listbuild([time_logged],[query_text],[time_to_execute],[time_to_close],[grefs_to_execute],[grefs_to_close])</code>
ClassMethod GetQueryHistory(Output pHistory, pMaxResults As %Integer = -1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pHistory
		Set pHistory = 0
		If (..#SESSIONSUBSCRIPT '= "") && $IsObject($get(%session)) {
			Set tMaxResults = $select(pMaxResults > -1: pMaxResults, 1: +$order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,""),-1))
			Set tKey = ""
			For {
				If (pHistory >= tMaxResults) Quit
				Set tKey = $order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,..#SESSIONSUBSCRIPT,tKey),-1,tData)
				If (tKey = "") Quit
				
				Set pHistory = pHistory + 1
				Set tTimes = $listget(tData,2)
				Set tRefs = $listget(tData,3)
				Set tLogTimeH = $listget(tTimes,1)
				Set tLogRefs = $listget(tRefs,1)
				Set tLogSec = +$piece(tLogTimeH,",",2)
				Set tLogTime = $$$timeUTCtoLocal($$$timeUTCHtoUTC(tLogTimeH))
				Set tExecuteTimeH = $listget(tTimes,2)
				Set tExecuteSec = +$piece(tExecuteTimeH,",",2)
				Set tExecuteTime = $select(tExecuteTimeH = "": "", 1: $zabs(tExecuteSec - tLogSec))
				Set tExecuteRefs = $listget(tRefs,2)
				Set tExecuteRefs = $select(tExecuteRefs = "": "", 1: tExecuteRefs - tLogRefs)
				Set tCloseTimeH = $listget(tTimes,3)
				Set tCloseSec = +$piece(tCloseTimeH,",",2)
				Set tCloseTime = $select(tCloseTimeH = "": "", 1: $zabs(tCloseSec - tExecuteSec))
				Set tCloseRefs = $listget(tRefs,3)
				Set tCloseRefs = $select(tCloseRefs = "": "", 1: tCloseRefs - (tExecuteRefs + tLogRefs))
				Set pHistory(pHistory) = $lb(tLogTime,$listget(tData,1),tExecuteTime,tCloseTime,tExecuteRefs,tCloseRefs)
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

}
