/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog displays information about a given Business Partner.
Class EnsPortal.Dialog.BusinessPartnerDetails Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Users must have READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// Name of Business Partner.
Property PartnerName As %ZEN.Datatype.string(ZENURL = "NAME");

XData Style
{
<style type="text/css">

#description {
	padding: 5px;
	width: 400px;
}

table.group th {
	white-space: nowrap;
	padding: .3rem;
}

table.group td {
	padding: .3rem;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<html id="description" OnDrawContent="DrawDescription" width="100%"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Business Partner Profile")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Details for Business Partner.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

/// Draw contents of description box.
Method DrawDescription(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tItem = ##class(Ens.Config.BusinessPartner).%OpenId(..PartnerName)
		If '$IsObject(tItem) {
			Write $$$FormatTextHTML($$$Text("There is no profile defined for Business Partner %1"),..PartnerName)
		}
		Else {
			&html<<div width="100%">
				<table class="table table-sm table-bordered table-striped" width="100%" valign="top">
					<tbody>
						<tr>
							<th scope="row">#($$$TextHTML("Partner Name"))#</th>
							<td colspan="2">#($ZCVT(tItem.PartnerName,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Description"))#</th>
							<td colspan="2">#($ZCVT(tItem.Description,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">&nbsp;</th>
							<th scope="col">#($$$TextHTML("Primary Contact"))#</th>
							<th scope="col">#($$$TextHTML("Alternative Contact"))#</th>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Name"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.Name,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.Name,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Title"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.Title,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.Title,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Phone"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.PhoneNumber,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.PhoneNumber,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Mobile"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.MobileNumber,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.MobileNumber,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Email"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.Email,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.Email,"O","HTML"))#&nbsp;</td>
						</tr>
						<tr>
							<th scope="row">#($$$TextHTML("Notes"))#</th>
							<td>#($ZCVT(tItem.PrimaryContact.Notes,"O","HTML"))#&nbsp;</td>
							<td>#($ZCVT(tItem.AlternativeContact.Notes,"O","HTML"))#&nbsp;</td>
						</tr>
					</tbody>
				</table>
			</div>>
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %OnDrawHTMLHead() As %Status
{
	// Bootstrap
	Write "<link rel=""stylesheet"" type=""text/css"" href=""bootstrap-4-4-1/dist/css/bootstrap.min.css""/>",!
	Write "<script type=""text/javascript"" src=""jquery-3.5.1.min.js""></script>",!
	Write "<script type=""text/javascript"" src=""bootstrap-4-4-1/dist/js/bootstrap.min.js""></script>"
	Quit $$$OK
}

}
