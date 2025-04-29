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
end
