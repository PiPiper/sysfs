describe PiPiper::Sysfs::Driver do
  let(:pins) { '@exported_pins' }
  let(:file) { double('File', read: true) }

  before(:each) do
    allow(File).to receive(:write).with('/sys/class/gpio/export', 4)
    allow(File).to receive(:write).with('/sys/class/gpio/gpio4/direction', :in)
    allow(File).to receive(:write).with('/sys/class/gpio/gpio4/direction', :out)
  end

  describe '#initialize' do
    it 'should load the driver' do
      expect { PiPiper::Sysfs::Driver.new }.not_to raise_error
    end

    it 'should not export any pins' do
      expect(subject.instance_variable_get(pins)).to be_empty
    end
  end

  describe '#pin_direction' do
    it 'should export the pin' do
      allow(File).to receive(:write)
      allow(subject).to receive(:exported?).with(4).and_return(true)
      expect(subject).to receive(:export).with(4)
      subject.pin_direction(4, :in)
    end

    it 'should set the pin to :in when given :in' do
      expect(File).to(
        receive(:write).with('/sys/class/gpio/gpio4/direction', :in))

      subject.pin_direction(4, :in)
    end

    it 'should set the pin to :out when given :out' do
      expect(File).to(
        receive(:write).with('/sys/class/gpio/gpio4/direction', :out))

      subject.pin_direction(4, :out)
    end

    it 'should allow multiple pins to be exported' do
      allow(File).to receive(:write).with('/sys/class/gpio/export', 5)
      allow(File).to(
        receive(:write).with('/sys/class/gpio/gpio5/direction', :in))

      subject.pin_direction(4, :in)
      subject.pin_direction(5, :in)

      expect(subject.instance_variable_get(pins)).to include(4, 5)
    end

    it 'should raise an error if pin is already exported' do
      subject.pin_direction(4, :in)

      expect { subject.pin_direction(4, :in) }.to raise_error(RuntimeError)
    end

    it 'should raise an error on invalid directions' do
      expect { subject.pin_direction(4, :bad) }.to raise_error(ArgumentError)
    end

    it 'should raise an error if export fails' do
      allow(subject).to receive(:exported?).with(4).and_return(false)
      expect { subject.pin_direction(4, :in) }.to(
        raise_error(RuntimeError, 'Pin 4 not exported'))
    end
  end

  describe '#pin_read' do
    it 'should return the value of the pin' do
      subject.pin_direction(4, :in)
      expect(File).to receive(:read).with('/sys/class/gpio/gpio4/value')
      subject.pin_read(4)
    end

    it 'should raise an error if pin is not exported' do
      expect { subject.pin_read(4) }.to(
        raise_error(ArgumentError, 'Pin 4 not exported'))
    end
  end

  describe '#pin_write' do
    it 'should write the value to the pin' do
      subject.pin_direction(4, :out)
      expect(File).to receive(:write).with('/sys/class/gpio/gpio4/value', 1)
      subject.pin_write(4, 1)
    end

    it 'should raise an error if invalid value' do
      expect { subject.pin_write(4, 25) }.to raise_error(ArgumentError)
    end

    it 'should raise an error if pin is not exported' do
      expect { subject.pin_write(4, 1) }.to(
        raise_error(ArgumentError, 'Pin 4 not exported'))
    end
  end

  describe '#pin_set_pud' do
    it 'should raise not implemented error because it is not implemented' do
      expect { subject.pin_set_pud(4, :up) }.to raise_error(NotImplementedError)
    end
  end

  describe '#pin_set_trigger' do
    before(:each) do
      subject.pin_direction(4, :in)
    end

    it 'should set the trigger for the pin to :both' do
      expect(File).to receive(:write).with('/sys/class/gpio/gpio4/edge', :both)
      subject.pin_set_trigger(4, :both)
    end

    it 'should set the trigger for the pin to :none' do
      expect(File).to receive(:write).with('/sys/class/gpio/gpio4/edge', :none)
      subject.pin_set_trigger(4, :none)
    end

    it 'should set the trigger for the pin to :falling' do
      expect(File).to(
        receive(:write).with('/sys/class/gpio/gpio4/edge', :falling))
      subject.pin_set_trigger(4, :falling)
    end

    it 'should set the trigger for the pin to :rising' do
      expect(File).to(
        receive(:write).with('/sys/class/gpio/gpio4/edge', :rising))
      subject.pin_set_trigger(4, :rising)
    end

    it 'should raise an error for invalid triggers' do
      expect { subject.pin_set_trigger(4, :invalid) }.to(
        raise_error(ArgumentError))
    end

    it 'should raise an error if pin is not exported' do
      expect { subject.pin_set_trigger(5, :rising) }.to(
        raise_error(ArgumentError, 'Pin 5 not exported'))
    end
  end

  describe '#pin_wait_for' do
    it 'should wait for the value of the pin to change' do
      allow(File).to(
        receive(:open).with('/sys/class/gpio/gpio4/value', 'r')
                      .and_return(file))
      allow(IO).to receive(:select)
      expect(subject.pin_wait_for(4)).to be(true)
    end
  end

  describe '#close' do
    it 'should unexport all exported pins' do
      subject.pin_direction(4, :in)
      allow(File).to receive(:write).with('/sys/class/gpio/unexport', 4)

      subject.close
      expect(subject.instance_variable_get(pins)).to be_empty
    end
  end

  describe '#unexport' do
    before(:each) do
      subject.pin_direction(4, :in)
    end

    it 'should unexport the pin' do
      allow(File).to receive(:write).with('/sys/class/gpio/unexport', 4)
      subject.unexport(4)
      expect(subject.instance_variable_get(pins)).to be_empty
    end

    it 'should not export other pins' do
      allow(File).to receive(:write).with('/sys/class/gpio/unexport', 4)
      allow(File).to receive(:write).with('/sys/class/gpio/export', 5)
      allow(File).to(
        receive(:write).with('/sys/class/gpio/gpio5/direction', :in))
      subject.pin_direction(5, :in)

      subject.unexport(4)
      
      exported_pins = subject.instance_variable_get(pins)
      expect(exported_pins).to include(5)
      expect(exported_pins).not_to include(4)
    end
  end

  describe '#unexport_all' do
    it 'should unexport all pins' do
      allow(File).to receive(:write).with('/sys/class/gpio/export', 5)
      allow(File).to(
        receive(:write).with('/sys/class/gpio/gpio5/direction', :in))
      allow(File).to receive(:write).with('/sys/class/gpio/unexport', 4)
      allow(File).to receive(:write).with('/sys/class/gpio/unexport', 5)

      subject.pin_direction(4, :in)
      subject.pin_direction(5, :in)

      subject.unexport_all
      expect(subject.instance_variable_get(pins)).to be_empty
    end
  end

  describe '#exported?' do
    it 'should return true if pin is exported' do
      subject.pin_direction(4, :in)
      expect(subject.exported?(4)).to be(true)
    end

    it 'should return false if pin is not exported' do
      expect(subject.exported?(4)).to be(false)
    end
  end
end
