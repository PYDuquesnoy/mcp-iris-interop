/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Memory and Startup
Class %CSP.UI.Portal.MemoryStartup Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Memory and Startup";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.MemoryStartup.zen";

Parameter HELPADDRESS = "Home,Configuration,Memory and Startup";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not allow this page to auto-switch namespaces if $NAMESPACE is specified
Parameter AUTONS As BOOLEAN = 0;

Parameter EMSSERVICE = "Config";

/// Holds the system default values for DB memory allocation, comma-delimited
Property AutoDBMem As %String;

/// Holds the system default value for routine cache memory allocation
Property Autoroutines As %Integer [ InitialExpression = {##class(%SYS.System).GetRoutineCache()} ];

Property DBSizesAllowed As %String;

Property Is32Bit As %Boolean [ InitialExpression = {$zu(40,0,2) = 4} ];

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property NotWindows As %Boolean;

/// Holds the current value for per-process memory
Property Oldbbsiz As %Integer;

/// Holds the current values for DB memory allocation, comma-delimited
Property OldDBMem As %String;

/// Holds the current Superserver port
Property OldDefaultPort As %Integer;

/// Holds the current database cache setting (automatic or manual configuration)
Property OldManualConfig As %Boolean;

/// Holds the current routine cache setting (automatic or manual configuration)
Property OldManualRoutines As %Boolean;

/// Holds the current value for routine cache memory allocation
Property Oldroutines As %String;

Property RestartMsg As %String [ InitialExpression = {$$$Text("Modification saved. You must restart the system for the new values to take effect.")} ];

Property InvalidMessage As %String [ InitialExpression = {$$$Text("Invalid value.")} ];

Property EditPort As %ZEN.Datatype.integer(ZENURL = "EditPort");

XData Style
{
<style type="text/css">
.EditForm {
	width: 640px;
}
.zenLabelDisabled {
	color: #404040;
	font-size: 12px;
	font-weight: bold;
	padding-right: 3px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group labelPosition="left" align="center">
<label id="Platform" label="Platform:" controlClass="normal"/>
</group>
<group id="restartMsg" hidden="true">
<label label="System Restart Pending - There are changes saved that will not take effect until restart." labelClass="rednote"/>
</group>
<spacer height="5px"/>
<group cellStyle="padding:4px;" labelPosition="left">
<spacer height="5px" enclosingStyle="border-bottom:1px black solid;"/>
<radioSet id="radConfigure"
label="Configure Database Cache (Global Buffers)"
displayList="Initial (25% of physical memory),Specify Amount"
valueList="0,1"
value="0"
onchange="zenPage.changeRadio(zenThis.getValue(),0);zenPage.doModified();"
layout="vertical"
labelStyle="vertical-align:top;"
 />
<text id="globals4kb" label="Memory Allocated for 4KB Database Cache (MB)" title="System memory allocated as global buffers for 4KB block-size databases." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<text id="globals8kb" label="Memory Allocated for 8KB Database Cache (MB)" title="System memory allocated as global buffers for 8KB block-size databases." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<text id="globals16kb" label="Memory Allocated for 16KB Database Cache (MB)" title="System memory allocated as global buffers for 16KB block-size databases." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<text id="globals32kb" label="Memory Allocated for 32KB Database Cache (MB)" title="System memory allocated as global buffers for 32KB databases." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<text id="globals64kb" label="Memory Allocated for 64KB Database Cache (MB)" title="System memory allocated as global buffers for 64KB databases." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<spacer height="5px" enclosingStyle="border-bottom:1px black solid;"/>
<radioSet id="radRoutines"
label="Configure Routine Cache"
displayList="Automatic (based on database cache),Specify Amount"
valueList="0,1"
value="0"
onchange="zenPage.changeRadio(zenThis.getValue(),1);zenPage.doModified();"
layout="vertical"
labelStyle="vertical-align:top;"
 />
<text id="routines" label="Memory Allocated for Routine Cache (MB)" hint="Required. (36-65536)" title="System memory allocated and used for caching server code." size="10" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<spacer height="10px" enclosingStyle="border-top:1px black solid;"/>
<text id="bbsiz" label="Maximum Per-Process Memory (KB)" size="10" hint="Required. (256-2147483647 or -1)" hintStyle="padding-top:2px;" onchange="zenPage.doModified();"/>
<checkbox id="AutoMode" label="Auto-start on System Boot" title="Automatically start this instance when the operating system starts up." onchange="zenPage.doModified();"/>
<text id="DefaultPort" label="Superserver Port Number" size="10" hint="Required." title="This is the TCP port used to accept incoming client requests." onchange="zenPage.doModified();"/>
<combobox id="SystemMode" label="System Mode" editable="true" unrestricted="true" displayList="Live System,Test System,Development System,Failover System" valueList="LIVE,TEST,DEVELOPMENT,FAILOVER" title="Provides a visual indicator within the Management Portal indicating how this system is used." onchange="zenPage.doModified();"/>
</group>
</group>
</form>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	zen("radConfigure").focus();
}

ClientMethod clearError(ctl) [ Language = javascript ]
{
	ctl.setProperty("hintClass","helpText");
	if (ctl.getProperty("hint") == this.InvalidMessage) {
		// reset the hint if it's "invalid value"
		ctl.setProperty("hint","");
	}
}

ClientMethod changeRadio(newVal, routines) [ Language = javascript ]
{
	var newVal = parseInt(newVal);
	var resetValue = false;
	
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	if (routines) {
		zen('routines').setProperty('disabled',!newVal);
		this.clearError(zen('routines'));
	} else {
		zen('globals4kb').setProperty('disabled',!newVal);
		zen('globals8kb').setProperty('disabled',!newVal);
		zen('globals16kb').setProperty('disabled',!newVal);
		zen('globals32kb').setProperty('disabled',!newVal);
		zen('globals64kb').setProperty('disabled',!newVal);
		this.clearError(zen('globals4kb'));
		this.clearError(zen('globals8kb'));
		this.clearError(zen('globals16kb'));
		this.clearError(zen('globals32kb'));
		this.clearError(zen('globals64kb'));
	}
	
	if (newVal == 0) {
		// changing to auto, reset to auto memory values
		if (routines) {
			zen('routines').setValue(zenPage.Autoroutines);
		} else {
			var memArray = zenPage.AutoDBMem.split(',');
			resetValue = true;
		}
	} else {
		//changing to manual
		if (routines && zenPage.OldManualRoutines) {
			zen('routines').setValue(zenPage.Oldroutines);
			if (zenPage.Oldroutines.split(',').length>1) {
				zen('routines').setProperty('disabled', true);
			}
		}
		if (!routines && zenPage.OldManualConfig) {
			var memArray = zenPage.OldDBMem.split(',');
			resetValue = true;
		}
	}
	if (resetValue) {
		zen('globals4kb').setValue(memArray[1]);
		zen('globals8kb').setValue(memArray[2]);
		zen('globals16kb').setValue(memArray[3]);
		zen('globals32kb').setValue(memArray[4]);
		zen('globals64kb').setValue(memArray[5]);
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// validate the control value. pass is either "true" or "false" indicating if there is already a field failed pass validation.<br>
/// defaultVal - value to set into the field if it is blank<br>
/// checkRange - if true, additionally check whether the number is in range: minVal - maxVal, inclusive<br>
/// validVal - if specified, an additional valid value outside the range
ClientMethod validateRequiredAndRange(ctl, pass, defaultVal, checkRange, minVal, maxVal, validVal) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	
	if (value == '') {
		// if blank, use the default value
		value = defaultVal;
		ctl.setValue(value);
	} else if (isNaN(value)) {
		if ((validVal == undefined) || (value != validVal)) {
			// fail if not numeric
			ok = false;
		}
	} else if (value < 0) {
		if ((validVal == undefined) || (value != validVal)) {
			// fail if negative
			ok = false;
		}
	} else if ((checkRange == true) && ((value < minVal) || (value > maxVal))) {
		if ((validVal == undefined) || (value != validVal)) {
			// fail if not in range
			ok = false;
		}
	}
	
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		if (ctl.getProperty('hint') == '') {
			// if there's no existing hint to turn red, set hint as "invalid value"
			ctl.setProperty('hint',this.InvalidMessage);
		}
		if (pass) {
			this.FirstFailed = ctl.getProperty("id");
		}		
	} else {
		this.clearError(ctl);
	}
	
	return ok;
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	var pass = true;
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	if (proxy.ManualConfig) {
		var memArray = zenPage.OldDBMem.split(',');
		if (!zenPage.validateRequiredAndRange(zen("globals4kb"),pass,memArray[1],
		                                      memArray[1] > 0,
		                                      16,
		                                      proxy.Is32Bit ? 2044 : 8388607)) pass = false;
		if (!zenPage.validateRequiredAndRange(zen("globals8kb"),pass,memArray[2],
		                                      true /* always need some 8k buffers */,
		                                      32,
		                                      proxy.Is32Bit ? 2044 : 16777215)) pass = false;
		if (!zenPage.validateRequiredAndRange(zen("globals16kb"),pass,memArray[3],
		                                      memArray[3] > 0,
		                                      64,
		                                      proxy.Is32Bit ? 2044 : 33554431)) pass = false;
		if (!zenPage.validateRequiredAndRange(zen("globals32kb"),pass,memArray[4],
		                                      memArray[4] > 0,
		                                      128,
		                                      proxy.Is32Bit ? 2044 : 67108863)) pass = false;
		if (!zenPage.validateRequiredAndRange(zen("globals64kb"),pass,memArray[5],
		                                      memArray[5] > 0,
		                                      256,
		                                      proxy.Is32Bit ? 2044 : 134217727)) pass = false;
	}
	if (proxy.ManualRoutines) {
		var rtns = zen("routines");
		if (rtns.getValue()!=zenPage.Oldroutines && !zenPage.validateRequiredAndRange(rtns,pass,zenPage.Oldroutines,true,36,65536)) pass = false;
	}
	if (!zenPage.validateRequiredAndRange(zen("bbsiz"),pass,zenPage.Oldbbsiz,true,256,2147483647,-1)) pass = false;
	if (!zenPage.validateRequiredAndRange(zen("DefaultPort"),pass,zenPage.OldDefaultPort,true,1,65535)) pass = false;
	
	zenSynchronousMode = oldSynchronousMode;
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Is32Bit = zenPage.Is32Bit;
		proxy.ManualConfig = parseInt(zen('radConfigure').getValue());
		proxy.ManualRoutines = parseInt(zen('radRoutines').getValue());

		if (!this.IsEMSReadOnly && !zenPage.validate(proxy)) {
			zenPage.afterValidate();
			return false;
		}
		
		proxy.OldManualConfig = zenPage.OldManualConfig;
		proxy.OldManualRoutines = zenPage.OldManualRoutines;
		if (proxy.ManualConfig) {
			proxy.globals4kb = parseInt(zen('globals4kb').getValue());
			proxy.globals8kb = parseInt(zen('globals8kb').getValue());
			proxy.globals16kb = parseInt(zen('globals16kb').getValue());
			proxy.globals32kb = parseInt(zen('globals32kb').getValue());
			proxy.globals64kb = parseInt(zen('globals64kb').getValue());
			
			var memArray = zenPage.OldDBMem.split(',');
			proxy.Oldglobals4kb = parseInt(memArray[1]);
			proxy.Oldglobals8kb = parseInt(memArray[2]);
			proxy.Oldglobals16kb = parseInt(memArray[3]);
			proxy.Oldglobals32kb = parseInt(memArray[4]);
			proxy.Oldglobals64kb = parseInt(memArray[5]);
		}
		if (proxy.ManualRoutines) {
			var rtns = zen('routines').getValue();
			proxy.routines = (rtns==zenPage.Oldroutines? zenPage.Oldroutines: parseInt(rtns));
			proxy.Oldroutines = zenPage.Oldroutines;
		}
		proxy.bbsiz = parseInt(zen('bbsiz').getValue());
		proxy.NotWindows = zenPage.NotWindows;
		proxy.AutoMode = zen('AutoMode').getValue();
		proxy.DefaultPort = parseInt(zen('DefaultPort').getValue());
		proxy.SystemMode = zen('SystemMode').getValue();
		proxy.RestartMsg = zenPage.RestartMsg;
		proxy.IsEMSReadOnly = this.IsEMSReadOnly;
	
		var result = zenPage.SaveData(proxy);
		zenPage.afterSave(result);
		if (result && (result.ok == 1)) {
			this.setButtonCaption("Close");
			this.Oldbbsiz = proxy.bbsiz;
			this.OldDBMem = "0,"+proxy.globals4kb+","+proxy.globals8kb+","+proxy.globals16kb+","+proxy.globals32kb+","+proxy.globals64kb;
			this.OldDefaultPort = proxy.DefaultPort;
			this.OldManualConfig = proxy.ManualConfig;
			this.OldManualRoutines = proxy.ManualRoutines;
			this.Oldroutines = proxy.routines;
		}
	} catch (ex) {
		alert("Error: " + ex);
	}
}

ClientMethod doModified() [ Language = javascript ]
{
	this.invokeSuper('doModified',arguments);
	this.setButtonCaption("Cancel");
}

ClientMethod setButtonCaption(text) [ Language = javascript ]
{
	var btn = document.getElementById('command_btnCancel');
	if (text == "Close") {
		btn.innerHTML = '<nobr>'+$$$Text('Close')+'</nobr>';
		btn.title = $$$Text('Return to menu');
	} else {
		btn.innerHTML = '<nobr>'+$$$Text('Cancel')+'</nobr>';
		btn.title = $$$Text('Return without saving new changes');
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""
	
	Try {
		If (pProxy.NotWindows = 0) {
			Set tSC = ##class(Config.WinStartup).SetServiceAutoStartByNumber(pProxy.AutoMode)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		If 'pProxy.IsEMSReadOnly {
			Set tSC = ##Class(Config.Startup).Get(.Properties)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			Set Properties("SystemMode") = pProxy.SystemMode
			Set ^%SYS("SystemMode") = pProxy.SystemMode
			If (pProxy.DefaultPort '= Properties("DefaultPort")) {
				Set tProxy.Message = pProxy.RestartMsg
				Set Properties("DefaultPort") = pProxy.DefaultPort
			}
			Set tSC = ##Class(Config.Startup).Modify(.Properties)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			Kill Properties
			
			Set tSC = ##Class(Config.Miscellaneous).Get(.Properties)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			Kill Properties
			
			Set tSC = ##Class(Config.config).Get(.Properties)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			If (pProxy.ManualConfig) {
				Set globals4kb = pProxy.globals4kb
				Set globals8kb = pProxy.globals8kb
				Set globals16kb = pProxy.globals16kb
				Set globals32kb = pProxy.globals32kb
				Set globals64kb = pProxy.globals64kb
			} Else {
				Set (globals4kb,globals8kb,globals16kb,globals32kb,globals64kb) = 0
			}
			If (pProxy.ManualRoutines) {
				Set routines = pProxy.routines
			} Else {
				Set routines = 0
			}
			Set Properties("routines") = routines
			Set Properties("globals2kb") = 0
			Set Properties("globals4kb") = globals4kb
			Set Properties("globals8kb") = globals8kb
			Set Properties("globals16kb") = globals16kb
			Set Properties("globals32kb") = globals32kb
			Set Properties("globals64kb") = globals64kb
			Set Properties("bbsiz") = pProxy.bbsiz
			Set tSC = ##Class(Config.config).Modify(.Properties)
			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			Kill Properties
			If ((pProxy.routines '= pProxy.Oldroutines) ||
			    (pProxy.globals4kb '= pProxy.Oldglobals4kb) ||
			    (pProxy.globals8kb '= pProxy.Oldglobals8kb) ||
			    (pProxy.globals16kb '= pProxy.Oldglobals16kb) ||
			    (pProxy.globals32kb '= pProxy.Oldglobals32kb) ||
			    (pProxy.globals64kb '= pProxy.Oldglobals64kb) ||
			    (pProxy.ManualConfig '= pProxy.OldManualConfig) ||
			    (pProxy.ManualRoutines '= pProxy.OldManualRoutines)) {
				Set tProxy.Message = pProxy.RestartMsg
			}
		}
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("System Memory and Startup Settings")
		
	If ##class(Config.CPF).PendingRestart() {
		Set ..%GetComponentById("restartMsg").hidden = 0
	}
	// Get auto memory values
	Set Mem = $listtostring($System.Util.GlobalBuffers())
	Set blksize = 1 
	For i=1:1:6 {
		Set blksize = blksize*2
		Set $p(Mem,",",i) = $p(Mem,",",i)*blksize\1024
	}
	Set ..AutoDBMem = Mem
	Set Autoglobals4kb = $P(Mem,",",2)
	Set Autoglobals8kb = $P(Mem,",",3)
	Set Autoglobals16kb = $P(Mem,",",4)
	Set Autoglobals32kb = $P(Mem,",",5)
	Set Autoglobals64kb = $P(Mem,",",6)
	
	// Get Config.config properties
	Kill Properties
	Set tSC = ##class(Config.config).Get(.Properties)
	If $$$ISERR(tSC) Quit tSC
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly||..EditPort Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}

	Set ..Oldbbsiz = Properties("bbsiz")
	Set ..Oldroutines = Properties("routines")
	Set globals4kb = Properties("globals4kb")
	Set globals8kb = Properties("globals8kb")
	Set globals16kb = Properties("globals16kb")
	Set globals32kb = Properties("globals32kb")
	Set globals64kb = Properties("globals64kb")
	Set ..OldDBMem = "0,"_globals4kb_","_globals8kb_","_globals16kb_","_globals32kb_","_globals64kb
	
	Set ..OldManualConfig = $S(+(globals4kb + globals8kb + globals16kb + globals32kb + globals64kb)=0:0,1:1)
	Set ..OldManualRoutines = (..Oldroutines[",") || (''..Oldroutines)
	If ..OldManualConfig {
		Set ..%GetComponentById("radConfigure").value = 1
	} Else {
		Set ..%GetComponentById("globals4kb").value = Autoglobals4kb
		Set ..%GetComponentById("globals8kb").value = Autoglobals8kb
		Set ..%GetComponentById("globals16kb").value = Autoglobals16kb
		Set ..%GetComponentById("globals32kb").value = Autoglobals32kb
		Set ..%GetComponentById("globals64kb").value = Autoglobals64kb
		Set ..%GetComponentById("globals4kb").disabled = 1
		Set ..%GetComponentById("globals8kb").disabled = 1
		Set ..%GetComponentById("globals16kb").disabled = 1
		Set ..%GetComponentById("globals32kb").disabled = 1
		Set ..%GetComponentById("globals64kb").disabled = 1
	}
	If ..OldManualRoutines {
		Set ..%GetComponentById("radRoutines").value = 1
		If ..Oldroutines["," {
			Set ..%GetComponentById("routines").disabled = 1
		}
	} Else {
		Set ..%GetComponentById("routines").value = ..Autoroutines
		Set ..%GetComponentById("routines").disabled = 1
	}
	
	If ..IsEMSReadOnly||..EditPort {
		Set ..%GetComponentById("radConfigure").disabled = 1
	}
	
	If ..Is32Bit {
		Set ..%GetComponentById("globals4kb").hint = "Required. (16-2044 or 0)"
		Set ..%GetComponentById("globals8kb").hint = "Required. (32-2044)"
		Set ..%GetComponentById("globals16kb").hint = "Required. (64-2044 or 0)"
		Set ..%GetComponentById("globals32kb").hint = "Required. (128-2044 or 0)"
		Set ..%GetComponentById("globals64kb").hint = "Required. (256-2044 or 0)"
	} Else {
		Set ..%GetComponentById("globals4kb").hint = "Required. (16-8388607 or 0)"
		Set ..%GetComponentById("globals8kb").hint = "Required. (32-16777215)"
		Set ..%GetComponentById("globals16kb").hint = "Required. (64-33554431 or 0)"
		Set ..%GetComponentById("globals32kb").hint = "Required. (128-67108863 or 0)"
		Set ..%GetComponentById("globals64kb").hint = "Required. (256-134217727 or 0)"
	}
	Do ##class(Config.WinStartup).GetServiceAutoStartAsNumber(.AutoMode)
	Set ..%GetComponentById("AutoMode").value = AutoMode
	Set ..NotWindows = $SELECT(AutoMode=-1:1,1:0)
	If ..EditPort Set ..%GetComponentById("AutoMode").disabled = 1

	// Hide the field if this is not windows
	If (AutoMode = -1) {
		Do ..HideComponent("AutoMode")
	}
	
	// Get Config.Startup settings
	Kill Properties
	Set tSC = ##class(Config.Startup).Get(.Properties)
	If $$$ISERR(tSC) Quit tSC
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly||(..EditPort&&(tProperty'="DefaultPort")) Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	Set ..OldDefaultPort = Properties("DefaultPort")
	Set ..DBSizesAllowed = Properties("DBSizesAllowed")
	If (..DBSizesAllowed '[ "4096") {
		Do ..HideComponent("globals4kb")
	}
	If (..DBSizesAllowed '[ "8192") {
		Do ..HideComponent("globals8kb")
	}
	If (..DBSizesAllowed '[ "16384") {
		Do ..HideComponent("globals16kb")
	}
	If (..DBSizesAllowed '[ "32768") {
		Do ..HideComponent("globals32kb")
	}
	If (..DBSizesAllowed '[ "65536") {
		Do ..HideComponent("globals64kb")
	}
	
	Set ..%GetComponentById("SystemMode").value = $G(^%SYS("SystemMode"))
	If ..EditPort Set ..%GetComponentById("SystemMode").disabled = 1
	
	// Get Config.Miscellaneous properties
	Kill Properties
	Set tSC = ##class(Config.Miscellaneous).Get(.Properties)
	If $$$ISERR(tSC) Quit tSC
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If ..IsEMSReadOnly||..EditPort Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Quit $$$OK
}

Method HideComponent(id As %String)
{
	Set ..%GetComponentById(id).hidden = 1
	Set ..%GetComponentById(id).containerStyle = "padding:0;"
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Memory and Startup")
}

/// This method resets the modified indicator and return user to the parent page. 
ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	if (this.EditPort == 1) {
		this.firePopupAction('ok',parseInt(zen('DefaultPort').getValue()),true);
	}
	self.document.location = this.ParentURL;
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
