/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A base class for print requests
Class EnsLib.Printing.PrintRequest Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

/// Time print request was created
Property RequestedAt As %TimeStamp [ InitialExpression = {$ZDT($H,3)} ];

/// User who created the print request
Property RequestedBy As %String(MAXLEN = 512) [ InitialExpression = {$USERNAME} ];

/// Print renderer to use
Property PrintRenderer As Ens.DataType.ConfigName;

/// Printer target name (or empty if it's not to be printed)
Property PrintTarget As Ens.DataType.ConfigName;

Storage Default
{
<Data name="PrintRequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RequestedAt</Value>
</Value>
<Value name="3">
<Value>RequestedBy</Value>
</Value>
<Value name="4">
<Value>PrintTarget</Value>
</Value>
<Value name="5">
<Value>PrintRenderer</Value>
</Value>
</Data>
<DataLocation>^EnsLib.Printing.PrintRequestD</DataLocation>
<DefaultData>PrintRequestDefaultData</DefaultData>
<IdLocation>^EnsLib.Printing.PrintRequestD</IdLocation>
<IndexLocation>^EnsLib.Printing.PrintRequestI</IndexLocation>
<StreamLocation>^EnsLib.Printing.PrintRequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
