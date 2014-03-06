# encoding: UTF-8
require 'rspec'
require 'fileutils'
require 'tempfile'
require 'pathname'
require 'base64'
require_relative '../lib/rivet'

Rivet::Log.level(Logger::FATAL)

module SpecHelpers
  AUTOSCALE_DIR      = File.join('.', 'autoscale')
  CONFIG_FILE        = File.join(AUTOSCALE_DIR, 'unit_test.rb')
  TEMPLATE_FILE      = File.join(AUTOSCALE_DIR, 'default.erb')
  BOOTSTRAP_TEMPLATE = '<%= "bar" %>'\

  DSL_VALUES = {
    :min_size                     => '1',
    :desired_capacity             => '1',
    :max_size                     => '3',
    :region                       => "'us-west-2'",
    :availability_zones           => '%w(b c a)',
    :key_name                     => "'UnitTests'",
    :instance_type                => "'m1.large'",
    :security_groups              => '%w(unit_test3 unit_tests1 unit_tests2)',
    :image_id                     => "'ami-12345678'",
    :iam_instance_profile         => "'unit_test_profile'",
    :default_cooldown             => '300',
    :placement_group              => "'unit test placement group'",
    :health_check_type            => ':ec2',
    :termination_policies         => '%w(policy2 policy1)',
    :load_balancers               => '%w(balancer2 balancer1)',
    :health_check_grace_period    => '100',
    :associate_public_ip_address  => 'true',
    :detailed_instance_monitoring => 'true',
    :block_device_mappings        => "[{:device_name => '/dev/sda1', :virtual_name => 'ephemeral0'}]",
    :kernel_id                    => "'aki-12345678'",
    :ramdisk_id                   => "'ari-12345678'",
    :spot_price                   => "'0.01'",
    :bootstrap                    => {
      :template => "'#{TEMPLATE_FILE}'",
      :foo => "'bar'"
    }
  }
  DSL_CONFIG_CONTENT = DSL_VALUES.inject(String.new) do |a, (k, v)|
    if k == :bootstrap
      v.each_pair do |bootstrap_attr, bootstrap_value|
        a << "bootstrap.#{bootstrap_attr} #{bootstrap_value}\n"
      end
    else
      a << "#{k} #{v}\n";
    end
    a
  end

  AUTOSCALE_IDENTITY_STRING = "bootstrap#{Base64.encode64('unit_test_user_data')}"\
                              "iam_instance_profile#{Base64.encode64(eval(DSL_VALUES[:iam_instance_profile]))}"\
                              "image_id#{Base64.encode64(eval(DSL_VALUES[:image_id]))}"\
                              "instance_type#{Base64.encode64(eval(DSL_VALUES[:instance_type]))}"\
                              "key_name#{Base64.encode64(eval(DSL_VALUES[:key_name]))}"\
                              "security_groups#{Base64.encode64(eval(DSL_VALUES[:security_groups]).join("\t"))}"\
                              "associate_public_ip_address#{Base64.encode64(eval(DSL_VALUES[:associate_public_ip_address]).to_s)}"\
                              "detailed_instance_monitoring#{Base64.encode64(eval(DSL_VALUES[:detailed_instance_monitoring]).to_s)}"\
                              "block_device_mappings#{Base64.encode64(eval(DSL_VALUES[:block_device_mappings]).join("\t"))}"\
                              "kernel_id#{Base64.encode64(eval(DSL_VALUES[:kernel_id]))}"\
                              "ramdisk_id#{Base64.encode64(eval(DSL_VALUES[:ramdisk_id]))}"\
                              "spot_price#{Base64.encode64(eval(DSL_VALUES[:spot_price]))}"

  def tempdir_context(name, &block)
    context name do
      before do
        @origin_dir = Dir.pwd
        @temp_dir = ::Pathname.new(::File.expand_path(::Dir.mktmpdir))
        Dir.chdir @temp_dir
      end

      after do
        Dir.chdir @origin_dir
        FileUtils.remove_entry(@temp_dir)
      end

      instance_eval &block
    end
  end

  def dsl_from_hash(hash)


  end

  def generate_config_mock(mock, attrs)
    attrs.each_pair do |a, v|
      if v.respond_to? :each_pair
        sub_mock = generate_config_mock(double("#{a} mock"), v)
        mock.stub(a).and_return(sub_mock)
      else
        mock.stub(a).and_return(eval(v))
      end
    end
    mock
  end

  def valid_config?(config, dsl_values)
    dsl_values.each_pair do |k, v|
      if v.respond_to? :each_pair
        valid_config?(config.send(k), v)
      else
        config.send(k).should == eval(v)
      end
    end
  end
end
