/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Utility functions for BPL
Class Ens.Util.BPL Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Validate the BPL potentially contained in the specified class. If the method
/// returns $$$OK, then the BPL was found and validates according to the BPL Schema
ClassMethod ValidateBPL(pClassName As %String) As %Status
{
	Set tSC=$$$OK
	do {
		#; Find the XDATA itself
		Set tSC=##class(Ens.Util.XML.XDataEntityResolver).EntityFromXDATA(.tStream,pClassName,"BPL")
		If $$$ISERR(tSC) Quit
		
		#; Create a SAX resolver for the Schema
		Set tResolver=##class(Ens.Util.XML.XDataEntityResolver).%New("Ens.Schema.BPL")
 		$$$ASSERT($IsObject(tResolver))
 		
 		Set tSC=##class(Ens.Util.XML.Validator).ValidateStream(tStream,tResolver,"Schema")
 		If $$$ISERR(tSC) Quit
 		
	} while (0)
	Quit tSC
}

}
