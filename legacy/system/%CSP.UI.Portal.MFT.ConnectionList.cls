/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Managed File Transfer Connection List page
Class %CSP.UI.Portal.MFT.ConnectionList Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Manager File Transfer Connections";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.MFT.ConnectionList.zen";

Parameter HELPADDRESS = "System Administration,Security,Managed File Transfer Connections";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.MFT.Connection.zen",,1)} ];

Property ConnectionName As %ZEN.Datatype.string(ZENURL = "ConnectionName");

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<vgroup id="idTable">
<tableNavBar id="tableBar" showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="%SYS.MFT.Connection.Base"
queryName="List"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="false"
>

<column colName="Name" header="Connection Name" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"/>
<column colName="Service" header="Service" />
<column colName="IsAuthorized" header="Status" />
<column id="colGet" linkCaption="Get Access Token" link="javascript:zenPage.doGetToken('#(%query.Name)#');" />
<column id="colRevoke" linkCaption="Revoke Access Token" link="javascript:zenPage.doRevokeToken('#(%query.Name)#','#(%query.IsAuthorized)#');" />
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.Name)#');" linkConfirm="Are you sure you want to delete connection '%1'?" />
<parameter value="*"/>
 </tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of Managed File Transfer Connections.")

	Set errorMessage=""
	Set name=..ConnectionName
	If name'="" {
		Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.sc)
		If $$$ISERR(sc) {
			Set errorMessage = $system.Status.GetErrorText(sc)
		} Else {
			Set authorized=connection.IsAuthorized(.errorMessage)
			If 'authorized,errorMessage'="" {
				Set errorMessage=$$$FormatText($$$Text("Error authorizing connection %1: %2"),name,errorMessage)
			}
		}
	}

	Set ..%GetComponentById("idRespond").value = errorMessage
	Set ..%GetComponentById("idRespond").hidden = (errorMessage="")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Managed File Transfer Connections")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$zconvert(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create Connection"),$$$Text("Create a new Managed File Transfer connection"),"zenPage.doNew();")

	Quit $$$OK
}

ClientMethod doNew() [ Language = javascript ]
{
	try {
		var url = this.EditPage + "isNew=1";
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(ApplicationName) [ Language = javascript ]
{
	try {
		var url = this.EditPage + "PID="+encodeURIComponent(ApplicationName);
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing configuration.
ClientMethod deleteSetting(name) [ Language = javascript ]
{
	try {
		// need to temparily make changesMade to false so that onunload will not prompt
		var ok = this.DeleteItem(name);
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery();
		 	zen("idRespond").setHidden(true);
			zen("idRespond").setValue("");
		} else {
		 	zen("idRespond").setHidden(false);
			zen("idRespond").setValue(ok);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Call server delete method.
ClassMethod DeleteItem(name) As %String [ ZenMethod ]
{
	Try {
		Set sc=##class(%SYS.MFT.Connection.Base).DeleteId(name)

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) {
		Set ok = $System.Status.GetErrorText(sc)
	} Else {
		Set ok = 1
	}
	
	Quit $zcvt(ok,"O","HTML")
}

ClientMethod doGetToken(name) [ Language = javascript ]
{
	if (name != "") {
		var tProxy = this.GetToken(name);
		if (tProxy.ok == 1) {
			if (tProxy.AuthorizationCodeURL != "") {
				window.location.href = tProxy.AuthorizationCodeURL;
			} else {
				alert("Internal error: Unable to obtain authorization code URL.");
			}
		}
		if (ok == 1) {
		 	zen("idRespond").setHidden(true);
			zen("idRespond").setValue("");
		} else {
		 	zen("idRespond").setHidden(false);
			zen("idRespond").setValue(tProxy.ErrorMessage);
		}
	} else {
		alert("Internal error: Name not specified.");
	}
}

ClassMethod GetToken(name As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {
		#; Initialize return proxy object
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ""
		Set tProxy.AuthorizationCodeURL = ""

		#; Get URL for authorization code.
		If name'="" {
			Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.sc)
			If $$$ISOK(sc) {
				Set scope=connection.DefaultScope()
				Set redirect=$select(%request.Secure:"https://",1:"http://")_%request.GetCgiEnv("HTTP_HOST")
				Set redirect=redirect_##class(%CSP.Page).EscapeURL(%request.Application_$classname())_".zen"
				Set redirect=redirect_"?ConnectionName="_##class(%CSP.Page).EscapeURL(connection.Name)
				Set redirect=redirect_"&PageScope="_##class(%CSP.Page).EscapeURL(scope)
				Set tProxy.AuthorizationCodeURL=connection.GetAuthorizationCodeURL(redirect,scope,,.sc)
				If $$$ISOK(sc) {
					Set tProxy.ok = 1
				} Else {
					Set tProxy.ErrorMessage = $system.Status.GetErrorText(sc)
				}
			} Else {
				Set tProxy.ErrorMessage = $$$Text("Unable to open connection: ")_$zconvert(name,"O","HTML")
			}
	}
	} Catch ex {
		Set tProxy.ErrorMessage = ex.DisplayString()
	}
	
	Set tProxy.ErrorMessage=$zcvt(tProxy.ErrorMessage,"O","HTML")
	
	Quit tProxy
}

ClientMethod doRevokeToken(name, isAuthorized) [ Language = javascript ]
{
	if (name != "") {
		var ok;
		var ok = this.RevokeToken(name,isAuthorized);
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.executeQuery();
		 	zen("idRespond").setHidden(true);
			zen("idRespond").setValue("");
		} else {
		 	zen("idRespond").setHidden(false);
			zen("idRespond").setValue(ok);
		}
	} else {
		alert("Internal error: Name not specified.");
	}
}

ClassMethod RevokeToken(name As %String, isAuthorized As %String) As %String [ ZenMethod ]
{
	Try {
		If isAuthorized'="Authorized" {
			Set ok=$$$Text("No access token to revoke")
			Quit
		}
		
		If name'="" {
			Set connection=##class(%SYS.MFT.Connection.Base).Open(name,.sc)
			If $$$ISOK(sc) {
				Set sc = connection.RevokeToken()
				If $$$ISERR(sc) {
					Set ok = $System.Status.GetErrorText(sc)
				} Else {
					Set ok = 1
				}
			} Else {
				Set ok = $$$Text("Unable to open connection: ")_$zconvert(name,"O","HTML")
			}
		} Else {
			Set ok = $$$Text("Connection name must be specified.")
		}
	} Catch ex {
		Set ok = ex.DisplayString()
	}
	
	Quit $zcvt(ok,"O","HTML")
}

}
