/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// The <class>%Routine</class> class provides a way to create and manipulate 
/// routines stored within a database.
/// <p>The <class>%Routine</class> class provides a stream interface 
/// (<i>see <class>%AbstractStream</class></i>) that allows you to read existing 
/// routines as well as create new one programmatically.
/// <p><class>%Routine</class> includes methods to save and compile 
/// modified routines.
/// <p>For example, the following code creates, saves, and compiles a 
/// simple ObjectScript routine (note that lines of code start with a space 
/// character):
/// <example>
/// Set routine = ##class(%Routine).%New("MyRoutine.MAC")
/// 
/// ; Write lines of code to the routine
/// Do routine.WriteLine("MyRoutine")
/// Do routine.WriteLine("Tag()")
/// Do routine.WriteLine(" Write ""This is my routine"",!")
/// Do routine.WriteLine(" Quit")
/// 
/// ; save the routine
/// Do routine.Save()
/// 
/// ; compile the routine
/// Do routine.Compile()
/// </example>
Class %Library.Routine Extends (%CharacterStream, %AbstractStream) [ Inheritance = right, System = 2 ]
{

/// The name of the routine.
Property RoutineName As %String;

/// The type of the routine.
Property RoutineType As %String;

Property RoutineVersion As %Integer;

/// True if this routine is generated from something else
Property Generated As %Boolean [ InitialExpression = 0 ];

/// For INT routines if this is compiled from a MAC then return true if the INT
/// is up to date with the MAC, but if the INT is different to the MAC, e.g. it was
/// modified and saved directly or the MAC was modified and saved but not compiled
/// then it will return false.<p>
/// For MAC routines it will be true if the generated pcode from compiling this MAC
/// is up to date and false if recompiling this MAC would generate different pcode, so
/// either the MAC has changed or the pcode has changed.
Property UpToDate As %Boolean [ Calculated ];

Method UpToDateGet() As %Boolean
{
	If i%IsModified Quit 0
	Set UpToDateState=1
	If $$$rtnIsMAC(i%RoutineType),$data(^rMAC(i%RoutineName,0)) {
		Set UpToDateState=0
		If $get(^ROUTINE(i%RoutineName,"MAC"))=$G(^rMAC(i%RoutineName,0)) {
			Set objts=$get(^rOBJ(i%RoutineName,"INT"))
			If objts=""||(objts=$get(^ROUTINE(i%RoutineName,0))) {
				Set UpToDateState=1
			}
		}
	} ElseIf $$$rtnIsINT(i%RoutineType),$data(^ROUTINE(i%RoutineName,0)) {
		If ..Generated {
			Set ts=$G(^ROUTINE(i%RoutineName,0))
			Set tsmac=$get(^rMAC(i%RoutineName,0))
			If tsmac'="" {
				If tsmac'=$get(^ROUTINE(i%RoutineName,"MAC")) {
					Set UpToDateState=0
				}
			} Else {
				Set class=$$RtnIsClass^%apiRTN(i%RoutineName)
				If class'="",$get(^ROUTINE(i%RoutineName,0,"CLS"))'=$$$defClassKeyGet(class,$$$cCLASStimechanged) {
					Set UpToDateState=0
				}
			}
		}
	}
	Quit UpToDateState
}

Property StoreGlvn As %String [ Calculated, Private ];

Property TempNode As %String [ Private ];

/// The current node we are reading from.
Property NodeNo As %String [ InitialExpression = 0, Private ];

Property Buffer As %Binary [ MultiDimensional, Private ];

Property Position As %Integer [ InitialExpression = 2, Private ];

Property IOSize As %Integer [ InitialExpression = 0, Private ];

Property IOLines As %Integer [ InitialExpression = 0, Private ];

Property IOLangMode As %Integer [ InitialExpression = 0, Private ];

Property IsModified As %Boolean [ InitialExpression = 0 ];

Property TimeStamp As %TimeStamp;

/// Number of times this routine has been locked.
Property Locked As %Integer [ InitialExpression = 0 ];

/// Lock the current routine
Method Lock() As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$FileNameInvalid,..RoutineName)
	If i%Locked>0 {
		Set i%Locked=i%Locked+1
		Quit $$$OK
	}
	Set ok=..LockRoutine(..RoutineName_"."_..RoutineType,1)
	If $$$ISERR(ok) Quit ok
	Set i%Locked=1
	Quit $$$OK
}

/// Unlock the current routine
Method Unlock() As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$FileNameInvalid,..RoutineName)
	Quit:i%Locked=0 $$$OK
	If i%Locked>1 {
		Set i%Locked=i%Locked-1
		Quit $$$OK
	}
	Set ok=..LockRoutine(..RoutineName_"."_..RoutineType,0)
	If $$$ISERR(ok) Quit ok
	Set i%Locked=0
	Quit $$$OK
}

/// Lock a particular routine <parameter>name</parameter>. If <parameter>lock</parameter> is true (the default)
/// then it locks the routine, and if false then it unlocks the routine. If a routine is derived from
/// a class then it will lock the class name in ^oddDEF to prevent another user from attempting to
/// edit the class at the same time this process is editing the routine. If IModeLock is True,
/// then it will unlock the routine with the #I flag so that the node will unlock even if in a transaction.
ClassMethod LockRoutine(name As %String, lock As %Boolean = 1, nsp As %String = {$namespace}, IModeLock As %Boolean = 0, timeout As %Integer = 0) As %Status
{
	Set name=$piece(name,";")
	Set sc=..normalizeName(.name,.rtn,.ext) If $$$ISERR(sc) Quit sc
	If nsp'="",nsp'=$namespace New $namespace Set $namespace=nsp
	
	#; Check to see if this routines is compiled from a class, and if so lock the class as well
	If '$$$rtnIsINC(ext),rtn[".",$piece(rtn,".",*)?0.1"G".N {
		If $$$rtnIsMAC(ext) {
			Set other=##class(%RoutineMgr).GetOther(rtn,ext,-1)
		} Else {
			Set other=##class(%RoutineMgr).GetOther(rtn,ext)
		}
		If $ZConvert($Piece(other,".",*),"U")="CSP" Set other=##class(%RoutineMgr).GetOther($Piece(other,".",1,*-1),"CSP")
		If other?.E1".CLS" {
			If ..CheckProtect(name) Quit $$$ERROR($$$RoutineProtect,name)
			Set other=$Piece(other,".CLS")
			If lock {
				Set sc=$$LockOneClass^%occLock(other,0,1,timeout)
			} Else {
				Set sc=$$UnlockOneClass^%occLock(other,0,1,IModeLock)
			}
			Quit sc
		}
	}
	#; For MAC lock the INT routine
	Set gbl=$select($$$rtnIsINT(ext)||($$$rtnIsMAC(ext)):"ROUTINE",$$$rtnIsINC(ext):"rINC",ext="OBJ":"rOBJ",1:"")
	If gbl="" Quit $$$ERROR($$$CanNotLockRoutine,name)
	If lock {
		Quit ##Class(%SYS.GlobalQuery).Lock(gbl,rtn,name,timeout)
	} else {
		Quit ##Class(%SYS.GlobalQuery).UnLock(gbl,rtn,IModeLock)
	}
}

/// Split a routine name into its components; set the name,type etc.
/// <p>If <var>name</var> has no extension, then the default is <i>.MAC</i>.
Method ParseRoutineName(name As %String) As %Status [ Private ]
{
	Set version=$piece(name,";",2,*),name=$piece(name,";")
	Set sc=..normalizeName(.name,.rn,.rt,0) If $$$ISERR(sc) Quit sc
	Set lang=$$$rtnTypeLang(rt),sc=$$$OK
	#; If routine already exists no need to check if name is valid
	If (rn'="")&&(rt'="")&&('$data(^rINDEX(rn,rt)))||(rt="") {
		If ..IOLangMode=10 {
			If rn'="",'$zname(rn,1,..IOLangMode) Quit $$$ERROR($$$FileNameInvalid,name)
		} Else {
			If rn'="",'$zname(rn,1) Quit $$$ERROR($$$FileNameInvalid,name)
		}
	}
	If $length(rn)>0 {
		Set i=""
		For  {
			Set i=$order(^rINDEX(rn,i)) Quit:i=""
			If i=rn||(i="OBJ") Continue
			If $$$rtnTypeLang(i)'=lang Set sc=$$$ERROR($$$RoutineAlreadyExists,rn_"."_i) Quit
		}
		If $$$ISERR(sc) Quit sc
	}
	If i%RoutineName=rn,i%RoutineType=rt Quit $$$OK
	If i%Locked {
		Set ok=..LockRoutine(rn_"."_rt,1)
		If $$$ISERR(ok) Quit ok
		Do ..LockRoutine(i%RoutineName_"."_i%RoutineType,0)
	}	
	
	Set i%RoutineName=rn,i%RoutineType=rt,i%RoutineVersion=version
	If i%RoutineVersion'="" Set i%RoutineVersion=##class(%RoutineMgr).ConvertVersion(rn,rt,i%RoutineVersion)
	#; For MVB, BAS language we need to set IOLangMode, for Mumps languages keep existing one
	Set oldlang=$select(..IOLangMode<10:0,1:..IOLangMode)
	If lang'=oldlang Set ..IOLangMode=lang
	Quit $$$OK
}

/// Check if we are allowed to save this routine in this namespace
ClassMethod CheckProtect(name As %String) As %Boolean
{
	Set sc=..normalizeName(.name,.rtn,.type) If $$$ISERR(sc) Quit 0
	Set return=0,global=$$$rtnGlobal(type),global=$extract(global,2,*)
	Set protection=$$GetGlobalPermission^%SYS.SECURITY($namespace,global,"("""_rtn_""")",1)
	Quit protection'["WRITE"
}

/// Return the complete routine name for this routine.
Method BuildRoutineName() As %String [ CodeMode = expression, Private ]
{
..RoutineName_"."_..RoutineType
}

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	Quit ..OpenStream(initval)
}

Method IOInit() [ Private ]
{
	Set i%AtEnd=0,i%Mode=0,i%NodeNo=0,i%Position=1,i%IOSize=0,i%IOLines=0,i%IOLangMode="",i%RoutineName="",i%RoutineType="",i%Locked=0,i%TempNode=""
	Quit
}

Method Rewind() As %Status
{
	#; Mode ..#WRITE: Flush
	If i%Mode=..#WRITE Do ..Flush() Set i%Mode=..#READCHANGED
	Set i%NodeNo=0,i%Position=2,i%Buffer="",i%AtEnd=0
	Set:i%Mode=..#READNODATA i%AtEnd=1
	Quit $$$OK
}

Method Flush() As %Status
{
	#; If i%Mode=..#WRITE Save Data in i%Buffer; don't change mode
	If i%Mode'=..#WRITE||(i%Buffer="") Quit $$$OK
	
	#; force write of data in buffer
	#; flush any data in buffer as well
	Set i%IOLines=i%IOLines+1
	Set ^||%Routine(i%TempNode,i%IOLines)=$translate(i%Buffer,$char(10))
	Set i%Buffer=""
	
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method SizeGet() As %Integer [ CodeMode = expression ]
{
i%IOSize
}

Method IOGetStreamId() As %String [ CodeMode = expression, Private ]
{
..BuildRoutineName()
}

Method OpenStream(sid As %String) As %Status
{
	#; Mode = ..#READCHANGED or ..#WRITE: Kill new data
	If (i%Mode=..#READCHANGED)!(i%Mode=..#WRITE) Kill ^||%Routine(i%TempNode) Set i%Mode=..#READNODATA
	
	Set sc=..normalizeName(.sid,.rn,,0) If $$$ISERR(sc) Quit sc
	If $isobject($get(%SourceControl)),rn'="" Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeLoad(sid)
	Set ..IOLangMode="",i%IOSize=0,i%IOLines=0,..TimeStamp="",i%TempNode="",i%Buffer="",i%Position=2,..Generated=0
	Set i%TempNode=$Increment(^||%Routine),tmp=i%TempNode Kill ^||%Routine(tmp)
	#; sid contains stream id to open
	#; stream id is routine name
	Set rc=..ParseRoutineName(sid) If $$$ISERR(rc) Quit rc
	Set name=..RoutineName,type=..RoutineType
	
	Set ts="",size=0,iolines=0
	If name="" {
		Set i%Mode=..#READNODATA,i%AtEnd=1
	} Else {
		Set i%Mode=..#READNOTCHANGED,i%AtEnd=0
		If ..RoutineVersion'="" {
			If $$$rtnIsMAC(type),$data(^rMACSAVE(name,..RoutineVersion)) {
				Set ..IOLangMode=$get(^rMACSAVE(name,..RoutineVersion,0,"LANG"))
				Set ts=$get(^rMACSAVE(name,..RoutineVersion))
				Set i=0 For  Set i=$order(^rMACSAVE(name,..RoutineVersion,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
			} ElseIf $$$rtnIsINC(type),$data(^rINCSAVE(name,..RoutineVersion)) {
				Set ..IOLangMode=$get(^rINCSAVE(name,..RoutineVersion,0,"LANG"))
				Set ts=$get(^rINCSAVE(name,..RoutineVersion))
				Set i=0 For  Set i=$order(^rINCSAVE(name,..RoutineVersion,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
			} ElseIf $$$rtnIsINT(type),$data(^rBACKUP(name,type,..RoutineVersion)) {
				Set ts=$get(^rBACKUP(name,type,..RoutineVersion,0))
				If ts="" {
					Set ts=$get(^rBACKUP(name,type,..RoutineVersion))
					Try {
						If ts'="",$ascii(ts)<48 Set ts=$listget(ts) If ts'="" Set ts=$zdth(ts,3)
					} Catch {}
				}
				Set ..IOLangMode=$get(^rBACKUP(name,type,..RoutineVersion,"LANG"))
				Set i=0 For  Set i=$order(^rBACKUP(name,type,..RoutineVersion,0,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
			}
		} ElseIf $$$rtnIsMAC(type),$data(^rMAC(name,0)) {
			Set ..IOLangMode=$G(^rMAC(name,0,"LANG"))
			Set ..Generated=+$get(^rMAC(name,0,"GENERATED"))
			Set ts=$G(^rMAC(name,0))
			Set i=0 For  Set i=$order(^rMAC(name,0,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
		} ElseIf $$$rtnIsINC(type),$data(^rINC(name,0)) {
			Set ..Generated=+$get(^rINC(name,0,"GENERATED"))
			Set ts=$G(^rINC(name,0))
			Set i=0 For  Set i=$order(^rINC(name,0,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
		} ElseIf $$$rtnIsINT(type),$data(^ROUTINE(name,0)) {
			Set ..IOLangMode=$G(^ROUTINE(name,"LANG"))
			Set ..Generated=+$get(^ROUTINE(name,0,"GENERATED"))
			Set ts=$G(^ROUTINE(name,0))
			#; If you 'ZR' the last line of a routine
			#; it does not remove the global but just reduces the line count. So we have to clean
			#; this up here.
			Set i=$get(^ROUTINE(name,0,0))
			For  Set i=$order(^ROUTINE(name,0,i)) Quit:+i=0  Kill ^ROUTINE(name,0,i)
			Set i=0 For  Set i=$order(^ROUTINE(name,0,i),1,line) Quit:+i'=i  Set ^||%Routine(tmp,$i(iolines))=line,size=size+$length(line)
		}
	}
	#; Do not count a lf on the last line
	Set i%IOLines=iolines,i%IOSize=size+$select(iolines>1:iolines-1,1:0)
	If ts'="" Set ..TimeStamp=$$$TimeToODBC(ts)
	
	If $isobject($get(%SourceControl)),$piece(sid,".",1,$length(sid,".")-1)'="" Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterLoad(sid,$this)
	Set i%IsModified=0
	Quit $$$OK
}

Method SaveStream(supressbackup As %Boolean = 0, Output Refresh As %Boolean) As %Status
{
#define compH(%h1,%h2) $s(+%h1<+%h2:-1,%h1>%h2:1,$p(%h1,",",2)<$p(%h2,",",2):-1,$p(%h1,",",2)>$p(%h2,",",2):1,1:0)
	Set Refresh=0,sc=$$$OK
	#; save the stream;
	If i%Mode=..#READNODATA Do ..Write(" ")
	If ..RoutineName="" Quit $$$ERROR($$$FileNameInvalid,"."_..RoutineType)
	
	If ..CheckProtect(..RoutineName_"."_..RoutineType) Quit $$$ERROR($$$RoutineProtect,..RoutineName)
	
	If i%Mode=..#WRITE Do ..Flush()
	
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Do $System.Encryption.SHA1HashResult()
	. Set i="",tmp=i%TempNode For  Set i=$order(^||%Routine(tmp,i),1,line) Quit:i=""  Do $system.Encryption.SHA1HashInput($listbuild(line))
	. Set before=$System.Encryption.SHA1HashResult()
	. Set srcCtl=%SourceControl New %SourceControl Set rc=srcCtl.OnBeforeSave(..RoutineName_"."_$zconvert(..RoutineType,"U"),$name(^||%Routine(i%TempNode)),$this)
	. Set i="",tmp=i%TempNode For  Set i=$order(^||%Routine(tmp,i),1,line) Quit:i=""  Do $system.Encryption.SHA1HashInput($listbuild(line))
	. If before'=$System.Encryption.SHA1HashResult() Do
	. . Set Refresh=1
	. . If $get(srcCtl.Modified)=1 Set srcCtl.Modified(..RoutineName_"."_$zconvert(..RoutineType,"U"))=1
	
	#; Do we need to save a backup version
	If 'supressbackup,$$VERMAX^%R(..RoutineType)>0 Do CreateBackup^%apiRTN(..RoutineName,..RoutineType,$name(^||%Routine(i%TempNode)))
		
	#; copy temp into store
	#; temp is stored line by line, merge it into store location
	If i%Mode'=..#READNOTCHANGED {
		Set tmp=i%TempNode,size=0,i="",lastline=""
		If $$$rtnIsMAC(..RoutineType) {
			Kill ^rMAC(..RoutineName) Do RemoveMap^%qarmac(..RoutineName,"MAC") $$$rtnRemoveMACIdx(..RoutineName)
			do:$d($$$SQLIndex(2,..RoutineName)) DeleteSQLIndex^%SYS.SQLSRV(..RoutineName)
			For  Set i=$O(^||%Routine(tmp,i),1,line) Quit:i=""  Set ^rMAC(..RoutineName,0,i)=line,size=size+$l(line)+1,lastline=i
			Set ^rMAC(..RoutineName,0,0)=lastline
			Set ^rMAC(..RoutineName,0,"SIZE")=$select(size>0:size-1,1:size)
		} ElseIf $$$rtnIsINT(..RoutineType) {
			Kill ^ROUTINE(..RoutineName) $$$rtnRemoveINTIdx(..RoutineName)
			For  Set i=$O(^||%Routine(tmp,i),1,line) Quit:i=""  Set ^ROUTINE(..RoutineName,0,i)=line,size=size+$l(line)+1,lastline=i
			Set ^ROUTINE(..RoutineName,0,0)=lastline
			Set ^ROUTINE(..RoutineName,0,"SIZE")=$select(size>0:size-1,1:size)
		} ElseIf $$$rtnIsINC(..RoutineType) {
			Kill ^rINC(..RoutineName) $$$rtnRemoveINCIdx(..RoutineName)
			For  Set i=$O(^||%Routine(tmp,i),1,line) Quit:i=""  Set ^rINC(..RoutineName,0,i)=line,size=size+$l(line)+1,lastline=i
			Set ^rINC(..RoutineName,0,0)=lastline
			Set ^rINC(..RoutineName,0,"SIZE")=$select(size>0:size-1,1:size)
		}
	}
	
	#; save size,timestamp etc. in appropriate nodes
	Set ts=$zutil(188)
	If $$$rtnIsMAC(..RoutineType) {
		Set ^rMAC(..RoutineName,0)=ts
		If ..IOLangMode'="" Set ^rMAC(..RoutineName,0,"LANG")=..IOLangMode
		If ..Generated {
			Set ^rMAC(..RoutineName,0,"GENERATED")=1
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size,1)
		} Else {
			Kill ^rMAC(..RoutineName,0,"GENERATED")
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size)
		}
		Set glo="^rMAC"
		Goto jrn
	} ElseIf $$$rtnIsINT(..RoutineType) {
		Set ^ROUTINE(..RoutineName,0)=ts
		If ..IOLangMode'="" Set ^ROUTINE(..RoutineName,"LANG")=..IOLangMode
		If ..Generated {
			Set ^ROUTINE(..RoutineName,0,"GENERATED")=1
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size,1)
		} Else {
			Kill ^ROUTINE(..RoutineName,0,"GENERATED")
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size)
		}
		Set glo="^ROUTINE"
		Goto jrn
	} ElseIf $$$rtnIsINC(..RoutineType) {
		Set ^rINC(..RoutineName,0)=ts
		If ..Generated {
			Set ^rINC(..RoutineName,0,"GENERATED")=1
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size,1)
		} Else {
			Kill ^rINC(..RoutineName,0,"GENERATED")
			Set ^rINDEX(..RoutineName,..RoutineType)=$LB($$$TimeToODBC(ts),size)
		}
		Set glo="^rINC"
jrn		$$$DocJrnAdd(..RoutineType,..RoutineName,tmp)
	}
	Set ..TimeStamp=$zdt(ts,3)
	
	Set i%Mode=..#READNOTCHANGED
	Do ..Rewind()
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Set sc=tmp.OnAfterSave(..RoutineName_"."_$zconvert(..RoutineType,"U"),$this)
	. If $listget($get(^rINDEX(..RoutineName,..RoutineType)),1)'=$$$TimeToODBC(ts) Do
	. . Set Refresh=1
	. . If $get(tmp.Modified)=1 Set tmp.Modified(..RoutineName_"."_$zconvert(..RoutineType,"U"))=1
	Set i%IsModified=0
	Quit sc
}

ClassMethod DeleteStream(sid As %ObjectIdentity) As %Status
{
	#; Not implemented
	Quit $$$OK
}

Method RoutineNameSet(newvalue As %String) As %Status
{
	Set sc=..ParseRoutineName(newvalue)
	If i%Mode=..#READNOTCHANGED Set i%Mode=..#READCHANGED
	Quit sc
}

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %String
{
	Set sc=$$$OK
	#; Mode ..#READNODATA: no data 
	If (i%Mode=..#READNODATA)||(i%AtEnd=1) Set len=-1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
	If i%Mode=..#WRITE Do ..Rewind()
	
	Set out="",buffer=i%Buffer
	For {
		#; do we need to read another chunk from global
		If i%Position>($length(buffer)+1){
			If ..ReadIntoBuffer()=0 Quit
			Set buffer=i%Buffer
		}
		Set needed=len-$length(out)
		If i%Position=1,i%Position+needed>$length(buffer) {
			Set out=out_buffer
		} Else {
			Set out=out_$extract(buffer,i%Position,i%Position+needed-1)
		}
		If i%Position+needed-1>$length(buffer)&&(i%NodeNo<i%IOLines) Set out=out_$char(10)
		Set i%Position=i%Position+needed
		#; see if we're done
		If $length(out)'<len Quit
	}
	
	#;if we are at the end with no data return -1
	Set len=$S((i%AtEnd=1)&($L(out)=0):-1,1:$L(out))
	
	Quit out
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %String
{
	Set sc=$$$OK,eol=0
	#; Mode ..#READNODATA: no data 
	If (i%Mode=..#READNODATA)||(i%AtEnd=1) Set len=-1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
	If i%Mode=..#WRITE Do ..Rewind()
	
	#; If we are past the end of this global read in the next one, as each node is a 'line' then we
	#; just read in one of these and return it as the next line.
	If i%Position>($length(i%Buffer)+1),..ReadIntoBuffer()=0 Set len=-1 Quit ""
	
	Set out=$extract(i%Buffer,i%Position,i%Position+len-1),i%Position=i%Position+len
	If i%Position>($length(i%Buffer)+1) Set eol=1
	#; if we are at the end with no data return -1
	Set len=$S((i%AtEnd=1)&($L(out)=0):-1,1:$L(out))
	If eol,i%NodeNo=i%IOLines Set i%AtEnd=1,eol=0
	Quit out
}

Method Write(data As %RawString = "") As %Status
{
	Do:i%Mode'=..#WRITE ..InitWriteData()
	Set data=$translate(data,$char(13))
	#; update size
	Set i%IOSize=i%IOSize+$L(data)
	
	#; write out each terminated piece to temp file
	Set buffer=$translate(i%Buffer,$char(10)),p=1
	For  {
		Set oldp=p,p=$find(data,$char(10),oldp) If p=0 Set data=$extract(data,oldp,*) Quit
		Set i%IOLines=i%IOLines+1
		Set ^||%Routine(i%TempNode,i%IOLines)=buffer_$extract(data,oldp,p-2),buffer=""
		If p>$length(data) Set data=$char(10) Quit
	}
	Set i%Buffer=buffer_data
	Quit $$$OK
}

Method WriteLine(data As %String = "") As %Status
{
	Do:i%Mode'=..#WRITE ..InitWriteData()
	Set data=$translate(data,$char(10,13))
	
	#; flush any data in buffer as well
	Set i%IOLines=i%IOLines+1
	Set ^||%Routine(i%TempNode,i%IOLines)=$translate(i%Buffer,$char(10))_data
	Set i%Buffer=""
	Set i%IOSize=i%IOSize+$length(data)+$select(i%IOLines=1:0,1:1)
	Quit $$$OK
}

Method InitWriteData() As %Status [ Private ]
{
	If i%Mode=..#WRITE Quit
	Set i%IsModified=1
	Kill ^||%Routine(i%TempNode)
	Do ..Rewind()
	Set i%Mode=..#WRITE
	Set i%IOSize=0
	Set i%IOLines=0
	#; a write is never at the end
	Set i%AtEnd=0
}

/// Reads the next node into Buffer.
/// <p>Returns 0 if there is no more data.
Method ReadIntoBuffer() As %Boolean [ Private ]
{
	#; advance and read from Node
	Set i=$order(^||%Routine(i%TempNode,i%NodeNo),1,buffer)
	Set i%NodeNo=i,i%Position=1,i%Buffer=$get(buffer)
	#; test for no more data
	If i="" Set i%AtEnd=1 Quit 0
	Quit 1
}

Method StoreGlvnGet() As %String [ Private ]
{
	If i%RoutineVersion'="" {
		Quit $select($$$rtnIsMAC(i%RoutineType):$name(^rMACSAVE(i%RoutineName,i%RoutineVersion)),$$$rtnIsINC(i%RoutineType):$name(^rINCSAVE(i%RoutineName,i%RoutineVersion)),1:$name(^rBACKUP(i%RoutineName,i%RoutineType,i%RoutineVersion,0)))
	} ElseIf $$$rtnIsMAC(..RoutineType) {
		Quit $name(^rMAC(i%RoutineName,0))
	} ElseIf $$$rtnIsINC(..RoutineType) {
		Quit $name(^rINC(i%RoutineName,0))
	} ElseIf $$$rtnIsINT(..RoutineType) {
		Quit $name(^ROUTINE(i%RoutineName,0))
	}
}

Method MoveToEnd() As %Status
{
	#; If no data or in write mode already nothing to do
	If (i%Mode=..#READNODATA)!(i%Mode=..#WRITE) Quit $$$OK
	Set i%Mode=..#WRITE,i%Buffer="",i%Position=1
	#; a write is never at the end
	Set i%AtEnd=0
	Quit $$$OK
}

Method Clear() As %Status
{
	#; Get rid of the attributes first
	Kill i%Attributes
	Kill ^||%Routine(i%TempNode)
	If i%Mode=..#READNODATA Quit $$$OK
	If i%Mode=..#WRITE Do ..Rewind()
	Kill @(..StoreGlvn)
	If $$$rtnIsINT(..RoutineType) $$$rtnRemoveINTIdx(..RoutineName)
	If $$$rtnIsMAC(..RoutineType) $$$rtnRemoveMACIdx(..RoutineName)
	If $$$rtnIsINC(..RoutineType) $$$rtnRemoveINCIdx(..RoutineName)
	Set i%Mode=..#READNODATA
	Set i%Buffer="",i%Position=2,i%NodeNo=0,i%IOSize=0,i%IsModified=1,i%IOLines=0
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	If i%Locked Set i%Locked=1 Do ..Unlock()
	If i%TempNode'="" Kill ^||%Routine(i%TempNode)
	Quit $$$OK
}

/// The name (without extension) of the routine associated with this object.
/// <p>This is for backwards compatibility only.
Property Name As %String [ Calculated ];

Method NameGet() As %String [ CodeMode = expression ]
{
..RoutineName
}

/// Return the namespace this routine is from
Property Namespace As %String [ Calculated ];

Method NamespaceGet() As %String [ CodeMode = expression ]
{
$namespace
}

/// The language mode of this routine
Property LanguageMode As %Integer [ Calculated ];

Method LanguageModeGet() As %Integer [ CodeMode = expression ]
{
+..IOLangMode
}

Method LanguageModeSet(languagemode As %Integer) As %Status
{
	If languagemode=..IOLangMode Quit $$$OK
	Set ..IOLangMode=languagemode
	If i%Mode=..#READNOTCHANGED Do ..MoveToEnd()
	Quit $$$OK
}

/// Compile this routine. 
/// <p>For information on <var>qSpec</var>, see 
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Method Compile(qspec As %String) As %Status
{
	Set sc=$$$OK
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	Set display=$$$qualifierGetValue(qstruct,"displaylog")
	If ..CheckProtect(..RoutineName_"."_..RoutineType) Set sc=$$$ERROR($$$RoutineProtect,..Name) Do:display DisplayError^%apiOBJ(sc) Quit sc
	If ..RoutineType="INC" Quit $$$OK
	If 'i%Locked {
		Set ok=..LockRoutine(..RoutineName_"."_..RoutineType,1)
		If $$$ISERR(ok) {
			If $$$GETERRORCODE(ok)'=$$$ERRORCODE($$$ItemNotCheckedOut),$$$GETERRORCODE(ok)'=$$$ERRORCODE($$$ItemNotEditable) {
				Do:display DisplayError^%apiOBJ(ok)
				Quit ok
			} Else {
				$$$DecErrorNum
			}
		}
		Do ..LockRoutine(..RoutineName_"."_..RoutineType,0)
	}
	If i%IsModified Set sc=..Save() If $$$ISERR(sc) Do:display DisplayError^%apiOBJ(sc) Quit sc
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(sc) Quit sc
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set sc=tmp.OnBeforeCompile(..RoutineName_"."_$zconvert(..RoutineType,"U"),.qstruct)
	. If $$$ISERR(sc) Kill errcount Do DecomposeStatus^%apiOBJ(sc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	Set sc=$$CompileRoutine^%apiRTN(..RoutineName_"."_..RoutineType,.qstruct)
	If $isobject($get(%SourceControl)) Do
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnAfterCompile(..RoutineName_"."_$zconvert(..RoutineType,"U"))
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount) Set sc=$$$ADDSC(sc,rc)
	Quit sc
}

/// Get the on-disk timestamp for the routine.
Method GetCurrentTimeStamp() As %TimeStamp
{
	If ..RoutineName="" Quit ""
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Do tmp.OnBeforeTimestamp(..RoutineName_"."_$zconvert(..RoutineType,"U"))
	If $$$rtnIsMAC(..RoutineType) {
		Set ts=$G(^rMAC(..RoutineName,0))
	} ElseIf $$$rtnIsINT(..RoutineType) {
		Set ts=$G(^ROUTINE(..RoutineName,0))
	} ElseIf $$$rtnIsINC(..RoutineType) {
		Set ts=$G(^rINC(..RoutineName,0))
	}
	Quit $zdt(ts,3)
}

/// Save this routine.
Method Save(supressbackup As %Boolean = 0) As %Status [ CodeMode = expression ]
{
..SaveStream(supressbackup)
}

/// Delete the routine <var>rtnname</var>. If the <var>rtnname</var> is not fully qualified we will resolve this into
/// a fully qualified name first and then proceed with the rest of the delete. For example if you specify 'test' and there
/// is a 'test.mac' it will resolve to this, if there was only a 'test.obj' it will resolve the name to this.
/// The parameter <var>flag</var> specifies how much to delete.
/// The options are:<ul>
/// <li>0 - Delete entire routine, for a MAC routine this will delete MAC, INT, OBJ. For an INT routine
/// it will delete INT and OBJ, for a INC routine it will only delete the INC, for a BAS routine it will
/// delete the BAS and the OBJ code.</li>
/// <li>1 - Delete just the named routine, for example for a MAC routine it will only delete the MAC
/// and it will leave the INT and OBJ if present.</li>
/// <li>2 - Delete all the source code but leave any OBJ code.</li></ul>
/// This returns a %Status code to show if it worked or not. If you pass a name like 'test.mac;*' it will
/// delete all backup versions of this routine. If the routine name which is passed does not
/// exists, the method will return success.
ClassMethod Delete(rtnname As %String, flag As %String = 0, supressbackup As %Boolean = 0, nsp As %String = {$namespace}) As %Status
{
	Set version=$piece(rtnname,";",2,*),rtnname=$piece(rtnname,";")
	Set sc=..normalizeName(.rtnname,.rtn,.type) If $$$ISERR(sc) Quit sc
	Quit:(type="")||(rtn="") $$$OK
	
	#; Only delete routines we can lock
	Set ok=##class(%Routine).LockRoutine(rtnname,1,.nsp)
	If $$$ISERR(ok) Quit ok
	Do ##class(%Routine).LockRoutine(rtnname,0,.nsp)
	
	#; Handle deleting a backup version
	If version'="" {
		If version="*" {
			If $$$rtnIsMAC(type) {
				Kill ^|nsp|rMACSAVE(rtn)
			} ElseIf $$$rtnIsINC(type) {
				Kill ^|nsp|rINCSAVE(rtn)
			} ElseIf $$$rtnIsINT(type) {
				Kill ^|nsp|rBACKUP(rtn,type)
			}
		} Else {
			Set version=##class(%RoutineMgr).ConvertVersion(rtn,type,version)
			If $$$rtnIsMAC(type) {
				Kill ^|nsp|rMACSAVE(rtn,version)
			} ElseIf $$$rtnIsINC(type) {
				Kill ^|nsp|rINCSAVE(rtn,version)
			} ElseIf $$$rtnIsINT(type) {
				Kill ^|nsp|rBACKUP(rtn,type,version)
			}
		}
		Quit $$$OK
	}
	d   ; Create a stack frame so $namespace undoes itself
	. n $namespace
	. zn nsp
	. Set sc=$$Delete^%apiRTN(rtnname,flag,'supressbackup)
	Quit sc
}

/// This is an <b>instance</b> method which tests if this routine exists (that 
/// is, it has been saved to disk).
Method RoutineExists() As %Boolean [ CodeMode = expression ]
{
..Exists(..RoutineName_"."_..RoutineType)
}

/// This is a <b>class</b> method which tests if the routine <var>name</var> exists.
/// <p>If <var>name</var> consists of a routine name and an extension, 
/// such as INT, MAC, etc. then it will check for this specific routine. If it
/// just contains the routine name it will check if either MAC, INT, or BAS exists.
/// <example>
/// Write ##class(%Routine).Exists("Test.MAC")
/// Write ##class(%Routine).Exists("Test")
/// </example>
ClassMethod Exists(name As %String) As %Boolean
{
	If name="" Quit 0
	Set version=$piece(name,";",2,*),name=$piece(name,";"),origname=name
	Set sc=..normalizeName(.name,.rtn,.type) If $$$ISERR(sc) $$$DecErrorNum Quit 0
	If version'="" {
		If $$$rtnIsMAC(type) Quit ''$data(^rMACSAVE(rtn,##class(%RoutineMgr).ConvertVersion(rtn,type,version)))
		If $$$rtnIsINC(type) Quit ''$data(^rINCSAVE(rtn,##class(%RoutineMgr).ConvertVersion(rtn,type,version)))
		Quit ''($data(^rBACKUP(rtn,type,##class(%RoutineMgr).ConvertVersion(rtn,type,version))))
	}
	Quit:rtn="" 0
	Quit $data(^rINDEX(rtn,type))
}

/// Return the timestamp the routine with <var>name</var> was last updated.
ClassMethod GetDate(name As %String) As %TimeStamp
{
	Set sc=..normalizeName(.name,.rtn,.type) If $$$ISERR(sc) Quit -1
	If '$data(^rINDEX(rtn,type)) Quit -1
	Quit $listget(^rINDEX(rtn,type))
}

/// This function syntax checks INT source code.<br>
///   Source - source (INT) code; 
///         either a single line stored in a variable, or
///         an array where: array(0)=#lines, array(1-n)=source<br>
///   Errors (byref) - Returned array of errors detected by compiler<br>
///   LanguageMode - language mode, 0-10 (optional, default 0)<br>
ClassMethod CheckSyntax(ByRef Source As %String, ByRef Errors As %String, LanguageMode As %Integer = 0) As %Status
{
 s $zt="Error"
 k Errors
 s rc=$$CHECK^%R(.Source,.Err,LanguageMode)
 i rc=1 q $$$OK
 i $$FMTERR^%R(Err,.Source,.Errors)
 q $$$ERROR($$$CompileFailed)
Error Set $ZT="" 
 Set Status=$$$ERROR($$$ObjectScriptError,$ze)
 Quit Status
}

/// This query provides a list of all routines that match the pattern 
/// specified by <var>spec</var>.
/// <p><var>spec</var> may contain both * and ? as wildcards. It may also 
/// consist of more than one, comma-delimited selections.
/// For example:<br>
/// <code>&quot;*.MAC&quot;</code><br>
/// <code>&quot;A*.MAC&quot;</code><br>
/// <code>&quot;A?.MAC&quot;</code><br>
/// <code>&quot;A*.MAC,B*.MAC&quot;</code><br>
/// <var>dir</var> specifies the direction to search in, 1 is forwards
/// and -1 is backwards.<br>
/// <var>type</var> is 1 to include OBJ files
/// in the search and the default, 0 will just include INT, MAC, INC, BAS.<br>
/// <var>nsp</var> is the namespace to list from. If omitted, the query returns the routines from the current
/// namespace. <var>nsp</var> can be either an explicit or an implied namespace.
Query RoutineList(spec As %String(MAXLEN=512), dir As %Integer, type As %Integer, nsp As %String) As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=512):File Name/Ext,Size:%Integer:Routine Size,Date:%TimeStamp:Date/Time last modified,Lang:%String:Language") [ SqlProc ]
{
}

ClassMethod RoutineListExecute(ByRef QHandle As %Binary, ByRef spec As %String(MAXLEN=512) = "", Dir As %Integer = 1, Type As %Integer = 0, Nsp As %String = {$namespace}, nolang As %Boolean = 0) As %Status [ Final ]
{
	Set sc=$$$OK
	Try {
		If Type="" Set Type=0
		Set rc=$$routineListExecute^%R(.QHandle,.spec,.Type,.Dir,Nsp)
		If rc'=1 Set sc=$$$ERROR($$$GeneralError,$Piece(rc,"^",2,*))
		Set QHandle("Nsp")=Nsp,QHandle("NoLang")=nolang,QHandle("pos")=1
		Kill QHandle("rows")
	} Catch {
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	}
	Quit sc
}

ClassMethod RoutineListClose(QHandle As %Binary) As %Status
{
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod RoutineListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set sc=$$$OK
	Try {
		Set Nsp=$g(QHandle("Nsp"),$namespace)
		If QHandle("pos")'<$length($get(QHandle("rows"))) {
			If QHandle="" Set AtEnd=1,Row="" Return $$$OK
			Do fetchFiles^%R(.QHandle,1000,.Rows,,Nsp)
			Set QHandle("pos")=1,QHandle("rows")=Rows
		}
		Set Row=$list($extract(QHandle("rows"),QHandle("pos"),*),1,3),QHandle("pos")=QHandle("pos")+$length(Row)
		If Row="" Set AtEnd=1 Return $$$OK
		If QHandle("NoLang") {
			Set Row=Row_$lb("")
		} Else {
			Set Lang=$$LANG^%R($li(Row),Nsp)
			#;Now add on the language mode of the routine.
			Set Row=Row_$lb($case(Lang,0:"Cache",1:"DSM-11",2:"DTM",3:"Ipsum",4:"Cobra",5:"DSM-VMS",6:"DSM-J",7:"DTM-J",8:"MSM",9:"Basic",10:"U2/M",11:"MVBasic",:""))
		}
	} Catch {
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	}
	Quit sc
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod RoutineListFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	Set sc=$$$OK
	Try {
		Set:FetchCount=0 FetchCount=1000
		Set Nsp=$g(QHandle("Nsp"),$namespace)
		Set RowSet=""
		Do fetchFiles^%R(.QHandle,.FetchCount,.Rows,,Nsp)
		#;Now add on the Language mode of the routine
		Set pos=1
		For i=1:1:FetchCount {
			Set Item=$li($extract(Rows,pos,*),1,3),pos=pos+$length(Item)
			Set RowSet=RowSet_Item
			If QHandle("NoLang") {
				Set RowSet=RowSet_$lb("")
			} Else {
				s Lang=$$LANG^%R($li(Item))
				s RowSet=RowSet_$lb($case(Lang,0:"Cache",1:"DSM-11",2:"DTM",3:"Ipsum",4:"Cobra",5:"DSM-VMS",6:"DSM-J",7:"DTM-J",8:"MSM",9:"Basic",10:"U2/M",11:"MVBasic",:""))
			}
		}
		Set ReturnCount=FetchCount,AtEnd=(QHandle="")
	} Catch {
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	}
	Quit sc
}

/// This query provides a list of all routines that match the <var>Spec</var>
/// ordered by the <var>OrderBy</var>. The <var>Dir</var> specifies the direction to search in, 1 is
/// in assending order and -1 is in decending order.
/// <p><var>Spec</var> may contain both * and ? as wildcards. It may also 
/// consist of more than one, comma-delimited selections.
/// For example:<br>
/// <code>&quot;*.MAC&quot;</code><br>
/// <code>&quot;A*.MAC&quot;</code><br>
/// <code>&quot;A?.MAC&quot;</code><br>
/// <code>&quot;A*.MAC,B*.MAC&quot;</code><p>
/// The <var>Type</var> is 1 to include OBJ files
/// in the search and the default, 0 will just include INT, MAC, INC, BAS.<p>
/// <var>OrderBy</var> is one of:<ul>
/// <li>Date - Date/Time the file was saved (the default)</li>
/// <li>Size - Size of the file</li>
/// <li>Type - Type of the file ie. INT, MAC, INC, BAS</li></ul>
/// If you wish to return the results in name order then use the RoutineList query as this is faster
/// as it does not need to build a full list first in order to sort it correctly.<br>
/// <var>nsp</var> is the namespace to list from. If omitted, the query returns the routines from the current
/// namespace. <var>nsp</var> can be either an explicit or an implied namespace.
Query RoutinesSortByField(Spec As %String(MAXLEN=512), Dir As %Integer, Type As %Integer, OrderBy As %String, nsp As %String) As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=256):File Name/Ext,Size:%Integer:Routine Size,Date:%TimeStamp:Date/Time last modified") [ SqlProc ]
{
}

ClassMethod RoutinesSortByFieldExecute(ByRef QHandle As %Binary, ByRef Spec As %String(MAXLEN=512) = "", Dir As %Integer = 1, Type As %Integer = 0, OrderBy As %String = "Date", Nsp As %String = {$namespace}) As %Status [ Final ]
{
	Set $zt="Trap"
	If Type="" Set Type=0
	d   ; Create a stack frame so $namespace undoes itself
	. n $namespace
	. zn Nsp
	. Set sc=$$routineListExecute^%R(.QHandle,.Spec,.Type,1)
	Set QHandle("Nsp")=Nsp
	If sc'=1 Quit $$$ERROR($$$GeneralError,$Piece(%sc,"^",2,*))
	Set idx=$Increment(^||%Routine)
	Set direntry=$Select(Dir=1:-1,1:$char(255))
	While QHandle'="" {
		Set fetchCount=10000
		Kill rowSet
		d   ; Create a stack frame so $namespace undoes itself
		. n $namespace
		. zn Nsp
		. Set sc=$$fetchFiles^%R(.QHandle,.fetchCount,.rowSet)
		While $Get(rowSet)'="" {
			Set orderby=$Select(OrderBy="Type":$Piece($List(rowSet),".",$Length($List(rowSet),".")),OrderBy="Size":$List(rowSet,2),1:$List(rowSet,3))
			Set name=$List(rowSet)
			#; If this is a directory place these first when sorted
			If $Case($ZConvert($Piece(name,".",$Length(name,".")),"U"),"CSPAPP":1,"PACKAGE":1,"DIR":1,:0) {
				Set ^||%Routine(idx,direntry,name)=$List(rowSet,1,3)
			} Else {
				Set:orderby="" orderby="/"
				Set ^||%Routine(idx,orderby,$Order(^||%Routine(idx,orderby,""),-1)+1)=$List(rowSet,1,3)
			}
			Set rowSet=$List(rowSet,4,*)
		}
	}
	Kill QHandle Set QHandle=$ListBuild(idx,"",Dir,"")
	Set QHandle("Nsp")=Nsp
	Quit $$$OK
Trap
	Set $ZT="" 
	Set sc=$$$ERROR($$$ObjectScriptError,$ze) Quit sc
}

ClassMethod RoutinesSortByFieldClose(QHandle As %Binary) As %Status
{
	If $ListGet(QHandle)'="" {
		Kill ^||%Routine($List(QHandle))
	}
	Set QHandle=""
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod RoutinesSortByFieldFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..RoutinesSortByFieldFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod RoutinesSortByFieldFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	If QHandle="" Set AtEnd=1 Quit $$$OK
	Set RowSet="",number=0,exit=0
	Set idx=$List(QHandle),orderby=$List(QHandle,2),dir=$List(QHandle,3),no=$List(QHandle,4)
	Set:no="" orderby=$Order(^||%Routine(idx,orderby),dir)
	While orderby'=""&&('exit) {
		Set no=$Order(^||%Routine(idx,orderby,no),1,item)
		While no'="" {
			Set RowSet=RowSet_item,number=number+1
			If number=FetchCount||($Length(RowSet)>20000) Set exit=1 Quit
			Set no=$Order(^||%Routine(idx,orderby,no),1,item)
		}
		Set:'exit orderby=$Order(^||%Routine(idx,orderby),dir)
	}
	Set ReturnCount=number
	If orderby="" Set AtEnd=1,QHandle="" Kill ^||%Routine(idx) Quit $$$OK
	Set QHandle=$ListBuild(idx,orderby,dir,no)
	Quit $$$OK
}

Method LastModifiedGet() As %TimeStamp [ CodeMode = expression ]
{
..GetCurrentTimeStamp()
}

ClassMethod FindClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = FindExecute ]
{
	Kill qHandle
	Quit $$$OK
}

ClassMethod FindExecute(ByRef qHandle As %Binary, Namespace As %String, RoutineName As %String, FindWhat As %String = "", MatchCase As %Boolean = 1) As %Status [ Internal ]
{
	Set $zt="ERROR"
	If Namespace="" Quit $$$ERROR($$$InvalidParameter,"Namespace","")
	If FindWhat="" Quit $$$ERROR($$$InvalidParameter,"FindWhat","")
	Set:'MatchCase FindWhat=$zcvt(FindWhat,"U")
	Kill Match
	d   ; Create a stack frame so $namespace undoes itself
	. n $namespace
	. zn Namespace
	. Do ROUTINE^%R(RoutineName,.Lines,.e,"L")
	If Lines(0) {
		For i=1:1:Lines(0) {
			Set l=Lines(i) Set:'MatchCase l=$zcvt(l,"U")
			If l[FindWhat Set Match(i)=1
		}
		If $d(Match) Merge qHandle("Lines")=Lines,qHandle("Match")=Match
	}
	Set qHandle="0"
	Quit $$$OK
ERROR Set $zt="" 
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod FindFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = FindExecute ]
{
	Set Index=qHandle
	Set Index=$o(qHandle("Lines",Index),1,Line) If Index="" Set Row="",AtEnd=1 Quit $$$OK
	Set qHandle=Index,Row=$lb(Line,$d(qHandle("Match",Index))) Quit $$$OK
}

/// The query returns the routine that contains <var>FindWhat</var>, one line per row, with two columns,
/// Line and Match. Line is the line text. Match is 1 if Line contains <var>FindWhat</var>.
/// The entire routine is returned.
Query Find(Namespace As %String, RoutineName As %String, FindWhat As %String, MatchCase As %Boolean = 1) As %Query(ROWSPEC = "Line:%String:Line,Match:%Boolean:Match") [ SqlProc ]
{
}

ClassMethod CompareClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = CompareExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

ClassMethod CompareExecute(ByRef qHandle As %Binary, Nsp1 As %String, RouName1 As %String, Nsp2 As %String = "", RouName2 As %String) As %Status [ Internal ]
{
	Set $zt="ERROR"
	Set Index=$i($$$ISCQUERYTEMP)
	;
	Set rc=..RoutineCompare(Nsp1,RouName1,Nsp2,RouName2,$name($$$ISCQUERYTEMP(Index)))
	Set qHandle=Index_"^" Quit $$$OK
ERROR Set $zt="" Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod RoutineCompare(Nsp1 As %String = "", RouName1 As %String = "", Nsp2 As %String = "", RouName2 As %String = "", GloRef As %String) As %Status [ Internal ]
{
	Set rtn(1)=RouName1,rtn(2)=RouName2,return=$$$OK,nline(1)=0,nline(2)=0
	Set del1=$$del1^%Wprim,del2=$$del2^%Wprim,CR=$c(10)
	If RouName1=RouName2,Nsp1=Nsp2 Quit $$$OK
	If Nsp1="" Quit $$$ERROR($$$InvalidParameter,"Nsp1",Nsp1)
	If RouName1="" Quit $$$ERROR($$$InvalidParameter,"RouName1",RouName1)
	If Nsp2="" Quit $$$ERROR($$$InvalidParameter,"Nsp2",Nsp2)
	If RouName2="" Quit $$$ERROR($$$InvalidParameter,"RouName2",RouName2)
	Set ns(1)=Nsp1,ns(2)=Nsp2
	Set (more(1),more(2))=0
rcmore ;
	For i=1,2 {
		Set src(i)="",rtn=$$ParseRoutineName^%R(rtn(i),.TYPE),start=1
		Set TYPE(i)=TYPE
		If '$$EXIST^%R(rtn(i),ns(i)) Set return=$$$ERROR($$$RoutineDoesNotExist,ns(i)_":"_rtn(i)) Quit
		If TYPE="OBJ" {
			If $$ROUTINE^%R(rtn(i),.obj,.e,"L","","",ns(i)) Set src(i)=obj(1) Set:$d(obj(2)) src(i,0)=obj(2)
		} Else {
			If more(i) Set start=more(i)+1,more(i)=0
			Else  Set end(i)=$$LENGTH^%R(rtn(i),ns(i))
			For j=start:1:end(i) {
				Set src(i)=src(i)_$$LINE^%R(rtn_"."_TYPE,j,ns(i))_$c(10)
				If $l(src(i))>32000 Set more(i)=j Quit
			}
			Set:j=end(i) more(i)=0
		}
		Quit:return'=$$$OK
	}
	If return'=$$$OK  Quit return
	Quit:TYPE(1)'=TYPE(2) $$$ERROR($$$InvalidRtnCompare,RouName1,RouName2)
	If TYPE="OBJ" {
		If src(1)=src(2),$g(src(1,0))=$g(src(2,0)) Quit $$$OK
		Set @GloRef@(1)=$lb("+1","","+1","") Quit $$$OK
	}
	Set return=$$compare(.src)
	If more(1)!more(2) Goto rcmore
	Quit return
compare(src) Set return=$g(return)
	For i=1,2 Set nline(i)=+$g(nline(i))
	Set src(1)=src(1)_$s($e(src(1),$l(src(1)))'=CR:CR,1:"")_"--end--"
	Set src(2)=src(2)_$s($e(src(2),$l(src(2)))'=CR:CR,1:"")_"--end--"
compare1 Set a=$p(src(1),CR),b=$p(src(2),CR) Goto:a'=b compare2
	#; Return= Number of lines +1
	If a="--end--",a=src(1) Quit return ;+$g(counter)
	Set ff=12 Do nextline Goto compare1
compare2 Set a=CR_$p(src(1),CR,1,2),b=CR_$p(src(2),CR,1,2)
	Set oa=$f(src(1),b)-$l(b),ob=$f(src(2),a)-$l(a)
	Set o=$s(oa<0:ob,ob<0:oa,oa>ob:ob,1:oa)
	If o<0 {
		Set ff=12 Do log($p(src(1),CR),$p(src(2),CR)),nextline
	} Else {
		Set ff=$s(o=oa:1,1:2)
		Set p=0 For k=1:1 Set p=$f($s(ff=2:src(2),1:src(1)),CR,p) Quit:'p  Quit:p>o
		For j=1:1:k Do log($p(src(1),CR),$p(src(2),CR)),nextline
	}
	Goto compare1
nextline Set:ff[1 src(1)=$p(src(1),CR,2,*),nline(1)=nline(1)+1
	Set:ff[2 src(2)=$p(src(2),CR,2,*),nline(2)=nline(2)+1
	Quit
#; xa,xb = line text
log(xa,xb) Set:$g(ff)[1!($g(ff)[2) counter=$g(counter)+1 Set nbytes=1024
	Set string=$g(string),line=""
	Set:ff=0 $p(line,del2,1)=xa,$p(line,del2,4)=xb
	Set:ff[1 $p(line,del2,1)="+"_nline(1),$p(line,del2,2)=xa
	Set:ff[2 $p(line,del2,3)="+"_nline(2),$p(line,del2,4)=xb
	Set @GloRef@(counter)=$lb($p(line,del2),$p(line,del2,2),$p(line,del2,3),$p(line,del2,4))
	Quit
}

ClassMethod CompareFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = FindExecute ]
{
 	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

/// This query provides a list of all lines that differ between two given routines.<br>
/// <var>Nsp1</var> and <var>RouName1</var> specify the first routine.<br>
/// <var>Nsp2</var> and <var>RouName2</var> specify the second routine.<br>
/// <var>Nsp1</var> and <var>RouName2</var> can be either an explicit or an implied namespace.
Query Compare(Nsp1 As %String, RouName1 As %String, Nsp2 As %String, RouName2 As %String) As %Query(ROWSPEC = "LineNo1:%String,Line1:%String,LineNo2:%String,Line2:%String") [ SqlProc ]
{
}

Method LineTerminatorGet() As %String
{
	Quit $char(10)
}

/// Returns the major.minor version number of the ObjectScript compiler that produced the object code
/// for this routine.  Returns 0 if there is no object code for the routine.
Method GetObjectVersion() As %Numeric
{
	If $Data(^rOBJ(..RoutineName))#2=0 Set sc=$$$ERROR($$$RoutineDoesNotExist,..RoutineName_".OBJ") Quit 0
	Set header=$E(@$ZR,1,16) Quit $A(header,11)_"."_$A(header,12)
}

ClassMethod normalizeName(ByRef rtn As %String, ByRef nm As %String, ByRef type As %String, obj As %Boolean = 1) As %Status [ Private ]
{
	Set nm="",version=""
	If rtn="" Set type="MAC" Quit $$$OK
	If rtn[";" {
		Set version=$piece(rtn,";",2,*),rtn=$piece(rtn,";")
	}
	Set type=$zconvert($piece(rtn,".",*),"U")
	If type="OBJ",'obj Quit $$$ERROR($$$FileNameInvalid,rtn)
	If rtn'["."||('$$$rtnIsKnown(type)&&(type'="OBJ")) {
		For type=$$$rtnMACTypes,$$$rtnINTTypes,$$$rtnINCTypes,"OBJ" {
			If type="OBJ",'obj Continue
			If $data(^rINDEX(rtn,type)) Set nm=rtn,rtn=rtn_"."_type_$select(version="":"",1:";"_version) Quit
		}
		If nm'="" Quit $$$OK
		If rtn'["." Set type="MAC",nm=rtn,rtn=rtn_".MAC"_$select(version="":"",1:";"_version) Quit $$$OK
		Set type="" Quit $$$ERROR($$$FileNameInvalid,rtn)
	}
	Set nm=$piece(rtn,".",1,*-1),rtn=nm_"."_type_$select(version="":"",1:";"_version)
	Quit $$$OK
}

/// Return list of globals where routine and class information is stored.<br>
/// Returns Names="ROUTINE,rBACKUP,rINC,rINCSAVE,rINDEX,rMAC,rMACSAVE,rMAP,rOBJ,oddDEF"<br>
/// Here is some documentation on the format of the routine globals.<br><br>
/// ROUTINE - Native .INT COS code, generated from .MAC, or generated from classes.
/// When compiled generates .OBJ code.<br>
/// ROUTINE(Name,0)=timestamp when last saved<br>
/// ROUTINE(Name,0,0)=# lines in routine<br>
/// ROUTINE(Name,0,1...x) = Source Lines in routine<br>
/// ROUTINE(Name,0,"GENERATED")= 0/1 whether routine is generated or native<br>
/// ROUTINE(Name,0,"INC",IncludeFileName1)=Timestamp when last include file last saved<br>
/// ROUTINE(Name,0,"INC",IncludeFileName2)=Timestamp when last include file last saved<br>
/// ROUTINE(Name,0,"SIZE")=# bytes in routine<br>
/// ROUTINE(Name,0,"LANG")=language mode<br><br>
/// ROUTINE(Name,"MAC")=Timestamp of .MAC code when last saved if generated<br>
/// rBACKUP(Name,Type,version) - backup of ^ROUTINE, created by the command
/// Merge ^rBACKUP(rtn,type,nextverersion)=^ROUTINE(rtn) where type="INT/MVI/BAS"<br><br>
/// rINC - Native .INT or macro code, compiled into .MAC when included with #include directive<br>
/// rINC(Name,0)=timestamp when last saved<br>
/// rINC(Name,0,0)=# lines in include file<br>
/// rINC(Name,0,1...x) = Source Lines in include file<br>
/// rINC(Name,0,"SIZE")=# bytes in include file<br>
/// rINC("ZZ","P") - Meta data used for precompiling include files<br><br>
/// rINCSAVE - Backup of ^rINC, created by the command
/// Merge ^rINCSAVE(rtn,nextver)=^rINC(rtn,0)<br><br>
/// rINDEX - Index of .OBJ, .INT, and .MAC routines<br>
/// rINDEX(Name,"OBJ/MAC/INC")=$lb(Time compiled,Size)<br>
/// rINDEX(Name,"INT")=$lb(Time compiled,Size,Generated 0/1)<br><br>
/// rMAC - Native .MAC Macro code which when compiled generates .INT code<br>
/// rMAC(Name,0)=Timestamp when last saved<br>
/// rMAC(Name,0,0)=#lines in routine<br>
/// rMAC(Name,0,1...x) = Source Lines in routine<br>
/// rMAC(Name,0,"SIZE")=# bytes in routine<br><br>
/// rMACSAVE(Name,Type,version) - backup of ^rMAC, created by the command
/// Merge ^rMACSAVE(rtn,nextver)=^rMAC(rtn,0)<br><br>
/// rMAP - Debug map used by the debugger and for error trapping<br>
/// rMAP(Name,"INT","MAC",offsets)=$lb(debuginfo)<br>
/// rMAP(Name,"MAC","INT",offsets)=$lb(debuginfo)<br><br>
/// rOBJ - Compiled .INT code<br>
/// rOBJ(Name,"INT")=timestamp of .INT code when compiled<br>
/// rOBJ(Name,0...n)=Compiled object code<br><br>
/// oddDEF - Source code for classes<br>
/// oddDEF($zcvt(Name,"U"),....)=source code from class. Note that all of the other
/// odd* nodes are meta data describing the class, and can be recreated by compiling 
/// the class. The rINDEXCLASS and rINDEXSQL nodes also get recreated when compiling
/// the class.<br><br>
ClassMethod GetRoutineGlobals(ByRef Names As %String) As %Status
{
 s $zt="Error"
 s Names="ROUTINE,rBACKUP,rINC,rINCSAVE,rINDEX,rMAC,rMACSAVE,rMAP,rOBJ,oddDEF"
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Return the total number of .OBJ routines in a namespace <br>
/// <var>namespace</var> Specify the namespace. Default value is the current namespace
ClassMethod GetRoutineCount(namespace As %String = {$namespace}) As %Integer [ Internal ]
{
	Set:namespace="" namespace=$namespace
	Set count=0
    Set routine=""
	For {
		Set routine=$order(^|namespace|rINDEX(routine))
		Quit:routine=""
		Do:$data(^|namespace|rINDEX(routine,"OBJ"))#2=1 $increment(count)
	}
	Return count
}

/// Compile a list of routines in the current namespace.
/// Pass this a comma separated list of items, which can include wild card
/// characters e.g. 'test.mac,abc*.int' or pass in a subscripted array with the
/// routine name as the subscript. It will return an error %Status.
/// If you do not wish to use multicompile then pass in /multicompile=0
ClassMethod CompileList(rtns As %String, qspec As %String) As %Status
{
	Quit $$CompileList^%apiRTN(.rtns,.qspec)
}

/// Compile all routines in a namespace.<br>
/// This method will compile all routines in the current namespace.<br>
/// <var>Flags</var> Bit string of options to method.<br>
/// Bit 0 - Suppress syntax error display.<br>
/// Bit 1 - Suppress output to principal device.<br>
/// <var>IO</var> Already open device to send the output to. For example, "c:\a.out" <br>
/// <var>Count</var> (by ref) Number of routines compiled.<br>
/// <var>Errors</var> (by ref) Number of routines with syntax errors.<br>
/// <var>MultiCompile</var> - If true then use multiple jobs to do the compile, if not specified use the default /multicompile qualifier setting<br>
/// <var>Journal</var> - If true then journal the compile, if false disable journaling for compile, if not specified use the default /journal qualifier setting<br>
/// <var>KeepSource</var> - If true (default) then keep INT code from compiling a MAC, if false then do not save INT code<br>
ClassMethod CompileAll(Flags As %String = 0, IO As %String = {$p}, ByRef Count As %Integer, ByRef Errors As %Integer, MultiCompile As %Integer, Journal As %Integer, KeepSource As %Boolean = 1) As %Status
{
 q $$Compile^%R("*.*",Flags,IO,.Count,.Errors,.MultiCompile,.Journal,KeepSource)
}

/// Compile selected routines in a namespace.<br>
/// <var>Mask</var> Selection mask of which routines to compile. This mask is passed to 
/// %Library.Routine.RoutineList() and must be in a format it understands.<br>
/// <var>Flags</var> Bit string of options to method.<br>
/// Bit 0 - Suppress syntax error display.<br>
/// Bit 1 - Suppress output to principal device.<br>
/// <var>IO</var> Already open device to send the output to. For example, "c:\a.out" <br>
/// <var>Count</var> (by ref) Number of routines compiled.<br>
/// <var>Errors</var> (by ref) Number of routines with syntax errors.<br>
/// <var>MultiCompile</var> - If true then use multiple jobs to do the compile, if not specified use the default /multicompile qualifier setting<br>
/// <var>Journal</var> - If true then journal the compile, if false disable journaling for compile, if not specified use the default /journal qualifier setting<br>
/// <var>KeepSource</var> - If true (default) then keep INT code from compiling a MAC, if false then do not save INT code<br>
ClassMethod CompileSelected(Mask As %String = "*.*", Flags As %String = 0, IO As %String = {$p}, ByRef Count As %Integer, ByRef Errors As %Integer, MultiCompile As %Integer, Journal As %Integer, KeepSource As %Boolean = 1) As %Status
{
 q $$Compile^%R(Mask,Flags,IO,.Count,.Errors,.MultiCompile,.Journal,KeepSource)
}

/// Compile all routines in all namespace.<br>
/// This method will compile all routines in all namespaces. This will not compile
/// routines in SYSTEM defined namespaces.<br>
/// <var>Flags</var> Bit string of options to method.<br>
/// Bit 0 - Suppress syntax error display.<br>
/// Bit 1 - Suppress output to principal device.<br>
/// <var>IO</var> Already open device to send the output to. For example, "c:\a.out" <br>
/// <var>Count</var> (by ref) Number of routines compiled.<br>
/// <var>Errors</var> (by ref) Number of routines with syntax errors.<br>
/// <var>MultiCompile</var> - If true (default) then use multiple jobs to do the compile<br>
/// <var>Journal</var> - If true (default) then journal the compile, if false disable journaling for compile<br>
/// <var>KeepSource</var> - If true (default) then keep INT code from compiling a MAC, if false then do not save INT code<br>
ClassMethod CompileAllNamespaces(Flags As %String = 0, IO As %String = {$p}, ByRef Count As %Integer, ByRef Errors As %Integer, MultiCompile As %Integer = 1, Journal As %Integer = 1, KeepSource As %Boolean = 1) As %Status
{
	Quit $$CompileAllNamespaces^%R("*.*",Flags,IO,.Count,.Errors,MultiCompile,Journal,KeepSource)
}

ClassMethod %ExistsId(id As %String) As %Boolean [ CodeMode = expression ]
{
..Exists(id)
}

Method %IsModified() As %Integer
{
	Quit $select(m%Attributes||(m%RoutineName)||(m%RoutineType)||(m%RoutineVersion)||(m%Generated):1,1:$case(i%Mode,..#READNOTCHANGED:0,:1))
}

Method %ObjectModified() As %Integer
{
	Quit $select(m%Attributes||(m%RoutineName)||(m%RoutineType)||(m%RoutineVersion)||(m%Generated):1,1:$case(i%Mode,..#READNOTCHANGED:0,:1))
}

}
