require '../MM/mm.rb'
require '../PCSet/pcset.rb'
require '../random.rb'
include Math

def choose(n, k)
  return [[]] if n.nil? || n.empty? && k == 0
  return [] if n.nil? || n.empty? && k > 0
  return [[]] if n.size > 0 && k == 0
  c2 = n.clone
  c2.pop
  new_element = n.clone.pop
  choose(c2, k) + append_all(choose(c2, k-1), new_element)
end

# Preliminary definitions. Eventually should break this stuff
# off into another library.

$pitch_classes      = %w(c c# d d# e f f# g g# a a# b)
$pitch_classes_lily = %w(c cis d dis e f fis g gis a ais b)


# Not flagging augmented chords... they don't really sound "functional" out
# of context.
$important_pcsets = {
  "maj"       => PCSet.new([0,4,7]).prime,
  "min"       => PCSet.new([0,3,7]).prime,
  "dim"       => PCSet.new([0,3,6]).prime,
  "maj7"      => PCSet.new([0,4,7,11]).prime,
  "dom7"      => PCSet.new([0,4,7,10]).prime,
  "min7"      => PCSet.new([0,3,7,10]).prime,
  "min maj7"  => PCSet.new([0,3,7,11]).prime,
  "half dim7" => PCSet.new([0,3,6,10]).prime,
  "dim7"      => PCSet.new([0,3,6,9]).prime
}

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

def midi_array_to_lily(midi_array, rhythm_array = nil, initial_rhythm_value = nil)
  if(rhythm_array.nil?)
    if(initial_rhythm_value.nil?)
      return midi_array.collect {|x| midi_to_lily(x)}.join(' ')
    else
      lily_array = midi_array.collect {|x| midi_to_lily(x)}
      lily_array[0] += initial_rhythm_value.to_s
      return lily_array.join(' ')
    end
  else
    output = []
    
    if(midi_array.length != rhythm_array.length)
      raise(StandardError, "midi_array and rhythm_array are different lengths", caller)
    end
    
    rhythm_array.each do |rhythm|
      midi_array_index = 0
      if(rhythm.nil?)
        output.push(midi_to_lily(midi_array[midi_array_index]))
        midi_array_index += 1
      elsif(rhythm[0..0] == 'r')
        output.push(rhythm)
      else
        output.push(midi_to_lily(midi_array[midi_array_index]) + rhythm)
        midi_array_index += 1
      end
    end
    return output.join(' ')
  end
end

$huron_config = MM::DistConfig.new(:scale => :none, :intra_delta => MM::DELTA_FUNCTIONS[:huron])

def process_durations(delay, duration, padding)
  delay_values    = []
  duration_values = []
  padding_values  = []
  
  total = delay + duration + padding
  
  num_full_measures = total / 16
  remainder         = total % 16
  
  delay_values << lily_dur(delay)
  delay_remainder = delay % 16
  
  duration_pickup = 16 - delay_remainder
  duration_values = lily_dur(duration, duration_pickup)
  duration_remainder = (duration - duration_pickup) % 16
  
  padding_pickup = 16 - duration_remainder
  padding_values = lily_dur(padding, padding_pickup)
  
  if num_full_measures == 0
    delay_values.unshift(time_signature(remainder))
  else                  
    delay_values.unshift("\\time 4/4")
    # Is the time signature change in the padding or the duration?
    if remainder == padding
      # The easy case.
      padding_values.unshift(time_signature(remainder))
    elsif remainder > padding
      # It's in the duration
      pos = remainder - padding
      
      reversed_duration_values = duration_values.reverse
      accum = 0
      reversed_duration_values.each_with_index do |d, i|
        case d
        when 16 then accum += 1
        when 8  then accum += 2
        when 4  then accum += 4
        when 2  then accum += 8
        when 1  then accum += 16
        end
        if accum == pos
          reversed_duration_values.insert(i + 1, time_signature(remainder))
          break
        end
      end
      duration_values = reversed_duration_values.reverse
    else
      # It's in the padding
      pos = remainder
      reversed_padding_values = padding_values.reverse
      accum = 0
      reversed_padding_values.each_with_index do |d, i|
        case d
        when 16 then accum += 1
        when 8  then accum += 2
        when 4  then accum += 4
        when 2  then accum += 8
        when 1  then accum += 16
        end
        if accum == pos
          reversed_padding_values.insert(i + 1, time_signature(remainder))
          break
        end
      end
      padding_values = reversed_padding_values.reverse
    end
  end
  
  [delay_values.flatten, duration_values, padding_values]
end

def time_signature(sixteenths)
  return "\\time #{sixteenths / 4}/4" if sixteenths % 4 == 0
  return "\\time #{sixteenths / 2}/8" if sixteenths % 2 == 0
  "\\time #{sixteenths}/16"
end

def lily_dur(d, pickup_length = 0)
  output = []
  
  if pickup_length > 0
    if d > pickup_length
      output << lily_dur(pickup_length).reverse
    else
      output << lily_dur(d).reverse
    end
    output.flatten!
    d -= pickup_length
  end
  
  if d > 0
    wholes = d / 16
    d -= wholes * 16
    wholes.times do
      output.push(1)
    end
  
    halves = d / 8
    d -= halves * 8
    halves.times do
      output.push(2)
    end
  
    quarters = d / 4
    d -= quarters * 4
    quarters.times do
      output.push(4)
    end
  
    eighths = d / 2
    d -= eighths * 2
    eighths.times do 
      output.push(8)
    end
  
    d.times do
      output.push(16)
    end
  end
  output
end

# The core of a slab is a steady-state combination of tones.
# Each tone is a strata. The strata are articulated in the
# both the frequency and time domains. That is, each tone
# begins and ends at a separate time. Each strata has a 
# viscocity, which corresponds to depth and speed of vibrato.

class Slab
  attr_reader :notes, :delays, :durations, :dynamics, :vib_depths, :articulations, :surprise, :lengths, :total_length, :paddings, :instruments, :strings
  def initialize(args = {})
    @notes      = args[:notes]      || [gaussian_in_range(40, 6, 30, 60).round, gaussian_in_range(50, 6, 40, 70).round, gaussian_in_range(60, 6, 48, 80).round, gaussian_in_range(60, 6, 48, 80).round]
    @notes      = @notes.sort
    @delays     = args[:delays]     || [gaussian_in_range(4, 2, 0, 8).round, gaussian_in_range(4, 2, 0, 8).round, gaussian_in_range(4, 2, 0, 8).round, gaussian_in_range(4, 2, 0, 8).round]
    @durations  = args[:durations]  || [gaussian_in_range(8, 2, 1, 12).round, gaussian_in_range(8, 2, 1, 12).round, gaussian_in_range(8, 2, 1, 12).round, gaussian_in_range(8, 2, 1, 12).round ]
    @dynamics   = args[:dynamics]   || []
    @vib_depths = args[:vib_depths] || []
    @articulations = args[:articulations] || []
    
    @surprise   = args[:surprise]   || 0.25
    
    @lengths = @delays.zip(@durations).map { |x, y| x + y }
    @total_length = @lengths.max
    @paddings = @lengths.map { |l| @total_length - l }
    @instruments = {}
    [:cello, :viola, :violin_2, :violin_1].each_with_index do |ins, index|
      @instruments[ins] = {}
      @instruments[ins][:note] = @notes[index]
      @instruments[ins][:delay] = @delays[index]
      @instruments[ins][:duration] = @durations[index]
      @instruments[ins][:padding] = @paddings[index]
      @instruments[ins][:dynamic] = @dynamics[index]
      @instruments[ins][:vib_depth] = @vib_depths[index]
      @instruments[ins][:articulation] = @articulations[index]
    end
    @strings = get_strings
  end
  
  def get_strings
    ins = :cello
    instruments = [:cello, :viola, :violin_2, :violin_1]
    output = {}
    
    instruments.each do |ins|
      output[ins] = ''
    
      dynamic_strings = {
        -5 => '\\pppp',
        -4 => '\\pppp',
        -3 => '\\ppp',
        -2 => '\\pp',
        -1 => '\\p',
        0  => '\\mp',
        1  => '\\mf',
        2  => '\\f',
        3  => '\\ff',
        4  => '\\ff',
        5  => '\\ff',
        6  => '\\ff',
        7  => '\\ff'
      }
      
      articulation_strings = {
        :sul_tasto => '^\\markup { "sul tasto" }'
      }
      
      vibrato_strings = {
        1 => '^\\markup { "vib." }'
      }
      
      #rest_values = lily_dur(@instruments[ins][:delay])
      #note_values = lily_dur(@instruments[ins][:duration], @instruments[ins][:delay])
      #padding_values = lily_dur(@instruments[ins][:padding], @instruments[ins][:duration] + @instruments[ins][:delay])
      
      rest_values, note_values, padding_values = process_durations(@instruments[ins][:delay], @instruments[ins][:duration], @instruments[ins][:padding])
      
      rest_values.each do |value|
        # String values are time signature changes
        output[ins] += value.class == String ? "#{value} " : "r#{value.to_s} "
      end
      
      note_lily = midi_to_lily(@instruments[ins][:note])
      ottava = false
      clef_change = false
      note_values.each_with_index do |value, index|
        if value.class == String
          output[ins] += "#{value} "
        else
          if ins == :violin_1 || ins == :violin_2
            if @instruments[ins][:note] > 101 && index == 0
              output[ins] += "\\ottava #2 "
              ottava = true
            elsif @instruments[ins][:note] > 89 && index == 0
              output[ins] += "\\ottava #1 "
              ottava = true
            end
          elsif ins == :viola
            if @instruments[ins][:note] > 91 && index == 0
              output[ins] += "\\ottava #2 "
              ottava = true
            elsif @instruments[ins][:note] > 79 && index == 0
              output[ins] += "\\ottava #1 "
              ottava = true
            end
          elsif ins == :cello
            if @instruments[ins][:note] > 81 && index == 0
              output[ins] += "\\ottava #2 "
              ottava = true
            elsif @instruments[ins][:note] > 69 && index == 0
              output[ins] += "\\ottava #1 "
              ottava = true
            end
          end
          output[ins] += "#{note_lily}#{value}"
          output[ins] += dynamic_strings[@instruments[ins][:dynamic]] if index == 0 && !dynamic_strings[@instruments[ins][:dynamic]].nil?
          output[ins] += articulation_strings[@instruments[ins][:articulation]] if index == 0 && !articulation_strings[@instruments[ins][:articulation]].nil?
          output[ins] += vibrato_strings[@instruments[ins][:vib_depth]] if index == 0 && !vibrato_strings[@instruments[ins][:vib_depth]].nil?
          output[ins] += " "
          output[ins] += "~ " unless index == (note_values.length - 1)
        end
      end
      output[ins] += "\\ottava #0 " if ottava
        
    
      #padding_values = lily_dur(@instruments[ins][:padding], @instruments[ins][:duration] + @instruments[ins][:delay])
      padding_values.each do |value|
        output[ins] += value.class == String ? "#{value} " : "r#{value.to_s} "
      end
      output[ins] = output[ins].strip
    end
    output
  end
end

# Found this value by trial and error.
$max_huron_dist = 1.6276666666666666

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

def generate_n_versions(basename = "candidate", n = 5)
  n.times do |i|
    generate_version("#{basename}_#{i}.ly")
  end
end

def generate_version(filename = "slab_test.ly")
  #distances = (0.00..0.55).step(0.05).map {|x| x.round(2)}
  #distances = (0.05..1.00).step(0.05).map {|x| x.round(2)}
  distances = (0.05..0.70).step(0.05).map {|x| x.round(2)}
  
  desired_set_size = 100
  max_vectors_at_each_distance = 2
  #desired_set_size = 5
  #max_vectors_at_each_distance = 1
     
  violin_1_range = [55, 107]
  violin_2_range = violin_1_range
  viola_range = [48, 98]
  cello_range = [36, 82]
  ranges = [violin_1_range, violin_2_range, viola_range, cello_range]
  tops = NArray[violin_1_range[1], violin_2_range[1], viola_range[1], cello_range[1]]
  bottoms = NArray[violin_1_range[0], violin_2_range[0], viola_range[0], cello_range[0]]
  
  midpoints = []
  ranges.each do |range|
    midpoints.push((range[0] + ((range[1] - range[0]) / 2.0)).round)
  end
  
  # origin = NArray[59, 74, 88, 91]     # the most consonant configuration near the middle of the range
  # origin = NArray[56, 69, 82, 83]      # the most dissonant configuration near the middle of the range
  origin = NArray[50, 62, 69, 76]       # open strings
  
  top_distance = MM.euclidean.call(origin, tops)
  bottom_distance = MM.euclidean.call(origin, bottoms)
  max_distance = [top_distance, bottom_distance].max

  scaled_euclidean = ->(v1, v2, config = nil) {
    MM.euclidean.call(v1, v2) / max_distance
  }
  
  scaled_huron = ->(v1, v2, config = $huron_config) {
    MM.ucm.call(v1, v2, config) / $max_huron_dist
  }
  
  metrics = [
    { :metric => scaled_euclidean, :weight => 2 },
    { :metric => scaled_huron, :config => $huron_config, :weight => 1 }
  ]
  multi = MM.get_multimetric(metrics)
  
  set_at_distance_opts = {
    :v1 => origin,
    :d => 0, 
    :dist_func => multi, 
    :allow_duplicates => false, 
    :config => :none, 
    :set_size => desired_set_size,
    :search_opts => {
      :start_step_size => 4.0, 
      :min_step_size => 1.0,
      :step_size_subtract => 1.0
    }
  }
    
  puts "-----"
  puts "Generating vectors..."  
  puts "-----"
  puts
  
  usable_vectors = []
  distances.each do |dis|
    set_at_distance_opts[:d] = dis
    vectors = []
    
    # Perform 3 searches, each with different starting step sizes    
    set_at_distance_opts[:search_opts][:start_step_size] = 4.0
    vectors += MM.set_at_distance(set_at_distance_opts)
    set_at_distance_opts[:search_opts][:start_step_size] = 7.0
    vectors += MM.set_at_distance(set_at_distance_opts)
    set_at_distance_opts[:search_opts][:start_step_size] = 12.0
    vectors += MM.set_at_distance(set_at_distance_opts)
    
    # This is important to minimize search algorithm step size bias
    vectors.shuffle!
    
    # At this point certain vectors need to be filtered out, for at least two reasons:
    #  1) They're out of range.
    #  2) There is a large imbalance between the euclidean and huron distances.
    #  3) They don't have four unique pitch classes. (Too thin.)
    keepers = []
    thin_keepers = []
    out_of_range = []
    unbalanced = []
    too_thin = []
    
    vectors.each do |v|
      sorted = v.sort
      in_range = (
        (v[0] >= cello_range[0]    && v[0] <= cello_range[1])    &&
        (v[1] >= viola_range[0]    && v[1] <= viola_range[1])    &&
        (v[2] >= violin_2_range[0] && v[2] <= violin_2_range[1]) &&
        (v[3] >= violin_1_range[0] && v[3] <= violin_1_range[1])
      )
      balanced = (scaled_euclidean.call(origin, v) - scaled_huron.call(origin, v)).abs < 0.4
      
      pcs = PCSet.new(v.to_i.to_a)
      thick = pcs.prime.pitches.size == 4
      
      keepers << v if in_range && balanced # && thick  let's let thin in, but sort to avoid them (below)
      thin_keepers << v if in_range && balanced && !thick
      out_of_range << v if !in_range
      unbalanced << v if !balanced
      too_thin << v if !thick
    end
    
    puts
    puts "-- Distance: #{dis} --"
    puts " #{vectors.size} matches of #{desired_set_size * 3} desired - #{((vectors.size.to_f / (desired_set_size * 3)) * 100).round(2)}% search success"
    puts " #{(keepers.size.to_f / vectors.size.to_f) * 100}% keepers"
    puts " #{keepers.size} keepers, #{out_of_range.size} out of range, #{unbalanced.size} unbalanced, #{too_thin.size} too thin"
    puts " #{(thin_keepers.size.to_f / keepers.size) * 100}% thin keepers"
    
    # Sort the keepers at this distance by their balance values
    # Or: don't, because the whole point is to get a sense of different balances.
    #keepers.sort_by! { |v| (scaled_euclidean.call(origin, v) - scaled_huron.call(origin, v)).abs }
    
    # Instead, sort by thickness.
    # This way thin sets can be used, but only as a last resort
    keepers.sort_by! { |v| PCSet.new(v.to_i.to_a).prime.pitches.size }
    keepers.reverse!
    
    keepers.each_with_index do |vector, index|
      break if index > (max_vectors_at_each_distance - 1)
      
      usable_vectors << vector
      
      print_vector_stats = true
      if print_vector_stats
        # Print vector statistics
        puts
        puts "- #{index}"
        puts "Vector: #{vector.to_a.to_s}"
        puts "Balance: #{(scaled_euclidean.call(origin, vector) - scaled_huron.call(origin, vector)).abs}"
        puts "Huron check: #{huron_check(vector)}"
        puts "Distance from origin:"
        puts "  Euclidean: #{scaled_euclidean.call(origin, vector)}"
        puts "  Huron:     #{scaled_huron.call(origin, vector)}"
        puts "  Multi:     #{multi.call(origin, vector)}"
      end
    end
  end
  
  puts "-----"
  puts "Doing statistics..."  
  puts "-----"
  puts
  
  surprises = []
    
  running_total_vector = NArray[0,0,0,0]
  running_total_dissonance = 0.0
  previous_vector = usable_vectors[0]
  
  usable_vectors.each_with_index do |v, index|
    #
    # Get the relationship of the current vector to the previous vectors by a variety of metrics
    # 
    # Note: index will always refer to the number of vectors previously evaluated. Using index - 1,
    # while tempting, would be incorrect. Also, always add the current vector to the running/previous
    # pools /after/ performing the calculations.
    #
    running_mean_vector = (running_total_vector.to_f / index).round
    running_total_vector += v
    # Can't use the multimetric here.
    # The euclidean, pitch space mean will not necessarily have mean dissonance!
    euclidean_distance_from_running_mean = scaled_euclidean.call(running_mean_vector, v)
    
    running_mean_dissonance = running_total_dissonance.to_f / index
    current_dissonance = huron_check(v)
    running_total_dissonance += current_dissonance
    dissonance_difference_from_running_mean = (current_dissonance - running_mean_dissonance).abs
    
    window_size = 5
    bottom = index < window_size ? 0 : index - window_size
    window = usable_vectors.slice(bottom, window_size)
    windowed_mean_vector = (window.inject(0, :+).to_f / window_size).round
    euclidean_distance_from_windowed_mean = scaled_euclidean.call(windowed_mean_vector, v)
    
    window_mean_dissonance = (window.map {|x| huron_check(x)}.inject(0, :+)) / window_size
    dissonance_difference_from_window = (current_dissonance - window_mean_dissonance).abs
        
    # The multimetric does make sense when comparing vectors which are not
    # themselves averages, so...
    distance_from_previous = multi.call(previous_vector, v)
    previous_vector = v
    
    running_distances  = euclidean_distance_from_running_mean + dissonance_difference_from_running_mean
    windowed_distances = euclidean_distance_from_windowed_mean + dissonance_difference_from_window
    total_of_distances = distance_from_previous + euclidean_distance_from_running_mean + euclidean_distance_from_windowed_mean + dissonance_difference_from_running_mean + dissonance_difference_from_window
    
    surprise = windowed_distances
    surprises << surprise
    
    print_full_stats = false
    if print_full_stats
      delta = v - usable_vectors[index - 1]
      next_delta = usable_vectors[index + 1] - v
      
      puts
      puts "Vector:                 #{v.to_a.to_s}"
      puts "Delta:                  #{delta.to_a.to_s}"
      puts "Next delta:             #{next_delta.to_a.to_s}"
      puts "Dissonance:             #{huron_check(v).round(3)}"
      puts "Run. mean dis.:         #{running_mean_dissonance.round(3)}"
      puts "Win. mean dis.:         #{window_mean_dissonance.round(3)}"
      puts "Running mean:           #{running_mean_vector.to_a.to_s}"
      puts "Windowed mean:          #{windowed_mean_vector.to_a.to_s}"
      puts "Multi from previous:    #{distance_from_previous.round(3)}"
      puts "Euc. from running mean: #{euclidean_distance_from_running_mean.round(3)}"
      puts "Euc. from window mean:  #{euclidean_distance_from_windowed_mean.round(3)}"
      puts "Dis. from running mean: #{dissonance_difference_from_running_mean.round(3)}"
      puts "Dis. from window:       #{dissonance_difference_from_window.round(3)}"
      puts "Total of run. dists:    #{running_distances.round(3)}"
      puts "Total of window dists:  #{windowed_distances.round(3)}"
      puts "Total of distances:     #{total_of_distances.round(3)}"
    end
  end
  
  min_surprise = surprises.min
  max_surprise = surprises.max
  mean_surprise = surprises.inject(:+).to_f / surprises.size
  
  scaled_surprises = ((NArray.to_na(surprises) - min_surprise) / max_surprise)
  scaled_surprises = scaled_surprises * (1.0 / scaled_surprises.max)
  mean_scaled_surprise = scaled_surprises.mean
  
  print_surprise_stats = true
  if print_surprise_stats
    puts "Min surprise: #{min_surprise.round(3)}"
    puts "Max surprise: #{max_surprise.round(3)}"
    mean_surprise = surprises.inject(:+) / surprises.size
    puts "Mean surprise: #{mean_surprise.round(3)}"
    puts
    puts "Min scaled:  #{scaled_surprises.min}"
    puts "Max scaled:  #{scaled_surprises.max}"
    puts "Mean scaled: #{scaled_surprises.mean}"
  end
  
  puts
  puts "-----"
  puts "Creating slabs..."  
  puts "-----"
  puts
  
  slabs = []
  
  usable_vectors.unshift(origin)
  scaled_surprises = NArray.to_na(scaled_surprises.to_a.unshift(0))
  
  usable_vectors.each_with_index do |v, index|
    pcs = PCSet.new(v.to_i.to_a)
    
    if index == 0
      delta = NArray[0,0,0,0]
    else
      prev_pcs = PCSet.new(usable_vectors[index-1].to_i.to_a)
      delta = v - usable_vectors[index - 1]
    end

    next_delta = usable_vectors[index + 1] - v unless usable_vectors[index + 1].nil?
    chord_name = $important_pcsets.key(pcs.prime)
    
    vib_depths    = [0,0,0,0]
    articulations = [nil, nil, nil, nil]
        
    dynamics = [gaussian_in_range(0, 0.5, -3, 3).round, 
                gaussian_in_range(0, 0.5, -3, 3).round, 
                gaussian_in_range(0, 0.5, -3, 3).round, 
                gaussian_in_range(0, 0.5, -3, 3).round]
    
    dynamics = [0,0,0,0] if index == 0
     
    # Give particularly surprising slabs a dynamic boost
    if scaled_surprises[index] > 0.6  # This number is a little arbitrary... should be 1 std above mean?
      dynamics = (NArray.to_na(dynamics) + 1).to_a
    end
    if scaled_surprises[index] > 0.99  # Double boost for this guy
      dynamics = (NArray.to_na(dynamics) + 1).to_a
      vib_depths = [1,1,1,1]
    end
    
    delays = [gaussian_in_range(5, 2, 0, 8).round, 
              gaussian_in_range(5, 2, 0, 8).round, 
              gaussian_in_range(5, 2, 0, 8).round, 
              gaussian_in_range(5, 2, 0, 8).round]
    
    # If it's a common chord, avoid cliches.
    # So for example, no arpeggiating a diminished chord upward.
    if($important_pcsets.include?(chord_name))
      delays = [gaussian_in_range(10, 4, 0, 16).round, 
                gaussian_in_range(10, 4, 0, 16).round, 
                gaussian_in_range(10, 4, 0, 16).round, 
                gaussian_in_range(10, 4, 0, 16).round]
    end
    
    delays = [0,0,0,0] if index == 0
    
    mean_duration = gaussian_in_range(20, 4, 8, 28)
    if index > 0 && (pcs.prime == prev_pcs.prime)
      mean_duration = mean_duration / 2.0
    end
    durations = [gaussian_in_range(mean_duration + (scaled_surprises[index] * 6), 4, 8, 32).round, 
                 gaussian_in_range(mean_duration + (scaled_surprises[index] * 6), 4, 8, 32).round, 
                 gaussian_in_range(mean_duration + (scaled_surprises[index] * 6), 4, 8, 32).round, 
                 gaussian_in_range(mean_duration + (scaled_surprises[index] * 6), 4, 8, 32).round]
    
    if index == 0
      durations = [mean_duration.round, mean_duration.round, mean_duration.round, mean_duration.round]
    end
    
    # Modifications based on horizontal motion
    if (delta.to_a.uniq.size == 1) && index > 0
      articulations = [:sul_tasto, :sul_tasto, :sul_tasto, :sul_tasto]
    end

    #
    #  WARNING!!!  It looks like there is a problem where sometimes articulations
    #              Are not correctly assigned. I had to go through and add a bunch
    #              of them manually, looking at the delta for each slab.
    #
    
    if index > 0
      delta.to_a.each_with_index do |d, i|
        # If there's no movement, we want to tone this note down
        if d == 0
          articulations[i] = :sul_tasto
          dynamics[i] = dynamics[i] - 1
        end
         
        # Give movements down a 5th/up a 4th a little vibrato
        if [-7,-19,-31,-43,5,17,29,41].include?(d.to_i)
          vib_depths[i] = 1
        end
      end
    end
    
    slab_args = {
      :notes => v.to_i.to_a, 
      :delays => delays, 
      :durations => durations,
      :dynamics => dynamics, 
      :vib_depths => vib_depths, 
      :articulations => articulations,
      :surprise => scaled_surprises[index]
    }
    slabs.push(Slab.new(slab_args))
  end
  
  puts "-----"
  puts "Rendering lilypond..."  
  puts "-----"
  puts
  
  render_slabs(slabs, filename)
end

def render_slabs(slabs = [], filename = "slab_test.ly", max_recovery = 17.0, n = 10)
  if(slabs == [])
    n.times do
      slabs.push(Slab.new)
    end
  end
  cello, viola, violin_2, violin_1 = '', '', '', ''
  m_cello, m_viola, m_violin_2, m_violin_1 = '', '', '', ''
  
  spacer_string_secondary = "\t\\secondaryRecovery"
  
  slabs.each_with_index do |slab, index|
    inter_slab_gap = ((max_recovery * slab.surprise) + 1).round
    
    spacer_string_primary = %(
    \\stopStaff
    \\once \\override Staff.TimeSignature #'stencil = ##f
    \\time 4/4
    R1^\\markup {\\fontsize #3 "#{inter_slab_gap.to_s}\\""} \\bar "|"
    \\startStaff

)

    midi_spacer_string = "\n\\time 1/4"
    inter_slab_gap.times do 
      midi_spacer_string += " r4"
    end
    midi_spacer_string += "\n\n"
    
    #\\fermataMarkup
    
    #pp slab.strings
    #puts "delays:  #{slab.delays.to_s}"
    #puts "durs:    #{slab.durations.to_s}"
    #puts "lengths: #{slab.lengths.to_s}"
    #puts "pads:    #{slab.paddings}"
    #puts "total length: #{slab.total_length}"
    
    pcs = PCSet.new(slab.notes)
    
    delta = NArray.to_na(slab.notes) - NArray.to_na(slabs[index - 1].notes)
    delta = NArray[0,0,0,0] if index == 0
    
    violin_1 += "%\t\t - Slab #{index}\n"
    violin_1 += "%\t\t - Notes: #{slab.notes.to_a.to_s}\n"
    violin_1 += "%\t\t - Delta: #{delta.to_a.to_s}\n"
    violin_1 += "%\t\t - Prime: #{pcs.prime.pitches.to_s}\n"
    violin_1 += "%\t\t - Impt.: #{$important_pcsets.key(pcs.prime)}\n"
    
    m_violin_1 += "%\t\t - Slab #{index}\n"
    m_violin_1 += "%\t\t - Notes: #{slab.notes.to_a.to_s}\n"
    m_violin_1 += "%\t\t - Delta: #{delta.to_a.to_s}\n"
    m_violin_1 += "%\t\t - Prime: #{pcs.prime.pitches.to_s}\n"
    m_violin_1 += "%\t\t - Impt.: #{$important_pcsets.key(pcs.prime)}\n"
    
    #violin_1 += "\\time #{slab.total_length}/16\n"
    
    violin_1 += "\n\t\t\t" + slab.strings[:violin_1] + "\n" + spacer_string_primary
    violin_2 += "\n% - V2  Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:violin_2] + "\n\t\t\t\t" + spacer_string_secondary + "\n" 
    viola    += "\n% - Vla Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:viola]    + "\n\t\t\t\t" + spacer_string_secondary + "\n" 
    cello    += "\n% - Cl  Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:cello]    + "\n\t\t\t\t" + spacer_string_secondary + "\n"

    m_violin_1 += "\n\t\t\t" + slab.strings[:violin_1] + "\n" + midi_spacer_string
    m_violin_2 += "\n% - V2  Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:violin_2] + "\n\t\t\t\t" + midi_spacer_string + "\n" 
    m_viola    += "\n% - Vla Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:viola]    + "\n\t\t\t\t" + midi_spacer_string + "\n" 
    m_cello    += "\n% - Cl  Slab #{index}\t\tDelta: #{delta.to_a.to_s}\t\tImpt.: #{$important_pcsets.key(pcs.prime)}\n\n\t\t\t" + slab.strings[:cello]    + "\n\t\t\t\t" + midi_spacer_string + "\n" 
    
  end
  write_lilypond(violin_1, violin_2, viola, cello, filename)
  write_lilypond(m_violin_1, m_violin_2, m_viola, m_cello, "midi_#{filename}")
end


def write_lilypond(v1, v2, vla, cl, filename = 'spheres.ly')
  outfile = File.open(filename, 'w')
  $stdout = outfile
  puts %(
\\version "2.14.2"
\\paper {
  #(set-paper-size "11x17" 'landscape)
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
  	\\new Staff { \\time 4/4 
#{v1} 
  	}
  	
  	\\new Staff { 
#{v2} 
  	}
  	
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
       \\remove "Bar_number_engraver"
     }
  }
}

)
  $stdout = STDOUT
  outfile.close
end

