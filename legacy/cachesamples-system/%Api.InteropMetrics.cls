/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provide Interoperability Interface metrics in Prometheus format
Class %Api.InteropMetrics Extends %CSP.REST [ Deprecated ]
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="" Method="get" Call="interfaces" />
  <Route Url="/year/:number" Method="get" Call="interfacesByYear"/>
  <Route Url="/year" Method="get" Call="interfacesByYear"/>
  <Route Url="/month/:number" Method="get" Call="interfacesByMonth"/>
  <Route Url="/month" Method="get" Call="interfacesByMonth"/>
  <Route Url="/day/:number" Method="get" Call="interfacesByDay"/>
  <Route Url="/day" Method="get" Call="interfacesByDay"/>
  <Route Url="/time/:start/:end" Method="get" Call="interfacesByTime"/>
  <Route Url="/time/:start" Method="get" Call="interfacesByTime"/>
  <Route Url="/namespace/:namespace" Method="get" Call="interfaces"/>
</Routes>
}

/// Collect the Interoperability Interface metrics and send them to the client in Prometheus Exposition Format.
/// Optionally filter results to only include those in <param>pNamespace</param>
ClassMethod interfaces(pNamespace As %String = "") As %Status
{
	#Dim sc As %Status = $$$OK
    #Dim ex As %Exception.AbstractException
    
    Try {
    	Set %response.ContentType = ..#CONTENTTYPETEXT
    	Write ##class(SYS.Monitor.SAM.Sensors).InteropMetrics(1,,,pNamespace)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Collect the Interoperability Interface metrics in the specified time range - using UTC - and send them to the client in Prometheus Exposition Format.
/// <param>pStart</param> is required and must be a valid date and optionally time in ODBC format [YY]YY-MM-DD.
/// Time, if specified uses the 24-hour clock and is separated from the date with either single space or a capital "T".
/// If no time is specified, the beginning of the day is used.
/// <param>pStart</param> is to be specified in UTC, and must not be after the current time.
/// <param>pEnd</param> is optional. If specified, it must be a valid date and optionally time in ODBC format [YY]YY-MM-DD.
/// Time, if specified uses the 24-hour clock and is separated from the date with either single space or a capital "T".
/// If no date or time is specified, the present time is used. If a date is specified, but time is not specified, the end of the day is used.
/// <param>pEnd</param> is to be specified in UTC. If a time after the current time is specified, the current time will be used. 
ClassMethod interfacesByTime(pStart As %String = "", pEnd As %String = "") As %Status
{
	#Dim sc As %Status = $$$OK
    #Dim ex As %Exception.AbstractException
    #Dim timeEx As %Exception.AbstractException
    
    Try {
    	Set %response.ContentType = ..#CONTENTTYPETEXT

        Try {
            Set x = $ZDATETIMEH(pStart,3)
        } Catch timeEx {
            If timeEx.Name="<VALUE OUT OF RANGE>" {
                Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropStartOutOfRange,pStart))
            } Else {
                Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropInvalidStart,pStart))
            }
        }
        If $SYSTEM.SQL.Functions.DATEDIFF("second",pStart,$ztimestamp) < 0 {
            Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropStartTimeAfterCurrentTime,pStart))
        }
        Set tStart = ##class(%TimeStamp).Normalize(pStart)

        If ""'=pEnd {
            Try {
                Set x = $ZDATETIMEH(pEnd,3)
            } Catch timeEx {
                If timeEx.Name="<VALUE OUT OF RANGE>" {
                    Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropEndOutOfRange,pEnd))
                } Else {
                    Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropInvalidEnd,pEnd))
                }
            }
            If $SYSTEM.SQL.Functions.DATEDIFF("second",tStart,pEnd) < 0 {
                Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropStartTimeAfterEndTime))
            }
        }

        If pEnd="" {
            Set tEnd = $ZDATETIME($ztimestamp,3)
        } ElseIf ((pEnd'[" ") && (pEnd'["T")) {
            Set tEnd = pEnd_" 23:59:59"
        } Else {
	        Set tEnd = ##class(%TimeStamp).Normalize(pEnd)
        }
        #; If tEnd is after the current time, use the current time
        If $SYSTEM.SQL.Functions.DATEDIFF("second",tEnd,$ztimestamp) < 0 {
            Set tEnd = $zdatetime($ztimestamp,3)
        }
        Write ##class(SYS.Monitor.SAM.Sensors).InteropMetrics(1,tStart,tEnd)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Collect the Interoperability Interface metrics for the specified interval and send them to the client in Prometheus Exposition Format.
/// <param>pInterval</param> may be 'year', 'month', or 'day'.
/// <param>pNumber</param> must be a non-negative integer.
/// A value of 0 means the returned results will represent any interfaces run within the current time period.
/// For example, if <param>pInterval</param> is 'year', this will return results for the current calendar year.
/// If <param>pNumber</param> is a positive value, then the results will represent any interfaces run in the interval <param>pNumber</param> prior to the current one.
/// For example, if <param>pInterval</param> is 'year' and <param>pNumber</param> is 1, this will return results for the previous calendar year,
/// if <param>pNumber<param> is 2, this will return results for the calendar year before the previous one.
/// UTC is used in determining the boundary between intervals.
ClassMethod interfacesByInterval(pInterval As %String = "", pNumber As %Integer = 0) As %Status
{
	#Dim sc As %Status = $$$OK
    #Dim ex As %Exception.AbstractException
    
    Try {
    	Set %response.ContentType = ..#CONTENTTYPETEXT

        If $Case(pInterval,"year":0,"month":0,"day":0,:1) {
            Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropInvalidIntervalType,pInterval))
        }
        If (($ZABS(pNumber)'=pNumber) || (pNumber#1)) {
            Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropInvalidInterval,pNumber,pInterval))
        }
        Set tCurrent = $ZDATE($ZTIMESTAMP,3)
        Set:$Case(pInterval,"month":1,"year":1,:0) $P(tCurrent,"-",3) = "01"
        Set:pInterval="year" $P(tCurrent,"-",2) = "01"
        #; Start by calculating the end date. It is the final millisecond of whichever day, month, or year was specified.
        Set tEnd = $System.SQL.Functions.DATEADD(pInterval,(1-pNumber),tCurrent)
        Set tEnd = $System.SQL.Functions.DATEADD("millisecond",-1,tEnd)
        #; If end date is out of range (before 12/31/1840), then return an error.
        Try {
            Set x = $ZDATETIMEH(tEnd,3)
        } Catch {
            Return ..ReportHttpStatusCode(..#HTTP400BADREQUEST,$$$ERROR($$$InteropEndOutOfRange,tEnd))
        }
        #; Now calculate the start date. This is today minus whatever number was specified.
        Set tStart = $System.SQL.Functions.DATEADD(pInterval,-pNumber,tCurrent)
        Try {
            Set x = $ZDATETIMEH(tStart,3)
        } Catch {
            #; Requested range includes 12/31/1840 00:00:00. No recordings can be before this time, so start with this time.
            Set tStart = 0
        }
    	Write ##class(SYS.Monitor.SAM.Sensors).InteropMetrics(1,tStart,tEnd)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Collect the Interoperability Interface metrics for the specified month and send them to the client in Prometheus Exposition Format.
/// <param>pNumber</param> must be a non-negative integer.
/// A value of 0 means the returned results will represent any interfaces run within the current calendar month.
/// If <param>pNumber</param> is a positive value, then the results will represent any interfaces run in the month <param>pNumber</param> prior to the current one.
/// For example, if is 1, this will return results for the previous calendar month and
/// if <param>pNumber<param> is 2, this will return results for the calendar month before the previous one.
/// /// UTC is used in determining the boundary between months.
ClassMethod interfacesByMonth(pMonth As %Integer = 0) As %Status
{
    Quit ..interfacesByInterval("month",pMonth)
}

/// Collect the Interoperability Interface metrics for the specified year and send them to the client in Prometheus Exposition Format.
/// <param>pNumber</param> must be a non-negative integer.
/// A value of 0 means the returned results will represent any interfaces run within the current calendar year.
/// If <param>pNumber</param> is a positive value, then the results will represent any interfaces run in the year <param>pNumber</param> prior to the current one.
/// For example, if is 1, this will return results for the previous calendar year and
/// if <param>pNumber<param> is 2, this will return results for the calendar year before the previous one.
/// /// UTC is used in determining the boundary between years.
ClassMethod interfacesByYear(pYear As %Integer = 0) As %Status
{
	Quit ..interfacesByInterval("year",pYear)
}

/// Collect the Interoperability Interface metrics for the specified day and send them to the client in Prometheus Exposition Format.
/// <param>pNumber</param> must be a non-negative integer.
/// A value of 0 means the returned results will represent any interfaces run within the current calendar day.
/// If <param>pNumber</param> is a positive value, then the results will represent any interfaces run in the day <param>pNumber</param> prior to the current one.
/// For example, if is 1, this will return results for the previous calendar day and
/// if <param>pNumber<param> is 2, this will return results for the calendar day before the previous one.
/// /// UTC is used in determining the boundary between days.
ClassMethod interfacesByDay(pDay As %Integer = 0) As %Status
{
	Quit ..interfacesByInterval("day",pDay)
}

}
