/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a stemmer configuration using the Hunspell plugin directly.
/// Unless you want to specify a non-default Hunspell library explicitly, use the default
/// stemming configuration ("DEFAULT"). See <class>%iKnow.Stemming.DefaultStemmer</class>.
Class %iKnow.Stemming.HunspellConfig Extends %iKnow.Stemming.Configuration [ Deprecated, System = 4 ]
{

/// Full path to the Hunspell affix file (.aff)
Property AffixFile As %String(MAXLEN = 2000) [ Required ];

/// Full path to the Hunspell dictionary file (.dic)
Property DictionaryFile As %String(MAXLEN = 2000) [ Required ];

Method CreateStemmerObject(Output pStemmer As %iKnow.Stemmer) As %Status
{
	set tSC = $$$OK
	try {
		set pStemmer = ##class(%iKnow.Stemming.HunspellStemmer).%New()
		set pStemmer.AffixFile = ..AffixFile
		set pStemmer.DictionaryFile = ..DictionaryFile
		do pStemmer.Load()
	} catch (ex) {
		set tSC = ex.AsStatus()
		try { set pStemmer = "" } catch {}
	}
	quit tSC
}

Storage Default
{
<Data name="StemmerConfigDefaultData1">
<Subscript>"StemmerConfig"</Subscript>
<Value name="1">
<Value>AffixFile</Value>
</Value>
<Value name="2">
<Value>DictionaryFile</Value>
</Value>
</Data>
<DefaultData>StemmerConfigDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
