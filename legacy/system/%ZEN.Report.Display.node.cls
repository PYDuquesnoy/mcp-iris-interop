/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

IncludeGenerator %ZEN.ReportUtil

/// Base class for all nodes in the ReportDisplay XData block.
Class %ZEN.Report.Display.node Extends (controller, %XML.Adaptor) [ Deprecated, Inheritance = right, System = 4 ]
{

Property xpath As %String(XMLPROJECTION = "NONE");

/// We use these to record namespace and namespace prefix for qualified name
Property xmlnamespace As %String(XMLPROJECTION = "none");

Property xmlnamespaceprefix As %String(XMLPROJECTION = "none");

/// used to flag table or item, etc., as being under a small mutiple
Property withinSmallmultiple As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// use to pass down result set from table when table uses sql to generate itself
Property level As %ZEN.Datatype.integer(XMLPROJECTION = "NONE");

/// XML namespace used for Zen Report display definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display";

Parameter XMLIGNORENULL = 1;

/// By setting this to 0, we disallow use of invalid attribute names in Zen Report XML documents.
Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// Calculated property that contains the tag name of the node.
/// This corresponds to the classname.
Property tag As %String(XMLPROJECTION = "none") [ Calculated ];

/// The style string is given in the form "attribute1:value1;attribute2:value2;...",
/// just as in CSS.  In general, the style string is directly copied into HTML tags
/// as the style attribute.  In XSL-FO, each attribute is rendered separately.  That is,
/// the resulting HTML tag would look like &lt;tag style='attribute1:value1;...'/&gt; and the
/// resulting XSL-FO tag would look like &lt;tag attribute1='value1' ... /&gt;.
Property style As %ZEN.Datatype.style;

/// same as style only HTML only
Property htmlstyle As %ZEN.Datatype.style;

/// same as style only XSL-FO only
Property xslfostyle As %ZEN.Datatype.style;

/// list of conditions - true one at index i selects style
Property selectstylecond As %ZEN.Datatype.string;

/// list of styles - picked by first true index i in list of conditions
/// for more information about individual values in list see style property
Property selectstylelist As %ZEN.Datatype.string;

/// stylecall - name of xsl:template to call to output style attributes
Property stylecall As %ZEN.Datatype.string;

/// list of xpaths, xpath function calls, and XSLT function calls. 
/// for each string here an xsl:with-param is generated with its select attribute set from here
Property styleparams As %ZEN.Datatype.list(DELIMITER = ";");

/// for each name here an xsl:with-param is generated with its name attribute set from here
Property styleparamNames As %ZEN.Datatype.list(DELIMITER = ";");

/// Specifies the node's style class.  Some classes come pre-defined when standard styling
/// is specified for the report, and custom classes may be define by the &lt;class&gt; tag
/// within the &lt;document&gt; tag.  Note: parent tags propagate their class attribute to their
/// children if the child class does not have an explicit class defined.  In HTML tags,
/// class is rendered using the class attribtue, and in XSL-FO tags it is rendered using
/// the xsl:use-attribute-set attribute.  It is a fatal error to specify a class that is
/// not defined.  For more information on classes, see the <class> tag.
Property class As %ZEN.Datatype.cssClass;

/// Specifies the width of the element within its containing object (page, table cell, etc.)
Property width As %ZEN.Datatype.length;

/// Specifies the template that can be used to add children to the node
/// The format is <classname>:<xdata-name>
Property template As %ZEN.Datatype.string;

Method tagGet() As %String
{
 Quit ..%ClassName()
}

/// This method outputs the necessary stylesheet information for the HTML report.
/// Every tag should override this method.
Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Quit $$$OK
}

/// This method outputs the necessary stylesheet information for the PDF report.
/// Every tag should override this method.
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Quit $$$OK
}

/// This method outputs the stylesheet that converts the input xml to the xml with Excel annotations
/// report, table and item should override this method.  Nested tables not supported.
Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Quit $$$OK
}

Method %StyleXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, isTableCell As %Boolean = 0, ignoreId As %Boolean = 0) As %Status
{
	Set tStyle=..style
	if ..tag'="table",..id'="",ignoreId=0 {	
		do ..OutputId(.context,.XSL,.delay)
	}
	if ..style'="",..style'=$c(0) {
		if $e(..style,$L(..style))=";" {
			Set tStyle=..style_..xslfostyle
		} else {
			Set tStyle=..style_";"_..xslfostyle
		}
	} else {
		Set tStyle=..xslfostyle
	}
	if (1) {
		if (..selectstylecond="") {
			s style=tStyle
		} else {
			Set found=0
			for i=1:1:$L(..selectstylecond,",") {
				X "Set %zcond=("_$P(..selectstylecond,",",i)_")"
				if %zcond,found=0 {
					Set style=$P(..selectstylelist,",",i)
					Set found=1
				}
			}
		}


		$$$createStyleObject(style,so)
	
	
		Set key=$o(so(""))
		While (key'="") {
			Do XSL.WriteLine("<xsl:attribute name='"_key_"'>"_so(key)_"</xsl:attribute>")
			Set key=$o(so(key))
		}
  		If ('isTableCell||($e(..width,$L(..width))'="%")),..width'="",..width'="none",(('##class(%ZEN.Report.Display.tableOutput).IsFop()) || ($e(..width,$L(..width))'="%")) { 
  			Set width=$zstrip(..width,"<>W") ; strip leading and trailing whitespace
            If $Extract(width,1,$L("proportional-column-width"))="proportional-column-width" { 
                ; proportional-column-width() function may only be used on fo:table-column. 
            } ElseIf $E(width)="{" || ($E(width)="$") { 
                Do XSL.WriteLine("<xsl:attribute name='width'><xsl:value-of select='"_$Select($Extract(width)="{":$Extract(width,2,*-1),1:width)_"'/></xsl:attribute>") 
            } Else { 
                Do XSL.WriteLine("<xsl:attribute name='width'>"_width_"</xsl:attribute>") 
            } 
        }
    }
	if (..stylecall'="") {
	   Do XSL.WriteLine("<xsl:call-template name='"_..stylecall_"'>")
	    for i=1:1:$L(..styleparams,";") {
	    	Do XSL.WriteLine("<xsl:with-param name='"_$P(..styleparamNames,";",i)_"' select='"_$P(..styleparams,";",i)_"'/>")
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	}
}

ClassMethod XSLFOStyle(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, style As %String, class As %String = "", width As %String = "", xslfostyle As %String = "", id As %String = "", selectstylecond As %String = "", stylecall As %String = "", styleparams As %String = "", selectstylelist As %String = "", styleparamNames As %String = "", ignoreId As %Boolean = 0)
{
	Set tStyle=style
	if id'="",ignoreId=0 {
		if $e(id)'="!" {
			Do XSL.Write("<xsl:attribute name='id'>")
			Do XSL.Write(id)
			Do XSL.WriteLine("</xsl:attribute>")
		} else {
			Do XSL.Write("<xsl:attribute name='id'>")
			Do XSL.Write("<xsl:value-of select='"_$e(id,2,*)_"'/>")
			Do XSL.WriteLine("</xsl:attribute>")
		}
	}
	
	if style'="",style'=$c(0) {
		if $e(style,$L(style))=";" {
			Set tStyle=style_xslfostyle
		} else {
			Set tStyle=style_";"_xslfostyle
		}
	} else {
		Set tStyle=xslfostyle
	}
	if (1) {
		if (selectstylecond="") {
			s style=tStyle
		} else {
			Set found=0
			for i=1:1:$L(selectstylecond,",") {
				X "Set %zcond=("_$P(selectstylecond,",",i)_")"
				if %zcond,found=0 {
					Set style=$P(selectstylelist,",",i)
					Set found=1
				}
			}
		}


		$$$createStyleObject(style,so)
	
	
		Set key=$o(so(""))
		While (key'="") {
			Do XSL.WriteLine("<xsl:attribute name='"_key_"'>"_so(key)_"</xsl:attribute>")
			Set key=$o(so(key))
		}
		If width'="",width'="none",(('##class(%ZEN.Report.Display.tableOutput).IsFop()) || ($e(width,$L(width))'="%"))  {
			Do XSL.WriteLine("<xsl:attribute name='width'>"_width_"</xsl:attribute>")
		}
	}
	if (stylecall'="") {
	   Do XSL.WriteLine("<xsl:call-template name='"_stylecall_"'>")
	    for i=1:1:$L(styleparams,";") {
	    	Do XSL.WriteLine("<xsl:with-param name='"_$P(styleparamNames,";",i)_"' select='"_$P(styleparams,";",i)_"'/>")
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	}
}

Method %ApplyClass(tag As %String, ByRef context As %String)
{
	Set ret=""
	Set found=0
	for i=1:1:$L(..class," ") {
		Set class=$P(..class," ",i)
		if $d(context("class",tag_"."_class)) Set found=1
	}
	if found=1 Set ret=" xsl:use-attribute-sets='"
	Set sep=""
	for i=1:1:$L(..class," ") {
		Set class=$P(..class," ",i)
		Set ret=ret_sep_$s(class="":"",$d(context("class",tag_"."_class)):tag_"."_class,1:"")
		Set sep=" "
	}
	if found=1 Set ret=ret_"' "
	quit ret
}

ClassMethod ApplyClass(inclass As %String, tag As %String, ByRef context As %String)
{
	Set ret=""
	Set found=0
	for i=1:1:$L(inclass," ") {
		Set class=$P(inclass," ",i)
		if $d(context("class",tag_"."_class)) Set found=1
	}
	if found=1 Set ret=" xsl:use-attribute-sets='"
	Set sep=""
	for i=1:1:$L(inclass," ") {
		Set class=$P(inclass," ",i)
		Set ret=ret_sep_$s(class="":"",$d(context("class",tag_"."_class)):tag_"."_class,1:"")
		Set sep=" "
	}
	if found=1 Set ret=ret_"' "
	quit ret
}

Method %StyleHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, backgroundImage As %String = "", ignoreId As %Boolean = 0, pStyle As %String = "")
{
	If ..id'="",ignoreId=0 {
		do ..OutputId(.context,.XSL,.delay)

	}	

	Set tStyle=..style
	if ..style'="",..style'=$c(0) {
		if $e(..style,$L(..style))=";" {
			Set tStyle=..style_..htmlstyle
		} else {
			Set tStyle=..style_";"_..htmlstyle
		}
	} else {
		Set tStyle=..htmlstyle
	}
	if tStyle'="" {
		if $e(tStyle,*)=";" {
			Set tStyle=tStyle_pStyle
		} else {
			Set tStyle=tStyle_";"_pStyle
		}
	} else {
		Set tStyle=pStyle
	}

	s style=""
	If 1 {
		If ..width'="" {
			// basic handling for trailing ;
			If $e(tStyle,$l(tStyle)) = ";" {
				Set style=tStyle_"width:"_..width
			} Else {
				Set style=tStyle_";width:"_..width
			}
		} Else {
			Set style=tStyle
		}
		Set found=0
		if (..selectstylecond'="") {
			for i=1:1:$L(..selectstylecond,",") {
				X "Set %zcond=("_$P(..selectstylecond,",",i)_")"

				if %zcond,found=0 {
					Set style=$P(..selectstylelist,",",i)
					Set found=1
				}
			}
		}
		
		If style'="" {
			if backgroundImage="" {
				Do XSL.Write("<xsl:attribute name='style'>"_style)
			} else {
				Set sep=$s(style'="":";",1:"")
				If $e(backgroundImage)="!" {
					Set src="<xsl:value-of select='concat(&quot;"_style_sep_"background-image:url(&quot;,"_$e(backgroundImage,2,$l(backgroundImage))_",&quot;)&quot;)'/>"
					Do XSL.Write("<xsl:attribute name='style'>"_src)
				} Else {
					Set src="url("_..%GetAbsoluteURL(backgroundImage,.context,0)_")"
					Do XSL.Write("<xsl:attribute name='style'>"_style_sep_"background-image:"_src)
				}
			}
			Do XSL.WriteLine("</xsl:attribute>")
		}
		If ..class'="" {
			Do XSL.WriteLine("<xsl:attribute name='class'>"_..class_"</xsl:attribute>")
		}
		
	} 
	if (..stylecall'="") {
	    Do XSL.WriteLine("<xsl:call-template name='"_..stylecall_"'>")
	    for i=1:1:$L(..styleparams,";") {
	    	Do XSL.WriteLine("<xsl:with-param name='"_$P(..styleparamNames,";",i)_"' select='"_$P(..styleparams,";",i)_"'/>")
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	}		
	
	Quit $$$OK
}

ClassMethod HTMLStyle(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, style As %String, class As %String = "", width As %String = "", htmlstyle As %String = "", id As %String = "", selectstylecond As %String = "", stylecall As %String = "", styleparams As %String = "")
{
	If id'="" {
		Do XSL.WriteLine("<xsl:attribute name='id'>"_id_"</xsl:attribute>")
	}	

	Set tStyle=style
	if style'="",style'=$c(0) {
		if $e(style,$L(style))=";" {
			Set tStyle=style_htmlstyle
		} else {
			Set tStyle=style_";"_htmlstyle
		}
	} else {
		Set tStyle=htmlstyle
	}

	s style=""
	If 1 {
		If width'="" {
			// basic handling for trailing ;
			If $e(tStyle,$l(tStyle)) = ";" {
				Set style=tStyle_"width:"_width
			} Else {
				Set style=tStyle_";width:"_width
			}
		} Else {
			Set style=tStyle
		}
		Set found=0
		if (selectstylecond'="") {
			for i=1:1:$L(selectstylecond,",") {
				X "Set %zcond=("_$P(selectstylecond,",",i)_")"
				if %zcond,found=0 {
					Set style=$P(selectstylelist,",",i)
					Set found=1
				}
			}
		}
		
		If style'="" {
			Do XSL.WriteLine("<xsl:attribute name='style'>"_style_"</xsl:attribute>")
		}
		If class'="" {
			Do XSL.WriteLine("<xsl:attribute name='class'>"_class_"</xsl:attribute>")
		}
		
	} 
	if (stylecall'="") {
	    Do XSL.WriteLine("<xsl:call-template name='"_stylecall_"'>")
	    for i=1:1:$L(styleparams,";") {
	    	Do XSL.WriteLine("<xsl:with-param name='"_$P(styleparamNames,";",i)_"' select='"_$P(styleparams,";",i)_"'/>")
	    }
	    Do XSL.WriteLine("</xsl:call-template>")

	}		
	
	Quit $$$OK
}

Method %GetAbsoluteURL(url As %String, context As %String, isServer As %Boolean) As %String
{
	Quit:'$d(context("request","URL")) url

	
	Set pageURL=$g(context("request","URL"))
	Set pageServer=$g(context("request","server"))
	Set pagePort=$g(context("request","port"),80)
	Set isHttps=($zconvert($g(context("request","https")),"l")="on")
	Set baseurl=$s(isHttps:"https:",1:"http:")_"//"_pageServer_":"_pagePort
	
	// if the URL is relative
	If $case($p(url,":"),"http":0,"https":0,:1) {
		s CSPIHN=$g(context("request","CSPIHN"))
		if ((CSPIHN'="") && isServer && +$g(context("request","USEINSTANCEHOSTNAMEONRELATIVEURLS"))) {
			; CSPIHN is the Gateway Instance Host Name 
			Set gatewayServer=$Piece(CSPIHN,":",1) 
			Set gatewayPort=$Piece(CSPIHN,":",2)
			Set baseurl=$s(isHttps:"https:",1:"http:")_"//"_gatewayServer_":"_gatewayPort
		}

 		Set location=$$CSPNormalizeURL^%SYS.cspServer(url,pageURL)
		Set url=baseurl_location
	}
	
	Quit url
}

ClassMethod CountSpaces(literal As %String)
{
	s count=0
	for i=1:1:$L(literal) i $e(literal,i)=" " s count=count+1
	q count
}

Method tagChildren() [ Internal ]
{
	s parent=$$$THIS
	if (parent.%IsA("%ZEN.Report.Display.childrenNode")) {
		Set i = parent.children.Next("")
		While (i'="") {
			Set child = parent.children.GetAt(i)
			s child.xmlnamespace=parent.xmlnamespace
			s child.xmlnamespaceprefix=parent.xmlnamespaceprefix
			Set child.withinSmallmultiple=parent.withinSmallmultiple
			;Set child.rset=parent.rset
			Set child.level=parent.level
			Set child.applyLevel=parent.applyLevel
			Set i= parent.children.Next(i)
		}
	}
}

ClassMethod updateFromTemplate(child, parent) [ Internal ]
{
	s $zt="updateFromTemplate"
	n %template
	if '$isObject(child) quit 
	s tExists=0
	Set %template = child.template
	Set bang=$e(child.template)
	if bang="!" {
		Set %template=$e(child.template,2,*)
		X "Set %template="_%template
	}
	if child.template'="" d $zobjclassmethod($p(%template,":",1),"%GetTemplateContents",.tNewChild,$p(%template,":",2),.tExists) 
	i tExists s child=tNewChild
	q
updateFromTemplate
	s $zt=""
	q
}

Method qualify(xpath As %String)
{
	if $e(xpath)="$" Quit xpath // JSL4462
	if $e(xpath)="{" Quit xpath // JSL4462
	q ##class(%ZEN.Report.group).Qualify(xpath,..xmlnamespaceprefix)
}

ClassMethod insertAxis(xpath As %String, axis As %String, position As %Integer)
{
	s $P(xpath,"/",position)=axis_$P(xpath,"/",position)
	q xpath
}

ClassMethod parent(xpath As %String)
{
	q $P(xpath,"/",$L(xpath,"/"))
}

ClassMethod CSPLinkToFileLink(url As %String, ByRef newUrl As %String, ext As %String, makeAbsoluteURL As %Boolean = 0) As %Status
{
	s tio=$io
	s $zt="CSPLinkToFileLinkErr"
	if ('..isCSPLink(url))||'$D(%request) {
		// Prodlog 107232
		if makeAbsoluteURL {
			Set appuri=$system.CSP.GetDefaultApp($namespace)
			do ##class(%RoutineMgr).GetWebServerPort(.port)
			Set newUrl="http://localhost:"_port_appuri_"/"_url 
			q $$$OK
		} else {
			Set newUrl=url q $$$OK
		}
	}
	Set tCSPtoFile=$G(%request.Data("$CSPTOFILE",1),0)
	if 'tCSPtoFile Set newUrl=url q $$$OK
	; TBD if our %request has different server and port than CSP url then Set newURL=url and quit
	Set tDir=$G(%request.Data("$DIR",1))
	if tDir="" {
		Set tmpdir=##class(%File).NormalizeDirectory(##class(%ZEN.Report.reportPage).%GetTempDir())
	} else {
		Set tmpdir=##class(%File).NormalizeDirectory(tDir)
	}
	set tTempFiles=$G(%request.Data("$TEMP",1),0)
	if tTempFiles Set file = tmpdir_##class(%FileBinaryStream).NewFileName(ext,tmpdir)
	if 'tTempFiles {
		s tName=$tr(url,"\/:","/__")
		s tName=$P(tName,"?",1)
		Set file = tmpdir_tName_"."_ext
	}
	s file=$tr(file,"\","/")	
	Set newUrl = "file:///"_file
 	Set httprequest=##class(%Net.HttpRequest).%New()
	Set httprequest.Server=%request.GetCgiEnv("SERVER_NAME")
 	Set httprequest.Port=%request.GetCgiEnv("SERVER_PORT",80)
	i ..needsURL(url) {
		s rootURL=$P(%request.URL,"/",1,$L(%request.URL,"/")-1)
		i $e(rootURL,$L(rootURL))'="/" s rootURL=rootURL_"/"
		s url=rootURL_url
		
	}
	if $D(%session) {
		s sep="?"
		i url["?" s sep="&"
		s url=url_sep_"CSPCHD="_%session.CSPSessionCookie_"&CSPSHARE=1"
	}
	Set sta=httprequest.Get(url)
	if '$$$ISOK(sta) Set newUrl=url q $$$OK
	open file:"WN":2
 	use file
 	if $isObject(httprequest.HttpResponse.Data) {
 		Do httprequest.HttpResponse.Data.OutputToDevice()
 	} else {
	 	w !,httprequest.HttpResponse.Data
 	}
 	close file
 	use tio
	q $$$OK
CSPLinkToFileLinkErr
	s $zt=""
	use tio
	q $$$OK
}

ClassMethod isCSPLink(url As %String)
{
	; A CSP link ends in .cls or .csp once the parameters have been stripped
	; strip parameters from url
	s tURL=$P(url,"?",1)
	; look at extension (last 4 characters)
	s ext=$e(tURL,$L(tURL)-3,$L(tURL))
	q (ext=".cls")||(ext=".csp")
}

ClassMethod needsURL(url As %String)
{
	if url["/" q 0
	q 1
}

ClassMethod GetDocForXSLFO(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String) As document
{
	Set document=##class(%ZEN.Report.Display.document).%New()
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		d this.updateFromTemplate(.child)		
		Set child.parent=this
		Set child.xpath=xpath
		If child.%Extends("%ZEN.Report.Display.document") {
			if 'child.%Extends("%ZEN.Report.Display.composite") {
				Set document=child Quit
			} else {
				Set document=child.GetDocForXSLFO(child, .context, .XSL, child.children, xpath) quit
			}
			Set orientation=document.orientation
		}
		//If (child.tag="pagefooter")||(child.tag="pageheader") {
		//	Set child.orientation=document.orientation
		//}
		Set i= children.Next(i)
	}
	quit document
}

ClassMethod DoDocForHTML(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String)
{
		Set i = children.Next("")
		While (i'="") {
			Set child=children.GetAt(i)
			d this.updateFromTemplate(.child)		
			Set child.parent=this
			Set child.xpath=xpath
			If child.%Extends("%ZEN.Report.Display.document") {
				if 'child.%Extends("%ZEN.Report.Display.composite") {
					Do child.%DrawStyleToHTML(.context,.XSL,.delay)
				} else {
					Do child.DoDocForHTML(child, .context, .XSL, child.children, xpath)
				}
			}
			Set i= children.Next(i)
		}
}

ClassMethod processExclamationPoint(x As %String)
{
	if $e(x)'="!" {
		quit x
	} else {
		quit "<xsl:value-of select='"_$e(x,2,*)_"'/>"
	}
}

Method OutputId(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	if ..id'="" {
		if $e(..id)'="!" {
			Do XSL.Write("<xsl:attribute name='id'>")
			Do XSL.Write(..id)
			Do XSL.WriteLine("</xsl:attribute>")
		} else {
			Do XSL.Write("<xsl:attribute name='id'>")
			Do XSL.Write("<xsl:value-of select='"_$e(..id,2,*)_"'/>")
			Do XSL.WriteLine("</xsl:attribute>")
		}
	}
}

}
