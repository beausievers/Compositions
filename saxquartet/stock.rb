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