/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Simple spacer meter
Class %CSP.Util.HTMLSpacer Extends %CSP.Util.HTMLMeter [ ServerOnly = 1, System = 4 ]
{

Method OnHTMLBody()
{
	Set SpaceImage = ##class(%CSP.Page).Link("/csp/sys/images/spacer.gif")

	&html<<image src="#(SpaceImage)#" width="#(..Width)#" height="#(..Height)#">>
}

}
