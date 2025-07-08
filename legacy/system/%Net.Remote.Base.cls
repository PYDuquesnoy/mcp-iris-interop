/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Remote.Base Extends %Net.Remote.Object [ System = 3 ]
{

Parameter REMOTECLASSNAME As STRING;

Method %Constructor(gateway As %Net.Remote.Gateway, className As %String, args...) As %Status
{
	if $IsObject($g(gateway))=0 return $$$OK
	if gateway.ProtocolVersion<58 return $$$ERROR($$$GeneralError,$classname()_" requires Gateway version 2020.1 or higher")
	set ..%gateway = gateway
	set classname = ..#REMOTECLASSNAME if classname="" set classname = $classname()
	do ..%dispatch("YD",$this_"",classname,gateway,args...)
	return $$$OK
}

Method %DispatchMethod(methodName As %String, args...) As %ObjectHandle
{
	return:$quit ..%dispatch(,$this_"",methodName,..%gateway,args...)
	do ..%dispatch(,$this_"",methodName,..%gateway,args...)
	return
}

ClassMethod %DispatchClassMethod(className As %String, methodName As %String, args...) As %ObjectHandle
{
	return:$quit ..%dispatch(,className,methodName,args...)
	do ..%dispatch(,className,methodName,args...)
	return
}

ClassMethod %dispatch(code = "YE", invokee, method, gateway, args...) As %ObjectHandle
{
	if gateway.ProtocolVersion<58 throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Recast Gateway requires IRIS version 2020.1 or higher"))
	try {
		set currentDevice = $io
		do ..%PreInvoke(gateway,.closedOREFs)
		set args = +$g(args)
		for i=1:1:args if $isObject($g(args(i))) do gateway.%RetainObject(args(i),gateway)
		set (sequenceNumber,gateway.SequenceNumber) = gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"",code,.closedOREFs,invokee_"",method,args,args...)
		do ..%GetResponse(gateway,sequenceNumber,code,currentDevice,.orefCache)
		do ..%ProcessReturnValues(gateway,currentDevice,.returnValue,args...)
		do ..%PostInvoke(gateway,currentDevice)
		return:$d(returnValue) returnValue
		return
		;
	} catch ex {
		use currentDevice
		if $classname(ex)="%Net.Remote.Exception" set x = $$$ERROR($$$RemoteGatewayError,ex.RawData) zt "JGTW"
		throw ex
	}
}

ClassMethod %ProcessReturnValues(gateway, currentDevice, returnValue, args...)
{
	for  {
		set type = $system.IS.Receive()
		;
		if (type="end") || (type="endofdata") quit
		;
		if type="value" {
			set value = $system.IS.Receive()
			set returnValue = value
			continue
		}
		if type="object" {
			set value = $system.IS.Receive()
			set returnValue = $zobjref(value)
			continue
		}
		if (type="vlist") || (type="valuelist") {
			set length = $system.IS.Receive()
			set collection = ##class(%ListOfDataTypes).%New()
			for i=1:1:length do collection.Insert($system.IS.Receive())
			set returnValue = collection
			continue
		}
		if (type="olist") || (type="objectlist") {
			set length = $system.IS.Receive()
			set collection = ##class(%ListOfObjects).%New()
			for i=1:1:length do collection.Insert($zobjref($system.IS.Receive()))
			set returnValue = collection
			continue
		}
		if type="bstream" {
			set stream = ##class(%GlobalBinaryStream).%New()
			set size = $system.IS.Receive()
			if size>0 {
				for  {
					set data = $system.IS.Receive()
					do stream.Write(data) set size = size-$l(data)
					quit:size<=0
				}
			}
			set returnValue = stream
			continue
		}
		if type="cstream" {
			set stream = ##class(%GlobalCharacterStream).%New()
			set size = $system.IS.Receive()
			if size>0 {
				for  {
					set data = $system.IS.Receive()
					do stream.Write(data) set size = size-$l(data)
					quit:size<=0
				}
			}
			set returnValue = stream
			continue
		}
		if (type="out") || (type="output") {
			set argnum = $system.IS.Receive()
			set subtype = $system.IS.Receive()
			if subtype="value" {
				set value = $system.IS.Receive()
				set args(argnum) = value
				continue
			}
			if subtype="object" {
				set value = $system.IS.Receive()
				set args(argnum) = $zobjref(value)
				continue
			}
			if (subtype="vlist") || (subtype="valuelist") {
				set length = $system.IS.Receive()
				set collection = ##class(%ListOfDataTypes).%New()
				for i=1:1:length do collection.Insert($system.IS.Receive())
				set args(argnum) = collection
				continue
			}
			if (subtype="olist")||(subtype="objectlist") {
				set length = $system.IS.Receive()
				set collection = ##class(%ListOfObjects).%New()
				for i=1:1:length do collection.Insert($zobjref($system.IS.Receive()))
				set args(argnum) = collection
				continue
			}
			if subtype="bstream" {
				set stream = ##class(%GlobalBinaryStream).%New()
				set size = $system.IS.Receive()
				if size>0 {
					for  {
						set data = $system.IS.Receive()
						do stream.Write(data) set size = size-$l(data)
						quit:size<=0
					}
				}
				set args(argnum) = stream
				continue
			}
			if subtype="cstream" {
				set stream = ##class(%GlobalCharacterStream).%New()
				set size = $system.IS.Receive()
				if size>0 {
					for  {
						set data = $system.IS.Receive()
						do stream.Write(data) set size = size-$l(data)
						quit:size<=0
					}
				}
				set args(argnum) = stream
				continue
			}
			; invalid subtype
			do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid return subtype token: %1",subtype))
		}
		; invalid type
		do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid return type token: %1",type))
	}
	return
}

Method %DispatchGetProperty(property As %String) As %ObjectHandle
{
	do $SYSTEM.Process.ThrowError(149)
}

Method %DispatchSetProperty(property As %String, value)
{
	do $SYSTEM.Process.ThrowError(149)
}

Method GatewayGet() As %Net.Remote.Gateway
{
	return ..%gateway
}

Method GatewaySet(value As %Net.Remote.Gateway) As %Status
{
	set ..%gateway = value
	return $$$OK
}

}
