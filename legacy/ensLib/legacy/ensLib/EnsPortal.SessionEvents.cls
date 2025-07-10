/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.SessionEvents Extends %CSP.SessionEvents
{

/// Ensure that we remove any temporary data from ^IRIS.Temp.EnsPortal.Data
ClassMethod OnEndSession()
{
	Do ..KillSessionNodes()
	Quit
}

ClassMethod Initialize(pNamespace As %String = "") As %Status
{
	If %session.EventClassExists($classname($this),pNamespace) Quit $$$OK
	Quit %session.EventClassAdd($classname($this),pNamespace)
}

ClassMethod KillSessionNodes() As %Boolean
{
	Do ..deleteTempStreams()
	Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId)
	Quit 1
}

ClassMethod GetTempNode() As %Integer
{
	Do ..Initialize()
	Quit $increment(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0))
}

ClassMethod KillTempNode(pCounter As %Integer = 0) As %Boolean
{
	Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pCounter)
	Quit 1
}

ClassMethod GetReference(pCounter As %Integer = 1) As %String [ CodeMode = expression ]
{
$name(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pCounter))
}

/// Internal method to cleanup temporary data created during User portal interactions.<br>
/// Includes deleting data made from exporting messages, deployment items and from
/// DTL Editor interactive test facility.
ClassMethod deleteTempStreams() [ Internal ]
{
	#; Validating Msg Export file
	#dim tEncryptedMsgExportLB = ""
	#dim tMsgExportLB = ""
	#dim tMsgFilename = ""
	#dim tMsgDocName = ""
	#dim tMsgKey = ""

	#; Validating deployment export file
	#dim tEncryptedGblOid = ""

	#dim tEncryptedDTLTestObjectOid = ""

	#dim tReturn = ""

	#dim tCounter = $Order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,""))

	While (tCounter '= "") {

		If $Data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter,"TempMsgExportFile"),tEncryptedMsgExportLB)#2 {

			Try {

				If (tEncryptedMsgExportLB'="") {

					Set tMsgExportLB = ##class(%CSP.Page).Decrypt(tEncryptedMsgExportLB)
					Set tMsgFilename = $LG(tMsgExportLB,1)
					Set tMsgDocName = $LG(tMsgExportLB,2)
					Set tMsgKey = $LG(tMsgExportLB,3)

					If tMsgFilename = ##class(EnsPortal.Dialog.ExportMessages).tempServerFilename(tMsgDocName,tMsgKey) {

						If ##class(%File).Exists(tMsgFilename) {

							If '##class(%Library.File).Delete(tMsgFilename,.tReturn) {
								$$$LOGWARNING("Failed to delete temporary user file: "_tMsgFilename_" ("_tReturn_")")
							}

						}

					}

				}

			} Catch {}

		} ElseIf $Data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter,"TempDeployGlobalStream"),tEncryptedGblOid)#2 {

			Try {

				If (tEncryptedGblOid'="") {

					If ##class(EnsPortal.Dialog.ExportFromItem).isValidExportTempStream(tEncryptedGblOid) {

						Set tReturn = ##class(%Stream.Object).%Delete(##class(%CSP.Page).Decrypt(tEncryptedGblOid))
						If $$$ISERR(tReturn) {
							$$$LOGWARNING("Failed to delete temporary deployment export stream global marked for delete at end of web session "_$$$StatusDisplayString(tReturn))
						}

					} Else {

						$$$LOGWARNING("Invalid temporary deployment export stream global marked for delete at end of web session.")

					}

				}

			} Catch {}

		} ElseIf $Data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter,"TempDTLTestObject"),tEncryptedDTLTestObjectOid)#2 {

			Try {

				If (tEncryptedDTLTestObjectOid'="") {

						#dim tDTLTestObjectOid = ##class(%CSP.Page).Decrypt(tEncryptedDTLTestObjectOid)
						If ##class(%Library.Persistent).%Exists(tDTLTestObjectOid) {
							Set tReturn = ##class(%Library.Persistent).%Delete(tDTLTestObjectOid)
							If $$$ISERR(tReturn) {
								$$$LOGWARNING("Failed to delete temporary test object marked for delete at end of web session "_$$$StatusDisplayString(tReturn))
							}
						}

				}

			} Catch {}

		} 

		Set tCounter = $Order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter))

	}
}

}
