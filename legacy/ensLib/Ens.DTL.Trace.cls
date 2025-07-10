/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides the ability to generate a trace message during
/// execution of a data transformation
Class Ens.DTL.Trace Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<trace value="This is a message"/>
}

Parameter TAGNAME = "trace";

/// This holds the value to assign to the property
Property Value As %String;

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tLanguage=$$$sysLangFromDTL(pCompiler.Language)
		$$$ASSERT(tLanguage=$$$objectscript||(tLanguage=$$$basic))

		Set usePython = (($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pCompiler.Language = $$$python)))
		If usePython  {
					Do ##class(Ens.DTL.Compiler).vDocsToPythonArgs(..Value,.args,.fullcode,.rep)
					If args Do pCompiler.Implementation.WriteLine(" ; ===== Start of args for python Trace Block ")
					For counter = args:-1:1 {
						Set codeLine = "Set arg"_counter_" = "_args(counter)
						Set codeLine = ##class(Ens.DTL.Transform).decoratePropString(codeLine)
						Set codeLine = ##class(Ens.VDoc.Utils).GetGetCode(codeLine,tLanguage,1)
						Do %code.WriteLine(" "_codeLine)
						If (codeLine [ "tSCGet") {
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
					Set ..Value = pCompiler.GeneratePyExec(rep,"DTLShape:Trace:",,1, pCompiler, args , newArgs)
					Kill args, newArgs, customVariablesArray

				}
		#; This value supports the VDoc syntax
		Set ..Value=##class(Ens.VDoc.Utils).GetGetCode(..Value,tLanguage,1)

		If tLanguage=$$$objectscript {
			$$$PCIndent(pCompiler.Indent,"Do ##class(Ens.Util.Trace).WriteTrace(""user"","""_pCompiler.ClassName_""",""Transform"","_..Value_")")
		} else {
			$$$PCIndent(pCompiler.Indent,"""Ens.Util.Trace"".WriteTrace(""user"","""_pCompiler.ClassName_""",""Transform"","_..Value_")")
		}
		If ..Value["tSCGet" {
			$$$PCIndent(pCompiler.Indent,$$$GenerateIgnoreMissingSource(pCompiler.Language,"tSCGet","tSCTrans"))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set tSC=$$$OK
	Try {
		Do pStream.Write("<trace ")
	
		Do pStream.Write("value="_$$$EA(..Value))
		If ..Disabled Do pStream.Write("disabled="_$$$EA(1))
		If ..LanguageOverride'="" Do pStream.Write(" languageOverride="_$$$EA(..LanguageOverride))
			
		Do ..WriteAnnotationXML(pStream,1)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Serialize this transform for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Do pStream.Write(..%ClassName()_..#SDELIM_$ZCVT(..Value,"I","HTML")_$Char(1))
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Set pState = $ZCVT(pState,"O","HTML")
	Set ..Value = $P(pState,..#SDELIM,2,99999)
	Quit $$$OK
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.DTL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the value we want to trace
		If ..Value="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrDTLNodeValidation,"value",..DisplayName()))
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Trace"
}

}
