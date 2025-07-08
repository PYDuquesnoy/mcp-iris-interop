/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.Diagnostic.Monitor
{

/// Fetch the list of all processes which have AppFrameInfo set. Current activity is returned in<br>
/// <var>pActivity</var>(ID) = appFrameInfo<br>
/// Optionally <var>pTag</var> may be supplied to limit the collection to appFrameInfo which contains the 
/// requested tag.
ClassMethod %FetchActivity(Output pActivity, pTag As %String = "*") As %Status
{
    Kill pActivity
    Set tSC = $$$OK

    Try {
        Set tStatement = ##class(%SQL.Statement).%New()
        Set tSC = tStatement.%PrepareClassQuery("%SYS.ProcessQuery","ListPids")
        Quit:$$$ISERR(tSC)
        
        Set tResult = tStatement.%Execute()

        While tResult.%Next() {
            Set PID = tResult.%GetData(1),state=+$zutil(67,4,PID)     // DP-430783 - record process state when it is queried

            Set tAppFrameInfo = $system.Process.GetAppFrameInfo(PID)

            // Select appFrame information that is tagged according to the requested pTag
            Set tSelectAppFrame = 0
            For k = 1:1:$LL(tAppFrameInfo) {
                Set:((pTag="*")||($LG($LG(tAppFrameInfo,1),1)=pTag)) tSelectAppFrame = 1
            }

            If tSelectAppFrame {
                Set pActivity(PID) = tAppFrameInfo,x=$I(pActivity)
                Set pActivity(PID,"state") = state
            }
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }

    Quit tSC
}

/// Write current activity to the current device.  The <var>pTag</var> parameter can filter the export to
/// a collection of AppFrameInfo entries pushed to the stack with that identification tag at $LB(frameInfo,1). By default
/// this will collect all AppFrameInfo entries which use the "%BI" tag anywhere in the stack. 
ClassMethod %PrintActivity(pTag As %String = "%BI")
{
    Do ..%FetchActivity(.tActivity,pTag)

    Set PID = $O(tActivity(""),1,tAppFrameInfo)
    While (PID'="") {
        Do $I(itemCount)
        Write !," "_PID,":",$LG(##class(%SYS.ProcessQuery).DecodeState(tActivity(PID,"state")),1),!

        For k = 1:1:$LL(tAppFrameInfo) {
            Set tStackLine = ..%ConvertBIFrameToString($LG(tAppFrameInfo,k),0)
            
            Write:(k>1) !
            Write ?((k-1)*2 + 8),tStackLine

            Write !
        }

        Set PID = $O(tActivity(PID),1,tAppFrameInfo)
    }

    Write !,$S('$G(itemCount):"No processes had AppFrameInfo for tag: " _ pTag,1:"Displaying AppFrameInfo from "_+$G(itemCount)_" processes for tag: " _ pTag)
}

/// Export current activity recorded in the AppFrameInfo to a file. The <var>pTag</var> parameter can filter the export to
/// a collection of AppFrameInfo entries pushed to the stack with that identification tag at $LB(frameInfo,1). By default
/// this will collect all AppFrameInfo entries which use the "%BI" tag anywhere in the stack. 
ClassMethod %ExportActivityToFile(pFileName = "", pTag As %String = "%BI") As %Status
{
    Set tSC = $$$OK

    Try {
        Set tFileStream = ##class(%Stream.FileBinary).%New()
		Set tSC = tFileStream.LinkToFile(pFileName)
        Quit:$$$ISERR(tSC)

        Do ..%FetchActivity(.tActivity,pTag)

        Set ID = $O(tActivity(""),1,tAppFrameInfo)
        While (ID'="") {
            Do $I(itemCount)
            Do tFileStream.WriteLine(" "_ID)

            Set tIndent = 0
            For k = 1:1:$LL(tAppFrameInfo) {
                Set tIndent = 8 + ((k-1)*2)
                Set tStackLine = ..%ConvertBIFrameToString($LG(tAppFrameInfo,k),tIndent)
                
                Do tFileStream.WriteLine(tStackLine)
            }

            Set ID = $O(tActivity(ID),1,tAppFrameInfo)
        }

        Do tFileStream.WriteLine($S('$G(itemCount):"No processes had AppFrameInfo for tag: " _ pTag,1:"Displaying AppFrameInfo from "_+$G(itemCount)_" processes for tag: " _ pTag))
    } Catch ex {
        Set tSC = ex.AsStatus()
    }

    Do:$IsObject($G(tFileStream)) tFileStream.%Save()

    Quit tSC
}

/// Conversion a single stack piece of appFrame data to a printable string.
ClassMethod %ConvertBIFrameToString(pFrameItem As %String, pIndent = 10) As %String
{
    Set tIndent = ""

    Set tStackPrintLine = pFrameItem
    
    // If there is a structured appFrameInfo formatassociated with the tag, use that for display
    If $ListValid(pFrameItem)&&($$$dsAppInfoTag(pFrameItem)="%BI") {
        Set tStackPrintLine = "%BI" _ " | " _ $$$dsAppInfoNS(pFrameItem) _ " | " _
                            $$$dsAppInfoTS(pFrameItem) _ " | " _
                            $$$dsAppInfoUser(pFrameItem) _ " | " _
                            $$$dsAppInfoMethod(pFrameItem) _ " | " _
                            $$Quote^%qcr($$$dsAppInfoData(pFrameItem))
    } Else {
        Set tStackPrintLine = $$Quote^%qcr(pFrameItem)
    }

    Quit $J("",pIndent) _ tStackPrintLine
}

}
