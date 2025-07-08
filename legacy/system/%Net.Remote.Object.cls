/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occErrors, %syskio, %SYS.DBSRV)

Class %Net.Remote.Object Extends %RegisteredObject [ System = 3 ]
{

Property %gateway As %Net.Remote.Gateway;

Method %OnNew(gateway As %Net.Remote.Gateway, args...) As %Status
{
	if $IsObject($g(gateway))=0 return $$$OK
	; args(1) is classname
	return ..%Constructor(gateway,args...)
}

Method %Constructor(gateway As %Net.Remote.Gateway, className As %String, args...) As %Status
{
	try {
		set ..%gateway = gateway
		;
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(..%gateway,.closedOREFs)
		;
		set args = +$g(args)
		if gateway.ProtocolVersion<58 {
			for i=1:1:args if $isObject($g(args(i))) set args(i) = args(i)_""
		} else {
			for i=1:1:args if $isObject($g(args(i))) do ..%gateway.%RetainObject(args(i),..%gateway)
		}
		set (sequenceNumber,..%gateway.SequenceNumber) = ..%gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YA",.closedOREFs,$this_"",className,args,args...)
		do ..%GetResponse(..%gateway,sequenceNumber,"YA",currentDevice,.orefCache)
		;
		if gateway.ProtocolVersion>=61 {
			do ..%ProcessReturnValues(gateway,currentDevice,,args...)
		}
		;
		do ..%PostInvoke(..%gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return $$$OK
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

Method %CastAs(classname As %String) As %Net.Remote.Object
{
	set neworef = ..%New()
	set success = ..%gateway.%CallUtilityMethod("castAs",$this,classname,neworef_"")
	if success {
		set neworef.%gateway = ..%gateway
		return neworef
	} else {
		return $$$NULLOREF
	}
}

Method %DispatchMethod(method As %String, args...) As %ObjectHandle
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(..%gateway,.closedOREFs)
		;
		set args = +$g(args)
		if ..%gateway.ProtocolVersion<58 {
			for i=1:1:args if $isObject($g(args(i))) set args(i) = args(i)_""
		} else {
			for i=1:1:args if $isObject($g(args(i))) do ..%gateway.%RetainObject(args(i),..%gateway)
		}
		set (sequenceNumber,..%gateway.SequenceNumber) = ..%gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YU",.closedOREFs,$this_"",method,args,args...)
		do ..%GetResponse(..%gateway,sequenceNumber,"YU",currentDevice,.orefCache)
		;
		if ..%gateway.ProtocolVersion>=61 {
			do ..%ProcessReturnValues(..%gateway,currentDevice,.returnValue,args...)
		} else {
			set type = $system.IS.Receive()
			if $zb'=$c(0) {
				set returnValue = $system.IS.Receive()
				set returnValue = $s(type="object":$zobjref(returnValue),1:returnValue)
			}
		}
		;
		do ..%PostInvoke(..%gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return:$d(returnValue) returnValue
		return
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

ClassMethod %ClassMethod(gateway As %Net.Remote.Gateway, className As %String, methodName As %String, args...) As %ObjectHandle
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(gateway,.closedOREFs)
		;
		set args = +$g(args)
		if gateway.ProtocolVersion<58 {
			for i=1:1:args if $isObject($g(args(i))) set args(i) = args(i)_""
		} else {
			for i=1:1:args if $isObject($g(args(i))) do gateway.%RetainObject(args(i),gateway)
		}
		set (sequenceNumber,gateway.SequenceNumber) = gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YU",.closedOREFs,className,methodName,args,args...)
		do ..%GetResponse(gateway,sequenceNumber,"YU",currentDevice,.orefCache)
		;
		if gateway.ProtocolVersion>=61 {
			do ..%ProcessReturnValues(gateway,currentDevice,.returnValue,args...)
		} else {
			set type = $system.IS.Receive()
			if $zb'=$c(0) {
				set returnValue = $system.IS.Receive()
				set returnValue = $s(type="object":$zobjref(returnValue),1:returnValue)
			}
		}
		;
		do ..%PostInvoke(gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return:$d(returnValue) returnValue
		return
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

Method %DispatchGetProperty(property As %String) As %ObjectHandle
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(..%gateway,.closedOREFs)
		;
		set (sequenceNumber,..%gateway.SequenceNumber) = ..%gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YV",.closedOREFs,$this_"",property)
		do ..%GetResponse(..%gateway,sequenceNumber,"YV",currentDevice,.orefCache)
		;
		set type = $system.IS.Receive()
		set value = $system.IS.Receive()
		set value = $s(type="object":$zobjref(value),1:value)
		;
		do ..%PostInvoke(..%gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return value
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

Method %DispatchSetProperty(property As %String, value)
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(..%gateway,.closedOREFs)
		;
		if ..%gateway.ProtocolVersion<58 {
			if $isObject(value) set value = value_""
		} else {
			if $isObject(value) do ..%gateway.%RetainObject(value,..%gateway)
		}
		set (sequenceNumber,..%gateway.SequenceNumber) = ..%gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YB",.closedOREFs,$this_"",property,value)
		do ..%GetResponse(..%gateway,sequenceNumber,"YB",currentDevice,.orefCache)
		;
		do ..%PostInvoke(..%gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

ClassMethod %GetStaticProperty(gateway As %Net.Remote.Gateway, className As %String, propertyName As %String) As %ObjectHandle
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(gateway,.closedOREFs)
		;
		set (sequenceNumber,gateway.SequenceNumber) = gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YV",.closedOREFs,className,propertyName)
		do ..%GetResponse(gateway,sequenceNumber,"YV",currentDevice,.orefCache)
		;
		set type = $system.IS.Receive()
		set value = $system.IS.Receive()
		set value = $s(type="object":$zobjref(value),1:value)
		;
		do ..%PostInvoke(gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return value
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

ClassMethod %SetStaticProperty(gateway As %Net.Remote.Gateway, className As %String, propertyName As %String, value As %ObjectHandle)
{
	try {
		set currentDevice = $io
		set ^||%gatewayDevice = $g(^||%gatewayDevice)+1
		set ^||%gatewayDevice(^||%gatewayDevice) = currentDevice
		do ..%PreInvoke(gateway,.closedOREFs)
		;
		if gateway.ProtocolVersion<58 {
			if $isObject(value) set value = value_""
		} else {
			if $isObject(value) do gateway.%RetainObject(value,gateway)
		}
		set (sequenceNumber,gateway.SequenceNumber) = gateway.SequenceNumber+2
		do $system.OS.SendRequest(sequenceNumber,"","YB",.closedOREFs,className,propertyName,value)
		do ..%GetResponse(gateway,sequenceNumber,"YB",currentDevice,.orefCache)
		;
		do ..%PostInvoke(gateway,currentDevice)
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		;
		return
		;
	} catch ex {
		use currentDevice
		kill ^||%gatewayDevice(+$g(^||%gatewayDevice))
		set ^||%gatewayDevice = ^||%gatewayDevice-1
		throw ex
	}
}

ClassMethod %ProcessReturnValues(gateway, currentDevice, returnValue, args...)
{
	for  {
		set type = $system.IS.Receive()
		;
		if type="end" quit
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
		if type="vlist" {
			set length = $system.IS.Receive()
			set collection = ##class(%ListOfDataTypes).%New()
			for i=1:1:length do collection.Insert($system.IS.Receive())
			set returnValue = collection
			continue
		}
		if type="olist" {
			set length = $system.IS.Receive()
			set collection = ##class(%ListOfObjects).%New()
			for i=1:1:length do collection.Insert($zobjref($system.IS.Receive()))
			set returnValue = collection
			continue
		}
		if type="mlist" {
			set length = $system.IS.Receive()
			set collection = ##class(%ListOfDataTypes).%New()
			for i=1:1:length {
				set etype = $system.IS.Receive()
				if etype="obj" {
					do collection.Insert($zobjref($system.IS.Receive()))
				} else {
					do collection.Insert($system.IS.Receive())
				}
			}
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
		if type="out" {
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
			; invalid subtype
			do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid return subtype token: ",subtype))
		}
		; invalid type
		do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid return type token: ",type))
	}
	return
}

ClassMethod %GetResponse(gateway As %Net.Remote.Gateway, sequenceNumber As %Integer, functionCode As %String, currentDevice As %String, ByRef orefCache)
{
	set doread = 1
	for  {
		; read from wire
		if doread set returnCode = $system.IS.ReceiveHeader(-1)
		set msgid = $li(returnCode,2)
		set context = $li(returnCode,3)
		set fun = $li(returnCode,4)
		set doread = 1
		if $li(returnCode,1)=0 set fun=$zwc(fun+$$$RCBASE)
		if $li(returnCode,1)=1 set fun=$zwc(fun+$$$OCBASE)
		; messageCount is odd for all messages initiated from Java
		if msgid#2=1 {
			if fun="Y9" {
				do ..%ProcessY9(gateway,msgid,.orefCache)
				continue
			} if fun="YG" {
				do ..%ProcessYG(gateway,msgid)
				continue
			} if fun="YH" {
				do ..%ProcessYH(gateway,msgid)
				continue
			} else {
				; push gateway context stack
				do $system.Context.Gateway().push(gateway)
				; dispatch to system to handle
				do $system.IS.SetApplicationDevice(currentDevice)
				set returnCode = ..%DispatchNativeCall(gateway.GatewayDevice,msgid,context,fun)
				; pop gateway context stack
				do $system.Context.Gateway().pop()
				; $system.IS.Execute returns 0, single opcode executed		
				if returnCode=0 continue
				; $system.IS.Execute returns -1, STOP code received
				if returnCode=-1 continue
				set type = $li(returnCode,1)
				if type'=2 do ..%ProcessError(gateway,currentDevice,$$$FormatText("Reentrancy execution error, return value %1",type))
				set doread = 0
				continue
			}
		}
		if (msgid=0)&&(fun="DC") {
			do ..%ProcessError(gateway,currentDevice,$$$FormatText("Connection closed by External Language Server"))
		} elseif msgid'=sequenceNumber {
			do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid message sequence number, expecting %1, received %2",sequenceNumber,msgid))
		} elseif fun=functionCode {
			quit
		} elseif fun="Y5" {
			do ..%ProcessError(gateway,currentDevice)
		} elseif fun="Y9" {
			do ..%ProcessY9(gateway,msgid,.orefCache)
			continue
		} else {
			do ..%ProcessError(gateway,currentDevice,$$$FormatText("Invalid function code, expecting %1, received %2",functionCode,fun))
		}
	}
	return
}

ClassMethod %ProcessY9(gateway, msgid, orefCache) As %String
{
	try {
		if gateway="" set gateway = ##class(%Net.Remote.Gateway).%GetContextGateway()
		set count = $system.IS.Receive()
		set classname = $system.IS.Receive()
		for i=1:1:count {
			// We cannot use an OREF that is currently pending release in ..ClosedProxies
			for attempt=1:1 {
				set oref(attempt) = $classmethod(classname,"%New")
				if $d(gateway.ClosedProxies(oref(attempt)_"")) continue
				set oref = oref(attempt)
				quit
			}
			set oref.%gateway = gateway
			set orefCache(oref_"") = oref
			if gateway.ProtocolVersion<58 {
				set oref = oref_""
			} else {
				do gateway.%RetainObject(oref,gateway)
			}
			set callargs(i) = oref
		}
		do $system.OS.SendRequest(msgid,"","Y9",.callargs)
	} catch e {
		do $system.OS.SendRequest(msgid,"","Y9","error",$ze)
	}
}

ClassMethod %ProcessYG(gateway, msgid) As %String
{
	try {
		set orefstring = $system.IS.Receive()
		set oref = $zobjref(orefstring)
		set callargs = oref.Count()
		for i=1:1:callargs {
			set callargs(i) = oref.GetAt(i)
			if $isObject(callargs(i)) do gateway.%RetainObject(callargs(i),gateway)
		}
		do $system.OS.SendRequest(msgid,"","YG","",.callargs)
	} catch e {
		do $system.OS.SendRequest(msgid,"","YG","error",$ze)
	}
}

ClassMethod %ProcessYH(gateway, msgid) As %String
{
	try {
		set orefstring = $system.IS.Receive()
		set oref = $zobjref(orefstring)
		do oref.Rewind()
		set size = oref.Size
		set chunksize = 3000000
		for  {
			set len = chunksize
			set data($i(counter)) = oref.Read(.len)
			quit:len<chunksize
		}
		do $system.OS.SendRequest(msgid,"","YH","",size,.data)
	} catch e {
		do $system.OS.SendRequest(msgid,"","YH","error",$ze)
	}
}

ClassMethod %DispatchNativeCall(device, msgid, context, fun) As %String
{
	set funcode = $sconvert(fun,"U2",0)
	#; do $System.OS.StartLog(7) // uncomment to perform SYSIO logging
	if $$$SYSIOFunction(funcode) {
		return $system.IS.Execute(1,msgid,context,funcode,-1)
	} else {
		return ##class(%SYS.DBSRV).GWExecuteSingle(msgid_"@"_device,context_"@"_device,fun)
	}
}

Method %OnClose() As %Status
{
	if ($isobject(..%gateway)=1) {
		if $g(..%gateway.ClosedProxies)>100 {
			// trigger a flush of ..%gateway.ClosedProxies
			set language = ..%gateway.ExternalLanguage
		}
		set ..%gateway.ClosedProxies($this_"") = ""
		set ..%gateway.ClosedProxies = $g(..%gateway.ClosedProxies)+1
	}
	return $$$OK
}

ClassMethod %PreInvoke(gateway As %Net.Remote.Gateway, parameters) [ Final ]
{
	use gateway.GatewayDevice
	set parameters = 0
	; set an unused node to force pass-by-value behavior in $system.OS.SendRequest
	set parameters(0) = ""
	if $d(gateway.ClosedProxies) {
		set oref = "" for  {
			set oref = $o(gateway.ClosedProxies(oref)) quit:oref=""
			set parameters = parameters+1
			set parameters(parameters) = oref
		}
		kill gateway.ClosedProxies
	}
	return
}

ClassMethod %PostInvoke(gateway As %Net.Remote.Gateway, device) [ Final ]
{
	if 'gateway.DisableOutputRedirect {
		set out = $system.IS.Receive() if $zb=$c(0) kill out
		set err = $system.IS.Receive() if $zb=$c(0) kill err
		if $d(out)||$d(err) {
			use $principal
			if ##class(%Device).GetType()=1 {
				write:$d(out) out
				write:$d(err) err
			}
		}
    	use device
	} else {
 	   use device
	}
	return
}

ClassMethod %ProcessError(gateway As %Net.Remote.Gateway, currentDevice As %String, error As %String) [ Final ]
{
	if $d(error) {
		; if error text is set, then it's a non-Y5 error, which is catastrophic, we close the device
		close gateway.GatewayDevice
		set gateway.Closed=1
		;
		throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$RemoteGatewayError,error))
	} else {
		set rawData = $system.IS.Receive()
		use currentDevice
		;
		set trimmedData = $tr(rawData,$c(9,13)," ")
		set errorLine = $p(trimmedData,$c(10),1)
		set remoteLanguage = ""
		;
		if $p(errorLine," ",1)="com.intersystems.gateway.IRISRemoteException:" {
			set remoteLanguage = "java"
			set errorLine = $p(errorLine," ",2,*)
			if ($e(errorLine,1,31)="<THROW> *%Net.Remote.Exception ") {
				set remoteError = $p(errorLine," ",4)
				set location = $tr($p(errorLine," ",5),$c(160)," ")
				set data = $p(errorLine," ",6,*)
			} else {
				set head = $p(errorLine," ",1)
				set find = $find(head,">")
				set remoteError = $e(head,1,find-1)
				set location = $e(head,find,*)
				set data = $p(errorLine," ",2,*)
			}
		} elseif $p(errorLine," ",1)="InterSystems.Data.IRISClient.Gateway.IRISRemoteException" {
			set remoteLanguage = "dotnet"
			set errorLine = $p(errorLine," ",3,*)
			if ($e(errorLine,1,31)="<THROW> *%Net.Remote.Exception ") {
				set remoteError = $p(errorLine," ",4)
				set location = $tr($p(errorLine," ",5),$c(160)," ")
				set data = $p(errorLine," ",6,*)
			} else {
				set head = $p(errorLine," ",1)
				set find = $find(head,">")
				set remoteError = $e(head,1,find-1)
				set location = $e(head,find,*)
				set data = $p(errorLine," ",2,*)
			}
		} else {
			set remoteError = $p(errorLine,":",1)
			set remoteError = $zstrip($zstrip($tr(remoteError,$c(9)," "),"*c"),"<=>w")
			set data = $p(errorLine,":",2,*)
			set data = $zstrip($zstrip($tr(data,$c(9)," "),"*c"),"<=>w")
			; location for Java and .NET is on line 2, starts with "at"
			; location for Python is on line 3, starts with "File"
			set location = ""
			set line2 = $zstrip($zstrip($tr($p(trimmedData,$c(10),2),$c(9)," "),"*c"),"<=>w")
			if $e(line2,1,3)="at " {
				set location = $e(line2,4,*)
			} else {
				set line3 = $zstrip($zstrip($tr($p(trimmedData,$c(10),3),$c(9)," "),"*c"),"<=>w")
				if $e(line3,1,5)="File " set location = line3
			}
		}
		;
		set precedingStack = ""
		set remoteStack = ""
		set localStack = $zu(41,-2)
		;
		set isPrecedingStack = 0
		for i=2:1:$l(trimmedData,$c(10)) {
			set line = $zstrip($zstrip($tr($p(trimmedData,$c(10),i),$c(9)," "),"*c"),"<=>w")
			if line="" continue
			if line="--- Beginning of preceding stack trace ---" set isPrecedingStack = 1 continue
			if $e(line,1,3)="at " set line = $e(line,4,*)
			if isPrecedingStack {
				set precedingStack = precedingStack_$lb(line)
			} else {
				set remoteStack = remoteStack_$lb(line)
			}
		}
		;
		set iStack = ..%mergeStack(precedingStack,remoteStack,localStack,remoteLanguage)
		;
		set exception = ##class(%Net.Remote.Exception).%New()
		set exception.RawData = rawData
		set exception.Name = "<GATEWAY>"
		set exception.Code = $$$GatewayException
		set exception.RemoteError = remoteError
		set exception.Location = location
		set exception.Data = data
		set exception.iStack = iStack
		throw exception
	}
}

ClassMethod %mergeStack(precedingStack, remoteStack, localStack, remoteLanguage) As %String
{
	if '$g(^%SYS("Gateway","Remote","ShowCompleteStack")) {
		set precedingStack = ..%cullStack(precedingStack)
		set remoteStack = ..%cullStack(remoteStack)
		set localStack = ..%cullStack(localStack)
	}
	;
	for i=0:1:$ll(localStack) quit:$lg(precedingStack,*-i)'=$lg(localStack,*-i)
	set precedingStack = $li(precedingStack,1,*-i)
	;
	if remoteLanguage="java" {
		set last = $li(remoteStack,*)
		set found = 0
		for i=$ll(precedingStack):-1:1 if $li(precedingStack,i)=last set found = i quit
		if found {
			for i=1:1:$ll(remoteStack) quit:$lg(precedingStack,found-i)'=$lg(remoteStack,*-i)
			set $li(precedingStack,found-i+1,found) = ""
		}
	}
	;
	return precedingStack_remoteStack_localStack
}

ClassMethod %cullStack(inStack) As %String
{
	set outStack = ""
	for i=1:1:$ll(inStack) set outStack = outStack_..%cullStackOne($li(inStack,i))
	quit outStack
}

ClassMethod %cullStackOne(line) As %String
{
	set head(1) = "d^%GetResponse"
	set head(2) = "e^%GetResponse"
	set head(3) = "^%ProcessError"
	set head(4) = "x^%DispatchNativeCall"
	set head(5) = "sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)"
	set head(6) = "sun.reflect.NativeMethodAccessorImpl.invoke0"
	set head(7) = "sun.reflect.NativeMethodAccessorImpl.invoke"
	set head(8) = "sun.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)"
	set head(9) = "java.lang.reflect.Method.invoke(Unknown Source)"
	set head(10) = "com.intersystems.gateway.JavaGateway.processMessage"
	set head(11) = "com.intersystems.gateway.JavaGateway.run"
	set head(12) = "com.intersystems.gateway.JavaGateway.run"
	set head(13) = "com.intersystems.gateway.GatewayInStream.readHeaderSYSIO"
	set head(14) = "com.intersystems.jdbc.InStream.readHeaderSYSIO"
	set head(15) = "com.intersystems.jdbc.IRIS.genericClassMethod"
	set head(16) = "InterSystems.Data.IRISClient.Gateway.GatewayInStream.readHeaderSYSIO"
	set head(17) = "InterSystems.Data.IRISClient.ADO.IRIS.GenericClassMethod"
	set head=17
	;
	set toHide=0 for i=1:1:head if $e(line,1,$l(head(i)))=head(i) set toHide=1 quit
	return $s(toHide:"",1:$lb(line))
}

}
