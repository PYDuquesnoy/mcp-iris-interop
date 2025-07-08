/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.utils.StringMatchUtils Extends %RegisteredObject [ System = 4 ]
{

ClassMethod tokenize(value As %String, Output array) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim n, i, j As %Integer
	#dim mgram As %String
	
	Try {
		k array
		set sc = ..getNumberOfTokens(.value, .n)
		Quit:$$$ISERR(sc)
		
		set i = 1
		set j = 1
		for i = 1:1:n {
			set mgram = $zstrip($p(value," ",i),"<>P")
			if (mgram = "") {
				Continue
			}
			set array(j) = mgram
			set j = $i(j)
		}
		set array = j - 1
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod getNumberOfTokens(ByRef value As %String, Output n As %Integer, pattern As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set value = $zstrip(value,"<>CP")
		set value = $zstrip(value,"=P")
		set value = $tr(value,$c(9),$c(32))
		set value = $tr(value,$c(160),$c(32))
		
		set value = $tr(value,"-/()[],:","        ")
		/*
		set value = $tr(value,"-",$c(32))
		set value = $tr(value,"/",$c(32))
		set value = $tr(value,"(",$c(32))
		set value = $tr(value,")",$c(32))
		set value = $tr(value,"[",$c(32))
		set value = $tr(value,"]",$c(32))
		set value = $tr(value,",",$c(32))
		*/
		
		if (pattern = "") {
			set n = $l(value," ")
		} else {
			set n = $l(" "_value_" "," "_pattern_" ") - 1
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod str2arr(value As %String, Output array) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim n, i As %Integer
	
	Try {
		set n = $l(value)
		k array
		set array = n
		for i = 1:1:n {
			set array(i) = $e(value,i)
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod compareNGrams(v1 As %String, v2 As %String, Output dist, ByRef costs = "", normalizeCode As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	set dist = ""

	#dim s, t
	
	Try {
		set sc = ..tokenize(v1, .s)
		Quit:$$$ISERR(sc)
		
		set sc = ..tokenize(v2, .t)
		Quit:$$$ISERR(sc)
		
		set sc = ..compareArr(.s, .t, .dist, .costs, normalizeCode)
		if ($$$ISERR(sc)) {
			set sc = $system.Status.AppendStatus($$$ERROR($$$GeneralError,"Error comparing: '"_v1_"' and '"_v2_"'"),sc)
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod compareMonoGrams(v1 As %String, v2 As %String, Output dist, ByRef costs = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	set dist = ""

	#dim s, t
	
	Try {
		set sc = ..str2arr(v1, .s)
		Quit:$$$ISERR(sc)
		
		set sc = ..str2arr(v2, .t)
		Quit:$$$ISERR(sc)
		
		set sc = ..compareArr(.s, .t, .dist, .costs, "")
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod ldist(v1 As %String, v2 As %String, ByRef costs = "") As %Double
{
	#dim d As %Double
	#dim sc As %Status
	
	set sc = ..compareMonoGrams(v1, v2, .d, .costs)
	if ($$$ISERR(sc)) {
		d $system.OBJ.DisplayError(sc)
		Quit 0
	}
	
	Quit d
}

ClassMethod compareArr(ByRef s, ByRef t, Output dist, ByRef costs, normalizeCode As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	set dist = ""

	#dim pp, p, d
	#dim i, j, n, m, cost, c1, c2, ins, del, subst, transp As %Integer
	#dim tj, si As %String
	
	Try {
		set n = s
		set m = t
		
		set p(0) = 0
		for i = 1:1:n {
			set si = s(i)
			set c1 = $g(costs(1,si),$g(costs(0,si),1))
			set p(i) = p(i-1) + c1
		}
		
		for j = 1:1:m {
			set tj = t(j)

			set c1 = $g(costs(2,tj),$g(costs(0,tj),1))

			set d(0) = p(0) + c1
			
			for i = 1:1:n {
				set si = s(i)

				set c1 = $g(costs(1,si),$g(costs(0,si),1))
				set c2 = $g(costs(2,tj),$g(costs(0,tj),1))

				if (s(i) = tj) {
					set cost = 0
				} elseif ($zcvt(s(i),"l") = $zcvt(tj,"l")) {
					set cost = $g(costs("c"),0.1)
				} elseif ((normalizeCode '= "") && (..nml(normalizeCode,s(i)) = ..nml(normalizeCode,tj))) {
					set cost = $g(costs("n"),0.2)
				} else {
					set cost = $g(costs("s"),1)
					if (c1 > cost) {
						set cost = c1
					}
					if (c2 > cost) {
						set cost = c2
					}
				}
				
				set del = d(i-1) + c1
				//break
				
				set ins = p(i) + c2

				set subst = p(i-1) + cost
				
				set d(i) = del
				if (ins < d(i)) {
					set d(i) = ins
				}
				if (subst < d(i)) {
					set d(i) = subst
				}
				
				if ((i > 1) && (j > 1)) {
					if ((tj = s(i-1)) && (t(j-1) = si)) {
						set cost = $g(costs("t"), 1)
						set transp = pp(i-2) + cost
						if (transp < d(i)) {
							set d(i) = transp
						}
					}
				}
			}
			
			k pp
			m pp = p
			k p
			m p = d
			k d
			m d = pp
			
			//w "j = "_j_": ", !
			//zw p
		}
		
		set dist = p(n)
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod nml(code As %String, v As %String) As %String
{
	k %nmlr
	set v = $replace(v, """", """""")
	set v = """"_v_""""
	set code = "set %nmlr = "_$replace(code, "?", v)
	x code
	
	Q %nmlr
}

}
