/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.ConfigItemSelector Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_Code, %Ens_RoutingRules or %Ens_BusinessRules
Parameter RESOURCE = "%Ens_Rules:WRITE,%Ens_Code:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

Parameter APPLYBUTTON = 0;

/// Flag to indicate whether "source" or "target" properties are desired.
Property TYPE As %String(ZENURL = "TYPE") [ InitialExpression = "target" ];

/// Flag to indicate whether multiple configuration items may be selected.
Property MULTI As %Boolean(ZENURL = "MULTI") [ InitialExpression = 1 ];

/// Name of the production to use.
Property PROD As %String(MAXLEN = 128, ZENURL = "PROD");

/// The current value of the control.
Property CURRVALUE As %String(MAXLEN = "", ZENURL = "VALUE");

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none">
<group  enclosingStyle="padding:20;" layout="none">
<group id="warningGroup" layout="none" hidden="true">
<label labelClass="zenLabel warningLabel" label="No production name has been specified in the General tab of your rule. Be careful to choose target(s) that exist in your production." />
</group>
<hgroup>
<label label="Current Production:" />
<spacer width="5" />
<label id="prodName" />
</hgroup>
<spacer height="20" />
<selector id="configItems" title="Available configuration items" size="80" label="Configuration Items" context="Ens.ContextSearch/ProductionItems"/>
</group>
</pane>
}

XData Style
{
<style type="text/css">
.labelText {
	font-size: 0.9em;
	font-weight: bold;
}

#warningGroup {
	border: 1px solid #D0D0D0;
	margin-bottom:  20px;
	padding: 2px;
	border: 1px solid #D04040;
	border-radius: 4px;
	background: #F04040;
background: -moz-linear-gradient(top, #F04040, #800000);
background: -webkit-linear-gradient(top, #F04040, #800000);
	background: linear-gradient(top, #F04040, #800000);
}

.zenLabel.warningLabel {
	color: white;
}
</style>
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Production Configuration Item Selector")
}

Method %OnGetSubtitle() As %String
{
	Quit $select(..MULTI: $$$TextHTML("Choose any number of configuration items from the list"), 1: $$$TextHTML("Choose a configuration item from the list"))
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('configItems').getValue();
}

/// Correct the context for 
Method %OnAfterCreatePage() As %Status
{
	Set tProdDisplay = ..PROD
	If tProdDisplay = "" {
		Set tProdDisplay = $$$Text("Unknown")
		Set ..%GetComponentById("warningGroup").hidden = 0
	}
	Do ..%SetValueById("prodName",tProdDisplay)
	Set tSelector = ..%GetComponentById("configItems")
	Set tSelector.value = ..CURRVALUE
	If ..MULTI {
		Set tSelector.multiSelect = 1
	}
	Set tParms = "?productionName="_$$$URLENCODE(..PROD)
	If ..TYPE = "target" {
		Set tParms = tParms _ "&targets=1"
	}
	Set tSelector.context = tSelector.context _ tParms
	Quit $$$OK
}

}
