/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syPrompt

/// Handles prompting for chui applications.
Class %Library.Prompt Extends %SYSTEM.Help [ Abstract, System = 4 ]
{

/// Prompt for a number.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value <br>
/// Min - Minimum value allowed<br>
/// Max - Maximum value allowed<br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$DisableHelpContextResponse - Disable entry of the help context character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
///      - $$$AllowNullMask - Allow null entry
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// $$$HelpContextResponse - Help context character entered if $$$DisableHelpContextCharMask set <br>
/// Value - Entered number<br>
ClassMethod GetNumber(Prompt As %String, ByRef Value As %Integer, Min As %Integer, Max As %Integer, ByRef Help As %String, Flag As %Integer = 0, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 f  {
	w !,Prompt_" " 
	i $d(Value),(+Value=Value) {
		s DefaultString=Value_" "_$$$DefaultPrompt_" "
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i $zb(Flag,$$$TrapCtrlCMask,1) {
	 	i '($v(0,-1,4)\4#2) {
		 	b 1
	 		s SetBreak=1
 		}
	}
	i (Timeout'=0),$d(Value),(+Value=Value) {
		r Number:Timeout s t=$t
		i $d(SetBreak) b 0
		i 't s Number=Value w Number q
	} else {
		r Number
		i $d(SetBreak) b 0
	}
	i (Number=""),$d(Value),(+Value=Value) s Number=Value q
	i (Number=""), $zb(+Flag,$$$AllowNullMask,1) q
	i (Number=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (Number=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help),! Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		Continue
	}
	i ($zcvt(Number,"U")=$$$HelpContextChar) {
		i $zb(+Flag,$$$DisableHelpContextCharMask,1) q
		d HELP Continue
	}
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[($zcvt(Number,"U")_","),(Number'="") s Number=$$$QuitChar q
	#;SML2207+ ; Allow user to enter leading '+' or '-' for changes to default value.
	if $zb(+Flag,$$$AllowIncrementalNumber,1) {
		s sign=$e(Number)
		if sign="+",$e(Number,2,*)?1.N {
			s Number=$g(Value)+$e(Number,2,*) w " = ",Number
		} elseif sign="-",$e(Number,2,*)?1.N {
			s Number=$g(Value)-$e(Number,2,*) w " = ",Number
		}
	}
	#;SML2207-
	i +Number'=Number w !!,"Please enter a valid number",! Continue
	i $d(Min),(Number<Min) w !!,"Answer must be greater than or equal to "_Min_", please re-enter",! Continue
	i $d(Max),(Number>Max) w !!,"Answer must be less than or equal to "_Max_", please re-enter",! Continue
 	q
 }
 i Number=$$$BackupChar q $$$BackupResponse
 i $zb(+Flag,$$$EnableQuitCharMask,1),(Number=$$$QuitChar) q $$$QuitResponse
 i Number=$$$HelpChar q $$$HelpResponse
 i $zcvt(Number,"U")=$$$HelpContextChar q $$$HelpContextResponse
 s Value=Number	
 q $$$SuccessResponse
HELP
 w !!
 w ?$$$HelpTab,"Any number entered is valid"
 i $d(Min),$d(Max) w !,?$$$HelpTab,"The answer must be between "_Min_ " and "_Max_" (inclusive)"
 i '$d(Min),$d(Max) w !,?$$$HelpTab,"The answer must be less than or equal to "_Max
 i $d(Min),'$d(Max) w !,?$$$HelpTab,"The answer must be greater than or equal to "_Min
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 i '$zb(+Flag,$$$DisableHelpContextCharMask,1) w !,?$$$HelpTab,$$$HelpContextChar_"  displays this help message"
 w !
 q
ERROR s $zt=""
 i $d(SetBreak) b 0
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompt for a number in a displayed menu.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value <br>
/// List - Array of menu items. This should be in one of the following 
/// two forms:<br>
/// List(1)="Option 1"<br>
/// List(2)="Option 2"<br>
/// List(n)="Option n"<br>
/// <br>
/// or
/// <br>
/// $lb(QueryName,ExecuteParam1,ExecuteParam2,ExecuteParamN)<br>
/// For example: $lb("SYS.Database:List","*")
/// <br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$DisableHelpContextCharMask - Disable entry of the help context character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
///      - $$$InitialDisplayMask - Display the menu when initially called<br>
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// $$$HelpContextResponse - Help context character entered if $$$DisableHelpContextCharMask set <br>
/// Value - Entered number<br>
ClassMethod GetMenu(Prompt As %String, ByRef Value As %Integer, ByRef List As %String, ByRef Help As %String, Flag As %Integer = 0, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 i $zb(+Flag,$$$InitialDisplayMask,1) {
	d LOAD
 	d DISPLAY
 }
 f  {
	w !,Prompt_" " 
	i $d(Value),(Value'="") {
		s DefaultString=Value_" "_$$$DefaultPrompt_" "
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i $zb(Flag,$$$TrapCtrlCMask,1) {
	 	i '($v(0,-1,4)\4#2) {
		 	b 1
	 		s SetBreak=1
 		}
	}
	i (Timeout'=0),$d(Value),(Value'="") {
		r String:Timeout s t=$t
		i $d(SetBreak) b 0
		i 't s String=Value w String q
	} else {
		r String
		i $d(SetBreak) b 0
	}
#; If a null string entered, and a default passed, use it
	i (String=""),$d(Value),(Value'="") s String=Value q
#; If a null string entered, and no default, return a backup char
	i String="" s String=$$$BackupChar q
	i (String=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (String=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		d LOAD
		d DISPLAY
		Continue
	}
	i ($zcvt(String,"U")=$$$HelpContextChar) {
		i $zb(+Flag,$$$DisableHelpContextCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help) d HELP Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		d HELP
		Continue
	}
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[($zcvt(String,"U")_","),(String'="") s String=$$$QuitChar q
	s String=$number(String,"I")
	i String'="" {
	 	d LOAD
	 	i (String<1)!(String>$o(Array($$$MaxInt),-1)) w !!,"Please enter a number between 1 and "_$o(Array($$$MaxInt),-1),! Continue
		q
 	} else {
 		w !!,"Please enter a number between 1 and "_$o(Array($$$MaxInt),-1),! Continue
 	}
 }
 i String=$$$BackupChar q $$$BackupResponse
 i $zb(+Flag,$$$EnableQuitCharMask,1),(String=$$$QuitChar) q $$$QuitResponse
 i String=$$$HelpChar q $$$HelpResponse
 i String=$$$HelpContextChar q $$$HelpContextResponse
 s Value=String
 q $$$SuccessResponse
HELP
#;SML1675 ; Call LOAD to make sure the Array is set.
 d LOAD
 w !!
 w ?$$$HelpTab,"The answer may be null or between 1 and "_$o(Array($$$MaxInt),-1)
 w !,?$$$HelpTab,""""" enters a null string"
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 i '$zb(+Flag,$$$DisableHelpContextCharMask,1) w !,?$$$HelpTab,$$$HelpContextChar_"  displays this help message"
 w !
 q
LOAD
 q:$d(Array)
 i $d(List)=1 {
	s Query=$li(List,1)
	Set Rset = ##class(%ResultSet).%New(Query)
	i $ll(List)=1 d Rset.Execute()
	i $ll(List)=2 d Rset.Execute($li(List,2))
	i $ll(List)=3 d Rset.Execute($li(List,2),$li(List,3))
	i $ll(List)=4 d Rset.Execute($li(List,2),$li(List,3),$li(List,4))
	i $ll(List)=5 d Rset.Execute($li(List,2),$li(List,3),$li(List,4),$li(List,5))
	i $ll(List)=6 d Rset.Execute($li(List,2),$li(List,3),$li(List,4),$li(List,5),$li(List,6))
	While (Rset.Next()) {
		s Array($i(Index))=Rset.GetData(1)
 	}
 	k Rset,Query,Index
 } else {
	 m Array=List
 }
 q
DISPLAY
 w !
 s MaxArray=$o(Array($$$MaxInt),-1)
 s Len=$l(MaxArray)
 i MaxArray>$$$LinesPerPage {
 	s Lines=0 
 	s Num=$o(Array(""))
 	while(Num?1n.n) {
	 	s Lines=Lines+1
	 	i Lines#$$$LinesPerPage=0 {
			w !
	 		s Status=..GetMore(,,Flag)
	 		w !
	 		i (Status=$$$QuitResponse)||(Status=$$$BackupResponse) q
	 	}
	 	w !,$j(Num,Len),") "_Array(Num)
	 	s Num=$o(Array(Num))
	 	Continue:Num'?1n.n
	 	i $x>40 Continue
	 	i $x+Len+2+$l(Array(Num))>79 Continue
		w ?40,$j(Num,Len),") "_Array(Num)
	 	s Num=$o(Array(Num))
 	}
 } else {
 	f i=1:1:MaxArray w !,$j(i,Len),") "_Array(i)
 }
 w ! 	 
 q
ERROR s $ZT=""
 i $d(SetBreak) b 0
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompt for a number or entry in a displayed menu. Returns the selected item.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value <br>
/// List - Array of menu items. This should be in one of the following 
/// two forms:<br>
/// List(1)="Option 1"<br>
/// List(2)="Option 2"<br>
/// List(n)="Option n"<br>
/// If List(n,0) exist then the help (? entered) will display List(n)_List(n,0).<br>
/// <br>
/// or
/// <br>
/// $lb(QueryName,ExecuteParam1,ExecuteParam2,ExecuteParamN)<br>
/// For example: $lb("SYS.Database:List","*")
/// <br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$DisableHelpContextCharMask - Disable entry of the help context character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
///      - $$$InitialDisplayMask - Display the menu when initially called<br>
///      - $$$AllowNullMask - Allow null entry<br>
///      - $$$EnableMultipleSelectionMask - Allow comma delimited numeric entry, ranges, and * for all<br>
///      - $$$MatchExactArrayMask - Only entries from the the array of options are allowed, case sensitive<br>
///      - $$$MatchArrayMask - Only entries from the array of options are allowed, not case sensitive<br>
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// $$$HelpContextResponse - Help character entered if $$$DisableHelpContextCharMask set <br>
/// Value - Value of selected item; or if the $$$EnableMultipleSelectionMask flag is used, a list of selected items in $listbuild format.<br>
/// If the size of the selected set exceeds the maximum local variable string size either an error will be thrown or
/// if $$$TrapErrorMask is specified, an error will be returned<br>
/// <br>
ClassMethod GetArray(Prompt As %String, ByRef Value As %String, ByRef List As %String, MinLen As %Integer, MaxLen As %Integer, ByRef Help As %String, Flag As %Integer = 0, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 i $zb(+Flag,$$$InitialDisplayMask,1) {
	d LOAD
 	d DISPLAY
 }
 f  {
	s needslist=0
	w !,Prompt_" " 
	i $d(Value),(Value'="") {
		s DefaultString=Value_" "_$$$DefaultPrompt_" "
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i $zb(Flag,$$$TrapCtrlCMask,1) {
	 	i '($v(0,-1,4)\4#2) {
		 	b 1
	 		s SetBreak=1
 		}
	}
	i (Timeout'=0),$d(Value),(Value'="") {
		r String:Timeout s t=$t
		i $d(SetBreak) b 0
		i 't s String=Value w String q
	} else {
		r String
	}
	i (String=""),$d(Value),(Value'="") s String=Value q
	i (String=""),$zb(+Flag,$$$AllowNullMask,1) q
	i (String=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (String=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		d LOAD
		d DISPLAY
		Continue
	}
	i ($zcvt(String,"U")=$$$HelpContextChar) {
		i $zb(+Flag,$$$DisableHelpContextCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help) d HELP Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		d HELP
		Continue
	}
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[($zcvt(String,"U")_","),(String'="") s String=$$$QuitChar q
	i String=$$$NullChar s String=""
 	i $IsValidNum(String,0) {
	 	d LOAD
		s String=$number(String,"I")
	 	i (String<1)!(String>$o(Array($$$MaxInt),-1)) w !!,"Please enter a number between 1 and "_$o(Array($$$MaxInt),-1),! Continue
		w " ",Array(+String) 
		s String=Array(+String)
		i $zb(+Flag,$$$EnableMultipleSelectionMask,1) s String=$lb(String)
		q
 	} 
 	if $zb(+Flag,$$$EnableMultipleSelectionMask,1) {
		d LOAD
		k String1
		f i=1:1 {
 			s Piece=$p(String,",",i)
			q:Piece=""
 			i Piece="*" {
				f j=1:1:$o(Array(""),-1) s String1(Array(j))=""
				q
			}
#; SML900
 			i (Piece'["-") || '(Piece?.N1"-".N) {
	 			i $d(Array(+Piece)) s String1(Array(+Piece))=""
			} else {
				f j=+$p(Piece,"-",1):1:+$p(Piece,"-",2) i $d(Array(j)) s String1(Array(j))=""
			}	 			
		}
#; Now merge the accumulated strings into $list format
		s i="" 
		s i=$o(String1(i))
		while (i'="") {
			s String2=$g(String2)_$lb(i)
			s i=$o(String1(i))
		}
#; If there is no String2 then String needs to be put in list format
#;	because EnableMultipleSelectionMask is true here
		i $d(String2) {
			#; We found at least one of the multiple selections in the list
			#; and ignored any others, so we're done
			m String=String2
			q
		} 
		#; No selections from the list were found and we're treating this as a
		#; single write-in response.  Fall through to the validation logic, but
		#; remember we need to convert the value to a list before returning
		s needslist=1
	}
 	i $d(MinLen),(MinLen=0),(String="") q
	i $zb(+Flag,$$$MatchArrayMask+$$$MatchExactArrayMask,1) {
		s Found=0
		d LOAD
		s Match=$o(Array(""))
		While (Match'="") {
			i $zb(+Flag,$$$MatchArrayMask,1),($zcvt(Array(Match),"U")=$zcvt(String,"U")) {
				s String=Array(Match) 
				s Found=1 
				q
			}
			i $zb(+Flag,$$$MatchExactArrayMask,1),(Array(Match)=String) {
				s String=Array(Match) 
				s Found=1 
				q
			}
			s Match=$o(Array(Match))
		}
		i 'Found {
			w !!,"Entry must be from the list, please re-enter",!
			Continue
		}
		q:Found
	}
	s Len=$l(String)
	i $d(MinLen),(Len<MinLen) w !!,"Answer must be at least "_MinLen_" characters long, please re-enter",! Continue
	i $d(MaxLen),(Len>MaxLen) w !!,"Answer must be at most "_MaxLen_" characters long, please re-enter",! Continue
	q
 }
 i String=$$$BackupChar q $$$BackupResponse
 i $zb(+Flag,$$$EnableQuitCharMask,1),(String=$$$QuitChar) q $$$QuitResponse
 i String=$$$HelpChar q $$$HelpResponse
 i $zcvt(String,"U")=$$$HelpContextChar q $$$HelpResponse
 i $g(needslist) s String=$lb(String)
 if $zb(+Flag,$$$EnableMultipleSelectionMask,1) {
	#; String could be an array, with $LIST values in subnodes
 	m Value=String
 } else {
 	s Value=String
 }
 q $$$SuccessResponse
HELP
 w !!
 w ?$$$HelpTab,"The answer "
 i '$d(MinLen) {
	w "may be null"
 }else {
 	w "must be "_MinLen
 }
 w " or more characters long, and up to "
 i '$d(MaxLen) {
	w "any length"
 
 }else {
	 w MaxLen_" characters long"
 }
 w !,?$$$HelpTab,""""" enters a null string"
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 i '$zb(+Flag,$$$DisableHelpContextCharMask,1) w !,?$$$HelpTab,$$$HelpContextChar_"  displays this help message"
 w !
 q
LOAD
 q:$d(Array)
 i $d(List)=1 {
	s Query=$li(List,1)
	Set Rset = ##class(%ResultSet).%New(Query)
	i $ll(List)=1 d Rset.Execute()
	i $ll(List)=2 d Rset.Execute($li(List,2))
	i $ll(List)=3 d Rset.Execute($li(List,2),$li(List,3))
	i $ll(List)=4 d Rset.Execute($li(List,2),$li(List,3),$li(List,4))
	i $ll(List)=5 d Rset.Execute($li(List,2),$li(List,3),$li(List,4),$li(List,5))
	i $ll(List)=6 d Rset.Execute($li(List,2),$li(List,3),$li(List,4),$li(List,5),$li(List,6))
	While (Rset.Next()) {
		s Array($i(Index))=Rset.GetData(1)
 	}
 k Rset,Query,Index
 }else {
	 m Array=List
 }
 q
DISPLAY
 w !
 s MaxArray=$o(Array($$$MaxInt),-1)
 s Len=$l(MaxArray)
 i MaxArray>$$$LinesPerPage {
 	s Lines=0 
 	s Num=$o(Array(""))
 	while(Num?1n.n) {
	 	s Lines=Lines+1
	 	i Lines#$$$LinesPerPage=0 {
			w !
	 		s Status=..GetMore(,,Flag)
	 		w !
	 		i (Status=$$$QuitResponse)||(Status=$$$BackupResponse) q
	 	}
#;SML905+  ; Get the extra data to be displayed
		s ArrayData=Array(Num)_$G(Array(Num,0),"")
 		w !,$j(Num,Len),") "_ArrayData
#;SML905-
	 	s Num=$o(Array(Num))
	 	Continue:Num'?1n.n
	 	i $x>40 Continue
#;SML905+  ; Get the extra data to be displayed
		s ArrayData=Array(Num)_$G(Array(Num,0),"")
	 	i $x+Len+2+$l(ArrayData)>79 Continue
		w ?40,$j(Num,Len),") "_ArrayData
#;SML905-
	 	s Num=$o(Array(Num))
 	}
}else {
#;SML905+  ; Get the extra data to be displayed
 	f i=1:1:MaxArray w !,$j(i,Len),") "_Array(i)_$G(Array(i,0),"")
 }
 w ! 	 
 w:$zb(+Flag,$$$EnableMultipleSelectionMask,1) ?5,"(Multiple selections allowed: * for all, or list such as 1,4,7-10)"
 q
ERROR s $ZT=""
 i $d(SetBreak) b 0
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompt for a String.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value <br>
/// Min - Minimum length of string allowed<br>
/// Max - Maximum length of string allowed<br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$DisableHelpContextCharMask - Disable entry of the help context character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// $$$HelpContextResponse - Help character entered if $$$DisableHelpContextCharMask set <br>
/// Value - Entered String<br>
ClassMethod GetString(Prompt As %String, ByRef Value As %String, MinLen As %Integer, MaxLen As %Integer, ByRef Help As %String, Flag As %Integer = 0, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 f  {
	w !,Prompt_" " 
	i $d(Value),(Value'="") {
		s DefaultString=Value_" "_$$$DefaultPrompt_" "
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i $zb(Flag,$$$TrapCtrlCMask,1) {
	 	i '($v(0,-1,4)\4#2) {
		 	b 1
	 		s SetBreak=1
 		}
	}
	i (Timeout'=0),$d(Value),(Value'="") {
		r String:Timeout s t=$t
		i $d(SetBreak) b 0
		i 't s String=Value w String q
	} else {
		r String
		i $d(SetBreak) b 0
	}
	i (String=""),$d(Value),(Value'="") s String=Value q
	i (String=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (String=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help) Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		Continue
	}
	i ($zcvt(String,"U")=$$$HelpContextChar) {
		i $zb(+Flag,$$$DisableHelpContextCharMask,1) q
		d HELP Continue
	}
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[($zcvt(String,"U")_","),(String'="") s String=$$$QuitChar q
	i String=$$$NullChar s String=""
	s Len=$l(String)
	i $d(MinLen),(Len<MinLen) w !!,"Answer must be at least "_MinLen_" characters long, please re-enter",! Continue
	i $d(MaxLen),(Len>MaxLen) w !!,"Answer must be at most "_MaxLen_" characters long, please re-enter",! Continue
 	q
 }
 i String=$$$BackupChar q $$$BackupResponse
 i $zb(+Flag,$$$EnableQuitCharMask,1),(String=$$$QuitChar) q $$$QuitResponse
 i String=$$$HelpChar q $$$HelpResponse
 i $zcvt(String,"U")=$$$HelpContextChar q $$$HelpContextResponse
 s Value=String
 q $$$SuccessResponse
HELP
 w !!
 w ?$$$HelpTab,"The answer "
 i '$d(MinLen) {
	w "may be null"
 } else {
 	w "must be "_MinLen
 }
 w " or more characters long, and up to "
 i '$d(MaxLen) {
	w "any length"
 
 } else {
	 w MaxLen_" characters long"
 }
 w !,?$$$HelpTab,""""" enters a null string"
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 i '$zb(+Flag,$$$DisableHelpContextCharMask,1) w !,?$$$HelpTab,$$$HelpContextChar_"  displays this help message"
 w !
 q
ERROR s $ZT=""
 i $d(SetBreak) b 0
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompt for a Password.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value <br>
/// Flag - From %syPrompt.inc<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
///      - $$$EchoNothing - No characters will be echoed. Default will echo "*"<br>
///      - $$$EchoPassword - Password will be displayed when entered<br>
///      - $$$ValidatePassword - Password will be validated against system password pattern<br>
/// Timeout - Timeout for prompt<br>
/// Username - Username used for password validation<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$TimeoutResponse - Input timed out, no value returned<br> 
/// Value - Entered String<br>
ClassMethod GetPassword(Prompt As %String, ByRef Value As %String, Flag As %Integer = 0, Timeout As %Integer = 0, Username As %String = "") As %Integer
{
 s $zt="Error"
#;SML817 Don't use secret mode for UNIX with script input
#;RJW1549 Don't use secret mode on any platform with script input because
#;use $io:(:"S") on sequential files does an lseek(beginning of file)
 s secret=($io'="00")
 s EchoNothing=0
 i $zb(Flag,$$$EchoNothing,1) s EchoNothing=1
 s EchoPassword=0
 i $zb(Flag,$$$EchoPassword,1) s EchoPassword=1
 s String=""
 f  {
	w !,Prompt_" " 
	i $d(Value),(Value'="") {
		i EchoPassword {
			s DefaultString=Value_" "_$$$DefaultPrompt_" "
		} else {
			s DefaultString="****** "_$$$DefaultPrompt_" "
		}
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i secret u $io:(:"S")
 	s X="",timeout=0
#;SML817
#;Allow CTRL/C during read
	i $zb(Flag,$$$TrapCtrlCMask,1),'($v(0,-1,4)\4#2) b 1 s SetBreak=1
	i 'secret {
		i Timeout {
			r String:Timeout 
			i '$t s timeout=1
		} else {
			r String
		}
	} else {
		 f i=1:1 {
			i Timeout {
				r *x:Timeout
			 	i '$t s timeout=1
			} else {
				r *x
			}
			q:timeout
			q:(x=13!(x=10))
			i x=27 s key=$key i key=$c(27,91,51,126) s x=127
		 	i x=8!(x=127) {
			 	s l=$l(String)
		 		i l,'EchoNothing w *8," ",*8 s String=$e(String,1,l-1)
		 		continue
		 	}
			s String=String_$c(x)
			i EchoNothing continue
			i EchoPassword {
				w $c(x)
			} else {
				w "*"
			}
		}
		i String="",$d(Value) s String=Value
	}
 	q:timeout
	i $zb(+Flag,$$$ValidatePassword,1) {
		s Status=$$ValidatePassword^%SYS.SECURITY(Username,String)
		i '$$$ISOK(Status) {
			w !,$SYSTEM.Status.GetErrorText(Status)
			s String=""
			k %objlasterror
			continue
		}
 	}
 	q
 }
 i timeout {
	zk Value
 	q $$$TimeoutResponse
 }
 i secret u $io:(:"-S") 
 i $d(SetBreak) b 0 k SetBreak
 s Value=String
 q $$$SuccessResponse
Error s $zt=""
 zk Value
 i secret u $io:(:"-S") 
 i $d(SetBreak) b 0 k SetBreak
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompts for a username<br>
/// This method will prompt for and return a username<br>
/// Flags - Flags for prompting<br>
/// Bit 1 - Use ":" in prompt
/// Bit 1 - Passed in when the system is hung so we don't reference a
/// process private global and hang ourselves.<br>
/// Return Values:<br>
/// Username - Username
ClassMethod GetUsername(Prompt As %String, ByRef Username As %String, Flags As %Integer = 0) As %Status [ Internal ]
{
 s $zt="Error"
 s Username=""
 #;There may be a FILEFULL condition in CACHETEMP, let the user log in
 Try {
	i $zb(+Flags,2,1) {
		 w !,"Username: "
	} else {
		w !,$$$GetMsg($$$UsersMsg,"UsernameC")
	}
 } catch {
 	w !,"Username: "
 }
#;Allow CTRL/C during read
 b 1
#;SGM188+
 s X=""
 s timeout=0
 f {
	r *x:30 i '$t s timeout=1 q
	#; If a return key or line feed, we're done
	q:(x=13!(x=10))
	#; Handle escaped command key sequences
	i x=27 {
		s key=$key
		#; Treat this sequence as a delete
		i key=$c(27,91,51,126) s x=127
		#; Ignore other escaped sequences
		i x=27 continue
	}
	#; If backspace or delete, remove the last typed character
	i x=8!(x=127) {
		s l=$l(X)
		i l w *8," ",*8 s X=$e(X,1,l-1)
		continue
	}
	#; Otherwise, add it to the input username
	s X=X_$c(x)
 }
 b 0
 i timeout q $$$ERROR($$$UserLoginTimeout)
#;SGM188-
 s Username=X
 q $$$OK
Error s $zt=""
 b 0
 i $ze["<INTERRUPT>" q $$$ERROR($$$UserCTRLC)
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Prompt for a Yes/No answer.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Value - Default value 0=No, 1=Yes<br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// Value - 0=No, 1=Yes<br>
ClassMethod GetYesNo(Prompt As %String, ByRef Value As %Integer, ByRef Help As %String, Flag As %Integer = 0, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 f  {
	w !,Prompt_" " 
	i $d(Value) {
		s DefaultString=$case(Value,0:$$$No,1:$$$Yes)_" "_$$$DefaultPrompt_" "
		i $x+$l(DefaultString)>70 w !,?$$$HelpTab
		w DefaultString
	}
	i (Timeout'=0),$d(Value) {
		r YesNo:Timeout
		i '$t s YesNo=Value w $case(YesNo,0:$$$No,1:$$$Yes) q
	} else {
		r YesNo
	}
	i (YesNo=""),$d(Value) s YesNo=Value q
	i (YesNo=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (YesNo=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help) Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		Continue
	}
	i ($zcvt(YesNo,"U")=$$$HelpContextChar) {
		i $zb(+Flag,$$$DisableHelpContextCharMask,1) q
		d HELP Continue
	}
	s YesNoUpperCase=$zcvt(YesNo,"U")
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[(YesNoUpperCase_","),(YesNoUpperCase'="") s YesNo=$$$QuitChar q
	i YesNoUpperCase]"" {
		i $e($zcvt($$$Yes,"U"),1,$l(YesNoUpperCase))=YesNoUpperCase s YesNo=1 q
		i $e($zcvt($$$No,"U"),1,$l(YesNoUpperCase))=YesNoUpperCase s YesNo=0 q
	}
	w !!,"Please enter "_$$$Yes_" or "_$$$No,!
 }
 i YesNo=$$$BackupChar q $$$BackupResponse
 i $zb(+Flag,$$$EnableQuitCharMask,1),(YesNo=$$$QuitChar) q $$$QuitResponse
 i YesNo=$$$HelpChar q $$$HelpResponse
 i $zcvt(YesNo,"U")=$$$HelpContextChar q $$$HelpContextResponse
 s Value=YesNo
 q $$$SuccessResponse
HELP
 w !!
 w ?$$$HelpTab,"Y/Ye/Yes and N/No are valid responses"
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 i '$zb(+Flag,$$$DisableHelpContextCharMask,1) w !,?$$$HelpTab,$$$HelpContextChar_"  displays this help message"
 w !
 q
ERROR s $ZT=""
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Prompt for More or Quit.<br>
/// <br>
/// Input Parameters:<br>
/// Prompt - Prompt to be displayed<br>
/// Help - Array of help text<br>
/// Flag - From %syPrompt.inc<br>
///      - $$$DisableBackupCharMask - Disable entry of the backup character<br>
///      - $$$TrapCtrlCMask - Trap CTRL/C and return CTRL/C status<br>
///      - $$$EnableQuitCharMask - Enable quit and return Quit status<br>
///      - $$$DisableHelpCharMask - Disable entry of the help character<br>
///      - $$$TrapErrorMask - Trap errors and return error status<br>
/// TimeOut - Timeout for prompt<br>
/// <br>
/// Output parameters:<br>
/// Status - One of the following from %syPrompt:<br>
/// $$$SuccessResponse - Successful entry, Value contains valid open device<br>
/// $$$BackupResponse - Backup character entered<br>
/// $$$QuitResponse - Quit character entered if $$$EnableQuitCharMask set<br>
/// $$$CtrlCResponse - CTRL/C entered if $$$TrapCtrlCMask set<br>
/// $$$ErrorResponse - Error during entry if $$$TrapErrorMask set<br>
/// $$$HelpResponse - Help character entered if $$$DisableHelpCharMask set <br>
/// Value - Entered number<br>
ClassMethod GetMore(Prompt As %String = "-more-", ByRef Help As %String, Flag As %Integer = {$$$EnableQuitCharMask}, Timeout As %Integer = 0) As %Integer
{
 s $zt="ERROR"
 f  {
	w !,Prompt_" "
	i $zb(Flag,$$$TrapCtrlCMask,1) {
	 	i '($v(0,-1,4)\4#2) {
		 	b 1
	 		s SetBreak=1
 		}
	}
	i (Timeout'=0) {
		r String#1:Timeout
		i $d(SetBreak) b 0
		i '$t s String="" q
	} else {
		r String#1
		i $d(SetBreak) b 0
	}
	i (String=$$$BackupChar) {
		i '$zb(+Flag,$$$DisableBackupCharMask,1) q
		w !!,$$$BackupChar_" Disabled for this prompt",! Continue
	}
	i (String=$$$HelpChar) {
		i $zb(+Flag,$$$DisableHelpCharMask,1) q
		i $d(Help)=0 d HELP Continue
		i $d(Help)=1 w !!,?$$$HelpTab,$g(Help) Continue
		w ! f i=1:1:+$o(Help($$$MaxInt),-1) w !,?$$$HelpTab,$g(Help(i))
		w !
		d HELP
		Continue
	}
	i String="" q
	i $zb(+Flag,$$$EnableQuitCharMask,1),$$$QuitString[($zcvt(String,"U")_","),(String'="") s String=$$$QuitChar q
 	q
 }
 i String=$$$BackupChar q $$$BackupResponse
 i String=$$$QuitChar q $$$QuitResponse
 i String=$$$HelpChar q $$$HelpResponse
 q $$$SuccessResponse
HELP
 w !!
 i $zb(+Flag,$$$EnableQuitCharMask,1) w !,?$$$HelpTab,$$$QuitChar_" quits the program"
 i '$zb(+Flag,$$$DisableBackupCharMask,1) w !,?$$$HelpTab,$$$BackupChar_"  returns to the previous prompt"
 i '$zb(+Flag,$$$DisableHelpCharMask,1) w !,?$$$HelpTab,$$$HelpChar_"  displays help text"
 w !
 q
ERROR s $ZT=""
 i $d(SetBreak) b 0
 i ($ze["<INTERRUPT>"),$zb(+Flag,$$$TrapCtrlCMask,1) q $$$CtrlCResponse
 i $zb(+Flag,$$$TrapErrorMask,1) q $$$ErrorResponse
 ztrap $ze
}

/// Edits an objects properties.
ClassMethod EditFields(Obj, New) [ Internal ]
{
 s $ZT="ERROR"
 n %Field,%Status,%Value,%New,%Obj
 s %New=New
 s %Obj=Obj
 s ClassName="##Class("_Obj.%ClassName(1)_")"
 d EDITFIELDSMENU
 s Max=$o(%Field($$$MaxInt),-1)
 f {
	s %Value=""
	s %Status=..GetNumber("Field number to change?",.%Value,1,Max,,$$$TrapCtrlCMask+$$$DisableHelpCharMask+$$$AllowNullMask)
 	i (%Status=$$$CtrlCResponse)||(%Status=$$$BackupResponse) q
	i %Status=$$$HelpResponse d EDITFIELDSMENU Continue
	i %Value="" s %Status=$$$SuccessResponse q
	i $d(%Field(%Value,"ReadOnly")) w !!,"Field is for display only, please re-enter",! Continue
	i $d(%Field(%Value))=0 w !!,"Invalid entry, please re-enter",! continue
	s x="s %Status="_ClassName_"."_%Field(%Value,"Property")_"Prompt(%Field(%Value,""Prompt""),.%Field)" 
	x x
 	i (%Status=$$$CtrlCResponse) q
 	#;SML968+ ; Refresh the %Field info after one of the fields is updated.
 	s x="s %Status="_ClassName_".LoadFields(.%Field,.%Obj,%New)"
 	x x
 	#;SML968-
 }
 q %Status
  
ERROR s $zt=""
 i $ze["<INTERRUPT>" q $$$CtrlCResponse
 ztrap $ZE
EDITFIELDSMENU
 s x="s %Status="_ClassName_".LoadFields(.%Field,.%Obj,%New)"
 x x
 s MaxSize=0
 s Num=$o(%Field(""))
 while (Num'="") {
	s Size=$l(%Field(Num,"Caption"))
	i Size>MaxSize s MaxSize=Size
 	s Num=$o(%Field(Num))
 }
 s MaxSize=MaxSize+7
 s Num=$o(%Field(""))
 w !
 while (Num'="") {
	w !,$j(Num,2)_")"
	i $d(%Field(Num,"ReadOnly")) {
		w "* "
	} else {
		w "  "
	}
	w %Field(Num,"Caption")_":",?MaxSize
	i %Field(Num,"Property")="NewGlobalCollation" s x="w "_ClassName_"."_%Field(Num,"Property")_"LogicalToDisplay(%Obj."_%Field(Num,"Property")_",2)"
	e  s x="w "_ClassName_"."_%Field(Num,"Property")_"LogicalToDisplay(%Obj."_%Field(Num,"Property")_")"
 	x x
 	s Num=$o(%Field(Num))
 }
 w !
 q
}

}
