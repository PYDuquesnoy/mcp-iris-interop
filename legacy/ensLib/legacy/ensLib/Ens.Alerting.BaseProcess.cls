/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsAlertErrors

/// Base process for use by the Managed Alert framework.
Class Ens.Alerting.BaseProcess Extends Ens.BusinessProcess [ Abstract, System = 4 ]
{

/// Don't show the setting for <property>AlertOnError</property>.
Parameter SETTINGS = "-AlertOnError";

/// Don't track message history.
Parameter SKIPMESSAGEHISTORY = 1;

/// Helper method to allow the process to send messages using a SimSync priority.
Method SendRequestSimSync(pTargetDispatchName As %String, pRequest As %Library.Persistent, pResponseRequired As %Boolean = 1, pCompletionKey As %String = "", pDescription As %String = "") As %Status [ Internal ]
{
	$$$sysTRACE("call to "_pTargetDispatchName)
	Set tZH=$zh
	Set tSC = ..SendRequestAsyncInternal(pTargetDispatchName, pRequest, pResponseRequired, pCompletionKey,0,,pDescription,1)
	$$$catTRACE("timing","duration of async call: "_($zh-tZH))
	Quit tSC
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
