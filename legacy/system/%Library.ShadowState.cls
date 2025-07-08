/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 	Datatype for display and validation of shadow states: <ul><li>
/// 			-2: shadow is being stopped</li><li>
/// 			-1: shadow is trying to connect to the source</li><li>
/// 			 0: shadow is suspended</li><li>
/// 			 1: shadow is processing</li><li>
/// 			 2: shadow is stopped</li><li>
/// 			 3: shadow journal copier is active</li></ul>
/// 
Class %Library.ShadowState Extends %Integer [ System = 4 ]
{

ClassMethod IsValid(%State As %RawString) As %Status [ CodeMode = expression, Internal ]
{
$s((%State<-2)||(%State>3):$$$ERROR($$$DatatypeValidationError,"%ShadowState",%State),1:$$$OK)
}

ClassMethod LogicalToDisplay(%state As %Integer) As %String [ Internal ]
{
	q:%state=-2 $$$Text("being stopped","%Utility")
	q:%state=-1 $$$Text("trying to connect","%Utility")
	q:%state=0 $$$Text("suspended","%Utility")
	q:%state=1 $$$Text("processing","%Utility")
	q:%state=2 $$$Text("stopped","%Utility")
	q:%state=3 $$$Text("copier active","%Utility") /// cluster journal copier in any state other than stopped or suspended
	q $$$Text("<UNKNOWN>","%Utility")
}

ClassMethod DisplayToLogical(%typename As %String) As %Integer [ Internal ]
{
	s %typename=$zcvt(%typename,"L")
	q:%typename=$$$Text("being stopped","%Utility") -2
	q:%typename=$$$Text("trying to connect","%Utility") -1
	q:%typename=$$$Text("suspended","%Utility") 0
	q:%typename=$$$Text("processing","%Utility") 1
	q:%typename=$$$Text("stopped","%Utility") 2
	q:%typename=$$$Text("copier active","%Utility") 3 /// cluster journal copier in any state other than stopped or suspended
	q -99
}

ClassMethod CanStart(%State As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
(%State=2)
}

ClassMethod CanStop(%State As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
((-2<%State)&&(%State<2))
}

ClassMethod CanResume(%State As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
(%State=0)
}

ClassMethod CanSuspend(%State As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
((%State=-1)||(%State=1))
}

}
