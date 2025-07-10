/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Service to consume data from batch files via FTP using the RecordMap parsing framework.
Class EnsLib.RecordMap.Service.BatchFTPService Extends EnsLib.RecordMap.Service.BatchFileService [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

}
