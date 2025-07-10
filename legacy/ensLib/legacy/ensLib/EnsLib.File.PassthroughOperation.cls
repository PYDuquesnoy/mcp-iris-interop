/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts objects of type Ens.StreamContainer and saves the encapsulated stream data to a file using the File OutboundAdapter.
Class EnsLib.File.PassthroughOperation Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source filename (stripped of certain characters in target filenames - see CharacterSetToRemove).<p>
/// See the method Ens.Util.File::CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q%!+(_a)", Required ];

/// Ens.Util.File::CreateTimestamp() will remove certain characters from the source filename before
/// applying the new name specifier. By default CreateTimestamp removes the following characters: <br>
/// |?\/:[]<>&,; and ASCII control characters 0,7,9,10 and 13. <br>
/// Set to IRIS Default to use the CreateTimestamp default. <br>
/// Set to None to have CreateTimestamp() not strip any characters from the original filename.<br> 
/// Set to Unix to have CreateTimestamp strip / and ASCII control character 0 characters.<br>
/// Set to Windows to have CreateTimestamp strip <>:/\|?* and ASCII control characters 0 through 31 and 34.<br>
/// Set to Detect Unix or Windows to detect at startup if Unix or Windows and use the appropriate set as given above. <br>
/// <br>
/// Note: After CreateTimestamp() has removed any specified characters it will carry out the date time modification based on the
/// filename specificiation and then the final output string, spaces (' ') are replaced by underbars ('_'), slashes ('/') replaced by hyphens ('-')
/// and colons (':') replaced by dots ('.'), except on VMS where both slashes ('/') and colons (':') are instead replaced by hyphens ('-').<br>
/// This means if characters are to be removed and the original filename contains / or : or spaces and are not considered removable characters
/// they are still modified to _,/,-,. as stated.
/// However if None is chosen as the character set to remove and the filename spec is just %f then no modifications will be applied to space, slashes or colons.
/// This can be used when it is necessary to use exactly the same name as the source.
/// 
Property CharacterSetToRemove As %String(DISPLAYLIST = ",IRIS Default,None,Unix,Windows,Detect Unix or Windows", VALUELIST = ",IRIS,None,Unix,Windows,OSDetect") [ InitialExpression = "IRIS" ];

/// Set in OnInit based on value of CharacterSetToRemove
Property CharactersToRemove As %String [ Internal ];

Parameter SETTINGS As %String = "Filename:Basic,CharacterSetToRemove:Basic";

Method OnInit() As %Status
{
	Set tSC = ##super()
	If $$$ISOK(tSC) {
		/*	Hardcoding the default from Ens.Util.File CreateTimestamp() method to
			avoid adding a test per message in order not to pass the extra parameter
			or pass a variable by reference
		*/
		If ..CharacterSetToRemove = "IRIS" {
			Set ..CharactersToRemove = "|?\/:[]<>&,;"_$Char(0,7,9,10,13)
		} ElseIf ..CharacterSetToRemove = "None" {
			Set ..CharactersToRemove = ""
		} ElseIf ..CharacterSetToRemove = "Unix" || (..CharacterSetToRemove = "OSDetect" && $$$isUNIX) {
			Set ..CharactersToRemove = "/"_$C(0)
		} ElseIf ..CharacterSetToRemove = "Windows" || (..CharacterSetToRemove = "OSDetect" && $$$isWINDOWS) {
			Set ..CharactersToRemove = "<>:/\|?*"_$Char(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,34)
		}
	}
	Return tSC
}

Method OnMessage(pRequest As Ens.StreamContainer, Output pResponse As %Persistent) As %Status
{
	Quit:'$IsObject(pRequest.Stream) $$$ERROR($$$EnsErrGeneral,"No Stream contained in StreamContainer Request")
	If "@"'=$E(..Adapter.FilePath) {
		Set tFilename=..Adapter.CreateFilename(##class(%File).GetFilename(pRequest.OriginalFilename),..Filename,,,,..CharactersToRemove)
		Set tSC=..Adapter.PutStream(tFilename, pRequest.Stream)
		Do pRequest.%Save() ; re-save in case PutStream() optimization changed the Stream filename
	} Else {
		#; Forward to agent
		If pRequest.Stream.%Extends("%Library.FileStreamAdaptor") {
			#; copy to a global stream in a new container
			Set tStream=##class(%FileBinaryStream).%New()
			Merge tStream.Attributes=pRequest.Stream.Attributes
			Set tSC=tStream.CopyFrom(pRequest.Stream)
			Set tSC=tStream.SaveStream()  Quit:$$$ISERR(tSC) tSC
			Set tMsg=##class(Ens.StreamContainer).%New(tStream)
		} Else {
			Set tMsg=pRequest
		}
		Set tFilename=##class(Ens.Util.File).CreateTimestamp(##class(%File).GetFilename(pRequest.OriginalFilename),..Filename,,,,..CharactersToRemove)
		Set tAgent=$P(..Adapter.FilePath,":"), tTimeout=+$P(tAgent,"(",2), tAgent=$P(tAgent,"(")  Set:'tTimeout tTimeout=-1
		Set tSC=..EnQueueToService(tAgent,tMsg,..%RequestHeader,,tFilename) ; !!! Sync(...,,tTimeout,..%RequestHeader.Description)
	}
	Quit tSC
}

ClassMethod EnQueueToService(pTargetQueueName As %String, pRequest As %RegisteredObject, pOriginalHeader As Ens.MessageHeader, Output pNewHeader As Ens.MessageHeader, pDescription As %String = "") As %Status [ Internal ]
{
	Set tSC = ##class(Ens.MessageHeader).NewRequestMessage(.pNewHeader,pRequest,pOriginalHeader.SessionId) Quit:$$$ISERR(tSC) tSC
	Set pNewHeader.CorrespondingMessageId = pOriginalHeader.%Id()
	Set pNewHeader.SourceConfigName = pOriginalHeader.TargetConfigName
	Set pNewHeader.TargetConfigName = $P(pTargetQueueName,":")
	Set pNewHeader.SourceBusinessType = $$$eHostTypeOperation
	Set pNewHeader.TargetBusinessType = $$$eHostTypeService
	Set pNewHeader.TargetQueueName = pTargetQueueName
	Set pNewHeader.Description = pDescription
	Quit ##class(Ens.Queue).EnQueue(pNewHeader)
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("FilePath",.tValue) {
		If "@"=$E(tValue) {
			Set tAgent=$E($P(tValue,":"),2,*)
			#; if agent package is installed, call it to find the appropriate agent Service connection.
			try {
				Set tSC=$classmethod("EnsLib.Agent.Interface","GetAgentService",tAgent,pItem.Name,.tAgentService)
				Set:""'=tAgentService&&$$$ISOK(tSC) pArray(tAgentService)=""
			} catch {  }
		}
	}
}

}
