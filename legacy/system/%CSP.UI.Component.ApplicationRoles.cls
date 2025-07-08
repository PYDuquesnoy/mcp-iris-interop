/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %CSP.UI.Component.ApplicationRoles
Class %CSP.UI.Component.ApplicationRoles Extends %CSP.UI.Component.abstractRoleTab [ System = 3 ]
{

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
.innerTable {
	border:1px solid #888;
}
</style>
}

ClientMethod doAssignRole(type, grantOption) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var matchrole = "";
	if (type == 'MatchRole') {
		matchrole = this.findElement('MatchRole').value;
		if (matchrole == "") {
			var msg = $$$Text("Please select a Matching Role.");
			alert(msg);
			this.findElement('MatchRole').focus();
			return false;	
		}
	}
	
	var privs = this.getSelList(":",true,false);
	if (privs == "") {
		var msg = $$$Text("No role selected. Nothing to assign.");
		alert(msg);
		return false;	
	}
	
	var st = this.AssignRole(this.PID,privs,matchrole);
	if (st != 1) {
		alert(st);
	} else {
		this.refreshContents();
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Save both kind of Roles:
/// 1) Roles that will always be added to application
///    NewMatchElement passed is in delimited by ":"
///    MatchRole = ""
/// 2) Matching roles with their associated target roles
///    NewMatchElement passed in is delimited by ":"
///    MatchRole = the MatchRole user selected
Method AssignRole(PID As %String, NewMatchElement As %String, MatchRole As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set newRoles = ""
		If Properties("MatchRoles") = "" {
			// if there aren't any existing roles, just set the new one
			Set newRoles = MatchRole_NewMatchElement
 		} Else {
	 		Set matchFound = 0
	 		// there are existing roles, so replace the old set for this matchRole with the new set
	 		For i=1:1:$LENGTH(Properties("MatchRoles"),",") {
				Set MatchElement = $PIECE(Properties("MatchRoles"),",",i)
				
				If ($P(MatchElement,":",1) = MatchRole) {
					// this is the element we are adding the new role/s to
					Set MatchElement = MatchElement_NewMatchElement
					Set matchFound = 1
				}
				
				If newRoles '= "" Set newRoles = newRoles_","
				Set newRoles = newRoles_MatchElement
	 		}
	 		If 'matchFound {
		 		// there aren't existing roles for this matchRole, so add it to the end
		 		Set newRoles = newRoles_","_MatchRole_NewMatchElement
	 		}
 		}
 		Set Properties("MatchRoles") = newRoles
 		
 		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

/// Remove All Roles that will always be added to application if Type = "ApplicationRole"
/// Remove All MatchRoles if Type = "MatchRole"
Method RemoveAllRoles(PID As %String, Type As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set newRoles = ""
		For i=1:1:$LENGTH(Properties("MatchRoles"),",") {
			Set Remove = 0
			Set MatchElement = $PIECE(Properties("MatchRoles"),",",i)
 			Set MatchRole = $P(MatchElement,":",1)
 			If Type = "MatchRole" {
 				If MatchRole '= "" Set Remove = 1
 			} Else {
	 			If MatchRole = "" Set Remove = 1
 			}
 			If Remove = 0 {
	 			If newRoles '= "" Set newRoles = newRoles_","
	 			Set newRoles = newRoles_MatchElement
 			}
		}
		Set Properties("MatchRoles") = newRoles
		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

	 	Set tSC = $$$OK
	 } Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

/// Remove a Role from a application
/// ElementID is ",TargetRole" or "MatchRole,TargetRole"
Method RemoveRole(PID As %String, ElementId As %String) As %String [ ZenMethod ]
{
	Try {
		Set PID = $$$ZENVAL(PID)
		
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set RemoveMatch = $PIECE(ElementId,",",1)
		Set RemoveTarget = $PIECE(ElementId,",",2)
		
		Set newRoles = ""
		For i=1:1:$LENGTH(Properties("MatchRoles"),",") {
			Set MatchElement = $PIECE(Properties("MatchRoles"),",",i)
 			Set MatchRole = $P(MatchElement,":",1)
 			
 			If MatchRole = RemoveMatch {
	 			Set newElement = MatchRole
	 			For j=2:1:$LENGTH(MatchElement,":") {
		 			Set target = $PIECE(MatchElement,":",j)
		 			If (target '= RemoveTarget) {
			 			Set newElement = newElement_":"_target
		 			}
	 			}
	 			If (newElement = MatchRole) {
		 			Set newElement = ""
	 			}
	 			Set MatchElement = newElement
 			}
 			If MatchElement '= "" {
 				If newRoles '= "" Set newRoles = newRoles_","
 				Set newRoles = newRoles_MatchElement
 			}
		}
		Set Properties("MatchRoles") = newRoles
		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
	 	If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

	 	Set tSC = $$$OK
	} Catch Error {
		Set tSC = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tSC
}

///   Return roles that should be loaded
ClassMethod GetRoles(Roles As %String, Output NullRoles As %String, Output MatchRoles As %String) As %Status
{
	Try {
	 	For i = 1:1:$LENGTH(Roles,",") {
			Set MatchElement = $PIECE(Roles,",",i)
		 	Set MatchRole = $P(MatchElement,":",1)
		 	For j = 2:1 {
			 	Set TargetRole = $p(MatchElement,":",j)
			 	q:TargetRole=""
			 	If MatchRole = "" {
				 	Set NullRoles(TargetRole) = ""
			 	} Else {
				 	Set MatchRoles(MatchRole,TargetRole) = ""
			 	}
			}
	 	}
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
		Set tSC = ##class(Security.Applications).Get($$$ZENVAL(..PID),.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tSC = ..GetRoles(Properties("MatchRoles"),.NullRoles,.MatchRoles)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				
		If ..type = "ApplicationRole" {
			Set label = $$$TextHTML("When a user enters this application, the following roles will be automatically added to the current role set:")
		 	Set header1 = $$$TextHTML("Application Roles")
		 	Set header2 = ""
	 	} Else {
		 	Set label = $$$TextHTML("When a user enters this application and if the user is a member of the matching roles, then these additional roles will be automatically added to the current role set:")
		 	Set header1 = $$$TextHTML("Matching Role")
		 	Set header2 = $$$TextHTML("Target Roles added to Matching Role")
	 	}
	 	Set lblRemove = $$$TextHTML("Remove")
	 	
	 	&html<<div>>
	 	&html<<div class="Text2">#(label)#</div>>
	 	&html<<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">>
	 	&html<<thead class="tpHead"><tr><th nowrap>#(header1)#</th><th nowrap>#(header2)#</th></tr></thead>>
	 	&html<<tbody class="tpBody">>
	
	 	Set (tRow,TotalRows) = 0
	 	If ..type = "ApplicationRole" {
			Set TargetRole = $O(NullRoles(""))
			While TargetRole '= "" {
				Set tRow = tRow + 1
				Set id = ","_TargetRole
				Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
				&html<<tr class="#(rowClass)#"><td class="tpStr" nowrap>#($ZCVT(TargetRole,"O","HTML"))#</td>>
				If '$$$ZENVAL(..readOnly) {
					&html<<td class="tpAction" style="text-align:center;"><a href="#1" onclick="zenPage.getComponent('#(..index)#').doRemoveRole('#(id)#')">#(lblRemove)#</a></td>>
				} Else {
					&html<<td>&nbsp;</td>>
				}
				&html<</tr>>
				Set TargetRole = $O(NullRoles(TargetRole))
			}
	 	} Else {
			Set MatchRole = $O(MatchRoles(""))
			While MatchRole '= "" {
				Set tRow = tRow + 1
				Set rowClass = $CASE(tRow#2,1:"tpOdd",:"tpEven")
				&html<<tr class="#(rowClass)#"><td class="tpStr" nowrap>#($ZCVT(MatchRole,"O","HTML"))#</td>>
				Set TargetRole = $O(MatchRoles(MatchRole,""))
				Set tCol = 0
				&html<<td width="100%"><table width="100%" class="innerTable"><tbody>>
				While TargetRole '= "" {
					Set tCol = tCol + 1
					Set id = MatchRole_","_TargetRole
					Set colClass = $CASE(tCol#2,1:"tpOdd",:"tpEven")
					&html<<tr class="#(colClass)#"><td class="tpStr" nowrap>#($ZCVT(TargetRole,"O","HTML"))#</td>>
					If '$$$ZENVAL(..readOnly) {
						&html<<td class="tpAction" style="text-align:center;" width="135px"><a href="#2" onclick="zenPage.getComponent('#(..index)#').doRemoveRole('#(id)#')">#(lblRemove)#</a></td>>
					}
					Set TargetRole = $O(MatchRoles(MatchRole,TargetRole))
					&html<</tr>>
				}
				&html<</tbody></table></td>>
				Set MatchRole = $O(MatchRoles(MatchRole))
			}
		 }
		Set FoundRows = tRow		
		If FoundRows = 0 {
			&html<<tr><td colspan="2">#($$$TextHTML("None."))#</td></tr>>
		}
		&html<</tbody>>
		&html<</table>>
		&html<</div>>
		
		If '$$$ZENVAL(..readOnly) {
			If ((FoundRows > 1) || ($g(tCol) > 1)) {
				&html<<input type="button" value='#($$$TextHTML("Remove All"))#' onclick="zenPage.getComponent('#(..index)#').doRemoveAllRoles('#(..type)#');" style="margin-top:5px;">>
			}
			
			If ..type = "ApplicationRole"  {
				&html<<div class="sectionLabel">#($$$TextHTML("Add additional application roles by selecting one or more available roles and pressing [Assign]."))#</div>>
			}
			
			Set tSC = ..DrawSelectBoxes(.NullRoles,..type)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
	} Catch Error {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,Error.AsStatus())
	}
	Quit
}

}
