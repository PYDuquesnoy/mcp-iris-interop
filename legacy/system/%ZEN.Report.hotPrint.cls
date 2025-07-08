/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.hotPrint Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod print2(pdfFileName, printerName, port, timeOut = "") As %Status
{
		   ; use TCP/IP to contact Print Server and print PDF file to printer
		    Set tSC=$$$OK
		   	Set tio=$io
		    try {
				Set tSC=##class(%ZEN.Report.PrintServer).PortToName(port,.tPrintServerName)
				if $$$ISOK(tSC) {
			    	Set Status=##class(%ZEN.Report.PrintServer).Start(tPrintServerName)
				} else {
					Set Status=$$$OK ; okay if port not part of any PrintServer, maybe PrintServer is being run manually
					Set tSC=$$$OK ; okay if port not part of any PrintServer, maybe PrintServer is being run manually
				}
	    		if $$$ISERR(Status) {
		    		Set tSC=Status
		    		quit 
	    		}
			    Set starttime=$zts
				Set dev="|TCP|1"
				open dev:("127.0.0.1":port:"S":$C(10)):10
				if '$TEST {
					set tSC=$$$ERROR($$$GeneralError,"Cannot contact server on port "_port_".") 
					if tPrintServerName'="" do ##class(%ZEN.Report.PrintServer).LogReportInfo(starttime, $zts, port, tSC, "Timed out on port "_port_" before we could print ",pdfFileName)
					quit
				}
				use dev
				write $L(pdfFileName)
				write ","
				write pdfFileName
				write $L(printerName)
				write ","
				write printerName
				write !

				if (timeOut="") {
					read done
				} else {
					read done:timeOut
					if '$TEST {
						set tSC=$$$ERROR($$$GeneralError,"Timed out on port "_port_" before we could print pdf file") 
						if tPrintServerName'="" do ##class(%ZEN.Report.PrintServer).LogReportInfo(starttime, $zts, port, tSC, "Timed out on port "_port_" before we could render ZEN Report",pdfFileName)
					}
				}
				if $P(done,",")=0 set tSC=$$$ERROR($$$GeneralError,$P(done,",",2))
				close dev
				use tio
				if tPrintServerName'="" do ##class(%ZEN.Report.PrintServer).LogReportInfo(starttime, $zts, port, tSC, "",pdfFileName)
		    } catch {
   				close dev
				use tio
				set tSC=$$$ERROR($$$GeneralError,"Received Control-C or there was a fatal error.")
		    }
		    quit tSC
}

}
