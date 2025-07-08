/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%cspBuild, %syINET)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// This is a wrapper class used by Studio to manipulate routines.
Class %Library.RoutineMgr Extends %RegisteredObject [ System = 2 ]
{

Parameter SQLPUBLICSECURITY = "{""RoutineMgr_DocumentTypes"":""E"",""RoutineMgr_StudioOpenDialog"":""Requires:%Development:USE"",""RoutineMgr_ImportItemList"":""Requires:%Development:USE""}";

/// The name of the routine associated with this object.
Property Name As %String;

/// The timestamp of the routine associated with this object.
Property TimeStamp As %TimeStamp [ Calculated ];

/// True is this is a CSP/CSR file, else false.
Property IsCSP As %Boolean [ Calculated ];

Method IsCSPGet() As %Boolean [ CodeMode = expression ]
{
..Code.%IsA("%CSP.Routine")
}

/// Return the namespace this routine/csp file exists in. Mainly used for CSP file for the Studio.
Property Namespace As %String [ Calculated ];

/// Deprecated
Property Protected As %Boolean [ Deprecated, InitialExpression = 0 ];

Method NamespaceGet() As %String [ CodeMode = expression ]
{
..Code.Namespace
}

Property Generated As %Boolean [ Calculated ];

Method GeneratedGet() As %Boolean
{
	Set generated=##class(%Studio.SourceControl.Interface).IsGenerated(..Name)
	If generated'="" Quit generated
	Quit ..Code.Generated
}

Property UpToDate As %Boolean [ Calculated ];

Method UpToDateGet() As %Boolean
{
	Quit ..Code.UpToDate
}

/// A stream (<class>%Routine</class> or <class>%CSP.Routine</class>) containing the routine 
/// associated with this object.
Property Code As %Routine;

Method %OnNew(name As %String = "") As %Status [ Private ]
{
	Set name=..NormalizeName(name)
	Set i%Name=name
	
	#; Construct the correct stream class and store this
		
	If ..IsCSPName(name) {
		Set rtn=##class(%CSP.Routine).%New(name)
		If rtn="" Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$CSPPageDoesNotExist,name))
	} ElseIf ..UserType(name,.cls) {
		Set $ztrap="trap"
		Set rtn=$classmethod(cls,"%New",name)
	} Else {
		Set rtn=##class(%Routine).%New(name)
	}
	If rtn="" Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$RoutineDoesNotExist,name))
	Set r%Code=rtn,i%Code=$$$NULLOID
	Quit $$$OK
trap Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Open an instance of <class>%RoutineMgr</class> for routine with name 
/// <var>id</var>.
ClassMethod %OpenId(id As %String, concurrency As %Integer = 0) As %String
{
	#; id is a routine name
	Set obj=..%New(id)
	If obj="" Quit ""
	
	Quit obj
}

/// Save the routine associated with this object.
/// Return <var>Refresh</var>=1 if the save has changed
/// the document so it should be refreshed in the client
Method %Save(Output Refresh As %Boolean) As %Status
{
	Set Refresh=0
	If (..Name="") Quit $$$ERROR($$$FileNameRequired)
	Quit ..Code.SaveStream(,.Refresh)
}

ClassMethod UserType(Name As %String, ByRef Class As %String, ByRef StudioType As %String, ByRef Schema As %String, ByRef StudioIcon As %Integer) As %Boolean
{
	Set ext=$zconvert($piece(Name,".",*),"U") If ext="" Quit 0
	Do StudioDocument^%SYS.cspServer2(.document)
	Set Class="",StudioType="",Schema=""
	For  Set Class=$order(document(Class)) Quit:Class=""||($data(document(Class,ext),data))
	If Class="" Quit 0
	Set StudioType=$list(data),Schema=$listget(data,3),StudioIcon=+$listget(data,4)
	Quit 1
}

/// Compile the routine associated with this object.
Method Compile(qspec As %String = "") As %Status
{
	Set sc=$$$qualifierParse("Compiler",qspec,.qstruct) q:$$$ISERR(sc) sc
	If $get(qspec)'["/checkuptodate=",$$$qualifierGetValue(qstruct,"checkuptodate")="all",$get(^%SYS("Studio","ForceCompile"),1)=1 Set sc=$$$qualifierAmend("Compiler",.qstruct,"/checkuptodate=expandedonly",.qstruct),qspec=qspec_" /checkuptodate=expandedonly" If $$$ISERR(sc) Quit sc
	Set display=$$$qualifierGetValue(qstruct,"displaylog")
	If $get(^||%Studio.Project)'="" {
		Set prj=##class(%Studio.Project).%OpenId(^||%Studio.Project)
		If $isobject(prj),prj.Defines'="" Set $$$qualifierGetValue(qstruct,"defines")=$zstrip(prj.Defines,"<>W")_$select($get($$$qualifierGetValue(qstruct,"defines"))="":"",1:","_$$$qualifierGetValue(qstruct,"defines"))
	}
	$$$InitISCName
	$$$InitErrorNums
	Set origlasterror=$get(%objlasterror)
	Set zh=$zh
	If display Write !,$$$FormatMessage(,"%Compiler",$select(qspec="":"CompileStartedNoQual",1:"CompileStarted"),,$zdt($horolog),qspec)
	Set sc=..Code.Compile(.qstruct)
	Quit $$reportCompile^%apiOBJ(sc,display,,,zh,$$$qualifierGetValue(qstruct,"displayerror"),origlasterror)
}

/// Get the on-disk timestamp for the routine associated with this object.
Method GetCurrentTimeStamp(ByRef compiletime As %TimeStamp, ByRef uptodate As %Boolean) As %TimeStamp
{
	Set name=..Name If name'["." Set name=name_".MAC"
	If name["/"||(name["\"),$translate($extract(name),"\","/")'="/" Set name="/"_name
	If name'["/" Set name=$piece(name,".",1,*-1)_"."_$zconvert($piece(name,".",*),"U")
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Do tmp.OnBeforeTimestamp(name)
	Quit ..TS(name,.compiletime,.uptodate)
}

Method TimeStampGet() As %TimeStamp [ CodeMode = expression ]
{
..Code.TimeStamp
}

/// Return the timestamp for this item.
/// Also returns two output parameters <var>compiletime</var> is the time when this item was compiled, or null if not compiled.
/// <var>uptodate</var> returns true if the named document is up to date with the compiled version, and false if the named
/// document has been modified but not compiled, or a compiled subitem has been modified.
ClassMethod TS(name As %String, Output compiletime As %TimeStamp, Output uptodate As %Boolean) As %TimeStamp
{
	Set version=+$piece(name,";",2),name=$piece(name,";")
	Set ext=$zconvert($piece(name,".",*),"l"),nm=$piece(name,".",1,*-1),ts="",compiletime="",uptodate=0
	If version'=0 {
		Set version=..ConvertVersion(nm,ext,version)
	}
	If ..IsCSPName(name) {
		If $translate($extract(name),"\","/")'="/" Set name="/"_name
		Set nm=$$GetFilename^%apiCSP(name)
		If nm'="" Set ts=$$$FileDateModified(nm)
		Set cls=$$CSPClassName^%apiCSP(name)
		If cls'="" {
			$$$comClassKeyGetLvar(compiletime,cls,$$$cCLASStimechanged)
			If $$$defClassKeyGet(cls,$$$cCLASSdeployed) {
				Set uptodate=1
			} Else {
				If compiletime'="" {
					Try {
						Set filetimestamp=$parameter(cls,"FileTimestamp")
					} Catch {
						Set filetimestamp=""
					}
					If filetimestamp=$$$FileDateModifiedUTC(nm,1) {
						If $$$defClassKeyGet(cls,$$$cCLASStimechanged)=$get($$$comClassKeyRaw(cls,$$$cCLASStimecreated)) {
							Set uptodate=1
						} Else {
							#; If timestamp does not match but hash of class has not changed then it is still up to date
							Set idx=$get(^rINDEXCLASS($zconvert(cls,"U")))
							Set hash=$listget(idx,13)
							If hash'="",hash=$$$comClassKeyGet(cls,$$$cCLASShash) Set uptodate=1
						}
						If uptodate {
							Set rtn=""
							For {
								Set rtn=$$$comClassArrayNext(cls,$$$cCLASSroutines,rtn) Quit:rtn=""
								Set time=$$$comClassArrayGet(cls,$$$cCLASSroutines,rtn)
								If time'="",time'=$get(^rOBJ(rtn,"INT"),time) Set uptodate=0 Quit
							}
						}
					}
				}
			}
		} Else {
			Set uptodate=1
		}
	} Else {		
		If $zstrip(nm,"<>W")="" Quit ""
		If $$$rtnIsMAC(ext) {
			Set macts=$get(^rMAC(nm,0))
			Set ts=$select(version=0:macts,1:$get(^rMACSAVE(nm,version)))
			If $data(^rOBJ(nm))#2 { Set compiletime=$zutil(99,0,$ZLA(^rOBJ(nm),5)) }
			If $data(^rOBJ(nm,"MAC"),objts)#2=1 {
				If objts=macts Set uptodate=1
			}
			If 'uptodate,$get(^ROUTINE(nm,"MAC"),"undef")=macts {
				Set objts=$get(^rOBJ(nm,"INT"))
				If objts=""||(objts=$get(^ROUTINE(nm,0))),$data(^rOBJ(nm)) {
					Set uptodate=1
				}
			}
		} ElseIf $$$rtnIsINT(ext) {
			If version=0 {
				Set ts=$get(^ROUTINE(nm,0))
				Set objts=$get(^rOBJ(nm,"INT"))
				If objts=""||(ts=objts),$data(^rOBJ(nm)) Set uptodate=1
			} Else {
				Set ts=$get(^rBACKUP(nm,$zconvert(ext,"U"),version,0))
				If ts="" {
					Set ts=$get(^rBACKUP(nm,$zconvert(ext,"U"),version))
					Try {
						If ts'="",$ascii(ts)<48 Set ts=$listget(ts) If ts'="" Set ts=$zdth(ts,3)
					} Catch {}
				}
			}
			If $data(^rOBJ(nm))#2 { Set compiletime=$zutil(99,0,$ZLA(^rOBJ(nm),5)) }
			If ext="py" Set uptodate=1  ; Python files are always up to date and there is no compile needed
		} ElseIf $$$rtnIsINC(ext) {
			Set ts=$select(version=0:$get(^rINC(nm,0)),1:$get(^rINCSAVE(nm,version))),compiletime=ts,uptodate=1
		} ElseIf ext="cls" {
			Set ts=$$$defClassKeyGet(nm,$$$cCLASStimechanged)
			If ts="" Set ts=$$CheckClassTS^%SYS.cspServer2(nm)
			Set compiletime=$get($$$comClassKeyRaw(nm,$$$cCLASStimechanged))
			If $$$defClassKeyGet(nm,$$$cCLASSdeployed) {
				Set uptodate=1
			} Else {
				If ts=$get($$$comClassKeyRaw(nm,$$$cCLASStimecreated),"undef") {
					Set uptodate=1
				} Else {
					#; If timestamp does not match but hash of class has not changed then it is still up to date
					Set idx=$get(^rINDEXCLASS($zconvert(nm,"U")))
					Set hash=$listget(idx,13)
					If hash'="",hash=$$$comClassKeyGet(nm,$$$cCLASShash) Set uptodate=1
				}
			
				If uptodate {
					Set uptodate=1
					Set rtn=""
					For {
						Set rtn=$$$comClassArrayNext(nm,$$$cCLASSroutines,rtn) Quit:rtn=""
						Set time=$$$comClassArrayGet(nm,$$$cCLASSroutines,rtn)
						If time'="",time'=$get(^rOBJ(rtn,"INT"),time) Set uptodate=0 Quit
					}
				}
			}
		} ElseIf ext="prj" {
			Set compiletime=$get(^oddPROJECT(nm)),uptodate=1
			Quit $listget($get(^oddPROJECT(nm)))
		} ElseIf ext="gbl" {
			Set ts=$horolog,uptodate=1
		} ElseIf ..UserType(name,.cls) {
			Set ts=$classmethod(cls,"TimeStamp",nm_"."_$zconvert(ext,"U"))
			Set compiletime=$classmethod(cls,"CompileTime",nm_"."_$zconvert(ext,"U"))
			Set uptodate=$classmethod(cls,"IsUpToDate",nm_"."_$zconvert(ext,"U"))
			Quit ts
		}
	}
	Try {
		If ts'="" Set ts=$$$TimeToODBC(ts)
		If compiletime'="" Set compiletime=$$$TimeToODBC(compiletime)
	} Catch {
		Set ts=""
	}
	Quit ts
}

Method NameSet(name As %String) As %Status
{
	Set name=..NormalizeName(name)
	If name=i%Name Quit $$$OK
	#; when we set Name, set the stream name as well
	If ..IsCSPName(name) {
		#; Copy from the old stream to this new stream and replace with this
		Set tmp=##class(%CSP.Routine).%New(name)
		If tmp=$$$NULLOREF Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$UnableToCreateRoutine,name))
		If ..Code.Locked {
			Set ok=tmp.Lock()
			If $$$ISERR(ok) Quit ok
			Set tmp.Locked=..Code.Locked
		}
		Do tmp.CopyFrom(..Code)
		Set r%Code=tmp,i%Code=$$$NULLOID
	} ElseIf ..UserType(name,.cls) {
		Set $ztrap="trap"
		If $classname(..Code)=cls {
			Set sc=..Code.SaveAs(name)
			If $$$ISERR(sc) Quit sc
		} Else {
			Set tmp=$classmethod(cls,"%New",name)
			If tmp=$$$NULLOREF Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$UnableToCreateRoutine,name))
			If ..Code.Locked {
				Set ok=tmp.Lock()
				If $$$ISERR(ok) Quit ok
				Set tmp.Locked=..Code.Locked
			}
			#; Ignore any existing code under this name
			Do tmp.Rewind()
			Do tmp.CopyFrom(..Code)
			Set r%Code=tmp,i%Code=$$$NULLOID
		}
	} Else {
		If name'["." Set name=name_".MAC"
		Set rt=$zconvert($piece(name,".",*),"U")
		If '$$$rtnIsKnown(rt) Quit $$$ERROR($$$FileNameInvalid,name)
		If ##class(%Routine).CheckProtect(name) Quit $$$ERROR($$$RoutineProtect,name)
		If '..IsCSPName(i%Name) {
			Set ok=..Code.RoutineNameSet(name)
			If $$$ISERR(ok) Quit ok
		} Else {
			#; Copy from the old stream to this new stream and replace with this
			Set tmp=##class(%Routine).%New(name)
			If tmp=$$$NULLOREF Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$UnableToCreateRoutine,name))
			If ..Code.Locked {
				Set ok=tmp.Lock()
				If $$$ISERR(ok) Quit ok
				Set tmp.Locked=..Code.Locked
			}
			Do tmp.CopyFrom(..Code) Set tmp.LanguageMode=..Code.LanguageMode
			Set r%Code=tmp,i%Code=$$$NULLOID
		}
	}
	Set i%Name=name
	Quit $$$OK
trap	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

Method LanguageModeGet() As %Integer
{
	If ..Code.%IsA("%Library.Routine") Quit ..Code.LanguageMode
	If ..Code.%IsA("%MV.StudioRoutines") Quit 11
	Quit 0
}

Method LanguageModeSet(languagemode As %Integer) As %Status
{
	If ..Code.%IsA("%Library.Routine") Set ..Code.LanguageMode=languagemode
	Quit $$$OK
}

/// Return true if this classname is a generated class, and false otherwise
ClassMethod IsClassGenerated(classname As %String) As %Boolean
{
	If classname="" Quit 0
	Set generated=##class(%Studio.SourceControl.Interface).IsGenerated(classname_".CLS")
	If generated'="" Quit generated
	Quit +$listget($get(^rINDEXCLASS($zconvert(classname,"U"))),10,0)
}

/// Return true if this document is generated and false otherwise
ClassMethod IsGenerated(name As %String) As %Boolean
{
	Set name=..NormalizeName(name),nm=$piece(name,".",1,*-1)
	If nm="" Quit 0
	Set generated=##class(%Studio.SourceControl.Interface).IsGenerated(name)
	If generated'="" Quit generated
	Set ext=$zconvert($piece(name,".",*),"U")
	If ..IsCSPName(name) {
		Quit 0
	} ElseIf ext="CLS" {
		Quit +$listget($get(^rINDEXCLASS($zconvert(nm,"U"))),10,0)
	} ElseIf $$$rtnIsMAC(ext) {
		Quit +$get(^rMAC(nm,0,"GENERATED"))
	} ElseIf $$$rtnIsINT(ext) {
		Quit +$get(^ROUTINE(nm,0,"GENERATED"))
	} ElseIf $$$rtnIsINC(ext) {
		Quit +$get(^rINC(nm,0,"GENERATED"))
	} ElseIf ext="PRJ" {
		Quit 0
	} ElseIf ..UserType(name,.cls) {
		Quit +$classmethod(cls,"IsGenerated",name)
	} 
	Quit 0
}

/// Returns true if this item is server only
ClassMethod IsServerOnly(name As %String) As %Boolean [ Internal ]
{
	Set ext=$zconvert($piece(name,".",*),"U")
	If ext'="CLS" { quit "" }	
	Set classname = $extract(name,1,*-4)
	Set res = $$$comClassKeyGet(classname,$$$cCLASSserveronly)
	if (res = "") { Set res = 0 }
	q res
}

/// Return true if this item is mapped from a database other than the default routine database.
/// Also return the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	Set name=..NormalizeName(name),nm=$piece(name,".",1,*-1)
	Set sourcedb=$namespace
	If nm="" Quit 0
	Set ext=$zconvert($piece(name,".",*),"U")
	If ..IsCSPName(name) {
		Quit 0
	} ElseIf ..UserType(name,.cls) {
		Quit $classmethod(cls,"IsMapped",name,.sourcedb)
	} ElseIf $$$rtnIsMAC(ext) {
		Set sourcedb=$$$GBLDBREF("rMAC",nm)
		Quit sourcedb'=$$$GBLDBREF("rMAC")
	} ElseIf $$$rtnIsINT(ext) {
		Set sourcedb=$$$GBLDBREF("ROUTINE",nm)
		Quit sourcedb'=$$$GBLDBREF("ROUTINE")
	} ElseIf $$$rtnIsINC(ext) {
		Set sourcedb=$$$GBLDBREF("rINC",nm)
		Quit sourcedb'=$$$GBLDBREF("rINC")
	} ElseIf ext="CLS" {
		Set sourcedb=$$$GBLDBREF("oddDEF",nm)
		Quit sourcedb'=$$$GBLDBREF("oddDEF")
	} ElseIf ext="PRJ" {
		Quit 0
	}
	Quit 0
}

/// Delete the routine <var>name</var>.
ClassMethod Delete(name As %String) As %Status
{
	Set name=..NormalizeName(name)
	If name["/"||(name["\"),$translate($extract(name),"\","/")'="/" Set name="/"_name
	Set ext=$piece(name,".",*)
	If ext="CLS" {
		Set sc=$$Delete^%apiOBJ($piece(name,".",1,*-1))
	} Else {
		If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
		. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeDelete(name)
		If ..UserType(name,.cls) {
			Set $ztrap="trap"
			Set sc=$classmethod(cls,"Delete",name)
		} ElseIf ..IsCSPName(name) {
			Set sc=##class(%CSP.Routine).Delete(name)
		} Else {
			Set sc=##class(%Routine).Delete(name)
		}
		If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
		. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterDelete(name)
	}
	If $$$ISOK(sc) Do ##class(%Studio.Project).DeleteItem(name)
	Quit sc
trap	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Used by Studio because it is hard to call %Studio.TemplateMgr directly
ClassMethod UpdateTemplates(qspec As %String) As %Status [ CodeMode = expression ]
{
##class(%CSP.StudioTemplateMgr).UpdateTemplates(.qspec)
}

/// Used by Studio to avoid calling %SQL.
ClassMethod CheckSQLIdentifier(ByRef ident As %String) As %Status [ CodeMode = expression ]
{
##class(%SQL.Manager.API).CheckIdentifier(.ident,1)
}

/// Return the port the InterSystems IRIS web server is running on or 0 if the
/// web server is not active. Also returns the server name which is useful if the web server
/// is running on a different machine. It can also
/// return a <var>urlprefix</var> which is added to the url to goto at the start and is required
/// if one web server is serving multiple InterSystems IRIS instances to differential between these versions.
/// It also returns <var>url</var> which is the constructed
/// url as a string, you just need to append the page you are going to request to this.
ClassMethod GetWebServerPort(ByRef port As %Integer, ByRef server As %String, ByRef urlprefix As %String, ByRef url As %String) As %Status [ Internal ]
{
	Quit ##class(%Studio.General).GetWebServerPort(.port,.server,.urlprefix,.url)
}

/// Try to return the current servers IP address/name
ClassMethod ServerIP() As %String [ Internal, Private ]
{
	Quit ##class(%Studio.General).ServerIP()
}

/// Return true if this is item is a file under a CSP application
ClassMethod IsCSPName(name As %String) As %Boolean
{
	Quit $$IsCSPName^%occXMLExport(name)
}

/// Lock this routine, return true if it worked and false if it did not.
Method Lock() As %Status
{
	#; This source control code is also in CheckSourceControlEdit() of %Api.Atelier.v1 and v2.
	#; Any changes here should go there also.
	If $isobject($get(%SourceControl)) Do  Quit:$$$ISERR(sc) sc
	. Set edit=0,isinsourcecontrol=0,ischeckedout=0,user="",name=##class(%Studio.SourceControl.Interface).normalizeName(..Name)
	. Set tmp=%SourceControl New %SourceControl
	. If tmp.IsReadOnly(name) Set sc=$$$ERROR($$$RoutineSourceRO,name) Quit
	. Set sc=tmp.GetStatus(name,.isinsourcecontrol,.edit,.ischeckedout,.user)
	. If $$$ISOK(sc),'edit Set sc=..ConstructEditError(name,isinsourcecontrol,ischeckedout,user)
	Quit ..Code.Lock()
}

/// Unlock this routine, return a status code.
Method Unlock() As %Status [ CodeMode = expression ]
{
..Code.Unlock()
}

/// Internal method to construct the correct error code if the item is not editable because
/// of source control hooks
ClassMethod ConstructEditError(name As %String, isinsourcecontrol As %Boolean, ischeckedout As %Boolean, user As %String) As %Status
{
	Set msg=""
	If $get(user)'="" Set msg=$$$FormatMessage(,"%Studio","UserEditing",,user)
	Quit $select($get(isinsourcecontrol):$$$ERROR($$$ItemNotCheckedOut,name,msg),1:$$$ERROR($$$ItemNotEditable,name,msg))
}

/// Internal method to construct a CSP session with current security permissions and return the session id
ClassMethod ConstructCSPSession() As %String [ CodeMode = expression, Internal ]
{
$$CreateTemplateSession^%SYS.cspServer2()
}

/// Deprecated internal method to return the CSP session id of the session constructed with <method>ConstructCSPSession</method>.
/// This is no longer needed as <method>ConstructCSPSession</method> returns the CSP sessionId directly now.
ClassMethod ReturnCSPSessionId(id As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
id
}

/// Return a list of the user document types that are defined
Query DocumentTypes() As %Query(ROWSPEC = "Extention:%String,Type:%String,Description:%String(MAXLEN=256),XMLNamespace:%String(MAXLEN=512),Icon:%Integer,AddNew:%Boolean") [ SqlProc ]
{
}

ClassMethod DocumentTypesExecute(ByRef QHandle As %Binary) As %Status
{
	Set QHandle=""
	Set cls=""
	Do StudioDocument^%SYS.cspServer2(.document)
	For  {
		Set cls=$order(document(cls)) Quit:cls=""
		Set ext=""
		For  {
			Set ext=$order(document(cls,ext),1,data) Quit:ext=""
			Set QHandle=QHandle_$listbuild($listbuild($zconvert(ext,"l"),$list(data),$list(data,2),$listget(data,3),+$listget(data,4),+$listget(data,5)))
		}
	}
	Set QHandle=$listbuild(0,QHandle)
	Quit $$$OK
}

ClassMethod DocumentTypesClose(ByRef QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod DocumentTypesFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	Set list=$listget(QHandle,2),index=$listget(QHandle)
	Set index=index+1
	Set $list(QHandle)=index
	If $listlength(list)<index Set AtEnd=1 Quit $$$OK
	Set Row=$list(list,index)
	Quit $$$OK
}

/// Return a list of namespaces on this system
Query NamespaceList() As %Query(ROWSPEC = "Namespace:%String") [ SqlProc ]
{
}

ClassMethod NamespaceListExecute(ByRef QHandle As %Binary) As %Status
{
	If '$system.Security.Check("%Development","USE") Quit $$$ERROR($$$SecurityNotDeveloper)
	Quit ##class(%SYS.Namespace).ListExecute(.QHandle,1,1)
}

ClassMethod NamespaceListClose(QHandle As %Binary) As %Status
{
	Quit ##class(%SYS.Namespace).ListClose(.QHandle)
}

ClassMethod NamespaceListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
start	Set sc=##class(%SYS.Namespace).ListFetch(.QHandle,.Row,.AtEnd)
	If Row="" Quit sc
	If $listget(Row,2)=0 {
		If AtEnd Set Row="" Quit sc
		Goto start
	}
	Set Row=$listbuild($list(Row))
	Quit sc
}

/// Given a comma separated list of <var>filename</var> this will return
/// a list of the items that are in these filenames. Along with the name
/// of each item it will also return the timestamp of the item if it is
/// present in InterSystems IRIS already, and -1 if the item is not present. This allows
/// you to decide if you wish to import this item and overwrite the existing
/// item in InterSystems IRIS.
Query ImportItemList(filename As %String(MAXLEN=512), charset As %String) As %Query(ROWSPEC = "Name:%String(MAXLEN=256),Modified:%TimeStamp") [ SqlProc ]
{
}

ClassMethod ImportItemListExecute(ByRef QHandle As %Binary, filename As %String(MAXLEN=512) = "", charset As %String = "", ByRef description As %String) As %Status
{
	Set sc=$$Load^%apiOBJ(filename,"-l-d-c-i",,.imported,1,,,,charset,.description)
	If $$$ISERR(sc) Set QHandle="" Quit sc
	Merge QHandle=imported
	Quit $$$OK
}

ClassMethod ImportItemListClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ImportItemListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ CodeMode = expression ]
{
..ImportItemListFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// Returns the next <var>FetchCount</var> rows in the query.
ClassMethod ImportItemListFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	New %SourceControl
	Set RowSet=""
	If $data(QHandle)\10=0 Set AtEnd=1 Quit $$$OK
	If +$get(FetchCount)=0 Set FetchCount=32000
	Set name=$order(QHandle(""))
	For no=1:1:FetchCount {
		If name="" Quit
		Set RowSet=RowSet_$listbuild(name,..GetDate(name))
		Kill QHandle(name)
		If $length(RowSet)>30000 Set FetchCount=no Quit
		Set name=$order(QHandle(name))
	}
	Set ReturnCount=FetchCount
	Set AtEnd=($data(QHandle)\10=0)
	Quit $$$OK
}

/// Return true if the routine/csp/class/project/global/object code exists and false otherwise.
ClassMethod Exists(name As %String) As %Boolean
{
	Set version=$piece(name,";",2,*),rtn=$piece(name,";")
	If $zstrip(rtn,"<>W")="" Quit 0
	If rtn'["." Set rtn=rtn_".MAC"
    Set ext=$zconvert($piece(rtn,".",*),"l")
	If name["/"||(name["\")||(ext="dir"),$translate($extract(name),"\","/")'="/" Set name="/"_name
	If name'["/" Set name=$piece(name,".",1,*-1)_"."_$zconvert($piece(name,".",*),"U")
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Do tmp.OnBeforeTimestamp(name)
	If ext="dir" {
		Set name=$piece(name,".",1,*-1)
		If $extract(name,*)'="/" Set name=name_"/"
		Set dir=$$GetFilename^%apiCSP(name)
		If dir="" Quit 0
		Quit ##class(%File).DirectoryExists(dir)
	} ElseIf ..IsCSPName(name) {
		If $translate($extract(name),"\","/")'="/" Set name="/"_name
		Quit ##class(%CSP.Routine).Exists(name)
	} ElseIf ..UserType(name,.cls) {
		Quit $classmethod(cls,"Exists",$piece(name,".",1,*-1)_"."_$zconvert(ext,"U"))
	} ElseIf (ext="cls")||(ext="%rule") {
		Set rtn=$piece(rtn,".",1,*-1)
		Set rtn=$$$NormalizeClassname(rtn)
		If version'="" Quit ''$data(^rBACKUP(rtn,"CLS",..ConvertVersion(rtn,"CLS",version)))
		If '##class(%Dictionary.ClassDefinition).%ExistsId(rtn) Quit 0
		If ext="%rule" {
		    If $get($$$comClassKeyRaw(rtn,$$$cCLASSsuper))'["Ens.Rule.Definition" Quit 0
		}
		Quit 1
	} ElseIf ext="gbl" {
		Set rtn=$piece(rtn,".",1,*-1)
		If $extract(rtn)'="^" Set rtn="^"_rtn
		Set $ztrap="exitExists"
		Quit ''$data(@rtn)
	} ElseIf ext="prj" {
		Quit ##class(%Studio.Project).%ExistsId($piece(rtn,".",1,*-1))
	} ElseIf ext="pkg" {
		Set cls=$piece(name,".",1,*-1)
		If ##class(%Studio.Package).Exists(cls) Quit 1
		Set tmp=$order(^rINDEXCLASS($zconvert(cls,"U")_"."),1,data)
		If tmp=""||($get(data)="") Quit 0
		If $extract($list(data,2),1,$length(cls)+1)=(cls_".") Quit 1
		Quit 0
	} Else {
		Quit ##class(%Routine).Exists(name)
	}
exitExists	Quit 0
}

/// Get or release a lock on a document.
///  If <parameter>lock</parameter> is true (the default) then it will be locked else it will be unlocked.
ClassMethod LockItem(name As %String, lock As %Boolean = 1, checksource As %Boolean = 1) As %Status
{
	Set version=$piece(name,";",2,*),rtn=$piece(name,";")
	If rtn'["." Set rtn=rtn_".mac"
	Set ext=$zconvert($piece(rtn,".",*),"l")
	If ..IsCSPName(name) {
		If $translate($extract(name),"\","/")'="/" Set name="/"_name
		Quit ##class(%CSP.Routine).LockRoutine(name,lock)
	} ElseIf ..UserType(name,.cls) {
		Try {
			Return $classmethod(cls,$select(lock:"LockName",1:"UnlockName"),name)
		} Catch {
			Return $$$ERROR($$$ObjectScriptError,$zerror)
		}
	} ElseIf ext="cls" {
		Set rtn=$piece(rtn,".",1,*-1)
		Set rtn=$$$NormalizeClassname(rtn)
		If lock {
			Quit $$ChkClass^%qccServer(rtn,1,checksource)
		} Else {
			Do UnlockClass^%qccServer(rtn)
			Quit $$$OK
		}
	} ElseIf ext="prj" {
		Quit ##class(%Studio.Project).LockItem($piece(rtn,".",1,*-1),lock)
	} ElseIf ext="pkg" {
		Quit ##class(%Studio.Package).LockItem($piece(rtn,".",1,*-1),lock)
	} Else {
		Quit ##class(%Routine).LockRoutine(name,lock)
	}
}

/// Internal function to return absolute version number
ClassMethod ConvertVersion(name, type, version) As %String
{
	If version'<0 Quit version
	Set ver=""
	If $$$rtnIsMAC(type) {
		For i=1:1:-version Set ver=$order(^rMACSAVE(name,ver),-1) Quit:ver=""
	} ElseIf $$$rtnIsINC(type) {
		For i=1:1:-version Set ver=$order(^rINCSAVE(name,ver),-1) Quit:ver=""
	} Else {
		For i=1:1:-version Set ver=$order(^rBACKUP(name,type,ver),-1) Quit:ver=""
	}
	If ver="" Quit 0
	Quit ver
}

/// Return the timestamp of this routine/csp/class/project/global/object code if it exists
/// or -1 if it does not exist
ClassMethod GetDate(name As %String) As %TimeStamp [ CodeMode = expression ]
{
$select(..Exists(name):..TS(name),1:-1)
}

/// Given a routine name return the name including extension that is most suitable for
/// Studio to open
ClassMethod BestRoutineMatch(name As %String) As %String
{
	Do StudioDocument^%SYS.cspServer2(.document)
	Set cls="",found=""
	For {
		Set cls=$order(document(cls)) Quit:cls=""
		Set ext=""
		For {
			Set ext=$order(document(cls,ext)) Quit:ext=""
			Try {
				If $classmethod(cls,"Exists",name_"."_$zconvert(ext,"U")) Set found=name_"."_ext
			} Catch {}
			If found'="" Quit
		}
		If found'="" Quit
	}
	If found'="" Quit found
	For type="MAC","INT","MVB","BAS","PY" {
		If ..Exists(name_"."_type) Set found=name_"."_$zconvert(type,"l") Quit
	}
	Quit found
}

/// For a given source item, this function returns the source item(s) generated
/// from it or from which it was generated (depending on the 'direction' flag).
/// <ul>
/// <li><b>name</b> - string containing name of source item. For example: "Test" or
/// "Sample.Person" There is NO ".MAC" etc in this name.</li>
/// <li><b>type</b> -  string containing type of source item: This can be one of:
/// "INT","MAC","BAS","MVB","MVI","CLS","CSP","CSR","PY"</li>
/// <li><b>direction</b> - direction flag: +1 will go in the direction that files are
/// compiled in, for example MAC to INT or CLS to MAC, -1 will go in the opposite
/// direction, INT to MAC, MAC to CLS etc.</li>
/// </ul>
/// Returns comma-delimited list of source names (including type string appended to the
/// end) or "" if there is no corresponding other. Example:
/// <ul>
/// <li>("Test","INT",-1)  --> "Test.MAC"</li>
/// <li>("Test","MAC",1)  --> "Test.INT"</li>
/// <li>("Sample.Person","CLS",1)  -->  "Sample.Person.1.MAC,Sample.Person.2.MAC"</li>
/// <li>("/csp/samples/menu","CSP",1)  -->  "csp.menu.CLS"</li>
/// <li>("Sample.Person.1","MAC",-1)  -->  "Sample.Person.CLS"</li>
/// </ul><p>
/// Note that for classes the routines shown do not include the method generator routines.<p>
/// The <var>label</var> is of the form 'label+offset', if included then this will return the
/// routine name followed by a ':' and then the offset corresponding to this position
ClassMethod GetOther(name As %String, type As %String, direction As %Integer = 1, label As %String) As %String
{
	If name="" Quit ""
	Set type=$ZConvert(type,"U")
	If type="CSP"||(type="CSR") {
		Set name=$select($extract(name)="/":name,1:"/"_name)
		If type="CSP",$ZConvert($Piece(name,".",*),"l")'="csp" Set name=name_".csp"
		If type="CSR",$ZConvert($Piece(name,".",*),"l")'="csr" Set name=name_".csr"
	}
	#; Handle user defined document types first
	Do StudioDocument^%SYS.cspServer2(.document)
	Set class="",others=""
	For  {
		Set class=$order(document(class)) Quit:class=""
		Set tmp=$classmethod(class,$select(direction=1:"GetOther",1:"GetPrevious"),name_"."_type)
		If tmp'="" Set others=others_tmp_","
	}
	Set others=others_..builtInGetOther(.name,.type,.direction)
	Set others=$zstrip(others,">",",")
	If $get(label)'="" {
		Set lbl=""
		Set sc=##class(%Studio.Debugger).INTLine(name_"."_type,$piece(label,"+"),+$piece(label,"+",2),.intname,.intline,.returntype)
		If $$$ISERR(sc) Quit ""
		If intname'="" {
			Set lbl="+"_intline
		} Else {
			If $$$rtnIsMAC(type) {
				Set intname=name
				If $piece(label,"+")'="" {
					Set lbl=$piece(label,"+")
					For i=1:1:$get(^ROUTINE(name,0,0)) If $piece($piece($piece(^(i),$c(9))," "),"(")=lbl Set lbl="+"_(i+$piece(label,"+",2)) Quit
					If lbl'["+" Set lbl=""
				} Else {
					Set lbl=label
				}
			}
		}
		If lbl="" {
			If type="CLS",label'="",label'["+" {
				Set lbl=$get($$$comMemberKeyRaw(name,$$$cCLASSmethod,label,$$$cMETHrtnlabel)),tag="",rtn=""
				Do gettagrtn^%occDescriptor(name,label,lbl,.tag,.rtn)
				If rtn="" Quit ""
				If $data(^ROUTINE(rtn,0)) Quit rtn_"."_$$$rtnLangINT($get(^ROUTINE(rtn,"LANG")))_":"_tag
			}
			Quit ""
		}
		Set mapped(intname_"."_$zconvert($$$rtnLangINT($get(^ROUTINE(intname,"LANG"))),"U"))=","_$piece(lbl,"+",2)
		Set sc=##class(%Studio.Debugger).MappedFromLine(intname,$piece(lbl,"+",2),,.mapping)
		For i=1:1:$length(mapping," ") {
			Set item=$piece(mapping," ",i) If item="" Continue
			Set name=$piece(item,","),type=$zconvert($piece(name,".",*),"U")
			Set mapped($piece(name,".",1,*-1)_"."_type)=$piece(item,",",2,32767)
		}
		If $$$ISERR(sc) Quit ""
		Set output=""
		For i=1:1:$length(others,",") {
			Set item=$piece(others,",",i) If item="" Continue
			Set item=$piece(item,".",1,*-1)_"."_$zconvert($piece(item,".",*),"U")
			If $data(mapped(item)) {
				Set offset=$translate(mapped(item),",","+"),type=$piece(item,".",*)
				Set output=item_":"_offset
				Quit
			}
		}
		If $piece(output,"+",2)="0" Set output=$piece(output,"+")
		Quit output
	}
	Quit others
}

ClassMethod builtInGetOther(name As %String, type As %String, direction As %Integer = 1) As %String [ Internal, Private ]
{
	If direction = 1 {
		#; Now handle built in document types
		If $$$rtnIsINT(type) {
			Set idxentry=$get(^rINDEX(name,type))
			#; If this is a generated INT file look at what generated it, does it look like part of a class?
			If $listget(idxentry,3),$Length(name,".")>1,$Piece(name,".",*)?.1(1"T",1"G").N {
				Set class=$Piece(name,".",1,*-1)
				If $$$comClassArrayDefined(class,$$$cCLASSroutines,name) {
					#; Check if this is a CSP or CSR file, else it is just a class
					If $$$comMemberKeyGet(class,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)'="" {
						Quit $$$comMemberKeyGet(class,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)
					} Else {
						Quit class_$select(##class(%RoutineMgr).Exists(class_".BPL"):".BPL",##class(%RoutineMgr).Exists(class_".DTL"):".DTL",1:".CLS")
					}
				}
			}
			If $Data(^rINDEX(name,"MAC")) Quit name_"."_$$$rtnLangMAC($get(^rMAC(name,0,"LANG")))
			Quit ""
		} ElseIf $$$rtnIsMAC(type) {
			If $data(^ROUTINE(name,0)) Quit name_"."_$$$rtnLangINT($get(^ROUTINE(name,"LANG")))
			Quit ""
		} ElseIf type = "CLS" {
			Quit ..getRoutinesFromClass(name,0)
		} ElseIf type = "CSP" {
			Set item=$$CSPClassName^%apiCSP(name,"")
			Quit $Select(item="":"",$Data(^rINDEXCLASS($ZCVT(item,"U"))):item_".CLS",1:"")
		} ElseIf type = "CSR" {
			Quit ..getClassesFromCSR(name)
		}
	} ElseIf direction = -1 {
		If $$$rtnIsINT(type) {
			If $data(^rMAC(name,0)) Quit name_"."_$$$rtnLangMAC($get(^rMAC(name,0,"LANG")))
			Set idxentry=$get(^rINDEX(name,type))
			#; If this is a generated INT file look at what generated it, does it look like part of a class?
			If $listget(idxentry,3),$Length(name,".")>1,$Piece(name,".",*)?.1(1"T",1"G").N {
				Set class=$Piece(name,".",1,*-1)
				If $$$comClassArrayDefined(class,$$$cCLASSroutines,name) Quit class_".CLS"
			}
			Quit ""
		} ElseIf $$$rtnIsMAC(type) {
			If $data(^ROUTINE(name,0)) Quit name_"."_$$$rtnLangINT($get(^ROUTINE(name,"LANG")))
			Quit ""
		} ElseIf type = "CLS" {
			If $$$comMemberKeyGet(name,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)'="" Quit $$$comMemberKeyGet(name,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)
			If ##class(%RoutineMgr).Exists(name_".BPL") Quit name_".BPL"
			If ##class(%RoutineMgr).Exists(name_".DTL") Quit name_".DTL"
			Quit ..getRoutinesFromClass(name,1)
		} ElseIf type = "CSP" {
			Set class=$$CSPClassName^%apiCSP(name,"")
			Quit ..getRoutinesFromClass(class,1)
		}
	}
	Quit ""
}

ClassMethod getClassesFromCSR(name As %String) As %String [ Internal, Private ]
{
	Set name=$$$NormalizeFilename(name)
	Set name=$piece(name,"/",*) ; match on name part only
	Set items=""
	Do ..getClassesFromCSRType(name,$$$sruleClassPrefix,.items)
	Do ..getClassesFromCSRType(name,$$$uruleClassPrefix,.items)
	Quit $Extract(items,2,*)
}

ClassMethod getClassesFromCSRType(name As %String, prefix As %String, ByRef items As %String) [ Internal, Private ]
{
	Set prefix=$zcvt(prefix,"U")
	Set classkey=$order(^rINDEXCLASS(prefix),1,data)
	While $extract(classkey,1,$length(prefix))=prefix {
		Set class=$list(data,2)
		Set file=$$$NormalizeFilename($$$defMemberKeyGet(class,$$$cCLASSparameter,"CSRURL",$$$cPARAMdefault))
		Set file=$piece(file,"/",*) ; match on name part only
		If file=name Set items=items_","_class_".CLS"
		Set classkey=$order(^rINDEXCLASS(classkey),1,data)
	}
	Quit
}

ClassMethod getRoutinesFromClass(class As %String, type As %Integer = 0) As %String
{
	Set rtn="",items=""
	For {
		Set rtn=$$$comClassArrayNext(class,$$$cCLASSroutines,rtn) Quit:rtn=""
		Set tmp=$select($case($zconvert($extract(rtn,*-3,*),"l"),".mac":1,".int":1,:0):$extract(rtn,1,*-4),1:rtn)
		If $data(^ROUTINE(tmp,0)),$piece(tmp,".",*)'="0" Set items=tmp_"."_$$$rtnLangINT($get(^ROUTINE(tmp,"LANG")))_","_items
	}
	If type=0 {
		Set generated=""
		For {
			Set generated=$$$comClassArrayNext(class,$$$cCLASSclasses,generated) Quit:generated=""
			If $zconvert($piece(generated,".",*),"U")="CLS" {
				Set cls=$piece(generated,".",1,*-1) If cls="" Continue
				#; Do not show pseudo items
				If $$$defClassKeyGet(cls,$$$cCLASSdeployed)=2 Continue
			}
			Set name=##class(%Studio.SourceControl.Interface).normalizeName(generated)
			If $data(items(name)) Continue
			Set items(name)=""
			Set items=items_name_","
		}
	}
	Quit $Extract(items,1,*-1)
}

/// For internal use only
ClassMethod CompileClass(class As %String, qspec As %String, ByRef Reload As %Boolean) As %Status
{
	Set class=$piece(class,";"),Reload=0
	Set ts=..TS(class_".cls")
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	If $get(qspec)'["/checkuptodate=",$$$qualifierGetValue(qstruct,"checkuptodate")="all",$get(^%SYS("Studio","ForceCompile"),1)=1 Set sc=$$$qualifierAmend("Compiler",.qstruct,"/checkuptodate=expandedonly",.qstruct),qstruct=qstruct_" /checkuptodate=expandedonly" If $$$ISERR(sc) Quit sc
	If $get(^||%Studio.Project)'="" {
		Set prj=##class(%Studio.Project).%OpenId(^||%Studio.Project)
		If $isobject(prj),prj.Defines'="" Set $$$qualifierGetValue(qstruct,"defines")=$zstrip(prj.Defines,"<>W")_$select($get($$$qualifierGetValue(qstruct,"defines"))="":"",1:","_$$$qualifierGetValue(qstruct,"defines"))
	}
	Set rc=$$Compile^%apiOBJ(class,.qstruct)
	Set Reload=(ts'=..TS(class_".cls"))
	Quit rc
}

/// Internal method to determine if we should display a directory or not
ClassMethod showDir(location As %String, ByRef w As %String) As %Boolean [ Internal, Private ]
{
	Set spec=$list(w,2),systemfiles=$listget(w,5),notstudio=$listget(w,7),showgenerated=$listget(w,8),mapped=$listget(w,11)
	Set sc=..StudioOpenDialogExecute(.qHandle,location_"/"_spec,,5,systemfiles,-2,notstudio,showgenerated,,,mapped) If $$$ISERR(sc) $$$ThrowStatus(sc)
	Set sc=..StudioOpenDialogFetchRows(.qHandle,1,.Row,,.AtEnd) If $$$ISERR(sc) $$$ThrowStatus(sc)
	Set sc=..StudioOpenDialogClose(.qHandle) If $$$ISERR(sc) $$$ThrowStatus(sc)
	Set complete=$listget(Row)
	Quit complete'=""
}

/// Used to provide autocomplete in the open dialog, you pass in the <var>name</var> the user
/// has entered and the <var>mask</mask> which is the current pattern mask and it will return
/// null if it can not find a match or the next name that does match.
ClassMethod AutoComplete(name As %String(MAXLEN=512), mask As %String = "", ByRef complete As %String(MAXLEN=512), generated As %Boolean = 1, directory As %String = "", saveas As %Boolean = 0) As %Status
{
	Set spec="",complete="",origname=name
	If name["*"||(name="")||($length(name)>255) Quit $$$OK
	If directory'="" {
		Set directory=$translate(directory,"\","/")
		If directory["/",$extract(directory)'="/" Set directory="/"_directory
		If $extract(directory,*)'="/" Set directory=directory_"/"
	}
	If mask=""||(mask="*.*") {
		Set spec=name_"*"
	} Else {
		For i=1:1:$length(mask,",") {
			Set spec=spec_name_$zstrip($piece(mask,",",i),"<>W")_","
		}
		Set spec=$extract(spec,1,*-1)
	}
	Set spec=directory_spec
	Set sc=..StudioOpenDialogExecute(.qHandle,spec,,5,,-1,,generated) If $$$ISERR(sc) Quit sc
	Set sc=..StudioOpenDialogFetchRows(.qHandle,1,.Row,,.AtEnd) If $$$ISERR(sc) Quit sc
	Set sc=..StudioOpenDialogClose(.qHandle) If $$$ISERR(sc) Quit sc
	Set complete=$listget(Row)
	#; On the save as dialog only use the current directory to find matches
	If 'saveas {
		#; If no match at this level see if we can find a match at the root level
		If directory'="",complete="" {
			Set directory=""
			Set sc=..AutoComplete(name,mask,.complete,.generated) If $$$ISERR(sc) Quit sc
		} ElseIf mask=""||(mask["*.cls")||(mask["*.*")||(mask="*"),$length(name,".")<3,directory="",name'["/" {
			If $extract(name)="%" {
				Set newname="%Library."_$extract(name,2,*)
			} Else {
				Set newname="User."_name
			}
			Set sc=..AutoComplete(newname,mask,.alternative,.generated) If $$$ISERR(sc) Quit sc
			If alternative'="" {
				If $extract(name)="%" {
					Set alternative="%"_$piece(alternative,".",2,32767)
				} Else {
					Set alternative=$piece(alternative,".",2,32767)
				}
				If complete=""||(complete]alternative) {
					Set complete=alternative
				}
			}
		}
	}
	If complete="" Quit $$$OK
	If $extract(complete)="/",$extract(directory_name)'="/" Set complete=$extract(complete,2,*)
	Set complete=$extract(complete,$length(directory)+1,*)
	Set extra=$extract(complete,$length(name)+1,*)
	If $length(extra,".")>2 Set complete=$extract(complete,1,$length(name))_$piece(extra,".")_"."
	#; Check is this has gone wrong for any reason
	If $extract(complete,1,$length(origname))'=origname Set complete=""
	Quit $$$OK
}

/// This query is used by the Studio open dialog to provide a list of the types
/// that can be opened. It will list all the items that match the <var>Spec</var>
/// ordered by the <var>OrderBy</var>.
/// The <var>Dir</var> specifies the direction to search in, 1 is
/// in ascending order (the default) and -1 is in descending order.
/// <p><var>Spec</var> may contain both * and ? as wildcards. It may also 
/// consist of more than one, comma-delimited selections. If you wish to exclude items
/// then prefix the pattern with ' symbol.
/// <var>OrderBy</var> is one of:<ul>
/// <li>1 - Name of the file (the default), case insensitive</li>
/// <li>2 - Date/Time the file was saved</li>
/// <li>3 - Size of the file</li>
/// <li>4 - Type of the file ie. INT, MAC, INC, BAS, MVB</li>
/// <li>5 - Name of the file sorted case sensitively</li></ul>
/// The query returns the name of the item, a delimiter to use to constructing paths with
/// this item, if not specified it defaults to '.'. For example if the
/// delimiter is '.' and you put in the pattern 'package/*' then when you select this
/// a directory it should change the selection to 'package.newpackage/*'. Note that
/// it always assumes that there is a '/' after the directory before the pattern, so
/// for a CSP application where the delimiter returned is '/' if the spec was
/// '/csp/samples/*' and you click on a directory 'cinema' you should construct the
/// spec '/csp/samples/cinema/*'.
/// The type of the item which can be one of:<ul>
/// <li>0  - MAC file, a routine containing macros</li>
/// <li>1  - INT file, a standard routine</li>
/// <li>2  - INC file, an include file</li>
/// <li>3  - BAS file, a Cache Basic routine</li>
/// <li>4  - CLS, a class</li>
/// <li>5  - CSP, a Cache Server Page or another file in this directory</li>
/// <li>7  - GBL, a Global</li>
/// <li>8  - PRJ, a Project</li>
/// <li>9  - a Package</li>
/// <li>10 - a CSP application</li>
/// <li>11 - MVB file, a MultiValue Basic macro routine</li>
/// <li>12 - MVI file, a MultiValue Basic routine</li>
/// <li>13 - OBJ, object code</li>
/// </ul>Further numbers are reserved for future use.
/// It also returns the routine size and the date it was last saved.<p>
/// The <var>SystemFiles</var> is true the results will include '%' items and INFORMATION.SCHEMA items in the search. If false (the default), results will only include non-percent items and no INFORMATION.SCHEMA items. 
/// <br>If <var>Flat</var> is true then it does not display directories but displays everything at the root level. 
/// <br>If <var>NotStudio</var> is true then it will display globals and OBJ routines as well, for Studio we exclude these types. 
/// <br>The <var>ShowGenerated</var> controls if this query includes items that are generated from another item, such as INT code that is generated from a class compilation. 
/// <br>The <var>Filter</var> if specified allows additional restrictions on the items being returned by specifying the WHERE clause of an SQL statement on the
/// <class>%Studio.OpenDialogItems</class>, refer to this for a list of fields that can be referenced.
Query StudioOpenDialog(Spec As %String(MAXLEN=512), Dir As %Integer, OrderBy As %Integer, SystemFiles As %Boolean, Flat As %Boolean, NotStudio As %Boolean = 0, ShowGenerated As %Boolean = 1, Filter As %String(MAXLEN=512), RoundTime As %Boolean = 0, Mapped As %Boolean = 1) As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=512):File Name/Ext,IsDirectory:%String,Type:%Integer:,Size:%Integer:Routine Size,Date:%TimeStamp:Date/Time last modified,Description:%String(MAXLEN=32767):Brief Description,IconType:%Integer") [ SqlProc ]
{
}

ClassMethod StudioOpenDialogExecute(ByRef QHandle As %Binary, Spec As %String(MAXLEN=512) = "", Dir As %Integer = 1, OrderBy As %Integer = 1, SystemFiles As %Boolean = 0, Flat As %Boolean = 0, NotStudio As %Boolean = 0, ShowGenerated As %Boolean = 1, Filter As %String(MAXLEN=512), RoundTime As %Boolean = 0, Mapped As %Boolean = 1) As %Status
{
	If (Dir'=-1)&&(Dir'=1) Set Dir=1
	If ($SYSTEM.Security.GetGlobalPermission(,"^SYS")'["READ") ||
	   ($SYSTEM.Security.GetGlobalPermission(,"^rINDEX")'["READ") {
		#; Atelier can try this with a user without sufficient privileges
		Set idx=$increment(^CacheTemp)
		Set QHandle=$listbuild(idx)
		Quit $$$OK
	}
	If $get(^SYS("Studio","CaseInsensitive")) Set OrderBy=5,Dir=1
	If $extract($namespace)="^" Set Mapped=1
	Do StudioDocument^%SYS.cspServer2(.document)
	#; Let regular CSP searching find the javascript documents
	Kill document("%Studio.JavaScriptRoutine")
	$$$CheckRtnIndexExistsQuit(sc)
	Set isrtn=0
	If $case(OrderBy,1:0,2:0,3:0,4:0,5:0,:1) Quit $$$ERROR($$$GeneralError,"Illegal value passed in for 'OrderBy="_OrderBy_"' for StudioOpenDialog query, values can be 1,2,3,4,5")
	#; The directory is the first part of the specification, e.g. 'Package/*.cls'
	Set rest=$piece(Spec,",",2,*),Spec=$piece(Spec,",")
	If Spec["/" {
		Set directory=$piece(Spec,"/",1,*-1),Spec=$piece(Spec,"/",*)
		Set directory=$translate(directory,"\","/")
		If directory="" Set directory="/"
	} Else {
		Set directory=""
	}
	Set Spec=Spec_$select(rest="":"",1:","_rest)
	If Flat'<0,$get(Filter)="",Spec["[",Spec["]" Set Filter=$piece($piece(Spec,"[",2),"]"),Spec=$piece(Spec,"[")
	Set w=$listbuild(directory,Spec,Dir,OrderBy,SystemFiles,Flat,NotStudio,ShowGenerated,Filter,RoundTime,Mapped)
	Set tNewSpec=""
	For tN=1:1:$length(Spec,",") {
		Set tMask=$ZStrip($Piece(Spec,",",tN),"<>W")
		If $length(tMask,".")=1 {
			Set tNewSpec=tNewSpec_","_tMask_"*.*"
		} ElseIf $extract(tMask,*)="*",$extract(tMask,*-2,*)'="*.*",tMask'[";" {
			If $extract(tMask,*-1,*)=".*" {
				Set tNewSpec=tNewSpec_","_tMask_","_tMask_".*"
			} Else {
				Set tNewSpec=tNewSpec_","_tMask_".*"
			}
		} Else {
			Set tNewSpec=tNewSpec_","_tMask
		}
	}
	Set tNewSpec=$extract(tNewSpec,2,*)
	For tN=1:1:$Length(tNewSpec,",") {
		Set tMask=$Piece(tNewSpec,",",tN),not=0
		If $extract(tMask)="'" Set tMask=$extract(tMask,2,*),not=1
		Set tFile=$Piece(tMask,".",1,*-1),tExt=$ZCONVERT($Piece(tMask,".",*),"U")
		Set tExt=$piece(tExt,";"),tFile=$piece(tFile,";")
        If tExt="GBL",$EXTRACT(tFile)="^" Set $EXTRACT(tFile)="" ##; Remove the leading caret
		Do ..genPattern(tFile,.tAS,.tAE,.tPattern,2)
		Do ..genPattern(tExt,tExt,,.tExtPat,1)
		If tExtPat="" S tExtPat="1"""_tExt_""""
		If not Set notlist($increment(notlist))=$listbuild(tPattern,tAS,tAE,tExtPat) Continue
		Set ttAS=tAS
		If tMask[";*" {
			Set w("BKP",$order(w("BKP",""),-1)+1)=$listbuild(tPattern,tAS,tAE,tExtPat)
			If '$Data(bkpEnd)||($e(tAE,1,$l(bkpEnd))]bkpEnd) Set bkpEnd=tAE
			If '$Data(bkpStart)||(bkpStart]tAS) Set bkpStart=tAS
		} Else {
			Set cls=""
			For  {
				Set cls=$order(document(cls)) Quit:cls=""
				Set ext=""
				For  {
					Set ext=$order(document(cls,ext),1,data) Quit:ext=""||(tExt="OTHER"&&($zconvert(ext,"U")="MVB"))
					Set userext($zconvert(ext,"U"))="" 
					If $zconvert(ext,"U")?@tExtPat||(tExt="OTHER") {
						Set lext=$zconvert(ext,"l")
						If '$data(w(lext,"end"))||($extract(tAE,1,$length(w(lext,"end")))]w(lext,"end")) Set w(lext,"end")=tAE
						If '$data(w(lext,"start"))||(w(lext,"start")]tAS) Set w(lext,"start")=tAS
						Set w(lext,$order(w(lext,""),-1)+1)=$listbuild(tPattern,tAS,tAE)
						Set w(lext)=$listbuild(cls,$list(data))
						Set tAS=ttAS
						Quit
					}					
				}
			}
			For tI=$$$rtnMACTypes,$$$rtnINTTypes,$$$rtnINCTypes,"OBJ" {
				If tI'="OBJ"||(NotStudio),tI?@tExtPat {
					If tAS="",'SystemFiles {
						If $zu(12)=$zu(12,"") {
							#; Nothing needed, we have to check an item at a time.
						} Else {
							Set tAS="&"
						}
					}
					If '$data(rtnEnd)||($e(tAE,1,$l(rtnEnd))]rtnEnd) Set rtnEnd=tAE
					If '$Data(rtnStart)||(rtnStart]tAS) Set rtnStart=tAS
					Set w(tI,$Order(w(tI,""),-1)+1)=$ListBuild(tPattern,tAS,tAE),isrtn=1
					Set tAS=ttAS
				}
			}
			If "CLS"?@tExtPat {
				If '$Data(clsEnd)||($zconvert($e(tAE,1,$l(clsEnd)),"U")]clsEnd) Set clsEnd=$zconvert(tAE,"U")
				If '$Data(clsStart)||(clsStart]$zconvert(tAS,"U")) Set clsStart=$zconvert(tAS,"U")
				Set w("CLS",$Order(w("CLS",""),-1)+1)=$ListBuild(tPattern,tAS,tAE)
			}
			If "GBL"?@tExtPat,NotStudio {
				Set w("GBL",$Order(w("GBL",""),-1)+1)=$ListBuild(tPattern,tAS,tAE)
			}
			If "PRJ"?@tExtPat,'Flat||(tExt="PRJ") {
				Set w("PRJ",$Order(w("PRJ",""),-1)+1)=$ListBuild(tPattern,tAS,tAE)
			}
			If '$$$rtnIsKnown(tExt),",PRJ,GBL,CLS,OBJ,OTHER,"'[(","_tExt_","),tExt'="",'$data(userext(tExt)) {
				If Flat,tExt="CSPALL" {
					Set w("CSP",$Order(w("CSP",""),-1)+1)=$ListBuild(tPattern,tAS,tAE,".E")
				} Else {
					Set w("CSP",$Order(w("CSP",""),-1)+1)=$ListBuild(tPattern,tAS,tAE,tExtPat)
				}
			}
		}
	}
	Set idx=$increment(^CacheTemp)
	New %insertidx Set %insertidx=1
	Set sc=$$$OK
	#; Scan the database for the items that match
	#; User defined types are all in lower case
	Set ext=$order(w(""))
	While ext'="",Flat'=-1 {
		If ext=$zconvert(ext,"l") {
			Set sc=..getUserDocument(idx,.w,ext,directory,OrderBy,SystemFiles,Flat,ShowGenerated,Mapped)
			If $$$ISERR(sc) Quit
		}
		Set ext=$order(w(ext))
	}
	If $data(w("CSP")) Do ..getCSPList(idx,.w,directory,OrderBy,Flat)
	Set namespace=""
	If Mapped=0 {
		New $namespace
		Set namespace=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^oddDEF))
		If $Data(w("GBL")),namespace'=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^dummyGbl)) {
			Set $namespace=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^dummyGbl))
			Set rc=..getGlobalList(idx,.w,directory,OrderBy,SystemFiles) If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
		}
		Set $namespace=namespace,namespace=$namespace
	}
	If $data(w("CLS")) Do ..getClassList(idx,.w,directory,OrderBy,clsStart,clsEnd,SystemFiles,Flat,ShowGenerated,RoundTime)
	If isrtn Do ..getRoutineList(idx,.w,directory,OrderBy,rtnStart,rtnEnd,SystemFiles,Flat,ShowGenerated,''$data(notlist)||($g(Filter)'=""),RoundTime)
	If $data(w("PRJ")),(Flat'=-1)||((","_Spec_",")[".prj,") Do ..getProjectList(idx,.w,directory,OrderBy,RoundTime)
	If $data(w("BKP")) Do ..getBackupList(idx,.w,directory,OrderBy,bkpStart,bkpEnd)
	If $Data(w("GBL")) Set rc=..getGlobalList(idx,.w,directory,OrderBy,SystemFiles) If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	#; Now remove any 'not' patterns
	If $data(notlist) {
		Set idxitm=""
		For  {
			Set idxitm=$order(^||%RoutineList(idx,1,idxitm),1,data) Quit:idxitm=""
			Set name=$list(data),ext=$zconvert($piece(name,".",*),"U"),name=$extract(name,1,*-$length(ext)-1)
            If ext="GBL",$EXTRACT(name)="^" Set $EXTRACT(name)="" ##; Need to remove the caret for comparison purposes
			For i=1:1:notlist {
				Set tmp=notlist(i),pattern=$list(tmp),start=$list(tmp,2),end=$list(tmp,3),extpat=$list(tmp,4)
				If ext?@extpat,start=""||(start']name),end=""||($extract(name,1,$Length(end))']end),pattern=""||(name?@pattern) {
					Kill ^||%RoutineList(idx,1,idxitm) Quit
				}
			}
		}
	}
	#; Now handle any SQL restrictions
	Set ^||%RoutineList(idx)=directory_$select(directory["/"&&(directory'="/"):"/",directory="":"",1:".")
	If $get(Filter)'="",$$$ISOK(sc) {
		Set Filter=$zstrip(Filter,"<>W")
		Set find=$find($zconvert(Filter,"l"),"order by") If find Set Filter=$extract(Filter,1,find-9)
		Set statement="SELECT IsDoc, Coll FROM %Studio.OpenDialogItems WHERE NOT("_$piece(Filter,";")_")"
		New %INDEX Set %INDEX=idx Kill err
		New %SourceControl  ; Make sure we do not fire source control hooks for dynamic query we run here when this gets compiled
		Set rs=##class(%ResultSet.SQL).%Prepare(statement,.err)
		If $isobject($get(err)) {
			Set sc=err.Status
		} Else {
			While rs.%Next() {
				Kill:rs.IsDoc=1 ^||%RoutineList(idx,rs.IsDoc,rs.Coll)
			}
		}
	}
	#; If delay load of routines setup for a merge sort of the routines
	If $data(^||%RoutineList(idx,2),tmp) {
		Merge ^||%RoutineList(idx,4)=^||%RoutineList(idx,1)
		Kill ^||%RoutineList(idx,1)
		Do ..getRoutineBlock(idx,.w,"",5,$list(tmp),$list(tmp,2),$list(tmp,3),1,400,$list(tmp,4))
	}
	Set QHandle=$listbuild(idx,Dir,"","",namespace,directory,Flat)
	Quit sc
}

ClassMethod StudioOpenDialogClose(QHandle As %Binary) As %Status
{
	If $listget(QHandle)'="" {
		Kill ^||%RoutineList($list(QHandle))
	}
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod StudioOpenDialogFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..StudioOpenDialogFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>StudioOpenDialogFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod StudioOpenDialogFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	New %insertidx
	Set RowSet="",number=0,exit=0,sourceicon=0
	If QHandle="" Set AtEnd=1 Quit $$$OK
	If FetchCount=0 Set FetchCount=-1
	Set idx=$List(QHandle),dir=$List(QHandle,2),idxdir=$List(QHandle,3),idxitm=$List(QHandle,4),namespace=$listget(QHandle,5),directory=$listget(QHandle,6),flat=$listget(QHandle,7)
	If flat'<0,$isobject($get(%SourceControl))=1 Set sourceicon=(%SourceControl.IconStatus\2=1)
	If namespace'="" {
		New $namespace
		Set $namespace=namespace
	}
	#; Show the directories first
	If idxdir'=-1 {
		For  {
			Set idxdir=$order(^||%RoutineList(idx,0,idxdir),dir,item) If idxdir="" Quit
			Set RowSet=RowSet_item_$lb(0),number=number+1
			If number=FetchCount||($length(RowSet)>30000) Set exit=1 Quit
		}
		If idxdir="" Set idxdir=-1
		If exit Goto ExitFetch
	}
	If idxitm'=-1 {
		Set merge=$order(^||%RoutineList(idx,4,""),1,mergedata)
lp		For  {
			Set oldidx=idxitm,idxitm=$order(^||%RoutineList(idx,1,idxitm),dir,item) If idxitm="" Quit
			If merge'="",idxitm]merge Set item=mergedata,idxitm=oldidx Kill ^||%RoutineList(idx,4,merge) Set merge=$order(^||%RoutineList(idx,4,""),1,mergedata)
			If sourceicon {
				Set name=$listget(item)
				If flat=0,directory'="" Set name=directory_$select($listget(item,2)'="":$listget(item,2),1:".")_name
				Set RowSet=RowSet_item_$listbuild(%SourceControl.ItemIconState(name))
			} Else {
				Set RowSet=RowSet_item_$listbuild(0)
			}
			If $increment(number)=FetchCount||($length(RowSet)>30000) Set exit=1 Quit
		}
		If idxitm="",$data(^||%RoutineList(idx,3),tmp),$data(^||%RoutineList(idx,2))#10=1 {
			Set idxitm=$order(^||%RoutineList(idx,1,""),-1) Kill ^||%RoutineList(idx,3)
			Merge w=^||%RoutineList(idx,2)
			Set %insertidx=$list(tmp,2)
			Do ..getRoutineBlock(idx,.w,"",5,$list(tmp),$list(w,2),$list(w,3),1,400,$list(w,4))
			If 'exit Goto lp
		}
		#; Check if we are done
		If idxitm="" Set AtEnd=1,QHandle="",idxitm=-1 Kill ^||%RoutineList(idx) Quit $$$OK
	}

ExitFetch	; Return from the fetch loop
	Set ReturnCount=number
	Set QHandle=$ListBuild(idx,dir,idxdir,idxitm,namespace,directory,flat)
	Quit $$$OK
}

/// User defined document types
ClassMethod getUserDocument(idx As %Integer, ByRef w As %String, ext As %String, directory As %String, sort As %Integer, system As %Boolean, flat As %Boolean, ShowGenerated As %Boolean, Mapped As %Boolean) As %Status [ Private ]
{
	Set cls=$list(w(ext)),start=w(ext,"start"),end=w(ext,"end"),newformat=0
	Merge tmp=w(ext) Kill tmp("start"),tmp("end") Set tmp=$listbuild(Mapped)
	Kill ^CacheTemp(idx)
	Try {
		Set sc=$classmethod(cls,"ItemList",idx,ext,.tmp,start,end,directory,sort,system,flat,ShowGenerated,.newformat)
	} Catch {
		If $zerror["<PARAMETER>",$zerror[$zname {
			Try {
				Set sc=$classmethod(cls,"ItemList",idx,ext,.tmp,start,end,directory,sort,system,flat,ShowGenerated)
			} Catch {
				If $zerror["<PARAMETER>",$zerror[$zname {
					Try {
						Set sc=$classmethod(cls,"ItemList",idx,ext,.tmp,start,end,directory,sort,system,flat)
					} Catch {
						Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
					}
				} Else {
					Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
				}
			}
		} Else {
			Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
		}
	}
	If $$$ISERR(sc) Quit sc
	#; We only get here is an error on Try block above

	If 'newformat {
		If $data(^CacheTemp(idx)) { Set gbl=$name(^CacheTemp(idx)) } Else { Set gbl=$name(^||%RoutineList(idx)) }
		Set i="",j="",k=""
		For  {
			Set i=$order(@gbl@(i)) Quit:i=""
			For  {
				Set j=$order(@gbl@(i,j)) Quit:j=""
				Set jdx=$select(sort=3:$j(j,8),1:j)
				For  {
					Set k=$order(@gbl@(i,j,k),1,data) Quit:k=""
					Kill ^(k) Set ^||%RoutineList(idx,i,jdx_$char(0)_k)=data
				}
			}
		}
		Kill ^CacheTemp(idx)
	}
	Quit sc
}

/// Add the list of backup items that match these patterns
ClassMethod getBackupList(idx As %Integer, ByRef w As %String, directory As %String, sort As %Integer, bkpstart As %String, bkpend As %String) [ Private ]
{
	Set data=""
	If directory'="" Quit
	If bkpstart="" {
		Set backup=$order(^rBACKUP(0))
	} ElseIf $data(^rBACKUP(bkpstart)) {
		Set backup=bkpstart
	} Else {
		Set backup=$order(^rBACKUP(bkpstart))
	}
	While backup'="" {
		Set type=$order(^rBACKUP(backup,""))
		While type'="" {
			Set i=$order(w("BKP",""),1,work)
			While +i {
				Set pattern=$list(work),start=$list(work,2),end=$list(work,3),extpat=$list(work,4)
				If start=""||(start']backup),end=""||($extract(backup,1,$length(end))']end),pattern=""||(backup?@pattern),type?@extpat {
					Set typeno=$case(type,"MAC":0,"INT":1,"INC":2,"BAS":3,"CLS":4,"CSP":5,"CSR":6,"GBL":7,"PRJ":8,"MVI":12,:0)
					Set data="",version=$order(^rBACKUP(backup,type,""),1,data)
					While version'="" {
						#; Size should be stored in its own node but a previous version stored it as a $list
						Set size=$get(^rBACKUP(backup,type,version,"SIZE"),0)
						If $ascii(data)<48 {
							Try {
								If size=0 Set size=$listget(data,2)
								Set data=$listget(data)
							} Catch {
								Set data=""
							}
						} Else {
							If data="" Set data=$get(^rBACKUP(backup,type,version,0))
							Try {
								If data'="" Set data=$zdt(data,3)
							} Catch {
								Set data=""
							}
						}
						Set order=$case(sort,1:$zconvert(backup,"U"),2:data,3:$j(size,8),4:typeno,5:backup)
						If order="" Set order=0
						Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(backup_"."_type_";"_version,"",typeno,size,data,"")
						Set data="",version=$order(^rBACKUP(backup,type,version),1,data)
					}
					Quit
				}
				Set i=$order(w("BKP",i),1,work)
			}
			Set type=$order(^rBACKUP(backup,type))
		}
		Set backup=$order(^rBACKUP(backup))
		If bkpend'="",$extract(backup,1,$length(bkpend))']bkpend Quit
	}
	#; MAC and INC are still in the old backup location
	For type="MAC","INC" {
		If type="MAC" {
			Set typeno=0,gbl=$name(^rMACSAVE)
		} Else {
			Set typeno=2,gbl=$name(^rINCSAVE)
		}
		If bkpstart="" {
			Set backup=$order(@gbl@(""))
		} ElseIf $data(@gbl@(bkpstart)) {
			Set backup=bkpstart
		} Else {
			Set backup=$order(@gbl@(bkpstart))
		}
		While backup'="" {
			Set i=$order(w("BKP",""),1,work)
			While +i {
				Set pattern=$list(work),start=$list(work,2),end=$list(work,3),extpat=$list(work,4)
				If start=""||(start']backup),end=""||($extract(backup,1,$length(end))']end),pattern=""||(backup?@pattern),type?@extpat {
					Set version=$order(@gbl@(backup,""))
					While version'="" {
						Set size=$get(@gbl@(backup,version,"SIZE")),ts=$get(@gbl@(backup,version))
						If ts'="" Set ts=$zdt(ts,3)
						Set order=$case(sort,1:$zconvert(backup,"U"),2:ts,3:$j(size,8),4:typeno,5:backup)
						If order="" Set order=0
						Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(backup_"."_type_";"_version,"",$select(typeno=0:$select($get(^rMACSAVE(backup,0,"LANG"))<9:0,1:11),1:typeno),size,ts,"")
						Set version=$order(@gbl@(backup,version))
					}
					Quit
				}
				Set i=$order(w("BKP",i),1,work)
			}
			Set backup=$order(@gbl@(backup))
			If bkpend'="",$extract(backup,1,$length(bkpend))']bkpend Quit
		}
	}
}

/// Fill up the list of globals that match the pattern in <var>w</var>.
ClassMethod getGlobalList(idx As %Integer, ByRef w As %String, directory As %String, sort As %Integer, SystemFiles As %Boolean) As %Status [ Private, PublicList = globaldir ]
{
	New globaldir
	Set sc=$$$OK
	If directory'="" Quit $$$OK
	Do GetDirNSP^%SYS.GD($namespace,"globaldir")
	If $get(globaldir)'="" Quit $$$ERROR($$$GeneralError,"Unable to list all globals in '"_$namespace_"' : "_globaldir)
	Set global=""
	If 'SystemFiles,$zu(12)'=$zu(12,"") Set global="&"
	Set global=$Order(globaldir(global))
	While global'="" {
		Set i=$Order(w("GBL",""),1,work)
		While +i {
			Set pattern=$List(work),start=$List(work,2),end=$List(work,3)
			If start=""||(start']global),end=""||($Extract(global,1,$Length(end))']end),pattern=""||(global?@pattern) {
				Set order=$case(sort,1:$zconvert(global,"U"),2:0,3:0,4:7,5:global)
				If order="" Set order=0
				Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$LB("^"_global_".gbl","",7,"","","")
				Quit
			}
			Set i=$Order(w("GBL",i),1,work)
		}
		Set global=$Order(globaldir(global))
	}
	Quit sc
}

/// Fill up the list of projects that match the pattern in <var>w</var>.
ClassMethod getProjectList(idx As %Integer, ByRef w As %String, directory As %String, sort As %Integer, RoundTime As %Boolean = 0) [ Private ]
{
	Set ns=$namespace
	If directory'="" Quit
	Set project=$Order(^|ns|oddPROJECT(""),1,data)
	While project'="" {
		Set i=$Order(w("PRJ",""),1,work)
		While +i {
			Set pattern=$List(work),start=$List(work,2),end=$List(work,3)
			If start=""||(start']project),end=""||($Extract(project,1,$Length(end))']end),pattern=""||(project?@pattern) {
				Set order=$case(sort,1:$zconvert(project,"U"),2:$ListGet(data),3:$j($ListGet(data,6),8),4:8,5:project)
				If order="" Set order=0
				Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(project_".prj","",8,$listget(data,6),$select(RoundTime:$piece($listget(data),"."),1:$listget(data)),$listget(data,3))
				Quit
			}
			Set i=$Order(w("PRJ",i),1,work)
		}
		Set project=$Order(^|ns|oddPROJECT(project),1,data)
	}
}

/// Fill up the list of CSP applications and files that match the pattern in <var>w</var>.
ClassMethod getCSPList(idx As %Integer, ByRef w As %String, directory As %String, sort As %Integer, flat As %Boolean, ByRef visited As %String, origdir As %String) [ Private ]
{
	If directory'="" {
		If $extract(directory)'="/" Set directory="/"_directory
		If $extract(directory,*)'="/" Set directory=directory_"/"
	}
	Set visit=$select(directory="":$char(0),1:directory)
	If $data(visited(visit)) Quit
	Set visited(visit)=""
	Set found=0
	If '$data(origdir) Set origdir=directory
	#; Autocomplete for CSP application name
	If $extract(directory)="/",flat=-1,$$getapp^%SYS.cspServer(directory)="" {
		Do CSPAppList^%SYS.cspServer2(.apps)
		Set url=""
		For {
			Set url=$order(apps(url),1,data) Quit:url=""
			Set name=$extract(url,$length(directory)+1,*)
			Set i=$Order(w("CSP",""),1,work)
			While +i {
				Set pattern=$List(work),start=$List(work,2),end=$List(work,3)
				If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern) {
					Set ^||%RoutineList(idx,0,url_$char(0)_$i(%insertidx))=$listbuild(url,"/",10,"","","")
					Set found=1
					Quit
				}
				Set i=$Order(w("CSP",i),1,work)
			}
			#; Only need first match we find
			If found Quit
		}
		Quit
	}
	#; If at the root level show the CSP applications defined
	If directory="" {
		Do CSPAppList^%SYS.cspServer2(.apps)
		Set url=""
		For {
			Set url=$order(apps(url),1,data) Quit:url=""
			If flat {
				Do ..getCSPList(idx,.w,$select($extract(url,1,2)="//":url,url="/":"/",1:$extract(url,2,*)),sort,flat,.visited,"")
			} ElseIf $extract(url,1,2)="//" {
				Set ^||%RoutineList(idx,0,url_$char(0)_$i(%insertidx))=$listbuild(url,"/",10,"","","")
			} ElseIf '$data(^%SYS("CSP","DefaultServerName")) {
				Set ^||%RoutineList(idx,0,url_$char(0)_$i(%insertidx))=$listbuild($select(url="/":"/",1:$extract(url,2,*)),"/",10,"","","")
			}
		}
	} Else {
		Set setting=$$getapp^%SYS.cspServer(directory,.path),dir=$$GetFilename^%apiCSP(directory)
		If setting=""||(dir="") Quit
		#; Make sure this application is for this namespace
		If $$$GetSecurityApplicationsNameSpace(setting)'=$namespace Quit
		Set recurse=+$$$GetSecurityApplicationsRecurse(setting)
		Set dir=##class(%File).NormalizeDirectory(dir)
		#; Returning blank dir from normalize call means there is some error with the directory value
		If dir="" Quit
		If '$$$FileDirectoryExists(dir) Quit
		Set f=$zsearch(dir_"*")
		While f'="" {
			Set url=$extract(f,$length(dir)+1,*)
			#; Do not show the .. and . directories
			If url="."||(url="..") Set f=$zsearch("") CONTINUE
			Set ext=$zconvert($piece($piece(url,".",*),";"),"u"),name=$piece(url,".",1,*-1)
			If name="" Set name=$piece(url,";"),ext=""
			If $$$FileDirectoryExists(f) {
				#; Check length against 2000 in case we hit a filesystem link that is causing a recursive loop
				If recurse,$length(f)<2000 {
					Set order=$extract(url,1,230)
					If flat=-1||(flat=-2) {
						Set i=$Order(w("CSP",""),1,work)
						While +i {
							Set pattern=$List(work),start=$List(work,2),end=$List(work,3),extpat=$List(work,4)
							If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern),ext?@extpat {
								Set ^||%RoutineList(idx,0,order_$char(0)_$i(%insertidx))=$LB(directory_url_"/","/",10,"","","")
								Set found=1
								Quit
							}
							Set i=$Order(w("CSP",i),1,work)
						}
					} ElseIf flat=1 {
						Set order=$e($e(directory_url,$l(origdir)+1,*),1,230)
						If $data(dirlist(order)) {
							For i=1:1 Quit:'$data(dirlist(order_i))
							Set order=order_i
						}
						Set dirlist(order)=url
					} Else {
						Set ^||%RoutineList(idx,0,order_$char(0)_$i(%insertidx))=$LB(url,"/",10,"","","")
					}
				}
			} Else {
				Set i=$Order(w("CSP",""),1,work)
				While +i {
					Set pattern=$List(work),start=$List(work,2),end=$List(work,3),extpat=$List(work,4)
					If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern),ext?@extpat {
						Set mddate=$$$FileDateModified(f),size=$zu(140,1,f),mddate=$select(mddate>0:$$$TimeToODBC(mddate),1:"")
						#; Set max size on order to prevent possible SUBSCRIPT errors
						Set order=$extract($case(sort,1:$zconvert($e(directory_url,$l(origdir)+1,*),"U"),2:mddate,3:$j(size,8),4:5,5:$e(directory_url,$l(origdir)+1,*)),1,230)
						If order="" Set order=0
						If flat {
							Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$LB(directory_url,"/",5,size,mddate,""),found=1
						} Else {
							Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$LB(url,"/",5,size,mddate,"")
						}
						Quit
					}
					Set i=$Order(w("CSP",i),1,work)
				}
			}
			If found,flat=-1||(flat=-2) Quit
			Set f=$zsearch("")
		}
		Set f=$order(dirlist(""),1,file)
		While f'="" {
			Do ..getCSPList(idx,.w,directory_file,sort,flat,.visited,origdir)
			Set f=$order(dirlist(f),1,file)
		}
	}
}

/// Fill up the list of class that match the pattern in <var>w</var>.
ClassMethod getClassList(idx As %Integer, ByRef work As %String, directory As %String, sort As %Integer, clsStart As %String, clsEnd As %String, SystemFiles As %Boolean = 0, flat As %Boolean, ShowGenerated As %Boolean, RoundTime As %Boolean = 0) [ Private ]
{
	Set showhidden=((","_$ROLES_",")[",ISC_Internal,")||($get(^%SYS("Studio","ShowHidden")))
	Set ns=$namespace
	If directory'="" {
		Set clsStart=$ZConvert(directory,"U")_"."_clsStart,clsEnd=$ZConvert(directory,"U")_"."_clsEnd
	}
	Merge w=work("CLS")
	#; Search the flat class list
	If flat {
		If 'SystemFiles,clsStart="" {
			If $zu(12)'=$zu(12,"") {
				Set clsStart="&"
			}
		}
		If clsStart=""||('$data(^|ns|rINDEXCLASS(clsStart),data)) Set clsStart=$order(^|ns|rINDEXCLASS(clsStart),1,data)
		Set class=clsStart,startInsert=$get(%insertidx)
		While class'="",$extract(class,1,$length(clsEnd))']clsEnd {
			Set name=$list(data,2)
			If $extract(name,1,$length(directory))'=directory {
				Set class=$Piece(class,".",1,$length(directory,"."))_"/"
			} Else {
				Set piecename=$select(directory="":name,1:$extract(name,$length(directory)+2,*))
				Set i=$order(w(""),1,work)
				While +i {
					Set pattern=$list(work),start=$list(work,2),end=$list(work,3)
					If start=""||(start']piecename),end=""||($extract(piecename,1,$length(end))']end),pattern=""||(piecename?@pattern) {
						Set order=$case(sort,1:$zconvert(name,"U"),2:$list(data),3:$j($listget(data,6),8),4:4,5:name)
						If order="" Set order=0
						If showhidden||('$listget(data,4)),ShowGenerated||('$listget(data,10)),$listget(data,16)'=2,SystemFiles||($p(class,".",1,2)'="INFORMATION.SCHEMA") Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(name_".cls","",4,$listget(data,6),$select(RoundTime:$piece($list(data),"."),1:$list(data)),"")
						Quit
					}
					Set i=$order(w(i),1,work)
				}
			}
			Set class=$order(^|ns|rINDEXCLASS(class),1,data)
			If flat=-1||(flat=-2),$get(%insertidx)'=startInsert Quit
		}
	} Else {
		Do ..getPackageList(idx,directory,SystemFiles,,.work)
		If directory'="" {
			Set dirdot=$select(directory="":0,1:$length(directory,"."))+1,dirlen=$length(directory)+2
			If clsStart=""||('$Data(^|ns|rINDEXCLASS(clsStart),data)) Set clsStart=$Order(^|ns|rINDEXCLASS(clsStart),1,data)
			Set class=clsStart
			While class'="",$Extract(class,1,$Length(clsEnd))']clsEnd {
				If $extract($list(data,2),1,$length(directory))'=directory {
					Set class=$Piece(class,".",1,$length(directory,"."))_"/"
				} ElseIf $length(class,".")=dirdot {
					Set name=$extract($list(data,2),dirlen,*)
					Set i=$Order(w(""),1,work)
					While +i {
						Set pattern=$List(work),start=$List(work,2),end=$List(work,3)
						If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern) {
							Set order=$case(sort,1:$zconvert(name,"U"),2:$List(data),3:$j($ListGet(data,6),8),4:4,5:name)
							If order="" Set order=0
							If showhidden||('$listget(data,4)),ShowGenerated||('$listget(data,10)),$listget(data,16)'=2 Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(name_".cls","",4,$ListGet(data,6),$select(RoundTime:$piece($list(data),"."),1:$list(data)),"")
							Quit
						}
						Set i=$Order(w(i),1,work)
					}
				} ElseIf $length(class,".")>dirdot {
					#; Skip forward over this package as we do not want to show this yet
					Set class=$Piece(class,".",1,dirdot)_"/"
				}
				Set class=$Order(^|ns|rINDEXCLASS(class),1,data)
			}
		}
	}
}

/// Fill up the list of packages for this directory.
ClassMethod getPackageList(idx As %Integer, directory As %String, SystemFiles As %Boolean, namespace As %String = {$namespace}, ByRef work As %String)
{
	#; Handle the common case of the root directory first so this is as fast as possible
	If namespace=$namespace,$zutil(12)=$zutil(12,"") Set SystemFiles=1
	Set disablepkgcheck=$get(^SYS("Studio","DisablePkgCheck"),0)
	If directory="" {
		Set class=$Order(^|namespace|rINDEXCLASS($select(SystemFiles:"",1:"&")))
		While class'="" {
			If class["." {
				If 'SystemFiles,$p(class,".",1,2)="INFORMATION.SCHEMA" { Set class=$Piece(class,".",1,2)_"/" Set class=$Order(^|namespace|rINDEXCLASS(class)) Continue }
				Set package=$List(^|namespace|rINDEXCLASS(class),2),package=$Piece(package,".")
				If disablepkgcheck||(..showDir(package,.work)) Set ^||%RoutineList(idx,0,$zconvert(package,"U")_$char(0)_$i(%insertidx))=$LB(package,".",9,"","",$get(^|namespace|oddPKG($zconvert(package,"U"),"description")))
				Set class=$Piece(class,".")_"/"
			}
			Set class=$Order(^|namespace|rINDEXCLASS(class))
		}
	} ElseIf directory'["/" {
		Set dir=directory,directory=$ZConvert(directory,"U")
		Set dirlen=$length(directory)+2,dirend=directory_"/",dirt=$length(directory,".")+1
		Set class=$Order(^|namespace|rINDEXCLASS(directory_"."),1,data)
		While class'=""&&(class']dirend) {
			If 'SystemFiles,$p(class,".",1,2)="INFORMATION.SCHEMA" { Set class=$Piece(class,".",1,2)_"/" Set class=$Order(^|namespace|rINDEXCLASS(class),1,data) continue }
			If $extract($list(data,2),1,$length(directory))'=dir {
				Set class=$Piece(class,".",1,$length(dir,"."))_"/"
			} ElseIf $find(class,".",dirlen) {
				Set package=$List(data,2),package=$Piece($Extract(package,dirlen,*),".")
				If disablepkgcheck||(..showDir(dir_"."_package,.work)) {
					Set ^||%RoutineList(idx,0,$zconvert(package,"U")_$char(0)_$i(%insertidx))=$LB(package,".",9,"","",$get(^|namespace|oddPKG($zconvert(package,"U"),"description")))
				}
				Set class=$Piece(class,".",1,dirt)_"/"
			}
			Set class=$Order(^|namespace|rINDEXCLASS(class),1,data)
		}
	}
}

/// Fill up the list of packages for this directory.
ClassMethod getRoutineList(idx As %Integer, ByRef work As %String, directory As %String, sort As %Integer, rtnStart As %String, rtnEnd As %String, SystemFiles As %Boolean, flat As %Boolean, ShowGenerated As %Boolean, notlist As %Boolean = 0, RoundTime As %Boolean = 0) [ Private ]
{
	If directory'="" {
		If sort=5,flat=1||(flat=0) Quit
		Set rtnStart=directory_"."_rtnStart,rtnEnd=directory_"."_rtnEnd
	}
	For type=$$$rtnMACTypes,$$$rtnINTTypes,$$$rtnINCTypes,"OBJ" {
		Merge w(type)=work(type)
		Set i=$order(w(type,""),1,tmp)
		While +i {
			If $list(tmp,2)=rtnStart Set $list(w(type,i),2)=""
			If $list(tmp,3)=rtnEnd Set $list(w(type,i),3)=""
			Set i=$order(w(type,i),1,tmp)
		}
	}
	Set count=0,w=work
	If 'notlist,sort=5,'flat Merge ^||%RoutineList(idx,2)=w Set ^||%RoutineList(idx,2)=$listbuild(rtnStart,rtnEnd,SystemFiles,ShowGenerated,RoundTime) Quit $$$OK
	Do ..getRoutineBlock(idx,.w,directory,sort,rtnStart,rtnEnd,SystemFiles,flat,count,ShowGenerated,RoundTime)
}

ClassMethod getRoutineBlock(idx As %Integer, ByRef w As %String, directory As %String, sort As %Integer, rtnStart As %String, rtnEnd As %String, SystemFiles As %Boolean, flat As %Boolean, number As %Integer, ShowGenerated As %Boolean, RoundTime As %Boolean = 0) [ Private ]
{
	Set idxstart=%insertidx,count=0,ns=$namespace
	Set disablepkgcheck=$get(^SYS("Studio","DisablePkgCheck"),0)
	If flat=-1||(flat=-2) Set number=1
	If sort'=5,$sortbegin(^||%RoutineList(idx,1))
	If flat {
		Set curr=rtnStart
		#; Step up to the first item to check
		If $get(curr)=""||('$Data(^|ns|rINDEX(curr))) Set curr=$Order(^|ns|rINDEX(curr))
		While curr'=""&&($extract(curr,1,$length(rtnEnd))']rtnEnd) {
			Set name=$select(directory="":curr,1:$extract(curr,$length(directory)+2,*))
			Set type=$order(w(""))
			While type'="" { 
				If '$data(^|ns|rINDEX(curr,type),idxentry) Set type=$order(w(type)) Continue
				If 'ShowGenerated,$listget(idxentry,3)=1 Set type=$order(w(type)) Continue
				If 'SystemFiles,$p(curr,".",1,2)="INFORMATION.SCHEMA" Set type=$order(w(type)) Continue
				Set typeno=$case(type,"MAC":0,"INT":1,"INC":2,"BAS":3,"MVB":11,"MVI":12,"OBJ":13,"PY":"python")
				Set i=$Order(w(type,""),1,tmp)
				While +i {
					Set pattern=$List(tmp),start=$List(tmp,2),end=$List(tmp,3)
					If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern) {
						Set order=$case(sort,1:$zconvert(curr,"U"),2:$lg(idxentry),3:$j($lg(idxentry,2),8),4:typeno,5:curr)
						If order="" Set order=0
						Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(curr_"."_$zconvert(type,"l"),"",typeno,$lg(idxentry,2),$select(RoundTime:$piece($listget(idxentry),"."),1:$listget(idxentry)),"")
						Quit
					}
					Set i=$Order(w(type,i),1,tmp)
				}
				Set type=$order(w(type))
			}
			If number'=0,%insertidx-idxstart>number Goto exit
			If flat=-1||(flat=-2),$increment(count)>2000,$data(idxentry) {
				#; Record a dummy entry to make the package show up even if it may be empty
				If flat=-2 {
					Set order=$case(sort,1:$zconvert(curr,"U"),2:$lg(idxentry),3:$j($lg(idxentry,2),8),4:typeno,5:curr)
					If order="" Set order=0
					Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(curr_"."_$zconvert(type,"l"),"",typeno,$lg(idxentry,2),$select(RoundTime:$piece($listget(idxentry),"."),1:$listget(idxentry)),"")
				}
				Goto exit
			}
			Set curr=$Order(^|ns|rINDEX(curr))
		}
	} Else {
		Set dirdot=$select(directory="":0,1:$length(directory,"."))+1,dirlen=$select(directory="":0,1:$length(directory)+2)
		Set lastpackage=""
		If rtnStart=""||('$data(^|ns|rINDEX(rtnStart))) Set rtnStart=$order(^|ns|rINDEX(rtnStart))
		Set curr=rtnStart
		While curr'="",$extract(curr,1,$length(rtnEnd))']rtnEnd {
			Set dots=$length(curr,".")
			If 'SystemFiles,$p(curr,".",1,2)="INFORMATION.SCHEMA" { Set curr=$order(^|ns|rINDEX(curr)) Continue }
			If (dirdot=1&&(dots<2))||(dots=dirdot&&($piece(curr,".",dots)'?1(.1"G"1.N,1"PY",1"py")))||(dots=(dirdot+1)&&($piece(curr,".",dots)?1(.1"G"1.N,1"PY",1"py"))) {
				Set name=$extract(curr,dirlen,*)
				Set type=""
				For {
					Set type=$order(w(type)) Quit:type=""
					If '$data(^|ns|rINDEX(curr,type),idxentry) Continue
					If 'ShowGenerated,$listget(idxentry,3)=1 Continue
					Set typeno=$case(type,"MAC":0,"INT":1,"INC":2,"BAS":3,"MVB":11,"MVI":12,"OBJ":13,"PY":"python")
					Set i=$Order(w(type,""),1,tmp)
					While +i {
						Set pattern=$List(tmp),start=$List(tmp,2),end=$List(tmp,3)
						If start=""||(start']name),end=""||($Extract(name,1,$Length(end))']end),pattern=""||(name?@pattern) {
							Set order=$case(sort,1:$zconvert(name,"U"),2:$lg(idxentry),3:$j($lg(idxentry,2),8),4:typeno,5:name)
							If order="" Set order=0
							Set ^||%RoutineList(idx,1,order_$char(0)_$i(%insertidx))=$listbuild(name_"."_$zconvert(type,"l"),"",typeno,$lg(idxentry,2),$select(RoundTime:$piece($listget(idxentry),"."),1:$listget(idxentry)),"")
							Quit
						}
						Set i=$Order(w(type,i),1,tmp)
					}
				}
			} ElseIf dots>dirdot {
				Set package=$piece($extract(curr,dirlen,*),"."),upackage=$zconvert(package,"U")
				If package'=lastpackage {
					Set lastpackage=package
					Set tmp=$order(^||%RoutineList(idx,0,upackage),1,data),found=0
					While $extract(tmp,1,$length(package))=upackage {
						If $list(data)=package Set found=1 Quit
						Set tmp=$order(^(tmp),1,data)
					}
					If 'found,disablepkgcheck||(..showDir($select(directory="":"",1:directory_".")_package,.w)) Set ^||%RoutineList(idx,0,upackage_$char(0)_$i(%insertidx))=$listbuild(package,".",9,"","","")
				}
				#; Skip forward over this package as we do not want to show this yet
				Set dots=$extract($piece(curr,".",dirdot+1))
				If dots="G" {
					Set dots=$extract($piece(curr,".",dirdot+1),2)
					If dots'="",dots]"9" Set curr=$piece(curr,".",1,dirdot)_"/"
				} Else {
					Set curr=$Piece(curr,".",1,dirdot)_$select(dots]"G":"/",1:".G")
				}
			}
			Set curr=$order(^|ns|rINDEX(curr))
		}
	}
	If sort'=5,$sortend(^||%RoutineList(idx,1))
	Quit
exit	If flat'=-1 Set ^||%RoutineList(idx,3)=$listbuild(curr,%insertidx)
	If sort'=5,$sortend(^||%RoutineList(idx,1))
}

/// Passed a pattern match this returns an COS style pattern and a start and stop point.
ClassMethod genPattern(pSpec As %String, ByRef prAS As %String, ByRef prAE As %String, ByRef prPattern As %String, pFlag As %Integer) [ Private ]
{
	#; pSpec      - Input,  Wildcard specification
	#; prAS       - Output, AZ style start
	#; prAE       - Output, AZ style end
	#; prPattern  - Output, Generated pattern
	#; pFlag      - Input,  Control flags
	
	#; Handle A:Z style masks
	If pFlag\2#2,pSpec[":" Set prAS=$P(pSpec,":",1),prAE=$P(pSpec,":",2),prPattern="" Quit
	
	#; Double up the quotes
	Set pSpec=$replace(pSpec,"""","""""")
	
	#; Regular wildcards
	While pSpec["?*"||(pSpec["*?") { Set pSpec=$replace($replace(pSpec,"?*","*"),"*?","*") }
	While pSpec["**" { Set pSpec=$replace(pSpec,"**","*") }
	Set (prPattern,tPart)="",prAS=$Piece($TR(pSpec,"?","*"),"*")
	For tI=1:1:$Length(pSpec) Do
	. If "*?"[$Extract(pSpec,tI) Do  Quit
	. . If tPart]"" Set prPattern=prPattern_"1"""_tPart_"""",tPart=""
	. . If $Extract(pSpec,tI)="?" Do  Quit
	. . . Set tN=1 For tI=tI:1:$Length(pSpec)-1 Quit:$Extract(pSpec,tI+1)'="?"  Set tN=tN+1
	. . . Set prPattern=prPattern_tN_"E"
	. . If $Extract(pSpec,tI)="*" Set prPattern=prPattern_".E" Quit
	. Set tPart=tPart_$E(pSpec,tI)
	If tPart]"" Set prPattern=prPattern_"1"""_tPart_"""",tPart=""
	If pFlag#2=0,prAS_"*"=pSpec Set prPattern=""
	Set prAE=prAS
	Quit
}

/// Given a CSP path create the associated directory.
ClassMethod CreateCSPDirectory(directory) As %Status
{
	Set file=$$GetFilename^%apiCSP(directory)
	If file'="" Quit ##class(%File).CreateDirectoryChain(file)
	Quit $$$OK
}

/// Method implemented for Studio
ClassMethod FeatureBits(bit As %Integer = "") As %Binary [ Internal ]
{
	Quit $select(bit="":$zversion(0),1:$zbitget($zversion(0)_$char(0,0,0,0),bit))
}

ClassMethod OnPageCode(language As %String, xml As %Boolean = 0) As %String
{
	If $get(language)="" Set language="cache"
	If xml {
		If language="cache" {
			Quit "	Write ""<?xml version=""""1.0"""" ?>"",!"_$char(13,10)_"	Quit $$$OK"
		} ElseIf language="mvbasic" {
			Quit "PRINT ""<?xml version=""""1.0"""" ?>"""_$char(13,10)_"RETURN 1"
		} ElseIf language="basic" {
			Quit "println ""<?xml version=""""1.0"""" ?>"""_$char(13,10)_"return system.Status.OK()"
		}
	} Else {
		If language="cache" {
			Quit "	&html<<html>"_$char(13,10)_"<head>"_$char(13,10)_"</head>"_$char(13,10)_"<body>>"_$char(13,10)_"	; To do..."_$char(13,10)_"	&html<</body>"_$char(13,10)_"</html>>"_$char(13,10)_"	Quit $$$OK"
		} ElseIf language="mvbasic" {
			Quit "PRINT ""<html>"""_$char(13,10)_"PRINT ""<head>"""_$char(13,10)_"PRINT ""</head>"""_$char(13,10)_"PRINT ""<body>"""_$char(13,10)_"* To do..."_$char(13,10)_"PRINT ""</body>"""_$char(13,10)_"PRINT ""</html>"""_$char(13,10)_"RETURN 1"
		} ElseIf language="basic" {
			Quit "println ""<html>"""_$char(13,10)_"println ""<head>"""_$char(13,10)_"println ""</head>"""_$char(13,10)_"println ""<body>"""_$char(13,10)_"' To do..."_$char(13,10)_"println ""</body>"""_$char(13,10)_"println ""</html>"""_$char(13,10)_"return system.Status.OK()"
		}
	}
	Quit ""
}

ClassMethod CheckDeveloperRole() As %Status [ Internal ]
{
	If '$system.Security.Check("%Development","use") Quit $$$ERROR($$$NoDevloperPriv)
	Quit $$$OK
}

ClassMethod KillProcess(pid As %String) As %Status [ Internal ]
{
	Quit $$KillProcess^%SYS.cspServer2(pid)
}

ClassMethod NormalizeName(name As %String) As %String
{
	If name=0 Set name=""
	If $extract(name)="/",$length(name,"/")>2 Set name=$extract(name,2,*)
	If name[".",name'["/" Set name=$piece(name,".",1,*-1)_"."_$zconvert($piece(name,".",*),"U")
	Quit name
}

/// Used to delete the files associated with a directory from the open dialog
ClassMethod DeletePackage(package) As %Status
{
	Set sc=$system.OBJ.DeletePackage(package,"-d") If $$$ISERR(sc) Quit sc
	Set rs=##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog")
	Set sc=rs.Execute(package_"/*.*",,,,1,,0)
	If $$$ISERR(sc) Quit sc
	For  {
		Quit:rs.Next()=0
		Set name=rs.Data("Name")
		If $piece(name,".",1,*-1)=package Continue
		If $zconvert($piece(name,".",*),"l")="mvb" Continue
		If ..Exists(name) Set rc=..Delete(name) If $$$ISERR(rc),$length(sc)<8000 Set sc=$$$ADDSC(sc,rc)
	}
	Quit sc
}

/// Calculates the names of all documents that are not up-to-date with their compiled code and returns their names as a subscripted array.<p>
/// Arguments:
/// <ul>
/// <li><b>pDocumentList</b> - A subscripted array of document names with the format pDocumentList("User.Test.cls")="". Can be used as the first argument to <b>$SYSTEM.OBJ.CompileList()</b>.</li>
/// <li><b>pSpec</b>         - Check documents that match this spec. May contain both * and ? as wildcards.
///   It may also consist of more than one, comma-delimited selections. If you wish to exclude items
///   then prefix the pattern with ' symbol.</li>
/// <li><b>pSystem</b>       - Check system documents.</li>
/// <li><b>pGenerated</b>    - Check generated documents.</li>
/// <li><b>pMapped</b>       - Check documents that are mapped from another code database.</li>
/// </ul> 
ClassMethod OutOfDateDocuments(Output pDocumentList As %String, pSpec As %String(MAXLEN=512) = "*", pSystem As %Boolean = 0, pGenerated As %Boolean = 0, pMapped As %Boolean = 1) As %Status
{
    #Dim tSC As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        #; Get the list of documents to check
        Set tSC = ..StudioOpenDialogExecute(.tQHandle,pSpec,1,1,pSystem,1,0,pGenerated,"",0,pMapped)
        If $$$ISERR(tSC) Quit
        Set tListIdx = $LIST(tQHandle)
        Set tRoutineNode = $ORDER(^||%RoutineList(tListIdx,1,""),1,tRoutineNodeData)
        While tRoutineNode '= "" {
            #; Check if this document is up-to-date
            Set tDocumentName = $LIST(tRoutineNodeData), tUpToDate = 0
			If $ZCONVERT($PIECE(tDocumentName,".",*),"U") = "CLS" {
				Set tUpToDate = $SYSTEM.OBJ.IsUpToDate($PIECE(tDocumentName,".",1,*-1))
			} Else {
				Do ..TS(tDocumentName,,.tUpToDate)
			}
            If 'tUpToDate Set pDocumentList(tDocumentName) = ""
            Set tRoutineNode = $ORDER(^||%RoutineList(tListIdx,1,tRoutineNode),1,tRoutineNodeData)
        }
        Kill ^||%RoutineList(tListIdx)
    } Catch (e) {
        Set tSC = e.AsStatus()
    }
    Quit tSC
}

}
