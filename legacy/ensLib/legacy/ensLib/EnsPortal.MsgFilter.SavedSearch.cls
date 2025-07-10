/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class to implement Saved Searches in the Management Portal.
/// Its primary purpose is to provide a persistent wrapper around the
/// EnsPortal.MsgFilter.Filter object used to construct Message Viewer searches.
Class EnsPortal.MsgFilter.SavedSearch Extends (%Persistent, EnsPortal.MsgFilter.SavedSearchBase) [ System = 4 ]
{

Index Name On Name [ IdKey ];

/// Utility method to convert instances of CSPX.EnsMsgFilterForm to instances of EnsPortal.MsgFilter.SavedSearch.
/// The top node of <var>pConverted</var> reports the number of searches which were converted, and the names of
/// the converted searches are inserted as subscripts of the array.
/// <var>pNotConverted</var> reports the number of searches which were not converted in the same format as 
/// <var>pConverted</var>, but also indicates whether it was skipped (-1) or encountered an error, as per the 
/// <var>pAction</var> parameter returned from <method>ConvertCSPXSearch</method>().
/// <var>pVerbose</var> indicates whether output should be logged to the current device. If <var>pVerbose</var>
/// is greater than 1, the output will be indented <var>pVerbose</var> characters. (This is primarily for use by
/// the InterSystems IRIS installation code.)
ClassMethod ConvertAllCSPXSearches(Output pConverted As %Integer, Output pNotConverted As %Integer, pVerbose As %Integer = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		#Def1arg Log(%text)	If pVerbose Write !?$select(pVerbose>1: pVerbose, 1: 0),%text
		Kill pConverted,pNotConverted
		Set pConverted = 0
		Set pNotConverted = 0
		Set tDoSummary = 1
		
		If '$data(^CSPX.EnsMsgFilterFormD) {
			$$$Log("- No saved message searches found in namespace '",$namespace,"'; no conversion necessary.")
			Set tDoSummary = 0
			Quit
		}
		Set tSkipped = 0
		
		Set tVerbose = $select(pVerbose > 1: pVerbose + 2, 1: pVerbose)
		$$$Log("- Starting conversion for saved message searches in namespace '",$namespace,"' at ",$zdt($zts,3,,3))
		Set tName = ""
		For {
			Set tName = $order(^CSPX.EnsMsgFilterFormD(tName))
			Quit:(tName = "")
			Set tStatus1 = ..ConvertCSPXSearch(tName,.tAction,tVerbose)
			If $$$ISOK(tStatus1) && (tAction = 1) {
				Set pConverted = pConverted + 1
				Set pConverted(tName) = ""
			}
			Else {
				Set pNotConverted = pNotConverted + 1
				Set pNotConverted(tName) = tAction
				If (tAction = -1) {
					Set tSkipped = tSkipped + 1
				}
				If $$$ISERR(tStatus1) {
					Set tStatus = $$$ADDSC(tStatus, tStatus1)
				}
			}
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If tDoSummary {
		$$$Log("- Conversion summary:")
		$$$Log("    ",pConverted," saved message searches were converted successfully")
		$$$Log("    ",tSkipped," saved message searches were skipped due to matching searches already existing")
		$$$Log("    ",pNotConverted-tSkipped," saved message searches were skipped due to errors")
		If $$$ISERR(tStatus) $$$Log(" == Error text: ",$system.Status.GetErrorText(tStatus))
		$$$Log("-  Saved message search conversion completed in namespace '",$namespace,"' at ",$zdt($zts,3,,3))
	}
	ElseIf $$$ISERR(tStatus) {
		$$$Log("- Error during conversion: ",$system.Status.GetErrorText(tStatus))
	}
	Quit tStatus
}

/// Method to convert an instance of CSPX.EnsMsgFilterForm (as saved in the old Management Portal),
/// into an instance of EnsPortal.MsgFilter.SavedSearch, as used in the new Management Portal.
/// <var>pSearchName</var> - Name of CSPX.EnsMsgFilterForm instance to convert
/// <var>pAction</var> returns 1 if successful, -1 if the named search already exists and 0 if there was some other error.
/// <var>pVerbose</var> controls whether output is written to the current device. If larger than 1, the value will be used to indent the output.
ClassMethod ConvertCSPXSearch(pSearchName As %String, Output pAction As %Integer, pVerbose As %Integer = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		#Def1arg Log(%text)	If pVerbose Write !?$select(pVerbose>1: pVerbose, 1: 0),%text
		Kill pAction
		Set pAction = 0
		Set tSearchData = ""
		If '$data(^CSPX.EnsMsgFilterFormD(pSearchName),tSearchData)#10 {
			Set tStatus = $$$ERROR($$$LoadObjectNotFound,"CSPX.EnsMsgFilterForm",pSearchName)
			Quit
		}
		
		If ..%ExistsId(pSearchName){
			Set pAction = -1
			$$$Log("+ SavedSearch '",pSearchName,"' already exists! Skipping conversion...")
		}
		Else {
			Set tNewSearch = ..%New()
			Set tNewSearch.Name = pSearchName
			
			Set tNewSearch.Filter.ColorBy = $lg(tSearchData,3)
			Set tNewSearch.Filter.EndId = $lg(tSearchData,4)
			Set tNewSearch.Filter.EndTime = $lg(tSearchData,5)
			Set tNewSearch.Filter.IsError = $lg(tSearchData,6)
			Set tNewSearch.Filter.MaxRows = $lg(tSearchData,7)
			Set tNewSearch.Filter.SortOrder = $lg(tSearchData,8)
			Set tNewSearch.Filter.Source = $lg(tSearchData,9)
			Set tNewSearch.Filter.StartId = $lg(tSearchData,10)
			Set tNewSearch.Filter.StartTime = $lg(tSearchData,11)
			Set tNewSearch.Filter.Status = $lg(tSearchData,12)
			Set tNewSearch.Filter.TimeFormat = $lg(tSearchData,14)
			Set tNewSearch.Filter.Type = $lg(tSearchData,15)
			
			Set tTerms = $lg(tSearchData,16)
			For i=1:1:$listlength(tTerms) {
				Set tCurrTerm = $listget(tTerms,i)
				If tCurrTerm = "" Continue
				If $listlength(tCurrTerm) = 1 {
					Set tCurrTerm = $listget(tCurrTerm)
					If tCurrTerm = "" Continue
				}
				Set tNewTerm = ##class(EnsPortal.MsgFilter.Term).%New()
				Set tNewTerm.SourceClass = $listget(tCurrTerm,3)
				Set tNewTerm.Disabled = $listget(tCurrTerm,2)
				Set tOldType = $listget(tCurrTerm,4)
				If (tOldType = "OR") {
					Set tNewTerm.Type = "OR"
				}
				ElseIf tOldType [ "Header" {
					Set tNewTerm.Type = "Header"
					If tNewTerm.SourceClass = "" { Set tNewTerm.SourceClass = "Ens.MessageHeader" }
				}
				ElseIf tOldType [ "SearchTable" {
					Set tNewTerm.Type = "SearchTable"
				}
				ElseIf tOldType [ "Body" {
					Set tNewTerm.Type = "Body"
					// Don't copy empty body terms
					If $listget(tCurrTerm,3) = "" Continue
				}
				ElseIf tOldType [ "VDoc" {
					Set tNewTerm.Type = "VDoc"_$select(tOldType [ "Segment": "Segment", 1: "Path")
				}
				Set tConditions = $listget(tCurrTerm,1)
				For j=1:1:$listlength(tConditions) {
					Set tCurrCond = $listget(tConditions,j)
					If tCurrCond = "" Continue
					If $listlength(tCurrCond) = 1 {
						Set tCurrCond = $listget(tCurrCond)
						If tCurrCond = "" Continue
					}
					Set tNewCond = ##class(EnsPortal.MsgFilter.Condition).%New()
					Set tNewCond.JoinOp = $listget(tCurrCond,1)
					Set tNewCond.Op = $listget(tCurrCond,2)
					Set tNewCond.OpVal = $listget(tCurrCond,3)
					Set tNewCond.Prop = $listget(tCurrCond,4)
					Set tInsStatus = tNewTerm.Conditions.Insert(tNewCond)
					If $$$ISERR(tInsStatus) {
						Set tStatus = $$$ADDSC(tStatus, tInsStatus)
					}
				}
				Set tInsStatus = tNewSearch.Filter.Terms.Insert(tNewTerm)
				If $$$ISERR(tInsStatus) {
					Set tStatus = $$$ADDSC(tStatus, tInsStatus)
				}
			}
			If $$$ISERR(tStatus) Quit
			Set tStatus = tNewSearch.%Save()
			If $$$ISERR(tStatus) Quit
			Set pAction = 1
			$$$Log("+ Saved Search '",pSearchName,"' successfully converted.")
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		$$$Log("+ Error converting Search '",$get(pSearchName),"': ",$system.Status.GetErrorText(tStatus))
	}
	Quit tStatus
}

/// Callback to update %TimeModified and %ModifiedBy.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set i%%TimeModified = $$$timeUTC
	Set i%%ModifiedBy = $username
	Quit $$$OK
}

/// Update %TimeModified and %ModifiedBy for SQL modifications.
Trigger OnUpdate [ Event = INSERT/UPDATE ]
{
	Set {%TimeModified*N} = $$$timeUTC
	Set {%ModifiedBy*N} = $username
}

/// Returns a set of IDs not including temporary ones
Query ListPermanent() As %SQLQuery
{
	SELECT %ID
	FROM SavedSearch
 	WHERE (%ID NOT LIKE 'z_QueuedForExport_%')
	ORDER BY %ID ASC
}

Storage Default
{
<Data name="SavedSearchDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Filter</Value>
</Value>
<Value name="3">
<Value>%CreatedBy</Value>
</Value>
<Value name="4">
<Value>%TimeCreated</Value>
</Value>
<Value name="5">
<Value>%TimeModified</Value>
</Value>
<Value name="6">
<Value>%ModifiedBy</Value>
</Value>
</Data>
<DataLocation>^EnsPortal.SavedSearchD</DataLocation>
<DefaultData>SavedSearchDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^EnsPortal.SavedSearchD</IdLocation>
<IndexLocation>^EnsPortal.SavedSearchI</IndexLocation>
<StreamLocation>^EnsPortal.SavedSearchS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
