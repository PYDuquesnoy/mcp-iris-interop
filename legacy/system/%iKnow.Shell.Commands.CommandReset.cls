/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Shell.Commands.CommandReset Extends %iKnow.Shell.Command [ Deprecated ]
{

Method GetCommandName() As %String
{
	quit "reset"
}

Method Describe(shell As %iKnow.Shell, ByRef description)
{
	set description("reset") = "Reset the internal state"
}

Method DescribeDetails(shell As %iKnow.Shell, ByRef description) [ Private ]
{
	set descStr = "Reset the internal state"_$c(10)
	set descStr = descStr_"The following states are reset:"_$c(10,10)
	set descStr = descStr_"device"_$c(9)_"0"_$c(10)
	set descStr = descStr_"filter"_$c(9)_"0"_$c(10)
	set descStr = descStr_"page"_$c(9)_"1"_$c(10)
	set descStr = descStr_"pagesize"_$c(9)_"10"_$c(10)
	set description("reset") = descStr
}

Method Run(shell As %iKnow.Shell, ByRef args, parentCommand As %iKnow.Shell.Command = "")
{
	set argCnt = $g(args,0)
	
	if (argCnt=1) {
		if (args(1)="?") {
			do ..DescribeDetails(shell, .description)
			do shell.OutputDescription(.description)
		} else {
			throw:argCnt>0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"reset: No arguments allowed"))
		}
	} elseif (argCnt>1) {
		throw:argCnt>0 ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"reset: No arguments allowed"))
	} else {
		do shell.RunState.Reset()
		do shell.OutputInfo("Current state reset to default")
	}
}

}
