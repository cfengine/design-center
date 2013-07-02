module Actions

  def Actions.assemble(type, installer, setup_steps, dctest)
    steps = []

    # pp method(__method__).parameters.map{|arg| __method__.to_s + " #{arg[1]} = #{eval arg[1].to_s}" }

    # note order: install, then bootstrap, then install DC, then other steps

    steps << { :path => "install_#{type}_#{installer}.sh", :args => [] }

    unless dctest.empty?
      setup_steps += [ 'dc' ]
    end

    if setup_steps.include?('bootstrap')
      steps << { :path => "bootstrap.sh", :args => [ :bootstrap_ip ] }
      setup_steps -= [ 'bootstrap' ]
    end

    if setup_steps.include?('dc')
      steps << { :path => "install_dc.sh", :args => [ :dcurl, :dcbranch ] }
      setup_steps -= [ 'dc' ]
    end

    steps += setup_steps.map { |s| { :path => "setup_#{s}.sh", :args => [:i] } }

    unless dctest.empty?
      steps << { :path => "dctest.sh", :args => dctest }
    end

    return steps
  end

  def Actions.process_args(args, options)
    return args.map { |a| (a.is_a? Symbol) ? options[a] : a }.join(' ')
  end
end
