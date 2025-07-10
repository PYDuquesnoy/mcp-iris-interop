/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.VisualTraceLegend Extends EnsPortal.VisualTraceLegend [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageTrace:USE";

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<svgFrame id="legend" width="700" height="510" svgWidth="700" svgHeight="510"
svgPage="Ens.Enterprise.Portal.SVG.TraceLegend">
</svgFrame>
</pane>
}

}
