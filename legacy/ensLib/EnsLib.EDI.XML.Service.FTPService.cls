/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Service to receive an XML document as a file from a remote FTP server
Class EnsLib.EDI.XML.Service.FTPService Extends EnsLib.EDI.XML.Service.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

Method OnProcessInput(pFTPStream As %Stream.Object, Output pOutput As %CharacterStream) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tDocument As EnsLib.EDI.XML.Document

	$$$sysTRACE("Got FTP Stream "_pFTPStream_"("_pFTPStream.Size_") for file '"_pFTPStream.Attributes("Filename")_"'")

	Set tDocument=##class(EnsLib.EDI.XML.Document).ImportFromLibraryStream(pFTPStream, .tSC)
	If $$$ISERR(tSC) {
		Return $$$ERROR($$$EnsErrGeneral,"Failed to create document from file '"_pFTPStream.Attributes("Filename")_"': "_$$$StatusDisplayString(tSC))
	}

	Quit ..standardOnProcessInput(tDocument)
}

}
