/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occErrors, %syDebug, %occUtility, LANG11)

/// This class is used internally by InterSystems. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// <center><b><font size=+2>System Debugging in InterSystems IRIS</font></b></center>
/// <b><font size=+1>Overview</font></b>
/// <p>The system debugger allows external debugging of processes via a set of debugging
/// commands provided by the class %Debugger.System.
/// The debugger may be used to attach to processes running ObjectScript routines, or to start routines for debugging. In
/// either case, the user must: <o:p></o:p></span></p>
/// <ul type=disc>
/// <li>Start a target process, specifying what routine it is to
///     execute (optional) </li>
/// <li>Attach to the target process </li>
/// <li>Issue commands to the target process to control its execution </li>
/// </ul>
/// <p>Any process
/// executing routines may be attached to by a user
/// with suitable privileges. <o:p></o:p></span></p>
/// <p>Debugging methods are provided
/// which allow the user to: <o:p></o:p></span></p>
/// <ul type=disc>
/// <li>Attach to the process and put it in break mode <o:p></o:p></span></li>
/// <li>Control execution (break, step, step into, step out, continue) <o:p></o:p></span></li>
/// <li>Set and clear breakpoints and <span class=SpellE>watchpoints</span>
///     <o:p></o:p></span></li>
/// <li>View current location and stack information <o:p></o:p></span></li>
/// <li>View and set variables, evaluate expressions, and execute COS
///     commands <o:p></o:p></span></li>
/// </ul>
/// <p>Commands may only be issued when the target is in break mode. Since the state of the target
/// is uncertain following any debugger command, the method <METHOD>IsStopped</METHOD> must be used to test if the process is in fact in break mode. After a process
/// has been attached, this method must be called, and return successfully,
/// following every debugger command, before another command may be issued. The
/// exceptions are <METHOD>Unattach</METHOD> (detach from a process and stop debugging), and <METHOD>Break</METHOD>
/// (break into a process which is executing under debugger control). <o:p></o:p></span></p>
/// <p><span style='font-family:Helvetica;color:black'>Location information is
/// automatically returned whenever the process breaks. The property
/// <PROPERTY>Location</PROPERTY> contains the raw location information. The methods
/// <METHOD>GetOffset</METHOD> and <METHOD>GetSource</METHOD>
/// may be used to obtain analysed location and source
/// data. <o:p></o:p></span></p>
/// <p><b><font size=+1>Terminals</font></b>
/// <p>Two terminal output windows may be started. One of the windows is started when
/// processes are started by the debugger,and is the principle device for the process. <o:p></o:p></span></p>
/// <p>Another window may be started after any process is attached, which is the debug device
/// for the process. All debugger output is displayed in this window. <o:p></o:p></span></p>
/// <p>Both of these windows are also available when debugging remote processes. In this case, the windows are
/// started on the local platform. <o:p></o:p></span></p>
/// <p><b><font size=+1>Starting a routine</font></b>
/// <p>The Debugger provides a stub which is jobbed to create a debug process. This stub awaits debugger commands
/// to open a terminal window, and execute the desired routine. <o:p></o:p></span></p>
/// <p>The method <METHOD>StartTarget</METHOD>, which takes a routine name as an argument, uses this stub to begin debugging a
/// routine. It jobs the stub to begin execution, starts the <span class=SpellE>Cterm</span>
/// windows, attaches to the process, and signals what routine is to be run. Upon
/// completion, the process is ready for debugging. Breakpoints may be set and the
/// routine executed. <o:p></o:p></span></p>
/// <p><p><b><font size=+1>Attaching a process</font></b>
/// <p>Any process may be attached for debugging. The method <METHOD>Attach</METHOD> takes a numeric process id as an argument.
/// Upon successful completion, the target is ready to be debugged. <o:p></o:p></span></p>
/// <p><p><b><font size=+1>Remote Debugging</font></b>
/// <p>Remote and local debugging are identical, except for the sequence of commands required
/// to open the Cterm windows. Since the Cterm windows are on the local platform, a separate %Debugger.System
/// instance must be used on the local and remote platforms. <o:p></o:p></span></p>
/// <p>To start a process, the user follows this sequence: <o:p></o:p></span></p>
/// <ul type=disc>
/// <li>(Remote platform) Start the target stub via <METHOD>StartTargetRemote</METHOD>
///     <o:p></o:p></span></li>
/// <li>(Local platform) Start the <span class=SpellE>cterm</span> via <METHOD>Cterm</METHOD>,
///     using the output port information returned from <METHOD>StartTargetRemote</METHOD>
///     <o:p></o:p></span></li>
/// <li>(Remote platform) Attach the target stub via <METHOD>DebugTarget</METHOD>
///     <o:p></o:p></span></li>
/// </ul>
/// 
/// <p>Remember that upon successful completion of any command, the target may not be in
/// break mode. The method <METHOD>IsStopped</METHOD> must be explicitly invoked, and return a success code, 
/// before any new commands may be issued.
/// </body>
/// </html>
Class %Debugger.System Extends %Library.RegisteredObject [ System = 3 ]
{

/// Flag indicating whether we are Attached to a target.
Property Attached As %Boolean [ InitialExpression = 0 ];

/// Session ID of target process.  Target signals on this Event.
Property Sid As %String(TRUNCATE = 1);

/// Command ID of target process.  Target waits for commands on this Event
Property CmdId As %String;

/// Process ID of target process
Property Pid As %String(TRUNCATE = 1);

/// Job number of target process
Property Job As %Integer;

/// Current Location info for target process
Property Location As %String(TRUNCATE = 0);

/// Current Stack info for target process
Property Stack As %String(TRUNCATE = 0);

/// Flag indicating if target is stopped
Property Stopped As %Boolean [ InitialExpression = 0 ];

/// Event id of this debugger instance
Property DebId As %String(TRUNCATE = 1);

/// Device for i/o redirecttion
Property Dev As %String(TRUNCATE = 1);

/// Flag indicating we have attempted to open an i/o device
Property DevOpen As %Boolean [ InitialExpression = 0 ];

/// Kill target on disconnect flag
Property Killtarget As %Boolean [ InitialExpression = 0 ];

/// Result set for Variables
Property RsetVars As %ResultSet [ InitialExpression = 0 ];

Property trace As %Boolean [ InitialExpression = 0 ];

/// Set to non-zero if running under Atelier debugger<br>
/// -1 means no trace<br>
/// >0 is the Atelier trace node
Property atelierTrace As %Boolean [ InitialExpression = 0 ];

/// This property can be used to disable outputing of device data by setting the value to 0
Property OutputToDebugDevice [ InitialExpression = 1 ];

/// Attach to another process having process id of pid.
/// <p>Fails if already attached (use <method>Unattach</method> first),or
/// if pid is invalid.
/// <p>On successful completion, process is attached and a break issued.
/// The process will be in break mode upon completion of its current operation.
Method Attach(pid As %String = "") As %Integer
{
    if '..atelierTrace,$get(^%apiOLE("debug")) s ..trace = 1
    If (..Attached) Quit $$$DebugAttached
    If (pid = "") Quit $$$DebugMissingPID
    If (pid <= 0) Quit $$$DebugInvalidPID

    s ..Stopped = 0

    Set $ZT = "DBGERR"

    Set ..Pid = pid
    Set ..Job = $zu(67,3,pid)
    
    If '..Job Quit $$$DebugBadPID
    
    Do ..Trace("PID "_..Pid)

    // get debug session id
    s ..Sid=$$SESSION^%SYS.Debug(..Pid)
    // get debug command id
    s ..CmdId="CMD"_..Sid
    s rc = $system.Event.Create(..Sid)
    s rc = $system.Event.Create(..CmdId)

    #; Open a debugging session in the target process.
    #; The target is set for debugging, and a break is pending.
    s sc = $ZU(25,pid,0)

    If (sc'=1) {
        Do ..Trace("Attach to target failed with code "_sc_" id "_..Sid)
        Do $system.Event.Delete(..Sid)
        Do $system.Event.Delete(..CmdId)
        if sc=-1 {
            Quit $$$DebugInDebugMode
        } elseif sc=-2 {
            Quit $$$DebugInSignonMode
        } else {
            Quit $$$DebugAttachFailed
        }
    }

 Set ..Attached = 1

 Quit $$$OK

DBGERR
 // We got some sort of error
 Do ..Trace("Attach error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugAttachFailed
}

/// Send a BREAK to the target process.
/// <p>On successful completion, a break has been issued.
/// The process will be in break mode upon completion of its current operation.
Method Break() As %Integer
{
 // Attached?
 If '..Attached Quit $$$DebugNotAttached
 If ..Stopped  Quit $$$OK

 // break into target
 s x=$$BREAK^%SYS.Debug(..Pid)
 If x'=$$$OK Quit $$$DebugBreakFailed

 Quit $$$OK
}

/// Return true if the target is in break mode.
Method IsStopped(timeout As %Integer = 1) As %Integer
{
 Do ..Trace("IsStopped")
 If '..Attached Quit $$$DebugTargetExited
 If (..Stopped) Quit $$$OK
 
 Set $ZT = "DBGERR"
 // Wait for a few seconds to see if stopped
waittarget
 s rc=$system.Event.WaitMsg(..Sid,timeout)
 i $li(rc)'=1 {
    #; $ZU(61,job#) returns pid if it exists and is alive otherwise returns 0 to indicate job is gone.
    i ($li(rc)=-1) ||( $zu(61,..Job)'=..Pid) {
        s rc = $$$DebugTargetExited
        Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerExited"),!
        s ..Stopped = 1
        s ..Attached = 0
        d $system.Event.Delete(..Sid)
        d $system.Event.Delete(..CmdId)
    } else {
        s rc = 0
    }
    goto DBGEXIT
 }
 ;target is stopped or exited
 s ..Stopped = 1

 #;"::0:0:0:0:2:0:0:0:0:0:USER%All
 s ..Location=$p($li(rc,2),"~",1)
 Do ..Trace("Location "_..Location)
 s stacktemp=$p($li(rc,2),"~",2)
 i $p(..Location,":",2)="" {
    ;we are no longer in a routine.  Unattach.
    s x = $$CLOSE^%SYS.Debug(..Pid)
    s rc=$system.Event.Signal(..CmdId,"B ""OFF""")
    s ..Attached = 0
    If rc '= $$$OK { Do ..Trace("Signal to target failed "_rc) Q rc }
    s rc = $$$DebugTargetExited
    Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerExited"),!
    goto DBGEXIT
 }
 ;target is stopped at a location
 s ..Stack=""
 f i=1:1:$l(stacktemp,$c(0)) {
    s stk = $p(stacktemp,$c(0),i)
    i $p(stk,"^",3) '= "" {
        i ..Stack="" {s ..Stack=(i-1)_"^"_$p(stk,"^",2,3)}
        else {s ..Stack = ..Stack_":"_(i-1)_"^"_$p(stk,"^",2,3)}
    }
 }
 Do ..Trace("Stack "_..Stack)
 ; if no debug device has been set up, do so now
 if ('..DevOpen) {
    s ..DevOpen = 1
    ; open debug device
    Do ..Trace("Opening Debug device")
    s rc = ..DBGCommand("B ""C"" D DBGDEV^%SYS.Debug("""_..Sid_""")",1)
    if rc '= $$$OK { Do ..Trace("DBGDEV failed "_..Sid) goto DBGERR }
    ; wait for job to be ready
    s rc=$system.Event.WaitMsg(..Sid,10)
    if $li(rc)'=1 { Do ..Trace("WaitMsg failed "_$li(rc)_" "_$lg(rc,2)) goto DBGERR }
    // connect to the port
    s port=$li(rc,2)
    if port'= 0 {
        s rc = ..LocalIO(port)
        if 'rc { Do ..Trace("LocalIO failed "_rc) w $$$GetSimpleMessage("%Studio","DebuggerNoIO"),! }
    } else {
        Do ..Trace("port 0")
        w $$$GetSimpleMessage("%Studio","DebuggerNoIO"),!
    }
    // Go back and wait for target to stop
    goto waittarget
 }

 s rc = $$$OK
DBGEXIT
 if (..Dev'="") && (rc'=$$$DebugTargetExited) {
    Set $ZT = "DBGERR1"
    ;Display any output
    d {
        If ..OutputToDebugDevice=0 Quit
        s outp=""
        f i=1:1:$$$MaxLocalLength {
            u ..Dev r x#1:0
            q:$t=0
            i ($ASCII(x)=-1) {
                s outp=outp_$ZB
            } elseif $ASCII(x) {
                s outp=outp_x
            }
        }
        U 0
        w:outp'="" outp
        ;do not continue forever if target not stopped
        q:rc=0
    } while outp'=""
 }
 Q rc
DBGERR
 Set $ZT = ""
 Do ..Trace("IsStopped error"_$ze)
 s rc = $$$DebugTargetExited
 Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerExited"),!
 goto DBGEXIT
DBGERR1
 s $ZT=""
 Do ..Trace("i/o error"_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerExited"),!
 Quit $$$DebugTargetExited
}

/// Interrupt the target process
/// <p>The target process is sent a software interrupt.  This causes
/// the target to break.  The next line of code will be executed when
/// the target is resumed.
Method Interrupt() As %Integer
{
 If '..Attached Quit $$$DebugNotAttached
 s rc=$system.Util.SendInterrupt(..Pid)
 If rc Quit $$$DebugTargetExited
 ; wait until break
 f i=1:1:2 s rc = ..IsStopped(1) q:rc
 If rc '= $$$OK Q rc
 // send step command to get us out of break frame
 s rc = ..DBGCommand("B ""S+"" G")
 If rc '= $$$OK Q rc
 ; wait until break
 s rc = ..IsStopped(1)
 Q rc
}

/// Write to the target process
Method Write(data As %String) As %Integer
{
 S $ZT="WRITEE"
 if ..Dev'="" {
     if data=""{
         s data = $c(27)_"["_$c(255)
     }
     USE ..Dev:(/PAD=0) w data,!
     U 0
 }
 Q $$$OK
WRITEE
 Set $ZT = ""
 Do ..Trace("Write error"_$ze)
 QUIT $$$ObjectScriptError
}

/// Perform a debug command.
Method DBGCommand(cmd As %String, issys As %Integer = 0) As %Integer
{
 // Attached?
 If '..Attached Quit $$$DebugNotAttached
 If '..Stopped Quit $$$DebugNotStopped

 Set $ZT = "DBGERR"
 #; If a system command, mark as exempt from secure shell restrictions
 If issys Set cmd=cmd_";"_$C(1)
 // send debug command
 s rc=$system.Event.Signal(..CmdId,cmd)
 i rc'=1 {
    Do ..Trace("DBGCommand signal "_rc)
    s ..Attached=0
    Quit $$$DebugTargetExited
 }
 // target is running
 s ..Stopped=0
 Quit $$$OK
DBGERR
 s $zt=""
 Do ..Trace("DBGCommand error "_$ze)
 // We got some sort of error
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

/// Continue the current process
Method Go() As %Integer
{
 Q ..DBGCommand("B ""C"" G")
}

/// Continue the current process without stepping on return
Method Resume() As %Integer
{
 Q ..DBGCommand("B ""C-"" G")
}

/// Continue the current process at tag
Method GoTo(tag As %String) As %Integer
{
 Q ..DBGCommand("B ""L"" G "_tag)
}

Method Line() As %Integer
{
 Q ..DBGCommand("B ""L"" G")
}

Method LineIn() As %Integer
{
 Q ..DBGCommand("B ""L+"" G")
}

Method LineOut() As %Integer
{
 Q ..DBGCommand("B ""L-"" G")
}

Method SetBreakpoint(routine As %String, offset As %Integer, condition As %String = "") As %Integer
{
 Set $ZT = "DBGERR"

 s cmd = "ZB +"_offset_"^"_routine
 If condition'="" {
    s cmd = cmd_"::"_$$$quote(condition)
 }
 ; issue the command
 s rc = ..DBGCommand(cmd)
 ; wait until break
 s rc = ..IsStopped(-1)
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("SetBreakpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method DisableBreakpoint(routine As %String, offset As %Integer, counter As %Integer = 0) As %Integer
{
 Set $ZT = "DBGERR"

 s cmd = "ZB -+"_offset_"^"_routine
 If counter
    s cmd = cmd_"#"_counter
 ; issue the command
 s rc = ..DBGCommand(cmd)
 ; wait until break
 s rc = ..IsStopped(-1) 
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("DisableBreakpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method RemoveBreakpoint(routine As %String, offset As %Integer) As %Integer
{
 Set $ZT = "DBGERR"

 s rc = ..DBGCommand("ZB --+"_offset_"^"_routine)
 ; wait until break
 s rc = ..IsStopped(-1) 
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("RemoveBreakpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method ClearBreakpoints() As %Integer
{
 s rc = ..DBGCommand("ZB /CLEAR")
 ; wait until break
 s rc = ..IsStopped(-1) 
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("ClearBreakpoints error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method SetWatchpoint(variable As %String, condition As %String = "") As %Integer
{
 Set $ZT = "DBGERR"

 s cmd = "ZB *"_variable
 If condition'="" {
    s cmd = cmd_"::"_$$$quote(condition)
 }
 ; issue the command
 s rc = ..DBGCommand(cmd)
 ; wait until break
 s rc = ..IsStopped(-1)
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("SetWatchpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method DisableWatchpoint(variable As %String, counter As %Integer = 0) As %Integer
{
 Set $ZT = "DBGERR"

 s cmd = "ZB -*"_variable
 If counter
    s cmd = cmd_"#"_counter
 ; issue the command
 s rc = ..DBGCommand(cmd)
 ; wait until break
 s rc = ..IsStopped(-1) 
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("DisableWatchpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method RemoveWatchpoint(variable As %String) As %Integer
{
 Set $ZT = "DBGERR"

 s rc = ..DBGCommand("ZB --*"_variable)
 ; wait until break
 s rc = ..IsStopped(-1) 
 Quit rc
DBGERR
 // We got some sort of error
 s $zt=""
 Do ..Trace("RemoveWatchpoint error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method Step() As %Integer
{
 Q ..DBGCommand("B ""S"" G")
}

Method StepIn() As %Integer
{
 Q ..DBGCommand("B ""S+"" G")
}

Method StepOut() As %Integer
{
 Q ..DBGCommand("B ""S-"" G")
}

/// Sets a variable to a value.
Method SetValue(variable As %String = "", value As %String = "") As %Integer
{
 // send SET command to target to set a variable
 Set cmd = "SET "_variable_"="_$$$quoteall(value)
 s rc = ..DBGCommand(cmd)
 
 ; wait until break
 s rc = ..IsStopped(-1)
 If rc '= $$$OK Q rc
    
 Quit rc
}

/// Gets the value of a variable
Method GetValue(Variable As %String = "", ByRef Value As %String, Lang As %Integer = 0) As %Integer
{
#;SML940+ ; rewrite this without calling %SYS.ProcessQuery.
#; When the private variable exists then we display the private variable
#; otherwise we display the public variable.
#; $ZU(88,9) is $DATA, $ZU(88,8) is $GET
 if $E(Variable)'="%" {
     s pvVariable = "~"_Variable
     s pvd = $zu(88,9,..Pid,pvVariable,Lang)
     if 'pvd,Lang=11,$$$MVEmuGetAccountValue($$$MVEmuTABLENUM)=$$$MVEmuD3 {
         s pbd = $Find(Variable,"("), rc = $Select(pbd:$E(Variable,1,pbd-2),1:Variable)
         s cmd = $ZCVT(rc,"U") i cmd'=rc {
             set pvVariable = "~"_cmd set:pbd pvVariable=pvVariable_"("_$E(Variable,pbd,*)
             set pvd = $zu(88,9,..Pid,pvVariable,Lang)
         }
     }
 } else { s pvd=0 }
 If pvd#2 {
     Set Value = $zu(88,8,..Pid,pvVariable,Lang)
     If pvd > 1 Set Value = Value_",..."
 } ElseIf pvd {
     Set Value = $Select(Lang=11:"<ARRAY>",1:"<UNDEFINED>,...")
 } Else {
     If Lang=11 {
        Set rc = $Find(Variable,"""") While rc {
            Set Variable = $E(Variable,1,rc-1)_""""_$E(Variable,rc,*)
            Set rc = $F(Variable,"""",rc+1)
        }
        Set cmd = "Set SYSDebugXyZzYSID = $ZVAR("""_Variable_""")"
        s rc = ..DBGCommand(cmd,1)
        Q:rc'=$$$OK rc
        s rc = ..IsStopped(-1)
        Q:rc'=$$$OK rc
        s cmd = "B ""C"" d $system.Event.Signal("""_..Sid_""",$g(SYSDebugXyZzYSID,""<UNDEFINED>"")) "_"k SYSDebugXyZzYSID"
        s rc = ..DBGCommand(cmd,1)
        Q:rc'=$$$OK rc
        #; wait for reply
        s rc=$system.Event.WaitMsg(..Sid,10)
        if $li(rc)'=1 { Do ..Trace("Eval Wait error "_$li(rc)_" "_$lg(rc,2)) Quit $$$DebugError }
        #; get the data
        s Value=$li(rc,2)
        ; wait until target returns
        s rc = ..IsStopped(-1)
        If Value'="<UNASSIGNED>" Quit rc
     }
     Set pbd = $zu(88,9,..Pid,Variable,Lang)
     If pbd#2 {
        Set Value = $zu(88,8,..Pid,Variable,Lang)
        If pbd > 1 Set Value = Value_",..."
     } ElseIf pbd {
        Set Value = $Select(Lang=11:"<ARRAY>",1:"<UNDEFINED>,...")
     } Else {
        Set:Lang'=11 Value = "<UNDEFINED>"
     }
 }
#;SML940-
 Q $$$OK
}

/// Evaluate and return the properties / values of variable which is an oref and any of its child objects, up to <b>maxdepth</b>
Method Atelierv5EvalOref(oref As %String, maxdepth As %Integer, ByRef result As %String) As %Status
{
    #Dim sc As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        If '..Attached Set sc = $$$ERROR($$$DebugNotAttached) Quit
        If '..Stopped Set sc = $$$ERROR($$$DebugNotStopped) Quit
        
        Do ..Trace("Atelierv5EvalOref "_oref)
        
        #; issue command to the target
        Set rc = ..DBGCommand("B ""C"" D ATELIERv5OREF^%SYS.Debug("""_..Sid_""","""_oref_""","_maxdepth_")",1)
        If rc '= 1 Set sc = $$$ERROR(rc) Quit

        #; wait for reply
        Set msg = $SYSTEM.Event.WaitMsg(..Sid,10), rc = $LIST(msg,1), resultlist = $LIST(msg,2)
        If rc '= 1 Do ..Trace("Atelierv5EvalOref Wait error "_rc) Quit
        Do ..Trace("Atelierv5EvalOref result "_resultlist)

        Set sc = $LIST(resultlist,1), result = $LIST(resultlist,2)

        #; wait until target returns
        Set rc = ..IsStopped(-1)
        If rc '= 1 {
            If $$$ISERR(sc) {
                Set sc = $SYSTEM.Status.AppendStatus(sc,$$$ERROR(rc))
            }
            Else {
                Set sc = $$$ERROR(rc)
            }
        }
    } Catch (e) {
        Do ..Trace("Atelierv5EvalOref error "_e.DisplayString())
        Set ..Sid = "", ..Attached = 0, rc = $$$DebugTargetExited
    }
    Quit sc
}

/// Evaluate and return the property/value pairs of variable which is an oref 
Method EvalOref(oref As %String = "", ByRef vararray As %Binary) As %Integer
{
    If '..Attached Quit $$$DebugNotAttached
    If ('..Stopped) Quit $$$DebugNotStopped
    
    s $ZT="DBGERR"
    Do ..Trace("EvalOref "_oref)

    ; issue command to the target
    s rc = ..DBGCommand("B ""C"" D OREF^%SYS.Debug("""_..Sid_""","_oref_")",1)
    if rc '= $$$OK goto DBGERR
    ; wait for reply
    s rc=$system.Event.WaitMsg(..Sid,10)
    if $li(rc)'=1 { Do ..Trace("EvalOref Wait error "_$li(rc)_" "_$lg(rc,2)) goto DBGERR }
    // get the data
    s vararray=$li(rc,2)
    Do ..Trace("EvalOref result "_vararray)
    ; wait until target returns
    s rc = ..IsStopped(-1)
    Q rc
DBGERR ;
    // We got some sort of error
    s $zt=""
    Do ..Trace("EvalOref error "_$ze)
    Set ..Sid = ""
    Set ..Attached = 0
    Quit $$$DebugTargetExited
}

/// Evaluate and return the value of expression 
/// <var>expr</var> within the target process.
Method Eval(expr As %String = "", ByRef result As %String) As %Integer
{
 If ('..Attached) Quit $$$DebugNotAttached
 If ('..Stopped) Quit $$$DebugNotStopped

 #; Test for variable or COS array
 Set lang=+$P(..Location,":",12)
 if lang=11 && ($E(expr,*)=">") && $ZNAME($P($P(expr,"<"),"("),0,11) &&
    (..GetValue($P(expr,"<"),.result,11)=$$$OK) {
    If result="<UNASSIGNED>" Quit $$$OK
    If result'["""" { Set result=""""_result_"""" }
    ElseIf result'["'" { Set result="'"_result_"'" }
    Else  { Set result="\"_result_"\" }
    Set cmd = ";SYSDebugXyZzYSID = "_result_"<"_$P(expr,"<",2,999)
    Set rc = ..DBGCommand(cmd,1)
    Goto chkcmd
 }
 Try { If $ZNAME(expr,0,lang) ||
       (lang<9 && $ZNAME($P(expr,"("),0,lang) && ($QLENGTH(expr)>=0)) ||
       (lang=11 && $ZNAME($P(expr,"("),0,lang) && ($QLENGTH("x("_$P(expr,"(",2,99))>=0)) 
       { Set rc = ..GetValue(expr,.result,lang) }
       Else { Goto EvalExpr }
 } Catch { Goto EvalExpr }
 Quit rc
 
EvalExpr
 #; Send an expression to the target to be evaluated
 if (lang=9) {
    Set cmd = "SYSDebugXyZzYSID = "
 } elseif (lang=11) {
    Set cmd = ";SYSDebugXyZzYSID = "
 } else {
    Set cmd = "try { set SYSDebugXyZzYSID="_expr_" } catch { set SYSDebugXyZzYSID=$E($ZE,1,$F($ZE,"">"")-1) }"
    set rc = ..DBGCommand(cmd,1)
    goto chkcmd
}
 s rc = ..DBGCommand(cmd_expr,1)
chkcmd 
 Q:rc'=$$$OK rc
 s rc = ..IsStopped(-1)
 Q:rc'=$$$OK rc
    
 s cmd = "B ""C"" d $system.Event.Signal("""_..Sid_""",$g(SYSDebugXyZzYSID,""<UNDEFINED>"")) "
 if (lang=9) {
    Set cmd = cmd_"erase SYSDebugXyZzYSID"
 } elseif (lang=11) {
    Set cmd = cmd_";$KILL SYSDebugXyZzYSID"
 } else {
    Set cmd = cmd_"k SYSDebugXyZzYSID"
 }
 s rc = ..DBGCommand(cmd,1)
 Q:rc'=$$$OK rc
 #; wait for reply
 s rc=$system.Event.WaitMsg(..Sid,10)
 if $li(rc)'=1 { Do ..Trace("Eval Wait error "_$li(rc)_" "_$lg(rc,2)) goto DBGERR }
 #; get the data
 s result=$li(rc,2)
 ; wait until target returns
 s rc = ..IsStopped(-1)
 Quit rc
DBGERR ;
 // We got some sort of error
 s $zt=""
 Do ..Trace("Eval error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

/// Get Stack info for target
/// Show the call stack, state and variables using ^%STACK
/// lev,start,.vararray,.next
Method StackVars(lev As %Integer, start As %String, ByRef vararray As %Binary) As %Integer
{
    If '..Attached Quit $$$DebugNotAttached
    If ('..Stopped) Quit $$$DebugNotStopped
    
    s $ZT="DBGERR"
    Do ..Trace("StackVars lev="_lev)

    ; issue command to the target
    s varray=""
    s rc = ..DBGCommand("B ""C"" D STKVAR^%SYS.Debug("""_..Sid_""","_lev_","_$ZU(144,1,start)_")",1)
    if rc '= $$$OK goto DBGERR
    ; wait for reply
    s rc=$system.Event.WaitMsg(..Sid,10)
    if $li(rc)'=1 { Do ..Trace("StackVars Wait error "_$li(rc)_" "_$lg(rc,2)) goto DBGERR }
    // get the data
    s vararray=$li(rc,2)
    ; wait until target returns
    s rc = ..IsStopped(-1)
    Q rc
DBGERR ;
 // We got some sort of error
 s $zt=""
 Do ..Trace("StackVars error "_$ze)
 Set ..Sid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

Method %OnNew(initval As %RawString = "") As %Status [ Private ]
{
 s ..DebId=$$SESSION^%SYS.Debug()
 If $system.Event.Defined(..DebId) {
    d $system.Event.Delete(..DebId)
 }
 s rc=$system.Event.Create(..DebId)
 Q:rc'=$$$OK $$$ERROR($$$GeneralError, "Unable to create event")  // JSL avoid <COMMAND> error
 Set ..RsetVars = ##class(%ResultSet).%New("%SYS.ProcessQuery:VariableByPid")
 Q $$$OK
}

Method %OnClose() As %Status [ Private ]
{
 Do ..Trace("OnClose")
 s $ZT="CLOSEE"
 If (..Attached) {
    // unattach and kill target
    Do ..Unattach()
 }
 Do $system.Event.Delete(..DebId)
CLOSEE
 s $ZT=""
 C:..Dev'="" ..Dev
 Quit $$$OK
}

/// Unattach from the current process, if any.
/// Assumes the target has been stopped
/// <p>Returns $$$OK if successful, error code if nothing to detach from
Method Unattach() As %Integer
{
 Do ..Trace("Unattach")
 If '..Attached Quit $$$DebugNotAttached

 Set ..Attached = 0

 Set $ZT = "UNATTACHERROR"

 If (..Killtarget) {
    d $zu(4,..Pid)
 } Else {
    // disconnect 
    Set x = $$CLOSE^%SYS.Debug(..Pid)
 }
 s ..Killtarget = 0
 d $system.Event.Delete(..Sid)
 d $system.Event.Delete(..CmdId)

 Quit $$$OK

UNATTACHERROR
 Set $ZT = ""
 Do ..Trace("Unattach error "_$ze)
 s ..Killtarget = 0
 d $system.Event.Delete(..Sid)
 d $system.Event.Delete(..CmdId)
 Quit $$$DebugTargetExited
}

/// Start a local debugging session on a new process.
/// Job the cterm debug stub
/// Start a cterm connected to the target
/// Run DebugTarget to run the process
/// <p>On exit from this routine, the target is in break mode waiting for a command
Method StartTarget(target As %String, pWriteOutput = 1) As %Integer
{
 if '..atelierTrace,$get(^%apiOLE("debug")) s ..trace = 1
 If (..Attached) Quit $$$DebugAttached

 s ..Killtarget = 1
 Set $ZT = "StartTargetErr"
 Do $SYSTEM.Event.Clear(+$J)
 
 #; Try to start the background job (with timeout)
 Job ##class(%Debugger.System).DebugStub(pWriteOutput)::3
 If $Test=0 {
     Do ..Trace("StartTarget could not JOB target: "_target)
     Quit $$$DebugStartFailed
 }
 set job=$ZCHILD
 
    #; TARGET: d $system.Event.Signal($ZPARENT,port)

 ; wait for job to return its port 
 s rc=$system.Event.WaitMsg("",10)
 i $li(rc)'=1 {
    Do ..Trace("StartTarget Wait error "_$li(rc)_" "_$lg(rc,2))
    s ..Attached = 0
    Quit $$$DebugTargetExited
 }
 // connect to the port
 s port=$li(rc,2)
 i port'= 0 {
    s rc = ..LocalIO(port)
    if 'rc { Do ..Trace("StartTarget i/o failed "_port) Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerNoIO"),! }
 } else {
     Do ..Trace("StartTarget port 0")
     Write:..OutputToDebugDevice $$$GetSimpleMessage("%Studio","DebuggerNoIO"),!
 }
 
 s ..DevOpen = 1
 s ..Stopped = 0

    #; TARGET: d $system.Event.Signal($ZPARENT,"")

 ; wait for job to see our port connection
 s rc=$system.Event.WaitMsg("",10)
 i $li(rc)'=1 goto StartTargetE

 // attach and signal the target
 Set rc = ..Attach(job)
 If rc'=$$$OK { Do ..Trace("StartTarget Attach "_rc) goto StartTargetE }

    #; ; wait for attach
    #; TARGET: d $system.Event.WaitMsg()

 // move target out of wait, into break mode
 s rc=$system.Event.Signal(job,"")
 If rc'=$$$OK { Do ..Trace("StartTarget Signal "_rc) goto StartTargetE }

 // synchronize. This is the wait for debugger message from target.
 s rc=$system.Event.WaitMsg(..Sid,5)
 i $li(rc)'=1  { Do ..Trace("StartTarget Wait "_$li(rc)_" "_$lg(rc,2)) goto StartTargetE }
 s ..Stopped = 1

#; ; get the target and go
#; B "L" d @$li($system.Event.WaitMsg(),2)

 s rc=$system.Event.Signal(job,target)
 If rc'=$$$OK { Do ..Trace("StartTarget Signal target "_rc) goto StartTargetE }
#; Studio will now issue Signal(..Sid, "B C G") 
 Quit $$$OK

StartTargetErr
 Set $ZT = ""
 Do ..Trace("Start target error "_$ze)
StartTargetE
 // kill target
 Do $zu(4,job)
 Set ..Pid = ""
 Set ..Attached = 0
 Quit $$$DebugTargetExited
}

/// System stub used by the debugger application
/// <p>This class method is jobbed in order to start a target process.
/// <p>The stub waits on the input event for the debugger to pass the name
/// of the target routine to be executed.
/// <p>When signalled, the stub then executes target routine
ClassMethod DebugStub(pWriteOutput)
{
 s port=0
 try {
    ; Find unused device name
    s opened=$P($V(-1,$J),"^",3)
    s i=$F(opened,"*,") s:i $E(opened,i-2)=""
    f i=1:1 {
        s dev="|TCP|"_i
        q:opened'[(dev_",")
    }
    ; Open a tcp port
    o dev:(/ACCEPT:/CRLF:/ESCAPE:/PAD:/SENDIMMEDIATE:/IOT="UTF8":/PORT=0):2
    if $T {
        u dev s port=$SYSTEM.TCPDevice.LocalPort()
    }
 } catch {
    ; try running with no port ??
 }
 ; tell the debugger which port to use
 try {
    d $system.Event.Signal($ZPARENT,port)
    i port {
        ; read for accept (open) from the debugger
        u dev r x
        d $zu(132)  ; set principal = current device
    }
 } catch {
    Set reason = $ze
    d $system.Event.Signal($ZPARENT,reason)
    halt
 }
 k (pWriteOutput)
 ; signal the debugger we are ready
 d $system.Event.Signal($ZPARENT,"")
 ; wait for attach
 d $system.Event.WaitMsg()
 ; get the target and go
 s ^||isc.debug = $li($system.Event.WaitMsg(),2)
 w:pWriteOutput "Executing ",^||isc.debug,!
 k pWriteOutput
 do @^||isc.debug break
 halt
}

Method LocalIO(port As %Integer, address As %String = "127.0.0.1") As %Boolean
{
 Set ..Dev = "|TCP|" _ port
 Open ..Dev:("127.0.0.1"::"SATM":/IOT="UTF8"):5
 i '$t {
     Set ..Dev = ""
     q 0
 }
 q 1
}

/// Log a trace if tracing enabled
Method Trace(pMsg As %String)
{
    #dim tNext,tNode As %Integer
    
    Set tNode=..atelierTrace
    If (tNode > 0) {
        Try {
            If pMsg="IsStopped",pMsg=^IRIS.Temp.Atelier("debug",$J,tNode,^IRIS.Temp.Atelier("debug",$J,tNode,0)) {
                #; Avoid the recurring IsStopped messages
                Return
            }
        } Catch {}
        Set tNext=$Increment(^IRIS.Temp.Atelier("debug",$J,tNode,0))
        Set ^(tNext)=pMsg
    } ElseIf (tNode < 0) {
        Quit
    } ElseIf ..trace {
        Write pMsg,!
    }
}

}
