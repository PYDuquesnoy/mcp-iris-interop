/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Background.Workflow.ExportRequest Extends EnsLib.Workflow.TaskRequest [ System = 4 ]
{

Parameter RESPONSECLASSNAME = "EnsLib.Background.Workflow.ExportResponse";

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
