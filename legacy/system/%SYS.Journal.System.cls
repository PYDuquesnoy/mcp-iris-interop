/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %sySystem, %sySite, %syCluster, %syConfig)

/// Journaling related API
Class %SYS.Journal.System Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Purpose: Start journaling <p>
/// Optional parameters for journaling: <ul><li>
/// curdir: primary journal directory </li><li>
/// altdir: alternate journal directory </li><li>
/// maxsiz: max size of journal file in bytes </li><li>
/// expsiz: [Windows & VMS only] unit increment of journal file size in bytes </li><li>
/// prefix: a string preceding the standard journal file name YYYYMMDD.NNN </li></ul>
/// shdwok: OK to share directory with shadow journal files despite potential file conflicts (DEFAULT = 0) 
/// Returns OK on success
ClassMethod Start(curdir As %String, altdir As %String, maxsiz As %Integer, expsiz As %Integer, prefix As %String, okshdw As %Boolean = 0) As %Status
{
	s $zt="Error"
 	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	d ..GetDefaults(.defcurdir,.defaltdir,.defmaxsiz,.defexpsiz,.defprefix,.shortnam)
	s curdir=$g(curdir,defcurdir),altdir=$g(altdir,defaltdir)
	s maxsiz=$g(maxsiz,defmaxsiz),expsiz=$g(expsiz,defexpsiz)
	s prefix=$g(prefix,defprefix)
	s started=$$INT^|"%SYS"|JRNSTART(curdir,altdir,shortnam,prefix,maxsiz,expsiz,0,.err,,$s(okshdw=1:-1,1:1))
#;Only update the Config and CPF file, don't activate its already been done
	i started {
		s Status=##Class(Config.Journal).Get(.P)
		s P("AlternateDirectory")=altdir
		s P("CurrentDirectory")=curdir
		s P("JournalFilePrefix")=prefix
		s Status=##Class(Config.Journal).Modify(.P,,$$$CPFSave+$$$CPFWrite)
	}
	q $s(started:$$$OK,1:$$$ERROR($$$JournalingStartError,$g(err)))
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Purpose: Stop journaling system wide
ClassMethod Stop() As %Status
{
	s $zt="Error"
 	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	s stopped=$$INT^|"%SYS"|JRNSTOP(.err)
	q $s(stopped:$$$OK,1:$$$ERROR($$$JournalingStopError,err))
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Purpose: Roll journaling to next file, without any journal property change (to activate) <p>
/// Input: <ul><li>
/// Reason: reason for the switch (0 = unspecified, 1 = user-initiated, etc.); </li></ul>
/// Output: <ul><li>
/// NewFile: the path of the file to which journaling has switched (if successfully) </li></ul>
/// Return success or error status. <p>
/// Caveat: Journal history global is NOT updated, a la journal daemon
ClassMethod RollToNextFile(Reason As %Integer, ByRef NewFile As %String) As %Status
{
	s $zt="Error"
	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	i '$$$ISJRNENABLED q $$$ERROR($$$JournalingSwitchError,$$$Text("Journaling disabled","%Utility"))
								#;HYY2452+
	i $$$ISJRNPAUSED {
		d $zu(9,"","Waiting for journal switch to finish...")
		f i=1:1:300 h .1 q:'$$$ISJRNPAUSED 
		i $$$ISJRNPAUSED q $$$ERROR($$$JournalingSwitchError,$$$Text("Another journal switch in progress","%Utility"))
	}
								#;HYY2452-
	s rc=$$$JrnRollToNextFile($g(Reason,$$$JRNSWREASONUNSPECIFIED))
 	i rc>0 s NewFile=$p(rc,",",2) q $$$OK
 	q $$$ERROR($$$JournalingSwitchError,rc) 
Error q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get the path of the journal directory other than the current one. <br>
/// Directory: The journal directory different from the current one or "" if none <br>
/// Type: 1 if Directory is Primary or 2 if Directory is Secondary or 0 if Directory is "" (meaning no other directory)
ClassMethod GetTheOtherDirectory(ByRef Directory As %String = "", ByRef Type As %Integer = 0) As %Integer
{
	s $zt="Error"
 	s Status=##Class(Config.Journal).Get(.Prop)
 	s primdir=Prop("CurrentDirectory")
 	s secdir=Prop("AlternateDirectory")
 	i $zu(12,primdir)=$zu(12,secdir) q $$$OK
 	s curfile=$$$JRNCURNAM
 	s curdir=$P(curfile,$s($$$ISWINDOWS:"\",$$$ISUNIX:"/",1:"]"),1,*-1)
 	i $zu(12,curdir)=$zu(12,secdir) {
        s Directory=primdir
        s Type=1
 	} else {
    	s Directory=secdir
        s Type=2
 	}
    q $$$OK
Error q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Switch journaling to the other journal directory if specified <br>
/// Return (by reference) the path of current journal file after a successful switch.
ClassMethod SwitchDirectory(ByRef NewFile As %String = "") As %Status
{
	s $zt="Error"
 	s Status=##Class(Config.Journal).Get(.Prop)
 	s primdir=Prop("CurrentDirectory")
 	s secdir=Prop("AlternateDirectory")
 	i $zu(12,primdir)=$zu(12,secdir) q 0
 	s curfile=$$$JRNCURNAM
 	s curdir=$P(curfile,$s($$$ISWINDOWS:"\",$$$ISUNIX:"/",1:"]"),1,*-1)
 	i $zu(12,curdir)=$zu(12,secdir) {
        s switched=$$INT^JRNSWTCH(primdir,secdir,.err,,,,,$$$JRNSWREASONACTIVATE)
 	} else {
        s switched=$$INT^JRNSWTCH(secdir,primdir,.err,,,,,$$$JRNSWREASONACTIVATE)
 	}
 	s Status=$s(switched:$$$OK,1:$$$ERROR($$$JournalingSwitchError,err))
 	i Status s NewFile=$$$JRNCURNAM
	q Status
Error q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Purpose: Switch journal file (and optionally change one or more journaling parameters) <p>
/// Optional parameters for journaling: <ul><li>
/// curdir: primary journal directory </li><li>
/// altdir: alternate journal directory </li><li>
/// maxsiz: max size of journal file in bytes </li><li>
/// expsiz: [Windows & VMS only] unit increment of journal file size in bytes </li><li>
/// shdwok: OK to share directory with shadow journal files despite potential file conflicts (DEFAULT = 0) </li><li> 
/// reason: reason for journal switch (DEFAULT: by user) </li></ul>
/// Returns OK on success
ClassMethod SwitchFile(curdir As %String, altdir As %String, maxsiz As %Integer, expsiz As %Integer, okshdw As %Boolean = 0, reason As %Integer) As %Status
{
	s $zt="Error"
	  #; a simple roll to next journal file if no journal property change (to activate)
	i $g(curdir)="",$g(altdir)="",$g(maxsiz)="" q ..RollToNextFile($g(reason,$$$JRNSWREASONUNSPECIFIED))
 	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	d ..GetDefaults(.defcurdir,.defaltdir,.defmaxsiz,.defexpsiz)
	s curdir=$g(curdir,defcurdir),altdir=$g(altdir,defaltdir)
	s maxsiz=$g(maxsiz,defmaxsiz),expsiz=$g(expsiz,defexpsiz)
	s switched=$$INT^|"%SYS"|JRNSWTCH(curdir,altdir,.err,,maxsiz,,$s(okshdw=1:-1,1:1),$g(reason,$$$JRNSWREASONUSER))
#;Only update the Config and CPF file, don't activate its already been done
	i switched {
		s Status=##Class(Config.Journal).Get(.P)
		s P("AlternateDirectory")=altdir
		s P("CurrentDirectory")=curdir
								#;HYY2330+
		s P("FileSizeLimit")=maxsiz\(1024*1024) ;in MBs
								#;HYY2330-
		s Status=##Class(Config.Journal).Modify(.P,,$$$CPFSave+$$$CPFWrite)
	}
	q $s(switched:$$$OK,1:$$$ERROR($$$JournalingSwitchError,err))
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod GetDefaults(ByRef curdir As %String, ByRef altdir As %String, ByRef maxsize As %Integer, ByRef expqty As %Integer, ByRef prefix As %String, ByRef shortnam As %String, curfile As %String, jrnall As %Integer) As %Status [ Internal, PublicList = (curdir, altdir, maxsize, expqty, prefix, shortnam, curfile, jrnall) ]
{
	d init^|"%SYS"|JRNSTART
	q $$$OK
}

/// Return current journal encryption status.<br>
/// Type - 1: Run time journal encryption status (default).<br>
///        2: Startup journal encryption status.<br>
///        3: Run time or Startup encryption status.<br>
/// Retrun 1 if journal encryption status is enabled, otherwise return 0. 
ClassMethod IsJournalEncryptionEnabled(Type As %Integer = 1) As %Integer
{
	if Type=1 quit $$$IsJournalEncryptionOn
	if Type=2 {
		s sec=##class(Security.System).%OpenId("SYSTEM")
		quit +sec.DBEncJournal
	}
	if Type=3 {
		s sec=##class(Security.System).%OpenId("SYSTEM")
		quit sec.DBEncJournal||($$$IsJournalEncryptionOn)
	}
	quit 0
}

/// Activate journal encryption such that new updates go to encrypted 
/// journal files.
ClassMethod ActivateEncryption(EnableStartup As %Boolean = 1) As %Status
{
	i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
								#;HYY1873+
	Set DBEncKeyIDList=$System.Security.System.GetDBEncKeyIDList()
	If DBEncKeyIDList="" q $$$ERROR($$$DBEncKeyNotActivated)
								#;HYY1873-
	Set sys=##class(Security.System).%OpenId("SYSTEM")
	i 'sys.DBEncStartMode q $$$ERROR($$$JrnEncRequiresStartupKey)
	#; enable journal encryption at startup if so desired
	#;SML1756+
	i EnableStartup {
		if 'sys.DBEncJournal {
			s sys.DBEncJournal=1
			s rc=sys.%Save()
			if $$$ISERR(rc) quit rc
		}
	}
	if '$$$IsJournalEncryptionOn {
		if '##class(SYS.MirrorConfiguration).AllowDBEncJournal() Quit $$$ERROR($$$EncJrnNotAllowed)
		i $$$EnableJournalEncryption
	}
	#;SML1756-
	i '$$$JRNSTATUS q $$$OK ;journaling is off, no need to switch
	i $$$IsCurrentJournalEncrypted q $$$OK ;already activated
	s Status=##class(%SYS.Journal.System).SwitchFile(,,,,,$$$JRNSWREASONACTIVATE)
	i Status q Status
	q $System.Status.AppendStatus(Status,$$$ERROR($$$JrnEncNotActivated))
}

/// Deactivate journal encryption such that new updates go to unencrypted 
/// journal files.
ClassMethod DeactivateEncryption(DisableStartup As %Boolean = 1) As %Status
{
	i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	#; disable journal encryption activation at startup if so desired
	Set sys=##class(Security.System).%OpenId("SYSTEM")
	#;SML1756 ; check return code of %Save() and return if failed.
	i DisableStartup,sys.DBEncJournal s sys.DBEncJournal=0 s rc=sys.%Save() i $$$ISERR(rc) quit rc
	i $$$DisableJournalEncryption
	i '$$$JRNSTATUS q $$$OK ;journaling is off, no need to switch file
	i '$$$IsCurrentJournalEncrypted q $$$OK ;already deactivated
	s Status=##class(%SYS.Journal.System).SwitchFile(,,,,,$$$JRNSWREASONACTIVATE)
	i Status q Status
	q $System.Status.AppendStatus(Status,$$$ERROR($$$JrnEncNotDeactivated))
}

/// Return OK if DBEncKey is not required for individual jobs to roll back
/// their own open transactions (i.e., OK to deactivate DBEncKey); otherwise, 
/// return an error indicating why DBEncKey must stay activated.
ClassMethod OKNoDBEncKeyNow() As %Status
{
	#; Must disable journal encryption before deactivating DBEncKey.
	#; By requiring new files NOT encrypted (and thus eliminating a moving 
	#; target -- the new files), we simplify the verification process and 
	#; only have to verify whether DBEncKey is required for rolling back 
	#; open transactions in existing files.
	i $$$IsJournalEncryptionOn q $$$ERROR($$$DBEncKeyRequiredNow,$$$Text("journal encryption is enabled","%Utility"))
	#; When journaling is disabled, prior journal files cannot be rolled
	#; back or forward (for data integrity reason). Thus, no need to check 
	#; further whether prior journal files contain open transactions.
	#; In addition, "current" journal file may remain encrypted (i.e., journal
	#; encryption cannot be deactivated) if journaling is disabled for I/O reason.
	i ..IsDisabled() q $$$OK
	#; Must deactivate journal encryption before deactivating DBEncKey.
	#; By requiring current file NOT encrypted (and thus eliminating a moving
	#; target -- new open transactions in current file), we simplify the
	#; verification process and only have to verify whether DBEncKey is 
	#; required for rolling back existing open transactions in past files.
	i $$$IsCurrentJournalEncrypted q $$$ERROR($$$DBEncKeyRequiredNow,$$$Text("current journal file is encrypted","%Utility"))
	d ##class(%SYS.Journal.File).RequiredForRollback(.OldestFile)
	i $g(OldestFile)="" q $$$OK ;no open transaction to roll back
	s LastEncryptedFile=##class(%SYS.Journal.File).LastEncrypted(OldestFile)
	i LastEncryptedFile="" q $$$OK ;none of the required files is encrypted
	q $$$ERROR($$$DBEncKeyRequiredForRollback,LastEncryptedFile)
}

/// Return OK if DBEncKey is not required at startup (i.e., OK to disable
/// DBEncKey activation at startup); otherwise, return an error indicating 
/// why DBEncKey must be activated at startup.
ClassMethod OKNoDBEncKeyAtStartup(LocalOnly As %Boolean = 0) As %Status
{
	i 'LocalOnly,$$$IsCluSys {
		#; check dependency requirement on local node first
		s Status=..OKNoDBEncKeyAtStartup(1) i $$$ISERR(Status) q Status
		#; check dependency requirement on other nodes
		#; get the oldest files required at recovery on all other nodes
		d ##class(%SYS.Journal.File).RequiredForClusterRecovery(.OldestFile,,1)
		#; if OldestFile=0, no other node of the cluster requires
		#; journal recovery (probably because we are the only node)
		i '$g(OldestFile) q $$$OK  
		#; otherwise verify none of the required files is encrypted
		s csn="" f  s csn=$o(OldestFile(csn),1,OldestFile) q:csn=""  d  q:LastEncryptedFile]""
		. s LastEncryptedFile=##class(%SYS.Journal.File).LastEncrypted(OldestFile,csn)
		#; csn="" implies that none of the required files is encrypted
		i csn="" q $$$OK 
		q $$$ERROR($$$DBEncKeyRequiredForRecovery,LastEncryptedFile)
	}
	#; Must disable journal encryption before diabling DBEncKey activation at startup.
	i $$$IsJournalEncryptionOn q $$$ERROR($$$DBEncKeyRequiredAtStartup,$$$Text("journal encryption is enabled","%Utility"))
	#; When journaling is disabled, prior journal files cannot be rolled
	#; back or forward (for data integrity reason). Thus, no need to check 
	#; further what journal files are required for crash recovery.
	#; In addition, "current" journal file may remain encrypted (i.e., journal
	#; encryption cannot be deactivated) if journaling is disabled for I/O reason.
	i ..IsDisabled() q $$$OK
	#; Must deactivate journal encryption before deactivating DBEncKey.
	i $$$IsCurrentJournalEncrypted q $$$ERROR($$$DBEncKeyRequiredAtStartup,$$$Text("current journal file is encrypted","%Utility"))
	d ##class(%SYS.Journal.File).RequiredForRecovery(.OldestFile)
	i $g(OldestFile)="" q $$$OK ;no open transaction to roll back
	s LastEncryptedFile=##class(%SYS.Journal.File).LastEncrypted(OldestFile)
	i LastEncryptedFile="" q $$$OK ;none of the required files is encrypted
	q $$$ERROR($$$DBEncKeyRequiredForRecovery,LastEncryptedFile)
}

/// TRUE if the given DBEncKeyID is used on journal files required for recovery
ClassMethod IsEncKeyInUse(DBEncKeyID As %String) As %Boolean
{
	s sys=##class(Security.System).%OpenId("SYSTEM")
	i sys.DBEncJournal {
		i DBEncKeyID=$System.Security.System.GetJrnEncKeyID(1) q 1 ;key for current file
		i DBEncKeyID=$System.Security.System.GetJrnEncKeyID(2) q 1 ;key for new file
	}
	d ##class(%SYS.Journal.File).RequiredForRecovery(.OldestFile)
	s inuse=0
        s CurrentFile=$$$JRNCURNAM
        for {
                i CurrentFile="" q
                i DBEncKeyID=$$$JRNENCKEYID(CurrentFile) s inuse=1 q
                i CurrentFile=OldestFile q
                s CurrentFile=$$$JRNFPREV(CurrentFile)
        }
	q inuse
}

/// TRUE if journaling is disabled system wide
ClassMethod IsDisabled(Status As %String = "", ByRef Cause As %String) As %Boolean
{
	i $g(Status)="" s Status=$$$JRNSTATUS
	i 'Status s Cause="by user" q 1
	i $p(Status,"^",3) s Cause="I/O error" q 1
	q 0
}

/// TRUE if journaling is paused system wide (when there is an ongoing journal switch)
ClassMethod IsPaused(Status As %String = "", ByRef Cause As %String) As %Boolean
{
	i $g(Status)="" s Status=$$$JRNSTATUS
	s Cause="switching journal"
	q $p(Status,"^",2)
}

/// TRUE if journaling is frozen system wide (i.e., journal updates are blocked), typically
/// when there is a journaling error and the system is set up to freeze on such errors.
ClassMethod IsFrozen(Status As %String = "", ByRef Cause As %String) As %Boolean
{
	i $g(Status)="" s Status=$$$JRNSTATUS
	s Cause="I/O error"
	q $p(Status,"^",5)
}

/// TRUE if there is a journaling error, from which the system may be trying to recover
ClassMethod IsGettingIOError(Status As %String = "", ByRef Cause As %String) As %Boolean
{
	i $g(Status)="" s Status=$$$JRNSTATUS
	s Cause=""
	q $p(Status,"^",4)
}

/// Get the path of the last journal file on the system -- meaningful only if
/// current journal file name = "" (i.e., journaling hasn't started)
ClassMethod GetLastFileName() As %String
{
	i $$$JRNCURNAM]"" q $$$JRNCURNAM
	s name=$p($g(^%SYS("JOURNAL","LAST")),"^",2)
	i name]"",$$$JRNCHECK(name)=1  ;use it to locate next file
	e  s name=$p($g(^%SYS("JOURNAL","WIJFILE")),",") q:name="" ""
	f  s next=$$$JRNFNEXT(name) q:next=""  s name=next
	q name
}

/// Return the path of current journal file
ClassMethod GetCurrentFileName() As %String
{
	q $$$JRNCURNAM
}

/// Return the object reference to current journal file
ClassMethod GetCurrentFile() As %SYS.Journal.File
{
	s name=$$$JRNCURNAM i name="" q $$$NULLOREF
	q ##class(%SYS.Journal.File).%OpenId(name)
}

/// Returns the ending offset of the last journal record in current journal file;
/// 0 if journaling is off
ClassMethod GetCurrentFileOffset() As %Integer
{
	q $zu(78,33)
}

/// Return the file count of current journal file
ClassMethod GetCurrentFileCount() As %Integer
{
	q $$$JRNCURFILECNT
}

/// Returns the state of the journaling system as a string.  Values are:<br><br>
/// 	"Normal" (Enabled and running normally)<br>
/// 	"Disabled" (stopped)<br>
/// 	"Suspended" (due to I/O error)<br>
/// 	"Frozen" (due to I/O error)<br>
/// 	"Paused" (during journal file switch)<br><br>
/// 		Frozen and Suspended are the same state (I/O error occurred), but
/// 		they differ in the action processes take (freeze or discard journal data respectively)
/// 		when they encounter this state.
ClassMethod GetStateString() As %String
{
	i '$$$ISJRNENABLED q $$$Text("Disabled","%Utility")
	i $$$ISJRNSUSPENDED q $$$Text("Suspended","%Utility")
	i $$$ISJRNFROZEN q $$$Text("Frozen","%Utility")
	i $$$ISJRNPAUSED q $$$Text("Paused","%Utility")
	q $$$Text("Normal","%Utility")
}

/// Returns the state of the journaling system as an Integer<br>
/// 	0 -	Enabled<br>
/// 	1 -	Disabled (stopped)<br>
/// 	2 - Suspended (due to I/O error)<br>
/// 	3 - Frozen (due to I/O error)<br>
/// 	4 -	Paused (during journal file switch)<br>
ClassMethod GetState() As %Integer
{
	#; 	Journaling can be in one state.
	#;		Disabled (stopped)
	#;		Suspended (due to I/O error)
	#;		Frozen (due to I/O error)
	#;		Paused (during journal file switch)
	#;		Enabled (none of the above apply)
	#;	Suspended and Frozen are the same state (I/O error occurred), but
	#;	they differ in the action processed take (freeze, discard journal data)
	#;	when they encounter this state.
	i '$$$ISJRNENABLED q 1
	i $$$ISJRNSUSPENDED q 2
	i $$$ISJRNFROZEN q 3
	i $$$ISJRNPAUSED q 4
	q 0
}

/// Purpose: Sync (commit) journal data to disk <p>
/// Returns a journal offset. It is guaranteed that journal data at or prior to the offset
/// are on disk by the time Sync() returns. <p>
/// Caveat: It is possible that journal file has been switched by the time Sync() returns.
/// In that case, it is unpredictable which journal file the returned offset refers to and
/// one might have to repeat Sync() until journal file remains the same before and after.
ClassMethod Sync() As %Integer [ CodeMode = expression ]
{
$zu(78,29)
}

/// Purpose: Report what portion of the journal has been committed to disk <p>
/// Returns a journal offset. It is guaranteed that journal data at or prior to the offset
/// are on disk. <p>
/// Caveat: see <method>Sync</method>
ClassMethod WhereCommitted() As %Integer [ CodeMode = expression ]
{
$zu(78,40)
}

/// Return the journal checkpoint information stored in the WIJ (aka Write Image Journal)
ClassMethod GetImageJournalInfo(ByRef JournalFileName As %String, ByRef JournalFileOffset As %Integer, ByRef JournalFileCount As %Integer, ByRef OpenTransFileOffset As %Integer, ByRef OpenTransFileCount As %Integer) As %Status
{
	s info=$$$JRNINDEX
#;JO2192+	
	s JournalFileOffset=+$P(info,",",$$$JIJRNOFF)
	s JournalFileName=$p(info,",",$$$JIJRNFILENAME)
	s JournalFileCount=+$p(info,",",$$$JIJRNFILECNT)
	s OpenTransFileCount=+$p(info,",",$$$JITRANSFILECNT)
	s OpenTransFileOffset=+$p(info,",",$$$JITRANSINDEX)
#;JO2192-	
	q $$$OK
}

/// Return the path of the cluster journal log
ClassMethod GetClusterJournalLog() As %String
{
	q $$$CLUJRNLOG
}

/// Return the path of the primary journal directory, which is not necessarily the current journal directory
ClassMethod GetPrimaryDirectory(ByRef Status As %Status = {$$$OK}) As %String
{
	q $g(^%SYS("JOURNAL","CURDIR"))
}

/// Return the path of the secondary journal directory
ClassMethod GetAlternateDirectory(ByRef Status As %Status = {$$$OK}) As %String
{
	q $g(^%SYS("JOURNAL","ALTDIR"))
}

/// Return the journal file name prefix
ClassMethod GetJournalFilePrefix() As %String
{
	q $g(^%SYS("JOURNAL","PREFIX"))
}

ClassMethod SetPrimaryDirectory(dir As %String, create As %Boolean) As %Status
{
 	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	s rc=..VerifyJournalDirectory(.dir,$g(create)) i rc'=$$$OK q rc
								#;HYY2425+
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as Config.Journal requires access to %SYS
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
								#;HYY2425-
	#;Only update the Config and CPF file, don't activate
	s Status=##Class(Config.Journal).Get(.P)
	s P("CurrentDirectory")=dir
	s Status=##Class(Config.Journal).Modify(.P,,$$$CPFSave+$$$CPFWrite)
								#;HYY2423+
	i Status=$$$OK s ^%SYS("JOURNAL","CURDIR")=dir
	q Status
								#;HYY2423-
}

ClassMethod SetAlternateDirectory(dir As %String, create As %Boolean) As %String
{
 	i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
	s rc=..VerifyJournalDirectory(.dir,$g(create)) i rc'=$$$OK q rc
								#;HYY2425+
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as Config.Journal requires access to %SYS
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
								#;HYY2425-
	#;Only update the Config and CPF file, don't activate
	s Status=##Class(Config.Journal).Get(.P)
	s P("AlternateDirectory")=dir
	s Status=##Class(Config.Journal).Modify(.P,,$$$CPFSave+$$$CPFWrite)
								#;HYY2423+
	i Status=$$$OK s ^%SYS("JOURNAL","ALTDIR")=dir
	q Status
								#;HYY2423-
}

/// Return the free space available for journal files
ClassMethod GetFreeSpace() As %Integer
{
	s altdir=..GetAlternateDirectory()
	s info=$zu(140,13,altdir),free=$p(info,",")*$p(info,",",4)
	s curdir=..GetPrimaryDirectory() i curdir=altdir q free
	s info=$zu(140,13,curdir)
	q $p(info,",")*$p(info,",",4)+free
}

ClassMethod VerifyJournalDirectory(dir As %String, create As %Boolean) As %Status [ Internal, Private ]
{
	s DIR=$zu(12,dir,2) i DIR]"" q $$$OK  ;directory exists (and is valid)
	i '$g(create) q $$$ERROR($$$JournalDirectoryNotExist,dir) ;directory doesn't exist (and we are not asked to create it)
	s DIR=$zu(12,dir,1) i DIR="" q $$$ERROR($$$JournalDirectoryInvalid,dir) ;an invalid directory name (e.g., name of an existing file)
	s dir=DIR
	#;JO3024+
	s status=$ZU(140,9,dir)
	if status quit $$$ERROR($$$JournalDirectoryCreateError,dir,status)
	quit $$$OK
	#;JO3024-
}

ClassMethod VerifyJournalFilePrefix(prefix As %String) As %Status [ Internal ]
{
	i $tr(prefix,"_","")?.AN q $$$OK
	q $$$ERROR($$$JournalFilePrefixInvalid,prefix)
}

ClassMethod GetHistoryHeader(jrnlogfd As %String, ByRef header As %String, Mirror As %Boolean = 0) As %Status [ Deprecated, Internal ]
{
  // deprecated
  q ##class(%SYS.Journal.History).GetHeader(jrnlogfd,.header,Mirror)
}

ClassMethod PurgeHistory(DaysOld As %Integer = 100) As %Status [ Deprecated, Internal ]
{
  // deprecated
  q ##class(%SYS.Journal.History).Purge(DaysOld)
}

ClassMethod DisableJournalWithAllRole() As %Status [ Internal ]
{
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 q $$STOP^%SYS.NOJRN()
}

ClassMethod GetDejournalReaderSettings(ByRef CacheSize As %Integer, ByRef ReadAheadSize As %Integer, ByRef disableaio As %Integer) As %Status [ Internal ]
{
 #; JRNRDCACHESIZ (8MB) and JRNRDAHEADSIZ (4MB) are defined in journal.h
 s CacheSize=$g(^%SYS("DEJOURNALING","Reader","CacheSize"),8*1024*1024)
 #; ReadAheadSize should be smaller than CacheSize
 s ReadAheadSize=$g(^%SYS("DEJOURNALING","Reader","ReadAheadSize"),CacheSize/2)
 s disableaio=$g(^%SYS("DEJOURNALING","Reader","disableaio"))
 q $$$OK
}

/// Supported 'type' values are: 
///   "jrnrest" for journal restore, 
///   "jrnrest1" for journal restore at InterSystems IRIS startup or set to abort on DB errors,
///   "shadow" for shadowing,  
///   "mirror" for regular mirroring and 
///   "mircatchup" for mirror catchup.
/// All but journal restore ("jrnrest" or "sturest") also requires a 
/// name (shadow or mirror name).
/// For "shadow", quesiz is also an input for default limit on gmheap, in pages.[HYY2181]
/// Returned parameters: 
///   numpref - initial/minimal # of (active) prefetchers (0 = no prefetching)
///   quesiz - size of the dejournal queue, in pages
///   stksiz - size of the dejournal stack, in pages
/// NB: A -1 value for stksiz tells the caller to use its own default.
///   sizmod - a flag indicating whether quesiz or stksiz is also a maximum,
///            used as an argument of $zu(78,50).
///     2 = quesiz and stksiz are in pages (same as 0)
///    +4 = quesiz is also the maximum size
///    +8 = stksiz is also the maximum size
/// NB: A user-specified quesiz or stksiz is in bytes, whereas we return in pages.
///   numupd - # of updaters
///   rangemax - max # of updates between the foremost and the hindmost updaters
///   maxpref - max # of prefetchers
///   inorder - updates should be applied in order, except for db's listed in
/// 	    ^MIRROR(mirrorname,"APD",db) if any.
/// Note:
/// A user-specified "" value (NOT undefined) is equivalent to -1 here.
/// A user-specified 0 value means NO (for prefetching only) or default algorithm.
/// 
ClassMethod GetDejournalSettings(type As %String, name As %String, ByRef numpref As %Integer, ByRef quesiz As %Integer, ByRef stksiz As %Integer, ByRef sizmod As %Integer, ByRef numupd As %Integer, ByRef rangemax As %Integer, ByRef maxpref As %Integer, ByRef inorder As %Integer) As %Status [ Internal ]
{
								#;HYY2317+
#define DEJRNLOG(%msg)	d:$g(^%ISCLOG("GetDejournalSettings")) $zu(9,"","GetDejournalSettings:"_%msg)
								#;HYY2317-
 #; -1 tells the caller to use its own algorithm to figure out the value
 s sysmaxpref=$g(^%SYS("DEJOURNALING","NumPrefetch"),-1)
 s sysactprefperupd=$g(^%SYS("DEJOURNALING","ActivePrefPerUpd"),-1)
 s sysquesiz=$g(^%SYS("DEJOURNALING","QueueSize"),-1)
 s sysstksiz=$g(^%SYS("DEJOURNALING","StackSize"),-1)
 s sysnumupd=$g(^%SYS("DEJOURNALING","NumUpdater"),0) $$$DEJRNLOG("sysnumupd="_sysnumupd)
 s sysrangemax=$g(^%SYS("DEJOURNALING","MaxRange"),-1)
								#;HYY2500+
 s inorder=0
								#;HYY2500-
 i type["jrnrest" {
   s maxpref=$g(^SYS("RESTORE","JOURNAL.FAST","prefetch"),sysmaxpref)
   s actprefperupd=$g(^SYS("RESTORE","JOURNAL.FAST","ActivePrefPerUpd"),sysactprefperupd)
   i type="jrnrest1" {
     s numupd=1 $$$DEJRNLOG("numupd=1 jrnrest1")
   } else {
     s numupd=$g(^SYS("RESTORE","JOURNAL.FAST","NumUpdater"),sysnumupd) $$$DEJRNLOG("numupd="_numupd_" jrnrest")
   }
   s rangemax=$g(^SYS("RESTORE","JOURNAL.FAST","MaxRange"),sysrangemax)
   s quesiz=$g(^SYS("RESTORE","JOURNAL.FAST","quesiz"),sysquesiz)
   s stksiz=$g(^SYS("RESTORE","JOURNAL.FAST","stksiz"),sysstksiz)
 } elseif type="shadow" {
   s maxpref=$g(^SYS("shdwcli",name,"prefetch"),sysmaxpref)
   s actprefperupd=$g(^SYS("shdwcli",name,"ActivePrefPerUpd"),sysactprefperupd)
   s numupd=1 $$$DEJRNLOG("numupd=1 shadow")
   s rangemax=$g(^SYS("shdwcli",name,"MaxRange"),sysrangemax)
     								#;HYY2181+
   i $g(quesiz)>0 s maxsiz=quesiz ;"GMHeapAdvisory" max # of pages by default
   #; The "GMHeapAdvisory" value is default limit on gmheap for queue or stack
   #; in *pages* & can be overriden by the user-specified "quesiz" or "stksiz"
   #; global node value, which is gmheap for queue or stack in *bytes*.
     								#;HYY2181-
   s quesiz=$g(^SYS("shdwcli",name,"quesiz"),sysquesiz)
   s stksiz=$g(^SYS("shdwcli",name,"stksiz"),sysstksiz)
 } elseif type="mirror" {
   s maxpref=$g(^MIRROR(name,"Config","NumPrefetch"),sysmaxpref)
   s actprefperupd=$g(^MIRROR(name,"Config","ActivePrefPerUpd"),sysactprefperupd)
   #;SML2393+ ;Setup multi-updater when this is a failover member or all members allowed (mode 2) or DR in mode 0.
   s dejrnmode=+$G(^SYS("MIRRORSET",name,"AllowParallelDejournaling"))
   s IsMember=$SYSTEM.Mirror.IsMember()
   if IsMember&&(IsMember=1||(dejrnmode=2)||(##class(Config.MirrorMember).IsDRMember()&&(dejrnmode=0))) {
	   s numupd=$g(^MIRROR(name,"Config","NumUpdater"),sysnumupd) $$$DEJRNLOG("numupd="_numupd_" mirror2")
	   s rangemax=$g(^MIRROR(name,"Config","MaxRange"),sysrangemax)
								#;HYY2500+
   } elseif $d(^MIRROR(name,"APD")) { ;has db entries
	   s numupd=$g(^MIRROR(name,"Config","NumUpdater"),sysnumupd) $$$DEJRNLOG("numupd="_numupd_" mirror2")
	   s rangemax=-1
	   ;db's not listed in ^MIRROR(name,"APD") are dejournaled in order
	   s inorder=1 
								#;HYY2500-
   } else {
	   s numupd=1 $$$DEJRNLOG("numupd=1 mirror1")
	   s rangemax=-1
   }
   #;SML2393-
   s quesiz=$g(^MIRROR(name,"Config","QueueSize"),sysquesiz)
   s stksiz=$g(^MIRROR(name,"Config","StackSize"),sysstksiz)
 } elseif type="mircatchup" {
   s maxpref=$g(^MIRROR(name,"Config","CatchupNumPrefetch"),sysmaxpref)
   s actprefperupd=$g(^MIRROR(name,"Config","CatchupActivePrefPerUpd"),sysactprefperupd)
   #;SML2393+ ;Setup multi-updater when this is a failover member or all members allowed (mode 2) or DR in mode 0.
   s dejrnmode=+$G(^SYS("MIRRORSET",name,"AllowParallelDejournaling"))
   s IsMember=$SYSTEM.Mirror.IsMember()
   if IsMember&&(IsMember=1||(dejrnmode=2)||(##class(Config.MirrorMember).IsDRMember()&&(dejrnmode=0))) {
	   s numupd=$g(^MIRROR(name,"Config","CatchupNumUpdater"),sysnumupd) $$$DEJRNLOG("numupd="_numupd_" mircatchup2")
	   s rangemax=$g(^MIRROR(name,"Config","CatchupMaxRange"),sysrangemax)
								#;HYY2500+
   } elseif $d(^MIRROR(name,"APD")) { ;has db entries
	   s numupd=$g(^MIRROR(name,"Config","CatchupNumUpdater"),sysnumupd) $$$DEJRNLOG("numupd="_numupd_" mircatchup2")
	   s rangemax=-1
	   ;db's not listed in ^MIRROR(name,"APD") are dejournaled in order
	   s inorder=1 
								#;HYY2500-
   } else {
	   s numupd=1 $$$DEJRNLOG("numupd=1 mircatchup1")
	   s rangemax=-1
   }
   #;SML2393-
   s quesiz=$g(^MIRROR(name,"Config","CatchupQueueSize"),sysquesiz)
   s stksiz=$g(^MIRROR(name,"Config","CatchupStackSize"),sysstksiz)
 } else {	;not supported option
   q $$$ERROR($$$InvalidParameter,"type",type)
 }
 s status=$$$OK
 i numupd<0 { // default (unspecified)
   s numupd=1 $$$DEJRNLOG("numupd=1 <0")
 } elseif $$$DEJRNUPDMAX<numupd {
   d $$$LOGMSG("Invalid number ("_numupd_") of dejournaling updaters - use system maximum instead",1,1)
   s numupd=$$$DEJRNUPDMAX $$$DEJRNLOG("numupd="_numupd_" max")
 }
 #; ^("prefetch")="" (NOT undefined) means use default algorithm (-1).
 #; ^("prefetch")=0 (NOT "") means no prefetching.
 i maxpref="" s maxpref=-1 ;default
     								#;HYY2138+
 i actprefperupd="" s actprefperupd=-1 ;default
     								#;HYY2138-
 i 'maxpref||'actprefperupd {
   s (maxpref,numpref,actprefperupd)=0 ;no prefetching
 } else { // maxpref and actprefperupd <0 (default) or >0 (user-specified)
   i maxpref<0 {
     s maxpref=$$$DEJRNPREFMAXDEF // default max # of prefetchers
   } elseif $$$DEJRNPREFMAXLMT<maxpref {
     d $$$LOGMSG("Invalid limit ("_maxpref_") on number of prefetchers for dejournaling - use system maximum instead",1,1)
     s maxpref=$$$DEJRNPREFMAXLMT
   }
     								#;HYY2137+
   i $$$DEJRNAFPUMAX<actprefperupd {
     d $$$LOGMSG("Invalid number ("_actprefperupd_") of active prefetchers per dejournaling updater - use system maximum instead",1,1)
     s actprefperupd=$$$DEJRNAFPUMAX ;max # of active prefetchers per updater
   }
     								#;HYY2137-
   s numcpu=$$$NUMCPU
   i numupd=1 {
     i actprefperupd<0 { // default
       s numpref=$s(numcpu<3:1,numcpu>6:6,1:numcpu-1)
       i numpref>maxpref s numpref=maxpref
     } else {
       s numpref=actprefperupd
     }
     								#;HYY2137+
   } elseif 'numupd { ;# of updaters unspecified -- get default
     s maxsiz=$$$GETCURGMHPAGES\4+1 ;# of pages
     								#;HYY2181+
     #; allow user-specified value to override the default max size
     i quesiz>0,quesiz\65536>maxsiz s maxsiz=quesiz\65536
     								#;HYY2181-
     s updmax=maxsiz\(50*1024*1024/65536) i updmax<1 s updmax=1
     $$$DEJRNLOG("updmax="_updmax_" limit by gmheap "_maxsiz)
     #; ##class(%SYS.System).GetGlobalCache() returns global buffer pool size in MBs
     s defupd=##class(%SYS.System).GetGlobalCache()\1024\32
     s defupd=$select(defupd<4:4,defupd>16:16,1:defupd) ;from 4 (<160GB) to 16 (>=512GB)
     i updmax>defupd s updmax=defupd $$$DEJRNLOG("updmax="_updmax_" limit by global buffers")
     i $g(inorder) {	;the APD case
       i actprefperupd<0 {
         #; treat the case as if the user specified #active prefetchers/updater
	 s actprefperupd=$s(numcpu<3:1,numcpu>6:6,1:numcpu-1)
	 i maxpref>0,maxpref<actprefperupd s actprefperupd=maxpref
       }
       i updmax>6 s updmax=6
       ; numupd and numpref are set in the else case (actprefperupd>0) below
     }
     if actprefperupd<0 { ;to derive defaults based on #CPUs
       i (updmax=1)||(numcpu<8)||((0<maxpref)&&(maxpref<6)) {
	 s numupd=1 $$$DEJRNLOG("numupd=1 numcpu="_numcpu_" maxpref="_maxpref)
     								#;HYY2181+
       } else { ;updmax>1, numcpu>=8 and maxpref>=6 or unspecified
     								#;HYY2181-
	 s numupd=numcpu\3 $$$DEJRNLOG("numupd="_numupd_"="_numcpu_"\3") ;2 active prefetchers for each updater
     								#;HYY2138+
	 i numupd>updmax s numupd=updmax $$$DEJRNLOG("numupd="_updmax_"=updmax")
     								#;HYY2138-
	 i maxpref>0,numupd*2>maxpref s numupd=maxpref\2 $$$DEJRNLOG("numupd="_numupd_"="_maxpref_"\2")
       }	
       i numupd=1 {
         s numpref=$s(numcpu<3:1,numcpu>6:6,1:numcpu-1)
         i numpref>maxpref s numpref=maxpref
       } else {
     								#;HYY2138+
         s numpref=$s(numupd=2:6,1:numupd*2)
     								#;HYY2138-
       }
     } else { ;to derive #updaters from #(active) prefetchers and #CPUs
       i maxpref>0 { ;max #prefetchers is specified
         s numupd=maxpref\actprefperupd $$$DEJRNLOG("numupd="_maxpref_"\"_actprefperupd)
	 i numupd<updmax s updmax=numupd $$$DEJRNLOG("updmax="_updmax)
       }
       s numupd=numcpu\(1+actprefperupd) $$$DEJRNLOG("numupd="_numcpu_"\(1+"_actprefperupd_")")
       i numupd<=1 {
         s numupd=1 $$$DEJRNLOG("numupd=1")
       } else {
         i numupd>updmax s numupd=updmax $$$DEJRNLOG("numupd="_updmax_"=updmax")
       }
       s numpref=numupd*actprefperupd
     }
     								#;HYY2137-
   } else { // 1<numupd<=$$$DEJRNUPDMAX
     i actprefperupd<0 { // default
       i $g(inorder) { ;the APD case
         s numpref=6*numupd ;may be adjusted down below due to numcpu limit
       } else {
         s numpref=$s(numupd>3:2*numupd,1:6)
       }
       ; #updaters <= total #active prefetchers <= #CPUs - #updaters
       i numpref>numcpu-numupd s numpref=(numcpu\numupd-1)*numupd
       i maxpref>0,maxpref<numpref s numpref=(maxpref\numupd)*numupd
       i numpref<numupd s numpref=numupd ;may override numcpu or maxpref limit
     } elseif $$$DEJRNAFPUMAX<actprefperupd {
       d $$$LOGMSG("Invalid number ("_actprefperupd_") of active prefetchers per dejournaling updater - use system maximum instead",1,1)
       s numpref=$$$DEJRNAFPUMAX*numupd
     } else {
       s numpref=actprefperupd*numupd
     }
   }
   #;NB: $$$DEJRNAFPUMAX*$$$DEJRNUPDMAX <= $$$DEJRNPREFMAXLMT
   i maxpref<numpref s maxpref=numpref
 }
     								#;HYY2198+
 i numupd<=0 s numupd=1 $$$DEJRNLOG("numupd=1 0")
     								#;HYY2198-
 s sizmod=2 ;indicating quesiz and stksiz values upon return are in pages
 i 'quesiz s quesiz=-1 ;quesiz=0 or "" is treated the same as -1
 i quesiz'=-1,quesiz<65536 { ;user-specified quesiz is in bytes
   d $$$LOGMSG("Invalid queue size ("_quesiz_" bytes) for dejournaling - use default setting instead",1,1)
   s quesiz=-1
 }
 i quesiz<=0,numpref { ;default setting for queue size (w/ prefetching on)
   #; Queue size is 50MB per updater, capped by 1/4 of free gmheap in total. 
   s quesiz=50*1024*1024*numupd 
     								#;HYY2181+
   s maxsiz=$g(maxsiz,$$$GETCURGMHPAGES\4+1)
     								#;HYY2181-
   i quesiz/65536>maxsiz s quesiz=maxsiz*65536
 }
 i quesiz>0 {
   s sizmod=sizmod+4 
   s quesiz=quesiz/65536 ;convert #bytes to #pages
 } elseif 'numpref {
   s sizmod=sizmod+4 ;prevent queue from growing (it shouldn't anyway)
   s quesiz=1 ;minimum quesiz for no prefetching (to be adjusted internally)
 }
 i 'stksiz s stksiz=-1 ;stksiz=0 or "" is treated the same as -1
 i stksiz'=-1,stksiz<65536 { ;user-specified stksiz is in bytes
   d $$$LOGMSG("Invalid stack size ("_stksiz_" bytes) for dejournaling - use default setting instead",1,1)
   s stksiz=-1
 }
 i stksiz>0 {
   s sizmod=sizmod+8 
   s stksiz=stksiz/65536 ;convert #bytes to #pages
 } elseif 'numpref {
   s stksiz=1 ;minimum stksiz for no prefetching (to be adjusted internally)
     								#;HYY2184+
 } else {
   #; By default, stack size = queue size. In this case, stack could grow.
   s stksiz=quesiz ;both values are in pages now
   s maxsiz=$g(maxsiz,$$$GETCURGMHPAGES\4+1) ;in pages
   i stksiz>maxsiz s stksiz=maxsiz
     								#;HYY2184-
 }
 q status
}

/// Returns status of the journaling system. <p>
/// Example:<example>
///   s rs=##class(%ResultSet).%New("%SYS.Journal.System:Status")
///   s rc=rs.Execute() w rc
///   while rs.Next() { w rs.Data("Main Status"),! h 10 }
/// </example>
/// Here the journaling status of a remote system is retrieved and displayed every 10 seconds.
/// See <class>%RemoteResultSet</class> for details on how to use it. 
Query Status() As %Query(ROWSPEC = "Main Status:%String,Cause:%String,Full Status:%String")
{
}

ClassMethod StatusExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	q $$$OK
}

ClassMethod StatusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s qHandle=$$$JRNSTATUS,$li(Row,3)=qHandle
	i ..IsDisabled(qHandle,.Cause) s $li(Row,1)="disabled",$li(Row,2)=Cause q $$$OK
	i ..IsFrozen(qHandle,.Cause) s $li(Row,1)="frozen",$li(Row,2)=Cause q $$$OK
	i ..IsGettingIOError(qHandle,.Cause) s $li(Row,1)="I/O error",$li(Row,2)=Cause q $$$OK
	i ..IsPaused(qHandle,.Cause) s $li(Row,1)="paused",$li(Row,2)=Cause q $$$OK
	s $li(Row,1)="OK",$li(Row,2)=""
	q $$$OK
}

ClassMethod StatusClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Returns info on journaling progress
/// Example:<example>
///   s rs=##class(%ResultSet).%New("%SYS.Journal.System:Progress")
///   s rc=rs.Execute() w rc
///   while rs.Next() { w $zdt(rs.Data("TimeStamp"),8),": ",$j(rs.Data("Offset"),10)," ",rs.Data("File Name"),! h 10 }
/// </example>
/// Here the current journal file name and offset are retrieved and displayed every 10 seconds.
Query Progress() As %Query(ROWSPEC = "File Name:%String,File Count:%Integer,Offset:%Integer,Offset Committed:%Integer,TimeStamp:%String")
{
}

ClassMethod ProgressExecute(ByRef qHandle As %Binary, GetCommitted As %Integer) As %Status [ Internal ]
{
	s qHandle=$g(GetCommitted)
	q $$$OK
}

ClassMethod ProgressFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	f  s FileName=..GetCurrentFileName(),FileCount=..GetCurrentFileCount(),Offset=..GetCurrentFileOffset(),TimeStamp=$zts s:qHandle Committed=..WhereCommitted() q:FileName=..GetCurrentFileName()
	s $li(Row,1)=FileName
	s $li(Row,2)=FileCount
	s $li(Row,3)=Offset
	s $li(Row,4)=$g(Committed)
	s $li(Row,5)=TimeStamp
	q $$$OK
}

ClassMethod ProgressClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Query returns a summary of the journaling system status.<br><br>
/// Example:<example>
///   s rs=##class(%ResultSet).%New("%SYS.Journal.System:Summary")
///   s rc=rs.Execute() w !,rs.GetColumnHeader(1),?40," ",rs.GetColumnHeader(2),!
///   while rs.Next() { w !,rs.Data("Parameter"),?40," ",rs.Data("Value") }
/// </example>
Query Summary() As %Query(ROWSPEC = "Parameter:%String,Value:%String")
{
}

ClassMethod SummaryExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	s $zt="error"
	s Index=$i($$$ISCQUERYTEMP)
	s qHandle=Index
	s qHandle("Current")=""
	d ##class(%SYS.Journal.System).GetDefaults(.curdir,.altdir,.maxsize,.expqty,.prefix,.shortnam)
	s row=1
	i $d(curdir) d
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Current journal directory","%Utility"),$g(curdir)),row=row+1
	.s x=$zu(140,13,curdir)
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Current journal directory free space (KB)","%Utility"),$p(x,",",2)*$p(x,",",4)/1024),row=row+1
	i $d(altdir),$l(altdir),$g(altdir)'=$g(curdir) d
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Alternate journal directory","%Utility"),$g(altdir)),row=row+1
	.s x=$zu(140,13,altdir)
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Alternate journal directory free space (KB)","%Utility"),$p(x,",",2)*$p(x,",",4)/1024),row=row+1
	s curfile=##class(%SYS.Journal.System).GetCurrentFileName()
	s $zt="state"
	i $l(curfile) d
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Current journal file","%Utility"),curfile),row=row+1
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Current journal file maximum size","%Utility"),$$$JRNMAXSIZE(curfile)),row=row+1
	.s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Current journal file space used","%Utility"),$p($$$JRNCUR,",",1)),row=row+1
state	;
	s $zt="error"
	s $$$ISCQUERYTEMP(Index,"Row",row)=$listbuild($$$Text("Journaling state","%Utility"),..GetStateString()),row=row+1	
	Quit $$$OK
error	;
	i $d(Index) d
	. k $$$ISCQUERYTEMP(Index)
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod SummaryFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = SummaryExecute ]
{
	s $zt="error"
	s rnum=$g(qHandle("Current")),rnum=$o($$$ISCQUERYTEMP(qHandle,"Row",rnum))
	i rnum'="" s Row=$$$ISCQUERYTEMP(qHandle,"Row",rnum)
	i rnum="" s AtEnd=1,Row=""
	s qHandle("Current")=rnum
	Quit $$$OK
error	;
	s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod SummaryClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = SummaryFetch ]
{
	i $d(qHandle) d
	. k $$$ISCQUERYTEMP(qHandle)
	Quit $$$OK
}

}
