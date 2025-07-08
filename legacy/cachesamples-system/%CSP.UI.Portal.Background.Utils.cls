/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class contains shared methods used by the systems background task UI pages.
Class %CSP.UI.Portal.Background.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Property OpenDetailsPage As %String [ InitialExpression = {..Link("/csp/sys/%CSP.UI.Portal.Background.Dialog.TaskInfo.zen",,1)} ];

Property OutputPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.Background.TaskInfoOutput.zen")} ];

ClassMethod GetTaskInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set SysBGTaskId = pParms("parmSysBGTaskId")
		Set pObject = ..HasEnded(SysBGTaskId)
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = $System.Status.GetErrorText(tSC)
	}
	Quit tSC
}

ClassMethod HasEnded(SysBGTaskId) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.HasEnded = 1
	Set tProxy.Error = ""
	Set tObj = ##class(%SYS.BackgroundTask).%OpenId(SysBGTaskId)
	If '$IsObject(tObj) {
		Set tProxy.Error = $$$FormatText($$$Text("Error: object for system background task id %1 no longer exist!"),SysBGTaskId)
	} Else {
		Set tProxy.HasEnded = tObj.HasEnded
		Set tProxy.CANCELDISPOSITION = tObj.#CANCELDISPOSITION
		Set tProxy.PAUSEDISPOSITION = tObj.#PAUSEDISPOSITION
		Set tProxy.CancelIsAvailable = tObj.CancelIsAvailable
		Set tProxy.PauseIsAvailable = tObj.PauseIsAvailable
		Set tProxy.ResumeIsAvailable = tObj.ResumeIsAvailable
	}
	Kill tObj
	Quit tProxy
}

/// This function is executed when SaveQuery is processed to run in the background. 
ClientMethod timeout() [ Language = javascript ]
{
	if (!this.SysBGTaskId) {
		alert("Unexpected error: no SysBGTaskId!");
		return;	
	}
	var proxy = this.HasEnded(this.SysBGTaskId);
	if (proxy.Error) {
		zen('result').setValue(proxy.Error);
		return;	
	}

	this.drawData();
	this.updateButtons(proxy);

	if (proxy.HasEnded != 1) {
		var timer = zen('timer');
		timer.setProperty('timeout',2000);
		timer.startTimer();
	}
}

ClientMethod updateButtons(proxy) [ Language = javascript ]
{
	if (proxy.CANCELDISPOSITION) {
		zen('btnAbort').setProperty('hidden',false);
		if (proxy.CancelIsAvailable == 0) {
			zen('btnAbort').setProperty('disabled',true);
			zen("btnAbort").setProperty("controlClass","commandButtonDisabled");
		} else {
			zen('btnAbort').setProperty('disabled',false);
			zen('btnAbort').setProperty('controlClass','commandButton');
		}
	}
	if (proxy.PAUSEISPOSITION) {
		zen('btnPause').setProperty('hidden',false);
		zen('btnResume').setProperty('hidden',false);
		if (proxy.PauseIsAvailable == 0) {
			zen('btnPause').setProperty('disabled',true);
			zen("btnPause").setProperty("controlClass","commandButtonDisabled");
		} else {
			zen('btnPause').setProperty('disabled',false);
			zen('btnPause').setProperty('controlClass','commandButton');
		}
		if (proxy.ResumeIsAvailable == 0) {
			zen('btnResume').setProperty('disabled',true);
			zen("btnResume").setProperty("controlClass","commandButtonDisabled");
		} else {
			zen('btnResume').setProperty('disabled',false);
			zen('btnResume').setProperty('controlClass','commandButton');
		}
	}
}

ClientMethod drawData() [ Language = javascript ]
{
	var outputlink = this.OutputPage + "?SysBGTaskId="+encodeURIComponent(this.SysBGTaskId);
	zen('output').setProperty('src',outputlink);
}

/// Show information for the background job id in a dialog window
ClientMethod openDetails(SysBGTaskId) [ Language = javascript ]
{
	if (SysBGTaskId) {
		url = this.OpenDetailsPage + '&SysBGTaskId=' + encodeURIComponent(SysBGTaskId);
		zenLaunchPopupWindow(url,'ViewDetails','status,scrollbars,resizable,width=750,height=600');
	}
}

/// Return on-going background tasklist (Input: database directory)
ClassMethod GetTaskList(pDirectory, Output pTaskList) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pTaskList = ""
		#; There really can only be one since they are currently mutually exclusive
		Set tRS = ##class(%ResultSet).%New("%SYS.BackgroundTask:RunningInDatabase")
		Set tSC = tRS.%Execute(pDirectory)
		Set tCols = tRS.%GetMetadata()
		Set tRow = 0
		While tRS.%Next() {
			Set tRow = tRow + 1
			Set:tRow>1 pTaskList = pTaskList _ "^"
			For col = 1:1:tCols.columnCount {
				Set tName = tCols.columns.GetAt(col).colName
				Set pTaskList = pTaskList _ tRS.%Get(tName) _ ";"
			}
		}
		Set tRS = ""
		}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Log error into ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") and ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
ClassMethod LogMsg(ErrMsg As %String = "", Status As %String = "ERROR")
{
	Set $$$TempMgtPortalTask($J,"Details") = $G($$$TempMgtPortalTask($J,"Details")) _" " _ ErrMsg
	Set $$$TempMgtPortalTask($J,"Status") = Status
}

}
