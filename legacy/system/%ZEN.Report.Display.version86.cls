/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.version86 Extends %RegisteredObject [ Deprecated, System = 4 ]
{

XData ConvertHTML
{
<zenxslt>
<xsl:template match="br|BR">
<fo:block>&#160;</fo:block>
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
        	<xsl:if test="@style">
        		<xsl:attribute name="{translate(substring-before(@style,':'),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')}">
        			<xsl:choose>
        			<xsl:when test="substring-before(substring-after(substring-after(@style,':'),' '),';')">
                    	<xsl:value-of select="substring-before(substring-after(substring-after(@style,':'),' '),';')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-after(substring-after(@style,':'),' ')"/>
                    </xsl:otherwise>
                    </xsl:choose>
		        </xsl:attribute>
    		</xsl:if>
        <xsl:apply-templates></xsl:apply-templates>
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
        <xsl:value-of select="concat(100*(@size div 3),'%')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>12pt</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
      <xsl:variable name="face">
    <xsl:choose>
      <xsl:when test="@face and @face!=''">
        <xsl:value-of select="@face"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>sans-serif</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <fo:inline font-size="{$size}" font-family="{$face}"
    color="{$color}">
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

}
