/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for all DeepSee dimension (star) tables.
Class %DeepSee.DimensionTable Extends %Persistent [ Abstract, NoExtent, System = 3 ]
{

/// Name of the cube that created this dimension table.
Parameter CUBENAME As STRING;

/// Name of the source table that provides data for this dimension table.
Parameter SOURCECLASS As STRING;

/// Turn off extent management for dimension tables.
Parameter MANAGEDEXTENT = 0;

/// Return the total number of items within the Dimension table.<br/>
/// The actual implementation is generated when the cube is compiled.
ClassMethod %Count() As %Integer [ Abstract ]
{
}

/// Return the member specification for the given member.<br/>
/// The actual implementation is generated when the cube is compiled.
ClassMethod %GetMemberSpec(pMemberId As %String, pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %String [ Abstract, Internal ]
{
}

/// Update a row in this dimension table with data from the source table with id <var>pID</var>.<br/>
/// The actual implementation is generated when the cube is compiled.
ClassMethod %UpdateRow(pID As %String, ByRef pValues As %String) As %Integer [ Abstract, Internal ]
{
}

/// Validate level KEY value; make sure it does not contain bad punctuation.
ClassMethod %ValidateKEY(pArg As %String) As %Status
{
	/* JMD1027
	If ((pArg["|")||(pArg["&")||(pArg[":")||(pArg["~")) {
		// Log this error
		Set tMsg = "Invalid character in level KEY '"_pArg_"'"
		Do ##class(%DeepSee.Utils).%WriteToLog("UPDATE",tMsg)
		Quit 0
	}
	*/
	Quit $$$OK
}

}
