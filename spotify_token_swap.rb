require 'sinatra'
require 'net/http'

# This is an example token swap service written
# as a Ruby/Sinatra service. This is required by
# the iOS SDK to authenticate a user.
#
# The service requires the Sinatra gem be installed:
#
# $ gem install sinatra
#
# To run the service, enter your client ID, client
# secret and client callback URL below and run the
# project.
#
# $ ruby spotify_token_swap.rb
#
# IMPORTANT: You will get authorization failures if you
# don't insert your own client credentials below.
#
# Once the service is running, pass the public URI to
# it (such as http://localhost:1234/swap if you run it
# with default settings on your local machine) to the
# token swap method in the iOS SDK:
#
# NSURL *swapServiceURL = [NSURL urlWithString:@"http://localhost:1234/swap"];
#
# -[SPAuth handleAuthCallbackWithTriggeredAuthURL:url
#                   tokenSwapServiceEndpointAtURL:swapServiceURL
#                                        callback:callback];
#

kClientId = "spotify-ios-sdk-beta"
kClientSecret = "ba95c775e4b39b8d60b27bcfced57ba473c10046"
kClientCallbackURL = "spotify-ios-sdk-beta://callback"

set :port, 1234 # The port to bind to.

post '/swap' do

    # This call takes a single POST parameter, "code", which
    # it combines with your client ID, secret and callback
    # URL to get an OAuth token from the Spotify Auth Service,
    # which it will pass back to the caller in a JSON payload.

	auth_code = params[:code]

	uri = URI.parse("https://ws.spotify.com")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = Net::HTTP::Post.new("/oauth/token")
	request.form_data = {
		"grant_type" => "authorization_code",
		"client_id" => kClientId,
		"client_secret" => kClientSecret,
		"redirect_uri" => kClientCallbackURL,
		"code" => auth_code
	}

	response = http.request(request)

	status response.code.to_i
	return response.body

end
