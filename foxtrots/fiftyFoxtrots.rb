#
# Beau Sievers
# Hanover, 2009
#
# Deeply indebted to 
# A Revised Grammar for the Foxtrot
# by Don Herbison-Evans
# http://donhe.topcities.com/pubs/foxtrot.html
#

require 'pp'

class Terminal
  attr_accessor :str
  
  def initialize(str)
    @str = str
  end
  
  def to_s
    @str
  end
end

class Optional
  attr_accessor :optArray
  
  def initialize(optArray)
    @optArray = optArray
  end
  
  def to_s
    out = '['
    optArray.each_index do |i|
      opt = optArray[i]
      if opt.class==Terminal or opt.class==Optional
        out += "#{opt.to_s}, " if i < optArray.length-1
        out += "#{opt.to_s}]" if i >= optArray.length-1
      elsif opt.class==Array
        out += '['
        opt.each_index do |j|
          item = opt[j]
          out += "#{item.to_s}"
          out += ', ' if j < opt.length-1
          out += ']' if j >= opt.length-1
        end
        out += ', ' if i< optArray.length-1
      end
    end
    out
  end
end

class Sentence
  attr_accessor :wordArray
  
  def initialize(wordArray)
    @wordArray = wordArray
  end
  
  def to_s
    out = ''
    @wordArray.each do |word|
      out += "#{word.to_s}"
      out += ' ' if @wordArray.index(word) < @wordArray.length-1
    end
    out
  end
  
  def indexOfFirstOptional
    classArray = @wordArray.map {|x| x.class}
    classArray.index(Optional)
  end
end

def processSentenceArray(sentenceAr)
  # while some of the sentences have optionals, iterate across the array
  while !sentenceAr.inject(true) {|a,b| a && isAllTerminals?(b)} do
    sentenceAr.each_index do |i|
      sentence = sentenceAr[i]
      # if the sentence has at least one optional, process it
      optIndex = sentence.indexOfFirstOptional
      if optIndex != nil
        word = sentence.wordArray[optIndex]
        word.optArray.each do |option|
          newSentence = Sentence.new(sentence.wordArray.clone)
          
          # if the option is another optional or a terminal, then create a new
          # sentence with the option replacing the word
          if option.class == Terminal or option.class == Optional
            newSentence.wordArray[optIndex] = option
            
          # if the option is an array, i.e. a sequenece of terminals/optionals
          # create a new sentence with that sequence inserted in place of the word
          elsif option.class == Array
            newSentence.wordArray.delete_at(optIndex)
            option.reverse.each do |item|
              newSentence.wordArray.insert(optIndex,item)
            end
          end
          
          # add the new sentence to the sentence array
          sentenceAr.push(newSentence.clone)
        end
        #delete the original sentence
        sentenceAr.delete(sentence)
      end
    end
  end
  sentenceAr
end

def isAllTerminals?(sentence)
  sentence.wordArray.inject(true) {|a,b| a && isTerminal?(b)}
end

def isTerminal?(word)
  word.class==Terminal
end

def printSentences(sentenceAr)
  sentenceAr.each do |s|
    print s.to_s + "\n"
  end
end

$lsnf = Terminal.new("lsnf")
$lsns = Terminal.new("lsns")
$lsnb = Terminal.new("lsnb")
$lsnc = Terminal.new("lsnc")
$lstf = Terminal.new("lstf")
$lsts = Terminal.new("lsts")
$lstb = Terminal.new("lstb")
$lstc = Terminal.new("lstc")
$rsnf = Terminal.new("rsnf")
$rsns = Terminal.new("rsns")
$rsnb = Terminal.new("rsnb")
$rsnc = Terminal.new("rsnc")
$rstf = Terminal.new("rstf")
$rsts = Terminal.new("rsts")
$rstb = Terminal.new("rstb")
$rstc = Terminal.new("rstc")
                      
$lqnf = Terminal.new("lqnf")
$lqns = Terminal.new("lqns")
$lqnb = Terminal.new("lqnb")
$lqnc = Terminal.new("lqnc")
$lqtf = Terminal.new("lqtf")
$lqts = Terminal.new("lqts")
$lqtb = Terminal.new("lqtb")
$lqtc = Terminal.new("lqtc")
$rqnf = Terminal.new("rqnf")
$rqns = Terminal.new("rqns")
$rqnb = Terminal.new("rqnb")
$rqnc = Terminal.new("rqnc")
$rqtf = Terminal.new("rqtf")
$rqts = Terminal.new("rqts")
$rqtb = Terminal.new("rqtb")
$rqtc = Terminal.new("rqtc")

# lsc ::= lsnc | lstc
# rsc ::= rsnc | rstc
# lqc ::= lqnc | lqtc
# rqc ::= rqnc | rqtc
# 
# lqs ::= lqns | lqts
# rqs ::= rqns | rqts

lsc = Optional.new([$lsnc,$lstc])
rsc = Optional.new([$rsnc,$rstc])
lqc = Optional.new([$lqnc,$lqtc])
rqc = Optional.new([$rqnc,$rqtc])
lqs = Optional.new([$lqns,$lqts])
rqs = Optional.new([$rqns,$rqts])

# lsn ::= lsnf | lsns | lsnb
# rsn ::= rsnf | rsns | rsnb
# lst ::= lstf | lsts | lstb
# rst ::= rstf | rsts | rstb
# lqn ::= lqnf | lqns | lqnb
# rqn ::= rqnf | rqns | rqnb
# lqt ::= lqtf | lqts | lqtb
# rqt ::= rqtf | rqts | rqtb

lsn = Optional.new([$lsnf,$lsns,$lsnb])
rsn = Optional.new([$rsnf,$rsns,$rsnb])
lst = Optional.new([$lstf,$lsts,$lstb])
rst = Optional.new([$rstf,$rsts,$rstb])
lqn = Optional.new([$lqnf,$lqns,$lqnb])
rqn = Optional.new([$rqnf,$rqns,$rqnb])
lqt = Optional.new([$lqtf,$lqts,$lqtb])
rqt = Optional.new([$rqtf,$rqts,$rqtb])

# LS ::= LSN | LST
# RS ::= RSN | RST
# LQ ::= LQN | LQT
# RQ ::= RQN | RQT

ls = Optional.new([lsn,lst])
rs = Optional.new([rsn,rst])
lq = Optional.new([lqn,lqt])
rq = Optional.new([rqn,rqt])

# lqsc ::= lq + rsc
# rqsc ::= rq + lsc
# lqqc ::= lq + rqc
# rqqc ::= rq + lqc

lqsc = Optional.new([[lq,rsc]])
rqsc = Optional.new([[rq,lsc]])
lqqc = Optional.new([[lq,rqc]])
rqqc = Optional.new([[rq,lqc]])

# lqr ::= lq + rq | lq + rqc
# rql ::= rq + lq | rq + lqc

lqr = Optional.new([[lq,rq],[lq,rqc]])
rql = Optional.new([[rq,lq],[rq,lqc]])

# l1l ::= ls + rs | lqr + lqr | ls + rsc
# r1r ::= rs + ls | rql + rql | rs + lsc
# l1r ::= ls + rql | lqr + ls | lq + rqsc | ls + rqqc
# r1l ::= rs + lqr | rql + rs | rq + lqsc | rs + lqqc

l1l = Optional.new([[ls,rs],[lqr,lqr],[ls,rsc]])
r1r = Optional.new([[rs,ls],[rql,rql],[rs,lsc]])
l1r = Optional.new([[ls,rql],[lqr,ls],[lq,rqsc],[ls,rqqc]])
r1l = Optional.new([[rs,lqr],[rql,rs],[rq,lqsc],[rs,lqqc]])

# l2l ::= l1l + l1l | l1r + r1l
# r2r ::= r1l + l1r | r1r + r1r
# l2r ::= l1l + l1r | l1r + r1r
# r2l ::= r1l + l1l | r1r + r1l

l2l = Optional.new([[l1l,l1l],[l1r,r1l]])
r2r = Optional.new([[r1l,l1r],[r1r,r1r]])
l2r = Optional.new([[l1l,l1r],[l1r,r1r]])
r2l = Optional.new([[r1l,l1l],[r1r,r1l]])

# l4l ::= l2l + l2l | l2r + r2l
# l4r ::= l2l + l2r | l2r + r2r
# r4l ::= r2r + r2l | r2l + l2l

l4l = Optional.new([[l2l,l2l],[l2r,r2l]])
l4r = Optional.new([[l2l,l2r],[l2r,r2r]])
r4l = Optional.new([[r2r,r2l],[r2l,l2l]])

# l8l ::= l4l + l4l | l4r + r4l

l8l = Optional.new([[l4l,l4l],[l4r,r4l]])


########## STRUCTURAL ELEMENTS ###############

sl1l = Terminal.new("l1l")
sr1r = Terminal.new("r1r")
sl1r = Terminal.new("l1r")
sr1l = Terminal.new("r1l")

# l2l ::= l1l + l1l | l1r + r1l
# r2r ::= r1l + l1r | r1r + r1r
# l2r ::= l1l + l1r | l1r + r1r
# r2l ::= r1l + l1l | r1r + r1l

sl2l = Optional.new([[sl1l,sl1l],[sl1r,sr1l]])
sr2r = Optional.new([[sr1l,sl1r],[sr1r,sr1r]])
sl2r = Optional.new([[sl1l,sl1r],[sl1r,sr1r]])
sr2l = Optional.new([[sr1l,sl1l],[sr1r,sr1l]])

# l4l ::= l2l + l2l | l2r + r2l
# l4r ::= l2l + l2r | l2r + r2r
# r4l ::= r2r + r2l | r2l + l2l

sl4l = Optional.new([[sl2l,sl2l],[sl2r,sr2l]])
sl4r = Optional.new([[sl2l,sl2r],[sl2r,sr2r]])
sr4l = Optional.new([[sr2r,sr2l],[sr2l,sl2l]])

# l8l ::= l4l + l4l | l4r + r4l

sl8l = Optional.new([[sl4l,sl4l],[sl4r,sr4l]])

$xStructures = processSentenceArray([Sentence.new([sl8l])])
$xl1l = processSentenceArray([Sentence.new([l1l])])
$xr1r = processSentenceArray([Sentence.new([r1r])])
$xl1r = processSentenceArray([Sentence.new([l1r])])
$xr1l = processSentenceArray([Sentence.new([r1l])])

def randomFromArray(anArray)
  anArray[rand(anArray.length)]
end

def al1l; randomFromArray($xl1l); end;
def ar1r; randomFromArray($xr1r); end;
def al1r; randomFromArray($xl1r); end;
def ar1l; randomFromArray($xr1l); end;

def randomFoxtrot
  theStructure = randomFromArray($xStructures).to_s.split(' ').map{|x| 'a'+x}
  sentenceArray = []
  inverseSentenceArray = []
  theStructure.each do |x| 
    theLine = eval(x)
    sentenceArray.push theLine
    inverseSentenceArray.push invertFoxtrotSentence(theLine)
  end

  puts "\nNormal: "
  sentenceArray.each do |sent|
    puts sent.to_s
  end
  puts sentenceArrayToLilypond(sentenceArray)
  
  puts "\nInverted: "
  inverseSentenceArray.each do |sent|
    puts sent.to_s
  end
  puts sentenceArrayToLilypond(inverseSentenceArray,-1)
end

def invertFoxtrotSentence(sentence)
  newSentence = []
  sentence.wordArray.each do |word|
    #puts word
    newWord = case word
      when $lsnf : $rsnb
      when $lsns : $rsns
      when $lsnb : $rsnf
      when $lsnc : $rsnc
      when $lstf : $rstb
      when $lsts : $rsts
      when $lstb : $rstf
      when $lstc : $rstc
      when $rsnf : $lsnb
      when $rsns : $lsns
      when $rsnb : $lsnf
      when $rsnc : $lsnc
      when $rstf : $lstb
      when $rsts : $lsts
      when $rstb : $lstf
      when $rstc : $lstc
        
      when $lqnf : $rqnb
      when $lqns : $rqns
      when $lqnb : $rqnf
      when $lqnc : $rqnc
      when $lqtf : $rqtb
      when $lqts : $rqts
      when $lqtb : $rqtf
      when $lqtc : $rqtc
      when $rqnf : $lqnb
      when $rqns : $lqns
      when $rqnb : $lqnf
      when $rqnc : $lqnc
      when $rqtf : $lqtb
      when $rqts : $lqts
      when $rqtb : $lqtf
      when $rqtc : $lqtc
    end
    newSentence.push newWord
    #puts newWord
  end
  out = Sentence.new(newSentence)
  #puts out.to_s
  out
end

def sentenceArrayToLilypond(sentenceArray,direction=1)
  outAll = ''
  dynamic = ''
  sentenceArray.each do |sentence|
    sentence.wordArray.each do |word|
      out = ''
      #puts word.str
      if word.to_s[3,1] == 'c' then closing = true else closing = false end
      out += ' \cross ' if closing == true
      out += 'a'
      out += '8' if word.to_s[1,1] == 'q'
      out += '4' if word.to_s[1,1] == 's'
      if word.to_s[3,1] == 'f'
        if dynamic != '\f'
          dynamic = '\f'
          out += dynamic
        end
      elsif word.to_s[3,1] == 's'
        if dynamic != '\mf'
          dynamic = '\mf'
          out += dynamic
        end
      elsif word.to_s[3,1] == 'b'
        if dynamic != '\p'
          dynamic = '\p'
          out += dynamic
        end
      end
      direction = direction * -1 if word.to_s[2,1] == 't'
      out += '\down' if direction == -1 unless closing == true
      out += '\up' if direction == 1 unless closing == true
      #out += ' ^"L" ' if word.to_s[0,1] == 'l'
      #out += ' ^"R" ' if word.to_s[0,1] == 'r'
    
      out += ' \slash ' if closing == true
      out += ' '
      outAll += out
      #puts out
    end
    outAll += "\n"
  end
  outAll
end

$lilyheader = "up = ^\\markup{\\fontsize #3 ↑}
down = ^\\markup{\\fontsize #3 ↓}
cross = \\override NoteHead #'style = #'cross
slash = \\override NoteHead #'style = #'slash
#(define num 1)
"

$lilyfooter = "\n\\version \"2.8.0\""

$partheader = "\\bookpart {

	\\header{
	  title = \"Foxtrot "
	  	  
$partheader2 = "\"
	  tagline = ##f
	}

	\\new StaffGroup <<
		\\new RhythmicStaff {
			\\set Staff.instrumentName = #\"Lead \"
			\\set Staff.shortInstrumentName = #\"Ld \"
			\\time 2/4
			\\slash
"

$partmiddle = "	\\bar \"|.\"
}

\\new RhythmicStaff {
	\\set Staff.instrumentName = #\"Follow \"
	\\set Staff.shortInstrumentName = #\"Fol \"

	\\time 2/4
	\\slash
"

$partfooter = "		}
	>>
}"

def fiftyFoxtrots
  theFile = File.open("foxtrotCollection.ly",'w')
  theFile.write($lilyheader)
    
  (1..50).to_a.each do |i|
    sentenceArray = []
    inverseSentenceArray = []
    6.times do 
      theStructure = randomFromArray($xStructures).to_s.split(' ').map{|x| 'a'+x}
      theStructure.each do |x|
        theLine = eval(x)
        sentenceArray.push theLine
        inverseSentenceArray.push invertFoxtrotSentence(theLine)
      end
    end
    theFile.write($partheader)
    theFile.write(i)
    theFile.write($partheader2)
    theFile.write(sentenceArrayToLilypond(sentenceArray))
    theFile.write($partmiddle)
    theFile.write(sentenceArrayToLilypond(inverseSentenceArray,-1))
    theFile.write($partfooter)
  end
  
  theFile.write($lilyfooter)
  theFile.close
end

def singleExample
  sentenceArray = []
  inverseSentenceArray = []
  theStructure = randomFromArray($xStructures).to_s.split(' ').map{|x| 'a'+x}
  theStructure.each do |x|
    theLine = eval(x)
    sentenceArray.push theLine
    inverseSentenceArray.push invertFoxtrotSentence(theLine)
  end
  
  puts "\nNormal: "
  sentenceArray.each do |sent|
    puts sent.to_s
  end
  puts sentenceArrayToLilypond(sentenceArray)
  
  puts "\nInverted: "
  inverseSentenceArray.each do |sent|
    puts sent.to_s
  end
  puts sentenceArrayToLilypond(inverseSentenceArray,-1)
end

singleExample

#printSentences(all)
#pp all.length