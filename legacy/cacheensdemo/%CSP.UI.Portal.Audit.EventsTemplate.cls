/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Audit Events Template
Class %CSP.UI.Portal.Audit.EventsTemplate Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ Abstract, System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "System Audit Events";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}
</style>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[0].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

ClientMethod doReset(event) [ Language = javascript ]
{
	var result = this.Reset(event);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(true);
}

ClientMethod doChangeStatus(event) [ Language = javascript ]
{
	var result = this.ChangeStatus(event);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(true);
}

ClientMethod doGetStatus(event) [ Language = javascript ]
{
	var result = this.GetStatus(event);
	if (result.ok != 1) alert(result.ErrorMessage);
	return result.payload
}

ClassMethod Reset(event As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Security.Events).Clear($P(event,"/",1),$P(event,"/",2),$P(event,"/",3))
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tProxy
}

ClassMethod ChangeStatus(event As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##class(Security.Events).Get($P(event,"/",1),$P(event,"/",2),$P(event,"/",3),.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set Properties("Enabled") = $S(Properties("Enabled")=1:0,1:1)
		Set tSC = ##class(Security.Events).Modify($P(event,"/",1),$P(event,"/",2),$P(event,"/",3),.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tProxy
}

ClassMethod GetStatus(event As %String) As %ZEN.proxyObject [ ZenMethod ]
{

	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##class(Security.Events).Get($P(event,"/",1),$P(event,"/",2),$P(event,"/",3),.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		set tProxy.payload = Properties("Enabled")
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tProxy
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
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
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

}
