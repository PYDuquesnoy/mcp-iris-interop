/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Wrapper class to correctly manage popups requested by Source Control hooks.
Class EnsPortal.Dialog.SourceControlManager Extends (%CSP.Portal.SourceControl.Dialog.Manager, EnsPortal.Template.standardPage) [ System = 4 ]
{

Parameter PAGENAME = "Source Control Dialog";

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_Code, %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules, %Ens_BPL, %Ens_DTL or %Ens_RecordMap
Parameter RESOURCE = "%Ens_Code:READ,%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ,%Ens_BPL:READ,%Ens_DTL:READ,%Ens_RecordMap:READ";

Parameter DOMAIN = "Ensemble";

/// Set this to the appropriate application class.
Parameter APPLICATION = "EnsPortal.Application";

/// Message to inform the user they may not perform a given action.
Property msgNotPermitted As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("You are not permitted to perform this action")} ];

ClassMethod %OnPreHTTP() As %Boolean
{
 Quit ##class(EnsPortal.Template.standardPage).%OnPreHTTP()
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	var opener = this.getOpener();
	var zenOpener = (opener && opener.zenPage ? opener.zenPage : null);
	if (zenOpener) {
		var cls = zenOpener._serverClass;
		if ((zenPage.CheckExtends(cls,"EnsPortal.Template.devPage")) || (zenPage.CheckExtends(cls,"EnsPortal.Template.prodConfigSCPage"))) { 
			zenOpener.toggleReadOnly();
		}
	}
	return true;
}

}
