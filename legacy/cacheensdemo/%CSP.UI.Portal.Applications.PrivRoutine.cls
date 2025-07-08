/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit Privileged Routine Application
Class %CSP.UI.Portal.Applications.PrivRoutine Extends %CSP.UI.Portal.Applications.EditTemplate [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

///  Displayed name of this page.
Parameter PAGENAME = "Edit Privileged Routine Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.PrivRoutine.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Privileged Routine Applications";

Parameter EMSSERVICE = "Security";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Applications.PrivRoutineList.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property ApplicationType As %Integer [ InitialExpression = {$$$AppTypePrivRoutine} ];

Property EditHeader As %String;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsNewSave As %Integer(ZENURL = "new");

Property NumTabs As %Integer [ InitialExpression = 4 ];

Property RolesHeader As %String;

Property RoutinesHeader As %String;

XData Style
{
<style type="text/css">
.sectionLabel {
	font-size:13px;
	font-weight:normal;
	color:black;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<link id="newLink" href="%25CSP.UI.Portal.Applications.PrivRoutine.zen?PID=" caption="Click here to create a new client application." hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Application Roles:Matching Roles:Routines/Classes"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: Application Edit -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">

<text id="Name" label="Privileged routine application name" size="40" onchange="zenPage.doModified();" hint="Required." title="Enter the path and name of your priviliged routine application"/>
<text id="Description" label="Description" size="80" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" value="1" onchange="zenPage.doModified();"/>

<select id="Resource" label="Resource required to run the application"
title="Specifies a resource for which users must have the Use permission (enabled as part of a privilege in a role) in order to run the application."
onchange="zenPage.doModified();"
/>

</group>
</form>
</vgroup>

<!-- Page 2: Application Roles -->
<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<ApplicationRoles id="AppRoleComponent" type="ApplicationRole" PID='#(%page.PID)#' readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 3: Match Roles -->
<vgroup id="page_3" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<ApplicationRoles id="MatchRoleComponent" type="MatchRole" PID='#(%page.PID)#' readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 4: Routines -->
<vgroup id="page_4" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html id="RoutineComponent" OnDrawContent="DrawRoutineTab"/>
<spacer height="15px"/>
<label labelClass="sectionLabel" label="To add a routine or class, fill out the following form and press [Assign]." hidden="#(%page.IsEMSReadOnly)#"/>
<fieldSet labelPosition="left" cellStyle="padding:4px;" hidden="#(%page.IsEMSReadOnly)#">
<select id="Location" label="Routine/Class location" hint="Required." showEmpty="false"/>
<text id="RoutineName" label="Routine/Class name" size="40" hint="Required. Enter a routine name, or for a class, enter Package.Name"/>
<radioSet id="isClass" label="This is a" valueList="0,1" displayList="Routine,Class" value="0" layout="vertical"/>
<button id="btnAssign" caption="Assign" onclick="zenPage.doAddRoutine();" align="right"/>
</fieldSet>
</vgroup>


</pane>
}

/// Set focus to the Name or Description field, disable fields if DispatchClass is defined.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("Name").focus();
	
	if (this.IsNewSave != 0) {
		this.showMsg($$$Text('Application saved.'),false);
		var newLink = zen('newLink');
		newLink.setHidden(false);
		return;
	}
	
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	}
	
	this.resetMsg();
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.invokeSuper('tabChanged',arguments);
	if (index == 3) {
		zen('Text1').setValue(this.RoutinesHeader);
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	this.resetMsg();
	zen('newLink').setHidden(true);
	
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.Description = zen('Description').getValue();
	proxy.Enabled = zen('Enabled').getValue();
	proxy.Resource = zen('Resource').getValue();
	proxy.ApplicationType = this.ApplicationType;
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	}
	this.setModified(false);
	if (proxy.PID == '') {
		var url = zenLink('%25CSP.UI.Portal.Applications.PrivRoutine.zen?PID='+encodeURIComponent(proxy.Name)+'&new=1');
		this.gotoPage(url);
		return;
	}
	// saved existing app
	this.showMsg($$$Text('Application saved.'),false);
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var pass = true;
	try {
		var oldSynchronousMode = zenSynchronousMode;
		zenSynchronousMode = true;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		zenSynchronousMode = oldSynchronousMode;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	
	return pass;
}

ClientMethod doAddRoutine() [ Language = javascript ]
{
	this.resetMsg();
	var elID = 'Location';
	var dbElem = zen(elID);
	var db = dbElem.getValue();
	var flagElem = zen('isClass')
	var flag = flagElem.getValue();
	var pass = true;
	if (db == '') {
		if (pass) dbElem.focus();
		dbElem.setProperty("hintClass","redText");
		dbElem.setProperty("controlClass","zenInvalid");
		pass = false;
	} else {
		dbElem.setProperty("hintClass","helpText");
		dbElem.setProperty("controlClass","");
	}
	var routineElem = zen('RoutineName');
	var routine = routineElem.getValue();
	if (routine == '') {
		if (pass) routineElem.focus();
		routineElem.setProperty("hintClass","redText");
		routineElem.setProperty("controlClass","zenInvalid");
		pass = false;
	} else {
		routineElem.setProperty("hintClass","helpText");
		routineElem.setProperty("controlClass","");
	}
	if (!pass) {
		this.showMsg(this.ValidationErrorMsg,true);
		return;
	}
	var ok = this.AddRoutine(this.PID,routine+':'+db+":"+flag);
	if (ok != 1) {
		alert(ok);
	} else {
		zen('RoutineComponent').refreshContents();
		dbElem.setValue('');
		routineElem.setValue('');
	}
}

ClientMethod doRemoveRoutine(element) [ Language = javascript ]
{
	var ok = this.RemoveRoutine(this.PID,element);
	if (ok != 1) {
		alert(ok);
	} else {
		zen('RoutineComponent').refreshContents();
	}
}

Method AddRoutine(PID As %String, Element As %String) As %String [ ZenMethod ]
{
	Try {
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If Properties("Routines") = "" {
			Set Properties("Routines") = Element
		} Else {
			Set Properties("Routines") = Properties("Routines")_","_Element
		}

		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
	 	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

	 	Set tSC = $$$OK
	} Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

Method RemoveRoutine(PID As %String, Element As %String) As %String [ ZenMethod ]
{
	Try {
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set newRoutines = ""
		Set Routines = Properties("Routines")
		For i = 1:1:$LENGTH(Routines,",") {
			Set Routine = $PIECE(Routines,",",i)
			If (Routine '= Element) {
				If (newRoutines '= "") Set newRoutines = newRoutines_","
				Set newRoutines = newRoutines_Routine
			}
		}
		Set Properties("Routines") = newRoutines
		
		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
	 	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

	 	Set tSC = $$$OK
	} Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.shortName = pProxy.Name

	Try {
		Set Properties("Description") = pProxy.Description
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("Resource") = pProxy.Resource
		
		If pProxy.PID = "" {
			Set Properties("Type") = pProxy.ApplicationType
			
			Set tSC = ##class(Security.Applications).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
			Set tProxy.shortName = ##class(%Library.File).GetFilename(pProxy.Name)
		} Else {
			Set tSC = ##class(Security.Applications).Modify(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method DrawRoutineTab(pSeed As %String) As %Status
{
	Try {
		Set tSC = ##class(Security.Applications).Get(..PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set Routines = Properties("Routines")
		&html<<div>>
		&html<<div class="Text2">#($$$Text("The following privileged routines and classes can execute the AddRoles method for this application definition."))#</div>>
	 	&html<<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">>
	 	&html<<thead class="tpHead"><tr><th nowrap>#($$$Text("Database Name"))#</th><th nowrap>#($$$Text("Routine/Class"))#</th><th nowrap>#($$$Text("Type"))#</th><th>&nbsp;</th></tr></thead>>
	 	&html<<tbody class="tpBody">>
	 	
	 	If Routines = "" {
			&html<<tr><td colspan="3">#($$$Text("None."))#</td></tr>>
		} Else {
		 	Set tRow = 0
		 	For i = 1:1:$LENGTH(Routines,",") {
			 	Set tRow = tRow + 1
				Set Routine = $PIECE(Routines,",",i)
				Set RouName = $P(Routine,":",1)
		 		Set DB = $P(Routine,":",2)
		 		Set Type=$s(+$p(Routine,":",3)=1:"Class",1:"Routine")
				Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
				&html<<tr class="#(rowClass)#">
				<td class="tpStr" nowrap>#(..EscapeHTML(DB))#</td>
				<td class="tpStr" nowrap>#(..EscapeHTML(RouName))#</td>
				<td class="tpStr" nowrap>#(..EscapeHTML(Type))#</td>>
				if '..IsEMSReadOnly {
					&html<<td class="tpAction" style="text-align:center;"><a href="#" onclick="zenPage.doRemoveRoutine('#(Routine)#');return false;">#($$$Text("Remove"))#</a></td>>
				}
				&html<</tr>>
			}
		}	 	
		
		&html<</tbody>>
		&html<</table>>
		&html<</div>>
		
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Populate the Resource dropdown
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$ServiceResourceType+$$$ApplicationResourceType+$$$UserResourceType)
	Set valueList = ""
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("Resource").displayList,..%GetComponentById("Resource").valueList) = valueList

	If ..PID = "" {
		// Creating new application
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the following form to create a new privileged routine application:")
		Set ..%GetComponentById("svgTabArea").hidden = 1
		Set ..%GetComponentById("svgTabArea").height = 0
	} Else {
		// Editing existing application
		Set ..EditHeader = $$$FormatText($$$Text("Edit definition for privileged routine application %1:"),..PID)
		Set ..RolesHeader = $$$FormatText($$$Text("Edit roles for privileged routine application %1:"),..PID)
		Set ..RoutinesHeader = $$$FormatText($$$Text("Edit routines and classes for privileged application %1:"),..PID)
		Set ..%GetComponentById("Text1").value = ..EditHeader
		
		Kill Properties
		Set tSC = ##class(Security.Applications).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ..%GetComponentById("svgTabArea").hidden = 1
			Set ..%GetComponentById("svgTabArea").height = 0
			Quit $$$OK
		}
		
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("Name").disabled = 1
		
		// Loop to set all field values
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		
		// Populate the Location dropdown
		Set tRS = ##class(%ResultSet).%New("Config.Databases:List")
		Do tRS.Execute("*")
		Set valueList = ""
		While tRS.Next() {
			Set name = tRS.GetData(1)
			If valueList = "" {
				Set valueList = name
			} Else {
				Set valueList = valueList_","_name
			}
		}
		Set ..%GetComponentById("Location").displayList = $$$Text("--- Select a database name ---")_","_valueList
		Set ..%GetComponentById("Location").valueList = ","_valueList
	}
	
	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Privileged Routine Applications","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Privileged Routine Application")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
