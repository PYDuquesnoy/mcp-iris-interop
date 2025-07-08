/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %callout

/// <P> Transform COS source code to a parse tree
/// <P> Internal ISC code, not for customer use - these interfaces may change without warning
Class %Library.COSCallout Extends %RegisteredObject [ System = 4 ]
{

/// <P>The directory for CacheObjectScript.DLL.
/// <P>
/// <P>Defaults to the instance's "Bin" directory - change it if you want to debug a different version of the DLL.
Property BinDir As %String(TRUNCATE = 1);

/// <P> How we call the DLL
/// <P>
/// <P> Takes one of the following values :-
/// <P> 1 - use $ZF(-3)         ... handy for debugging the DLL because it doesn't stay loaded
/// <P> 2 - use $ZF(-4)/$ZF(-5) ... to cache the DLL handle
/// <P> 3 - use $ZF(-4)/$ZF(-6) ... the default - there's normally no reason to change it
/// <P>
/// <P>Initialised to 3
Property DLLCallMode As %Integer [ InitialExpression = 3 ];

/// <P> The cached DLLHandle (used only when DLLCallMode=2)
Property DLLHandle As %Integer [ InitialExpression = 0 ];

/// <P>Set to a result code string
/// <P>
/// <P>Mainly of use to Intersystems support.
Property DLLResultCode As %String(TRUNCATE = 1);

Method %OnClose() As %Status
{
	// bail out quietly if a Cache error occurs in this method
	Set $ZT="TRAP"

	// if we have a cached handle ..
	If ..DLLHandle'=0 {
	 
		// unload the DLL
		If $ZF(-4,2,..DLLHandle)
	}
TRAP
	Quit $$$OK
}

/// <P> Convert the given COS source code to a parse tree
/// <P>
/// <UL>
///  <LI><P> SourceStream is a stream containing the source code
///  <LI><P> ErrorsStream is a stream to which any error messages are written
/// </UL>
/// <P>
/// <P> The return value is 1 on success, 0 on failure
/// <P>
/// <P> If 0 is returned the caller should see the DLLResultCode property
///     for information about failure.
/// <P>
/// <P> CacheObjectScript.DLL must be in the directory given by the BinDir property.
///     By default this points to the instance's "Bin" directory.
/// <P> <HR>
/// <P> In the example below SourceIn and ErrorsOut are streams.
///     SourceIn supplies the source code and ErrorsOut receives any error messages.
/// <P>
/// <EXAMPLE>
/// Set TT=##class(%Library.COSCallout).%New()
/// Set Ret=TT.Compile(SourceIn,ErrorsOut)
/// If 'Ret Write "Fatal error: ",TT.DLLResultCode,! ZTrap
/// Do Errors.Rewind()
/// If 'Errors.AtEnd {
///   //... show Errors
/// }
/// Else {
///   //... use tree
/// }
/// </EXAMPLE>
Method Compile(SourceStream As %RawString, ErrorsStream As %RawString, ByRef ColoringErrors As %Boolean) As %Boolean
{
 // the ordinal of zfCompile in CacheObjectScript.DLL
#define zfCompileOrdinal 1

	#Dim IO,DLLPATH,Errors,ReturnedResult,ZFOK
	
 Set IO=$IO
 If ..BinDir="" {Do ..SetDefaultBinDir()}
 
 Set ..DLLResultCode="Calling zfCompile .."
 Set $ZTrap="CompileErr" 
 Set ReturnedResult=..InvokeDLL($$$zfCompileOrdinal,$Listbuild($this,+SourceStream,+ErrorsStream))
 Set $ZTrap=""
 
 // unpack returned result
 If $ListLength(ReturnedResult)>1 {
  Set ZFOK=$List(ReturnedResult,1)
  Set ColoringErrors=$List(ReturnedResult,2)
  Set ..DLLResultCode=$List(ReturnedResult,3)
 }
 Else {
  Set ZFOK=0
  Set ColoringErrors=0
  Set ..DLLResultCode="FAIL"
 }
     
 Use IO
 Quit ZFOK

CompileErr ;
 Set ..DLLResultCode="ERROR: "_$ZError
 Set $Ztrap="" 
 Use IO
 Quit 0
}

/// <P>Helper function to return the InterSystems IRIS configuration name.
Method ConfigName() As %String [ CodeMode = expression, Private ]
{
$Piece($Zutil(86),"*",2)
}

/// <P>Helper function to return the InterSystems IRIS configuration path.
Method ConfigPath() As %String [ CodeMode = expression, Private ]
{
$Piece($Zutil(86),"*")
}

/// <P> Invoke the CacheObjectScript DLL function (DLLFunction), passing DLLArgs.
/// <P> Returns what the $ZF call into the DLL returns, or something in the same format :-
/// <P> $LISTBUILD(ZFOK, $LISTBUILD(Lang1, Lang2, ...), ColoringErrors, DLLResultCode)
Method InvokeDLL(DLLFunction As %Integer, DLLArgs) As %List [ Private ]
{
	#Dim DLLPath,ret,failed
	
	Set DLLPath=..PathToDLL()
	
	If ..DLLCallMode=1 {
	
		// invoke the DLL
		Quit $ZF(-3,DLLPath,DLLFunction,DLLArgs)
	}
	
	ElseIf ..DLLCallMode=2 {
	
		// fetch the handle if necessary
		If ..DLLHandle=0 {
			Set ..DLLHandle = $ZF(-4,1,DLLPath)
		}
	
		// invoke the DLL
		Set ret = ..ZF5(..DLLHandle,DLLFunction,DLLArgs,.failed)  
		
		Quit $Select(failed:$LB(0,"",0,"ZF5 failed"),1:ret)
	}
	
	ElseIf ..DLLCallMode=3 {
	 
		// invoke the DLL
		Set ret = ..ZF6(DLLPath,DLLFunction,DLLArgs,.failed)
	
		Quit $Select(failed:$LB(0,"",0,"ZF6 failed"),1:ret)
	}
	
	Else {
		ZT "DLLMODE"
	}
}

/// <P> Sets failed to 1 if the $ZF(-5,..) call fails, otherwise sets it to 0 and returns the DLL return code
Method ZF5(handle As %Integer, DLLFunction As %Integer, DLLArgs, ByRef failed As %Boolean) As %String [ Private ]
{
 Set $ZTrap = "TRAPZF5"
 Set failed = 0
 Quit $ZF(-5,handle,DLLFunction,DLLArgs)
	
TRAPZF5 ; error trap for $ZF(-5,..) call
 Set failed = 1
 Quit ""
}

/// <P> Sets failed to 1 if the $ZF(-6,..) call fails, otherwise sets it to 0 and returns the DLL return code
Method ZF6(DLLPath As %String, DLLFunction As %Integer, DLLArgs, ByRef failed As %Boolean) As %String [ Private ]
{
 Set failed = 0

 // try calling the DLL assuming it's already loaded
 Set $ZTrap = "TRAPZF6a"	
 Quit $ZF(-6,$$$COSCalloutLibrary,DLLFunction,DLLArgs)
	
TRAPZF6a ; initial error trap for $ZF(-6,..) call

 // try again after loading the DLL into the process table
 Set $ZTrap = "TRAPZF6b"
 If $ZF(-4,7,$$$COSCalloutLibrary,DLLPath)
 Quit $ZF(-6,$$$COSCalloutLibrary,DLLFunction,DLLArgs)

TRAPZF6b
 Set failed = 1
 Quit ""
}

/// <P> Return the path to the DLL
ClassMethod PathToDLL() As %String
{
	#Dim dllname
	
	If $$$isWINDOWS,$System.Version.Is64Bits() {
		Set dllname="objectscript64"
	}
	Else {
		Set dllname="objectscript"
	}
	
	Quit $Get(^%SYS("bindir"))_dllname_$Select($$$isWINDOWS:".dll",$$$isUNIX:".so",$$$isVMS:".exe",1:".dll")
}

/// <P> Set the default for the instance's "Bin" directory
Method SetDefaultBinDir() [ Private ]
{
	#Dim configpath,pathsep
	
	If $Get(^%SYS("bindir"))'="" {
		Set ..BinDir=^%SYS("bindir")
	}
	Else {
		Set configpath=..ConfigPath()
		Set pathsep=$Select(configpath["/":"/",1:"\")
		Set ..BinDir=$Piece(configpath,pathsep,1,$Length(configpath,pathsep)-1)_pathsep_"bin"_pathsep
	}
}

}
