/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines some common statistical functions to use in DeepSee 
/// <p>
/// The Following tags are defined here:
/// <ul>
/// <li>&lt;dsstat:variance&gt; Takes two attributes:
/// <ul> 
/// <li><b>sourceProperty</b>. Defines a measure that represents variance for the source property defined.
/// <li><b>stderr</b> possible values <code>true/false</code>. If true then another measure representing
/// standard error of the mean is added.
/// </ul> 
/// Example: &lt;dsstat:variance sourceProperty = "Value" stderr="true"/&gt;
/// <li> &lt;dsstat:regression&gt; Creates 3 measures for simple linear regression between two properties.
/// Takes two attributes: 
/// <ul>
/// <li> <b>sourceProperty1</b>
/// <li> <b>sourceProperty2</b>
/// </ul>
/// For example the following tag: &lt;dsstat:regression  sourceProperty1 = "LandArea" sourceProperty2 = "Value"/&gt; 
/// creates 3 measures:
/// <ul>
/// <li> LivingAreaValue Correlation
/// <li> LivingAreaValue Slope
/// <li> LivingAreaValue Intercept
/// </ul>
/// </ul>
/// Note:  &lt;dsstat:regression&gt; tag requires variance to be defined for both properties.
Class %DeepSee.extensions.Statistics [ System = 4 ]
{

/// This paramter is used to transform original cube definition. 
/// If it is defined in subcalss then the cube definition is piped 
/// through XSLT transformation. XSL is taken from XData block named
/// in this paramter.
Parameter TRANSFORMXSL = "Statistics";

XData Statistics
{
<?xml version="1.0"?>
<xsl:stylesheet version = '1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
                xmlns:ds='http://www.intersystems.com/deepsee'
                xmlns:dsstat='http://www.intersystems.com/deepsee/stat'
                >
    <xsl:output indent="yes"/>

    <xsl:template match="*">
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template match="/ds:cube">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="/ds:cube/*"/>
        </xsl:copy>

    </xsl:template>

    <xsl:template match="dsstat:variance">
        <xsl:comment> ======== Expanded from <xsl:value-of select="name()"/> <xsl:text> </xsl:text> <xsl:value-of select="@sourceProperty"/> ==============</xsl:comment>
        <measure name="%{@sourceProperty}0" hidden="true" sourceProperty="{@sourceProperty}" aggregate="COUNT"/>
        <measure name="%{@sourceProperty}1" hidden="true" sourceProperty="{@sourceProperty}" aggregate="SUM"/>
        <measure name="%{@sourceProperty}2" hidden="true" sourceExpression="%source.{@sourceProperty}*%source.{@sourceProperty}" aggregate="SUM"/>

        <calculatedMember name="%%{@sourceProperty}V1" valueExpression="(Measures.[%{@sourceProperty}2] - ((Measures.[%{@sourceProperty}1]*Measures.[%{@sourceProperty}1])/Measures.[%{@sourceProperty}0]))" dimension="Hidden"/>
        <calculatedMember name="{@sourceProperty} Var" valueExpression="IIF(Measures.[%{@sourceProperty}0]&gt;1,IIF((Hidden.[%%{@sourceProperty}V1]&lt;0),0,(Hidden.[%%{@sourceProperty}V1]/(Measures.[%{@sourceProperty}0]-1))),-1)" dimension="Measures"/>
        <xsl:if test='@stderr="true"'>
        <calculatedMember name="{@sourceProperty} StdErr" valueExpression="IIF(Measures.[{@sourceProperty} Var]=-1,-1,sqrt(Measures.[{@sourceProperty} Var]/Measures.[%{@sourceProperty}0]))" dimension="Measures"/>
        </xsl:if>
        <xsl:comment> ======== End of <xsl:value-of select="name()"/> <xsl:text> </xsl:text> <xsl:value-of select="@sourceProperty"/> ==============</xsl:comment>
    </xsl:template>

    <xsl:template match="dsstat:regression">
        <xsl:comment> ======== Expanded from <xsl:value-of select="name()"/> <xsl:text> </xsl:text> <xsl:value-of select="@sourceProperty1"/> <xsl:value-of select="@sourceProperty2"/>==============</xsl:comment>

        <measure name="%C{@sourceProperty1}{@sourceProperty2}" hidden="true" sourceExpression="%source.{@sourceProperty1}*%source.{@sourceProperty2}" aggregate="AVG"/>
        <calculatedMember name="%%Cov{@sourceProperty1}{@sourceProperty2}" valueExpression="Measures.[%C{@sourceProperty1}{@sourceProperty2}] - ((Measures.[%{@sourceProperty1}1]*Measures.[%{@sourceProperty2}1])/(Measures.[%{@sourceProperty1}0]*Measures.[%{@sourceProperty2}0]))" dimension="Hidden"/>
        <calculatedMember name="{@sourceProperty1}{@sourceProperty2} Correlation" valueExpression="IIF(Measures.[{@sourceProperty1} Var]=-1,-1,Hidden.[%%Cov{@sourceProperty1}{@sourceProperty2}]/sqrt(Measures.[{@sourceProperty2} Var]*Measures.[{@sourceProperty1} Var]))" dimension="Measures" />
        <calculatedMember name="{@sourceProperty1}{@sourceProperty2} Slope" valueExpression="IIF(Measures.[{@sourceProperty1} Var]=-1,-1,Hidden.[%%Cov{@sourceProperty1}{@sourceProperty2}]/Measures.[{@sourceProperty1} Var])" dimension="Measures" />

        <calculatedMember name="%%{@sourceProperty1}{@sourceProperty2}I" valueExpression="Measures.[{@sourceProperty1}{@sourceProperty2} Slope]*Measures.[%{@sourceProperty1}1]/Measures.[%{@sourceProperty1}0]" dimension="Hidden" />
        <calculatedMember name="{@sourceProperty1}{@sourceProperty2} Intercept" valueExpression="IIF(Measures.[{@sourceProperty1}{@sourceProperty2} Slope]=-1,-1,Measures.[%{@sourceProperty2}1]/Measures.[%{@sourceProperty2}0] - Hidden.[%%{@sourceProperty1}{@sourceProperty2}I])" dimension="Measures" />
        <xsl:comment> ======== End of <xsl:value-of select="name()"/>  ==============</xsl:comment>
    </xsl:template>

</xsl:stylesheet>
}

}
