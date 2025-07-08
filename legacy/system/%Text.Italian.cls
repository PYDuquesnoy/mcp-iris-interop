/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.Italian</CLASS> class implements the Italian language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.Italian Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 5;

Parameter SOURCELANGUAGE = "it";

Parameter NOISEWORDS100 = "di a e a in è esso voi quello lui era per su sia con As I suo sia uno abbia ciò da o ha avuto da caldo parola ma che cosa alcuni noi latta verso l'esterno altro erano tutti là quando su usi vostro come detto ciascuno lei quale loro tempo se volontà senso circa molti allora loro scriva come così questi lei lungo faccia cosa veda lui due ha sguardo più giorno potrebbe vada venuto numero suono no maggior parte gente mio sopra sappia acqua che chiamata primo luogo chi possa giù lato stato ora ritrovamento c'è ne nuovo lavoro parte introito ottenga posto";

Parameter NOISEWORDS200 = "fatto tensione dove dopo parte posteriore poco soltanto rotondo uomo anno venuto esposizione ogni buon me give nostro sotto nome molto attraverso appena forma frase grande pensi opinione aiuto basso linea differisca girata causa molto media prima movimento destra ragazzo vecchio anche stessi dica insieme tre desideri aria pozzo anche gioco piccolo estremità messo domestico colto mano orificio grande periodo aggiunga livelli terra qui mosto grande alto tali segua atto perchè chieda uomini cambiamento è andato luce gentile fuori bisogno casa immagine prova noi ancora animale punto madre mondo vicino configurazione auto terra padre testa basamento possedere pagina se paese trovato risposta scuola sviluppisi";

Parameter NOISEWORDS300 = "studio ancora impari pianta copertura alimento sole quattro fra dichiari conservazione occhio mai ultimo lasciato pensiero città albero traversa podere duro inizio forza storia sega lontano mare tiraggio di sinistra in ritardo funzionamento non mentre pressa fine notte reale vita pochi del nord aperto sembri insieme dopo bianco bambini cominci ottenuto camminata esempio facilità carta gruppo sempre musica quelli entrambi contrassegno spesso lettera fino a miglio fiume automobile piedi cura secondo luogo libro trasporti ha preso scienza mangi stanza amico ha cominciato idea pesci montagna arresto volta base sentasi cavallo taglio sicuro vigilanza colore faccia legno principale abbastanza pianura ragazza usuale giovane aspetti sopra mai rosso lista benchè";

/// [Previously private]
ClassMethod removeAllAccents(ByRef b As %String, ByRef k As %Integer)
{
	s b=$tr(b,"àáâäèéêëòóôöùúûüìíîïÁÉÍÓÒÚ","aaaaeeeeoooouuuuiiiiAEIOOU")
}

/// Simple Italian stemmer.  See http://www.unine.ch/info/clef/italianStemmer.txt
/// [Previously private]
ClassMethod stemWord(ByRef b As %String) As %String
{
	s k = $l(b)
	s j=""
	do ..removeAllAccents(.b, .k)
	quit:k<=5 b				; don't stem if the word has length <= 5
	
	if (    ..ends(b, k, 2,  "ie", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 2,  "he", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 1,   "e", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 2,  "ii", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 2,  "hi", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 1,   "i", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 2,  "ia", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 1,   "a", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 2,  "io", .j)) { d ..setto(.b, "", j, .k) }
	elseif (..ends(b, k, 1,   "o", .j)) { d ..setto(.b, "", j, .k) }

	s b=$e(b,1,k)
	quit b
}

}
