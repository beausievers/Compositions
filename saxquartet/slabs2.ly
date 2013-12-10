
\version "2.16.0"
\paper {
  top-margin = 1.25\in
  bottom-margin = 1.25\in
  system-system-spacing #'minimum-distance = #28
  ragged-last-bottom = ##f
  print-page-number = ##t
    print-first-page-number = ##t
    oddFooterMarkup = \markup \fill-line { " " }
    evenFooterMarkup = \markup \fill-line { " " }
    oddHeaderMarkup = \markup { {
       \bold \fontsize #3 \on-the-fly #print-page-number-check-first
       \fromproperty #'page:page-number-string } }
    evenHeaderMarkup = \markup { {
       \bold \fontsize #3 \on-the-fly #print-page-number-check-first
       \fromproperty #'page:page-number-string } }
}
\header { 
  tagline = ""
}

secondaryRecovery = {
  \stopStaff
  \once \override Staff.TimeSignature #'stencil = ##f
  \time 4/4
  s1
  \startStaff
}

\score {
  \new StaffGroup <<
  #(set-accidental-style 'neo-modern 'StaffGroup)
  	\new Staff \transpose c d { \time 4/4 
dis'1\mp^\markup{
\column{
\line {\italic "each removed tone/rest maximally changes the aggregate consonance of the chord."}
\line {\italic ""}
\line {\italic "slowly and carefully. no vibrato. read all rests precisely."}
\line {\italic "it is okay to pause between bars."}
}

} ais'1 c'1 b1 b1 c'1 dis'1 e'1 cis'1 fis'1 c'1 ais2 r2 a'1 a'1 a'1 cis''1 dis'1 fis'1 b'1 e''1 dis''1 cis'''1 g'1 f''1 d''1 g''1 gis''1 c'1 e''2 r2 ais''1 b''1 dis''2 r2 dis''1 g''1 cis''1 
  	}
  	
  	\new Staff \transpose c a { 
cis'1\mp gis'1 d'2 r2 f2 r2 dis'1 gis'1 d'1 f1 f'1 b1 dis'1 c''1 g2 r2 g'1 d''1 cis''1 b'1 gis''2 r2 a2 r2 gis''1 f1 f''1 f''1 cis1 ais1 fis''1 e2 r2 dis''1 gis'1 cis1 e'2 r2 fis''1 dis1 g''1 a''1  
  	}
  	
  	\new Staff \transpose c d' {
d'2\mp r2 a'2 r2 e'1 fis1 e'1 ais'2 r2 fis1 f'1 a'1 f'2 r2 d''2 r2 gis'1 cis'1 fis2 r2 dis'2 r2 a'1 cis2 r2 fis'1 dis''1 gis'1 b'1 fis'1 cis''1 d''2 r2 cis''2 r2 dis2 r2 fis'1 dis1 gis,1 e''2 r2 d''1 fis'1 b'2 r2 gis,1 a1 
  	}
  	
  	\new Staff \transpose c a' {
e'1\mp g'1 dis'1 g1 f'2 r2 a'1 e2 r2 fis'2 r2 dis'2 r2 a'1 fis'1 e'1 f1 e1 g1 g2 r2 b1 ais1 dis1 ais2 r2 cis2 r2 c'2 r2 dis2 r2 fis1 a,1 d'1 fis1 fis,2 r2 gis,1 cis'1 b,1 fis,1 dis,1 cis'2 r2 f,2 r2 \bar "|."
  	}
  >>
	
  \midi {
    \context {
      \Score
      tempoWholesPerMinute = #(ly:make-moment 60 4)
    }
  }
  
  \layout {
    indent = #0
    \context {
       \Score
       
       \override MultiMeasureRest #'Y-offset = #-17.5
       \override MultiMeasureRestText #'extra-offset = #'(0 . -17.5)
       \override TimeSignature #'break-visibility = #end-of-line-invisible
     }
  }
}

