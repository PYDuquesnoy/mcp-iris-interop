/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Service.FileService is the file based service class which reads an XML document and
/// then uses %XML.Reader to convert the document to a set of persistent classes.
Class EnsLib.XML.Object.Service.FileService Extends EnsLib.XML.Object.Service.Standard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// Just pass the input stream along to EnsLib.XML.Object.Service.Standard
Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	Quit ..standardOnProcessInput(pInput)
}

}
