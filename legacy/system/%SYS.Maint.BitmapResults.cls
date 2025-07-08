/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class gets populated by methods NameSpace and OneClass in <class>%SYS.Maint.Bitmap</class>
/// <p><property>RunID</property> is the same as the ID of the row stored in %SYS.Maint.Bitmap 
/// <p><property>OldSize</property> and <property>NewSize</property> are the number of MB before and after.
/// <p><property>Compression</property> is the % the index was compressed, if 0 the index was empty.
/// 
/// <p><property>Status</property> can have one of the following values:
/// 
/// <ul>
/// 	<li>finished
/// 	<li>Global:  <i>GlobalName</i> is not local, skipping compression
/// 	<li>an error message
/// </ul>
/// <p><property>LastCompression</property> is the timestamp from when the last compression was finished.
/// 
Class %SYS.Maint.BitmapResults Extends %Persistent [ System = 4 ]
{

Property RunID As %SYS.Maint.Bitmap;

Property ClassName As %String(MAXLEN = 500);

Property GlobalName As %String(MAXLEN = 500);

Property OldSize As %Integer;

Property NewSize As %Integer;

Property Status As %String;

Property Compression As %String;

Property LastCompressed As %TimeStamp;

Storage Default
{
<Data name="BitmapResultsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RunID</Value>
</Value>
<Value name="3">
<Value>ClassName</Value>
</Value>
<Value name="4">
<Value>GlobalName</Value>
</Value>
<Value name="5">
<Value>OldSize</Value>
</Value>
<Value name="6">
<Value>NewSize</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>Compression</Value>
</Value>
<Value name="9">
<Value>LastCompressed</Value>
</Value>
</Data>
<DataLocation>^%SYS.Maint.BitmapResultsD</DataLocation>
<DefaultData>BitmapResultsDefaultData</DefaultData>
<IdLocation>^%SYS.Maint.BitmapResultsD</IdLocation>
<IndexLocation>^%SYS.Maint.BitmapResultsI</IndexLocation>
<StreamLocation>^%SYS.Maint.BitmapResultsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
