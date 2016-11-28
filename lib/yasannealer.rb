# Returns x rounded to n significant figures.
def round_figures(x, n)
  x #round(x, int(n - math.ceil(math.log10(abs(x)))))
end

# Returns time in seconds as a string formatted HHHH:MM:SS.
def time_string(seconds)
  Time.at(seconds).utc.strftime("%H:%M:%S")
end

class Yasannealer
  # Performs simulated annealing by calling functions to calculate
  # energy and make moves on a state.  The temperature schedule for
  # annealing may be provided manually or estimated automatically.

  attr_accessor :tmax, :tmin, :steps, :updates, :state,
                  :start

  MESS = "SYSTEM ERROR: method missing"

  def initialize(initial_state, opts = {})
    self.tmin = opts[:tmin] || 0.001
    self.tmax = opts[:tmax] || 60.0
    self.steps = opts[:steps] || 1000000
    self.updates = opts[:updates] || 60

    self.state = initial_state.dup
  end

  def move; raise MESS; end
  def energy; raise MESS; end

  # Prints the current temperature, energy, acceptance rate,
  # improvement rate, elapsed time, and remaining time.

  # The acceptance rate indicates the percentage of moves since the last
  # update that were accepted by the Metropolis algorithm.  It includes
  # moves that decreased the energy, moves that left the energy
  # unchanged, and moves that increased the energy yet were reached by
  # thermal excitation.

  # The improvement rate indicates the percentage of moves since the
  # last update that strictly decreased the energy.  At high
  # temperatures it will include both moves that improved the overall
  # state and moves that simply undid previously accepted moves that
  #increased the energy by thermal excititation.  At low temperatures
  # it will tend toward zero as the moves that can decrease the energy
  # are exhausted and moves that would increase the energy are no longer
  # thermally accessible.
  def update(step, t, e, acceptance, improvement)
    elapsed = Time.now - self.start
    if step == 0
      puts(' Temperature        Energy    Accept   Improve     Elapsed   Remaining')
      puts("\r%12.2f  %12.2f                      %s            " % [t, e, time_string(elapsed).to_s] )
    else
      remain = (self.steps - step) * (elapsed.to_f / step)
      puts("\r%12.2f  %12.2f  %7.2f%%  %7.2f%%  %s  %s" % [t, e, 100.0 * acceptance, 100.0 * improvement, time_string(elapsed), time_string(remain)])
    end
  end

  # Minimizes the energy of a system by simulated annealing.
  # Parameters
  # state : an initial arrangement of the system
  #
  # Returns
  # (state, energy): the best state and energy found.
  def anneal
    step = 0
    self.start = Time.now

    # Precompute factor for exponential cooling from Tmax to Tmin
    if self.tmin <= 0.0
      raise 'Exponential cooling requires a minimum temperature greater than zero.'
    end
    t_factor = -Math.log(self.tmax.to_f / self.tmin)

    # Note initial state
    t = self.tmax
    e = self.energy

    prev_state = self.state.dup
    prev_energy = e
    best_state = self.state.dup
    best_energy = e

    trials, accepts, improves = 0, 0, 0
    if self.updates > 0
      update_wavelength = self.steps / self.updates
      self.update(step, t, e, nil, nil)
    end

    # Attempt moves to new states
    while step < self.steps
      step += 1
      t = self.tmax * Math.exp(t_factor * step / self.steps)
      self.move
      e = self.energy
      dE = e - prev_energy
      trials += 1

      if dE > 0.0 and Math.exp(-dE / t) < rand()
        # Restore previous state
        self.state = prev_state.dup
        e = prev_energy
      else
        # Accept new state and compare to best state
        accepts += 1
        if dE < 0.0
          improves += 1
        end

        prev_state = self.state.dup
        prev_energy = e

        if e < best_energy
          best_state = self.state.dup
          best_energy = e
        end
      end

      if self.updates > 1
          if step / update_wavelength > (step - 1) / update_wavelength
            self.update(step, t, e, accepts.to_f / trials, improves.to_f / trials)
            trials, accepts, improves = 0, 0, 0
          end
      end

      break if best_energy == 0.0
    end

    # line break after progress output
    puts

    self.state = best_state.dup

    # Return best state and energy
    return [best_state, best_energy]

  end
end
