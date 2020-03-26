# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Calculator' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  def shared_pods 
    pod 'RxSwift'
    pod 'RxCocoa'
  end

  # Pods for Calculator
  shared_pods
  pod 'SteviaLayout'

  target 'CalculatorTests' do
    inherit! :search_paths
    # Pods for testing
    shared_pods
    pod 'RxTest'
  end

end
