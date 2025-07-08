/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.reportTemplate Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod %GetTemplateContents(pRetVal As %ZEN.Report.Display.node, pTemplateName As %String, Output pTemplateExists As %Boolean) As %Status [ CodeMode = objectgenerator, Internal, ProcedureBlock = 0 ]
{
	Do %code.WriteLine(" Set pTemplateExists = 0")
	If (%class.Abstract || ($e(%class.Name,1,4)="%ZEN"))  {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Set tSC = $$$OK
	Do %code.WriteLine(" New tRetVal")
	Do %code.WriteLine(" Set tRetVal = """"")
	Do %code.WriteLine(" Goto Dispatch")

	#; figure out if this page should provide automatic localization
	#; For library (system) classes, localization occurs for %ZEN domain
	#; For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	Do %code.WriteLine(" ")
	
	#; find XData for contents of template tag
	#; Skip items in tSkip
	Set tSkip("Contents") = ""
	Set tSkip("Style") = ""

	Set tTemplates = 0
	Set xdc = %compiledclass.XDatas.Count()
	For n = 1:1:xdc {
		Set xdata = %compiledclass.XDatas.GetAt(n)
		If ('$D(tSkip(xdata.Name))) {
			Set tName = xdata.Name

			#; get XDATA as stream
			Set tStream = xdata.Data

			#; generate object tree for template
			If (tStream.Size > 0) {
				#; make sure block starts with "<template"

				Set tHasTemplate = 0
				Do tStream.Rewind()
				While ('tStream.AtEnd) {
					Set tLine = tStream.ReadLine()
					If (tLine [ "<") {
						If ($Find(tLine,"<template")) {
							Set tHasTemplate = 1
						}
						Quit
					}
				}

				If (tHasTemplate) {
					Set tTemplates = tTemplates + 1
					Do tStream.Rewind()
					#; render the stream into page object (with children)
					Set tReader = ##class(%XML.Reader).%New()
					Set tSC = tReader.OpenStream(tStream)
					If $$$ISERR(tSC) Quit
					Do tReader.Correlate("template","%ZEN.Report.Display.template")
	
					#; there should only be one template defined
					#; if template needs to be removed - GetAt(1) to get higher level contents
					Do tReader.Next(.tTemplate,.tSC)
					If $$$ISERR(tSC) Quit
					If '$IsObject(tTemplate) {
						Set tSC = $$$ERROR($$$GeneralError,"No template element defined in template block: "_xdata.Name)
						Quit 
					}

					#; keep track of template name
					Set tTemplateNames(tName) = ""

					#; local label for template (append "lbl"
					Do %code.WriteLine("lbl"_tName)

					#; generate code for template
					s pCollection="list"
					s pKey=""
					; return the value in the "parent" we pass to %GenerateCode - pRetVal
					Do tTemplate.%GenerateCode(%code,tLocalize,pCollection,1,pKey,"pRetVal",1)

					Do %code.WriteLine(" Set pTemplateExists = 1")
					Do %code.WriteLine(" Goto Done")
				}
			}
		}
	}

	#; dispatcher
	Do %code.WriteLine("Dispatch")
	If $D(tTemplateNames) {
		Do %code.Write(" Goto $Case(pTemplateName")
		Set tName = $O(tTemplateNames(""))
		While (tName'="") {
			Do %code.Write(","""_tName_""":lbl"_tName)
			Set tName = $O(tTemplateNames(tName))
		}

		Do %code.WriteLine(",:Done)")
	}
	Do %code.WriteLine("Done")
	Do %code.WriteLine(" Quit $$$OK")

	Quit tSC
}

}
