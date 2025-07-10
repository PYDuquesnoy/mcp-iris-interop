/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A base class for print requests
Class EnsLib.Printing.PrintJob Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

/// Printer target name (or empty if it's not to be printed)
Property PrintTarget As Ens.DataType.ConfigName;

/// Time print job was rendered
Property RenderedAt As %TimeStamp [ InitialExpression = {$ZDT($H,3)} ];

/// MIME Type of the content (e.g. text/plain, text/html, application/pdf etc).
Property ContentType As %String(MAXLEN = 128);

/// Print job content
Property Content As %Stream.GlobalBinary;

Storage Default
{
<Data name="PrintJobDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RenderedAt</Value>
</Value>
<Value name="3">
<Value>ContentType</Value>
</Value>
<Value name="4">
<Value>Content</Value>
</Value>
<Value name="5">
<Value>PrintTarget</Value>
</Value>
</Data>
<DataLocation>^EnsLib.Printing.PrintJobD</DataLocation>
<DefaultData>PrintJobDefaultData</DefaultData>
<IdLocation>^EnsLib.Printing.PrintJobD</IdLocation>
<IndexLocation>^EnsLib.Printing.PrintJobI</IndexLocation>
<StreamLocation>^EnsLib.Printing.PrintJobS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
