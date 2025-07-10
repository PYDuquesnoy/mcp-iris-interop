/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Service.FTPService is the FTP based service class which reads an XML document and
/// then uses %XML.Reader to convert the document to a set of persistent classes.
Class EnsLib.XML.Object.Service.FTPService Extends EnsLib.XML.Object.Service.Standard [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

Method OnProcessInput(pFTPStream As %Stream.Object, Output pOutput As %CharacterStream) As %Status
{
	$$$sysTRACE("Got FTP Stream "_pFTPStream_"("_pFTPStream.Size_") for file '"_pFTPStream.Attributes("Filename")_"'")

	Quit ..standardOnProcessInput(pFTPStream)
}

}
