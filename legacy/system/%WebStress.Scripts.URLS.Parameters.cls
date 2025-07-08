/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Scripts.URLS.Parameters Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Parameter FileTimestamp = "60183,39714";

Relationship URL As %WebStress.Scripts.URLS [ Cardinality = parent, Inverse = Parameters ];

/// The name of the parameter
Property Key As %String(MAXLEN = 10000, TRUNCATE = 1) [ SqlFieldName = Param_Key ];

/// Defines whether the parameter is part of the URL itself or is contained in
/// the form data
Property Type As %String(DISPLAYLIST = ",Form Data,Parameter,Stream", TRUNCATE = 1, VALUELIST = ",F,P,S") [ InitialExpression = "P", SqlFieldName = Param_Type ];

/// The value associated with this key
Property Value As %String(MAXLEN = 10000, TRUNCATE = 1) [ SqlFieldName = Param_Value ];

/// A stream containing the posted file or stream (XML etc)
Property PostStream As %GlobalCharacterStream;

Property PostStreamBoundary As %String(TRUNCATE = 1);

Property PostStreamName As %String(TRUNCATE = 1);

Property PostStreamFilename As %String(TRUNCATE = 1);

Property PostStreamContentType As %String(TRUNCATE = 1);

Property ValueDecode As %String(MAXLEN = 10000, TRUNCATE = 1) [ Calculated, SqlComputeCode = {	new PID
	set PID={ID}
	set {ValueDecode}=##class(%WebStress.Scripts.URLS.Parameters).%OpenId(PID,0).ValueDecode}, SqlComputed, Transient ];

Method ValueDecodeGet() As %String
{
	set code=""
	if (..Value'="")&&((..Key="WSCRIPT")||(..Key="WEVENT")||(..Key="CSPToken")) {
		set $ztrap="failed"
		set code=$$$cspDecode("notencrypted",..Value)
		if $translate($piece(code,$char(1),2),").:%")'?.an {
			// Now try 5.1
			goto failed
		}
		else {
			set code=$piece(code,$char(1),2)
		}
	}
	quit code
failed
	set $ztrap=""
	quit ""
}

Storage Default
{
<Data name="ParametersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Key</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Value</Value>
</Value>
<Value name="5">
<Value>PostStream</Value>
</Value>
<Value name="6">
<Value>SavedDate</Value>
</Value>
<Value name="7">
<Value>SavedTime</Value>
</Value>
<Value name="8">
<Value>SyncSave</Value>
</Value>
<Value name="9">
<Value>Version</Value>
</Value>
<Value name="10">
<Value>ValueDecode</Value>
</Value>
<Value name="11">
<Value>PostStreamBoundary</Value>
</Value>
<Value name="12">
<Value>PostStreamContentType</Value>
</Value>
<Value name="13">
<Value>PostStreamFilename</Value>
</Value>
<Value name="14">
<Value>PostStreamName</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Parameters")</DataLocation>
<DefaultData>ParametersDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.URLSC("Parameters")</IdLocation>
<IndexLocation>^WebStress.ParametersI</IndexLocation>
<StreamLocation>^WebStress.ParametersS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
