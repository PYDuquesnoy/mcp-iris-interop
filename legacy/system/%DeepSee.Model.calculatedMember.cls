/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a calculated member within a DeepSee cube.<br/>
/// At query processing time, references to a calculated member are replaced with the
/// <property>valueExpression</property> that defines the member.
Class %DeepSee.Model.calculatedMember Extends %DeepSee.Model.node [ System = 3 ]
{

/// Cube that this calculated member belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = calculatedMembers ];

/// Name of the dimension this calculated member belongs to.
/// This does not have to be an existing dimension.
Property dimension As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// MDX expression that defines the value of this calculated member.
Property valueExpression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Optional format string to apply to this member.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Optional. Units applied to this member (if it is a measure).<br/>
/// This is not currently used.
Property units As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// If true, this calculatedMember is hidden. That is, it will not be listed among the
/// cube's members within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

Property listingFilter As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Test if this member's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	If (..dimension="") {
		Set tSC = $$$ERROR($$$GeneralError,"Calculated member must define a dimension name: " _ ..name)
	}

	If (..valueExpression="") {
		Set tSC = $$$ERROR($$$GeneralError,"Calculated member must define a valueExpression: " _ ..name)
	}

	Quit tSC
}

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-406089
	Set tCalcObj = {}
	
	Try {
		If ($$$UPPER(..dimension)'="MEASURES") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj("Dimension based Calculated Members are not supported for AtScale export:"_..dimension_":"_..name,$$$msgInfo))
			Set tCalcObj = ""
			Quit
		}
		
		Set tCalcObj.name = ..name
		Set tCalcObj.displayName = ..displayName
		Set tCalcObj.expression = ..valueExpression		// The arbitrary valueExpression will successfully import and is validated by AtScale prior to publishing 
		Set tCalcObj.description = ..description _ $S((..description'=""):$C(13,10,13,10),1:"") _ $$$Text("Original expression in IRIS")_": " _ ..valueExpression 
		Set tCalcObj.formatting = ..formatString
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tCalcObj={}
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tCalcObj
}

}
