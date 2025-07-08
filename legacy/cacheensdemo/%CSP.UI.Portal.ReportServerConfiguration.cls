/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Management Portal - Configure a Report Server via the Logi Report Server portal
Class %CSP.UI.Portal.ReportServerConfiguration Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Configure Report Server";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ReportServerConfiguration.zen";

Parameter HELPADDRESS = "Home,Configuration,Reports (Logi Analytics)";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ReportServers.zen";

Property rsName As %ZEN.Datatype.string;

Property rsHost As %ZEN.Datatype.string;

Property rsPort As %ZEN.Datatype.string;

Property rsSSO As %ZEN.Datatype.boolean;

Property session As %ZEN.Datatype.string;

Property defaultURI As %ZEN.Datatype.string;

/// 
/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
    background-image: url('');
}
.EditForm td > * {
}

.boxedArea {
    border: 1px solid black;
    margin-left: 5px;
    padding: 3px;
}

a.link {
    font-size: 16px;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
    <hgroup>
    <label id="Text1" value="Select a user to configure #(%page.rsName)# or " containerStyle="padding-bottom:4px;"/>
    <link caption="sign in manually." href="#(%page.defaultURI)#" containerStyle="padding-bottom:4px;"/>
    </hgroup>
    <spacer height="10" />
    <label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
    <tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table"
    saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
    />
    <tablePane id="table"
    queryClass="Report.ExternalUser"
    queryName="AllReportRoles"
    dataSource="columns"
    fixedHeaders="false"
    ondblclick="zenPage.doSelect();"
    pageSize="0"
    maxRows="1000"
    showValueInTooltip="false"
    showZebra="true"
    valueColumn="ReportUser"
    useSnapshot="true"
    width ="600"
    >
    <parameter value="#(%page.rsName)#"/>
    <parameter value="#(%page.rsSSO)#"/>
    <column colName="ReportUser" header="Report User" />
    <column linkCaption="Select" link="#" onclick="zenPage.doSelect('#(%query.ReportUser)#');"/>
     </tablePane>
    </pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
    this.invokeSuper('onloadHandler',arguments);
}

Method %OnAfterCreatePage() As %Status
{
        Set tSC = ##super()
        If $$$ISERR(tSC) Quit tSC
    
        // fail silently, this is clean up and does not affect the current user
        Do ##class(Report.ExternalUser).CleanTokens()
        
        Set ..lblTitle = $$$Text("Each report server defines its own users. Select a user to configure this report server as, or configure without signing in.")
    
        Set (..LocatorHeader,..StdTitle) = $$$Text("Report Server Configuration")
        
        If '##class(%Report.ServerDefinition).%ExistsId(..PID) {
            Quit $$$Text("Invalid Server Definition")
        }
        Set rs = ##class(%Report.ServerDefinition).%OpenId(..PID)
        Set %page.rsName = rs.Name
        Set %page.rsHost = rs.Host
        Set %page.rsPort = rs.Port
        Set %page.rsSSO = rs.SSOEnabled
        
        Set %page.session = %session.SessionId
        Set %page.defaultURI = ..formatURI()
        
        Set tSC = ##class(Report.ExternalUser).RevokeToken(%page.rsName, %page.session)
        Quit:$$$ISERR(tSC) tSC
    
        Quit $$$OK
}

Method %OnGetTitle() As %String
{
    Quit ..EscapeHTML(..PID)
}

///     Return the array of links to show in the locator bar.<br/>
///     pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
        Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
        Set tPageName = $$$Text("System","%Utility")
        Set tURL = ..Link($$$GetHomePage)
        Set pLink($I(pLink)) = $LB(tPageName,tURL)
    
        Set tPageName = $$$Text("Configuration","%Utility")
        Set pLink($I(pLink)) = $LB(tPageName,tURL)
    
        Set tPageName = $$$Text("InterSystems Reports","%Utility")
        Set tURL = ..Link(..ParentURL)
        Set pLink($I(pLink)) = $LB(tPageName,tURL)
        
        // default: add *this* page to list
        Set tPageName = ..%OnGetPageName()
        Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?rsName="_..rsName_"rsHost="_..rsHost_"rsPort="_..rsPort_"&PID="_$ZCVT($ZCVT(..PID,"O","UTF8"),"O","URL")_"&"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
    
        Quit $$$OK
}

///     Edit the current row
ClientMethod doSelect(pReportUser) [ Language = javascript ]
{
        if (pReportUser === undefined) {
            pReportUser = zenPage.getComponentById('table').getValue();
        }
        try {
            var PID = zenPage.issueToken(pReportUser);
            zenPage.gotoPage(zenPage.formatURI(PID) + encodeURIComponent(zenPage.getToken(PID)));
        } catch (ex) {
            zenPage.showMsg('Error: ' + ex);    
        }
}

Method issueToken(pReportUser) As %String [ ZenMethod ]
{
    Quit ##class(Report.ExternalUser).IssueToken(%page.session, %page.rsName, pReportUser)
}

Method formatURI(PID = -1) As %String [ ZenMethod ]
{
        Set uri = "//" _ %page.rsHost _ ":" _ %page.rsPort 
        if (##class(Report.ExternalUser).%ExistsId(PID)) {
            Set tExternalUser = ##class(Report.ExternalUser).%OpenId(PID)
            Set uri = uri _ "/externalauth.jsp?auth_id=" _ PID _ "&auth_key="
        }
        Quit uri
}

Method getToken(PID = -1) As %String [ ZenMethod ]
{
                if (##class(Report.ExternalUser).%ExistsId(PID)) {
                    Set tExternalUser = ##class(Report.ExternalUser).%OpenId(PID)
                    Quit tExternalUser.AuthToken
                }
                Quit ""
}

///     Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
        Set pDisplay = 1
        Set pSearchBox = 0
        Set pRibbonTitle = ..%OnGetPageName()
    
        Quit $$$OK
}

}
