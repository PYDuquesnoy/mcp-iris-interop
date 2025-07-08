/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// This class provides an interface for ZEN report tags to be displayed in a table.
/// Any tag that will be embedded in a table must extend tableOutput.
/// 
/// When a class that does not implement the "children" property extends tableOutput,
/// it must introduce a children property with XMLPROJECTION="none."  See the &lt;p&gt; tag
/// for an example.  
/// When a class that does not implement the "field" or "group" or "removeEmpty" property extends tableOutput
/// it must introduce a "field" or "group" or "removeEmpty" property with XMLPROJECTION="none"
Class %ZEN.Report.Display.tableOutput Extends controller [ Abstract, Deprecated, System = 4 ]
{

/// items and captions can now have groups that allow them to repeat on a line
/// when table draw in orient="col"
Property grouppath As %ZEN.Datatype.string;

/// Short-hand property to specify the elements caption within the table's header row.
Property caption As %ZEN.Datatype.caption;

/// Calculated property that indicates whether or not this element specifies a header cell.
Property hasHeader As %Boolean(XMLPROJECTION = "none") [ Calculated ];

/// Calculated property that indicates whether or not this element specifies a footer cell.
Property hasFooter As %Boolean(XMLPROJECTION = "none") [ Calculated ];

/// when grouppath is set, the number of columns in the group
Property colcount As %ZEN.Datatype.string;

/// fo attributes of block for things like orphan control
/// One would specify foblock="orphans='1'"
Property foblock As %ZEN.Datatype.string;

/// Is block wrapped inside a block container
Property includeBlockContainer As %ZEN.Datatype.boolean(XMLNAME = "include-block-container");

/// properties of block container such as overflow='hidden' to truncate data too large
Property blockContainerProperty As %ZEN.Datatype.string(XMLNAME = "block-container-property");

Property tooLongText As %ZEN.Datatype.string(VALUELIST = ",none,truncate,wrap,unset", XMLNAME = "too-long-text") [ InitialExpression = "unset" ];

/// truncate text if it is too long if truncate is true
Property truncate As %ZEN.Datatype.boolean;

/// the width to use in truncation, if not specified inherited from table cell
Property truncationWidth As %ZEN.Datatype.string(XMLNAME = "truncation-width");

/// the height to use in truncation.
Property truncationHeight As %ZEN.Datatype.string(XMLNAME = "truncation-height");

/// cross-tab properties<br>
/// get headers for cross-tab item from this xpath<br>
/// used for matching<br>
Property crosstabHeaderGroup As %ZEN.Datatype.string;

/// cross-tab properties<br>
/// get headers for cross-tab item from this xpath<br>
/// used for writing header labels<br>
Property crosstabHeaderGroupLabels As %ZEN.Datatype.string;

/// cross-tab properties<br>
/// get headers for cross-tab item from this xpath<br>
/// used for writing header labels<br>
/// relative to crosstabHeaderGroupLabels
Property crosstabHeaderLabelDataField As %ZEN.Datatype.string;

/// cross-tab properties<br>
/// get headers for cross-tab item from this xpath<br>
/// used for matching<br>
Property crosstabHeaderGroupTooLongText As %ZEN.Datatype.string(VALUELIST = ",none,truncate,wrap,unset") [ InitialExpression = "unset" ];

/// the width to use in truncation of cross tab header lablels, if not specified inherited from table cell
Property crosstabTruncationWidth As %ZEN.Datatype.string;

/// the height to use in truncation of cross tab header labels, if not specified inherited from table cell
Property crosstabTruncationHeight As %ZEN.Datatype.string;

/// Defaults to "".  Field (attribute or element) of crosstabHeaderGroup used in constructing match.
Property crosstabHeaderDataField As %ZEN.Datatype.string;

/// xpath representing "row" of table where cross-tab data lives
Property crosstabRowGroup As %ZEN.Datatype.string;

/// xpath representing data of cross-tab at row determined by crosstabRowGroup[$row]/
Property crosstabDataGroup As %ZEN.Datatype.string;

/// xpath representing data that will match against header name crosstabHeaderGroup[$col]
Property crosstabHeaderMatchField As %ZEN.Datatype.string;

/// xpath representing data that will appear in footer
Property crosstabFooterGroup As %ZEN.Datatype.string;

/// if non-null has footer data is formatted
Property crosstabFooterFormatNumber As %ZEN.Datatype.string;

/// xpath expression, which can use $pos, to get data to display in crosstab footer group
Property crosstabFooterDataField As %ZEN.Datatype.string;

Property linefeedTreatment As %ZEN.Datatype.string(VALUELIST = ",ignore,preserve,treat-as-space,treat-as-zero-width-space", XMLNAME = "linefeed-treatment");

Property rowspan As %ZEN.Datatype.integer;

Property colspan As %ZEN.Datatype.integer;

/// <p>Part of the tableOutput API that searches for a &lt;caption&gt; child and if it
/// finds one renders it (just as an &lt;item&gt; tag) as the row/column's header.</p><p>
/// As a short-hand, one can simply specify the caption attribute for the tag,
/// but that is less flexible.</p>
Method %DrawHeaderFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, orient As %String) As %Status
{
	//see if elt should have a header
	if ..crosstabHeaderGroupTooLongText="unset",%report.TooLongText'="unset" Set ..crosstabHeaderGroupTooLongText=%report.TooLongText
	If '..hasHeader {
		Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("th",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
		Do XSL.WriteLine("<fo:block/></fo:table-cell>")
		Quit $$$OK
	} 
	if (..crosstabHeaderGroup'="") {
	  if (orient'="row") {
		  if +%report.XsltVersion=2 {
		  	Do XSL.WriteLine("<xsl:variable name='prevmatch' select='position()'/>")
		  }
		  if ..crosstabHeaderGroupLabels'="" {
		  	Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroupLabels_"'>")
		  } else {
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")
		  }
		  Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
		  Do XSL.WriteLine("<xsl:variable name='currmatch' select='position()'/>")		  
	      Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("th",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
	      if (..crosstabHeaderGroupTooLongText="truncate") Do XSL.WriteLine("<fo:block-container "_..blockContainerProperty_$s(..crosstabHeaderGroupTooLongText="truncate":" overflow='hidden'",1:"")_$s(..crosstabTruncationWidth'="":" width='"_..crosstabTruncationWidth_"'",1:"")_$s(..crosstabTruncationHeight'="":" height='"_..truncationHeight_"'",1:"")_">")
	      Do XSL.WriteLine("<fo:block>")
	      if ..crosstabHeaderDataField="",..crosstabHeaderLabelDataField="" {
		      	If (..crosstabHeaderGroupTooLongText="wrap") {
					Do XSL.WriteLine("<xsl:variable name='wrappedtext'>")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name='text' select='.'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:variable>")				    
				    Do XSL.WriteLine("<xsl:value-of select='$wrappedtext'/>")
				} else {
	      			Do XSL.WriteLine("<xsl:value-of select='.'/>")
				}
								
		  } else {
				if ..crosstabHeaderLabelDataField'="" {
		  			Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderLabelDataField_"'/>")
			  	}			  
			  	elseif ..crosstabHeaderDataField'="" {
		  			Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderDataField_"'/>")
			  	}
	      }
	      Do XSL.WriteLine("</fo:block>")
	      if (..crosstabHeaderGroupTooLongText="truncate") Do XSL.WriteLine("</fo:block-container>")
	      Do XSL.WriteLine("</fo:table-cell>")
	      Do XSL.WriteLine("</xsl:for-each>")
	  }
	  Quit $$$OK
	}

	d ..tagChildren()
	//check for caption element
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			If child.tag="caption" {
				Set:child.class="" child.class=..class
				
				If ..removeEmpty,..field'="" {
					Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
				}
				
				Do child.%DrawCellFO(.context,.XSL,.delay,orient) 
				If ..removeEmpty,..field'="" {
					Do XSL.WriteLine("</xsl:if>")
				}
				Set found=1 
				Quit
			}
			Set i= ..children.Next(i)
		}
		Quit:found $$$OK
	}

	//no caption elt found
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
	}

	Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("th",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
	Do XSL.WriteLine("<fo:block >")
	if ..ifexpression'="" {
		X "s %val=("_..ifexpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=1'>")
	}
	
	Do XSL.WriteLine("<xsl:text>"_$zcvt(..caption,"O","XML")_"</xsl:text>")
	if ..ifexpression'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	
	Do XSL.WriteLine("</fo:block>")
	Do XSL.WriteLine("</fo:table-cell>")
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	
	Quit $$$OK
}

/// <p>Part of the tableOutput API that searches for a &lt;summary&gt; child and if it
/// finds one renders it (just as an &lt;item&gt; tag) as the row/column's footer.</p>
Method %DrawFooterFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, oldSummary As %Boolean, orient As %String) As %Status
{
	d ..tagChildren()

	if (..crosstabFooterGroup'="") {
	  if (orient="row") {
		  Do XSL.WriteLine("<fo:table-row>")
		  Do XSL.WriteLine("<fo:table-cell><fo:block/></fo:table-cell>")
	  }
	  if +%report.XsltVersion=2 {
	  	Do XSL.WriteLine("<xsl:variable name='prevmatch' select='position()'/>") // JSL4323
	  }
	  Do XSL.WriteLine("<xsl:for-each select='"_..crosstabFooterGroup_"'>")
	  Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
	  Do XSL.WriteLine("<xsl:variable name='currmatch' select='position()'/>")
	  Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
      Do XSL.WriteLine("<fo:block>")
      If ..crosstabFooterDataField'="" {
	      Do XSL.WriteLine("<xsl:value-of select='"_..crosstabFooterDataField_"'/>")
      } else {
	      if ..crosstabFooterFormatNumber="" {
		  	Do XSL.WriteLine("<xsl:value-of select='.'/>")
	      } else {
		    Do XSL.WriteLine("<xsl:value-of select='format-number(.,&quot;"_..crosstabFooterFormatNumber_"&quot;)'/>")
	      }
      }
      Do XSL.WriteLine("</fo:block>")
      Do XSL.WriteLine("</fo:table-cell>")
      Do XSL.WriteLine("</xsl:for-each>")
      if (orient="row") Do XSL.WriteLine("</fo:table-row>")
      Quit $$$OK
	}

 if oldSummary	{
	//see if elt should have a footer cell
	If '..hasFooter {
		Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
		Do XSL.WriteLine("<fo:block/></fo:table-cell>")
		Quit $$$OK
	}
}

	//check for summary elt
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			If child.tag="summary" {
				Do XSL.WriteLine("<!-- footer field="_child.field_" -->")
				Set:child.class="" child.class=..class
				Set child.parent=$$$THIS

				If ..removeEmpty,..field'="" {
					Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
				}
			
				Do child.%DrawCellFO(.context,.XSL,.delay,orient) 
				If ..removeEmpty,..field'="" {
					Do XSL.WriteLine("</xsl:if>")
				}
	
				Set found=1 
				;Quit
			}
			Set i= ..children.Next(i)
		}
		Quit:found $$$OK
	}

	//shouldn't happen, but display blank cell if footer but no summary tag
	if (oldSummary) {
		Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
		Do XSL.WriteLine("<fo:block/></fo:table-cell>")
	}

	Quit $$$OK
}

/// <p>Part of the tableOutput API that searches for a &lt;summary&gt; child and if it
/// finds one renders it (just as an &lt;item&gt; tag) as the row/column's footer.</p>
Method %DrawFooterToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	d ..tagChildren()

	//check for summary elt

	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			If child.tag="summary" {
				Do XSL.WriteLine("<!-- footer field="_child.field_" -->")
				Set:child.class="" child.class=..class
				Set child.parent=$$$THIS

				Do child.%DrawToAnnotatedXML(.context,.XSL,.delay) 
	
				Set found=1 
				;Quit
			}
			Set i= ..children.Next(i)
		}
		Quit:found $$$OK
	}

	Quit $$$OK
}

Method %DrawCellFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, orient As %String) As %Status
{
	if $this.%Extends("%ZEN.Report.Display.item"),..breakOnLineFeed {
		Set ..linefeedTreatment="preserve"
	}

	if ..%Extends("%ZEN.Report.Display.xslt") {
		Set sc = ..%DrawToXSLFO(.context,.XSL,.delay)
		quit sc
	}
	if ..grouppath="",..crosstabHeaderGroup="" {
		Set sc = ..%DrawCellFO1(.context, .XSL, .delay)
	} elseif ..crosstabHeaderGroup'="" {
		
		if (orient="col") {		
	    	Do XSL.WriteLine("<xsl:variable name='row' select='position()'/>")
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")
	    	Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
    
	    	Do XSL.WriteLine("<!-- Check to see whether this row has a visit for the column we're in -->")
	    	Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
	   		Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='number-rows-spanned'>"_..rowspan_"</xsl:attribute>")
			Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='number-columns-spanned'>"_..colspan_"</xsl:attribute>")

	        Do XSL.WriteLine("<xsl:choose>")
	        Set tcrosstabHeaderDataField=..crosstabHeaderDataField
	        if tcrosstabHeaderDataField'="" Set tcrosstabHeaderDataField="/"_tcrosstabHeaderDataField
	    	Do XSL.WriteLine("<xsl:when test='"_..crosstabHeaderGroup_"[$col]"_tcrosstabHeaderDataField_"="_..crosstabRowGroup_"[$row]/"_..crosstabDataGroup_"/"_..crosstabHeaderMatchField_"'>")

			Do XSL.WriteLine("<!-- Loop over all visits for this row ")
			Do XSL.WriteLine("     If there's a match, output the field info,")
			Do XSL.WriteLine("     otherwise put in an empty line -->")
			Do XSL.WriteLine("     <xsl:for-each select='"_..crosstabRowGroup_"[$row]/"_..crosstabDataGroup_"'>")
			Do XSL.WriteLine("     <xsl:if test='"_..crosstabHeaderGroup_"[$col]"_tcrosstabHeaderDataField_"="_..crosstabHeaderMatchField_"'>")
			if ..tooLongText="unset",%report.TooLongText'="unset" Set ..tooLongText=%report.TooLongText
			if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("<fo:block-container "_..blockContainerProperty_$s((..truncate)||(..tooLongText="truncate"):" overflow='hidden'",1:"")_$s(..truncationWidth'="":" width='"_..truncationWidth_"'",1:"")_$s(..truncationHeight'="":" height='"_..truncationHeight_"'",1:"")_">")
			DO XSL.WriteLine("<fo:block "_..foblock_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
			If ..tag="item"||(..tag="block")||(..tag="div")||(..tag="barcode") {
				Set sc= ..%DrawToXSLFO(.context,.XSL,.delay,1)
			}
			Do XSL.WriteLine("</fo:block>")
			if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("</fo:block-container>")
	
			Do XSL.WriteLine("     </xsl:if>")
			Do XSL.WriteLine("     </xsl:for-each>")
         
	    	Do XSL.WriteLine("     </xsl:when>")
	    	Do XSL.WriteLine("     <xsl:otherwise>")
	     	Do XSL.WriteLine("     <fo:block/>")
	    	Do XSL.WriteLine("     </xsl:otherwise>")
	    	Do XSL.WriteLine("     </xsl:choose>")
	    	Do XSL.WriteLine("</fo:table-cell>")
	       	Do XSL.WriteLine("</xsl:for-each>")
		
		} else {
			if ..crosstabHeaderGroupTooLongText="unset",%report.TooLongText'="unset" Set ..crosstabHeaderGroupTooLongText=%report.TooLongText
	        Set tcrosstabHeaderDataField=..crosstabHeaderDataField
	        if tcrosstabHeaderDataField'="" Set tcrosstabHeaderDataField="/"_tcrosstabHeaderDataField
			Do XSL.WriteLine("<xsl:variable name='row' select='position()'/>")
			Do XSL.WriteLine("<fo:table-row>")
			Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("th",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
			if (..crosstabHeaderGroupTooLongText="truncate") Do XSL.WriteLine("<fo:block-container "_..blockContainerProperty_$s(..crosstabHeaderGroupTooLongText="truncate":" overflow='hidden'",1:"")_$s(..crosstabTruncationWidth'="":" width='"_..crosstabTruncationWidth_"'",1:"")_$s(..crosstabTruncationHeight'="":" height='"_..truncationHeight_"'",1:"")_">")
			Do XSL.WriteLine("<fo:block>")
			if ..crosstabHeaderGroupLabels="" {
				If (..crosstabHeaderGroupTooLongText="wrap") {
					Do XSL.WriteLine("<xsl:variable name='wrappedtext'>")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
					Do XSL.WriteLine("<xsl:with-param name='text' select='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:variable>")				    
				    Do XSL.WriteLine("<xsl:value-of select='$wrappedtext'/>")
				} else {
					Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"'/>")
				}			
				
			} else {
				If (..crosstabHeaderGroupTooLongText="wrap") {
					Do XSL.WriteLine("<xsl:variable name='wrappedtext'>")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name='text' select='"_..crosstabHeaderGroupLabels_"[$row]"_tcrosstabHeaderDataField_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:variable>")				    
				    Do XSL.WriteLine("<xsl:value-of select='$wrappedtext'/>")
				} else {
					Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderGroupLabels_"[$row]"_tcrosstabHeaderDataField_"'/>")
				}


			}
			Do XSL.WriteLine("</fo:block>")
			if (..crosstabHeaderGroupTooLongText="truncate") Do XSL.WriteLine("</fo:block-container>")
			Do XSL.WriteLine("</fo:table-cell>")
			
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")

	    	Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
    
	    	Do XSL.WriteLine("<!-- Check to see whether this row has a visit for the column we're in -->")
	    	Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
	   		Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='number-rows-spanned'>"_..rowspan_"</xsl:attribute>")
			Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='number-columns-spanned'>"_..colspan_"</xsl:attribute>")

	        Do XSL.WriteLine("<xsl:choose>")
	    	Do XSL.WriteLine("<xsl:when test='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"="_..crosstabRowGroup_"[$col]/"_..crosstabDataGroup_"/"_..crosstabHeaderMatchField_"'>")

			Do XSL.WriteLine("<!-- Loop over all visits for this row ")
			Do XSL.WriteLine("     If there's a match, output the field info,")
			Do XSL.WriteLine("     otherwise put in an empty line -->")
			Do XSL.WriteLine("     <xsl:for-each select='"_..crosstabRowGroup_"[$col]/"_..crosstabDataGroup_"'>")

			Do XSL.WriteLine("     <xsl:if test='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"="_..crosstabHeaderMatchField_"'>")

			if ..tooLongText="unset",%report.TooLongText'="unset" Set ..tooLongText=%report.TooLongText
			if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("<fo:block-container "_..blockContainerProperty_$s((..truncate)||(..tooLongText="truncate"):" overflow='hidden'",1:"")_$s(..truncationWidth'="":" width='"_..truncationWidth_"'",1:"")_$s(..truncationHeight'="":" height='"_..truncationHeight_"'",1:"")_">")
			DO XSL.WriteLine("<fo:block "_..foblock_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
			If ..tag="item"||(..tag="block")||(..tag="div")||(..tag="barcode") {
				Set sc= ..%DrawToXSLFO(.context,.XSL,.delay,1)
			}
			Do XSL.WriteLine("</fo:block>")
			if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("</fo:block-container>")
	
			Do XSL.WriteLine("     </xsl:if>")
			Do XSL.WriteLine("     </xsl:for-each>")
         
	    	Do XSL.WriteLine("     </xsl:when>")
	    	Do XSL.WriteLine("     <xsl:otherwise>")
	     	Do XSL.WriteLine("     <fo:block/>")
	    	Do XSL.WriteLine("     </xsl:otherwise>")
	    	Do XSL.WriteLine("     </xsl:choose>")
	    	Do XSL.WriteLine("</fo:table-cell>")
	       	Do XSL.WriteLine("</xsl:for-each>")
	    	Do XSL.WriteLine("</fo:table-row>")			

		}
		

	} else {
		$$$itemNumInc
		Set mode="item"_$$$itemNum
		;if ..tag'="caption" Do XSL.WriteLine("<fo:table-row>")
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(..grouppath)_"' mode='"_mode_"' />")		
		;if ..tag'="caption" Do XSL.WriteLine("</fo:table-row>")
		Set delay2=##class(%GlobalCharacterStream).%New()
		Do delay.WriteLine("<xsl:template match='"_..qualify(..grouppath)_"' mode='"_mode_"'>")
		Set sc = ..%DrawCellFO1(.context, .delay, .delay2)
		Do delay.WriteLine("</xsl:template>")
		Do delay.CopyFrom(delay2)

	}
	Quit sc
}

/// Part of the tableOutput API that displays the element contained in a table cell for
/// the PDF report.
Method %DrawCellFO1(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Do ..IfIncludeCol(.context,.XSL,.delay)
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
	}
	Do XSL.WriteLine("<!-- tag="_..tag_" -->")
	Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("td",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
	Set i=..children.Next("")
	while i'="" {
		Set child=..children.GetAt(i)
		If child.tag="variable" {
			Do child.%DrawToXSLFO(.context,.XSL,.delay)
		}
		Set i=..children.Next(i)
	}
	Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='number-rows-spanned'>"_..rowspan_"</xsl:attribute>")
	Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='number-columns-spanned'>"_..colspan_"</xsl:attribute>")
	if ..colcount'="" {
		Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 0'>")
		Do XSL.WriteLine("<xsl:attribute name='ends-row'>true</xsl:attribute>")
		Do XSL.WriteLine("</xsl:if>")
	}
	if ..tooLongText="unset",%report.TooLongText'="unset" Set ..tooLongText=%report.TooLongText
	if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("<fo:block-container "_..blockContainerProperty_$s((..truncate)||(..tooLongText="truncate"):" overflow='hidden'",1:"")_$s(..truncationWidth'="":" width='"_..truncationWidth_"'",1:"")_$s(..truncationHeight'="":" height='"_..truncationHeight_"'",1:"")_">")
	DO XSL.WriteLine("<fo:block "_..foblock_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
	If ..id'="" { // JSL5217
		if $e(..id)="!" {
			Set id=$e(..id,2,*)
			DO XSL.WriteLine("<xsl:attribute name='id'>"_"<xsl:value-of select='"_id_"'/>"_"</xsl:attribute>")
		} else {
			DO XSL.WriteLine("<xsl:attribute name='id'>"_..id_"</xsl:attribute>")
		}
	}
	#; hack. Some elements have an extra parameter to tell it not to output the id. Use it if we can:
	If ..tag="item"||(..tag="block")||(..tag="summary")||(..tag="div")||(..tag="barcode") {
		Set sc= ..%DrawToXSLFO(.context,.XSL,.delay,1,1)
	}ElseIf (..tag="table") || (..tag="container"){
		Set sc= ..%DrawToXSLFO(.context,.XSL,.delay)
	}
	 Else {
		Set sc= ..%DrawToXSLFO(.context,.XSL,.delay,1)
	}

	Do XSL.WriteLine("</fo:block>")
	if (..includeBlockContainer)||(..truncate)||(..tooLongText="truncate") Do XSL.WriteLine("</fo:block-container>")
	Do XSL.WriteLine("</fo:table-cell>")
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	Do ..EndIfIncludeCol(.context,.XSL,.delay)	
	Quit sc
}

/// <p>Part of the tableOutput API that searches for a &lt;caption&gt; child and if it
/// finds one renders it (just as an &lt;item&gt; tag) as the row/column's header.</p><p>
/// As a short-hand, one can simply specify the caption attribute for the tag,
/// but that is less flexible.</p>
Method %DrawHeaderToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, orient As %String) As %Status
{
	d ..tagChildren()
	if ..crosstabHeaderGroupTooLongText="unset",%report.TooLongText'="unset" Set ..crosstabHeaderGroupTooLongText=%report.TooLongText
	//see if elt should have a header
	If '..hasHeader {
		Do XSL.WriteLine("<th>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
		Do XSL.WriteLine("</th>")
		Quit $$$OK
	} 
	if (..crosstabHeaderGroup'="") {
		if (orient'="row") {
		  if +%report.XsltVersion=2 {
		  	Do XSL.WriteLine("<xsl:variable name='prevmatch' select='position()'/>")
		  }
		  if ..crosstabHeaderGroupLabels'="" {
		  	Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroupLabels_"'>")
		  } else {
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")
		  }
		  Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
		  Do XSL.WriteLine("<xsl:variable name='currmatch' select='position()'/>")		  
	      if orient="col" {
		      Do XSL.WriteLine("<th>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	      } else {
		      Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	      }
	      if ..crosstabHeaderDataField="",..crosstabHeaderLabelDataField="" {
		      Do XSL.WriteLine("<xsl:value-of select='.'/>")
	      } else {
		    if ..crosstabHeaderLabelDataField'="" {
			    Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderLabelDataField_"'/>")
		    } elseif ..crosstabHeaderDataField'="" {
		    	Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderDataField_"'/>")
		    }
	      }
	      if (orient="col") {
	      	Do XSL.WriteLine("</th>")
	      } else {
		    Do XSL.WriteLine("</td>")
	      }
	      Do XSL.WriteLine("</xsl:for-each>")
		}
	  Quit $$$OK
	}

	//check for caption element
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			If ..removeEmpty,..field'="" {
				Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
			}

			Set:child.class="" child.class=..class
			If child.tag="caption" Do child.%DrawCellToHTML(.context,.XSL,.delay,orient) Set found=1 
			If ..removeEmpty,..field'="" {
				Do XSL.WriteLine("</xsl:if>")
			}

			If found=1 Quit
			
			Set i= ..children.Next(i)
		}
		Quit:found $$$OK
	}
	
	//no caption elt found
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
	}
	if ..ifexpression'="" {
		X "s %val=("_..ifexpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=1'>")
	}
	Do XSL.WriteLine("<th>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	Do XSL.WriteLine("<![CDATA["_..caption_"]]></th>")
	if ..ifexpression'="" {
		Do XSL.WriteLine("</xsl:if>")
	}

	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("</xsl:if>")
	}

	Quit $$$OK
}

/// <p>Part of the tableOutput API that searches for a &lt;summary&gt; child and if it
/// finds one renders it (just as an &lt;item&gt; tag) as the row/column's footer.</p>
Method %DrawFooterToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, oldSummary As %Boolean, orient As %String) As %Status
{
	d ..tagChildren()
	if (..crosstabFooterGroup'="") {
	  if (orient="row") {
		  Do XSL.WriteLine("<tr>")
		  Do XSL.WriteLine("<td/>")
	  }
	  if +%report.XsltVersion=2 {
		  Do XSL.WriteLine("<xsl:variable name='prevmatch' select='position()'/>") // JSL4323
	  }
	  Do XSL.WriteLine("<xsl:for-each select='"_..crosstabFooterGroup_"'>")
	  Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")	  	  
	  Do XSL.WriteLine("<xsl:variable name='currmatch' select='position()'/>")	  
	  Do XSL.WriteLine("<td "_$$$applyclass("td",.context)_">") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
       If ..crosstabFooterDataField'="" {
	      Do XSL.WriteLine("<xsl:value-of select='"_..crosstabFooterDataField_"'/>")
      } else {
	      if ..crosstabFooterFormatNumber="" {
		  	Do XSL.WriteLine("<xsl:value-of select='.'/>")
	      } else {
		    Do XSL.WriteLine("<xsl:value-of select='format-number(.,&quot;"_..crosstabFooterFormatNumber_"&quot;)'/>")
	      }
      }
      Do XSL.WriteLine("</td>")
      Do XSL.WriteLine("</xsl:for-each>")
	  if (orient="row") Do XSL.WriteLine("</tr>")      
      Quit $$$OK
	}

 if oldSummary {
	//see if elt should have a footer cell
	If '..hasFooter {
		Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
		Do XSL.WriteLine("</td>")
		Quit $$$OK
	}
 }

	//check for summary elt
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
  			If child.%Extends("%ZEN.Report.Display.tableOutput") {
  				s child.removeEmpty=..removeEmpty
  				Set tXMLProj = $ZCVT($$$comMemberArrayGet(child.%ClassName(1),$$$cCLASSproperty,"group",$$$cPROPparameter,"XMLPROJECTION"),"U")
	  			if tXMLProj="NONE" s child.group=..group
  			}

			Set:child.class="" child.class=..class
			If ..removeEmpty,..field'="" {
				Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
			}

			If child.tag="summary" Do child.%DrawCellToHTML(.context,.XSL,.delay,orient) Set found=1 ; Quit
			If ..removeEmpty,..field'="" {
				Do XSL.WriteLine("</xsl:if>")
			}

			Set i= ..children.Next(i)
		}
		Quit:found $$$OK
	}
	
	//shouldn't happen, but display blank cell if footer but no summary tag
	if (oldSummary) {
	 Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	 Do XSL.WriteLine("</td>")
	}
	Quit $$$OK
}

/// Part of the tableOutput API that displays the element contained in a table cell for
/// the HTML report.
Method %DrawCellToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, orient As %String) As %Status
{
	if ..%Extends("%ZEN.Report.Display.xslt") {
		Set sc= ..%DrawToHTML(.context,.XSL,.delay)
		quit sc
	}
	if (..grouppath="") && (..crosstabHeaderGroup="") {
		Set sc=..%DrawCellToHTML1(.context,.XSL,.delay)
	} elseif ..crosstabHeaderGroup'="" {
		if (orient="col") {
	    	Do XSL.WriteLine("<xsl:variable name='row' select='position()'/>")
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")
	    	Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
    
	    	Do XSL.WriteLine("<!-- Check to see whether this row has a visit for the column we're in -->")
	    	;if orient="row" Do XSL.WriteLine("<tr>")
	    	Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	   		Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='rowspan'>"_..rowspan_"</xsl:attribute>")
			Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='colspan'>"_..colspan_"</xsl:attribute>")
	        Do XSL.WriteLine("<xsl:choose>")
	        Set tcrosstabHeaderDataField=..crosstabHeaderDataField
	        if tcrosstabHeaderDataField'="" Set tcrosstabHeaderDataField="/"_tcrosstabHeaderDataField
	    	Do XSL.WriteLine("<xsl:when test='"_..crosstabHeaderGroup_"[$col]"_tcrosstabHeaderDataField_"="_..crosstabRowGroup_"[$row]/"_..crosstabDataGroup_"/"_..crosstabHeaderMatchField_"'>")

			Do XSL.WriteLine("<!-- Loop over all visits for this row ")
			Do XSL.WriteLine("     If there's a match, output the field info,")
			Do XSL.WriteLine("     otherwise put in an empty line -->")
			Do XSL.WriteLine("     <xsl:for-each select='"_..crosstabRowGroup_"[$row]/"_..crosstabDataGroup_"'>")
			Do XSL.WriteLine("     <xsl:if test='"_..crosstabHeaderGroup_"[$col]"_tcrosstabHeaderDataField_"="_..crosstabHeaderMatchField_"'>")

			If ..tag="item"||(..tag="block")||(..tag="div")||(..tag="barcode") {
				Set sc= ..%DrawToHTML(.context,.XSL,.delay,1)
			}
	
			Do XSL.WriteLine("     </xsl:if>")
			Do XSL.WriteLine("     </xsl:for-each>")
         
	    	Do XSL.WriteLine("     </xsl:when>")
	    	Do XSL.WriteLine("     <xsl:otherwise>")
	    	Do XSL.WriteLine("     <br/>")
	    	Do XSL.WriteLine("     </xsl:otherwise>")
	    	Do XSL.WriteLine("     </xsl:choose>")
	    	Do XSL.WriteLine("</td>")
			;if orient="row" Do XSL.WriteLine("</tr>")    	
	       	Do XSL.WriteLine("</xsl:for-each>")	
		} else { ; orient="row"
	        Set tcrosstabHeaderDataField=..crosstabHeaderDataField
	        if tcrosstabHeaderDataField'="" Set tcrosstabHeaderDataField="/"_tcrosstabHeaderDataField
			Do XSL.WriteLine("<xsl:variable name='row' select='position()'/>")
			Do XSL.WriteLine("<tr>")
			Do XSL.WriteLine("<th>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
			if ..crosstabHeaderGroupLabels="" {
				Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"'/>")
			} else {
				Do XSL.WriteLine("<xsl:value-of select='"_..crosstabHeaderGroupLabels_"[$row]"_tcrosstabHeaderDataField_"'/>")
			}
			Do XSL.WriteLine("</th>")
			
			Do XSL.WriteLine("<xsl:for-each select='"_..crosstabHeaderGroup_"'>")

	    	Do XSL.WriteLine("<xsl:variable name='col' select='position()'/>")
    
	    	Do XSL.WriteLine("<!-- Check to see whether this row has a visit for the column we're in -->")
	    	Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	   		Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='rowspan'>"_..rowspan_"</xsl:attribute>")
			Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='colspan'>"_..colspan_"</xsl:attribute>")

	        Do XSL.WriteLine("<xsl:choose>")
	    	Do XSL.WriteLine("<xsl:when test='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"="_..crosstabRowGroup_"[$col]/"_..crosstabDataGroup_"/"_..crosstabHeaderMatchField_"'>")

			Do XSL.WriteLine("<!-- Loop over all visits for this row ")
			Do XSL.WriteLine("     If there's a match, output the field info,")
			Do XSL.WriteLine("     otherwise put in an empty line -->")
			Do XSL.WriteLine("     <xsl:for-each select='"_..crosstabRowGroup_"[$col]/"_..crosstabDataGroup_"'>")

			Do XSL.WriteLine("     <xsl:if test='"_..crosstabHeaderGroup_"[$row]"_tcrosstabHeaderDataField_"="_..crosstabHeaderMatchField_"'>")

			If ..tag="item"||(..tag="block")||(..tag="div")||(..tag="barcode") {
				Set sc= ..%DrawToHTML(.context,.XSL,.delay,1)
			}

			Do XSL.WriteLine("     </xsl:if>")
			Do XSL.WriteLine("     </xsl:for-each>")
         
	    	Do XSL.WriteLine("     </xsl:when>")
	    	Do XSL.WriteLine("     <xsl:otherwise>")
	    	Do XSL.WriteLine("     <br/>")
	    	Do XSL.WriteLine("     </xsl:otherwise>")
	    	Do XSL.WriteLine("     </xsl:choose>")
	    	Do XSL.WriteLine("</td>")
	       	Do XSL.WriteLine("</xsl:for-each>")
	    	Do XSL.WriteLine("</tr>")			


		}
	} else {
		Set mode="item"
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(..grouppath)_"' mode='"_mode_"' />")		
		Set delay2=##class(%GlobalCharacterStream).%New()
		Do delay.WriteLine("<xsl:template match='"_..qualify(..grouppath)_"' mode='"_mode_"'>")
		Set sc=..%DrawCellToHTML1(.context,.delay,.delay2)
		Do delay.WriteLine("</xsl:template>")
		Do delay.CopyFrom(delay2)

	}
	Quit sc
}

Method %DrawCellToHTML1(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{

	Do ..IfIncludeCol(.context,.XSL,.delay)
	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("<xsl:if test="""_..xpath_"/"_..field_"/text()"">")
	}
	if ..colcount'="" {
		$$$varNumInc
		Do XSL.WriteLine("<xsl:variable name='tr"_$$$varNum_"'>")
		Do XSL.WriteLine("<![CDATA[")
		Do XSL.WriteLine("<tr>")
		Do XSL.WriteLine("]]>")
		Do XSL.WriteLine("</xsl:variable>")
		Do XSL.WriteLine("<xsl:variable name='etr"_$$$varNum_"'>")
		Do XSL.WriteLine("<![CDATA[")
		Do XSL.WriteLine("</tr>")
		Do XSL.WriteLine("]]>")
		Do XSL.WriteLine("</xsl:variable>")
		
		Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 1  or (("_..colcount_") = 1)'>")
		Do XSL.WriteLine("<xsl:value-of select='$tr"_$$$varNum_"' disable-output-escaping='yes'/>")
		Do XSL.WriteLine("</xsl:if>")
	}

	Do XSL.WriteLine("<td>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='rowspan'>"_..rowspan_"</xsl:attribute>")
	Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='colspan'>"_..colspan_"</xsl:attribute>")

	If ..tag="item"||(..tag="block")||(..tag="summary")||(..tag="div")||(..tag="barcode") {
		#; hack to tell item tags that they have already been styled
		Set sc= ..%DrawToHTML(.context,.XSL,.delay,1)
	} Else {
		Set sc= ..%DrawToHTML(.context,.XSL,.delay)
	}
	Do XSL.WriteLine("</td>")
	if ..colcount'="" {
		Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 0'>")
		Do XSL.WriteLine("<xsl:value-of select='$etr"_$$$varNum_"' disable-output-escaping='yes'/>")
		Do XSL.WriteLine("</xsl:if>")
	}

	If ..removeEmpty,..field'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	Do ..EndIfIncludeCol(.context,.XSL,.delay)
	Quit sc
}

Method hasHeaderGet() As %Boolean
{
	If ..caption'="" Quit 1
	If ..crosstabHeaderGroup'="" Quit 1
	If '..%IsA("%ZEN.Report.Display.childrenNode") Quit 0
	d ..tagChildren()
	Set header=0
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		If child.tag="caption" Set header=1 Quit
		Set i= ..children.Next(i)
	}
	Quit header
}

Method hasFooterGet() As %Boolean
{
	If '..%IsA("%ZEN.Report.Display.childrenNode") Quit 0
	d ..tagChildren()
	Set footer=0
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		If child.tag="summary" Set footer=1 Quit
		Set i= ..children.Next(i)
	}
	Quit footer
}

/// Returns the width of the cell containing this object.
Method %Width()
{
	Set width=..width
	If width=""  {
		$$$createStyleObject(..style,so)
		Set width = $g(so("width"))
	}
	if $e(width,$L(width))="%",..IsFop() {
		Set width="proportional-column-width("_$e(width,1,$L(width)-1)_")"
	}
	q width
}

/// Returns the width of the cell containing this object.
Method %OldWidth()
{
	If ..width'="" Quit ..width
  	$$$createStyleObject(..style,so)
  	Quit $g(so("width"))
}

/// Returns the width of the header cell for this object.
Method %HeaderWidth()
{
	If '..hasHeader Quit ..%Width()
	
	//check for caption element
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		d ..tagChildren()
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
			If child.tag="caption" Set width=child.%Width() Quit
			Set i= ..children.Next(i)
		}
		Quit:$d(width) width 
	}
	
	//No caption elt, so just use the cell width
	Quit ..%Width()
}

/// Returns the width of the footer cell for this object.
Method %FooterWidth()
{
	If '..hasFooter Quit ..%Width()
	
	//check for caption element
	If ..%IsA("%ZEN.Report.Display.childrenNode") {
		d ..tagChildren()
		Set i = ..children.Next(""),found=0
		While (i'="") {
			Set child=..children.GetAt(i)
			d ..updateFromTemplate(.child)			
			If child.tag="summary" Set width=$g(width)+child.%Width() ; Quit
			Set i= ..children.Next(i)
		}
		Quit:$d(width) width 
	}
	
	//No summary elt, so just use the cell width
	Quit ..%Width()
}

Method updateFromTemplate(child) [ Internal ]
{
	d ##class(%ZEN.Report.Display.node).updateFromTemplate(.child)
}

Method tagChildren1() [ Internal ]
{
	s parent=$$$THIS
	if (parent.%IsA("%ZEN.Report.Display.childrenNode")) {
		Set i = parent.children.Next("")
		While (i'="") {
			Set child = parent.children.GetAt(i)
			s child.xmlnamespace=parent.xmlnamespace
			s child.xmlnamespaceprefix=parent.xmlnamespaceprefix
			Set i= parent.children.Next(i)
		}
	}
}

ClassMethod IsFop() As %Boolean [ Internal ]
{
	q +$g(^%SYS("zenreport","oldfop"))
}

ClassMethod %DrawSort(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, orderby As %String, datatype As %String) As %Status
{
		if orderby'="",orderby'=$c(0) {
			Set %orderby=orderby
			 if $e(%orderby)="!" {
				Set %orderby=$e(%orderby,2,$L(%orderby))
				X "Set %orderby="_%orderby
		}

		For i=1:1:$L(%orderby,",") {
			Set xpath=$P(%orderby,",",i)
			Do XSL.Write("<xsl:sort")
			Do XSL.Write(" select='"_$zstrip($P(xpath,"\",1),"<>W")_"'")
			Set direction=$zstrip($zcvt($P(xpath,"\",2),"u"),"<>W") Set:direction="" direction="ASC" Set:((direction'="ASC")&&(direction'="DESC")) direction="ASC" 
			if direction="ASC" Do XSL.Write(" order='ascending' ")
			if direction="DESC" Do XSL.Write(" order='descending' ")
			Set datatypePiece = $zstrip($P(xpath,"\",3),"<>W")
			Do XSL.Write(" data-type='"_$s(datatypePiece'="":datatypePiece,1:datatype)_"'")
			Do XSL.WriteLine("/>")
		}
	}
}

Method %BeginGroup(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, mode As %String, name As %String)
{
	Do XSL.WriteLine("<xsl:apply-templates select='"_name_"' mode='"_mode_"' >")
	Do ..%IncLevel(.context,.XSL,.delay)
	Do ..%ApplyLevelParameters(.context,.XSL,.delay)
	Do XSL.WriteLine("<xsl:with-param  name='prevmatch' select='position()'/>")
}

Method %BeginGroupNoInc(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, mode As %String, name As %String)
{
	Do XSL.WriteLine("<xsl:apply-templates select='"_name_"' mode='"_mode_"' >")
	Do ..%ApplyLevelParameters(.context,.XSL,.delay) ; this increments ..applyLevel
	Do XSL.WriteLine("<xsl:with-param  name='prevmatch' select='position()'/>")
}

Method %EndGroup(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, mode As %String, name As %String)
{
		Do XSL.WriteLine("</xsl:apply-templates>")
}

}
