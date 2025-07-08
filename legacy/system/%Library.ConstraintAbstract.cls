/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %systemInclude

IncludeGenerator %systemInclude

/// Constraint root class
Class %Library.ConstraintAbstract [ Abstract, Not ProcedureBlock, System = 2 ]
{

ClassMethod Check() As %Status [ ServerOnly = 1 ]
{
 QUIT $$$ERROR($$$MethodNotImplemented,"%ConstraintAbstract::%Check")
}

}
