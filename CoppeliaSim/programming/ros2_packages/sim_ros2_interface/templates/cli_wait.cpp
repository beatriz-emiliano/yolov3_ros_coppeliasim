#py from parse_interfaces import *
#py interfaces = parse_interfaces(pycpp.params['interfaces_file'])
#py for interface_name, interface in interfaces.items():
#py if interface.tag == 'srv':
    else if(clientProxy->serviceType == "`interface.full_name`")
    {
        auto cli = boost::any_cast< std::shared_ptr< rclcpp::Client<`interface.cpp_type`> > >(clientProxy->client);
        long timeout_ms = 1000 * in->timeout;
        out->result = cli->wait_for_service(std::chrono::milliseconds(timeout_ms));
    }
#py endif
#py endfor
