/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature Algorithm element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.SignatureMethod Extends %XML.Security.Algorithm [ System = 4 ]
{

Property HMACOutputLength As %Integer;

Storage Default
{
<Data name="AlgorithmState">
<Value name="1">
<Value>Algorithm</Value>
</Value>
<Value name="2">
<Value>HMACOutputLength</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
