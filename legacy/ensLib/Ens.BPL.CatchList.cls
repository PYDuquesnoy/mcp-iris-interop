/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a collection of one or more <catch> activies and and optional <catchall>
Class Ens.BPL.CatchList Extends Ens.BPL.NodeList [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.BPL.Catch";

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push($Piece(..#ELEMENTTYPE,".",$Length(..#ELEMENTTYPE,"."))_"List")
	Do {
		
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		/// Default override to Python if specified for Process.Language
		Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(..LanguageOverride,pCompiler.Process.Language)

		#; Going to Create a switch statement here
		Set tSwitch=##class(Ens.BPL.Switch).%New()
		$$$ASSERT($IsObject(tSwitch))
		
		#; Set a flag for the catchall, initially we haven't seen one
		Set (tSeenCatchAll,tSeenCatch)=0,tCatchAllNode=$$$NULLOREF
		
		For tI=1:1:..Count() {
			Set tNode=..GetAt(tI)
			If tNode.%ClassName()="Catch" Set tSeenCatch=1
			If tNode.%ClassName()="CatchAll" Set tSeenCatchAll=1,tCatchAllNode=tNode
		}
		
		If tSeenCatch=0 {
		
			#; Must have at least one case in a switch, so create a dummy one
			Set tCase=##class(Ens.BPL.Case).%New()
			$$$ASSERT($IsObject(tCase))
			
			#; Force the condition to 0 so that the default is executed
			Set tCase.Condition=0
			
			Do tSwitch.Cases.Insert(tCase)
		
			#; There HAS to be catch all if there are no catch activities
			$$$ASSERT(tSeenCatchAll)
				
			Set tDefault=##class(Ens.BPL.Default).%New()
			$$$ASSERT($IsObject(tDefault))
			
			Do tDefault.Activities.Insert(tCatchAllNode)
			
			Do tSwitch.Cases.Insert(tDefault)
			
		} Else {
			
			#; Have seen a catch go insert them
			For tI=1:1:..Count() {
			
				#; Insert the catch nodes
				Set tNode=..GetAt(tI)
				
				If tNode.%ClassName()="Catch" {
					
					Set tCase=##class(Ens.BPL.Case).%New()
					$$$ASSERT($IsObject(tCase))
					
					If tLanguageOverride=$$$python {
						// Inline Python code translation of instance method Ens.BPLThread::Fault
						Set tCase.Condition="iris.cls('%SYSTEM.Status').GetOneStatusText(context._LastError,1)=="_tNode.Fault_" if iris.cls('%SYSTEM.Status').Equals(context._LastError,"""_$$$EnsErrBPLThrownFault_""") else 0"

					} ElseIf tLanguage=$$$objectscript {
						Set tCase.Condition="..Fault("_tNode.Fault_")"
					} Else {
						Set tCase.Condition="Me.Fault("_tNode.Fault_")"
					}
					
					Do tCase.Activities.Insert(tNode)
					
					Do tSwitch.Cases.Insert(tCase)
				}
			}
			
			If tSeenCatchAll {
				
				Set tDefault=##class(Ens.BPL.Default).%New()
				$$$ASSERT($IsObject(tDefault))
			
				Do tDefault.Activities.Insert(tCatchAllNode)
			
				Do tSwitch.Cases.Insert(tDefault)
				
			} Else {
				
				#; No CatchAll, create handler transfer code
				
				Set tCode=##class(Ens.BPL.Code).%New()
				$$$ASSERT($IsObject(tCode))
				
				If 'pCompiler.CurrentThread.CatchStack.Empty()
				{
					if (pCompiler.CurrentThread.CatchStack.Peek(.tTransferState)) {
						
						If tLanguage=$$$objectscript {
							#; There is an enclosing catch, transfer control to that
							Do tCode.Code.WriteLine(" #; Transfer control to the enclosing fault handler")
							Do tCode.Code.WriteLine(" Set ..%NextState="""_tTransferState_"""")
							Do tCode.Code.WriteLine(" Goto Exit")
						} Else {
							Do tCode.Code.WriteLine(" #; Transfer control to the enclosing fault handler")
							Do tCode.Code.WriteLine(" Me.%NextState="""_tTransferState_"""")
							Do tCode.Code.WriteLine(" Goto Exit")
						}
						
					} Else {
						If tLanguage=$$$objectscript {
							Do tCode.Code.WriteLine(" #; No enclosing fault handler")
							Do tCode.Code.WriteLine(" Set status=context.%LastError")
						} Else {
							Do tCode.Code.WriteLine(" #; No enclosing fault handler")
							Do tCode.Code.WriteLine(" status=context.%LastError")
						}
					}
					
				} Else {
					If tLanguage=$$$objectscript {
						Do tCode.Code.WriteLine(" #; No enclosing fault handler")
						Do tCode.Code.WriteLine(" Set status=context.%LastError")
					} Else {
						Do tCode.Code.WriteLine(" #; No enclosing fault handler")
						Do tCode.Code.WriteLine(" status=context.%LastError")
					}
				}
				
				#; Create a default
				Set tDefault=##class(Ens.BPL.Default).%New()
				$$$ASSERT($IsObject(tDefault))
					
				#; The default has our 'goto' code
				Do tDefault.Activities.Insert(tCode)
					
				#; Add the default
				Do tSwitch.Cases.Insert(tDefault)
			}
		}
		
		Set tSC=tSwitch.GenerateCode(pCompiler)
		
		If $$$ISERR(tSC) Quit
		
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
