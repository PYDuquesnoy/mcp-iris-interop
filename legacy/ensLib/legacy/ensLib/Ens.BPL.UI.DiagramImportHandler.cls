/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// A SAX-handler for parsing a BPL diagram document.
Class Ens.BPL.UI.DiagramImportHandler Extends %XML.SAX.ContentHandler [ System = 4 ]
{

/// Result of parsing.
Property Diagram As Diagram;

/// Transient object used during parsing.
Property Shape As Shape;

Property InCode As %Boolean [ InitialExpression = 0 ];

Property InAnnotation As %Boolean [ InitialExpression = 0 ];

Property InPyFromImport As %Boolean [ InitialExpression = 0 ];

/// Transient object used during parsing.
Property CurrMessage As Ens.BPL.Message;

/// Transient object used during parsing.
Property Connector As Connector;

/// Transient object used during parsing.
Property Property As Ens.BPL.Property;

/// Index of shapes subscripted by index no.
Property Index As %String [ MultiDimensional ];

/// Converts list of attrs into an array keyed by attr name
Method UnpackAttrs(attrs As %List, ByRef array As %String) [ Private ]
{
	For i = 1:5:$LL(attrs) {
		If ($LG(attrs,i+1) '= "") {
			Set array($LG(attrs,i+1)) = $LG(attrs,i+4)
		}
	}
}

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List)
{
	Do ..UnpackAttrs(attrs,.arr)

	If (localname = "diagram") {
		Set ..Diagram = ##class(Diagram).%New()
		Set ..Diagram.Name = $G(arr("Name"))
		Set ..Diagram.Annotation = $G(arr("Annotation"))
		Set ..Diagram.ShowAnnotation = +$G(arr("ShowAnnotation"))
		Set ..Diagram.Component = +$G(arr("Component"))
		Set ..Diagram.Layout = $G(arr("Layout"),"automatic")
		Set ..Diagram.Language = $G(arr("Language"),$$$objectscript)
		Set ..Diagram.Request = $G(arr("Request"))
		Set ..Diagram.Response = $G(arr("Response"))
		Set ..Diagram.HasErrors = $G(arr("HasErrors"))
		Set ..Diagram.ContextSuperClass = $G(arr("ContextSuperClass"))
		Set ..Diagram.Version = $G(arr("Version"))
		Set ..Diagram.Includes = $G(arr("Includes"))
		Set ..Diagram.PyFromImport = $G(arr("PyFromImport"))

		Set ..Diagram.Width = +$G(arr("Width"))
		Set ..Diagram.Height = +$G(arr("Height"))
		Set:..Diagram.Width=0 ..Diagram.Width=2000
		Set:..Diagram.Height=0 ..Diagram.Height=2000
	}
	ElseIf ($IsObject(..Diagram)) {

		If (localname = "shape") {
			Set ..Shape = ##class(Shape).%New($G(arr("_Type")))
			Set ..Shape.Name = $G(arr("Name"))
			Set tBoolean = $ZCVT($G(arr("Disabled")),"L")
			Set ..Shape.Disabled = $Case(tBoolean,"true":1,"false":0,:+tBoolean)
			Set ..Shape.xPos = +$G(arr("xPos"))
			Set ..Shape.yPos = $G(arr("yPos"))

			Set tParentNo = $G(arr("parentShape"))
			If (tParentNo = "") {
				Do ..Diagram.InsertShape(..Shape)
			}
			Else {
				// insert into parent's list
				Set tParent = $G(..Index(+tParentNo))
				Do ..Diagram.InsertShape(..Shape,tParent)

				// what if there is no parent?
			}
			
			// put shape into index
			Set idx = $G(arr("_index"))

			If (idx '= "") {
				Set ..Index(+idx) = ..Shape
			}
			
			// loop over attrs, put extras into the "bag"
			Set k = $O(arr(""))
			While (k '= "") {
				If (",Name,_Type,xPos,yPos,Annotation,ShowAnnotation,parentShape,_index,Disabled," '[ (","_k_",")) {
					// here's one we don't recognize, bag it
					Do ..Shape.SetProperty(k,$G(arr(k)))
				}
				Set k = $O(arr(k))
			}
		}
		ElseIf (localname = "context") {
			// context for diagram
			Set ..Diagram.Context = ##class(Ens.BPL.Context).%New()
			Set ..Diagram.Context.Properties = ##class(Ens.BPL.PropertyList).%New()
		}

		ElseIf (localname = "property") {
			If ($IsObject(..Diagram.Context) && $IsObject(..Diagram.Context.Properties)) {
				// add a property to the context
				Set tProp = ##class(Ens.BPL.Property).%New()
				Set tProp.Name = $G(arr("name"))
				Set tProp.Type = $G(arr("type"),"%String")
				Set tProp.InitialExpression = $G(arr("initialexpression"))
				Set tProp.Collection = $G(arr("collection"))
				Set tProp.Instantiate = $G(arr("instantiate"))
				
				Do ..Diagram.Context.Properties.Insert(tProp)
				Set ..Property = tProp
			}
		}
		ElseIf (localname = "parameter") {
			If ($IsObject(..Property)) {
				// add parameter to current property in process context
				Set tParamName = $G(arr("name"))
				Set tParamValue = $G(arr("value"))

				Do ..Property.Parameters.SetAt(tParamValue,tParamName)
			}
			ElseIf ($IsObject(..Shape)) {
				#; parameter within XSLT
				Do ..Shape.Parameters.SetAt($G(arr("value")),$G(arr("name")))
			}
		}
		ElseIf (localname = "connection") {
			Set to = $G(arr("to"))
			Set from = $G(arr("from"))
			
			If ((to '= "") && (from '= "")) {
				Set toShape = ..Index(to)
				Set fromShape = ..Index(from)
				If ($IsObject(toShape) && $IsObject(fromShape)) {
					Set tDisabled = $G(arr("Disabled"))
					Set tDisabled = $S(tDisabled="true":1,1:0)
					Do fromShape.ConnectTo(toShape, $G(arr("Name")), $G(arr("Condition")), tDisabled,$G(arr("ConnectType")),$G(arr("languageOverride")))
				}
			}
		}
		ElseIf (localname = "annotation") {
			Set ..InAnnotation = 1
		}
		ElseIf (localname="pyFromImport") {
			Set ..InPyFromImport=1
		}
		ElseIf ($IsObject(..Shape)) {
			// $$$ASSERT(..Shape.Type = "call")
			Set:$Data(arr("languageOverride")) ..Shape.LanguageOverride=$G(arr("languageOverride"))
			If (localname = "request") {
				// create an object to hold data
				Set ..CurrMessage = ##class(Ens.BPL.Request).%New()
				Set ..CurrMessage.Type = $G(arr("type"))
				Set ..Shape.Request = ..CurrMessage
			}
			ElseIf (localname = "response") {
				// create an object to hold data
				Set ..CurrMessage = ##class(Ens.BPL.Response).%New()
				Set ..CurrMessage.Type = $G(arr("type"))
				Set ..Shape.Response = ..CurrMessage
			}
			ElseIf (localname = "assign") {
				$$$ASSERT($IsObject(..CurrMessage))
				// create an object to hold data
				Set tAssign = ##class(Ens.BPL.Assign).%New()
				Set tAssign.Property = $G(arr("property"))
				Set tAssign.Value = $G(arr("value"))
				Set tAssign.Action = $G(arr("action"))
				Set:tAssign.Action="" tAssign.Action = "set"
				Set tAssign.Key = $G(arr("key"),"""""")
				
				// insert
				Do ..CurrMessage.Activities.Insert(tAssign)
			}
			ElseIf (localname = "code") {
				// Required to save code content to XDATA BPL definition
				Set ..InCode = 1
			}
		}

	}
	
	Quit
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String)
{
	If (localname = "shape") {
		Set ..Shape = ""
	}
	ElseIf (localname = "connection") {
		Set ..Connector = ""
	}
	ElseIf (localname = "annotation") {
		Set ..InAnnotation = 0
	}
	ElseIf (localname = "pyFromImport") {
		Set ..InPyFromImport = 0
	}
	ElseIf (localname = "property") {
		Set ..Property = ""
	}
	ElseIf (localname = "request") {
		Set ..CurrMessage = ""
	}
	ElseIf (localname = "response") {
		Set ..CurrMessage = ""
	}
	ElseIf (localname = "code") {
		Set ..InCode = 0
	}

	Quit
}

Method characters(chars As %Library.String, length As %Library.Integer)
{
	If ($IsObject(..Shape) && ..InCode) {
		// add to code for this shape
		Do ..Shape.Code.Write(chars)
	}
	ElseIf ($IsObject(..Diagram) && ..InAnnotation) {
		If ('$IsObject(..Shape)) && '$IsObject(..Property) {
			// add to diagram annotation
			Set ..Diagram.Annotation = ..Diagram.Annotation _ chars
		}
		ElseIf $IsObject(..Shape) && '$IsObject(..Property) {
			// add to shape annotation
			Set ..Shape.Annotation = ..Shape.Annotation _ chars
		}
		ElseIf '$IsObject(..Shape) && $IsObject(..Property) {
			// add to property annotation
			Set ..Property.Annotation = ..Property.Annotation _ chars
		}
	}
	ElseIf ($IsObject(..Diagram) && ..InPyFromImport) {
		If ('$IsObject(..Shape)) && '$IsObject(..Property) {
			// add to diagram PyFromImport
			Set ..Diagram.PyFromImport = ..Diagram.PyFromImport _ chars
		}
	}

	Quit
}

}
