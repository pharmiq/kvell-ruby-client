# frozen_string_literal: true

RSpec.describe Kvell::Client do
  let(:client) { Kvell::Client.new }

  let(:api_key) { 'api_key' }
  let(:secret_key) { 'secret_key' }

  before do
    Kvell.configure do |config|
      config.api_key = api_key
      config.secret_key = secret_key
      config.api_endpoint = 'https://api.pay.stage.kvell.group'
    end
  end

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

  describe '#check_payment_possibility_status' do
    subject(:result) do
      VCR.use_cassette("kvell/check_payment_possibility_status/#{cassette}", erb: erb) do
        client.check_payment_possibility_status(request_id)
      end
    end

    let(:erb) do
      {
        api_key: api_key,
        signature: Digest::SHA256.hexdigest("#{api_key}#{request_id}#{secret_key}"),
      }
    end

    let(:request_id) { '57bc37bf-cf78-4393-98e1-67fa4fa801db' }

    context 'with valid data' do
      let(:cassette) { 'success' }

      let(:data_expected) do
        {
          error_message: '',
          fio_nspk: 'Иванов Иван Иванович',
          nspk_id: 'B50731148152890M0000110011460901',
          status: 'success',
        }
      end

      it { expect(result).to have_attributes(data_expected) }
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

      context 'when amount is invalid' do
        let(:cassette) { 'invalid_amount' }

        let(:request_id) { '158bfba2-ba57-45f8-affb-db55d01cf5e8' }

        let(:data_expected) do
          {
            error_message: 'Ошибка при разборе сообщения',
            fio_nspk: '',
            nspk_id: '',
            status: 'error',
          }
        end

        it { expect(result).to have_attributes(data_expected) }
      end

      context 'when fio is mismatched' do
        let(:cassette) { 'mismatch_fio' }

        let(:request_id) { 'a73abd5e-0882-4098-ba91-46a23813c7c4' }

        let(:data_expected) do
          {
            error_message: 'Несовпадение ФИО получателя',
            fio_nspk: 'Иванов Иван Иванович',
            nspk_id: 'B5073115812064040000130011460901',
            status: 'error',
          }
        end

        it { expect(result).to have_attributes(data_expected) }
      end

      context 'when bank is not available' do
        let(:cassette) { 'invalid_bank' }

        let(:request_id) { '6ed9e6fb-7618-4b38-9121-8262c7d1c407' }

        let(:data_expected) do
          {
            error_message: 'Ошибка логики в СБП: Не найден Получатель',
            fio_nspk: '',
            nspk_id: '',
            status: 'error',
          }
        end

        it { expect(result).to have_attributes(data_expected) }
      end
    end
  end
end
