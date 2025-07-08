/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Component for editing SQL Privileges on the User and Role edit pages
Class %CSP.UI.Component.SQLPrivileges Extends (%ZEN.Component.component, %CSP.UI.Component.SelectBoxUtils) [ System = 3 ]
{

Parameter DOMAIN [ Internal ] = "%Utility";

/// This is the XML namespace for this component.
Parameter NAMESPACE [ Internal ] = "http://www.intersystems.com/zen";

Property namespace As %ZEN.Datatype.string;

Property nsDisplayList As %ZEN.Datatype.string;

Property nsValueList As %ZEN.Datatype.string;

/// Name of the User/Role being edited
Property PID As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, tables are for display only
Property readOnly As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = 0 ];

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

ClientMethod changeNS(sel) [ Language = javascript ]
{
	var newVal = sel.options[sel.selectedIndex].value;
	zenPage.changeNS(newVal);
}

ClientMethod doAssignPriv(grantOption) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	
	var privList = this.getSelList(",",false,false);
	if (privList == "") {
		var msg = $$$Text("No role selected. Nothing to assign.");
		alert(msg);
		return false;	
	}
	
	var st = this.AssignPrivs(this.PID,privList,grantOption,this.namespace);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doChangeGrantOption(priv, isChecked) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.AssignPrivs(this.PID,priv,Number(isChecked),this.namespace)
	if (st != 1) {
		alert(st);
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doRemovePriv(priv) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemovePriv(this.PID,priv,this.namespace);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod doRemoveAllPrivs() [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var st = this.RemoveAllPrivs(this.PID,this.namespace);
	if (st != 1) {
		alert(st);
	} else {
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
Method AssignPrivs(PID As %String, Privs As %String, GrantOption As %Boolean, Namespace As %String) As %String [ ZenMethod ]
{
	Try {
		New $namespace
		Set $namespace = ..namespace
		
		Set PID = $$$ZENVAL(PID)
		
		For i = 1:1:$LENGTH(Privs,",") {
			Set j = $P(Privs,",",i)
			Set $P(PrivList,",",j) = 1
		}
		
		Set status = ##class(%SQL.Manager.API).SaveSysPriv(1,PID,PrivList,GrantOption)
		If status '= 1 Throw
		
		Set returnVal = $$$OK
    } Catch Error {
		If ($G(status,1) = 0) {
			Set status = $$$Text("Unsuccessful. Please make sure that you have sufficient SQL privilege to perform this operation.")
		} Else {
			Set status = $System.Status.GetErrorText(Error.AsStatus())
		}
		Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

/// Remove all roles from a user
/// Create a comma-delimited list of the user's roles and send it to RemoveRole()
Method RemoveAllPrivs(PID As %String, Namespace As %String) As %String [ ZenMethod ]
{
	Try {
		Set AllPrivs = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,"
		Set returnVal = ..RemovePriv(PID,AllPrivs,Namespace)
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
Method RemovePriv(PID As %String, Privs As %String, Namespace As %String) As %String [ ZenMethod ]
{
	Try {
		New $namespace
		Set $namespace = ..namespace
		
		Set PID = $$$ZENVAL(PID)
		
		For i = 1:1:$LENGTH(Privs,",") {
			Set j = $P(Privs,",",i)
			Set $P(PrivList,",",j) = 1
		}
		
		Set status = ##class(%SQL.Manager.API).SaveSysPriv(0,PID,PrivList,0)
		If status '= 1 Throw
		
		Set returnVal = $$$OK
	} Catch Error {
		If ($G(status,1) = 0) {
			Set status = $$$Text("Unsuccessful. Please make sure that you have sufficient SQL privilege to perform this operation.")
		} Else {
			Set status = $System.Status.GetErrorText(Error.AsStatus())
		}
		Set returnVal = $ZCVT(status,"O","JS")
	}
	Quit returnVal
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	Try {
		Set numRemovable = 0
		If ..namespace = "" {
			Set ..namespace = $G(%session.Data("$NAMESPACE"),$namespace)
		}
		If (","_..namespace_"," '[ ","_..nsValueList_",") Set ..namespace = $namespace
		// update the session $NAMESPACE now
		Set %session.Data("$NAMESPACE") = ..namespace
		
		&html<
			<div style="margin-bottom:3px;">
			<span class="zenLabel">#($$$TextHTML("Namespace"))#</span>
			<select id="#(..%MakeId("Namespace"))#" onchange="zenPage.getComponent('#(..index)#').changeNS(this);" value="#($zconvert(..namespace,"O","HTML"))#">>
		For i=1:1:$LENGTH(..nsValueList,",") {
			Set val = $PIECE(..nsValueList,",",i)
			Set display = $PIECE(..nsDisplayList,",",i)
			Set selected = $SELECT(val=..namespace:"selected",1:"")
			&html<<option value="#(val)#" #(selected)#>#(display)#</option>>
		}
		&html<</select></div>>
		
		New $namespace
		Set $namespace = ..namespace
		
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.CatalogPriv:UserSysPrivs")
		Set tSC = tRS.Execute($$$ZENVAL(..PID))
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set i=0
		Set PrivArrayNum($i(i)) = "%CREATE_FUNCTION"
		Set PrivArrayNum($i(i)) = "%DROP_FUNCTION"
		Set PrivArrayNum($i(i)) = "%CREATE_METHOD"
		Set PrivArrayNum($i(i)) = "%DROP_METHOD"
		Set PrivArrayNum($i(i)) = "%CREATE_PROCEDURE"
		Set PrivArrayNum($i(i)) = "%DROP_PROCEDURE"
		Set PrivArrayNum($i(i)) = "%CREATE_QUERY"
		Set PrivArrayNum($i(i)) = "%DROP_QUERY"
		Set PrivArrayNum($i(i)) = "%CREATE_TABLE"
		Set PrivArrayNum($i(i)) = "%ALTER_TABLE"
		Set PrivArrayNum($i(i)) = "%DROP_TABLE"
		Set PrivArrayNum($i(i)) = "%CREATE_VIEW"
		Set PrivArrayNum($i(i)) = "%ALTER_VIEW"
		Set PrivArrayNum($i(i)) = "%DROP_VIEW"
		Set PrivArrayNum($i(i)) = "%CREATE_TRIGGER"
		Set PrivArrayNum($i(i)) = "%DROP_TRIGGER"
		Set PrivArrayNum($i(i)) = "%NOCHECK"
		Set PrivArrayNum($i(i)) = "%NOTRIGGER"
		Set PrivArrayNum($i(i)) = "%NOINDEX"
		Set PrivArrayNum($i(i)) = "%NOLOCK"
		Set PrivArrayNum($i(i)) = "%BUILD_INDEX"
		Set PrivArrayNum($i(i)) = "%CREATE_ML_CONFIGURATION"
		Set PrivArrayNum($i(i)) = "%ALTER_ML_CONFIGURATION"
		Set PrivArrayNum($i(i)) = "%DROP_ML_CONFIGURATION"
		Set PrivArrayNum($i(i)) = "%MANAGE_MODEL"
		Set PrivArrayNum($i(i)) = "%USE_MODEL"
		Set PrivArrayNum($i(i)) = "%DROP_UNOWNED"
		Set PrivArrayNum($i(i)) = "%NOJOURN"
		Set PrivArrayNum($i(i)) = "%CANCEL_QUERY"
		Set PrivArrayNum($i(i)) = "%MANAGE_FOREIGN_SERVER"
		Set PrivArrayNum($i(i)) = "%USE_EMBEDDING"
		Set TotalPrivs = i
		For i=1:1:TotalPrivs {
			Set PrivArrayStr(PrivArrayNum(i)) = i
		}
		&html<
			<div>
			<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">
			<thead class="tpHead">
				<tr><th nowrap>#($$$TextHTML("SQL Privilege"))#</th><th nowrap>#($$$TextHTML("Grant Option"))#</th><th nowrap>#($$$TextHTML("Granted Via"))#</th><th>&nbsp;</th></tr>
			</thead>
			<tbody class="tpBody">>
		Set LBLMSG("Public") = $$$TextHTML("Public")
		Set LBLMSG("Direct") = $$$TextHTML("Direct")
		Set LBLMSG("Role") = $$$TextHTML("Role")
		Set LBLMSG("User") = $$$TextHTML("User")
	 	Set tRow = 0
	 	While tRS.Next() {
		 	Set tRow = tRow + 1
		 	Set Priv = tRS.Data("PRIVILEGE")
			Set Grant = tRS.Data("ADMIN_OPTION")
			Set tGrantedVia = tRS.Data("GRANTED_VIA")
			Set privNum = PrivArrayStr(Priv)
		 	Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
		 	Set ExcludedItems(Priv) = ""
			&html<
				<tr class="#(rowClass)#">
					<td class="tpStr" nowrap>#($ZCVT(Priv,"O","HTML"))#</td>
					<td class="tpStr" nowrap style="text-align:center;">>
			If '$$$ZENVAL(..readOnly) && (tGrantedVia = "Direct") {
				&html<
						<input type="checkbox" #($CASE(Grant,"Yes":"checked",:""))# onclick="zenPage.getComponent('#(..index)#').doChangeGrantOption('#(privNum)#',this.checked);"/>>
			} Else {
				Write $ZCVT(Grant,"O","HTML")
			}
			&html<
					</td>
					<td class="tpStr" nowrap>>
			If tGrantedVia = "" {
				&html<
					&nbsp;-&nbsp;>
			} ElseIf tGrantedVia[" - " {
				Set GrantVia = $P(tGrantedVia," - ",1)
				If $G(LBLMSG(GrantVia)) '= "" Set GrantVia = LBLMSG(GrantVia)
				&html<
					#($ZCVT(GrantVia_":"_$P(tGrantedVia," - ",2),"O","HTML"))#>
			} Else {
				Set GrantedVia = $S($G(LBLMSG(tGrantedVia))'="":LBLMSG(tGrantedVia), 1:tGrantedVia)
				&html<
					#($ZCVT(GrantedVia,"O","HTML"))#>
			}	
					&html<</td>>
			If '$$$ZENVAL(..readOnly) {
				If tGrantedVia = "Direct" {
					Set numRemovable = numRemovable + 1
					&html<
						<td class="tpAction" style="text-align:center;"><a href="#2" onclick="zenPage.getComponent('#(..index)#').doRemovePriv('#(privNum)#');">#($$$TextHTML("Remove"))#</a></td>>
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
		
		If '$$$ZENVAL(..readOnly) {
			If (numRemovable > 1) {
				&html<
				<input type="button" value='#($$$TextHTML("Remove All"))#' onclick="zenPage.getComponent('#(..index)#').doRemoveAllPrivs();" style="margin-top:5px;">>
			}
			If (tRow < TotalPrivs) {
				&html<
					<div class="sectionLabel">#($$$TextHTML("Assign the user additional privileges by selecting one or more available privileges and pressing [Assign]."))#</div>>
				
				// Start to draw the Available list box
				Set tSC = ..DrawAvailableList(..index)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
				// Populate the Available list box
				set privName=""
				for {
					set privName=$o(PrivArrayStr(privName)) quit:privName=""
					set privNum = PrivArrayStr(privName)
					if '$d(ExcludedItems(privName)) {
						&html<<option value="#(privNum)#">#($ZCVT(privName,"O","HTML"))#</option>>
					}
				}
				#; For i=1:1:TotalPrivs {
				#; 	Set privName = PrivArrayNum(i)
				#; 	Set privNum = PrivArrayStr(privName)
				#; 	If '$D(ExcludedItems(privName)) {
				#; 		&html<<option value="#(privNum)#">#($ZCVT(privName,"O","HTML"))#</option>>
				#; 	}
				#; }
				
				// Draw the arrows and Select list box
				Set tSC = ..DrawSelectList(..index)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				
				// Draw assign buttons
				&html<
					<td align="left">
						<input type="button" value='#($$$TextHTML("Assign"))#' onclick="zenPage.getComponent('#(..index)#').doAssignPriv(false);">
						<br/><br/>
						<input type="button" value='#($$$TextHTML("Assign with Grant Option"))#' onclick="zenPage.getComponent('#(..index)#').doAssignPriv(true);">
					</td>
					</tr></table>
					<div class="sectionLabel">#($$$TextHTML("Hold the [Shift] or [Ctrl] key while clicking to select multiple roles."))#</div>>
			}
		}
	} Catch Error {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,Error.AsStatus())
	}
	Quit
}

}
