/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.CompoundPredicate Extends Predicate [ System = 3 ]
{

Property Predicates As list Of Predicate(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property booleanOperator As %DeepSee.PMML.Datatype.String(VALUELIST = ",and,or,xor,surrogate", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Method %WriteComputeCode(pVar As %String, pObj As %String, pIndent As %String, pStream As %Stream.TmpCharacter) As %Status
{
	set tCombined = "", tCount = ..Predicates.Count()
	for i = 1:1:tCount {
		set tPredicate = ..Predicates.GetAt(i)
		if (tPredicate.%Extends($classname())) {
			do tPredicate.%WriteComputeCode(pVar_i, pObj, pIndent, pStream)
			do pStream.Write(pIndent_"set x = $i("_pVar_"U("_pVar_i_"))")
		} else {
			do pStream.WriteLine(pIndent_"set "_pVar_i_" = "_tPredicate.%GetComputeCode(pObj)_", x = $i("_pVar_"U("_pVar_i_"))")
		}
		
		if (..booleanOperator="surrogate") {
			if (i<tCount) {
				set tCombined = tCombined _ pVar_i_"'=$c(0):"_pVar_i_", "
			} else {
				set tCombined = "$s("_tCombined_"1:"_pVar_i_")"
			}
		} else {
			set tOperator = $case(..booleanOperator, "and":"&&", "or":"||", "xor":"+")
			set tCombined = tCombined _ $s(tCombined="":"", 1:" "_tOperator_" ") _ "$s("_pVar_i_"=$c(0):0, 1:"_pVar_i_")"
		}
	}
	do pStream.Write(pIndent_"set "_pVar_" = "_tCombined)
	if (..booleanOperator="and") {
		do pStream.Write("  set:$d("_pVar_"U($c(0)))&&'$d("_pVar_"U(0)) "_pVar_" = $c(0)")
	} elseif (..booleanOperator="or") {
		do pStream.Write("  set:$d("_pVar_"U($c(0)))&&'$d("_pVar_"U(1)) "_pVar_" = $c(0)")
	} elseif (..booleanOperator="xor") {
		do pStream.Write("  set:$d("_pVar_"U($c(0))) "_pVar_" = $c(0)")
	} elseif (..booleanOperator="surrogate") {
		do pStream.Write("  set:$d("_pVar_"U($c(0))) mvc = mvc + 1")
	}
	do pStream.WriteLine("  kill "_pVar_"U")
	quit $$$OK
}

Method %GetAsTree(Output pTree) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pTree
		set pTree = ..booleanOperator
		for i = 1:1:..Predicates.Count() {
			kill tTree
			set tSC = ..Predicates.GetAt(i).%GetAsTree(.tTree)
			quit:$$$ISERR(tSC)
			merge pTree(i) = tTree
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
