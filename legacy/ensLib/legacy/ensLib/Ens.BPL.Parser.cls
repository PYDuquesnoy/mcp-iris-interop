/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsErrors, %occSAX)

/// This class parses the BPL source and returns the root of the parse
/// tree that represents the Business Process Class
Class Ens.BPL.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the ^||%ISC.Ens.BPLData key where the parsed BPL data is found
Property Key As %Integer [ Private ];

/// This holds the ActivityID counter
Property ActivityCount As %Integer [ InitialExpression = 0 ];

/// This is the entry point to the parser, a stream containing the XML BPL
/// definition is passed and an instance of Ens.BPL.Process is returned. Validation
/// of the XML is performed according to the associated schema (see Ens.BPL.Schema)
/// On Success an instance of Ens.BPL.Process is returned. On failure, the status
/// code contains one or more error codes. In the case of an 'Invalid BPL' error,
/// additional information form the Schema Validator will be contained in the return
/// status
Method ParseStream(pStream As %BinaryStream, Output pProcess As Ens.BPL.Process) As %Status
{
	Set tSC=$$$OK
	Try {
		
		#; Create an XML import handler
		Set tHandler=##class(%XML.ImportHandler).%New("IRIS.Temp",$$$IntHandler) 
		$$$ASSERT($IsObject(tHandler))
 	
 		#; Create the Entity Resolver
 		Set tResolver=##class(Ens.Util.XML.XDataEntityResolver).%New("Ens.Schema.BPL")
 		$$$ASSERT($IsObject(tResolver))
 	
		#; Parse the XML data in the specfied stream
		Set tSC=##Class(%XML.SAX.Parser).ParseStream(pStream,tHandler,tResolver,,,"Schema")
		If $$$ISERR(tSC) Quit		
	
		#; Copy tree because handler will delete it's copy when it goes out of scope
		Set ..Key=$Increment(^||%ISC.Ens.BPLData) Merge ^||%ISC.Ens.BPLData(..Key)=@tHandler.DOMName@(tHandler.Tree)
		
		If $Data(^||%ISC.Ens.BPLData(..Key,"error"))||($Data(^||%ISC.Ens.BPLData(..Key,"warning"))) {
			Set tSC=..CollectBPLErrors()
			Quit
		}
		
		Set tSC=..parseProcess(.pProcess)
		
	}
	Catch {
		Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	If ..Key '= "" Kill ^||%ISC.Ens.BPLData(..Key)
	Quit tSC
}

/// Parse the Process
Method parseProcess(Output pProcess As Ens.BPL.Process) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Create the class
		Set tProcess=##class(Ens.BPL.Process).%New()
		$$$ASSERT($IsObject(tProcess))
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,1)="process")
			
		#; Set the (optional) language
		Set tProcess.Language=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","language"),tProcess.Language)
		
		#; Get the (mandatory) request type
		Set tProcess.Request=^||%ISC.Ens.BPLData(..Key,1,"a","request")
		
		#; Get the (optional) response type
		Set tProcess.Response=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","response"))
		
		#; Get the (optional) component
		Set tProcess.Component=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","component"))
		
		#; Get the (optional) contextsuperclass
		Set tProcess.ContextSuperClass=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","contextsuperclass"))
		
		#; Get the Version
		Set tProcess.Version=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","version"))
		
		#; Get the (optional) includes
		Set tProcess.Includes=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","includes"))
		
		#; Get the (optional) height
		Set tProcess.Height=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","height"))
		
		#; Get the (optional) width
		Set tProcess.Width=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","width"))
		
		#; Get the (optional) layout
		Set tProcess.Layout=$Get(^||%ISC.Ens.BPLData(..Key,1,"a","layout"))

		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,1,"c",""))
		while tChild'="" {
			
			#; Children can only be elements
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,1,"c",tChild)="e")
			
			#; Pick out type of the child
			Set tType=^||%ISC.Ens.BPLData(..Key,tChild)
			If tType="context" {
				
				#; Parse the context
				Set tSC=..parseContext(.tContext,tChild,tProcess)
				If $$$ISERR(tSC) Quit
		
				$$$ASSERT($IsObject(tContext))
	
				#; Fix up relationships
				Set tProcess.Context=tContext,tContext.Parent=tProcess
				
			} elseif tType="sequence" {
				
				Set tSC=..parseSequence(.tSequence,tChild,tProcess)
				If $$$ISERR(tSC) Quit
				
				$$$ASSERT($Isobject(tSequence))
				
				#; Fix up relationships
				Set tProcess.Sequence=tSequence,tSequence.Parent=tProcess
			} elseif tType="pyFromImport" {
				set tProcess.PyFromImport=..ParsePyFromImport(tChild)
			} else {
				$$$ASSERT("0:Unrecognized")
			}
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,1,"c",tChild))	
		}
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pProcess=tProcess
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCatch(Output pCatch As Ens.BPL.Catch, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="catch")
		
		#; Create a catch
		Set tCatch=##class(Ens.BPL.Catch).%New()
		$$$ASSERT($IsObject(tCatch))
		
		#; Get the mandatory Filter
		Set tCatch.Fault=^||%ISC.Ens.BPLData(..Key,pIndex,"a","fault")
			
		#; Fix up relationship
		Set tCatch.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tCatch,pIndex,.tStartChild)
		
		#; A catch just contains a (possibly empty) list of activities
		Set tSC=..parseActivities(tCatch.Activities,pIndex,tCatch,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pCatch=tCatch
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCatchAll(Output pCatchAll As Ens.BPL.CatchAll, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="catchall")
		
		#; Create a catchall
		Set tCatchAll=##class(Ens.BPL.CatchAll).%New()
		$$$ASSERT($IsObject(tCatchAll))
		
		#; Fix up relationship
		Set tCatchAll.Parent=pParent
		#; Parse the common attributes
		Do ..ParseActivity(tCatchAll,pIndex,.tStartChild)
		
		#; A catch just contains a (possibly empty) list of activities
		Set tSC=..parseActivities(tCatchAll.Activities,pIndex,tCatchAll,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pCatchAll=tCatchAll
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse a compensation handler
Method parseCompensationHandler(Output pCompensationHandler As Ens.BPL.CompensationHandler, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create a compensation handler
		Set tCompensationHandler=##class(Ens.BPL.CompensationHandler).%New()
		$$$ASSERT($IsObject(tCompensationHandler))
		
		#; Fix up relationship
		Set tCompensationHandler.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tCompensationHandler,pIndex,.tStartChild)
		
		#; A compensation just contains a (possibly empty) list of activities
		Set tSC=..parseActivities(tCompensationHandler.Activities,pIndex,tCompensationHandler,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pCompensationHandler=tCompensationHandler

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse the Context
Method parseContext(Output pContext As Ens.BPL.Context, pChild As %String, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Create the Context
		Set tContext=##class(Ens.BPL.Context).%New()
		$$$ASSERT($IsObject(tContext))
		
		#; Fix up relationship
		Set tContext.Parent=pParent
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pChild)="context")
		
		#; Parse the properties
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pChild,"c",pChild))
		while (tChild'="") {
			
			#; A context can only contain properties, which
			#; are always defined as elements
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pChild,"c",tChild)="e")
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tChild)="property")
			
			Set tProperty=##class(Ens.BPL.Property).%New()
			$$$ASSERT($IsObject(tProperty))
			
			Set tName=^||%ISC.Ens.BPLData(..Key,tChild,"a","name")
		
			Set tType=$Get(^||%ISC.Ens.BPLData(..Key,tChild,"a","type"))	
			Set tExpr=$Get(^||%ISC.Ens.BPLData(..Key,tChild,"a","initialexpression"))
			Set tColl=$Get(^||%ISC.Ens.BPLData(..Key,tChild,"a","collection"))
			Set tInst=$Get(^||%ISC.Ens.BPLData(..Key,tChild,"a","instantiate"))
			
			#; Address prodlog #56548, property type should have extraneous spaces stripped
			#; This isn't a complete fix as other types of errors can be caused by typos entered by
			#; the user. The class compiler needs to be fixed to address the general issue.
			Set tProperty.Parent=tContext,tProperty.Name=tName,tProperty.Type=$ZStrip(tType,"<>W")
			Set tProperty.InitialExpression=tExpr,tProperty.Collection=tColl
			Set tProperty.Instantiate=tInst
			
			#; Annotation present?
			Set tAnnotation="",tFirstChild=$Order(^||%ISC.Ens.BPLData(..Key,tChild,"c",""))
			If tFirstChild'="" {
				If ^||%ISC.Ens.BPLData(..Key,tChild,"c",tFirstChild)="e" {
					If ^||%ISC.Ens.BPLData(..Key,tFirstChild)="annotation" {
				
						#; Now collect the annotation
						Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",""))
						While tAnnChild'="" {
							If ^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild)="c" {
								Set tAnnotation=tAnnotation_^||%ISC.Ens.BPLData(..Key,tAnnChild)
							}
							Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild))
						}
						Set tProperty.Annotation=tAnnotation
					} else {
						Set tFirstChild=""	
					}
				}
			}
			
			#; Parameters present?
			Set tParams=$Order(^||%ISC.Ens.BPLData(..Key,tChild,"c",tFirstChild))
			If tParams'="" {
				
				$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tChild,"c",tParams)="e")
				$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tParams)="parameters")
				
				#; Walk the parameters
				Set tParam=$Order(^||%ISC.Ens.BPLData(..Key,tParams,"c",""))
				while tParam'="" {
				
					Set tParamName=$Get(^||%ISC.Ens.BPLData(..Key,tParam,"a","name"))
					Set tParamValue=$Get(^||%ISC.Ens.BPLData(..Key,tParam,"a","value"))
						
					Do tProperty.Parameters.SetAt(tParamValue,tParamName)
					
					Set tParam=$Order(^||%ISC.Ens.BPLData(..Key,tParams,"c",tParam))
				}
			}	
			
			Do tContext.Properties.Insert(tProperty)
			
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pChild,"c",tChild))
		}
					
		#; Assign the output
		Set pContext=tContext
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse Branch statement
Method parseBranch(Output pBranch As Ens.BPL.Branch, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="branch")
		
		Set tBranch=##class(Ens.BPL.Branch).%New()
		$$$ASSERT($IsObject(tBranch))
		
		#; Fix up relationship
		Set tBranch.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tBranch,pIndex,.tStartChild)
		
		#; Get the condition
		Set tBranch.Condition=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","condition"))
		
		#; And the label to branch to
		Set tBranch.Label=^||%ISC.Ens.BPLData(..Key,pIndex,"a","label")

		#; Pick out the (optional) OverrideLanguage
		Set tBranch.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
			
		#; Assign the output
		Set pBranch=tBranch
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse if statement
Method parseIf(Output pIf As Ens.BPL.If, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="if")
		
		Set tIf=##class(Ens.BPL.If).%New()
		$$$ASSERT($IsObject(tIf))
		
		#; Fix up relationship
		Set tIf.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tIf,pIndex,.tStartChild)
		
		Set tIf.Condition=^||%ISC.Ens.BPLData(..Key,pIndex,"a","condition")

		#; Pick out the (optional) OverrideLanguage
		Set tIf.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Parse the true,false elements
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tStartChild))
		while (tChild'="") {
			
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tChild)="true"||(^||%ISC.Ens.BPLData(..Key,tChild)="false"))
		
			If ^||%ISC.Ens.BPLData(..Key,tChild)="true" {
				
				#; Parse the common attributes
				Do ..ParseAnnotation(tIf.True,tChild,.tStartChildTrue)
							
				Set tSC=..parseActivities(tIf.True,tChild,tIf,.tStartChildTrue)		
			} else {
				
				#; Parse the common attributes
				Do ..ParseAnnotation(tIf.False,tChild,.tStartChildFalse)
				
				Set tSC=..parseActivities(tIf.False,tChild,tIf,tStartChildFalse)
			}
			
			If $$$ISERR(tSC) Quit

			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
			
		#; Assign the output
		Set pIf=tIf
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse Label statement
Method parseLabel(Output pLabel As Ens.BPL.Label, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="label")
		
		Set tLabel=##class(Ens.BPL.Label).%New()
		$$$ASSERT($IsObject(tLabel))
		
		#; Fix up relationship
		Set tLabel.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tLabel,pIndex,.tStartChild)
		
		#; Assign the output
		Set pLabel=tLabel
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse switch statement
Method parseSwitch(Output pSwitch As Ens.BPL.Switch, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="switch")
		
		Set tSwitch=##class(Ens.BPL.Switch).%New()
		$$$ASSERT($IsObject(tSwitch))
		
		#; Fix up relationship
		Set tSwitch.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tSwitch,pIndex,.tStartChild)
		
		Set tSeenDefault=0
		
		#; Parse the cases
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tStartChild))
		while (tChild'="") {
			
			Set tSC=..parseCaseNode(.tCaseNode,tChild,tSwitch)
			If $$$ISERR(tSC) Quit
			
			#; Record presence of default
			If tCaseNode.%IsA("Ens.BPL.Default") Set tSeenDefault=1
			
			Do tSwitch.Cases.Insert(tCaseNode)
			
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
		#; Create a default if one hasn't been supplied
		If tSeenDefault=0 {
		
			Set tDefault=##class(Ens.BPL.Default).%New()
			$$$ASSERT($IsObject(tDefault))
			
			#; Add it to the cases collection	
			Do tSwitch.Cases.Insert(tDefault)
		}
		
		#; Assign the output
		Set pSwitch=tSwitch
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse the 'Case' statement
Method parseCaseNode(Output pCaseNode As Ens.BPL.CaseNode, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="case"||(^||%ISC.Ens.BPLData(..Key,pIndex)="default"))
		
		If ^||%ISC.Ens.BPLData(..Key,pIndex)="case" {
		
			Set tCaseNode=##class(Ens.BPL.Case).%New()
			$$$ASSERT($IsObject(tCaseNode))
				
			#; Get the (mandatory) condition
			Set tCaseNode.Condition=^||%ISC.Ens.BPLData(..Key,pIndex,"a","condition")

			#; Pick out the (optional) OverrideLanguage
			Set tCaseNode.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
			
		} else {
			
			Set tCaseNode=##class(Ens.BPL.Default).%New()
			$$$ASSERT($IsObject(tCaseNode))
		}
		
		#; Fix up the parent
		Set tCaseNode.Parent=pParent
		
		#; Get the (optional) name
		Set tCaseNode.Name=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","name"))
			
		#; Parse the common attributes
		Do ..ParseAnnotation(tCaseNode,pIndex,.tStartChild)
				
		Set tSC=..parseActivities(tCaseNode.Activities,pIndex,tCaseNode,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pCaseNode=tCaseNode
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse the Activity List
Method parseActivities(ByRef pActivities As Ens.BPL.ActivityList, pIndex As %Integer, pParent As Ens.BPL.Node, pStartChild As %String = "", ByRef pEndChild As %String) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Parse the Activities in this list
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",pStartChild))
		while (tChild'="") {
			
			#; An activity list can only contain activities, which
			#; are always defined as elements
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild)="e")
			
			#; Pick out the Activity Type
			Set tType=^||%ISC.Ens.BPLData(..Key,tChild),tActivity=$$$NULLOREF
			
			#; Parse accordingly
			If tType="alert" {
				Set tSC=..parseAlert(.tActivity,tChild,pParent)
			} elseif tType="assign" {
				Set tSC=..parseAssign(.tActivity,tChild,pParent)
			} elseif tType="branch" {
				Set tSC=..parseBranch(.tActivity,tChild,pParent)
			} elseif tType="break" {
				Set tSC=..parseBreak(.tActivity,tChild,pParent)
			} elseif tType="call" {
				Set tSC=..parseCall(.tActivity,tChild,pParent)
			} elseif tType="code" {
				Set tSC=..parseCode(.tActivity,tChild,pParent)
			} elseif tType="compensate" {
				Set tSC=..parseCompensate(.tActivity,tChild,pParent)
			} elseif tType="continue" {
				Set tSC=..parseContinue(.tActivity,tChild,pParent)
			} elseif tType="empty" {
				Set tSC=..parseEmpty(.tActivity,tChild,pParent)
			} elseif tType="delay" {
				Set tSC=..parseDelay(.tActivity,tChild,pParent)
			}  elseif tType="foreach" {
				Set tSC=..parseForEach(.tActivity,tChild,pParent)
			} elseif tType="flow" {
				Set tSC=..parseFlow(.tActivity,tChild,pParent)
			} elseif tType="if" {
				Set tSC=..parseIf(.tActivity,tChild,pParent)
			} elseif tType="label" {
				Set tSC=..parseLabel(.tActivity,tChild,pParent)
			} elseif tType="milestone" {
				Set tSC=..parseMilestone(.tActivity,tChild,pParent)
			} elseif tType="receive" {
				Set tSC=..parseReceive(.tActivity,tChild,pParent)
			} elseif tType="reply" {
				Set tSC=..parseReply(.tActivity,tChild,pParent)
			} elseif tType="rule" {
				Set tSC=..parseRule(.tActivity,tChild,pParent)
			} elseif tType="scope" {
				Set tSC=..parseScope(.tActivity,tChild,pParent)
			} elseif tType="sequence" {
				Set tSC=..parseSequence(.tActivity,tChild,pParent)
			} elseif tType="sql" {
				Set tSC=..parseSQL(.tActivity,tChild,pParent)
			} elseif tType="switch" {
				Set tSC=..parseSwitch(.tActivity,tChild,pParent)
			} elseif tType="throw" {
				Set tSC=..parseThrow(.tActivity,tChild,pParent)
			} elseif tType="trace" {
				Set tSC=..parseTrace(.tActivity,tChild,pParent)
			} elseif tType="transform" {
				Set tSC=..parseTransform(.tActivity,tChild,pParent)
			} elseif tType="sync" {
				Set tSC=..parseSync(.tActivity,tChild,pParent)
			} elseif tType="until" {
				Set tSC=..parseUntil(.tActivity,tChild,pParent)
			} elseif tType="while" {
				Set tSC=..parseWhile(.tActivity,tChild,pParent)
			} elseif tType="xslt" {
				Set tSC=..parseXSLT(.tActivity,tChild,pParent)
			} elseif tType="xpath" {
				Set tSC=..parseXPATH(.tActivity,tChild,pParent)
			} else {
				Quit
			}
			
			If $$$ISERR(tSC) Quit
			
			#; Add this activity to the list
			Do pActivities.Insert(tActivity)
			
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
		Set pEndChild=tChild
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse the Message Activity List
Method parseMessageActivities(ByRef pActivities As Ens.BPL.ActivityList, pIndex As %Integer, pParent As Ens.BPL.Node, pStartChild As %String = "") As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Parse the Activities in this list
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",pStartChild))
		while (tChild'="") {
			
			#; An activity list can only contain activities, which
			#; are always defined as elements
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild)="e")
			
			#; Pick out the Activity Type
			Set tType=^||%ISC.Ens.BPLData(..Key,tChild),tActivity=$$$NULLOREF
			
			#; Parse accordingly
			If tType="assign" {
				Set tSC=..parseAssign(.tActivity,tChild,pParent)
			} elseif tType="code" {
				Set tSC=..parseCode(.tActivity,tChild,pParent)
			} elseif tType="trace" {
				Set tSC=..parseTrace(.tActivity,tChild,pParent)
			} else {
				$$$ASSERT("0:No Default")
			}
			If $$$ISERR(tSC) Quit
			
			#; Add this activity to the list
			Do pActivities.Insert(tActivity)
			
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseFlow(Output pFlow As Ens.BPL.Flow, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create a flow
		Set tFlow=##class(Ens.BPL.Flow).%New()
		$$$ASSERT($IsObject(tFlow))
		
		#; Fix up relationship
		Set tFlow.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tFlow,pIndex,.tStartChild)
		
		#; A sequence just contains a (possibly empty) list of activities
		Set tSC=..parseActivities(tFlow.Activities,pIndex,tFlow,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pFlow=tFlow

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseScope(Output pScope As Ens.BPL.Scope, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create a scope
		Set tScope=##class(Ens.BPL.Scope).%New()
		$$$ASSERT($IsObject(tScope))
		
		#; Fix up relationship
		Set tScope.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tScope,pIndex,.tStartChild)
		
		#; Parse the known activities, noting the end case
		Set tSC=..parseActivities(tScope.Activities,pIndex,tScope,tStartChild,.tEndChild)
		If $$$ISERR(tSC) Quit
		
	    #; If there are no compensation or fault handlers then we are done
	    If tEndChild="" Quit
		
		do
		{
			If (^||%ISC.Ens.BPLData(..Key,tEndChild)="compensationhandlers") {
				
				Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",""))
				While tChild'="" {
					
					#; A compensation handler list  can only contain compensation handlers
					#; which are always defined as elements
					$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",tChild)="e")
					
					#; Parse the compensation handler
					Set tSC=..parseCompensationHandler(.tCompensationHandler,tChild,tScope)
					If $$$ISERR(tSC) Quit
					
					#; Add this activity to the list
					Do tScope.CompensationHandlers.Insert(tCompensationHandler)
					
					Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",tChild))
				}
					
			} elseif (^||%ISC.Ens.BPLData(..Key,tEndChild)="faulthandlers") {
				
				Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",""))
				while (tChild'="") {
					
					#; An activity list can only contain activities, which
					#; are always defined as elements
					$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",tChild)="e")
					
					#; Pick out the Activity Type
					Set tType=^||%ISC.Ens.BPLData(..Key,tChild)
					
					if (tType="catch") {
						
						Set tSC=..parseCatch(.tCatch,tChild,pParent) 
						
					} elseif (tType="catchall") {
						
						Set tSC=..parseCatchAll(.tCatch,tChild,pParent)
						
					} else {
						$$$ASSERT("0:Only catch/catchall allowed")
					}
					If $$$ISERR(tSC) Quit
					
					#; Add this activity to the list
					Do tScope.FaultHandlers.Insert(tCatch)
					
					Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,tEndChild,"c",tChild))
				}
			} else {
				$$$ASSERT("0:Only compensation handler/faulthandlers allowed")
			}
			
			// Get the next child
			Set tEndChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tEndChild))
			
		} while (tEndChild'="")
		
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pScope=tScope

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseSequence(Output pSequence As Ens.BPL.Sequence, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create a sequence
		Set tSequence=##class(Ens.BPL.Sequence).%New()
		$$$ASSERT($IsObject(tSequence))
		
		#; Fix up relationship
		Set tSequence.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tSequence,pIndex,.tStartChild)
		
		#; A sequence just contains a (possibly empty) list of activities
		Set tSC=..parseActivities(tSequence.Activities,pIndex,tSequence,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pSequence=tSequence

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseWhile(Output pWhile As Ens.BPL.While, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="while")
		
		#; Create the while
		Set tWhile=##class(Ens.BPL.While).%New()
		$$$ASSERT($IsObject(tWhile))
		
		#; Fix up relationship
		Set tWhile.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tWhile,pIndex,.tStartChild)
		
		#; Get the condition
		Set tWhile.Condition=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","condition"))

		#; Pick out the (optional) OverrideLanguage
		Set tWhile.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Parse the Activities
		Set tSC=..parseActivities(tWhile.Activities,pIndex,tWhile,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pWhile=tWhile
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseUntil(Output pUntil As Ens.BPL.Until, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="until")
		
		#; Create the until
		Set tUntil=##class(Ens.BPL.Until).%New()
		$$$ASSERT($IsObject(tUntil))
		
		#; Fix up relationship
		Set tUntil.Parent = pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tUntil,pIndex,.tStartChild)
		
		#; Get the condition
		Set tUntil.Condition= $Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","condition"))

		#; Pick out the (optional) OverrideLanguage
		Set tUntil.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Parse the Activities
		Set tSC=..parseActivities(tUntil.Activities,pIndex,tUntil,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pUntil=tUntil
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseAlert(Output pAlert As Ens.BPL.Alert, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="alert")
		
		#; Create an alert object
		Set tAlert=##class(Ens.BPL.Alert).%New()
		$$$ASSERT($IsObject(tAlert))
		
		#; Fix up relationship
		Set tAlert.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tAlert,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tAlert.Value=^||%ISC.Ens.BPLData(..Key,pIndex,"a","value")

		#; Pick out the (optional) OverrideLanguage
		Set tAlert.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Assign the output
		Set pAlert=tAlert
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseAssign(Output pAssign As Ens.BPL.Assign, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="assign")
		
		#; Create an assign object
		Set tAssign=##class(Ens.BPL.Assign).%New()
		$$$ASSERT($IsObject(tAssign))
		
		#; Fix up relationship
		Set tAssign.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tAssign,pIndex,.tStartChild)
		
		#; Pick out the property name
		Set tAssign.Property=^||%ISC.Ens.BPLData(..Key,pIndex,"a","property")
		
		#; Pick out the value
		Set tAssign.Value=^||%ISC.Ens.BPLData(..Key,pIndex,"a","value")
		
		#; Pick out the type
		Set tAssign.Action=^||%ISC.Ens.BPLData(..Key,pIndex,"a","action")

		#; Pick out the (optional) OverrideLanguage
		Set tAssign.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Pick out the (optional) key
		Set tAssign.Key=^||%ISC.Ens.BPLData(..Key,pIndex,"a","key")
		
		#; Assign the output
		Set pAssign=tAssign
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseForEach(Output pForEach As Ens.BPL.ForEach, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="foreach")
		
		#; Create an ForEach object
		Set tForEach=##class(Ens.BPL.ForEach).%New()
		$$$ASSERT($IsObject(tForEach))
		
		#; Fix up relationship
		Set tForEach.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tForEach,pIndex,.tStartChild)
		
		#; Pick out the property name
		Set tForEach.Property=^||%ISC.Ens.BPLData(..Key,pIndex,"a","property")
		
		#; Pick out the key
		Set tForEach.Key=^||%ISC.Ens.BPLData(..Key,pIndex,"a","key")
		
		#; Parse the Activities
		Set tSC=..parseActivities(tForEach.Activities,pIndex,tForEach,tStartChild)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pForEach=tForEach
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseReply(Output pReply As Ens.BPL.Reply, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="reply")
		
		Set tReply=##class(Ens.BPL.Reply).%New()
		$$$ASSERT($IsObject(tReply))
		
		#; Fix up relationship
		Set tReply.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tReply,pIndex,.tStartChild)
		
		#; Assign the output
		Set pReply=tReply
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseDelay(Output pDelay As Ens.BPL.Delay, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="delay")
		
		Set tDelay=##class(Ens.BPL.Delay).%New()
		$$$ASSERT($IsObject(tDelay))
		
		#; Fix up relationship
		Set tDelay.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tDelay,pIndex,.tStartChild)
		
		#; Get the (optional) Until
		Set tDelay.Until=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","until"))
		
		#; Get the (optional) For
		Set tDelay.Duration=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","duration"))
		
		#; Assign the output
		Set pDelay=tDelay
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseEmpty(Output pEmpty As Ens.BPL.Empty, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="empty")
		
		Set tEmpty=##class(Ens.BPL.Empty).%New()
		$$$ASSERT($IsObject(tEmpty))
		
		#; Fix up relationship
		Set tEmpty.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tEmpty,pIndex,.tStartChild)
		
		#; Assign the output
		Set pEmpty=tEmpty
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseBreak(Output pBreak As Ens.BPL.Break, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="break")
		
		Set tBreak=##class(Ens.BPL.Break).%New()
		$$$ASSERT($IsObject(tBreak))
		
		#; Fix up relationship
		Set tBreak.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tBreak,pIndex,.tStartChild)
		
		#; Assign the output
		Set pBreak=tBreak
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCall(Output pCall As Ens.BPL.Call, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="call")
		
		Set tCall=##class(Ens.BPL.Call).%New()
		$$$ASSERT($IsObject(tCall))
		
		#; Fix up relationship
		Set tCall.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tCall,pIndex,.tStartChild)
		
		#; Get the (mandatory) Class
		Set tCall.Target=^||%ISC.Ens.BPLData(..Key,pIndex,"a","target")
		
		#; Get the (optional) Async flag
		Set tCall.Async=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","async"),tCall.Async)
	
		#; Get the (optional) Timeout
		Set tCall.Timeout=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","timeout"))
		
		#; Get the (optional) LanguageOverride
		Set tCall.LanguageOverride=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))

		#; Parse the DataTransforms
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tStartChild))
		while tChild'="" {
			
			Set tSC=..parseMessage(.tMessage,tChild,tCall)
			If $$$ISERR(tSC) Quit
			
			$$$ASSERT($IsObject(tMessage))
			
			If tMessage.%IsA("Ens.BPL.Request") {
				Set tCall.Request=tMessage	
			} else {
				Set tCall.Response=tMessage
			}
			
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
		#; Assign the output
		Set pCall=tCall
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseContinue(Output pContinue As Ens.BPL.Continue, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="continue")
		
		Set tContinue=##class(Ens.BPL.Continue).%New()
		$$$ASSERT($IsObject(tContinue))
		
		#; Fix up relationship
		Set tContinue.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tContinue,pIndex,.tStartChild)
		
		#; Assign the output
		Set pContinue=tContinue
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCompensate(Output pCompensate As Ens.BPL.Compensate, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="compensate")
		
		#; Create a compensate object
		Set tCompensate=##class(Ens.BPL.Compensate).%New()
		$$$ASSERT($IsObject(tCompensate))
		
		#; Fix up relationship
		Set tCompensate.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tCompensate,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tCompensate.Target=^||%ISC.Ens.BPLData(..Key,pIndex,"a","target")
		
		#; Assign the output
		Set pCompensate=tCompensate
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseMessage(Output pMessage As Ens.BPL.Message, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="request"||(^||%ISC.Ens.BPLData(..Key,pIndex)="response"))
		
		If ^||%ISC.Ens.BPLData(..Key,pIndex)="request" {
				
			Set tMessage=##class(Ens.BPL.Request).%New()
		
		} else {
			
			Set tMessage=##class(Ens.BPL.Response).%New()
		}
		
		$$$ASSERT($IsObject(tMessage))
		
		#; Fix up relationship
		Set tMessage.Parent=pParent
		
		#; Get the mandatory type
		Set tMessage.Type=^||%ISC.Ens.BPLData(..Key,pIndex,"a","type")
		
		#; Parse the Activities
		Set tSC=..parseMessageActivities(tMessage.Activities,pIndex,tMessage)
		If $$$ISERR(tSC) Quit
		
		#; Assign the output
		Set pMessage=tMessage
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseMilestone(Output pMilestone As Ens.BPL.Milestone, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="milestone")
		
		#; Create an milestone object
		Set tMilestone=##class(Ens.BPL.Milestone).%New()
		$$$ASSERT($IsObject(tMilestone))
		
		#; Fix up relationship
		Set tMilestone.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tMilestone,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tMilestone.Value=^||%ISC.Ens.BPLData(..Key,pIndex,"a","value")

		#; Pick out the (optional) OverrideLanguage
		Set tMilestone.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Assign the output
		Set pMilestone=tMilestone
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseSync(Output pSync As Ens.BPL.Sync, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="sync")
		
		Set tSync=##class(Ens.BPL.Sync).%New()
		$$$ASSERT($IsObject(tSync))
		
		#; Fix up relationship
		Set tSync.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tSync,pIndex,.tStartChild)
		
		#; Get the (optional) Timeout
		Set tSync.Timeout=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","timeout"))
		
		#; Get the calls
		Set tSync.Calls=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","calls"))
		
		#; Get the waittype
		Set tSync.Type=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","type"),tSync.Type)
		
		#; Get the allowresync
		Set tSync.AllowResync=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","allowresync"))
		
		#; Assign the output
		Set pSync=tSync
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseThrow(Output pThrow As Ens.BPL.Throw, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="throw")
		
		#; Create an trace object
		Set tThrow=##class(Ens.BPL.Throw).%New()
		$$$ASSERT($IsObject(tThrow))
		
		#; Fix up relationship
		Set tThrow.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tThrow,pIndex,.tStartChild)
		
		#; Pick out the status
		Set tThrow.Fault=^||%ISC.Ens.BPLData(..Key,pIndex,"a","fault")
		
		#; Assign the output
		Set pThrow=tThrow
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseTrace(Output pTrace As Ens.BPL.Trace, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="trace")
		
		#; Create an trace object
		Set tTrace=##class(Ens.BPL.Trace).%New()
		$$$ASSERT($IsObject(tTrace))
		
		#; Fix up relationship
		Set tTrace.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tTrace,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tTrace.Value=^||%ISC.Ens.BPLData(..Key,pIndex,"a","value")

		#; Pick out the (optional) OverrideLanguage
		Set tTrace.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Assign the output
		Set pTrace=tTrace
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseTransform(Output pTransform As Ens.BPL.Transform, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="transform")
		
		Set tTransform=##class(Ens.BPL.Transform).%New()
		$$$ASSERT($IsObject(tTransform))
		
		#; Fix up relationship
		Set tTransform.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tTransform,pIndex,.tStartChild)
		
		#; Get the Class,Input and Output
		Set tTransform.Class=^||%ISC.Ens.BPLData(..Key,pIndex,"a","class")
		Set tTransform.Source=^||%ISC.Ens.BPLData(..Key,pIndex,"a","source")
		Set tTransform.Target=^||%ISC.Ens.BPLData(..Key,pIndex,"a","target")
		
		#; Assign the output
		Set pTransform=tTransform
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCode(Output pCode As Ens.BPL.Code, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="code")

		#; Create a code object
		Set tCode=##class(Ens.BPL.Code).%New()
		$$$ASSERT($IsObject(tCode))
		
		#; Fix up relationship
		Set tCode.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tCode,pIndex,.tStartChild)

		#; Pick out the (optional) OverrideLanguage
		Set tCode.LanguageOverride=$G(^||%ISC.Ens.BPLData(..Key,pIndex,"a","languageOverride"))
		
		#; Walk the characters and write to the stream
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tStartChild))
		While tChild'="" {
			If ^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild)="c" {
				Do tCode.Code.Write(^||%ISC.Ens.BPLData(..Key,tChild))		
			}
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
		#; Assign the output
		Set pCode=tCode
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseSQL(Output pSQL As Ens.BPL.SQL, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="sql")
		
		#; Create a SQL object
		Set tSQL=##class(Ens.BPL.SQL).%New()
		$$$ASSERT($IsObject(tSQL))
		
		#; Fix up relationship
		Set tSQL.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tSQL,pIndex,.tStartChild)
		
		#; Walk the characters and write to the stream
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tStartChild))
		While tChild'="" {
			If ^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild)="c" {
				Set tLine=^||%ISC.Ens.BPLData(..Key,tChild) Do tSQL.SQL.Write(tLine)		
			}
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tChild))
		}
		
		#; Assign the output
		Set pSQL=tSQL
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseReceive(Output pReceive As Ens.BPL.Receive, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="receive")
		
		Set tReceive=##class(Ens.BPL.Receive).%New()
		$$$ASSERT($IsObject(tReceive))
		
		#; Fix up relationship
		Set tReceive.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tReceive,pIndex,.tStartChild)
		
		#; Get the (mandatory) request name
		Set tReceive.Request=^||%ISC.Ens.BPLData(..Key,pIndex,"a","request")
		
		#; Get the (optional) timeout
		Set tReceive.Timeout=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","timeout"),tReceive.Timeout)
		
		#; Assign the output
		Set pReceive=tReceive
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseRule(Output pRule As Ens.BPL.Rule, pIndex As %Integer, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pIndex)="rule")
		
		Set tRule=##class(Ens.BPL.Rule).%New()
		$$$ASSERT($IsObject(tRule))
		
		#; Fix up relationship
		Set tRule.Parent=pParent
		
		#; Parse the common attributes
		Do ..ParseActivity(tRule,pIndex,.tStartChild)
		
		#; Get the (mandatory) Rule name
		Set tRule.Rule=^||%ISC.Ens.BPLData(..Key,pIndex,"a","rule")
		
		#; Get the (optional) resultLocation
		Set tRule.ResultLocation=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","resultLocation"),tRule.ResultLocation)
		
		#; Get the (optional) reasonLocation
		Set tRule.ReasonLocation=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","reasonLocation"),tRule.ReasonLocation)

		#; Get the (optional) ruleContext
		Set tRule.RuleContext=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","ruleContext"),tRule.RuleContext)

		#; Assign the output
		Set pRule=tRule
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseXSLT(Output pXSLT As Ens.BPL.XSLT, pChild As %String, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Create the XSLT
		Set tXSLT=##class(Ens.BPL.XSLT).%New()
		$$$ASSERT($IsObject(tXSLT))
		
		#; Fix up relationship
		Set tXSLT.Parent=pParent
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pChild)="xslt")
		
		#; Parse the common attributes
		Do ..ParseActivity(tXSLT,pChild,.tStartChild)
		
		#; Get the (mandatory) xslurl
		Set tXSLT.XSLURL=^||%ISC.Ens.BPLData(..Key,pChild,"a","xslurl")
		
		#; Get the (mandatory) source
		Set tXSLT.Source=^||%ISC.Ens.BPLData(..Key,pChild,"a","source")
		
		#; Get the (mandatory) target
		Set tXSLT.Target=^||%ISC.Ens.BPLData(..Key,pChild,"a","target")
		
		#; Get the XSLT Version
		Set tXSLT.XSLTVersion=$G(^||%ISC.Ens.BPLData(..Key,pChild,"a","xsltversion"),"1.0")

		#; Parse the properties
		Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pChild,"c",tStartChild))
		while (tChild'="") {
	
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pChild,"c",tChild)="e")
			$$$ASSERT(^||%ISC.Ens.BPLData(..Key,tChild)="parameters")
			
			#; Walk the parameters
			Set tParam=$Order(^||%ISC.Ens.BPLData(..Key,tChild,"c",""))
			
			while tParam'="" {
			
				Set tParamName=$Get(^||%ISC.Ens.BPLData(..Key,tParam,"a","name"))
				Set tParamValue=$Get(^||%ISC.Ens.BPLData(..Key,tParam,"a","value"))
					
				Do tXSLT.Parameters.SetAt(tParamValue,tParamName)
				
				Set tParam=$Order(^||%ISC.Ens.BPLData(..Key,tChild,"c",tParam))
			}
			Set tChild=$Order(^||%ISC.Ens.BPLData(..Key,pChild,"c",tChild))
		}	
					
		#; Assign the output
		Set pXSLT=tXSLT
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseXPATH(Output pXPATH As Ens.BPL.XPATH, pChild As %String, pParent As Ens.BPL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Create the XPATH
		Set tXPATH=##class(Ens.BPL.XPATH).%New()
		$$$ASSERT($IsObject(tXPATH))
		
		#; Fix up relationship
		Set tXPATH.Parent=pParent
		
		$$$ASSERT(^||%ISC.Ens.BPLData(..Key,pChild)="xpath")
		
		#; Parse the common attributes
		Do ..ParseActivity(tXPATH,pChild,.tStartChild)
		
		#; Get the (mandatory) source
		Set tXPATH.Source=^||%ISC.Ens.BPLData(..Key,pChild,"a","source")
		
		#; Get the (mandatory) property
		Set tXPATH.Property = $Get(^||%ISC.Ens.BPLData(..Key,pChild,"a","property"))
		
		#; Get the (mandatory) context
		Set tXPATH.Context  = $Get(^||%ISC.Ens.BPLData(..Key,pChild,"a","context"))
		
		#; Get the (mandatory) expression
		Set tXPATH.Expression= $Get(^||%ISC.Ens.BPLData(..Key,pChild,"a","expression"))
		
		#; Get the (optional) prefix mappings
		Set tXPATH.PrefixMappings=$Get(^||%ISC.Ens.BPLData(..Key,pChild,"a","prefixmappings"))
		
		#; Get the (optional) schemaspec
		Set tXPATH.SchemaSpec=$Get(^||%ISC.Ens.BPLData(..Key,pChild,"a","schemaspec"))
					
		#; Assign the output
		Set pXPATH=tXPATH
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse an annotation
Method ParseAnnotation(pActivity As Ens.BPL.Activity, pIndex As %Integer, Output pStartChild As %String)
{
	#; Get the (optional) annotation
	Set tAnnotation="",pStartChild="",tFirstChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",""))
	If tFirstChild'="" {
		If ^||%ISC.Ens.BPLData(..Key,pIndex,"c",tFirstChild)="e" {
			If ^||%ISC.Ens.BPLData(..Key,tFirstChild)="annotation" {
					
				#; First Child is an <annotation> element, set the StartChild output
				#; so subsequent parsing will skip this element.
				Set pStartChild = tFirstChild
				
				#; Now collect the annotation
				Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",""))
				While tAnnChild'="" {
					If ^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild)="c" {
						Set tAnnotation=tAnnotation_^||%ISC.Ens.BPLData(..Key,tAnnChild)
					}
					Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild))
				}
				Set pActivity.Annotation=tAnnotation
			} 
		}
	}
}

/// Parse an PyFromImport element content
Method ParsePyFromImport(pIndex As %Integer) As %String [ Private ]
{
	Set (tPyFromImport,tPyFromImportChild)=""
	For {
		Set tPyFromImportChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",tPyFromImportChild),1,nodeType)
		Quit:tPyFromImportChild=""
		Set nextText=^||%ISC.Ens.BPLData(..Key,tPyFromImportChild)
		Set:"c"=nodeType tPyFromImport=tPyFromImport_nextText
	}
	// Remove leading and trailing lines added by XData Formatting
	Return $ZSTRIP(tPyFromImport,"<>C")
}

/// Parse the common members of a BPL Activity
Method ParseActivity(pActivity As Ens.BPL.Activity, pIndex As %Integer, Output pStartChild As %String)
{
	#; Get the (optional) Name
	Set pActivity.Name=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","name"))
	
	#; Get the (optional) XPos
	Set pActivity.XPos=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","xpos"))

	#; Get the (optional) YPos	
	Set pActivity.YPos=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","ypos"))
	
	#; Get the (optional) XEnd
	Set pActivity.XEnd=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","xend"))

	#; Get the (optional) YEnd	
	Set pActivity.YEnd=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","yend"))
	
	#; Get the (optional) Disabled
	Set tDisabled=$Get(^||%ISC.Ens.BPLData(..Key,pIndex,"a","disabled"))
	Set pActivity.Disabled=((tDisabled="true")||(tDisabled=1))
	
	#; Assign the ActivityID
	Set ..ActivityCount=..ActivityCount+1,pActivity.ActivityID=..ActivityCount

	#; Get the (optional) annotation
	Do ..ParseAnnotation(pActivity,pIndex,.pStartChild)
	
	/*
	#; Get the (optional) annotation
	Set tAnnotation="",pStartChild="",tFirstChild=$Order(^||%ISC.Ens.BPLData(..Key,pIndex,"c",""))
	If tFirstChild'="" {
		If ^||%ISC.Ens.BPLData(..Key,pIndex,"c",tFirstChild)="e" {
			If ^||%ISC.Ens.BPLData(..Key,tFirstChild)="annotation" {
					
				#; First Child is an <annotation> element, set the StartChild output
				#; so subsequent parsing will skip this element.
				Set pStartChild = tFirstChild
				
				#; Now collect the annotation
				Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",""))
				While tAnnChild'="" {
					If ^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild)="c" {
						Set tAnnotation=tAnnotation_^||%ISC.Ens.BPLData(..Key,tAnnChild)
					}
					Set tAnnChild=$Order(^||%ISC.Ens.BPLData(..Key,tFirstChild,"c",tAnnChild))
				}
				Set pActivity.Annotation=tAnnotation
			} 
		}
	}
	*/
}

/// Collect Parser Errors into a single status value
Method CollectBPLErrors() As %Status
{
	Set tSC=$$$ERROR($$$EnsErrInvalidBPL)
	For tType="error","warning" {		
		Set tIndex = ""
		For {
			Set tIndex=$Order(^||%ISC.Ens.BPLData(..Key,tType,tIndex),1,tMessage)
			Quit:(tIndex = "")
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$GeneralError,tMessage))
		}
	}
	Quit tSC
}

}
