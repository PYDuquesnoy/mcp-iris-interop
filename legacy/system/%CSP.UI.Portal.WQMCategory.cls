/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occWorkQueue

/// Zen page for System Management Portal - Edit WQM Category
Class %CSP.UI.Portal.WQMCategory Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Work Queue Manager Category";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.WQMCategory.zen";

Parameter HELPADDRESS = "System Administration,Configuration,System Configuration,WQM Category";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.WQMCategories.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not register in recent list
Parameter RECENT = 0;

/// ID for edit.
Property PID As %String(ZENURL = "PID");

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// If set to 1 then the generic Save and Cancel button will be shown on the ribbon bar.
Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">
.EditForm { width:600px; }
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="categoryCtl" label="Category name" size="45"
title="" readOnly="false"
 onchange="zenPage.doModified();"/>
<text id="usercategoryPrefixCtl" label="" size="5"
hidden ="true"
value=""/>
<select id="MaxActiveWorkersCtl" label="Max active workers" 
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<select id="DefaultWorkersCtl" label="Default workers" 
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<select id="MaxWorkersCtl" label="Max workers"
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod getProxy() [ Language = javascript ]
{
	try {

		var proxy = new zenProxy();

		proxy.Category = zen('categoryCtl').getValue();
		proxy.MaxActiveWorkers = zen('MaxActiveWorkersCtl').getValue();
		proxy.DefaultWorkers = zen('DefaultWorkersCtl').getValue();
		proxy.MaxWorkers = zen('MaxWorkersCtl').getValue();
		return proxy;

	} catch (ex) {

		alert("Error doSave: " + ex);
	}
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Return tSC

	#; Create value and display list based on max workers

	#dim categoryCtl = ..%GetComponentById("categoryCtl")
	#dim userCategoryPrefixCtl = ..%GetComponentById("usercategoryPrefixCtl")
	#dim MaxActiveWorkersList = ..%GetComponentById("MaxActiveWorkersCtl")
	#dim DefaultWorkersList = ..%GetComponentById("DefaultWorkersCtl")
	#dim MaxWorkersList = ..%GetComponentById("MaxWorkersCtl")

	s MaxActiveWorkers=##Class(Config.WorkQueues).MaxWorkersAvailable()
	If MaxActiveWorkers > 1 {

		#dim additional
		For additional = 1:1:MaxActiveWorkers {
			Set MaxActiveWorkersList.valueList=MaxActiveWorkersList.valueList_","_additional
			Set MaxActiveWorkersList.displayList=MaxActiveWorkersList.displayList_","_additional
		}
		For additional = 1:1:MaxActiveWorkers/2 {
			Set DefaultWorkersList.valueList=DefaultWorkersList.valueList_","_additional
			Set DefaultWorkersList.displayList=DefaultWorkersList.displayList_","_additional
		}
		For additional = 1:1:MaxActiveWorkers {
			Set MaxWorkersList.valueList=MaxWorkersList.valueList_","_additional
			Set MaxWorkersList.displayList=MaxWorkersList.displayList_","_additional
		}
	}

	Set MaxActiveWorkersList.displayList = $$$TextHTML("Dynamic")_" ("_MaxActiveWorkers_")"_","_$Piece(MaxActiveWorkersList.displayList,",",2,*)
	Set DefaultWorkersList.displayList = $$$TextHTML("Dynamic")_" ("_(MaxActiveWorkers/2)_")"_","_$Piece(DefaultWorkersList.displayList,",",2,*)
	Set MaxWorkersList.displayList = $$$TextHTML("Dynamic")_" ("_MaxActiveWorkers_")"_","_$Piece(MaxWorkersList.displayList,",",2,*)
	If ..PID '= "" {

		If ##class(Config.WorkQueues).IsSystemWorkQueue(..PID) {

			Set ..lblTitle = $$$TextHTML("Use the form below to edit the user category:")

		} Else {

			Set ..lblTitle = $$$TextHTML("Use the form below to edit the system category:")
			Set categoryCtl.label = $$$TextHTML("System category")
		}

		Set categoryCtl.disabled = 1

	} Else {
		Set ..isNew = 1
		Set ..lblTitle = $$$TextHTML("Use the form below to create a new category:")
		Set categoryCtl.hint = $$$TextHTML("Required. String of letters, numbers, and periods with a maximum of 45 characters.")

	}

	Set tSC = ..PopulateFields()

	Return tSC
}

Method %OnGetPageName() As %String
{
	If ..PID '= "" {
		Quit $$$TextHTML("Edit Work Queue Manager Category")
	} Else {
		Quit $$$TextHTML("New Work Queue Manager Category")
	}
}

/// Save current item. Subclass may override.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.pageModified) {
			this.doCancel();
			return;
		}

		var proxy = new zenProxy();

		proxy.Category = zen('categoryCtl').getValue();
		proxy.MaxActiveWorkers = zen('MaxActiveWorkersCtl').getValue();
		proxy.DefaultWorkers = zen('DefaultWorkersCtl').getValue();
		proxy.MaxWorkers = zen('MaxWorkersCtl').getValue();

		var result = this.SaveData(proxy,this.isNew);
		this.afterSave(result);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject, isNew As %Boolean) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	#dim tSC = $$$OK

	Try {

		Set tProxy = ##class(%ZEN.proxyObject).%New()

		s Properties("MaxActiveWorkers")=pProxy.MaxActiveWorkers
		s Properties("DefaultWorkers")=pProxy.DefaultWorkers
		s Properties("MaxWorkers")=pProxy.MaxWorkers

		i isNew {
			Set tSC = ##class(Config.WorkQueues).Create(pProxy.Category,.Properties)
		} else {
			Set tSC = ##class(Config.WorkQueues).Modify(pProxy.Category,.Properties)
		}	
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.ok = 1

	} Catch ex {

		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(ex.AsStatus()),"O","HTML")

	}

	Quit tProxy
}

Method PopulateFields() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	Try {

		If ..PID '= "" {

			Set ..%GetComponentById("categoryCtl").value = ..PID

			s tSC=##Class(Config.WorkQueues).Get(..PID,.Properties)
			i $$$ISOK(tSC) {
				Set ..%GetComponentById("MaxActiveWorkersCtl").value = Properties("MaxActiveWorkers")
				Set ..%GetComponentById("DefaultWorkersCtl").value = Properties("DefaultWorkers")
				Set ..%GetComponentById("MaxWorkersCtl").value = Properties("MaxWorkers")
			}
		} Else {

			Set ..%GetComponentById("categoryCtl").value = ""
			Set ..%GetComponentById("MaxActiveWorkersCtl").value = 0
			Set ..%GetComponentById("DefaultWorkersCtl").value = 0
			Set ..%GetComponentById("MaxWorkersCtl").value = 0
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

}
