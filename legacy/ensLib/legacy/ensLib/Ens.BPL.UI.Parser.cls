/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class validates and parses a <class>BPL.UI.Diagram</class> object into a <class>BPL.Process</class> object.<br>
/// Usage:
/// <example>
/// Set tParser = ##class(Ens.BPL.UI.Parser).%New()
/// Set tSC = tParser.ParseDiagram(tDiagram)
/// Set tProcess = tParser.Process
/// </example>
Class Ens.BPL.UI.Parser Extends %RegisteredObject [ System = 4 ]
{

/// The Process object created as a result of parsing
Property Process As Ens.BPL.Process;

/// Create an error code for a diagram parsing error
Method MakeError(pErr As %String, pShape As Shape = "") As %Status
{
	If ($IsObject(pShape)) {
		Set pErr = pErr _ " (" _ pShape.Index _ ")"
	}

	Quit $$$ERROR($$$EnsErrInvalidBPLDiagram,pErr)
}

/// Analyze the given diagram and check for syntax errors
/// If there are errors, they are set into <property>Error</property>.<br>
Method ValidateDiagram(pDiagram As Diagram) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	
	Do {
		// find the start & end tags
		Set tStart = ""
		Set tEnd = ""
		For i = 1:1:pDiagram.ShapeList.Count() {
			Set tShape = pDiagram.ShapeList.GetAt(i)
			
			// test for duplicate label names
			If ((tShape.Type = "label")&&(tShape.Name'="")) {
				If ($D(tLabelNames(tShape.Name))) {
					// duplicate start shape
					Set tSC = $$$ADDSC(tSC,..MakeError("More than one Label with the same name: ("_tShape.Name_")",tShape))
				}
				Else {
					Set tLabelNames(tShape.Name) = ""
				}
			}
			
			// test start & end (top-level only!!!)
			If ('$IsObject(tShape.Parent)) {
				If (tShape.Type = "start") {
					If ($IsObject(tStart)) {
						// duplicate start shape
						Set tSC = $$$ADDSC(tSC,..MakeError("Duplicate Start event in Diagram",tShape))
					}
					Else {
						Set tStart = tShape
					}
				}
				ElseIf (tShape.Type = "end") {
					Set tEnd = tShape
				}
			}
			
			// test for connections
			If (tShape.Type = "start") {
				If (tShape.OutputList.Count() = 0) {
					// Unconnected
					Set tSC = $$$ADDSC(tSC,..MakeError("Unconnected <" _ tShape.Type _"> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
				}
			}
			ElseIf (tShape.Type = "end") {
				If (tShape.InputList.Count() = 0) {
					// Unconnected
					Set tSC = $$$ADDSC(tSC,..MakeError("Unconnected <" _ tShape.Type _"> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
				}
			}
			Else {
				If ((tShape.InputList.Count() = 0) || (tShape.OutputList.Count() = 0)) {
					// Unconnected
					Set tSC = $$$ADDSC(tSC,..MakeError("Unconnected <" _ tShape.Type _"> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
				}
			}
		}
		
		If ('$IsObject(tStart)) {
			// missing start shape
			Set tSC = $$$ADDSC(tSC,..MakeError("No Start event in Diagram"))
		}

		If ('$IsObject(tEnd)) {
			// missing end shape
			Set tSC = $$$ADDSC(tSC,..MakeError("No End event in Diagram"))
		}

	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Analyze the given diagram and create a BPL object tree<br>
Method ParseDiagram(pDiagram As Diagram) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	
	Do {
		// reset
		Set ..Process = ""

		// first validate
		Set tSC = ..ValidateDiagram(pDiagram)
		If $$$ISERR(tSC) Quit
		
		// create a process object
		Set ..Process = ##class(Ens.BPL.Process).%New()
		Set ..Process.Language = pDiagram.Language
		Set ..Process.Request = pDiagram.Request
		Set ..Process.Response = pDiagram.Response

		Set ..Process.Width = pDiagram.Width
		Set ..Process.Height = pDiagram.Height
		Set ..Process.Version = pDiagram.Version
		Set ..Process.Includes = pDiagram.Includes
		Set ..Process.PyFromImport = pDiagram.PyFromImport

		If (pDiagram.Layout = "automatic") {
			// default
			Set ..Process.Layout = ""
		}
		Else {
			Set ..Process.Layout = pDiagram.Layout
		}

		If (+pDiagram.Component) {
			Set ..Process.Component = 1
		}

		Set ..Process.Context = pDiagram.Context
		Set ..Process.ContextSuperClass = pDiagram.ContextSuperClass
		
		// find start of top sequence
		Set tSC = ..FindStartShape(pDiagram.ShapeList,.tStart)
		If $$$ISERR(tSC) Quit
		
		// create top-level BPL sequence
		Set tSequence = ##class(Ens.BPL.Sequence).%New()
		If (pDiagram.Layout = "manual") {
			Set tSequence.XPos = tStart.xPos
			Set tSequence.YPos = tStart.yPos
		}
		Set tSequence.Parent = ..Process
		Set ..Process.Sequence = tSequence
		
		// Start shape indicates disabled state for top sequence
		Set tSequence.Disabled = tStart.Disabled

		// Now process this sequence
		Set tSC = ..ParseSequence(tStart, tSequence, "", tSequence.Activities)
		If $$$ISERR(tSC) Quit
		
	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Find the starting shape in the given collection.
Method FindStartShape(pList As %RegisteredObject, ByRef pStart As Shape) As Shape
{
	Set $ZT="Trap",tSC=$$$OK
	Set pStart = ""
	
	Do {
		// find the start & end tags
		For i = 1:1:pList.Count() {
			Set tShape = pList.GetAt(i)
			If (tShape.Type = "start") {
				Set pStart = tShape
				Quit
			}
		}
	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Given a starting shape, process all the shapes in the given sequence.
/// Add the BPL nodes to the given ActivityList (which could be any NodeList).<br>
/// If <var>pEnd</var> is present, then processing stops when it is reached.
/// <var>pCurrScope</var> is the current containing scope, if any.
Method ParseSequence(pStart As Shape, pParent As Ens.BPL.Node, pCurrScope As Ens.BPL.Scope, pActivities As Ens.BPL.NodeList, pEnd As Shape = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	
	Do {
		// follow chain of shapes connected to start...
		Set tShape = pStart
		While ($IsObject(tShape) && (tShape '= pEnd)) {
			
			// create node for this shape
			Set tSC = $$$ADDSC(tSC,..CreateBPLNode(tShape,.tNode, pParent))
			If $$$ISERR(tSC) Quit
			
			// (Note: some shapes do not create nodes (e.g.,start)
			If ($IsObject(tNode)) {
				// fault and compensation handlers get added to the current scope
				If (tShape.Type = "compensationhandler") {
					If ('$IsObject(pCurrScope)) {
						Set tSC = $$$ADDSC(tSC,..MakeError(tShape.Type _" found outside of scope in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
						Quit
					}
					Set tNode.Parent = pCurrScope
					Do pCurrScope.CompensationHandlers.Insert(tNode)
				}
				ElseIf ((tShape.Type = "catch")||(tShape.Type = "catchall")) {
					If ('$IsObject(pCurrScope)) {
						Set tSC = $$$ADDSC(tSC,..MakeError(tShape.Type _" found outside of scope in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
						Quit
					}
					Set tNode.Parent = pCurrScope
					Do pCurrScope.FaultHandlers.Insert(tNode)
				}
				Else {
					Set tNode.Parent = pParent
					Do pActivities.Insert(tNode)
				}
			}

			// see if this shape has children...
			// Assume only shapes that are allowed to have children, do.
			If (tShape.Children.Count() > 0) {
				// process the children
				// find start of sequence
				Set tSC = $$$ADDSC(tSC,..FindStartShape(tShape.Children,.tStart))
				If $$$ISERR(tSC) Quit

				If ('$IsObject(tStart)) {
					Set tSC = $$$ADDSC(tSC,..MakeError("No start event for " _ tShape.Type _" in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]", tShape))
					Quit
				}
				
				// Now process this sequence
				Set tSC = $$$ADDSC(tSC,..ParseSequence(tStart, tNode, pCurrScope, tNode.Activities))
				If $$$ISERR(tSC) Quit
			}
			
			// test for switch / flow / if / scope statements
			If ((tShape.Type = "switch") || 
				(tShape.Type = "flow") || 
				(tShape.Type = "scope") || 
				(tShape.Type = "if")) {
				
				If (tShape.OutputList.Count() = 0) {
					// error
					If (tShape.Type = "flow") {
						Set tSC = $$$ADDSC(tSC,..MakeError("No branches for <flow> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
					}
					ElseIf (tShape.Type = "if") {
						Set tSC = $$$ADDSC(tSC,..MakeError("No case for <if> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
					}
					If (tShape.Type = "scope") {
						Set tSC = $$$ADDSC(tSC,..MakeError("No elements for <scope> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
					}
					Else {
						Set tSC = $$$ADDSC(tSC,..MakeError("No cases for <switch> in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
					}
					Quit
				}
				
				// first find the join at the end
				Set tBranch = 1
				Set tEnd = ""
				While ('$IsObject(tEnd) && (tBranch <= tShape.OutputList.Count())) {
					Set tEnd = tShape.OutputList.GetAt(tBranch).ToShape
					Set tJoinCount = 1
					While ((tJoinCount>0) && $IsObject(tEnd)) {
						If (tEnd.Type = "join") {
							Set tJoinCount = tJoinCount - 1
						}
						ElseIf ((tEnd.Type = "switch") || (tEnd.Type = "flow")|| (tEnd.Type = "if")||(tEnd.Type = "scope")) {
							// we need another
							Set tJoinCount = tJoinCount + 1
						}

						If (tJoinCount > 0) {
							// get next shape
							If (tEnd.OutputList.Count() > 0) {
								Set tFoundNext = 0
								For n = 1:1:tEnd.OutputList.Count() {
									Set tNextEnd = tEnd.OutputList.GetAt(n).ToShape
									If ($IsObject(tNextEnd)) {
										// !!!
										Set tFoundNext = 1
										Set tEnd = tNextEnd
										Quit
									}
								}
								If ('tFoundNext) {
									// !!!!
									Set tEnd = ""
									Set tBranch = tBranch + 1
								}
							}
							Else {
								// must be a missing join...
								Set tEnd = ""
								Set tBranch = tShape.OutputList.Count() + 1 // go to end
							}
						}
					}
				}

				If ('$IsObject(tEnd)) {
					// error
					Set tSC = $$$ADDSC(tSC,..MakeError("No join at end of " _ tShape.Type _ " in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
					Quit
				}

				// place position of join within starting element
				Set tNode.XEnd = tEnd.xPos
				Set tNode.YEnd = tEnd.yPos

				// now handle switch, if, and flow differently
				
				If (tShape.Type = "switch") {
					// switch logic
					$$$ASSERT($classname(tNode) = "Ens.BPL.Switch")

					// process each sequence within the switch cases
					Set tCaseList = ##class(Ens.BPL.CaseList).%New()
					Set tNode.Cases = tCaseList
					Set tDefault = ""
					For n = 1:1:tShape.OutputList.Count() {
						Set tConnect = tShape.OutputList.GetAt(n)
						If (tConnect.Condition = "") {
							// if no condition, this is the default

							If tDefault'="" {
								// We can only have one default
								Set tSC = $$$ADDSC(tSC,..MakeError("Switch only allows one default in Diagram: [" _ $S(tShape.Name="":"unnamed",1:tShape.Name) _ "]",tShape))
								Quit
							}

							Set tCase = ##class(Ens.BPL.Default).%New()
							If (tConnect.Name '= "Default") {
								Set tCase.Name = tConnect.Name
							}
							Set tDefault = tCase
							
							// insert the default at the end
						}
						Else {
							Set tCase = ##class(Ens.BPL.Case).%New()
							Set tCase.Name = tConnect.Name
							Set tCase.Condition = tConnect.Condition
							Set tCase.LanguageOverride = tConnect.LanguageOverride
							Do tCaseList.Insert(tCase)
						}
						
						// now process the sequence for each case
						// start of sequence is first child
						
						Set tStart = tConnect.ToShape
						Set tSC = $$$ADDSC(tSC,..ParseSequence(tStart, tNode, pCurrScope, tCase.Activities,tEnd))
						If $$$ISERR(tSC) Quit
					}
					
					// Bail out on any errors
					If $$$ISERR(tSC) Quit
					
					// make sure default goes at the end
					If ($IsObject(tDefault)) {
						Do tCaseList.Insert(tDefault)
					}
				}
				ElseIf (tShape.Type = "if") {
					// if logic
					$$$ASSERT($classname(tNode) = "Ens.BPL.If")

					// process the true and false sequences
					For n = 1:1:tShape.OutputList.Count() {
						
						Set tConnect = tShape.OutputList.GetAt(n)
						
						If (tConnect.Name = "true") {
							// true
							Set tStart = tConnect.ToShape
							Set tSeq = tNode.True
						}
						ElseIf (tConnect.Name = "false") {
							// false
							Set tStart = tConnect.ToShape
							Set tSeq = tNode.False
						}
						Else {
							// error
							Set tStart = ""
							Set tSeq = ""
						}
						
						// now process the sequence for each case
						// start of sequence is first child
						If ($IsObject(tStart)) {
							Set tSC = $$$ADDSC(tSC,..ParseSequence(tStart, tNode, pCurrScope, tSeq, tEnd))
							If $$$ISERR(tSC) Quit
						}
					}
				}
				ElseIf(tShape.Type = "scope") {
					// scope logic
					// process main (and only) branch
					// pull out fault and compensation handlers as we go

					$$$ASSERT($classname(tNode) = "Ens.BPL.Scope")

					// scope has activities, faults, etc.
					// find which is which
					Set tConnect = tShape.OutputList.GetAt(1)
					Set tStart = tConnect.ToShape
					
					// process sequence of shapes; set *this* scope as current scope
					Set tSC = $$$ADDSC(tSC,..ParseSequence(tStart, tNode, tNode, tNode.Activities,tEnd))
					If $$$ISERR(tSC) Quit

					// if there is no catchall, add one!
					Set tHasCatchAll = 0
					For n=1:1:tNode.FaultHandlers.Count() {
						If (tNode.FaultHandlers.GetAt(n).%IsA("Ens.BPL.CatchAll")) {
							Set tHasCatchAll = 1
							Quit
						}
					}

					If ('tHasCatchAll) {
						Set tCatch = ##class(Ens.BPL.CatchAll).%New()
						Do tNode.FaultHandlers.Insert(tCatch)
					}
				}
				Else {
					// flow logic
					// process each sequence within the flow branches

					$$$ASSERT($classname(tNode) = "Ens.BPL.Flow")

					// flow has activities
					For n = 1:1:tShape.OutputList.Count() {
						// create a sequence for each branch of the flow
						
						Set tConnect = tShape.OutputList.GetAt(n)

						Set tSequence = ##class(Ens.BPL.Sequence).%New()
						Set tSequence.Parent = pParent
						Set tSequence.Name = tConnect.Name
						Set tSequence.Disabled = tConnect.Disabled
						
						// add this sequence to the flow
						Do tNode.Activities.Insert(tSequence)

						// now process the sequence for this branch
						// start of sequence is first child
						
						Set tStart = tConnect.ToShape
						Set tSC = $$$ADDSC(tSC,..ParseSequence(tStart, tNode, pCurrScope, tSequence.Activities,tEnd))
						If $$$ISERR(tSC) Quit
					}
				}

				// common logic					
				// next shape should be a Join
				// all paths should end at the same join...
				If ($IsObject(tEnd) && (tEnd.OutputList.Count() = 1)) {
					Set tShape = tEnd.OutputList.GetAt(1).ToShape
				}
				Else {
					Set tShape = ""
				}
			}
			Else {
				// not a switch or flow
				// find next shape (assume one connection)
				If (tShape.OutputList.Count() = 1) {
					Set tShape = tShape.OutputList.GetAt(1).ToShape
				}
				Else {
					Set tShape = ""
				}
			}
		}

	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Finds an instance of a <class>Ens.BPL.Node</class> object
/// that corresponds to the given shape.
Method CreateBPLNode(pShape As Shape, ByRef pNode As Ens.BPL.Node, pParent As Ens.BPL.Activity) As %Status
{
	Set pNode = ""
	Set tSC = $$$OK
	
	If (pShape.Type = "assign") {
		Set pNode = ##class(Ens.BPL.Assign).%New()
		Set pNode.Property = pShape.GetProperty("Property")
		Set pNode.Value = pShape.GetProperty("Value")
	
		Set t = pShape.GetProperty("Action")
		If (t '= "") {
			Set pNode.Action = t
		}

		Set t = pShape.GetProperty("Key")
		If (t '= "") {
			Set pNode.Key = t
		}
	}
	ElseIf (pShape.Type = "call") {
		Set pNode = ##class(Ens.BPL.Call).%New()
		Set pNode.Async = +pShape.GetProperty("Async")
		Set pNode.Target = pShape.GetProperty("Target")
		Set pNode.Timeout = pShape.GetProperty("Timeout")

		// copy request and response from Shape (if present)
		
		If ($IsObject(pShape.Request)) {
			Set pNode.Request = pShape.Request
		}

		If ($IsObject(pShape.Response)) {
			Set pNode.Response = pShape.Response
		}
	}
	ElseIf (pShape.Type = "code") {
		Set pNode = ##class(Ens.BPL.Code).%New()
		Do pNode.Code.CopyFrom(pShape.Code)
	}
	ElseIf (pShape.Type = "delay") {
		Set pNode = ##class(Ens.BPL.Delay).%New()
		Set pNode.Duration = pShape.GetProperty("Duration")
		Set pNode.Until = pShape.GetProperty("Until")
	}
	ElseIf (pShape.Type = "break") {
		Set pNode = ##class(Ens.BPL.Break).%New()
	}
	ElseIf (pShape.Type = "continue") {
		Set pNode = ##class(Ens.BPL.Continue).%New()
	}
	ElseIf (pShape.Type = "empty") {
		Set pNode = ##class(Ens.BPL.Empty).%New()
	}
	ElseIf (pShape.Type = "foreach") {
		Set pNode = ##class(Ens.BPL.ForEach).%New()
		Set pNode.Property = pShape.GetProperty("Property")
		Set pNode.Key = pShape.GetProperty("Key")
	}
	ElseIf (pShape.Type = "flow") {
		Set pNode = ##class(Ens.BPL.Flow).%New()
	}
	ElseIf (pShape.Type = "if") {
		Set pNode = ##class(Ens.BPL.If).%New()
		Set pNode.Condition = pShape.GetProperty("Condition")
	}
	ElseIf (pShape.Type = "label") {
		Set pNode = ##class(Ens.BPL.Label).%New()
	}
	ElseIf (pShape.Type = "branch") {
		Set pNode = ##class(Ens.BPL.Branch).%New()
		Set pNode.Label = pShape.GetProperty("Label")
		Set pNode.Condition = pShape.GetProperty("Condition")
	}
	ElseIf (pShape.Type = "receive") {
		Set pNode = ##class(Ens.BPL.Receive).%New()
		Set pNode.Request = pShape.GetProperty("Request")
		Set pNode.Timeout = pShape.GetProperty("Timeout")
	}
	ElseIf (pShape.Type = "reply") {
		Set pNode = ##class(Ens.BPL.Reply).%New()
	}
	ElseIf (pShape.Type = "rule") {
		Set pNode = ##class(Ens.BPL.Rule).%New()
		Set pNode.Rule = pShape.GetProperty("Rule")
		Set pNode.ResultLocation = pShape.GetProperty("ResultLocation")
		Set pNode.ReasonLocation = pShape.GetProperty("ReasonLocation")
		Set pNode.RuleContext = pShape.GetProperty("RuleContext")
	}
	ElseIf (pShape.Type = "sequence") {
		Set pNode = ##class(Ens.BPL.Sequence).%New()
	}
	ElseIf (pShape.Type = "sql") {
		Set pNode = ##class(Ens.BPL.SQL).%New()
		Do pNode.SQL.CopyFrom(pShape.Code)
	}
	ElseIf (pShape.Type = "switch") {
		Set pNode = ##class(Ens.BPL.Switch).%New()
	}
	ElseIf (pShape.Type = "sync") {
		Set pNode = ##class(Ens.BPL.Sync).%New()
		Set pNode.Calls = pShape.GetProperty("Calls")
		Set pNode.Type = pShape.GetProperty("Type")
		Set pNode.Timeout = pShape.GetProperty("Timeout")
		Set pNode.AllowResync = pShape.GetProperty("AllowResync")
	}
	ElseIf (pShape.Type = "alert") {
		Set pNode = ##class(Ens.BPL.Alert).%New()
		Set pNode.Value = pShape.GetProperty("Value")
	}
	ElseIf (pShape.Type = "trace") {
		Set pNode = ##class(Ens.BPL.Trace).%New()
		Set pNode.Value = pShape.GetProperty("Value")
	}
	ElseIf (pShape.Type = "milestone") {
		Set pNode = ##class(Ens.BPL.Milestone).%New()
		Set pNode.Value = pShape.GetProperty("Value")
	}
	ElseIf (pShape.Type = "transform") {
		Set pNode = ##class(Ens.BPL.Transform).%New()
		Set pNode.Class = pShape.GetProperty("Class")
		// Handle IE10 in Studio being very bad about capitalization of "class"
		If (pNode.Class = "") Set pNode.Class = pShape.GetProperty("class")
		Set pNode.Source = pShape.GetProperty("Source")
		Set pNode.Target = pShape.GetProperty("Target")
	}
	ElseIf (pShape.Type = "while") {
		Set pNode = ##class(Ens.BPL.While).%New()
		Set pNode.Condition = pShape.GetProperty("Condition")
	}
	ElseIf (pShape.Type = "until") {
		Set pNode = ##class(Ens.BPL.Until).%New()
		Set pNode.Condition = pShape.GetProperty("Condition")
	}
	ElseIf (pShape.Type = "scope") {
		Set pNode = ##class(Ens.BPL.Scope).%New()
	}
	ElseIf (pShape.Type = "compensate") {
		Set pNode = ##class(Ens.BPL.Compensate).%New()
		Set pNode.Target = pShape.GetProperty("Target")
	}
	ElseIf (pShape.Type = "compensationhandler") {
		Set pNode = ##class(Ens.BPL.CompensationHandler).%New()
	}
	ElseIf (pShape.Type = "catch") {
		Set pNode = ##class(Ens.BPL.Catch).%New()
		Set pNode.Fault = pShape.GetProperty("Fault")
	}
	ElseIf (pShape.Type = "catchall") {
		Set pNode = ##class(Ens.BPL.CatchAll).%New()
	}
	ElseIf (pShape.Type = "throw") {
		Set pNode = ##class(Ens.BPL.Throw).%New()
		Set pNode.Fault = pShape.GetProperty("Fault")
	}
	ElseIf (pShape.Type = "start") {
		// no node for this
		Set pNode = ""
	}
	ElseIf (pShape.Type = "end") {
		// no node for this
		Set pNode = ""
		// remember end position
		Set pParent.XEnd = pShape.xPos
		Set pParent.YEnd = pShape.yPos
	}
	ElseIf (pShape.Type = "join") {
		// no node for this
		Set pNode = ""
	}
	ElseIf (pShape.Type = "xslt") {
		Set pNode = ##class(Ens.BPL.XSLT).%New()
		Set pNode.Source = pShape.GetProperty("Source")
		Set pNode.Target = pShape.GetProperty("Target")
		Set pNode.XSLURL = pShape.GetProperty("XSLURL")
		Set pNode.XSLTVersion = pShape.GetProperty("XSLTVersion")
		Set pNode.Parameters = pShape.Parameters
	}
	ElseIf (pShape.Type = "xpath") {
		Set pNode = ##class(Ens.BPL.XPATH).%New()
		Set pNode.Source = pShape.GetProperty("Source")
		Set pNode.Property = pShape.GetProperty("Property")
		Set pNode.Context = pShape.GetProperty("Context")
		Set pNode.Expression = pShape.GetProperty("Expression")
		Set pNode.PrefixMappings = pShape.GetProperty("PrefixMappings")
		Set pNode.SchemaSpec = pShape.GetProperty("SchemaSpec")
	}
	Else {
		// unknown type
		Set tSC = $$$ERROR($$$EnsErrInvalidBPLDiagram,"Unknown shape type in BPL diagram (" _ pShape.Type _ ")")
		Set pNode = ""
	}

	// set common properties
	If ($IsObject(pNode)) {
		Set pNode.Name = pShape.Name
		Set pNode.Disabled = pShape.Disabled
		Set pNode.XPos = pShape.xPos
		Set pNode.YPos = pShape.yPos
		Set pNode.Annotation = pShape.Annotation
		// Common support for Shape LanguageOverride
		Set t = pShape.GetProperty("LanguageOverride")
		If (t '= "") {
			Set pNode.LanguageOverride =  t
		}
	}

	Quit tSC
}

}
