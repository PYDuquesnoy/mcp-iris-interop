/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a calendar.
Class %DeepSee.Component.Widget.calendar Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// Style for widget sections
XData Style
{
<style type="text/css">

.schedulePaneTable {
	font-family: arial;
	font-size: 14px;
	color: #404040;
	border: 1px solid #404040;
	width: 100%;
	table-layout: fixed;
	background: white;
}

input.scheduleBtn {
	width: 100%;
	font-size: 14px;
	vertical-align: middle;
}

td.scheduleMonthCellHi {
	background: rgb(53,107,141);
	color: white;
}

div.scheduleSlotHi {
	background: rgb(53,107,141);
	color: white;
}
div.scheduleSlotBookedHi,div.scheduleSlotUnavailableHi {
	background: rgb(53,107,141);
	color: white;
}

</style>
}

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Calendar","%DeepSee"),..%ClassName(1),"deepsee/calendar_48.gif")
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB565 - required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// add schedule pane to the widget
		Set tCalendar = ##class(%ZEN.ComponentEx.schedulePane).%New()
		Set tCalendar.id = ..%MakeWidgetId("calendar")
		Set tCalendar.dayList = tCalendar.shortDayList // !!!
		Set tCalendar.onchangeview = "zenPage.getComponent("_..index_").changeViewHandler();"
		Set tCalendar.cellHeight = 10
		Set tCalendar.interval = 90
		Set tCalendar.view = "month"
		//Set tCalendar.controllerId = tController.id
		Set tSC = pGroup.%AddChild(tCalendar)
		If $$$ISERR(tSC) Quit
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var calendar = this.findComponent('calendar');
	if (calendar) {
		var calendarDiv = calendar.getEnclosingDiv();
		calendarDiv.style.width = width-10 + 'px';
		calendarDiv.style.height = height + 'px';

		var hdr = calendar.findElement('header');
		var hh = (hdr) ? hdr.offsetHeight : calendar.headerHeight;

		// adjust size of calendar cells
		// !!! move this logic to schedulePane
		var ch = calendar.cellHeight;
		switch(calendar.view) {
		case 'month':
			ch = Math.floor((height - parseInt(hh) - 20) / (7*3));
			break;
		default:
			var intervals = 8;
			ch = Math.floor((height - parseInt(hh) - 20) / (intervals));
			break;
		}
		if (ch != calendar.cellHeight) {
			calendar.cellHeight = ch;
			calendar.refreshContents();
		}
	}
}

/// User has selected a different view in the calendar.
ClientMethod changeViewHandler() [ Language = javascript ]
{
	this.adjustSizes(false);
}

/// Apply the given filter to this widget.
ClientMethod applyFilter(name, value) [ Language = javascript ]
{
}

}
