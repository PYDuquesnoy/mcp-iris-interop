/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %sySystem, %syLock)

/// Provide Interface for users to read lock table information in the system. 
/// <class>SYS.Lock</class> is used to perform management operations.
/// <br>
/// <br>
/// <b>Filter  Specification</b><br><br>
/// The argument to the Rset.Execute() method selects which subset of the current
/// locks to return. The first character of the 'id' argument determines the category of the locks to be collected.
/// This has various forms as described below.
/// <br>
/// 1) Null String or "*" - All locks. When the 'id' is a null string (default value when no id specified) or "*", it collects all locks in the lock table.
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks in lock table.
/// Do Rset.Execute("")
///  
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks in lock table.
/// Do Rset.Execute()
/// </example>
/// 2) 'P' or numeric - Process ID. Collect all locks owned by the job with the specified process ID. If the 'id' is a numeric value without a leading 'P', it is treated as a process ID.<br>
/// For all systems the process ID is in decimal form.<br>
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by a process whose process ID is 2004.
/// Do Rset.Execute("P2004")
///  
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by a process whose process ID is 2004.
/// Do Rset.Execute("2004")
/// </example>
/// 3) 'J' - Internal job number. Collect all locks owned by the job with the specified internal job number.<br>
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by a process whose internal job number is 20.
/// Do Rset.Execute("J20")
/// </example>
/// 4) 'C' - Remote client system Name. Collect all locks owned by the remote client system with the specified name.<br>
/// The Name can be one of the names displayed in the 'Process ID' column of the ^LOCKTAB utility.<br>
/// When the string following the leading 'C' is empty, it collects all locks owned by jobs of the local system.<br>
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by jobs of local system.
/// Do Rset.Execute("C")
///  
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by remote client named 'SystemA'.
/// Do Rset.Execute("CSystemA")
/// </example>
/// 5) 'S' - Remote server system Name. Collect all locks sent to the specified remote system.<br>
/// When the string following the leading 'S' is empty then it collects all locks kept on the local system.<br>
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks on the local system.
/// Do Rset.Execute("S")
///  
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks sent to remote server named 'SystemA'.
/// Do Rset.Execute("SSystemA")
/// </example>
/// 6) 'N' - Network Protocol. Collect all locks owned by the remote client system through the network protocol. The protocol can be:
/// <ul><li>"ECP" - The owner is an ECP remote client system.</li>
/// <li>"" - The owner is a remote client system of any protocol.</li></ul>
/// Example:
/// <example>
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by remote ECP clients.
/// Do Rset.Execute("NECP")
///  
/// Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
/// //Collect all locks owned by remote clients.
/// Do Rset.Execute("N")
/// </example>
Class %SYS.LockQuery Extends %SYSTEM.Help [ Abstract, Final, SqlTableName = "", StorageStrategy = "", System = 4 ]
{

/// Check if any remote system owns any lock in the system.<br>
/// Return TRUE(1) if there is any lock owned by the specified network type, otherwise return FALSE(0).<br>
/// <br>
/// The NetType argument specifies the network type of the remote system.<br>
/// It has following value:
/// <ul><li>"NECP" - The remote system owned the lock through ECP network.</li>
/// <li>"N" or "" - The null string (Default) means any network type.</li></ul>
/// For un-recognized network type this method will return FALSE.<br>
/// Example:
/// <example>
/// // Return 1 if any lock is owned by remote ECP client.
/// Set rc=##Class(%SYS.LockQuery).AnyRemoteOwnedLocks("NECP")
///  
/// // Return 1 if any lock is owned by any remote client.
/// Set rc=##Class(%SYS.LockQuery).AnyRemoteOwnedLocks("N")
/// </example>
ClassMethod AnyRemoteOwnedLocks(NetType As %String = "") As %Boolean
{
	Set Rset=##class(%ResultSet).%New("%SYS.LockQuery:List")
	#; Query locks owned by network type DCP.
	If NetType="" s NetType="N"
	Do Rset.Execute(NetType)
	#; If any one exists, the query for Next will return true.
	Quit Rset.Next()
}

/// Convert a remote client system name to internal system number.
ClassMethod ClientSysNameToSysNum(SysName As %String = "") As %Integer [ Internal, Private ]
{
	#; get system name transaltion table.
	If ..GetLockSysNameTable(.systems,.bytes2,.sysn2)
	I '$d(sysn2(1,SysName),val) s val=-1
	Quit val
}

/// Convert a remote client system number to client system name.
ClassMethod ClientSysNumToSysName(SysNum As %Integer = 0) As %String [ Internal, Private ]
{
	#; get system name transaltion table.
	If ..GetLockSysNameTable(.systems,.bytes2,.sysn2)
	I '$d(sysn2(2,SysNum),val) s val=""
	Quit val
}

/// Common Execute codes for List and Detail query.
ClassMethod CommonExecute(ByRef qHandle As %Binary, id As %String, Flag As %Integer) As %Status [ Internal, Private ]
{
	#; get system name transaltion table.
	If ..GetLockSysNameTable(.systems,.bytes2,.sysn2)
	#; set up pid,clin,ntype,svrn according to the requesting id string.
	#;SML2050 ; Set the NoLineRoutine according to the Flags.
	s NoLineRoutine=0 if Flag=3 s Flag=2,NoLineRoutine=1
	S id=..TranslateID(id)
	s pid=$p(id,",",1)
	s clin=$p(id,",",2)
	s ntype=$p(id,",",3)
	s svrn=$p(id,",",4)
	s $zt="ngathererr"
	s nulsub=$zu(68,1,1)
	s Index=$i($$$ISCQUERYTEMP)
	s TEMPGLO=$name($$$ISCQUERYTEMP(Index))
	k @TEMPGLO
	s GAIndex=$i($$$ISCQUERYTEMP)
	s TEMPGAGLO=$name($$$ISCQUERYTEMP(GAIndex))
	k @TEMPGAGLO
	#;SML2050+ setup PPG for keeping the line/routine info.
	s TMPLRGLO=$name(^||%ISCLockTemp($j))
	k @TMPLRGLO
	#;SML2050-
	#; If the criteria specified is bad then do get any entry and quit.
	I pid'=-1&(clin'=-2)&(ntype'=-1)&(svrn'=-2) {
		S INDEX=0,BADINDEX=0
		S lock=$LB("") F  S lock=$$$LockOrder($LI(lock),pid,Flag) Q:lock=""  DO
		. F i=2:1:$LISTLENGTH(lock) DO
		. . s lent=$LI(lock,i),nOwner=$$$LockTotalOwner(lent)
		. . i ntype>0!(clin'<0) S found=0 Do  q:found=0
		. . . F nn=1:1:nOwner Do  q:found
		. . . . s sys=$$$LockOwnerSYSID($$$LockOwner(lent,nn))
		. . . . I ntype>0,sys,$$NTypeMatch(sys,ntype) s found=1 q
		. . . . I clin'<0,sys=clin s found=1 q
		. . i svrn'<0 s sys=$$$LockGetSys($$$LockNNSFN(lent)) q:sys'=svrn
		. . d BuildRow(lent,Flag)
		S lock=TEMPGAGLO F  S plock=lock,lock=$Q(@lock) Q:lock=""  Q:$qs(lock,1)'=GAIndex  DO
		. S INDEX=INDEX+1,@TEMPGLO@(INDEX)=@lock
		. q:plock=TEMPGAGLO
		. i $qs(lock,2)'=$qs(plock,2) s plock=$name($$$ISCQUERYTEMP(GAIndex,$qs(plock,2))) k @(plock) q
		. i $qs(lock,3)'=$qs(plock,3) s plock=$name($$$ISCQUERYTEMP(GAIndex,$qs(plock,2),$qs(plock,3))) k @(plock) q
		k @TEMPGAGLO
		#;SML2050
		k @TMPLRGLO
	}
ngathererr
	s nulsub=$zu(68,1,nulsub)
	s qHandle=Index_"^"
	Quit $$$OK
NTypeMatch(sys,ntype) ; Check if the owner sys # matchs the protocol. 1 -> yes. 0 -> no.
	s $zt="MatchErr"
	#; network type 100 means any remote protocol.
	i ntype=100 q 1
	s sys=$zu(89,2,sys)
	q sys=ntype
MatchErr ;
	q 0
BuildRow(info,Flag)
	S nnsfn=$$$LockNNSFN(info),rem=$$$LockGetSys(nnsfn),REM=""
	I rem S REM=$ZU(63,4,rem)
	S ref=$$$LockString(info)
	#;SML394+
	I $e(ref,$l(ref))="*" s ref=$e(ref,1,$l(ref)-1),nodelock=1
	Else  s nodelock=0
	#;SML394-
	S REF=$$nref(ref,REM,nnsfn,.dir) ;w/ machine name!
	If nnsfn'=$$$LockLOCALSFN s nnsnf=$$$LockMaskOffDmn(nnsfn),ref="^"_ref
	Else  S nnsfn=0  ; the local lock is %SYS namespace.
	s ownersys=$$$LockTotalOwner(info)
#;SML1455, SML1718 ; add iOwner for internal job number owner.
	s (Owner,Counts,Mode,EscalateInfo,iOwner)=""
#;TCS015+
	s rmtowner=""
#;TCS015-
	f loc=1:1:ownersys d
#;SML1718 ; iow is the lr_tid in the LRB.
	. s ow=$$$LockOwner(info,loc),iow=$$$LockOwnerTID(ow)
	. s sn=$ZU(89,1,0,$$$LockOwnerSYSID(ow))
#if 0   ;SML457+
	. S owid=$$getownerid(sn,$$$LockOwnerPID(ow),Flag)
#else   ;SML457=
	. S owid=$$getownerid(sn,$$$LockOwnerPID(ow),$$$LockOwnerRemPID(ow),Flag)
#endif  ;SML457-
#;TCS015+
	. s ormtow=(sn'=0)
#;TCS015-
	. If $$$LockOwnerXcnt(ow) Do
	. . S Mode="X"
#;SML1455
	. . S EscalateInfo=$$$LockOwnerFlag2(ow)_"^"_$$$LockOwnerEscalatableXcnt(ow)_"^"_$$$LockOwnerEscalatedXcnt(ow)_"^"_$$$LockOwnerDelayEscalatableXcnt(ow)_"^"_$$$LockOwnerDelayEscalatedXcnt(ow)
	. . S Counts=$$$LockOwnerXcnt(ow)_$s($$$LockXDelayed($$$LockOwnerFlag(ow)):"D",1:"")
#;SML1718 ; setup iOwner
	. . S Owner=owid,iOwner=iow
#;TCS015+
	. . S rmtowner=ormtow
#;SML1455, SML1718 ; setup iOwner
	. If $$$LockOwnerZAXcnt(ow) S Mode="ZAX",Counts="",Owner=owid,rmtowner=ormtow,EscalateInfo="",iOwner=iow
#;TCS015-
	. If $$$LockOwnerScnt(ow) Do
#;SML1455
	. . S escainfo=$$$LockOwnerFlag2(ow)_"^"_$$$LockOwnerEscalatableScnt(ow)_"^"_$$$LockOwnerEscalatedScnt(ow)_"^"_$$$LockOwnerDelayEscalatableScnt(ow)_"^"_$$$LockOwnerDelayEscalatedScnt(ow)
	. . S cnt=$$$LockOwnerScnt(ow)_$s($$$LockSDelayed($$$LockOwnerFlag(ow)):"D",1:"")
	. . If Mode=""!(Mode="S") Do
	. . . S Mode="S"
	. . . s Counts=Counts_$s(Counts="":cnt,1:","_cnt)
#;SML1455
	. . . s EscalateInfo=EscalateInfo_$s(EscalateInfo="":escainfo,1:","_escainfo)
	. . . s Owner=Owner_$s(Owner="":owid,1:","_owid)
#;SML1718 ; setup iOwner
	. . . s iOwner=iOwner_$s(iOwner="":iow,1:","_iow)
#;TCS015+
	. . . i ownersys=1!(Flag'=2) s rmtowner=ormtow!(+rmtowner)
	. . . e  s rmtowner=rmtowner_$s(rmtowner="":ormtow,1:","_ormtow)
#;TCS015-
#;SML1455
	. . If Mode="X"!(Mode="ZAX") S Counts=Counts_"|"_cnt,EscalateInfo=EscalateInfo_"|"_escainfo
	s LHFlag=$s(Mode="ZAX":"Z",1:"")
	I $$$LockLost(info) S LHFlag=LHFlag_"L"
	I REM]"" S LHFlag=LHFlag_"*"
	I $$$LockNeed(info)!$$$DelockPending(info) S LHFlag=LHFlag_"D"
	I $$$LockPending(info) S LHFlag=LHFlag_"P"
	#;SML394+
	I nodelock S LHFlag=LHFlag_"N"
	#;SML394-
	s delkey=$$$LockLHBaddr(info)_","_$$$LockLHBgen(info)_",,"
	if (Flag'=2) {
		s lrow=$ListBuild(delkey,Owner,Mode,LHFlag,Counts,nnsfn,ref,REF)
		#;SML2847 Check Flag = 4 for ConflictList
		If (Flag=1||(Flag=4)) {
			s (WaitPID,WaitMode,WaitType)=""
			s waitersys=$$$LockTotalWaiters(info)
			f loc=1:1:waitersys d
			. s wt=$$$LockWaiter(info,loc)
			. s sn=$ZU(89,1,0,$$$LockWaiterSYSID(wt))
#if 0   ;SML457+
			. S wtid=$$getownerid(sn,$$$LockWaiterPID(wt),Flag)
#else   ;SML457=
			. S wtid=$$getownerid(sn,$$$LockWaiterPID(wt),0,Flag)
#endif  ;SML457-
			. s WaitPID=WaitPID_$s(WaitPID="":wtid,1:","_wtid)
			. S wmode=$e("SXSXZ",$$$LockWaiterMode(wt))
			. s WaitMode=WaitMode_$s(WaitMode="":wmode,1:","_wmode)
			. S wtype=$$$LockWaiterType(wt)
			. s WaitType=WaitType_$s(WaitType="":wtype,1:","_wtype)
			s lrow=lrow_$ListBuild(WaitPID,WaitMode,WaitType)
#;TCS015+
#;SML1455
#;SML2847 Don't inlucde escalate info for ConflictList
			If Flag=1 s lrow=lrow_$ListBuild(rmtowner)_$ListBuild(EscalateInfo)
#;TCS015-
		}
		s key=$p(TEMPGAGLO,")")_","_nnsfn_","""_$qs(ref,0)_""""
		#;SML1336 ; create different entry for node and tree only for "Detail" query.
		#;SML2625 ; create different entries for node and tree for both 'Detail' and 'List' queries.
		#;SML3010 ; The row is now set in MakeKey.
		do MakeKey(key,ref,lrow,$s(nodelock:",""*"")",1:""))
		Quit
	}
	#; Flags is 2 here. it's a web list query.
	s key=$p(TEMPGAGLO,")")_","""_$s(REM'="":REM,1:" ")_""","""_dir_""","""_$qs(ref,0)_""""
	If LHFlag["L"!(LHFlag["D")!(LHFlag["P") {
		s Removable=$s(LHFlag["D":2,LHFlag["L":1,1:0)
		#;SML1336 ; tell it is a node lock or tree lock for U2.
		s mode=$s(LHFlag["L":"Lost",LHFlag["D":"DelockPending",1:$s(Mode="S":"SharePending",1:"LockPending"))_$s(nodelock:"_Node",1:"")
		#;SML1718 ; get internal owner job number
		s ow=$p(Owner,",",1),iow=$p(iOwner,",",1)
		s owx=$e(ow,2,$l(ow))
#;SML655+
		s owi=owx   ;Internal PID
#;SML655-
		s $p(delkey,",",3)=ow
#if 0   ;SML529+
		s lrow=$ListBuild(owx,mode,ref,dir,REM,Removable,delkey)
#else   ;SML529=
		#;SML1718 ; pass internal job number for ChkExamine()
		s lrow=$ListBuild(owx,mode,ref,dir,REM,Removable,delkey,$$ChkExamine(iow))
#endif  ;SML529-
#;TCS015+
#;SML655+
		s lrow=lrow_$ListBuild(+rmtowner,owi)
#;SML655-
#;TCS015-
		#;SML1704+, SML2050
		if +rmtowner||NoLineRoutine {
			s lrow=lrow_$ListBuild("")
		} else {
			#;SML1718 ; get the line number from the internal job number
			#;SML2050+ ; get the line/routine info from previous value if existed.
			if '$d(@TMPLRGLO@(iow),lrinfo) {
				s lrinfo=##CLASS(%SYS.ProcessQuery).GetCurrentLineAndRoutine(iow)
				s @TMPLRGLO@(iow)=lrinfo
			}
			s lrow=lrow_$ListBuild(lrinfo)
			#;SML2050-
		}
		#;SML1704-
		s tail=","""_mode_""","""_owx_""")"
		#;SML3010 ; The row is now set in MakeKey.
		do MakeKey(key,ref,lrow,tail)
	} Else {
		s Removable=1
		for ii=1:1:$l(Owner,",") {
			#;SML1336 ; tell it is a node lock or tree lock for U2.
			s mode=$s(Mode="X":"Exclusive",Mode="S":"Shared",1:"LockZA")_$s(nodelock:"_Node",1:"")
			#;SML1455+
			s cnt=$p(Counts,",",ii),einfo=$p(EscalateInfo,",",ii)
			If cnt["|" {
				s xeinfo=$p(einfo,"|"),seinfo=$p(einfo,"|",2)
				s xcnt=$p(cnt,"|"),scnt=$p(cnt,"|",2)
				s ebcnt=+$p(xeinfo,"^",2),edcnt=+$p(xeinfo,"^",3),ebdcnt=+$p(xeinfo,"^",4),eddcnt=+$p(xeinfo,"^",5)
				If +xcnt>1||$s(xcnt["D":(ebdcnt+eddcnt)>1,1:(ebdcnt+eddcnt)>0) {
					if xcnt["D" {
						s cnt=+xcnt-ebdcnt-eddcnt
						s ps="+" s:cnt=0 cnt="",ps=""
						i ebdcnt s cnt=cnt_ps_ebdcnt_"e",ps="+"
						i eddcnt s cnt=cnt_ps_eddcnt_"E"
						s mode=mode_"/"_cnt_"->Delock"
					} else {
						s cnt=+xcnt-ebcnt-edcnt
						s ps="+" s:cnt=0 cnt="",ps=""
						i ebcnt s cnt=cnt_ps_ebcnt_"e",ps="+"
						i edcnt s cnt=cnt_ps_edcnt_"E",ps="+"
						i ebdcnt s cnt=cnt_ps_ebdcnt_"de",ps="+"
						i eddcnt s cnt=cnt_ps_eddcnt_"dE"
						s mode=mode_"/"_cnt
					}
				} else {
					s xf=+$p(xeinfo,"^")
					if $$$LockXEscalatable(xf) s mode=mode_"_e"
					if $$$LockXEscalated(xf) s mode=mode_"_E"
					if xcnt["D" s mode=mode_"->Delock"
				}
				s mode=mode_",Shared"
				s ebcnt=+$p(seinfo,"^",2),edcnt=+$p(seinfo,"^",3),ebdcnt=+$p(seinfo,"^",4),eddcnt=+$p(seinfo,"^",5)
				If +scnt>1||$s(scnt["D":(ebdcnt+eddcnt)>1,1:(ebdcnt+eddcnt)>0) {
					if scnt["D" {
						s cnt=+scnt-ebdcnt-eddcnt
						s ps="+" s:cnt=0 cnt="",ps=""
						i ebdcnt s cnt=cnt_ps_ebdcnt_"e",ps="+"
						i eddcnt s cnt=cnt_ps_eddcnt_"E"
						s mode=mode_"/"_cnt_"->Delock"
					} else {
						s cnt=+scnt-ebcnt-edcnt
						s ps="+" s:cnt=0 cnt="",ps=""
						i ebcnt s cnt=cnt_ps_ebcnt_"e",ps="+"
						i edcnt s cnt=cnt_ps_edcnt_"E",ps="+"
						i ebdcnt s cnt=cnt_ps_ebdcnt_"de",ps="+"
						i eddcnt s cnt=cnt_ps_eddcnt_"dE"
						s mode=mode_"/"_cnt
					}
				} else {
					s xf=+$p(seinfo,"^")
					if $$$LockSEscalatable(xf) s mode=mode_"_e"
					if $$$LockSEscalated(xf) s mode=mode_"_E"
					if scnt["D" s mode=mode_"->Delock"
				}
			} ElseIf cnt'="" {
				if (Mode="X") {
					s xeinfo=einfo,xcnt=cnt
					s ebcnt=+$p(xeinfo,"^",2),edcnt=+$p(xeinfo,"^",3),ebdcnt=+$p(xeinfo,"^",4),eddcnt=+$p(xeinfo,"^",5)
					If +xcnt>1||$s(xcnt["D":(ebdcnt+eddcnt)>1,1:(ebdcnt+eddcnt)>0) {
						if xcnt["D" {
							s cnt=+xcnt-ebdcnt-eddcnt
							s ps="+" s:cnt=0 cnt="",ps=""
							i ebdcnt s cnt=cnt_ps_ebdcnt_"e",ps="+"
							i eddcnt s cnt=cnt_ps_eddcnt_"E"
							s mode=mode_"/"_cnt_"->Delock"
						} else {
							s cnt=+xcnt-ebcnt-edcnt
							s ps="+" s:cnt=0 cnt="",ps=""
							i ebcnt s cnt=cnt_ps_ebcnt_"e",ps="+"
							i edcnt s cnt=cnt_ps_edcnt_"E",ps="+"
							i ebdcnt s cnt=cnt_ps_ebdcnt_"de",ps="+"
							i eddcnt s cnt=cnt_ps_eddcnt_"dE"
							s mode=mode_"/"_cnt
						}
					} else {
						s xf=+$p(xeinfo,"^")
						if $$$LockXEscalatable(xf) s mode=mode_"_e"
						if $$$LockXEscalated(xf) s mode=mode_"_E"
						if xcnt["D" s mode=mode_"->Delock"
					}
				} elseif (Mode="S") {
					s seinfo=einfo,scnt=cnt
					s ebcnt=+$p(seinfo,"^",2),edcnt=+$p(seinfo,"^",3),ebdcnt=+$p(seinfo,"^",4),eddcnt=+$p(seinfo,"^",5)
					If +scnt>1||$s(scnt["D":(ebdcnt+eddcnt)>1,1:(ebdcnt+eddcnt)>0) {
						if scnt["D" {
							s cnt=+scnt-ebdcnt-eddcnt
							s ps="+" s:cnt=0 cnt="",ps=""
							i ebdcnt s cnt=cnt_ps_ebdcnt_"e",ps="+"
							i eddcnt s cnt=cnt_ps_eddcnt_"E"
							s mode=mode_"/"_cnt_"->Delock"
						} else {
							s cnt=+scnt-ebcnt-edcnt
							s ps="+" s:cnt=0 cnt="",ps=""
							i ebcnt s cnt=cnt_ps_ebcnt_"e",ps="+"
							i edcnt s cnt=cnt_ps_edcnt_"E",ps="+"
							i ebdcnt s cnt=cnt_ps_ebdcnt_"de",ps="+"
							i eddcnt s cnt=cnt_ps_eddcnt_"dE"
							s mode=mode_"/"_cnt
						}
					} else {
						s xf=+$p(seinfo,"^")
						if $$$LockSEscalatable(xf) s mode=mode_"_e"
						if $$$LockSEscalated(xf) s mode=mode_"_E"
						if scnt["D" s mode=mode_"->Delock"
					}
				} else {
					If +cnt>1 s mode=mode_"/"_cnt
					If cnt["D" s mode=mode_"->Delock"
				}
			}
			#;SML1455-
			#;SML1718 ; get internal job owner.
			s ow=$p(Owner,",",ii),iow=$p(iOwner,",",ii)
#if 0   ;SML457+
			s $p(delkey,",",3)=ow
#else   ;SML457=
			s $p(delkey,",",3)=$s($e(ow,1,4)="CDTM":$p(ow,"/"),1:ow)
#endif  ;SML457-
			s ow=$e(ow,2,$l(ow))
#;SML655+
			s owi=ow   ;Internal PID
#;SML655-
#if 0   ;SML529+
			s lrow=$ListBuild(ow,mode,ref,dir,REM,Removable,delkey)
#else   ;SML529=
			#;SML1718 ; pass internal job number for ChkExamine()
			s lrow=$ListBuild(ow,mode,ref,dir,REM,Removable,delkey,$$ChkExamine(iow))
#endif  ;SML529-
#;TCS015+
#;SML655+
			s lrow=lrow_$ListBuild($p(rmtowner,",",ii),owi)
#;SML655-
#;TCS015-
			#;SML1704+,SML2050
			if +$p(rmtowner,",",ii)||NoLineRoutine {
				s lrow=lrow_$ListBuild("")
			} else {
				#;SML1718 ; get the line number from the internal job number
				#;SML2050+ ; get the line/routine info from previous value if existed.
				if '$d(@TMPLRGLO@(iow),lrinfo) {
					s lrinfo=##CLASS(%SYS.ProcessQuery).GetCurrentLineAndRoutine(iow)
					s @TMPLRGLO@(iow)=lrinfo
				}
				s lrow=lrow_$ListBuild(lrinfo)
				#;SML2050-
			}
			#;SML1704-
			s tail=","""_mode_""","""_ow_""")"
			#;SML3010 ; The row is now set in MakeKey.
			do MakeKey(key,ref,lrow,tail)
		}
	}
	s waitersys=$$$LockTotalWaiters(info)
	s Removable=0
	for loc=1:1:waitersys {
		#;SML1718; Get internal job number.
		s wt=$$$LockWaiter(info,loc),iow=$$$LockOwnerTID(wt)
		s sn=$ZU(89,1,0,$$$LockWaiterSYSID(wt))
#if 0   ;SML457+
		S wtid=$$getownerid(sn,$$$LockWaiterPID(wt),Flag)
#else   ;SML457=
		S wtid=$$getownerid(sn,$$$LockWaiterPID(wt),0,Flag)
#endif  ;SML457-
		s $p(delkey,",",3)=wtid
		s wtid=$e(wtid,2,$l(wtid))
#;SML655+
		s owi=wtid   ;Internal PID
#;SML655-
		S wm=$e("SXSXZ",$$$LockWaiterMode(wt))
		#;SML1336 ; tell it is a node lock or tree lock for U2.
		s mode="Wait"_$s(wm="X":"Exclusive",wm="S":"Shared",1:"LockZA")_$s(nodelock:"_Node",1:"")
		S wtype=$$$LockWaiterType(wt)
		s mode=mode_$s(wtype="E":"Exact",wtype="P":"Parent",1:"Child")
#if 0   ;SML529+
		s lrow=$ListBuild(wtid,mode,ref,dir,REM,Removable,delkey)
#else   ;SML529=
		#;SML1718 ; pass internal job number for ChkExamine()
		s lrow=$ListBuild(wtid,mode,ref,dir,REM,Removable,delkey,$$ChkExamine(iow))
#endif  ;SML529-
#;TCS015+
#;SML655+
		s lrow=lrow_$ListBuild((sn'=0),owi)
#;SML655-
#;TCS015-
		#;SML2050+
		if (sn'=0)||NoLineRoutine {
			s lrow=lrow_$ListBuild("")
		} else {
			if '$d(@TMPLRGLO@(iow),lrinfo) {
				s lrinfo=##CLASS(%SYS.ProcessQuery).GetCurrentLineAndRoutine(iow)
				s @TMPLRGLO@(iow)=lrinfo
			}
			s lrow=lrow_$ListBuild(lrinfo)
		}
		#;SML2050-
		s tail=","""_mode_""","""_wtid_""")"
		#;SML3010 ; The row is now set in MakeKey.
		do MakeKey(key,ref,lrow,tail)
	}
	q
nref(r,REM,nnsfn,dir) ;build a full global reference from 'r' for remote machine 'REM'
	S (dir,glocaret)=""
	I nnsfn'=$$$LockLOCALSFN S glocaret="^",dir=$$$Locknnsfn2dir(nnsfn)
	E  s dir=$$$GetSysMgrDir
	S REM=$G(REM)
	s xdir=dir
	i xdir]"" s xdir=$s(REM]"":"["_$$subscr(dir)_","_$$subscr(REM)_"]",1:"["_$$subscr("^^"_dir)_"]")
	Q glocaret_xdir_r
subscr(x) ;return x if it is a number, "x" if it is not
	S $ZT="suberr" I x?1N.E,+x=x Q x
suberr S $ZT="" I x["""" S ii=0 F  S i=$F(x,"""",ii) Q:'ii  DO
	. S x=$E(x,1,ii-1)_$E(x,ii-1,$L(x)),ii=ii+1 ;double quote
	Q """"_x_""""
#if 0   ;SML457+
getownerid(sn,prid,Flag) ; get owner's pid, return remote machine name if owner is remote.
#else   ;SML457=
getownerid(sn,prid,rempid,Flag) ; get owner's pid, return remote machine name if owner is remote.
#endif  ;SML457-
#;SML655+
	q:sn=0 $s(Flag=2:"P",1:"")_prid
#;SML655-
	s SN=$G(systems(sn))
	#; For ddp nodes the first 4 bytes of sys are zeros.
	i SN="" i $zwa(sn,1)=0&($zwa(sn,3)=0) s SN=$$conv32($zwa(sn,5))
	i SN="" s SN="@" d
	. f ii=1:1:6 s SN=SN_$A(sn,ii) s:ii'=6 SN=SN_"."
#if 0   ;SML457+
	q $s(Flag=2:"C",1:"")_SN
#else   ;SML457=
	q $s(Flag=2:"C",1:"")_SN_$s(rempid:"/"_rempid,1:"")
#endif  ;SML457-
conv32(val) ; Given 'val' a decimal number return 3 Uppercase alpha
	s val=val\2
	s x3=val#32,val=val\32,x2=val#32,x1=val\32
	q $C(x1+64,x2+64,x3+64)
#;SML3010 ; Also pass the value to be stored in the key.
MakeKey(key,ref,value,tail)
	s subs=$s($l(ref,"(")>1:","_$p(ref,"(",2,999),1:")")
	#;SML3010+ ; We want to make sure the key reference we made here
	#; won't casue any error before returning the key.
	#; if it can't make a valid key then we back up one subscript and try again
	#; until it made a good key.
	s ckey=key_$s(tail'="":$e(subs,1,*-1)_tail,1:subs)
	if ('$$KeyValid(ckey,value)) {
		s qlen=$QLENGTH(ref)
		do {
			s qlen=qlen-1
			s subs=""
			for ii=1:1:qlen {
				s sub=$qs(ref,ii)
				i sub'?1.N s sub=""""_sub_""""
				s subs=subs_","_sub
			}
			s subs=subs_","_BADINDEX_")"
			s ckey=key_$s(tail'="":$e(subs,1,*-1)_tail,1:subs)
		} while '$$KeyValid(ckey,value)
		s BADINDEX=BADINDEX+1
	}
	quit
KeyValid(ckey,value)
	Try {
		s @ckey=value
		s goodkey=1
	} catch {
		s goodkey=0
	}
	q goodkey
	#;SML3010-
#;SML529+
ChkExamine(job)
#;SML1718+ ; the job is now internal job number, remote sys will be greater than 65535.
	q:job\65536 0   ; Only local job could be examined.
	#; Get the examine flag directory from pidtable.
	q $ZU(61,31,job,2)
#;SML1718-
#;SML529-
}

/// Get lock system number and name translation table.
ClassMethod GetLockSysNameTable(ByRef SYSTEMS As %String, ByRef BYTES2 As %String, ByRef SYSN2 As %String) As %Status [ Internal, Private ]
{
	;Synthesize entry for this computer only if needed (network not up)
    ;Never let OURNAME be "", even if ^NET(0,"THISCO") is
    S OURNAME=$G(^|"^^"_$zu(12)|NET(0,"THISCO")) S:OURNAME="" OURNAME=0
	; There may be multiple directory sets pointing at the local host
	; so we standardize by using ^NET(0,"THISCO")
	S SYSTEMS(0)=OURNAME,BYTES2(OURNAME)=0,SYSN2(1,OURNAME)=0,SYSN2(2,0)=OURNAME
	Do Scannscli
	Q 1
Scannscli ;
#;SML815
	s savze=$ze
#;SML1198 ; save $ECODE
	s ecodesave=$ECODE
	s $zt="Scannsclierr"
	S sys=0,nsclimax=$SYSTEM.ECP.MaxServerConnections()
nextns ;
	S sys=sys+1
	Q:sys>nsclimax
	S addr=$zu(89,1,0,sys)
	I addr="" Goto nextns
	#;SML1204+
	I $l(addr)=2 {
		S hostname=$zu(89,1,2,sys) G:hostname="" nextns
		if $d(BYTES2(hostname)) {
			#; Duplicate remote client found, we need to put the
			#; GUID at the end. But first we need to update the
			#; existing entry.
			s oldhost=hostname,oldsys=SYSN2(1,oldhost),guid=$zu(89,1,3,oldsys)
			s oldaddr=BYTES2(oldhost)
			#; Remove old entry.
			k BYTES2(oldhost),SYSN2(1,oldhost)
			#; Set new data for old entry.
			s hostname=oldhost_"|"_guid
			S SYSTEMS(oldaddr)=hostname,BYTES2(hostname)=oldaddr
			s SYSN2(1,hostname)=oldsys,SYSN2(2,oldsys)=hostname
			#; Now setup new hostname for this entry.
			s hostname=oldhost_"|"_$zu(89,1,3,sys)
		}
		S SYSTEMS(addr)=hostname,BYTES2(hostname)=addr
		s SYSN2(1,hostname)=sys,SYSN2(2,sys)=hostname
	}
	#;SML1204-
	Goto nextns
Scannsclierr ;
#;SML815, SML1198 restore $ECODE too
	i $d(savze),$ze["<FUNCTION" {
		try {
			s $ECODE=ecodesave
		} catch {}
		s $ze=savze
	}
	Q
}

/// Translate the input ID string and return four values separated by commas.<br>
/// 1) pid : The process ID, 0 - all processes.<br>
/// 2) clin: The remote client system number, -1 - all remote systems.<br>
/// 3) ntype: The network protocol from remote client, 100 - all network protocols.<br>
/// 4) svrn: The remote server system number, -1 - all remote systems.
/// 
ClassMethod TranslateID(id As %String) As %String [ Internal, Private ]
{
	#; set up pid,clin,ntype,svrn according to the requesting id string.
	#;SML1758 ; accept "*" as "" to return all lock items.
	If id=""||(id="*") {
		#; get all locks in the lock table.
		s pid=0,clin=-1,ntype=0,svrn=-1
	} ElseIf $e(id)="J" {
		#; Job Number specified. Get locks owned by the job.
		#; Convert the internal job number to PID.
		s pid=$e(id,2,$l(id))
		If pid?1.N {
			If +pid<65536 {
				s pid=$zu(61,+pid)
				If pid=0 S pid=-1
				s clin=-1
			} Else {
				#; The internal job number has system number included.
				#; set up the system number for the search.
				s clin=pid\65536
				s pid=0
			}
		} Else {
			#; If this is an invalid job number then set it to a bad
			#; value so no lock will be find in the lock table.
			S pid=-1
			s clin=-1
		}
		s ntype=0,svrn=-1
	} ElseIf $e(id)="N" {
		#; Remote network type is specified, Get all locks owned
		#; by remote system with the specified network protocol.
		#; ntype = 100 means any remote system will match
		#; ntype = -1 means bad net type, no lock entry will match.
		s ntype=$e(id,2,$l(id))
		#;SML1716 ; remove legacy network type.
		s ntype=$case(ntype,"":100,"ECP":4,:-1)
		s pid=0,clin=-1,svrn=-1
	} ElseIf $e(id)="C" {
		#; System number or system name specified.
		s id=$e(id,2,$l(id))
		s pid=0,ntype=0,svrn=-1
		#; if the system name could not be found then set clin=-2 so
		#; it won't find any matching system.
		s clin=$s(id?1.N:id,id="":0,1:..ClientSysNameToSysNum(id))
		If clin<0 s clin=-2
	} ElseIf $e(id)="S" {
		#; Locks to remote server specified.
		s id=$e(id,2,$l(id))
		s pid=0,ntype=0,clin=-1
		#; if the system name could not be found then set svrn=-2 so
		#; it won't find any matching system.
		s svrn=$s(id?1.N:id,id="":0,1:$zu(63,0,id))
		If svrn<0 s svrn=-2
	} Else {
		#; Job PID is specified, Get locks owned by the job.
		s:$e(id)="P" id=$e(id,2,$l(id))
		#;SML1264 ; strip off the possible system name following the pid.
		s id=$p(id,":")
#;SML655+
#;SML741
		s pid=$s(id?1.N:id,1:-1)
#;SML655-
		s clin=-1,ntype=0,svrn=-1
	}
	Quit pid_","_clin_","_ntype_","_svrn
}

/// Get detail columns for lock table entries.<br>
/// <br>
/// <b>DelKey</b>: A key to be used for <class>SYS.Lock</class>.<method>DeleteOneLock</method> to remove the lock (row).<br><br>
/// <b>Owner</b>: Owner of the lock item. For local system owner it is Process ID (in decimal form). For remote client owner, it is the client system name. For share lock there can be more than one owner, and they are separated by ','.<br><br>
/// <b>Mode</b>: Lock mode of the lock item. It can be:<ul><li>
/// 'X' - exclusive lock.</li><li>
/// 'S' - share lock.</li><li>
/// 'ZAX' - ZALLOCATE type lock.</li></ul>
/// <b>Flags</b>: Attribute of the lock item. It can be:<ul><li>
/// '*' - to remote server.</li><li>
/// 'D' - Lock is in Delock Pending state, waiting for server to release the lock.</li><li>
/// 'P' - Lock is in Lock Pending state, waiting for server to grant the lock.</li><li>
/// 'L' - Lock is lost due to network reset.</li><li>
/// 'Z' - Lock granted by ZA command. The ZA and ZD commands are obsolete, though the network daemons still grant the locks for remote client with the ZA lock mode internally.</li></ul>
/// <b>Counts</b>: Lock count of the lock item. The format depends on the lock mode:<ul><li>
/// For 'X' mode - it is the lock count for the exclusive lock. If the owner also locked it with share mode, the share lock count will be separated with '|' from exclusive lock count, for example, "2|1" means 2 'X' count and 1 'S' count.</li><li>
/// For 'S' mode - it is the lock count for the share lock. There can be more than one owner for share lock, so the lock count is separated with ',' between each owner. For example, "1,3,4" means first owner has lock count 1, second owner has lock count 3 and third owner has lock count 4.</li><li>
/// For 'ZAX' mode - the Counts will be null string if the owner does not own it with share mode. Otherwise the share lock count will be separated by '|'. For example, "|3" the owner locked it with 'ZAX' mode and 'S' mode with lock count 3.</li></ul>
/// <b>Sfn</b>: System File Number of the lock item. It tells in which database this lock is located, in internal system file number form.<br><br>
/// <b>LockString</b>: Lock reference string of the lock item. This does not include the database name.<br><br>
/// <b>FullReference</b>: Full lock reference string of the lock item. This includes the database and system name (if remote lock).<br><br>
/// <b>WaiterPID</b>: Waiter of the lock item. This has the same format as <b>Owner</b>. There can be more than one waiter of the lock and they are separated by ','.<br><br>
/// <b>WaiterMode</b>: Lock mode the waiter is waiting for. It can be:<ul><li>
/// 'X' - Waiting for exclusive lock mode.</li><li>
/// 'S' - Waiting for share lock mode.</li><li>
/// 'Z' - Waiting for ZALLOCATE lock mode.</li></ul>
/// <b>WaiterType</b>: Which node the waiter is waiting for. It can be:<ul><li>
/// 'E' - Exact node. It is waiting for the same lock node.</li><li>
/// 'P' - Parent node. It is waiting for a parent node.</li><li>
/// 'C' - Child node. It is waiting for a child node.</li></ul>
/// <b>RemoteOwner</b>: A boolean value, TRUE means one of the lock owner(s) is remote.<br><br>
/// <b>EscalateInfo</b>: A series of counters if the lock node involved lock escalation. A null string if no lock escalation is involved. Each owner has its own set of counters separated by ','.
/// The counters are for internal use.<br><br>
Query Detail(id As %String = "") As %Query(ROWSPEC = "DelKey:%String,Owner:%String,Mode:%String,Flags:%String,Counts:%String,Sfn:%Integer,LockString:%String,FullReference:%String,WaiterPID:%String,WaiterMode:%String,WaiterType:%String,RemoteOwner:%Boolean,EscalateInfo:%String") [ SqlProc ]
{
}

ClassMethod DetailExecute(ByRef qHandle As %Binary, id As %String = "") As %Status [ Internal ]
{
	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	Quit ..CommonExecute(.qHandle,id,1)
}

ClassMethod DetailFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = DetailExecute ]
{
	Quit ..ListFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod DetailClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = DetailExecute ]
{
	Quit ..ListClose(.qHandle)
}

/// Get short information of each lock entry.<br>
/// See the <query>Detail</query> query description for each column.
Query List(id As %String = "") As %Query(ROWSPEC = "DelKey:%String,Owner:%String,Mode:%String,Flags:%String,Counts:%String,Sfn:%Integer,LockString:%String,FullReference:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, id As %String = "") As %Status [ Internal ]
{
	#; Execute the query with deltail flag 0.
	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	Quit ..CommonExecute(.qHandle,id,0)
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 $$$DEFAULTFETCHPPG
 Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	s Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

/// Query for Web Lock display utility to use.<br><br>
/// This query returns a row for each lock owner and lock waiter. So if one lock is owned by more than one process, it will return one row for each owner. It also returns one row for each waiter for one lock item.<br><br>
/// <b>ProcessClient</b>: Owner's or waiter's Process ID. It can be a client system name if it is owned by a remote client. There is only one owner or waiter for each row.<br><br>
/// <b>ModeCount</b>: Lock mode and count of the lock item. If the lock count is 1 the count will not be displayed, otherwise a '/<i>count</i>' will follow. A '->Delock' will be appended if the lock is in 'Deferred Delock' state (delocked within a transaction). The column can be:<ul><li>
/// 'Exclusive' - Exclusive lock mode.</li><li>
/// 'Shared' - Share lock mode.</li><li>
/// 'LockZA' - ZALLOCATE lock mode.</li><li>
/// 'WaitExclusive' - Waiting for exclusive lock mode.</li><li>
/// 'WaitShared' - Waiting for share lock mode.</li><li>
/// 'WaitLockZA' - Waiting for ZALLOCATE lock mode.<br>
/// The Wait modes are followed by 'Exact', 'Parent', or 'Child'</li><li>
/// 'LockPending' - Exclusive lock Pending, waiting for server to grant the exclusive lock.</li><li>
/// 'SharePending' - Share lock Pending, waiting for server to grant the share lock.</li><li>
/// 'DelockPending' - Delock Pending, waiting for server to release the lock.</li><li>
/// 'Lost' - Lock lost due to network reset.</li></ul>
/// <b>Reference</b>: Lock reference string of the lock item. This does not include the database name.<br><br>
/// <b>Directory</b>: The database where the lock item is located.<br><br>
/// <b>System</b>: The system name where the lock is located. If it is the local system the column will be a null string.<br><br>
/// <b>Removable</b>: Flag indicates whether this lock (row) can be removed or not. Value 1 -> Removable, 0 -> Not removable, 2 -> Removable, but needs special warning because it is in 'DelockPending' state.<br><br>
/// <b>DeleteID</b>: Delete key that can be used to call <class>SYS.Lock</class>.<method>DeleteOneLock</method> to delete the lock of the specific owner (that is the row).<br><br>
/// <b>CanBeExamined</b>: Flag to tell whether the owner job can be examined or not.
Query WebList(id As %String = "", NoLineRoutine As %Boolean = 0) As %Query(ROWSPEC = "Pid:%String,ModeCount:%String,Reference:%String,Directory:%String,System:%String,Removable:%Integer,DeleteID:%String,CanBeExamined:%Boolean,RemoteOwner:%Boolean,PidInternal:%String,RoutineInfo:%String") [ Internal, SqlProc ]
{
}

ClassMethod WebListExecute(ByRef qHandle As %Binary, id As %String = "", NoLineRoutine As %Boolean = 0) As %Status [ Internal ]
{
	#; Execute the query with deltail flag 2.
	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	Quit ..CommonExecute(.qHandle,id,$s(NoLineRoutine:3,1:2))
}

ClassMethod WebListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = WebListExecute ]
{
	Quit ..ListFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod WebListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = WebListExecute ]
{
	Quit ..ListClose(.qHandle)
}

Query WebListFilter(Filter As %String = "", NoLineRoutine As %Boolean = 0) As %Query(ROWSPEC = "Pid:%String,ModeCount:%String,Reference:%String,Directory:%String,System:%String,Removable:%Integer,DeleteID:%String,CanBeExamined:%Boolean,RemoteOwner:%Boolean,PidInternal:%String,RoutineInfo:%String,OSUserName:%String") [ Internal, SqlProc ]
{
}

ClassMethod WebListFilterExecute(ByRef qHandle As %Binary, Filter As %String = "", NoLineRoutine As %Boolean = 0) As %Status [ Internal ]
{
	if '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	set qHandle("Filter")=Filter
	quit ..CommonExecute(.qHandle,"",$select(NoLineRoutine:3, 1:2))
}

ClassMethod WebListFilterFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = WebListExecute ]
{
	while (AtEnd=0) {
		set Status=..ListFetch(.qHandle,.Row,.AtEnd)
		quit:(AtEnd||$$$ISERR(Status))
		set proc = ##class(%SYS.ProcessQuery).%OpenId(+$listget(Row),,.procObjStatus)
		if $$$ISOK(procObjStatus)&&$IsObject(proc) set Row = Row _ $listbuild(proc.OSUserName)
		if $zcvt($ListToString(Row,$c(13)),"U")[$zcvt(qHandle("Filter"),"U") quit
	}
	quit Status
}

ClassMethod WebListFilterClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = WebListExecute ]
{
	Quit ..ListClose(.qHandle)
}

/// Gets all lock entries that may conflict with the lock reference specified in <parameter>LockRef</parameter> if an exclusive lock on that reference were to be attempted.<p>
/// <parameter>LockRef</parameter> is a string that contains the quoted lock reference (quoted by the $NAME function if desired), and is taken as a reference in the current namespace.  Extended reference may also be used to specify a different namespace or system^directory.<p>
/// The output columns are similar to the output column in <query>Detail</query> query except 'EscalateInfo' is not included. See the <query>Detail</query> query description for each column.<p>
/// Notes:
/// <li>If the lock reference is subject to subscript level mapping, then the result set may include results from multiple databases due to the implicit duplication of locks to multiple subscript level mapping targets.</li>
/// <li>The result set will include locks owned by the calling process itself.</li>
/// <li>The result set can include locks that are both lower or higher than <parameter>LockRef</parameter> in the lock tree (ancestors and descendants), as well as an exact match.</li
/// <li>The result set can also include locks that are not direct descendants of <parameter>LockRef</parameter> if there are waiters waiting for a parent.  For example, if <parameter>LockRef</parameter> = $NAME(^X("abc",1)) and there is a waiter waiting for ^X("abc") due to a lock held on ^X("abc",2), then ^X("abc",2) will be included in the result set with a waiter of type "P".  As with the other queries, ^X("abc") itself is not returned in the results because it has not yet been acquired.</li>
Query Conflicts(LockRef As %String = "") As %Query(ROWSPEC = "DelKey:%String,Owner:%String,Mode:%String,Flags:%String,Counts:%String,Sfn:%Integer,LockString:%String,FullReference:%String,WaiterPID:%String,WaiterMode:%String,WaiterType:%String,RemoteOwner:%Boolean") [ SqlProc ]
{
}

ClassMethod ConflictsExecute(ByRef qHandle As %Binary, LockRef As %String = "") As %Status [ Internal ]
{
	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	if (LockRef'="") {
		s rc=$$$OK
		Try {
			Set NS=$QS(LockRef,-1)		;Get Namespace
			Set LR=$LB($QS(LockRef,0))	; Get global name.
			Set ql=$QLENGTH(LockRef)
			For i=1:1:ql s LR=LR_$LB($QS(LockRef,i))
			d $zu(156,45,NS,LR)
		} Catch {
			s rc=$$$ERROR($$$GeneralError,"Caught Error, $ZE="_$ZE_" $ZU(56,2)="_$zu(56,2))
		}
		if '$$$ISOK(rc) {
			d $zu(156,46)	; Clear Filter Lock Reference.
			q rc
		}
	}
	Set rc=..CommonExecute(.qHandle,"",4)
	d $zu(156,46)	; Clear Filter Lock Reference.
	Quit rc
}

ClassMethod ConflictsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ConflictsExecute ]
{
	Quit ..ListFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod ConflictsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ConflictsExecute ]
{
	Quit ..ListClose(.qHandle)
}

Storage Default
{
<Data name="LockDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Mode</Value>
</Value>
<Value name="3">
<Value>Owner</Value>
</Value>
<Value name="4">
<Value>Counts</Value>
</Value>
<Value name="5">
<Value>LockCount</Value>
</Value>
<Value name="6">
<Value>LockMode</Value>
</Value>
<Value name="7">
<Value>LockOwner</Value>
</Value>
<Value name="8">
<Value>LockFlags</Value>
</Value>
<Value name="9">
<Value>LockReference</Value>
</Value>
<Value name="10">
<Value>LockInDelockPending</Value>
</Value>
<Value name="11">
<Value>LockInLockPending</Value>
</Value>
<Value name="12">
<Value>LockIsLost</Value>
</Value>
<Value name="13">
<Value>LockWaiters</Value>
</Value>
<Value name="14">
<Value>Flags</Value>
</Value>
<Value name="15">
<Value>ReferenceString</Value>
</Value>
<Value name="16">
<Value>Waiters</Value>
</Value>
<Value name="17">
<Value>OwnerSys</Value>
</Value>
<Value name="18">
<Value>SysFileNumber</Value>
</Value>
</Data>
<DataLocation>^SYS.LockD</DataLocation>
<DefaultData>LockDefaultData</DefaultData>
<IdLocation>^SYS.LockD</IdLocation>
<IndexLocation>^SYS.LockI</IndexLocation>
<StreamLocation>^SYS.LockS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
