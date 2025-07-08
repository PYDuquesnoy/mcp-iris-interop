/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// This class serves as a debug agent for debugging processes.
/// It receives client debugging commands, sends then to the debug target, gets responses, and sends them back to the client.
/// 
/// The implementation is based on the XDEBUG DBGP protocol used by the eclipse DLTK.
/// <br>
/// http://xdebug.org/docs-dbgp.php
/// 
Class %Atelier.v1.XDebugAgent Extends %CSP.WebSocket
{

/// Parameter for Localization
Parameter DOMAIN = "%XDEBUG";

/// Require development resource
Parameter SECURITYRESOURCE = "%Development";

Parameter NULLSTATE = 0;

Parameter EXITSTATE = 1;

Parameter STOP = 2;

Parameter IDLE = "OnIdle";

Parameter TIMEOUT = 0.1;

/// This is the CLASS context for variable display in the IDE 
Parameter CLASS = 2;

/// This is the PUBLIC context for variable display in the IDE 
Parameter PUBLIC = 1;

/// This is the PRIVATE context for variable display in the IDE 
Parameter PRIVATE = 0;

/// This holds the current command
Property Command As %String [ MultiDimensional ];

/// This holds the debug_target (passsed to us by set_feature)
Property DebugTarget As %String;

/// This holds the next state to switch to
Property NextState As %String [ InitialExpression = {..#NULLSTATE} ];

/// This holds the current state of the FSM, Initial state is "{..#NULLSTATE}"
/// Before the machine can run a valid state needs to be established
Property State As %String [ InitialExpression = {..#NULLSTATE}, Internal ];

/// This holds the debugger instance
Property Debug As %Debugger.System;

/// This holds the TRACE flag
Property Trace As %Boolean [ InitialExpression = {$Get(^IRIS.Temp.Atelier("debug"))>0} ];

/// This holds the TRACE global node for this session
Property TraceNode As %Integer;

/// This holds the device list for $System.Socket.Select
Property DeviceList As %List;

/// This holds the websocket device
Property WebSocketDevice As %String;

/// This holds the target OR PID
Property TargetOrPID As %String;

/// This holds the attached flag
Property Attached As %Boolean [ InitialExpression = 0 ];

/// This holds the launched flag
Property Launched As %Boolean [ InitialExpression = 0 ];

/// This holds the Continuation command issued flag
Property ContinuationCmdIssued As %Boolean [ InitialExpression = 0 ];

/// This holds the current transaction identifier
Property TransactionId As %String [ MultiDimensional ];

/// Breakpoints
Property BreakPoints As %String [ MultiDimensional ];

/// This holds the last 'continuation' command issued
/// Continuation commands are 'run','step_into','step_over','step_out'
/// 'stop' and 'detach'. We need to record this so that the appropriate
/// status message can be reported to the client when a breakpoint is hit
/// or the program ends.
Property LastContinuationCmd As %String;

/// This holds the mappings from server stack level to IDE stack level
Property StackLevelMappings As %Integer [ MultiDimensional ];

/// This holds the values of the features set by the IDE
Property Features As %String [ MultiDimensional ];

/// This holds the first run command flag
Property FirstRunCommandSeen As %Boolean [ InitialExpression = 0 ];

/// The WebSocket Server
Method Server() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
   
    #dim tInitMsg,tRes As %String
    
    Try {
         
        #; Initially we are only reading from the WebSocket
        Set ..WebSocketDevice=$IO,..DeviceList=$ListBuild(..WebSocketDevice)

        #; Using newline as a terminator
        Use ..WebSocketDevice:(/TERMINATOR=$Char(10))

        #; Initialize the trace
        Do ..InitTrace()

        #; Set up the first state
        Set ..NextState=..#IDLE

        #; Get the init msg
        Set tSC=..GetInitMsg(.tInitMsg)
        If $$$ISERR(tSC) Quit

        Set tSC=..ReportEvent("init",tInitMsg)
        If $$$ISERR(tSC) Quit
        
        #; Run the FSM
        For {
            
            Try {
                
                #; Set the current state
                Set ..State=..NextState
            
                #; Check if we should exit
                If ..State=..#EXITSTATE Quit
                
                If ..State=..#STOP {
                    
                    #; We are going to exit
                    Set ..NextState=..#EXITSTATE
                
                    #; We sometimes get here before ever issuing a run command
                    #; Not sure how, but see github issue #2350
                    If ..LastContinuationCmd'="" {
                        Set tRes="<response"
                        Set tRes=tRes_" command='"_..LastContinuationCmd_"'"
                        Set tRes=tRes_" status='stopped'"
                        Set tRes=tRes_" reason='ok'"
                        Set tRes=tRes_" transaction_id='"_..TransactionId(..LastContinuationCmd)_"'"
                        Set tRes=tRes_"/>"
                        
                        #; Report the stop event
                        Set tSC=..ReportEvent("stop",tRes)
                        If $$$ISERR(tSC) Quit
                    }
                    
                    Quit
                }
                
                #; Execute the current state, if returns error, exit (below)
                If (..State '= ..#IDLE) {
                    Do ..Trace("Calling state "_..State)
                }
                Set tSC=$method($this,..State)
                
            } Catch (e) {
                Set tSC=e.AsStatus()
            }   
            
            #; Errored?
            If $$$ISERR(tSC) Quit
            
            #; Should Exit?
            If ..State=..#EXITSTATE Quit
        }

        #; If we have errored then tidy up
        If $$$ISERR(tSC) Do ..Trace("Server error: "_tSC)
        
        #; Tidy Up
        Set tSC=..TidyUp(tSC)
        
        Do ..Trace("Exiting")
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
     
    #; If there has been an error
    If $$$ISERR(tSC) {
        
        #; Form an eye-readable error message from the status
        Set e=##class(%Exception.StatusException).CreateFromStatus(tSC)
    
        #; Report error exit with error message
        #; TODO: HOW? (GITHUB ISSUE #5)
        Do ..ReportEvent("error","<exit>"_$ZCVT(e.DisplayString(),"O","XML")_"</exit>")
    }
    
    #; Now end the server
    Hang 1 ; let messages flush
    Do ..EndServer()
    
    Quit tSC
}

/// This where we receive and dispatch commands and pump debuggee output
Method OnIdle() As %Status [ Internal, Private ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tI,tLength,tIO,tRet As %Integer
    #dim tList As %List
    #dim tKey As %Char
    #dim tCmd,tData,tFrame,tRes As %String
    #dim tDbgIO,tWsIO As %Boolean
    
    #; Set the default state
    Set ..NextState=..#IDLE
            
    Try {
        
        #; Select on device(s) with something available to read
        Set tList=$System.Socket.Select(..DeviceList,..#TIMEOUT)
    
        #; If we timed out
        If tList="" {
            
            If ..ContinuationCmdIssued {
                #; Determine the 'run' state of the debuggee and act apropriately
                Set tRet=..Debug.IsStopped()
            } Else {
                #; Don't check IsStopped if we have never issued a Run command
                Set tRet=0 ; not stopped => do nothing here
            }
            
            If tRet=$$$OK {
                
                #; Only report broken or terminated if a command has been issued
                If ..ContinuationCmdIssued {
                    
                    #; Reset the run flag               
                    Set ..ContinuationCmdIssued=0
                    
                    #; If we are stopped in debugger.system ( ran off end )
                    If $Piece(..Debug.Location,":",2)["%Debugger.System" {
                        
                        Do ..Trace("Ran Off End")
                        
                        #; Make it finish
                        Do ..Debug.DBGCommand("B ""OFF"" G")
                        
                        #; Wait for it it quit
                        If $System.Event.WaitMsg("",1)
                        
                        #; Check again
                        If ..Debug.IsStopped() 
                        
                        #; Terminate
                        Set ..NextState=..#STOP
                        
                    } else {
                        
                        Do ..Trace("Hit A BreakPoint")
                            
                        #; We hit a breakpoint
                        Set tRes="<response"
                        Set tRes=tRes_" command='"_..LastContinuationCmd_"'"
                        Set tRes=tRes_" status='break'"
                        Set tRes=tRes_" reason='ok'"
                        Set tRes=tRes_" transaction_id='"_..TransactionId(..LastContinuationCmd)_"'"
                        Set tRes=tRes_"/>"
                        
                        #; Report the status event
                        Set tSC=..ReportEvent("status",tRes)
                    }
                }
                
            } elseif (tRet = $$$DebugTargetExited) {
                
                #; We're all done
                Set ..NextState=..#STOP
                        
            } elseif (tRet = 0) {
                
                #; No Action, not stopped
                
            } else {
                
                #; Want to quit
                Set tSC=$$$ERROR(tRet)
                
                Quit
            }
            
            #; Go round again
            Quit
        }
        
        #; If we were interrupted
        If tList=-1 {
            
            #; report the interrupt
            Set tSC=..ReportEvent("interrupt","<interrupt/>")
            If $$$ISERR(tSC) Quit
            
            #; Go round again
            Set ..NextState=..#IDLE
            Quit
        }
        
        #; Determine source of I/O
        Set (tWsIO,tDbgIO)=0
        For tI=1:1:$ListLength(tList) {
            If $List(tList,tI)=..WebSocketDevice {
                Set tWsIO=1
            } elseif $List(tList,tI)=..Debug.Dev {
                 Set tDbgIO=1
            } else {
                ZT "OOPS"
            }
        }
        
        #; Prioritize command channel
        If tWsIO {
        
            #; Read the data from the websocket (command stream)
            Set tIO=$IO Use ..WebSocketDevice
            
            #; Read up to terminator
            Try {
                
                Read tData
                
            } Catch (e) {
                
                #; Can't do anything more
                Set ..NextState=..#EXITSTATE
                Set tData=-99
                Do ..Trace("websocket unexpected error "_$ZE_" "_$ZU(56,2))
            }
            
            Use tIO
            If tData=-99 Quit
            
            #; Trace what we received
            Do ..Trace("Received:"_tData)
                    
            Set tSC=..MapCommandToHandler(tData)
            If $$$ISERR(tSC) Quit

        }

        #; If we have Debuggee IO, process that too
        If tDbgIO {
             
            Set tIO=$IO Use ..Debug.Dev
            
            #; Read the available data from the debugger output
            Try {
                
                Read tData#4500:1 Set tKey=$KEY
                
            } Catch (e) {
                
                If $ZE'["<READ>" Use tIO Throw e
                
                #; The debuggee has closed the socket
                Set tData="",tKey=""
                Do ..Trace("DbgIO <READ> "_$ZU(56,2))
                
                #; Remove debug device from the Select list
                Set ..DeviceList=$ListBuild($List(..DeviceList))
            }
            
            Use tIO
            
            #; If READ was terminated by a delimiter, append delimiter for client
            If tKey'="" Set tData=tData_$Char(10)
                
            #; Report any output to the DbgChannel
            If tData'="" {
                
                #; Trace
                Do ..Trace("output:"_tData)
                
                #; Form and output response
                Set tRes="<?xml version='1.0' encoding='UTF-8'?>"
                Set tRes=tRes_"<stream type='stdout'>"_$System.Encryption.Base64Encode($ZCVT(tData,"O","UTF8"),1)_"</stream>"
                
                Set tSC=..ReportEvent("stdout",tRes)
                If $$$ISERR(tSC) Quit
            }
        }
    
    } catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Get InitMsg
Method GetInitMsg(Output pInitMsg) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
      Set pInitMsg=
        "<init appid=""AtelierDebugger"" "_
        "     idekey=""Atelier"" "_
        "     session=""{$job}"" "_
        "     thread=""1"" "_
        "     parent=""{$zv}"" "_
        "     language=""COS"" "_
        "     protocol_version=""1.0"" "_
        "     fileuri=""file://"">"_
        "    <engine version=""1.0"">%Atelier.XDebugAgent</engine>"_
        "    <company>InterSystems Corporation</company>"_
        "    <license>Copyright 2015 InterSystems Corporation</license>"_
        "    <url>http://www.intersystems.com</url>"_
        "    <copyright>Copyright 2015 InterSystems Corporation</copyright>"_
        "</init>"
        
        #; Interpolate
        Set pInitMsg=..Interpolate(pInitMsg,"{$job}",$JOB)
        Set pInitMsg=..Interpolate(pInitMsg,"{$zv}",$ZV)

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Here we do state specific tidy up (will be called if an error has occurred)
Method TidyUp(pStatus) As %Status
{
    #; If the debugger is attached, bring it down
    If ..Debug.Attached Do ..Debug.Unattach()

    Quit pStatus
}

/// Event handler for the <b>PreServer</b> event: this is invoked before
/// starting the WebSockets Server.
/// Changes to the <property>SharedConnection</property> flag must be made here.
Method OnPreServer() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        
        #; Don't allow access if the %Development resource cannot be used
        If '$system.Security.Check("%Development","USE") {
            $$$ThrowStatus($$$ERROR($$$SecurityNotDeveloper))
        }

        #; debug agent must be executed from a REST context
        If $$$GetSecurityApplicationsDispatchClass(%request.AppData)="" {
            $$$ThrowStatus($$$ERROR($$$CSPIllegalRequest))
        }
            
        #; Instantiate an instance of the debugger
        Set ..Debug=##class(%Debugger.System).%New()
        Set ..Debug.trace=0
        Set ..Debug.atelierTrace=-1
        
        #; Don't want the debugger to do its own output
        Set ..Debug.OutputToDebugDevice=0
        
        #; We are going to use raw sockets
        Set ..NoDataFraming = 2
        
        #; Intialize breakpoint count
        Set ..BreakPoints=0
    
    } catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Intialize the trace (if required)
Method InitTrace()
{
    If ..Trace=0 Quit
    Set ..TraceNode=$Increment(^IRIS.Temp.Atelier("debug",$J))
    Set ..Debug.atelierTrace=..TraceNode
}

/// Log a trace if tracing enabled
Method Trace(pMsg As %String)
{
    #dim tNext As %Integer
    If ..Trace=0 Quit
    Set tNext=$Increment(^IRIS.Temp.Atelier("debug",$J,..TraceNode,0))
    Set ^(tNext)=pMsg
}

/// Parse XDebug command
/// 
/// Definition:-
/// 
/// cmd     :   cmdname [ arglist ];
/// cmdname :   lowercase STRING
/// arglist :   arg | [ arg arglist ];
/// arg     :   argid argval
/// argid   :   '-' CHAR
/// argval  :   STRING
/// 
/// Example:- 
/// 
/// feature_get -i 6 -n language_supports_threads
/// 
/// The command string is parsed into this structure:-
/// 
/// var="feature_get"
/// var("-i")=6
/// var("-n")="language_supports_threads"
/// 
Method ParseCommand(pCmdString As %String, Output pParsed) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tInQuotes As %Boolean
    #dim tArg,tChar,tVal,tSpaces As %String
    #dim tEnd,tI As %Integer
    
    Try {
        
        #; pick out the command and the command string
        Set pParsed=$Piece(pCmdString," "),pCmdString=$Piece(pCmdString," ",2,*)
        Set:$Length(pCmdString) pCmdString=" "_pCmdString_" "
        
        Set (tInQuotes,tSpaces)=0
    
        For tI=1:1:$Length(pCmdString) {
            Set tChar=$Extract(pCmdString,tI)
            If tChar="""" Set tInQuotes='tInQuotes
            If (tChar=" ")&&('tInQuotes) {
                Set tSpaces($Increment(tSpaces))=tI
            }
        }
        
        If tSpaces#2=0 Set tSpaces($Increment(tSpaces))=$Length(pCmdString)+1

        For tI=1:2:tSpaces-1 {
            Set tArg=$Extract(pCmdString,tSpaces(tI+0)+1,tSpaces(tI+1)-1)
            Set tVal=$Extract(pCmdString,tSpaces(tI+1)+1,tSpaces(tI+2)-1)
            Set pParsed(tArg)=tVal
        }
        
        If '$Data(pParsed("-i")) {
            Set tSC=$$$ERROR($$$XDebugCmdInvalid,pCmdString)
        }
        
    } Catch(e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Map the command to the associated handler (assumes valid command)
/// Some commands are handled inline
Method MapCommandToHandler(pCmdString As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCmd As %String
    
    #; Set next state and kill command
    Set ..NextState=..#IDLE Kill ..Command
    
    Try {
        
        #; Strip leading,trailing and collapse internal whitespace and lowercase
        Set pCmdString=$ZSTRIP(pCmdString,"<>W")
         
        #; Parse the command
        Set tSC=..ParseCommand(pCmdString,.tCmd)
        If $$$ISERR(tSC) Quit
        
        #; Record the transcation id on a command basis
        Set ..TransactionId=tCmd("-i")
        Set ..TransactionId(tCmd)=..TransactionId
        
        #; Check for quit first
        If tCmd="q" Set ..State=..#EXITSTATE Quit
            
        #; Record the command
        Merge ..Command=tCmd
            
        #; Dispatch to the method with the same name as the command
        Set ..NextState=tCmd
        
    } Catch(e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Report an event by writing to the WebSocket
Method ReportEvent(pEvent As %String, pXmlData = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tIO,tOutputFrame As %String
    
    Try {
        
        #; Trace
        Do ..Trace("Event:"_pEvent_"|"_pXmlData)
    
        #; We are using XML for DLTK
        Set tOutputFrame = $System.Encryption.Base64Encode($ZCVT(pXmlData,"O","UTF8"),1)
    
        #; Output the Frame to the websocket, need terminator to flush
        Set tIO=$IO Use ..WebSocketDevice Write $length(tOutputFrame)_"|"_tOutputFrame,*-3 Use tIO

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Report an event by writing to the WebSocket
Method ReportError(pErrorText As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tXml As %String
    
    Try {
    
        Set tXml="<error>"_$ZCVT(pErrorText,"O","XML")_"</error>"
        
        Set tSC=..ReportEvent("error",tXml)

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Utility method to interpolate values in a string
ClassMethod Interpolate(pString, pTerm, pValue) As %String [ CodeMode = expression ]
{
$replace(pString,pTerm,pValue,1,1)
}

/// Utility method to launch the target given the properties set by set_feature
Method Attach() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tPID,tRc As %Integer
    
    Try {
    
        Set tPID=$Piece(..DebugTarget,":",2)
        
        Do ..Trace("Attaching to PID: "_tPID)
    
        #; Attach to process
        Set tRc=..Debug.Attach(tPID)
        If tRc=$$$OK {
            
            #; Record the PID
            Set ..TargetOrPID=tPID
            
            #; Attached, check for debuggee output device open
            Do ..Trace("Debug Device Name:"_..Debug.Dev)
            If ..Debug.Dev'="" {
                
                #; Set up the device list for reading 2 channels
                Set ..DeviceList=$ListBuild(..WebSocketDevice,..Debug.Dev)
            }

            #; Record that we are attached
            Set ..Attached=1
            
            Do ..Trace("Attached to PID: "_tPID)
            
        } else {
            
            Set tSC=$$$ERROR(tRc,tPID)
            Set tMsg=$System.Status.GetOneErrorText(tSC)
            
            Do ..ReportError(tMsg)
        }
        
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Utility method to launch the target given the properties set by set_feature
Method Launch() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

    #dim tMsg,tNamespace,tTarget,tTargetName,tRtnName As %String
    #dim tRet As %Integer
    #dim tIsUpToDate As %Boolean
    #dim tSrc,tErrs As %String
    
    Try {
        
        Set tNamespace=$Piece(..DebugTarget,":",1)
        Set tTarget=$Piece(..DebugTarget,":",2)
        
        Do ..Trace("Launching: "_tTarget)
        
        #; We want to kill the target when we detach
        Set ..Debug.Killtarget=1
        
        #; Going to swap namespace
        Set $namespace=tNamespace
                
        #; Only if we aren't already attached
        If ..Debug.Attached=0 {
            
            #; Because we launched, if we unattach we want to kill target
            Set ..Debug.Killtarget=1
            
            #; ##class(classname).method()
            #; label+offset^routine
            
            #; Validate the target by compiling it
            Set tSrc(0)=1,tSrc(1)=" Do "_tTarget
            Set tSrc=$Compile(tSrc,0,tErrs)
            If tSrc {
                Set tSC=$$$ERROR($$$DebugInvalidTarget,tTarget)
                Set tMsg=$System.Status.GetOneErrorText(tSC)
                
                Do ..ReportError(tMsg)
                Quit
            }
            
            Set tTargetName=""
            If $Extract(tTarget,1,7)="##class" {
                Set tTargetName=$Piece($Piece(tTarget,"##class(",2),")")_".cls"
            } else {
                Set tRtnName=$Piece($Piece(tTarget,"^",2),"(")
                Set tTargetName=tRtnName_$Select($Data(^rMAC(tRtnName)):".MAC",1:".INT")
            }
            
            #; Check to see if source is up to date
            Set tIsUpToDate=0
            Do ##class(%RoutineMgr).TS(tTargetName,,.tIsUpToDate)
            If 0=tIsUpToDate {
                
                Set tSC=$$$ERROR($$$DebugSourceNotCompiled,tTargetName)
                Set tMsg=$System.Status.GetOneErrorText(tSC)
                
                #; Report 'soft' error
                Do ..ReportError(tMsg_": "_tTarget)
                Quit
            }
            
            #; Start the target ( don't want output written )
            Set tRet=..Debug.StartTarget(tTarget,0)
            If tRet=1 {
                
                #; Record the target
                Set ..TargetOrPID=tTarget
                
                #; Attached, check for debuggee output device open
                Do ..Trace("Debug Device Name:"_..Debug.Dev)
                If ..Debug.Dev'="" {
                    
                    #; Set up the device list for reading 2 channels
                    Set ..DeviceList=$ListBuild(..WebSocketDevice,..Debug.Dev)
                }

                #; Record that we are attached
                Set ..Attached=1
                
            } else {
                
                Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
                 
                #; Report 'soft' error
                Set tSC=..ReportError(tMsg_": "_tTarget)
            }
        } else {
            
            #; Report 'soft' error
            Set tSC=..ReportError("Already attached to target: "_tTarget)
        }
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'stop' command
Method stop()
{
    #; Must set the default next state
    Set ..NextState=..#STOP

    Quit $$$OK
}

/// IDE Command handler FOR 'feature_get' command
Method "feature_get"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRes As %String
    #dim tSupported As %Boolean
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Handle feature get
        Set tRes="<response" 
        Set tRes=tRes_" command='feature_get'"
        Set tRes=tRes_" feature='"_..Command("-n")_"'"
        
        If ..Command("-n")="language_supports_threads" {
            
            #; We don't support threads
            Set tSupported=0
        }
        
        ElseIf ..Command("-n")="language_name" {
            
            #; we DO support a language name
            Set tSupported=1
        }
        
        ElseIf ..Command("-n")="stdin" {
            
            #; We don't support STDIN
            Set tSupported=1
        }
        
        ElseIf ..Command("-n")="notify_ok" {
            
            #; We do support notifications
            Set tSupported=1
            
        } ElseIf ..Command("-n")="language_version" {
            
            #; We do support notifications
            Set tSupported=1
            
        } else {
            
            #; Default, we DON'T support it (whatever it is?)
            Set tSupported=0
        }
        
        #; Recored what is supported
        Set tRes=tRes_" supported='"_tSupported_"'"
        
        #; Transaction id is mandatory
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_">"
        
        If ..Command("-n")="language_name" {
            
            #; We say everything is COS
            Set tRes=tRes_"COS"
            
        } ElseIf ..Command("-n")="language_version" {
            
            #; We say everything is COS
            Set tRes=tRes_$ZV
        }
        
        Set tRes=tRes_"</response>"
        
        #; Report the event
        Set tSC=..ReportEvent("feature_get",tRes)
        If $$$ISERR(tSC) Quit
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'feature_set' command
Method "feature_set"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRes,tValue As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        If $Data(..Command("-v")) {
            Set tValue=..Command("-v")
        } ElseIf $Data(..Command("-v_base64")) {
            Set tValue=$System.Encryption.Base64Decode(..Command("-v_base64"))
        } Else {
            Set tValue=""
        }
        
        #; For now we say accept all features, regardless
        Set ..Features(..Command("-n"))=tValue
        
        #; Form the response
        Set tRes="<response" 
        Set tRes=tRes_" command='feature_set'"
        Set tRes=tRes_" feature='"_..Command("-n")_"'"
        Set tRes=tRes_" success='1'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_"/>"
        
        if ..Command("-n")="debug_target" {
            
            #; Debugging is not allowed with %SecureBreak
            If $Roles["%SecureBreak" {
                Do ..ReportError("Debugging is not allowed with the %SecureBreak role."_
                    " Please see your administrator to change your permissions.")
                Set tSC=$$$OK
                Quit
            }
            
            #; %SYS:##class(%BUG.BUGME).Run()
            #; %SYS:label+offset^routine
            #; pid:process number
            Set ..DebugTarget=tValue
            
            #; If second piece is numeric we are attaching
            If $Piece(..DebugTarget,":",2)?1.N {
                Set tSC=..Attach()
            } else {
                Set tSC=..Launch()
            }
            
            If $$$ISERR(tSC) {
                #; The error has already been reported so we don't want
                #; to report it again
                Set tSC=$$$OK
                Quit
            }
        }
        
        #; Report it
        Set tSC=..ReportEvent("feature_set",tRes)
        If $$$ISERR(tSC) Quit
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'break' command
Method break() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tSuccess As %Boolean
    #dim tRet As %Integer
    #dim tRes As %String
    
    #; Must set the to step out
    Set ..NextState=..#IDLE
    
    Try {
    
        Set tSuccess=1
        Set tRet=..Debug.Break()
        If tRet'=$$$OK {
             #; Indicate break failure
             Set tSuccess=0
        }   
        
        #; Form the response
        Set tRes="<response" 
        Set tRes=tRes_" command='break'"
        Set tRes=tRes_" success='"_tSuccess_"'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_"/>"
    
        #; Report it
        Set tSC=..ReportEvent("break",tRes)
        If $$$ISERR(tSC) Quit
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE (pseudo) Command handler FOR 'watchpoint_set' command
/// breakpoint_set -m DebugMe -n 2 -r 0 -s enabled -t watch -f file:///Users/haiodo/Develop/workspaces/runtime-New_configuration222/Demo3/User.Debug.cls -i 22 -- WA==
Method "watchpoint_set"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCondition,tOnePiece,tVariableName,tRes,tVariableNames As %Status
    #dim tI,tID,tRet As %Integer
    
    Try {
        
        Set tVariableNames = $System.Encryption.Base64Decode(..Command("--"))
        For tI=1:1:$Length(tVariableNames,",") {
        
            #; Pick out one variable name and condition
            Set tOnePiece=$Piece(tVariableNames,",",tI)
            Set tVariableName=$Piece(tOnePiece,"|",1),tCondition=$Piece(tOnePiece,"|",2)
            
            #; Check for valid variable name
            If $zname(tVariableName,0)=0 {
                #; Create an error response
                Set tRes=..CreateErrorResponse("breakpoint_set",200,..TransactionId,$$$Text("Breakpoint Cannot Be Set - Invalid Variable Name"))
                Set tSC=..ReportEvent("error",tRes)
                Quit
            }
            
            If ..Command("-s")="enabled" {
                
                Set tRet=..Debug.SetWatchpoint(tVariableName,tCondition)
                
            } elseif ..Command("-s")="disabled" {
                
                #; Have to set the watchpoint first
                Set tRet=..Debug.SetWatchpoint(tVariableName,tCondition)
            
                If tRet'=$$$OK {
                    
                    #; Create an error response
                    Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
                    Set tRes=..CreateErrorResponse("breakpoint_set",200,..TransactionId,$$$Text("Breakpoint Cannot Be Set - ")_tMsg)
                    Set tSC=..ReportEvent("error",tRes)
                    Quit
                }
                
                #; Then disable it
                Set tRet=..Debug.DisableWatchpoint(tVariableName)
                
            } else {
                ZT "OOPS"
            }
            
            If tRet'=$$$OK {
                
                #; Create an error response
                Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
                Set tRes=..CreateErrorResponse("breakpoint_set",200,..TransactionId,$$$Text("Breakpoint Cannot Be Set - ")_tMsg)
                Set tSC=..ReportEvent("error",tRes)
                Quit
            }
        }
        
        If $$$ISERR(tSC) Quit
    
        Do ..Trace("Watchpoint_"_..Command("-s")_":"_tVariableNames)
        
        Set ..BreakPoints=..BreakPoints+1,tID=..BreakPoints
        
        #; Record arguments
        Set ..BreakPoints(tID,"--")=..Command("--")
        Set ..BreakPoints(tID,"-f")=..Command("-f")
        Set ..BreakPoints(tID,"-m")=..Command("-m")
        Set ..BreakPoints(tID,"-n")=..Command("-n")
        Set ..BreakPoints(tID,"-t")=..Command("-t")
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_set'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_" state='"_..Command("-s")_"'"
        Set tRes=tRes_" id='"_tID_"'"
        Set tRes=tRes_"/>"
        
        Set tSC=..ReportEvent("watchpoint_set",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler FOR 'breakpoint_set' command
/// breakpoint_set -m DebugMe -n 3 -r 0 -s enabled -t line -f file:///Users/jamien/eclipse/runtime-EclipseApplication/XDebug/User.Debug.cls -i 10"
Method "breakpoint_set"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCondition,tID,tFileName,tLineNo,tMsg,tMethod,tIntName,tRes As %String
    #dim tNameSpace,tState,tTraceMsg,tType As %String
    #dim tHitCount,tIntLine,tRet As %Integer
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Suport for setting watch points
        If $Get(..Command("-t"))="watch" Do .."watchpoint_set"() Quit 
        
        Set tMethod=$Get(..Command("-m"))
        
        #; Filename must be URL decoded
        Set tFileName=$zcvt($Piece(..Command("-f"),"/",*),"I","URL")
        Set tHitCount=+$Get(..Command("-h"))
        Set tLineNo=$Get(..Command("-n"))
        Set tState=$Get(..Command("-s"))
        Set tType=$Get(..Command("-t"))
        
        Set tNameSpace=""
        If $Extract(tFileName)="|" Set tNameSpace=$Piece(tFileName,"|",2),tFileName=$Piece(tFileName,"|",3)
        
        #; Translate into IntName,IntLine and Condition
        Set tSC=##class(%Studio.Debugger).INTLine(tFileName,tMethod,tLineNo,.tIntName,.tIntLine,.tRet,tNameSpace)
        If $$$ISERR(tSC) Quit
        
        Do ..Trace("mapping: "_tNameSpace_":"_tFileName_":"_tMethod_":"_tLineNo_" -> "_tIntName_":"_tIntLine)
        
        #; Breakpoint cannot be set if cannot be mapped
        If tRet=2 {
            #; Create an error response
            Set tRes=..CreateErrorResponse("breakpoint_set",201,..TransactionId,$$$Text("Breakpoint Cannot Be Mapped"))
            Set tSC=..ReportEvent("error",tRes)
            Quit    
        }
        
        #; Breakpoint cannot be moved as IDE will get out of sync
        If tRet=1 {
            
            #; Create an error response
            Set tRes=..CreateErrorResponse("breakpoint_set",203,..TransactionId,$$$Text("No Code On Breakpoint Line"))
            Set tSC=..ReportEvent("error",tRes)
            Quit
        }
        
        #; Default is no condition
        Set tCondition=""
        
        If tState="enabled" {
        
            If tType="conditional" {
                Set tCondition=$System.Encryption.Base64Decode(..Command("--"))
            }
            
            Do ..Trace("Setting BP")
            
            #; Attempt to physically set the breakpoint
            Set tRet=..Debug.SetBreakpoint(tIntName,tIntLine,tCondition)
            
        } elseif tState="disabled" {
            
            #; Have to set the BP first
            Set tRet=..Debug.SetBreakpoint(tIntName,tIntLine,tCondition)
            
            If tRet'=$$$OK {
                
                #; Create an error response
                Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
                Set tRes=..CreateErrorResponse("breakpoint_set",200,..TransactionId,$$$Text("Breakpoint Cannot Be Set - ")_tMsg)
                Set tSC=..ReportEvent("error",tRes)
                Quit
            }
            
            #; Then disable it
            Set tRet=..Debug.DisableBreakpoint(tIntName,tIntLine)
        }
        
        If tRet'=$$$OK {
            
            #; Create an error response
            Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
            Set tRes=..CreateErrorResponse("breakpoint_set",200,..TransactionId,$$$Text("Breakpoint Cannot Be Set - ")_tMsg)
            Set tSC=..ReportEvent("error",tRes)
            Quit
        }
        
        Do ..Trace("BP "_tState_":"_tIntName_"("_tIntLine_"):"_tCondition_":"_tHitCount)
        
        If tHitCount>1 {
            
            #; This is the way we enable hit counts ( hit count is really skip count )
            Set tRet=..Debug.DisableBreakpoint(tIntName,tIntLine,tHitCount-1)
            If tRet'=$$$OK {
                
                #; Create an error response
                Set tMsg=$System.Status.GetOneErrorText($$$ERROR(tRet))
                Set tRes=..CreateErrorResponse("breakpoint_disable",200,..TransactionId,$$$Text("Breakpoint Cannot Be Disabled - ")_tMsg)
                Set tSC=..ReportEvent("error",tRes)
                Quit
            }
        }
        
        Set ..BreakPoints=..BreakPoints+1,tID=..BreakPoints
        
        #; Record arguments
        Set ..BreakPoints(tID,"-f")=tFileName
        Set ..BreakPoints(tID,"-m")=tMethod
        Set ..BreakPoints(tID,"-n")=tLineNo
        Set ..BreakPoints(tID,"-t")=tType
        
        #; Record our entrypoint
        Set ..BreakPoints(tID,"intName")=tIntName
        Set ..BreakPoints(tID,"intLine")=tIntLine
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_set'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_" state='"_tState_"'"
        Set tRes=tRes_" id='"_tID_"'"
        Set tRes=tRes_"/>"
        
        Set tSC=..ReportEvent("breakpoint_set",tRes)
        If $$$ISERR(tSC) Quit
            
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// breakpoint_get -d User.Debug.cls:DebugMe:3 -i 51"
Method "breakpoint_get"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tBP,tID,tFileName,tFunction,tLineNo,tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        Set tID=..Command("-d")
        
        Set tFileName   = ..BreakPoints(tID,"-f")
        Set tFunction   = ..BreakPoints(tID,"-m")
        Set tLineNo     = ..BreakPoints(tID,"-n")
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_get'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'>"
        
        Set tRes=tRes_"<breakpoint id='"_tID_"'"
        Set tRes=tRes_" filename='dbgp://"_tFileName_"'"
        Set tRes=tRes_" lineno='"_tLineNo_"'"
        Set tRes=tRes_" function='"_tFunction_"'>"
        
        Set tRes=tRes_"</breakpoint>"
        
        Set tRes=tRes_"</response>"
        
        Set tSC=..ReportEvent("breakpoint_get",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// breakpoint_list
Method "breakpoint_list"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tBP,tID,tFileName,tFunction,tLineNo,tRes,tType As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_list'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'>"
        
        Set tID="" For {
            
            Set tID=$Order(..BreakPoints(tID)) If tID="" Quit
            
            Set tFileName=..BreakPoints(tID,"-f")
            Set tFunction=..BreakPoints(tID,"-m")
            Set tLineNo=..BreakPoints(tID,"-n")
            Set tType=..BreakPoints(tID,"-t")
            
            #; Don't list watchpoints
            If tType="watch" Continue
        
            #; Form the breakpoint element
            Set tBP="<breakpoint id='"_tID_"' "
            Set tBP=tBP_" type='"_tType_"'"
            Set tBP=tBP_" filename='"_tFileName_"'"
            Set tBP=tBP_" function='"_tFunction_"'"
            Set tBP=tBP_" lineno='"_tLineNo_"'"
            Set tBP=tBP_"/>"
            
            #; Add the element to the response
            Set tRes=tRes_tBP
        }
        
        Set tRes=tRes_"</response>"
        
        Set tSC=..ReportEvent("breakpoint_list",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// breakpoint_remove
Method "breakpoint_remove"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tIntName,tIntLine,tRes,tOnePiece,tVariableName,tVariableNames As %String
    #dim tI,tID,tRet As %Integer
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Get the breakpoint id
        Set tID=..Command("-d")
    
        If ..BreakPoints(tID,"-t")="watch" {
            
            Set tVariableNames = $System.Encryption.Base64Decode(..BreakPoints(tID,"--"))
            For tI=1:1:$Length(tVariableNames,",") {
            
                #; Pick out one variable name and condition
                Set tOnePiece=$Piece(tVariableNames,",",tI)
                Set tVariableName=$Piece(tOnePiece,"|",1)
                
                Set tRet=..Debug.RemoveWatchpoint(tVariableName)
                
                If tRet'=$$$OK Set tSC=$$$ERROR(tRet) Quit
            }
            
            If $$$ISERR(tSC) Quit
            
        } else {
            
            Set tIntName=..BreakPoints(tID,"intName")
            Set tIntLine=..BreakPoints(tID,"intLine")
            
            #; Remove the breakpoint
            Set tRet=..Debug.RemoveBreakpoint(tIntName,tIntLine)
        }
        
        If tRet'=$$$OK Set tSC=$$$ERROR(tRet) Quit
        
        #; Remove our entry
        Kill ..BreakPoints(tID)
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_remove'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'/>"
    
        Set tSC=..ReportEvent("breakpoint_remove",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// breakpoint_update
Method "breakpoint_update"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tI,tID,tIntLine,tRet As %Integer
    #dim tCondition,tIntName,tOnePiece,tVariableName,tRes,tState,tVariableNames As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Get the breakpoint id and state
        Set tID=..Command("-d"),tState=..Command("-s")
        
        If ..BreakPoints(tID,"-t")="watch" {
            
            Set tVariableNames = $System.Encryption.Base64Decode(..BreakPoints(tID,"--"))
            For tI=1:1:$Length(tVariableNames,",") {
            
                #; Pick out one variable name and condition
                Set tOnePiece=$Piece(tVariableNames,",",tI)
                Set tVariableName=$Piece(tOnePiece,"|",1),tCondition=$Piece(tOnePiece,"|",2)
                
                If tState="enabled" {
                    Set tRet=..Debug.SetWatchpoint(tVariableName,tCondition)
                } elseif tState="disabled" {
                    Set tRet=..Debug.DisableWatchpoint(tVariableName)
                } else {
                    ZT "OOPS"
                }
                If tRet'=$$$OK Set tSC=$$$ERROR(tRet) Quit
            }
        
            Do ..Trace("Watchpoint_"_tState_":"_tVariableNames)
            
            If $$$ISERR(tSC) Quit
            
        } else {
            
            #; Get the Name and Line
            Set tIntName=..BreakPoints(tID,"intName")
            Set tIntLine=..BreakPoints(tID,"intLine")
            
            #; Either set or disable
            if tState="enabled" {
                Set tRet=..Debug.SetBreakpoint(tIntName,tIntLine)
            } elseif tState="disabled" {
                Set tRet=..Debug.DisableBreakpoint(tIntName,tIntLine)
            } else {
                ZT "OOPS"
            }
        
            Do ..Trace("BP "_tState_":"_tIntName_"("_tIntLine_")")
        }
        
        If tRet'=$$$OK Set tSC=$$$ERROR(tRet) Quit
        
        #; Response
        Set tRes="<response"
        Set tRes=tRes_" command='breakpoint_update'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'/>"
        
        Set tSC=..ReportEvent("breakpoint_update",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'context_names' command
Method "context_names"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRet As %Integer
    #dim tRes,tResult As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        Set tRes="<response"
        Set tRes=tRes_" command='context_names'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_">"
        
        #; Local and Global
        Set tRes=tRes_"<context name='Local' id='"_..#PRIVATE_"'/>"
        Set tRes=tRes_"<context name='Global' id='"_..#PUBLIC_"'/>"
        
        #; Class is dependent upon existence of $this?.N1"@".E
        Set tResult="",tRet=..Debug.Eval("$this",.tResult)
        
        If tResult?.N1"@".E {
            Set tRes=tRes_"<context name='Class' id='"_..#CLASS_"'/>"
        }
    
        Set tRes=tRes_"</response>"
        
        #; Report the event
        Set tSC=..ReportEvent("context_names",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'context_get' command
Method "context_get"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tCallStack,tContext,tServerLev,tEncoding,tIdeLev,tName As %String
    #dim tProp,tPropList,tRes,tValue,tVarName,tVarValue As %String
    #dim tLength As %Integer
    #dim tRS As %ResultSet
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        #; Get the context will be 0 for locals, 1 for globals, 2 for class
        Set tContext=..Command("-c")
        
        #; Form the response wrapper
        Set tRes="<response"
        Set tRes=tRes_" command='context_get'"
        Set tRes=tRes_" context='"_tContext_"'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_">"
        
        #; Initialize the proplist
        Set tPropList=""
        
        #; We can do this only if the process is stopped
        If ..Debug.IsStopped(0)=$$$OK {
            
            #; If its a class context
            If tContext=..#CLASS {
                
                #; Get the ClassProperties
                Set tSC=..GetClassProperties(.tPropList)
                
            } else {
            
                #; Get the stack depth requested
                Set tIdeLev=..Command("-d")
                
                #; Map the IDE Level to the Server Level
                Set tServerLev=..StackLevelMappings(tIdeLev)
                
                #; Log the request stack level
                Do ..Trace("StackLevel IDE->Server:"_tIdeLev_"->"_tServerLev)
                
                Set tSC=..GetStackProperties(tContext,tServerLev,.tPropList)
            }
        
            If $$$ISERR(tSC) Quit
        }
        
        Set tRes=tRes_tPropList_"</response>"
        
        #; Report the event
        Set tSC=..ReportEvent("context_get",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler for 'eval' command
Method eval() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tLength,tRet As %Integer
    #dim tExpr,tProp,tResult,tRes,tType As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; And the data itself
        Set tExpr=$System.Encryption.Base64Decode(..Command("--"))
        
        #; Log the decoded value
        Do ..Trace("eval:"_tExpr)
        
        #; Expressions passed from the 'expressions' window will
        #; be preceded by these two characters
        If $Extract(tExpr,1,2)="#$" {
            
            #; It's an expression
            Set $Extract(tExpr,1,2)=""
            
        } else {
            
            #; It's a command from the interactive console window
            #; NYI (Needs Server Work)
        }
        
        #; Set the value
        Set tRet=..Debug.Eval(tExpr,.tResult)
        If tRet'=1 Set tRet=0
        
        Set tRes="<response command='eval'"
        Set tRes=tRes_" success='"_tRet_"'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'>"
        
        Kill tProp
        Set tSC=..CreatePropertyResponse(tExpr,tResult,.tProp)
        If $$$ISERR(tSC) Quit
        
        #; Add the property to the response
        Set tRes=tRes_tProp_"</response>"
        
        #; Report the event
        Set tSC=..ReportEvent("eval",tRes)
        If $$$ISERR(tSC) Quit
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler for 'property_set' command
Method "property_set"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tLength,tRet As %Integer
    #dim tName,tData,tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Check the Stack Depth, we can only change variable values for the current stack frame
        #; where depth = 1
        If ..Command("-d")=1 {
            
            #; Get the property name
            Set tName=..Command("-n")
            
            #; And the data itself
            Set tData=$System.Encryption.Base64Decode(..Command("--"))
            
            #; Log the decoded value
            Do ..Trace("property_set:"_tData)
            
            #; Set the value
            Set tRet=..Debug.SetValue(tName,tData)
            If tRet'=1 Set tRet=0
        
        } else {
            
            #; Cannot set a property for any other stack depth
            Set tRet=0
        }
        
        Set tRes="<response command='property_set'"
        Set tRes=tRes_" success='"_tRet_"'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'/>"
        
        #; Report the event
        Set tSC=..ReportEvent("property_set",tRes)
        If $$$ISERR(tSC) Quit
        
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler for 'property_get' command
Method "property_get"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tDepth,tContext,tLength,tRet As %Integer
    #dim tName,tProp,tValue,tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Get the property name
        Set tName=..Command("-n")
        
        #; If it's a property value
        If $piece(tName,".")="$this" {
            Set tRet=..Debug.Eval(tName,.tValue)
        } else {
            #; Get the value
            Set tRet=..Debug.GetValue(tName,.tValue)
        }
        If tRet'=1 Set tRet=0
        
        #; Log the raw value
        Do ..Trace("property_get:"_tValue)
        
        Set tRes="<response command='property_get'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'>"
        
        Kill tProp
        Set tSC=..CreatePropertyResponse(tName,tValue,.tProp)
        If $$$ISERR(tSC) Quit
        
        #; Add the property to the response
        Set tRes=tRes_tProp_"</response>"
            
        #; Report the event
        Set tSC=..ReportEvent("property_get",tRes)
        If $$$ISERR(tSC) Quit
        
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler for 'property_value' command
Method "property_value"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tDepth,tContext,tLength,tRet As %Integer
    #dim tEncoding,tName,tType,tValue,tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Get the property name
        Set tName=..Command("-n")
        
        #; Get the value from the debuggee
        Set tRet=..Debug.GetValue(tName,.tValue)
        If tRet'=1 Set tRet=0
        
        #; Log the raw value
        Do ..Trace("property_value:"_tValue)
        
        If tValue?.E1.C.E {
            Set tType="string",tEncoding="base64"
            Set tValue=$System.Encryption.Base64Encode(tValue,1)
        } else {
            Set tType="string",tEncoding="none"
        }
        
        Set tRes="<response command='property_value'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_" success='"_tRet_"'"
        Set tRes=tRes_" size='"_$Length(tValue)_"'"
        Set tRes=tRes_" type='"_tType_"'"
        Set tRes=tRes_" encoding='"_tEncoding_"'>"
    
        If tEncoding="none" {
            #; Need XML encoding
            Set tRes=tRes_$ZCVT(tValue,"O","XML")
        }
        
        #; Add the property to the response
        Set tRes=tRes_"</response>"
            
        #; Report the event
        Set tSC=..ReportEvent("property_value",tRes)
        If $$$ISERR(tSC) Quit
        
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// IDE Command handler FOR 'run' command
Method run() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Command has been issued
        Set ..ContinuationCmdIssued=1
        
        #; Record the continuation command type
        Set ..LastContinuationCmd="run"
        
        If ..FirstRunCommandSeen=0 {
            
            #; This is the first run command
            Set ..FirstRunCommandSeen=1
            
            #; Don't execute run command for Attached process on first run
            If ..TargetOrPID?1.N {
            
                Quit
            }
        }
         
        #; Make it GO without stepping
        Set tSC=..Debug.Resume()
    
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler for 'step_into' command
Method "step_into"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRet As %Integer
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Command has been issued
        Set ..ContinuationCmdIssued=1
        
        #; Record the continuation command type
        Set ..LastContinuationCmd="step_into"
        
        #; Make it SO
        Set tRet=..Debug.LineIn()
        
        #; 1 status means OK
        If tRet=$$$OK Quit
        
        #; Non zero status is an error message code
        Set tSC=$$$ERROR(tRet)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler for 'step_over' command
Method "step_over"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRet As %Integer
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Command has been issued
        Set ..ContinuationCmdIssued=1
        
        #; Record the continuation command type
        Set ..LastContinuationCmd="step_over"
        
        #; Line mode
        Set tRet=..Debug.Line()
            
        #; 1 status means OK
        If tRet=$$$OK Quit
        
        #; Non zero status is an error message code
        Set tSC=$$$ERROR(tRet)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler for 'step_over' command
Method "step_out"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRet As %Integer
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Command has been issued
        Set ..ContinuationCmdIssued=1
        
        #; Record the continuation command type
        Set ..LastContinuationCmd="step_out"
        
        #; Line mode
        Set tRet=..Debug.LineOut()
            
        #; 1 status means OK
        If tRet=$$$OK Quit
        
        #; Non zero status is an error message code
        Set tSC=$$$ERROR(tRet)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

Method stderr() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        Set tRes="<response" 
        Set tRes=tRes_" command='stderr'"
        Set tRes=tRes_" success='1'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_"/>"
        
        #; Report the Event
        Set tSC=..ReportEvent("stderr",tRes)
        If $$$ISERR(tSC) Quit
        
        #; TODO: If has asked to disable then we should NOT send output
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

Method stdout() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRes As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        Set tRes="<response" 
        Set tRes=tRes_" command='stdout'"
        Set tRes=tRes_" success='1'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_"/>"
        
        #; Report the Event
        Set tSC=..ReportEvent("stdout",tRes)
        If $$$ISERR(tSC) Quit
        
        #; TODO: If has asked to disable then we should NOT send output
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'stdin' command
Method stdin() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tRes,tText As %String
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        Set tRes="<response" 
        Set tRes=tRes_" command='stdin'"
        Set tRes=tRes_" success='1'"
        Set tRes=tRes_" transaction_id='"_..TransactionId_"'"
        Set tRes=tRes_"/>"
        
        #; Report the Event
        Set tSC=..ReportEvent("stdin",tRes)
        If $$$ISERR(tSC) Quit
        
        If $Data(..Command("--")) {
            
            Set tText=$System.Encryption.Base64Decode(..Command("--"))
        
            Use ..Debug.Dev Write tText,*-3
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// IDE Command handler FOR 'stack_get' command
Method "stack_get"() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tLevel,tI As %Integer
    #dim tCallStack,tServerLev,tEntry,tFile,tIdeLev,tPos,tRes As %String
    #dim tStkArray,tData As %String
    
    #; For file reference
    #dim tNameSpace,tFileName,tLabel,tOffset
    #dim tMapped As %Boolean
    
    #; Must set the default next state
    Set ..NextState=..#IDLE
    
    Try {
        
        #; Level is optional
        Set tLevel=+$Get(..Command("-d"))
        
        #; Get the stack info
        #; TODO: Honor the depth argument; for now, just return the entire stack
        Set tCallStack=..Debug.Stack
        
        Do ..Trace("stack: "_tCallStack)

        #; Set up the response
        Set tRes="<response command='stack_get' transaction_id='"_..TransactionId_"'>"
        
        #; Clear out the stack level mappings
        Kill ..StackLevelMappings
        
        #; Collect the stack info into a local array so we can manipulate
        #; it if necessary
        #; Levels must be consecutive for IDE
        #; and go in reverse order compared to Server levels
        
        Set tIdeLev=$Length(tCallStack,":")
        Set tI=1

        #; If the first item is %Debugger.System, ignore it
        If $Piece(tCallStack,":",1)["%Debugger.System" {
            Set tIdeLev=tIdeLev-1
            Set tI=2
        }
        
        For tI=tI:1:$Length(tCallStack,":") {
            
            Set tEntry=$Piece(tCallStack,":",tI)
            
            #; Need to do reverse mapping here
            Set tServerLev=$Piece(tEntry,"^",1)
            
            #; Pick out the position
            Set tPos=$Piece(tEntry,"^",2,3)
            
            #; Do we have a location?
            If $Piece(tPos,"^",1)="" {
                #; If we are in an Xecute there is none, so we report the
                #; previous location, which should be the line with the Xecute
                If $Data(tStkArray(tIdeLev+1)) {
                    Set tStkArray(tIdeLev)=tStkArray(tIdeLev+1)
                    Set ..StackLevelMappings(tIdeLev)=tServerLev
                    Set tIdeLev=tIdeLev-1
                    Do ..Trace("mapping:"_tPos_" -> previous")
                    Continue
                } Else {
                    #; We have to ignore it
                    #; The client gets an error if we report no location
                    Do ..Trace("mapping:"_tPos_" -> No Location: Not Mapped")
                    Continue
                }
            }
            
            #; Get the namespace
            Set tNameSpace=$Piece(..Debug.Location,":",13,*)
            
            #; Convert to something the client understands
            Set tSC=..GetClientPosFromDebugPos(tPos,.tMapped,.tNameSpace,.tFileName,.tLabel,.tOffset)
            If $$$ISERR(tSC) Quit
           
            If tMapped=0 {
                Do ..Trace("mapping:"_tPos_" -> No Source: Not Mapped")
                
                #; Can't report anything here
                Continue
            }
                 
            Do ..Trace("mapping:"_tPos_" -> "_tNameSpace_":"_tFileName_":"_tLabel_":"_tOffset)
            
            #; Record the stack level mapping
            Set ..StackLevelMappings(tIdeLev)=tServerLev
            
            #; Save the mapping
            If $Extract(tNameSpace)="^" Set tNameSpace=$Tr($Tr(tNameSpace,"/","\"),"\","#")
            Set tStkArray(tIdeLev)=$ListBuild(tNameSpace,tFileName,tLabel,tOffset)
            
            Set tIdeLev=tIdeLev-1
        }
        
        #; Must check error in loop
        If $$$ISERR(tSC) Quit
        
        #; Return the stack in IDE level order
        
        Set tIdeLev=0
        For {
            Set tIdeLev=$Order(tStkArray(tIdeLev),1,tData)
            Quit:tIdeLev=""
            
            Set tRes=tRes_"<stack level='"_tIdeLev_"' type='file'"
            Set tRes=tRes_" filename='dbgp://"_$ZCVT("|"_$List(tData,1)_"|"_$List(tData,2),"O","URL")_"'"
            Set tRes=tRes_" method='"_$List(tData,3)_"'"
            Set tRes=tRes_" methodoffset='"_$List(tData,4)_"'"
            Set tRes=tRes_" lineno='"_$List(tData,4)_"'"
            Set tRes=tRes_"/>"
        }

        Set tRes=tRes_"</response>"

        #; Report the event
        Set tSC=..ReportEvent("stack_get",tRes)
        If $$$ISERR(tSC) Quit

    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Create an error response including error code and message to be displayed by IDE
Method CreateErrorResponse(pCmd As %String, pErrorCode As %Integer, pTransactionId As %Integer, pMsg As %String) As %String
{
    #dim tRes As %String
    
    Set tRes="<response command='"_pCmd_"' transaction_id='"_pTransactionId_"'>"
    Set tRes=tRes_"<error code='"_pErrorCode_"'><message>"_pMsg_"</message></error>"
    Set tRes=tRes_"</response>"
            
    Quit tRes
}

/// Given a variable name and a value, create a property for reporting to the IDE
Method CreatePropertyResponse(pVarName As %String, pVarValue As %String, Output pXML As %String, pNumChildren = 0) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tLength,tConstant As %Integer
    #dim tEncoding,tType As %String
    
    Try {
        
        #; Determine the type and encoding according to if string contains control 
        #; characters
        If pVarValue?.E1.C.E {
            #; If the value contains control characters we must quote them
            Set pVarValue=##class(%Global).Quote(pVarValue)
            #; The comment added to %Status values can contain bare control characters
            If pVarValue?.E1.C.E {
                #; If so, quote them
                Set pVarValue=..requote(pVarValue)
            }
            Set tType="string",tEncoding="none",tConstant=1
        } else {
            Set tType="string",tEncoding="none",tConstant=0
            
            #; If it looks like an object, make it constant
            If pVarValue?1.N1"@".E Set tConstant=1
        }
        
        #; Record the length of the value to report ACTUAL length
        Set tLength=$Length(pVarValue)
        
        #; Apply the IDE feature (the IDE will call "property_value" to get full value)
        If $Length(pVarValue)>(..Features("max_data")) {
            
            #; Truncate to maximum allowed length
            Set pVarValue=$Extract(pVarValue,1,..Features("max_data"))
        }
        
        #; If the encoding is base64 then encode it
        If tEncoding="base64" Set pVarValue=$System.Encryption.Base64Encode(pVarValue,1)
    
        #; If the varname is subscripted, encode it because the subscript could
        #; make the XML invalid
        If pVarName["(" Set pVarName=$ZCVT(pVarName,"O","XML")
    
        Set pXML="<property"
        Set pXML=pXML_" name='"_pVarName_"'" 
        Set pXML=pXML_" fullname='"_pVarName_"'"
        Set pXML=pXML_" type='"_tType_"'"
        Set pXML=pXML_" constant='"_tConstant_"'"
        Set pXML=pXML_" children='"_(''pNumChildren)_"'"
        Set pXML=pXML_" size='"_tLength_"'"
        Set pXML=pXML_" numchildren='"_pNumChildren_"'"
        Set pXML=pXML_" encoding='"_tEncoding_"'"
        Set pXML=pXML_">"
        
        #; Need XML encoding
        Set pXML=pXML_$ZCVT(pVarValue,"O","XML")
        
        Set pXML=pXML_"</property>"
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Get the properties for the CLASS context
Method GetClassProperties(Output pPropList As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tProp,tVarName,tVarValue As %String
    
    Try {
            
        #; Create the result set
        Set tRS=##class(%ResultSet).%New("%Studio.Debugger:WatchListOref")
        
        #; Execute for this level
        Set tSC=tRS.Execute($$$objOrefToInt($this),"$this")
        If $$$ISERR(tSC) Quit
        
        While tRS.%Next() {
        
            #; Get the variable (expression) name and value
            Set tVarName=tRS.Get("Expression")
            Set tVarValue=tRS.Get("Value")
            
            #; Trace the values
            Do ..Trace("Context:"_..#CLASS_":$this."_tVarName_":"_tVarValue)
            
            Kill tProp
            Set tSC=..CreatePropertyResponse("$this."_tVarName,tVarValue,.tProp)
            If $$$ISERR(tSC) Quit
            
            #; Add the property to the response
            Set pPropList=pPropList_tProp
        }
            
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Given a context (LOCAL,GLOBAL) and stack level, get the variables defined at that level
Method GetStackProperties(pContext As %Integer, pServerLevel As %Integer, Output pPropList As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tProp,tVarName,tVarValue,tBareName As %String
    #dim tSubCnt,maxlen As %Integer
    
    Try {
        #; Create the result set
        Set tRS=##class(%ResultSet).%New("%Debugger.Stack:StackVarAtLevel")
        
        #; Execute for this level
        Set tSC=tRS.Execute($$$objOrefToInt($this),pServerLevel)
        If $$$ISERR(tSC) Quit

        #; The result will be Base64 encoded so we have to consider that
        #; in the max result we can produce.
        #; The maximum result for the encode is $$$MaxLocalLength,
        #; so the maximum input is $$$MaxLocalLength\4*3.
        #; But the Base64Encode requires an extra outlen\76*4.
        #; (I think throwing ERMXSTR after applying that extra is wrong.)
        #; So the actual max output is $$$MaxLocalLength-($$$MaxLocalLength\76*4)
        #; giving the max input as
        Set maxlen=($$$MaxLocalLength-($$$MaxLocalLength\76*4))\4*3-100
        #; The 100 is to account for the response header
        
        Set tBareName="",tSubCnt=0
        
        While tRS.%Next() {
        
            #; Get the variable name
            Set tVarName=tRS.Get("Variable")
            
            #; Only give the first 50 subscripts of any variable
            If tBareName=$Piece(tVarName,"(") {
                Set tSubCnt=tSubCnt+1
                If tSubCnt>50 Continue
            } Else {
                Set tBareName=$Piece(tVarName,"("),tSubCnt=1
            }
            
            #; And value
            Set tVarValue=tRS.Get("Value")
            
            #; Trace the values
            Do ..Trace("Context:"_pContext_":"_tVarName_":"_tVarValue)
            
            #; Variable may start with ~ (means is private variable)
            If $Extract(tVarName)="~" {
                
                #; If we are asking for the global context then don't report private
                #; variables
                If pContext=..#PUBLIC Continue
                
                #; Form the property variable name
                Set tVarName=$Extract(tVarName,2,*)
                
            } else {
                
                #; If we are asking for the local context then don't report global
                #; variables
                If pContext=..#PRIVATE Continue
            }
                                  
            Kill tProp
            Set tSC=..CreatePropertyResponse(tVarName,tVarValue,.tProp)
            If $$$ISERR(tSC) Quit
            
            #; Give up if the response gets too long
            If $Length(pPropList)+$Length(tProp) > maxlen {
                Quit
            }
            
            #; Add the property to the response
            Set pPropList=pPropList_tProp
        }
   
    } Catch (e) {
    }
    Quit tSC
}

/// This method is given the debugger position (in the INT code) and returns a logical docname,label and offset
/// The client will have to perform addtional logic to find exactly where in the source document the location is
/// If pMapped is 0, then there is no source
ClassMethod GetClientPosFromDebugPos(pServerIntPos, Output pMapped, ByRef pNameSpace, Output pDocName, Output pLabel, Output pOffset)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tDocName,tIntLine,tIntName,tLabel,tLogicalPos,tOffset As %String
    #dim tRet As %Integer
    
    Try {
        
        Set tDocName=$Piece(pServerIntPos,"^",2)
        If tDocName["|" {
            Set pNameSpace=$Translate($Piece(tDocName,"|",2),"""")
            Set tDocName=$Piece(tDocName,"|",3)
        }
        
        Set tDocName=tDocName_".int"

        Set tLabel=$Piece($Piece(pServerIntPos,"^"),"+")
        Set tOffset=$Piece($Piece(pServerIntPos,"^"),"+",2)
        
        Set tSC=##class(%Studio.Debugger).INTLine(tDocName,tLabel,tOffset,.tIntName,.tIntLine,.tRet,pNameSpace)
        If $$$ISERR(tSC) Quit
        
        If tRet=2 {
            #; It can't be mapped, probably because there is no compiled source
            #; so we will just send back the raw location
            #; Was: Set pMapped=0,(pDocName,pLabel)="",pOffset=0
            Set pMapped=1,pDocName=tDocName,pLabel=tLabel,pOffset=+tOffset
            Quit
        }
        
        #; Now reconvert to discover source document, label, offset
        Set tSC=##class(%Studio.Debugger).MappedFromLine(tIntName,tIntLine,pNameSpace,.tLogicalPos)
        If $$$ISERR(tSC) Quit
        
        #; Successfully mapped
        Set pMapped=1
        
        If tLogicalPos'="" {
            Set pDocName=$Piece(tLogicalPos,",")
            Set pLabel=$Piece(tLogicalPos,",",2)
            Set pOffset=$Piece(tLogicalPos,",",3)
        } Else {
            Set pDocName=tIntName_".int"
            Set pLabel=""
            Set pOffset=tIntLine
        }
            
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Given a string that is the output of Quote(), check for control characters that were
/// left inside a quoted literal. If found, Quote that literal and insert it back into
/// the original string. This is done carefully so we don't end up with double-double quotes.
ClassMethod requote(value As %String) As %String
{
    set q=value
    set pi=1,limit=$Length(q,"""")
    while pi<=limit {
        set p=$Piece(q,"""",pi)
        if p?.E1.C.E {
            set nq=##class(%Global).Quote(p)
            if $Extract(nq)="""" {
                set $Extract(nq)=""
            } else {
                set nq="""_"_nq
            }
            if $Extract(nq,*)="""" {
                set $Extract(nq,*)=""
            } else {
                set nq=nq_"_"""
            }
            set $Piece(q,"""",pi)=nq
            set limit=limit+$Length(nq,"""")-1,pi=pi-1
        }
        set pi=pi+1
    }
    quit q
}

}
