# frozen_string_literal: true

RSpec.describe Kvell::Client do
  let(:client) { Kvell::Client.new }

  describe '#fetch_banks' do
    subject(:result) do
      VCR.use_cassette("kvell/fetch_banks/#{cassette}", erb: erb) do
        client.fetch_banks
      end
    end

    let(:erb) do
      {
        api_key: api_key,
      }
    end

    let(:api_key) { 'key' }

    before do
      Kvell.configure do |config|
        config.api_key = api_key
        config.api_endpoint = 'https://api.pay.stage.kvell.group'
      end
    end

    context 'with valid data' do
      let(:cassette) { 'success' }

      it do
        expect(result).to include(
          a_hash_including(bank_bic: '044525593', bank_id: '100000000008', name: 'Альфа-Банк'),
        )
      end
    end

    context 'with invalid data' do
      context 'when api_key is nil' do
        let(:cassette) { 'empty_api_key' }

        let(:api_key) { nil }

        it {
          expect do
            subject
          end.to raise_exception Faraday::UnprocessableEntityError,
                                 'the server responded with status 422'
        }
      end

      context 'when api_key is invalid' do
        let(:cassette) { 'invalid_api_key' }

        let(:api_key) { 'invalid_api_key' }

        it {
          expect do
            subject
          end.to raise_exception Faraday::UnprocessableEntityError,
                                 'the server responded with status 422'
        }
      end
    end
  end

  describe '#check_payment_possibility' do
    subject(:result) do
      VCR.use_cassette("kvell/check_payment_possibility/#{cassette}", erb: erb) do
        client.check_payment_possibility(**params)
      end
    end

    let(:erb) do
      {
        api_key: api_key,
        signature: Digest::SHA256.hexdigest(
          "#{api_key}#{params.phone}#{params.bank_id}#{secret_key}",
        ),
      }
    end

    let(:api_key) { 'api_key' }
    let(:secret_key) { 'secret_key' }

    before do
      Kvell.configure do |config|
        config.api_key = api_key
        config.secret_key = secret_key
        config.api_endpoint = 'https://api.pay.stage.kvell.group'
      end
    end

    let(:params) do
      Kvell::Requests::CheckPaymentPossibility.new do |cpp|
        cpp.amount = amount
        cpp.phone = '79991234567'
        cpp.bank_id = bank_id
        cpp.fio = fio
        cpp.fio_check = true
      end
    end

    let(:amount) { 100 }
    let(:fio) { 'Иванов Иван Иванович' }
    let(:bank_id) { '100000000111' }

    context 'with valid data' do
      let(:cassette) { 'success' }

      it { is_expected.to eq('request_id' => '8dcb02c9-a5f5-476a-86f8-d5eacaf313bf') }
    end

    context 'with invalid data' do
      context 'when api_key is nil' do
        let(:cassette) { 'empty_api_key' }

        let(:api_key) { nil }

        it {
          expect do
            subject
          end.to raise_exception Faraday::UnprocessableEntityError,
                                 'the server responded with status 422'
        }
      end

      context 'when api_key is invalid' do
        let(:cassette) { 'invalid_api_key' }

        let(:api_key) { 'invalid_api_key' }

        it {
          expect do
            subject
          end.to raise_exception Faraday::UnprocessableEntityError,
                                 'the server responded with status 422'
        }
      end
    end
  end
end
