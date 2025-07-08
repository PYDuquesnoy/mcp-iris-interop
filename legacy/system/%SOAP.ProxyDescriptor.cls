/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %occSAX)

IncludeGenerator %soap

/// Super class for generated classes that represent SOAP Client WebMethods.
/// <br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.ProxyDescriptor Extends %SOAP.Descriptor [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// The name of the SOAP operation being implemented.
Property %RequestName As %String(XMLPROJECTION = "NONE");

/// <var>operation</var> is the SOAP operation.
Method %OnNew(operation As %String) As %Status
{
	Set ..%RequestName=$get(operation)
	Quit $$$OK
}

}
