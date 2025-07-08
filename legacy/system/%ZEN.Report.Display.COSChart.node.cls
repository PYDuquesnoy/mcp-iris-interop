/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.node Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property children As list Of %ZEN.Report.Display.COSChart.node;

Property attributes As %String [ Internal, MultiDimensional ];

Property name As %String;

Property content As %String;

Property id As %Integer;

Property parent As node;

Property displayed As %Boolean [ InitialExpression = 0 ];

Property %index As %Integer;

Property %angle As %Double;

Method setText(content As %String)
{
	Set ..content=content
}

Method setAttribute(property As %String, value As %String)
{
	if value="" quit
	Set ..attributes(property)=value
	if property="class" {
		do ##class(cchart).ParseCSSStyle("%ZEN.Report.Display.COSChart.cchart", .parsedClasses)
		Set attr="" for  { Set attr=$O(parsedClasses(value, attr),1,val) q:attr=""
			if $D(val),val'="" {
				Set ..attributes(attr)=$zstrip(val,"<>W")
			}
		}

		
	}
	if 1 { //$g(%context("html"))=1 {
		if property="style",'$IsObject(value) {
			Set value=$zcvt(value,"I","XML")
			for i=1:1:$L(value,";") {
				Set pair=$zstrip($P(value,";",i),"<>W")
				Set attr=$zstrip($P(pair,":"),"<>W")
				Set val=$zstrip($P(pair,":",2),"<>W")
				if $e(val)="'" {
					Set $e(val)="&apos;"
				}
				if $e(val,*)="'" {
					Set $e(val,$l(val))="&apos;"
				}
				if $e(val)="""" {
					Set $e(val)="&quot;"
				}
				if $e(val,*)="""" {
					Set $e(val,$l(val))="&quot;"
				}

				Set:attr'="" ..attributes(attr)=val
			}
		}
	}
}

Method getAttribute(property As %String)
{
	quit $g(..attributes(property))
}

Method createElementSVG(name As %String)
{
	Set tHTML5=%report.isHTML5
	if tHTML5 {
		Set ..name=name
	} else {
		Set ..name="svg:"_name
	}
	Set ..id=$i(^||%ISC.ZENReport.charts)
}

ClassMethod newElementSVG(name As %String)
{
	Set newElement=##class(node).%New()
	do newElement.createElementSVG(name)
	quit newElement
}

Method appendChild(node As %ZEN.Report.Display.COSChart.node) As %Status
{
	Set Status=..children.Insert(node)
	Set node.parent=##this
	quit Status
}

Method removeChild(node As %ZEN.Report.Display.COSChart.node)
{
	Set size=..children.Size
	for i=1:1:size {
		if $isObject(..children.GetAt(i))&&(..children.GetAt(i).id=node.id) {
			do ..children.RemoveAt(i)
		}
	}
}

Method insertBefore(newNode As node, existingNode As node)
{
	Set found = 0
	if (..children.Size=0) {
		do ..children.Insert(newNode)
		Set newNode.parent=##this
		Set found=1
		quit found
	}
	if (..children.Size=1) {
		Set found=1
		do ..children.SetAt(..children.GetAt(1),2)
		do ..children.SetAt(newNode,1)
		quit found
	}
	Set size=..children.Size
	for i=1:1:size {
		if ..children.GetAt(i).id=existingNode.id {
			; slide up
			Set found=1
			for j=size:-1:i {
				do ..children.SetAt(..children.GetAt(j),j+1)
			}
			do ..children.SetAt(newNode,i)
			Set newNode.parent=##this
			quit
		}
	}
	if (found=0) {
		do ..children.Insert(newNode)
	}
	quit found
}

Method clearChildren()
{
	; Should we walk subschildren and clear those as well?
	do ..children.Clear()
}

Method firstChild()
{
 	if ..children.Size=0 quit ""
	quit ..children.GetAt(1)
}

Method findSVGElement(id As %String)
{
	if id=$P(..getAttribute("id"),"_",1) {
		quit ##this
	} else {
		Set found=""
		for i=1:1:..children.Count() {

			Set found=..children.GetAt(i).findSVGElement(id)
			if found'="" quit
		}
		quit found
	}
}

Method Display(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Set tHTML5=%report.isHTML5
	if ..name=$s(tHTML5:"defs", 1:"svg:defs") {
		
		if tHTML5 {
			Do XSL.WriteLine("<defs>")
		} else {
			Do XSL.WriteLine("<svg:defs>")
		}

		// standard styles from cchart
		Set me = ##class(%Dictionary.CompiledClass).%OpenId("%ZEN.Report.Display.COSChart.cchart")
		if %report.isHTML5 {
			Set suffix=""
		} else {
			Set suffix="NoHTML5"
		}
		Set idx = me.XDatas.FindObjectId("%ZEN.Report.Display.COSChart.cchart"_"||SVGStyle"_suffix)
		Set data = me.XDatas.GetAt(idx).Data
		Do data.Rewind()
		Do XSL.CopyFrom(data)
		
		// override styles from ZEN Reports chart
		Set me = ##class(%Dictionary.CompiledClass).%OpenId(%report.%ClassName(1))
		if $isObject(me) {
			Set idx = me.XDatas.FindObjectId(%report.%ClassName(1)_"||SVGStyle")
			Set data = me.XDatas.GetAt(idx).Data
			Do data.Rewind()
			Do XSL.CopyFrom(data)
		}
		
		// standard defintions from cchart
		Set me = ##class(%Dictionary.CompiledClass).%OpenId("%ZEN.Report.Display.COSChart.cchart")
		Set idx = me.XDatas.FindObjectId("%ZEN.Report.Display.COSChart.cchart"_"||SVGDef"_suffix)
		Set data = me.XDatas.GetAt(idx).Data
		Do data.Rewind()
		Do XSL.CopyFrom(data)
		if tHTML5 {
			Do XSL.WriteLine("</defs>")
		} else {
			Do XSL.WriteLine("</svg:defs>")
		}
		quit
	}
	Set valid=1
	If ..name="path" && '$D(..attributes("d")) {
		Set valid=0 ; a path element must have a d attribute
	}
	If ..name="rect" && '($D(..attributes("width"))&&$D(..attributes("height"))) {
		Set valid=0 ; a rect element must have a height and width attribute
	}

	if valid {
		Do XSL.Write("<"_..name)
		Set notSVG("logicalHeight")=""
		Set notSVG("logicalWidth")=""
		Set notSVG("xOffset")=""
		Set notSVG("yOffset")=""
		Set notSVG("effectiveHeight")=""
		Set notSVG("effectiveWidth")=""
		s attr="" for {  set attr=$O(..attributes(attr),1,value) q:attr=""
			if '$D(notSVG(attr)) Do XSL.Write(" "_attr_"='"_$g(value)_"'")
		}
		Do XSL.Write(">")
		Do XSL.Write(..content)
		for i=1:1:..children.Size {
			Do ..children.GetAt(i).Display(.context,.XSL,.delay)
		}
		Do XSL.WriteLine("</"_..name_">")
	}
}

}
