# frozen_string_literal: true

RSpec.describe Kvell::Client do
  let(:client) { Kvell::Client.new }

  let(:api_key) { 'api_key' }
  let(:secret_key) { 'secret_key' }
  let(:payout_secret_key) { 'payout_secret_key' }

  before do
    Kvell.configure do |config|
      config.api_key = api_key
      config.secret_key = secret_key
      config.payout_secret_key = payout_secret_key
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

      it { is_expected.to have_attributes(data_expected) }
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

        it { is_expected.to have_attributes(data_expected) }
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

        it { is_expected.to have_attributes(data_expected) }
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

        it { is_expected.to have_attributes(data_expected) }
      end
    end
  end

  # Кассеты записаны на методах выплаты на карту, так как для СБП тестирование на стороне KVELL
  # не настрено
  describe '#pay' do
    subject(:result) do
      VCR.use_cassette("kvell/pay/#{cassette}", erb: erb) do
        client.pay(params)
      end
    end

    let(:erb) do
      {
        api_key: api_key,
        signature: Digest::SHA256.hexdigest("#{api_key}#{params.to_json}#{payout_secret_key}"),
      }
    end

    let(:params) do
      Kvell::Requests::Pay.new do |pay|
        pay.amount = amount
        pay.phone = '79991234567'
        pay.bank_id = '100000000111'
        pay.fio = 'Иванов Иван Иванович'
        pay.transaction = transaction
        pay.description = 'Выплата по заявке 1234'
        pay.customer = '79991234567'
      end
    end
    let(:transaction) { '418e6125-6fb6-47d8-83e6-e0bc3ae567c2' }
    let(:amount) { 100 }

    context 'with valid data' do
      let(:cassette) { 'success' }

      let(:data_expected) do
        {
          status: 'completed',
          transaction: '418e6125-6fb6-47d8-83e6-e0bc3ae567c2',
          amount: 100,
          commission: 0,
          description: 'Выплата по заявке 1234',
          created_at: '2025-04-28T17:01:28.591290Z',
        }
      end

      it { is_expected.to have_attributes(data_expected) }
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

        let(:transaction) { '467b4a20-9fe7-487b-9584-cf007b7a0fc7' }
        let(:amount) { -1 }

        # let(:data_expected) do
        #   {
        #     errors: [
        #       { code: 20_099, message: 'json: cannot unmarshal number -1 into Go struct field' \
        #         'SBPPayoutRequest.amount of type uint' },
        #     ],
        #   }
        # end

        it {
          expect do
            subject
          end.to raise_exception Faraday::BadRequestError,
                                 'the server responded with status 400'
        }
      end

      context 'when transaction already created' do
        let(:cassette) { 'transaction_already_created' }

        # let(:data_expected) do
        #   {
        #     errors: [
        #       { code: 20_007, message: 'Транзакция совершалась прежде' },
        #     ],
        #   }
        # end

        it {
          expect do
            subject
          end.to raise_exception Faraday::BadRequestError,
                                 'the server responded with status 400'
        }
      end

      # context 'when fio is mismatched' do
      #   let(:cassette) { 'mismatch_fio' }

      #   let(:request_id) { 'a73abd5e-0882-4098-ba91-46a23813c7c4' }

      #   let(:data_expected) do
      #     {
      #       error_message: 'Несовпадение ФИО получателя',
      #       fio_nspk: 'Иванов Иван Иванович',
      #       nspk_id: 'B5073115812064040000130011460901',
      #       status: 'error',
      #     }
      #   end

      #   it { is_expected.to have_attributes(data_expected) }
      # end

      # context 'when bank is not available' do
      #   let(:cassette) { 'invalid_bank' }

      #   let(:request_id) { '6ed9e6fb-7618-4b38-9121-8262c7d1c407' }

      #   let(:data_expected) do
      #     {
      #       error_message: 'Ошибка логики в СБП: Не найден Получатель',
      #       fio_nspk: '',
      #       nspk_id: '',
      #       status: 'error',
      #     }
      #   end

      #   it { is_expected.to have_attributes(data_expected) }
      # end
    end
  end
end
