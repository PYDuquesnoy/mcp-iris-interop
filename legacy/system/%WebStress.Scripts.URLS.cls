/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Scripts.URLS Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60212,85655";

Relationship Script As %WebStress.Scripts [ Cardinality = parent, Inverse = URLs ];

/// This is the port that was explicitly specified in the original call
Property SpecifiedPort As %String(TRUNCATE = 1);

/// This is the verb that was used to call this web reference. Expected answers are either GET or POST.
Property Verb As %String(TRUNCATE = 1);

/// This is the URL of the call
Property Path As %String(MAXLEN = 10000, TRUNCATE = 1);

/// This specifies an explicit server address that is different from that specified for the test
Property ServerChange As %String(TRUNCATE = 1);

/// This is the user entered description of the functionality of this URL
Property Description As %String(MAXLEN = 30, TRUNCATE = 1);

/// The delay in milliseconds before calling this URL
Property Delay As %Integer;

/// This is an array of the headers sent by the browser
Property Headers As array Of %String(TRUNCATE = 1);

Relationship Parameters As %WebStress.Scripts.URLS.Parameters [ Cardinality = children, Inverse = URL ];

/// The code that should be executed before the web call is made
/// Example 1 - do PreURL20^Random.Script.1
/// Example 2 - do ##class(MyPackage.MyClass).GetParams1(.params)
Property PreExecute As %String(MAXLEN = 100, TRUNCATE = 1);

/// The code that should be called after the web call is completed
/// Example 1 - do PostURL20^Random.Script.1
/// Example 2 - do ##class(MyPackage.MyClass).AfterCall1()
Property PostExecute As %String(MAXLEN = 100, TRUNCATE = 1);

/// This is the recorded request that was sent from the browser
Property Request As %GlobalCharacterStream;

/// This is the recorded response that was received back from the webserver
Property Response As %GlobalCharacterStream;

/// This is the number of milliseconds that were recorded between the request 
/// being received from the browser and the response being sent back from the server
Property RecordedTime As %Integer;

/// This is similar to the RecordedTime but is the total time for the page with all of its components
Property PageTime As %Integer [ Calculated, SqlComputeCode = {	set id={ID}
	set {PageTime}=##class(%WebStress.Scripts.URLS).%OpenId(id,0).PageTime}, SqlComputed ];

Property NumberOfParameters As %Integer [ Calculated, SqlComputeCode = {	set id={ID}
	set {NumberOfParameters}=##class(%WebStress.Scripts.URLS).%OpenId(id,0).NumberOfParameters}, SqlComputed ];

/// The protocol used
Property Protocol As %String(TRUNCATE = 1);

/// Indicates that this URL is the start of a page 'group'. 
Property PageMarker As %Boolean;

Method NumberOfParametersGet() As %Integer
{
	quit ..Parameters.Count()
}

Method PageTimeGet() As %Integer
{
	if ..PageMarker = 0 quit ..RecordedTime
	set script = ..Script.%Id()
	set childsub = $piece(..%Id(),"||",2)
	set total = ..RecordedTime
	&sql(declare PAGETIMEGET cursor for
		select RecordedTime,PageMarker
		into :time,:mark
		from %WebStress_Scripts.URLS
		where Script = :script
		and childsub > :childsub)
	&sql(open PAGETIMEGET)
	for  {
		&sql(fetch PAGETIMEGET)
		if (SQLCODE'=0)||(mark) quit
		set total=total+time
	}
	&sql(close PAGETIMEGET)
	quit total
}

Method DumpToFile() As %String
{
	set file = $zu(12,"")_"webstress_dump_"_$job_".html"
	close file
	open file:"WNS":1 if '$test quit ""
	use file
	do ..Response.Rewind()
	write ..Response.Read()
	close file
	quit "webstress_dump_"_$job_".html"
}

Method DestroyDumpFile(file)
{
	do ##class(%Library.File).Delete(file)
}

Query ListDetail(script As %String) As %SQLQuery
{
SELECT childsub,Path,Verb,NumberOfParameters,Delay,PageTime FROM URLS
 WHERE (PageMarker = 1 AND Script = :script)
 ORDER BY childsub
}

Query ShowURL(script As %String) As %SQLQuery
{
	select ID,Path,Verb,NumberOfParameters from URLs where Script = :script
}

Storage Default
{
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"Headers"</Subscript>
</Data>
<Data name="URLSDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Delay</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Path</Value>
</Value>
<Value name="5">
<Value>Port</Value>
</Value>
<Value name="6">
<Value>PostExecute</Value>
</Value>
<Value name="7">
<Value>PreExecute</Value>
</Value>
<Value name="8">
<Value>RecordedTime</Value>
</Value>
<Value name="9">
<Value>Request</Value>
</Value>
<Value name="10">
<Value>Response</Value>
</Value>
<Value name="11">
<Value>Server</Value>
</Value>
<Value name="12">
<Value>Verb</Value>
</Value>
<Value name="13">
<Value>temp</Value>
</Value>
<Value name="14">
<Value>DefaultPort</Value>
</Value>
<Value name="15">
<Value>SavedDate</Value>
</Value>
<Value name="16">
<Value>SavedTime</Value>
</Value>
<Value name="17">
<Value>SyncSave</Value>
</Value>
<Value name="18">
<Value>Version</Value>
</Value>
<Value name="19">
<Value>ExplicitPort</Value>
</Value>
<Value name="20">
<Value>ServerChange</Value>
</Value>
<Value name="21">
<Value>SpecifiedPort</Value>
</Value>
<Value name="22">
<Value>Protocol</Value>
</Value>
<Value name="23">
<Value>ContainsCSPToken</Value>
</Value>
<Value name="24">
<Value>PageMarker</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("URLs")</DataLocation>
<DefaultData>URLSDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.ScriptsC("URLs")</IdLocation>
<IndexLocation>^WebStress.URLSI</IndexLocation>
<StreamLocation>^WebStress.URLSS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
