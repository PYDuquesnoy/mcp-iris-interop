/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// Subclass of <CLASS>%FileCharacterStream</CLASS> that is used to load, save, compile,
/// delete, etc. CSP files. To create one you pass it the URL of the CSP file you wish
/// to manipulate such as:
/// <EXAMPLE>
/// Set stream=##class(%CSP.Routine).%New("/csp/samples/inspector.csp")
/// Do stream.OutputToDevice()
/// </EXAMPLE>
Class %CSP.Routine Extends %FileCharacterStream [ System = 3 ]
{

/// Override of file extension from %FileCharacterStream.
Parameter FILEEXT = "csp";

/// True if this routine is generated from something else
Property Generated As %Boolean;

Property IsModified As %Boolean [ InitialExpression = 0 ];

Property UpToDate As %Boolean [ Calculated ];

Method UpToDateGet() As %Boolean
{
	If i%IsModified Quit 0
	Set ts=##class(%RoutineMgr).TS(i%Url,,.uptodate)
	Quit uptodate
}

/// Override of %OnClose method from %FileCharacterStream
Method %OnClose() As %Status [ Internal, Private ]
{
	If i%Locked Set i%Locked=1 Do ..Unlock()
	Quit ##super()
}

/// Override of IOGetStreamId method from %FileCharacterStream
Method IOGetStreamId() As %String [ Internal, Private ]
{
	Quit i%Url
}

/// Override of %OnNew method from %FileCharacterStream
Method %OnNew(url As %String = "") As %Status [ Internal, Private ]
{
	#; pass CSP url via %OnNew()
	If url="" Quit $$$OK
	Quit ..LinkToUrl(url)
}

/// Override of OpenStream method from %FileCharacterStream to open a %CSP.Routine.
Method OpenStream(url As %String) As %Status
{
	If url="" Quit $$$OK
	Quit ..LinkToUrl(url)
}

/// Override of SaveStream method from %FileCharacterStream to save this stream
Method SaveStream(supressbackup As %Boolean = 1, Output Refresh As %Boolean) As %Status
{
	#Dim rc,type,new,old,io,timemodified,tmp,same,zeof,status
	Set Refresh=0
	If i%Mode=..#READNOTCHANGED||(i%Mode=..#READNODATA) Quit $$$OK
	#; close file (if open), go to read mode
	Set rc=$$$OK
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	Set type=$zconvert($piece(i%Url,".",$length(i%Url,".")),"U")
	Set new=i%NormalizedDirectory_i%TempFile,old=$select(i%StoreFile="":"",1:i%NormalizedDirectory_i%StoreFile)
	Set io=$IO
	If '##class(%File).Exists(new) Quit $$$ERROR($$$CSPNoSave,old,new)
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set shabefore=##class(%File).SHA1Hash(new)
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeSave(i%Url,new,$this)
	Set same=##class(%File).Compare(old,new)
	If same {
		Do ##class(%File).Delete(new)
	} ElseIf i%StoreFile'="" {
		Set $ztrap="copyerr"
		Open new:("RUK\RAW\":::/NOXY=1):0 Else  Close old Goto cont
		Open old:("WNRUK\RAW\":::/NOXY=1):0 Else  Goto cont
		Do {
			Use new Read tmp#32000 Set zeof=$zeof Use old Write tmp
		} While 'zeof
copyerr	Set $ztrap=""
		Use io
		Close new,old
		Do ##class(%File).Delete(new)
cont	Use io
	} Else {
		Set i%StoreFile=i%TempFile,i%TempFile=""
	}
	Set i%Mode=..#READNOTCHANGED
	Use io

	// if the file has changed and it is not a .csp or .csr file, then clear any existing version from the Gateways' caches
	If ('same) {
		Set rc=..ClearGatewayCache(i%Url)
		If $$$ISERR(rc) Quit rc
	}
	
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterSave(i%Url,$this)
	. If ##class(%File).SHA1Hash(i%NormalizedDirectory_i%StoreFile)'=shabefore Set Refresh=1
	Set i%IsModified=0
	Quit rc
}

/// If needed this will clear the gateway cache of this static url
ClassMethod ClearGatewayCache(url As %String, clear As %List = "") As %Status
{
	If $get(^%SYS("CSP","DisableGatewayCacheClear"),0) Quit $$$OK
	If $extract(url)'="/" Set url="/"_url
	Set type=$zconvert($piece(url,".",$length(url,".")),"u")
	If type="CSP"||(type="CSR")||($length(url,"/")=2) Quit $$$OK
	Set remove=""
	If clear="" Set clear=$listbuild("*/"_$piece(url,"/",$length(url,"/")))
	#; The /csp/broker files are in every CSP application so we will always remove these from the cache
	If $piece(url,"/",1,3)="/csp/broker" {
		#; get filename from url
		Set remove=clear
	} Else {
		#; Check to see if this url has gateway caching of static files turned on and has an expiration for files
		Set app=$$getapp^%SYS.cspServer(url,.path)
		Set expires=$$$GetSecurityApplicationsServeFilesTimeout(app)
		If expires>0,$$$GetSecurityApplicationsServeFiles(app)=2 {
			Set remove=clear
		}
	}
	If remove'="" {
		Set registry = $System.CSP.GetGatewayRegistry()
		If $isobject(registry) Set sc=registry.RemoveFilesFromCaches(remove) If $$$ISERR(sc) $$$DecErrorNum			
	}
	Quit $$$OK
}

/// Property holding the URL for this CSP application.
Property Url As %String;

/// Set method for Url property
Method UrlSet(url As %String) As %Status [ Internal ]
{
	Quit ..LinkToUrl(url)
}

/// Readonly property holding the namespace for this CSP application.
Property Namespace As %String;

/// Set method for Namespace property to make it readonly
Method NamespaceSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%Namespace=val
	Quit $$$OK
}

/// Link this stream to the file pointed to by this <var>url</var>.
Method LinkToUrl(url As %String = "") As %Status
{
	If url="" Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	If $extract(url)'="/" Set url="/"_url
	Quit:url=i%Url $$$OK
	Set version=$piece(url,";",2,*),url=$piece(url,";")
#;No more versioning csp. Always use current.
	i version'="" q $$$ERROR($$$FeatureNotSupported,"CSP versioning")
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeLoad(url)
	Set filename=$$GetFilename^%apiCSP(url,.path,.config)
	If filename="" Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	If $$$GetSecurityApplicationsNameSpace(config)'=$namespace Quit $$$ERROR($$$CSPIncorrectNamespace,url,$$$GetSecurityApplicationsNameSpace(config),$namespace)
	#; Check the directory exists and create it if not
	If '##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename)) Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	#; If current routine is locked then lock the new name and release the existing lock
	If i%Locked {
		Set ok=..LockRoutine(url,1)
		If $$$ISERR(ok) Quit ok
		Do ..LockRoutine(i%Url,0)
	}
	Set i%Url=url
	Set i%Namespace=$$$GetSecurityApplicationsNameSpace(config)
	Set sc=..LinkToFile(filename)
	If $$$ISERR(sc) Quit sc
	If $isobject($get(%SourceControl))=1 {
		If ##class(%File).Exists(filename) {
			#; Need to create temporary file from real one with permanent store being correct name
			Set newfilename=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_##class(%FileBinaryStream).NewFileName($select(filename[".":$piece(filename,".",*),1:""))
			#; Need to create the new file as writable so use my own copy method rather than %File one
			Set ..Directory="",i%StoreFile=filename,i%TempFile=newfilename,i%Mode=..#READCHANGED
			If '..CopyFile(filename,newfilename) Quit $$$ERROR($$$FileCanNotCopy,filename,newfilename)
		}
		Set tmp=%SourceControl New %SourceControl Set sc=tmp.OnAfterLoad(url,$this)
	}
	Set i%IsModified=0
	Quit sc
}

/// Copy file.
ClassMethod CopyFile(oldn As %String, newn As %String) As %Boolean [ Internal ]
{
	Quit $$copy^%apiOBJ(oldn,newn)
}

/// Compile this CSP page. This calls <METHOD>SaveStream</METHOD> to flush the stream
/// out to disk before calling compile.
Method Compile(qspec As %String = "") As %Status
{
	#Dim type,sc,qstruct,rc,tmp,errcount
	
	Set type=$zconvert($piece(i%Url,".",$length(i%Url,".")),"U")
	If type'="CSP",type'="CSR" Quit $$$OK
	Set sc=$$$OK
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	New $namespace Set $namespace=i%Namespace
	If i%IsModified Set sc=..SaveStream() If $$$ISERR(sc) Quit sc
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnBeforeCompile(i%Url,.qstruct)
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	
	If $ZConvert($Piece(i%Url,".",$Length(i%Url,".")),"l")="csp" {
		Set sc=$$loadCSPPage^%apiCSP(i%Url,.qstruct,$$$cFAMILYCSP)
		if '$get(^%SYS("CSP","DisableGatewayCacheClear")) {
			try {
				// clear any existing version from the Gateways' caches
				#Dim registry As %CSP.Mgr.GatewayRegistry
				#Dim fn As %String
				#Dim iii As %Integer
				Set fn=i%Url
				#; get filename from url
				For { S iii=$f(fn,"/") Quit:iii=0   S fn=$e(fn,iii,*) }
				Set registry = $System.CSP.GetGatewayRegistry()
				Set rc=registry.RemoveFilesFromCaches($lb("*/"_fn)) If $$$ISERR(rc) $$$DecErrorNum
			} catch {}
		}
	} Else {
		Set:i%Url'="" sc=$$loadCSPPage^%apiCSP(i%Url,.qstruct,$$$cFAMILYCSR)
	}

	If $isobject($get(%SourceControl)) Do
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnAfterCompile(i%Url) If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	Quit sc
}

/// Delete the file associated with this CSP url
ClassMethod Delete(url As %String) As %Status [ ProcedureBlock = 1 ]
{
	If url="" Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	Set version=$piece(url,";",2,*),url=$piece(url,";")
	i version'="" q $$$ERROR($$$FeatureNotSupported,"CSP versioning")
	Set type=$zconvert($piece(url,".",$length(url,".")),"U")
	If $extract(url)'="/" Set url="/"_url
	Set filename=$$GetFilename^%apiCSP(url,.path,.config)
	If filename="" Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	If $$$GetSecurityApplicationsNameSpace(config)'=$namespace Quit $$$ERROR($$$CSPPageDoesNotExist,url)
	#; Only delete CSP pages we can lock
	Set ok=..LockRoutine(url,1,0)
	If $$$ISERR(ok) Quit ok
	Do ..LockRoutine(url,0,0)
	If type="CSR" {
		Set ok=$$DeleteRuleFile^%apiCSP(url)
		If $$$ISERR(ok) Quit ok
	}
	If '##class(%File).Delete(filename) Quit $$$ERROR($$$FileCanNotDelete,filename)
	If type="CSP" {
		Set classname=$$GetCSPClassName^%SYS.cspServer(url),sc=$$$OK
		If classname'="",$$$defClassDefined(classname) {
			Set deleteclass=1
			$$$comMemberKeyGetLvar(cspfile,classname,$$$cCLASSparameter,"CSPFILE",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(cspurl,classname,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)
			If $$$isWINDOWS {
				If $ZConvert(cspfile,"l")=$ZCVT(filename,"l")||($zconvert(cspurl,"l")=$zconvert(url,"l")) Set ok=$$Delete^%apiOBJ(classname,"-d")
			} Else {
				If cspfile=filename||($piece(cspurl,".",1,$length(cspurl,".")-1)=$piece(url,".",1,$length(url,".")-1))  Set ok=$$Delete^%apiOBJ(classname,"-d")
			}
		}
	}
	Quit ok
}

/// Return true if the CSP file exists (not the class) and false otherwise.
ClassMethod Exists(url As %String) As %Boolean
{
	If url="" Quit 0
	Set version=$piece(url,";",2,*),url=$piece(url,";")
	Set type=$zconvert($piece(url,".",$length(url,".")),"U")
	If version'="" Throw ##class(%Exception.StatusException).ThrowIfInterrupt($$$ERROR($$$FeatureNotSupported,"CSP versioning"))
	If $extract(url)'="/" Set url="/"_url
	Set filename=$$GetFilename^%apiCSP(url)
	If filename="" Quit 0
	Set exists=##class(%File).Exists(filename)
	If exists Quit 1
	If type'="CSP",type'="CSR" Quit 0
	Set cls=$$GetCSPClassName^%SYS.cspServer(url)
	If cls="" Quit 0
	$$$comMemberKeyGetLvar(cspfile,cls,$$$cCLASSparameter,"CSPFILE",$$$cPARAMdefault)
	If cspfile=filename||(cspfile="") Quit 0
	Quit ##class(%File).Exists(cspfile)
}

/// Return the timestamp of this CSP/CSR file. If there is no file then return -1
ClassMethod GetDate(url As %String) As %TimeStamp
{
	If url="" Quit -1
	If $extract(url)'="/" Set url="/"_url
	Set url=$piece(url,";")
	Set filename=$$GetFilename^%apiCSP(url)
	If filename="" Quit -1
	Set time=##class(%File).GetFileDateModified(filename)
	If +time<1 Quit -1
	Quit $zdt(time,3)
}

/// Get the timestamp for the routine.
Method GetCurrentTimeStamp() As %TimeStamp
{
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Do tmp.OnBeforeTimestamp(..Url)
	Quit ..LastModified
}

/// Caclulated property that contains the current timestamp for the routine.
Property TimeStamp As %TimeStamp [ Calculated ];

/// Get method for TimeStamp property.
Method TimeStampGet() As %TimeStamp [ CodeMode = expression, Internal ]
{
..GetCurrentTimeStamp()
}

/// Number of times this routines has been locked.
Property Locked As %Integer [ InitialExpression = 0 ];

/// Lock the current routine
Method Lock() As %Status
{
	If i%Locked>0 {
		Set i%Locked=i%Locked+1
		Quit $$$OK
	}
	Set ok=..LockRoutine(i%Url,1)
	If $$$ISERR(ok) Quit ok
	Set i%Locked=1
	Quit $$$OK
}

/// Unlock the current routine
Method Unlock() As %Status
{
	Quit:i%Locked=0 $$$OK
	If i%Locked>1 {
		Set i%Locked=i%Locked-1
		Quit $$$OK
	}
	Set ok=..LockRoutine(i%Url,0)
	If $$$ISERR(ok) Quit ok
	Set i%Locked=0
	Quit $$$OK
}

/// Lock or unlock a particular routine <parameter>name</parameter>. If <parameter>lock</parameter>
/// is true then it will be locked else it will be unlocked.
ClassMethod LockRoutine(name As %String, lock As %Boolean = 1, checkfile As %Boolean = 1) As %Status
{
	Set name=$piece($translate(name,"\","/"),";")
	If $Extract(name)'="/" Set name="/"_name
	Set file=$$GetFilename^%apiCSP(name)
	If file="" Quit $$$ERROR($$$CSPPageDoesNotExist,name)
	If checkfile,##class(%File).Exists(file) {
		#; Test if file in filesystem is writeable
		If '$$$FileWritable(file) {
			Quit $$$ERROR($$$CanNotLockCSP,file,name)
		}
	}
	If checkfile=-1 Quit $$$OK
	If $ZConvert($Piece(name,".",$Length(name,".")),"l")'="csp" {
		if lock {
			Quit ##Class(%SYS.GlobalQuery).Lock("cspRule",file,name)
		} else {
			Quit ##Class(%SYS.GlobalQuery).UnLock("cspRule",file,0)
		}
	} Else {
		Set class=$$CSPClassName^%apiCSP(name,"")
		If class="" {
			If lock {
				Quit ##Class(%SYS.GlobalQuery).Lock("cspRule",file,name)
			} else {
				Quit ##Class(%SYS.GlobalQuery).UnLock("cspRule",file,0)
			}
		}
		If lock {
			Quit ##Class(%SYS.GlobalQuery).Lock("oddDEF",class,name)
		} else {
			Quit ##Class(%SYS.GlobalQuery).UnLock("oddDEF",class,0)
		}
	}
	Quit $$$OK
}

/// Override of GetReadOpenParameter from %FileCharacterStream
Method GetReadOpenParameter(filename As %String, mode As %Integer, ByRef pos As %Integer) As %String [ Internal, Private ]
{
	Set parm = $select(mode=..#READLINE:..#OPENREADTERM,1:..#OPENREAD)
	If (i%TranslateTable=0) && (pos=0) {
		Set i%BOM=""
		Set io=$io
		Open filename:"RUK\RAW\":0 Else  Quit parm ; caller will report error
		Try {
			Use filename Read header#512
		} Catch {
			Set header=""
		}
		If $extract(header,1,2)=$Char(255,254) Set i%TranslateTable="UnicodeLittle",i%BOM=$char(255,254),pos=2
		If $extract(header,1,2)=$Char(254,255) Set i%TranslateTable="UnicodeBig",i%BOM=$char(254,255),pos=2
		If $extract(header,1,3)=$Char(239,187,191) Set i%TranslateTable="UTF8",i%BOM=$char(239,187,191),pos=3
		If pos=0 {
			Set ext=$zconvert($piece(filename,".",$length(filename,".")),"l"),charset=""
			If ext="csp"||(ext="csr")||(ext="htm")||(ext="html")||(ext="asp") {
				#; Now look for <%@PAGE directive
				Set find=$find(header,"<%")
				While find'=0 {
					If $length($extract(header,1,find-3),"""")#2,$length($extract(header,1,find-3),"'")#2 {
						If $$getPage^%cspCompile($extract(header,find-2,*),.lang,.charset) Quit
					}
					Set find=$find(header,"<%",find)
				}
			} ElseIf ext="xml",$extract($zstrip(header,"*W"),1,5)="<?xml" {
				Set header=$piece($piece($zstrip(header,"*W"),">"),"encoding=",2)
				Set quote=$extract(header)
				Set charset=$piece($piece(header,quote,2),header)
				If charset="" Set charset="UTF-8"
			}
			If charset="" {
				Set charset=##class(%SYS.NLS.Table).GetCSPTable()
				If charset="" Set charset=$get(^%SYS("CSP","DefaultFileCharset"))
			}
			If charset'="" {
				If ##class(%Net.Charset).TranslateTableExists(charset) Set i%TranslateTable=##class(%Net.Charset).GetTranslateTable(charset)
			}
		}
		Use io
		Close filename
	}
	
	If i%TranslateTable=0 Set i%TranslateTable=""
	
	Quit parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")
}

Method GetWriteOpenParameter(filename As %String, mode As %Integer) As %String [ Private ]
{
	Set parm=$select(mode=..#WRITEAPPEND:..#OPENAPPEND,1:..#OPENWRITE)
	Set i%IsModified=1
	If i%TranslateTable=0 {
		Set i%TranslateTable=""
		Set charset=##class(%SYS.NLS.Table).GetCSPTable()
		If charset="" Set charset=$get(^%SYS("CSP","DefaultFileCharset"))
		If charset'="" {
			If ##class(%Net.Charset).TranslateTableExists(charset) Set i%TranslateTable=##class(%Net.Charset).GetTranslateTable(charset)
		}
	}
	If mode'=..#WRITEAPPEND,i%BOM'="" {
		Set io=$io
		Open filename:(..#OPENWRITE_"K\RAW\":/noxy=1):0 Else  Goto exit
		Use filename
		Write i%BOM
		Use io
		Close filename
		Set parm=..#OPENAPPEND
	}
	If '..StreamFormatWrite Set parm=$translate(parm,"S","U")
exit	Quit parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")
}

Method Clear(permanent As %Boolean = 1) As %Status
{
	Set i%IsModified=1
	Quit ##super(permanent)
}

Storage Custom
{
<Type>%Library.CompleteCustomStorage</Type>
}

}
