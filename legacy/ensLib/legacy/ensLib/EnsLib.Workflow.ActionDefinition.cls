/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines the set of available actions that a user can make within a Workflow application.
/// Users can  extend this list.
Class EnsLib.Workflow.ActionDefinition Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Index ID On Name [ IdKey ];

/// Identifying name used for this action. This must be a unique value.
Property Name As %String(MAXLEN = 50);

/// Used to display the button caption for this action within the workflow application.
Property Caption As %String(MAXLEN = 100);

/// Used to display popup help for this action within the workflow application.
Property Title As %String(MAXLEN = 100);

/// If defined, this action prompts the user before performing the action.
Property Prompt As %String(MAXLEN = 100);

/// Create the set of default Workflow actions
/// This will clear out the existing actions
ClassMethod CreateDefaultActions(pForce As %Boolean = 0) As %Status
{
	Set tSC = $$$OK

	Do {
		If ('pForce) {
			// see if actions are defined
			If (..%ExistsId("Approve")) {
				Quit
			}
		}

		Set tSC = ..%KillExtent()
		If $$$ISERR(tSC) Quit
		
		Set tAction = ..%New()
		Set tAction.Name = "Approve"
		Set tAction.Caption = $$$Text("Approve","Ensemble")
		Set tAction.Title = $$$Text("Approve this item","Ensemble")
		Set tAction.Prompt = $$$Text("Do you wish to approve this item?","Ensemble")
		Set tSC = tAction.%Save()
		If $$$ISERR(tSC) Quit

		Set tAction = ..%New()
		Set tAction.Name = "Reject"
		Set tAction.Caption = $$$Text("Reject","Ensemble")
		Set tAction.Title = $$$Text("Reject this item","Ensemble")
		Set tAction.Prompt = $$$Text("Do you wish to reject this item?","Ensemble")
		Set tSC = tAction.%Save()
		If $$$ISERR(tSC) Quit

	} While (0)
	
	Quit tSC
}

/// Return a list of available Workflow actions.
Query ActionList() As %SQLQuery
{
	SELECT Name,Caption,Title FROM ActionDefinition
 	ORDER BY Name
}

Storage Default
{
<Data name="ActionDefinitionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Caption</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
<Value name="4">
<Value>Prompt</Value>
</Value>
</Data>
<DataLocation>^EnsLib.W.ActionDefinitionD</DataLocation>
<DefaultData>ActionDefinitionDefaultData</DefaultData>
<IdLocation>^EnsLib.W.ActionDefinitionD</IdLocation>
<IndexLocation>^EnsLib.W.ActionDefinitionI</IndexLocation>
<StreamLocation>^EnsLib.W.ActionDefinitionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
