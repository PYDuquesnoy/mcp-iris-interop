/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Add to Mirror dialog for Management Portal.
Class %CSP.UI.Portal.Dialog.DBMirrorAdd Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.DBMirrorAdd.zen";

/// Displayed name of this page.
Parameter PAGENAME = "AddToMirror";

Parameter RESOURCE = "%Admin_Manage:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// DB name to be added to mirror.
Property DBName As %ZEN.Datatype.string(ZENURL = "DBName");

/// DB directory to be added to mirror.
Property Dir As %ZEN.Datatype.string(ZENURL = "Dir");

/// Primary Mirror name for DB to be added.
Property MirDBName As %ZEN.Datatype.string(ZENURL = "MirDBName");

/// Indicates whether multiple databases can be added.
Property Multi As %ZEN.Datatype.boolean(ZENURL = "Multi") [ InitialExpression = 0 ];

/// Indicates how many databases the user is adding.
Property MultiCount As %ZEN.Datatype.integer [ InitialExpression = 0 ];

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
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Add" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<text id="txtDBName" label="Mirror Database Name" size="60" hint="Required." hintClass="helpText"/>
<vgroup id="multiDBTable">
<html OnDrawContent="DrawMultiText" seed=""/>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter the leading characters of a database name followed by [Tab] to filter the list. For example: C for all database names starting with letter 'C'."/>
<tablePane id="table" cellSpacing="2"
queryClass="Config.Databases"
queryName="LocalDatabaseCanMirrorList"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
onmultiselect="zenPage.rowSelect(zenThis.selectedRows);"
>
<column colName="Name" header="Name"/>
<column colName="Directory" header="Directory"/>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
 </tablePane>
 <spacer height="10px"/>
 <checkbox id="chkBackground" caption="Run add in the background" captionClass="zenLabel" title="Recommended if adding multiple databases."/>
 </vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("btnCancel").focus();
}

ClientMethod rowSelect(selectedRows) [ Language = javascript ]
{
	var dbArray = selectedRows.split(',');
	var isRowSelected = false;
	this.MultiCount = 0;
	for (var i = 0; i < dbArray.length; i++) {
		if (dbArray[i] != '') {
			isRowSelected = true;
			this.MultiCount++;
		}
	}
	if (this.MultiCount >= 5) {
		zen('chkBackground').setValue(true);
		zen('chkBackground').setDisabled(true);
	} else {
		zen('chkBackground').setDisabled(false);
	}
	if (isRowSelected) {
		this.ToggleFinishButton(1);
	} else {
		this.ToggleFinishButton(0);
	}
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg();
	if (!this.Multi) {
		var MirDBName = zen("txtDBName").value;
		if (MirDBName == "") {
			this.showMsg($$$Text("Please enter a mirror database name."));
			zen("txtDBName").focus();
			return false;
		}
	} else {
		if (this.MultiCount < 1) {
			this.showMsg($$$Text("Please select one or more databases."));
			return false;
		}
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var ok = this.validate();
		if (!ok) return false;
		var confirmText = $$$Text("Are you sure you want to add this database to the mirror?");
		if (this.Multi && this.MultiCount > 1) {
			confirmText = $$$Text("Are you sure you want to add these databases to the mirror?");
		}
		if (!confirm(confirmText)) return false;
		var background = zen('chkBackground').getValue();
		if (!this.Multi) {
			ok = this.SaveData(this.Dir,zen("txtDBName").value);
		} else {
			ok = this.SaveDataMulti(zen('table').selectedRows,background);
		}
		if (ok == 1) {
			if (background || (this.MultiCount >= 5)) {
				text = $$$Text("This job is running in the background. You may view background tasks to see the status and result.");
				alert(text);
			}
			return true;
		} else {
			this.showMsg(ok);
			return false;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen("txtDBName").value;
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	if (value.indexOf("*") == -1) {
		value += "*";
	}
	table.parameters[0].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Add to Mirror")
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
	Do ..%GetNavTableState()
	If %page.Multi {
		Set ..%GetComponentById("txtDBName").hidden = 1
		Do ..ToggleFinishButton(0)
	} Else {
		Set ..%GetComponentById("chkBackground").hidden = 1
		Set ..%GetComponentById("multiDBTable").hidden = 1
		Set ..%GetComponentById("txtDBName").value = ..DBName
	}
	Quit $$$OK
}

Method ToggleFinishButton(Enabled As %Boolean) As %Status [ ZenMethod ]
{
	Set Button =..%GetComponentById("btnFinish")
	If Enabled {
		Set Button.disabled = 0
		Set Button.controlClass = "commandButton"
	} Else {
		Set Button.disabled = 1
		Set Button.controlClass = "commandButtonDisabled"
	}
	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set DBName = %page.DBName
	Set MirDBName = %page.MirDBName
	Set Dir = %page.Dir
	If %page.Multi {
		Set tTitle = $$$FormatText($$$TextHTML("Add Databases to Mirror %1"),$ZCVT(MirDBName,"O","HTML"))
	} Else {
		Set tTitle = $$$FormatText($$$TextHTML("Add Database %1 to Mirror %2"),$ZCVT(DBName,"O","HTML"),$ZCVT(MirDBName,"O","HTML"))
	}
	Set tNote1 = $$$TextHTML("A database can be added to the mirror only on the running Primary Failover Member (this system).")
	Set tNote2 = $$$TextHTML("Once it has been successfully added to the Mirror, you must backup (or copy) and restore the database from the Primary Failover Member (this system) to the other Failover Member.")
	&html<<p class="Description">#(tTitle)#</p>
	<hr size="1"/>
	<p class="Description">#(tNote1)# #(tNote2)#</p>
	>
	Quit 1
}

ClassMethod DrawMultiText(pSeed As %String) As %Status
{
	
	Set tNote1 = $$$TextHTML("The following is a list of the local databases which can be added to the mirror:")
	&html<<p class="Description">#(tNote1)#</p>>
	Quit $$$OK
}

ClassMethod SaveData(Dir As %String, MirDBName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(SYS.MirrorConfiguration).AddDatabaseToMirrorSet(Dir,MirDBName)
		If $$$ISERR(tSC) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tSC = $System.Status.GetErrorText(tSC)
	}
	Quit tSC
}

ClassMethod SaveDataMulti(DBNames As %String, Background As %Boolean) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set delim = ","
		Set length = $Length(DBNames,delim)
		Set addList = ""
		Kill tItems
		For i=1:1:length {
			Set DBName = $Piece(DBNames,delim,i)
			If (DBName = "") Continue
			Set Dir = ##class(Config.Databases).GetDirectory(DBName)
			Set addList = addList_$ListBuild($ListBuild(Dir,DBName))
			Set tItems(DBName) = Dir
		}
		
		If Background || (length >= 5) {
		 	Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorAddDatabases",$namespace,.tParms,.tItems,.tJob)
		 	If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			TSTART
			Set inTrans = 1
			For i=1:1:$ListLength(addList) {
				Set Dir = $List($List(addList,i),1)
				Set MirDBName = $List($List(addList,i),2)
				Set tSC = ##class(SYS.MirrorConfiguration).AddDatabaseToMirrorSet(Dir,MirDBName)
				If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			TCOMMIT
			Set inTrans = 0
		}
	} Catch exp {
		If ($Get(inTrans,"")) { TROLLBACK 1 }
		Set tSC = exp.AsStatus()
		Set tSC = $System.Status.GetErrorText(tSC)
	}
	Quit tSC
}

}
