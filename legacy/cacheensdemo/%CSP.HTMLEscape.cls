/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// HTML escape output to the current device
Class %CSP.HTMLEscape Extends %RegisteredObject
{

Method %OnNew() As %Status
{
	#; Retain the name of the redirection routine
	Set $system.Context.DeviceRedirect().Stack($increment($system.Context.DeviceRedirect().Stack))=$lb($zutil(82,12),$System.Device.GetMnemonicRoutine(),$classname())
	#; Set THIS routine for redirection
	Use $io::("^"_$ZNAME)
	#; Switch redirection on
	Do $zutil(82,12,1)
	RETURN $$$OK
}

Method %OnClose() As %Status
{
	Set stack=$system.Context.DeviceRedirect().Stack($system.Context.DeviceRedirect().Stack)
	Kill $system.Context.DeviceRedirect().Stack($i($system.Context.DeviceRedirect().Stack,-1)+1)
	Set $lg(redirect,routine)=stack
	Use $io::($select(routine="":"",1:"^"_routine))
	Do $zutil(82,12,redirect)
	RETURN $$$OK
}

ClassMethod Callback() [ ProcedureBlock = 0 ]
{
	RETURN
rstr(sz,to) [rt] public {
	New rt
	Set vr="rt"
	Set stack=$system.Context.DeviceRedirect().Stack($system.Context.DeviceRedirect().Stack)
	Set $lg(redirect,routine)=stack
	Use $io::($select(routine="":"",1:"^"_routine))
	Do $zutil(82,12,redirect)
	Try {
		Set:$data(sz) vr=vr_"#"_sz Set:$data(to) vr=vr_":"_to
		Read @vr
	} Catch err {
	}
	Use $io::("^"_$ZNAME)
	Do $zutil(82,12,1)
	Do:$data(to) $zutil(96,4,$t)
	If $isobject(err) Throw err
	Quit rt
}
wchr(s)	public { Do write($char(s)) }
wff() public { Do write($char(12)) }
wnl() public { Do write(,1) }
wstr(s) public { Do write(s) }
wtab(s) public { Do write($justify("",s-$x)) }
write(str,nl=0) {
	Set stack=$system.Context.DeviceRedirect().Stack($system.Context.DeviceRedirect().Stack)
	Set $lg(redirect,routine,class)=stack
	Use $io::($select(routine="":"",1:"^"_routine))
	Do $zutil(82,12,redirect)
	Try {
		If nl {
			Do $classmethod(class,"WriteNL")
		} Else {
			Do $classmethod(class,"Write",str)
		}
	} Catch err {}
	Use $io::("^"_$ZNAME)
	Do $zutil(82,12,1)
}
}

/// Ouput the escaped new line
ClassMethod WriteNL()
{
	Write !
}

/// Ouput to the escaped <var>str</var> value.
ClassMethod Write(str As %String)
{
	Write $zconvert(str,"O","HTML")
}

}
