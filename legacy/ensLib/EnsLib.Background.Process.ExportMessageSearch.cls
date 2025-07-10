/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Process for exporting messages in the background via WorkFlow
Class EnsLib.Background.Process.ExportMessageSearch Extends Ens.BusinessProcessBPL [ DependsOn = Ens.Background.BP.Context, System = 4 ]
{

/// Flag to require Workflow confirmation task before creating export.<br>
/// The default is On <br>
Property ConfirmationRequired As %Boolean [ InitialExpression = 1 ];

/// If ConfirmationRequired is On then this flag is used to indicate if confirmation is by the requestor.<br>
/// If ConfirmationByRequestor is Off then the user to confirm is taken from the ConfirmUser setting.<br>
/// The default is On <br>
Property ConfirmationByRequestor As %Boolean [ InitialExpression = 1 ];

/// This is used as the Workflow user who needs to confirm or cancel the request if confirmation is required
/// and ConfirmationByRequestor is Off.<br>
/// If this setting is left empty then the confirmation task will be distributed to members of the role for acceptance first.<br>
Property ConfirmUser As %String(MAXLEN = 128);

/// Workflow Role that will be used instead of the Workflow role provided in the request.
Property WorkFlowRole As %String(MAXLEN = 128);

Parameter SETTINGS = "ConfirmationRequired:WorkFlow,ConfirmationByRequestor:WorkFlow,ConfirmUser:WorkFlow:selector?context={Ens.ContextSearch/WorkflowUsers},WorkFlowRole:WorkFlow:selector?context={Ens.ContextSearch/WorkflowRoles}";

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Background.Request.ExportMessage' contextsuperclass='Ens.Background.BP.Context' height='2200' width='2000' >
<context>
<property name='TemporaryExportFile' type='%Stream.FileBinary' instantiate='0' >
<annotation><![CDATA[This is the temporary file that will be downloaded via the workflow. By making it a context property it will be deleted when the BP thread is completed.]]></annotation>
</property>
<property name='TemporaryExportFilename' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='' />
</parameters>
</property>
<property name='FileKey' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='' />
</parameters>
</property>
<property name='FileHash' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='' />
</parameters>
</property>
</context>
<sequence xend='200' yend='1850' >
<if name='FindRole' condition='process.WorkFlowRole=""' xpos='200' ypos='250' xend='200' yend='500' >
<annotation><![CDATA[Use Workflow from process if specified. Otherwise use the workflow role from the request]]></annotation>
<true>
<assign name="Set to request value" property="context.WorkFlowRole" value="request.WorkFlowRole" action="set" xpos='470' ypos='400' />
</true>
<false>
<assign name="Set to process value" property="context.WorkFlowRole" value="process.WorkFlowRole" action="set" xpos='200' ypos='400' />
</false>
</if>
<if name='CheckConfirmationRequirement' condition='process.ConfirmationRequired' xpos='200' ypos='600' xend='200' yend='1200' >
<annotation><![CDATA[Check if Confirmation is required]]></annotation>
<true>
<if name='Assign Confirm User' condition='process.ConfirmationByRequestor' xpos='470' ypos='750' xend='470' yend='1000' >
<true>
<assign name="Set to Requestor" property="context.ConfirmUser" value="request.RequestedByUsername" action="set" xpos='740' ypos='900' />
</true>
<false>
<assign name="Set to Confirmer" property="context.ConfirmUser" value="process.ConfirmUser" action="set" xpos='470' ypos='900' />
</false>
</if>
<while name='FirstConfirmWithUser' condition='context.WaitOnWorkFlow' xpos='470' ypos='1100' xend='200' yend='550' >
<annotation>This first confirms if the user wants to execute the background process</annotation>
<call name='Seek Confirmation' target='EnsLib.Background.Workflow.Operation' async='1' xpos='200' ypos='250' >
<request type='EnsLib.Background.Workflow.ExportRequest' >
<assign property="callrequest.%Actions" value="&quot;Confirm,Cancel Request,-Relinquish&quot;" action="set" />
<assign property="callrequest.%Subject" value="&quot;Please confirm or cancel work request &quot;" action="set" />
<assign property="callrequest.%UserName" value="context.ConfirmUser" action="set" />
<assign property="callrequest.%Command" value="context.WorkFlowRole" action="set" />
<assign property="callrequest.%Message" value="&quot;Export of messages requested by &quot;_request.RequestedByUsername" action="set" />
</request>
<response type='EnsLib.Background.Workflow.ExportResponse' >
<assign property="context.ConfirmAction" value="callresponse.%Action" action="set" />
</response>
</call>
<sync name='Wait For User Confirmation' calls='Seek Confirmation' type='all' xpos='200' ypos='350' />
<assign name="Got Confirmation" property="context.WaitOnWorkFlow" value="0" action="set" xpos='200' ypos='450' />
</while>
</true>
<false>
<assign name="AutoConfirm" property="context.ConfirmAction" value="&quot;Confirm&quot;" action="set" xpos='200' ypos='750' >
<annotation><![CDATA[Automatically confirm WF request]]></annotation>
</assign>
</false>
</if>
<if name='Check If Cancelled' condition='context.ConfirmAction="Confirm"' xpos='200' ypos='1300' xend='200' yend='1750' >
<true>
<code name='Create Temporary File' xpos='470' ypos='1450' >
<![CDATA[
 	Set tSC = $$$OK
 	Try {
 		#; Open Saved Search
 		Set tSavedSearch = $classmethod(request.SearchClass,"%OpenId",request.SavedSearch,,.tSC)
 		If $$$ISERR(tSC) Quit

 		#; Run the search based on saved search
 		Set tFilter = tSavedSearch.Filter
 		Set tAssistantClass=##class(EnsPortal.MessageViewer).GetAssistantClass()
 		Set tSC = $classmethod(tAssistantClass,"GetResultSet",tFilter, .tSearchResultSet)
 		If $$$ISERR(tSC) Quit

 		#; Create temporary export file from the results
 		$$$LOGINFO("Creating Temporary File for: "_request.RequestedByUsername)
 		#dim tFileKey = $$$JobSessionId
 		Set context.TemporaryExportFilename = ##class(EnsPortal.Dialog.ExportMessages).tempServerFilename(request.LocalFilename,tFileKey,request.RequestedByUsername)
 		Set tExportInfo = ##class(EnsPortal.Dialog.ExportMessages).CreateTempFile(request.LocalFilename,tFileKey, request.CharSet, request.MsgSeperators,tSearchResultSet,request.RequestedByUsername)

 		#; Create a link to the temporary file so that it is deleted when the process completes/purged
 		If (context.TemporaryExportFilename'="") && ##class(%Library.File).Exists(context.TemporaryExportFilename) {
 			Set context.TemporaryExportFile = ##class(%Stream.FileBinary).%New()
 			Do context.TemporaryExportFile.LinkToFile(context.TemporaryExportFilename)
 			Set context.FileHash = $SYSTEM.Encryption.SHA3HashStream($$$ensSHA3CheckLength,context.TemporaryExportFile,.status)
		 	$$$LOGINFO("Finished creating temporary file: "_context.TemporaryExportFilename)
 		}

 	} Catch ex {

	 	Set tSC = ex.AsStatus()

	 }

 	#; Delete saved search
 	If $classmethod(request.SearchClass,"%Extends","EnsPortal.MsgFilter.SavedSearch") && ($Extract(request.SavedSearch,1,18)="z_QueuedForExport_") {
	 	Set tSC = $$$ADDSC(tSC,$classmethod(request.SearchClass,"%DeleteId",request.SavedSearch))
 	}
 	If $$$ISERR(tSC) {
 		Set status = tSC
 	}

 ]]>
</code>
<assign name="Reset flag to wait on workflow" property="context.WaitOnWorkFlow" value="1" action="set" xpos='470' ypos='1550' />
<while name='Use WorkFlow for download' condition='context.WaitOnWorkFlow' xpos='470' ypos='1650' xend='200' yend='550' >
<call name='WorkFlow notification Of Download' target='EnsLib.Background.Workflow.Operation' async='1' xpos='200' ypos='250' >
<request type='EnsLib.Background.Workflow.ExportRequest' >
<assign property="callrequest.%Actions" value="&quot;Completed Download,-Relinquish,-Save&quot;" action="set" />
<assign property="callrequest.%UserName" value="request.RequestedByUsername" action="set" />
<assign property="callrequest.%FormTemplate" value="&quot;EnsLib.Background.Workflow.Template.DownloadExport.cls&quot;" action="set" />
<assign property="callrequest.%Command" value="context.WorkFlowRole" action="set" />
<assign property="callrequest.%Subject" value="&quot;Exported File available for download&quot;" action="set" />
<assign property="callrequest.%FormFields" value="&quot;TemporaryExportFilename,CharSet,LocalFilename,FileKey,FileHash&quot;" action="set" />
<assign property="callrequest.%FormValues" value="context.TemporaryExportFilename" action="set" key="&quot;TemporaryExportFilename&quot;" />
<assign property="callrequest.%FormValues" value="request.CharSet" action="set" key="&quot;CharSet&quot;" />
<assign property="callrequest.%FormValues" value="request.LocalFilename" action="set" key="&quot;LocalFilename&quot;" />
<assign property="callrequest.%FormValues" value="$$$JobSessionId" action="set" key="&quot;FileKey&quot;" />
<assign property="callrequest.%FormValues" value="context.FileHash" action="set" key="&quot;FileHash&quot;" />
</request>
<response type='EnsLib.Background.Workflow.ExportResponse' />
</call>
<sync name='Wait on Workflow' calls='WorkFlow notification Of Download' allowresync='true' type='all' xpos='200' ypos='350' />
<assign name="Finished with workflow" property="context.WaitOnWorkFlow" value="0" action="set" xpos='200' ypos='450' />
</while>
</true>
<false>
<code name='Remove Saved Search if cancelled' xpos='200' ypos='1450' >
<![CDATA[ If $classmethod(request.SearchClass,"%Extends","EnsPortal.MsgFilter.SavedSearch") && ($Extract(request.SavedSearch,1,18)="z_QueuedForExport_") {
  Set tSC = $classmethod(request.SearchClass,"%DeleteId",request.SavedSearch)
 }]]>
</code>
</false>
</if>
</sequence>
</process>
}

Storage Default
{
<Data name="ExportMessageSearchDefaultData">
<Subscript>"ExportMessageSearch"</Subscript>
<Value name="1">
<Value>ConfirmationRequired</Value>
</Value>
<Value name="2">
<Value>ConfirmationByRequestor</Value>
</Value>
<Value name="3">
<Value>ConfirmUser</Value>
</Value>
<Value name="4">
<Value>WorkFlowRole</Value>
</Value>
</Data>
<DefaultData>ExportMessageSearchDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
