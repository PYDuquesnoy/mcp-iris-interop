/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.SimplePredicate Extends Predicate [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property operator As %DeepSee.PMML.Datatype.String(VALUELIST = ",equal,notEqual,lessThan,lessOrEqual,greaterThan,greaterOrEqual,isMissing,isNotMissing", XMLPROJECTION = "ATTRIBUTE");

Property value As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Method %GetComputeCode(pObj As %String) As %String
{
	quit:..operator="isMissing" $$$PropMissing(pObj,..field)
	quit:..operator="isNotMissing" "'"_$$$PropMissing(pObj,..field)
	set tFieldValue = $$$PropValue(pObj,..field)
	if ($g(%PMML("Fields",$$$PROPERTYNAME(..field),"datatype"))="boolean") { // BDB505
		set tValue = $case($$$LOWER(..value), "false":0, "true":1, :..value)
		set tFieldValue = "$case($$$LOWER("_tFieldValue_"), ""false"":0, ""true"":1, :"_tFieldValue_")"
	} else {
		set tValue = $s((..value=+..value):..value, 1:$$$QUOTE(..value))
	}
	quit "$s("_$$$PropMissing(pObj,..field)_":$c(0), 1:("_tFieldValue_$case(..operator, "equal":"=", "notEqual":"'=", "lessThan":"<", "lessOrEqual":"<=", "greaterThan":">", "greaterOrEqual":">=") _ tValue _"))"
}

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$d(pDictionary("fields", ..field)) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_..field_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if (..value="") && (..operator'="isMissing") && (..operator'="isNotMissing") {
			set tSC = $$$ERROR($$$GeneralError, "value is a required attribute for operator '"_..operator_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method SetOperatorSymbol(pSymbol As %String) As %Status
{
	quit ..operatorSet(..OperatorFromSymbol(pSymbol))
}

ClassMethod OperatorFromSymbol(pSymbol As %String) As %String
{
	quit $case(pSymbol, "=":"equal", "!=":"notEqual", "<":"lessThan", "<=":"lessOrEqual", ">":"greaterThan", ">=":"greaterOrEqual", :pSymbol)
}

ClassMethod SymbolFromOperator(pOperator As %String) As %String
{
	quit $case(pOperator, "equal":"=", "notEqual":"!=", "lessThan":"<", "lessOrEqual":"<=", "greaterThan":">", "greaterOrEqual":">=", :pOperator)
}

Method %GetAsTree(Output pTree) As %Status [ Internal ]
{
	set pTree = $lb(..field, ..operator, ..value)
	quit $$$OK
}

}
