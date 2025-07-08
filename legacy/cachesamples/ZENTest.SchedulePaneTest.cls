/// 
/// Test page for Zen SchedulePane component.<br/>
/// 
/// This page used the <class>ZENTest.ScheduleData</class> class to store
/// 
/// appointments entered via the schedule pane.
Class ZENTest.SchedulePaneTest Extends %ZEN.Component.page
{

/// 
/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Schedule Pane Test";

Parameter DOMAIN = "ZENTEST";

XData Style
{

<style type="text/css">



body {

	font-family: lucida sans unicode;

}



#leftGroup {

	padding-left: 10px;

	padding-right: 10px;

	background: #AAAADD;

	border: 1px solid darkgray;

}



#schedule {

	width: 800px;

	background: white;

	border: 1px solid #4040C0;

}



</style>
}

/// 
/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{

<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" 

dragAndDrop="true"

title="Zen Schedule Pane Test">

<demo:demoTitle id="title" title="Zen Schedule Pane Test Page" category="Zen Test Suite"/>



<locatorBar id="locator">

<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>

<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>

<locatorLink caption="Schedule Pane" title="Schedule Pane Test Page" />

</locatorBar>



<spacer height="10"/>



<hgroup cellVAlign="top">

<vgroup cellAlign="left" id="leftGroup">

<calendar onchange="zenPage.selectDate(zenThis.getValue());"/>

<spacer height="10"/>

<hgroup>

<select label="Display" value="day"

	title="Select the display format for the Schedule Pane."

	showEmpty="false"

	onchange="zenPage.setScheduleView(zenThis.getValue());"

	displayList="Day,Week,Month"

	valueList="day,week,month"

/>

<spacer width="10"/>

<select label="Interval" value="30"

	title="Select the time interval to show for day view within the Schedule Pane."

	showEmpty="false"

	onchange="zenPage.setScheduleInterval(zenThis.getValue());"

	displayList="5m,15m,30m,60m"

	valueList="5,15,30,60"

/>

</hgroup>

<spacer height="10"/>

<dataController id="dataController" modelClass="ZENTest.ScheduleData"/>

<form id="theForm" controllerId="dataController">

<select label="Person" value="Bob"

	title="Select the person whose schedule you wish to see."

	id="ctrlPerson"

	showEmpty="false"

	dataBinding="Person"

	onchange="zenPage.setPerson(zenThis.getValue());"

	valueList="Bob,Fred,Sally,Zelda"

/>

<text label="Reason" title="The reason for the scheduled item."

	id="ctrlReason" dataBinding="Reason"/>

<text label="Time" id="ctrlTime" 

	title="Start time for the scheduled item."

	dataBinding="StartTime"/>

<select label="Duration" value="30"

	title="Select the duration of the scheduled item."

	id="ctrlDuration"

	dataBinding="Duration"

	showEmpty="false"

	displayList="5m,15m,30m,45m,1h,1h 30m,2h,2h 30m,3h,3h 30m,4h,4h 30m,5h"

	valueList="5,15,30,45,60,90,120,150,180,210,240,270,300"

/>

<select label="Priority" value="Normal"

	title="Priority of the scheduled item."

	id="ctrlPriority"

	dataBinding="Priority"

	valueList="Low,Normal,High"

/>

<textarea label="Notes" id="ctrlNotes" 

	title="Notes related to the scheduled item."

dataBinding="Notes"/>

<hgroup>

<button caption="Save" 

	title="Save the current scheduled item."

	onclick="zenPage.saveItem();"/>

<spacer width="10"/>

<button caption="Delete"

title="Delete the current scheduled item."

 onclick="zenPage.deleteItem();"/>

</hgroup>

</form>

</vgroup>

<spacer width="10"/>

<schedulePane id="schedule"

caption="Schedule for Bob"

dateFormat="5"

interval="30"

startTime="540"

endTime="1020"

 dropEnabled="true"

 ondrop="zenPage.scheduleDataDrop(dragData);"

onselectitem="zenPage.selectItem(id,time);"

 OnGetScheduleInfo="GetScheduleInfo">

 <parameter id="parmPerson" paramName="Person" value="Bob"/>

 </schedulePane>

 <spacer width="10"/>

 <vgroup>

 <titleBox title="Meeting Templates" 

 subtitle="Drag an item and drop it onto the Schedule Pane."/>

 <listBox dragEnabled="true">

 <option text="Massage" value="Massage:60"/>

 <option text="Pedicure" value="Pedicure:30"/>

 <option text="Mud Bath" value="Mud Bath:90"/>

 <option text="Staff Meeting" value="Staff Meeting:60"/>

 </listBox>

 </vgroup>

</hgroup>



</page>
}

/// 
/// GetScheduleInfo callback for the Schedule Pange.<br/>
/// 
/// This method returns the set of scheduled items
/// 
/// that should be displayed on the schedulePane.
ClassMethod GetScheduleInfo(ByRef pParms As %String, pStartDate As %Date, pEndDate As %Date, ByRef pInfo As %List) As %Boolean
{

	// pParms is an array of parameter values associated with the schedule pane

	// pStartDate and pEndDate are the start and ending date values (in $H format)

	// that the schedule pane is interested in.

	// this method should find all appointments within the given time range

	// and return these in a list ordered by date and time:

	// pInfo(day,minute,n) =  $LB(Duration,ID,Reason,Type,Style)

	// where 'day' is the day number in $H format

	// 'minute' is the minute for the start time for the appointment

	// 'Duration' is duration in minutes of the appointment

	// 'ID' is the ID of the object representing the appointment

	// (in this case an instance of ZENTest.ScheduleData)

	// 'Reason' is the text to display for the appointment.

	// 'Type' is 1 for appointments, 0 for 'unavailable' time slots.

	// 'Style' is an optional css style string to apply to the appointment.

	// 

	// pInfo(day) contains css style for the entire day.

	

	// pParms("Person") should contain name of person

	Set tName = $G(pParms("Person"))

	Set (tID,tStartTime,tDuration,tReason,tPriority) = ""



	// Return an array of the form:

	// pInfo(day,time,n) = $LB(duration,value[,text,type,[,style]])

	// type=0--unavailable,1=booked



	// day-style (gray out weekends)

	// loop over days in range; if Sunday or Saturday

	// set day-wide style.

	For d = pStartDate:1:pEndDate {

		Set tWeekDay = +$ZDT(d,10)

		If ((tWeekDay = 0)||(tWeekDay = 6)) {

			Set pInfo(d) = "background: #C0C0F0;"

		}

	}



	// lookup scheduled items from table

	Set SQLCODE = 0

	Set t1 = $ZDT(pStartDate,3)

	Set t2 = $ZDT(pEndDate+1,3)

	&sql(DECLARE sql1 CURSOR FOR

		SELECT ID,StartTime,Duration,Reason,Priority

		INTO :tID,:tStartTime,:tDuration,:tReason,:tPriority

		FROM ZENTest.ScheduleData

		WHERE Person = :tName AND

		StartTime >= :t1 AND StartTime < :t2

	)

	&sql(OPEN sql1)

	&sql(FETCH sql1)

	While (SQLCODE = 0) {

		Set d = $ZDTH(tStartTime,3)

		Set tDate = +d

		Set tTime = $P(d,",",2)\60

		Set tStyle = $Case(tPriority,"High":"background:red;","Low":"background:#A0A0FF;",:"")

		Set pInfo(tDate,tTime,1) = $LB(tDuration,tID,tReason,1,tStyle)

		&sql(FETCH sql1)

	}

	&sql(CLOSE sql1)

	Quit 1
}

/// 
/// Save the current appointment information.
ClientMethod saveItem() [ Language = javascript ]
{

	zenPage.getComponentById('theForm').save();

	var schedule = zenPage.getComponentById('schedule');

	schedule.refreshContents();
}

/// 
/// Delete the current appointment.
ClientMethod deleteItem() [ Language = javascript ]
{

	var controller = zenPage.getComponentById('dataController');

	var id = controller.getModelId();

	if ('' != id) { 

		controller.deleteId(id);

		controller.setModelId('');

		var schedule = zenPage.getComponentById('schedule');

		schedule.refreshContents();

	}
}

/// 
/// View the schedule for the person <var>name</var>.
ClientMethod setPerson(name) [ Language = javascript ]
{

	var schedule = zenPage.getComponentById('schedule');

	schedule.setProperty('caption','Schedule for ' + name);

	var parm = zenPage.getComponentById('parmPerson');

	parm.value = name;

	schedule.refreshContents();

	var controller = zenPage.getComponentById('dataController');

	controller.setModelId('');

	controller.setDataByName('Person',name);

	controller.raiseDataChange();
}

/// 
/// User has selected a new date in the calendar.
/// 
/// Update the schedule pane.
ClientMethod selectDate(date) [ Language = javascript ]
{

	var schedule = zenPage.getComponentById('schedule');

	schedule.setDate(date);



	var controller = zenPage.getComponentById('dataController');

	controller.setModelId('');
}

/// 
/// User has selected a new item in the schedule.
/// 
/// Update the form showing details for the selected appointment.
ClientMethod selectItem(id, time) [ Language = javascript ]
{

	

	var controller = zenPage.getComponentById('dataController');

	if (id) {

		// existing appointment

		// set the data controller to refer to the selected appointment

		// this will automatically update the form with appointment details.

		controller.setModelId(id);

	}

	else {

		// new appointment

		var schedule = zenPage.getComponentById('schedule');

		var name=zenPage.getComponentById('ctrlPerson').getValue();	

		// fill in form with default information

		controller.createNewObject();

		controller.setDataByName('Person',name);

		controller.setDataByName('StartTime',time);

		controller.setDataByName('Duration',schedule.selectedInterval);

		controller.raiseDataChange();

		

		// give focus to the reason field

		zenPage.getComponentById('ctrlReason').focus();

	}
}

/// 
/// Data drop handler for schedule pane.
/// 
/// User has dropped an item on the schedule pane.
ClientMethod scheduleDataDrop(dragData) [ Language = javascript ]
{

	// Ask schedule what time slot was dropped on

	var schedule = zenPage.getComponentById('schedule');

	var time = schedule.getDropTimeSlot();

	if ('' != time) {

		var d = dragData.value.toString().split(':');

		var reason = d[0];

		var duration = d[1];



		// create a new appointment using the dataController

		// fill in its details, save them, and then

		// refresh the schedule pane.

		var controller = zenPage.getComponentById('dataController');

		var name=zenPage.getComponentById('ctrlPerson').getValue();

		controller.setModelId('');

		controller.setDataByName('Person',name);

		controller.setDataByName('StartTime',time);

		controller.setDataByName('Duration',duration);

		controller.setDataByName('Reason',reason);

		controller.raiseDataChange();

		zenPage.getComponentById('theForm').save();

		schedule.refreshContents();

	}

	return true;
}

/// 
/// Change what the schedule pane is displaying.
/// 
/// <var>view</var> is 'day','week', or 'month'.
ClientMethod setScheduleView(view) [ Language = javascript ]
{

	var schedule = zenPage.getComponentById('schedule');

	schedule.setView(view);
}

/// 
/// Change the time interval displayed by the schedulePane.
ClientMethod setScheduleInterval(interval) [ Language = javascript ]
{

	var schedule = zenPage.getComponentById('schedule');

	schedule.setProperty('interval',interval);

	schedule.refreshContents();
}

}

