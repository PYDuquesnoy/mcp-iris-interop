/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.barcode Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// The namespace prefix for BarCode4J barcode elements in namespace http://barcode4j.krysalis.org/ns
Property barcodeNamespacePrefix As %ZEN.Datatype.string [ InitialExpression = "barcode" ];

/// value contains the barcode message that will be rendered, used only if field is non-null
Property value As %ZEN.Datatype.string;

/// if non-null xpath expression refering to barcode message that will be rendered
Property field As %ZEN.Datatype.string;

Property barcodeOrientation As %ZEN.Datatype.string(VALUELIST = ",0,90,-90,180,-180,270,-270") [ InitialExpression = "0" ];

/// See <href>http://barcode4j.sourceforge.net/2.1/barcode-xml.html</href> for more information about barcode types
Property barcodeType As %ZEN.Datatype.string(VALUELIST = ",intl2of5,itf-14,codabar,code39,code128,upc-a,upc-e,ean-13,ean-8,ean-128,postnet,royal-mail-cbc,usps4cb,pdf417,datamatrix") [ InitialExpression = "code39" ];

Property htmlErrorMessage As %ZEN.Datatype.caption(XMLPROJECTION = "none") [ InitialExpression = "Barcode elements are only supported in PDF output." ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Set sc=$$$OK
	Do XSL.WriteLine("<inline>"_..htmlErrorMessage_"</inline>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0, ByRef ignoreId = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.WriteLine("<fo:block"_$$$applyclass("div",.context)_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">") 
	if 'incell {
		$$$stylefo
	} elseif 'ignoreId {
		do ..OutputId(.context,.XSL,.delay)
	}
	Do XSL.WriteLine("<fo:instream-foreign-object>")
	$$$groupNumInc
	Do XSL.WriteLine("<xsl:variable name='barcodemessage"_$$$groupNum_"'>")
	if ..field'="" {
		Do XSL.WriteLine("<xsl:value-of select='"_..field_"'/>")
	} else {
		Do XSL.WriteLine("<xsl:value-of select='"""_..value_"""'/>")
	}
	Do XSL.WriteLine("</xsl:variable>")
	Do XSL.WriteLine("<"_..barcodeNamespacePrefix_$s(..barcodeNamespacePrefix'="":":",1:"")_"barcode xmlns"_$s(..barcodeNamespacePrefix'="":":",1:"")_..barcodeNamespacePrefix_"='http://barcode4j.krysalis.org/ns' message='{$barcodemessage"_$$$groupNum_"}' orientation='"_..barcodeOrientation_"'>")
	Do XSL.WriteLine("<"_..barcodeNamespacePrefix_$s(..barcodeNamespacePrefix'="":":",1:"")_..barcodeType_">")
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" {
			Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
			Quit:$$$ISERR(sc)
		}
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</"_..barcodeNamespacePrefix_$s(..barcodeNamespacePrefix'="":":",1:"")_..barcodeType_">")
	Do XSL.WriteLine("</"_..barcodeNamespacePrefix_$s(..barcodeNamespacePrefix'="":":",1:"")_"barcode>")
	Do XSL.WriteLine("</fo:instream-foreign-object>")
	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
