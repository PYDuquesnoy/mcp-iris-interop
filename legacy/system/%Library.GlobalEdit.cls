/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syPrompt, %syGluedef)

Class %Library.GlobalEdit Extends (%Persistent, %SYSTEM.Help) [ Inheritance = right, StorageStrategy = GlobalStorage, System = 4 ]
{

Parameter DEFAULTCONCURRENCY = 0;

/// Collation of the global.
Property Collation As %Library.Collate;

/// Directory global is located in.
Property Directory As %SysPath [ ReadOnly ];

/// Block size of the database the global is in.
Property DatabaseBlockSize As %Integer(VALUELIST = ",2048,4096,8192,16384,32768,65536") [ InitialExpression = {$$$8k}, ReadOnly ];

/// Global directory entry exists.
Property Exists As Security.Datatype.BooleanYN [ ReadOnly ];

/// First data block of the global.<br>
/// Note referencing this property causes a $D(global) and I/O to occur.
Property FirstDataBlock As %Integer [ Calculated ];

/// Growth block for the global.
Property GrowthBlock As %Integer;

/// Keep global directory attributes when deleted.
Property IsKeep As Security.Datatype.BooleanYN;

/// Global contains no data.
Property IsEmpty As Security.Datatype.BooleanYN [ ReadOnly ];

/// Name of the global.
Property Name As %String;

/// Top pointer block of the global.
Property PointerBlock As %Integer;

/// Current permission on the global.
/// This is the "RW" value that the process who has this 
/// instance open has access to it.
Property Permission As Security.Datatype.Permission [ ReadOnly ];

/// Resource name of the global.
Property ResourceName As %String [ ReadOnly ];

/// System name where global resides.
Property System As %String [ ReadOnly ];

ClassMethod GetName(Directory, Prompt, Value, Obj, Min, Max, Help, Flag, Timeout) As %Integer [ Internal ]
{
 s $zt="ERROR"    
 f  {
	s Value1=$g(Value)
	s Status=##Class(%Library.Prompt).GetArray(Prompt,.Value1,$lb("%SYS.GlobalQuery:DirectoryList",Directory),.Min,.Max,.Help,.Flag,.Timeout)
 	i (Status=$$$CtrlCResponse)||(Status=$$$BackupResponse)||(Value1="") q
#; Validate global specification. 
 	i '..IsValidName(Value1) w !!,Value1_" is not a legal name, please re-enter" continue

#; If here, we have a valid directory specification, and
#; the directory exists. Lets get an object handle to it
	s Gbl=##Class(%GlobalEdit).Open(Value1,Directory,,,.Status)

	i $zb(+Flag,$$$MustExistMask,1) {
		i $$$ISERR(Status) {
			w ! d $SYSTEM.Status.DisplayError(Status) w !
			Continue
		}
		s Obj=Gbl
		s Value=Value1
		q
	}
#;If here, the global must not exist, i.e. we are going to create a new one.
	i $$$ISOK(Status) {
		w !!,"Global "_Value1_" already exists, please re-enter",!
		Continue
	}
 	k %objlasterror
 	s Gbl=##Class(%GlobalEdit).%New(Directory)
	i $d(%objlasterror) {
		w ! d $SYSTEM.Status.DisplayError(%objlasterror) w !
		Continue
	}
 	k %objlasterror
	s Gbl.Name=Value1
	i $d(%objlasterror) {
		w ! d $SYSTEM.Status.DisplayError(%objlasterror) w !
		Continue
	}
	s Obj=Gbl
	s Value=Value1
 	q
 }
 q Status
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
}

ClassMethod LoadFields(Field, Obj, New) [ Internal ]
{
#define Name 1
#define Directory 2
#define Collation 3
#define GrowthBlock 4
#define PointerBlock 5
#define ResourceName 6
#define IsKeep 7
#define Permission 8

 s Field=Obj
 s Field($$$Collation,"Caption")="Collation"
 s Field($$$Collation,"Prompt")="Collation type?"
 s Field($$$Collation,"Property")="Collation"
 i 'New s Field($$$Collation,"ReadOnly")=""

 s Field($$$Directory,"Caption")="Directory"
 s Field($$$Directory,"Property")="Directory"
 s Field($$$Directory,"ReadOnly")=""
 
 s Field($$$GrowthBlock,"Caption")="Growth block"
 s Field($$$GrowthBlock,"Prompt")="Growth block?"
 s Field($$$GrowthBlock,"Property")="GrowthBlock"

 s Field($$$Name,"Caption")="Name"
 s Field($$$Name,"Property")="Name"
 s Field($$$Name,"ReadOnly")=""
 
 s Field($$$PointerBlock,"Caption")="Pointer block"
 s Field($$$PointerBlock,"Prompt")="Pointer block?"
 s Field($$$PointerBlock,"Property")="PointerBlock"
 i 'New s Field($$$PointerBlock,"ReadOnly")=""
 
 s Field($$$IsKeep,"Caption")="Preserve attributes"
 s Field($$$IsKeep,"Prompt")="Preserve attributes on delete?"
 s Field($$$IsKeep,"Property")="IsKeep"

 s Field($$$Permission,"Caption")="Permission"
 s Field($$$Permission,"Property")="Permission"
 s Field($$$Permission,"ReadOnly")=""
 
 s Field($$$ResourceName,"Caption")="Resource Name"
 s Field($$$ResourceName,"Prompt")="Resource Name?"
 s Field($$$ResourceName,"Property")="ResourceName"
 s Field($$$ResourceName,"ReadOnly")=""
 q $$$OK
}

ClassMethod GrowthBlockPrompt(Prompt, Obj)
{
 s $zt="ERROR"
 f  {
	s Value=Obj.GrowthBlockLogicalToDisplay(Obj.GrowthBlock)
	s Status=##Class(%Library.Prompt).GetNumber(Prompt,.Value,,,,$$$TrapCtrlCMask)
 	i (Status=$$$CtrlCResponse)||(Status=$$$BackupResponse) q
 	k %objlasterror
	s Obj.GrowthBlock=Obj.GrowthBlockDisplayToLogical(Value)
	i $d(%objlasterror) w ! d $SYSTEM.Status.DisplayError(%objlasterror) w ! Continue
	q
 }
 q Status
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
}

ClassMethod PointerBlockPrompt(Prompt, Obj)
{
 s $zt="ERROR"
 f  {
	s Value=Obj.PointerBlockLogicalToDisplay(Obj.PointerBlock)
	s Status=##Class(%Library.Prompt).GetNumber(Prompt,.Value,,,,$$$TrapCtrlCMask)
 	i (Status=$$$CtrlCResponse)||(Status=$$$BackupResponse) q
 	k %objlasterror
	s Obj.PointerBlock=Obj.PointerBlockDisplayToLogical(Value)
	i $d(%objlasterror) w ! d $SYSTEM.Status.DisplayError(%objlasterror) w ! Continue
	q
 }
 q Status
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
}

ClassMethod CollationPrompt(Prompt, Obj)
{
 s $zt="ERROR"    
 f  {
	s Value=Obj.CollationLogicalToDisplay(Obj.Collation)
	s Status=##Class(%Library.Prompt).GetArray(Prompt,.Value,$lb("%Library.Collate:CollationList"),,,,$$$TrapCtrlCMask+$$$MatchArrayMask+$$$InitialDisplayMask)
 	i (Status=$$$CtrlCResponse)||(Status=$$$BackupResponse) q
 	k %objlasterror
	s Obj.Collation=Obj.CollationDisplayToLogical(Value)
	i $d(%objlasterror) w ! d $SYSTEM.Status.DisplayError(%objlasterror) w ! Continue
	q
 }
 q Status
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
}

ClassMethod IsKeepPrompt(Prompt, Obj)
{
 s $zt="ERROR"
 f  {
	s Value=Obj.IsKeep
	s Status=##Class(%Library.Prompt).GetYesNo(Prompt,.Value,,$$$TrapCtrlCMask)
 	i (Status=$$$CtrlCResponse)||(Status=$$$BackupResponse) q
 	k %objlasterror
	s Obj.IsKeep=Value
	i $d(%objlasterror) w ! d $SYSTEM.Status.DisplayError(%objlasterror) w ! Continue
	q
 }
 q Status
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
}

/// Return the space used, and the space allocated, in a global.
/// including big string blocks
/// 'Allocated' - total size, in MB, of blocks allocated for the global.<br>
/// 'Used' - total used data, in MB, for the global.<br>
/// 'fast' - 2 : returns stochastic estimates for both 'Allocated' and 'Used' (fastest option for large globals) <br>
/// 1 : only returns exact 'Allocated' value (avoids reads of data blocks) <br>
/// 0 : returns exact values for both 'Allocated' and 'Used'.
Method GetSize(ByRef Allocated As %Integer, ByRef Used As %Integer, fast As %Integer = 0) As %Integer [ Internal ]
{
 s $zt="GetSizeE"
 o 63:"^^"_i%Directory 
 s blk=i%PointerBlock
 s (Bytes,Count)=0
 s blksiz=i%DatabaseBlockSize
 s big='(blksiz=$$$2k)
 i blk {
	 if fast=2 {
 		 s rc=$$EstimatedSize^%GSIZE(i%Directory,i%Name,.Results)
		 s Count=Results("blocks"),Bytes=Results("bytes")
	 }
	 elseif fast=1 {
		 s rc=$$INTbrief^%GSIZE(blk,big)
		 s Count=+rc
	 } else {
		 f  q:'blk  v blk s type=$case(i%DatabaseBlockSize,$$$2k:$$$type2k,:$$$type) q:(type=8!(type=12))  s blk=$v(2,-5)
		 s rc=$$INTdetail^%GSIZE(blk,big,blksiz)
		 s Count=$p(rc,",",2),Bytes=+rc
	 }
	 /* We don't need to close 63 here because it is closed in %GSIZE. */
 }
 s Allocated=Count*i%DatabaseBlockSize/$$$megabyte,Allocated=##Class(%Library.Utility).FormatMB(Allocated) 
 i (fast'=1) s Used=Bytes/$$$megabyte,Used=##Class(%Library.Utility).FormatMB(Used)
 q $$$OK
GetSizeE s $zt=""
 c 63
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Validate the passed name is legal for a global name.
ClassMethod IsValidName(Name As %String) As %Boolean [ CodeMode = expression, Internal ]
{
$zname(Name,3)
}

ClassMethod InvalidateGlobalVector(Name As %String = "", Directory As %String = "") As %Status [ Internal ]
{
 i Name="" {
	i Directory="" {
		  d $zu(154) 
		  q $$$OK
	}
	q $$$ERROR($$$NotALegalName,"")	
 }
 i Directory'="" s Directory=##Class(%Library.File).NormalizeDirectory(Directory) 
 i $e(Name)="^" s Name=$e(Name,2,$l(Name))
 i $D(@("^|""^^"_Directory_"""|"_Name)) 
 Do $Zutil(154)
 q $$$OK
}

/// Open an instance of a global.
ClassMethod Open(Name As %String, Directory As %String = {$zu(12,"")}, System As %String = "", concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle
{
	Set return = ..%OpenId($lb(Name,Directory,System),.concurrency,.sc)
	q return
}

Method %LoadData(id As %String) As %Status [ Internal, Private ]
{
 s $zt="%LoadDataE"
 s Name=$li(id,1) s:$e(Name)="^" Name=$e(Name,2,$l(Name))
 i '..IsValidName(Name) q $$$ERROR($$$NotALegalName,i%Name)
 s Directory=$li(id,2) s:$e(Directory,1,2)="^^" Directory=$e(Directory,3,$l(Directory))
 s System=$li(id,3)
 i System'="" g Remote
 s x=$zu(49,Directory)
 If x<-3 Quit $$$ERROR($$$DatabaseNotAvailable)
 i x=-3 q $$$ERROR($$$DatabaseNameInvalid)
 i x=-2 q $$$ERROR($$$DatabaseDoesNotExist,Directory)
 i (+x=-1) || (+x=$$$SFNUNDEF) Quit $$$ERROR($$$DatabaseNotAvailable)
#;SML669+
 s rc=$zu(167,6,7,Directory,Name)
 if +rc=-1 q $$$ERROR($$$NotALegalName,Name)
 if +rc=-2 q $$$ERROR($$$GlobalNotFound,Name)
 if +rc=-3 q $$$ERROR($$$DatabaseNotAvailable)
 ; rc is Keep^Collation,Growth^Pointer
 s i%DatabaseBlockSize=+$p(x,",",$$$blksizpiece) ;block size
 s i%ResourceName=$$$getresource(x)
 s i%Permission=$System.Security.Users.ResourcePermissionGet(i%ResourceName)
 s i%Name=Name
 s i%Directory=Directory
 s i%System=""
 s i%PointerBlock=$p(rc,"^",4)
 s i%GrowthBlock=$p(rc,"^",3)
 s i%Collation=$p(rc,"^",2)
 s i%IsKeep=$p(rc,"^",1)
 s i%IsEmpty=$case(i%PointerBlock,0:1,:0)
 s i%Exists=1
 q $$$OK
#;SML669-
Remote s $zt=""
 Quit $$$ERROR($$$UnexpectedError,"<UNSUPPORTED>")
%LoadDataE s $zt=""
 c 63
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 s $zt="%SaveDataE"
 i i%System'="" g Remote
 s x=$zu(49,i%Directory)
 If x<-3 Quit $$$ERROR($$$DatabaseNotAvailable)
 i x=-3 q $$$ERROR($$$DatabaseNameInvalid)
 i x=-2 q $$$ERROR($$$DatabaseDoesNotExist,i%Directory)
 #;SML1323 ; Allow never mounted DB.
 i (+x=-1) Quit $$$ERROR($$$DatabaseNotAvailable)
 i 'i%Exists {
	i '..IsValidName(i%Name) q $$$ERROR($$$NotALegalName,i%Name)
	Set rc=$zu(178,"^^"_i%Directory,i%Name,i%Collation,-1,0,i%IsKeep,i%PointerBlock,i%GrowthBlock)
	i rc=-2 q $$$ERROR($$$GlobalIsRemote,i%Name)
	i rc=-1 q $$$ERROR($$$GlobalExists,i%Name)
	i rc'=1 q $$$ERROR($$$CannotCreateGlobal,i%Name)
 }
 s DirectoryBlock=+$p(x,",",$$$glodirpiece) ;glodir
 s DatabaseBlockSize=+$p(x,",",$$$blksizpiece) ;block size
 i i%Exists {
#;SML669+
#;Get the global info in directory block to compare with data in the class.
#;if no change we don't need to update the directory block. 
    s rc=$zu(167,6,7,i%Directory,i%Name)
    if +rc=-1 q $$$ERROR($$$NotALegalName,i%Name)
    if +rc=-2 q $$$ERROR($$$GlobalNotFound,i%Name)
    if +rc=-3 q $$$ERROR($$$DatabaseNotAvailable)
    if ((i%GrowthBlock'=$p(rc,"^",3))||(i%IsKeep'=$p(rc,"^",1))) {
        #; Update the directory block, only modify Keep and Growth.
        #; Bit 8 below means "don't remove entry if Keep=0 and global is empty"
        s rc=$zu(167,6,7+8,i%Directory,i%Name,i%IsKeep,$p(rc,"^",2),i%GrowthBlock,$p(rc,"^",4))
        if +rc=-1 q $$$ERROR($$$NotALegalName,i%Name)
        if +rc=-2 q $$$ERROR($$$GlobalNotFound,i%Name)
        if +rc=-3 q $$$ERROR($$$DatabaseNotAvailable)
        if +rc=-4 q $$$ERROR($$$BadParameter)
        d ..InvalidateGlobalVector(i%Name,i%Directory)
    }
#;SML669-
 }
 s Status=..%LoadData($lb(i%Name,i%Directory,i%System))
 i $$$ISERR(Status) q Status
 q $$$OK
Remote
 Quit $$$ERROR($$$UnexpectedError,"<UNSUPPORTED>")
%SaveDataE s $zt=""
 c 63
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

/// Compact a global.
/// <br>
/// PercentFull - How full each data page should be, 50-100<br>
/// MbProcessed - How many MB of the global was processed<br>
/// MbCompressed - How many MB was it compressed to<br>
/// MbToCompress - How many MB of the global to compress in this call (0=ALL)<br>
/// LastGlobalReference - Last reference, "" = completed<br><br>
/// Typical useage is as follows, which compacts the data pages
/// to 80%full, and returns the amount of data processed, and the size it was compacted to:<br><br>
/// s x=##Class(%GlobalEdit).Open("X",dbdirectory)<br>
/// s t=x.Compact(80,.CurrSize,.NewSize)<br><br>
/// Note that this function can be called repeatedly for the same global so that
/// it can be done in chunks by using the last two parameters. The following example
/// does 10MB chunks of the global at a time and accumulates and displays a status:<br><br>
/// s x=##Class(%GlobalEdit).Open("X",dbdirectory)<br>
/// s TotalCurrSize=0,TotalNewSize=0<br>
/// do {<br>
/// s t=x.Compact(80,.CurrSize,.NewSize,10,.LastReference)<br>
/// s TotalCurrSize=TotalCurrSize+CurrSize<br>
/// s TotalNewSize=TotalNewSize+NewSize<br>
/// w !,"Global "_x.Name_" processed="_TotalCurrSize_", compacted to="_TotalNewSize<br>
/// } while LastReference'=""<br>
Method Compact(PercentFull As %Integer = 90, ByRef MbProcessed As %Float, ByRef MbCompressed As %Float, MbToCompress As %Integer = 0, ByRef LastGlobalReference As %String = "") As %Status
{
#;The number of MB compacted in each $zu(98) call
#define MBPerZU98Call 32
 s $ZT="ERROR"
#; Initialize return values
 s MbProcessed=0
 s MbCompressed=0
#;Internal counters
 s BlocksProcessed=0
 s BlocksCompressed=0
#;Get the block size of the database, and calculate how many of the blocks
#;are in one MB
#;JO2541+
 s info=$ZU(49,i%Directory)
 #;These are errors generated by (SYS.Database).%LoadData(). We can't
 #; use SYS.Database here because this is a %Library class which can
 #; be run from outside of %SYS so it doesn't have access to SYS.Database.
 I +info<-3 Quit $$$ERROR($$$DatabaseNotAvailable)
 I +info=-3 q $$$ERROR($$$DatabaseNameInvalid)
 I +info=-2 q $$$ERROR($$$DatabaseDoesNotExist,i%Directory)
 #;SML1729 ; If this is read-only because it is a mirrored db and we're not the primary, then let the operation proceed 
 I $$$mirrordbnowrite(info)||$$$readonlyattrib(info)||($$$readonlystatus(info)&&($SYSTEM.Mirror.IsPrimary()||'$$$mirrored(info))) Quit $$$ERROR($$$ReadOnlyFileSystem)
 s BlockSize=+$p(info,",",$$$blksizpiece)
 s BlocksPerMb=$case(BlockSize,2048:512,4096:256,8192:128,16384:64,32768:32,:16)
#;JO2541-
#;If we passed in how much of the global we want to compress in MB, calculate
#;how many blocks that is
 s BlocksToCompress=$s(MbToCompress<0:0,1:MbToCompress\1)
 i BlocksToCompress'=0 s BlocksToCompress=BlocksPerMb*BlocksToCompress
 s PercentFull=$s(PercentFull<50:50,PercentFull>100:100,1:PercentFull\1)
#;While compacting the database, we want the number of lines/global references
#;to move, and we want to be able to respond to CTRL/C, resjob, etc. So we will
#;continuously call $zu(98) compacting only a "small" amount of data for each call.
 s BlocksPerRound=BlocksPerMb*$$$MBPerZU98Call
#;Now get the starting global reference where we will start compacting. It is either
#;the name of the global object we have open, or an entire global reference, returned
#;in the LastGlobalReference variable from a prior call to this method on the same global
#;if we are doing chunks of this global at a time. If we are calling this repeatedly
#;for the same global (i.e. doing it in chunks) make sure that the LastGlobalReference
#;passed in is the same name as the global object we have open.
#;Tack on an implied namespace if necessary
 s NameSpace="^|"""_"^^"_i%Directory_"""|"
 if (LastGlobalReference'=""),($e($p(LastGlobalReference,"|",3),1,$l(i%Name))=i%Name) {
	s GRef=LastGlobalReference
 } else {
	s GRef=NameSpace_i%Name
 }
 s LastGlobalReference=""
#;Form a lock reference. We only allow one process access to a single global at a time.
#;JO2427+
#;Use ^%GCOMPACT(<dir>,<globnam>) so that we can let gcompact run on
#;globals in mirrored databses on the mirror backup where we can't take out
#;locks in the database because we're not the primary
 s LockRef="^%GCOMPACT("""_i%Directory_""","""_i%Name_""")"
#;JO2427-
#;$zu(98) will compact starting at the current reference in the global vector.
 i $d(@GRef) {
	#;JO2542+
	l +@LockRef:5 
	i '$t {
		s owner=^$LOCK(LockRef,"OWNER")
		if owner="" {
			; Try parent lock, maybe its a truncate/defrag/return space
			s owner=^$LOCK($Name(^%GCOMPACT(i%Directory)),"OWNER")
		}
		if owner="" {
			; Not sure who owns the lock, use a generic message
			q $$$ERROR($$$UnexpectedError,"Lock not granted")
		} else {
			quit $$$ERROR($$$MaintOperationInProgress,owner)
		}
	}
	#;JO2542-
	s BatchMode=$zu(68,25,1)
	s Audit=1
	f  {
#; If I didn't pass in the number of blocks to compress, then we just do the max for
#; each $zu(98) call. Otherwise, do the min(BlocksPerRound,BlocksToCompress)
 		i BlocksToCompress=0 {
 			s Status=$zu(98,PercentFull,BlocksPerRound,Audit)
 		} else {
	 		s Status=$zu(98,PercentFull,$Case(BlocksPerRound>BlocksToCompress,0:BlocksPerRound,1:BlocksToCompress),Audit)
 		}
 		s Audit=0 ; only audit the first call
#;SML790  should get all rest pieces of ":" for return in case ":" is in the subscript.
 		s Code=$p(Status,":",2,$l(Status,":"))
  		i +Status'=1 q
 		s BlocksProcessed=BlocksProcessed+$p(Code,",",1)
 		s BlocksCompressed=BlocksCompressed+$p(Code,",",2)
 		s MbProcessed=##Class(%Library.Utility).FormatMB(BlocksProcessed/BlocksPerMb)
		s MbCompressed=##Class(%Library.Utility).FormatMB(BlocksCompressed/BlocksPerMb)
 		s LastGlobalReference=$p(Code,",",3,*)
#;If the last reference is "", then we are done!
		i LastGlobalReference="" q
#;Carefull here, the last reference may not contain the namespace which we need for
#;the correct $D(ref)
		i $e(LastGlobalReference,1,2)'="^|" s LastGlobalReference=NameSpace_$e(LastGlobalReference,2,*)
		i BlocksToCompress'=0 {
			s BlocksToCompress=BlocksToCompress-BlocksPerRound
			i BlocksToCompress<=0 q
		}
		i $d(@LastGlobalReference)
 	}	
	d $zu(68,25,BatchMode)
	l -@LockRef
 	i +Status'=1 {
		if (Code=1) {
			s msg="GCOMPACT detected that there were insufficient free global"
			s msg=msg_$C(13,10)_" buffers to start compacting a bottom pointer block."
			s msg=msg_$C(13,10)_" Try again when the system is not so busy or increase the"
			s msg=msg_$C(13,10)_" size of the global buffer pool."
 		} 
 		if (Code=2) {
	 		s msg="GCOMPACT detected that a write daemon panic occured while it"
	 		s msg=msg_$C(13,10)_" was running. Try again when the system is not so busy."
 		} 
 		if '((Code=1)||(Code=2)) {
	 		s msg="Unknown error code ("_Code_") returned from $ZU(98)."
	 		s msg=msg_$C(13,10)_"GCOMPACT aborted."
 		}
	 	q $$$ERROR($$$UnexpectedError,msg)
 	}
 }
 q $$$OK
ERROR s $ZT=""
 i $d(LockRef) l -@LockRef
 i $d(BatchMode) d $zu(68,25,BatchMode)
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

/// Compact a global.<br>
/// See the method Compact for details on parameters.
ClassMethod CompactGlobal(Name As %String, Directory As %String = {$zu(12,"")}, PercentFull As %Integer = 90, ByRef MbProcessed As %Integer, ByRef MbCompressed As %Integer, MbToCompress As %Integer = 0, ByRef LastGlobalReference As %String = "") As %Status
{
 s $zt="ERROR"
 s Gbl=##Class(%GlobalEdit).Open(Name,Directory,,,.Status)
 i '$$$ISOK(Status) q Status
 q Gbl.Compact(PercentFull,.MbProcessed,.MbCompressed,MbToCompress,.LastGlobalReference)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
 s $zt="%OnNewE"
 s Directory=$g(initvalue)
 i Directory="" {
	 s Directory=$zu(12,"")
 } else {
	 s Directory=##Class(%Library.File).NormalizeDirectory(Directory)
 }
 s x=$zu(49,Directory)
 If x<-3 Quit $$$ERROR($$$DatabaseNotAvailable)
 i x=-3 q $$$ERROR($$$DatabaseNameInvalid)
 i x=-2 q $$$ERROR($$$DatabaseDoesNotExist,Directory)
 #;SML1323 ; Allow never mounted DB.
 i (+x=-1) Quit $$$ERROR($$$DatabaseNotAvailable)
 s i%Collation=+$p(x,",",$$$colpiece) ;col
 s i%Directory=Directory
 s i%Exists=0
 s i%GrowthBlock=+$p(x,",",$$$glogrpiece) ;ggrow
 s i%IsKeep=$zb(+$p(x,",",17),$zu(40,8,24),1)>0
 s i%IsEmpty=1
 s i%PointerBlock=+$p(x,",",$$$gloptrpiece) ;gptr
 s i%Permission=$System.Security.Users.ResourcePermissionGet($$$getresource(x))
 s i%ResourceName=$$$getresource(x)
 s i%System=""
 q $$$OK
%OnNewE s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

/// This checks the integrity of a global.  The return value contains information about the global 
Method CheckIntegrity(Silent As %Boolean) As %Status
{
 s $zt="CheckE"
 s rc=$$CheckGlobalIntegrity^%SYS.DATABASE(i%Directory,i%Name,$$$errmaxperglobal,.glototblks,.glopntblks,.glototbytes,.glopntbytes,.globigblks,.globigbytes,.globigstrings,.datasize)
 Quit rc
CheckE
 s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

/// This checks the integrity of a single global.  The return value contains information about the global 
ClassMethod CheckGlobalIntegrity(Directory As %String = "", Name As %String, StopAfterAnyError As %Boolean) As %Status [ PublicList = errorreturn ]
{
 Set $zt="CheckGloE"
 New errorreturn
 Quit $$CheckGlobalIntegrity^%SYS.DATABASE(Directory,Name,$s($g(StopAfterAnyError):1,1:$$$errmaxperglobal))
CheckGloE
 Set $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

Method CollationSet(Arg As %String) As %Status
{
 Set col=-1
 If Arg?1.3N {
	Set col=+Arg
	Do GetNLSCollations^%SYS.Access(.array,1,0,0)
	If '$D(array(col)) Set col=-1
 } ElseIf Arg?1.A1N {
	Do GetNLSCollations^%SYS.Access(.array,1,0,1)
	If $D(array(Arg),status) Set col=+$LI(status,3)
 }
 If col<0 Quit $$$ERROR($$$BadParameter)
 If i%Exists Quit $$$ERROR($$$CannotModifyProperty)
 Set i%Collation=col
 Quit $$$OK
}

/// Create a global with specified characteristics. Parameter Namespace can be a namespace or a directory.  If it is a namespace global mapping rules will apply.
ClassMethod Create(Namespace As %String = "", Name As %String, Collation As %String, GrowthBlock As %Integer, PointerBlock As %Integer, Keep As %Boolean, JournalState As %Integer, ByRef Exists As %Boolean) As %Status
{
 Set $Ztrap="errCreate"
 If Namespace="" Set Namespace=$zu(12,"")
 If $Extract(Namespace,1,2)="^^" {
    Set dir=$Extract(Namespace,3,$Length(Namespace)),Namespace=dir
 } Else { 
   Set $Ztrap="errNs" 
   Set index=$zu(90,3,1,$zcvt(Namespace,"U"))
   If index s dir=$p($$getdest^%SYS.GXLINF1($zcvt(Namespace,"U"),Name),"^",2)
 }
afterNs If $Get(dir)="" Set dir=Namespace
#;Save view buffer
 Set blksiz=$$$getblksiz($$$dirinfo(dir))
 Set (Exists,noviewbuf)=0
 Set $Ztrap="errView"
 Set viewbuf=$View(0,0,-blksiz)
afterView
 Set glob=##class(%GlobalEdit).Open(Name,dir,,,.rc)
 If $$$ISERR(rc) {
    Set glob=##class(%GlobalEdit).%New(dir)
    If glob="" Quit %objlasterror
    Set glob.Name=Name
    #; Collation can be set only for a new global
    If $Data(Collation) {
	    Kill %objlasterror
	    Set glob.Collation=Collation
	    If $D(%objlasterror) Quit %objlasterror
    }
 } Else { Set Exists=1 }
 If $Data(Keep) Set glob.IsKeep=Keep
 If $Get(PointerBlock) Set glob.PointerBlock=PointerBlock
 If $Get(GrowthBlock) Set glob.GrowthBlock=GrowthBlock
 Set rc=glob.%Save() 
 If 'noviewbuf Open 63:"^^"_dir View 0:0:-blksiz:viewbuf
 Quit rc
errNs
 Set $zt="errCreate",$ze="",$ec=""
 Goto afterNs
errView
 Set $zt="errCreate",$ze="",$ec=""
 Set noviewbuf=1 Goto afterView
errCreate
 Set $Ztrap="" Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

Method FirstDataBlockGet() As %Integer
{
 Quit $s($d(@("^|"_"""^^"_i%Directory_"""|"_i%Name)):+$lg($zu(208),24),1:0) ;SJ2958
}

/// Delete a directory entry for a global if the global does not exist.<br>
/// This should be called with Switch 10 set if the global is possibly being accessed by users.<br>
/// <br>
/// Parameters:
/// <br>
/// Directory - Directory where the global lives.<br>
/// Global - Name of the global to delete the directory entry for.<br>
/// Note: You must have write access to the database to delete the directory entry.<br>
ClassMethod DeleteDirectoryEntry(Directory, Global) As %Status
{
#;Change to the implied namespace and see if the global exists.
#;If not, then clear the keep bit and kill the global. This needs
#;to be called while switch 10 is set so no Set to the global happens
#;between the $D and the Kill.
 s Status=$$$OK
 Try {
 	#;SML1968+
 	i '$d(@("^|""^^"_Directory_"""|"_Global)) {
 		i $zu(167,6,1,Directory,Global,0)
 		k @("^|""^^"_Directory_"""|"_Global)
 	}
 } catch {
	#;SML1968-
 	s Status=$$$ERROR($$$ObjectScriptError,$ze)
 }
 q Status
}

/// Compare the same global in two different databases.<br>
/// <pre>
/// Parameters: 
/// SrcDirectory - Directory where the source nodes are located.
/// DstDirectory - Directory where the destination nodes are located.
/// StartingNode - Node where the compare is started.
/// EndingNode - Node where the compare finishes. "" - (Default) Compare all nodes until end of global.
/// MaxDifferences - Maximum number of differences to return. 0 - (Default) Return all differences.
/// MaxToCompare - 2 Piece comma delimited string as follows:
/// 
///   If Flags Bit 3 - Off:"MaxMBToProcess,AverageNodeSize"
///     If MaxMBToProcess is 0, then the method will process the entire range.
///     If MaxMBToProcess is > 0, then the method will return after that number of MB has been processed.
///     If AverageNodeSize is 0, then the MB processed is calculated by adding the length of each node and its data value.
///     If AverageNodeSize is > 0, then the MB processed is calculated by multiplying the number of nodes processed by
///     the AverageNodeSize. This is more accurate.
/// 
///   If Flags Bit 3 - On: "MaxNodesToProcess,AverageNodeSize"
///     If MaxNodesToProcess is 0, then the method will process the entire range.
///     If MaxNodesToProcess is > 0, then the method will return after that number of nodes has been processed.
///     If AverageNodeSize is 0, then the MB processed is calculated by adding the length of each node and its data value.
///     If AverageNodeSize is is > 0, then the MB processed is calculated by multiplying the number of nodes processed by
///     the AverageNodeSize. This is more accurate.
///   
/// Flags - Bit string of compare options.
///   Bit 0 - Return Data values
///   Bit 1 - Format Node names using %Library.Utility:FormatReference()
///   Bit 2 - Format Data values using %Library.Utility:FormatString()
///   Bit 3 - 0 - MaxMBToProcess is passed in MaxToCompare variable
///           1 - MaxNodesToProcess is passed in MaxToCompare variable
/// 
/// Return Values:
/// Status - Return Status of the method. 
///   1) If MaxMBToProcess is > 0, and we have reached the max, the error $$$ERROR($$$MaxMBToCompare) is returned.
///   2) If MaxNodesToProcess is > 0, and we have reached the max, the error $$$ERROR($$$MaxNodesToCompare) is returned.
///   3) If MaxDifferences > 0 and we have reached the max, the error $$$ERROR($$$MaxDifferencesReached) is returned.
///   4) If we have exceeded process storage space ($s) with a large amount of differences, the error $$$ERROR($$$MaxStorageReached) is returned.
///   In these four cases any differences found are returned in the Differences() array. The caller may then call this method again using the returned LastNodeProcessed as
///   the StartingNode to compare the next set of nodes.
///   5) $$$ERROR($$$DifferencesFound) - The compare completed successfuly, and some differences were found. Results are in the Differences() array.
///   6) $$$OK - The compare has completed successfully. No differences were found.
/// 
/// Differences - Number of differences
/// Differences(0) - $lb(LastNodeProcessed,BlocksChecked,NodesChecked,MBChecked,BlockSize)
///   LastNodeProcessed - Last node processed in the compare. May be used as the StartingNode if the method is called again. Returns "" if at end of range.
///   BlocksChecked - Number of Blocks in the SrcDirectory processed. More accurate if AverageNodeSize is passed.
///   NodesChecked - Number of Nodes in the SrcDirectory processed.
///   MBChecked - Number of MB in the SrcDirectory processed. More accurate if AverageNodeSize is passed.
///   BlockSize - Blocksize of the SrcDirectory
///   
/// Differences(1..x,1) - Global name. Always returned, may be formatted if specified in the Flags parameter.
/// Differences(1..x,2) - Reason for difference
///   1 - Value is Different
///   2 - Node is in source but not destination
///   3 - Node is in destination but not source
/// Differences(1..x,3) - Source data value or "" if source does not exist. Only returned if specified in the Flags parameter. May be formatted if specified in the Flags parameter
/// Differences(1..x,4) - Destination data value or "" if destination does not exist. Only returned if specified in the Flags parameter. May be formatted if specified in the Flags parameter]]></Description>
/// 
/// Notes:
/// AverageNodeSize should be passed for most accurate values for BlocksChecked and MBChecked values in the Differences(0) return value.
/// AverageNodeSize is returned by the method %Library.GetGlobalSizeBySubscript(). See this method for how this value is calculated.
/// </pre>
ClassMethod CompareRange(SrcDirectory As %String, DstDirectory As %String, StartingNode As %String, EndingNode As %String, MaxDifferences As %Integer = 0, MaxToCompare As %String = "0,0", Flags As %Integer = 7, ByRef Differences As %String) As %Status
{
#define EncodeKey(%Node,%CollationTable,%Key) s %Key=$zu(70,6,%Node,%CollationTable)
#define ValueDifferent 1
#define NodeDoesNotExistDst 2
#define NodeDoesNotExistSrc 3
#;
#define ReturnDataValuesBit	1
#define FormatNodeNamesBit	2
#define FormatDataValuesBit	4
#define MaxNodesToCompareBit 8

#define AreWePastEnd $$$EncodeKey($e(SrcNode,2,*),CollationTable,SrcKey) $$$EncodeKey($e(DstNode,2,*),CollationTable,DstKey) i ((SrcKey]EndKey)||(SrcKey=EndKey))&&((DstKey]EndKey)||(DstKey=EndKey)) { ztrap "EXIT" } i ((SrcKey]EndKey)||(SrcKey=EndKey)){ s SrcNode="" ZTRAP "NODE" } i ((DstKey]EndKey)||(DstKey=EndKey)){ s DstNode="" ZTRAP "NODE" }

#;This macro checks to see if the source and destination nodes are =.
#;It is assumed that we have already checked to make sure That both nodes are not past the end range ($$$AreWePastEndRange)
#;If the nodes are different, then generate a <ZNODE> error.
#;If the data values are different, then log it.
#;If we have hit the maximum number of differences, then generate a <ZMAXD> error. 
#define CheckDiffs																					##Continue				
#;Generate a <ZNODE> error if the nodes don't match. 												##Continue
 i SrcNode'=DstNode ZTRAP "NODE"																	##Continue
#;If here, the node exists in both places, but the data is different								##Continue
#;The following line handles the case where the previous compare had the nodes the same,			##Continue 
#;but the data was different, and it is the last nodes to compare. The next $query returns both		##Continue
#;null, but the data is different. It avoids putting a null node in the diff array.					##Continue
 i (SrcNode=""),(DstNode="") d $$$APPERROR($$$ERSYNTX)												##Continue
 s Differences($i(Differences),1)=$case(FormatNodeNames,0:SrcNode,:$$FormatName^%qcr(SrcNode,1))	##Continue
 s Differences(Differences,2)=$$$ValueDifferent														##Continue
 i ReturnDataValues {																				##Continue
	s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))		##Continue
	s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))		##Continue
 }																									##Continue
#;Generate a <ZMAXD> error if we hit the maximum number of differences.								##Continue
 i $g(Differences,0)>=MaxDiffs ZTRAP "MAXD"


 s $zt="Error"
 s Status=$$$OK
 k Differences
 s Differences=0
 s Differences(0)=$lb("",0,0,0,"")
 s NodesChecked=1
#;Save some room (2mb) so if we get a <STORE> error we can kill this,
#;return a $$$ERROR($$$MaxStorageReached) error, and then the caller can try to continue. 
 s SaveSpace=$j("SaveSpace",2*1024*1024)
 s ReturnDataValues=$zb(Flags,$$$ReturnDataValuesBit,1)
 s FormatNodeNames=$zb(Flags,$$$FormatNodeNamesBit,1)
 s FormatDataValues=$zb(Flags,$$$FormatDataValuesBit,1)
 s MaxNodesToCompare=$zb(Flags,$$$MaxNodesToCompareBit,1)
#;Move the nodes into work globals
 s StartNode=StartingNode
 s EndNode=$g(EndingNode)
 i EndNode="" s EndNode=StartNode
 i $e(StartNode)="^" s StartNode=$e(StartNode,2,*)
 i $e(EndNode)="^" s EndNode=$e(EndNode,2,*)
#;make sure the global is a valid name, and does not contain a directory reference
 i '$zname($p(StartNode,"("),3) q $$$ERROR($$$GlobalReferenceInvalid,StartingNode)
 i '$zname($p(EndNode,"("),3) q $$$ERROR($$$GlobalReferenceInvalid,EndingNode)
 i $p(StartNode,"(")'=$p(EndNode,"(") q $$$ERROR($$$MGBLStartAndEndGlobalDiffer)
#;Verify the source and destination directories exist and are mounted
 s Info=$zu(49,SrcDirectory)
 i Info<-1 {
	s Status=$$$ERROR($$$DatabaseDoesNotExist,SrcDirectory)
	q Status
 }
 i Info=-1 {
	s Status=$$$ERROR($$$DatabaseIsDismounted,SrcDirectory)
	q Status
 }
 s BlockSize=$$$getblksiz(Info) 
 s Info=$zu(49,DstDirectory)
 i Info<-1 {
	s Status=$$$ERROR($$$DatabaseDoesNotExist,DstDirectory)
	q Status
 }
 i Info=-1 {
	s Status=$$$ERROR($$$DatabaseIsDismounted,DstDirectory)
	q Status
 }
 s AverageNodeSize=+$p(MaxToCompare,",",2)
 i MaxNodesToCompare {
	s MaxNodes=+$p(MaxToCompare,",",1)
	i MaxNodes=0 s MaxNodes=9999999999999999
 } else {
 	s MaxMBToCompare=+$p(MaxToCompare,",",1)
	i MaxMBToCompare=0 {		
		s MaxNodesToCompare=1
		s MaxNodes=9999999999999999
	} else {
		i AverageNodeSize>0 {
			s MaxNodesToCompare=1
			s MaxNodes=MaxMBToCompare*(1024*1024)\AverageNodeSize	
		} else {
			s M=MaxMBToCompare*(1024*1024)
		}
 	}
 }
 i MaxDifferences=0 {
    s MaxDiffs=9999999999999999
 } else {
	s MaxDiffs=MaxDifferences
 }
#;See if the globals exist. If they both don't, then they match, return success. 
 s GloName=$p(StartNode,"(")
 s SrcInfo=$zu(167,6,7,SrcDirectory,GloName)
 i (+SrcInfo<0),(SrcInfo'=-2) q $$$ERROR($$$MGBLUnableToGetDirInfo,SrcDirectory,GloName,SrcInfo)
 s DstInfo=$zu(167,6,7,DstDirectory,GloName)
 i (+DstInfo<0),(DstInfo'=-2) q $$$ERROR($$$MGBLUnableToGetDirInfo,DstDirectory,GloName,DstInfo)
#;Global does not exist in either database, return success
 i (DstInfo=-2),(SrcInfo=-2) q $$$OK
#; If the global exists in both databases, make sure the collation is the same
 i (SrcInfo'=-2),(DstInfo'=-2) {
	i +$p(SrcInfo,"^",2)'=+$p(DstInfo,"^",2) q $$$ERROR($$$GeneralError,"Collations do not match") 
	s Info=SrcInfo
 } else {
#;Global only exists in one database. Get the Info for the one which exists so we can get the rule for encoding	 
	 i SrcInfo=-2 {
		 s Info=DstInfo
	 } else {
		 s Info=SrcInfo
	 }
 }
 s Collation=+$p(Info,"^",2)
 s CollationTable=$zu(70,1,Collation)
 i StartNode=EndNode {
	i StartNode'["(" {
		s EndNode=EndNode_"(END)"	 
	} else {
		s EndNode=$e(EndNode,1,*-1)_",END)"
	}
 } else {
	i EndNode'["(" s EndNode=EndNode_"(END)"	 
 }
#;Translate BEGIN and END in subscripts
 s StartNode=..TranslateBEGINandEND("",StartNode,0)
 s EndNode=..TranslateBEGINandEND("",EndNode,1)
 $$$EncodeKey(StartNode,CollationTable,StartKey)
 $$$EncodeKey(EndNode,CollationTable,EndKey)
#;StartKey is after EndKey. Just exit with success, do not return an error.
 i StartKey]EndKey q $$$OK
#;We are going to do $query with passing in the database as a directory spec.
 s SrcNS="^|""^^"_SrcDirectory_"""|"
 s DstNS="^|""^^"_DstDirectory_"""|"
 s SrcDir="^^"_SrcDirectory
 s DstDir="^^"_DstDirectory
 s SrcPrefetch=$p(SrcNS_StartNode,"(")
 s DstPrefetch=$p(DstNS_StartNode,"(")
 s x=$prefetchon(@SrcPrefetch)
 s x=$prefetchon(@DstPrefetch)
 s Prefetch=1
#;Run in batch mode.  
 s BatchFlag=$system.Process.BatchFlag(1)
#;Force $query to return node without a namespace specification.
 s oldzu687=$zu(68,7,1)
 s SrcNode=StartNode
 s DstNode=StartNode
 s LastNodeProcessed=SrcNode
#;L is the length of the nodes Key value and Data
 s L=0
#;First start out by using $d() to test the start node in both source and destination. After we process the $d(),
#;we will $query through the nodes.
#;Trap null subscript error since ^X(3,BEGIN) translates to ^X(3,"")
 Try {
	s SrcExists=$d(@(SrcNS_SrcNode),SrcData)
 } catch {
	 i $ze["SUBSCRIPT" {
		 s SrcExists=0
	 } else {
		 Throw $ze
	 }
 }
 Try {
	s DstExists=$d(@(DstNS_DstNode),DstData)
 } catch {
	 i $ze["SUBSCRIPT" {
		 s DstExists=0
	 } else {
		 Throw $ze
	 }
 }
 i (SrcExists=1)||(SrcExists=11) {
	s NodesChecked=1
	s L=$l(SrcData)+$l(SrcNode)
	i (DstExists=1)||(DstExists=11) {
#;If here both source and data nodes exist. Check if the data values are the same.
		 i SrcData'=DstData {
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:"^"_SrcNode,:$$FormatName^%qcr("^"_SrcNode,1))
			s Differences(Differences,2)=$$$ValueDifferent
			i ReturnDataValues {
				s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
				s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
			}
		 }
	 } else {
#;If here, the source node exists, and the destination node does not.
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:"^"_SrcNode,:$$FormatName^%qcr("^"_SrcNode,1))		 	
			s Differences(Differences,2)=$$$NodeDoesNotExistDst		 	
			i ReturnDataValues {
				s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
				s Differences(Differences,4)=""
			}
	 }
 } else {
	i (DstExists=1)||(DstExists=11) {
#;If here the source node does not exist, and the destination node exists.
		s Differences($i(Differences),1)=$case(FormatNodeNames,0:"^"_DstNode,:$$FormatName^%qcr("^"_DstNode,1))	 	
		s Differences(Differences,2)=$$$NodeDoesNotExistSrc		 	
		i ReturnDataValues {
			s Differences(Differences,3)=""
			s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
		}
	 }	 
 }
 s Status=$$$OK
 s $ze=""
 s SrcNode="^"_SrcNode
 s DstNode="^"_DstNode
 s EndNode="^"_EndNode
 s SrcData=""
 s DstData=""
#;If there are no nodes after the end range, then we do not have to perform
#;a check to see if we have $queried past the end range. This check is expensive
#;so we try to avoid it by having two loops below which are identical, except for the test
#;to see if we are beyond the end range.
#;CODE CHANGES IN ONE MUST BE DONE IN THE OTHER.
 s TmpNode=$q(@(SrcNS_$e(EndNode,2,*)))
 i TmpNode="" {
	 s CheckEndRange=0
 } else{
	 s CheckEndRange=1
 }
NodesMatch
#;When here, the source node and destination node are always the same.
#;$query through each of them until we either reach the end ($query=""),
#;the nodes are different, we hit the max mb, we hit the max # of diffs
#;Use user defined error traps to minimize CPU time for compares. Allow the loops
#;to drift past the end range in some cases. We only check to see if we are within the range
#;once every 1000 nodes, or if we find a difference to minimize CPU useage.
 i MaxNodesToCompare {
 	Try {
#;THIS CODE IS SIMILAR AS THE BELOW LOOP. MAKE CHANGES HERE AND THERE
		 i 'CheckEndRange {
			f i=NodesChecked:1:MaxNodes {
#;This $query generate a <SYNTAX> error if SrcNode="" or DstNode=""
		 		s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData),DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData) i (SrcNode=DstNode),(SrcData=DstData) continue
#;If here we have a difference
				$$$AreWePastEnd
				$$$CheckDiffs
			}
#;We may have hit the MaxNodes and end of global at the same time!
			i (SrcNode=""),(DstNode="") d $$$APPERROR($$$ERSYNTX)
			$$$AreWePastEnd
			ZTRAP "MAXN"
		} else {
			f i=NodesChecked:1:MaxNodes {
#;This $query generate a <SYNTAX> error if SrcNode="" or DstNode=""
#;Check every 1,000 nodes to see if we went beyond the end range.
		 		s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData),DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData) i (SrcNode=DstNode),(SrcData=DstData) {continue:(i#1000)  $$$AreWePastEnd }
#;If here we have a difference
				$$$AreWePastEnd
				$$$CheckDiffs
			}
#;We may have hit the MaxNodes and end of global at the same time!
			i (SrcNode=""),(DstNode="") d $$$APPERROR($$$ERSYNTX)
			$$$AreWePastEnd
			ZTRAP "MAXN"
		}
 	} catch {
		s NodesChecked=NodesChecked+(i-NodesChecked)+1
	}
 } else {
 	Try {
#;THIS CODE IS SIMILAR AS THE ABOVE LOOP. MAKE CHANGES HERE AND THERE
		i 'CheckEndRange {
			f i=1:1 {
#;These $query generate a <SYNTAX> error if SrcNode="" or DstNode=""
		 		s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData),DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData),L=L+$l(SrcNode)+$l(SrcData)
#;Generate a <ZSIZE> error if we have reached the max mb to compare
		 		i (SrcNode=DstNode),(SrcData=DstData) continue:L<=M
		 		$$$AreWePastEnd 
		 		i L>M ZTRAP "SIZE"
				$$$CheckDiffs
			}
		 } else {
			f i=1:1 {
#;These $query generate a <SYNTAX> error if SrcNode="" or DstNode=""
		 		s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData),DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData),L=L+$l(SrcNode)+$l(SrcData)
#;Check every 1,000 nodes to see if we went beyond the end range.
#;Generate a <ZSIZE> error if we have reached the max mb to compare
		 		i (SrcNode=DstNode),(SrcData=DstData) i '(i#1000) {$$$AreWePastEnd} continue:L<=M
		 		$$$AreWePastEnd 
		 		i L>M ZTRAP "SIZE"
				$$$CheckDiffs
			}
		 }
	 } Catch {
		  s NodesChecked=NodesChecked+i
	 }
 }
#;See if we exceeded the amount of data we wanted to check.
#;If so return the last node we processed, and the error code
#;saying that we hit the max number of mb to compare. This method should
#;then get called by the caller again, passing in the LastNodeProcessed we just returned
#;as the starting node in order to continue scanning the range for differences.
 i $ze["<ZSIZE>" {
	s LastNodeProcessed=SrcNode
	s Status=$$$ERROR($$$MaxMBToCompare,$fn(L/(1024*1024),"",1))
	g Exit	 
 }
#;Same as <ZSIZE> but with nodes.
#;If we originally passed in the MaxMBToCompare, and we switched above to
#;check based on number of nodes, make sure we return the MaxMBToCompare error.
 i $ze["<ZMAXN>" {
	s LastNodeProcessed=SrcNode
	i $zb(Flags,$$$MaxNodesToCompareBit,1) {
		s Status=$$$ERROR($$$MaxNodesToCompare,MaxNodes)
	} else {
		s Status=$$$ERROR($$$MaxMBToCompare,$p(MaxToCompare,",",1))
	}
	g Exit	 
 }
#;If we have a syntax error, then we have $queried to the end of both
#;source and destination nodes (SrcNode="",DstNode=""), and then executed
#;a $query on the null SrcNode.
#;Adjust the number of nodes checked.
 i $ze["<SYNTAX>" {
 	s NodesChecked=NodesChecked-3
	i (SrcNode=""),(DstNode="") {
		s Status=$$$OK
		s LastNodeProcessed=""
		g Exit
	} else {
#;Something bad happened when we were forming the node to $query on.
#;We shouldn't get here. SrcNode or DstNode will have the bad node we tried to query on. Report it as an error.
		s Status=$$$OK
		i SrcNode'="" {
			s LastNodeProcessed=SrcNode
			s Status=$$$ADDSC(Status,$$$ERROR($$$GeneralError,"Syntax error processing source node: "_SrcNode_" "_$ze))
		}
		i DstNode'="" {
			i SrcNode="" s LastNodeProcessed=DstNode
			s Status=$$$ADDSC(Status,$$$ERROR($$$GeneralError,"Syntax error processing destination node: "_DstNode_" "_$ze))
		}
		g Exit
	}		 
 }
#;We have hit the max number of differences we are to report.
#;Return the error code for this, and the last node we processed.
#;This method should then get called by the caller again, passing 
#;in the LastNodeProcessed we just returned,
#;in order to continue scanning the range for differences. 
 i $ze["<ZMAXD>" {
	s LastNodeProcessed=SrcNode
	s Status=$$$ERROR($$$MaxDifferencesReached,Differences)
	g Exit
 }
 i $ze["<ZNODE>" {
#;If here, One (or both) nodes are within the range we are checking, and we have one of the following situations:
#;1) SrcNode is Null, DstNode is not. Return all the remaining DstNodes in the range as differences.
#;2) DstNode is null, SrcNode is not. Return all the remaining SrcNodes in the range as differences.
#;3) SrcNode'=DstNode. 
	i (SrcNode=""),(DstNode="") {
		s Status=$$$OK
		s LastNodeProcessed=""
		g Exit
	}
SrcNodeNull
	i SrcNode="" {
#;All DstNodes after this until we hit the end range or null 
#;are marked as existing in the destination db but not the source db.
		s LastNodeProcessed=""
		s NodesChecked=NodesChecked-2
	 	f i=1:1 {
#;As we traverse the destination nodes, make sure they are still in the range.
			$$$EncodeKey($e(DstNode,2,*),CollationTable,DstKey)
			i (DstKey]EndKey)||(DstKey=EndKey) {
				s LastNodeProcessed=""
				q
			}
#;The destination node is still within the range. From now on we will use the
#;destination node to calculate length and last node processed.
			s LastNodeProcessed=DstNode
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:DstNode,:$$FormatName^%qcr(DstNode,1))	 	
			s Differences(Differences,2)=$$$NodeDoesNotExistSrc		 	
			i ReturnDataValues {
				s Differences(Differences,3)=""
				s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
			}
			s NodesChecked=NodesChecked+1
			i 'AverageNodeSize {
				s L=L+$l(DstNode)+$l(DstData)
				i $d(M),(L>M) {
					s Status=$$$ERROR($$$MaxMBToCompare,$fn(L/(1024*1024),"",1))
					q
				}
			} else {
				i NodesChecked>=MaxNodes {
					s Status=$$$ERROR($$$MaxNodesToCompare,MaxNodes)
					q				
				}
			}
			i $g(Differences,0)>=MaxDiffs {
				s Status=$$$ERROR($$$MaxDifferencesReached,Differences)
				q
			}
			s DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData)
			i DstNode="" {
				s LastNodeProcessed=""
				q
			}
	 	}
		g Exit
	}
DstNodeNull
 	if DstNode="" {
#;All SrcNodes after this until we hit the end range or null 
#;are marked as existing in the source db but not the destination db.
#;Reverse $query on the source node to get the last node processed, until
#;we can validate that the current SrcNode is within range.
		s NodesChecked=NodesChecked-2
		s LastNodeProcessed=""				
		f i=1:1 {
			$$$EncodeKey($e(SrcNode,2,*),CollationTable,SrcKey)
			i (SrcKey]EndKey)||(SrcKey=EndKey) {
				s LastNodeProcessed=""
				q
			}
		 	s LastNodeProcessed=SrcNode
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:SrcNode,:$$FormatName^%qcr(SrcNode,1))
			s Differences(Differences,2)=$$$NodeDoesNotExistDst		 	
			i ReturnDataValues {
				s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
				s Differences(Differences,4)=""
			}
			s NodesChecked=NodesChecked+1
			i 'AverageNodeSize {
				s L=L+$l(SrcNode)+$l(SrcData)
				i $d(M),(L>M) {
					s Status=$$$ERROR($$$MaxMBToCompare,$fn(L/(1024*1024),"",1))
					q
				}
			} else {
				i NodesChecked>=MaxNodes {
					s Status=$$$ERROR($$$MaxNodesToCompare,MaxNodes)
					q				
				}
			}
			i $g(Differences,0)>=MaxDiffs {
				s Status=$$$ERROR($$$MaxDifferencesReached,Differences)
				q
			}
 			s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData)
 			i SrcNode="" {
	 			s LastNodeProcessed=""
	 			q
 			}
	 	}
		g Exit
 	}
NodesDontMatch
#;If here, the nodes do not match.
	s GoTag=""
	i SrcKey]DstKey {
#;There are missing source nodes. $query the destination nodes and
#;find which ones are missing.		
		s LastNodeProcessed=DstNode
	 	f i=1:1 {
#;The destination node is still within the range. From now on we will use the
#;destination node to calculate length and last node processed.
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:DstNode,:$$FormatName^%qcr(DstNode,1))	 	
			s Differences(Differences,2)=$$$NodeDoesNotExistSrc		 	
			i ReturnDataValues {
				s Differences(Differences,3)=""
				s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
			}
			s DstNode=$q(@(DstNS_$e(DstNode,2,*)),1,DstData)
			i DstNode="" {
				s GoTag="DstNodeNull"
				q
			}
			s NodesChecked=NodesChecked+1
			i (SrcNode=DstNode) {
#;If here, the destination $query has caught up to the source.
#;See if the data is different.
				s LastNodeProcessed=SrcNode
				i (SrcData'=DstData) {
					s Differences($i(Differences),1)=$case(FormatNodeNames,0:SrcNode,:$$FormatName^%qcr(SrcNode,1))
					s Differences(Differences,2)=$$$ValueDifferent
					i ReturnDataValues {
						s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
						s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
					}					
				}
				s GoTag="NodesMatch"
				q
			}
			$$$EncodeKey($e(DstNode,2,*),CollationTable,DstKey)			
			i (DstKey]EndKey)||(DstKey=EndKey) {
#;The Destination is beyond the end of the range. Get the rest of the source nodes.
				s DstNode=""
				s GoTag="DstNodeNull"
				q
			}
			i (DstKey]SrcKey) {
				s GoTag="NodesDontMatch"
				q
			}
			s LastNodeProcessed=DstNode
			i 'AverageNodeSize {
				s L=L+$l(DstNode)+$l(DstData)
				i $d(M),(L>M) {
					s Status=$$$ERROR($$$MaxMBToCompare,$fn(L/(1024*1024),"",1))
					q
				}
			} else {
				i NodesChecked>=MaxNodes {
					s Status=$$$ERROR($$$MaxNodesToCompare,MaxNodes)
					q				
				}
			}
			i $g(Differences,0)>=MaxDiffs {
				s Status=$$$ERROR($$$MaxDifferencesReached,Differences)
				q
			}
	 	}
 		i GoTag="NodesDontMatch" g NodesDontMatch
 		i GoTag="DstNodeNull" g DstNodeNull
 		i GoTag="NodesMatch" g NodesMatch
 		g Exit		
	} else {
#;DstKey is after SrcKey		
#;There are missing destination nodes. $query the source nodes and
#;find which ones are missing.		
		s LastNodeProcessed=SrcNode
	 	f i=1:1 {
#;The source node is still within the range. From now on we will use the
#;source node to calculate length and last node processed.
			s Differences($i(Differences),1)=$case(FormatNodeNames,0:SrcNode,:$$FormatName^%qcr(SrcNode,1))	 	
			s Differences(Differences,2)=$$$NodeDoesNotExistDst		 	
			i ReturnDataValues {
				s Differences(Differences,3)=""
				s Differences(Differences,4)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
			}
			s SrcNode=$q(@(SrcNS_$e(SrcNode,2,*)),1,SrcData)
			i SrcNode="" {
				s GoTag="SrcNodeNull"
				q
			}
			s NodesChecked=NodesChecked+1
			i (SrcNode=DstNode) {
#;If here, the source $query has caught up to the Destination.
#;See if the data is different.
				s LastNodeProcessed=SrcNode
				i (SrcData'=DstData) {
					s Differences($i(Differences),1)=$case(FormatNodeNames,0:DstNode,:$$FormatName^%qcr(DstNode,1))
					s Differences(Differences,2)=$$$ValueDifferent
					i ReturnDataValues {
						s Differences(Differences,3)=$case(FormatDataValues,0:SrcData,:$$Format^%qcr(SrcData,1))
						s Differences(Differences,4)=$case(FormatDataValues,0:DstData,:$$Format^%qcr(DstData,1))
					}					
				}
				s GoTag="NodesMatch"
				q
			}
			$$$EncodeKey($e(SrcNode,2,*),CollationTable,SrcKey)			
			i (SrcKey]EndKey)||(SrcKey=EndKey) {
#;The Source node is beyond the end of the range. Get the rest of the destination nodes.
				s SrcNode=""
				s GoTag="SrcNodeNull"
				q
			}
			i (SrcKey]DstKey) {
				s GoTag="NodesDontMatch"
				q
			}
			s LastNodeProcessed=SrcNode
			i 'AverageNodeSize {
				s L=L+$l(SrcNode)+$l(SrcData)
				i $d(M),(L>M) {
					s Status=$$$ERROR($$$MaxMBToCompare,$fn(L/(1024*1024),"",1))
					q
				}
			} else {
				i NodesChecked>=MaxNodes {
					s Status=$$$ERROR($$$MaxNodesToCompare,MaxNodes)
					q				
				}
			}
			i $g(Differences,0)>=MaxDiffs {
				s Status=$$$ERROR($$$MaxDifferencesReached,Differences)
				q
			}
	 	}
 		i GoTag="NodesDontMatch" g NodesDontMatch
 		i GoTag="SrcNodeNull" g SrcNodeNull
 		i GoTag="NodesMatch" g NodesMatch
 		g Exit
	}
 }
 i $ze["<ZEXIT>" {
	s Status=$$$OK
	s LastNodeProcessed=""
	g Exit
 }
#;Everything should exit above. If here, we have something we haven't handled in the code above. 
 ztrap $ze

Exit
 i $d(BatchFlag) d $system.Process.BatchFlag(BatchFlag)
 i $d(Prefetch) {
	s x=$prefetchoff(@SrcPrefetch)
	s x=$prefetchoff(@DstPrefetch)
	k Prefetch
 }
 i $d(oldzu687) d $zu(68,7,oldzu687)
 i $$$ISOK(Status) {
	 i Differences'=0 s Status=$$$ERROR($$$DifferencesFound,Differences)
 }
#;Get approximate # of blocks checked. Average block is 28% free
 s PercentFreeSpace=1.28
 i 'AverageNodeSize {
	 i L=0 {
		 s BlocksChecked=0
 	} else {
 		s BlocksChecked=L*PercentFreeSpace\BlockSize+1
 	}
 } else {
	s BlocksChecked=NodesChecked*AverageNodeSize\BlockSize
	i (BlocksChecked=0),(NodesChecked>0) s BlocksChecked=1
 }
 s MBChecked=BlocksChecked*BlockSize/(1024*1024)
 s MBChecked=$s(MBChecked=0:0,MBChecked<.1:"0.1",1:$fn(MBChecked,"",1))
 s Differences(0)=$lb($e(LastNodeProcessed,2,*),BlocksChecked,NodesChecked,MBChecked,BlockSize)
 q Status
Error s $zt=""
 k SaveSpace
 i $ze["STORE" {
	s Status=$$$ERROR($$$MaxStorageReached)
	g Exit
 }
#;Don't save large array of differences in error trap, just the count
 s Diffs=$g(Differences)
 s Diffs(0)=$g(Differences(0))
 k Differences
 m Differences=Diffs
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 d BACK^%ETN
 g Exit
}

/// Get size of this global<br>
/// 'Allocated' - total size, in MB, of blocks allocated for the global.<br>
/// 'Used' - total used data, in MB, for the global.<br>
/// 'fast' - 2 : returns stochastic estimates for both 'Allocated' and 'Used' (fastest option for large globals) <br>
/// 1 : only returns exact 'Allocated' value (avoids reads of data blocks) <br>
/// 0 : returns exact values for both 'Allocated' and 'Used'.
ClassMethod GetGlobalSize(Directory As %String, GlobalName As %String, ByRef Allocated As %Integer, ByRef Used As %Integer, fast As %Integer = 0) As %Status
{
 s $zt="ERROR"
 s Obj=##Class(%GlobalEdit).Open(GlobalName,Directory,,,.Status)
 i '$$$ISOK(Status) q Status
 q Obj.GetSize(.Allocated,.Used,fast)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Return the number of global nodes in the range, and journal sizing information.<br>
/// This method will return the number of global nodes in the range, and the sizes of data within that range.
/// It will also return 
/// information about the amount of journal space which would be used if the range were
/// merged into a different database, or moved via a DataMove operation.<br><br>
/// Parameters:<br>
/// Directory - Directory where global is located.<br>
/// StartNode - Starting node of global. Note that you can specify ^GLOBAL(BEGIN) to mean the start of the global.
/// This would include ^GLOBAL itself.
/// You can also specify ^GLOBAL("XXX"_$c(1)_"*next)" to mean start counting after global ^GLOBAL("XXX").<br>
/// EndNode - End Node of global. The returned sizes do not include the EndNode. Note that you can specify ^GLOBAL(END)
/// to mean through the end of the global. An EndNode value of null, or equal to the value of StartNode will return the size of 
/// StartNode and all children of StartNode.<br>
/// Return Values: <br>
/// The method will return a %Status value of success, or an error.<br>
/// The array Size returns data and estimated journal sizes in both blocks and MB for the specified global range.<br>
/// If the global does not exist the sizes will all be set to 0.
/// If any error occurs, sizes will not be set.<br><br>
/// Size=Number of data nodes<br>
/// Size("DataSize","Bytes")=Size of global data in bytes<br>
/// Size("DataSize","MB")=Size of global data in MB<br>
/// Size("KeySize","Bytes")=Size of global keys in bytes<br>
/// Size("KeySize","MB")=Size of global keys in MB<br>
/// Size("TotalNodeSize","Bytes")=Total size of all global data in bytes (Datasize + KeySize)<br>
/// Size("TotalNodeSize","MB")=Total size of all global data in MB (Datasize + KeySize)<br>
/// Size("JournalOverHead","Bytes")=Estimate of size of journal overhead in bytes<br>
/// Size("JournalOverHead","MB")=Estimate of size of journal overhead in MB<br>
/// Size("TotalJournalSize","Bytes")=Estimate of total journal size in bytes<br>
/// Size("TotalJournalSize","MB")=Estimate of total journal size in MB<br><br>
/// Examples:<br><br>
/// Find the counts of global ^DATA<br>
/// s Status=##Class(%GlobalEdit).GetGlobalCountBySubscript("c:\iris\mgr\user\","DATA","",.Size)<br><br>
/// Find the counts of global ^DATA("Jones")<br>
/// s x=##Class(%GlobalEdit).GetGlobalCountBySubscript("c:\iris\mgr\user\","DATA(""Jones"")","",.Size)<br><br>
/// Find the count of nodes between nodes ^DATA("Jones") up to but not including ^DATA("Smith","zzzzz")<br>
/// s x=##Class(%GlobalEdit).GetGlobalCountBySubscript("c:\iris\mgr\user\","DATA(""Jones"")","DATA(""Smith"",""zzzzz"")",.Size)<br><br>
/// Find the count of all the nodes after after node ^X(500)<br>
/// s x=##Class(%GlobalEdit).GetGlobalCountBySubscript("c:\db1\","^X(500"_$c(1)_"*next)","^X(END)",.Size)<br><br>
/// Find the count of all the nodes from the beginning of the global up to but not including ^X(500)<br>
/// s x=##Class(%GlobalEdit).GetGlobalCountBySubscript("c:\db1\","^X(BEGIN)","^X(500)",.Size)<br><br>
ClassMethod GetGlobalCountBySubscript(Directory As %String, StartingNode As %String, EndingNode As %String = "", ByRef Size As %String = 0)
{
#define EncodeKey(%Node,%Collation,%Key) s %Key=$zu(70,6,%Node,$zu(70,1,%Collation))
#;Estimated journal overhead (bytes) for each entry for normal globals and big string globals
#define SmallOverHead 36
#define LargeOverHead 24
 s $zt="Error"
 s Status=$$$OK
 k Size
 s DataSize=0
 s KeySize=0
 s NodeCount=0
 s JournalOverHead=0
 s StartNode=StartingNode
 s EndNode=EndingNode
 i EndNode="" s EndNode=StartNode
 i $e(StartNode)'="^" s StartNode="^"_StartNode
 i $e(EndNode)'="^" s EndNode="^"_EndNode
 s GloName=$p(StartNode,"(")
 i GloName'=$p(EndNode,"(") q $$$ERROR($$$GblNamesMustBeTheSame,StartingNode,EndingNode)
 s Info=$zu(49,Directory)
 i Info<-1 q $$$ERROR($$$DatabaseDoesNotExist,Directory)
 i Info=-1 q $$$ERROR($$$DatabaseIsDismounted,Directory)
 s BlockSize=$$$getblksiz(Info)
 s Status=$$GetJournal^%SYS.CONFIG(.Properties)
 i '$$$ISOK(Status) q Status
 s Info=$zu(167,6,7,Directory,GloName)
 i (+Info<0) {
#;-2=Global does not exist
	i Info=-2 {
		g Success
	} else {
		s Status=$$$ERROR($$$UnableToGetDirInfo,GloName,Info)
	}
	q Status
 }
 s Block=+$p(Info,"^",4)
#;If block=0, we have a directory entry for the global, but no data yet 
 i Block=0 g Success
 s Collation=+$p(Info,"^",2)
 s Rule=$zu(70,1,Collation)
#;If we specify (END), we want to calculate all the globals at this level. We could have a global with
#;a subscript like ^X($c(65535)_"A"). So lets just get a string with 512 $c(65535)
#;concatenated together (longer than max subscript).
 i $$$IsUnicode {
	s $p(EndRange,$c(65535),512)=""
 } else {
	s $p(EndRange,$c(255),512)=""
 }
#;^X("D"$c(1)_*Next) really means ^X("D",END)
 i $zcvt($e(EndNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s EndNode=$e(EndNode,1,*-7)_",END)"
 }
 i $e(EndNode,$l(EndNode)-3,$l(EndNode))="END)" {
	s EndNode=$e(EndNode,1,$l(EndNode)-4)_""""_EndRange_""""_")"
 }
 s Status=..EncodeKey(EndNode,Rule,.EndKey)
 i '$$$ISOK(Status) q Status

#;We need to handle ^X(BEGIN):^X(20) special.
#;Transform this to ^X:^X(20) which is according to the SLM mapping rules. 
#;^X is included in the ^X(BEGIN):^X(20) range.
 i $e($p(StartNode,"(",2),1,6)="BEGIN)" {
	 s StartNode=$p(StartNode,"(",1) 
 }
#;Convert ^X(123,...,BEGIN) to ^X(123,...,"")
 i $e(StartNode,$l(StartNode)-5,$l(StartNode))="BEGIN)" {
 	s StartNode=$e(StartNode,1,$l(StartNode)-6)_""""""_")"
 }
#;Convert ^X(123,10_$c(1)_"*next)" to ^X(123,10,$c(255...)). Then do a $Query(StartNode)to get the
#;first node we care about
 i $zcvt($e(StartNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s StartNode=$e(StartNode,1,*-7)_","_""""_$e(EndRange,1,32)_""""_")"
#;Now adjust the StartNode to the next node using $Q. If there is no node, or
#;we are past the Ending node, then we are done.
	Try {
		s StartNode=$q(@("^|""^^"_Directory_"""|"_$e(StartNode,2,*)))
		s StartNodeAdjusted=1
	} catch {
		s Status=$$$ERROR($$$GlobalReferenceInvalid,StartingNode)
	}
	i '$$$ISOK(Status) q Status
	i StartNode="" {
#;Set sizes to 0 here
		g Success
	} else {
#;Strip directory spec
		s StartNode="^"_$p(StartNode,"|",3,*)
	}
 }	 
 s Status=..EncodeKey(StartNode,Rule,.StartKey)
 i '$$$ISOK(Status) q Status
#;If StartNode was adjusted to or past the end node, then we are done.
 i $d(StartNodeAdjusted) {
	i (StartNode=EndNode)||(StartKey]EndKey) {
		g Success
	}
 }
#;Bump endkey so "]" works
 i StartNode=EndNode s EndKey=EndKey_$c(1)
 i $d(StartNodeAdjusted)=0 {
	 i StartKey]EndKey q $$$ERROR($$$GblEndNodeAfterBeginNode,EndingNode,StartingNode)
 }
 o 63:"^^"_Directory
#;Perform trickery here to get the starting block into the view buffer. 
#;First use $zu(207,3) to perform a $Data on the start node to get its global data page
#;into the view buffer. If the $Data fails to find the node, then use $zu(207,4) to $query
#;to the first node in the specified range and get it into the view buffer. If both functions fail to
#;find a page, then we are done since the global must have just been killed, or never existed.
#;Get and retain the block which contains the start node. We might have a begin node of ^X("") which would
#;generate a subscript error, so catch it and drop into $query.
 s Val=0
 Try {
	s Val=$zu(207,3,"^|""^^"_Directory_"""|"_$e(StartNode,2,*))
 } catch {
	s Val=0
 }
 i Val=0 {
	 Try {
		s Val=$zu(207,4,"^|""^^"_Directory_"""|"_$e(StartNode,2,*))
	 } catch {
		s Status=$$$ERROR($$$GeneralError,"Unable to query to starting node - "_Directory_":"_StartingNode)
		g Exit
	 }
 }
 i Val=0 g Success
#;Get the first node in the page into a variable. We use this for debugging only since it will go into the %ETN entry.
 s FirstNodeOnPage=$v(1,-5)
#;Find the first node on the page which is the same as or later than the start node of the range.
#;If we are looking at entire global (say ^X), and ^X itself doesn't exist, we need to skip over the placeholder for
#;it in the data page since $v(1,-5) will return ^X, and $v(2,-5) will return a null string, leaving the possibility that
#;an erroneous node ^X="" could get counted.
 f FirstNodeToApply=1:1 {
	i FirstNodeToApply=1 {
		i FirstNodeOnPage'["(" {
			i $d(@("^|""^^"_Directory_"""|"_$e(FirstNodeOnPage,2,*)))=10 continue
		}
	}
	s NodeKey=$v(2*FirstNodeToApply-1,-6)
	q:NodeKey=""
#;StartKey points to the node we want to start on.
	i (NodeKey]StartKey) q
	i (NodeKey=StartKey) q
 }
#;We must have found the node on the page. If we didn't something bad is going on
 i NodeKey="" {
	s Status=$$$ERROR($$$GeneralError,"Unable to find starting node - "_Directory_":"_StartingNode)
	g Exit
 }
#;We could have the instance where the range is A(50):(52) and A(51) existed.
 i (NodeKey]EndKey) {
	s Found=0
	s Node="^|""^^"_Directory_"""|"_$e(StartNode,2,*)
	s DD=$d(@Node,Data)
	i (DD=1)||(DD=11) {
		s Found=1
		s Count=Count+1
		s DataSize=DataSize+$l(Data)
		s KeySize=KeySize+$l(NodeKey)
		s JournalOverHead=JournalOverHead+$$$SmallOverHead
	}	
	s Done=1	
	g Success
 }
#;If here, FirstNodeToApply is pointing to the first node on the page we might need to move. See if the node
#;we found is before we hit the end node. Continue on processing nodes in the page until either we go past the end node,
#;or we hit the end of the page.
#;
#;Note that we also come here when we are processing a page below and we determine that the page
#;contains a big data node. 
 f  {
 	f j=FirstNodeToApply:1 {
		s NodeKey=$v(2*j-1,-6)
		q:NodeKey=""
		i (EndKey]NodeKey) {
#;We have to look at the datatype because it may be a big data node, and since the data may have been deleted
#;by the time we reference it since it lies outside the view buffer. So we do a $g() and set it
#;to "" if it was deleted. The journal apply will pick this up and delete it later. If not big data
#;we can use $v() to retrieve the data. $view offsets are defined in hinteg.c function gdview.
			s Val=$v(2*j,-6)
			s DataType=$a($e(Val))
#;Type=3,5,7 means big data.
			i (DataType=3)||(DataType=5)||(DataType=7) {
				s Val=$p(Val,",",3)+($p(Val,",",2)-1*(BlockSize-$zu(40,32,10)))
	 			s JournalOverHead=JournalOverHead+$$$SmallOverHead+(($l(NodeKey)+Val/65536*$$$LargeOverHead)\1)
			} else {
				s Val=$l($v(2*j,-6))				
				s JournalOverHead=JournalOverHead+$$$SmallOverHead
			}
			s DataSize=DataSize+Val
			s KeySize=KeySize+$l(NodeKey)
 			s NodeCount=NodeCount+1
			continue
		} else {
#;If here, we have just gone past the EndKey so we are done
			s Done=1	
			q
		}
 	}
#;If we reached the end of the global, we are done
 	i $d(Done) q
 	s LastNodeOnPrevPage=$v(-2,-5)
 	$$$EncodeKey(LastNodeOnPrevPage,Collation,LastNodeOnPrevPageKey)
#;Do a $query on the last node we processed and load the next page into the view buffer.
 	s Val=$zu(207,4,"^|""^^"_Directory_"""|"_$e(LastNodeOnPrevPage,2,*))
#;We don't have any data after we applied the previous page.
#;We now need to $query any we find before or equal to the last node to copy
 	i Val=0 q
 	s FirstNodeOnPage=$v(1,-5)
 	$$$EncodeKey(FirstNodeOnPage,Collation,FirstNodeOnPageKey)
 	i (FirstNodeOnPageKey]EndKey)||(FirstNodeOnPageKey=EndKey) g Exit
#;There may have been some data inserted into the tree which pushed data from the page we just processed
#;(or even data from a couple of pages before the page we just processed which could even be from a SLM range
#;which is prior to the range ) into the page we just loaded in
#;with $zu(207,4). If so, we MUST skip over those nodes since we can't double count the data. We are guaranteed that
#;we will find the next node we need to process on this page. The variable FirstNodeToApply will be set
#;to the first node which $querys after the last node on the previous page.
 	i FirstNodeOnPageKey']LastNodeOnPrevPageKey {
		f FirstNodeToApply=1:1 {
			i FirstNodeToApply=1 {
				i FirstNodeOnPage'["(" {
					i $d(@("^|""^^"_Directory_"""|"_$e(FirstNodeOnPage,2,*)))=10 continue
				}
			}
			s NodeKey=$v(2*FirstNodeToApply-1,-6)
			q:NodeKey=""
			i (NodeKey]LastNodeOnPrevPageKey) q
		}
#;We must have found the node on the page. If we didn't something bad is going on
 		i NodeKey="" {
			s Status=$$$ERROR($$$GeneralError,"Unable to find node on next page - "_Directory_":"_LastNodeOnPrevPage)
			g Exit
 		}
		continue	 	
 	}
 	s FirstNodeToApply=1
	continue
 }
 i '$$$ISOK(Status) g Exit
Success
 s NumJournalFiles=KeySize+DataSize+JournalOverHead/(Properties("FileSizeLimit")*(1024*1024))\1+1
 s Size("DataSize","Bytes")=DataSize
 s Size("DataSize","MB")=$fn(DataSize/(1024*1024),"",2)
 s Size("KeySize","Bytes")=KeySize
 s Size("KeySize","MB")=$fn(KeySize/(1024*1024),"",2)
 s Size("TotalNodeSize","Bytes")=KeySize+DataSize
 s Size("TotalNodeSize","MB")=$fn(Size("KeySize","MB")+Size("DataSize","MB"),"",2)
#;Add in Journal directory size and journal header for each file
 s Size("JournalOverHead","Bytes")=JournalOverHead+(NumJournalFiles*$p($zu(78,28),"^",3))+(NumJournalFiles*65535)
 s Size("JournalOverHead","MB")=$fn(Size("JournalOverHead","Bytes")/(1024*1024),"",2)
 s Size("TotalJournalSize","Bytes")=DataSize+KeySize+Size("JournalOverHead","Bytes")
 s Size("TotalJournalSize","MB")=$fn(Size("DataSize","MB")+Size("KeySize","MB")+Size("JournalOverHead","MB"),"",2)
 s Size=NodeCount
 s Status=$$$OK
Exit
 c 63
 q Status
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 d BACK^%ETN
 g Exit
}

/// Return the size of a global or range of nodes in a global.<br>
/// This method will return the size of a global based on the number
/// of database blocks the global resides in.<br><br>
/// Parameters:<br>
/// Directory - Directory where global is located.<br>
/// StartNode - Starting node of global. Note that you can specify ^GLOBAL(BEGIN) to mean the start of the global.
/// This would include ^GLOBAL itself.
/// You can also specify ^GLOBAL("XXX"_$c(1)_"*next)" to mean start counting after global ^GLOBAL("XXX").<br>
/// EndNode - End Node of global. The returned sizes do not include the EndNode. Note that you can specify ^GLOBAL(END)
/// to mean through the end of the global. An EndNode value of null, or equal to the value of StartNode will return the size of 
/// StartNode and all children of StartNode.<br>
/// Size - Maximum number of MB to count. If the size of the global exceeds this value, 
/// calculation stops, and an error is returned. If undefined or set to 0, then the entire range is counted.
/// Be careful to reset this for multiple calls to the method.<br>
/// Fast - If set and the global is large, this method will attempt a stochastic sample instead of taking an exact measurement. <br>
/// CalculateAverage - 0/1 - If set, then the following averages will be calculated and returned. Calculating the averages requires
/// additional time as it samples the data pages of the global. If not set, the values will be set to 0.<br>
/// Size("AverageNodesPerPage")<br>
/// Size("AverageNodeSize")<br><br>
/// Return Values: <br>
/// The method will return a %Status value of success, or an error.<br>
/// The array Size returns the amount of data in both blocks and MB, for each
/// level of the global, as well as the size of big string data, and a total. 
/// If the global does not exist the sizes will all be set to 0.
/// If any error occurs, sizes will not be set.<br>
/// Size=Total size in MB of the global range<br>
/// Size("Blocks","1")=# Blocks in level 1<br>
/// Size("Blocks","2")=# Blocks in level 2<br>
/// Size("Blocks","3")=# Blocks in level 3<br>
/// Size("Blocks","BigStrings")=# Big String Blocks<br>
/// Size("Blocks","Total")=Total # Blocks in global range<br>
/// Size("MB","1")=# MB in level 1<br>
/// Size("MB","2")=# MB in level 2<br>
/// Size("MB","3")=# MB in level 3<br>
/// Size("MB","BigStrings")=# Big String MB<br>
/// Size("MB","Total")=Total # MB in global range<br>
/// Size("AverageNodesPerPage")=Average nodes per page (Estimate)<br>
/// AverageNodesPerPage is calculated as follows:<br>
/// As each Bottom Pointer block is examined, 10 % of the data nodes pointed to by this pointer block are randomly selected and examined.
/// The number of nodes is accumulated in each selected page and summed together, and the total size of data blocks examined is summed
/// together. When we reach 20GB of data blocks examined, the loop continues, but we only select 2% of the data pages.
/// After we process the last pointer block, The AverageNodesPerPage is calculated by dividing the size of the summed data pages
/// by the number of summed nodes.
/// Size("AverageNodeSize")=Average node size (Estimate)<br>
/// AverageNodeSize is calculated by first estimating the total number of nodes in the global<br>
/// TotalNodes = Size("AverageNodesPerPage") * (Size("Blocks","Total")-Size("Blocks","BigStrings"))<br>
/// We then use the following:<br>
/// AverageNodeSize=$fn(Size*(1024*1024)/TotalNodes,"",1)
/// <br>
/// Examples:<br><br>
/// Find the size of global ^DATA<br>
/// s Status=##Class(%GlobalEdit).GetGlobalSizeBySubscript("c:\132u1\mgr\user\","DATA","",.Size)<br><br>
/// Find the size of data ^DATA("Jones")<br>
/// s x=##Class(%GlobalEdit).GetGlobalSizeBySubscript("c:\132u1\mgr\user\","DATA(""Jones"")","",.Size)<br><br>
/// Find the size of data between nodes ^DATA("Jones") up to but not including ^DATA("Smith","zzzzz")<br>
/// s x=##Class(%GlobalEdit).GetGlobalSizeBySubscript("c:\132u1\mgr\user\","DATA(""Jones"")","DATA(""Smith"",""zzzzz"")",.Size)<br><br>
/// Find the size of all the data after after node ^X(500)<br>
/// s x=##Class(%GlobalEdit).GetGlobalSizeBySubscript("c:\db1\","^X(500"_$c(1)_"*next)","^X(END)",.Size)<br><br>
/// Find the size of all the data from the beginning of the global up to but not including ^X(500)<br>
/// s x=##Class(%GlobalEdit).GetGlobalSizeBySubscript("c:\db1\","^X(BEGIN)","^X(500)",.Size)<br><br>
ClassMethod GetGlobalSizeBySubscript(Directory As %String, StartingNode As %String, EndingNode As %String = "", ByRef Size As %String = 0, Fast As %Boolean = 0, CalculateAverages As %Boolean = 0)
{
#;This is the same definition as below. Change it here and there!
 s $zt="Error"
 s StartNode=StartingNode
 s EndNode=EndingNode
 i EndNode="" s EndNode=StartNode
 i $e(StartNode)'="^" s StartNode="^"_StartNode
 i $e(EndNode)'="^" s EndNode="^"_EndNode
 s MaxSize=Size
 s TotalNodes=0
 s TotalNodesPages=0
 k Size
 s Status=$$$OK
 s Count=0
 s GloName=$p(StartNode,"(")
 i GloName'=$p(EndNode,"(") q $$$ERROR($$$GblNamesMustBeTheSame,StartingNode,EndingNode)
 s Info=$zu(49,Directory)
 i Info<-1 q $$$ERROR($$$DatabaseDoesNotExist,Directory)
 i Info=-1 q $$$ERROR($$$DatabaseIsDismounted,Directory)
 s BlockSize=$$$getblksiz(Info)
 s Info=$zu(167,6,7,Directory,GloName)
 i (+Info<0) {
	i Info=-2 {
		s Status=$$$OK
		f i=1:1:3 s Level("Blocks",i)=0
		s Level("Blocks","BigStrings")=0
		s Level=2
		g Exit
	} else {
		s Status=$$$ERROR($$$UnableToGetDirInfo,GloName,Info)
	}
	q Status
 }
 s Block=+$p(Info,"^",4)
#;If block=0, we have a directory entry for the global, but no data yet 
 i Block=0 {
	f i=1:1:3 s Level("Blocks",i)=0
	s Level("Blocks","BigStrings")=0
	s Level=2
	g Exit
 }
 s Collation=+$p(Info,"^",2)
 s Rule=$zu(70,1,Collation)
#;If we specify (END), we want to calculate all the globals at this level. We could have a global with
#;a subscript like ^X($c(65535)_"A"). So lets just get a string with 512 $c(65535)
#;concatenated together (longer than max subscript).
 i $$$IsUnicode {
	s $p(EndRange,$c(65535),512)=""
 } else {
	s $p(EndRange,$c(255),512)=""
 }
#;^X("D"$c(1)_*Next) really means ^X("D",END)
 i $zcvt($e(EndNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s EndNode=$e(EndNode,1,*-7)_",END)"
 }
 i $e(EndNode,$l(EndNode)-3,$l(EndNode))="END)" {
	s EndNode=$e(EndNode,1,$l(EndNode)-4)_""""_EndRange_""""_")"
 }
 s Status=..EncodeKey(EndNode,Rule,.EndKey)
 i '$$$ISOK(Status) q Status

#;We need to handle ^X(BEGIN):^X(20) special.
#;Transform this to ^X:^X(20) which is according to the SLM mapping rules. 
#;^X is included in the ^X(BEGIN):^X(20) range.
 i $e($p(StartNode,"(",2),1,6)="BEGIN)" {
	 s StartNode=$p(StartNode,"(",1) 
 }
#;Convert ^X(123,...,BEGIN) to ^X(123,...,"")
 i $e(StartNode,$l(StartNode)-5,$l(StartNode))="BEGIN)" {
 	s StartNode=$e(StartNode,1,$l(StartNode)-6)_""""""_")"
 }
#;Convert ^X(123,10_$c(1)_"*next)" to ^X(123,10,$c(255...)). Then do a $Query(StartNode)to get the
#;first node we care about
 i $zcvt($e(StartNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s StartNode=$e(StartNode,1,*-7)_","_""""_$e(EndRange,1,32)_""""_")"
#;Now adjust the StartNode to the next node using $Q. If there is no node, or
#;we are past the Ending node, then we are done.
	Try {
		s StartNode=$q(@("^|""^^"_Directory_"""|"_$e(StartNode,2,*)))
		s StartNodeAdjusted=1
	} catch {
		s Status=$$$ERROR($$$GlobalReferenceInvalid,StartingNode)
	}
	i '$$$ISOK(Status) q Status
	i StartNode="" {
		f i=1:1:3 s Level("Blocks",i)=0
		s Level("Blocks","BigStrings")=0
		s Level=2
		g Exit
	} else {
#;Strip directory spec
		s StartNode="^"_$p(StartNode,"|",3,*)
	}
 }	 
 s Status=..EncodeKey(StartNode,Rule,.StartKey)
 i '$$$ISOK(Status) q Status
#;If StartNode was adjusted to or past the end node, then we are done.
 i $d(StartNodeAdjusted) {
	i (StartNode=EndNode)||(StartKey]EndKey) {
		f i=1:1:3 s Level("Blocks",i)=0
		s Level("Blocks","BigStrings")=0
		s Level=2
		g Exit
	}
 }
#;Bump endkey so "]" works
 i StartNode=EndNode s EndKey=EndKey_$c(1)
 i $d(StartNodeAdjusted)=0 {
	 i StartKey]EndKey q $$$ERROR($$$GblEndNodeAfterBeginNode,EndingNode,StartingNode)
 }
 o 63:"^^"_Directory
 if Fast {
	s Status=..GetGlobalSizeBySubscriptEstimate(Directory,BlockSize,MaxSize,Block,StartingNode,EndingNode,StartKey,EndKey,CalculateAverages,.Level,.TotalNodes,.TotalNodesPages)
 }
 else {
	s Status=..GetGlobalSizeBySubscriptPrecise(Directory,BlockSize,MaxSize,Block,StartingNode,EndingNode,StartKey,EndKey,CalculateAverages,.Level,.TotalNodes,.TotalNodesPages)
 }
Exit
 i '$GET(Level("Blocks",Level+1)) f i=1:1:Level s Level("Blocks",i)=0
 s i="" f  s i=$o(Level("Blocks",i)) q:i=""  s Level("MB",i)=$fn(Level("Blocks",i)*BlockSize/(1024*1024),"",2)
 s i="" f  s i=$o(Level("Blocks",i)) q:i="Total"  s Level("Blocks","Total")=$g(Level("Blocks","Total"))+Level("Blocks",i),Level("MB","Total")=$g(Level("MB","Total"))+Level("MB",i)
 s Level=Level("MB","Total")
 m Size=Level
 i TotalNodesPages'=0 {
	 s AverageNodesPerPage=TotalNodes/TotalNodesPages
 } else {
	 s AverageNodesPerPage=0
 }
 s TotalNodes=AverageNodesPerPage*(Size("Blocks","Total")-Size("Blocks","BigStrings"))
 s Size("AverageNodesPerPage")=AverageNodesPerPage
 i TotalNodes'=0 {
	 s Size("AverageNodeSize")=$fn(Size*(1024*1024)/TotalNodes,"",1)
 } else {
	 s Size("AverageNodeSize")=0
 }
Exit1
 c 63
 q Status
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 d BACK^%ETN
 g Exit1
 Return Status
}

/// Internal helper for GetGlobalSizeBySubscript. Relies on its caller for initial validation
/// and the determination and encoding of the StartKey, EndKey values.
/// Called for Fast=False.
/// <br>
ClassMethod GetGlobalSizeBySubscriptPrecise(Directory As %String, BlockSize As %String, MaxSize As %String, Block As %Integer, StartingNode As %String, EndingNode As %String, StartKey As %String, EndKey As %String = "", CalculateAverages As %Boolean = 0, ByRef Level As %String = 0, ByRef TotalNodes As %Integer = 0, ByRef TotalNodesPages As %Integer = 0) [ Internal ]
{
 s Status=$$$OK,Level=1,Count=0,Level("Blocks",Level)=0
 #;First count all the pointer blocks
 f  {
 	v Block
 	s Count=Count+1
 	s Type=$$$type q:(Type=6!(Type=70))
 	f i=1:1 {
		s StartNodeKey=$v(2*i-1,-6)
#;Get the block previous to the one we are looking at for the down pointer
		i ((StartNodeKey]StartKey))||(StartNodeKey="") {
			s NextLevelBlock=$v(2*(i-1),-5)
 			q
 		}
 		i StartKey=StartNodeKey {
			s NextLevelBlock=$v(2*i,-5)
 			q
 		}
 	}
	s Level("Blocks",Level)=Level("Blocks",Level)+1
#;We are at the first page in the level we are starting to count. Now follow right links until end
 	f  {
		s Block=$$$link
 		i Block=0 {
			s Block=NextLevelBlock
			s Level=Level+1,Level("Blocks",Level)=0
			q
 		}
 		v Block
 		s Count=Count+1
 		i (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
	 		s Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
	 		q
 		}
 		s StartNodeKey=$v(1,-6)
 		i EndKey]StartNodeKey s Level("Blocks",Level)=Level("Blocks",Level)+1
 		s NextPageKey=$v(-1,-6)
 		i NextPageKey]EndKey {
			s Block=NextLevelBlock
			s Level=Level+1,Level("Blocks",Level)=0
			q
 		}
 	}
 	i '$$$ISOK(Status) q
 }
 i '$$$ISOK(Status) q Status
#;We are now at the bottom pointer level.
#;
 s Level("Blocks",Level+1)=0
 s Level("Blocks","BigStrings")=0
 s DataPage=""
 f {
	v Block
	s Count=Count+1
 	i (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
	 	s Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
		q
 	}
 	k SizePage
 	s NumSizePage=0
	k BigStringPtr
	s Found=0
 	f i=1:1 {
		s StartNodeKey=$v(2*i-1,-6)
		q:StartNodeKey=""
#;We save the previous data page block number so we can look down at
#;the data block level to see if the global range started on the previous page.		
		i StartKey]StartNodeKey s DataPage=$v(2*i,-6)
		i ((StartNodeKey]StartKey)||(StartKey=StartNodeKey))&&(EndKey]StartNodeKey) {
 			s Level("Blocks",Level+1)=Level("Blocks",Level+1)+1
 			s Count=Count+1
  			i (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
	 			s Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
				q
 			}
			s Found=1
 			s Data=$v(2*i,-6)
 			i CalculateAverages {
	 			s NumSizePage=NumSizePage+1
 				s SizePage(NumSizePage)=Data
 			}
 			i $p(Data,",")=1 s BigStringPtr($p(Data,",",2))="" 			
 		} else {
		 	q:StartNodeKey]EndKey 
		}
 	}
 	i '$$$ISOK(Status) q
	i StartNodeKey]EndKey {
		s Block=0
	} else {
		s Block=$$$link
	}
#;We are going to get the average number of Data Nodes per page
#;Sample 10% of the data pages until we hit 20gb. Sample 2% after.
#;We might have specified a range in a global which doesn't have any
#;data in it. We could get no array of pages to check for size.
	i NumSizePage {
		i TotalNodesPages*BlockSize<21474836480 /*20*1024*1024*1024*/ {
			s Pct=.10
		} else {
			s Pct=.02
		}
		s NumPages=NumSizePage*Pct\1
		i NumPages<1 s NumPages=1
		k Selected
		s TotalNodesPages=TotalNodesPages+NumPages
		f k=1:1:NumPages {
	#;Don't sample the same page twice.
			d  { s RandomPage=$r(NumSizePage)+1 } While ($d(Selected(RandomPage)))
			s Selected(RandomPage)=1
			s SizePage=SizePage(RandomPage)
			v +$p(SizePage,",",2)
	#;Count number of nodes.		
			For N=1:1 {
				Set X=$V(N-1*2+1,-6)
				Quit:X=""
			}
			s N=N-1
			s TotalNodes=TotalNodes+N
		}
	}
#;Check the previous data page now.
	i DataPage'="" {
		v +$p(DataPage,",",2)
	 	f i=1:1 {
			s StartNodeKey=$v(2*i-1,-6)
			q:StartNodeKey=""
			i ((StartNodeKey]StartKey)||(StartKey=StartNodeKey))&&(EndKey]StartNodeKey) {
 				s Level("Blocks",Level+1)=Level("Blocks",Level+1)+1
 				s Found=1
#;If there is a big string in the data page, add it to the big string check 				
 				i +DataPage s BigStringPtr(+$p(DataPage,",",2))=""
 				q
			}
 		}
 		s DataPage=""
 	}
	q:Found=""
 	s Level("Blocks",Level)=Level("Blocks",Level)+1
#;Now get the big string blocks	For the pointer page we just worked on. Block structure may have changed,
#;so trap the error and ignore.
	Try {
	s BigBlock=""
	f  {
		s BigBlock=$o(BigStringPtr(BigBlock)) q:BigBlock=""
		v BigBlock
		s Count=Count+1
	 	i (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
			s Status=$$$ERROR($$$GeneralError,"Size calculation exceeds maximum value of "_MaxSize_", calculation ending")
			q
 		}
		f i=1:1 {
			s StartNodeKey=$v(2*i-1,-6)
			q:StartNodeKey=""
			i ((StartNodeKey]StartKey)||(StartKey=StartNodeKey))&&(EndKey]StartNodeKey) {
	 			s Data=$v(2*i,-6)
	 			#;RJF519 (JO3199): Change to macro for bigstring test
	 			if $$$gdviewisbigstr($a(Data)) {
 					s Level("Blocks","BigStrings")=Level("Blocks","BigStrings")+$p(Data,",",2)
	 			}
	 		}
		}
	}
	} Catch {}
	i '$$$ISOK(Status) q
 	i Block=0 q
 }
 Return Status
}

/// The stochastic estimate counterpart to GetGlobalSizeBySubscriptPrecise. For Fast=True.
/// This borrows the algorithm from EstimatedSize^%GSIZE.
/// 
ClassMethod GetGlobalSizeBySubscriptEstimate(Directory As %String, BlockSize As %String, MaxSize As %String, Block As %Integer, StartingNode As %String, EndingNode As %String, StartKey As %String, EndKey As %String = "", CalculateAverages As %Boolean = 0, ByRef Level As %String = 0, ByRef TotalNodes As %Integer = 0, ByRef TotalNodesPages As %Integer = 0) [ Internal ]
{
	Try {
	#; Init the sample size caps and the starting values.
	Set SampleSizePointers=10000
	Set SampleSizeLeaves=5000
	Set Status=$$$OK,Level=1,Count=0,Level("Blocks",Level)=0,Level("Blocks",2)=0,Level("Blocks","BigStrings")=0
	Set TotalNodes=0,TotalNodesPages=0

	#; Determine if this is a large global. If not, just use the precise measurement.
	#; Note, ViewBlockFromTop will think the global does not exist (rc=-1) if it has no data.
 	Set DataDepth=0
	Set rc=$$ViewBlockFromTop^%GSIZE(.DataDepth,Directory,StartKey)
	If ((rc=0)||($EXTRACT(rc,1,2)="0,")) {
		Set Status=$$$ERROR($$$GeneralError,"Failed to measure the depth of the global tree, calculation ending.")
		Return Status
	}
	If (rc=-1||(DataDepth<=3)) {
		Return ..GetGlobalSizeBySubscriptPrecise(Directory,BlockSize,MaxSize,Block,StartingNode,EndingNode,StartKey,EndKey,CalculateAverages,.Level,.TotalNodes,.TotalNodesPages)
	}
	#; also check for the case where the global is large, but the subrange is tiny: 
	#; only one mid-level pointer to sample from
	Set SampleDepth=DataDepth-2
	Set rc=$$ViewBlockFromTop^%GSIZE(SampleDepth,Directory,StartKey,.FirstSampleBlock)
	If ((rc=-1)||(rc=0)||($EXTRACT(rc,1,2)="0,")) {
		Set Status=$$$ERROR($$$GeneralError,"Failed to retrieve the first sample-depth pointer, calculation ending.")
		Return Status
	}
	view FirstSampleBlock
	set NextPageKey=$v(-1,-6)
	if NextPageKey]EndKey {
		Return ..GetGlobalSizeBySubscriptPrecise(Directory,BlockSize,MaxSize,Block,StartingNode,EndingNode,StartKey,EndKey,CalculateAverages,.Level,.TotalNodes,.TotalNodesPages)
	}
	#; Proceed with the stochastic estimate.
	#; First count the blocks in the levels above the sample depth.
	Set Level=1
	f  {
		Quit:(Level>=SampleDepth)
		v Block
		s Count=Count+1
		s Type=$$$type q:(Type=6!(Type=70))
		f i=1:1 {
			set StartNodeKey=$v(2*i-1,-6)
			#;Get the block previous to the one we are looking at for the down pointer
			if ((StartNodeKey]StartKey))||(StartNodeKey="") {
				set NextLevelBlock=$v(2*(i-1),-5)
				quit
			}
			if StartKey=StartNodeKey {
				s NextLevelBlock=$v(2*i,-5)
				quit
			}
		}
		s Level("Blocks",Level)=Level("Blocks",Level)+1
		#;We are at the first page in the level we are starting to count. Now follow right links until end
		f  {
			s Block=$$$link
			i Block=0 {
				s Block=NextLevelBlock
				s Level=Level+1,Level("Blocks",Level)=0
				quit
			}
			v Block
			s Count=Count+1
			i (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
				s Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
				Return Status
			}
			s NextPageKey=$v(-1,-6)
			i (NextPageKey]EndKey) {
				s Block=NextLevelBlock
				s Level=Level+1,Level("Blocks",Level)=0
				quit
			}
		}
	}

	#; Traverse the level above the bottom-level pointers and sample stochastically
	set Block=NextLevelBlock
	set ChildCount=0,SampleArray=0,first=1,last=0,end=0
	for {
		quit:('Block)
		v Block
		s Type=$$$type q:(Type=6!(Type=70))
		s Count=Count+1
		set Level("Blocks",Level)=Level("Blocks",Level)+1

		#; Check if this is the final parent/midlevel pointer.
		set NextPageKey=$v(-1,-6)
		if NextPageKey]EndKey {
			set last=1
		}

		#; Iterate over the children and sample ones within range.
		for i=1:1 {
			set Key=$view(2*i-1,-6)
			set Pointer=$view(2*i,-5)
			Quit:Key=""
			#; if we haven't found the starting child yet, find it
			if first {
				if (Key]StartKey)||(Key="") {
					set previous=$v(2*(i-1),-5)
					set SampleArray($INCREMENT(SampleArray))=previous
					set ChildCount=ChildCount+1,Count=Count+1
					set SampleArray("first")=previous
					set first=0
				} 
				elseif StartKey=Key {
					set SampleArray("first")=Pointer
					set first=0
				}
				else {
					continue
				}
			}
			#; if this is the last parent, check each bottom pointer 
			#; to see if it's the last one
			if last {
				view Pointer
				set NextPageKey=$v(-1,-6)
				if NextPageKey]EndKey {
					set end=1
					set SampleArray("last")=Pointer
				}
				set StartNodeKey=$v(1,-6)
				if StartNodeKey]EndKey {
					set end=1
					set SampleArray("last")=Pointer
				}
				view Block
			}
			#; stochastically choose whether to replace a sampled pointer with this one,
			#; or just add to the sample array if not at capacity yet
			set ChildCount=ChildCount+1,Count=Count+1
			if (SampleArray<SampleSizePointers) {
				set SampleArray($INCREMENT(SampleArray))=Pointer
			} else {
				set AddToSample=$random(ChildCount)<SampleArray
				if AddToSample {
					set Index=$random(SampleArray)+1
					set SampleArray(Index)=Pointer
				}
			}
			#; check count limit
			i (MaxSize'=0),((Count*BlockSize/(1024*1024))>MaxSize) {
				s Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
				Return Status
			}
			#; quit if we've reached the edge of the range
			Quit:(end)
		}
		#; We are done sampling this pointer block's children.
		#; Check whether to continue to the next one or if this was the last.
		Quit:(last||end)
		#; This wasn't the last pointer to sample from, so get the next and continue
		Set Block=$$$link
	}
	#; we know the number of bottom pointers, so just set it here
	s Level("Blocks",Level+1)=ChildCount

	#; If we didn't find any bottom pointers within the subscript range,
	#; then assume the actual block count is either zero or negligible and return.
	If SampleArray=0 {
		Return $$$OK
	}

	#; This will be the multiplier to apply to the data blocks count
	Set Multiplier=ChildCount/SampleArray
	Set Level=Level+1

	#; Step 4: traverse the bottom pointers sample and collect a sample 
	#; of data block pointers, noting which ones contain big strings
	Set Level("Blocks","BigStrings")=0
	Merge ParentArray=SampleArray
	Kill SampleArray
	Set SampleArray=0,ChildCount=0,BigStringCount=0,first=1,end=0
	For i=1:1:ParentArray {
 		k SizePage
 		s NumSizePage=0
		view ParentArray(i)
		#; count the number of data blocks in this bottom pointer,
		#; and identify ones that hold big strings
		for j=1:1 {
			set Pointer=$view(j*2,-5)
			quit:Pointer=""
			#; handle the starting edge of the range
			if (first) && (ParentArray(i)=$get(ParentArray("first"))) {
				set StartNodeKey=$view(j*2-1,-6)
				if ((StartNodeKey]StartKey))||(StartNodeKey="") {
					#; not adding the previous-page data block for now
					//set SampleArray($INCREMENT(SampleArray))=previous
					set previous=$v(2*(j-1),-5)
					set SampleArray("first")=previous
					set first=0
				}
				elseif StartKey=StartNodeKey {
					set SampleArray("first")=Pointer
					set first=0
				}
				else {
					continue
				}
			}
			#; handle the ending edge of the range
			if ParentArray(i)=$get(ParentArray("last")) {
				set StartNodeKey=$view(j*2-1,-6)
				#; if we're beyond the range, stop sampling from this block
				Quit:(StartNodeKey]EndKey)
				set SampleArray("last")=Pointer
			}
			#; If it's an in-range data block pointer, count it.
			#; If it contains a big string, count and stochastically add to the sample.
			Set Data=$v(2*j,-6)
 			i CalculateAverages {
	 			s NumSizePage=NumSizePage+1
 				s SizePage(NumSizePage)=Data
 			}
			set IsBigString=($p(Data,",")=1),BigStringPointer=$p(Data,",",2)
			set ChildCount=ChildCount+1,Count=Count+1,BigStringCount=BigStringCount+IsBigString
			set AddToSample=(IsBigString && ($random(BigStringCount)<SampleSizeLeaves))
			if AddToSample {
				if (SampleArray<SampleSizeLeaves) {
					set SampleArray($INCREMENT(SampleArray))=BigStringPointer
				}
				else {
					set Index=$random(SampleArray)+1
					set SampleArray(Index)=BigStringPointer
				}
			}
			#; Do not exceed a certain count size
			if (MaxSize'=0),((Count*BlockSize/(1024*1024))>MaxSize) {
				set Status=$$$ERROR($$$GeneralError,"Size calculation for "_StartingNode_":"_EndingNode_" in "_Directory_" exceeds maximum value of "_MaxSize)
				return Status
			}
		}
		i NumSizePage {
			s Pct=.02
			s NumPages=NumSizePage*Pct\1
			i NumPages<1 s NumPages=1
			k Selected
			s TotalNodesPages=TotalNodesPages+NumPages
			f k=1:1:NumPages {
		#;Don't sample the same page twice.
				d  { s RandomPage=$r(NumSizePage)+1 } While ($d(Selected(RandomPage)))
				s Selected(RandomPage)=1
				s SizePage=SizePage(RandomPage)
				v +$p(SizePage,",",2)
		#;Count number of nodes.		
				For N=1:1 {
					Set X=$V(N-1*2+1,-6)
					Quit:X=""
				}
				s N=N-1
				s TotalNodes=TotalNodes+N
			}
		}
	}
	#; Number of data block leaves seen in this bottom pointer sample
	Set Level("Blocks",Level+1)=$number(Multiplier*ChildCount,0)

	#; Step 5: measure the big strings in the big string pointer sample.
	#; Try-catch: if block structure changed, trap the error and ignore it
	Set BigBlockCount=0
	Try {
		for idx=1:1:SampleArray {
			set BigBlock=SampleArray(idx)
			view BigBlock
			#; check we're not going over the count traversal limit
			s Count=Count+1
			if (MaxSize'=0),(((Count*BlockSize)/(1024*1024))>MaxSize) {
				set Status=$$$ERROR($$$GeneralError,"Size calculation exceeds maximum value of "_MaxSize_", calculation ending")
				quit
			}
			f i=1:1 {
				s StartNodeKey=$v(2*i-1,-6)
				q:StartNodeKey=""
				i ((StartNodeKey]StartKey)||(StartKey=StartNodeKey))&&(EndKey]StartNodeKey) {
					s Data=$v(2*i,-6)
					#;RJF519 (JO3199): Change to macro for bigstring test
					if $$$gdviewisbigstr($a(Data)) {
						s BigBlockCount=BigBlockCount+$p(Data,",",2)
					}
				}
			}
		}
	} Catch {}
	#; Apply one more term to the multiplier to scale big strings up to the population size.
	If (SampleArray > 0) {
		set Multiplier=Multiplier*BigStringCount/SampleArray
	}
	Set Level("Blocks","BigStrings")=$number(BigBlockCount*Multiplier,0)
	Return Status
	}
	Catch(err){
		return err.AsStatus()
	}
}

/// Encode a Global reference.<br>
ClassMethod EncodeKey(GblRef As %String, Rule As %Integer, ByRef Key As %String) As %Status [ Internal ]
{
 s $zt="Error"
 k Key
 i $$$IsUnicode {
	s MaxChar=$c(65535)
 } else {
	s MaxChar=$c(255)
 }
  i $e(GblRef)="^" {
	 s ISCNewGblRef=$e(GblRef,2,*)
 } else {
	 s ISCNewGblRef=GblRef
 } 
 s:$e(ISCNewGblRef)="|" ISCNewGblRef=$p(ISCNewGblRef,"|",3,*) 
 s Key=$p(ISCNewGblRef,"(") 
 f i=1:1:$ql("^"_ISCNewGblRef) {
	s Sub=$qs("^"_ISCNewGblRef,i)
	f  {
		s Ok=0
#;Encode each subscript. If we get a subscript error, the reference may have been padded
#;with $c(MaxChar). If so, remove them up until we can contruct a valid subscript.
		Try {
			s EncSub=$zu(70,2,Sub,+Rule) 
			s Ok=1
		} catch {
			i $e(Sub,*)=MaxChar {
				s Sub=$e(Sub,1,*-1)
			} else {
				Throw
			}
		}
		q:Ok
	}
 	s Key=Key_$c(0)_$zu(70,2,Sub,+Rule)
 }
 q $$$OK
Error s $zt=""
 k Key
 i ($ze["SUBSCRIPT")||($ze["FUNCTION") {
	 s Status=$$$ERROR($$$GlobalReferenceInvalid,GblRef)
 } else {
	s Status=$$$ERROR($$$ObjectScriptError,$ze)
 }
 d BACK^%ETN
 q Status
}

/// Kill a subscripted range of a single global in a single database.<br>
/// This method will kill a range of globals node of a single global in a single database. The starting
/// and ending global name must be the same. When a range is specified, the global is killed from the
/// starting node up to but not including the ending node. The exception to this is if the starting and 
/// ending node is the same then that global is killed. The start and end nodes must not contain namespace
/// specifications. Process private globals are not supported. Note that this method ignores all namespace
/// specifications.<br>
/// Parameters:<br>
/// Directory - Location of global to kill.<br>
/// StartingNode - First node of global range to kill. Note that you can specify ^GLOBAL(BEGIN) to mean the start of the global.
/// This includes the global ^GLOBAL itself
/// You can also specify ^GLOBAL("XXX"_$c(1)_"*next)" to mean start deleting after global ^GLOBAL("XXX").<br>
/// EndingNode - Ending node of global range to kill, up to, but not including this node. Note that you can specify 
/// ^GLOBAL(END) to mean through the end of the global.<br><br>
/// Return Values: <br>
/// The method will return a %Status value of success, or an error.<br><br>
/// Examples:<br>
/// Kill nodes between ^X(1,5) and ^X(1,50), not including ^X(1,50)<br>
/// s Status=##Class(%GlobalEdit).KillRange("c:\db1\","^X(1,5),"^X(1,50)")<br><br>
/// Kill node ^X(500) and all subnodes<br>
/// s Status=##Class(%GlobalEdit).KillRange("c:\db1\","^X(500),"^X(500)")<br><br>
/// Kill everything after node ^X(500)<br>
/// s Status=##Class(%GlobalEdit).KillRange("c:\db1\","^X(500"_$c(1)_"*next)","^X(END)")<br><br>
/// Kill everything from the beginning of the node up to but not including ^X(500)<br>
/// s Status=##Class(%GlobalEdit).KillRange("c:\db1\","^X(BEGIN)","^X(500)")<br><br>
ClassMethod KillRange(Directory As %String, StartingNode As %String, EndingNode As %String) As %Status
{
#;This is the same definition as Above. Change it here and there!
 s $zt="Error"
 s Status=$$$OK
 #;SML1968+ ; If the nodes are explicit reference then change them to implicit reference.
 s StartNode=$s($e(StartingNode,2)="|":"^"_$p(StartingNode,"|",3,*),1:StartingNode)
 s EndNode=$s($e(EndingNode,2)="|":"^"_$p(EndingNode,"|",3,*),1:EndingNode)
 i $e(StartNode)'="^" s StartNode="^"_StartNode
 i $e(EndNode)'="^" s EndNode="^"_EndNode
 #;SML1968-
 s Info=$zu(49,Directory)
 i Info<-1 {
	s Status=$$$ERROR($$$DatabaseDoesNotExist,Directory)
	q Status
 }
 i Info=-1 {
	s Status=$$$ERROR($$$DatabaseIsDismounted,Directory)
	q Status
 }
#;Nodes must start with "^", and must not have a namespace or directory specification
 i $p(StartNode,"(")'=$p(EndNode,"(") q $$$ERROR($$$MGBLStartAndEndGlobalDiffer)
 i ($e(StartNode)'="^")||("|["[$e(StartNode,2)) q $$$ERROR($$$GlobalReferenceInvalid,StartNode)
 i ($e(EndNode)'="^")||("|["[$e(EndNode,2)) q $$$ERROR($$$GlobalReferenceInvalid,EndNode)
#;Make sure the global node exists 
 s GloName=$p(StartNode,"(")
 s Info=$zu(167,6,7,Directory,GloName)
 i (+Info<0) {
	i Info=-2 q $$$OK  ; Don't return $$$ERROR($$$GlobalNotFound,GloName)
	q $$$ERROR($$$MGBLUnableToGetDirInfo,Directory,GloName,Info)
 }
 s Rule=$zu(70,1,+$p(Info,"^",2))
#;Process the EndNode first, and encode the key for it.
#;If we specify (END), we want to delete all the globals at this level. We could have a global with
#;a subscript like ^X($c(65535)_"A"). 
#;So lets just get a string with 511 $c(65535) concatenated together (max subscript).
 i $$$IsUnicode {
	s $p(EndRange,$c(65535),511)=""
 } else {
	s $p(EndRange,$c(255),511)=""
 } 
#;^X("D"$c(1)_*Next) really means ^X("D",END)
 i $zcvt($e(EndNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s EndNode=$e(EndNode,1,*-7)_",END)"
 }
 i $e(EndNode,$l(EndNode)-3,$l(EndNode))="END)" {
	s EndNode=$e(EndNode,1,$l(EndNode)-4)_""""_EndRange_""""_")"
 }
 s Status=..EncodeKey(EndNode,Rule,.EndKey)
 i '$$$ISOK(Status) q Status
#;We need to handle ^X(BEGIN):^X(20) special.
#;Transform this to ^X:^X(20) which is according to the SLM mapping rules. 
#;^X is included in the ^X(BEGIN):^X(20) range.
 i $e($p(StartNode,"(",2),1,6)="BEGIN)" {
	 s StartNode=$p(StartNode,"(",1) 
 }
#;See if we have a range like ^X:^X(20). Change StartNode to ^X(""):^X(20),
#;and zkill ^X and ^X(""). Trap any errors (SUBSCRIPT) and ignore.
 i $p(StartNode,"(",2)="" {
	Try {zk @("^|""^^"_Directory_"""|"_$e(StartNode,2,*))} catch {}
#;Handle ^A:^A
	i StartNode'=EndNode s StartNode=StartNode_"("""")"
 }
#;Convert ^X(123,...,BEGIN) to ^X(123,...,"") and zkill ^X(123,...,"")
#;Trap any errors (SUBSCRIPT) and ignore.
 i $e(StartNode,$l(StartNode)-5,$l(StartNode))="BEGIN)" {
 	s StartNode=$e(StartNode,1,$l(StartNode)-6)_""""""_")"
 }
#;Convert ^X(123,10_$c(1)_"*next)" to ^X(123,10,$c(255...)). Then do a $Query(StartNode)to get the
#;first node we care about
 i $zcvt($e(StartNode,*-6,*),"U")=$zcvt(($c(1)_"*next)"),"U") {
	s StartNode=$e(StartNode,1,*-7)_","_""""_$e(EndRange,1,32)_""""_")"
#;Now adjust the StartNode to the next node using $Q. If there is no node, or
#;we are past the Ending node, then we are done.
	Try {
		s StartNode=$q(@("^|""^^"_Directory_"""|"_$e(StartNode,2,*)))
	} catch {
		s Status=$$$ERROR($$$GlobalReferenceInvalid,StartingNode)
	}
	i '$$$ISOK(Status) q Status
	i StartNode="" q $$$OK
#;Strip directory spec
	s StartNode="^"_$p(StartNode,"|",3,*)
	s Status=..EncodeKey(StartNode,Rule,.StartKey)
	i '$$$ISOK(Status) q Status
	i (StartKey=EndKey)||(StartKey]EndKey) q $$$OK
 }	 
#;Handle the same start and end subscript first
 i StartNode=EndNode {
	 #;SML1968
	 k @("^|""^^"_Directory_"""|"_$e(StartNode,2,*))
	 q $$$OK
 }
 s Status=..EncodeKey(StartNode,Rule,.StartKey)
 i '$$$ISOK(Status) q Status
 i StartKey]EndKey q $$$ERROR($$$GblEndNodeAfterBeginNode,StartingNode,EndingNode)
 #;SML1968+ ; Make StartNode an explicit reference. Trap if startnode is ^X("")
 s StartNode="^|""^^"_Directory_"""|"_$e(StartNode,2,*)
 Try {zk @StartNode} Catch {}
 #;SML1968-
 s Prefetch=$p(StartNode,"(")
 s x=$prefetchon(@Prefetch)
#;First, find the level at which the wedge start and end nodes have the same level of subscripts. If
#;no subscripts on the first reference, set Level to 1, and we'll use a first subscript on the first
#;level="", and handle the top level with a zkill later.
 s StartNumSubs=$ql(StartNode)
 s EndNumSubs=$ql(EndNode)
 i StartNumSubs<EndNumSubs {
	 s SubLevel=StartNumSubs
 } else {
	 s SubLevel=EndNumSubs
 }
#;Now find the first level where the begin subscript is not = end subscript
 s Found=0
 f i=1:1:SubLevel i $qs(StartNode,i)'=$qs(EndNode,i) s Found=1 q
 i Found {
 	s SubLevel=i
#;Get the ending subscript on this level. We want to kill everything between the start and end
#;subscript on this level
	s EndSub=$qs(EndNode,SubLevel)
#;Construct the starting node at this level
 #;SML1968
 	i '$system.Process.RefInKind() {
	 	s Node=$name(@StartNode,SubLevel)
 	} else {
	 	s Node="^|""^^"_Directory_"""|"_$p($name(@StartNode,SubLevel),"^",2,*)
 	}
#;If we have the same number of subscripts for start and end range, and the level is the same
#;as number of subscripts, then just kill the first node.
#;For example ^X(5):^X(10), then kill ^X(5)
#;If ^X(5,9):^X(10) we can't k ^X(5), we must $query through the first part of the global (below)
#;But if we have a range which has a starting subscript as "", then trap the SUBSCRIPT error, 
#;and we will handle it below. 
	Try {
		i (SubLevel=StartNumSubs) k @Node
	} catch {}
#;Now prune the wedge, until we meet the subscript at the same level on the ending node. 
	f  {
#;Keep looping and killing until:
#;1)Subscript is equal or greater than the end subscript at this level
#;  or
#;2)We are at the end of the global
		s Next=$o(@Node) q:(Next]]EndSub)||(Next=EndSub)||(Next="")
		k @$zr
 	}
 }
#;Now we can $query through the remaining nodes until we hit the end range
 s Status=$$$OK
 s NextNode=StartNode
 f  {
	s NextNode=$q(@NextNode) q:NextNode=""
	s Status=..EncodeKey(NextNode,Rule,.NextNodeKey)
	i '$$$ISOK(Status) q
	q:(NextNodeKey=EndKey)||(NextNodeKey]]EndKey)
	zk @NextNode
 }
 i $d(Prefetch) s x=$prefetchoff(@Prefetch)
 i '$$$ISOK(Status) q Status
 q $$$OK
Error s $zt=""
 i $d(Prefetch) s x=$prefetchoff(@Prefetch)
 #;SML1968 ;i $d(OldNS) zn OldNS
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 d BACK^%ETN
 q Status
}

/// Replaces "BEGIN","END", and "*next" in a global subscript with subscripts 
/// with real meaning where a $Query, or $Data can be executed on it. If Directory
/// is not "", then prepends the directory specification to it. 
/// Flags = 0 - Start subscript
/// Flags = 1 - End Subscript
ClassMethod TranslateBEGINandEND(Directory As %String = "", Node As %String, Flags As %Integer) As %String [ Internal ]
{
#;No error trapping here. Shouldn't get one. Let the caller handle it.
#;Number of $c(255) or $c(65535) characters we pad the last subscript with for "END"
#define EndNodeSubPadSize $case($$$IsUnicode,1:10,:5)
#define EndNodeSubPadChar $case($$$IsUnicode,1:$c(65535),:$c(255))
 s NewNode=Node
 i $e(NewNode)="^" s NewNode=$e(Node,2,*)
 s quote=""""
 s $p(EndRange,$$$EndNodeSubPadChar,$$$EndNodeSubPadSize)=""
 i Flags=0 {
#;If we have ^X(BEGIN) it really means ^X, not ^X("")
	i NewNode["(BEGIN)",NewNode'[quote s NewNode=$p(NewNode,"(",1)
	i NewNode["BEGIN)",NewNode'[quote s NewNode=$replace(NewNode,"BEGIN","""""")
#;If using ^X(10_$c(1)_"*next)", it means start at the global after ^X(10). Skip over the $d() to the $q()
	i NewNode[($c(1)_"*next)") s NewNode=$replace(NewNode,$c(1)_"*next",","""_EndRange_"""")
 } Else {
#;Add $c(255) or $c(65535) to end
	i NewNode["(" {
		i $e(NewNode,$l(NewNode)-3,*)="END)" s NewNode=$replace(NewNode,"END",""""_EndRange_"""")
		i NewNode[($c(1)_"*next)") s NewNode=$replace(NewNode,$c(1)_"*next",","""_EndRange_"""")
 	} 
 }
 i Directory'="" s NewNode="^|""^^"_Directory_"""|"_NewNode
 q NewNode
}

Method GrowthBlockSet(Arg As %String) As %Status
{
 If (+Arg'=Arg) q $$$ERROR($$$BadParameter)
 Set i%GrowthBlock=+Arg
 q $$$OK
}

Method IsKeepSet(Arg As %Boolean) As %Status
{
 i (Arg=0)!(Arg=1) {
	 s i%IsKeep=Arg
	 q $$$OK
 }
 Quit $$$ERROR($$$BadParameter)
}

/// Set the Global name.
/// <br>
/// If prefaced by a "^" strip it off
Method NameSet(Arg As %String) As %Status
{
 i i%Exists q $$$ERROR($$$CannotModifyProperty)
 s:$e(Arg)="^" Arg=$e(Arg,2,$l(Arg))
#;Let the name be set if it is invalid. Rarely is the set
#;actually tested for correctness in the user's code. We'll test again 
#;before we actually save the global. This allows the error message in 
#;%SaveData to actually return the correct error
 s Status=$$$OK
 s i%Name=Arg
 i '..IsValidName(i%Name) s Status=$$$ERROR($$$NotALegalName,Arg)
 q Status
}

Method PointerBlockSet(Arg As %String) As %Status
{
 i i%Exists q $$$ERROR($$$CannotModifyProperty)
 If (+Arg'=Arg) q $$$ERROR($$$BadParameter)
 Set i%PointerBlock=+Arg
 q $$$OK
}

Storage GlobalStorage
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^Library.GlobalEditS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
