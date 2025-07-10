/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Visual Trace SVG Page<br>
/// This page renders the SVG needed to display a visual trace.
Class EnsPortal.SVG.VisualTrace Extends EnsPortal.SVG.templatePage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MessageTrace:USE";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Number of messages displayed on a page
Parameter MSGPERPAGE = 40;

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

/// Include EDI ACKs in display
Parameter INCLUDEACKS = 1;

/// Enable display of internal messages and related events
Parameter SHOWINTERNALITEMS = 0;

/// Lane width
Parameter HOSTWIDTH = 170;

/// Host line width
Parameter HOSTLINEWIDTH = 16;

/// Vertical space used by header and footer
Parameter TOPY = 100;

/// Difference between rows
Parameter DELTAY = 40;

Parameter TRACETYPE = "VisualTrace";

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

/// Property to disable selection of items other than the requested ID in <property>sessionId</property>.
Property noSelect As %Boolean(ZENURL = "NOSELECT");

/// Property to control whether mini-mode is in use - this should only be used for the display
/// in the message viewer. Set to 1 to use the mini-mode.
Property mode As %Integer(ZENURL = "MODE");

ClassMethod IncludeEvents() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","IncludeEvents"), $G(%request.Data("INCLUDEEVENTS",1), ..#INCLUDEEVENTS))
}

ClassMethod EventsWindow() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","EventsWindow"), $G(%request.Data("EVENTSWINDOW",1),$G(^EnsPortal.Settings($USERNAME,"VisualTrace","EventsWindow"),$G(^EnsPortal.Settings("_Ensemble","VisualTrace","EventsWindow"), ..#EVENTSWINDOW))))
}

ClassMethod EventsMaxRows() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","EventsMaxRows"), $G(%request.Data("EVENTSMAXROWS",1),$G(^EnsPortal.Settings($USERNAME,"VisualTrace","EventsMaxRows"),$G(^EnsPortal.Settings("_Ensemble","VisualTrace","EventsMaxRows"),..#EVENTSMAXROWS))))
}

ClassMethod IncludeIOLogEntries() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","IncludeIOLogEntries"), $G(%request.Data("INCLUDEIOLOG",1),..#INCLUDEIOLOG))
}

ClassMethod ShowInternalItems() [ CodeMode = expression ]
{
$G(%session.Data("EnsMsgTraceFilterForm","ShowInternalItems"), $G(%request.Data("SHOWINTERNAL",1),..#SHOWINTERNALITEMS))
}

ClassMethod IncludeAcks() [ CodeMode = expression ]
{
$G(%request.Data("INCLUDEACKS",1),..#INCLUDEACKS)
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
		Quit $$$OK // Exit
	}
	//Set startTime = $G(%request.Data("STARTTIME",1))
	//Set endTime = $G(%request.Data("ENDTIME",1))
	//Set startId = $G(%request.Data("STARTID",1))
	//Set endId = $G(%request.Data("ENDID",1))

	Set currPage = +$G(%request.Data("PAGE",1),1)
	Set printable = +$G(%request.Data("PRINTABLE",1))
	Set msgPerPage = $G(%request.Data("MSGPERPAGE",1), ..#MSGPERPAGE)
	
	#;From EnsPortal.VisualTrace ("" or "None","SameHost","Corresponding"). "SameBody" not currently passed in.
	#dim tRelated As %String = ""
	Set tRelated = $G(%request.Data("SHOWRELATED",1),"")
	#;"" or currentId+"~"+currentSVGId+"~"+currentType+"~"+currentClass+"~"+currentLine;
	#dim tRelatedItem As %String = ""
	Set tRelatedItem = $G(%request.Data("RELATEDITEM",1))
	#dim tRelatedId,tRelatedSVGId,tRelatedType,tRelatedClass,tRelatedLine As %String = ""
	#dim tFilterArray As %String
	
	If ((tRelated="SameBody")||(tRelated="SameHost")||(tRelated="Corresponding")) { 
		/*
		zenPage.currentId+"~"+zenPage.currentSVGId+"~"+zenPage.currentType+"~"+zenPage.currentClass+"~"+zenPage.currentLine;
		"84~ioLog_12~ioLog~undefined~undefined"                            
		"241~message_241~message~~")                                    
		"164~ack_15~ack~EnsLib.HL7.Message~null")                       
		"441~event_441~event~null~null")
		"ScheduleHandler~host_Ens.ScheduleHandler~host~null~hostLine_Ens.ScheduleHandler                              
		"toSelfHL7HTTP~host_toSelfHL7HTTP~host~null~hostLine_toSelfHL7HTTP"
		*/
		Set tRelatedId=$P(tRelatedItem,"~",1)
		Set tRelatedSVGId=$P(tRelatedItem,"~",2)
		Set tRelatedType=$P(tRelatedItem,"~",3)
		Set tRelatedClass=$P(tRelatedItem,"~",4)
		Set tRelatedLine=$P(tRelatedItem,"~",5)
	}
	#dim tFilterSourceHost,tFilterTargetHost As %String = ""
	#dim tRestrictHeader As Ens.MessageHeader = ""
	#dim tRestrictEvent As Ens.Util.Log = ""
	#dim tRestrictIOLog As Ens.Util.IOLog = ""
	#dim tRestrictACK As %RegisteredObject = ""
	#dim tFilterBodyClass,tFilterBodyID As %String = ""
	If tRelated="SameHost" {
		If tRelatedType="host" {
			/* Get All items that send to or send from this item */
			Set tFilterSourceHost = $E(tRelatedSVGId,6,*) ; "host_*"
			Set tFilterTargetHost = tFilterSourceHost
		} ElseIf tRelatedType="message" {
			Try {
				/* Get All items that have same Source and Target as this message */
				Set tRestrictHeader=##class(Ens.MessageHeader).%OpenId(tRelatedId)
				Set tFilterSourceHost = tRestrictHeader.SourceConfigName
				Set tFilterTargetHost = tRestrictHeader.TargetConfigName
			} Catch {}
		} ElseIf tRelatedType="event" {
			Try {
				/* Get All items that send to or send from this item */
				Set tRestrictEvent=##class(Ens.Util.Log).%OpenId(tRelatedId)
				Set tFilterSourceHost = tRestrictEvent.Source
				Set tFilterTargetHost = tFilterSourceHost
			} Catch {}
		} ElseIf tRelatedType="ioLog" {
			Try {
				/* Get All items that send to or send from this item */
				Set tRestrictIOLog=##class(Ens.Util.IOLog).%OpenId(tRelatedId)
				Set tFilterSourceHost = tRestrictIOLog.ConfigName
				Set tFilterTargetHost = tFilterSourceHost
			} Catch {}
		}
		Set tFilterArray("SourceHost")=tFilterSourceHost
		Set tFilterArray("TargetHost")=tFilterTargetHost
	} ElseIf tRelated = "SameBody" {
		If tRelatedType="message" {
			Try {
				/* Get All items that have same MessageBody Class and ID */
				Set tRestrictHeader=##class(Ens.MessageHeader).%OpenId(tRelatedId)
				Set tFilterBodyClass = tRestrictHeader.MessageBodyClassName
				Set tFilterBodyID = tRestrictHeader.MessageBodyId
				Set tFilterArray("MessageBody")=tFilterBodyClass_":"_tFilterBodyID
			} Catch {}		
		}
	} ElseIf tRelated="Corresponding" {
		If tRelatedType="message" {
			Set tFilterArray("CorrespondingID")=tRelatedId
		} ElseIf tRelatedType="ioLog" {
			Try {
				/* Get corresponding request id */
				Set tRestrictIOLog=##class(Ens.Util.IOLog).%OpenId(tRelatedId)
				Set tFilterArray("CorrespondingID") = tRestrictIOLog.CorrespondingRequestId
			} Catch {}
		} ElseIf tRelatedType="ack" {
			Try {
				/* Get corresponding request id */
				Set tRestrictACK=$CLASSMETHOD(tRelatedClass,"%OpenId",tRelatedId)
				Set tFilterArray("CorrespondingID") = $P(tRestrictACK.Source,$C(13,10),3)
			} Catch {}
		}
		If $G(tFilterArray("CorrespondingID"))="" Kill tFilterArray("CorrespondingID")
		If $D(tFilterArray("CorrespondingID"))#2 {
			Try {
				Set tRestrictHeader=##class(Ens.MessageHeader).%OpenId(tFilterArray("CorrespondingID"))
				Set tFilterArray("CorrespondingID") = tFilterArray("CorrespondingID")_"^"_tRestrictHeader.SourceConfigName_"^"_tRestrictHeader.TimeCreated	
			} Catch {}	
		}
	}

	#; draw messages
	#dim tFilterSpec As %String = ""
	If $D(tFilterArray) {
		#dim tFilter,tFilterKey As %String = ""
		Set tFilterKey = $O(tFilterArray(tFilterKey),1,tFilter)
		While tFilterKey'="" {
			Set tFilterSpec = tFilterSpec_", " _tFilterKey_":"_tFilter
			If tFilterKey="CorrespondingID" Set tFilterSpec = $Piece(tFilterSpec,"^",1)
			Set tFilterKey = $O(tFilterArray(tFilterKey),1,tFilter)
		}
		Set tFilterSpec = $$$TextHTML("Filter")_$ZCVT(" = "_$E(tFilterSpec,3,*),"O","HTML")
	}

		
	#; build trace info
	Set n = ..BuildTraceInfo(sessionId, currPage, .tFilterArray)

	#; Used to pass back in buildinfo annotation
	#dim tFirstMsgId,tItemCount As %String = ""
	#; n=[itemCount]#[rows]#[columns]#[width]#[height]
	#; Used in portal page to find number of items in the trace
	Set tItemCount = +n

	Merge cls = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clsinfo")
	Merge clsInv = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clslane")
	Merge noHeight = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"noheight")

	If ('n) || ($O(cls(""))="") {
		// nothing to show
		&html<<text class="GeneralMessage" x="10" y="36" text-anchor="start">#($$$TextHTML("No messages selected for tracing."))#</text>>
		&html<<annotation id='buildinfo' data='0~0'/>>
		Quit $$$OK // Exit
	}

	//&html<<script language="javascript">
	//var svg = top.document.getElementById("SVGTrace");
	//setCanvasSize(#(canvasWidth)#,#(canvasHeight)#); ???
	//svg.setAttribute("width",#(canvasWidth)#);
	//svg.setAttribute("height",#(canvasHeight)#);
	//svg.setAttribute("viewBox","0 0 #(canvasWidth)# #(canvasHeight)#");
	//</script>
	//>

	Set laneTitle(0) = $$$Text("IO")
	Set laneTitle(1) = $$$Text("Services")
	Set laneTitle(2) = $$$Text("Processes")
	Set laneTitle(3) = $$$Text("Operations")
	Set laneTitle(4) = $$$Text("IO")

	Set hostWidth = ..#HOSTWIDTH
	Set hostLineWidth = ..#HOSTLINEWIDTH
	Set topY = ..#TOPY
	Set deltaY = ..#DELTAY
	Set canvasWidth = $P(n,"#",4)
	Set canvasHeight = $P(n,"#",5)

	If ..mode = 1 {
		Set lastMessage = ..currPage * msgPerPage
		Set firstMessage = lastMessage - msgPerPage + 1
		Merge oldCls = cls
		Kill cls
		For j=firstMessage:1:lastMessage {
			If $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",j,"event")) {
				Set hostname = $get(^("sourceClass"))
				If hostname '= "" {
					Set evtLane=$get(clsInv(hostname))
					If evtLane '= "" {
						Set cls(evtLane,hostname) = $get(oldCls(evtLane,hostname))
						Set tColCount(evtLane) = $get(tColCount(evtLane))+1
					}
				}
			}
			ElseIf $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",j,"iolog")) {
				Set inbound = $get(^("inbound"),0)
				Set ioLane = $select(inbound: 0, 1: 4)
				Set cls(ioLane,"External") = $get(oldCls(ioLane,"External"))
				Set tColCount(ioLane) = 1
			}
			ElseIf $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",j,"ack")) {
				Set inbound=$get(^("inbound"),0)
				Set ackLane = $select(inbound: 0, 1: 4)
				Set cls(ackLane,"External") = $get(oldCls(ackLane,"External"))
				Set tColCount(ackLane) = 1
			}
			Else {
				Set sourceHost=$get(^("sourceClass"))
				Set startLane=$get(^("orType"))
				If (sourceHost '= "") && (startLane '= "") {
					If '$data(cls(startLane,sourceHost)) Set tColCount(startLane) = $get(tColCount(startLane))+1
					Set cls(startLane,sourceHost) = $get(oldCls(startLane,sourceHost))
				}
				
				Set targetHost = $get(^("targetClass"))
				Set endLane = $get(^("destType"))
				If (targetHost '= "") && (endLane '= "") {
					If '$data(cls(endLane,targetHost)) Set tColCount(endLane) = $get(tColCount(endLane))+1
					Set cls(endLane,targetHost) = $get(oldCls(endLane,targetHost))
				}
			}
		}
		Set tNewColCount = 0
		For j=0:1:4 Set tNewColCount = tNewColCount + $get(tColCount(j))
		If tNewColCount '= $piece(n,"#",3) {
			Set canvasWidth = ..#HOSTWIDTH*tNewColCount
			If canvasWidth < 300 Set canvasWidth = 500
		}
		If (lastMessage < n) {
			&html<<g id="traceTruncated" truncated="1" />>
		}
	}
	
	#; canvas
	&html<<rect id="traceCanvas" class="canvas" x="0" y="0" width="#(canvasWidth)#" height="#(canvasHeight)#" onmousedown="svgPage.selectItem(evt, 'canvas');"/>>

	#; find the size of each of the lanes
	#; build index of columns by time
	For i=0:1:4 {
		Set colCount(i) = 0
	}

	If $d(cls(0,"External")) {
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

	If $d(cls(4,"External")) {
		Set laneWidth(4) = hostWidth
		Set laneX(4) = $G(laneX(3),0) + $G(laneWidth(3),0)
		Set colOrder(4,"IOOutput")="Operation.IO"
		Set colCount(4) = 1
	}

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
				Set k = $ZCVT(colOrder(lane,c),"O","HTML")
				// Split into package name and class name
				Set pkgName = $P(k,".",1,$L(k,".")-1)
				Set (clsName,helperName) = $P(k,".",$L(k,"."))
				// If not a good fit, split preferrably at a punctuation character searching left and right around the middle
				If ($L(k)>20) && ((pkgName="") || (clsName="")) {
					#; need to base on unescaped for splitting. Will escaped after split.
					Set k=$zcvt(k,"I","HTML")
					Set mid = $L(k)\2
					Set split = 0
					Set j = 0
					For i = mid:1:$L(k) {
						Set j = j+1
						If $E(k,i)?1p {
							Set pkgName = $E(k,1,i)
							Set clsName = $E(k,i+1,$L(k))
							Set split = 1
							Quit
						}
						If $E(k,mid-j)?1p {
							Set pkgName = $E(k,1,mid-j)
							Set clsName = $E(k,mid-j+1,$L(k))
							Set split = 1
							Quit
						}
					}
					If 'split {
						Set pkgName = $E(k,1,mid)
						Set clsName = $E(k,mid+1,$L(k))
					}
					Set k=$zcvt(k,"O","HTML")
					Set pkgName = $zcvt(pkgName,"O","HTML")
					Set clsName = $zcvt(clsName,"O","HTML")
				}
				Set xm = x + (hostWidth / 2)
				Set nl = nl+1
				If (nl>1) {
					&html<<line class="SepLine#(f)#" x1="#(x)#" y1="#(40-(f*40))#" x2="#(x)#" y2="#(canvasHeight)#" />>
					Set f = 0
				}
				&html<
					<rect class="LaneRect#($S(printable:1,1:nl#2))#" x="#(x)#" y="70" width="#(hostWidth)#" height="#(canvasHeight-70)#" onmousedown="svgPage.selectItem(evt, 'canvas');" />
					<clipPath id="cliphost_#(k)#"><rect x="#(x+5)#" y="40" width="#(hostWidth-6)#" height="30" style="fill:white; stroke:blue;" /></clipPath>
					<rect class="HostLine" id="hostLine_#(k)#" x="#(xm-(hostLineWidth/2))#" y="70" width="#(hostLineWidth)#" height="#(canvasHeight-70)#" />
					<rect class="HostRect" id="host_#(k)#" x="#(x+2)#" y="40" width="#(hostWidth-4)#" height="30" rx="4" onmousedown="svgPage.selectItem(evt, 'host', 'host_#(k)#', '#(clsName)#', null, 'hostLine_#(k)#');" />
					<text class="HostTitle" x="#(xm)#" y="52" clip-path="url(#cliphost_#(k)#)" text-anchor="middle" onmousedown="svgPage.selectItem(evt, 'host', 'host_#(k)#', '#(clsName)#', null, 'hostLine_#(k)#');">#(pkgName)#</text>
					<text class="HostTitle" x="#(xm)#" y="65" clip-path="url(#cliphost_#(k)#)" text-anchor="middle" onmousedown="svgPage.selectItem(evt, 'host', 'host_#(k)#', '#(clsName)#', null, 'hostLine_#(k)#');">#(clsName)#</text>
				>

				#; draw helper text along the host rect (going down)
				Set yt = 400
				While (yt < (canvasHeight - 75)) {
					#; writing-mode="tb", not supported- use rotate 
					&html<<text class="HostRectLabel" x="#(xm)#" y="#(yt)#" text-anchor="middle" transform="rotate(90,#(xm)#,#(yt)#) translate(0,5)">#(helperName)#</text>>

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
			<text class="HostRectLabel" x="13" y="#(yt-100)#" text-anchor="middle" transform="rotate(90,13,#(yt-100)#) translate(0,5)">#($$$Text("Time"))#</text>
		>
		Set yt = yt + 400
	}

	#; draw messages
	Set y = topY
	Set msgcount = 0
	Set maxMessage = ..currPage * msgPerPage
	Set n = maxMessage - msgPerPage + 1
	While ((n '= "") && (msgcount < msgPerPage)) {
		If $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"event")) {
			// draw event marker
			Set hostname=^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"sourceClass")
			If ""'=hostname {
				Set laneStart = $G(clsInv(hostname))
				If ""'=laneStart {
					Set colStart = $G(cls(laneStart,hostname))
					If ""'=colStart {
						Set xStart = laneX(laneStart) + ((colStart-1) * hostWidth) + (hostWidth / 2)
						Set eventId = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id")
						Set eventType = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"type")

						Set eventStyle = "eventMarkerBack"
						&html<<rect id="event_#(eventId)#" class="#(eventStyle)#" x="#(xStart-7)#" y="#(y-7)#" width="14" height="14"/>>

						If (eventType>0) {
							Set eventStyle = "eventMarker"_eventType
							Set path =  "M " _(xStart-6)_" "_y_" L "_xStart_" "_(y+6)_" "_(xStart+6)_" "_y_" "_xStart_" "_(y-6)_" z"
							&html<<path class="#(eventStyle)#" d="#(path)#" onmousedown="svgPage.selectItem(evt, 'event', 'event_#(eventId)#', '#(eventId)#', null, null);"/>>
						} Else {
							Set eventStyle = "ruleMarker"_(-eventType)
							Set path =  "M " _(xStart)_" "_y_" m -5.5, 0 a 5.5,5.5 0 1,0 11,0 a 5.5,5.5 0 1,0 -11,0"
							&html<<path class="#(eventStyle)#" d="#(path)#" onmousedown="svgPage.selectItem(evt, 'rule', 'rule_#(eventId)#', '#(eventId)#', null, null);"/>>
						}
						&html<<text class="MsgLabel" x="#(xStart - 12)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			
						Set y = y + deltaY	
					}
				}
			}
		}
		ElseIf $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"iolog")) {
			Set hostname = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"host")
			Set inbound = $g(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"inbound"),0)
			Set laneStart = $s(inbound: 0, 1:4)
			Set xStart = laneX(laneStart) + (hostWidth / 2)
			Set ioId = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id")
			Set correspondingHdrId = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgid"))

			&html<<g id="ioLogGrp_#(n)#" onmousedown="svgPage.selectItem(evt, 'ioLog', 'ioLog_#(n)#', '#(ioId)#');" >>
			Set ioStyle = "eventMarkerBack"
			&html<<rect id="ioLog_#(n)#" class="#(ioStyle)#" x="#(xStart-9)#" y="#(y-9)#" width="18" height="18" entrytype="ioEntry" entryid="#(ioId)#" correspondingId="#(correspondingHdrId)#"/>>

			Set ioStyle = "ioArrows"
			Set topPath =  "M " _(xStart-7)_" "_(y-5)_" L "_(xStart+1)_" "_(y-5)_" "_(xStart+1)_" "_(y-8)_" "_(xStart+8)_" "_(y-4)_" "_(xStart+1)_" "_(y+1)_" "_(xStart+1)_" "_(y-2)_" "_(xStart-8)_" "_(y-2)_" z"
			&html<<path class="#(ioStyle)#" d="#(topPath)#" />>

			Set bottomPath =  "M " _(xStart+7)_" "_(y+5)_" L "_(xStart-1)_" "_(y+5)_" "_(xStart-1)_" "_(y+8)_" "_(xStart-8)_" "_(y+4)_" "_(xStart-1)_" "_(y-1)_" "_(xStart-1)_" "_(y+2)_" "_(xStart+8)_" "_(y+2)_" z"
			&html<<path class="#(ioStyle)#" d="#(bottomPath)#" />>

			&html<<text class="MsgLabel" x="#(xStart - 13)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			&html<</g>>
			If (inbound)&&$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"id"),nextmsgId) {
				If $g(nextmsgId) '= ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgid") {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}
		ElseIf $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"ack")) {
			Set ackId = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id")
			Set ackClass = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgclass")
			Set hostname = $p($g(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"ack",ackId)),"^",1)
			If hostname="" {
				Set hosttype = ""
			}
			Else {
				Set hosttype = $g(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clslane",hostname))
			}
			Set inbound = $g(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"inbound"),0)
			Set correspondingHdrId = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgid"))
			// Information coming from a matching IOLog record may override previously designated IO lane
			If hosttype=1 {
				Set inbound = 1
			}
			ElseIf hosttype=3 {
				Set outbound = 0
			}
			Set laneStart = $s(inbound: 0, 1:4)
			Set xStart = laneX(laneStart) + (hostWidth / 2)

			Set ackStyle = "ackBack"
			&html<<g id="ackGrp_#(n)#" onmousedown="svgPage.selectItem(evt, 'ack', 'ack_#(n)#', '#(ackId)#', '#(ackClass)#', null);" >>
			&html<<rect id="ack_#(n)#" class="#(ackStyle)#" x="#(xStart-7)#" y="#(y-7)#" width="14" height="14" entrytype="ack" entryid="#(ackClass)#:#(ackId)#" correspondingId="#(correspondingHdrId)#"/>>

			Set ackStyle = "ackArrow"
			Set path =  "M " _(xStart-6)_" "_y_" L "_xStart_" "_(y+5)_" "_xStart_" "_(y+1)_" "_(xStart+6)_" "_(y+1)_" "_(xStart+6)_" "_(y-2)_" "_xStart_" "_(y-2)_" "_xStart_" "_(y-6)_" z"

			&html<<path class="#(ackStyle)#" d="#(path)#" />>
			&html<<text class="MsgLabel" x="#(xStart - 14)#" y="#(y+2)#" text-anchor="end">[#(n)#]</text>>
			&html<</g>>
			If (inbound)&&$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"id"),nextmsgId) {
				If $g(nextmsgId) '= ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgid") {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}
		Else {
			Set laneStart = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"orType")
			Set laneEnd = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"destType")

			Set colStart = cls(laneStart,^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"sourceClass"))
			Set colEnd = cls(laneEnd,^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"targetClass"))

			Set xStart = laneX(laneStart) + ((colStart-1) * hostWidth) + (hostWidth / 2)
			Set zend = laneX(laneEnd) + ((colEnd-1) * hostWidth) + (hostWidth / 2)

			#; draw message line
			Set msgId = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id")
			If tFirstMsgId = "" Set tFirstMsgId = msgId
			Set msgTime = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"time")
			Set msgClass = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgClass")
			Set callType = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"callType")
			Set msgType = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"msgType")
			Set respNo = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"respNo"))
			Set backLink = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"back"))
			Set backPos = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"backPos"))

			Set startStyle = "MsgStart" _ callType

			#; test for queued/discarded messages
			#; queued = 2, discarded = 4

			Set s = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"status")
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
			Set hasResponse = ((respNo '= "") && ((callType = "Sync") || (callType = "Async")))
			
			If hasResponse {
				Set lineLink = "respLine_"_msgId
			}
			ElseIf backLink '= "" {
				Set lineLink = "respLine_" _ backLink
			}
			Else {
				Set lineLink = ""
			}
			
			&html<<g id="#(msgId)#" lineId="#(lineLink)#" rectId="message_#(msgId)#" onmousedown="svgPage.selectItem(evt, 'message', 'message_#(msgId)#', '#(msgId)#', null, '#(lineLink)#');">>

			#; link to response
			If hasResponse {
				#; draw fancy response lines
				#; search for entries with no height
				Set tRespNo = respNo
				Set tDrawEnd = 1
				If tRespNo > maxMessage {
					Set tRespNo = maxMessage + 1
					Set tDrawEnd = 0
				}
				Set tHeightKey = +n
				Set tMissing = 0
				For {
					Set tHeightKey = $order(noHeight(tHeightKey))
					Quit:(tHeightKey="")||(tHeightKey>tRespNo)
					Set tMissing = tMissing + 1
				}
				Set rh = (tRespNo - n - tMissing) * deltaY

				#; prevent overlap using advanced heuristics
				Set rc = ($R(10) + 2)

				&html<<polyline id="respLine_#(msgId)#" class="LinkLine" points="#(zend-off)# #(y)#, #(zend-off-(rc*a))# #(y)#, #(zend-off-(rc*a))# #(y+rh)##($select(tDrawEnd: ", "_(zend-off)_" "_(y+rh),1:""))#" />>
			}
			ElseIf backLink && backPos && (backPos <= ((currPage-1) * msgPerPage)) {
				Set rc = ($R(10) + 2)
				&html<<polyline id="respLine_#(backLink)#" class="LinkLine" points="#(xStart-off)# #(y)#, #(xStart-off+(rc*a))# #(y)#, #(xStart-off+(rc*a))# 70" />>
			}

			#; selection box
			Set mt = "" // (msgType="Response") // different background colors for request and response messages
			&html<<rect id="message_#(msgId)#" class="MsgOutline#(mt)#" x="#(xSel)#" y="#(y-12)#" width="#(xSelWid)#" height="24" rx="4" />>

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

			If $data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"iolog"))&&$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"msgid"),ioLogMsg) {
				If ioLogMsg '= ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id") {
					Set y = y + deltaY
				}
			}
			ElseIf $data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"ack"))&&$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"msgid"),ackMsg) {
				If (ackMsg '= ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n,"id"))||($g(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n+1,"inbound"))) {
					Set y = y + deltaY
				}
			}
			Else {
				Set y = y + deltaY
			}
		}

		#; next message
		Set n = $O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n))
		Set msgcount = msgcount + 1
	}
	Set tItemCount = tItemCount_"~"_tFirstMsgId_"~"_tFilterSpec
	&html<<annotation id='buildinfo' data='#(tItemCount)#'/>>

	Quit $$$OK
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status
{
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

/* Rule Log */

.ruleMarker1 {
	fill: green;
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

.selected {
	stroke-width: 2;
}
>
	Write "]]></style>>"

	Quit $$$OK
}

/// Callback method called when drawing the SVG defs for this page.
ClassMethod %OnDrawSVGDef() As %Status
{
	&html<<defs>
	<!-- defs -->>

	/*
	&html<
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
*/

	&html<

<!-- filters -->
<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
<feOffset dx="4" dy="4" result="offsetBlur" />
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

ClassMethod BuildSpec(filter = "session", sessionId = "", startTime = "", endTime = "", startId = "", endId = "", Output includeEvents, Output eventsWindow, Output eventsMaxRows, Output showInternalItems, Output includeIOLogEntries, Output includeACKs, ByRef pFilterArray) As %String [ Internal, Private ]
{
	Set includeEvents = ..IncludeEvents()
	Set eventsWindow = ..EventsWindow()
	Set eventsMaxRows = ..EventsMaxRows()
	Set showInternalItems = ..ShowInternalItems()
	Set includeIOLogEntries = ..IncludeIOLogEntries()
	Set includeACKs = ..IncludeAcks()
	
	Set spec = filter _ "^" _ sessionId _
						"^" _ startTime _
						"^" _ endTime _
						"^" _ startId _
						"^" _ endId _
						"^" _ includeEvents _
						"^" _ eventsWindow _
						"^" _ eventsMaxRows _
						"^" _ showInternalItems _
						"^" _ includeIOLogEntries _
						"^" _ ..#TRACETYPE _
						"^" _ includeACKs
						
	Set tFilterKey = $O(pFilterArray(""),1,tFilter)
	While tFilterKey'="" {
		Set spec = spec_"^" _tFilterKey_tFilter
		Set tFilterKey = $O(pFilterArray(tFilterKey),1,tFilter)
	}					
	Quit spec
}

ClassMethod UseOldData(spec As %String = "", timeCreated As %String = "", currPage As %String = 1, msgPerPage As %Integer, Output returnValue As %String) As %Boolean
{
	Set returnValue = ""
	If (spec = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"spec"))) {
		Set oldtmc = +$G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"tmc"))

		#; only reuse temp file within a specific time window
		If ((timeCreated>=oldtmc) && ((timeCreated-oldtmc)<=..#CACHETIMEOUT)) {
			#; reuse
			Set tStartN = ((currPage - 1) * msgPerPage) + 1
			Kill noHeight, classinfo
			Merge noHeight = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"noheight")
			Merge classinfo = ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"clsinfo")
			Set tColCount = ..GetColCount(currPage, .classinfo)
			Set returnValue = ..CalculateDimensions(+$G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"count")),+$G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"rowcount")),tColCount,tStartN,.noHeight)
			Quit 1
		}
	}
	Quit 0
}

/// Construct arrays containing the trace info for this message session:<br>
/// <var>^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")</var> contains info about each message.<br>
/// <var>cls</var> contains info about the Business classes used.<br>
/// This method returns the number of items (messages / events/ IOLog entries), the number of rows, 
/// the number of columns, the width and the height of the SVG diagram.
/// The format of this string is as follows:
/// [itemCount]#[rows]#[columns]#[width]#[height]
ClassMethod BuildTraceInfo(sessionId As %String = "", currPage As %String = "1", ByRef pFilterArray As %String) As %String [ Internal ]
{
	// For debugging
	If '$d(%request) Set %request=##class(%CSP.Request).%New()
	If '$d(%session) Set %session=##class(%CSP.Session).%New(99)

	// To do:  Add some indication that the search ended due to having exceded search boundaries (HCR)

	#; Note: there are 5 lanes encoded as follows:
	#; 0 = IO to/from Service
	#; 1 = Service
	#; 2 = Process 
	#; 3 = Operation
	#; 4 = IO to/from Operation

	#; get search parms from properties
	Set (startTime,endTime,startId,endId)="" // We are no longer using these (HCR)
	//Set sessionId = ..sessionId
	//Set startTime = ..startTime
	//Set endTime = ..endTime
	//Set startId = ..startId
	//Set endId = ..endId
	//Set currPage = ..currPage
	
	/* Set up Filters */
	
	#dim tFilterSourceHost As %String = $G(pFilterArray("SourceHost"))
	#dim tFilterTargetHost As %String = $G(pFilterArray("TargetHost"))
	#dim tFilterMessageBody As %String = $P($G(pFilterArray("MessageBody")),":",1)
	#dim tFilterMessageBodyID As %String = $P($G(pFilterArray("MessageBody")),":",2)
	#dim tFilterCorrespondingID As %String = $P($G(pFilterArray("CorrespondingID")),"^",1)
	#dim tFilterCorrespondingSource As %String = $P($G(pFilterArray("CorrespondingID")),"^",2)
	#dim tFilterCorrespondingTime As %String = $P($G(pFilterArray("CorrespondingID")),"^",3)
	
	&sql(SELECT SessionId INTO :sessionId FROM Ens.MessageHeader WHERE %ID = :sessionId)

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
	Set spec = ..BuildSpec("session",sessionId,startTime,endTime,startId,endId,.IncludeEvents,.EventsWindow,.EventsMaxRows,.ShowInternalItems,.IncludeIOLogEntries,.IncludeACKs,.pFilterArray)
	
	Do ##class(EnsPortal.SessionEvents).Initialize()
	#; check if our temp data is for this request
	Lock +^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")
	If ..UseOldData(spec,tmc,currPage,msgPerPage,.return) {
		Lock -^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")
		Quit return
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
				AND
				(
						(
							(:tFilterSourceHost IS NULL)
							AND
							(:tFilterTargetHost IS NULL)
						)
						OR
						(
							(:tFilterSourceHost = :tFilterTargetHost)
							AND
							(
								(SourceConfigName=:tFilterSourceHost)
								OR 
								(TargetConfigName=:tFilterTargetHost)
							)
						)
						OR
						(
							(:tFilterSourceHost <> :tFilterTargetHost)
							AND
							(
								(SourceConfigName=:tFilterSourceHost)
								AND 
								(TargetConfigName=:tFilterTargetHost)
							)
						)
				)
				AND
				(
					(:tFilterMessageBody IS NULL)
					OR
					(MessageBodyClassName=:tFilterMessageBody AND MessageBodyID=:tFilterMessageBodyID)
				)
				AND
				(
					(:tFilterCorrespondingID IS NULL)
					OR
					(ID = :tFilterCorrespondingID)
					OR
					(CorrespondingMessageID = :tFilterCorrespondingID)
					OR
					(
						(:tFilterCorrespondingSource IS NOT NULL)
						AND
						(:tFilterCorrespondingTime IS NOT NULL)
						AND
						(TargetConfigName = :tFilterCorrespondingSource)
						AND
						(TimeCreated <= :tFilterCorrespondingTime)
					)
				)
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
	Set tLimitEvents = $G(^EnsPortal.Settings($USERNAME,"VisualTrace","LimitEvents"),$G(^EnsPortal.Settings("_Ensemble","VisualTrace","LimitEvents"),1))
	If IncludeEvents && ((EventsMaxRows>0)||'tLimitEvents) {
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
			If tLimitEvents {
				Set k=k+1
				If (k>EventsMaxRows) Quit  // Reached EventsMaxRows
			}
 			If sesId=sessionId {
 				// Event generated by the session
 				Set:eventHost="" eventHost=eventClass
 				Set:eventHost'="" tEvents(eventTime_"#"_eventMsg,eventId) = $LB(eventHost, eventType)
 			}
   				&sql(FETCH sqlEVENTTIME)
		}
		&sql(CLOSE sqlEVENTTIME)
		/* If went over max find last 1000 event logs */
		If tLimitEvents&&(k>EventsMaxRows) {
			#;Remove events window from endEventTimes
			Set endEventTime = $P(endTime2,".",1)
			Set dt = $ZDTH(endEventTime,3,1,,,,,,,-1)
			If dt'=-1 {
				Set t = $P(dt,",",2)
				If t<86400 Set $p(dt,",",2) = t
				Else  Set $P(dt,",",1) = $P(dt,",",1)+1, $P(dt,",",2) = t-86400
				Set endEventTime = $ZDT(dt,3,1)_"."_fs // Put back the fractional part
			}
			&sql(DECLARE sqlEVENTTIMEDESC CURSOR FOR 
			SELECT %ID, SessionId, TimeLogged, ConfigName, Type, MessageId, SourceClass
			INTO :eventId, :sesId, :eventTime, :eventHost, :eventType, :eventMsg, :eventClass
			FROM Ens_Util.Log
			WHERE TimeLogged >= :startTime2 AND TimeLogged <= :endEventTime
			ORDER BY TimeLogged DESC
			)
			Set kreverse = 0
			&sql(OPEN sqlEVENTTIMEDESC)
			&sql(FETCH sqlEVENTTIMEDESC)
			While (SQLCODE = 0) {
				Set kreverse = kreverse+1 If kreverse>EventsMaxRows Quit  // Reached EventsMaxRows  	
				If sesId=sessionId {
 					// Event generated by the session
 					Set:eventHost="" eventHost=eventClass
 					If eventHost'="" {
	 					If $D(tEvents(eventTime_"#"_eventMsg,eventId)) Quit
	 					Set tEvents(eventTime_"#"_eventMsg,eventId) = $LB(eventHost, eventType)
 					}
 				}
   				&sql(FETCH sqlEVENTTIMEDESC)
			}
			&sql(CLOSE sqlEVENTTIMEDESC)
		}
	
		#; get rule logs and sort by time. Insert as if an Event and identify as type -1
		&sql(DECLARE sqlRULELOG CURSOR FOR 
			SELECT %ID, TimeExecuted, ConfigName, CurrentHeaderId
			INTO :ruleId,:ruleTime, :ruleHost, :ruleMsg
			FROM Ens_Rule.Log
			WHERE SessionId = :sessionId
		)
		&sql(OPEN sqlRULELOG)
		&sql(FETCH sqlRULELOG)
		While (SQLCODE = 0) {
				If ruleMsg = "" Set ruleMsg = sessionId
				If ruleHost = "" Try {Set ruleHost = ##class(Ens.MessageHeader).%OpenId(sessionId).SourceConfigName} Catch {}
				Set tEvents(ruleTime_"#"_ruleMsg,ruleId) = $LB(ruleHost,-1)
				&sql(FETCH sqlRULELOG)
			}
		&sql(CLOSE sqlRULELOG)
	}

	Set tEventTime = $O(tEvents(""))

	// figure out types of origin etc.
	Set n = 0
	Set tIOLogData = 0
	Set tRowCount = 0

	If (filter="time") || (filter="id") {
		If IncludeIOLogEntries {
			// Force use of SessionId index first
			Set tIOLogSQL = "SELECT io.%ID As ID, io.ConfigName, io.CorrespondingRequestId, io.IsInbound, io.TimeReceived, io.HostClass "
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
			Set tIOLogSQL = "SELECT io.%ID As ID, io.ConfigName, io.CorrespondingRequestId, io.IsInbound, io.TimeReceived, io.HostClass "
			 				_"FROM Ens_Util.IOLog io "
							_"WHERE io.SessionId = ? "
							_"AND ((? IS NULL) OR (CorrespondingRequestId = ?))"
							_"ORDER BY io.%ID"
			Set tIOLogState = ##class(%SQL.Statement).%New()
			Set tSC = tIOLogState.%Prepare(tIOLogSQL)
			If $$$ISOK(tSC) {
				Set tIOLogRS = tIOLogState.%Execute(sessionId,tFilterCorrespondingID,tFilterCorrespondingID)
				If $IsObject(tIOLogRS) Set tIOLogData = tIOLogRS.%Next()
			}
		}
		&sql(OPEN sqlSESSION)
		&sql(FETCH sqlSESSION)
	}

	Kill internalItems Do:'ShowInternalItems ..ArrayOfInternalItems(.internalItems)
	Kill noHeight
	Kill tErrors

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
			Kill currentMsgData 
		
			Set currentMsgData("id") = id
			Set currentMsgData("time") = $$$timeUTCtoLocal(ctime)
			Set currentMsgData("orType") = ortype
			Set currentMsgData("destType") = desttype
		
			If classname="" {
				Set currentMsgData("msgClass") = "NULL"
			} else {
				Try {
					Set mb = $classmethod(classname,"%OpenId",body)
					If ($IsObject(mb)) {
						Set currentMsgData("msgClass") = $classname(mb)
						If IncludeACKs && mb.%Extends("EnsLib.EDI.Document")&&('(mb.%IsA("EnsLib.EDI.ASTM.Document"))) {
							Set findACK = 1
							If mb.%Extends("EnsLib.EDI.BatchDocument")&&(mb.ParentId'="") Set findACK = 0
							
							Set findACK("class") = $classname(mb)
							Set findACK("timeCreated") = mb.TimeCreated
							; If we are a response being returned to a service
							If (desttype=1)&&(msgtype=2) Set findACK("response")=body
						}
					}
					Else {
						// ain't got no body...
						Set currentMsgData("msgClass") = "N/A"
					}
				}
				Catch ex {
					If ex.Name [ "<CLASS DOES NOT EXIST>" {
						Set currentMsgData("msgClass") = "N/A"
					}
					Else { Throw ex }
				}
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
					Set:currentMsgData("msgType")="Response" currentMsgData("callType") = "SyncResponse"
				}
				Else {
					Set:currentMsgData("msgType")="Response" currentMsgData("callType") = "AsyncResponse"
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
			Set tAddAcks = IncludeACKs && findACK&&(findACK("class")'="")&&((ortype=1)||(desttype=3)||(desttype=1))
			Do InjectEvents(0,tAddAcks)
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
	//Merge ^h($zh)=^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace") // For debugging

	#; return total number of messages and other items found, plus number of rows and columns
	Set startMessage = ((currPage - 1) * msgPerPage) + 1

	Quit ..CalculateDimensions(n,tRowCount,cc,startMessage,.noHeight) // No.items # No.rows # No.cols # width # height

InjectEvents(inbound=1,addACKs=0)
	If addACKs {
		Do AddACKs()
	}
	Set tNextAck = $order(tAckData(""))

	// event time is "time#msgId"
	While 1 {
		// inject events into list
		Set tNextEvent = $p(tEventTime,"#")
		Set tNextEventMsgId = $p(tEventTime,"#",2)
		If tIOLogData {
			If id && (tIOLogRS.%Get("CorrespondingRequestId") > id) {
				Set tNextIOLog = ""
			}
			Else {
				Set tNextIOLog = tIOLogRS.%Get("TimeReceived")
			}
		}
		Else { Set tNextIOLog = "" }
		
		// Quit if no items are next
		If (tNextEvent = "") && (tNextIOLog = "") && (tNextAck = "") {
			Quit
		}
		
		// Work out which timestamp is first - logic is dependent on three comparisons
		Set tTimes = $lb(tNextEvent, tNextIOLog, tNextAck)
		Set tTypes = $lb("event", "iolog", "ack")
		Set tPrecedes = $lb()
		Set tNext = ""
		For i=1:1:3 {
			Set j = (i+1)#3
			If j=0 Set j=3
			If ($lg(tTimes,i) = "") && ($lg(tTimes,j) = "") {
				Set tNextIndex = (i-1)#3
				If tNextIndex = 0 Set tNextIndex = 3
				Set tNext = $lg(tTypes,tNextIndex)
				Quit
			}
			ElseIf $lg(tTimes,i) = "" {
				Set $list(tPrecedes, i) = 0
			}
			ElseIf $lg(tTimes,j) = "" {
				Set $list(tPrecedes, i) = 1
			}
			ElseIf i = 1 { // events should not precede ACKs and IOLog entries with same timestamp EXCEPT if event precedes message
				Set $list(tPrecedes, i) = $select(tNextEventMsgId < id: 1, 1: $lg(tTimes,j) ] $lg(tTimes, i))
			}
			Else {
				Set $list(tPrecedes, i) = $lg(tTimes, i) '] $lg(tTimes, j)
			}
		}
		If tNext = "" {
			// Precedes = ( 1 v 2, 2 v 3, 3 v 1 )
			If $lg(tPrecedes, 1) = 0 {
				Set tNextIndex = $select($lg(tPrecedes, 2): 2, 1: 3)
			}
			Else {
				Set tNextIndex = $select($lg(tPrecedes, 3): 3, 1: 1)
			}
			Set tNext = $lg(tTypes,tNextIndex)
		}

		If tNext = "event" { ; event comes first
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
					Set tSameRow = 1
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
		ElseIf (tNext = "iolog") { ; IO Log entry comes first
			// Quit if last IOLog entry or logged at the same time or after message was created
			If (tNextIOLog = "") || (tNextIOLog = ctime) || (tNextIOLog ] ctime) {
				Quit
			}
			Set n = n + 1
			If ('tSameRow)&&((tIOLogRS.%Get("ConfigName") = sourceClass) || (tIOLogRS.%Get("ConfigName") = targetClass)) { 
				Set tSameRow = 1
				Set noHeight(n) = ""
			}
			Else { 
				Set tSameRow = 1
				Set tRowCount = tRowCount + 1
			}
			Kill tCurrentData
			Set tCurrentData("iolog") = 1
			Set tCurrentData("id") = tIOLogRS.%Get("ID")
			Set tCurrentData("msgid") = tIOLogRS.%Get("CorrespondingRequestId")
			Set tCurrentData("host") = tIOLogRS.%Get("ConfigName")
			
			Set tInbound = tIOLogRS.%Get("IsInbound")
			Set tLaneType = "outbound"
			If tInbound {
				Set tCurrentData("inbound") = tInbound
				Set tLaneType = "inbound"
			}
			Set tIOLogLanes(tLaneType) = ""
			Set tIOLogLanes(tLaneType,"IOLog")=""
			If '$d(tIOLogLanes(tLaneType,"first")) Set tIOLogLanes(tLaneType,"first") = tIOLogRS.%Get("ID")

			Set cls(4 * ('tInbound),"External") = ""
			Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n) = tCurrentData
			Set tObj = ##class(Ens.Util.IOLog).%OpenId(tIOLogRS.%Get("ID"))
			If $IsObject(tObj) {
				Set tConfigName = tObj.ConfigName
				If tConfigName'="" {
					Set tHostType = $g(clsInv(tConfigName))
					Try {
						Set tOut = tObj.OutObjectId
						If (tOut'="") && (tHostType=1) Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"ack",tOut) = tConfigName_"^out"
						Set tIn = tObj.InObjectId
						If (tIn'="") && (tHostType=3) Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",0,"ack",tIn) = tConfigName_"^in"
					} Catch {}
				}
			}
			Set tIOLogData = tIOLogRS.%Next()
		}
		ElseIf (tNext = "ack") {
			// Quit if last ACK or if ACK occurred at the same time (or after) message was created
			If (tNextAck = "") || (tNextAck = ctime) || (tNextAck ] ctime) {
				Quit
			}
			Set tNextAckClass = $order(tAckData(tNextAck,""))
			While tNextAckClass '= "" {
				Set tTempList = ""
				Set tNextAckId = $order(tAckData(tNextAck,tNextAckClass,""),1,tTempList)
				/*
					tTempList("toSelfHL7HTTP","220",0,"144",1) 
					Where 
						1st = source or target class 
						2nd = id or Corresponding request id if outbound
						3rd = inbound/outbound
						4th = bodyid
						5th = def/orig
					
				*/
				While tNextAckId '= "" {
					Set n = n + 1
					Set tSameRow = 1
					If ('tSameRow)&&$lg(tTempList,3) {
						//Set noHeight(n) = ""
					}
					Else {
						Set tRowCount = tRowCount + 1
					}
					Kill tAckArray
					Set tAckArray("ack") = 1
					Set tAckArray("host") = $lg(tTempList,1)
					Set tAckArray("msgclass") = tNextAckClass
					Set realMsgId = ""
					Set tClassTablename = $get(tAckIntern("sqltable",tNextAckClass))
					If tClassTablename '= "" {
						Set bodyRef = $select(body = $lg(tTempList,4): body, 1: $lg(tTempList,4))						
						Set tQueryLoc = $select($listget(tTempList,5): "def", 1: "orig")						
						If tQueryLoc = "def" {
							If (bodyRef '= "") && ((id="")||(desttype="")||('$data(tAckIntern("done",tQueryLoc,tClassTablename,bodyRef,desttype,id)))) {
								If (desttype="") {
									Set desttype = $order(tAckIntern("done",tQueryLoc,tClassTablename,bodyRef,desttype),-1)
								}
								If (desttype'="") Set realMsgId = $order(tAckIntern("done",tQueryLoc,tClassTablename,bodyRef,desttype,id),-1)
							}						
						} Else {
							If (bodyRef '= "") && ((id="")||('$data(tAckIntern("done",tQueryLoc,tClassTablename,bodyRef,id)))) {
								Set realMsgId = $order(tAckIntern("done",tQueryLoc,tClassTablename,bodyRef,id),-1)
							}
						}
					}
					If realMsgId = "" {
						Set realMsgId = id
					}
					Set tAckArray("msgid") = realMsgId
					
					Set tAckArray("id") = tNextAckId
					Set tAckArray("timecreated") = tNextAck
					Set tLaneType = "outbound"
					If $lg(tTempList,3) {
						Set tAckArray("inbound") = 1
						Set tLaneType = "inbound"
					} Else {
						#; If we know it was a corresponding message header id
						If $E($lg(tTempList,2),*)="*" {
							Set tAckArray("msgid") = $E($lg(tTempList,2),1,*-1)
							If (tAckArray("msgid")'="") && $D(msgIndex(tAckArray("msgid")))	Set tAckArray("backPos") = msgIndex(tAckArray("msgid"))
						}
					}
					Set tIOLogLanes(tLaneType) = ""
					Set tIOLogLanes(tLaneType,"ACK") = ""
					If '$data(tIOLogLanes(tLaneType,"first")) Set tIOLogLanes(tLaneType,"first") = tNextAckId
					
					Merge ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace",n) = tAckArray
					Set cls(4 * '$lg(tTempList,3),"External") = ""
					Set tTempList = "",tNextAckId = $order(tAckData(tNextAck,tNextAckClass,tNextAckId),1,tTempList)
				}
				Set tNextAckClass = $order(tAckData(tNextAck,tNextAckClass))
			}
			Kill tAckData(tNextAck)
			Set tNextAck = $order(tAckData(tNextAck))
		}
	}
	Quit

AddACKs()
	// All the reusable data is cached under the tAckIntern local
	Set tClassTablename = $get(tAckIntern("sqltable",findACK("class")))
	If tClassTablename = "" {
		Set tClassTablename = $$$ClassSQLTable(findACK("class"))
		Set tAckIntern("sqltable",findACK("class")) = tClassTablename
	}
	Set tQueryIsDef = 1
	If $g(findACK("response")) { ; use original document for search
		If $data(tAckIntern("done","orig",tClassTablename,body)) {
			Set tAckIntern("done","orig",tClassTablename,body,id) = ""
			Quit
		}
		Set tStatement = $get(tAckIntern("stmt","orig",tClassTablename))
		If '$IsObject(tStatement) {
			Set tStatement = ##class(%SQL.Statement).%New()
			Set tAckIntern("stmt","orig",tClassTablename) = tStatement
			Set tOK = tStatement.%Prepare("SELECT %ID AS ID, TimeCreated, Source, ChildCount FROM "_tClassTablename
				_" WHERE %ID = ?")
			If 'tOK Set tErrors($i(tErrors)) = tOK Quit
		}
		Set tAckRS = tStatement.%Execute(body)
		Set tAckIntern("done","orig",body,id) = ""
		Set tQueryIsDef = 0
	}
	Else {
		If $data(tAckIntern("done","def",tClassTablename,body,desttype)) {
			Set tAckIntern("done","def",tClassTablename,body,desttype,id) = ""
			Quit
		}
		Set tStatement = $get(tAckIntern("stmt","def",tClassTablename))
		If '$IsObject(tStatement) {
			Set tStatement = ##class(%SQL.Statement).%New()
			Set tAckIntern("stmt","def",tClassTablename) = tStatement
			Set tOK = tStatement.%Prepare("SELECT %ID AS ID, TimeCreated, Source, ChildCount FROM "_tClassTablename
				_" WHERE OriginalDocId = ? AND TimeCreated >= ?"
				_" ORDER BY ID")
			If 'tOK Set tErrors($i(tErrors)) = tOK Quit
		}
		Set tGetTime = $get(tAckInternal("timecreated",findACK("class")))
		If tGetTime = "" {
			Set tGetTime = ##class(%Dictionary.CompiledClass).IDKEYExists(findACK("class"), "TimeCreatedGetStored")
			Set tAckInternal("timecreated",findACK("class")) = tGetTime
		}
		If tGetTime {
			Set tBodyTime = $classmethod(findACK("class"),"TimeCreatedGetStored", body)
		}
		Else {
			Set tBodyTime = ctime
		}
		Set tAckRS = tStatement.%Execute(body, tBodyTime)
		Set tAckIntern("done","def",tClassTablename,body,desttype,id) = ""
	}
	If '$IsObject(tAckRS) Quit
	While tAckRS.%Next() {
		Set tInboundAck = 0
		Set tAckSet = 0
		Set tDone = 0
		// Choose between Service IO and Operation IO given the information we have at the moment
		// If we are a service, perform additional checks
		If (ortype = 1) {
			Set tInboundAck = 1
			// If Source = originalID, it is inbound
			If (tAckRS.Source = body) {
				Set tAckSet = 1
			}
			// Otherwise, if not a batch AND not a match, then check for ACK in operation
			ElseIf (0 = +tAckRS.ChildCount) {
				// Ensure that this isn't the ACK from the operation
				If (tAckRS.Source [ $c(13,10)) && (desttype = 3) {
					Set tAckSet = 1
					Set tInboundAck = 0
				}
				Else {
					Set tDone = 1
				}
			}
			// If this is a synchronous send, we use a returned body as the ack
			If (reqID '= "") && (reqID > id) {
				Set tDone = 1
			}
		}
		If ('tDone) && ('tAckSet) && ((ortype = 3)||(desttype=3)) {
			; Operation constructs responses differently
			If tAckRS.Source = body {
				Set tDone = 1
			}
		}
		If tDone Continue
		If ('tAckSet) && ('tInboundAck) && (desttype = 1) { Set tInboundAck = 1 }
		
		Try {
			Set tCorrespondingMessageHeaderID = $P(tAckRS.Source,$C(13,10),3)
			If (tFilterCorrespondingID'="")&&(tCorrespondingMessageHeaderID'="")&&(tFilterCorrespondingID'=tCorrespondingMessageHeaderID) Continue
		} Catch {}
		
		If tInboundAck {
			Set tCurrAckData = $lb(sourceClass, id, tInboundAck, body, tQueryIsDef)
		} Else {
			Set tCurrAckData = $lb(targetClass, $S(+$G(tCorrespondingMessageHeaderID):tCorrespondingMessageHeaderID_"*",1:id), tInboundAck, body, tQueryIsDef)
		}
		Set tAckData(tAckRS.TimeCreated,findACK("class"),tAckRS.ID) = tCurrAckData
	}
	Quit
}

ClassMethod GetColCount(currPage As %Integer = 1, ByRef classinfo As %String) As %Integer [ Internal ]
{
	#; count number of columns
	Set tPageNum = +currPage
	Set tColCount = 0
	For tLane = 0:1:4 {
		Set k = $order(classinfo(tLane,""))
		While (k '= "") {
			If $data(classinfo(tLane,k)) {
				Set tColCount = tColCount + 1
			}
			Set k = $order(classinfo(tLane,k))
		}
	}
	Quit tColCount
}

ClassMethod ClearTraceData()
{
	Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"VisualTrace")
}

ClassMethod CalculateDimensions(n As %String = "0", rows As %String = "0", cols As %String = "0", startN As %String = "", ByRef noHeight)
{
	Set width = ..#HOSTWIDTH*cols
	Set:width<300 width = 500
	Set msgPerPage = $select($IsObject($get(%request)): $get(%request.Data("MSGPERPAGE",1),..#MSGPERPAGE), 1: ..#MSGPERPAGE)
	Set lastEntry = startN + msgPerPage - 1
	If lastEntry > n {
		Set lastEntry = n
	}
	
	Set tMissing = 0
	Set k=""_startN
	For {
		Set k=$order(noHeight(k))
		Quit:(k = "")||(k > lastEntry)
		Set tMissing = tMissing + 1
	}
	Set visibleRows = lastEntry - startN - tMissing + 1
	Set height = (..#DELTAY * visibleRows) + ..#TOPY
	Set:height<200 height = 200
	
	Quit n_"#"_rows_"#"_cols_"#"_width_"#"_height
}

ClientMethod onSVGLoad() [ Language = javascript ]
{
	// replace context menu (adobe only)
	try {
		var newMenuRoot = parseXML(printNode(document.getElementById('CanvasMenu')), contextMenu);
		contextMenu.replaceChild( newMenuRoot, contextMenu.firstChild );
	}
	catch (ex) {
	}
	// Call parent zenPage's onSVGLoad method, if it exists. This is used by the Message Viewer
	// to resize the SVG diagram once it has been fully loaded.
	if (window.parent && window.parent.zenPage && window.parent.zenPage.onTraceSVGLoad) {
		window.parent.zenPage.onTraceSVGLoad();
	}

	return true;
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

ClientMethod getCurrentHeight() [ Language = javascript ]
{
	var height = null;
	var traceCanvas = document.getElementById('traceCanvas');
	if (traceCanvas && traceCanvas.attributes) {
		for (var i = 0; i < traceCanvas.attributes.length; i++) {
			var attr = traceCanvas.attributes.item(i);
			if (attr && (attr.name == 'height')) {
				height = attr.value;
				break;
			}
		}
	}
	return height;
}

ClientMethod getCurrentWidth() [ Language = javascript ]
{
	var width = null;
	var traceCanvas = document.getElementById('traceCanvas');
	if (traceCanvas && traceCanvas.attributes) {
		for (var i = 0; i < traceCanvas.attributes.length; i++) {
			var attr = traceCanvas.attributes.item(i);
			if (attr && (attr.name == 'width')) {
				width = attr.value;
				break;
			}
		}
	}
	return width;
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

/// Consolidated function to select a new item from the diagram (and unselect any previously selected items).
ClientMethod selectItem(evt, type, svgId, itemId, extraType, lineId) [ Language = javascript ]
{
	if (evt) {
		evt.stopPropagation();
	}
	if (this.noSelect) {
		if (((type == 'message') && (itemId != this.sessionId)) || (type != 'message')) {
			return;
		}
	}

	// unselect currently selected item
	// note: when previously selected type is 'canvas', this condition is not triggered
	if (zenPage.currentId && (zenPage.currentType != null) && (zenPage.currentSVGId != null)) {
		var selectedObj = document.getElementById(zenPage.currentSVGId);
		if (selectedObj) {
			switch (zenPage.currentType) {
				case 'rule':
				case 'event':
				case 'ioLog':
				case 'ack':
					selectedObj.setAttribute('class', selectedObj.getAttribute('class').split(' ')[0]);
					break;
				case 'message':
					selectedObj.setAttribute('class', 'MsgOutline');
					var lineObj = document.getElementById(zenPage.currentLine);
					if (lineObj) {
						lineObj.setAttribute('class','LinkLine');
					}
					break;
				case 'host':
					selectedObj.setAttribute('class','HostRect');
					var lineObj = document.getElementById(zenPage.currentLine);
					if (lineObj) {
						lineObj.setAttribute('class','HostLine');
					}
					break;
			}
		}
		
	}
	// The values should be null when type is 'canvas'
	zenPage.currentId = itemId;
	zenPage.currentSVGId = svgId;
	zenPage.currentType = type;
	zenPage.currentClass = extraType;
	zenPage.currentLine = lineId;
	
	if (type == 'canvas') {
		return;
	}
	var selectedObj = document.getElementById(svgId);
	if (selectedObj) {
		switch (type) {
			case 'event':
			case 'rule':
			case 'ioLog':
			case 'ack':
				selectedObj.setAttribute('class', selectedObj.getAttribute('class') + ' selected');
				break;
			case 'message':
				selectedObj.setAttribute('class', 'MsgOutlineSelect');
				// note that a "back" link to a line created earlier should still be passed in lineId
				var lineObj = document.getElementById(zenPage.currentLine);
				if (lineObj) {
					lineObj.setAttribute('class','LinkLineSelect');
				}
				break;
			case 'host':
				selectedObj.setAttribute('class','HostRectSelect');
				var lineObj = document.getElementById(zenPage.currentLine);
				if (lineObj) {
					lineObj.setAttribute('class','HostLineSelect');
				}
				break;
		}
	}
	// update content display
	if (zenPage && zenPage.updateTabs) {
		zenPage.updateTabs();
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
