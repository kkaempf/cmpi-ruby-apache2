#
# Provider RCP_HttpdSettingData for class RCP_HttpdSettingData:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A representation of the settings of a Httpd server connection. The
  # relationship between the SettingData and the TelnetProtocolEndpoint is
  # described by instantiating the ElementSettingData association.
  #
  #
  # CIM_SettingData is used to represent configuration and and operational
  # parameters for CIM_ManagedElement instances. There are a number of
  # different uses of CIM_SettingData supported in the model today.
  # Additional uses may be defined in the future.
  # Instances of CIM_SettingData may represent Aspects of a
  # CIM_ManagedElement instance. This is modeled using the
  # CIM_SettingsDefineState association. CIM_SettingData may be used to
  # define capabilities when associated to an instance of CIM_Capabilities
  # through the CIM_SettingsDefineCapabilities association. 
  # Instances of CIM_SettingData may represent different types of
  # configurations for a CIM_ManagedElement, including persistent
  # configurations, in progress configuration changes, or requested
  # configurations. The CIM_ElementSettingData association is used to model
  # the relationship between a CIM_SettingData instance and the
  # CIM_ManagedElement for which it is a configuration. 
  # When an instance of CIM_SettingData represents a configuration, the
  # current operational values for the parameters of the element are
  # reflected by properties in the Element itself or by properties in its
  # associations. These properties do not have to be the same values that
  # are present in the SettingData object. For example, a modem might have
  # a SettingData baud rate of 56Kb/sec but be operating at 19.2Kb/sec. 
  # Note: The CIM_SettingData class is very similar to CIM_Setting, yet
  # both classes are present in the model because many implementations have
  # successfully used CIM_Setting. However, issues have arisen that could
  # not be resolved without defining a new class. Therefore, until a new
  # major release occurs, both classes will exist in the model. Refer to
  # the Core White Paper for additional information. SettingData instances
  # can be aggregated together into higher- level SettingData objects using
  # ConcreteComponent associations.
  #
  class RCP_HttpdSettingData < InstanceProvider
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "cleanup terminating? #{terminating}"
      true
    end

    def self.typemap
      {
        "DocumentRoot" => Cmpi::string,
        "PortNumber" => Cmpi::uint32,
        "InstanceID" => Cmpi::string,
        "ElementName" => Cmpi::string,
        "ChangeableType" => Cmpi::uint16,
        "ConfigurationName" => Cmpi::string,
        "Caption" => Cmpi::string,
        "Description" => Cmpi::string,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      return unless File.exist? "/etc/apache2/default-server.conf"

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdSettingData"
      if want_instance
        result = Cmpi::CMPIInstance.new result
      end
      
      # Set key properties
      
      result.InstanceID = "Apache2" # string  (-> CIM_SettingData)
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      
      # result.DocumentRoot = nil # string  (-> RCP_HttpdSettingData)
      File.open("/etc/apache2/default-server.conf") do |f|
        f.each do |l|
          if l =~ /^DocumentRoot\s+\"([^\"]+)\"/
            result.DocumentRoot = $1
          end
        end
      end

      # result.Port = nil # uint16  (-> RCP_HttpdSettingData)
      File.open("/etc/apache2/listen.conf") do |f|
        f.each do |l|
          if l =~ /^Listen\s+(\d+)/
            result.PortNumber = $1.to_i
          end
        end
      end

      # result.ElementName = nil # string  (-> CIM_SettingData)
      result.ChangeableType = ChangeableType.send(:"Not Changeable - Persistent") # uint16  (-> CIM_SettingData)
      # result.ConfigurationName = nil # string  (-> CIM_SettingData)
      # result.Caption = nil # string MaxLen 64  (-> CIM_ManagedElement)
      # result.Description = nil # string  (-> CIM_ManagedElement)
      yield result
    end
    public
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "get_instance ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
        break # only return first instance
      end
      result.done
      true
    end
    
    def create_instance( context, result, reference, newinst )
      @trace_file.puts "create_instance ref #{reference}, newinst #{newinst.inspect}"
      # Create instance according to reference and newinst
      result.return_objectpath reference
      result.done
      true
    end
    
    def set_instance( context, result, reference, newinst, properties )
      @trace_file.puts "set_instance ref #{reference}, newinst #{newinst.inspect}, props #{properties.inspect}"
      properties.each do |prop|
        newinst.send "#{prop.name}=".to_sym, FIXME
      end
      result.return_instance newinst
      result.done
      true
    end
    
    def delete_instance( context, result, reference )
      @trace_file.puts "delete_instance ref #{reference}"
      result.done
      true
    end
    
    # query : String
    # lang : String
    def exec_query( context, result, reference, query, lang )
      keys = [ "InstanceID", "ElementName" ]
      @trace_file.puts "exec_query ref #{reference}, query #{query}, lang #{lang}"
      expr = CMPISelectExp.new query, lang, keys
      each(context, reference, nil, true) do |instance|
        @trace_file.puts "match #{instance} against #{expr}"
        if expr.match(instance)
          instance.set_property_filter expr.filter
          @trace_file.puts "match!"
          result.return_instance instance
        end
      end
      result.done
      true
    end
    
    #
    # ----------------- valuemaps following, don't touch -----------------
    #
    
    class ChangeableType < Cmpi::ValueMap
      def self.map
        {
          "Not Changeable - Persistent" => 0,
          "Changeable - Transient" => 1,
          "Changeable - Persistent" => 2,
          "Not Changeable - Transient" => 3,
        }
      end
    end
  end
end
