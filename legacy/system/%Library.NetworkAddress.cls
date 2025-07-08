/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syINET

/// This datatype class validates IP addresses and ports in the format IP|Port. The IP
/// address can either be an IPV4, IPV6, or DNS name. For example:<br><br>
/// 127.0.0.1|1972<br>
/// fe80::20c:29ff:fe21:20cf|1972<br>
/// hostname|1972<br>
Class %Library.NetworkAddress Extends %Library.String [ System = 4 ]
{

ClassMethod IsValid(%Val As %RawString) As %Status
{
#;All null is ok. To force the property to contain something, use the [Required] flag
#;on the property.
	i %Val="" q $$$OK
#;If anything is specified, the whole thing must be specified.
	s Addr=$p(%Val,"|",1)
	s Port=$p(%Val,"|",2)
	i '$isvalidnum(Port) q $$$ERROR($$$DTNotNum,Port)
	i (Port<0) q $$$ERROR($$$DTMinVal,Port,0)
	i (Port>65535) q $$$ERROR($$$DTMaxVal,Port,65535)
	Quit $case('($$$ISIP(Addr)!((Addr?1AN.(1AN,1"-",1"_").(1"."1.(1AN,1"-",1"_"))1AN)&($l(Addr)<256)&($tr(Addr,".","")'?.N))),0:1,1:$$$ERROR($$$DTFailure,Addr))
}

/// Method to Get the address in a format usable with an http url.
/// The format of %NetworkAddress is address_"|"_port, while the address required
/// for a url is address_":"_port.  Furthermore, if the address is an IPV6 colon separated
/// hex representation, the address must be enclosed with [].
ClassMethod FormatForHttp(Address) As %String
{
	s a=$p(Address,"|",1),p=$p(Address,"|",2)
	i a[":" s a="["_a_"]"
	q a_":"_p
}

}
