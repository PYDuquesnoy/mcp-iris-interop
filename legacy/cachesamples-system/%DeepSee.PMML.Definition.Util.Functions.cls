/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Functions [ System = 3 ]
{

ClassMethod IsBuiltIn(pFunction As %String) As %Boolean
{
	do ..AddToDictionary(.tDict)
	quit $g(tDict("functions",pFunction))="built-in"
}

ClassMethod AddToDictionary(ByRef pDictionary) As %Status
{
    set pDictionary("functions","+") = "built-in"
    set pDictionary("functions","-") = "built-in"
    set pDictionary("functions","*") = "built-in"
    set pDictionary("functions","/") = "built-in"
    
    set pDictionary("functions","min") = "built-in"
    set pDictionary("functions","max") = "built-in"
    set pDictionary("functions","sum") = "built-in"
    set pDictionary("functions","avg") = "built-in"
    set pDictionary("functions","median") = "built-in"
    set pDictionary("functions","product") = "built-in"
    
    set pDictionary("functions","log10") = "built-in"
    set pDictionary("functions","ln") = "built-in"
    set pDictionary("functions","sqrt") = "built-in"
    set pDictionary("functions","abs") = "built-in"
    set pDictionary("functions","exp") = "built-in"
    set pDictionary("functions","pow") = "built-in"
    set pDictionary("functions","threshold") = "built-in"
    set pDictionary("functions","floor") = "built-in"
    set pDictionary("functions","ceil") = "built-in"
    set pDictionary("functions","round") = "built-in"
    
    set pDictionary("functions","isMissing") = "built-in"
    set pDictionary("functions","isNotMissing") = "built-in"
    
    set pDictionary("functions","equal") = "built-in"
    set pDictionary("functions","notEqual") = "built-in"
    set pDictionary("functions","lessThan") = "built-in"
    set pDictionary("functions","lessOrEqual") = "built-in"
    set pDictionary("functions","greaterThan") = "built-in"
    set pDictionary("functions","greaterOrEqual") = "built-in"
    
    set pDictionary("functions","isIn") = "built-in"
    set pDictionary("functions","isNotIn") = "built-in"
    
    set pDictionary("functions","and") = "built-in"
    set pDictionary("functions","or") = "built-in"
    
    set pDictionary("functions","not") = "built-in"
    
    set pDictionary("functions","if") = "built-in"
    
    set pDictionary("functions","uppercase") = "built-in"
    set pDictionary("functions","lowercase") = "built-in"
    set pDictionary("functions","substring") = "built-in"
    set pDictionary("functions","trimBlanks") = "built-in"
    
    set pDictionary("functions","formatNumber") = "built-in"
    set pDictionary("functions","formatDatetime") = "built-in"
    
    set pDictionary("functions","dateDaysSinceYear") = "built-in"
    set pDictionary("functions","dateSecondsSinceYear") = "built-in"
    set pDictionary("functions","dateSecondsSinceMidnight") = "built-in"
    
    quit $$$OK
}

}
