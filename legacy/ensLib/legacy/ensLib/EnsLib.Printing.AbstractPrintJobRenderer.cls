/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract printer operation
Class EnsLib.Printing.AbstractPrintJobRenderer Extends Ens.BusinessOperation [ Abstract, ProcedureBlock, System = 4 ]
{

Parameter INVOCATION = "Queue";

/// Render a print job from a request
Method Render(pRequest As EnsLib.Printing.PrintRequest, ByRef pResponse As EnsLib.Printing.PrintJob) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.Printing.PrintRequest"> 
		<Method>Render</Method>
	</MapItem>
</MapItems>
}

}
