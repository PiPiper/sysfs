module PiPiper
  class Sysfs < Driver

    GPIO_HIGH = 1
    GPIO_LOW  = 0

    def initialize
      @exported_pins = Set.new
    end

    def close
      unexport_all
      @exported_pins.empty? 
    end
    
# Support GPIO pins
    def pin_direction(pin, direction)
      raise ArgumentError, "direction should be :in or :out" unless [:in, :out].include? direction
      export(pin)
      raise RuntimeError, "Pin #{pin} not exported" unless exported?(pin)
      File.write("/sys/class/gpio/gpio#{pin}/direction", direction)
    end

    def pin_read(pin)
      raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
      File.read("/sys/class/gpio/gpio#{pin}/value").to_i
    end

    def pin_write(pin, value)
      raise ArgumentError, "value should be GPIO_HIGH or GPIO_LOW" unless [GPIO_LOW, GPIO_HIGH].include? value
      raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
      File.write("/sys/class/gpio/gpio#{pin}/value", value)
    end

    def pin_set_pud(pin, value)
      raise NotImplementedError, "Pull up/down not avaliable with this driver. keep it on :off" unless value == :off
    end
    
    def pin_set_trigger(pin, trigger)
      raise ArgumentError, "trigger should be :falling, :rising, :both or :none" unless [:falling, :rising, :both, :none].include? trigger
      raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
      File.write("/sys/class/gpio/gpio#{pin}/edge", trigger)
    end

    def pin_wait_for(pin)
      fd = File.open("/sys/class/gpio/gpio#{pin}/value", "r")
      fd.read
      IO.select(nil, nil, [fd], nil)
      true
    end

# Specific behaviours

    def export(pin)
      raise RuntimeError, "pin #{pin} is already reserved by another Pin instance" if @exported_pins.include?(pin)
      File.write("/sys/class/gpio/export", pin)
      @exported_pins << pin
    end

    def unexport(pin)
      File.write("/sys/class/gpio/unexport", pin)
      @exported_pins.delete(pin)
    end

    def unexport_all
      @exported_pins.dup.each { |pin| unexport(pin) }
    end

    def exported?(pin)
      @exported_pins.include?(pin)
    end
  end
end
