/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract printer operation
Class EnsLib.Printing.AbstractPrinter Extends (Ens.BusinessOperation, EnsLib.Printing.AbstractPrinterDelegate) [ Abstract, ProcedureBlock, System = 4 ]
{

/// Printer Delegate instance
Property PrinterDelegate As EnsLib.Printing.AbstractPrinterDelegate [ InitialExpression = {$this}, Internal, Private ];

/// Printer Delegate class name if you need this
Property PrinterDelegateClass As Ens.DataType.Class(EXTENDS = "EnsLib.Printing.AbstractPrinterDelegate");

Parameter SETTINGS As %String = "PrinterDelegateClass";

Parameter INVOCATION = "Queue";

/// Print a print job
Method Print(pRequest As EnsLib.Printing.PrintJob, ByRef pResponse As Ens.Response) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.Printing.PrintJob"> 
		<Method>Print</Method>
	</MapItem>
</MapItems>
}

/// Default implementation of AbstractPrinterDelegate:findDestinationForPrinter method
Method FindDestinationForPrinter(pSender As %RegisteredObject, pPrintTarget As %String, ByRef pDestination As %String) As %Status
{
	// Default is to use the print target
	Set pDestination = pPrintTarget
	Quit $$$OK
}

Method OnInit() As %Status
{
	Set tSC = ##super()
	If $$$ISOK(tSC) {
		Set ..PrinterDelegate = ##class(Ens.AbstractDelegate).InitializeDelegate(..PrinterDelegateClass,"EnsLib.Printing.AbstractPrinterDelegate",$this,.tSC)
	}
	
	Quit tSC
}

}
