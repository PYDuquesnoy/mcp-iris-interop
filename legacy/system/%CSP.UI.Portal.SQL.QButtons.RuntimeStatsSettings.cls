/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by Cach&eacute;. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Settings dialog for SQL PTools in Management Portal.
Class %CSP.UI.Portal.SQL.QButtons.RuntimeStatsSettings Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.RuntimeStatsSettings.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "RuntimeStatsSettings";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property msgPurgeQueryDone As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Purge all cached queries done.")} ];

Property msgPurgeQuery As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Purge all cached queries failed.")} ];

Property warningImage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/broker/images/warning.png")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.caption {
	padding-top: 10px;
}
.pL20 {
	padding-left: 20px;
}
.pR20 {
	padding-right: 20px;
}
.optionTitle {
	font-size: 16px;
	font-weight: bold;	
}
.changeNote {
	color: #4D3926;
	margin: 20px;
	background: white;
	border: 1px solid #4D3926;
	border-radius: 5px;
	font-size: 0.8em;
	padding: 6px;
}
.settingNote {
	color: #4D3926;
	font-size: 0.8em;
	padding: 20px 30px 20px 20px;	
}

</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />
<jsonProvider id="jsonSettingsInfo" OnGetTargetObject="GetSettingsInfo">
 </jsonProvider>

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%">

<html><div id="settingNote" class="settingNote">NOTE:...</div>
</html>
<label id="idRespond" value=""/>
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();"/>
</hgroup>

</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<group enclosingStyle="margin:10px;">
<spacer height="10"/>
<label label="SQL Runtime Stats Collection Option" labelClass="optionTitle" />
<label label="(Select one of the following)"/>
<spacer height="4"/>

<radioButton id="radTurnOnStats_0" name="radStatsFlag" label="" caption="0" 
hint="hint" optionValue="0" onclick="zenPage.changeOption(0);"/>

<radioButton id="radTurnOnStats_1" name="radStatsFlag" caption="1" 
hint="hint" optionValue="1" onclick="zenPage.changeOption(1);"/>

<radioButton id="radTurnOnStats_2" name="radStatsFlag" caption="2" 
hint="hint" optionValue="2" onclick="zenPage.changeOption(2);"/>

<radioButton id="radTurnOnStats_3" name="radStatsFlag" caption="3" 
hint="hint" optionValue="3" onclick="zenPage.changeOption(3);"/>
<spacer height="10"/>

<fieldSet id="idTimeout" label="SQL Runtime Stats Collection Timeout Options" labelClass="pL20 optionTitle" enclosingClass="pL20 pR20">
 <group enclosingStyle="margin:10px;">
 <hgroup>
 <label label="Timeout by "/>
 <select id="timeoutOption" displayList="hours or minutes, date and time" valueList="M,T" showEmpty="false" value="" onchange="zenPage.changeTimeoutOption();"/>
 </hgroup>
	<hgroup id="idHowLong" label="SQL Runtime Stats collection will expire after this number of hours and/or minutes has passed upon Save:" labelClass="zenLabel" labelPosition="left" >
	<text id="txtHours" value="" size="3" label="Hours:" labelClass="zenLabel pL20" onchange="zenPage.validate(zenThis);"/>
	<text id="txtMinutes" value="" size="3" label="Minutes:" labelClass="zenLabel pL20" onchange="zenPage.validate(zenThis);"/>
	</hgroup>
	<spacer height="4"/>
	<group id="idDateTime" hidden="true" enclosingStyle="padding-left:20px" labelPosition="left">
	<dateText id="ExpirationDate" label="Select an expiration date: " minDate="" size="18" value=""
	title="default is today" onkeyup="zenPage.keyUp(zenEvent,zenThis);" onblur="zenThis.ondatechangeHandler();"/>
	<hgroup labelPosition="top" label="Enter an expiration time: ">
	<text id="txtExpHour" label="hour" value="" size="2" hint="(0-23)" onchange="zenPage.validate(zenThis);"/>
	<label value=":"/>
	<text id="txtExpMinute" label="minute" value="" size="2" hint="(0-59)" onchange="zenPage.validate(zenThis);"/>
	</hgroup>
	</group>
	<html>
	<div id="errorNote" class="errorNote" style="display:none;"></div>
	</html>

<spacer height="4"/>	
<select id="resetOption" label="When a timeout has occurred, reset SQL Runtime Stats Collection Option back to one of the following:"
labelClass="zenLabel" enclosingClass="pL20"
displayList="0,1"
valueList="0,1"
value="0"
showEmpty="false"
/> 
</group>
</fieldSet>

<spacer height="10"/>

<html>
<div id="changeNote" class="changeNote" style="display:none;"></div>
</html>
</group>
</pane>
}

ClientMethod validate(ctl) [ Language = javascript ]
{
	var errorNote = document.getElementById('errorNote');
	var msg = '';
	var id = ctl.getProperty('id');
	var value = zen(id).getValue();
	if (value != null && isNaN(value)) {
		switch (id) {
			case 'txtHours':
				msg = $$$Text("Invalid hours");
				break;
			case 'txtMinutes':
				msg = $$$Text("Invalid minutes");
				break;
			case 'txtExpHour':
				msg = $$$Text("Invalid hour");
				break;
			case 'txtExpMinute':
				msg = $$$Text("Invalid minute");
				break;	
			}
		errorNote.innerHTML = msg;
		errorNote.style.display = 'block';
	}
	else {
		errorNote.style.display = 'none';
	}
}

ClientMethod changeOption(newOption) [ Language = javascript ]
{
	var txt = '';
	var option = parseInt(newOption);
	var json = this._settingsInfo;
	var proxy = json.proxy;
	var old = json.TurnOnStats;
	var changeNote = document.getElementById('changeNote');
	this._settingsInfo.newSetting = option;
	if (json.TurnOnStats != option) {
		txt = $$$Text("You are changing Option from %1 to %2")
		txt = txt.replace('%1',old);
		txt = txt.replace('%2',option);
		var index = old.toString()+option.toString();
		txt += proxy.changeOption[index];
		var image = '<img src="' + this.warningImage + '" width="16" height="16" border="0"/>&nbsp;';
		changeNote.innerHTML = image + txt;
		changeNote.style.display = 'block';
	} else {
		changeNote.style.display = 'none';
	}
	zen('idTimeout').setHidden(option<2);
}

ClientMethod changeTimeoutOption() [ Language = javascript ]
{
	var timeoutOption = zen('timeoutOption').getValue();	
	var flag = (timeoutOption == "T");
	var idHowLong = zen('idHowLong');
	var idDateTime = zen('idDateTime');
	idHowLong.setHidden(flag);
	idDateTime.setHidden(!flag);
	// if there is an error message shown for the other option, hide it now because that does not apply to this option.
	var errorNote = document.getElementById('errorNote');
	errorNote.style.display = 'none';
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent, ctl) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		ctl.ondatechangeHandler();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
/// 
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var errMsg = '';		
		var json = this._settingsInfo;
		var actionFlag = (!isNaN(parseInt(json.newSetting),10)) ? json.newSetting : json.TurnOnStats;
		var optionChanged = (actionFlag != json.TurnOnStats);
		var timeoutOption = zen('timeoutOption').getValue();
		var resetOption = zen("resetOption").getValue();
		var hours = '';
		var minutes = '';
		var ExpirationDate = '';
		var errorNote = document.getElementById('errorNote');		
		errorNote.style.display = 'none';
		if (actionFlag > 1 ) {		
			if (timeoutOption == 'M') {
				hours = parseInt(zen('txtHours').getValue(),10);
				if (isNaN(hours)) {
					hours = 0;
				}
				minutes = parseInt(zen('txtMinutes').getValue(),10);
				if (isNaN(minutes)) {
					minutes = 0;	
				}
				if ((hours===0) && (minutes===0)) {
					errMsg += $$$Text("Please enter valid number of hours or minutes for expiration. ");	
				} else {
					zen("txtHours").setValue(hours);
					zen("txtMinutes").setValue(minutes);
				}
			} else {
				ExpirationDate = zen('ExpirationDate').getValue();
				if (ExpirationDate == '') {
					//set it to today;
					ExpirationDate = json.Today;
					zen('ExpirationDate').setValue(ExpirationDate);		
				}
				hours = parseInt(zen('txtExpHour').getValue(),10);
				minutes = parseInt(zen('txtExpMinute').getValue(),10);
				if (isNaN(hours) || isNaN(minutes) || (hours < 0 || hours > 23) || (minutes < 0 || minutes > 59)) {
					errMsg += $$$Text("Please enter a valid expiration time. ");	
				} else {
					hours = (hours < 10) ? '0' + hours : hours;
					minutes = (minutes < 10) ? '0' + minutes : minutes;
					zen("txtExpHour").setValue(hours);
					zen("txtExpMinute").setValue(minutes);
				}
			}
		}
	
		if (errMsg) {
			errorNote.innerHTML = $$$Text("ERROR") + ": " + errMsg;
			errorNote.style.display = 'block';
			return false;
		}
		/// Save settings to server 
		var text = (optionChanged) ? $$$Text("You have changed the SQL Runtime Stats Collection Option. ") : $$$Text("Please confirm. ");
		var ok = confirm(text+$$$Text("Are you sure you want to proceed with these changes?"));
		if (!ok) {
			return false;
		}
		
		ok = this.SaveSQLStats(actionFlag,timeoutOption,hours,minutes,ExpirationDate,resetOption);		
		if (ok != '') {
			errorNote.innerHTML = ok;
			errorNote.style.display = 'block';
			return false;	
		}
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
		return false;
	}
	return true;
}

ClassMethod SaveSQLStats(actionFlag, timeoutOption, hours, minutes, ExpirationDate, resetOption) As %String [ ZenMethod ]
{
	Set returnActionFlag = 1
	Set terminateCond = ""
	Set collectFlag = ""
	If actionFlag > 1 {
		If timeoutOption = "M" {
			Set totalMinutes = hours * 60 + minutes
			Set terminateCond = "M:"_totalMinutes_":"_resetOption
		} Else {
			Set terminateCond = "T:"_$TR(ExpirationDate,"-","")_" "_hours_minutes_":"_resetOption
		}
	}
	Set SQLStatsFlag = $SYSTEM.SQL.SetSQLStats(actionFlag,returnActionFlag,collectFlag,terminateCond)
	// if no error returned from Save, send null back to client. Otherwise return error message for client to display.
	Set tError = $S(SQLStatsFlag?1"0 ".E:$SYSTEM.Status.GetErrorText(SQLStatsFlag),1:"")
	Quit tError
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var json = zen('jsonSettingsInfo').getContentObject();
	var proxy = this.getSettingMessages(json);
	this._settingsInfo = json;
	this._settingsInfo.proxy = proxy;
	
	zen("radTurnOnStats_0").setValue(json.TurnOnStats);
	for (var option=0; option<4; option++) {
		zen("radTurnOnStats_"+option).setProperty('caption',proxy.option[option]);
		zen("radTurnOnStats_"+option).setProperty('hint',proxy.hintOption[option]);
	}
	var displayList = proxy.option[0].replace(', ',' ') + ',' + proxy.option[1].replace(', ',' ');
	zen('resetOption').setProperty('displayList', displayList);
	zen('resetOption').setValue(json.resetOption);
	zen('timeoutOption').setValue(json.timeoutOption);
	this.changeOption(json.TurnOnStats);
	this.changeTimeoutOption();
	if (json.timeoutOption == "M") {
		zen('txtHours').setValue(json.Hour);
		zen('txtMinutes').setValue(json.Min);
	} else {
		if (json.ExpirationDisplay) {
			var exp = json.ExpirationDisplay;
			exp = exp.substring(0,exp.indexOf(" "));
			zen('ExpirationDate').setValue(exp);
		}
	}
	zen('txtExpHour').setValue(json.ExpHour);
	zen('txtExpMinute').setValue(json.ExpMin);
	// set expiration date default to today
	if (json.Expired || (zen('ExpirationDate').getValue().length<1)) {
		zen('ExpirationDate').setValue(json.Today);
	}
	// set earliest date selection to today 
	zen('ExpirationDate').setProperty('minDate',json.Today);
	if (proxy.settingNoteHTML) {
		document.getElementById("settingNote").innerHTML = proxy.settingNoteHTML;	
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("btnFinish").focus();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("SQL Runtime Stats Settings")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Quit $$$OK
}

}
