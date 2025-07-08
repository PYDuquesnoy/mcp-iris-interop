/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occErrors, %syDebug, %syPidtab, LANG11)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// Studio debugging interface.
Class %Studio.Debugger Extends %Library.RegisteredObject [ System = 3 ]
{

/// SessionId if attached to CSP process
Property CSPId As %String;

/// System Debugger object
Property Debug As %Debugger.System;

/// Last error
Property LastError As %Integer;

/// Current breakpoint information for target process
Property Breakpoints As %String;

/// Current watchpoint information for target process
Property Watchpoints As %String;

/// I/O redirection flag
Property IO As %Boolean;

/// Project
Property Project As Project;

Property trace As %Boolean [ InitialExpression = 0 ];

/// Job off a routine that executes <var>tag</var>.
/// If breakpoints are specified, the target will halt at the first breakpoint.
Method StartTarget(tag As %String, StartOption As %Boolean = 0, project As Project = "") As %Status
{

 if $get(^%apiOLE("debug")) s ..trace = 1
 s ..IO = 1
#; Check syntax on target spec
 If '..TranslateMvb(.tag) {
    w $$$FormatMessage("","%ObjectErrors",$$$DebugInvalidTarget,,tag),!
    Quit $$$ERROR($$$DebugTargetExited) 
 }
  
 Set $ZT = "STARTTARGETERROR"
 
 // Start the target
 s rc=..Debug.StartTarget(tag)
 If rc'=$$$OK goto STARTTARGETERROR
 
 // Set breakpoints
 s ..Project = project
 If project'="" {
    s rc=..SetBreakpointsFromProject(project)
 }

 Write $$$FormatMessage(,"%Studio","DebuggerStarted",,tag),!
 // execute the target routine
 s rc = ..Debug.Go()
 Q:rc=$$$OK rc

STARTTARGETERROR
 Set $ZT = ""
 d ..Unattach(0)
 Quit $$$ERROR(rc)
}

Method TranslateMvb(ByRef tag As %String) As %Boolean [ Private ]
{
 // if it's a routine reference ..
 If (tag?.AN1"^".E) {
    if $find(tag,"(") {
        s rou=$p(tag,"(",1)
        s paren=$e(tag,$find(tag,"(")-1,$l(tag))
    } else {
        s rou=tag
        s paren=""
    }
         
    // valid document extensions which can be used to explicitly select a debugging target
    Set targetExtensions=$ListBuild("MVB")
    
    // parse the tag into label, routine base name, routine extension
    Set uparrowl=$Length(rou,"^"),label=$Piece(rou,"^"),rt=$Piece(rou,"^",2,uparrowl)
    If rt="" {Quit 0}
    If rt["." {
         Set rtdotl=$Length(rt,"."),rtbase=$Piece(rt,".",1,rtdotl-1),rtext=$Piece(rt,".",rtdotl)
     
        // if it's not a valid overriding extension we need to treat it as part of the name instead
        If '$ListFind(targetExtensions,$ZCvt(rtext,"U")) {
            Set rtbase=rt,rtext=""
        }
    }
    Else {
        Set rtbase=rt,rtext=""
    }
    
    // IF the tag contains a "~" *OR* has a .MVB extension *OR* (there's no rMAP entry for the base name *AND* there's no INT/BAS routine of that name)
    // THEN it's MVB
    If (rtbase["~") || (rtext="MVB") || ('$Data(^rMAP(rtbase)) && '##class(%Routine).Exists(rtbase_".INT") && '##class(%Routine).Exists(rtbase_".BAS")) {
     
        // if the base doesn't contain "~" put the prefix on
        If rtbase'["~" {Set rtbasex=$$$DEFAULTPROGRAMFILE_"~"_rtbase} Else {Set rtbasex=rtbase}
    
        // if there isn't a map entry for the prefixed base report an error
        If '$Data(^rMAP(rtbasex,"MVB","MVI")) {Quit 0}
    
        // set the tag to the MVI equivalent
        Set rou=label_"^"_^rMAP(rtbasex,"MVB","MVI")
    }
    Set tag=rou_paren
 }
 // no error
 Quit 1
}

/// Attach to another process having process id of pid.
/// <p>Fails if already attached (use <method>Unattach</method> first),or
/// if pid is invalid.
/// <p>On successful completion, process is attached and a break issued.
/// The process will be in break mode upon completion of its current operation.
Method Attach(pid As %String = "", project As Project = "") As %Status
{
 if $get(^%apiOLE("debug")) s ..trace = 1

 Set $zt="trap"
 
 If (pid="") Quit $$$ERROR($$$DebugMissingPID)
 
 //clear any messages to self
 d $system.Event.Clear(+$J)

 //attach to process
 Set rc=..Debug.Attach(pid)
 
 If rc=$$$OK {
    Write $$$FormatMessage(,"%Studio","DebuggerAttached",,pid),!
    s ..Project = project
    Q rc
 } else {Q $$$ERROR(rc)}
trap
 s $zt=""
 Q $$$ERROR(..Error($ze))
}

Method %OnNew(initval As %RawString = "") As %Status [ Private ]
{
 Set $zt="trap"
 s ..Debug=##class(%Debugger.System).%New()
 I ..Debug=$$$NULLOREF Q $$$ERROR($$$GeneralError,"Failed to create debug object")
 Quit $$$OK
trap
 s $zt=""
 Q $$$ERROR(..Error($ze))
}

/// Send a BREAK to the target process.
/// <p>A successful return indicates the target will be in break mode
/// on completion of the current command.
/// <p>Issue IsStopped to determine if target is in break mode.
Method Break() As %Boolean
{
 Set $zt="trap"
 w:..trace "BREAK",!
 s rc = ..Debug.Break()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s $zt=""
 s ..LastError = ..Error($ze)
 Q 0
}

/// Returns 1 if the target is stopped in break mode.
/// 0 indicates target is still running.
/// 2 indicates target has exited debugger or fatal error.
Method IsStopped() As %Integer
{
 Set $zt="trap"
 s rc = ..Debug.IsStopped(0)
 If rc=$$$OK {
    If $f($p(..Debug.Location,":",2),"%Debugger.System") {
        d ..DBGCommand("B ""OFF"" G")
        s code = $system.Event.WaitMsg("",1)
        s msg = $li(code,2)
        if msg="" {
            Write !,$$$GetSimpleMessage("%Studio","ProgramStopped"),!
        } elseif msg["^%Debugger.System" {
            w $$$FormatMessage("","%ObjectErrors",$$$DebugInvalidTarget,,..Project.Target),!
        }
        s rc = ..Debug.IsStopped()
    } elseIf ..CSPId && $f($p(..Debug.Location,":",2),"%SYS.cspServer") {
        d ..Go()
        s rc = ..Debug.IsStopped()
    } elseIf $f($p(..Debug.Location,":",2),"%SOAP.WebService") {
        d ..Unattach(0)
        s rc=$$$DebugTargetExited
    } elseIf ($f($p(..Debug.Location,":",2),"LANG")) || ($f($p(..Debug.Location,":",2),"%SYS.MV"))  {
        // Set breakpoints
        If ..Project'="" {
            s rc=..SetBreakpointsFromProject(..Project)
            If rc'=$$$OK {
                w "Error occurred setting breakpoints"
            }
            s ..Project=""
        }
        d ..LineOut()
        s rc = 0
    }
 }
 S ..LastError=rc
 if ..trace {if (rc)&&(rc'=$$$DebugTargetExited) w "Stopped at ",$p(..Debug.Location,":",2)," ",$p(..Debug.Location,":",3),!}
 Q $S(rc=$$$OK:1,rc=0:0,1:2)
trap
 s $zt=""
 s ..LastError = ..Error($ze)
 try { w:..trace "Status ",..LastError,! } catch {}
 Q 0
}

/// Write to target process
Method WriteTarget(data As %String) As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.Write(data)
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s $zt=""
 s ..LastError = ..Error($ze)
 Q 0
}

/// Interrupt the target process.  The current command will be interrupted.
/// Execution will proceed with the next command.
Method Interrupt() As %Boolean
{
 Set $zt="trap"
 w:..trace "Interrupt",!

 s rc = ..Debug.Interrupt()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Perform a debug command.
Method DBGCommand(cmd As %String, IsSys As %Integer = 0) As %Boolean
{
 Set $zt="trap"
 w:..trace "Command: ",cmd,!
 s rc = ..Debug.DBGCommand(cmd,IsSys)
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Evaluate and return the value of expression 
/// <var>expr</var> within the target process.
Method Eval(expr As %String = "") As %String
{
 Set $zt="trap"
 w:..trace "Eval: ",expr," = "
 
 s rc = ..Debug.Eval(expr,.result)
 s ..LastError=rc
 w:..trace result,!

 i rc'=$$$OK {
     Q ""
 } 
 Q result
trap
 s ..LastError = ..Error($ze)
 Q ""
}

/// Sets a variable to a value.
Method SetValue(variable As %String = "", value As %String = "") As %Boolean
{
 Set $zt="trap"
 w:..trace "SetValue ",variable," = ",value,!

 s rc = ..Debug.SetValue(variable,value)
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Gets the value of a variable.
Method GetValue(variable As %String = "", ByRef value As %String) As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.GetValue(variable,.value)
 If rc'=$$$OK S ..LastError=rc Q '$$$OK

 s rc = ..Debug.Stopped(-1)
 w:..trace "GetValue: ",variable," = ",value,!
 
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Gets the simple stack information sent from the target.
Method GetStack() As %String
{
 q ..Debug.Stack
}

/// Requests stack variable info.
Method GetStackId() As %String
{
 s sid=$$$objOrefToInt($this)
 w:..trace "StackId ",sid,!
 q sid
}

/// Return the current location of the debugger. This includes both the command and the argument
/// positions.
Method GetOffset(ByRef RoutineName As %String, ByRef BeginCmdLine As %Integer, ByRef BeginCmdOffset As %Integer, ByRef EndCmdLine As %Integer, ByRef EndCmdOffset As %Integer, ByRef BeginArgLine As %Integer, ByRef BeginArgOffset As %Integer, ByRef EndArgLine As %Integer, ByRef EndArgOffset As %Integer, ByRef NameSpace As %String) As %Integer
{

 Set $zt="trap"
 q:('..Debug.Attached) $$$ERROR($$$DebugTargetExited)
 // Get offset info from target
 Set RoutineName = $P(..Debug.Location,":",2)
 
 Set RoutineName = RoutineName_"."_$$$rtnLangINT(+$P(..Debug.Location,":",12))
 
 Set BeginCmdLine = +$P(..Debug.Location,":",3)
 Set BeginCmdOffset = +$P(..Debug.Location,":",4)
 Set EndCmdLine = +$P(..Debug.Location,":",5)
 Set EndCmdOffset = +$P(..Debug.Location,":",6)
 Set BeginArgLine = +$P(..Debug.Location,":",8)
 Set BeginArgOffset = +$P(..Debug.Location,":",9)
 Set EndArgLine = +$P(..Debug.Location,":",10)
 Set EndArgOffset = +$P(..Debug.Location,":",11)
 Set NameSpace = $P(..Debug.Location,":",13,*)
 
 Quit +$P(..Debug.Location,":",7) // flag
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Return the routine source at the current location
Method GetSource() As %String
{
 Set $zt="trap"
 q:('..Debug.Attached) $$$ERROR($$$DebugTargetExited)
 // Get offset info from target
 Set rtn = $P(..Debug.Location,":",2)
 Set BeginLine = $P(..Debug.Location,":",3)

 Set start = $P(..Debug.Location,":",4)
 Set end = $P(..Debug.Location,":",6)

 If (rtn="")||(BeginLine="") {
 Quit ""
 }

 Set s = $G(^ROUTINE(rtn,0,BeginLine))
 If (+end = 0) {
     Quit $E(s,+start,*)
 }

 Quit $E(s,+start,end)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
    If ..CSPId'="" {
        Set session=##class(%CSP.Session).GetSession(..CSPId)
        I session'=$$$NULLOREF Do session.endSession(0,1)
        k session
    }
    Quit $$$OK
}

/// Check if routine is mapped to current namespace
/// <p>Returns 1 if successful, 0 if not mapped to current
Method RoutineMap(current As %String, routine As %String, rouns As %String) As %Boolean
{
 Set $zt="trap"
 Set roudir=$$defdir^%SYS.GLO($select($extract(rouns)="^":rouns,1:$zcvt(rouns,"U")))
 s mapdir = $$GetGlobalSourceDatabase^%SYS.SECURITY($name(^|current|ROUTINE(routine)))
 s mapdir = $zcvt($p(mapdir,"^",3),"U")
 Q (mapdir=roudir)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Continue the current process
Method Go() As %Boolean
{
 Set $zt="trap"
 w:..trace "GO",!
 s rc = ..Debug.Go()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Continue the current process
Method GoTo(tag As %String) As %Boolean
{
 Set $zt="trap"
 w:..trace "GOTO",!
 s rc = ..Debug.GoTo(tag)
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method Line() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.Line()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method LineIn() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.LineIn() = $$$OK
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method LineOut() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.LineOut() = $$$OK
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method SetBreakpoint(routine As %String, offset As %Integer, condition As %String = "", label As %String = "") As %Boolean
{
    Set $zt="trap"
 
    Set rc=..INTLine(routine,label,offset,.intname,.intline,.returntype) If $$$ISERR(rc) Set ..LastError=rc Quit 0
    If returntype = 1 {
        Write $$$FormatMessage(,"%Studio","BreakMoved",,label_"+"_offset_"^"_routine),!
    } ElseIf returntype = 2 {
        Write $$$FormatMessage(,"%Studio","BreakNotSet",,label_"+"_offset_"^"_routine),!
        Quit 0
    }
    If $zconvert($piece(routine,".",$length(routine,".")),"U")="MVB" {
        #; Find the OBJ line that maps to the MVI line where we want the breakpoint
        w:..trace "SetBreakpoint0 ",intname," ",intline,!
        Try {
          If '$D(^ROUTINE(intname,"MAP",1),map) Set rc=$$map^%R(intname_".MVI") Goto:rc>1 nomap Set map=^ROUTINE(intname,"MAP",1)
          Xecute ("(pl) Zload "_intname_" Set pl=$ZU(135,3)",.plines)
        } Catch { Goto nomap }
        #; Find the first OBJ offset that maps to the source line
        If '$D(^ROUTINE(intname,"MAP",0),map0) Goto nomap
        If $A(map0,3)=1 {
            Set off=0 For i=3:6:$ZWA(map,1)*6 Set off=$ZWA(map,i),line=$ZWA(map,i+2) If line>=intline Quit
        } Else {
            Set off=0,num=$ZWA(map0,1)-1,done=0,node=1
            For i=17:16:$ZLA(map,9)*16+1 Set off=$ZLA(map,i),line=$ZLA(map,i+4) If line>=intline Set done=1 Quit
            While ('done && (node <= num)) {
                If '$D(^ROUTINE(intname,"MAP",1,node),map) Goto nomap
                For i=17:16:$ZLA(map,9)*16+1 Set off=$ZLA(map,i),line=$ZLA(map,i+4) If line>=intline Set done=1 Quit
                Set node=node+1
            }
        }
        #; Find the plines entry which contains that offset
        #; ListValid means it is a large routine
        If $ListValid(plines) {
            Set plines=$LI(plines)
            For i=1:1:$L(plines)/4 Quit:$ZLA(plines,i*4-3)>off
        } Else {
            For i=1:1:$L(plines)/2 Quit:$ZWA(plines,i*2-1)>off
        }
        Set intline=i
nomap }
    w:..trace "SetBreakpoint ",intname," ",intline,!
    Set rc = ..Debug.SetBreakpoint(intname,intline,condition)
    Set ..LastError=rc
    Quit $select(rc=$$$OK:1,1:0)
trap
    s ..LastError = ..Error($ze)
    Q 0
}

Method DisableBreakpoint(routine As %String, offset As %Integer, condition As %String = "", counter As %Integer, label As %String = "") As %Boolean
{
 Set $zt="trap"
    Set rc=..INTLine(routine,label,offset,.intname,.intline,.returntype) If $$$ISERR(rc) Set ..LastError=rc Quit 0
    If returntype = 2 Set ..LastError=$$$ERROR($$$DebugNoMapBreakpoint,label_"+"_offset_"^"_routine) Quit 0
    w:..trace "DisableBreakpoint ",intname," ",intline,!
    Set rc = ..Debug.DisableBreakpoint(intname,intline,counter)
    Set ..LastError=rc
    Quit $select(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method RemoveBreakpoint(routine As %String, offset As %Integer, label As %String = "") As %Boolean
{
 Set $zt="trap"
    Set rc=..INTLine(routine,label,offset,.intname,.intline,.returntype) If $$$ISERR(rc) Set ..LastError=rc Quit 0
    If returntype = 2 Set ..LastError=$$$ERROR($$$DebugNoMapBreakpoint,label_"+"_offset_"^"_routine) Quit 0
    w:..trace "RemoveBreakpoint ",intname," ",intline,!
    Set rc = ..Debug.RemoveBreakpoint(intname,intline)
    Set ..LastError=rc
    Quit $select(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method ClearBreakpoints() As %Boolean
{
 Set $zt="trap"
 w:..trace "ClearBreakpoints",!
 s rc = ..Debug.ClearBreakpoints()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method SetWatchpoint(variable As %String, condition As %String = "") As %Boolean
{
    Set $zt="trap"
 
    w:..trace "SetWatchpoint ",variable," ",condition,!
    Set rc = ..Debug.SetWatchpoint(variable,condition)
    Set ..LastError=rc
    Quit $select(rc=$$$OK:1,1:0)
trap
    s ..LastError = ..Error($ze)
    Q 0
}

Method DisableWatchpoint(variable As %String, counter As %Integer) As %Boolean
{
 Set $zt="trap"
 Set rc = ..Debug.DisableWatchpoint(variable,counter)
 Set ..LastError=rc
 Quit $select(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method RemoveWatchpoint(variable As %String) As %Boolean
{
 Set $zt="trap"
 Set rc = ..Debug.RemoveWatchpoint(variable)
 Set ..LastError=rc
 Quit $select(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Set all break points defined in project.
/// <p>Return 0 if project=NULL, else
/// return status code from SetBreakpoint
Method SetBreakpointsFromProject(project As Project) As %Boolean
{
 Set $zt="trap"
 w:..trace "SetBreakpointsFromProject",!

 If (project = $$$NULLOREF) Quit 0
 Set rc = $$$OK
#;breakpoints
 Set key = ""
 f  {
    Set bp = project.BreakPoints.GetNext(.key)
    Q:bp=$$$NULLOREF
    Set offset=bp.Offset,label=""
    If offset["+" Set label=$piece(offset,"+"),offset=$piece(offset,"+",2)
    Set err=..SetBreakpoint(bp.Routine,offset,bp.Condition,label)
    If err'=$$$OK s rc=err
 }
#;watchpoints
 Set key = ""
 f  {
    Set wp = project.WatchPoints.GetNext(.key)
    Q:wp=$$$NULLOREF
    Set err=..SetWatchpoint(wp.Variable,wp.Condition)
    If err'=$$$OK s rc=err
 }
 Quit rc
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method Step() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.Step()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method StepIn() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.StepIn()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

Method StepOut() As %Boolean
{
 Set $zt="trap"
 s rc = ..Debug.StepOut()
 S ..LastError=rc Q $S(rc=$$$OK:1,1:0)
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Unattach from the current process, if any.
/// <p>Returns $$$OK if successful, $$$ERROR if nothing to detach from
Method Unattach(kill As %Boolean) As %Status
{
 w:..trace "Unattach ",!
 if '..Debug.Attached Q $$$OK
 Set $zt="trap"
 
 s rc = ..Debug.Unattach()
 if rc '= $$$OK s rc = $$$ERROR(rc)
 If ..CSPId'="" {
    Set session=##class(%CSP.Session).GetSession(..CSPId)
    I session'=$$$NULLOREF w "end session " Do session.endSession(0,1)
    Set ..CSPId=""
 }
 Write $$$GetSimpleMessage("%Studio","DebuggerStopped"),!
 Q rc
trap
 s $zt=""
 Q $$$ERROR(..Error($ze))
}

/// To attach to a CSP process, first call this method which will return you a unique
/// ID number. Then display the CSP page but add an extra parameter of 'CSPDEBUG=&lt;ID&gt;'
/// for example 'http://localhost/csp/samples/loop.csp?CSPDEBUG=123456'. Then call the
/// <method>AttachToCSP</method> method which will attach to the process that is
/// running this CSP page.
Method GetCSPAttachID() As %Integer
{
 Set $zt="trap"
 For  Set id=$zla($system.Encryption.GenCryptRand(4))\2 Quit:'$Data(^IRIS.TempCSP("Debug",id))
 Set ^IRIS.TempCSP("Debug",id)=""

 Quit id
trap
 s ..LastError = ..Error($ze)
 Q 0
}

/// Attach to a CSP process, first you must call the <method>GetCSPAttachID</method>
/// to obtain the ID to pass to this method.
Method AttachToCSP(id As %Integer, project As Project = "") As %Status
{
    
 Set $ZT = "AttachToCSPE"
 
 // start debug proxy
 Set rc = $$$DebugAttachFailed
 w:..trace "Waiting for CSPDEBUG=",id,!
 For i=1:1:100 {
    If $Get(^IRIS.TempCSP("Debug",id))'="" {
        Set rc = $$$OK
        Quit
    }
    w:i#10=0 ". "
    Hang 0.1
 }
 If rc'=$$$OK goto AttachToCSPExit
 
 Set job=^IRIS.TempCSP("Debug",id)
 Set ..CSPId=^IRIS.TempCSP("Debug",id,"id")
 Kill ^IRIS.TempCSP("Debug",id)
 w:..trace "CSP job ",job,!

 // attach to the target
 Set rc = ..Debug.Attach(job)
 If rc'=$$$OK w "CSP: ATTACH failed",! goto AttachToCSPExit 

 // signal the target
 Set rc = $system.Event.Signal(job)
 If rc'=$$$OK w "CSP: SIGNAL failed",! goto AttachToCSPExit 

 // synchronize
 s ..Debug.DevOpen = 1
 s rc = ..Debug.IsStopped(5)
 If rc'=$$$OK {
    w "CSP: STOPPED failed",!
    goto AttachToCSPExit
 }
 
 Write $$$FormatMessage(,"%Studio","DebuggerAttached",,job),!

 // Set breakpoints
 If project'="" {
    s rc=..SetBreakpointsFromProject(project)
    If rc'=$$$OK {
        w "CSP: BREAKPOINTS failed",! 
        s rc = $$$DebugAttachFailed
        goto AttachToCSPExit
    }
 }
 // execute the target routine
 s rc = ..Debug.Go()
 if rc '= $$$OK goto AttachToCSPExit
 Quit $$$OK

AttachToCSPE
 Set rc=..Error($ZE)
AttachToCSPExit
 Set $ZT = ""
 d ..Unattach(0)
 QUIT $$$ERROR(rc)
}

Query ProcessList() As %Query(ROWSPEC = "PID:%String,Namespace:%String,Routine:%String,State:%String,Device:%String") [ SqlProc ]
{
}

ClassMethod ProcessListExecute(ByRef QHandle As %Binary) As %Status
{
 // handle is subscript, index

 // allocate space in IRIS.Temp
 Set index = $Increment(^IRIS.Temp)

 // build list of PIDs into temp space

 // GetInfo returns the following info
 // info(1) = jobnumber
 // info(2) = pid
 // info(3) = unused
 // info(4) = namespace
 // info(5) = routine
 // info(6) = lines executed
 // info(7) = global references
 // info(8) = process state
 // info(9) = prinicipal device
 // info(10) = EXAMINEOK (1 or 0)
 // info(11) = debug active (4 or 0)

 Set delim = $C(19) _ "^" _ $C(1)       // delimiter
 Set jobnum = 1
 Set pid = $zj("")

 While (pid '= "") {
    Set info = ..GetInfo(jobnum,pid)
    // pid, namespace, routine, state,device
    // force pid to be a string for client
    Set rName = $p(info,delim,5)
    if ($p(rName,".",1)= "MVB")  ; Correction for MVB name
    {
        Set temp = $p(rName,".",2)
        if (temp = +temp) d
        . new $namespace
        . set $namespace = $p(info,delim,4)
        . set mvName = ##class(%RoutineMgr).GetOther(rName,"MVI") 
        . if (mvName '= "") set rName = mvName
     }

     Set ^IRIS.Temp(index,jobnum) = $LB(pid _ "",$p(info,delim,4),rName,$p(info,delim,8),$p(info,delim,9))
     Set pid = $zj(pid)
     Set jobnum = jobnum + 1
 }

 // qhandle is index,jobnum
 Set QHandle = $LB(index,"")

 Quit $$$OK
}

ClassMethod ProcessListClose(QHandle As %Binary) As %Status
{
 Set index = $LI(QHandle,1)

 // kill temp data
 Kill ^IRIS.Temp(index)
 Set QHandle=""
 Quit $$$OK
}

ClassMethod ProcessListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 Set Row="",AtEnd=0

 Set index = $LI(QHandle,1)
 Set key = $LI(QHandle,2)

 Set key = $Order(^IRIS.Temp(index,key))
 Set QHandle = $LB(index,key)
 If (key = "") {
 Set AtEnd = 1
 Quit $$$OK
 }

 // result: PID,Namespace,Routine,State,Device
 Set Row = ^IRIS.Temp(index,key)

 Quit $$$OK
}

/// Gather information about a process
ClassMethod GetInfo(Job As %Integer, Pid As %Integer) As %String
{
#define ODEL    $$del2^%Wprim  
#define oDEL    $$del1^%Wprim
 s $zt="etgetinfo"
 s rtn=$zu(67,5,Pid) ;s:rtn="" rtn="M SHELL"
 i rtn="" {
    s jobtype=$zu(67,10,Pid)
#; ;JO2062+
    if $$$INTERACTIVEJOB(jobtype)!$$$BACKGROUNDJOB(jobtype) {
        s rtn=$$$FOREJOBNAME
    } else {
        s rtn=$ZU(67,32,Pid)  ;get "%SS" dmn name if there is one
        if rtn="" {   ;this job has no %SS name
            s rtn=jobtype  ;defaults to numeric job type
        }
    }
#; ;JO2062-
 }
 s d=$$$ODEL
 s accum=Job_d_Pid_d_d_$zu(67,6,Pid)_d_rtn_d_$zu(67,8,Pid)_ ;1-6
         d_$zu(67,9,Pid)_d_$$state(Pid)_d_$zu(67,7,Pid)_ ;7-9
         d_$zu(67,31,2,Pid)_d_$zu(67,16,Pid) ;10-11
etgetinfo ;
 s $zt=""
 q $g(accum)
state(pid)
 s stateval=$ZU(67,4,Pid)
 #;RJF472
 q ##class(%SYS.ProcessQuery).StateLogicalToDisplay(stateval)
}

/// Given a document <var>name</var>, <var>label</var> and <var>line</var> offset it returns the name and line corresponding to this in the INT code
/// <var>returntype</var> values are<ul>
/// <li>0 - Ok</li>
/// <li>1 - Line given is not mapped so returning the next mapped line as breakpoint instead</li>
/// <li>2 - No mapping found at all, nothing returned</li></ul>
/// For example if you wish to find out which line is generated from class 'User.Test' in method 'MyMethod' at offset '+3' you
/// call:
/// <example>Set sc=##class(%Studio.Debugger).INTLine("User.Test.CLS","MyMethod",3,.intname,.intline,.returntype)</example>
/// <var>type</var> is one of 'CLS' or 'MAC' currently.
ClassMethod INTLine(name As %String, label As %String, line As %Integer, ByRef intname As %String, ByRef intline As %String, ByRef returntype As %Integer, pNameSpace As %String = {$namespace}) As %Status
{
    Set intname="",intline=-1,returntype=2
    
    If $length(name,".")=1 {
        Set intname=name,intline=line,returntype=0 Quit $$$OK
    }
    
    Set type=$zconvert($piece(name,".",$length(name,".")),"U"),name=$piece(name,".",1,$length(name,".")-1)
    If $$$rtnIsINT(type) {
        Set line=+line
        If label'="" {
            For i=1:1:$get(^|pNameSpace|ROUTINE(name,0,0)) If $piece($piece($piece($piece(^(i),$c(9))," "),"("),";")=label Set line=i+line,label="" Quit
            If label'="" Quit $$$OK
        }
        If $data(^|pNameSpace|ROUTINE(name,0,line)) {
            Set intname=name,intline=line,returntype=0
        }
        Quit $$$OK
    }
    
    Set line=$select(+line=0:1,1:line)
    If type="MAC",'$data(^|pNameSpace|rMAP(name,type,"INT")) Quit $$$OK
    If type="MVB" {
        If name'["~" {Set namex=$$$DEFAULTPROGRAMFILE_"~"_name} Else {Set namex=name}
        Set fullintname=$G(^|pNameSpace|rMAP(namex,"MVB","MVI"))
        Set intname=$select($extract(fullintname,1,3)=($$$DEFAULTPROGRAMFILE_"~"):$extract(fullintname,4,$length(fullintname)),1:fullintname)
        #; if line is directly mapped, take it
        If $Data(^|pNameSpace|rMAP(namex,"MVB","MVI",line),intline) { Set intline=$listget(intline,2) }
        #; if it's within a mapped range, adjust from the first line of the range
        Else { Set i=$Order(^|pNameSpace|rMAP(namex,"MVB","MVI",line),-1,intline)
            If i="" Set intline=""
            Else  Set intline=$listget(intline,2) Set:intline'=-1 intline=intline+line-i
        }
        #; if it didn't generate any code, skip to the next generated line
        If intline=-1 { Set line=$O(^|pNameSpace|rMAP(namex,"MVB","MVI",line),1,intline)
            If line="" Set intline="",returntype=2
            Else  Set intline=$listget(intline,2),returntype=$Select(intline="":2,1:1)
        } Else {
            Set returntype=$Select(intline="":2,1:0)
        }
    } ElseIf type="MAC" {
        If $get(label)'="" {
            For i=1:1:^|pNameSpace|rMAC(name,0,0) {
                If $piece($translate(^|pNameSpace|rMAC(name,0,i),$char(9,160)_"(","   ")," ")=label {
                    Set line=i+line,label="" Quit
                }
            }
        }
        If $get(label)'="" Quit $$$OK
        Set intname=name,previousline=line
        While $data(^|pNameSpace|rMAP(name,"MAC","INT",previousline),data)#10=0 {
            Set previousline=$order(^|pNameSpace|rMAP(name,"MAC","INT",previousline),-1)
            If previousline="" Quit
        }
        If previousline="" Quit $$$OK
        #; Line mapped to -1 so does not exist in target
        If $list(data,2)=-1 {
            Set tmp=previousline
            For  Set tmp=$order(^|pNameSpace|rMAP(name,"MAC","INT",tmp)) Quit:tmp=""  If $data(^|pNameSpace|rMAP(name,"MAC","INT",tmp),data)#10=1,$list(data,2)'=-1 Quit
            If tmp="" Quit $$$OK
            Set intline=$list(data,2),returntype=1
            Quit $$$OK
        }
        Set intline=$list(data,2)+line-previousline,returntype=0
    } ElseIf label'="" {
        Set defaultname=$get(^|pNameSpace|rMAP(name,type,"INT"))
        If $data(^|pNameSpace|rMAP(name,type,"INT",label,line),data) {
            Set previousline=line
        } Else {
            Set previousline=$order(^|pNameSpace|rMAP(name,type,"INT",label,line),-1,data)
            If previousline="" Quit $$$OK
        }
        Set intname=$listget(data,1,defaultname)
        #; Line mapped to -1 so does not exist in target
        If $list(data,2)=-1 {
            Set tmp=previousline
            For  Set tmp=$order(^|pNameSpace|rMAP(name,type,"INT",label,tmp),1,data) Quit:tmp=""||($list(data,2)'=-1)
            If tmp="" Quit $$$OK
            Set intline=$list(data,2),returntype=1
            Quit $$$OK
        }
        Set intline=$list(data,2)+line-previousline,returntype=0
    }
    Quit $$$OK
}

/// Given INT routine name and line number and offset in this line return an array of source lines
/// that map to this INT line. The format of this return array is:<p>
/// map(type,StartEnd)=$listbuild(sourceName,sourceLabel,sourceLine,Offset,Namespace)<p>
/// Where StartEnd is 1 for the start of the map and 2 for the end, sourceName is the name of the
/// source file, sourceLabel is the method/label name, sourceLine is the number of lines from
/// this label to the location, Offset is the offset on the line, Namespace is the location
/// of the source file.
ClassMethod SourceLine(intName As %String, startLine As %Integer, startPos As %Integer, endLine As %Integer, endPos As %Integer, Namespace As %String, ByRef map As %String) As %Status
{
    s $zt = "SourceLineE"
    Kill map
    If $get(Namespace)="" Set Namespace=$namespace
    #; If this routine is not mapped nothing to return
    If $zstrip(intName,"<>W")="" Quit $$$OK
    Set key1=""
    For key="INT","MVI" {If $Data(^|Namespace|rMAP(intName,key)) {Set key1=key Quit}}
    If key1="" {Quit $$$OK}
    Set type=""
    For  {
        Set type=$order(^|Namespace|rMAP(intName,key1,type)) Quit:type=""
        Do ..addMap(intName,key1,type,startLine,startPos,.map,1,Namespace)
        Do ..addMap(intName,key1,type,endLine,endPos,.map,2,Namespace)
    }
    Quit $$$OK
SourceLineE
    #; If this routine is not mapped nothing to return
    s $zt=""
    Quit $$$OK
}

ClassMethod addMap(name, intmvikey, type, line, pos, map, loc, Namespace) [ Private ]
{
    If $get(Namespace)="" Set Namespace=$namespace
    Set targetnsp=Namespace
    If intmvikey = "MVI" {
        If $data(^|Namespace|MV.RTN(name),data) Set targetname=$list(data,2)_"~"_$list(data,3)
        Else  If $data(^%MV.RTN(name),data) Set targetname=$list(data,3)_"~"_$list(data,4),targetnsp=$list(data,2)
        Else  Set targetname=""
    } else {
        Set targetname=$get(^|Namespace|rMAP(name,intmvikey,type))
    }
    Set macmvbkey=$Select(intmvikey="MVI":"MVB",1:"MAC")
    Set tmpline=line,label="",offset=""
    Do {
        If $data(^|Namespace|rMAP(name,intmvikey,type,tmpline),tmpdata)#10=1 {
            If offset="" {
                If type=macmvbkey {
                    If targetname="" Set targetname=name
                    Set offset=$list(tmpdata,2)+line-tmpline
                    Quit
                } Else {
                    #; If this is the end of method marker return with no label
                    If $listdata(tmpdata,2),$listget(tmpdata,2)="" Set offset="" Quit
                    Set offset=$select($list(tmpdata,3)=0:0,1:$list(tmpdata,3)+line-tmpline)
                }
            }
            If type'=macmvbkey,$listget(tmpdata,2)'="" Set label=$list(tmpdata,2) Quit
        }
        Set tmpline=$order(^|Namespace|rMAP(name,intmvikey,type,tmpline),-1) Quit:tmpline=""
    } While 1
    If offset="" Quit
    #; If there is no source map, the int map can't be good either
    #; But this does not work well for MV with q-pointers, etc
    If targetname'="",intmvikey'="MVI",'$data(^|targetnsp|rMAP(targetname,type)) {
        Try { Kill ^|Namespace|rMAP(name,intmvikey) } Catch {}
        Quit
    }
    Set basetarget=$select($extract(targetname,1,3)=($$$DEFAULTPROGRAMFILE_"~"):$extract(targetname,4,$length(targetname)),1:targetname)
    If $data(^|Namespace|rMAP(name,intmvikey,type,line,pos),data) {
        Set map(type,loc)=$listbuild(basetarget,label,$listget(data,2,offset),$list(data,3),targetnsp)
        Quit
    } Else {    
        Set newpos=$order(^|Namespace|rMAP(name,intmvikey,type,line,pos),-1,data)
    }
    If newpos="" {
        Set map(type,loc)=$listbuild(basetarget,label,offset,pos,targetnsp)
    } Else {
        Set endint=$list(data,4)+newpos
        If pos<endint,pos>newpos {
            If $list(data,5)=0 Quit
            Set map(type,loc)=$listbuild(basetarget,label,$listget(data,2,offset),$list(data,3)+$select(loc=2:$list(data,5),1:0),targetnsp)
        } Else {
            Set map(type,loc)=$listbuild(basetarget,label,$listget(data,2,offset),pos-endint+$list(data,3)+$list(data,5),targetnsp)
        }
    }
}

/// Return the list of source files that the current break point maps to starting with the INT/BAS routine.
/// Each source file is separated by a space character.
/// The format of each source file data is:<p>
/// routineName,label,beginCmdLine,beginCmdOffset,endCmdLine,endCmdOffset,beginArgLine,beginArgOffset,endArgLine,endArgOffset,Namespace
Method MappedOffset(ByRef mapping As %String, ByRef namespace As %String, ByRef flag As %String) As %Status
{
    Set $zt="trap"
    Set mapping="",namespace="",flag=""
    Quit:('..Debug.Attached) $$$ERROR($$$DebugTargetExited)
    Set flag=..GetOffset(.routineName,.beginCmdLine,.beginCmdOffset,.endCmdLine,.endCmdOffset,.beginArgLine,.beginArgOffset,.endArgLine,.endArgOffset,.namespace)
    Quit ..MappedFromPos(routineName,beginCmdLine,beginCmdOffset,endCmdLine,endCmdOffset,beginArgLine,beginArgOffset,endArgLine,endArgOffset,.namespace,.mapping)
trap
    Set ..LastError = ..Error($ze)
    Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Return the list of source files that the position passed in maps to.
/// Each source file is separated by a space character.
/// The format of each source file data is:<p>
/// routineName,label,beginCmdLine,beginCmdOffset,endCmdLine,endCmdOffset,beginArgLine,beginArgOffset,endArgLine,endArgOffset,Namespace
ClassMethod MappedFromPos(routineName As %String, beginCmdLine As %Integer, beginCmdOffset As %Integer, endCmdLine As %Integer, endCmdOffset As %Integer, beginArgLine As %Integer, beginArgOffset As %Integer, endArgLine As %Integer, endArgOffset As %Integer, namespace As %String, ByRef mapping As %String, ByRef flag As %String) As %Status
{
    Set $zt="trap"
    Set rtn=$piece(routineName,".",1,$length(routineName,".")-1)
    #; Convert offset base to 1 based
    Set beginCmdOffset=beginCmdOffset+1,endCmdOffset=endCmdOffset+1,beginArgOffset=beginArgOffset+1,endArgOffset=endArgOffset+1
    Set sc=..SourceLine(rtn,beginCmdLine,beginCmdOffset,endCmdLine,endCmdOffset,.namespace,.cmdmap)
    If $$$ISERR(sc) Quit sc
    Set sc=..SourceLine(rtn,beginArgLine,beginArgOffset,endArgLine,endArgOffset,.namespace,.argmap)
    If $$$ISERR(sc) Quit sc
    Set mapping=routineName_",,"_beginCmdLine_","_(beginCmdOffset-1)_","_endCmdLine_","_(endCmdOffset-1)_","_beginArgLine_","_(beginArgOffset-1)_","_endArgLine_","_(endArgOffset-1)
    Set type="",srcnsp=""
    For  {
        Set type=$order(cmdmap(type)) Quit:type=""
        Set data1=$get(cmdmap(type,1)),data2=$get(cmdmap(type,2))
        If data1="" Set data1=$listbuild($listget(data2),$listget(data2,2),-1,-1,$listget(data2,5))
        Set tmp(type)=$list(data1,1,4)_$list(data2,3,4),srcnsp=$list(data1,5)
    }
    Set type=""
    For  {
        Set type=$order(argmap(type)) Quit:type=""
        Set data1=$get(argmap(type,1)),data2=$get(argmap(type,2))
        If data1="" Set data1=$listbuild($listget(data2),$listget(data2,2),-1,-1,$listget(data2,5))
        Set data=$get(tmp(type))
        If data="" Set data=$listbuild($listget(data1),$listget(data1,2),-1,-1,-1,-1)
        Set tmp(type)=data_$list(data1,3,4)_$list(data2,3,4)
    }
    Set type=""
    For  {
        Set type=$order(tmp(type),1,data) Quit:type=""
        If $listlength(data)'=10 Set data=data_$listbuild(-1,-1,-1,-1)
        For i=4,6,8,10 {
            Set j=$list(data,i) If j>0 Set $list(data,i)=j-1
        }
        Set tmp=$lts(data,",")
        Set $piece(tmp,",",1)=$piece(tmp,",")_"."_type
        Set mapping=mapping_" "_tmp_","_srcnsp
    }
    Quit $$$OK
trap
    Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Return the list of source files that the routine and line map to.
/// The format of each source file data is:<p>
/// routineName.routineType,label,line,namespace
ClassMethod MappedFromLine(rtn As %String, line As %Integer, namespace As %String, ByRef mapping As %String) As %Status
{
    Set sc=..SourceLine(rtn,line,1,line,9999,.namespace,.map)
    If $$$ISERR(sc) Quit sc
    Set type="",mapping=""
    For  {
        Set type=$order(map(type)) Quit:type=""
        Set data1=$get(map(type,1)),data2=$get(map(type,2))
        If data1="" Set data1=$listbuild($listget(data2),$listget(data2,2),-1,-1)
        Set mapping=mapping_" "_$listget(data1)_"."_$zconvert(type,"l")_","_$listget(data1,2)_","_$listget(data1,3)_","_$listget(data1,5)
    }
    Set mapping=$extract(mapping,2,*)
    Quit $$$OK
}

/// error routine
Method Error(err As %String) As %Integer [ Private ]
{
 Set $ZT = ""
 Try { Write $$$FormatText($$$ERRMSG($$$ObjectScriptError),err),! } Catch {}
 Quit $$$ObjectScriptError
}

/// return process id of attached target
Method Pid() As %String
{
 Quit ..Debug.Pid
}

/// Get the values of the specified $c(1)-separated list of variables.
Query WatchList(deb As %Integer, Watch As %String(MAXLEN=1024)) As %Query(ROWSPEC = "Expression:%String,Value:%String") [ SqlProc ]
{
}

ClassMethod WatchListExecute(ByRef qHandle As %Binary, deb As %Integer, Watch As %String(MAXLEN=1024)) As %Status
{
    s Sdeb = $zobjref(deb)
    If (Sdeb = $$$NULLOREF) Quit 0
    s qHandle="",val = ""
    f i=1:1 {
        Set wv = $p(Watch,$c(1),i)
        Q:wv=""
        s rc = Sdeb.Debug.Eval(wv,.val)
        q:rc'=$$$OK
        s qHandle(wv)=val
    }
    s qHandle = ""
    Quit $$$OK
}

ClassMethod WatchListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = WatchListExecute ]
{
    Quit $$$OK
}

ClassMethod WatchListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = WatchListExecute ]
{
    s Row=""
    s var = $o(qHandle(qHandle))
    if var="" {
        s AtEnd=1
    }
    else {
        s Row = $ListBuild(var,qHandle(var))
        s qHandle = var
    }
    Quit $$$OK
}

/// Get the properties of the specified variable whose value is an oref.
/// %Studio.General::DumpObjectExecute implements logic to dump object
/// and collect properties in qHandle array. WatchList query from %Studio.Debugger to deliver array to client.
Query WatchListOref(deb As %Integer, WatchOref As %String(MAXLEN=256)) As %Query(ROWSPEC = "Expression:%String,Value:%String") [ SqlProc ]
{
}

ClassMethod WatchListOrefExecute(ByRef qHandle As %Binary, deb As %Integer, Watch As %String(MAXLEN=256)) As %Status
{
    s Sdeb = $zobjref(deb)
    If (Sdeb = $$$NULLOREF) QUIT $$$ERROR($$$DebugError)
    s qHandle="", proparray=""
    s rc = Sdeb.Debug.EvalOref(Watch,.proparray)
    i rc'=$$$OK Quit $$$ERROR(rc)
    i proparray="" QUIT $$$OK
    Set ptr=0
    While $listnext(proparray,ptr,prop) {
        If '$listnext(proparray,ptr,val) Quit
        Set qHandle(prop)=val
    }
    s qHandle = ""
    Quit $$$OK
}

ClassMethod WatchListOrefClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = WatchListExecute ]
{
    Quit $$$OK
}

ClassMethod WatchListOrefFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = WatchListExecute ]
{
    s Row=""
    s prop = $o(qHandle(qHandle))
    if prop="" {
        s AtEnd=1
    }
    else {
        s Row = $ListBuild(prop,qHandle(prop))
        s qHandle = prop
    }
    Quit $$$OK
}

Method ViewAsBinary(variableName As %String) As %String
{
    Set value = ""
    try {
        Set variable = ..Eval(variableName)
        if ($l(variable))
        {
            Set String="$bit("
            Set Bit=0
            for  {
                Set Bit=$bitfind(variable,1,Bit+1)
                i Bit=0 q
                Set String=String_Bit_","
            }
            If $e(String,*)="," s String=$e(String,1,*-1)
            Set value=String_")" 
        }
    }
    catch(x)
    {
        w !,$ZE,!
    }

    Quit value
}

}
