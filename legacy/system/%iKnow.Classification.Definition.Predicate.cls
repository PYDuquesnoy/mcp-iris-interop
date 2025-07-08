/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.Predicate Extends PredicateBase [ Deprecated, System = 3 ]
{

Property term As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property operator As %String(VALUELIST = ",equal,notEqual,lessThan,lessOrEqual,greaterThan,greaterOrEqual", XMLPROJECTION = "ATTRIBUTE");

Property value As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Method %GenerateCode() As %String
{
	quit "($g(pDocumentVector("_..term_"))"_$case(..operator, "equal":"=", "notEqual":"'=", "lessThan":"<", "lessOrEqual":"<=", "greaterThan":">", "greaterOrEqual":">=")_(+..value)_")"
}

}
