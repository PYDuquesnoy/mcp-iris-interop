/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class to store IOLog entries for classes that extend <class>EnsLib.EDI.Segmented</class>
/// and have Separators. The goal here is to keep a record of the separators used to send
/// EDI documents to other systems.
Class Ens.Util.IOLogSegmentedObj Extends Ens.Util.IOLogObj [ System = 4 ]
{

Property InObjectSeparators As %String;

Property OutObjectSeparators As %String;

Storage Default
{
<Data name="IOLogSegmentedObjDefaultData">
<Subscript>"IOLogSegmentedObj"</Subscript>
<Value name="1">
<Value>InObjectSeparators</Value>
</Value>
<Value name="2">
<Value>OutObjectSeparators</Value>
</Value>
</Data>
<DefaultData>IOLogSegmentedObjDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
