/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.Expression Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the variable
Property Variable As %String;

/// This holds the Operator 
Property Operator As %String;

/// This holds the value
Property Value As %String;

/// This holds the Seperator if there is a previous expression in the list
Property Separator As %String;

}
