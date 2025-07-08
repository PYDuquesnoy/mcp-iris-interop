/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Superclass for "assign role" components for User and Application edit pages
Class %CSP.UI.Component.abstractRoleTab Extends (%ZEN.Component.component, %CSP.UI.Component.SelectBoxUtils) [ System = 3 ]
{

Parameter DOMAIN [ Internal ] = "%Utility";

/// This is the XML namespace for this component.
Parameter NAMESPACE [ Internal ] = "http://www.intersystems.com/zen";

/// Name of the Application/User being edited
Property PID As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, tables are for display only
Property readOnly As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = 0 ];

/// Type of roles this component affects
Property type As %ZEN.Datatype.string(VALUELIST = ",ApplicationRole,MatchRole,UserRole,UserEscalationRole,RoleRole");

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
.Text2:first-letter {
    font-size:1.4em;
}
.Text2 {
    font-size:13px;
    max-width:575px;
    margin-bottom:5px;
}
.sectionLabel {
	font-size:13px;
	font-weight:normal;
	color:black;
	margin-top:15px;
}
</style>
}

ClientMethod doRemoveRole(roleID) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemoveRole(this.PID,roleID,this.type);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doRemoveAllRoles(type) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemoveAllRoles(this.PID,type);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

Method DrawSelectBoxes(ByRef ExcludedItems As %String, Type As %String = "") As %Status
{
	Try {
		// Build a Roles array
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:Roles")
		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tRow = 0
		While tRS.Next() {
			If ((..type'="UserEscalationRole")&&(tRS.GetData(4)=1 /* EscalationOnly */)) {
				Continue
			}
			Set tRow = tRow + 1
			Set Roles(tRow) = tRS.GetData(1)
		}
		Kill tRS
		
		// Draw the Match Role dropdown
		If ..type = "MatchRole" {
	 		&html<
	 			<div class="sectionLabel">#($$$TextHTML("To add a matching role, fill out the following form and press [Assign]."))#</div>
	 			<div style="margin-top:15px;">
					<span class="zenLabel">#($$$TextHTML("Select a matching role:"))#</span>
					<select id=#(..%MakeId("MatchRole"))#>
						<option value="" selected>#($$$TextHTML(" ----- Select One ----- "))#</option>>
			Set tRow = $O(Roles(0))
			While tRow '= "" {
				&html<
						<option value="#(Roles(tRow))#">#($ZCVT(Roles(tRow),"O","HTML"))#</option>>
				Set tRow = $O(Roles(tRow))
			}
			&html<
					</select>
				</div>
				<div class="sectionLabel">#($$$TextHTML("Select target roles to add to the selected matching role:"))#</div>>
		}
		
		// Start to draw the Available list box
		Set tSC = ..DrawAvailableList(..index)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		// Populate the Available list box
		Set tRow = $O(Roles(0))
		While tRow '= "" {
			If '$D(ExcludedItems(Roles(tRow))) {
				&html<<option value="#(Roles(tRow))#">#($ZCVT(Roles(tRow),"O","HTML"))#</option>>
			}
			Set tRow = $O(Roles(tRow))
		}
		
		// Draw the arrows and Select list box
		Set tSC = ..DrawSelectList(..index)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		// Draw assign button(s)
		&html<
			<td align="left">
				<input type="button" value='#($$$TextHTML("Assign"))#' onclick="zenPage.getComponent('#(..index)#').doAssignRole('#(..type)#',false);">>
		If ((..type = "UserRole") || (..type = "RoleRole")) {
			&html<
				<br/><br/>
				<input type="button" value='#($$$TextHTML("Assign with Grant Option"))#' onclick="zenPage.getComponent('#(..index)#').doAssignRole('#(..type)#',true);">>
		}
		&html<
			</td></tr></table>
			<div class="sectionLabel">#($$$TextHTML("Hold the [Shift] or [Ctrl] key while clicking to select multiple roles."))#</div>>
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

}
