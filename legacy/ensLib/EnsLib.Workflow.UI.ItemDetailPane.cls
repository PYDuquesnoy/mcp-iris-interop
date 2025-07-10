/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// An AutoPage pane that displays details for a Workflow Item
Class EnsLib.Workflow.UI.ItemDetailPane Extends %CSP.Util.Pane [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Method DrawHEAD(pInstance As %CSP.Util.PageInstance) As %Status
{
	// get page ID values
	Merge tID = pInstance.IDValues

	// override table style
	&html<
<style>

BODY {
	background: #EEFFFF;
}

TABLE.LayoutMain {
	background: #EEFFFF;
}

TABLE.LayoutMain TD.LayoutContentCol {
	background: #EEFFFF;
	padding-left: 20px;
	vertical-align: top;
	
	filter: progid:DXImageTransform.Microsoft.Gradient(GradientType=1, StartColorStr='#DDEEFF', EndColorStr='#4040FF');
}

table.Props {	border: 1px black solid; background: white; 
				filter: 
					progid:DXImageTransform.Microsoft.dropShadow(color=#404040, OffX=2, OffY=2, Positive=2);
			}

table.Props td {	border-bottom: 1px blue solid;
					border-right: 1px blue solid;
					padding: 2px;
				  }

td.PropLabel { font-weight: bold; padding: 0px;}

table.Context {	border: none; }

table.Context td {	border-bottom: 1px gray solid;
					border-right: 1px gray solid;
					padding: 0px;
				  }


td.Label { font-weight: bold; padding: 0px;}

</style>
<script language="JavaScript">
function loadHandler()
{
	var form = self.document.theForm;
	// test for user-callback (from CSP form template)
	if (self.onLoad) {
		self.onLoad(form)
	}
	return true;
}

function submitHandler(action,confirmMsg)
{
	if (confirmMsg && (confirmMsg != '')) {
		if (!confirm(confirmMsg)) {
			return false;
		}
	}
	
	var form = self.document.theForm;

	// test for user-callback (from CSP form template)
	if (self.onAction) {
		if (!self.onAction(form,action)) {
			return false;
		}
	}

	form.SUBMIT_OPERATION.value = action;
	form.submit();
	return true;
}
</script>
>

	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As %CSP.Util.PageInstance) As %Status
{
	// get page ID values
	Merge tID = pInstance.IDValues

	// Item Id
	Set tItemId = $G(tID(1))

	Set tShowItem = 1
	Set tRefresh = 0

	Do {
		// page variables
		// SUBMIT_OPERATION specifies which operation we are submitting
		&html<<form name="theForm">
			<input type="hidden" name="SUBMIT_OPERATION" value="">
			<input type="hidden" name="$ID1" value="#($G(%request.Data("$ID1",1)))#">
			<input type="hidden" name="$ID2" value="#($G(%request.Data("$ID2",1)))#">
			<input type="hidden" name="$FRAME" value="#($G(%request.Data("$FRAME",1)))#">
		>

		// test for submit
		Set tMsg = ""
		Set tSubOp = $G(%request.Data("SUBMIT_OPERATION",1))
		If (tSubOp '= "") {
			Set tSC = ..ProcessSubmit(tSubOp,tItemId,%session.Username,.tShowItem,.tMsg,.tRefresh)
			If $$$ISERR(tSC) {
				Write "Error:",!
				Do $System.Status.DisplayError(tSC)
				Quit
			}
			
			If (tMsg '= "") {
				&html<<div>#(tMsg)#</div>>
				Quit
			}
		}

		Set tItem = ""
		If (tShowItem) {
			Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(tItemId)
		}

		If ('$IsObject(tItem)) {
			Set msgText("EDNoSelection") = $$$TextHTML("No item selected.")
			&html<<div class="Text1">#(msgText("EDNoSelection"))#</div>>
		}
		Else {
			// what state are we in?
			Set tOwner = tItem.Task.%TaskStatus.AssignedTo
			If (tOwner = "") {
				Set tState = "unowned"
			}
			ElseIf (tOwner = %session.Username) {
				Set tState = "owned"
			}
			Else {
				// owned by someone else
				Set tState = "other"
			}
			
			Do ..ShowDetails(tItem,tState)
			
			If (tState = "owned") {
				Do ..ShowForm(tItem,tState)
			}

			&html<<hr><div>>
			
			// determine what buttons to show
			If (tState = "unowned") {
				Do ##class(EnsLib.Workflow.FormEngine).ShowAcceptButton(tItem)
			}	 
			ElseIf (tState = "owned") {
				Do ##class(EnsLib.Workflow.FormEngine).ShowActionButtons(tItem)
			}
			&html<</div>>
		}

		&html<</form>>

		If (tRefresh) {
			// refresh upper pane
			&html<
				<script language="javascript">
				if (self.top.Detail) { self.top.Detail.refreshTable(); }
				</script>
			>
		}


		// onload notifier
		&html<
			<script language="javascript">
				loadHandler();
			</script>
		>

	} While(0)

	Quit $$$OK
}

/// Submit handler for this page
Method ProcessSubmit(pAction As %String, pItemId As %String, pUserName As %String, ByRef pShowItem As %Boolean, ByRef pMsg As %String, ByRef pRefresh As %Boolean) As %Status
{
	// !!! move to pre HTTP
	Set tSC = $$$OK
	Set pRefresh = 0 // refresh upper pane
	Set pShowItem = 1 // show the work item
	
	Do {
		// test if task was reassigned or cancelled
		If ('##class(EnsLib.Workflow.Worklist).%ExistsId(pItemId)) {
			Set pMsg = "This worklist item has been cancelled or r&euml;assigned to another user."
			Quit
		}

		// test for built-in ops first
		If (pAction = "$Accept") {
			// take ownership
			Set tSC = ##class(EnsLib.Workflow.Engine).%TakeOwnershipForTask(pItemId,pUserName,.pMsg)
			If $$$ISERR(tSC) Quit
			Set pRefresh = 1
			Set pShowItem = 1
		}
		ElseIf (pAction = "$Relinquish") {
			// give up ownership
			Set tSC = ##class(EnsLib.Workflow.Engine).%RelinquishOwnershipForTask(pItemId,pUserName,.pMsg)
			If $$$ISERR(tSC) Quit
			Set pRefresh = 1
			Set pShowItem = 1
		}
		ElseIf (pAction = "$Save") {
			// save form fields to Task object

			// process form submit (if there is a form)
			Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(pItemId)
			If ($IsObject(tItem) && ##class(EnsLib.Workflow.FormEngine).HasForm(tItem.Task)) {
				Set tSC = ##class(EnsLib.Workflow.FormEngine).ProcessSubmit(tItem.Task)
			}
		
			Set pShowItem = 1
		}
		Else {
			// Disallow this action if the production is not running
			If '##class(Ens.Director).IsProductionRunning() {
				Set tSC = $$$EnsError($$$EnsErrProductionNotRunning)
				Quit
			}
			
			// process form submit (if there is a form)
			Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(pItemId)
			If ($IsObject(tItem) && ##class(EnsLib.Workflow.FormEngine).HasForm(tItem.Task)) {
				Set tSC = ##class(EnsLib.Workflow.FormEngine).ProcessSubmit(tItem.Task)
			}
	
			// pass operation to Workflow Engine
			Set tSC = ##class(EnsLib.Workflow.Engine).%ProcessAction(pAction,pItemId,pUserName,.pMsg)
			If $$$ISERR(tSC) Quit
			Set pRefresh = 1
			Set pShowItem = 0
		}
	} While(0)
	
	Quit tSC
}

/// Show details for this worklist item
Method ShowDetails(pItem As EnsLib.Workflow.Worklist, pState As %String) As %Status
{
	Set tTask = pItem.Task

	Set tOwner = $ZCVT(tTask.%TaskStatus.AssignedTo,"O","HTML")
	Set:tOwner="" tOwner = "<i>"_$$$TextHTML("unassigned")_"</i>"
	
	&html<<table>
	<tr>
		<td class="label">#($$$TextHTML("TaskId:","Ensemble"))#</td>
		<td>#(tTask.%Id())#&nbsp;&nbsp;&nbsp;</td>
		<td class="label">#($$$TextHTML("Owner:","Ensemble"))#</td>
		<td>#(tOwner)#&nbsp;&nbsp;&nbsp;</td>
		<td class="label">#($$$TextHTML("Subject:","Ensemble"))#</td>
		<td>#($ZCVT(tTask.%Subject,"O","HTML"))#&nbsp;</td>
	</tr></table>>
		
	If (pItem.Task.%Message '= "") {
		&html<<table><tr valign="top">
			<td class="label">#($$$TextHTML("Message:","Ensemble"))#</td>
			<td><textarea rows="5" cols="80" readonly>#($ZCVT(tTask.%Message,"O","HTML"))#</textarea></td>
		</tr></table>>
	}
	Quit $$$OK
}

/// Show form for this worklist item
Method ShowForm(pItem As EnsLib.Workflow.Worklist, pState As %String) As %Status
{
	Set tSC = $$$OK
	Set tTask = pItem.Task

	If (##class(EnsLib.Workflow.FormEngine).HasForm(tTask)) {
		&html<<hr>>
		Set tSC = ##class(EnsLib.Workflow.FormEngine).DrawHTMLForm(tTask,%request.URL)
	}

	Quit tSC
}

}
