/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.TermEntity Extends Term [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "Entity";

Property type As %String(VALUELIST = ",entity", XMLPROJECTION = "NONE") [ InitialExpression = "entity", ReadOnly ];

Property value As %String(MAXLEN = 200, XMLPROJECTION = "NONE") [ Internal ];

Property Entries As list Of %String(MAXLEN = 200, XMLNAME = "Value", XMLPROJECTION = "ELEMENT");

/// Returns a string representation of this term
Method GetValue() As %String
{
	if (..Entries.Count()>1) {
		set tValues = ""
		for i = 1:1:..Entries.Count() {
			set tValues = tValues _ $lb(..Entries.GetAt(i))
		}
		quit tValues
	} else {
		quit ..Entries.GetAt(1)
	}
}

Method %EqualsInternal(pTerm As Term) As %Boolean [ Internal, Private ]
{
	set tCount = ..Entries.Count()
	quit:tCount'=pTerm.Entries.Count() 0
	for i = 1:1:tCount {
		set tValues(..Entries.GetAt(i)) = ""
	}
	set tOK = 1
	for i = 1:1:tCount {
		set tOK = $d(tValues(pTerm.Entries.GetAt(i)))
		quit:'tOK
	}
	quit tOK
}

Method OnGetDisplayName(pMode As %Integer = 0) As %String [ Internal, Private ]
{
	set tCount = ..Entries.Count()
	quit:'pMode ..Entries.GetAt(1) _ $s(tCount>1:" ("_(tCount-1)_" more)", 1:"")
	quit:tCount=1 ..Entries.GetAt(1) _ " (entity)"
	set tDisplay = "Entities:"
	for i = 1:1:tCount {
		set tDisplay = tDisplay _ $case(pMode, 1:$s(i=1:"",1:"; "), 2:$c(13,10) _ " - ") _ ..Entries.GetAt(i)
	}
	quit tDisplay
}

Method ContainsEntry(pValue As %String) As %Integer
{
	set tContainsEntry = 0
	for i = 1:1:..Entries.Count() {
		set:(..Entries.GetAt(i)=pValue) tContainsEntry = i
		quit:tContainsEntry
	}
	quit tContainsEntry
}

Method RemoveEntry(pValue As %String, Output pIsEmpty As %Boolean) As %Status
{
	set tSC = $$$OK, pIsEmpty = 0
	try {
		set tIndex = ..ContainsEntry(pValue)
		do:tIndex ..Entries.RemoveAt(tIndex)
		set pIsEmpty = '..Entries.Count()
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method EntryCount() As %Integer
{
	quit ..Entries.Count()
}

Storage Default
{
<Data name="TermState">
<Value name="1">
<Value>value</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>negation</Value>
</Value>
<Value name="4">
<Value>count</Value>
</Value>
<Value name="5">
<Value>Entries</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
