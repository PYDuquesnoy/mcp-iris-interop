/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// APIs for automatic target selection when resending messages from the Message Bank
Class Ens.Enterprise.MsgBank.Targeting [ Abstract, System = 4 ]
{

/// Enables Individual Targeting in the current namespace.
/// If <var>pCallbackClass</var> is supplied, this will be used as the callback class for 
/// all automatic resend targeting. If <var>pForce</var> is true, then Collective Targeting will
/// be disabled. This allows one to ensure that Individual Targeting does occur.
ClassMethod EnableIndividualTargeting(pCallbackClass As %String = "", pForce As %Boolean = 0) As %Status [ Final ]
{
	Set ^Ens.MsgBank.Targeting("Individual") = 1
	If pCallbackClass'="" Set ^Ens.MsgBank.Targeting("CallbackClass")=pCallbackClass
	If pForce Quit ..DisableCollectiveTargeting()
	Quit $$$OK
}

/// Disables Individual Targeting in the current namespace.
ClassMethod DisableIndividualTargeting() As %Status [ Final ]
{
	Kill ^Ens.MsgBank.Targeting("Individual")
	Quit $$$OK
}

/// Enables Collective Targeting in the current namespace.
/// If <var>pCallbackClass</var> is supplied, this will be used as the callback class for 
/// all automatic resend targeting
ClassMethod EnableCollectiveTargeting(pCallbackClass As %String = "") As %Status [ Final ]
{
	Set ^Ens.MsgBank.Targeting("Collective")=1
	If pCallbackClass'="" Set ^Ens.MsgBank.Targeting("CallbackClass")=pCallbackClass
	Quit $$$OK
}

/// Disables Collective Targeting in the current namespace.
ClassMethod DisableCollectiveTargeting() As %Status [ Final ]
{
	Kill ^Ens.MsgBank.Targeting("Collective")
	Quit $$$OK
}

/// Retrieves the current settings as output variables. By default, it will also validate the configuration
/// and output any errors in <var>pIsValid</var>.
ClassMethod GetCurrentConfig(Output pCallbackClass As %String, Output pIndividual As %Boolean, Output pCollective As %Boolean, ByRef pIsValid = 1) As %Status [ Final ]
{
	Set pCallbackClass = $G(^Ens.MsgBank.Targeting("CallbackClass"))
	Set pCollective = $G(^Ens.MsgBank.Targeting("Collective"),0)
	Set pIndividual = $G(^Ens.MsgBank.Targeting("Individual"),0)
	If $G(pIsValid)&&(pCollective||pIndividual) {
		Set pIsValid = ..isConfigValid(.pIndividual, .pCollective)
	}
	Quit $$$OK
}

/// Sets the callback class for both Individual and Collective Targeting in the current namespace.
/// If <var>pCallbackClass</var> isn't supplied, the value is set to ""
ClassMethod SetCallbackClass(pCallbackClass As %String = "") As %Status [ Final ]
{
	Set ^Ens.MsgBank.Targeting("CallbackClass")=pCallbackClass
	Quit $$$OK
}

/// This is a stub for a callback to redirect specific messages supplied to the Enterprise
/// Message Bank resend pages. The method should return the new target and/or node in the two output
/// parameters <var>pNewNode</var> and <var>pNewItem</var>. These should be left as "" to leave 
/// the target as the original.
ClassMethod IndividualMessage(pMessageHeaderId As %Integer, Output pNewNode As %String, Output pNewItem As %String) As %Status [ Abstract ]
{
	Set pNewNode = ""
	Set pNewItem = ""
	Quit $$$OK
}

/// This is a stub for a callback to redirect a group of messages supplied to the Enterprise
/// Message Bank resend pages. Note that all of the messages will be resent to the target speficied
/// in this callback. The method must return the new target and/or node in the two output
/// parameters <var>pNewNode</var> and <var>pNewItem</var>. These should be left as "" to leave
/// the targets as per the original messages.
/// It is also important to note that <var>pGlobalCounter</var> is a reference to the node in
/// ^IRIS.Temp.ResendIDs being used to process messages. The message IDs are all stored in nodes
/// immediately below the supplied reference, so you need to $order over 
/// ^IRIS.Temp.ResendIDs(pGlobalCounter,<messageId>) to retrieve all the message IDs.
ClassMethod AllMessages(pGlobalCounter As %Integer, Output pNewNode As %String, Output pNewItem As %String) As %Status [ Abstract ]
{
	Set pNewNode = ""
	Set pNewItem = ""
	Quit $$$OK
}

ClassMethod isConfigValid(Output pIndividual As %Boolean, Output pCollective As %Boolean) As %Status [ Internal ]
{
	Set pIndividual = 0
	Set pCollective = 0
	Set tCallbackClass = $G(^Ens.MsgBank.Targeting("CallbackClass"))
	If tCallbackClass Quit $$$ERROR($$$EnsErrGeneral,"Callback class is not specified")
	
	If '##class(%Dictionary.CompiledClass).%ExistsId(tCallbackClass) Quit $$$ERROR($$$EnsErrGeneral,"Callback class does not exist")
	
	Set tIndivStatus = $$$OK
	If $G(^Ens.MsgBank.Targeting("Individual")) {
		Set tMeth = ##class(%Dictionary.CompiledMethod).%OpenId(tCallbackClass_"||IndividualMessage")
		If $IsObject(tMeth) {
			Set pIndividual = ((tMeth.ClassMethod)&&('tMeth.Abstract))
			If 'pIndividual Set tIndivStatus = $$$ERROR($$$EnsErrGeneral,tCallbackClass_":IndividualMessage() is not a runnable classmethod")
		}
		Else { 
			Set pIndividual = 0 
			Set tIndivStatus = $$$ERROR($$$EnsErrGeneral,tCallbackClass_":IndividualMessage() does not exist")
		}
	}
	Set tCollStatus = $$$OK
	If $G(^Ens.MsgBank.Targeting("Collective")) {
		Set tMeth = ##class(%Dictionary.CompiledMethod).%OpenId(tCallbackClass_"||AllMessages")
		If $IsObject(tMeth) {
			Set pCollective = ((tMeth.ClassMethod)&&('tMeth.Abstract))
			If 'pCollective Set tCollStatus = $$$ERROR($$$EnsErrGeneral,tCallbackClass_":AllMessages() is not a runnable classmethod")
		}
		Else {
			Set pCollective = 0
			Set tCollStatus = $$$ERROR($$$EnsErrGeneral,tCallbackClass_":AllMessages() does not exist")
		}
	}
	If pCollective&&pIndividual {
		Set pIndividual = 0
		Set tIndivStatus= $$$ERROR($$$EnsErrGeneral,"Individual Targeting is being overridden by Collective Targeting.")
	}
	Quit $$$ADDSC(tIndivStatus,tCollStatus)
}

}
