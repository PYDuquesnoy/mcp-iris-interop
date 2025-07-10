/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used for export message request background processing
Class Ens.Background.Request.ExportMessage Extends Ens.Background.Request [ System = 4 ]
{

Parameter XMLTYPE = "BackgroundMessageExport";

/// This is used to suggest to the browser what filename to use in the download
Property LocalFilename As %String(MAXLEN = "");

/// This is the character set to use when creating the export - the default is the system default
Property CharSet As %String(MAXLEN = 128);

/// This is used to specify how the messages in the export will be separated <br>
/// CRLF,CR,LF,MLLP,Tab,None
Property MsgSeperators As %String(MAXLEN = 10);

/// This is the name of the message viewer search class that will be invoked with the SavedSearch
Property SearchClass As %String(MAXLEN = 128);

/// This is the name of the saved search details that are saved temporarily with a unique name
Property SavedSearch As %String(MAXLEN = 128);

Storage Default
{
<Data name="ExportMessageDefaultData">
<Subscript>"ExportMessage"</Subscript>
<Value name="1">
<Value>LocalFilename</Value>
</Value>
<Value name="2">
<Value>CharSet</Value>
</Value>
<Value name="3">
<Value>MsgSeperators</Value>
</Value>
<Value name="4">
<Value>SearchClass</Value>
</Value>
<Value name="5">
<Value>SavedSearch</Value>
</Value>
</Data>
<DefaultData>ExportMessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
