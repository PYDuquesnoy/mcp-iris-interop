/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

/// This holds the (generated) properties defined by the BPL <context>
Class Ens.BP.Context Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// This holds the registered ResponseHandlers
Property %ResponseHandlers As array Of %String(XMLPROJECTION = "none") [ SqlFieldName = _ResponseHandlers ];

/// This holds the reference to the context object
Property %Context As Ens.BP.Context(XMLPROJECTION = "none") [ Calculated ];

/// This holds the reference to the process object
Property %Process As Ens.BusinessProcess(XMLPROJECTION = "none");

/// This holds last exception
Property %LastError As %Status [ InitialExpression = {$$$OK} ];

/// This holds the last thrown fault
Property %LastFault As %String(MAXLEN = "");

/// Prevent this class from having the same default XML Type and Name as any of its subclasses that have the short classname "Context".
Parameter XMLTYPE As %String = "BP_Context";

/// Prevent the XML Type and Name of classes derived from this class from interfering with one another if they have the same short classname.
Parameter XMLINCLUDEINGROUP As %Boolean = 0;

/// Accessor for the %Context property
Method %ContextGet() As Ens.BP.Context
{
	Quit $this
}

/// This method updates the Response Handlers collection by adding a new Response Handler name
Method SetResponseHandler(pResponseHandlerName As %String, pCompletionKey As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do ..%ResponseHandlers.SetAt(pResponseHandlerName,pCompletionKey)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Initialize the %Process property on construction
Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..%Process=initvalue
	Quit $$$OK
}

/// This method is called by the Management Portal to determine
/// the content type that will be returned by the <method>%ShowContents</method>
/// method.
/// The return value is a string containing an HTTP content type.
Method %GetContentType() As %String
{
	Quit "text/xml"
}

/// This method is called by the Management Portal to 
/// display a message-specific content viewer.<br>
/// This method displays its content by writing out to the current device.
/// The content should match the type returned by the 
/// <method>%GetContentType</method> method.<br>
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	// show contents as XML
	&html<<?xml version="1.0" ?>
	<!-- type: #($classname())#  id: #(..%Id())# -->
	>
	Do $method($this,"XMLExport")
}

/// This method is called by the Management Portal to 
/// display a portion of the HEAD section of a
/// message-specific content viewer.<br>
Method %ShowContentsHead(pZenOutput As %Boolean = 0)
{
}

/// This is invoked when a thread enters an activity
Method EnterActivity(pActivity As %Integer, pSubActivity As %Integer, pActivityID As %Integer)
{
}

/// This is invoked when a thread leaves an activity
Method LeaveActivity(pActivity As %Integer, pSubActivity As %Integer, pActivityID As %Integer)
{
}

Storage Default
{
<Data name="%ResponseHandlers">
<Attribute>%ResponseHandlers</Attribute>
<Structure>subnode</Structure>
<Subscript>"%ResponseHandlers"</Subscript>
</Data>
<Data name="ContextDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%Process</Value>
</Value>
<Value name="3">
<Value>%LastError</Value>
</Value>
<Value name="4">
<Value>%LastFault</Value>
</Value>
</Data>
<DataLocation>^Ens.BP.ContextD</DataLocation>
<DefaultData>ContextDefaultData</DefaultData>
<IdLocation>^Ens.BP.ContextD</IdLocation>
<IndexLocation>^Ens.BP.ContextI</IndexLocation>
<StreamLocation>^Ens.BP.ContextS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
