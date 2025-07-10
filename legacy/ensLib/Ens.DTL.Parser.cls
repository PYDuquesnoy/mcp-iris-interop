/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsErrors, %occSAX)

/// This class parses the DTL source and returns the root of the parse
/// tree that represents the Data Transform Class
Class Ens.DTL.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the ^||%ISC.Ens.DTLData key where the parsed DTL data is found
Property Key As %Integer [ Private ];

/// This is the test entry point to the parser
Method ParseStream(Output pTransform As Ens.DTL.Transform, pStream As %BinaryStream)
{
	Set tSC=$$$OK
	Try {
		
		#; Create an XML import handler
		Set tHandler=##class(%XML.ImportHandler).%New("IRIS.Temp",$$$IntHandler) 
		$$$ASSERT($IsObject(tHandler))
 			
 		#; Create the Entity Resolver on the schema found in class 'Ens.Schema.DTL'
 		Set tResolver=##class(Ens.Util.XML.XDataEntityResolver).%New("Ens.Schema.DTL")
 		$$$ASSERT($IsObject(tResolver))
 	
		#; Parse the XML data in the specfied stream
		Set tSC=##Class(%XML.SAX.Parser).ParseStream(pStream,tHandler,tResolver,,,"Schema")		 
		If $$$ISERR(tSC) Quit		
	
		#; Copy tree because handler will delete its copy when it goes out of scope
		Set ..Key=$Increment(^||%ISC.Ens.DTLData) Merge ^||%ISC.Ens.DTLData(..Key)=@tHandler.DOMName@(tHandler.Tree)
		
		If $Data(^||%ISC.Ens.DTLData(..Key,"error"))||($Data(^||%ISC.Ens.DTLData(..Key,"warning"))) {
			Set tSC=..CollectDTLErrors()
			Quit
		}
		
		Set tSC=..parseTransform(.pTransform)
		
	}
	Catch ex {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	If ..Key '= "" Kill ^||%ISC.Ens.DTLData(..Key)
	Quit tSC
}

/// Parse the Transform
Method parseTransform(Output pTransform As Ens.DTL.Transform) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create the class
		Set tTransform=##class(Ens.DTL.Transform).%New()
		$$$ASSERT($IsObject(tTransform))
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,1)="transform")
			
		#; Set the (optional) language
		Set tTransform.Language=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","language"),tTransform.Language)
		
		#; Get the (mandatory) source type
		Set tTransform.SourceClass=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","sourceClass"))
		Set:""=tTransform.SourceClass tTransform.SourceClass=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","source"))
		
		#; Get the (mandatory) target type
		Set tTransform.TargetClass=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","targetClass"))
		Set:""=tTransform.TargetClass tTransform.TargetClass=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","target"))
			
		#; Set the (optional) create type
		Set tTransform.Create=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","create"),tTransform.Create)

		#; Set the (optional) source type
		Set tTransform.SourceDocType=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","sourceDocType"))
		Set:""=tTransform.SourceDocType tTransform.SourceDocType=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","sourceType"),tTransform.SourceDocType)

		#; Set the (optional) target type
		Set tTransform.TargetDocType=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","targetDocType"))
		Set:""=tTransform.TargetDocType tTransform.TargetDocType=$Get(^||%ISC.Ens.DTLData(..Key,1,"a","targetType"),tTransform.TargetDocType)

		#; A transform just contains a (possibly empty) list of actions

		Set tActions=##class(Ens.DTL.ActionList).%New()
		$$$ASSERT($IsObject(tActions))

		#; Parse the common attributes
		Do ..parseAction(tTransform,1,.tStartChild)

		Do ..parsePyFromImport(tTransform,1,.tStartChild)
		
		Set tSC=..parseActions(.tActions,1,$this,tStartChild)
		If $$$ISERR(tSC) Quit
			
		Set tTransform.Actions=tActions
		
		#; Assign the output
		Set pTransform=tTransform
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseAction(pAction As Ens.DTL.Action, pIndex As %Integer, Output pStartChild As %String)
{
	#; Get the (optional) annotation
	Set tAnnotation="",pStartChild="",tFirstChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",""))
	If tFirstChild'="" {
		If ^||%ISC.Ens.DTLData(..Key,pIndex,"c",tFirstChild)="e" {
			If ^||%ISC.Ens.DTLData(..Key,tFirstChild)="annotation" {
				
				#; First Child is an <annotation> element, set the StartChild output
				#; so subsequent parsing will skip this element
				Set pStartChild=tFirstChild
				
				#; Now collect the annotation
				Set tAnnChild=$Order(^||%ISC.Ens.DTLData(..Key,tFirstChild,"c",""))
				While tAnnChild'="" {
					If ^||%ISC.Ens.DTLData(..Key,tFirstChild,"c",tAnnChild)="c" {
						Set tAnnotation=tAnnotation_^||%ISC.Ens.DTLData(..Key,tAnnChild)
					}
					Set tAnnChild=$Order(^||%ISC.Ens.DTLData(..Key,tFirstChild,"c",tAnnChild))
				}
				Set pAction.Annotation=tAnnotation
			} 
		}
	}
	#; Get the Disabled flag
	Set pAction.Disabled=''$Get(^||%ISC.Ens.DTLData(..Key,pIndex,"a","disabled"))

	#; Get the Expanded flag. Default to true
	Set pAction.Expanded=''$Get(^||%ISC.Ens.DTLData(..Key,pIndex,"a","expanded"),1)
}

Method parseActions(ByRef pActions As Ens.DTL.ActionList, pIndex As %Integer, pParent As Ens.DTL.Node, pStartChild As %String = "") As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Parse the Activities in this list
		Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",pStartChild))
		while (tChild'="") {
			#; An action list can only contain actions, which
			#; are always defined as elements
			$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild)="e")
			
			#; Pick out the Action Type
			Set tType=^||%ISC.Ens.DTLData(..Key,tChild),tAction=$$$NULLOREF
			
			#; Parse accordingly
			If tType="assign" {
				Set tSC=..parseAssign(.tAction,tChild,pParent)
			} elseif tType="break" {
				Set tSC=..parseBreak(.tAction,tChild,pParent)
			} elseif tType="code" {
				Set tSC=..parseCode(.tAction,tChild,pParent)
			} elseif tType="comment" {
				Set tSC=..parseComment(.tAction,tChild,pParent)
			} elseif tType="foreach" {
				Set tSC=..parseForEach(.tAction,tChild,pParent)
			} elseif tType="sql" {
				Set tSC=..parseSQL(.tAction,tChild,pParent)
			} elseif tType="subtransform" {
				Set tSC=..parseSubTransform(.tAction,tChild,pParent)
			} elseif tType="trace" {
				Set tSC=..parseTrace(.tAction,tChild,pParent)
			} elseif tType="if" {
				Set tSC=..parseIf(.tAction,tChild,pParent)
			} elseif tType="switch" {
				Set tSC=..parseSwitch(.tAction,tChild,pParent)
			} elseif tType="group" {
				Set tSC=..parseGroup(.tAction,tChild,pParent)
			} else {
				$$$ASSERT("0:No default")
			}

			If $$$ISERR(tSC) Quit
			
			#; Add this action to the list
			Do pActions.Insert(tAction)
			
			Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild))
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseAssign(Output pAssign As Ens.DTL.Assign, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="assign")
		
		#; Create an assign object
		Set tAssign=##class(Ens.DTL.Assign).%New()
		$$$ASSERT($IsObject(tAssign))
		
		#; Fix up relationship
		Set tAssign.Parent=pParent
		
		#; Parse the commonality
		Do ..parseAction(tAssign,pIndex,.tStartChild)
		
		#; Pick out the property name
		Set tAssign.Property=^||%ISC.Ens.DTLData(..Key,pIndex,"a","property")
		
		#; Pick out the (optional) value
		Set tAssign.Value=$Get(^||%ISC.Ens.DTLData(..Key,pIndex,"a","value"))
		
		#; Pick out the action
		Set tAssign.Action=^||%ISC.Ens.DTLData(..Key,pIndex,"a","action")
		
		#; Pick out the key
		Set tAssign.Key=^||%ISC.Ens.DTLData(..Key,pIndex,"a","key")

		#; Pick out the language override in case it is present
		Set tAssign.LanguageOverride=$G(^||%ISC.Ens.DTLData(..Key,pIndex,"a","languageOverride"))
		
		#; Assign the output
		Set pAssign=tAssign
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseTrace(Output pTrace As Ens.DTL.Trace, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="trace")
		
		#; Create an trace object
		Set tTrace=##class(Ens.DTL.Trace).%New()
		$$$ASSERT($IsObject(tTrace))
		
		#; Fix up relationship
		Set tTrace.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tTrace,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tTrace.Value=^||%ISC.Ens.DTLData(..Key,pIndex,"a","value")

		#; Pick out the language override in case it is present
		Set tTrace.LanguageOverride=$G(^||%ISC.Ens.DTLData(..Key,pIndex,"a","languageOverride"))
		
		#; Assign the output
		Set pTrace=tTrace
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseBreak(Output pBreak As Ens.DTL.Break, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="break")
		
		#; Create a break object
		Set tBreak=##class(Ens.DTL.Break).%New()
		$$$ASSERT($IsObject(tBreak))
		
		#; Fix up relationship
		Set tBreak.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tBreak,pIndex,.tStartChild)
		
		#; Assign the output
		Set pBreak=tBreak
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseCode(Output pCode As Ens.DTL.Code, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="code")
		
		#; Create a code object
		Set tCode=##class(Ens.DTL.Code).%New()
		$$$ASSERT($IsObject(tCode))
		
		#; Fix up relationship
		Set tCode.Parent=pParent
		
		
		Set tCode.LanguageOverride=$G(^||%ISC.Ens.DTLData(..Key,pIndex,"a","languageOverride"))

		#; Parse the common attributes
		Do ..parseAction(tCode,pIndex,.tStartChild)
		
		#; Walk the characters and write to the stream
		Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tStartChild))
		While tChild'="" {
			If ^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild)="c" {
				Set tLine=^||%ISC.Ens.DTLData(..Key,tChild) Do tCode.Code.Write(tLine)		
			}
			Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild))
			If (tChild '= "") Do tCode.Code.WriteLine()
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

Method parseComment(Output pComment As Ens.DTL.Comment, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="comment")
		
		#; Create a comment object
		Set tComment=##class(Ens.DTL.Comment).%New()
		$$$ASSERT($IsObject(tComment))
		
		#; Fix up relationship
		Set tComment.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tComment,pIndex,.tStartChild)
		
		#; Assign the output
		Set pComment=tComment
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parseForEach(Output pForEach As Ens.DTL.ForEach, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="foreach")
		
		#; Create an foreach object
		Set tForEach=##class(Ens.DTL.ForEach).%New()
		$$$ASSERT($IsObject(tForEach))
		
		#; Fix up relationship
		Set tForEach.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tForEach,pIndex,.tStartChild)
		
		#; Pick out the value
		Set tForEach.Key=^||%ISC.Ens.DTLData(..Key,pIndex,"a","key")
		Set tForEach.Property=^||%ISC.Ens.DTLData(..Key,pIndex,"a","property")
		Set tForEach.Unload=^||%ISC.Ens.DTLData(..Key,pIndex,"a","unload")

		#; Parse actions inside
		Set tSC=..parseActions(tForEach.Actions,pIndex,tForEach,tStartChild) If $$$ISERR(tSC) Quit

		#; Assign the output
		Set pForEach=tForEach
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method parsePyFromImport(pAction As Ens.DTL.Action, pIndex As %Integer, Output pStartChild As %String)
{
	#; Get the (optional) annotation
	Set pyFromImport="",tSecondChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",pStartChild))
	If tSecondChild'="" {
		If ^||%ISC.Ens.DTLData(..Key,pIndex,"c",tSecondChild)="e" {
			If ^||%ISC.Ens.DTLData(..Key,tSecondChild)="pyFromImport" {
				
				#; Second Child if it exists, otherwise first, is an <pyFromImport> element, set the StartChild output
				#; so subsequent parsing will skip this element
				Set pStartChild=tSecondChild
				
				#; Now collect the annotation
				Set tAnnChild=$Order(^||%ISC.Ens.DTLData(..Key,tSecondChild,"c",""))
				While tAnnChild'="" {
					If ^||%ISC.Ens.DTLData(..Key,tSecondChild,"c",tAnnChild)="c" {
						Set pyFromImport=pyFromImport_^||%ISC.Ens.DTLData(..Key,tAnnChild)
					}
					Set tAnnChild=$Order(^||%ISC.Ens.DTLData(..Key,tSecondChild,"c",tAnnChild))
				}
				Set pAction.pyFromImport=pyFromImport
			} 
		}
	}
}

Method parseSQL(Output pSQL As Ens.DTL.SQL, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="sql")
		
		#; Create a SQL object
		Set tSQL=##class(Ens.DTL.SQL).%New()
		$$$ASSERT($IsObject(tSQL))
		
		#; Fix up relationship
		Set tSQL.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tSQL,pIndex,.tStartChild)
		
		#; Walk the characters and write to the stream
		Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tStartChild))
		While tChild'="" {
			If ^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild)="c" {
				Set tLine=^||%ISC.Ens.DTLData(..Key,tChild) Do tSQL.SQL.Write(tLine)
			}
			Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild))
			If (tChild '= "") { Do tSQL.SQL.WriteLine() }
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

Method parseSubTransform(Output pSubTrans As Ens.DTL.Assign, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="subtransform")
		
		#; Create a subtransform object
		Set tSubTrans=##class(Ens.DTL.SubTransform).%New()
		$$$ASSERT($IsObject(tSubTrans))
		
		#; Fix up relationship
		Set tSubTrans.Parent=pParent
		
		#; Parse the commonality
		Do ..parseAction(tSubTrans,pIndex,.tStartChild)

		#; Pick out the (optional) auxiliary argument
		Set tSubTrans.Aux=$Get(^||%ISC.Ens.DTLData(..Key,pIndex,"a","aux"))
		
		#; Pick out the property name
		Set tSubTrans.Class=^||%ISC.Ens.DTLData(..Key,pIndex,"a","class")
		
		#; Pick out the (optional) value
		Set tSubTrans.SourceObj=$Get(^||%ISC.Ens.DTLData(..Key,pIndex,"a","sourceObj"))
		
		#; Pick out the action
		Set tSubTrans.TargetObj=^||%ISC.Ens.DTLData(..Key,pIndex,"a","targetObj")
		
		#; Assign the output
		Set pSubTrans=tSubTrans
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse if statement
Method parseIf(Output pIf As Ens.DTL.If, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="if")
		
		Set tIf=##class(Ens.DTL.If).%New()
		$$$ASSERT($IsObject(tIf))
		
		#; Fix up relationship
		Set tIf.Parent=pParent
		
		#; Parse the common attributes
		Do ..parseAction(tIf,pIndex,.tStartChild)
		
		Set tIf.Condition=^||%ISC.Ens.DTLData(..Key,pIndex,"a","condition")

		#; Pick out the language override in case it is present
		Set tIf.LanguageOverride=$G(^||%ISC.Ens.DTLData(..Key,pIndex,"a","languageOverride"))
		
		#; Parse the true,false elements
		Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tStartChild))
		while (tChild'="") {
			$$$ASSERT(^||%ISC.Ens.DTLData(..Key,tChild)="true"||(^||%ISC.Ens.DTLData(..Key,tChild)="false"))
		
			If ^||%ISC.Ens.DTLData(..Key,tChild)="true" {
				Set tSC=..parseActions(tIf.True,tChild,tIf)		
			} else {
				Set tSC=..parseActions(tIf.False,tChild,tIf)
			}
			
			If $$$ISERR(tSC) Quit

			Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild))
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

/// Parse switch statement
Method parseSwitch(Output pSwitch As Ens.DTL.Switch, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="switch")

		Set tSwitch=##class(Ens.DTL.Switch).%New()
		$$$ASSERT($IsObject(tSwitch))

		#; Fix up relationship
		Set tSwitch.Parent=pParent

		#; Parse the common attributes
		Do ..parseAction(tSwitch,pIndex,.tStartChild)

		Set tSeenDefault=0

		#; Pick out the language override in case it is present
		Set tSwitch.LanguageOverride=$G(^||%ISC.Ens.DTLData(..Key,pIndex,"a","languageOverride"))

		#; Parse the cases
		Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tStartChild))
		while (tChild'="") {
			
			Set tSC=..parseCaseNode(.tCaseNode,tChild,tSwitch)
			If $$$ISERR(tSC) Quit

			#; Record presence of default
			If tCaseNode.%IsA("Ens.DTL.Default") Set tSeenDefault=1

			Do tSwitch.Cases.Insert(tCaseNode)

			Set tChild=$Order(^||%ISC.Ens.DTLData(..Key,pIndex,"c",tChild))
		}

		#; Create a default if one hasn't been supplied since we do not persist empty Default
		If tSeenDefault=0 {

			Set tDefault=##class(Ens.DTL.Default).%New()
			$$$ASSERT($IsObject(tDefault))

			#; Add it to the cases collection	
			Do tSwitch.Cases.Insert(tDefault)

			#; Set Expanded to same as Switch
			Set tDefault.Expanded = tSwitch.Expanded

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
Method parseCaseNode(Output pCaseNode As Ens.DTL.CaseNode, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="case"||(^||%ISC.Ens.DTLData(..Key,pIndex)="default"))

		If ^||%ISC.Ens.DTLData(..Key,pIndex)="case" {

			Set tCaseNode=##class(Ens.DTL.Case).%New()
			$$$ASSERT($IsObject(tCaseNode))

			#; Get the (mandatory) condition
			Set tCaseNode.Condition=^||%ISC.Ens.DTLData(..Key,pIndex,"a","condition")

		} else {

			Set tCaseNode=##class(Ens.DTL.Default).%New()
			$$$ASSERT($IsObject(tCaseNode))
		}

		#; Fix up the parent
		Set tCaseNode.Parent=pParent

		#; Parse the common attributes
		Do ..parseAction(tCaseNode,pIndex,.tStartChild)

		Set tSC=..parseActions(tCaseNode.Actions,pIndex,tCaseNode,tStartChild)
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

/// Parse the 'Group' statement
Method parseGroup(Output pGroup As Ens.DTL.Group, pIndex As %Integer, pParent As Ens.DTL.Node) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		$$$ASSERT(^||%ISC.Ens.DTLData(..Key,pIndex)="group")

		Set tGroup=##class(Ens.DTL.Group).%New()
		$$$ASSERT($IsObject(tGroup))

		#; Fix up the parent
		Set tGroup.Parent=pParent

		#; Parse the common attributes
		Do ..parseAction(tGroup,pIndex,.tStartChild)

		Set tSC=..parseActions(tGroup.Actions,pIndex,tGroup,tStartChild)
		If $$$ISERR(tSC) Quit

		#; Assign the output
		Set pGroup=tGroup

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Collect Parser Errors into a single status value
Method CollectDTLErrors() As %Status
{
	Set tSC=$$$ERROR($$$EnsErrInvalidDTL)
	For tType="error","warning" {		
		Set tIndex = ""
		For {
			Set tIndex = $Order(^||%ISC.Ens.DTLData(..Key,tType,tIndex),1,tMessage)
			Quit:(tIndex = "")
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$GeneralError,tMessage))
		}
	}
	Quit tSC
}

}
