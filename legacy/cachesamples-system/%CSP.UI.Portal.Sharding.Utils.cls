/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%BigData.ShardingManager, %sqlui)

/// Utilities used by Management Portal Sharding.
Class %CSP.UI.Portal.Sharding.Utils Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Property iTimeoutInterval As %ZEN.Datatype.integer [ InitialExpression = 500 ];

Property msgWait As %ZEN.Datatype.string;

/// Returns current state of sharding. If pService("ECP") and pService("Sharding") both equal to 1, then sharding is enabled.
ClassMethod IsShardingEnabled(Output pService) As %Boolean
{
	Kill pService,properties
	New $namespace
    Set $namespace="%SYS"
	Set status = ##class(Security.Services).Get("%Service_ECP",.properties)
	Set pService("ECP") = +$G(properties("Enabled"))
	Kill properties
	Set status = ##class(Security.Services).Get("%Service_Sharding",.properties)
	Set pService("Sharding") = +$G(properties("Enabled"))
	Quit (pService("ECP") = 1 && pService("Sharding") = 1)
}

/// Validate the control value. pass is either "true" or "false" indicating if there is already a field that failed validation. 
/// Type is "N" for numeric or "S" for string. If numeric, if checkRange is true, we additionally validate that the number is 
/// between minVal and maxVal, inclusive.
ClientMethod validateRequired(ctl, pass, type, checkRange, minVal, maxVal) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	switch (type) {
		/// contains at least one numeric character
		case "N":
			if (!(value.match(/\d/))) {
				ok = false;
			} else if (checkRange == true) {
				if (isNaN(value)) {
					// fail if not numeric
					ok = false;
				} else if ((value < minVal) || (value > maxVal)) {
					// fail if not in range
					ok = false;
				}
			}
			break;
		case "S":
		/// contains at least one character after striping all blanks
			if (zenTrim(value) == '') {
				ok = false;
			}
			break;
	}
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		ctl.setProperty("controlClass","zenInvalid");
		if (pass) {
			this.FirstFailed = ctl.getProperty("id");
		}
	} else {
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
	return ok;
}

/// Check job status for Assign, Reassign, Activate and Verify Shard.
ClassMethod CheckJobStatus(PID) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.msg = ""
	// check if background job has errorred
	If $G($$$TempMgtPortalTask(PID,"Status")) = $$$Text("ERROR") {
		Set proxy.status = "error" 
		Set proxy.msg = $G($$$TempMgtPortalTask(PID,"Details"))
		Quit proxy
	}
	// check if it is finished
	Set Status = $G($$$TempMgtPortalTask(PID,"FinishStatus"))
	// if it has not finished, check if the process has been terminated or suspended
	If Status '= 1 {
		Set tCurrentNS = $ZU(5)
		Set $Namespace = "%SYS"
		Set tPOBJ = ##class(%CSP.UI.Portal.ProcessDetails).GetPIDOBJ(PID)
		If '$IsObject(tPOBJ) {
			Set proxy.status = "terminated"
			Set proxy.msg = $$$FormatText($$$Text("Process '%1' no longer exists."),PID)
		} Else {
			If tPOBJ.CanBeSuspended = 0 {
				Set proxy.status = "suspended"
				Set proxy.msg = $$$FormatText($$$Text("Process '%1' has been suspended."),PID)
			} Else {
				Set proxy.status = "running"
			}
		}
		Set $Namespace = tCurrentNS
	} Else {
		Set proxy.status = "done"
	}
	Quit proxy
}

ClassMethod GetNamespaceLists(Output valueList, Output displayList, Output defaultDM)
{
		Set ShardInfo = 1
		Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces, .ShardInfo)
		Set (valueList,displayList,defaultDM) = ""
		#; Include only Data Master namespaces and non-sharding namespaces
		#; Default to the first DM found (there should be at least one otherwise we would not be here)
		For i=1:1:tCnt {
			If Namespaces(i) '= "%SYS" {
				Set shard = $G(ShardInfo(i))
				If ((shard = "") || ($lg(shard,1) = "DM")) {
					If (($lg(shard,1) = "DM") && (defaultDM = "")) {
						Set defaultDM = Namespaces(i)	
					}
					Set valueList = valueList _ $S(valueList'="":",",1:"") _ Namespaces(i)
					Set displayList = displayList _ $S(displayList'="":",",1:"") _ Namespaces(i) _ " " _ $lg($G(ShardInfo(i)),2)
				}
			}
		}
}

ClassMethod GetShardList(Output valueList, Output displayList)
{
	Set (valueList, displayList) = ""
	Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ListShards")
	Do tRS.Execute()
	While tRS.Next() {
		If tRS.Data("ROLE") = "Data" {
			Set valueList = valueList _ $S(valueList="":"",1:",") _ tRS.Data("SHARD")
			Set displayList = displayList _ $S(displayList="":"",1:",") _ tRS.Data("SHARD") _ " - " _ tRS.Data("SHARD_DATABASE")
		}
	}
}

}
