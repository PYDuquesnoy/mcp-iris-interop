/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspGatewayRegistry

/// Class allowing to load CSP.log into <class>%CSP.Util.CSPLogEvent</class> class and
/// search it using SQL.
Class %CSP.Util.CSPLogEvent Extends %Persistent [ System = 4 ]
{

/// used to be able to filter/delete a bad dataload
Property ImportTS As %TimeStamp;

Property EvtTimestamp As %TimeStamp [ Required ];

Property EvtDate As %Date [ Calculated, SqlComputeCode = { set {*} = $zdh($p({EvtTimestamp}," ",1),3)}, SqlComputed ];

Property RTBuild As %String;

Property LogLevel As %Integer;

Property GatewayID As %String;

Property GatewayPID As %Integer;

Property GatewayTID As %Integer;

Property ConnectionNo As %Integer;

Property Server As %String;

Property CachePID As %String;

Property RequestID As %String;

Property SessionID As %String;

Property RemoteAddr As %String;

Property Page As %String(MAXLEN = 300);

Property CallType As %String;

Property Payload As %String(MAXLEN = 32000);

Property CookieName As %String(MAXLEN = 255);

Property CookieSP As %Integer(MAXVAL = 65536, MINVAL = 1);

Property CookieUP As %String(MAXLEN = 255);

Property CookieValue As %String(MAXLEN = 100);

Property CookiePath As %String(MAXLEN = 1000);

Property CookieConn As %Integer;

Property CookieServer As %Integer;

Property CookieAppNo As %Integer;

Property CookiePrivateSession As %Boolean;

Index Session On SessionID [ Type = bitmap ];

Index SessionServer On (SessionID, Server);

Index Server On Server [ Type = bitmap ];

Index CallType On CallType [ Type = bitmap ];

Index Page On Page [ Type = bitmap ];

Index RemoteAddr On RemoteAddr [ Type = bitmap ];

Index Connection On ConnectionNo [ Type = bitmap ];

Index ServerNumberC On CookieServer [ Type = bitmap ];

Index ApplicationNumber On CookieAppNo [ Type = bitmap ];

Index GatewayID On GatewayID [ Type = bitmap ];

Index LogLevel On LogLevel [ Type = bitmap ];

Index EvtTimestamp On EvtTimestamp;

/// Imports CSP.log from CSP Gateway registry<br>
/// Displays all registered CSP Gateways and allow to select what log to load<br>
/// <br>
/// dateFromTS - timestamp in ODBC format or leave empty to load all data from the beginning of the log<br>
/// dateToTS - timestamp in ODBC format or leave empty to load all data to the end of the log<br>
/// Example: <example>Set res=##class(%CSP.Util.CSPLogEvent).GtwImport()</example>
ClassMethod GtwImport() As %String
{
 Set pGatewayID = 1,pRunTuneTable = 0, pFilterGZIPErrors = 0, pDeleteExtent = 0, display = 1
 
A Set Reg=$SYSTEM.CSP.GetGatewayRegistry()
 Set Mgrs=Reg.GetGatewayMgrs()
 Set count=Mgrs.Count()
 If count=0 Write "Nothing to select",! Quit "Nothing to select"
 For i=1:1:Mgrs.Count() {
	 Set Mgr=Mgrs.GetAt(i)
	 Write i_": "
	 Write Mgr.Server," ",Mgr.IPAddress," ",Mgr.Port," ",Mgr.Version,!
 	}
 Read "Select Gateway <ENTER to quit>: ",cnt
 If cnt="" Write "Nothing Selected",! Quit "Nothing Selected"
 Set Mgr=Mgrs.GetAt(cnt)
 if '$IsObject(Mgr) { Write " Incorrect Selection",!! goto A}
 Else {Write !,Mgr.Server," ",Mgr.IPAddress," ",Mgr.Port," ",Mgr.Version,!}
 
 Set sc=Mgr.GetCSPLog(.log,"",1,1)
 Set dateFromTS=..GetTS(log)
 Set Option=..OPTION("Date From?",(dateFromTS))
 Set dateFromTS=Option w $c(13),$j(" ",80),$c(13),"Date From?              : "_Option

 Set sc=Mgr.GetCSPLog(.log,"",-1,1)
 Set dateToTS=..GetTS(log)
 Set Option=..OPTION("Date To?",(dateToTS))
 Set dateToTS=Option  w $c(13),$j(" ",80),$c(13),"Date To                 : "_Option

 Set Option=$zcvt($E(..OPTION("Delete Extent?     ",$s(pDeleteExtent=1:"Y",1:"N"))),"U")
 Set pDeleteExtent=$S(Option="Y":1,1:0)     W $c(13),"Delete Extent           : "_Option
 
 Set Option=$zcvt($E(..OPTION("Run TuneTable?     ",$s(pRunTuneTable=1:"Y",1:"N"))),"U")
 Set pRunTuneTable=$S(Option="Y":1,1:0)     w $c(13),"Run TuneTable?          : "_Option

 Set Option=$zcvt($E(..OPTION("Filter GZIP Errors?",$s(pFilterGZIPErrors=1:"Y",1:"N"))),"U")
 Set pFilterGZIPErrors=$S(Option="Y":1,1:0) W $c(13),"Filter GZIP Errors      : "_Option

 Set Option=$zcvt($E(..OPTION("Confirm?           ","Y")),"U")
 If Option'="Y" W $c(13),"Not Confirmed           : "_Option Quit "Not Confirmed"
 W $c(13),"Confirm                 : "_Option

 s pGatewayID=Mgr.IPAddress_" "_Mgr.Port
 Set startDate = $$$FormatCSPLogDate(0)
 Set sc=Mgr.GetCSPLog(.log,startDate,1,999999)
 If 'sc Do $system.Status.DecomposeStatus(sc,.err) Write err(err),! Quit err(err)
 Quit ..Import(log, dateFromTS, dateToTS, pGatewayID, pRunTuneTable, pFilterGZIPErrors, pDeleteExtent, display)
}

/// Imports CSP.log from from CSP.log file<br>
/// Displays all registered CSP Gateways and allow to select what log to load<br>
/// <br>
/// dateFromTS - timestamp in ODBC format or leave empty to load all data from the beginning of the log<br>
/// dateToTS - timestamp in ODBC format or leave empty to load all data to the end of the log<br>
/// Example: <example>Set res=##class(%CSP.Util.CSPLogEvent).FileImport()</example>
ClassMethod FileImport(pFile) As %String
{
 #dim dateFromTS as %TimeStamp = ""
 #dim dateToTS  as %TimeStamp = ""
 Set pGatewayID = 1,pRunTuneTable = 0, pFilterGZIPErrors = 0, pDeleteExtent = 0, display = 1
 
 Set Option=..OPTION("File Name?","")
 If Option="" Write "Nothing Selected",! Quit "Nothing Selected"
 Set pFile=Option     W $c(13),$j(" ",80),$c(13),"File Name               : "_Option
 
 Set file=##class(%Stream.FileCharacter).%New()
 Set file.Filename=pFile
 Set file.LineTerminator=$c(13,10)
 
 Set dateFromTS=..GetTS(file)
 Set Option=..OPTION("Date From?",(dateFromTS))
 Set dateFromTS=Option, Option=$s(Option="":"Oldest",1:Option)
 w $c(13),$j(" ",80),$c(13),"Date From?              : "_Option

 Set Option=..OPTION("Date To?","")
 Set dateToTS=Option, Option=$s(Option="":"Latest",1:Option)
 w $c(13),$j(" ",80),$c(13),"Date To                 : "_Option

 Set Option=$zcvt($E(..OPTION("Delete Extent?     ",$s(pDeleteExtent=1:"Y",1:"N"))),"U")
 Set pDeleteExtent=$S(Option="Y":1,1:0)     W $c(13),"Delete Extent           : "_Option
 
 Set Option=$zcvt($E(..OPTION("Run TuneTable?     ",$s(pRunTuneTable=1:"Y",1:"N"))),"U")
 Set pRunTuneTable=$S(Option="Y":1,1:0)     w $c(13),"Run TuneTable?          : "_Option

 Set Option=$zcvt($E(..OPTION("Filter GZIP Errors?",$s(pFilterGZIPErrors=1:"Y",1:"N"))),"U")
 Set pFilterGZIPErrors=$S(Option="Y":1,1:0) W $c(13),"Filter GZIP Errors      : "_Option

 Set Option=$zcvt($E(..OPTION("Confirm?           ","Y")),"U")
 If Option'="Y" W $c(13),"Not Confirmed           : "_Option Quit "Not Confirmed"
 W $c(13),"Confirm                 : "_Option

 Quit ..Import(file, dateFromTS, dateToTS, pGatewayID, pRunTuneTable, pFilterGZIPErrors, pDeleteExtent, display)
}

/// Imports CSP.log from CSP.log file<br>
/// <br>
/// dateFromTS - timestamp in ODBC format or leave empty to load all data from the beginning of the log<br>
/// dateToTS - timestamp in ODBC format or leave empty to load all data to the end of the log<br>
/// Example: <example>Set res=##class(%CSP.Util.CSPLogEvent).FileImport(pFile,from,to,1,1,0,1,1)</example>
ClassMethod FileImportNoPrompt(pFile As %String, dateFromTS As %TimeStamp = "", dateToTS As %TimeStamp = "", pGatewayID = 1, pRunTuneTable = 0, pFilterGZIPErrors = 0, pDeleteExtent = 0, display = 0) As %String
{
	If '##class(%File).Exists(pFile) Quit $$$ERROR($$$GeneralError,"File does not exist")
	Set file=##class(%Stream.FileCharacter).%New()
	Set file.Filename=pFile
	Set file.LineTerminator=$c(13,10)
	Quit ..Import(file, dateFromTS, dateToTS, pGatewayID, pRunTuneTable, pFilterGZIPErrors, pDeleteExtent, display)
}

/// Imports CSP.log from stream<br>
/// <br>
/// dateFromTS - timestamp in ODBC format or leave empty to load all data from the beginning of the log<br>
/// dateToTS - timestamp in ODBC format or leave empty to load all data to the end of the log<br>
ClassMethod Import(pStream As %Stream.GlobalCharacter, dateFromTS As %TimeStamp = "", dateToTS As %TimeStamp = "", pGatewayID = 1, pRunTuneTable = 0, pFilterGZIPErrors = 0, pDeleteExtent = 0, display = 0) As %String
{
	// Set res=##class(%CSP.Util.CSPLogGEvent).Import(stream)
	Set cnt=0,imported=0
	Set gzipcnt=0
	Set startH=$zh,importTS=$zdt($zts,3)
	Set lastTS=""
	Set sc=$$$OK
	If pDeleteExtent Do ..%KillExtent()
	Do pStream.Rewind()
	Do {
		Set line=pStream.ReadLine()	
	} while (line'[ ">>> Time:")&&('pStream.AtEnd)
	
	while ('pStream.AtEnd) {
		
		Set obj=""
		Set obj=##class(%CSP.Util.CSPLogEvent).%New()
		Set obj.ImportTS=importTS	
		Set ts=..data(line,"Time: ")
		;w ts,!
		Set thisTS=..DateCvt(ts)
		If (cnt>0)&(cnt#10000=0) w:display cnt," events imported up to time stamp: ",$g(lastTS,"N/A"),", with total seconds elapsed=",$zh-startH,!
		If $i(cnt)
		If thisTS="" Set thisTS=lastTS
		Set obj.EvtTimestamp=thisTS
		Set lastTS=thisTS
		Set RTBuild=..data(line,"RT Build: ") If line["SM Build" Set obj.RTBuild=..data(line,"SM Build: ")
		Set RTBuild=$p(RTBuild," ",1)
		Set obj.RTBuild=RTBuild
		Set obj.LogLevel=..data(line,"Log-Level: ")
		Set obj.GatewayID=pGatewayID
		Set obj.GatewayPID=..data(line,"Gateway-PID: ")
		Set obj.GatewayTID=..data(line,"Gateway-TID: ")
		Set obj.ConnectionNo=..data(line,"Connection-No: ")
		Set obj.Server=..data(line,"Server: ")
		Set obj.CachePID=..data(line,"Cache-PID: ")
		Set obj.RequestID=..data(line,"Request-ID: ")
		Set obj.SessionID=..data(line,"Session-ID: ")
		Set obj.RemoteAddr=..data(line,"Remote-Addr: ")
		Set obj.Page=$p(..data(line,"Page: ")," ",2,99)
		Set obj.CallType=$p(..data(line,"Page: ")," ",1)
		Set obj.Payload=""
		Do {
			i line'="" Set obj.Payload=obj.Payload_line_pStream.LineTerminator
			Set line=pStream.ReadLine()
		} while (line'[ ">>> Time:")&&('pStream.AtEnd)
		#define b36(%x) ($a(%x)#87#48)*36+($a(%x,2)#87#48)*36+($a(%x,3)#87#48)
		If obj.LogLevel=3,obj.Payload [ "Set-Cookie:", obj.Payload [ "CSPSESSIONID" {
			Set cookie="CSPSESSIONID"_$p($p(obj.Payload,"CSPSESSIONID",2),";",1,2)
			Set (chdname,obj.CookieName)=$p($p(cookie,";",1),"=")
			Set obj.CookieSP            =$p($p(chdname,"-SP-",2),"-")
			Set obj.CookieUP            =$p($p(chdname,"-UP-",2),"-")
			Set (cspchd,obj.CookieValue)=$p($p(cookie,";",1),"=",2)
			Set obj.CookiePath          =$p($p(cookie,"path=",2),";")
			Set obj.CookieConn          =$$$b36($e(cspchd,1,3))
			Set obj.CookiePrivateSession=$e(cspchd,4)="p"
			Set obj.CookieServer        =$$$b36("0"_$e(cspchd,5,6))
			Set obj.CookieAppNo         =$$$b36("0"_$e(cspchd,7,8))
		}
        ; handle Payload: Connection Forcefully Closed [62]
        If obj.ConnectionNo="",obj.LogLevel=2 {
            Set ccAt=$find(obj.Payload,"Connection Forcefully Closed [")
            Set:ccAt>1 obj.ConnectionNo=$e(obj.Payload,ccAt,$find(obj.Payload,"]",ccAt)-2)
		}
		;w obj.Payload,!,!,!
		Set sc=$$$OK
		If ..CheckTS(thisTS,dateFromTS) continue
		If ..CheckTS(dateToTS,thisTS) continue
		If pFilterGZIPErrors {
			//only save If this isn't a GZIP error
			If obj.Payload'["cannot GZIP" {
				Set sc=obj.%Save()
			}
			else {
				s ^GZIPFiltered=$ZDT($ZTS,3)
				Set gzipcnt=gzipcnt+1
				Set imported=imported-1
			}
		}
		else {
			Set sc=obj.%Save()
		}
		If $$$ISERR(sc) { 
			Do:display DisplayError^%apiOBJ(sc)
			w:display !,"Last Event Processed:",!
			w:display obj.Payload,!
		}
		If $i(imported)
	}
	If pRunTuneTable {
		w:display "Running TuneTable...",!
		Do $SYSTEM.SQL.TuneTable("%CSP_Util.CSPLogEvent",0,display,,1,1)
	}
	If pFilterGZIPErrors Write:display !!,"The 'cannot GZIP' error filtered out: "_gzipcnt,!
	&sql(Select count(*) into :total from %CSP_Util.CSPLogEvent)
	IF SQLCODE s total="n/a"
	Write:display !!,"CSPLog Events Read: "_cnt_", Imported: "_imported_", Total: "_total,!
	Quit "CSPLog Events Read: "_cnt_", Imported: "_imported_", Total: "_total
}

ClassMethod data(str, del1, del2) As %String [ Private ]
{
	Set del2=$g(del2,";")
	Q $p($p(str,del1,2),del2,1)
}

ClassMethod DumpEvents(pFile, pLogLevel, pServer, pStartTime, pEndTime, pConnectionNo, pThreadId, pServerPID) As %String
{
	Set sql="Select Payload"
	Set sql=sql_" from %CSP.Util.CSPLogEvent WHERE ID IS NOT NULL"
	If $D(pLogLevel) Set sql=sql_" AND (LogLevel<='"_pLogLevel_"' OR LogLevel IS NULL)"
	If $D(pGatewayID) Set sql=sql_" AND (GatewayID='"_pGatewayID_"' OR GatewayID IS NULL)"
	If $D(pServer) Set sql=sql_" AND (Server='"_pServer_"' OR Server IS NULL)"
	If $D(pStartTime) Set sql=sql_" AND EvtTimestamp>='"_pStartTime_"'"
	If $D(pEndTime) Set sql=sql_" AND EvtTimestamp<='"_pEndTime_"'"
	If $D(pConnectionNo) Set sql=sql_" AND (ConnectionNo='"_pConnectionNo_"' OR ConnectionNo IS NULL)"
	If $D(pThreadId) Set sql=sql_" AND ThreadId='"_pThreadId_"' OR ConnectionNo IS NULL)"
	If $D(pServerPID) Set sql=sql_" AND ServerPID='"_pServerPID_"' OR ServerPID IS NULL)"
	Set sql=sql_" ORDER BY EvtTimestamp, ID"
	quit ..SqlToFile(pFile,sql)
}

ClassMethod SqlToFile(pFile, pSQL, display = 1) As %String
{
	Write:display pSQL,!!
	If pFile="" quit 0
	Set file=##class(%FileCharacterStream).%New()
	Set file.Filename=pFile
	Set result=##class(%SQL.Statement).%ExecDirect(.query,pSQL)
	Set cnt=0
	If $G(^GZIPFiltered) {
		Set sc=file.WriteLine("NOTE: Last Import of Events filtered 'cannot GZIP' error")
	}
	Set sc=file.WriteLine("SQL Query for Event Extraction:")
	Set sc=file.WriteLine(pSQL)
	Set sc=file.WriteLine("================================================")
	while (result.%Next()) {
		Set cnt=cnt+1
		Set data = result.Payload
		Set sc=file.Write(data)
	}
	Set sc=file.WriteLine("================================================")
	Set sc=file.WriteLine("Total Event Count="_cnt)
	Set sc=file.%Save()
	Write:display "CSPLog Events Exported: "_cnt
	quit "CSPLog Events Exported: "_cnt
}

ClassMethod DateCvt(pDate = "") As %String
{
	If pDate="" quit ""
	Set mm=$e(pDate,5,7),dd=$tr($e(pDate,9,10)," "),yy=$e(pDate,21,24)
	Set date=mm_" "_dd_" "_yy
	Set dateH=$ZDH(date,7,,,,,,,,1)
	Set datetime=$ZD(dateH,3)_" "_$e(pDate,12,19)
	Quit datetime
}

/// Returns 1 If TS1<TS2
ClassMethod CheckTS(TS1, TS2) As %String
{
	If $G(TS1)="" Quit 0
	If $G(TS2)="" Quit 0
	If $TR($ZDTH(TS1,3),",",".")<$TR($ZDTH(TS2,3),",",".") Quit 1
	Quit 0
}

/// Returns selected Option
ClassMethod OPTION(prompt, default, max) As %String
{
OPTION1 ; 
 w !
 w prompt w:default'="" " <"_default_">" w " : "
 r in i default'="",in="" q default
 q:in=""&(default="") ""
 i in=""""""!(in=" ")!($zconvert(in,"L")="null") q ""
 i $zconvert(in,"L")="e"!($zconvert(in,"L")="q") q -1
 i +$g(max)>0,'(in?1.2N)!(in<1)!(in>max) w !!,"Please enter a number between 1 and "_max,! g OPTION1
 q in
}

ClassMethod GetTS(pStream As %Stream.GlobalCharacter) As %TimeStamp
{
	Do pStream.Rewind()
	Do {
		Set line=pStream.ReadLine()	
	} while (line'[ ">>> Time:")&&('pStream.AtEnd)
	Q:line="" ""
	Set ts=..data(line,"Time: ")
	;w ts,!
	Set thisTS=..DateCvt(ts)
	Q thisTS
}

Storage Default
{
<Data name="CSPLogEventDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ImportTS</Value>
</Value>
<Value name="3">
<Value>EvtTimestamp</Value>
</Value>
<Value name="4">
<Value>RTBuild</Value>
</Value>
<Value name="5">
<Value>LogLevel</Value>
</Value>
<Value name="6">
<Value>GatewayPID</Value>
</Value>
<Value name="7">
<Value>GatewayTID</Value>
</Value>
<Value name="8">
<Value>ConnectionNo</Value>
</Value>
<Value name="9">
<Value>Server</Value>
</Value>
<Value name="10">
<Value>CachePID</Value>
</Value>
<Value name="11">
<Value>RequestID</Value>
</Value>
<Value name="12">
<Value>SessionID</Value>
</Value>
<Value name="13">
<Value>RemoteAddr</Value>
</Value>
<Value name="14">
<Value>Page</Value>
</Value>
<Value name="15">
<Value>Payload</Value>
</Value>
<Value name="16">
<Value>CookieName</Value>
</Value>
<Value name="17">
<Value>CookieSP</Value>
</Value>
<Value name="18">
<Value>CookieUP</Value>
</Value>
<Value name="19">
<Value>CookieValue</Value>
</Value>
<Value name="20">
<Value>CookiePath</Value>
</Value>
<Value name="21">
<Value>CookieConn</Value>
</Value>
<Value name="22">
<Value>CookieServer</Value>
</Value>
<Value name="23">
<Value>CookieAppNo</Value>
</Value>
<Value name="24">
<Value>CookiePrivateSession</Value>
</Value>
<Value name="25">
<Value>CallType</Value>
</Value>
<Value name="26">
<Value>GatewayID</Value>
</Value>
</Data>
<DataLocation>^IRIS.Temp.CSPLogEventD</DataLocation>
<DefaultData>CSPLogEventDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.Temp.CSPLogEventD</IdLocation>
<IndexLocation>^IRIS.Temp.CSPLogEventI</IndexLocation>
<StreamLocation>^IRIS.Temp.CSPLogEventS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
