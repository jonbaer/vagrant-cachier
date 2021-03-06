require_relative 'provision_ext'
Vagrant::Action::Builtin::Provision.class_eval do
  include VagrantPlugins::Cachier::ProvisionExt
end

# Add our custom translations to the load path
I18n.load_path << File.expand_path("../../../locales/en.yml", __FILE__)

module VagrantPlugins
  module Cachier
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-cachier'

      config 'cache' do
        require_relative "config"
        Config
      end

      guest_capability 'linux', 'gemdir' do
        require_relative 'cap/linux/gemdir'
        Cap::Linux::Gemdir
      end

      guest_capability 'linux', 'rvm_path' do
        require_relative 'cap/linux/rvm_path'
        Cap::Linux::RvmPath
      end

      guest_capability 'linux', 'chef_file_cache_path' do
        require_relative 'cap/linux/chef_file_cache_path'
        Cap::Linux::ChefFileCachePath
      end

      guest_capability 'debian', 'apt_cache_dir' do
        require_relative 'cap/debian/apt_cache_dir'
        Cap::Debian::AptCacheDir
      end

      guest_capability 'redhat', 'yum_cache_dir' do
        require_relative 'cap/redhat/yum_cache_dir'
        Cap::RedHat::YumCacheDir
      end

      guest_capability 'arch', 'pacman_cache_dir' do
        require_relative 'cap/arch/pacman_cache_dir'
        Cap::Arch::PacmanCacheDir
      end

      # TODO: This should be generic, we don't want to hard code every single
      #       possible provider action class that Vagrant might have
      ensure_single_cache_root = lambda do |hook|
        require_relative 'action/ensure_single_cache_root'
        hook.before VagrantPlugins::ProviderVirtualBox::Action::Boot, Action::EnsureSingleCacheRoot

        if defined?(Vagrant::LXC)
          # TODO: Require just the boot action file once its "require dependencies" are sorted out
          require 'vagrant-lxc/action'
          hook.before Vagrant::LXC::Action::Boot, Action::EnsureSingleCacheRoot
        end
      end
      action_hook 'ensure-single-cache-root-exists-on-up',     :machine_action_up,     &ensure_single_cache_root
      action_hook 'ensure-single-cache-root-exists-on-reload', :machine_action_reload, &ensure_single_cache_root

      clean_action_hook = lambda do |hook|
        require_relative 'action/clean'
        hook.before Vagrant::Action::Builtin::GracefulHalt, Action::Clean
      end
      action_hook 'remove-guest-symlinks-on-halt',    :machine_action_halt,    &clean_action_hook
      action_hook 'remove-guest-symlinks-on-package', :machine_action_package, &clean_action_hook
    end
  end
end
