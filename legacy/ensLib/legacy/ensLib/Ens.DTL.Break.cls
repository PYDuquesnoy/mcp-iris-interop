/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to break out of a series of actions. When performed in
/// a <foreach>, the <break> will immeadiately exit the foreach and resume with processing the following actions.
/// If the <break> appears anywhere else, the processing of any actions following the <break> will be skipped and 
/// the DTL will terminate
Class Ens.DTL.Break Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<break/>
}

Parameter TAGNAME = "break";

/// This holds the value to assign to the property
Property Value As %String;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tLanguage=$$$sysLangFromDTL(pCompiler.Transform.Language)

		$$$ASSERT(tLanguage=$$$objectscript||(tLanguage=$$$basic))

		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"Quit")
		} Else {
			$$$PCIndent(pCompiler.Indent,"Exit Do")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Break"
}

}
