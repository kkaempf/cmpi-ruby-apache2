#
# Provider RCP_HttpdHostedService for class
# RCP_HttpdHostedService:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  #
  # CIM_HostedService is an association between a Service and the System on
  # which the functionality is located. The cardinality of this association
  # is one-to-many. A System can host many Services. Services are weak with
  # respect to their hosting System. Heuristic: A Service is hosted on the
  # System where the LogicalDevices or SoftwareFeatures that implement the
  # Service are located. The model does not represent Services hosted
  # across multiple systems. The model is as an ApplicationSystem that acts
  # as an aggregation point for Services that are each located on a single
  # host.
  #
  class RCP_HttpdHostedService < AssociationProvider
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "RCP_HttpdHostedService.cleanup terminating? #{terminating}"
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
      svc_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdProtocolService"
      enum = Cmpi.broker.enumInstanceNames context, svc_ref
      svc_ref = enum.next_element

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdHostedService"
      if want_instance
        result = Cmpi::CMPIInstance.new result
        result.set_property_filter(properties) if properties
      end
      
      # Set key properties
      
      result.Antecedent = cs_ref # CIM_System ref Max 1 Min 1  (-> CIM_HostedService)
      result.Dependent = svc_ref # CIM_Service ref  (-> CIM_HostedService)
      
      yield result
    end
    public
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "RCP_HttpdHostedService.enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdHostedService.enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdHostedService.get_instance ref #{reference}, props #{properties.inspect}"
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
      @trace_file.puts "RCP_HttpdHostedService.associator_names #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}"
    end
    
    def associators( context, result, reference, assoc_class, result_class, role, result_role, properties )
      @trace_file.puts "RCP_HttpdHostedService.associators #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}, #{properties}"
    end
    
    def reference_names( context, result, reference, result_class, role )
      @trace_file.puts "RCP_HttpdHostedService.reference_names #{context}, #{result}, #{reference}, #{result_class}, #{role}"
      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def references( context, result, reference, result_class, role, properties )
      @trace_file.puts "RCP_HttpdHostedService.references #{context}, #{result}, #{reference}, #{result_class}, #{role}, #{properties}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
  end
end
