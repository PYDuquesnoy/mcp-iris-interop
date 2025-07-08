/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a property within a DeepSee KPI.
Class %DeepSee.Model.KPI.property Extends node [ System = 3 ]
{

/// KPI that this property belongs to.
Relationship kpi As %DeepSee.Model.KPI.kpi(XMLPROJECTION = "none") [ Cardinality = one, Inverse = properties ];

/// Default value to apply to this property.
Property defaultValue As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Column (1-based) in the KPI's SQL or MDX query that supplies the value for this KPI.
Property columnNo As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Default format to apply to this property.
Property format As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Default css style to apply to this property.
Property style As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Default css style to apply to the column header used for this property.
Property headerStyle As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Test if this properties's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
