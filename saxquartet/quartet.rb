require '../MM/mm.rb'
require '../PCSet/pcset.rb'
require '../random.rb'
require '../stock.rb'

$soprano_range = (56..87)
$alto_range    = (49..81)
$tenor_range   = (44..76)
$bari_range    = (36..69)

class Slab
  attr_accessor :notes
  
  def initialize
    s = Random.rand($soprano_range)
    a = Random.rand($alto_range)
    t = Random.rand($tenor_range)
    b = Random.rand($bari_range)
    @notes = [b, t, a, s]
  end
  
  def huron
    pc_slab = PCSet.new(@notes)
    pc_slab.huron[0]
  end
  
  def variations
    slabs = []
    @notes.each_index {|i|
      new_slab = @notes.clone
      new_slab.delete_at(i)
      slabs << new_slab
    }
    slabs
  end
  
  def variations_huron
    variations.map {|slab| 
      pcslab = PCSet.new(slab)
      pcslab.huron[0]
    }
  end
  
  def deltas
    variations_huron.map {|x| huron - x}
  end
  
  def abs_deltas
    deltas.map {|x| x.abs}
  end
  
  # TODO: Currently the .max method just grabs whichever max comes first in the case of duplicates; ideally we would grab one at random.
  def deltas_max_index
    abs_deltas.index(abs_deltas.max)
  end
  
  def deltas_max
    deltas[deltas_max_index]
  end
  
  def range
    @notes.max - @notes.min
  end
  
  def center
    @notes.max - (range / 2)
  end
  
  # tightness?
  def mean_note_difference
    differences = @notes.combination(2).to_a.map {|a, b| (a - b).abs}
    mean = differences.inject{ |sum, el| sum + el }.to_f / differences.size
    mean
  end
  
  # The index of the largest delta corresponds to:
  #   - The index ([b, t, a, s]) of the instrument to be removed to make the biggest 
  #     change in consonance
  #   - The index of the variation with the resultant pitches
  #
  # Positive deltas mean the clang became more dissonant, negative means it became 
  # more consonant.
  
  def render
    bari, tenor, alto, soprano = '', '', '', ''
    instrument_strings = [bari, tenor, alto, soprano]
    @notes.each_with_index {|note, index| 
      duration_string = '1'
      duration_string = '2' if index == deltas_max_index
      instrument_string = instrument_strings[index]
      note_string = midi_to_lily(note) + duration_string
      instrument_string << note_string
      instrument_string << ' r2' if index == deltas_max_index
    }
    instrument_strings
  end
  
  def stats
    {
      'notes' => @notes,
      'range' => range,
      'center' => center,
      'mean_note_difference' => mean_note_difference,
      'huron' => huron,
      'variations' => variations,
      'variations_huron' => variations_huron,
      'deltas' => deltas,
      'abs_deltas' => abs_deltas,
      'deltas_max_index' => deltas_max_index,
      'deltas_max' => deltas_max
    }
  end
end

def render_piece(pool_size = 10000, num_slabs = 35, filename = 'slabs.ly')
  slabs = []
  pool_size.times {
    slabs << Slab.new
  }
  
  slabs_mean_note_difference = slabs.map {|x| x.mean_note_difference}
  uniq_mean_note_difference = slabs_mean_note_difference.uniq.sort
  
  slabs_deltas_max = slabs.map {|x| x.deltas_max}
  uniq_deltas_max = slabs_deltas_max.uniq.sort
  
  slabs_range = slabs.map {|x| x.range}
  uniq_range = slabs_range.uniq.sort
    
  slab_index = 0
  
  winning_slabs = []
    
  while(slab_index < num_slabs)
    target_mean_note_difference = uniq_mean_note_difference[(uniq_mean_note_difference.size / num_slabs) * slab_index]
    target_deltas_max = uniq_deltas_max[(uniq_deltas_max.size / num_slabs) * slab_index]
    target_range = uniq_range[(uniq_range.size / num_slabs) * slab_index]
    
    mean_note_difference_tolerance = 3.5
    deltas_max_tolerance = 0.4
    range_tolerance = 7
    
    puts "target_mean_note_difference: #{target_mean_note_difference}"
    puts "target_deltas_max: #{target_deltas_max}"
    puts "target_range: #{target_range}"
    
    # Find slabs close our targets
    while true  # I'm crying
      candidate = Slab.new
      
      delta_ok = false
      tight_ok = false
      range_ok = false
      
      delta_ok = true if (candidate.deltas_max - target_deltas_max).abs < deltas_max_tolerance
      tight_ok = true if (candidate.mean_note_difference - target_mean_note_difference).abs < mean_note_difference_tolerance
      range_ok = true if (candidate.range - target_range).abs < range_tolerance
      
      break if(delta_ok && tight_ok && range_ok)
    end
    
    # Add the winner
    winning_slabs << candidate
    
    puts "winner mean_note_difference: #{candidate.mean_note_difference}"
    puts "winner deltas_max: #{candidate.deltas_max}"
    puts "winner range: #{candidate.range}"
    puts
    
    slab_index += 1
  end
  
  bari, tenor, alto, soprano = '', '', '', ''
  winning_slabs.each {|slab|
    instrument_strings = slab.render
    bari    << instrument_strings[0] + ' '
    tenor   << instrument_strings[1] + ' '
    alto    << instrument_strings[2] + ' '
    soprano << instrument_strings[3] + ' '
  }
  write_lilypond(soprano, alto, tenor, bari, filename)
  return(winning_slabs)
end

def write_lilypond(soprano, alto, tenor, bari, filename = 'slabs.ly')
  outfile = File.open(filename, 'w')
  $stdout = outfile
  puts %(
\\version "2.16.0"
\\paper {
  #(set-paper-size "8.5x11" 'portrait)
  top-margin = 1.25\\in
  bottom-margin = 1.25\\in
  system-system-spacing #'minimum-distance = #28
  ragged-last-bottom = ##f
  print-page-number = ##t
    print-first-page-number = ##t
    oddFooterMarkup = \\markup \\fill-line { " " }
    evenFooterMarkup = \\markup \\fill-line { " " }
    oddHeaderMarkup = \\markup { {
       \\bold \\fontsize #3 \\on-the-fly #print-page-number-check-first
       \\fromproperty #'page:page-number-string } }
    evenHeaderMarkup = \\markup { {
       \\bold \\fontsize #3 \\on-the-fly #print-page-number-check-first
       \\fromproperty #'page:page-number-string } }
}
\\header { 
  tagline = ""
}

secondaryRecovery = {
  \\stopStaff
  \\once \\override Staff.TimeSignature #'stencil = ##f
  \\time 4/4
  s1
  \\startStaff
}

\\score {
  \\new StaffGroup <<
  #(set-accidental-style 'neo-modern 'StaffGroup)
  	\\new Staff \\transpose c d { \\time 4/4 
#{soprano} 
  	}
  	
  	\\new Staff \\transpose c a { 
#{alto} 
  	}
  	
  	\\new Staff \\transpose c d' {
#{tenor}
  	}
  	
  	\\new Staff \\transpose c a' {
#{bari}
  	}
  >>
  
  \\midi {
    \\context {
      \\Score
      tempoWholesPerMinute = #(ly:make-moment 60 4)
    }
  }
  
  \\layout {
    indent = #0
    \\context {
       \\Score
       
       \\override MultiMeasureRest #'Y-offset = #-17.5
       \\override MultiMeasureRestText #'extra-offset = #'(0 . -17.5)
       \\override TimeSignature #'break-visibility = #end-of-line-invisible
     }
  }
}

)
  $stdout = STDOUT
  outfile.close
end