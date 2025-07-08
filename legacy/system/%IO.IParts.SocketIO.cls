/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %IO.IParts.SocketIO [ Abstract, System = 2 ]
{

Method DefaultFlushOnWriteGet() [ CodeMode = expression ]
{
1
}

Method Open(pHost As %String, pPort As %String, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean [ Abstract ]
{
}

}
