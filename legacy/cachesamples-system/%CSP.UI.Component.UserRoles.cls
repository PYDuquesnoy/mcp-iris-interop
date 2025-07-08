/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Component for editing roles on the User edit page
Class %CSP.UI.Component.UserRoles Extends %CSP.UI.Component.abstractRoleTab [ System = 3 ]
{

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

ClientMethod doAssignRole(type, grantOption) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	var roleList = this.getSelList(",",false,false);
	if (roleList == "") {
		var msg = $$$Text("No role selected. Nothing to assign.");
		alert(msg);
		return false;	
	}
	
	var st = this.AssignRoles(this.PID,roleList,grantOption,this.type);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doChangeGrantOption(roleID, isChecked) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.AssignRoles(this.PID,roleID,Number(isChecked),this.type)
	if (st != 1) {
		alert(st);
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Assign a Role to a User or change the grant option on a User's existing Role
/// PID: User name
/// RoleList: Comma-delimited list of roles to change
/// In case user selected roles longer than 32K, 
/// we break them into 100 items a piece before sending to the server to avoid error
/// GrantOption: 1 - Add grant option, 0 - Remove grant option
Method AssignRoles(PID As %String, RoleList As %String, GrantOption As %Boolean, Type As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set class = $case(Type, "UserRole":"Security.Users", "UserEscalationRole":"Security.Users", :"Security.Roles")
		If Type="UserEscalationRole" {
			Set tSC = $ClassMethod(class,"AddEscalationRoles",PID,.RoleList)
		} Else {
			Set tSC = $ClassMethod(class,"AddRoles",PID,.RoleList, GrantOption)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set returnVal = $$$OK
    } Catch Error {
	    If ($G(status,0) = 0) Set status = $System.Status.GetErrorText(Error.AsStatus())
	    Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

/// Remove all roles from a user
/// Create a comma-delimited list of the user's roles and send it to RemoveRole()
Method RemoveAllRoles(PID As %String, Type As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		If Type="UserEscalationRole" {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserEscalationRole")
		} Else {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserRole")
		}
		Set tSC = tRS.Execute(PID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set roleList = ""
		While tRS.Next() {
			If (roleList '= "") Set roleList = roleList_","
			Set roleList = roleList_tRS.Get("ROLE_NAME")
		}
		
		Set returnVal = ..RemoveRole(PID,roleList,Type)
	} Catch Error {
		Set returnVal = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit returnVal
}

/// Remove a Role from a User
/// PID: User name
/// RoleList: Comma-delimited list of roles to remove
/// In case user selected roles longer than 32K, 
/// we break them into 100 items a piece before sending to the server to avoid error
Method RemoveRole(PID As %String, RoleList As %String, Type As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set class = $case(Type, "UserRole":"Security.Users", "UserEscalationRole":"Security.Users", :"Security.Roles")
		set method = $case(Type, "UserEscalationRole":"RemoveEscalationRoles", :"RemoveRoles")
		Set tSC = $ClassMethod(class,method,PID,.RoleList)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set returnVal = $$$OK
	} Catch Error {
		If ($G(status,0) = 0) Set status = $System.Status.GetErrorText(Error.AsStatus())
		Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Try {
		Set PID = $$$ZENVAL(..PID)
		Set ReadOnly = $$$ZENVAL(..readOnly)
		
		If ..type="UserEscalationRole" {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserEscalationRole")
		} Else {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserRole")
		}
		Set tSC = tRS.Execute(PID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If ..type = "UserRole" {
			Set TitleText = $$$FormatText($$$TextHTML("User %1 is assigned to the following roles:"),$ZCVT(PID,"O","HTML"))
		} ElseIf ..type = "UserEscalationRole" {
			Set TitleText = $$$FormatText($$$TextHTML("User %1 is assigned to the following Escalation Roles:"),$ZCVT(PID,"O","HTML"))
		} Else {
			Set TitleText = $$$FormatText($$$TextHTML("Role %1 is assigned to the following roles:"),$ZCVT(PID,"O","HTML"))
		}

		Set EditPageBase = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Role.zen",,1)


		&html<
			<div>
			<div class="Text2">#(TitleText)#</div>
			<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">
			<thead class="tpHead">
				<tr><th nowrap>#($$$TextHTML("Role Name"))#</th>>
				If ..type'="UserEscalationRole" &html<<th nowrap>#($$$TextHTML("Grant Option"))#</th>>
			&html<<th>&nbsp;</th></tr>
			</thead>
			<tbody class="tpBody">>
	 	Set tRow = 0
	 	While tRS.Next() {
		 	Set tRow = tRow + 1
		 	Set Role = tRS.Get("ROLE_NAME")
		 	Set tAdmin = $select(..type="UserEscalationRole":"", 1:tRS.Get("ADMIN_OPTION"))
		 	Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
		 	Set ExcludedItems(Role) = ""
		 	
		 	If $G(EditPageBase) '= "" {
			 	Set EditPage = EditPageBase_"PID="_$ZCVT(Role,"O","URL")
				&html<<tr class="#(rowClass)#"><td class="tpAction" nowrap><a href="#(EditPage)#">#($ZCVT(Role,"O","HTML"))#</a></td>>
			} Else {
				&html<<tr class="#(rowClass)#"><td class="tpStr" nowrap>#($ZCVT(Role,"O","HTML"))#</td>>	
			}
		 	
			If ..type'="UserEscalationRole" {
				&html<
					<td class="tpStr" nowrap style="text-align:center;">>
				If 'ReadOnly {
					&html<<input type="checkbox" #($CASE(tAdmin,1:"checked",:""))# onclick="zenPage.getComponent('#(..index)#').doChangeGrantOption('#(Role)#',this.checked);"/>>
				} Else {
					Set text = $CASE(tAdmin,1:$$$TextHTML("Yes"),:$$$TextHTML("No"))
					&html<#(text)#>
				}
				&html<
					</td>>
			}
			If 'ReadOnly {
				&html<
					<td class="tpAction" style="text-align:center;"><a href="#1" onclick="zenPage.getComponent('#(..index)#').doRemoveRole('#(Role)#','#(..type)#');">#($$$TextHTML("Remove"))#</a></td>>
			}
			&html<
				</tr>>
		}
	 	If tRow = 0 {
			&html<
				<tr><td colspan="3">#($$$TextHTML("None."))#</td></tr>>
		}
		&html<
			</tbody>
			</table>
			</div>>
		
		If 'ReadOnly {
			If (tRow > 1) {
				&html<
					<input type="button" value='#($$$TextHTML("Remove All"))#' onclick="zenPage.getComponent('#(..index)#').doRemoveAllRoles('#(..type)#');" style="margin-top:5px;">>
			}
			&html<
				<div class="sectionLabel">#($$$TextHTML("Assign the user to additional roles by selecting one or more available roles and pressing [Assign]."))#</div>>
			Set tSC = ..DrawSelectBoxes(.ExcludedItems,..type)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
	} Catch Error {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,Error.AsStatus())
	}
	Quit
}

}
