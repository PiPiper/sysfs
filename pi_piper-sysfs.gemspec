# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pi_piper/sysfs/version'

Gem::Specification.new do |spec|
  spec.name          = "pi_piper-sysfs"
  spec.version       = PiPiper::Sysfs::VERSION
  spec.authors       = ['Zshawn Syed', 'Jason Whitehorn', 'Marc-Antoine Brenac']
  spec.email         = ['zsyed91@gmail.com', 'jason.whitehorn@gmail.com', 'elmatou@gmail.com']

  spec.summary       = %q{GPIO kernel driver library for the Raspberry Pi and PiPiper}
  spec.description   = 'GPIO kernel driver library for the Raspberry Pi and other' \
                       ' boards that use the chipset. Commonly used with the' \
                       ' PiPiper ruby library. it implements Pin (with events)' \
                       ' it reads from sysfs, and needs root UID to work'

  spec.homepage      = "https://github.com/PiPiper/sysfs"
  spec.license       = "BSD"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib/pi_piper"]

  spec.add_runtime_dependency 'pi_piper', ">= 2.0.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov'
end
