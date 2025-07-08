/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %sySystem, %sySite, %syCluster, %syConfig)

/// Journaling history related API
Class %SYS.Journal.History Extends %RegisteredObject [ Abstract, System = 4 ]
{

ClassMethod GetHeader(jrnlogfd As %String, ByRef header As %String, Mirror As %Boolean = 0) As %Status [ Internal ]
{
  s $zt="Error"
  s zeof=$zu(68,40,0) ;we want <ENDOFFILE> triggered at EOF
  u jrnlogfd r logline
  #; issue a warning if the log doesn't contain a header??
  #;SML1599 ; Without VERSION= line treated as corrupted.
								#;HYY1960+
  i '$$$JRNLOGLineIsHdrKey(logline,$$$JRNLOGHdrKeyVersionU) q $$$ERROR($$$JrnLogNoVersion,jrnlogfd)
								#;HYY1960-
  s version=$p(logline,"=",2)
  #;SML1599 ; the mirror log did not have checksum, needs to rebuild.
  if Mirror&&(version\1=1) q $$$ERROR($$$JrnLogNoChecksum,jrnlogfd,version)
  i version\1>$s(Mirror:$$$MIRJRNLOGVERSION,1:$$$JRNLOGVERSION) q $$$ERROR($$$JrnLogBadVersion,jrnlogfd,version,$$$JRNLOGVERSION)
  s maxline=$p(logline,",",2) i 'maxline s maxline=$s(Mirror:$$$MIRJRNLOGHDRMaxLine,1:$$$JRNLOGHDRMaxLine)
  s linenum=1,header(1)=logline
  f  {  
    i $i(linenum)>maxline q   ;generate an error??
    u jrnlogfd r logline ;<ENDOFFILE> would lead to early termination
     								#;HYY1549+
    i $$$IsBlankLine(logline) continue  ;skip blank lines
     								#;HYY1549-
    s header(linenum)=logline
    i $$$JRNLOGLineIsHdrKey(logline,$$$JRNLOGHdrKeyEndU) q
  }
  i $zu(68,40,zeof) ;restore $ZEOF state if any
  q $$$OK
Error s $zt="" i $zu(68,40,zeof)
  q $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod Purge(DaysOld As %Integer = 100) As %Status [ Internal ]
{
#; For a log entry to be eligible for purging, the corresponding file must
#; have been purged (doesn't exist or is no longer valid) and the file (and
#; therefore the log entry) must be at least X days old, where X = DaysOld.
#; In addition, all log entries preceding it must be eligible for purging,
#; too.
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  s jrnlog=$zu(12)_"journal.log"
  s errhdr="Journal History Purge: "
  								#;HYY1658+
  #; create a temporary copy
  #; The TempFileName() method requires global access and therefore should
  #; be called before jrnlog lock is acquired to avoid a deadlock situation.
  								#;HYY1919+
  								#;HYY2421+
  #; tmplog must be created in mgr directory, where journal.log is.
  s tmplog=$zu(12)_##class(%FileBinaryStream).NewFileName("tmp")
  								#;HYY2421-
  								#;HYY1919-
  								#;HYY1658-
  s $zt="ErOpenLog"
  i $$$JRNLOGWTLCKSET
  s etstate=1 ;log file locked (must be released upon exit)
  $$$JrnLogOpenForRead(jrnlog):0 e  d $$$JRNLOGWTLCKCLR q $$$ERROR($$$FileCanNotOpen,jrnlog)
  s etstate=2 ;log file opened (must be closed upon exit)
  s rc=..GetHeader(jrnlog,.logheader)
  i 'rc d $$$JRNLOGWTLCKCLR c jrnlog q rc
    #; If the file contains no header (an old version), we have to re-open
    #; it to read from the beginning, as GetHeader() has read past
    #; its first line.
  i '$d(logheader) c jrnlog $$$JrnLogOpenForRead(jrnlog):0 e  d $$$JRNLOGWTLCKCLR q $$$ERROR($$$FileCanNotOpen,jrnlog)
  s filepath="",nextfile=""
  #; Find the first log entry that does NOT meet the following purge criteria:
  #; (1) the file no longer exists (or is no longer a journal file);
  #; (2) the file was created prior to the given date limit (= today - DaysOld)
  #; Unlike the criterion for purging journal files, we use the creation time
  #; of a file (i.e., the time when the corresponding log entry was made)
  #; instead of its completion time, just to keep things a bit simpler.
  s purgecnt=0 ;# of files to purge
  s lastchksum=0 ;chksum of the last entry to be purged
  								#;HYY1658+
  s zeofset=$zu(68,40,1)
  f  {
    u jrnlog r logline i $ZEOF q  ;nothing to purge
  								#;HYY1658-
     								#;HYY1549+
    i $$$IsBlankLine(logline) continue  ;skip blank lines
     								#;HYY1549-
    s jrnfile=$p(logline,",",2)
    i $zu(78,22,jrnfile)>0 q  ;found the oldest journal file that exists
    #; jrnfile either doesn't exist anymore or is not a valid journal file
    s timestamp=$p(logline,",",$$$JRNLOGRecTime) ;creation time in UTC
    s hdate=$zdateh(timestamp,3) ;
    i $h-$zu(193,hdate,0)<DaysOld q  ;found the oldest entry to keep
    #; current entry meets purging criteria; skip it and keep looking
    s purgecnt=purgecnt+1 ;# of files to purge
    s lastchksum=$p(logline,",",$$$JRNLOGRecChksum)
  }
  								#;HYY1658+
  i zeofset,$zu(68,40,0)
  i 'purgecnt g ExitPurge
  s oldmask=$zu(47,$$$JRNLOGumask)
  o tmplog:("wns":/IOT="UTF8"):0 s created=$t
  d $zu(47,oldmask) ;restore previous umask
  								#;HYY1658-
  i 'created c jrnlog d $$$JRNLOGWTLCKCLR q $$$ERROR($$$FileCanNotOpen,tmplog)
  s $zt="ErPostCreateTmp"
  #; copy log header to the temporary copy with edition# bumped & a new base
  s newbase=0 ;set to 1 after a new base chksum is written
  s linenum="" f  s linenum=$o(logheader(linenum)) q:linenum=""  d 
  . s hdrline=logheader(linenum)
  . i $$$JRNLOGLineIsHdrKey(hdrline,$$$JRNLOGHdrKeyEditionU) d
  . . s hdrline=$p(hdrline,"=",2,$l(hdrline))
  . . s edition=hdrline+1 ;bump edition by 1
  . . s time=$zdt($h,3)
  . . u tmplog w $$$JRNLOGHdrKeyEditionM,edition,",,",time,!
  . e  i $$$JRNLOGLineIsHdrKey(hdrline,$$$JRNLOGHdrKeyBaseU) d
      #; the chksum of the last entry to be purged would be the new base chksum
  . . s $p(hdrline,"=",2)=lastchksum 
  . . s newbase=1
  . . u tmplog w hdrline,!
  . e  i $$$JRNLOGLineIsHdrKey(hdrline,$$$JRNLOGHdrKeyEndU),'newbase d
      #; before we write the header end, add a BASE= line if it hasn't
      #; been written yet
  . . u tmplog w $$$JRNLOGHdrKeyBaseM,lastchksum,!
  . . s newbase=1
  . . u tmplog w hdrline,!
  . e  u tmplog w hdrline,!
  #; if we are here, logline is the first entry to keep in the log
  u tmplog w logline,!
  #; copy from that entry and on to the temp copy
  s zeofset=$zu(68,40,1)
  f  {
    u jrnlog r logline i $ZEOF=-1 c jrnlog,tmplog q  ;done
     								#;HYY1549+
    i $$$IsBlankLine(logline) continue  ;skip blank lines
     								#;HYY1549-
    u tmplog w logline,!
  }
  i zeofset,$zu(68,40,0)
  #; Lock original for read, blocking both read and write
  i $$$JRNLOGRDBANSET
  s $zt="ErPostReadBan",Status=$$$OK
								#;HYY2031+
  #; save tmplog to recover jrnlog from if the job died after deleting jrnlog
  i $$$RegisterJrnLogFiles(0,tmplog,jrnlog)
								#;HYY2031-
  #; Swap the temp copy to the original (rename or delete and copy)
  #; Alternatively, we could copy the temp one to the original and 
  #; delete the temp one; but delete-and-rename is more efficient.
  s rc=$zu(140,5,jrnlog) ;delete the original
  i rc<0 {
    d $zu(9,"",$g(errhdr)_"Error deleting "_jrnlog_": "_rc)
    								#;HYY1658+
    i $$$JRNLOGRDBANCLR
    i $$$JRNLOGWTLCKCLR
								#;HYY2031+
    #; tmplog no longer needed once locks are released
    i $$$UnregisterJrnLogFiles(0)
								#;HYY2031-
    #; The jrnlog lock must be released before we create the error status,
    #; which requires global access.
    								#;HYY1658-
    s Status=$$$ERROR($$$FileCanNotDelete,jrnlog)
  } else {
    s rc=$zu(140,6,tmplog,jrnlog) ;rename the temp one to original
    								#;HYY1658+
    i $$$JRNLOGRDBANCLR
    i $$$JRNLOGWTLCKCLR
    								#;HYY1658-
								#;HYY2031+
    #; tmplog no longer needed once locks are released
    i $$$UnregisterJrnLogFiles(0)
								#;HYY2031-
    i rc<0 {
      d $zu(9,"",$g(errhdr)_"Error renaming to "_jrnlog_": "_rc)
      s Status=$$$ERROR($$$FileCanNotRename,jrnlog)
  								#;HYY2453+
    } else {
      s switched=##class(%SYS.Journal.System).RollToNextFile($g(reason,$$$JRNSWREASONACTIVATE))
  								#;HYY2453-
    }
  }
  q Status
  								#;HYY1658+
ExitPurge ;
  i $$$JRNLOGWTLCKCLR
  i '$g(zeofset,1),$zu(68,40,0) ;reset it only if zeofset is explicitly set to 0
  i $g(etstate)=2 c jrnlog
  q $g(Status,$$$OK)
ErOpenLog s $zt="" i $$$JRNLOGWTLCKCLR
  i $g(etstate)=2 c jrnlog
  								#;HYY1658-
  i $ze'["<ENDOFFILE>",$ze'["<ZNONE>" s Status=$$$ERROR($$$ObjectScriptError,$ze)
		  						#;HYY1578+
  e  s Status=$$$OK,$ze=""
		  						#;HYY1578-
  i '$g(zeofset,1),$zu(68,40,0) ;reset it only if zeofset is explicitly set to 0
  q Status
  								#;HYY1677+
ErPostCreateTmp s $zt="ErOpenLog" 
  i $ze'="" d BACK^%ETN s $ze="" ;HYY000
  #;delete the temp log file
  c tmplog s rc=$zu(140,5,tmplog) 
  i rc<0 d $zu(9,"",$g(errhdr)_"Error deleting "_tmplog_": "_rc)
  g ErOpenLog
ErPostReadBan s $zt="ErPostCreateTmp"
  i $$$JRNLOGRDBANCLR
								#;HYY2031+
  i $ze'="" d BACK^%ETN s $ze="" ;HYY000
  #; tmplog no longer needed once rd ban is lifted
  i $$$UnregisterJrnLogFiles(0)
								#;HYY2031-
  g ErPostCreateTmp
  								#;HYY1677-
}

ClassMethod Validate(HistoryLogFile As %String) As %Integer [ Internal ]
{
  q $zu(78,83,HistoryLogFile)
}

ClassMethod CreateLog(HistoryLogFile As %SysPath) As %Status [ Internal ]
{
  // open/create 'HistoryLogFile' with proper header
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  i $g(HistoryLogFile)="" s HistoryLogFile=$zu(12)_"journal.log"
  s Status=($$$JrnLogOpenCreate(HistoryLogFile)>0)
  q Status
}

ClassMethod UpdateLog(JournalFilePath As %SysPath) As %Status [ Internal ]
{
  // Write an entry to the log file opened via <method>CreateLog</method>
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  s Status=($$$JrnLogAppend(JournalFilePath)>0)
  q Status
}

ClassMethod CloseLog() As %Status [ Internal ]
{
  // Close the log file opened via <method>CreateLog</method>
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  i $$$JrnLogClose
  q $$$OK
}

ClassMethod Build(LogFile As %SysPath, ByRef JrnFiles As %String) As %Status [ Internal ]
{
  // Build a journal log with the given list of journal files 'JrnFiles', where
  // JrnFiles(FileIndex) = JrnFilePath (higher FileIndex => newer JrnFilePath)
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  i $g(LogFile)="" s LogFile=$zu(12)_"journal.log"
  s rc=$$$JrnLogOpenCreate(LogFile) 
  i rc<1 u 0 w !,"Failed to create ",LogFile q 0
  s $zt="Error"
  s FileIndex=""
  f  {
	#;SML2302 ; The JrnFiles is reference of the array.
    s FileIndex=$o(JrnFiles(FileIndex),1,JrnFile)
    i FileIndex="" q
    s rc=$$$JrnLogAppend(JrnFile)
    i rc<0 u 0 w !,JrnFile," doesn't exist or is not a journal file" q
    e  i 'rc u 0 w !,"Failed to update the log with an entry about ",JrnFile q
  }
  i $$$JrnLogClose
  q (rc=1)
Error s $zt="" u 0 w !,$ze,!
  i $$$JrnLogClose
  q -1
}

ClassMethod CopyLog(SourceLogFile As %SysPath, TargetLogFile As %SysPath) As %Status [ Internal ]
{
  // Create 'TargetLogFile' and copy entries from 'SourceLogFile' to 'TargetLogFile'
  // For test purpose only.
  i '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
  i $$$JRNLOGWTLCKSET
  s $zt="Error"
  $$$JrnLogOpenForRead(SourceLogFile):0 e  d $$$JRNLOGWTLCKCLR q $$$ERROR($$$FileCanNotOpen,SourceLogFile)
  s rc=..GetHeader(SourceLogFile,.SourceLogHeader)
  i 'rc d $$$JRNLOGWTLCKCLR c SourceLogFile q rc
  s zeof=$zu(68,40,1) ;set $ZEOF at end of file
  #;SML2302+ ; Set large storage to avoid <STORE> error.
  s OrigStorage=$ZSTORAGE
  s $ZSTORAGE=2147483647
  s JrnFiles=0 ;FileIndex
  #;SML2302-
  f  {
    u SourceLogFile r logline q:$ZEOF  ;end of file
     								#;HYY1549+
    i $$$IsBlankLine(logline) continue  ;skip blank lines
     								#;HYY1549-
    #;SML2302 ; Use local variable to avoid deadlock with JD.
    s JrnFiles($i(JrnFiles))=$p(logline,",",2)
  }
  i 'zeof,$zu(68,40,0) ;restore <ENDOFFILE> mode if it was the old state
  c SourceLogFile d $$$JRNLOGWTLCKCLR  ;done reading 'SourceLogFile'
  s $zt="" ;clear the error trap that clears WTLCK and closes SourceLogFile
  s FileIndex=""
  f  {
    #;SML2302 ; Use local variable to avoid deadlock with JD.
    s FileIndex=$o(JrnFiles(FileIndex),-1,JrnFile)
    i $$$JRNCHECK(JrnFile)<1 {
      // found the latest log entry that is no longer valid
      // it and all entries prior to it will be skipped
      #;SML2302+ ; Use local variable to avoid deadlock with JD.
      k JrnFiles(FileIndex)
      f  s FileIndex=$o(JrnFiles(FileIndex),-1) q:FileIndex=""  k JrnFiles(FileIndex)
      #;SML2302-
      q
    }
  }
  #;SML2302+ ; Use local variable to avoid deadlock with JD.
  s rc=..Build(TargetLogFile,.JrnFiles)
  k JrnFiles
  s $ZSTORAGE=OrigStorage
  #;SML2302-
  q rc
Error s $zt="" u 0 w !,$ze,!
  #;SML2302+ ; Use local variable to avoid deadlock with JD.
  k JrnFiles ;FileIndex
  if $d(OrigStorage) s $ZSTORAGE=OrigStorage
  #;SML2302-
  c SourceLogFile d $$$JRNLOGWTLCKCLR
  q -1
}

/// Load the HistoryLogFile entries into the JrnFileInfo array
ClassMethod LoadLog(HistoryLogFile As %String, ByRef JrnFileInfo As %SysPath, ByRef LogHeader As %String) As %Status [ Internal ]
{
  	
  	i ($g(HistoryLogFile)="")||(HistoryLogFile=$zu(12)_"journal.log") q ..LoadLocalLog(.JrnFileInfo,.LogHeader)
  	$$$JrnLogOpenForRead(HistoryLogFile):0 e  q $$$ERROR($$$FileCanNotOpen,HistoryLogFile)
  	s $zt="LoadLogError"
	s Status=##class(%SYS.Journal.System).GetHistoryHeader(HistoryLogFile,.LogHeader)
	i 'Status c HistoryLogFile q Status
	s zeofset=$zu(68,40,1)
	s JrnFileInfo=0 ;# of journal files
	f  {
	   u HistoryLogFile r logline i $ZEOF c HistoryLogFile q  ;end of file
	   i $$$IsBlankLine(logline) continue  ;skip blank lines
	   s JrnFileInfo($i(JrnFileInfo))=logline
	}
	i $zu(68,40,zeofset)
	q $$$OK
LoadLogError s $zt="" 
	c HistoryLogFile 
	i $d(zeofset),$zu(68,40,zeofset)
	q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Load the HistoryLogFile entries into the JrnFileInfo array
ClassMethod LoadLocalLog(ByRef JrnFileInfo As %SysPath, ByRef LogHeader As %String) As %Status [ Internal ]
{
  	
  	s HistoryLogFile=$zu(12)_"journal.log"
	i $$$JRNLOGRDSHRSET ;log file locked (must be released upon exit)
	s $zt="LoadLocalError"
  	$$$JrnLogOpenForRead(HistoryLogFile):0 e  d $$$JRNLOGRDSHRCLR q $$$ERROR($$$FileCanNotOpen,HistoryLogFile)
	s Status=##class(%SYS.Journal.System).GetHistoryHeader(HistoryLogFile,.LogHeader)
	i 'Status d $$$JRNLOGRDSHRCLR c HistoryLogFile q Status
	s zeofset=$zu(68,40,1)
	s JrnFileInfo=0 ;# of journal files
	f  {
	   u HistoryLogFile r logline i $ZEOF d $$$JRNLOGRDSHRCLR c HistoryLogFile q  ;end of file
	   s JrnFileInfo($i(JrnFileInfo))=logline
	}
	i $zu(68,40,zeofset)
	q $$$OK
LoadLocalError s $zt="" 
	d $$$JRNLOGRDSHRCLR c HistoryLogFile 
	i $d(zeofset),$zu(68,40,zeofset)
	q $$$ERROR($$$ObjectScriptError,$ze)
}

}
