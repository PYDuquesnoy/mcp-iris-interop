/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Server side model of the Composite object in the RecordMap structure.
Class EnsLib.RecordMap.Model.Composite Extends EnsLib.RecordMap.Model.RecordProperty [ System = 4 ]
{

/// List of Composite and Field components embedded within this Composite.
Property SubElements As list Of EnsLib.RecordMap.Model.RecordProperty(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

/// Recursive method to retrieve the greatest depth of this branch of the object graph.
Method GetDepth(Output pHasRepeats As %Boolean) As %Integer [ Internal, ServerOnly = 1 ]
{
	Set tDepth = 0
	Set tMax = 0
	For i=1:1:..SubElements.Count() {
		Set tObject = ..SubElements.GetAt(i)
		Set tDepth = tObject.GetDepth(.pHasRepeats)
		If (tDepth > tMax) Set tMax = tDepth
	}
	Quit tMax+1
}

/// Ensure SubElements are valid.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	For i=1:1:..SubElements.Count() {
		Set tObject = ..SubElements.GetAt(i)
		Set tObject.RecordType = ..RecordType
		Set tSC = tObject.%ValidateObject(1)
		If $$$ISERR(tSC) Quit
	}
	Quit tSC
}

}
