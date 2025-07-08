/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.AppStats Extends %CSP.Page [ System = 4 ]
{

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
 Quit $system.Security.Check("%Development","USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	&html<
	<HTML>
	<HEAD>
	</HEAD>
	<BODY>
	>
	do ..StatsCollection()
	&html<
	</BODY>
	</HTML>>
	Quit $$$OK
}

ClassMethod StatsCollection() [ ProcedureBlock = 0 ]
{
	if $zversion[" 5.0" {

		
		set sessionId=0,sessionCount=0,now=$piece($horolog,",",1)*86400+$piece($horolog,",",2)
		for  {
			set sessionId=$order(^%cspSession(sessionId),1,data)
			if sessionId="" quit
			set sessionCount=sessionCount+1
			set timeout=$lg(data,4)
			set timeleft=$justify(timeout-now\60,0,0)
			set time(timeleft)=$i(time(timeleft))
		}
		set luFree = $system.License.LUAvailable()
		set luUsed = $system.License.LUConsumed()
		
		set timeNow=($piece($zts,",",1)*86400)+$piece($zts,",",2)
		set gref=$v(4*4+$ZU(40,2,1),-2,4)
		set pread=$v(7*4+$ZU(40,2,1),-2,4)
		set pwri=$v(8*4+$ZU(40,2,1),-2,4)
		set rlas=$v(0*4+$ZU(40,2,1),-2,4)
		set gsk=$v(9*4+$ZU(40,2,1),-2,4)
		set rseizes=$zu(162,3,2)
		set seizes=$zu(162,3,4)
		
		set neg1=4294967295
		set bdb0off=$ZU(40,2,128)
		set bdbbase=$V($ZU(40,2,21),-2,"P")
		set bdbsiz=$ZU(40,29,0)
		set wdqsizoff=$ZU(40,29,2)
		set off=$V(bdb0off,-2,4)
		set wdqsize=$V(bdbbase+off+wdqsizoff,-3,4)
		set last=off
		for i=1:1:5 {
			set off=$V(bdb0off+(i*4),-2,4)
	 		if (off=last)||(off=neg1) quit
	 		set wdqsize=wdqsize_","_$V(bdbbase+off+wdqsizoff,-3,4)
	 		set last=off
		}
		
		set MINATOM=4  ;1 for non-alpha chips, usually
		set off=$ZU(40,2,146)
	 	if '$V(off,-2,MINATOM) {
		 	set wdwake=0
	 	}
	 	else {
			set wdphaseoff=$ZU(40,2,145)
			if 'wdphaseoff {
				set wdwake=1
			}
			else {
				set wdwake='$V(wdphaseoff,-2,4)
			}
	 	}
	 	set LUAvailable=$system.License.LUAvailable()
	 	set LUConsumed=$system.License.LUConsumed()

		set vars="LUAvailable,LUConsumed,sessionCount,timeNow,gref,pread,pwri,rlas,gsk,seizes,rseizes,wdqsize,wdwake"
	 	set len=$length(vars,",")
	 	for var=1:1:len {
		 	set variable=$piece(vars,",",var)
		 	write variable,":",@variable,":"
	 	}
	}
}

}
