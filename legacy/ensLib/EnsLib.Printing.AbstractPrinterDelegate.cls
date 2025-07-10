/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract printer operation
Class EnsLib.Printing.AbstractPrinterDelegate Extends Ens.AbstractDelegate [ Abstract, System = 4 ]
{

/// Override this to customize the mapping from logical print targets to actual print destinations
Method FindDestinationForPrinter(pSender As %RegisteredObject, pPrintTarget As %String, ByRef pDestination As %String) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

}
