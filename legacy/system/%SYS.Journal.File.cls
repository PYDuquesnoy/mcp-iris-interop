/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %syPidtab, FILEINC)

/// Journal file related API
Class %SYS.Journal.File Extends %Persistent [ StorageStrategy = JournalFileStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Path of the journal file
Property Name As %SysPath [ ReadOnly ];

Property Chan As %Integer [ InitialExpression = -1, Internal, ReadOnly ];

/// The end of the last valid record in the journal file (applicable to open file only)
Property End As %Integer [ Calculated ];

/// Object reference to the first record in the journal file (applicable to open file only)
Property FirstRecord As %SYS.Journal.Record [ Calculated ];

/// Object reference to the last record in the journal file (applicable to open file only)
Property LastRecord As %SYS.Journal.Record [ Calculated ];

/// Object reference to the last marker record in the journal file (applicable to open file only)
Property LastMarker As %SYS.Journal.Marker [ Calculated ];

/// Cluster start time in time(0) format (i.e., # of seconds since the Epoch)
/// or 0 if not a cluster journal file
Property ClusterStartTime0 As %Integer [ Calculated ];

/// Cluster start time in %TimeStamp format or "" if not a cluster journal file
Property ClusterStartTime As %String [ Calculated ];

Method %LoadData(FileName As %String, flag As %Boolean) As %Status [ Private ]
{
	q ..Open(FileName)
}

/// To open a journal file for record retrieval
Method Open(FileName As %String) As %Status
{
	s FileName=$zu(12,FileName,0)
	s rc=..IsValidJournal(FileName) i rc'=$$$OK q rc
								#;HYY1872+
	i $d(i%Chan),i%Chan'<0,$$$JRNCLOSE(i%Chan)
								#;HYY1872-
	s i%Chan=$$$JRNOPEN(FileName,0) i i%Chan<0 q $$$ERROR($$$JournalFileOpenForRecordFailed,FileName)
	s i%Name=FileName i $$$JRNUSE(i%Chan)
	q $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	i $d(i%Chan),i%Chan'<0,$$$JRNCLOSE(i%Chan)
	q $$$OK
}

Method %OnNew() As %Status [ Private ]
{
	s rc=##class(%SYS.Journal.System).SwitchFile() i rc'=$$$OK q rc
	q ..Open($$$JRNCURNAM)
}

/// To use an open journal file for record retrieval (necessary when you have multiple journal file instances
/// open at the same time and need to switch from one file to another).
Method Use() As %Integer
{
	q $$$JRNUSE(i%Chan)
}

Method EndGet() As %Integer
{
	q $$$JRNPREV(0)
}

/// TRUE if the given <parameter>FileName</parameter> is a journal file
ClassMethod IsValidJournal(FileName As %String) As %Status
{
	s status=$$$JRNCHECK(FileName) q:status>0 $$$OK
	i status=0 q $$$ERROR($$$JournalFileNotExist,FileName)
	q $$$ERROR($$$JournalFileInvalid,FileName)
}

Method FirstRecordGet() As %SYS.Journal.Record
{
	s addr=$$$JRNNEXT(0) i addr'>0 q $$$NULLOREF
	q ##class(%SYS.Journal.Record).%OpenId(addr)
}

Method LastRecordGet() As %SYS.Journal.Record
{
	s addr=$$$JRNPREV(0) i addr'>0 q $$$NULLOREF
	s addr=$$$JRNPREV(addr) i addr'>0 q $$$NULLOREF
	q ##class(%SYS.Journal.Record).%OpenId(addr)
}

Method ClusterStartTime0Get() As %Integer
{
	q $$$JRNHDRINFO(0)
}

Method ClusterStartTimeGet() As %String
{
	q $s($$$JRNHDRINFO(0):$zdt($$$JRNHDRINFO(1),3),1:"")
}

/// Return the object reference to the record at the given journal location (<parameter>Address</parameter>)
Method GetRecordAt(Address As %Integer) As %SYS.Journal.Record
{
	q ##class(%SYS.Journal.Record).%OpenId(Address)
}

/// Return the object reference to the record after the given journal location (<parameter>Address</parameter>)
Method GetRecordAfter(Address As %Integer) As %SYS.Journal.Record
{
	s rec=##class(%SYS.Journal.Record).%OpenId(Address) i $IsObject(rec) q rec.Next
	s addr=Address\$$$JRNBLKSIZ*$$$JRNBLKSIZ 
	f  s addr=$$$JRNNEXT(addr) q:addr>Address  q:addr'>0
	i addr'>0 q $$$NULLOREF
	q ##class(%SYS.Journal.Record).%OpenId(addr)
}

/// Return the object reference to the record prior to the given journal location (<parameter>Address</parameter>)
Method GetRecordBefore(Address As %Integer) As %SYS.Journal.Record
{
	#;Not sure why GetRecordAfter has 2 ways of doing this, it seems to imply that
	#;there can be a transient problem getting the subsequent record. Whatever it is,
	#;I don't think it applies to getting the previous record which should already exist.
	#;s rec=##class(%SYS.Journal.Record).%OpenId(Address) i $IsObject(rec) q rec.Prev
	s addr=$$$JRNPREV(Address)
	i addr'>0 q $$$NULLOREF
	q ##class(%SYS.Journal.Record).%OpenId(addr)
}

Method LastMarkerGet() As %SYS.Journal.Record
{
	s addr=$$$GETJRNMARK(0) i addr'>0 q $$$NULLOREF
	q ##class(%SYS.Journal.Marker).%OpenId(addr)
}

/// Purpose: Get journal file prior to the given journal file <p>
/// InSession: whether to limit the search within a journal session (default=NO)
ClassMethod GetPrev(FileName As %String = "", ByRef PrevFileName As %String, InSession As %Boolean, MirOnly As %Boolean = 0, MirrorSetName As %String = "") As %Status
{
								#;HYY2288+
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	s $zt="Error"
	i MirOnly,$g(FileName)="",$g(PrevFileName)="" {
		s firstFile=""
		#;SML1439 ; Pass Mirror Set Name to the PREVJRN^JRNUTIL2.
		s rc=$$PREVJRN^|"%SYS"|JRNUTIL2(.firstFile,,,,1,MirrorSetName)
		s PrevFileName=firstFile
	}
	else {
		#;SML1439 ; Pass Mirror Set Name to the PREVJRN^JRNUTIL2.
		s rc=$$PREVJRN^|"%SYS"|JRNUTIL2(FileName,.PrevFileName,+$g(InSession),,MirOnly,MirrorSetName)
								#;HYY2325-
	}
	#;JO2141-
	i rc'>0 q $$$ERROR($$$JournalFilePrevError,FileName,rc)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Purpose: Get journal file following the given journal file <p>
ClassMethod GetNext(FileName As %String, ByRef NextFileName As %String, MirOnly As %Boolean = 0, MirrorSetName As %String = "") As %Status
{
	#;SML1439 ; Pass Mirror Set Name to the NEXTJRN^JRNUTIL2.
								#;HYY2288+
	#; switch to %SYS as ^JRNUTIL2 may call ^JRNUTIL
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	s $zt="Error"
	s rc=$$NEXTJRN^|"%SYS"|JRNUTIL2(FileName,.NextFileName,,,MirOnly,MirrorSetName)
								#;HYY2325-
	#;JO2141-
	i rc'>0 q $$$ERROR($$$JournalFileNextError,FileName,rc)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Purpose: Get max size of a journal file
ClassMethod GetMaxSize(FileName As %String) As %Integer
{
	q $$$JRNMAXSIZE(FileName)
}

/// Get the GUID assigned to the given journal file.
/// 
ClassMethod GetGUID(FileName As %String) As %String [ CodeMode = expression ]
{
$p($zu(78,22,FileName,$$$JrnHdrTHISGUID),",",2)
}

/// Get the GUID assigned to this system in the mirror configuration file. <br>
/// This is used to help people identify which system created the journal file.<br>
/// Since this comes from the config file, it's possible that this can change over time but its not supposed to.
ClassMethod GetSystemGUID(FileName As %String) As %String [ CodeMode = expression ]
{
$p($zu(78,22,FileName,$$$JrnHdrSYSGUID),",",2)
}

ClassMethod GetMirrorGUID(FileName As %String) As %String [ CodeMode = expression ]
{
$p($zu(78,22,FileName,$$$JrnHdrMIRGUID),",",2)
}

/// Purpose: Check integrity of the journal file(s) <br>
/// jrnlist can be either a file path or, if passed by reference, a number-indexed array of file paths, e.g.: <br>
/// jrnlist(1)=path1, jrnlist(2)=path2, etc. <br>
/// The file paths in the array should be in chronicle order, that is, path1 and 
/// path2 are assumed to have been created consecutively in the example above.
/// If it is determined that the files in the given array do not meet that 
/// criterion, a single value 0 is returned (for "Invalid Parameter") and the top
/// node of the array is set to the number index of the offending path. <br>
/// Detail: If 1, scan each given journal file forward to locate the last record and verify it is the last record to be expected.<br>
/// 	If 2, verify values stored in each record are retrievable.<br>
/// If SrcDirs is set to 1 and passed by reference, the database directories used in the
/// specified journal file(s) will be stored in SrcDirs array upon return.
ClassMethod CheckIntegrity(ByRef jrnlist As %String, Detail As %Integer = 0, ByRef SrcDirs As %String, quietly As %Integer = 1) As %Status
{
	i $d(jrnlist)<10 {	// a single file is specified
	  s path=$g(jrnlist)
	  s Status=$$$JRNHDRALL(path)
	  i 'Status q $$$ERROR($$$JournalFileNotExist,path)
	  i Status<0 q $$$ERROR($$$JournalFileInvalid,path)
	  s hdrinfo=$p(Status,",",2,$l(Status))
	  s jrnend=$p(hdrinfo,",",$$$JrnHdrMIREND)
	  i 'jrnend s jrnend=$p(hdrinfo,",",$$$JrnHdrCURREND)
	  i 'jrnend {
	    s NextFile=$p(hdrinfo,",",$$$JrnHdrNEXTJRN)
	    i NextFile]"" {
	      s NextGUID=$p(hdrinfo,",",$$$JrnHdrNEXTGUID)
	      s Status=$$$JRNHDRALL(NextFile)
	      i Status>0,NextGUID'="",$p(Status,",",$$$JrnHdrTHISGUID+1)=NextGUID {
	        s jrnend=$p(Status,",",$$$JrnHdrPREVEND+1)
	      }
	    }
	  }
	  q ..CheckIntegrityOne(path,Detail,jrnend,.SrcDirs,quietly)
	}
	// Verify all journal files are valid and get their header info if not supplied
	s guid=0,num="",Status=1 for  {
	  s num=$o(jrnlist(num),1,path) q:num=""
	  i path="" s Status="",jrnlist=num q  ;should not happen
	  i $g(jrnlist(num,"info"))="" {
	    s Status=$$$JRNHDRALL(path) i Status'>0 q
	    s jrnlist(num,"info")=$p(Status,",",2,$l(Status))
	    s prevguid=$p(Status,",",1+$$$JrnHdrPREVGUID)
	    i guid'=0,prevguid'="",prevguid'=guid s Status="",jrnlist=num q
	    s guid=$p(Status,",",1+$$$JrnHdrTHISGUID)
	  }
	}
	i Status="" q 0  ;Invalid Parameter Error??
	i 'Status q $$$ERROR($$$JournalFileNotExist,path)
	i Status<0 q $$$ERROR($$$JournalFileInvalid,path)
	// Check integrity of a chain of journal files
	s num="",Status=1 for  {
	  s num=$o(jrnlist(num),1,path) q:num=""
	  i path="" s Status="" q  ;should not happen
	  s jrnend=$p(jrnlist(num,"info"),",",$$$JrnHdrCURREND)
	  i 'jrnend {
	    s nextnum=$o(jrnlist(num),1,nextfile)
	    i nextnum]"" s jrnend=$p(jrnlist(nextnum,"info"),",",$$$JrnHdrPREVEND)
	  }
	  i 'quietly w !,"Checking ",path," up to ",$s(jrnend:jrnend,1:"end of journal")
	  s Status=..CheckIntegrityOne(path,Detail,jrnend,.SrcDirs,quietly)
	  i 'Status q
	}
	q Status
}

/// Purpose: Check integrity of a journal file <br>
ClassMethod CheckIntegrityOne(path As %String, scan As %Integer = 0, jrnend As %Integer, ByRef jrnsrcdir As %String, quietly As %Integer) As %Status [ Internal ]
{
	s verbose='$g(quietly)
	s dev=$$$JRNOPEN(path,0) i dev<0 {
	  i verbose w !,"ERROR: Unable to open ",path,! 
	  q $$$ERROR($$$JournalFileOpenForRecordFailed,path)
	}
	i $$$JRNUSE(dev)
	  #; Collect a list of databases in journal directory block if requested
	  							#;HYY2028+
	i $g(jrnsrcdir) {
	  							#;HYY2044+
	  i $$$IsMirrorJournalFile(path) {
	    f sfn=0:1:($$$SFNUNDEF-1) {
	      s dir=$$$JRNDIRLOOKUP(sfn) 
	      i dir="" continue
	    							#;HYY2040+
	      i $$$IsMirrorDBName(dir) { ;dir is mirror db name
	        s jrnsrcdir(dir)="" ;dir is mirror db name
	      } else { ;dir is physical path
	        #; don't save dir yet as it could be the local path for the
	        #; mirror db on a backup member, in which case it is not in
	        #; the journal header, unless it happens to be the path of
	        #; another db on the primary, which leads to ambiguity.
	        s mdn=$$$JRNMDNLOOKUP(sfn) ;mirror db name if any
	        i mdn="" { ;not a mirrored db
	          s jrnsrcdir(dir)="" ;dir is physical path of source db
	    							#;HYY2040-
		  continue
		}
		#;for a mirror journal file, a non-null mdn must be a mirror 
		#;db name. This is not true for a non-mirror journal file.
		s jrnsrcdir(mdn)="" ;store its mirror db name
	      }
	      s dir=$$$JRNRAWDIRLOOKUP(sfn) ;sfn^path
	      #;In the scenario where sfn sequence in the journal is not
	      #;continuous (for reason other than the presence of mirror 
	      #;db names), $$$JRNRAWDIRLOOKUP(i) may return an sfn > i, 
	      #;as i is actually the slot # in journal directory block.
	      s i=sfn f  {
	        q:dir<=sfn
	        s i=i-1 q:i<0
	        s dir=$$$JRNRAWDIRLOOKUP(i) ;sfn^path
	      }
	      i dir-sfn { ;+dir'=sfn: not supposed to happen
	        d $zu(9,"","CheckIntegrityOne: no sfn "_sfn_" in "_path)
	        continue
	      }
	      s dir=$p(dir,"^",2,$l(dir))
	      s jrnsrcdir(dir)="" ;dir is physical path on the primary
	    }
	  } else { ;not a mirror journal file
	    f sfn=0:1:($$$SFNUNDEF-1) {
	      s dir=$$$JRNDIRLOOKUP(sfn) 
	      i dir'="" s jrnsrcdir(dir)=""
	    }
	  }
	  							#;HYY2044-
	}
	  							#;HYY2028-
	i 'jrnend,'scan d $$$JRNCLOSE(dev) q 1 ;nothing to check further
	s lastbck=$$$JRNPREV(0)
	  #; First, verify the last journal record reachable backward matches what
	  #; we get from (current or previous) journal header, if any
	i jrnend,jrnend>lastbck {
	  i $$$JRNCLOSE(dev)
	  i verbose {
	    w !!,"ERROR: Inconsistency in ",path," --"
	    w !,"Offset ",jrnend," is end of journal according to journal header,"
	    w !,"but the last reachable journal record ends @ offset ",lastbck,!
	  }
	  q $$$ERROR($$$JournalFileCorruption,path,lastbck,jrnend)
	}
	  #; Then, if requested, scan journal forward to locate the last record
	  #; and verify it matches the offset we got above.
	i 'scan d $$$JRNCLOSE(dev) q 1
	i scan=1 {
	  s lastfor=0 f  s addr=$$$JRNNEXT(lastfor) q:addr'>0  s lastfor=addr
	} else { ;scan>1
	  try {
	    s (addr,lastfor)=0 f  {
	      s lastfor=addr
	      s addr=$$$JRNNEXT(lastfor) q:addr'>0  
	      s type=$$$JRNTYPE(addr)
	      i type=$$$JRNBITSET {
	        s bitpos=$$$JRNBITPOS(addr)
	        s newval=$$$JRNNEWBITVAL(addr)
	        s oldval=$$$JRNOLDBITVAL(addr)
			continue
	      }
	      s numdata=$$$JRNNUMDATA(addr) 
	      #; records like TSTART has numdata < 0
	      i numdata<=0 continue
	      i numdata=2 {
	        s newval=$$$JRNNEWVAL(addr)
	        s oldval=$$$JRNOLDVAL(addr)
			continue
	      } 
	      #;JO3199+
	      i type=$$$JRNVECSET||(type=$$$JRNVECKILL) {
		      s vecindex=$$$JRNVECINDEX(addr)
		      s vectype=$$$JRNVECTYPE(addr)
	      }
	      #;JO3199-
	      i type-$$$JRNSET,type-$$$JRNNSET,type-$$$JRNMIRSET,type-$$$JRNVECSET s oldval=$$$JRNOLDVAL(addr)
	      e  s newval=$$$JRNNEWVAL(addr)
	    }
	  } catch {
	    i verbose {
	      w !,"ERROR: ",$ze
	      w !,"  from record at offset ",$g(addr),", ",path,!
	    }
	  }
	}
	s lastbck=$$$JRNPREV(lastbck) ;start offset of the last record from backward
	i $$$JRNCLOSE(dev)
	  #; With a growing file, lastfor>lastbck is possible.
	i lastfor>=lastbck q 1 ;OK
	i verbose {
	  w !,"ERROR: Inconsistency in ",path," --"
	  w !,"The last journal record reached by scanning forward, @ offset ",lastfor
	  w !,"is different from the last record in the file, @ offset ",lastbck,!
	}
	q $$$ERROR($$$JournalFileCorruption,path,lastfor,lastbck)
}

/// 	Locate journal files given in JrnFileList in the directories given in LocDirList
/// 
ClassMethod Locate(ByRef LocatedFiles As %String, ByRef JrnFileList As %String, LocDirList As %String) As %Status [ Internal ]
{
	i '$isobject(LocDirList) {
	  s locDirList(0)=$g(LocDirList)
	} elseif LocDirList.%IsA("%Collection.ListOfDT") {
	  s key="" f  s val=LocDirList.GetNext(.key) q:key=""  s locDirList(key)=val
	} else {
	  q 0 ;unsupported data type of LocDirList
	}
	s Status=1,num=0,i="" f  {
	  s i=$o(JrnFileList(i),1,jrnf) q:i=""
	  s fname=..ExtractFileName(jrnf) ;jrnf may have come from a different OS
	  s j="" f  {
	    s j=$o(locDirList(j),1,locdir) q:j=""
	    s fpath=$zu(12,locdir)_fname
	    s status=$$$JRNCHECK(fpath)
	    i status>0 {
	      s LocatedFiles(i)=$zu(12,fpath,0)
	      q  ;found the file
	    }
	    #; i status<0  ?? the case of bad journal file
	  }
	  i $g(LocatedFiles(i))="" {
		#;JO3154: Status=0 means doesn't exist so add ' to following test
	    i 'Status s Status=$$$ERROR($$$JournalFileNotExist,fname)
	    e  s Status=$System.Status.AppendStatus(Status,$$$ERROR($$$JournalFileNotExist,fname))
	  }
	}
	q Status
}

/// 	Returns OK and a list of local journal files (as SelectedFiles) 
/// 	between FirstFile and LastFile (inclusive). Error if either FirstFile 
/// 	or LastFile is not found. <br>
/// 	FirstFile (and LastFile) can be a full path, a file name (yyyymmdd.nnn)
/// 	with or without a prefix or a GUID representing the file.<br>
/// 	If FirstFile="" or not specified, it defaults to the first file in journal log.<br>
/// 	If LastFile="" or not specified, it defaults to the last file in journal log.
/// 
ClassMethod SelectRange(ByRef SelectedFiles As %String, FirstFile As %String = "", LastFile As %String = "", JrnLogPath As %String = "") As %Status [ Internal ]
{
	i $g(JrnLogPath)="" s JrnLogPath=$zu(12)_"journal.log"
	s Status=##class(%SYS.Journal.History).LoadLog(JrnLogPath,.JrnFileInfo)
	i 'Status q Status
	i FirstFile="" {	// get the first file in the log
	  s i=$o(JrnFileInfo(""),1,jrninfo) i i="" q $$$OK ;empty log
	  s path=$p(jrninfo,",",2),GUID=$p(jrninfo,",",4)
	} else {
	  s i="",path="",GUID="" f  {	// looking for FirstFile
	    s i=$o(JrnFileInfo(i),1,jrninfo) q:i=""
	    s path=$p(jrninfo,",",2),GUID=$p(jrninfo,",",4)
	    i ..Match(FirstFile,path,GUID) q
	    k JrnFileInfo(i)
	  }
	}
	i i="" q $$$ERROR($$$JournalFileNotInLog,FirstFile,JrnLogPath) ;FirstFile NOT found in journal log
	s SelectedFiles(i)=path
	i LastFile="" {	// get files up to the last one in the log
	  f  {
	    s i=$o(JrnFileInfo(i),1,jrninfo) q:i=""
	    s path=$p(jrninfo,",",2)
	    s SelectedFiles(i)=path
	  }
	  q $$$OK
	}
	i '..Match(LastFile,path,GUID) {// if FirstFile is not also LastFile
	  f  {	// looking for LastFile
	    s i=$o(JrnFileInfo(i),1,jrninfo) q:i=""
	    s path=$p(jrninfo,",",2),GUID=$p(jrninfo,",",4)
	    s SelectedFiles(i)=path
	    #; @TODO@ i ..Match(FirstFile,path,GUID) q  ;ambiguous FirstFile
	    i ..Match(LastFile,path,GUID) q
	  }
	  i i="" q $$$ERROR($$$JournalFileNotInLog,LastFile,JrnLogPath) ;LastFile NOT found
	}
	/*
	f  {	// check ambiguity of FirstFile and LastFile
	  s i=$o(JrnFileInfo(i),1,jrninfo) q:i=""
	  s path=$p(jrninfo,",",2),GUID=$p(jrninfo,",",4)
	  i ..Match(FirstFile,path,GUID) q  // FirstFile is ambiguous!!
	  i ..Match(LastFile,path,GUID) q  // LastFile is ambiguous!!
	}
	i i]"" q 0 ;ambiguous
	*/
	q $$$OK
}

/// File can be a full path, a file name (yyyymmdd.nnn) or a GUID representing the file.<br>
/// Path is a full path in canonical form on the original platform.<br>
/// 	Returns <ul><li> 
/// 			0: no match; </li><li>
/// 			1: File matches the full path; </li><li>
/// 			2: File matches the file name (including prefix); </li><li>
/// 			3: File matches the file name without prefix; </li><li>
/// 			4: File matches GUID.</li></ul>
/// 
ClassMethod Match(File As %String, Path As %String, GUID As %String) As %Status [ Internal ]
{
	i $zcvt(File,"U")=$zcvt(GUID,"U") q 4 ;matching GUID
	i $p(Path,"]",2)]"" {	;Path is a VMS file path
	  s File=$zcvt(File,"U")
	  s Path=$zcvt(Path,"U")
	  s FileName=$p($p(Path,"]",2),";")
	} elseif $f(Path,"/") {	;Path is a Unix file path
	  s FileName=$p(Path,"/",$l(Path,"/"))
	} else {	;Path is a Windows file path
	  s File=$zcvt(File,"U")
	  s Path=$zcvt(Path,"U")
	  s FileName=$p(Path,"\",$l(Path,"\"))
	}
	i File=$$$JRNSHORTNAME(FileName) q 3 ;matching file name w/o prefix
	i File=FileName q 2 ;matching file name including prefix
	i File=Path q 1 ;matchin full path
	q 0 ;no match
}

/// 	Given the full path of a journal file, extract its file name portion
/// 
ClassMethod ExtractFileName(Path As %SysPath) As %String [ Internal ]
{
	i $p(Path,"]",2)]"" q $p($p(Path,"]",2),";") ;VMS file path
	e  i $f(Path,"/") q $p(Path,"/",$l(Path,"/")) ;Unix file path
	e  q $p(Path,"\",$l(Path,"\")) ;Windows file path
}

/// Purpose: (virtually) restore the journal
ClassMethod Restore(FileName As %String, Detail As %Integer = 0) As %Status
{
	s $zt="Error"
	s jrnf=..%OpenId(FileName) i jrnf=$$$NULLOREF q $$$ERROR($$$JournalFileOpenIdFailed,FileName)
	s lastrec=jrnf.LastRecord i lastrec=$$$NULLOREF q $$$OK
	s jrec=jrnf.FirstRecord i jrec=$$$NULLOREF q $$$ERROR($$$JournalFileFirstRecordInvalid)
	i 'Detail d  q '(jrec.Address<lastrec.Address)
	. f  s next=jrec.Next q:next=""  k jrec s jrec=next
	s rc=$$$OK f  s next=jrec.Next q:next=""  k jrec s jrec=next s rc=jrec.Restore(Detail-1) q:rc'=$$$OK
	i rc'=$$$OK q rc
	q '(jrec.Address<lastrec.Address)
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Purpose: Regenerate the jobid->PID translation table based on records stored
/// in the specified journal file
ClassMethod RestorePIDList(FileName As %String) As %Status
{
	s $zt="Error"
	s jrnf=..%OpenId(FileName) i jrnf=$$$NULLOREF q $$$ERROR($$$JournalFileOpenIdFailed,FileName)
	s lastaddr=$$$JRNPREV(0) i lastaddr'>0 q $$$OK  ;journal file is empty
	; Get the 1st address in the journal file
	s addr=$$$JRNNEXT(0) i addr'>0 q $$$OK
	s mgdir=$$$JRNDIRLOOKUP(0)  ; mgr dir in this journal file (sfn #0)
	s srchref="^[""^^"_mgdir_"""]SYS(""PIDList"","  ;this is our pidlist
	s srchreflen=$L(srchref)
	; Do this in a transaction so we leave a journal record of
	; what took place. Restoring the pidlist from another system's
	; journal can alter entries which belong to this computer.
	TSTART
	while ((addr > 0) && (addr < lastaddr)) {
		s exttype=$$$JRNTYPE1(addr),remote=$$$JRNREMSYS(addr)
		s type=$$$JRNExtTypeToType(exttype)
		if (('remote) && (type = $$$JRNSET)) {
		   s ref=$$$JRNNODE(addr)
		   if $E(ref,1,srchreflen)=srchref {
			   s value=$$$JRNNEWVAL(addr)
			   i exttype=$$$JRNINCRIGTYP,@ref>=value continue  ;set to greater value only
			   s @ref=value
		   }
		}
		s addr=$$$JRNNEXT(addr)
	}
	TCOMMIT
	quit $$$OK
Error s $zt=""
	TROLLBACK:$TLEVEL
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Return the path of the oldest journal file on each node that is required 
/// for cluster recovery, which includes rolling forward and back transactions.<br>
/// FileName = # of nodes where journal recovery is required <br>
/// FileName(csn) = the path of the oldest journal file on node <#csn> <br>
/// If SkipSelf = 1, skip the node where the method is called (local node is covered by RequiredForRecovery()
ClassMethod RequiredForClusterRecovery(ByRef FileName As %String, ByRef FileCount As %Integer, SkipSelf As %Boolean = 0) As %Status
{
	s $zt="Error"
	s rs=##class(%ResultSet).%New("%SYS.ClusterInfo:NodeList")
	s rc=rs.Execute(SkipSelf) i $$$ISERR(rc) q rc
	s FileName=0
	f  {
		i 'rs.Next() q
		s csn=rs.Data("CSN")
#;JO2192+
		i rs.Data("Prev Journal File Count")<rs.Data("Transaction File Count") {
			s FileName(csn)=rs.Data("Prev Journal File")
			s FileCount(csn)=rs.Data("Prev Journal File Count")
#;JO2192-
		} else {	// Prev Journal File Count >= Transaction File Count
			s FileName(csn)=rs.Data("Transaction File")
			s FileCount(csn)=rs.Data("Transaction File Count")
		}
		i $i(FileName)
	}
	q $$$OK
Error	q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Return the name of the oldest journal file required for crash recovery, which
/// includes rolling forward and backward transactions. <br>
/// FileName="" if journaling is disabled, meaning that none is required, as
/// transactions cannot be rolled forward or backward from a pre-disabling file
ClassMethod RequiredForRecovery(ByRef FileName As %String, ByRef FileCount As %Integer) As %Status
{
	#;i ##class(SYS.Cluster).IsMember() s Status=..RequiredForClusterRecovery(.FileName,.FileCount) i $$$ISERR(Status) q Status
	s wijjrninfo=$$$JRNINDEX
#;JO2192+	
	s FileName=$p(wijjrninfo,",",$$$JIJRNFILENAME)
	s jrnfilecnt=$p(wijjrninfo,",",$$$JIJRNFILECNT)
	i FileName="" q $$$OK ;journaling is disabled
	s FileCount=$$$TRANSFILECNTONDISK
#;JO2192-	
	s filecnt=jrnfilecnt f  q:filecnt'>FileCount  s stat=..GetPrev(FileName,.PrevName,1) q:$$$ISERR(stat)  q:PrevName=""  s FileName=PrevName,filecnt=filecnt-1
	q $g(stat,$$$OK)
}

/// Return the path of the oldest journal file containing open transactions. <br>
/// FileName: the oldest file containing open transactions or current journal file
/// <br>FileCount: the file counter value assigned to the file
ClassMethod RequiredForRollback(ByRef FileName As %String, ByRef FileCount As %Integer) As %Status
{
	s FileCount($$$JRNCURFILECNT)="" ;current file is required for rollback
	s ecpjrnindex=$System.ECP.GetProperty("ECPJrnIndex")
	i ecpjrnindex s FileCount($p(ecpjrnindex,",",2))=""
	if $$$USEU2 {
		For i=1:1:($$$STmaxpid-1) s jobtype=$zu(61,10,i) i $$$INTERACTIVEJOB(jobtype)!$$$BACKGROUNDJOB(jobtype),$zu(61,19,i)!$ZU(61,29,i) s FileCount($zu(61,18,i))=""
	} else {
		For i=1:1:($$$STmaxpid-1) s jobtype=$zu(61,10,i) i $$$INTERACTIVEJOB(jobtype)!$$$BACKGROUNDJOB(jobtype),$zu(61,19,i) s FileCount($zu(61,18,i))=""
	}
	#; get the earliest file count containing open transaction and the offset of an open transaction in the file
	s filecnt=$o(FileCount("")) ;earliest file count containing open transactions
	i ##class(%SYS.Journal.System).IsDisabled() q $$$OK ;journaling is disabled; cannot roll back open transaction
	#; find the matching current file name and count
	f  s FileName=$$$JRNCURNAM,FileCount=$$$JRNCURFILECNT q:FileName=$$$JRNCURNAM
	#; find the file name corresponding to the earliest file count containing open transactions
	f  q:FileCount'>filecnt  s stat=..GetPrev(FileName,.PrevName,1) q:$$$ISERR(stat)  q:PrevName=""  s FileName=PrevName,FileCount=FileCount-1
	q $g(stat,$$$OK)
}

/// Return the path of the last encrypted file no older than OldestFile if given
ClassMethod LastEncrypted(OldestFile As %String = "", csn As %Integer = -1) As %String
{
	i csn'<0 {
		s rs=##class(%ResultSet).%New("%SYS.Journal.File:ClusterList")
		#; list files of cluster node <csn> from the latest backwards
		s rc=rs.Execute("",0,csn) i $$$ISERR(rc) q rc 
		s CurrentFile=""
		f  {
			i 'rs.Next() q
			s CurrentFile=rs.Data("Name")
			i $$$JRNENCKEYIDLEN(CurrentFile) q
			i CurrentFile=OldestFile s CurrentFile="" q
		}
		q CurrentFile
	}
	s CurrentFile=$$$JRNCURNAM
	for {
		i CurrentFile="" q
		i $$$JRNENCKEYIDLEN(CurrentFile) q
		i CurrentFile=OldestFile s CurrentFile="" q
		s CurrentFile=$$$JRNFPREV(CurrentFile)
	}
	q CurrentFile
}

/// Purpose: Purge old journal files based on criteria given in number of days or backups, taking care not to purge files required for transaction rollbacks or crash recovery.<p>
/// Parameters:<ul><li>
/// NDaysOld: journal files must be at least this # of days old to be purged</li><li>
/// NBackupsOld: journal files must be older than this # of successive successful backups to be purged</li></ul>
/// If both parameters are specified, only one criterion has to be met to qualify a journal file for purging (subject to the restriction about rollback and crash recovery).<br>
/// Note: It is the completion date, rather than the creation date, of a file that must meet the date criterion if specified. Thus, a file may not be OK to purge even though the date in its name appears to meet the date criterion.
ClassMethod Purge(NDaysOld As %Integer, NBackupsOld As %Integer) As %Status
{
								#;HYY2288+
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while Purge^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","PURGE").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
								#;HYY2325-
	s $zt="Error"
	d Purge^JRNUTIL($g(NDaysOld)_","_$g(NBackupsOld))
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Purge <em>all</em> journal files except those required for transaction rollbacks or crash recovery.<br>Warning: Post-backup journal files are not necessarily preserved.
ClassMethod PurgeAll() As %Status
{
								#;HYY2288+
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while Purge^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","PURGE").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
								#;HYY2325-
	s $zt="Error"
	d Purge^JRNUTIL(-1)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Purpose: Purge the journal file with the given name <p>
/// Warning: This method does NOT check for open transactions before deleting the journal file.<p> 
/// FilePath: the full path of the journal file to purge <br>
/// PurgeTimeH: Time of purging in $H format <br>
/// LogOnly: if 1, skip purging and log the purged file only. Default = 0
ClassMethod PurgeOne(FilePath As %String, PurgeTimeH As %String, LogOnly As %Integer = 0) As %Status
{
								#;HYY2288+
								#;HYY2325+
	s $zt="Error"
	i LogOnly s ^%SYS("JOURNAL","PURGED",FilePath)=$zdt($g(PurgeTimeH,$h),3) q $$$OK
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while DELFILE^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","PURGED").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
								#;HYY2325-
	s rc=$$DELFILE^JRNUTIL(FilePath,$g(PurgeTimeH,$h))
	i rc<=0 q $$$ERROR($$$JournalFileDeleteError,FilePath,rc)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Purpose: Archive old journal files based on criteria given in number of seconds or backups, taking care not to archive files required for transaction rollbacks or crash recovery.<p>
/// Parameters:<ul><li>
/// NSecondsOld: journal files must be at least this # of seconds old to be archived</li><li>
/// NBackupsOld: journal files must be older than this # of successive successful backups to be archived</li></ul>
/// If both parameters are specified, only one criterion has to be met to qualify a journal file for archiving (subject to the restriction about rollback and crash recovery).<br>
/// Note: It is the completion time, rather than the creation time, of a file that must meet the time criterion if specified. Thus, a file may not be OK to archive even though its timestamp appears to meet the time criterion.
ClassMethod Archive(NSecondsOld As %Integer, NBackupsOld As %Integer) As %Status
{
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while Archive^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","ARCHIVE").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
	s $zt="Error"
	d Archive^JRNUTIL($g(NSecondsOld)_","_$g(NBackupsOld))
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
}

/// Archive <em>all</em> journal files except those required for transaction rollbacks or crash recovery.<br>Warning: Post-backup journal files are not necessarily preserved.
ClassMethod ArchiveAll() As %Status
{
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while Archive^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","ARCHIVE").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
	s $zt="Error"
	d Archive^JRNUTIL(-1)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
}

/// Purpose: Archive the journal file with the given name <p>
/// Warning: This method does NOT check for open transactions before deleting the journal file.<p> 
/// FilePath: the full path of the journal file to archive <br>
/// ArchiveTimeH: Time of archiving in $H format <br>
/// LogOnly: if 1, skip archiving and log the archived file only. Default = 0
ClassMethod ArchiveOne(FilePath As %String) As %Status
{
	s $zt="Error"
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	i $NAMESPACE'="%SYS" {
		; Cannot continue as no read access to %SYS => no write access,
		; while ArchiveFile^JRNUTIL requires write access to %SYS
		; to set ^%SYS("JOURNAL","ARCHIVED").
		d GetNSInfo^%SYS.NAMESPACE("%SYS",.Info)
		q $$$ERROR($$$UserInsufficentPrivForNameSpace,"%SYS",$g(Info("Directory")),$g(Info("Resource")))
	}
	s rc=$$ArchiveFile^JRNUTIL(FilePath)
	i rc<=0 q $$$ERROR($$$JournalFileArchiveError,FilePath,rc)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
}

/// Translate the numeric reason for the creation of a new journal file to string form
ClassMethod TranslateReason(reason As %Integer = 0) As %String
{
	s reason=+reason
    q:reason=$$$JRNSWREASONUNSPECIFIED $$$Text("unspecified")
    q:reason=$$$JRNSWREASONUSER $$$Text("by user")
    q:reason=$$$JRNSWREASONFILESIZELMT $$$Text("file size limit reached")
    q:reason=$$$JRNSWREASONIORETRY $$$Text("to retry failed I/O")
    q:reason=$$$JRNSWREASONBACKUP $$$Text("by backup")
    q:reason=$$$JRNSWREASONRESTORE $$$Text("by restore")
    q:reason=$$$JRNSWREASONTASKMGR $$$Text("by task manager")
    q:reason=$$$JRNSWREASONACTIVATE $$$Text("to activate journal changes")
    q:reason=$$$JRNSWREASONREENABLEJRN $$$Text("to reenable journaling")
 #;JO2141+
    q:reason=$$$JRNSWREASONPRIMARYMIRRORStart $$$Text("by mirror startup")
    q:reason=$$$JRNSWREASONPRIMARYMIRRORStop $$$Text("by mirror shutdown")
	q:reason=$$$JRNSWREASONMirrorDBRemoved $$$Text("mirror database removed")
 #;JO2141-
    q:reason=$$$JRNSWREASONSTARTUP $$$Text("<STARTUP>")
	    							#;HYY2255+
    q:reason=$$$JRNSWREASONExpandDirTable $$$Text("to expand directory table")
	    							#;HYY2255-
    q $$$Text("UNKNOWN: ")_reason
}

/// Return the reason for the creation of the given journal file (<parameter>File</parameter>) in string form
ClassMethod GetReason(File As %SysPath) As %String [ CodeMode = expression ]
{
..TranslateReason($$$JRNSWREASON(File))
}

/// <br>FileCount: the file counter value assigned to the file
ClassMethod Summary(FilePath As %String, ByRef DataFields As %String) As %Status
{
 s info=$$$JRNHDRALL(FilePath) i info'>0 q $$$ERROR($$$JournalFileInvalid,FilePath)
 #;&FileGUID:%String,&MaxSize:%Integer,&CreationTime:%TimeStamp,&EncryptionKeyID:%String="",&FileCount:%Integer,&MinTransFileCount:%Integer,&MinTransFileIndex:%Integer,&MirrorFileCount:%Integer=0,&MirrorMinTransFileCount:%Integer,&MirrorMinTransFileIndex:%Integer,&MirrorFileEnd:%Integer,&MirrorGUID:%String,&SystemGUID:%String,&SessionGUID:%String,&PrevFile:%SysPath="",&PrevFileGUID:%String,&PrevFileEnd:%Integer,&NextFile:%SysPath="",&NextFileGUID:%String
 s info=$p(info,",",2,*) ;skip the status field
 s DataFields("FileGUID")=$p(info,",",$$$JrnHdrTHISGUID)
 s DataFields("MaxSize")=$p(info,",",$$$JrnHdrMAXSIZ)
 s time0=$p(info,",",$$$JrnHdrTIMECREATED)
 s DataFields("CreationTime")=$zdt($zdth(time0,-2),3)
 i $p(info,",",$$$JrnHdrENCKEYIDLEN) {
   s DataFields("EncryptionKeyID")=$p(info,",",$$$JrnHdrENCKEYID)
 }
 #; jrncnt ($$$JrnHdrJRNCNT) is for internal use only
 s DataFields("FileCount")=$p(info,",",$$$JrnHdrFILECNT)
 s DataFields("MinTransFileCount")=$p(info,",",$$$JrnHdrMINTRANSFILECNT)
 s DataFields("MinTransFileIndex")=$p(info,",",$$$JrnHdrMINTRANSINDEX)
 s fcnt=$p(info,",",$$$JrnHdrMIRFILECNT)
 i fcnt {	; a mirror journal file
   s DataFields("MirrorFileCount")=fcnt
   s DataFields("MirrorMinTransFileCount")=$p(info,",",$$$JrnHdrMINMIRTRANSFILECNT)
   s DataFields("MirrorMinTransFileIndex")=$p(info,",",$$$JrnHdrMINMIRTRANSINDEX)
   s DataFields("MirrorFileEnd")=$p(info,",",$$$JrnHdrMIREND)
   s DataFields("MirrorGUID")=$p(info,",",$$$JrnHdrMIRGUID)
   s DataFields("SystemGUID")=$p(info,",",$$$JrnHdrSYSGUID)
   s DataFields("SessionGUID")=$p(info,",",$$$JrnHdrSESSGUID)
 }
 s file=$p(info,",",$$$JrnHdrPREVJRN)
 i file'="" {
   s DataFields("PrevFile")=file
   s DataFields("PrevFileGUID")=$p(info,",",$$$JrnHdrPREVGUID)
   s DataFields("PrevFileEnd")=$p(info,",",$$$JrnHdrPREVEND)
 }
 s file=$p(info,",",$$$JrnHdrNEXTJRN)
 i file'="" {
   s DataFields("NextFile")=file
   s DataFields("NextFileGUID")=$p(info,",",$$$JrnHdrNEXTGUID)
 }
 q $$$OK
}

/// Returns sfn's and paths/names of databases in a journal file
Query DatabaseList(FilePath As %String) As %Query(ROWSPEC = "sfn:%Integer, Database Path or Alias:%String") [ SqlProc ]
{
}

ClassMethod DatabaseListExecute(ByRef qHandle As %Binary, FilePath As %String) As %Status [ Internal ]
{
 s dev=$$$JRNOPEN(FilePath,0)
 i dev<0 q $$$ERROR($$$JournalFileInvalid,FilePath)
 s index=$i($$$ISCQUERYTEMP)
 s $$$ISCQUERYTEMP(index)="%SYS.Journal.File:DatabaseList,"_$j
 s qHandle=$name($$$ISCQUERYTEMP(index,""))
 s ismirjrn=$$$IsMirrorJournalFile(FilePath)
 try {
   i $$$JRNUSE(dev)
   f sfn=0:1:$$$SFNUNDEF-1 {
     s target=$$$JRNDIRLOOKUP(sfn)
     #; if jf is current journal file, a mirrored db is associated with two
     #; entries: one is its physical path, followed by an entry that begins 
     #; with <0><ff>:mirror:. Skip the second entry to be consistent with the
     #; display if jf is a non-current journal file.
     i (target="")||($a(target)=0) continue 
     i ismirjrn {
       s mdn=$$$JRNMDNLOOKUP(sfn)
       i mdn="" s $$$ISCQUERYTEMP(index,sfn)=target
       e  s $$$ISCQUERYTEMP(index,sfn)=mdn
     } else {
       s $$$ISCQUERYTEMP(index,sfn)=target
     }
   }
   i $$$JRNCLOSE(dev)
 } catch {
   i $$$JRNCLOSE(dev)
   q
 }
 q $$$OK
}

ClassMethod DatabaseListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
        s sfn=$o(@qHandle) i sfn="" s Row="",AtEnd=1 q $$$OK
	s index=$qs(qHandle,1)
        s qHandle=$name($$$ISCQUERYTEMP(index,sfn))
        s $li(Row,1)=sfn
        s $li(Row,2)=$$$ISCQUERYTEMP(index,sfn)
	q $$$OK
}

ClassMethod DatabaseListClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
        s index=$qs(qHandle,1)
        k $$$ISCQUERYTEMP(index)
	q $$$OK
}

/// Returns journal file names and file sizes in the reverse order of time (i.e., latest file first)<br>
/// The file size is the actual size on disk which for compressed files should be smaller than the amount of journal data in the file.
Query ByTimeReverseOrder(FileName As %String) As %Query(ROWSPEC = "Name:%String, Size:%Integer, Creation Time: %TimeStamp, Reason: %String, Data Size: %Integer") [ SqlProc ]
{
}

ClassMethod ByTimeReverseOrderExecute(ByRef qHandle As %Binary, FileName As %String = "") As %Status [ Internal ]
{
	i $g(FileName)="" s qHandle=FileName q $$$OK
	s status=..IsValidJournal(FileName) q:$$$ISERR(status) status  
	s qHandle=FileName
	q $$$OK
}

ClassMethod ByTimeReverseOrderFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s Name=qHandle
	i Name="" {
		s PrevName=$$$JRNCURNAM 
		i PrevName="" s PrevName=##class(%SYS.Journal.System).GetLastFileName() 
		i PrevName="" s Row="",AtEnd=1 q $$$OK
	} else {
		s rc=..GetPrev(Name,.PrevName) q:$$$ISERR(rc) rc 
		i PrevName="" s Row="",AtEnd=1 q $$$OK
	}
	s FileSize=$$$GetJrnFileSize(PrevName) 
	i (FileSize<0)||($$$JRNCHECK(PrevName)'=$$$OK) s Row="",AtEnd=1 q $$$OK
	#;JO3154: Add DataSize field
	s DataSize=$$$GetJrnDataSize(PrevName)
	s $li(Row,1)=PrevName
	i $zu(115,5)=2 {	// DISPLAY mode
		s $li(Row,2)=$$TranslateSize^SHDWSTAT(FileSize)
		s $li(Row,5)=$$TranslateSize^SHDWSTAT(DataSize)
	} else {
		s $li(Row,2)=FileSize
		s $li(Row,5)=DataSize
	}
	s $li(Row,3)=$zdt($zdth($p($zu(78,22,PrevName,4),",",2),-2),3)
	s $li(Row,4)=..GetReason(PrevName)
	s qHandle=PrevName
	q $$$OK
}

ClassMethod ByTimeReverseOrderClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Returns journal file names and file sizes in the reverse order of time (i.e., latest file first) for the specified mirror <br>
/// The file size is the actual size on disk which for compressed files should be smaller than the amount of journal data in the file.
Query MirrorByTimeReverseOrder(FileName As %String, MirrorSetName As %String) As %Query(ROWSPEC = "Name:%String, Size:%Integer, Creation Time: %TimeStamp, Reason: %String, Data Size: %Integer") [ SqlProc ]
{
}

ClassMethod MirrorByTimeReverseOrderExecute(ByRef qHandle As %Binary, FileName As %String = "", MirrorSetName As %String = "") As %Status [ Internal ]
{
	i $g(FileName)'="" {
		s status=..IsValidJournal(FileName) 
		i $$$ISERR(status) q status  
	}
	i '$SYSTEM.Mirror.IsMember() q $$$ERROR($$$NotMirrorMember,$p($zu(86),"*",*))
	NEW $NAMESPACE
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
 	i MirrorSetName="" s MirrorSetName=##class(Config.Mirrors).GetMirrorName()
 	s jrnlogfile=$zu(12)_"mirrorjrn-"_MirrorSetName_".log"
 	s miridx=$SYSTEM.Mirror.MirrorNameToIndex(MirrorSetName,0)
 	i miridx<0 s miridx=0
 	s miridx=miridx+1
	i $$$MIRJRNLOGRDSHRSET(miridx)
	s $zt="LogLocked",$ze=""
	$$$JrnLogOpenForRead(jrnlogfile):0 i '$t {
		i $$$MIRJRNLOGRDSHRCLR(miridx)
		q $$$ERROR($$$FileCanNotOpen,jrnlogfile)
	}
	s status=##class(%SYS.Journal.History).GetHeader(jrnlogfile,,miridx) ;skip header
	i 'status {
		c jrnlogfile 
		d $$$MIRJRNLOGRDSHRCLR(miridx)
		q status
	}
	s index=$i($$$ISCQUERYTEMP)
	s $$$ISCQUERYTEMP(index)="%SYS.Journal.File:MirrorByTimeReverseOrder,"_$j
	s qHandle=$name($$$ISCQUERYTEMP(index,""))
	s linecnt=0
	i $g(FileName)="" {
		f  {
			u jrnlogfile r logline
			i $$$IsBlankLine(logline) continue  ;skip blank lines
			s $$$ISCQUERYTEMP(index,$i(linecnt))=logline
		}
	} else {
		s FileName=$zu(12,FileName,0) ;all lower cases on Windows
		f  {
			u jrnlogfile r logline
			i $$$IsBlankLine(logline) continue  ;skip blank lines
			i $zu(12,$p(logline,","),0)=FileName q  ;got all entries before FileName
			s $$$ISCQUERYTEMP(index,$i(linecnt))=logline
		}
	}
LogLocked s $zt=""
	c jrnlogfile
	d $$$MIRJRNLOGRDSHRCLR(miridx)
	i $ze'="",$ze'["ENDOFFILE" {
		s status=$$$ERROR($$$UnexpectedError,$ze)
		s $ze=""
	}
	q status
}

ClassMethod MirrorByTimeReverseOrderFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s index=$qs(qHandle,1)
	s qHandle=$q(@qHandle,-1)
	i (qHandle="")||($qs(qHandle,1)'=index) s Row="",AtEnd=1 q $$$OK
	s Name=$p(@qHandle,",")
	s FileSize=$$$GetJrnFileSize(Name) 
	i (FileSize<0)||($$$JRNCHECK(Name)'=$$$OK) s Row="",AtEnd=1 q $$$OK
	#;JO3154: Add DataSize field
	s DataSize=$$$GetJrnDataSize(Name)
	s $li(Row,1)=Name
	i $zu(115,5)=2 {	// DISPLAY mode
		s $li(Row,2)=$$TranslateSize^SHDWSTAT(FileSize)
		s $li(Row,5)=$$TranslateSize^SHDWSTAT(DataSize)
	} else {
		s $li(Row,2)=FileSize
		s $li(Row,5)=DataSize
	}
	s $li(Row,3)=$zdt($zdth($p($zu(78,22,Name,4),",",2),-2),3)
	s $li(Row,4)=..GetReason(Name)
	q $$$OK
}

ClassMethod MirrorByTimeReverseOrderClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
        s index=$qs(qHandle,1)
        k $$$ISCQUERYTEMP(index)
	q $$$OK
}

/// 	Returns paths of journal files (along with their mirror names if any) that are eligible for purging based on the default or given criteria.<br>
/// 	DaysToKeep: How many days of journal files to keep. Use default (current system setting) if left unspecified. If 0, none is purgeable; if <0, all files are purgeable except those required for transaction rollback and crash recovery.
Query Purgeable(DaysToKeep As %Integer) As %Query(ROWSPEC = "FilePath:%String,MirrorName:%String") [ SqlProc ]
{
}

ClassMethod PurgeableExecute(ByRef qHandle As %Binary, DaysToKeep As %Integer = "") As %Status [ Internal ]
{
	s $zt="Error"
	i $g(DaysToKeep)="" {
		s flifespan=""
		if $d(^$ROUTINE("%ZJRNPURGE")) s flifespan=$$^%ZJRNPURGE()
		s:flifespan="" flifespan=$g(^%SYS("JOURNAL","LIFESPAN","FILE"))
	} else {
		s flifespan=+DaysToKeep
	}
	s purgenode=$name(^||%ISC.JRN.PURGE)
	n $namespace
	i $namespace'="%SYS" s $namespace="%SYS"
	d Purge^JRNUTIL(flifespan,1,purgenode)
	s qHandle=$name(@purgenode@(""))
	q $$$OK
Error	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

ClassMethod PurgeableFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
getnext s nextnode=$q(@qHandle)
	#; don't make qHandle="", as qHandle is needed in Close()
	i nextnode="" s Row="",AtEnd=1 q $$$OK
	s qHandle=nextnode
	i $ql(nextnode)<2 g getnext
	s $li(Row,1)=@qHandle ;FilePath
	s MirrorName=$qs(qHandle,1)
	#; a real mirror name must be in alphanumerics only
	i MirrorName'?1.NA s MirrorName=""
	s $li(Row,2)=MirrorName
	q $$$OK
}

ClassMethod PurgeableClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	i $g(qHandle)'="" {
	  s glob=$qs(qHandle,0) 
	  k @glob 
	}
	Quit $$$OK
}

/// Information on cluster journal files <br>
/// By default, files are listed in reverse order of time, unless TimeOrder = 1 <br>
/// If FileName is specified, files are listed until FileName is reached (depend on TimeOrder) <br>
/// If CSN is given, only files belong to the node are listed.
Query ClusterList(FileName As %String = "", TimeOrder As %Boolean = 0, CSN As %Integer = -1) As %Query(ROWSPEC = "Name:%String, Size:%Integer, Cluster Start Time:%TimeStamp, First Sequence: %Integer, Last Sequence: %Integer, Cluster System Number: %Integer, Reason: %String, Creation Time: %TimeStamp, Cluster Start Time UTC: %Integer") [ SqlProc ]
{
}

ClassMethod ClusterListExecute(ByRef qHandle As %Binary, FileName As %String = "", TimeOrder As %Boolean = 0, CSN As %Integer = -1) As %Status [ Internal, PublicList = (jrninfo, jrninfor) ]
{
								#;HYY2288+
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	s $zt="Error"
	s index=$$initjrninfo^|"%SYS"|JRNINFO()	i $$updjrninfo^|"%SYS"|JRNINFO()
								#;HYY2325+
	i $g(FileName)]"",$g(@jrninfo@(FileName))="" q $$$ERROR($$$JournalFileNotExist,FileName)
	s qHandle=$lb(FileName,TimeOrder,index,jrninfo,jrninfor,CSN)
	q $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

ClassMethod ClusterListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s Name=$li(qHandle,1),TimeOrder=$li(qHandle,2),jrninfo=$li(qHandle,4),jrninfor=$li(qHandle,5),CSN=$li(qHandle,6)
	i CSN'<0 {	// CSN is specified
		s cnt=$s(Name="":"",1:$p(@jrninfo@(Name),",",2))
		s cnt=$o(@jrninfor@(CSN,cnt),$s(TimeOrder:1,1:-1),Name)
		i cnt="" s Row="",AtEnd=1 q $$$OK  // none found
	} elseif Name="" {
		i TimeOrder {
			s cnt=2**32,csn="" f  s csn=$o(@jrninfor@(csn)) q:csn=""  s cnt(csn)=$o(@jrninfor@(csn,""),1,Name(csn)) i cnt(csn)<cnt s cnt=cnt(csn),Name=Name(csn)
		} else {
			s cnt=0,csn="" f  s csn=$o(@jrninfor@(csn)) q:csn=""  s cnt(csn)=$o(@jrninfor@(csn,""),-1,Name(csn)) i cnt(csn)>cnt s cnt=cnt(csn),Name=Name(csn)
		}
	} else {
		s cnt=$p(@jrninfo@(Name),",",2)+$s(TimeOrder:1,1:-1)
		s csn="" f  s csn=$o(@jrninfor@(csn)) q:csn=""  q:$g(@jrninfor@(csn,cnt))]""
		i csn="" s Row="",AtEnd=1 q $$$OK  // none found
		s Name=@jrninfor@(csn,cnt)
	}
	s info=@jrninfo@(Name),csn=+info,idx=$p(info,",",2)
	s $li(Row,1)=Name,$li(qHandle,1)=Name
	s FileSize=$$$GetJrnFileSize(Name) 
	i filesize<0 s $li(Row,2)="N/A" q $$$OK  ;file doesn't exist anymore
	s $li(Row,2)=filesize 
	s $li(Row,9)=$p(info,",",3) // cluster start time as a time(0) value (UTC)
	s $li(Row,3)=$zdt($zdth($p(info,",",3),-2),3) // cluster start time in ODBC format (local)
	s $li(Row,4)=$p(info,",",4) // first sequence 
	s $li(Row,5)=$p(info,",",5) // last sequence
	s $li(Row,6)=+info  // csn
	s $li(Row,7)=..GetReason(Name)
	s $li(Row,8)=$zdt($zdth($p($zu(78,22,Name,4),",",2),-2),3)
	q $$$OK
}

ClassMethod ClusterListClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
								#;HYY2288+
	NEW $NAMESPACE
								#;HYY2325+
	try {
		SET $NAMESPACE="%SYS"
	} catch {
		;no read access to %SYS
	}
	s $zt="Error"
	d killjrninfo^|"%SYS"|JRNINFO($li(qHandle,3))
								#;HYY2325+
	Quit $$$OK
Error s $zt="" q $$$ERROR($$$UnexpectedError,$ze)
								#;HYY2288-
}

/// Returns addresses of records in a given journal file that match a given string
Query Search(String As %String, FileName As %String, Offset As %Integer, Backward As %Boolean) As %Query(ROWSPEC = "Offset:%Integer") [ SqlProc ]
{
}

ClassMethod SearchExecute(ByRef qHandle As %Binary, String As %String, FileName As %String, Offset As %Integer, Backward As %Boolean = 0) As %Status [ Internal ]
{
	i $g(String)="" q $$$ERROR($$$JournalFileSearchUndefined)
	i $g(FileName)="" q $$$ERROR($$$JournalFileUndefined)
	s chan=$$$JRNOPEN(FileName,0) i chan<0 q $$$ERROR($$$JournalFileOpenForRecordFailed,FileName)
	i $$$JRNUSE(chan)
	i $g(Offset)="" s Offset=$s(Backward:$$$JRNPREV($$$JRNPREV(0)),1:$$$JRNNEXT(0))
	s qHandle=$lb(String,chan,Offset,Backward)
	q $$$OK
}

Storage JournalFileStorage
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%SYSTEM.FileS</StreamLocation>
<Type>%CustomStorage</Type>
}

ClassMethod SearchFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s Offset=$li(qHandle,3) i Offset'>0 s AtEnd=1,Row="" q $$$OK
	s Backward=$li(qHandle,4),str=$li(qHandle,1),func=$s(Backward:18,1:17)
	s found=0 f  d  q:found  s Offset=$zu(78,func,Offset) q:Offset'>0
	. s rec=$$thisrec^JRNDUMP(Offset,.glo,.val) d $$$LOGMSG("thisrec: "_Offset_","_glo,1,0)
	. i rec'[str,$g(glo)'[str,$g(val)'[str q
	. s found=1 d $$$LOGMSG("thisrec: found",1,0)
	i 'found s AtEnd=1,Row="" q $$$OK
	s Next=$s(Backward:$$$JRNPREV(Offset),1:$$$JRNNEXT(Offset))
	s $li(qHandle,3)=Next
	s $li(Row,1)=Offset
	q $$$OK
}

ClassMethod SearchClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	i $$$JRNCLOSE($li(qHandle,2))
	Quit $$$OK
}

/// Compress a journal file<br>
/// <ul>
/// <li>engine is the name of one of the supported compression engines (eg. lz4, zstd or zlib)</li>
/// <li>chunksz is in MB (range=1-16) and specifies how much uncompressed journal data to pack into one compressed chunk. Larger chunks increase compression 
/// efficiency but requires larger buffers and reading more data from disk to access a journal file record.</li>
/// </ul>
/// The engine and chunksz parameters use the default system values if omitted.<br><br>
/// If compression fails a partially created output file is deleted.<br>
/// The output file must not exist to start with or an error is returned.<br>
/// In order to compress an encrypted file the encryption key must be active and the output file will be encrypted.
/// <br><br>
/// <b>Caution:</b> Be careful with file names. If the intention is to create a compressed version of a journal file with the system's naming scheme
/// by appending a 'z' to the name, specify a temporary output file and then rename/move the resulting file if the operation is succesful to
/// the target name. It is best to avoid having incomplete files with a file name the system might look for. Also take care to ensure the output file has the proper filesystem level protection.
ClassMethod Compress(infile As %String, outfile As %String, enginename As %String = "", chunksz As %Integer = 0) As %Status
{
	if $$$FILEEXISTS(outfile) {
		quit $$$ERROR($$$FileAlreadyExists,outfile)
	}
	if +$G(chunksz)=0 s chunksz=$$$DefaultJrnfileCompressionChunkSz
	#;16 is arbitrary but keep in sync with check inside jrnfunc116() 
	if ((chunksz<1) || (chunksz>64)) { // HYY2323
		quit $$$ERROR($$$JournalCompressionChunkSzRangeErr,chunksz)
	}
	if $G(enginename)="" {
		#;JO3274: correct "enginenane" -> "enginename"
		s enginename=$$$DefaultJrnFileCompressionEngine
	}
	s engineid=$SYSTEM.Util.CompressionNameToID(enginename)
	if engineid=-1 quit $$$ERROR($$$CPFUnknownCompressionEngineName,enginename)
	s flags=$SYSTEM.Util.GetCompressionEngineFlags(engineid)
	if flags["Hidden" quit $$$ERROR($$$CPFUnknownCompressionEngineName,enginename)
	#;JO3286: added quietflag=0
	s rc=$zu(78,116,infile,outfile,engineid,chunksz,0)
	if +rc<1 {
		quit $$$ERROR($$$JournalFileCompressionFailed,infile,rc)
		do $ZU(138,5,outfile)  ;remove the output file
	}
	quit $$$OK
}

/// Decompress a journal file<br>
/// <ul>
/// <li>The output file must not exist or an error is returned</li>
/// <li>If decompression fails, the output file will be deleted</li>
/// <li>To decompress an encrypted file the encryption key must be active and the output file will be encrypted.</li>
/// </ul>
/// <b>Caution:</b> Be careful with file names and locations. If the intention is to create a uncompressed version of a journal file with the system's naming scheme
/// by removing the 'z' from the name it is best to specify a temporary file name and then rename/move the resulting file if the operation 
/// is succesful to the desired target name. When opening a journal file the system first tries to open the uncompressed version. If it opens a file
/// which is being generated it may think that the file is smaller than it actually is (the size will be determined when it is opened) and
/// may return incorrect results. Also take care to ensure that the output file has the proper filesystem level protection.
ClassMethod Decompress(infile As %String, outfile As %String) As %Status
{
	if $$$FILEEXISTS(outfile) {
		quit $$$ERROR($$$FileAlreadyExists,outfile)
	}
	s rc=$ZU(78,117,infile,outfile)
	if +rc<1 {
		quit $$$ERROR($$$JournalFileDecompressionFailed,infile,rc)
	}
	quit $$$OK
}

}
