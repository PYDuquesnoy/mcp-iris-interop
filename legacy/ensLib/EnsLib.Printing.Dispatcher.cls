/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Printing.Dispatcher Extends Ens.BusinessProcessBPL [ ClassType = persistent, System = 4 ]
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='EnsLib.Printing.PrintRequest' response='Ens.Response' height='2000' width='2000' >
<sequence xend='550' yend='650' >
<call name='Render Print Job' target='@request.PrintRenderer' async='0' xpos='550' ypos='200' >
<request type='EnsLib.Printing.PrintRequest' >
<assign property='callrequest' value='request' action='set' />
</request>
<response type='EnsLib.Printing.PrintJob' >
<assign property='response' value='callresponse' action='set' />
</response>
</call>
<if name='Print?' condition='request.PrintTarget&apos;=""' xpos='550' ypos='300' xend='550' yend='550' >
<true>
<call name='Print This Job' target='@request.PrintTarget' async='0' xpos='685' ypos='450' >
<request type='EnsLib.Printing.PrintJob' >
<assign property='callrequest' value='response' action='set' />
<assign property='callrequest.PrintTarget' value='request.PrintTarget' action='set' />
</request>
</call>
</true>
</if>
</sequence>
</process>
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
