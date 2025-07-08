/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

/// 
Class %ZEN.Report.SplitAndMerge Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod %DisplayPDF(rpt As %ZEN.Report.reportPage, DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, RepeatingElement As %String, CountRepeatingElement As %String, ByRef ArrayLogFiles As %String, ByRef oldxmlfile, ByRef transformfile) As %Status
{
	
	Set tSC=$$$OK

	Do {
		if $g(^%SYS("zenreport","logsplitandmerge")) {
			set classname=rpt.%ClassName(1)
			set logId=$i(^%ISCLOG("zenreport","logentries","splitandmerge"))
		}

		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = rpt.%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0) Quit:$$$ISERR(tSC)
		Set tSC = rpt.%MakeToXSLFOFile(.xslfile) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/pdf
		Set tmpdir=##class(%File).NormalizeDirectory(rpt.GetRootDir())
		Set tRootName=rpt.GetSafeRootName()
		if tRootName="" Set logfile = tmpdir_##class(%FileBinaryStream).NewFileName("txt",rpt.GetRootDir())		
		if tRootName'="" Set logfile = rpt.MakeFileName(rpt.GetRootDir(),tRootName,".txt")
 		; delete logfile so user does not see "ghost" of old logfile when using $REPORTNAME
		i $g(logfile)'="" Do ##class(%File).Delete(logfile)
		if tRootName="" Set pdffile = tmpdir_##class(%FileBinaryStream).NewFileName("pdf",rpt.GetRootDir())
		if tRootName'="" Set pdffile = rpt.MakeFileName(rpt.GetRootDir(),tRootName,".pdf")
		if $g(^%SYS("zenreport","logsplitandmerge")) {
			set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"begintime")=$zts
			set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"xmlfile")=xmlfile
			set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"xslfile")=xslfile
			set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"finaloutputfile")=rpt.OutputFileName
		}

		if (async'=0) {
			if tRootName="" Set lockfile = tmpdir_##class(%FileBinaryStream).NewFileName("lck",rpt.rpt.GetRootDir())
			if tRootName'="" Set lockfile = rpt.MakeFileName(rpt.GetRootDir(),tRootName,".lck")
			if $g(^%SYS("zenreport","logsplitandmerge")) {
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"lockfile")=lockfile
			}

		}

		if '##class(%File).Exists(xmlfile) set tSC=$$$ERROR($$$GeneralError,"xml file does not exist.  The file is "_xmlfile) quit
		Set tXmldoc=##class(%XML.Document).%New()
		Set tXmldoc.KeepWhitespace=1
		Set tEntityResolver = $$$NULLOREF
		Set tSAXFlags = $$$SAXDEFAULTS
		Set tSAXSchemaSpec = ""
		Set tStream=##class(%FileBinaryStream).%New()
		Set tStream.Filename = xmlfile
		Set tSC=##class(%XML.SAX.Parser).ParseStream(tStream,tXmldoc,tEntityResolver,tSAXFlags,,tSAXSchemaSpec)
		if $$$ISERR(tSC) quit 
		#Dim tRoot As %XML.Node
		Set tRoot=tXmldoc.GetDocumentElement()
		#Dim tChild As %XML.Node
		Set tFlag=tRoot.MoveToFirstChild(1)
		Set tChild=tRoot
		Set mdXMLFileNames=0
		Set tInc=0
		while (1) {
			if (tFlag=0) quit
			if (tChild="") quit
			if ((tChild.NodeType = $$$xmlELEMENTNODE)&&(tChild.QName=RepeatingElement))
			{	; create XML file containing root and child nodes
				#Dim writer As %XML.Writer
				Set tTmpdir=##class(%File).NormalizeDirectory(rpt.GetRootDir())
				if rpt.SplitRootName="" Set tXMLFileName = tTmpdir_"xml"_##class(%FileBinaryStream).NewFileName("xml",rpt.GetRootDir())
				if rpt.SplitRootName'="" Set tXMLFileName = tTmpdir_rpt.SplitRootName_$i(tInc)_".xml"
				Set mdXMLFileNames($i(mdXMLFileNames))=tXMLFileName
				Set writer=##class(%XML.Writer).%New()
				Set tSC=writer.OutputToFile(tXMLFileName)
				if $$$ISERR(tSC) quit
				Set tRoot=tXmldoc.GetDocumentElement()
				Set tSC=writer.RootElement(tRoot.QName)
				If $$$ISERR(tSC) Quit
				Set attributeName=""
				for { set attributeName=tRoot.NextAttributeName(attributeName) q:attributeName=""
					do tRoot.GetAttribute(attributeName, .namespace , .value, .valueNamespace)	
					Set tSC=writer.WriteAttribute(attributeName, value, namespace, valueNamespace)
					If $$$ISERR(tSC) Quit
				}
				If $$$ISERR(tSC) Quit
				Set Count=CountRepeatingElement
				while (Count > 0) {
					if (tChild.NodeType = $$$xmlELEMENTNODE) {
						Set tSC=writer.CanonicalTree(tChild)
						If $$$ISERR(tSC) Quit
					}
					Set tFlag=tChild.MoveToNextSibling(1)
					if tFlag=0 quit
					if ((tChild.NodeType = $$$xmlELEMENTNODE)&&(tChild.QName=RepeatingElement)) {
						Set Count=Count-1
					}

				}
				If $$$ISERR(tSC) Quit
				Set tSC=writer.EndRootElement()
				If $$$ISERR(tSC) Quit
				if tFlag=0 quit
				
			} else {
				Set tFlag=tChild.MoveToNextSibling()
				if (tFlag=0) quit
			}
		} 
		if $$$ISERR(tSC) quit

		for i=1:1:mdXMLFileNames {
			if rpt.SplitDir'="" Set tTmpdir=##class(%File).NormalizeDirectory(rpt.SplitDir)
			if rpt.SplitRootName="" Set tpdffile=tTmpdir_"pdf"_##class(%FileBinaryStream).NewFileName("pdf",rpt.GetRootDir())
			if rpt.SplitRootName'="" Set tpdffile=tTmpdir_rpt.SplitRootName_i_".pdf"
			if $g(^%SYS("zenreport","logsplitandmerge")) {
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,i,"txmlfile")=mdXMLFileNames(i)
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,i,"txslfile")=xslfile
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,i,"tpdffile")=tpdffile
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,i,"tbegintime")=$zts
			}

			Set tSC = rpt.%PerformTransform(mdXMLFileNames(i), xslfile, tpdffile, logfile, 1, RenderServer, async, $g(lockfile),DisplayLog)
			if $g(^%SYS("zenreport","logsplitandmerge")) {
				set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,i,"tendtime")=$zts
			}

			if $$$ISERR(tSC) quit

			Set mdPDFFileNames($i(mdPDFFileNames))=tpdffile
			if rpt.SplitOnly Set rpt.%SplitReturnedPDFs(i)=tpdffile
		}
		if $$$ISERR(tSC) quit

		if 'rpt.SplitOnly {
			Set tSC=##class(%SYS.ZENReportPDFMerge).%ServeTransform(rpt,.mdPDFFileNames,pdffile,logfile,.ArrayLogFiles)

			If $$$ISOK(tSC) {
				If DisplayLog {
					Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
				}
				Else {
					Set oid = ##class(%CSP.StreamServer).GetOidForFile(pdffile)
				}
				Set stream=##class(%Stream.Object).%Open(oid)
				$$$SETIO("RAW")
				Do stream.OutputToDevice()
			}
			; if in asynch mode generation of PDF is done by queuing hot JVM server which has responsibility for
			; deleting xmlfile and xslfile.  The queing hot JVM server needs to be connected to a print management system
			; that has the responsibilty for deleting the pdf file when renered.  No logfile is created when PDF rendering
			; is done by hot JVM server.
		}
		if ('async) do rpt.DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.mdXMLFileNames,.mdPDFFileNames,,,rpt.SplitOnly,0) 
		if $g(^%SYS("zenreport","logsplitandmerge")) {
			set ^%ISCLOG("zenreport","logentries","splitandmerge",logId,classname,pdffile,"endtime")=$zts
		}
	} while (0) ;
	Quit tSC
}

Storage Default
{
<Data name="SplitAndMergeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.SplitAndMergeD</DataLocation>
<DefaultData>SplitAndMergeDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%ZEN.Report.SplitAndMergeD</IdLocation>
<IndexLocation>^%ZEN.Report.SplitAndMergeI</IndexLocation>
<StreamLocation>^%ZEN.Report.SplitAndMergeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
