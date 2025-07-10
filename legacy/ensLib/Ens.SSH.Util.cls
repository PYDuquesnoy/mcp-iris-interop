/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to provide Interoperable SSH utilities
Class Ens.SSH.Util Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This classmethod is the basic template for providing the Keyboard Interactive callback
/// for SSH Session authentication.
/// See %Net.SSH.Session::AuthenticateWithKeyboardInteractive.
/// Subclass this class and override InteractiveAuth to handle different challenge/response requirements.
/// context is the adapter instance
ClassMethod InteractiveAuth(username As %String, instructions As %String, prompts As %List, promptflags As %List, ByRef context As Ens.Adapter) As %List
{

	#dim tDTL = context.SFTPInteractiveDTL
	#dim tPassword = ""
	#dim tListReturn = ""

	If tDTL = "" {

		Set tPassword = context.%CredentialsObj.Password
		Set tListReturn = $ListBuild(tPassword)

	} Else {

		#dim tDTLChallenge = ..createChallengeSource(username, instructions, prompts, promptflags)

		#dim tDTLResponse As Ens.SSH.InteractiveAuth.Response

		#dim tSC = $classmethod(tDTL,"Transform",tDTLChallenge,.tDTLResponse,.context)
		$$$ThrowOnError(tSC)

		Set tListReturn = ..createListReturnFromResponse(tDTLResponse, .context)

	}

	Return tListReturn
}

ClassMethod createChallengeSource(username As %String, instructions As %String, prompts As %List, promptflags As %List, ByRef context As Ens.Adapter) As Ens.SSH.InteractiveAuth.Challenge
{
	#dim tDTLChallenge As Ens.SSH.InteractiveAuth.Challenge
	Set tDTLChallenge = ##class(Ens.SSH.InteractiveAuth.Challenge).%New()

	Set tDTLChallenge.Username = username
	Set tDTLChallenge.Instructions = instructions

	#dim listPtr = 0
	#dim count =0
	#dim listValue
	Set listPtr=0,count=0
	While $ListNext(prompts,listPtr,listValue) {
		Set count=count+1
		Do tDTLChallenge.Prompts.SetAt($Get(listValue),count)
	}
	SET listPtr=0,count=0
	While $ListNext(promptflags,listPtr,listValue) {
		Set count=count+1
		Do tDTLChallenge.PromptFlags.SetAt($Get(listValue),count)
	}

	Return tDTLChallenge
}

ClassMethod createListReturnFromResponse(DTLResponse As Ens.SSH.InteractiveAuth.Response, ByRef context As Ens.Adapter) As %List
{
	#dim count
	#dim tListReturn = ""

	For count = 1:1:DTLResponse.Responses.Count() {
		Set tListReturn = tListReturn_$ListBuild(DTLResponse.Responses.GetAt(count))
	}

	If (DTLResponse.UseCredentialsPasswordAt > 0) {
		Set $List(tListReturn, DTLResponse.UseCredentialsPasswordAt) = context.%CredentialsObj.Password
	}

	If (DTLResponse.UseSFTPPassphraseCredentialsPasswordAt > 0) {
		Set $List(tListReturn, DTLResponse.UseSFTPPassphraseCredentialsPasswordAt) = context.%SFTPPassphraseCredentialsObj.Password
	}

	Return tListReturn
}

}
