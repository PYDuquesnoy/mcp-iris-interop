/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created using the page template: Default
Class Ens.Enterprise.Portal.SystemList Extends (EnsPortal.Template.standardPage, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Enterprise Systems";

/// User needs READ permissions on the %Ens_MsgBank resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank:READ";

/// User needs WRITE permissions on the %Ens_MsgBankConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_MsgBankConfig:WRITE";

Property canViewEvents As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankEventLog).#RESOURCE)} ];

Property canViewMessages As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankViewer).#RESOURCE)} ];

Property canViewSearch As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.EnterpriseSearch).#RESOURCE)} ];

Property canViewMonitor As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MonitorStatus).#RESOURCE)} ];

Property NewConnection As %Boolean [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
   
/*fieldSet styles*/
.fieldset{
     background: #FFFFFF;
     border: solid 2px #ebf3ff;
     color: #000000;
     font-size: 1em;
     font-family: helvetica;

}

table.group td.msgBankLink {
	text-align: center;
	padding-left: 30px;
	padding-right: 30px;
}
</style>
}

/// This XML block defines the contents of this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<titleBox id="idTitle" title="" />
<hgroup width="100%">
<spacer width="1em"/>
<vgroup>
<spacer height="1em"/>
<hgroup>
<tableNavigator id="connectionsNav" tablePaneId="ConnectionInfoTable"/>
<spacer width=".5em"/>
<button caption="New Connection" id="openNewForm" onclick="zenPage.openNewConnectionInfoForm()"/>
<spacer width="50em"/>
</hgroup>
<spacer height="1em"/>
<tablePane
    width="90%"
    id="ConnectionInfoTable"
    queryClass="Ens.Enterprise.MonitorClient"
    queryName="EnumerateClients"
    maxRows="1000" 
    pageSize="10" 
    useSnapshot="true"
    rowSelect="false"
    extraColumnWidth="5%"
    showZebra="true"
    caption="Client Systems">
<column colName="ID" hidden="true" width="2%"/>
<column colName="IsNode" hidden="true" width="2%"/>
<column header="Client Nickname" width="19%" colName="Name" filterType="text"/>
<column header="Node Id" width="7%" colName="NodeId" filterType="text"/>
<column header="Web IP Address" title ="please enter the full webserver IP address with port: (18.209.0.57:7752) or the dns name with port: www.mycompany.com:57772" 
   width="17%" colName="WebIPAddress"/>
<column header="Namespace" width="10%" colName="Namespace"/>
<column header="SSL Configuration" width="8%" colName="SSLConfig"/>
<column header="SOAP Credentials" width="11%" colName="SOAPCredentials"/>
<column header="Service Path" width="18%" colName="ServicePath" hidden="false" />
<column header="Threshold" width="5%" colName="QueueThreshold"/>

<column header="" width="4%" linkCaption="edit" 
         link="javascript:zenPage.showConnectionInfoForm('#(%query.ID)#');"/>
<column header="" width="4%" linkCaption="delete" 
         link="javascript:zenPage.maybeDelete('#(%query.ID)#');"/>
<column colName="HomePath" hidden="true" />
<column colName="HomePage" hidden="true" />
<column colName="Version" hidden="true" />
<column colName="SSLCheckServerIdentity" hidden="true"/>
</tablePane>
<spacer height="1em"/>
<html OnDrawContent="DrawMsgBankLinks" />
<spacer height="1em"/>
<fieldSet id="connectionsFormGroup" hidden="true" legend="Edit Client connection info">
<form id="connectionsForm" 
         controllerId="connectionsData" 
         layout="vertical"
         cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
 
<text label="Name:" required="true" dataBinding="Name" id="Name" name="Name" size="40"/>
<text label="Web IP Address: (including port)" dataBinding="WebIPAddress" id="WebIPAddress" name="WebIPAddress" required="true"
           size="40" title="please enter the full ip address with port: (18.209.0.57:7752) or the dns name with port: www.mycompany.com:57772"/>
<hgroup>
<text label="Namespace:" dataBinding="Namespace" required="true"
                id="NamespaceBox" size="25"/> 
<spacer width=".5em" />
<text label="Queue Threshold:" dataBinding="QueueThreshold" id="QueueThreshold" name="QueueThreshold" size="10" />
</hgroup>
<text label="Service Web Application Path:" dataBinding="ServicePath" id="ServicePath" name="ServicePath"
	size="40" title="This is the / terminated URL path to the client's web application for the service %CSP.Monitor.Server in this namespace. Do not include http(s)://. For HealthShare this could for example be /csp/healthshare/namespace/services/ Leave blank to default to /csp/namespace/"/>
<selector id="soapCreds" dataBinding="SOAPCredentials" label="Soap Credentials:" name="SoapCreds" context="Ens.ContextSearch/Credentials" />
<selector id="sslConfig" dataBinding="SSLConfig" label="SSL Configuration:" name="sslConfig" context="Ens.ContextSearch/SSLConfigs" />
<checkbox id="sslCheckServerIdentity" dataBinding="SSLCheckServerIdentity" label="SSL Check Server Identity" name="sslSSLCheckServerIdentity"/>
<hgroup>
<button caption="Save" id="save" onclick="zenPage.saveConnectionInfo();" />
<spacer width=".5em"/>
<button caption="Hide Form" onclick="zenPage.hideConnectionInfoForm();" />  
</hgroup>   
</form>
</fieldSet>
<hgroup width="5px"/>
</vgroup>
</hgroup>
<dataController id="connectionsData"  
    modelClass="Ens.Enterprise.Portal.MonitorModel" 
    modelId=""
/>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zenPage.NewConnection) {
		zenPage.openNewConnectionInfoForm();
	}
}

ClientMethod hideConnectionInfoForm() [ Language = javascript ]
{
	var connectionsFormGroup=zenPage.getComponentById("connectionsFormGroup");
	connectionsFormGroup.setProperty('hidden',true);
}

ClientMethod openNewConnectionInfoForm() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('connectionsData');
	controller.createNewObject();	
	var connectionsFormGroup = zen("connectionsFormGroup");
	connectionsFormGroup.setProperty('legend', $$$Text('Info for new Client connection'));
	connectionsFormGroup.setProperty('hidden',false);
	var nameControl = zen('Name');
	nameControl.setProperty('readOnly',false);
	nameControl.setProperty('disabled',false);
	var thresholdControl = zen('QueueThreshold');
	thresholdControl.setProperty('readOnly',false);
	thresholdControl.setProperty('disabled',false);	
	var servicepathControl = zen('ServicePath');
	servicepathControl.setProperty('readOnly',false);
	servicepathControl.setProperty('disabled',false);
	var sslCheckServerIdentityControl = zen('sslCheckServerIdentity');
	sslCheckServerIdentityControl.setProperty('readOnly',false);
	sslCheckServerIdentityControl.setProperty('disabled',false);
}

ClientMethod showConnectionInfoForm(id) [ Language = javascript ]
{
	var controller = zen('connectionsData');
	controller.setProperty('modelId',id);
	var connectionsFormGroup = zen("connectionsFormGroup");
	connectionsFormGroup.setProperty('legend', $$$Text('Edit Client connection info'));
	var nameControl = zen('Name');
	var disableNameControl = (nameControl.getValue() != '');
	var nameTitle = (disableNameControl ? $$$Text('To change the name you need to delete and recreate this entry.') : '');
	nameControl.setProperty('title',nameTitle);
	nameControl.setProperty('readOnly',disableNameControl);
	nameControl.setProperty('disabled',disableNameControl);
	var thresholdControl = zen('QueueThreshold');
	thresholdControl.setProperty('readOnly',false);
	thresholdControl.setProperty('disabled',false);
	var servicepathControl = zen('ServicePath');
	servicepathControl.setProperty('readOnly',false);
	servicepathControl.setProperty('disabled',false);
	var sslCheckServerIdentityControl = zen('sslCheckServerIdentity');
	sslCheckServerIdentityControl.setProperty('readOnly',false);
	sslCheckServerIdentityControl.setProperty('disabled',false);
	connectionsFormGroup.setProperty('hidden',false);
}

/// save connections model to database
ClientMethod saveConnectionInfo() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	// validate and save form
	var form = zenPage.getComponentById('connectionsForm');
	var servicepathControl = zen('ServicePath');
	var serviceURL=servicepathControl.getValue();
	if ((serviceURL!=='') && (serviceURL.charAt(0)!=="/")) {
		alert($$$Text('Service URL does not start with a \/\n Please edit and resave if needed.'));			
	}
	form.save();
	var table=zenPage.getComponentById('ConnectionInfoTable');
	//refresh data in connections table
	table.executeQuery();
}

/// Delete current item from database- after confirming
ClientMethod maybeDelete(id) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	var controller = zenPage.getComponentById('connectionsData');

	if ('' == id) {
		alert('Nothing selected to delete.');
	}
	else if (confirm('Do you wish to delete this item?')) {
		controller.deleteId(id);

		var table = zenPage.getComponentById('ConnectionInfoTable');
		table.executeQuery();
		//controller.update();
	}
}

Method DrawMsgBankLinks(pSeed) As %Status
{
	Set tDisabledAttr = "onclick=""return false;"" class=""msgBankLink disabledMsgBankLink"" title="""_..msgNotPermitted_""""
	&html<<table class="group" cellpadding="0" cellspacing="0" border="0" style="font-size: 0.9em;">
	<tr>>
	If ..canViewMonitor {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MonitorStatus.zen"))#">#($$$TextHTML("Enterprise Monitor"))#</a></td>>
	}
	If ..canViewSearch {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.EnterpriseSearch.zen"))#">#($$$TextHTML("Enterprise Message Viewer"))#</a></td>>
	}
	If ..canViewMessages {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MsgBankViewer.zen"))#">#($$$TextHTML("Message Bank Viewer"))#</a></td>>
	}
	If ..canViewEvents {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MsgBankEventLog.zen"))#">#($$$TextHTML("Message Bank Event Log"))#</a></td>>
	}
	&html<</tr>
	</table>>
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ..%GetComponentById("idTitle").title = $$$FormatText($$$Text("View and edit participating enterprise client systems"))

	// Set data controller to be readOnly if the user can't edit
	Set tController = ..%GetComponentById("connectionsData")
	Set tController.readOnly = '..canEdit
	
	// Open New Connection Info form is specified in request
	Set ..NewConnection = +$G(%request.Data("NEWCONNECTION",1))

	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("Enterprise Systems")
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Enterprise Systems")
}

}
