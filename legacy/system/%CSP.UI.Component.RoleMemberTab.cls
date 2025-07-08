/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Component for the "Members" tab on the Role edit page
Class %CSP.UI.Component.RoleMemberTab Extends (%ZEN.Component.component, %CSP.UI.Component.SelectBoxUtils) [ System = 3 ]
{

Parameter DOMAIN [ Internal ] = "%Utility";

/// This is the XML namespace for this component.
Parameter NAMESPACE [ Internal ] = "http://www.intersystems.com/zen";

/// Name of the Application/User being edited
Property PID As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, tables are for display only
Property readOnly As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = 0 ];

/// Users or Roles, depending on which radio button is selected
Property Type As %ZEN.Datatype.string;

Property EscalationOnly As %ZEN.Datatype.boolean;

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

ClientMethod doAssignRole(grantOption) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	if (this.Type == "Users") {
		var delim = "*";
	} else {
		var delim = ","
	}
	var roleList = this.getSelList(delim,false,false);
	if (roleList == "") {
		var msg = $$$Text("No role selected. Nothing to assign.");
		alert(msg);
		return false;	
	}

	var st = this.AssignRoles(this.PID,roleList,grantOption);
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
	var st = this.AssignRoles(this.PID,roleID,isChecked,false);
	if (st != 1) {
		alert(st);
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doRadioChange(newVal) [ Language = javascript ]
{
	this.Type = newVal;
	this.UpdateType(newVal);
	this.refreshContents();
}

ClassMethod UpdateType(newVal As %String) As %Status [ ZenMethod ]
{
	Set %session.Data("RoleType") = newVal
	Quit $$$OK
}

ClientMethod doRemoveRole(roleID, type) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemoveRole(this.PID,roleID,type);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doRemoveAllRoles() [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemoveAllRoles(this.PID);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Assign a User or Role to the Role or change the grant option on a User/Role's existing Role
/// PID: Role name
/// MemberList: Comma- or Asterisk-delimited list of users or roles to change
/// GrantOption: 1 - Add grant option, 0 - Remove grant option
Method AssignRoles(PID As %String, MemberList As %String, GrantOption As %Boolean) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)

		Set delim = $SELECT(..Type="Users":"*",1:",")
		Set class = $SELECT(..Type="Roles":"Security.Roles",1:"Security.Users")
		For i=1:1:$LENGTH(MemberList,delim) {
			Set tRow = $PIECE(MemberList,delim,i)
			If tRow '= "" {
				Set Member = $G(%session.Data("Roles",tRow),tRow)
				If ..Type="Escalation" {
					Set tSC = $ClassMethod(class,"AddEscalationRoles",Member,.PID)
				} Else {
					Set tSC = $ClassMethod(class,"AddRoles",Member,.PID,GrantOption)
				}
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}

	    Set returnVal = $$$OK
    } Catch Error {
		If ($G(status,0) = 0) Set status = $System.Status.GetErrorText(Error.AsStatus())
		Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

/// Remove all roles from a user
Method RemoveAllRoles(PID As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)

		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:RoleUser")
		Set tSC = tRS.Execute(PID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		While tRS.Next() {
			Set tSC = ..RemoveRole(PID,tRS.Get("NAME"),tRS.Get("USER"))
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		// Find all the Users who can escalate to this role
		Do {
			Set tSC = ##class(Security.Roles).InUse(PID,.inUse,.users,.more,,,4 /*4=Check Escalation roles*/)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If inUse {
				Set i=0
				While $listnext(users,i,user) {
					Set tSC = ..RemoveRole(PID,user,"escalation")
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
			}
		} While more
	} Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

/// Remove a Role from a User
/// PID: Role name
/// Member: Role or user to remove
/// Type: "USER" or "ROLE"
Method RemoveRole(PID As %String, Member As %String, Type As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set class = $SELECT(Type="ROLE":"Security.Roles",1:"Security.Users")
		Set method = $SELECT(Type["escalation":"RemoveEscalationRoles",1:"RemoveRoles")
		Set tSC = $ClassMethod(class,method,Member,.PID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set returnVal = $$$OK
	} Catch Error {
		If ($G(status,0) = 0) Set status = $System.Status.GetErrorText(Error.AsStatus())
		Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

Method DrawSelectBoxes(ByRef ExcludedItems As %String) As %Status
{
	Try {
		Kill %session.Data("Roles")
		If ..Type = "Roles" {
			Set tRS = ##class(%ResultSet).%New("Security.Roles:List")
			Set type = $$$TextHTML("Role")
			Set tSC = tRS.Execute("*","*",0)
		} Else { /* Type = "Users" || Type = "Escalation" */
			Set tRS = ##class(%ResultSet).%New("Security.Users:List")
			Set type = $$$TextHTML("User")
			Set tSC = tRS.Execute("*","*","*")
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tRow = 0
		While tRS.Next() {
			Set tRow = tRow + 1
			Set Name = tRS.GetData(1)
			Set %session.Data("Roles",tRow) = Name
			If ..Type = "Users" {
				If (tRow > $G($$$IRISTempMgt($Username,"MaxUsers"),1000)) Quit
				Set tSC = ##class(Security.Users).Get(Name,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				If ($zb(+$G(Properties("Flags")),$$$NormalUser,1) = 0) {
					Set ExcludedItems(Name) = ""
				}
			}
		}
		Kill tRS
		
		// Start to draw the Available list box
		Set tSC = ..DrawAvailableList(..index)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		// Populate the Available list box
		Set tRow = $O(%session.Data("Roles",0))
		While tRow '= "" {
			If '$D(ExcludedItems(%session.Data("Roles",tRow))) {
				If (..Type = "Users") || ($E(%session.Data("Roles",tRow),1,$L($$$DBResourcePrefix))'=$$$DBResourcePrefix) {
					&html<<option value="#(tRow)#">#($ZCVT(%session.Data("Roles",tRow),"O","HTML"))# (#(type)#)</option>>
				}
			}
			Set tRow = $O(%session.Data("Roles",tRow))
		}
		
		// Draw the arrows and Select list box
		Set tSC = ..DrawSelectList(..index,0,"")
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		// Draw assign button(s)
		&html<
			<td align="left">
				<input type="button" value='#($$$TextHTML("Assign"))#' onclick="zenPage.getComponent('#(..index)#').doAssignRole(false);">>
			If ..Type'="Escalation" {
				&html<
					<br/><br/>
					<input type="button" value='#($$$TextHTML("Assign with Grant Option"))#' onclick="zenPage.getComponent('#(..index)#').doAssignRole(true,0);">>
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

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Try {
		Set PID = $$$ZENVAL(..PID)
		Set ReadOnly = $$$ZENVAL(..readOnly)
		
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:RoleUser")
		Set tSC = tRS.Execute(PID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		While tRS.Next() {
			Set results($zcvt(tRS.Get("NAME"),"l")) = $lb(tRS.Get("NAME"), tRS.Get("USER"), tRS.Get("ADMIN_OPTION"))
		}

		// Find all the Users who can escalate to this role
		Do {
			Set tSC = ##class(Security.Roles).InUse(PID,.inUse,.users,.more,,,4 /*4=Check Escalation roles*/)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If inUse {
				Set i=0
				While $listnext(users,i,user) {
					Set results($zcvt(user, "l")_":ESC") = $lb(user,"USER (escalation)", 0)
				}
			}
		} While more
		
		Set EditPage("ROLE") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Role.zen",,1)
		Set EditPage("USER") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.User.zen",,1)
		
		Set headerText = $$$FormatText($$$TextHTML("Users and Roles Assigned to Role %1:"),$ZCVT(PID,"O","HTML"))
		Set nameColumnHeader = $$$TextHTML("User or Role Name")
		
		&html<
			<div>
			<div class="Text2">#(headerText)#</div>
			<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">
			<thead class="tpHead">
				<tr><th nowrap>#(nameColumnHeader)#</th>>
				&html<<th nowrap>#($$$TextHTML("Type"))#</th><th nowrap>#($$$TextHTML("Grant Option"))#</th>>
				&html<<th>&nbsp;</th></tr>
			</thead>
			<tbody class="tpBody">>
	 	Set tRow = 0
		Set idx = ""
		For { 
			Set idx = $order(results(idx),1,result)
			If idx="" Quit
			Set $lg(tName, OwnerType, tAdmin) = result
		 	Set tRow = tRow + 1
		 	Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")

			If $G(EditPage($p(OwnerType," ",1))) '= "" {
				Set EditPage = EditPage($p(OwnerType," ",1))_"PID="_$ZCVT(tName,"O","URL")
				&html<<tr class="#(rowClass)#"><td class="tpAction" nowrap><a href="#(EditPage)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			} Else {
				&html<<tr class="#(rowClass)#"><td class="tpStr" nowrap>#($ZCVT(tName,"O","HTML"))#</td>>	
			}
		 	&html<<td class="tpStr" nowrap>#($ZCVT(OwnerType,"O","HTML"))#</td>>	
			Set tEsp = $zconvert($zconvert(tName,"O","JS"),"O","HTML")
			&html<<td class="tpStr" nowrap style="text-align:center;">>
			If 'ReadOnly {
				&html<<input type="checkbox" #($CASE(tAdmin,1:"checked",:""))# onclick="zenPage.getComponent('#(..index)#').doChangeGrantOption('#(tEsp)#',this.checked);"/>>
			} Else {
				Set text = $CASE(tAdmin,1:$$$TextHTML("Yes"),:$$$TextHTML("No"))
				&html<#(text)#>
			}
			&html<</td>>

		 	Set ExcludedItems(tName) = ""
			If 'ReadOnly {
				Set hideRemove = 0
				If (OwnerType = "USER") {
					Set tSC = ##class(Security.Users).Get(tName,.Properties)
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
					If ($zb(+$G(Properties("Flags")),$$$NormalUser,1) = 0) {
						Set hideRemove = 1
					}
				}
				If 'hideRemove {
					&html<
						<td class="tpAction" style="text-align:center;"><a href="#1" onclick="zenPage.getComponent('#(..index)#').doRemoveRole('#(tEsp)#','#(OwnerType)#');">#($$$TextHTML("Remove"))#</a></td>>
				}
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
					<input type="button" value='#($$$TextHTML("Remove All"))#' onclick="zenPage.getComponent('#(..index)#').doRemoveAllRoles();" style="margin-top:5px;">>
			}
			
			Set escalationOnly = 0
			If ##class(Security.Roles).Exists(PID,.RoleObj) && RoleObj.EscalationOnly {
				Set escalationOnly = 1
				Set ..Type = "Escalation"
			}

			Set type = ..Type
			If type = "" {
				Set type = $G(%session.Data("RoleType"),"Users")
				Set ..Type = type
			}
			&html<<div class="sectionLabel">#($$$TextHTML("Assign additional users or roles by selecting one or more available users or roles and pressing [Assign]."))#</div>>
			If 'escalationOnly &html<<input type="radio" id="#(..%MakeId("typeUsers"))#" name="listType" value="Users" #($SELECT(type="Users":"checked",1:""))# onchange="zenPage.getComponent('#(..index)#').doRadioChange(this.value);"><span class="normal" style=#($SELECT(type="Users":"font-weight:bold;",1:""))#>#($$$TextHTML("Users"))#</span></input>>
			&html<<input type="radio" id="#(..%MakeId("typeEscalation"))#" name="listType" value="Escalation" #($SELECT(type="Escalation":"checked",1:""))# onchange="zenPage.getComponent('#(..index)#').doRadioChange(this.value);"><span class="normal" style=#($SELECT(type="Escalation":"font-weight:bold;",1:""))#>#($$$TextHTML("Users (via escalation)"))#</span></input>>
			If 'escalationOnly &html<<input type="radio" id="#(..%MakeId("typeRoles"))#" name="listType" value="Roles" #($SELECT(type="Roles":"checked",1:""))# onchange="zenPage.getComponent('#(..index)#').doRadioChange(this.value);"><span class="normal" style=#($SELECT(type="Roles":"font-weight:bold;",1:""))#>#($$$TextHTML("Roles"))#</span></input>>
			
			Set ExcludedItems(PID) = ""
			Set tSC = ..DrawSelectBoxes(.ExcludedItems)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
	} Catch Error {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,Error.AsStatus())
	}
	Quit
}

}
