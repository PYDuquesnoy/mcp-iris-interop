/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Schedule spec editor.
/// Schedules are used to schedule resources and alerts.
Class EnsPortal.ScheduleEditor Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to edit this page.
Parameter EDITRESOURCE = "%Ens_ProductionConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Schedule Editor";

/// ID of schedule spec to display.
Property scheduleId As %String(ZENURL = "scheduleId");

/// Value of schedule string currently being edited.
Property scheduleString As %String(ZENURL = "schedule");

/// Value of schedule string currently being edited.
Property editMode As %String(ZENURL = "editMode");

/// Selected row in listing mode.
Property selectedRow As %ZEN.Datatype.integer;

/// whether or not the page is in add mode
Property addMode As %ZEN.Datatype.boolean;

Property msgDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to remove this item?")} ];

Property msgDate As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please select a date!")} ];

Property lblAdd As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Add New Item Below")} ];

Property lblEdit As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Edit Setting Below")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
table.listingTable {
	border: 1px solid black;
	width: 100%;
}

table.listingTable tr.selectedRow {
	background: yellow;
}

table.listingTable th {
	border-bottom: 1px solid black;	
	border-right: 1px solid gray;	
	background: #D0D0D0;
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
}

table.listingTable td {
	border-bottom: 1px solid gray;	
	border-right: 1px solid gray;
	padding: 2px;
	padding-left: 4px;
	padding-right: 4px;
}

#propertyPane1 {
	position: relative;
	width: 370px;
	background: #E0E0D0;
	border-left: 1px solid #D0D0D0;
	border-bottom: none;
}

.schedulePaneDayHeader {
	font-size: 0.8em;
}

.detailTitle {
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 5px;
	overflow: hidden;
	background: #D0D0D0;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup id="mainGroup" cellVAlign="top">
<pane paneName="propertyPane" />
<pane paneName="detailPane" />
</hgroup>
</pane>
}

XData propertyPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="background:#E0E0D0;">
<vgroup id="propertyPane1" hidden="false">
<hgroup>
<spacer width="5"/>
<vgroup>
<form cellStyle="padding:2px;">
<vgroup id="grpSchedule" >
<textarea id="txtScheduleString" label="Raw String" cols="37" rows="5" containerStyle="padding-top:10px;" onkeypress="zenPage.setModified(true);" onchange="zenPage.setModified(true);"/>
<hgroup>
<button id="rawStringApplyButton" controlClass="commandButton" caption="Preview" 
   title="Click to apply this raw string to the current display, without saving any of the changes" onclick="zenPage.applyRawToView()" />
<spacer width="5"/>
<button id="rawStringSaveButton" controlClass="commandButton" caption="Save Spec" 
   title="Click to save this raw string to the currently selected schedule specification" onclick="zenPage.saveRaw();" />
<spacer width="5"/>
<button id="rawStringCancelButton" controlClass="commandButton" caption="Cancel" hidden="true"
   title="Close this window, without saving any of the changes" onclick="zenPage.cancelRaw()" />
</hgroup>
<textarea id="txtDescription" label="Description" cols="37" rows="2" containerStyle="padding-top:10px;" onkeypress="zenPage.setModified(true);" onchange="zenPage.setModified(true);"/>
<button controlClass="commandButton" caption="Save Description" title="Click to save description" onclick="zenPage.saveDescription();"/>
<checkbox id="chkDeployable" label="Deployable" title="When this option is selected, this schedule specification will be included when schedule specifications are exported to a deployment package" onchange="zenPage.saveDeployable();"/>
<spacer width="5"/>
<html id="listing1" label="Action Table" OnDrawContent="DrawListing1" containerStyle="padding-top:15px;" />
<spacer height="10"/>
<hgroup>
<hgroup id="grpAdd" hidden="true">
<button controlClass="commandButton" caption="Add Action"  title="Click to add a new action to the schedule spec" onclick="zenPage.addItem();"/>
<spacer width="5"/>
</hgroup>
</hgroup>
</vgroup>
<vgroup id="grpIntro">
<spacer height="40"/>
<hgroup>
<spacer width="20"/>
<label label="Use this page to create or edit a schedule specification." />
</hgroup>
</vgroup>
<spacer height="2" />
<vgroup id="grpAction" hidden="true" label="" labelClass="schedulePaneDayHeader" cellStyle="padding:1px;" >
<!--<vgroup id="grpAction" hidden="true" label="" labelClass="schedulePaneDayHeader" cellStyle="padding:4px;" containerStyle="border:1px solid #404040;">-->
<select id="Action" label="Action:" valueList="START,STOP" value="START" showEmpty="false" 
        onchange="zenPage.setModified(true);"/>
<select id="Frequency" label="How often do you want this action to be run?"
displayList="Daily,Weekly,Monthly,Yearly,One time only" valueList="1,2,3,4,5" value="2"
  onchange="zenPage.setModified(true);zenPage.changeFrequency(zenThis.value);" showEmpty="false"/>

<!-- The numbers in the id values id2, id3, id4, id5 are used cleverly in the changeFrequency() method - do not "improve" them -->

<vgroup id="id2" label="Which day of the week?" enclosingClass="zenLabel" >
<select id="cmbWeekly" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" valueList="00,01,02,03,04,05,06" 
        showEmpty="false" value="01" onchange="zenPage.setModified(true);"/>
</vgroup>

<vgroup id="id3" label="Select a date " hidden="true">
<hgroup>
<vgroup labelPosition="left">
<radioButton id="radMonth1" name="radMonth" caption="by day of month" optionValue="month" value="month" enclosingClass="zenLabel" 
             onchange="zenPage.setModified(true);zenPage.changeMonthly(zenThis.value);"/>
<radioButton id="radMonth2" name="radMonth" caption="by day of week" optionValue="week" enclosingClass="zenLabel" 
             onchange="zenPage.setModified(true);zenPage.changeMonthly(zenThis.value);"/>
</vgroup>
<vgroup>
<select id="MonthlyDate" value="1" onchange="zenPage.setModified(true);"/>
<hgroup id="MonthlyDay" labelPosition="left" disabled="true">
<select id="cmbMonthWeek" valueList="01,02,03,04,05" 
       displayList="First week,Second week,Third week,Fourth week,Fifth week" showEmpty="false" value="01"
         onchange="zenPage.setModified(true);" />
<select id="cmbMonthlyDay" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" 
      valueList="00,01,02,03,04,05,06" showEmpty="false" value="01" 
        onchange="zenPage.setModified(true);"/>
</hgroup>
</vgroup>
</hgroup>

</vgroup>

<vgroup id="id4" hidden="true" label="On which day?" >
<dateSelect id="YearlyDate" format="MD" onchange="zenPage.setModified(true);"/>
</vgroup>
<vgroup id="id5" hidden="true" label="On which day?">
<dateText id="OneTimeDate" name="OneTimeDate" onchange="zenPage.setModified(true);"/>
</vgroup>
<hgroup label="Time of the day: (hh:mm:ss)" labelPosition="left">
<select id="Hour" showEmpty="false" value="00" onchange="zenPage.setModified(true);"/>
<html>:</html>
<select id="Minute" showEmpty="false" value="00" onchange="zenPage.setModified(true);"/>
<html>:</html>
<select id="Second" showEmpty="false" value="00" onchange="zenPage.setModified(true);"/>

</hgroup>
<!--<dateText id="StartDate" name="StartDate" label="Date to begin this action:"/>-->
<spacer height="5"/>
<hgroup>
<hgroup id="grpSave" hidden="false">
<button controlClass="commandButton" caption="Save Action" title="Click to save the action shown below" onclick="zenPage.saveSchedule();"/>
<spacer width="5"/>
</hgroup>
<hgroup id="grpClear" hidden="true">
<button controlClass="commandButton" caption="Clear Action" title="Click to hide the action detail fields" onclick="zenPage.clearFields();"/>
<spacer width="5"/>
</hgroup>
<hgroup id="grpRemove" hidden="false">
<button controlClass="commandButtonRemove" caption="Remove Action"  title="To remove an action, click on a row of the table first." onclick="zenPage.removeItem();"/>
</hgroup>
</hgroup>
<spacer height="5"/>
</vgroup>
</form>

</vgroup>
</hgroup>
</vgroup>
</pane>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup valign="top" enclosingStyle="background:#D0D0D0;">
<spacer height="5" />
<label labelClass="detailTitle" labelStyle="padding-left:9px;" label="Detailed View of Current Schedule" />
<spacer height="5" />
<hgroup valign="top">
<spacer width="9"/>
<vgroup id="navigatorPane" valign="top" cellAlign="left" >
<calendar onchange="zenPage.selectDate(zenThis.getValue());"/>

<form cellStyle="padding:3px;padding-left:6px;">
<label labelClass="detailTitle" labelStyle="padding-left:0px;padding-top:6px;" label="Display Settings" />
<select label="Interval" value="30"
	title="Select the time interval to display."
	showEmpty="false"
	onchange="zenPage.setScheduleInterval(zenThis.getValue());"
	displayList="5m,15m,30m,60m"
	valueList="5,15,30,60"
/>
<select label="Start Time" value="360"
id="selStartTime"
	title="Select the starting time to display."
	showEmpty="false"
	onchange="zenPage.setScheduleStartTime(zenThis.getValue());"
/>
<select label="End Time" value="1080"
id="selEndTime"
	title="Select the end time to display."
	showEmpty="false"
	onchange="zenPage.setScheduleEndTime(zenThis.getValue());"
/>
</form>

</vgroup>
<spacer width="9"/>
<vgroup id="grpSchedulePane" containerStyle="background:white;">

<!-- schedule view -->
<schedulePane id="schedulePane"
caption=""
dateFormat="3"
interval="30"
startTime="360"
endTime="1080"
onselectitem="zenPage.selectItem(id,time);"
 view="week"
 OnGetScheduleInfo="GetScheduleInfo">
 <parameter id="scheduleSpec" paramName="scheduleSpec" value=""/>
  </schedulePane>

</vgroup>
<spacer width="9"/>
</hgroup>
</vgroup>
</pane>
}

ClientMethod selectItem(id, time) [ Language = javascript ]
{
}

/// user selected a Schedule spec from drop-down
ClientMethod changeSchedule() [ Language = javascript ]
{
	var proxy = this.LoadSchedule(this.scheduleId);
	if (proxy.Message == "") {
		zen("txtDescription").setValue(proxy.Description);
		zen("txtScheduleString").setValue(proxy.ScheduleSpec);
		zen("chkDeployable").setValue(proxy.Deployable);
		this.scheduleString = proxy.ScheduleSpec;
		this.refreshCalendar();
	} else {
		alert(proxy.Message);
	}
}

/// user wishes to apply the current raw string to the entire schedule view
ClientMethod applyRawToView() [ Language = javascript ]
{
	this.scheduleString = zen("txtScheduleString").getValue();
	if (this.scheduleString == "") {
		alert($$$Text('The string is empty.'));
	}
	else {
		var msg = zenPage.ValidateScheduleString(this.scheduleString);
		if (msg.length > 0) {
			alert(msg);
		}
		else {
			this.refreshCalendar();
		}
	}
}

ClientMethod changeFrequency(choice) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	for (var i=2;i<6;i++) {
		var id = "id"+i;
		zen(id).setHidden(i!=choice);
	}
}

/// enable/disable radio buttons for monthly
ClientMethod changeMonthly(choice) [ Language = javascript ]
{
	zen("MonthlyDate").setProperty("disabled",choice == "week");
	zen("MonthlyDay").setProperty("disabled",choice != "week");
}

/// user clicked "Add Item". Reset the selectedRow to null, refresh table and show action block.
ClientMethod addItem() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	this.setModified(false);
	this.selectedRow = "";
	var tab = self.document.getElementById('actionTable');
	var len = tab.rows.length;
	var row = tab.insertRow(len);
	row.id = "addInstructionRow";
	var cell = row.insertCell(0);
	cell.colSpan = 2;
	cell.innerHTML = $$$Text("Choose values below");
	
	// set action editing fields to defaults
	zen('Action').setValue('START');
	zen('Frequency').setValue('2'); // weekly frequency
	zen('id2').setHidden(0); // show the day of week for weekly frequency
	zen('cmbWeekly').setValue('01'); // day of week is Monday
	zen('id3').setHidden(1); // don't show the fields for other frequencies
	zen('id4').setHidden(1); // don't show the fields for other frequencies
	zen('Hour').setValue('00');
	zen('Minute').setValue('00');
	zen('Second').setValue('00');
	
	// set hidden fields to defaults, just in case they get displayed later
	zen('MonthlyDate').setValue('1'); 
	zen('cmbMonthWeek').setValue('01');
	zen('cmbMonthlyDay').setValue('01');
	zen('radMonth2').setValue('month');

	// show action editing fields
	this.setActionsHidden(false);
	
	// hide Add, show Clear and Save
	zenPage.gotoAdded();
}

/// user clicked "Remove Item". If confirmed, remove the matching piece from scheduleString and refresh table.
ClientMethod removeItem() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	if (this.selectedRow == "") {
		alert($$$Text("Please choose an action to remove."));
		return;
	}
	var c = confirm(this.msgDelete);
	if (c == false) return;
	var newSchedule = "";
	var thisRow = this.selectedRow - 1;
	var tSchedule = this.scheduleString.split(",");
	for (n=0;n<tSchedule.length;n++) {
		if (n != thisRow) {
			if (newSchedule == "") newSchedule = newSchedule + tSchedule[n];
			else newSchedule = newSchedule + "," + tSchedule[n];
		}
	}
	zenPage.setModified(true);
	this.scheduleString = newSchedule;
	this.refreshList();
	this.selectedRow = "";
	var ok = this.updateSchedule();
	if (ok.length > 0) {
		alert(ok);
	}
	this.setActionsHidden(true);
	this.gotoNotSelected();
}

/// user clicked New. Open New Schedule dialog.
ClientMethod selectSchedule() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ScheduleSelect.zen'),this.addPopupSuffix('SelectSchedule'),'resizable,width=600,height=400');
}

/// user clicked "Save As"
ClientMethod saveRawSchedule() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	zenPage.setModified(false);
	var parms = {
		scheduleString:zenPage.scheduleString
	}
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ScheduleImport.zen'),this.addPopupSuffix('ImportSchedule'),'resizable,width=600,height=500',parms);
}

/// user clicked "Save" by the description. 
ClientMethod saveDescription() [ Language = javascript ]
{
	if (zenPage.scheduleId == "") { return false; }
	if (!this.checkEdit()) { return false; }
	if (zen('txtDescription').getValue().length > 255) {
		alert ($$$Text("Please keep the description length under 255 characters."));
		return false;
	}
	
	// only save the description
	this.updateSchedule();
	this.clearFields();
	this.setModified(false);
	
	// deal with popup vs. regular mode
	if (zenPage.editMode == "ProductionConfigPopup") {
		if (zenPage.scheduleId == "") {
			alert($$$Text("You must save to a named schedule to save a description."));
		}
		else {
			alert($$$FormatText($$$Text("Schedule spec description saved to %1."),zenPage.scheduleId));
		}
	}
	else {
		alert($$$FormatText($$$Text("Schedule spec description saved to %1."),zenPage.scheduleId));
	}
}

/// user clicked "Save Action". If selectedRow exists then this is Edit. Otherwise it's Add.
ClientMethod saveSchedule() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	// if user hit Save when they did not enter any changes to a new item, return
	if (!zenPage.pageModified && zenPage.addMode) {
		if (!confirm($$$Text("You did not edit the new action; are you sure you want to add it?"))) { return false; }
	}
	
	zenPage.setModified(false);
	var tSchedule = this.scheduleString;
	var StartTime = "T"+zen("Hour").getValue()+":"+zen("Minute").getValue()+":"+zen("Second").getValue();
	//adding the new item
	var Action = zen("Action").getValue();
	var Frequency = zen("Frequency").getValue();
	var newSchedule = Action + ":";
	
	//Daily,Weekly,Monthly,Yearly,One time only
	switch (Frequency)
	{
	case "1":
		// Daily
		newSchedule = newSchedule + "*-*-*" + StartTime;
		break;
	case "2":
		//Weekly
		var tSchedule = zen("cmbWeekly").getValue();
		newSchedule = newSchedule + "WEEK-*-" + tSchedule + StartTime;
		break;
	case "3":
		//Monthly
		if (zen("radMonth1").getValue() == "month") {
			var MonthlyDate = zen("MonthlyDate").getValue();
			newSchedule = newSchedule + "*-*-" + MonthlyDate + StartTime;
		} else {
			var cmbMonthWeek = zen("cmbMonthWeek").getValue();
			var tSchedule = zen("cmbMonthlyDay").getValue();
			newSchedule = newSchedule + "WEEK-" + cmbMonthWeek + "-" + tSchedule + StartTime;
		}
		break;
	case "4":
		//Yearly
		var YearlyDate = zen("YearlyDate").getValue();
		if (YearlyDate == "") {
			zen("YearlyDate").focus();
			return;
		} else {
			var YearlyDate = YearlyDate.split("-");
			newSchedule = newSchedule + "*-" + YearlyDate[1]+"-"+YearlyDate[2]+ StartTime ;
		}
		break;
	case "5":
		//One time only
		var OneTimeDate = zen("OneTimeDate").getValue();
		if (OneTimeDate == "") {
			zen("OneTimeDate").focus();
			return;		
		} else {
			newSchedule = newSchedule + OneTimeDate + StartTime;
		}
		break;
	default:
		break;		
	}
	
	// Put new item into schedule string
	var tSchedule = this.scheduleString.split(",");
	var tSche;
	if (zenPage.addMode) { // add new
		for (n=0; n<tSchedule.length; n++) {
			tSche = tSchedule[n];
			if (tSche == newSchedule) {
				alert($$$Text("The new entry is a duplicate of an existing entry. Duplicate entries are not allowed."));
				return false;
			}
		}
		if (this.scheduleString != "") this.scheduleString = this.scheduleString + "," + newSchedule;
		else this.scheduleString = newSchedule;
	} 
	else { // edit existing
		var tString = "";
		var thisRow = this.selectedRow - 1;
		for (n=0; n<tSchedule.length; n++) {
			tSche = tSchedule[n];
			if (n == thisRow) tSche = newSchedule;
			if (tString == "") tString = tString + tSche;
			else tString = tString + "," + tSche;
		}
		this.scheduleString = tString;
	}
	
	// save the changed string
	zenPage.saveCurrentStringAndName();
}

ClientMethod saveCurrentStringAndName() [ Language = javascript ]
{
	this.selectedRow = "";
	var ok = this.updateSchedule();
	if (ok.length > 0) {
		alert(ok);
	}
	else {
		alert($$$FormatText($$$Text("Schedule %1 updated."), zenPage.scheduleId));
	}
	this.clearFields();
	this.setModified(false);
}

ClientMethod clearFields() [ Language = javascript ]
{
	// hide action display fields
	zenPage.setActionsHidden(true);
	
	// get rid of empty row at bottom of display table
	if (zenPage.addMode) zenPage.removeEmptyRow();
	
	// show Add, hide Clear and Save
	zenPage.gotoNotSelected();
}

ClientMethod gotoNotSelected() [ Language = javascript ]
{
	this.setModified(false);
	zenPage.addMode = false;
	zen("grpSave").setHidden(1);
	zen("grpAdd").setHidden(0);
	zen("grpClear").setHidden(1);
	zen("grpRemove").setHidden(1);
}

ClientMethod gotoSelected() [ Language = javascript ]
{
	zenPage.addMode = false;
	zen("grpSave").setHidden(0);
	zen("grpAdd").setHidden(1);
	zen("grpClear").setHidden(1);
	zen("grpRemove").setHidden(0);
}

ClientMethod gotoAdded() [ Language = javascript ]
{
	zenPage.addMode = true;
	zen("grpSave").setHidden(0);
	zen("grpAdd").setHidden(1);
	zen("grpClear").setHidden(0);
	zen("grpRemove").setHidden(1);
}

ClientMethod removeEmptyRow() [ Language = javascript ]
{
	var row = self.document.getElementById('emptyTableRow');
	if (row) {
		var tab = self.document.getElementById('actionTable');
		var len = tab.rows.length;
		var row = tab.deleteRow(len-1);
	}
	var row = self.document.getElementById('addInstructionRow');
	if (row) {
		var tab = self.document.getElementById('actionTable');
		var len = tab.rows.length;
		var row = tab.deleteRow(len-1);
	}
}

/// Refresh list and calendar
ClientMethod refreshCalendar() [ Language = javascript ]
{
	this.refreshList();
	zen('scheduleSpec').value = this.scheduleString; 
	zen('txtScheduleString').setValue(this.scheduleString);
	zen('schedulePane').refreshContents();
}

/// Refresh list
ClientMethod refreshList() [ Language = javascript ]
{
	zen('listing1').refreshContents();
}

ClientMethod updateSchedule() [ Language = javascript ]
{
	this.refreshCalendar();
	
	// Save to server, but only if we have a name for the schedule specification
	if (zenPage.scheduleId.length > 0) { 
		return zenPage.SaveData(zenPage.scheduleId,zen('txtDescription').getValue(),zenPage.scheduleString,zen('chkDeployable').getValue());
	} else { return $$$Text('Use Save As if you want to save to a named schedule.');}
}

/// User has selected a row in the listing table.
ClientMethod selectRow(row) [ Language = javascript ]
{
	if (this.selectedRow == row) { // unselect the row
		this.selectedRow = "";
		this.refreshList();
		this.setActionsHidden(true);
		this.gotoNotSelected();
		return false;
	}
	this.gotoSelected();
	this.selectedRow = row;
	this.refreshList();
	this.setActionsHidden(false);
	var schedule = this.scheduleString.split(",");
	schedule = schedule[row-1];
	var action = schedule.split(":");
	zen('Action').setValue(action[0]);
	var main = schedule.split(action[0]+":");
	var piece = main[1].split("T");
	var date = piece[0].split("-");
	var year = date[0];
	var mon = date[1];
	var day = date[2];
	var time = piece[1].split(":");
	zen('Hour').setValue(time[0]);
	zen('Minute').setValue(time[1]);
	zen('Second').setValue(time[2]);
	var Frequency = "";
	// evaluate year and month
	switch(year) {
	case 'WEEK':
		if (mon == "*") {
			// every week on a day, i.e. WEEK-*-03 everyweek on Wednesday
			Frequency = 2;
			zen("cmbWeekly").setValue(day);

		} else {
			// monthly by day of week, i.e. WEEK-01-02 first week on Tuesday (monthly)
			Frequency = 3;
			zen("radMonth2").setValue("week");
			zen("cmbMonthWeek").setValue(mon);
			zen("cmbMonthlyDay").setValue(day);
			this.changeMonthly("week");
		}
		break;
		
	case '*':
		// monthly, every month on the 12th, i.e. *-*-12
		if (mon == "*") {
			Frequency = 3;
			if (day == "*") {
				Frequency = 1;	
			} else {
				zen("radMonth1").setValue("month");
				zen("MonthlyDate").setValue(day);
				this.changeMonthly("month");			
			}
		} else {
			// yearly on a particular date, i.e. *-05-02 Yearly on May 2
			Frequency = 4;
			zen("YearlyDate").setValue("2009-"+mon+"-"+day);
		}
		break;
		
	default:
		//one time only
		Frequency = 5;
		var date = action[1].split("T");
		zen("OneTimeDate").setValue(date[0]);	
		break;
		
	}
	zen('Frequency').setValue(Frequency);
	this.changeFrequency(Frequency);
}

/// User clicked Delete button.
ClientMethod deleteSchedule() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var cal = document.getElementById('targetSchedule');
	var id = cal.value;
	if (id=='') {
		alert($$$Text('Please select a Schedule Spec to delete'));
		return false;
	} 
	else {
		if (confirm($$$FormatText($$$Text('Are you sure you want to delete schedule %1?'),id))) {
			var msg = this.DeleteID(id);
			if (msg!='') {
				alert(msg);
			}
			else { 
				// get rid of the option we previously generated on the client 
				var found = false;
				var len = cal.options.length;
				for (i = 0; ((i < len) && (found == false)); i++) {
					if (cal.options[i].selected == true) {
						cal.remove(i);
						found = true;
					}
				}
				// start fresh with no schedule selected
				zenPage.showWorkArea("");
			}
		}
	}
}

/// Delete the given id.
ClassMethod ValidateScheduleString(txt) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(Ens.ScheduleHandler).ValidateScheduleSpec(.txt, .errors, .n)
	If $$$ISERR(tSC) {
		For k=1:1:n {
			If (""'=errors(k)) {
				Set tMsg = tMsg _ errors(k)
			}
		}
	}
	Quit tMsg
}

/// Delete the given id.
ClassMethod DeleteID(id) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(Ens.Util.Schedule).%DeleteId(id)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If (..scheduleId="") {
		Quit ..%OnGetPageName()
	}
	Quit ..scheduleId
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Schedule Spec Editor","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Set pCommands(1) = $LB("btnNew",$$$Text("New"),$$$Text("Create a new schedule"),"zenPage.selectSchedule();")
	// If (%page.editMode = "ProductionConfigPopup") {
		Set pCommands(2) = $LB("btnSaveAs",$$$Text("Save As"),$$$Text("Save the current raw string as a named schedule"),"zenPage.saveRawSchedule();")
	// }
	Set pCommands(3) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete a schedule spec"),"zenPage.deleteSchedule();")

	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	&html<
	<td nowrap="1" style="padding-left:50px;">
	<div nowrap="1">
		<span style="font-size:0.8em;color:#404040;padding-left:20px;">#($$$TextHTML("Choose a schedule spec to work on:"))#</span>
		<select id="targetSchedule" type="select" name="targetSchedule" onchange="zenPage.showWorkArea(this.value);">
			<option value="" ></option>
	>
		
	// Set up the list of existing schedule specs
	Set tRS = ##class(%ResultSet).%New("Ens.Util.Schedule:Extent")
	Set tSC = tRS.Execute()
	While (tRS.Next()) {
		Set tOption = $ZCVT($G(tRS.Data("ID")),"O","HTML")
		&html<
			<option value="#(tOption)#" >#(tOption)#</option>
		>
	}

	&html<
		</select>
	</div></td>
	>
	Quit $$$OK
}

/// Draw table under Description with Schedule view mode = calendar.
Method DrawListing1(pSeed As %String) As %Status
{
	// pull apart the schedule string and display its contents as a table.
		
	&html<<table id="actionTable" class="listingTable" border="0" cellspacing="0">>

	// headings
	&html<<tr>>
	&html<<th>#($$$Text("Action"))#</th><th>#($$$Text("Event Specification"))#</th>>
	&html<</tr>>
	
	If ""=..scheduleString {
		&html<<tr id="emptyTableRow"><td colspan=2>#($$$Text("No actions defined"))#</td></tr>>
	}
	Else {
		Set length = $L(..scheduleString,",")	
		For n = 1:1:length {
			Set piece = $P(..scheduleString,",",n)
			Set tAction = $P(piece,":",1)
			If tAction '= "" {
				Set tStartTime = $P(piece,":",2,99)
				&html<<tr onclick="zenPage.selectRow(#(n)#);" class="#($S(..selectedRow=n:"selectedRow",1:""))#">>
				&html<<td nowrap>#($S(tAction'="":$ZCVT(tAction,"O","HTML"),1:"&nbsp;"))#</td>>
				&html<<td nowrap>#($S(tStartTime'="":$ZCVT(tStartTime,"O","HTML"),1:"&nbsp;"))#</td>>
				&html<</tr>>
			}
		}
	}
	&html<</table>>
	Quit $$$OK
}

/// GetScheduleInfo callback for the Schedule Page.<br/>
/// This method returns the set of scheduled items
/// that should be displayed on the schedulePane.
ClassMethod GetScheduleInfo(ByRef pParms As %String, pBeginDate As %Date, pEndDate As %Date, ByRef pInfo As %List) As %Boolean
{
	// pParms is an array of parameter values associated with the schedule pane
	// pBeginDate and pEndDate are the beginning and ending date values (in $H format)
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
	// pParms("scheduleSpec") is passed in as the string that contains the schedule items for this Schedule Spec. 
	// e.g. START:*-*-*T01:00:00,START:WEEK-01-02T02:02:02,START:WEEK-*-02T02:02:02,START:*-*-13T13:13:13,STOP:*-05-02T02:02:12,START:2009-09-25T00:00:01
	//
	// pInfo(day) contains css style for the entire day.

	set tSC=$$$OK
	try {
		set tScheduleSpec = $g(pParms("scheduleSpec")) quit:tScheduleSpec=""
		set tCurrentDateTime=$tr($zdatetime(pBeginDate_",00000",3)," ","T")
		set tEndDateTime=$tr($zdatetime(pEndDate+1,3)," ","T")

		// fetch events into tScheduleEvents
		for {
			set tSC=##class(Ens.ScheduleHandler).ParseScheduleSpec(tScheduleSpec,.tCurrentState,.tNextEventDateTime,,tCurrentDateTime)
			Quit:$$$ISERR(tSC)
			Quit:tCurrentState="DISABLED"
			set tScheduleEvents($i(tScheduleEvents))=tCurrentState_"^"_tCurrentDateTime
			Quit:tNextEventDateTime]tEndDateTime
			Quit:tNextEventDateTime="" 
			set tCurrentDateTime=tNextEventDateTime
		}
		
		// convert tScheduleEvent to START-STOP pairs
		set tStartIndex="",tStopIndex=""
		for i=1:1:$g(tScheduleEvents) {
			if tStartIndex="" set:$p(tScheduleEvents(i),"^",1)="START" tStartIndex=i continue
			if tStopIndex="",$p(tScheduleEvents(i),"^",1)'="STOP" continue
			set tStopIndex=i
			set tStartStop($i(tStartStop))=$p(tScheduleEvents(tStartIndex),"^",2)_"^"_$p(tScheduleEvents(tStopIndex),"^",2)
			set tStartIndex="",tStopIndex=""
		}
		if tStartIndex'="" set tStartStop($i(tStartStop))=$p(tScheduleEvents(tStartIndex),"^",2)_"^"_tEndDateTime

		// convert tStartStop to pInfo format
		for i=1:1:$g(tStartStop) {
			set tStartDateTime=$zdatetimeh($tr($p(tStartStop(i),"^",1),"T"," "),3)
			set tStartDate=$p(tStartDateTime,",",1)
			set tStartTime=$p(tStartDateTime,",",2)
			set tStopDateTime=$zdatetimeh($tr($p(tStartStop(i),"^",2),"T"," "),3)
			set tStopDate=$p(tStopDateTime,",",1)
			set tStopTime=$p(tStopDateTime,",",2)

			if tStartDate=tStopDate {
				set pInfo(tStartDate,tStartTime\60,1)=$lb((tStopTime-tStartTime)\60,$g(pParms("id")),$g(pParms("reason")))
			} else {
				set pInfo(tStartDate,tStartTime\60,1)=$lb((86400-tStartTime)\60,$g(pParms("id")),$g(pParms("reason")))
				for tDate=tStartDate+1:1:tStopDate-1 {
					set pInfo(tDate,0,1)=$lb(1440,$g(pParms("id")),$g(pParms("reason")))
				}
				set pInfo(tStopDate,0,1)=$lb(tStopTime\60,$g(pParms("id")),$g(pParms("reason")))
			}
		}

	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}

	quit tSC

	// The following is old code and does not get executed
	
	Set (tID,tStartTime,tDuration,tReason,tPriority) = ""
	// Return an array of the form:
	// pInfo(day,time,n) = $LB(duration,value[,text,type,[,style]])
	// type=0--unavailable,1=booked

	// day-style (gray out weekends)
	// loop over days in range; if Sunday or Saturday
	// set day-wide style.
	For d = pBeginDate:1:pEndDate {
		Set tWeekDay = +$ZDT(d,10)
		//If ((tWeekDay = 0)||(tWeekDay = 6)) {
		//	Set pInfo(d) = "background: #C0C0F0;"
		//}
	}
	// Example: 
	Set scheduleSpec = $G(pParms("scheduleSpec"))
	Set tAction = $P(scheduleSpec,":",1)
	Set pInfo(pBeginDate,600,3) = $lb(35,tAction)
	Quit 1
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var navDiv = zen('navigatorPane').getEnclosingDiv();
		var calDiv = zen('schedulePane').getEnclosingDiv();
		var propDiv = zen('propertyPane1').getEnclosingDiv();
	
		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var cw = winWidth - (parseFloat(navDiv.offsetWidth) + parseFloat(propDiv.offsetWidth)) - 30;
		calDiv.style.width = cw + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// User has selected a new date in the calendar.
/// Update the schedule pane.
ClientMethod selectDate(date) [ Language = javascript ]
{
	var schedule = zen('schedulePane');
	schedule.setDate(date);
}

/// Change the time interval displayed by the schedulePane.
ClientMethod setScheduleInterval(interval) [ Language = javascript ]
{
	var schedule = zen('schedulePane');
	schedule.setProperty('interval',interval);
	schedule.refreshContents();
}

/// Change the startTime displayed by the schedulePane.
ClientMethod setScheduleStartTime(time) [ Language = javascript ]
{
	var start = parseInt(time);
	var end = parseInt(zen('selEndTime').getValue());
	var schedule = zen('schedulePane');
	if (end == start) {
		alert($$$Text("Cannot have the same start and end time"));
		var oldStart = schedule.getProperty('startTime');
		zen('selStartTime').setValue(oldStart);
	}
	else if (end < start) {
		alert($$$Text("Cannot have a start time after an end time"));
		var oldStart = schedule.getProperty('startTime');
		zen('selStartTime').setValue(oldStart);
	}
	else {
		schedule.setProperty('startTime',time);
		schedule.refreshContents();
	}
}

/// Change the endTime displayed by the schedulePane.
ClientMethod setScheduleEndTime(time) [ Language = javascript ]
{
	var start = parseInt(zen('selStartTime').getValue());
	var end = parseInt(time);
	var schedule = zen('schedulePane');
	if (start == end) {
		alert($$$Text("Cannot have the same start and end time"));
		var oldEnd = schedule.getProperty('endTime');
		zen('selEndTime').setValue(oldEnd);
	}
	else if (start > end) {
		alert($$$Text("Cannot have an end time before a start time"));
		var oldEnd = schedule.getProperty('endTime');
		zen('selEndTime').setValue(oldEnd);
	}
	else {
		schedule.setProperty('endTime',time);
		schedule.refreshContents();
	}
}

ClientMethod setActionsHidden(flag) [ Language = javascript ]
{
	// set visibility of fields back to default states
	zen('id3').setHidden(true);
	zen('id4').setHidden(true);
	zen('id5').setHidden(true);
	
	// reveal or hide the fields
	zen('grpAction').setHidden(flag);
}

/// user changed Deployable flag
ClientMethod saveDeployable() [ Language = javascript ]
{
	if (zenPage.scheduleId == "") { return false; }
	if (!this.checkEdit()) { return false; }
	
	var ok = this.updateSchedule();
	if (ok.length > 0) {
		alert(ok);
	}
	else {
		alert($$$FormatText($$$Text("Schedule %1 updated."), zenPage.scheduleId));
	}
	this.clearFields();
	this.setModified(false);
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set displayListStart = "12am (start),1am"
	Set valueListStart = "0,60"
	Set displayListEnd = "1am"
	Set valueListEnd = "60"
	For i = 2:1:11 {
		Set displayListStart = displayListStart _ "," _i_"am",valueListStart=valueListStart_","_(i*60)
		Set displayListEnd = displayListEnd _ "," _i_"am",valueListEnd=valueListEnd_","_(i*60)
	}
	Set displayListStart = displayListStart _ "," _"12pm",valueListStart=valueListStart_","_(12*60)
	Set displayListEnd = displayListEnd _ "," _"12pm",valueListEnd=valueListEnd_","_(12*60)
	For i = 13:1:23 {
		Set displayListStart = displayListStart _ "," _(i-12)_"pm",valueListStart=valueListStart_","_(i*60)
		Set displayListEnd = displayListEnd _ "," _(i-12)_"pm",valueListEnd=valueListEnd_","_(i*60)
	}
	Set displayListEnd = displayListEnd _ "," _"12am (end)",valueListEnd=valueListEnd_","_(24*60)
	Set tStart = ..%GetComponentById("selStartTime")
	Set tStart.displayList = displayListStart	
	Set tStart.valueList = valueListStart
	Set tEnd = ..%GetComponentById("selEndTime")
	Set tEnd.displayList = displayListEnd	
	Set tEnd.valueList = valueListEnd

	// See if given Schedule Spec exists, if so gets its schedule string value
	Set valueList = "1"
	For i = 2:1:31 Set valueList = valueList_","_i
	Set ..%GetComponentById("MonthlyDate").valueList = valueList
	// default yearly date to 30 days from today
	Set tDate = $zdt(+($H+30),3)
	Set ..%GetComponentById("YearlyDate").minYear = $E(tDate,1,4)
	Set ..%GetComponentById("YearlyDate").value = tDate
	Set ..%GetComponentById("OneTimeDate").value = tDate
	Set valueList = "00"
	For i = 1:1:23 Set a="0"_i,valueList = valueList_","_$E(a,$L(a)-1,$L(a))
	Set ..%GetComponentById("Hour").valueList = valueList
	Set valueList = "00"
	For i = 1:1:59 Set a="0"_i,valueList = valueList_","_$E(a,$L(a)-1,$L(a))
	Set ..%GetComponentById("Minute").valueList = valueList
	Set ..%GetComponentById("Second").valueList = valueList
	
	// Use either the scheduleId or the scheduleString to populate the fields in the form
	
	If (""'=%page.scheduleString) { // we have a scheduleString!
		If (%page.editMode = "ProductionConfigPopup") { // this is a popup
			Set ..%GetComponentById("rawStringSaveButton").title="Click to save this raw string and return its value to the production configuration page for the Schedule field" 
			Set ..%GetComponentById("rawStringCancelButton").hidden = 0
			Set ..%GetComponentById("grpSchedule").hidden = 0	
			Set ..%GetComponentById("grpAdd").hidden = 0
			Set ..%GetComponentById("grpIntro").hidden = 1
	}
		Else { // not really a valid state, shouldn't happen
			Set ..%GetComponentById("grpSchedule").hidden = 1	
			Set ..%GetComponentById("grpIntro").hidden = 0
		}
	}
	ElseIf (""'=%page.scheduleId) { // we have a scheduleId!
		If ("@"=$E(%page.scheduleId)) { // strip off the @ prefix
			Set %page.scheduleId = $E(%page.scheduleId,2,*) 
		}
		If (""=%page.scheduleId) { // not really a valid state, shouldn't happen
			Set ..%GetComponentById("grpSchedule").hidden = 1	
			Set ..%GetComponentById("grpIntro").hidden = 0
		}
		Else { // get the schedule spec identified by the scheduleId
			If ##class(Ens.Util.Schedule).%ExistsId(%page.scheduleId) = 1 {
				Set tSObj = ##class(Ens.Util.Schedule).%OpenId(%page.scheduleId)
				Set ..%GetComponentById("txtDescription").value = tSObj.Description
				Set %page.scheduleString = tSObj.ScheduleSpec
				Set ..%GetComponentById("propertyPane1").hidden = 0
				Kill tSObj
			}
		} 
		If (%page.editMode = "ProductionConfigPopup") { // this is a popup
			Set ..%GetComponentById("rawStringSaveButton").title="Click to save this named schedule and return its value to the production configuration page for the Schedule field" 
			Set ..%GetComponentById("rawStringCancelButton").hidden = 0
		}
	}
	Else { // not really a valid state, shouldn't happen
		Set ..%GetComponentById("grpSchedule").hidden = 1	
		Set ..%GetComponentById("grpIntro").hidden = 0
	}
	
	// Either way, now we have the schedule string to populate those fields in the form that need it
	
	Set ..%GetComponentById("scheduleSpec").value = %page.scheduleString 
	Set ..%GetComponentById("txtScheduleString").value = %page.scheduleString
	
	Quit tSC
}

/// Load up the properties of the named schedule into the properties of the proxy object
ClassMethod LoadSchedule(scheduleId) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Message = ""
	If ##class(Ens.Util.Schedule).%ExistsId(scheduleId) = 0 {
		Set tProxy.Description = ""
		Set tProxy.ScheduleSpec = ""		
		Set tProxy.Deployable = 0
	} Else  {
		Set tSObj = ##class(Ens.Util.Schedule).%OpenId(scheduleId)
		Set tProxy.Description = tSObj.Description
		Set tProxy.ScheduleSpec = tSObj.ScheduleSpec
		Set tProxy.Deployable = tSObj.Deployable
	}
	Quit tProxy
Error
	Set $ZT=""
	Set tProxy.Message = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action != "ok") {
			return false;
		}
		popupName = this.removePopupSuffix(popupName);
		switch(popupName) {
			case 'SelectSchedule': // fall-through
			case 'ImportSchedule':
				cal = document.getElementById("targetSchedule");
				opt = new Option(value,value,false,true); // make a new option and let it be selected
				if (zenIsIE) { // works either way for Chrome
					cal.add(opt); // must do it this way for IE
				}
				else { // works either way for Chrome
					cal.add(opt,null); // must do it this way for Firefox
				}
				zenPage.showWorkArea(value);
				break;
			case 'switchNamespace':
				zenPage.changeURLNamespace(value);
				break;
		}
	} catch (ex) {
		alert( $$$FormatText($$$Text("Error: %1"),ex) );	
	}
}

ClientMethod showWorkArea(value) [ Language = javascript ]
{
	try {
		if (zenPage.pageModified) {
			if (!confirm($$$Text('You have unsaved changes. Are you sure you wish to change to another schedule spec?'))) {
				if (this.scheduleId.length > 0) {
					document.getElementById("targetSchedule").value = this.scheduleId; // return drop-down to its previous value if any
				}
				return false;
			}
		}
		document.getElementById("targetSchedule").value = value; // for when the value comes from a URL parameter
		this.selectedRow = "";
		this.scheduleId = value; 
		this.changeSchedule(); 
	
		// show Add, hide Clear
		zenPage.gotoNotSelected();
	
		if (value == "") { // for when the user selects the blank option
			zen("grpSchedule").setHidden(true);
			this.setActionsHidden(true);
			zen("grpIntro").setHidden(false);
		}
		else { // the user has selected a valid option
			this.setActionsHidden(true);
			zen("grpIntro").setHidden(true);
			zen("grpSchedule").setHidden(false);
			if (zenPage.editMode == "ProductionConfigPopup") {
				zen("rawStringCancelButton").setHidden(false);
			}
		}
	} catch (ex) {
		alert( $$$FormatText($$$Text("Error: %1"),ex) );	
	}
}

/// Save modified schedule to server.
ClassMethod SaveData(pScheduleId As %String, Description As %String, scheduleString As %String, pDeployable As %Boolean) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set msg = ""
	Try {
		If ##class(Ens.Util.Schedule).%ExistsId(pScheduleId) = 0 {
			Set tSObj = ##class(Ens.Util.Schedule).%New()
			Set tSObj.Name = pScheduleId
		} Else  {
			Set tSObj = ##class(Ens.Util.Schedule).%OpenId(pScheduleId)
		}
		Set tSObj.Description = Description
		Set tSObj.ScheduleSpec = scheduleString
		Set tSObj.Deployable = pDeployable		
		Set tSC = tSObj.%Save()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) Set msg = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	
	Quit msg
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "SaveData": ..#EDITRESOURCE,
						: "")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	if (zenPage.editMode == "ProductionConfigPopup") {
		if (zenPage.scheduleId.length > 0) {
			zenPage.showWorkArea(zenPage.scheduleId); 
		}
		else {
			if (zenPage.scheduleString.length > 0) {
				zenPage.refreshCalendar();
			}
		}
	}
	else {
		zenPage.showWorkArea(zenPage.scheduleId); 
	}
	zen('selEndTime').setValue("1080"); // for IE
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	// value to be used in the production configuration page Schedule field
	var val = document.getElementById("targetSchedule").value; 
	
	if (!val || val == "") { // this is an unnamed raw string 
		return zen('txtScheduleString').getValue();
	}
	else { // this is the name of a named schedule spec
		return "@" + val;
	}
}

ClientMethod saveRaw(action) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (zenPage.editMode == "ProductionConfigPopup") { // return the raw string (or schedule spec name) value to the production configuration page

		// only do a save if we actually have a name for the schedule
		if (zenPage.scheduleId.length > 0) {
			zenPage.scheduleString = zen('txtScheduleString').getValue();
			if (this.scheduleString == "") {
				alert($$$Text('The string is empty.'));
			}
			else {
				var msg = zenPage.ValidateScheduleString(this.scheduleString);
				if (msg.length > 0) {
					alert(msg);
				}
				else {
					zenPage.saveCurrentStringAndName(); 
				}
			}
		}
		
		// return from the popup
		this.firePopupAction('ok',zenPage.getDialogValue());
	}
	else { // because of the way the page works ("New" button) we already have a schedule name associated with the raw string
		zenPage.scheduleString = zen('txtScheduleString').getValue();
		if (this.scheduleString == "") {
			alert($$$Text('The string is empty.'));
		}
		else {
			var msg = zenPage.ValidateScheduleString(this.scheduleString);
			if (msg.length > 0) {
				alert(msg);
			}
			else {
				zenPage.saveCurrentStringAndName(); 
			}
		}
	}
}

/// simply return to the production configuration page
ClientMethod cancelRaw(action) [ Language = javascript ]
{
	this.firePopupAction('cancel','');
}

}
