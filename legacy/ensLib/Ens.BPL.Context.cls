/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <context> is an object that is available to a BPL business process anywhere inside the <process> element.
/// context is a general-purpose container for any data that needs to be persisted during the life cycle of 
/// the business process. You define each data item as a property on the context object when creating the BPL
/// business process as follows in the example
Class Ens.BPL.Context Extends Ens.BPL.Node [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<context>
  <property name='Test' type='%Integer' initialexpression='342' >
    <parameters>
      <parameter name='MAXVAL' value='1000' />
    </parameters>
  </property>
  <property name='Another' type='%String' initialexpression='Yo' >
    <parameters>
      <parameter name='MAXLEN' value='2' />
      <parameter name='MINLEN' value='1' />
    </parameters>
  </property>
</context>
}

/// This holds the context Properties list
Property Properties As Ens.BPL.PropertyList;

Method %OnNew(initvalue As %RawString) As %Status
{
	Set ..Properties=##class(Ens.BPL.PropertyList).%New()
	$$$ASSERT($IsObject(..Properties))
	Quit $$$OK
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Properties.Count() {
			Set tSC=..Properties.GenerateCode(pCompiler)
		}
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Context is optional ( but usually present )
		If ..Properties.Count() {
			
			Do pStream.WriteLine("<context>")
			
			Set tSC=..Properties.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		
			Do pStream.WriteLine("</context>")
		}
		
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
		#; Delegate to the properties
		Set tSC=..Properties.Validate(pStatus,pContext)				
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
