/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Visual Trace SVG Page<br>
/// This page renders the SVG needed to display a visual trace.
Class EnsPortal.SVG.MessageTrace Extends %ZEN.SVGComponent.svgPage [ System = 4 ]
{

/// User needs USE privilege on the %Ens_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MessageTrace";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Number of messages displayed on a page
Parameter MSGPERPAGE = 100;

/// Number of seconds that the cached Trace Temp File is valid.
Parameter CACHETIMEOUT = 5;

/// Enable inclusion of Event Log entries
Parameter INCLUDEEVENTS = 1;

/// Additional time in seconds after processed time of last message in trace to scan for events
Parameter EVENTSWINDOW = 30;

/// Maximum number of event log entries to be scanned to look for events
Parameter EVENTSMAXROWS = 1000;

/// Include IOLog Entries in display
Parameter INCLUDEIOLOG = 1;

/// Enable display of internal messages and related events
Parameter SHOWINTERNALITEMS = 0;

/// Session to trace
Property sessionId As %String(ZENURL = "SESSIONID");

/// Start time for trace
Property startTime As %String(ZENURL = "STARTTIME");

/// End time for trace
Property endTime As %String(ZENURL = "ENDTIME");

/// Start Id for trace
Property startId As %String(ZENURL = "STARTID");

/// End Id for trace
Property endId As %String(ZENURL = "ENDID");

/// Curr page of trace
Property currPage As %String(ZENURL = "PAGE");

ClassMethod IncludeEvents() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","IncludeEvents"), ..#INCLUDEEVENTS)
}

ClassMethod EventsWindow() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","EventsWindow"), ..#EVENTSWINDOW)
}

ClassMethod EventsMaxRows() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","EventsMaxRows"), ..#EVENTSMAXROWS)
}

ClassMethod IncludeIOLogEntries() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","IncludeIOLogEntries"), ..#INCLUDEIOLOG)
}

ClassMethod ShowInternalItems() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","ShowInternalItems"), ..#SHOWINTERNALITEMS)
}

ClassMethod ArrayOfInternalItems(Output v As %String)
{
	// Build a local array indexed with message body class names that will NOT be displayed on 
	// the diagram unless option to show internal items is selected
	Set v("EnsLib.DICOM.Message.Poll") = ""
	Set v("EnsLib.DICOM.Message.SessionAck") = ""
	Set v("EnsLib.DICOM.Message.SessionStart") = ""
	Set v("EnsLib.DICOM.Message.SessionStop") = ""
	Set v("EnsLib.PrivateSession.Message.Ack") = ""
	Set v("EnsLib.PrivateSession.Message.Poll") = ""
	Set v("EnsLib.PrivateSession.Message.Start") = ""
	Set v("EnsLib.PrivateSession.Message.Stop") = ""
	Quit
}

Method %OnDrawSVGPage() As %Status
{
	Set tSC = ..DrawMessageTrace()
	Quit tSC
}

/// Draw the SVG message trace
Method DrawMessageTrace() As %Status
{
	Set sessionId = $G(%request.Data("SESSIONID",1))
	If sessionId="" {
		// we don't have a session id
		&html<<text class="GeneralMessage" x="10" y="36" text-anchor="start">#($$$TextHTML("Please provide a Session ID"))#</text>>
		Quit $$$OK
	}
	//Set startTime = $G(%request.Data("STARTTIME",1))
	//Set endTime = $G(%request.Data("ENDTIME",1))
	//Set startId = $G(%request.Data("STARTID",1))
	//Set endId = $G(%request.Data("ENDID",1))

	/*
	// find loading div in outer html
	var loadingDiv = self.document.getElementById("loading");
	if (loadingDiv) {
		loadingDiv.style.display = 'none';
	}
	
	setCanvasSize(#(canvasWidth)#,#(canvasHeight)#);
	*/

	Set currPage = $G(%request.Data("PAGE",1))
	//Set canvasHeight = $G(%request.Data("$HEIGHT",1),800) // !!! hcr
	//Set canvasWidth = $G(%request.Data("$WIDTH",1),1200) // !!! hcr
			
	#; build trace info
	Set n = ..BuildTraceInfo(sessionId, currPage)
	Merge cls = ^IRIS.TempMsgTrace(%session.SessionId,0,"clsinfo")
	Merge clsInv = ^IRIS.TempMsgTrace(%session.SessionId,0,"clslane")
	Merge noHeight = ^IRIS.TempMsgTrace(%session.SessionId,0,"noheight")

	If ('n) || ($O(cls(""))="") {
		// nothing to show
		&html<<text class="GeneralMessage" x="10" y="36" text-anchor="start">#($$$TextHTML("No messages selected for tracing."))#</text>>
		Quit $$$OK
	}

	Set hostWidth = 170 // width of each host column
	Set hostLineWidth = 16 // width of line within a host column
	Set canvasWidth = $P(n,"#",3)*hostWidth + 200
	Set canvasHeight = $P(n,"#",2)*80 + 100

	&html<<script language="javascript">
	var svg = top.document.getElementById("SVGTrace");
	svg.setAttribute("width",#(canvasWidth)#);
	svg.setAttribute("height",#(canvasHeight)#);
	svg.setAttribute("viewBox","0 0 #(canvasWidth)# #(canvasHeight)#");
	</script>
	>

	#; canvas
	&html<<rect class="canvas" x="0" y="0" width="#(canvasWidth)#" height="#(canvasHeight)#" onmousedown="svgPage.clickCanvas(evt);"/>>

	Set laneTitle(0) = $$$Text("IO")
	Set laneTitle(1) = $$$Text("Services")
	Set laneTitle(2) = $$$Text("Processes")
	Set laneTitle(3) = $$$Text("Operations")
	Set laneTitle(4) = $$$Text("IO")

	#; find the size of each of the lanes
	#; build index of columns by time
	Set colCount(0) = 0
	Set colCount(4) = 0

	If $d(cls(0)) {
		Set laneWidth(0) = hostWidth
		Set colOrder(0,"IOInput")="Service.IO"
		Set colCount(0) = 1
		Set laneX(0) = 0
	}

	For lane = 1:1:3 {
		Kill colTime
		Set colCount(lane) = 0

		#; build index of columns by initial msg id
		Set k = $O(cls(lane,""))
		While (k '= "") {
			Set colTime(cls(lane,k)) = k
			Set colCount(lane) = colCount(lane) + 1
			Set k = $O(cls(lane,k))
		}
		
		#; make list of cols by msg id (time), assign # to cls index
		Set c = 0
		Set t = $O(colTime(""))
		While (t '= "") {
			Set c = c + 1
			#; col# --> classname
			Set colOrder(lane,c) = colTime(t)
			Set cls(lane,colTime(t)) = c
			Set t = $O(colTime(t))
		}
		
		#; calculate size/pos of lane
		Set laneWidth(lane) = colCount(lane) * hostWidth
		Set laneX(lane) = $G(laneX(lane-1),0) + $G(laneWidth(lane-1),0)
	}

	If $d(cls(4)) {
		Set laneWidth(4) = hostWidth
		Set laneX(4) = $G(laneX(3),0) + $G(laneWidth(3),0)
		Set colOrder(4,"IOOutput")="Operation.IO"
		Set colCount(4) = 1
	}

	#; title bar 		<text class="PaneTitle" x="10" y="15" text-anchor="start">#($$$Text("Visual Trace"))#</text>

	&html<<rect class="diagramHeader" x="0" y="0" width="#(canvasWidth)#" height="40" />>
	//	<text class="PaneAction" x="130" y="15" text-anchor="start">#($$$Text("Back to Message Viewer"))#</text>
	//	<text class="PaneAction2" x="#(canvasWidth-100)#" y="15" text-anchor="start">#($$$Text("Printable Version"))#</text>
	//>
	/*
	If $d(cls(0)) &html<<line class="SepLine" x1="#(laneX(1))#" y1="0" x2="#(laneX(1))#" y2="#(canvasHeight)#" />>
	&html<
		<line class="SepLine" x1="#(laneX(2))#" y1="0" x2="#(laneX(2))#" y2="#(canvasHeight)#" />
		<line class="SepLine" x1="#(laneX(3))#" y1="0" x2="#(laneX(3))#" y2="#(canvasHeight)#" />
	>
	If $d(cls(4)) &html<<line class="SepLine" x1="#(laneX(4))#" y1="0" x2="#(laneX(4))#" y2="#(canvasHeight)#" />>
	*/

	#; lanes and titles (types, components, background)
	Set nl = 0
	For lane = 0:1:4 {
		if (colCount(lane) > 0) {
			&html<<text class="LaneTitle" x="#(laneX(lane)+10)#" y="34" text-anchor="start">#(laneTitle(lane))#</text>>
			
			#; draw each host/component within the lane
			Set c = $O(colOrder(lane,""))
			Set x = laneX(lane)
			Set f = 1 // first of this group
			While (c '= "") {
				Set k = colOrder(lane,c)
				Set pkgName = $P(k,".",1,$L(k,".")-1)
				Set clsName = $P(k,".",$L(k,"."))
				Set xm = x + (hostWidth / 2)
				Set nl = nl+1
				If (nl>1) {
					&html<<line class="SepLine#(f)#" x1="#(x)#" y1="#(40-(f*40))#" x2="#(x)#" y2="#(canvasHeight)#" />>
					Set f = 0
				}
				&html<
					<rect class="LaneRect#(nl#2)#" x="#(x)#" y="70" width="#(laneWidth(lane))#" height="#(canvasHeight-70)#" onmousedown="svgPage.clickCanvas(evt);" />
					<clipPath id="cliphost_#(k)#"><rect x="#(x+5)#" y="40" width="#(hostWidth-6)#" height="30" style="fill:white; stroke:blue;" /></clipPath>
					<rect class="HostLine" id="host_#(k)#_line" x="#(xm-(hostLineWidth/2))#" y="70" width="#(hostLineWidth)#" height="#(canvasHeight-70)#" />
					<rect class="HostRect" id="host_#(k)#" x="#(x+2)#" y="40" width="#(hostWidth-4)#" height="30" rx="3" onmousedown="svgPage.clickHost(evt);" />
					<text class="HostTitle" x="#(xm)#" y="52" clip-path="url(#cliphost_#(k)#)" text-anchor="middle">#(pkgName)#</text>
					<text class="HostTitle" x="#(xm)#" y="65" clip-path="url(#cliphost_#(k)#)" text-anchor="middle">#(clsName)#</text>
				>

				#; draw helper text along the host rect (going down)
				Set yt = 400
				While (yt < (canvasHeight - 75)) {
					&html<
						#; writing-mode="tb", not supported- use rotate 
						<text class="HostRectLabel" x="#(xm)#" y="#(yt)#" text-anchor="middle" transform="rotate(90,#(xm)#,#(yt)#) translate(0,5)" >
						#(clsName)#</text>
					>

					Set yt = yt + 400
				}

				Set x = x + hostWidth
				Set c = $O(colOrder(lane,c))
			}
		}
	}
	//&html<<line class="SepLine" x1="#(laneX(lane)+hostWidth)#" y1="0" x2="#(laneX(lane)+hostWidth)#" y2="#(canvasHeight)#" />> !!! consertar

	#; draw time line (going down)
	Set yt = 300
	While (yt < (canvasHeight - 75)) {

		&html<
			<line class="Time" x1="20" y1="#(yt-200)#" x2="20" y2="#(yt)#" />
			<line class="Time" x1="15" y1="#(yt-5)#" x2="20" y2="#(yt)#" />
			<line class="Time" x1="25" y1="#(yt-5)#" x2="20" y2="#(yt)#" />
			<text class="HostRectLabel" x="13" y="#(yt-100)#" text-anchor="middle" transform="rotate(90,13,#(yt-100)#) translate(0,5)" >
				Time</text>
		>
		Set yt = yt + 400
	}

	#; draw messages
	Set topY = 100
	Set y = topY
	Set deltaY = 40

	Set msgcount = 0
	Set n = ((..currPage-1) * ..#MSGPERPAGE) + 1
	While ((n '= "") && (msgcount < ..#MSGPERPAGE)) {
		If $G(^IRIS.TempMsgTrace(%session.SessionId,n,"event")) {
			// draw event marker
			Set hostname=^IRIS.TempMsgTrace(%session.SessionId,n,"sourceClass")
			If ""'=hostname {
				Set laneStart = $G(clsInv(hostname))
				If ""'=laneStart {
					Set colStart = $G(cls(laneStart,hostname))
					If ""'=colStart {
						Set xStart = laneX(laneStart) + ((colStart-1) * hostWidth) + (hostWidth / 2)
						Set eventId = ^IRIS.TempMsgTrace(%session.SessionId,n,"id")
						Set eventType = ^IRIS.TempMsgTrace(%session.SessionId,n,"type")
			
						Set eventStyle = "eventMarkerBack"
						&html<<rect class="#(eventStyle)#" x="#(xStart-7)#" y="#(y-7)#" width="14" height="14"/>>
			
						Set eventStyle = "eventMarker"_eventType
						Set path =  "M " _(xStart-6)_" "_y_" L "_xStart_" "_(y+6)_" "_(xStart+6)_" "_y_" "_xStart_" "_(y-6)_" z"
						&html<<path class="#(eventStyle)#" d="#(path)#" onmousedown="clickEvent(evt,'#(eventId)#');"/>>
			
						&html<<text class="MsgLabel" x="#(xStart - 12)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			
						Set y = y + deltaY	
					}
				}
			}
		}
		ElseIf $G(^IRIS.TempMsgTrace(%session.SessionId,n,"iolog")) {
			Set hostname = ^IRIS.TempMsgTrace(%session.SessionId,n,"host")
			Set inbound = $g(^IRIS.TempMsgTrace(%session.SessionId,n,"inbound"),0)
			Set laneStart = $s(inbound: 0, 1:4)
			Set xStart = laneX(laneStart) + (hostWidth / 2)
			Set ioId = ^IRIS.TempMsgTrace(%session.SessionId,n,"id")

			&html<<g id="ioLog#(n)#" onmousedown="clickIOEntry(evt,'#(ioId)#','ioLogRect#(n)#');" >>
			Set ioStyle = "eventMarkerBack"
			&html<<rect id="ioLogRect#(n)#" class="#(ioStyle)#" x="#(xStart-9)#" y="#(y-9)#" width="18" height="18" entrytype="ioEntry" entryid="#(ioId)#" />>

			Set ioStyle = "ioArrows"
			Set topPath =  "M " _(xStart-7)_" "_(y-5)_" L "_(xStart+1)_" "_(y-5)_" "_(xStart+1)_" "_(y-8)_" "_(xStart+8)_" "_(y-4)_" "_(xStart+1)_" "_(y+1)_" "_(xStart+1)_" "_(y-2)_" "_(xStart-8)_" "_(y-2)_" z"
			&html<<path class="#(ioStyle)#" d="#(topPath)#" />>

			Set bottomPath =  "M " _(xStart+7)_" "_(y+5)_" L "_(xStart-1)_" "_(y+5)_" "_(xStart-1)_" "_(y+8)_" "_(xStart-8)_" "_(y+4)_" "_(xStart-1)_" "_(y-1)_" "_(xStart-1)_" "_(y+2)_" "_(xStart+8)_" "_(y+2)_" z"
			&html<<path class="#(ioStyle)#" d="#(bottomPath)#" />>

			&html<<text class="MsgLabel" x="#(xStart - 13)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			&html<</g>>
			If (inbound)&&$data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"id"),nextmsgId) {
				If $g(nextmsgId) '= ^IRIS.TempMsgTrace(%session.SessionId,n,"msgid") {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}
		ElseIf $G(^IRIS.TempMsgTrace(%session.SessionId,n,"ack")) {
			Set hostname = ^IRIS.TempMsgTrace(%session.SessionId,n,"host")
			Set inbound = $g(^IRIS.TempMsgTrace(%session.SessionId,n,"inbound"),0)
			Set laneStart = $s(inbound: 0, 1:4)
			Set xStart = laneX(laneStart) + (hostWidth / 2)
			Set ackId = ^IRIS.TempMsgTrace(%session.SessionId,n,"id")
			Set ackClass = ^IRIS.TempMsgTrace(%session.SessionId,n,"msgclass")

			Set ackStyle = "ackBack"
			&html<<g id="ack#(n)#" onmousedown="clickACK(evt,'#(ackClass)#','#(ackId)#','ackRect#(n)#');" >>
			&html<<rect id="ackRect#(n)#" class="#(ackStyle)#" x="#(xStart-7)#" y="#(y-7)#" width="14" height="14" entrytype="ack" entryid="#(ackClass)#:#(ackId)#"/>>

			Set ackStyle = "ackArrow"
			Set path =  "M " _(xStart-6)_" "_y_" L "_xStart_" "_(y+5)_" "_xStart_" "_(y+1)_" "_(xStart+6)_" "_(y+1)_" "_(xStart+6)_" "_(y-2)_" "_xStart_" "_(y-2)_" "_xStart_" "_(y-6)_" z"

			&html<<path class="#(ackStyle)#" d="#(path)#" />>
			&html<<text class="MsgLabel" x="#(xStart - 14)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			&html<</g>>
			If (inbound)&&$data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"id"),nextmsgId) {
				If $g(nextmsgId) '= ^IRIS.TempMsgTrace(%session.SessionId,n,"msgid") {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}
		Else {
			Set laneStart = ^IRIS.TempMsgTrace(%session.SessionId,n,"orType")
			Set laneEnd = ^IRIS.TempMsgTrace(%session.SessionId,n,"destType")

			Set colStart = cls(laneStart,^IRIS.TempMsgTrace(%session.SessionId,n,"sourceClass"))
			Set colEnd = cls(laneEnd,^IRIS.TempMsgTrace(%session.SessionId,n,"targetClass"))

			Set xStart = laneX(laneStart) + ((colStart-1) * hostWidth) + (hostWidth / 2)
			Set zend = laneX(laneEnd) + ((colEnd-1) * hostWidth) + (hostWidth / 2)

			#; draw message line
			Set msgId = ^IRIS.TempMsgTrace(%session.SessionId,n,"id")
			Set msgTime = ^IRIS.TempMsgTrace(%session.SessionId,n,"time")
			Set msgClass = ^IRIS.TempMsgTrace(%session.SessionId,n,"msgClass")
			Set callType = ^IRIS.TempMsgTrace(%session.SessionId,n,"callType")
			Set msgType = ^IRIS.TempMsgTrace(%session.SessionId,n,"msgType")
			Set respNo = $G(^IRIS.TempMsgTrace(%session.SessionId,n,"respNo"))
			Set backLink = $G(^IRIS.TempMsgTrace(%session.SessionId,n,"back"))

			Set startStyle = "MsgStart" _ callType

			#; test for queued/discarded messages
			#; queued = 2, discarded = 4

			Set s = ^IRIS.TempMsgTrace(%session.SessionId,n,"status")
			If (s = 2) {
				Set endStyle = "MsgTermQueued"
			}
			ElseIf (s = 4) {
				Set endStyle = "MsgTermDiscarded"
			}
			Else {
				Set endStyle = "MsgTerm" _ callType
			}

			If ($e(msgClass,1,7)="EnsLib.")||($e(msgClass,1,4)="Ens.") {
				Set msgClass = $P(msgClass,".",2,$L(msgClass,"."))
			} Else {
				Set msgClass = $P(msgClass,".",$L(msgClass,"."))
			}

			If (xStart < zend) {
				Set off = -(hostLineWidth\2)
				Set a = -5
				Set anchor1 = "start"
				Set anchor2 = "end"
				Set xSel = xStart - 10
				Set xSelWid = zend - xStart + 20
			}
			Else {
				Set off = hostLineWidth\2
				Set a = 5
				Set anchor1 = "end"
				Set anchor2 = "start"
				Set xSel = zend - 10
				Set xSelWid = xStart - zend + 20
			}

			#; message line
			&html<<g id="#(msgId)#" onmousedown="svgPage.clickMsg(evt,'#(backLink)#');">>

			#; link to response
			If ((respNo '= "") && ((callType = "Sync") || (callType = "Async"))) {
				#; draw fancy response lines
				#; search for entries with no height
				Set tHeightKey = +n
				Set tMissing = 0
				For {
					Set tHeightKey = $order(noHeight(tHeightKey))
					Quit:(tHeightKey="")||(tHeightKey>respNo)
					Set tMissing = tMissing + 1
				}
				Set rh = (respNo - n - tMissing) * deltaY

				#; prevent overlap using advanced heuristics
				Set rc = ($R(10) + 2)

				&html<<polyline id="respLine_#(msgId)#" class="LinkLine" points="#(zend-off)# #(y)#, #(zend-off-(rc*a))# #(y)#, #(zend-off-(rc*a))# #(y+rh)#, #(zend-off)# #(y+rh)#" />>
			}

			#; selection box
			Set mt = "" // (msgType="Response") // in case we want different background colors for request and response messages
			&html<<rect id="msg_#(msgId)#" class="MsgOutline#(mt)#" x="#(xSel)#" y="#(y-12)#" width="#(xSelWid)#" height="24" rx="4" />>

			#; terminator
			&html<<rect class="#(endStyle)#" x="#(zend-((hostLineWidth-2)/2))#" y="#(y-9)#" width="#(hostLineWidth-2)#" height="18" rx="2"/>>

			#; line
			&html<<line class="MsgLine#(msgType)#" x1="#(xStart)#" y1="#(y)#" x2="#(zend+off)#" y2="#(y)#" />>

			#; start circle
			If ((callType = "SyncResponse") || (callType = "AsyncResponse")) {
				&html<<circle class="#(startStyle)#" cx="#(xStart)#" cy="#(y)#" r="#((hostLineWidth\2)-2)#"/>>
			}
			Else {
				&html<<circle class="#(startStyle)#" cx="#(xStart)#" cy="#(y)#" r="#(hostLineWidth\2)#"/>>
			}

			#; arrow

			If (endStyle = "MsgTermDiscarded") {
				#; discarded indicator
				#; noresponse indicator
				&html<<circle class="Discarded" cx="#(zend+off+a)#" cy="#(y)#" r="5" />>
			}
			Else {
				If (callType = "NoResponse") {
					#; noresponse indicator
					&html<<line class="MsgLine#(msgType)#" x1="#(zend+off+a)#" y1="#(y-6)#" x2="#(zend+off+a)#" y2="#(y+6)#" />>
				}
				Else {
					&html<<line class="MsgLine#(msgType)#" x1="#(zend+off+a)#" y1="#(y-5)#" x2="#(zend+off)#" y2="#(y)#" />>
					&html<<line class="MsgLine#(msgType)#" x1="#(zend+off+a)#" y1="#(y+5)#" x2="#(zend+off)#" y2="#(y)#" />>
				}

				If ((callType = "Async") || (callType = "AsyncResponse") || (callType = "NoResponse")) {
					#; extra arrows
					&html<<line class="MsgLine#(msgType)#" x1="#(zend+off+(2*a))#" y1="#(y-5)#" x2="#(zend+off+a)#" y2="#(y)#" />>
					&html<<line class="MsgLine#(msgType)#" x1="#(zend+off+(2*a))#" y1="#(y+5)#" x2="#(zend+off+a)#" y2="#(y)#" />>
				}
			}

			#; labels
			&html<<text class="MsgLabel" x="#(xStart - off - (1*a))#" y="#(y-2)#" text-anchor="#(anchor1)#">#(msgTime)#</text>>
			&html<<text class="MsgLabel" x="#(xStart - off - (1*a))#" y="#(y+10)#" text-anchor="#(anchor1)#">#(msgClass)#</text>>
			&html<<text class="MsgLabel" x="#(xSel - 2)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>

			&html<</g>>

			If $data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"iolog"))&&$data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"msgid"),ioLogMsg) {
				If ioLogMsg '= ^IRIS.TempMsgTrace(%session.SessionId,n,"id") {
					Set y = y + deltaY
				}
			}
			ElseIf $data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"ack"))&&$data(^IRIS.TempMsgTrace(%session.SessionId,n+1,"msgid"),ackMsg) {
				If (ackMsg '= ^IRIS.TempMsgTrace(%session.SessionId,n,"id"))||($g(^IRIS.TempMsgTrace(%session.SessionId,n+1,"inbound"))) {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}

		#; next message
		Set n = $O(^IRIS.TempMsgTrace(%session.SessionId,n))
		Set msgcount = msgcount + 1
	}

	Quit $$$OK
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status
{
	#; find svg font from localization file
	Set tFont = $$$Text("FontFamily","Arial,Tahoma,Verdana")

	#; style
	Write "<style type=""text/css""><![CDATA[",!
	&html<

.canvas {
	fill: white;
	stroke: gray;
	stroke-width: 1;
}

rect.TitleRect {
	fill: #FFEEDD;
	stroke: black;
	stroke-width: 1;
}

rect.HostRect1 {
	fill: rgb(156,154,140);
	stroke: grey;
	stroke-width: 1;
}

rect.HostRect2 {
	fill: rgb(53,107,141);
	stroke: grey;
	stroke-width: 1;
}

rect.HostRect {
	fill: url(#hostgrad);
	stroke: darkblue;
	stroke-width: 1;
}

.HostRectLabel {
	font-size: 10pt;
	stroke: none;
	fill: black;
}

rect.HostRectSelect {
	fill: rgb(243,231,153);
	stroke: darkblue;
	stroke-width: 2;
}

rect.HostRectSelectOld {
	fill: url(#hostgradselect);
	stroke: green;
	stroke-width: 2;
}

rect.LaneRect1 {
	fill: white;
	stroke: none;
}

rect.LaneRect0 {
	fill: rgb(236,236,236);
	stroke: none;
}

text.PaneTitle {
	font-size: 13px;
	fill: rgb(138,138,138);
	font-weight: bold;
}

text.PaneAction {
	font-size: 12px;
	fill: #3b84bc;
}

text.PaneAction: hover {
	fill: #98923a;
}

text.PaneAction2 {
	font-size: 12px;
	fill: #3b84bc;
	font-weight: bold;
}

text.PaneAction2: hover {
	fill: #98923a;
}

text.GeneralMessage {
	font-size: 13px;
	font-weight: bold;
}

text.LaneTitle {
	font-size: 14px;
	font-weight: bold;
}

text.HostTitle1 {
  font-size: 8pt;
  font-weight: bold;
  stroke: none;
  fill: white;
}

text.HostTitle {
  font-size: 8pt;
  font-weight: bold;
  stroke: none;
  fill: black;
}

text.MsgLabel {
  font-size: 8pt;
  stroke: none;
  fill: black;
}

line.SepLine1 {
	stroke: black;
	stroke-width: 2;
}

line.SepLine0 {
	stroke: gray;
	stroke-width: 1;
}

line.SepLine {
	stroke: gray;
	stroke-width: 1;
}

line.Time {
	stroke: gray;
	stroke-width: 2;
	stroke-linecap: round;
}

rect.HostLine {
	fill: #D0D0FF;
}

rect.HostLineOld {
	fill: #D0D0FF;
	stroke: gray;
	stroke-width: 1;
}

rect.HostLineSelect {
	fill: rgb(243,231,153);
}

rect.HostLineSelectOld2 {
	fill: rgb(243,231,153);
	stroke: gray;
	stroke-width: 1;
}

rect.HostLineSelectOld {
	fill: yellow;
	stroke: green;
	stroke-width: 2;
}

rect.MsgOutline0 {
	fill: #f2f2ff;
	stroke: darkblue;
	stroke-width: 2;
	fill-opacity: 0.9;
}

rect.MsgOutline1 {
	fill: #f2f9f2;
	stroke: darkblue;
	stroke-width: 2;
	fill-opacity: 0.9;
}

rect.MsgOutline {
	fill: white;
	stroke: darkblue;
	stroke-width: 2;
	fill-opacity: 0.9;
}

rect.MsgOutlineSelect {
	fill: rgb(243,231,153);
	stroke: darkred;
	stroke-width: 2;
	fill-opacity: 0.9;
}

rect.MsgOutlineSelectOld {
	fill: url(#hostgradselect);
	stroke: green;
	stroke-width: 2;
	opacity: 0.8;
	filter: url(#dropShadow);
}

line.MsgLineRequest {
	stroke: blue;
	stroke-width: 2;
	stroke-linecap: round;
	opacity: 0.8;
}

line.MsgLineResponse {
	stroke: green;
	stroke-width: 2;
	stroke-linecap: round;
	opacity: 0.8;
}

line.MsgLineError {
	stroke: red;
	stroke-width: 2;
	stroke-linecap: round;
	opacity: 0.8;
}

.LinkLine {
	stroke: gray;
	stroke-width: 2;
	stroke-linejoin: round;
	fill: none;
	opacity: 0.8;
}

.LinkLineSelect {
	stroke: darkred;
	stroke-width: 2;
	stroke-linejoin: round;
	fill: none;
	opacity: 0.8;
}

rect.MsgTerm {
	fill: gray;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermQueued {
	fill: gray;
	stroke: black;
	stroke-width: 1;
}

rect.MsgTermDiscarded {
	fill: silver;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermNoResponse {
	fill: orange;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermResponse {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermAsyncResponse {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermSyncResponse {
	fill: lightblue;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermAsync {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

rect.MsgTermSync {
	fill: lightblue;
	stroke: blue;
	stroke-width: 1;
}

circle.Discarded {
	fill: silver;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStart {
	fill: yellow;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartNoResponse {
	fill: orange;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartSyncResponse {
	fill: lightblue;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartResponse {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartSync {
	fill: lightblue;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartAsync {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

circle.MsgStartAsyncResponse {
	fill: plum;
	stroke: blue;
	stroke-width: 1;
}

text, tspan {
	font-family: #(tFont)#;
}

.diagramHeader {
	stroke: rgb(88,88,88);
	stroke-width: 1;
	vertical-align: bottom;
	height: 48px;
	fill: rgb(232,231,225);
}

.diagramHeader2 {
	position: relative;
	vertical-align: bottom;
	height: 48px;
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
	border-right: 1px solid black;
	display: none;
}

.dgmHeader {
	position: absolute;
	bottom: 0px;
	left: 0px;
	overflow: hidden;
}

.dgmHeaderLabel {
	font-weight: bold;
	font-size: 12pt;
	color: #404040;
}

.dgmHeaderCmd {
	text-decoration: none;
	font-size: 10pt;
	color: blue;
}

.dgmHeaderCmd:hover {
	text-decoration: none;
	color: darkred;
}

.ribbonLabel {
	vertical-align: middle;
	color: #404040;
	font-weight: bold;
	font-size: 10pt;
}

.ribbonSortOption:hover,.ribbonSortOptionSelected:hover {
	color: darkred;
}

.ribbonSortOption {
	text-decoration: none;
	color: blue;
	font-weight: normal;
}

.ribbonSortOptionSelected {
	text-decoration: none;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

.eventMarkerBack {
	fill: white;
	stroke: blue;
	stroke-width: 1;
	opacity: 0.9;
}

/* Assert,Error,Warning,Info,Trace,Alert */

.eventMarker1 {
	fill: silver;
	stroke: black;
	stroke-width: 1;
}

.eventMarker2 {
	fill: red;
	stroke: black;
	stroke-width: 1;
	opacity: 0.7;
}

.eventMarker3 {
	fill: orange;
	stroke: black;
	stroke-width: 1;
}

.eventMarker4 {
	fill: white;
	stroke: black;
	stroke-width: 1;
}

.eventMarker5 {
	fill: lightblue;
	stroke: black;
	stroke-width: 1;
}

.eventMarker6 {
	fill: yellow;
	stroke: black;
	stroke-width: 1;
}

/* IOLog, EDI Acknowledgement Response */

.ackArrow {
	fill: green;
	stroke: black;
	stroke-width: 0;
}

.ackBack {
	fill: white;
	stroke: blue;
	stroke-width: 1;
	opacity: 0.9;
}

.ioArrows {
	fill: blue;
	stroke-width: 0;
}

>
	Write "]]></style>>"

	Quit $$$OK
}

/// Callback method called when drawing the SVG defs for this page.
ClassMethod %OnDrawSVGDef() As %Status
{
	&html<
<!-- defs -->

<defs>
<menu id="CanvasMenu" xmlns="http://mynamespace.com/">
    <header>Message Trace Menu</header>
    <menu id="menu_zoom">
	 <header>Zoom</header>
	 <item id="menu_zoom_33" onactivate="svgPage.setZoom(33);">33%</item>
	 <item id="menu_zoom_50" onactivate="svgPage.setZoom(50);">50%</item>
	 <item id="menu_zoom_75" onactivate="svgPage.setZoom(75);">75%</item>
	 <item id="menu_zoom_88" onactivate="svgPage.setZoom(88);">88%</item>
	 <item checked="yes" id="menu_zoom_100" onactivate="svgPage.setZoom(100);">100%</item>
	 <item id="menu_zoom_110" onactivate="svgPage.setZoom(110);">110%</item>
	 <item id="menu_zoom_125" onactivate="svgPage.setZoom(125);">125%</item>
	 <item id="menu_zoom_150" onactivate="svgPage.setZoom(150);">150%</item>
	 <item id="menu_zoom_200" onactivate="svgPage.setZoom(200);">200%</item>
    </menu>
    <separator/>
	<item id="search" onactivate="svgPage.selectItem(null);">Search</item>
    <separator/>
	<item action="Copy" id="Copy">Copy</item>
	<item action="Find" id="Find">Find...</item>
	<item action="FindAgain" id="FindAgain">Find Again</item>
    <separator/>
	<item enabled="no" checked="yes" id="details" onactivate="svgPage.showMsgDetails();">Show Details</item>
	<item enabled="no" id="contents" onactivate="svgPage.showMsgContents();">Show Contents</item>
    <separator/>
	<item id="legend" onactivate="svgPage.showLegend();">Legend...</item>
    <separator/>
    <item action="ViewSource">View Source</item>
    <item action="About">A&amp;bout SVG Viewer...</item>
</menu>

<!-- filters -->
<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
<feOffset dx="4px" dy="4px" result="offsetBlur" />
<feMerge>
	<feMergeNode in="offsetBlur"/>
	<feMergeNode in="SourceGraphic"/>
</feMerge>
</filter>

<linearGradient id="hostgrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:#D0D0FF" />
<stop offset="90%" style="stop-color:#8080FF" />
</linearGradient>

<linearGradient id="hostgradselect" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:yellow" />
<stop offset="90%" style="stop-color:orange" />
</linearGradient>

</defs>
>

	Quit $$$OK
}

/// Construct arrays containing the trace info for this message session:<br>
/// <var>^IRIS.TempMsgTrace(%session.SessionId)</var> contains info about each message.<br>
/// <var>cls</var> contains info about the Business classes used.<br>
/// This method returns the number of items (messages / events/ IOLog entries), the number of rows, the number of columns.
ClassMethod BuildTraceInfo(sessionId As %String = "", currPage As %String = "1") As %String
{
	// Incluir um indicador de que parou por exceder os limites de inclusao de eventos!!!  hcr

	#; Note: there are 5 lanes encoded as follows:
	#; 0 = IO to/from Service
	#; 1 = Service
	#; 2 = Process 
	#; 3 = Operation
	#; 5 = IO to/from Operation

	#; get search parms from properties
	#; pegar do searchCriteria???? hcr
	Set (startTime,endTime,startId,endId)="" // hcr
	//Set sessionId = ..sessionId
	//Set startTime = ..startTime
	//Set endTime = ..endTime
	//Set startId = ..startId
	//Set endId = ..endId
	//Set currPage = ..currPage

	#; there are 3 types of filter: session, time, and id
	Set filter = "session"
	If ((startTime '= "") || (endTime '= "")) {
		Set filter = "time"
	}
	If ((startId '= "") || (endId '= "")) {
		Set filter = "id"
	}

	#; constants for inclusion of event log entries in the message trace (HCR076)
	Set IncludeEvents = ..IncludeEvents()
	Set EventsWindow = ..EventsWindow()
	Set EventsMaxRows = ..EventsMaxRows()
	Set ShowInternalItems = ..ShowInternalItems()
	Set IncludeIOLogEntries = ..IncludeIOLogEntries()

	#; build spec for this query and test to see if temp data matches it
	
	Set tmc = $P($H,",",2)
	Set spec = filter _ "^" _ sessionId _
						"^" _ startTime _
						"^" _ endTime _
						"^" _ startId _
						"^" _ endId _
						"^" _ IncludeEvents _
						"^" _ EventsWindow _
						"^" _ EventsMaxRows _
						"^" _ ShowInternalItems _
						"^" _ IncludeIOLogEntries

	//Set tShow=showId, showId=""  ??? hcr
	Set (tShow,showId) = ""

	#; check if our temp data is for this request
	Lock +^IRIS.TempMsgTrace(%session.SessionId)
	If (spec = $G(^IRIS.TempMsgTrace(%session.SessionId,0,"spec"))) {
		Set oldtmc = +$G(^IRIS.TempMsgTrace(%session.SessionId,0,"tmc"))

		#; only reuse temp file within a specific time window
		If ((tmc>=oldtmc) && ((tmc-oldtmc)<=..#CACHETIMEOUT)) {
			#; reuse
			Lock -^IRIS.TempMsgTrace(%session.SessionId)
			Quit ^IRIS.TempMsgTrace(%session.SessionId,0,"count")_"#"_+$G(^IRIS.TempMsgTrace(%session.SessionId,0,"rowcount"))_"#"_+$G(^IRIS.TempMsgTrace(%session.SessionId,0,"columns"))
		}
	}

	#; kill temp data
	Do ..ClearTraceData()
	Set ^IRIS.TempMsgTrace(%session.SessionId,0,"spec") = spec
	Set ^IRIS.TempMsgTrace(%session.SessionId,0,"tmc") = tmc

	#; Discover session boundaries (HCR076)
	Set SessionStartTime = ""
	Set SessionEndTime = ""
	Set SessionStartId = ""
	Set SessionEndId = ""
	&sql(DECLARE sqlSESSIONLIMITS CURSOR FOR 
		SELECT %ID, TimeCreated, TimeProcessed 
		INTO :id, :ctime, :ptime 
		FROM Ens.MessageHeader
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
	If (startId2>endId2) || (startTime2]endTime2) Quit "0#0#0" // Nothing will be retrieved!

	#; query for messages by session id
	&sql(DECLARE sqlSESSION CURSOR FOR 
		SELECT %ID, TimeCreated, SourceConfigName, 
			TargetConfigName, BusinessProcessId, Type, 
			MessageBodyClassName, MessageBodyId, ReturnQueueName, CorrespondingMessageId,
			Status, IsError, SourceBusinessType, TargetBusinessType
		INTO :id, :ctime, :sourceClass, :targetClass, 
			:bprocid, :msgtype, :classname, :body, :returnQueue, :reqID,
			:status, :iserr, :ortype, :desttype
		FROM Ens.MessageHeader
		WHERE SessionId = :sessionId
		ORDER BY %ID
		)

	#; query for messages by time and id
	&sql(DECLARE sqlTIMEID CURSOR FOR 
		SELECT %ID, TimeCreated, SourceConfigName, 
			TargetConfigName, BusinessProcessId, Type, 
			MessageBodyClassName, MessageBodyId, ReturnQueueName, CorrespondingMessageId,
			Status, IsError, SourceBusinessType, TargetBusinessType
		INTO :id, :ctime, :sourceClass, :targetClass, 
			:bprocid, :msgtype, :classname, :body, :returnQueue, :reqID,
			:status, :iserr, :ortype, :desttype
		FROM Ens.MessageHeader
		WHERE SessionId = :sessionId AND TimeCreated >= :startTime2 AND TimeCreated <= :endTime2 AND
			%ID >= :startId2 AND %ID <= :endId2
		ORDER BY %ID
		)

	#; queries for events
	&sql(DECLARE sqlEVENTTIME CURSOR FOR 
		SELECT %ID, SessionId, TimeLogged, ConfigName, Type, MessageId, SourceClass
		INTO :eventId, :sesId, :eventTime, :eventHost, :eventType, :eventMsg, :eventClass
		FROM Ens_Util.Log
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
	Set tIOLogData = 0
	Set tRowCount = 0

	If (filter="time") || (filter="id") {
		If IncludeIOLogEntries {
			// Force use of SessionId index first
			Set tIOLogSQL = "SELECT io.%ID As ID, io.ConfigName, io.CorrespondingRequestId, io.IsInbound, io.TimeReceived "
			 				_"FROM %INORDER Ens_Util.IOLog io "
			 				_"JOIN ( "
			 				_	"SELECT %ID As ID "
			 				_	"FROM Ens_Util.IOLog "
			 				_	"WHERE CorrespondingRequestId >= ? AND CorrespondingRequestId <= ? "
			 				_	"AND TimeReceived >= ? AND TimeResponded <= ? "
							_" ) restrictTimeId "
							_"ON io.%ID = restrictTimeId.ID "
							_"WHERE io.SessionId = ? "
							_"ORDER BY io.%ID"
			Set tIOLogState = ##class(%SQL.Statement).%New()
			Set tSC = tIOLogState.%Prepare(tIOLogSQL)
			If $$$ISOK(tSC) {
				Set tIOLogRS = tIOLogState.%Execute(startId2, endId2, startTime2, startTime2, sessionId)
				If $IsObject(tIOLogRS) Set tIOLogData = tIOLogRS.%Next()
			}
		}
		&sql(OPEN sqlTIMEID)
		&sql(FETCH sqlTIMEID)
	}
	Else {
		// filter="session"
		If IncludeIOLogEntries {
			Set tIOLogSQL = "SELECT io.%ID As ID, io.ConfigName, io.CorrespondingRequestId, io.IsInbound, io.TimeReceived "
			 				_"FROM Ens_Util.IOLog io "
							_"WHERE io.SessionId = ? "
							_"ORDER BY io.%ID"
			Set tIOLogState = ##class(%SQL.Statement).%New()
			Set tSC = tIOLogState.%Prepare(tIOLogSQL)
			If $$$ISOK(tSC) {
				Set tIOLogRS = tIOLogState.%Execute(sessionId)
				If $IsObject(tIOLogRS) Set tIOLogData = tIOLogRS.%Next()
			}
		}
		&sql(OPEN sqlSESSION)
		&sql(FETCH sqlSESSION)
	}

	Kill internalItems Do:'ShowInternalItems ..ArrayOfInternalItems(.internalItems)

	While (SQLCODE = 0) {
		#; Check if message body class is on the list of internal items to be skipped
		If (classname="") || ('$D(internalItems(classname))) {
			Set tSameRow = 0
			Do InjectEvents(1)

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
		
			Set:tShow=id showId=id
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"id") = id
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"time") = $$$timeUTCtoLocal(ctime)
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"orType") = ortype
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"destType") = desttype
		
			If classname="" {
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgClass") = "NULL"
			} else {
				Try {
					Set mb = $zobjclassmethod(classname,"%OpenId",body)
					If ($IsObject(mb)) {
						Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgClass") = mb.%ClassName(1)
						If mb.%Extends("EnsLib.EDI.Document")&&('(mb.%IsA("EnsLib.EDI.ASTM.Document"))) {
							Set findACK = 1
							If mb.%Extends("EnsLib.EDI.BatchDocument")&&(mb.ParentId'="") Set findACK = 0
							
							Set findACK("class") = mb.%ClassName(1)
							Set findACK("timeCreated") = mb.TimeCreated
							; If we are a response being returned to a service
							If (desttype=1)&&(msgtype=2) Set findACK("response")=body
							
						}
					}
					Else {
						// ain't got no body...
						Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgClass") = "N/A"
					}
				}
				Catch ex {
					If ex.Name [ "<CLASS DOES NOT EXIST>" {
						Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgClass") = "N/A"
					}
					Else { Throw ex }
				}
			}
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"sourceClass") = sourceClass
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"targetClass") = targetClass
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = ""
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgType") = "Request"
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"status") = status

			If (msgtype = 2) {
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgType") = "Response"
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "Response"
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"back") = reqID
			}
			Else {
				If (returnQueue = "") {
					// fire / forget
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "NoResponse"
				}
				ElseIf ($$$queueIsPrivateQueue(returnQueue) || (+returnQueue=returnQueue)) {
					// private
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "Sync"
				}
				Else {
					// async
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "Async"
				}
			}

			If ((reqID '= "") && ($D(msgIndex(reqID)))) {
				// point our request to us
				Set ^IRIS.TempMsgTrace(%session.SessionId,msgIndex(reqID),"respNo") = n
				If (^IRIS.TempMsgTrace(%session.SessionId,msgIndex(reqID),"callType") = "Sync") {
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "SyncResponse"
				}
				Else {
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"callType") = "AsyncResponse"
				}
			}

			// test for messages with errors
			If (iserr) {
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgType") = "Error"
			}

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
			Do InjectEvents(0)
			/// Add ACKs for EDI documents, but *NOT* ASTM as OriginalDocId is not indexed
			If findACK&&(findACK("class")'="")&&((ortype=1)||(desttype=3)||(desttype=1)) {
				Do InjectACK()
			}
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
	Set ^IRIS.TempMsgTrace(%session.SessionId,0,"count") = n
	Set ^IRIS.TempMsgTrace(%session.SessionId,0,"rowcount") = tRowCount

	#; count number of columns
	Set cc = 0
	For lane = 1:1:3 {
		Set k = $O(cls(lane,""))
		While (k '= "") {
			Set cc = cc + 1
			Set k = $O(cls(lane,k))
		}
	}
	#; add columns for IO Log / ACK lanes
	If $d(tIOLogLanes("inbound")) {
		Set cls(0,"External")=""
		Set cc = cc + 1
	}
	If $d(tIOLogLanes("outbound")) {
		Set cls(4,"External")=""
		Set cc = cc + 1
	}

	Merge ^IRIS.TempMsgTrace(%session.SessionId,0,"clsinfo") = cls
	Merge ^IRIS.TempMsgTrace(%session.SessionId,0,"clslane") = clsInv
	Set ^IRIS.TempMsgTrace(%session.SessionId,0,"columns") = cc
	Lock -^IRIS.TempMsgTrace(%session.SessionId)

	#; return total number of messages and other items found, plus number of rows and columns
	Set:n>..#MSGPERPAGE showId="" // don't go to id
	Quit n_"#"_tRowCount_"#"_cc


InjectEvents(inbound=1)
	// event time is "time#msgId"
	While (((tEventTime'="") && (tEventTime '] (ctime_"#"_id)) && (tEventTime '= (ctime_"#"_id)))||(tIOLogData&&((tIOLogRS.%Get("CorrespondingRequestId")<id)||((tIOLogRS.%Get("CorrespondingRequestId")=id)&&(inbound=''tIOLogRS.%Get("IsInbound")))))) {
		// inject events into list
		Set tNextEvent = $p(tEventTime,"#")
		If tIOLogData { Set tNextIOLog = tIOLogRS.%Get("TimeReceived") }
		Else { Set tNextIOLog = "" }

		If (tNextEvent'="")&&(tNextIOLog ] tNextEvent)||(tNextIOLog = "") { ; event comes first
			Set tEventId = $O(tEvents(tEventTime,""))
			While (tEventId'="") {
				Set tName = $LG(tEvents(tEventTime,tEventId),1)
				If $D(clsInv(tName)) { // associated config item is already on diagram
					Set n = n + 1
					Set tRowCount = tRowCount + 1
					Set tSameRow = 1
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"event") = 1
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"id") = tEventId
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"sourceClass") = $LG(tEvents(tEventTime,tEventId),1)
					Set ^IRIS.TempMsgTrace(%session.SessionId,n,"type") = $LG(tEvents(tEventTime,tEventId),2)
				}
				Set tEventId = $O(tEvents(tEventTime,tEventId))
			}
			Set tEventTime = $O(tEvents(tEventTime))
		}
		ElseIf (tNextIOLog'="") { ; IO Log entry comes first
			Set n = n + 1
			If ('tSameRow) { 
				Set tSameRow = 1 
				Set ^IRIS.TempMsgTrace(%session.SessionId,0,"noheight",n) = ""
			}
			Else { Set tRowCount = tRowCount + 1 }
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"iolog") = 1
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"id") = tIOLogRS.%Get("ID")
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgid") = tIOLogRS.%Get("CorrespondingRequestId")
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"host") = tIOLogRS.%Get("ConfigName")
			
			Set tInbound = tIOLogRS.%Get("IsInbound")
			If tInbound {
				Set ^IRIS.TempMsgTrace(%session.SessionId,n,"inbound") = tInbound
				Set tIOLogLanes("inbound") = ""
				Set tIOLogLanes("inbound","IOLog")=""
				If '$d(tIOLogLanes("inbound","first")) Set tIOLogLanes("inbound","first") = tIOLogRS.%Get("ID")
			}
			Else {
				Set tIOLogLanes("outbound") = ""
				Set tIOLogLanes("outbound","IOLog") = ""
				If '$d(tIOLogLanes("outbound","first")) Set tIOLogLanes("outbound","first") = tIOLogRS.%Get("ID")
			}
			Set tIOLogData = tIOLogRS.%Next()
		}
	}
	Quit

InjectACK()
	Set tClassTablename = $$$ClassSQLTable(findACK("class"))
	If $g(findACK("response")) { ; use original document for search
		Set tAckSQL = "SELECT %ID AS ID, TimeCreated, Source, ChildCount FROM "_tClassTablename
			_" WHERE %ID = ?"
		Set tAckRS = ##class(%ResultSet.SQL).%Prepare(tAckSQL,,, body)
	}
	Else {
		Set tAckSQL = "SELECT %ID AS ID, TimeCreated, Source, ChildCount FROM "_tClassTablename
			_" WHERE OriginalDocId = ? AND TimeCreated >= ? AND ID > ?"
			_" ORDER BY ID"
		Set tAckRS = ##class(%ResultSet.SQL).%Prepare(tAckSQL,,, body, ctime, +$get(tLastAck(findACK("class"), body)))
	}
	If $IsObject(tAckRS)&&tAckRS.%Next() {
		; If we are a service, perform additional checks
		If (ortype = 1) {
			; If Source '= originalID, AND not a batch this is not a match
			If (tAckRS.%Get("Source") '= body) && (0 = +tAckRS.%Get("ChildCount")) Quit
			; If this is a synchronous send, we use a returned body as the ack
			If (reqID '= "") && (reqID > id) Quit
		}
		ElseIf ((ortype = 3)||(desttype=3)) {
			; Operation constructs responses differently
			If tAckRS.%Get("Source") = body Quit
		}
		Set tLastAck(findACK("class"), body) = tAckRS.%Get("ID")
		Set n = n + 1
		
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"ack") = 1
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"host") = sourceClass
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgclass") = findACK("class")
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"msgid") = id
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"id") = tAckRS.%Get("ID")
		Set ^IRIS.TempMsgTrace(%session.SessionId,n,"timecreated") = tAckRS.%Get("TimeCreated")
		If (ortype = 1) { 
			If (desttype'=3) { Set tInboundAck = 1 }
			Else { ; Sent from Service to Operation
				Set tSource = tAckRS.%Get("Source")
				If $e(tSource,1,$l(body)+2) = (body_$c(13,10)) { Set tInboundAck = 0 } ; If Source contains origID_" "_<IP Address> it is from operation
				Else { Set tInboundAck = 1 }
			} 
		}
		ElseIf (desttype=3) { Set tInboundAck = 0 }
		ElseIf (desttype=1) { Set tInboundAck = 1 }
		Else { Set tInboundAck = 0 }
		If tInboundAck {
			; ACK produced in service
			Set ^IRIS.TempMsgTrace(%session.SessionId,n,"inbound") = 1
			Set tIOLogLanes("inbound") = ""
			Set tIOLogLanes("inbound","ACK") = ""
			Set tRowCount = tRowCount + 1
			If '$d(tIOLogLanes("inbound","first")) Set tIOLogLanes("inbound","first") = tAckRS.%Get("ID")
		}
		Else {
			Set tIOLogLanes("outbound") = ""
			Set tIOLogLanes("outbound","ACK") = ""
			If ('tSameRow) {
				Set tSameRow = 1
				Set ^IRIS.TempMsgTrace(%session.SessionId,0,"noheight",n) = ""
			}
			If '$d(tIOLogLanes("outbound","first")) Set tIOLogLanes("outbound","first") = tAckRS.%Get("ID")
		}
	}
	Quit
}

ClassMethod ClearTraceData()
{
	Kill ^IRIS.TempMsgTrace(%session.SessionId)
}

ClientMethod onSVGLoad() [ Language = javascript ]
{
	// client-side state variables
	// id of current selected message
	this.currMsgId = null;
	
	// id of current selected host
	this.currHostId = null;
	
	// what to view when user clicks on trace item
	this.defaultView = "details";

	this.currRespLine = null;

	// replace context menu (adobe only)
	try {
		var newMenuRoot = parseXML(printNode(document.getElementById('CanvasMenu')), contextMenu);
		contextMenu.replaceChild( newMenuRoot, contextMenu.firstChild );
	}
	catch (ex) {
	}
}

/// Set the zoom level
ClientMethod setZoom(zoom) [ Language = javascript ]
{
	var currZoom = zenParent.getProperty('zoom');
	if (zoom == currZoom) return;

	var oldzoom = currZoom;
	zenParent.setProperty('zoom',zoom);

 	// update context menu
 	svgPage.setMenuItemOption("checked","menu_zoom_" + oldzoom, "menu_zoom", false);
 	svgPage.setMenuItemOption("checked","menu_zoom_" + zoom, "menu_zoom", true);
}

/// set the option for the given menu item
ClientMethod setMenuItemOption(pOption, pItemId, pSubMenuId, value) [ Language = javascript ]
{
	// adobe only
	try {
		var menuItems = contextMenu.childNodes.item(0).childNodes;
		var tItem;
	      
		for (i = 0; i != menuItems.length - 1; i++) {
			if (menuItems.item(i).nodeType == 1) {
				tItem = menuItems.item(i);
				if (!pSubMenuId) {
					// top-level menu item
					if (tItem.getAttribute('id') == pItemId) {
						tItem.setAttribute(pOption,value ? 'yes' : 'no');
					}
				}
	            else if ((tItem.nodeName == 'menu') && (tItem.getAttribute('id') == pSubMenuId)) {
					// submenu
	
					// loop over items in submenu
					var submenuItems = tItem.childNodes;
	               
					for (j = 0; j != submenuItems.length - 1; j++) {
						tSubItem = submenuItems.item(j)
						if (tSubItem.nodeType == 1) {
							if (tSubItem.getAttribute('id') == pItemId) {
								tSubItem.setAttribute(pOption,value ? 'yes' : 'no');
							}
						}
					}
				}
			}
		}
	}
	catch(ex) {
	}
}

/// Mouse click on canvas
ClientMethod clickCanvas(evt) [ Language = javascript ]
{
	evt.stopPropagation();
	svgPage.selectItem(null);
	svgPage.selectHost(null);
}

/// Mouse click on message
ClientMethod clickMsg(evt, back) [ Language = javascript ]
{
	var el = evt.target;
	evt.stopPropagation();
	svgPage.selectItem(el.parentNode.id, back);
}

ClientMethod clickHost(evt) [ Language = javascript ]
{
	var el = evt.target;
	evt.stopPropagation();
	svgPage.selectHost(el.id);
}

ClientMethod clickEvent(evt, eventId) [ Language = javascript ]
{
	evt.stopPropagation();
	svgPage.selectItem(null);
	svgPage.selectHost(null);
	self.showDetails(eventId,'event');
	currMsgId = -1;
}

ClientMethod clickIOEntry(evt, ioLogId, ioRectId) [ Language = javascript ]
{
	evt.stopPropagation();
	svgPage.selectOtherItem(ioRectId);
	if (defaultView=='details') {
		self.showDetails(ioLogId, 'ioEntry');
	}
	else {
		self.showContents(ioLogId, 'ioEntry');
	}
	currMsgId = -1;
}

ClientMethod clickACK(evt, ackClassname, ackId, ackRectId) [ Language = javascript ]
{
	evt.stopPropagation();
	svgPage.selectOtherItem(ackRectId);
	var ackArray = [ackClassname, ackId];
	if (defaultView=='details') {
		self.showDetails(ackArray, 'ack');
	}
	else {
		self.showContents(ackArray, 'ack');
	}
	currMsgId = -1;
}

ClientMethod selectOtherItem(itemId) [ Language = javascript ]
{
	if ((currMsgId != null) && (currMsgId != -1)) {
		svgPage.selectItem(null);
	}
	if ((currHostId != null) && (currHostId != -1)) {
		svgPage.selectHost(null);
	}
	
	var item;
	if (itemId != currOtherId) {
		if (currOtherId) {
			item = document.getElementById(currOtherId);
			if (item) {
				item.setAttribute("class", item.getAttribute("class").split(' ')[0]);
			}
		}
		currOtherId = itemId;
		
		if (currOtherId) {
			item = document.getElementById(currOtherId);
			if (item) {
				item.setAttribute("class", item.getAttribute("class") + ' selected');
			}
		}
	}
	svgPage.setMenuItemOption("enabled","details", null, currOtherId != null);
	svgPage.setMenuItemOption("enabled","contents", null, currOtherId != null);
}

/// Select a host (to hilite)
ClientMethod selectHost(id) [ Language = javascript ]
{
	var el;

	if (this.currOtherId != null) {
		svgPage.selectOtherItem(null);
	}
	if ((this.currMsgId != null) && (this.currMsgId != -1)) {
		svgPage.selectItem(null);
	}

	if (id != this.currHostId) {
		if (this.currHostId) {
			el = document.getElementById(this.currHostId);
			if (el) {
				el.setAttribute("class","HostRect");
			}
			el = document.getElementById(this.currHostId + "_line");
			if (el) {
				el.setAttribute("class","HostLine");
			}
		}

		this.currHostId = id;
		if (this.currHostId) {
			el = document.getElementById(this.currHostId);
			if (el) {
				el.setAttribute("class","HostRectSelect");
			}
			el = document.getElementById(this.currHostId + "_line");
			if (el) {
				el.setAttribute("class","HostLineSelect");
			}
		}
	}
}

/// Select a new item
ClientMethod selectItem(id, back) [ Language = javascript ]
{
	var rect,line;

	if (this.currOtherId != null) {
		svgPage.selectOtherItem(null);
	}
	if (this.currHostId != null) {
		svgPage.selectHost(null);
	}

	if (id == this.currMsgId) {
		return;
	}

	// unhighlight old message
	if (this.currMsgId && this.currMsgId != -1) {
		rect = document.getElementById('msg_' + this.currMsgId);
		if (rect) {
			rect.setAttribute("class","MsgOutline");
		}
		
		// unhighlight response lines (if any)
		if (this.currRespLine) {
			this.currRespLine.setAttribute("class","LinkLine");
			this.currRespLine = null;
		}
	}

	this.currMsgId = id;

	// highlight new message
	if (this.currMsgId) {
		rect = document.getElementById('msg_' + this.currMsgId);
		if (rect) {
			rect.setAttribute("class","MsgOutlineSelect");
		}

		// highlight response lines (if any)
		line = document.getElementById("respLine_" + this.currMsgId);
		if (line) {
			line.setAttribute("class","LinkLineSelect");
			this.currRespLine = line;
		}
		else if (back && back != '') {
			// try back link
			line = document.getElementById("respLine_" + back);
			if (line) {
				line.setAttribute("class","LinkLineSelect");
				this.currRespLine = line;
			}
		}
	}

	zenPage.showItemDetails(1); // dummy - hcr

	/*
	// raise event for container page
	try {
		if (("details" == this.defaultView) || (!this.currMsgId)) {
			zenPage.showMessageDetails(this.currMsgId);
		}
		else {
			zenPage.showMessageContents(this.currMsgId);
		}
	}
	catch(ex) {
		alert('Message trace: Unable to notify container page.\n' + ex);
	}

	// update menu
	svgPage.setMenuItemOption("enabled","details", null, this.currMsgId != null);
	svgPage.setMenuItemOption("enabled","contents", null, this.currMsgId != null);
	*/
}

/// Called from context menu
ClientMethod showMsgDetails() [ Language = javascript ]
{
	if (this.currMsgId && this.currMsgId != -1) {
		// update info sheet
		if (zenPage && zenPage.showMessageDetails) {
			zenPage.showMessageDetails(this.currMsgId);
		}
	}
	else if (this.currOtherId && this.currOtherId != -1) {
		var currOtherEl = document.getElementById(currOtherId);
		var elType = currOtherEl.getAttribute("entrytype");
		var elId = currOtherEl.getAttribute("entryid");
		if (elType=='ack') {
			elId = elId.split(':');
		}
		svgPage.showDetails(elId, elType);
	}
	// set default operation
	this.defaultView = "details";
	svgPage.setMenuItemOption("checked","details", null, true);
	svgPage.setMenuItemOption("checked","contents", null, false);
}

/// Called from context menu
ClientMethod showMsgContents() [ Language = javascript ]
{
	if (this.currMsgId && this.currMsgId != -1) {
		// update info sheet
		if (zenPage && zenPage.showMessageContents) {
			zenPage.showContents(this.currMsgId);
		}
	}
	else if (this.currOtherId && this.currOtherId != -1) {
		var currOtherEl = document.getElementById(currOtherId);
		var elType = currOtherEl.getAttribute("entrytype");
		var elId = currOtherEl.getAttribute("entryid");
		if (elType=='ack') {
			elId = elId.split(':');
		}
		svgPage.showContents(elId, elType);
	}

	// set default operation
	this.defaultView = "contents";
	svgPage.setMenuItemOption("checked","details", null, false);
	svgPage.setMenuItemOption("checked","contents", null, true);
}

// Show box with message/item details.

ClientMethod showDetailsBox(itemNo) [ Language = javascript ]
{
	var config = this.getProductionModel();
	if (!config) return;

	var host = config.hosts[itemNo];
	if (this._overlay && this._overlay.parentNode) {
		this._overlay.parentNode.removeChild(this._overlay);
	}
	delete this._overlay;

	if (host) {
		//sheet.setContent(host.name);

		if (this._currEl) {
			// create overlay
			var svg = zenPage.getComponentById('svgDiagram');

			var el = this._currEl;
			var wid = 200;
			var hgt = 150;
			if ('overview' == this.displayMode) {
				wid = 150;
				hgt = 30;
			}
			var x = parseInt(el.getAttribute('cx')) - wid/2;
			var y = parseInt(el.getAttribute('cy')) + parseInt(el.getAttribute('r'));

			var overlay = svg.document.createElementNS(SVGNS,'svg');
			svg.svgGroup.appendChild(overlay);
			this._overlay = overlay;

			var rect = svg.document.createElementNS(SVGNS,'rect');
			overlay.appendChild(rect);

			var label = svg.document.createElementNS(SVGNS,'text');
			label.setAttribute('id',this.makeId('logo'));
			label.setAttribute('class','laneTitle');

			var textNode = svg.document.createTextNode(host.name);
			label.appendChild(textNode);
			overlay.appendChild(label);

			wid = label.getComputedTextLength() + 4;
			x = (x+wid+5 > svg.width) ? svg.width - wid-5 : x;
			x = (x < 0) ? 0 : x;
			y = (y+hgt+8 > svg.height) ? y - hgt - 18 : y + 8;
			y = (y < 0) ? 0 : y;

			label.setAttribute('x',x+2);
			label.setAttribute('y',y+hgt-7);

			rect.setAttribute('x',x);
			rect.setAttribute('y',y);
			rect.setAttribute('width',wid);
			rect.setAttribute('height',hgt);
			rect.setAttribute('rx',4);
			rect.setAttribute('class','overlay');
			rect.setAttribute('style','fill-opacity:0.9;');
		}
	}
	else {
		// sheet.setContent('');
	}
}

/// Called from context menu -
/// Show legend window
ClientMethod showLegend() [ Language = javascript ]
{
	if (zenPage && zenPage.showLegend) {
		zenPage.showLegend();
	}
}

}
