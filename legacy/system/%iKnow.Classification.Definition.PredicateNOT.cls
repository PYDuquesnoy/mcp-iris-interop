/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.PredicateNOT Extends PredicateBase [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "NOT";

Property predicate As PredicateBase(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Method %GenerateCode() As %String
{
	quit "'"_..predicate.%GenerateCode()
}

}
