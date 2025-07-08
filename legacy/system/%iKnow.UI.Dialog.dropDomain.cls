/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// This dialog lets the user Add a new iKnow domain or configuration definition.
Class %iKnow.UI.Dialog.dropDomain Extends %CSP.UI.Portal.Dialog.WizardTemplate [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter AUTONS As BOOLEAN = 1;

Parameter DOMAIN = "%iKnow";

/// Security requirement
Parameter RESOURCE = "%Development";

/// DOCBOOK Topic Id that offers help for this page.
Parameter HELPID As STRING;

Property domainDefinitionClass As %ZEN.Datatype.string(ZENURL = "DOMAINDEF");

Property returnValue As %ZEN.Datatype.string;

XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<vgroup>
<label label="Do you want to delete the domain or only its contents?" 
hint="This operation cannot be undone!" />
<spacer height="15" />
<button id="cmdDropData" caption="Drop domain contents only" onclick="zenPage.DropDomainData();" />
<spacer height="15" />
<button id="cmdDropDef" caption="Drop domain &amp; definition class" onclick="zenPage.DropDomainDefinition();" />
</vgroup>
</pane>
}

Method DropDomainDefinition() As %Status [ ZenMethod ]
{
	&js<zen('cmdDropData').setProperty('disabled', true); zen('cmdDropDef').setProperty('disabled', true);>
	set tSC = ..%RunBackgroundMethod("DropDomainDefinitionAsync",..domainDefinitionClass)
	quit tSC
}

ClassMethod DropDomainDefinitionAsync(pClassName As %String) As %Status [ Internal ]
{
	do ..%SetBackgroundMethodStatus("Dropping domain...", 0)
	set ^IRIS.Temp.IK.DomainDrop(+$job) = $lb(0, "DropDef", pClassName)
	set $li(^IRIS.Temp.IK.DomainDrop(+$job),1) = $system.OBJ.Delete(pClassName,"-d")
	do ..%EndBackgroundMethod()
	quit $$$OK
}

Method DropDomainData() As %Status [ ZenMethod ]
{
	&js<zen('cmdDropData').setProperty('disabled', true); zen('cmdDropDef').setProperty('disabled', true);>
	set tSC = ..%RunBackgroundMethod("DropDomainDataAsync",..domainDefinitionClass)
	quit tSC
}

ClassMethod DropDomainDataAsync(pClassName As %String) As %Status [ Internal ]
{
	do ..%SetBackgroundMethodStatus("Dropping data...", 0)
	set ^IRIS.Temp.IK.DomainDrop(+$job) = $lb(0, "DropData", pClassName)
	set $li(^IRIS.Temp.IK.DomainDrop(+$job),1) = $classmethod(pClassName,"%DropData")
	do ..%EndBackgroundMethod()
	quit $$$OK
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	set tInfo = $g(^IRIS.Temp.IK.DomainDrop(pTaskID))
	set tStatus = $lg(tInfo,1)
	if $$$ISERR(tStatus) {
		set tMessage = $zcvt($system.Status.GetErrorText(tStatus),"O","JS")
		&js<alert('Error during delete operation\n#(tMessage)#');>
	} else {
		if $lg(tInfo,2)="DropData" {
			&js<alert('Domain contents dropped successfully'); zenPage.dialogFinish();>
		} else {
			&js<alert('Domain definition dropped successfully'); zenPage.setProperty('returnValue','redirect'); zenPage.dialogFinish();>
		}
	}
	kill ^IRIS.Temp.IK.DomainDrop(pTaskID)
}

Method %OnGetSubtitle() As %String
{
	set tDomainName = "undefined"
	try {
		set tDomainName = $classmethod(..domainDefinitionClass, "%GetDomainName")
	} catch {}
	quit $$$TextHTML("Drop domain")_" '"_$zcvt(tDomainName,"O","HTML")_"'"
}

Method %OnGetTitle() As %String
{
	quit "Drop domain data"
}

/// Get the value that will be applied when the user presses the OK button.
/// This is implemented by subclasses.
ClientMethod getDialogValue() [ Language = javascript ]
{
	return zenPage.getProperty('returnValue');
}

}
