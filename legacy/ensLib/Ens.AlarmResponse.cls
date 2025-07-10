/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.AlarmResponse Extends Ens.Response [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Indicate if the timer event was interrupted
Property IsInterrupted As %Boolean;

Storage Default
{
<Data name="AlarmResponseDefaultData">
<Subscript>"AlarmResponse"</Subscript>
<Value name="1">
<Value>IsInterrupted</Value>
</Value>
</Data>
<DefaultData>AlarmResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
