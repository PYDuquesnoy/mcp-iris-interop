/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.Document Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the identifing name of the Document
Property Name As %String;

/// This holds the transaction sets, usually only 1 per SEF file but may be more
Property Sets As EnsLib.EDI.SEF.SetList;

/// This holds the responsible agency code, which identifies the standards
/// organization
Property Agency As %String;

/// This holds the Standard on which the implementation guidelines for this
/// document is based
Property Standard As %String;

/// This holds the doc type
Property DocType As %String;

/// This holds the doc title
Property Title As %String;

/// This holds the name of the reference tables to be used for this document
Property Ref As %String;

/// This holds the object variables
Property ObjVars As ObjectVariableList;

/// This holds the semantic references
Property SemRefs As SemanticReferenceList;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Record standard,doctype and title and reference
		Set $$$vaSchemaGbl(pCompiler.DocKey)=..Agency_"|"_..Standard_"|"_..DocType_"|"_..Title_"|"_..Ref
		
		#; Delegate to Sets
		Set tSC=..Sets.GenerateDescriptor(pCompiler)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..Sets=##class(EnsLib.EDI.SEF.SetList).%New()
		$$$ASSERTNOLOG($IsObject(..Sets))
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tSC=..Sets.GenerateText(pStream)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Name MUST NOT be non-empty string
		If ..Name="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeValidation,"Name",..Name,..DisplayName()))
		}
		
		If "|"_$$$GENDOD_"|"_$$$TDCC_"|"_$$$TRADACOMS_"|"_$$$UNEDIFACT_"|"_$$$ASCX12_"|"'[("|"_..Agency_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,..Agency,$$$GENDOD_","_$$$TDCC_","_$$$TRADACOMS_","_$$$UNEDIFACT_","_$$$ASCX12))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
		Set tSC=..Sets.Validate(.pStatus)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GetSegment(pTable As %Integer, pOrdinal As %Integer, pSegName As %String, Output pSegment As EnsLib.EDI.SEF.Segment) As %String
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pSegment=$$$NULLOREF,tSC=..Sets.GetSegment(pTable,pOrdinal,pSegName,.pSegment)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
