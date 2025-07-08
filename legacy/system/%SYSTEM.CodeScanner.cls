/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used to scan user code looking for references to deprecated functionality.
Class %SYSTEM.CodeScanner Extends %SYSTEM.Help
{

Parameter DOMAIN = "%Utility";

/// Create a row in the PPG.
ClassMethod AddRow(idx As %Integer, doc As %String, location As %String, message As %String) [ Internal, Private ]
{
    Set ^||%DeprecatedList(idx,$INCREMENT(^||%DeprecatedList(idx))) = $LISTBUILD(doc,location,message)
}

/// Create a row that reports <code>cls</code> as deprecated.
ClassMethod ReportClassDeprecated(idx As %Integer, doc As %String, location As %String, cls As %String) [ Internal, Private ]
{
    Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("Class '%1' is deprecated."),cls))
}

/// Normalize <code>cls</code> using <code>imports</code> and create a row if it's deprecated.
/// Create a row with the error text if the normalization fails.
/// Returns the normalized class name, or the empty string if normalization failed.
ClassMethod NormalizeClassAndReport(idx As %Integer, doc As %String, location As %String, cls As %String, ByRef imports) As %String [ Internal, Private ]
{
    If '$ZNAME(cls,4) Return "" ##; Don't attempt to normalize something that's not a class name
    Set sc = $$NormalizeClassnameByImports^%occName(.norm,cls,.imports)
    If $$$ISERR(sc) {
        Do ..AddRow(idx,doc,location,$SYSTEM.Status.GetOneStatusText(sc))
        Set norm = ""
    } ElseIf $$$defClassKeyGet(norm,$$$cCLASSdeprecated) {
        Do ..ReportClassDeprecated(idx,doc,location,norm)
    }
    Return norm
}

/// Search <code>line</code> of ObjectScript for references to deprecated functions.
ClassMethod CheckLine(idx As %Integer, line As %String, doc As %String, docType As %Integer, location As %String, ByRef imports, ByRef zuFns, ByRef vars) [ Internal, Private ]
{
    If $ZSTRIP(line,"*CW") = "" Quit ##; Blank line
    If docType '= 1 { ##; INT routines can't have MPP directives
        #; Strip leading whitespace and normalize the rest
        Set lineNoWs = $TRANSLATE($ZSTRIP(line,"<W"),$CHAR(9,160),"  ")
        #; Check if this is a #import line
        If $ZCONVERT($EXTRACT(lineNoWs,1,7),"l") = "#import" {
            #; Directive must be followed by whitespace
            If $EXTRACT(lineNoWs,8) '= " " Quit
            Set pkgs = $ZSTRIP($EXTRACT(lineNoWs,8,*),"*CW")
            For j=1:1:$LENGTH(pkgs,",") {
                Set pkg = $PIECE(pkgs,",",j)
                If $ZNAME(pkg,4) {
                    If docType = 0 {
                        #; imports in MAC routines are stored as a subscripted array
                        Set imports($PIECE(pkgs,",",j)) = ""
                    } Else {
                        #; imports in classes are stored as a $LIST
                        Set imports = imports_$LISTBUILD(pkgs)
                    }
                }
            }
            #; There can't be any other matches on this line
            Quit
        }
        #; Check if this is a #dim line
        If $ZCONVERT($EXTRACT(lineNoWs,1,4),"l") = "#dim" {
            #; Directive must be followed by whitespace
            If $EXTRACT(lineNoWs,5) '= " " Quit
            Set varsAndDec = $ZSTRIP($EXTRACT($PIECE(lineNoWs,"="),5,*),"<=>W")
            If $PIECE(varsAndDec,",",*)[" " {
                Set cls = ..NormalizeClassAndReport(idx,doc,location,$PIECE(varsAndDec," ",*),.imports)
                If cls '= "" {
                    #; Record the declared type of the variables
                    Set dimVars = $ZSTRIP($EXTRACT(varsAndDec,1,$LENGTH($PIECE($ZCONVERT(varsAndDec,"l")," as ",1,*-1))),"*CW")
                    For j=1:1:$LENGTH(dimVars,",") {
                        Set dimVar = $PIECE(dimVars,",",j)
                        If $ZNAME(dimVar) Set vars(dimVar) = cls
                    }
                }
            }
            #; There can't be any other matches on this line
            Quit
        }
        #; Check if this is #sqlcompile mode
        If ($ZCONVERT($EXTRACT(lineNoWs,1,11),"l") = "#sqlcompile") {
            #; Directive must be followed by whitespace and "mode" must follow whitespace
            If $EXTRACT(lineNoWs,12) = " ", $ZCONVERT($EXTRACT($ZSTRIP($EXTRACT(lineNoWs,12,*),"<W"),1,4),"l") = "mode" {
                Do ..AddRow(idx,doc,location,$$$Text("The #sqlcompile mode macro preprocessor directive is deprecated."))
            }
            #; There can't be any other matches on this line
            Quit
        }
    }
    If docType = 0, line["(", $ZNAME($PIECE(line,"("),2) {
        #; This is a label with arguments, so clear our variable type array
        Kill vars
    }
    #Define InStringLiteral ($LENGTH($EXTRACT(line,1,position-1),"""")-1)#2 = 1
    #; Check if there's a comment on this line
    Set commentStart = $$$MaxStringLength, commentTestLine = $TRANSLATE(line,"/;#",$CHAR(0,0,0)), position = 0
    For {
        Set position = $FIND(commentTestLine,$CHAR(0),position)
        If position = 0 Quit
        If $$$InStringLiteral Continue
        Set currentChar = $EXTRACT(line,position), prevChar = $EXTRACT(line,position-1)
        If (
            #; Found a // comment
            ((prevChar = "/") && (currentChar = "/")) ||
            #; Found a ; comment
            (prevChar = ";") ||
            #; Found a #; comment (not in a INT routine)
            ((docType '= 1) && (prevChar = "#") && (currentChar = ";"))
        ) {
            Set commentStart = position + $CASE(prevChar,";":0,:1)
            Quit
        }
    }
    #Define ReportIfMemberDeprecated(%cls,%key) ##Continue
            If $EXTRACT(member) = """", $EXTRACT(member,*) = """" Set member = $REPLACE($EXTRACT(member,2,*-1),"""""","""") ##Continue
            If member '= "", $$$comMemberKeyGet(%cls,%key,member,$$$cXXXXdeprecated) { ##Continue
                Set memStr = $CASE(%key, ##Continue
                    $$$cCLASSmethod:$SELECT( ##Continue
                        $$$comMemberKeyGet(%cls,%key,member,$$$cMETHclassmethod):"Class", ##Continue
                        $$$comMemberKeyGet(%cls,%key,member,$$$cMETHclientmethod):"Client", ##Continue
                        1:"" ##Continue
                    )_"Method", ##Continue
                    $$$cCLASSproperty:$CASE( ##Continue
                        $$$comMemberKeyGet(%cls,%key,member,$$$cPROPrelationship), ##Continue
                        1:"Relationship", ##Continue
                        :"Property" ##Continue
                    ), ##Continue
                    :"Parameter" ##Continue
                ) ##Continue
                Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("%1 in class '%2' is deprecated."),memStr_" '"_member_"'",%cls)) ##Continue
            }
    #Define FindEndOfMember ##Continue
                If $EXTRACT(member) = """" { ##Continue
                    #; Find the closing quote ##Continue
                    For c=2:1:$LENGTH(member) { ##Continue
                        If $EXTRACT(member,c) = """", $EXTRACT(member,c-1) '= """", $EXTRACT(member,c+1) '= """" { ##Continue
                            Set endChar = $EXTRACT(member,c+1), $EXTRACT(member,c+1,*) = "" Quit ##Continue
                        } ##Continue
                    } ##Continue
                } Else { ##Continue
                    #; Find the end of the member reference ##Continue
                    For c=1:1:$LENGTH(member) { ##Continue
                        If '$ZNAME($EXTRACT(member,1,c),5) { ##Continue
                            Set endChar = $EXTRACT(member,c), $EXTRACT(member,c,*) = "" Quit ##Continue
                        } ##Continue
                    } ##Continue
                }
    Set lineLower = $ZCONVERT(line,"l"), position = 0
    #; Find instances of ##class() on this line
    For {
        Set position = $FIND(lineLower,"##class(",position)
        If (position = 0) || (position > commentStart) Quit
        If $$$InStringLiteral Continue
        Set ppCls = $PIECE($EXTRACT(line,position,*),")")
        If $EXTRACT(ppCls) = """", $EXTRACT(ppCls,*) = """" Set ppCls = $EXTRACT(ppCls,2,*-1)
        If docType = 1 {
            #; No imports in INT routines
            If $ZNAME(ppCls,4) {
                Set norm = $$$NormalizeClassname(ppCls)
                If $$$defClassKeyGet(norm,$$$cCLASSdeprecated) Do ..ReportClassDeprecated(idx,doc,location,norm)
            } Else {
                Set norm = ""
            }
        } Else {
            Set norm = ..NormalizeClassAndReport(idx,doc,location,ppCls,.imports)
        }
        If norm '= "" {
            #; Check if this method or parameter is deprecated
            Set member = $PIECE($PIECE($PIECE($EXTRACT(line,position,*),")",2,*),".",2,*),"(")
            If $EXTRACT(member) = "#" {
                Set $EXTRACT(member) = ""
                $$$FindEndOfMember
                $$$ReportIfMemberDeprecated(norm,$$$cCLASSparameter)
            } Else {
                $$$ReportIfMemberDeprecated(norm,$$$cCLASSmethod)
            }
        }
    }
    #; Find instances of $system.class on this line
    Set position = 0
    For {
        Set position = $FIND(lineLower,"$system.",position)
        If (position = 0) || (position > commentStart) Quit
        If $$$InStringLiteral Continue
        Set firstParen = $FIND(line,"(",position)
        If 'firstParen Quit
        Set cls = "%SYSTEM."_$PIECE($EXTRACT(line,position,firstParen-1),".",1,*-1)
        If $ZNAME(cls,4) {
            If $$$defClassKeyGet(cls,$$$cCLASSdeprecated) Do ..ReportClassDeprecated(idx,doc,location,cls)
            #; Check if the called method is deprecated
            Set member = $EXTRACT(line,position+$LENGTH(cls)-7,firstParen-2)
            $$$ReportIfMemberDeprecated(cls,$$$cCLASSmethod)
        }
    }
    If docType = 4 { ##; Class
        Set cls = $PIECE(doc,".",1,*-1)
        #; Find instaces of relative dot, $this., or i%var syntax on this line
        For syn="..","$this.","i%" {
            Set position = 0
            For {
                Set position = $FIND(lineLower,syn,position)
                If (position = 0) || (position > commentStart) Quit
                If $$$InStringLiteral Continue
                Set member = $EXTRACT(line,position,*)
                If syn = "..", $EXTRACT(member) = "." Continue ##; Variable parameter syntax
                #; Find the member name and termination character
                Set memberType = $$$cCLASSproperty, endChar = ""
                If $EXTRACT(member) = "#" {
                    If syn = "i%" Continue ##; i%var can only be a property
                    Set $EXTRACT(member) = "", memberType = $$$cCLASSparameter
                }
                $$$FindEndOfMember
                If endChar = "(", syn '= "i%" Set memberType = $$$cCLASSmethod
                $$$ReportIfMemberDeprecated(cls,memberType)
            }
        }
    }
    If docType '= 1 { ##; INT routines can't have type declarations
        #; Find references to members of variables with known types on this line
        Set var = ""
        For {
            Set var = $ORDER(vars(var),1,cls)
            If var = "" Quit
            Set varTest = var_".", position = 0
            For {
                Set position = $FIND(line,varTest,position)
                If (position = 0) || (position > commentStart) Quit
                If $$$InStringLiteral Continue
                Set prevChar = $EXTRACT(line,position-$LENGTH(varTest)-1)
                #; Check if this variable reference is "complete".
                #; For example, if we're looking for variable "bc"
                #; and there's another variable "abc", we don't want
                #; to treat "a|bc." as a valid match.
                If $ZNAME(prevChar,5) || ("0123456789"[prevChar) Continue
                Set member = $EXTRACT(line,position,*), memberType = $$$cCLASSproperty, endChar = ""
                If $EXTRACT(member) = "#" Set $EXTRACT(member) = "", memberType = $$$cCLASSparameter
                $$$FindEndOfMember
                If endChar = "(" Set memberType = $$$cCLASSmethod
                $$$ReportIfMemberDeprecated(cls,memberType)
            }
        }
    }
    #UnDef FindEndOfMember
    #UnDef ReportIfMemberDeprecated
    #; Find instances of $zobj functions on this line
    For fn="class","classmethod","method","property","val","mod","ref","new","cnt" {
        Set fnTest = "$zobj"_fn_"(", fnMsg = $ZCONVERT(fnTest,"U")_")", position = 0
        For {
            Set position = $FIND(lineLower,fnTest,position)
            If (position = 0) || (position > commentStart) Quit
            If $$$InStringLiteral Continue
            Do ..AddRow(idx,doc,location,$CASE(";val;mod;ref;new;cnt;"[(";"_fn_";"),
                #; Internal fuction
                1:$$$FormatText($$$Text("System function '%1' is not supported in user code."),fnMsg),
                #; Deprecated function
                :$$$FormatText($$$Text("System function '%1' should be replaced with '%2'."),fnMsg,"$"_$EXTRACT(fnMsg,6,*-2)_$CASE(fn="class",1:"NAME",:"")_"()")
            ))
        }
    }
    #; Find instances of %this on this line
    Set position = 0
    For {
        Set position = $FIND(line,"%this",position)
        If (position = 0) || (position > commentStart) Quit
        If $$$InStringLiteral Continue
        Do ..AddRow(idx,doc,location,$$$Text("Use of '%this' to reference the current object instance context is deprecated. Use system variable '$THIS' instead."))
    }
    #; Find instances of $zf(-1) or $zf(-2) on this line
    Set position = 0
    For {
        Set position = $FIND(lineLower,"$zf(",position)
        If (position = 0) || (position > commentStart) Quit
        If $$$InStringLiteral Continue
        Set zfFirstArg = $ZSTRIP($PIECE($EXTRACT(line,position,*),","),"*CW")
        If ";-1;-2;"[(";"_zfFirstArg_";") {
            Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("System function '%1' should be replaced with '%2'."),"$ZF("_zfFirstArg_")","$ZF(-100)"))
        }
    }
    #; Find instances of deprecated $zu(til) functions on this line
    #Define BeautifyZuFn "$ZUTIL("_zuFn_$CASE($EXTRACT(zuFn,*),",":"...)",:"")
    Set position = 0
    For {
        Set position = $FIND(lineLower,"$zu",position)
        If (position = 0) || (position > commentStart) Quit
        If $$$InStringLiteral Continue
        If $EXTRACT(lineLower,position,position+2) = "til" Set position = position + 3
        If $EXTRACT(line,position) '= "(" Continue
        Set zuArgs = $ZSTRIP($PIECE($EXTRACT(line,position+1,*),")"),"*CW")
        Set zuFn = $SELECT(
            (";68,27,;68,39,;68,55,;69,13,;69,14,;69,19,;69,20,;69,27,;69,28,;69,31,;69,35,;69,39,;69,55,;69,67,;78,28,;"[(";"_$EXTRACT(zuArgs,1,6)_";")):$EXTRACT(zuArgs,1,6),
            (";67,1,;68,6,;69,6,;90,4,;"[(";"_$EXTRACT(zuArgs,1,5)_";")):$EXTRACT(zuArgs,1,5),
            (";100);113);130,;133,;"[(";"_$EXTRACT(zuArgs,1,4)_";")):$EXTRACT(zuArgs,1,4),
            1:""
        )
        If zuFn '= "" {
            Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("System function '%1' is obsolete and its continued use is discouraged."),$$$BeautifyZuFn))
            Continue
        }
        For argLen=6:-1:2 {
            Set zuFn = $EXTRACT(zuArgs,1,argLen)
            If $DATA(zuFns(zuFn),zuRep) {
                If zuRep '= "" {
                    #; Convert to a valid ObjectScript expression
                    Set zuRepCls = $PIECE(zuRep,"_"), zuRepMeth = $PIECE(zuRep,"_",2,*)_"()", zuRepExpr = $CASE(
                        $EXTRACT(zuRep,1,8)="%SYSTEM.",
                        1:"$"_$EXTRACT(zuRepCls,2,*)_"."_zuRepMeth,
                        :"##class("_zuRepCls_")."_zuRepMeth
                    )
                    Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("System function '%1' should be replaced with '%2'."),$$$BeautifyZuFn,zuRepExpr))
                } Else {
                    Do ..AddRow(idx,doc,location,$$$FormatText($$$Text("System function '%1' has been superseded."),$$$BeautifyZuFn))
                }
                Quit
            }
        }
    }
    #UnDef InStringLiteral
    #UnDef BeautifyZuFn
}

/// Output a subscripted array of deprecated <code>$ZUTIL</code> functions and their replacements.
/// Functions taken from <a href="https://github.com/intersystems/language-server/blob/42eb61fe90f9260dcdb08b87f28edbc7af3ecf77/server/src/utils/variables.ts#L64">InterSystems Language Server</a> VS Code extension.
ClassMethod SetUpZuFns(Output zuFns As %String) [ Internal, Private ]
{
    #; Functions that can be easily replaced with ClassMethods
    Set zuFns("4,") = "%SYSTEM.Process_Terminate", zuFns("18,") = "%SYSTEM.Process_Undefined",
        zuFns("18)") = "%SYSTEM.Process_Undefined", zuFns("20,") = "%SYSTEM.Process_UserRoutinePath",
        zuFns("20)") = "%SYSTEM.Process_UserRoutinePath", zuFns("21)") = "%SYSTEM.Process_PrivateGlobalLocation",
        zuFns("21,0)") = "%SYSTEM.Process_PrivateGlobalLocation", zuFns("21,1)") = "%SYSTEM.Process_KillAllPrivateGlobals",
        zuFns("21,2)") = "%SYSTEM.Process_KillAllPrivateGlobals", zuFns("22,0,") = "%Device_SetFFBS",
        zuFns("22,0)") = "%Device_SetFFBS", zuFns("28,") = "%SYSTEM.Util_Collation",
        zuFns("39,") = "%SYSTEM.Process_SysRoutinePath", zuFns("39)") = "%SYSTEM.Process_SysRoutinePath",
        zuFns("53)") = "%SYSTEM.INetInfo_TCPName", zuFns("53,") = "%SYSTEM.INetInfo_TCPStats",
        zuFns("55,") = "%SYSTEM.Process_LanguageMode", zuFns("55)") = "%SYSTEM.Process_LanguageMode",
        zuFns("56,2)") = "%SYSTEM.Process_ErrorLine", zuFns("56,6)") = "%SYSTEM.Process_OSError",
        zuFns("67,0,") = "%SYSTEM.Process_IsGhost", zuFns("67,4,") = "%SYSTEM.Process_State",
        zuFns("67,5,") = "%SYSTEM.Process_Routine", zuFns("67,6,") = "%SYSTEM.Process_NameSpace",
        zuFns("67,7,") = "%SYSTEM.Process_CurrentDevice", zuFns("67,8,") = "%SYSTEM.Process_LinesExecuted",
        zuFns("67,5)") = "%SYSTEM.Process_Routine", zuFns("67,6)") = "%SYSTEM.Process_NameSpace",
        zuFns("67,7)") = "%SYSTEM.Process_CurrentDevice", zuFns("67,8)") = "%SYSTEM.Process_LinesExecuted",
        zuFns("67,9,") = "%SYSTEM.Process_GlobalReferences", zuFns("67,10,") = "%SYSTEM.Process_JobType",
        zuFns("67,11,") = "%SYSTEM.Process_UserName", zuFns("67,12,") = "%SYSTEM.Process_ClientNodeName",
        zuFns("67,13,") = "%SYSTEM.Process_ClientExecutableName", zuFns("67,14,") = "%SYSTEM.Process_CSPSessionID",
        zuFns("67,15,") = "%SYSTEM.Process_ClientIPAddress", zuFns("67,9)") = "%SYSTEM.Process_GlobalReferences",
        zuFns("67,10)") = "%SYSTEM.Process_JobType", zuFns("67,11)") = "%SYSTEM.Process_UserName",
        zuFns("67,12)") = "%SYSTEM.Process_ClientNodeName", zuFns("67,13)") = "%SYSTEM.Process_ClientExecutableName",
        zuFns("67,14)") = "%SYSTEM.Process_CSPSessionID", zuFns("67,15)") = "%SYSTEM.Process_ClientIPAddress",
        zuFns("71,") = "%SYSTEM.Process_FixedDate", zuFns("71)") = "%SYSTEM.Process_FixedDate",
        zuFns("78,23,") = "%SYS.Journal.File_PurgeOne", zuFns("78,29)") = "%SYS.Journal.System_Sync",
        zuFns("78,40)") = "%SYS.Journal.System_WhereCommitted", zuFns("82,12,") = "%Device_ReDirectIO",
        zuFns("82,12)") = "%Device_ReDirectIO", zuFns("90,10,") = "%SYS.Namespace_Exists",
        zuFns("94,") = "%SYSTEM.Process_Broadcast", zuFns("96,3,") = "%SYSTEM.Process_ThrowError",
        zuFns("96,4,") = "%SYSTEM.Process_IODollarTest", zuFns("96,9)") = "%SYSTEM.Process_CallingRoutine",
        zuFns("96,10)") = "%SYSTEM.Process_CallingDatabase", zuFns("96,14)") = "%Device_GetType",
        zuFns("110)") = "%SYS.System_GetNodeName", zuFns("114,") = "%SYSTEM.INetInfo_EthernetAddress",
        zuFns("128,1)") = "%SYSTEM.Process_StepInfo", zuFns("132)") = "%Device_ChangePrincipal",
        zuFns("140,7,") = "%File_Attributes", zuFns("147,") = "%File_NormalizeFilenameWithSpaces",
        zuFns("158,0)") = "%Device_InstalledPrinters", zuFns("158,1,") = "%Device_InstalledPrinters",
        zuFns("168,") = "%SYSTEM.Process_CurrentDirectory", zuFns("168)") = "%SYSTEM.Process_CurrentDirectory",
        zuFns("186,") = "%SYSTEM.Process_TerminalPrompt", zuFns("186)") = "%SYSTEM.Process_TerminalPrompt",
        zuFns("189)") = "%SYSTEM.INetInfo_Connected", zuFns("68,1,") = "%SYSTEM.Process_NullSubscripts",
        zuFns("68,1)") = "%SYSTEM.Process_NullSubscripts", zuFns("68,2,") = "%SYSTEM.Process_OpenMode",
        zuFns("68,2)") = "%SYSTEM.Process_OpenMode", zuFns("68,3,") = "%SYSTEM.Process_FileMode",
        zuFns("68,3)") = "%SYSTEM.Process_FileMode", zuFns("68,5,") = "%SYSTEM.Process_BreakMode",
        zuFns("68,5)") = "%SYSTEM.Process_BreakMode", zuFns("68,7,") = "%SYSTEM.Process_RefInKind",
        zuFns("68,7)") = "%SYSTEM.Process_RefInKind", zuFns("68,11,") = "%SYSTEM.Process_LineRecall",
        zuFns("68,11)") = "%SYSTEM.Process_LineRecall", zuFns("68,15,") = "%SYSTEM.Process_DisconnectErr",
        zuFns("68,15)") = "%SYSTEM.Process_DisconnectErr", zuFns("68,21,") = "%SYSTEM.Process_SynchCommit",
        zuFns("68,21)") = "%SYSTEM.Process_SynchCommit", zuFns("68,22,") = "%SYSTEM.Process_DX",
        zuFns("68,22)") = "%SYSTEM.Process_DX", zuFns("68,25,") = "%SYSTEM.Process_BatchFlag",
        zuFns("68,25)") = "%SYSTEM.Process_BatchFlag", zuFns("68,28,") = "%SYSTEM.Process_GlobalKillDisabled",
        zuFns("68,28)") = "%SYSTEM.Process_GlobalKillDisabled", zuFns("68,30,") = "%SYSTEM.Process_PopError",
        zuFns("68,30)") = "%SYSTEM.Process_PopError", zuFns("68,32,") = "%SYSTEM.Process_ZDateNull",
        zuFns("68,32)") = "%SYSTEM.Process_ZDateNull", zuFns("68,34,") = "%SYSTEM.Process_AsynchError",
        zuFns("68,34)") = "%SYSTEM.Process_AsynchError", zuFns("68,40,") = "%SYSTEM.Process_SetZEOF",
        zuFns("68,40)") = "%SYSTEM.Process_SetZEOF", zuFns("68,42,") = "%SYSTEM.Process_NodeNameInPid",
        zuFns("68,42)") = "%SYSTEM.Process_NodeNameInPid", zuFns("68,43,") = "%SYSTEM.Process_OldZU5",
        zuFns("68,43)") = "%SYSTEM.Process_OldZU5", zuFns("68,45,") = "%SYSTEM.Process_TruncateOverflow",
        zuFns("68,45)") = "%SYSTEM.Process_TruncateOverflow", zuFns("68,51,") = "%SYSTEM.Process_SwitchOSdir",
        zuFns("68,51)") = "%SYSTEM.Process_SwitchOSdir", zuFns("68,60,") = "%SYSTEM.Process_AsyncDisconnectErr",
        zuFns("68,60)") = "%SYSTEM.Process_AsyncDisconnectErr", zuFns("68,63,") = "%SYSTEM.Process_ScientificNotation",
        zuFns("68,63)") = "%SYSTEM.Process_ScientificNotation", zuFns("68,66,") = "%SYSTEM.Process_TelnetNUL",
        zuFns("68,66)") = "%SYSTEM.Process_TelnetNUL", zuFns("68,67,") = "%SYSTEM.Process_ExceptionLog",
        zuFns("68,67)") = "%SYSTEM.Process_ExceptionLog", zuFns("68,70,") = "%SYSTEM.Process_IEEEError",
        zuFns("68,70)") = "%SYSTEM.Process_IEEEError", zuFns("68,71,") = "%SYSTEM.Process_IPv6Format",
        zuFns("68,71)") = "%SYSTEM.Process_IPv6Format", zuFns("68,72,") = "%SYSTEM.Process_MVUndefined",
        zuFns("68,72)") = "%SYSTEM.Process_MVUndefined",
    #; Functions that can't be easily replaced
        zuFns("5,") = "", zuFns("9,") = "", zuFns("12,") = "",
        zuFns("15,") = "", zuFns("49,") = "", zuFns("62,") = "",
        zuFns("67,0)") = "", zuFns("67,4)") = "", zuFns("78,21)") = "",
        zuFns("86)") = "", zuFns("78,22,") = "", zuFns("96,5,") = "",
        zuFns("115,11,") = "", zuFns("140,1,") = "", zuFns("188)") = "",
        zuFns("193,") = "", zuFns("69,0,") = "", zuFns("69,1,") = "",
        zuFns("69,2,") = "", zuFns("69,3,") = "", zuFns("69,5,") = "",
        zuFns("69,7,") = "", zuFns("69,8,") = "", zuFns("69,10,") = "",
        zuFns("69,11,") = "", zuFns("69,15,") = "", zuFns("69,21,") = "",
        zuFns("69,22,") = "", zuFns("69,26,") = "", zuFns("69,30,") = "",
        zuFns("69,32,") = "", zuFns("69,34,") = "", zuFns("69,37,") = "",
        zuFns("69,40,") = "", zuFns("69,42,") = "", zuFns("69,43,") = "",
        zuFns("69,44,") = "", zuFns("69,45,") = "", zuFns("69,49,") = "",
        zuFns("69,51,") = "", zuFns("69,60,") = "", zuFns("69,63,") = "",
        zuFns("69,66,") = "", zuFns("69,68,") = "", zuFns("69,69,") = "",
        zuFns("69,70,") = "", zuFns("69,71,") = "", zuFns("69,72,") = "",
        zuFns("68,26,") = "", zuFns("68,26)") = ""
}

/// Scan user-defined classes and routines in this namespace for references to classes and system functions that have been deprecated or should be replaced.<p>
/// ObjectScript code in the routine body, Property <code>SqlComputeCode</code>, and Method and Trigger implementations with <code>Language = objectscript</code>
/// is scanned. Classes defined with the <code>Deprecated</code> keyword will not be scanned. The <b>mapped</b> argument controls whether documents mapped from
/// a non-default database are scanned. By default, only documents in the default database will be scanned.<p> 
/// The query returns:
/// <ul>
/// <li> <b>Document</b> - The name of the document, including the file extension.
/// <li> <b>Location</b> - A line number or class keyword describing where the deprecated reference is located in <b>Document</b>.
/// <li> <b>Message</b> - A string describing the deprecated reference at <b>Location</b> in <b>Document</b>.
/// </ul>
/// A row will be returned if the following code structures are encountered:
/// <ul>
/// <li> A class defined with the <code>Deprecated</code> keyword that is:
/// <ul>
/// <li> Referenced in ObjectScript code using <code>##class()</code> or <code>$SYSTEM.class.method()</code> syntax.
/// <li> In the superclass, <code>CompileAfter</code>, <code>DependsOn</code>, or <code>PropertyClass</code> list of a class definition.
/// <li> Defined as the type of an argument in a Method or class Query's argument list.
/// <li> Defined as the return type of a Method.
/// <li> Defined as the type of a Property or class Query.
/// </ul>
/// <li> A Method defined with the <code>Deprecated</code> keyword that is referenced using:
/// <ul>
/// <li> <code>##class().method()</code> syntax.
/// <li> <code>$SYSTEM.class.method()</code> syntax.
/// <li> <code>variable.method()</code> syntax, where <code>variable</code> is a method argument defined with a type
/// or a local variable with a type declared using <code>#Dim</code>.
/// <li> <code>$THIS.method()</code> syntax, when in a class definition.
/// <li> Relative dot (<code>..method()</code>) syntax, when in a class definition.
/// </ul>
/// <li> A Property defined with the <code>Deprecated</code> keyword that is referenced using:
/// <ul>
/// <li> <code>variable.property</code> syntax, where <code>variable</code> is a method argument defined with a type
/// or a local variable with a type declared using <code>#Dim</code>.
/// <li> <code>$THIS.property</code> syntax, when in a class definition.
/// <li> Instance variable (<code>i%property</code>) syntax, when in a class definition.
/// </ul>
/// <li> A Parameter defined with the <code>Deprecated</code> keyword that is referenced using:
/// <ul>
/// <li> <code>##class().#parameter</code> syntax.
/// <li> <code>variable.#parameter</code> syntax, where <code>variable</code> is a method argument defined with a type
/// or a local variable with a type declared using <code>#Dim</code>.
/// <li> <code>$THIS.#parameter</code> syntax, when in a class definition.
/// <li> Relative dot (<code>..#parameter</code>) syntax, when in a class definition.
/// </ul>
/// <li> A <code>$ZUTIL</code> function listed in the <a href="https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_replacements">$ZUTIL Replacements documentation</a>.
/// <li> A <code>$ZOBJ</code> function that has been <a href="https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN_20101#GCRN_upgrade20101_zobj">replaced with a standard system function</a>.
/// <li> The <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_macros_mpp_lbSQLCompile_Mode">#sqlcompile mode</a> macro preprocessor directive.
/// <li> <code>$ZF(-1)</code> or <code>$ZF(-2)</code>.
/// <li> Class keyword <code>LegacyInstanceContext</code> or a reference to the obsolete <code>%this</code> variable.
/// <li> Property keyword <code>SqlListDelimiter</code> or <code>SqlListType</code>.
/// <li> A Method or Trigger with keyword <code>CodeMode</code> set to 'generator'.
/// <li> A system function that is not supported in user code.
/// <li> A short class name that did not match a class in any of the imported packages.
/// <li> A short class name that matched classes in multiple imported packages and therefore was ambiguous.
/// <li> A Method or class Query argument list that is formatted incorrectly.
/// </ul>
Query ScanDocuments(mapped As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Document:%String(MAXLEN=512),Location:%String,Message:%String") [ SqlName = ScanDocuments, SqlProc ]
{
}

ClassMethod ScanDocumentsExecute(ByRef qHandle As %Binary, mapped As %Boolean = 0) As %Status [ Internal ]
{
    #Dim sc As %Status = $$$OK
    #Dim e As %Exception.AbstractException

    Try {
        If '$SYSTEM.Security.Check("%Development","USE") Set sc = $$$ERROR($$$NoDevloperPriv) Quit
        #; Reserve a subscript in the PPG for this call
        Set idx = $INCREMENT(^||%DeprecatedList)
        #; Get an array of documents to scan
        Set sodIdx = "", sc = ##class(%RoutineMgr).StudioOpenDialogExecute(.qh,"*.cls,*.mac,*.int",1,1,0,1,0,0,"",0,mapped)
        If $$$ISERR(sc) Quit
        #; Create the array of deprecated $ZUTIL functions
        Do ..SetUpZuFns(.zuFns)
        #; Determine if we should skip system code
        Set skipSystem = (","_$ROLES_",")'[",ISC_Internal,", (nsIsSys, nsIsEns, nsIsHs) = 0
        #; If skipping system code, determine the type of namespace this is
        If skipSystem Set nsIsSys = ($NAMESPACE = "%SYS"), nsIsEns = ##class(%EnsembleMgr).IsEnsembleNamespace(), nsIsHs = ##class(%EnsembleMgr).IsHealthShareNamespace()
        Set sodIdx = $LIST(qh), docId = ""
        For {
            Set docId = $ORDER(^||%RoutineList(sodIdx,1,docId),1,docData)
            If docId = "" Quit
            Set docNameExt = $LIST(docData), docName = $PIECE(docNameExt,".",1,*-1), docType = $LIST(docData,3)
            #; Skip this document if it's system code
            #; Source: https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_appx_identifiers#RCOS_appx_identifiers_class_avoid
            If (
                #; Only percent documents that start with Z or z are user-created (except for %ZEN and %ZHS*)
                (($EXTRACT(docName) = "%") && (
                    ("Zz"'[$EXTRACT(docName,2)) ||
                    ($EXTRACT(docName,1,5) = "%ZEN.") ||
                    ($EXTRACT(docName,1,4) = "%ZHS")
                )) ||
                #; The IRIS and INFORMATION packages are reserved for system code in all namespaces
                (($EXTRACT(docName,1,5) = "IRIS.") || ($EXTRACT(docName,1,12) = "INFORMATION.")) ||
                #; Only Z or z non-percent documents are user-created in %SYS
                (skipSystem && nsIsSys && ($EXTRACT(docName) '= "%") && ("Zz"'[$EXTRACT(docName))) ||
                #; In Interoperability namespaces, packages that start with Ens and the CSPX package are reserved for system code
                (skipSystem && nsIsEns && (
                    ($EXTRACT(docName,1,3) = "Ens") ||
                    ($EXTRACT(docName,1,5) = "CSPX.")
                )) ||
                #; In HealthShare namespaces, packages that start with HS (except HS.Local) and the SchemaMap package are reserved for system code
                (skipSystem && nsIsHs && (
                    (($EXTRACT(docName,1,2) = "HS") && ($EXTRACT(docName,1,9) '= "HS.Local.")) ||
                    ($EXTRACT(docName,1,10) = "SchemaMap.")
                ))
            ) {
                Continue
            }
            Kill imports, vars
            If docType = 0 { ##; MAC
                If '$DATA(^rMAC(docName,0)) Continue
                For i=1:1:$GET(^rMAC(docName,0,0)) {
                    If '$DATA(^rMAC(docName,0,i),line) Continue
                    Do ..CheckLine(idx,line,docNameExt,docType,i,.imports,.zuFns,.vars)
                }
            } ElseIf docType = 1 { ##; INT
                If '$DATA(^ROUTINE(docName,0)) Continue
                For i=1:1:$GET(^ROUTINE(docName,0,0)) {
                    If '$DATA(^ROUTINE(docName,0,i),line) Continue
                    Do ..CheckLine(idx,line,docNameExt,docType,i,.imports,.zuFns,.vars)
                }
            } Else { ##; Class
                If $$$defClassKeyGet(docName,$$$cCLASSdeprecated) {
                    #; Skip classes that are deprecated since the
                    #; user has already declared that they are outdated
                    Continue
                }
                Set utd = $SYSTEM.OBJ.IsUpToDate(docName)
                Kill clsImports
                #; Get a list of packages that this class imports
                Do NormalizeClassnameByDef^%occName(,$PIECE(docName,".",*),docName,.cache)
                Set clsImports = $GET(cache(1,docName))_$LISTBUILD($$$ClassPackageName(docName))
                Kill cache
                #; Check the superclass list, CompileAfter, DependsOn and PropertyClass
                For k=$$$cCLASSsuper,$$$cCLASScompileafter,$$$cCLASSdependson,$$$cCLASSpropertyclass {
                    Set clsList = $CASE(utd,1:$$$comClassKeyGet(docName,k),:$$$defClassKeyGet(docName,k))
                    If clsList = "" Continue
                    Set loc = $CASE(k,
                        $$$cCLASSsuper:"Super",
                        $$$cCLASScompileafter:"CompileAfter",
                        $$$cCLASSdependson:"DependsOn",
                        :"PropertyClass"
                    )
                    For j=1:1:$LENGTH(clsList,",") {
                        Set cls = $PIECE(clsList,",",j)
                        If ('utd) || (k = $$$cCLASSdependson) { ##; DependsOn doesn't appear in ^oddCOM
                            Do ..NormalizeClassAndReport(idx,docNameExt,loc,cls,.clsImports)
                        } ElseIf $$$defClassKeyGet(cls,$$$cCLASSdeprecated) {
                            Do ..ReportClassDeprecated(idx,docNameExt,loc,cls)
                        }
                    }
                }
                #; Check if LegacyInstanceContext is set
                If $$$defClassKeyGet(docName,$$$cCLASSlegacyinstancecontext) {
                    Do ..AddRow(idx,docNameExt,"LegacyInstanceContext",$$$FormatText($$$Text("%1 keyword %2 is deprecated."),"Class","LegacyInstanceContext"))
                }
                #Define ValidateType(%mem,%key) ##Continue
                    If utd { ##Continue
                        #; The class compiler already normalized the type class ##Continue
                        Set type = $$$comMemberKeyGet(docName,%mem,member,%key) ##Continue
                        If type '= "", $$$defClassKeyGet(type,$$$cCLASSdeprecated) Do ..ReportClassDeprecated(idx,docNameExt,prefix_" Type",type) ##Continue
                    } Else { ##Continue
                        Set type = $$$defMemberKeyGet(docName,%mem,member,%key) ##Continue
                        If type '= "" Do ..NormalizeClassAndReport(idx,docNameExt,prefix_" Type",type,.clsImports) ##Continue
                    }
                #Define ValidateFormalSpec(%mem,%keyCom,%keyDef) ##Continue
                    If utd { ##Continue
                        #; The class compiler already parsed the argument list ##Continue
                        Set argsList = $$$comMemberKeyGet(docName,%mem,member,%keyCom), ptr = 0 ##Continue
                        While $LISTNEXT(argsList,ptr,arg) { ##Continue
                            If $LISTGET(arg,2) '= "" { ##Continue
                                If $$$defClassKeyGet($LIST(arg,2),$$$cCLASSdeprecated) { ##Continue
                                    Do ..ReportClassDeprecated(idx,docNameExt,prefix_" Argument List",$LIST(arg,2)) ##Continue
                                } ##Continue
                                Set vars($LIST(arg)) = $LIST(arg,2) ##Continue
                            } ##Continue
                        } ##Continue
                    } Else { ##Continue
                        #; Parse the argument list ##Continue
                        Kill argsArr ##Continue
                        Set sc = $$parseFormal^%occName($PIECE(prefix," "),member,$$$defMemberKeyGet(docName,%mem,member,%keyDef),.argsArr) ##Continue
                        If $$$ISERR(sc) { ##Continue
                            Do ..AddRow(idx,docNameExt,prefix_" Argument List",$SYSTEM.Status.GetOneStatusText(sc)) ##Continue
                            Set sc = $$$OK ##Continue
                        } Else { ##Continue
                            Set arg = "" ##Continue
                            For { ##Continue
                                Set arg = $ORDER(argsArr(arg)) ##Continue
                                If arg = "" Quit ##Continue
                                If $GET(argsArr(arg,2)) '= "" { ##Continue
                                    Set norm = ..NormalizeClassAndReport(idx,docNameExt,prefix_" Argument List",argsArr(arg,2),.clsImports) ##Continue
                                    If norm '= "" Set vars(argsArr(arg)) = norm ##Continue
                                } ##Continue
                            } ##Continue
                        } ##Continue
                    }
                #; Check property types and SQLComputeCodes
                Set member = ""
                For {
                    Set member = $ORDER(^oddDEF(docName,$$$cCLASSproperty,member))
                    If member = "" Quit
                    Set prefix = $CASE(
                        $$$defMemberKeyGet(docName,$$$cCLASSproperty,member,$$$cPROPrelationship),
                        1:"Relationship",
                        :"Property"
                    )_" "_member
                    $$$ValidateType($$$cCLASSproperty,$$$cPROPtype)
                    #; Check if SqlListDelimiter or SqlListType is set
                    For key=$$$cPROPsqllistdelimiter,$$$cPROPsqllisttype {
                        If $$$defMemberKeyDefined(docName,$$$cCLASSproperty,member,key) {
                            Set keyStr = $CASE(key,$$$cPROPsqllistdelimiter:"SqlListDelimiter",:"SqlListType")
                            Do ..AddRow(idx,docNameExt,prefix_" "_keyStr,$$$FormatText($$$Text("%1 keyword %2 is deprecated."),"Property",keyStr))
                        }
                    }
                    Kill vars
                    Set impl = $$$defMemberKeyGet(docName,$$$cCLASSproperty,member,$$$cPROPsqlcomputecode), implImports = clsImports
                    For i=1:1:$LENGTH(impl,$CHAR(13,10)) {
                        Do ..CheckLine(idx,$PIECE(impl,$CHAR(13,10),i),docNameExt,docType,prefix_" SqlComputeCode"_$CASE(i-1,0:"",:"+"_(i-1)),.implImports,.zuFns,.vars)
                    }
                    Kill implImports
                }
                #; Check query argument lists and types
                For {
                    Set member = $ORDER(^oddDEF(docName,$$$cCLASSquery,member))
                    If member = "" Quit
                    Set prefix = "Query "_member
                    $$$ValidateType($$$cCLASSquery,$$$cQUERYtype)
                    $$$ValidateFormalSpec($$$cCLASSquery,$$$cQUERYformalspecparsed,$$$cQUERYformalspec)
                }
                #; Check trigger implementations
                For {
                    Set member = $ORDER(^oddDEF(docName,$$$cCLASStrigger,member))
                    If member = "" Quit
                    #; Check if CodeMode is generator
                    If $$$defMemberKeyGet(docName,$$$cCLASStrigger,member,$$$cTRIGGERcodemode) = $$$cTRIGGERCODEMODEGENERATOR {
                        Do ..AddRow(idx,docNameExt,prefix_" CodeMode",$$$Text("CodeMode value 'generator' is deprecated. Use 'objectgenerator' instead."))
                    }
                    If (";"_$$$cTRIGGERLANGUAGENONE_";"_$$$cTRIGGERLANGUAGEOBJECTSCRIPT_";")'[(
                        ";"_$$$defMemberKeyGet(docName,$$$cCLASStrigger,member,$$$cTRIGGERlanguage)_";"
                    ) {
                        #; Language must be ObjectScript
                        Continue
                    }
                    Kill vars
                    Set impl = $$$defMemberKeyGet(docName,$$$cCLASStrigger,member,$$$cTRIGGERcode), implImports = clsImports
                    For i=1:1:$LENGTH(impl,$CHAR(13,10)) {
                        Do ..CheckLine(idx,$PIECE(impl,$CHAR(13,10),i),docNameExt,docType,"Trigger "_member_" Code+"_i,.implImports,.zuFns,.vars)
                    }
                    Kill implImports
                }
                #; Check method argument lists, return types and implementations
                For {
                    Set member = $ORDER(^oddDEF(docName,$$$cCLASSmethod,member))
                    If member = "" Quit
                    Set prefix = $SELECT(
                        $$$defMemberKeyGet(docName,$$$cCLASSmethod,member,$$$cMETHclassmethod):"Class",
                        $$$defMemberKeyGet(docName,$$$cCLASSmethod,member,$$$cMETHclientmethod):"Client",
                        1:""
                    )_"Method "_member
                    Kill vars
                    #; Can't use the macro because method return type doesn't appear in ^oddCOM
                    Set type = $$$defMemberKeyGet(docName,$$$cCLASSmethod,member,$$$cMETHreturntype)
                    If type '= "" Do ..NormalizeClassAndReport(idx,docNameExt,prefix_" Return Type",type,.clsImports)
                    $$$ValidateFormalSpec($$$cCLASSmethod,$$$cMETHformalspecparsed,$$$cMETHformalspec)
                    #; Check if CodeMode is generator
                    If $$$defMemberKeyGet(docName,$$$cCLASSmethod,member,$$$cMETHcodemode) = $$$cMETHCODEMODEGENERATOR {
                        Do ..AddRow(idx,docNameExt,prefix_" CodeMode",$$$Text("CodeMode value 'generator' is deprecated. Use 'objectgenerator' instead."))
                    }
                    If (";"_$$$cMETHLANGUAGENONE_";"_$$$cMETHLANGUAGEOBJECTSCRIPT_";")'[(
                        ";"_$$$defMemberKeyGet(docName,$$$cCLASSmethod,member,$$$cMETHlanguage)_";"
                    ) {
                        #; Language must be ObjectScript
                        Continue
                    }
                    Set implImports = clsImports
                    For i=1:1:$GET(^oddDEF(docName,$$$cCLASSmethod,member,$$$cMETHimplementation),0) {
                        If '$DATA(^oddDEF(docName,$$$cCLASSmethod,member,$$$cMETHimplementation,i),implLine) Continue
                        Do ..CheckLine(idx,implLine,docNameExt,docType,prefix_" Implementation+"_i,.implImports,.zuFns,.vars)
                    }
                    Kill implImports
                }
            }
        }
        #UnDef ValidateFormalSpec
        #UnDef ValidateType
    } Catch e {
        Set sc = e.AsStatus()
    }
    If $$$ISERR(sc) {
        #; Don't leak results if there was an error
        Kill ^||%DeprecatedList(idx)
    } Else {
        Set qHandle = $LISTBUILD(idx,"")
    }
    #; Always clean up the StudioOpenDialog PPG
    If sodIdx '= "" Kill ^||%RoutineList(sodIdx)
    Return sc
}

ClassMethod ScanDocumentsClose(qHandle As %Binary) As %Status [ Internal ]
{
    If $LISTGET(qHandle) '= "" Kill ^||%DeprecatedList($LIST(qHandle))
	Return $$$OK
}

ClassMethod ScanDocumentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
    Set rowId = $ORDER(^||%DeprecatedList($LIST(qHandle),$LIST(qHandle,2)),1,Row)
    If rowId = "" {
        Set AtEnd = 1
    } Else {
        Set AtEnd = 0, $LIST(qHandle,2) = rowId
    }
    Return $$$OK
}

/// Define the list of things to scan for. The format is:<ul>
/// <li>patterns(num)=pattern</li>
/// <li>patterns(num,"case")=case sensitive</li>
/// <li>patterns(num,"version")=version customer will see the problem in</li>
/// <li>patterns(num,"info")=description of the problem</li>
/// <li>patterns(num,"whole")=whole word pattern match</li></ul>
ClassMethod SetupPatterns(ByRef patterns As %String, ByRef info As %String) [ Internal, Private ]
{
	Set patterns(1)="$zobjval(",patterns(1,"case")=0,patterns(1,"version")="2011.2"
	Set patterns(1,"info")="Use of '$zobjval' is not supported. It relies on internal slot number information which has changed so code using this will not function correctly. Replace this useage with i%var to reference the instance variable 'var' which is fully supported in all versions of Cache."
	Set patterns(2)="$zobjmod(",patterns(2,"case")=0,patterns(2,"version")="2011.2"
	Set patterns(2,"info")="Use of '$zobjmod' is not supported. It relies on internal slot number information which has changed so code using this will not function correctly. Replace this useage with ..PropIsModified()/..PropSetModified(val) method calls which are supported in all versions of Cache."
	Set patterns(3)="$$$cIVARslot",patterns(3,"case")=1,patterns(3,"version")="2011.2"
	Set patterns(3,"info")="Use of '$$$cIVARslot' macro is not supported. The macro has been removed as it is no longer used internally so code using this will report an error on compilation. Look at where the slot number was used and remove the use of the slot number, e.g. i%var instead of $zobjval and then remove the code that uses the macro."
	Set patterns(4)="$$$cIVARrefslot",patterns(4,"case")=1,patterns(4,"version")="2011.1"
	Set patterns(4,"info")="Use of '$$$cIVARrefslot' macro is not supported. The macro has been removed as it is no longer used internally so code using this will report an error on compilation. Look at where the refslot number was used and remove the use of the refslot number, e.g. r%var instead of $zobjval and then remove the code that uses the macro."
	Set patterns(5)="%this",patterns(5,"case")=1,patterns(5,"version")="2011.1",patterns(5,"whole")=1
	Set patterns(5,"info")="Use of '%this' to reference the current object instance context is deprecated. There may be some false matches if you happen to have a local variable called %this rather than the case where %this is assumed to be the current oref in an instance method. Since 2010.1 you should use $this system variable which provides the current context in both class methods and instance methods. Code using %this as the instance context will continue to work as old classes automatically have 'LegacyInstanceContext' keyword added to them which makes all instance methods pass a first argument of %this, however removing 'LegacyInstanceContext' will improve the speed of calling instance methods and at some point we will remove this backward compatibility keyword."
	Set patterns=$order(patterns(""),-1)
}

/// This method is <b>deprecated</b>. Use the <QUERY>ScanDocuments</QUERY> class Query instead.<p>
/// Scan all namespaces on this system looking for code that may not work correctly due to use of unsupported features.
/// You can pass an options <var>SearchList</var> argument which is a mask of which documents to search for.
ClassMethod ScanAll(SearchList As %String = "*.*") [ Deprecated ]
{
	Do List^%SYS.NAMESPACE(.nslist,3,0)
	Set ns="" For  Set ns=$Order(nslist(ns)) Quit:ns=""  Do
	. If ns="%SYS"||(ns="ENSLIB")||(ns="DOCBOOK") Quit
	. New $namespace Set $namespace=ns
	. Do ..Scan(SearchList)
	Quit
}

/// This method is <b>deprecated</b>. Use the <QUERY>ScanDocuments</QUERY> class Query instead.<p>
/// Scan this namespace looking for code that may not work correctly due to use of unsupported features.
/// You can pass an options <var>SearchList</var> argument which is a mask of which documents to search for.
ClassMethod Scan(SearchList As %String = "*.*") [ Deprecated ]
{
	New %SourceControl,%text
	Write "Scanning namespace : ",$namespace
	Do ..SetupPatterns(.patterns)
	Set sc=##class(%RoutineMgr).StudioOpenDialogExecute(.QHandle,SearchList,1,1,0,1,,0)
	If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit

	Set idx=$list(QHandle),found=0
	For i=1:1:patterns {
		Set pattern=patterns(i),name=pattern,case=+$get(patterns(i,"case")),whole=+$get(patterns(i,"whole"))
		Set pattern=$select(case:pattern,1:$zconvert(pattern,"l"))
		If pattern["?"||(pattern["*")||(pattern["\")||(whole) {
			Set pattern=##class(%Studio.Project).pattern(pattern,whole,.wild)
		} Else {
			Set wild=0
		}
		Set %text=$char(13,10,13,10)_"Scanning for '"_name_"' which will cause problems in "_patterns(i,"version")_$char(13,10)_patterns(i,"info")_$char(13,10)
		Set item=""
		For {
			Set item=$order(^||%RoutineList(idx,1,item),1,data) Quit:item=""
			If $extract($list(data),1,7)="EnsLib." Continue
			Do ..searchItem(pattern,$list(data),.found,wild,case,99999999,name,whole)
		}
	}
	Kill ^||%RoutineList(idx)
	If found=0 {
		Write !!,"No potential problems found",!!
	} Else {
		Write !!,"Found "_found_" potential issues",!!
	}
}

/// Search this specific items for the string
ClassMethod searchItem(pattern As %String, Name As %String, ByRef Found As %Integer = 0, wild As %Boolean = 0, CaseSensitive As %Boolean = 1, Max As %Integer = 200, Pattern As %String, WholeWords As %Boolean = 0) As %Boolean [ Internal, Private ]
{
#define check(%str,%pat,%case,%wild) $s(%wild:$s('%case:$zcvt(%str,"l"),1:%str)?@%pat,'%case:$zcvt(%str,"l")[%pat,1:%str[%pat) w:%text'="" %text s:%text'="" %text=""
	Set oldFound=Found
	Set name=$piece(Name,".",1,$length(Name,".")-1),type=$zconvert($piece(Name,".",$length(Name,".")),"U")
	If name="" Quit 0
	If Name["/"||(Name["\") {
		Set csp=##class(%CSP.Routine).%New(Name)
		If csp=$$$NULLOREF Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set trail=""
		For lineno=1:1 {
			If csp.AtEnd Quit
			Set eol=0,line=trail_csp.ReadLine(32000,,.eol),trail=""
			If $$$check(line,pattern,CaseSensitive,wild) Write $char(13,10)_Name_"("_lineno_"): "_$zstrip(line,"<W") Set Found=Found+1 If Found'<Max Quit
			If 'eol Set lineno=lineno-1,trail=$extract(line,*-700,*)
		}
	} ElseIf ##class(%RoutineMgr).UserType(Name,.cls) {
		Do $classmethod(cls,"Search",Name,Pattern,WholeWords,CaseSensitive,Max,.Found)
	} ElseIf type="CLS" {
		If '$data(^oddDEF(name)) Quit 0
		Do ..searchClassNode(Name,"^oddDEF("""_name_""")",$$$cROOTclass,name,pattern,.Found,"",CaseSensitive,Max,wild) 
	} ElseIf $$$rtnIsMAC(type) {
		If '$data(^rMAC(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^rMAC(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf $$$rtnIsINT(type) {
		If '$data(^ROUTINE(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^ROUTINE(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf $$$rtnIsINC(type) {
		If '$data(^rINC(name,0)) Quit 0
		If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
		Set l=0 For lineno=1:1:$get(^rINC(name,0,0)) If $data(^(lineno),line),$increment(l),$$$check(line,pattern,CaseSensitive,wild) Do  If Found'<Max Quit
		. Write $char(13,10)_Name_"("_l_"): "_$zstrip(line,"<W") Set Found=Found+1
	} ElseIf type="PRJ" {
		Set prj=##class(%Studio.Project).%OpenId(name)
		If prj'=$$$NULLOREF {
			If $$$check(name,pattern,CaseSensitive,wild) Write $char(13,10)_Name_": "_Name Set Found=Found+1
			Set item="",items=prj.Items
			#; Create list of items in this project.
			Set itemobj=items.GetNext(.item)
			While item'=""&&(Found<Max) {
				If $isobject(itemobj) {
					Set name=itemobj.Name,type=itemobj.Type
					If ..searchItem(Pattern,name_$select(type="CLS":".CLS",1:""),.Found,WholeWords,CaseSensitive,Max)
					Do items.%UnSwizzleAt(item)
				}
				Set itemobj=items.GetNext(.item)
			}
		}
	}
	Quit (oldFound'=Found)
}

/// Search this class for the string
ClassMethod searchClassNode(Name As %String, ref As %String, type As %String, NewName As %String, pattern As %String, ByRef Found As %Integer, Tree As %String, CaseSensitive As %Boolean = 1, Max As %Integer = 200, Wild As %Boolean = 0) [ Internal, Private ]
{
#define check(%str,%pat,%case,%wild) $s(%wild:$s('%case:$zcvt(%str,"l"),1:%str)?@%pat,'%case:$zcvt(%str,"l")[%pat,1:%str[%pat) w:%text'="" %text s:%text'="" %text=""
	Set value="",data=$data(@ref,value)
	#;
	#; Check for 'value' nodes e.g property parameters 
	If 'data Quit
	Set line=$translate(Tree,","," ") If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch If Found'<Max Quit
	Set line=NewName If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch If Found'<Max Quit
	Set line=value If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch If Found'<Max Quit
	If data=1 Quit
	Set key="" For  Set key=$Order(@ref@(key)) Quit:key=""  Do  Quit:Found'<Max
	  #; If this key isn't defined for this tnode type then don't output
	. Set external=$$$tableSubSubToExtGet(type,key) If external=""||(external="Name") Quit
	  #; If the keyword is of type "k", that is, its a keyword with a single value
	. If $extract($$$tableTypeGet(type,key))="k" Do
	    #; If this is the implementation we need to output all the subnodes
	. . If $$$tableMultiLineGet(type,key) Do  Quit
	. . . For lineno=1:1:@ref@(key) Do  Quit:Found'<Max
	. . . . Set line=@ref@(key,lineno)
	. . . . If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch
	. . If $$$check(external,pattern,CaseSensitive,Wild) Set line=@ref@(key) Do outputMatch Quit
	. . Set value=@ref@(key),line=value
	. . If $$$check(line,pattern,CaseSensitive,Wild) Do
	. . . If $length(value,$char(13,10))=1 Do outputMatch Quit
	. . . For lineno=1:1:$length(value,$char(13,10)) Do  Quit:Found'<Max
	. . . . Set line=$piece(value,$char(13,10),lineno)
	. . . . If $$$check(line,pattern,CaseSensitive,Wild) Do outputMatch
	. Else  Do
	. . Set name="" For  Set name=$Order(@ref@(key,name)) Quit:name=""  Do ..searchClassNode(Name,$Extract(ref,1,$Length(ref)-1)_","""_key_""","""_name_""")",key,name,pattern,.Found,Tree_external_","_name_",",CaseSensitive,Max,Wild) Quit:Found'<Max
	Quit
outputMatch Set Found=Found+1,output=$char(13,10)_Name
	If $piece(Tree,",")'="Storage" {
		Set output=output_"("_$piece(Tree,",",2)
		If $get(external)="Implementation" {
			Set output=output_$select($get(lineno)>0:"+"_(lineno),1:"")_")"
		} ElseIf $get(external)="FormalSpec" {
			Write output_"): "_$piece(Tree,",",2)_"(",$zstrip(line,"<W"),")" Quit
		} ElseIf $piece(Tree,",",$length(Tree,",")-2)="Parameter" {
			Set output=output_")" If $length(Tree,",")>4 Set output=output_"["_$piece(Tree,",",$length(Tree,",")-1)_"]"
		} Else {
			Set output=output_")" If $get(external)'="" Set output=output_"["_external_$select($get(lineno)>0:"+"_lineno,1:"")_"]"
		}
	} Else {
		Set output=output_"(Storage)["_$piece(Tree,",",2,*)_$get(external)_"]"
	}
	Write output_": "_$zstrip(line,"<W")
	Quit
}

}
