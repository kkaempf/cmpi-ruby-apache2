#
# Provider RCP_HttpdServiceAccessBySAP for class
# RCP_HttpdServiceAccessBySAP:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  #
  # CIM_ServiceAccessBySAP is an association that identifies the access
  # points for a Service. For example, a printer might be accessed by
  # NetWare, MacIntosh or Windows ServiceAccessPoints, which might all be
  # hosted on different Systems.
  #
  class RCP_HttpdServiceAccessBySAP < AssociationProvider

    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end

    def cleanup( context, terminating )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.cleanup terminating? #{terminating}"
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
      svc_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdProtocolService"
      enum = Cmpi.broker.enumInstanceNames context, svc_ref
      svc_ref = enum.next_element
      sap_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdProtocolEndpoint"
      enum = Cmpi.broker.enumInstanceNames context, sap_ref
      sap_ref = enum.next_element

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_HttpdServiceAccessBySAP"
      if want_instance
        result = Cmpi::CMPIInstance.new result
        result.set_property_filter(properties) if properties
      end

      # Set key properties

      result.Antecedent = svc_ref # CIM_Service ref  (-> CIM_ServiceAccessBySAP)
      result.Dependent = sap_ref # CIM_ServiceAccessPoint ref  (-> CIM_ServiceAccessBySAP)

      yield result
    end
    public

    def enum_instance_names( context, result, reference )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end

    def enum_instances( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end

    def get_instance( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.get_instance ref #{reference}, props #{properties.inspect}"
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
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.associator_names #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}"
    end

    def associators( context, result, reference, assoc_class, result_class, role, result_role, properties )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.associators #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}, #{properties}"
    end

    def reference_names( context, result, reference, result_class, role )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.reference_names #{context}, #{result}, #{reference}, #{result_class}, #{role}"
      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end

    def references( context, result, reference, result_class, role, properties )
      @trace_file.puts "RCP_HttpdServiceAccessBySAP.references #{context}, #{result}, #{reference}, #{result_class}, #{role}, #{properties}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
  end
end
