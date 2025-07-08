/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// Helper routine which supports the MERGE command "Execute".
Class %SYS.Execute Extends (%Library.RegisteredObject, %SYSTEM.Help) [ Final, Inheritance = right, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Parameter SOURCECONTROL [ Internal ] = {"Revision path: $Id: //iris/latest/databases/sys/cls/Config/CPF.xml#118 $"_$c(13,10)_"Last Change:   $DateTime: 2023/05/12 18:32:41 $"_$c(13,10)_"Changelist #:  $Change: 6004472 $"_$c(13,10)_"Checked in by: $Author: slubars $"};

/// Class name
Property ClassName As %String;

/// Class method name
Property MethodName As %String;

/// Routine name to execute. One of the following formats:<br>
/// 1) ^RTNNAME<br>
/// 2) TAG^RTNNAME<br>
/// 3) $$TAG^RTNNAME<br>
Property RoutineName As %String;

/// Namespace to execute the class or routine in.
Property Namespace As %String [ Required ];

/// Arguments to the Classmethod or routine. Up to 20 parameters may be passed.
Property Arg1 As %String(MAXLEN = 1024);

Property Arg2 As %String(MAXLEN = 1024);

Property Arg3 As %String(MAXLEN = 1024);

Property Arg4 As %String(MAXLEN = 1024);

Property Arg5 As %String(MAXLEN = 1024);

Property Arg6 As %String(MAXLEN = 1024);

Property Arg7 As %String(MAXLEN = 1024);

Property Arg8 As %String(MAXLEN = 1024);

Property Arg9 As %String(MAXLEN = 1024);

Property Arg10 As %String(MAXLEN = 1024);

Property Arg11 As %String(MAXLEN = 1024);

Property Arg12 As %String(MAXLEN = 1024);

Property Arg13 As %String(MAXLEN = 1024);

Property Arg14 As %String(MAXLEN = 1024);

Property Arg15 As %String(MAXLEN = 1024);

Property Arg16 As %String(MAXLEN = 1024);

Property Arg17 As %String(MAXLEN = 1024);

Property Arg18 As %String(MAXLEN = 1024);

Property Arg19 As %String(MAXLEN = 1024);

Property Arg20 As %String(MAXLEN = 1024);

ClassMethod Execute(Properties As %String) As %Status [ Internal ]
{
 s $zt="Error"
 n %Status
 s %Status=$$$OK
 i $d(Properties("ClassName")) {
	s X="s %Status=$classmethod("""_Properties("ClassName")_""","""_Properties("MethodName")_""""
	f i=1:1:20 { 
		i $d(Properties("Arg"_i)) {
			s X=X_","_""""_Properties("Arg"_i)_""""
		} else {
			q
		}
 	}
	s X=X_")"
 } else {
	i (Properties("RoutineName")["^"),$e(Properties("RoutineName"),1)'="^" {
		s X=Properties("RoutineName")
	} else {
		i $e(Properties("RoutineName"),1)'="^" {
			s X="^"_Properties("RoutineName")
		} else {
			s X=Properties("RoutineName")
		}
	}
	i $e(Properties("RoutineName"),1,2)="$$" {
		s X="s %Status="_X
		i '$d(Properties("Arg1")) s X=X_"()"
	} else {
		s X="s %Status=1 d "_X
	}
	i $d(Properties("Arg1")) {
		s X=X_"("
		f i=1:1:20 { 
			i $d(Properties("Arg"_i)) {
				s X=X_""""_Properties("Arg"_i)_""""_","
			} else {
				q
			}
	 	}
	 	i $e(X,*)="," s X=$e(X,1,*-1)
		s X=X_")"
	}
 }
 n $namespace
 zn Properties("Namespace")
 Try {
	 X X
 } catch {
	 i ($ze["<COMMAND>")&&(($ze[$zcvt($g(Properties("ClassName"),"----"),"U"))) {
		 s %Status=$$$OK
	 } else {
		 s %Status=$$$ADDSC($$$ERROR($$$MGActionXecuteError,X),$$$ERROR($$$ObjectScriptError,$ze))
	 }
 }
 q %Status	 
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q Status
}

}
