/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// This class is used to display a list within a ZEN Report.
Class %ZEN.Report.Display.list Extends childrenNode [ Deprecated, System = 4 ]
{

/// Specifies the group from which to obtain the entries in the list
Property group As %ZEN.Datatype.string;

/// Specifies the list type.<br>
/// Possible values are: "none","circle","square","disc", "1", "A", "a", "I", "i".<br>
/// PDF reports do not support "square" or "circle".
Property type As %ZEN.Datatype.string(VALUELIST = ",none,circle,square,disc,1,A,a,I,i") [ InitialExpression = "none" ];

/// Specifies an image to use for the list bullet.
Property image As %ZEN.Datatype.uri;

/// Use to separate rendered items
Property separator As %ZEN.Datatype.string(VALUELIST = ",none,line") [ InitialExpression = "none" ];

/// Specifies (as an integer) the first value for a list.  If <property>type</property> = "I", 
/// <property>startvalue</property> = 3 will start with "III".
Property startvalue As %ZEN.Datatype.integer [ InitialExpression = 1 ];

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	if ..group'="" {
		d ..%IncLevel(.context, .XSL, .delay)
	}
	d ..tagChildren()
	d ..%BeginDrawFo(.context,.XSL,.delay)
	If ..group="" Quit $$$OK
	
	$$$groupNumInc
	
	If ..image'="" {	
		Set ordered=0
	} ElseIf $case(..type,"disc":1,"circle":1,"square":1,"none":1,:0) {
		Set ordered=0
	} Else {
		Set ordered=1
	}
	
	// list container
	Do XSL.WriteLine("<fo:list-block"_$$$applyclass("list",.context)_">") 
	$$$stylefo
	
	Set mode="list"_$$$groupNum
	Do XSL.WriteLine("  <xsl:apply-templates select='"_..qualify(..group)_"' mode='"_mode_"' >")
	Do ..%ApplyLevelParameters(.context,.XSL,.delay)
	Do XSL.WriteLine("  </xsl:apply-templates>")
	
	
	Do XSL.WriteLine("</fo:list-block>")
	
	// template for each list item
	Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
	Do ..%DeclareLevelParameters(.context,.delay,.delay2)
	Do delay.WriteLine("  <fo:list-item>")
	
	Do delay.WriteLine("    <fo:list-item-label end-indent='label-end()'><fo:block>")
	If ordered {
		Do delay.WriteLine("      <xsl:variable name='listnum'>")
		Do delay.WriteLine("        <xsl:number />")
		Do delay.WriteLine("      </xsl:variable>")
		Do delay.WriteLine("      <xsl:number format='"_..type_"' value='$listnum + "_..startvalue_" - 1' />.")
	} ElseIf ..image'="" {
		Set url = ..%GetAbsoluteURL(..image,.context,1)
		Do delay.WriteLine("      <fo:external-graphic>")
		Do delay.WriteLine("        <xsl:attribute name='src'>url('"_url_"')</xsl:attribute>")
		Do delay.WriteLine("      </fo:external-graphic>")
	} ElseIf ..type="none" {
		Do delay.WriteLine($$$nbsp)
	} Else {
		// same as &bull;
		Do delay.WriteLine("      &#8226;")
	}
	Do delay.WriteLine("    </fo:block></fo:list-item-label>")
	
	Do delay.WriteLine("    <fo:list-item-body start-indent='body-start()'>")
	Do delay.WriteLine("    <fo:block>")
	Set delay2 = ##class(%GlobalCharacterStream).%New()
	Set i = ..children.Next(""),sc=$$$OK
	While i'="" {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set:child.class="" child.class=..class
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
			Do delay.WriteLine("<xsl:if test=""string("_child.field_")"">")
		}
		Set sc = child.%DrawToXSLFO(.context,.delay,.delay2)  Quit:$$$ISERR(sc)
		If ..separator="line" Do delay.WriteLine(" <fo:block/>")		
		If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
			Do delay.WriteLine("</xsl:if>")
		}

		Set i = ..children.Next(i)
	}
	Do delay.WriteLine("    </fo:block></fo:list-item-body>")
	Do delay.WriteLine("  </fo:list-item>")
	Do delay.WriteLine("</xsl:template>")
	Do delay.CopyFrom(delay2)
	Do ..%EndLevel(.context,.XSL,.delay)
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	If ..group'="" {
		d ..%IncLevel(.context, .XSL, .delay)
	}
	d ..tagChildren()
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	If ..group="" Quit $$$OK
	
	$$$groupNumInc
	If ..image'="" {	
		Set ordered=0
	} ElseIf $case(..type,"disc":1,"circle":1,"square":1,"none":1,:0) {
		Set ordered=0
	} Else {
		Set ordered=1
	}
	
	; ",none,circle,square,disc,1,A,a,I,i"
	; list-style-type: disc | circle | square | decimal | decimal-leading-zero | lower-roman | upper-roman | lower-greek | lower-latin | upper-latin | armenian | georgian | lower-alpha | upper-alpha | none | inherit
	Set type=$case(..type,"none":"none","circle":"circle","square":"square","disc":"disc","1":"decimal","A":"upper-latin","a":"lower-latin","I":"upper-roman","i":"lower-roman",:"none")
	Set ..style="list-style-type:"_type_..style
	If ordered {
		Do XSL.WriteLine("<ol start='"_..startvalue_"'>") $$$stylehtml
	} ElseIf ..image'="" {
		// have to do class manually because we aren't using $$$stylehtml
		Set style="list-style-image:url("""_..image_""");"_..style
		Do XSL.WriteLine("<ul class='"_..class_"' style='"_style_"'>")
	} Else {
		Do XSL.WriteLine("<ul>") $$$stylehtml
	}
	
	Set mode="list"_$$$groupNum
	Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(..group)_"' mode='"_mode_"' >")
	Do ..%ApplyLevelParameters(.context,.XSL,.delay)
	Do XSL.WriteLine("</xsl:apply-templates>")
	
	If ordered {
		Do XSL.WriteLine("</ol>")
	} Else {
		Do XSL.WriteLine("</ul>")
	}
	
	// template for each list item
	d ..tagChildren()
	Do delay.WriteLine("<xsl:template match='"_..qualify(..group)_"' mode='"_mode_"'>")
	Do ..%DeclareLevelParameters(.context,.delay,.delay2)
	
	Do delay.WriteLine("  <li>")
	Set delay2 = ##class(%GlobalCharacterStream).%New()
	Set i = ..children.Next(""),sc=$$$OK
	While i'="" {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
			Do delay.WriteLine("<xsl:if test=""string("_child.field_")"">")
		}
		Set sc = child.%DrawToHTML(.context,.delay,.delay2)  Quit:$$$ISERR(sc)
		If ..separator="line" Do delay.WriteLine(" <br/>")
		If child.%IsA("%ZEN.Report.Display.item"),child.suppressEmpty {
			Do delay.WriteLine("</xsl:if>")
		}
		Set i = ..children.Next(i)
	}
	Do delay.WriteLine("  </li>")
	Do delay.WriteLine("</xsl:template>")
	Do delay.CopyFrom(delay2)
	Do ..%EndLevel(.context,.XSL,.delay)
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

}
