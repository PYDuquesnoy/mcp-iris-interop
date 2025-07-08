/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class serves as an agent for terminal I/O.
Class %Atelier.v7.TerminalAgent Extends %CSP.WebSocket
{

/// Require development resource
Parameter SECURITYRESOURCE = "%Development";

/// The method name of "debug target" that we launch for the child process
Parameter DEBUGTARGET [ Internal ] = "ChildProcess";

/// Expression to enable external interrupts for the current process
Parameter ENABLEINTERRUPTEXPR [ Internal ] = "$SYSTEM.Util.SetInterruptEnable(1)";

Parameter TIMEOUT [ Internal ] = 0.02;

/// The terminal is waiting for the configuration message from the client
Parameter InitState [ Internal ] = 0;

/// The terminal is waiting for command input from the user
Parameter PromptState [ Internal ] = 1;

/// The terminal is waiting for READ input from the user
Parameter ReadState [ Internal ] = 2;

/// The terminal is executing user's input
Parameter ExecuteState [ Internal ] = 3;

/// This holds the TRACE flag
Property Trace As %Boolean [ InitialExpression = {$GET(^IRIS.Temp.Atelier("terminal")) > 0} ];

/// This holds the TRACE global node for this session
Property TraceNode As %Integer [ Internal ];

/// This holds the device list for $SYSTEM.Socket.Select
Property DeviceList As %List [ Internal ];

/// This holds the WebSocket device
Property WebSocketDevice As %String [ Internal ];

/// The state the the terminal is in
Property State As %String [ InitialExpression = {..#InitState}, Internal ];

/// This holds the debugger instance.
/// We use the debugger to control the child process.
Property Debug As %Debugger.System [ Internal ];

/// If true, enable &lt;EXTERNAL INTERRUPT&gt; before sending the prompt message
Property EnableInterruptBeforePrompt As %Boolean [ InitialExpression = 0, Internal ];

/// If true, ANSI escape codes will not be included in any text sent to the client
Property RawMode As %Boolean [ InitialExpression = 0, Internal ];

/// The last value of $KEY set by a child process READ.
Property ChildProcessDKey As %String [ Internal ];

/// The <CLASS>%SyntaxColor</CLASS> instance used to color prompt input
Property SyntaxColor As %SyntaxColor [ Internal ];

/// The value of <code>$PRINCIPAL</code> for the child process.
Property ChildProcessPrincipalDevice As %String [ Internal ];

/// Intialize the trace (if requested)
Method InitTrace() [ Internal, Private ]
{
    If ..Trace {
        Set ..TraceNode = $INCREMENT(^IRIS.Temp.Atelier("terminal",$JOB))
    }
}

/// Log a trace if tracing enabled
Method TraceMsg(pMsg As %String) [ Internal, Private ]
{
    If ..Trace {
        Set tNext = $INCREMENT(^IRIS.Temp.Atelier("terminal",$JOB,..TraceNode,0))
        Set ^(tNext) = pMsg
    }
}

/// Create the terminal prompt string. This method is called in the child process.
ClassMethod TerminalPrompt(pRawMode As %Boolean = 0) As %String [ Internal ]
{
    Set tTerminalPrompt = $SYSTEM.Process.TerminalPrompt(), tResult = ""
    If tTerminalPrompt '= "0" {
        For i=1:1:$LENGTH(tTerminalPrompt,",") {
            Set tPC = $PIECE(tTerminalPrompt,",",i)
            #; Support all prompt codes except 7
            Set tPCStr = $CASE(tPC,
                "1":$SYSTEM.INetInfo.LocalHostName(),
                "2":$NAMESPACE,
                "3":##class(%SYS.System).GetInstanceName(),
                "4":$ZTIME($PIECE($HOROLOG,",",2),1),
                "5":$JOB,
                "6":$USERNAME,
                "8":$SELECT($TLEVEL > 0:"TL"_$TLEVEL,1:""),
                :""
            )
            If tPCStr '= "" Set tResult = tResult_tPCStr_":"
        }
    }
    Set tResult = $SELECT($EXTRACT(tResult,*) = ":":$EXTRACT(tResult,1,*-1),1:tResult)_">"
    Quit $CASE(pRawMode,0:$CHAR(27)_"[1m"_tResult_$CHAR(27)_"[0m",:tResult)
}

/// Read data from the WebSocket device and convert it to a %DynamicObject
Method ReadFromWebSocket(Output pUserMsg As %DynamicObject) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    #; Read the data from the WebSocket
    Set tData = ..Read($$$MaxLocalLength,.tSC,..#TIMEOUT)
    If $$$ISERR(tSC) Quit tSC
    
    #; Trace what we received
    Do ..TraceMsg("Received: "_tData)

    #; Create the %DynamicObject
    Try {
        Set pUserMsg = ##class(%DynamicObject).%FromJSON(tData)
    } Catch (e) {
        Set tSC = e.AsStatus()
        Do ..TraceMsg("WebSocket read invalid JSON")
    }

    Quit tSC
}

/// Read output from the child process
Method ReadFromDebugDev(Output pOutput As %String) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Do ..TraceMsg("Reading output from child process")
    Set pOutput = ""
    Set tIO = $IO
    Try {
        Use ..Debug.Dev
        Do {
            #; Read until terminator
            Read tData:..#TIMEOUT Set tKey = $KEY
            #; Process the terminator
            Do ..TraceMsg("tKey: "_tKey_" ..ChildProcessDKey: "_..ChildProcessDKey)
            Do ..TraceMsg("tData: "_tData)
            Set pOutput = pOutput_tData_$SELECT(
                #; Add the newline characters if we terminated at the end of a line
                #; Don't add duplicate newlines where the output is delimited by
                #; $CHAR(13,10) instead of a single $CHAR(13) or single $CHAR(10)
                ((tKey = $CHAR(13)) || ((tKey = $CHAR(10)) && ((..ChildProcessDKey '= $CHAR(13)) || (tData '= "")))):$CHAR(13,10),
                #; Filter out ANSI escape codes if we're in raw mode
                $EXTRACT(tKey) = $CHAR(27):$CASE(..RawMode,0:tKey,:""),
                1:""
            ), ..ChildProcessDKey = tKey
        } While $EXTRACT(tKey) = $CHAR(27) ##; Keep going until we hit a newline or the end of the output
    } Catch (e) {
        If e.%IsA("%Exception.SystemException"), e.AsSystemError()["<READ>" {
            Kill pOutput
            Do ..TraceMsg("Child process device is closed")
        } Else {
            Set tSC = e.AsStatus()
            Do ..TraceMsg("Child process read error: "_$SYSTEM.Status.GetErrorText(tSC))
        }
    }
    Use tIO

    Quit tSC
}

/// Send an &lt;EXTERNAL INTERRUPT&gt; to the child process
Method InterruptChildProcess() As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    #; Only attempt to send <EXTERNAL INTERRUPT> if we know it's enabled
    If '..EnableInterruptBeforePrompt {
        #; Interrupt the child process
        Set ^IRIS.Temp.Atelier("terminal",$JOB,"interrupt") = 1, tRC = $SYSTEM.Util.SendInterrupt(..Debug.Pid)
        If tRC = 0 {
            Do ..TraceMsg("Interrupted child process")
            Set ..EnableInterruptBeforePrompt = 1
        } ElseIf tRC = 1 {
            Do ..TraceMsg("Interrupt failed because child process already exited")
            Set tSC = $$$ERROR($$$TerminalInterruptNoChild)
        } ElseIf tRC = 2 {
            Do ..TraceMsg("Interrupt failed because child process didn't respond")
            Set tSC = $$$ERROR($$$TerminalInterruptNoResponse)
        } ElseIf tRC = 3 {
            Do ..TraceMsg("Interrupt failed because child process hasn't enabled interrupts or is halting")
            Set tSC = $$$ERROR($$$TerminalInterruptHalting)
        }
    }

    Quit tSC
}

/// Send the JSON message to the WebSocket
Method SendMessageToWebSocket(pMsg As %DynamicObject) As %Status [ Internal, Private ]
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        Do ..TraceMsg("Sending "_pMsg.type_" message")

        #; Trace the message
        Set tMsgStr = pMsg.%ToJSON()
        Do ..TraceMsg("Sending: "_$EXTRACT(tMsgStr,1,200))
    
        #; Write the message to the WebSocket
        Set tSC = ..Write(tMsgStr)
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    
    Quit tSC
}

/// Send the terminal prompt message to the WebSocket
Method SendPromptToWebSocket() As %Status [ Internal, Private ]
{
    #; Make sure debugger knows it's stopped
    Do ..Debug.IsStopped(..#TIMEOUT)
    If ..EnableInterruptBeforePrompt {
        Do ..TraceMsg("Enabling external interrupt for child process")
        Set tRC = ..Debug.Eval(..#ENABLEINTERRUPTEXPR)
        If tRC > 1 Quit $$$ERROR(tRC)
        Set ..EnableInterruptBeforePrompt = 0
    }
    #; Generate the terminal prompt string in the child process
    Set tRC = ..Debug.Eval("##class("_$CLASSNAME()_").TerminalPrompt("_..RawMode_")",.tTerminalPrompt)
    If tRC '= 1 Quit $$$ERROR(tRC)
    Quit ..SendMessageToWebSocket({ "type": "prompt", "text": (tTerminalPrompt) })
}

/// Send the child process's output to the WebSocket
Method SendOutputToWebSocket(pOutput As %String) As %Status [ CodeMode = expression, Internal, Private ]
{
..SendMessageToWebSocket({ "type": "output", "text": (pOutput) })
}

/// Send the read message to the WebSocket.
/// No text is needed since it should already have been sent.
Method SendReadToWebSocket() As %Status [ CodeMode = expression, Internal, Private ]
{
..SendMessageToWebSocket({ "type": "read" })
}

/// Sanitize user input in response to a prompt
Method SanitizePromptInput(pInput As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$ZSTRIP($REPLACE($TRANSLATE(pInput,$CHAR(13,10),"  "),"""",""""""),"*C")
}

/// Check if user input is valid INT syntax.
/// If not, return the error output that should be sent to the user.
Method SyntaxCheckInput(pInput As %String) As %String [ Internal, Private ]
{
    Set (tResult, tSrc) = "", tSrc(0) = $LENGTH(pInput,$CHAR(13,10))
    #; Build the source array with awareness of user's multi-line input
    For i=1:1:tSrc(0) {
        Set tSrc(i) = " "_$ZSTRIP($ZSTRIP($PIECE(pInput,$CHAR(13,10),i),"*C"),"<W")
    }
    #; Check the syntax
    Set tRC = $$CHECK^%R(.tSrc,.tErrors)
    If tRC = 0 {
        #; Process the errors
        Set tPtr = 0, tResult = $CASE(..RawMode,0:$CHAR(27)_"[31;1m<SYNTAX>"_$CHAR(27)_"[0m",:"<SYNTAX>")
        While $LISTNEXT(tErrors,tPtr,tError) {
            Set tResult = tResult_$CHAR(13,10)
            If tSrc(0) > 1 {
                #; Only show the line number if there's more than one
                Set tResult = tResult_"Line "_$LIST(tError)_": "
            }
            Set tResult = tResult_$CASE(..RawMode,0:$CHAR(27)_"[31;1m"_$LIST(tError,4)_":"_$CHAR(27)_"[0m",:$LIST(tError,4)_":")_$PIECE($LIST(tError,5),":",4,*)
        }
    }

    Quit tResult
}

/// Returns pInput with ANSI escape codes that color the text
Method SyntaxColorInput(pInput As %String, Output pOutput As %String) As %Status
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        If ..RawMode {
            #; Can't do anything if we're in raw mode
            Set pOutput = pInput Quit
        }
        Set pOutput = "", tInStrm = ##class(%Stream.TmpCharacter).%New(), tOutStrm = ##class(%Stream.TmpCharacter).%New()
        #; Populate input stream
        Set tInputLines = $LENGTH(pInput,$CHAR(13,10))
        For i=1:1:$LENGTH(pInput,$CHAR(13,10)) {
            Set tInputLines(i) = $ZSTRIP($ZSTRIP($PIECE(pInput,$CHAR(13,10),i),"*C"),"<W")
            Set tSC = tInStrm.WriteLine(" "_tInputLines(i))
            If $$$ISERR(tSC) Quit
        }
        If $$$ISERR(tSC) Quit
        #; Syntax color INT input with "K" flag (JSON output)
        Set tRC = ..SyntaxColor.Color(.tInStrm,.tOutStrm,"INT","K")
        If 'tRC Set tSC = $$$ERROR($$$TerminalSyntaxColorFailed,..SyntaxColor.DLLResultCode) Quit
        #; Convert output stream to JSON
        Set tOutArr = ##class(%DynamicArray).%FromJSON(tOutStrm), tOutIter = tOutArr.%GetIterator()
        #; Build the output string
        While tOutIter.%GetNext(.tLineIdx,.tLineArr) {
            If tLineIdx > 0 {
                Set pOutput = pOutput_$CHAR(13,10)
            }
            Set tLineIter = tLineArr.%GetIterator(), tPrevColor = "0", tLastPosColored = 0
            While tLineIter.%GetNext(.tTknIdx,.tTknObj) {
                If tTknIdx = 0 {
                    #; Append the original number of spaces
                    Set pOutput = pOutput_$JUSTIFY("",$LENGTH($PIECE(pInput,$CHAR(13,10),tLineIdx + 1)) - $LENGTH($ZSTRIP($PIECE(pInput,$CHAR(13,10),tLineIdx + 1),"<W")))
                } Else {
                    #; Pick the color based on the token type
                    Set tColor = $CASE(tTknObj.s,
                        0:"31;1", ##; Bright red (errors)
                        5:"34",18:"34",58:"34",17:"34",27:"34",28:"34",53:"34",54:"34", ##; Blue ($ functions/vars, globals, ##class, JSON true/false)
                        7:"32",51:"32",31:"32",25:"32",6:"32",23:"32", ##; Green (comments, class/routine names, string/number literals)
                        47:"36",46:"36",49:"36",33:"36",34:"36",20:"36", ##; Cyan (local vars, i%var, r%var)
                        32:"35",52:"35", ##; Magenta (commands)
                        30:"33",35:"33",36:"33",55:"33",3:"33",14:"33",15:"33",22:"33", ##; Yellow (routine labels, class members)
                        :"0" ##; Default
                    )
                    If tColor '= tPrevColor, tTknObj.s '= 1 {
                        #; This non-whitespace token is a different color than the previous one, so change the color mode
                        Set pOutput = pOutput_$CHAR(27)_"["_tColor_"m"
                    }
                    Set tLastPosColored = tTknObj.p + tTknObj.c - 1
                    Set pOutput = pOutput_$EXTRACT(tInputLines(tLineIdx + 1),tTknObj.p,tLastPosColored)
                    If tTknObj.s '= 1 Set tPrevColor = tColor
                }
            }
            If tLastPosColored < $LENGTH(tInputLines(tLineIdx + 1)) {
                #; Color any text at the edn of the line that we missed as an error
                Set pOutput = pOutput_$CHAR(27)_"[31;1m"_$EXTRACT(tInputLines(tLineIdx + 1),tLastPosColored + 1,*)
            }
            #; Always reset the color at the end of a line
            Set pOutput = pOutput_$CHAR(27)_"[0m"
        }
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    
    Quit tSC
}

/// Event handler for the <b>PreServer</b> event: this is invoked before
/// starting the WebSockets Server.
Method OnPreServer() As %Status
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    Try {
        #; Don't allow access if the %Development resource cannot be used
        If '$SYSTEM.Security.Check("%Development","USE") {
            Set tSC = $$$ERROR($$$SecurityNotDeveloper) Quit
        }

        #; debug agent must be executed from a REST context
        If $$$GetSecurityApplicationsDispatchClass(%request.AppData) = "" {
            Set tSC = $$$ERROR($$$CSPIllegalRequest)
        }

        #; Create an instance of the debugger
        Set ..Debug = ##class(%Debugger.System).%New()
        Set ..Debug.trace = 0
        Set ..Debug.atelierTrace = -1
        
        #; Don't want the debugger to do its own output
        Set ..Debug.OutputToDebugDevice = 0

        #; Create an instance of %SyntaxColor
        Set ..SyntaxColor = ##class(%SyntaxColor).%New()
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    
    Quit tSC
}

/// Event handler for the <b>PostServer</b> event: this is invoked after
/// closing the WebSockets Server.
Method OnPostServer() As %Status
{
    Do ..TraceMsg("Entering OnPostServer()")
    #; If the debugger is attached, bring it down
    If ..Debug.Attached Do ..TraceMsg("Terminating child process"), ..Debug.Unattach()
    Kill ^IRIS.Temp.Atelier("terminal",$JOB,"interrupt")
    Do ..TraceMsg("Exiting OnPostServer()")
	Quit $$$OK
}

/// The WebSocket Server.  Use the <Method>Read</Method> and <Method>Write</Method> methods
/// to receive data from, and send data to, the client.
/// Call the <Method>EndServer</Method> method to gracefully terminate the WebSocket Server.
Method Server() As %Status
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException
    
    Try {
        
        #; Initially we are only reading from the WebSocket
        Set ..WebSocketDevice = $IO, ..DeviceList = $LISTBUILD(..WebSocketDevice)

        #; Using newline as a terminator
        Use ..WebSocketDevice:(/TERMINATOR=$CHAR(10))

        #; Initialize the trace
        Do ..InitTrace()

        #; Send the init message
        Set tSC = ..SendMessageToWebSocket({ "type": "init", "protocol": 1, "version": ($ZVERSION) })
        If $$$ISERR(tSC) Quit

        #; Enter the REPL
        Do ..TraceMsg("Entering loop")
        For {
            If ..State '= ..#ExecuteState {
                #; Only read from the WebSocket device
                Set tDeviceList = $SYSTEM.Socket.Select($LISTBUILD(..WebSocketDevice),..#TIMEOUT)
                If tDeviceList = -1 {
                    Do ..TraceMsg("Non-execute $SYSTEM.Socket.Select() interrupted")
                } ElseIf tDeviceList '= "" {
                    #; Make sure WebSocketDevice is ready for read
                    Set (tWsIO,tPtr) = 0
                    While $LISTNEXT(tDeviceList,tPtr,tDevice) {
                        If tDevice = ..WebSocketDevice {
                            Set tWsIO = 1 Quit
                        }
                    }
                    If tWsIO {
                        #; Read the data from the WebSocket
                        Set tSC = ..ReadFromWebSocket(.tUserMsg)
                        If $$$ISERR(tSC) Quit

                        If ..State = ..#InitState {
                            #; Process configuration message
                            If tUserMsg.type = "config" {
                                #; Set the initial namespace
                                Try {
                                    Do ..TraceMsg("Setting initial namespace to "_tUserMsg.namespace)
                                    Set $NAMESPACE = tUserMsg.namespace
                                } Catch (e) {
                                    Set tSC = e.AsStatus()
                                }
                                If $$$ISERR(tSC) Quit

                                #; Set ..RawMode
                                Set ..RawMode = tUserMsg.%Get("rawMode",0)
                                Do ..TraceMsg("Setting RawMode to "_..RawMode)

                                #; Start the child process
                                Do ..TraceMsg("Starting child process")
                                Set ..Debug.Killtarget = 1
                                Set tRC = ..Debug.StartTarget("##class("_$CLASSNAME()_")."_..#DEBUGTARGET_"()",0)
                                If tRC = 1 {
                                    #; Attached, check for debuggee output device open
                                    Do ..TraceMsg("Debug Device Name: "_..Debug.Dev)
                                    If ..Debug.Dev = "" {
                                        Set tSC = $$$ERROR($$$TerminalNoDevice) Quit
                                    }
                                    #; Set up the device list for reading two channels
                                    Set ..DeviceList = $LISTBUILD(..WebSocketDevice,..Debug.Dev)
                                } Else {
                                    Set tSC = $$$ERROR(tRC) Quit
                                }
                                #; Make sure argumentless BREAKs are enabled
                                Set tRC = ..Debug.Eval("$SYSTEM.Process.BreakMode(1)")
                                If tRC '= 1 Set tSC = $$$ERROR(tRC) Quit
                                #; Run to the argumentless BREAK in ChildProcess()
                                Set tRC = ..Debug.Resume()
                                If tRC '= 1 Set tSC = $$$ERROR(tRC) Quit
                                Set tIsStopped = ..Debug.IsStopped(..#TIMEOUT*100)
                                If tIsStopped = 0 {
                                    Set tSC = $$$ERROR($$$DebugNotStopped) Quit
                                } ElseIf tIsStopped '= 1 {
                                    Set tSC = $$$ERROR(tIsStopped) Quit
                                }

                                #; Save the principal device for the child process
                                Set tRC = ..Debug.Eval("$PRINCIPAL",.tPrincipal)
                                If tRC '= 1 Set tSC = $$$ERROR(tRC) Quit
                                Set ..ChildProcessPrincipalDevice = tPrincipal

                                #; Send the opening prompt
                                Set tSC = ..SendPromptToWebSocket()
                                If $$$ISERR(tSC) Quit
                                Set ..State = ..#PromptState
                            }
                        } Else {
                            #; Process the user input
                            If tUserMsg.type = "prompt" {
                                #; Check the syntax of the user's input
                                Do ..TraceMsg("Checking syntax of prompt input")
                                Set tSyntaxErrs = ..SyntaxCheckInput(tUserMsg.input)
                                If tSyntaxErrs '= "" {
                                    #; Send error output message
                                    Set tSC = ..SendOutputToWebSocket(tSyntaxErrs)
                                    If $$$ISERR(tSC) Quit
                                } Else {
                                    #; Execute the commands on the child process
                                    Do ..TraceMsg("Executing prompt input")
                                    Set tRC = ..Debug.DBGCommand(
                                        "Try {Xecute """_..SanitizePromptInput(tUserMsg.input)_"""} Catch (tTerminalErr) {"_
                                            "Write ##class("_$CLASSNAME()_").ExceptionHandler(tTerminalErr,"_..RawMode_") Kill tTerminalErr"_
                                        "} Use 0" ##; See note here https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GTER_intro#GTER_general_use
                                    ,1)
                                    If tRC '= 1 Set tSC = $$$ERROR(tRC) Quit
                                }
                                Set ..State = ..#ExecuteState
                            } ElseIf tUserMsg.type = "read" {
                                #; Send the input to the child process
                                Set tRC = ..Debug.Write(tUserMsg.input)
                                If tRC '= 1 Set tSC = $$$ERROR(tRC) Quit
                                Set ..State = ..#ExecuteState
                            } ElseIf tUserMsg.type = "interrupt" {
                                If ..State = ..#PromptState {
                                    #; We are at the prompt, so don't actually send an interrupt
                                    #; Output <INTERRUPT>
                                    Set tSC = ..SendOutputToWebSocket($CHAR(13,10)_$CASE(..RawMode,0:$CHAR(27)_"[31;1m<INTERRUPT>"_$CHAR(27)_"[0m",:"<INTERRUPT>")_$CHAR(13,10))
                                    If $$$ISERR(tSC) Quit
                                    #; Send the prompt message
                                    Set tSC = ..SendPromptToWebSocket()
                                    If $$$ISERR(tSC) Quit
                                } Else {
                                    #; We are performing a READ, so interrupt the child process
                                    Set tSC = ..InterruptChildProcess()
                                    If $$$ISERR(tSC) Quit
                                    #; Flip state so we can capture the interrupt output
                                    Set ..State = ..#ExecuteState
                                }
                            } ElseIf tUserMsg.type = "color", ..State = ..#PromptState {
                                #; Syntax color user input
                                Set tSC = ..SyntaxColorInput(tUserMsg.input,.tColoredInput)
                                If $$$ISERR(tSC) {
                                    #; Swallow this error because coloring isn't necessary for the terminal's functioning
                                    Do ..TraceMsg("Error syntax coloring input: "_$SYSTEM.Status.GetErrorText(tSC))
                                    Set tColoredInput = tUserMsg.input, tSC = $$$OK
                                }
                                #; Send the color message
                                Set tSC = ..SendMessageToWebSocket({ "type": "color", "text": (tColoredInput) })
                                If $$$ISERR(tSC) Quit
                            }
                        }
                    }
                } ElseIf ..State = ..#ReadState {
                    #; Check if a read timed out
                    Set tState = $SYSTEM.Process.State(..Debug.Pid)
                    If tState = "EVTW" {
                        #; Send the prompt message
                        Set tSC = ..SendPromptToWebSocket()
                        If $$$ISERR(tSC) Quit
                        Set ..State = ..#PromptState
                    } ElseIf ..Debug.IsStopped(0) = $$$DebugTargetExited {
                        #; The child process exited
                        Do ..TraceMsg("Child process exited") Quit
                    }
                }
            } Else {
                #; Read from either device
                Set tDeviceList = $SYSTEM.Socket.Select(..DeviceList,..#TIMEOUT)
                If tDeviceList = -1 {
                    Do ..TraceMsg("ExecuteState $SYSTEM.Socket.Select() interrupted")
                } ElseIf tDeviceList '= "" {
                    #; Determine source of I/O
                    Set (tWsIO,tDbgIO,tPtr) = 0
                    While $LISTNEXT(tDeviceList,tPtr,tDevice) {
                        If tDevice = ..WebSocketDevice {
                            Set tWsIO = 1
                        } ElseIf tDevice = ..Debug.Dev {
                            Set tDbgIO = 1
                        }
                    }
                    #; Prioritize the WebSocket
                    If tWsIO {
                        #; Read the data from the WebSocket
                        Set tSC = ..ReadFromWebSocket(.tUserMsg)
                        If $$$ISERR(tSC) Quit

                        #; Process the user input
                        If tUserMsg.type = "interrupt" {
                            #; Interrupt the child process
                            Set tSC = ..InterruptChildProcess()
                            If $$$ISERR(tSC) Quit
                        }
                    }
                    If tDbgIO {
                        #; Read from the child process
                        Set tSC = ..ReadFromDebugDev(.tOutput)
                        If $$$ISERR(tSC) Quit
                        If '$DATA(tOutput) Quit ##; Child process exited
                        If tOutput '= "" {
                            #; Send output message to the WebSocket
                            Set tSC = ..SendOutputToWebSocket(tOutput)
                            If $$$ISERR(tSC) Quit
                        } Else {
                            Do ..TraceMsg("Skip sending empty output")
                        }
                    }
                } Else {
                    #; Check if we're done executing
                    Set tState = $SYSTEM.Process.State(..Debug.Pid), tStopped = ..Debug.IsStopped(0)
                    If (
                        #; Ready for the next command
                        (
                            (tState = "EVTW") &&
                            (tStopped = 1) &&
                            ($SYSTEM.Process.Routine(..Debug.Pid) = ($CLASSNAME()_".1"))
                        ) ||
                        #; Reading from the principal device
                        (
                            ($EXTRACT(tState,1,4) = "READ") &&
                            ($SYSTEM.Process.CurrentDevice(..Debug.Pid) = ..ChildProcessPrincipalDevice)
                        )
                    ) {
                        #; Child process is done executing
                        If tState = "EVTW" {
                            #; Send the prompt message
                            Set tSC = ..SendPromptToWebSocket()
                            If $$$ISERR(tSC) Quit
                            Set ..State = ..#PromptState
                        } Else {
                            #; Send the read message
                            Set tSC = ..SendReadToWebSocket()
                            If $$$ISERR(tSC) Quit
                            Set ..State = ..#ReadState
                        }
                        Set ..ChildProcessDKey = ""
                    } ElseIf tStopped = $$$DebugTargetExited {
                        #; The child process exited
                        Do ..TraceMsg("Child process exited") Quit
                    }
                }
            }
        }

        If $$$ISERR(tSC) Do ..TraceMsg("Server error running loop: "_$SYSTEM.Status.GetErrorText(tSC))
        
        #; Terminate the child process if it's alive
        If ..Debug.Attached Do ..TraceMsg("Terminating child process"), ..Debug.Unattach()
        
        Do ..TraceMsg("Exiting Server()")
    
    } Catch (e) {
        Set tSC = e.AsStatus()
        Do ..TraceMsg("Uncaught error: "_$SYSTEM.Status.GetErrorText(tSC))
    }

    #; Report error before closing the WebSocket
    If $$$ISERR(tSC), '$$$ERRORISTYPE(tSC,$$$CSPWebSocketClosed) {
        Do ..SendMessageToWebSocket({
            "type": "error",
            "text": ($SYSTEM.Status.GetErrorText(tSC))
        })
    }
    
    #; Now end the server, letting the messages flush
    Hang ..#TIMEOUT
    Do ..EndServer()
    
    Quit tSC
}

/// Dummy method to use as the "debug target" in the child process.
ClassMethod ChildProcess() [ Internal ]
{
    Break
    Quit $$$OK
}

/// Helper method used for processing exceptions caused by user input
ClassMethod ExceptionHandler(pEx As %Exception.AbstractException, pRawMode As %Boolean = 0) As %String [ Internal ]
{
    Set tResult = ""
    If pEx.%IsA("%Exception.SystemException") {
        Set tResult = pEx.AsSystemError()
        #; Strip out the location if it's this routine
        If tResult[("^"_$CLASSNAME()_".1") {
            Set tResult = $PIECE(tResult,">",1)_">"_$EXTRACT(tResult,$FIND(tResult,"^"_$CLASSNAME()_".1"),*)
        }
        If $GET(^IRIS.Temp.Atelier("terminal",$ZPARENT,"interrupt")) {
            #; Show the <EXTERNAL INTERRUPT> as an <INTERRUPT> like the regular terminal
            Set tResult = $REPLACE(tResult,"<EXTERNAL INTERRUPT>","<INTERRUPT>"), ^IRIS.Temp.Atelier("terminal",$ZPARENT,"interrupt") = 0
        }
        If 'pRawMode {
            #; Add the bright red ANSI escape sequence to the angle-bracketed portion
            Set tResult = $CHAR(27)_"[31;1m"_$PIECE(tResult,">",1)_">"_$CHAR(27)_"[0m"_$PIECE(tResult,">",2,*)
        }
    } Else {
        Set tResult = $SYSTEM.Status.GetOneErrorText(pEx.AsStatus())
        If 'pRawMode {
            #; Add the bright red ANSI escape sequence to the "ERROR #NNNN:" portion
            Set tResult = $CHAR(27)_"[31;1m"_$PIECE(tResult,":",1)_":"_$CHAR(27)_"[0m"_$PIECE(tResult,":",2,*)
        }
    }
    Quit $CHAR(13,10)_tResult
}

}
