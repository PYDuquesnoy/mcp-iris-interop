/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.TransformSelector Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_Code, %Ens_RoutingRules or %Ens_BusinessRules
Parameter RESOURCE = "%Ens_Rules:WRITE,%Ens_Code:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE";

Parameter APPLYBUTTON = 0;

/// The current value of the control.
Property CURRVALUE As %String(ZENURL = "VALUE");

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none">
<group  enclosingStyle="padding:20;" layout="none">
<selector id="transforms" title="Available transforms" size="80" label="Transforms" context="Ens.ContextSearch/Classes?super=Ens.DataTransform&amp;hideAbstract=1&amp;system=1" multiSelect="true"/>
<spacer height="20"/>
<button id="dtlEditorLink" caption="DTL Editor" controlClass="commandButton" title="Launch the DTL editor. If there are multiple transforms then only the first will be opened." onclick="zenPage.showDTLEditor();"/>
<spacer height="20"/>
</group>
</pane>
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Data Transform Selector")
}

Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Choose any number of transforms from the list")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('transforms').getValue();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSelector = ..%GetComponentById("transforms")
	Set tSelector.value = ..CURRVALUE
	Quit ##super()
}

/// Open DTL editor in a new window.
ClientMethod showDTLEditor() [ Language = javascript ]
{
	if (this.studioMode) { return; }
	var dtl = zen('transforms').getValue();
	if (dtl=='') {
		alert($$$Text('Please select a data transformation class.'));
		return;
	}
	var dtlarray=dtl.split(',');
	var onedtl=dtlarray[0];
	onedtl += '.DTL';
	var url = zenLink('EnsPortal.DTLEditor.zen');
	if (url.indexOf('?') < 0) { url += '?'; }
	else { url += '&'; }
	var win = window.open(url + 'DT='+encodeURIComponent(onedtl));
	try {
		win.focus();
	}
	catch(ex) {}
}

/// Handle where Rule editor marked Rule as read only/can't edit
ClientMethod ondialogStart() [ Internal, Language = javascript ]
{
	try {
		var opener = this.getOpener();
		if ( opener ) {
			if (opener.zenPage.readOnly || !opener.zenPage.canEdit) {
				/*	Change sub title and disable OK and drop down.
					Parent page will not use if changes.
				*/
				var stdSubTitles = document.getElementsByClassName('stdSubTitle');
				if (stdSubTitles) {
					var stdSubTitleElement = stdSubTitles[0];
					if (stdSubTitleElement) stdSubTitleElement.innerText = $$$Text('Rule cannot be modified - provides link to DTL Editor only');
				}
				var selectorIcons = document.getElementsByClassName('selectorIcon');
				if (selectorIcons) {
					var selectorIconElement = selectorIcons[0];
					if (selectorIconElement) selectorIconElement.setAttribute('onclick','');
				}
				var btnOK = zen('btnOK');
				if (btnOK) {
					btnOK.setProperty('disabled',true);
					btnOK.setProperty('controlStyle',zenPage.disabledStyle);
				}
			}
		}
	} catch (ex) {/*fail silently as unexpected error in the above ought not to prevent page loading */}
}

}
