defmodule Stellar.TxBuild.DefaultTest do
  use ExUnit.Case

  alias Stellar.{KeyPair, TxBuild}

  alias Stellar.TxBuild.{
    Account,
    BaseFee,
    CreateAccount,
    Memo,
    Operation,
    Operations,
    Payment,
    SequenceNumber,
    Signature,
    Transaction,
    TransactionEnvelope,
    TimeBounds
  }

  setup do
    keypair = KeyPair.from_secret_seed("SACHJRYLY43MUXRRCRFA6CZ5ZW5JVPPR4CWYWIX6BWRAOHOFVPVYDO5Z")
    signature = Signature.new(keypair)
    source_account = Account.new("GD726E62G6G4ANHWHIQTH5LNMFVF2EQSEXITB6DZCCTKVU6EQRRE2SJS")

    {:ok, %TxBuild{tx: tx}} = tx_build = TxBuild.new(source_account)

    %{
      source_account: source_account,
      keypair: keypair,
      signature: signature,
      tx: tx,
      tx_build: tx_build,
      tx_envelope: TransactionEnvelope.new(tx, []),
      tx_envelope_base64:
        "AAAAAgAAAAD/rxPaN43ANPY6ITP1bWFqXRISJdEw+HkQpqrTxIRiTQAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABxIRiTQAAAEDGQ1zlNXPps1aYpgCyHFzNgApPhKWhZqXlzPDMYXrZKilBt2SlWDkyki5pkiwKZ5Uc0bLNS1uqu31CJ5GFSWYO"
    }
  end

  test "new/2", %{source_account: source_account, tx: tx} do
    {:ok, %TxBuild{tx: ^tx, signatures: [], tx_envelope: nil}} = TxBuild.new(source_account)
  end

  test "new/2 with_options", %{source_account: source_account, keypair: {public_key, _secret}} do
    sequence_number = SequenceNumber.new(123_456)
    base_fee = BaseFee.new(500)
    memo = Memo.new(text: "TEST")

    op =
      [destination: public_key, starting_balance: 1.5]
      |> CreateAccount.new()
      |> Operation.new()

    operations = Operations.new([op])

    {:ok,
     %TxBuild{
       tx: %Transaction{
         sequence_number: ^sequence_number,
         base_fee: ^base_fee,
         memo: ^memo,
         operations: ^operations
       }
     }} =
      TxBuild.new(
        source_account,
        sequence_number: sequence_number,
        base_fee: base_fee,
        memo: memo,
        operations: operations
      )
  end

  test "new/2 with_bad_options", %{source_account: source_account} do
    {:error, :invalid_time_bounds} = TxBuild.new(source_account, time_bounds: nil)
  end

  test "new/2 invalid_source_account" do
    {:error, :invalid_source_account} = TxBuild.new("ABCD")
  end

  test "add_memo/2", %{tx_build: tx_build} do
    memo = Memo.new(text: "hello")
    {:ok, %TxBuild{tx: %Transaction{memo: ^memo}}} = TxBuild.add_memo(tx_build, memo)
  end

  test "add_memo/2 invalid_memo", %{tx_build: tx_build} do
    {:error, :invalid_memo} = TxBuild.add_memo(tx_build, "MEMO")
  end

  test "add_memo/2 piping_error" do
    {:error, :invalid_source_account} = TxBuild.add_memo({:error, :invalid_source_account}, :memo)
  end

  test "set_time_bounds/2", %{tx_build: tx_build} do
    time_bounds = TimeBounds.new(min_time: 0, max_time: 123_456_789)

    {:ok, %TxBuild{tx: %Transaction{time_bounds: ^time_bounds}}} =
      TxBuild.set_time_bounds(tx_build, time_bounds)
  end

  test "set_time_bounds/2 invalid_time_bounds", %{tx_build: tx_build} do
    {:error, :invalid_time_bounds} = TxBuild.set_time_bounds(tx_build, "12-10-2022")
  end

  test "set_time_bounds/2 piping_error" do
    {:error, :invalid_memo} = TxBuild.set_time_bounds({:error, :invalid_memo}, :time_bounds)
  end

  test "set_sequence_number/2", %{tx_build: tx_build} do
    seq_number = SequenceNumber.new(123_456_789)

    {:ok, %TxBuild{tx: %Transaction{sequence_number: ^seq_number}}} =
      TxBuild.set_sequence_number(tx_build, seq_number)
  end

  test "set_sequence_number/2 invalid_sequence_number", %{tx_build: tx_build} do
    {:error, :invalid_sequence_number} = TxBuild.set_sequence_number(tx_build, 12_102_022)
  end

  test "set_sequence_number/2 piping_error" do
    {:error, :invalid_memo} = TxBuild.set_sequence_number({:error, :invalid_memo}, :time_bounds)
  end

  test "set_base_fee/2", %{tx_build: tx_build} do
    base_fee = BaseFee.new(1_500)

    {:ok, %TxBuild{tx: %Transaction{base_fee: ^base_fee}}} =
      TxBuild.set_base_fee(tx_build, base_fee)
  end

  test "set_base_fee/2 invalid_base_fee", %{tx_build: tx_build} do
    {:error, :invalid_base_fee} = TxBuild.set_base_fee(tx_build, 1_000)
  end

  test "set_base_fee/2 piping_error" do
    {:error, :invalid_sequence_number} =
      TxBuild.set_base_fee({:error, :invalid_sequence_number}, :base_fee)
  end

  test "set_base_fee/2 before_adding_operations", %{
    tx_build: tx_build,
    keypair: {public_key, _secret}
  } do
    base_fee = BaseFee.new(500)
    op1 = CreateAccount.new(destination: public_key, starting_balance: 1.5)
    op2 = Payment.new(destination: public_key, asset: :native, amount: 150)

    {:ok, %TxBuild{tx: %Transaction{base_fee: %BaseFee{fee: 500, multiplier: 2}}}} =
      tx_build
      |> TxBuild.set_base_fee(base_fee)
      |> TxBuild.add_operations([op1, op2])
  end

  test "set_base_fee/2 after_adding_operations", %{
    tx_build: tx_build,
    keypair: {public_key, _secret}
  } do
    base_fee = BaseFee.new(200)
    op1 = CreateAccount.new(destination: public_key, starting_balance: 1.5)
    op2 = Payment.new(destination: public_key, asset: :native, amount: 150)

    {:ok, %TxBuild{tx: %Transaction{base_fee: %BaseFee{fee: 200, multiplier: 2}}}} =
      tx_build
      |> TxBuild.add_operations([op1, op2])
      |> TxBuild.set_base_fee(base_fee)
  end

  test "add_operation/2", %{tx_build: tx_build, keypair: {public_key, _secret}} do
    op_body = CreateAccount.new(destination: public_key, starting_balance: 1.5)
    operation = Operation.new(op_body)

    {:ok, %TxBuild{tx: %Transaction{operations: %Operations{operations: [^operation]}}}} =
      TxBuild.add_operation(tx_build, op_body)
  end

  test "add_operation/2 invalid_operation", %{tx_build: tx_build} do
    operation =
      "INVALID_DESTINATION"
      |> (&CreateAccount.new(destination: &1, starting_balance: 1.5)).()
      |> Operation.new()

    {:error, :invalid_operation} = TxBuild.add_operation(tx_build, operation)
  end

  test "add_operation/2 piping_error" do
    {:error, :invalid_memo} = TxBuild.add_operation({:error, :invalid_memo}, :operation)
  end

  test "add_operations/2", %{tx_build: tx_build, keypair: {public_key, _secret}} do
    op1 = CreateAccount.new(destination: public_key, starting_balance: 1.5)
    op2 = Payment.new(destination: public_key, asset: :native, amount: 100)
    operations = [Operation.new(op1), Operation.new(op2)]

    {:ok, %TxBuild{tx: %Transaction{operations: %Operations{operations: ^operations}}}} =
      TxBuild.add_operations(tx_build, [op1, op2])
  end

  test "add_operations/2 invalid_operation", %{tx_build: tx_build} do
    operation =
      "INVALID_DESTINATION"
      |> (&CreateAccount.new(destination: &1, starting_balance: 1.5)).()
      |> Operation.new()

    {:error, :invalid_operation} = TxBuild.add_operations(tx_build, [operation])
  end

  test "add_operations/2 piping_error" do
    {:error, :invalid_memo} = TxBuild.add_operations({:error, :invalid_memo}, :operation)
  end

  test "sign/2", %{keypair: keypair, tx_build: tx_build} do
    signature = Signature.new(keypair)
    {:ok, %TxBuild{signatures: [^signature | _signatures]}} = TxBuild.sign(tx_build, signature)
  end

  test "sign/2 invalid_signature", %{tx_build: tx_build} do
    signature = Signature.new({"PUBLIC", "SECRET"})
    {:error, :invalid_signature} = TxBuild.sign(tx_build, signature)
  end

  test "sign/2 piping_error" do
    {:error, :invalid_operation} = TxBuild.sign({:error, :invalid_operation}, :signature)
  end

  test "sign/2 multiple", %{signature: signature, tx_build: tx_build} do
    {pk, sk} = KeyPair.random()
    signatures = [signature, Signature.new({pk, sk})]

    {:ok, %TxBuild{signatures: ^signatures}} = TxBuild.sign(tx_build, signatures)
  end

  test "sign_envelope/2", %{keypair: keypair, tx_envelope_base64: tx_envelope_base64} do
    signature = Signature.new(keypair)

    {:ok,
     "AAAAAgAAAAD/rxPaN43ANPY6ITP1bWFqXRISJdEw+HkQpqrTxIRiTQAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACxIRiTQAAAEDGQ1zlNXPps1aYpgCyHFzNgApPhKWhZqXlzPDMYXrZKilBt2SlWDkyki5pkiwKZ5Uc0bLNS1uqu31CJ5GFSWYOxIRiTQAAAEDGQ1zlNXPps1aYpgCyHFzNgApPhKWhZqXlzPDMYXrZKilBt2SlWDkyki5pkiwKZ5Uc0bLNS1uqu31CJ5GFSWYO"} =
      TxBuild.sign_envelope(tx_envelope_base64, signature)
  end

  test "sign_envelope/2 multiple", %{signature: signature, tx_envelope_base64: tx_envelope_base64} do
    {pk, sk} =
      KeyPair.from_secret_seed("SAALZGBDHMY5NQGU2L6G4GHQ65ESCDQD5TNYPWM5AZDVB3HICLKF4KI3")

    signatures = [signature, Signature.new({pk, sk})]

    {:ok,
     "AAAAAgAAAAD/rxPaN43ANPY6ITP1bWFqXRISJdEw+HkQpqrTxIRiTQAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADxIRiTQAAAEDGQ1zlNXPps1aYpgCyHFzNgApPhKWhZqXlzPDMYXrZKilBt2SlWDkyki5pkiwKZ5Uc0bLNS1uqu31CJ5GFSWYOxIRiTQAAAEDGQ1zlNXPps1aYpgCyHFzNgApPhKWhZqXlzPDMYXrZKilBt2SlWDkyki5pkiwKZ5Uc0bLNS1uqu31CJ5GFSWYO8057hgAAAEC70Ava49XnFEQ6d9ed+IvfiMWL6do55bekG9LctPFnjTrRITSFs9cuHTfvbkSTCcFxw5IrZxqgeupuYb+ubU8H"} =
      TxBuild.sign_envelope(tx_envelope_base64, signatures)
  end

  test "sign_envelope/2 invalid_signature", %{tx_envelope_base64: tx_envelope_base64} do
    signature = Signature.new({"PUBLIC", "SECRET"})
    {:error, :invalid_signature} = TxBuild.sign_envelope(tx_envelope_base64, signature)
  end

  test "build/1", %{tx_build: tx_build, tx_envelope: tx_envelope} do
    {:ok, %TxBuild{tx_envelope: ^tx_envelope}} = TxBuild.build(tx_build)
  end

  test "build/1 piping_error" do
    {:error, :invalid_operation} = TxBuild.build({:error, :invalid_operation})
  end

  test "envelope/1", %{
    signature: signature,
    tx_build: tx_build,
    tx_envelope_base64: tx_envelope_base64
  } do
    {:ok, ^tx_envelope_base64} =
      tx_build
      |> TxBuild.sign(signature)
      |> TxBuild.envelope()
  end

  test "envelope/1 piping_error" do
    {:error, :invalid_signature} = TxBuild.envelope({:error, :invalid_signature})
  end
end
