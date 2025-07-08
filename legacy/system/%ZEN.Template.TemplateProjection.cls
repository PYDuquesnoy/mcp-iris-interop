/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Projection class used by <class>%ZEN.Templage.studioTemplate class</class>.
Class %ZEN.Template.TemplateProjection Extends %Projection.AbstractProjection [ Deprecated, System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Don't run this method on the base class
		If (pClassName="%ZEN.Template.studioTemplate") Quit

		Set tTemplateName = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATENAME",$$$cPARAMdefault)
		Set tTemplateMode = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATEMODE",$$$cPARAMdefault)
		Set tTemplateDescription = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATEDESCRIPTION",$$$cPARAMdefault)
		Set tTemplateType = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATETYPE",$$$cPARAMdefault)
		Set tGlobalTemplate = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"GLOBALTEMPLATE",$$$cPARAMdefault)
		Set tTemplateNoOutput = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATENOOUTPUT",$$$cPARAMdefault)
		Set tTemplateAccelerator = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATEACCELERATOR",$$$cPARAMdefault)
		Set tTemplateGroup = $$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"TEMPLATEGROUP",$$$cPARAMdefault)

		#; Now register this template information
		If (+tGlobalTemplate) {
			#; Only-% templates are supported for global templates
			Set tPageName = "/isc/studio/templates/" _ $ZCVT(pClassName,"O","URL")_".cls"
		}
		Else {
			#; Use the default csp application for the current namespace
			Set tPageName = $$getDefaultApp^%SYS.cspServer2($namespace) _ "/" _ $ZCVT(pClassName,"O","URL")_".cls"
		}

		#; use name as id
		Set version = $System.Version.GetNumber()
		If ($E(version,1,3) = "5.2") {
			Set tSC = ##class(%CSP.StudioTemplateMgr).AddTemplate(tTemplateName,tTemplateMode,tPageName,tTemplateDescription,pClassName,tTemplateType,1,tGlobalTemplate,tTemplateName,tTemplateNoOutput)
		}
		ElseIf ($E(version,1,6) = "2007.1") {
			Set tSC = ##class(%CSP.StudioTemplateMgr).AddTemplate(tTemplateName,tTemplateMode,tPageName,tTemplateDescription,pClassName,tTemplateType,1,tGlobalTemplate,tTemplateName,tTemplateNoOutput,tTemplateAccelerator)
		}
		Else {
			Set tSC = ##class(%CSP.StudioTemplateMgr).AddTemplate(tTemplateName,tTemplateMode,tPageName,tTemplateDescription,pClassName,tTemplateType,1,tGlobalTemplate,tTemplateName,tTemplateNoOutput,tTemplateAccelerator,tTemplateGroup)
		}
		If $$$ISERR(tSC) Quit

	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod RemoveProjection(pClassName As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Don't run this method on the base class
		If (pClassName="%ZEN.Template.studioTemplate") Quit

	} While(0)
Exit
  	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
