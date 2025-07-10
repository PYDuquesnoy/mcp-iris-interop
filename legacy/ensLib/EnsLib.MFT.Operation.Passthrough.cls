/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts objects of type Ens.StreamContainer and uploads to MFT Server
Class EnsLib.MFT.Operation.Passthrough Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.MFT.Adapter.Outbound";

/// Name of target MFT Folder to use if the request object has an empty OutputFolder property.<br>
/// The folder value will be concatenated with the target filename
/// and hence a trailing / or other character as appropriate for the particular service
/// is needed.<br>
Property DefaultMFTFolder As %String(MAXLEN = 1000) [ InitialExpression = "/" ];

/// The OutputFilename property of the request is used as the name of file to create on the MFT Server.<p>
/// If the OutputFilename property of the request is empty then this specification setting is used
/// to generate the target filename as follows:<p>
/// The %f specifier if present will be replaced with the value of
/// the filename portion of the OriginalFilename property.<p>
/// The specification may include timestamp specifiers. See the method CreateTimestamp in class 
/// <CLASS>Ens.Util.File </CLASS> 
/// for documentation of timestamping options.<p>
/// An example to specify a fixed name with a date time stamp for those requests with an empty OutputFilename could be: <p>
/// ImportantDocument.%Q.txt <p>
/// This will create a target file name of for example ImportantDocument.2017-01-30_14.12.44.630.txt<p>
Property DefaultFilenameSpec As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f" ];

/// Indicate if a file on the server exists with the same name then still upload.<br>
/// Default is to upload if a file with the same name exists. <br>
/// The particular MFT Server may generate different versions rather than replace.<br>
Property Overwrite As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS As %String = ",DefaultMFTFolder:Basic,DefaultFilenameSpec:Basic,Overwrite:Basic,-SendSuperSession";

/// Takes an Ens.StreamContainer object and uploads the Stream to the MFT Service. <br>
/// See DefaultMFTFolder and DefaultFilenameSpec.<br>
/// Returns an %MFT.ItemInfo object with information about the upload.
Method OnMessage(pRequest As Ens.StreamContainer, Output pResponse As %MFT.ItemInfo) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tOutputFolder As %String
	#dim tFilenameWithFolder As %String

	Try {

		If 'pRequest.%Extends("Ens.StreamContainer") {

			Set tSC = $$$ERROR($$$EnsErrGeneral,"Request is not a StreamContainer")
			Quit

		}

		If '$IsObject(pRequest.Stream) {

			Set tSC = $$$ERROR($$$EnsErrGeneral,"No Stream contained in StreamContainer Request")
			Quit

		}

		If pRequest.OutputFolder '= "" {

			Set tOutputFolder = pRequest.OutputFolder

		} Else {

			Set tOutputFolder = ..DefaultMFTFolder

		}

		If pRequest.OutputFilename '= "" {

			Set tFilenameWithFolder = tOutputFolder_pRequest.OutputFilename

		} Else {

			#dim tInitialFilenameNoPath As %String
			Set tInitialFilenameNoPath = ##class(%File).GetFilename(pRequest.OriginalFilename)

			Set tFilenameWithFolder = ##class(Ens.Util.File).CreateTimestamp(tInitialFilenameNoPath,
																..DefaultFilenameSpec,
																0 /*isVMS*/,
																tOutputFolder,
																0 /*Not Local*/)

		}

		#dim tTriedReconnecting As %Boolean = 0
		#dim tReconnectedOnError As %Boolean = 0

		Set tSC = ..Adapter.UploadStream(pRequest.Stream,
										tFilenameWithFolder,
										..Overwrite,
										.pResponse,
										.tTriedReconnecting,
										.tReconnectedOnError)

		#; Set Retry flag if reconnected.
		If $$$ISERR(tSC) && tTriedReconnecting && tReconnectedOnError Set ..Retry = 1

	} Catch ex {

		Set tSC=ex.AsStatus()

	}

	Quit tSC
}

}
