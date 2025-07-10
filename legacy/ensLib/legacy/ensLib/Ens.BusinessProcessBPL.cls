/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.BusinessProcessBPL Extends Ens.BusinessProcess [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// This property holds the instance of the initial thread of this process
Property %Thread As Ens.BP.Thread;

/// This property holds the context object
Property %Context As Ens.BP.Context;

/// This property holds the counter for delays and timeouts
Property %Counter As %Integer;

/// This property holds the collection of synchronised responses
Property %SynchronizedResponses As array Of %String [ SqlFieldName = _SynchronizedResponses ];

/// BPL Janitor will remove related classes
Projection Janitor As Ens.BPLJanitor;

/// This set of flags controls the logging performed by the rule engine whenever a Rule activity is executed.
/// The following flags are available:
/// <ul><li>'e' - log errors only. All errors will be logged irrespective of other flags, so 
/// setting the value to 'e' or leaving the value empty will only log errors.</li>
/// <li>'r' - log return values. This is the default value for the setting, and is 
/// also automatic whenever the 'd' or 'c' flags are specified.</li>
/// <li>'d' - log user-defined debug actions in the rule. This will also include 'r'.</li>
/// <li>'c' - log details of the conditions that are evaluated in the rule. This will also include 'r'.</li>
/// <li>'a' - log all available information. This is equivalent to 'rcd'.</li></ul>
Property RuleLogging As %String [ InitialExpression = {$$$eRuleLogTypeReturn} ];

Parameter SETTINGS = "RuleLogging:Dev";

/// Ensure that the value of <property>RuleLogging</property> is normalized at the time that it is set.
Method RuleLoggingSet(pRuleLogging As %String = {$$$eRuleLogTypeReturn}) As %Status
{
	Set i%RuleLogging = ##class(Ens.Rule.Definition).NormalizeRuleLogTypes(pRuleLogging)
	Quit $$$OK
}

ClassMethod OnCompile() [ CodeMode = objectgenerator ]
{
    Set tSC=$$$OK
    do {
        #; Don't run this method on the base class
        If %compiledclass.Name="Ens.BusinessProcessBPL" Quit
        
        #; find XDATA block named BPLERROR
        If ##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||BPLERROR") {
            Set tSC=$$$ERROR($$$EnsErrInvalidBPL)
            Quit
        }
        
        #; find XDATA block named BPL
        If ##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||BPL") {
            Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||BPL")
        
            #; get XDATA as stream
            Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
            Do tStream.Rewind()
    
            Set tSC=##class(Ens.BPL.Compiler).CompileStream(tStream,%class.Name)
        } else {
            
            #; Must have an XDATA BPL Block
            Set tSC=$$$ERROR($$$EnsErrMissingBPL)
        }
    } while (0)
    Quit tSC
}

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status [ CodeMode = objectgenerator, GenerateAfter = OnCompile ]
{
    #; Don't run this method on the base class
    If %compiledclass.Name="Ens.BusinessProcessBPL" Quit $$$OK
    
    #; If compile failed for any reason, don't attempt to generate this method
    If '$Data(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name)) Quit $$$OK
    
    Do %code.WriteLine(" Set $ZT=""Trap"",tSC=$$$OK do {")
    Do %code.WriteLine(" #; Create the initial thread")
    Do %code.WriteLine(" Set ..%Thread=$zobjclassmethod("""_^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"ThreadClass")_""",""%New"",$this)")
    Do %code.WriteLine(" $$$ASSERT($IsObject(..%Thread))")
    Do %code.WriteLine(" #; Create the final response body")
    
    #; Response is optional
    Set tResponse=$Get(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"ResponseClass"))
    If tResponse'="" {
        Do %code.WriteLine(" Set response=$zobjclassmethod("""_^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"ResponseClass")_""",""%New"")")
        Do %code.WriteLine(" $$$ASSERT($IsObject(response))")
    } else {
        Do %code.WriteLine(" Set response=$$$NULLOREF")
    }
    Do %code.WriteLine(" #; Create the context class")
    Do %code.WriteLine(" Set ..%Context=$zobjclassmethod("""_^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"ContextClass")_""",""%New"",$this)")
    Do %code.WriteLine(" $$$ASSERT($IsObject(..%Context))")
    Do %code.WriteLine(" #; Schedule the top level thread")
    Do %code.WriteLine(" Set tSC=..%Thread.SwitchState(.tStatus,request,.response,"""",0)")
    Do %code.WriteLine(" Kill %BPLVARS")
    Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
    Do %code.WriteLine(" #; Status MUST be 'completed','waiting' or 'errored'")
    Do %code.WriteLine(" $$$ASSERT(tStatus=$$$eRunStatusCompleted||(tStatus=$$$eRunStatusWaiting)||(tStatus=$$$eRunStatusErrored))")
    Do %code.WriteLine(" If tStatus'=$$$eRunStatusWaiting&&(..%Context.%Id()'="""")&&(..%SessionId'="""") Kill ^Ens.BPL.Milestone(..%SessionId,..%Context.%Id())") 
    Do %code.WriteLine(" } while (0)")
    Do %code.WriteLine("Exit Quit tSC")
    Do %code.WriteLine("Trap Set $ZT="""",tSC=$$$EnsSystemError Goto Exit")
    Quit $$$OK
}

/// Handle a 'Response'
Method OnResponse(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, callresponse As %Library.Persistent, pCompletionKey As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = OnCompile ]
{
    #; Don't run this method on the base class
    If %compiledclass.Name="Ens.BusinessProcessBPL" Quit $$$OK
    
    #; If compile failed for any reason, don't attempt to generate this method
    If '$Data(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name)) Quit $$$OK
    
    Do %code.WriteLine(" Set $ZT=""Trap"",tSC=$$$OK do {")
    Do %code.WriteLine("   If pCompletionKey'="""" {")
    Do %code.WriteLine("     #; Apply Response handler if specified")
    Do %code.WriteLine("     Set tResponseHandler=..%Context.%ResponseHandlers.GetAt(pCompletionKey)")
    Do %code.WriteLine("     If tResponseHandler'="""" {")
    Do %code.WriteLine("       Set tSC=$zobjmethod(..%Context,tResponseHandler,$this,..%Context,request,.response,callrequest,callresponse,pCompletionKey)")
    Do %code.WriteLine("       If $$$ISERR(tSC) Quit")
    Do %code.WriteLine("    }")
    Do %code.WriteLine("  }") 
    Do %code.WriteLine("  #; Schedule the top level thread")
    Do %code.WriteLine("  Set tSC=..%Thread.SwitchState(.tStatus,request,.response,pCompletionKey,0,callresponse)")
    Do %code.WriteLine("  Kill %BPLVARS")
    Do %code.WriteLine("  If $$$ISERR(tSC) Quit")
    Do %code.WriteLine("  #; Status MUST be 'completed' or 'waiting'")
    Do %code.WriteLine("  $$$ASSERT(tStatus=$$$eRunStatusCompleted||(tStatus=$$$eRunStatusWaiting))")
    Do %code.WriteLine("  Set tSC=..UpdateSynchronizedResponses()")
    Do %code.WriteLine("  If $$$ISERR(tSC) Quit")
    Do %code.WriteLine("  If tStatus=$$$eRunStatusCompleted&&(..%Context.%Id()'="""")&&(..%SessionId'="""") Kill ^Ens.BPL.Milestone(..%SessionId,..%Context.%Id())")
    Do %code.WriteLine(" } while (0)")
    Do %code.WriteLine("Exit Quit tSC")
    Do %code.WriteLine("Trap Set $ZT="""",tSC=$$$EnsSystemError Goto Exit")
    Quit $$$OK
}

/// We override this method to determine if there is an active error handler and if so to dispatch to it
Method OnErroredResponse(pErroredResponseStatus As %Status, request As %Library.Persistent, ByRef response As %Library.Persistent, pCompletionKey As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = OnCompile ]
{
    #; Don't run this method on the base class
    If %compiledclass.Name="Ens.BusinessProcessBPL" Quit $$$OK
    
    #; If compile failed for any reason, don't attempt to generate this method
    If '$Data(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name)) Quit $$$OK
    
    Do %code.WriteLine(" Set $ZT=""Trap"",tSC=$$$OK do {")
    Do %code.WriteLine(" #; Determine if the thread has an active handler")
    Do %code.WriteLine(" Set tSC=..%Thread.AnyHandlerActive(.tActive)")
    Do %code.WriteLine(" If $$$ISERR(tSC)")
    Do %code.WriteLine(" #; If there isn't a handler active then return the original response status")
    Do %code.WriteLine(" If tActive = 0 Set tSC=pErroredResponseStatus Quit")
    Do %code.WriteLine(" #; Record LastError")
    Do %code.WriteLine(" Set ..%Context.%LastError=pErroredResponseStatus")
    Do %code.WriteLine(" Set tSC=..%Thread.SwitchState(.tStatus,request,.response,pCompletionKey,1)")
    Do %code.WriteLine(" Kill %BPLVARS")
    Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
    Do %code.WriteLine(" #; Status MUST be 'completed' or 'waiting'")
    Do %code.WriteLine(" $$$ASSERT(tStatus=$$$eRunStatusCompleted||(tStatus=$$$eRunStatusWaiting))")    
    Do %code.WriteLine(" Set tSC=..UpdateSynchronizedResponses()")
    Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
    Do %code.WriteLine(" } while (0)")
    Do %code.WriteLine("Exit Quit tSC")
    Do %code.WriteLine("Trap Set $ZT="""",tSC=$$$EnsSystemError Goto Exit")
    Quit $$$OK
}

/// Update the synchronized responses
Method UpdateSynchronizedResponses() As %Status
{
    $$$sysTRACE("Start UpdateSynchronizedResponses")
    
    /// Recurse through the threads and ask each to remove from this processes
    /// %SynchronizedResponses array which are still outstanding
    Set tSC=..%Thread.UpdateSynchronizedResponses()
    If $$$ISERR(tSC) Quit tSC
    
    /// The array now contains those responses which have been
    /// synchronized by ALL threads. walk through the array and remove
    /// each response from the processes PendingResponse collection
    Set tResponse=..%SynchronizedResponses.Next("")
    While (tResponse'="") {
        Do ..RemovePendingResponse(tResponse)
        Set tResponse=..%SynchronizedResponses.Next(tResponse)
    }
    
    Do ..%SynchronizedResponses.Clear()
    
    $$$sysTRACE("Finish UpdateSynchronizedResponses")
    
    Quit tSC
}

ClassMethod IsComponent() As %Boolean [ CodeMode = objectgenerator, GenerateAfter = OnRequest ]
{
    Set tIsComponent=$get(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"IsComponent"),0)
    Do %code.WriteLine(" Quit "_tIsComponent)
}

ClassMethod GetMessageList() As %String
{
    Quit ..GetRequestClassList()
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest ]
{
    Set tClass=$get(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"RequestClass"),"%Library.Persistent")
    Do %code.WriteLine(" Quit $lb("""_tClass_""")")
    Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest ]
{
    Set tRequestClass=$get(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"RequestClass"),"%Library.Persistent")
    Set tResponseClass=$get(^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"ResponseClass"),"%Library.Persistent")
    Do %code.WriteLine(" If pRequest=""""||(pRequest="""_tRequestClass_""") Quit $lb("""_tResponseClass_""")")
    Do %code.WriteLine(" Quit """"")
    Quit $$$OK
}

Method MakeTimerCall(pPrefix As %String, Output pName As %String, pTimeout As %String, pCompletionKeyList As %String, Output pAlarmHandle As %String, pDescription As %String = "", pIsTimer As %Boolean = 1) As %Status
{
    #; Create the call's name from a combination of prefix and runtime counter
    Set ..%Counter=..%Counter+1
    Set pName=pPrefix_..%Counter
    
    #; Set the timer
    Quit ..SetTimer(pTimeout,pName,$ListFromString(pCompletionKeyList),.pAlarmHandle,pDescription,pIsTimer)
}

/// Deprecated
Method MakeAlarmCall(pThread As Ens.BP.Thread, pPrefix As %String, Output pName As %String, pDuration As %String, pUntil As %String = "", pIsTimer As %Boolean = 0, pDescription As %String = "") As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Form the alarm request
        Set tRequest=##class(Ens.AlarmRequest).%New()
        If '$IsObject(tRequest) Set tSC=%objlasterror Quit
        #; Set the duration or instant to wait until
        If pDuration'="" {
            Set tRequest.Duration=pDuration
        } elseif pUntil'="" {
            Set tRequest.Until=pUntil
        } else {
            $$$ASSERT("0:Duration or Instant MUST be specified")
        }
        #; Create the call's name from a combination of prefix and runtime counter
        Set ..%Counter=..%Counter+1
        Set pName=pPrefix_..%Counter
        
        #; Make the request
        Set tSC=pThread.MakeAsyncCall("","Ens.Alarm",tRequest,pName,1,pIsTimer,pDescription)
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$EnsSystemError
    Goto Exit
}

/// Deprecated - use Ens.BusinessProcess.Purge()
ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer, pKeepIntegrity As %Boolean) As %Status [ CodeMode = expression ]
{
##super(.pDeletedCount,.pDaysToKeeep,.pKeepIntegrity)
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
    Set tId=$$$oidPrimary(oid)
    &sql(SELECT %Context INTO :tContext FROM Ens.BusinessProcessBPL WHERE %ID = :tId)
    If 'SQLCODE {
        &sql(DELETE from Ens_BP.Context where %ID = :tContext)
        If SQLCODE < 0 Return $$$ERROR($$$SQLCode,SQLCODE,$Get(%msg,"Error Deleting Context"))
        &sql(DELETE from Ens_BP.Thread where %Process = :tId)
        If SQLCODE < 0 Return $$$ERROR($$$SQLCode,SQLCODE,$Get(%msg,"Error Deleting Thread"))
    } ElseIf SQLCODE<0 {
        Return $$$ERROR($$$SQLCode,SQLCODE,$Get(%msg,"Error Finding Associated Context"))
    }
    Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
    &sql(DELETE from Ens_BP.Context where %ID = :{%Context} )
    If SQLCODE >= 0 &sql(DELETE from Ens_BP.Thread where %Process = :{ID})
    If SQLCODE < 0 Set %ok = 0
}

Method WillHandleErroredResponse() As %Boolean [ CodeMode = expression, Internal ]
{
1
}

Storage Default
{
<Data name="%SynchronizedResponses">
<Attribute>%SynchronizedResponses</Attribute>
<Structure>subnode</Structure>
<Subscript>"%SynchronizedResponses"</Subscript>
</Data>
<Data name="BusinessProcessBPLDefaultData">
<Subscript>"BusinessProcessBPL"</Subscript>
<Value name="1">
<Value>%Context</Value>
</Value>
<Value name="2">
<Value>%Thread</Value>
</Value>
<Value name="3">
<Value>%Counter</Value>
</Value>
<Value name="4">
<Value>RuleLogging</Value>
</Value>
</Data>
<DefaultData>BusinessProcessBPLDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
