class CFEngineProvisioner < Vagrant::Provisioners::Base

  ######################################################################

  class CFEngineError < Vagrant::Errors::VagrantError
    error_namespace("vagrant.provisioners.cfengine")
  end

  ######################################################################

  class Config < Vagrant::Config::Base
    # Valid values for the mode parameter
    CFEngineValidModes = [ :bootstrap, :singlerun ]

    # Default config values
    CFEngineConfigDefaults = {
      'mode' => :bootstrap,
      'force_bootstrap' => false,
      'install_cfengine' => true,
      'am_policy_hub' => true,
      'policy_server' => nil,
      'tarfile_url' => nil,
      'tarfile_tmpfile' =>  'downloaded-vagrant-cfengine-tarfile.tar.gz',
      'tarfile_path' => nil,
      'files_path' => nil,
      'runfile_path' => nil,
      'classes' => nil,
      'agent_options' => "",
      # Internal parameters, normally should not be modified
      'debian_repo_file' => '/etc/apt/sources.list.d/cfengine-community.list',
      'debian_repo_line' => 'deb http://cfengine.com/pub/apt $(lsb_release -cs) main',
      'yum_repo_file' =>    '/etc/yum.repos.d/cfengine-community.repo',
      'yum_repo_url' =>     'http://cfengine.com/pub/yum/',
      'repo_gpg_key_url' => 'http://cfengine.com/pub/gpg.key',
    }      

    # Generate the accessors 
    CFEngineConfigDefaults.keys.each do |param|
      eval "attr_accessor :#{param}"
      eval "def #{param}; @#{param}.nil? ? #{CFEngineConfigDefaults[param].inspect} : @#{param}; end"
    end

    def validate(env, errors)
      super

      errors.add("Invalid mode parameter, must be one of #{CFEngineValidModes.inspect}") unless CFEngineValidModes.include?(mode)
      if mode == :singlerun
        errors.add("When mode == :singlerun, you must specify the runfile_path parameter") if !runfile_path
      end
      if mode == :bootstrap
        errors.add("Invalid files_path parameter, must be an existing directory") unless !files_path || File.directory?(files_path)
        errors.add("Invalid tarfile_path parameter, must be an existing file") unless !tarfile_path || File.exists?(tarfile_path)
        errors.add("Only one of tarfile_url, tarfile_path or files_path must be specified") if (tarfile_url && files_path) || (tarfile_url && tarfile_path) || (tarfile_path && files_path)
        errors.add("tarfile_tmpfile must be a relative path inside the current directory") unless !tarfile_tmpfile || (Pathname.new(tarfile_tmpfile).relative? && tarfile_tmpfile !~ /\.\.\//)
        errors.add("tarfile_path must be a relative path inside the current directory") unless !tarfile_path || (Pathname.new(tarfile_path).relative? && tarfile_path !~ /\.\.\//)
        errors.add("files_path must be a relative path inside the current directory") unless !files_path || (Pathname.new(files_path).relative? && files_path !~ /\.\.\//)
      end
      if classes
        errors.add("Invalid classes parameter, must be a list of strings.") unless classes.is_a?(Array)
      end

      # URL validation happens in prepare.
    end
  end

  ######################################################################

  # Shamelessly copied from Vagrant::Action::Box::Download
  class CFDownloader 
    def initialize(env, url)
      @env = env
      @classes = [Vagrant::Downloaders::HTTP, Vagrant::Downloaders::File]
      @downloader = nil
      @url = url
      instantiate_downloader
    end

    def instantiate_downloader

      # Find the class to use.
      @classes.each_index do |i|
        klass = @classes[i]

        # Use the class if it matches the given URI or if this
        # is the last class...
        if @classes.length == (i + 1) || klass.match?(@url)
          @env[:vm].ui.info I18n.t("vagrant.actions.box.download.with", :class => klass.to_s)
          @downloader = klass.new(@env[:vm].ui)
          break
        end
      end

      # This line should never be reached, but we'll keep this here
      # just in case for now.
      raise Errors::CFEngineDownloadUnknownType if !@downloader

      @downloader.prepare(@url)
      true
    end

    def download_to(f)
      @downloader.download!(@url, f)
    end
  end

  ######################################################################

  def initialize(env, config)
    super
    @logger = Log4r::Logger.new("vagrant::provisioners::cfengine")
  end

  def self.config_class
    Config
  end

  def prepare
    # We download the tarfile, if necessary, during prepare, so during provision!
    # we can just copy it to the VM.
    if config.tarfile_url
      @downloader = CFDownloader.new(@env, config.tarfile_url)
      f = File.open(config.tarfile_tmpfile, "w")
      @downloader.download_to(f)
      f.close
    end
  end

  def provision!
    # First install CFEngine, if requested and necessary
    if !verify_cfengine_installation || config.install_cfengine == :force
      # Configure for the package mechanism to use
      set_packager_variables

      if config.install_cfengine
        add_cfengine_repo
        install_cfengine_package
        unless verify_cfengine_installation
          # TODO: eliminate the error once the proper message for the exception is added to en.yml
          env[:vm].ui.error("CFEngine installation failed, cannot provision host")
          raise CFEngineError, :cfengine_installation_failed
        end
      else
        # TODO: eliminate the error once the proper message for the exception is added to en.yml
        env[:vm].ui.error("CFEngine is not installed, and config.install_cfengine is set to false. Cannot provision host.")
        raise CFEngineError, :cfengine_not_installed
        return
      end
    end

    # Install /var/cfengine files if necessary
    if config.tarfile_url
      install_tarfile(config.tarfile_tmpfile)
      File.unlink(config.tarfile_tmpfile)
    elsif config.tarfile_path
      install_tarfile(config.tarfile_path)
    elsif config.files_path
      install_files(config.files_path)
    end

    if config.mode == :bootstrap
      # If mode == :bootstrap, we may need to install some files, and then bootstrap the system
      env[:vm].ui.info("Operating in bootstrap mode.")
      fix_critical_permissions
      if !verify_bootstrap || config.force_bootstrap
        env[:vm].ui.info("Re-bootstrapping because config.force_bootstrap is set to 'true'") if config.force_bootstrap
        bootstrap_cfengine
      else
        env[:vm].ui.info("CFEngine has already been bootstrapped, no need to do it again")
      end
    end
    
    # In :singlerun mode, we just run the requested policy file
    env[:vm].ui.info("Operating in singlerun mode.") if config.mode == :singlerun

    # runfile_path is also valid in :bootstrap mode
    if config.runfile_path
      env[:vm].ui.info("Running requested file: #{config.runfile_path}")
      # If runfile_path is a relative path, we assume it's inside the /vagrant directory
      # We enclose the path in quotes in case there are spaces in there
      if Pathname.new(config.runfile_path).relative?
        runfile = "'/vagrant/#{config.runfile_path}'"
      else
        runfile = "'#{config.runfile_path}'"
      end
      cmd = "/var/cfengine/bin/cf-agent -KI -f #{runfile} #{classes_args} #{config.agent_options}"
      env[:vm].ui.info("Command: #{cmd}")
      status = env[:vm].channel.sudo(cmd, :error_check => false)  do |type, data|
        output_from_cmd(type, data)
      end
      if status != 0
        env[:vm].ui.error("cf-agent returned non-zero exit code: #{status}")
        raise CFEngineError, :runfile_error
      end
    end
  end

  # Helper functions

  def verify_cfengine_installation
    env[:vm].ui.info("Checking if CFEngine is already installed in this host.")
    return env[:vm].channel.test("test -d /var/cfengine && test -x /var/cfengine/bin/cf-agent", :sudo => true)
  end

  def verify_bootstrap
    # This only checks that the host has at some point been bootstrapped, it does not check
    # the state of the connection to the hub, the running daemons, or anything else.
    env[:vm].ui.info("Checking if CFEngine has already been bootstrapped.")
    return env[:vm].channel.test("test -f /var/cfengine/policy_server.dat", :sudo => true)
  end

  def add_deb_repo
    env[:vm].ui.info("Adding the CFEngine repository to #{config.debian_repo_file}")
    env[:vm].channel.sudo("mkdir -p #{File.dirname(config.debian_repo_file)} && /bin/echo #{config.debian_repo_line} > #{config.debian_repo_file}")
    env[:vm].channel.sudo("GPGFILE=`tempfile`; wget -O $GPGFILE #{config.repo_gpg_key_url} && apt-key add $GPGFILE; rm -f $GPGFILE")
  end

  def add_yum_repo
    env[:vm].ui.info("Adding the CFEngine repository to #{config.yum_repo_file}")
    env[:vm].channel.sudo("mkdir -p #{File.dirname(config.yum_repo_file)} && (echo '[cfengine-repository]'; echo 'name=CFEngine Community Yum Repository'; echo 'baseurl=#{config.yum_repo_url}'; echo 'enabled=1'; echo 'gpgcheck=1') > #{config.yum_repo_file}")
    env[:vm].ui.info("Installing CFEngine Community Yum Repository GPG KEY from #{config.repo_gpg_key_url}")
    env[:vm].channel.sudo("GPGFILE=$(mktemp) && wget -O $GPGFILE #{config.repo_gpg_key_url} && rpm --import $GPGFILE; rm -f $GPGFILE")
  end

  def get_vm_packager
    if env[:vm].channel.test("test -d /etc/apt")
      :apt
    elsif env[:vm].channel.test("test -f /etc/yum.conf")
      :yum
    else
      :other
    end
  end

  def set_packager_variables
    # Determine the type of distro if possible
    @__distro = get_vm_packager
    if @__distro == :apt
      @__pkg_install_cmd = "apt-get install"
      @__pkg_update_cmd = "apt-get update"
    elsif @__distro == :yum
      @__pkg_install_cmd = "yum -y install"
      @__pkg_update_cmd = nil
    else
      env[:vm].ui.error("I don't know how to install packages in this distribution.")
      raise CFEngineError, :unsupported_cfengine_package_distro
    end
  end

  def add_cfengine_repo
    if @__distro == :apt
      add_deb_repo
    elsif @__distro == :yum
      add_yum_repo
    else
      env[:vm].ui.error("Don't know how to configure the CFEngine package repository in this distribution")
      raise CFEngineError, :unsupported_cfengine_package_distro
    end
  end

  def install_cfengine_package
    env[:vm].ui.info("Installing the CFEngine binary package.")
    env[:vm].channel.sudo("#{@__pkg_update_cmd}")
    env[:vm].channel.sudo("#{@__pkg_install_cmd} cfengine-community")
  end

  # tarfile is assumed to be a relative path within the current directory
  def install_tarfile(tarfile)
    unless File.exists?(tarfile)
      env[:vm].ui.error("The tarfile #{tarfile} does not exist, cannot install on VM.")
      raise CFEngineError, :tarfile_disappeared
    end
    # Then untar it on the VM
    env[:vm].ui.info("Unpacking tarfile on VM from /vagrant/#{tarfile}")
    env[:vm].channel.sudo("cd /var/cfengine && tar zxvf '/vagrant/#{tarfile}'")
  end

  # dirpath is assumed to be a relative path within the current directory
  def install_files(dirpath)
    # Copy the contents of dirpath to /var/cfengine on the VM
    unless File.directory?(dirpath)
      env[:vm].ui.error("The path #{dirpath} must exist and be a directory")
      raise CFEngineError, :invalid_files_directory
    end
    env[:vm].ui.info("Copying files from /vagrant/#{dirpath} to /var/cfengine on VM")
    env[:vm].channel.sudo("cp -a '/vagrant/#{dirpath}/'* /var/cfengine")
  end

  def fix_critical_permissions
    # We hardcode fixing the permissions on /var/cfengine/ppkeys/, if it exists,
    # because otherwise CFEngine will fail to bootstrap.
    if env[:vm].channel.test("test -d /var/cfengine/ppkeys", :sudo => true)
      env[:vm].ui.info("Setting permissions to 600 on /var/cfengine/ppkeys on VM")
      env[:vm].channel.sudo("chmod -R 600 /var/cfengine/ppkeys")
    end
  end

  def classes_args
    # Return a string appropriate for passing as arguments to cf-agent, containing
    # the classes to define, if any
    if config.classes
      return config.classes.map { |c| "-D#{c}" }.join(" ")
    else
      return ""
    end
  end

  def bootstrap_cfengine
    if config.am_policy_hub
      # For the policy server, config.policy_server is optional
      ipaddr = (config.policy_server.nil? || config.policy_server.empty?) ? get_my_ipaddr : config.policy_server
      if !ipaddr
        env[:vm].ui.error("I couldn't find my IP address for bootstrap, and no policy_server config parameter was specified in the Vagrantfile.")
        raise CFEngineError, :no_bootstrap_ip
      else
        name = "CFEngine policy hub"
      end
    else
      # For clients, config.policy_server is mandatory
      ipaddr = config.policy_server
      if !ipaddr
        env[:vm].ui.error("You need to specify the policy_server config parameter in the Vagrantfile.")
        raise CFEngineError, :no_bootstrap_ip
      else
        name = "CFEngine client"
      end
    end
    env[:vm].ui.info("I am a #{name}, bootstrapping to policy server at #{ipaddr}.")
    status = env[:vm].channel.sudo("/var/cfengine/bin/cf-agent --bootstrap --policy-server #{ipaddr}", :error_check => false) do |type, data|
      output_from_cmd(type, data)
    end
    if status == 0
      env[:vm].ui.info("#{name} bootstrapped successfully.")
      if config.am_policy_hub
        # The policy hub might need to execute some policy before agents
        # will be able to bootstrap against it (adjust fw policy).
        # It might not happen on it's own before the first client comes
        # up. This will only help if the hub is the first provisioned node.
        env[:vm].ui.info("Because I am a hub, running cf-agent manually for the first time to finish initialization.")
        cmd = "/var/cfengine/bin/cf-agent -K -f /var/cfengine/masterfiles/failsafe.cf #{classes_args} && /var/cfengine/bin/cf-agent -K #{classes_args} #{config.agent_options}"
        env[:vm].ui.info("Command: #{cmd}")
        env[:vm].channel.sudo(cmd) do |type,data|
          output_from_cmd(type, data)
        end
      end
    else
      env[:vm].ui.error("Error bootstrapping #{name}.")
      raise CFEngineError, :bootstrap_error
    end
  end

  # Utilities

  def execute_capture(cmd, user_opts={})
    opts = user_opts.merge({:error_check => false})
    stdout = nil
    stderr = nil
    exit_status = env[:vm].channel.execute(cmd, :error_check => false) do |type, data|
      if type == :stdout
        stdout = (stdout||"") + data
      else
        stderr = (stderr||"") + data
      end
    end
    return [exit_status, stdout, stderr]
  end

  def output_from_cmd(type, data)
    # Output the data with the proper color based on the stream.
    color = type == :stdout ? :green : :red
    
    # Note: Be sure to chomp the data to avoid extra newlines.
    env[:vm].ui.info(data.chomp, :color => color, :prefix => false)
  end

  def get_my_ipaddr
    (status, out, err) = execute_capture("ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'")
    @logger.debug("Obtaining host's IP address: status=#{status}, out=#{out}, err=#{err}")
    if status != 0
      env[:vm].ui.error("Error obtaining my IP address: #{err}", :color => :red)
    else
      ipaddr = (out.split)[0]
    end
    ipaddr
  end

end
