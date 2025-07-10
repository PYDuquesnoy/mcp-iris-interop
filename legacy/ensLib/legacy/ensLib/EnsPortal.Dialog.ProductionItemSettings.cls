/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page allows the user to see the default values for specific settings and selectively reset them.
Class EnsPortal.Dialog.ProductionItemSettings Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// Displayed name of this page.
Parameter PAGENAME = "Production Specific Settings";

Parameter APPLYBUTTON = 0;

Parameter OKBUTTON = 0;

Parameter CANCELBUTTON = 1;

/// Production Name
Property ProductionName As %String(ZENURL = "PRODUCTION");

/// Item Name
Property ItemName As %String(ZENURL = "ITEMNAME");

/// Number of settings that are eligible to be reset
Property NoOfResetableSettings As %Integer [ InitialExpression = 0 ];

/// If true, user cannot modify the production in parent page
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.txtMessages {
	font-size: 10pt;
}

.headerMessage {
	font-size: 12pt;
	font-weight: bold;
}

.zenLabel {
	font-size: 10pt;
	padding-right: 5px;
	font-weight: normal;
	color: black;
}

.labelText {
	font-size: 10pt;
	font-weight: bold;
	color: black;
	padding: 0px;
	padding-right: 5px;
	border: 0px;
}

.boxedArea {
	font-size: 10pt;
	border: 1px solid #888888;
}

TABLE.DetailTable	{ 
	font-size: 10pt;
	border: 1px #222222 solid;
}

TABLE.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: left;
	padding: 2px;
}

TABLE.DetailTable TD { 
	text-align: left;
	padding: 2px;
}

TD.DetailValue A {
	width: 100%;
	padding-left: 3px;
	padding-right: 3px;
}

TD.DetailValue DIV {
	width: 100%;
}

TD.DetailLabel { 
	background: #EEDDFF;
	font-weight: bold;
}

.commandButtonGray {
	background: darkgray;
	color: rgb(67,67,67);
	text-decoration: none;
	border-left: 1px solid lightgray;
	border-right: 2px solid gray;
	border-top: 1px solid lightgray;
	border-bottom: 2px solid gray;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
}

.commandButtonGray:hover {
	background: rgb(53,107,141);
	color: rgb(235,235,235);
	background-image: url(portal/button_gray_hover.png);
	background-repeat: repeat-x;
}
</style>
}

/// This XML block defines the contents of this dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<spacer height="10" />
<html id="idHeader" OnDrawContent="DrawHeader" enclosingStyle="margin-left: 20px;"></html>
<spacer height="15" />
<html id="idDetails" OnDrawContent="DrawTable" enclosingStyle="margin-left: 20px;"></html>
<spacer height="10" />
<button id="btnDefault" caption="Restore Default" controlClass="commandButtonGray" enclosingStyle="margin-left: 20px;" onclick="zenPage.closeThisWindow();" title="Restore default values for the settings selected above and return to the Production configuration page" />
<spacer height="10" />
<html id="idFooter" OnDrawContent="DrawFooter" enclosingStyle="margin-left: 20px;"></html>
</pane>
}

/// Draw messages at the top of the popup and initialize variable to track changes.
Method DrawHeader(pSeed As %String) As %Status
{
	Set tMsg = $$$TextHTML("To revert a setting to its default value, select it in the table below and click button [Restore Default].")
	Set tMsg2 = $$$TextHTML("Only settings whose names are shown in black have been overridden and are available for selection.")
	Set tMsg3 = $$$TextHTML("Any Core settings that are specified using a System Default Setting are shown here for information.")
	Set tMsg4 = $$$TextHTML("To stop a listed Core setting from using a System Default Setting it is necessary to delete the System Default Setting.")
	&html<<div class="txtMessages">#(tMsg)#<br/>#(tMsg2)#<br/>#(tMsg3)#<br/>#(tMsg4)#</div>>
	Quit $$$OK
}

/// Display table based on settings for the Production or item.
/// $LB(Target,Value,ValueType,Default,DefaultType)
/// (WAS: $lb(Target,Name,Value,ValueType,Default,DefaultType,Description,Type,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired))
/// ValueType tells you where this Value is coming from:
/// $$$eConfigSettingValueTypeProperty:   this value is from class definition property default;
/// $$$eConfigSettingValueTypeSystem:     this value is from the default settings;
/// $$$eConfigSettingValueTypeProduction: this value is from Production definition.
/// $$$eConfigSettingValueTypeRegistry: this value is from Registry
/// DefaultType is similar to ValueType, it is the ValueType of the Default property:
/// $$$eConfigSettingValueTypeProperty: this default value is from class definition property default;
/// $$$eConfigSettingValueTypeSystem:   this default value is from the default settings.
/// pSeed = 0 is the initial load; pSeed = 1 is reset.
/// Black means it's defined in the Production;
/// Blue means it's coming from default settings;
/// Green means it's coming from class definition.
Method DrawTable(pSeed As %String) As %Status
{
	Set lbl0 = $$$TextHTML("Select")
	Set lbl1 = $$$TextHTML("Setting")
	Set lbl2 = $$$TextHTML("Applies to")
	Set lbl3 = $$$TextHTML("Current")
	Set lbl4 = $$$TextHTML("Value")
	Set lbl7 = $$$TextHTML("Value Source")
	Set lbl5 = $$$TextHTML("Default")
	Set lbl6 = $$$TextHTML("Default Source")
	Set lbl8 = $$$TextHTML("Source")
	Set title1 = $$$Text("Setting name - Place the cursor over a given setting to see its corresponding property name")
	Set title2 = $$$Text("For configuration items, indicates if it is a host setting or an adapter setting")
	Set title4 = $$$Text("Current value")
	Set title5 = $$$Text("Default value")
	Set title6 = $$$Text("Where the default value is coming from")
	Set title7 = $$$Text("Where the current value is coming from")
	Set lblLocal("ClassDef") = $$$TextHTML("Class definition")
	Set lblLocal("ProdDef") = $$$TextHTML("Production definition")
	Set lblLocal("DefaultSetting") = $$$TextHTML("System default setting")
	Set lblLocal("Registry") = $$$TextHTML("Service Registry")

	&html<<form id="theForm">
	<table class="DetailTable" border="1" cellspacing="0" cellpadding="4">
	<tr><th rowspan="2"><image src="images/Checkmark.png" align="right"></th>
	<th title="#(title1)#" rowspan="2">#(lbl1)#</th>
	<th title="#(title2)#" rowspan="2">#(lbl2)#</th>
	<th colspan="2" style="border-bottom:1px solid gray;">#(lbl3)#</th>
	<th colspan="2" style="border-bottom:1px solid gray;">#(lbl5)#</th>
	</tr>
	<tr><th title="#(title4)#" style="border-top:0px;">#(lbl4)#</th>
	<th title="#(title7)#" style="border-top:0px;">#(lbl8)#</th>
	<th title="#(title5)#" style="border-top:0px;">#(lbl4)#</th>
	<th title="#(title6)#" style="border-top:0px;">#(lbl8)#</th>>
	
	Set field = ""
	For {
		Set field = $O(%session.Data("ProdConf_Settings",field))
		Quit:field=""
		Do ..DrawRow(field,.lblLocal)
	}

	&html<</table></form>>

	Quit $$$OK
}

/// Draw a row for a setting.
Method DrawRow(name As %String, ByRef lblLocal As %String)
{
	// %session.Data("ProdConf_Settings",aName.GetAt(i)) = $LB(aTarget.GetAt(i),aValue.GetAt(i),aValueSource.GetAt(i),aDefaultValue.GetAt(i),aDefaultSource.GetAt(i))

	Set btnDefault = $$$Text("Default")	
	Set data = %session.Data("ProdConf_Settings",name)
	Set default = $LG(data,4)
	Set id = "chk"_name
	Set idCurrent = "fld"_name
	Set idValSource = "vs"_name
	Set idDefault = "def"_name
	Set idProp = "lbl"_name
	Set idDefColor = "color"_name
	Set idOldValue = "old"_name
	Set txtName = $$$GetLocalizedName(name)
	Set target = $LG(data,1)
	Set value = $LG(data,2)
	Set ValueType = $LG(data,3)
	Set DefaultType = $LG(data,5)
	Set dt = $Case(DefaultType,$$$eConfigSettingValueTypeProduction:lblLocal("ProdDef"),$$$eConfigSettingValueTypeSystem:lblLocal("DefaultSetting"),$$$eConfigSettingValueTypeRegistry:lblLocal("Registry"),:lblLocal("ClassDef"))
	Set vt = $Case(ValueType,$$$eConfigSettingValueTypeProduction:lblLocal("ProdDef"),$$$eConfigSettingValueTypeSystem:lblLocal("DefaultSetting"),$$$eConfigSettingValueTypeRegistry:lblLocal("Registry"),:lblLocal("ClassDef"))
 	Set defColor = $Case(DefaultType,$$$eConfigSettingValueTypeSystem:"blue",:"darkgreen")
 	Set labelColor = $Case(ValueType,$$$eConfigSettingValueTypeProduction:"black",$$$eConfigSettingValueTypeSystem:"blue",$$$eConfigSettingValueTypeRegistry:"brown",:"darkgreen")
   	Set backcolor = ""
   	Set ismodif = 0
   	If $D(%session.Data("ProdConf_Settings_Reset",0,name)) {
   		// If user has modified the item, then it is no longer a default.
   		Set ismodif = 1
	   	Set backcolor = "yellow"
	   	Set labelColor = "black"
	   	Set value = %session.Data("ProdConf_Settings_Reset",0,name)
   	}
   	If $D(%session.Data("ProdConf_Settings_Reset",1,name)) {
   		// If user has changed it to default, then use default's color and value.
	   	Set backcolor = "yellow"
	   	Set labelColor = defColor
	   	Set value = default
   	}
	&html<<tr><td align="center">>
	If labelColor="black" {
		Set ..NoOfResetableSettings = ..NoOfResetableSettings+1
		&html<<input type="checkbox" id="#(id)#" name="#(id)#" onclick="zenPage.setToDefault('#(name)#','#(ismodif)#');"></td>>
	}
	Else  {
		&html<&nbsp;>
	}

	&html<
	<td id="#(idProp)#" nowrap class="label" style="color:#(labelColor)#;" title="#(name)#"><b>#($ZCVT(txtName,"O","HTML"))#</b></td>
	<td nowrap>#($S(target'="":$ZCVT(target,"O","HTML"),1:"&nbsp;"))#</td>
	<td id="#(idCurrent)#" nowrap style="background:#(backcolor)#">#($S(value'="":$ZCVT(value,"O","HTML"),1:"&nbsp;"))#</td>
	<td id="#(idValSource)#" nowrap>#(vt)#</td>
	<td id="#(idDefault)#" nowrap>#($S(default'="":$ZCVT(default,"O","HTML"),1:"&nbsp;"))#</td>
	<td nowrap>#(dt)#</td>
	<input type="hidden" id="#(idDefColor)#" value="#(defColor)#"></tr>
	<input type="hidden" id="#(idOldValue)#" value="#($ZCVT(value,"O","HTML"))#"></tr>>
}

Method DrawFooter(pSeed As %String) As %Status
{
	If '..NoOfResetableSettings {
		&html<<div class="txtMessages" style="color:red;font-weight:bold;">#($$$TextHTML("All settings above already have default values and cannot be reset."))#
		<br/>#($$$TextHTML("Please close this window to return."))#</div>>
	}
	&html<<br/>
	<div class="boxedArea">
	<table border="0">
	<tr valign="top">
		<td style="font-size: 10pt; color: #888888;"><b>#($$$TextHTML("Legend"))# &nbsp;</b></td>
		<td><table class="txtMessages" style="margin-left:10px;font-size:.9em;" border="0" cellspacing="0" cellpadding="4">
			<tr><td align="right" nowrap><div style="color:black;font-weight:bold;">#($$$TextHTML("Black: "))#</div></td><td>&nbsp;</td>
				<td nowrap>#($$$TextHTML("Current value comes from the Production definition."))#</td></tr>
			<tr><td align="right" nowrap><div style="color:darkgreen;font-weight:bold;">#($$$TextHTML("Green: "))#</div></td><td>&nbsp;</td>
				<td nowrap>#($$$TextHTML("Current value comes from the business host class definition."))#</td></tr>
			<tr><td align="right" nowrap><div style="color:blue;font-weight:bold;">#($$$TextHTML("Blue: "))#</div></td><td>&nbsp;</td>
				<td nowrap>#($$$TextHTML("Current value comes from system default settings."))#</td></tr>
			<tr><td>&nbsp;</td><td>&nbsp;</td>
				<td>#($$$TextHTML("(You can use the System Default Settings page in the portal to configure default settings.)"))#</td></tr>
			<tr><td align="right" nowrap><div style="color:brown;font-weight:bold;">#($$$TextHTML("Brown: "))#</div></td><td>&nbsp;</td>
				<td nowrap>#($$$TextHTML("Current value comes from Service Registry setting."))#</td></tr>	
			</table></td>
	</tr>
	</table>
	</div>>
	Quit $$$OK
}

/// Handle check/uncheck of a setting.
ClientMethod setToDefault(name, isMod) [ Language = javascript ]
{
	if (this.readOnly) {
		alert($$$Text('Production is set to read only. This page is for information only.'));
		return;
	}
	var ctrl = self.document.getElementById('chk' + name);
	var isChecked = ctrl.checked;
	if (isChecked) {
		// User selected this setting to acquire default value; highlight value as modified and set property's name and value with default's color and value
		document.getElementById('fld' + name).innerHTML = document.getElementById('def' + name).innerHTML;
		document.getElementById('fld' + name).style.background = 'yellow';
		document.getElementById('lbl' + name).style.color = document.getElementById('color' + name).value;
	}
	else {
		// User unselected this setting; revert to previous style and value
		document.getElementById('fld' + name).innerHTML = document.getElementById('old' + name).value;
		if (isMod != '1') { document.getElementById('fld' + name).style.background = document.bgColor; }
		document.getElementById('lbl' + name).style.color = 'black';
	}
	var isChanged = zenPage.StateTrack(isChecked,name);
	if (isChanged) {
		zenSetProp('btnDefault','controlClass','commandButton');
	}
	else {
		zenSetProp('btnDefault','controlClass','commandButtonGray');
	}
}

/// Set session info to keep track of changes made here.
ClassMethod StateTrack(pChecked As %Boolean, pName As %String) As %Boolean [ ZenMethod ]
{
	If (pChecked) {
		Set %session.Data("ProdConf_Settings_Reset",1,pName) = ""
	}
	Else {
		Kill %session.Data("ProdConf_Settings_Reset",1,pName)
	}
	Quit ..ThereAreModifications()
}

/// Return a value indicating if the user has modified any of the settings in this window.
ClassMethod ThereAreModifications() As %Boolean [ ZenMethod ]
{
	Quit $O(%session.Data("ProdConf_Settings_Reset",1,""))'=""
}

/// Close the dialog popup; the modifications are passed back via session data.
ClientMethod closeThisWindow() [ Language = javascript ]
{
	if (this.readOnly) {
		return false;
	} else if (zenPage.ThereAreModifications()) {
		zenPage.dialogFinish();
	}
	else {
		alert($$$Text('There are no settings to be restored'));
		return false;
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Select Default For Settings","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If %page.ItemName = -1 {
		Set tTitle = $$$Text("Restore Default Values for Selected Production Settings")
	}
	Else {
		Set tTitle = $$$FormatText($$$Text("Restore Default Values for Selected Settings of Item '%1'"),$ZCVT(%page.ItemName,"O","HTML"))
	}
	Quit tTitle
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Production %1"),$ZCVT(%page.ProductionName,"O","HTML"))
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnCancel').setProperty('title',$$$Text("Close this window and return without changing anything"));
}

/// Handle where Production Configuration page marked production as read and only/can't edit
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		var opener = this.getOpener();
		if ( opener ) {
			if (opener.zenPage.readOnly || !opener.zenPage.canEdit) {
				this.readOnly = true;
				var stdTitles = document.getElementsByClassName('stdTitle');
				if (stdTitles) {
					var stdTitleElement = stdTitles[0];
					if (stdTitleElement) {
						if (this.ItemName == -1) {
							stdTitleElement.innerText = $$$Text('Current and Default Values for Production Settings.');
						} else {
							stdTitleElement.innerText = $$$Text('Current and Default Values for Selected Item: '+zenEscapeHTML(this.ItemName));
						}
					}
				}
				var txtMessages = document.getElementsByClassName('txtMessages');
				if (txtMessages) {
					var txtMessageElement = txtMessages[0];
					if (txtMessageElement) {
						txtMessageElement.innerText = $$$Text('Information Only - Production set to Read Only.');
					}
					if (this.NoOfResetableSettings == 0) {
						var warningtxtMessageElement = txtMessages[1];
						if (warningtxtMessageElement) {
							warningtxtMessageElement.innerText = '';
						}
					}
				}
				var inputTags = document.getElementsByTagName('input');
				if (inputTags) {
					for (var c = 0 ; (c < inputTags.length) ; c++ ) {
						if ((inputTags[c].type) === 'checkbox') {
							inputTags[c].setAttribute('type','hidden');
						}
					}
				}
				var btnRestore = zen('btnDefault');
				if (btnRestore) {
					btnRestore.setProperty('hidden',true);
				}
			} else {
				this.readOnly = false;
			}
		}
	} catch (ex) {
		/*	Fail silently as unexpected error in the above ought not to prevent page loading.
			Production configuration page will still protect at update attempts if read only
		*/
		this.readOnly = false; 
	}
}

}
