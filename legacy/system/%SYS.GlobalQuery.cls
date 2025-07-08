/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syPrompt, %syDataMove)

Class %SYS.GlobalQuery Extends %SYSTEM.Help [ Abstract, System = 3 ]
{

Parameter DEFAULTCONCURRENCY [ Internal ] = 0;

///  Default Localization Domain
Parameter DOMAIN = "%Utility";

ClassMethod DecodeReplication(Index As %Integer) As %String [ Internal, Private ]
{
#define REPENTLEN 8        
 S Bits32=4294967296
 s addr=Index*$$$REPENTLEN+$$$STNETREPA
 S S=$V(addr,-3,4)+($v(addr+4,-3,4)*Bits32)
 s String=""
 F BITNO=0:1 Q:S=0  S:S#2 String=String_BITNO_"," S S=S\2 
 q $e(String,1,$l(String)-1)
}

ClassMethod Lock(Global, Subscript, Name, Timeout = 0) As %Status [ Internal ]
{
	s $zt="Error"
	Set timeout=0
	If $$GetGlobalPermission^%SYS.SECURITY(.ns,Global,"("_$$$QuoteName(Subscript)_")",2)'["WRITE" Quit $$$ERROR($$$RoutineProtect,Name)
	Set global="^|"_$$$QuoteName(ns)_"|"_Global_"("_$$$QuoteName(Subscript)_")"
	For {
		#; If we get the lock we are done
		Lock +@global:timeout If $test Return $$$OK
		Set user=0,job=""
		Set data=$zutil(156,40,ns,"^"_Global,Subscript)
		Set job=$listget($listget(data,2))
		If job'="" Set user=$zutil(67,11,job)
		If timeout=0 {
			If job'="" {
				If $$$IsISCWorker {
					If $$JobIsWorker^%SYS.WorkQueueMgr(job) {
						#; If we are a worker job and we competing with a lock from another worker job then
						#; allow it to wait up to $$$LockTimout for this other worker to release the lock
						Set timeout=$select(Timeout=0:$$$LockTimeout,1:Timeout)
						Continue
					} Else {
						Set mastergroup=$system.Context.WorkMgr().MasterGroup
						If +mastergroup'=0,$$GroupJob^%SYS.WorkQueueMgr(mastergroup)=$piece(job,":") {
							#; If we are a worker and our master process is the one that owns the lock we do not need to lock it at all
							Return $$$OK
						}
					}
				}
				If Timeout=0 {
					#; If we do not want a timeout and we have details on job with the lock return error
					#; If job="" then process that held the lock may have released it so try again for very short period of time
					Quit 
				}
			}
			Set timeout=$select(Timeout=0:0.00001,1:Timeout)
		} Else {
			#; Exit the loop and report an error
			Quit
		}
	}
	If job'="" Quit $$$ERROR($$$CanNotLockRoutineInfo,Name,user,job)
	Quit $$$ERROR($$$CanNotLockRoutine,Name)
Error Set $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

ClassMethod UnLock(Global, Subscript, IModeLock = 0) As %Status [ Internal ]
{
 s $zt="Error"
 Set ns=$$$GBLDBREF(Global,Subscript)
 Set global="^|"_$$$QuoteName(ns)_"|"_Global_"("_$$$QuoteName(Subscript)_")"
 If IModeLock {
	Lock -@global#"I"
 } else {
	Lock -@global 
 }
 Quit $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod DisplayToLogical(%val As %String) As %Library.Boolean [ Internal ]
{
 q $case($zcvt(%val,"U"),$$$GetMsg("%SYSTEM.Library","YES"):1,$$$GetMsg("%SYSTEM.Library","NO"):0,:0)
}

/// Passed a pattern match this returns an COS style pattern and a start and stop point.
ClassMethod Generate(Mask As %String, ByRef Begin As %String, ByRef End As %String, ByRef Pattern As %String, Flag As %Integer) [ Internal ]
{
 #; Mask      - Input,  Wildcard specification
 #; Begin       - Output, AZ style start
 #; End       - Output, AZ style end
 #; Pattern  - Output, Generated pattern
 #; Flag      - Input,  Control flags

 #; Handle A:Z style masks
 If Flag\2#2,Mask[":" Set Begin=$P(Mask,":",1),End=$P(Mask,":",2),Pattern="" Quit

 #; Double up the quotes
 For i=$L(Mask,"""")-1:-1:1 Set Mask=$p(Mask,"""",1,i)_""""""_$p(Mask,"""",i+1,*)

 #; Regular wildcards
 For  Quit:Mask'["**"  Set Mask=$p(Mask,"**",1)_"*"_$p(Mask,"**",2,*)
 Set (Pattern,tPart)="",Begin=$p($TR(Mask,"*?","**"),"*")
 For i=1:1:$Length(Mask) Do
 . If "*?"[$Extract(Mask,i) Do  Quit
 . . If tPart]"" Set Pattern=Pattern_"1"""_tPart_"""",tPart=""
 . . If $Extract(Mask,i)="?" Do  Quit
 . . . Set n=1 For i=i:1:$Length(Mask)-1 Quit:$Extract(Mask,i+1)'="?"  Set n=n+1
 . . . Set Pattern=Pattern_n_"E"
 . . If $Extract(Mask,i)="*" Set Pattern=Pattern_".E" Quit
 . Set tPart=tPart_$E(Mask,i)
 If tPart]"" Set Pattern=Pattern_"1"""_tPart_"""",tPart=""
 If Flag#2=0,Begin_"*"=Mask Set Pattern=""
 Set End=Begin
 Quit
}

ClassMethod LogicalToDisplay(%val As %Library.Boolean) As %String [ Internal ]
{
 q $case(%val,1:$$$GetMsg("%SYSTEM.Library","Yes"),0:$$$GetMsg("%SYSTEM.Library","No"),:%val)
}

/// Returns whether the passed name matches the Pattern array
ClassMethod Matches(Name As %String, ByRef Patterns As %String) As %Boolean [ Internal ]
{
 s Status=0
 s i=$O(Patterns(0,""),1,Work)
 While i'="" {
 	s Pattern=$List(Work),Start=$List(Work,2),End=$List(Work,3)
 	#;The Range STC4:STC5 used to be able to return a global named STC54!
 	i (Pattern'=""&&(Name?@Pattern))||((Start']Name)&&(Name']End)) {
#;If here we have a match on the pattern. Now see if we match any of the
#;"not" patterns If so, set the status back to 0 and get out
		s Status=1
 		s j=$O(Patterns(1,""),1,Work)
 		While j'="" {
 			s Pattern=$List(Work),Start=$List(Work,2),End=$List(Work,3)
 			i (Pattern'=""&&(Name?@Pattern))||((Start']Name)&&(Name']End)) {
				s Status=0
		 		Quit
 			}
 			Set j=$Order(Patterns(1,j),1,Work)
 		}
 		Quit
 	}
 	Set i=$Order(Patterns(0,i),1,Work)
 }
 q Status
}

/// Parses a passed mask into a series of patterns in an array.<br>
/// The resulting array can be passed to the $SYSTEM.Library.Pattern.Matches
/// function along with a Name to determine if the name matches the mask.
/// <br><br>
/// The passed in mask may be a series of masks, each separated by a comma.
/// Valid masks are as follows:
/// <br>
/// ABC* - All strings starting with ABC<br>
/// A:D - All strings between A and D<br>
/// A:D,Y* - All strings between A and D, and all strings starting with Y<br>
/// A:D,'C* - All strings between A and D, except those starting with C
ClassMethod Parse(Masks As %String, ByRef Patterns As %String) [ Internal ]
{
 k Patterns
 f i=1:1:$l(Masks,",") {
 	s Mask=$ZStrip($p(Masks,",",i),"<>W")
 	i $e(Mask)="'" {
	 	s Not=1
	 	s Mask=$e(Mask,2,$l(Mask))
 	} else {
	 	s Not=0
 	}
 	d ..Generate(Mask,.Start,.End,.Pattern,3)
	i Not {
 		s Patterns(1,$o(Patterns(1,""),-1)+1)=$lb(Pattern,Start,End)
	} else {
 		s Patterns(0,$o(Patterns(0,""),-1)+1)=$lb(Pattern,Start,End)
	}
 }
}

/// Check whether the input mask has wildcards specified.
/// Return TRUE if there is wildcard otherwise return FALSE.
ClassMethod Wildcards(Mask As %String = "*") As %Boolean [ Internal ]
{
#; Wildcard if mask is '*'.
 q:Mask="*" 1
 d ..Parse(Mask,.pat)
#; Assume thete is no wildcard.
 s rc=0,id=""
 for {
	 s id=$o(pat(0,id))
	 q:id=""
	 s pat=$li(pat(0,id),1)
#; It is wildcard if it is not like 1"globalname".
	 i pat=""!($e(pat,1,2)'="1""")!($l(pat,"""")'=3)!($e(pat,$l(pat))'="""") s rc=1 q
 }
 q rc
}

/// Returns a list of the Globals in a database<br>
/// <br>
/// <b>Parameters:</b> <br>
/// Directory  -  the directory file-spec for a database file. <br>
/// System  -  ECP database server logical name, as defined in the Application Server list.<br>
/// Mask  -  a mask, or comma-separated list of masks, to select globals. Default is "*" for all.<br>
/// SystemGlobals  -  boolean flag to include system globals in the results. Default is "0".<br>
/// Index  -  Internal use only.<br>
/// IgnoreHasData - For faster list of Globals set this to 1 and the HasData column will always be FALSE.<br>
/// <br>
/// Valid masks are as follows:
/// <br>
/// ABC* - All strings starting with ABC<br>
/// A:D - All strings between A and D<br>
/// A:D,Y* - All strings between A and D, and all strings starting with Y<br>
/// A:D,'C* - All strings between A and D, except those starting with C
Query DirectoryList(Directory As %String, System As %String, Mask As %String, SystemGlobals As %Boolean, Index As %Integer, IgnoreHasData As %Boolean = 0) As %Query(ROWSPEC = "Name:%String,ResourceName:%String,Permission:%String,Empty:%String,Keep:%String,Collation:%String,PointerBlock:%String,GrowthBlock:%String,HasData:%Boolean,Journal:%String") [ SqlProc ]
{
}

ClassMethod DirectoryListExecute(ByRef qHandle As %Binary, Directory As %String, System As %String = "", Mask As %String = "*", SystemGlobals As %Boolean = 0, Index As %Integer = 0, IgnoreHasData As %Boolean = 0) As %Status [ Internal ]
{
#define LocalSystem "LocalSystem"
 s $zt="DirectoryListExecuteE"
 i Index=0 { 
	s Index=$i($$$ISCQUERYTEMP)
 }
 s SuperMask=Mask
 i 'SystemGlobals {
	i $zcvt(Directory,"L")=$zcvt($zu(12),"L") {
		s SuperMask=Mask_$$$PercentSYSSystemGlobalList
	} else {
		s SuperMask=Mask_$$$SystemGlobalList
	}
 }
 s:$e(Directory,1,2)="^^" Directory=$e(Directory,3,$l(Directory))
#;SML965+  ; Use the new GetDatabaseInfo and GetGlobalDIrectoryInfo to get the directory.
 s:System="" System=$$$LocalSystem
 if System=$$$LocalSystem {
	 s:Directory="^" Directory="~"
	 s remsys=""
	 s NSP=$s(Directory="~":"^",1:"^^"_Directory)
 } Else {
	 s remsys=System
	 s NSP="^"_System_"^"_Directory
 }
 s rc=$$GetDatabaseInfo^%SYS.DATABASE(NSP,.dbinfo)
 i $$$ISERR(rc) Quit rc
 s oldval=$zu(68,7,0)
 k ^||DirectoryList
 s save=$name(^||DirectoryList)
 d $zu(68,7,oldval)
 s rc=$$GetGlobalDirectoryInfoFromDBInfo^%SYS.DATABASE(NSP,dbinfo,save,.tally,0)
 i $$$ISERR(rc) Quit rc
 s ResourceName=$$$getresource(dbinfo)
 d 
 . n $roles s $roles=""
 . s Permission=$tr($$$PermissionLogicalToDisplay($System.Security.Users.ResourcePermissionGet(ResourceName)),"U","")
 s ReadOnly=$Case($$$readonlyattrib(dbinfo),0:0,:1)
 i 'ReadOnly s ReadOnly=$$$readonlystatus(dbinfo)
 i ReadOnly s Permission=$tr(Permission,"W","")
 s Journal=..LogicalToDisplay($s($zb(+$p(dbinfo,",",$$$attribpiece),+$zu(40,8,23),1):0,1:1))
 i SuperMask'="*" d ..Parse(SuperMask,.Patterns)
 #; Get an array with the collation numbers/names
 s st=##class(%Collate).MakeArray(.ColName,0,1,2)
 S NextName=""
 For  S NextName=$o(^||DirectoryList(NextName)) Q:NextName=""  D
 . i SuperMask'="*" q:'..Matches(NextName,.Patterns)
 . s dirinfo=^||DirectoryList(NextName)
 . s PointerBlock=$p(dirinfo,"^",3)
 . s GrowthBlock=$p(dirinfo,"^",2)
 . s Collation=$G(ColName(+$p(dirinfo,"^",5)))
 . s IsKeep=..LogicalToDisplay($Case($zb(+$p(dirinfo,"^",4),$zu(40,0,57),1),$zu(40,0,57):1,:0))
 . s GName=$s(Directory="~":"^||",1:"^|""^"_remsys_"^"_Directory_"""|")_NextName
#;In some older version of %GD, checking to see if the global had data in it using $D(GNAME)
#;was a performance hole (possibly across the network). 
#;So we decided to base the check on the Pointer block being = 0.
#;However, the Kill code does not set the Pointer Block to 0 when the global is killed,
#;so it is not quite accurate, so we switched back to use the $D method. When the kill code
#;gets updated, we can change this back to look at the pointer block.
 . ;s IsEmpty=$case(PointerBlock,0:..LogicalToDisplay(1),:..LogicalToDisplay(0))
#;SML1073 ; Don't check $D() of the global if it is asked to ignore it.
 . s HasData=$s(IgnoreHasData:0,1:$d(@GName)'=0)
 . s IsEmpty=..LogicalToDisplay('HasData)
 . s $$$ISCQUERYTEMP(Index,System,Directory,NextName)=$lb(NextName,ResourceName,Permission,IsEmpty,IsKeep,Collation,PointerBlock,GrowthBlock,HasData,Journal)
 Close 63
 k ^||DirectoryList
#;qHandle=index^system^directory^name
 s qHandle=Index_"^"_System_"^"_Directory_"^"
 q $$$OK
#;SML965-
DirectoryListExecuteE s $zt=""
 c 63
#;Put the error message back into the list of globals we return so the user can see we
#;got some sort of error. If this occurs, there is probably some sort of database degrade
 s $$$ISCQUERYTEMP(Index,System,Directory,"ZZ"_$ze)=$lb("ZZ"_$ze,ResourceName,Permission,IsEmpty,IsKeep,Collation,PointerBlock,GrowthBlock,IsEmpty)
#;qHandle=index^system^directory^name
 s qHandle=Index_"^"_System_"^"_Directory_"^"
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod DirectoryListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 	s Index=$p(qHandle,"^",1)
 	s System=$p(qHandle,"^",2)
 	s Directory=$p(qHandle,"^",3)
 	s Name=$p(qHandle,"^",4,999)
	s Name=$o($$$ISCQUERYTEMP(Index,System,Directory,Name),1,Row)
	i Name="" s AtEnd=1,Row=""
	s qHandle=Index_"^"_System_"^"_Directory_"^"_Name
	Quit $$$OK
}

ClassMethod DirectoryListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = DirectoryListExecute ]
{
 s Index=$p(qHandle,"^",1)
 k $$$ISCQUERYTEMP(Index)
 Quit $$$OK
}

/// Returns a list of the Globals in a namespace (used for GUI display)<br>
/// <br>
/// <b>Parameters:</b> <br>
/// NameSpace  -  a namespace. Default is current namespace. <br>
/// Mask  -  a mask, or comma-separated list of masks, to select globals. Default is "*" for all.<br>
/// SystemGlobals  -  boolean flag to include system globals in the results. Default is "0".<br>
/// UnavailableDatabases  -  a returned local array of any databases not currently accessible, i.e. array(name)=status.<br>
/// Index  -  Internal use only.<br>
/// IgnoreHasData - For faster list of Globals set this to 1 and the HasData column will always be FALSE.<br>
/// Mapped - Return all mapped global nodes when set to 1, the default value of this parameter is 1.
/// <br>
/// Valid masks are as follows:
/// <br>
/// ABC* - All strings starting with ABC<br>
/// A:D - All strings between A and D<br>
/// A:D,Y* - All strings between A and D, and all strings starting with Y<br>
/// A:D,'C* - All strings between A and D, except those starting with C
Query NameSpaceList(NameSpace As %String, Mask As %String, SystemGlobals As %Boolean, ByRef UnavailableDatabases As %String, Index As %Integer, IgnoreHasData As %Boolean = 0, Mapped As %Boolean = 1) As %Query(ROWSPEC = "Name:%String,Location:%String,ResourceName:%String,Permission:%String,Empty:%String,Keep:%String,Collation:%String,PointerBlock:%String,GrowthBlock:%String,HasData:%Boolean,Journal:%String,LockLocation:%String,HasSubscripts:%Boolean") [ SqlProc ]
{
}

ClassMethod NameSpaceListExecute(ByRef qHandle As %Binary, NameSpace As %String = {$namespace}, Mask As %String = "*", SystemGlobals As %Boolean = 0, ByRef UnavailableDatabases As %String, Index As %Integer = 0, IgnoreHasData As %Boolean = 0, Mapped As %Boolean = 1) As %Status [ Internal ]
{
#define LocalSystem "LocalSystem"
#define UnknownSystem "UnknownSystem"
#define DIRSLASH $s($$$ISUNIX:"/",$$$ISWINDOWS:"\",1:"")
 s $zt="NameSpaceListExecuteE"
 k UnavailableDatabases
 s Index2=$i($$$ISCQUERYTEMP)
 s Index1=$i($$$ISCQUERYTEMP)
 i Index=0 { 
	s Index=$i($$$ISCQUERYTEMP)
 }
 #;SML1764+
 i $e(NameSpace)'="^" {
	 s NameSpace=$zcvt(NameSpace,"U")
	 if 'Mapped {
		 #; If don't return mapped global then it would work like DirectoryList query.
		 s sysdir=##class(%SYS.Namespace).GetGlobalDest(NameSpace)
		 #; exit if it is a bad namespace.
		 if sysdir="" goto Exit
		 #; treat this as a directory namespace.
		 s NameSpace="^"_sysdir
	 }
 }
 #;SML1764-
#; First handle an implied namespace.
 i $e(NameSpace)="^" {
#if 0 ;JO1844+
	s System=$p(NameSpace,"^",2) i System="" s System=$$$LocalSystem
	s Directory=$p(NameSpace,"^",3)
#else ;JO1844=
    if NameSpace="^" {
	    ; Looking for private globals
	    s System=$$$LocalSystem
	    s Directory="^"
	    s SystemGlobals=0
    } else {
	   s System=$p(NameSpace,"^",2) i System="" s System=$$$LocalSystem
	   s Directory=$p(NameSpace,"^",3)
	}
#endif ;JO1844-
#; Get the globals in the current default database which pass
#; the mask passed in.
 	Set Rset = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
 	s Status=Rset.Execute(Directory,System,Mask,SystemGlobals,Index2,IgnoreHasData)
 	i $$$ISERR(Status) {
	 	i System=$$$LocalSystem {
	 		s UnavailableDatabases(Directory)=Status
	 	} else {
	 		s UnavailableDatabases("\\"_System_"\"_Directory)=Status
		}		 	
 	} else {
#; Merge in the result before the query is killed
 		m $$$ISCQUERYTEMP(Index1)=$$$ISCQUERYTEMP(Index2)
 	}
 	d Rset.Close()
#;Now get the % Globals in the MGR database and merge them in. Note
#;that we can't use the mask at this point, we have to do it below
#;so we don't get extra stuff (i.e. non-percent) added in.
	i SystemGlobals {
 		Set Rset = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
 		s Status=Rset.Execute($zu(12),$$$LocalSystem,"%*",SystemGlobals,Index2,IgnoreHasData)
 		i $$$ISERR(Status) {
 			s UnavailableDatabases(Directory)=Status
 		} else {
#; Merge in the result before the query is killed
 			m $$$ISCQUERYTEMP(Index1)=$$$ISCQUERYTEMP(Index2)
 		}
 		d Rset.Close()
	}
 	d ..Parse(Mask,.Patterns)
 	s System=$o($$$ISCQUERYTEMP(Index1,""))
 	while (System'="") {
		s Directory=$o($$$ISCQUERYTEMP(Index1,System,""))
		while (Directory'="") {
			s Global=$o($$$ISCQUERYTEMP(Index1,System,Directory,""),1,Row)
			while (Global'="") {
 				i ..Matches(Global,.Patterns) {
					s $$$ISCQUERYTEMP(Index,Global)=$lb($li(Row,1),$case(System,$$$LocalSystem:"",:"\\"_System_"\")_Directory)_$li(Row,2,10)_$lb(Directory)_$lb(0 /* HasSubscripts */)
 				}
				s Global=$o($$$ISCQUERYTEMP(Index1,System,Directory,Global),1,Row)
			}
			s Directory=$o($$$ISCQUERYTEMP(Index1,System,Directory))
		}
	 	s System=$o($$$ISCQUERYTEMP(Index1,System))
 	}
 	g Exit
 }
#; Now handle a real namespace.
 i 'SystemGlobals {
 	i NameSpace="%SYS" {
 		 s SuperMask=Mask_",'%a:%z"
 	} else {
		 s SuperMask=Mask_",'%a:%z,'%:%Z"
 	}
 } else {
	 s SuperMask=Mask
 }
#;SML1565+
 #;Get the namespace information and save the original nsgennum.
 #; If later nsgennum is changed then we have to start it over.
 #; If the namespace is removed in the middle of processing, we
 #; need to handle it to return without any information.
Retry ;
 kill $$$ISCQUERYTEMP(Index)
 s nspinfo=$zu(90,28,2,NameSpace)
 if nspinfo="" goto Exit
 s oldnsgennum=$p(nspinfo,"|",6)
 k gxlatinfo
 do getgxlatarray^%SYS.GXLINFO(.nspinfo,"",.gxlatinfo,0)
 #; Oops, the namespace is removed.
 if '$d(gxlatinfo) goto Exit
 #; Retry when the namespace is changed.
 if $p(nspinfo,"|",6)'=oldnsgennum goto Retry
 s num=$o(gxlatinfo(""),1,gxaltinfo)
 while (num'="") {
	s pat=$list(gxaltinfo,1)
	s EntryInfo=$list(gxaltinfo,2)
	s slmtab=$list(gxaltinfo,3)
#; First, get all the implicit mappings
	s indx=$p(EntryInfo,"|",3),indx2=$p(EntryInfo,"|",6)
	s DirectoryIndex(indx)=indx
	s DirectoryIndex(indx2)=indx2
#; Now see if any % globals are mapped that match the mask
	i $e(pat)="%" {
	  s wildpat=$Case(indx=indx2,1:1,:0)
	  for mi=1:1:$l(Mask,",") {
		s Maskx=$p(Mask,",",mi)
		if ($e(Maskx)="%" || ($e(Maskx)="*")) {
			i $e(Maskx,$l(Maskx))="*" s mask=$e(Maskx,1,$l(Maskx)-1),wildmask=1
			e  s wildmask=0,mask=Maskx
			s masklen=$l(mask),patlen=$l(pat),match=0
			i patlen < masklen {
				i wildpat && ($e(pat,1,patlen)=$e(mask,1,patlen)) s match=1
			}
			i patlen > masklen {
				i wildmask && ($e(pat,1,masklen)=$e(mask,1,masklen)) s match=1
			}
			i patlen=masklen {
				i pat=mask s match=1
			}
			i match {
				i wildpat s pat=pat_"*"
				i 'indx {
					s PercentDirs(indx)=""
					quit
				} else {
					s dirpat=$zu(90,7,indx),mgrdir=$zu(12)
					i dirpat'=mgrdir {
						s libdir=$e($$DatabaseByName^%SYS.CONFIG($$$UCFILENAME_"LIB"),3,*)
						i dirpat'=libdir s PercentDirs(indx)="" quit
					}
				}
			}
		}
	  }
	}
#; Now get the replication mappings
	f i=2,5 {
		s RepDirs=..DecodeReplication($p(EntryInfo,"|",i))
		f j=1:1 {
			s RepDir=+$p(RepDirs,",",j)
			q:RepDir=0  
			s DirectoryIndex(RepDir)=RepDir
		}
	}
#; Now get the SLM and SLM Replication directories
	i slmtab'="" {
		s NumSlmMapEntries=$p($li(slmtab,1),"|",1)
		f i=0:1:NumSlmMapEntries-1 {
			s RedirectionPattern=$li(slmtab,i*2+3)
			s DirectoryIndex(+$p(RedirectionPattern,"|",1))=+$p(RedirectionPattern,"|",1)
			s RepDirs=..DecodeReplication(+$p(RedirectionPattern,"|",2))
			f j=1:1 {
				s RepDir=+$p(RepDirs,",",j)
				q:RepDir=0  
				s DirectoryIndex(RepDir)=RepDir
			}
		}
 	}
	s num=$o(gxlatinfo(num),1,gxaltinfo)
 }
#; Add the default global Directory to it 
#; The default global Directory is processed last
 s DirectoryIndex(999999)=$p(nspinfo,"|",2)
#;SML1565-
#; Now for each Directory in the mapping, get all the globals from it
#; by calling the query. Skip over index 0 as it is a placeholder.
 s DirectoryIndex=$o(DirectoryIndex(0),1,Destination)
 while (DirectoryIndex'="") {
	s Directory=$zu(90,7,Destination)
	s System=$zu(90,6,Destination)
	i System=0 {
		s System=$$$LocalSystem
	} else {
		s System=$zu(63,4,System)
		i System="" s System=$$$UnknownSystem
	}
 	Set Rset = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
 	s Status=Rset.Execute(Directory,System,SuperMask,SystemGlobals,Index2,IgnoreHasData)
 	i $$$ISERR(Status) {
	 	i System=$$$LocalSystem {
	 		s UnavailableDatabases(Directory)=Status
	 	} else {
	 		s UnavailableDatabases("\\"_System_"\"_Directory)=Status
		}		 	
 	} else {
#; Merge in the result before the query is killed
 		m $$$ISCQUERYTEMP(Index1)=$$$ISCQUERYTEMP(Index2)
		d Rset.Close()
#; Now find any %globals mapped from the namespace to this directory,
#; using Mask for the query instead of SuperMask
		i DirectoryIndex=999999 s indx=0
		e  s indx=DirectoryIndex
		i $d(PercentDirs(indx)) {
			s Index3=$i($$$ISCQUERYTEMP)
			Set Rset = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
			s Status=Rset.Execute(Directory,System,Mask,SystemGlobals,Index3,IgnoreHasData)
			i '$$$ISERR(Status) m $$$ISCQUERYTEMP(Index1)=$$$ISCQUERYTEMP(Index3)
			d Rset.Close()
			k $$$ISCQUERYTEMP(Index3)
		}
 	}	 		
#;Now build defaults for globals which were not yet created in the databases
#;Note that we can't get defaults for remote globals
#;Default row contains the following:
#;"Location,ResourceName,Permission,Empty,Keep,Collation,PointerBlock,GrowthBlock,Journal"
	i System=$$$LocalSystem {
		s dbinfo=$$$dirinfo(Directory)
		i +dbinfo<0 {
			s DefaultRow(System,Directory)=$lb(Directory,"??","??",..LogicalToDisplay(1),"??","??","0","0","0","??")
		} else {
			s keep=$$$keepstate(dbinfo)
			s resource=$$$getresource(dbinfo)
			s coll=$p(dbinfo,",",$$$colpiece)
			s pntblk=$p(dbinfo,",",$$$gloptrpiece)
			s growblk=$p(dbinfo,",",$$$glogrpiece)
  			s Journal=..LogicalToDisplay($s($zb(+$p(dbinfo,",",$$$attribpiece),+$zu(40,8,23),1):0,1:1))
			s DefaultRow(System,Directory)=$lb(Directory,resource,$$$PermissionLogicalToDisplay($System.Security.Users.ResourcePermissionGet(resource)),..LogicalToDisplay(1),..LogicalToDisplay(keep),##Class(%Library.Collate).LogicalToDisplay(coll),pntblk,growblk,0,Journal)
		}
	} else {
		s DefaultRow(System,Directory)=$lb("\\"_System_"\"_Directory,"??","??",..LogicalToDisplay(1),"??","??","0","0","0","??")
	}
 	s DirectoryIndex=$o(DirectoryIndex(DirectoryIndex),1,Destination)
 }
#; Now get the default Directory and System for the namespace 
#;SML1565
 s DefaultDestination=+$p(nspinfo,"|",2)
 s DefaultDirectory=$zu(90,7,DefaultDestination)
 s DefaultSystem=$zu(90,6,DefaultDestination)
 i DefaultSystem'=0 {
	s DefaultSystem=$zu(63,4,DefaultSystem)
	i DefaultSystem="" s DefaultSystem=$$$UnknownSystem
 } else {
	s DefaultSystem=$$$LocalSystem
 }
#; Now that we have all the directories and globals in them, lets
#; check if the global maps to that Directory at the namespace level.
#; If it does not (i.e. we can't see it) then remove it from the list
 s System=$o($$$ISCQUERYTEMP(Index1,""))
 while (System'="") {
	s Directory=$o($$$ISCQUERYTEMP(Index1,System,""))
	while (Directory'="") {
		s Global=$o($$$ISCQUERYTEMP(Index1,System,Directory,""),1,Row)
		while (Global'="") {
#; First, see if there is a mapping which refers to this global
#;SML1565+
			s num=$o(gxlatinfo(""),1,gxlatinfo),EntryId=0
			while (num'="") {
				if Global']$li(gxlatinfo,1) {
					if Global=$li(gxlatinfo,1) {
						s EntryInfo=$li(gxlatinfo,2),slmtab=$li(gxlatinfo,3)
						if slmtab'=""||$p(EntryInfo,"|",2)||$p(EntryInfo,"|",3)||$p(EntryInfo,"|",4) {
							s EntryId=1
						}
						Quit
					}
					#; The Global collated lower.
					s num=$o(gxlatinfo(num),-1,gxlatinfo)
					if num="" Quit
					s EntryInfo=$li(gxlatinfo,2)
					if $p(EntryInfo,"|",5)||$p(EntryInfo,"|",6)||$p(EntryInfo,"|",7) {
						s EntryId=-1,slmtab=""
					}
					Quit
				}
				#; The Global collated higher.
				s num=$o(gxlatinfo(num),1,gxlatinfo)
			}
#; Now calculate where the lock for this global would go.
			s LockDestination=$s('EntryId:0,EntryId>0:$p(EntryInfo,"|",4),1:$p(EntryInfo,"|",7))
#;SML1565-
			i LockDestination=0 {
				s LockDirectory=DefaultDirectory
				s LockSystem=System
			} else {
				s LockDirectory=$zu(90,7,LockDestination)
				s LockSystem=$zu(90,6,LockDestination)
				i LockSystem'=0 {
					s LockSystem=$zu(63,4,LockSystem)
					i LockSystem="" s LockSystem=$$$UnknownSystem
				} else {
					s LockSystem=$$$LocalSystem
				}
			}
			s LockLocation=$case(LockSystem,$$$LocalSystem:"",:"\\"_LockSystem_"\")_LockDirectory
#; If there is no mapping or replication for this global, then it 
#; must explicitly go in the default database for the namespace. 
#; See if the directory and the system match. If so, create an 
#; entry for it.
			i EntryId=0 {
				i (DefaultDirectory=Directory),(DefaultSystem=System) {
					s $$$ISCQUERYTEMP(Index,Global)=$lb($li(Row,1),$case(DefaultSystem,$$$LocalSystem:"",:"\\"_DefaultSystem_"\")_DefaultDirectory)_$li(Row,2,10)_$lb(LockLocation,$s($li(Row,1)["(":1,1:0 /*HasSubscripts*/))
				}
				g Next	; Next global
			}
#; Now handle mapped globals which are not SLM mapped
			s Found=0
			k IRISTemp
			#;SML1565+
			i slmtab="" {
				s ImplicitDestination=$s('EntryId:0,EntryId>0:$p(EntryInfo,"|",3),1:$p(EntryInfo,"|",6))
			#;SML1565-
				i ImplicitDestination'=0 {
					s ImplicitDirectory=$zu(90,7,ImplicitDestination)
					s ImplicitSystem=$zu(90,6,ImplicitDestination)
					i ImplicitSystem'=0 {
						s ImplicitSystem=$zu(63,4,ImplicitSystem)
						i ImplicitSystem="" s ImplicitSystem=$$$UnknownSystem
					} else {
						s ImplicitSystem=$$$LocalSystem
					}
					i (ImplicitDirectory=Directory),(ImplicitSystem=System) {
						s $$$ISCQUERYTEMP(Index,Global)=$lb($li(Row,1),$case(ImplicitSystem,$$$LocalSystem:"",:"\\"_ImplicitSystem_"\")_ImplicitDirectory)_$li(Row,2,10)_$lb(LockLocation,$s($li(Row,1)["(":1,1:0 /*HasSubscripts*/))
						s Found=1
					} else {
						i $d($$$ISCQUERYTEMP(Index,Global))=0 s IRISTemp(Index,Global)=$lb($li(Row,1))_DefaultRow(ImplicitSystem,ImplicitDirectory)_$lb(LockLocation,$s($li(Row,1)["(":1,1:0 /*HasSubscripts*/))
					}
				}
				#;SML1565
				s ReplicationDestination=$s('EntryId:0,EntryId>0:$p(EntryInfo,"|",2),1:$p(EntryInfo,"|",5))
				i ReplicationDestination'=0 {
					s ReplicationDestinations=..DecodeReplication(ReplicationDestination)
					f j=1:1 {
						s ReplicationDestination=$p(ReplicationDestinations,",",j)
						q:ReplicationDestination=""
						s ReplicationDirectory=$zu(90,7,ReplicationDestination)
						s ReplicationSystem=$zu(90,6,ReplicationDestination)
						i ReplicationSystem'=0 {
							s ReplicationSystem=$zu(63,4,ReplicationSystem)
							i ReplicationSystem="" s ReplicationSystem=$$$UnknownSystem
						} else {
							s ReplicationSystem=$$$LocalSystem
						}
						i (ReplicationDirectory=Directory),(ReplicationSystem=System) {
							s $$$ISCQUERYTEMP(Index,Global_" Replicated")=$lb($li(Row,1)_" (Replicated)",$case(ReplicationSystem,$$$LocalSystem:"",:"\\"_ReplicationSystem_"\")_ReplicationDirectory)_$li(Row,2,10)_$lb(LockLocation,$s($li(Row,1)["(":1,1:0 /*HasSubscripts*/))
							s Found=1
						} else {
							i $d($$$ISCQUERYTEMP(Index,Global_" Replicated"))=0 s IRISTemp(Index,Global_" Replicated")=$lb($li(Row,1)_" (Replicated)")_DefaultRow(ReplicationSystem,ReplicationDirectory)_$lb(LockLocation,$s($li(Row,1)["(":1,1:0 /*HasSubscripts*/))
						}
					}
				}
				i Found m $$$ISCQUERYTEMP(Index)=IRISTemp(Index)
				g Next
			}
#;Now handle SLM mapped globals
#;SML1565
			s DefaultSlmDestination=$s('EntryId:0,EntryId>0:$p(EntryInfo,"|",3),1:$p(EntryInfo,"|",6))
			i DefaultSlmDestination'=0 {
				s DefaultSlmDirectory=$zu(90,7,DefaultSlmDestination)
				s DefaultSlmSystem=$zu(90,6,DefaultSlmDestination)
				i DefaultSlmSystem'=0 {
					s DefaultSlmSystem=$zu(63,4,DefaultSlmSystem)
					i DefaultSlmSystem="" s DefaultSlmSystem=$$$UnknownSystem
				} else {
					s DefaultSlmSystem=$$$LocalSystem
				}
			} else {
				s DefaultSlmDirectory=DefaultDirectory
				s DefaultSlmSystem=DefaultSystem
			}
			#;SML1565+
			s NumSlmMapEntries=$p($li(slmtab,1),"|",1)
			#;SML2587+ ; If the last entry is not mapped to default DB then it must have the :END mapped.
			s EndEntry=$s($p($li(slmtab,(NumSlmMapEntries-1)*2+3),"|")'=0:NumSlmMapEntries-1,1:NumSlmMapEntries-2)
			f i=0:1:EndEntry {
			#;SML2587-
				#;SML1565+
				s RedirPattern=$li(slmtab,i*2+3)
				s SlmDestination=$p(RedirPattern,"|",1)
				#;SML1565-
				i SlmDestination'=0 {
					s SlmDirectory=$zu(90,7,SlmDestination)
					s SlmSystem=$zu(90,6,SlmDestination)
					i SlmSystem'=0 {
						s SlmSystem=$zu(63,4,SlmSystem)
						i SlmSystem="" s SlmSystem=$$$UnknownSystem
					} else {
						s SlmSystem=$$$LocalSystem
					}
				} else {
					s SlmDirectory=DefaultSlmDirectory
					s SlmSystem=DefaultSlmSystem
				}
				;s Subscript="("_$case(i,0:"BEGIN",:$zu(90,17,SlmTableId,i))_":"_$case(i,NumSlmMapEntries-1:"END",:$zu(90,17,SlmTableId,i+1))_")"
#;Remove any trailing $c(1) so display is ok
#;SML1565+		
#;SML2587+ ; 
				if ('i) {
					#; if the first entry is mapped to non-default DB then it is a BEGIN mapping.
					if SlmDestination'=0 {
						s sub1="BEGIN"
						goto getsub2
					}
					s Subscript=""
				} else {
					s sub1=$li(slmtab,i*2+2)
					#; Translate the ending ',""' to ',BEGIN'.
					if $e(sub1,*-2,*)=",""""" s $e(sub1,*-1,*)="BEGIN"
					#; If the last entry is not mapped to default DB then we want to display the :END for the range.
getsub2				if (i = (NumSlmMapEntries-1)) {
						#; The laste entry is mapped to it must mapped to the end of the global.
						s sub2="END"
					} else {
						s sub2=$li(slmtab,i*2+4)
						#; The last byte is $C(1) means mapping to end of this subscript.
						if $e(sub2,*)=$C(1),$e(sub2,1,*-1)'=sub1 s $e(sub2,*)=",END"
					}
					s Subscript=$tr("("_sub1_"):("_sub2_")",$c(1),"")
				}
#;SML2587-				
#; Add the $c(0) here so it will collate before with any replication
				s CollateSubscript="("_$li(slmtab,i*2+2)_$c(0)
#;SML1565-
#;If we have the following mapping in the slm table:
#;  X 	        c:\141u1\mgr\user\
#; 	X(100:200) 	c:\141u1\mgr\newdata\
#; 	X(200:300) 	c:\141u1\mgr\user\ ------->remove this one
#;  X(300:400) 	c:\141u1\mgr\newdata\
#;  Then remove any mappings which map back to the default database (STC2201)
				i (SlmDirectory=DefaultSlmDirectory),(SlmSystem=DefaultSlmSystem),(Subscript'="") continue
				i (SlmDirectory=Directory),(SlmSystem=System) {
					s $$$ISCQUERYTEMP(Index,Global_CollateSubscript)=$lb(Global_Subscript,$case(SlmSystem,$$$LocalSystem:"",:"\\"_SlmSystem_"\")_SlmDirectory)_$li(Row,2,10)_$lb(LockLocation,$s(Subscript["(":1,1:0 /*HasSubscripts*/))
					s Found=1
				} else {
					i $d($$$ISCQUERYTEMP(Index,Global_CollateSubscript))=0 s IRISTemp(Index,Global_CollateSubscript)=$lb(Global_Subscript)_DefaultRow(SlmSystem,SlmDirectory)_$lb(LockLocation,$s(Subscript["(":1,1:0 /*HasSubscripts*/))
				}

				#;SML1565
				s SlmRepDestination=$p(RedirPattern,"|",2)
				i SlmRepDestination'=0 {
					s SlmRepDestinations=..DecodeReplication(SlmRepDestination)
					f j=1:1 {
						s SlmRepDestination=$p(SlmRepDestinations,",",j)
						q:SlmRepDestination=""
						s SlmRepDirectory=$zu(90,7,SlmRepDestination)
						s SlmRepSystem=$zu(90,6,SlmRepDestination)
						i SlmRepSystem'=0 {
							s SlmRepSystem=$zu(63,4,SlmRepSystem)
							i SlmRepSystem="" s SlmRepSystem=$$$UnknownSystem
						} else {
							s SlmRepSystem=$$$LocalSystem
						}
						;s Subscript="("_$case(i,0:"BEGIN",:$zu(90,17,SlmTableId,i))_":"_$case(i,NumSlmMapEntries-1:"END",:$zu(90,17,SlmTableId,i+1))_")"
#;Remove any trailing $c(1) so display is ok
#;SML1565+						
						s Subscript=$tr($case(i,0:"",NumSlmMapEntries-1:"",:"("_$li(slmtab,i*2+2)_":")_$case(i,0:"",NumSlmMapEntries-1:"",:$li(slmtab,i*2+4)_")"),$c(1),"")
#; Add the $c(1) here so replication collates after non-replication
						s CollateSubscript="("_$li(slmtab,i*2+2)_$c(1)
#;SML1565-
						i (SlmRepDirectory=Directory),(SlmRepSystem=System) {
							s $$$ISCQUERYTEMP(Index,Global_CollateSubscript)=$lb(Global_Subscript_" (Replicated)",$case(SlmRepSystem,$$$LocalSystem:"",:"\\"_SlmRepSystem_"\")_SlmRepDirectory)_$li(Row,2,10)_$lb(LockLocation,$s(Subscript["(":1,1:0 /*HasSubscripts*/))
							s Found=1
						} else {
							i $d($$$ISCQUERYTEMP(Index,Global_CollateSubscript))=0 s IRISTemp(Index,Global_CollateSubscript)=$lb(Global_Subscript_" (Replicated)")_DefaultRow(SlmRepSystem,SlmRepDirectory)_$lb(LockLocation,$s(Subscript["(":1,1:0 /*HasSubscripts*/))
						}
					}
				}
			}  ; End For i
			i Found m $$$ISCQUERYTEMP(Index)=IRISTemp(Index)
Next
			s Global=$o($$$ISCQUERYTEMP(Index1,System,Directory,Global),1,Row)
		}
		s Directory=$o($$$ISCQUERYTEMP(Index1,System,Directory))
	}
  	s System=$o($$$ISCQUERYTEMP(Index1,System))
 }
Exit
 k $$$ISCQUERYTEMP(Index1)
#;qHandle=index^name
 s qHandle=Index_"^"
 q $$$OK
NameSpaceListExecuteE s $zt="NameSpaceListExecuteEE"
 k $$$ISCQUERYTEMP(Index1)
 k $$$ISCQUERYTEMP(Index2)
 i $d(Index3) k $$$ISCQUERYTEMP(Index3)
NameSpaceListExecuteEE s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

ClassMethod NameSpaceListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 	s Index=$p(qHandle,"^",1)
 	s Name=$p(qHandle,"^",2,999)
 	s Name=$o($$$ISCQUERYTEMP(Index,Name),1,Row)
 	i Name="" s AtEnd=1,Row="" q $$$OK
	s qHandle=Index_"^"_Name
	Quit $$$OK
}

ClassMethod NameSpaceListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = NameSpaceListExecute ]
{
 s Index=$p(qHandle,"^",1)
 k $$$ISCQUERYTEMP(Index)
 Quit $$$OK
}

/// Returns a list of Globals in a namespace (used for terminal display)<br>
/// <br>
/// <b>Parameters:</b> <br>
/// NameSpace  -  a namespace. Default is current namespace. <br>
/// Mask  -  a mask, or comma-separated list of masks, to select globals. Default is "*" for all.<br>
/// SystemGlobals  -  boolean flag to include system globals in the results. Default is "0".<br>
/// UnavailableDatabases  -  a returned local array of any databases not currently accessible, i.e. array(name)=status.<br>
/// Index  -  Internal use only.<br>
/// <br>
/// Valid masks are as follows:
/// <br>
/// ABC* - All strings starting with ABC<br>
/// A:D - All strings between A and D<br>
/// A:D,Y* - All strings between A and D, and all strings starting with Y<br>
/// A:D,'C* - All strings between A and D, except those starting with C
Query NameSpaceListChui(NameSpace As %String, Mask As %String, SystemGlobals As %Boolean, ByRef UnavailableDatabases As %String, Index As %Integer) As %Query(ROWSPEC = "Name:%String,Location:%String,ResourceName:%String,Permission:%String,Empty:%String,Keep:%String,Collation:%String,Ptr:%String,Grth:%String,HasData:%Boolean,Jrn:%String,LockLocation:%String") [ SqlProc ]
{
}

ClassMethod NameSpaceListChuiExecute(ByRef qHandle As %Binary, NameSpace As %String = {$namespace}, Mask As %String = "*", SystemGlobals As %Boolean = 0, ByRef UnavailableDatabases As %String, Index As %Integer = 0) As %Status [ Internal ]
{
	q ..NameSpaceListExecute(.qHandle,NameSpace,Mask,SystemGlobals,.UnavailableDatabases,Index)
}

ClassMethod NameSpaceListChuiFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	q ..NameSpaceListFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod NameSpaceListChuiClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = NameSpaceListExecute ]
{
	q ..NameSpaceListClose(.qHandle)
}

/// Returns the size of Globals in a database<br>
/// <br>
/// <b>Parameters:</b> <br>
/// Directory  -  the directory file-spec for a database file. <br>
/// System  -  Currently ignored, pass as a null string. Getting the size of a global in an
/// ECP mounted database is not currently supported. You can get the size for these globals directly
/// on the ECP server itself.<br>
/// Mask  -  a mask, or comma-separated list of masks, to select globals. Default is "*" for all.<br>
/// SystemGlobals  -  boolean flag to include system globals in the results. Default is "0".<br>
/// Index  -  Internal use only.<br>
/// FastFlag  -  If 1, don't return 'Used' count, only the precise 'Allocated' count. If 2, return estimates for 'Allocated' and 'Used' (fastest option for huge globals). <br>
/// <br>
/// Valid masks are as follows:
/// <br>
/// ABC* - All strings starting with ABC<br>
/// A:D - All strings between A and D<br>
/// A:D,Y* - All strings between A and D, and all strings starting with Y<br>
/// A:D,'C* - All strings between A and D, except those starting with C
Query Size(Directory As %String, System As %String = "", Mask As %String, SystemGlobals As %Boolean, Index As %Integer, FastFlag As %Integer) As %Query(ROWSPEC = "Name:%String,Allocated MB:%Float:Allocated (MB),Used MB:%Float:Used (MB)") [ SqlProc ]
{
}

ClassMethod SizeExecute(ByRef qHandle As %Binary, Directory As %String, System As %String = "", Mask As %String = "*", SystemGlobals As %Boolean = 0, Index As %Integer = 0, FastFlag As %Integer = 0) As %Status [ Internal ]
{
#define LocalSystem "LocalSystem"
#define UnknownSystem "UnknownSystem"
 s $zt="SizeExecuteE"
 s System=$$$LocalSystem
 s Index1=$i($$$ISCQUERYTEMP)
 i Index=0 { 
	s Index=$i($$$ISCQUERYTEMP)
 }
 Set Rset = ##class(%ResultSet).%New("%SYS.GlobalQuery:DirectoryList")
#;SML1073 ; use faster global list.
 s Status=Rset.Execute(Directory,System,Mask,SystemGlobals,Index1,1)
 i $$$ISERR(Status) Quit Status
#; Merge in the result before the query is killed
 m $$$ISCQUERYTEMP(Index)=$$$ISCQUERYTEMP(Index1)
 d Rset.Close()
 s qHandle=Index_"^"_System_"^"_Directory_"^"_FastFlag_"^"
 q $$$OK
SizeExecuteE s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$Zerror)
}

ClassMethod SizeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 	s Index=$p(qHandle,"^",1)
	s System=$p(qHandle,"^",2)
	s Directory=$p(qHandle,"^",3)
	s FastFlag=$p(qHandle,"^",4)
	s Name=$p(qHandle,"^",5,999)
	s Name=$o($$$ISCQUERYTEMP(Index,System,Directory,Name),1,Row)
	i Name="" s AtEnd=1,Row="" quit $$$OK
 	s sc=##class(%GlobalEdit).GetGlobalSize(Directory,Name,.Allocated,.Used,FastFlag)
 	i $$$ISERR(sc) Quit sc
	e  s Row=$lb(Name,Allocated,$G(Used,0))
	s qHandle=Index_"^"_System_"^"_Directory_"^"_FastFlag_"^"_Name
	Quit $$$OK
}

ClassMethod SizeClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = SizeExecute ]
{
 s Index=$p(qHandle,"^",1)
 k $$$ISCQUERYTEMP(Index)
 Quit $$$OK
}

/// Measures the size of a given global or subnode in the current namespace,
/// iterating over the mappings and measuring data in each.
/// Each row returns the subscript range that was measured, the corresponding
/// database, and either allocated or estimated size in megabytes (MB). <br>
/// <br>
/// For root globals, this query measures size by each subscript mapping. 
/// The sum will equal the total size (or estimate) of the global
/// from the namespace's perspecive.<br>
/// <br>
/// For subnodes, this query measures the entire subnode once in each mapped database.
/// In typical scenarios, this will still sum to the subnode's overall size
/// from the namespace's perspective.<br>
/// <br>
/// Note that in certain configurations, a database may contain global
/// data that the namespace doesn't see. This can happen if different namespaces
/// map different parts of the same global to the same database.
/// Subnode queries may measure unseen data and return inflated results in these cases.<br>
/// <br>
/// Measurements in remote or dismounted databases are unsupported.
/// They either return errors or are quietly skipped if SilentSkip=1.<br>
/// <br>
/// <b>Parameters:</b> <br>
/// Global - the name of the global or subnode to measure (for example, "testglobal" or "testglobal(1)"),
/// 	with or without a prepended carat.<br>
/// FastFlag - flag to run fast stochastic estimation. 
/// 	If set, fills Estimated column. Otherwise, fills Allocated column.
/// 	Default is 0 (not set). 1 is recommended for huge globals. <br>
/// SilentSkip - flag to silently skip unavailable databases and exclude them from results. 
/// 	If 0 (not set), stops and returns an error instead of skipping. Default is 0. <br>
/// 
Query NameSpaceSize(Global As %String, FastFlag As %Boolean = 0, SilentSkip As %Boolean = 0) As %Query(ROWSPEC = "SubscriptRange:%String,Database:%String,Allocated:%Float:Allocated (MB),Estimated:%Float:Estimated (MB)") [ SqlProc ]
{
}

/// Executes all relevant subscript range measurements and assembles them in a temp global for Fetch.
/// 
ClassMethod NameSpaceSizeExecute(ByRef qHandle As %Binary, Global As %String, FastFlag As %Boolean = 0, SilentSkip As %Boolean = 0) As %Status [ Internal ]
{
    Try {
        Set Index=$i($$$ISCQUERYTEMP)
        Set Namespace=$NAMESPACE
		// Remove the prepended carat, if present. Underlying method calls don't expect it.
		If $e(Global,1)="^" Set Global=$piece(Global,"^",2)
	    // Retrieve a validated array of subscript mappings for this global.
        Set sc=..GetGlobalMappings(Namespace,Global,.mapArray,SilentSkip)
        If sc'=$$$OK Return sc
        Set Entry=$o(mapArray(""))
        // Store this information to be iterated over in Fetch.
        While (Entry'="") {
            Set Directory=$listget(mapArray(Entry),1)
			Set SubscriptRange=$listget(mapArray(Entry),2)
			Set StartNode=$piece(SubscriptRange,":",1)
            Set EndNode=""
            If (SubscriptRange[":") set EndNode=Global_$piece(SubscriptRange,":",2)
            Kill Size
			Set sc=##class(%GlobalEdit).GetGlobalSizeBySubscript(Directory,StartNode,EndNode,.Size,FastFlag)
    		If $$$ISERR(sc) Return sc
			If FastFlag {
        		Set Allocated=""
        		Set Estimated=Size
    		} Else {
        		Set Allocated=Size
        		Set Estimated=""
    		}
			Set $$$ISCQUERYTEMP(Index,Entry)=$lb(SubscriptRange,Directory,Allocated,Estimated)
            Set Entry=$o(mapArray(Entry))
        }
        Set qHandle("Index")=Index
        Set qHandle("Entry")=""
        Return $$$OK
    } Catch(error) {
        Return error.AsStatus()
    }
}

/// Iterates over results in the temp global assembled by NameSpaceSizeExecute.
/// Results should already be in the $list format expected for rows.
/// 
ClassMethod NameSpaceSizeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
    Set Index=qHandle("Index")
    Set Entry=qHandle("Entry")
    Set Entry=$order($$$ISCQUERYTEMP(Index,Entry),1,Row)
    If Entry="" Set AtEnd=1,Row="" Quit $$$OK
    Set qHandle("Entry")=Entry
    Quit $$$OK
}

/// Cleans up the temp global data from NameSpaceSizeExecute.
/// 
ClassMethod NameSpaceSizeClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = NameSpaceSizeExecute ]
{
 s Index=qHandle("Index")
 k $$$ISCQUERYTEMP(Index)
 Quit $$$OK
}

/// Internal helper for the NameSpaceSize class query.
/// Amasses a validated array of subscript mappings and their corresponding databases
/// for a given global (or subnode) in a given namespace.
/// Takes as input a global name (no carat), the empty array
/// to fill (passed by reference), and the SilentSkip flag.
/// 
/// By default, returns status OK if all databases are local and available and
/// an error status if a database is remote, dismounted, or missing.
/// If SilentSkip is set, it skips over unavailable databases and assembles
/// an array of the local, available ones without complaint.
/// 
ClassMethod GetGlobalMappings(Namespace As %String, Global As %String, ByRef mapArray, SilentSkip As %Boolean = 0) As %Status [ Internal ]
{
	Set stmt=##class(%SQL.Statement).%New()
	Set sc=stmt.%PrepareClassQuery("%SYS.GlobalQuery","NameSpaceList",0)
	If sc'=$$$OK Return sc
	Set SystemGlobals=1,UnavailableDatabases="",IgnoreHasData=1,Mapped=1
	// NameSpaceList only works with root global names, not with subnodes.
	// We extract the root name to get the possible relevant mappings.
	Set IsSubnode=($piece(Global,"(",2)'="")
	Set Rset=stmt.%Execute(Namespace,$piece(Global,"(",1),SystemGlobals,.UnavailableDatabases,,IgnoreHasData,Mapped)
	If Rset.%SQLCODE<0 Return $$$ERROR($$$SQLError,Rset.%SQLCODE,Rset.%Message)
	Set Directories=0
	Set mapArray=0
	// Even if the global has no subscript mappings, if the global has
	// any data, NameSpaceList will return the default global mapping for it.
	// It may return no entries if the global has no data at all.
	While Rset.%Next(.sc) {
		If sc'=$$$OK Return sc
		// Check if database is remote or otherwise unavailable.
		// If the database is remote or dismounted, we can't measure it.
		Set Directory=Rset.%Get("Location")
		Set remote=($extract(Directory,1,2)="\\")
		Set rc=$zu(49,Directory)
		If ((rc<=-1)||remote)&&(SilentSkip) continue
		If remote return $$$ERROR($$$DatabaseIsRemote,Directory)
		If rc<-1 return $$$ERROR($$$DatabaseDoesNotExist,Directory)
		If rc=-1 return $$$ERROR($$$DatabaseIsDismounted,Directory)
		// Database is local and available; add mapping to array
		Set Name=Rset.%Get("Name")
		// For whole globals, we measure each subscript mapping.
		// For subnodes, we measure the whole subnode once in each database.
		If 'IsSubnode {
			Set mapArray=mapArray+1
			Set mapArray(mapArray)=$lb(Directory,Name)
		} ElseIf $GET(Directories(Directory),"")="" {
			Set mapArray=mapArray+1
			Set mapArray(mapArray)=$lb(Directory,Global)
			Set Directories(Directory)=1
		}
	}
	Return sc
}

Storage GlobalStorage
{
<StreamLocation>^%SYS.GlobalQueryS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
