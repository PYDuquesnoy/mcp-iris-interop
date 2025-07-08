/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// For InterSystems internal use only, subject to change without notice
Class %Exception.CPPException Extends %SystemBase
{

Parameter %MODULENAME [ Internal ] = 1;

Parameter %MODULEGENERATIONOPTIONS [ Internal ] = 0;

/// Name is the name of the error
Property Name As %String(MAXLEN = "");

/// Code is the error code
Property Code As %String(MAXLEN = "");

/// Location is the location at which the error occurred
Property Location As %String(MAXLEN = "");

/// Data is extra information supplied for certain errors
Property Data As %String(MAXLEN = "");

/// This holds an Inner exception. It is typically set to the caught exception when creating a new exception
/// object in a catch block.
Property InnerException As %RawString;

/// iStack holds an internal representation of the execution stack at the time of the exception.
Property iStack As %String(MAXLEN = "") [ Internal ];

/// This returns a string that represents the exception. Users should feel free
/// to modify the format in subclasses
Method DisplayString(pLevel As %Integer = 0) As %String [ Language = cpp ]
{
}

Method BinDisplayString(pLevel As %Integer = 0) As %Binary [ Internal, Language = cpp ]
{
}

}
