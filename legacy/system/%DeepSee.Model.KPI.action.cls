/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for an action within a DeepSee KPI.
Class %DeepSee.Model.KPI.action Extends node [ System = 3 ]
{

/// KPI that this property belongs to.
Relationship kpi As %DeepSee.Model.KPI.kpi(XMLPROJECTION = "none") [ Cardinality = one, Inverse = actions ];

/// Test if this action's definition is valid.
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
