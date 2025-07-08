/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Activate New License Key dialog for Management Portal.
Class %CSP.UI.Portal.Dialog.LicenseActivate Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.License.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.LicenseActivate.zen";

Parameter EMSSERVICE = "License";

/// Displayed name of this page.
Parameter PAGENAME = "LicenseActivate";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property KeyFile As %String;

Property NoKeyActive As %Boolean [ InitialExpression = {$System.License.KeyLicenseCapacity()="Default license for configuration diagnosis."} ];

Property ReturnMsg As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
.Description {
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />
<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnPrint" controlClass="commandButton" caption="Print" title="Print the current license key information and contents of the key file selected" onclick="zenPage.doPrint(zen('txtLicenseFile').getValue());" />
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButtonDisabled" caption="Activate" onclick="zenPage.dialogFinish();" disabled="true"/>
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<vgroup enclosingStyle="padding:2px;" valign="top">
<hgroup labelPosition="left" label="License Key File:" cellVAlign="top">
<text id="txtLicenseFile" size="80" onchange="zenPage.showFile(zenThis.getValue());" onkeyup="zenPage.keyUp(zenEvent);"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('*.key');"/>
</hgroup>
<spacer height="4px"/>
<hgroup cellVAlign="top">
<html id="idCurrentContents" label="Active license information:" OnDrawContent="DrawCurrent"/>
<spacer width="5px"/>
<html id="idFileContents" OnDrawContent="DrawFileForActivate" labelStyle="white-space:nowrap;"/>
</hgroup>
</vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.IsEMSReadOnly = false;
	this.invokeSuper('onloadHandler',arguments);
   	zen("txtLicenseFile").focus();
}

/// User clicked one of the Browse buttons.
ClientMethod browseSelect(wildcard) [ Language = javascript ]
{
	var Dir = zen("txtLicenseFile").getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		this.showFile(zen("txtLicenseFile").getValue());
	}
}

ClientMethod showFile(filename) [ Language = javascript ]
{
	var msg = "";
	zen("txtLicenseFile").setValue(filename);
	if (filename != "") {
		msg = $$$Text("Contents of %1:");
		msg = msg.replace(/%1/g,zenEscapeHTML(filename));
		zen("btnFinish").setProperty('disabled',false);
		zen("btnFinish").setProperty('controlClass','commandButton');
	} else {
		zen("btnFinish").setProperty('disabled',true);
		zen("btnFinish").setProperty('controlClass','commandButtonDisabled');
	}
	zen("idFileContents").setProperty('label',msg);
	// We need to set this twice so the HTML encoding works correctly
	zen("idFileContents").setProperty('label',msg);
	zen("idFileContents").setProperty('seed',filename);
	this.resetMsg();
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			this.showFile(value);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var pass = true;
	try {
		var ctl = zen('txtLicenseFile');
		if (ctl.getValue() == "") {
			pass = false;
			ctl.setProperty("controlClass","zenInvalid");
			ctl.focus();
		} else {
			ctl.setProperty("controlClass","");
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	
	return pass;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		var st = this.validate();
		if (!st) {
			this.showMsg($$$Text("Please select a license key file."),1);
			return false;
		}
		var filename = zen("txtLicenseFile").getValue();
		var result = this.PrepareActivate(filename,this.NoKeyActive);
		if (result.ok == 1) {
			var msg = $$$Text("Activating file %1.");
			msg = msg.replace('%1',filename);
			if (result.Message != "") {
				result.Message = result.Message.replace(/!/g,'\n');
				msg = msg + "\n\n" + result.Message;
			}
			if (result.MessageRestart != "") {
				msg = msg + "\n\n" + result.MessageRestart;
			}
			msg = msg + "\n\n" + $$$Text("Are you sure you want to do this?");
			var ok = confirm(msg);

			if (ok) {
				var result2 = this.Activate(filename);
				if (result2.ok == 1) {
					this.ReturnMsg = result2.Message;
					return true;
				} else if (result.MessageRestart != "") {
					// activation could have failed because restart is required.
					return true;
				}
				this.showMsg(result2.ErrorMessage,1);
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
		}
		return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return false;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.ReturnMsg;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Activate a New License Key")
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
	
	Set ..KeyFile = $$$KEYFILENAME
	If (##class(%File).Exists(..KeyFile) && ##class(%SYSTEM.License).IsPendingActivation()) {
		Set ..%GetComponentById("txtLicenseFile").value = ..KeyFile
		Set ..%GetComponentById("idFileContents").seed = ..KeyFile
		Set ..%GetComponentById("idFileContents").label = $$$FormatText($$$Text("Contents of %1:"),..KeyFile)
		Set tSC = ##class(%SYSTEM.License).IsValidKey(..KeyFile,.RequiresRestart,.RestartReason)
		If $$$ISERR(tSC) Quit $$$OK
		If (RequiresRestart) {
			Set ..%GetComponentById("idRespond").value = ..RestartMsg
			Set ..%GetComponentById("idRespond").enclosingClass = "errorNote"
		} Else {
			Set ..%GetComponentById("idRespond").value = $$$FormatText($$$Text("Click [Activate] to activate the %1 in MGR."),..KeyFile)
			Set ..%GetComponentById("btnFinish").disabled = 0
			Set ..%GetComponentById("btnFinish").controlClass = "commandButton"
		}
		Set ..%GetComponentById("idRespond").hidden = 0
	}
	If ..NoKeyActive {
		Set ..%GetComponentById("idCurrentContents").hidden = 1
	}
	Quit $$$OK
}

ClassMethod DrawCurrent(pSeed As %String) As %Status
{
	Set tSC = ..GetLicenseInfo(.licArray)
	If $$$ISERR(tSC) Quit tSC

	&html<<div style="padding:2px;background:#fff;"><pre>>
	&html<[ConfigFile]<br/>>
	&html<FileType=#($ZCVT(licArray("FileType"),"O","HTML"))#<br/><br/>>
	&html<[License]<br/>>
	&html<LicenseCapacity=#($ZCVT(licArray("LicenseCapacity"),"O","HTML"))#<br/>>
	&html<CustomerName=#($ZCVT(licArray("CustomerName"),"O","HTML"))#<br/>>
	&html<OrderNumber=#($ZCVT(licArray("OrderNumber"),"O","HTML"))#<br/>>
	&html<ExpirationDate=#($ZCVT(licArray("ExpirationDate"),"O","HTML"))#<br/>>
	&html<AuthorizationKey=#($ZCVT(licArray("AuthorizationKey"),"O","HTML"))#<br/>>
	&html<MachineID=#($ZCVT(licArray("MachineID"),"O","HTML"))#<br/>>
	
	If licArray("ApplicationKey") '= "" {
		&html<<br/><br/>
		#($ZCVT(licArray("ApplicationKey"),"O","HTML"))#>	
	}

	&html<</pre></div>>

	Quit 1
}

Method DrawFileForActivate(pFile As %String) As %Status
{
	If (pFile '= "") {
		Quit ..DrawFile(pFile,0)
	}
	Quit $$$OK
}

/// This method is called when user first clicked the Activate button.
/// Evaluates the file user selected and return appropriate message. 
/// Note that this is a very basic check from the UI. Detailed check will be in the actual ##class(%SYSTEM.License).Upgrade().
/// When proxy.ok = 0 proxy.Message or proxy.MessageRestart indicates a confirmation is needed.
/// proxy.ErrorMessage means Activate cannot be done. 
ClassMethod PrepareActivate(pFile As %String, NoKeyActive As %Boolean) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Message = ""
	Set tProxy.MessageRestart = ""
	Set tProxy.ErrorMessage = ""
	Try {
		If '##class(%File).Exists(pFile) {
			Set tProxy.ErrorMessage = $$$TextHTML("File does not exist.")
			Throw
		}
		
		Set tSC = ##class(%SYSTEM.License).IsValidKey(pFile,.RequiresRestart,.RestartReason)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If 'NoKeyActive {
			Set HasReductions = ##class(%SYSTEM.License).CheckKeyForUpgrade(pFile,.Reductions,.tSC)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If HasReductions {
				Set tProxy.Message = $$$TextJS("Activating this key will:")
				If $D(Reductions("Cores")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$FormatText($$$TextJS("Reduce the number of supported cores from %1 to %2."),$LIST(Reductions("Cores"),1),$LIST(Reductions("Cores"),2))
				}
				If $D(Reductions("Users")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$FormatText($$$TextJS("Reduce the number of license units from %1 to %2."),$LIST(Reductions("Users"),1),$LIST(Reductions("Users"),2))
				}
				If $D(Reductions("Server")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$FormatText($$$TextJS("Change the supported server type from %1 to %2."),$LIST(Reductions("Server"),1),$LIST(Reductions("Server"),2))
				}
				If $D(Reductions("LicenseType")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$FormatText($$$TextJS("Change the supported license type from %1 to %2."),$LIST(Reductions("LicenseType"),1),$LIST(Reductions("LicenseType"),2))
				}
				If $D(Reductions("Product")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$FormatText($$$TextJS("Reduce the product level from %1 to %2."),$LIST(Reductions("Product"),1),$LIST(Reductions("Product"),2))
				}
				If $D(Reductions("Feature")) {
					Set tProxy.Message = tProxy.Message_"!- "_$$$TextJS("Remove support for the following features:")
					Set (feature,featureList) = ""
					For {
						Set feature = $ORDER(Reductions("Feature",feature))
						Quit:(feature = "")
						If (featureList = "") {
							Set featureList = featureList_" "_feature
						} Else {
							Set featureList = featureList_", "_feature
						}
					}
					Set tProxy.Message = tProxy.Message_featureList_"."
				}
			}
		}
		If RestartReason '= "" {
			Set tProxy.MessageRestart = $$$FormatText($$$TextJS("System restart will be required for this key: %1"),RestartReason)
		}
	Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If (tProxy.ErrorMessage = "") {
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	}
	Quit tProxy
}

/// This method is called when user already confirmed to override iris.key if exists.
ClassMethod Activate(pFile As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Try {
		If '##class(%File).Exists(pFile) {
			Set tProxy.ErrorMessage = $$$TextHTML("File does not exist.")
			Throw
		}
		Set tSC = ##class(%SYSTEM.License).IsValidKey(pFile,.RequiresRestart,.RestartReason)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tKeyFile = ##class(%File).NormalizeFilename($zu(12)_$$$KEYFILENAME)
		Set tFile = ##class(%File).NormalizeFilename(pFile)
		#; If the file is not in manager directory, copy it there. Save file name as 'iris.key'.
		Set tIsCacheKey = $ZCVT(tFile,"L") = $ZCVT(tKeyFile,"L")
		If 'tIsCacheKey {
			#; copy the file now
			Set source = ##class(%Stream.FileCharacter).%New()
			Set source.Filename = pFile
			If (source.SizeGet() = 0) {
				Set tProxy.ErrorMessage = $$$Text("Source file is empty.")
				Throw
			}
			Set sc = ##class(%File).CopyFile(pFile,tKeyFile,1)
			If 'sc {
				Set tProxy.ErrorMessage = $$$Text("Could not copy file.")
				Throw
			}  
		}
		Set tSC = ##class(%SYSTEM.License).Upgrade()
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.Message = $$$Text("License key activated.")
		If 'tIsCacheKey {
			Set tProxy.Message = tProxy.Message_" "_$$$FormatText($$$Text("File %1 has been copied to %2."),pFile,tKeyFile)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If (tProxy.ErrorMessage = "") {
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	}
	Quit tProxy
}

}
