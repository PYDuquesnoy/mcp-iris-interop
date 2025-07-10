/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %ZEN.ReportUtil, %products)

Class Ens.Util.Documentation [ ClassType = "", System = 4 ]
{

/// Helper method: Return the URL to render the production documentation in HTML format.
ClassMethod GetDocHTML(ProductionClass As %String, Output URL As %String)
{
	Set URL = ""
	If $G(ProductionClass)="" Quit
	#dim htmlDocStreamOID = ..getHTMLDocStreamOID(ProductionClass)
	If $G(htmlDocStreamOID)="" Quit

	If '..CheckDocExists(ProductionClass,.htmlDocStreamOID) Quit

	Set URL = ..BuildURL(htmlDocStreamOID)

	Quit
}

/// Internal method to generate the url for Doc Stream to be served. <br>
/// If this is called from a non web  session then it only returns the HTMLDocStreamIOD
ClassMethod BuildURL(HTMLDocStreamOID As %String) As %String [ Internal ]
{
	#; up to caller to create encrypted oid and link
	If '$Data(%session) Return HTMLDocStreamOID

	#dim linkToHTMLDocumentation = ##class(%CSP.Page).Link("%25CSP.StreamServer.cls?STREAMOID="_##class(%CSP.Page).Encrypt(HTMLDocStreamOID))
	Quit linkToHTMLDocumentation
}

ClassMethod GetRecordMode() As %String [ Internal ]
{
	If $$$isVMS {
		Quit "U"
	}
	Else {
		Quit "S"
	}
}

/// Production documentation generation -- Common code for HTML and PDF formats.
/// See the description for methods CreateDocumentHTML and CreateDocumentPDF in class <class>Ens.Config.Production</class>.<br>
/// The parameter <parameter>pAllSettings</parameter> defaults to 0 but if set to 1
/// all settings including default values for a host item will be included.<br> 
/// 
ClassMethod CreateDoc(pProduction As %String = "", pIntro As %Boolean = 1, pFormat As %String, Output LogFileName As %String, Output URL As %String, Output BookName As %String, PDFFileName As %String = "", PDFRenderer As %String = "", ByRef Params As %String, pAllSettings As %Boolean = 0) As %Status
{
	Set LogFileName = ""
	Set URL = ""
	Set BookName = ""

	If $system.Version.GetBuildOS()="VMS" Quit $$$ERROR($$$GeneralError,"Not available on VMS")

	Set LogFile = ""
	Set TempDir = ##class(%File).GetDirectory(##class(%File).TempFilename())
	Set tSC = $$$OK

	// If PDF, check renderer
	If pFormat="PDF" {
		If ($G(PDFRenderer) = "") {
			If $G(^%SYS("zenreport","transformerpath"))'="" {
				Set PDFRenderer=^%SYS("zenreport","transformerpath")
			} 
			ElseIf (##class(%File).Exists($$$fopbat)) {
				Set PDFRenderer=$$$fopbat
			} 
			Else {
				Quit $$$ERROR($$$GeneralError,"You must set ^%SYS(""zenreport"",""transformerpath"") to the location of your PDF transformer.")
		    }
		}
	}
	
	// Check Production class
	If pProduction="" Quit $$$ERROR($$$EnsErrGeneral, "A Production class must be provided")
	If '..IsA(pProduction, "Ens.Production") Quit $$$ERROR($$$EnsErrGeneral, "'"_pProduction_"' is not a Production class")

	Try {
		Set ProductionFileName = ""
		Set ProductionExportName = ""
		Set SchemasFileName = ""
		Set RulesFileName = ""
		Set RulesExportName = ""
		Set TransformsFileName = ""
		Set TransformsExportName = ""
		Set Mode = ..GetRecordMode()

		// Assign a book name and a file name for the book and for the log
		Set BookFileName = ""
		Do ..BookName(pProduction, .BookName, .BookFileName, .LogFileName)

		// Create the log file
		Set LogFile = ##class(%File).%New(LogFileName)
		Do LogFile.Open("WN"_Mode)
		Do LogFile.WriteLine("Generating documentation for Production '"_pProduction_"'")
		Do LogFile.WriteLine("Format: "_pFormat_" - Include introduction: "_$S(pIntro:"Yes",1:"No"))

		// Get collection of Production items
		Do LogFile.WriteLine("Invoking FindStudioProjectItems")
		Set tSC = ##class(Ens.Config.Production).FindStudioProjectItems(pProduction, .pItems)
		If 'tSC Quit

		// Parameters for XSLT
		Kill vparms

		// Include or not introduction / terminology chapter
		If 'pIntro Set vparms("intro") = "'false'"
		// Indicate in report if default settings included
		If pAllSettings Set vparms("allSettings") = "'true'"

		Set ProductionFileName = TempDir_BookName_"PRODMOD.XML"
		Set ProductionExportName = TempDir_BookName_"PRODEXP.XML"
		/*	Generate a pseudo Production class XData block inorder to be able
			to show all settings - ie class definition and defaults.
			If pAllSettings is false then only show what is in the production class
			but use any overridden/runtime static changes such as PoolSize
			that are specified in SDS table
		*/
		Set tSC = ..CreateProductionFileOptionalSDS(pProduction, ProductionFileName, LogFile, pAllSettings)
		If 'tSC Quit

		// Create temporary file with the Production's schemas
		Kill tSchemas
		For Type = "hl7", "ast" {
			Set Name = ""
			For {
				Set Name = $O(pItems(Type,Name))
				Quit:Name=""
				Set tSchemas(Name_"."_Type) = ""
			}
		}
		If $D(tSchemas) {
			Set SchemasFileName = TempDir_BookName_"SCHEMAS.XML"
			Do LogFile.WriteLine("Exporting schema definitions to temp file '"_SchemasFileName_"'")
			Set tSC = $system.OBJ.Export(.tSchemas, SchemasFileName, "-d")
			Set vparms("schema") = "'"_SchemasFileName_"'"
			Kill tSchemas
		}
		If 'tSC Quit

		// Create temporary files with the Production's rules export and rule definitions
		Kill tRules
		Set Name = ""
		For {
			Set Name = $O(pItems("rul",Name))
			Quit:Name=""
			// Determine if the Name is an alias or not, and use the class name
			Set RulesClassName = ##class(Ens.Projection.Rule).ResolveRuleAlias(Name)
			If RulesClassName="" Set RulesClassName = Name
			Set tRules(RulesClassName_".cls") = ""
		}
		If $D(tRules) {
			Set RulesExportName = TempDir_BookName_"RULEEXP.XML"
			Do LogFile.WriteLine("Exporting rules to temp file '"_RulesExportName_"'")
			Set tSC = $system.OBJ.Export(.tRules, RulesExportName, "-d")
			If 'tSC Quit
			Set RulesFileName = TempDir_BookName_"RULEMOD.XML"
			Do LogFile.WriteLine("Extracting rule definitions to temp file '"_RulesFileName_"'")
			Set tSC = ..CreateRulesFile(RulesExportName, RulesFileName)
			If 'tSC Quit
			Set vparms("rules") = "'"_RulesFileName_"'"
			Kill tRules
		}
		If 'tSC Quit

		// Create temporary files with the Production's transformations export and transformations summary definitions
		Kill tTransf
		Set Name = ""
		For {
			Set Name = $O(pItems("cls",Name))
			Quit:Name=""
			If ..IsA(Name,"Ens.DataTransform") Set tTransf(Name_".cls") = ""
		}
		If $D(tTransf) {
			Set TransformsExportName = TempDir_BookName_"TRANSFEXP.XML"
			Do LogFile.WriteLine("Exporting data transformations to temp file '"_TransformsExportName_"'")
			Set tSC = $system.OBJ.Export(.tTransf, TransformsExportName, "-d")
			If 'tSC Quit
			Set TransformsFileName = TempDir_BookName_"TRANSFMOD.XML"
			Do LogFile.WriteLine("Extracting data transformation definitions to temp file '"_TransformsFileName_"'")
			Set tSC = ..CreateTransformsFile(TransformsExportName, TransformsFileName)
			If 'tSC Quit
			Set vparms("xforms") = "'"_TransformsFileName_"'"
			Kill tTransf
		}
		If 'tSC Quit

		// Run the first XSLT
		#dim xslFileLocation = $system.Util.InstallDirectory()
		Set CSPDir = $S($$$isUNIX:"csp",1:"CSP")
		For tDirPiece = CSPDir,"enslib","xsl" {
			Set xslFileLocation = ##class(%Library.File).SubDirectoryName(xslFileLocation,tDirPiece,1)
		}
		Set XSLFileName = xslFileLocation_"ProductionDocBook"_pFormat_".xsl"
		Set vparms("name") = "'"_BookName_"'"
		Do LogFile.WriteLine("Performing XSLT '"_XSLFileName_"'")
		Do LogFile.WriteLine("   to create output file '"_BookFileName_"'")
		If $G(^Ens.DebugDoc) {
			Do LogFile.WriteLine("Executing: Set tSC = ##class(%XML.XSLT.Transformer).TransformFile("""_ProductionFileName_""", """_XSLFileName_""", """_BookFileName_""", , .vparms)")
		}
		Set tSC = ##class(%XML.XSLT.Transformer).TransformFile(ProductionFileName, XSLFileName, BookFileName, , .vparms)
		If 'tSC Quit

		If pFormat="HTML" {

			Set tSC = ..createHTMLDocStream(BookFileName, xslFileLocation, pProduction, LogFile , .vparms)
			If 'tSC Quit

			// URL to display the HTML document
			Set URL = ..BuildURL(..getHTMLDocStreamOID(pProduction))
		}

		If pFormat="PDF" {
			// Run the second XSLT to generate a PDF file
			Set CSPName = $system.Util.InstallDirectory()
			Set CSPDir = $S($$$isUNIX:"csp",1:"CSP")
			For tDirPiece = CSPDir,"enslib","xsl" {
				Set CSPName = ##class(%Library.File).SubDirectoryName(CSPName,tDirPiece,1)
			}
			Set PDFXSLFileName = CSPName _ "DocBookPDFSimple.xsl"
			Set PDFFileName = ##class(%File).NormalizeFilename(PDFFileName)
			Set PDFFile = ##class(%File).%New(PDFFileName)
			Set tSC = PDFFile.Open("WN"_Mode)
			If 'tSC Do LogFile.WriteLine("Ensure you have sufficient privileges to write to file '"_PDFFileName_"'") Quit
			Do PDFFile.Close()

			// Prepare the string of XSL parameters for DocBookPDFSimple.xsl
			// Note that FOP and XEP require slightly different syntax for the name-value pairs
			// Default logo is $$$LOGO1
			// (To do: Make it compatible with VMS after resolution of current XSLT issues on that platform)
			If '$D(Params("logo-image")) {

				Set XMLName = $system.Util.InstallDirectory()
				If $$$isWINDOWS {
					Set XMLName = $TR(XMLName,"\","/")
				}
				Set CSPDir = $S($$$isUNIX:"csp",1:"CSP")
				For tDirPiece = CSPDir,"broker" {
					Set XMLName = XMLName_tDirPiece_"/"
				}
				Set Params("logo-image") = XMLName_$$$LOGO1
				If '##class(%Library.File).Exists(Params("logo-image")) Kill Params("logo-image")

			}

			Set ParamString = ""
			Set Connect = $S($ZCVT(PDFRenderer,"l")["fop":" ",1:"=")
			For p = "logo-image", "title-color", "href-color", "logo-name", "logo-address1", "logo-address2", "logo-citystatezip", "logo-website" {
				If $D(Params(p)) Set ParamString = ParamString_" -param "_p_Connect_""""_Params(p)_""""
			}

			Do LogFile.WriteLine("Generating PDF file '"_PDFFileName_"'")
			Do LogFile.WriteLine("using XSLT '"_PDFXSLFileName_"'")
			Do LogFile.WriteLine("with PDF renderer '"_PDFRenderer_"'")
			Do LogFile.WriteLine("passing these parameters: "_ParamString)

			// note that this command string is a prediction, because $zf(-100) does not accept the full OS command as a single string.
			// the audit log will contain the actual command string.
			Set cmdStr = PDFRenderer_" -xml "_BookFileName_" -xsl "_PDFXSLFileName_" -pdf "_PDFFileName_ParamString_" 2>&1"
			Do LogFile.WriteLine("Note: If the PDF renderer fails, check if Java is properly configured for the current user '"_$Username_"'.")
			Do LogFile.WriteLine("Executing: "_cmdStr)

			Set cmd = PDFRenderer
			Set cmdArgs = ""
			Set cmdArgs($increment(cmdArgs)) = "-xml"
			Set cmdArgs($increment(cmdArgs)) = BookFileName
			Set cmdArgs($increment(cmdArgs)) = "-xsl"
			Set cmdArgs($increment(cmdArgs)) = PDFXSLFileName
			Set cmdArgs($increment(cmdArgs)) = "-pdf"
			Set cmdArgs($increment(cmdArgs)) = PDFFileName

			#; Quote the necessary -param name values.
			#dim tParamValue = ""
			For p = "logo-image", "title-color", "href-color", "logo-name", "logo-address1", "logo-address2", "logo-citystatezip", "logo-website" {
				Continue:'$D(Params(p))

				Set cmdArgs($increment(cmdArgs)) = "-param"

				If p="logo-image" {

					/*	Don't quote or NormalizeFilenameWithSpaces the logo-image file name.

						Format of file path given by: 

							https://xmlgraphics.apache.org/fop/fo.html#external-resources
								src="url('file:d:///images/logo.jpg')

						DocBookPDFSimple.xsl prepends file: to the url spec. Need to ensure 3 forward slashes

						logo-image could have been passed in so need to check if already have three /
					*/

					Set tParamValue = Params(p)

					If $E(tParamValue)="/" {

						If $E(tParamValue,2)'="/" Set $E(tParamValue)="///"

					} ElseIf $E(tParamValue,2,3)=":/" {

						If $E(tParamValue,4)'="/" Set $E(tParamValue,2,3)=":///"

					}

				} Else {

					Set tParamValue = """"_Params(p)_""""

				}

				If (Connect=" ") {
					Set cmdArgs($increment(cmdArgs)) = p
					Set cmdArgs($increment(cmdArgs)) = tParamValue
				} Else {
					Set cmdArgs($increment(cmdArgs)) = p_Connect_tParamValue
				}

			}

			Kill tFile, ret, tRetCode
			Set tSC = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, .tFile, .ret, 300, 1, .tRetCode, .cmdArgs)
			Do LogFile.WriteLine("PDF renderer terminated with code: "_$G(tRetCode)_$S($G(tRetCode)=0:" (success)",1:" (ERROR)"))
			If +$G(tRetCode) {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"PDF renderer terminated with error code: "_tRetCode)
			}
			If $G(ret)="" {
				Do LogFile.WriteLine("PDF renderer did not return any output")
			}
			Else {
				Do LogFile.WriteLine("PDF renderer returned:")
				Do LogFile.WriteLine(ret)
			}
			Do LogFile.WriteLine("")
			If 'tSC Quit
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}

	If $IsObject(LogFile) {
		If tSC {
			Do LogFile.WriteLine("Done!")
		}
		Else {
			Do LogFile.WriteLine("Error: "_$system.Status.GetErrorText(tSC))
		}
		Do LogFile.Close()
	}

	// Cleanup temp files, but only if there wasn't an error, as the files may be useful for trouble-shooting
	// and will be deleted upon next system restart anyway.  If ^Ens.DebugDoc=1 the temp files are not deleted.
	If tSC && '$G(^Ens.DebugDoc) {
		For file = ProductionFileName, ProductionExportName, SchemasFileName, RulesExportName, RulesFileName, TransformsFileName, TransformsExportName, BookFileName {
			If file'="" Do ##class(%File).Delete(file)
		}
		If pFormat="HTML" {
			Do ##class(%File).Delete(LogFileName)
			Set LogFileName = ""
		}
	}

	Quit tSC
}

/// Create a file with just the Production definition, skipping other items.
/// Deprecated in favour of using CreateProductionFileOptionalSDS and using pIncludeDefaultSettings parameter as 0
ClassMethod CreateProductionFile(InFile As %String, OutFile As %String) [ Deprecated, Internal ]
{
	Set tSC = $$$OK

	Try {
		Set Mode = ..GetRecordMode()

		// Create output file
		Set File = ##class(%File).%New(OutFile)
		If $IsObject(File), File.%IsA("%File")
		Else  Set tSC = $$$ERROR($$$EnsErrGeneral, "Unable to create file to write Production definition to") Quit
		Do File.Open("WN"_Mode_"K\UTF8\")

		// Open input file
		Set File2 = ##class(%File).%New(InFile)
		Do File2.Open("R"_Mode_"K\UTF8\")

		// Copy the first and second lines <?xml ...> and <Export ...>
		Do File.WriteLine(File2.ReadLine())
		Do File.WriteLine(File2.ReadLine())

		// Find "<Production ...>" line
		Do {
			Set Line = File2.ReadLine()
			If Line?1"<Data><![CDATA[<Production ".e Set Line = $E(Line,$F(Line,"CDATA["),*)
		} While (Line'?1"<Production ".e && 'File2.AtEnd)
		If File2.AtEnd Set tSC = $$$ERROR($$$EnsErrGeneral, "Tag <Production ...> not found within Production class export file") Quit

		// Copy until "</Production>" is found
		Do {
			Do File.WriteLine(..UnescapeCDATA(Line))
			Set Line = File2.ReadLine()
		} While (Line'["</Production>" && 'File2.AtEnd)

		Do File.WriteLine($E(Line,1,$F(Line,"</Production>")-1))
		Do File.WriteLine("</Export>")
		Do File.Close()
		Do File2.Close()
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC

	/*
	Sample XData block:
	<XData name="ProductionDefinition">
	<Data><![CDATA[
	<Production Name="Demo.HL7.MsgRouter.Production" LogGeneralTraceEvents="false">
	<ActorPoolSize>1</ActorPoolSize>

	</Production>
	]]></Data>
	</XData>

	Sample XData block on Japanese box:
	<XData name="ProductionDefinition">
	<Data><![CDATA[<Production Name="Toshi.Package.ToshiClass">
	 <ActorPoolSize>2</ActorPoolSize>

	</Production>
	]]></Data>
	</XData>

	Sample export file on VMS:
	<?xml version="1.0" encoding="UTF-8"?><Export generator="Cache" version="25" zv=
	"Cache for OpenVMS/ALPHA V8.4 (Alpha) 2012.1 (Build 554U)" ts="2012-01-18 21:10:
	46"><Class name="Demo.RecordMap.Production"><ProcedureBlock>1</ProcedureBlock><S
	uper>Ens.Production</Super>
	<TimeChanged>62466,61384</TimeChanged><TimeCreated>61860,58884.126262</TimeCreat
	ed>
	<Production Name="Demo.RecordMap.Production" LogGeneralTraceEvents="false">
	  <Description>Sample Production to illustrate a simple input/output transformat
	ion using generated RecordMaps. NOTE: The source file, RecordMap.Delimited.Input
	.txt, and a sample output file, RecordMap.Delimited.Output.txt, should be locate
	d in [install_dir]/dev/RecordMap/.</Description>  <ActorPoolSize>2</ActorPoolSiz
	e>  <Item Name="Delimited.RecordMap.FileService" Category="" ClassName="EnsLib.R
	etc...
	*/
}

/// Create a file with just the data transformation definitions, skipping transformation code.
ClassMethod CreateTransformsFile(InFile As %String, OutFile As %String) [ Internal ]
{
	Set tSC = $$$OK

	Try {
		Set Mode = ..GetRecordMode()

		// Create output file
		Set File = ##class(%File).%New(OutFile)
		If $IsObject(File), File.%IsA("%File")
		Else  Set tSC = $$$ERROR($$$EnsErrGeneral, "Unable to create file to write data transformation definitions to") Quit
		Do File.Open("WN"_Mode_"K\UTF8\")

		// Open input file
		Set File2 = ##class(%File).%New(InFile)
		Do File2.Open("R"_Mode_"K\UTF8\")

		// Copy the first and second lines
		Do File.WriteLine(File2.ReadLine())
		Do File.WriteLine(File2.ReadLine())

		// Copy lines that start with tags Class or transform
		Do {
			Set Line = File2.ReadLine()
			If Line?1"<Class ".e Do File.WriteLine("<Document "_$E(Line,8,*))
			If Line?1"<transform ".e Do File.WriteLine(Line)
			If Line?1"</transform>".e Do File.WriteLine("</transform>")
			If Line?1"</Class>".e Do File.WriteLine("</Document>")
		} While 'File2.AtEnd

		Do File.WriteLine("</Export>")
		Do File.Close()
		Do File2.Close()
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Create a file with just the rule definitions, skipping rule class code.
ClassMethod CreateRulesFile(InFile As %String, OutFile As %String) [ Internal ]
{
	Set tSC = $$$OK
	
	Try {
		Set Mode = ..GetRecordMode()

		// Create output file
		Set File = ##class(%File).%New(OutFile)
		If $IsObject(File), File.%IsA("%File")
		Else  Set tSC = $$$ERROR($$$EnsErrGeneral, "Unable to create file to write rule definitions to") Quit
		Do File.Open("WN"_Mode_"K\UTF8\")
		
		// Open input file
		Set File2 = ##class(%File).%New(InFile)
		Do File2.Open("R"_Mode_"K\UTF8\")
		
		// Copy the first and second lines
		Do File.WriteLine(File2.ReadLine())
		Do File.WriteLine(File2.ReadLine())

		Set RuleDefFound = 0
		Do { 
			Set Description = ""
			Set KeepDescribing = 1
			Do { 
				Set Line = File2.ReadLine()
				If $F(Line,"<ruleDefinition") { // Start the next rule definition
					Set FirstLine = 1 
					Set RuleDefFound = 1
				}
				If Line?1"<Class name=".e Set ClassName = $P(Line,"""",2) // Store the class name until later
				If Line?1"<Description>".e { // Store the description tag and its contents until later
					Do { 
						Set Description = Description _ " " _ Line 
						If $F(Line,"</Description>") { 
							Set KeepDescribing = 0 
						}
						Set Line = File2.ReadLine()
					} While (KeepDescribing && 'File2.AtEnd)
				}
				If Line?1"<Data><![CDATA[<ruleDefinition".e Set Line = $E(Line,$F(Line,"CDATA["),*)
			} While (Line'?1"<ruleDefinition".e && 'File2.AtEnd)
			If (File2.AtEnd && 'RuleDefFound) Set tSC = $$$ERROR($$$EnsErrGeneral, "Rule definition tag not found within rule export file") Quit
		
			// Copy until "</ruleDefinition>" is found
			Do {
				If (FirstLine) {
					Do File.WriteLine($E(Line,1,$F(Line,"<ruleDefinition ")-1) _ "class=""" _ ClassName _ """ " _ ..UnescapeCDATA($E(Line,$F(Line,"<ruleDefinition "),*)))
					Do File.WriteLine(Description)
					Set FirstLine = 0
				}
				Else {
					Do File.WriteLine(..UnescapeCDATA(Line))
				}
				Set Line = File2.ReadLine()
			} While (Line'["</ruleDefinition>" && 'File2.AtEnd)
	
			Do File.WriteLine($E(Line,1,$F(Line,"</ruleDefinition>")-1))
		
		} While 'File2.AtEnd
	
		Do File.WriteLine("</Export>")
		Do File.Close()
		Do File2.Close()
	}
	
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Unescape a CDATA block in case it was escaped upon export.
ClassMethod UnescapeCDATA(line As %String) As %String [ Internal ]
{
	Set pos = 1
	For  {
		Set pos = $F(line,"]]]]><![CDATA[>",pos)
		Quit:'pos
		Set line = $E(line,1,pos-16)_"]]>"_$E(line,pos,$L(line))
	}
	Quit line
}

ClassMethod IsA(pClass As %String, pType As %String) As %Boolean [ Internal ]
{
	If $$$comMemberKeyGet(pClass,$$$cCLASSmethod,"%IsA",$$$cMETHrunnable), $ZObjClassmethod(pClass,"%IsA",pType) Quit 1
	Quit 0
}

/// Choose a book name and file name for the book and for the log, based on a CRC of the namespace and production name.
/// The files are temporary, they will be created in the system's temp directory.
ClassMethod BookName(pProduction As %String, Output BookName As %String, Output BookFileName As %String, Output LogFileName As %String)
{
	Set Dir = ##class(%File).GetDirectory(##class(%File).TempFilename()) // Temp dir
	Set BookName = "DOC"_$ZCRC($namespace_pProduction,7)
	Set BookFileName = Dir_BookName_".XML"
	Set LogFileName = Dir_BookName_".LOG"
	Quit
}

/// Fits the given name into the target size.
/// Parameter pRemoveList may optionally contain a comma delimited list of strings to be removed, such as "Production,Message".
ClassMethod FitName(pName As %String = "", pSize As %Integer = 35, pRemoveList = "") As %String [ Internal ]
{
	If pSize<1 Quit ""
	Set tOut = $ZStrip(pName,"*PC")
	For n = 1:1:$L(pRemoveList,",") {
		Set tStr = $P(pRemoveList,",",n)
		If tStr = "" Continue
		For {
			Set i = $F($ZCVT(tOut,"l"),$ZCVT(tStr,"l"))
			Quit:'i
			Set t = $E(tOut,1,i-$L(tStr)-1)_$E(tOut,i,*)
			Quit:t=""
			Set tOut = t
		}
	}
	If $L(tOut)>pSize {
		Set tCRC = $ZCRC(pName,6)
		Set tLen = pSize-6
		
	}
	Quit tOut
}

ClassMethod VMSRemoveMachineName(FileLocation As %String) As %String [ Internal ]
{
	If $$$isVMS && (FileLocation[":") {
		// Remove machine name to avoid parsing troubles in cases such as _$2$DKA0:[...]
		Set SysDr = $P(FileLocation,":",1)
		Set Dr = $P(SysDr,"$",$L(SysDr,"$"))
		Set FileLocation = Dr_":"_$P(FileLocation,":",2,$L(FileLocation,":"))
	}
}

/// Converts a VMS full file spec to a file URL format.
/// Example: "_MACHINE$DKA0:[HCR122.MGR.TEMP]DOC1081268018TRANSFMOD.XML" becomes "_MACHINE$DKA0/HCR122/MGR/TEMP/DOC1081268018TRANSFMOD.XML"
ClassMethod BuildVMSFileURL(pFile As %String) As %String [ Internal ]
{
	If $G(pFile)="" Quit ""
	//Quit "URL:file:///"_$P(pFile,":",2)
	Set disk = $P(pFile,":",1)
	Set pf = $P(pFile,":",2)
	Set file = $P(pFile,"]",2)
	Set dirs = $P($P(pf,"]",1),"[",2)
	Set URL = "URL:file://localhost/DKA0/" //_disk_"/" // "URL:file:///"_$P(disk,"$",2)_"/" //_disk_"/"
	For i = 1:1:$L(dirs,".") Set URL = URL_$P(dirs,".",i)_"/"
	Set URL = URL_file
	Quit URL
}

/// Return a boolean value indicating if the production documentation already exists.
ClassMethod CheckDocExists(ProductionClass As %String, ByRef pHTMLDocStreamOID) As %Boolean
{

	#dim Exists = 0

	If $G(ProductionClass)="" Quit 0

	If $Get(pHTMLDocStreamOID) '= "" {

		Set pHTMLDocStreamOID = ..getHTMLDocStreamOID(ProductionClass)
		If $G(pHTMLDocStreamOID)="" Quit 0

	}

	Set Exists = ##class(%Stream.Object).%Exists(pHTMLDocStreamOID)

	Quit Exists
}

/// Internal method - deprecated.
/// See CreateProductionFileOptionalSDS()
ClassMethod CreateProductionFileWithAllSettings(pProduction As %String, pProductionFileName As %String, pLogFile, pIncludeDefaultSettings As %Boolean = 1) As %Status [ Deprecated, Internal ]
{
	Return ..CreateProductionFileOptionalSDS(pProduction, pProductionFileName, .pLogFile, 1)
}

/// Internal method to generate a pseudo Production class XData block containing all values from 
/// the production class or include all setting values - i.e. class definition and optional defaults.
/// Ensure overridden(runtime) static changes from SDS are used whether all settings are included or not.
ClassMethod CreateProductionFileOptionalSDS(pProduction As %String, pProductionFileName As %String, pLogFile, pIncludeDefaultSettings As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tProductionObject, tClonedProductionObject As Ens.Config.Production
	#dim tItem As Ens.Config.Item
	#dim tFileObject As %Stream.FileCharacter
	#dim tSettingsCounter, tItemsCounter
	#dim tList, tListCounter

	Try {

		If $G(^Ens.DebugDoc) {
			Do pLogFile.WriteLine("Process free memory prior to XML generation: "_$S)
		}

		Set tFileObject=##class(%Stream.FileCharacter).%New()
		Set tFileObject.TranslateTable="UTF8"
		Set tSC = tFileObject.LinkToFile(pProductionFileName)
		If $$$ISERR(tSC) Quit

		Set tProductionObject = ##class(Ens.Config.Production).%OpenId(pProduction,0,.tSC)
		If $$$ISERR(tSC) Quit

		Set tClonedProductionObject=tProductionObject.%ConstructClone(1) // Want clone of items as well.
		#; Get overridden/runtime values from SDS and use those
		Do tClonedProductionObject.GetStaticSettings(.tList,0)
		For tListCounter=1:1 {
			If '$Data(tList(tListCounter)) Quit
			If $List(tList(tListCounter),$$$ensStaticSource)=$$$eConfigSettingValueTypeSystem {
				Set $property(tClonedProductionObject,$List(tList(tListCounter),$$$ensStaticName))=$List(tList(tListCounter),$$$ensStaticValue)
			}
		}
		Kill tList
		If pIncludeDefaultSettings {
			Do tClonedProductionObject.PopulateModifiedSettings()
			For tSettingsCounter=1:1:tClonedProductionObject.ModifiedSettings.Count() {
				Do tClonedProductionObject.Settings.SetAt(tClonedProductionObject.ModifiedSettings.GetAt(tSettingsCounter),tSettingsCounter)
			}
		}
		For tItemsCounter=1:1:tClonedProductionObject.Items.Count() {
			Set tItem=tClonedProductionObject.Items.GetAt(tItemsCounter)
			If pIncludeDefaultSettings {
				Do tItem.PopulateModifiedSettings()
				For tSettingsCounter=1:1:tItem.ModifiedSettings.Count() {
					Do tItem.Settings.SetAt(tItem.ModifiedSettings.GetAt(tSettingsCounter),tSettingsCounter)
				}
			}
			#; Get overridden/runtime values and use those.
			Do tItem.GetStaticSettings(.tList,0)
			For tListCounter=1:1 {
				If '$Data(tList(tListCounter)) Quit
				If $List(tList(tListCounter),$$$ensStaticSource)=$$$eConfigSettingValueTypeSystem {
					Set $property(tItem,$List(tList(tListCounter),$$$ensStaticName))=$List(tList(tListCounter),$$$ensStaticValue)
				}
			}
			Kill tList
		}
		Do tFileObject.WriteLine("<?xml version=""1.0"" encoding=""UTF-8""?>")
		#dim tInfoObject = $$$NULLOREF
		#dim tVersion = ""
		Set tSC = ##class(%CSP.UI.Portal.API).GetSystemInfo(.tInfoObject)
		If $$$ISERR(tSC) {
			Set tVersion = $zcvt($zv,"O","XML")
		} Else {
			Set tVersion = $zcvt(tInfoObject.CacheVerStr,"O","XML")
		}
		#dim tLocalTimeStamp = $zdatetime($zdatetimeh($ztimestamp,-3),3)
		Do tFileObject.WriteLine("<Export zv='"_tVersion_"' ts='"_tLocalTimeStamp_"'>")
		Do tClonedProductionObject.XMLExportToStream(.tFileObject)
		Do tFileObject.WriteLine("</Export>")
		set tSC= tFileObject.%Save()

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If $G(^Ens.DebugDoc) {
		Do pLogFile.WriteLine("Process free memory after XML generation: "_$S)
	}

	Kill tClonedProductionObject

	Quit tSC
}

/// Internal method to create the HTML report stream using XSLT and persist in an <class>Ens.Util.ProdHTMLReport</class>
ClassMethod createHTMLDocStream(pSourceXMLDocument As %String, pXSLFileLocation As %String, pProduction As %String, pLogFile As %Stream.Object, ByRef pParms As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim XSLFileName = pXSLFileLocation_"ProductionDocBookFinalHTML.xsl"

		#dim vparms
		#dim tXSLStream
		#dim xslURL="file:///"_pXSLFileLocation_"ProductionDocBookFinalHTML.xsl"
		Set tSC=##class(Ens.Util.URLStream).GetURLStream(xslURL,.tXSLStream)
		If $$$ISERR(tSC) Quit
		#dim tSourceDocument = ##class(%Stream.FileBinary).%New()
		Do tSourceDocument.LinkToFile(pSourceXMLDocument)
		#dim tHTMLStream = ##class(%Stream.TmpBinary).%New()

		If $Data(pLogFile) && $IsObject(pLogFile) {
			Do pLogFile.WriteLine("Performing XSLT '"_XSLFileName_"'")
			Do pLogFile.WriteLine("   to create HTML Stream")
			If $G(^Ens.DebugDoc) {
				Do pLogFile.WriteLine("Executing: Set tSC = ##class(%XML.XSLT.Transformer).TransformStream("""_pSourceXMLDocument_""", """_xslURL_""", """_tHTMLStream_""", , .vparms)")
			}
		}

		Do ..populateProductData(.pParms)

		Set tSC=##class(%XML.XSLT.Transformer).TransformStream(tSourceDocument,tXSLStream,.tHTMLStream,,.pParms)
		If $$$ISERR(tSC) Quit

		Set tSC = ..storeProductionHTMLDoc(pProduction, tHTMLStream, .pParms)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Internal helper method for logo in HTML Report
ClassMethod populateProductData(ByRef pParms As %String) [ Internal ]
{
	Try {

		#dim tProductLogo
		#dim tProduct = "InterSystems IRIS"
		Set tProductLogo = $$$LOGO1
		#dim tInstalledProduct = $System.Version.GetISCProduct()

		If tInstalledProduct = $$$HealthShareProductKey {
			Set tProduct = "HealthShare"
			Set tProductLogo = $$$PRODUCT3LOGO
		}

		If tProduct'="" Set pParms("product") = "'"_tProduct_"'"
		If tProductLogo'="" Set pParms("productLogo") = "'"_tProductLogo_"'"

	} Catch {}
}

/// Internal Persist HTML report created for the production and record OID
ClassMethod storeProductionHTMLDoc(pProduction As %String, pHTMLTmpStream As %Stream.TmpBinary, ByRef pParms As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tHTMLReportObject As Ens.Util.ProdHTMLReport

	Try {
		If ##class(Ens.Util.ProdHTMLReport).%ExistsId(pProduction) {

			Set tHTMLReportObject = ##class(Ens.Util.ProdHTMLReport).%OpenId(pProduction,,.tSC)
			If $$$ISERR(tSC) Quit

			/* If more than a day since last generation then check to see if only differ in generation time
				- protects against runaway data updates/journal creation
			*/
			#dim tSecondsSinceLastGeneration = $$HorologDiff^EnsUtil($ztimestamp,tHTMLReportObject.GenerationDateUTCH)
			If ((tSecondsSinceLastGeneration>0)&&(tSecondsSinceLastGeneration<86400)) {
				If ..reportsTheSame(tHTMLReportObject.Report,pHTMLTmpStream) Quit
			}

			#; Delete prior report
			#dim tPriorStreamOID = tHTMLReportObject.Report.%Oid()
			If (tPriorStreamOID '= "") {
				Try {Do ##class(%Stream.Object).%Delete(tPriorStreamOID)} Catch {}
			}

		} Else {
			Set tHTMLReportObject = ##class(Ens.Util.ProdHTMLReport).%New(pProduction)
		}

		#; Create a new report stream object this way to use location specified in the object
		Do tHTMLReportObject.ReportNewObject()  $$$ASSERT($IsObject(tHTMLReportObject.Report))

		Set tSC = tHTMLReportObject.Report.CopyFrom(pHTMLTmpStream)
		If $$$ISERR(tSC) Quit
		Set tHTMLReportObject.Report.ContentType="text/html"
		#; Do not want to double convert utf-8 when serve
		Set tHTMLReportObject.Report.CharSet="raw"
		Set tSC = tHTMLReportObject.Report.%Save()
		If $$$ISERR(tSC) Quit
		Kill pHTMLTmpStream

		Set tHTMLReportObject.GenerationDateUTCH = $ztimestamp
		Set tHTMLReportObject.Username = $Username
		If ($Get(pParms("allSettings"))="'true'") {
			Set tHTMLReportObject.IncludeDefaultSettings = 1
		} Else {
			Set tHTMLReportObject.IncludeDefaultSettings = 0
		}
		Set tSC = tHTMLReportObject.%Save()
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Return tSC
}

/// Internal method to try to identify if report has not changed to avoid persisting/journalling.
ClassMethod reportsTheSame(pExistingReport As %CSP.BinaryStream, pNewReport As %Stream.TmpBinary) As %Boolean [ Internal, Private ]
{
	#dim reportsTheSame = 0
	If (pExistingReport.Size=pNewReport.Size) {
		/*
			Reports are the same if only differ in the generation time.
			We count as different if instance version different as well as other contents.
		*/
		#dim section = 0
		Do pExistingReport.Rewind()
		Do pNewReport.Rewind()
		Set reportsTheSame = 1
		While 'pExistingReport.AtEnd {
			Do $Increment(section)
			If section=1 {
				#dim tExistFirstRead = pExistingReport.Read()
				#dim tNewFirstRead = pNewReport.Read()
			} Else {
				If (pExistingReport.Read()'=pNewReport.Read()) {
					Set reportsTheSame = 0
					Quit
				}
			}
		}
		Do pExistingReport.Rewind()
		Do pNewReport.Rewind()
		If reportsTheSame {
			#; Check if first section differs only in time
			#dim tExistCheckFrom = $Find(tExistFirstRead,"InterSystems IRIS Release Label")
			#dim tNewCheckFrom = $Find(tNewFirstRead,"InterSystems IRIS Release Label")
			If $Extract(tExistFirstRead,tExistCheckFrom,*)'=$Extract(tNewFirstRead,tNewCheckFrom,*) Set reportsTheSame = 0
		}
	}
	Return reportsTheSame
}

/// Return the OID of the HTML report stream so that it can be streamed
ClassMethod getHTMLDocStreamOID(pProduction As %String) As %String [ Internal ]
{
	#dim oid = ""
	Try {
		Set oid =##class(Ens.Util.ProdHTMLReport).%OpenId(pProduction).Report.%Oid()
	} Catch {}
	Return oid
}

/// Method to retrieve last date the HTML report was created for a production to the minute. <br>
/// The default is to return the value escaped for HTML. <br>
/// Also returns the age in seconds in 3rd parameter and the user that generated.<br>
ClassMethod LastHTMLCreationDate(pProduction As %String = "", pOutputEscape As %String = "HTML", Output pAgeInSeconds = 0, Output pUser As %String) As %String
{
	If pProduction="" Return ""
	#dim tLastDateLocalDisplay = ""

	Try {
		#dim tHTMLReportObject = ##class(Ens.Util.ProdHTMLReport).%OpenId(pProduction)
		If '$IsObject(tHTMLReportObject) Quit

		#dim tLastDateUTCH = tHTMLReportObject.GenerationDateUTCH
		If tLastDateUTCH = "" Quit

		#; Do not show seconds
		Set tLastDateLocalDisplay = $zdatetime($zdatetimeh(tLastDateUTCH,-3),3,2)

		Set pAgeInSeconds = $$HorologDiff^EnsUtil($ztimestamp,tLastDateUTCH)\1

		If (tLastDateLocalDisplay '= "") {

			Set pUser = tHTMLReportObject.Username
			If (pOutputEscape'="") Set tLastDateLocalDisplay = $ZCVT(tLastDateLocalDisplay,"O",pOutputEscape)

		}

	} Catch {

		#; used to filter out invalid ts in H format
		Set tLastDateLocalDisplay = ""

	}

	Return tLastDateLocalDisplay
}

/// Internal method to obtain IncludeDefaultSettings value for report
ClassMethod LastHTMLIncludedDefaultSettings(pProduction As %String) As %Boolean [ Internal ]
{
	#dim tIncludes = ""
	Try {
		Set tIncludes = ##class(Ens.Util.ProdHTMLReport).%OpenId(pProduction).IncludeDefaultSettings
	} Catch {}
	Return tIncludes
}

/// Method to delete the HTML Report for a production in current namespace <br>
/// API to provide cleanup should it be needed. <br>
ClassMethod DeleteHTMLReport(pProduction As %String = "") As %Status
{
	Return ##class(Ens.Util.ProdHTMLReport).%DeleteId(pProduction)
}

}
