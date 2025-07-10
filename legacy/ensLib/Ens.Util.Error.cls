/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Util.Error [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod EnsError(pClassName As %String, pMethodName As %String, pErrorCode As %String, pMessage1 As %String, pMessage2 As %String, pMessage3 As %String, pFramesToHide As %Integer = 0)
{
	Set tSC=$$$ERROR($g(pErrorCode),$g(pMessage1),$g(pMessage2),$g(pMessage3))
	Do ##class(Ens.Util.Log).LogStatus(pClassName,pMethodName,tSC,pFramesToHide+1)
	Quit tSC
}

ClassMethod EnsSystemError(pClassName As %String, pMethodName As %String) As %Status
{
	If $G(^Ens.Debug("LogETN")) {
		#; %ETN doesn't log an error when $ZE is null OR $ZE["<INTERRUPT>"
		Set tZE=$ZE, tInfo=$$LOG^%ETN(), tDate=$List(tInfo,1), tSeq=$List(tInfo,2), tSource=$$VGet^%ERN($S(""=tDate:0,1:tDate),$S(""=tSeq:0,1:tSeq),"Line"), tDate=$ZDate(tDate,2)
	} Else {
		Set tZE=$ZE, tDate="-", tSeq="-", tLoc=$P($P($G(tZE),">",2)," "), tSource=$S(tLoc'["^":tLoc, 1:$Text(@tLoc))
	}
	Set $ZE = ""
	Quit ..EnsError(pClassName,pMethodName,$$$EnsErrException,$G(tZE)_" -- ",tDate,tSeq_" @'"_tSource_"'",1)
}

ClassMethod ExceptionStatus(pType As %String = "", exception As %Exception.AbstractException = "") As %Status
{
	If $G(^Ens.Debug("LogETN")) {
		#; %ETN doesn't log an error when $ZE is null OR $ZE["<INTERRUPT>"
		Set tZE=$ZE, tInfo=$$LOG^%ETN(), tDate=$List(tInfo,1), tSeq=$List(tInfo,2), tSource=$$VGet^%ERN($S(""=tDate:0,1:tDate),$S(""=tSeq:0,1:tSeq),"Line"), tDate=$ZDate(tDate,2)
	} Else {
		Set tZE=$ZE, tDate="-", tSeq="-", tLoc=$P($P($G(tZE),">",2)," "), tSource=$S(tLoc'["^":tLoc, 1:$Text(@tLoc))
	}
	Set $ZE = ""
	If exception'="" {
		Set exDisplay=", exception="_exception.DisplayString()
	} Else {
		Set exDisplay=""
	}
	Quit $$$ERROR($$$EnsErrException,$G(tZE)_$S(""=pType:"",1:"|"_pType)_" -- ",tDate,tSeq_" @'"_tSource_"'"_exDisplay)
}

}
