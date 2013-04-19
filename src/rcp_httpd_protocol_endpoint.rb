#
# Provider RCP_HttpdProtocolEndpoint for classes
# RCP_HttpdProtocolEndpoint:CIM::Class
# RCP_HttpdTCPProtocolEndpoint:CIM::Class
# RCP_HttpdProtocolService:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A communication point from which data can be sent or received.
  # ProtocolEndpoints link system or computer interfaces to
  # LogicalNetworks.
  #
  #
  # A communication point from which data can be sent or received.
  # ProtocolEndpoints link system or computer interfaces to
  # LogicalNetworks.
  #
  class RCP_HttpdProtocolEndpoint < MethodProvider
    
    include InstanceProviderIF
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.cleanup terminating? #{terminating}"
      true
    end
    
    def self.typemap
      {
        "Description" => Cmpi::string,
        "OperationalStatus" => Cmpi::uint16A,
        "EnabledState" => Cmpi::uint16,
        "TimeOfLastStateChange" => Cmpi::dateTime,
        "Name" => Cmpi::string,
        "NameFormat" => Cmpi::string,
        "ProtocolType" => Cmpi::uint16,
        "ProtocolIFType" => Cmpi::uint16,
        "OtherTypeDescription" => Cmpi::string,
        "SystemCreationClassName" => Cmpi::string,
        "SystemName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "OtherEnabledState" => Cmpi::string,
        "RequestedState" => Cmpi::uint16,
        "EnabledDefault" => Cmpi::uint16,
        "AvailableRequestedStates" => Cmpi::uint16A,
        "TransitioningToState" => Cmpi::uint16,
        "InstallDate" => Cmpi::dateTime,
        "StatusDescriptions" => Cmpi::stringA,
        "Status" => Cmpi::string,
        "HealthState" => Cmpi::uint16,
        "CommunicationStatus" => Cmpi::uint16,
        "DetailedStatus" => Cmpi::uint16,
        "OperatingStatus" => Cmpi::uint16,
        "PrimaryStatus" => Cmpi::uint16,
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "ElementName" => Cmpi::string,
      }
    end
    
    # Methods
    
    # CIM_EnabledLogicalElement: uint32 RequestStateChange(...)
    #
    # type information for RequestStateChange(...)
    def request_state_change_args; [["RequestedState", Cmpi::uint16, "TimeoutPeriod", Cmpi::dateTime],[Cmpi::uint32, "Job", Cmpi::ref]] end
    #
    # See class RequestStateChange for return values
    #
    # Input args
    #  RequestedState : uint16
    #    The state requested for the element. This information will be
    #    placed into the RequestedState property of the instance if the
    #    return code of the RequestStateChange method is 0 (\'Completed
    #    with No Error\'), or 4096 (0x1000) (\'Job Started\'). Refer to the
    #    description of the EnabledState and RequestedState properties for
    #    the detailed explanations of the RequestedState values.
    #    Value can be one of
    #      Enabled: 2
    #      Disabled: 3
    #      Shut Down: 4
    #      Offline: 6
    #      Test: 7
    #      Defer: 8
    #      Quiesce: 9
    #      Reboot: 10
    #      Reset: 11
    #      DMTF Reserved: ..
    #      Vendor Reserved: 32768..65535
    #  TimeoutPeriod : dateTime
    #    A timeout period that specifies the maximum amount of time that
    #    the client expects the transition to the new state to take. The
    #    interval format must be used to specify the TimeoutPeriod. A value
    #    of 0 or a null parameter indicates that the client has no time
    #    requirements for the transition. 
    #    If this property does not contain 0 or null and the implementation
    #    does not support this parameter, a return code of \'Use Of Timeout
    #    Parameter Not Supported\' shall be returned.
    #
    # Additional output args
    #  Job : CIM_ConcreteJob ref
    #    May contain a reference to the ConcreteJob created to track the
    #    state transition initiated by the method invocation.
    #
    def request_state_change( context, reference, requested_state, job, timeout_period )
      @trace_file.puts "request_state_change #{context}, #{reference}, #{requested_state}, #{job}, #{timeout_period}"
      method_return_value = RequestStateChange.send(:"Completed with No Error") # uint32
      
      # Output arguments
      job = nil # CIM_ConcreteJob ref
      
      #  function body goes here
      
      return [method_return_value, job]
    end
    
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      result = Cmpi::CMPIObjectPath.new reference.namespace, reference.classname
      if want_instance
        result = Cmpi::CMPIInstance.new result
        result.set_property_filter(properties) if properties
      end
      
      # Set key properties
      
      case reference.classname
      when "RCP_HttpdTCPProtocolEndpoint"
        result.Name = "Apache2 TCP Server Endpoint" # string MaxLen 256  (-> CIM_ProtocolEndpoint)
      when "RCP_HttpdProtocolEndpoint"
        result.Name = "Apache2 Server Endpoint" # string MaxLen 256  (-> CIM_ProtocolEndpoint)
      when "RCP_HttpdProtocolService"
        result.Name = "Apache2 HTTP service" # string MaxLen 256  (-> CIM_Service)
      else
        raise "rcp_httpd_protocol_endpoint.rb does not serve #{reference.classname}"
      end

      # Get HttpdSettingData for port
      enum = Cmpi.broker.enumInstances(context, Cmpi::CMPIObjectPath.new(reference.namespace, "RCP_HttpdSettingData"), ["PortNumber"])
      unless enum.has_next
        return # no apache2 found
      end
      data = enum.next_element
      port = data.PortNumber.to_i
      proto = nil
      # check for tcp/udp listener on port
      IO.popen("netstat -tuln") do |io|
        io.each do |l|
          # Proto Recv-Q Send-Q Local Address           Foreign Address         State      
          # tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      
          if l =~ /^([\w]+)\s+[^\s]+\s+[^\s+]\s+[^:]+:(\d+)\s+[^\s]+\s+LISTEN/
            if $2.to_i == port
              proto = $1
              break
            end
          end
        end
      end
      
      # get scoping system
      enum = Cmpi.broker.enumInstanceNames(context, Cmpi::CMPIObjectPath.new(reference.namespace, "RCP_ComputerSystem"))
      raise "Upcall to RCP_ComputerSystem failed for RCP_HttpdProtocolEndpoint" unless enum.has_next
      cs = enum.next_element
      result.SystemCreationClassName = cs.CreationClassName # string MaxLen 256  (-> CIM_ServiceAccessPoint)
      result.SystemName = cs.Name # string MaxLen 256  (-> CIM_ServiceAccessPoint)
      result.CreationClassName = reference.classname # string MaxLen 256  (-> CIM_ServiceAccessPoint)
      unless want_instance
        yield result
        return
      end

      # Instance: Set non-key properties
      
      case reference.classname
      when "RCP_HttpdTCPProtocolEndpoint"
        result.Description = "Apache2 TCP protocol endpoint"
        result.PortNumber = port
        result.ProtocolIFType = ProtocolIFType.send(proto.upcase.to_sym) if proto # uint16  (-> CIM_ProtocolEndpoint)
      when "RCP_HttpdProtocolEndpoint"
        result.Description = "Apache2 protocol endpoint"
        result.ProtocolIFType = ProtocolIFType.send(proto.upcase.to_sym) if proto # uint16  (-> CIM_ProtocolEndpoint)
      when "RCP_HttpdProtocolService"
        result.Description = "Apache2 HTTP service"
        result.PrimaryOwnerName = "root" # string MaxLen 64  (-> CIM_Service)
        result.PrimaryOwnerContact = "root@#{cs.Name}" # string MaxLen 256  (-> CIM_Service)
        # result.MaxConnections = nil # uint16  (-> CIM_ProtocolService)
        result.Caption = "HTTP deamon" # string MaxLen 64  (-> CIM_ManagedElement)
        result.Protocol = Protocol.Other # uint16  (-> CIM_ProtocolService)
      else
        raise "rcp_httpd_protocol_endpoint.rb does not serve #{reference.classname}"
      end

      # result.OperationalStatus = [OperationalStatus.Unknown] # uint16[]  (-> CIM_ProtocolEndpoint)
      result.EnabledState = proto ? EnabledState.Enabled : EnabledState.Disabled # uint16  (-> CIM_ProtocolEndpoint)
      # result.TimeOfLastStateChange = nil # dateTime  (-> CIM_ProtocolEndpoint)
      # result.NameFormat = nil # string MaxLen 256  (-> CIM_ProtocolEndpoint)
      # Deprecated !
      # result.ProtocolType = ProtocolType.Unknown # uint16  (-> CIM_ProtocolEndpoint)
      # result.OtherTypeDescription = nil # string MaxLen 64  (-> CIM_ProtocolEndpoint)
      # result.OtherEnabledState = nil # string  (-> CIM_EnabledLogicalElement)
      # result.RequestedState = RequestedState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.EnabledDefault = EnabledDefault.Enabled # uint16  (-> CIM_EnabledLogicalElement)
      # result.AvailableRequestedStates = [AvailableRequestedStates.Enabled] # uint16[]  (-> CIM_EnabledLogicalElement)
      # result.TransitioningToState = TransitioningToState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.InstallDate = nil # dateTime  (-> CIM_ManagedSystemElement)
      # result.StatusDescriptions = [] # string[]  (-> CIM_ManagedSystemElement)
      # Deprecated !
      # result.Status = Status.OK # string MaxLen 10  (-> CIM_ManagedSystemElement)
      # result.HealthState = HealthState.Unknown # uint16  (-> CIM_ManagedSystemElement)
      result.CommunicationStatus = CommunicationStatus.send("Communication OK".to_sym) if proto # uint16  (-> CIM_ManagedSystemElement)
      # result.DetailedStatus = DetailedStatus.send(:"Not Available") # uint16  (-> CIM_ManagedSystemElement)
      result.OperatingStatus = proto ? OperatingStatus.Servicing : OperatingStatus.Stopped # uint16  (-> CIM_ManagedSystemElement)
      result.PrimaryStatus = proto ? PrimaryStatus.OK : PrimaryStatus.Unknown # uint16  (-> CIM_ManagedSystemElement)
      # result.InstanceID = nil # string  (-> CIM_ManagedElement)
      # result.Caption = nil # string MaxLen 64  (-> CIM_ManagedElement)
      # result.ElementName = nil # string  (-> CIM_ManagedElement)
      yield result
    end
    public
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.get_instance ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
        break # only return first instance
      end
      result.done
      true
    end
    
    def create_instance( context, result, reference, newinst )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.create_instance ref #{reference}, newinst #{newinst.inspect}"
      # Create instance according to reference and newinst
      result.return_objectpath reference
      result.done
      true
    end
    
    def set_instance( context, result, reference, newinst, properties )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.set_instance ref #{reference}, newinst #{newinst.inspect}, props #{properties.inspect}"
      properties.each do |prop|
        newinst.send "#{prop.name}=".to_sym, FIXME
      end
      result.return_instance newinst
      result.done
      true
    end
    
    def delete_instance( context, result, reference )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.delete_instance ref #{reference}"
      result.done
      true
    end
    
    # query : String
    # lang : String
    def exec_query( context, result, reference, query, lang )
      @trace_file.puts "RCP_HttpdProtocolEndpoint.exec_query ref #{reference}, query #{query}, lang #{lang}"
      keys = ["Name", "SystemCreationClassName", "SystemName", "CreationClassName"]
      expr = CMPISelectExp.new query, lang, keys
      each(context, reference, expr.filter, true) do |instance|
        if expr.match(instance)
          result.return_instance instance
        end
      end
      result.done
      true
    end
    
    #
    # ----------------- valuemaps following, don't touch -----------------
    #
    
    class Protocol < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "SSH" => 2,
          "Telnet" => 3,
          "CLP" => 4,
          "CIM-XML" => 5,
          "WS-Management" => 6,
          "CIM-RS" => 7,
          # "DMTF Reserved" => 8..32767,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end

    class OperationalStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "OK" => 2,
          "Degraded" => 3,
          "Stressed" => 4,
          "Predictive Failure" => 5,
          "Error" => 6,
          "Non-Recoverable Error" => 7,
          "Starting" => 8,
          "Stopping" => 9,
          "Stopped" => 10,
          "In Service" => 11,
          "No Contact" => 12,
          "Lost Communication" => 13,
          "Aborted" => 14,
          "Dormant" => 15,
          "Supporting Entity in Error" => 16,
          "Completed" => 17,
          "Power Mode" => 18,
          "Relocating" => 19,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class EnabledState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shutting Down" => 4,
          "Not Applicable" => 5,
          "Enabled but Offline" => 6,
          "In Test" => 7,
          "Deferred" => 8,
          "Quiesce" => 9,
          "Starting" => 10,
          # "DMTF Reserved" => 11..32767,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class ProtocolType < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "IPv4" => 2,
          "IPv6" => 3,
          "IPX" => 4,
          "AppleTalk" => 5,
          "DECnet" => 6,
          "SNA" => 7,
          "CONP" => 8,
          "CLNP" => 9,
          "VINES" => 10,
          "XNS" => 11,
          "ATM" => 12,
          "Frame Relay" => 13,
          "Ethernet" => 14,
          "TokenRing" => 15,
          "FDDI" => 16,
          "Infiniband" => 17,
          "Fibre Channel" => 18,
          "ISDN BRI Endpoint" => 19,
          "ISDN B Channel Endpoint" => 20,
          "ISDN D Channel Endpoint" => 21,
          "IPv4/v6" => 22,
          "BGP" => 23,
          "OSPF" => 24,
          "MPLS" => 25,
          "UDP" => 26,
          "TCP" => 27,
        }
      end
    end
    
    class ProtocolIFType < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "Regular 1822" => 2,
          "HDH 1822" => 3,
          "DDN X.25" => 4,
          "RFC877 X.25" => 5,
          "Ethernet CSMA/CD" => 6,
          "ISO 802.3 CSMA/CD" => 7,
          "ISO 802.4 Token Bus" => 8,
          "ISO 802.5 Token Ring" => 9,
          "ISO 802.6 MAN" => 10,
          "StarLAN" => 11,
          "Proteon 10Mbit" => 12,
          "Proteon 80Mbit" => 13,
          "HyperChannel" => 14,
          "FDDI" => 15,
          "LAP-B" => 16,
          "SDLC" => 17,
          "DS1" => 18,
          "E1" => 19,
          "Basic ISDN" => 20,
          "Primary ISDN" => 21,
          "Proprietary Point-to-Point Serial" => 22,
          "PPP" => 23,
          "Software Loopback" => 24,
          "EON" => 25,
          "Ethernet 3Mbit" => 26,
          "NSIP" => 27,
          "SLIP" => 28,
          "Ultra" => 29,
          "DS3" => 30,
          "SIP" => 31,
          "Frame Relay" => 32,
          "RS-232" => 33,
          "Parallel" => 34,
          "ARCNet" => 35,
          "ARCNet Plus" => 36,
          "ATM" => 37,
          "MIO X.25" => 38,
          "SONET" => 39,
          "X.25 PLE" => 40,
          "ISO 802.211c" => 41,
          "LocalTalk" => 42,
          "SMDS DXI" => 43,
          "Frame Relay Service" => 44,
          "V.35" => 45,
          "HSSI" => 46,
          "HIPPI" => 47,
          "Modem" => 48,
          "AAL5" => 49,
          "SONET Path" => 50,
          "SONET VT" => 51,
          "SMDS ICIP" => 52,
          "Proprietary Virtual/Internal" => 53,
          "Proprietary Multiplexor" => 54,
          "IEEE 802.12" => 55,
          "Fibre Channel" => 56,
          "HIPPI Interface" => 57,
          "Frame Relay Interconnect" => 58,
          "ATM Emulated LAN for 802.3" => 59,
          "ATM Emulated LAN for 802.5" => 60,
          "ATM Emulated Circuit" => 61,
          "Fast Ethernet (100BaseT)" => 62,
          "ISDN" => 63,
          "V.11" => 64,
          "V.36" => 65,
          "G703 at 64K" => 66,
          "G703 at 2Mb" => 67,
          "QLLC" => 68,
          "Fast Ethernet 100BaseFX" => 69,
          "Channel" => 70,
          "IEEE 802.11" => 71,
          "IBM 260/370 OEMI Channel" => 72,
          "ESCON" => 73,
          "Data Link Switching" => 74,
          "ISDN S/T Interface" => 75,
          "ISDN U Interface" => 76,
          "LAP-D" => 77,
          "IP Switch" => 78,
          "Remote Source Route Bridging" => 79,
          "ATM Logical" => 80,
          "DS0" => 81,
          "DS0 Bundle" => 82,
          "BSC" => 83,
          "Async" => 84,
          "Combat Net Radio" => 85,
          "ISO 802.5r DTR" => 86,
          "Ext Pos Loc Report System" => 87,
          "AppleTalk Remote Access Protocol" => 88,
          "Proprietary Connectionless" => 89,
          "ITU X.29 Host PAD" => 90,
          "ITU X.3 Terminal PAD" => 91,
          "Frame Relay MPI" => 92,
          "ITU X.213" => 93,
          "ADSL" => 94,
          "RADSL" => 95,
          "SDSL" => 96,
          "VDSL" => 97,
          "ISO 802.5 CRFP" => 98,
          "Myrinet" => 99,
          "Voice Receive and Transmit" => 100,
          "Voice Foreign Exchange Office" => 101,
          "Voice Foreign Exchange Service" => 102,
          "Voice Encapsulation" => 103,
          "Voice over IP" => 104,
          "ATM DXI" => 105,
          "ATM FUNI" => 106,
          "ATM IMA" => 107,
          "PPP Multilink Bundle" => 108,
          "IP over CDLC" => 109,
          "IP over CLAW" => 110,
          "Stack to Stack" => 111,
          "Virtual IP Address" => 112,
          "MPC" => 113,
          "IP over ATM" => 114,
          "ISO 802.5j Fibre Token Ring" => 115,
          "TDLC" => 116,
          "Gigabit Ethernet" => 117,
          "HDLC" => 118,
          "LAP-F" => 119,
          "V.37" => 120,
          "X.25 MLP" => 121,
          "X.25 Hunt Group" => 122,
          "Transp HDLC" => 123,
          "Interleave Channel" => 124,
          "FAST Channel" => 125,
          "IP (for APPN HPR in IP Networks)" => 126,
          "CATV MAC Layer" => 127,
          "CATV Downstream" => 128,
          "CATV Upstream" => 129,
          "Avalon 12MPP Switch" => 130,
          "Tunnel" => 131,
          "Coffee" => 132,
          "Circuit Emulation Service" => 133,
          "ATM SubInterface" => 134,
          "Layer 2 VLAN using 802.1Q" => 135,
          "Layer 3 VLAN using IP" => 136,
          "Layer 3 VLAN using IPX" => 137,
          "Digital Power Line" => 138,
          "Multimedia Mail over IP" => 139,
          "DTM" => 140,
          "DCN" => 141,
          "IP Forwarding" => 142,
          "MSDSL" => 143,
          "IEEE 1394" => 144,
          "IF-GSN/HIPPI-6400" => 145,
          "DVB-RCC MAC Layer" => 146,
          "DVB-RCC Downstream" => 147,
          "DVB-RCC Upstream" => 148,
          "ATM Virtual" => 149,
          "MPLS Tunnel" => 150,
          "SRP" => 151,
          "Voice over ATM" => 152,
          "Voice over Frame Relay" => 153,
          "ISDL" => 154,
          "Composite Link" => 155,
          "SS7 Signaling Link" => 156,
          "Proprietary P2P Wireless" => 157,
          "Frame Forward" => 158,
          "RFC1483 Multiprotocol over ATM" => 159,
          "USB" => 160,
          "IEEE 802.3ad Link Aggregate" => 161,
          "BGP Policy Accounting" => 162,
          "FRF .16 Multilink FR" => 163,
          "H.323 Gatekeeper" => 164,
          "H.323 Proxy" => 165,
          "MPLS" => 166,
          "Multi-Frequency Signaling Link" => 167,
          "HDSL-2" => 168,
          "S-HDSL" => 169,
          "DS1 Facility Data Link" => 170,
          "Packet over SONET/SDH" => 171,
          "DVB-ASI Input" => 172,
          "DVB-ASI Output" => 173,
          "Power Line" => 174,
          "Non Facility Associated Signaling" => 175,
          "TR008" => 176,
          "GR303 RDT" => 177,
          "GR303 IDT" => 178,
          "ISUP" => 179,
          "Proprietary Wireless MAC Layer" => 180,
          "Proprietary Wireless Downstream" => 181,
          "Proprietary Wireless Upstream" => 182,
          "HIPERLAN Type 2" => 183,
          "Proprietary Broadband Wireless Access Point to Mulipoint" => 184,
          "SONET Overhead Channel" => 185,
          "Digital Wrapper Overhead Channel" => 186,
          "ATM Adaptation Layer 2" => 187,
          "Radio MAC" => 188,
          "ATM Radio" => 189,
          "Inter Machine Trunk" => 190,
          "MVL DSL" => 191,
          "Long Read DSL" => 192,
          "Frame Relay DLCI Endpoint" => 193,
          "ATM VCI Endpoint" => 194,
          "Optical Channel" => 195,
          "Optical Transport" => 196,
          "Proprietary ATM" => 197,
          "Voice over Cable" => 198,
          "Infiniband" => 199,
          "TE Link" => 200,
          "Q.2931" => 201,
          "Virtual Trunk Group" => 202,
          "SIP Trunk Group" => 203,
          "SIP Signaling" => 204,
          "CATV Upstream Channel" => 205,
          "Econet" => 206,
          "FSAN 155Mb PON" => 207,
          "FSAN 622Mb PON" => 208,
          "Transparent Bridge" => 209,
          "Line Group" => 210,
          "Voice E&M Feature Group" => 211,
          "Voice FGD EANA" => 212,
          "Voice DID" => 213,
          "MPEG Transport" => 214,
          "6To4" => 215,
          "GTP" => 216,
          "Paradyne EtherLoop 1" => 217,
          "Paradyne EtherLoop 2" => 218,
          "Optical Channel Group" => 219,
          "HomePNA" => 220,
          "GFP" => 221,
          "ciscoISLvlan" => 222,
          "actelisMetaLOOP" => 223,
          "Fcip" => 224,
          # "IANA Reserved" => 225..4095,
          "IPv4" => 4096,
          "IPv6" => 4097,
          "IPv4/v6" => 4098,
          "IPX" => 4099,
          "DECnet" => 4100,
          "SNA" => 4101,
          "CONP" => 4102,
          "CLNP" => 4103,
          "VINES" => 4104,
          "XNS" => 4105,
          "ISDN B Channel Endpoint" => 4106,
          "ISDN D Channel Endpoint" => 4107,
          "BGP" => 4108,
          "OSPF" => 4109,
          "UDP" => 4110,
          "TCP" => 4111,
          "802.11a" => 4112,
          "802.11b" => 4113,
          "802.11g" => 4114,
          "802.11h" => 4115,
          "NFS" => 4200,
          "CIFS" => 4201,
          "DAFS" => 4202,
          "WebDAV" => 4203,
          "HTTP" => 4204,
          "FTP" => 4205,
          "NDMP" => 4300,
          "Telnet" => 4400,
          "SSH" => 4401,
          "SM CLP" => 4402,
          "SMTP" => 4403,
          "LDAP" => 4404,
          "RDP" => 4405,
          "HTTPS" => 4406,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32768..,
        }
      end
    end
    
    class RequestedState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "No Change" => 5,
          "Offline" => 6,
          "Test" => 7,
          "Deferred" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          "Not Applicable" => 12,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class EnabledDefault < Cmpi::ValueMap
      def self.map
        {
          "Enabled" => 2,
          "Disabled" => 3,
          "Not Applicable" => 5,
          "Enabled but Offline" => 6,
          "No Default" => 7,
          "Quiesce" => 9,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class AvailableRequestedStates < Cmpi::ValueMap
      def self.map
        {
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "Offline" => 6,
          "Test" => 7,
          "Defer" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          # "DMTF Reserved" => ..,
        }
      end
    end
    
    class TransitioningToState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "No Change" => 5,
          "Offline" => 6,
          "Test" => 7,
          "Defer" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          "Not Applicable" => 12,
          # "DMTF Reserved" => ..,
        }
      end
    end
    
    class Status < Cmpi::ValueMap
      def self.map
        {
          "OK" => :OK,
          "Error" => :Error,
          "Degraded" => :Degraded,
          "Unknown" => :Unknown,
          "Pred Fail" => :"Pred Fail",
          "Starting" => :Starting,
          "Stopping" => :Stopping,
          "Service" => :Service,
          "Stressed" => :Stressed,
          "NonRecover" => :NonRecover,
          "No Contact" => :"No Contact",
          "Lost Comm" => :"Lost Comm",
          "Stopped" => :Stopped,
        }
      end
    end
    
    class HealthState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "OK" => 5,
          "Degraded/Warning" => 10,
          "Minor failure" => 15,
          "Major failure" => 20,
          "Critical failure" => 25,
          "Non-recoverable error" => 30,
          # "DMTF Reserved" => ..,
          # "Vendor Specific" => 32768..65535,
        }
      end
    end
    
    class CommunicationStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Not Available" => 1,
          "Communication OK" => 2,
          "Lost Communication" => 3,
          "No Contact" => 4,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class DetailedStatus < Cmpi::ValueMap
      def self.map
        {
          "Not Available" => 0,
          "No Additional Information" => 1,
          "Stressed" => 2,
          "Predictive Failure" => 3,
          "Non-Recoverable Error" => 4,
          "Supporting Entity in Error" => 5,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class OperatingStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Not Available" => 1,
          "Servicing" => 2,
          "Starting" => 3,
          "Stopping" => 4,
          "Stopped" => 5,
          "Aborted" => 6,
          "Dormant" => 7,
          "Completed" => 8,
          "Migrating" => 9,
          "Emigrating" => 10,
          "Immigrating" => 11,
          "Snapshotting" => 12,
          "Shutting Down" => 13,
          "In Test" => 14,
          "Transitioning" => 15,
          "In Service" => 16,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class PrimaryStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "OK" => 1,
          "Degraded" => 2,
          "Error" => 3,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class RequestStateChange < Cmpi::ValueMap
      def self.map
        {
          "Completed with No Error" => 0,
          "Not Supported" => 1,
          "Unknown or Unspecified Error" => 2,
          "Cannot complete within Timeout Period" => 3,
          "Failed" => 4,
          "Invalid Parameter" => 5,
          "In Use" => 6,
          # "DMTF Reserved" => ..,
          "Method Parameters Checked - Job Started" => 4096,
          "Invalid State Transition" => 4097,
          "Use of Timeout Parameter Not Supported" => 4098,
          "Busy" => 4099,
          # "Method Reserved" => 4100..32767,
          # "Vendor Specific" => 32768..65535,
        }
      end
    end
  end

  class RCP_HttpdTCPProtocolEndpoint < MethodProvider
    
    include InstanceProviderIF
    
    def self.typemap
      {
        "PortNumber" => Cmpi::uint32,
        "ProtocolIFType" => Cmpi::uint16,
        "Description" => Cmpi::string,
        "OperationalStatus" => Cmpi::uint16A,
        "EnabledState" => Cmpi::uint16,
        "TimeOfLastStateChange" => Cmpi::dateTime,
        "Name" => Cmpi::string,
        "NameFormat" => Cmpi::string,
        "ProtocolType" => Cmpi::uint16,
        "OtherTypeDescription" => Cmpi::string,
        "SystemCreationClassName" => Cmpi::string,
        "SystemName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "OtherEnabledState" => Cmpi::string,
        "RequestedState" => Cmpi::uint16,
        "EnabledDefault" => Cmpi::uint16,
        "AvailableRequestedStates" => Cmpi::uint16A,
        "TransitioningToState" => Cmpi::uint16,
        "InstallDate" => Cmpi::dateTime,
        "StatusDescriptions" => Cmpi::stringA,
        "Status" => Cmpi::string,
        "HealthState" => Cmpi::uint16,
        "CommunicationStatus" => Cmpi::uint16,
        "DetailedStatus" => Cmpi::uint16,
        "OperatingStatus" => Cmpi::uint16,
        "PrimaryStatus" => Cmpi::uint16,
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "ElementName" => Cmpi::string,
      }
    end
  end

  class RCP_HttpdProtocolService < MethodProvider
    
    include InstanceProviderIF
    
    def self.typemap
      {
        "Protocol" => Cmpi::uint16,
        "OtherProtocol" => Cmpi::string,
        "MaxConnections" => Cmpi::uint16,
        "CurrentActiveConnections" => Cmpi::uint16,
        "SystemCreationClassName" => Cmpi::string,
        "SystemName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "Name" => Cmpi::string,
        "PrimaryOwnerName" => Cmpi::string,
        "PrimaryOwnerContact" => Cmpi::string,
        "StartMode" => Cmpi::string,
        "Started" => Cmpi::boolean,
        "EnabledState" => Cmpi::uint16,
        "OtherEnabledState" => Cmpi::string,
        "RequestedState" => Cmpi::uint16,
        "EnabledDefault" => Cmpi::uint16,
        "TimeOfLastStateChange" => Cmpi::dateTime,
        "AvailableRequestedStates" => Cmpi::uint16A,
        "TransitioningToState" => Cmpi::uint16,
        "InstallDate" => Cmpi::dateTime,
        "OperationalStatus" => Cmpi::uint16A,
        "StatusDescriptions" => Cmpi::stringA,
        "Status" => Cmpi::string,
        "HealthState" => Cmpi::uint16,
        "CommunicationStatus" => Cmpi::uint16,
        "DetailedStatus" => Cmpi::uint16,
        "OperatingStatus" => Cmpi::uint16,
        "PrimaryStatus" => Cmpi::uint16,
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "Description" => Cmpi::string,
        "ElementName" => Cmpi::string,
      }
    end
    
  end  
end
