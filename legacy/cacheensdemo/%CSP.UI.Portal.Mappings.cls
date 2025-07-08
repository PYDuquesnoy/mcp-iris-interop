/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syConfig

/// Zen page for System Management Portal - Show Databases Freespace
Class %CSP.UI.Portal.Mappings Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Mappings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mappings.zen";

Parameter HELPADDRESS = "Home,Configuration,Namespaces,Global Mappings";

Parameter EMSSERVICE = "Namespace";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Namespaces.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property CPFMapFile As %String;

Property CPFMapName As %String;

Property EditPage As %String;

Property MapType As %ZEN.Datatype.string(ZENURL = "MapType");

Property Namespace As %ZEN.Datatype.string(ZENURL = "PID");

XData Style
{
<style type="text/css">
.brownnote {
	color: #DA4848;
	font-size: 0.8em;
}
.link {
	color:#333695;	
	text-decoration: underline;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<vgroup id="idWarning"  hidden="true" cellStyle="padding-bottom:2px;" containerStyle="padding:2px;height:1.5em;">
<label id="id_Warning" value="" enclosingClass="brownnote"/>
</vgroup>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<tableNavBar id="tableNav" showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
 title="Enter the leading characters of a global name followed by [Tab] to filter the list. For example: C for all global names starting with letter 'C'."/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
queryName="List"
>
<column colName="Name" hidden="true"/>
<column colName="Global" header="Global"/>
<column colName="Subscript" header="Subscript"/>
<column colName="Database" header="Database" />
<column colName="Collation" id="CollationCol" OnDrawCell="DrawCollation" style="text-align:left;" hidden="true"/>
<column colName="LockDatabase" id="LockDBCol" header="Lock Database" hidden="true"/>
<column colName="Routine" header="Routine"/>
<column colName="Type" header="Type"/>
<column colName="Package" header="Package"/>
<column linkCaption="Edit" id="LinkEdit" width="80" link="#" onclick="zenPage.editMapping('#(%query.Name)#');return false;" hidden="#(%page.IsEMSReadOnly)#"/>
<column linkCaption="Delete" id="LinkDelete" width="80" link="#" onclick="zenPage.deleteMapping('#(%query.Name)#');return false;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="#(%page.Namespace)#"/>
<parameter value="#(%page.Filter)#"/>
<parameter value="#(%page.CPFMapFile)#"/>
<parameter value="0"/>
</tablePane>
 </form>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	if (value.indexOf("*") == -1) {
		value += "*";
	}
	table.parameters[1].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows,this.MapType);
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set tooltip = $Case(..MapType,"Gbl":$$$TextHTML("New Global Mappings"),"Rtn":$$$TextHTML("New Routine Mappings"),:$$$TextHTML("New Package Mappings"))
	Set pCommands(1) = $LB("btnNew",$$$Text("New"),tooltip,"zenPage.editMapping('');")
	Set pCommands(2) = $LB("btnSave",$$$Text("Save Changes"),$$$Text("Save all new changes"),"zenPage.doSave();")
	Set pCommands(3) = $LB("btnDiscard",$$$Text("Discard Changes"),$$$Text("Discard all new changes"),"zenPage.doDiscard();")
	Set pCommands(4) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return to Home page without saving new changes"),"zenPage.doCancel();")

	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..MapType,"Gbl":$$$TextHTML("Global Mappings"),"Rtn":$$$TextHTML("Routine Mappings"),:$$$TextHTML("Package Mappings"))
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit ..%OnGetTitle()
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	#; Know what type of mapping we are doing
	If ..MapType = "" Set ..MapType = "Gbl"
	Do ..%GetNavTableState(..MapType_..%GetPageName())
	Set espNamespace = ..EscapeHTML(..Namespace)
	If ..MapType = "Gbl" {
		Set EditPage = "%CSP.UI.Portal.Mappings.Global.zen"
		Set ..%GetComponentById("table").queryClass = "Config.MapGlobals"
		Set ..lblTitle = $$$FormatText($$$Text("The global mappings for namespace %1 are displayed below:"),espNamespace)
		Set ..HelpAddress = "Home,Configuration,Namespaces,Global Mappings"
		If ..IsEMSReadOnly {
			Set ..%GetComponentById("CollationCol").hidden = 0
			Set ..%GetComponentById("LockDBCol").hidden = 0
		}
	} ElseIf ..MapType = "Rtn" {
		Set EditPage = "%CSP.UI.Portal.Mappings.Routine.zen"
		Set ..%GetComponentById("table").queryClass = "Config.MapRoutines"
		Set ..lblTitle = $$$FormatText($$$Text("The routine mappings for namespace %1 are displayed below:"),espNamespace)
		Set ..HelpAddress = "Home,Configuration,Namespaces,Routine Mappings"
	} ElseIf ..MapType = "Prj" {
		Set EditPage = "%CSP.UI.Portal.Mappings.Package.zen"
		Set ..%GetComponentById("table").queryClass = "Config.MapPackages"
		Set ..lblTitle = $$$FormatText($$$Text("The package mappings for namespace %1 are displayed below:"),espNamespace)
		Set ..HelpAddress = "Home,Configuration,Namespaces,Package Mappings"
	} Else {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Set ..lblTitle = $$$TextHTML("Incorrect map type. Unable to continue.")
		Quit $$$OK
	}
	Set ..EditPage = ..Link(EditPage,,1)
	
	If '##class(Config.Namespaces).Exists(..Namespace) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set ..%GetComponentById("id_Warning").value = $$$Text("Item(s) changed. Click 'Save Changes' to save into the Configuration file or 'Discard Changes' to discard all changes.")
	
	Set tSC = ##Class(Config.CPF).FileToName(.CPFFile,.CPFName,.CPFMapFile,.CPFMapName)	
	If $$$ISERR(tSC) Quit tSC

	Set ..CPFMapFile = CPFMapFile
	Set ..CPFMapName = CPFMapName
	If ($g($$$CONFIG2(CPFName,$$$CPFSHA256Hash))'=##Class(%Library.File).GetFileSHA256Hash(CPFFile)) {
		Set ..%GetComponentById("LinkEdit").hidden = 1
		Set ..%GetComponentById("LinkDelete").hidden = 1
		Set ..%GetComponentById("id_Warning").value = $$$FormatText($$$Text("Warning, mapping data cannot be modified, the %1 file has been modified by a text editor."),CPFFile)
		Set ..%GetComponentById("idWarning").hidden = 0
		q $$$OK
	}
	#; Initialize CPF related files
	Set tSC = ..Init(CPFName)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("LinkEdit").hidden = 1
		Set ..%GetComponentById("LinkDelete").hidden = 1
		Set ..%GetComponentById("id_Warning").value = $SYSTEM.Status.GetErrorText(tSC)
		Set ..%GetComponentById("idWarning").hidden = 0
		Quit $$$OK
	}
	Quit $$$OK
}

/// Process Add or Edit. Open popup window and pass in parameters.
ClientMethod editMapping(selectedName) [ Language = javascript ]
{
	try {
		var url = this.EditPage+"$ID1="+encodeURIComponent(this.Namespace)+"&$ID2="+encodeURIComponent(selectedName);
		zenLaunchPopupWindow(url,'EditMapping','resizable,width=800,height=550');
	 } catch (ex) {
		alert("Error: " + ex);	
	 }
}

/// Delete existing mapping.
ClientMethod deleteMapping(idRow) [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.CPFMapFile = this.CPFMapFile;
		proxy.CPFMapName = this.CPFMapName;
		proxy.MapType = this.MapType;
		proxy.Namespace = this.Namespace;
		var ok = this.DeleteItem(idRow,proxy);
		if (ok != 1) {
			alert(ok);
		} else {
			this.refreshTable(0);
			zenPage.setModified(true);
		}
	} catch (ex) {
		alert("Error: " + ex);
	}
}

/// Save current mappings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.MapType = this.MapType;
		proxy.Namespace = this.Namespace;
		var ok = this.SaveChanges(proxy);
		if (ok != 1) {
			alert(ok);
		} else {
			zen("idWarning").setHidden(true);
			zenPage.setModified(false);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Cancel current mappings.
ClientMethod doDiscard() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.MapType = this.MapType;
		proxy.Namespace = this.Namespace;
		var ok = this.CancelChanges(proxy);
		if (ok != 1) {
			alert(ok);
		} else {
			this.refreshTable(1);		
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Refresh table. 
/// flag = 1: user has either Saved Changes or Canceled Changes.<br>
/// flag = 0: user returned from Edit or Delete. Leave changeMade flag to be true
ClientMethod refreshTable(flag) [ Language = javascript ]
{
	try {
		var modified = (flag) ? false: true;
		zenPage.setModified(modified);
		zen("idWarning").setHidden(flag);
		// refresh table
		var table = zen('table');
		table.clearSnapshot = true
		table.executeQuery();
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((action == "ok") || (action == "apply")) {
			this.refreshTable(0);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Initialize CPF file/global
Method Init(CPFName As %String) As %Status
{
	i $g($$$CONFIG1(..CPFMapName))'="" {
		s Status=$$$ERROR($$$GeneralError,$$$Text("Warning, mapping data cannot be modified,")_" DataMove "_$$$CONFIG1(..CPFMapName)_" "_$$$Text("is currently using the mapping space."))
		q Status
	}
	Try {
		#;When first loading the page, we copy all the mappings from the current CPF object into this
		#;temporary object. When we save the change, we merge it back in into the current 
		#;CPF object. We need the databases/namespaces copied here since a mapping save requires
		#;that the database and namespace be there also
	
		Set Index = $case(..MapType,"Gbl":"MapGlobals","Rtn":"MapRoutines","Prj":"MapPackages")
		Kill $$$CONFIG3(..CPFMapName,Index,..Namespace)
		Merge $$$CONFIG3(..CPFMapName,Index,..Namespace) = $$$CONFIG3(CPFName,Index,..Namespace)
		Kill $$$CONFIG2(..CPFMapName,"Databases")
		Merge $$$CONFIG2(..CPFMapName,"Databases") = $$$CONFIG2(CPFName,"Databases")
		Kill $$$CONFIG2(..CPFMapName,"Namespaces")
		Merge $$$CONFIG2(..CPFMapName,"Namespaces") = $$$CONFIG2(CPFName,"Namespaces")
		
		Set tSC = $$$OK
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Call server save method.
ClassMethod SaveChanges(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = ##class(%CSP.UI.System.MappingsAPI).SaveChangeList(pProxy.Namespace,pProxy.MapType)
	If $$$ISERR(tSC) Set tmsg = $ZCVT($System.Status.GetErrorText(tSC),"O","JS") Quit tmsg
	Quit 1
}

/// Call server cancel method.
ClassMethod CancelChanges(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = ##class(%CSP.UI.System.MappingsAPI).ClearChangeList(pProxy.Namespace,pProxy.MapType)
	If $$$ISERR(tSC) Set tmsg = $ZCVT($System.Status.GetErrorText(tSC),"O","JS") Quit tmsg
	Quit 1
}

/// Call server delete method.
ClassMethod DeleteItem(Name As %String, pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Try {
		If pProxy.MapType = "Gbl" {
			Set ClassName = "MapGlobals"
		} ElseIf pProxy.MapType = "Rtn" {
			Set ClassName = "MapRoutines"
		} Else {
			Set ClassName = "MapPackages"
		}
		
		Set tSC = $ClassMethod("Config."_ClassName,"Delete",pProxy.Namespace,Name,pProxy.CPFMapFile,$$$CPFSave)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		#;Flag to let us know that we have changed mappings
		Set $$$CONFIG3(pProxy.CPFMapName,ClassName,pProxy.Namespace) = 1

		Set tmsg = 1
	} Catch Error {
		TROLLBACK 1
		Set tmsg = $ZCVT($System.Status.GetErrorText(tSC),"O","JS") 
	}
	Quit tmsg
}

Method DrawCollation(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $zconvert(##class(%Collate).LogicalToDisplay(%query(pName)),"O","HTML")
	Quit $$$OK
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	/// YSD2322 Temporarily change the timeout for this page to 180
	If +%request.GatewayTimeout < 180 {
		Set %response.Timeout = 180
	}
	Quit 1
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("Namespaces","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set tURL = ..Link($ZCVT($className(),"O","URL")_".zen"_"?MapType="_..EscapeURL(..MapType)_"&PID="_..EscapeURL(..Namespace))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Quit $$$OK
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	this.invokeSuper('setModified',arguments);
	if (flag == true) {
		this.enableCommandButton('btnSave');
		this.enableCommandButton('btnDiscard');
	} else {
		this.disableCommandButton('btnSave');
		this.disableCommandButton('btnDiscard');
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen('idWarning').getProperty('hidden') == false) {
		this.disableCommandButton('btnNew');
	}
	this.setModified(false);
}

ClientMethod removeElement(el) [ Language = javascript ]
{
	el.parentNode.removeChild(el);
}

/// Overriden to add MapType to the page name to distinguish the type for the page.
ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,this.MapType);
}

/// Overriden to add MapType to the page name to distinguish the type for the page.
ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value,this.MapType);
}

/// Used to Save tableNavBar values, add MapType to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, pMapType As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,pMapType_..%GetPageName(),"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

}
