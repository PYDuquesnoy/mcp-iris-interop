/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Displays a daily schedule for a given time period
/// as an HTML component. The schedule displays time slots
/// for one or more days. User-defined scheduled items are
/// placed on top of the appropriate time slots.<br/>
/// <h3>Controlling the Display of the Schedule</h3>
/// The <property>view</property> property controls what timespan
/// is displayed: day, week, or month.<br/>
/// The <property>date</property> controls what time period
/// is displayed. If a weekly <property>view</property> is used, then
/// the week containing <property>date</property> is displayed.<br/>
/// The <property>interval</property> property specifies the size of each time slot
/// in minutes.<br/> while the <property>cellHeight</property> property
/// specifies how tall each slot will be (in pixels).<br/>
/// The number of intervals displayed for each day is determined by the
/// <property>startTime</property> and <property>endTime</property> properties;
/// these provide the default starting and ending times for each day (in minutes from
/// midnight). If there are scheduled items outside this range, additional
/// slots are added to make the items visible.<br/>
/// When the user clicks on a cell, the <property>onselectitem</property>
/// event handler is invoked. This handler is passed 2 variables:
/// <var>id</var>-the user defined id value for a scheduled
/// item as provided by the <property>OnGetScheduleInfo</property> callback (or null for an empty cell);
/// and <var>time</var>-the time value
/// associated with the cell (in yyyy-mm-dd hh:mm:ss format).
/// <h3>Providing Data for the Schedule</h3>
/// The scheduled items are provided by the user-defined 
/// server-side callback method <property>OnGetScheduleInfo</property>.
/// This callback is passed an array of parameter values (from the 
/// <property>parameters</property> collection; the starting day value (as
/// $H format) and the ending day value (also as $H format). It returns
/// an array containing a list of items to display.<br/>
/// The array of scheduled items takes the form:
/// <pre>
/// pInfo(day,time,n) = $LB(duration,id,text,type,style)
/// </pre>
/// Where <var>day</var> is the day ($H) for the item;
/// <var>time</var> is the start time (in minutes from midnight)
/// for the item; <var>n</var> is a arbitrary number (typically 1)
/// used just in case there are two or more items with the same day and time
/// value. The data for each element contains 
/// <var>duration</var>, length of the item in minutes;
/// <var>id</var>, a logical id value associated with this item
/// (and passed on to the <property>onselectitem</property> event handler;
/// <var>text</var>, text to display within the item;
/// <var>type</var>, indicates the type of item: 0 is "unavailable"
/// time slot and 1 is a scheduled time slot;
/// <var>style</var> is option css style to apply to the time slot.<br/>
/// You can also provide day-wide styles by using the top-nodes of the
/// array:
/// <pre>
/// pInfo(day) = "css style for this day"
/// </pre>
/// <br/>
/// <br/>
/// For example:
/// <example language="CLS!MEMBER">
/// ClassMethod GetScheduleInfo(ByRef pParms As %String,pStartDate As %Date,pEndDate As %Date,ByRef pInfo As %List) As %Boolean
/// {
/// 	// Display a 1 hour staff meeting for the first
/// 	// day of this period.
/// 	Set pInfo(pStartDate,9*60,1) = $LB(60,1,"Staff Meeting",1,"background: green;")
/// 	Quit 1
/// }
/// </example>
Class %ZEN.ComponentEx.schedulePane Extends %ZEN.Component.component [ Deprecated, LegacyInstanceContext, System = 3 ]
{

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// If provided, this text is displayed as a caption
/// along the top of the schedule. The text is *not*
/// HTML escaped, so that it can contain markup.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// Specifies what type of schedule to display.
Property view As %ZEN.Datatype.string(MAXLEN = 20, VALUELIST = ",day,week,month", ZENEXPRESSION = 1) [ InitialExpression = "day" ];

/// Specifies the size (duration) of the calendar slots (in minutes).
Property interval As %ZEN.Datatype.integer(MINVAL = 5, ZENEXPRESSION = 1) [ InitialExpression = 30 ];

/// Start time of the current selected cell(s).
Property selectedTime As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0);

/// Length (in minutes) of the current selected cell(s).
Property selectedInterval As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0);

/// List of localized day names.
Property dayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// List of localized short day names.
Property shortDayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// List of localized month names.
Property monthList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// List of localized short month names.
Property shortMonthList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Specified which day of the week (Sunday=0, Saturday = 6) is displayed as
/// the starting day of the week.<br/>
/// This allows for customizing for locales in which weeks start with
/// other days of the week.
Property firstDayOfWeek As %ZEN.Datatype.integer(MAXVAL = 6, MINVAL = 0) [ InitialExpression = 0 ];

/// Date format used for sub-caption. Refer to the
/// $ZDT function for details.
Property dateFormat As %ZEN.Datatype.integer(MAXVAL = 17, MINVAL = -1) [ InitialExpression = -1 ];

/// Date to display (in YYYY-MM-DD format).<br/>
/// If not specified, the current day is used.<br/>
/// The schedule will display a range of days that contain
/// this date value. The range of values depends on the current
/// value of the <property>view</property> property.
Property date As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Starting time (in minutes from midnight) to show for the daily
/// calendar.
Property startTime As %ZEN.Datatype.integer(MAXVAL = 1440, MINVAL = 0, ZENEXPRESSION = 1) [ InitialExpression = 480 ];

/// Ending time (in minutes from midnight) to show for the daily
/// calendar.
Property endTime As %ZEN.Datatype.integer(MAXVAL = 1440, MINVAL = 0, ZENEXPRESSION = 1) [ InitialExpression = 1080 ];

/// Height of header cells.
Property headerHeight As %ZEN.Datatype.length(ZENEXPRESSION = 1) [ InitialExpression = 40 ];

/// Height of time slot cell.
Property cellHeight As %ZEN.Datatype.length(ZENEXPRESSION = 1) [ InitialExpression = 30 ];

/// User-defined set of parameters. These are passed
/// along to the <property>OnGetScheduleInfo</property>
/// callback method.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// onselectitem event handler:
/// If defined, this event is fired when the user clicks on an item within the schedule.
Property onselectitem As %ZEN.Datatype.eventHandler;

/// onchangeview event handler:
/// If defined, this event is fired when the user changes the view mode of the schedule (such as from month to day view).
Property onchangeview As %ZEN.Datatype.eventHandler;

/// Name of Server-side callback method to call to get information
/// used to display the schedule.<br/>
/// This must be the name of a server-only method in the page
/// class that contains this component.
Property OnGetScheduleInfo As %ZEN.Datatype.delegator(FORMALSPEC = "&pParms:%String,pStartDate:%Date,pEndDate:%Date,&pInfo:%List", RETURNTYPE = "%Boolean");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Table used to layout the schedule." */
.schedulePaneTable {
	font-family: lucida sans unicode;
	border: 1px solid black;
	width: 100%;
	table-layout: fixed;
}

/* @doc="Header for a day within the schedule." */
.schedulePaneDayHeader {
	font-weight: bold;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding: 2px;
	text-align: left;
	overflow: hidden;
}

/* @doc="Header for the schedule." */
.schedulePaneHeader {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	padding: 2px;
	text-align: left;
	overflow: hidden;
	border-top: 1px solid black;
	border-left: 1px solid black;
	border-right: 1px solid black;
}

.schedulePaneHeader table {
	width: 100%;
	padding: 2px;
	font-weight: bold;
	font-size: 1.4em;
}

.schedulePaneDaySubHeader {
	font-weight: normal;
	font-size: 0.8em;
}

.schedulePaneDayBody {
	position: relative;
}

.schedulePaneTable td {
}

.scheduleMonthCell {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	text-align: right;
	vertical-align: top;
	position: relative;
}

.scheduleMonthCellHi {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	text-align: right;
	vertical-align: top;
	background: yellow;
	position: relative;
}

/* day from other than the current month */
.scheduleMonthCellGray {
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	text-align: right;
	vertical-align: top;
	color: #606060;
	background: #D0D0D0;
	position: relative;
}

.scheduleMonthItems {
	padding: 2px;
	text-align: left;
	font-size: 0.8em;
	font-weight: normal;
	overflow: hidden;
	position: absolute;
}

.scheduleMonthCellHi .scheduleMonthItems {
	overflow-y: auto;
}

.scheduleSlot,.scheduleSlotHi {
	font-size: 7pt;
	width: 100%;
	position: absolute;
	border-bottom: 1px dotted black;
	border-right: 1px solid black;
}

/* @doc="Highlighted empty cell." */
.scheduleSlotHi {
	border: 1px solid black;
	background: yellow;
}

/* @doc="Highlighted cell." */
.scheduleSlotBookedHi,.scheduleSlotUnavailableHi {
	border: 2px solid black;
	background: yellow;
}

/* @doc="Description for a schedule cell." */
.scheduleSlotCaption {
	font-size: 8pt;
	text-align: center;
	vertical-align: middle;
	border: none;
}

.scheduleSlotTime {
	font-size: 7pt;
	text-align: left;
	vertical-align: top;
	border: none;
}

/* @doc="Div for a schedule cell." */
.scheduleSlotBooked,.scheduleSlotUnavailable,
.scheduleSlotBookedHi,.scheduleSlotUnavailableHi  {
	position: absolute;
	font-size: 9pt;
	text-align: center;
	overflow: hidden;
}

.scheduleSlotBooked {
	border: 1px solid black;
	background: #FFEEAA;
}

.scheduleSlotUnavailable {
	color: #404040;
	background: #D0D0D0;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
}

/* @doc="Buttons within header." */
.scheduleBtn {
	width: 100%;
	font-size: 12pt;
}

</style>
}

/// Draw the contents of this component.
Method %DrawHTML()
{
	Set tStartDate = $$$ZENVAL(..date)
	If (tStartDate = "") {
		// default is today
		Set tStartDate = +$H
	}
	Else {
		// convert to $H
		Set tStartDate = +$ZDTH(tStartDate,3)
	}
	If (..view = "day") {
		Set tEndDate = tStartDate
	}
	ElseIf(..view = "month") {
		Set tStartDate = ..%GetMonthRange(tStartDate,.tEndDate,..firstDayOfWeek)
	}
	Else {
		// 1 week
		Set tStartDate = ..%GetStartOfWeek(tStartDate,..firstDayOfWeek)
		Set tEndDate = tStartDate + 6
	}

	Do ..%DrawHeader()

	Set tDays = tEndDate - tStartDate + 1
	Set tCellWidth = $J((1/tDays)*100,0,3)_"%"  // as percentage

	// Get schedule info
	Set tSC = ..%GetScheduleInfo(tStartDate,tEndDate, .tInfo)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		Quit
	}

	// per-diem info
	Set tStartTime = $$$ZENVAL(..startTime)+0
	Set tEndTime = $$$ZENVAL(..endTime)+0
	Set tInterval = $$$ZENVAL(..interval)+0
	Set tHeaderHeight = $$$ZENVAL(..headerHeight)+0
	Set tCellHeight = $$$ZENVAL(..cellHeight)+0

	&html<<table class="schedulePaneTable" border="0" cellspacing="0" cellpadding="0">>

	// test for month mode
	If (..view = "month") {
		Do ..%DrawMonthView(.tInfo,tStartDate,tEndDate)
	}
	Else {
		// Look at info returned from user
		// move into tBookings
		// adjust start/end time if there are bookings out of range
		For d = tStartDate:1:tEndDate {
			Set tInfoTime = $O(tInfo(d,""))
			While (tInfoTime '= "") {
				If (tInfoTime < tStartTime) {
					Set tStartTime = tInfoTime
				}
				Set n = $O(tInfo(d,tInfoTime,""))
				While (n '= "") {
					Set tDuration = $LG(tInfo(d,tInfoTime,n),1)
					If ((tInfoTime+tDuration) > tEndTime) {
						Set tEndTime = tInfoTime+tDuration
					}
					Set tBookings(d,$I(tBookings)) = $LB(tInfoTime) _ $G(tInfo(d,tInfoTime,n))
					Set n = $O(tInfo(d,tInfoTime,n))
				}
				Set tInfoTime = $O(tInfo(d,tInfoTime))
			}
		}

		// round off start/end times to interval
		// slots & pixels/minute
		Set tSlots = (((tEndTime-tStartTime)/tInterval)+0.5)\1
		Set tPPM = (tCellHeight*tSlots)/(tEndTime-tStartTime)
		
		// Localization
		Set tMonthList = $S(..monthList'="":..monthList, 1:$$$Text("January,February,March,April,May,June,July,August,September,October,November,December"))
		Set tMonthList = " "_$Replace(tMonthList,","," ") //$ZDT doesn't like commas
		Set tDayList = $S(..dayList'="":..dayList, 1:$$$Text("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday"))
		
		&html<<tr>>
		For d = tStartDate:1:tEndDate {
			// Get localized display values for headers
			Set tDay = $P(tDayList,",",$ZDT(d,10)+1)
			Set tDate = $ZDT(d,..dateFormat,,,tMonthList) // format

			Set tDayStyle = $G(tInfo(d))
			Set tDateStyle = $S(d=+$H:"style=""font-weight: bold;""",1:"")

			&html<<td width="#(tCellWidth)#" valign="top" height="#(tHeaderHeight + (tCellHeight*tSlots))#px">>
			&html<<div class="schedulePaneDayHeader" style="height:#(tHeaderHeight)#px;"><div>#(tDay)#</div><div class="schedulePaneDaySubHeader" #(tDateStyle)#>#(tDate)#</div></div>>
			&html<<div class="schedulePaneDayBody" style="height:#(tCellHeight*tSlots)#px;#(tDayStyle)#">>

			// first draw time cells
			Set y = 0
			Set tTimeSlot = tStartTime
			While (tTimeSlot < tEndTime) {
				Set tLength = 1
				Set hgt = tCellHeight*tLength
				Set tTimeVal = $ZDT(d_","_(tTimeSlot*60),3)
				Set cid = d_":"_(1000+$I(tCellId))
				&html<<div id="#(..%MakeId(cid))#" zenTime="#(tTimeVal)#" style="top:#(y)#px;height:#(hgt)#px;" class="scheduleSlot" onclick="zenPage.getComponent(#(..index)#).mouseClickHandler(event,-1,'#(tTimeVal)#','#(cid)#',null,#(tInterval)#);" onmousedown="return zenPage.getComponent(#(..index)#).mouseDownHandler(event);">#(..%FormatTime(tTimeSlot))#</div>>
				Set tTimeSlot = tTimeSlot + (tInterval * tLength)
				Set y = y + hgt
			}

			// show bookings overlaid on grid
			Set tBookedTill = ""
			Set b = $O(tBookings(d,""))
			While (b '= "") {
				Set tTime = $LG(tBookings(d,b),1)
				Set tDuration = $LG(tBookings(d,b),2)
				Set tID = $LG(tBookings(d,b),3)
				Set tCaption = $LG(tBookings(d,b),4,tID)
				Set tType = $LG(tBookings(d,b),5,1)
				Set tStyle = $LG(tBookings(d,b),6)
				Set tCellClass = $Case(tType,0:"Unavailable",:"Booked")

				// conflict detection
				If ((tBookedTill = "")||(tTime>=tBookedTill)) {
					Set tConflict = 0
					Set tBookedTill = tTime + tDuration
				}
				Else  {
					Set tConflict = tConflict + 1
					If (tBookedTill < (tTime + tDuration)) {
						Set tBookedTill = tTime + tDuration
					}
				}

				Set y = (tTime - tStartTime) * tPPM
				Set hgt = (tDuration * tPPM) - 1
				Set w = $S(tConflict:(9-tConflict)*10_"%",1:"98%")
				Set tTimeVal = $ZDT(d_","_(tTime*60),3)
				Set cid = "u"_$I(tCellId)
				&html<<div id="#(..%MakeId(cid))#" class="scheduleSlot#(tCellClass)#" style="top:#(y)#px;height:#(hgt)#px;width:#(w)#;#(tStyle)#" onclick="zenPage.getComponent(#(..index)#).mouseClickHandler(event,#(tType)#,'#(tTimeVal)#','#(cid)#','#(tID)#',#(tDuration)#);" onmousedown="return zenPage.getComponent(#(..index)#).mouseDownHandler(event);">>
				Set tTimeCaption = ..%FormatTime(tTime)
				Set tTip = tTimeCaption_"-"_..%FormatTime(tTime+tDuration)_": "_tCaption

				// contents of cell
				&html<<table border="0" cellpadding="0" cellspacing="0" width="100%" height="100%">>
				&html<<tr height="1%"><th width="100%" class="scheduleSlotTime">#(tTimeCaption)#</th></tr>>
				&html<<tr height="100%"><td title="#(tTip)#" width="100%" class="scheduleSlotCaption">#($ZCVT(tCaption,"O","HTML"))#</td></tr>>
				&html<</table>>
				&html<</div>>
				Set b = $O(tBookings(d,b))
			}
			&html<</div>>
			&html<</td>>
		}
		&html<</tr>>
	}
	&html<</table>>
	Quit
}

/// Draw the header for the schedule.
Method %DrawHeader()
{
	Set msgDay = $$$Text("Day","%ZEN")
	Set msgWeek = $$$Text("Week","%ZEN")
	Set msgMonth = $$$Text("Month","%ZEN")
	Set tCaption = ..caption
	&html<<div class="schedulePaneHeader" id="#(..%MakeId("header"))#">>
	&html<<table border="0" cellpadding="0" cellspacing="0"><tr>>
	&html<<th style="text-align:left;">&nbsp;<span id="#(..%MakeId("caption"))#">#(tCaption)#</span>&nbsp;</th>>
	&html<
		<td style="width:1.5em;text-align:center;"><input type="button" class="scheduleBtn" value="&laquo;" onclick="zenPage.getComponent(#(..index)#).previousPeriod();"/></td>
		<td style="width:4.0em;text-align:center;"><input type="button" class="scheduleBtn" #($S(..view="day":"style=""font-weight:bold;""",1:""))# value="#(msgDay)#" onclick="zenPage.getComponent(#(..index)#).setView('day');"/></td>
		<td style="width:4.0em;text-align:center;"><input type="button" class="scheduleBtn" #($S(..view="week":"style=""font-weight:bold;""",1:""))# value="#(msgWeek)#" onclick="zenPage.getComponent(#(..index)#).setView('week');"/></td>
		<td style="width:4.0em;text-align:center;"><input type="button" class="scheduleBtn" #($S(..view="month":"style=""font-weight:bold;""",1:""))# value="#(msgMonth)#" onclick="zenPage.getComponent(#(..index)#).setView('month');"/></td>
		<td style="width:1.5em;text-align:center;"><input type="button" class="scheduleBtn" value="&raquo;" onclick="zenPage.getComponent(#(..index)#).nextPeriod();"/></td>
	>
	&html<</tr></table></div>>
}

/// Draw the month view for the schedule.
Method %DrawMonthView(ByRef pInfo, pStartDate As %Date, pEndDate As %Date)
{
	Set tCellWidth = "14.28%"
	Set tHeaderHeight = ($$$ZENVAL(..headerHeight)+0) / 2
	Set tCellHeight = ($$$ZENVAL(..cellHeight)+0) * 3
	
	// Localization
	Set tDayList = $S(..dayList'="":..dayList,1:$$$Text("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday"))
	Set tMonthList = $S(..monthList'="":..monthList,1:$$$Text("January,February,March,April,May,June,July,August,September,October,November,December"))
	
	Set tDate = $$$ZENVAL(..date)
	If (tDate = "") {
		Set tDate = $E($ZDT(+$H,3),1,10)
	}
	Set tYear = +$E(tDate,1,4)
	Set tMonth = +$E(tDate,6,7)
	Set tLabel = $P(tMonthList,",",tMonth) _ " " _ tYear

	// Look at info returned from user
	// move into tBookings, sorted by day
	For d = +pStartDate:1:+pEndDate {
		Set tInfoTime = $O(pInfo(d,""))
		While (tInfoTime '= "") {
			Set n = $O(pInfo(d,tInfoTime,""))
			While (n '= "") {
				Set tDuration = $LG(pInfo(d,tInfoTime,n),1)
				Set tBookings(d,$I(tBookings)) = $LB(tInfoTime) _ $G(pInfo(d,tInfoTime,n))
				Set n = $O(pInfo(d,tInfoTime,n))
			}
			Set tInfoTime = $O(pInfo(d,tInfoTime))
		}
	}
	
	&html<<tr>>
	&html<<td colspan="7" valign="top">>
	&html<<div class="schedulePaneDayHeader" style="text-align:center; vertical-align:middle; height:#(tHeaderHeight)#px;">#(tLabel)#</div>>
	&html<</td>>
	&html<</tr>>

	&html<<tr>>
	For c = 1:1:7 {
		Set n = (c + ..firstDayOfWeek) # 7
		Set:n=0 n = 7 
		Set tDay = $P(tDayList,",",n)
		&html<<td style="width:#(tCellWidth)#;vertical-align:top;">>
		&html<<div class="schedulePaneDayHeader" style="text-align:center; vertical-align:middle; height:#(tHeaderHeight)#px;">#(tDay)#</div>>
		&html<</td>>
	}
	&html<</tr>>

	Set tDay = +pStartDate
	For r = 1:1:6 {
		&html<<tr>>
		For c = 1:1:7 {
			Set d = $ZDT(tDay,3)
			Set tMonthNumber = +$E(d,6,7)
			Set tDayNumber = +$E(d,9,10)
			Set cls = $S(tMonthNumber=tMonth:"scheduleMonthCell",1:"scheduleMonthCellGray")
			Set tDateStyle = $S(+tDay=+$H:"font-weight: bold;",1:"")
			Set cid = tDay
			Set tTimeVal = d
			&html<<td id="#(..%MakeId(cid))#" class="#(cls)#" style="#(tDateStyle)#;width:#(tCellWidth)#;vertical-align:top;height:#(tCellHeight)#px;" onclick="zenPage.getComponent(#(..index)#).mouseClickHandler(event,-1,'#(tTimeVal)#','#(cid)#',null,null);" onmousedown="return zenPage.getComponent(#(..index)#).mouseDownHandler(event);">>

		
			If ($D(tBookings(tDay))) {
				// show bookings for this day (!!! width)
				&html<<div class="scheduleMonthItems" style="width:100px;vertical-align:top;height:#(tCellHeight-10)#px;">>
				Set n = $O(tBookings(tDay,""))
				While (n '= "") {
					Set tText = $LG(tBookings(tDay,n),4)
					&html<<div>#($ZCVT(tText,"O","HTML"))#</div>>
					Set n = $O(tBookings(tDay,n))
				}
				&html<</div>>
			}
						
			Write tDayNumber,"&nbsp;"			
			&html<</td>>
			
			Set tDay = tDay + 1
		}
		&html<</tr>>
		If (tDay > pEndDate) Quit
	}
}

/// Given a date (as a $H value), return the
/// date (as a $H value) of the start of the week the date is in.<br/>
/// <var>pStartOfWeek</var> indicates which is the starting day of the week (Sunday=0, Saturday = 6).
ClassMethod %GetStartOfWeek(pDate As %Date, pStartOfWeek As %Integer = 0) As %Date
{
	Set pDate = +pDate
	Set tWeekDay = +$ZDT(pDate,10)
	Set tStart = pDate - tWeekDay + pStartOfWeek
	Set:tStart>pDate tStart = tStart - 7
	Quit tStart
}

/// Given a date (as a $H value), return the
/// date (as a $H value) of the first and last dates to display for the month the date is in.<br/>
ClassMethod %GetMonthRange(pDate As %Date, Output pEndDate, pStartOfWeek As %Integer = 0) As %Date
{
	Set pDate = +pDate
	Set tStart = $ZDT(pDate,3)
	Set $E(tStart,9,10) = "01"
	Set tYear = +$E(tStart,1,4)
	Set tMonth = +$E(tStart,6,7)

	// find day of week of first day of month;
	// find first date *before* this that is a start of a week
	Set tWeekDay = +$ZDT(+$ZDTH(tStart,3),10)
	Set tOffset = (tWeekDay - pStartOfWeek) # 7
	Set tStartDate = +$ZDTH(tStart,3) - tOffset

	// find last day to display
	Set tLastDay = +$ZDTH(tStart,3) + ..%DaysInMonth(tYear,tMonth)
	Set tWeekDay = +$ZDT(tLastDay,10)
	Set tOffset = (pStartOfWeek - tWeekDay) # 7
	Set pEndDate = tLastDay + tOffset - 1

	Quit tStartDate
}

/// Return number of days in the given year and month.
ClassMethod %DaysInMonth(y, m) As %Integer
{
	Quit $Case(m,1:31,2:$S(..%IsLeapYear(y):29,1:28),3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31,:0)
}

/// Return whether the given year is a leap year.
ClassMethod %IsLeapYear(y) As %Boolean
{
	If ((y#4) = 0) {
		If '(((y#100) = 0) && ((y#400) '= 0)) {
			Quit 1
		}
	}
	Quit 0
}

/// Take a time value (number of minutes from midnight) and return 
/// a formatted display value.
ClassMethod %FormatTime(pTime As %Integer) As %String
{
	Set tHour = pTime \ 60
	Set tMinute = pTime # 60
	If (tHour = 0) {
		Set tHour = 12
		Set tPost = "am"
	}
	ElseIf (tHour = 12) {
		Set tPost = "pm"
	}
	ElseIf (tHour>12) {
		Set tPost = "pm"
		Set tHour = tHour - 12
	}
	Else {
		Set tPost = "am"
	}
	Quit $Replace($J(tHour,2)," ","&nbsp;")_":"_$TR($J(tMinute,2)," ","0")_tPost
}

/// Get an array (<var>pInfo</var>) containing info used to show the schedule.<br/>
/// This array is subscripted by item number.
Method %GetScheduleInfo(pStartDate As %Date, pEndDate As %Date, ByRef pInfo As %String) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetScheduleInfo '= "")) {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParameters(key) = value
			Set key = ..parameters.Next(key)
		}
		Set tSC = $zobjmethod(tHost,..OnGetScheduleInfo,.tParameters,pStartDate,pEndDate,.pInfo)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Grab mouse down to prevent text selection.
ClientMethod mouseDownHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}
	evt.cancelBubble = true;
	return false;
}

/// Mouse click handler<br/>
/// <var>type</var> can be: -1 for unassigned slot, 0 for unavailable, 1 for booked item.<br/>
/// <var>cellId</var> is HTML id of the item<br/>
/// <var>itemId</var> is the user provided id of the item.<br/>
ClientMethod mouseClickHandler(evt, type, time, cellId, userId, duration) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var multi = evt.ctrlKey && userId == null;
	this.selectedInterval = duration;
	this.selectItem(cellId, multi, time);
	zenInvokeCallbackMethod(this.onselectitem,this,'onselectitem','id',userId,'time',this.selectedTime);
	return true;
}

ClientMethod selectItem(id, multi, time) [ Internal, Language = javascript ]
{
	if (this._selectedItems) {
		// test if multi is allowed
		if ('month' != this.view) {
			if (this._selectedItems[0]) {
				if (this._selectedItems[0].toString().charAt(0)=='u' || id.toString().charAt(0)=='u') {
					multi = false;
				}
				else {
					var idDay = id.split(':')[0];
					var sDay = this._selectedItems[0].toString().split(':')[0];
					if (sDay != idDay) {
						multi = false;
					}
				}
			}
		}
		if (!multi) {
			for (var n = 0; n < this._selectedItems.length; n++) {
				var div = this.findElement(this._selectedItems[n]);
				if (div && div._oldClass) {
					div.className = div._oldClass;
				}
			}
			delete this._selectedItems;
		}
	}

	if (id) {
		if (!this._selectedItems) {
			this._selectedItems = new Array();
		}
		this._selectedItems[this._selectedItems.length] = id;

		if (multi && this._selectedItems.length > 1) {
			this.selectedTime = (this.selectedTime == 0 || time < this.selectedTime) ? time : this.selectedTime;

			// select all items in range
			this._selectedItems.sort();

			var sDay,start,end;
			if ('month' == this.view) {
				sDay = this._selectedItems[0];
				start = this._selectedItems[0];
				end = this._selectedItems[this._selectedItems.length-1];
			}
			else {
				sDay = this._selectedItems[0].toString().split(':')[0];
				start = this._selectedItems[0].toString().split(':')[1];
				end = this._selectedItems[this._selectedItems.length-1].toString().split(':')[1];
			}
			var newList = new Array();

			for (var n = start; n <= end; n++) {
				var nid = ('month' == this.view) ? n : (sDay+":"+n);
				newList[newList.length] = nid;
				var div = this.findElement(nid);
				if (div) {
					switch (div.className) {
					case 'scheduleSlot':
						div._oldClass = div.className;
						div.className = 'scheduleSlotHi';
						break;
					case 'scheduleSlotBooked':
						div._oldClass = div.className;
						div.className = 'scheduleSlotBookedHi';
						break;
					case 'scheduleSlotUnavailable':
						div._oldClass = div.className;
						div.className = 'scheduleSlotUnavailableHi';
						break;
					case 'scheduleMonthCell':
					case 'scheduleMonthCellGray':
						div._oldClass = div.className;
						div.className = 'scheduleMonthCellHi';
						break;
					}
				}
			}
			this._selectedItems = newList;
			this.selectedInterval = this._selectedItems.length * parseInt(this.interval);
		}
		else {
			this.selectedTime = time;
			var div = this.findElement(id);
			if (div) {
				switch (div.className) {
				case 'scheduleSlot':
					div._oldClass = div.className;
					div.className = 'scheduleSlotHi';
					break;
				case 'scheduleSlotBooked':
					div._oldClass = div.className;
					div.className = 'scheduleSlotBookedHi';
					break;
				case 'scheduleSlotUnavailable':
					div._oldClass = div.className;
					div.className = 'scheduleSlotUnavailableHi';
					break;
				case 'scheduleMonthCell':
				case 'scheduleMonthCellGray':
					div._oldClass = div.className;
					div.className = 'scheduleMonthCellHi';
					break;
				}
			}
		}
	}
	else {
		this.selectedTime = 0;
		this.selectedInterval = 0;
	}
}

/// Display the next time period.
ClientMethod nextPeriod() [ Language = javascript ]
{
	var delta;
	switch (this.view) {
	case 'week':
	case '':
		delta = 7;
		break;
	case 'month':
		delta = 28;
		break;
	default:
		delta = 1;
		break;
	}
	this.moveToNewDay(delta);
}

/// Display the previous time period.
ClientMethod previousPeriod() [ Language = javascript ]
{
	var delta;
	switch (this.view) {
	case 'week':
	case '':
		delta = -7;
		break;
	case 'month':
		delta = -28;
		break;
	default:
		delta = -1;
		break;
	}
	this.moveToNewDay(delta);
}

/// Move ahead or back the given number of days.
ClientMethod moveToNewDay(delta) [ Language = javascript ]
{
	var curr;	
	if ('' == this.date) {
		curr = new Date();
	}
	else {
		curr = zenStringToDate(this.date);
	}	
	var newDate = curr;
	// there are some months with more than 28 days, so we need ot handle months diffs seperately 
	if (delta==28||delta==-28){		
		newDate.setMonth(curr.getMonth()+(delta/28));
	} else {
		newDate.setTime(parseInt(curr.getTime()) + (86400*1000*delta));
	}
	this.date = zenDateToString(newDate);	
	this.refreshContents();
}

/// Set the <property>view</property> mode of this control.
ClientMethod setView(view) [ Language = javascript ]
{
	if (view != this.view) {
		this.setProperty('view',view);
		zenInvokeCallbackMethod(this.onchangeview,this,'onchangeview');
	}
}

/// Set the <property>date</property> mode of this control.
ClientMethod setDate(date) [ Language = javascript ]
{
	this.setProperty('date',date);
}

/// Set the <property>interval</property> property of this control.
ClientMethod setInterval(interval) [ Language = javascript ]
{
	this.setProperty('interval',interval);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'date':
		if (this.date != value) {
			this.date = value;
			this.refreshContents();
		}
		break;
	case 'view':
		if (this.view != value) {
			this.view = value;
			this.refreshContents();
		}
		break;
	case 'interval':
		if (this.interval != value) {
			this.interval = value;
			this.refreshContents();
		}
		break;
	case 'caption':
		this.caption = value;
		var el = this.findElement('caption');
		if (el) {
			el.innerHTML = this.caption;
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This client callback is called just from refreshContents
/// just after the new HTML is delivered from the server.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	delete this._selectedItems;
	this.selectedTime = 0;
	this.selectedInterval = 0;
}

/// Return information about the most recent
/// data drop. This is intended to be called from
/// a ondrop handler.<br/>
/// It returns the time slot where the data was dropped in
/// yyyy-mm-dd hh:mm:ss format or '' if data was not dropped
/// on a valid slot.
ClientMethod getDropTimeSlot() [ Language = javascript ]
{
	// find slot that has been dragged on
	var tgtId = ZLM.getDragInnerDestination().id;
	var tgtIndex = -1;
	var tgtType = '';
	if (tgtId) {
		var div = self.document.getElementById(tgtId);
		if (div && div.getAttribute('zenTime')) {
			return div.getAttribute('zenTime');
		}
	}
	return '';
}

}
