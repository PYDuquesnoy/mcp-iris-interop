/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides the ability to synchronize on one or more asynchronous calls
Class Ens.BPL.Sync Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<sync calls="call1,call2" timeout="10" type="all"/>
}

/// This holds the comma delimited list of names of calls to wait for 
Property Calls As %String(MAXLEN = "");

/// This holds the type, 'any' = wait for any call to complete, 
/// 'all' = wait for all calls to complete
Property Type As %String [ InitialExpression = "all" ];

/// This holds the timeout
Property Timeout As %String;

/// This holds the allow-resync flag
Property AllowResync As %Boolean [ InitialExpression = 0 ];

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		$$$EnterActivity($$$ActivitySync,$$$SubActivityMain)
		
		#; Initialize the <sync> data structures
		If tLanguage=$$$objectscript {
			$$$GC(" Do ..%PendingResponses.Clear(),..%SyncResponses.Clear()")
			$$$GC(" Set ..%SyncTimedOut=0,..%PendingTimeout="""",..%PendingAlarmHandle="""",..%SyncName=""""")
		} else {
			$$$GC(" Me.%PendingResponses.Clear() : Me.%SyncResponses.Clear()")
			$$$GC(" Me.%SyncTimedOut=0 : Me.%PendingTimeout="""" : Me.%PendingAlarmHandle="""" : Me.%SyncName=""""")
		}
		
		#; If the names of the calls have been indirected, then runtime code must be generated
		If $Extract(..Calls)="@" {
			
			#; Pick out the name of the indirected variable
			Set tCalls=$Extract(..Calls,2,$Length(..Calls))
				
			#; Generate Runtime Code
			If tLanguage=$$$objectscript {
				$$$GC(" For tI=1:1:$Length("_tCalls_","","") {")
				$$$GC("    If ..%Process.IsResponsePending($Piece("_tCalls_","","",tI)) Do ..%PendingResponses.SetAt("""",$Piece("_tCalls_","","",tI))")
				$$$GC(" }")
			} else {
				$$$GC("   For tI=1 To Len("_tCalls_","","")")
				$$$GC("      If Me.%Process.IsResponsePending(Piece("_tCalls_","","",tI)) Then Me.%PendingResponses.SetAt("""",Piece("_tCalls_","","",tI))")
				$$$GC("   Next")
			}
			
			If ..Timeout'="" {
				
				#; Pick out the name of the indirected variable
				Set tCalls=$Extract(..Calls,2,$Length(..Calls))
				
				#; Make an alarm call but DO mark as the special 'timer' call
				If tLanguage=$$$objectscript {
					$$$GC(" If ..%PendingResponses.Count()>0 {")
					$$$GC("    Set %name="""",%alarmhandle=""""")
					$$$GC("    Set status=..%Process.MakeTimerCall(""_Timeout"",.%name,"_..Timeout_","_tCalls_",.%alarmhandle,"""_..Name_""")")
					$$$GC("    If $$$ISERR(status) Quit")
					$$$GC("    Do ..%PendingResponses.SetAt("""",%name) Set ..%PendingTimeout=%name,..%PendingAlarmHandle=%alarmhandle,..%SyncName="""_..Name_"""")
					$$$GC(" }")
				} else {
					$$$GC(" If Me.%PendingResponses.Count()>0 Then")
					$$$GC("   %name="""" : %alarmhandle=""""")
					$$$GC("   status=Me.%Process.MakeTimerCall(""_Timeout"",%name,"_..Timeout_","_tCalls_",%alarmhandle,"""_..Name_""")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
					$$$GC("   Me.%PendingResponses.SetAt("""",%name) : Me.%PendingTimeout=%name : Me.%PendingAlarmHandle=%alarmhandle : Me.%SyncName="""_..Name_"""")
					$$$GC(" End If")
				}
			}
			
		} else {
			
			#; Generate Compile-time Code
			For tI=1:1:$Length(..Calls,",") {
				Set tCall=$zu(144,1,$Piece(..Calls,",",tI))
				If tLanguage=$$$objectscript {
					$$$GC(" If ..%Process.IsResponsePending("_tCall_") Do ..%PendingResponses.SetAt("""","_tCall_")")
				} else {
					$$$GC("   If Me.%Process.IsResponsePending("_tCall_") Then Me.%PendingResponses.SetAt("""","_tCall_")")
				}
			}
			
			If ..Timeout'="" {
				
				If ..AllowResync=1 {
					Set tCalls=""
				} else {
					Set tCalls=..Calls
				}
				
				#; Make an alarm call but DO mark as the special 'timer' call
				If tLanguage=$$$objectscript {
					$$$GC(" If ..%PendingResponses.Count()>0 {")
					$$$GC("    Set %name="""",%alarmhandle=""""")
					$$$GC("    Set status=..%Process.MakeTimerCall(""_Timeout"",.%name,"_..Timeout_","""_tCalls_""",.%alarmhandle,"""_..Name_""")")
					$$$GC("    If $$$ISERR(status) Quit")
					$$$GC("    Do ..%PendingResponses.SetAt("""",%name) Set ..%PendingTimeout=%name,..%PendingAlarmHandle=%alarmhandle,..%SyncName="""_..Name_"""")
					$$$GC(" }")
				} else {
					$$$GC(" If Me.%PendingResponses.Count()>0 Then")
					$$$GC("   %name="""" : %alarmhandle=""""")
					$$$GC("   status=Me.%Process.MakeTimerCall(""_Timeout"",%name,"_..Timeout_","""_tCalls_""",%alarmhandle,"""_..Name_""")")
					$$$GC("   If System.Status.IsError(status) Then Exit Do")
					$$$GC("   Me.%PendingResponses.SetAt("""",%name) : Me.%PendingTimeout=%name : Me.%PendingAlarmHandle=%alarmhandle : Me.%SyncName="""_..Name_"""")
					$$$GC(" End If")
				}
			}
		}
		
		Set tNextState1=pCompiler.CurrentStateCounter.Next()
		Set tNextState2=pCompiler.CurrentStateCounter.Next()
		
		If tLanguage=$$$objectscript {
			$$$GC(" If ..%PendingResponses.Count()=0 {")
			$$$GC("    Set ..%NextState="""_tNextState2_"""")
			$$$GC(" } else {")
			$$$GC("    Set ..%NextState="""_tNextState1_""",..%Wait=1")
			$$$GC(" }")
		} else {
			$$$GC("   If Me.%PendingResponses.Count()=0 Then")
			$$$GC("      Me.%NextState="""_tNextState2_"""")
			$$$GC("   Else")
			$$$GC("      Me.%NextState="""_tNextState1_""" : Me.%Wait=1")
			$$$GC("   End If")
		}
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tNextState1,pCompiler.CurrentThread)
		
		If tLanguage=$$$objectscript {
			
			If ..Type="any" {
				
				$$$GC(" Do ..SatisfyPendingResponses()")
				$$$GC(" Do ..%PendingResponses.Clear()")
				$$$GC(" Set ..%NextState="""_tNextState2_"""")
			} else {
				$$$GC(" If ..%PendingResponses.Count()=0 {")
				$$$GC("    Set ..%NextState="""_tNextState2_"""")
				$$$GC(" } else {")
				$$$GC("    Set ..%NextState="""_tNextState1_""",..%Wait=1")
				$$$GC(" }")
			}
		} else {
			
			If ..Type="any" {
				
				$$$GC("   Me.SatisfyPendingResponses()")
				$$$GC("   Me.%PendingResponses.Clear()")
				$$$GC("   Me.%NextState="""_tNextState2_"""")
			} else {
				$$$GC("   If Me.%PendingResponses.Count()=0 Then")
				$$$GC("      Me.%NextState="""_tNextState2_"""")
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tNextState1_""" : Me.%Wait=1")
				$$$GC("   End If")
			}
		}
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tNextState2,pCompiler.CurrentThread)
		
		$$$LeaveActivity($$$ActivitySync,$$$SubActivityMain)
		
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<sync ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("calls="_$$$EA(..Calls))
		If ..Timeout'="" Do pStream.Write("timeout="_$$$EA(..Timeout))
		If ..AllowResync'=0 Do pStream.Write("allowresync='true' ")
		
		Do pStream.Write("type="_$$$EA(..Type))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</sync>")
		} else {
			Do pStream.WriteLine("/>")
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the calls we want to sync on
		If ..Calls="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"calls",..DisplayName()))
		}
		
		#; Type initial expression is "all"
		If "|all|any|"'[("|"_..Type_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLEnumeration,"type","all,any",..DisplayName()))
		}
		
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
	Quit "Sync"
}

Method AllowResyncGet() As %Boolean
{
	Quit ((i%AllowResync=1)||(i%AllowResync="true"))
}

}
