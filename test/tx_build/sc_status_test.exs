defmodule Stellar.TxBuild.SCStatusTest do
  use ExUnit.Case

  alias Stellar.Test.Fixtures.XDR, as: XDRFixtures
  alias Stellar.TxBuild.{SCStatus}

  test "new/1 when type is ok", %{} do
    %SCStatus{type: :ok, value: nil} = SCStatus.new(ok: nil)
  end

  test "new/1 when type ok is incorrect" do
    {:error, :invalid_void} = SCStatus.new(ok: :UNKNOWN)
  end

  test "new/1 when type is unknown_error", %{} do
    %SCStatus{type: :unknown_error, value: :UNKNOWN_ERROR_GENERAL} =
      SCStatus.new(unknown_error: :UNKNOWN_ERROR_GENERAL)
  end

  test "new/1 when type unknown_error is incorrect" do
    {:error, :invalid_unknown_error} = SCStatus.new(unknown_error: :UNKNOWN)
  end

  test "new/1 when type is host_value_error", %{} do
    %SCStatus{type: :host_value_error, value: :HOST_VALUE_UNKNOWN_ERROR} =
      SCStatus.new(host_value_error: :HOST_VALUE_UNKNOWN_ERROR)
  end

  test "new/1 when type host_value_error is incorrect" do
    {:error, :invalid_host_value_error} = SCStatus.new(host_value_error: :UNKNOWN)
  end

  test "new/1 when type is host_object_error", %{} do
    %SCStatus{type: :host_object_error, value: :HOST_OBJECT_UNKNOWN_ERROR} =
      SCStatus.new(host_object_error: :HOST_OBJECT_UNKNOWN_ERROR)
  end

  test "new/1 when type host_object_error is incorrect" do
    {:error, :invalid_host_object_error} = SCStatus.new(host_object_error: :UNKNOWN)
  end

  test "new/1 when type is host_function_error", %{} do
    %SCStatus{type: :host_function_error, value: :HOST_FN_UNKNOWN_ERROR} =
      SCStatus.new(host_function_error: :HOST_FN_UNKNOWN_ERROR)
  end

  test "new/1 when type host_function_error is incorrect" do
    {:error, :invalid_host_function_error} = SCStatus.new(host_function_error: :UNKNOWN)
  end

  test "new/1 when type is host_storage_error", %{} do
    %SCStatus{type: :host_storage_error, value: :HOST_STORAGE_UNKNOWN_ERROR} =
      SCStatus.new(host_storage_error: :HOST_STORAGE_UNKNOWN_ERROR)
  end

  test "new/1 when type host_storage_error is incorrect" do
    {:error, :invalid_host_storage_error} = SCStatus.new(host_storage_error: :UNKNOWN)
  end

  test "new/1 when type is host_context_error", %{} do
    %SCStatus{type: :host_context_error, value: :HOST_CONTEXT_UNKNOWN_ERROR} =
      SCStatus.new(host_context_error: :HOST_CONTEXT_UNKNOWN_ERROR)
  end

  test "new/1 when type host_context_error is incorrect" do
    {:error, :invalid_host_context_error} = SCStatus.new(host_context_error: :UNKNOWN)
  end

  test "new/1 when type is vm_error", %{} do
    %SCStatus{type: :vm_error, value: :VM_UNKNOWN} = SCStatus.new(vm_error: :VM_UNKNOWN)
  end

  test "new/1 when type vm_error is incorrect" do
    {:error, :invalid_vm_error} = SCStatus.new(vm_error: :UNKNOWN)
  end

  test "new/1 when type is contract_error", %{} do
    %SCStatus{type: :contract_error, value: 4_294_967_295} =
      SCStatus.new(contract_error: 4_294_967_295)
  end

  test "new/1 when type contract_error is incorrect" do
    {:error, :invalid_uint32} = SCStatus.new(contract_error: :UNKNOWN)
  end

  test "new/1 when type is host_auth_error", %{} do
    %SCStatus{type: :host_auth_error, value: :HOST_AUTH_UNKNOWN_ERROR} =
      SCStatus.new(host_auth_error: :HOST_AUTH_UNKNOWN_ERROR)
  end

  test "new/1 when type host_auth_error is incorrect" do
    {:error, :invalid_host_auth_error} = SCStatus.new(host_auth_error: :UNKNOWN)
  end

  test "to_xdr when type is ok" do
    %StellarBase.XDR.SCStatus{
      type: %StellarBase.XDR.SCStatusType{identifier: :SST_OK},
      value: %StellarBase.XDR.Void{void: nil}
    } = SCStatus.new(ok: nil) |> SCStatus.to_xdr()
  end
end
