/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the error page that is called if an error occurs when generating the XML
/// template code. It will output the error information as a template, so this will
/// be pasted into the current document in Studio. If you wish to write your own
/// error page just inherit from this page. Then in the final template page set the
/// ERRORPAGE parameter to your new error page.
Class %CSP.StudioTemplateError Extends (%CSP.StudioTemplateInsert, %CSP.Error) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

/// Create the template with the error information in it.
ClassMethod OnPage() As %Status
{
 Write "<TemplateError>",!
 New ErrorInfo
 Do ..DecomposeError(%request.Get("Error:ErrorCode"),.ErrorInfo)
 New i
 For i=1:1:ErrorInfo Do
 . Write ErrorInfo(i,"Desc"),!
 . If ErrorInfo(i,"ErrorNo")=$$$ERRORCODE($$$FailedToCreateClass) Do
 . . Write "Compile Errors:",!
 . . New j
 . . Set j="" For  Set j=$O(ErrorInfo(i,"Error",j)) Quit:j=""  Do
 . . . Write "   Routine: ",ErrorInfo(i,"Error",j,"Routine")
 . . . Write " Offset: ",ErrorInfo(i,"Error",j,"Offset"),!
 . . . Write "   Error: ",ErrorInfo(i,"Error",j,"Error"),!
 . . . Write "   Description: ",ErrorInfo(i,"Error",j,"Desc"),!
 . . . Write "   Line: ",ErrorInfo(i,"Error",j,"Line"),!
 . . Write !
 . Else  Do
 . . Write "   Error: ",ErrorInfo(i,"Error"),!
 . Write "   ErrorNo: ",ErrorInfo(i,"ErrorNo"),!
 . Write "   CSP Page: ",ErrorInfo(i,"URL"),!
 . Write "   Namespace: ",ErrorInfo(i,"Namespace"),!
 . Write "   Class: ",ErrorInfo(i,"Class"),!
 . If $G(ErrorInfo(i,"Routine"))'="" Do
 . . Write "   Routine: ",ErrorInfo(i,"Routine"),!
 . . Write "   Location: ",ErrorInfo(i,"Location"),!
 . . If $G(ErrorInfo(i,"Line"))'="" Write "   Line: ",ErrorInfo(i,"Line"),!
 . Write "</TemplateError>",!

 Quit $$$OK
}

}
