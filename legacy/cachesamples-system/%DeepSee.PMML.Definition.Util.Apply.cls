/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Apply Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property function As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property mapMissingTo As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property invalidValueTreatment As %DeepSee.PMML.Datatype.InvalidValueTreatmentMethod(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "returnInvalid" ];

Property defaultValue As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property Expressions As list Of AbstractExpression(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$d(pDictionary("functions", ..function)) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown function: '"_..function_"'")
			quit
		}
		
		// TODO: verify datatype/optype of function corresponds to outcome of nested Expressions?
		
		for i = 1:1:..Expressions.Count() {
			set tSC = ..Expressions.GetAt(i).%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the COS code to compute this expression. Sets <var>pInline</var> to 1 if the returned
/// string can simply be nested in an enclosing expression. If <var>pInline</var> = 0, the code
/// returned is assumed to populate a variable <var>tValue</var>, with each line prepended with
/// appropriate whitespace to allow simple compilation.
Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String
{
	#define WriteLine(%s) set tCode = tCode_$c(13,10,9)_%s
	#define WriteBlock(%s) set tCode = tCode_$c(13,10)_%s
	set tFunction = ..function, tCode = ""
	
	// simple maths
	if (tFunction = "+") || (tFunction = "-") || (tFunction = "*") || (tFunction = "/") {
		
		set pInline = 0
		set tUniqueVarName = "tValue"_$i(%varNameCounter), tUniqueStatusName = "tStatus"_%varNameCounter
		for i = 1:1:..Expressions.Count() {
			set tExprCode = ..Expressions.GetAt(i).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
			if tInline {
				if (i=1) {
					$$$WriteLine("set tValue = "_tExprCode)
				} else {
					$$$WriteLine("set tValue = tValue "_tFunction_" ("_tExprCode_")")
				}
			} else {
				if (i=1) {
					$$$WriteBlock(tExprCode)
				} else {
					$$$WriteLine("set "_tUniqueVarName_" = tValue, "_tUniqueStatusName_" = $g(tStatus,""valid"")")
					$$$WriteBlock(tExprCode)
					$$$WriteLine("set tValue = "_tUniqueVarName_" "_tFunction_" tValue, tStatus = $s(tStatus=""missing"":""missing"", 1:"_tUniqueStatusName_")")
				}
			}
		}
		quit tCode
		
	} elseif (tFunction = "min") || (tFunction = "max") || (tFunction = "sum") || (tFunction = "avg") || (tFunction = "median") || (tFunction = "product") {
		
		set tUni = $i(%varNameCounter)
		set tCode = $c(9)_"set tOneValid"_tUni_" = 0", pInline = 0
		if (tFunction = "sum") {
			$$$WriteLine("set tSum"_tUni_" = 0")
		} elseif (tFunction = "avg") {
			$$$WriteLine("set tSum"_tUni_" = 0, tCount"_tUni_" = 0")
		} elseif (tFunction = "product") {
			$$$WriteLine("set tProduct"_tUni_" = 1")
		} elseif (tFunction = "min") {
			$$$WriteLine("set tMin"_tUni_" = """"")
		} elseif (tFunction = "max") {
			$$$WriteLine("set tMax"_tUni_" = """"")
		} elseif (tFunction = "median") {
			$$$WriteLine("set tCount"_tUni_" = 0")
			$$$WriteLine("kill tMedian"_tUni)
		}
		for i = 1:1:..Expressions.Count() {
			set tExprCode = ..Expressions.GetAt(i).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
			if tInline {
				$$$WriteLine("set tValue = "_tExprCode_", tStatus=""valid"", tOneValid"_tUni_"=1")
			} else {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode)
				$$$WriteLine("set:'tOneValid"_tUni_" tOneValid"_tUni_" = ($g(tStatus,""valid"")=""valid"")")
			}
			if (tFunction = "sum") {
				$$$WriteLine("set:$g(tStatus)'=""missing"" tSum"_tUni_" = tSum"_tUni_" + tValue")
			} elseif (tFunction = "avg") {
				$$$WriteLine("set:$g(tStatus)'=""missing"" tSum"_tUni_" = tSum"_tUni_" + tValue, tCount"_tUni_" = tCount"_tUni_"+1")
			} elseif (tFunction = "product") {
				$$$WriteLine("set:$g(tStatus)'=""missing"" tProduct"_tUni_" = tProduct"_tUni_" * tValue")
			} elseif (tFunction = "min") {
				$$$WriteLine("set:($g(tStatus)'=""missing"")&&((tMin"_tUni_"="""")||(tMin"_tUni_">tValue)) tMin"_tUni_" = tValue")
			} elseif (tFunction = "max") {
				$$$WriteLine("set:($g(tStatus)'=""missing"")&&((tMax"_tUni_"="""")||(tMax"_tUni_"<tValue)) tMax"_tUni_" = tValue")
			} elseif (tFunction = "median") {
				$$$WriteLine("set:$g(tStatus)'=""missing"" tCount"_tUni_" = tCount"_tUni_"+1, tMedian"_tUni_"(tValue, tCount"_tUni_")=""""")
			}
		}
		if (tFunction = "sum") {
			$$$WriteLine("set tValue = tSum"_tUni_"")
		} elseif (tFunction = "avg") {
			$$$WriteLine("set tValue = tSum"_tUni_" / tCount"_tUni)
		} elseif (tFunction = "product") {
			$$$WriteLine("set tValue = tProduct"_tUni_"")
		} elseif (tFunction = "min") {
			$$$WriteLine("set tValue = tMin"_tUni_"")
		} elseif (tFunction = "max") {
			$$$WriteLine("set tValue = tMax"_tUni_"")
		} elseif (tFunction = "median") {
			$$$WriteLine("set i=0, x="""", tValue=""""")
			$$$WriteLine("kill tMedianValue")
			$$$WriteLine("for {")
			$$$WriteLine(" set x=$order(tMedian"_tUni_"(x))")
			$$$WriteLine(" quit:x=""""")
			$$$WriteLine(" set y=""""")
			$$$WriteLine(" for {")
			$$$WriteLine("  set y=$order(tMedian"_tUni_"(x,y))")
			$$$WriteLine("  quit:y=""""")
			$$$WriteLine("  set tMedianValue($i(i)) = x")
			$$$WriteLine(" }")
			$$$WriteLine("}")
			$$$WriteLine("if (tCount"_tUni_"=1) {")
			$$$WriteLine(" set tValue = tMedianValue(1)")
			$$$WriteLine("} elseif (tCount"_tUni_"#2) {")
			$$$WriteLine(" set tValue = tMedianValue(tCount"_tUni_"/2)")
			$$$WriteLine("} else {") 
			$$$WriteLine(" set tValue = (tMedianValue(tCount"_tUni_"\2) + tMedianValue(tCount"_tUni_"\2+1))/2")
			$$$WriteLine("}")
		}
		$$$WriteLine("set tStatus = $s(tOneValid"_tUni_":""valid"", 1:""missing"")")
		quit tCode
		
	} elseif (tFunction = "log10") || (tFunction = "ln") || (tFunction = "abs") || (tFunction = "exp") || (tFunction = "not") || (tFunction = "uppercase") || (tFunction = "lowercase") || (tFunction = "trimBlanks") || (tFunction = "expm1") || (tFunction = "ln1p") || (tFunction = "sin") || (tFunction = "sin") || (tFunction = "cos") || (tFunction = "acos") || (tFunction = "tan") || (tFunction = "atan") {
		
		set tFun = $case(tFunction, "log10":"$zlog", "ln":"$zln", "abs":"$zabs", "exp":"$zexp", "not":"'", "uppercase":"$$$UPPER", "lowercase":"$$$LOWER", "trimBlanks":"$zstrip", "expm1":"$zexp", "ln1p":"$zln", "sin":"$zsin", "asin":"$zarcsin", "cos":"$zcos", "acos":"$zarccos", "tan":"$ztan", "atan":"$zarctan")
		set tArgs = $case(tFunction, "trimBlanks":",""<>WC"")", "ln1p":"+1", :"")
		set tExtra = $case(tFunction, "expm1":"-1", :"")
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.pInline, pOverrideSource, pThis, pArrayFormat)
		if pInline {
			quit tFun_"("_tExprCode_tArgs_")"_tExtra
		} else {
			$$$WriteLine("set tStatus=""valid""")
			$$$WriteBlock(tExprCode)
			$$$WriteLine("set tValue = $s($g(tStatus)=""missing"":"""", 1:"_tFun_"(tValue"_tArgs_")"_tExtra_")")
			quit tCode
		}
		
	} elseif (tFunction = "sinh") || (tFunction = "cosh") || (tFunction = "tanh") {
		
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.pInline, pOverrideSource, pThis, pArrayFormat)
		set tX = $s(pInline:tExprCode, 1:"tValue")
		if tFunction = "sinh" {
			set tHCode = "(($zexp("_tX_") - $zexp(-"_tX_"))/2)"
		} elseif tFunction = "cosh" {
			set tHCode = "(($zexp("_tX_") + $zexp(-"_tX_"))/2)"
		} elseif tFunction = "tanh" {
			set tHCode = "(1-(2/($zexp(2*"_tX_")+1)))"
		}
		if pInline {
			set tExprCode = tHCode
		} else {
			$$$WriteLine("set tStatus=""valid""")
			$$$WriteBlock(tExprCode)
			$$$WriteLine("set tValue = "_tHCode)
		}
		quit tExprCode
		
	} elseif (tFunction = "floor") || (tFunction = "round") || (tFunction = "ceil") || (tFunction = "rint") {
		
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.pInline, pOverrideSource, pThis, pArrayFormat)
		if pInline {
			quit "##class(%DeepSee.PMML.Utils.Math).CastInteger("_tExprCode_","_$$$QUOTE(tFunction)_")"
		} else {
			$$$WriteLine("set tStatus=""valid""")
			$$$WriteBlock(tExprCode)
			$$$WriteLine("set tValue = ##class(%DeepSee.PMML.Utils.Math).CastInteger(tValue,"_$$$QUOTE(tFunction)_")")
			quit tCode
		}
		
	} elseif (tFunction = "pow") {
		
		set tUni = $i(%varNameCounter)
		set tExprCode1 = ..Expressions.GetAt(1).%GetComputeCode(.tInline1, pOverrideSource, pThis, pArrayFormat)
		set tExprCode2 = ..Expressions.GetAt(2).%GetComputeCode(.tInline2, pOverrideSource, pThis, pArrayFormat)
		set pInline = 0
		if 'tInline1 {
			$$$WriteLine("set tStatus=""valid""")
			$$$WriteBlock(tExprCode1)
			$$$WriteLine("set tValue"_tUni_"x1 = tValue, tStatus"_tUni_"x1 = $g(tStatus,""valid"")")
		} else {
			$$$WriteLine("set tValue"_tUni_"x1 = "_tExprCode1_", tStatus"_tUni_"x1=""valid""")
		}
		if 'tInline2 {
			$$$WriteLine("set tStatus=""valid""")
			$$$WriteBlock(tExprCode2)
			$$$WriteLine("set tValue"_tUni_"x2 = tValue, tStatus"_tUni_"x2 = $g(tStatus,""valid"")")
		} else {
			$$$WriteLine("set tValue"_tUni_"x2 = "_tExprCode2_", tStatus"_tUni_"x2=""valid""")
		}
		$$$WriteLine("set tValue = $s((tValue"_tUni_"x1=0)&&(tValue"_tUni_"x2=0):1, 1:tValue"_tUni_"x1**tValue"_tUni_"x2)")
		$$$WriteLine("set tStatus = $s((tStatus"_tUni_"x1=""missing"")||(tStatus"_tUni_"x2=""missing""):""missing"", 1:""valid"")")
		quit tCode
		
	} elseif (tFunction = "modulo") {
		
		set tUni = $i(%varNameCounter)
		set tExprCode1 = ..Expressions.GetAt(1).%GetComputeCode(.tInline1, pOverrideSource, pThis, pArrayFormat)
		set tExprCode2 = ..Expressions.GetAt(2).%GetComputeCode(.tInline2, pOverrideSource, pThis, pArrayFormat)
		set pInline = tInline1*tInline2
		if pInline {
			quit "("_tExprCode1_" # "_tExprCode2_")"
		} else {
			if 'tInline1 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode1)
				$$$WriteLine("set tValue"_tUni_"x1 = tValue, tStatus"_tUni_"x1 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x1 = "_tExprCode1_", tStatus"_tUni_"x1=""valid""")
			}
			if 'tInline2 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode2)
				$$$WriteLine("set tValue"_tUni_"x2 = tValue, tStatus"_tUni_"x2 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x2 = "_tExprCode2_", tStatus"_tUni_"x2=""valid""")
			}
			$$$WriteLine("set tValue = tValue"_tUni_"x1 # tValue"_tUni_"x2, tStatus = $s((tStatus"_tUni_"x1=""missing"")||(tStatus"_tUni_"x2=""missing""):""missing"", 1:""valid"")")
		}
		quit tCode
		
	} elseif (tFunction = "hypot") {
		
		set tUni = $i(%varNameCounter)
		set tExprCode1 = ..Expressions.GetAt(1).%GetComputeCode(.tInline1, pOverrideSource, pThis, pArrayFormat)
		set tExprCode2 = ..Expressions.GetAt(2).%GetComputeCode(.tInline2, pOverrideSource, pThis, pArrayFormat)
		set pInline = tInline1*tInline2
		if pInline {
			quit "$zsqr(("_tExprCode1_"**2) + ("_tExprCode2_"**2))"
		} else {
			if 'tInline1 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode1)
				$$$WriteLine("set tValue"_tUni_"x1 = tValue, tStatus"_tUni_"x1 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x1 = "_tExprCode1_", tStatus"_tUni_"x1=""valid""")
			}
			if 'tInline2 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode2)
				$$$WriteLine("set tValue"_tUni_"x2 = tValue, tStatus"_tUni_"x2 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x2 = "_tExprCode2_", tStatus"_tUni_"x2=""valid""")
			}
			$$$WriteLine("set tValue = $zsqr((tValue"_tUni_"x1**2) + (tValue"_tUni_"x2**2)), tStatus = $s((tStatus"_tUni_"x1=""missing"")||(tStatus"_tUni_"x2=""missing""):""missing"", 1:""valid"")")
		}
		quit tCode
		
	} elseif (tFunction = "threshold") || (tFunction = "equal") || (tFunction = "notEqual") || (tFunction = "greaterThan") || (tFunction = "greaterOrEqual") || (tFunction = "lessThan") || (tFunction = "lessOrEqual") || (tFunction = "and") || (tFunction = "or") {
		
		set tUni = $i(%varNameCounter)
		set tOperator = $case(tFunction, "threshold":">", "equal":"=", "notEqual":"'=", "lessThan":"<", "lessOrEqual":"<=", "greaterThan":">", "greaterOrEqual":">=", "and":"&&", "or":"||")
		set tExprCode1 = ..Expressions.GetAt(1).%GetComputeCode(.tInline1, pOverrideSource, pThis, pArrayFormat)
		set tExprCode2 = ..Expressions.GetAt(2).%GetComputeCode(.tInline2, pOverrideSource, pThis, pArrayFormat)
		if tInline1 && tInline2 {
			set pInline = 1
			quit "(("_tExprCode1_")"_tOperator_"("_tExprCode2_"))"
		} else {
			set pInline = 0
			if 'tInline1 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode1)
				$$$WriteLine("set tValue"_tUni_"x1 = tValue, tStatus"_tUni_"x1 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x1 = "_tExprCode1_", tStatus"_tUni_"x1=""valid""")
			}
			if 'tInline2 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode2)
				$$$WriteLine("set tValue"_tUni_"x2 = tValue, tStatus"_tUni_"x2 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x2 = "_tExprCode2_", tStatus"_tUni_"x2=""valid""")
			}
			$$$WriteLine("set tValue = tValue"_tUni_"x1 "_tOperator_" tValue"_tUni_"x2")
			$$$WriteLine("set tStatus = $s((tStatus"_tUni_"x1=""missing"")||(tStatus"_tUni_"x2=""missing""):""missing"", 1:""valid"")")
		quit tCode
		}
		
	} elseif (tFunction = "isMissing") || (tFunction = "isNotMissing") {
		
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
		set pInline = 0
		if tInline {
			/// maybe we can just return "valid" here?
			$$$WriteLine("set tValue = "_tExprCode)
		} else {
			$$$WriteBlock(tExprCode)
		}
		$$$WriteLine("set tValue = ($g(tStatus,""valid"")"_$s(tFunction="isNotMissing":"'", 1:"")_"=""missing""), tStatus = ""valid""")
		quit tCode
	
	} elseif (tFunction = "isValid") || (tFunction = "isNotValid") {
		
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
		set pInline = 0
		if tInline {
			/// maybe we can just return "valid" here?
			$$$WriteLine("set tValue = "_tExprCode)
		} else {
			$$$WriteBlock(tExprCode)
		}
		$$$WriteLine("set tValue = ($g(tStatus,""valid"")"_$s(tFunction="isNotValid":"'", 1:"")_"=""valid""), tStatus = ""valid""")
		quit tCode
	
	} elseif (tFunction = "isIn") || (tFunction = "isNotIn") {
		
		set tUni = $i(%varNameCounter)
		set pInline = 0
		for i = 2:1:..Expressions.Count() {
			set tExprCode = ..Expressions.GetAt(i).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
			if tInline {
				$$$WriteLine("set tValue = "_tExprCode)
			} else {
				$$$WriteBlock(tExprCode)
			}
			$$$WriteLine("set:$g(tStatus)'=""missing"" tValues"_tUni_"($s(tValue="""":$c(0), 1:tValue)) = """"")
		}
		set tExprCode = ..Expressions.GetAt(1).%GetComputeCode(.tInline, pOverrideSource, pThis, pArrayFormat)
		if tInline {
			$$$WriteLine("set tValue = "_tExprCode_", tStatus = ""valid""")
		} else {
			$$$WriteLine("set tStatus = ""valid""")
			$$$WriteBlock(tExprCode)
		}
		$$$WriteLine("set tValue = "_$s(tFunction="isNotIn":"'", 1:"")_"$d(tValues"_tUni_"($s(tValue="""":$c(0), 1:tValue)))")
		quit tCode
	
	} elseif (tFunction = "if") || (tFunction = "substring") {
		
		set tExprCode1 = ..Expressions.GetAt(1).%GetComputeCode(.tInline1, pOverrideSource, pThis, pArrayFormat)
		set tExprCode2 = ..Expressions.GetAt(2).%GetComputeCode(.tInline2, pOverrideSource, pThis, pArrayFormat)
		set tExprCode3 = ..Expressions.GetAt(3).%GetComputeCode(.tInline3, pOverrideSource, pThis, pArrayFormat)
		if tInline1 && tInline2 && tInline3 {
			set pInline = 1
			if (tFunction = "if") {
				quit "$s(("_tExprCode1_"):("_tExprCode2_"), 1:("_tExprCode3_"))"
			} else {
				quit "$e("_tExprCode1_","_tExprCode2_",("_tExprCode2_")+("_tExprCode3_")-1)"
			}
		} else {
			set pInline = 0
			if 'tInline1 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode1)
				$$$WriteLine("set tValue"_tUni_"x1 = tValue, tStatus"_tUni_"x1 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x1 = "_tExprCode1_", tStatus"_tUni_"x1 = ""valid""")
			}
			if 'tInline2 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode2)
				$$$WriteLine("set tValue"_tUni_"x2 = tValue, tStatus"_tUni_"x2 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x2 = "_tExprCode2_", tStatus"_tUni_"x2 = ""valid""")
			}
			if 'tInline3 {
				$$$WriteLine("set tStatus=""valid""")
				$$$WriteBlock(tExprCode3)
				$$$WriteLine("set tValue"_tUni_"x3 = tValue, tStatus"_tUni_"x3 = $g(tStatus,""valid"")")
			} else {
				$$$WriteLine("set tValue"_tUni_"x3 = "_tExprCode3_", tStatus"_tUni_"x3 = ""valid""")
			}
			if (tFunction = "if") {
				$$$WriteLine("set tValue = $s(tValue"_tUni_"x1:tValue"_tUni_"2, 1:tValue"_tUni_"x3)")
				$$$WriteLine("set tStatus = $s((tStatus"_tUni_"x1=""missing""):""missing"", tValue"_tUni_"x1:tStatus"_tUni_"x2, 1:tStatus"_tUni_"x3)")
			} else {
				$$$WriteLine("set tValue = $e(tValue"_tUni_"x1, tValue"_tUni_"x2, tValue"_tUni_"x2+tValue"_tUni_"x3-1)")
				$$$WriteLine("set tStatus = $s((tStatus"_tUni_"x1=""missing"")||(tStatus"_tUni_"x2=""missing"")||(tStatus"_tUni_"x3=""missing""):""missing"", 1:""valid"")")
			}
			quit tCode
		}
		
	} else {
		// TODO: formatNumber, formatDatetime, dateDaysSinceYear, dateSecondsSinceYear, dateSecondsSinceMidnight
		set tSC = $$$ERROR($$$GeneralError, "function not implemented: "_tFunction)
		throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
	}
		
	// user-defined functions are currently
	quit ""
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set tSC = $$$OK
	for i = 1:1:..Expressions.Count() {
		set tSC = ..Expressions.GetAt(i).%GetInputFields(.pFields)
		quit:$$$ISERR(tSC)
	}
	quit tSC
}

}
