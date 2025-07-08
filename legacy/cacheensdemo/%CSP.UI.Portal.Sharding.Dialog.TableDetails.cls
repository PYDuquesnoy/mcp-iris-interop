/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Sharding.Dialog.TableDetails Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.TableDetails.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ShardingTableDetails";

Parameter RESOURCE = "%Admin_Manage";

Parameter CANCELBUTTON = 0;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property MASTERNAMESPACE As %String(ZENURL = "MASTERNAMESPACE");

Property TABLENAME As %String(ZENURL = "TABLENAME");

Property SHARDKEY As %String(ZENURL = "SHARDKEY");

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<form>
 <label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="form" cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<label id="MasterNamespace" label="Master namespace:" value="#(%page.MASTERNAMESPACE)#" enclosingClass="normal"/>
 <label id="TableName" label="Table name:" value="#(%page.TABLENAME)#" enclosingClass="normal"/>
 <label id="ShardKey" label="Shard key:" value="#(%page.SHARDKEY)#" enclosingClass="normal"/>
 <html><hr size="1"/></html>
 </group>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="%SQL.Manager.Catalog"
queryName="ShardTableDataDistribution"
showValueInTooltip="true"
showZebra="true"
useSnapshot="true"
>
<column colName="SHARD" header="Shard Number"/>
<column colName="ROWCOUNT" header="Row Count"/>
<parameter value="#(%page.TABLENAME)#"/>
 </tablePane>
 </form>
    <html id="idError" OnDrawContent="DrawAbortError" hidden="true"/>
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
	If %page.MASTERNAMESPACE '= "", $Namespace '= %page.MASTERNAMESPACE {
		Set $Namespace = %page.MASTERNAMESPACE
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Shard distribution for table")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $ZCVT(..TABLENAME,"O","HTML")
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed '= "" {
		&html<<div class="ErrorBox"><pre>#(..EscapeHTML(seed))#</pre></div>>
	}
	Quit $$$OK
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
