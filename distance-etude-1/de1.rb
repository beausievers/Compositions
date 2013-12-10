require '../MM/mm.rb'
require '../PCSet/pcset.rb'
require '../random.rb'

# Preliminary definitions. Eventually should break this stuff
# off into another library.

$pitch_classes      = %w(c c# d d# e f f# g g# a a# b)
$pitch_classes_lily = %w(c cis d dis e f fis g gis a ais b)

def midi_to_pitch(midi_note_number)
  pitch_class = $pitch_classes[(midi_note_number % 12)]
  octave = (midi_note_number / 12) - 1
  "#{pitch_class}#{octave}"
end

def midi_to_lily(midi_note_number)
  return midi_note_number if(midi_note_number.class == String)
  pitch_class = $pitch_classes_lily[(midi_note_number % 12)]
  octave = (midi_note_number / 12) - 4
  octave_string = ''
  if(octave > 0)
    1.upto(octave) do
      octave_string += "'"
    end
  elsif(octave < 0)
    -1.downto(octave) do
      octave_string += ","
    end
  end
  "#{pitch_class}#{octave_string}"
end


#
# Let's create a morph in consonance space.
#
# First, let's define a consonance delta function based on Huron,
# where more dissonant intervals are understood to be further apart:
#
huron = ->(a, b) {
  #              U       m2/M7   M2/m7  m3/M6  M3/m6  P4/P5   A4/d5
  huronTable = [ 0,   -1.428, -0.582, 0.594, 0.386, 1.240, -0.453 ]
  output = (a.to_i - b.to_i).abs
  return huronTable[MM.interval_class(output, 12)] if output.class == Fixnum
  output.collect { |x| huronTable[MM.interval_class(x, 12)] }
}

$huron = huron

def huron_check(v)
  v_combo = MM.ordered_2_combinations(v.to_a.uniq)
  NArray.to_na(v_combo.map {|a,b| $huron.call(a,b)}).sum
end

none = MM::DistConfig.new
none.scale = "none"
none.intra_delta = huron

ucm_no_dup = ->(v1, v2, config) {
  v1 = NArray.to_na(v1.to_a.uniq!)
  v2 = NArray.to_na(v2.to_a.uniq!)
  MM.ucm.call(v1, v2, config)
}
$ucm_no_dup = ucm_no_dup

m = NArray[0,3,5,7,10]
n = NArray[0,1,2,3,4]
o = NArray[12,13,14,15,16]

# Test it out...
# Old: MM.metric_path(m, n, MM.ucm, none, 10, 0.5, true)
# Not a a good test: MM.metric_path(:v1 => m, :v2 => n, :metric => MM.ucm, :euclidean_tightness => 0.5)

################
#              #
################

all_interval = NArray[60, 61, 62, 64, 67, 68, 72]

ode_to_napolean = NArray[60, 61, 64, 65, 68, 69, 72]

# spelling is key = C   Bb  B   F   Gb  A
schoenberg = NArray[60, 61, 62, 65, 66, 69] #, 72]

start = NArray[36, 43, 48, 55, 62, 69] #, 76]    # Open strings across all instruments
middle = schoenberg
ending = NArray[107, 102,97,92,87,82] #,77]       # 4ths in the upper register
ending_lower = ending - 12

path1 = MM.metric_path(start, middle, MM.ucm, none, 5, 0.05, false, false)
path2 = MM.metric_path(middle, ending, MM.ucm, none, 4, 0.05, true, false)
$path = path1 + path2
path_pitches = $path.to_a.map {|na| na.to_i.to_a.sort.map {|note| midi_to_pitch(note)}}
$path.each { |path| 
  set = PCSet.new(path.to_i.to_a)
  puts "#{huron_check(path).round(3)}\t#{MM.ucm.call($path, ending, none).round(3)}\t#{set.intervalVector}\t#{set.huron.to_s}"
}



def write_lilypond(v1, v2, vla, cl, filename = 'test.ly')
  outfile = File.open(filename, 'w')
  $stdout = outfile
  puts %(
\\version "2.14.2"
\\paper {
  #(set-paper-size "11x17" 'portrait)
  system-system-spacing #'minimum-distance = #12
}
\\header { 
  tagline = ""
}

\\score {
  \\new StaffGroup <<
  #(set-accidental-style 'neo-modern 'StaffGroup)
  	\\new Staff { \\set Timing.defaultBarType = "'" \\time 10/16 #{v1} }
  	\\new Staff { #{v2} }
  	\\new Staff {
  	  \\clef alto
  	  #{vla}
  	}
  	\\new Staff {
  	  \\clef bass
  	  #{cl}
  	}
  >>
  
  \\midi {
    \\context {
      \\Score
      tempoWholesPerMinute = #(ly:make-moment 135 4)
    }
  }
  
  \\layout {
    indent = #0
    ragged-right = ##t
    tupletFullLength = ##t
    \\context {
      \\Score
        proportionalNotationDuration = #(ly:make-moment 1 28)
        \\override SpacingSpanner #'strict-note-spacing = ##t
        \\override SpacingSpanner #'strict-grace-spacing = ##t
        \\override SpacingSpanner #'uniform-stretching = ##t
    }
    \\context {
      \\Staff
        \\remove Time_signature_engraver
    }
    \\context {
      \\Voice
        \\remove Stem_engraver
        \\remove Beam_engraver
        \\remove Forbid_line_break_engraver
    }
  }
}
)
  $stdout = STDOUT
  outfile.close
end

def generate_score(filename = 'test.ly')
  violin_1_range = [55, 107]
  violin_2_range = violin_1_range
  viola_range = [48, 98]
  cello_range = [36, 82]
  ranges = [violin_1_range, violin_2_range, viola_range, cello_range]

  first_rest_string = 's16 '
  rest_string = 's '
  
  # Create a density map first, and then assign
  # specific notes in accord with the density map.
  num_frames = 180
  densities  = Array.new(num_frames * $path.size).fill(0)
  max_notes  = 4
  num_notes  = 46
  sd         = 13

  $path.each_with_index do |subpath, path_index|
    num_notes.times do |i|
      begin
        index = gaussian_in_range(num_frames * 0.5, sd, 0, num_frames - 1) + (path_index * num_frames)
      end while densities[index] >= max_notes
      densities[index] += 1
    end
  end
  
  violin_1, violin_2, viola, cello = '', '', '', ''
  quartet = [violin_1, violin_2, viola, cello]

  densities.each_with_index do |density, index|
    if (index % num_frames == 0)
      quartet.each { |ins| ins << "\n\n% Section #{index / num_frames}\n\n"}
    end
    if density == 0
      quartet.each { |ins| ins << (index == 0 ? first_rest_string : rest_string) }
    else
      subpath = $path[index / num_frames]
      begin
        notes = []
        v1_note, v2_note, viola_note, cello_note = [], [], [], []
        all_notes = [v1_note, v2_note, viola_note, cello_note]
        density.times do notes << subpath.to_a.sample.to_i end
        notes.sort.each do |note|
          if note < viola_range[0]    
            # if it's too low for viola...
            cello_note << note if cello_note.size == 0
          elsif note < violin_1_range[0] && note <= cello_range[1] && note <= viola_range[1]
            # if it's too low for the violin, and the cello or viola could get it...
            if cello_note.size == 0     # try the cello
              cello_note << note
            elsif viola_note.size == 0  # then try the viola
              viola_note << note
            end
          elsif note < violin_1_range[0] && note > cello_range[1]   # too low for violin, too high for cello...
            viola_note << note if viola_note.size == 0
          elsif note > viola_range[1]   # too high for viola
            violins = [v1_note, v2_note].shuffle
            a_violin = violins.pop
            the_other_violin = violins.pop
            if a_violin.size == 0
              a_violin << note
            elsif the_other_violin.size == 0
              the_other_violin << note
            end
          else
            tries = 0
            begin
              tries += 1
              index = rand(4)
              candidate = all_notes[index]
              range = ranges[index]
              if tries >= 40
                puts "BREAK"
                break
              end
            end while candidate.size != 0 
            candidate << note if note >= range[0] && note <= range[1]
          end
        end
        all_notes = [nil] if all_notes.flatten == []
      end while all_notes.flatten.map {|x| x.class == Fixnum ? 1 : 0}.inject(:+) < notes.length
      quartet.each_with_index do |ins, i|
        ins << (all_notes[i].size == 0 ? rest_string : midi_to_lily(all_notes[i][0]) + '16 ')
      end
    end
  end

  write_lilypond(violin_1, violin_2, viola, cello, filename)
end

def generate_n_versions(n)
  0.upto(n - 1) do |i|
    generate_score("test_#{i}.ly")
  end
end

=begin

  Play open strings when possible.
  Allow notes to decay naturally.

=end

