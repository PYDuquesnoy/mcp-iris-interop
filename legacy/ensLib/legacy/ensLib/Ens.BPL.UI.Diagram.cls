/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Represents a BPL Diagram within the Studio graphical editor.
Class Ens.BPL.UI.Diagram Extends (%RegisteredObject, Ens.Util.PortalModelBase) [ System = 4 ]
{

/// Used for shape placement
Parameter XSPACE = 270;

/// Used for shape placement
Parameter YSPACE = 100;

/// Used for shape placement
Parameter XSTART = 200;

/// Used for shape placement
Parameter YSTART = 150;

/// Name of this diagram
Property Name As %String(MAXLEN = 50);

/// width of the diagram
Property Width As %Integer(MAXVAL = 10000, MINVAL = 0) [ InitialExpression = 2000 ];

/// height of the diagram
Property Height As %Integer(MAXVAL = 10000, MINVAL = 0) [ InitialExpression = 2000 ];

/// Annotation for this diagram
Property Annotation As %String(MAXLEN = "");

/// Flag indicating whether to show the annotation
Property ShowAnnotation As %Boolean;

/// Flag indicating whether this is a "Component" Business Process.
Property Component As %Boolean;

/// This holds the layout flag for the diagram
Property Layout As %String(MAXLEN = 20) [ InitialExpression = "automatic" ];

/// This holds the version # for the diagram
Property Version As %Integer(MINVAL = 0);

/// This holds the language of the class
Property Language As %String(MAXLEN = 20) [ InitialExpression = "objectscript" ];

/// This holds the type of the input message
Property Request As %String(MAXLEN = 255) [ Required ];

/// This holds the type of the output message
Property Response As %String(MAXLEN = 255) [ Required ];

/// List of all top-level shapes within this diagram.
Property ShapeList As list Of Shape;

/// Time the source for this diagram was last modified
Property LastModified As %TimeStamp;

/// Set by BPL editor if there are logical errors within this diagram
Property HasErrors As %Boolean [ InitialExpression = 0 ];

/// Definition of context for this diagram
Property Context As Ens.BPL.Context;

/// Transient list of branch elements within the diagram.
/// Subscripted by Index.
Property BranchList As %String [ MultiDimensional ];

/// Transient list of label elements within the diagram.
/// Subscripted by Name.
Property LabelList As %String [ MultiDimensional ];

/// This holds the [ optional ] name of the context superclass
Property ContextSuperClass As %String;

/// This holds an [ optional ] list of include files.
Property Includes As %String;

/// This holds optional list of Python "from" and "import" statements supporting modules available to each Python sub-context.
Property PyFromImport As %String;

/// Create an empty default diagram (with start and end tags)
ClassMethod CreateNewDiagram(pName As %String) As Diagram
{
	Quit ..CreateDiagramFromBPL(pName, "")
}

/// Add a shape to this Diagram.<br>
/// <var>pParent</var>, if present, is the parent shape to insert into.
Method InsertShape(pShape As Shape, pParent As Shape = "")
{
	// insert into diagrams's list
	Do ..ShapeList.Insert(pShape)

	If ($IsObject(pParent)) {
		// insert into shape's list
		Do pParent.Children.Insert(pShape)
		Set pShape.Parent = pParent
	}
	
	// let shape know its index in the list (0 based list)
	Set pShape.Index = ..ShapeList.Count() - 1
}

/// Serialize this diagram for use by the editor.
Method Serialize(pState As %CharacterStream)
{
	Set tDiagram = "<diagram "
	For tAttr = "Name","Width","Height","Layout","Language","Request","Response","LastModified","Version","Includes" {
		Set tValue = $ZCVT($zobjproperty($this, $TR(tAttr,"_")), "O", "HTML")
		Set tDiagram = tDiagram _ tAttr _ "=""" _ tValue _ """ "
	}
	If (..Component) {
		Set tDiagram = tDiagram _ "Component=""1"" "
	}
	If (..ContextSuperClass'="") {
		Set tDiagram = tDiagram _ "ContextSuperClass="""_..ContextSuperClass_""" "
	}
	Set tDiagram = tDiagram _ "ShowAnnotation=""" _ +..ShowAnnotation _ """>"

	Do pState.WriteLine(tDiagram)
			
	// annotation
	If (..Annotation '= "") {
		Do pState.Write("<annotation>")
		Do pState.Write($ZCVT(..Annotation,"O","HTML"))
		Do pState.WriteLine("</annotation>")
	}

	If (..PyFromImport '= "") {
		Do pState.Write("<pyFromImport>")
		Do pState.Write($ZCVT(..PyFromImport,"O","HTML"))
		Do pState.WriteLine("</pyFromImport>")
	}

	// context
	If ($IsObject(..Context)) {
		Do ..Context.GenerateXML(pState)
	}
	// shapes
	For i = 1:1:..ShapeList.Count() {
		Do ..ShapeList.GetAt(i).Serialize(pState)
	}
	
	// connectors
	For i = 1:1:..ShapeList.Count() {
		Set shape =..ShapeList.GetAt(i)
		
		For c = 1:1:shape.OutputList.Count() {
			Do shape.OutputList.GetAt(c).Serialize(pState)
		}
		
		If (shape.GotoConnection) {
			Do shape.GotoConnection.Serialize(pState)
		}
	}

	Do pState.WriteLine("</diagram>")
}

/// Called by Studio interface to open a diagram
ClassMethod Open(id As %String, ByRef pDiagram As Diagram, pConcurrency As %Integer = -1) As %Status
{
	Set pDiagram = "", tSC = $$$OK
	Set tHasDesc = 0

	Do {
		// see if there is any BPL
		// if we have a BPLError XDATA open from that
		Set tStream = ..GetBPLStream(id, .tXDataName, .tDesc, .tTimestamp, pConcurrency)
		If ('$IsObject(tStream)) Quit
		
		If (tXDataName = "BPLError") {
			// open diagram from saved diagram state
			Set tSC = ..CreateDiagramFromXML(tStream, .pDiagram)
			If ($$$ISERR(tSC)) Quit
			If $IsObject(pDiagram) && (pDiagram.Annotation '= "") {
				Set tHasDesc = 1
			}
		}
		Else {
			// Now try to parse the XML	
			Set tParser = ##class(Ens.BPL.Parser).%New()
  			$$$ASSERT($IsObject(tParser))
  			
  			Set tSC = tParser.ParseStream(tStream,.tProcess)
			If ($$$ISERR(tSC)) Quit
			
			// Now create a diagram object from the parse tree
			Set pDiagram = ..CreateDiagramFromBPL(id, tProcess)
		}
	} While(0)
	
	If ($IsObject(pDiagram) && 'tHasDesc) {
		Set pDiagram.Annotation = tDesc
	}
	If $IsObject(pDiagram) Set pDiagram.Timestamp = $get(tTimestamp)
	
	Quit tSC
}

/// Create a Diagram from a BPL parse tree<br>
/// If <var>pProcess</var> is missing, create a default diagram.
ClassMethod CreateDiagramFromBPL(pName As %String, pProcess As Ens.BPL.Process = "") As Diagram
{
	Set diagram = ##class(Diagram).%New()
	Set diagram.Name = pName
	Set diagram.ShowAnnotation = 1
	Set diagram.Component = 0
	Set diagram.ContextSuperClass = ""
	
	// default values
	Set diagram.Request = "Ens.Request"
	Set diagram.Response = "Ens.Response"

	If ($IsObject(pProcess)) {
		Set diagram.Language = pProcess.Language
		Set diagram.Request = pProcess.Request
		Set diagram.Response = pProcess.Response

		Set:(pProcess.Width'="") diagram.Width = pProcess.Width
		Set:(pProcess.Height'="") diagram.Height = pProcess.Height

		Set diagram.Context = pProcess.Context
		Set diagram.ContextSuperClass = pProcess.ContextSuperClass

		If (pProcess.Layout '= "") {
			Set diagram.Layout = pProcess.Layout
			// else pick up default of "automatic"
		}

		If (+pProcess.Component) {
			Set diagram.Component = 1
		}

		Set diagram.Version = pProcess.Version
		Set diagram.Includes = pProcess.Includes
		Set diagram.PyFromImport = pProcess.PyFromImport
	}
	
	Set xPos = ..#XSTART
	Set yPos = ..#YSTART
	
	// start
	Set start = ##class(Shape).%New("start")
	Set start.Name = ""
	If ($IsObject(pProcess)) {
		Set start.Disabled = pProcess.Sequence.Disabled
	}
	If ($IsObject(pProcess) && (diagram.Layout="manual")) {
		Set tChild = pProcess.Sequence.Activities.GetAt(1)
		If (pProcess.Sequence.XPos '= "") {
			Set start.xPos = pProcess.Sequence.XPos
		}
		ElseIf ($IsObject(tChild)) {
			Set start.xPos = tChild.XPos
		}
		Else {
			Set start.xPos = xPos
		}

		If (pProcess.Sequence.YPos '= "") {
			Set start.yPos = pProcess.Sequence.YPos
		}
		ElseIf ($IsObject(tChild)) {
			Set start.yPos = tChild.YPos - ..#YSPACE
		}
		Else {
			Set start.yPos = yPos
		}
	}
	Else {
		Set start.xPos = xPos
		Set start.yPos = yPos
	}
	Do diagram.InsertShape(start)
	Set yPos = yPos + ..#YSPACE
	
	Set prevAct = ""

	If ($IsObject(pProcess)) {
		Set prevAct = start

		// process-level data
		Do ..WalkActivityList(diagram, "",pProcess.Sequence.Activities, .xPos, .yPos, .prevAct)
	}

	// end
	Set end = ##class(Shape).%New("end")
	Set end.Name = ""

	If (diagram.Layout="manual") {
		Set tChild = pProcess.Sequence.Activities.GetAt(pProcess.Sequence.Activities.Count())

		If (pProcess.Sequence.XEnd '= "") {
			Set end.xPos = pProcess.Sequence.XEnd
		}
		ElseIf ($IsObject(tChild)) {
			Set end.xPos = tChild.XPos
		}
		Else {
			Set end.xPos = xPos
		}

		If (pProcess.Sequence.YEnd '= "") {
			Set end.yPos = pProcess.Sequence.YEnd
		}
		ElseIf ($IsObject(tChild)) {
			Set end.yPos = tChild.YPos + ..#YSPACE
		}
		Else {
			Set end.yPos = yPos
		}
	}
	Else {
		Set end.xPos = xPos
		Set end.yPos = yPos
	}
	Do diagram.InsertShape(end)

	If ($IsObject(prevAct)) {
		Do prevAct.ConnectTo(end)
	}

	// layout out shapes
	If (diagram.Layout '= "manual") {
		// first sort multiple outputs by depth
		For i = 1:1:diagram.ShapeList.Count() {
			Set tShape = diagram.ShapeList.GetAt(i)
			if (tShape.OutputList.Count() > 1) {
				Kill da,wa,sort
				Do ..ArrangeShapes(..#XSTART,..#YSTART,tShape,.da,.wa)

				// sort elements of output list				
				For n = 1:1:tShape.OutputList.Count() {
					Set sort(da(n),n) = tShape.OutputList.GetAt(n)
				}
				
				Do tShape.OutputList.Clear()
				
				Set d = $O(sort(""))
				While (d '= "") {
					Set n = $O(sort(d,""))
					While (n '= "") {
						Do tShape.OutputList.Insert(sort(d,n))
						Set n = $O(sort(d,n))
					}
					Set d = $O(sort(d))
				}
			}
		}

		// now arrange the shapes
		Kill da,wa
		Set %xMax = 0
		Set %yMax = 0
		Do ..ArrangeShapes(..#XSTART,..#YSTART,start,.da,.wa)
		
		// adjust size of diagram if it is too small
		If (%xMax > (diagram.Width - 600)) {
			Set diagram.Width = %xMax + 600
		}
		If (%yMax > (diagram.Height - 250)) {
			Set diagram.Height = %yMax + 250
		}
	}

	// add connections from branch(es) to label(s)
	Set g = $O(diagram.BranchList(""))
	While (g'="") {
		// find label
		Set branch = diagram.BranchList(g)
		Set lbl = diagram.BranchList(g,"label")

		If ((lbl'="")&&$D(diagram.LabelList(lbl))) {
			Do branch.AddGotoConnect(diagram.LabelList(lbl))
		}

		Set g = $O(diagram.BranchList(g))
	}

	Quit diagram
}

/// Duplicate of client logic used to auto-arrange shapes
ClassMethod ArrangeShapes(xp As %Integer, yp As %Integer, shape As Shape, ByRef depthArray, ByRef widthArray)
{
#define TESTSIZE(%x,%y) Set:%x>+$G(%xMax) %xMax=%x  Set:%y>+$G(%yMax) %yMax=%y

	Set lastShape = shape
	Set child = ""

	Set shape.xPos=xp,shape.yPos=yp

	// test if this shape has any short-circuit connections to a join
	Set ss = 0
	if (shape.OutputList.Count() > 1) {
		for n = 1:1:shape.OutputList.Count() {
			if (shape.OutputList.GetAt(n).ToShape.Type = "join") {
				Set ss = 1
				Quit
			}
		}
	}

	// process branches
	Set wid = 0
	Set x = xp
	
	for n = 1:1:shape.OutputList.Count() {
		// reset y pos
		Set y = yp + ..#YSPACE
		
		if (shape.OutputList.Count() > 1) {
			// a little more space for first children
			Set y = y + (..#YSPACE / 2)
		}
		
		// update x pos; test for overshift
		if (ss) {
			if (n = 1) {
				Set x = xp + (..#XSPACE / 2)
			}
			elseif ((n > 1) && (shape.OutputList.GetAt(n-1).ToShape.Type '= "join")) {
				Set x = x + ..#XSPACE + $S((wid>0):(wid-1)*..#XSPACE,1:0)
			}
		}
		else {
			if (n = 1) {
				Set x = xp
			}
			else {
				Set x = x + ..#XSPACE + $S((wid>0):(wid-1)*..#XSPACE,1:0)
			}
		}

		Set child = shape.OutputList.GetAt(n).ToShape
		Set endOfBranch = 0

		Set depthArray(n) = 0.5
		Set widthArray(n) = 1

		// trace to end of this thread
		While ($IsObject(child) && 'endOfBranch) {
			Set depthArray(n) = depthArray(n) + 1

			if (child.Type = "join") {
				Set lastShape = child

				Set child.xPos=x,child.yPos=y

				// end of branch
				Set endOfBranch = 1
				$$$TESTSIZE(x,y)
			}
			else {
				Set child.xPos=x,child.yPos=y
				$$$TESTSIZE(x,y)

				if (child.OutputList.Count() = 0) {
					// end of thread
					Set child = ""
				}
				else {
					if ((child.Type = "sequence")||(child.Type = "while")||(child.Type = "foreach")||(child.Type = "until")) {
						// recurse placement of sequence contents
						
						Set start = child.Children.GetAt(1)
						If ($IsObject(start)) {
							Kill da
							Kill wa
							Do ..ArrangeShapes(..#XSTART,..#YSTART,start,.da,.wa)
						}

						Set y = y + ..#YSPACE
					}
					elseif ((child.Type = "switch")||(child.Type = "if")||(child.Type = "flow")||(child.Type = "scope")) {
						// recurse placement for branches
						Kill da
						Kill wa

						Set child = ..ArrangeShapes(x,y,child,.da,.wa)

						// find largest depth
						Set max = 0
						Set d = $O(da(""))
						While (d '= "") {
							Set max = $S(da(d)>max:da(d),1:max)
							Set d = $O(da(d))
						}
						Set depthArray(n) = depthArray(n) + max
						
						// sum up widths
						Set wid = 0
						Set w = $O(wa(""))
						While (w '= "") {
							Set wid = wid + wa(w)
							Set w = $O(wa(w))
						}

						// see if we need to increase our width
						if (wid > widthArray(n)) {
							Set widthArray(n) = wid
						}

						// move join
						if ($IsObject(child)) {
							Set y = y + (..#YSPACE * max)
							Set child.xPos=x,child.yPos=y
						}
						
						Set y = y + ..#YSPACE
					}
					else {
						Set y = y + ..#YSPACE
					}

					if ($IsObject(child)) {
						// next child in line
						Set child = child.OutputList.GetAt(1).ToShape
					}
				}
			}
		}
	}
	
	Quit lastShape
}

ClassMethod WalkActivityList(diagram As Diagram, pParent As Shape, pActivities As Ens.BPL.ActivityList, ByRef xPos As %Integer, ByRef yPos As %Integer, ByRef prevAct As Shape, connectLabel As %String = "", connectCondition As %String = "", connectDisabled As %Boolean = 0, connectType As %String = "", connectLanguageOverride As %String = "")
{
	// walk over the given Activities
	Set tActivities = pActivities
	For a = 1:1:tActivities.Count() {
		Set tActivity = tActivities.GetAt(a)
		Set tType = $classname(tActivity)
		Set tShapeType = $ZCVT(tActivity.%ClassName(0),"L")

		If (tType = "Ens.BPL.Assign") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Property", tActivity.Property)
			Do shape.SetProperty("Value", tActivity.Value)
			Do shape.SetProperty("Action", tActivity.Action)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)
			Do shape.SetProperty("Key", tActivity.Key)
		}
		ElseIf (tType = "Ens.BPL.Call") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Target", tActivity.Target)
			Do shape.SetProperty("Async", +tActivity.Async)
			Do shape.SetProperty("Timeout", tActivity.Timeout)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)

			// request
			Set shape.Request = tActivity.Request
	
			// response
			Set shape.Response = tActivity.Response
		}
		ElseIf (tType = "Ens.BPL.Code") {
			Do CreateShape(tShapeType)

			// get code from stream
			Do shape.Code.CopyFrom(tActivity.Code)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)
		}
		ElseIf (tType = "Ens.BPL.Delay") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Duration", tActivity.Duration)
			Do shape.SetProperty("Until", tActivity.Until)
		}
		ElseIf (tType = "Ens.BPL.Break") {
			Do CreateShape(tShapeType)
		}
		ElseIf (tType = "Ens.BPL.Continue") {
			Do CreateShape(tShapeType)
		}
		ElseIf (tType = "Ens.BPL.Label") {
			Do CreateShape(tShapeType)
			#; add to label list
			Set:shape.Name'="" diagram.LabelList(shape.Name) = shape
		}
		ElseIf (tType = "Ens.BPL.Branch") {
			Do CreateShape(tShapeType)

			#; set bagged properties
			Do shape.SetProperty("Condition", tActivity.Condition)
			Do shape.SetProperty("Label", tActivity.Label)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)

			#; add to branch list
			If (shape.Index'="") {
				Set diagram.BranchList(shape.Index) = shape
				Set diagram.BranchList(shape.Index,"label") = tActivity.Label
			}
		}
		ElseIf (tType = "Ens.BPL.Empty") {
			Do CreateShape(tShapeType)
		}
		ElseIf (tType = "Ens.BPL.XSLT") {
			Do CreateShape(tShapeType)
			#; set bagged properties
			Do shape.SetProperty("Source", tActivity.Source)
			Do shape.SetProperty("Target", tActivity.Target)
			Do shape.SetProperty("XSLURL", tActivity.XSLURL)
			Do shape.SetProperty("XSLTVersion", tActivity.XSLTVersion)
			Set shape.Parameters = tActivity.Parameters
		}
		ElseIf (tType = "Ens.BPL.XPATH") {
			Do CreateShape(tShapeType)
			#; set bagged properties
			Do shape.SetProperty("Source", tActivity.Source)
			Do shape.SetProperty("Property", tActivity.Property)
			Do shape.SetProperty("Context", tActivity.Context)
			Do shape.SetProperty("Expression", tActivity.Expression)
			Do shape.SetProperty("PrefixMappings", tActivity.PrefixMappings)
			Do shape.SetProperty("SchemaSpec", tActivity.SchemaSpec)
		}
		ElseIf (tType = "Ens.BPL.Scope") {
			Do CreateShape(tShapeType)

			Set yPos = yPos + ..#YSPACE

			// join for end of scope
			Set join = ##class(Shape).%New("join")
			If (diagram.Layout="manual") {
				Set join.xPos = $S(tActivity.XEnd'="":tActivity.XEnd,1:xPos)
				Set join.yPos = $S(tActivity.YEnd'="":tActivity.YEnd,1:xPos)
			}
			Else {
				Set join.xPos = xPos
				Set join.yPos = yPos
			}
			Do diagram.InsertShape(join, pParent)
	
			Set xp = xPos
			Set yp = yPos

			Set ymax = yPos

			// process children of this scope
			Set prevAct = shape
			Do ..WalkActivityList(diagram, pParent,tActivity.Activities, .xp, .yp, .prevAct, ,,tActivity.Disabled)
			If (yp > ymax) {
				Set ymax = yp
			}

			// add compensation and fault handlers to scope
			// these are placed within the main "flow" of the scope
			Do ..WalkActivityList(diagram, pParent,tActivity.FaultHandlers, .xp, .yp, .prevAct,,,tActivity.Disabled)
			If (yp > ymax) {
				Set ymax = yp
			}

			If (tActivity.CompensationHandlers.Count() > 0) {
				Do ..WalkActivityList(diagram, pParent,tActivity.CompensationHandlers, .xp, .yp, .prevAct,,,tActivity.Disabled)
				If (yp > ymax) {
					Set ymax = yp
				}
			}

			// connect end of "flow" to join
			Do prevAct.ConnectTo(join)

			// move join to after placed shapes
			Set yPos = ymax
			If ((diagram.Layout'="manual") || (tActivity.YEnd="")) {
				Set join.yPos = ymax
			}
			Set prevAct = join
		}
		ElseIf (tType = "Ens.BPL.Flow") {
			Do CreateShape(tShapeType)

			Set yPos = yPos + ..#YSPACE

			// join for end of flow	
			Set join = ##class(Shape).%New("join")
			If (diagram.Layout="manual") {
				Set join.xPos = $S(tActivity.XEnd'="":tActivity.XEnd,1:xPos)
				Set join.yPos = $S(tActivity.YEnd'="":tActivity.YEnd,1:xPos)
			}
			Else {
				Set join.xPos = xPos
				Set join.yPos = yPos
			}
			Do diagram.InsertShape(join, pParent)
	
			Set ymax = yPos + ..#YSPACE
			Set c = tActivity.Activities.Count()
			If (c > 2) {
				Set adj = 2
			}
			Else {
				Set adj = 1
			}

			// process children of this flow
			For c = 1:1:tActivity.Activities.Count() {
				Set xp = xPos + ((c-adj) * ..#XSPACE) - (..#XSPACE/2)
				Set yp = yPos
				
				// assume each branch is enclosed within a <sequence>
				Set tSeq = tActivity.Activities.GetAt(c)
				Set prevAct = shape
				
				If (tSeq.%IsA("Ens.BPL.Sequence") && (tSeq.Activities.Count() > 0)) {
					Do ..WalkActivityList(diagram, pParent,tSeq.Activities, .xp, .yp, .prevAct, tSeq.Name,,tSeq.Disabled)
					If (yp > ymax) {
						Set ymax = yp
					}
					Do prevAct.ConnectTo(join)
				}
			}
			
			// move join to after placed shapes
			Set yPos = ymax
			If ((diagram.Layout'="manual") || (tActivity.YEnd="")) {
				Set join.yPos = ymax
			}
			Set prevAct = join
		}
		ElseIf (tType = "Ens.BPL.If") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Condition", tActivity.Condition)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)

			Set yPos = yPos + ..#YSPACE

			// join for end of if
			Set join = ##class(Shape).%New("join")
			If (diagram.Layout="manual") {
				Set join.xPos = $S(tActivity.XEnd'="":tActivity.XEnd,1:xPos)
				Set join.yPos = $S(tActivity.YEnd'="":tActivity.YEnd,1:xPos)
			}
			Else {
				Set join.xPos = xPos
				Set join.yPos = yPos
			}
			Do diagram.InsertShape(join, pParent)
	
			// process children of this If
			Set ymax = yPos + ..#YSPACE

			// get true and false sequences
			// make a guess about which to place first
			If ((tActivity.True.Count()=0) && (tActivity.False.Count()=0)) {
				#; JMD268
				Set seq(1) = tActivity.True
				Set seqlbl(1) = "true"
				Set seq(2) = tActivity.False
				Set seqlbl(2) = "false"
			}
			ElseIf (tActivity.True.Count() < tActivity.False.Count()) {
				Set seq(1) = tActivity.True
				Set seqlbl(1) = "true"
				Set seq(2) = tActivity.False
				Set seqlbl(2) = "false"
			}
			Else {
				Set seq(1) = tActivity.False
				Set seqlbl(1) = "false"
				Set seq(2) = tActivity.True
				Set seqlbl(2) = "true"
			}

			// place sequences
			For sq = 1:1:2 {
				Set xp = xPos
				Set yp = yPos + ..#YSPACE
				Set prevAct = shape
	
				If ($IsObject(seq(sq))) {
					Do ..WalkActivityList(diagram, pParent,seq(sq), .xp, .yp, .prevAct, seqlbl(sq))
					If (yp > ymax) {
						Set ymax = yp
					}
					If (prevAct = shape) {
						Do prevAct.ConnectTo(join,seqlbl(sq))
					}
					Else {
						Do prevAct.ConnectTo(join)
					}
				}
			}

			Set yPos = ymax
			
			// move join to after placed shapes
			If ((diagram.Layout'="manual") || (tActivity.YEnd="")) {
				Set join.yPos = ymax
			}
			Set prevAct = join
		}
		ElseIf (tType = "Ens.BPL.Switch") {
			Do CreateShape(tShapeType)

			// process switch
			Set caseCount = tActivity.Cases.Count()
			If (caseCount > 2) {
				// a little extra space for crowded switches
				Set yPos = yPos + ..#YSPACE
			}

			// join for end of switch
			Set join = ##class(Shape).%New("join")
			If (diagram.Layout="manual") {
				Set join.xPos = $S(tActivity.XEnd'="":tActivity.XEnd,1:xPos)
				Set join.yPos = $S(tActivity.YEnd'="":tActivity.YEnd,1:xPos)
			}
			Else {
				Set join.xPos = xPos
				Set join.yPos = yPos
			}
			Do diagram.InsertShape(join, pParent)
	
			// process children of this Switch
			Set ymax = yPos + ..#YSPACE
			If (caseCount > 2) {
				Set adj = 2
			}
			Else {
				Set adj = 0
			}
			Set cc = tActivity.Cases.Count()
			For c = 1:1:cc {
				// place children "out-of-phase"
				Set xp = xPos + ((c-adj) * ..#XSPACE) - (..#XSPACE/2)
				Set yp = yPos + ..#YSPACE
				Set case = tActivity.Cases.GetAt(c)
				Set prevAct = shape
				Set cond = ""
				Set lang = ""
				Set lbl = case.Name

				If (case.%IsA("Ens.BPL.Default")) {
					If (lbl = "") {
						Set lbl = "Default"
					}
				}
				Else {
					Set cond = case.Condition
					// Confirmed Property in BPLProcess is populated from Definition XData
					Set lang = case.LanguageOverride
				}
				
				If (case.Activities.Count() > 0) {
					Do ..WalkActivityList(diagram, pParent,case.Activities, .xp, .yp, .prevAct, lbl, cond, , ,lang)
					If (yp > ymax) {
						Set ymax = yp
					}
					Do prevAct.ConnectTo(join)
				}
				Else {
					// no activities-- direct line to Join
					Do prevAct.ConnectTo(join,lbl,cond)
				}
			}
	
			Set yPos = ymax
			
			// move join to after placed shapes
			If ((diagram.Layout'="manual") || (tActivity.YEnd="")) {
				Set join.yPos = ymax
			}
			Set prevAct = join
		}
		ElseIf (tType = "Ens.BPL.Receive") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Request", tActivity.Request)
			Do shape.SetProperty("Timeout", tActivity.Timeout)
		}
		ElseIf (tType = "Ens.BPL.Reply") {
			Do CreateShape(tShapeType)
		}
		ElseIf (tType = "Ens.BPL.Rule") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Rule", tActivity.Rule)
			Do shape.SetProperty("ResultLocation", tActivity.ResultLocation)
			Do shape.SetProperty("ReasonLocation", tActivity.ReasonLocation)
			Do shape.SetProperty("RuleContext", tActivity.RuleContext)
		}
		ElseIf (tType = "Ens.BPL.SQL") {
			Do CreateShape(tShapeType)

			// get code from stream
			Do shape.Code.CopyFrom(tActivity.SQL)
		}
		ElseIf (tType = "Ens.BPL.Sync") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Calls", tActivity.Calls)
			Do shape.SetProperty("Type", tActivity.Type)
			Do shape.SetProperty("Timeout", tActivity.Timeout)
			Do shape.SetProperty("AllowResync", tActivity.AllowResync)
		}
		ElseIf (tType = "Ens.BPL.Milestone") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Value", tActivity.Value)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)
		}
		ElseIf (tType = "Ens.BPL.Trace") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Value", tActivity.Value)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)
		}
		ElseIf (tType = "Ens.BPL.Alert") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Value", tActivity.Value)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)
		}
		ElseIf (tType = "Ens.BPL.Transform") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Class", tActivity.Class)
			Do shape.SetProperty("Source", tActivity.Source)
			Do shape.SetProperty("Target", tActivity.Target)
		}
		ElseIf (tType = "Ens.BPL.Sequence") {
			Do CreateShape(tShapeType)

			// set bagged properties

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.ForEach") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Property", tActivity.Property)
			Do shape.SetProperty("Key", tActivity.Key)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.Until") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Condition", tActivity.Condition)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.While") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Condition", tActivity.Condition)
			Do shape.SetProperty("LanguageOverride", tActivity.LanguageOverride)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.Throw") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Fault", tActivity.Fault)
		}
		ElseIf (tType = "Ens.BPL.Compensate") {
			Do CreateShape(tShapeType)

			// set bagged properties
			Do shape.SetProperty("Target", tActivity.Target)
		}
		ElseIf (tType = "Ens.BPL.CompensationHandler") {
			Do CreateShape(tShapeType)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.Catch") {
			Do CreateShape(tShapeType)
			// set bagged properties
			Do shape.SetProperty("Fault", tActivity.Fault)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		ElseIf (tType = "Ens.BPL.CatchAll") {
			Do CreateShape(tShapeType)

			// process children of this loop
			Do ..ProcessGroup(diagram, shape, tActivity.Activities,tActivity)
		}
		Else {
			// unknown activity
			Do CreateShape("unknown")
		}
		
		Set yPos = yPos + ..#YSPACE
	}
	
	Quit prevAct
	
CreateShape(shapetype)
	// common code to create shapes
	Set shape = ##class(Shape).%New(shapetype)
	Set shape.Name = tActivity.Name
	Set shape.Disabled = tActivity.Disabled
	Set shape.Annotation = tActivity.Annotation
	If (diagram.Layout="manual") {
		Set shape.xPos = $S(+tActivity.XPos'=0:tActivity.XPos,1:xPos)
		Set shape.yPos = $S(+tActivity.YPos'=0:tActivity.YPos,1:yPos)
	}
	Else {
		// note: this auto layout is ignored
		Set shape.xPos = xPos
		Set shape.yPos = yPos
	}

	Do diagram.InsertShape(shape, pParent)
	If ($IsObject(prevAct)) {
		Set tConnect = prevAct.ConnectTo(shape, connectLabel,connectCondition,connectDisabled,connectType,connectLanguageOverride)
		Set connectType = ""
		Set connectLabel = ""
		Set connectCondition = ""
		Set connectDisabled = 0
		Set prevAct = shape
	}
	Quit
}

/// Create a sub-group of shapes
ClassMethod ProcessGroup(diagram As Diagram, pParent As Shape, pActivities As Ens.BPL.ActivityList, pSequence As Ens.BPL.Activity)
{
	Set xPos = ..#XSTART
	Set yPos = ..#YSTART

	// start
	Set start = ##class(Shape).%New("start")
	Set start.Name = ""
	If (diagram.Layout="manual") {
		Set tChild = pActivities.GetAt(1)
		If ($IsObject(tChild)) {
			// place start before first item
			Set start.xPos = tChild.XPos
			Set start.yPos = tChild.YPos - ..#YSPACE
		}
		Else {
			Set start.xPos = xPos
			Set start.yPos = yPos
		}
	}
	Else {
		Set start.xPos = xPos
		Set start.yPos = yPos
	}
	Do diagram.InsertShape(start,pParent)
	Set yPos = yPos + ..#YSPACE
	
	Set prevAct = start

	// process activities for this group
	Do ..WalkActivityList(diagram, pParent,pActivities, .xPos, .yPos, .prevAct)

	// end
	Set end = ##class(Shape).%New("end")
	Set end.Name = ""
	If (diagram.Layout="manual") {
		Set tChild = pActivities.GetAt(pActivities.Count())
		If (pSequence.XEnd '= "") {
			Set end.xPos = pSequence.XEnd
		}
		ElseIf ($IsObject(tChild)) {
			// place end after last item
			Set end.xPos = tChild.XPos
		}
		Else {
			Set end.xPos = xPos
		}

		If (pSequence.YEnd '= "") {
			Set end.yPos = pSequence.YEnd
		}
		ElseIf ($IsObject(tChild)) {
			Set end.xPos = tChild.YPos + ..#YSPACE
		}
		Else {
			Set end.yPos = yPos
		}
	}
	Else {
		Set end.xPos = xPos
		Set end.yPos = yPos
	}
	Do diagram.InsertShape(end,pParent)

	If ($IsObject(prevAct)) {
		Do prevAct.ConnectTo(end)
	}
}

/// Find the BPL definition (as a stream) for the given
/// BPL class; return "" if not found.<BR>
/// Returns if this is a BPL or an BPLError XDATA block
/// Also returns Description for this class
ClassMethod GetBPLStream(cls As %String, ByRef pXDataName As %String, ByRef pDesc As %String, Output pTimestamp As %TimeStamp, pConcurrency As %Integer = -1) As %Stream.Object
{
	
	// id is the name of a BPL class, try to find it
	Set cdef = ##class(%Dictionary.ClassDefinition).%OpenId(cls,pConcurrency)
	If ('$IsObject(cdef)) {
		// no class
		Quit ""
	}
	
	Set pDesc = cdef.Description
	Set pTimestamp = $zdatetime(cdef.TimeChanged,3,,6)
	
	// try to find XDATA
	
	Set tXData = ""
	// first try BPLError
	If ##class(%Dictionary.XDataDefinition).IDKEYExists(cdef.Name,"BPLError") {
		Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(cdef.Name,"BPLError",pConcurrency)
		If $IsObject(tXData) Set pXDataName = "BPLError"
	}
	ElseIf ##class(%Dictionary.XDataDefinition).IDKEYExists(cdef.Name,"BPL") {
		Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(cdef.Name,"BPL",pConcurrency)
		If $IsObject(tXData) Set pXDataName = "BPL"
	}

	// neither xdata found, quit
	If '$IsObject(tXData) {
		Set pXDataName = ""
		Quit ""
	}
	
	// get XDATA as stream
	Set tStream = tXData.Data
	If ($IsObject(tStream)) {
		Do tStream.Rewind()
	}
	
	Quit tStream
}

/// Convert this diagram to BPL
Method ConvertToBPL(pOutStream As %BinaryStream, Output pConverted As %Boolean) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Set pConverted = 0
	Do {
		// Create a diagram parser
		Set tParser = ##class(Parser).%New()
		Set tSC = tParser.ParseDiagram($this)
		If $$$ISERR(tSC) Quit
		

		// Now what we have a Process object, validate it
		Set tSC = $$$OK
 		#; Need a validation context
 		Set tValidationContext=##class(Ens.BPL.ValidationContext).%New()
 		$$$ASSERT($IsObject(tValidationContext))
 
 		Do tParser.Process.Validate(.tSC,tValidationContext)
		If $$$ISERR(tSC) Quit

		// if ok, create BPL 
		Set pConverted = 1
		Set tSC = $$$ADDSC(tSC,tParser.Process.GenerateXML(pOutStream))
		If $$$ISERR(tSC) Quit
		
	} While (0)
Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Convert an  xml diagram-document into a set of BPL objects
ClassMethod CreateBPLFromXML(pInStream As %Stream.Object, pOutStream As %Stream.Object) As %Status
{
	Set $ZT="Trap",tSC=$$$OK

	Do {
		// create a diagram object
		Set tSC = ..CreateDiagramFromXML(pInStream,.tDiagram)

		If $$$ISERR(tSC) Quit
		
		// now create BPL objects from this diagram
		Set tSC = tDiagram.ConvertToBPL()
		
	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Convert an xml diagram-document into a Diagram and its related objects.
ClassMethod CreateDiagramFromXML(pInStream As %Stream.Object, ByRef pDiagram As Diagram) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Set pDiagram = ""
	
	Do {
		#; Create an XML import handler
		Set tHandler=##class(Ens.BPL.UI.DiagramImportHandler).%New() 
 			
		#; Parse the XML data in the specified stream
		Set tSC = ##Class(%XML.SAX.Parser).ParseStream(pInStream,tHandler)
		If $$$ISERR(tSC) Quit

		Set pDiagram = tHandler.Diagram	
		If ('$IsObject(pDiagram)) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to create BPL Diagram")
		}
		
	} While (0)

Exit
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Helper method to escape a string to HTML and replace all occurrences of &#39; with single quote ( ' )
ClassMethod EscapeForSVG(pText As %String) As %String [ Internal ]
{
	Set tHTML = $ZCVT(pText,"O","HTML")
	Set tEsc = ""
	Set p1 = 1
	While (1) {
		Set p2 = $F(tHTML,"&#39;",p1)
		If (p2 = 0) {
			Set tEsc = tEsc_$E(tHTML,p1,99999)
			Quit
		}
		Else {
			Set tEsc = tEsc_$E(tHTML,p1,p2-6) _ "'"
			Set p1 = p2
		}
	}
	Quit tEsc
}

}
