/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

/// <div style="color:red;padding:5px; border:1px solid black; background:#FFFFAA;">
/// <b>Note:</b> This class is included because it is needed by
/// other parts of the library. You should not use this or any other class within
/// this package within your applications as a future version will
/// be incompatible. If you are interested in this functionality
/// please contact InterSystems.
/// </div><br/>
/// This is the base class for nodes within an XGEN document.<br/>
/// A node represents a specific action within an XGEN document.<br/>
/// See <class>%XGEN.AbstractDocument</class> for an overview of XGEN.
Class %XGEN.AbstractNode Extends AbstractElement [ System = 3 ]
{

/// Generate code for this node.<br/>
/// User classes should not override this method, instead they should override the
/// <method>%OnGenerateCode</method> method.
Method %GenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status [ Final, Internal ]
{
	Quit ..%OnGenerateCode(pTargetClass,pCode,pDocument)
}

/// Generate code for this node.<br/>
/// This method is called when a class containing an XGEN
/// document is compiled.<br/>
/// <var>pTargetClass</var> is the class that contains the XGEN document.<br/>
/// <var>pCode</var> is a stream containing the generated code.<br/>
/// <var>pDocument</var> is the top-level XGEN document object that contains this node.<br/>
/// A subclass will provide an implementation of this method that will
/// generate specific lines of code.<br/>
/// For example:
/// <example>
/// Do pCode.WriteLine(..%Indent()_"Set " _ ..target _ "=" _ $$$quote(..value))
/// </example>
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %XGEN.AbstractDocument) As %Status
{
	Quit $$$OK
}

}
