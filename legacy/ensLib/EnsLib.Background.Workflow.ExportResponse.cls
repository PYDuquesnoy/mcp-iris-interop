/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Background.Workflow.ExportResponse Extends EnsLib.Workflow.TaskResponse [ System = 4 ]
{

Method downloadLink() As %String [ Internal ]
{
	Try {

		#dim tLink = $C(0)_$ZCVT("Failed to link to temporary export file","O","JS")
		#dim tFilename = ..%FormValues.GetAt("TemporaryExportFilename")
		#dim tCharSet = ..%FormValues.GetAt("CharSet")
		#dim tDocName = ..%FormValues.GetAt("LocalFilename")
		#dim tFileKey = ..%FormValues.GetAt("FileKey")
		#dim tFileHash = ..%FormValues.GetAt("FileHash")

		#dim tExpectedTempFilename = ##class(EnsPortal.Dialog.ExportMessages).tempServerFilename(tDocName,tFileKey,..%TaskStatus.Request.%UserName)
		If tExpectedTempFilename'=tFilename {
			Set tLink = tLink _" "_$ZCVT(" (expected name mismatch)","O","JS")
			Quit
		}


		#dim tStream = ##class(%FileBinaryStream).%New()
		#dim tSC = tStream.LinkToFile(tFilename)
		If $$$ISERR(tSC) Quit

		#dim tExpectedFileHash = $SYSTEM.Encryption.SHA3HashStream($$$ensSHA3CheckLength,tStream,.tSC)
		If tExpectedFileHash'=tFileHash || $$$ISERR(tSC) {
			Set tLink = tLink _" "_$ZCVT(" (expected File Hash mismatch)","O","JS")
			Quit
		}

		Do tStream.SetAttribute("ContentDisposition","attachment; filename="_tDocName)
		Do tStream.SetAttribute("CharSet",tCharSet)
		Set tSC = tStream.%Save()
		If $$$ISERR(tSC) Quit

		#dim Oid = tStream.%Oid()
		Set tLink = ##class(%CSP.Page).Link("%25CSP.StreamServer.cls?STREAMOID="_##class(%CSP.Page).Encrypt(Oid))

	} Catch {

	}

	Quit tLink
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
