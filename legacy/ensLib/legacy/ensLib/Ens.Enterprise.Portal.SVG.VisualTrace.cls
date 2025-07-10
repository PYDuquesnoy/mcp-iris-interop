/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.SVG.VisualTrace Extends EnsPortal.SVG.VisualTrace [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageTrace:USE";

Parameter TRACETYPE = "MsgBankTrace";

/// IOLog entries aren't available on the Message Bank, so don't attempt to look for them.
Parameter INCLUDEIOLOG = 0;

/// IOLog entries aren't available on the Message Bank, so don't attempt to look for them.
ClassMethod IncludeIOLogEntries() [ CodeMode = expression ]
{
0
}

/// Construct arrays containing the trace info for this message session:<br>
/// <var>^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")</var> contains info about each message.<br>
/// <var>cls</var> contains info about the Business classes used.<br>
/// This method returns the number of items (messages / events/ IOLog entries), the number of rows, 
/// the number of columns, the width and the height of the SVG diagram.
/// The format of this string is as follows:
/// [itemCount]#[rows]#[columns]#[width]#[height]
ClassMethod BuildTraceInfo(sessionId As %String = "", currPage As %String = "1") As %String [ Internal ]
{
	
	#; Note: there are 5 lanes encoded as follows:
	#; 0 = IO to/from Service
	#; 1 = Service
	#; 2 = Process 
	#; 3 = Operation
	#; 5 = IO to/from Operation

	#; get search parms from properties
	Set (startTime,endTime,startId,endId)="" // hcr
	&sql(SELECT SessionId INTO :sessionId FROM Ens_Enterprise_MsgBank.MessageHeader WHERE %ID = :sessionId)

	#; there are 3 types of filter: session, time, and id
	Set filter = "session"
	If ((startTime '= "") || (endTime '= "")) {
		Set filter = "time"
	}
	If ((startId '= "") || (endId '= "")) {
		Set filter = "id"
	}

	Set msgPerPage = $select($IsObject($get(%request)): $get(%request.Data("MSGPERPAGE",1),..#MSGPERPAGE), 1: ..#MSGPERPAGE)
	#; build spec for this query and test to see if temp data matches it
	
	Set tmc = $P($H,",",2)
	Set spec = ..BuildSpec("session",sessionId,startTime,endTime,startId,endId,.IncludeEvents,.EventsWindow,.EventsMaxRows,.ShowInternalItems,.IncludeIOLogEntries,.IncludeACKs)
	
	#; check if our temp data is for this request
	Lock +^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")
	If ..UseOldData(spec,tmc,currPage,msgPerPage,.returnValue) {
		Lock -^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")
		Quit returnValue
	}

	#; kill temp data
	Do ..ClearTraceData()
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"spec") = spec
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"tmc") = tmc

	#; Discover session boundaries (HCR076)
	Set SessionStartTime = ""
	Set SessionEndTime = ""
	Set SessionStartId = ""
	Set SessionEndId = ""
	&sql(DECLARE sqlSESSIONLIMITS CURSOR FOR 
		SELECT %ID, TimeCreated, TimeProcessed 
		INTO :id, :ctime, :ptime 
		FROM Ens_Enterprise_MsgBank.MessageHeader
		WHERE SessionId = :sessionId
	)
	&sql(OPEN sqlSESSIONLIMITS)
	Set id = "", ctime = "", ptime = ""
	&sql(FETCH sqlSESSIONLIMITS)
	While (SQLCODE=0) {
		If (id'="") && ((SessionStartId="") || (SessionStartId>id)) Set SessionStartId = id
		If (id'="") && ((SessionEndId="") || (SessionEndId<id)) Set SessionEndId = id
		If (ctime'="") && ((SessionStartTime="") || (SessionStartTime]ctime)) Set SessionStartTime = ctime
		If (ptime'="") && ((SessionEndTime="") || (SessionEndTime']ptime)) Set SessionEndTime = ptime
		&sql(FETCH sqlSESSIONLIMITS)
	}
	&sql(CLOSE sqlSESSIONLIMITS)
	#; Convert search parameters startTime and endTime to UTC
	If startTime = "" Set startTime1 = startTime
	Else  Set startTime1 = $$$timeLocaltoUTC(startTime)
	If endTime = "" Set endTime1 = endTime
	Else  Set endTime1 = $$$timeLocaltoUTC(endTime)
	#; Adjust search parameters based on session boundaries
	If (startId>SessionStartId) Set startId2 = startId
	Else  Set startId2 = SessionStartId
	If (endId'="") && (endId<SessionEndId) Set endId2 = endId
	Else  Set endId2 = SessionEndId
	If (startTime1]SessionStartTime) Set startTime2 = startTime1
	Else  Set startTime2 = SessionStartTime
	If (endTime1'="") && (endTime1']SessionEndTime) Set endTime2 = endTime1
	Else  Set endTime2 = SessionEndTime
	If (startId2>endId2) || (startTime2]endTime2) Quit "0#0#0#0#0" // Nothing will be retrieved!

	#; query for messages by session id
	&sql(DECLARE sqlSESSION CURSOR FOR 
		SELECT %ID, TimeCreated, SourceConfigName, 
			TargetConfigName, BusinessProcessId, Type, 
			ClientBodyClassName, MessageBodyId, ReturnQueueName, CorrespondingMessageId,
			Status, IsError, SourceBusinessType, TargetBusinessType
		INTO :id, :ctime, :sourceClass, :targetClass, 
			:bprocid, :msgtype, :classname, :body, :returnQueue, :reqID,
			:status, :iserr, :ortype, :desttype
		FROM Ens_Enterprise_MsgBank.MessageHeader
		WHERE SessionId = :sessionId
		ORDER BY TimeCreated, %ID
		)

	#; query for messages by time and id
	&sql(DECLARE sqlTIMEID CURSOR FOR 
		SELECT %ID, TimeCreated, SourceConfigName, 
			TargetConfigName, BusinessProcessId, Type, 
			ClientBodyClassName, MessageBodyId, ReturnQueueName, CorrespondingMessageId,
			Status, IsError, SourceBusinessType, TargetBusinessType
		INTO :id, :ctime, :sourceClass, :targetClass, 
			:bprocid, :msgtype, :classname, :body, :returnQueue, :reqID,
			:status, :iserr, :ortype, :desttype
		FROM Ens_Enterprise_MsgBank.MessageHeader
		WHERE SessionId = :sessionId AND TimeCreated >= :startTime2 AND TimeCreated <= :endTime2 AND
			%ID >= :startId2 AND %ID <= :endId2
		ORDER BY TimeCreated, %ID
		)

	#; queries for events
	&sql(DECLARE sqlEVENTTIME CURSOR FOR 
		SELECT %ID, SessionId, TimeLogged, ConfigName, Type, MessageId, SourceClass
		INTO :eventId, :sesId, :eventTime, :eventHost, :eventType, :eventMsg, :eventClass
		FROM Ens_Enterprise_MsgBank.Log
		WHERE TimeLogged >= :startTime2 AND TimeLogged <= :endEventTime
		ORDER BY TimeLogged
		)

	Kill tEvents
	If IncludeEvents && (EventsMaxRows>0) {
		#; get events and sort by time

		#; Calculate latest time for events based on last TimeProcessed,or EndTime search filter, plus EventsWindow (HCR076)
		Set fs = $P(endTime2,".",2), endEventTime = $P(endTime2,".",1)
		Set dt = $ZDTH(endEventTime,3,1,,,,,,,-1)
			If dt'=-1 {
				Set t = $P(dt,",",2)+EventsWindow
				If t<86400 Set $p(dt,",",2) = t
				Else  Set $P(dt,",",1) = $P(dt,",",1)+1, $P(dt,",",2) = t-86400
				Set endEventTime = $ZDT(dt,3,1)_"."_fs // Put back the fractional part
			}
		#; ... and limit the number of Event Log rows that are scanned to EventsMaxRows (HCR076)
		Set k = 0
		&sql(OPEN sqlEVENTTIME)
		&sql(FETCH sqlEVENTTIME)
		While (SQLCODE = 0) {
			Set k = k+1 If k>EventsMaxRows Quit  // Reached EventsMaxRows
 			If sesId=sessionId {
 				// Event generated by the session
 				Set:eventHost="" eventHost=eventClass
 				Set:eventHost'="" tEvents(eventTime_"#"_eventMsg,eventId) = $LB(eventHost, eventType)
 			}
   			&sql(FETCH sqlEVENTTIME)
		}
		&sql(CLOSE sqlEVENTTIME)
	}

	Set tEventTime = $O(tEvents(""))

	// figure out types of origin etc.
	Set n = 0
	Set tRowCount = 0

	If (filter="time") || (filter="id") {
		&sql(OPEN sqlTIMEID)
		&sql(FETCH sqlTIMEID)
	}
	Else {
		// filter="session"
		&sql(OPEN sqlSESSION)
		&sql(FETCH sqlSESSION)
	}

	Kill internalItems Do:'ShowInternalItems ..ArrayOfInternalItems(.internalItems)
	Kill noHeight
	Kill tErrors

	While (SQLCODE = 0) {
		#; Check if message body class is on the list of internal items to be skipped
		If classname=$C(0) Set classname="" ; This is when no message such as sent to Ens.ScheduleHandler
		If (classname="") || ('$D(internalItems(classname))) {
			Set tSameRow = 0
			Do InjectEvents()

			Set n = n + 1
			Set tRowCount = tRowCount + 1
			Set ortype=+ortype
			Set desttype=+desttype
			Kill findACK
			Set findACK = 0

			// TODO: Joe will change the page to support the "Unknown" column
			If ortype=0 Set ortype=2
			If desttype=0 Set desttype=2

			// set msg array
			Set msgIndex(id) = n
			Kill currentMsgData 
		
			Set currentMsgData("id") = id
			Set currentMsgData("time") = $$$timeUTCtoLocal(ctime)
			Set currentMsgData("orType") = ortype
			Set currentMsgData("destType") = desttype
		
			If classname="" {
				Set currentMsgData("msgClass") = "NULL"
			} else {
				Set currentMsgData("msgClass") = classname
			}
			Set currentMsgData("sourceClass") = sourceClass
			Set currentMsgData("targetClass") = targetClass
			Set currentMsgData("callType") = ""
			Set currentMsgData("msgType") = "Request"
			Set currentMsgData("status") = status

			If (msgtype = 2) {
				Set currentMsgData("msgType") = "Response"
				Set currentMsgData("callType") = "Response"
				Set currentMsgData("back") = reqID
			}
			Else {
				If (returnQueue = "") {
					// fire / forget
					Set currentMsgData("callType") = "NoResponse"
				}
				ElseIf ($$$queueIsPrivateQueue(returnQueue) || (+returnQueue=returnQueue)) {
					// private
					Set currentMsgData("callType") = "Sync"
				}
				Else {
					// async
					Set currentMsgData("callType") = "Async"
				}
			}

			If ((reqID '= "") && ($D(msgIndex(reqID)))) {
				// point our request to us
				Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",msgIndex(reqID),"respNo") = n
				If (^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",msgIndex(reqID),"callType") = "Sync") {
					Set currentMsgData("callType") = "SyncResponse"
				}
				Else {
					Set currentMsgData("callType") = "AsyncResponse"
				}
				// Also create up pointer for situation where previous message is not on the same page
				Set currentMsgData("backPos") = msgIndex(reqID)
			}

			// test for messages with errors
			If (iserr) {
				Set currentMsgData("msgType") = "Error"
			}
			
			Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n) = currentMsgData

			// cls array (remember earliest time (msgid) for each class)
			Set t = $G(cls(ortype,sourceClass))
			If ((t="") || (t>id)) {
				Set cls(ortype,sourceClass) = id _ ".1", clsInv(sourceClass) = ortype
			}

			Set t = $G(cls(desttype,targetClass))
			If ((t="") || (t>id)) {
				Set cls(desttype,targetClass) = id _ ".2", clsInv(targetClass ) = desttype
			}

			Set tSameRow = 0
			Do InjectEvents()
		}

		If (filter = "time") || (filter = "id") {
			&sql(FETCH sqlTIMEID)
		}
		Else {
			&sql(FETCH sqlSESSION)
		}
	}

	If (filter = "time") || (filter = "id") {
		&sql(CLOSE sqlTIMEID)
	}
	Else {
		&sql(CLOSE sqlSESSION)
	}

	#; get remaining events
	Set ctime = "9999"
	Set tSameRow = 0
	Do InjectEvents()

	#; put meta data in 0 node
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"count") = n
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"rowcount") = tRowCount
	Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"noheight") = noHeight

	#; get number of columns
	Set cc = ..GetColCount(currPage, .cls)
	
	Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clsinfo") = cls
	Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clslane") = clsInv
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"columns") = cc
	Lock -^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")

	#; return total number of messages and other items found, plus number of rows and columns
	Set startMessage = ((currPage - 1) * msgPerPage) + 1

	Quit ..CalculateDimensions(n,tRowCount,cc,startMessage,.noHeight) // No.items # No.rows # No.cols # width # height

InjectEvents()
	// No ACKs or IOLog entries on Message Bank, but same structure is used to allow for simpler maintenance
	// event time is "time#msgId"
	While 1 {
		// inject events into list
		Set tNextEvent = $p(tEventTime,"#")
		Set tNextEventMsgId = $p(tEventTime,"#",2)
		
		; event comes first because no others
		// Quit if last event OR event logged after message created
		If (tNextEvent = "") || (tNextEvent ] ctime) || ((tNextEvent = ctime) && (tNextEventMsgId >= id)) {
			Quit
		}
		Set tEventId = $O(tEvents(tEventTime,""))
		While (tEventId'="") {
			Set tName = $LG(tEvents(tEventTime,tEventId),1)
			If $D(clsInv(tName)) { // associated config item is already on diagram
				Set n = n + 1
				Set tRowCount = tRowCount + 1
				Kill tCurrentData
				Set tCurrentData("event") = 1
				Set tCurrentData("id") = tEventId
				Set tCurrentData("sourceClass") = $LG(tEvents(tEventTime,tEventId),1)
				Set tCurrentData("type") = $LG(tEvents(tEventTime,tEventId),2)
				Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n) = tCurrentData
			}
			Set tEventId = $O(tEvents(tEventTime,tEventId))
		}
		Set tEventTime = $O(tEvents(tEventTime))
	}
	Quit
}

}
