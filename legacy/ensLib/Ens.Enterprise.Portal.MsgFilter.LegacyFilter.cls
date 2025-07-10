/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Helper class to allow Enterprise Message Search to serialise and deserialize XML to and from systems
/// using CSPX.EnsMsgFilterForm to drive message searches.
Class Ens.Enterprise.Portal.MsgFilter.LegacyFilter Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLNAME = "MsgFilter";

Property Name As %String(MAXLEN = 128, XMLPROJECTION = "attribute") [ Required ];

Property Description As %String(MAXLEN = 2000, XMLNAME = "description", XMLPROJECTION = "element");

/// Set of detailed condition terms in the MsgFilter.
Property Terms As list Of EnsPortal.MsgFilter.Term(XMLNAME = "Term", XMLPROJECTION = "element");

/// Serialized set of detailed condition terms from the filter info pane
Property TermsStr As %String(MAXLEN = "") [ Transient ];

/// Timeout to quit doing PostRS checks from within queries
Property Timeout As %Numeric;

/// Runtime mode to use (controls use of Logical/ODBC/Display values)
Property RuntimeMode As %String [ InitialExpression = 2 ];

/// Message types
Property Type As %String(DISPLAYLIST = ",Session Start,Request,Response,All", VALUELIST = ",0,1,2,3") [ InitialExpression = 0 ];

/// How to sort data
Property SortOrder As %String(DISPLAYLIST = ",Oldest First,Newest First", VALUELIST = ",1,2") [ InitialExpression = 2 ];

/// Number of rows to display
Property MaxRows As %Integer(MINVAL = 1);

/// Time format
Property TimeFormat As %String(DISPLAYLIST = ",Time Only,Complete", VALUELIST = ",12,999") [ InitialExpression = 999 ];

/// Column to color results by
Property ColorBy As %String(VALUELIST = ",TimeCreated,SessionId,Status,Error,Source");

/// Errors
Property IsError As %String(DISPLAYLIST = ",false,true", VALUELIST = ",0,1");

/// Starting date
Property StartTime As %String;

/// Starting ID value
Property StartId As %Integer;

/// Message status
Property Status As Ens.DataType.MessageStatus;

/// End date
Property EndTime As %String;

/// End ID value
Property EndId As %Integer;

/// Source
Property Source As %String(MAXLEN = 128);

Method ConvertToNewFilter(Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set tStatus = $$$OK
	Kill pFilter
	Set pFilter = ##class(EnsPortal.MsgFilter.Filter).%New()
	For prop = "EndId","EndTime","MaxRows","SortOrder","Source","StartId","StartTime","Status","TimeFormat","Timeout","Type" {
		Set $property(pFilter,prop) = $property($this,prop)
	}
	Set pFilter.IsError = $select(..IsError = "": "", 1: ''..IsError)
	For i=1:1:..Terms.Count() {
		#dim tTerm As EnsPortal.MsgFilter.Term
		Set tTerm = ..Terms.GetAt(i)
		If '$IsObject(tTerm) Continue
		Set tNewTerm = ##class(EnsPortal.MsgFilter.Term).%New()
		Set tNewTerm.SourceClass = tTerm.SourceClass
		Set tNewTerm.Disabled = tTerm.Disabled
		If tTerm.Type = "OR" {
			Set tNewTerm.Type = "OR"
		}
		ElseIf tTerm.Type [ "Header" {
			Set tNewTerm.Type = "Header"
			If tNewTerm.SourceClass = "" { Set tNewTerm.SourceClass = "Ens.MessageHeader" }
		}
		ElseIf tTerm.Type [ "SearchTable" {
			Set tNewTerm.Type = "SearchTable"
		}
		ElseIf tTerm.Type [ "Body" {
			Set tNewTerm.Type = "Body"
			// Don't copy empty body terms
			If tTerm.SourceClass = "" Continue
		}
		ElseIf tTerm.Type [ "VDoc" {
			Set tNewTerm.Type = "VDoc"_$select(tTerm.Type [ "Segment": "Segment", 1: "Path")
		}
		Set tNewTerm.Conditions = tTerm.Conditions.%ConstructClone(1)
		
		Set tInsStatus = pFilter.Terms.Insert(tNewTerm)
		If $$$ISERR(tInsStatus) {
			Set tStatus = $$$ADDSC(tStatus, tInsStatus)
		}
	}
	Quit tStatus
}

ClassMethod CreateFromNewFilter(pFilter As EnsPortal.MsgFilter.Filter, Output pLegacyFilter As Ens.Enterprise.Portal.MsgFilter.LegacyFilter) As %Status
{
	Set tStatus = $$$OK
	Kill pLegacyFilter
	Set pLegacyFilter = ..%New()
	For prop = "EndId","EndTime","MaxRows","SortOrder","Source","StartId","StartTime","Status","TimeFormat","Timeout","Type","IsError" {
		Set $property(pLegacyFilter,prop) = $property(pFilter,prop)
	}
	Set pLegacyFilter.RuntimeMode = 2
	For i=1:1:pFilter.Terms.Count() {
		#dim tTerm As EnsPortal.MsgFilter.Term
		Set tTerm = pFilter.Terms.GetAt(i)
		If '$IsObject(tTerm) Continue
		Set tLegacyTerm = ##class(EnsPortal.MsgFilter.Term).%New()
		Set tLegacyTerm.Disabled = tTerm.Disabled
		Set tLegacyTerm.SourceClass = tTerm.SourceClass
		If tTerm.Type = "Header" {
			Set tLegacyTerm.SourceClass = ""
		}
		
		Set tLegacyTerm.Type = $case(tTerm.Type,
				"OR": "OR",
				"Header": "Header Field",
				"SearchTable": "VDoc SearchTable Field",
				"Body": "Body Property",
				"VDocSegment": "VDoc Segment Field",
				"VDocPath": "VDoc Property Path")
		
		Set tLegacyTerm.Conditions = tTerm.Conditions.%ConstructClone(1)
		
		Set tInsStatus = pLegacyFilter.Terms.Insert(tLegacyTerm)
		If $$$ISERR(tInsStatus) {
			Set tStatus = $$$ADDSC(tStatus, tInsStatus)
		}
	}
	Quit tStatus
}

}
