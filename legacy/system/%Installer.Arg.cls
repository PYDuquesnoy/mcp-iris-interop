/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an "Arg" activity within a Manifest document. It passes an argument into a method called via "Invoke" or "Error" activities.
Class %Installer.Arg Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Argument Value. It can be set to a constant value or a variable name to be evaluated at runtime.
Property Value As %String(MAXLEN = 32000);

}
