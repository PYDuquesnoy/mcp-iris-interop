/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Allows conditions to be evaluated and actions to be performed depending
/// upon their truth value.
Class Ens.DTL.Switch Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<switch>
<case condition='source.StringValue=""'>
	<assign property="target.StringValue" value="DNF"/>
</case>
<case condition='source.StringValue="1"'>
	<assign property="target.StringValue" value="Gold"/>
</case>
<case condition='source.StringValue="2"'>
	<assign property="target.StringValue" value="Silver"/>
</case>
<case condition='source.StringValue="1"'>
	<assign property="target.StringValue" value="Bronze"/>
</case>
<default>
	<assign property="target.StringValue" value="Finished"/>
</default>
</switch>
}

Parameter TAGNAME = "switch";

Property Cases As Ens.DTL.CaseList;

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {
		Set ..Cases=##class(Ens.DTL.CaseList).%New()
		$$$ASSERT($IsObject(..Cases))

	} Catch ex {

		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{

	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim tOpenedIf As %Boolean = 0
		#dim tI, tCase, tCondition
		#dim tOpeningIfCase = 0
		#dim tCheckMissingSrc As %Integer = 0

		Set tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		Set usePython = (($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pCompiler.Language = $$$python)))


		// this code block wraps all case.condition expressions using python ClassMethods and assigns the return values of these methods to case.condition
		// we need this as a separate loop from the next For tI=1:1:..Cases.Count() loop as we need to write Do %code.WriteLine(" "_fullcode) if it exists 
		// for each of the case.conditions (in case it turns out to be a VDoc property)
		If usePython {
			For tI=1:1:..Cases.Count() {
				Set tCase=..Cases.GetAt(tI)
				If tCase.%ClassName()="Case" {
					Do ##class(Ens.DTL.Compiler).vDocsToPythonArgs(tCase.Condition,.args,.fullcode,.rep)
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
					Set tCase.Condition = pCompiler.GeneratePyExec(rep,"DTLShape:If:",,1, pCompiler, args , newArgs)
					Kill args, newArgs, customVariablesArray
				}
			}
		}
		
		For tI=1:1:..Cases.Count() {
			Set tCase=..Cases.GetAt(tI)
			If tCase.Disabled Continue
			If tOpeningIfCase = 0 Set tOpeningIfCase = tI
			If tCase.%ClassName()="Case" {
				Set tCondition=##class(Ens.VDoc.Utils).GetGetCode(tCase.Condition,tLanguage,1)
				#; correctly resolve the collection syntax for non-VDoc references
				If (tCondition [ ".(") {
					Set tCondition = ##class(Ens.DTL.Transform).decoratePropString(tCondition)
				}
				If tCondition [ "tSCGet" {
					Do ##class(Ens.DTL.If).ConvertExtraStatusChecks(tCase.Condition,.tCondition,tLanguage)
					If $L(tCondition,"tSCGet")-1 > tCheckMissingSrc {
						Set tCheckMissingSrc = $L(tCondition,"tSCGet")-1
					}
				}

				If tI=tOpeningIfCase {
					If tLanguage=$$$objectscript {
						$$$PCIndent(pCompiler.Indent,"If ("_tCondition_") {")
						Do pCompiler.AddIndent()
					} Else {
						$$$PCIndent(pCompiler.Indent,"If ("_tCondition_") Then")
					}
					Set tOpenedIf = 1
					If tCheckMissingSrc > 0 {
						$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
						For i=2:1:tCheckMissingSrc {
							$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
						}
					}

				} else {

					If tLanguage=$$$objectscript {
						Do pCompiler.RemoveIndent()
						$$$PCIndent(pCompiler.Indent,"} elseif ("_tCondition_") {")
						Do pCompiler.AddIndent()
					} Else {
						$$$PCIndent(pCompiler.Indent,"ElseIf ("_tCondition_") Then")
					}
					If tCheckMissingSrc > 0 {
						$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
						For i=2:1:tCheckMissingSrc {
							$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
						}
					}
				}

			} else {

				#; It's the default but ought not be 1. Only code if something to write
				if tOpenedIf && (tCase.Actions.Count()) {

					If tLanguage=$$$objectscript {
						Do pCompiler.RemoveIndent()
						$$$PCIndent(pCompiler.Indent,"} else {")
						Do pCompiler.AddIndent()
					} Else {
						$$$PCIndent(pCompiler.Indent,"Else")
					}
					If tCheckMissingSrc > 0 {
						$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
						For i=2:1:tCheckMissingSrc {
							$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
						}
						// Reset to 0 so don't add unnecessary check outside of this block
						Set tCheckMissingSrc = 0
					}

				}

			}

			#; Dont generate code unless there are some activites to perform
			if (tCase.Actions.Count()) {

				Set tSC=tCase.GenerateCode(pCompiler)
				If $$$ISERR(tSC) Quit

			}

		}

		if tOpenedIf {
			If tLanguage=$$$objectscript {
				Do pCompiler.RemoveIndent()
				$$$PCIndent(pCompiler.Indent,"}")
			} else {
				$$$PCIndent(pCompiler.Indent,"End If")
			}
			// One last chance to check tSCGet values and reset to OK if all conditions failed and there was no default
			If tCheckMissingSrc > 0 {
				$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet","tSCTrans"))
				For i=2:1:tCheckMissingSrc {
					$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(tLanguage,"tSCGet"_i,"tSCTrans"))
				}
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; Delegate to the cases
		Set tSC=..Cases.Validate(.pStatus,pContext)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	#dim tSC=$$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Do pStream.Write("<switch ")

		If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))
		If ..LanguageOverride'="" Do pStream.Write(" languageOverride="_$$$EA(..LanguageOverride))

		If '..Expanded Do ..WriteExpandedAttribute(pStream)

		If ..Annotation'=""||(..Cases.Count()) {

			Do pStream.WriteLine(">")
			Do ..WriteAnnotationXML(pStream,0)

			Set tSC=..Cases.GenerateXML(pStream,language)
			If $$$ISERR(tSC) Quit

			Do pStream.WriteLine("</switch>")

		} else {

			Do pStream.WriteLine("/>")

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Switch"
}

}
