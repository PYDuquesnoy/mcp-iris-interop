/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This tag is the basic tag for displaying hard-coded values and data
/// returned by the report.
Class %ZEN.Report.Display.item Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// If the value attribute is specified, the &lt;item&gt; renders that as a
/// literal value.
Property value As %ZEN.Datatype.caption;

/// If the field attribute is specified, the &lt;item&gt; renders the value
/// of that field in the XML data.  Note: field is actually used
/// as an XPath expression, so if you have the data:<br>
/// <p>&lt;record id='1'&gt;&lt;customer&gt;MegaPlex Systems&lt;/customer&gt;&lt;/record&gt;</p>
/// one would obtain the value of the id attribute with the XPath 
/// expression '@id', whereas to obtain the value of the child element
/// customer one would use the XPath expression 'customer'.
Property field As %ZEN.Datatype.string;

/// <p>If the special attribute is specified, the <item> renders a
/// pre-definied piece of dynamic data.  Possible values are 
/// currently: </p>
/// <ul>
/// <li>number : gives the record number within the group.</li>
/// <li>page-number : inserts the page number within a PDF report.  Is rendered as '##' in HTML.</li>
/// <li>page-count : inserts the number of pages within a PDF report.  It is rendered as '##' in HTML.</li>
/// <li>page-number-of : inserts the page number in the form '2 of 18'.  It is rendered as '## of ##' in HTML.</li>
/// <li>page-number-/ : inserts the page number in the form '2/18'.  It is rendered as '##/##' in HTML.</li>
/// </ul>
Property special As %ZEN.Datatype.string(VALUELIST = ",number,page-count,page-number,page-number-of,page-number-/,page-count-with-xpath,page-number-of-with-xpath,page-number-/-with-xpath");

/// <dl>
/// <dt>Example: &lt;item special="page-number-of" />.</dt>
/// <dd>This will give something like "1 of 9".</dd>
/// <dt>Example (z is of in Polish): &lt;item special="page-number-of" ofString=" z " />.</dt>
/// <dd>This will give something like "1 z 9".</dd>
/// </dl>
Property ofString As %ZEN.Datatype.caption [ InitialExpression = " of " ];

/// Optional formatting string for a numeric output.<br>
/// Number formats are specified in the
/// format required for the XPath format-number function.
Property formatNumber As %ZEN.Datatype.string;

/// Optional hyperlink to place around the item's data.<br>
/// If the link attribute begins with
/// an exclamation point, it is interpreted as an XPath expression just as in the field
/// attribute.  This allows you to dynamically generate URLs within the XML data, and then
/// use these customized URLs in the display.
Property link As %ZEN.Datatype.string;

/// Preserve linefeed in data
Property breakOnLineFeed As %ZEN.Datatype.boolean;

/// Preserve spaces in data
Property literalSpaces As %ZEN.Datatype.boolean;

/// Insert zero-width spaces after characters.  This allows field to wrap when in too short a column
Property insertZeroWidthSpaces As %ZEN.Datatype.boolean(XMLNAME = "insert-zero-width-spaces");

/// reverse string in XSL-FO mode
Property reverse As %ZEN.Datatype.boolean;

/// the item's field is xml and should be copied to the output
Property copyxml As %ZEN.Datatype.boolean;

/// the item's field is well-formed html and should either be copied as html or transformed to XSL-FO
Property copyhtml As %ZEN.Datatype.boolean;

/// the item's field is well-formed html and should either be copied as html or transformed to XSL-FO
Property copyhtml86 As %ZEN.Datatype.boolean;

/// the item's field is well-formed xml and defines a DeepSee table in canoncial format
Property createtable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If suppressDuplicates is 1 then an item that matches previous item is displayed as empty
Property suppressDuplicates As %ZEN.Datatype.boolean;

/// If displayCaption is 1 we display the caption of the item when the item is rendered
Property displayCaption As %ZEN.Datatype.boolean;

/// If suppressEmpty is 1 we suppress the rendering of the item and any following break if it is empty
Property suppressEmpty As %ZEN.Datatype.boolean;

/// expression that will be evaluated and put in output if "if" condition is true
Property expression As %ZEN.Datatype.string;

/// if expression that controls output of expression
Property if As %ZEN.Datatype.string [ InitialExpression = "1" ];

/// call - name of xsl:template to call
/// when call is defined
Property call As %ZEN.Datatype.string;

/// list of xpaths, xpath function calls, and XSLT function calls. 
/// for each string here an xsl:with-param is generated with its select attribute set from here
Property params As %ZEN.Datatype.list(DELIMITER = ";");

/// for each name here an xsl:with-param is generated with its name attribute set from here
Property paramNames As %ZEN.Datatype.list(DELIMITER = ";");

/// For multi-line caption
Property multiline As %ZEN.Datatype.boolean;

/// show-destination attribute of fo:basic-link
Property showDestination As %ZEN.Datatype.string(XMLNAME = "show-destination") [ InitialExpression = "replace" ];

/// indicate-destination attribute of fo:basic-link
Property indicateDestination As %ZEN.Datatype.string(XMLNAME = "indicate-destination") [ InitialExpression = "false" ];

/// <p>If the appendToLastPage attribute and special attribute are defined, the string 
/// value will be appended to the end of the %ZENLastPage string to allow the <item> 
/// special featues reference a page-number-citation ref-id that was generate by a <body>
/// with the appendIdToLastPage attribue set to "true"</p>
Property appendToZenLastPage As %ZEN.Datatype.string;

/// When table uses sql, fieldnum when non-null is number of field in sql
Property fieldnum As %ZEN.Datatype.integer;

/// When table uses sql, fieldname when non-null is name of field in sql
Property fieldname As %ZEN.Datatype.string;

/// True if Excel numeric field
Property isExcelNumber As %ZEN.Datatype.boolean;

/// True if Excel date field
Property isExcelDate As %ZEN.Datatype.boolean;

/// True if Excel time field
Property isExcelTime As %ZEN.Datatype.boolean;

/// if non-null is display number format of element value, only effective when mode="displayxlsx"
Property excelNumberFormat As %ZEN.Datatype.string;

/// column name instead of default which is fieldName
Property excelName As %ZEN.Datatype.string;

/// identifies this item as an excel Aggregate.  Note that AGGREGATETAG parameter must be set in report for aggregate to appear!
Property isExcelAggregate As %ZEN.Datatype.boolean;

/// xmlname - used to output item as having the specified xmlname when drawing to annotated xml for Excel
Property xmlname As %ZEN.Datatype.string;

/// excel formula function
Property excelFormula As %ZEN.Datatype.string;

/// placeholder
/// marks an aggregate as a placeholder
/// used for alignment
Property placeholder As %ZEN.Datatype.boolean;

XData ConvertHTML
{
<zenxslt>
<xsl:template match="br|BR">
<!-- <fo:block>&#160;</fo:block> -->
<xsl:text>&#x0A;</xsl:text>
</xsl:template>
		<xsl:template match="OL|ol">
		<fo:block>
        <fo:list-block>
            <xsl:apply-templates select="LI|li" mode="ordered"/>
        </fo:list-block>
        </fo:block>
    </xsl:template>
    		<xsl:template match="UL|ul">
		<fo:block>
        <fo:list-block>
            <xsl:apply-templates select="LI|li" mode="unordered"/>
        </fo:list-block>
        </fo:block>
    </xsl:template>

    <xsl:template match="LI|li" mode="ordered">
        <fo:list-item>
            <fo:list-item-label end-indent="label-end()">
                <fo:block>
                    <xsl:value-of select="concat(position(),&quot;.&quot;)" />
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>
                    <xsl:apply-templates ></xsl:apply-templates>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item> 
        
    </xsl:template>
        <xsl:template match="LI|li" mode="unordered">
        <fo:list-item>
            <fo:list-item-label end-indent="label-end()">
                <fo:block>
                    <xsl:text>&#x2022;</xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>
					<xsl:apply-templates ></xsl:apply-templates>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item> 
        
    </xsl:template>

<xsl:template match="P|p|div">
        <fo:block>
    		<xsl:if test="@align">
        		<xsl:attribute name="text-align">
                    <xsl:value-of select="@align"/>
		        </xsl:attribute>
    		</xsl:if>
        	<xsl:if test="string-length(@style) &gt; 0">
        		<xsl:attribute name="{translate(substring-before(@style,':'),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')}">
        			<xsl:choose>
        			<xsl:when test="normalize-space(substring-before(substring-after(@style,':'),';'))">
                    	<xsl:value-of select="normalize-space(substring-before(substring-after(@style,':'),';'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(substring-after(@style,':'))"/>
                    </xsl:otherwise>
                    </xsl:choose>
		        </xsl:attribute>
    		</xsl:if>
        <xsl:apply-templates></xsl:apply-templates>
        <fo:block>&#160;</fo:block>
        </fo:block>
    </xsl:template>
    <xsl:template match="SPAN|span">
        <fo:inline>
        	<xsl:if test="@style">
        		<xsl:attribute name="{substring-before(@style,':')}">
                    <xsl:value-of select="substring-before(substring-after(substring-after(@style,':'),' '),';')"/>
		        </xsl:attribute>
    		</xsl:if>
        <xsl:apply-templates></xsl:apply-templates>
        </fo:inline>
    </xsl:template>
	 <!-- begin Trak change 6/15/2015 JSL5010 -->
	 <xsl:template match="pre">
		<fo:block white-space-collapse="false" font-family="monospace" font-size="10pt"><xsl:apply-templates/></fo:block>
	</xsl:template>
	<xsl:template match="h1">
		<fo:block font-size="18pt">
		<xsl:call-template name="set-alignment"/>
		<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="h2">
		<fo:block font-size="14pt">
		<xsl:call-template name="set-alignment"/>
		<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="h3">
	<fo:block font-size="12pt" font-weight="bold"
		space-before="6pt">
		<xsl:call-template name="set-alignment"/>
		<xsl:apply-templates/>
	</fo:block>
	</xsl:template>
	<xsl:template name="set-alignment">	
		<xsl:for-each select="tokenize(@style,';')">
	    	<xsl:variable name="name1">
	    	<xsl:value-of select="normalize-space(substring-before(.,':'))"/>
	    	</xsl:variable>
	    	<xsl:if test="(($name1='text-align'))">
	    	<xsl:attribute name="{$name1}">
	    	<xsl:value-of select="normalize-space(substring-after(.,':'))"/>
	    	</xsl:attribute>
	    	</xsl:if>
	    	</xsl:for-each>
	</xsl:template>
	 <!-- end Trak change 6/15/2015 JSL5010 -->    
     <xsl:template match="FONT|font">
  	<xsl:variable name="color">
    <xsl:choose>
      <xsl:when test="@color">
        <xsl:value-of select="@color"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:variable name="size">
    <xsl:choose>
      <xsl:when test="@size">
     <!-- use Chris's new algorithm -->
     <xsl:choose>
      <xsl:when test="@size &lt;= 1">
        <xsl:text>xx-small</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 2">
        <xsl:text>x-small</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 3">
        <xsl:text>small</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 4">
        <xsl:text>medium</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 5">
        <xsl:text>large</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 6">
        <xsl:text>x-large</xsl:text>
      </xsl:when>
      <xsl:when test="@size &lt;= 7">
        <xsl:text>xx-large</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>xx-large</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
      <xsl:variable name="face">
    <xsl:choose>
      <xsl:when test="@face and @face!=''">
        <xsl:value-of select="@face"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <fo:inline>
  <xsl:if test="$size!=''">
  <xsl:attribute name="font-size">
  <xsl:value-of select="$size"/>
  </xsl:attribute>
  </xsl:if>
  <xsl:if test="$face!=''">
  <xsl:attribute name="font-family">
  <xsl:value-of select="$face"/>
  </xsl:attribute>
  </xsl:if>
	<xsl:if test="$color!=''">
  <xsl:attribute name="color">
  <xsl:value-of select="$color"/>
  </xsl:attribute>
  </xsl:if>
    <xsl:apply-templates/>
  </fo:inline>
</xsl:template>


    <xsl:template match="STRONG|strong" >
        <fo:inline font-weight="bold">
        <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="EM|em" >
        <fo:inline font-style="italic">
        <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="SUB|sub" >
        <fo:inline vertical-align="sub">
        <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="SUP|sup" >
        <fo:inline vertical-align="super">
        <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="U|u" >
        <fo:inline text-decoration="underline">
        <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="STRIKE|strike" >
	 <fo:inline text-decoration="line-through">
        <xsl:apply-templates/>
        </fo:inline>    
        </xsl:template>
    <xsl:template match="TABLE|table">
	   	<fo:table border-collapse='collapse' table-layout='fixed'>
	   <xsl:if test="@height">
	   <xsl:attribute name="height">
	   <xsl:value-of select="concat('.75*',@height,'pt')"/>
	   </xsl:attribute>
	   </xsl:if>
   	   <xsl:if test="@width">
	   <xsl:attribute name="width">
	   <xsl:value-of select="concat('.75*',@width,'pt')"/>
	   </xsl:attribute>
	   </xsl:if>

       <xsl:apply-templates></xsl:apply-templates>
        </fo:table>
    </xsl:template>
    <xsl:template match="BLOCKQUOTE|blockquote">
  	<fo:block margin-left="1.5cm" margin-right="1.5cm">
    	<xsl:apply-templates />
  	</fo:block>
	</xsl:template>
  
    <!--
    <xsl:template match="@border">
        <xsl:attribute name="border-before-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-after-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-start-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-end-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
     <xsl:template match="@cellpadding">
        <xsl:attribute name="padding-before">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-after">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-start">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-end">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@cellspacing">
        <xsl:attribute name="border-separation.block-progression-direction">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-separation.inline-progression-direction">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
    -->
    <xsl:template match="TBODY|tbody">
    	<fo:table-body>
        <xsl:apply-templates></xsl:apply-templates>
        </fo:table-body>
    </xsl:template>
    <xsl:template match="TR|tr">
    	<fo:table-row>
        <xsl:if test="../../@height">
  	   <xsl:attribute name="height">
	   <xsl:value-of select='concat(.75 * ../../@height div count(../../TBODY/TR), "pt")'/>
	   </xsl:attribute>

        </xsl:if>      
        <xsl:apply-templates></xsl:apply-templates>
        </fo:table-row>
    </xsl:template>
    <xsl:template match="TD|td">
    	<fo:table-cell>
    	<xsl:for-each select="tokenize(@style,';')">
    	<xsl:variable name="name1">
    	<xsl:value-of select="normalize-space(substring-before(.,':'))"/>
    	</xsl:variable>
    	<xsl:if test="(($name1='width') or ($name1='text-align'))">
    	<xsl:attribute name="{$name1}">
    	<xsl:value-of select="normalize-space(substring-after(.,':'))"/>
    	</xsl:attribute>
    	</xsl:if>
    	</xsl:for-each>
    	<xsl:if test="../../../@cellpadding!=''">
        <xsl:attribute name="padding-before">
        	<xsl:value-of select="concat(../../../@cellpadding,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-after">
        	<xsl:value-of select="concat(../../../@cellpadding,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-start">
        	<xsl:value-of select="concat(../../../@cellpadding,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-end">
        	<xsl:value-of select="concat(../../../@cellpadding,'pt')"/>
        </xsl:attribute>
        </xsl:if>
        <xsl:if test="../../../@border!=''">
        <xsl:attribute name="border-before-width">
        	<xsl:value-of select="concat(../../../@border,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-after-width">
        	<xsl:value-of select="concat(../../../@border,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-start-width">
        	<xsl:value-of select="concat(../../../@border,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-end-width">
        	<xsl:value-of select="concat(../../../@border,'pt')"/>
        </xsl:attribute>
        </xsl:if>
        <xsl:if test="../../../@cellspacing!=''">
        <xsl:attribute name="border-separation.block-progression-direction">
        	<xsl:value-of select="concat(../../../@cellspacing,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-separation.inline-progression-direction">
        	<xsl:value-of select="concat(../../../@cellspacing,'pt')"/>
        </xsl:attribute>
        </xsl:if>
        <xsl:attribute name='border-before-style'>solid</xsl:attribute>
		<xsl:attribute name='border-after-style'>solid</xsl:attribute>
		<xsl:attribute name='border-start-style'>solid</xsl:attribute>
		<xsl:attribute name='border-end-style'>solid</xsl:attribute>
		<xsl:attribute name='border-collapse'>collapse</xsl:attribute>
    	<fo:block>
        <xsl:apply-templates></xsl:apply-templates>
        </fo:block>
        </fo:table-cell>
    </xsl:template>
    
    <xsl:template match="IMG|img">
    <fo:block>
    <fo:external-graphic>
		<xsl:if test="@src">
       	<xsl:attribute name="src">
       	<xsl:value-of select="@src"/>
		</xsl:attribute>
    	</xsl:if>
		<xsl:if test="@width">
       	<xsl:attribute name="width">
       	<xsl:value-of select="concat('.75*',@width,'pt')"/>
		</xsl:attribute>
       	<xsl:attribute name="content-width">
       	<xsl:value-of select="concat('.75*',@width,'pt')"/>
		</xsl:attribute>

    	</xsl:if>
		<xsl:if test="@height">
       	<xsl:attribute name="height">
       	<xsl:value-of select="concat('.75*',@height,'pt')"/>
		</xsl:attribute>
       	<xsl:attribute name="content-height">
       	<xsl:value-of select="concat('.75*',@height,'pt')"/>
		</xsl:attribute>

    	</xsl:if>
		<xsl:if test="@scaling">
		<xsl:attribute name="scaling">
		<xsl:value-of select="@scaling"/>
		</xsl:attribute>
		</xsl:if>
    <xsl:apply-templates/>
   	</fo:external-graphic>
	</fo:block>
    </xsl:template>

    <xsl:template match="*" >
        <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>
    
    </zenxslt>
}

XData CreateTable
{
<zenxslt>
	<xsl:template match="worksheet">
	<fo:block>
	<xsl:apply-templates select="title"/>
	<fo:table table-layout="fixed">
	<xsl:if test="@width">
	<xsl:attribute name="width">
	<xsl:value-of select="@width"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-collapse">
	<xsl:attribute name="border-collapse">
	<xsl:value-of select="@border-collapse"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-style">
	<xsl:attribute name="border-style">
	<xsl:value-of select="@border-style"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border">
	<xsl:attribute name="border">
	<xsl:value-of select="@border"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-top">
	<xsl:attribute name="border-top">
	<xsl:value-of select="@border-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-bottom">
	<xsl:attribute name="border-bottom">
	<xsl:value-of select="@border-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-left">
	<xsl:attribute name="border-left">
	<xsl:value-of select="@border-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-right">
	<xsl:attribute name="border-right">
	<xsl:value-of select="@border-right"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-top">
	<xsl:attribute name="padding-top">
	<xsl:value-of select="@padding-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-bottom">
	<xsl:attribute name="padding-bottom">
	<xsl:value-of select="@padding-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-before">
	<xsl:attribute name="padding-before">
	<xsl:value-of select="@padding-before"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-after">
	<xsl:attribute name="padding-after">
	<xsl:value-of select="@padding-after"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-left">
	<xsl:attribute name="padding-left">
	<xsl:value-of select="@padding-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-right">
	<xsl:attribute name="padding-right">
	<xsl:value-of select="@padding-right"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-start">
	<xsl:attribute name="padding-start">
	<xsl:value-of select="@padding-start"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-end">
	<xsl:attribute name="padding-end">
	<xsl:value-of select="@padding-end"/>
	</xsl:attribute>
	</xsl:if>

	<xsl:for-each select="data/row[1]/cell">
	<fo:table-column>
	<xsl:attribute name="column-number">
	<xsl:value-of select="position()"/>
	</xsl:attribute>
	<xsl:attribute name="column-width">
	<xsl:choose>
	<xsl:when test="not(@column-width)">
	proportional-column-width(1)
	</xsl:when>
	<xsl:otherwise>
	<xsl:value-of select="@column-width"/>
	</xsl:otherwise>
	</xsl:choose>
	</xsl:attribute>
	</fo:table-column>
	</xsl:for-each>
	<xsl:if test="column-headers">
	<fo:table-header>
	<xsl:apply-templates select="column-headers"/>
	</fo:table-header>
	</xsl:if>
	<fo:table-body>
	<xsl:apply-templates select="row-headers"/>
	<xsl:apply-templates select="data"/>
	</fo:table-body>
	</fo:table>
	</fo:block>
	</xsl:template>
	<xsl:template match="row-headers">
	<xsl:apply-templates select="header" mode="row-header"/>
	</xsl:template>
	<xsl:template match="header" mode="row-header">
	
	</xsl:template>
	<xsl:template match="data">
	<xsl:apply-templates select="row"/>
	</xsl:template>
	<xsl:template match="row">
	<fo:table-row>
	<xsl:apply-templates select="cell"/>
	</fo:table-row>
	</xsl:template>
	<xsl:template match="cell">
	<fo:table-cell>
	<xsl:if test="@rowspan">
	<xsl:attribute name="number-rows-spanned">
	    <xsl:value-of select="@rowspan"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@background-color">
	<xsl:attribute name="background-color">
	<xsl:value-of select="@background-color"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@color">
	<xsl:attribute name="color">
	<xsl:value-of select="@color"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-weight">
	<xsl:attribute name="font-weight">
	<xsl:value-of select="@font-weight"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-style">
	<xsl:attribute name="font-style">
	<xsl:value-of select="@font-style"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-size">
	<xsl:attribute name="font-size">
	<xsl:value-of select="@font-size"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@text-decoration">
	<xsl:attribute name="text-decoration">
	<xsl:value-of select="@text-decoration"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@text-align">
	<xsl:attribute name="text-align">
	<xsl:value-of select="@text-align"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-family">
	<xsl:attribute name="font-family">
	<xsl:value-of select="@font-family"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-style">
	<xsl:attribute name="border-style">
	<xsl:value-of select="@border-style"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border">
	<xsl:attribute name="border">
	<xsl:value-of select="@border"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-top">
	<xsl:attribute name="border-top">
	<xsl:value-of select="@border-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-bottom">
	<xsl:attribute name="border-bottom">
	<xsl:value-of select="@border-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-left">
	<xsl:attribute name="border-left">
	<xsl:value-of select="@border-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-right">
	<xsl:attribute name="border-right">
	<xsl:value-of select="@border-right"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-top">
	<xsl:attribute name="padding-top">
	<xsl:value-of select="@padding-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-bottom">
	<xsl:attribute name="padding-bottom">
	<xsl:value-of select="@padding-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-before">
	<xsl:attribute name="padding-before">
	<xsl:value-of select="@padding-before"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-after">
	<xsl:attribute name="padding-after">
	<xsl:value-of select="@padding-after"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-left">
	<xsl:attribute name="padding-left">
	<xsl:value-of select="@padding-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-right">
	<xsl:attribute name="padding-right">
	<xsl:value-of select="@padding-right"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-start">
	<xsl:attribute name="padding-start">
	<xsl:value-of select="@padding-start"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-end">
	<xsl:attribute name="padding-end">
	<xsl:value-of select="@padding-end"/>
	</xsl:attribute>
	</xsl:if>

	<fo:block>
	<xsl:choose>
	<xsl:when test="@format">
	<xsl:value-of select="format-number(@value,@format)"/>
	</xsl:when>
	<xsl:otherwise>
	<xsl:value-of select="@value"/>
	</xsl:otherwise>
	</xsl:choose>
	</fo:block>
	</fo:table-cell>
	</xsl:template>
	<xsl:template match="title">
	<fo:block>
	<xsl:value-of select="."/>
	</fo:block>
	</xsl:template>

	<xsl:template match="column-headers">
	<fo:table-row>
	<xsl:apply-templates select="header"/>
	</fo:table-row>
	<xsl:apply-templates select="column-headers">
	</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="header">
	<fo:table-cell>
	<xsl:if test="@colspan">
	<xsl:attribute name="number-columns-spanned">
	    <xsl:value-of select="@colspan"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@background-color">
	<xsl:attribute name="background-color">
	<xsl:value-of select="@background-color"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@color">
	<xsl:attribute name="color">
	<xsl:value-of select="@color"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-weight">
	<xsl:attribute name="font-weight">
	<xsl:value-of select="@font-weight"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-style">
	<xsl:attribute name="font-style">
	<xsl:value-of select="@font-style"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-size">
	<xsl:attribute name="font-size">
	<xsl:value-of select="@font-size"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@text-decoration">
	<xsl:attribute name="text-decoration">
	<xsl:value-of select="@text-decoration"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@text-align">
	<xsl:attribute name="text-align">
	<xsl:value-of select="@text-align"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@font-family">
	<xsl:attribute name="font-family">
	<xsl:value-of select="@font-family"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-style">
	<xsl:attribute name="border-style">
	<xsl:value-of select="@border-style"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border">
	<xsl:attribute name="border">
	<xsl:value-of select="@border"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-top">
	<xsl:attribute name="border-top">
	<xsl:value-of select="@border-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-bottom">
	<xsl:attribute name="border-bottom">
	<xsl:value-of select="@border-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-left">
	<xsl:attribute name="border-left">
	<xsl:value-of select="@border-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@border-right">
	<xsl:attribute name="border-right">
	<xsl:value-of select="@border-right"/>
	</xsl:attribute>
	</xsl:if>
		<xsl:if test="@padding-top">
	<xsl:attribute name="padding-top">
	<xsl:value-of select="@padding-top"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-bottom">
	<xsl:attribute name="padding-bottom">
	<xsl:value-of select="@padding-bottom"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-before">
	<xsl:attribute name="padding-before">
	<xsl:value-of select="@padding-before"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-after">
	<xsl:attribute name="padding-after">
	<xsl:value-of select="@padding-after"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-left">
	<xsl:attribute name="padding-left">
	<xsl:value-of select="@padding-left"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-right">
	<xsl:attribute name="padding-right">
	<xsl:value-of select="@padding-right"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-start">
	<xsl:attribute name="padding-start">
	<xsl:value-of select="@padding-start"/>
	</xsl:attribute>
	</xsl:if>
	<xsl:if test="@padding-end">
	<xsl:attribute name="padding-end">
	<xsl:value-of select="@padding-end"/>
	</xsl:attribute>
	</xsl:if>
	<fo:block>
	<xsl:value-of select="@value"/>
	</fo:block>
	</fo:table-cell>
	</xsl:template>
	</zenxslt>
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0, ByRef ignoreId = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)

	Set ..link=$zstrip(..link,"<>W")
	If ..link'="" {
		// If ..link starts with !, interpret it as an XPath expression
		If $e(..link) = "!"  {
			Set link="<xsl:value-of select='concat(""url("","_$e(..link,2,$l(..link))_","")"")'/>"
		} Else {
			Set link="url("_..link_")"
		}
		Do XSL.WriteLine("<fo:basic-link "_$$$applyclass("a",.context)_">") Do ..XSLFOStyle(.context,.XSL,.delay,..style,..class,..width,..xslfostyle,..id,..selectstylecond,..stylecall,..styleparams, ..selectstylelist,..styleparamNames)
		Do XSL.WriteLine("<xsl:attribute name='external-destination'>"_link_"</xsl:attribute>")
		Do XSL.WriteLine("<xsl:attribute name='show-destination'>"_..showDestination_"</xsl:attribute>")
		Do XSL.WriteLine("<xsl:attribute name='indicate-destination'>"_..indicateDestination_"</xsl:attribute>")
		
	}

	if (..createtable=0) {
		If (incell)||(..multiline) {
			Do XSL.WriteLine("<fo:inline"_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
			If 'ignoreId { // JSL5217
				do ..OutputId(.context,.XSL,.delay)
			}

		} Else {
			Do XSL.WriteLine("<fo:inline "_$$$applyclass("td",.context)_">") Do ..XSLFOStyle(.context,.XSL,.delay,..style,..class,..width,..xslfostyle,..id,..selectstylecond,..stylecall,..styleparams, ..selectstylelist,..styleparamNames, 1)
		}
	}

	If ..call'="" {
	    Do XSL.WriteLine("<xsl:call-template name='"_..call_"'>")
	    if ..params'="" {
		    for i=1:1:$L(..params,";") {
	    		Do XSL.WriteLine("<xsl:with-param name='"_$P(..paramNames,";",i)_"' select='"_$P(..params,";",i)_"'/>")
	    	}
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	} Elseif ..fieldnum'="",..level'="",$D(%cache(..level)),$isObject(%cache(..level)) {
		if ..suppressDuplicates {
			Set prevValue=$$PrevFieldLookupNum^%occZENReports(..fieldnum,..level,1)
			Set currValue=$$FieldLookupNum^%occZENReports(..fieldnum,..level,1)
			if prevValue=currValue {
				Do XSL.WriteLine("")
			} else {
				Do XSL.WriteLine(..TransformToFO(currValue))
			}
		} else {
			Set currValue=$$FieldLookupNum^%occZENReports(..fieldnum,..level,1)
			Do XSL.WriteLine(..TransformToFO(currValue))
		}
	} Elseif ..fieldname'="",..level'="",$D(%cache(..level)),$isObject(%cache(..level)) {
		if ..suppressDuplicates {
			Set prevValue=$$PrevFieldLookup^%occZENReports(..fieldname,..level,1)
			Set currValue=$$FieldLookup^%occZENReports(..fieldname,..level,1)
			if prevValue=currValue {
				Do XSL.WriteLine("")
			} else {
				Do XSL.WriteLine(..TransformToFO(currValue))
			}
		} else {
			Set currValue=$$FieldLookup^%occZENReports(..fieldname,..level,1)
			Do XSL.WriteLine(..TransformToFO(currValue))			
		}
	} ElseIf ((..field'="")&&(..special="")) {
		if ..tooLongText="unset",%report.TooLongText'="unset" Set ..tooLongText=%report.TooLongText
		If ..field=$c(0) Set ..field=""""""
		If 0 { ;..removeEmpty,..field'="" {
			Do XSL.WriteLine("<xsl:if test=""count("_..xpath_"/"_..field_")!=0"">")
		}
		If ..suppressDuplicates {
			Do XSL.WriteLine("<xsl:if test=""not("_..field_"=preceding-sibling::"_##class(%ZEN.Report.Display.node).parent(..qualify(..xpath))_"/"_..field_")"">")
		}
		If ..displayCaption {
			Do XSL.WriteLine("<xsl:text>"_..caption_"</xsl:text>")
		}
		If ..breakOnLineFeed,'..literalSpaces {
			if ('..insertZeroWidthSpaces && '(..tooLongText="wrap")) {
			    Do XSL.WriteLine("<xsl:call-template name=""break"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("<xsl:with-param name=""oldbehaviorlinefeed"" select='"_+$g(%context("Props","OldBehaviorLineFeedOnBreak"))_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
			} else {
					Do XSL.WriteLine("<xsl:call-template name=""break"">")
			    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("<xsl:with-param name=""oldbehaviorlinefeed"" select='"_+$g(%context("Props","OldBehaviorLineFeedOnBreak"))_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
			}			    
			    

		} elseif ..literalSpaces,'..breakOnLineFeed {
			if ('..insertZeroWidthSpaces  && '(..tooLongText="wrap")) {
				Do XSL.WriteLine("<xsl:call-template name=""space"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
			} else {
					Do XSL.WriteLine("<xsl:call-template name=""space"">")
			    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
			}			    

		} elseif ..literalSpaces,..breakOnLineFeed {
			if ('..insertZeroWidthSpaces && '(..tooLongText="wrap")) {
				Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("<xsl:with-param name=""oldbehaviorlinefeed"" select='"_+$g(%context("Props","OldBehaviorLineFeedOnBreak"))_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
			} else {
					Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
			    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("<xsl:with-param name=""oldbehaviorlinefeed"" select='"_+$g(%context("Props","OldBehaviorLineFeedOnBreak"))_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
			}

		}else {
			if ..copyxml { 
  			    Do XSL.WriteLine("<xsl:copy-of select="""_..xpath_"/"_..field_""">")
			    Do XSL.WriteLine("</xsl:copy-of>")		
			}
			elseif ..copyhtml {
				if (+$g(%context("converthtml")) = 0) {
					Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"ConvertHTML","%ZEN.Report.Display.item") ; XSL for ConvertHTML
					Set %context("converthtml")=1
				}			
				Do XSL.WriteLine("<fo:block linefeed-treatment=""preserve"">")
				if %report.DefaultFontFaceCopyHTML'="" {
					  Do XSL.Write("<xsl:attribute name='font-family'>")
					  Do XSL.Write(%report.DefaultFontFaceCopyHTML)
  					  Do XSL.WriteLine("</xsl:attribute>")

				}
				if %report.DefaultFontSizeCopyHTML'="" {
					  Do XSL.Write("<xsl:attribute name='font-size'>")
					  Do XSL.Write(%report.DefaultFontSizeCopyHTML)
  					  Do XSL.WriteLine("</xsl:attribute>")

				}
				Do XSL.WriteLine("<xsl:apply-templates select='"_$$$celldata_"'/>")
				Do XSL.WriteLine("</fo:block>")
			} elseif ..copyhtml86 {
				if (+$g(%context("converthtml")) = 0) {
					Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"ConvertHTML","%ZEN.Report.Display.version86") ; XSL for ConvertHTML
					Set %context("converthtml")=1
				}			
				Do XSL.WriteLine("<fo:block>")
				if %report.DefaultFontFaceCopyHTML'="" {
					  Do XSL.Write("<xsl:attribute name='font-family'>")
					  Do XSL.Write(%report.DefaultFontFaceCopyHTML)
  					  Do XSL.WriteLine("</xsl:attribute>")

				}
				if %report.DefaultFontSizeCopyHTML'="" {
					  Do XSL.Write("<xsl:attribute name='font-size'>")
					  Do XSL.Write(%report.DefaultFontSizeCopyHTML)
  					  Do XSL.WriteLine("</xsl:attribute>")

				}
				Do XSL.WriteLine("<xsl:apply-templates select='"_$$$celldata_"'/>")
				Do XSL.WriteLine("</fo:block>")

			} elseif ..createtable {
				if (+$g(%context("createtable")) = 0) {
					Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"CreateTable","%ZEN.Report.Display.item") ; XSL for create table
					Set %context("createtable")=1
				}			
				Do XSL.WriteLine("<xsl:apply-templates select='"_$$$celldata_"'/>")

			}
			else {
				If (..insertZeroWidthSpaces ||  (..tooLongText="wrap")) {
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
					
				} else {
					Do XSL.WriteLine("<xsl:value-of select='"_$$$celldata_"'/>")
				}
			}
		}	
		If 0 { ;..removeEmpty,..field'="" {
			Do XSL.WriteLine("</xsl:if>")
		}
		If ..suppressDuplicates {
			Do XSL.WriteLine("</xsl:if>")
		}

	} ElseIf ..special'="" {
		Set output=""
		If ..displayCaption {
			Set output=..caption
		}

		If ..special="number" {
			if ..parent.%Extends("%ZEN.Report.Display.table"),'..parent.UseXSLT() {
				Set output=output_$i(%number)
			} else { 
				Set output=output_"<xsl:number/>"
			}
			Do XSL.WriteLine(output)
		} ElseIf ..special = "page-number" {
			Set output=output_"<fo:page-number/>"
			Do XSL.WriteLine(output)
		} ElseIf (..special = "page-count") || (..special = "page-count-with-xpath") {
			Set output=output_"<fo:page-number-citation-last ref-id='{$zenPageSequenceId}'/>"
			Do XSL.WriteLine(output)
		} ElseIf (..special = "page-number-of") || (..special = "page-number-of-with-xpath") {
			Set output=output_"<fo:page-number/>"_..ofString_"<fo:page-number-citation-last ref-id='{$zenPageSequenceId}'/>"
			Do XSL.WriteLine(output)
		} ElseIf (..special = "page-number-/") || (..special = "page-number-/-with-xpath") {
			Set output=output_"<fo:page-number/>/<fo:page-number-citation-last ref-id='{$zenPageSequenceId}'/>"
			Do XSL.WriteLine(output)
		} Else {
			Set output="Invalid special"
		}
		
	} ElseIf ..expression'="",..if'="" {
		New %cond,%value
		X "S %cond="_..if
		X "S %value="_..expression
		If ..displayCaption {
			Set %value=..caption_%value
		}
		If %cond {
			If ..breakOnLineFeed,'..literalSpaces {
				if ('..insertZeroWidthSpaces && '(..tooLongText="wrap")) {
				    Do XSL.WriteLine("<xsl:call-template name=""break"">")
				    ;Do XSL.WriteLine("<xsl:with-param name=""text"" select='&quot;"_%value_"&quot;'/>")
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
				} else {
						Do XSL.WriteLine("<xsl:call-template name=""break"">")
				    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
						Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
					    Do XSL.WriteLine("<xsl:with-param name=""text"">")
					    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
				}			    
			    

			} elseif ..literalSpaces,'..breakOnLineFeed {
				if ('..insertZeroWidthSpaces  && '(..tooLongText="wrap")) {
					Do XSL.WriteLine("<xsl:call-template name=""space"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
				} else {
						Do XSL.WriteLine("<xsl:call-template name=""space"">")
				    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
						Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
   					    Do XSL.WriteLine("<xsl:with-param name=""text"">")
					    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
				}			    

			} elseif ..literalSpaces,..breakOnLineFeed {
				if ('..insertZeroWidthSpaces && '(..tooLongText="wrap")) {
					Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
				} else {
						Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
				    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
						Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
					    Do XSL.WriteLine("<xsl:with-param name=""text"">")
					    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
					    Do XSL.WriteLine("</xsl:with-param>")
					    Do XSL.WriteLine("</xsl:call-template>")
				}

			}else {
				If (..insertZeroWidthSpaces ||  (..tooLongText="wrap")) {
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
				
				} else {
					Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				}

			}	
		}
		
		
	} ElseIf ..value'=$c(0) {
		If ..displayCaption {
			Set value=..caption_..value
		} else {
			Set value=..value
		}

		If '..literalSpaces {
			s countspaces=..CountSpaces(..value)			
			if $L(..value)'=countspaces {
				if ('..reverse) {
					
					If (..insertZeroWidthSpaces ||  (..tooLongText="wrap")) {
						Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
					    Do XSL.WriteLine("<xsl:with-param name=""text"" select='&quot;"_value_"&quot;'/>")
					    Do XSL.WriteLine("</xsl:call-template>")
					
					} else {
						Do XSL.WriteLine("<![CDATA["_value_"]]>")
					}
					
				} else {
					Do XSL.WriteLine("<xsl:call-template name=""reverse"">")
			    	Do XSL.WriteLine("<xsl:with-param name=""input"" select='"""_value_"""'/>")
			    	Do XSL.WriteLine("</xsl:call-template>")

				}


			}  else {
				Do XSL.WriteLine("<xsl:text><![CDATA["_value_"]]></xsl:text>")
			}
		} elseif ..literalSpaces {
			if ('..insertZeroWidthSpaces  && '(..tooLongText="wrap")) {
				Do XSL.WriteLine("<xsl:call-template name=""space"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='&quot;"_..value_"&quot;'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
			} else {
					Do XSL.WriteLine("<xsl:call-template name=""space"">")
			    	Do XSL.WriteLine("<xsl:with-param name=""text"">")
					Do XSL.WriteLine("<xsl:call-template name=""insert-zero-width-spaces"">")
				    Do XSL.WriteLine("<xsl:with-param name=""text"" select='&quot;"_..value_"&quot;'/>")
				    Do XSL.WriteLine("</xsl:call-template>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
			}			    

		}
	}
 if ..multiline {
#; March 26, 2009	
	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption",child.tag'="summary" Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 }

	if (..createtable=0) {
		Do XSL.WriteLine("</fo:inline>")
	}
	Do:..link'="" XSL.WriteLine("</fo:basic-link>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
 if ..multiline {
#; March 26, 2009	
	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption",(child.tag'="summary") Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 }

	Set ..link=$zstrip(..link,"<>W")
	If ..link'="" {
		Set link=..link
		// If ..link starts with !, interpret it as an XPath expression
		If $e(..link) = "!" Set link="<xsl:value-of select='"_$e(..link,2,$l(..link))_"'/>"
		Do XSL.WriteLine("<a>") $$$stylehtml
		Do XSL.WriteLine("<xsl:attribute name='href'>"_link_"</xsl:attribute>")
	} ElseIf 'incell{
		#; need somewhere to put style info
		Do XSL.WriteLine("<span>") $$$stylehtml
	} 
	if ..link="",incell&&(..id'="") {
		#; need somewhere to put id info
		Do XSL.WriteLine("<span>")
		do ..OutputId(.context,.XSL,.delay)	
	}

	If ..call'="" {
	    Do XSL.WriteLine("<xsl:call-template name='"_..call_"'>")
	    if ..params'="" {
		    for i=1:1:$L(..params,";") {
		    	Do XSL.WriteLine("<xsl:with-param name='"_$P(..paramNames,";",i)_"' select='"_$P(..params,";",i)_"'/>")
		    }
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	} Elseif ..fieldnum'="",..level'="",$D(%cache(..level)),$isObject(%cache(..level)) {
		if ..suppressDuplicates {
			Set prevValue=$$PrevFieldLookupNum^%occZENReports(..fieldnum,..level,1)
			Set currValue=$$FieldLookupNum^%occZENReports(..fieldnum,..level,1)
			if prevValue=currValue {
				Do XSL.WriteLine("")
			} else {
				Do XSL.WriteLine(..TransformToHTML(currValue))
			}
		} else {
			Set currValue=$$FieldLookupNum^%occZENReports(..fieldnum,..level,1)
			Do XSL.WriteLine(..TransformToHTML(currValue))
		}
	} Elseif ..fieldname'="",..level'="",$D(%cache(..level)),$isObject(%cache(..level)) {
		if ..suppressDuplicates {
			Set prevValue=$$PrevFieldLookup^%occZENReports(..fieldname,..level,1)
			Set currValue=$$FieldLookup^%occZENReports(..fieldname,..level,1)
			if prevValue=currValue {
				Do XSL.WriteLine("")
			} else {
				Do XSL.WriteLine(..TransformToHTML(currValue))
			}
		} else {
			Set currValue=$$FieldLookup^%occZENReports(..fieldname,..level,1)
			Do XSL.WriteLine(..TransformToHTML(currValue))
		}

	} ElseIf ..field'="",..special="" {
		If ..field=$c(0) Set ..field=""""""
		If 0 { ;..removeEmpty,..field'="" {
			Do XSL.WriteLine("<xsl:if test=""count("_..xpath_"/"_..field_")!=0"">")
		}
		If ..suppressDuplicates {
			Do XSL.WriteLine("<xsl:if test=""not("_..field_"=preceding-sibling::"_##class(%ZEN.Report.Display.node).parent(..qualify(..xpath))_"/"_..field_")"">")
		}
		If ..displayCaption {
			Do XSL.WriteLine("<xsl:text>"_..caption_"</xsl:text>")
		}
		If ..breakOnLineFeed,'..literalSpaces {
			    Do XSL.WriteLine("<xsl:call-template name=""break"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")

		} elseif ..literalSpaces,'..breakOnLineFeed {
				if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {
			    	Do XSL.WriteLine("<xsl:call-template name=""space_server"">")
				} else {
					Do XSL.WriteLine("<xsl:call-template name=""space"">")
				}
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
		} elseif ..literalSpaces,..breakOnLineFeed {
				if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {			
				    Do XSL.WriteLine("<xsl:call-template name=""spacebreak_server"">")
				} else {
					Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
				}
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='"_$$$celldata_"'/>")
			    Do XSL.WriteLine("</xsl:call-template>")

		}else {
			if ..copyxml { 
  			    Do XSL.WriteLine("<xsl:apply-templates select='"_..xpath_"/"_..field_"' mode='copy'>")
			    Do XSL.WriteLine("</xsl:apply-templates>")		
			} elseif ..copyhtml {
				if (+$g(%context("converthtml")) = 0) {
					Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"ConvertRichText","%ZEN.Report.Display.item") ; Common XSL for timeline
					Set %context("converthtml")=1
				}			
				Do XSL.WriteLine("<xsl:apply-templates select='"_$$$celldata_"'/>")
			}
			else {
				Do XSL.WriteLine("<xsl:value-of select='"_$$$celldata_"'/>")
			}
		}	
		If 0 { ;..removeEmpty,..field'="" {
			Do XSL.WriteLine("</xsl:if>")
		}
		If ..suppressDuplicates {
			Do XSL.WriteLine("</xsl:if>")
		}

	} ElseIf ..special'="" {
		Set output=""
		If ..displayCaption {
			Set output=..caption
		}

		If ..special="number" {
			if ..parent.%Extends("%ZEN.Report.Display.table"),'..parent.UseXSLT() {
				Set output=output_$i(%number)
			} else {
				Set output=output_"<xsl:number/>"
			}
		} ElseIf ..special = "page-number" {
			Set output=output_"##"
		} ElseIf ..special = "page-count" {
			Set output=output_"##"
		} ElseIf ..special = "page-number-of" {
			Set output=output_"##"_..ofString_"##"
		} ElseIf ..special = "page-number-/" {
			Set output=output_"##/##"
		} ElseIf ((..special="page-count-with-xpath")&&(..field'="")) {
			Set output=output_"##"
		} ElseIf ((..special="page-number-of-with-xpath")&&(..field'="")) {
			Set output=output_"##"_..ofString_"##"
		} ElseIf ((..special="page-number-/-with-xpath")&&(..field'="")) {
			Set output=output_"##/##"
				
		} Else {
			Set output="Invalid special"
		}
		Do XSL.WriteLine(output)
	} ElseIf ..expression'="",..if'="" {
		New %cond,%value
		X "S %cond="_..if
		X "S %value="_..expression
		If ..displayCaption {
			Set %value=..caption_%value
		}
		if %cond {
			If ..breakOnLineFeed,'..literalSpaces {
			    Do XSL.WriteLine("<xsl:call-template name=""break"">")
			    Do XSL.WriteLine("<xsl:with-param name=""text"">")
			    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
			    Do XSL.WriteLine("</xsl:with-param>")
			    Do XSL.WriteLine("</xsl:call-template>")

			} elseif ..literalSpaces,'..breakOnLineFeed {
					if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {
				    	Do XSL.WriteLine("<xsl:call-template name=""space_server"">")
					} else {
						Do XSL.WriteLine("<xsl:call-template name=""space"">")
					}
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")
			} elseif ..literalSpaces,..breakOnLineFeed {
					if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {			
					    Do XSL.WriteLine("<xsl:call-template name=""spacebreak_server"">")
					} else {
						Do XSL.WriteLine("<xsl:call-template name=""spacebreak"">")
					}
				    Do XSL.WriteLine("<xsl:with-param name=""text"">")
				    Do XSL.WriteLine("<![CDATA["_%value_"]]>")
				    Do XSL.WriteLine("</xsl:with-param>")
				    Do XSL.WriteLine("</xsl:call-template>")

			}else {
				Do XSL.WriteLine("<![CDATA["_%value_"]]>")
			}	
		}
	} Else {
		If ..value'="" {
			If ..displayCaption {
				Set value=..caption_..value
			} else {
				Set value=..value
			}

			if '..literalSpaces {
				s countspaces=..CountSpaces(value)
				if $L(value)'=countspaces {
					Do XSL.WriteLine("<![CDATA["_value_"]]>")
				} else {
					Do XSL.WriteLine("<xsl:text><![CDATA["_value_"]]></xsl:text>")
				}
			} else {
				if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {
			    	Do XSL.WriteLine("<xsl:call-template name=""space_server"">")
				} else {
					Do XSL.WriteLine("<xsl:call-template name=""space"">")
				}
			    Do XSL.WriteLine("<xsl:with-param name=""text"" select='&quot;"_value_"&quot;'/>")
			    Do XSL.WriteLine("</xsl:call-template>")
				
			}
		} Else {
			if '..multiline {
				if (%report.isServer&&('%report.isHTML5)&&('..withinSmallmultiple)) {
					Do XSL.WriteLine("<xsl:text disable-output-escaping='yes'>&amp;#160;</xsl:text>")
				} else {
					Do XSL.WriteLine($$$nbsp)
				}
			}
		}
	}

	If ..link'="" {
		Do XSL.WriteLine("</a>")
	} ElseIf 'incell {
		Do XSL.WriteLine("</span>")
	}
	if ..link="",incell&&(..id'="") {
		#; need somewhere to put id info
		Do XSL.WriteLine("</span>")
	}


	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

/// This method outputs the stylesheet that converts the input xml to the xml with Excel annotations
/// report, table and item should override this method.  Nested tables not supported.
Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	
	Set sc=$$$OK
	d ..%BeginDrawFo(.context,.XSL,.delay)
	if ..xmlname'="" {
		Set elementName=..xmlname
	} else {
		Set elementName="item"
	}
	Do XSL.WriteLine("<xsl:element name='"_elementName_"'>")

	if ..excelName'="" {
		Do XSL.WriteLine("<xsl:attribute name='excelName'>")
		Do XSL.WriteLine("<xsl:value-of select=""'"_##class(%ZEN.Report.reportPage).%ResolveText(..excelName,.context)_"'""/>")
		Do XSL.WriteLine("</xsl:attribute>")
	} 
	if ..isExcelNumber'="" {
		Do XSL.WriteLine("<xsl:attribute name='isExcelNumber'>")
		Do XSL.WriteLine("<xsl:value-of select='"_..isExcelNumber_"'/>")
		Do XSL.WriteLine("</xsl:attribute>")
	}
	if ..isExcelDate'="" {
		Do XSL.WriteLine("<xsl:attribute name='isExcelDate'>")
		Do XSL.WriteLine("<xsl:value-of select='"_..isExcelDate_"'/>")
		Do XSL.WriteLine("</xsl:attribute>")

	}
	if ..isExcelTime'="" {
		Do XSL.WriteLine("<xsl:attribute name='isExcelTime'>")
		Do XSL.WriteLine("<xsl:value-of select='"_..isExcelTime_"'/>")
		Do XSL.WriteLine("</xsl:attribute>")

	}
	if ..excelNumberFormat'="" {
		Do XSL.WriteLine("<xsl:attribute name='excelNumberFormat'>")
		Do XSL.WriteLine("<xsl:value-of select='"""_..excelNumberFormat_"""'/>")
		Do XSL.WriteLine("</xsl:attribute>")

	}		
	if ..isExcelAggregate {
		if $D(context("aggregateTag"),aggregateTag) {
			Do XSL.WriteLine("<xsl:attribute name='"_aggregateTag_"'>")
			Do XSL.WriteLine("<xsl:value-of select='1'/>")
			Do XSL.WriteLine("</xsl:attribute>")
		}
	}
	if ..excelFormula'="" {
		Do XSL.WriteLine("<xsl:attribute name='excelFormula'>")
		Do XSL.WriteLine("<xsl:value-of select='"""_..excelFormula_"""'/>")
		Do XSL.WriteLine("</xsl:attribute>")
	
	}	
	
	If ..placeholder {
		Do XSL.WriteLine("<xsl:attribute name='placeholder'>")
		Do XSL.WriteLine("<xsl:value-of select='1'/>")
		Do XSL.WriteLine("</xsl:attribute>")

	}
	If ..field'="" {
		Set elementValue=..field
	} elseif ..value'="" {
		Set elementValue=""""_..value_""""
	} else {
		Set elementValue=""""""
	}
	//Call Custom Templates From Excel As Well 
    If ..call'="" { 
	    Do XSL.WriteLine("<xsl:call-template name='"_..call_"'>") 
	    if ..params'="" { 
	    	for i=1:1:$L(..params,";") { 
		    	Do XSL.WriteLine("<xsl:with-param name='"_$P(..paramNames,";",i)_"' select='"_$P(..params,";",i)_"'/>") 
	    	} 
	    } 
		Do XSL.WriteLine("</xsl:call-template>") 
    }   
   	else
   	{ 

		Do XSL.WriteLine("<xsl:value-of select='"_elementValue_"'/>")
	}		
	Do XSL.WriteLine("</xsl:element>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit sc
}

XData ConvertRichText
{
<zenxslt>
<xsl:template match="br|BR">
<br/>
</xsl:template>

		<xsl:template match="OL|ol">
        <ol>
            <xsl:apply-templates select="LI|li" mode="ordered"/>
        </ol>
    </xsl:template>
    		<xsl:template match="UL|ul">
		 <ul>
            <xsl:apply-templates select="LI|li" mode="unordered"/>
        </ul>
    </xsl:template>

    <xsl:template match="LI|li" mode="ordered">
        <li>
        <xsl:apply-templates/>
        </li> 
      
    </xsl:template>
        <xsl:template match="LI|li" mode="unordered">
        <li>
            
					<xsl:apply-templates ></xsl:apply-templates>
            
        </li> 
        
    </xsl:template>

	    <xsl:template match="P|p|div">
        <p>
    		<xsl:if test="@align">
        		<xsl:attribute name="align">
                    <xsl:value-of select="@align"/>
		        </xsl:attribute>
    		</xsl:if>
        	<xsl:if test="@style">
        		<xsl:attribute name="style">
                    <xsl:value-of select="@style"/>
		        </xsl:attribute>
    		</xsl:if>
        <xsl:apply-templates></xsl:apply-templates>
        </p>
    </xsl:template>
    <xsl:template match="SPAN|span">
        <span>
        	<xsl:if test="@style">
        		<xsl:attribute name="style">
                    <xsl:value-of select="@style"/>
		        </xsl:attribute>
    		</xsl:if>
        <xsl:apply-templates></xsl:apply-templates>
        </span>
    </xsl:template>
     <xsl:template match="FONT|font">
  	<xsl:variable name="color">
    <xsl:choose>
      <xsl:when test="@color">
        <xsl:value-of select="@color"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>black</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:variable name="size">
    <xsl:choose>
      <xsl:when test="@size">
        <xsl:value-of select="@size"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>3</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
      <xsl:variable name="face">
    <xsl:choose>
      <xsl:when test="@face and @face!=''">
        <xsl:value-of select="@face"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Verdana</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <font size="{$size}" face="{$face}"
    color="{$color}">
    <xsl:apply-templates/>
  </font>
</xsl:template>


    <xsl:template match="STRONG|strong" >
        <span style='font-weight:bold'>
        <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="EM|em" >
        <span style='font-style:italic'>
        <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="SUB|sub" >
        <sub>
        <xsl:apply-templates/>
        </sub>
    </xsl:template>
    <xsl:template match="SUP|sup" >
        <sup>
        <xsl:apply-templates/>
        </sup>
    </xsl:template>
    <xsl:template match="U|u" >
        <span style='text-decoration:underline'>
        <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="STRIKE|strike" >
	 <span style='text-decoration:line-through'>
        <xsl:apply-templates/>
        </span>    
        </xsl:template>
    <xsl:template match="TABLE|table">
	   	<table >
	   <xsl:if test="@height">
	   <xsl:attribute name="height">
	   <xsl:value-of select="@height"/>
	   </xsl:attribute>
	   </xsl:if>
   	   <xsl:if test="@width">
	   <xsl:attribute name="width">
	   <xsl:value-of select="@width"/>
	   </xsl:attribute>
	   </xsl:if>
		<xsl:attribute name="border">
		<xsl:value-of select="@border"/>
		</xsl:attribute>
		<xsl:attribute name="cell-padding">
		<xsl:value-of select="@cell-padding"/>
		</xsl:attribute>

       <xsl:apply-templates></xsl:apply-templates>
        </table>
    </xsl:template>
    <xsl:template match="BLOCKQUOTE|blockquote">
  	<blockquote>
    	<xsl:apply-templates />
  	</blockquote>
	</xsl:template>
  
    <!--
    <xsl:template match="@border">
        <xsl:attribute name="border-before-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-after-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-start-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-end-width">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
     <xsl:template match="@cellpadding">
        <xsl:attribute name="padding-before">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-after">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-start">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="padding-end">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@cellspacing">
        <xsl:attribute name="border-separation.block-progression-direction">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
        <xsl:attribute name="border-separation.inline-progression-direction">
        	<xsl:value-of select="concat(.,'pt')"/>
        </xsl:attribute>
    </xsl:template>
    -->
    <xsl:template match="TBODY|tbody">
    	<tbody>
        <xsl:apply-templates></xsl:apply-templates>
        </tbody>
    </xsl:template>
    <xsl:template match="TR|tr">
    	<tr>
      
        <xsl:apply-templates></xsl:apply-templates>
        </tr>
    </xsl:template>
    <xsl:template match="TD|td">
    	<td>
        <xsl:apply-templates></xsl:apply-templates>
        </td>
    </xsl:template>
    <xsl:template match="IMG|img">
    <img>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
	</img>
    </xsl:template>
		
    <xsl:template match="*" >
        <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>
    
    </zenxslt>
}

Method TransformToFO(currValue As %String)
{
	if ..literalSpaces {
		Set currValue=$replace(currValue," ","&#160;")
	}
	if ..insertZeroWidthSpaces || (..tooLongText="wrap") {
		Set currValue=..FInsertZeroWidthSpaces(currValue)
	}
	If ..displayCaption {
		Set currValue = ..caption_currValue
	}	
	quit currValue
}

Method TransformToHTML(currValue As %String)
{
	if ..literalSpaces {
		Set currValue=$replace(currValue," ","&#160;")
	}
	if ..breakOnLineFeed {
		Set currValue = $replace(currValue,$c(10),"<br/>")
	}
	if ..insertZeroWidthSpaces || (..tooLongText="wrap") {
		Set currValue=..FInsertZeroWidthSpaces(currValue)
	}	
	If ..displayCaption {
		Set currValue = ..caption_currValue
	}

	quit currValue
}

Method FInsertZeroWidthSpaces(currValue As %String)
{
	Set i=1
	while (i < $L(currValue)) {
		Set currValue=$e(currValue,1,i)_"&#x200B;"_$e(currValue,i+1,*)
		Set i=i+9 // length of a single character + length of &#x200B;
	}
	quit currValue
}

}
