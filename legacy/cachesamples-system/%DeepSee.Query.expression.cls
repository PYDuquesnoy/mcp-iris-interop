/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines an expression within a DeepSee query.<br/>
/// An expression belongs to a <class>set</class>.
/// Though an expression is a group, it only makes use of its first two children.
Class %DeepSee.Query.expression Extends group [ System = 3 ]
{

/// Logical operator that is applied to the children of this expression.
/// This can be an operator (such as "+", or a SCALAR function, such as "SQRT").
Property operator As %DeepSee.Datatype.string(MAXLEN = 25, XMLPROJECTION = "attribute");

/// Set true if this operator is a scalar function.
Property isScalarFunction As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If this operator is a scalar function, this is the number of expected arguments.
/// This takes the form "arguments:optional arguments".
Property scalarArgCount As %String(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Axis label used for this expression.
Property label As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "Expression" ];

/// Format string to apply to this member.
Property formatString As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Solve order to apply to this expression (applied from outer calcMember).
Property solveOrder As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Return the type of this node.<br/>
Method %GetType() As %String
{
	Quit $$$dstExpression
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	// we should have 2 and only 2 children
	Set tText = ""

	Set tChild1 = ..children.GetAt(1)
	Set tChild2 = ..children.GetAt(2)

	If (..isScalarFunction) {
		// scalar function
		Set tText = ..operator _ "("
		For n=1:1:..children.Count() {
			Set tText = tText _ $S(n>1:",",1:"") _ ..children.GetAt(n).%ToString(.pSC)
		}
		Set tText = tText_")"
	}
	ElseIf ($IsObject(tChild1) && $IsObject(tChild2)) {
		If ((..operator="*")||(..operator="/"))||(..operator="+")||(..operator="-") {
			// DTB624 - Wrap child expressions in parens.
			Set tChild1Text = tChild1.%ToString(.pSC)
			If $$$ISERR(pSC) Quit ""
			If tChild1.%IsA("%DeepSee.Query.expression") {
				Set tChild1Text = "(" _ tChild1Text _ ")"
			}
			
			Set tChild2Text = tChild2.%ToString(.pSC)
			If $$$ISERR(pSC) Quit ""
			If tChild2.%IsA("%DeepSee.Query.expression") {
				Set tChild2Text = "(" _ tChild2Text _ ")"
			}
			
			Set tText = tChild1Text _ ..operator _ tChild2Text
		}
		Else {
			Set tOp = $Case(..operator,"AND":" AND ","OR":" OR ","NOP":" NOP ",:..operator)
			Set tText = "("_tChild1.%ToString(.pSC)_tOp_tChild2.%ToString(.pSC)_")"
		}
	}
	Quit tText
}

/// Execute and build the axes output for this expression.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// add node to axis tree
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("exp",pVisible,1,pParent,..label,..operator)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set:..formatString'="" $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pNodeNo),12) = ..formatString
		// JMD1504
		Set:+..solveOrder'=0 $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pNodeNo),15) = +..solveOrder

		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
		Set tSetNode = pNodeNo

		// there should be two children
		Set tChildCount = ..children.Count()
		If (..isScalarFunction) {
			Set tMinArgs = +$P(..scalarArgCount,":",1)
			Set tMaxArgs = $S(..scalarArgCount[":":+$P(..scalarArgCount,":",2),1:tMinArgs)
			If ((tChildCount<tMinArgs)||(tChildCount>tMaxArgs)) {
				Set tSC = $$$ERROR($$$GeneralError,"Scalar function has wrong number of arguments: " _ ..operator)
				Quit
			}
		}
		ElseIf (tChildCount'=2) {
			Set tSC = $$$ERROR($$$GeneralError,"Expression must have 2 child nodes: '" _ ..operator _ "'")
			Quit
		}

		Set tShowIntermediate = 1 // turn this on or else simple expressions fail
		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			// JMD931: test types of children
			If (..operator'="NOP") {
				If (tChild.%IsA("%DeepSee.Query.set")) {
					If ('tChild.%IsA("%DeepSee.Query.calculatedMember")&&'tChild.%IsA("%DeepSee.Query.tuple")) {
						Set tSC = $$$ERROR($$$GeneralError,"Expression cannot be applied to a set: '" _ tChild.%ToString() _ "'")
						Quit
					}
				}
				ELseIf (tChild.%IsA("%DeepSee.Query.function")) {
					Set tType = tChild.%GetType()
					Set tIsError = $Case(tType,$$$dstSet:"set",:"")
					If (tIsError'="") {
						Set tSC = $$$ERROR($$$GeneralError,"Expression cannot be applied to a "_tIsError_": '" _ tChild.%ToString() _ "'")
						Quit
					}
				}
			}

			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo,.tNewNodeNo,tSetNode,tShowIntermediate)
			If $$$ISERR(tSC) Quit
			// hide child node and its children
			
			// +DTB400 - Hide the top aggregate node for the parent
			Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo))
			If $LG(tNodeInfo,24)'="" {
				Set tChildNodeNo = $LG(tNodeInfo,24)
			}
			Else {
				Set tChildNodeNo = tNewNodeNo
			}
			// -DTB400

			
			Set tSC = ..%HideNode(tCubeIndex,pKey,%axis,tChildNodeNo)
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// JMD887
		If ($$$UPPER(..operator)="LOOKUP") {
			Set tTermList = ..children.GetAt(1).%GetValue()
			// note use of termlist in this axis (even if the termlist does not exist!)
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"termlist",$$$UPPER(tTermList)) = $G(^DeepSee.TermList($$$UPPER(tTermList),"modDate"))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process the filter output for this expression.
Method %ProcessFilter(ByRef pFilterTree As %List, pCube As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// add node to filter tree
		Set pFilterTree($I(pNodeNo)) = $LB("exp",..operator)
		Set pFilterTree(pParent,"ch",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set tSetNode = pNodeNo

		// there should be two children
		Set tChildCount = ..children.Count()
		If (..isScalarFunction) {
			Set tMinArgs = +$P(..scalarArgCount,":",1)
			Set tMaxArgs = $S(..scalarArgCount[":":+$P(..scalarArgCount,":",2),1:tMinArgs)
			If ((tChildCount<tMinArgs)||(tChildCount>tMaxArgs)) {
				Set tSC = $$$ERROR($$$GeneralError,"Scalar function has wrong number of arguments: " _ ..operator)
				Quit
			}
		}
		ElseIf (tChildCount'=2) {
			Set tSC = $$$ERROR($$$GeneralError,"Expression must have 2 child nodes")
			Quit
		}

		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			Set tSC = tChild.%ProcessFilter(.pFilterTree,pCube,.pNodeNo,.tNewNodeNo,tSetNode)
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
