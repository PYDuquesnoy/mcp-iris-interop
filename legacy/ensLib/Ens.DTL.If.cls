/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the If Action. A supplied condition expression is evaluated. If the condition evaluates to true
/// the sequence of activities defined within the True activity list are executed. If the conditions evaluates to false then
/// the sequence of activities defined within the False activity list are exectued. At least one of the True or False activity
/// lists MUST be none empty.
Class Ens.DTL.If Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<if condition="1">
 <true>
 	<trace value="condition evaluates to true"/>
 </true>
 <false>
 	<trace value="condition evaluates to false"/>
 </false>
</if>
}

Parameter TAGNAME = "if";

/// This holds the selection condition
Property Condition As %String;

/// This holds the activities to be performed if the condition
/// evaluates to true
Property True As Ens.DTL.ActionList;

/// This holds the activities to be performed if the condition
/// evaluates to be false
Property False As Ens.DTL.ActionList;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		Set tCondition = ..Condition
		Set usePython = (($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pCompiler.Language = $$$python)))
		If usePython  {
					Do ##class(Ens.DTL.Compiler).vDocsToPythonArgs(tCondition,.args,.fullcode,.rep)
					Set argsComparedToEmptyStrings = ##class(Ens.DTL.Compiler).findEmptyStringComparisons(rep)
					If args Do pCompiler.Implementation.WriteLine(" ; ===== Start of args for python If Block ")
					For counter = args:-1:1 {
						Set codeLine = "Set arg"_counter_" = "_args(counter)
						Set codeLine = ##class(Ens.DTL.Transform).decoratePropString(codeLine)
						Set codeLine = ##class(Ens.VDoc.Utils).GetGetCode(codeLine,tLanguage,1)
						Do %code.WriteLine(" "_codeLine)
						If (codeLine [ "tSCGet") && (argsComparedToEmptyStrings.GetAt("arg"_counter) = "") {
							$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
						}
					}		
					Set rep = ##class(Ens.DTL.Transform).decoratePropString(rep)

					Set customVariablesArray = ##class(Ens.DTL.Compiler).parsePyExpression(rep)
					Set newArgs = ##class(%ListOfDataTypes).%New()
					Set currArg=""
					For  {
						Set value=customVariablesArray.GetNext(.currArg)  
						Quit:currArg="" 
						If $DATA(pCompiler.ContextCustomVariables(currArg)) {
							// newArgs will have the arguments at the intersection of customVariablesArray and pCompiler.ContextCustomVariables. This is important to account
							// for duplicates as well as stray argument names that might either be generated in ##class(Ens.DTL.Compiler).parsePyExpression() or pCompiler.ContextCustomVariables(). 
							Do newArgs.Insert(currArg)
						}
					}
					Set tCondition = pCompiler.GeneratePyExec(rep,"DTLShape:If:",,1, pCompiler, args , newArgs)
					Kill args, newArgs, customVariablesArray

				}

		#; replace {} with document interface API
		Set tCondition = ##class(Ens.VDoc.Utils).GetGetCode(tCondition,tLanguage,1)

		#; correctly resolve the collection syntax for non-VDoc references
		If (tCondition [ ".(") {
			Set tCondition = ##class(Ens.DTL.Transform).decoratePropString(tCondition)
		}
		Set tStartIf = $select(tLanguage = $$$objectscript: "{", 1: "Then")
		Set tEndIf = $select(tLanguage = $$$objectscript: "}", 1: "End If")
		Set tCheckMissingSrc = 0
		If tCondition [ "tSCGet"  {
			Do ..ConvertExtraStatusChecks(..Condition,.tCondition,tLanguage)
			Set tCheckMissingSrc = $L(tCondition,"tSCGet")-1
		}
		
		#; <true> only
		If (..True.Count()>0 && (..False.Count() = 0))
		{
			$$$PCIndent(pCompiler.Indent,"If ("_tCondition_") " _ tStartIf)
			Do pCompiler.AddIndent()
			#; Clean up before doing any processing within the block
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
			Set tSC=..True.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,tEndIf)
			#; Clean up following the block in case result was false and we haven't already cleaned up
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
		} 
		#; <false> only
		elseif (..False.Count()>0 && (..True.Count() = 0))
		{	
			Set tFalseCondition = $select(tLanguage = $$$objectscript: "('("_tCondition_"))", 1: "Not ("_tCondition_")")
			$$$PCIndent(pCompiler.Indent,"If "_tFalseCondition_tStartIf)
			Do pCompiler.AddIndent()
			#; Clean up before doing any processing within the block
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
			Set tSC=..False.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,tEndIf)
			#; Clean up following the block in case result was true and we haven't already cleaned up
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
		} 
		else 
		#; <true> and <false>
		{
			Set tElse = $select(tLanguage = $$$objectscript: "} Else {", 1: "Else")
			$$$PCIndent(pCompiler.Indent,"If ("_tCondition_") " _ tStartIf)
			Do pCompiler.AddIndent()
			#; Clean up before doing any processing within the block
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
			Set tSC=..True.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,tElse)
			Do pCompiler.AddIndent()
			#; Clean up before doing any processing within the block
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
			Set tSC=..False.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
			Do pCompiler.RemoveIndent()
			$$$PCIndent(pCompiler.Indent,tEndIf)
		} 
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	Set tSC=$$$OK
	Try {
		Do pStream.Write("<if ")
		
		#; Generate the condition
		Do pStream.Write("condition="_$$$EA(..Condition))
		If ..Disabled Do pStream.Write("disabled="_$$$EA(1))
		If ..LanguageOverride'="" Do pStream.Write(" languageOverride="_$$$EA(..LanguageOverride))
		If '..Expanded Do ..WriteExpandedAttribute(pStream)
		Do pStream.WriteLine(">")
		
		Do ..WriteAnnotationXML(pStream,0)
		
		#; The Schema ensures that there is at most one <true> or <false> element
		#; and requires that at least one <true> or <false> element be present
		If ..True.Count() {
			
			#; Generate the optional <true> activity list
			Do pStream.WriteLine("<true>")
			Set tSC=..True.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit
			Do pStream.WriteLine("</true>")
		}
		
		If ..False.Count() {
			
			#; Generate the optional <false> activity list
			Do pStream.WriteLine("<false>")
			Set tSC=..False.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit
			Do pStream.WriteLine("</false>")
		}
		
		if (..True.Count() = 0 && (..False.Count() = 0)) {
			
			#; Generate empty <true> and <false> tags to satify schema
			Do pStream.WriteLine("<true/>")
			Do pStream.WriteLine("<false/>")
		}
		
		Do pStream.WriteLine("</if>")
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set tSC=$$$OK
	Try {
		Set ..True=##class(Ens.DTL.ActionList).%New()
		$$$ASSERT($IsObject(..True))
		
		Set ..False=##class(Ens.DTL.ActionList).%New()
		$$$ASSERT($IsObject(..False))
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Must know the condition we want to test
		If ..Condition="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"condition",..DisplayName()))
		}
		
		#; Both true and false should be validated
		Set tSC=..True.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
		
		Set tSC=..False.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "If"
}

/// If there are any tSCGet statuses being set that should not be, due to the value being compared against "", remove them
/// If there are multiple tSCGet statuses being set, give each a distinct name so that their values can be checked later
ClassMethod ConvertExtraStatusChecks(pConditionAsCondition As %String, ByRef pConditionAsCode As %String, pLanguage As %String = {$$$objectscript}) [ Internal ]
{
	Quit:(pConditionAsCode '[ "tSCGet")
	Set tCondition = $Replace(pConditionAsCondition,"'","!")
	If pLanguage '= $$$objectscript {
		Set tCondition = $Replace(tCondition,"<>","!=")
		Set tConditionU = $zcvt(tCondition,"U")
		If (tConditionU [ "AND") || (tConditionU [ "OR") {
			Set tLoc = 0
			Set offset = 0
			For {
				Set tLocAND = $FIND(tConditionU,"AND",tLoc)
				Set tLocOR = $FIND(tConditionU,"OR",tLoc)
				If (tLocAND+tLocOR = 0) Quit
				If (tLocOR=0) || ((tLocAND'=0) && (tLocAND < tLocOR)) {
					Set $E(tCondition,tLocAND-offset-3,tLocAND-offset-1) = "&&"
					Set tLoc = tLocAND
					Do $I(offset)
				} Else {
					Set $E(tCondition,tLocOR-offset-2,tLocOR-offset-1) = "||"
					Set tLoc = tLocOR
				}
			}
		}
	}
	If $$$ISOK(##class(Ens.Rule.Model.expression).parse(tCondition,.tModel,0)) && (tModel.errorText = "") {
		Set tSC = ..IdentifyUnnecessarySCs(tModel,.tStatusCodes)
		If $$$ISERR(tSC) {
			// Avoid clearing out tSCGet if the result may not be correct
			Kill tStatusCodes
		}
	}

	Set tTSCGetTotal= $L(pConditionAsCode,"tSCGet")-1
	Set tTSCGetCount = 0
	Set tRemaining = $P(pConditionAsCode,"tSCGet",2,*)
	Set pConditionAsCode = $P(pConditionAsCode,"tSCGet",1)
	For i=1:1:tTSCGetTotal {
		// Remove the tSCGet if we found that this value is being compared against ""
		If $G(tStatusCodes(i),1)=0 {
			If pLanguage=$$$objectscript {
				// Remove .tSCGet
				Set pConditionAsCode = $E(pConditionAsCode,1,*-1)
			}
			// Just remove tSCGet
		} Else {
			// Modify tSCGet to tSCGet2, etc.
			Set pConditionAsCode = pConditionAsCode_"tSCGet"_$S($I(tTSCGetCount)>1:tTSCGetCount,1:"")
		}
		Set pConditionAsCode = pConditionAsCode_$P(tRemaining,"tSCGet")
		Set tRemaining = $P(tRemaining,"tSCGet",2,*)
	}
	Set pConditionAsCode = pConditionAsCode_tRemaining
}

ClassMethod IdentifyUnnecessarySCs(pModel As Ens.Rule.Model.expression, pStatusCodes = "") As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK

	If $Case(pModel.operator, "||":1,"&&":1,:0) {
		Set pos = 0
		Set:$Case($D(pStatusCodes),"11":1,"10":1,:0) pos = $O(pStatusCodes(""),-1)
		For i=1:1:pModel.operands.Count() {
			Kill tStatusCodes
			Set tSC = ..IdentifyUnnecessarySCs(pModel.operands.GetAt(i),.tStatusCodes)	Quit:$$$ISERR(tSC)
			Set tCount = ""
			For {
				Set tCount = $O(tStatusCodes(tCount),1,keep)	Quit:""=tCount
				Set pStatusCodes($i(pos)) = keep
			}
		}
	} Else {
		If ($Case(pModel.operator,"=":1,"!=":1,:0)) && ((pModel.operands.Count() = 2) && ((pModel.operands.GetAt(1).value = """""") || (pModel.operands.GetAt(2).value = """"""))) {
			Set pStatusCodes(1) = 0
		} Else {
			Set tSC = pModel.constructCOS(.tCode)
			#; Guard against expression parsing not returning code
			If $Data(tCode)#2 {
				Set tCount = $L(tCode,".GetValueAt(")-1
				For i=1:1:tCount {
					Set pStatusCodes(i) = 1
				}
			}
		}
	}
	Quit tSC
}

}
