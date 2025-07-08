/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Setting" activity within a Manifest document.
/// It configures an "Item" in a production by
/// making a call tothe Ens.Production:ApplySettings method.
Class %Installer.Setting Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Item name
Property Item As %String(MAXLEN = 128) [ Required ];

/// Target name
Property Target As %String(MAXLEN = 128, VALUELIST = ",Item,Host,Adapter") [ Required ];

/// Setting name
Property Setting As %String(MAXLEN = 128) [ Required ];

/// Variable value
Property Value As %String(MAXLEN = 32000) [ Required ];

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(-1)_"Set tSettings($$$EVAL("_..Item_"),$$$EVAL("_..Target_"),$$$EVAL("_..Setting_")) = $$$EVAL1("_..Value_")")
	Quit $$$OK
}

}
