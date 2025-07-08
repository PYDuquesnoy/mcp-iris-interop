/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.Rule Extends node [ Deprecated, System = 3 ]
{

Property category As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property score As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property Predicate As PredicateBase(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

}
