/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%Exception.AbstractException</class> defines the interface to exceptions
/// that may be caught and thrown via the Try/Catch exception handling facilities. Users wishing
/// to define new exception classes should inherit from this interface class. Only instances of classes
/// that inherit from %Exception.AbstractException may be thrown with the 'throw' command.
Class %Exception.AbstractException Extends %Exception.CPPException [ Abstract ]
{

Method %OnNew(pName As %String = "", pCode As %String = "", pLocation As %String = "", pData As %String = "", pInnerException As %Exception.AbstractException = {$$$NULLOREF}) As %Status [ Private ]
{
	Set i%Name=pName,i%Code=pCode,i%Location=pLocation,i%Data=pData,i%InnerException=pInnerException
	Set i%iStack=$LI($ZU(41,-2),2,*)
	Quit $$$OK
}

/// This outputs the string representation of the exception to the current device, recursively
/// outputing any inner exceptions. 
Method OutputToDevice(pLevel As %Integer = 0) [ ServerOnly = 1 ]
{
	Set tStream = ##class(%GlobalCharacterStream).%New()
	Do ..OutputToStream(tStream,pLevel)
	Do tStream.OutputToDevice()
}

/// This outputs the string representation of the exception to the supplied stream, recursively
/// outputting any inner exceptions.
Method OutputToStream(pStream As %CharacterStream, pLevel As %Integer = 0)
{
	Do pStream.WriteLine(..DisplayString(pLevel))
	If $IsObject(..InnerException) Do ..InnerException.OutputToStream(pStream,pLevel+1)
}

/// This returns a string that represents the exception. Users should feel free
/// to modify the format in subclasses.
Method DisplayString(pLevel As %Integer = 0) As %String
{
	Quit $Justify("",pLevel)_..Name_" "_..Code_" "_..Location_" "_..Data
}

Method BinDisplayString(pLevel As %Integer = 0) As %Binary [ Internal ]
{
	Quit ..DisplayString(pLevel)
}

/// This returns a string that represents the SQL %msg string. Users should feel free
/// to modify the format and content in subclasses.<br>
/// DEPRECATED - use AsSQLMessage() instead. Override OnAsSQLMessage() to customize the value returned
/// by AsSQLMessage().
Method SQLMessageString(pLevel As %Integer = 0) [ Deprecated ]
{
	Quit $Justify("",pLevel)_..Name_" "_..Code_" "_..Location_" "_..Data
}

/// Convert this exception to a %Status compatible value.
Method AsStatus() As %Status [ Final ]
{
	Set tSC = ..OnAsStatus()
	
	#; Append any inner error codes
	Set tmp=$this
	While $isobject(tmp.InnerException) {
		Set tmp=tmp.InnerException
		Set tSC=$$EmbedStatus^%apiOBJ(tSC,tmp.OnAsStatus(),0)
	}
	
	Quit tSC
}

/// Override this method to provide a custom conversion of an exception to a status.
Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(..Code,..Data,,,,,,,,,..Location)
}

/// Return the SQLCODE value corresponding to the exception.
Method AsSQLCODE() As %Integer [ Final ]
{
	Set tSQLCODE = ..OnAsSQLCODE()	
	Quit tSQLCODE
}

/// Override this method to provide a custom conversion of an exception to an SQLCODE value.
Method OnAsSQLCODE() As %Integer [ CodeMode = expression, Private ]
{
-400
}

/// Return the SQL %msg string describing details of the exception.
Method AsSQLMessage() As %String(MAXLEN="") [ Final ]
{
	quit ..OnAsSQLMessage()
}

/// Override this method to provide a custom conversion of an exception to the SQL %msg string.
Method OnAsSQLMessage() As %String(MAXLEN="") [ CodeMode = expression, Private ]
{
..Data
}

/// Call the log function (LOG^%ETN) to log this exception.
/// You can view this log at the terminal with 'Do ^%ER' utility or from the system management portal.
Method Log() As %Status
{
	try {
		do LOG^%ETN(..DisplayString())
		set sc=$$$OK
	} catch err {
		set sc=err.AsStatus()
	}
	quit sc
}

/// This method sets an array that is passed by reference to the execution stack at the time of the exception.
/// The top unsubscripted value is the number of execution levels.<br><br>
/// array(n) is a string that indicates how the next
/// level was created. It is empty for the current level. The value may be:<br>
/// DO - issued a DO command<br>
/// $$ - called an extrinsic function<br>
/// XECUTE - issued an XECUTE command<br>
/// BREAK - entered a debug prompt because of a &LT;BREAK><br>
/// ERROR - entered a debug prompt because of an error<br>
/// $ETRAP - executed a $ETRAP<br>
/// CALLIN - entered via a callin<br><br>
/// array(n,"PLACE") is the location of the last command executed at this level. It is a line reference followed
/// by the command number on that line.
Method StackAsArray(ByRef array) As %Status
{
	Kill array
	Set (n,array)=$LL(i%iStack),ptr=0,res=""
	While $LISTNEXT(i%iStack,ptr,level) {
		Set array(n)=$P("?,,DO,$$,XECUTE,BREAK,ERROR,$ETRAP,CALLIN",",",$F("dexBETC",$P(level,"^",1))+1)
		Set where=$P(level,"^",2,3) Set:where="^" where=""
		Set array(n,"PLACE")=where_" "_$P(level,"^",4)
		Set n=n-1
	}
	Quit $$$OK
}

}
