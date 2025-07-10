/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract printer operation
Class EnsLib.Printing.UNIXPrinter Extends EnsLib.Printing.AbstractPrinter [ ProcedureBlock, System = 4 ]
{

/// This value must either be lp or specified in the permitted interoperability OS command list.
Property Command As %String(MAXLEN = 512) [ InitialExpression = "lp" ];

/// Printer options, separated by a linefeed
Property Options As %String(MAXLEN = 32700);

/// Character set to use when printing (UTF-8 is the default)
Property CharSet As %String [ InitialExpression = "UTF8" ];

Parameter SETTINGS As %String = "Command,Options,CharSet::selector?context={Ens.ContextSearch/CharacterSets}";

/// Print a print job
Method Print(pRequest As EnsLib.Printing.PrintJob, ByRef pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status=$$$OK
	#dim ex As %Exception.AbstractException

	#dim tCmd As %String
	#dim tCharSet

	Try {

		// Build the command to invoke lp with
		Set tSC = ..buildCommand(pRequest,.tCmd,.tCharSet)
		Quit:$$$ISERR(tSC)
		
		// Invoke the UNIX lp
		Set tSC = ..printJob(pRequest,.tCmd,tCharSet)
		Quit:$$$ISERR(tSC)

	} Catch ex {
		Set tSC=$$$EnsSystemError
	}

	Quit tSC
}

/// Constructs the lp command for this print job
Method buildCommand(pRequest As EnsLib.Printing.PrintJob, ByRef pCmd As %String, ByRef pCharSet As %String) As %Status
{
	#dim tSC As %Status
	#dim tDestination As %String
	Kill pCmd
	Set pCmd("cmd") = ..Command
	Set pCharSet = ..CharSet
	Set tSC = ..FindDestinationForPrinter($this,pRequest.PrintTarget,.tDestination)
	If $$$ISERR(tSC) Quit tSC

	If (tDestination'="") {
		Set pCmd($I(pCmd)) = "-d"
		Set pCmd($I(pCmd)) = tDestination
	}
	If ..Options'="" {
		#dim tOptions As %String
		#dim tOption As %String
		#dim i As %Integer

		Set tOptions = $TR(..Options,$C(13,10),$C(10,10))
		For i=1:1:$L(tOptions,$C(10)) {
			Set tOption=$P(tOptions,$C(10),i)
			If tOption'="" {
				Set pCmd($I(pCmd)) = "-o"
				Set pCmd($I(pCmd)) = tOption
			}
		}
	}

	Quit tSC
}

/// Submit the print job using the specified command
Method printJob(pRequest As EnsLib.Printing.PrintJob, ByRef pCmd As %String, pCharSet As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tStdInFilename = ##class(%Library.File).TempFilename()
	#dim tStdOutFilename = ##class(%Library.File).TempFilename()
	#dim tStdErrFilename = ##class(%Library.File).TempFilename()

	#dim tTempFile As %Stream.FileCharacter

	#dim tOSCommand As %String
	#dim tCmdArgs As %String

	Try {

		If pRequest.Content.Size = 0 {
			$$$sysTRACE("Print request is empty")
			Quit
		}

		Set tOSCommand = $Get(pCmd("cmd"))

		Merge tCmdArgs = pCmd
		Kill tCmdArgs("cmd")

		Set tSC =..createStdInFile(pRequest,pCharSet,tStdInFilename)
		If $$$ISERR(tSC) Quit

		#dim tFlags = "/STDIN="_$C(34)_tStdInFilename_$C(34)_" /STDOUT="_$C(34)_tStdOutFilename_$C(34)_" /STDERR="_$C(34)_tStdErrFilename_$C(34)

		If $$$DoTrace {
			$$$sysTRACE("Flags:"_tFlags)
			$$$sysTRACE("OS Command:"_tOSCommand)
			#dim tCount
			#dim tOptions = ""
			For tCount=1:1:tCmdArgs {Set tOptions = tOptions_" "_$G(tCmdArgs(tCount))}
			$$$sysTRACE("Options:"_tOptions)
		}

		If $ZF(-100,tFlags,tOSCommand,.tCmdArgs) {}

		Set tTempFile = ##class(%Stream.FileCharacter).%New()
		Set tSC = tTempFile.LinkToFile(tStdErrFilename)
		If $$$ISOK(tSC) {
			If tTempFile.Size>0 {
				#dim tErrInfo = tTempFile.Read()
				Set tSC = $$$EnsError($$$EnsErrGeneral,"Error Printing: "_tErrInfo)
			}
		} Else {
			Quit
		}

		If $$$DoTrace {
			Set tTempFile = ##class(%Stream.FileCharacter).%New()
			Set tSC = tTempFile.LinkToFile(tStdOutFilename) 
			If $$$ISOK(tSC) {
				If tTempFile.Size>0 {
					#dim tOut = tTempFile.Read()
					$$$sysTRACE(tOut)
				}
			}
		}

	} Catch ex {

		Set tSC=$$$EnsSystemError

	}

	#; Ensure file link to StdOut or StdErr files is closed.
	Set tTempFile = ""

	Set tSC = $$$ADDSC(tSC,..deleteTempFiles(tStdInFilename,tStdOutFilename,tStdErrFilename))

	Quit tSC
}

Method createStdInFile(pRequest As EnsLib.Printing.PrintJob, pCharSet As %String, pStdInFilename As %String = {##class(%Library.File).TempFilename()}) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tTempFile As %Stream.FileCharacter

	Try {

		#; Create temporary StdIn file for print request
		Set tTempFile = ##class(%Stream.FileCharacter).%New()
		Set tTempFile.Filename = pStdInFilename
		Set tTempFile.TranslateTable = pCharSet
		Set tSC = tTempFile.CopyFromAndSave(pRequest.Content)

		If $$$ISOK(tSC) && ((pStdInFilename="")||'##class(%Library.File).Exists(pStdInFilename)) {

			Set tSC = $$$EnsError($$$EnsErrGeneral,"Failed to create temporary StdIn file for print request")

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

Method deleteTempFiles(pFileNames...) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	If '$Get(pFileNames) Quit tSC

	#dim ex As %Exception.AbstractException

	#dim tFileToDelete As %String
	#dim tCount As %Integer
	#dim tDeleteInfo

	Try {

		For tCount = 1:1:pFileNames {

			Set tFileToDelete = pFileNames(tCount)

			If (tFileToDelete'="") && ##class(%Library.File).Exists(tFileToDelete) {
				If '##class(%Library.File).Delete(tFileToDelete,.tDeleteInfo) Set tSC = $$$ADDSC(tSC,$$$ERROR($$$GeneralError,("Error -"_$Get(tDeleteInfo)_" deleting temp file "_tFileToDelete)))
			}

		}

	} Catch ex {

		Set tSC = $$$ADDSC(tSC,ex.AsStatus())

	}

	Quit tSC
}

Method OnInit() As %Status
{
	#Dim tSC = ##super()
	If $$$ISOK(tSC) {

		If ..Command = "" {

			Set tSC = $$$EnsError($$$EnsErrGeneral,"Printing command is not specified")

		} ElseIf (..Command '= "lp") && ('$Data(^%SYS("Interoperability","Permitted","OS Command",..Command))#2) {

			Set tSC = $$$EnsError($$$EnsErrGeneral,"Printing command '"_..Command_"' is not allowed")

		} Else {

			Set ..PrinterDelegate = ##class(Ens.AbstractDelegate).InitializeDelegate(..PrinterDelegateClass,"EnsLib.Printing.AbstractPrinterDelegate",$this,.tSC)
		}
	}
	
	Quit tSC
}

}
