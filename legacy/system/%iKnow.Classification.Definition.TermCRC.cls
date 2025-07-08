/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.TermCRC Extends Term [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "CRC";

Property type As %String(VALUELIST = ",crc", XMLPROJECTION = "NONE") [ InitialExpression = "crc", ReadOnly ];

Property value As %String(MAXLEN = 200, XMLPROJECTION = "NONE") [ Internal ];

Property Entries As list Of TermCRCEntry(XMLNAME = "Entry", XMLPROJECTION = "ELEMENT");

/// Returns a string representation of this term
Method GetValue() As %String
{
	set tCount = ..Entries.Count()
	set tValue = ""
	for i = 1:1:tCount {
		set tEntry = ..Entries.GetAt(i)
		set $li(tValue,i) = $lb(tEntry.Master, tEntry.Relation, tEntry.Slave)
	}
	quit tValue
}

Method %EqualsInternal(pTerm As Term) As %Boolean [ Internal, Private ]
{
	set tCount = ..Entries.Count()
	quit:tCount'=pTerm.Entries.Count() 0
	set tOK = 1
	for i = 1:1:tCount {
		set tOK = (pTerm.ContainsEntry(..Entries.GetAt(i).ToString()))
		quit:'tOK
	}
	quit tOK
}

Method OnGetDisplayName(pMode As %Integer = 0) As %String [ Internal, Private ]
{
	set tCount = ..Entries.Count()
	set tDisplay = $s('pMode:"", 1:"CRCs:")
	for i = 1:1:tCount {
		set:pMode tDisplay = tDisplay _ $case(pMode, 1:$s(i=1:"", 1:"; "), 2:$c(13,10) _ " - ")
		set tDisplay = tDisplay _ "'"_..Entries.GetAt(i).Master_"' '"_..Entries.GetAt(i).Relation_"' '"_..Entries.GetAt(i).Slave_"'"
		quit:'pMode
	}
	set:('pMode)&&(tCount>1) tDisplay = tDisplay _ " ("_(tCount-1)_" more)"
	quit tDisplay
}

Method ContainsEntry(pValue As %String) As %Integer
{
	if $lv(pValue) {
		set pValue = $lts(pValue,$c(0))
	} elseif $l(pValue,":")=3 {
		set pValue = $tr(pValue,":",$c(0))
	}
	set tContainsEntry = 0
	for i = 1:1:..Entries.Count() {
		set:(..Entries.GetAt(i).ToString()=pValue) tContainsEntry = i
		quit:tContainsEntry
	}
	quit tContainsEntry
}

Method RemoveEntry(pValue As %String, Output pIsEmpty As %Boolean) As %Status
{
	set tSC = $$$OK
	try {
		set tIndex = ..ContainsEntry(pValue)
		do:tIndex ..Entries.RemoveAt(tIndex, .tSC)
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
