/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.BP.Utils.Upgrade [ ClassType = "", System = 4 ]
{

/// This is used to upgrade pending list subnode structure to the current parent/child structure.
/// It is called by the upgrade procedure in %Library.EnsembleMgr::dataUpgradeSteps()
/// with display=0 and dryRun = 0 and with no limitToId. <br>
/// The method attempts to recompile the particular Business Process classes involved
/// if the dry run flag is not set and the classes are not Ens* nor HS*. <br>
/// Note: the check whether the code database is writeable is carried out in
/// %Library.EnsembleMgr::dataUpgradeSteps() <br>
/// This classmethod can be run independently to find in progress requests prior to an
/// upgrade (it does not check if the production is running). <br>
/// <EXAMPLE>
///  Do ##class(Ens.BP.Utils.Upgrade).UpgradePendingResponsesStorage(.log,1,1)
/// </EXAMPLE>
/// <p><b>Output </b>
/// <br> Status for BP ID 60 : Started
/// <br> Found pending responses : 1
/// <br> Class : EnsLib.Testing.Process
/// <br> Status for BP ID 60 : Completed Dry Run Only
/// <br> Status for BP ID 61 : Started
/// <br> Found pending responses : 24
/// <br> Class : Custom.BP.Test
/// <br> Status for BP ID 61 : Completed Dry Run Only
/// 
ClassMethod UpgradePendingResponsesStorage(ByRef log, display As %Boolean = 1, dryRun As %Boolean = 1, limitToId As %String = "")
{
	kill log
	If limitToId = "" {
		Set bpID = $Order(^Ens.BusinessProcessD(""))
	} Else {
		Set bpID = limitToId
	}
	While bpID '= "" {
		If $Data(^Ens.BusinessProcessD(bpID,"pending"),numMPR)#2 {
			Set logEntry = $i(log)
			Set log(logEntry,"ID") = bpID
			Set log(logEntry,"Status") = "Started"
			If display Write !,"Status for BP ID "_bpID_" : " _log(logEntry,"Status")
            Set log(logEntry,"Count") = numMPR
            If display Write !,"Found pending responses : " _log(logEntry,"Count")

            Set bp = ##class(Ens.BusinessProcess).%OpenId(bpID,,.sc)
			If $$$ISERR(sc) {
				Set log(logEntry,"Error") = $system.Status.GetErrorText(sc)
				If display Write !,"Error for BP ID "_bpID_" : " _log(logEntry,"Error")
			} Else {
				Set bpClassname = $classname(bp)
				Set bp = $$$NULLOREF
				Set log(logEntry,"Class") = bpClassname
				If display Write !,"Class : " _log(logEntry,"Class")
                If 'dryRun {
                    If '$Data(seen(bpClassname))&&($E(bpClassname,1,3)'="Ens")&&($E(bpClassname,1,2)'="HS") {
                        Try {
                            Set sc = $system.OBJ.Compile(bpClassname,"ck-d",.errorlog)
                        } Catch ex {
                            Set sc = ex.AsStatus()
                        }
                        If $$$ISERR(sc) {
                            Set log(logEntry,"Recompiled") = "Failed"
                            Merge log(logEntry,"CompileError") = errorLog
                        } Else {
                            Set log(logEntry,"Recompiled") = "Succeeded"
                        }
                    } Else {
                        Set log(logEntry,"Recompiled") = "Skipped"
                    }
                    Set seen(bpClassname) = ""
                    If $i(seen(bpClassname)) = 1 && display Write !,"Recompiled first occurrence of "_bpClassname_" : " _log(logEntry,"Recompiled")
                }
                Try {
                    If 'dryRun {
                        Set inTrans = 1
                        TStart
                    }
                    For pending = 1:1:numMPR {
                        Set mprData = $Get(^Ens.BusinessProcessD(bpID,"pending",pending))
                        If mprData = "" {
                            Set log(logEntry,"Error") = "Missing pending entry #: "_pending
                            If display Write !,"Error for BP ID "_bpID_" : " _log(logEntry,"Error")
                            Quit ; skip rest of pending for this BP
                        } Else {
                            If dryRun Continue
                            Set mpr = ##class(Ens.BP.MasterPendingResponse).%New($List(mprData,1),$List(mprData,2),$List(mprData,3),$List(mprData,4))
                            Do mpr.%BusinessProcessSetObjectId(bpID)
                            Set sc = mpr.%Save()
                            If $$$ISERR(sc) {
                                Set log(logEntry,"Error") = $system.Status.GetErrorText(sc)
                                If display Write !,"Error for BP ID "_bpID_", pending response # "_pending_" : " _log(logEntry,"Error")
                                Quit ; skip rest of pending for this BP
                            }
                        }
                    }
                } Catch ex {
                    Set log(logEntry,"Error") = ex.DisplayString()
                }
                /*  We are going to remove the old global storage for pending
                    if not an error so need to either rollback any partial conversion
                    or commit.
                */
                If $Get(inTrans) {
                    If $Data(log(logEntry,"Error")) {
                        TRollBack
                    } Else {
                        TCommit
                    }
                    Kill inTrans
                }
				If 'dryRun && '$Data(log(logEntry,"Error")) Kill ^Ens.BusinessProcessD(bpID,"pending")
				Set log(logEntry,"Status") = $Select($Data(log(logEntry,"Error")):"Errored",1:"Completed")_$Select(dryRun: " Dry Run Only",1:"")
				If display Write !,"Status for BP ID "_bpID_" : " _log(logEntry,"Status")
			}
		}
		If limitToId = "" {
			Set bpID = $Order(^Ens.BusinessProcessD(bpID))
		} Else {
			Set bpID = ""
		}
	}
}

}
