/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Table to which custom disambiguation rules can be added to influence the default stemmer class 
/// (<class>%iKnow.Stemming.DefaultStemmer</class>). See also <class>%iKnow.Stemming.Utils</class>.
Class %iKnow.Stemming.Rule Extends %Persistent [ Deprecated, System = 4 ]
{

/// The plugin to which this rule applies (use "All" for all plugin types)
Property Plugin As %String(VALUELIST = ",All,Hunspell") [ Required ];

/// Type of disambiguation rule
Property Type As %String(VALUELIST = ",Exception,Ending,Affix") [ Required ];

/// Specification of the rule, whether it applies (only) to concepts or relationships.
/// When type=Exception: the role of the entity in which case the exception applies.
/// When type'=Exception: whether tems satisfying this rule are Not-a-Concept or Not-a-Relation
Property Spec As %String(VALUELIST = ",Relation,Concept,NoRelation,NoConcept");

/// Language for which this rules holds
Property LanguageCode As %String(MAXLEN = 2) [ Required ];

/// Value of the exception or ending this rule represents
Property Value As %String(MAXLEN = 100) [ Required ];

/// For exceptions, what to replace <property>Value</property> with
Property Replace As %String(MAXLEN = 100) [ Required ];

/// For advanced exceptions, this value should appear in the entity being stemmed for the rule to apply.
Property Entity As %String(MAXLEN = 200);

Storage Default
{
<Data name="RuleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Plugin</Value>
</Value>
<Value name="4">
<Value>Spec</Value>
</Value>
<Value name="5">
<Value>Value</Value>
</Value>
<Value name="6">
<Value>Language</Value>
</Value>
<Value name="7">
<Value>LanguageCode</Value>
</Value>
<Value name="8">
<Value>Replace</Value>
</Value>
<Value name="9">
<Value>Entity</Value>
</Value>
</Data>
<DataLocation>^IRIS.IS.StemmingRuleD</DataLocation>
<DefaultData>RuleDefaultData</DefaultData>
<IdLocation>^IRIS.IS.StemmingRuleD</IdLocation>
<IndexLocation>^IRIS.IS.StemmingRuleI</IndexLocation>
<StreamLocation>^IRIS.IS.StemmingRuleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
