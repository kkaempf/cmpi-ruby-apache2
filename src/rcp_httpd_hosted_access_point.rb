#
# Provider RCP_HttpdHostedAccessPoint for class
# RCP_HttpdHostedAccessPoint:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  #
  # CIM_HostedAccessPoint is an association between a Service AccessPoint
  # and the System on which it is provided. The cardinality of this
  # association is one-to-many and is weak with respect to the System. Each
  # System can host many ServiceAccessPoints. Heuristic: If the
  # implementation of the ServiceAccessPoint is modeled, it must be
  # implemented by a Device or SoftwareFeature that is part of the System
  # that is hosting the ServiceAccessPoint.
  #
  class RCP_HttpdHostedAccessPoint < AssociationProvider
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.cleanup terminating? #{terminating}"
      true
    end
    
    def self.typemap
      {
        "Antecedent" => Cmpi::ref,
        "Dependent" => Cmpi::ref,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      cs_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ComputerSystem"
      enum = Cmpi.broker.enumInstanceNames context, cs_ref
      cs_ref = enum.next_element
      sap_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdProtocolEndpoint"
      enum = Cmpi.broker.enumInstanceNames context, sap_ref
      sap_ref = enum.next_element

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdHostedAccessPoint"
      if want_instance
        result = Cmpi::CMPIInstance.new result
        result.set_property_filter(properties) if properties
      end
      
      # Set key properties
      
      result.Antecedent = cs_ref # CIM_System ref Max 1 Min 1  (-> CIM_HostedAccessPoint)
      result.Dependent = sap_ref # CIM_ServiceAccessPoint ref  (-> CIM_HostedAccessPoint)
      
      yield result
    end
    public
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.get_instance ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
        break # only return first instance
      end
      result.done
      true
    end
    
    # Associations
    def associator_names( context, result, reference, assoc_class, result_class, role, result_role )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.associator_names #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}"
    end
    
    def associators( context, result, reference, assoc_class, result_class, role, result_role, properties )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.associators #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}, #{properties}"
    end
    
    def reference_names( context, result, reference, result_class, role )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.reference_names #{context}, #{result}, #{reference}, #{result_class}, #{role}"
      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def references( context, result, reference, result_class, role, properties )
      @trace_file.puts "RCP_HttpdHostedAccessPoint.references #{context}, #{result}, #{reference}, #{result_class}, #{role}, #{properties}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
  end
end
