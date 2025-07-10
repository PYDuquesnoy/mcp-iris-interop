/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

Class Ens.Enterprise.Portal.base [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT2
	Set pLink(1) = $LB(tPageName,..homePage)
	
	Set tPageName = $$$Text("Enterprise Portal")
	Set pLink(2) = $LB(tPageName,"Ens.Enterprise.Portal.MonitorStatus.zen")

	Set tPageName = ..%OnGetPageName()
	Set pLink(3) = $LB(tPageName,$ZCVT($classname(),"O","URL")_".zen")
	Quit $$$OK
}

}
