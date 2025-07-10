/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract printer operation
Class EnsLib.Printing.ZENReportsRenderer Extends EnsLib.Printing.AbstractPrintJobRenderer [ ProcedureBlock, System = 4 ]
{

/// Render a print job from a request
Method Render(pRequest As EnsLib.Printing.ZENReportsPrintRequest, ByRef pResponse As EnsLib.Printing.PrintJob) As %Status
{
	#define ZENREPORTMODE4PDF 2
	
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap",%objlasterror=$$$OK
	Do {
		#dim tRenderer As %ZEN.Report.reportPage
		#dim tOutput As %Stream.FileBinary
		#dim tKey As %String
		#dim tValue As %String
		
		// Load an instance of the renderer
		Set tRenderer = $ZOBJCLASSMETHOD(pRequest.ClassName,"%New")
		If '$IsObject(tRenderer) Set tSC=%objlasterror Quit
		
		// Now, assign any parameters
		Set tKey=""
		For {
			Set tValue = pRequest.Parameters.GetNext(.tKey)
			Quit:tKey=""
			
			Set $ZOBJPROPERTY(tRenderer,tKey)=tValue
		}
		
		Set tOutput = ##class(%Stream.FileBinary).%New()
		Do tOutput.Write("")
		
		// Invoke the report:
		Set tSC = tRenderer.GenerateReport(tOutput.Filename, 0) //$$$ZENREPORTMODE4PDF)
		Quit:$$$ISERR(tSC)
		
		Do tOutput.Rewind()
		
		// Construct the response
		Set pResponse = ##class(EnsLib.Printing.PrintJob).%New()
		Set tSC = pResponse.Content.CopyFrom(tOutput)
		Quit:$$$ISERR(tSC)
		
		Set pResponse.ContentType = "application/pdf"
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
