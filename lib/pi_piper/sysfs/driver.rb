require 'filewatcher'

module PiPiper
  module Sysfs
    class Driver < PiPiper::Driver

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
        File.write(direction_file(pin), direction)
      end

      def pin_read(pin)
        raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
        File.read(value_file(pin)).to_i
      end

      def pin_write(pin, value)
        raise ArgumentError, "value should be GPIO_HIGH or GPIO_LOW" unless [GPIO_LOW, GPIO_HIGH].include? value
        raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
        File.write(value_file(pin), value)
      end

      def pin_set_pud(pin, value)
        raise NotImplementedError, "Pull up/down not available with this driver. keep it on :off" unless value == :off
      end
      
      def pin_set_trigger(pin, trigger)
        raise ArgumentError, "trigger should be :falling, :rising, :both or :none" unless [:falling, :rising, :both, :none].include? trigger
        raise ArgumentError, "Pin #{pin} not exported" unless exported?(pin)
        File.write(edge_file(pin), trigger)
      end

      def pin_wait_for(pin, trigger)
        pin_set_trigger(pin, trigger)
        value = pin_read(pin)

        FileWatcher.new([value_file(pin)]).watch do |filename, event|
          next unless event == :changed || event == :new
          next unless pin_value_changed?(pin, trigger, value)
          break
        end

        true
      end

  # Specific behaviours

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

      private

      def export(pin)
        raise RuntimeError, "pin #{pin} is already reserved by another Pin instance" if @exported_pins.include?(pin)
        File.write("/sys/class/gpio/export", pin)
        @exported_pins << pin
      end

      def value_file(pin)
        "/sys/class/gpio/gpio#{pin}/value"
      end

      def edge_file(pin)
        "/sys/class/gpio/gpio#{pin}/edge"
      end

      def direction_file(pin)
        "/sys/class/gpio/gpio#{pin}/direction"
      end

      def pin_value_changed?(pin, trigger, value)
        last_value = value
        value = pin_read(pin)
        return false if value == last_value
        return false if trigger == :rising && value == 0
        return false if trigger == :falling && value == 1
        true
      end
    end
  end
end
