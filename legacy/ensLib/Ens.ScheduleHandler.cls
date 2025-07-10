/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.ScheduleHandler Extends Ens.BusinessProcess [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Parameter SKIPMESSAGEHISTORY As BOOLEAN = 1;

Parameter DOMAIN = "Ensemble";

Method OnRequest(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	$$$sysTRACE("requested to invoke schedule handler on "_$zdatetime($H,3))
	Quit ..UpdateProduction()
}

Method OnResponse(request As %Library.Persistent, ByRef response As Ens.Response, callrequest As %Library.Persistent, callresponse As %Library.Persistent, pCompletionKey As %String) As %Status
{
	$$$sysTRACE("received timer notification on "_$zdatetime($H,3))
	Quit ..UpdateProduction(1)
}

Method UpdateProduction(pCalledFromAResponse As %Boolean = 0) As %Status
{
	#dim tSC = $$$OK
	#dim tSC1 = $$$OK
	#dim tConfigName
	#dim tClosestEventDateTime, tSchedule, tCurrentState, tNextEventDateTime
	#dim tCanMakeAlarmRequest, tDuplicateSecondsToAdd, tSecondsUntil

	$$$sysTRACE("Updating production on "_$zdatetime($H,3))
	Set tSC=##class(Ens.Director).UpdateProduction(##class(Ens.Director).GetRunningProductionUpdateTimeout(),,1)
	If $$$ISERR(tSC) {
		$$$sysTRACE("Production update failed")
		set tClosestEventDateTime=##class(Ens.ScheduleHandler).AdjustedCurrentTime("+m")
	} else {
		$$$sysTRACE("Production updated")
		set tClosestEventDateTime=""
	}

	set tConfigName="" for  {
		set tConfigName=$o($$$ConfigRoot(tConfigName)) quit:tConfigName=""
		if '$g($$$ConfigIsEnabled(tConfigName)) Continue
		set tSchedule=$g($$$ConfigSchedule(tConfigName))
		If tSchedule'="" {
			Set tSC1=##class(Ens.ScheduleHandler).ParseScheduleSpec(tSchedule,.tCurrentState,.tNextEventDateTime)
			If $$$ISERR(tSC1) {
				Set tSC = $$$ADDSC(tSC, tSC1)
				Quit
			}
			If tCurrentState="DISABLED" Continue
			If tNextEventDateTime'="" if (tClosestEventDateTime="")||(tClosestEventDateTime]tNextEventDateTime) set tClosestEventDateTime=tNextEventDateTime
		}
	}

	/*	Avoid duplicate alarm requests unless this is an acceptable
		renew repeat. (duration of zero seconds accounted for when making request)
		Look to see if any outstanding requests to Ens.Alarm by Ens.ScheduleHandler.
	*/
	Set tCanMakeAlarmRequest = 0

	If (tClosestEventDateTime'="") {
		If ($d($$$EnsRuntimeAppData("SchedulerHandler","AlarmSet",tClosestEventDateTime))=0) {
			#; Not requested for this time before
			Set tCanMakeAlarmRequest = 1
		} ElseIf pCalledFromAResponse {
			/*	Already requested for this time so check if any alarm(s) outstanding
				Simplified check - doesn't check if the outstanding is for the same time
				since we do not record relation with schedule.
				If no outstanding alarms then allow repeat.
				Use 10 to indicate a repeat to aid adding a few seconds to prevent possible
				tight loop.
			*/
			Set:'..outstandingAlarmRequest("Ens.ScheduleHandler") tCanMakeAlarmRequest = 10
		}
	}

	If tCanMakeAlarmRequest {

		/*	If we have an alarm request to send after receiving a response then check if we need to regenerate
			the ScheduleHandler to prevent indefinite session growth.
			Check once a day - we can use EnsJobLocal due to pool size of 1.
			If ScheduleHandler job restarted then it will check again.
			Regenerating will lead to recalculating next event time.
		*/
		If pCalledFromAResponse {
			If $Get($$$EnsJobLocal("ScheduleHandler","Restart")) '= +$HOROLOG {
				Set $$$EnsJobLocal("ScheduleHandler","Restart") = +$HOROLOG
				#dim tDaysForRestart = $Get($$$EnsConfig("ScheduleHandler","DaysForRestart"),7)
				If tDaysForRestart < 1 Set tDaysForRestart = 1
				If $System.SQL.Functions.DATEDIFF("d",..%TimeCreated,$$$timeUTC) >= tDaysForRestart {
					Job ##class(Ens.ScheduleService).CallScheduleService()::5
					If $Test {
						$$$LOGINFO($$$FormatText($$$Text("Regenerating ScheduleHandler thread (regeneration period every %1 days)"), tDaysForRestart))
						Return tSC
					}
					/* If fail to job off then fall through to send Alarm request from here. */
				}
			}
		}

		/* Make alarm request setting Timeout to Event date time as default be will calculate seconds until and replace */
		Set tAlarmRequest = ##class(Ens.AlarmRequest).%New()
		$$$ASSERT($IsObject(tAlarmRequest))
		Set tAlarmRequest.Timeout = tClosestEventDateTime
		Set tAlarmRequest.DiscardOnShutdown = 1

		Set tSC1 = ##class(Ens.Util.Time).TimeoutToSeconds(tClosestEventDateTime,.tSecondsUntil)
		If $$$ISOK(tSC1) {
			Set tAlarmRequest.Timeout = tSecondsUntil
			If $Get($$$EnsJobLocal("ScheduleHandler","InZoneWithClockChange")) && $system.Util.IsDST() {
				/*	If we are in the first of the repeated hours for fallback (DST or legislation) i.e. an ambiguous time
					then we need to calculate Timeout as if no dst and add time and use Timeout=seconds.
					If in initial duplicated hour find timeuntil until and add 3600.
					This code exists for the potential to be called during the 1 hour or 30 minute period a year.
					Also protect against delay request of 0 seconds due to allowing repeats.
				*/
				Set tDuplicateSecondsToAdd = ..ambiguousSecondsToAdd()
				Set tAlarmRequest.Timeout = tAlarmRequest.Timeout+$Get(tDuplicateSecondsToAdd,0)
			}
			/*	If we calculate 0 seconds add 30 seconds to ensure do not enter tight loop
				if this is a repeat request - i.e. same time.
				If there is a schedule less than 30 seconds after this one then we will
				not use it but update production called at +30 seconds will identify 
				if the particular item needs to have it status changed.
			*/
			Set:('tAlarmRequest.Timeout&&(tCanMakeAlarmRequest=10)) tAlarmRequest.Timeout = 30
			Set tSC1=..SendRequestAsyncInternal("Ens.Alarm",tAlarmRequest,1,"ScheduleHandler",0)
			If $$$ISOK(tSC1) {
				Set $$$EnsRuntimeAppData("SchedulerHandler","AlarmSet",tClosestEventDateTime)=""
				$$$sysTRACE("requested timer alarm of "_tAlarmRequest.Timeout_" seconds for next event on "_tClosestEventDateTime)
			} Else {
				Set tSC = $$$ADDSC(tSC, tSC1)
			}
		} Else {
			Set tSC = $$$ADDSC(tSC, tSC1)
		}

	}

	Quit tSC
}

ClassMethod ParseScheduleSpec(pScheduleSpec As %String, Output pCurrentState As %String, Output pNextEventDateTime As %String, Output pNextEventAction As %String, pCurrentDateTime As %String = "") As %Status
{
	set tSC=$$$OK
	set tGlobalNextEventDateTime="",tGlobalNextEventAction=""
	set tGlobalPrevEventDateTime="",tGlobalPrevEventAction=""
	set tHasErrors=0, tSpec=pScheduleSpec
	if "@"=$E(tSpec) {
		set tSpec1="", tName=$E(tSpec,2,*)
		&sql(Select ScheduleSpec Into :tSpec1 From Ens_Util.Schedule Where Name=:tName)
		set:'SQLCODE tSpec=tSpec1
	}
	for i=1:1:$L(tSpec,",") {
		set tScheduleSpecOne=$p(tSpec,",",i)
		set tSC=..validateSchedulePiece(.tScheduleSpecOne) If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Set tSC=$$$OK,tHasErrors=1 Quit
		set tThisAction=$p(tScheduleSpecOne,":",1)
		set tThisSchedule=$p(tScheduleSpecOne,":",2,99)
		;
		set tThisNextEventDateTime=..Next(tThisSchedule,"+",pCurrentDateTime)
		if tThisNextEventDateTime'="" if (tGlobalNextEventDateTime="")||(tGlobalNextEventDateTime]tThisNextEventDateTime) set tGlobalNextEventDateTime=tThisNextEventDateTime,tGlobalNextEventAction=tThisAction
		;
		set tThisPrevEventDateTime=..Next(tThisSchedule,"-",pCurrentDateTime)
		if tThisPrevEventDateTime'="" if (tGlobalPrevEventDateTime="")||(tThisPrevEventDateTime]tGlobalPrevEventDateTime) set tGlobalPrevEventDateTime=tThisPrevEventDateTime,tGlobalPrevEventAction=tThisAction
	}
	quit:$$$ISERR(tSC) tSC
	if tHasErrors set pCurrentState="DISABLED" quit tSC
	;
	set pCurrentState=tGlobalPrevEventAction
	if pCurrentState="" set pCurrentState=$s(tGlobalNextEventAction="START":"STOP",1:"START")
	set pNextEventAction=tGlobalNextEventAction
	;
	; drop the DST-adjustment disambiguator
	set pNextEventDateTime=$p(tGlobalNextEventDateTime,"@",1)
	;
	quit $$$OK
}

/// This method checks for the syntax validity of an entire ScheduleSpec.
/// It returns an error if the syntax of the ScheduleSpec is invalid.
/// It returns an array of responses that explains the problem in detail if there is any invalid syntax.
ClassMethod ValidateScheduleSpec(ByRef pScheduleSpec, ByRef pScheduleErrors, Output pLength) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pLength = $L(pScheduleSpec,",")
	for i=1:1:pLength {
		set tScheduleSpecOne=$p(pScheduleSpec,",",i)
		set tSC1=..validateSchedulePiece(.tScheduleSpecOne) 
		If $$$ISERR(tSC1) {
			Set pScheduleErrors(i) = "Error in segment " _ i _ ": " _ $System.Status.GetErrorText(tSC1) _ ". "
			Set tSC=$$$ADDSC(tSC,tSC1) 
		}
		Else {
			Set pScheduleErrors(i) = ""
		}
	}
	quit tSC
}

/// This method checks for the syntax validity of one piece of a ScheduleSpec.
/// It returns an error if the syntax of the ScheduleSpec is invalid
/// If the syntax is valid, pScheduleSpec will contain the normalized ScheduleSpec
ClassMethod validateSchedulePiece(ByRef pScheduleSpec) As %Status [ Internal ]
{
	set tScheduleSpecNormalized=$tr($zcvt(pScheduleSpec,"u")," ")
	set tAction=$p(tScheduleSpecNormalized,":",1)
	set tSchedule=$p(tScheduleSpecNormalized,":",2,99)
	set tDate=$p(tSchedule,"T",1)
	set tTime=$p(tSchedule,"T",2)
	set Y=$p(tDate,"-",1)
	set M=$p(tDate,"-",2)
	set D=$p(tDate,"-",3)
	set h=$p(tTime,":",1)
	set m=$p(tTime,":",2)
	set s=$p(tTime,":",3)
	if tAction'="STOP",tAction'="START" quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"action name",tAction)
	if Y'="*",Y'="WEEK",(Y'?1.N)||(Y<1) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"year",Y)
	If Y="WEEK" {
		if M'="*",(M'?1.N)||(M<1)||(M>5) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"occurrence-number",M)
		if D'="*",(D'?1.N)||(D<0)||(D>6) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"day-of-week",D)
	} Else {
		if M'="*",(M'?1.N)||(M<1)||(M>12) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"month",M)
		if D'="*",(D'?1.N)||(D<1)||(D>31) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"day",D)
	}
	if h'="*",(h'?1.N)||(h<0)||(h>23) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"hour",h)
	if m'="*",(m'?1.N)||(m<0)||(m>59) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"minute",m)
	if s'="*",(s'?1.N)||(s<0)||(s>59) quit $$$ERROR($$$EnsErrInvalidScheduleEventSpec,pScheduleSpec,"second",s)
	Set pScheduleSpec=tScheduleSpecNormalized
	quit $$$OK
}

ClassMethod Next(pScheduleDateTime As %String, pDirection As %String, pCurrentDateTime As %String = "") As %String
{
	if pScheduleDateTime="" quit ""
	set result="",adjust="=X"
	If pCurrentDateTime="" set pCurrentDateTime=..dstCompensatedCurrentTime()
	set dateCurrent=$p(pCurrentDateTime,"T",1)
	set timeCurrent=$p(pCurrentDateTime,"T",2)
	set current("Y")=$p(dateCurrent,"-",1)
	set current("M")=$p(dateCurrent,"-",2)
	set current("D")=$p(dateCurrent,"-",3)
	set current("h")=$p(timeCurrent,":",1)
	set current("m")=$p(timeCurrent,":",2)
	set current("s")=$p(timeCurrent,":",3)
	;
	set dateSchedule=$p(pScheduleDateTime,"T",1)
	set timeSchedule=$p(pScheduleDateTime,"T",2)
	set schedule("Y")=$p(dateSchedule,"-",1)
	set schedule("M")=$p(dateSchedule,"-",2)
	set schedule("D")=$p(dateSchedule,"-",3)
	set schedule("h")=$p(timeSchedule,":",1)
	set schedule("m")=$p(timeSchedule,":",2)
	set schedule("s")=$p(timeSchedule,":",3)
	;
	merge event=schedule
	;
	if event("Y")="WEEK" {
		if event("D")="*" {
			set event("Y")=current("Y")
			set event("M")=current("M")
			set event("D")=current("D")
			set adjust=pDirection_"D"
		} elseif event("M")="*" {
			set event("Y")=current("Y")
			set event("M")=current("M")
			set event("D")=current("D")+event("D")-$zdate($zdateh(dateCurrent,3),10)
			set adjust=pDirection_"W"
			do ..makeValid(.event)
		} else {
			set weekcount=event("M")
			set event("Y")=current("Y")
			set event("M")=current("M")
			set event("D")=current("D")+event("D")-$zdate($zdateh(dateCurrent,3),10)
			set event("D")=$tr((event("D")#7),0,7)+((weekcount-1)*7)
			set adjust=pDirection_"G"_weekcount
			; don't call ..makeValid(), so in case this date is invalid, we just call ..adjust()
		}
	} else {
		if event("Y")="*" set event("Y")=current("Y"),adjust=pDirection_"Y"
		if event("M")="*" set event("M")=current("M"),adjust=pDirection_"M"
		if event("D")="*" set event("D")=current("D"),adjust=pDirection_"D"
	}
	if event("h")="*" set event("h")=current("h"),adjust=pDirection_"h"
	if event("m")="*" set event("m")=current("m"),adjust=pDirection_"m"
	if event("s")="*" set event("s")=current("s"),adjust=pDirection_"s"
	;
	if (..isValid(.event)=0) {
		set result=..adjust(.event,adjust)
	} else {
		set compare=..compare(.event,.current)
		if ((pDirection="+")&&(compare=1))||((pDirection="-")&&((compare=-1)||(compare=0))) {
			set result=..adjust(.event,"")
		} else {
			set result=..adjust(.event,adjust)
		}
	}
	; we assume the original comparision of time is valid because dstCompensatedScheduleTime() does not alter any order of time
	if result'="" set result=..dstCompensatedScheduleTime(result)
	;
	quit result
	;
}

ClassMethod AdjustedCurrentTime(adjustment) As %String
{
	set pCurrentDateTime=..dstCompensatedCurrentTime()
	set dateCurrent=$p(pCurrentDateTime,"T",1)
	set timeCurrent=$p(pCurrentDateTime,"T",2)
	set current("Y")=$p(dateCurrent,"-",1)
	set current("M")=$p(dateCurrent,"-",2)
	set current("D")=$p(dateCurrent,"-",3)
	set current("h")=$p(timeCurrent,":",1)
	set current("m")=$p(timeCurrent,":",2)
	set current("s")=$p(timeCurrent,":",3)
	quit ..adjust(.current,adjustment)
}

ClassMethod compare(dt1, dt2) As %Integer
{
	if +dt1("Y")'=+dt2("Y") quit $s(dt1("Y")>dt2("Y"):1,1:-1)
	if +dt1("M")'=+dt2("M") quit $s(dt1("M")>dt2("M"):1,1:-1)
	if +dt1("D")'=+dt2("D") quit $s(dt1("D")>dt2("D"):1,1:-1)
	if +dt1("h")'=+dt2("h") quit $s(dt1("h")>dt2("h"):1,1:-1)
	if +dt1("m")'=+dt2("m") quit $s(dt1("m")>dt2("m"):1,1:-1)
	if +dt1("s")'=+dt2("s") quit $s(dt1("s")>dt2("s"):1,1:-1)
	quit 0
}

/// For the purpose of schedule time (formal time as opposed to actual time)
/// this method collapses the non-existing hour, when turning DST on, to a single point in time
/// For example, 2009-03-08T02:00:00 to 2009-03-08T03:00:00
ClassMethod dstCompensatedScheduleTime(datetime) As %String
{
	set datetime1=$tr(datetime,"T"," ")
	set datetime2=$zdt($zdTH($zdT($zdth(datetime1,3),-3),-3),3)
	If datetime1=datetime2 {
		quit datetime
	} else {
		; move the hour up by one, after zero out minute and second values, the hour is collapsed to one point in time
		set hour=$tr($j($p($p(datetime,"T",2),":",1)+1,2)," ","0")
		; we append the original datetime as a DST-adjustment disambiguator
		; so we can distinguish different time values within that hour and sort them correctly
		quit $p(datetime,"T",1)_"T"_hour_":00:00"_"@"_datetime
	}
}

/// For the purpose of current time (actual time as opposed to formal time)
/// this method collapses the first duplicated hour or half hour, when moving local time back (DST off),
/// to a single point in time. For example, the first occurrence of 2009-11-01T01:00:00 to 2009-11-01T02:00:00
/// (i.e. when DST is on, for there is  another occurrence of 2009-11-01T01:00:00 to 2009-11-01T02:00:00 with 
/// DST off after the clock change).
/// The number of duplicated (ambiguous) seconds when moving local time back (DST off) if current local time 
/// is in the first of the duplicated time slots is returned in the parameter.
ClassMethod dstCompensatedCurrentTime(Output pSubjectToDuplicateSeconds As %Integer = 0) As %String
{
	Set tCurrentUTC = $ztimestamp
	Set tCurrentLocal = $zdatetimeh(tCurrentUTC,-3)
	Set tCompensatedCurrentTime = $tr($zdatetime(tCurrentLocal,3)," ","T")
	Try {
		Set tCurrentUTCHour = ($P(tCurrentUTC,",",1)+(($P(tCurrentUTC,",",2)+3600)\86400))_","_(($P(tCurrentUTC,",",2)+3600)#86400)
		Set tCurrentUTCHourLocal = $zdatetimeh(tCurrentUTCHour,-3)
		Set tCurrentLocalPlus60 = ($P(tCurrentLocal,",",1)+(($P(tCurrentLocal,",",2)+3600)\86400))_","_(($P(tCurrentLocal,",",2)+3600)#86400)
		If tCurrentLocalPlus60 = tCurrentUTCHourLocal {
			#; Not in time change slot 	
			Quit
		}
		If tCurrentUTCHourLocal = tCurrentLocal {
			#; We are in a repeated hour so return start hour for the duration since will be repeated when clock goes back
			Set tNextLocalHourTime = $zdatetime(tCurrentLocal,3)
			Set tHourValue = $tr($j($p($p(tNextLocalHourTime," ",2),":",1),2)," ","0")
			Set tCompensatedCurrentTime = $p(tNextLocalHourTime," ",1)_"T"_tHourValue_":00:00"
			Set pSubjectToDuplicateSeconds = 3600
			Quit				
		}
		Set tdiffTime = ((($p(tCurrentUTCHourLocal,",",1)-$p(tCurrentLocal,",",1))*86400)+$p(tCurrentUTCHourLocal,",",2)-$p(tCurrentLocal,",",2))
		If tdiffTime > 3600 {
			#; We are about to go into jump forward but this is taken care of by dstCompensatedScheduleTime()
			Quit
		}
		If ((tdiffTime>0 && (tdiffTime<1800)) ||(tdiffTime>1800 && (tdiffTime<3600))) {
			#; Approaching the hour change so all good
			Quit
		}
		#;Recompute for 30 minute clock change.
		Set tCurrentUTCHalfHour = ($P(tCurrentUTC,",",1)+(($P(tCurrentUTC,",",2)+1800)\86400))_","_(($P(tCurrentUTC,",",2)+1800)#86400)
		Set tCurrentUTCHalfHourLocal = $zdatetimeh(tCurrentUTCHalfHour,-3)
		Set tCurrentLocalPlus30 =  ($P(tCurrentLocal,",",1)+(($P(tCurrentLocal,",",2)+1800)\86400))_","_(($P(tCurrentLocal,",",2)+1800)#86400)

		If tCurrentLocalPlus30 = tCurrentUTCHalfHourLocal {
			#; Not in time change slot
			Quit
		}
		If tCurrentUTCHalfHourLocal = tCurrentLocal {
			#; We are in a repeated half hour so return start of half hour for the duration since will be repeated when clock goes back 
			Set tNextLocalHalfHourTime = $zdatetime(tCurrentLocal,3)
			Set tHourValue = $tr($j($p($p(tNextLocalHourTime," ",2),":",1),2)," ","0")
			Set tMinuteValue = $tr($j($p($p(tNextLocalHourTime," ",2),":",2),2)," ","0")
			Set tMinuteValue = $S((+tMinuteValue<30):"00",1:"30")
			Set tCompensatedCurrentTime = $p(tNextLocalHalfHourTime," ",1)_"T"_tHourValue_":"_tMinuteValue_":00"
			Set pSubjectToDuplicateSeconds = 1800
			Quit				
		}
	} Catch {}
	
	Quit tCompensatedCurrentTime
}

/// This is a helper method to return number of duplicated (ambiguous) seconds 
/// when moving local time back (DST off) if current local time is in the first of 
/// the duplicated time slots.
/// 
ClassMethod ambiguousSecondsToAdd() As %String [ Internal ]
{
	#Dim tAmbiguousSecondsToAdd As %Integer
	Do ..dstCompensatedCurrentTime(.tAmbiguousSecondsToAdd)
	Quit tAmbiguousSecondsToAdd
}

ClassMethod adjust(dt, adjust) As %String
{
	set sign=$e(adjust,1)
	set type=$e(adjust,2,99)
	if type="X" quit ""
	set adjustment=$s(sign="+":1,sign="-":-1,1:0)
	if type="Y" {
		; move the year until the date is valid, this handles cases like every year on Feb 29th.
		; maximium 8 adjustments are needed because the longest span of non-leap year is 8 years
		for i=1:1:8 set dt("Y")=dt("Y")+adjustment,isvalid=..isValid(.dt) quit:isvalid
		if isvalid=0 quit ""
	} elseif type="M" {
		set dt("M")=dt("M")+adjustment
		if dt("M")<1  set dt("Y")=dt("Y")-1,dt("M")=dt("M")+12
		if dt("M")>12 set dt("Y")=dt("Y")+1,dt("M")=dt("M")-12
		; if date is invalid because month just got changes, change it again, this handles cases like every month on the 31th
		; only one more adjustment is enough because we never have 2 consecutive short months
		if ..isValid(.dt)=0 set dt("M")=dt("M")+adjustment
	} elseif type="W" {
		set dt("D")=dt("D")+(adjustment*7)
		do ..makeValid(.dt)
	} elseif $e(type)="G" {
		set weekcount=+$e(type,2,*)
		set oldmonth=dt("M")
		; the number 120 is somewhat arbitary.
		; If we can't find a 5th Sunday in 10 years, we just give up
		set isvalid=0
		for i=1:1:120 {
			set dt("D")=dt("D")+(adjustment*28)
			do ..makeValid(.dt)
			if dt("M")=oldmonth set dt("D")=dt("D")+(adjustment*7)
			do ..makeValid(.dt)
			set dt("D")=$tr((dt("D")#7),0,7)+((weekcount-1)*7)
			set isvalid=..isValid(.dt) quit:isvalid
			set dt("D")=$tr((dt("D")#7),0,7)
			set oldmonth=dt("M")
		}
		if isvalid=0 quit ""
	} elseif type'="" {
		set dt(type)=$g(dt(type))+adjustment
	}
	do ..makeValid(.dt)
	quit (+dt("Y"))_"-"_$tr($j(+dt("M"),2)," ","0")_"-"_$tr($j(+dt("D"),2)," ","0")_"T"_$tr($j(+dt("h"),2)," ","0")_":"_$tr($j(+dt("m"),2)," ","0")_":"_$tr($j(+dt("s"),2)," ","0")
}

ClassMethod isValid(dt) As %Boolean
{
	set DC(1)=31,DC(3)=31,DC(4)=30,DC(5)=31,DC(6)=30,DC(7)=31,DC(8)=31,DC(9)=30,DC(10)=31,DC(11)=30,DC(12)=31
	set y=dt("Y"),DC(2)=28+$s(y#400=0:1,y#100=0:0,y#4=0:1,1:0)
	quit dt("D")'>DC(+dt("M"))
}

ClassMethod makeValid(dt)
{
	set DC(1)=31,DC(3)=31,DC(4)=30,DC(5)=31,DC(6)=30,DC(7)=31,DC(8)=31,DC(9)=30,DC(10)=31,DC(11)=30,DC(12)=31
	set y=dt("Y"),DC(2)=28+$s(y#400=0:1,y#100=0:0,y#4=0:1,1:0)
	if dt("s")>59 set dt("m")=dt("m")+1,dt("s")=dt("s")-60
	if dt("s")<0  set dt("m")=dt("m")-1,dt("s")=dt("s")+60
	if dt("m")>59 set dt("h")=dt("h")+1,dt("m")=dt("m")-60
	if dt("m")<0  set dt("h")=dt("h")-1,dt("m")=dt("m")+60
	if dt("h")>23 set dt("D")=dt("D")+1,dt("h")=dt("h")-24
	if dt("h")<0  set dt("D")=dt("D")-1,dt("h")=dt("h")+24
	if dt("D")>DC(+dt("M")) set dt("D")=dt("D")-DC(+dt("M")),dt("M")=dt("M")+1
	if dt("D")<1            set dt("M")=dt("M")-1,DC(0)=31,dt("D")=DC(+dt("M"))+dt("D")
	if dt("M")>12 set dt("Y")=dt("Y")+1,dt("M")=dt("M")-12
	if dt("M")<1  set dt("Y")=dt("Y")-1,dt("M")=dt("M")+12
	quit
}

ClassMethod Test(pSchedule, pCurrentTime)
{
#define TST(%schedule,%direction,%currenttime,%expectedresult)
#define TEST(%schedule,%direction,%currenttime,%expectedresult) set result=..Next(%schedule,%direction,%currenttime) write %schedule," - ",?22,$s(result=%expectedresult:"passed",1:"       - failed"),"[",result,"]",!
	;
	; test onetime event
	$$$TEST("2005-08-08T09:00:00","+","2005-06-29T08:00:00","2005-08-08T09:00:00")
	$$$TEST("2004-08-08T09:00:00","+","2005-06-29T08:00:00","")
	; tests events on the same day
	$$$TEST("*-*-*T09:00:00","+","2005-06-29T08:00:00","2005-06-29T09:00:00")
	$$$TEST("*-*-*T09:00:00","-","2005-06-29T08:00:00","2005-06-28T09:00:00")
	; tests events on the next day
	$$$TEST("*-*-*T07:00:00","+","2005-06-29T08:00:00","2005-06-30T07:00:00")
	$$$TEST("*-*-*T07:00:00","-","2005-06-29T08:00:00","2005-06-29T07:00:00")
	; tests events on every month
	$$$TEST("*-*-05T07:00:00","+","2005-06-29T08:00:00","2005-07-05T07:00:00")
	$$$TEST("*-*-30T07:00:00","+","2005-06-29T08:00:00","2005-06-30T07:00:00")
	$$$TEST("*-02-29T07:00:00","+","2005-06-29T08:00:00","2008-02-29T07:00:00")
	$$$TEST("*-*-05T07:00:00","-","2005-06-29T08:00:00","2005-06-05T07:00:00")
	$$$TEST("*-*-30T07:00:00","-","2005-06-29T08:00:00","2005-05-30T07:00:00")
	$$$TEST("*-02-29T07:00:00","-","2005-06-29T08:00:00","2004-02-29T07:00:00")
	; tests skipping 06/31
	$$$TEST("*-*-31T07:00:00","+","2005-06-29T08:00:00","2005-07-31T07:00:00")
	$$$TEST("*-*-31T07:00:00","-","2005-06-29T08:00:00","2005-05-31T07:00:00")
	; tests events on every year
	$$$TEST("*-05-15T07:00:00","+","2005-06-29T08:00:00","2006-05-15T07:00:00")
	$$$TEST("*-06-30T07:00:00","+","2005-06-29T08:00:00","2005-06-30T07:00:00")
	$$$TEST("*-05-15T07:00:00","-","2005-06-29T08:00:00","2005-05-15T07:00:00")
	$$$TEST("*-06-30T07:00:00","-","2005-06-29T08:00:00","2004-06-30T07:00:00")
	; test every year on 02/29
	$$$TEST("*-02-29T07:00:00","+","2005-06-29T08:00:00","2008-02-29T07:00:00")
	$$$TEST("*-02-29T07:00:00","-","2005-06-29T08:00:00","2004-02-29T07:00:00")
	; 2005-06-29T08:00:00 is a Wednesday, tests events on every weekday
	$$$TEST("WEEK-*-3T07:00:00","+","2005-06-29T08:00:00","2005-07-06T07:00:00")
	$$$TEST("WEEK-*-3T09:00:00","+","2005-06-29T08:00:00","2005-06-29T09:00:00")
	$$$TEST("WEEK-*-0T07:00:00","+","2005-06-29T08:00:00","2005-07-03T07:00:00")
	$$$TEST("WEEK-*-5T07:00:00","+","2005-06-29T08:00:00","2005-07-01T07:00:00")
	$$$TEST("WEEK-*-3T07:00:00","-","2005-06-29T08:00:00","2005-06-29T07:00:00")
	$$$TEST("WEEK-*-3T09:00:00","-","2005-06-29T08:00:00","2005-06-22T09:00:00")
	$$$TEST("WEEK-*-0T07:00:00","-","2005-06-29T08:00:00","2005-06-26T07:00:00")
	$$$TEST("WEEK-*-5T07:00:00","-","2005-06-29T08:00:00","2005-06-24T07:00:00")
	; test events that happen on n-th week
	$$$TEST("WEEK-2-5T07:00:00","+","2005-06-29T08:00:00","2005-07-08T07:00:00")
	$$$TEST("WEEK-5-1T07:00:00","+","2005-06-29T08:00:00","2005-08-29T07:00:00")
	$$$TEST("WEEK-2-5T07:00:00","-","2005-06-29T08:00:00","2005-06-10T07:00:00")
	$$$TEST("WEEK-5-1T07:00:00","-","2005-06-29T08:00:00","2005-05-30T07:00:00")
	; test event at the same time as it should occur
	$$$TEST("2005-08-08T08:00:00","-","2005-08-08T08:00:00","2005-08-08T08:00:00")
	$$$TEST("2005-08-08T08:00:00","+","2005-08-08T08:00:00","")
	; test day-light-saving time
	$$$TEST("*-*-*T02:30:00","+","2009-03-08T01:45:00","2009-03-08T03:00:00@2009-03-08T02:30:00")
	$$$TEST("*-*-*T*:*:30","+","2009-03-08T01:59:33","2009-03-08T03:00:00@2009-03-08T02:00:30")
	$$$TEST("*-*-*T*:*:30","+","2009-03-08T03:00:00","2009-03-08T03:00:30")
	;test WEEK-wn-dn where wn-dn falls on a 7th or 14th or 21st or 28
	$$$TEST("WEEK-02-02T12:00:00","-","2015-07-14T12:12:12","2015-07-14T12:00:00")
	$$$TEST("WEEK-02-02T12:00:00","+","2015-07-14T12:12:12","2015-08-11T12:00:00")
	$$$TEST("WEEK-02-02T12:00:00","-","2015-08-11T12:12:12","2015-08-11T12:00:00")
	$$$TEST("WEEK-02-02T12:00:00","-","2015-08-11T11:12:12","2015-07-14T12:00:00")
	$$$TEST("WEEK-02-01T12:00:00","-","2015-08-10T11:12:12","2015-07-13T12:00:00")
	$$$TEST("WEEK-02-02T12:00:00","+","2015-08-11T12:12:12","2015-09-08T12:00:00")
	$$$TEST("WEEK-02-01T12:00:00","-","2015-07-13T12:12:12","2015-07-13T12:00:00")
	$$$TEST("WEEK-02-01T12:00:00","+","2015-07-13T12:12:12","2015-08-10T12:00:00")
	;
	/*
		Nov 7, 2021 - Daylight Saving Time Ended

	When local daylight time was about to reach
		Sunday, November 7, 2021, 2:00:00 am clocks were turned backward 1 hour to
		Sunday, November 7, 2021, 1:00:00 am local standard time instead.
	*/
	$$$TEST("*-*-*T01:05:00","+","2021-11-06T23:50:00","2021-11-07T01:05:00")
	$$$TEST("*-*-*T01:05:00","+","2021-11-07T01:00:00","2021-11-07T01:05:00")
	$$$TEST("*-*-*T02:05:00","+","2021-11-07T01:05:00","2021-11-07T02:05:00")
	;
	do ..ParseScheduleSpec("START:*-*-*T07:00:00,STOP:*-*-*T20:00:00",.tCurrentState,.tNextEvent)
	write "current state = ",$g(tCurrentState),!
	write "   next event = ",$g(tNextEvent),!
	;
	quit
}

/// Internal method used to recreate a primary request header for the scheduler.
Method recreatePrimaryRequestHeader(pRequestHeader As Ens.MessageHeader, Output pSC As %Status = {$$$OK}, Output pWarningText As %String = "") As Ens.MessageHeader [ Internal ]
{
	#dim tPrimaryRequestHeader As Ens.MessageHeader
	#dim ex As %Exception.AbstractException
	Try {
		Set tPrimaryRequestHeader=##class(Ens.MessageHeader).%New()
		Set tPrimaryRequestHeader.SourceBusinessType=$$$eHostTypeService
		Set tPrimaryRequestHeader.Type=$$$eMessageTypeRequest
		Set tPrimaryRequestHeader.Invocation=$$$eMessageInvocationQueue
		Set tPrimaryRequestHeader.SessionId=pRequestHeader.SessionId
		Set tPrimaryRequestHeader.SourceConfigName="Ens.ScheduleService"
		Set tPrimaryRequestHeader.TargetConfigName="Ens.ScheduleHandler"
		Set tPrimaryRequestHeader.TargetBusinessType=$$$eHostTypeProcess
		Set tPrimaryRequestHeader.TargetQueueName="Ens.ScheduleHandler"
		Set tPrimaryRequestHeader.Priority=$$$eMessagePriorityAsync
		Set tPrimaryRequestHeader.TimeCreated=$$$timeUTC
		Set tPrimaryRequestHeader.TimeProcessed=$$$timeUTC
		Set tPrimaryRequestHeader.Status=$$$eMessageStatusCompleted
		Set tPrimaryRequestHeader.Description=$$$Text("Primary Request rebuilt for Scheduler")
		Set pWarningText=$$$FormatText($$$Text("Recreating a primary request header for Ens.ScheduleHandler Business Process ID '%1' because primary request header has been purged."),pRequestHeader.BusinessProcessId)
	} Catch ex {
		Set tPrimaryRequestHeader = $$$NULLOREF
		Set pWarningText=$$$FormatText($$$Text("Failed to recreate a primary request header for Ens.ScheduleHandler Business Process ID '%1' after primary request header has been purged."),pRequestHeader.BusinessProcessId)
		Set pWarningText=pWarningText_" "_ex.DisplayString()
		Set pSC=$$$ERROR($$$EnsErrGeneral,pWarningText)
	}
	Quit tPrimaryRequestHeader
}

/// This method is used to clean up the $$$EnsRuntimeAppData("SchedulerHandler","AlarmSet") data
/// Called by Ens.MonitorService::Purge
ClassMethod PurgeAlarmSets(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; AlarmSet date is Local and has a T separating date and time (ISO 8601) irrespective of locale settings

		#; Do not allow cleaning current day
		#dim tDaysToKeep = pDaysToKeep
		If tDaysToKeep = 0 Set tDaysToKeep = 1

		#dim tDoNotDeleteDate = $$$timeUTCtoLocal(##class(Ens.Purge).GetDoNotDeleteDate(tDaysToKeep))

		#dim tAlarmSetDateToExamine = $Order($$$EnsRuntimeAppData("SchedulerHandler","AlarmSet",""))
		#dim tAlarmSetDateNoT = $Replace(tAlarmSetDateToExamine,"T"," ")

		While (tAlarmSetDateToExamine '= "") && ($SYSTEM.SQL.Functions.DATEDIFF("s",tAlarmSetDateNoT,tDoNotDeleteDate) > 0) {

			Kill $$$EnsRuntimeAppData("SchedulerHandler","AlarmSet",tAlarmSetDateToExamine)
			If $Increment(pDeletedCount) {}

			Set tAlarmSetDateToExamine = $Order($$$EnsRuntimeAppData("SchedulerHandler","AlarmSet",tAlarmSetDateToExamine))

			Set tAlarmSetDateNoT = $Replace(tAlarmSetDateToExamine,"T"," ")

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// This internal helper method used to check if outstanding (delivered)
/// alarm requests.
ClassMethod outstandingAlarmRequest(pConfigItem As %String = "Ens.ScheduleHandler") As %Boolean [ Internal ]
{
	#dim tSQL = "SELECT TOP 1 ID FROM Ens.MessageHeader head WHERE head.Status = ? AND head.SourceConfigName = ? AND head.TargetConfigName = 'Ens.Alarm'"
	#dim tStatement = ##class(%SQL.Statement).%New()
	/* Ensure logical mode */
	Set tStatement.%SelectMode = 0
	Return ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,$$$eMessageStatusDelivered,pConfigItem).%Next()
}

Method OnInit() As %Status
{
	If '$Data($$$EnsJobLocal("ScheduleHandler","InZoneWithClockChange")) {
		Set $$$EnsJobLocal("ScheduleHandler","InZoneWithClockChange") = ..inZonewithClockChanges()
	}
	Quit $$$OK
}

Method inZonewithClockChanges() As %Boolean [ Internal, Private ]
{
	Set tHorologDay=(+$h-$zdate($zts,14)+1)
	#; assumption that any clock change lasts longer than 10 days.
	For tDayInYear=1:10:364 {
		#; increment LocalTime minute value. Assumption clock change is not 12 hours.
		Do $i(offset($p($zdatetimeh((tHorologDay+tDayInYear),-3),",",2)))
		Set tHasChange = (($o(offset(""))'=$o(offset(""),-1)))
		Quit:tHasChange
	}
	Return tHasChange
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
