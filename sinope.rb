require 'json'
require 'logger'
require 'net/http'
require 'net/https'
require 'uri'

class Sinope

    HOST = 'neviweb.com'
    # gateway modes
    HOME = 0
    AWAY = 2
    # device modes
    # auto => 3
    # away => 5
    # bypass => 131, temporary device setpoint override

    def initialize(username, password)
        @username = username
        @password = password
        @http = Net::HTTP.new(HOST, 443)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
    end

    def status()
        login() if !logged_in?

        get_gateway() if @gateway.nil?
        status = {:gateway => @gateway}

        get_devices() if @devices.nil?
        status[:devices] = @devices

        @devices.each do |device|
            device[:status] = device_status(device)
        end
        return status
    end

    def device_status(device)
        @logger.debug "Requesting status of #{device['name']}"
        request = get("/api/device/#{device['id']}/data")
        response = request(request)
        return format(response)
    end

    def setpoint(device_id, value, format='f')
        @logger.warn "Not yet implemented"
    end

    def home_away_status()
        login if !logged_in?
        get_gateway() if @gateway.nil?
        request = get("/api/gateway/#{@gateway['id']}/mode")
        response = request( request )
        return response['mode']
    end

    def home()
        @logger.debug "Setting home/away state to Home"
        return set_home_away(HOME)
    end

    def away()
        @logger.debug "Setting home/away state to Away"
        return set_home_away(AWAY)
    end

    def set_home_away(mode)
        login if !logged_in?
        get_gateway() if @gateway.nil?
        request = post("/api/gateway/#{@gateway['id']}/mode")
        request.set_form_data({'mode' => mode})
        return request(request)
    end

    def logged_in?()
        return !@session_id.nil? && !@session_id.empty?
    end

    def login()
        @logger.debug "Logging in"
        request = post('/api/login')
        request.content_type = 'application/x-www-form-urlencoded; charset=UTF-8'
        request.set_form_data({'email' => @username, 'password' => @password, 'stayConnected' => 0})
        begin
            response = request(request)
        rescue Exception => e
            raise "Authentication error: #{e}"
        end
        @logger.debug response

        @session_id = response['session']
        @temperature_format = response['user']['format']['temperature']
        @logger.debug "Logged in"
    end

    def get_gateway()
        @logger.debug "Getting Gateway"
        request = get('/api/gateway')
        response = request(request)
        @gateway = response[0]
    end

    def get_devices()
        @logger.debug "Getting Devices"
        request = get("/api/device?gatewayId=#{@gateway['id']}")
        @devices = request(request)
    end

    def get(path)
        request = Net::HTTP::Get.new(path)
        request.content_type = 'application/json'
        request['Session-Id'] = @session_id
        return request
    end

    def put(path)
        request = Net::HTTP::Put.new(path)
        request['Session-Id'] = @session_id
        return request
    end

    def post(path)
        request = Net::HTTP::Post.new(path)
        request['Session-Id'] = @session_id
        return request
    end

    def request(request)
        response = @http.request(request)
        if response.message == 'OK'
            body = JSON.parse(response.body)
            raise "Request error: #{body}" if body.is_a?(Hash) && !body['error'].nil?
            return body
        else
            raise "Failed request for #{request.path}: #{response.message}"
        end
    end

    def format(response)
        if @temperature_format == 'f'
            response['temperature'] = cToF(response['temperature'].to_f).to_s if response['temperature']
            response['setpoint'] = cToF(response['setpoint'].to_f).to_s if response['setpoint']
        end
        return response
    end

    def cToF(temp) 
        return (temp * 1.8 + 32).to_f
    end

    def fToC(temp) 
        return ((temp - 32) / 1.8).to_f
    end
end
