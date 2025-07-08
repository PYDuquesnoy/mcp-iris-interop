/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// The controller class has the <xsl:if> logic that allows any node or tableOuput
/// to be removed from rendering
Class %ZEN.Report.Display.controller Extends common [ Deprecated, System = 4 ]
{

Property ifxpath As %ZEN.Datatype.string;

Property ifexpression As %ZEN.Datatype.string;

Property unlessexpression As %ZEN.Datatype.string;

Property includeColUnlessExpression As %ZEN.Datatype.string;

Property includeColIfExpression As %ZEN.Datatype.string;

Property includeColUnlessXPath As %ZEN.Datatype.string;

Property includeColIfXPath As %ZEN.Datatype.string;

Property applyLevel As %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

Method %BeginFOIf(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..IfCommon(.context,.XSL,.delay)
}

Method %EndFOIf(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..EndIfCommon(.context,.XSL,.delay)
}

Method %BeginHTMLIf(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..IfCommon(.context,.XSL,.delay)
}

Method %EndHTMLIf(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..EndIfCommon(.context,.XSL,.delay)
}

Method IfIncludeCol(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if ..includeColIfExpression'="" {
		X "s %val=("_..includeColIfExpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=1'>")
	}
	if ..includeColUnlessExpression'="" {
		X "s %val=("_..includeColUnlessExpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=0'>")
	}
	if ..includeColIfXPath'="" {
		Do XSL.WriteLine("<xsl:if test='"_..includeColIfXPath_"'>")
	}
	if ..includeColUnlessXPath'="" {
		Do XSL.WriteLine("<xsl:if test='not("_..includeColUnlessXPath_")'>")
	}

	q $$$OK
}

Method EndIfIncludeCol(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if ..includeColIfExpression'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	if ..includeColUnlessExpression'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	if ..includeColIfXPath'="" {
		Do XSL.WriteLine("</xsl:if>")
	}
	if ..includeColUnlessXPath'="" {
		Do XSL.WriteLine("</xsl:if>")
	}

	q $$$OK
}

Method IfCommon(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if ..ifexpression'="" {
		X "s %val=("_..ifexpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=1'>")
	}
	if ..unlessexpression'="" {
		X "s %val=("_..unlessexpression_")"
		Do XSL.WriteLine("<xsl:if test='"_%val_"=0'>")
	}

	if ..ifxpath'="" Do XSL.WriteLine("<xsl:if test='"_..ifxpath_"'>")
	s tSC=..IfIncludeCol(.context,.XSL,.delay)
	q tSC
}

Method EndIfCommon(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if ..ifxpath'="" Do XSL.WriteLine("</xsl:if>")
	if ..ifexpression'="" Do XSL.WriteLine("</xsl:if>")
	if ..unlessexpression'="" Do XSL.WriteLine("</xsl:if>")
	s tSC=..EndIfIncludeCol(.context,.XSL,.delay)
	q tSC
}

Method %BeginDrawHtml(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if '$g(context("xdata",##this.%ClassName(1))) { // don't allow more than 1 copy of Xdata
		Set context("xdata",##this.%ClassName(1))=1
		do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"AllXslt",##this.%ClassName(1)) // JSL4288
		do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"HtmlXslt",##this.%ClassName(1)) // JSL4288
	}
	q ..%BeginHTMLIf(.context,.XSL,.delay)
}

Method %EndDrawHtml(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..%EndHTMLIf(.context,.XSL,.delay)
}

Method %BeginDrawFo(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	if '$g(context("xdata",##this.%ClassName(1))) { // don't allow more than 1 copy of Xdata
		Set context("xdata",##this.%ClassName(1))=1
		do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"AllXslt",##this.%ClassName(1)) // JSL4288
		do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"XslFoXslt",##this.%ClassName(1)) // JSL4288
	}
	q ..%BeginFOIf(.context,.XSL,.delay)
}

Method %EndDrawFo(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status [ Internal ]
{
	q ..%EndFOIf(.context,.XSL,.delay)
}

Method %IncLevel(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Set ..applyLevel=..applyLevel+1
}

Method %ApplyLevelParameters(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	//$$$levelNumInc
	Do XSL.WriteLine("<xsl:with-param name='zenPageSequenceId' select='$zenPageSequenceId'/>")
	Do XSL.WriteLine("<!-- apply level = "_..applyLevel_" -->")
	for i=0:1:..applyLevel-1 {
		Do XSL.WriteLine("<xsl:with-param name='level"_i_"' select='$level"_i_"'/>")
	}
	Do XSL.WriteLine("<xsl:with-param name='level"_..applyLevel_"' select='position()'/>")
	;Do XSL.WriteLine("<xsl:with-param name='tableNumber' select='"_$$$tableNum_"'/>")
}

Method %DeclareLevelParameters(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:param name='zenPageSequenceId'/>")
	for i=0:1:..applyLevel {
		Do XSL.WriteLine("<xsl:param name='level"_i_"'/>")
	}
	Do XSL.WriteLine("<xsl:param name='level"_(i+1)_"' select='position()'/>")
	;Do XSL.WriteLine("<xsl:param name='currmatch' select='position()'/>")
	;Do XSL.WriteLine("<xsl:param name='tableNumber'/>")
}

Method %EndLevel(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	//$$$levelNumDec
	Set ..applyLevel=..applyLevel-1
	Do XSL.WriteLine("<!-- end level = "_..applyLevel_" -->")
}

}
