module PiPiper
  def self.driver=(driver)
    # Placeholder for testing, PiPiper 3.0 contains this so we can remove
  end
end

require 'pi_piper'
require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pi_piper/sysfs'
