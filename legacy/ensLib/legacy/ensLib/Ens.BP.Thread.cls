/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

/// This class represents a thread of control with a business process 
Class Ens.BP.Thread Extends %Persistent [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// This holds a reference to the process
Property %Process As Ens.BusinessProcess [ Private ];

Index %Process On %Process;

/// This holds a reference to the context
Property %Context As Ens.BP.Context [ Calculated, Private ];

/// This holds a collection of pending responses that this thread is waiting for
Property %PendingResponses As array Of %String [ SqlFieldName = _PendingResponses ];

/// This holds a collection of responses that this thread has received.
/// The thread instance will be saved and be opened later.
/// The contents of %SyncResponses are saved message body objects passed from 
/// Ens.BusinessProcess MessageHeaderHandler to the Process' OnResponse
Property %SyncResponses As %Library.ArrayOfObjectsWithClassName [ SqlFieldName = _SyncResponses ];

/// This holds the next state of the thread
Property %NextState As %String [ Final, InitialExpression = "S1", Private ];

/// This holds the run status of this machine
Property %Status As Ens.DataType.RunStatus [ InitialExpression = {$$$eRunStatusRunning} ];

/// Set this property to 1 to suspend this thread and to
/// allow other threads to run
Property %Wait As %Boolean [ Final, InitialExpression = 0, Private, Transient ];

/// This holds the (possibly empty) set of child threads that this process is waiting on
Property %ChildThreads As array Of %String [ SqlFieldName = _ChildThreads ];

/// This holds the timeout status of the most recent <SYNC> call and may be 0, 1 or 2
/// 0 - The call did not timeout
/// 1 - The call timed out
/// 2 - The call was interrupted
Property %SyncTimedOut As %Integer [ InitialExpression = 0 ];

/// This holds the name of the pending timeout call
Property %PendingTimeout As %String;

/// This holds the handle the pending alarm request
Property %PendingAlarmHandle As %String;

/// This holds the name attribute of the <sync> tag
Property %SyncName As %String;

/// This holds the callstack for compensation handlers
Property %SubroutineStack As %String;

/// This holds the callstack for faulthanders
Property %HandlerStack;

/// This holds the activitystack for locating an activity at runtime
Property %ActivityStack;

/// Accessor for the %Context property
Method %ContextGet() As Ens.BP.Context
{
	Quit ..%Process.%Context
}

/// Start Thread, creates a new instance of the specified thread class, stores it's Id in
/// the collection of child threads. Consequently the thread becomes runnable at the next
/// state switch
Method StartThread(pThreadClass As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		$$$ASSERT(pThreadClass'="")
		
		#; Create an instance of the thread class
		Set tThread=$zobjclassmethod(pThreadClass,"%New",..%Process)
		$$$ASSERT($IsObject(tThread))
		
		#; Save it, to get the thread id
		Set tSC=tThread.%Save()
		If $$$ISERR(tSC) Quit
		
		#; Store the Id of the newly created thread in the array of child threads
		Do ..%ChildThreads.SetAt($$$eRunStatusRunning,tThread.%Id())
		
		$$$ASSERT(..%ChildThreads.Count())
		
	} while (0)	
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Determine if a CompletionKey exists in this threads pending responses
Method IsResponsePending(pCompletionKey As %String) As %Boolean
{
	Set tIsResponsePending=0
	
	Set tResponse=..%PendingResponses.Next("")
	While tResponse'="" {
		If tResponse=pCompletionKey Set tIsResponsePending=1 Quit
		Set tResponse=..%PendingResponses.Next(tResponse)
	}
	
	Quit tIsResponsePending
}

/// Run the thread by handling responses,executing child threads, and calling the method
/// indicated by the NextState property.
Method SwitchState(Output pStatus As Ens.DataType.RunStatus, request As %Library.Persistent, response As %Library.Persistent, pCompletionKey As %String, pResumingPostErroredResponse As %Boolean, callresponse As %Library.Persistent) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		If pCompletionKey'="" {
			
			#; We have received a response
			
			#; Test to see if the response is a timeout message
			If $Extract(pCompletionKey,1,8)="_Timeout" {
				
				#; Yes, is the timeout for this thread?
				If pCompletionKey=..%PendingTimeout {
					
					#; Yes, We have timed out on a sync, first update the process-wide collection of 
					#; synchronized responses.
					Set tResponse=..%PendingResponses.Next("")
					While tResponse'="" {
						If tResponse'=pCompletionKey Do ..%Process.%SynchronizedResponses.SetAt("",tResponse)
						Set tResponse=..%PendingResponses.Next(tResponse)
					}
					
					#; Clear out this threads pending responses, the pending timeout and set the timed out flag 
					Do ..%PendingResponses.Clear() Set ..%PendingTimeout="",..%PendingAlarmHandle="",..%SyncName=""
					
					#; May be 0,1 or 2
					Set ..%SyncTimedOut=1+''..%Process.%IsTimerInterrupted
					
				} Else {
					
					#; The timeout is not applicable to this thread, must give any child threads the chance
					#; to process
				}
			} else {
				
				#; No, it's a regular response, not a timeout
				
				#; If we are resuming following a call response which has errored
				If pResumingPostErroredResponse {

					#; If there is a handler active
					If ..HandlerActive() {

						#; If the error is a response to a request made by THIS thread
						If ..IsResponsePending(pCompletionKey) {
							
							#; There is a handler for this thread, set the next state to the beginning of the handler and unwind the activities	    
							Set ..%NextState=$$$Top(..%HandlerStack),$ZE="" 
							
							$$$ASSERT(..%NextState'="")
							
							Do ..UnwindActivities()
							
							#; Need to Pop the Handler Stack once the next state has been determined
							$$$Pop(..%HandlerStack)
						}
					}
				}

				#; We have synchronized on this key, so this key is no longer pending for this thread
				Do ..%PendingResponses.RemoveAt(pCompletionKey)
				
				#; This Thread has synchronized on this response
				If $Data(callresponse)#2 {
					Do ..%SyncResponses.SetAt(callresponse,pCompletionKey)
				} Else {
					#; Do not expect callresponse not to be defined
					Do ..%SyncResponses.SetAt(response,pCompletionKey)
				}
				
				#; Add the response to the process wide collection of synchronized responses
				Do ..%Process.%SynchronizedResponses.SetAt("",pCompletionKey)
				
				#; If a timeout is only thing left that we are waiting for, remove it too
				If ..%PendingResponses.Count()=1 {
					Set tNext=..%PendingResponses.Next("")
					If $Extract(tNext,1,8)="_Timeout" {
						Do ..%PendingResponses.Clear()
						Do ..%Process.%SynchronizedResponses.SetAt("",tNext)
					}
				}
			}
		}
			
		#; Need to make sure that the Child threads are only scheduled with the pResumingPostErroredResponse flag once		
		Set tLoopCount=0
		
		#; While not indicated to stop, switch states
		While((..%Status=$$$eRunStatusRunning||(..%Status=$$$eRunStatusWaiting))) {
	
			If tLoopCount Set pResumingPostErroredResponse = 0
			
			Set ..%Status=$$$eRunStatusRunning,tThreadsWaiting=0
			
			If ..%ChildThreads.Count() {
				
				#; Run the child threads until ALL of them are waiting
				while (tThreadsWaiting'=..%ChildThreads.Count()) {
					
					Set tChildThreadId=..%ChildThreads.Next("")
					while (tChildThreadId'="") {
			
						#; pick out the thread status
						Set tStatus=..%ChildThreads.GetAt(tChildThreadId)
						
						If tStatus=$$$eRunStatusRunning||(tStatus=$$$eRunStatusWaiting) {
							
							Set tThread=##class(Ens.BP.Thread).%OpenId(tChildThreadId,,.tSC)
							If $$$ISERR(tSC) Quit
							
							$$$ASSERT($IsObject(tThread))
							
							#; Found a runnable thread, so run it
							If $Data(callresponse) {
								Set tSC1=tThread.SwitchState(.tStatus,request,.response,pCompletionKey,pResumingPostErroredResponse,callresponse)
							} Else {
								Set tSC1=tThread.SwitchState(.tStatus,request,.response,pCompletionKey,pResumingPostErroredResponse)
							}
							If tStatus=$$$eRunStatusCompleted {
								Do ..%ChildThreads.RemoveAt(tChildThreadId)
							} else {
								
								#; Update the status recorded in the child list
								Do ..%ChildThreads.SetAt(tStatus,tChildThreadId)
							}
								
							#; Must Save the Thread's new State
							Set tSC=tThread.%Save() If $$$ISERR(tSC) Quit
							
							#; If a thread has errored then by defintion, this parent thread has errored
							If tStatus=$$$eRunStatusErrored {
								
								Set ..%Status=$$$eRunStatusErrored
								$$$ASSERT($$$ISERR(tSC1))
							
								Quit
							}
							
							#; Increment the count of waiting threads
							If tStatus=$$$eRunStatusWaiting Set tThreadsWaiting=tThreadsWaiting+1
							
						}	
						Set tChildThreadId=..%ChildThreads.Next(tChildThreadId)
					}
					
					#; If a child thread has errored or the BPL runtime has errored then 
					#; don't attempt to schedule any more child threads
					If (..%Status=$$$eRunStatusErrored)||$$$ISERR(tSC) Quit
				}
			}
			
			#; Increment the loop count
			Set tLoopCount = tLoopCount + 1
			
			If ..%Status'=$$$eRunStatusErrored,tThreadsWaiting {
				
				#; This thread should wait because it's children are waiting
				Set ..%Wait=0,..%Status=$$$eRunStatusWaiting
				Quit
			}
			
			#; If there has been an error in the BPL runtime then quit
			If $$$ISERR(tSC) Quit
			
			#; If a child thread has errored
			If ..%Status=$$$eRunStatusErrored {
				
				#; Clean up the child threads they musn't be allowed to run again
				Do ..%ChildThreads.Clear()
					
				#; If there is an error handler defined, transfer control to it
				If $$$Top(..%HandlerStack)'="" {
					
					Set tCurrState=$$$Top(..%HandlerStack),..%NextState=""
					
					#; Error is beeing handled, this thread is now running again
					Set ..%Status=$$$eRunStatusRunning
				} else {
					
					#; If we are the top level thread and the error has not been
					#; handled then must report the error
					
					$$$ASSERT($$$ISERR(tSC1))
					
					Set tSC=tSC1	
					Quit
				}
			} else {
		
				$$$ASSERT(..%Status=$$$eRunStatusRunning)
				
				#; Now execute this thread
				Set tCurrState=..%NextState,..%NextState=""
			}
			
			#; Execute the method representing the next state
			Set tSC=$zobjmethod($this,tCurrState,..%Process,..%Context,..%SyncTimedOut,..%SyncResponses,request,.response)
			If $$$ISERR(tSC) Set ..%Status=$$$eRunStatusErrored Quit
				
			If ..%Wait=1 {
				
				#; This thread should wait
				Set ..%Wait=0,..%Status=$$$eRunStatusWaiting
				Quit
			}
			
			#; If the next state is 'Stop' this thread has run to completion
			If ..%NextState="Stop" {
				Set ..%Status=$$$eRunStatusCompleted
			}
		}
		
	} while (0)
Exit
	#; Assign the output
	Set pStatus=..%Status
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This initializes the thread with the owning process
Method %OnNew(initvalue As %RawString) As %Status [ CodeMode = objectgenerator, Private ]
{
	Do %code.WriteLine(" Set ..%Process=initvalue")
	Do %code.WriteLine(" Set ..%NextState=""S1""")
	Do %code.WriteLine(" Quit $$$OK")
}

/// Synchronize threads
Method SyncThreads(Output pComplete As %Boolean) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pComplete=0
		If ..%ChildThreads.Count()=0 {
			
			#; No more threads in my collection, they are all complete
			Set pComplete=1
		}
	} while (0)	
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Make an Asynchronous call to the specified class, if a non-empty response handler is specified,
/// that response handler will be called when the response is received
Method MakeAsyncCall(pResponseHandlerName As %String, pClassName As %String, pRequest As %Library.Persistent, pCompletionKey As %String, pResponseRequired As %Boolean, pIsTimer As %Boolean = 0, pDescription As %String = "", pSimSync As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Update the name of the request handler
		If pResponseHandlerName'="" {
			Do ..%Context.SetResponseHandler(pResponseHandlerName,pCompletionKey)
		}
		
		#; Do the call
		Set tSC=..%Process.SendRequestAsyncInternal(pClassName,pRequest,pResponseRequired,pCompletionKey,pIsTimer,,pDescription,pSimSync)
		If $$$ISERR(tSC) Quit
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Make a synchronous call to the specified class. If a non-empty response handler is specified,
/// the response handler is called inline
Method MakeSyncCall(pResponseHandlerName As %String, pClassName As %String, request As %Library.Persistent, response As %Library.Persistent, callrequest As %Library.Persistent, pDescription As %String = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Make the request
		Set tSC=..%Process.SendRequestSync(pClassName,callrequest,.tCallResponse,,pDescription)
		If $$$ISERR(tSC) Quit
		
		#; Execute the handler inline
		If pResponseHandlerName'="" {
			Set tSC=$zobjmethod(..%Context,pResponseHandlerName,..%Process,..%Context,request,.response,callrequest,tCallResponse)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Update the Synchronized Response array
Method UpdateSynchronizedResponses() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Walk through the list of child threads
		Set tChildThreadId=..%ChildThreads.Next("")
		While (tChildThreadId'="") {
			
			Set tThread=##class(Ens.BP.Thread).%OpenId(tChildThreadId,,.tSC)
			If $$$ISERR(tSC) Quit
			
			$$$ASSERT($IsObject(tThread))
		
			#; Recurse	
			Set tSC=tThread.UpdateSynchronizedResponses()
			If $$$ISERR(tSC)
								
			Set tChildThreadId=..%ChildThreads.Next(tChildThreadId)
		}
		
		If $$$ISERR(tSC) Quit
		
		#; Walk through pending responses and update the processes synchronized 
		#; responses array
		Set tResponse=..%PendingResponses.Next("")
		While tResponse'="" {
			Do ..%Process.%SynchronizedResponses.RemoveAt(tResponse)	
			Set tResponse=..%PendingResponses.Next(tResponse)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This is invoked by a compensate activity when it wants to call a compensation handler
Method GoSub(pGoSubState As %String, pReturnState As %String) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {	
		#; Push the state onto the stack
		$$$Push(pReturnState,..%SubroutineStack)
		
		#; Set the next state to switch to
		Set ..%NextState=pGoSubState
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This is invoked by a compensation handler when it wants to return to the caller
Method Return() As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {
		#; Get the return state
		Set ..%NextState=$$$Top(..%SubroutineStack)
	
		#; Pop the state off the stack
		$$$Pop(..%SubroutineStack)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This is invoked when a <sync> for 'any' is satisfied. The remaining pending responses
/// need to removed from the master pending response list of the process. This ensures that
/// delayed responses from a prior calls donot interfere with the current <sync>.
Method SatisfyPendingResponses()
{
	Set tName=..%PendingResponses.Next("")
	While tName'="" {
		Do ..%Process.RemovePendingResponse(tName)
		Set tName=..%PendingResponses.Next(tName)
	}
	If ..%PendingTimeout'="" Do ..%Process.RemovePendingResponse(..%PendingTimeout)
}

/// This is invoked when a thread enters an activity
Method EnterActivity(pActivity As %Integer, pSubActivity As %Integer, pActivityID As %Integer)
{
	#; Each entry on the stack is a $List of activity,subactivity and unique ( for this BP ) activity ID
	$$$Push($ListBuild(pActivity,pSubActivity,pActivityID),..%ActivityStack)
}

/// This is invoked when a thread leaves an activity
Method LeaveActivity(pActivity As %Integer, pSubActivity As %Integer, pActivityID As %Integer)
{
	$$$Pop(..%ActivityStack)
}

/// This is invoked when control is transferred to a fault handler
Method UnwindActivities()
{
	#; Unwind the activity stack until a scope block is encountered
	If $ListLength(..%ActivityStack) {
		
		for tI=$ListLength(..%ActivityStack):1:-1 {
	
			If $List($List(..%ActivityStack,tI),1)=$$$ActivityScope
			{
				Set ..%ActivityStack=$List(..%ActivityStack,1,tI-1)
				Quit
			}
		}
	}
}

/// Does this thread have a fault handler active?
Method HandlerActive() As %Boolean [ CodeMode = expression, Internal ]
{
($$$Top(..%HandlerStack)'="")
}

/// Does this thread or any of its children have a fault handler active?
Method AnyHandlerActive(ByRef pActive As %Boolean) As %Status
{
	Set tSC=$$$OK 
	Do {
		#; Check for this thread being active
		Set pActive=..HandlerActive() If pActive Quit
	
		#; Now check the children	
		Set tChildThreadId=..%ChildThreads.Next("")
		while (tChildThreadId'="") {

			#; Open the thread
			Set tThread=##class(Ens.BP.Thread).%OpenId(tChildThreadId,,.tSC)
			If $$$ISERR(tSC) Quit
		
			#; Test to see if it has a handler active
			Set tSC=tThread.AnyHandlerActive(.pActive)
			If $$$ISERR(tSC) || pActive Quit
			
			#; Get the next
			Set tChildThreadId=..%ChildThreads.Next(tChildThreadId)
		}
		
	} while (0)
	
	Quit tSC
}

Method ManageState(pStatus As %Status) As %Status [ Internal ]
{
	#; If an error is indicated
	If $$$ISERR(pStatus) {
	    
	    #; Record the errored status
	    Set ..%Context.%LastError=pStatus
	    
	    #; Test to see if there is an handler on the Stack
	    If ..HandlerActive() {
		    		    
		  	#; There is a handler, set the next state to the beginning of the handler and unwind the activities	    
	       	Set pStatus=$$$OK,..%NextState=$$$Top(..%HandlerStack),$ZE="" 
	       	
	       	$$$ASSERT(..%NextState'="")
	       	
	       	Do ..UnwindActivities()
	       	
	       	#; Need to Pop the Handler Stack once the next state has been determined
	       	$$$Pop(..%HandlerStack)
	    }
	}
	Quit pStatus
}

Method ManageStatus(pStatus As %Status, pMethodName As %String) As %Status
{
	If $ZE'["<ZTHRO>" { 
		If ..HandlerActive() { 
			Set pStatus=$$$ERROR($$$ObjectScriptError,$ZE) 
		} else { 
			Set pStatus=##class(Ens.Util.Error).EnsSystemError(..%ClassName(),pMethodName)
		}
	} 
	Quit pStatus
}

Method Fault(pFault As %String) As %Boolean
{
	If $System.Status.Equals(..%Context.%LastError,$$$EnsErrBPLThrownFault) {
		Quit ($System.Status.GetOneStatusText(..%Context.%LastError,1)=pFault)
	}
	Quit 0
}

Storage Default
{
<Data name="%ChildThreads">
<Attribute>%ChildThreads</Attribute>
<Structure>subnode</Structure>
<Subscript>"%ChildThreads"</Subscript>
</Data>
<Data name="%PendingResponses">
<Attribute>%PendingResponses</Attribute>
<Structure>subnode</Structure>
<Subscript>"%PendingResponses"</Subscript>
</Data>
<Data name="%SyncResponses">
<Attribute>%SyncResponses</Attribute>
<Structure>subnode</Structure>
<Subscript>"%SyncResponses"</Subscript>
</Data>
<Data name="ThreadDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%NextState</Value>
</Value>
<Value name="3">
<Value>%Process</Value>
</Value>
<Value name="4">
<Value>%Status</Value>
</Value>
<Value name="5">
<Value>%SyncTimedOut</Value>
</Value>
<Value name="6">
<Value>%PendingTimeout</Value>
</Value>
<Value name="7">
<Value>%CallStack</Value>
</Value>
<Value name="8">
<Value>%SubroutineStack</Value>
</Value>
<Value name="9">
<Value>%FaultHandler</Value>
</Value>
<Value name="10">
<Value>%FaultHandlerStack</Value>
</Value>
<Value name="11">
<Value>%HandlerStack</Value>
</Value>
<Value name="12">
<Value>%ActivityStack</Value>
</Value>
<Value name="13">
<Value>%PendingAlarmHandle</Value>
</Value>
<Value name="14">
<Value>%SyncName</Value>
</Value>
<Value name="15">
<Value>%LastFault</Value>
</Value>
</Data>
<DataLocation>^Ens.BP.ThreadD</DataLocation>
<DefaultData>ThreadDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.BP.ThreadD</IdLocation>
<IndexLocation>^Ens.BP.ThreadI</IndexLocation>
<StreamLocation>^Ens.BP.ThreadS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
