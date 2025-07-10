/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Allows conditions to be evaluated and actions to be performed depending
/// upon their truth value.
Class Ens.BPL.Switch Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<switch>
<case condition='context.PrimeRate=""'>
	<assign property="response.IsApproved" value="0"/>
</case>
<case condition='context.CreditRating=""'>
	<assign property="response.IsApproved" value="0"/>
</case>
<case condition='request.Nationality&#039;="USA"'>
	<assign property="response.IsApproved" value="0"/>
</case>
<case condition='context.CreditRating&lt;50'>
	<assign property="response.IsApproved" value="0"/>
</case>
<default>
<assign property="response.IsApproved" value="1"/>
<assign property="response.InterestRate" value="context.PrimeRate+2+(5*(1-(context.CreditRating/100)))"/>
</default>
</switch>
}

Property Cases As Ens.BPL.CaseList;

Method %OnNew(initvalue As %RawString) As %Status
{
	Set ..Cases=##class(Ens.BPL.CaseList).%New()
	$$$ASSERT($IsObject(..Cases))
	Quit $$$OK
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		$$$EnterActivity($$$ActivitySwitch,$$$SubActivityMain)
		
		Set tPostSwitchState=pCompiler.CurrentStateCounter.Next()

		set hadCase=0
		For tI=1:1:..Cases.Count() {
			
			Set tCase=..Cases.GetAt(tI) 
				
			If tCase.Activities.Count() {
				Set tNextState=pCompiler.CurrentStateCounter.Next()
			} else {
				Set tNextState=tPostSwitchState
			}
			
			
			If tLanguage=$$$objectscript {

				If tCase.%ClassName()="Case" {
					set hadCase=1
					/// It is the Case "Connector" that holds both expression and LanguageOverride
					/// Default override to Python if specified for Process.Language
					Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(tCase.LanguageOverride,pCompiler.Language)
					
					if tI=1 {
						// Start of Switch "Do structure"
						$$$GC("   Do {")
					} else {
						// End of previous Case
						$$$GC("     Quit") // Quit "Do structure" after setting ..%NextState
						$$$GC("   }") // Close if
					}

					#; Allows mix of python and non-python case conditions within same switch
					If $$$python=tLanguageOverride {
						// For Python expression, generates new Method on Thread that implements the expression
						// Set tValue to invocation signature "..SomeMethod(..., ...)
						set tCondition=pCompiler.GeneratePyExec(tCase.Condition,"BPLShape:Switch:",tLanguage)
					} else {
						#; This value supports the VDoc syntax
						Set tCondition=##class(Ens.VDoc.Utils).GetGetCode(tCase.Condition,tLanguage)
					}
					
					// Condition is pre-evaluated for Python or updated for VirtualDoc syntax
					// Then New standalone If block for each Case 
					$$$GC("   If ("_tCondition_") {")
				} elseif hadCase {
					// If non-Default cases have been output then close the preceeding case
					$$$GC("     Quit") // Quit Do structure
					$$$GC("   }") // Close previous If
				}
				// Line output for both Default and Non-Default 
				$$$GC("     Set ..%NextState="""_tNextState_"""")
				
			} else {
				
				If tCase.%ClassName()="Case" {
					
					#; It's a case
					 
					#; This value supports the VDoc syntax
					Set tCondition=##class(Ens.VDoc.Utils).GetGetCode(tCase.Condition,"")
					
					If tI=1 {
						$$$GC("   If ("_tCondition_") Then")
					} else {
						$$$GC("   ElseIf ("_tCondition_") Then")
					}
				} else {
					#; It's the default
					$$$GC("   Else")
				}
				$$$GC("   Me.%NextState="""_tNextState_"""")
			}
			
			#; Dont generate a case unless there are some activites to perform
			if (tCase.Activities.Count()) {
				
				Do pCompiler.StateStack.Push(tPostSwitchState)
				Do pCompiler.StateStack.Push(tNextState)
			
				Set tSC=tCase.GenerateCode(pCompiler)
				If $$$ISERR(tSC) Quit
			}
		}
		If tLanguage=$$$objectscript {
			If hadCase {
				// End of Switch "Do structure"
				// A switch is always expected in designer validation, to require at least one case. Can't just be a default.
				// Hence this line is always expected to execute for ObjectScript compilation
				$$$GC("   } while (0)")  
			}
		} else {
			$$$GC("   End If")
		}

		$$$LeaveActivity($$$ActivitySwitch,$$$SubActivityMain)
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tPostSwitchState,pCompiler.CurrentThread)
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Delegate to the cases
		Set tSC=..Cases.Validate(.pStatus,pContext)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<switch ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine(">")
		
		If ..Annotation'="" {
			Do ..GenerateAnnotation(pStream)
		}
		
		Set tSC=..Cases.GenerateXML(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine("</switch>")
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Switch"
}

}
