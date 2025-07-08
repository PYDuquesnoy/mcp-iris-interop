/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Context.Gateway Extends %SystemBase
{

Property gateway As %String(MAXLEN = "") [ MultiDimensional ];

Method push(gateway)
{
	set i%gateway = $g(i%gateway)+1
	set i%gateway(i%gateway) = gateway
}

Method pushDelayed(io, protocol)
{
	set i%gateway = $g(i%gateway)+1
	set i%gateway(i%gateway) = $lb(io,protocol)
}

Method pop()
{
	kill i%gateway(+$g(i%gateway))
	set i%gateway = i%gateway-1
}

Method get() As %ObjectHandle
{
	if $d(i%gateway)=0 quit $$$NULLOREF
	set gateway = $g(i%gateway(i%gateway))
	if gateway="" quit $$$NULLOREF
	if $isObject(gateway) quit gateway
	set gateway = ##class(%Net.Remote.Gateway).%CreateReverseGateway($li(gateway,1),$li(gateway,2))
	set i%gateway(i%gateway) = gateway
	quit gateway
}

}
