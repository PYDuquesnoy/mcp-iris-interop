/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Provides the API for managing form associated with Workflow tasks.
Class EnsLib.Workflow.FormEngine Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Determines if this Task has an associated form.
ClassMethod HasForm(pTask As EnsLib.Workflow.TaskResponse) As %Boolean
{
	Quit ((pTask.%FormTemplate '= "") || (pTask.%FormFields '= ""))
}

/// Request to save the task form.
ClassMethod ProcessSubmit(pTask As EnsLib.Workflow.TaskResponse) As %Status
{
	Set tSC = $$$OK
	Set $ZT = ""

	Do {
		// copy submitted form values into Response Collection
		Set tFormFields = pTask.%FormFields

		For f = 1:1:$L(tFormFields,",") {
			Set tField = $P(tFormFields,",",f)
			If (tField '= "") {
				Do pTask.%FormValues.SetAt($G(%request.Data(tField,1)),tField)
			}
		}
		Set tSC = pTask.OnFormSubmit()  Quit:$$$ISERR(tSC)
		Set tSC = pTask.%Save()  Quit:$$$ISERR(tSC)
	} While (0)
Done
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Writes out HTML for the associated form to the current device.
ClassMethod DrawHTMLForm(pTask As EnsLib.Workflow.TaskResponse, pURL As %String = "") As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	Do {
		If (pTask.%FormTemplate '= "") {
			// CSP-based form template
			If (pTask.%FormTemplate [ "/") {
				// get URL
				Set tURL = pTask.%FormTemplate
			} Else {
				// assemble URL
				Set tURL = $P(pURL,"/",1,$L(pURL,"/")-1) _ "/" _ pTask.%FormTemplate
			}
			Set tClass = $system.CSP.GetClassName(tURL)
			If (tClass '= "") {
				// make task available to CSP template
				Set %task = pTask

				// invoke template page to display form
				Do $classmethod(tClass,"OnPage")
				Kill %task
			}
		} Else {
			// Use FormFields definition
			&html<<table>>
			Set tFormFields = pTask.%FormFields
			For f = 1:1:$L(tFormFields,",") {
				Set tField = $P(tFormFields,",",f)
				Set tValue = pTask.%FormValues.GetAt(tField)
				Set tSC = ..DrawHTMLField(tField, tValue)  Quit:$$$ISERR(tSC)
			}
			&html<</table>>
		}
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Write out HTML for a specific field.
/// Type is "String",
ClassMethod DrawHTMLField(pName As %String, pValue As %String = "", pType As %String = "String", pCaption As %String = "") As %Status
{
	//YSD2195 Set:pCaption="" pCaption = pName
	If pCaption="" {
		Set pCaption = pName
		//Use the localized string if it's defined.
		Set uselanguage = $$$SessionLanguage
		Set pCaption = $$FormatMessage^%occMessages(uselanguage,"Ensemble",pCaption,pCaption)
	} 
	
	&html<<tr><td>#(pCaption)#</td><td>>
	
	If (pType = "String") {
		&html<<input type="text" name="#(pName)#" value="#(pValue)#">>
	}
	Else {
		&html<&nbsp;>
	}

	&html<</td></tr>>
	
	Quit $$$OK
}

/// Display Accept Button for this an item.
ClassMethod ShowAcceptButton(pItem As EnsLib.Workflow.Worklist) As %Status
{
	Set tAction = ##class(EnsLib.Workflow.ActionDefinition).%New()
	Set tAction.Name = "$Accept"
	Set tAction.Caption = "@Ensemble:Accept@Accept"
	Set tAction.Title = "@Ensemble:AcceptTitle@Take ownership of this item"

	Do ..DrawActionButton(tAction)
	Quit $$$OK
}

/// Displays defined action buttons for a worklist item.
ClassMethod ShowActionButtons(pItem As EnsLib.Workflow.Worklist) As %Status
{
	// Relinquish and Save are built-in
	// Other actions are defined by EnsLib.Workflow.ActionDefinition

	// !!! make sure default actions are defined
	Do ##class(EnsLib.Workflow.ActionDefinition).CreateDefaultActions()

	Set tOwner = pItem.Task.%TaskStatus.AssignedTo

	#dim tActions = pItem.Task.%Actions

	#dim tHideRelinquish = 0
	If tActions["-Relinquish" {
		Set tActions = $Replace(tActions,"-Relinquish","")
		Set tActions = $ZSTRIP(tActions,"<>",",")
		Set tHideRelinquish = 1
	}

	#dim tHideSave = 0
	If tActions["-Save" {
		Set tActions = $Replace(tActions,"-Save","")
		Set tActions = $ZSTRIP(tActions,"<>",",")
		Set tHideSave = 1
	}

	// 
	If 'tHideRelinquish {
		Set tAction = ##class(EnsLib.Workflow.ActionDefinition).%New()
		Set tAction.Name = "$Relinquish"
		Set tAction.Caption = "@Ensemble:Relinquish@Relinquish"
		Set tAction.Title = "@Ensemble:RelinquishTitle@Relinquish ownership of this item"
		Do ..DrawActionButton(tAction)
	}

	// save (if there is a form)
	If 'tHideSave && ..HasForm(pItem.Task) {
		Set tAction = ##class(EnsLib.Workflow.ActionDefinition).%New()
		Set tAction.Name = "$Save"
		Set tAction.Caption = "@Ensemble:Save@Save"
		Set tAction.Title = "@Ensemble:SaveTitle@Save this item"
		Do ..DrawActionButton(tAction)
	}

	// Task-defined actions

	// loop over items defined for this task

	// default: always provide "Approve" by Default
	If (tActions = "") {
		Set tActions = "Approve"
	}

	// Check to see if a production is running ...	
	Set tIsRunning = ##class(Ens.Director).IsProductionRunning()

	For p = 1:1:$L(tActions,",") {
		Set tActId = $P(tActions,",",p)
		Set tAction = ##class(EnsLib.Workflow.ActionDefinition).%OpenId(tActId)
		If '$IsObject(tAction) {
			// undefined action, create a transient one
			Set tAction = ##class(EnsLib.Workflow.ActionDefinition).%New()
			Set tAction.Name = tActId
			Set tAction.Caption = tActId
			Set tAction.Title = ""
		}
		
		// Only draw enabled buttons if the production is running
		Do ..DrawActionButton(tAction,tIsRunning)
	}

	Quit $$$OK
}

ClassMethod DrawActionButton(pAction As EnsLib.Workflow.ActionDefinition, pEnabled As %Boolean = 1)
{
	Set trActions("Corrected") = "@Ensemble:Corrected@Corrected"
	Set trActions("Ignored") = "@Ensemble:Ignored@Ignored"
	If ($E(pAction.Title,1,1) = "@") {
		Set lActionTitle = ##class(%CSP.Util.AutoFormGenerator).LocalizeText(pAction.Title)
	} Else {
		If pAction.Title'="",$D(trActions(pAction.Title)) Set lActionTitle = ##class(%CSP.Util.AutoFormGenerator).LocalizeText(pAction.Title)
		Else  Set lActionTitle = pAction.Title
	}
	If ($E(pAction.Caption,1,1) = "@") {
		Set lActionCaption = ##class(%CSP.Util.AutoFormGenerator).LocalizeText(pAction.Caption)
	} Else {
		//YSD2195 If pAction.Caption'="",$D(trActions(pAction.Caption)) Set lActionCaption = ##class(%CSP.Util.AutoFormGenerator).LocalizeText(pAction.Caption)
		If pAction.Caption'="",$D(trActions(pAction.Caption)) Set lActionCaption = ##class(%CSP.Util.AutoFormGenerator).LocalizeText(trActions(pAction.Caption))
		Else  Set lActionCaption = pAction.Caption
	}
	
	// if we are in the Zen portal, dispatch to zenPage
	&html<<input #($S('pEnabled:"disabled",1:""))# 
			title="#($ZCVT(lActionTitle,"O","HTML"))#"
			type="button"
			name="BTN_#(pAction.Name)#"
			value="#($ZCVT(lActionCaption,"O","HTML"))#"
			onclick="zenPage?zenPage.actionButtonHandler('#(pAction.Name)#','#($ZCVT(pAction.Prompt,"O","JS"))#'):submitHandler('#(pAction.Name)#','#($ZCVT(pAction.Prompt,"O","JS"))#');">
		>
}

/// Submit handler: this is called by the SubmitHandler on the Zen page handling the submit.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit, Output pMsg As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMsg = ""
		Set tItemId = $G(%request.Data("$ITEMID",1))
		Set tAction = pSubmit.%Action

		// logic from old DetailPane

		// test if task was reassigned or cancelled
		If ('##class(EnsLib.Workflow.Worklist).%ExistsId(tItemId)) {
			Set pMsg = $$$Text("This worklist item has been cancelled or re-assigned to another user.","Ensemble")
			Quit
		}

		// test for built-in ops first
		If (tAction = "$Accept") {
			// take ownership
			Set tSC = ##class(EnsLib.Workflow.Engine).%TakeOwnershipForTask(tItemId,$UserName,.pMsg)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tAction = "$Relinquish") {
			// give up ownership
			Set tSC = ##class(EnsLib.Workflow.Engine).%RelinquishOwnershipForTask(tItemId,$UserName,.pMsg)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tAction = "$Save") {
			// save form fields to Task object

			// process form submit (if there is a form)
			Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(tItemId)
			If ($IsObject(tItem) && ##class(EnsLib.Workflow.FormEngine).HasForm(tItem.Task)) {
				Set tSC = ##class(EnsLib.Workflow.FormEngine).ProcessSubmit(tItem.Task)
			}
		}
		Else {
			// Disallow this action if the production is not running
			If '##class(Ens.Director).IsProductionRunning() {
				Set tSC = $$$EnsError($$$EnsErrProductionNotRunning)
				Quit
			}
			
			// process form submit (if there is a form)
			Set tItem = ##class(EnsLib.Workflow.Worklist).%OpenId(tItemId)
			If ($IsObject(tItem) && ##class(EnsLib.Workflow.FormEngine).HasForm(tItem.Task)) {
				Set tSC = ##class(EnsLib.Workflow.FormEngine).ProcessSubmit(tItem.Task)
			}
	
			// pass operation to Workflow Engine
			Set tSC = ##class(EnsLib.Workflow.Engine).%ProcessAction(tAction,tItemId,$UserName,.pMsg)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
