/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

IncludeGenerator %occExtent

Class EnsLib.RecordMap.ComplexBase [ Abstract, System = 4 ]
{

/// Helper method to ensure that we can try to force an ID for classes.
Method %GetId() As %String [ CodeMode = objectgenerator ]
{
	Set tIdExpr = $get($$$EXTidexpression($$$pEXT,%class.Name))
	If tIdExpr '= "" Do %code.WriteLine(" If ..%Id()="""" Do ..%IdSet("_tIdExpr_")")
	Do %code.WriteLine(" Quit ..%Id()")
	Quit $$$OK
}

}
