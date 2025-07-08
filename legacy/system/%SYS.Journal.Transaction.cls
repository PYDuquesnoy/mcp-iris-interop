/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, ROLLBAC)

Class %SYS.Journal.Transaction Extends %Persistent [ StorageStrategy = JournalFileStorage, System = 4 ]
{

Parameter READONLY = 1;

Index TranId On (File, TStart) [ IdKey ];

Property File As %SYS.Journal.File;

Property ProcessID As %Integer;

Property TStart As %SYS.Journal.Record;

Property TStartAddress As %Integer;

Property TerminationType As %String;

Property Records As list Of %SYS.Journal.Record;

Method %LoadData(id As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set file = $Piece(id,",",1), trec = $Piece(id,",",2)
	If (file = "") || (trec = "") { Quit $$$ERROR($$$JournalTransactionIDInvalid,id)}
	s i%File=file
	If '$isobject(..File) { Quit $$$ERROR($$$JournalFileOpenIdFailed,file) }
	d ..File.Use()
	i $$$JRNTYPE(trec)'=$$$JRNBEGTRANS {
		s ..File=""  // close the old file (put off till GetPhysicalLocation()?
		s sc=##class(%SYS.Journal.Record).GetPhysicalLocation(.trec,.file) QUIT:'sc sc
		s ..File=##class(%SYS.Journal.File).%OpenId(file)
		If '$isobject(..File) { Quit $$$ERROR($$$JournalFileOpenIdFailed,file) }
		d ..File.Use()
		i $$$JRNTYPE(trec)'=$$$JRNBEGTRANS { Quit $$$ERROR($$$JournalTransactionStartInvalid,trec,file)} 
	}
	Set i%TStartAddress = trec
	Set i%ProcessID = $$$JRNPID(i%TStartAddress)
	QUIT $$$OK
}

Method RetrieveSelectedValues(ctpRefs As %Integer, ctpValues As %Integer) As %Status
{
		#; ctpRefs is a pointer into $$$ISCQUERYTEMP where the interesting global references are stored. This structure is
		#; designed to facilitate the lookup of a global reference (gref). If the gref is found in the structure then it
		#; is one in which we are interested. We will then pull the new value from the journal and place it into
		#; $$$ISCQUERYTEMP(ctpValues,<extentname>,<addressname>,<objectId>,<nodesubscripts>)
		#; The structure of $$$ISCQUERYTEMP(ctpRefs) is:
		#; 		$$$ISCQUERYTEMP(ctpRefs,<globalhash>) = ""	<<== This is simply a quick top level value intended to quickly eliminate uninteresting globals
		#; 		$$$ISCQUERYTEMP(ctpRefs,<globalreferencehash>,<sub>) = $ListBuild(<globalreference>,<extentname>,<addressname>,<addressstructure>,<objectid>)
		#;
	Set indValRoot = $E($name($$$ISCQUERYTEMP(ctpValues)),1,*-1)_","""
	#;s $zt="Error"
	s addr=i%TStartAddress
ScanFile ;
    d ..File.Use() 
	f  {
		s addr=$$$JRNNEXT(addr) q:addr'>0  
		i $$$JRNPID(addr)'=i%ProcessID continue
		s exttype=$$$JRNTYPE1(addr) q:exttype=$$$JRNCOMMIT  
		s type=$$$JRNExtTypeToType(exttype) i type'=$$$JRNSET continue
		s globalref=$$$JRNNODE(addr)
		s tStrip=$zu(68,7,1) ;to allow us to remove nsp from gref via $name()
		s globalref=$name(@globalref)
		s tStrip=$zu(68,7,tStrip)
		s global=$qs(globalref,0)
		s globalhash=$zcrc($zwunpack(global),7) 
		i '$d($$$ISCQUERYTEMP(ctpRefs,globalhash)) continue
		s globalrefhash=$zcrc($zwunpack(globalref),7)
		s ptr="s" f  {
			s ptr=$o($$$ISCQUERYTEMP(ctpRefs,globalrefhash,ptr),-1) q:ptr=""  
			i globalref'=$list($$$ISCQUERYTEMP(ctpRefs,globalrefhash,ptr),1) continue
			s indVal=indValRoot_$list($$$ISCQUERYTEMP(ctpRefs,globalrefhash,ptr),2)_""","_$e(globalref,$l(global)+2,$l(globalref)-1)_")"
			s @indVal=$$$JRNNEWVAL(addr)
		}
		i ptr="" {
			f  {
			s ptr=$o($$$ISCQUERYTEMP(ctpRefs,globalhash,"s",ptr)) q:ptr=""  
			s matchref=$list($$$ISCQUERYTEMP(ctpRefs,globalhash,"s",ptr),1) 
			i '$e(globalref,1,$l(matchref)-1)=$e(matchref,1,$l(matchref)-1) continue
			s indVal=indValRoot_$list($$$ISCQUERYTEMP(ctpRefs,globalhash,"s",ptr),2)_""","_$e(globalref,$l(global)+2,$l(globalref)-1)_")"
			s @indVal = $$$JRNNEWVAL(addr)
			}
		}
	}
	i addr>0 q $$$OK  // TCOMMIT encountered before end of journal file
	s rc=##class(%SYS.Journal.File).GetNext(..File.Name,.next)
	i rc'=$$$OK quit $$$ERROR($$$JournalFileNextError,..File.Name,rc)
	s ..File=##class(%SYS.Journal.File).%OpenId(next) 
	i '$isobject(..File) quit $$$ERROR($$$JournalFileOpenIdFailed,..File.Name)
	s addr=0 g ScanFile
#;Error s $zt="" d BACK^%ETN q '$$$OK
}

/// Returns the virtual location of the TSTART of current transaction,
/// in the form of JournalFileName,JournalFileOffset,JournalFileCount.<br>
/// Note that the TSTART may be physically located in the next file after
/// journal switches.
ClassMethod GetVirtualLocation() As %String
{
	s $zt="ERROR"
	$$$GETBEGTRANS(tranoffset,tranfilecnt)
	#; The most common case: curfilecnt=tranfilecnt AND paused=0 after curfilename implies curfilename <-> curfilecnt
	#; Note that we must fetch curfilename before testing paused, as curfilename may change after paused is tested 0, before curfilecnt changes (while paused=1)
	s curfilename=$$$JRNCURNAM i '##class(%SYS.Journal.System).IsPaused(),$$$JRNCURFILECNT=tranfilecnt q curfilename_","_tranoffset_","_tranfilecnt
	#; Now that jrnswitch occurs between TSTART and now, our task
	#; is to get a consistent pair of curfilecnt and curfilename
	f  s curfilecnt=$$$JRNCURFILECNT,curfilename=$$$JRNCURNAM q:'##class(%SYS.Journal.System).IsPaused()&&($$$JRNCURFILECNT=curfilecnt)  h:##class(%SYS.Journal.System).IsPaused() .01
	#; Now figure out what file name tranfilecnt corresponds to, using curfilecnt and curfilename
	s filecnt=curfilecnt,filename=curfilename f  q:filecnt'>tranfilecnt  s prevfile=$$$JRNFPREV(filename) q:prevfile=""  s filename=prevfile,filecnt=filecnt-1
	i filecnt'=tranfilecnt ztrap "TLOC"  ;shouldn't happen
	q filename_","_tranoffset_","_tranfilecnt
ERROR s $zt="" d BACK^%ETN  ;log local variables for analysis
	ztrap $ze  ;pass it on to the caller
}

/// Returns the job number of successive processes with open transactions.<br>
ClassMethod GetOpenTx(Job As %Integer, ByRef TxInfo As %String) As %Status
{
	s $zt = "RunErr"
	i 'Job {
		s TxInfo = $zu(34,25)
	} else {
		s TxInfo = $zu(34,25,Job)
	}
	Q $$$OK	
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// Returns the timestamp on the txstart record at journal file index and journal file offset.<br>
ClassMethod GetTxJrnTime(tjrncnt As %Integer, tjrnoff As %Integer, ByRef timestamp As %Integer) As %Status
{
	s $zt = "RunErr"
	
	s jrnoff = $zu(78,4)
	s jrncnt =  $zu(78,26)
	#; check inputs
	i (tjrncnt>jrncnt) s $ze="Invalid journal index" goto RunErr
	s jrnf = $zu(78,3)
	f {
		#; open the file
		s jd = $zu(78,5,jrnf) i jd=-1 s $ze="Failed to open journal file "_jrnf goto RunErr
		s rc = $zu(78,6,jd)
		#; get timestamp if this is the journal file
		i jrncnt=tjrncnt {
			s timestamp = $zu(78,24,tjrnoff)
			i timestamp=-1 s $ze="Invalid offset" goto RunErr
			#; close file    
			d $zu(78,7,jd)
			Q
		}
		#; close file    
		d $zu(78,7,jd)
		s jrncnt = jrncnt - 1 Q:(jrncnt<tjrncnt)
		s jh = $zu(78,22,jrnf,99)
		s jrnf = $p(jh,",",2)
	}
	Q $$$OK	
RunErr
	s $zt=""
	i $d(jd) && (jd'=-1) d $zu(78,7,jd)
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// Returns the number of bytes from starting journal file offset to current journal file offset.<br>
ClassMethod GetTxJrnSize(tjrncnt As %Integer, tjrnoff As %Integer, ByRef tjrnbytes As %Integer) As %Status
{
	s $zt = "RunErr"
	
	s jrnoff = $zu(78,4)
	s jrncnt =  $zu(78,26)
	#; check inputs
	i (tjrncnt>jrncnt) s tjrnbytes=-1 Q $$$OK
	#; if this file, we are done
	i tjrncnt=jrncnt {
		s tjrnbytes = jrnoff - tjrnoff
		i tjrnbytes<0 s tjrnbytes=-1
		Q $$$OK
	}
	#; not in current file. Get previous file name.
	s jendsum = jrnoff
	s jrnf = $zu(78,3)
	#; get the header and file name
	s jh = $zu(78,22,jrnf,99)
	s jrnf = $p(jh,",",2)
	s jrncnt = jrncnt - 1
	f {
		#; open the file
		s jd = $zu(78,5,jrnf) i jd=-1 s tjrnbytes=-1 Q
		s rc = $zu(78,6,jd)
		#; get current offset in journal file
		s jend = $zu(78,18,0)
		i jrncnt=tjrncnt {
			s curbytes = jend - tjrnoff
			i curbytes<0 {
				s tjrnbytes=-1
			} else {
				s tjrnbytes = curbytes + jendsum
			}
			#; close file    
			d $zu(78,7,jd)
			Q
		}
		#; update the total
		s jendsum = jendsum + jend
		#; close file    
		d $zu(78,7,jd)
		s jrncnt = jrncnt - 1
		#; get the header and file name
		s jh = $zu(78,22,jrnf,99)
		s jrnf = $p(jh,",",2)
	}
	Q $$$OK	
RunErr
	s $zt=""
	i $d(jd) && (jd'=-1) d $zu(78,7,jd)
	q $$$ERROR($$$UnexpectedError,$ze)
}

/// Query to get transaction metrics<p>
/// SizeMin: limit transactions listed to those whose size exceeds this value.<p>
/// JobNum: job number in pidtab<p>
/// Pid: job process id<p>
/// JournalBytes: number of bytes from starting journal file offset to current journal file offset.<p>
/// JournalFile: full path name of starting journal file.<p>
/// JournalRef: starting journal file refcount.<p>
/// StartOffset: byte offset of TStart record in starting journal file.<p>
/// StartTime: timestamp of the TStart record in $Horolog format
Query List(SizeMin As %Integer = 0) As %Query(ROWSPEC = "JobNum:%String,Pid:%String,JournalBytes:%Integer,JournalFile:%String,JournalRef:%Integer,StartOffset:%String,StartTime:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, SizeMin As %Integer) As %Status [ Internal ]
{
	s $zt = "RunErr"
	
	s Index=$i($$$ISCQUERYTEMP)
	s qHandle = Index
	#; get current journal offset
	s curjrnoff = $zu(78,4)
	#; for each process, get the transaction file count and journal offset
	#; list of elements for each jnum: jrnfcnt,jrnoff,txlen,jnum,pid,timestamp
	s jnum = 0
	f {
		s txinfo = $zu(34,25,jnum) Q:'+txinfo
		s jnum = $p(txinfo,",",1)
		s pid = $p(txinfo,",",2)
		s txjrnoff = $p(txinfo,",",3)
		s txjrnfcnt = $p(txinfo,",",4)
		s $$$ISCQUERYTEMP(Index,1,jnum) = $lb(txjrnfcnt,txjrnoff,,pid) 
		s $$$ISCQUERYTEMP(Index,2,txjrnfcnt,jnum) = ""
	}
	i '$d( $$$ISCQUERYTEMP(Index,2)) s qHandle("h")="" Q $$$OK
	#; get time and length information. Start with current journal file.
	s jrnfcnt =  $zu(78,26)
	s jrnf = $zu(78,3)
	s jendsum = 0
	s jrnfcnt1st = $o($$$ISCQUERYTEMP(Index,2,""))
	f  {
		#; open the file
		s jd = $zu(78,5,jrnf)
		i jd=-1 {
			s $ze="Failed to open journal file "_jrnf goto RunErr
		}
		s rc = $zu(78,6,jd)
		#; get current offset in journal file
		s jend = $zu(78,18,0)
		#; if tx in this file, set file name and get the tx
		i $d($$$ISCQUERYTEMP(Index,2,jrnfcnt)) {
			s $$$ISCQUERYTEMP(Index,2,jrnfcnt) = $lb(jrnf)  
			#; loop thru the transactions in this file and get the timestamp
			s jnum = ""
			f {
				s jnum = $o($$$ISCQUERYTEMP(Index,2,jrnfcnt,jnum)) Q:jnum=""
				#; get time from jrn blk header
				s $lb(,joff) = $$$ISCQUERYTEMP(Index,1,jnum)
				s t = $zu(78,24,joff)
				s $li($$$ISCQUERYTEMP(Index,1,jnum),5) = t   

				#; update length info for the job	 
				s txd =$$$ISCQUERYTEMP(Index,1,jnum) 
				s $lb(,txjrnoff) = txd
				s txjlen = jend - txjrnoff + jendsum
				s $li($$$ISCQUERYTEMP(Index,1,jnum),3) = txjlen
				i txjlen'<SizeMin s $$$ISCQUERYTEMP(Index,3,jnum) = ""
			}
		}
		#; close file    
		d $zu(78,7,jd)
		#; Get prior journal file. if past earliest journal file we're done.
		s jrnfcnt = jrnfcnt-1
		Q:jrnfcnt<jrnfcnt1st
		#; get the header and file name
		s jh = $zu(78,22,jrnf,99)
		s jrnf = $p(jh,",",2)
	} 	
	s qHandle("jnum") = ""
	Q $$$OK
RunErr
	s $zt=""
	i $d(jd) && (jd'=-1) d $zu(78,7,jd)
	q $$$ERROR($$$UnexpectedError,$ze)
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	s $zt = "RunErr"
	i '$d(qHandle("jnum")) {
		s AtEnd = 1
		Q $$$OK
	}
	s Index = qHandle	
	s jnum = qHandle("jnum")
	s jnum = $o($$$ISCQUERYTEMP(Index,3,jnum))
	i jnum="" {
		s AtEnd = 1
		Q $$$OK
	}	
	s $lb(txjrnfcnt,txjrnoff,jlen,pid,t) = $$$ISCQUERYTEMP(Index,1,jnum)
	s $lb(jrnf) = $g($$$ISCQUERYTEMP(Index,2,txjrnfcnt))
	s Row = $lb(jnum,pid,jlen,jrnf,txjrnfcnt,txjrnoff,t)
	s qHandle("jnum") = jnum
	Q $$$OK
RunErr
	s $zt=""
	q $$$ERROR($$$UnexpectedError,$ze)
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
  i $d(qHandle) k $$$ISCQUERYTEMP(qHandle)
  Q $$$OK
}

Storage JournalFileStorage
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%SYSTEM.FileS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
