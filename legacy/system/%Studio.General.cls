/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syINET, %syPidtab)

/// Collection of ClassMethods used by Studio
Class %Studio.General [ System = 3 ]
{

/// return $c(1) delimetered string
/// p1 - %SYSTEM.Version.GetNumber()
/// p2 - Is MVB installed
/// p3 - Is Ensamble installed
/// p4 - Is Activate available
/// p5 - Is Other Enabled
/// p6 - Feetback URL
/// p7 - _$SYSTEM.Version.Format(4)
/// p8 - ^%SYS("Studio","NoXecute")
/// p9 - U2 Enabled.  Bit 30
ClassMethod GetStudioInfo() As %String
{
	set sDelim = $c(1) //delimeter
	set sRet = ##class(%SYSTEM.Version).GetNumber()
	set sRet = sRet_sDelim
	set sRet = sRet_$zbitget($zversion(0)_$char(0,0,0,0),39) //MVB
	set sRet = sRet_sDelim
	set sRet = sRet_$$$comClassDefined("Ens.StudioManager") //Ensemble
	set sRet = sRet_sDelim
	set sRet = sRet_##class(%SYSTEM.Activate).Available() //Activate
	set sRet = sRet_sDelim
	set sRet = sRet_$zbitget($zversion(0)_$char(0,0,0,0),32) //Other
	set sRet = sRet_sDelim
	set sRet = sRet_$g(^%SYSTEM.Config("FeedbackURL"))
	set sRet = sRet_sDelim
	try {
		set sRet = sRet_$SYSTEM.Version.Format(4)
	} catch {
	}
	set sRet = sRet_sDelim
	set sRet = sRet_$g(^%SYS("Studio","NoXecute")) //Block execute
	set sRet = sRet_sDelim
	set sRet = sRet_..FeatureBits(30)
	Quit sRet
}

ClassMethod CheckDeveloperRole() As %Status
{
	If '$system.Security.Check("%Development","use") Quit $$$ERROR($$$NoDevloperPriv)
	Quit $$$OK
}

ClassMethod FeatureBits(bit As %Integer = "") As %Binary
{
	Quit $select(bit="":$zversion(0),1:$zbitget($zversion(0)_$char(0,0,0,0),bit))
}

/// Internal method to construct a CSP session with current security permissions and return the session id
ClassMethod ConstructCSPSession(page As %String = "") As %String [ CodeMode = expression ]
{
$$CreateTemplateSession^%SYS.cspServer2(page)
}

/// Deprecated internal method to return the CSP session id of the session constructed with <method>ConstructCSPSession</method>.
/// This is no longer needed as <method>ConstructCSPSession</method> returns the CSP sessionId directly now.
ClassMethod ReturnCSPSessionId(id As %String) As %String [ CodeMode = expression, Deprecated ]
{
id
}

/// Return the port the InterSystems IRIS web server is running on or 0 if the
/// web server is not active. Also returns the server name which is useful if the web server
/// is running on a different machine. It can also
/// return a <var>urlprefix</var> which is added to the url to goto at the start and is required
/// if one web server is serving multiple InterSystems IRIS instances to differential between these versions.
/// It also returns <var>url</var> which is the constructed
/// url as a string, you just need to append the page you are going to request to this.
ClassMethod GetWebServerPort(ByRef port As %Integer, ByRef server As %String, ByRef urlprefix As %String, ByRef url As %String) As %Status
{
	Set port=$get(^%SYS("WebServer","Port")),origserver=$get(server)
	If +port {
		If $get(^%SYS("WebServer","Name"))'="" {
			Set server=$get(^%SYS("WebServer","Name"))
		} Else {
			Set server=origserver
		}
	} Else {
		Set server=""
	}
	Set urlprefix=$zconvert($get(^%SYS("WebServer","URLPrefix")),"l")
	If origserver="",server="127.0.0.1"||(server="::1") {
		Set server=..ServerIP()
	}
	If +port {
		Set tmpserver=$select(server="":..ServerIP(),1:server)
		If tmpserver[":" Set tmpserver="["_tmpserver_"]"
		Set protocol=$zconvert($get(^%SYS("WebServer","Protocol"),$select(port=443:"https",1:"http")),"l")
		Set url=protocol_"://"_tmpserver_$select(port=80||(port=443):"",1:":"_port)_"/"_$select(urlprefix="":"",1:urlprefix_"/")
	} Else {
		Set url=""
	}
	i server=""	Set server=$zcvt($zu(54,0),"U")
	Quit $$$OK
}

/// Try to return the current servers IP address/name
ClassMethod ServerIP() As %String [ Private ]
{
	If $extract($io,1,$length("|TCP|"))="|TCP|",$zutil(67,10,$job)'=$$$CSPSRV {
		Set serverip=$$$GetTCPLocalIP(0)
	} Else {
		Set serverip=$$$GetLocalIPText(0)
		If serverip="" Set serverip=$$$LOCALHOST
	}
	Quit $piece(serverip,"%")
}

ClassMethod KillProcess(pid As %String) As %Status [ Internal ]
{
	Quit $$KillProcess^%SYS.cspServer2(pid)
}

ClassMethod Execute(%cmd As %String) [ ProcedureBlock = 0 ]
{
  Set Data=$namespace_">"_%cmd
  Do $SYSTEM.Security.Audit($$$SourceSystem,$$$TypeDirectMode,$$$NameDirectMode,Data,Data)

  new (%StudioLocalVariables,%cmd)
  try {
   	  	set %StudioLocalSub = ""
	 	set:($d(%StudioLocalVariables)) %StudioLocalSub =$O(%StudioLocalVariables(""))
		while (%StudioLocalSub '= "") {
			merge @%StudioLocalSub = %StudioLocalVariables(%StudioLocalSub)
			set %StudioLocalSub = $O(%StudioLocalVariables(%StudioLocalSub))
		}
		kill %StudioLocalVariables,%StudioLocalSub
		
			// Don't use %cmd in case the command is argumentless write or zwrite.
			// We don't want %cmd displayed in the output.
		set ^||%isc.studio.cmd=%cmd kill %cmd
	 	x ^||%isc.studio.cmd
	 	kill ^||%isc.studio.cmd
	 	write !

		set %StudioLocalSub =""
		set %StudioLocalSub = $o(@%StudioLocalSub)
		while (%StudioLocalSub '= "") {
			merge:($e(%StudioLocalSub,1,1) '= "%") %StudioLocalVariables(%StudioLocalSub) = @%StudioLocalSub
			set %StudioLocalSub = $o(@%StudioLocalSub)
		}
    	}
	catch {
		write !,$g(%cmd,$g(^||%isc.studio.cmd))," - Error ",$P($ze,">",1),">",!
	}
	Quit
}

Query DumpObject(oref As %String) As %Query(ROWSPEC = "Name:%String,Value:%String") [ SqlProc ]
{
}

ClassMethod DumpObjectExecute(ByRef qHandle As %Binary, oref As %String) As %Status
{
	s qHandle = ""
 ;	s oref =  $zobjref(+oref)
	Set cd=$system.CLS.DumpContext(oref,0)
	Set inst=$piece(cd,"^",8)
	For j=1:1:inst {
		Set pd=$system.CLS.Property(j,oref,0)
		Set ivar=$piece(pd,"^")
		Set slot=$piece(pd,"^",2)
		Set mode=+$piece(pd,"^",3)
		Set refprop=($zb(mode,16,1)=16)
		
		If refprop {
			Do ..DumpObjectSlot(.qHandle,oref,ivar,slot)
			Do ..DumpObjectSlot(.qHandle,oref,ivar_"[r%]",slot+1)
		} Else {
			Do ..DumpObjectSlot(.qHandle,oref,ivar,slot)
		}
	}
	Quit $$$OK
}

ClassMethod DumpObjectSlot(ByRef qHandle As %String, oref As %String, ivar As %String, slot As %Integer)
{
	if ($data($zobjval(oref,slot,0,3,slot))\10) {
		New %data
		Merge %data=$zobjval(oref,slot,0,3,slot)
		If $data(%data)#2 {
			s qHandle(ivar)=%data
		}
		Set ref="%data"
		Set ref=$query(@ref,1,val)
		While ref'="" {
			s qHandle(ivar_$extract(ref,6,*)) = val
			Set ref=$query(@ref,1,val)
		}
	} else {
		set qHandle(ivar) = $select('$data($zobjval(oref,slot,0,3,slot)):"<UNDEFINED>",1:$zobjval(oref,slot,0,3,slot))
	}
}

ClassMethod DumpObjectClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DumpObjectExecute ]
{
	Quit $$$OK
}

ClassMethod DumpObjectFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DumpObjectExecute ]
{
	s Row=""
	s var = $o(qHandle(qHandle))
	if var="" {
		s AtEnd=1
	}
	else {
		s Row = $ListBuild(var,qHandle(var))
		s qHandle = var
	}

	Quit $$$OK
}

/// For each property of <b>oref</b>, return its name, value, <code>$DATA(value)</code>, 
/// <code>$ISOBJECT(value)</code>, <code>$CLASSNAME(value)</code> and if the property is calculated
Query AnalyzeObjectProperties(oref As %String) As %Query(ROWSPEC = "Name:%String,Value:%String,Data:%Integer,IsObject:%Boolean,Classname:%String,Calculated:%Boolean") [ SqlProc ]
{
}

ClassMethod AnalyzeObjectPropertiesExecute(ByRef qHandle As %Binary, oref As %String) As %Status
{
	Set qHandle = ""
 ;	Set oref = $zobjref(+oref)

	#; Adapted from DumpObjectToArray^%occRun()
	Set class = $CLASSNAME(oref)
	Set cd = $SYSTEM.CLS.DumpContext(oref)
	Set numsub = $PIECE(cd,"^",10)
	For supcls=0:1:numsub-1 {
		Set context = $SYSTEM.CLS.DumpContext(oref,supcls)
		Set inst = $PIECE(context,"^",8), props = $PIECE(context,"^",7)
		For j=1:1:props {
			Try {
				Set pd = $SYSTEM.CLS.Property(j,oref,supcls)
			} Catch {
				#; Aliases have no slots so it will throw a FUNCTION error for these so just ignore
				#; these slots, we could use 'inst' to only iterate through items with slots assigned
				#; but this would miss calculated properties which we want to detect
				Continue
			}
			Set ivar = $PIECE(pd,"^")
			If $DATA(properties(0,ivar))||($DATA(properties(1,ivar)))||($DATA(properties(2,ivar))) Continue
			Set mode = +$PIECE(pd,"^",3)
			Set refprop = ($ZBOOLEAN(mode,16,1)=16)
			$$$comMemberKeyGetLvar(aliases,class,$$$cCLASSproperty,ivar,$$$cPROPaliases)
			Set properties($SELECT(j<=inst:refprop,1:2),ivar) = pd_aliases
		}
	}

	#; Attribute values
	Set ivar = ""
	For  {
		Set ivar = $ORDER(properties(0,ivar),1,pd) Quit:ivar=""
		If ivar = "%%OID" Continue
		Do ..AnalyzeObjectProperty(.qHandle,oref,ivar,pd,0)
	}
	#; Swizzled references
	If $DATA(properties(1)) {
		Set ivar = ""
		For {
			Set ivar = $ORDER(properties(1,ivar),1,pd) Quit:ivar=""
			Do ..AnalyzeObjectProperty(.qHandle,oref,ivar,pd,1)
		}
	}
	#; Calculated references
	If $DATA(properties(2)) {
		Set ivar = ""
		For {
			Set ivar = $ORDER(properties(2,ivar),1,pd) Quit:ivar=""
			Do ..AnalyzeObjectProperty(.qHandle,oref,ivar,pd,2)
		}
	}

	Quit $$$OK
}

ClassMethod AnalyzeObjectProperty(ByRef qHandle As %Binary, oref As %String, ivar As %String, pd As %String, type As %Integer)
{
	Set slot = $PIECE(pd,"^",2)
	Set mode = +$PIECE(pd,"^",3)
	Set refprop = ($ZBOOLEAN(mode,16,1) = 16)

	If refprop, $DATA($ZOBJVAL(oref,slot+1,0,3,slot+1)) # 2, $ZOBJVAL(oref,slot+1,0,3,slot+1) '= "" {
		#; Use the values for the r% property
		Do ..AnalyzeObjectPropertyValues(.qHandle,oref,ivar,slot+1,refprop,type)
	}
	Else {
		Do ..AnalyzeObjectPropertyValues(.qHandle,oref,ivar,slot,refprop,type)
	}
}

ClassMethod AnalyzeObjectPropertyValues(ByRef qHandle As %Binary, oref As %String, ivar As %String, slot As %Integer, refprop As %Boolean, type As %Integer)
{
	Set data = $DATA($ZOBJVAL(oref,slot,0,3,slot))
	If data # 2 {
		Set value = $ZOBJVAL(oref,slot,0,3,slot)
	}
	Else {
		Set value = "<UNDEFINED>"
	}
	Set isobj = $ISOBJECT(value)
	Set clsname = $SELECT(isobj:$CLASSNAME(value),1:"")
	Set calculated = $SELECT(type=2:1,1:0)
	If refprop Set isobj = 1
	Set qHandle(ivar) = $LISTBUILD(value,data,isobj,clsname,calculated)
}

ClassMethod AnalyzeObjectPropertiesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = AnalyzeObjectPropertiesExecute ]
{
	Quit $$$OK
}

ClassMethod AnalyzeObjectPropertiesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = AnalyzeObjectPropertiesExecute ]
{
	Set Row = ""
	Set var = $ORDER(qHandle(qHandle))
	If var = "" {
		Set AtEnd = 1
	}
	Else {
		Set Row = $LISTBUILD(var)_qHandle(var)
		Set qHandle = var
	}
	Quit $$$OK
}

/// Return the date last modified of file <var>filename</var> in %Timestamp format.
/// By default this is local time, if you pass <var>utc</var> as true it returns it in UTC time
ClassMethod GetFileDateModified(filename As %String, utc As %Boolean = 0) As %String
{
    Set $ZT = "DateModifiedERROR"
    quit $zdt($$$FileDateModifiedUTC(filename,utc),3)
DateModifiedERROR;
	quit ""
}

ClassMethod DecomposeStatus(status As %String) As %Status
{
	set Ret = ""
	try {
		s a = $$DecomposeStatus^%apiOBJ(status,.list)
		for i = 1:1  d  q:$d(list(i))=0
		. s Ret = Ret_$g(list(i))
		. s Ret = Ret_$c(1)
	} catch ds 
	{}
	quit Ret
}

}
