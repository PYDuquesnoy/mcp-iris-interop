/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple configuration object for the <class>%iKnow.Stemming.TextStemmer</class> class, which
/// wraps the <class>%Text.Text</class> Standardize() method. Use <property>DefaultLanguage</property>
/// to identify the language for which the %Text class should be instantiated.
Class %iKnow.Stemming.TextConfig Extends %iKnow.Stemming.Configuration [ Deprecated, System = 4 ]
{

Property DefaultLanguage As %String;

/// Instantiates a stemmer object based on the current object's configuration.
Method CreateStemmerObject(Output pStemmer As %iKnow.Stemmer) As %Status
{
	set pStemmer = ##class(%iKnow.Stemming.TextStemmer).%New(..DefaultLanguage)
	quit $s($isobject(pStemmer):$$$OK, 1:$g(%objlasterror))
}

Storage Default
{
<Data name="TextConfigDefaultData">
<Subscript>"TextConfig"</Subscript>
<Value name="1">
<Value>DefaultLanguage</Value>
</Value>
</Data>
<DefaultData>TextConfigDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
