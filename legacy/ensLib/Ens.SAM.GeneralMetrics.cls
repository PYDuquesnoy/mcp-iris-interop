/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Used to collect statistics as given in EnsMonitorServiceDaily section
/// of Ens.SAM.SensorDefinitions class aimed at providing Message Retention Metrics. <br>
/// The Collect() api provided here is called by the  Ens.Util.Tasks.MonitorMetrics
/// task.
Class Ens.SAM.GeneralMetrics Extends %RegisteredObject [ System = 4 ]
{

Parameter SAMDEFINITIONCLASS = "Ens.SAM.SensorDefinitions";

Parameter SAMDEFINITION = "EnsMonitorServiceDaily";

/// Comma separate list of number of days to show message header counts for. <br>
/// Exclude oldest and 0. Same values in task Ens.Util.Tasks.MonitorMetrics
Property DayBoundariesForCounts As %String [ InitialExpression = "56, 28, 14, 7, 1" ];

/// Collects EnsMonitorServiceDaily stats.
ClassMethod Collect(pDayBoundariesForCounts As %String = "") As %Status
{
    Set sc = $$$OK
    #; not a production host item so populate expected local variable
    New $$$EnsJobLocal
    Merge $$$SAMInteropConfig = $$$SAMInteropPermConfig

    #; These are stats collected daily and hence we do not clear out at the end of each poll
    $$$EnsSetSAMSampler(..#SAMDEFINITIONCLASS,..#SAMDEFINITION,.isSAMSamplingEnabled,.sc)
    #; Account for production not running as default SAMProductionLabel is from Runtime global
    Set $$$EnsSAMSampler.SAMProductionLabel = $ListBuild($$$EnsSAMProductionLabel,##class(Ens.Director).GetActiveProductionName())

    If $$$ISOK(sc) {

        If 'isSAMSamplingEnabled Return $$$OK

        Try {

            Set monitorInstance = ..%New()

            If pDayBoundariesForCounts '= "" {
                /* check pDayBoundariesForCounts only contains positive numbers */
                Set validList = 1
                For i = 1 : 1 : $Length(pDayBoundariesForCounts,",") {
                    Set day = +$ZSTRIP($Piece(pDayBoundariesForCounts,",", i),"<>W")
                    If day <= 0 {Set validList = 0  Quit}
                }
                If 'validList {
                    Set sc = $$$ERROR($$$GeneralError, "DayBoundariesForCounts must one or more numbers greater than 0, separated by a comma.")
                    Quit
                }
                Set monitorInstance.DayBoundariesForCounts = pDayBoundariesForCounts
            }

            Set sc = monitorInstance.collectDailyMetrics()

        } Catch ex { Set sc = ex.AsStatus()}

    }

    Return sc
}

/// Internal method to collect the metrics
Method collectDailyMetrics() As %Status [ Internal, Private ]
{
    Set sc = $$$OK, scSQL = $$$OK, scSize = $$$OK
    $$$EnsStartSAMSample
    /* Need to reset the temp storage data since not a production
        item that could use $$$EnsRemoveLastRecordedSensorSample as
        this is a different process from the last run.
    */
    Set sensor = ""
    For {
        Set sensor = $Order($$$EnsSAMSampler.SAMSensors(sensor))  Quit:(sensor="")
        Kill $$$SAMInteropCentralGlobal($namespace,sensor)
    }
    /* Count of Headers by day grouped by certain ages.
        This calculation walks all of the TimeCreated
        Index global storage.
        These calculations are aimed to aid identifying
        if number of headers are growing over time despite
        purging.
        This is called from the task Ens.Util.Tasks.MonitorMetrics
    */
    If $Data(^Ens.MessageHeaderD)>1 {
        Set timeCreated = "", lastCreatedDate = "", currentDateDayCount = 0, oldestAgeInDays = 0, oldestDateCreated = ""
        /* Convert DayBoundariesForCounts into ordered array */
        For i = 1 : 1 : $Length(..DayBoundariesForCounts,",") {
            Set day = +$ZSTRIP($Piece(..DayBoundariesForCounts,",", i),"<>W")
             If day > 0 Set boundaryDays(day) = ""
        }
        For {
            Set timeCreated = $Order(^Ens.MessageHeaderI("TimeCreated",timeCreated))
            Quit:(timeCreated="")
            Set timeCreatedDate = $Piece(timeCreated," ")
            If lastCreatedDate = "" {
                Set lastCreatedDate = timeCreatedDate
                Set oldestDateCreated = timeCreatedDate
                Set oldestAgeInDays = $SYSTEM.SQL.Functions.DATEDIFF("day",timeCreated,$$$timeUTC)
                Set currentAgeInDays = oldestAgeInDays
            } ElseIf timeCreatedDate'=lastCreatedDate {
                #; Collect oldest count
                If lastCreatedDate=oldestDateCreated {
                    $$$EnsCollectOneSAMSample("InteropOldestMessageHeaderCount",currentDateDayCount,"")
                    $$$EnsCollectOneSAMSample("InteropOldestMessageHeaderDays",oldestAgeInDays,"")
                }
                Set lastCreatedDate = timeCreatedDate
                #; Total count
                Do $I(ageCount(0),currentDateDayCount)
                #; Calculate Counts per band
                Set boundary = ""
                For {
                    Set boundary = $Order(boundaryDays(boundary),-1)  Quit:(boundary="")
                    Do:(currentAgeInDays>(boundary-1)) $I(ageCount(boundary),currentDateDayCount)
                }
                Set currentAgeInDays = $SYSTEM.SQL.Functions.DATEDIFF("d",timeCreatedDate,$$$timeUTC)
                /* possible on a test system that timeCreatedDate is in the future and so currentAgeInDays < 0. So count as 0
                    boundaryDays array at this point does not include 0
                */
                If currentAgeInDays < 0 Set currentAgeInDays = 0
                Set currentDateDayCount = 0
            }
            Set hdrId = "" 
            For {
                Set hdrId = $Order(^Ens.MessageHeaderI("TimeCreated",timeCreated,hdrId))
                Quit:(hdrId="")
                Do $Increment(currentDateDayCount)
            }
        }
        #; Record data and include all days (0)
        Set boundaryDays(0) = ""
        #; Account for the last day counts before recording metrics
        Set boundary = ""
        For {
            Set boundary = $Order(boundaryDays(boundary),-1)  Quit:(boundary="")
            Do:(currentAgeInDays>=(boundary)) $I(ageCount(boundary),currentDateDayCount)
            $$$EnsCollectOneSAMSample("InteropHeaderCountOlderThan",$Get(ageCount(boundary),0),"days=" _ boundary)
        } 
    } Else {
        /* No headers */
        $$$EnsCollectOneSAMSample("InteropOldestMessageHeaderCount",0,"")
    }

    /* Count of Session IDs	*/
    Set sql = "SELECT COUNT(DISTINCT(SESSIONID)) AS SESSIONCOUNT FROM Ens.MessageHeader"
    Set queryResult = ##class(%SQL.Statement).%ExecDirect(.statement,sql)
    If queryResult.%SQLCODE < 0 {
        Set scSQL = ##class(%Exception.SQL).CreateFromSQLCODE(queryResult.%SQLCODE,queryResult.%Message).AsStatus()
    } ElseIf (queryResult.%SQLCODE = 0)  && queryResult.%Next() {
        Set sessionCount = queryResult.%Get("SESSIONCOUNT")
    } Else {
        Set sessionCount = 0
    }
    If $$$ISERR(scSQL) {
        Set sc = $$$ADDSC(sc,scSQL)
    } Else {
        $$$EnsCollectOneSAMSample("InteropSessionCount",sessionCount,"")
    }
    /* Obtain %SYS info on db used space */
    Set currentNSP = $namespace
    Try {
        New $namespace
        Set $namespace = "%SYS"
        Set sc = ##class(%EnsembleMgr).getNSPSoleUseNonSysDBs(currentNSP,"ALL",.databases)
        /* Find space used by array databases. Name = directory */
        Set usedSpace = 0
        Set db = $Order(databases(""),1,dbDir)
        While db '= "" {
            Set dbObj = ##class(SYS.Database).%OpenId(dbDir)
            Set usedSpace = usedSpace + dbObj.Size - +$Get(^IRIS.Temp.SAM("freespace",dbDir))
            Set db = $Order(databases(db),1,dbDir)
        }
        Set dbObj = ""
    } Catch ex {
        Set scSize = ex.AsStatus()
        Set sc = $$$ADDSC(sc,scSize)
    }
    Set $namespace = currentNSP
    If $$$ISOK(scSize) {
        $$$EnsCollectOneSAMSample("InteropNamespaceStorageMB",usedSpace,"")
        If sessionCount > 0 {
            Set averageUsedPerSession = (usedSpace * 1024)\sessionCount
            $$$EnsCollectOneSAMSample("InteropSessionStorageKB",averageUsedPerSession,"")
        }
    }

    /*	The 86400 used if we are calculating averages but we are not at the moment.
        temp data cleanup not carried out in this class.
    */

    $$$EnsCompleteSAMSample(86400)
    Return sc
}

}
