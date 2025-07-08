/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %qccStringList

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
Class %Studio.ClassMgr [ System = 4 ]
{

/// Perform basic checks we are allowed to proceed
ClassMethod Check() As %Status
{
	If '$system.Security.Check("%Development","USE") Quit $$$ERROR($$$SecurityNotDeveloper)
	$$$CheckClassDefRtnIdx(sc)
	Quit $$$OK
}

/// Return the timestamp a class was last modified and last compiled
ClassMethod Timestamp(class As %String(MAXLEN=256), ByRef timemodified As %TimeStamp, ByRef timecompiled As %TimeStamp) As %Status
{
	Set timecompiled="",timemodified=""
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	If class="" Quit $$$OK
	Set timemodified=##class(%RoutineMgr).TS(class_".cls",.timecompiled)
	Quit $$$OK
}

/// Lock the class for editing
ClassMethod Lock(class As %String(MAXLEN=256)) As %Status
{
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	If class="" Quit $$$OK
	Quit $$ChkClass^%qccServer(class)
}

/// Unlock the class
ClassMethod UnLock(class As %String(MAXLEN=256)) As %Status
{
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	If class="" Quit $$$OK
	Do UnlockClass^%qccServer(class)
	Quit $$$OK
}

/// Check if there is a class name conflict
ClassMethod IsClassnameConflict(class As %String(MAXLEN=256)) As %Status
{
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	Quit $$IsClassnameConflict^%occName(class)
}

/// Return the entire class definition in the stream <var>defintion</var> property
ClassMethod GetDefinition(class As %String(MAXLEN=256), Output definition As %Stream.GlobalCharacter, Output Hash As %String(MAXLEN="")) As %Status
{
	Set definition="",lock=0,Hash=""
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	#; Do not fire any source control events when loading a class definition here
	New %SourceControl
	Set ns=$$$GBLDBREF("oddDEF",class)
	Try {
		Set lock=$$ClassIndexLock^%SYS.cspServer2(ns,,class)
		Set sc=$$GetClassDefinitionCP^%qccServer(class,2,.serialized) If $$$ISERR(sc) Goto exit
		Set showhidden=((","_$ROLES_",")[",ISC_Internal,")||$get(^%SYS("Studio","ShowHidden"))
		Set data=$get(^rINDEXCLASS($zconvert(class,"U")))
		$$$SetClsIndexRow(Hash,data,showhidden)
		If $get(serialized) {
			Set definition=##class(%Stream.GlobalCharacter).%New()
			For i=1:1:serialized Do definition.Write(serialized(i))
		}
	} Catch {
		Set rc=$$$ERROR($$$ObjectScriptError,$zerror),sc=$$$ADDSC(sc,rc)
	}
exit	If lock Set lock=$$ClassIndexLock^%SYS.cspServer2(ns,0,class)
	Quit sc
}

/// Call the OnBeforeLoad/OnAfterLoad source control events for this class
/// return true if the class is modified and false if it is not
ClassMethod OnOpenClass(class As %String(MAXLEN=256), Output modified As %Boolean) As %Status
{
	Set modified=0
	Quit $$$OK
}

/// Passed a class definition in stream <var>definition</var> this is saved
ClassMethod SaveDefinition(ByRef definition As %Stream.GlobalCharacter, Hash As %String(MAXLEN=""), Output List As %Stream.GlobalCharacter, Output Lengths As %String(MAXLEN="")) As %Status
{
	Set serialized=0,List="",Lengths="",lock=0
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	While 'definition.AtEnd {
		Set serialized($increment(serialized))=definition.Read()
	}
	Set definition=""
	Try {
		Set sc=$$SaveClassDefinition^%qccServer(.serialized,.updated,1) If $$$ISERR(sc) Goto exit
		If $data(Hash) {
			Set sc=..ClassList(Hash,.List,.Lengths) If $$$ISERR(sc) Goto exit
		}
		Set class=""
		For  {
			Set class=$order(updated(class)) Quit:class=""
			Kill serialized
			If definition="" Set definition=##class(%Stream.GlobalCharacter).%New()
			Set sc=$$GetClassDefinitionCP^%qccServer(class,2,.serialized) If $$$ISERR(sc) Quit
			For i=1:1:$get(serialized) Do definition.Write(serialized(i))
		}
	} Catch {
		Set rc=$$$ERROR($$$ObjectScriptError,$zerror),sc=$$$ADDSC(sc,rc)
	}
exit	Quit sc
}

ClassMethod Delete(class As %String(MAXLEN=256)) As %Status
{
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	Quit $$DeleteClassDefinition^%qccServer(class,1)
}

ClassMethod GetSchema(schemaspec As %String(MAXLEN=256), ByRef definition As %Stream.GlobalBinary) As %Status
{
	Set definition=##class(%Stream.GlobalBinary).%New()
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	Set sc=##class(%Studio.SASchemaUtil).getSchemaDefinition(schemaspec,.serialized)
	If $$$ISERR(sc) Quit sc
	For i=1:1:$get(serialized) Do definition.Write(serialized(i))
	Quit $$$OK
}

ClassMethod GetSpecialListByStream(kind As %String, param As %String, ByRef result As %Stream.GlobalBinary) As %Status
{
	$$$CheckRtnIndexExistsQuit(sc)
	;
	Set result=##class(%Stream.GlobalBinary).%New()
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	;
	i kind="packagelist" d  q $$$OK
	. s c="" f  s c=$o(^rINDEXCLASS(c),1,data) q:c=""  d
	. . s package=$$$ClassPackageName($List(data,2))
	. . i package'="" s sort(package)=""
	. s p="" f  s p=$o(sort(p)) q:p=""  d result.Write($$$LB(p))
	;
	i kind="incfilelist" d  q $$$OK
	. s f="" f  s f=$o(^rINDEX(f)) q:f=""  d:$d(^rINDEX(f,"INC"))
	. . d result.Write($$$LB(f))
	;
	i kind="userlist" d  q $$$OK
	. d result.Write($$GetSpecialListUserlist^%SYS.SQLSEC())
	;
	i kind="storagestrategylist" d  q $$$OK
	. d GetEnvironment^%apiOBJ($$$cENVstoragestrategylist,.sslist)
	. i sslist'="" f i=1:1:$l(sslist,",") d result.Write($$$LB("$"_$p(sslist,",",i)))
	;
	i kind="superclasslist" d  q $$$OK
	. d GetAllSuperClasses^%occLibrary(param,.classes)
	. s class="" f  s class=$o(classes(class)) q:class=""  d result.Write($$$LB(class))
	;
	i kind="derivedclasslist" d  q $$$OK
	. d GetAllDerivedClasses^%occLibrary(param,.classes)
	. s class="" f  s class=$o(classes(class)) q:class=""  d result.Write($$$LB(class))
	;
	i kind="projectionlist" d  q $$$OK
	. d GetAllDerivedClasses^%occLibrary("%Projection.AbstractProjection",.classes)
	. s class="" f  s class=$o(classes(class)) q:class=""  d result.Write($$$LB(class))
	;
	i kind="derivedclasslonglist" d  q $$$OK
	. d GetAllDerivedClasses^%occLibrary(param,.classes)
	. s class="" f  s class=$o(classes(class)) q:class=""  d result.Write($$$LB(class))
	;
	Quit $$$OK
}

/// Return a list of all classes available in this namespace, it is passed the client hash value
/// in the format $$$SLB(name)_$$$SLB(hash)_$$$SLB(name2)_$$$SLB(hash2). This checks each of the named regions and if they are
/// all identical then it returns with a null stream in <var>List</var>. If any of the regions has
/// changed then we will resend all the classes in this region in the format:<br>
/// $$SLB(name)_$$$SLB(hash)_data_$$$SLB("")_$$$SLB(name2)_$$$SLB(hash2)_data2_$$$SLB("")<br>
/// Where data is of the form:<br>
/// $$$SLB(row)_$$$SLB(nextrow)_...<br>
/// Where row is of the form:<br>
/// $$$SLB(classname)_$$$SLB(timestamp)_$$SLB(superclass)_$$$SLB(classtype defined)_$$$SLB(classtype)_$$$SLB(system)_$$$SLB(hidden)_$$$SLB(abstract)_$$$SLB(import)<br>
/// To tell the client to remove a named block from its cache we will send the hash=-1 for this i.e.<br>
/// $$$SLB(name)_$$$SLB("")_$$$SLB("")_nextblock<br>
/// So the hash is "" and the block is terminated with $$$SLB("") as per normal. Note that the last block is also terminated with $$$SLB("").
/// The lengths of the various block is returned in <var>Lengths</var> which is an output argument. This is a comma separated list
/// of length in characters of the stream data. This can be used to quickly divide the stream into pieces on the client.
ClassMethod ClassList(Hash As %String(MAXLEN=""), Output List As %Stream.GlobalCharacter, Output Lengths As %String(MAXLEN="")) As %Status
{
#define hash(%input)	$translate($system.Encryption.Base64Encode($system.Encryption.SHA1Hash(%input)),"/+=","_-")
	Set List="",Lengths=""
	Set showhidden=((","_$ROLES_",")[",ISC_Internal,")||$get(^%SYS("Studio","ShowHidden"))
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	Do findmappings^%R($namespace,.dblist,.dir,1)
	Set db=""
	For  {
		Set db=$order(dblist(db),1,data) Quit:db=""
		Try {
			Set hash($$$hash(db))=$listbuild($$$hash($lb($$ClassIndexTS^%SYS.cspServer2(db),$roles)_data),data,db)
		} Catch { }
	}
	#; Walk the client hash and figure out which items we need to send to client, and if any items need to be removed from client
	Set count=$$Split^%qccSerialize(Hash,.array)
	For i=1:1:count\2 {
		Set name=array(i*2-1),value=array(i*2) If name="" Continue
		If $data(hash(name),hashval) {
			If $list(hashval)=value Kill hash(name)
		} Else {
			Set remove(name)=""
		}
	}
	If '$data(remove),'$data(hash) Quit $$$OK
	Set List=##class(%Stream.GlobalBinary).%New()
	#; First output the items to remove
	Set name="",output=""
	For  {
		Set name=$order(remove(name)) Quit:name=""
		Set data=$$$SLB(name)_$$$SLB("")_$$$SLB("")
		Set output=output_data,Lengths=Lengths_$length(data)_","
	}
	New %class,%end
	Set extname=""
	For  {
		Set extname=$order(hash(extname),1,hashval) Quit:extname=""
		Set db=$list(hashval,3),rangelist=$list(hashval,2)
		#; Recompute hash here now we have the lock
		Set hashval=$$$hash($lb($$ClassIndexTS^%SYS.cspServer2(db),$roles)_rangelist)
		Set tmp=$$$SLB(extname)_$$$SLB(hashval),length=$length(tmp),output=output_tmp
		For item=1:1:$listlength(rangelist) {
			Set range=$list(rangelist,item)
			Set @("%class="_$list(range)),%end=$list(range,2) If %end'="" Set @("%end="_%end)
			Try {
				If %class'="",$data(^rINDEXCLASS(%class)) Set %class=$order(^rINDEXCLASS(%class),-1)
				For  {
					Set %class=$order(^rINDEXCLASS(%class),1,data) Quit:%class=""  If %end'="",%end']%class Quit
					$$$SetClsIndexRow(summary,data,showhidden)
				Set length=length+$length(summary),output=output_summary If $length(output)>31000 Do List.Write(output) Set output=""
				}
			} Catch {
				Set rc=$$$ERROR($$$ObjectScriptError,$zerror),sc=$$$ADDSC(sc,rc)
			}
		}
		Set output=output_$$$SLB(""),Lengths=Lengths_(length+$length($$$SLB("")))_","
	}
	If output'="" Do List.Write(output)
	Set Lengths=$extract(Lengths,1,*-1)
	Quit sc
}

/// Return information about this macro
/// If <var>arglist</var> is not defined ($d(arglist)=0) then it does not return the expansion
ClassMethod GetMacroInf(macroname As %String(MAXLEN=512), arg As %String(MAXLEN=512), arglist As %String(MAXLEN=1024), ByRef signature As %String(MAXLEN=512), ByRef location As %String(MAXLEN=512), ByRef definition As %String(MAXLEN=512), ByRef expansion As %String(MAXLEN=512))
{
	Quit $$GetMacroInf^%qccServer(macroname,arg,.arglist,.signature,.location,.definition,.expansion)
}

/// Return list of macros
Query MacroList(arg As %String(MAXLEN=512), ByRef clienthash As %String(MAXLEN=128), Output Reload As %Boolean) As %Query(ROWSPEC = "Name:%String(MAXLEN=512)") [ SqlProc ]
{
}

ClassMethod MacroListExecute(ByRef qHandle As %Binary, arg As %String(MAXLEN=512), ByRef clienthash As %String(MAXLEN=128), Output Reload As %Boolean) As %Status
{
	Set qHandle="",Reload=0
	Set sc=..Check() If $$$ISERR(sc) Quit sc
	Set sc=$$MacroListHash^%qccServer(arg,.hash,.dephash) If $$$ISERR(sc) Quit sc
	If clienthash=(hash_","_dephash) Quit $$$OK
	Set clienthash=hash_","_dephash
	Set qHandle=$listbuild(hash,$get(^IRIS.TempMacro(hash,"systeminclude")),"")
	Quit $$$OK
}

ClassMethod MacroListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = MacroListExecute ]
{
	Set qHandle=""
	Quit $$$OK
}

ClassMethod MacroListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = MacroListExecute ]
{
	Set Row=""
	If qHandle="" Set AtEnd=1 Quit $$$OK
	Set hash=$list(qHandle),systeminclude=$list(qHandle,2),cursor=$list(qHandle,3)
	If 'systeminclude {
		Set cursor=$order(^IRIS.TempMacro(hash,"data",$char(0),cursor)) 
		If cursor="" Set qHandle="",AtEnd=1 Quit $$$OK
		Set macroinf=$get(^IRIS.TempMacro(hash,"data",cursor))
		If $piece(macroinf,$char(1),2)'="" { Set Row=$listbuild(cursor_"(") } Else { Set Row=$listbuild(cursor) }
	} Else {
		#; Use merge sort
		If cursor="" {
			Set c1=$order(^IRIS.TempMacro(hash,"data",$char(0),""))
			Set c2=$order(^rINC("%systemInclude","P","E",$char(0),""))
		} Else {
			Set c1=$piece(cursor,","),c2=$piece(cursor,",",2)
		}
		If c1=""||(c1]c2),c2'="" {
			Set c2inf=$get(^rINC("%systemInclude","P","E",c2))
			If $piece(c2inf,$char(1),2)'="" { Set Row=$listbuild(c2_"(") } Else { Set Row=$listbuild(c2) }
			Set c2=$order(^rINC("%systemInclude","P","E",$char(0),c2))
		} ElseIf c1'="" {
			Set c1inf=$get(^IRIS.TempMacro(hash,"data",c1))
			If $piece(c1inf,$char(1),2)'="" { Set Row=$listbuild(c1_"(") } Else { Set Row=$listbuild(c1) }
			Set c1=$order(^IRIS.TempMacro(hash,"data",$char(0),c1))
		} Else {
			Set qHandle="",AtEnd=1 Quit $$$OK
		}
		Set cursor=c1_","_c2
	}
	Set $list(qHandle,3)=cursor
	Quit $$$OK
}

}
