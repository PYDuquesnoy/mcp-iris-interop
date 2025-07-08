/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// Represents a Studio Project.
/// <p>Many methods in this class use the <var>qspec</var> argument, which is a list of flags or qualifiers.
/// See <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Class %Studio.Project Extends (%Persistent, %XML.Adaptor) [ System = 3 ]
{

Parameter SQLPUBLICSECURITY = "{""Project_ProjectItemsList"":""Requires:%Development:USE"",""Project_WatchVariablesList"":""Requires:%Development:USE"",""Project_BreakPointsList"":""Requires:%Development:USE"",""Project_WatchPointsList"":""Requires:%Development:USE""}";

Index NameIdx On Name [ IdKey ];

Property Name As %String(MAXLEN = 64, XMLNAME = "name", XMLPROJECTION = "attribute");

Property LastModified As %Studio.TimeStamp(XMLPROJECTION = "attribute");

Property Description As %String(MAXLEN = 4000, XMLNAME = "ProjectDescription", XMLPROJECTION = "element");

Property Target As %String(MAXLEN = 256, XMLPROJECTION = "attribute");

ClassMethod TargetNormalize(val As %String) As %String
{
	If $translate($zconvert(val,"l"),"s")["http://" Set val=$piece($piece(val,"://",2,32767),"/",2,32767)
	If val["/" {
		Set app=$$getapp^%SYS.cspServer(val)
		If (app="")||($$$GetSecurityApplicationsNameSpace(app)'=$namespace) Set val=""
	}
	Quit val
}

Property TargetType As %Integer(XMLPROJECTION = "attribute");

Property RunInTerminal As %Boolean(XMLPROJECTION = "attribute");

Property HttpServer As %String(MAXLEN = 256, XMLPROJECTION = "attribute");

Property Locked As %Integer(XMLPROJECTION = "none") [ Transient ];

Property TerminalUsername As %String(MAXLEN = 64, XMLPROJECTION = "attribute");

Property TerminalPassword As %String(MAXLEN = 64, XMLPROJECTION = "attribute");

Property TerminalPort As %Integer(XMLPROJECTION = "attribute");

Property Projections As list Of %String(MAXLEN = 128, XMLPROJECTION = "none");

Property Defines As %String(MAXLEN = 4000, XMLPROJECTION = "attribute");

Property DebugStepping As %String(MAXLEN = 64, XMLPROJECTION = "none");

/// Temporary stream for passing information between InterSystems IRIS and client system.
Property Stream As %FileBinaryStream(XMLPROJECTION = "none") [ Transient ];

/// Temporary name of the stream
Property StreamName As %String(MAXLEN = 256, XMLPROJECTION = "none") [ Transient ];

Relationship Items As ProjectItem(XMLITEMNAME = "ProjectItem", XMLPROJECTION = "wrapped") [ Cardinality = children, Inverse = Project ];

Relationship BreakPoints As BreakPoint(XMLITEMNAME = "BreakPoint", XMLPROJECTION = "wrapped") [ Cardinality = children, Inverse = Project ];

Relationship WatchVariables As WatchVariable(XMLITEMNAME = "WatchVariable", XMLPROJECTION = "wrapped") [ Cardinality = children, Inverse = Project ];

Relationship WatchPoints As WatchPoint(XMLITEMNAME = "WatchPoint", XMLPROJECTION = "wrapped") [ Cardinality = children, Inverse = Project ];

Method %OnNew(initvalue) As %Status
{
	Set ..Locked=0
	Kill ^||%Studio.Project
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private ]
{
	Set ^||%Studio.Project=..Name
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(sc) Quit sc
	. Set tmp=%SourceControl New %SourceControl Set sc=tmp.OnBeforeLoad(..Name_".PRJ")
	. If $$$ISERR(sc) Quit
	. Set sc=tmp.OnAfterLoad(..Name_".PRJ")
	Quit $$$OK
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private ]
{
	Set name=$zconvert(..Name,"l")
	Set i="" For  Set i=$order(^oddPROJECT(i)) Quit:i=""||($zconvert(i,"l")=name&&(i'=..Name))
	If i'="" {
		#; If this is a clash of default project names just kill the other version
		If $extract($zconvert(name,"l"),1,$length("default_"))="default_" {
			Kill ^oddPROJECT(i)
		} Else {
			Quit $$$ERROR($$$DuplicatedName,i)
		}
	}
	Set ts=$zutil(188),..LastModified=$$$TimeToODBC(ts)
	Do ..Stream.Clear()
	If i%Name'="",$isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeSave(i%Name_".PRJ","")
	QUIT $$$OK
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	If i%Name'="",$isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterSave(i%Name_".PRJ")
	QUIT $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	If ..Locked Set ..Locked=1 Do ..Unlock()
	If r%Stream'=$$$NULLOREF Do (r%Stream).Clear()
	#; Remove the global variable when this class is closed
	Kill ^||%Studio.Project
	Quit $$$OK
}

Method %IsModified() As %Integer
{
	Quit 1
}

Method %ObjectModified() As %Integer
{
	Quit 1
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	Set id=$$$oidPrimary(oid)
	If id'="",$isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeDelete(id_".PRJ")
	QUIT $$$OK
}

/// Return the timestamp the project with <var>name</var> was last updated.
ClassMethod GetDate(name As %String) As %TimeStamp
{
	If '$data(^oddPROJECT(name)) Quit -1
	Quit $listget(^oddPROJECT(name))
}

Method NameSet(val As %String) As %Status
{
	Set oname=i%Name,locked=..Locked
	Set i%Name=val
	Set ^||%Studio.Project=val
	#; If current project is locked then lock the new name and release the existing lock
	If ..Locked {
		Set ..Locked=0
		Set ok=..Lock()
		If $$$ISERR(ok) {
			Set i%Name=oname,..Locked=locked
			Quit ok
		}
		Set i%Name=oname
		Do ..Unlock()
		Set i%Name=val,..Locked=locked
	}
	Quit $$$OK
}

ClassMethod NameIsValid(val As %String) As %Status
{
	If $length(val)>64 Quit $$$ERROR($$$DTMaxLen,val,64)
	Set sc=$$$OK
	For char=",",".",";","/","\" {
		If val[char Set sc=$$$ERROR($$$DTInvalidChar,val,char) Quit
	}
	Quit sc
}

/// Delete this project
ClassMethod Delete(id As %String) As %Status
{
	If id="" Quit $$$ERROR($$$ProjectBlankName)
	If $isobject($get(%SourceControl)) {
		Set edit=0,isinsourcecontrol=0,ischeckedout=0,user=""
		Do
		. Set tmp=%SourceControl New %SourceControl Set sc=tmp.GetStatus(id_".PRJ",.isinsourcecontrol,.edit,.ischeckedout,.user)
		If $$$ISERR(sc) Quit sc
		If 'edit Quit ##class(%RoutineMgr).ConstructEditError(id_".PRJ",isinsourcecontrol,ischeckedout,user)
	}
	Set sc=##Class(%SYS.GlobalQuery).Lock("oddPROJECT",id,id_".PRJ") If $$$ISERR(sc) Quit sc
	Set sc=..%DeleteId(id)
	Do ##Class(%SYS.GlobalQuery).UnLock("oddPROJECT",id)
	Quit sc
}

/// Lock the project.
Method Lock() As %Status
{
	If i%Name="" Quit $$$ERROR($$$ProjectBlankName)
	If ..Locked>0 {
		Set ..Locked=..Locked+1
		Quit $$$OK
	}
	Set sc=..LockItem(i%Name,1)
	If $$$ISOK(sc) Set ..Locked=..Locked+1
	Quit sc
}

/// Unlock the project.
Method Unlock() As %Status
{
	If i%Name="" Quit $$$ERROR($$$ProjectBlankName)
	Quit:..Locked=0 $$$OK
	If ..Locked>1 {
		Set ..Locked=..Locked-1
		Quit $$$OK
	}
	Set sc=..LockItem(i%Name,0)
	If $$$ISOK(sc) Set ..Locked=..Locked-1
	Quit sc
}

/// Lock a project with the <var>name</var>. If <var>lock</var> is true then it is locked
/// and if it is false then it is unlocked.
ClassMethod LockItem(name As %String, lock As %Boolean) As %Status
{
	If name="" Quit $$$ERROR($$$ProjectNoName)
	Set nm=$zconvert(name,"l")
	Set i="" For  Set i=$order(^oddPROJECT(i)) Quit:i=""||($zconvert(i,"l")=nm&&(i'=name))
	If i'="" Quit $$$ERROR($$$DuplicatedName,i)

	If lock {
		If $isobject($get(%SourceControl)) {
			Set edit=0,isinsourcecontrol=0,ischeckedout=0,user=""
			Do
			. Set tmp=%SourceControl New %SourceControl Set sc=tmp.GetStatus(name_".PRJ",.isinsourcecontrol,.edit,.ischeckedout,.user)
			If $$$ISERR(sc) Quit sc
			If 'edit Quit ##class(%RoutineMgr).ConstructEditError(name_".PRJ",+$get(isinsourcecontrol),+$get(ischeckedout),$get(user))
		}
	}
	If lock {
		Quit ##Class(%SYS.GlobalQuery).Lock("oddPROJECT",name,name_".PRJ")
	} else {
		Quit ##Class(%SYS.GlobalQuery).UnLock("oddPROJECT",name,0)
	}
}

/// Create a clone of this project and then save it with a new name. Note that if the
/// target name already exists then it will be deleted without warning. It is the responsibility
/// of the caller to check if it wishes to overwrite the new name or not.
Method CreateClone(name As %String) As %Status [ ProcedureBlock = 1 ]
{
	Set prj=..%ConstructClone(1)
	If prj=$$$NULLOREF Quit $$$ERROR($$$UnableToCopyProject)
	Set prj.Name=name
	If ..%ExistsId(name) Set sc=..%DeleteId(name) If $$$ISERR(sc) Quit sc
	Quit prj.%Save()
}

/// Add an item to the project, you can just pass the full name in the <var>name</var> argument and nothing in the
/// <var>type</var> argument and this will add the correct type information automatically.
Method AddItem(name As %String, type As %String = "") As %Status
{
	Set sc=..NormalizeName(.name,.type) If $$$ISERR(sc) Quit sc

	#; Check if this item is already in the project, if it is just return to caller
	If ..Name'="" {
		Set id = ..Name _ "||" _ name _ "||" _ type
		If ..Items.FindObjectId(id)'="" Quit $$$OK
	}
	#; Allow matching of CSP items case insensitively so if you add A.CSP you can remove a.CSP and it will work
	#; We do not allow two items of the same name in the same project differing only in case
	If type="CSP" ||(type = "DIR"){
		Set key="" For  Set oref=..Items.GetNext(.key) Quit:key=""  If $isobject(oref),$zconvert(oref.Name,"l")=$zconvert(name,"l"),oref.Type=type Quit
		If key'="",oref.Name'=name Quit $$$ERROR($$$ProjectIncludesCSP,name,..Items.GetAt(key).Name)
	} Else {
		Set items=..Items
		Set key="" For {
			Set oref=items.GetNext(.key) Quit:key=""
			If '$isobject(oref) Continue
			Set n=oref.Name,t=oref.Type
			If n=name,t=type Quit
			If type="PKG"&&(t="CLS"||(t="PKG"))||(type="CLS"&&(t="PKG")) Set list(t,n)=key
		}
	}
	
	If key'="" Quit $$$OK

	#; Can not add any classes that are already included from packages
	If type="CLS"||(type="PKG") {
		If ..Name'="" {
			For i=1:1:$length(name,".")-1 {
				Set root=$piece(name,".",1,i)
				If ..Items.FindObjectId(..Name_"||"_root_"||PKG")'="" Set sc=$$$ERROR($$$ProjectIncludesPackage,name_"."_type,root) Quit
			}
			If $$$ISERR(sc) Quit sc
		}
		Set entry=""
		For  {
			Set entry=$order(list("PKG",entry)) Quit:entry=""
			If $extract(name,1,$length(entry)+1)=(entry_".") Set sc=$$$ERROR($$$ProjectIncludesPackage,name_"."_type,entry) Quit
		}
		If $$$ISERR(sc) Quit sc
	}
	
	Set item = ##class(ProjectItem).%New()
	Set item.Name = name,item.Type = type
	Do ..Items.Insert(item)
	#; Remove any classes that are already in this package
	If type="PKG" {
		Set sc=$$$qualifierParse("Compiler","",.qstruct) Quit:$$$ISERR(sc) sc
		Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct)
		Set entry=""
		For  {
			Set entry=$order(list("CLS",entry),1,data) Quit:entry=""
			If $data(clslist(entry)) Do ..Items.RemoveAt(data)
		}	
	}
	
	if type="DIR" {
		Set entry=""
		set n = $l(name)
		For  {
			Set node=..Items.GetNext(.entry) Quit:entry=""
			If $isobject(node),((node.Type="CSP") || (node.Type="DIR")){
			 if (($l(node.Name) > n) &&($e(node.Name,1,n)=name)) {
				Do ..Items.RemoveAt(entry)			 }
			}
		}	
	}
	
	Quit sc
}

Method RemoveItem(name As %String, type As %String = "") As %Status
{
	Set sc=..NormalizeName(.name,.type,1) If $$$ISERR(sc) Quit sc
	If ..Name'="" {
		Set id = ..Name _ "||" _ name _ "||" _ type
		Set oid=..Items.RemoveObject($lb(id))
		Quit:oid'=$$$NULLOID $$$OK
	}
	#; Allow matching of CSP items case insensitively so if you add A.CSP you can remove a.CSP and it will work
	#; We do not allow two items of the same name in the same project differing only in case
	If type="CSP" {
		Set key="" For  Set oref=..Items.GetNext(.key) Quit:key=""  If $isobject(oref),$zconvert(oref.Name,"l")=$zconvert(name,"l"),oref.Type=type Quit
	} Else {
		Set key="" For  Set oref=..Items.GetNext(.key) Quit:key=""  If $isobject(oref),oref.Name=name,oref.Type=type Quit
	}
	If key'="" Do ..Items.RemoveAt(key) Quit $$$OK
	If type="PKG" {
		#; If you remove A.PKG but this is not in the project then remove all classes in this package, and subpackages
		Set entry=""
		For  {
			Set entry=..Items.Next(entry) Quit:entry=""
			Set node=..Items.GetOrefAt(entry)
			If $isobject(node),$case(node.Type,"CLS":1,"PKG":1,:0),$extract(node.Name,1,$length(name)+1)=(name_".") Do ..Items.RemoveAt(entry)
		}
		Quit $$$OK
	} ElseIf type="CLS" {
		Set sc=$$$OK
		If ..Name'="" {
			For i=1:1:$length(name,".")-1 {
				Set root=$piece(name,".",1,i)
				If ..Items.FindObjectId(..Name_"||"_root_"||PKG")'="" Set sc=$$$ERROR($$$ProjectIncludesPackage,name_"."_type,root) Quit
			}
			If $$$ISERR(sc) Quit sc
		}
		Set entry=""
		For  {
			Set entry=..Items.Next(entry) Quit:entry=""
			Set node=..Items.GetOrefAt(entry)
			If $isobject(node),node.Type="PKG",$extract(name,1,$length(node.Name)+1)=(node.Name_".") Set sc=$$$ERROR($$$ProjectIncludesPackage,name_"."_type,node.Name) Quit
		}
		If $$$ISERR(sc) Quit sc
	} elseif type="DIR" {
		Set entry=""
		set n = $l(name)
		For  {
			Set node=..Items.GetNext(.entry) Quit:entry=""
			If $isobject(node),((node.Type="CSP") || (node.Type="DIR")){//,$data(clslist(node.Name)) Do ..Items.RemoveAt(entry)
			 if (($l(node.Name) > n) &&($e(node.Name,1,n)=name)) {
				Do ..Items.RemoveAt(entry)			 }
			}
		}	
	}
	Quit $$$ERROR($$$ProjectItemNotPresent,name)
}

Method AddBreakPoint(rtn As %String, offset As %Integer, condition As %String = "", label As %String = "") As %Status
{
	If rtn="" Quit $$$ERROR($$$PropertyRequired,"%Studio.BreakPoint::Routine")
	If label'="" Set offset=label_"+"_offset
	Set len=$length(rtn,".")
	If len>1 Set rtn=$piece(rtn,".",1,len-1)_"."_$zconvert($piece(rtn,".",len),"U")
	Set bp = ##class(BreakPoint).%New()
	Set bp.Routine = rtn
	Set bp.Offset = offset
	Set bp.Condition = condition
	Do ..BreakPoints.Insert(bp)
	Quit $$$OK
}

Method RemoveBreakPoint(rtn As %String, offset As %Integer, label As %String = "") As %Status
{
	If label'="" Set offset=label_"+"_offset
	Set len=$length(rtn,".")
	If len>1 Set rtn=$piece(rtn,".",1,len-1)_"."_$zconvert($piece(rtn,".",len),"U")
	If ..Name'="" {
		Set id = ..Name _ "||" _ rtn _ "||" _ offset
		Set oid=..BreakPoints.RemoveObject($lb(id))
		Quit:oid'=$$$NULLOID $$$OK
	}
	Set key=""
	For  {
		Set bp=..BreakPoints.GetNext(.key) Quit:key=""
		If $isobject(bp),bp.Offset=offset {
			Set brtn=bp.Routine
			Set len=$length(brtn,".")
			If len>1 Set brtn=$piece(brtn,".",1,len-1)_"."_$zconvert($piece(brtn,".",len),"U")
			If rtn=brtn Quit
		}
	}
	If key'="" Do ..BreakPoints.RemoveAt(key) Quit $$$OK
	Quit $$$ERROR($$$DeleteObjectNotFound)
}

Method RemoveBreakPointsForRoutine(rtn As %String) As %Status
{
	Set len=$length(rtn,".")
	If len>1 Set rtn=$piece(rtn,".",1,len-1)_"."_$zconvert($piece(rtn,".",len),"U")
	#; loop over breakpoints, remove all for this routine
	Set key = ""
	Do {
		Set bp = ..BreakPoints.GetNext(.key)
		If ((bp '= $$$NULLOREF)) {
			Set brtn=bp.Routine
			Set len=$length(brtn,".")
			If len>1 Set brtn=$piece(brtn,".",1,len-1)_"."_$zconvert($piece(brtn,".",len),"U")
			If (brtn = rtn) {
				Do ..BreakPoints.RemoveAt(key)
			}
		}
	} While (key '= "")
	Quit $$$OK
}

/// Remove all break points from a project.<br>
Method RemoveAllBreakPoints() As %Status
{
	Do ..BreakPoints.Clear()
	Quit $$$OK
}

Method AddWatchPoint(var As %String, condition As %String = "") As %Status
{
	If var="" Quit $$$ERROR($$$PropertyRequired,"%Studio.WatchPoint::Variable")
	Set wp = ##class(WatchPoint).%New()
	Set wp.Variable = var
	Set wp.Condition = condition
	Do ..WatchPoints.Insert(wp)
	Quit $$$OK
}

Method RemoveWatchPoint(var As %String, condition As %String = "") As %Status
{
	If ..Name'="" {
		Set id = ..Name _ "||" _ var
		Set oid=..WatchPoints.RemoveObject($lb(id))
		Quit:oid'=$$$NULLOID $$$OK
	}
	Set key=""
	For  {
		Set wp=..WatchPoints.GetNext(.key) Quit:key=""
		If $isobject(wp),wp.Variable=var Quit
	}
	If key'="" Do ..WatchPoints.RemoveAt(key) Quit $$$OK
	Quit $$$ERROR($$$DeleteObjectNotFound)
}

/// Remove all break points from a project.<br>
Method RemoveAllWatchPoints() As %Status
{
	Do ..WatchPoints.Clear()
	Quit $$$OK
}

Method AddWatchVariable(variable As %String, pane As %Integer) As %Status
{
	Set sc = $$$OK
	If variable="" Quit $$$ERROR($$$PropertyRequired,"%Studio.WatchVariable::Variable")
	If pane="" Quit $$$ERROR($$$PropertyRequired,"%Studio.WatchVariable::Pane")
	Set wv = ##class(WatchVariable).%New()
	Set wv.Variable = variable,wv.Pane=pane
	Do ..WatchVariables.Insert(wv)
	Quit sc
}

Method RemoveWatchVariable(variable As %String, pane As %Integer) As %Status
{
	If ..Name'="" {
		Set id = ..Name _ "||" _ $replace(variable,"||","__") _ "||" _ pane
		Set oid=..WatchVariables.RemoveObject($lb(id))
		Quit:oid'=$$$NULLOID $$$OK
	}
	Set key="" For  Set key=..WatchVariables.Next(key) Quit:key=""  Quit:(..WatchVariables.GetAt(key).Variable=variable&&(..WatchVariables.GetAt(key).Pane=pane))
	If key'="" Do ..WatchVariables.RemoveAt(key) Quit $$$OK
	Quit $$$ERROR($$$DeleteObjectNotFound)
}

/// Remove all watch variables from a project.<br>
Method RemoveAllWatchVariables() As %Status
{
	Do ..WatchVariables.Clear()
	Quit $$$OK
}

/// Get the on-disk timestamp for the project.
Method GetCurrentTimeStamp() As %TimeStamp
{
	Set id=..Name If id="" Quit ..LastModified
	&sql(select LastModified into :ts from %Studio.Project where Name=:id)
	If SQLCODE Quit ..LastModified
	Quit ts
}

/// Return comma separated list of items in this project which can be called as web pages
Method ListWebPages(ByRef pages As %String(MAXSTRING=""), qspec As %String = "") As %Status
{
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) Quit:$$$ISERR(sc) sc
	Set pages="",item=""
	For {
		Set itemobj=..Items.GetNext(.item) If '$isobject(itemobj) Quit
		Set name=itemobj.Name,type=itemobj.Type
		If type="CSP" {
			If $length(name,".")=1 Set name=name_".csp"
			Set newtype=$zconvert($piece(name,".",*),"U")
			If newtype="CSP" Set pages=pages_$select($extract(name)="/":"",1:"/")_name_","
		} ElseIf type="CLS" {
			If ##class(%SYSTEM.CSP).WebPage(name) Set pages=pages_name_".cls,"
		} ElseIf type="PKG" {
			Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct) If $$$ISERR(sc) Quit
			Set clslist=""
			For  {
				Set clslist=$order(clslist(clslist)) Quit:clslist=""
				If ##class(%SYSTEM.CSP).WebPage(clslist) Set pages=pages_clslist_".cls,"
			}
		}
		Do ..Items.%UnSwizzleAt(item)
		If $length(pages)>($$$MaxLocalLength-400) Quit
	}
	Set pages=$extract(pages,1,*-1)
	Quit sc
}

/// Compile all the items in this project, using the <var>qspec</var>. The order
/// of compilation is INT, CLS, MAC, CSR, CSP, other.
Method Compile(qspec As %String = "", ByRef %errorlog As %String) As %Status
{
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	Set origlasterror=$get(%objlasterror)
	If ..Defines'="" {
		Set $$$qualifierGetValue(qstruct,"defines")=$zstrip(..Defines,"<>W")_$select($get($$$qualifierGetValue(qstruct,"defines"))="":"",1:","_$$$qualifierGetValue(qstruct,"defines"))
	}
	Set display=$$$qualifierGetValue(qstruct,"displaylog")
	If ..Items.Count()=0 {
		If display Write !,$$$GetSimpleMessage("%Compiler","NothingCompile")
		Quit $$$OK
	}
	Set zh=$zh
	If display Write !,$$$FormatMessage(,"%Compiler",$select(qstruct="":"CompileStartedNoQual",1:"CompileStarted"),,$zdt($horolog),qstruct)
	If $Get(%SourceControl)'="" Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnBeforeCompile(i%Name_".PRJ",.qstruct)
	. If $$$ISERR(rc) Do DecomposeStatus^%apiOBJ(rc,.%errorlog,.qstruct)
	$$$InitErrorNums
	Set item="",sc=$$$OK
	#; Create list of items in this project.
	Set itemobj=..Items.GetNext(.item)
	While item'="" {
		If $isobject(itemobj) {
			Set name=itemobj.Name,type=itemobj.Type
			If '##class(%RoutineMgr).Exists(name_$Select(type="CLS"||(type="PKG")||(type="DIR"):"."_type,1:"")) {
				#; Do nothing with items that do not exist
			} ElseIf type="MAC" {
				#; Separate out MAC, INT routine types
				If $length(name,".")=1 Set name=name_".MAC"
				Set ext=$ZConvert($Piece(name,".",*),"U")
				Set slot=$select($$$rtnIsMAC(ext):"MAC",$$$rtnIsINT(ext):"INT",1:"")
				Set:slot'="" itemlist(slot,$Piece(name,".",1,*-1))=ext
			} ElseIf type="CSP" {
				#; Separate out CSP and CSR files
				If $length(name,".")=1 Set name=name_".csp"
				Set newtype=$zconvert($piece(name,".",*),"U")
				If newtype="CSP"||(newtype="CSR") Set itemlist(newtype,name)=""
			} ElseIf type="PKG" {
				Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct)
				Set clslist=""
				For  {
					Set clslist=$order(clslist(clslist)) Quit:clslist=""
					If '$$$defClassKeyGet(clslist,$$$cCLASSdeployed) Set itemlist("CLS",clslist)=""
				}
			} ElseIf type="CLS" {
				Set itemlist(type,name)=""
			} ElseIf type="DIR" {
				Set rs=##class(%ResultSet).%New("%Library.RoutineMgr:StudioOpenDialog")
				Do rs.Execute(name_"/*.cspall,*.csp,*.csr",1,1,1,1)
				While rs.Next() {
					Set name1=rs.Data("Name")
					If $length(name1,".")=1 Set name1=name1_".csp"
					Set newtype1=$zconvert($piece(name1,".",*),"U")
					If newtype1="CSP"||(newtype1="CSR") Set itemlist(newtype1,name1)=""
				}
				Set rs=""
			} Else {
				Set itemlist(type,$piece(name,".",1,*-1))=""
			}
			Do ..Items.%UnSwizzleAt(item)
		}
		Set itemobj=..Items.GetNext(.item)
	}
	Set rc=..realCompile(.qstruct,.%errorlog,.itemlist)
	If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	If $Get(%SourceControl)'="" Do  If $$$ISERR(rc) Quit rc
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnAfterCompile(i%Name_".PRJ")
	. If $$$ISERR(rc) Set errcount=$get(%errorlog),sc=$$$ADDSC(sc,rc) Do DecomposeStatus^%apiOBJ(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount)

	Quit $$reportCompile^%apiOBJ(sc,display,,,zh,$$$qualifierGetValue(qstruct,"displayerror"),origlasterror)
}

/// Compile all the items in itemlist. Used by <method>Compile</method> and <Method>Import</Method>.
ClassMethod realCompile(qstruct, ByRef %errorlog As %String, ByRef itemlist As %String, ByRef updatedlist As %String) As %Status
{
	Set rc=$$$OK,sc=$$$OK
	Kill updatedlist
	If $$$qualifierAmend("Compiler",.qstruct,"/nodisplay",.qstructa)
	If $$$qualifierAmend("Compiler",.qstruct,"/cspcompileclass=0",.qstructb)
	#; Remove any items we do not have write access on
	Set type=""
	For {
		Set type=$order(itemlist(type)) Quit:type=""
		If type="GBL" Continue
		Set item=$order(itemlist(type,""))
		While item'="" {
			Set name=item_$select(type'="CSP"&&(type'="CSR"):"."_type,1:"")
			If $$CheckProtect^%occSAX(name) {
				Kill itemlist(type,item)
				Set rc=$$$ERROR($$$CompileProtect,name)
				Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) Set:$$$ISOK(sc) sc=rc
			}
			Set item=$order(itemlist(type,item))
		}
	}
	#; Compile the INT types
	Set item=""
	For {
		Set item=$order(itemlist("INT",item)) Quit:item=""
		If $isobject($get(%SourceControl)) {
			Do
			. $$$SuspendErrorCount
			. Set tmp=%SourceControl New %SourceControl
			. Set rc=tmp.OnBeforeCompile(item_"."_$zconvert(itemlist("INT",item),"U"),.qstruct)
			If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc) Kill itemlist("INT",item) Continue
		}
		Set rtnlist(item_"."_$zconvert(itemlist("INT",item),"U"))=""
	}
	Set rc=$$CompileList^%apiRTN(.rtnlist,.qstruct) Kill rtnlist
	If $$$ISERR(rc) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstructa) Set:$$$ISOK(sc) sc=rc
	Set item=""
	For  {
		Set item=$order(itemlist("INT",item)) Quit:item=""
		If $isobject($get(%SourceControl)) {
			Do
			. $$$SuspendErrorCount
			. Set tmp=%SourceControl New %SourceControl
			. Set rc=tmp.OnAfterCompile(item_"."_$zconvert(itemlist("INT",item),"U"))
			If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
		}
	}
	#; Now compile any classes
	If $data(itemlist("CLS")) {
		Merge classes=itemlist("CLS")
		Set cls="" For  Set cls=$order(classes(cls)) Quit:cls=""  If $$$defClassKeyGet(cls,$$$cCLASSdeployed) Kill classes(cls)
		If $isobject($get(%SourceControl)) {
			Set item=$Order(classes(""))
			While item'="" {
				Do
				. $$$SuspendErrorCount
				. Set tmp=%SourceControl New %SourceControl
				. Set rc=tmp.OnBeforeCompile(item_".CLS",.qstruct)
				If $$$ISERR(rc) Kill classes(item) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
				Set item=$Order(classes(item))
			}
		}
		Set rc=$$CompileList^%occCompile(.classes,.qstruct,.%errorlog,.updClsList)
		If $$$ISERR(rc),$$$ISOK(sc) Set sc=rc
		If $isobject($get(%SourceControl)) {
			Set item=$Order(classes(""))
			While item'="" {
				Do
				. $$$SuspendErrorCount
				. Set tmp=%SourceControl New %SourceControl
				. Set rc=tmp.OnAfterCompile(item_".CLS")
				If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
				Set item=$Order(classes(item))
			}
		}
	}
	#; Then compile the MAC types
	Set item=""
	For  {
		Set item=$order(itemlist("MAC",item)) Quit:item=""
		If $isobject($get(%SourceControl)) {
			Do
			. $$$SuspendErrorCount
			. Set tmp=%SourceControl New %SourceControl
			. Set rc=tmp.OnBeforeCompile(item_"."_$zconvert(itemlist("MAC",item),"U"),.qstruct)
			If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc) Kill itemlist("MAC",item) Continue
		}
		Set rtnlist(item_"."_$zconvert(itemlist("MAC",item),"U"))=""
	}
	Set rc=$$CompileList^%apiRTN(.rtnlist,.qstruct) Kill rtnlist
	If $$$ISERR(rc) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstructa) Set:$$$ISOK(sc) sc=rc
	Set item=""
	For  {
		Set item=$order(itemlist("MAC",item)) Quit:item=""
		If $isobject($get(%SourceControl)) {
			Do
			. $$$SuspendErrorCount
			. Set tmp=%SourceControl New %SourceControl
			. Set rc=tmp.OnAfterCompile(item_"."_$zconvert(itemlist("MAC",item),"U"))
			If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
		}
	}
	#; Compile any CSR pages
	Set item=""
	For {
		Set item=$Order(itemlist("CSR",item)) Quit:item=""
		Set name=$select($extract(item)="/":item,1:"/"_item)
		Set rc=$$$OK
		If $isobject($get(%SourceControl)) Do
		. $$$SuspendErrorCount
		. Set tmp=%SourceControl New %SourceControl
		. Set rc=tmp.OnBeforeCompile(name,.qstruct)
		If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc) Continue
		Set rc=$$LoadRuleFile^%apiCSP(name,.qstruct)
		If $$$ISERR(rc) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstructa) Set sc=$$$ADDSC(sc,rc)
		Set rc=$$$OK
		If $isobject($get(%SourceControl)) Do
		. $$$SuspendErrorCount
		. Set tmp=%SourceControl New %SourceControl
		. Set rc=tmp.OnAfterCompile(name)
		If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
	}
	#; Compile any CSP pages
	Kill classlist
	Set item=""
	For {
		Set item=$Order(itemlist("CSP",item)) Quit:item=""
		Set name=$select($extract(item)="/":item,1:"/"_item)
		Set rc=$$$OK
		If $isobject($get(%SourceControl)) Do
		. $$$SuspendErrorCount
		. Set tmp=%SourceControl New %SourceControl
		. Set rc=tmp.OnBeforeCompile(name,.qstruct)
		If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc) Continue
		Set rc=$$LoadPage^%apiCSP(name,.qstructb,.classname)
		If $$$ISERR(rc) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstructa) Set sc=$$$ADDSC(sc,rc)
		Set rc=$$$OK
		If $get(classname)'="" Set classlist(classname)=name
		If $get(classname)="",$isobject($get(%SourceControl)) Do
		. $$$SuspendErrorCount
		. Set tmp=%SourceControl New %SourceControl
		. Set rc=tmp.OnAfterCompile(name)
		If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
	}
	#; Handle classes from CSP compiles
	If $data(classlist) {
		Set rc=$$CompileList^%occCompile(.classlist,.qstruct,.%errorlog,.updClsList)
		If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
		If $isobject($get(%SourceControl)) {
			Set item=$Order(classlist(""),1,name)
			While item'="" {
				Do
				. $$$SuspendErrorCount
				. Set tmp=%SourceControl New %SourceControl
				. Set rc=tmp.OnAfterCompile(name)
				If $$$ISERR(rc) Set errcount=$get(%errorlog) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) $$$IncErrorNums(%errorlog-errcount) Set sc=$$$ADDSC(sc,rc)
				Set item=$Order(classlist(item),1,name)
			}
		}
		
	}
	#; Compile any other items
	Set type=$order(itemlist(""))
	While type'="" {
		If ",CSP,CSR,MAC,CLS,INT,PRJ,GBL,PKG,INC,OBJ,DIR,"'[(","_type_",") {
			Set item=$order(itemlist(type,""))
			While item'="" {
				Set rc=..compileUserType(item_"."_type,.qstruct)
				If $$$ISERR(rc) Do DecomposeStatus^%occSystem(rc,.%errorlog,.qstruct) If $$$ISOK(sc) Set sc=rc
				Set item=$order(itemlist(type,item))
			}
		}
		Set type=$order(itemlist(type))
	}
	#; Add class suffix to updated class names
	Set item=""
	For  Set item=$O(updClsList(item),1,tmp) Quit:item=""  Set updatedlist(item_".cls")=tmp
	Quit sc
}

ClassMethod compileUserType(name As %String, ByRef qstruct As %String) As %Status [ Private ]
{
	Set rc=$$$OK,sc=$$$OK
	If $isobject($get(%SourceControl)) Do
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnBeforeCompile(name,.qstruct)
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	Set $ztrap="trap"
	If $$$ISOK(rc) {
		If ##class(%RoutineMgr).UserType(name,.cls) {
			Set rtn=$classmethod(cls,"%New",name)
			If rtn="" {
				Set rc=$select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$RoutineDoesNotExist,name))
			} Else {
				Set rc=rtn.Compile(.qstruct)
			}
		} Else {
			Set rc=$$$ERROR($$$ImportUserItemNotPresent,name)
		}
	}
	If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	Set rc=$$$OK
afterCompile	Set $ztrap=""
	If $isobject($get(%SourceControl)) Do
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnAfterCompile(name)
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	Quit sc
trap	Set $ztrap=""
	Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	Goto afterCompile
}

/// Export this project in XML format to the <var>filename</var>.<p>
/// If the <var>justproject</var> is true then it will only export the project
/// definition, but not any items in this project, otherwise the default behavour
/// is to export all the items in the project to the same XML file.<p>
/// The <var>qspec</var> are the standard cache objects qualifiers.<p>
Method Export(ByRef filename As %String, qspec As %String, justproject As %Boolean, ByRef %errorlog As %String, Charset As %String = "", ShowFilename As %Boolean = 1) As %Status
{
	#; Must make sure the project is up to date before exporting it.
	Set sc=$$$qualifierParseAlterDefault("Export","/norecursive",.qspec,.qstruct) q:$$$ISERR(sc) sc
	If $extract($zconvert(i%Name,"l"),1,$length("default_"))="default_" Quit $$$ERROR($$$CanNotExportDefaultProject,i%Name)
	If $Get(justproject) {
		Quit ..ExportList(.filename,i%Name_".PRJ",.qstruct,Charset,ShowFilename)
	} Else {
		Set item=""
		#; Create list of items in this project.
		Set itemobj=..Items.GetNext(.item)
		While item'="" {
			If $isobject(itemobj) {
				Set name=itemobj.Name,type=itemobj.Type
				If ##class(%RoutineMgr).Exists(name_$Select(type="CLS"||(type="PKG")||(type="DIR"):"."_type,1:"")) {
					If (type="DIR") {
						Set sc=##class(%RoutineMgr).StudioOpenDialogExecute(.QHandle,name_"/*.*",1,1,0,1,,,"")
						If $$$ISERR(sc) Quit
						Set idx=$list(QHandle)
						Set itemS=$order(^||%RoutineList(idx,1,""),1,data)
						While itemS'="" {
							Set list($lg(data,1))=""
							Set itemS=$order(^||%RoutineList(idx,1,itemS),1,data)
						}
						Kill ^||%RoutineList(idx)
					} Else {
						Set list(name_$Select(type="CLS"||(type="PKG"):"."_type,1:""))=""
					}
				}
				Do ..Items.%UnSwizzleAt(item)
			}
			Set itemobj=..Items.GetNext(.item)
		}
		If $$$ISERR(sc) Quit sc
		Set list(i%Name_".PRJ")=""
		Quit ..ExportList(.filename,.list,.qstruct,Charset,ShowFilename)
	}
}

/// Check the project so that if any items are do not exist then we will remove them from the project
Method Check() As %Status
{
	Set item="",sc=$$$OK
	#; Create list of items in this project.
	Set itemobj=..Items.GetNext(.item)
	While item'="" {
		If $isobject(itemobj) {
			Set name=itemobj.Name,type=itemobj.Type
			Set itemname=name_$Select(type="CLS"||(type="PKG")||(type="DIR"):"."_type,1:"")
			If '##class(%RoutineMgr).Exists(itemname) {
				Do ..Items.RemoveAt(item)
			} Else {
				Set sc=..Items.%UnSwizzleAt(item)
				If $$$ISERR(sc) Quit
			}
		}
		Set itemobj=..Items.GetNext(.item)
	}
	Quit sc
}

/// Package up this project into a global for deployment. This can be imported using the <method>InstallFromGbl</method>.
/// The qualifiers are used to determine if we should export selectivity information using the /exportselectivity qualifier.
/// Also the /keepsource will determine if we add intermediate compilation files such as User.Test.1.int when you are creating
/// a package containing User.Test.cls. If you pass removesource=1 then it will strip out all source code in the package
/// including class method code, and routines.
Method DeployToGbl(gbl As %String, qspec As %String, removesource As %Boolean = 0) As %Status
{
	Quit ..Deploy("",.qspec,,,gbl,removesource)
}

/// Package up this project into a global for deployment and then export this global to the file specified.
/// This can be imported using the <method>InstallFromFile</method>.
/// The qualifiers are used to determine if we should export selectivity information using the /exportselectivity qualifier.
/// Also the /keepsource will determine if we add intermediate compilation files such as User.Test.1.int when you are creating
/// a package containing User.Test.cls. If you pass removesource=1 then it will strip out all source code in the package
/// including class method code, and routines. If the filename ends in .gz or .gzip it will automatically gzip the file.
Method DeployToFile(file As %String, qspec As %String, removesource As %Boolean = 0) As %Status
{
	Kill ^||%pkg
	Set sc=..Deploy("",.qspec,,,"^||%pkg",removesource) If $$$ISERR(sc) Goto exit
	Set sc=$$ExportXMLList^%apiOBJ("^||%pkg.gbl",file,.qspec)
exit	Kill ^||%pkg
	Quit sc
}

/// Export this project to a DAT file or a global for deployment.  The DAT file will be stored in the <var>deploydir</var>
/// directory.<p>
/// The <var>qspec</var> are the standard cache objects qualifiers.<p>
Method Deploy(ByRef deploydir As %String, qspec As %String, ByRef %errorlog As %String, ShowFilename As %Boolean = 1, gbl As %String = "", removesource As %Boolean = 0) As %Status
{
	#; Must make sure the project is up to date before exporting it.
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	If $extract($zconvert(i%Name,"l"),1,$length("default_"))="default_" Quit $$$ERROR($$$CanNotExportDefaultProject,i%Name)
	
	Set item = ""
	Kill ^||%Studio.Project.Deploy
	
	#; First, we make a list of things to deploy:
	#;    * Everything in the project
	#;    * For CSP pages, include the derived class
	#;    * If keepsource is enabled, also include INT and MAC routines derived from classes
	#;    * Globals derived from the selected classes (including classes derived from CSP pages)
	#; This list maybe rather large, so use ^||%Studio.Project.Deploy to build it
	Set itemobj = ..Items.GetNext(.item)
	While item '= "" {
		Set name = itemobj.Name
		Set type = itemobj.Type
		
		// Convert CSP files into the underlying class name
		Set:type="CSP" name = $$CSPClassName^%apiCSP(name,"/"), type = "CLS"
		
		// For some historical reason, INC, INT and MAC are all marked as type MAC
		If type="MAC" {
			Set type = $P(name,".",*)
		}
		
		// Split the type off the end of the name for items that are NOT classes or packages
		If type'="PKG",type'="CLS" Set name = $P(name,".",1,*-1)
		If type="PKG" {
			Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct)
			Set clslist=""
			For  {
				Set clslist=$order(clslist(clslist)) Quit:clslist=""
				Do ..addclass(clslist)
			}
		} ElseIf type="DIR" {
			Set rs=##class(%ResultSet).%New("%Library.RoutineMgr:StudioOpenDialog")
			Do rs.Execute(name_"/*.cspall,*.csp,*.csr",1,1,1,1)
			While rs.Next() {
				Set name1=rs.Data("Name")
				If $length(name1,".")=1 Set name1=name1_".csp"
				Set newtype1=$zconvert($piece(name1,".",*),"U")
				If newtype1="CSP"||(newtype1="CSR") Set ^||%Studio.Project.Deploy(newtype1,name1)=""
			}
			Set rs=""
		} ElseIf type="CLS" {
			Do ..addclass(name)
		} ElseIf name'="" {
			Set ^||%Studio.Project.Deploy(type,name)=##class(%RoutineMgr).Exists(name_"."_type)
		}
		Do ..Items.%UnSwizzleAt(item)
		Set itemobj=..Items.GetNext(.item)
	}
	
	#; Expand the list of classes to include derived ones
	Set class = ""
	For {
		Set class = $Order(^||%Studio.Project.Deploy("CLS",class)) Quit:class=""
		Set sc=$$DeployRef^%occMain(class,.qstruct,.cls,,,,,,,1) If $$$ISERR(sc) Quit
	}		
	If $$$ISERR(sc) Quit sc
	For i=1:1 {
		If '$data(cls(i),class) Quit
		If '$data(^||%Studio.Project.Deploy("CLS",class)) {
			Set ^||%Studio.Project.Deploy("CLS",class)=""
			Set sc=$$DeployRef^%occMain(class,.qstruct,.cls,,,,,,,1) If $$$ISERR(sc) Quit
		}
	}
	If $$$ISERR(sc) Quit sc
	
	// Next, ensure that we have .OBJ files for any INT/MAC routines specified
	For ext="MAC","INT" {
		Set name = ""
		For {
			Set name = $Order(^||%Studio.Project.Deploy(ext,name))
			Quit:name=""
			
			// For MAC routines, if keepsource is specified, then add the INT
			If ext="MAC",$$$qualifierGetValue(qstruct,"keepsource"),'removesource {
				Set:$D(^ROUTINE(name)) ^||%Studio.Project.Deploy("INT",name)=""
			}
	
			// For ALL routines, make sure we grab the compiled object code
			// (there's little point in having an INT without the OBJ)
			If $data(^rOBJ(name)) {
				Set ^||%Studio.Project.Deploy("OBJ",name)=""
			} ElseIf removesource {
				Set sc=$$$ERROR($$$DplyNoOBJ,name) Quit
			}
		}
		If $$$ISERR(sc) Quit
	}
	If $$$ISERR(sc) Quit sc
	If removesource Kill ^||%Studio.Project.Deploy("INT"),^("MAC")
	
	If gbl'="" {
		Set sc= ..deployGbl(gbl,.qstruct,removesource)
	} Else {

		// Ok, now let's go and export this stuff!
		Set sc = ..createDatabase(.deploydir,.qstruct)
		If $$$ISOK(sc) {
			Set sc = ..deployToDatabase(.deploydir,.qstruct,removesource)
			
			// Finally, dismount the DB
			Set rc=$Zutil(3,deploydir)  ; There's no Dismount^%SYS.DATABASE()
		}
	}
	
	Kill ^||%Studio.Project.Deploy
	
	Quit sc
}

Method addclass(classname As %String) [ Internal, Private ]
{
	Set exists=##class(%RoutineMgr).Exists(classname_".cls")
	Set ^||%Studio.Project.Deploy("CLS",classname)=exists

	Set manifest=""
	For {
		Set manifest=$$$comClassArrayNext(classname,$$$cCLASSmanifest,manifest) Quit:manifest=""
		Set name=$piece(manifest,".",1,*-1),type=$zconvert($piece(manifest,".",*),"U")
		If name'="",type'="" Set ^||%Studio.Project.Deploy(type,name)=exists
	}
}

Method createDatabase(ByRef deploydir As %String, ByRef qstruct As %String) As %Status [ Private ]
{
	// Delete any pre-existing database ...
	Set sc = $$DeleteDatabase^%SYS.DATABASE(deploydir)
	//Quit:$$$ISERR(sc) sc

	// Create a new database
	Set sc = $$CreateDatabase^%SYS.DATABASE(deploydir)
	Quit:$$$ISERR(sc) sc
	
	// Mount the database
	Set sc = $$MountDatabase^%SYS.DATABASE(deploydir)
	Quit:$$$ISERR(sc) sc
	

	Quit $$$OK
}

Method deployToDatabase(ByRef deploydir As %String, ByRef qstruct As %String, removesource As %Boolean = 0) As %Status [ Private ]
{
#define TAB $x+39\40*40

	Set $ZT="Trap"
	;
	Set outdir="^^"_deploydir
 	;
	Set ^|outdir|rINDEXCLASS=$ZTIMESTAMP
	Set ^|outdir|rINDEX=$ZTIMESTAMP
	;
	For tType=$$$rtnMACTypes,$$$rtnINTTypes,$$$rtnINCTypes,"OBJ" {
		Set tRtn=""
		For {
			Set tRtn=$Order(^||%Studio.Project.Deploy(tType,tRtn)) Quit:tRtn=""
			
			If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,tRtn,".",tType
			
			Merge:tType="OBJ" ^|outdir|rOBJ(tRtn)=^rOBJ(tRtn)
			Merge:$$$rtnIsINT(tType) ^|outdir|ROUTINE(tRtn)=^ROUTINE(tRtn)
			Merge:$$$rtnIsMAC(tType) ^|outdir|rMAC(tRtn)=^rMAC(tRtn)
			Merge:$$$rtnIsINC(tType) ^|outdir|rINC(tRtn)=^rINC(tRtn)
			Merge ^|outdir|rINDEX(tRtn,tType)=^rINDEX(tRtn,tType)
		}
	}
	
	Set tCls="" 
	For  {
		Set tCls=$Order(^||%Studio.Project.Deploy("CLS",tCls))
		Quit:tCls=""
		
		If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,tCls,".CLS"
		Set sc=$$DeployRef^%occMain(tCls,.qstruct,,.tbls,.gbls,.rtns,.proc,.extent,removesource) If $$$ISERR(sc) Quit
		Merge ^|outdir|DeployData("PROC",tCls)=proc
		Merge ^|outdir|DeployData("TABLE",tCls)=tbls
		Merge ^|outdir|DeployData("EXTENT")=extent
		For i=1:1:gbls {
			Set gbl=gbls(i)
			Merge @("^|"""_outdir_"""|"_$extract(gbl,2,*))=@gbl
			For j=1:1:$get(gbls(i,0)) {
				Set gbl=gbls(i,j)
				Kill @("^|"""_outdir_"""|"_$extract(gbl,2,*))
			}		
			For j=1:1:$get(gbls(i,"set")) {
				Set gbl=$list(gbls(i,"set",j)),val=$list(gbls(i,"set",j),2)
				Set @("^|"""_outdir_"""|"_$extract(gbl,2,*))=val
			}		
		}
		If removesource Set ^|outdir|oddDEF(tCls,$$$cCLASSdeployed)=1
	}
	Set ^|outdir|oddDEF=^oddDEF
 
	Set tGbl=""
	For {
		Set tGbl=$Order(^||%Studio.Project.Deploy("GBL",tGbl)) Quit:tGbl=""
		Set gbl=$select($extract(tGbl)="^":tGbl,1:"^"_tGbl)
		If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,gbl
		Merge @("^|"""_outdir_"""|"_$extract(gbl,2,*))=@gbl
	}
	
	Set ^|outdir|DeployData("FORMAT")=0
	Set ^|outdir|DeployData("VERSION")=##class(%SYSTEM.Version).GetNumber()
	Set ^|outdir|DeployData("TIME")=$ztimestamp
	Set ^|outdir|DeployData("DELIMIDS")=$$$GetDelimitedIds
	
Exit
	Quit $$$OK
Trap
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

Method deployGbl(gbl As %String, ByRef qstruct As %String, removesource As %Boolean = 0) As %Status [ Private ]
{
#define TAB $x+39\40*40

	If $data(@gbl) Quit $$$ERROR($$$DplyGblInUse,gbl)
	Set $ZT="Trap"
	Set sc=$$$OK
	Kill ^||%occMainDeployItm
	New %node Set %node=0
	For tType=$$$rtnMACTypes,$$$rtnINTTypes,$$$rtnINCTypes,"OBJ" {
		Set tRtn=""
		For {
			Set tRtn=$Order(^||%Studio.Project.Deploy(tType,tRtn),1,exists) Quit:tRtn=""
			If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,$select(exists=0:"-",1:"")_tRtn_"."_tType
			If exists=0 {
				Set @gbl@("DELETERTN",tRtn,tType)=""
			} Else {
				If tType="OBJ" {
					Merge @gbl@("rOBJ",tRtn)=^rOBJ(tRtn)
					If $data($$$SQLIndex(2,tRtn)) {
						Kill gbls
						Do addSQLIndex^%occMain(tRtn,.gbls)
						Do ..packGbls(gbl,"SQLSTMT",tRtn,.gbls)
					}
				}
				Merge:$$$rtnIsINT(tType) @gbl@("ROUTINE",tRtn)=^ROUTINE(tRtn)
				Merge:$$$rtnIsMAC(tType) @gbl@("rMAC",tRtn)=^rMAC(tRtn)
				Merge:$$$rtnIsINC(tType) @gbl@("rINC",tRtn)=^rINC(tRtn)
				Merge @gbl@("rINDEX",tRtn,tType)=^rINDEX(tRtn,tType)
			}
		}
	}
	
	Set tCls="" 
	For  {
		Set tCls=$Order(^||%Studio.Project.Deploy("CLS",tCls),1,exists) Quit:tCls=""
		If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,$select(exists=0:"-",1:"")_tCls,".cls"
		If exists=0 {
			Set @gbl@("DELETECLS",tCls)=""
		} Else {
			Set sc=$$DeployRef^%occMain(tCls,.qstruct,,.tbls,.gbls,.rtns,.proc,.extent,removesource) If $$$ISERR(sc) Quit
			Do ..packGbls(gbl,"CLS",tCls,.gbls)
			Merge @gbl@("PROC",tCls)=proc
			Merge @gbl@("TABLE",tCls)=tbls
			Merge @gbl@("EXTENT")=extent
		}
	}
	If $$$ISERR(sc) Goto Trap
 
	Set tGbl=""
	For {
		Set tGbl=$Order(^||%Studio.Project.Deploy("GBL",tGbl)) Quit:tGbl=""
		Set tgbl=$select($extract(tGbl)="^":tGbl,1:"^"_tGbl)
		If $$$qualifierGetValue(qstruct,"displaylog") Write:$x>70 ! w ?$$$TAB,$select($data(@tgbl):"",1:"-")_tgbl
		Do ..packGbls(gbl,"GBL",tGbl,tgbl)
	}
	#; Pack format
	Set @gbl@("FORMAT")=0
	Set @gbl@("VERSION")=##class(%SYSTEM.Version).GetNumber()
	Set @gbl@("TIME")=$ztimestamp
	Set @gbl@("DELIMIDS")=$$$GetDelimitedIds
	Kill ^||%occMainDeployItm
	
	Quit $$$OK
Trap	If $$$ISOK(sc) Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	Kill @gbl
	Kill ^||%occMainDeployItm
	Quit sc
}

ClassMethod packGbls(target, type, name, ByRef gbls) [ Internal ]
{
	If $data(gbls)\10=0 Set gbls(1)=gbls,gbls=1
	For i=1:1:gbls {
		If '$data(gbls(i),gbl) Continue
		Set %node=$increment(%node)
		Set @target@(type,name,%node)=gbl
		Merge @target@(%node)=@gbl
		For j=1:1:$get(gbls(i,0)) {
			Set removegbl=gbls(i,j)
			If target["(" {
				Set ref=$extract(target,1,*-1)_","_%node_","_$extract(removegbl,$length(gbl)+1,*)
			} Else {
				Set ref=target_"("_%node_","_$extract(removegbl,$length(gbl)+1,*)
			}
			Kill @ref
		}
		For j=1:1:$get(gbls(i,"set")) {
			Set tmp=gbls(i,"set",j),setgbl=$list(tmp),val=$list(tmp,2)
			If target["(" {
				Set ref=$extract(target,1,*-1)_","_%node_","_$extract(setgbl,$length(gbl)+1,*)
			} Else {
				Set ref=target_"("_%node_","_$extract(setgbl,$length(gbl)+1,*)
			}
			Set @ref=val
		}
	}
}

/// Backup the items that will be replaced when installing a deployed set of items to <var>backupgbl</var>
ClassMethod BackupDeployContent(gbl As %String, backupgbl As %String, qspec As %String) As %Status
{
	Set sc=..InstallFromGbl(gbl,.qspec,0,.project,1) If $$$ISERR(sc) Quit sc
	Set sc=project.Check() If $$$ISERR(sc) Quit sc
	Set sc=project.DeployToGbl(backupgbl,.qspec) If $$$ISERR(sc) Quit sc
	Quit $$$OK
}

/// This will install any routines, classes and globals into the current namespace
/// from a file created with the <method>DeployToFile</method>. The qualifiers respects the
/// /importselectivity item to determine of we should import selectivity information from this package.
/// If you pass in a %Studio.Project in <var>project</var> then this will be returned with all the items
/// in the deployment in <var>gbl</var> added to the project. If <var>listonly</var> is true then nothing
/// will be actually changed in the database, so you can list items. If <var>runinstall</var> is false then
/// if the deployment contains a routine called 'INSTALL' (note not in the database, but in the deployment)
/// then we will not automatically run this after installing the items in this deployment. The default
/// is to run the INSTALL routine if present.
ClassMethod InstallFromFile(file As %String, qspec As %String, runinstall As %Boolean = 1, ByRef project As %Studio.Project, listonly As %Boolean = 0, backupgbl As %String = "", validatesig As %Boolean = 0, transaction As %Boolean = 1)
{
	Kill ^||%pkg
	Set sc=$$Load^%apiOBJ(file,.qspec,,.imported,0,"||%pkg.gbl") If $$$ISERR(sc) Quit sc
	If '$data(^||%pkg) Quit $$$ERROR($$$DplyBadFile,file)
	Set sc=..InstallFromGbl("^||%pkg",.qspec,.runinstall,.project,.listonly,.backupgbl,.validatesig,.transaction)
	Kill ^||%pkg
	Quit sc
}

/// This will install any routines, classes and globals into the current namespace
/// from a global created with the <method>DeployToGbl</method>. The qualifiers respects the
/// /importselectivity item to determine if we should import selectivity information from this package.
/// If you pass in a %Studio.Project in <var>project</var> then this will be returned with all the items
/// in the deployment in <var>gbl</var> added to the project. If <var>listonly</var> is true then nothing
/// will be actually changed in the database, so you can list items. If <var>runinstall</var> is true then
/// if the deployment contains a routine called 'INSTALL' (note not in the database, but in the deployment)
/// then we will automatically run PRE^INSTALL before the installation and ^INSTALL after installing the items
/// in this deployment. The default is to run the INSTALL routine if present.
/// If <var>backupgbl</var> is defined then any items which will
/// be replaced by items in the package are backed up to this global location first. Also if the deployment contains
/// an INSTALL routine then this will be placed in the backup as UNINSTALL, and if the deployment contains an UNINSTALL
/// routine this will be placed in the backup as INSTALL. So when the backup is installed (do you uninstall this deployment)
/// it will run the PRE^UNINSTALL routine of the original deployment and after it is uninstalled it will run ^UNINSTALL.
/// If <var>transaction</var> is false then we will not use a transaction to allow rolling back the install. If <var>validatesig</var>
/// is true we will validate any code being replaced is the original version installed from InterSystems.
ClassMethod InstallFromGbl(gbl As %String, qspec As %String, runinstall As %Boolean = 1, ByRef project As %Studio.Project, listonly As %Integer = 0, backupgbl As %String = "", validatesig As %Boolean = 0, transaction As %Boolean = 1)
{
	Set sc=$$$OK,installitem=""
	If backupgbl'=""||(validatesig)||(listonly) {
		Set sc=..internalInstall(gbl,.qspec,0,.items,$select(validatesig:2,1:1),.transaction) If $$$ISERR(sc) Quit sc
	}
	If backupgbl'="" {
		Set tmpprj=##class(%Studio.Project).%New()
		Set item=""
		For {
			Set item=$order(items(item)) Quit:item=""
			#; Never backup the install item as this is only valid after loading from the install package
			If $length(item,".")=2,$piece(item,".")="INSTALL"||($piece(item,".")="UNINSTALL") Set installitem=installitem_$lb(item) Continue
			Set rc=tmpprj.AddItem(item)
		}
		Set sc=tmpprj.DeployToGbl(backupgbl,.qspec) If $$$ISERR(sc) Quit sc
		#; Now add the INSTALL as UNINSTALL and visa versa in the backup
		For name="INSTALL","UNINSTALL" {
			Set altname=$select(name="INSTALL":"UNINSTALL",1:"INSTALL")
			For node="rOBJ","ROUTINE","rMAC" {
				Merge @backupgbl@(node,name)=@gbl@(node,altname)
				Set type=$select(node="rOBJ":"OBJ",node="ROUTINE":"INT",1:"MAC")
				Merge @backupgbl@("rINDEX",name,type)=@gbl@("rINDEX",altname,type)
			}
		}
		
	}
	If 'listonly {
		Kill items
		Set sc=..internalInstall(gbl,.qspec,.runinstall,.items,0,.transaction)
	}
	Set addprj=$isobject($get(project))
	If listonly,'addprj {
		If $isobject($get(tmpprj)) {
			For i=1:1:$ll(installitem) Set rc=tmpprj.AddItem($list(installitem,i))
			Set project=tmpprj
		} Else {
			Set project=##class(%Studio.Project).%New(),addprj=1
		}
	}
	If addprj {
		Set item=""
		For {
			Set item=$order(items(item)) Quit:item=""
			Set rc=project.AddItem(item) If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
		}
	}
	Quit sc
}

ClassMethod internalInstall(gbl As %String, qspec As %String, runinstall As %Boolean = 1, ByRef items As %String, listonly As %Integer = 0, transaction As %Boolean = 1) [ Internal, Private ]
{
#define TAB $x+39\40*40
	$$$InitISCName
	$$$ResetAllTemp
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstructo) Quit:$$$ISERR(sc) sc
	Set sc=$$$qualifierAmend("Compiler",.qstructo,"-d",.qstruct) q:$$$ISERR(sc) sc
	Kill $$$tCLSQUALIFIERS Merge $$$tCLSQUALIFIERS=qstruct
	Set format=$get(@gbl@("FORMAT"))
	Set clscnt=0
	If format="" Set sc=$$$ERROR($$$DplyFormat)
	If $$$ISOK(sc),format'=0 Set sc=$$$ERROR($$$DplyFormatType,format)
	If $$$ISOK(sc),$piece(##class(%SYSTEM.Version).GetNumber(),".",1,2)'=$piece($get(@gbl@("VERSION")),".",1,2) {
		If $piece($get(@gbl@("VERSION")),".",1,2)<2013.1||($piece(##class(%SYSTEM.Version).GetNumber(),".",1,2)<$piece($get(@gbl@("VERSION")),".",1,2)) Set sc=$$$ERROR($$$DplyVersion,$get(@gbl@("VERSION")),##class(%SYSTEM.Version).GetNumber())
	}
	If $$$ISOK(sc),$data(@gbl@("DELIMIDS"),tmp),tmp'=$$$GetDelimitedIds Set sc=$$$ERROR($$$DplyDelimId,$get(@gbl@("DELIMIDS")),$$$GetDelimitedIds)
	If $$$ISERR(sc) {
		If $$$qualifierGetValue(qstructo,"displaylog") Do DisplayError^%apiOBJ(sc)
		Quit sc
	}
	#; If there is an install routine then run it
	If runinstall,'listonly,$data(@gbl@("rOBJ","INSTALL")) {
		Merge ^rOBJ("INSTALL")=@gbl@("rOBJ","INSTALL"),^rINDEX("INSTALL","OBJ")=@gbl@("rINDEX","INSTALL","OBJ")
		Try {
			Do PRE^INSTALL
		} Catch {}
	}
	
	If transaction TStart
	#; Change batch mode for this job
	Set batch=$zutil(68,25,1)
	
	Set $ztrap="exit"

	Set oldconcurrency=$zutil(115,10)

	#; Delete any classes first
	Set cls=""
	For {
		Set cls=$order(@gbl@("DELETECLS",cls)) Quit:cls=""
		Set items(cls_".CLS")=""
		If listonly {
			If listonly=2 {
				Set sc=$$ValidateClassRoutines^%occClass(cls)
				If $$$ISERR(sc) Goto exit
			}
		} ElseIf $$$defClassDefined(cls) {
			Set clslist(cls)=""
		}
	}
	If $data(clslist) Set sc=$$Delete^%apiOBJ(.clslist,.qstructo,,1) If $$$ISERR(sc) Goto exit

	#; Take care of the classes
	Set cls=""
	For clscnt=1:1 {
		Set cls=$order(@gbl@("CLS",cls)) Quit:cls=""
		Set items(cls_".CLS")=""
		If listonly {
			If listonly=2 {
				Set sc=$$ValidateClassRoutines^%occClass(cls)
				If $$$ISERR(sc) Goto exit
			}
		} Else {
			Set sc=$$IsClassnameConflict^%occName(cls) If $$$ISERR(sc) Goto exit
			Set sc=$$LockOneClass^%occLock(cls,0,1) If $$$ISERR(sc) Goto exit
			Set locked(cls)=""
			If $$$defClassDefined(cls) Do SaveLocalSettings^%occStorage(cls,.qstructo,1)
			Set sc=$$deleteruntime^%occClass(cls,$name(^||%Studio.Project.tmp),1,.routines,.qstruct) If $$$ISERR(sc) Goto exit
		}
	}
	If 'listonly {
		#; We need to delete the classes first before merging in the new data else a delete of one class can modify ^oddEXTR in another class
		#; we have just merged the data over for
		Set cls=""
		For {
			Set cls=$order(@gbl@("CLS",cls)) Quit:cls=""
			Set rc=$$LockOneClass^%occLock(cls,-2,0)
			If $$$ISERR(rc) Set rc=$$$EMBEDERROR(rc,$$$ErrorCompilingClass,cls) Goto exit
			If $$$qualifierGetValue(qstructo,"displaylog") Write:$x>70 ! w ?$$$TAB,cls,".cls"
			Set rtn=""
			For {
				Set rtn=$order(routines(cls,rtn)) Quit:rtn=""
				Do Delete^%apiRTN(rtn_".MAC",0,0,0,0)
			}
			Set i=""
			For {
				Set i=$order(@gbl@("CLS",cls,i),1,node) Quit:i=""
				#; Check if we have any globals we would overwrite, if we do this is an error unless the data is identical
				#; ^oddCOM, ^oddEXTR, ^oddSQL are going to be present due to the temp drop of the table, so we do not want to verify data on import for these
				If $data(@node),node'["^oddCOM(",node'["^oddEXTR(",node'["^oddSQL(",node'["^rINDEXSQL",node'["^rOBJ" {
					Set sc=$$mergesame^%occMain(node,$name(@gbl@(i)))
					If $$$ISERR(sc) {
						Set sc=$$$EMBEDERROR(sc,$$$DplyGblNode,cls)
						Do UnlockOneClass^%occLock(cls,-2,0)
						Goto exit
					}
				} Else {
					Merge @node=@gbl@(i)
				}
			}
			Do RestoreLocalSettings^%occStorage(cls,.qstructo,1)
			Do RebuildItemIndex^%R(cls,"CLS")
			Do UnlockOneClass^%occLock(cls,-2,0)
		}
		#; We need to do this after all classes are imported to avoid interclass dependency issues
		Set cls=""
		For {
			Set cls=$order(@gbl@("CLS",cls)) Quit:cls=""
			#; Fix up class information, includes restoring local settings
			Set sc=$$Fixup^%occMain(cls,.qstructo,gbl) If $$$ISERR(sc) Goto exit
			Set sc=$$UnlockOneClass^%occLock(cls,0,1) If $$$ISERR(sc) Goto exit
			Kill locked(cls)
		}
	}
	
	#; Delete the routines in both deleted set and ones to be replaced
	For node="DELETERTN","rINDEX" {
		Set rtn=""
		For {
			Set rtn=$order(@gbl@(node,rtn)) Quit:rtn=""
			Set type=""
			For {
				Set type=$order(@gbl@(node,rtn,type)) Quit:type=""
				Set items(rtn_"."_type)=""
				If listonly {
					If listonly=2 {
						Set sc=$$VerifySig^%occLibrary(rtn)
						If $$$ISERR(sc) Goto exit
					}
				} Else {
					If $$$qualifierGetValue(qstructo,"displaylog") Write:$x>70 ! w ?$$$TAB,$select(node="DELETERTN":"-",1:"")_rtn_"."_type
					If $data(^rINDEX(rtn,type)) {
						If node="rINDEX" {
							// For existing routines that are being replaced, do not
							// delete the object code now
							If $data(^rOBJ(rtn)) Set objs(rtn)=""
							If type'="OBJ" {
								Set sc=$$Delete^%apiRTN(rtn_"."_type,,2) If $$$ISERR(sc) Goto exit
							}
						} Else {
							Set sc=$$Delete^%apiRTN(rtn_"."_type,,0) If $$$ISERR(sc) Goto exit
						}
					}
				}
			}
		}
	}

	If 'listonly,$$$qualifierGetValue(qstructo,"displaylog") Write !

	#; Now update the routines, we already removed the destinations
	If 'listonly {
		For node="rOBJ","ROUTINE","rMAC","rINC","rINDEX" {
			If $$$qualifierGetValue(qstructo,"displaylog"),$data(@gbl@(node)) Write:$x>70 ! w ?$$$TAB,"^",node
			If node="rOBJ" {
				Set name=""
				For {
					Set name=$order(@gbl@("rOBJ",name)) Quit:name=""
					Set rc=$compile(i,127,i,@gbl@("rOBJ",name),,,name)
					Kill objs(name)
					Merge @("^"_node)@(name,"INT")=@gbl@("rOBJ",name,"INT")
				}
			} Else {
				Merge @("^"_node)=@gbl@(node)
			}
		}
		#; If any more that didn't get replaced (shouldn't happen?)
		Set name=""
		For  Set name=$order(objs(name)) Quit:name=""  Kill ^rOBJ(name)
		#; Update any SQL statement index entries
		Set name=""
		For {
			Set name=$order(@gbl@("SQLSTMT",name)) Quit:name=""
			Set i=""
			For {
				Set i=$order(@gbl@("SQLSTMT",name,i),1,node) Quit:i=""
				Merge @node=@gbl@(i)
			}
		}
	}
	
	#; Update the globals
	Set name=""
	For {
		Set name=$order(@gbl@("GBL",name)) Quit:name=""
		Set i=""
		For {
			Set i=$order(@gbl@("GBL",name,i),1,node) Quit:i=""
			Set items($zstrip(name_".GBL","<","^"))=""
			If listonly Continue
			If $$$qualifierGetValue(qstructo,"displaylog") Write:$x>70 ! w ?$$$TAB,$select($data(@gbl@(i)):"",1:"-")_node
			Kill @node
			Merge @node=@gbl@(i)
		}
	}
	
	If transaction TCommit
	#; If there is an install routine then run it
	If runinstall,'listonly,$data(@gbl@("rOBJ","INSTALL")) Do ^INSTALL
	#; If we installed a few classes reset the routine/class per process cache values as a install can mess with these
	Do resetCache^%qarmac()
	If $get(oldconcurrency)'="" Do $zutil(115,10,oldconcurrency)
	Do $zutil(68,25,batch)
	Quit $$$OK
exit	Set $ztrap="exit2"
	Kill $$$tSUPERTREEall
	$$$ResetAllTemp
	If $$$ISOK(sc) Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	If $$$qualifierGetValue(qstructo,"displayerror") Write ! Do DisplayError^%apiOBJ(sc)
	If $data(locked) {
		Set cls="" For  Set cls=$order(locked(cls)) Quit:cls=""  Do UnlockOneClass^%occLock(cls,0,1)
	}
exit2	Set $ztrap=""
	If transaction TRollback
	If $get(oldconcurrency)'="" Do $zutil(115,10,oldconcurrency)
	If $get(batch)'="" Do $zutil(68,25,batch)
	Quit sc
}

/// Wrapper to <method>Deploy</method> which returns a binary stream in <property>Stream</property>
/// rather than writing to a file.
Method DeployToStream(qspec As %String, ByRef %errorlog As %String) As %Status
{
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct) q:$$$ISERR(sc) sc
	#; Get rid of any old stream first
	Do ..Stream.Clear()
	
	Set dir=$P(##class(%FileBinaryStream).NewFileName("dat"),".")
	Set dir=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_dir
	
	If '##class(%File).DirectoryExists(dir) Do ##class(%File).CreateDirectory(dir)
	Set dir=##class(%File).NormalizeDirectory(dir)
	
	Set rc=..Deploy(.dir,.qstruct,.%errorlog,0)
	
	#; Match up our filestream to the file we just produced
	Do ..Stream.LinkToFile(dir_$$$UCFILENAME_".DAT")
	Quit rc
}

/// Wrapper to <method>Export</method> which returns a stream in <property>Stream</property>
/// rather than writing to a file.
Method ExportToStream(qspec As %String, justproject As %Boolean, ByRef %errorlog As %String, file As %String = "", Charset As %String = "") As %Status
{
	Set sc=$$$qualifierParse("Export",.qspec,.qstruct) q:$$$ISERR(sc) sc
	#; Get rid of any old stream first
	Do ..Stream.Clear()
	Set file=$piece(file,"/",*),file=$piece(file,"\",*),file=$piece(file,"]",*)
	If file=""||(##class(%File).Exists(file)) {
		Set file=$select(file[".":$piece(file,".",*),1:"")
		If file="" Set file="xml"
		Set file=##class(%FileBinaryStream).NewFileName(file)
	}
	Set file=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_file
	Set rc=..Export(file,.qstruct,justproject,.%errorlog,Charset,0)
	#; Match up our filestream to the file we just produced
	Do ..Stream.LinkToFile(file)
	Quit rc
}

/// This will try and set the <property>Stream</property> to point to the filename <var>file</var>.
/// This is used by the Studio so the Import method shows the filename the user expects.
Method SetStreamName(file As %String = "") As %Status
{
	Do ..Stream.Clear()
	Set ..StreamName=file
	Set file=$piece(file,"/",*),file=$piece(file,"\",*),file=$piece(file,"]",*)
	If file=""||(##class(%File).Exists(file)) {
		Set file=$select(file[".":$piece(file,".",*),1:"")
		If file="" Set file="xml"
		Set file=##class(%FileBinaryStream).NewFileName(file)
	}
	Set file=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_file
	Do ..Stream.LinkToFile(file)
	Quit $$$OK
}

/// Return the name of the stream. Used by Studio because it can not access the Stream
/// property directly
Method GetStreamName() As %String
{
	Do ..Stream.Rewind()
	Quit ..Stream.Filename
}

/// Export a <var>list</var> of items to the <var>filename</var> specified. The list can either be
/// comma delimited such as 'TEST.MAC,Example.CLS,/csp/samples/loop.csp' or a subscripted array
/// with the first subscript being the name of the item to export. The <var>qspec</var> are the standard 
/// ObjectScript qualifiers, if the "d" is passed then it will output status information to the current
/// device.
ClassMethod ExportList(ByRef filename As %String, ByRef list As %String, qspec As %String, Charset As %String = "", ShowFilename As %Boolean = 1) As %Status
{
	Set filename=##class(%File).NormalizeFilename(filename)
	Set sc=$$$qualifierParseAlterDefault("Export","/norecursive",.qspec,.qstruct) q:$$$ISERR(sc) sc
	Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
	If $$$qualifierGetValue(qstruct,"displaylog") {
		Write !,$$$GetSimpleMessage("%Compiler","ExportXMLStart")_$zdt($horolog)
	}
	Do AddPackageClasses^%apiOBJ(.list,.qstruct)
	If $$$qualifierGetValue(qstruct,"recursive") {
		Set sc=$$GetRecursiveExportList^%apiOBJ(.list,.qstruct)
		If $$$ISERR(sc) Do DecomposeStatus^%occSystem(sc,.errorlog,.qstruct) Quit sc
	}	
	Set status=$$Export^%occXMLExport(filename,.qstruct,.list,Charset)
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(status) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(status) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
		If ShowFilename Write "  File "_filename,!
	}
	Quit status
}

/// Wrapper to <method>ExportList</method> which returns a stream in <property>Stream</property>
/// rather than writing to a file.
Method ExportListToStream(ByRef list As %String, qspec As %String, file As %String = "", Charset As %String = "") As %Status
{
	#; Get rid of any old stream first
	Set sc=$$$qualifierParse("Export",.qspec,.qstruct) q:$$$ISERR(sc) sc
	Do ..Stream.Clear()
	Set file=$piece(file,"/",*),file=$piece(file,"\",*),file=$piece(file,"]",*)
	If file=""||(##class(%File).Exists(file)) {
		Set file=$select(file[".":$piece(file,".",*),1:"")
		If file="" Set file="xml"
		Set file=##class(%FileBinaryStream).NewFileName(file)
	}
	Set file=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_file
	Set rc=..ExportList(file,.list,.qstruct,Charset,0)
	#; Match up our filestream to the file we just produced
	Do ..Stream.LinkToFile(file)
	Quit rc
}

/// Import the XML description of routines, classes, CSP files, and projects into this namespace.
/// This returns the list of items imported in <var>imported</var> separated by commas.
/// You can pass in the <var>qspec</var> to tell it if it should compile these imported elements as well.
/// If <var>listonly</var> is true then it will just return the list of items to import and not
/// import anything. <var>selecteditems</var> is an optional comma separated list of items, if present
/// then it will only import these items and it will skip any item not in this list.
/// The <var>filename</var> may be a comma separated list of files.
ClassMethod Import(filename As %String, qspec As %String, ByRef %errorlog As %String, ByRef imported As %String, listonly As %Boolean = 0, selecteditems As %String = "", displayname As %String) As %Status [ CodeMode = expression ]
{
$System.OBJ.Load(filename,.qspec,.%errorlog,.imported,.listonly,.selecteditems,.displayname)
}

/// Wrapper to <method>Import</method> which is passed a stream in <property>Stream</property>
/// rather than a file.
Method ImportFromStream(qspec As %String, ByRef %errorlog As %String, ByRef imported As %String, listonly As %Boolean = 0, selecteditems As %String = "") As %Status
{
	If ..Stream=""||(..Stream.Filename="") Quit $$$ERROR($$$ProjectNoStream)
	Do ..Stream.Rewind()
	Set rc=..Import(..Stream.Filename,.qspec,.%errorlog,.imported,.listonly,.selecteditems,..StreamName)
	Do ..Stream.Clear()
	Quit rc
}

/// Wrapper to ExportCDLList^%apiOBJ which returns a stream in <property>stream</property>
/// rather than writing to a file. You pass this a comma separated list of classes, or an
/// array subscripted by the class name. The <var>file</var> is the filename to output this
/// to without the directory.
Method ExportCDLToStream(classname As %String = "", qspec As %String = "", file As %String = "", Charset As %String = "") As %Status
{
	Quit $$$ERROR($$$FeatureNotSupported,"CDL Export")
}

/// Wrapper to Export^%apiRTN which returns a stream in <property>stream</property>
/// rather than writing to a file. You pass this a comma separated list of routines or an
/// array subscripted by the routine name. The <var>file</var> is the filename to output this
/// to without the directory.
Method ExportRtnToStream(rtnlist As %String = "", qspec As %String = "", file As %String = "", Charset As %String = "") As %Status
{
	Do ..Stream.Clear()
	Set file=$piece(file,"/",*),file=$piece(file,"\",*),file=$piece(file,"]",*)
	If file=""||(##class(%File).Exists(file)) {
		Set file=$select(file[".":$piece(file,".",*),1:"")
		If file="" Set file="cdl"
		Set file=##class(%FileBinaryStream).NewFileName(file)
	}
	Set file=##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory())_file
	Set rc=..ExportRtn(.rtnlist,.qspec,.file,.Charset,0)
	Do ..Stream.LinkToFile(file)
	Quit rc
}

/// Wrapper to Export^%apiRTN which returns a stream in <property>stream</property>
/// rather than writing to a file. You pass this a comma separated list of routines or an
/// array subscripted by the routine name. The <var>file</var> is the filename to output this
/// to without the directory.
ClassMethod ExportRtn(rtnlist As %String = "", qspec As %String = "", file As %String = "", Charset As %String = "", ShowFilename As %Boolean = 1) As %Status
{
	Set file=##class(%File).NormalizeFilename(file)
	Set sc=$$$qualifierParse("Export",.qspec,.qstruct) q:$$$ISERR(sc) sc
	Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(file))
	If $$$qualifierGetValue(qstruct,"displaylog") {
		Write !,$$$GetSimpleMessage("%Compiler","ExportROStart")_$zdt($horolog)
	}
	Set charset=""
	If $get(Charset)'="" {
		Set charset=$$MapCharset^%SYS.NLS(Charset)
		If charset="" Quit $$$ERROR($$$CSPInvalidCharacterSet,Charset)
		If charset="RAW"||(charset=$$GetCharset^%SYS.NLS()) Set charset=""
	}
	Set rc=$$Export^%apiRTN(rtnlist,file,"WNS"_$select(charset="":"",1:"K\"_charset_"\"),,.qstruct,,$$$qualifierGetValue(qstruct,"displaylog"))
	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISERR(rc) Write !,$$$GetSimpleMessage("%Compiler","ExportErrors"),!
		If $$$ISOK(rc) Write !,$$$GetSimpleMessage("%Compiler","ExportOk"),!
		If ShowFilename Write "  File "_file,!
	}
	Quit rc
}

ClassMethod sLoadLargeList(filestream As %GlobalCharacterStream, qspec As %String, ByRef errorlog As %String, loadedliststream As %GlobalCharacterStream, listonly As %Boolean, selecteditemstream As %GlobalCharacterStream) As %Status
{
	Do ..StreamToArray(filestream,.file,"*")
	Do ..StreamToArray(selecteditemstream,.selecteditem)
	Set sc=$$Load^%apiOBJ(.file,.qspec,.errorlog,.loadedlist,.listonly,.selecteditems,.displayname)
	Do ..ArrayToStream(.loadedlist,loadedliststream)
	Quit sc
}

Method sLoadStreamLargeList(qspec As %String, ByRef errorlog As %String, loadedliststream As %GlobalCharacterStream, listonly As %Boolean, selecteditemstream As %GlobalCharacterStream) As %Status
{
	If ..Stream=""||(..Stream.Filename="") Quit $$$ERROR($$$ProjectNoStream)
	Do ..Stream.Rewind()
	Do ..StreamToArray(selecteditemstream,.selecteditems)
	Set sc=$$Load^%apiOBJ(..Stream.Filename,.qspec,.errorlog,.loadedlist,.listonly,.selecteditems,..StreamName)
	Do ..ArrayToStream(.loadedlist,loadedliststream)
	Do ..Stream.Clear()
	Quit sc
}

ClassMethod sCompileLargeList(itemliststream As %GlobalCharacterStream, qspec As %String, ByRef errorlog As %String) As %Status
{
	Do ..StreamToArray(itemliststream,.itemlist)
	Quit ##class(%SYSTEM.OBJ).CompileList(.itemlist,.qspec,.errorlog)
}

ClassMethod StreamToArray(stream As %Stream.Object, ByRef array As %String, delim As %String = ",")
{
	Do stream.Rewind()
	Set list="",start=1
next	Set list=$extract(list,start,*)_stream.Read(10000)
	Set start=1,tlist=$translate(list,delim_"()""",$char(0,0,0,0,0,0,0)),pos=1,bracket=0
loop	Set pos=$find(tlist,$char(0),pos) If 'pos Goto exit
	Set char=$extract(list,pos-1)
	If char="""" Set pos=$find(list,"""",pos) If 'pos { Goto exit } Goto loop
	If char="(" Set bracket=bracket+1 Goto loop
	If char=")" Set bracket=bracket-1 Goto loop
	If char=delim,bracket=0 Set item=$zstrip($extract(list,start,pos-2),"<>W"),start=pos If item'="" Set array(item)=""
	Goto loop
exit	If 'stream.AtEnd Goto next
	If $length(list)'<start Set item=$zstrip($extract(list,start,*),"<>W") If item'="" Set array(item)=""
}

ClassMethod ArrayToStream(ByRef array As %String, stream As %Stream.Object)
{
	Do stream.Clear()
	Set a="",first=1
	For  Set a=$order(array(a)) Quit:a=""  Do stream.Write($select(first:"",1:",")_a) Set first=0
}

/// List of all projects
Query ProjectList() As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Name,LastModified") [ SqlProc ]
{
	SELECT ID, Name, LastModified
	FROM %Studio.Project
	ORDER BY Name
}

/// List of all items for a project
Query ProjectItemsList(project As %String(MAXLEN=512), noexpandpackages As %Boolean = 0) As %Query(CONTAINID = 1, ROWSPEC = "ID,Name,Type,InSourceControl,Package,CSPApp") [ SqlProc ]
{
}

ClassMethod ProjectItemsListExecute(ByRef QHandle As %Binary, project As %String(MAXLEN=512), noexpandpackages As %Boolean = 0) As %Status
{
	If $isobject($get(%SourceControl)),%SourceControl.IconStatus#2=1 Set tmp=%SourceControl
	New %SourceControl
	Set idx=$increment($$$ISCQUERYTEMP)
	Set sc=$$$qualifierParse("Compiler","",.qstruct) Quit:$$$ISERR(sc) sc
	#; Build the temp structure with the project items in
	Set item=""
	For {
		Set item=$order(^oddPROJECT(project,"Items",item)) Quit:item=""
		Set type=""
		For {
			Set type=$order(^oddPROJECT(project,"Items",item,type)) Quit:type=""
			Set name=item_$select(type="MAC"||(type="CSP"):"",1:"."_type)
			If ((type="CSP") || (type = "DIR")),$extract(name)="/" Set name=$extract(name,2,*)
			If type="MAC",$piece(item,".",*)'=$zconvert($piece(item,".",*),"U") Set ^oddPROJECT=0 Do ..Normalize()
			If type="PKG",'noexpandpackages {
				Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,item,.qstruct)
				Set clslist=""
				For  {
					Set clslist=$order(clslist(clslist)) Quit:clslist=""
					Set row=$listbuild(project_"||"_clslist_"||CLS",clslist,"CLS",$select($get(tmp)="":0,1:tmp.ItemIconState(clslist_".CLS")),item,"")
					Set $$$ISCQUERYTEMP(idx,clslist_".CLS")=row
				}	
			}
			Set displayname=$select(type="MAC":$piece(item,".",1,*-1)_"."_$zconvert($piece(item,".",*),"l"),1:item)
			Set row=$listbuild(project_"||"_item_"||"_type,displayname,$select(type="MVB":"MAC",1:type),$select($get(tmp)="":0,1:tmp.ItemIconState(name)),"")
			If ((type="CSP") || (type="DIR")) {
				Do getapp^%SYS.cspServer("/"_item,.path)
				Set row=row_$listbuild($extract(path,2,*))
			} Else {
				Set row=row_$listbuild("")
			}
			Set $$$ISCQUERYTEMP(idx,name)=row
		}
	}
	Set QHandle=$listbuild(idx,"")
	Quit $$$OK
}

ClassMethod ProjectItemsListClose(QHandle As %Binary) As %Status
{
	#; Close the collection
	If $listget(QHandle)'="" {
		Kill $$$ISCQUERYTEMP($list(QHandle))
	}
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ProjectItemsListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..ProjectItemsListFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>ProjectItemsListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod ProjectItemsListFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	Set idx=$list(QHandle),item=$list(QHandle,2)
	Set number=0,RowSet=""
	Set item=$order($$$ISCQUERYTEMP(idx,item),1,data)
	While item'="" {
		Set RowSet=RowSet_data,number=number+1
		If number=FetchCount||($length(RowSet)>20000) Quit
		Set item=$order($$$ISCQUERYTEMP(idx,item),1,data)
	}
	If item="" {
		Set AtEnd=1,QHandle=""
		Kill $$$ISCQUERYTEMP(idx)
		Quit $$$OK
	}
	Set QHandle=$listbuild(idx,item)
	Quit $$$OK
}

/// List of all break points for a project
Query BreakPointsList(projectID As %String(MAXLEN=512)) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Routine,Offset,Condition") [ SqlProc ]
{
	SELECT ID, Routine, Offset,Condition
	FROM %Studio.BreakPoint
	WHERE Project = :projectID
}

/// List of all break points for a project
Query WatchPointsList(projectID As %String(MAXLEN=512)) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Variable,Condition") [ SqlProc ]
{
	SELECT ID, Variable, Condition
	FROM %Studio.WatchPoint
	WHERE Project = :projectID
}

/// List of all watch variables for a project
Query WatchVariablesList(projectID As %String(MAXLEN=512)) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Variable,Pane") [ SqlProc ]
{
	SELECT ID, Variable, Pane
	FROM %Studio.WatchVariable
	WHERE Project = :projectID
}

/// Find a particular string inside this project.
/// <br><var>String</var> is the string to search for.
/// The list of matches is written to the screen. If <var>WholeWords</var> is true then it will only find whole
/// words and not fragments, it defaults to false. If <var>CaseSensitive</var> is true (the default)
/// then the search is case sensitive, otherwise it is case insensitive.
/// The maximum number of matches it will find can be specified in <var>Max</var>
/// which defaults to 200. If <var>wild</var> is false then the <var>PatternList</var> does not contain
/// any wild cards and so should be treated as a string literal search even the pattern contains ?*\ characters.
Method FindInProject(String As %String, WholeWords As %Boolean = 0, CaseSensitive As %Boolean = 1, Max As %Integer = 200, wild As %Boolean = 1) As %Status
{
	New %SourceControl
	Set found=0,files=0
	Set pattern=String,attrs=""
	If WholeWords Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchWholeWords")
	If CaseSensitive Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchCase")
	Write !,$$$GetSimpleMessage("%Compiler","SearchFor")_"'"_String_"'"_$$$GetSimpleMessage("%Compiler","SearchIn")_" Project"_$select(attrs="":"",1:" ("_$extract(attrs,2,*)_")")
	Set sc=$$$qualifierParse("Compiler","r",.qstruct) Quit:$$$ISERR(sc) sc
	Set pattern=$select(CaseSensitive:pattern,1:$zconvert(pattern,"l"))
	If (wild&&(pattern["?"||(pattern["*")||(pattern["\")))||(WholeWords) {
		Set pattern=..pattern(pattern,WholeWords,.wild)
	} Else {
		Set wild=0
	}
	Set item="",items=..Items
	#; Create list of items in this project.
	Set itemobj=items.GetNext(.item)
	While item'=""&&(found<Max) {
		If $isobject(itemobj) {
			Set name=itemobj.Name,type=itemobj.Type
			if type="DIR" {
				d ..FindInFiles(String,name_"/*.*",0, WholeWords, CaseSensitive, Max , "", wild)
			}
			ElseIf type="PKG" {
				Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct)
				Set clslist=""
				For  {
					Set clslist=$order(clslist(clslist)) Quit:clslist=""
					If ..searchItem(pattern,clslist_".CLS",.found,wild,CaseSensitive,Max,String,WholeWords) Set files=files+1 If found'<Max Quit
				}
	
			} Else {
				If ..searchItem(pattern,name_$select(type="CLS":".CLS",1:""),.found,wild,CaseSensitive,Max,String,WholeWords) Set files=files+1
			}
			Do items.%UnSwizzleAt(item)
		}
		Set itemobj=items.GetNext(.item)
	}
	If found>0 {
		Write !,$$$GetSimpleMessage("%Compiler","SearchFound")_found_$$$GetSimpleMessage("%Compiler","SearchOccurrences")_files_$$$GetSimpleMessage("%Compiler","SearchFiles")
		If found'<Max Write $$$GetSimpleMessage("%Compiler","SearchMax")
		Write !
	} Else {
		Write !,$$$GetSimpleMessage("%Compiler","SearchNotFound"),!
	}
	Quit $$$OK
}

/// <p>Search a list of files or a project for a string, or using a Regular Expression. Writes matches to the current device.</p>
/// <p>Arguments:</p>
/// <ul>
/// <li><code>pQuery</code> - The string to search for, or a Regular Expression if <code>pRegex</code> is <code>1</code>.</li>
/// <li><code>pRegex</code> - If <code>1</code>, <code>pQuery</code> will be interpreted as a Regular Expression and <code>pWholeWords</code>, <code>pCaseSensitive</code>, and <code>pWildCards</code> will be ignored. Defaults to <code>0</code>.</li>
/// <li><code>pWholeWords</code> - If <code>1</code>, only whole word matches will be returned, not fragments. Ignored if <code>pRegex</code> is <code>1</code>. Defaults to <code>0</code>.</li>
/// <li><code>pCaseSensitive</code> - If <code>1</code>, the search is case sensitive. Ignored if <code>pRegex</code> is <code>1</code>. Defaults to <code>1</code>.</li>
/// <li><code>pWildCards</code> - If <code>0</code>, wild card characters <code>?*\</code> will be treated as literals. Ignored if <code>pRegex</code> is <code>1</code>. Defaults to <code>1</code>.</li>
/// <li><code>pMax</code> - The maximum number of matches to return. Defaults to <code>200</code>.</li>
/// <li><code>pProject</code> - The project to search in. If empty, <code>pDocuments</code>, <code>pSystem</code>, <code>pGenerated</code>, and <code>pMapped</code> will be used to specify the files to search.</li>
/// <li><code>pDocuments</code> - The list of files to search. See the documentation for the <code>Spec</code> parameter of the <code>StudioOpenDialog</code> query in <CLASS>%Library.RoutineMgr</CLASS> for allowed syntax. Ignored if <code>pProject</code> is not empty.</li>
/// <li><code>pSystem</code> - If <code>1</code>, system files will be searched (where source is available). Ignored if <code>pProject</code> is not empty. Defaults to <code>0</code>.</li>
/// <li><code>pGenerated</code> - If <code>1</code>, generated files will be searched. Ignored if <code>pProject</code> is not empty. Defaults to <code>0</code>.</li>
/// <li><code>pMapped</code> - If <code>1</code>, files mapped from other namespaces will be searched. Ignored if <code>pProject</code> is not empty. Defaults to <code>1</code>.</li>
/// <li><code>pIncludeRegex</code> - If a file name matches this Regular Expression, it will be included in the search. The matching is case sensitive and file names are normalized so that the first character and path separator are <code>/</code> (for example, <code>/%Api/Atelier/v6.cls</code> and <code>/csp/user/menu.csp</code>). Defaults to the empty string and no matching is done.</li>
/// <li><code>pExcludeRegex</code> - If a file name matches this Regular Expression, it will be excluded from the search. Follows the same rules as <code>pIncludeRegex</code>. Defaults to the empty string and no matching is done.</li>
/// </ul>
ClassMethod FindInFilesAtelierv6(pQuery As %String, pRegex As %Boolean = 0, pWholeWords As %Boolean = 0, pCaseSensitive As %Boolean = 1, pWildCards As %Boolean = 1, pMax As %Integer = 200, pProject As %String = "", pDocuments As %String(MAXLEN=512) = "", pSystem As %Boolean = 0, pGenerated As %Boolean = 0, pMapped As %Boolean = 1, pIncludeRegex As %String = "", pExcludeRegex As %String = "") As %Status [ Internal ]
{
	#Dim tSC As %Status = $$$OK
	#Dim tEx As %Exception.AbstractException

	Try {
		New %SourceControl
		Set (tNumFound, tNumFiles) = 0

		If pProject '= "" {
			#; Use the project contents for the initial document list

			#; Write the opening message
			Set tAttrs = ""
			If 'pRegex, pWholeWords Set tAttrs = tAttrs_","_$$$GetSimpleMessage("%Compiler","SearchWholeWords")
			If 'pRegex, pCaseSensitive Set tAttrs = tAttrs_","_$$$GetSimpleMessage("%Compiler","SearchCase")
			Write !,$$$GetSimpleMessage("%Compiler","SearchFor")_"'"_pQuery_"'"_$$$GetSimpleMessage("%Compiler","SearchIn")_"Project '"_pProject_"'"_$SELECT(tAttrs="":"",1:" ("_$EXTRACT(tAttrs,2,*)_")")

			Set tSC = ..ProjectItemsListExecute(.tQHandle,pProject)
			If $$$ISERR(tSC) Quit
			Set tPrjIdx = $LIST(tQHandle)
			Kill tQHandle
			Set tPrjItem = $ORDER($$$ISCQUERYTEMP(tPrjIdx,""),1,tPrjItemData)
			While tPrjItem '= "" {
				If $LIST(tPrjItemData,3) = "DIR" {
					Set tSC = ##class(%RoutineMgr).StudioOpenDialogExecute(.tQHandle,$LIST(tPrjItemData,2)_"/*.*",1,1,0,1)
					If $$$ISERR(tSC) Quit
					Set tListIdx = $LIST(tQHandle)
					Set tCspItem = $ORDER(^||%RoutineList(tListIdx,1,""),1,tCspItemData)
					While tCspItem '= "" {
                        Set tSearchList($LIST(tCspItemData)) = ""
						Set tCspItem = $ORDER(^||%RoutineList(tListIdx,1,tCspItem),1,tCspItemData)
					}
					Kill ^||%RoutineList(tListIdx), tListIdx, tCspItem, tCspItemData, tQHandle
				} ElseIf $LIST(tPrjItemData,3) = "CLS" {
                    Set tSearchList($LIST(tPrjItemData,2)_".cls") = ""
				} ElseIf $LIST(tPrjItemData,3) '= "PKG" {
                    Set tSearchList($LIST(tPrjItemData,2)) = ""
				}
				Set tPrjItem = $ORDER($$$ISCQUERYTEMP(tPrjIdx,tPrjItem),1,tPrjItemData)
			}
			Kill $$$ISCQUERYTEMP(tPrjIdx), tPrjIdx, tPrjItem, tPrjItemData
			If $$$ISERR(tSC) Quit
		} Else {
			#; Use StudioOpenDialog to generate the initial document list

			#; Write the opening message
			Set tAttrs = ""
			If 'pRegex, pWholeWords Set tAttrs = tAttrs_","_$$$GetSimpleMessage("%Compiler","SearchWholeWords")
			If pSystem Set tAttrs = tAttrs_","_$$$GetSimpleMessage("%Compiler","SearchSystem")
			If 'pRegex, pCaseSensitive Set tAttrs = tAttrs_","_$$$GetSimpleMessage("%Compiler","SearchCase")
			Write !,$$$GetSimpleMessage("%Compiler","SearchFor")_"'"_pQuery_"'"_$$$GetSimpleMessage("%Compiler","SearchIn")_"'"_pDocuments_"'"_$SELECT(tAttrs="":"",1:" ("_$EXTRACT(tAttrs,2,*)_")")
			
			Set tSC = ##class(%RoutineMgr).StudioOpenDialogExecute(.tQHandle,pDocuments,1,1,pSystem,1,,pGenerated,,,pMapped)
			If $$$ISERR(tSC) Quit
			Set tListIdx = $LIST(tQHandle)
			Set tRoutineItem = $ORDER(^||%RoutineList(tListIdx,1,""),1,tRoutineItemData)
			While tRoutineItem '= "" {
                Set tSearchList($LIST(tRoutineItemData)) = ""
				Set tRoutineItem = $ORDER(^||%RoutineList(tListIdx,1,tRoutineItem),1,tRoutineItemData)
			}
			Kill ^||%RoutineList(tListIdx)
		}
		
        If pRegex {
            Set tMatcher = ##class(%Regex.Matcher).%New(pQuery)
        } Else {
            Set tPattern = pQuery, tPattern = $SELECT(pCaseSensitive:tPattern,1:$ZCONVERT(tPattern,"l"))
            If (pWildCards && (tPattern["?"||(tPattern["*")||(tPattern["\"))) || (pWholeWords) {
                Set tPattern = ..pattern(tPattern,pWholeWords,.pWildCards)
            } Else {
                Set pWildCards = 0
            }
        }
        #; Loop through the document list until we hit pMax
        Set tDocName = ""
        For {
            Set tDocName = $ORDER(tSearchList(tDocName))
            If (tDocName = "") || (tNumFound >= pMax) Quit
            If (pIncludeRegex '= "") || (pExcludeRegex '= "") {
                #; Convert all . but the last to / and prepend / if it's not present
                Set tNormalizedDocName = $TRANSLATE($PIECE($SELECT(
                    $EXTRACT(tDocName,1)'="/":"/"_tDocName,
                    1:tDocName
                ),".",1,*-1),".","/")_"."_$PIECE(tDocName,".",*)
                #; Match this document against the provided regex(es)
                If pIncludeRegex '= "", '$MATCH(tNormalizedDocName,pIncludeRegex) {
                    #; pIncludeRegex was provided and this document doesn't match it
                    Continue
                }
                If pExcludeRegex '= "", $MATCH(tNormalizedDocName,pExcludeRegex) {
                    #; pExcludeRegex was provided and this document does match it
                    Continue
                }
            }
            #; Search the document
            If pRegex {
                If ..searchItemRegex(tMatcher,tDocName,.tNumFound,pMax) Set tNumFiles = tNumFiles + 1
            } Else {
                If ..searchItem(tPattern,tDocName,.tNumFound,pWildCards,pCaseSensitive,pMax,pQuery,pWholeWords) Set tNumFiles = tNumFiles + 1
            }
        }
		
		#; Write the closing message
		If tNumFound > 0 {
			Write !,$$$GetSimpleMessage("%Compiler","SearchFound")_tNumFound_$$$GetSimpleMessage("%Compiler","SearchOccurrences")_tNumFiles_$$$GetSimpleMessage("%Compiler","SearchFiles")
			If tNumFound '< pMax Write $$$GetSimpleMessage("%Compiler","SearchMax")
			Write !
		} Else {
			Write !,$$$GetSimpleMessage("%Compiler","SearchNotFound"),!
		}

	} Catch (tEx) {
		If tEx.Name = "<REGULAR EXPRESSION>" {
			Set tSC = ##class(%Regex.Matcher).LastStatus()
		} Else {
			Set tSC = tEx.AsStatus()
		}
	}

	Quit tSC
}

/// Find a particular string inside a list of files.
/// <br><var>String</var> is the string to search for.
/// The <var>PatternList</var> is the list of items to search. Typically this will
/// be '*.*' but you can specify just MAC and INC files with '*.mac,*.inc' or a
/// list of individual files with 'abc.mac,def.cls'. The acceptable extensions at this
/// time are int,mac,inc,bas,cls,csp,csr,prj,mvm,bam,mvb.
/// The list of matches is written to the screen. If <var>pSystem</var> is true then it also
/// searches system routines and classes (where the source is available) when searching the
/// entire namespace. If <var>WholeWords</var> is true then it will only find whole
/// words and not fragments, it defaults to false. If <var>CaseSensitive</var> is true (the default)
/// then the search is case sensitive, otherwise it is case insensitive.
/// The maximum number of matches it will find can be specified in <var>Max</var>
/// which defaults to 200. If <var>wild</var> is false then the <var>String</var> does not contain
/// any wild cards and so should be treated as a string literal search even if it contains ?*\ characters.
ClassMethod FindInFiles(String As %String, PatternList As %String, pSystem As %Boolean = 0, WholeWords As %Boolean = 0, CaseSensitive As %Boolean = 1, Max As %Integer = 200, Filter As %String(MAXLEN=512) = "", wild As %Boolean = 1, pGenerated As %Boolean = 1, pMapped As %Boolean = 1) As %Status
{
	New %SourceControl,%Files
	Set found=0,%Files=0
	Set pattern=String,attrs=""
	If WholeWords Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchWholeWords")
	If pSystem Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchSystem")
	If CaseSensitive Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchCase")
	Write !,$$$GetSimpleMessage("%Compiler","SearchFor")_"'"_String_"'"_$$$GetSimpleMessage("%Compiler","SearchIn")_"'"_PatternList_"'"_$select(attrs="":"",1:" ("_$extract(attrs,2,*)_")")
	Set pattern=$select(CaseSensitive:pattern,1:$zconvert(pattern,"l"))
	If (wild&&(pattern["?"||(pattern["*")||(pattern["\")))||(WholeWords) {
		Set pattern=..pattern(pattern,WholeWords,.wild)
	} Else {
		Set wild=0
	}
	Set sc=##class(%RoutineMgr).StudioOpenDialogExecute(.QHandle,PatternList,1,1,pSystem,1,,pGenerated,Filter,,pMapped)
	If $$$ISERR(sc) Quit sc
	Set idx=$list(QHandle)
	Set item=$order(^||%RoutineList(idx,1,""),1,data)
	While item'=""&&(found<Max) {
		If ..searchItem(pattern,$list(data),.found,wild,CaseSensitive,Max,String,WholeWords) Set %Files=%Files+1
		Set item=$order(^||%RoutineList(idx,1,item),1,data)
	}
	Kill ^||%RoutineList(idx)
	If found>0 {
		Write !,$$$GetSimpleMessage("%Compiler","SearchFound")_found_$$$GetSimpleMessage("%Compiler","SearchOccurrences")_%Files_$$$GetSimpleMessage("%Compiler","SearchFiles")
		If found'<Max Write $$$GetSimpleMessage("%Compiler","SearchMax")
		Write !
	} Else {
		Write !,$$$GetSimpleMessage("%Compiler","SearchNotFound"),!
	}
	Quit $$$OK
}

ClassMethod pattern(pattern As %String, wholewords As %Boolean = 0, ByRef wild As %Boolean) As %String [ Internal ]
{
	#; Double up the quotes
	Set pattern=$replace(pattern,"""",""""""),wild=1
	Set tmp=$translate(pattern,"*?\",$char(0,0,0))
	Set out="",find=0,oldfind=1,part=""
	For  {
		Set find=$find(tmp,$char(0),find) Quit:find=0
		Set part=part_$extract(pattern,oldfind,find-2),oldfind=find,item=$extract(pattern,find-1),match=""
		If item="?" {
			For j=find:1:$length(tmp)+1 Quit:$extract(pattern,j)'="?"
			Set match=(j-find+1)_"E"
			Set find=j,oldfind=j
		} ElseIf item="\" {
			Set part=part_$extract(pattern,find)
			Set find=find+1,oldfind=find
		} ElseIf item="*" {
			Set match=".E"
		}
		If match'="" {
			If part'="" Set out=out_"1"""_part_"""",part=""
			Set out=out_match
		}
	}
	Set part=part_$extract(pattern,oldfind,*)
	If part'="" Set out=out_"1"""_part_""""
	If 'wholewords Quit ".E"_out_".E"
	Quit "1(1"""",.E1(1P,1C))"_out_"1(1"""",1(1P,1C).E)"
}

/// Search this specific item for the string
ClassMethod searchItem(pattern As %String, Name As %String, ByRef Found As %Integer = 0, wild As %Boolean = 0, CaseSensitive As %Boolean = 1, Max As %Integer = 200, Pattern As %String, WholeWords As %Boolean = 0) As %Boolean [ Private ]
{
#define check(%str,%pat,%case,%wild) $s(%wild:$s('%case:$zcvt(%str,"l"),1:%str)?@%pat,'%case:$zcvt(%str,"l")[%pat,1:%str[%pat)
	Set oldFound=Found
	Set name=$piece(Name,".",1,*-1),type=$zconvert($piece(Name,".",*),"U")
	If name="" Quit 0
	If Name["/"||(Name["\") {
		Set csp=##class(%CSP.Routine).%New(Name)
		If csp=$$$NULLOREF Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set trail=""
		For lineno=1:1 {
			If csp.AtEnd Quit
			Set eol=0,line=trail_csp.ReadLine(32000,,.eol),trail=""
			If $$$check(line,pattern,CaseSensitive,wild) Write $char(13,10)_Name_"("_lineno_"): "_$zstrip(line,"<W") Set Found=Found+1 If Found'<Max Quit
			If 'eol Set lineno=lineno-1,trail=$extract(line,*-700,*)
		}
	} ElseIf ##class(%RoutineMgr).UserType(Name,.cls) {
		Do $classmethod(cls,"Search",Name,Pattern,WholeWords,CaseSensitive,Max,.Found)
	} ElseIf type="CLS" {
		If '$data(^oddDEF(name)) Quit 0
		Do ..searchClassNode(Name,"^oddDEF("""_name_""")",$$$cROOTclass,name,pattern,.Found,"",CaseSensitive,Max,wild) 
	} ElseIf $$$rtnIsMAC(type) {
		If '$data(^rMAC(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^rMAC(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf $$$rtnIsINT(type) {
		If '$data(^ROUTINE(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^ROUTINE(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf $$$rtnIsINC(type) {
		If '$data(^rINC(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^rINC(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf type="PRJ" {
		Set prj=##class(%Studio.Project).%OpenId(name)
		If prj'=$$$NULLOREF {
			If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
			Set item="",items=prj.Items
			#; Create list of items in this project.
			Set itemobj=items.GetNext(.item)
			While item'=""&&(Found<Max) {
				If $isobject(itemobj) {
					Set name=itemobj.Name,type=itemobj.Type
					If ..searchItem(Pattern,name_$select(type="CLS":".CLS",1:""),.Found,WholeWords,CaseSensitive,Max) Set %Files=%Files+1
					Do items.%UnSwizzleAt(item)
				}
				Set itemobj=items.GetNext(.item)
			}
		}
	}
	Quit (oldFound'=Found)
#undef check
}

/// Search this class for the string
ClassMethod searchClassNode(Name As %String, ref As %String, type As %String, NewName As %String, pattern As %String, ByRef Found As %Integer, Tree As %String, CaseSensitive As %Boolean = 1, Max As %Integer = 200, Wild As %Boolean = 0) [ Private ]
{
#define check(%str,%pat,%case,%wild) $s(%wild:$s('%case:$zcvt(%str,"l"),1:%str)?@%pat,'%case:$zcvt(%str,"l")[%pat,1:%str[%pat)
	Set value="",data=$data(@ref,value)
	#;
	#; Check for 'value' nodes e.g property parameters 
	If 'data Quit
	Set line=$translate(Tree,","," "),tmp=$translate($piece(Tree,",",*-2,*),","," ")
	If $$$check(tmp,pattern,CaseSensitive,Wild) {
		Do outputMatch
	} Else {
        If type = $$$cROOTclass Set value = "Class" ##; Search for "Class" instead of the value of ^oddDEF(<cls>)
		For line=value,NewName {
			If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch Quit
		}
	}
	If data=1 Quit
	Set key=""
	While Found<Max {
		Set key=$Order(@ref@(key),1,value) Quit:key=""
		Set external=$$$tableSubSubToExtGet(type,key)
        #; If this key isn't defined for this tnode type, or it's a type that we don't want to search, then don't output
        If external=""||(";Name;TimeChanged;TimeCreated;"[(";"_external_";")) Continue
		Set lineno=0
		#; If the keyword is of type "k", that is, its a keyword with a single value
		If $extract($$$tableTypeGet(type,key))="k" {
			#; If this is the implementation we need to output all the subnodes
			If $$$tableMultiLineGet(type,key) {
				For lineno=1:1:value {
					If $select(lineno=1:$data(@ref@(key,1),line)#10=1,1:$data(^(lineno),line)#10=1) {
						If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch If Found'<Max Quit
					}
				}
			} ElseIf (";Super;Description;Copyright;"'[(";"_external_";")), $$$check(external,pattern,CaseSensitive,Wild) {
                #; Don't match the keyword names Super, Description or Copyright because they don't appear in the text
				Set line=value Do outputMatch
			} ElseIf external = "Super", $$$check("Extends",pattern,CaseSensitive,Wild) {
                #; For Super, match Extends instead since it actually appears in the text
				Set line="Extends" Do outputMatch
            } Else {
				Set line=value
				If $$$check(line,pattern,CaseSensitive,Wild) {
					If $length(value,$char(13,10))=1 {
						Do outputMatch
					} Else {
						For lineno=1:1:$length(value,$char(13,10)) {
							Set line=$piece(value,$char(13,10),lineno)
							If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch If Found'<Max Quit
						}
					}
				}
			} 
		} Else {
			Set name=""
			For {
				Set name=$Order(@ref@(key,name)) Quit:name=""
				Do ..searchClassNode(Name,$zreference,key,name,pattern,.Found,Tree_external_","_name_",",CaseSensitive,Max,Wild) Quit:Found'<Max
			}
		}
	}
	Quit
outputMatch Set Found=Found+1,output=$char(13,10)_Name
	If $piece(Tree,",")'="Storage" {
		Set output=output_"("_$piece(Tree,",",2)
		If $get(external)="Implementation" {
			Set output=output_$select($get(lineno)>0:"+"_(lineno),1:"")_")"
		} ElseIf $get(external)="FormalSpec" {
			Write output_"): "_$piece(Tree,",",2)_"(",$zstrip(line,"<W"),")" Quit
		} ElseIf $piece(Tree,",",*-2)="Parameter" {
			Set output=output_")" If $length(Tree,",")>4 Set output=output_"["_$piece(Tree,",",*-1)_"]"
		} Else {
			Set output=output_")" If $get(external)'="" Set output=output_"["_external_$select($get(lineno)>0:"+"_lineno,1:"")_"]"
		}
	} Else {
		Set output=output_"(Storage)["_$piece(Tree,",",2,*)_$get(external)_"]"
	}
	Write output_": "_$zstrip(line,"<W")
	Quit
}

/// Search a list of files, using a Regular Expression.
/// <br><var>Regex</var> is the Regular Expression for the search.
/// The <var>ItemList</var> is the list of items to search. Typically this will
/// be '*.*' but you can specify just MAC and INC files with '*.mac,*.inc' or a
/// list of individual files with 'abc.mac,def.cls'. The acceptable extensions at this
/// time are int,mac,inc,bas,cls,csp,csr,prj,mvm,bam,mvb.
/// <br>
/// The list of matches is written to the current device.
/// <br>
/// If <var>pSystem</var> is true then it also
/// searches system routines and classes (where the source is available).
/// If <var>pGenerated</var> is true then it also searches generated items.
/// The maximum number of matches it will find can be specified in <var>Max</var>
/// which defaults to 200.
ClassMethod FindInFilesRegex(Regex As %String, ItemList As %String, pSystem As %Boolean = 0, pGenerated As %Boolean = 0, Max As %Integer = 200, pMapped As %Boolean = 1) As %Status
{
	#dim e As %Exception.SystemException
	#dim Matcher As %Regex.Matcher
	#dim sc As %Status
	
	New %SourceControl,%Files
	
	Set found=0,%Files=0
	Set attrs=""
	Set sc=$$$OK
	
	Try {
		Set Matcher=##class(%Regex.Matcher).%New(Regex)
	} Catch (e) {
		If e.Name="<REGULAR EXPRESSION>" {
			Set sc=##class(%Regex.Matcher).LastStatus()
		} Else {
			Set sc=e.AsStatus()
		}
	}
	If $$$ISERR(sc) Quit sc
	
	If pSystem Set attrs=attrs_","_$$$GetSimpleMessage("%Compiler","SearchSystem")
	Write !,$$$GetSimpleMessage("%Compiler","SearchFor")_"'"_Regex_"'"_$$$GetSimpleMessage("%Compiler","SearchIn")_"'"_ItemList_"'"_$select(attrs="":"",1:" ("_$extract(attrs,2,*)_")")
	
	Set sc=##class(%RoutineMgr).StudioOpenDialogExecute(.QHandle,ItemList,1,1,pSystem,1,,pGenerated,,pMapped)
	If $$$ISERR(sc) Quit sc
	
	Set idx=$list(QHandle)
	Set item=$order(^||%RoutineList(idx,1,""),1,data)
	While item'=""&&(found<Max) {
		If ..searchItemRegex(Matcher,$list(data),.found,Max) Set %Files=%Files+1
		Set item=$order(^||%RoutineList(idx,1,item),1,data)
	}
	Kill ^||%RoutineList(idx)
	
	If found>0 {
		Write !,$$$GetSimpleMessage("%Compiler","SearchFound")_found_$$$GetSimpleMessage("%Compiler","SearchOccurrences")_%Files_$$$GetSimpleMessage("%Compiler","SearchFiles")
		If found'<Max Write $$$GetSimpleMessage("%Compiler","SearchMax")
		Write !
	} Else {
		Write !,$$$GetSimpleMessage("%Compiler","SearchNotFound"),!
	}
	Quit $$$OK
}

/// Search this specific item for the string
ClassMethod searchItemRegex(Matcher As %Regex.Matcher, Name As %String, ByRef Found As %Integer, Max As %Integer = 200) As %Boolean [ Private ]
{
	Set oldFound=Found
	Set name=$piece(Name,".",1,*-1),type=$zconvert($piece(Name,".",*),"U")
	If name="" Quit 0
	If Name["/"||(Name["\") {
		Set csp=##class(%CSP.Routine).%New(Name)
		If csp=$$$NULLOREF Quit 0
		If Matcher.Match(name) {
			Write $char(13,10)_Name_": "_Name
			Set Found=Found+1
		}
		Set trail=""
		For lineno=1:1 {
			If csp.AtEnd Quit
			Set eol=0,line=trail_csp.ReadLine(32000,,.eol),trail=""
			If Matcher.Match(line) {
				Write $char(13,10)_Name_"("_lineno_"): "_$zstrip(line,"<W")
				Set Found=Found+1 If Found'<Max Quit
			}
			If 'eol Set lineno=lineno-1,trail=$extract(line,*-700,*)
		}
	} ElseIf ##class(%RoutineMgr).UserType(Name,.cls) {
		If Matcher.Match(name) {
			Write $char(13,10)_Name_": "_name
			Set Found=Found+1
		}
		Do $classmethod(cls,"SearchRegex",Name,Matcher,Max,.Found)
	} ElseIf type="CLS" {
		If '$data(^oddDEF(name)) Quit 0
		Do ..searchClassNodeRegex(Matcher,Name,"^oddDEF("""_name_""")",$$$cROOTclass,name,.Found,"",Max)
	} ElseIf $$$rtnIsMAC(type) {
		If '$data(^rMAC(name,0)) Quit 0
		If Matcher.Match(name) {
			Write $char(13,10)_Name_": "_name
			Set Found=Found+1
		}
		Set l=0
		For lineno=1:1:$get(^rMAC(name,0,0)) {
			If $data(^(lineno),line),$increment(l),Matcher.Match(line) { 
				Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W")
				Set Found=Found+1 If Found'<Max Quit
			}
		}
	} ElseIf $$$rtnIsINT(type) {
		If '$data(^ROUTINE(name,0)) Quit 0
		If Matcher.Match(name) {
			Write $char(13,10)_Name_": "_name
			Set Found=Found+1
		}
		Set l=0
		For lineno=1:1:$get(^ROUTINE(name,0,0)) {
			If $data(^(lineno),line),$increment(l),Matcher.Match(line) {
				Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W")
				Set Found=Found+1 If Found'<Max Quit
			}
		}
	} ElseIf $$$rtnIsINC(type) {
		If '$data(^rINC(name,0)) Quit 0
		If Matcher.Match(name) {
			Write $char(13,10)_Name_": "_name
			Set Found=Found+1
		}
		Set l=0
		For lineno=1:1:$get(^rINC(name,0,0)) {
			If $data(^(lineno),line),$increment(l),Matcher.Match(line) {
				Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W")
				Set Found=Found+1 If Found'<Max Quit
			}
		}
	} ElseIf type="PRJ" {
		Set prj=##class(%Studio.Project).%OpenId(name)
		If prj'=$$$NULLOREF {
			If Matcher.Match(name) {
				Write $char(13,10)_Name_": "_name
				Set Found=Found+1
			}
			Set item="",items=prj.Items
			#; Create list of items in this project.
			Set itemobj=items.GetNext(.item)
			While item'=""&&(Found<Max) {
				If $isobject(itemobj) {
					Set name=itemobj.Name,type=itemobj.Type
					If ..searchItemRegex(Matcher,name_$select(type="CLS":".CLS",1:""),.Found,Max) Set %Files=%Files+1
					Do items.%UnSwizzleAt(item)
				}
				Set itemobj=items.GetNext(.item)
			}
		}
	}
	Quit (oldFound'=Found)
}

/// Search this class for the string
ClassMethod searchClassNodeRegex(Matcher As %Regex.Matcher, Name As %String, ref As %String, type As %String, NewName As %String, ByRef Found As %Integer, Tree As %String, Max As %Integer = 200) [ Private ]
{
	Set value="",data=$data(@ref,value)
	#;
	#; Check for 'value' nodes e.g property parameters 
	If 'data Quit
	Set line=$translate(Tree,","," "),tmp=$translate($piece(Tree,",",*-2,*),","," ")
	If Matcher.Match(tmp) {
		Do outputMatch
	} Else {
        If type = $$$cROOTclass Set value = "Class" ##; Search for "Class" instead of the value of ^oddDEF(<cls>)
		For line=value,NewName {
			If Matcher.Match(line) Do outputMatch Quit
		}
	}
	If data=1 Quit 
	Set key=""
	While Found<Max {
		Set key=$Order(@ref@(key),1,value) Quit:key=""
		Set external=$$$tableSubSubToExtGet(type,key)
		#; If this key isn't defined for this tnode type, or it's a type that we don't want to search, then don't output
        If external=""||(";Name;TimeChanged;TimeCreated;"[(";"_external_";")) Continue
		Set lineno=0
		#; If the keyword is of type "k", that is, it's a keyword with a single value
		If $extract($$$tableTypeGet(type,key))="k" {
			#; If this is the implementation we need to output all the subnodes
			If $$$tableMultiLineGet(type,key) {
				For lineno=1:1:value {
					If $select(lineno=1:$data(@ref@(key,1),line)#10=1,1:$data(^(lineno),line)#10=1) {
						If Matcher.Match(line) Do outputMatch If Found'<Max Quit
					}
				}
			} ElseIf (";Super;Description;Copyright;"'[(";"_external_";")), Matcher.Match(external) {
                #; Don't match the keyword names Super, Description or Copyright because they don't appear in the text
				Set line=value Do outputMatch
			} ElseIf external = "Super", Matcher.Match("Extends") {
                #; For Super, match Extends instead since it actually appears in the text
				Set line="Extends" Do outputMatch
            } Else {
				If $length(value,$char(13,10))=1 {
					If Matcher.Match(value) {
						Set line=value Do outputMatch
					}
				} Else {
					For lineno=1:1:$length(value,$char(13,10)) {
						Set line=$piece(value,$char(13,10),lineno)
						If Matcher.Match(line) Do outputMatch If Found'<Max Quit
					}
				}
			} 
		} Else {
			Set name=""
			For {
				Set name=$Order(@ref@(key,name)) Quit:name=""
				Do ..searchClassNodeRegex(Matcher,Name,$zreference,key,name,.Found,Tree_external_","_name_",",Max)
				Quit:Found'<Max
			}
		}
	}
	Quit
outputMatch Set Found=Found+1,output=$char(13,10)_Name
	If $piece(Tree,",")'="Storage" {
		Set output=output_"("_$piece(Tree,",",2)
		If $get(external)="Implementation" {
			Set output=output_$select($get(lineno)>0:"+"_(lineno),1:"")_")"
		} ElseIf $get(external)="FormalSpec" {
			Write output_"): "_$piece(Tree,",",2)_"(",$zstrip(line,"<W"),")" Quit
		} ElseIf $piece(Tree,",",*-2)="Parameter" {
			Set output=output_")" If $length(Tree,",")>4 Set output=output_"["_$piece(Tree,",",*-1)_"]"
		} Else {
			Set output=output_")" If $get(external)'="" Set output=output_"["_external_$select($get(lineno)>0:"+"_lineno,1:"")_"]"
		}
	} Else {
		Set output=output_"(Storage)["_$piece(Tree,",",2,*)_$get(external)_"]"
	}
	Write output_": "_$zstrip(line,"<W")
	Quit
}

ClassMethod DeleteItem(name As %String)
{
	Do ..NormalizeName(.name,.type)
	Set currproj=$get(^||%Studio.Project)
	Set project=$order(^oddPROJECT(""))
	While project'="" {
		If $data(^oddPROJECT(project,"Items",name,type)),project'=currproj {
			Kill ^oddPROJECT(project,"Items",name,type)
			Set $list(^oddPROJECT(project))=$ZDT($H,3)
			Set $list(^oddPROJECT(project),6)=$listget(^oddPROJECT(project),6)-1
		}
		Set project=$order(^oddPROJECT(project))
	}
}

/// Normalize the name passed in and determine its type
ClassMethod NormalizeName(ByRef name As %String, ByRef type As %String = "", skiptype As %Boolean = 0) As %Status
{
	Set type=$zconvert(type,"U")
	
	if (type = "DIR") {
		Quit $$$OK
	}
	
	If type'="" {
		For test="CLS","PKG" {
			If type=test,$zconvert($piece(name,".",*),"U")'=test Set name=name_"."_test
		}
	}
	If name'["." Set name=name_".MAC",type="MAC"
	Set type=$zconvert($piece(name,".",*),"U")
	If $$$rtnIsKnown(type) {
		Set name=$piece(name,".",1,*-1)_"."_type,type="MAC"
	} ElseIf name["/"||(name["\"),type'="GBL" {
		If type'="DIR" {
			Set type="CSP"
		} Else {
			Set name=$piece(name,".",1,*-1)
		}
	} ElseIf type="CLS"||(type="PKG") {
		Set name=$piece(name,".",1,*-1)
	} Else {
		Set name=$piece(name,".",1,*-1)_"."_type
	}
	If 'skiptype,",MAC,CLS,CSP,GBL,PKG,XML,JS,CSS,OBJ,DIR,"'[(","_type_","),'##class(%RoutineMgr).UserType(name) Quit $$$ERROR($$$ProjectInvalidType,type)
	If type'="GBL" Set name=$translate(name,"\","/")
	If type="GBL",$extract(name)="^" Set name=$extract(name,2,*)
	If $extract(name)="/",$length(name,"/")>2 Set name=$extract(name,2,*)
	If name="" Quit $$$ERROR($$$ProjectBlankName)
	Quit $$$OK
}

ClassMethod Normalize() As %Status
{
	If $get(^oddPROJECT)=1 Quit $$$OK
	Set ^oddPROJECT=1
	Set project=""
	For  {
		Set project=$order(^oddPROJECT(project)) Quit:project=""
		Kill newitems,items
		Merge items=^oddPROJECT(project,"Items")
		Set item=""
		For  {
			Set item=$order(items(item)) Quit:item=""
			Set type=""
			For  {
				Set type=$order(items(item,type),1,data) Quit:type=""
				Set newname=item,newtype=type
				Set sc=..NormalizeName(.newname,.newtype) If $$$ISERR(sc) Goto exit
				Set newitems(newname,newtype)=data
			}
		}
		Kill ^oddPROJECT(project,"Items") Merge ^oddPROJECT(project,"Items")=newitems
	}
	Quit $$$OK
exit	Quit sc
}

/// Internal method to determine if all classes in this project are up to date.
/// The <var>uptodate</var> is returned as a %Boolean value to indicate if everything is up to date or not.
/// If some items are not up to date then the items in question are returned in a comma separated list in <var>notuptodate</var>.
Method IsUpToDate(ByRef uptodate As %Boolean, ByRef notuptodate As %String = "") As %Status [ Internal ]
{
	Set uptodate=1
	Set item=""
	#; Create list of items in this project.
	Set itemobj=..Items.GetNext(.item)
	While item'="" {
		If $isobject(itemobj) {
			Set name=itemobj.Name,type=itemobj.Type
			If type="CSP" {
				#; Separate out CSP and CSR files
				If $length(name,".")=1 Set name=name_".csp"
				Set newtype=$zconvert($piece(name,".",*),"U")
				If newtype="CSP",'$system.CSP.IsUpToDate(name) Set uptodate=0,notuptodate=notuptodate_name_","
			} ElseIf type="PKG" {
				Kill clslist Set sc=$$GetPackageList^%occLibrary(.clslist,name,.qstruct)
				Set clslist=""
				For  {
					Set clslist=$order(clslist(clslist)) Quit:clslist=""
					If '$$$defClassKeyGet(clslist,$$$cCLASSdeployed),'$system.OBJ.IsUpToDate(clslist) Set uptodate=0,notuptodate=notuptodate_clslist_".cls,"
				}
			} ElseIf type="CLS" {
				IF '$system.OBJ.IsUpToDate(name) Set uptodate=0,notuptodate=notuptodate_name_".cls,"
			} ElseIf type="DIR" {
				Set rs=##class(%ResultSet).%New("%Library.RoutineMgr:StudioOpenDialog")
				Do rs.Execute(name_"/*.cspall,*.csp,*.csr",1,1,1,1)
				While rs.Next() {
					Set name1=rs.Data("Name")
					If $length(name1,".")=1 Set name1=name1_".csp"
					Set newtype1=$zconvert($piece(name1,".",*),"U")
					If newtype1="CSP",'$system.CSP.IsUpToDate(name1) Set uptodate=0,notuptodate=notuptodate_name1_","
				}
				Set rs=""
			}
			Do ..Items.%UnSwizzleAt(item)
		}
		Set itemobj=..Items.GetNext(.item)
	}
	Set notuptodate=$extract(notuptodate,1,*-1)
	Quit $$$OK
}

Storage Default
{
<Data name="Data">
<Value name="1">
<Value>LastModified</Value>
</Value>
<Value name="2">
<Value>Target</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>TargetType</Value>
</Value>
<Value name="5">
<Value>HttpServer</Value>
</Value>
<Value name="6">
<Value>ItemCount</Value>
</Value>
<Value name="7">
<Value>TerminalUsername</Value>
</Value>
<Value name="8">
<Value>TerminalPassword</Value>
</Value>
<Value name="9">
<Value>TerminalPort</Value>
</Value>
<Value name="10">
<Value>RunInTerminal</Value>
</Value>
<Value name="11">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="12">
<Value>Projections</Value>
</Value>
<Value name="13">
<Value>Defines</Value>
</Value>
<Value name="14">
<Value>DebugStepping</Value>
</Value>
</Data>
<DataLocation>^oddPROJECT</DataLocation>
<DefaultData>Data</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^oddPROJECT</IdLocation>
<IndexLocation>^oddPROJECTI</IndexLocation>
<StreamLocation>^%Studio.ProjectS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
