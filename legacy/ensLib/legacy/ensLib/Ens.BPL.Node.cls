/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

IncludeGenerator (Ensemble, EnsCompiler)

/// This class is an internal detail of the implementation of the BPL Compiler
/// Represents a node in the parse tree
Class Ens.BPL.Node Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds a reference to the parent node of this node. Only the root
/// node of the parse tree will have no parent
Property Parent As Ens.BPL.Node;

/// Optional setting. Sets the compilation language at level of activity.
/// To be useful, this will differ from the main BPL language.<br/>
/// Example 1: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Code block activity to accomodate Embedded <em>Python</em> source code.<br/>
/// Example 2: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Assignment activity expression to accomodate Embedded <em>Python</em> code expression.
Property LanguageOverride As %String(VALUELIST = ",python,objectscript,basic");

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		$$$ASSERT("0:Subclass Responsibility")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		$$$ASSERT("0:Subclass Responsibility")
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		// Nothing to do
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Normalize Attribute
Method NormalizeAttribute(pAttr)
{
	Set tAttr=""
	For tI=1:1:$Length(pAttr) {
		Set tC=$Extract(pAttr,tI)
		If tC="'" {
			Set tAttr=tAttr_"&apos;"
		} elseif tC="<" {
			Set tAttr=tAttr_"&lt;"
		} elseif tC=">" {
			Set tAttr=tAttr_"&gt;"
		} elseif tC="&" {
			Set tAttr=tAttr_"&amp;"
		} else {
			Set tAttr=tAttr_tC
		}
	}
	Quit ("'"_tAttr_"' ")
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	$$$ASSERT("0:Subclass Responsibility")
	Quit "SubClass Responsibility"
}

}
