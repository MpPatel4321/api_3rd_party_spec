# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require_relative 'authentication_api'

describe AuthenticationApi do
  let(:api) { AuthenticationApi.new }
  let(:client_id) { 'f20a83b0edc00446fd3393674215899effa680d1b43aa88420ba3f1c1a7f473a' }
  let(:client_secret) { '874beede2c95d3819d505e7296ba00adee788d4dacb66257cbc5f7fd38b6b3d8' }
  let(:encoding) { 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' }
  let(:application) { 'application/json' }
  let(:ruby) { 'Ruby' }

  describe '#redirect_uri' do
    it 'returns the correct redirect URI' do
      redirect_uri = api.redirect_uri
      expect(redirect_uri).to include('https://www.test.co/redirect')
    end
  end

  describe '#request_access_token' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Content-Type' => application,
        'Host' => 'api.affinipay.com',
        'User-Agent' => ruby
      }
    end
    let(:redirect_uri) { api.redirect_uri }
    let(:payload) do
      {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": 'authorization_code',
        "redirect_uri": nil,
        "code": nil
      }
    end

    it 'returns the access token' do
      url = URI('https://api.affinipay.com/oauth/token')
      request = Net::HTTP::Post.new(url)
      response = Net::HTTPSuccess.new(1.0, '201', 'OK')
      params = { code: nil, redirect_uri: api.redirect_uri }

      stub_request(:post, url).with(body: payload.to_json, headers: headers).to_return(response)

      api.request_access_token(params)

      expect(response.code).to eq('201')
    end
  end

  describe '#get_user_credential' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Authorization' => 'Bearer some_access_token',
        'Host' => 'api.affinipay.com',
        'User-Agent' => ruby
      }
    end

    it 'returns the user credentials' do
      url = URI('https://api.affinipay.com/gateway-credentials')
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      request = Net::HTTP::Post.new(url)
      params = { 'access_token' => 'some_access_token' }

      stub_request(:get, url).with(headers: headers).to_return(response)

      response = api.get_user_credential(params)
      expect(response.code).to eq('200')
    end
  end

  describe '#create_charge' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Authorization' => 'Basic c29tZV9zZWNyZXRfa2V5Og==',
        'Content-Type' => application,
        'Host' => 'api.chargeio.com',
        'User-Agent' => ruby
      }
    end

    it 'returns the created charge' do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      url = URI('https://api.chargeio.com/v1/charges')
      request = Net::HTTP::Post.new(url)
      secret_key = 'some_secret_key'
      account_id = 'some_account_id'
      amount = 10.0
      method = 'credit_card'
      payload = { amount: amount, method: method, account_id: account_id }
      stub_request(:post, url).with(body: payload.to_json, headers: headers).to_return(response)
      response = api.create_charge(secret_key, account_id, amount, method)
      expect(response.code).to eq('200')
    end
  end

  describe '#disconnect_user_access_token' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Authorization' => application,
        'Content-Type' => application,
        'Host' => 'api.affinipay.com',
        'User-Agent' => ruby
      }
    end
    let(:payload) do
      {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": 'client_credentials',
        "scope": 'tenant'
      }
    end

    it 'returns the disconnected user access token' do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      url = URI('https://api.affinipay.com/oauth/token')
      request = Net::HTTP::Post.new(url)
      stub_request(:post, url).with(body: payload.to_json, headers: headers).to_return(response)

      response = api.disconnect_user_access_token
      expect(response.code).to eq('200')
    end
  end

  describe '#delete_merchant' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Authorization' => 'Bearer some_access_token',
        'Host' => 'secure.affinipay.com',
        'User-Agent' => ruby
      }
    end

    it 'deauthorizes the merchant application' do
      access_token = 'some_access_token'
      public_key = 'some_public_key'
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      url = URI("https://secure.affinipay.com/api/v1/merchants/#{public_key}/deauthorize_application")
      request = Net::HTTP::Post.new(url)
      stub_request(:delete, url).with(headers: headers).to_return(response)

      response = api.delete_merchant(access_token, public_key)
      expect(response.code).to eq('200')
    end
  end

  describe '#get_transaction' do
    let(:headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => encoding,
        'Authorization' => 'Basic c29tZV9zZWNyZXRfa2V5Og==',
        'Content-Type' => application,
        'Host' => 'api.chargeio.com',
        'User-Agent' => ruby
      }
    end
    context 'when the transaction ID is valid' do
      it 'returns the transaction method type' do
        transaction_id = 'valid_transaction_id'
        secret_key = 'some_secret_key'
        transaction_type = 'CreditCard' # Replace with the expected transaction type
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        url = URI("https://api.chargeio.com/v1/transactions/#{transaction_id}")
        request = Net::HTTP::Post.new(url)
        stub_request(:get, url).with(headers: headers).to_return(response)

        response = api.get_transaction(transaction_id, secret_key)
        expect(response.code).to eq('200')
      end
    end

    context 'when the transaction ID is invalid' do
      it 'returns an error message' do
        transaction_id = 'invalid_transaction_id'
        secret_key = 'some_secret_key'
        error_message = 'Invalid transaction ID' # Replace with the expected error message
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        url = URI("https://api.chargeio.com/v1/transactions/#{transaction_id}")
        request = Net::HTTP::Post.new(url)
        stub_request(:get, url).with(headers: headers).to_return(status: 500)
        response = api.get_transaction(transaction_id, secret_key)
        expect(response.code).to eq('500')
      end
    end
  end
end
