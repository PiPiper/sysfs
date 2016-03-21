require 'spec_helper'

describe PiPiper::Sysfs do
  it 'has a version number' do
    expect(PiPiper::Sysfs::VERSION).not_to be nil
  end

  context 'init & close' do
    it 'should load the driver' do
      expect{ PiPiper::Sysfs.new }.not_to raise_error
    end

    it 'should unexport every pin at close' do
      expect(subject).to receive(:unexport_all)
      subject.close
    end
  end

  let(:file_like_object) { double("file like object") }

  before :example do
    allow(File).to receive(:read).and_return("1")
    allow(File).to receive(:write).and_return("1")
    allow(File).to receive(:open).and_return(file_like_object)
  end

  describe 'Specific behaviours' do
    it '#export(pin)' do
      expect(File).to receive(:write).with("/sys/class/gpio/export", 4)
      expect(subject.instance_variable_get('@exported_pins')).not_to include(4)
      subject.export(4)
      expect(subject.instance_variable_get('@exported_pins')).to include(4)
    end

    it '#unexport(pin)' do
      expect(File).to receive(:write).with("/sys/class/gpio/unexport", 4)

      subject.export(4)
      expect(subject.instance_variable_get('@exported_pins')).to include(4)
      subject.unexport(4)
      expect(subject.instance_variable_get('@exported_pins')).not_to include(4)
    end

    it '#unexport_all' do
      subject.export(4)
      subject.export(18)
      subject.export(27)
      expect(subject.instance_variable_get('@exported_pins')).to eq Set.new([4,18,27])
      subject.unexport_all
      expect(subject.instance_variable_get('@exported_pins')).to eq Set.new([])
    end

    it '#exported?(pin)' do
      subject.export(4)
      expect(subject.exported?(4)).to be true
      expect(subject.exported?(112)).to be false
    end

    context "when a pin is not exported" do
      it 'should stop RW access to pin after unexport' do
        subject.unexport(4)
        expect { subject.pin_read(4) }.to raise_error ArgumentError, "Pin 4 not exported"
        expect { subject.pin_write(4, 1) }.to raise_error ArgumentError, "Pin 4 not exported"
      end
    end

    context "when a pin is already exported" do
      it 'should raise_error when a pin is already in use' do
        subject.export(4)
        expect { subject.export(4) }.to raise_error RuntimeError
      end
    end
  end

  context 'API for Pin' do
    it '#pin_direction(pin, direction)' do
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/direction", :in)
      subject.pin_direction(5, :in)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio6/direction", :out)
      subject.pin_direction(6, :out)

      expect{ subject.pin_direction(7, :inout) }.to raise_error ArgumentError, "direction should be :in or :out"
    end

    it '#pin_write(pin, value)' do
      subject.export(5)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/value", 1)
      subject.pin_write(5, 1)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/value", 0)
      subject.pin_write(5, 0)
      expect { subject.pin_write(5, 99) }.to raise_error ArgumentError, "value should be GPIO_HIGH or GPIO_LOW"
    end

    it '#pin_read(pin)' do
      subject.export(5)
      expect(File).to receive(:read).with("/sys/class/gpio/gpio5/value")
      subject.pin_read(5)
    end

    it '#pin_set_pud(pin, value)' do
      expect {subject.pin_set_pud(5, :up)}.to raise_error NotImplementedError
    end

    it '#pin_set_trigger(pin, trigger)' do
      subject.export(5)
      
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/edge", :none)
      subject.pin_set_trigger(5, :none)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/edge", :both)
      subject.pin_set_trigger(5, :both)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/edge", :falling)
      subject.pin_set_trigger(5, :falling)
      expect(File).to receive(:write).with("/sys/class/gpio/gpio5/edge", :rising)
      subject.pin_set_trigger(5, :rising)
      
      expect { subject.pin_set_trigger(5, :not_a_trigger) }.to raise_error ArgumentError, "trigger should be :falling, :rising, :both or :none"
    end

    it '#pin_wait_for(pin)'
  end
end