/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// This class provides utility methods for CSPBIND related tools.
Class %CSP.DwxUtils [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// Returns information about what kind of member <var>member</var> is.
/// <p>Upon return, <var>mtype</var> contains either a property type, in the case 
/// of a property, or a return type in the case of a method.
/// Possible return values include:
/// <table cols=2>
/// <tr><td><b>LITERAL</b></td><td>A literal property</td></tr>
/// <tr><td><b>MULTIDIM</b></td><td>A multidimensional property</td></tr>
/// <tr><td><b>PERSISTENT</b></td><td>A reference property</td></tr>
/// <tr><td><b>SERIAL</b></td><td>A serial property</td></tr>
/// <tr><td><b>METHOD</b></td><td>A method</td></tr>
/// <tr><td><b>ID</b></td><td>The %Id() method</td></tr>
/// <tr><td><b>STREAM</b></td><td>A stream attribute</td></tr>
/// <tr><td><b>BSTREAM</b></td><td>A binary stream attribute</td></tr>
/// <tr><td><b>LIST</b></td><td>A list of datatypes attribute</td></tr>
/// <tr><td><b>LISTOBJ</b></td><td>A list of objects attribute</td></tr>
/// <tr><td><b>&quot;&quot;</b></td><td>Not a member</td></tr>
/// </table>
ClassMethod GetMemberInfo(class As %String, member As %String, ByRef mtype As %String) As %String [ Internal ]
{
	New type,name,classtype,colltype
	Set type=""
	Set mtype=""

	; normalize class name
	Set class=$$$NormalizeClassname(class)

	; test if class exists
	If ('##class(%ClassDefinition).%ExistsId(class)) QUIT ""

	; test for id, method or property
	If member="" {
		Set type=""
	} ElseIf member="%Id()" {
		Set type="ID",mtype="%String"
	} ElseIf member["(" {
		Set name=$P(member,"(",1)
		If $$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHrunnable) {
			Set type="METHOD",mtype=$$$comMemberKeyGet(class,$$$cCLASSmethod,name,$$$cMETHreturntype)
		}
	} ElseIf $$$comMemberDefined(class,$$$cCLASSproperty,member) {
		Set mtype=$$$comMemberKeyGet(class,$$$cCLASSproperty,member,$$$cPROPtype)
		Set colltype=$$$comMemberKeyGet(class,$$$cCLASSproperty,member,$$$cPROPcollection)
		Set classtype=$$$getClassType(mtype)
		If colltype=$$$cPROPCOLLECTIONLIST {
			If (classtype=$$$cCLASSCLASSTYPEPERSISTENT)!(classtype=$$$cCLASSCLASSTYPESERIAL) {
				Set type="LISTOBJ"
			} Else {
				Set type="LIST"
			}
		} ElseIf colltype=$$$cPROPCOLLECTIONARRAY {
			Set type="ARRAY"
		} ElseIf classtype="stream" {
			$$$comClassKeyGetLvar(clientdatatype,mtype,$$$cCLASSclientdatatype)
			If clientdatatype="BINARYSTREAM" {
				Set type="BSTREAM"
			} ElseIf clientdatatype="CHARACTERSTREAM" {
				Set type="STREAM"
			}
		} ElseIf classtype=$$$cCLASSCLASSTYPEPERSISTENT {
			Set type="PERSISTENT"
		} ElseIf classtype=$$$cCLASSCLASSTYPESERIAL {
			Set type="SERIAL"
		} ElseIf ($$$comMemberKeyGet(class,$$$cCLASSproperty,member,$$$cPROPmultidimensional) = 1) {
			Set type="MULTIDIM"
		} Else {
			Set type="LITERAL"
		}
	}

	Quit type
}

/// This returns the same information as <METHOD>getMemberInfo</MEMBER> except that 
/// the information pertains to the member referenced by <var>member</member>.
/// <p><var>mname</var> is the referenced member name.
/// <p><var>mcontainer</var> is name of the class containing the member. 
/// (equal to <var>class</var> if member is not an extended reference.
ClassMethod GetReferenceInfo(class As %String, member As %String, ByRef mtype As %String, ByRef mname As %String, ByRef mcontainer As %String) As %String [ Internal ]
{
	New type,name,i,pre,post,info
	Set type=""
	Set mtype=""
	Set mname=""
	Set info=""

	; normalize class name
	Set class=$$$NormalizeClassname(class)

	Set mcontainer=class

	;scan for dot syntax (check for ())
	If (member[".") {
		For i=1:1:$L(member) {
			If ($E(member,i,i)=".") {
				Set pre=$E(member,1,i-1),post=$E(member,i+1,$L(member))
				Set info=..GetMemberInfo(class,pre,.type)
				Set:(info="LIST"!info="LISTOBJ") type="%AbstractList"
				Set:info="ARRAY" type="%AbstractArray"
				Set:info="STREAM" type="%AbstractStream"
				Set:info="BSTREAM" type="%AbstractStream"
				If ((info'="LITERAL")&(info'="METHOD")) {
					Set info=..GetReferenceInfo(type,post,.type,.mname,.mcontainer)
				}
				Quit
			}
		}
	} Else {
		Set info=..GetMemberInfo(class,member,.type)
		Set mname=member
	}

	Set mtype=type
	QUIT info
}

/// Used by form tag to get the value of the VALUE attribute for 
/// an HTML control bound to this member. <var>oref</var> is the name 
/// of the oref variable.
ClassMethod GetValueExpression(class As %String, member As %String, oref As %String, mode As %String = "HTML", listmode As %String = "S", pagelanguage As %String = "cache", js As %Boolean = 0) As %String [ Internal, ProcedureBlock = 1 ]
{
	If $extract(member,1,1)="." Quit ""
	
	Set expr=""
	
	Set dot=$select(pagelanguage["mv":"->",1:".")
	
	;scan for dot syntax (check for ())
	Set pos=$find(member,dot)
	If pos'=0 {
		Set pre=$extract(member,1,pos-$length(dot)-1)
		Set post=$extract(member,pos,$length(member))
			Set info=..GetMemberInfo(class,pre,.type)
			Set:(info="LIST"!info="LISTOBJ") type="%AbstractList"
			Set:info="ARRAY" type="%AbstractArray"
			Set:info="STREAM" type="%AbstractStream"
			Set:info="BSTREAM" type="%AbstractStream"
		Set expr=..GetValueExpression(type,post,oref_dot_pre,mode,listmode,pagelanguage,js)
			}
	
	If (expr="") {
		Set info=..GetMemberInfo(class,member,.type)
		;Quote member if needed
		If (info'="")&&(info'="ID")&&(info'="METHOD") {
			Set member = $$$QN(member)
		}
		; build expression
		If (info="LITERAL") {
			If (..HasL2D(class,member)) {
				Set expr=oref_dot_member_"LogicalToDisplay("_oref_dot_member_")"
			} Else {
				Set expr=oref_dot_member
			}
			If js {
				If pagelanguage="basic" {
					Set expr="case("_oref_"."_member_",$Chr(0):"""",:("_expr_"))"
				} ElseIf pagelanguage="mvbasic" {
					Set expr="(IF "_oref_"->"_member_"=$Char(0) THEN """" ELSE ("_expr_"))"
				} Else {
					Set expr="$select("_oref_"."_member_"=$c(0):"""",1:("_expr_"))"
				}
			}
		} ElseIf (info="MULTIDIM") {
			Set expr="$G("_oref_dot_member_")"
		} ElseIf (info="PERSISTENT") {
			Set expr=oref_dot_member_"GetObjectId()"
		} ElseIf (info="SERIAL") {
			Set expr=oref_dot_member_dot_"LogicalToOdbc("_oref_dot_member_"GetObjectId())"
		} ElseIf (info="LIST") {
			If $extract(listmode,1)="S" {
				Set delim=$extract(listmode,2,$length(listmode))
				If pagelanguage="basic" {
					Set expr="""%CSP.DwxUtils"".ListToDisplay("_oref_"."_member_$select(delim'="":","""_delim_"""",1:",")_","""_mode_""")"
				} ElseIf pagelanguage="mvbasic" {
					Set expr="""%CSP.DwxUtils""->ListToDisplay("_oref_"->"_member_$select(delim'="":","""_delim_"""",1:",")_","""_mode_""")"
				} Else {
					Set expr="##class(%CSP.DwxUtils).ListToDisplay("_oref_"."_member_$select(delim'="":","""_delim_"""",1:",")_","""_mode_""")"
				}
			} ElseIf $extract(listmode,1)="L" {
				Set expr=oref_dot_member_$extract(listmode,2,$length(listmode))
			}
		} ElseIf (info="LISTOBJ") {
			If $extract(listmode,1)="S" {
				Set expr="%response"_dot_"GetText("""",""%CSPBind"",""NoListOfObjects"",""List of Objects is not supported."")"
			} ElseIf $extract(listmode,1)="L" {
				Set expr=oref_dot_member_$extract(listmode,2,$length(listmode))
			}
		} ElseIf (info="METHOD")!(info="ID") {
			Set expr=oref_dot_member
		} ElseIf (info="STREAM") {
			If pagelanguage="basic" {
				Set expr="""%CSP.DwxUtils"".EscapeStream("_oref_"."_member_","""_mode_""")"
			} ElseIf pagelanguage="mvbasic" {
				Set expr="""%CSP.DwxUtils""->EscapeStream("_oref_"->"_member_","""_mode_""")"
			} Else {
				Set expr="##class(%CSP.DwxUtils).EscapeStream("_oref_"."_member_","""_mode_""")"
			}
		} ElseIf (info="BSTREAM") {
			If pagelanguage="basic" {
				Set expr="case("_oref_"."_member_","""":"""",:"_oref_"."_member_".%Oid())"
			} ElseIf pagelanguage="mvbasic" {
				Set expr="( IF "_oref_"->"_member_"="""" THEN """" ELSE "_oref_"->"_member_".%Oid())"
			} Else {
				Set expr="$select("_oref_"."_member_"="""":"""",1:"_oref_"."_member_".%Oid())"
			}
		} ElseIf (info'="") {
			Set expr=oref_dot_member
		}
	}

	If expr="" {
		Quit ""
	} ElseIf pagelanguage="basic" {
		Quit "case("_oref_","""":"""",:("_expr_"))"
	} ElseIf pagelanguage="mvbasic" {
		Quit "(IF "_oref_"="""" THEN """" ELSE ("_expr_"))"
	} Else {
		Quit "$select("_oref_"="""":"""",1:("_expr_"))"
	}
}

/// Used by form tag to return a code snippet containing a 
/// code snippet to set the value of the specified class member. <var>oref</var> 
/// is the name of the oref variable. <var>varname</var> is the name of the 
/// variable containing the value to set into the member. <var>caption</var> is name used 
/// in the generated error message.
/// <p>As <var>caption</var> is used to create a JavaScript message, it needs to 
/// have any special characters quoted accordingly.
ClassMethod GetSetCode(class As %String, member As %String, oref As %String, varname As %String, caption As %String, testcode As %String = "", listmode As %String = "") As %String [ Internal ]
{
	New info,type,c,i,pre,post,code,delim,errcode,indent

	QUIT:$E(member,1,1)="." ""
	
	Set code=""
	
	;scan for dot syntax (check for ())
	If (member[".") {
		For i=1:1:$L(member) {
			If ($E(member,i,i)=".") {
			Set pre=$E(member,1,i-1),post=$E(member,i+1,$L(member))
			Set info=..GetMemberInfo(class,pre,.type)
			Set:(info="LIST"!info="LISTOBJ") type="%AbstractList"
			Set:info="ARRAY" type="%AbstractArray"
			Set:info="STREAM" type="%AbstractStream"
			Set:info="BSTREAM" type="%AbstractStream"
			Set:info="PERSISTENT" testcode=testcode_$S(testcode="":"If ",1:",")_"("_oref_"."_pre_"'="""")"
			Set code=..GetSetCode(type,post,oref_"."_pre,varname,caption,testcode,listmode)
			Quit
			}
		}
	}
	
	If (code="") {
		Set code=code_" ; "_member_" "_$$$EOL
		Set info=..GetMemberInfo(class,member,.type)
		; build expression
		Set:testcode'="" testcode=testcode_" "
		Set errcode="Set error=error_%response.GetText("""",""%CSPBind"",""InvalidValue"",""%1 has an invalid value."","""_caption_""")_""\n"""
		If (info="LITERAL") {
			If ..HasD2L(class,member) {
				Set code=code_" If $data("_varname_") {"_$$$EOL
				Set code=code_"   Set value=$select("_varname_"="""":"""",1:##class("_class_")."_member_"DisplayToLogical("_varname_"))"_$$$EOL
				Set code=code_"   If ("_varname_"'=""""),(value="""") {"_$$$EOL
				Set code=code_"     "_errcode_$$$EOL
				Set code=code_"   } Else {"_$$$EOL
				Set code=code_"     "_testcode_"Set "_oref_"."_member_"=value"_$$$EOL
				Set code=code_"   }"_$$$EOL
				Set code=code_" }"_$$$EOL
			} Else {
				Set code=code_" If $data("_varname_") {"_$$$EOL
				Set code=code_"   "_testcode_"Set "_oref_"."_member_"="_varname_$$$EOL
				Set code=code_" }"_$$$EOL
			}
		} ElseIf (info="PERSISTENT") {
			Set code=code_" If $data("_varname_") {"_$$$EOL
			Set code=code_"   If ("_varname_"'=""""),'##class("_type_").%ExistsId("_varname_") {"_$$$EOL
			Set code=code_"     "_errcode_$$$EOL
			Set code=code_"   } Else {"_$$$EOL
			Set code=code_"     "_testcode_"Do "_oref_"."_member_"SetObjectId("_varname_")"_$$$EOL
			Set code=code_"   }"_$$$EOL
			Set code=code_" }"_$$$EOL
		} ElseIf (info="SERIAL") {
			Set code=code_" If $data("_varname_") {"_$$$EOL
			Set code=code_"   Set value=$select("_varname_"="""":"""",1:"_oref_"."_member_".OdbcToLogical("_varname_"))"_$$$EOL
			Set code=code_"   If ("_varname_"'=""""),(value="""") {"_$$$EOL
			Set code=code_"     "_errcode_$$$EOL
			Set code=code_"   } Else {"_$$$EOL
			Set code=code_"     "_testcode_"Do "_oref_"."_member_"SetObjectId(value)"_$$$EOL
			Set code=code_"   }"_$$$EOL
			Set code=code_" }"_$$$EOL
		} ElseIf (info="LIST") {
			If $extract(listmode,1)="S" {
				Set delim=$extract(listmode,2,$length(listmode))
				Set code=code_" If $data("_varname_") {"_$$$EOL
				Set code=code_"   Set value=$select("_varname_"="""":"""",1:"_oref_"."_member_".DisplayToLogical("_varname_$S(delim'="":","""_delim_"""",1:"")_"))"_$$$EOL
				Set code=code_"   If ("_varname_"'=""""),(value="""") {"_$$$EOL
				Set code=code_"     "_errcode_$$$EOL
				Set code=code_"   } Else {"_$$$EOL
				Set code=code_"     "_testcode_"Do "_oref_"."_member_".Clear(),"_oref_"."_member_".InsertList(value)"_$$$EOL
				Set code=code_"   }"_$$$EOL
				Set code=code_" }"_$$$EOL
			} ElseIf listmode="L" {
				Set indent=""
				If testcode'="" {
					Set code=code_" "_testcode_" {"_$$$EOL
					Set indent="  "
				}
				Set code=code_indent_"   Do "_oref_"."_member_".Clear()"_$$$EOL
				Set code=code_indent_"   If $data("_varname_")=1 {"_$$$EOL
				Set code=code_indent_"     Do "_oref_"."_member_".Insert("_varname_")"_$$$EOL
				Set code=code_indent_"   } Else {"_$$$EOL
				Set code=code_indent_"     Set i=$order("_varname_"(""""))"_$$$EOL
				Set code=code_indent_"     While i'="""" {"_$$$EOL
				Set code=code_indent_"       Do "_oref_"."_member_".Insert("_varname_"(i))"_$$$EOL
				Set code=code_indent_"       Set i=$order("_varname_"(i))"_$$$EOL
				Set code=code_indent_"     }"_$$$EOL
				Set code=code_indent_"   }"_$$$EOL
				If testcode'="" {
					Set code=code_" }"_$$$EOL
				}
			}
		} ElseIf (info="LISTOBJ") {
			If listmode="L" {
				Set indent=""
				If testcode'="" {
					Set code=code_" "_testcode_" {"_$$$EOL
					Set indent="  "
				}
				Set code=code_indent_" Do "_oref_"."_member_".Clear()"_$$$EOL
				Set code=code_indent_" If $data("_varname_")=1 {"_$$$EOL
				Set code=code_indent_"   Do "_oref_"."_member_".InsertObjectId("_varname_")"_$$$EOL
				Set code=code_indent_" } Else {"_$$$EOL
				Set code=code_indent_"   Set i=$order("_varname_"(""""))"_$$$EOL
				Set code=code_indent_"   While i'="""" {"_$$$EOL
				Set code=code_indent_"     Do "_oref_"."_member_".InsertObjectId("_varname_"(i))"_$$$EOL
				Set code=code_indent_"     Set i=$order("_varname_"(i))"_$$$EOL
				Set code=code_indent_"   }"_$$$EOL
				Set code=code_indent_" }"_$$$EOL
				If testcode'="" {
					Set code=code_" }"_$$$EOL
				}
			}
		} ElseIf (info="STREAM") {
			Set code=code_" If $data("_varname_")"
			If testcode'="" Set code=code_"&&("_testcode_")"
			Set code=code_" {"_$$$EOL
			Set code=code_"   Do "_oref_"."_member_".Rewind()"_$$$EOL
			Set code=code_"   If $isobject("_varname_") {"_$$$EOL
			Set code=code_"     Do "_varname_".Rewind()"_$$$EOL
			Set code=code_"     While '"_varname_".AtEnd {"_$$$EOL
			Set code=code_"       Do "_oref_"."_member_".Write("_varname_".Read(16000))"_$$$EOL
			Set code=code_"     }"_$$$EOL
			Set code=code_"   } Else {"_$$$EOL
			Set code=code_"     Do "_oref_"."_member_".Write("_varname_")"_$$$EOL
			Set code=code_"   }"_$$$EOL
			Set code=code_" }"_$$$EOL
		}
	}
	
	// Note: we do not generate code for BSTREAM or LISTOBJ.  Exception is
	//		LISTOBJ for SELECT tag.
	
	Quit code
}

/// Used by the csp:search tag to return a code snippet to retrieve the
/// logical value of the specified class member. 
/// Constructs a command to convert the display value in the
/// variable named <var>varname</var> to a logical value and save it in 
/// the variable named <var>value</var>.
ClassMethod GetLogicalValue(class As %String, member As %String, value As %String, varname As %String) As %String [ Internal ]
{
	New info,type,c,i,pre,post,code

	QUIT:$E(member,1,1)="." ""

	Set code=""

	;scan for dot syntax (check for ())
	If (member[".") {
		For i=1:1:$L(member) {
			If ($E(member,i,i)=".") {
				Set pre=$E(member,1,i-1),post=$E(member,i+1,$L(member))
				Set info=..GetMemberInfo(class,pre,.type)
				Set:(info="LIST"!info="LISTOBJ") type="%AbstractList"
				Set:info="ARRAY" type="%AbstractArray"
				Set:info="STREAM" type="%AbstractStream"
				Set:info="BSTREAM" type="%AbstractStream"
				Set code=..GetLogicalValue(type,post,value,varname)
				Quit
			}
		}
	}

	If (code="") {
		Set info=..GetMemberInfo(class,member,.type)
		; build expression
		If (info="LITERAL")&&..HasD2L(class,member) {
			Set code=code_"Set "_value_"=##class("_class_")."_member_"DisplayToLogical("_varname_")"
		} Else {
			Set code=code_"Set "_value_"="_varname
		}
	}

	Quit code
}

/// Returns true if property <var>prop</var> has a DisplayToLogical method.
ClassMethod HasD2L(class As %String, prop As %String) As %Boolean [ CodeMode = expression, Internal ]
{
''$$$comSubMemberDefined($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPmethod,"DisplayToLogical")
}

/// Returns true if property <var>prop</var> has a LogicalToDisplay method.
ClassMethod HasL2D(class As %String, prop As %String) As %Boolean [ CodeMode = expression, Internal ]
{
''$$$comSubMemberDefined($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPmethod,"LogicalToDisplay")
}

/// Recursively builds an array of orefs to all the children 
/// of element <var>parent</var>. Text atoms are not included.
ClassMethod GetElementChildren(parent As %CSP.Element, ByRef children) [ Internal ]
{
 New i,count,el
 Set count=parent.Children.Count()

 For i=1:1:count Set el=parent.Children.GetAt(i) Do:el.TagName'=""  ; tag name is "" for atoms
 . Set children($increment(children))=el
 . If (el.Children.Count()>0) Do ..GetElementChildren(el,.children)

 QUIT
}

/// Writes out the contents of the stream as quoted text.<br>
/// <var>mode</var> can be HTML or JS.
ClassMethod EscapeStream(stream As %AbstractStream, mode As %String = "HTML") As %String [ Internal, ProcedureBlock = 1 ]
{
 If (stream="") Quit ""

 Do stream.Rewind()
 If (mode="HTMLSTRING") {
	 Quit stream.Read(32000)
 } Else {
	 While 'stream.AtEnd {
	 	Set len=1000
	 	If (mode="HTML") {
		 	Set text=##class(%CSP.Page).EscapeHTML(stream.Read(.len))
	 	} Else  {
		 	Set text=##class(%CSP.Page).QuoteJS(stream.Read(.len))_" + "
	 	}
	 	If (text'="") Write text
	 }
 }

 Quit ""
}

/// Gets the contents of a list of datatypes as a delimiter separated string
ClassMethod ListToDisplay(list As %Collection.ListOfDT, delim As %String = {$char(13,10)}, mode As %String = "HTML") As %String [ Internal, ProcedureBlock = 1 ]
{
	Set delim=$get(delim,$char(13,10))
	Set (display,sep)=""
	If (mode="HTMLSTRING") {
		For i=1:1:list.Count() Set display=display_sep_list.GetAt(i) Set sep=delim
	} ElseIf (mode="HTML") {
		For i=1:1:list.Count() Write sep_##class(%CSP.Page).EscapeHTML(list.GetAt(i)) Set sep=delim
	} Else {
		For i=1:1:list.Count() {
			Set element=list.GetAt(i)
			If $length(display)+$length(element)>1000 {
				If display'="" Write ##class(%CSP.Page).QuoteJS(display)_" + "
				Set display=sep_element
			} Else {
				Set display=display_sep_element
			}
			Set sep=delim
		}
	}
	Quit display
}

/// Returns the HTML (as a table row) for a control for the 
/// specified binding.
/// !!! pass in query/field for reference combo!
ClassMethod GetHTMLForField(class As %String, bind As %String, readonly As %Boolean = 0, precaption As %String = "<b>", postcaption As %String = ":</b>") As %String [ Internal ]
{
 New info,mtype,maxlen,caption,collection,dtype,required,search,name
 New member,mcontainer,control,vlist,dlist,i,vdelim,ddelim
 New code
 Set code=""

 Set info=..GetReferenceInfo(class,bind,.mtype,.member,.mcontainer)

 If (info="") Quit ""

 Set name=$TR(bind,".","_")
 Set size=0
 Set caption=""
 Set required=0
 Set (vdelim,ddelim)=","

 ; control can be text,checkbox,textarea,combo,query
 Set control=""

 If ((info="LITERAL")!(info="SERIAL")!(info="PERSISTENT")!(info="STREAM")!(info="LIST")) Do
 . Set caption=..GetPropertyCaption(mcontainer,member)
 . Set:(caption="") caption=$TR(bind,"."," ")
 . Set required=..IsPropertyRequired(mcontainer,member)
 . Set:(readonly=0) readonly=..IsPropertyReadOnly(mcontainer,member)
 . ; make referenced properties readonly
 . If (info="PERSISTENT"),(bind[".") Set readonly=1
 . Set maxlen=..GetPropertyMaxLen(mcontainer,member)
 . Set:(maxlen'="") size=+maxlen
 . Set:((control="")&(mtype="%Boolean")) control="checkbox" ; !!!use client type
 . If (info="LITERAL"),(control=""),('readonly) Do
 . . Set vlist=..GetPropertyParam(mcontainer,member,"VALUELIST")
 . . Set vdelim=$E(vlist,1,1)
 . . Set dlist=..GetPropertyParam(mcontainer,member,"DISPLAYLIST")
 . . Set:(dlist="") dlist=vlist,ddelim=vdelim
 . . Set ddelim=$E(dlist,1,1)
 . . Set:(dlist'="") control="combo"
 . Else  If (info="STREAM"),(control="") Do
 . . Set control="textarea"
 . Else  If (info="PERSISTENT"),(control="") Do
 . . Set control="query"
 Else  If ((info="METHOD")!(info="ID")) Do
 . Set caption=$TR($P(bind,"(",1),".%","  ")
 . Set name=$TR($P(name,"(",1),".%","_")
 . Set readonly=1

 ; check maximum size of fields
 Set:(size>50) size=50

 ; caption
 Set code=code_"<tr>"
 Set code=code_"<td><div align=""right"">"_precaption_caption_postcaption_"</div></td>"

 ; control
 Set:(control="") control="text"

 If ((control="text")!(control="checkbox")) Do
 . ; text box
 . Set code=code_"<td><input type="""_control_""" name="""_name_""" cspbind="""_bind_""""
 . Set:(required=1) code=code_" csprequired"
 . Set:(readonly=1) code=code_" readonly"
 . Set:(size>0) code=code_" size="""_size_"""" 
 . Set code=code_">"_$S(required=1:"*",1:"")_"</td>"

 Else  If ((control="textarea")) Do
 . ; textarea
 . Set code=code_"<td><textarea name="""_name_""" cspbind="""_bind_""""
 . Set:(required=1) code=code_" csprequired"
 . Set:(readonly=1) code=code_" readonly"
 . Set code=code_"></textarea>"_$S(required=1:"*",1:"")_"</td>"

 Else  If (control="combo"),(dlist'="") Do
 . ; combo box
 . Set code=code_"<td><select name="""_name_""" cspbind="""_bind_""""
 . Set:(readonly=1) code=code_" readonly"
 . Set code=code_">"
 . For i=1:1:$L(vlist,vdelim)  Do
 . . Set code=code_"<option value="""_$P(dlist,ddelim,i)_""">"_$P(dlist,ddelim,i)
 . Set code=code_"</select></td>"

 Else  If (control="query") Do
 . ; query combo box
 . Set code=code_"<td><select name="""_name_""" cspbind="""_bind_""" classname="""_mtype_""" query=""Extent"""
 . Set:(readonly=1) code=code_" readonly"
 . Set code=code_"></select></td>"

 Set code=code_"</tr>"

 Quit code
}

/// Test method
ClassMethod Test() [ Internal ]
{
 Write "Test!",!
 QUIT
}

/// Does the string <VAR>prop</VAR> represent a method?
/// If not return "", if so return the name of the method.
ClassMethod IsMethod(class As %String, prop As %String) As %String [ Internal ]
{
 New name
 Quit:prop'["(" ""

 Set name=$P(prop,"(",1)
 Quit name
}

/// Return a string containing the data type (class name) for 
/// property <VAR>prop</VAR> of class <VAR>class</VAR>.
ClassMethod GetPropertyType(class As %String, prop As %String) As %String [ CodeMode = expression, Internal ]
{
$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPtype)
}

/// Returns whether property <VAR>prop</VAR> of class <VAR>class</VAR> 
/// is a required field.
ClassMethod IsPropertyRequired(class As %String, prop As %String) As %Boolean [ CodeMode = expression, Internal ]
{
$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPrequired)
}

/// Returns whether property <VAR>prop</VAR> of class <VAR>class</VAR> 
/// is read only.
ClassMethod IsPropertyReadOnly(class As %String, prop As %String) As %Boolean [ Internal ]
{
	New ro

	Quit:..IsPropertyStream(class,prop) 0

	If $$$comMemberKeyGet(class,$$$cCLASSmethod,prop_"Set",$$$cMETHstub)'="" {
		Set ro='$$$comSubMemberDefined(class,$$$cCLASSproperty,prop,$$$cPROPmethod,"Set")
	} Else {
		Set ro='$$$comMemberKeyGet(class,$$$cCLASSmethod,prop_"Set",$$$cMETHrunnable)
	}

	QUIT ro
}

/// Returns whether  
/// property <VAR>prop</VAR> of class <VAR>class</VAR> is a stream.
ClassMethod IsPropertyStream(class As %String, prop As %String) As %Boolean [ CodeMode = expression, Internal ]
{
($$$comMemberKeyGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPtype)="%Library.Stream")&&($$$classIsSerial($$$comMemberKeyGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPruntimetype)))
}

/// Returns whether property <VAR>prop</VAR> of class <VAR>class</VAR> 
/// has an index defined.
ClassMethod IsPropertySearchable(class As %String, prop As %String) As %Boolean [ Internal, ProcedureBlock = 1 ]
{
	// used by Wizard
	Set class=$$$NormalizeClassname(class)
	
	; loop over indices- see if there is one for us
	Set search=""
	Set c=1
	Set i=$$$comMemberNext(class,$$$cCLASSindex,"")
	While (i'="")&(search="") {
		Set type=$$$comMemberKeyGet(class,$$$cCLASSindex,i,$$$cINDEXtype)
		If (type="index") || (type="bitmap") {
			Set p=$$$comMemberKeyGet(class,$$$cCLASSindex,i,$$$cINDEXproperties)
			For j=1:1:$length(p,",") {
				If $piece($piece(p,",",j),":")=prop Set search=1 Quit
			}
		}
		Set i=$$$comMemberNext(class,$$$cCLASSindex,i)
	}
	
	Set:search="" search=0
	QUIT search
}

/// Return the value of the MAXLEN parameter (or "" if not defined) for 
/// property <VAR>prop</VAR> of class <VAR>class</VAR>.
ClassMethod GetPropertyMaxLen(class As %String, prop As %String) As %String [ CodeMode = expression, Internal ]
{
$$$comMemberArrayGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPparameter,"MAXLEN")
}

/// Return a string indicating whether  
/// property <VAR>prop</VAR> of class <VAR>class</VAR> is a collection.
ClassMethod GetPropertyCollection(class As %String, prop As %String) As %String [ CodeMode = expression, Internal ]
{
$$$comMemberKeyGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPcollection)
}

/// Return a string containing the caption for 
/// property <VAR>prop</VAR> of class <VAR>class</VAR>.
ClassMethod GetPropertyCaption(class As %String, prop As %String) As %String [ CodeMode = expression, Internal ]
{
$$$comMemberArrayGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPparameter,"CAPTION")
}

/// Return a string containing value of parameter <var>param</var> for 
/// property <VAR>prop</VAR> of class <VAR>class</VAR>.
ClassMethod GetPropertyParam(class As %String, prop As %String, param As %String) As %String [ CodeMode = expression, Internal ]
{
$$$comMemberArrayGet($$$NormalizeClassname(class),$$$cCLASSproperty,prop,$$$cPROPparameter,param)
}

}
