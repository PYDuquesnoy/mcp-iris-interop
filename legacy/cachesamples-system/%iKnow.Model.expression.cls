/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a reusable "expression" which can be referred to using 
/// %expression.<i>expressionName</i> in this domain definition.
Class %iKnow.Model.expression Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Relationship domain As %iKnow.Model.domain(XMLPROJECTION = "none") [ Cardinality = one, Inverse = expressions ];

/// Name of the expression, which can be referred to using "%expression.<i>name</i>" onwards
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Value of this expression. This can refer to other (previously) defined expression or domain
/// class methods.
Property value As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Whether or not values passed through %Build() at runtime should be accepted as values for this
/// parameter. If no value is specified at runtime, <property>value</property> is still used by default.
Property acceptRuntimeParameter As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "'name' is a required attribute for <expression>")
			quit
		}
		
		// verify if the name is unique
		set tCount = 0
		for i = 1:1:..domain.expressions.Count() {
			set tExpression = ..domain.expressions.GetAt(i)
			set:tExpression.name=..name tCount = tCount+1
			set:'tCount tPrior(tExpression.name) = ""
		}
		if (tCount > 1) {
			set tSC = $$$ERROR($$$GeneralError, "Duplicate <expression> name: '"_..name_"'")
			quit
		}
		
		// verify dependencies exist
		set tSC = ##class(%iKnow.DomainDefinition).%ParseExpression("", ..value,, .tDependencies) 
		quit:$$$ISERR(tSC)
		set tDep = ""
		for {
			set tDep = $order(tDependencies(tDep))
			quit:tDep=""
			
			if '$d(tPrior(tDep)) {
				set tSC = $$$ERROR($$$GeneralError, "Expression '"_..name_"' depends on another expression '"_tDep_"' which should be defined before '"_..name_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
