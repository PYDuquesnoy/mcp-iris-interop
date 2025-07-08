/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class allows a report server to validate a token provided by IRIS
Class %Report.AuthExternalUser Extends %RegisteredObject [ Language = objectscript ]
{

/// For external use, enables report server to authenticate IRIS-authenticated users
/// If a valid user on the report server is returned, the user will be authenticated
/// Anything else will prompt a Unauthorized response and direct users to the manual login page
ClassMethod ValidateToken(PID As %String, pAuthToken As %String) As %String
{
    New $NAMESPACE
    Set $NAMESPACE="%SYS"
    
    if ('##class(Report.ExternalUser).%ExistsId(PID)) {
        Quit ""
    }
    Set tExternalUser = ##class(Report.ExternalUser).%OpenId(PID)
    if (##class(%Library.UTC).Diff(##class(%Library.UTC).NowUTC(), tExternalUser.IssueTime) > tExternalUser.ExpiresIn) {
        Do ##class(Report.ExternalUser).%DeleteId(PID)
        Quit ""
    }
    if (tExternalUser.AuthToken '= pAuthToken) {
        Quit ""
    }
    Set tReportUser = tExternalUser.ReportUser
    Do ##class(Report.ExternalUser).%DeleteId(PID)
    Quit tReportUser
}

}
