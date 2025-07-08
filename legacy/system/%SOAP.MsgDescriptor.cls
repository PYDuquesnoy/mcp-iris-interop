/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %soap

/// Super class for generated classes that represent SOAP Service WebMethods.
/// <br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.MsgDescriptor Extends %SOAP.Descriptor [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// Indicate that extra methods are to be generated for 
/// %XML.MsgDescriptor class.<br>
/// 
/// This parameter is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this parameter.
Parameter XMLMSGDESCRIPTOR = 1;

/// The name of the response to the SOAP operation being implemented.
Property %ResponseName As %String(XMLPROJECTION = "NONE");

/// Execute Web Method represented by this class and XMLExport result.
/// This method is invoked by the web service class. In turn, this method invokes:
/// <p><ul>
/// <li><b>OnPreWebMethod()</b></li>
/// <li>the web method</b></li>
/// <li><b>OnPostWebMethod()</b></li>
/// </ul></p>
/// Note that <METHOD>OnPostWebMethod()</METHOD> always gets run, even if there was an error.
Method InvokeService(%Service As %SOAP.WebService) [ CodeMode = generator, GenerateAfter = XMLGenerate ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).InvokeService(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Copy %request data to the properties of this class.
Method ProcessHTTP() As %Status [ CodeMode = generator, GenerateAfter = XMLGenerate ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).ProcessHTTP(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

}
