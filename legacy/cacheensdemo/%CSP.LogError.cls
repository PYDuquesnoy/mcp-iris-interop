/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Log the error that has occured but do not display any information to the user about this error.
Class %CSP.LogError Extends %CSP.Error [ System = 3 ]
{

/// If an error occurs while processing a HyperEvent then this method is called.
/// Log error and send simple response.
ClassMethod HyperEventError()
{
	Set message=..ErrString()
	Set $ztrap="LogMe"
	Set $ECode=message
LogMe	Set $ZError=$$$GetSimpleMessage("%CSP","ErrorZE")
	Do BACK^%ETN
	Write "alert('",$$$GetSimpleMessage("%CSP","Error"),"');",!
	Quit
}

/// Create message for logging CSP error.
ClassMethod ErrString() [ Internal ]
{
	Do ..DecomposeError(%request.Get("Error:ErrorCode"),.ErrorInfo)
	Set message=""
	For i=1:1:ErrorInfo {
		Set message=message_ErrorInfo(i,"Desc")_$char(13,10)
		If ErrorInfo(i,"ErrorNo")=$$$ERRORCODE($$$FailedToCreateClass) {
			Set j=$O(ErrorInfo(i,"Error",j))
			While (j'="") {
				Set message=message_"    * Routine: "_ErrorInfo(i,"Error",j,"Routine")_$char(13,10)
				Set message=message_"      Offset: "_ErrorInfo(i,"Error",j,"Offset")_$char(13,10)
				Set message=message_"      Error: "_ErrorInfo(i,"Error",j,"Error")_$char(13,10)
				Set message=message_"      Description: "_ErrorInfo(i,"Error",j,"Desc")_$char(13,10)
				Set message=message_"      Line: "_ErrorInfo(i,"Error",j,"Line")_$char(13,10)
				Set j=$O(ErrorInfo(i,"Error",j))
			}
		} else {
			Set message=message_"    Error: "_ErrorInfo(i,"Error")_$char(13,10)
		}
		Set message=message_"    ErrorNo: "_ErrorInfo(i,"ErrorNo")_$char(13,10)
		Set message=message_"    CSP Page: "_ErrorInfo(i,"URL")_$char(13,10)
		Set message=message_"    Namespace: "_ErrorInfo(i,"Namespace")_$char(13,10)
		Set message=message_"    Class: "_ErrorInfo(i,"Class")_$char(13,10)
		If $G(ErrorInfo(i,"Routine"))'="" {
			Set message=message_"    Routine: "_ErrorInfo(i,"Routine")_$char(13,10)
			Set message=message_"    Location: "_ErrorInfo(i,"Location")_$char(13,10)
			If $G(ErrorInfo(i,"Line"))'="" Set message=message_"    Line: "_ErrorInfo(i,"Line")_$char(13,10)
		}
	}
	Quit message
}

/// Output the error page as HTML.
/// Log error and send simple response.
ClassMethod OnPage() As %Status
{
	Set message=..ErrString()
	Set $ztrap="LogMe"
	Set $ECode=message
LogMe	Set $ZError=$$$GetSimpleMessage("%CSP","ErrorZE")
	Do BACK^%ETN
	Set msg=$$$GetSimpleMessage("%CSP","Error")
	&html<<html><head><title>Error</title></head>
	<body>
	#(msg)#
	</body>
	</html>>
	Quit $$$OK
}

}
