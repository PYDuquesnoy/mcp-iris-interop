/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a member property within a dimension level within a DeepSee cube.<br/>
Class %DeepSee.Model.property Extends (%DeepSee.Model.node, %DeepSee.Model.source) [ System = 3 ]
{

/// If true, this property is hidden. That is, it will not be listed among the
/// level's properties within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If specified, then use this property to sort members of the current level.<br/>
/// The value can be "asc" for ascending order, "desc" for descending order,
/// "asc numeric" for ascending numeric order, or "desc numeric" for descending numeric order.<br/>
/// If more than one property specifies sorting, then members are sorted using a combination
/// of properties. The sorting is applied in the order in which the properties are
/// listed in the level definition.
Property sort As %DeepSee.Datatype.string(VALUELIST = ",asc,desc,asc numeric,desc numeric", XMLPROJECTION = "attribute");

/// If true, then this property is used to supply the display name for members
/// of this level.<br/>
/// Only one property for a given level can set this property.
Property isName As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional. If true, then this property is used to supply an alternate descriptive name for members
/// of this level.<br/>
/// Only one property for a given level can set this property.
Property isDescription As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, then the value of this property is not stored within a dimension
/// table. Instead its value is retrieved from the data source when a query
/// is executed.
Property isReference As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, then use the display (external) value of the field (if applicable) in the source
/// table when fetching data for this property.<br/>
/// This is only applied for properties that specify a <property>sourceProperty</property>.
Property useDisplayValue As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional format string to apply to this property.
Property formatString As %DeepSee.Datatype.string(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tProp = ""
	
	Try {
		// Perform a series of checks to see if this is AtScale-compatible
		If (..sourceProperty="") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Property cannot be exported without a sourceProperty: ")_pAuxiliaryIndex.currLevelName_":"_..name,$$$msgInfo))
			Set tProp = ""
			Quit
		}
		If ..disabled {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Property is disabled and will not be exported: ")_pAuxiliaryIndex.currLevelName_":"_..name,$$$msgInfo))
			Set tProp = ""
			Quit
		}
		
		Set pStatus = ..%AtScaleProcessSourceRef(..sourceProperty,.pAuxiliaryIndex)
		If $$$ISERR(pStatus) Quit
		
		// Produce the attribute and source column.
		Set tCurrAttribute = ..%AtScaleProduceAttribute(..sourceProperty,pAuxiliaryIndex)
		
		If $IsObject(tCurrAttribute) {
			// Pass along property-specific properties to the current attribute
			If (..sort'="") {
				// DP-407548 - Create a sort object if the source 
				Set tSortObj = {}
				Set tSortObj.order = $$$atScaleSort(..sort)
				Set tSortObj.column = tCurrAttribute.keyColumns.%Get(0)		// These attributes use a single column
				Set tCurrAttribute.sort = tSortObj
			}
			
			Set:(..formatString'="") tCurrAttribute.customFormat = ..formatString
			
			Do pAuxiliaryIndex.attributes.%Push(tCurrAttribute)
			
			// Read the name of the returned attribute to make sure the reference and the produced
			// attribute will always match.
			Set tProp = tCurrAttribute.name
		}
		
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tProp=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tProp
}

}
