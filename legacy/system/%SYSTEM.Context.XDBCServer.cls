/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Context.XDBCServer Extends %SystemBase
{

/// TCP/Shared Memory device for the connection - Used to be help in %qdev
Property Device As %RawString;

Property ServerOptions As %String(MAXLEN = "") [ MultiDimensional ];

Property contextStack As %String(MAXLEN = "") [ MultiDimensional ];

Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	set tSC=$$$OK
	try {
		set i%Device=""
	}
	catch(ex) {
		set tSC = ex.AsStatus()
	}
	RETURN tSC
}

/// pushState will push the current state of the Context.XDBCServer singleton onto the contextStack. 
/// This method is not normally invoked directly. It is normally called by a utility class method to push a context. 
Method pushState() As %Status
{
	set tPtr=i%contextStack+1
	set i%contextStack(tPtr,1) = ..Device
	// We do not need to push the ServerOptiosn array
	//merge i%contextStack(tPtr,2) = ..ServerOptions
		// When any new properties are added to this class make sure to handle them appropriately here and also in popContext
	set i%contextStack = tPtr
	RETURN $$$OK
}

/// popState will restore the state of the Context.SQL singleton from the top of the contextStack and remove the top stack element. 
/// This method is not normally invoked directly. It is normally called by a utility class method to pop a context. 
Method popState() As %Status
{
	if i%contextStack {
		set tPtr=i%contextStack
		set i%Device=i%contextStack(tPtr,1)
		// We do not need to pop the ServerOptiosn array
		//kill i%ServerOptions merge i%ServerOptions=i%contextStack(tPtr,2)
			// When any new properties are added to this class make sure to handle them appropriately here and also in popContext
		set i%contextStack=tPtr-1
		kill i%contextStack(tPtr)
	}
	RETURN $$$OK
}

}
