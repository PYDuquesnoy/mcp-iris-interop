/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.PredicateAND Extends PredicateBase [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "AND";

Property predicates As list Of PredicateBase(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Method %GenerateCode() As %String
{
	set tCode = "", tCount = ..predicates.Count()
	for i = 1:1:tCount {
		set tCode = tCode _$s(tCode="":"", 1:" && ")_ ..predicates.GetAt(i).%GenerateCode()
	}
	quit "("_tCode_")"
}

}
