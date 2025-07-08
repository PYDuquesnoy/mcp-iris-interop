/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syStats)

/// This class provides methods to trace the execution of a process.  Traced processes
/// write events to a trace file with information about the routine line where it ocurred
/// and, if applicable, the global reference.  The events available for tracing
/// correspond to the metrics reported in performance monitoring tools (PERFMON,
/// %SYS.MONLBL, etc).  Raw data is written to a trace file, iristrace_<i>pid</i>.txt,
/// in a specified directory, which is parsed by this class.
/// <p>
/// Different sets of trace events can be selected to produce traces for different purposes.
/// Highly detailed application execution tracing can be achieved, including all 
/// global references (the GloRef event), all application subroutine calls (RtnLoad)
/// and/or every line of application code executed (RtnLines).  Or, tracing can be limited
/// to less common events such as physical block reads (DataBlkRd, UpntBlkRd, etc),
/// network cache misses (NCacheMiss), and/or block collisions (BlkWait), in order to
/// find all the locations in the application where these occurenced may be affecting 
/// performance.
Class %SYS.Trace Extends %SYSTEM.Help [ Abstract ]
{

/// Returns the directory where trace files will be written by processes being traced.
ClassMethod GetDirectory() As %SysPath
{
	s dir=$g(^%SYS("TRACE","DIR"))
	q dir
}

/// Sets the directory where trace files will be written by processes being traced.
/// Note that trace files may contain sensitive information such as global references
/// (but not values) or parameters passed to subroutines.  The trace directory must
/// exist and must be writeable by the processes being traced (i.e. on UNIX and Linux
/// systems it must be writeable by the effective group selected at installation).
ClassMethod SetDirectory(dir As %SysPath) As %Status
{
	q:'$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	s ndir="",sc=..ValidateDirectory(dir,.ndir)
	if $$$ISERR(sc) q sc
	s ^%SYS("TRACE","DIR")=ndir
	q $$$OK
}

/// Validates a directory argument for tracing.
/// Returns status success or error and, if validation passes,
/// passes the normalized directory back in ndir.
/// 
ClassMethod ValidateDirectory(dir As %SysPath, ByRef ndir As %SysPath) As %Status
{
	q:'$l(dir) $$$ERROR($$$DirectoryNameInvalid,dir)
	s ndir=##class(%File).NormalizeDirectory(dir)
	s len=$l(ndir)
	q:'len $$$ERROR($$$DirectoryNameInvalid,dir)
	q:$ZISWIDE(ndir) $$$ERROR($$$DirectoryNameInvalid,dir)
	$$$QUITONERROR(sc,##class(%SysPath).IsValid(ndir))
	q:'##class(%File).DirectoryExists(ndir) $$$ERROR($$$DirectoryNotExist,ndir)
	q $$$OK
}

/// Returns a list where each list element is a monitor event to record. 
/// See <METHOD>SetEvents</METHOD>.
ClassMethod GetEvents() As %List
{
	s events=$g(^%SYS("TRACE","EVENTS"))
	q:events'="" events
	#; The default set...
	s all=..EventNames()
	for i=$$$MONRTNLD,$$$MONGREF, ; calls, stack, and grefs
	      $$$MONBLKWAIT,$$$MONNETMISS, ; block collisions and network misses
	      $$$MONBLKRDDIR,$$$MONBLKRDUPNT,$$$MONBLKRDBPNT,$$$MONBLKRDDATA, ; physical reads
	      $$$MONBLKRDBDATA,$$$MONBLKRDMAP,$$$MONBLKRDOTHER { 
		s events=events_$lb($li(all,i+1)) ; +1 because $$$MON* constants are zero-based
	}
	q events
}

/// Set the default list of monitor events that traced processes will record in the trace file.  
/// The list of available events is returned by <METHOD>EventNames</METHOD> and listed in
/// by the ^TRACE or ^%SYS.MONLBL utilities.
/// <p>
/// Note that the "RtnLoad" event is treated specially, and traces not just literal
/// routine loads but all subroutine calls and returns.  This allows for tracing the
/// application stack and time spent in subroutines, methods, and extrinsic functions.
ClassMethod SetEvents(events As %List) As %Status
{
	q:'$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	try {
		s sc=..ValidateEvents(events)
		if $$$ISERR(sc) return sc
		s ^%SYS("TRACE","EVENTS")=events
		return $$$OK
	} catch err {
		return err.AsStatus()
	}
}

/// Validate a list of monitor events for trace files.
/// Returns status success if the event list is valid and an error if not.
/// 
ClassMethod ValidateEvents(events As %List) As %Status
{
	return ..GetEventCodes(events)
}

/// Validate a list of monitor events for trace files and, if status is OK,
/// returns a list of numerical event codes in nlist. Wrapped by ValidateEvents
/// to obscure nlist, which is for internal use only. Called directly by StartPID.
/// 
ClassMethod GetEventCodes(events As %List, ByRef nlist As %List) As %Status [ Internal ]
{
	try {
		s list=..EventNames(),nlist=""
		return:'$ll(events) $$$ERROR($$$InvalidParameter1,"events")
		f i=1:1:$ll(events) {
			s e=$li(events,i)
			s n=$listfind(list,e)
			return:'n $$$ERROR($$$InvalidParameter1,"events")
			s nlist=nlist_$lb(n-1)
		}
		return $$$OK
	} catch err {
		return err.AsStatus()
	}
}

/// Returns the system-wide default for maximum trace file size in MB. See SetMaxSize.
ClassMethod GetMaxSize() As %Integer
{
	s maxsize=$g(^%SYS("TRACE","MAXSIZE"),0)
	return maxsize
}

/// Sets the system-wide default for maximum trace file size in MB. The default value is 0 (no cap).
/// The value, when converted from MB to bytes, must be a valid integer (maximum ~2047 MB).
ClassMethod SetMaxSize(maxsize As %Integer) As %Status
{
	q:'$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	s sc=..ValidateMaxSize(maxsize)
	if $$$ISERR(sc) return sc
	s ^%SYS("TRACE","MAXSIZE")=maxsize
	return $$$OK
}

/// Accepts as input a size cap in MB, converts to bytes, and checks if the byte count is within range.
/// If the byte count is negative or too large for a 32-bit integer, it is invalid.
ClassMethod ValidateMaxSize(maxsize As %Integer) As %Status
{
	#; convert MB to bytes and round to the nearest integer
	s maxbytes=(maxsize*1024*1024\1)
	#; Ensure value is within range for a 32-bit integer
	if (maxbytes < 0)||(maxbytes > 2147483647) {
		return $$$ERROR($$$InvalidParameter,"maxsize","Value outside of range (0-2047), was "_maxsize)
	}
	return $$$OK
}

/// Start tracing in a target process.  If a trace file of the same name
/// already exists, it will be recreated. If arguments are empty, 
/// system-wide defaults will be used.
/// Note that a successful return status does not wait for the target
/// process to (re)create the trace file.
ClassMethod StartPID(pid, dir As %String = "", events As %List = "", maxsize As %Integer = "") As %Status
{
	q:'$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	if dir="" set dir=..GetDirectory()
	s ndir="",sc=..ValidateDirectory(dir,.ndir)
	if $$$ISERR(sc) q sc
	if events="" set events=..GetEvents()
	s sc=..GetEventCodes(events,.nlist)
	if $$$ISERR(sc) q sc
	#; Compose the event bytestring. Each char is an event's numerical code.
	s nevents=""
	f i=1:1:$ll(nlist) { 
		s nevents=nevents_$char($li(nlist,i)) 
	}
	if maxsize="" set maxsize=..GetMaxSize()
	s sc=..ValidateMaxSize(maxsize)
	if $$$ISERR(sc) q sc
	s maxbytes=(maxsize*1024*1024)\1
	s ok=$zu(84,18,1,pid,ndir,nevents,maxbytes)
	#; Tracing is configured but possibly not yet started upon success.
	#; Possible error returns are as follows:
	#;	 0: process does not exist or is shutting down
	#;	-1: process is already being traced
	#;  -2: not enough memory for the trace configuration struct
	q:(ok=-2) $$$ERROR($$$InsufficientSMHeap)
	q:(ok=-1) $$$ERROR($$$ProcessAlreadyTraced,pid)
	q:'ok $$$ERROR($$$ProcessDoesNotExist,pid)
	q $$$OK
}

/// Stop a process's trace
ClassMethod StopPID(pid) As %Status
{
	#; only fails if pid not found, so really success
	s ok=$zu(84,18,0,pid)
	q $$$OK
}

/// Returns a list all process IDs that are being traced
ClassMethod PIDList() As %List
{
	q $listfromstring($zu(84,18,2),",")
}

/// Returns a list of event names
ClassMethod EventNames() As %List
{
	f i=1:1:$$$MONPID {
		s t=$text(@("Flist+"_i_"^%SYS.MONLBL"))
		s $list(evtnames,i)=$p(t,";",4)
	}
	q evtnames
}

/// Reads a trace file and parses records into rows with the following columns:
/// <li><b>Event:</b> the event (monitor metric) name, or special markers CALL, QUIT, START, STOP, HALT, ARG, STACK 
/// <li><b>Text:</b> some events (ARG and STACK) carry only an unstructured text note relating to the previous event (with all other columns null)
/// <li><b>TOffset:</b> time offset from start in microseconds
/// <li><b>Level:</b> the stack level if subroutine calls are being traced, otherwise -1
/// <li><b>Count:</b> the number that this event would add to the corresponding performance metric (typically 1)
/// <li><b>LineAndRoutine:</b> routine line where the event occurred 
/// <li><b>RoutineSFN:</b> internal SFN (system file number) for the routine database (directly from trace file) 
/// <li><b>RoutineLoc:</b> an implied namespace (^sys^directory) corresponding to RoutineSFN. If the trace file was created prior to the last
/// startup (or created on a different machine), this column may be inaccurate or null.
/// <li><b>SrcLine:</b> the line of source code, if the "s" flag is used and if the source is available)
/// <li><b>GlobalRef:</b> Null if the trace event is not an operation on a global, otherwise the global
/// reference (gvn).  The reference includes a leading ^.  No environment is specified - it is not given
/// as an extended reference - except in the case of a process private global, which will include ^||.
/// In some unusual cases the global reference may not be able to be translated properly and either the
/// last subscript may appear incomplete, or the value of GlobalRef may instead be a printable sequence
/// of hex characters with no leading ^.  Therefore the caller should be mindful if doing any
/// manipulations of this value (e.g. use try/catch if operating on this value with $qlength or $qsubscript).
/// If "q" is specified in the flags parameter, non-printing characters in the global reference will be
/// quoted (similarly to the output of the ZWRITE command).
/// <li><b>GlobalSFN:</b> internal SFN (system file number) for the database (directly from trace file) 
/// <li><b>GlobalLoc:</b> an implied namespace (^sys^directory) corresponding to GlobalSFN.  If the trace file was created prior to the last
/// startup (or created on a different machine), this column may be inaccurate or null.  Process private globals also report null.
/// <p>
/// The flags parameter may include the following characters
/// <br>s - fetch source line into SrcLine column from routine INT code
/// <br>q - quote global reference to avoid non-printing characters in subscript
/// <p>
/// Note that if the end of the trace file is reached before a STOP or HALT record up fetching the
/// next row, an error $$$UnexpectedEndOfFile, will be returned and additional rows may become
/// available later if the traced process is still running.
Query ReadFile(file As %String, flags As %String) As %Query(ROWSPEC = "Event:%String,Text:%String,TOffset:%Integer,Level:%Integer,Count:%Integer,LineAndRoutine:%String,RoutineSFN:%Integer,RoutineLoc:%String,SrcLine:%String,GlobalRef:%String,GlobalSFN:%Integer,GlobalLoc:%String") [ SqlProc ]
{
}

ClassMethod ReadFileExecute(ByRef qHandle As %Binary, file As %String, flags As %String) As %Status [ Internal ]
{
	o file:"R":5 e  q $$$ERROR($$$FileCanNotOpen,file)
	try {
		s qHandle=$lb(file,$get(flags),-1,"","",..EventNames())
		s sc=$$$OK
	} catch {
		c file
		s sc=err.AsStatus()
	}
	q sc
}

ClassMethod ReadFileFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s $lb(file,flags,level,lastrou,lastrsfn)=qHandle
	s io=$io,sc=$$$OK
	s oldzeof=$zu(68,40,1)
	s sc=$$$OK
	try {
		u file
		r line 
		i $zb=""||$zeof {
			#; We've reached the end of file before encountering a STOP or HALT record
			#; Return an error and the caller may decide to call %Next() again.
			#; If we got a partial record ($zb shows no terminator) back up to the
			#; beginning of line in case we're called again..
			i $zb="",$zseek(-$l(line),1)
			s sc=$$$ERROR($$$UnexpectedEndOfFile)
			q
		}
		#; We have a line to process
		#;
		#; Comma-delimited pieces in file:
		#;	1(evt)  2      3      4      5      6    
		#;  ------  -----  -----  -----  -----  -----  
		#;  START   time   rsfn   rou    level  ver^mstarttime
		#;  STOP    time
		#;  HALT
		#;  metric# time   rsfn   rou+ln count  grefhex^sfn^col^gstate
		#;  CALL    time   rsfn   rou+ln
		#;  QUIT    time   lineno
		#; 	STACK   text
		#;  ARG     text
		s evt=$p(line,",")
		#; SGM158+
		s text=$p(line,",",2,*) 
		if (evt="ARG") && ($p($p(text,"]",2)," ",2)="STR") {
			#; Decode the hex-encoded string values for string ARG events.
			#; The prefix NH indicates the hex digits per character.
			#; Unicode strings are two bytes or four hex digits per character.
			#; 8-bit strings are one byte or two hex digits per character.
			s strstart=$find(text,"): ")
			s hexlen=$e(text,strstart)
			s hexstr=$e(text,strstart+2,*)
			s str="" f i=1:hexlen:$l(hexstr) s str=str_$c($zh($e(hexstr,i,i+hexlen-1)_"h"))
			s text=$e(text,1,strstart-1)_$$Quote^%qcr(str)
			s Row=$lb(evt,text)
			q
		}
		#; SGM158-
		i (evt="STACK") || (evt="ARG") {
			#; These are treated as unstructured text
			s Row=$lb(evt,$p(line,",",2,*))
			q
		}
		s tim=$p(line,",",2)
		s rsfn=$p(line,",",3) 
		s rou=$p(line,",",4),ln=$p(rou,"+",2),rou=$p(rou,"+",1)
		s cnt=$p(line,",",5) 
		s gref=$p(line,",",6)
		i 'cnt&&(evt=$$$MONRTNLD) {
			s cnt=1 ; we don't trace the first MONRTNLD, so count it in the zero-count record
			s $li(qHandle,4,5)=$lb(rou,rsfn)
		} elseif evt="START" {
			s level=cnt,cnt=1,gref=""
			s $li(qHandle,3,5)=$lb(level,rou,rsfn)
		} elseif evt="QUIT" {
			s ln=rsfn
			s rou=lastrou
			s rsfn=lastrsfn
			s $li(qHandle,3)=level-1
		} elseif evt="CALL" {
			s evt="CALL"
			s $li(qHandle,3)=level+1
		} elseif (evt="STOP") || (evt="HALT") {
			s AtEnd=1
		}
		i gref'="" {
			s gsfn=$piece(gref,"^",2),col=$piece(gref,"^",3),gstate=$p(gref,"^",4)
			s gref=$piece(gref,"^",1)
			try {
				#; Translate the gref to printable.  
				s enc="" f i=1:2:$l(gref) s enc=enc_$c($zh($e(gref,i,i+1)_"h"))
				#; If gstate has GFS_ORDSETUP then the reference may have
				#; a 1 or 6 0xFFs as the final subscript for $order
				#; (forward and reverse respectively).  If so strip it off
				#; so it prints as a null subscript.
				i $zb(+gstate,16,1) {
					i ($e(enc,*)=$c(1)) {
						s gvn("internal")=$e(enc,1,*-1)
					} elseif ($e(enc,*-5,*)=$c(255,255,255,255,255,255)) {
						s gvn("internal")=$e(enc,1,*-6)
					} else {
						s gvn("internal")=enc
					}
				} else {
					s gvn("internal")=enc
				}
				#; Now convert to printable
				d GetPrintableRef^|"%SYS"|DMREPAIR(.gvn,$zu(70,1,col))
				i flags["q" { s tmp=$$Quote^%qcr($e(gvn("printable"),2,*),1) }
				else { s tmp=$e(gvn("printable"),2,*) }
				i $zb(+gstate,8,1) {
					#; PPG reference
					s gref="^||"_tmp
					s gimplns=""
				} else {
					s gref="^"_tmp
					s gimplns=$$SFNtoNS(gsfn)
				}
			} catch {} ; gref is hex dump of encoded form on error
		}
		i rsfn'="" {
			s rimplns=$$SFNtoNS(rsfn)
			try { s:ln&&(rimplns'="")&&(flags["s") srcline=$g(^|rimplns|ROUTINE(rou,0,ln)) } catch {}
		}
		s:evt=0||evt evt=$li($li(qHandle,6),evt+1) ; convert numeric to event name
		s Row=$lb(evt,"",tim,level,cnt,
		          $s(ln:"+"_ln_"^"_rou,rou="":"",1:"^"_rou),rsfn,rimplns,srcline,
		          gref,gsfn,rimplns)
	} catch err { }
	u io
	d $zu(68,40,oldzeof)
	q:$g(err) err.AsStatus()
	q sc
SFNtoNS(sfn)
	s dir=$p($zu(49,+sfn,3),"^",2)
	q:dir="" ""
	s sys=$p($zu(49,+sfn,3),"^",1)
	q:'sys "^^"_dir
	s sys=$zu(63,4,sys)
	q:sys="" ""
	q "^"_sys_"^"_dir
}

ClassMethod ReadFileClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	c $list(qHandle,1)
	q $$$OK
}

/// Writes a formatted display of a trace file to the current device.
/// <p>
/// The flags parameter may include the following characters 
/// <br>d - Display databases for routines and globals.  If possible, ^sys^directory is displayed,
/// otherwise, internal system file numbers.  If the trace file was created prior to the last
/// startup (or created on a different machine), the reported ^sys^directory may be inaccurate.
/// <br>n - Display databases for routines and global references as internal system file numbers.
/// <br>s - Display source line
/// <br>w - Wait for more data if end of the file is encountered and the process is still being traced (ctrl-c to stop)
ClassMethod Display(file As %String, flags As %String)
{
#define indent w ! w:$l(t) $j(t-stime/1000000,0,6)_":" w ?15,$j("",$select(level<20:level*2,1:40))
#define boldon w *27,*91,*49,*109
#define boldoff w *27,*91,*48,*109
	try {
		s level=-1,(stime,dtim)=0,flags=$g(flags)
		w !,"Reading TRACE file ",file
		s rs=##class(%ResultSet).%New("%SYS.Trace:ReadFile")
		$$$THROWONERROR(sc,rs.%Execute(file,flags_"q"))
		f  {
			b 4
			s atend='rs.%Next(.sc)
			b 5
			i $$$ISERR(sc) {
				i ($$$GETERRORCODE(sc)=$$$ERRORCODE($$$UnexpectedEndOfFile)) {
					q:flags'["w"
					h .1
					continue
				}
				$$$ThrowStatus(sc)
			}
			q:atend
			s evt=rs.Event
			s t=rs.TOffset
			i rs.Text'="" {
				#; just display the event and its text
				$$$indent w evt," ",rs.Text
				continue
			}
			s:rs.Level'="" level=rs.Level
			s info=""
			i evt="START" {
				s stime=t
			} elseif evt="CALL" {
				s stime(level+1)=t
			} elseif evt="QUIT" {
				s:$g(stime(level))'="" info="("_(t-stime(level)/1000000)_"s in call)"
			}
			$$$indent $$$boldon w evt $$$boldoff 
			w:(rs.Count'=1)&&(rs.Count'="") "[",rs.Count,"]"
			i rs.LineAndRoutine'="" {
				w:(evt'="RtnLoad") " at" ; RtnLoad displays the routine being loaded so no "at"
				w " ",rs.LineAndRoutine
				i (flags["n") || ((flags["d") && (rs.RoutineLoc="")) {
					w " in SFN ",rs.RoutineSFN
				} elseif (flags["d") {
					w " in ",rs.RoutineLoc
				} 
			}
			w:$l(info) " ",info		
			s t="" ; don't re-print time in $$$indent
			i rs.GlobalRef'="" {
				i (flags'["n") && (flags'["d") {
					w ", ",rs.GlobalRef
				} else { 
					$$$indent
					w "ref: ",rs.GlobalRef
					i $e(rs.GlobalRef,1,3)'="^||" {
						i (flags["n") || ((flags["d") && (rs.GlobalLoc="")) {
							w " in SFN ",rs.GlobalSFN
						} elseif (flags["d") {
							w " in ",rs.GlobalLoc
						}
					}
				}
			}	
			i rs.SrcLine'="" { 
				$$$indent
				f i=1:1 { q:($e(rs.SrcLine,i)'=$c(9))&&($e(rs.SrcLine,i)'=" ") }
				w "src:  ",$e(rs.SrcLine,i,*)
			}
		}
	} catch err {
		$$$boldoff
		w:err.Name'="<INTERRUPT>" !!,"Error reading trace file: ",err.DisplayString()
		b 1
	}
	w !
}

}
