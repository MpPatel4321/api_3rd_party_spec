# frozen_string_literal: true

require 'uri'
require 'byebug'
require 'json'
require 'net/http'

class AuthenticationApi
  CLIENT_ID     = 'f20a83b0edc00446fd3393674215899effa680d1b43aa88420ba3f1c1a7f473a'
  CLIENT_SECRET = '874beede2c95d3819d505e7296ba00adee788d4dacb66257cbc5f7fd38b6b3d8'

  def redirect_uri
    client_id = CLIENT_ID
    response_type             = 'code'
    redirect_uri              = 'https://www.test.co/redirect'
    scope                     = 'payments'
    url_base                  = 'https://secure.cpacharge.com/oauth/authorize'
    url_params                = "?redirect_uri=#{redirect_uri}&client_id=#{client_id}&scope=#{scope}&response_type=#{response_type}"
    url_base + url_params
  end

  def request_access_token(params)
    get_access_token(grant_type: 'authorization_code', code: params['code'], redirect_uri: params['redirect_uri'])
  end

  def get_user_credential(response)
    url = URI('https://api.affinipay.com/gateway-credentials')
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{response['access_token']}"

    https.request(request)
  end

  def create_charge(secret_key, account_id, amount, method)
    url = URI('https://api.chargeio.com/v1/charges')
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request = request_content_type(request)
    request.basic_auth secret_key.to_s, ''
    request.body = JSON.dump({
                               "amount": (amount),
                               "method": method,
                               "account_id": account_id
                             })
    https.request(request)
  end

  def disconnect_user_access_token
    url = URI('https://api.affinipay.com/oauth/token')

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['Authorization'] = 'application/json'
    request = request_content_type(request)
    request.body = JSON.dump({
                               "client_id": CLIENT_ID,
                               "client_secret": CLIENT_SECRET,
                               "grant_type": 'client_credentials',
                               "scope": 'tenant'
                             })

    https.request(request)
  end

  def delete_merchant(access_token, public_key)
    url = URI("https://secure.affinipay.com/api/v1/merchants/#{public_key}/deauthorize_application")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Delete.new(url)
    request['Authorization'] = "Bearer #{access_token}"

    https.request(request)
  end

  def get_transaction(transaction_id, secret_key)
    url = URI("https://api.chargeio.com/v1/transactions/#{transaction_id}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request = request_content_type(request)
    request.basic_auth secret_key.to_s, ''
    https.request(request)
  rescue StandardError => errors
    response
  end

  private

  def request_content_type(request)
    request['Content-Type'] = 'application/json'
    request
  end

  def get_access_token(grant_type: 'authorization_code', code: nil, redirect_uri: nil)
    url = URI('https://api.affinipay.com/oauth/token')

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request = request_content_type(request)
    request.body = JSON.dump({
                               "client_id": CLIENT_ID,
                               "client_secret": CLIENT_SECRET,
                               "grant_type": grant_type,
                               "redirect_uri": redirect_uri,
                               "code": code
                             })
    https.request(request)
  end
end
