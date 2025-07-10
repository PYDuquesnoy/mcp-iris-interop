/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.AlarmRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// This property is deprecated, use property 'Timeout' instead
Property Duration As %String [ Calculated ];

/// This property is deprecated, use property 'Timeout' instead
Property Until As %String [ Calculated ];

/// Timeout takes both the Duration and Until specification
Property Timeout As %String;

Property DurationInSeconds As %Float;

Property DiscardOnShutdown As %Boolean [ InitialExpression = 0 ];

/// This method computes the duration-in-seconds from the current time to the set time in the future
/// It is different from the DurationInSeconds property which is a static value equal to the duration
/// from the time of the creation of the object to the set time in the future.
Method DurationInSecondsFromNow() As %Float
{
	Set tSC=##class(Ens.Util.Time).TimeoutToSeconds(i%Timeout,.tTemp)
	If $$$ISERR(tSC) Quit 0
	Quit tTemp
}

Method TimeoutSet(pTimeout As %String) As %Status
{
	Set i%Timeout=pTimeout
	Set tSC=##class(Ens.Util.Time).TimeoutToSeconds(pTimeout,.tTemp)
	If $$$ISERR(tSC) Quit tSC
	Set i%DurationInSeconds=tTemp 
	Quit $$$OK
}

Method DurationGet() As %Status
{
	if ..isDuration() quit i%Timeout
	quit ""
}

Method DurationSet(pDuration As %String) As %Status
{
	Quit ..TimeoutSet(pDuration)
}

Method UntilGet() As %Status
{
	if ..isDuration() quit ""
	quit i%Timeout
}

Method UntilSet(pTimeout As %String) As %Status
{
	Quit ..TimeoutSet(pTimeout)
}

Method isDuration() As %Boolean
{
	if i%Timeout=+i%Timeout quit 1
	quit $zcvt($e(i%Timeout,1),"u")="P"
}

Storage Default
{
<Data name="AlarmRequestDefaultData">
<Subscript>"AlarmRequest"</Subscript>
<Value name="1">
<Value>Duration</Value>
</Value>
<Value name="2">
<Value>DurationInSeconds</Value>
</Value>
<Value name="3">
<Value>Until</Value>
</Value>
<Value name="4">
<Value>DiscardOnShutdown</Value>
</Value>
<Value name="5">
<Value>Timeout</Value>
</Value>
</Data>
<DefaultData>AlarmRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
