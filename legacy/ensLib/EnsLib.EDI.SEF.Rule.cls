/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.Rule Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the condition
Property Condition As ExpressionList;

/// This holds the type
Property Type As %String;

/// This holds the setting
Property Setting As %String;

/// This holds the parameter
Property Parameter As %String;

}
