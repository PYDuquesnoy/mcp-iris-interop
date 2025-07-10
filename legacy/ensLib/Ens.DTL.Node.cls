/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

IncludeGenerator (Ensemble, EnsCompiler)

/// Represents a node in the parse tree
Class Ens.DTL.Node Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Field Delimiter used by serialized form of DTL.
Parameter SDELIM = "|";

/// This holds a reference to the parent node of this node. Only the root
/// node of the parse tree will have no parent
Property Parent As Ens.DTL.Node;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
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

/// Serialize for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Do pStream.Write(..%ClassName()_$C(1))
	Quit $$$OK
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Quit $$$OK
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
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

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	$$$ASSERT("0:Subclass Responsibility")
	Quit "SubClass Responsibility"
}

}
