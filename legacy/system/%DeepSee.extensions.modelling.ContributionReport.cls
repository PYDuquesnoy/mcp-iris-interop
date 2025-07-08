/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.ContributionReport Extends (%RegisteredObject, Base) [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.Report;

Property file As %File;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.Report) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..config = conf
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method apply() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = ..report()
		Quit:$$$ISERR(sc)
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method report() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim name, type As %String
	#dim listPos, listNeg As %List
	#dim attributes As %String
	
	Try {
		set name = ..config.classifierName
		
		if (..config.classifierType = "lda") {
			set lda = ##class(%DeepSee.extensions.utils.LDA).NameIdxOpen(name, -1, .sc)
			Quit:$$$ISERR(sc)
			
			set sc = lda.GetMajorContributors(..config.TargetValue, ..config.TargetValue2, ..config.Margin, .listPos, .listNeg)
			Quit:$$$ISERR(sc)
			
		} else {
			set sc = $$$ERROR($$$GeneralError, "Not yet implemented")
			Quit
		}
		
		set sc = ..getAttributes(.attributes)
		Quit:$$$ISERR(sc)
		
		set type = ..config.getType()
		if (type = "text") {
			set sc = ..TextReport(attributes, listPos, listNeg)
			Quit:$$$ISERR(sc)
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method TextReport(attributes As %String, listPos As %List, listNeg As %List) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		w "Principal contributors to main component:", !
		w "  Positive:", !
		set sc = ..PrintList(attributes, listPos)
		Quit:$$$ISERR(sc)
		
		w "  Negative:", !
		set sc = ..PrintList(attributes, listNeg)
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method PrintList(keywords As %String, list As %List, Output Top) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim n, i, k, idx, maxlen As %Integer
	#dim w As %Double
	#dim keyword, type As %String
	#dim p As %Integer
	#dim D
	#dim strict As %Boolean
	
	Try {
		set n = $ll(list)
		set strict = ..config.strict

		set maxlen = 0		
		for i=1:1:n {
			set k = $li($li(list,i),1)
			set keyword = $p(keywords,",",k)
			if ($l(keyword) > maxlen) {
				set maxlen = $l(keyword)
			}
		}
				
		for i=1:1:n {
			set k = $li(list,i)
			set w = $li(k,2) * 100
			set k = $li(k,1)
			set keyword = $p(keywords,",",k)
			set sc = ..GetFilteredData(keyword, .D)
			Quit:$$$ISERR(sc)
			
			
			set p = D(0)
			if (p > 0.55) {
				if (w > 0) {
					set Top(1,1) = $g(Top(1,1)) + 1
					set Top(1,1,Top(1,1)) = keyword
				} else {
					if (strict) {
						Continue
					}
					set Top(1,-1) = $g(Top(1,-1)) + 1
					set Top(1,-1,Top(1,-1)) = keyword
				}
			} elseif (p < 0.45) {
				if (w > 0) {
					if (strict) {
						Continue
					}
					set Top(-1,1) = $g(Top(-1,1)) + 1
					set Top(-1,1,Top(-1,1)) = keyword
				} else {
					set Top(-1,-1) = $g(Top(-1,-1)) + 1
					set Top(-1,-1,Top(-1,-1)) = keyword
				}
			}
			
			set type = ..config.getType()
			if (type = "text") {
				set sc = ..outputText(i, k, maxlen, keyword, w, .D)
			} elseif (type = "html") {
				set sc = ..outputHTML(i, maxlen, keyword, w, .D)
			} else {
				set sc = ..outputCSV(i, maxlen, keyword, w, .D)
			}
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getAttributes(Output values As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set values =  $parameter(..config.ClassifierClass,"AttributeValues")
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod outputText(i As %Integer, k As %Integer, maxlen As %Integer, keyword As %String, w As %Double, ByRef D) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim idx As %Integer
	
	Try {
		
			w $j(i,3)_"/"_$j(k,3)_": "_keyword_$j(": ", maxlen - $l(keyword) + 2)_$c(9)_$fn(w,"",2)_"%"
			
			if ($d(D) > 1) {
				for idx = 0:1:2 {
					w $j($fn(D(idx),"",2),6)
				}
				for idx = 3:1:6 {
					w $j(D(idx),6)
				}
			}
			w !
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod outputCSV(file As %File, i As %Integer, maxlen As %Integer, keyword As %String, w As %Double, ByRef D) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim idx As %Integer
	
	Try {
		set sc = file.Write($j(i,3)_", "_keyword_$j(", ", maxlen - $l(keyword) + 2)_$c(9)_$fn(w,"",2)_"%"_",")
		Quit:$$$ISERR(sc)
		if ($d(D) > 1) {
			for idx = 0:1:2 {
				set sc = file.Write($j($fn(D(idx),"",2),6)_",")
				Quit:$$$ISERR(sc)
			}
			Quit:$$$ISERR(sc)
			for idx = 3:1:6 {
				set sc = file.Write($j(D(idx),6)_",")
				Quit:$$$ISERR(sc)
			}
			Quit:$$$ISERR(sc)
		}
		set sc = file.WriteLine()
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod openHTML(file As %File, conf As %DeepSee.extensions.iKnow.conf.Config) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim data As %DeepSee.extensions.iKnow.conf.Data = conf.data
	#dim model As %DeepSee.extensions.iKnow.conf.Model = conf.model
	#dim clf As %DeepSee.extensions.iKnow.conf.Classifier = conf.classifier
	
	#dim title, t As %String
	
	Try {
		set title = "Domain "_data.Domain_" Analysis Report"
		set t = clf.TargetValue
		
		set sc = file.WriteLine("<html>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<head>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<title>"_title_"</title>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</head>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<body>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<center><h1>"_title_"</h1></center>")
		Quit:$$$ISERR(sc)
		set title = "The Most Relevant Entities and CRC Patterns to recognize sources where "
		set title = title_model.MDField_ " has value of "_t
		set sc = file.WriteLine("<center><h2>"_title_"</h2></center>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<h3>Tables:</h3>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<ul>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<li><a href = '#Positive Contributions'>Positive Contributions</a></li>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<li><a href = '#Negative Contributions'>Negative Contributions</a></li>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<li><a href = '#ToTable'>Comaprative Influences of Patterns for Discriminanat and Frequency Analysis</a></li>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</ul>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<a href = '#Legend'>Explanation of Table Columns</a>")
		Quit:$$$ISERR(sc)
		
		set sc = ..writeHTMLTableHeader(file, "Positive Contributions", t)
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod writeHTMLTopTable(file As %File, ByRef Top) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim Cell
	
	Try {
		set sc = file.WriteLine("<table border = '1' cellspacing = '2' cellpadding = '2'>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<caption><em>Comparative Influences for Discriminant and Frequency Based Approach</em></caption>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<a name = 'TopTable'/>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<tr>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<th></th>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<th>Positive Frequency Influence</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Negative Frequency Influence</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</tr>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<tr>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<th>Positive Discriminant Influence</th>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<td>")
		Quit:$$$ISERR(sc)
		
		m Cell = Top(1,1)
		set sc = ..writeHTMLTopTableCell(file, .Cell)
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</td>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<td>")
		Quit:$$$ISERR(sc)
		
		k Cell
		m Cell = Top(-1,1)
		set sc = ..writeHTMLTopTableCell(file, .Cell)
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</td>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("</tr>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<tr>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<th>Negative Discriminant Influence</th>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<td>")
		Quit:$$$ISERR(sc)
		
		k Cell
		m Cell = Top(1,-1)
		set sc = ..writeHTMLTopTableCell(file, .Cell)
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</td>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<td>")
		Quit:$$$ISERR(sc)
		
		k Cell
		m Cell = Top(-1,-1)
		set sc = ..writeHTMLTopTableCell(file, .Cell)
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</td>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("</tr>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</table>")
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod writeHTMLTopTableCell(file As %File, ByRef Top) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, n As %Integer
	
	
	Try {
		if ($d(Top) = 0) {
			Quit
		}
		set sc = file.WriteLine("<ul>")
		Quit:$$$ISERR(sc)

		set n = Top
		for i = 1:1:n {
			set sc = file.Write("<li>")
			Quit:$$$ISERR(sc)

			set sc = file.Write(Top(i))
			Quit:$$$ISERR(sc)
			
			set sc = file.WriteLine("</li>")
			Quit:$$$ISERR(sc)
		}
		

		set sc = file.WriteLine("</ul>")
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod writeHTMLTableLegend(file As %File, target As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = file.WriteLine("<a name = 'Legend'/>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<h3>Explanation of Table Columns:</h3>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<dl>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<dt>Concept or CRC</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Entity of type Concept or CRC Pattern used in classification. CRC patterns are presented in the form of <em>master~relation~slave</em></dd>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<dt>Contribution</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Contribution of given <em>Entitiy or CRC Pattern</em> in classification formula</dd>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<dt>P("_target_"|Concept)</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Conditional probability of a source having target value "_target_" if it includes given <em>Entitiy or CRC Pattern</em> </em></dd>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<dt>SDiff</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Weighted difference between spreads of the given <em>Entitiy or CRC Pattern</em> in sources with and without value "_target_"</dd>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<dt>FDiff</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Weighted difference between frequencies of the given <em>Entitiy or CRC Pattern</em> in sources with and without value "_target_"</dd>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<dt>Spread("_target_")</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Spread of the given <em>Entitiy or CRC Pattern</em> in sources with the metdata value of "_target_"</dd>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<dt>Spread(Not "_target_")</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Spread of the given <em>Entitiy or CRC Pattern</em> in sources with other metdata values (Not "_target_")</dd>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<dt>Freq("_target_")</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Frequency of the given <em>Entitiy or CRC Pattern</em> in sources with the metdata value of "_target_"</dd>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<dt>Freq(Not "_target_")</dt>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<dd>Frequency of the given <em>Entitiy or CRC Pattern</em> in sources with other metdata values (Not "_target_")</dd>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("</dl>")
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod writeHTMLTableHeader(file As %File, title As %String, target As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = file.WriteLine("<table border = '1' cellspacing = '2' cellpadding = '2'>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<caption><em>"_title_"</em></caption>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<a name = '"_title_"'/>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<tr>")
		Quit:$$$ISERR(sc)

		set sc = file.WriteLine("<th>#</th>")
		Quit:$$$ISERR(sc)
		
		set sc = file.WriteLine("<th>Concept or CRC</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Contribution</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>P("_target_"|Concept)</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>SDiff</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>FDiff</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Spread("_target_")</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Spread(Not "_target_")</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Freq("_target_")</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<th>Freq(Not "_target_")</th>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</tr>")
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod closeHTML(file As %File) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = file.WriteLine("</body>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</html>")
		Quit:$$$ISERR(sc)

		d file.Close()
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method outputHTML(i As %Integer, maxlen As %Integer, keyword As %String, w As %Double, ByRef D) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim idx As %Integer
	#dim file As %File
	
	Try {
		set file = ..file
		
		set sc = file.WriteLine("<tr>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<td>"_i_"</td>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<td>"_keyword_"</td>")
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("<td>"_$fn(w,"",2)_"%</td>")
		Quit:$$$ISERR(sc)
		
		for idx = 0:1:2 {
			set sc = file.WriteLine("<td>"_$fn(D(idx),"",2)_"</td>")
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
		for idx = 3:1:6 {
			set sc = file.WriteLine("<td>"_D(idx)_"</td>")
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
		set sc = file.WriteLine("</tr>")
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetFilteredData(entity As %String, Output D) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s1, s0, f1, f0, N1, N0 As %Integer = 0
	#dim ds, df, bayes As %Double = 0

	Try {
		set bayes = 0.5
		
		set D(0) = bayes
		set D(1) = ds
		set D(2) = df
		set D(3) = s1
		set D(4) = f1
		set D(5) = s0
		set D(6) = f0
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

}
