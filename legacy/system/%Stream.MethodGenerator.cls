/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provided by the object based method generator so you have a stream to write
/// the code to and to set the type of code.
Class %Stream.MethodGenerator Extends %Stream.GlobalCharacter [ System = 2 ]
{

/// Specified the type of code this stream represents. This is one of<ul>
/// <li><b>code</b> : A block of code, this is the default value</li>
/// <li><b>expression</b> : An expression</li>
/// <li><b>call</b> : A call to another routine</li></ul>
Property CodeMode As %String(VALUELIST = ",call,code,expression,") [ InitialExpression = "code" ];

Property Language As %String(VALUELIST = ",objectscript,cache,basic,java,tsql,javascript,mvbasic,") [ InitialExpression = "objectscript" ];

Storage Custom
{
<Type>%Library.CompleteCustomStorage</Type>
}

}
